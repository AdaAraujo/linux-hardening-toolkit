#!/bin/bash
# Module 03 — User Account Security
# Checks for insecure user configurations

section_header "👤 MODULE 3: User Account Security"

# --- Check 1: Users with empty passwords ---
empty_pw=$(awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null)
if [[ -z "$empty_pw" ]]; then
    log_pass "No users with empty passwords"
else
    count=$(echo "$empty_pw" | wc -l)
    log_fail "${count} user(s) with empty passwords found" "Users: $(echo $empty_pw | tr '\n' ', ')"
fi

# --- Check 2: Multiple UID 0 accounts ---
uid0_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
uid0_count=$(echo "$uid0_users" | wc -l)
if [[ "$uid0_count" -eq 1 ]]; then
    log_pass "Only root has UID 0"
else
    log_fail "Multiple accounts with UID 0 detected" "Users: $(echo $uid0_users | tr '\n' ', ')"
fi

# --- Check 3: Root account has password ---
root_pw=$(grep "^root:" /etc/shadow 2>/dev/null | cut -d: -f2)
if [[ -n "$root_pw" && "$root_pw" != "*" && "$root_pw" != "!" ]]; then
    log_pass "Root account has a password set"
else
    log_warn "Root account may not have a password" "Verify root access method"
fi

# --- Check 4: Sudo group members ---
sudo_users=$(getent group sudo 2>/dev/null | cut -d: -f4)
if [[ -n "$sudo_users" ]]; then
    log_warn "Users in sudo group: ${sudo_users}" "Review if all need elevated privileges"
else
    log_pass "No additional users in sudo group"
fi

# --- Check 5: Users with login shell ---
login_users=$(awk -F: '$7 !~ /(nologin|false|sync|halt|shutdown)/ {print $1}' /etc/passwd | grep -v "^root$")
login_count=$(echo "$login_users" | grep -c . 2>/dev/null || echo 0)
if [[ "$login_count" -le 5 ]]; then
    log_pass "Login-enabled accounts: ${login_count} (reasonable)"
else
    log_warn "${login_count} accounts with login shells" "Review if all are needed"
fi

# --- Check 6: Password aging policy ---
max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
if [[ -n "$max_days" && "$max_days" -le 90 ]]; then
    log_pass "Password max age: ${max_days} days"
else
    log_warn "Password max age: ${max_days:-99999} days" "Recommend 90 days or less"
    if [[ "$MODE" == "fix" ]]; then
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
        echo -e "         ${GREEN}→ Fixed: PASS_MAX_DAYS set to 90${NC}"
    fi
fi

# --- Check 7: Minimum password length ---
min_len=$(grep "^PASS_MIN_LEN" /etc/login.defs 2>/dev/null | awk '{print $2}')
if [[ -n "$min_len" && "$min_len" -ge 8 ]]; then
    log_pass "Minimum password length: ${min_len}"
else
    log_warn "Minimum password length: ${min_len:-5}" "Recommend 8 or more"
    if [[ "$MODE" == "fix" ]]; then
        sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN 8/' /etc/login.defs
        echo -e "         ${GREEN}→ Fixed: PASS_MIN_LEN set to 8${NC}"
    fi
fi
