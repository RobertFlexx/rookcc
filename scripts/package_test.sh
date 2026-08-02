#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
TMP=$(mktemp -d "${TMPDIR:-/tmp}/rcc-package.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
A="$TMP/a"; B="$TMP/b"; EPOCH=1704067200
SOURCE_DATE_EPOCH=$EPOCH ./scripts/package.sh "$A" >/dev/null
SOURCE_DATE_EPOCH=$EPOCH ./scripts/package.sh "$B" >/dev/null
VERSION=$(tr -d '\r\n' < VERSION); NAME="rcc-$VERSION"

for suffix in tar.gz zip SHA256SUMS; do
  cmp "$A/$NAME.$suffix" "$B/$NAME.$suffix" >/dev/null || { printf 'FAIL package-check: %s is not reproducible\n' "$suffix" >&2; exit 1; }
done
mkdir "$TMP/tar" "$TMP/zip"
tar -xzf "$A/$NAME.tar.gz" -C "$TMP/tar"
unzip -q "$A/$NAME.zip" -d "$TMP/zip"
diff -qr "$TMP/tar/$NAME" "$TMP/zip/$NAME" >/dev/null || { printf 'FAIL package-check: archive trees differ\n' >&2; exit 1; }
(cd "$TMP/tar/$NAME" && sha256sum -c MANIFEST.sha256 >/dev/null)
[[ $(find "$TMP/tar/$NAME" -type f -name '*.md' | wc -l) -eq 1 ]] || { printf 'FAIL package-check: source package must contain only README.md\n' >&2; exit 1; }

while IFS= read -r path; do
  case "$path" in */build/*|*/dist/*|*/tests/tmp/*|*/__pycache__/*|*.pyc|*.ppu|*.o|*.a|*.so|*.exe) printf 'FAIL package-check: generated artifact leaked: %s\n' "$path" >&2; exit 1;; esac
done < <(find "$TMP/tar/$NAME" -type f | LC_ALL=C sort)

for required in README.md Makefile scripts/build.sh scripts/install.sh scripts/package.sh scripts/package_test.sh tests/target_format_matrix.py tests/native_linker_driver_contract.py tests/native_host_smoke.py src/rcc_native_linker.pas src/rcc_macho.pas src/rcc_object_writer.pas include/rcc/capabilities.h; do
  [[ -f $TMP/tar/$NAME/$required ]] || { printf 'FAIL package-check: omitted %s\n' "$required" >&2; exit 1; }
done
for forbidden in scripts/rcc-driver.sh scripts/release_status.py scripts/source_feature_scan.py src/rcc_release_gate.pas; do
  [[ ! -e $TMP/tar/$NAME/$forbidden ]] || { printf 'FAIL package-check: obsolete component shipped: %s\n' "$forbidden" >&2; exit 1; }
done

PACKAGE_LOG="$TMP/package-self-test.log"
if ! make -C "$TMP/tar/$NAME" test >"$PACKAGE_LOG" 2>&1; then
  printf 'FAIL package-check: extracted source archive did not build and test\n' >&2
  sed -n '1,240p' "$PACKAGE_LOG" >&2
  exit 1
fi

printf 'package check passed: reproducible archives, manifest, native-only source tree, extracted-tree tests\n'
