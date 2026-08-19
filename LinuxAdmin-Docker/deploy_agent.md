# Remote Deployment Guide: MeshCentral & Wazuh

This guide documents the steps taken to troubleshoot and successfully deploy the Wazuh security agent to a target endpoint using MeshCentral for remote management.

## 1. Network Configuration & Agent Re-Baking
**Problem:** The host machine's IP address shifted (from `10.22.10.103` to `10.22.12.148`), breaking the connection for the previously generated MeshCentral agents.
**Solution:** Updated the MeshCentral configuration on the host to reflect the new IP (`10.22.12.148`) and regenerated a new MeshCentral Agent executable. 

## 2. Remote IT Control Establishment
Transferred the freshly baked MeshCentral Agent to the target PC (`DESKTOP-O1KLISG`) and executed it. This instantly established a secure reverse-tunnel, providing full remote control (Desktop, Terminal, and Files) from the host browser.

## 3. Silent Wazuh Installation (For New PCs)
Using the MeshCentral **Terminal** tab (which opens a classic `cmd.exe` by default), the following command was executed remotely to silently download, install, and configure the Wazuh agent in the background:
```cmd
curl.exe -o wazuh-agent.msi https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi && msiexec.exe /i wazuh-agent.msi /q WAZUH_MANAGER="10.22.12.92" WAZUH_REGISTRATION_SERVER="10.22.12.92" && net start WazuhSvc
```
*(Wait 15-30 seconds, and the new PC will appear as **Active** in the Wazuh Dashboard)*

## 4. Re-authenticating Existing Agents (For Old PCs)
**Problem:** PCs that already had Wazuh installed from a previous deployment attempt would connect to the new server IP (`10.22.12.92`), but the Wazuh Manager would reject their old security keys.
**Solution:** Using the MeshCentral **Terminal** tab, we forced the existing agents to request a brand new security key using the built-in `agent-auth` tool:

```cmd
cd "C:\Program Files (x86)\ossec-agent"
agent-auth.exe -m 10.22.12.92
net stop WazuhSvc && net start WazuhSvc
```
*Result: The agent outputs `Valid key received`, restarts its service, and immediately registers as **Active** in the unified portal.*

## 5. Security Key Authentication
To bypass the auto-enrollment errors and forcefully register the agent, the built-in authentication tool was run via the remote terminal:
```powershell
cd "C:\Program Files (x86)\ossec-agent"
.\agent-auth.exe -m 192.168.129.1
```
*Result: Valid key received.*

## 6. Resolving Server-Side Hung Connections
**Problem:** During rapid `net stop` and `net start` troubleshooting cycles, the Wazuh Manager blocked the connection with an `"Agent key already in use"` error, interpreting the rapid reconnection as a potential session hijack.
**Solution:** Restarted the Wazuh Manager Docker container (`docker restart single-node-wazuh.manager-1`) to forcefully clear the hung connection state.

## 7. Final Verification
Executed `net stop WazuhSvc; net start WazuhSvc` one final time on the target PC. The agent successfully connected using its new key and immediately registered as **Active** in the Unified Security Portal dashboard.
