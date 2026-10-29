# Active Linux Intrusion Prevention & Dynamic Kernel Firewall Defense (Fail2ban)

A production-grade **Intrusion Prevention System (IPS)** architecture utilizing **Fail2ban** to actively monitor service authentication and HTTP ingress logs, dynamically injecting kernel-level packet filter rules (`nftables`/`iptables` via UFW) to neutralize brute-force attacks and vulnerability scanners at machine speed.

---

## SecOps Architectural Workflow

```
         Unauthorized Probes (SSH Dictionary / Web Vulnerability Scanners)
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       System Logging & Journald                             │
│       - systemd-journald (sshd.service authentication attempts)             │
│       - /var/log/nginx/access.log (HTTP 401/403/404 scanning probes)        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Real-time Stream
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Fail2ban IPS Engine                               │
│       - Regex pattern analysis against active jail filters                  │
│       - Failure evaluation against threshold (maxretry within findtime)     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Threshold Breached
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Dynamic Kernel Packet Filter                          │
│       - Calls UFW / iptables to insert active REJECT/DROP rule              │
│       - Offending IP severed at Layer 3/4 network boundary                   │
│       - Auto-releases rule after progressive ban window expires             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Active Jail Matrix

| Jail Name | Service | Inspection Target | Trigger Threshold | Protective Action |
| :--- | :--- | :--- | :--- | :--- |
| **`sshd`** | OpenSSH (Port 22) | `_SYSTEMD_UNIT=sshd.service` | 3 failed attempts in 10m | Dynamic UFW `REJECT` rule injected on all incoming traffic |
| **`nginx-botsearch`** | Nginx (Port 80/443) | `/var/log/nginx/access.log` | 2 malicious probe queries | Dynamic firewall ban blocking web exploit scanners (`/.env`, `/wp-login.php`, etc.) |

---

## Core Engineering Capabilities

### 1. Dynamic Firewall Injection (`banaction = ufw`)
Unlike basic rate limiters that consume application memory, Fail2ban triggers kernel-level packet filtering. Banned IPs are blocked before TCP handshakes can consume application or server resources:
```text
Anywhere   REJECT   198.51.100.42   # by Fail2Ban after 0 attempts against sshd
```

### 2. Progressive Exponential Ban Escalation
Repeat offenders are subjected to geometric ban multipliers, transforming temporary 1-hour blocks into multi-day bans for persistent botnets:
```ini
bantime           = 1h
findtime          = 10m
maxretry          = 3
bantime.increment = true
```

### 3. Subnet & Management Whitelisting
Prevents operator lockouts by hardcoding administrative IP CIDRs and loopback adapters into the global configuration:
```ini
ignoreip = 127.0.0.1/8 ::1 192.168.122.1
```

### 4. Zero-Downtime Decoupled Configuration
Follows enterprise Debian/Ubuntu packaging standards. Upgrades never overwrite security baselines by isolating custom overrides to `/etc/fail2ban/jail.local`.

---

## Repository Structure

```
.
├── config/
│   └── jail.local             # Production Fail2ban jail definitions & policies
├── scripts/
│   ├── install.sh             # Automated installer & service activation
│   └── test-defense.sh        # Automated attack simulation & UFW verification suite
├── LICENSE                    # MIT License
└── README.md                  # Architectural documentation & SecOps reference
```

---

## Quickstart & Deployment

### 1. Deploy Defense Configuration
Clone this repository and execute the automated installer with root privileges:
```bash
sudo ./scripts/install.sh
```

### 2. Verify Active Jails
Inspect the live status of the running defense daemon:
```bash
sudo fail2ban-client status
```

Expected output:
```text
Status
|- Number of jail:      2
`- Jail list:   nginx-botsearch, sshd
```

### 3. Execute Automated Attack Simulation
Run the included test suite to verify dynamic kernel rule injection and automatic unban cleanup:
```bash
sudo ./scripts/test-defense.sh
```

Expected output:
```text
==> [1/4] Verifying Fail2ban daemon connectivity...
==> [2/4] Simulating intrusion ban on IP: 198.51.100.42 ...
==> [3/4] Auditing dynamic kernel firewall insertion in UFW...
    Kernel Firewall Rule Confirmed:
[ 1] Anywhere   REJECT IN   198.51.100.42   # by Fail2Ban after 0 attempts against sshd
==> [4/4] Releasing test IP from active jail...
    Dynamic Firewall Rule Removed. Clean state confirmed.
==> Intrusion defense verification PASSED.
```

---

## Operational Administration Reference

| Task | Command |
| :--- | :--- |
| **Inspect Jail Health** | `sudo fail2ban-client status sshd` |
| **View Active Banned IPs** | `sudo fail2ban-client get sshd banned` |
| **Manually Ban Threat IP** | `sudo fail2ban-client set sshd banip <IP>` |
| **Manually Unban IP** | `sudo fail2ban-client set sshd unbanip <IP>` |
| **Audit Live Kernel Rules** | `sudo ufw status verbose` |
| **Stream Defense Logs** | `sudo journalctl -u fail2ban -f` |

---

## Author
**Patrick Isles**  
*Systems Administration & Infrastructure Engineering*  
- GitHub: [github.com/patrick-isles](https://github.com/patrick-isles)  
- LinkedIn: [linkedin.com/in/patrick-isles-78aba6232](https://www.linkedin.com/in/patrick-isles-78aba6232/)

---

## License
MIT License. Open for educational and enterprise infrastructure reference.
