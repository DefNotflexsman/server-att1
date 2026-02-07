$root = Split-Path -Parent $PSScriptRoot
$webDir = Join-Path $root "web"

if (-not (Test-Path $webDir)) {
  Write-Error "Missing $webDir"
  exit 1
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Error "Python not found. Install Python or host the web files another way."
  exit 1
}

Set-Location $webDir
python -m http.server 8080
