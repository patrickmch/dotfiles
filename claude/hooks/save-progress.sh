#!/bin/bash
PROGRESS_FILE="${CLAUDE_PROJECT_DIR}/PROGRESS.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create the file with template if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << 'EOF'
# Project Progress

## Current Phase
<!-- What major feature/task are we working on? -->

## Last Updated
<!-- Auto-updated by hook -->

## Session Context
### Active Files
- 

### Key Variables/State
- 

### Dependencies Involved
- 

## Design Decisions Log
| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|

## Completed This Session
- 

## Next Steps
1. 

## Open Questions / Blockers
- 

## Recovery Instructions
<!-- If session cuts off, start here: -->

---
EOF
    echo "Created new PROGRESS.md"
fi

# Append a session marker if this is a new day
if ! grep -q "## Session: $(date '+%Y-%m-%d')" "$PROGRESS_FILE" 2>/dev/null; then
    echo -e "\n---\n## Session: $(date '+%Y-%m-%d')\n" >> "$PROGRESS_FILE"
fi

echo "Progress file ready at: $PROGRESS_FILE"
echo "Last updated: $TIMESTAMP"
