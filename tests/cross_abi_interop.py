#!/usr/bin/env python3
"""Link RCC and Clang objects in both directions for cross-target ABI checks."""
from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import tempfile


RCC = pathlib.Path(sys.argv[1]).resolve()
ROOT = pathlib.Path(__file__).resolve().parents[1]
CLANG = shutil.which("clang")
LLD = shutil.which("ld.lld")

TARGETS = {
    "aarch64-linux": {
        "triple": "aarch64-linux-gnu",
        "emulation": "aarch64elf",
        "qemu": os.environ.get("QEMU_AARCH64") or shutil.which("qemu-aarch64"),
        "start": ".text\n.globl _start\n_start:\n  bl main\n  mov x8, #93\n  svc #0\n",
    },
    "riscv64-linux": {
        "triple": "riscv64-linux-gnu",
        "emulation": "elf64lriscv",
        "qemu": os.environ.get("QEMU_RISCV64") or shutil.which("qemu-riscv64"),
        "start": ".text\n.globl _start\n_start:\n  call main\n  li a7, 93\n  ecall\n",
    },
}

CALLEE = r"""
#include <stdarg.h>
struct H4 { double a,b,c,d; };
struct Mix { int i; double d; };
struct Large { long a,b,c,d,e; };
struct Pair { long a,b; };
struct __attribute__((aligned(16))) Wide { long a,b; };
struct H4 h4(struct H4 x) { x.a += x.d; x.b *= 2.0; return x; }
struct Mix mixed(struct Mix x) { x.i += 5; x.d *= 2.0; return x; }
struct Large large(struct Large x) { x.a += x.e; x.c *= 3; return x; }
long sum_i(int n, ...) {
  va_list ap; long s=0; va_start(ap,n);
  while (n-- > 0) s += va_arg(ap,long);
  va_end(ap); return s;
}
double sum_d(int n, ...) {
  va_list ap; double s=0; va_start(ap,n);
  while (n-- > 0) s += va_arg(ap,double);
  va_end(ap); return s;
}
long sum_pair(int marker, ...) {
  va_list ap; struct Pair p; va_start(ap,marker);
  p=va_arg(ap,struct Pair); va_end(ap); return marker+p.a+p.b;
}
long sum_wide(int marker, ...) {
  va_list ap; struct Wide p; long tail; va_start(ap,marker);
  p=va_arg(ap,struct Wide); tail=va_arg(ap,long); va_end(ap);
  return marker+p.a*3+p.b*5+tail*7;
}
"""

CALLER = r"""
struct H4 { double a,b,c,d; };
struct Mix { int i; double d; };
struct Large { long a,b,c,d,e; };
struct Pair { long a,b; };
struct __attribute__((aligned(16))) Wide { long a,b; };
struct H4 h4(struct H4); struct Mix mixed(struct Mix);
struct Large large(struct Large);
long sum_i(int,...); double sum_d(int,...); long sum_pair(int,...);
long sum_wide(int,...);
int main(void) {
  struct H4 a=h4((struct H4){1,2,3,4});
  struct Mix b=mixed((struct Mix){7,2.5});
  struct Large c=large((struct Large){1,2,3,4,5});
  struct Pair p={19,23};
  struct Wide w={11,13};
  if (!(a.a==5 && a.b==4 && a.c==3 && a.d==4)) return 81;
  if (!(b.i==12 && b.d==5)) return 82;
  if (!(c.a==6 && c.b==2 && c.c==9 && c.d==4 && c.e==5)) return 83;
  if (sum_i(10,1L,2L,3L,4L,5L,6L,7L,8L,9L,10L)!=55) return 84;
  if (sum_d(4,1.25,2.5,4.0,8.25)!=16.0) return 85;
  if (sum_pair(1,p)!=43) return 86;
  if (sum_wide(1,w,17L)!=218) return 87;
  return 0;
}
"""


def run(command: list[str], timeout: int = 30) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, text=True, capture_output=True, timeout=timeout)


if not CLANG or not LLD:
    print("SKIP cross ABI interop: clang and ld.lld are required")
    raise SystemExit(0)

available = [(name, config) for name, config in TARGETS.items() if config["qemu"]]
if not available:
    print("SKIP cross ABI interop: no target emulator is available")
    raise SystemExit(0)

failures = 0
with tempfile.TemporaryDirectory(prefix="rcc-cross-abi-") as directory:
    temporary = pathlib.Path(directory)
    caller_source = temporary / "caller.c"
    callee_source = temporary / "callee.c"
    caller_source.write_text(CALLER, encoding="utf-8")
    callee_source.write_text(CALLEE, encoding="utf-8")

    for target, config in available:
        start_source = temporary / f"start-{target}.s"
        start_object = temporary / f"start-{target}.o"
        start_source.write_text(str(config["start"]), encoding="utf-8")
        assembled = run([
            CLANG, f"--target={config['triple']}", "-c", str(start_source),
            "-o", str(start_object),
        ])
        if assembled.returncode:
            print(f"FAIL {target} startup assembly\n{assembled.stdout}{assembled.stderr}")
            failures += 1
            continue

        for caller_name, callee_name in (("rcc", "clang"), ("clang", "rcc")):
            objects: list[pathlib.Path] = []
            compile_failed = False
            for role, compiler_name, source in (
                ("caller", caller_name, caller_source),
                ("callee", callee_name, callee_source),
            ):
                output = temporary / f"{target}-{caller_name}-{role}.o"
                if compiler_name == "rcc":
                    command = [
                        str(RCC), f"--target={target}", "-ffreestanding", "-std=c17",
                        "-O2", f"-I{ROOT / 'include'}", "-c", str(source), "-o", str(output),
                    ]
                else:
                    command = [
                        CLANG, f"--target={config['triple']}", "-ffreestanding",
                        "-std=c17", "-O2", "-c", str(source), "-o", str(output),
                    ]
                compiled = run(command)
                if compiled.returncode:
                    print(
                        f"FAIL {target} {compiler_name} {role} compile\n"
                        f"{compiled.stdout}{compiled.stderr}"
                    )
                    failures += 1
                    compile_failed = True
                    break
                objects.append(output)
            if compile_failed:
                continue

            executable = temporary / f"{target}-{caller_name}-to-{callee_name}"
            linked = run([
                LLD, "-m", str(config["emulation"]), "-o", str(executable),
                str(start_object), *(str(item) for item in objects),
            ])
            detail = linked.stdout + linked.stderr
            ok = linked.returncode == 0
            if ok:
                executed = run([str(config["qemu"]), str(executable)])
                detail += executed.stdout + executed.stderr
                ok = executed.returncode == 0
                if not ok:
                    detail += f"program exited with status {executed.returncode}\n"
            print(
                "PASS" if ok else "FAIL",
                target,
                f"{caller_name}-caller/{callee_name}-callee",
            )
            if not ok:
                print(detail)
                failures += 1

raise SystemExit(1 if failures else 0)
