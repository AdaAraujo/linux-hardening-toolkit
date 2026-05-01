#!/bin/bash
# Module 06 — Audit & Logging
# Checks auditd, syslog, and log rotation configuration

section_header "📋 MODULE 6: Audit & Logging"

# --- Check 1: Syslog/rsyslog service ---
if systemctl is-active rsyslog &>/dev/null 2>&1; then
    log_pass "rsyslog is active and running"
elif systemctl is-active syslog &>/dev/null 2>&1; then
    log_pass "syslog is active and running"
else
    log_fail "No syslog service running" "System events are not being logged"
    if [[ "$MODE" == "fix" ]]; then
        apt-get install -y rsyslog >/dev/null 2>&1
        systemctl enable rsyslog >/dev/null 2>&1
        systemctl start rsyslog >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: rsyslog installed and started${NC}"
    fi
fi

# --- Check 2: Auditd installed ---
if command -v auditd &>/dev/null || dpkg -l | grep -q auditd 2>/dev/null; then
    log_pass "auditd is installed"

    # Check if running
    if systemctl is-active auditd &>/dev/null 2>&1; then
        log_pass "auditd service is running"
    else
        log_warn "auditd is installed but not running" "Start with: systemctl start auditd"
    fi
else
    log_warn "auditd is not installed" "Detailed audit trail not available"
    if [[ "$MODE" == "fix" ]]; then
        apt-get install -y auditd >/dev/null 2>&1
        systemctl enable auditd >/dev/null 2>&1
        systemctl start auditd >/dev/null 2>&1
        echo -e "         ${GREEN}→ Fixed: auditd installed and started${NC}"
    fi
fi

# --- Check 3: Log rotation ---
if [[ -f /etc/logrotate.conf ]]; then
    log_pass "logrotate is configured"
else
    log_warn "logrotate config not found" "Logs may grow indefinitely"
fi

# --- Check 4: Auth log exists ---
if [[ -f /var/log/auth.log ]]; then
    log_pass "/var/log/auth.log exists"
    # Check if recent
    auth_age=$(find /var/log/auth.log -mmin -60 2>/dev/null)
    if [[ -n "$auth_age" ]]; then
        log_pass "Auth log is being actively written"
    else
        log_warn "Auth log may not be updating" "Check rsyslog configuration"
    fi
elif [[ -f /var/log/secure ]]; then
    log_pass "/var/log/secure exists (RHEL-style)"
else
    log_fail "No authentication log found" "Login attempts are not being recorded"
fi

# --- Check 5: Kernel log ---
if [[ -f /var/log/kern.log ]] || dmesg &>/dev/null; then
    log_pass "Kernel logging is available"
else
    log_warn "Kernel log not accessible" "Check dmesg permissions"
fi

# --- Check 6: Failed login tracking ---
if command -v faillog &>/dev/null || command -v lastb &>/dev/null; then
    log_pass "Failed login tracking tools available"
    failed_count=$(lastb 2>/dev/null | grep -c . || echo 0)
    if [[ "$failed_count" -gt 0 ]]; then
        echo -e "    ${CYAN}→ ${failed_count} failed login attempts recorded${NC}"
    fi
else
    log_warn "No failed login tracking tools found"
fi
