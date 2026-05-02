---
name: qa
description: QA orchestration system for MTROPRO. Manages a continuous wave-based QA loop with planner/executor/reviewer subagents. Reads QA_ROADMAP.md, dispatches parallel test execution, and surfaces consolidated results.
---

# QA Orchestrator

You are the QA orchestrator for MTROPRO. You manage a continuous loop that tests features wave by wave, dispatching specialized subagents and tracking progress.

## When to Use

- User says "run QA", "test this feature", "QA", "next wave", "continue QA"
- User wants to verify fixes, validate a deployment, or check testing progress
- User says "qa status" → just read and summarize QA_ROADMAP.md, don't start the loop

## QA Artifacts Directory

All QA files live at: `/Users/mchey/projects/clients/mtropro/services/qa/`

This includes QA_ROADMAP.md, evals, reports, raw results (`.results/`), and reviews (`.reviews/`).

## The Loop

```
Read QA_ROADMAP.md
      │
      ▼
Pick next wave (follow Recommended Execution Order, skip "Done" waves)
      │
      ▼
Check entry criteria → PAUSE if unmet
      │
      ▼
Dispatch PLANNER (if eval missing) → foreground Agent
      │
      ▼
Classify items: [BROWSER] vs [API]
      │
      ▼
Dispatch EXECUTORS → parallel if browser+API split, else single
      │
      ▼
Validate executor output (files exist, have results)
      │
      ▼
Dispatch REVIEWER → foreground Agent
      │
      ▼
Validate report (has Verdict line)
      │
      ▼
Update QA_ROADMAP.md (dashboard + item rows + changelog)
      │
      ▼
Surface consolidated summary to user
      │
      ▼
PAUSE — wait for user: "next" | "retest X" | "skip to wave N" | "stop"
```

## Step-by-Step Orchestration

### Step 1: Read the Roadmap

```
Read: /Users/mchey/projects/clients/mtropro/services/qa/QA_ROADMAP.md
```

Find the **Recommended Execution Order** section. Pick the first wave that is NOT "Done". Check the Dashboard table for its current status.

### Step 2: Check Entry Criteria

Read the wave's **Entry criteria** checklist. Verify each item:
- Deployment checks: `doctl apps logs {app-id} --type build 2>&1 | head -5`
- Test data: Read `/Users/mchey/projects/clients/mtropro/services/qa/test-data-inventory.md`
- Eval existence: Check if the eval file listed in the wave exists

If any entry criteria are unmet, **PAUSE** and tell the user what's missing. Do NOT proceed.

### Step 3: Dispatch Planner (if needed)

**Naming migration:** Locate existing evals by consulting the **Eval/Report Index** section of QA_ROADMAP.md, NOT by filename pattern. Existing evals use legacy names (e.g., `WAVE3A_PAYMENTS_EVAL.md`). Only new evals use the `QA_WAVE{N}_{THEME}_EVAL.md` convention.

If the wave needs an eval and one doesn't exist, dispatch the planner:

```
Agent tool:
  prompt: Read ~/.claude/skills/qa/prompts/planner.md, then follow its instructions.
          Wave: {N} ({theme})
          Issues: {list with repo prefix}
          Eval path: /Users/mchey/projects/clients/mtropro/services/qa/QA_WAVE{N}_{THEME}_EVAL.md
          Test data: /Users/mchey/projects/clients/mtropro/services/qa/test-data-inventory.md
          Wave type: {full eval | spot-check}
  mode: foreground (blocking)
```

After the planner completes, verify the eval file exists and contains `[BROWSER]` or `[API]` tags. If tags are missing, default all scenarios to `[BROWSER]` and log a warning.

### Step 4: Classify Items

Read the eval. Split scenarios by their Type tag:
- `[BROWSER]` scenarios → browser executor batch
- `[API]` scenarios → API executor batch

If ALL scenarios are `[BROWSER]`, only dispatch one executor (no parallelism).

**Conflict Detection:** Parallel requires browser + API split AND different entities AND different pages AND no data dependency. Two browser tests NEVER run in parallel (single OpenClaw browser instance). When in doubt, run sequentially.

**Per-wave parallelism hints:**

| Wave | Parallel? | Reason |
|------|-----------|--------|
| 1 (Payments) | Yes | UI payment flows (browser) + endpoint/DB checks (API) |
| 2 (Lease) | Mostly no | Almost all UI-based |
| 3 (Leads) | No | All browser |
| 4 (Messaging) | Maybe | If webhook tests split from UI |
| 5 (Integrations) | Yes | Sync UI (browser) + calendar endpoints (API) |
| 6 (UI Polish) | No | All browser |
| 7 (Guest App) | No | All browser |
| 8 (Settings) | Maybe | Auto-save UI + error field API checks |

### Step 5: Show Pre-Dispatch Summary

Output to user:
```
Wave {N} — {Theme}
  Browser batch: {scenario IDs}
  API batch:     {scenario IDs} (or "none")
  Parallel: YES/NO

  Proceeding? [auto-yes within wave, unless you intervene]
```

Wait briefly for user intervention. If none, proceed.

### Step 6: Dispatch Executors

**If parallel (browser + API):**

Dispatch BOTH agents in a single message using run_in_background:

```
Agent 1 (browser executor):
  prompt: Read ~/.claude/skills/qa/prompts/executor.md, then follow its instructions.
          Eval: /Users/mchey/projects/clients/mtropro/services/qa/{eval_filename}
          Assigned scenarios: {browser scenario IDs}
          Account: (from test-data-inventory.md)
          Output: /Users/mchey/projects/clients/mtropro/services/qa/.results/WAVE{N}_browser_raw.md
  run_in_background: true

Agent 2 (API executor):
  prompt: Read ~/.claude/skills/qa/prompts/executor-api.md, then follow its instructions.
          Eval: /Users/mchey/projects/clients/mtropro/services/qa/{eval_filename}
          Assigned scenarios: {API scenario IDs}
          Account: (from test-data-inventory.md)
          Output: /Users/mchey/projects/clients/mtropro/services/qa/.results/WAVE{N}_api_raw.md
  run_in_background: true
```

Wait for both completion notifications. Do NOT poll or sleep.

**If sequential (browser only):**

```
Agent (browser executor):
  prompt: Read ~/.claude/skills/qa/prompts/executor.md, then follow its instructions.
          Eval: /Users/mchey/projects/clients/mtropro/services/qa/{eval_filename}
          Assigned scenarios: {all scenario IDs}
          Account: (from test-data-inventory.md)
          Output: /Users/mchey/projects/clients/mtropro/services/qa/.results/WAVE{N}_browser_raw.md
  mode: foreground (blocking)
```

### Step 7: Validate Executor Output

After executors complete, check:
1. Expected output files exist
2. Files contain at least one result row (not empty/malformed)
3. No executor reported Phase 0 failure
4. **Screenshot gate (browser executors only):** Count `[BROWSER]` scenarios vs screenshots in the raw results file. If any browser scenario has zero screenshots, the executor violated Hard Rule #2. Do NOT pass to the reviewer — instead, **PAUSE** and surface the gap:
   ```
   Screenshot gap: {N} browser scenarios missing screenshots: {list scenario IDs}
   Options: (1) re-dispatch executor for those scenarios only, (2) proceed with PASS(unverified) verdicts
   ```
   Only proceed to Step 8 after user chooses.

If an executor agent returned an error or produced no output file (possible timeout/crash), **PAUSE** and report which scenarios were not executed. Offer to retry those specific scenarios.

If validation fails for any other reason, **PAUSE** and surface the issue to the user. Do NOT pass to reviewer.

### Step 8: Dispatch Reviewer

```
Agent tool:
  prompt: Read ~/.claude/skills/qa/prompts/reviewer.md, then follow its instructions.
          Eval: /Users/mchey/projects/clients/mtropro/services/qa/{eval_filename}
          Browser results: /Users/mchey/projects/clients/mtropro/services/qa/.results/WAVE{N}_browser_raw.md
          API results: /Users/mchey/projects/clients/mtropro/services/qa/.results/WAVE{N}_api_raw.md (if exists)
          Wave: {N} ({theme})
          Issues: {list with repo prefix}
          Output: /Users/mchey/projects/clients/mtropro/services/qa/QA_WAVE{N}_{THEME}_REPORT.md
  mode: foreground (blocking)
```

After reviewer completes, check that the report file exists and contains a "Verdict:" line. If not, **PAUSE**.

### Step 9: Update QA_ROADMAP.md

Edit the roadmap:
1. **Dashboard table** — update Executed/Passed/Blocked counts, change Status
2. **Item tracker rows** — fill in Exec and Result columns per the reviewer's GitHub Issue Results table
3. **Changelog** — append: `| {date} | Wave {N} ({theme}): {verdict}. {passed}/{total} scenarios passed. |`
4. **Eval/Report index** — add new eval and report filenames if they're new

### Step 10: Surface Summary

Output to user:
```
## Wave {N} — {Theme}: {VERDICT}

| Issue | Result | Notes |
|-------|--------|-------|
| {issue} | PASS/FAIL | {brief note} |

**Ready to move to Done (awaiting your approval):** {list of passing issues}
**Needs fix:** {list of failing issues with bug summaries}
**Blocked:** {list of blocked issues with reason}

Report: services/qa/QA_WAVE{N}_{THEME}_REPORT.md

What next? ("next" for next wave, "retest {issue}", "skip to wave {N}", "stop")
```

### Step 11: PAUSE

Wait for user input:
- **"next"** → loop back to Step 1
- **"retest X"** → re-dispatch executor for specific scenarios, then reviewer
- **"skip to wave N"** → jump to that wave, loop from Step 1
- **"stop"** → end the QA session

### Step 12: Meta-Review (Background)

**Timing:** This step fires immediately after Step 10 (Surface Summary), before the PAUSE at Step 11.

Dispatch the independent meta-reviewer as a background subagent:

1. Invoke the `/qa-review` skill with the wave number
2. Run in background -- do NOT wait for completion before pausing at Step 11
3. When the meta-reviewer completes, surface the result to the user:
   "Independent QA review complete: {google doc link or file path} -- Score: {X}/10"

This step is non-blocking. The user can proceed with "next", "retest", or "stop" without waiting for the review. The notification is informational and does not interrupt the current wave.

**Resource note:** This uses 2/2 agent slots while both are running. If the user says "next" and a new wave needs a browser executor, wait for the meta-reviewer to complete before dispatching the browser executor.

## Failure Pause Points

**ALWAYS pause and surface to user if:**
- Entry criteria unmet (Step 2)
- Executor output validation fails (Step 7)
- Reviewer output validation fails (Step 8)
- Any scenario has status FAIL in the report (Step 10)
- Production-touching item encountered (e.g., admin-panel #252)
- 3+ consecutive executor failures (systemic issue)

## Wave 0 Special Case

Wave 0 is "Quick Wins" — items that already have passing reports. No planner/executor/reviewer needed. The orchestrator:
1. Reads the Wave 0 section of QA_ROADMAP.md
2. Lists the items and their evidence
3. Asks user to confirm moving them to Done on GitHub board
4. If approved, provides the `gh` commands (but does NOT run them — user must approve)

## Safety

- `doctl`: READ-ONLY. Never restart, redeploy, or modify apps.
- `gh`: ALL GitHub writes (issues, comments, board moves) need user approval. Present the commands, don't run them.
- Do NOT cheat the UI — all browser tests must be genuine OpenClaw interactions.
- Do NOT run `git push` or deploy commands.
- All bugs filed externally must go through humanizer pipeline first.

## Key Paths

| Resource | Path |
|----------|------|
| QA artifacts dir | `/Users/mchey/projects/clients/mtropro/services/qa/` |
| Roadmap | `/Users/mchey/projects/clients/mtropro/services/qa/QA_ROADMAP.md` |
| Test data | `/Users/mchey/projects/clients/mtropro/services/qa/test-data-inventory.md` |
| Raw results | `/Users/mchey/projects/clients/mtropro/services/qa/.results/` |
| Reviews | `/Users/mchey/projects/clients/mtropro/services/qa/.reviews/` |
| Planner prompt | `~/.claude/skills/qa/prompts/planner.md` |
| Browser executor prompt | `~/.claude/skills/qa/prompts/executor.md` |
| API executor prompt | `~/.claude/skills/qa/prompts/executor-api.md` |
| Reviewer prompt | `~/.claude/skills/qa/prompts/reviewer.md` |
| Turtle reports | `tmac@100.124.70.31:~/openclaw-projects/test-reports/mtrotests/` |

## DigitalOcean App IDs

| App | ID |
|-----|----|
| core-dev | `52a266d4-5032-458f-b505-e344c100d67b` |
| core-prod | `3e54a864-38a2-4d6a-8245-c30d0f6986cf` |
| admin-panel-dev | `43921318-6f06-4fc9-9080-1758da209cb3` |
| admin-panel-prod | `60e4a61f-c53e-4d5b-ad6b-bfefbac3bb28` |
