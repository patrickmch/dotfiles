#!/bin/bash
# Detect which machine this Claude session is running on and inject a
# CURRENT_MACHINE line into session context via SessionStart hook stdout.
#
# Designed in wiki/decisions/2026-04-10-session-machine-detection.md
# (infrastructure repo). The fleet, with verified `hostname -s` values:
#   - gc      hostname "gc"        Tailscale 100.118.247.22
#   - eagle   hostname "pro"       Tailscale 100.116.125.97  (Tailscale name "eagle" != OS hostname)
#   - turtle  hostname "turtle-1"  Tailscale 100.124.70.31

HOSTNAME=$(hostname -s 2>/dev/null)
COMPUTER_NAME=$(scutil --get ComputerName 2>/dev/null)

MACHINE=""

# 1. hostname -s
case "$HOSTNAME" in
  gc)              MACHINE=gc ;;
  pro|eagle)       MACHINE=eagle ;;
  turtle|turtle-1) MACHINE=turtle ;;
esac

# 2. ComputerName fallback (covers stale hostname but correct mac name in System Settings)
if [[ -z "$MACHINE" ]]; then
  case "$COMPUTER_NAME" in
    gc*)       MACHINE=gc ;;
    pro*|eagle*) MACHINE=eagle ;;
    turtle*)   MACHINE=turtle ;;
  esac
fi

# 3. Tailscale IP fallback (covers both of the above being wrong/stale). Absolute
#    path because the SessionStart shell may not have /opt/homebrew/bin in PATH.
if [[ -z "$MACHINE" ]]; then
  for TS in /opt/homebrew/bin/tailscale /usr/local/bin/tailscale tailscale; do
    if command -v "$TS" >/dev/null 2>&1; then
      TS_IP=$("$TS" ip -4 2>/dev/null | head -1)
      break
    fi
  done
  case "$TS_IP" in
    100.118.247.22) MACHINE=gc ;;
    100.116.125.97) MACHINE=eagle ;;
    100.124.70.31)  MACHINE=turtle ;;
  esac
fi

case "$MACHINE" in
  gc)
    echo "CURRENT_MACHINE: gc (Mac Mini M4 Pro, always-on server @ 100.118.247.22)"
    echo "- You are running LOCALLY on gc. Do NOT ssh gc — you are already here."
    echo "- For eagle operations: ssh eagle  (interactive dev, browser, mbsync)"
    echo "- For turtle operations: ssh turtle  (experimental sandbox)"
    ;;
  eagle)
    echo "CURRENT_MACHINE: eagle (MacBook Pro M1 Pro, interactive dev @ 100.116.125.97)"
    echo "- You are running LOCALLY on eagle. Do NOT ssh eagle — you are already here."
    echo "- For gc operations: ssh gc  (always-on server, cron, OpenClaw, agents)"
    echo "- For turtle operations: ssh turtle  (experimental sandbox)"
    ;;
  turtle)
    echo "CURRENT_MACHINE: turtle (experimental sandbox @ 100.124.70.31)"
    echo "- You are running LOCALLY on turtle. Do NOT ssh turtle — you are already here."
    echo "- For gc operations: ssh gc  (always-on server)"
    echo "- For eagle operations: ssh eagle  (interactive dev)"
    ;;
  *)
    echo "CURRENT_MACHINE: unknown (hostname=$HOSTNAME ComputerName=$COMPUTER_NAME)"
    echo "- Detection failed. Falling back to whatever CLAUDE.md says — verify before acting on machine-specific guidance."
    ;;
esac

exit 0
