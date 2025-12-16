# Acceptance Criteria & Test Plan

> This document defines the acceptance criteria for each milestone.
> Updated: 2024-12-14

## Milestone 0 — Discovery + Decisions + Version Plan

### Acceptance Criteria
- [x] `docs/sources.md` exists with official links for all components
- [x] `docs/versions.md` exists with pinned versions and dates
- [x] `docs/acceptance.md` exists (this file)
- [ ] No deployment code exists yet

### Verification
```bash
ls -la docs/
# Should show: sources.md, versions.md, acceptance.md
```

---

## Milestone 1 — Repo Bootstrap + Ansible Skeleton

### Acceptance Criteria
- [ ] Full repo structure exists per specification
- [ ] README.md has prerequisites and quickstart
- [ ] `ansible/inventory/hosts.ini.example` exists (no passwords)
- [ ] `ansible/inventory/group_vars/all.yml` has defaults
- [ ] `scripts/healthcheck.sh` skeleton exists

### Verification
```bash
tree -L 3 soc-in-a-box/
cat README.md | head -50
```

---

## Milestone 2 — Base OS + UFW + Docker

### Acceptance Criteria
- [ ] Ansible roles: common_base, firewall_ufw, docker_engine
- [ ] `deploy_server.yml` runs these roles
- [ ] Idempotent: 2nd run shows no changes
- [ ] Docker installed and working
- [ ] UFW configured with correct exposure mode

### Verification
```bash
# On target server:
docker --version
docker compose version
sudo ufw status verbose
```

---

## Milestone 3 — Wazuh Single-Node

### Acceptance Criteria
- [ ] Wazuh installed via wazuh-ansible v4.14.1
- [ ] All services running (manager, indexer, dashboard)
- [ ] Dashboard accessible at https://<IP>:443
- [ ] No crash loops in services

### Verification
```bash
# On target server:
systemctl status wazuh-manager
systemctl status wazuh-indexer
systemctl status wazuh-dashboard
curl -k https://localhost:443 | head -20
```

---

## Milestone 4 — DFIR-IRIS

### Acceptance Criteria
- [ ] IRIS running via Docker Compose
- [ ] Version v2.4.24 pinned
- [ ] UI accessible at https://<IP>:8444
- [ ] Admin password documented (how to retrieve from logs)

### Verification
```bash
# On target server:
docker compose -f /opt/iris/docker-compose.yml ps
curl -k https://localhost:8444/api/ping
```

---

## Milestone 5 — Ollama + AI Module

### Acceptance Criteria
- [ ] Ollama running (internal network only, NOT exposed)
- [ ] AI module running on port 8085
- [ ] `/health` endpoint returns 200
- [ ] Can communicate with Ollama internally

### Verification
```bash
# On target server:
curl http://localhost:8085/health
# Ollama should NOT be accessible from outside:
# curl http://<IP>:11434  # Should timeout/refuse
```

---

## Milestone 6 — IRIS API Integration

### Acceptance Criteria
- [ ] AI module can create cases in IRIS
- [ ] AI module can add notes to cases
- [ ] Secrets not in git (only .env.example)

### Verification
```bash
# Test POST /analyze with mock payload
curl -X POST http://localhost:8085/analyze \
  -H "Content-Type: application/json" \
  -d '{"alert_id": "test-001", "rule_level": 12, "description": "Test alert"}'
# Should create case in IRIS
```

---

## Milestone 7 — Wazuh → AI Integration

### Acceptance Criteria
- [ ] Custom integration script exists
- [ ] Filters by severity level
- [ ] Logs results properly
- [ ] Test data payloads work

### Verification
```bash
# Run with test payload
python3 /var/ossec/integrations/ai_enrich.py --test
```

---

## Milestone 8 — Custom Rules + Sample Logs

### Acceptance Criteria
- [ ] Custom decoders for OpenEDR/auditd
- [ ] Custom rules trigger on test data
- [ ] End-to-end: test log → alert → AI → IRIS case
- [ ] healthcheck.sh validates full pipeline

### Verification
```bash
./scripts/healthcheck.sh --full-pipeline
```

---

## Milestone 9 — Endpoint Automation + Demo

### Acceptance Criteria
- [ ] Windows agent deployment playbook
- [ ] Linux agent deployment playbook
- [ ] Demo scenarios documented
- [ ] Smoke tests pass

### Verification
```bash
./scripts/healthcheck.sh --with-endpoints
```

---

## Global Quality Gates

### Every Milestone Must:
1. Pass `scripts/healthcheck.sh` for that milestone
2. Have no uncommitted changes to secrets
3. Be idempotent (can run twice without errors)
4. Update this acceptance.md with results
