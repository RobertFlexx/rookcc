#!/usr/bin/env python3
"""Reproducible RCC/GCC/Clang optimization benchmark for release gates."""
from __future__ import annotations

import argparse
import csv
import json
import pathlib
import re
import shutil
import statistics
import subprocess
import tempfile
import time

OPTS = ["O0", "O1", "O2", "O3", "Os", "Oz"]
SCALES = [("tiny", 8, 2_000_000), ("small", 64, 500_000), ("medium", 256, 125_000)]


def source(functions: int, iterations: int) -> str:
    pieces = ["#include <stdio.h>\n#include <stdint.h>\n"]
    pieces.append(
        "static uint64_t rotl64(uint64_t x,unsigned r){"
        "r&=63u;return r?((x<<r)|(x>>(64u-r))):x;}\n"
    )
    for i in range(functions):
        c1 = ((0x9E3779B97F4A7C15 * (i + 1)) | 1) & 0xFFFFFFFFFFFFFFFF
        c2 = ((0xD1B54A32D192ED03 ^ (i * 0x94D049BB133111EB)) | 1) & 0xFFFFFFFFFFFFFFFF
        r = (i * 7 + 13) % 63 + 1
        pieces.append(
            f"static uint64_t f{i}(uint64_t x){{"
            f"x^=UINT64_C(0x{c1:016x});"
            f"x=rotl64(x,{r}u);"
            f"x*=UINT64_C(0x{c2:016x});"
            "return x^(x>>17);}\n"
        )
    pieces.append("typedef uint64_t(*fn)(uint64_t);static fn const fs[]={")
    pieces.append(",".join(f"f{i}" for i in range(functions)))
    pieces.append("};\n")
    pieces.append(
        f"int main(void){{uint64_t x=1;uint64_t i;for(i=0;i<UINT64_C({iterations});++i)"
        f"{{x=fs[(x^i)&{functions - 1}u](x+i);}}"
        'printf("%llu\\n",(unsigned long long)x);return 0;}\n'
    )
    return "".join(pieces)


def run(cmd: list[str], timeout: int) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, timeout=timeout)


def median_command(cmd: list[str], repeats: int, timeout: int, remove: pathlib.Path | None = None) -> float:
    samples: list[float] = []
    for _ in range(repeats):
        if remove:
            remove.unlink(missing_ok=True)
        start = time.perf_counter()
        result = run(cmd, timeout)
        samples.append(time.perf_counter() - start)
        if result.returncode:
            raise RuntimeError(" ".join(cmd) + "\n" + result.stdout + result.stderr)
    return statistics.median(samples)


def section_sizes(path: pathlib.Path) -> tuple[int | None, int | None, int | None]:
    tool = shutil.which("size")
    if not tool:
        return None, None, None
    result = run([tool, "-B", str(path)], 10)
    if result.returncode:
        return None, None, None
    for line in reversed(result.stdout.splitlines()):
        fields = line.split()
        if len(fields) >= 4 and all(x.isdigit() for x in fields[:4]):
            return int(fields[0]), int(fields[1]), int(fields[2])
    return None, None, None


def stripped_bytes(path: pathlib.Path, output: pathlib.Path) -> int | None:
    tool = shutil.which("strip")
    if not tool:
        return None
    shutil.copy2(path, output)
    result = run([tool, "--strip-all", str(output)], 20)
    return output.stat().st_size if result.returncode == 0 else None


def version(path: str) -> str:
    result = run([path, "--version"], 10)
    text = (result.stdout or result.stderr).strip()
    return text.splitlines()[0] if text else "unknown"


def markdown(rows: list[dict[str, object]], compilers: dict[str, str]) -> str:
    out = ["# RCC optimization benchmark", "", "## Compilers", ""]
    for name, path in compilers.items():
        out.append(f"- **{name}:** `{version(path)}` (`{path}`)")
    for scale, _, _ in SCALES:
        group = [row for row in rows if row["program"] == scale]
        out += ["", f"## {scale.capitalize()}", "", "| Compiler | Opt | Compile ms | Runtime ms | Exe bytes | Stripped | .text |", "|---|---:|---:|---:|---:|---:|---:|"]
        for row in group:
            out.append(
                f"| {row['compiler']} | -{row['optimization']} | "
                f"{float(row['compile_seconds_median']) * 1000:.3f} | "
                f"{float(row['runtime_seconds_median']) * 1000:.3f} | "
                f"{row['binary_bytes']} | {row['stripped_bytes'] or 'n/a'} | "
                f"{row['text_bytes'] or 'n/a'} |"
            )
    return "\n".join(out) + "\n"


parser = argparse.ArgumentParser()
parser.add_argument("--rcc", required=True)
parser.add_argument("--gcc", default=shutil.which("gcc") or shutil.which("cc"))
parser.add_argument("--clang", default=shutil.which("clang"))
parser.add_argument("--compile-runs", type=int, default=3)
parser.add_argument("--runtime-runs", type=int, default=5)
parser.add_argument("--json-out")
parser.add_argument("--csv-out")
parser.add_argument("--markdown-out")
args = parser.parse_args()

compilers = {"rcc": str(pathlib.Path(args.rcc).resolve())}
if args.gcc:
    compilers["gcc"] = str(pathlib.Path(args.gcc).resolve())
if args.clang:
    compilers["clang"] = str(pathlib.Path(args.clang).resolve())
if len(compilers) < 2:
    raise SystemExit("at least one GCC/Clang comparison compiler is required")

rows: list[dict[str, object]] = []
with tempfile.TemporaryDirectory() as td:
    root = pathlib.Path(td)
    for scale, functions, iterations in SCALES:
        c = root / f"{scale}.c"
        c.write_text(source(functions, iterations))
        expected: str | None = None
        for name, compiler in compilers.items():
            for opt in OPTS:
                exe = root / f"{scale}-{name}-{opt}"
                command = [compiler, "-std=c17", f"-{opt}", str(c), "-o", str(exe)]
                compile_seconds = median_command(command, args.compile_runs, 180, exe)
                warm = run([str(exe)], 90)
                if warm.returncode:
                    raise RuntimeError(warm.stderr)
                runtime_seconds = median_command([str(exe)], args.runtime_runs, 90)
                output = run([str(exe)], 90).stdout
                if expected is None:
                    expected = output
                if output != expected:
                    raise RuntimeError(f"checksum mismatch: {scale} {name} -{opt}")
                text, data, bss = section_sizes(exe)
                stripped = stripped_bytes(exe, root / f"{exe.name}.stripped")
                rows.append({
                    "program": scale,
                    "functions": functions,
                    "iterations": iterations,
                    "compiler": name,
                    "compiler_version": version(compiler),
                    "optimization": opt,
                    "compile_seconds_median": round(compile_seconds, 6),
                    "runtime_seconds_median": round(runtime_seconds, 6),
                    "binary_bytes": exe.stat().st_size,
                    "stripped_bytes": stripped,
                    "text_bytes": text,
                    "data_bytes": data,
                    "bss_bytes": bss,
                    "output": output.strip(),
                })

print("program compiler opt compile_ms runtime_ms bytes stripped text")
for row in rows:
    print(
        f"{row['program']:7} {row['compiler']:8} -{row['optimization']:2} "
        f"{float(row['compile_seconds_median']) * 1000:10.3f} "
        f"{float(row['runtime_seconds_median']) * 1000:10.3f} "
        f"{row['binary_bytes']:8} {str(row['stripped_bytes']):>8} {str(row['text_bytes']):>8}"
    )

payload = {"compilers": {name: {"path": path, "version": version(path)} for name, path in compilers.items()}, "results": rows}
if args.json_out:
    pathlib.Path(args.json_out).write_text(json.dumps(payload, indent=2) + "\n")
if args.csv_out:
    with pathlib.Path(args.csv_out).open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
if args.markdown_out:
    pathlib.Path(args.markdown_out).write_text(markdown(rows, compilers))
