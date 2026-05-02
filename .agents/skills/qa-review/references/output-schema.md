# Output Schema

Write local markdown with this structure:

```markdown
# QA Review: <target>

- Artifact root: `<path>`
- Reviewed at: <ISO timestamp or local date/time>
- Overall score: <N>/10
- Verdict: <production-grade | trustworthy-with-gaps | targeted-reverification | weak | reject>

## Scorecard

| Dimension | Score | Evidence |
|---|---:|---|
| Eval Quality | 0-2 | ... |
| Execution Fidelity | 0-2 | ... |
| Evidence Completeness | 0-2 | ... |
| Review Accuracy | 0-2 | ... |
| Process Compliance | 0-2 | ... |

## Findings

- Ordered by severity and impact.
- Include file paths and artifact references.

## Missing Or Weak Evidence

- List gaps that materially affect trust.

## Recommendations

- Concrete follow-up checks or process fixes.

## Artifact Index

- Key files reviewed.
```
```

Keep prose concise. The review should be usable as a decision artifact, not a transcript of everything inspected.
