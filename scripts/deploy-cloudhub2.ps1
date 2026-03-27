param(
  [string]$MuleEnv = "dev",
  [string]$MuleKey = "cursur12345678",
  [string]$ApiAutodiscoveryId = "",
  [string]$PlatformClientId = "",
  [string]$PlatformClientSecret = "",
  [string]$SettingsFile = ".\\munit-settings.xml",
  [switch]$SkipTests = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $env:ANYPOINT_CONNECTED_APP_CLIENT_ID -or -not $env:ANYPOINT_CONNECTED_APP_CLIENT_SECRET) {
  throw "Missing Connected App env vars. Set ANYPOINT_CONNECTED_APP_CLIENT_ID and ANYPOINT_CONNECTED_APP_CLIENT_SECRET first."
}

$extra = @()
if ($SkipTests) { $extra += "-DskipTests" }
if ($ApiAutodiscoveryId -and $ApiAutodiscoveryId.Trim().Length -gt 0) {
  $extra += "-Dapi.autodiscovery.id=$ApiAutodiscoveryId"
}
if ($PlatformClientId -and $PlatformClientId.Trim().Length -gt 0) {
  $extra += "-Danypoint.platform.client_id=$PlatformClientId"
}
if ($PlatformClientSecret -and $PlatformClientSecret.Trim().Length -gt 0) {
  $extra += "-Danypoint.platform.client_secret=$PlatformClientSecret"
}

$cmd = @(
  "mvn"
  "-s", $SettingsFile
  "-Pcloudhub-dev"
  "clean", "package", "mule:deploy"
  "-Danypoint.connectedAppClientId=$env:ANYPOINT_CONNECTED_APP_CLIENT_ID"
  "-Danypoint.connectedAppClientSecret=$env:ANYPOINT_CONNECTED_APP_CLIENT_SECRET"
  "-Dmule.env=$MuleEnv"
  "-Dmule.key=$MuleKey"
) + $extra

Write-Host "Executing: $($cmd -join ' ')"
& $cmd[0] $cmd[1..($cmd.Length - 1)]
