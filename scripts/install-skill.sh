#!/usr/bin/env bash
set -eEuo pipefail

NAME=rocketman
SOURCE=""
MODE=both
DRY_RUN=false
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.config/opencode}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
STATE_HOME="${ROCKETMAN_STATE_HOME:-$HOME/.local/state/rocketman}"
TARGETS=() LABELS=() STAGES=() BACKUPS=() ATTEMPTED=()
ACTIVE=false

info(){ printf '\033[34m[INFO]\033[0m %s\n' "$*"; }
ok(){ printf '\033[32m[OK]\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m[WARN]\033[0m %s\n' "$*" >&2; }
die(){ printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    --opencode-only) [[ "$MODE" == both ]] || die "choose one runtime scope"; MODE=opencode; shift ;;
    --claude-only) [[ "$MODE" == both ]] || die "choose one runtime scope"; MODE=claude; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) die "unknown engine option: $1" ;;
  esac
done

[[ -n "$SOURCE" && -d "$SOURCE" ]] || die "--source must name the verified Rocketman payload"
[[ "${EUID:-$(id -u)}" -ne 0 ]] || die "run as the logged-in user, not root"
grep -q '^name: rocketman$' "$SOURCE/SKILL.md" || die "source skill identity is invalid"
VERSION="$(tr -d '[:space:]' < "$SOURCE/VERSION")"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "source version is invalid"
for tool in awk cp date mkdir mv rm sha256sum; do command -v "$tool" >/dev/null 2>&1 || die "$tool is required"; done

case "$MODE" in both|opencode) LABELS+=(opencode); TARGETS+=("$OPENCODE_HOME/skills/rocketman") ;; esac
case "$MODE" in both|claude) LABELS+=(claude-code); TARGETS+=("$CLAUDE_HOME/skills/rocketman") ;; esac

info "Rocketman $VERSION install; selected mode: $MODE"
info "[install 1/4] Preflight and destination plan"
for i in "${!TARGETS[@]}"; do
  [[ "${TARGETS[$i]}" != "/" && "${TARGETS[$i]}" != "$HOME" ]] || die "unsafe target: ${TARGETS[$i]}"
  printf '  %-12s %s\n' "${LABELS[$i]}:" "${TARGETS[$i]}"
done
if $DRY_RUN; then
  printf '\nDry run complete. No skill homes, locks, transactions, backups, or persistent state were created or changed.\n'
  exit 0
fi

umask 077
mkdir -p "$STATE_HOME/transactions"
LOCK="$STATE_HOME/transaction.lock"
mkdir "$LOCK" 2>/dev/null || die "another installation is active or a lock remains at $LOCK; inspect it before recovery"
TX="$STATE_HOME/transactions/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir "$TX"
printf 'pid=%s\nstarted=%s\n' "$$" "$(date -u +%FT%TZ)" > "$LOCK/owner"

rollback(){
  local i target backup failed
  $ACTIVE || return 0
  warn "Rollback: restoring committed runtime targets in reverse order"
  for ((i=${#TARGETS[@]}-1;i>=0;i--)); do
    [[ "${ATTEMPTED[$i]:-0}" == 1 ]] || continue
    target="${TARGETS[$i]}"
    backup="${BACKUPS[$i]:-}"
    if [[ -e "$target" || -L "$target" ]]; then
      failed="$TX/failed-$i"
      mv "$target" "$failed" || { warn "could not move failed target aside: $target"; continue; }
      rm -rf -- "$failed"
    fi
    if [[ -n "$backup" && ( -e "$backup" || -L "$backup" ) ]]; then
      mv "$backup" "$target" || warn "manual recovery required: $backup -> $target"
    fi
  done
  ACTIVE=false
}
cleanup(){
  local stage
  for stage in "${STAGES[@]:-}"; do
    [[ -z "$stage" || ! -e "$stage" ]] || rm -rf -- "$stage"
  done
  if [[ -d "$LOCK" ]]; then rm -f "$LOCK/owner"; rmdir "$LOCK" 2>/dev/null || true; fi
}
on_exit(){
  local rc=$?
  [[ $rc -eq 0 ]] || rollback
  cleanup
  trap - EXIT
  exit "$rc"
}
trap on_exit EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

info "[install 2/4] Stage complete runtime payloads beside each destination"
for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  parent="$(dirname "$target")"
  mkdir -p "$parent"
  stage="$(mktemp -d "$parent/.rocketman-stage.XXXXXX")"
  STAGES+=("$stage")
  mkdir -p "$stage/contracts" "$stage/references"
  cp "$SOURCE/contracts/rocketman.json" "$stage/contracts/"
  cp "$SOURCE/references/"*.md "$stage/references/"
  cp "$SOURCE/SKILL.md" "$stage/references/rocketman-core.md"
  cp "$SOURCE/VERSION" "$stage/VERSION"
  if [[ "${LABELS[$i]}" == opencode ]]; then
    cp "$SOURCE/.opencode/skills/rocketman/SKILL.md" "$stage/SKILL.md"
  else
    cp "$SOURCE/.claude/skills/rocketman/SKILL.md" "$stage/SKILL.md"
  fi
  chmod 0644 "$stage/SKILL.md" "$stage/VERSION" "$stage/contracts/rocketman.json" "$stage/references/"*.md
  (cd "$stage" && find . -type f ! -name MANIFEST.sha256 -print0 | sort -z | xargs -0 sha256sum > MANIFEST.sha256)
  (cd "$stage" && sha256sum -c MANIFEST.sha256 >/dev/null) || die "staged payload verification failed for ${LABELS[$i]}"
  grep -q '^name: rocketman$' "$stage/SKILL.md" || die "runtime entrypoint identity failed for ${LABELS[$i]}"
done

info "[install 3/4] Commit and verify"
ACTIVE=true
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"
  parent="$(dirname "$target")"
  backup=""
  ATTEMPTED[$i]=1
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$parent/.rocketman-backup-$stamp-$$-$i"
    [[ ! -e "$backup" && ! -L "$backup" ]] || die "backup path already exists: $backup"
    BACKUPS[$i]="$backup"
    mv "$target" "$backup" || die "could not preserve existing target: $target"
  else
    BACKUPS[$i]=""
  fi
  mv "${STAGES[$i]}" "$target" || die "could not commit staged payload to $target"
  (cd "$target" && sha256sum -c MANIFEST.sha256 >/dev/null) || die "installed payload verification failed: $target"
  ok "${LABELS[$i]} installed and verified"
  if [[ "${ROCKETMAN_TEST_FAIL_AFTER:-}" == "${LABELS[$i]}" ]]; then die "injected failure after ${LABELS[$i]} commit"; fi
done

info "[install 4/4] Finalize receipt"
receipt="$TX/receipt"
{
  printf 'name=%s\nversion=%s\ninstalled=%s\nmode=%s\n' "$NAME" "$VERSION" "$(date -u +%FT%TZ)" "$MODE"
  for i in "${!TARGETS[@]}"; do
    printf 'target.%s=%s\n' "${LABELS[$i]}" "${TARGETS[$i]}"
    [[ -z "${BACKUPS[$i]:-}" ]] || printf 'backup.%s=%s\n' "${LABELS[$i]}" "${BACKUPS[$i]}"
    printf 'manifest.%s=%s\n' "${LABELS[$i]}" "$(sha256sum "${TARGETS[$i]}/MANIFEST.sha256" | awk '{print $1}')"
  done
} > "$receipt"
ACTIVE=false

printf '\nRocketman installed and independently verified.\n'
for i in "${!TARGETS[@]}"; do printf '  %-12s %s\n' "${LABELS[$i]}:" "${TARGETS[$i]}"; done
for i in "${!BACKUPS[@]}"; do
  backup="${BACKUPS[$i]:-}"
  [[ -z "$backup" ]] || printf '  Backup: %s\n' "$backup"
done
printf '  Receipt: %s\n' "$receipt"
printf '  Next: Start a fresh OpenCode or Claude Code session to discover /rocketman.\n\n'

cat <<'ROCKET_SUCCESS'
    .-----.
   /| ^ ^ |\
  /_| \_/ |_\
     |___|
   __|   |__
  /___| |___\
ROCKET_SUCCESS
