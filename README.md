# Rocketman

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

**Meet Rocket**, the OpenCode little guy. He carries the shared /rocketman workflow into OpenCode.

For Claude Code, meet **Luna**, the lunar-lander little guy: the same mission discipline, a different ride.

Rocketman turns a feature request into a researched, staged, verifiable implementation. GitHub Issues and pull requests are the durable project record; stage count and boundaries adapt to the work.

## Runtime characters

### OpenCode — Rocket

Opening pose:

```text
     /\
    /  \
   /____\
  | o  o |
  |  __  |
   \____/
    /||\
   /_||_\
```

Verified-success pose:

```text
     /\
    /  \
   /____\
  | ^  ^ |
  |  \_/ |
   \____/
    /||\
   /_||_\
```

### Claude Code — Luna

Opening pose:

```text
   .-----.
  /| o o |\
 /_|  ^  |_\
    |   |
  __|   |__
 /_________\
```

Verified-success pose:

```text
   .-----.
  /| ^ ^ |\
 /_|  \_/ |_\
    |   |
  __|   |__
 /_________\
```

All hero grids are printable 7-bit ASCII, graphic-only, and kept within 36 columns. Names live in surrounding copy, never inside the artwork.

## What it does

- **Investigate:** inspect the actual repository, runtime, tools, branches, issues, PRs, dependencies, and project conventions.
- **Clarify:** ask only decision-changing questions; infer reversible, least-privilege defaults and record consequential assumptions.
- **Plan:** define the objective, invariants, dependencies, and observable completion conditions.
- **Stage:** choose the smallest coherent number of implementation stages. One stage may be enough; larger work gets as many as it needs.
- **Coordinate:** maintain a GitHub issue as the durable plan, with branch/base, completed and remaining stage checklists, and closeout comments.
- **Implement:** work on a feature branch and keep the PR and issue aligned as scope or progress changes.
- **Verify:** distinguish implementation, tests, experiments, mocks, and target-runtime behaviour. Never overstate what a check proves.
- **Close out:** record exact changes, evidence, remaining assumptions, and next action. Keep the parent issue open while planned work remains.

## Installation

Runtime adapters and shared skill instructions are in this repository. From a reviewed checkout, run `bash install.sh --dry-run` and then `bash install.sh`. The installer targets `~/.config/opencode/skills/rocketman` and `~/.claude/skills/rocketman`.

## Development

See AGENTS.md for repository guidance and SKILL.md for the canonical workflow. The workflow contract and reference material live in contracts/ and references/.

## Provenance

The staged GitHub workflow is grounded in [GODMASK issue #85](https://github.com/ryanraposo/GODMASK/issues/85): a baseline and architecture stage, adaptive implementation stages, per-stage issue closeouts, linked PR commits, explicit remaining work, and honest boundaries around synthetic validation versus real runtime execution.
