#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
python3 - "$ROOT" <<'PY'
import pathlib,sys
root=pathlib.Path(sys.argv[1])
rocket=["     /\\","    /  \\","   /____\\","  | o  o |","  |  __  |","   \\____/","    /||\\","   /_||_\\"]
rocket_success=["     /\\","    /  \\","   /____\\","  | ^  ^ |","  |  \\_/ |","   \\____/","    /||\\","   /_||_\\"]
luna=["   .-----.","  /| o o |\\"," /_|  ^  |_\\","    |   |","  __|   |__"," /_________\\"]
luna_success=["   .-----.","  /| ^ ^ |\\"," /_|  \\_/ |_\\","    |   |","  __|   |__"," /_________\\"]
for name,art in [("Rocket",rocket),("Rocket success",rocket_success),("Luna",luna),("Luna success",luna_success)]:
    assert all(line.isascii() and len(line)<=36 and all(32<=ord(ch)<=126 for ch in line) for line in art), name
readme=(root/"README.md").read_text()
page=(root/"index.html").read_text()
installer=(root/"install.sh").read_text()
for name,art in [("Rocket",rocket),("Luna",luna)]:
    for surface,source in [("README",readme),("Pages",page),("installer",installer)]:
        assert "\n".join(art) in source, f"{name} opening pose missing from {surface}"
assert "\n".join(rocket_success) in installer
assert "\n".join(luna_success) in installer
assert "name: rocketman" in (root/".opencode/skills/rocketman/SKILL.md").read_text()
assert "name: rocketman" in (root/".claude/skills/rocketman/SKILL.md").read_text()
print("Runtime entrypoints and four mascot poses verified.")
PY
bash -n "$ROOT/install.sh"
bash "$ROOT/install.sh" --dry-run > "$tmp/dry-run.txt"
grep -q "Dry run complete" "$tmp/dry-run.txt"
mkdir -p "$tmp/home"
HOME="$tmp/home" OPENCODE_HOME="$tmp/home/.config/opencode" CLAUDE_HOME="$tmp/home/.claude" ROCKETMAN_STATE_HOME="$tmp/home/.local/state/rocketman" bash "$ROOT/install.sh" > "$tmp/install.txt"
test -f "$tmp/home/.config/opencode/skills/rocketman/SKILL.md"
test -f "$tmp/home/.claude/skills/rocketman/SKILL.md"
(cd "$tmp/home/.config/opencode/skills/rocketman" && sha256sum -c MANIFEST.sha256 >/dev/null)
(cd "$tmp/home/.claude/skills/rocketman" && sha256sum -c MANIFEST.sha256 >/dev/null)
grep -q "Next: Start a fresh OpenCode or Claude Code session" "$tmp/install.txt"
echo "Installer dry-run and dual-runtime installation tests passed."
