#!/usr/bin/env bash
# dotfiles-sync-install.sh — install the dotfiles-sync launchd agent for the current user.
#
# Reads the template plist from ~/dotfiles/launchd/, substitutes /Users/mchey with
# the current $HOME, and loads it into launchd. Idempotent — safe to re-run.
#
# Usage: bash ~/dotfiles/bin/dotfiles-sync-install.sh

set -euo pipefail

DOTFILES="${HOME}/dotfiles"
TEMPLATE="${DOTFILES}/launchd/com.mchey.dotfiles-sync.plist"
TARGET="${HOME}/Library/LaunchAgents/com.mchey.dotfiles-sync.plist"
LABEL="com.mchey.dotfiles-sync"

if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: template not found at $TEMPLATE"
  echo "Make sure ~/dotfiles is cloned and up to date."
  exit 1
fi

# Ensure logs directory exists
mkdir -p "${HOME}/logs"

# Unload existing agent if loaded (idempotent)
if launchctl list "$LABEL" &>/dev/null; then
  echo "Unloading existing $LABEL..."
  launchctl unload "$TARGET" 2>/dev/null || true
fi

# Generate plist with correct paths for this user
sed "s|/Users/mchey|${HOME}|g" "$TEMPLATE" > "$TARGET"
echo "Wrote $TARGET"

# Load the agent
launchctl load "$TARGET"
echo "Loaded $LABEL"

# Verify it's running
if launchctl list "$LABEL" &>/dev/null; then
  echo "Verified: $LABEL is loaded and will run daily at 04:00 + on boot."
else
  echo "WARNING: $LABEL did not appear in launchctl list after loading."
  exit 1
fi

# Check gh availability (non-fatal — sync still works, just can't file issues)
if command -v gh >/dev/null 2>&1 || [ -x /opt/homebrew/bin/gh ] || [ -x /usr/local/bin/gh ]; then
  echo "gh CLI: found"
else
  echo "WARNING: gh CLI not found. Sync will run but cannot file GitHub issues on failure."
  echo "Install with: brew install gh && gh auth login"
fi

echo ""
echo "Done. The agent will tick once now (RunAtLoad) and then daily at 04:00."
echo "Logs: ~/logs/dotfiles-sync.log"
