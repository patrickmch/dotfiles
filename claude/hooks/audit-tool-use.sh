#!/bin/bash
# audit-tool-use.sh — PostToolUse hook that logs every tool call to an audit file.
#
# Logs tool name, input summary, timestamp, session ID, and working directory
# to ~/logs/audit/claude-tools.jsonl (append-only JSONL).
#
# This is observability only — always exits 0, never blocks.

set -u

INPUT=$(cat)
AUDIT_DIR="${HOME}/logs/audit"
AUDIT_FILE="${AUDIT_DIR}/claude-tools.jsonl"

mkdir -p "$AUDIT_DIR"

# Extract fields from hook input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"' 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null)
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Derive project name from cwd
PROJECT=$(echo "$CWD" | sed -n 's|.*/projects/clients/\([^/]*\).*|\1|p')
if [ -z "$PROJECT" ]; then
  PROJECT=$(echo "$CWD" | sed -n 's|.*/projects/\([^/]*\).*|\1|p')
fi
if [ -z "$PROJECT" ]; then
  PROJECT="unknown"
fi

# For Bash commands, truncate long commands in the log (keep first 500 chars)
if [ "$TOOL_NAME" = "Bash" ]; then
  TOOL_INPUT=$(echo "$INPUT" | jq -c '{command: (.tool_input.command // "" | .[0:500]), description: (.tool_input.description // "")}' 2>/dev/null)
fi

# Write JSONL entry
jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg session "$SESSION_ID" \
  --arg project "$PROJECT" \
  --arg cwd "$CWD" \
  --argjson input "$TOOL_INPUT" \
  '{ts: $ts, tool: $tool, project: $project, session: $session, cwd: $cwd, input: $input}' \
  >> "$AUDIT_FILE" 2>/dev/null

exit 0
