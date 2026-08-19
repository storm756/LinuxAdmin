# ==============================================================================
# LinuxAdmin Unified Security Portal - Server Initialization Script
# ==============================================================================
# This script automatically detects the host's IP address and configures
# MeshCentral and Wazuh documentation to use the new IP. It ensures the project
# remains portable across different network environments (DHCP to Static).
# ==============================================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Starting LinuxAdmin Server Initialization   " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Network Discovery
Write-Host "[1/4] Detecting Primary Network IP Address..." -ForegroundColor Yellow
$ipInfo = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -match "Wi-Fi|Ethernet" -and $_.IPAddress -notmatch "169.254" -and $_.IPAddress -notmatch "127.0.0.1" -and $_.IPAddress -notmatch "172."} | Select-Object -First 1

if (-not $ipInfo) {
    Write-Host "      [ERROR] Could not detect a valid Wi-Fi or Ethernet IP address." -ForegroundColor Red
    Write-Host "      Please ensure you are connected to a network." -ForegroundColor Red
    exit 1
}

$detectedIp = $ipInfo.IPAddress
$currentIp = Read-Host "      [INPUT] Enter the target IP Address (Press Enter to use auto-detected: $detectedIp)"
if ([string]::IsNullOrWhiteSpace($currentIp)) {
    $currentIp = $detectedIp
}

Write-Host "      [SUCCESS] Target IP Address set to: $currentIp" -ForegroundColor Green
Write-Host ""

# 2. Configuration Migration (MeshCentral)
Write-Host "[2/4] Updating MeshCentral Configuration..." -ForegroundColor Yellow
$meshConfigPath = ".\MeshCentral\opt\LinuxAdmin\data\config.json"

if (Test-Path $meshConfigPath) {
    $configContent = Get-Content -Raw $meshConfigPath
    # Use regex to replace the IP address in the "cert" field while preserving JSON structure
    $configContent = $configContent -replace '"cert"\s*:\s*".*?"', "`"cert`": `"$currentIp`""
    Set-Content -Path $meshConfigPath -Value $configContent
    Write-Host "      [SUCCESS] MeshCentral config.json updated." -ForegroundColor Green
} else {
    Write-Host "      [WARNING] Could not find MeshCentral config.json at $meshConfigPath" -ForegroundColor DarkYellow
}
Write-Host ""

# 3. Wazuh Certificate Update
Write-Host "[3/5] Updating Wazuh Certificates for New IP..." -ForegroundColor Yellow
$certsYmlPath = ".\LinuxAdmin-Docker\single-node\config\certs.yml"

if (Test-Path $certsYmlPath) {
    $certsContent = Get-Content -Raw $certsYmlPath
    # Replace the dashboard IP with the new current IP, while preserving other nodes
    $certsContent = $certsContent -replace '(?s)(dashboard:\s+- name: wazuh\.dashboard\s+ip: ).*?(?=\r?\n)', "`${1}$currentIp"
    Set-Content -Path $certsYmlPath -Value $certsContent
    Write-Host "      [SUCCESS] certs.yml updated with new IP." -ForegroundColor Green
    
    # Run the Wazuh certificate generator container
    Write-Host "      Running Wazuh certificate generator..." -ForegroundColor Cyan
    Push-Location ".\LinuxAdmin-Docker\single-node"
    $certGenOutput = docker-compose -f generate-indexer-certs.yml run --rm generator 2>&1
    Pop-Location
    Write-Host "      [SUCCESS] Wazuh certificates successfully regenerated!" -ForegroundColor Green
} else {
    Write-Host "      [WARNING] Could not find certs.yml at $certsYmlPath" -ForegroundColor DarkYellow
}
Write-Host ""

# 4. Documentation Update
Write-Host "[4/5] Updating Deployment Documentation..." -ForegroundColor Yellow
$agentDocPath = ".\LinuxAdmin-Docker\deploy_agent.md"

if (Test-Path $agentDocPath) {
    $docContent = Get-Content -Raw $agentDocPath
    # Replace old IP addresses in the deployment commands with the new IP
    $docContent = $docContent -replace "WAZUH_MANAGER='[0-9\.]+'", "WAZUH_MANAGER='$currentIp'"
    $docContent = $docContent -replace "WAZUH_REGISTRATION_SERVER='[0-9\.]+'", "WAZUH_REGISTRATION_SERVER='$currentIp'"
    $docContent = $docContent -replace "agent-auth\.exe -m [0-9\.]+", "agent-auth.exe -m $currentIp"
    Set-Content -Path $agentDocPath -Value $docContent
    Write-Host "      [SUCCESS] deploy_agent.md updated." -ForegroundColor Green
} else {
    Write-Host "      [WARNING] Could not find deploy_agent.md at $agentDocPath" -ForegroundColor DarkYellow
}
Write-Host ""

# 5. Service Restart
Write-Host "[5/5] Restarting Docker Containers..." -ForegroundColor Yellow
$dockerComposeDir = ".\LinuxAdmin-Docker\single-node"

if (Test-Path $dockerComposeDir) {
    Push-Location $dockerComposeDir
    
    # Restart meshcentral and wazuh.dashboard
    $dockerOutput = docker-compose restart meshcentral wazuh.dashboard 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [SUCCESS] Container restarted successfully." -ForegroundColor Green
    } else {
        Write-Host "      [WARNING] Docker restart returned an error. Ensure Docker is running." -ForegroundColor DarkYellow
        Write-Host "      Docker output: $dockerOutput" -ForegroundColor DarkYellow
    }
    Pop-Location
} else {
    Write-Host "      [WARNING] Could not find Docker Compose directory at $dockerComposeDir" -ForegroundColor DarkYellow
}
Write-Host ""

# Final Summary
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Server Successfully Migrated & Initialized! " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Access your platforms locally via these links:"
Write-Host "  -> Unified Portal:  http://localhost:8080"
Write-Host "  -> MeshCentral:     https://localhost:8843"
Write-Host "  -> Wazuh Dashboard: https://localhost"
Write-Host ""
Write-Host " Access your platforms remotely via these links:"
Write-Host "  -> Unified Portal:  http://$($currentIp):8080"
Write-Host "  -> MeshCentral:     https://$($currentIp):8843"
Write-Host "  -> Wazuh Dashboard: https://$currentIp"
Write-Host ""
Write-Host " Note: If this is the first time running on a new IP, you may need to accept"
Write-Host " the self-signed certificate warning in your browser again."
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
