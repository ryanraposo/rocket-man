#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
python3 - "$ROOT" <<'PY'
import pathlib,sys
root=pathlib.Path(sys.argv[1])
opening=["     /\\","    /  \\","   /____\\","  | o  o |","  |  __  |","   \\____/","    /||\\","   /_||_\\"]
success=["    .-----.","   /| ^ ^ |\\","  /_| \\_/ |_\\","     |___|","   __|   |__","  /___| |___\\"]
for name,art in [("Rocket opening",opening),("Rocket success",success)]:
    assert all(line.isascii() and len(line)<=36 and all(32<=ord(ch)<=126 for ch in line) for line in art), name
readme=(root/"README.md").read_text()
page=(root/"index.html").read_text()
bootstrap=(root/"install.sh").read_text()
engine=(root/"scripts/install-skill.sh").read_text()
agents=(root/"AGENTS.md").read_text()
runtime_files=[(root/"runtimes/opencode.yaml").read_text(),(root/"runtimes/claude-code.yaml").read_text()]
assert "\\n".join(line.ljust(max(map(len,opening))) for line in opening) in readme, "centered README art must be cell-aligned"
assert "\\n".join(opening) in page, "Pages opening pose missing"
assert bootstrap.count("\\n".join(opening))==1, "bootstrap must print one opening pose"
assert "\\n".join(opening) not in engine, "transaction engine must not print a second opening pose"
assert "\\n".join(success) in engine, "verified success lander missing from transaction engine"
assert "Meet **Rocket**" in readme and "Luna" not in readme
assert "Runtime characters" not in readme and "mascots" not in page
assert "one named mascot, Rocket" in agents
assert all("name: Rocket" in item for item in runtime_files)
assert all(all(line in item for line in opening) and all(line in item for line in success) for item in runtime_files)
assert "github.io/rocket-man/install.sh" in readme and "github.io/rocket-man/install.sh" in page
print("Rocket identity, aligned opening art, remote install docs, and lunar-lander success pose verified.")
PY
bash -n "$ROOT/install.sh" "$ROOT/scripts/install-skill.sh" "$ROOT/scripts/package-release.sh" "$ROOT/tests/run.sh"
mkdir -p "$tmp/dry-home"
HOME="$tmp/dry-home" OPENCODE_HOME="$tmp/dry-home/.config/opencode" CLAUDE_HOME="$tmp/dry-home/.claude" ROCKETMAN_STATE_HOME="$tmp/dry-home/.local/state/rocketman" bash "$ROOT/install.sh" --dry-run > "$tmp/dry-run.txt"
grep -q "Dry run complete" "$tmp/dry-run.txt"
test ! -e "$tmp/dry-home/.config/opencode"
test ! -e "$tmp/dry-home/.claude"
test ! -e "$tmp/dry-home/.local/state/rocketman"
bash "$ROOT/scripts/package-release.sh" "$tmp/dist" > "$tmp/package.txt"
test -s "$tmp/dist/rocketman-0.1.0.tar.gz"
test -s "$tmp/dist/SHA256SUMS"
(cd "$tmp/dist" && sha256sum -c SHA256SUMS >/dev/null)
python3 - "$tmp/dist/rocketman-0.1.0.tar.gz" <<'PY'
import sys,tarfile
with tarfile.open(sys.argv[1],"r:gz") as tf:
    names=tf.getnames()
    assert names and all(n.startswith("rocketman-0.1.0/") for n in names)
    assert "rocketman-0.1.0/SKILL.md" in names
    assert "rocketman-0.1.0/scripts/install-skill.sh" in names
    assert "rocketman-0.1.0/install.sh" in names
print("Versioned release archive structure verified.")
PY
mkdir -p "$tmp/home"
HOME="$tmp/home" OPENCODE_HOME="$tmp/home/.config/opencode" CLAUDE_HOME="$tmp/home/.claude" ROCKETMAN_STATE_HOME="$tmp/home/.local/state/rocketman" bash "$ROOT/install.sh" > "$tmp/install.txt"
test -f "$tmp/home/.config/opencode/skills/rocketman/SKILL.md"
test -f "$tmp/home/.config/opencode/skills/rocketman/references/rocketman-core.md"
grep -q "Read references/rocketman-core.md" "$tmp/home/.config/opencode/skills/rocketman/SKILL.md"
test -f "$tmp/home/.claude/skills/rocketman/SKILL.md"
test -f "$tmp/home/.claude/skills/rocketman/references/rocketman-core.md"
grep -q "Read references/rocketman-core.md" "$tmp/home/.claude/skills/rocketman/SKILL.md"
(cd "$tmp/home/.config/opencode/skills/rocketman" && sha256sum -c MANIFEST.sha256 >/dev/null)
(cd "$tmp/home/.claude/skills/rocketman" && sha256sum -c MANIFEST.sha256 >/dev/null)
grep -q "Next: Start a fresh OpenCode or Claude Code session" "$tmp/install.txt"
grep -q "^    .-----." "$tmp/install.txt"
test -s "$tmp/home/.local/state/rocketman/transactions/"*/receipt
mkdir -p "$tmp/recovery-home/.config/opencode/skills/rocketman" "$tmp/recovery-home/.claude/skills/rocketman"
printf 'opencode-original\\n' > "$tmp/recovery-home/.config/opencode/skills/rocketman/original.txt"
printf 'claude-original\\n' > "$tmp/recovery-home/.claude/skills/rocketman/original.txt"
if HOME="$tmp/recovery-home" OPENCODE_HOME="$tmp/recovery-home/.config/opencode" CLAUDE_HOME="$tmp/recovery-home/.claude" ROCKETMAN_STATE_HOME="$tmp/recovery-home/.local/state/rocketman" ROCKETMAN_TEST_FAIL_AFTER=claude-code bash "$ROOT/install.sh" > "$tmp/rollback.txt" 2>&1; then
  echo "Expected injected failure did not occur" >&2
  exit 1
fi
grep -q "opencode-original" "$tmp/recovery-home/.config/opencode/skills/rocketman/original.txt"
grep -q "claude-original" "$tmp/recovery-home/.claude/skills/rocketman/original.txt"
grep -q "Rollback: restoring" "$tmp/rollback.txt"
test ! -d "$tmp/recovery-home/.local/state/rocketman/transaction.lock"
echo "Installer dry-run, release packaging, dual-runtime install, and reverse-rollback tests passed."
