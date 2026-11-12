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
</div>

# Rocketman

</div>

Meet **Rocket**. He blasts off to get moving, then plants his feet like a lunar lander when the mission is a-go.

**Rocket** turns a feature request into a researched, staged, verifiable implementation. GitHub Issues and pull requests are his tools; synced stages are deployed in his wake; and his approach adapts to the work.

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

Rocketman installs one canonical workflow into OpenCode, Claude Code, or both. The public bootstrap downloads a versioned release, verifies its exact SHA-256, validates the archive, then hands off to the transactional installer.

**From a reviewed checkout:**

```bash
bash install.sh --dry-run
bash install.sh
```

**Remote install — once this repository is public, Pages is enabled, and a matching release is published:**

Review-first:

```bash
curl -fsSLo install.sh --proto '=https' --tlsv1.2 https://ryanraposo.github.io/rocket-man/install.sh
less install.sh
bash install.sh --dry-run
bash install.sh
```

Short form:

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://ryanraposo.github.io/rocket-man/install.sh | bash
```

Version-pinned:

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://ryanraposo.github.io/rocket-man/install.sh |
  ROCKETMAN_VERSION=0.1.0 bash
```

A same-origin checksum detects corruption and mismatches; it is not an independent root of trust. Add `--require-attestation` when the release has GitHub build provenance and the GitHub CLI is available.

The installer targets `~/.config/opencode/skills/rocketman` and `~/.claude/skills/rocketman`. Existing destinations are preserved as sibling backups. A failed multi-runtime commit rolls back in reverse order. Receipts live under `~/.local/state/rocketman/transactions/`.

See [the installer contract](references/installer-contract.md) for the release format, trust boundary, options, and recovery behaviour.

```bash
bash install.sh --dry-run
bash install.sh
```

See AGENTS.md for repository guidance and SKILL.md for the canonical workflow. The workflow contract and reference material live in contracts/ and references/.
