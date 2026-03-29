# Global CLAUDE.md

## Environment

- Interactive dev on **eagle** (MacBook Pro M1 Pro, 32GB, mchey). Claude sessions, browser, local dev, audio transcription.
- Always-on server on **turtle** (turtle-1, tmac, 100.124.70.31). Cron, OpenClaw, agents, background tasks.
- **Incoming (Tue 2026-03-24)**: **groundcontrol / gc** (Mac Mini M4 Pro, 64GB). Replaces turtle as always-on server.
- Uses **Happy Coder** (`happy` CLI) as wrapper around `claude`. Shell context may differ from direct `claude` invocation.
- NEVER commit hardcoded secrets. ALWAYS use .env or secrets files.
- Secrets go in `~/.env` (sourced by .zshrc, globally gitignored). Never in settings.json or committed files.

## DEPRECATION: ~/code/ → ~/projects/

~/code/ is a symlink to ~/projects/. Use ~/projects/ in all new references.
When you encounter a ~/code/ reference in any file, update it to ~/projects/.

When creating project skills, read `~/projects/docs/creating-project-skills.md` first.

## Project Routing

When I mention a keyword, load that project's CLAUDE.md BEFORE acting.

| Keywords | Project | Path | Machine |
|----------|---------|------|---------|
| crowdsolve, circle, community, cohort, founders | CrowdSolve | ~/projects/crowdsolve/ | turtle |
| mtro, phillip, andre, property, tenant | MTRO | ~/projects/mtropro/ | turtle |
| midway, furnished finder, leads, rentals | Midway | ~/projects/midway/ | turtle |
| wellness, librarian, WEC, christine, health videos | Wellness Librarian | ~/projects/wellness-librarian/ | turtle |
| summit, training, athletes, climbing plan | Summit | ~/projects/summit/ + ~/projects/summit-ai/ | turtle |
| workspace, workspace-hub, email autopilot | Workspace Hub | ~/projects/workspace-hub/ | turtle |
| linkedin, outreach, prospecting | LinkedIn Outreach | ~/projects/linkedin-outreach-helper/ | turtle (stale) |
| openclaw, terry, agent, cron | OpenClaw | turtle: ~/.openclaw/ | turtle |
| invoice, stripe, billing, timesheet | Invoicing | ~/projects/scripts/invoice.py | turtle |
| email, gmail | Email | Google Workspace MCP | turtle |
| calendar, meetings, schedule | Calendar | Google Workspace MCP | turtle |
| website, portfolio, mcheyser | mcheyser.com | ~/projects/mcheyser-site/ | turtle |
| wec-landing, wec site | WEC Landing | ~/projects/wec-landing/ | turtle |
| jackson, mentoring, miller | Jackson Mentoring | ~/projects/jackson-mentoring/ | turtle |
| todos, tasks, what do I need to do | Todos | ~/projects/todos/ | turtle |
| ai presentations, workshops, ai events | AI Presentations | ~/projects/ai-presentations/ | turtle |
| ai consulting, ai services, ai clients | AI Consulting | ~/projects/ai-consulting/ | turtle |

## People Routing

When I mention a person, load the relevant project context.

| Name | Project(s) | Context Location |
|------|-----------|-----------------|
| Phil / Phillip | MTRO | ~/context/people/phillip-galaviz/summary.md |
| Andre | MTRO | ~/context/people/andre-galaviz/summary.md |
| Christine | Wellness Librarian, WEC Landing | ~/context/people/christine-smith/summary.md |
| Tim | CrowdSolve | ~/context/people/tim-wolters/summary.md |
| Lillian | Coaching | ~/context/people/lillian-bailey/summary.md |
| Brad | Meetings | ~/context/people/brad/summary.md |
| Nicole | Meetings | ~/context/people/nicole-macaraig/summary.md |
| James Anderson | Coaching | ~/context/people/james-anderson/summary.md |
| David Elliot | Coaching | ~/context/people/david-elliot/summary.md |
| Liz | Coaching | ~/context/people/liz-long-rottman/summary.md |
| Rotem | Meetings | ~/context/people/rotem-brayer/summary.md |
| Mahdi | Meetings | ~/context/people/mahdi-omar/summary.md |
| Jackson / Jackson Miller | Jackson Mentoring | ~/context/people/jackson-miller/summary.md |
| Wendy / Wendy Miller | Jackson Mentoring | ~/context/people/jackson-miller/summary.md |
| Gary / Gary Miller | Jackson Mentoring | ~/context/people/jackson-miller/summary.md |
| James Hwang | MTRO | ~/context/people/james-hwang/summary.md |
| Allen / Allen Duan | MTRO | ~/context/people/allen-duan/summary.md |
| Natalie / Natalie Levy | AI Presentations, AI Consulting | ~/context/people/natalie-levy/summary.md |
| Chris McDermut / Christopher | AI Presentations, AI Consulting | ~/context/people/christopher-mcdermut/summary.md |
| Megan | Personal | ~/context/people/megan-reznicek/summary.md |

## MTRO PRO Duplication Warning

Two copies exist and are NOT synced:
- **eagle**: `~/projects/mtropro/` (partial clone, interactive dev)
- **turtle**: `~/projects/mtropro/` (full monorepo, push disabled, QA pipeline)

Different branches and commits. ALWAYS verify which copy and git state before working on MTRO.

## Deep Reference Index

Load via @path ONLY when the current task needs them.

| Resource | Location |
|----------|----------|
| Workspace Principles | `~/projects/.orchestrator/PRINCIPLES.md` |
| Circle.so API docs | ~/projects/circle-knowledge-base/data/ |
| Meeting transcripts | ~/projects/meeting-transcripts/ (by person) |
| WEC video data | ~/Documents/wellness_evolution_community/ |
| ai-humanizer | ~/ai-humanizer/ |
| OpenClaw docs | turtle: ~/.openclaw/workspace/ |
| Inactive projects | ~/projects/.orchestrator/inactive-projects.md |
| Relationship map | ~/projects/.orchestrator/relationship-map.md |
| Context DB + query CLI | `~/context/scripts/query.py` |

## Cross-Project Dependencies

```
summit ──▶ summit-ai (RAG backend)
linkedin-outreach-helper ──▶ llm_router
outreach-judge ──▶ llm_router
workspace-hub ──▶ project emails/ dirs (filing)
scripts/invoice.py ──▶ my_gcal_meetings (credentials)
mtropro ──▶ DigitalOcean (11 apps)
midway ──▶ Railway
wellness-librarian ──▶ Supabase pgvector, Railway
```

## Two-Machine Architecture

**pro** (MacBook Pro M1 Pro, 32GB) = interactive dev. Claude sessions, browser, local dev. Not always-on.
**turtle** (Mac Mini, 16GB) = always-on server. Cron, OpenClaw, agents, background tasks, browser automation.

| Task needs... | Run on... |
|---------------|-----------|
| Interactive development | pro |
| Claude sessions | pro |
| Google Workspace MCP | pro |
| Browser automation (claude-in-chrome) | pro |
| Schedule / background / cron | turtle |
| OpenClaw agents | turtle |
| Browser automation (headless/scraping) | turtle |
| Telegram approval flow | turtle |

```bash
# From pro: mosh into turtle for server tasks
mosh-turtle

# On turtle: everything is local
openclaw status
openclaw cron list
openclaw agent --to telegram --message "..." --deliver
```

Concurrency limits: pro max 5 agents (32GB). turtle max 5 agents (16GB).

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

```bash
# Each worker explores independently, reports back
ib new-agent --worker --name research-1 --model sonnet "Research [topic A]"
ib new-agent --worker --name research-2 --model sonnet "Research [topic B]"
ib new-agent --worker --name research-3 --model sonnet "Research [topic C]"

# Monitor all
ib watch

# Lead synthesizes findings after workers complete
```

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
2. If project-specific → add to that project's CLAUDE.md under Rules or Gotchas.
3. If cross-cutting → add to ~/projects/.orchestrator/PRINCIPLES.md in the correct section.
4. Write in imperative voice. 1-3 lines. Do NOT append to the bottom. Place it in the right section.
5. Read the file first. Propose the edit as a diff. Wait for approval on significant additions.

NEVER let a hard-won lesson exist only in conversation history. Capture it immediately.

### Context Loading

Load project context on demand. NEVER load all projects at once. Pull only what the current task requires. For full orchestration patterns, security model, or trust ladder: load `~/projects/.orchestrator/PRINCIPLES.md`.

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

*Last Updated: 2026-03-22*
*Workspace principles and detailed patterns: `~/projects/.orchestrator/PRINCIPLES.md`*
