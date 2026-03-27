param(
  [Parameter(Mandatory = $true)][string]$ConnectedAppClientId,
  [Parameter(Mandatory = $true)][string]$ConnectedAppClientSecret,
  [Parameter(Mandatory = $true)][string]$OrgId,
  [Parameter(Mandatory = $true)][string]$EnvId,
  [string]$ExchangeGroupId = "",
  [Parameter(Mandatory = $true)][string]$ExchangeAssetId,
  [Parameter(Mandatory = $true)][string]$ExchangeAssetVersion,
  [Parameter(Mandatory = $true)][string]$ApiInstanceLabel,
  [string]$ApiInstanceType = "http",
  [string]$MuleVersion4Proxy = "4.6.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $ExchangeGroupId -or $ExchangeGroupId.Trim().Length -eq 0) {
  $ExchangeGroupId = $OrgId
}

function Get-Token {
  $tokenResp = Invoke-RestMethod -Method Post -Uri "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" -ContentType "application/json" -Body (@{
    client_id     = $ConnectedAppClientId
    client_secret = $ConnectedAppClientSecret
    grant_type    = "client_credentials"
  } | ConvertTo-Json)
  return $tokenResp.access_token
}

function Invoke-AnypointApi {
  param(
    [string]$Method,
    [string]$Uri,
    [object]$Body = $null
  )
  $headers = @{
    Authorization   = "Bearer $script:Token"
    "X-ANYPNT-ORG-ID" = $OrgId
    "X-ANYPNT-ENV-ID" = $EnvId
  }
  if ($null -ne $Body) {
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body ($Body | ConvertTo-Json -Depth 10)
  }
  return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
}

$script:Token = Get-Token
Write-Host "Token acquired."

# 1) Create API Manager instance from Exchange asset.
$createApiUri = "https://anypoint.mulesoft.com/apimanager/xapi/v1/organizations/$OrgId/environments/$EnvId/apis"
$apiResp = Invoke-AnypointApi -Method Post -Uri $createApiUri -Body @{
  endpoint = @{
    deploymentType = "CH"
    uri = "https://american-airlines-info-app-dev-jjvb3b.5sc6y6-3.usa-e2.cloudhub.io"
    proxyUri = "http://0.0.0.0:8081"
    isCloudHub = $true
    muleVersion4OrAbove = $true
    muleVersion4Proxy = $MuleVersion4Proxy
  }
  instanceLabel = $ApiInstanceLabel
  spec = @{
    groupId = $ExchangeGroupId
    assetId = $ExchangeAssetId
    version = $ExchangeAssetVersion
  }
}
$apiId = $apiResp.id
Write-Host "API Manager instance created. apiId=$apiId"

# 2) Apply Basic Authentication policy.
$policyUri = "https://anypoint.mulesoft.com/apimanager/xapi/v1/organizations/$OrgId/environments/$EnvId/apis/$apiId/policies"
$null = Invoke-AnypointApi -Method Post -Uri $policyUri -Body @{
  policyTemplateId = "basic-authentication"
  configurationData = @{
    credentialsOrigin = "customExpression"
    usernameExpression = "#[attributes.headers.'authorization' default '']"
    passwordExpression = "#[attributes.headers.'authorization' default '']"
  }
}
Write-Host "Basic Authentication policy applied."

# 3) Create SLA tiers.
$slaUri = "https://anypoint.mulesoft.com/apimanager/api/v1/organizations/$OrgId/environments/$EnvId/apis/$apiId/tiers"
$null = Invoke-AnypointApi -Method Post -Uri $slaUri -Body @{
  name = "Bronze"
  limits = @(@{ timePeriodInMilliseconds = 60000; maximumRequests = 100 })
}
$null = Invoke-AnypointApi -Method Post -Uri $slaUri -Body @{
  name = "Gold"
  limits = @(@{ timePeriodInMilliseconds = 60000; maximumRequests = 2000 })
}
Write-Host "SLA tiers Bronze/Gold created."

Write-Host "Next: create API client app and contract in API Manager UI (or with app-management APIs tied to your org's governance model)."
