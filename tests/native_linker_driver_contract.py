#!/usr/bin/env python3
"""Exercise native host linking without requiring every supported host OS."""

from __future__ import annotations

import json
import os
import pathlib
import stat
import subprocess
import sys
import tempfile


def run(
    compiler: pathlib.Path,
    arguments: list[str],
    environment: dict[str, str],
    *,
    expect_success: bool = True,
) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        [str(compiler), *arguments],
        env=environment,
        text=True,
        capture_output=True,
    )
    if expect_success and completed.returncode != 0:
        raise SystemExit(
            f"command failed ({completed.returncode}): "
            f"{compiler} {' '.join(arguments)}\n{completed.stderr}"
        )
    if not expect_success and completed.returncode == 0:
        raise SystemExit(
            f"command unexpectedly succeeded: {compiler} {' '.join(arguments)}"
        )
    return completed


def write_fake_linker(path: pathlib.Path) -> None:
    path.write_text(
        """#!/usr/bin/env python3
import json
import os
import pathlib
import stat
import sys

arguments = sys.argv[1:]
output_index = arguments.index("-o")
output = pathlib.Path(arguments[output_index + 1])
object_files = []
for argument in arguments:
    candidate = pathlib.Path(argument)
    if candidate.is_file():
        data = candidate.read_bytes()
        if data.startswith(b"\\x7fELF") or data.startswith(b"\\xcf\\xfa\\xed\\xfe"):
            object_files.append({"path": argument, "magic": data[:4].hex()})
capture = pathlib.Path(os.environ["RCC_TEST_LINK_CAPTURE"])
capture.write_text(json.dumps({"arguments": arguments, "objects": object_files}))
output.write_bytes(b"rcc native-link test output\\n")
output.chmod(output.stat().st_mode | stat.S_IXUSR)
""",
        encoding="utf-8",
    )
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def assert_sequence(values: list[str], sequence: list[str]) -> None:
    width = len(sequence)
    if not any(values[index : index + width] == sequence for index in range(len(values))):
        raise SystemExit(f"missing linker argument sequence: {sequence!r}\nactual: {values!r}")


def native_environment(
    base: dict[str, str], target: str, linker: pathlib.Path, capture: pathlib.Path
) -> dict[str, str]:
    result = dict(base)
    result["RCC_TEST_NATIVE_TARGET"] = target
    result["RCC_PLATFORM_LINKER"] = str(linker)
    result["RCC_TEST_LINK_CAPTURE"] = str(capture)
    return result


def check_native_link(
    compiler: pathlib.Path,
    root: pathlib.Path,
    linker: pathlib.Path,
    target: str,
    expected_triple: str,
    expected_magic: str,
    expected_darwin_arch: str | None,
) -> None:
    capture = root / f"{target}-capture.json"
    environment = native_environment(os.environ, target, linker, capture)
    machine = run(compiler, ["-dumpmachine"], environment).stdout.strip()
    if machine != expected_triple:
        raise SystemExit(f"native target mismatch: expected {expected_triple}, got {machine}")

    source = root / "native source.c"
    output = root / f"{target} native output"
    extra_object = root / "extra input.o"
    explicit_library = root / "libexplicit.dylib"
    library_directory = root / "library directory"
    runpath = root / "runtime library directory"
    sysroot = root / "target sysroot"
    extra_object.write_bytes(b"not inspected by the fake linker")
    explicit_library.write_bytes(b"fake dylib input")
    library_directory.mkdir(exist_ok=True)
    runpath.mkdir(exist_ok=True)
    sysroot.mkdir(exist_ok=True)

    dry_run = run(
        compiler,
        ["-###", str(source), "-o", str(output)],
        environment,
    )
    if "native platform driver" not in dry_run.stdout or capture.exists():
        raise SystemExit("native dry-run did not describe the linker without running it")

    run(
        compiler,
        [
            str(source),
            str(extra_object),
            str(explicit_library),
            "-L",
            str(library_directory),
            "-lcontract",
            "-R",
            str(runpath),
            "--sysroot",
            str(sysroot),
            "-o",
            str(output),
        ],
        environment,
    )
    if not output.is_file() or not os.access(output, os.X_OK):
        raise SystemExit(f"native linker output is not executable: {output}")
    captured = json.loads(capture.read_text(encoding="utf-8"))
    arguments: list[str] = captured["arguments"]
    objects: list[dict[str, str]] = captured["objects"]
    generated = [item for item in objects if item["magic"] == expected_magic]
    if len(generated) != 1:
        raise SystemExit(
            f"expected one generated {expected_magic} object, got {objects!r}"
        )
    if pathlib.Path(generated[0]["path"]).exists():
        raise SystemExit("temporary native-link object was not removed")
    if str(extra_object) not in arguments or str(explicit_library) not in arguments:
        raise SystemExit(f"native linker inputs were not preserved: {arguments!r}")
    if f"-L{library_directory}" not in arguments or "-lcontract" not in arguments:
        raise SystemExit(f"native linker library flags were not preserved: {arguments!r}")
    if "-lsourcecontract" not in arguments:
        raise SystemExit(f"source-declared native library was not linked: {arguments!r}")
    assert_sequence(arguments, ["-Xlinker", "-rpath", "-Xlinker", str(runpath)])
    assert_sequence(arguments, ["-o", str(output)])
    if expected_darwin_arch is None:
        if "-arch" in arguments:
            raise SystemExit(f"non-Darwin native link received -arch: {arguments!r}")
        if f"--sysroot={sysroot}" not in arguments:
            raise SystemExit(f"native ELF sysroot was not forwarded: {arguments!r}")
    else:
        assert_sequence(arguments, ["-arch", expected_darwin_arch])
        assert_sequence(arguments, ["-isysroot", str(sysroot)])

    capture.unlink()
    object_output = root / f"{target} direct object.o"
    run(compiler, ["-c", str(source), "-o", str(object_output)], environment)
    if capture.exists():
        raise SystemExit("-c unexpectedly invoked the native platform linker")
    if object_output.read_bytes()[:4].hex() != expected_magic:
        raise SystemExit(f"-c emitted the wrong native object format for {target}")

    object_link_output = root / f"{target} object-only output"
    run(
        compiler,
        [str(object_output), "-o", str(object_link_output)],
        environment,
    )
    object_link_arguments = json.loads(capture.read_text(encoding="utf-8"))[
        "arguments"
    ]
    if str(object_output) not in object_link_arguments:
        raise SystemExit("native object-only link did not forward its input")


def main(arguments: list[str]) -> int:
    if len(arguments) != 2:
        raise SystemExit(f"usage: {arguments[0]} RCC_DRIVER_TEST_BINARY")
    compiler = pathlib.Path(arguments[1]).resolve()
    if not compiler.is_file():
        raise SystemExit(f"compiler not found: {compiler}")

    build_directory = compiler.parent
    with tempfile.TemporaryDirectory(prefix="rcc-native-driver-", dir=build_directory) as temp:
        root = pathlib.Path(temp)
        linker = root / "fake platform linker.py"
        write_fake_linker(linker)
        source = root / "native source.c"
        source.write_text(
            "#pragma rcc link sourcecontract\n"
            'extern int puts(const char *);\n'
            'int main(void) { puts("native driver"); return 0; }\n',
            encoding="utf-8",
        )

        cases = [
            (
                "x86_64-macos",
                "x86_64-apple-darwin-rcc",
                "cffaedfe",
                "x86_64",
            ),
            (
                "arm64-macos",
                "aarch64-apple-darwin-rcc",
                "cffaedfe",
                "arm64",
            ),
            (
                "x86_64-freebsd",
                "x86_64-unknown-freebsd-rcc",
                "7f454c46",
                None,
            ),
            (
                "aarch64-netbsd",
                "aarch64-unknown-netbsd-rcc",
                "7f454c46",
                None,
            ),
            (
                "riscv64-linux",
                "riscv64-unknown-linux-rcc",
                "7f454c46",
                None,
            ),
        ]
        for case in cases:
            check_native_link(compiler, root, linker, *case)

        cross_capture = root / "cross-capture.json"
        cross_environment = native_environment(
            os.environ, "x86_64-macos", linker, cross_capture
        )
        rejected = run(
            compiler,
            [
                "--target=arm64-macos",
                str(source),
                "-o",
                str(root / "invalid cross executable"),
            ],
            cross_environment,
            expect_success=False,
        )
        if "cross-target macOS executable linking" not in rejected.stderr:
            raise SystemExit(f"missing cross-link diagnostic:\n{rejected.stderr}")
        if cross_capture.exists():
            raise SystemExit("cross-target executable unexpectedly invoked the host linker")

        missing_environment = dict(cross_environment)
        missing_environment["RCC_PLATFORM_LINKER"] = str(
            root / "missing platform linker"
        )
        missing = run(
            compiler,
            [str(source), "-o", str(root / "missing-linker-output")],
            missing_environment,
            expect_success=False,
        )
        if "RCC_PLATFORM_LINKER is not executable" not in missing.stderr:
            raise SystemExit(f"missing native linker diagnostic:\n{missing.stderr}")

    print("native platform linker driver contract passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

