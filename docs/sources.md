# Official Documentation Sources

> This file tracks all official documentation sources used in this project.
> Updated: 2024-12-14

## Wazuh

### Main Documentation
- **Release Notes**: https://documentation.wazuh.com/current/release-notes/index.html
- **4.14.1 Release Notes**: https://documentation.wazuh.com/current/release-notes/release-4-14-1.html
- **Installation Guide**: https://documentation.wazuh.com/current/installation-guide/index.html
- **Deployment with Ansible**: https://documentation.wazuh.com/current/deployment-options/deploying-with-ansible/installation-guide.html

### wazuh-ansible
- **GitHub Repository**: https://github.com/wazuh/wazuh-ansible
- **Roles Documentation**: https://documentation.wazuh.com/current/deployment-options/deploying-with-ansible/roles/index.html
- **Variables Reference**: https://documentation.wazuh.com/current/deployment-options/deploying-with-ansible/reference.html
- **Password Management**: https://documentation.wazuh.com/current/user-manual/user-administration/password-management.html

#### Available Playbooks:
- `wazuh-aio.yml` — All-in-one (single-node): indexer + manager + dashboard
- `wazuh-distributed.yml` — Multi-node cluster
- `wazuh-agent.yml` — Agent only

#### Gotchas / Important Notes:
- Clone with specific tag: `git clone --branch v4.14.1 https://github.com/wazuh/wazuh-ansible.git`
- Main branch may contain bugs; always use tagged releases
- Requires Ansible 2.9+ with Python 3.8+
- **Default credentials**: Username `admin`, Password `changeme` (or see passwords file)
- Passwords file location: `/var/ossec/etc/wazuh-passwords.txt` (if exists)
- Password tool: `/usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh`
- For single-node: set `single_node: true` and `indexer_network_host: 127.0.0.1`
- Installation takes ~10-15 minutes on first run

---

## DFIR-IRIS

### Main Documentation
- **Quick Start**: https://docs.dfir-iris.org/latest/getting_started/
- **GitHub Repository**: https://github.com/dfir-iris/iris-web
- **Releases**: https://github.com/dfir-iris/iris-web/releases
- **v2.4.24 Release**: https://github.com/dfir-iris/iris-web/releases/tag/v2.4.24
- **Configuration**: https://docs.dfir-iris.org/latest/operations/configuration/
- **Upgrades**: https://docs.dfir-iris.org/latest/operations/upgrades/

#### Gotchas / Important Notes:
- Admin password is printed ONLY on first boot in logs
- Find password: `docker compose logs app | grep "WARNING :: post_init :: create_safe_admin"`
- If password not in logs, instance already started once (password was set)
- Must change POSTGRES_PASSWORD, SECURITY_KEY, SECURITY_PASSWORD_SALT in .env
- Default port is 443 (HTTPS); we use 8444 to avoid conflict with Wazuh

---

## Ollama

### Main Documentation
- **Official Docs**: https://docs.ollama.com
- **GitHub Repository**: https://github.com/ollama/ollama
- **API Reference**: https://github.com/ollama/ollama/blob/main/docs/api.md
- **Docker Hub**: https://hub.docker.com/r/ollama/ollama
- **Releases**: https://github.com/ollama/ollama/releases

### Llama 3.2 Model
- **Model Page**: https://ollama.com/library/llama3.2
- **All Tags**: https://ollama.com/library/llama3.2/tags
- **1B Variant**: https://ollama.com/library/llama3.2:1b
- **3B Variant**: https://ollama.com/library/llama3.2:3b

#### Gotchas / Important Notes:
- Default API port: 11434
- `/api/chat` for chat completions (streaming by default)
- `/api/generate` for text generation
- Model must be pulled before use: `ollama pull llama3.2`
- 3B model requires ~4GB RAM; 1B model requires ~2GB RAM
- For CPU-only: expect slower inference (10-30 tokens/sec on modern CPU)
- NEVER expose Ollama port (11434) publicly; use internal Docker network only

---

## Docker & Compose

### Official Documentation
- **Docker Install**: https://docs.docker.com/engine/install/ubuntu/
- **Compose Plugin**: https://docs.docker.com/compose/install/linux/
- **Compose File Reference**: https://docs.docker.com/compose/compose-file/

---

## Ubuntu / System

### Official Documentation
- **UFW Firewall**: https://help.ubuntu.com/community/UFW
- **Ubuntu 22.04 Server Guide**: https://ubuntu.com/server/docs

---

## Integration References

### Wazuh Custom Integrations
- **Custom Integration Docs**: https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/integration.html
- **Active Response**: https://documentation.wazuh.com/current/user-manual/capabilities/active-response/index.html

### IRIS API
- **API Documentation**: https://docs.dfir-iris.org/latest/operations/api/
