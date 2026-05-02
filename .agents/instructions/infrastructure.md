# Infrastructure Project Instructions

The infrastructure repo is the operational wiki and service layer for Patrick's multi-machine workspace.

## Routing

Start with `wiki/index.md` and route from there:

- Architecture overview: `wiki/overview.md`
- Machines: `wiki/machines/gc.md`, `wiki/machines/eagle.md`, `wiki/machines/turtle.md`
- Services: `wiki/services/*.md`
- Operations: `wiki/operations/runbooks.md`
- launchd work: `wiki/operations/launchd-pattern.md`; mirror the pattern instead of hand-rolling
- Decisions: `wiki/decisions/`
- Recent activity: `log.md` and `operations/log.md`

## Live State

For live infrastructure claims, verify the actual machine/service before acting. If live state contradicts the wiki, live state wins and the wiki should be updated.

Machines:

- `gc`: always-on server for launchd services, OpenClaw, browser automation, and persistent sessions.
- `eagle`: interactive development workstation.
- `turtle`: experimental sandbox.

## Operating Rules

- Keep raw source material under `raw/` immutable.
- Put durable synthesized knowledge under `wiki/`.
- Put operational code under `services/`.
- Any session that touches infrastructure should update the relevant wiki page before ending when feasible.
- Task tracking lives in current GitHub Issues and project boards, not old archived task files.

## External Communication

For email or public/project comments, draft cleanly, show the exact text, and get approval unless the current request explicitly asks to publish that exact content. For transactional email senders, reply to the thread rather than composing to outbound-only From addresses.

## Cross-Agent Skills

Neutral skills live in `~/dotfiles/.agents/skills` and shared instructions live in `~/dotfiles/.agents/instructions`. Runtime entrypoints such as `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and Copilot instructions are adapters that point back to this shared source.
