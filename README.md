# LinuxAdmin Security Stack (Wazuh + MeshCentral)

This project contains a bundled installation of **Wazuh** (a powerful open-source security platform for threat detection and compliance) and **MeshCentral** (an open-source remote web-based management tool). 

By running this stack, you deploy a central server capable of monitoring endpoint security and providing remote administrative access to your organization's computers.

---

## 🚀 One-Click Quick Start (Recommended)

To get everything running on a new machine with a single command, we have provided a PowerShell setup script. 

**Prerequisites:**
1. Windows 10/11 or Windows Server.
2. [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running (with the WSL 2 backend enabled).
3. At least 8-16GB of RAM and ~50GB of free disk space.

**Setup Instructions:**
1. Open **PowerShell**.
2. Navigate to this directory (where `start.ps1` is located).
3. Run the script:
   ```powershell
   .\start.ps1
   ```
   *(Note: If you get an Execution Policy error, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` first).*

The script will automatically extract the MeshCentral database backup, generate all necessary SSL certificates for Wazuh, configure your Linux kernel memory limits within Docker, and spin up the unified Docker Compose stack.

---

## 🖥️ Accessing the Dashboards

Once the script finishes, wait 2-3 minutes for the Wazuh Indexer to fully initialize, then access your dashboards:

### Wazuh Dashboard
* **URL:** [https://localhost](https://localhost)
* **Default Username:** `admin`
* **Default Password:** `SecretPassword`

### MeshCentral Dashboard
* **URL:** [https://localhost:8843](https://localhost:8843)
* **Default Username:** `linuxadmin`
* **Default Password:** `SecretPassword` (or create a new account from the login page).

*(Note: You can safely bypass the "Not Secure" self-signed certificate warnings in your browser).*

---

## 🛠️ Manual Setup (Fallback Method)

If you prefer to run things manually or the script fails, follow these steps in PowerShell:

1. **Extract MeshCentral:**
   ```powershell
   mkdir MeshCentral
   tar -xzvf LinuxAdmin_backup.tar.gz -C MeshCentral
   ```

2. **Generate Wazuh Certificates:**
   ```powershell
   cd LinuxAdmin-Docker\single-node
   docker-compose -f generate-indexer-certs.yml run --rm generator
   ```

3. **Configure the Linux Kernel:**
   *(Wazuh's database requires a higher memory map limit).*
   ```powershell
   wsl -d docker-desktop -u root sysctl -w vm.max_map_count=262144
   ```

4. **Start the Stack:**
   ```powershell
   docker-compose up -d
   ```

## 🛑 Stopping the Stack

To stop the servers without losing any data, run:
```powershell
cd LinuxAdmin-Docker\single-node
docker-compose down
```
