#!/bin/bash
# Module 04 — File Permission Audit
# Checks for dangerous file permissions and SUID/SGID binaries

section_header "📁 MODULE 4: File Permissions"

# --- Check 1: /etc/passwd permissions ---
passwd_perm=$(stat -c "%a" /etc/passwd 2>/dev/null)
if [[ "$passwd_perm" == "644" ]]; then
    log_pass "/etc/passwd permissions: 644"
else
    log_fail "/etc/passwd permissions: ${passwd_perm}" "Should be 644"
    if [[ "$MODE" == "fix" ]]; then
        chmod 644 /etc/passwd
        echo -e "         ${GREEN}→ Fixed: /etc/passwd set to 644${NC}"
    fi
fi

# --- Check 2: /etc/shadow permissions ---
shadow_perm=$(stat -c "%a" /etc/shadow 2>/dev/null)
if [[ "$shadow_perm" == "640" || "$shadow_perm" == "600" ]]; then
    log_pass "/etc/shadow permissions: ${shadow_perm}"
else
    log_fail "/etc/shadow permissions: ${shadow_perm}" "Should be 640 or 600"
    if [[ "$MODE" == "fix" ]]; then
        chmod 640 /etc/shadow
        echo -e "         ${GREEN}→ Fixed: /etc/shadow set to 640${NC}"
    fi
fi

# --- Check 3: /etc/gshadow permissions ---
if [[ -f /etc/gshadow ]]; then
    gshadow_perm=$(stat -c "%a" /etc/gshadow 2>/dev/null)
    if [[ "$gshadow_perm" == "640" || "$gshadow_perm" == "600" ]]; then
        log_pass "/etc/gshadow permissions: ${gshadow_perm}"
    else
        log_fail "/etc/gshadow permissions: ${gshadow_perm}" "Should be 640 or 600"
    fi
fi

# --- Check 4: SUID binaries ---
echo -e "\n  ${CYAN}Scanning for SUID binaries...${NC}"
suid_files=$(find / -perm -4000 -type f 2>/dev/null | head -20)
suid_count=$(echo "$suid_files" | grep -c . 2>/dev/null || echo 0)

# Known safe SUID binaries
safe_suid="/usr/bin/sudo /usr/bin/passwd /usr/bin/chsh /usr/bin/chfn /usr/bin/newgrp /usr/bin/gpasswd /usr/bin/su /usr/bin/mount /usr/bin/umount /usr/lib/openssh/ssh-keysign"

unexpected=0
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if ! echo "$safe_suid" | grep -q "$file"; then
        echo -e "    ${YELLOW}→ Unexpected SUID: ${file}${NC}"
        unexpected=$((unexpected + 1))
    fi
done <<< "$suid_files"

if [[ $unexpected -eq 0 ]]; then
    log_pass "No unexpected SUID binaries found (${suid_count} total, all known)"
else
    log_warn "${unexpected} unexpected SUID binaries found" "Review for potential privilege escalation"
fi

# --- Check 5: World-writable files ---
echo -e "\n  ${CYAN}Scanning for world-writable files...${NC}"
ww_files=$(find / -xdev -perm -0002 -type f 2>/dev/null | grep -v "/proc\|/sys\|/dev" | head -10)
ww_count=$(echo "$ww_files" | grep -c . 2>/dev/null || echo 0)

if [[ $ww_count -eq 0 || -z "$ww_files" ]]; then
    log_pass "No world-writable files found"
else
    log_warn "${ww_count} world-writable files found" "Anyone can modify these files"
    while IFS= read -r file; do
        [[ -n "$file" ]] && echo -e "    ${YELLOW}→ ${file}${NC}"
    done <<< "$ww_files"
fi

# --- Check 6: /tmp sticky bit ---
tmp_perm=$(stat -c "%a" /tmp 2>/dev/null)
if [[ "$tmp_perm" == *"1"* || "$tmp_perm" == "1777" ]]; then
    log_pass "/tmp has sticky bit set"
else
    log_fail "/tmp missing sticky bit" "Users could delete each other's temp files"
    if [[ "$MODE" == "fix" ]]; then
        chmod 1777 /tmp
        echo -e "         ${GREEN}→ Fixed: Sticky bit set on /tmp${NC}"
    fi
fi
