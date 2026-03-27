param(
  [Parameter(Mandatory = $true)][string]$SecurePropertiesToolJar,
  [Parameter(Mandatory = $true)][string]$PlainText,
  [Parameter(Mandatory = $true)][string]$MuleKey
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $SecurePropertiesToolJar)) {
  throw "Secure properties tool jar not found: $SecurePropertiesToolJar"
}

$cmd = @(
  "java", "-cp", $SecurePropertiesToolJar,
  "com.mulesoft.tools.SecurePropertiesTool",
  "string", "encrypt",
  "Blowfish",
  $PlainText,
  $MuleKey
)

Write-Host "Encrypting value using Mule Secure Properties Tool..."
$encrypted = & $cmd[0] $cmd[1..($cmd.Length - 1)]
Write-Host "Encrypted value (use in config-<env>-secure.properties):"
Write-Host "![${encrypted}]"
