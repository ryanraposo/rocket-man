<div align="center">
<pre>
     /\
    /  \
   /____\
  | o  o |
  |  __  |
   \____/
    /||\
   /_||_\
</pre>

# Rocketman

</div>

Meet **Rocket**, Rocketman's little guy. He blasts off to get the work moving, then plants his feet like a lunar lander when the mission is verified.

Rocketman turns a feature request into a researched, staged, verifiable implementation. GitHub Issues and pull requests are the durable project record; stage count and boundaries adapt to the work.

## What it does

- **Investigate:** inspect the actual repository, runtime, tools, branches, issues, PRs, dependencies, and project conventions.
- **Clarify:** ask only decision-changing questions; infer reversible, least-privilege defaults and record consequential assumptions.
- **Plan:** define the objective, invariants, dependencies, and observable completion conditions.
- **Stage:** choose the smallest coherent number of implementation stages. One stage may be enough; larger work gets as many as it needs.
- **Coordinate:** maintain a GitHub issue as the durable plan, with branch/base, completed and remaining stage checklists, and closeout comments.
- **Implement:** work on a feature branch and keep the PR and issue aligned as scope or progress changes.
- **Verify:** distinguish implementation, tests, experiments, mocks, and target-runtime behaviour. Never overstate what a check proves.
- **Close out:** record exact changes, verification, remaining assumptions, and next action. Keep the parent issue open while planned work remains.

## Installation

Rocketman is one skill with the same workflow in both supported environments: OpenCode and Claude Code. From a reviewed checkout, run:

```bash
bash install.sh --dry-run
bash install.sh
```

The installer targets `~/.config/opencode/skills/rocketman` and `~/.claude/skills/rocketman`.

## Development

See AGENTS.md for repository guidance and SKILL.md for the canonical workflow. The workflow contract and reference material live in contracts/ and references/.
