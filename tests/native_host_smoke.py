#!/usr/bin/env python3
"""Compile and execute a hosted C program on the machine running the test."""

from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile


def run(*arguments: str) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(arguments, text=True, capture_output=True)
    if completed.returncode != 0:
        raise SystemExit(
            f"command failed ({completed.returncode}): {' '.join(arguments)}\n"
            f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
        )
    return completed


def main(arguments: list[str]) -> int:
    if len(arguments) != 2:
        raise SystemExit(f"usage: {arguments[0]} RCC")
    compiler = pathlib.Path(arguments[1]).resolve()
    if not compiler.is_file():
        raise SystemExit(f"compiler not found: {compiler}")

    target = run(str(compiler), "-dumpmachine").stdout.strip()
    supported_host = any(
        operating_system in target
        for operating_system in ("linux", "darwin", "freebsd", "openbsd", "netbsd")
    ) and target.startswith(("x86_64-", "aarch64-", "riscv64-"))
    if not supported_host:
        raise SystemExit(f"native smoke test does not recognize host target {target}")

    with tempfile.TemporaryDirectory(prefix="rcc-native-host-") as temporary:
        root = pathlib.Path(temporary)
        source = root / "native_host.c"
        executable = root / "native host executable"
        object_file = root / "native host object.o"
        source.write_text(
            "#include <stdio.h>\n"
            'int main(void) { printf("rcc-native:%d\\n", 42); return 0; }\n',
            encoding="utf-8",
        )

        run(str(compiler), str(source), "-O2", "-o", str(executable))
        output = run(str(executable)).stdout
        if output != "rcc-native:42\n":
            raise SystemExit(f"native executable output mismatch: {output!r}")

        direct_run = run(str(compiler), "-O2", "-run", str(source)).stdout
        if direct_run != "rcc-native:42\n":
            raise SystemExit(f"native -run output mismatch: {direct_run!r}")

        run(str(compiler), "-c", str(source), "-o", str(object_file))
        magic = object_file.read_bytes()[:4]
        expected_magic = b"\xcf\xfa\xed\xfe" if "darwin" in target else b"\x7fELF"
        if magic != expected_magic:
            raise SystemExit(
                f"native object format mismatch for {target}: {magic.hex()}"
            )

    print(f"native hosted compile/link/run passed for {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
