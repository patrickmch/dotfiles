#!/bin/bash
# Remove em dashes from gh issue/pr commands
# " — " becomes " " (single space), standalone "—" just gets removed

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on gh issue/pr commands
if echo "$COMMAND" | grep -qE '^gh (issue|pr) (comment|create|edit)'; then
  # Remove " — " (with spaces) → single space, then any remaining standalone —
  FIXED=$(echo "$COMMAND" | sed 's/ — / /g; s/—//g')
  if [ "$FIXED" != "$COMMAND" ]; then
    ESCAPED=$(echo "$FIXED" | jq -Rs '.')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"permissionDecisionReason\":\"Removed em dashes\",\"updatedInput\":{\"command\":$ESCAPED}}}"
    exit 0
  fi
fi

# No changes needed
exit 0
