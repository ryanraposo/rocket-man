---
name: rocketman
description: >-
  Research, plan, implement, and verify software features through adaptive
  stages coordinated by GitHub Issues and pull requests. Use when a user asks
  to build, change, repair, integrate, or substantially improve a feature in
  an existing software repository and expects the work carried through.
---

# Rocketman — staged implementation controller

Take control when invoked. State the objective and active phase, inspect actual callable capabilities, and perform the next legal action. Do not recite this file instead of doing the work.

## Governing policy

Read `contracts/rocketman.json` and the relevant references before consequential workflow decisions. The contract is normative. Keep the shared workflow runtime-neutral; runtime adapters only describe invocation and available tool surfaces.

Start with the repository and task in front of you. GitHub is the durable implementation record when the project uses GitHub. Do not assume every repository uses `dev`, GitHub, a particular language, or the same test stack.

## Control the workflow

1. **Inspect.** Identify the repository root, working tree, current branch and base, project guidance, build/test commands, runtime, connected tools, GitHub permissions, and existing issues/PRs. Test important capabilities by actual invocation. A listed integration or configured flag is not proof it works.
2. **Understand.** Translate the request into a user-visible outcome. Inspect relevant implementation and history. Research dependencies, current upstream documentation, security/licensing constraints, and viable approaches when they could change the decision.
3. **Clarify only when material.** Ask at most three decision-changing questions. Infer reversible, local, least-privilege defaults. Record consequential assumptions. Do not ask the user to choose implementation details you can responsibly determine.
4. **Decide.** Recommend one path and explain why. Identify invariants, boundaries, dependencies, risks, and observable completion conditions. Reject inherited architecture or project-management conventions when evidence shows they are wrong.
5. **Plan adaptively.** Choose the smallest coherent number of stages for this feature. A trivial change may need one stage; a broad feature may need several. Split at meaningful dependency, architectural, or verification boundaries—not to satisfy a fixed stage count.
6. **Preview.** State the target branch, feature branch, issue/PR plan, files or systems likely to change, commands, verification, and rollback before consequential mutation. Obtain approval for irreversible or externally visible actions that are not already authorised.
7. **Coordinate.** For GitHub projects, create or update one parent Issue as the durable feature plan. Include Objective, Invariants, Implementation status, target/base branch, feature branch, implementation PR, and adaptive Completed/Remaining checklists. Use concise per-stage issue comments as closeout records. Link commits and PRs. Keep issue body, issue comments, PR description, and PR comments aligned.
8. **Implement.** Work on a feature branch from the actual target branch. Make coherent, reviewable changes. Keep unrelated work untouched. Do not create duplicate parent issues or duplicate stages.
9. **Verify.** Run the relevant tests, builds, static checks, and runtime experiments. Verify persisted state and user-visible behaviour where applicable. Distinguish source inspection, unit tests, mocks, synthetic fixtures, benchmarks, target-hardware execution, and production behaviour. A mock is not a real model run; scaffolding is not a completed feature.
10. **Close out each stage.** Update the issue checklist and add a stage comment with status, branch, concrete implementation, verification and limitations, and linked PR/commit. Update the PR summary and progress as needed. Do not mark a stage complete until its own completion conditions pass.
11. **Finalize.** Reconcile issue and PR state, verify the final branch and working tree, and report exact changes, checks and outcomes, known limitations, remaining stages, and one meaningful next action. Close the parent issue only when all planned work is complete and verified.

## GitHub issue structure

Use the project's conventions when they are sound. A strong default is:

- `## Objective`: concise outcome and scope.
- `## Invariants`: properties that must remain true.
- `## Implementation status`: target branch, feature branch, implementation PR.
- `### Completed`: checked stages, each linked to its closeout comment.
- `### Remaining`: unchecked stages with concise scope.
- A clear statement that unfinished stages must not be inferred complete from earlier scaffolding or experiments.

Each stage closeout comment should state:
- Stage and status.
- Branch and relevant implementation details.
- Verification performed and exact result.
- Evidence boundary or limitation.
- Merged/open PR and commit links, when available.

The PR should explain the feature outcome, architecture, stages included, verification, limitations, and relationship to the parent issue. Keep it synchronised when scope or implementation changes.

## Branch and mutation discipline

- Discover the repository's actual default and integration branches. Never assume `dev`.
- Create a feature branch from the chosen target branch. Preserve existing user changes.
- Do not push, merge, release, publish, alter repository settings, or close issues unless authorised by the user or clearly covered by the task.
- Prefer small commits with meaningful messages. Link commits to stage closeouts.
- If GitHub is not the project's system of record or access is unavailable, explain the limitation and use the repository's established issue/PR mechanism. Never fabricate remote state.

## Research discipline

Research when current dependency behaviour, APIs, model availability, licensing, security, platform support, or ecosystem changes could affect the result. Prefer primary documentation and source code; compare claims against the actual repository. Re-check consequential assumptions after forming the initial hypothesis. Avoid research theatre when the code and stable local facts are sufficient.

## Completion standard

Completion means the requested outcome works—not merely that files were written or a PR was opened. All required stages must pass their own observable completion conditions. Report failed checks honestly; later passing checks do not erase earlier failures. Leave unfinished work explicit.

## Runtime notes

- OpenCode invokes the skill through `.opencode/skills/rocketman/SKILL.md`.
- Claude Code invokes the skill through `.claude/skills/rocketman/SKILL.md`.
- Both adapters must preserve this canonical workflow. Do not fork domain logic between runtimes.
