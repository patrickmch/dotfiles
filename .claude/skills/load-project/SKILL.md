---
name: load-project
description: Generate a structured primer for the current project — recent activity (commits, issues, PRs), in-flight work (PROGRESS.md, plan.md, log.md), recent wiki pages, raw inventory, and available tools/skills. Use at session start when you need to ground in current state without 5-10 minutes of manual reconstruction.
---

# /load-project

Generate a structured primer for the current project so the session starts grounded in current state instead of reconstructing it manually.

## When to Use

- Starting a session in a non-trivial project after time away
- Resuming work after a session restart (e.g., watchdog killed previous session)
- Switching between projects and need to rebuild context fast

## Steps

### 1. Detect project root

Walk up from `cwd` looking for `CLAUDE.md`. Use Bash:

```bash
DIR=$(pwd)
while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/CLAUDE.md" ]; then echo "$DIR"; break; fi
  DIR=$(dirname "$DIR")
done
```

If no `CLAUDE.md` is found anywhere up the tree, stop and report: "Not in a recognized project. Run from a directory under a CLAUDE.md root."

Otherwise, the printed path is the project root. Capture it; subsequent steps use it as `<root>`.

### 2. Read core files

For each of these files, if it exists, read its content. Use the Read tool. Skip silently if absent — output `(no <filename>)` in the corresponding output section.

- `<root>/PROGRESS.md` — full read; if larger than 20KB, flag size in output but still include the full content
- `<root>/plan.md` — full read
- `<root>/log.md` — last 5 dated entries (header pattern: `## [YYYY-`). If file > 50KB, tail-read instead:

  ```bash
  SIZE=$(stat -f "%z" <root>/log.md 2>/dev/null || echo 0)
  if [ "$SIZE" -gt 51200 ]; then
    tail -200 <root>/log.md | awk '/^## \[/{c++} c<=5'
  else
    awk '/^## \[/{c++} c<=5' <root>/log.md
  fi
  ```

- `<root>/operations/log.md` — same logic as `log.md` if it exists

Capture each file's content for later assembly into the output.

### 3. Walk the wiki (if exists)

If `<root>/wiki/` directory exists:

```bash
find <root>/wiki -type f -name "*.md" -exec stat -f "%m %N" {} \; | sort -rn | head -15 | awk '{print $2}'
```

For each of the 15 most-recently-modified pages, extract:
- Path (relative to `<root>/wiki/`)
- `updated:` date from frontmatter (if present, otherwise use file mtime)
- First ~200 characters of the body (after the closing `---` of frontmatter)

Helper extraction function:

```bash
extract_meta() {
  local file=$1
  local title=$(grep "^title:" "$file" | head -1 | sed 's/title: *//;s/^"//;s/"$//')
  local updated=$(grep "^updated:" "$file" | head -1 | sed 's/updated: *//')
  # Body preview: skip frontmatter, collapse newlines to spaces (not stripped — preserves word boundaries), squeeze spaces, cut to 200 chars
  local preview=$(awk '/^---$/{c++; next} c>=2' "$file" | head -10 | tr '\n' ' ' | tr -s ' ' | cut -c1-200)
  # If no frontmatter title, fall back to first H1
  if [ -z "$title" ]; then
    title=$(grep "^# " "$file" | head -1 | sed 's/^# //')
  fi
  printf "| %s | %s | %s |\n" "$title" "$updated" "$preview"
}
```

Format as a markdown table with header row. If `<root>/wiki/` does NOT exist, output `(no wiki/)` for this section.

### 4. Inventory raw/ (if exists)

If `<root>/raw/` directory exists:

```bash
# Per-subdirectory summary: count + latest mtime. Skip empty subdirs.
find <root>/raw -mindepth 1 -maxdepth 1 -type d | while read subdir; do
  count=$(find "$subdir" -type f | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    latest=$(find "$subdir" -type f -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} \; 2>/dev/null | sort -rn | head -1)
    base=$(basename "$subdir")
    echo "raw/$base/: $count files | latest: $latest"
  fi
done

# Flat files at raw/ root if any
find <root>/raw -maxdepth 1 -type f -exec stat -f "%Sm %z %N" -t "%Y-%m-%d" {} \; 2>/dev/null | sort -rn | head -10
```

For each subdirectory, output:
- Subdirectory name (e.g., `raw/transcripts/`)
- File count
- Latest file (date + filename)

**Do NOT read file contents** — this is inventory only. Sample filenames are enough; the model can fetch specific files later if relevant.

If `<root>/raw/` does NOT exist or is empty, output `(no raw/)` for this section.

### 5. Capture git state

Run all five commands. Each is independent — if one fails (e.g., not a git repo), continue with the others. If `git status` fails entirely, output `(not a git repo)` for the whole "What's been happening" section and skip step 6.

```bash
cd <root>

# Last 10 commits, oneline format
git log --oneline -10 2>&1

# Working tree status (short format)
git status --short 2>&1

# Current branch
git branch --show-current 2>&1

# Origin remote URL (used to detect GitHub repo for next step)
git remote get-url origin 2>&1

# Relative time of the last commit (for the header — e.g., "10 hours ago")
git log -1 --format='%cr' 2>&1
```

Capture all five outputs. The relative time goes into the header line; the rest go into the "What's been happening" section.

### 6. Capture GitHub issues + PRs (if applicable)

Only run if (a) `gh` CLI is available and (b) the origin remote points at github.com. Otherwise output `(GitHub data unavailable — gh CLI not installed or remote isn't GitHub)`.

```bash
# Check gh availability
which gh > /dev/null 2>&1 || { echo "(no gh CLI)"; }

# Check remote is GitHub
URL=$(git remote get-url origin 2>/dev/null)
case "$URL" in
  *github.com*) ;;
  *) echo "(remote is not GitHub: $URL)"; ;;
esac

# Open issues (10 max)
gh issue list --state open --limit 10

# Open PRs (5 max)
gh pr list --state open --limit 5
```

Format issues in the output as: `#NUMBER (priority:LABEL) Title`. Format PRs as: `#NUMBER Title — branch`.

### 7. Capture capabilities

#### Project-level MCPs / tool config

If `<root>/.claude/settings.json` exists, parse it for the relevant fields. Some projects use it as an enable list (`enabledPlugins`, `mcpServers`); others use it as a blocklist (`disabledTools`, `permissions.deny`). Surface whichever pattern applies:

```bash
SETTINGS=<root>/.claude/settings.json
if [ -f "$SETTINGS" ]; then
  python3 -c "
import json
with open('$SETTINGS') as f:
    data = json.load(f)
plugins = data.get('enabledPlugins', {})
servers = data.get('mcpServers', {})
# Different projects use different field name conventions for blocklists.
# Cover blockedTools, disabledTools, and permissions.deny.
blocked = data.get('blockedTools', []) or data.get('disabledTools', [])
deny = (data.get('permissions') or {}).get('deny', [])

enabled_count = sum(1 for v in plugins.values() if v)
if enabled_count:
    print('Enabled plugins:')
    for name, on in plugins.items():
        if on:
            print(f'  - {name}')
if servers:
    print('MCP servers:')
    for name in servers:
        print(f'  - {name}')
if blocked:
    print('Blocked tools (project denylist):')
    for t in blocked:
        print(f'  - {t}')
if deny:
    print('Permission deny list:')
    for t in deny:
        print(f'  - {t}')
if not (enabled_count or servers or blocked or deny):
    print('(settings.json present but no plugin/MCP/tool entries)')
"
else
  echo "(no project-level MCP config)"
fi
```

Note: only project-level config is listed here. User-level `~/.claude/settings.json` is intentionally skipped — those are in scope of every session and listing them is noise.

#### Project-specific skills

Skills can live in either `<root>/.claude/skills/` (Claude Code convention) or `<root>/skills/` (some projects use a top-level `skills/` directory). Check both:

```bash
for skills_dir in <root>/.claude/skills <root>/skills; do
  if [ -d "$skills_dir" ] && [ "$(ls -A "$skills_dir" 2>/dev/null)" ]; then
    echo "From $skills_dir:"
    ls "$skills_dir"
  fi
done
```

For each entry, list as `/<skill-name>` or just the directory name. If neither directory exists or both are empty, output `(no project-specific skills)`.

#### Relevant cross-project skills

The model already has visibility into user-level skills via system reminders. Don't enumerate them all. Instead, list the cross-project skills most likely to be relevant for any project session:

- `/humanizer` — text polishing (always relevant for outbound content)
- `/qa-skills` — testing orchestration (relevant for code projects)
- `/load-project` — this skill (reflexive)
- `/playwright-cli` — browser automation (when relevant)
- `/browser-profile` — isolated browser profile setup (when relevant)

Curate to ~3-5 lines based on what's likely useful for the project type.

## Output Format

After all 7 steps complete, assemble the captured data into a single structured markdown primer following this template. Output the primer as the final response from this skill.

```markdown
# Project Primer: <project-name>
Generated <ISO timestamp> · Root: <absolute path>
Branch: <name> (<dirty/clean>) · Last commit: <sha> (<relative time>)

## What's been happening

### Last 10 commits
<git log --oneline -10 output>

### Working tree
<git status --short output, or "clean">

### Open issues (<repo>)
<gh issue list output, formatted as: #N (priority:X) Title>

### Open PRs
<gh pr list output, or "(no open PRs)">

## In flight

### PROGRESS.md
<full content or "(no PROGRESS.md)">

### plan.md
<full content or "(no plan.md)">

### log.md (last 5 entries)
<entries or "(no log.md)">

### operations/log.md (last 5 entries)
<entries or "(no operations/log.md)">

## Wiki — recent pages

| Page | Updated | Preview |
|------|---------|---------|
| <relative path> | <date> | <first 200 chars> |

(Or "(no wiki/)" if absent)

## Raw — inventory only

### raw/<subdir>/: <count> files | latest: <date> <filename>

(Or "(no raw/)" if absent)

## Capabilities

### Project MCPs
<plugin/server names, or "(no project-level MCP config)">

### Project-specific skills
<skill names, or "(no project-specific skills)">

### Relevant cross-project skills
- /humanizer — text polishing
- /qa-skills — testing orchestration
- /load-project — this skill (reflexive)
```

**Choices baked in (do not deviate):**
- No TL;DR summary at the end
- Tables for tabular data
- Raw inventory is sparse — filenames + dates + sizes only, never content
- Wiki preview capped at 200 characters
- Each section is independently useful — sections that have no data should output `(no X)` rather than being omitted, so the structure stays predictable
- Output goes straight to the user as the skill's final response — do not save to a file
