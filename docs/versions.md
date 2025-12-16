# Pinned Versions Registry

> All component versions are pinned here. NO "latest" tags allowed.
> Updated: 2024-12-14

## Core Components

| Component | Version | Date Pinned | Official Source |
|-----------|---------|-------------|-----------------|
| **Wazuh** | 4.14.1 | 2024-12-14 | [Release Notes](https://documentation.wazuh.com/current/release-notes/release-4-14-1.html) |
| **wazuh-ansible** | v4.14.1 | 2024-12-14 | [GitHub Tag](https://github.com/wazuh/wazuh-ansible/releases/tag/v4.14.1) |
| **DFIR-IRIS** | v2.4.24 | 2024-12-14 | [GitHub Release](https://github.com/dfir-iris/iris-web/releases/tag/v2.4.24) |
| **Ollama** | 0.5.13 | 2024-12-14 | [GitHub Release](https://github.com/ollama/ollama/releases/tag/v0.5.13) |

## AI Models

| Model | Tag | Size | Date Pinned | Official Source |
|-------|-----|------|-------------|-----------------|
| **Llama 3.2** (default) | llama3.2:3b | 2.0GB | 2024-12-14 | [Ollama Library](https://ollama.com/library/llama3.2:3b) |
| **Llama 3.2** (fallback) | llama3.2:1b | 1.3GB | 2024-12-14 | [Ollama Library](https://ollama.com/library/llama3.2:1b) |

## Docker Images

| Image | Tag | Date Pinned | Source |
|-------|-----|-------------|--------|
| ollama/ollama | 0.5.13 | 2024-12-14 | [Docker Hub](https://hub.docker.com/r/ollama/ollama) |
| python | 3.11-slim | 2024-12-14 | [Docker Hub](https://hub.docker.com/_/python) |

## System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Ubuntu | 22.04 LTS | 22.04 LTS |
| RAM | 16GB | 16GB+ |
| CPU | 4 cores | 8 cores |
| Disk | 50GB | 100GB+ |
| Docker | 24.0+ | Latest stable |
| Docker Compose | v2.20+ | Latest stable |
| Ansible | 2.14+ | 2.16+ |
| Python | 3.10+ | 3.11+ |

## Version Selection Rationale

### Wazuh 4.14.1
- Latest stable release (Nov 12, 2025)
- Includes hot reload feature for agent config
- Security and performance fixes over 4.14.0

### DFIR-IRIS v2.4.24
- Latest stable release
- Fixes permissions check ordering
- Security fix GHSA-qhqj-8qw6-wp8v

### Ollama 0.5.13
- Stable release with OLLAMA_CONTEXT_LENGTH support
- Good balance of features and stability
- Note: v0.13.x series exists but is newer/less tested

### Llama 3.2 (3B default, 1B fallback)
- 3B: Best performance for CPU-only setups under 16GB RAM
- 1B: Fallback if 3B is too slow/heavy
- Both support 128K context window
- Multilingual support (EN, DE, FR, IT, PT, HI, ES, TH)

---

## Update Policy

1. Check for updates monthly
2. Test new versions in staging before production
3. Update this file with every version change
4. Never use pre-release (rc, alpha, beta) versions in production
