#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf '[ERROR] Invalid VERSION\n' >&2; exit 1; }
DIST="${1:-$ROOT/dist}"
PREFIX="rocketman-$VERSION"
EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$ROOT" log -1 --format=%ct)}"
mkdir -p "$DIST"
FILES="$(mktemp "${TMPDIR:-/tmp}/rocketman-files.XXXXXX")"
trap 'rm -f "$FILES"' EXIT
git -C "$ROOT" ls-files -z > "$FILES"
[[ -s "$FILES" ]] || { printf '[ERROR] No tracked release files\n' >&2; exit 1; }
while IFS= read -r -d '' path; do
  [[ -f "$ROOT/$path" && ! -L "$ROOT/$path" ]] || { printf '[ERROR] Unsupported release entry: %s\n' "$path" >&2; exit 1; }
done < "$FILES"
ARCHIVE="$DIST/$PREFIX.tar.gz"
tar --create --file=- --directory "$ROOT" --null --files-from "$FILES" \
  --sort=name --transform="s,^,$PREFIX/," --mtime="@$EPOCH" \
  --owner=0 --group=0 --numeric-owner --format=posix \
  --pax-option=delete=atime,delete=ctime | gzip -n > "$ARCHIVE"
(cd "$DIST" && sha256sum "$(basename "$ARCHIVE")" > SHA256SUMS)
printf '[OK] %s\n[OK] %s/SHA256SUMS\n' "$ARCHIVE" "$DIST"
