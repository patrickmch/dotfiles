# QA Review Rubric

Score each dimension from 0-2 for a total score out of 10. Score independently; a strong dimension does not compensate for a weak one.

## Eval Quality

- 0: Missing plan, missing pass/fail criteria, no severity or scope.
- 1: Covers major paths but has incomplete data references, vague expected results, or unclear dependencies.
- 2: Comprehensive scenarios with severity, validated test data, clear pass/fail criteria, and explicit dependencies.

## Execution Fidelity

- 0: Execution substituted code review or commentary for the required tests.
- 1: Most steps executed, but some scenarios lack action traces, command output, screenshots, API evidence, or completion notes.
- 2: Every planned step executed with concrete action traces and environment checks.

## Evidence Completeness

- 0: No raw evidence or evidence cannot independently support verdicts.
- 1: Evidence exists for most scenarios, but some verdicts depend on unsupported prose.
- 2: Evidence covers every scenario and a reviewer can verify each verdict from artifacts alone.

## Review Accuracy

- 0: Verdicts contradict raw evidence or pass skipped scenarios.
- 1: Mostly correct, with minor unsupported claims or severity mismatches.
- 2: Verdicts are traceable to evidence, severity is defensible, and ambiguous design decisions are flagged instead of auto-passed.

## Process Compliance

- 0: Required process gates were skipped or final artifacts are missing.
- 1: Most process steps followed, with minor gaps in changelog, dashboard, evidence quality notes, or report format.
- 2: Entry checks, evidence gates, report writing, dashboard/changelog updates, and review handoff all match the project process.

## Score Interpretation

- 9-10: Production-grade QA.
- 7-8: Trustworthy with minor gaps.
- 5-6: Some gaps undermine confidence; targeted re-verification needed.
- 3-4: Systemic issues; several verdicts questionable.
- 0-2: Reject; rerun the wave.
