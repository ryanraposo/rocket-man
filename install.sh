#!/usr/bin/env bash
set -eEuo pipefail

NAME=rocketman
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=both
DRY_RUN=false
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.config/opencode}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
STATE_HOME="${ROCKETMAN_STATE_HOME:-$HOME/.local/state/rocketman}"
TARGETS=() LABELS=() BACKUPS=() COMMITTED=0 ACTIVE=false

info(){ printf '\033[34m[INFO]\033[0m %s\n' "$*"; }
ok(){ printf '\033[32m[OK]\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m[WARN]\033[0m %s\n' "$*" >&2; }
die(){ printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

cat <<'ROCKET'\n     /\
    /  \
   /____\
  | o  o |
  |  __  |
   \____/
    /||\
   /_||_\\nROCKET
printf '\n'
cat <<'LUNA'\n   .-----.
  /| o o |\
 /_|  ^  |_\
    |   |
  __|   |__
 /_________\\nLUNA
printf '\n'

while (($#)); do
  case "$1" in
    --opencode-only) [[ "$MODE" == both ]] || die "choose one runtime scope"; MODE=opencode; shift ;;
    --claude-only) [[ "$MODE" == both ]] || die "choose one runtime scope"; MODE=claude; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) printf 'Usage: ./install.sh [--opencode-only|--claude-only] [--dry-run]\n'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ "${EUID:-$(id -u)}" -ne 0 ]] || die "run as the logged-in user, not root"
command -v cp >/dev/null && command -v mv >/dev/null && command -v sha256sum >/dev/null || die "cp, mv, and sha256sum are required"
[[ -f "$ROOT/SKILL.md" && -f "$ROOT/contracts/rocketman.json" ]] || die "run this installer from a complete Rocketman checkout"

case "$MODE" in both|opencode) LABELS+=(opencode); TARGETS+=("$OPENCODE_HOME/skills/rocketman") ;; esac
case "$MODE" in both|claude) LABELS+=(claude-code); TARGETS+=("$CLAUDE_HOME/skills/rocketman") ;; esac

info "Rocketman install; selected mode: $MODE"
info "[install 1/4] Preflight and destination plan"
for i in "${!TARGETS[@]}"; do printf '  %-12s %s\n' "${LABELS[$i]}:" "${TARGETS[$i]}"; done
if $DRY_RUN; then
  printf '\nDry run complete. No skill homes, locks, transactions, backups, or persistent state were created or changed.\n'
  exit 0
fi

umask 077
mkdir -p "$STATE_HOME/transactions"
LOCK="$STATE_HOME/transaction.lock"
mkdir "$LOCK" 2>/dev/null || die "another installation is active or lock remains at $LOCK"
TX="$STATE_HOME/transactions/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir "$TX"
printf 'pid=%s\nstarted=%s\n' "$$" "$(date -u +%FT%TZ)" > "$LOCK/owner"

rollback(){
  local i target backup
  $ACTIVE || return 0
  warn "Rollback: restoring $COMMITTED committed runtime target(s)"
  for ((i=${#BACKUPS[@]}-1;i>=0;i--)); do
    target="${TARGETS[$i]}"; backup="${BACKUPS[$i]}"
    [[ ! -e "$target" ]] || mv "$target" "$TX/failed-$i" || true
    [[ -z "$backup" || ! -e "$backup" ]] || mv "$backup" "$target" || warn "manual recovery required: $backup -> $target"
  done
  ACTIVE=false
}
cleanup(){
  [[ ! -d "$LOCK" ]] || { rm -f "$LOCK/owner"; rmdir "$LOCK" 2>/dev/null || true; }
}
on_exit(){ rc=$?; [[ $rc -eq 0 ]] || rollback; cleanup; trap - EXIT; exit "$rc"; }
trap on_exit EXIT
trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 143' TERM

info "[install 2/4] Stage complete runtime payloads"
for i in "${!TARGETS[@]}"; do
  stage="$TX/stage-$i"; mkdir -p "$stage"
  if [[ "${LABELS[$i]}" == opencode ]]; then
     mkdir -p "$stage/contracts" "$stage/references"
    cp "$ROOT/contracts/rocketman.json" "$stage/contracts/"
    cp "$ROOT/references/"*.md "$stage/references/"
    cp "$ROOT/SKILL.md" "$stage/references/rocketman-core.md"
    cp "$ROOT/.opencode/skills/rocketman/SKILL.md" "$stage/SKILL.md"
  else
     mkdir -p "$stage/contracts" "$stage/references"
    cp "$ROOT/contracts/rocketman.json" "$stage/contracts/"
    cp "$ROOT/references/"*.md "$stage/references/"
    cp "$ROOT/SKILL.md" "$stage/references/rocketman-core.md"
    cp "$ROOT/.claude/skills/rocketman/SKILL.md" "$stage/SKILL.md"
  fi
  (cd "$stage" && sha256sum SKILL.md contracts/rocketman.json references/*.md > MANIFEST.sha256)
  (cd "$stage" && sha256sum -c MANIFEST.sha256 >/dev/null) || die "staged payload verification failed"
done

info "[install 3/4] Commit runtime payloads"
ACTIVE=true
for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"; parent="$(dirname "$target")"
  mkdir -p "$parent"
  backup=""
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$TX/backup-$i"
    mv "$target" "$backup"
  fi
  BACKUPS+=("$backup")
  mv "$TX/stage-$i" "$target"
  COMMITTED=$((COMMITTED+1))
  (cd "$target" && sha256sum -c MANIFEST.sha256 >/dev/null) || die "installed payload verification failed: $target"
  ok "${LABELS[$i]} installed and verified"
done

info "[install 4/4] Finalize receipt"
printf 'version=0.1.0\ninstalled=%s\nmode=%s\n' "$(date -u +%FT%TZ)" "$MODE" > "$TX/receipt"
ACTIVE=false
printf '\nRocketman installed and independently verified.\n'
for i in "${!TARGETS[@]}"; do printf '  %-12s %s\n' "${LABELS[$i]}:" "${TARGETS[$i]}"; done
for i in "${!BACKUPS[@]}"; do backup="${BACKUPS[$i]}"; [[ -z "$backup" ]] || printf '  Backup: %s\n' "$backup"; done
printf '  Receipt: %s\n' "$TX/receipt"
printf '  Next: Start a fresh OpenCode or Claude Code session to discover /rocketman.\n\n'

cat <<'ROCKET_SUCCESS'\n     /\
    /  \
   /____\
  | ^  ^ |
  |  \_/ |
   \____/
    /||\
   /_||_\\nROCKET_SUCCESS
cat <<'LUNA_SUCCESS'\n   .-----.
  /| ^ ^ |\
 /_|  \_/ |_\
    |   |
  __|   |__
 /_________\\nLUNA_SUCCESS
