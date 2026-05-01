# 🔒 Linux Hardening Toolkit

An automated security hardening script for Ubuntu/Debian servers. Scans for common misconfigurations, applies security best practices, and generates a detailed compliance report.

![Bash](https://img.shields.io/badge/Bash-4.0+-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)
![Linux](https://img.shields.io/badge/Linux-Ubuntu%2FDebian-orange?logo=linux)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 What It Does

The toolkit runs **7 security modules** that audit and optionally fix common vulnerabilities:

| Module | What It Checks |
|--------|---------------|
| **SSH Hardening** | Root login, password auth, default port, protocol version, idle timeout |
| **Firewall (UFW)** | UFW status, default policies, open ports audit |
| **User Security** | Empty passwords, UID 0 accounts, inactive users, sudo group audit |
| **File Permissions** | SUID/SGID binaries, world-writable files, sensitive file permissions |
| **System Updates** | Pending security patches, automatic updates config |
| **Audit Logging** | Auditd status, log rotation, syslog configuration |
| **Network Security** | IP forwarding, ICMP redirects, SYN cookies, open ports |

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/AdaAraujo/linux-hardening-toolkit.git
cd linux-hardening-toolkit

# Make scripts executable
chmod +x harden.sh modules/*.sh

# Run audit only (no changes — safe to run)
sudo ./harden.sh --audit

# Run full hardening (applies fixes)
sudo ./harden.sh --fix

# Generate HTML report
sudo ./harden.sh --audit --report
```

## 📁 Project Structure

```
linux-hardening-toolkit/
├── harden.sh               # Main script — orchestrates all modules
├── modules/
│   ├── 01_ssh.sh           # SSH server hardening
│   ├── 02_firewall.sh      # UFW firewall configuration
│   ├── 03_users.sh         # User account security
│   ├── 04_permissions.sh   # File permission audit
│   ├── 05_updates.sh       # System updates check
│   ├── 06_audit.sh         # Audit logging setup
│   └── 07_network.sh       # Network security settings
├── reports/
│   └── report_generator.py # Generates HTML compliance report
├── tests/
│   └── test_checks.sh      # Validates module checks
├── README.md
├── README.pt-br.md
└── LICENSE
```

## 📊 How Each File Works

### `harden.sh`
The main orchestrator. Parses command-line arguments (`--audit`, `--fix`, `--report`), runs each module in order, collects results (PASS/FAIL/WARNING), displays a summary with color-coded output, and optionally calls the report generator.

### `modules/01_ssh.sh` — SSH Hardening
Checks `/etc/ssh/sshd_config` for insecure settings. In `--fix` mode: disables root login, disables password authentication (forces key-based), sets idle timeout, restricts SSH protocol to v2.

### `modules/02_firewall.sh` — Firewall
Checks if UFW is installed and active, verifies default deny policies, lists currently open ports and flags unnecessary ones.

### `modules/03_users.sh` — User Security
Scans for users with empty passwords, detects multiple UID 0 accounts (should be only root), lists users in the sudo group for review, checks for inactive accounts.

### `modules/04_permissions.sh` — File Permissions
Finds SUID/SGID binaries that could be exploited for privilege escalation, detects world-writable files and directories, verifies permissions on sensitive files like `/etc/passwd`, `/etc/shadow`.

### `modules/05_updates.sh` — System Updates
Checks for pending security updates, verifies if unattended-upgrades is configured for automatic patching.

### `modules/06_audit.sh` — Audit Logging
Checks if auditd is installed and running, verifies log rotation is configured, checks syslog/rsyslog status.

### `modules/07_network.sh` — Network Security
Checks kernel parameters: IP forwarding (should be off), ICMP redirect acceptance, SYN flood protection, and lists listening ports.

### `reports/report_generator.py`
Reads audit results from JSON and generates a styled HTML compliance report with pass/fail counts, severity indicators, and recommendations.

## 🔐 Security Checks Summary

The toolkit checks **25+ security settings** based on:
- CIS Benchmark for Ubuntu Linux
- NIST SP 800-123 (Server Security Guide)
- Common SOC/sysadmin best practices

## ⚠️ Important Notes

- Always run `--audit` first to review what will change
- The `--fix` mode modifies system configurations — **use on test systems first**
- Backup your configs before running: `sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak`
- Designed for Ubuntu 22.04+ / Debian 12+

## 📈 Future Improvements

- [ ] CIS Benchmark score calculation
- [ ] Docker container hardening module
- [ ] Crontab security audit
- [ ] PDF report export
- [ ] Rollback feature for applied fixes

## 📝 License

MIT License
