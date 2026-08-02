#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

FPC_BIN="${FPC:-fpc}"
if ! command -v "$FPC_BIN" >/dev/null 2>&1; then
  printf 'error: Free Pascal compiler not found (set FPC=/path/to/fpc)\n' >&2
  exit 127
fi

mkdir -p build/units
"$FPC_BIN" \
  -Mobjfpc -Sh -O2 -XX -Xs -CX \
  -Fu./src -FU./build/units -FE./build \
  -o"$(pwd)/build/rcc" \
  src/rcc.pas

printf 'built %s\n' "$(pwd)/build/rcc"
