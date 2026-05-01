#!/bin/bash
# ============================================================
# Linux Hardening Toolkit — Main Orchestrator
#
# Usage:
#   sudo ./harden.sh --audit          # Audit only (safe)
#   sudo ./harden.sh --fix            # Apply fixes
#   sudo ./harden.sh --audit --report # Audit + HTML report
#
# Author: Ada Araújo
# ============================================================

set -euo pipefail

# === COLORS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# === GLOBAL VARIABLES ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
REPORTS_DIR="${SCRIPT_DIR}/reports"
MODE="audit"      # audit or fix
GENERATE_REPORT=false
RESULTS_FILE="/tmp/hardening_results.json"

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# === FUNCTIONS ===

banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║         🔒 Linux Hardening Toolkit v1.0             ║"
    echo "║         Security Audit & Hardening Script           ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Mode:   ${BOLD}${MODE}${NC}"
    echo -e "  Date:   $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  Host:   $(hostname)"
    echo -e "  OS:     $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  Kernel: $(uname -r)"
    echo ""
}

usage() {
    echo "Usage: sudo $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --audit       Run security audit only (no changes)"
    echo "  --fix         Apply security fixes"
    echo "  --report      Generate HTML compliance report"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0 --audit            # Safe audit scan"
    echo "  sudo $0 --fix              # Apply hardening"
    echo "  sudo $0 --audit --report   # Audit with report"
    exit 0
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR] This script must be run as root (use sudo)${NC}"
        exit 1
    fi
}

# Result logging functions used by modules
log_pass() {
    local check="$1"
    local detail="${2:-}"
    echo -e "  ${GREEN}[PASS]${NC} ${check}"
    [[ -n "$detail" ]] && echo -e "         ${CYAN}→ ${detail}${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "{\"status\":\"PASS\",\"check\":\"${check}\",\"detail\":\"${detail}\"}," >> "$RESULTS_FILE"
}

log_fail() {
    local check="$1"
    local detail="${2:-}"
    echo -e "  ${RED}[FAIL]${NC} ${check}"
    [[ -n "$detail" ]] && echo -e "         ${YELLOW}→ ${detail}${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "{\"status\":\"FAIL\",\"check\":\"${check}\",\"detail\":\"${detail}\"}," >> "$RESULTS_FILE"
}

log_warn() {
    local check="$1"
    local detail="${2:-}"
    echo -e "  ${YELLOW}[WARN]${NC} ${check}"
    [[ -n "$detail" ]] && echo -e "         ${CYAN}→ ${detail}${NC}"
    WARN_COUNT=$((WARN_COUNT + 1))
    echo "{\"status\":\"WARN\",\"check\":\"${check}\",\"detail\":\"${detail}\"}," >> "$RESULTS_FILE"
}

section_header() {
    local title="$1"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $title${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_summary() {
    local total=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
    local score=0
    if [[ $total -gt 0 ]]; then
        score=$(( (PASS_COUNT * 100) / total ))
    fi

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                    AUDIT SUMMARY                     ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "║  ${GREEN}PASS:${NC}    ${PASS_COUNT}                                         ║"
    echo -e "║  ${RED}FAIL:${NC}    ${FAIL_COUNT}                                         ║"
    echo -e "║  ${YELLOW}WARNING:${NC} ${WARN_COUNT}                                         ║"
    echo -e "║  Total:   ${total}                                         ║"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════╣${NC}"

    if [[ $score -ge 80 ]]; then
        echo -e "║  Score: ${GREEN}${score}%${NC} — Good security posture              ║"
    elif [[ $score -ge 50 ]]; then
        echo -e "║  Score: ${YELLOW}${score}%${NC} — Needs improvement                  ║"
    else
        echo -e "║  Score: ${RED}${score}%${NC} — Critical issues found               ║"
    fi

    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Export functions so modules can use them
export -f log_pass log_fail log_warn section_header
export RESULTS_FILE MODE PASS_COUNT FAIL_COUNT WARN_COUNT
export RED GREEN YELLOW BLUE CYAN BOLD NC

# === PARSE ARGUMENTS ===
while [[ $# -gt 0 ]]; do
    case $1 in
        --audit)  MODE="audit"; shift ;;
        --fix)    MODE="fix"; shift ;;
        --report) GENERATE_REPORT=true; shift ;;
        --help)   usage ;;
        *)        echo "Unknown option: $1"; usage ;;
    esac
done

# === MAIN EXECUTION ===
check_root
banner

# Initialize results file
echo "[" > "$RESULTS_FILE"

# Run each module in order
for module in "${MODULES_DIR}"/[0-9]*.sh; do
    if [[ -f "$module" ]]; then
        source "$module"
    fi
done

# Close JSON array
# Remove trailing comma and close array
sed -i '$ s/,$//' "$RESULTS_FILE"
echo "]" >> "$RESULTS_FILE"

# Print summary
print_summary

# Generate report if requested
if [[ "$GENERATE_REPORT" == true ]]; then
    echo -e "${BLUE}[*] Generating HTML report...${NC}"
    if command -v python3 &>/dev/null; then
        python3 "${REPORTS_DIR}/report_generator.py" "$RESULTS_FILE"
        echo -e "${GREEN}[✓] Report saved to reports/hardening_report.html${NC}"
    else
        echo -e "${YELLOW}[!] Python3 not found. Install it to generate reports.${NC}"
    fi
fi

echo -e "${BLUE}[*] Hardening ${MODE} complete.${NC}"
