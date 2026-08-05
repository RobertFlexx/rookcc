#!/usr/bin/env python3
"""Reproducible RCC/GCC compile-time, output-size and runtime benchmark."""
from __future__ import annotations

import argparse
import json
import pathlib
import shutil
import statistics
import subprocess
import tempfile
import time


def source(functions: int, iterations: int) -> str:
    pieces = ['#include <stdio.h>\n#include <stdint.h>\n']
    for i in range(functions):
        pieces.append(
            f'static uint64_t f{i}(uint64_t x){{x^={i+1}u;'
            'x*=UINT64_C(11400714819323198485);return (x>>17)|(x<<47);}\n'
        )
    pieces.append(f'int main(void){{uint64_t x=1;int r;for(r=0;r<{iterations};r++){{')
    for i in range(functions):
        pieces.append(f'x=f{i}(x);')
    pieces.append('}printf("%llu\\n",(unsigned long long)x);return 0;}\n')
    return ''.join(pieces)


def timed_command(cmd: list[str], repeats: int, timeout: int) -> tuple[float, subprocess.CompletedProcess[str]]:
    values: list[float] = []
    last: subprocess.CompletedProcess[str] | None = None
    for _ in range(repeats):
        start = time.perf_counter()
        last = subprocess.run(cmd, text=True, capture_output=True, timeout=timeout)
        values.append(time.perf_counter() - start)
        if last.returncode:
            raise RuntimeError(' '.join(cmd) + '\n' + last.stdout + last.stderr)
    assert last is not None
    return statistics.median(values), last


parser = argparse.ArgumentParser()
parser.add_argument('--rcc', required=True)
parser.add_argument('--json-out')
args = parser.parse_args()
cc = shutil.which('gcc') or shutil.which('cc')
if not cc:
    raise SystemExit('system GCC/cc not found')
compilers = {'rcc': str(pathlib.Path(args.rcc).resolve()), 'gcc': cc}
rows: list[dict[str, object]] = []

with tempfile.TemporaryDirectory() as td:
    root = pathlib.Path(td)
    for scale, functions, iterations in [('small', 8, 500000), ('large', 220, 20000)]:
        c = root / (scale + '.c')
        c.write_text(source(functions, iterations))
        expected: str | None = None
        for opt in ['-O0', '-O2', '-Os']:
            for name, compiler in compilers.items():
                exe = root / f'{scale}-{name}-{opt[1:]}'
                compile_seconds, _ = timed_command(
                    [compiler, '-std=c17', opt, str(c), '-o', str(exe)], 3, 180
                )
                # Warm the executable once before taking runtime samples.
                warm = subprocess.run([str(exe)], text=True, capture_output=True, timeout=60)
                if warm.returncode:
                    raise RuntimeError(warm.stderr)
                runtime_seconds, run = timed_command([str(exe)], 5, 60)
                if expected is None:
                    expected = run.stdout
                if run.stdout != expected:
                    raise RuntimeError(f'output mismatch for {scale} {name} {opt}')
                rows.append(
                    {
                        'program': scale,
                        'functions': functions,
                        'iterations': iterations,
                        'compiler': name,
                        'optimization': opt,
                        'compile_seconds_median': round(compile_seconds, 6),
                        'runtime_seconds_median': round(runtime_seconds, 6),
                        'binary_bytes': exe.stat().st_size,
                        'output': run.stdout.strip(),
                    }
                )

print('program compiler opt compile_s runtime_s bytes')
for row in rows:
    print(
        f"{row['program']:7} {row['compiler']:8} {row['optimization']:3} "
        f"{row['compile_seconds_median']:9.6f} "
        f"{row['runtime_seconds_median']:9.6f} {row['binary_bytes']:8}"
    )
text = json.dumps(rows, indent=2)
if args.json_out:
    pathlib.Path(args.json_out).write_text(text + '\n')
