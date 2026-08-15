#!/usr/bin/env python3
"""Release blockers that previously caused silent miscompilation."""
from __future__ import annotations
import pathlib, subprocess, sys, tempfile

rcc = pathlib.Path(sys.argv[1]).resolve()

def check(src: str, *args: str) -> subprocess.CompletedProcess[str]:
    with tempfile.TemporaryDirectory() as td:
        p = pathlib.Path(td) / "t.c"
        p.write_text(src)
        return subprocess.run([str(rcc), *args, "--check", str(p)], text=True,
                              capture_output=True, timeout=20)

def compile_run(src: str, *args: str) -> tuple[subprocess.CompletedProcess[str], subprocess.CompletedProcess[str] | None]:
    with tempfile.TemporaryDirectory() as td:
        root = pathlib.Path(td); c = root / "t.c"; exe = root / "t"
        c.write_text(src)
        cp = subprocess.run([str(rcc), *args, str(c), "-o", str(exe)], text=True,
                            capture_output=True, timeout=30)
        if cp.returncode:
            return cp, None
        rp = subprocess.run([str(exe)], text=True, capture_output=True, timeout=10)
        return cp, rp

failed = 0

def result(name: str, passed: bool, detail: str = "") -> None:
    global failed
    print(("PASS" if passed else "FAIL"), name)
    if not passed:
        failed += 1
        if detail: print(detail)

cp = check("int f(void){x:; x:; return 0;}", "-std=gnu17")
result("duplicate-label", cp.returncode != 0 and "duplicate label" in (cp.stdout+cp.stderr).lower(), cp.stdout+cp.stderr)

src = r'''
#include <stddef.h>
#include <stdio.h>
struct __attribute__((packed)) P { char c; int i; };
struct __attribute__((packed, aligned(8))) PA { char c; int i; };
struct M { char c; int i __attribute__((aligned(8))); };
int main(void) {
  printf("%zu %zu %zu %zu %zu\n", sizeof(struct P), offsetof(struct P,i),
         sizeof(struct PA), _Alignof(struct PA), offsetof(struct M,i));
  return 0;
}
'''
cp, rp = compile_run(src, "-std=gnu17", "-O2")
result("packed-aligned-layout", cp.returncode == 0 and rp is not None and rp.returncode == 0 and rp.stdout.strip() == "5 1 8 8 8",
       cp.stdout+cp.stderr+("" if rp is None else rp.stdout+rp.stderr))

src = r'''
#include <stdio.h>
int main(void) {
  int a[] = {[4] = 11, [1] = 7, 3};
  printf("%zu %d %d %d %d\n", sizeof(a) / sizeof(a[0]), a[0], a[1], a[2], a[4]);
  return 0;
}
'''
cp, rp = compile_run(src, "-std=c99", "-O2")
result("array-designators", cp.returncode == 0 and rp is not None and
       rp.returncode == 0 and rp.stdout.strip() == "5 0 7 3 11",
       cp.stdout+cp.stderr+("" if rp is None else rp.stdout+rp.stderr))


src = r'''
#include <stdio.h>
struct P { int x; int y; };
static struct P make(void) { return (struct P){40, 2}; }
int main(void) {
  int *scalar = &(int){41};
  struct P *p = &(struct P){20, 22};
  struct P q = make();
  *scalar += 1;
  printf("%d %d %d\n", *scalar, p->x + p->y, q.x + q.y);
  return 0;
}
'''
cp, rp = compile_run(src, "-std=c99", "-O2")
result("compound-literal-storage", cp.returncode == 0 and rp is not None and
       rp.returncode == 0 and rp.stdout.strip() == "42 42 42",
       cp.stdout+cp.stderr+("" if rp is None else rp.stdout+rp.stderr))

cp = check("int main(void){int x __attribute__((unused));return 0;}",
           "-std=gnu17", "-Wall", "-Werror")
result("implemented-unused-attribute", cp.returncode == 0, cp.stdout+cp.stderr)

cp = check("typedef int v4si __attribute__((vector_size(16))); int main(void){return 0;}", "-std=gnu17")
result("unsupported-codegen-attribute-fails", cp.returncode != 0 and "not implemented" in (cp.stdout+cp.stderr).lower(), cp.stdout+cp.stderr)

cp = check("int f(void){int unused; return 0;}", "-Wall", "-Werror")
result("warnings-as-errors", cp.returncode != 0 and "unused variable" in (cp.stdout+cp.stderr).lower(), cp.stdout+cp.stderr)


cp = check("int f(void){int unused; return 0;}", "-Wall", "-Werror", "-Wno-unused-variable")
result("selective-warning-disable", cp.returncode == 0, cp.stdout+cp.stderr)

cp = check("int f(void){return 0;}", "-std=gnu17", "-ffunction-sections")
result("unsupported-codegen-option-fails", cp.returncode != 0 and
       "not implemented" in (cp.stdout+cp.stderr).lower(), cp.stdout+cp.stderr)

cp = check("int f(void) __attribute__((aligned(32))); int main(void){return 0;}", "-std=gnu17")
result("unsupported-function-alignment-fails", cp.returncode != 0 and
       "not implemented" in (cp.stdout+cp.stderr).lower(), cp.stdout+cp.stderr)

cp = check("int f(void) __attribute__((ms_abi)); int f(void){return 0;}", "-std=gnu17")
result("unsupported-abi-attribute-fails", cp.returncode != 0 and
       "not implemented" in (cp.stdout+cp.stderr).lower(), cp.stdout+cp.stderr)

sys.exit(1 if failed else 0)
