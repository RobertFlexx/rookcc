#!/usr/bin/env python3
"""Compare rcc against gcc on correctness, runtime, code size and compile time.

Usage:
    python3 bench/compare.py [--rcc build/rcc] [--opt -O2] [--runs 5]
                             [--json out.json] [--baseline old.json]

Every benchmark prints a checksum line; rcc output must match gcc output
exactly or the benchmark is reported as a correctness failure.
"""

import argparse
import json
import os
import shutil
import statistics
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
PROGRAMS = os.path.join(HERE, "programs")


def sh(cmd, timeout=600):
    started = time.perf_counter()
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    return proc, time.perf_counter() - started


def load_segment_sizes(path):
    """(file bytes, resident bytes) summed over PT_LOAD program headers.

    Section headers are not comparable here because rcc emits executables
    without a section table, so the program headers are the common ground.
    """
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:4] != b"\x7fELF" or data[4] != 2:
        return os.path.getsize(path), os.path.getsize(path)
    little = data[5] == 1
    order = "little" if little else "big"

    def num(off, size):
        return int.from_bytes(data[off:off + size], order)

    phoff = num(0x20, 8)
    phentsize = num(0x36, 2)
    phnum = num(0x38, 2)
    filesz = memsz = 0
    for i in range(phnum):
        base = phoff + i * phentsize
        if num(base, 4) != 1:  # PT_LOAD
            continue
        filesz += num(base + 0x20, 8)
        memsz += num(base + 0x28, 8)
    return filesz, memsz


def best_of(exe, runs):
    """Return (best wall time, stdout) - best-of-N to reduce scheduler noise."""
    times = []
    output = None
    for _ in range(runs):
        proc, elapsed = sh([exe])
        if proc.returncode != 0:
            return None, "EXIT=%d %s" % (proc.returncode, proc.stderr.strip())
        output = proc.stdout
        times.append(elapsed)
    return min(times), output


def compile_with(compiler_cmd, source, out, repeats=3):
    """Compile, returning (ok, best compile time, error text)."""
    best = None
    err = ""
    for _ in range(repeats):
        proc, elapsed = sh(compiler_cmd + [source, "-o", out])
        if proc.returncode != 0:
            return False, None, (proc.stderr or proc.stdout).strip()
        best = elapsed if best is None else min(best, elapsed)
    return True, best, err


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rcc", default=os.path.join(HERE, os.pardir, "build", "rcc"))
    ap.add_argument("--gcc", default="gcc")
    ap.add_argument("--opt", default="-O2")
    ap.add_argument("--gcc-opt", default=None,
                    help="optimization flag for gcc (defaults to --opt)")
    ap.add_argument("--runs", type=int, default=5)
    ap.add_argument("--compile-repeats", type=int, default=3)
    ap.add_argument("--json", default=None)
    ap.add_argument("--baseline", default=None)
    ap.add_argument("--only", default=None, help="comma separated benchmark names")
    args = ap.parse_args()

    rcc = os.path.abspath(args.rcc)
    gcc_opt = args.gcc_opt or args.opt
    if not os.path.exists(rcc):
        sys.exit("rcc binary not found: %s" % rcc)
    if shutil.which(args.gcc) is None:
        sys.exit("gcc not found in PATH")

    names = sorted(f[:-2] for f in os.listdir(PROGRAMS) if f.endswith(".c"))
    if args.only:
        wanted = {n.strip() for n in args.only.split(",")}
        names = [n for n in names if n in wanted]

    baseline = {}
    if args.baseline and os.path.exists(args.baseline):
        with open(args.baseline) as fh:
            baseline = {r["name"]: r for r in json.load(fh)["results"]}

    results = []
    workdir = tempfile.mkdtemp(prefix="rccbench-")
    try:
        for name in names:
            src = os.path.join(PROGRAMS, name + ".c")
            rcc_exe = os.path.join(workdir, name + ".rcc")
            gcc_exe = os.path.join(workdir, name + ".gcc")

            r_ok, r_ct, r_err = compile_with([rcc, args.opt], src, rcc_exe,
                                             args.compile_repeats)
            g_ok, g_ct, g_err = compile_with([args.gcc, gcc_opt], src, gcc_exe,
                                             args.compile_repeats)

            entry = {"name": name, "rcc_compiled": r_ok, "gcc_compiled": g_ok}
            if not r_ok:
                entry["error"] = "rcc compile failed: " + r_err[:400]
                results.append(entry)
                print("%-10s COMPILE FAIL  %s" % (name, r_err.splitlines()[:1]))
                continue
            if not g_ok:
                entry["error"] = "gcc compile failed: " + g_err[:400]
                results.append(entry)
                print("%-10s gcc compile failed" % name)
                continue

            r_time, r_out = best_of(rcc_exe, args.runs)
            g_time, g_out = best_of(gcc_exe, args.runs)
            correct = (r_out == g_out) and r_time is not None

            r_load, r_mem = load_segment_sizes(rcc_exe)
            g_load, g_mem = load_segment_sizes(gcc_exe)
            entry.update({
                "rcc_compile_s": r_ct,
                "gcc_compile_s": g_ct,
                "rcc_run_s": r_time,
                "gcc_run_s": g_time,
                "rcc_load": r_load,
                "gcc_load": g_load,
                "rcc_mem": r_mem,
                "gcc_mem": g_mem,
                "rcc_file": os.path.getsize(rcc_exe),
                "gcc_file": os.path.getsize(gcc_exe),
                "correct": correct,
                "rcc_output": (r_out or "").strip(),
                "gcc_output": (g_out or "").strip(),
            })
            results.append(entry)

            if not correct:
                print("%-10s WRONG OUTPUT  rcc=%r gcc=%r"
                      % (name, (r_out or "")[:60], (g_out or "")[:60]))
                continue

            slow = r_time / g_time if g_time else float("nan")
            fat = entry["rcc_file"] / entry["gcc_file"] if entry["gcc_file"] else 0
            cspeed = g_ct / r_ct if r_ct else 0
            delta = ""
            if name in baseline and baseline[name].get("rcc_run_s"):
                prev = baseline[name]["rcc_run_s"]
                delta = "  (%+.1f%% vs baseline)" % ((r_time / prev - 1) * 100)
            print("%-10s run %7.3fs vs %7.3fs = %5.2fx slower | "
                  "file %6d vs %6d = %4.2fx | compile %.3fs vs %.3fs = %4.1fx faster%s"
                  % (name, r_time, g_time, slow, entry["rcc_file"],
                     entry["gcc_file"], fat, r_ct, g_ct, cspeed, delta))

        good = [r for r in results if r.get("correct")]
        if good:
            slowdowns = [r["rcc_run_s"] / r["gcc_run_s"] for r in good
                         if r["gcc_run_s"]]
            sizes = [r["rcc_file"] / r["gcc_file"] for r in good if r["gcc_file"]]
            cspeeds = [r["gcc_compile_s"] / r["rcc_compile_s"] for r in good
                       if r["rcc_compile_s"]]
            print("\n%d/%d correct | geomean %.2fx slower than gcc %s | "
                  "geomean %.2fx file size | geomean %.1fx faster to compile"
                  % (len(good), len(results),
                     statistics.geometric_mean(slowdowns), gcc_opt,
                     statistics.geometric_mean(sizes),
                     statistics.geometric_mean(cspeeds)))
        else:
            print("\nno benchmarks passed")

        if args.json:
            with open(args.json, "w") as fh:
                json.dump({"opt": args.opt, "gcc_opt": gcc_opt,
                           "results": results}, fh, indent=2)
        return 0 if len(good) == len(results) else 1
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
