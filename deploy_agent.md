# Remote Deployment Guide: MeshCentral & Wazuh

This guide documents the steps taken to troubleshoot and successfully deploy the Wazuh security agent to a target endpoint using MeshCentral for remote management.

## 1. Network Configuration & Agent Re-Baking
**Problem:** The host machine's IP address shifted (from `10.22.10.103` to `10.22.12.148`), breaking the connection for the previously generated MeshCentral agents.
**Solution:** Updated the MeshCentral configuration on the host to reflect the new IP (`10.22.12.148`) and regenerated a new MeshCentral Agent executable. 

## 2. Remote IT Control Establishment
Transferred the freshly baked MeshCentral Agent to the target PC (`DESKTOP-O1KLISG`) and executed it. This instantly established a secure reverse-tunnel, providing full remote control (Desktop, Terminal, and Files) from the host browser.

## 3. Silent Wazuh Installation
Using the MeshCentral **Terminal** tab, the following PowerShell command was executed remotely to silently download and install the Wazuh agent in the background:
```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi -OutFile ${env:tmp}\wazuh-agent.msi
msiexec.exe /i ${env:tmp}\wazuh-agent.msi /q WAZUH_MANAGER='10.22.12.148' WAZUH_REGISTRATION_SERVER='10.22.12.148'
```

## 4. Configuration Conflict Troubleshooting
**Problem:** The Wazuh agent failed to appear in the dashboard. Remote inspection of `ossec.log` revealed the agent was attempting to connect to the old IP (`10.22.10.116`). The MSI installer had detected a legacy Wazuh installation and preserved the old `ossec.conf` file.
**Solution:** Using the MeshCentral **Files** tab, `C:\Program Files (x86)\ossec-agent\ossec.conf` was modified remotely:
- Updated the server `<address>` to `10.22.12.148`.
- Removed an obsolete `<enrollment>` block that was demanding assignment to a non-existent group (`TerritorialArmy`), which was causing the server to reject the connection with an "Invalid Group" error.

## 5. Security Key Authentication
To bypass the auto-enrollment errors and forcefully register the agent, the built-in authentication tool was run via the remote terminal:
```powershell
cd "C:\Program Files (x86)\ossec-agent"
.\agent-auth.exe -m 10.22.12.148
```
*Result: Valid key received.*

## 6. Resolving Server-Side Hung Connections
**Problem:** During rapid `net stop` and `net start` troubleshooting cycles, the Wazuh Manager blocked the connection with an `"Agent key already in use"` error, interpreting the rapid reconnection as a potential session hijack.
**Solution:** Restarted the Wazuh Manager Docker container (`docker restart single-node-wazuh.manager-1`) to forcefully clear the hung connection state.

## 7. Final Verification
Executed `net stop WazuhSvc; net start WazuhSvc` one final time on the target PC. The agent successfully connected using its new key and immediately registered as **Active** in the Unified Security Portal dashboard.
