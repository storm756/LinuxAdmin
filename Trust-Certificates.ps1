# ==============================================================================
# LinuxAdmin Unified Security Portal - Certificate Trust Automation
# ==============================================================================
# This script imports the local Wazuh and MeshCentral Root Certificates into
# the Windows Trusted Root Certification Authorities store to permanently bypass
# browser SSL warnings.
# ==============================================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " LinuxAdmin Certificate Trust Initialization " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we are in the correct directory (Admin prompts often start in System32)
Set-Location $PSScriptRoot

# Paths to the generated Root CA certificates
$meshRootPath = ".\MeshCentral\opt\LinuxAdmin\data\root-cert-public.crt"
$wazuhRootPath = ".\LinuxAdmin-Docker\single-node\config\wazuh_indexer_ssl_certs\root-ca.pem"

$successCount = 0

# 1. MeshCentral Certificate
Write-Host "[1/2] Importing MeshCentral Root Certificate..." -ForegroundColor Yellow
if (Test-Path $meshRootPath) {
    try {
        Import-Certificate -FilePath $meshRootPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
        Write-Host "      [SUCCESS] MeshCentral Root CA Trusted." -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "      [ERROR] Failed to import MeshCentral cert. Are you running as Administrator?" -ForegroundColor Red
        Write-Host "      Details: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "      [WARNING] MeshCentral root certificate not found at $meshRootPath" -ForegroundColor DarkYellow
}
Write-Host ""

# 2. Wazuh Certificate
Write-Host "[2/2] Importing Wazuh Root Certificate..." -ForegroundColor Yellow
if (Test-Path $wazuhRootPath) {
    try {
        Import-Certificate -FilePath $wazuhRootPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
        Write-Host "      [SUCCESS] Wazuh Root CA Trusted." -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "      [ERROR] Failed to import Wazuh cert. Are you running as Administrator?" -ForegroundColor Red
        Write-Host "      Details: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "      [WARNING] Wazuh root certificate not found at $wazuhRootPath" -ForegroundColor DarkYellow
}
Write-Host ""

Write-Host "=============================================" -ForegroundColor Cyan
if ($successCount -eq 2) {
    Write-Host " Setup Complete! Both certificates are trusted." -ForegroundColor Green
    Write-Host " Please completely close and reopen your browser" -ForegroundColor Green
    Write-Host " for the changes to take effect." -ForegroundColor Green
} else {
    Write-Host " Setup finished with some errors." -ForegroundColor DarkYellow
}
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host 'Press Enter to exit...'; Read-Host | Out-Null
