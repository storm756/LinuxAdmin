<#
.SYNOPSIS
  One-click setup for the LinuxAdmin Docker stack (Wazuh + MeshCentral).

.DESCRIPTION
  This script automatically extracts MeshCentral data, generates required
  SSL certificates for Wazuh, configures WSL settings, and starts the entire
  docker-compose stack.
#>

$ErrorActionPreference = "Stop"

$currentDir = Get-Location
$dockerDir = Join-Path $currentDir "LinuxAdmin-Docker\single-node"

Write-Host "=================================================="
Write-Host "  Starting LinuxAdmin Setup (Wazuh + MeshCentral) "
Write-Host "=================================================="

# 1. Extract MeshCentral Data if it doesn't exist
$meshDir = Join-Path $currentDir "MeshCentral"
$backupFile = Join-Path $currentDir "LinuxAdmin_backup.tar.gz"

if (-Not (Test-Path $meshDir)) {
    Write-Host "[1/4] Extracting MeshCentral backup..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $meshDir | Out-Null
    tar -xzvf $backupFile -C $meshDir
} else {
    Write-Host "[1/4] MeshCentral folder already exists, skipping extraction." -ForegroundColor Green
}

# 2. Generate Wazuh Certificates
Write-Host "[2/4] Generating Wazuh Indexer Certificates..." -ForegroundColor Cyan
Set-Location $dockerDir
docker-compose -f generate-indexer-certs.yml run --rm generator

# 3. Configure WSL Max Map Count
Write-Host "[3/4] Configuring Linux Kernel settings (vm.max_map_count)..." -ForegroundColor Cyan
wsl -d docker-desktop -u root sysctl -w vm.max_map_count=262144
$check = wsl -d docker-desktop -u root sysctl vm.max_map_count
Write-Host "Verified: $check" -ForegroundColor Green

# 4. Start the stack
Write-Host "[4/4] Starting the Docker Compose stack..." -ForegroundColor Cyan
docker-compose up -d

Write-Host "=================================================="
Write-Host "  Setup Complete! The containers are starting."
Write-Host "=================================================="
Write-Host "Wazuh Dashboard: https://localhost"
Write-Host "MeshCentral:     https://localhost:8843"
Write-Host "Please allow a few minutes for the Wazuh Indexer to initialize."

Set-Location $currentDir
