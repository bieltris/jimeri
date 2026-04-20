Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$frontend = Join-Path $root "frontend"

Set-Location $frontend

Write-Host "Subindo Flutter Web em http://localhost:3000" -ForegroundColor Cyan
flutter run -d edge --web-port 3000
