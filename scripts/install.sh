#!/usr/bin/env bash
# ==============================================================================
# Script: install.sh
# Purpose: Automated deployment of Fail2ban Intrusion Defense Architecture
# Author: Patrick Isles
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONF_SRC="${SCRIPT_DIR}/../config/jail.local"
CONF_DEST="/etc/fail2ban/jail.local"

echo "==> [1/4] Verifying root privileges..."
if [[ $EUID -ne 0 ]]; then
    echo "[-] Error: install.sh must be executed with sudo or as root." >&2
    exit 1
fi

echo "==> [2/4] Ensuring Fail2ban package installation..."
if ! command -v fail2ban-client &>/dev/null; then
    apt-get update -qq && apt-get install -y fail2ban
fi

echo "==> [3/4] Deploying production jail configuration..."
install -m 644 "$CONF_SRC" "$CONF_DEST"

echo "==> [4/4] Restarting Fail2ban daemon and activating jails..."
systemctl restart fail2ban
systemctl enable fail2ban

# Wait briefly for daemon socket initialization
sleep 2

echo "==> Deployment successful. Active jail status:"
fail2ban-client status
