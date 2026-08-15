#!/usr/bin/env python3
"""Release-tree integrity and compiler-source reachability checks."""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "src"


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)
    print(f"FAIL {message}")


def require_file(path: pathlib.Path, failures: list[str]) -> None:
    if not path.is_file():
        fail(f"missing release input: {path.relative_to(ROOT)}", failures)


def read(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


failures: list[str] = []
version = read(ROOT / "VERSION").strip()
units = {path.stem: path for path in SRC.glob("*.pas")}
uses = {
    name: set(re.findall(r"\brcc_[a-z0-9_]+\b", read(path).lower()))
    for name, path in units.items()
}
seen: set[str] = set()
stack = ["rcc"]
while stack:
    name = stack.pop()
    if name in seen:
        continue
    seen.add(name)
    stack.extend(
        dependency
        for dependency in uses.get(name, set())
        if dependency in units and dependency not in seen
    )

unreachable = sorted(set(units) - seen)
if unreachable:
    fail("unreachable Pascal units: " + ", ".join(unreachable), failures)

required = [
    "Makefile",
    "README.md",
    "VERSION",
    "RELEASE_HARDENING.md",
    f"RELEASE_NOTES_{version}.md",
    f"VERIFICATION_{version}.md",
    f"COMPATIBILITY_{version}.md",
    "scripts/package.sh",
    "scripts/package_test.sh",
    "scripts/release_gate.sh",
    "bench/compare.py",
    "tests/c_differential.py",
    "tests/cross_differential.py",
    "tests/cross_execution.py",
    "tests/cross_abi_interop.py",
    "tests/semantic_conversions.py",
    "tests/standard_modes.py",
    "tests/release_hardening.py",
    "tests/parser_fuzz.py",
    "tests/determinism.py",
    "tests/examples_smoke.py",
    "tests/source_integrity.py",
]
for relative in required:
    require_file(ROOT / relative, failures)

empty_bodies: list[str] = []
for path in units.values():
    if re.search(r"\bbegin\s*end\s*;", read(path), re.IGNORECASE):
        empty_bodies.append(path.name)
if empty_bodies:
    fail("empty procedure/function bodies: " + ", ".join(sorted(empty_bodies)), failures)

match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
if not match:
    fail(f"invalid VERSION value: {version!r}", failures)
else:
    major, minor, patch = match.groups()
    version_number = int(major) * 100000 + int(minor) * 1000 + int(patch)
    checks = {
        "src/rcc_build.pas": [
            rf"RCCVersion\s*=\s*'{re.escape(version)}'",
            rf"RCCVersionNumber:.*?Result\s*:=\s*{version_number}\b",
        ],
        "src/rcc_feature_policy.pas": [
            rf"__ROOKCC_MAJOR__'\s*,\s*'{major}'",
            rf"__ROOKCC_MINOR__'\s*,\s*'{minor}'",
            rf"__ROOKCC_PATCH__'\s*,\s*'{patch}'",
        ],
        "include/rcc/version.h": [
            rf"RCC_VERSION_MAJOR\s+{major}\b",
            rf"RCC_VERSION_MINOR\s+{minor}\b",
            rf"RCC_VERSION_PATCH\s+{patch}\b",
            rf"RCC_VERSION_NUMBER\s+{version_number}\b",
            rf'RCC_VERSION_STRING\s+"{re.escape(version)}"',
        ],
        "include/rcc/features.h": [
            rf"__RCC_HEADER_VERSION__\s+{version_number}\b",
        ],
        "README.md": [re.escape(version)],
        "man/rcc.1": [re.escape(version)],
    }
    for relative, patterns in checks.items():
        text = read(ROOT / relative)
        for pattern in patterns:
            if not re.search(pattern, text, re.DOTALL):
                fail(f"version mismatch in {relative}: /{pattern}/", failures)

for forbidden in [
    ROOT / "src/rcc_string_pool.pas",
    ROOT / "scripts/rcc-driver.sh",
    ROOT / "scripts/release_status.py",
    ROOT / "scripts/source_feature_scan.py",
    ROOT / "src/rcc_release_gate.pas",
]:
    if forbidden.exists():
        fail(f"obsolete or disconnected component shipped: {forbidden.relative_to(ROOT)}", failures)

tracked_text = "\n".join(
    read(path)
    for path in list(SRC.glob("*.pas"))
    + [ROOT / "README.md", ROOT / f"RELEASE_NOTES_{version}.md"]
)
for marker in ["TODO", "FIXME", "not implemented yet"]:
    matches = [
        line.strip()
        for line in tracked_text.splitlines()
        if marker.lower() in line.lower()
    ]
    if matches:
        sample = "; ".join(matches[:3])
        fail(f"release marker {marker!r} remains: {sample}", failures)

generated_artifacts = sorted(ROOT.glob("*.core"))
if generated_artifacts:
    fail(
        "generated core dumps in release root: "
        + ", ".join(path.name for path in generated_artifacts),
        failures,
    )

if failures:
    sys.exit(1)

print(
    f"PASS source-integrity: {len(units)} Pascal units reachable, "
    f"version {version} consistent, release inputs present"
)
