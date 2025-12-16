# SOC-in-a-Box

> Single-node Security Operations Center with AI-powered alert enrichment.
> Deploys Wazuh + DFIR-IRIS + Ollama-based AI module via Ansible.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Ubuntu 22.04 Server                         │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │     Wazuh       │  │   DFIR-IRIS     │  │   AI Stack      │ │
│  │  (Single-node)  │  │  (Docker)       │  │  (Docker)       │ │
│  │                 │  │                 │  │                 │ │
│  │ • Manager       │  │ • Web UI        │  │ • FastAPI       │ │
│  │ • Indexer       │  │ • PostgreSQL    │  │ • Ollama        │ │
│  │ • Dashboard     │  │ • RabbitMQ      │  │ • llama3.2      │ │
│  │                 │  │                 │  │                 │ │
│  │ Port: 443       │  │ Port: 8444      │  │ Port: 8085      │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │          │
│           └────────────────────┼────────────────────┘          │
│                                │                               │
│                    ┌───────────▼───────────┐                   │
│                    │  Integration Layer    │                   │
│                    │  (Wazuh → AI → IRIS)  │                   │
│                    └───────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites (on your laptop/control machine)

1. **Ansible 2.14+** with Python 3.10+
   ```bash
   # Ubuntu/Debian (or WSL)
   sudo apt update && sudo apt install -y ansible python3-pip

   # macOS
   brew install ansible

   # Install required Ansible collections
   ansible-galaxy collection install ansible.posix community.general

   # Verify
   ansible --version
   ```

2. **SSH access** to Ubuntu 22.04 target server (password auth OK)

3. **WSL Users (Windows)**: If running from WSL on a Windows filesystem (`/mnt/c/...`),
   Ansible will ignore `ansible.cfg` due to world-writable directory permissions.
   **Workaround**: Set the config path explicitly:
   ```bash
   export ANSIBLE_CONFIG=/mnt/c/Users/YourUser/path/to/soc-in-a-box/ansible/ansible.cfg
   ```
   Or copy the project to a native Linux path (e.g., `~/soc-in-a-box`).

4. **Target server requirements**:
   - Ubuntu 22.04 LTS (fresh install recommended)
   - 16GB RAM minimum
   - 50GB disk minimum
   - SSH enabled with password authentication

### Installation

1. **Clone this repository**:
   ```bash
   git clone <repo-url>
   cd soc-in-a-box
   ```

2. **Configure inventory**:
   ```bash
   cp ansible/inventory/hosts.ini.example ansible/inventory/hosts.ini
   # Edit hosts.ini with your server IP
   ```

3. **Review and adjust variables** (optional):
   ```bash
   # Edit defaults if needed
   nano ansible/inventory/group_vars/all.yml
   ```

4. **Run the deployment**:
   ```bash
   cd ansible
   ansible-playbook playbooks/deploy_server.yml \
     --ask-pass \
     --ask-become-pass
   ```

   Enter SSH password and sudo password when prompted.

5. **Verify deployment**:
   ```bash
   ../scripts/healthcheck.sh <SERVER_IP>
   ```

## Access Points

| Service | URL | Default Port |
|---------|-----|--------------|
| Wazuh Dashboard | `https://<SERVER_IP>:443` | 443 |
| DFIR-IRIS | `https://<SERVER_IP>:8444` | 8444 |
| AI Module Health | `http://<SERVER_IP>:8085/health` | 8085 |

> **Note**: All services use self-signed certificates in dev mode. Accept the browser warning.

## Default Credentials

**IMPORTANT**: Passwords are NOT stored in this repository.

### Wazuh
- Generated on first install
- Location on server: `/var/ossec/etc/wazuh-passwords.txt`
- Or check Ansible output

### DFIR-IRIS
- Admin password printed on first boot
- Retrieve: `docker compose logs app | grep "create_safe_admin"`

### Demo Password
For testing, set `DEMO_ADMIN_PASSWORD` environment variable before running Ansible:
```bash
export DEMO_ADMIN_PASSWORD="YourSecurePassword123!"
ansible-playbook playbooks/deploy_server.yml --ask-pass --ask-become-pass
```

## Firewall Exposure Modes

Configure via `exposure` variable in `group_vars/all.yml`:

### `exposure: lan` (default)
- Services accessible only from private networks (10.x, 172.16.x, 192.168.x)
- SSH allowed from anywhere
- Recommended for internal testing

### `exposure: public`
- Services accessible from internet
- Basic auth can be enabled for additional protection
- Use only if you understand the risks

## Port Reference

| Port | Service | Protocol | Notes |
|------|---------|----------|-------|
| 22 | SSH | TCP | Always allowed |
| 443 | Wazuh Dashboard | HTTPS | Main Wazuh UI |
| 1514 | Wazuh Agent | TCP | Agent communication |
| 1515 | Wazuh Registration | TCP | Agent registration |
| 8444 | DFIR-IRIS | HTTPS | Incident response UI |
| 8085 | AI Module | HTTP | Internal enrichment API |
| 9200 | Wazuh Indexer | HTTPS | Internal only |
| 11434 | Ollama | HTTP | **Internal only, never exposed** |

## Project Structure

```
soc-in-a-box/
├── README.md
├── docs/
│   ├── sources.md          # Official documentation links
│   ├── versions.md         # Pinned component versions
│   ├── acceptance.md       # Test criteria per milestone
│   ├── architecture.md     # Detailed architecture (TODO)
│   ├── troubleshooting.md  # Common issues (TODO)
│   └── demo_scenarios.md   # Demo walkthroughs (TODO)
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.ini.example
│   │   └── group_vars/all.yml
│   ├── roles/
│   │   ├── common_base/
│   │   ├── firewall_ufw/
│   │   ├── docker_engine/
│   │   ├── wazuh_single/
│   │   ├── iris_stack/
│   │   └── ai_stack/
│   └── playbooks/
│       ├── deploy_server.yml
│       └── deploy_endpoints.yml (later)
├── docker/
│   ├── iris/
│   │   ├── compose.yml
│   │   └── .env.example
│   └── ai/
│       ├── compose.yml
│       └── .env.example
├── ai-module/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── .env.example
│   └── app/
│       ├── main.py
│       ├── llm/
│       └── enrich/
├── wazuh-custom/
│   ├── integrations/
│   ├── decoders/
│   └── rules/
└── scripts/
    └── healthcheck.sh
```

## Troubleshooting

### Ansible connection issues
```bash
# Test SSH connectivity
ssh user@<SERVER_IP>

# Test Ansible ping
ansible all -i inventory/hosts.ini -m ping --ask-pass
```

### Service not starting
```bash
# Check service status on server
sudo systemctl status wazuh-manager
docker compose -f /opt/iris/docker-compose.yml logs
```

### Certificate warnings
This is expected with self-signed certificates. For production, configure proper TLS.

## Version Information

See [docs/versions.md](docs/versions.md) for pinned versions:
- Wazuh: 4.14.1
- DFIR-IRIS: v2.4.24
- Ollama: 0.5.13
- Llama model: llama3.2:3b (default) / llama3.2:1b (fallback)

## License

MIT License - See LICENSE file.

## Contributing

1. Check [docs/sources.md](docs/sources.md) for official documentation
2. Follow version pinning policy in [docs/versions.md](docs/versions.md)
3. Update [docs/acceptance.md](docs/acceptance.md) with test results
