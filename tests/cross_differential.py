#!/usr/bin/env python3
"""Differentially test rcc's cross-compiled output by actually running it.

Each program in tests/cross is freestanding (no libc) and returns a checksum
as its exit status. The program is built for every target rcc advertises and
executed - natively for the host, under qemu-user for the others - and every
architecture must agree with the reference compiler.

Usage:
    python3 tests/cross_differential.py [path-to-rcc] [--reference gcc]
                                        [--levels -O0,-O2] [--keep-going]
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASES = os.path.join(HERE, "cross")
DEFAULT_RCC = os.path.join(HERE, os.pardir, "build", "rcc")

# (label, rcc target triple, qemu runner or None for native)
TARGETS = [
    ("x86_64", "x86_64-unknown-linux", None),
    ("aarch64", "aarch64-unknown-linux", "qemu-aarch64"),
    ("riscv64", "riscv64-unknown-linux", "qemu-riscv64"),
]


def run(cmd, timeout=120):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)


def build_and_run(compiler, flags, source, out, runner):
    build = run([compiler] + flags + [source, "-o", out])
    if build.returncode != 0:
        text = (build.stderr or build.stdout).strip().splitlines()
        return None, "compile: " + (text[0] if text else "failed")
    try:
        execution = run(([runner] if runner else []) + [out])
    except subprocess.TimeoutExpired:
        return None, "timeout"
    if execution.returncode < 0:
        return None, "signal %d" % -execution.returncode
    return execution.returncode, ""


def available(targets):
    usable = []
    for label, triple, runner in targets:
        if runner and shutil.which(runner) is None:
            print("skipping %s: %s not installed" % (label, runner))
            continue
        usable.append((label, triple, runner))
    return usable


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rcc", nargs="?", default=DEFAULT_RCC)
    ap.add_argument("--reference", default="gcc")
    ap.add_argument("--levels", default="-O0,-O2")
    ap.add_argument("--keep-going", action="store_true")
    args = ap.parse_args()

    rcc = os.path.abspath(args.rcc)
    if not os.path.exists(rcc):
        sys.exit("rcc binary not found: %s" % rcc)

    levels = [l.strip() for l in args.levels.split(",") if l.strip()]
    targets = available(TARGETS)
    sources = sorted(f for f in os.listdir(CASES) if f.endswith(".c"))
    if not sources:
        sys.exit("no cross test programs in %s" % CASES)

    workdir = tempfile.mkdtemp(prefix="rcccross-")
    failures = []
    checks = 0
    try:
        for name in sources:
            src = os.path.join(CASES, name)
            expected = None
            if shutil.which(args.reference):
                expected, err = build_and_run(
                    args.reference, ["-O2", "-w"], src,
                    os.path.join(workdir, name + ".ref"), None)
                if expected is None:
                    failures.append("%s: reference %s" % (name, err))
                    continue

            row = []
            for label, triple, runner in targets:
                worst = None
                for level in levels:
                    checks += 1
                    got, err = build_and_run(
                        rcc, [level, "-ffreestanding", "--target=" + triple],
                        src, os.path.join(workdir, "%s.%s%s" % (name, label, level)),
                        runner)
                    if got is None:
                        worst = err
                        failures.append("%s %s %s: %s" % (name, label, level, err))
                        break
                    if expected is not None and got != expected:
                        worst = "got %d want %d" % (got, expected)
                        failures.append("%s %s %s: %s"
                                        % (name, label, level, worst))
                        break
                row.append("%s=%s" % (label, worst if worst else "ok"))
            print("%-12s %s" % (name, "  ".join(row)))
            if failures and not args.keep_going:
                break
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    if failures:
        print("\n%d failure(s) across %d checks" % (len(failures), checks))
        for f in failures[:40]:
            print("  " + f)
        return 1
    print("\ncross differential suite passed: %d programs x %d targets x %d levels"
          % (len(sources), len(targets), len(levels)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
