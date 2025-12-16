#!/usr/bin/env bash
# =============================================================================
# SOC-in-a-Box Health Check Script
# =============================================================================
# Usage: ./healthcheck.sh <SERVER_IP> [OPTIONS]
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
#   2 - Usage error

# Don't use set -e as we handle errors ourselves
set -uo pipefail

# SSH credentials (optional - for remote checks)
SSH_USER="${SSH_USER:-}"
# Note: Removed BatchMode=yes to allow password authentication
# For non-interactive use, set up SSH keys
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    echo "Usage: $0 <SERVER_IP> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --ssh-user USER    SSH user for remote checks (enables detailed checks)"
    echo "  --milestone N      Only check specific milestone (2-9)"
    echo "  --full-pipeline    Test end-to-end: alert → AI → IRIS"
    echo "  --with-endpoints   Include endpoint agent checks"
    echo "  --help             Show this help"
    echo ""
    echo "Environment:"
    echo "  SSH_USER           Alternative way to set SSH user"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100                        # Basic port checks"
    echo "  $0 192.168.1.100 --ssh-user ubuntu      # Full checks with SSH"
    echo "  $0 192.168.1.100 --milestone 2          # Only M2 checks"
    exit 2
}

# Remote command execution (if SSH available)
run_remote() {
    local cmd=$1
    if [[ -n "$SSH_USER" ]]; then
        ssh $SSH_OPTS "$SSH_USER@$SERVER_IP" "$cmd" 2>/dev/null
        return $?
    else
        return 1
    fi
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((SKIPPED++))
}

log_info() {
    echo -e "[INFO] $1"
}

check_url() {
    local url=$1
    local description=$2
    local timeout=${3:-10}

    if curl -sk --connect-timeout "$timeout" --max-time "$timeout" "$url" > /dev/null 2>&1; then
        log_pass "$description"
        return 0
    else
        log_fail "$description"
        return 1
    fi
}

check_port() {
    local host=$1
    local port=$2
    local description=$3
    local timeout=${4:-5}

    # Use nc (netcat) for portability, fallback to /dev/tcp
    if command -v nc &>/dev/null; then
        if nc -z -w "$timeout" "$host" "$port" 2>/dev/null; then
            log_pass "$description"
            return 0
        else
            log_fail "$description"
            return 1
        fi
    else
        if timeout "$timeout" bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
            log_pass "$description"
            return 0
        else
            log_fail "$description"
            return 1
        fi
    fi
}

# =============================================================================
# Parse Arguments
# =============================================================================

SERVER_IP=""
FULL_PIPELINE=false
WITH_ENDPOINTS=false
MILESTONE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --ssh-user)
            SSH_USER="$2"
            shift 2
            ;;
        --milestone)
            MILESTONE="$2"
            shift 2
            ;;
        --full-pipeline)
            FULL_PIPELINE=true
            shift
            ;;
        --with-endpoints)
            WITH_ENDPOINTS=true
            shift
            ;;
        --help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            if [[ -z "$SERVER_IP" ]]; then
                SERVER_IP=$1
            else
                echo "Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$SERVER_IP" ]]; then
    echo "Error: SERVER_IP is required"
    usage
fi

# =============================================================================
# Main Checks
# =============================================================================

echo "=============================================="
echo "SOC-in-a-Box Health Check"
echo "Target: $SERVER_IP"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# Milestone 2: Base Infrastructure
# -----------------------------------------------------------------------------
if [[ -z "$MILESTONE" || "$MILESTONE" == "2" ]]; then
    echo "--- Milestone 2: Base Infrastructure ---"

    # SSH
    check_port "$SERVER_IP" 22 "SSH port 22 reachable"

    # Docker check (requires SSH)
    if [[ -n "$SSH_USER" ]]; then
        result=$(run_remote "docker --version" 2>/dev/null || echo "")
        if echo "$result" | grep -q "Docker version"; then
            log_pass "Docker installed"
        else
            log_fail "Docker not installed or not accessible"
        fi

        result=$(run_remote "docker compose version" 2>/dev/null || echo "")
        if echo "$result" | grep -q "Docker Compose"; then
            log_pass "Docker Compose plugin installed"
        else
            log_fail "Docker Compose plugin not installed"
        fi

        result=$(run_remote "systemctl is-active docker" 2>/dev/null || echo "")
        if echo "$result" | grep -q "^active"; then
            log_pass "Docker service running"
        else
            log_fail "Docker service not running"
        fi

        # UFW check
        result=$(run_remote "sudo ufw status" 2>/dev/null || echo "")
        if echo "$result" | grep -q "Status: active"; then
            log_pass "UFW firewall active"
        else
            log_fail "UFW firewall not active"
        fi
    else
        log_skip "Docker status (use --ssh-user for detailed checks)"
        log_skip "UFW status (use --ssh-user for detailed checks)"
    fi

    echo ""
fi

# -----------------------------------------------------------------------------
# Milestone 3: Wazuh
# -----------------------------------------------------------------------------
if [[ -z "$MILESTONE" || "$MILESTONE" == "3" ]]; then
    echo "--- Milestone 3: Wazuh ---"

    check_url "https://$SERVER_IP:443" "Wazuh Dashboard reachable (port 443)"
    check_port "$SERVER_IP" 1514 "Wazuh Agent port 1514 reachable"
    check_port "$SERVER_IP" 1515 "Wazuh Registration port 1515 reachable"

    if [[ -n "$SSH_USER" ]]; then
        # Check systemd services
        for svc in wazuh-manager wazuh-indexer wazuh-dashboard filebeat; do
            result=$(run_remote "systemctl is-active $svc" 2>/dev/null || echo "")
            if echo "$result" | grep -q "^active"; then
                log_pass "$svc service running"
            else
                log_fail "$svc service not running"
            fi
        done

        # Check Wazuh Indexer API (internal)
        result=$(run_remote "curl -sk https://127.0.0.1:9200 -u admin:admin 2>/dev/null | head -1" || echo "")
        if echo "$result" | grep -q "Unauthorized\|wazuh-indexer"; then
            log_pass "Wazuh Indexer API responding on localhost:9200"
        else
            log_fail "Wazuh Indexer API not responding"
        fi

        # Check passwords file exists
        result=$(run_remote "test -f /root/.wazuh-passwords && echo 'exists'" 2>/dev/null || echo "")
        if echo "$result" | grep -q "exists"; then
            log_pass "Wazuh passwords file exists (/root/.wazuh-passwords)"
        else
            log_fail "Wazuh passwords file missing (/root/.wazuh-passwords)"
        fi

        # Check Wazuh Manager API
        result=$(run_remote "curl -sk https://127.0.0.1:55000 2>/dev/null | head -1" || echo "")
        if echo "$result" | grep -q "Unauthorized\|Welcome\|API"; then
            log_pass "Wazuh Manager API responding on localhost:55000"
        else
            log_fail "Wazuh Manager API not responding"
        fi
    else
        log_skip "Wazuh services status (use --ssh-user for detailed checks)"
        log_skip "Wazuh Indexer API (use --ssh-user for detailed checks)"
        log_skip "Wazuh Manager API (use --ssh-user for detailed checks)"
    fi

    echo ""
fi

# -----------------------------------------------------------------------------
# Milestone 4: DFIR-IRIS
# -----------------------------------------------------------------------------
if [[ -z "$MILESTONE" || "$MILESTONE" == "4" ]]; then
    echo "--- Milestone 4: DFIR-IRIS ---"

    check_url "https://$SERVER_IP:8444" "IRIS UI reachable (port 8444)"

    # Check API health endpoint if available
    if curl -sk --connect-timeout 5 "https://$SERVER_IP:8444/api/ping" 2>/dev/null | grep -q "pong"; then
        log_pass "IRIS API responding (/api/ping)"
    else
        log_skip "IRIS API ping (endpoint may not exist or auth required)"
    fi

    if [[ -n "$SSH_USER" ]]; then
        result=$(run_remote "docker compose -f /opt/iris/docker-compose.yml ps 2>/dev/null" || echo "")
        if echo "$result" | grep -q "Up\|running"; then
            log_pass "IRIS containers running"
        else
            log_fail "IRIS containers not running"
        fi
    fi

    echo ""
fi

# -----------------------------------------------------------------------------
# Milestone 5: AI Module + Ollama
# -----------------------------------------------------------------------------
if [[ -z "$MILESTONE" || "$MILESTONE" == "5" ]]; then
    echo "--- Milestone 5: AI Module ---"

    check_url "http://$SERVER_IP:8085/health" "AI Module health endpoint"

    # Ollama should NOT be publicly accessible
    if curl -s --connect-timeout 3 "http://$SERVER_IP:11434" > /dev/null 2>&1; then
        log_fail "Ollama port 11434 is exposed (SECURITY ISSUE - should be internal only)"
    else
        log_pass "Ollama port 11434 not exposed (correct)"
    fi

    if [[ -n "$SSH_USER" ]]; then
        result=$(run_remote "docker compose -f /opt/ai-module/docker-compose.yml ps 2>/dev/null" || echo "")
        if echo "$result" | grep -q "Up\|running"; then
            log_pass "AI containers running"
        else
            log_fail "AI containers not running"
        fi
    fi

    echo ""
fi

# -----------------------------------------------------------------------------
# Milestone 6-8: Integration Tests (optional)
# -----------------------------------------------------------------------------
if [[ "$FULL_PIPELINE" == true ]]; then
    echo "--- Full Pipeline Test ---"

    # TODO: Implement full pipeline test
    # 1. Send test alert payload to AI module
    # 2. Verify case created in IRIS
    # 3. Verify note added with AI summary

    log_skip "Pipeline test: Alert → AI (not implemented yet)"
    log_skip "Pipeline test: AI → IRIS case (not implemented yet)"
    log_skip "Pipeline test: End-to-end (not implemented yet)"

    echo ""
fi

# -----------------------------------------------------------------------------
# Milestone 9: Endpoints (optional)
# -----------------------------------------------------------------------------
if [[ "$WITH_ENDPOINTS" == true ]]; then
    echo "--- Endpoint Checks ---"

    # TODO: Add endpoint checks
    log_skip "Windows agent connectivity (not implemented yet)"
    log_skip "Linux agent connectivity (not implemented yet)"

    echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo "=============================================="
echo "Summary"
echo "=============================================="
echo -e "Passed:  ${GREEN}$PASSED${NC}"
echo -e "Failed:  ${RED}$FAILED${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Health check FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}Health check PASSED${NC}"
    exit 0
fi
