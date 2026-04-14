#!/bin/bash
# bash-safety-gate.sh — PreToolUse hook that blocks dangerous Bash patterns.
#
# Returns JSON deny response for blocked commands. Uses JSON output format
# (not exit codes) so Claude sees the reason and can adjust.
#
# Reference: anthropics/claude-code#31250 (silent failure with exit codes)

set -u

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only gate Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Strip quoted strings to avoid false positives on patterns mentioned inside
# gh issue comments, --body, --comment, echo, etc. Replace single-quoted,
# double-quoted, and heredoc bodies with empty strings before matching.
STRIPPED=$(echo "$COMMAND" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

deny() {
  local reason="$1"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED by bash-safety-gate: $reason"
  }
}
EOF
  exit 0
}

# --- Blocked patterns ---

# Force push
if echo "$STRIPPED" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f\b'; then
  deny "git push --force is never allowed. Use --force-with-lease if you must."
fi

# Hard reset
if echo "$STRIPPED" | grep -qE 'git\s+reset\s+--hard'; then
  deny "git reset --hard discards work. Use git stash or git reset --soft."
fi

# Reading secrets files directly
if echo "$STRIPPED" | grep -qE 'cat\s+~/\.env|cat\s+\$HOME/\.env|cat\s+.*credentials|cat\s+.*\.secret'; then
  deny "Direct read of secrets files (.env, credentials, .secret) is blocked."
fi

# Writing to secrets
if echo "$STRIPPED" | grep -qE '>\s*~/\.env|>\s*\$HOME/\.env|tee\s+~/\.env|tee\s+\$HOME/\.env'; then
  deny "Writing to ~/.env is blocked. Secrets are managed manually."
fi

# Destructive rm patterns
if echo "$STRIPPED" | grep -qE 'rm\s+-rf\s+/|rm\s+-rf\s+~/|rm\s+-rf\s+\$HOME/|rm\s+-rf\s+\.\s'; then
  deny "Destructive rm -rf on home/root/cwd is blocked."
fi

# Killing all processes
if echo "$STRIPPED" | grep -qE 'killall|pkill\s+-9|kill\s+-9\s+-1'; then
  deny "Mass process killing is blocked."
fi

# Modifying launchd services without review
if echo "$STRIPPED" | grep -qE 'launchctl\s+(unload|remove|bootout)\s'; then
  deny "Removing launchd services requires manual review. Use launchctl kickstart for restarts."
fi

# curl to unknown domains (allow github, api.telegram.org, anthropic, tailscale, localhost)
if echo "$STRIPPED" | grep -qE '^curl\s|;\s*curl\s|&&\s*curl\s|\|\s*curl\s'; then
  if ! echo "$COMMAND" | grep -qE 'curl.*https?://(api\.github\.com|github\.com|api\.telegram\.org|api\.anthropic\.com|raw\.githubusercontent\.com|localhost|127\.0\.0\.1|100\.)'; then
    deny "curl to unapproved domain. Approved: github.com, api.telegram.org, api.anthropic.com, localhost, tailscale IPs (100.*)."
  fi
fi

# No issues found
exit 0
