#!/usr/bin/env python3
"""Compile and run every shipped example, including the multi-file example."""
from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile

rcc = pathlib.Path(sys.argv[1]).resolve()
root = pathlib.Path(__file__).resolve().parents[1]
examples = root / "examples"
CASES = [
    ("hello", [examples / "hello.c"], [], 0),
    ("control", [examples / "control.c"], [], 0),
    ("fibonacci", [examples / "fibonacci.c"], [], 0),
    ("memory", [examples / "memory.c"], [], 0),
    ("preprocessor", [examples / "preprocessor.c"], [], 0),
    ("argc", [examples / "argc.c"], ["one", "two"], 0),
    ("return42", [examples / "return42.c"], [], 42),
    ("multi-file", [examples / "multi_main.c", examples / "multi_math.c"], [], 0),
]

failed = 0
with tempfile.TemporaryDirectory() as td:
    work = pathlib.Path(td)
    for name, sources, args, expected_status in CASES:
        exe = work / name
        cp = subprocess.run(
            [str(rcc), "-std=c17", "-O2", *map(str, sources), "-o", str(exe)],
            text=True,
            capture_output=True,
            timeout=45,
        )
        detail = cp.stdout + cp.stderr
        ok = cp.returncode == 0
        if ok:
            rp = subprocess.run([str(exe), *args], text=True, capture_output=True, timeout=20)
            detail += rp.stdout + rp.stderr
            ok = rp.returncode == expected_status
        print(("PASS" if ok else "FAIL"), "example-" + name)
        if not ok:
            print(detail)
            failed += 1

sys.exit(1 if failed else 0)
