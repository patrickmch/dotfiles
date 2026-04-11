# Global System Preferences

Workspace schema (project routing, people, directory structure): `~/projects/CLAUDE.md`

## Environment

Claude sessions can run on any machine in the fleet. A SessionStart hook (`~/.claude/hooks/detect-machine.sh`) emits a `CURRENT_MACHINE:` line into the session-reminder block at startup — **trust that over any assumption in this file**. The fleet:

- **eagle** — MacBook Pro M1 Pro, 32GB, mchey @ 100.116.125.97. Interactive dev, browser, local dev, audio recording, mbsync. Not always-on.
- **gc / groundcontrol** — Mac Mini M4 Pro, 64GB, mchey @ 100.118.247.22. Always-on server. Cron, OpenClaw, agents, background tasks, persistent `claude-infra` Telegram session.
- **turtle** — turtle-1, tmac @ 100.124.70.31. Experimental OpenClaw sandbox. No production services.
- Uses **Happy Coder** (`happy` CLI) as wrapper around `claude`. Shell context may differ from direct `claude` invocation.
- NEVER commit hardcoded secrets. ALWAYS use .env or secrets files.
- Secrets go in `~/.env` (sourced by .zshrc, globally gitignored). Never in settings.json or committed files.
- Always output URLs as plain text (e.g. `https://example.com`), never as markdown links (`[text](url)`). Markdown links are not visible in the CLI console.

## DEPRECATION: ~/code/ → ~/projects/

~/code/ is a symlink to ~/projects/. Use ~/projects/ in all new references.
When you encounter a ~/code/ reference in any file, update it to ~/projects/.

## ~/projects/ is for Patrick's work only

~/projects/ contains organized project work that follows the client-project-template pattern. External programs (cloned upstream repos, SDKs, tools you use but didn't build) go in ~/, not ~/projects/. If you need to clone someone else's repo to build or run it, put it in the home directory.

When creating project skills, read `~/projects/docs/creating-project-skills.md` first.

## Three-Machine Architecture

**eagle** (MacBook Pro M1 Pro, 32GB) = interactive dev workstation. Browser, local dev. Not always-on.
**gc** (Mac Mini M4 Pro, 64GB) = always-on server. Cron, OpenClaw, agents, background tasks, browser automation, persistent Claude sessions.
**turtle** (2014 MBP, 16GB) = experimental sandbox. OpenClaw experimentation, throwaway agent work. No production services.

The session you're reading this in could be running on any of them — `CURRENT_MACHINE` (from the SessionStart hook) is ground truth. Use the routing table below to decide where *new* work should happen, and use `ssh <host>` only when you're not already there.

| Task needs... | Run on... |
|---------------|-----------|
| Interactive development | eagle |
| Claude sessions | any (gc hosts the persistent `claude-infra` Telegram session; eagle for ad-hoc; turtle for experiments) |
| Google Workspace MCP | eagle |
| Browser automation (claude-in-chrome) | eagle |
| Schedule / background / cron | gc |
| OpenClaw agents (production) | gc |
| Browser automation (headless/scraping) | gc (via `ssh gc "~/bin/ocp browser ..."` if not already on gc) |
| Telegram approval flow | gc |
| OpenClaw experiments / sandbox | turtle |

```bash
# Reach server tasks (run from eagle or turtle; skip the ssh if already on gc)
ssh gc

# ocp lives in ~/bin on gc — full path required because ~/bin is not in SSH PATH
~/bin/ocp status
~/bin/ocp cron list
~/bin/ocp agent --to telegram --message "..." --deliver

# OCP browser automation on gc (wrap in `ssh gc "..."` only if not already on gc):
ssh gc "~/bin/ocp browser navigate 'https://example.com'"
ssh gc "~/bin/ocp browser snapshot"                        # get element refs
ssh gc "~/bin/ocp browser click e13"                       # click by ref ID
ssh gc "~/bin/ocp browser type e11 'hello@example.com'"    # type into field
ssh gc "~/bin/ocp browser screenshot"                      # capture image

# Reach experimental sandbox
ssh turtle
```

**OpenClaw vs Playwright**: OpenClaw (`ocp`) is the browser automation tool on gc — use it via SSH commands above. The `mcp__plugin_playwright_playwright__*` tools in your session are a DIFFERENT tool (local Playwright). For headless browser work (scraping, form fills, QA), use OCP on gc.

**CAPTCHAs**: When OCP hits a CAPTCHA on gc, there is currently no way to solve it remotely. The OCP dashboard (port 18789) is a config UI, not a live browser view. Instead, use eagle's local Chrome (claude-in-chrome) for tasks that require authenticated browser sessions.

Concurrency limits: eagle max 5 agents (32GB). gc max 10-15 agents (64GB). turtle max 5 agents (16GB).

### Interactive TUI Testing via tmux (gc)

For testing interactive TUI apps (Zellij, Emacs, etc.) that need a real TTY, use tmux on gc as a remote-controlled terminal. This bypasses the "can't press keys via SSH" limitation.

```bash
# Start the app in tmux
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux new-session -d -s test -x 200 -y 50 'TERM=xterm-256color <app>'"
sleep 5

# Send keystrokes (Escape, Space, Alt+x, Ctrl+\, typed text, Enter)
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux send-keys -t test Escape"
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux send-keys -t test Space"
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux send-keys -t test M-t"        # Alt+t
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux send-keys -t test C-\\\\"     # Ctrl+\
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux send-keys -t test 'anagram'"  # type text
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux send-keys -t test Enter"

# Capture screen output (see what the user would see)
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux capture-pane -t test -p"

# Cleanup
ssh gc "export PATH=/opt/homebrew/bin:\$PATH; tmux kill-server"
```

---

## Architecture Patterns

### Agent Output Rules (CRITICAL — applies to ALL agent work)

Agents do work LOCALLY. They NEVER push, send, post, or publish without explicit approval. The flow is always:

1. **Agent writes locally.** Code changes, drafts, plans, docs — all written to local files. No remote actions.
2. **Agent surfaces the work.** The lead agent (or the agent itself if solo) presents what was done: the content, a summary, a diff, or a file path. Show enough that Patrick can evaluate without reading every line.
3. **[PAUSE].** The agent stops and asks for input. Example: "Here's the doc. Want me to create a branch and PR?" or "Here's the draft email. Want me to send?"
4. **Patrick approves, edits, or rejects.** Only after explicit "go" does the agent take any remote action (push, PR, send, post, deploy).

This means:
- `ib` workers write code but do NOT `git push`. The lead surfaces the diff and asks to push.
- Content agents write drafts but do NOT post. The lead presents the draft and score and asks to post.
- Email agents draft but do NOT send. The lead presents the draft and asks to send.
- If an agent needs Patrick's input mid-task (ambiguous requirement, design decision, blocked), it STOPS and surfaces the question. Do not guess. Do not proceed with assumptions on anything consequential.
- When multiple agents are running, the lead agent collects and surfaces all pending approvals together rather than interrupting one at a time.

### Plan → Execute → Review

EVERY non-trivial task uses this pattern. Each role is a SEPARATE ittybitty agent.

```bash
# 1. PLANNER (Opus) — analyzes, writes eval, produces plan
ib new-agent --name planner --model opus "Read the codebase. Write an EVAL
first (how we verify success). Then write a plan with [PAUSE] points.
Output the plan for approval."

# 2. EXECUTOR (Sonnet, --worker) — implements the plan
ib new-agent --worker --name coder --model sonnet "Implement the approved
plan at [path]. Do not deviate. Log progress to PROGRESS.md."

# 3. REVIEWER (Sonnet, --worker) — runs the eval
ib new-agent --worker --name reviewer --model sonnet "Run the eval defined
by the planner. Report pass/fail per criterion. If anything fails, document
what needs fixing."
```

The planner writes the EVAL before the plan. If you cannot define how to verify success, the task is not ready. Go back and clarify.

Skip this for: typos, one-line changes, simple lookups, status checks.
Use this for: feature work, refactors, bug fixes, multi-file changes, anything touching production, anything > 30 minutes.
For new projects or major features, use `/deep-project` to decompose before planning. For implementation, use `/deep-implement` over ad-hoc coding.

### Parallel Exploration

For research, audits, large codebase analysis, or any task where multiple independent questions need answers: spawn parallel worker agents.

ALWAYS use parallel agents when there are 2+ independent workstreams. Do not do them sequentially.

### Worker Role Scoping

When spawning workers, restrict their tools:

- **Coder** (`--worker`): Read, Write, Edit, Glob, npm/python, git diff/status/add/commit. NO git push, SSH, curl, .env writes.
- **Tester** (`--worker`): Read, Glob, test runners only. NO Write, Edit, git, SSH.
- **Reviewer** (`--worker`): Read, Glob, git diff/log only. NO Write, Edit, push, SSH.
- **Content** (`--worker`): Read, Write (drafts only), ai-humanizer. NO curl, SSH, API calls.

Workers CANNOT spawn sub-agents. Only manager agents can spawn.

---

## Memory Protocol

### Automatic
- **claude-mem**: Captures session activity, injects summaries into future sessions. Per-directory. Ambient. You do not manage this.
- **Auto Memory**: Learns from corrections. On by default.

### PROGRESS.md (MANDATORY for active projects)

Maintain a `PROGRESS.md` in every active project root. Update after every significant task. Include:
- **Current Status**: what phase, what's done, what's next
- **Design Decisions**: every significant choice with rationale
- **Session Context**: key variables, file paths, dependencies
- **Blockers/Questions**: unresolved issues

Update BEFORE any long-running operation. A fresh session must be able to continue seamlessly from PROGRESS.md alone.

### Learning Capture (MANDATORY)

When you discover something that would be useful in future sessions:

1. Classify: Is this project-specific or cross-cutting?
2. If project-specific → update that project's wiki or CLAUDE.md.
3. If cross-cutting → add to ~/projects/docs/client-project-template.md in the correct section.
4. Write in imperative voice. 1-3 lines. Do NOT append to the bottom. Place it in the right section.
5. Read the file first. Propose the edit as a diff. Wait for approval on significant additions.

NEVER let a hard-won lesson exist only in conversation history. Capture it immediately.

### Context Loading

Load project context on demand. NEVER load all projects at once. Pull only what the current task requires. For full orchestration patterns, security model, or trust ladder: load `~/projects/docs/client-project-template.md`.

---

## Hard Rules

NEVER do any of the following without explicit approval. No exceptions.

- Send emails, DMs, or messages to any external service
- Create or edit posts on CrowdSolve/Circle or any public platform
- Run OpenClaw write commands on turtle
- Deploy to production (Railway, DigitalOcean, Vercel, any hosting)
- Execute any Stripe/payment operation
- Git push to ANY remote branch
- Modify credentials or .env files
- Take any action that costs money or contacts a person

Violations of these rules break trust. Always [PAUSE] and present what you intend to do.

---

## External Content Rules

ANY text that will be read by someone other than Patrick MUST go through the humanizer MCP tools before sending. No exceptions. This includes GitHub comments, Circle posts, emails, LinkedIn messages, Slack messages, client communications, and any other external-facing text.

1. Draft the content
2. Run it through `humanizer_fix`, then `humanizer_score` (target under 10)
3. If score > 10, use `humanizer_analyze`, rewrite, re-score until it passes
4. Present draft + score to Patrick
5. [PAUSE] — NEVER send, post, or publish without explicit approval

---

*Last Updated: 2026-04-05*
*Workspace schema: `~/projects/CLAUDE.md`*
*Workspace principles and detailed patterns: `~/projects/docs/client-project-template.md`*
