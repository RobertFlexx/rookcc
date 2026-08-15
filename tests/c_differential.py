#!/usr/bin/env python3
"""Deterministic runtime differential tests against the host C compiler."""
from __future__ import annotations
import pathlib, random, shutil, subprocess, sys, tempfile
rcc=pathlib.Path(sys.argv[1]).resolve(); cc=shutil.which("cc") or shutil.which("gcc")
if not cc: print("SKIP C differential: no system compiler"); raise SystemExit(0)

FIXED=[
("recursion", '#include <stdio.h>\nlong f(int n){return n<2?n:n*f(n-1);} int main(void){printf("%ld\\n",f(12));return 0;}'),
("bitfields", '#include <stdio.h>\nstruct B{unsigned a:3,b:5,c:9;}; int main(void){struct B x={5,17,300};printf("%u %u %u %zu\\n",x.a,x.b,x.c,sizeof x);return 0;}'),
("function-pointer", '#include <stdio.h>\nint a(int x){return x+3;} int b(int x){return x*5;} int main(void){int(*f[2])(int)={a,b};printf("%d\\n",f[0](7)+f[1](7));return 0;}'),
("aggregate", '#include <stdio.h>\nstruct P{long a;double b;}; struct P f(long x){struct P p={x*3,x/4.0};return p;} int main(void){struct P p=f(20);printf("%ld %.2f\\n",p.a,p.b);return 0;}'),
("variadic", '#include <stdio.h>\n#include <stdarg.h>\ndouble f(int n,...){va_list ap;double s=0;va_start(ap,n);while(n--)s+=va_arg(ap,double);va_end(ap);return s;}int main(void){printf("%.2f\\n",f(3,1.25,2.5,4.0));return 0;}'),
]

def generated(seed:int)->str:
 r=random.Random(seed); vals=[r.randrange(-5000,5001) for _ in range(24)]
 ops=[]
 for i in range(80):
  a=r.randrange(24); b=r.randrange(24); k=r.randrange(1,31)
  op=r.choice(["+","-","^","|","&"])
  ops.append(f"x[{a}]=(x[{a}] {op} x[{b}]) + {k}; s += (unsigned)x[{a}] * {i+1}u;")
 return '#include <stdio.h>\nint main(void){long x[24]={'+','.join(map(str,vals))+'}; unsigned long s=0;int r;for(r=0;r<7;r++){'+''.join(ops)+'}printf("%lu %ld %ld\\n",s,x[3],x[19]);return 0;}'

cases=FIXED+[(f"generated-{i:02d}",generated(0xC0DE+i)) for i in range(16)]
opts=["-O0","-O2","-Os"]
failed=0
with tempfile.TemporaryDirectory() as td:
 root=pathlib.Path(td)
 for name,src in cases:
  c=root/(name+".c"); c.write_text(src)
  for opt in opts:
   outputs=[]; detail=[]; ok=True
   for compiler,tag in [(str(rcc),"rcc"),(cc,"cc")]:
    exe=root/f"{name}-{tag}-{opt[1:]}"
    cp=subprocess.run([compiler,"-std=gnu17",opt,str(c),"-o",str(exe)],text=True,capture_output=True,timeout=45)
    if cp.returncode: ok=False; outputs.append(None); detail.append(cp.stdout+cp.stderr); continue
    rp=subprocess.run([str(exe)],text=True,capture_output=True,timeout=10)
    ok &= rp.returncode==0; outputs.append(rp.stdout); detail.append(rp.stdout+rp.stderr)
   ok &= outputs[0] is not None and outputs[0]==outputs[1]
   print(("PASS" if ok else "FAIL"),name,opt)
   if not ok: print("".join(detail)); failed+=1
sys.exit(1 if failed else 0)
