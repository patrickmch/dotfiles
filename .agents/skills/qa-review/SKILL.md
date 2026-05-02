---
name: qa-review
description: Review QA artifacts against a scored rubric and produce a local markdown assessment. Use after a QA/test wave completes, when asked to score QA quality, or when asked for an independent QA meta-review.
---

# QA Review

Independent review of QA/testing artifacts. This neutral version defaults to local markdown output and keeps Google Docs or other external publication as an optional adapter.

## Inputs

Accept one or more of:

- A QA artifacts directory.
- A specific wave, run, release, PR, or test batch identifier.
- A request to review the most recent QA wave.
- A request to summarize all prior local reviews.

If the artifacts directory is not obvious, search the current project for likely paths such as `qa/`, `services/qa/`, `test-results/`, `playwright-report/`, `.reviews/`, `QA_ROADMAP.md`, or files containing `wave`, `qa`, `test plan`, `raw results`, or `review` in their names. Ask only if multiple plausible artifact roots exist and choosing one would change the result.

## Review Flow

1. Discover artifacts using `references/artifact-discovery.md`.
2. Score the evidence with `references/rubric.md`.
3. Write the result using the schema in `references/output-schema.md`.
4. Use local markdown output first. See `references/output-adapters.md` for optional publishing adapters.
5. Cite file paths and concrete evidence for every material claim.

## Output Rules

- Default output path: `<artifact-root>/.reviews/<review-id>_qa_review.md`.
- If the artifact root is read-only, write to the current project under `.reviews/` and state the path.
- Do not create Google Docs, comments, tickets, or external reports unless the user explicitly asks and the runtime exposes the required tools.
- Do not mark a QA wave trustworthy when raw evidence is missing. Missing artifacts should lower the relevant rubric dimensions.

## Trend Report

When asked for `all`, `trend`, or `history`:

1. Find prior local review files under `.reviews/`.
2. Extract total and dimension scores.
3. Report trajectory as improving, stable, declining, or insufficient data.
4. Include a compact markdown table in the response.
