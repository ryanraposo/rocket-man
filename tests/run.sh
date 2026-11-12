#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
python3 - "$ROOT" <<'PY'
import pathlib,sys,re
root=pathlib.Path(sys.argv[1])
opening=["     /\\","    /  \\","   /____\\","  | o  o |","  |  __  |","   \\____/","    /||\\","   /_||_\\"]
success=["    .-----.","   /| ^ ^ |\\","  /_| \\_/ |_\\","     |___|","   __|   |__","  /___| |___\\"]
for name,art in [("Rocket opening",opening),("Rocket success",success)]:
    assert all(line.isascii() and len(line)<=36 and all(32<=ord(ch)<=126 for ch in line) for line in art), name
readme=(root/"README.md").read_text()
page=(root/"index.html").read_text()
installer=(root/"install.sh").read_text()
agents=(root/"AGENTS.md").read_text()
runtime_files=[(root/"runtimes/opencode.yaml").read_text(),(root/"runtimes/claude-code.yaml").read_text()]
assert "\n".join(line.ljust(max(map(len,opening))) for line in opening) in readme, "centered README art must be cell-aligned"
assert "\n".join(opening) in page, "Pages opening pose missing"
assert installer.count("\n".join(opening))==1, "installer must print one opening pose"
assert "\n".join(success) in installer, "verified success lander missing"
assert "Meet **Rocket**" in readme and "Luna" not in readme
assert "Runtime characters" not in readme and "mascots" not in page
assert "one named mascot, Rocket" in agents
assert all("name: Rocket" in item for item in runtime_files)
assert all("\n".join(opening) in item and "\n".join(success) in item for item in runtime_files)
print("One Rocket identity, aligned opening art, and lunar-lander success pose verified.")
PY
bash -n "$ROOT/install.sh"
bash "$ROOT/install.sh" --dry-run > "$tmp/dry-run.txt"
grep -q "Dry run complete" "$tmp/dry-run.txt"
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
echo "Installer dry-run, dual-runtime install, and reverse-rollback tests passed."
