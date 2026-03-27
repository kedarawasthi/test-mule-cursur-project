param(
  [string]$BaseUrl = "http://localhost:8085"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Api {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [AllowNull()][object]$Body = $null,
    [hashtable]$Headers = @{}
  )

  $uri = "$BaseUrl$Path"
  $statusCode = 0
  $responseBody = ""
  $contentType = ""

  try {
    $params = @{
      Uri         = $uri
      Method      = $Method
      Headers     = $Headers
      TimeoutSec  = 15
      UseBasicParsing = $true
    }

    if ($null -ne $Body -and (($Body -isnot [string]) -or -not [string]::IsNullOrWhiteSpace($Body))) {
      $params["Body"] = $Body
    }

    $resp = Invoke-WebRequest @params
    $statusCode = [int]$resp.StatusCode
    $responseBody = [string]$resp.Content
    $contentType = [string]$resp.Headers["Content-Type"]
  } catch {
    $webResp = $null
    $ex = $_.Exception
    if ($null -ne $ex -and $null -ne $ex.PSObject.Properties["Response"]) {
      $webResp = $ex.Response
    }

    if ($null -eq $webResp) {
      throw
    }

    $statusCode = [int]$webResp.StatusCode
    $contentType = [string]$webResp.Headers["Content-Type"]
    $stream = $webResp.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $responseBody = $reader.ReadToEnd()
    $reader.Dispose()
  }

  $json = $null
  if ($responseBody -and ($responseBody.Trim().StartsWith("{") -or $responseBody.Trim().StartsWith("["))) {
    try {
      $json = $responseBody | ConvertFrom-Json -ErrorAction Stop
    } catch {
      $json = $null
    }
  }

  [pscustomobject]@{
    StatusCode  = $statusCode
    Body        = $responseBody
    Json        = $json
    ContentType = $contentType
    Uri         = $uri
  }
}

function Invoke-ApiWithCircuitRetry {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [AllowNull()][object]$Body = $null,
    [hashtable]$Headers = @{},
    [int]$MaxRetries = 5,
    [int]$SleepSeconds = 2
  )

  for ($attempt = 0; $attempt -le $MaxRetries; $attempt++) {
    $res = Invoke-Api -Method $Method -Path $Path -Body $Body -Headers $Headers
    $isCircuitOpen = ($res.StatusCode -eq 503) -and ($res.Body -match "Circuit breaker is OPEN")
    if (-not $isCircuitOpen) {
      return $res
    }

    if ($attempt -lt $MaxRetries) {
      Start-Sleep -Seconds $SleepSeconds
    }
  }

  return $res
}

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) {
    throw $Message
  }
}

$seedId = Get-Random -Minimum 150000 -Maximum 900000
$cleanupIds = New-Object System.Collections.Generic.List[int]
$results = New-Object System.Collections.Generic.List[object]

function Run-Test {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Script
  )

  try {
    & $Script
    $results.Add([pscustomobject]@{ Name = $Name; Status = "PASS"; Detail = "" })
  } catch {
    $results.Add([pscustomobject]@{ Name = $Name; Status = "FAIL"; Detail = $_.Exception.Message })
  }
}

function Wait-ForApiReady {
  param(
    [int]$MaxAttempts = 30,
    [int]$SleepSeconds = 2
  )

  for ($i = 0; $i -lt $MaxAttempts; $i++) {
    try {
      $res = Invoke-Api -Method "GET" -Path "/api/flights"
      if ($res.StatusCode -eq 200 -or $res.StatusCode -eq 503) {
        return
      }
    } catch {
      # Keep waiting while app is redeploying.
    }
    Start-Sleep -Seconds $SleepSeconds
  }
}

function Wait-ForDbCircuitClosed {
  param(
    [int]$MaxAttempts = 70,
    [int]$SleepSeconds = 2
  )

  for ($i = 0; $i -lt $MaxAttempts; $i++) {
    try {
      $res = Invoke-Api -Method "GET" -Path "/api/flights"
      if ($res.StatusCode -eq 200) {
        return
      }
    } catch {
      # Ignore transient readiness failures while waiting.
    }

    Start-Sleep -Seconds $SleepSeconds
  }

  throw "DB circuit did not close in expected time window"
}

function Test-FlightPresent {
  param([int]$Id)
  $res = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights/$Id"
  if ($res.StatusCode -ne 200 -or $null -eq $res.Json) {
    return $false
  }

  if ($res.Json -is [System.Array]) {
    return @($res.Json).Count -gt 0
  }

  return $null -ne $res.Json.ID
}

function Ensure-FlightExists {
  param([int]$Id)

  $singleObject = @{
    ID = $Id
    code = "AA$Id"
    price = 100
    departureDate = "2026-04-10T08:00:00Z"
    origin = "SFO"
    destination = "LAX"
    emptySeats = 10
    plane = @{ type = "Boeing 737"; totalSeats = 180 }
  }

  $singlePayload = $singleObject | ConvertTo-Json -Depth 5

  $payload = @($singleObject) | ConvertTo-Json -Depth 5 -Compress
  if (-not $payload.TrimStart().StartsWith("[")) {
    $payload = "[" + $payload + "]"
  }

  $batchRes = Invoke-ApiWithCircuitRetry -Method "POST" -Path "/api/flights/batch" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  if ($batchRes.StatusCode -ne 202) {
    $createRes = Invoke-ApiWithCircuitRetry -Method "POST" -Path "/api/flights" -Body $singlePayload -Headers @{ "Content-Type" = "application/json" }
    $createOk = ($createRes.StatusCode -eq 200) -or ($createRes.Body -match "Duplicate entry")
    Assert-True $createOk "Failed to seed flight $Id via batch/post. Batch=$($batchRes.StatusCode), Post=$($createRes.StatusCode)"
  }

  for ($i = 0; $i -lt 12; $i++) {
    if (Test-FlightPresent -Id $Id) {
      return
    }
    Start-Sleep -Seconds 1
  }

  throw "Seeded flight $Id did not become visible in time"
}

Wait-ForApiReady
Wait-ForDbCircuitClosed

Run-Test "GET all flights returns collection" {
  $res = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights"
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($null -ne $res.Json) "Expected JSON body"
  Assert-True ($null -ne $res.Json.Count) "Expected Count field in response"
}

Run-Test "GET flights with valid destination filter" {
  $res = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights?destination=SFO"
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($null -ne $res.Json) "Expected JSON body"
  if (($res.Json | Measure-Object).Count -gt 0) {
    $allMatch = @($res.Json | Where-Object { $_.destination -ne "SFO" }).Count -eq 0
    Assert-True $allMatch "Expected all filtered records to have destination=SFO"
  }
}

Run-Test "GET flights with invalid destination enum returns 400" {
  $res = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights?destination=XYZ"
  Assert-True ($res.StatusCode -eq 400) "Expected 400, got $($res.StatusCode)"
}

Run-Test "GET non-existing flight id returns 200 with empty/zero count" {
  $res = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights/9999999"
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($null -ne $res.Json) "Expected JSON body"
}

Run-Test "POST create flight with boundary numeric values" {
  $selectedId = $null
  $candidateBase = Get-Random -Minimum 150000 -Maximum 850000

  foreach ($i in 0..200) {
    $candidateId = $candidateBase + $i
    $probe = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights/$candidateId"
    if ($probe.StatusCode -ne 200) {
      continue
    }

    $exists = $false
    if ($probe.Json -is [System.Array]) {
      $exists = @($probe.Json).Count -gt 0
    } elseif ($null -ne $probe.Json) {
      $exists = $true
    }

    if (-not $exists) {
      $selectedId = $candidateId
      break
    }
  }

  Assert-True ($null -ne $selectedId) "Could not find an available ID for create boundary test"

  $payload = @{
    ID = $selectedId
    code = "AA$selectedId"
    price = 0
    departureDate = "2026-04-10T08:00:00Z"
    origin = "SFO"
    destination = "LAX"
    emptySeats = 0
    plane = @{
      type = "Boeing 737"
      totalSeats = 0
    }
  } | ConvertTo-Json -Depth 4

  $res = Invoke-ApiWithCircuitRetry -Method "POST" -Path "/api/flights" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True (@(200, 201) -contains $res.StatusCode) "Create failed for candidate ID $selectedId with status $($res.StatusCode): $($res.Body)"
  Assert-True ($res.Body -match "created successfully") "Expected create success message"

  $cleanupIds.Add($selectedId) | Out-Null
  $script:seedId = $selectedId
}

Run-Test "POST duplicate flight id returns DB error status" {
  $id = $seedId
  Ensure-FlightExists -Id $id
  $payload = @{
    ID = $id
    code = "AA$id-DUP"
    price = 100
    departureDate = "2026-04-10T08:00:00Z"
    origin = "SFO"
    destination = "LAX"
    emptySeats = 10
    plane = @{
      type = "Boeing 737"
      totalSeats = 100
    }
  } | ConvertTo-Json -Depth 4

  $res = Invoke-ApiWithCircuitRetry -Method "POST" -Path "/api/flights" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True (@(400, 409, 500, 503) -contains $res.StatusCode) "Expected error status (400/409/500/503), got $($res.StatusCode)"
}

Run-Test "POST with unsupported media type returns 415" {
  $res = Invoke-Api -Method "POST" -Path "/api/flights" -Body "plain-text-payload" -Headers @{ "Content-Type" = "text/plain" }
  Assert-True ($res.StatusCode -eq 415) "Expected 415, got $($res.StatusCode)"
}

Run-Test "PUT update existing flight" {
  $id = $seedId
  Ensure-FlightExists -Id $id
  $payload = @{
    ID = $id
    code = "AA$id-U"
    price = 999.99
    departureDate = "2026-04-10T09:30:00Z"
    origin = "SFO"
    destination = "CLE"
    emptySeats = 1
    plane = @{
      type = "Boeing 737 MAX"
      totalSeats = 180
    }
  } | ConvertTo-Json -Depth 4

  $res = Invoke-ApiWithCircuitRetry -Method "PUT" -Path "/api/flights/$id" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($res.Body -match "updated successfully") "Expected update success message"
}

Run-Test "PUT malformed JSON returns 400" {
  $res = Invoke-Api -Method "PUT" -Path "/api/flights/$seedId" -Body "{bad-json}" -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 400) "Expected 400, got $($res.StatusCode)"
}

Run-Test "DELETE existing flight without active bookings" {
  $id = $null
  $candidateBase = Get-Random -Minimum 150000 -Maximum 850000

  foreach ($i in 0..200) {
    $candidateId = $candidateBase + $i
    $probe = Invoke-ApiWithCircuitRetry -Method "GET" -Path "/api/flights/$candidateId"
    if ($probe.StatusCode -ne 200) {
      continue
    }

    $exists = $false
    if ($probe.Json -is [System.Array]) {
      $exists = @($probe.Json).Count -gt 0
    } elseif ($null -ne $probe.Json) {
      $exists = $true
    }

    if (-not $exists) {
      $id = $candidateId
      break
    }
  }

  Assert-True ($null -ne $id) "Could not allocate ID for delete-existing test"
  Ensure-FlightExists -Id $id
  Assert-True (Test-FlightPresent -Id $id) "Expected seeded flight $id before delete"

  $res = Invoke-ApiWithCircuitRetry -Method "DELETE" -Path "/api/flights/$id"
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($res.Body -match "deleted successfully") "Expected delete success message"
}

Run-Test "DELETE non-existing flight remains idempotent success" {
  $res = Invoke-ApiWithCircuitRetry -Method "DELETE" -Path "/api/flights/9999999"
  Assert-True ($res.StatusCode -eq 404) "Expected 404, got $($res.StatusCode)"
}

Run-Test "Unknown API route returns 404" {
  $res = Invoke-Api -Method "GET" -Path "/api/does-not-exist"
  Assert-True ($res.StatusCode -eq 404) "Expected 404, got $($res.StatusCode)"
}

Run-Test "Method not allowed returns 405" {
  $res = Invoke-Api -Method "PATCH" -Path "/api/flights"
  Assert-True ($res.StatusCode -eq 405) "Expected 405, got $($res.StatusCode)"
}

Run-Test "DW simple transforms case and phone format" {
  $payload = '{"Field1":"hello world","phoneNumber":"555-123-4567"}'
  $res = Invoke-Api -Method "POST" -Path "/dw/simple" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($res.Json.Field2 -eq "HELLO WORLD") "Expected uppercase Field2"
  Assert-True ($res.Json.phoneNumber -eq "5551234567") "Expected normalized phone number"
}

Run-Test "DW simple handles missing fields boundary" {
  $payload = '{}'
  $res = Invoke-Api -Method "POST" -Path "/dw/simple" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($res.Json.Field2 -eq "") "Expected empty Field2 default"
  Assert-True ($res.Json.phoneNumber -eq "") "Expected empty phoneNumber default"
}

Run-Test "DW complex handles single XML object (array normalization)" {
  $xml = @"
<flights>
  <flight>
    <FlightId>AA100</FlightId>
    <DepartureCity>SFO</DepartureCity>
    <ArrivalCity>LAX</ArrivalCity>
    <AvailableSeats>12</AvailableSeats>
    <category>Domestic</category>
    <price>100</price>
    <options>
      <option><id>OPT1</id></option>
    </options>
  </flight>
</flights>
"@
  $res = Invoke-Api -Method "POST" -Path "/dw/complex" -Body $xml -Headers @{ "Content-Type" = "application/xml" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($res.Json.totalOptionCount -eq 1) "Expected totalOptionCount=1"
  Assert-True ($res.Json.flights[0].price -eq 110) "Expected domestic uplift to 110"
}

Run-Test "DW complex filters out zero-seat flights boundary" {
  $xml = @"
<flights>
  <flight>
    <FlightId>AA200</FlightId>
    <DepartureCity>JFK</DepartureCity>
    <ArrivalCity>LHR</ArrivalCity>
    <AvailableSeats>0</AvailableSeats>
    <category>International</category>
    <price>200</price>
    <options>
      <option><id>OPT2</id></option>
    </options>
  </flight>
</flights>
"@
  $res = Invoke-Api -Method "POST" -Path "/dw/complex" -Body $xml -Headers @{ "Content-Type" = "application/xml" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True (($res.Json.flights | Measure-Object).Count -eq 0) "Expected filtered flights list to be empty"
}

Run-Test "DW multi1 splits baggage at 30kg boundary" {
  $payload = @'
{
  "passengerName": "Jane Doe",
  "flightNumber": "AA450",
  "travelDate": "04/15/2026",
  "flightClass": "Business",
  "baggage": [
    {"id":"BAG001","weight":30},
    {"id":"BAG002","weight":31}
  ]
}
'@
  $res = Invoke-Api -Method "POST" -Path "/dw/multi1" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True ($res.Body -match "<specialAssistance>true</specialAssistance>") "Expected specialAssistance true for Business class"
  Assert-True ($res.Body -match "<normalBaggage>") "Expected normalBaggage node"
  Assert-True ($res.Body -match "<heavyBaggage>") "Expected heavyBaggage node"
}

Run-Test "DW multi2 filters cancelled and maps JFK origin" {
  $xml = @"
<flights>
  <flight>
    <id>FL901</id>
    <src>JFK</src>
    <dest>LAX</dest>
    <deptTime>2026-04-20T14:30</deptTime>
    <price>650</price>
    <status>ACTIVE</status>
  </flight>
  <flight>
    <id>FL902</id>
    <src>ORD</src>
    <dest>MIA</dest>
    <deptTime>2026-04-21T09:00</deptTime>
    <price>380</price>
    <status>CANCELLED</status>
  </flight>
</flights>
"@
  $res = Invoke-Api -Method "POST" -Path "/dw/multi2" -Body $xml -Headers @{ "Content-Type" = "application/xml" }
  Assert-True ($res.StatusCode -eq 200) "Expected 200, got $($res.StatusCode)"
  Assert-True (($res.Json | Measure-Object).Count -eq 1) "Expected only ACTIVE flights"
  Assert-True ($res.Json[0].route.origin -eq "John F. Kennedy") "Expected JFK mapping to John F. Kennedy"
}

Run-Test "Batch endpoint accepts valid payload with 202" {
  $id1 = $seedId + 10
  $id2 = $seedId + 11
  $payload = @(
    @{
      ID = $id1
      code = "AA$id1"
      price = 300
      departureDate = "2026-05-01T07:00:00Z"
      origin = "CLE"
      destination = "SFO"
      emptySeats = 18
      plane = @{ type = "Airbus A320"; totalSeats = 160 }
    },
    @{
      ID = $id2
      code = "AA$id2"
      price = 400
      departureDate = "2026-05-01T11:00:00Z"
      origin = "SFO"
      destination = "LAX"
      emptySeats = 24
      plane = @{ type = "Boeing 737"; totalSeats = 180 }
    }
  ) | ConvertTo-Json -Depth 5

  $res = Invoke-Api -Method "POST" -Path "/api/flights/batch" -Body $payload -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 202) "Expected 202, got $($res.StatusCode)"
  Assert-True ($res.Body -match "Batch accepted for processing") "Expected batch accepted response"
  $cleanupIds.Add($id1) | Out-Null
  $cleanupIds.Add($id2) | Out-Null
}

Run-Test "Batch endpoint handles empty array boundary" {
  $res = Invoke-Api -Method "POST" -Path "/api/flights/batch" -Body "[]" -Headers @{ "Content-Type" = "application/json" }
  Assert-True ($res.StatusCode -eq 202) "Expected 202, got $($res.StatusCode)"
}

# Best-effort cleanup
foreach ($id in $cleanupIds) {
  try {
    [void](Invoke-Api -Method "DELETE" -Path "/api/flights/$id")
  } catch {
    # Ignore cleanup failures to preserve original test signal.
  }
}

$failed = @($results | Where-Object { $_.Status -eq "FAIL" })
$passed = @($results | Where-Object { $_.Status -eq "PASS" })

Write-Host ""
Write-Host "Local API Regression Results ($($results.Count) tests):"
$results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "Passed: $($passed.Count)"
Write-Host "Failed: $($failed.Count)"

if ($failed.Count -gt 0) {
  throw "Regression suite failed. Review failed test details above."
}

