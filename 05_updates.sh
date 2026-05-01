#!/bin/bash
# Module 05 — System Updates
# Checks for pending updates and automatic update configuration

section_header "📦 MODULE 5: System Updates"

# --- Check 1: Package manager available ---
if command -v apt-get &>/dev/null; then
    log_pass "APT package manager available"
else
    log_warn "APT not found — checks limited to Debian/Ubuntu"
    return 0
fi

# --- Check 2: Pending security updates ---
echo -e "  ${CYAN}Checking for updates (this may take a moment)...${NC}"
apt-get update -qq 2>/dev/null

upgradable=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo 0)
if [[ "$upgradable" -eq 0 ]]; then
    log_pass "System is up to date — no pending updates"
else
    log_warn "${upgradable} package(s) have updates available" "Run: sudo apt upgrade"
    if [[ "$MODE" == "fix" ]]; then
        echo -e "         ${CYAN}→ Installing updates...${NC}"
        apt-get upgrade -y -qq 2>/dev/null
        echo -e "         ${GREEN}→ Fixed: Updates installed${NC}"
    fi
fi

# --- Check 3: Security updates specifically ---
security_updates=$(apt list --upgradable 2>/dev/null | grep -i "security" | wc -l)
if [[ "$security_updates" -eq 0 ]]; then
    log_pass "No pending security updates"
else
    log_fail "${security_updates} security update(s) pending" "Security patches should be applied immediately"
fi

# --- Check 4: Unattended upgrades ---
if dpkg -l | grep -q "unattended-upgrades" 2>/dev/null; then
    log_pass "Unattended-upgrades is installed"
else
    log_warn "Unattended-upgrades not installed" "Automatic security updates not configured"
    if [[ "$MODE" == "fix" ]]; then
        apt-get install -y unattended-upgrades >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: unattended-upgrades installed${NC}"
    fi
fi

# --- Check 5: Last update timestamp ---
if [[ -f /var/lib/apt/periodic/update-success-stamp ]]; then
    last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null)
    now=$(date +%s)
    days_ago=$(( (now - last_update) / 86400 ))
    if [[ $days_ago -le 7 ]]; then
        log_pass "Last successful update: ${days_ago} day(s) ago"
    else
        log_warn "Last update was ${days_ago} days ago" "Updates should run at least weekly"
    fi
else
    log_warn "Cannot determine last update time" "Check update schedule"
fi
