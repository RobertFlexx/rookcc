#!/usr/bin/env python3
"""Require every bundled C/POSIX header to be self-contained and parseable."""
from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
RCC = pathlib.Path(sys.argv[1]).resolve()
INCLUDE = ROOT / "include"
HEADERS = sorted(
    path.relative_to(INCLUDE).as_posix()
    for path in INCLUDE.rglob("*.h")
    if not path.relative_to(INCLUDE).as_posix().startswith("rcc/")
)

failures = 0
with tempfile.TemporaryDirectory(prefix="rcc-header-check-") as temporary:
    source = pathlib.Path(temporary) / "header.c"
    for header in HEADERS:
        source.write_text(
            "#define _GNU_SOURCE 1\n"
            "#define _POSIX_C_SOURCE 200809L\n"
            f"#include <{header}>\n"
            "int main(void) { return 0; }\n",
            encoding="utf-8",
        )
        result = subprocess.run(
            [str(RCC), "-std=gnu17", "--check", str(source)],
            text=True,
            capture_output=True,
            timeout=30,
        )
        ok = result.returncode == 0
        print(("PASS" if ok else "FAIL"), header)
        if not ok:
            print(result.stdout + result.stderr)
            failures += 1

print(f"checked {len(HEADERS)} bundled headers")
raise SystemExit(1 if failures else 0)
