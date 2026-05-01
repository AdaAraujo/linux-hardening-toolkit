#!/bin/bash
# Module 07 — Network Security
# Checks kernel network parameters and listening services

section_header "🌐 MODULE 7: Network Security"

# --- Check 1: IP Forwarding ---
ip_forward=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
if [[ "$ip_forward" == "0" ]]; then
    log_pass "IP forwarding is disabled"
else
    log_warn "IP forwarding is enabled" "Disable unless this is a router/gateway"
    if [[ "$MODE" == "fix" ]]; then
        sysctl -w net.ipv4.ip_forward=0 >/dev/null 2>&1
        echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.d/99-hardening.conf
        echo -e "         ${GREEN}→ Fixed: IP forwarding disabled${NC}"
    fi
fi

# --- Check 2: ICMP Redirect acceptance ---
icmp_redirect=$(cat /proc/sys/net/ipv4/conf/all/accept_redirects 2>/dev/null)
if [[ "$icmp_redirect" == "0" ]]; then
    log_pass "ICMP redirects are rejected"
else
    log_warn "ICMP redirects are accepted" "Could be used for MITM attacks"
    if [[ "$MODE" == "fix" ]]; then
        sysctl -w net.ipv4.conf.all.accept_redirects=0 >/dev/null 2>&1
        echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.d/99-hardening.conf
        echo -e "         ${GREEN}→ Fixed: ICMP redirects disabled${NC}"
    fi
fi

# --- Check 3: SYN cookies (SYN flood protection) ---
syn_cookies=$(cat /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null)
if [[ "$syn_cookies" == "1" ]]; then
    log_pass "SYN cookies enabled (SYN flood protection)"
else
    log_fail "SYN cookies disabled" "Vulnerable to SYN flood attacks"
    if [[ "$MODE" == "fix" ]]; then
        sysctl -w net.ipv4.tcp_syncookies=1 >/dev/null 2>&1
        echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-hardening.conf
        echo -e "         ${GREEN}→ Fixed: SYN cookies enabled${NC}"
    fi
fi

# --- Check 4: Source routing ---
src_route=$(cat /proc/sys/net/ipv4/conf/all/accept_source_route 2>/dev/null)
if [[ "$src_route" == "0" ]]; then
    log_pass "Source routing is disabled"
else
    log_warn "Source routing is enabled" "Could allow attackers to specify packet routes"
    if [[ "$MODE" == "fix" ]]; then
        sysctl -w net.ipv4.conf.all.accept_source_route=0 >/dev/null 2>&1
        echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.d/99-hardening.conf
        echo -e "         ${GREEN}→ Fixed: Source routing disabled${NC}"
    fi
fi

# --- Check 5: Bogus ICMP responses ---
bogus_icmp=$(cat /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses 2>/dev/null)
if [[ "$bogus_icmp" == "1" ]]; then
    log_pass "Bogus ICMP error responses ignored"
else
    log_warn "System responds to bogus ICMP errors" "Could be used for reconnaissance"
fi

# --- Check 6: Listening services audit ---
echo -e "\n  ${CYAN}Listening services:${NC}"
if command -v ss &>/dev/null; then
    ss -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
        local_addr=$(echo "$line" | awk '{print $4}')
        process=$(echo "$line" | grep -oP 'users:\(\("[^"]+' | cut -d'"' -f2)
        echo -e "    ${CYAN}→ ${local_addr} (${process:-unknown})${NC}"
    done
fi
log_pass "Network service audit completed"

# --- Check 7: IPv6 ---
ipv6_enabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)
if [[ "$ipv6_enabled" == "1" ]]; then
    log_pass "IPv6 is disabled"
else
    log_warn "IPv6 is enabled" "Disable if not needed to reduce attack surface"
fi
