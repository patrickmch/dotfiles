#!/bin/bash
# Poll turtle-hosted agent status, pending approvals, and CrowdSolve state.
# Runs as a SessionStart hook. On turtle itself all checks are local; on any
# other host (eagle, gc) the script SSHes to turtle. (Historical note: the
# "remote" branch used to target a machine called `air` — now `eagle`.)

# Detect if we're on turtle (local) or elsewhere (SSH to turtle)
if [[ "$USER" == "tmac" || "$(hostname -s)" == "turtle-1" ]]; then
  # Running on turtle — all local
  LOCAL=true
else
  # Running on eagle / gc / other — SSH to turtle
  LOCAL=false
  TURTLE="tmac@100.124.70.31"
  TIMEOUT=10
  if ! ssh -o ConnectTimeout=3 -o BatchMode=yes "$TURTLE" "echo ok" &>/dev/null; then
    echo "turtle-1 unreachable (offline or no network)"
    exit 0
  fi
fi

echo "=== turtle-1 Agent Status ==="

if $LOCAL; then
  AGENTS=$(cd ~/openclaw-projects/test-reports 2>/dev/null && ~/ittybitty/ib list 2>/dev/null)
else
  AGENTS=$(ssh -o ConnectTimeout=$TIMEOUT "$TURTLE" "zsh -l -c 'cd ~/openclaw-projects/test-reports && ~/ittybitty/ib list 2>/dev/null'" 2>/dev/null)
fi

if [ -n "$AGENTS" ]; then
  echo "$AGENTS"
else
  echo "No agents running"
fi

echo ""

echo "=== Pending Approvals ==="
HAS_APPROVALS=false
for dir in \
  "openclaw-projects/test-reports/mtrotests" \
  "openclaw-projects/circle-community" \
  ".openclaw/workspace/skills/mtropro-ci" \
  "openclaw-projects/mtropro"; do
  if $LOCAL; then
    content=$(cat ~/"$dir"/APPROVAL.md 2>/dev/null)
  else
    content=$(ssh -o ConnectTimeout=$TIMEOUT "$TURTLE" "cat ~/$dir/APPROVAL.md 2>/dev/null")
  fi
  if [ -n "$content" ] && echo "$content" | grep -q "PENDING"; then
    echo "[$dir]"
    echo "$content" | grep -A3 "PENDING"
    HAS_APPROVALS=true
  fi
done
if [ "$HAS_APPROVALS" = false ]; then
  echo "None"
fi

echo ""

echo "=== CrowdSolve Pending Drafts ==="
if $LOCAL; then
  DRAFTS=$(ls ~/.openclaw/workspace/crowdsolve-pending/*.json 2>/dev/null | wc -l | tr -d ' ')
else
  DRAFTS=$(ssh -o ConnectTimeout=$TIMEOUT "$TURTLE" "ls ~/.openclaw/workspace/crowdsolve-pending/*.json 2>/dev/null | wc -l | tr -d ' '")
fi

if [ "$DRAFTS" -gt 0 ] 2>/dev/null; then
  if $LOCAL; then
    for f in ~/.openclaw/workspace/crowdsolve-pending/*.json; do
      python3 -c "import json; d=json.load(open('$f')); print('- {} [{}] status={}'.format(d.get('title','?'), d.get('type','?'), d.get('status','?')))" 2>/dev/null || true
    done
  else
    ssh -o ConnectTimeout=$TIMEOUT "$TURTLE" 'for f in ~/.openclaw/workspace/crowdsolve-pending/*.json; do python3 -c "import json; d=json.load(open(\"$f\")); print(\"- {} [{}] status={}\".format(d.get(\"title\",\"?\"), d.get(\"type\",\"?\"), d.get(\"status\",\"?\")))" 2>/dev/null || true; done' 2>/dev/null
  fi
else
  echo "None"
fi

echo ""

# Latest WORKLOG tail (if any agent is running)
if echo "$AGENTS" | grep -q "running"; then
  echo "=== Latest WORKLOG (last 5 lines) ==="
  if $LOCAL; then
    tail -5 ~/openclaw-projects/test-reports/mtrotests/WORKLOG.md 2>/dev/null
  else
    ssh -o ConnectTimeout=$TIMEOUT "$TURTLE" "tail -5 ~/openclaw-projects/test-reports/mtrotests/WORKLOG.md 2>/dev/null"
  fi
fi

exit 0
