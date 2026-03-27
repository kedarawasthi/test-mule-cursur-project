param(
  [Parameter(Mandatory = $true)][string]$ConnectedAppClientId,
  [Parameter(Mandatory = $true)][string]$ConnectedAppClientSecret,
  [Parameter(Mandatory = $true)][string]$OrgId,
  [string]$GroupId = "",
  [string]$AssetId = "american-airlines-info-api",
  [string]$AssetVersion = "1.0.0",
  [string]$AssetName = "American Airlines Info API",
  [string]$Description = "RAML specification for American Airlines Info API",
  [string]$Dependencies = "68ef9520-24e9-4cf2-b2f5-620025690913:training-american-flight-data-type:1.0.1,68ef9520-24e9-4cf2-b2f5-620025690913:training-american-flights-example:1.0.1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $GroupId -or $GroupId.Trim().Length -eq 0) {
  $GroupId = $OrgId
}

$apiSourceDir = Join-Path $PSScriptRoot "..\\src\\main\\resources\\api"
if (-not (Test-Path $apiSourceDir)) {
  throw "API source directory not found: $apiSourceDir"
}

$tmpDir = Join-Path $env:TEMP ("american-airlines-info-api-" + [Guid]::NewGuid().ToString("N"))
$tmpZip = "$tmpDir.zip"
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
  Copy-Item -Path (Join-Path $apiSourceDir "*") -Destination $tmpDir -Recurse -Force
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zipArchive = [System.IO.Compression.ZipFile]::Open($tmpZip, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    $files = Get-ChildItem -Path $tmpDir -Recurse -File
    $tmpDirFullPath = (Get-Item -Path $tmpDir).FullName
    $tmpDirPattern = [Regex]::Escape($tmpDirFullPath)
    foreach ($file in $files) {
      $relativePath = [Regex]::Replace($file.FullName, "(?i)^$tmpDirPattern[\\/]", "").Replace("\", "/")
      [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $relativePath) | Out-Null
    }
  }
  finally {
    $zipArchive.Dispose()
  }

  $tokenResp = Invoke-RestMethod -Method Post -Uri "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" -ContentType "application/json" -Body (@{
    client_id     = $ConnectedAppClientId
    client_secret = $ConnectedAppClientSecret
    grant_type    = "client_credentials"
  } | ConvertTo-Json)

  $token = $tokenResp.access_token
  if (-not $token) {
    throw "Failed to acquire Anypoint token."
  }

  $publishUrl = "https://anypoint.mulesoft.com/exchange/api/v2/organizations/$OrgId/assets/$GroupId/$AssetId/$AssetVersion"
  Write-Host "Publishing API spec asset to Exchange: $publishUrl"

  $response = & curl.exe --location --request POST $publishUrl `
    --header "Authorization: bearer $token" `
    --header "x-sync-publication: true" `
    --form "name=$AssetName" `
    --form "description=$Description" `
    --form "dependencies=$Dependencies" `
    --form "properties.mainFile=american-airlines-info-api.raml" `
    --form "properties.apiVersion=v1" `
    --form "files.raml.zip=@$tmpZip"

  Write-Host $response
}
finally {
  if (Test-Path $tmpZip) { Remove-Item -Path $tmpZip -Force }
  if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force }
}
