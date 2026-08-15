#!/usr/bin/env python3
"""Targeted conversion and promotion differential suite."""
from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys
import tempfile

rcc = pathlib.Path(sys.argv[1]).resolve()
cc = shutil.which("cc") or shutil.which("gcc")
if not cc:
    print("SKIP semantic conversions: no system C compiler")
    raise SystemExit(0)

PROGRAMS = {
    "promotions": r'''#include <stdio.h>
int main(void){signed char a=-3; unsigned char b=250; short c=-1000; unsigned short d=65000;
printf("%d %d %d %u %d\n",a+1,b+10,c+d,(unsigned)(a*b),(a<b));return 0;}''',
    "usual-arithmetic": r'''#include <stdio.h>
int main(void){int a=-1; unsigned b=1; long c=-2; unsigned long d=3;
printf("%d %lu %d %lu\n",a<b,c+d,c<d,(unsigned long)(a+d));return 0;}''',
    "float-casts": r'''#include <stdio.h>
int main(void){double x=3.75; float y=2.5f; float z=-2.5f; printf("%d %u %d %.2f\n",(int)x,(unsigned)y,(int)z,x+(double)z);return 0;}''',
    "float-bool": r'''#include <stdio.h>
int main(void){double a=0.5,b=-0.25,c=0.0;printf("%d %d %d\n",(_Bool)a,(_Bool)b,(_Bool)c);return 0;}''',
    "uint-float-boundaries": r'''#include <stdio.h>
int main(void){unsigned int u=(unsigned int)4294967295.0;unsigned long long x=9223372036854775808ULL;double d=(double)x;unsigned long long y=(unsigned long long)d;printf("%u %.0f %llu\n",u,d,y);return 0;}''',
    "conditional": r'''#include <stdio.h>
int main(void){int a=-5; unsigned b=7; printf("%u %u %d\n",1?a:b,0?a:b,(int)(1?3.5:2));return 0;}''',
    "pointer": r'''#include <stdio.h>
int main(void){int a[4]={1,2,3,4}; int *p=a; void *v=p; printf("%td %d %d\n",(p+3)-p,*(int*)v,p!=0);return 0;}''',
    "void-pointer-return": r'''#include <stdio.h>
static inline void *offset(void *p){return (char *)p+1;}
int main(void){char value[2]={41,42};char *p=(char *)offset(value);printf("%d\n",*p);return 0;}''',
}

failed = 0
with tempfile.TemporaryDirectory() as td:
    root = pathlib.Path(td)
    for name, src in PROGRAMS.items():
        c = root / (name + ".c")
        c.write_text(src)
        outputs: list[str | None] = []
        details: list[str] = []
        ok = True
        for compiler, tag in [(str(rcc), "rcc"), (cc, "cc")]:
            exe = root / (name + "-" + tag)
            cp = subprocess.run(
                [compiler, "-std=c17", "-O2", str(c), "-o", str(exe)],
                text=True,
                capture_output=True,
                timeout=30,
            )
            if cp.returncode:
                ok = False
                details.append(cp.stdout + cp.stderr)
                outputs.append(None)
                continue
            rp = subprocess.run([str(exe)], text=True, capture_output=True, timeout=10)
            ok &= rp.returncode == 0
            details.append(rp.stdout + rp.stderr)
            outputs.append(rp.stdout)
        ok &= outputs[0] is not None and outputs[0] == outputs[1]
        print(("PASS" if ok else "FAIL"), name)
        if not ok:
            print("".join(details))
            failed += 1

sys.exit(1 if failed else 0)
