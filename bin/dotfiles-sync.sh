#!/usr/bin/env bash
# dotfiles-sync.sh — daily launchd-triggered sync for ~/dotfiles with failure surfacing.
#
# Runs once daily via com.mchey.dotfiles-sync.plist on each machine (gc, eagle, turtle).
# Goal: every machine stays in lockstep with patrickmch/dotfiles on GitHub automatically,
# and if anything goes wrong (merge conflict, network error, local drift), a GitHub issue
# gets filed to McHeyser/infrastructure so the failure doesn't silently disappear into
# ~/logs/ where it'll be ignored until the next audit.
#
# Parent tracker: McHeyser/infrastructure — "Fleet-wide sync + backup pattern"
# Design notes:
#   - NEVER auto-pushes, NEVER auto-merges. --ff-only only.
#   - Dedups failure issues on title so repeat failures don't spam.
#   - Silent exit on healthy state (up-to-date + clean). All other states are surfaced.
#
# Exit codes:
#   0 = healthy (up-to-date, or successful ff-only pull)
#   1 = failure surfaced (issue filed or attempted)

set -u

# Source secrets (GH_TOKEN for gh CLI auth under launchd, which has no env vars)
if [ -f "${HOME}/.env" ]; then
  # shellcheck disable=SC1091
  source "${HOME}/.env"
fi

LOG="${HOME}/logs/dotfiles-sync.log"
DOTFILES="${HOME}/dotfiles"
HOSTNAME_SHORT=$(hostname -s 2>/dev/null || hostname)
REPO="McHeyser/infrastructure"

# Resolve gh CLI path — launchd's default PATH may not include homebrew bin dirs
if command -v gh >/dev/null 2>&1; then
  GH=$(command -v gh)
elif [ -x /opt/homebrew/bin/gh ]; then
  GH=/opt/homebrew/bin/gh
elif [ -x /usr/local/bin/gh ]; then
  GH=/usr/local/bin/gh
else
  GH=""
fi

mkdir -p "$(dirname "$LOG")"

log() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$HOSTNAME_SHORT" "$*" >> "$LOG"
}

# File a GitHub issue to surface a sync failure.
# Dedups against open issues with the same title so we don't spam on repeated failures.
file_failure_issue() {
  local subject="$1"
  local error_body="$2"
  local title="dotfiles-sync failure on ${HOSTNAME_SHORT}: ${subject}"

  if [ -z "$GH" ]; then
    log "ERROR: gh CLI not found on PATH or standard homebrew paths — cannot file failure issue. subject='$subject'"
    return 1
  fi

  # Dedup: look for an existing open issue with the same title
  local existing
  existing=$("$GH" issue list --repo "$REPO" --search "\"$title\" in:title state:open" --limit 1 --json number --jq '.[0].number // empty' 2>/dev/null || echo "")
  if [ -n "${existing:-}" ]; then
    log "open issue #$existing already matches '$title' — not duplicating"
    return 0
  fi

  local issue_body
  issue_body="This issue was filed automatically by \`com.mchey.dotfiles-sync\` on \`${HOSTNAME_SHORT}\` because dotfiles-sync hit a state it couldn't auto-resolve. Surfaced here (rather than dying silently in launchd logs) per the fleet-sync pattern.

## Error

${subject}

## Details

\`\`\`
${error_body}
\`\`\`

## Context

- Machine: \`${HOSTNAME_SHORT}\`
- User: \`$(whoami)\`
- Time: \`$(date '+%Y-%m-%d %H:%M:%S %z')\`
- Dotfiles path: \`${DOTFILES}\`
- Script: \`$0\`
- Log: \`${LOG}\`

## To resolve

1. SSH to \`${HOSTNAME_SHORT}\`
2. \`cd ${DOTFILES}\`
3. Check \`git status\` and \`git log --oneline -5\`
4. Resolve the conflict / push the local commits / fix whatever the subject says
5. Close this issue

The launchd agent will continue ticking daily at 4:00 AM. Dedup is on issue title, so if the same problem recurs before you close this, no new issue is filed."

  if "$GH" issue create --repo "$REPO" --title "$title" --label "task,priority:med" --body "$issue_body" >> "$LOG" 2>&1; then
    log "failure issue filed: $title"
    return 0
  else
    log "FAILED to file failure issue for: $title"
    return 1
  fi
}

# --- main ---

cd "$DOTFILES" 2>/dev/null || {
  log "cannot cd to $DOTFILES"
  file_failure_issue "cannot cd to ~/dotfiles" "Directory $DOTFILES does not exist or is not accessible on this host. Possibly dotfiles have never been checked out here."
  exit 1
}

# Sanity: verify it's actually a git repo
if [ ! -d .git ]; then
  log "$DOTFILES is not a git repo (no .git dir)"
  file_failure_issue "~/dotfiles is not a git repo" "$DOTFILES exists but has no .git directory — dotfiles not properly cloned here."
  exit 1
fi

# Fetch
FETCH_OUTPUT=$(git fetch origin 2>&1)
FETCH_RC=$?
if [ $FETCH_RC -ne 0 ]; then
  log "git fetch failed (rc=$FETCH_RC): $FETCH_OUTPUT"
  file_failure_issue "git fetch failed" "Exit code: $FETCH_RC

Output:
$FETCH_OUTPUT"
  exit 1
fi

# Figure out current branch + remote ref
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo main)
REMOTE_REF="origin/${CURRENT_BRANCH}"

# Count behind/ahead/dirty
BEHIND=$(git rev-list --count "HEAD..${REMOTE_REF}" 2>/dev/null || echo 0)
AHEAD=$(git rev-list --count "${REMOTE_REF}..HEAD" 2>/dev/null || echo 0)
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')

log "state: branch=${CURRENT_BRANCH} behind=${BEHIND} ahead=${AHEAD} dirty=${DIRTY}"

# Fully clean and in sync — silent exit
if [ "$BEHIND" -eq 0 ] && [ "$AHEAD" -eq 0 ] && [ "$DIRTY" -eq 0 ]; then
  exit 0
fi

# Behind, clean tree, no local commits — attempt ff-only pull
if [ "$BEHIND" -gt 0 ] && [ "$DIRTY" -eq 0 ] && [ "$AHEAD" -eq 0 ]; then
  log "behind by $BEHIND commits with clean tree — attempting ff-only pull"
  PULL_OUTPUT=$(git pull --ff-only origin "$CURRENT_BRANCH" 2>&1)
  PULL_RC=$?
  if [ $PULL_RC -eq 0 ]; then
    log "ff-only pull succeeded"
    exit 0
  else
    log "ff-only pull failed (rc=$PULL_RC): $PULL_OUTPUT"
    file_failure_issue "ff-only pull failed" "Branch: $CURRENT_BRANCH
Behind by: $BEHIND
Ahead by: $AHEAD
Exit code: $PULL_RC

Output:
$PULL_OUTPUT"
    exit 1
  fi
fi

# Dirty working tree — not safe to pull even if behind
if [ "$DIRTY" -gt 0 ]; then
  log "dirty tree: $DIRTY uncommitted change(s)"
  file_failure_issue "dirty working tree prevents sync" "Branch: $CURRENT_BRANCH
Behind by: $BEHIND
Ahead by: $AHEAD
Dirty files: $DIRTY

git status --short:
$(git status --short)"
  exit 1
fi

# Clean but ahead of remote (unpushed commits) and not behind — file a reminder
if [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -eq 0 ]; then
  log "$AHEAD local commits not pushed"
  file_failure_issue "$AHEAD unpushed local commit(s)" "Branch: $CURRENT_BRANCH
Ahead by: $AHEAD commits

Commits:
$(git log --oneline "${REMOTE_REF}..HEAD")"
  exit 1
fi

# Diverged (both ahead and behind) — can't ff-only, can't auto-merge
if [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then
  log "diverged: ahead=$AHEAD behind=$BEHIND"
  file_failure_issue "diverged from remote ($AHEAD ahead, $BEHIND behind)" "Branch: $CURRENT_BRANCH
Ahead by: $AHEAD
Behind by: $BEHIND

Local-only commits:
$(git log --oneline "${REMOTE_REF}..HEAD")

Remote-only commits:
$(git log --oneline "HEAD..${REMOTE_REF}")"
  exit 1
fi

# Unreachable in theory
log "unexpected state — exiting 0 out of caution"
exit 0
