# QA Meta-Review Rubric

Scoring criteria for independent QA wave reviews. Each dimension is scored 0-2. Total score out of 10.

## Dimensions

### 1. Eval Quality (0-2)

Was the test plan well-written?

| Score | Criteria |
|---|---|
| 0 | Missing scenarios, no severity levels, no pass/fail criteria |
| 1 | Covers happy paths with criteria, but test data refs not validated against inventory, or UI labels assumed from issue titles without verification |
| 2 | Comprehensive scenarios with severity levels. Test data IDs validated against test-data-inventory.md. UI labels verified against deployed app. Clear pass/fail criteria. Dependencies between scenarios explicitly noted. |

**Check against:** `~/.claude/skills/qa/prompts/planner.md`

**Evidence to cite:** Scenario count, severity distribution, test data ID accuracy, pass/fail criteria presence, type tags ([BROWSER]/[API]) on all scenarios.

### 2. Execution Fidelity (0-2)

Did the executor follow the eval and agent docs?

| Score | Criteria |
|---|---|
| 0 | Code review substituted for browser testing, eval steps skipped, no screenshots captured |
| 1 | Most steps executed with screenshots, but some scenarios missing ref IDs in observations, or some eval steps partially covered |
| 2 | Every eval step executed. Screenshots for every scenario. Factual observations reference specific ref IDs (e.g., "clicked e13"). Phase 0 environment check verified before testing. |

**Check against:** `~/.claude/skills/qa/prompts/executor.md` (Hard Rules section)

**Evidence to cite:** Screenshot count vs scenario count, browser command presence (navigate/click/type/snapshot), ref ID mentions in observations, Phase 0 pass/fail.

### 3. Evidence Completeness (0-2)

Is the raw evidence sufficient to independently verify verdicts?

| Score | Criteria |
|---|---|
| 0 | No screenshots, generic observations without browser actions, results could not be verified independently |
| 1 | Screenshots present for most scenarios, observations mostly reference browser actions, but some gaps where evidence is text-only |
| 2 | Full screenshot coverage. Every observation ties to a specific browser command or API call. A reader with no other context could verify each verdict from the raw results alone. |

**Check against:** `~/.claude/skills/qa/prompts/reviewer.md` (Evidence Validation Gates)

**Evidence to cite:** Scenarios with screenshots / total scenarios, scenarios with browser commands / total [BROWSER] scenarios, any observations that cite code files instead of browser interactions.

### 4. Review Accuracy (0-2)

Did the reviewer correctly judge pass/fail against the eval?

| Score | Criteria |
|---|---|
| 0 | Verdicts contradict raw evidence. PASS given for scenarios with skipped steps. Severity misclassification. |
| 1 | Most verdicts correct. Minor misalignments: report claims something the raw evidence doesn't fully support, or a design decision was silently passed without flagging. |
| 2 | Every verdict traceable to raw evidence with specific quotes. Evidence validation gates (browser commands, screenshots, step completeness, no developer hearsay) applied. Bugs properly severitied. Design decisions flagged as needing human input rather than auto-passed. |

**Check against:** `~/.claude/skills/qa/prompts/reviewer.md` (Rules for Judging Results, Evidence Validation Gates)

**Evidence to cite:** Specific scenarios where report verdict differs from what raw evidence shows. Missed bugs. Incorrectly passed design decisions.

### 5. Process Compliance (0-2)

Were the QA skill docs followed end-to-end?

| Score | Criteria |
|---|---|
| 0 | Hard rules violated (no screenshots, code review substitution for [BROWSER] scenarios). Roadmap not updated. |
| 1 | Most process steps followed. Minor gaps: report not mirrored to turtle, changelog entry incomplete, evidence quality section missing from report. |
| 2 | Full compliance with SKILL.md orchestration flow: Phase 0 checked, entry criteria verified, validation gates applied (Gates A-D), roadmap dashboard updated, changelog appended, report mirrored to turtle, evidence standards met. |

**Check against:** `~/.claude/skills/qa/SKILL.md` (Steps 1-13, Evidence Requirements)

**Evidence to cite:** Roadmap changelog entry accuracy, dashboard counts match report, report file exists, turtle mirror attempted.

## Score Interpretation

| Range | Meaning | Action |
|---|---|---|
| 9-10 | Excellent -- production-grade QA | No action needed |
| 7-8 | Good -- minor gaps, results trustworthy | Note improvements for next wave |
| 5-6 | Acceptable -- some gaps undermine confidence | Specific items need re-verification |
| 3-4 | Weak -- systemic issues | Multiple verdicts questionable, consider partial retest |
| 0-2 | Reject -- results cannot be trusted | Re-run the wave |

## Scoring Rules

1. Score each dimension independently. A perfect score in one dimension does not compensate for a zero in another.
2. When in doubt between two scores, choose the lower one. It is better to flag a concern than to miss one.
3. Always cite specific evidence for each score. "Screenshots present" is not sufficient -- state "14/15 scenarios have screenshots; W10.5 is missing."
4. Missing artifacts automatically zero the relevant dimension (see Handling Missing Artifacts below).
5. The rubric is a living document. If a review reveals a gap in the rubric itself, note it in the Improvement Recommendations section.
6. If a referenced file path in "Check against" has moved, check `~/.claude/skills/qa/prompts/` for the current filename.

## Handling Missing Artifacts

When artifacts for a wave are missing, apply these automatic scores:

| Missing Artifact | Scoring Impact |
|---|---|
| No test plan (eval/checklist) exists | Eval Quality = 0. Note "No plan found -- wave used spot-check or ad-hoc approach" |
| No raw results exist | Execution Fidelity = 0 AND Evidence Completeness = 0. Note "No execution artifacts found" |
| No report exists | Review Accuracy = 0. Note "No reviewer report found" |
| Multiple test plans for one wave | Read all. Score Eval Quality based on combined coverage |
| Multiple raw result files (retests) | Review the most recent complete set. Note prior attempts in findings as context but score only final results |

Process Compliance is scored based on whatever artifacts DO exist -- if the roadmap was updated correctly for a wave with missing results, that dimension can still score > 0.
