#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION=$(tr -d '\r\n' < VERSION)
NAME="rcc-${VERSION}"
OUT=${1:-dist}
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(date +%s)}

mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
STAGE="$OUT/$NAME"

rm -rf "$STAGE" "$OUT/$NAME.tar.gz" "$OUT/$NAME.zip" \
  "$OUT/$NAME.SHA256SUMS"
mkdir -p "$STAGE"

ROOT_FILES=(
  .gitignore LICENSE Makefile README.md VERSION
  RELEASE_HARDENING.md "RELEASE_NOTES_${VERSION}.md" "VERIFICATION_${VERSION}.md"
  "COMPATIBILITY_${VERSION}.md"
)
ROOT_DIRECTORIES=(
  .github bench completions examples include man scripts src tests
)

copy_file() {
  local source=$1
  [[ -f "$source" ]] || {
    printf 'error: release input is missing: %s\n' "$source" >&2
    exit 1
  }
  mkdir -p "$STAGE/$(dirname "$source")"
  cp -a "$source" "$STAGE/$source"
}

release_files() {
  local directory=$1
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard -z -- "$directory"
  else
    find "./$directory" -type f -print0
  fi
}

for path in "${ROOT_FILES[@]}"; do
  copy_file "$path"
done

for directory in "${ROOT_DIRECTORIES[@]}"; do
  [[ -d "$directory" ]] || {
    printf 'error: release directory is missing: %s\n' "$directory" >&2
    exit 1
  }
  while IFS= read -r -d '' path; do
    rel=${path#./}
    case "$rel" in
      build/*|dist/*|tests/tmp/*|*/__pycache__/*|*.pyc|MANIFEST.sha256) continue ;;
    esac
    { [[ -f "$rel" ]] || [[ -L "$rel" ]]; } || continue
    copy_file "$rel"
  done < <(release_files "$directory")
done

(
  cd "$STAGE"
  find . -type f ! -name MANIFEST.sha256 -print0 \
    | sort -z \
    | xargs -0 sha256sum > MANIFEST.sha256
  sha256sum -c MANIFEST.sha256 >/dev/null
)


find "$STAGE" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
tar --sort=name --mtime="@$SOURCE_DATE_EPOCH" --owner=0 --group=0 \
  --numeric-owner -C "$OUT" -czf "$OUT/$NAME.tar.gz" "$NAME"
(
  cd "$OUT"
  find "$NAME" \( -type f -o -type d \) | LC_ALL=C sort \
    | zip -X -q "$NAME.zip" -@
  sha256sum "$NAME.tar.gz" "$NAME.zip" > "$NAME.SHA256SUMS"
)

printf 'created %s\ncreated %s\ncreated %s\n' \
  "$OUT/$NAME.tar.gz" "$OUT/$NAME.zip" "$OUT/$NAME.SHA256SUMS"
