#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
python3 - "$ROOT" <<'PY'
import pathlib,sys
root=pathlib.Path(sys.argv[1])
for p in [root/'README.md',root/'index.html',root/'install.sh']:
    assert p.is_file(), f"missing {p}"
for name,opening,success in [
 ('opencode','     /\\\n    /  \\\n   /____\\\n     ||\n    /||\\\n   /_||_\\','     /\\\n    /  \\\n   /____\\\n    \\ || /\n     \\||/\n      \\/'),
 ('claude','    .---.\n   /|   |\\\n  /_|___|_\\\n     | |\n   __| |__\n  /_______\\','    .---.\n   /| ^ |\\\n  /_|___|_\\\n     | |\n   __| |__\n  /_______\\')]:
    assert len(opening.splitlines()) <= 7
    assert all(len(line)<=36 and line.isascii() and all(32<=ord(c)<=126 for c in line) for line in opening.splitlines())
    assert all(len(line)<=36 and line.isascii() and all(32<=ord(c)<=126 for c in line) for line in success.splitlines())
    for surface in ['README.md','index.html','install.sh']:
        text=(root/surface).read_text()
        # Opening art must be present on every required surface.
        if surface=='README.md':
            assert all(line in text for line in opening.splitlines()), (name,surface)
        elif surface=='index.html':
            assert all(line in text for line in opening.splitlines()), (name,surface)
        else:
            assert all(line in text for line in opening.splitlines()), (name,surface)
print('Mascot source and width checks passed.')
PY
bash "$ROOT/install.sh" --dry-run > "$tmp/dry-run.txt"
grep -q "Dry run complete" "$tmp/dry-run.txt"
mkdir -p "$tmp/home"
HOME="$tmp/home" OPENCODE_HOME="$tmp/home/.config/opencode" CLAUDE_HOME="$tmp/home/.claude" ROCKETMAN_STATE_HOME="$tmp/home/.local/state/rocketman" bash "$ROOT/install.sh" > "$tmp/install.txt"
test -f "$tmp/home/.config/opencode/skills/rocketman/SKILL.md"
test -f "$tmp/home/.claude/skills/rocketman/SKILL.md"
grep -q "Next: Start a fresh OpenCode or Claude Code session" "$tmp/install.txt"
echo "Installer dry-run and dual-runtime installation tests passed."
