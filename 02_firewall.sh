#!/bin/bash
# Module 02 — Firewall (UFW) Configuration
# Checks firewall status, policies, and open ports

section_header "🧱 MODULE 2: Firewall (UFW)"

# --- Check 1: UFW installed ---
if command -v ufw &>/dev/null; then
    log_pass "UFW is installed"
else
    log_fail "UFW is not installed" "No firewall protection"
    if [[ "$MODE" == "fix" ]]; then
        apt-get install -y ufw >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: UFW installed${NC}"
    fi
    return 0
fi

# --- Check 2: UFW active ---
ufw_status=$(ufw status 2>/dev/null | head -1)
if echo "$ufw_status" | grep -q "active"; then
    log_pass "UFW is active"
else
    log_fail "UFW is inactive" "Firewall is not protecting the system"
    if [[ "$MODE" == "fix" ]]; then
        ufw --force enable >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: UFW enabled${NC}"
    fi
fi

# --- Check 3: Default incoming policy ---
default_in=$(ufw status verbose 2>/dev/null | grep "Default:" | head -1)
if echo "$default_in" | grep -qi "deny\|reject"; then
    log_pass "Default incoming policy: deny"
else
    log_fail "Default incoming policy is not deny" "All ports are open by default"
    if [[ "$MODE" == "fix" ]]; then
        ufw default deny incoming >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: Default incoming set to deny${NC}"
    fi
fi

# --- Check 4: Default outgoing policy ---
default_out=$(ufw status verbose 2>/dev/null | grep "Default:" | tail -1)
if echo "$default_out" | grep -qi "allow"; then
    log_pass "Default outgoing policy: allow"
else
    log_warn "Default outgoing policy may be restrictive" "Could block legitimate traffic"
fi

# --- Check 5: SSH port allowed ---
ssh_rule=$(ufw status 2>/dev/null | grep -i "22\|ssh")
if [[ -n "$ssh_rule" ]]; then
    log_pass "SSH port (22) has a firewall rule"
else
    log_warn "No explicit SSH rule found" "Ensure SSH access is configured before enabling UFW"
    if [[ "$MODE" == "fix" ]]; then
        ufw allow ssh >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: SSH rule added${NC}"
    fi
fi

# --- Check 6: Audit open ports ---
echo -e "\n  ${CYAN}Currently open ports:${NC}"
if command -v ss &>/dev/null; then
    ss -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
        port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
        process=$(echo "$line" | grep -oP '\"[^\"]+\"' | head -1 | tr -d '"')
        echo -e "    ${CYAN}→ Port ${port} (${process:-unknown})${NC}"
    done
else
    netstat -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
        port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
        echo -e "    ${CYAN}→ Port ${port}${NC}"
    done
fi
log_pass "Open ports audit completed"
