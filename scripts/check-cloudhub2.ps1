param(
  [Parameter(Mandatory = $true)][string]$OrgId,
  [Parameter(Mandatory = $true)][string]$EnvId,
  [Parameter(Mandatory = $true)][string]$AppName,
  [string]$BaseUrl = "https://anypoint.mulesoft.com"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $env:ANYPOINT_CONNECTED_APP_CLIENT_ID -or -not $env:ANYPOINT_CONNECTED_APP_CLIENT_SECRET) {
  throw "Missing Connected App env vars. Set ANYPOINT_CONNECTED_APP_CLIENT_ID and ANYPOINT_CONNECTED_APP_CLIENT_SECRET first."
}

$tokenResp = Invoke-RestMethod -Method Post -Uri "$BaseUrl/accounts/api/v2/oauth2/token" -ContentType "application/json" -Body (@{
  client_id = $env:ANYPOINT_CONNECTED_APP_CLIENT_ID
  client_secret = $env:ANYPOINT_CONNECTED_APP_CLIENT_SECRET
  grant_type = "client_credentials"
} | ConvertTo-Json)

$token = $tokenResp.access_token
if (-not $token) { throw "Could not retrieve access token." }

$headers = @{
  Authorization = "Bearer $token"
}

$deploymentsUrl = "$BaseUrl/amc/application-manager/api/v2/organizations/$OrgId/environments/$EnvId/deployments"
$deployments = Invoke-RestMethod -Method Get -Uri $deploymentsUrl -Headers $headers

$items = @($deployments.items)
if ($items.Count -eq 0) {
  Write-Host "No deployments returned for org/env."
  exit 0
}

$target = $items | Where-Object {
  $n = if ($_.PSObject.Properties["name"]) { $_.name } else { $null }
  $an = if ($_.PSObject.Properties["application"] -and $_.application -and $_.application.PSObject.Properties["name"]) { $_.application.name } else { $null }
  ($n -eq $AppName) -or ($an -eq $AppName)
} | Select-Object -First 1

if (-not $target) {
  Write-Host "Deployment not found for app '$AppName'."
  Write-Host "Available deployments:"
  $items | ForEach-Object { Write-Host "- $($_.name)" }
  exit 1
}

$deploymentId = $target.id
Write-Host "Found deployment id: $deploymentId"

$detailUrl = "$BaseUrl/amc/application-manager/api/v2/organizations/$OrgId/environments/$EnvId/deployments/$deploymentId"
$detail = Invoke-RestMethod -Method Get -Uri $detailUrl -Headers $headers

Write-Host "Status: $($detail.status)"
if ($detail.PSObject.Properties["target"]) {
  if ($detail.target.PSObject.Properties["targetId"]) {
    Write-Host "Target: $($detail.target.targetId)"
  } else {
    Write-Host "Target: $($detail.target)"
  }
}
if ($detail.PSObject.Properties["lastModifiedDate"]) {
  Write-Host "Last modified: $($detail.lastModifiedDate)"
}

if ($detail.PSObject.Properties["failureCause"] -and $detail.failureCause) {
  Write-Host "Failure cause: $($detail.failureCause)"
}

if ($detail.PSObject.Properties["application"] -and $detail.application -and $detail.application.PSObject.Properties["status"]) {
  Write-Host "Application status: $($detail.application.status)"
}
