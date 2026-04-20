Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$backend = Join-Path $root "backend"

Set-Location $backend

Write-Host "Subindo API em http://localhost:8080" -ForegroundColor Cyan
go run ./cmd/api
