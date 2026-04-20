Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$backend = Join-Path $root "backend"

Set-Location $backend

Write-Host "Criando admin local com as credenciais do backend/.env" -ForegroundColor Cyan
go run ./cmd/seed-admin
