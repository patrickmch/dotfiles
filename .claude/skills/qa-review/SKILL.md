---
name: qa-review
description: Independent QA meta-reviewer. Scores completed QA waves out of 10 against a rubric and outputs to Google Docs. Use when QA testing is complete and you want an independent quality assessment, or when the user says "/qa-review".
---

# QA Meta-Review

Independent review of completed QA waves. Reads artifacts directly from the filesystem, scores against a rubric, and outputs to Google Docs.

## When to Use

- After a `/qa` wave completes (auto-triggered as Step 14)
- User says `/qa-review`, "review the QA", "score the testing", "how good was our QA"
- User wants to verify QA quality for a specific wave

## QA Artifacts Directory

All QA files live at: `/Users/mchey/projects/clients/mtropro/services/qa/`

## Invocation

### Parse Arguments

| Input | Behavior |
|---|---|
| `/qa-review` (no args) | Review the most recent wave |
| `/qa-review wave-10` or `/qa-review 10` | Review wave 10 specifically |
| `/qa-review all` | Consolidated trend report across all reviewed waves |

### Determine Target Wave

**If a wave number is specified:** Use it directly.

**If no wave number (most recent):**
1. Read `/Users/mchey/projects/clients/mtropro/services/qa/QA_ROADMAP.md`
2. Scan the Changelog section in reverse (bottom to top)
3. Match the first entry containing `Wave {N}` where N is a number
4. Use N as the target wave
5. If no match: error with "Cannot determine most recent wave -- please specify a wave number (e.g., /qa-review wave-10)"

**If "all":** Skip to the Trend Report flow below.

### Scope Exclusions

- **Wave 0** (Quick Wins) is exempt -- board cleanup only, no testing to review
- **Deferred waves** (e.g., Wave 9) are skipped unless explicitly targeted

If the target wave is excluded, inform the user and suggest an alternative.

## Single Wave Review

### Step 1: Dispatch Meta-Reviewer

Spawn a subagent with the meta-reviewer prompt. Provide:
- The wave number
- Path to artifacts: `/Users/mchey/projects/clients/mtropro/services/qa/`
- Path to rubric: `~/.claude/skills/qa-review/rubric.md`

Read the full meta-reviewer prompt from `~/.claude/skills/qa-review/prompts/meta-reviewer.md` and dispatch the agent with it.

The meta-reviewer handles all artifact discovery, scoring, file writing, and Google Doc creation.

### Step 2: Surface Results

When the meta-reviewer completes, surface the result:

```
Independent QA review complete:
  Wave: {N} -- {Theme}
  Score: {X}/10
  Review: {google_doc_url OR local_file_path}
```

If running as a background task (auto-triggered from `/qa`), this surfaces as an informational notification.

## Trend Report (`/qa-review all`)

1. Read all files matching `/Users/mchey/projects/clients/mtropro/services/qa/.reviews/WAVE*_meta_review.md`
2. Extract the score and per-dimension scores from each
3. Build a trend table:

```
| Wave | Score | Eval | Exec | Evidence | Review | Process |
|------|-------|------|------|----------|--------|---------|
| 10   | 8/10  | 2    | 2    | 1        | 2      | 1       |
```

4. Note the trajectory: improving, stable, or declining
5. Surface the table to the user

If no review files exist: "No meta-reviews have been run yet. Use /qa-review wave-{N} to review a specific wave."

## Key Paths

| Resource | Path |
|---|---|
| Rubric | `~/.claude/skills/qa-review/rubric.md` |
| Meta-reviewer prompt | `~/.claude/skills/qa-review/prompts/meta-reviewer.md` |
| QA artifacts | `/Users/mchey/projects/clients/mtropro/services/qa/` |
| Review output | `/Users/mchey/projects/clients/mtropro/services/qa/.reviews/` |
| QA Roadmap (artifact index) | `/Users/mchey/projects/clients/mtropro/services/qa/QA_ROADMAP.md` |
| OAuth credentials | `~/.google_workspace_mcp/credentials/patrick@mcheyser.com.json` |
