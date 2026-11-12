# Rocketman installer contract

## Delivery model

Rocketman uses the `curl-bash` two-stage pattern:

1. The small public `install.sh` bootstrap prints Rocket's opening pose once.
2. It downloads a versioned `rocketman-X.Y.Z.tar.gz` release and `SHA256SUMS` to a private temporary directory.
3. It checks the exact artifact name and SHA-256 before use.
4. It optionally verifies GitHub build provenance with `--require-attestation`.
5. It validates every archive member and extracts only regular files and directories without following links.
6. It hands the verified source tree to `scripts/install-skill.sh`.
7. The engine preflights, plans, stages beside each destination, commits, verifies installed manifests, and writes a receipt. A failed multi-runtime commit rolls back in reverse order.

The bootstrap never writes to skill homes. The transaction engine never downloads executable code during commit.

## Trust

HTTPS authenticates the bootstrap origin at the time of download. A SHA-256 file hosted beside the release detects corruption and mismatched assets; it is not an independent root of trust. Review the bootstrap before piping it to Bash. Use `--require-attestation` when the release has GitHub provenance and the local `gh` CLI supports verification.

## Commands

From a reviewed checkout:

```bash
bash install.sh --dry-run
bash install.sh
```

After the repository is public, GitHub Pages is enabled, and a versioned release with the archive and checksum manifest exists:

```bash
# Review-first
curl -fsSLo install.sh --proto '=https' --tlsv1.2 https://ryanraposo.github.io/rocket-man/install.sh
less install.sh
bash install.sh --dry-run
bash install.sh

# Short form
curl -fsSL --proto '=https' --tlsv1.2 https://ryanraposo.github.io/rocket-man/install.sh | bash

# Version-pinned
curl -fsSL --proto '=https' --tlsv1.2 https://ryanraposo.github.io/rocket-man/install.sh |
  ROCKETMAN_VERSION=0.1.0 bash
```

The short form is not available while the repository is private or Pages and a matching release are unpublished.

## Options

- `--opencode-only` / `--claude-only`: select one runtime.
- `--dry-run`: verify and print the plan without creating skill homes, locks, backups, or persistent state.
- `--verify-only`: verify the checkout or downloaded release without installing.
- `--require-attestation`: require GitHub artifact provenance verification.
- `ROCKETMAN_VERSION=X.Y.Z`: pin the remote release.

## Destinations and recovery

- OpenCode: `~/.config/opencode/skills/rocketman`
- Claude Code: `~/.claude/skills/rocketman`
- State and receipts: `~/.local/state/rocketman/transactions/`

Existing destinations are moved to unique sibling backup directories before replacement. They remain in place after success. If a later runtime fails, newly committed targets are removed and previous targets are restored in reverse order. The receipt records installed destinations, backup paths, and manifest identities.

The transaction engine prints the exact `Next:` instruction before Rocket's related lunar-lander success pose. Dry-run, verify-only, failure, and rollback never print the success pose.
