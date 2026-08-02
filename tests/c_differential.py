#!/usr/bin/env python3
"""Differentially test rcc against a reference compiler.

Each program in tests/c prints a deterministic transcript. The program is
built by both compilers at several optimization levels and the transcripts
must match exactly, so any codegen regression shows up as a diff.

Usage:
    python3 tests/c_differential.py [path-to-rcc] [--reference gcc]
                                    [--levels -O0,-O1,-O2,-O3,-Os]
                                    [--keep-going]
"""

import argparse
import difflib
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASES = os.path.join(HERE, "c")
DEFAULT_RCC = os.path.join(HERE, os.pardir, "build", "rcc")


def run(cmd, cwd=None, timeout=120):
    return subprocess.run(cmd, capture_output=True, text=True, cwd=cwd,
                          timeout=timeout)


def build_and_run(compiler, flags, source, out):
    build = run([compiler] + flags + [source, "-o", out])
    if build.returncode != 0:
        return None, "compile failed: " + (build.stderr or build.stdout).strip()
    execution = run([out])
    if execution.returncode != 0:
        return None, "exit %d: %s" % (execution.returncode,
                                      execution.stderr.strip())
    return execution.stdout, ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rcc", nargs="?", default=DEFAULT_RCC)
    ap.add_argument("--reference", default="gcc")
    ap.add_argument("--levels", default="-O0,-O1,-O2,-O3,-Os")
    ap.add_argument("--keep-going", action="store_true")
    args = ap.parse_args()

    rcc = os.path.abspath(args.rcc)
    if not os.path.exists(rcc):
        sys.exit("rcc binary not found: %s" % rcc)
    if shutil.which(args.reference) is None:
        sys.exit("reference compiler not found: %s" % args.reference)

    levels = [lvl.strip() for lvl in args.levels.split(",") if lvl.strip()]
    sources = sorted(f for f in os.listdir(CASES) if f.endswith(".c"))
    if not sources:
        sys.exit("no test programs in %s" % CASES)

    workdir = tempfile.mkdtemp(prefix="rccdiff-")
    failures = []
    checks = 0
    try:
        for name in sources:
            src = os.path.join(CASES, name)
            # The reference transcript is built once at -O2; a conforming
            # program must produce the same output at every level.
            expected, err = build_and_run(
                args.reference, ["-O2", "-w"], src,
                os.path.join(workdir, name + ".ref"))
            if expected is None:
                failures.append("%s: reference %s" % (name, err))
                continue

            for level in levels:
                checks += 1
                actual, err = build_and_run(
                    rcc, [level], src,
                    os.path.join(workdir, "%s%s.rcc" % (name, level)))
                if actual is None:
                    failures.append("%s %s: %s" % (name, level, err))
                    if not args.keep_going:
                        break
                    continue
                if actual != expected:
                    diff = "\n".join(list(difflib.unified_diff(
                        expected.splitlines(), actual.splitlines(),
                        "gcc", "rcc " + level, lineterm=""))[:24])
                    failures.append("%s %s: output mismatch\n%s"
                                    % (name, level, diff))
                    if not args.keep_going:
                        break
            print("%-14s %s" % (name, "ok" if not any(
                f.startswith(name) for f in failures) else "FAIL"))
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    if failures:
        print("\n%d failure(s) across %d checks:\n" % (len(failures), checks))
        for f in failures:
            print(f)
            print()
        return 1
    print("\nC differential suite passed: %d programs x %d levels"
          % (len(sources), len(levels)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
