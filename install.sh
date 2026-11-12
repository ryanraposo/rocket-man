#!/usr/bin/env bash
set -eEuo pipefail

ROCKETMAN_REPOSITORY="ryanraposo/rocket-man"
ROCKETMAN_DEFAULT_VERSION="0.1.0"
ROCKETMAN_RELEASE_ROOT="${ROCKETMAN_RELEASE_BASE_URL:-https://github.com/ryanraposo/rocket-man/releases/download}"
ROCKETMAN_REQUIRE_ATTESTATION=false
ROCKETMAN_VERIFY_ONLY=false
ROCKETMAN_TEMP=""
ROCKETMAN_LOCAL_SOURCE=""
ROCKETMAN_ENGINE_ARGS=()

info(){ printf '\033[34m[INFO]\033[0m %s\n' "$*"; }
ok(){ printf '\033[32m[OK]\033[0m %s\n' "$*"; }
die(){ printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }
usage(){
  cat <<'USAGE'
Usage: install.sh [options]

  --opencode-only       Install only the OpenCode skill
  --claude-only         Install only the Claude Code skill
  --dry-run             Verify and print the install plan without mutation
  --verify-only         Verify the checkout or downloaded release only
  --require-attestation Require GitHub build-provenance verification
  --version             Print the selected version
  --help                Show this help

Set ROCKETMAN_VERSION=X.Y.Z to pin a remote release.
USAGE
}

cat <<'ROCKET'
     /\
    /  \
   /____\
  | o  o |
  |  __  |
   \____/
    /||\
   /_||_\
ROCKET
printf '\n'

while (($#)); do
  case "$1" in
    --require-attestation) ROCKETMAN_REQUIRE_ATTESTATION=true; shift ;;
    --verify-only) ROCKETMAN_VERIFY_ONLY=true; shift ;;
    --opencode-only|--claude-only|--dry-run) ROCKETMAN_ENGINE_ARGS+=("$1"); shift ;;
    --version) printf '%s\n' "${ROCKETMAN_VERSION:-$ROCKETMAN_DEFAULT_VERSION}"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ "${EUID:-$(id -u)}" -ne 0 ]] || die "run as the logged-in user, not root"
umask 077

source_ref="${BASH_SOURCE[0]:-}"
if [[ -n "$source_ref" && -f "$source_ref" ]]; then
  candidate="$(cd "$(dirname "$source_ref")" && pwd)"
  if [[ -f "$candidate/SKILL.md" && -f "$candidate/scripts/install-skill.sh" ]]; then
    ROCKETMAN_LOCAL_SOURCE="$candidate"
  fi
fi

if [[ -n "$ROCKETMAN_LOCAL_SOURCE" ]]; then
  info "Using reviewed local checkout: $ROCKETMAN_LOCAL_SOURCE"
  if $ROCKETMAN_VERIFY_ONLY; then
    bash "$ROCKETMAN_LOCAL_SOURCE/tests/run.sh"
    ok "Local checkout passed its verification suite"
    exit 0
  fi
  exec bash "$ROCKETMAN_LOCAL_SOURCE/scripts/install-skill.sh" \
    --source "$ROCKETMAN_LOCAL_SOURCE" "${ROCKETMAN_ENGINE_ARGS[@]}"
fi

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
version="${ROCKETMAN_VERSION:-$ROCKETMAN_DEFAULT_VERSION}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "ROCKETMAN_VERSION must be X.Y.Z"
asset="rocketman-$version.tar.gz"
release="$ROCKETMAN_RELEASE_ROOT/v$version"
ROCKETMAN_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/rocketman.bootstrap.XXXXXX")"
cleanup(){
  case "$ROCKETMAN_TEMP" in "${TMPDIR:-/tmp}"/rocketman.bootstrap.*) rm -rf -- "$ROCKETMAN_TEMP" ;; esac
}
trap cleanup EXIT HUP INT TERM
fetch(){
  curl --disable --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --connect-timeout 10 --max-time 120 --retry 3 --retry-max-time 60 \
    --output "$2" "$1"
}

info "[bootstrap 1/4] Fetching versioned release $version"
fetch "$release/$asset" "$ROCKETMAN_TEMP/$asset" || die "release download failed"
fetch "$release/SHA256SUMS" "$ROCKETMAN_TEMP/SHA256SUMS" || die "checksum manifest download failed"

info "[bootstrap 2/4] Verifying exact artifact identity and SHA-256"
python3 - "$ROCKETMAN_TEMP/$asset" "$ROCKETMAN_TEMP/SHA256SUMS" "$asset" <<'PY'
import hashlib,re,sys
archive,manifest,wanted=sys.argv[1:]
lines=open(manifest,encoding="ascii").read().splitlines()
if len(lines)!=1:
    raise SystemExit("checksum manifest must contain exactly one artifact entry")
m=re.fullmatch(r"([0-9a-fA-F]{64})  ([A-Za-z0-9._-]+)",lines[0])
if not m or m.group(2)!=wanted:
    raise SystemExit("checksum manifest does not identify the exact expected artifact")
actual=hashlib.sha256(open(archive,"rb").read()).hexdigest()
if actual.lower()!=m.group(1).lower():
    raise SystemExit("SHA-256 mismatch for "+wanted)
print("SHA-256 verified: "+actual)
PY
ok "Artifact checksum verified"

if $ROCKETMAN_REQUIRE_ATTESTATION; then
  command -v gh >/dev/null 2>&1 || die "gh is required by --require-attestation"
  info "[bootstrap 3/4] Verifying GitHub build provenance"
  gh attestation verify "$ROCKETMAN_TEMP/$asset" -R "$ROCKETMAN_REPOSITORY" >/dev/null || die "artifact provenance verification failed"
  ok "GitHub build provenance verified"
else
  info "[bootstrap 3/4] Provenance verification is optional; use --require-attestation to enforce it"
fi

info "[bootstrap 4/4] Validating archive types, paths, and extracting safely"
python3 - "$ROCKETMAN_TEMP/$asset" "rocketman-$version" "$ROCKETMAN_TEMP/extract" <<'PY'
import os,stat,sys,tarfile
from pathlib import Path
archive,expected,destination=Path(sys.argv[1]),sys.argv[2],Path(sys.argv[3])
seen=set()
with tarfile.open(archive,"r:gz") as tf:
    members=tf.getmembers()
    if not members:
        raise SystemExit("release archive is empty")
    for member in members:
        raw=member.name
        if any(ord(c)<32 or ord(c)==127 for c in raw):
            raise SystemExit("archive member contains a control character")
        trimmed=raw[:-1] if member.isdir() and raw.endswith("/") else raw
        parts=trimmed.split("/")
        if not trimmed or raw.startswith("/") or any(p in ("",".","..") for p in parts) or parts[0]!=expected:
            raise SystemExit("unsafe or unexpected archive member: "+raw)
        normalized="/".join(parts)
        if normalized in seen:
            raise SystemExit("duplicate archive member: "+raw)
        seen.add(normalized)
        if not (member.isdir() or member.isfile()):
            raise SystemExit("links and special archive entries are not allowed: "+raw)
        if member.mode & 0o7000:
            raise SystemExit("dangerous permission bits in archive member: "+raw)
    destination.mkdir(mode=0o700)
    root=destination/expected
    root.mkdir(mode=0o700)
    for member in members:
        trimmed=member.name[:-1] if member.isdir() and member.name.endswith("/") else member.name
        parts=trimmed.split("/")
        target=destination.joinpath(*parts)
        if member.isdir():
            target.mkdir(parents=True,exist_ok=True)
            os.chmod(target,0o755)
            continue
        target.parent.mkdir(parents=True,exist_ok=True)
        flags=os.O_WRONLY|os.O_CREAT|os.O_EXCL
        if hasattr(os,"O_NOFOLLOW"):
            flags|=os.O_NOFOLLOW
        fd=os.open(target,flags,0o600)
        try:
            source=tf.extractfile(member)
            if source is None:
                raise SystemExit("could not read archive member: "+member.name)
            with source,os.fdopen(fd,"wb") as output:
                fd=-1
                while True:
                    chunk=source.read(1024*1024)
                    if not chunk: break
                    output.write(chunk)
        finally:
            if fd>=0: os.close(fd)
        os.chmod(target,0o755 if member.mode & 0o111 else 0o644)
PY
root="$ROCKETMAN_TEMP/extract/rocketman-$version"
[[ -f "$root/SKILL.md" && -f "$root/scripts/install-skill.sh" && -f "$root/VERSION" ]] || die "verified archive is missing required Rocketman files"
grep -q '^name: rocketman$' "$root/SKILL.md" || die "release archive has the wrong skill identity"
[[ "$(tr -d '[:space:]' < "$root/VERSION")" == "$version" ]] || die "release version does not match its archive identity"

if $ROCKETMAN_VERIFY_ONLY; then
  ok "Release $version verified; no installation changes made"
  exit 0
fi

bash "$root/scripts/install-skill.sh" --source "$root" "${ROCKETMAN_ENGINE_ARGS[@]}"
