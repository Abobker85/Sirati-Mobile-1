# Starts a Codemagic build through the REST API and follows it until it finishes.
#
#   pwsh tool/codemagic_build.ps1 -AppId <Codemagic app id> [-Workflow ios-testflight] [-Branch main]
#
# The app id is the long id in the Codemagic app URL (codemagic.io/app/<AppId>).
# The API token (Codemagic > Teams > Personal Account > Integrations > Codemagic API) is read from the
# CODEMAGIC_API_TOKEN environment variable, or typed into a hidden prompt. It is never written anywhere.
param(
  [Parameter(Mandatory = $true)][string]$AppId,
  [string]$Workflow = 'ios-testflight',
  [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'
$token = $env:CODEMAGIC_API_TOKEN
if (-not $token) {
  $secure = Read-Host 'Codemagic API token' -AsSecureString
  $token = [System.Net.NetworkCredential]::new('', $secure).Password
}
$headers = @{ 'x-auth-token' = $token; 'Content-Type' = 'application/json' }
$body = @{ appId = $AppId; workflowId = $Workflow; branch = $Branch } | ConvertTo-Json

$start = Invoke-RestMethod -Method Post -Uri 'https://api.codemagic.io/builds' -Headers $headers -Body $body
$buildId = $start.buildId
Write-Host "Started build $buildId ($Workflow on $Branch)"
Write-Host "https://codemagic.io/app/$AppId/build/$buildId"

$last = ''
while ($true) {
  Start-Sleep -Seconds 30
  $build = (Invoke-RestMethod -Method Get -Uri "https://api.codemagic.io/builds/$buildId" -Headers $headers).build
  $status = $build.status
  if ($status -ne $last) { Write-Host ("{0:HH:mm:ss}  {1}" -f (Get-Date), $status); $last = $status }
  if ($status -in 'finished', 'failed', 'canceled', 'skipped', 'timeout', 'warning') { break }
}
if ($status -ne 'finished') { Write-Error "Build ended with status: $status"; exit 1 }
Write-Host 'Build finished. When App Store Connect finishes processing, the build appears in TestFlight.'
