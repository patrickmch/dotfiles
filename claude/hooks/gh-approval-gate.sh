#!/bin/bash
# gh-approval-gate.sh — Blocks GitHub write operations on this machine.
# Requires user approval before any gh comment/issue/pr write or git push.
# Also blocks gh writes via SSH to turtle-1.

input=$(cat)
tool_name="$CLAUDE_TOOL_USE_NAME"

if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null)
if [ -z "$command" ]; then
  command=$(echo "$input" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"$//')
fi

blocked=false
reason=""

# Direct gh writes
if echo "$command" | grep -qE 'gh\s+(issue|pr)\s+(comment|create|close|reopen|edit|review|merge)'; then
  blocked=true
  reason="GitHub issue/PR write operation"
fi

if echo "$command" | grep -qE 'gh\s+project\s+item-edit'; then
  blocked=true
  reason="GitHub project board modification"
fi

if echo "$command" | grep -qE 'gh\s+api\s+.*--(method|X)\s+(POST|PUT|PATCH|DELETE)'; then
  blocked=true
  reason="GitHub API write operation"
fi

if echo "$command" | grep -qE 'git\s+push'; then
  blocked=true
  reason="git push to remote"
fi

# SSH tunnel to turtle-1 running gh writes
if echo "$command" | grep -qE 'ssh.*tmac.*gh\s+(issue|pr)\s+(comment|create|close|reopen|edit|review|merge)'; then
  blocked=true
  reason="GitHub write via SSH to turtle-1"
fi

if echo "$command" | grep -qE 'ssh.*tmac.*git\s+push'; then
  blocked=true
  reason="git push via SSH to turtle-1"
fi

# SSH write operations on turtle-1 (destructive or state-changing)
if echo "$command" | grep -qE 'ssh.*tmac.*(rm\s|rmdir|mv\s|chmod\s|chown\s|truncate|dd\s|mkfs|kill\s|pkill|systemctl\s+(start|stop|restart|enable|disable)|crontab\s+-[er])'; then
  blocked=true
  reason="Destructive/write operation via SSH to turtle-1"
fi

if [ "$blocked" = true ]; then
  echo "APPROVAL REQUIRED: $reason" >&2
  echo "Show the user what you want to post and get explicit approval before proceeding." >&2
  echo "Once approved, the user will allow this tool call." >&2
  exit 2
fi

exit 0
