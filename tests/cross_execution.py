#!/usr/bin/env python3
"""Execute freestanding AArch64 and RISC-V64 output under QEMU."""
from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import tempfile


RCC = pathlib.Path(sys.argv[1]).resolve()
PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
REFERENCE = shutil.which("cc") or shutil.which("gcc") or shutil.which("clang")
EMULATORS = {
    "aarch64-linux": os.environ.get("QEMU_AARCH64") or shutil.which("qemu-aarch64"),
    "riscv64-linux": os.environ.get("QEMU_RISCV64") or shutil.which("qemu-riscv64"),
}
OPTIMIZATIONS = ("-O0", "-O2", "-Os")

CASES = {
    "arithmetic": r"""
static unsigned long mix(unsigned long x) {
  int i;
  for (i = 0; i < 31; ++i) x = (x * 33u) ^ (x >> 7) ^ (unsigned long)i;
  return x;
}
int main(void) { return (int)(mix(1234567u) & 255u); }
""",
    "control-flow": r"""
int main(void) {
  int i = 0, sum = 0;
again:
  if (i == 17) goto done;
  switch (i % 4) {
    case 0: sum += i; break;
    case 1: sum -= 3; break;
    case 2: sum ^= i * 5; break;
    default: sum += 7;
  }
  ++i;
  goto again;
done:
  return sum & 255;
}
""",
    "memory-and-structs": r"""
struct Pair { long left, right; };
static long fold(struct Pair *pairs, int count) {
  long result = 0;
  int i;
  for (i = 0; i < count; ++i) result += pairs[i].left * 3 - pairs[i].right;
  return result;
}
int main(void) {
  struct Pair values[4] = {{3, 1}, {7, 2}, {11, 5}, {19, 8}};
  return (int)(fold(values, 4) & 255);
}
""",
    "wide-call": r"""
static long sum10(long a, long b, long c, long d, long e,
                  long f, long g, long h, long i, long j) {
  return a + b * 2 + c * 3 + d * 4 + e * 5 +
         f * 6 + g * 7 + h * 8 + i * 9 + j * 10;
}
int main(void) { return (int)(sum10(1,2,3,4,5,6,7,8,9,10) & 255); }
""",
    "function-pointer": r"""
static long add(long x) { return x + 17; }
static long mul(long x) { return x * 9; }
int main(void) {
  long (*table[2])(long) = {add, mul};
  return (int)((table[0](5) + table[1](7)) & 255);
}
""",
    "aggregate-return": r"""
struct Pair { long left, right; };
static struct Pair make(long x) {
  struct Pair result = {x * 3, x + 11};
  return result;
}
int main(void) {
  struct Pair value = make(13);
  return (int)((value.left + value.right) & 255);
}
""",
    "compound-literal": r"""
struct Pair { long left, right; };
static long total(const struct Pair *p) { return p->left + p->right; }
int main(void) { return (int)(total(&(struct Pair){19, 23}) & 255); }
""",
    "aggregate-assignment": r"""
struct Pair { long left, right; };
static struct Pair make(long x) { struct Pair p = {x + 3, x * 4}; return p; }
int main(void) {
  struct Pair a = {1, 2}, b = {3, 4};
  a = b;
  b = make(9);
  return (int)((a.left + a.right + b.left + b.right) & 255);
}
""",
    "bit-fields": r"""
struct Bits { unsigned a:3, b:5; signed c:7; unsigned d:9; };
int main(void) {
  struct Bits bits = {5, 19, -27, 300};
  bits.a += 2;
  bits.b ^= 7;
  bits.c--;
  return (int)((bits.a + bits.b + bits.c + bits.d) & 255);
}
""",
    "static-bit-fields": r"""
struct Bits { unsigned a:4, b:9; signed c:11; };
static struct Bits bits = {13, 377, -513};
int main(void) { return (int)((bits.a + bits.b + bits.c) & 255); }
""",
    "union": r"""
union Word { unsigned long whole; unsigned char bytes[8]; };
int main(void) {
  union Word value;
  value.whole = 0x1122334455667788ul;
  return (int)((value.bytes[0] + value.bytes[3] + value.bytes[7]) & 255);
}
""",
    "static-storage": r"""
static unsigned long seed = 17;
static unsigned long next(void) { static unsigned long calls = 3; return (seed += 5) * calls++; }
int main(void) { return (int)((next() + next() + next()) & 255); }
""",
    "multidimensional-array": r"""
int main(void) {
  int values[3][4] = {{1,2,3,4},{5,6,7,8},{9,10,11,12}};
  int i, j, sum = 0;
  for (i = 0; i < 3; ++i) for (j = 0; j < 4; ++j) sum += values[i][j] * (i + 1);
  return sum & 255;
}
""",
    "recursion": r"""
static unsigned long fib(unsigned n) { return n < 2 ? n : fib(n-1) + fib(n-2); }
int main(void) { return (int)(fib(12) & 255); }
""",
    "floating-point": r"""
static double polynomial(double x) {
  return ((x * 1.5 - 2.25) * x + 4.0) / 2.0;
}
int main(void) {
  float f = 3.25f;
  double d = polynomial(2.0);
  if (d != 2.75) return 91;
  if ((int)(f * 4.0f) != 13) return 92;
  if (!(-0.0 == 0.0) || (0.0 / 0.0) == (0.0 / 0.0)) return 93;
  return 0;
}
""",
    "floating-calls": r"""
static double blend(long a, double b, float c, long d, double e) {
  return (double)a + b * 2.0 + (double)c * 3.0 + (double)d + e;
}
static double invoke(double (*fn)(long,double,float,long,double)) {
  return fn(3, 1.25, 2.0f, 7, 0.5);
}
int main(void) { return invoke(blend) == 19.0 ? 0 : 94; }
""",
    "aggregate-abi": r"""
struct H4 { double a,b,c,d; };
struct F2 { float a,b; };
struct Mix { int i; double d; };
struct Large { long a,b,c,d,e; };
static struct H4 h4(struct H4 x) { x.a += x.d; x.b *= 2.0; return x; }
static struct F2 f2(struct F2 x) { x.a += 1.0f; x.b *= 3.0f; return x; }
static struct Mix mixed(struct Mix x) { x.i += 5; x.d *= 2.0; return x; }
static struct Large large(struct Large x) { x.a += x.e; x.c *= 3; return x; }
int main(void) {
  struct H4 a=h4((struct H4){1,2,3,4});
  struct F2 b=f2((struct F2){2,3});
  struct Mix c=mixed((struct Mix){7,2.5});
  struct Large d=large((struct Large){1,2,3,4,5});
  return a.a==5 && a.b==4 && a.c==3 && a.d==4 && b.a==3 && b.b==9 &&
         c.i==12 && c.d==5 && d.a==6 && d.b==2 && d.c==9 && d.d==4 && d.e==5
         ? 0 : 95;
}
""",
    "split-aggregate-argument": r"""
struct Pair { long a, b; };
static long consume(long a, long b, long c, long d, long e, long f, long g,
                    struct Pair pair, long tail) {
  return a+b+c+d+e+f+g + pair.a*3 + pair.b*5 + tail*7;
}
int main(void) {
  struct Pair pair = {11, 13};
  return consume(1,2,3,4,5,6,7,pair,17) == 245 ? 0 : 96;
}
""",
    "variadic-abi": r"""
#include <stdarg.h>
struct Pair { long a, b; };
static long integer_sum(int count, ...) {
  va_list ap; long result = 0;
  va_start(ap, count);
  while (count-- > 0) result += va_arg(ap, long);
  va_end(ap); return result;
}
static double floating_sum(int count, ...) {
  va_list ap; double result = 0.0;
  va_start(ap, count);
  while (count-- > 0) result += va_arg(ap, double);
  va_end(ap); return result;
}
static long pair_sum(int marker, ...) {
  va_list ap, copy; struct Pair value;
  va_start(ap, marker); va_copy(copy, ap);
  value = va_arg(copy, struct Pair);
  va_end(copy); va_end(ap);
  return marker + value.a + value.b;
}
struct __attribute__((aligned(16))) Wide { long a, b; };
static long aligned_sum(int marker, ...) {
  va_list ap; struct Wide value; long tail;
  va_start(ap, marker);
  value = va_arg(ap, struct Wide); tail = va_arg(ap, long);
  va_end(ap); return marker + value.a * 3 + value.b * 5 + tail * 7;
}
int main(void) {
  struct Pair pair = {19, 23};
  struct Wide wide = {11, 13};
  if (integer_sum(10,1L,2L,3L,4L,5L,6L,7L,8L,9L,10L) != 55) return 97;
  if (floating_sum(4,1.25,2.5,4.0,8.25) != 16.0) return 98;
  if (pair_sum(1,pair) != 43) return 99;
  return aligned_sum(1,wide,17L) == 218 ? 0 : 100;
}
""",
}


def run(command: list[str], timeout: int = 30) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, text=True, capture_output=True, timeout=timeout)


if not REFERENCE:
    print("SKIP cross execution: no host reference compiler")
    raise SystemExit(0)
if not any(EMULATORS.values()):
    print("SKIP cross execution: qemu-aarch64 and qemu-riscv64 are unavailable")
    raise SystemExit(0)

failures = 0
with tempfile.TemporaryDirectory(prefix="rcc-cross-execution-") as temporary:
    root = pathlib.Path(temporary)
    for name, source in CASES.items():
        source_path = root / f"{name}.c"
        source_path.write_text(source, encoding="utf-8")
        reference = root / f"{name}-reference"
        compiled = run([REFERENCE, "-std=c17", "-O2", str(source_path), "-o", str(reference)])
        if compiled.returncode:
            print(f"FAIL {name} reference compile\n{compiled.stdout}{compiled.stderr}")
            failures += 1
            continue
        expected = run([str(reference)]).returncode
        for target, emulator in EMULATORS.items():
            if not emulator:
                continue
            for optimization in OPTIMIZATIONS:
                executable = root / f"{name}-{target}-{optimization[1:]}"
                compiled = run([
                    str(RCC), f"--target={target}", "-ffreestanding", "-std=c17",
                    optimization, f"-I{PROJECT_ROOT / 'include'}",
                    str(source_path), "-o", str(executable),
                ])
                detail = compiled.stdout + compiled.stderr
                ok = compiled.returncode == 0
                if ok:
                    executed = run([emulator, str(executable)])
                    detail += executed.stdout + executed.stderr
                    ok = executed.returncode == expected
                    if not ok:
                        detail += (
                            f"expected exit status {expected}, "
                            f"got {executed.returncode}\n"
                        )
                print(("PASS" if ok else "FAIL"), name, target, optimization)
                if not ok:
                    print(detail)
                    failures += 1

raise SystemExit(1 if failures else 0)
