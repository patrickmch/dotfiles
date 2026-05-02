# Artifact Discovery

Use structured artifact discovery before scoring.

## Candidate Files

Look for:

- QA roadmaps or indexes: `QA_ROADMAP.md`, `qa-roadmap.md`, `test-plan.md`, `checklist.md`.
- Plans/evals: files with `eval`, `plan`, `scenario`, `wave`, or `checklist` in the name.
- Raw execution: files with `raw`, `results`, `execution`, `screenshots`, `trace`, `api`, or `browser` in the name.
- Final reports: files with `report`, `review`, `summary`, or `verdict` in the name.
- Machine artifacts: Playwright reports, screenshots, traces, junit/xml/json result files, and logs.

## Selection Rules

- Prefer artifacts in the requested wave/run directory.
- If multiple retries exist, score the most recent complete retry and mention earlier attempts as context.
- If a plan exists but no raw execution exists, score execution and evidence dimensions low.
- If raw evidence exists but no final report exists, score review accuracy low and still assess what the evidence supports.
- If artifact names are ambiguous, use timestamps and roadmap/changelog references to select the target set.
