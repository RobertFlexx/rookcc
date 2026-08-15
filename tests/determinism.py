#!/usr/bin/env python3
"""Verify deterministic object and executable emission across repeated builds."""
from __future__ import annotations

import hashlib
import pathlib
import subprocess
import sys
import tempfile

rcc = pathlib.Path(sys.argv[1]).resolve()
SOURCE = r'''#include <stdio.h>
struct P { long x; double y; };
static struct P make(long n) { struct P p = {n * 7, n / 8.0}; return p; }
int main(void) { struct P p = make(24); printf("%ld %.1f\n", p.x, p.y); return 0; }
'''


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


failed = 0
with tempfile.TemporaryDirectory() as td:
    root = pathlib.Path(td)
    source = root / "determinism.c"
    source.write_text(SOURCE)
    for mode, extra, suffix in [
        ("object", ["-c"], ".o"),
        ("executable", [], ""),
    ]:
        hashes: list[str] = []
        details = ""
        ok = True
        for run in range(3):
            output = root / f"{mode}-{run}{suffix}"
            cp = subprocess.run(
                [str(rcc), "-std=c17", "-O2", *extra, str(source), "-o", str(output)],
                text=True,
                capture_output=True,
                timeout=45,
            )
            details += cp.stdout + cp.stderr
            if cp.returncode != 0:
                ok = False
                break
            hashes.append(digest(output))
        ok = ok and len(set(hashes)) == 1
        print(("PASS" if ok else "FAIL"), "deterministic-" + mode)
        if not ok:
            if hashes:
                print("hashes:", " ".join(hashes))
            print(details)
            failed += 1

sys.exit(1 if failed else 0)
