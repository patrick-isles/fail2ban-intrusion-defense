#!/usr/bin/env bash
# ==============================================================================
# Script: test-defense.sh
# Purpose: Dynamic intrusion prevention simulation and firewall audit
# Author: Patrick Isles
# ==============================================================================

set -euo pipefail

TEST_IP="198.51.100.42" # RFC 5737 Documentation Benchmark IP

echo "==> [1/4] Verifying Fail2ban daemon connectivity..."
fail2ban-client ping >/dev/null

echo "==> [2/4] Simulating intrusion ban on IP: $TEST_IP ..."
fail2ban-client set sshd banip "$TEST_IP" >/dev/null

echo "==> [3/4] Auditing dynamic kernel firewall insertion in UFW..."
if ufw status | grep -q "$TEST_IP"; then
    echo "    Kernel Firewall Rule Confirmed:"
    ufw status | grep "$TEST_IP"
else
    echo "[-] Error: Dynamic firewall rule failed to inject!" >&2
    exit 1
fi

echo "==> [4/4] Releasing test IP from active jail..."
fail2ban-client set sshd unbanip "$TEST_IP" >/dev/null

if ! ufw status | grep -q "$TEST_IP"; then
    echo "    Dynamic Firewall Rule Removed. Clean state confirmed."
else
    echo "[-] Error: Rule failed to clean up!" >&2
    exit 1
fi

echo "==> Intrusion defense verification PASSED."
