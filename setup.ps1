$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$serverDir = Join-Path $root "server"
$pluginsDir = Join-Path $serverDir "plugins"

New-Item -ItemType Directory -Force -Path $serverDir, $pluginsDir | Out-Null

# Paper 1.12.2 (latest) via PaperMC v2 API
$paperJar = Join-Path $serverDir "paper-1.12.2.jar"
if (-not (Test-Path $paperJar)) {
  $paperProject = Invoke-RestMethod -Uri "https://api.papermc.io/v2/projects/paper/versions/1.12.2"
  $paperBuild = $paperProject.builds | Select-Object -Last 1
  $paperBuildInfo = Invoke-RestMethod -Uri ("https://api.papermc.io/v2/projects/paper/versions/1.12.2/builds/{0}" -f $paperBuild)
  $paperFile = $paperBuildInfo.downloads.application.name
  $paperUrl = ("https://api.papermc.io/v2/projects/paper/versions/1.12.2/builds/{0}/downloads/{1}" -f $paperBuild, $paperFile)
  Invoke-WebRequest -Uri $paperUrl -OutFile $paperJar
}

# EaglercraftXServer + EaglerWeb from GitHub releases
$ghHeaders = @{ "User-Agent" = "eaglercraft-setup" }
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/lax1dude/eaglerxserver/releases/latest" -Headers $ghHeaders
$assets = $release.assets

function Get-AssetUrl([string]$name) {
  $asset = $assets | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if ($null -eq $asset) { return $null }
  return $asset.browser_download_url
}

$eaglerServerUrl = Get-AssetUrl "EaglerXServer.jar"
if (-not $eaglerServerUrl) {
  throw "EaglerXServer.jar not found in the latest release assets."
}
Invoke-WebRequest -Uri $eaglerServerUrl -OutFile (Join-Path $pluginsDir "EaglerXServer.jar")

$eaglerWebUrl = Get-AssetUrl "EaglerWeb.jar"
if ($eaglerWebUrl) {
  Invoke-WebRequest -Uri $eaglerWebUrl -OutFile (Join-Path $pluginsDir "EaglerWeb.jar")
}

# AuthMeReloaded from GitHub releases (avoid Cloudflare blocking)
$authRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/AuthMe/AuthMeReloaded/releases/latest" -Headers $ghHeaders
$authAsset = $authRelease.assets | Where-Object {
  $_.name -match '\.jar$' -and $_.name -notmatch 'sources|javadoc'
} | Select-Object -First 1
if ($null -eq $authAsset) {
  throw "AuthMeReloaded jar not found in latest GitHub release."
}
Invoke-WebRequest -Uri $authAsset.browser_download_url -OutFile (Join-Path $pluginsDir $authAsset.name)

# Ensure offline-mode for AuthMe
$serverProps = Join-Path $serverDir "server.properties"
if (-not (Test-Path $serverProps)) {
  @"
# Eaglercraft setup
online-mode=false
"@ | Set-Content -Path $serverProps -Encoding ASCII
}

Write-Host "Download complete."
