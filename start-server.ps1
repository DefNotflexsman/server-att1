$root = Split-Path -Parent $PSScriptRoot
$serverDir = Join-Path $root "server"
$jar = Join-Path $serverDir "paper-1.12.2.jar"

if (-not (Test-Path $jar)) {
  Write-Error "Missing $jar. Run scripts\\setup.ps1 first."
  exit 1
}

Set-Location $serverDir
& java -Xms1G -Xmx2G -jar $jar nogui
