# GitHub implementation workflow

## Parent Issue

Create or update one issue per coherent feature. Avoid issue proliferation. The issue is the durable plan and must survive individual implementation PRs.

Use Objective, Invariants, Implementation status, Completed, and Remaining sections. Record the actual target branch and feature branch. Link the implementation PR. Make stage boundaries meaningful and adaptive.

## Stage lifecycle

1. Define a stage's outcome and observable completion conditions.
2. Implement it on the feature branch.
3. Run stage-specific checks.
4. Update the issue checklist.
5. Add a closeout comment describing implementation, verification, limitations, and linked commits/PR.
6. Update the PR body or comments so the same progress is visible there.
7. Leave the stage open if any required condition is unverified.

A merged PR does not imply the parent issue is complete when later stages remain.

## Honest reporting

Distinguish code-level contract tests from real runtime execution, synthetic fixtures from real inputs, and model interfaces from actual model inference. State the target hardware/platform when relevant. Record exact test counts only when the command output confirms them.

## Issue closeout template

```markdown
## Stage N — Concrete stage name

**Status: Implemented**

- **Branch:** feature branch and base branch.
- **Implementation:** concise concrete changes.
- **Verification:** exact checks and results.
- **Boundary:** what this evidence does not establish, if relevant.

**Merged:** PR link and commit links, when applicable.
```
