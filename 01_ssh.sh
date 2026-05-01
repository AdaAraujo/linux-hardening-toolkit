#!/bin/bash
# Module 01 — SSH Server Hardening
# Checks and hardens OpenSSH configuration

section_header "🔑 MODULE 1: SSH Server Hardening"

SSHD_CONFIG="/etc/ssh/sshd_config"

if [[ ! -f "$SSHD_CONFIG" ]]; then
    log_warn "SSH server not installed" "sshd_config not found"
    return 0
fi

# --- Check 1: Root login disabled ---
root_login=$(grep -i "^PermitRootLogin" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ "$root_login" == "no" ]]; then
    log_pass "Root login is disabled"
else
    log_fail "Root login is allowed" "PermitRootLogin should be 'no'"
    if [[ "$MODE" == "fix" ]]; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
        echo -e "         ${GREEN}→ Fixed: PermitRootLogin set to no${NC}"
    fi
fi

# --- Check 2: Password authentication ---
pass_auth=$(grep -i "^PasswordAuthentication" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ "$pass_auth" == "no" ]]; then
    log_pass "Password authentication is disabled (key-based only)"
else
    log_warn "Password authentication is enabled" "Consider using SSH keys only"
    if [[ "$MODE" == "fix" ]]; then
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
        echo -e "         ${GREEN}→ Fixed: PasswordAuthentication set to no${NC}"
    fi
fi

# --- Check 3: SSH Protocol version ---
protocol=$(grep -i "^Protocol" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ -z "$protocol" || "$protocol" == "2" ]]; then
    log_pass "SSH Protocol version 2 (default on modern systems)"
else
    log_fail "SSH Protocol version 1 detected" "Vulnerable to known attacks"
    if [[ "$MODE" == "fix" ]]; then
        echo "Protocol 2" >> "$SSHD_CONFIG"
        echo -e "         ${GREEN}→ Fixed: Protocol set to 2${NC}"
    fi
fi

# --- Check 4: Empty passwords ---
empty_pass=$(grep -i "^PermitEmptyPasswords" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ "$empty_pass" != "yes" ]]; then
    log_pass "Empty passwords are not permitted"
else
    log_fail "Empty passwords are permitted" "Major security risk"
    if [[ "$MODE" == "fix" ]]; then
        sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"
        echo -e "         ${GREEN}→ Fixed: PermitEmptyPasswords set to no${NC}"
    fi
fi

# --- Check 5: Max authentication attempts ---
max_auth=$(grep -i "^MaxAuthTries" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ -n "$max_auth" && "$max_auth" -le 4 ]]; then
    log_pass "Max authentication attempts: ${max_auth}"
else
    log_warn "Max authentication attempts not limited" "Recommend MaxAuthTries 3"
    if [[ "$MODE" == "fix" ]]; then
        if grep -q "^#*MaxAuthTries" "$SSHD_CONFIG"; then
            sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' "$SSHD_CONFIG"
        else
            echo "MaxAuthTries 3" >> "$SSHD_CONFIG"
        fi
        echo -e "         ${GREEN}→ Fixed: MaxAuthTries set to 3${NC}"
    fi
fi

# --- Check 6: Idle timeout ---
alive_interval=$(grep -i "^ClientAliveInterval" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ -n "$alive_interval" && "$alive_interval" -gt 0 ]]; then
    log_pass "SSH idle timeout configured: ${alive_interval}s"
else
    log_warn "No SSH idle timeout configured" "Idle sessions stay open indefinitely"
    if [[ "$MODE" == "fix" ]]; then
        echo "ClientAliveInterval 300" >> "$SSHD_CONFIG"
        echo "ClientAliveCountMax 2" >> "$SSHD_CONFIG"
        echo -e "         ${GREEN}→ Fixed: Idle timeout set to 5 minutes${NC}"
    fi
fi

# --- Check 7: X11 Forwarding ---
x11=$(grep -i "^X11Forwarding" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
if [[ "$x11" == "no" ]]; then
    log_pass "X11 Forwarding is disabled"
else
    log_warn "X11 Forwarding is enabled" "Disable if not needed"
fi
