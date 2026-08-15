#!/usr/bin/env python3
"""ELF and SysV ABI interoperability in both compiler directions."""
from __future__ import annotations
import pathlib, shutil, subprocess, sys, tempfile
rcc=pathlib.Path(sys.argv[1]).resolve(); cc=shutil.which("cc") or shutil.which("gcc")
if not cc: print("SKIP cross differential: no system compiler"); raise SystemExit(0)

CASES={
"integer-aggregate":(
 'struct P{long a,b;}; struct P make(long x){struct P p={x,x+9};return p;}',
 '#include <stdio.h>\nstruct P{long a,b;};struct P make(long);int main(void){struct P p=make(30);printf("%ld %ld\\n",p.a,p.b);return 0;}',"30 39\n"),
"mixed-aggregate":(
 'struct M{double x;long y;};struct M make(double x,long y){struct M m={x+0.5,y+4};return m;}',
 '#include <stdio.h>\nstruct M{double x;long y;};struct M make(double,long);int main(void){struct M m=make(2.0,8);printf("%.1f %ld\\n",m.x,m.y);return 0;}',"2.5 12\n"),
"packed-memory-class":(
 'struct __attribute__((packed)) P{char c;long x;}; long take(struct P p){return p.c+p.x;}',
 '#include <stdio.h>\nstruct __attribute__((packed)) P{char c;long x;};long take(struct P);int main(void){struct P p={3,40};printf("%ld %zu\\n",take(p),sizeof p);return 0;}',"43 9\n"),
"variadic-fp":(
 '#include <stdarg.h>\ndouble sum(int n,...){va_list ap;double s=0;va_start(ap,n);while(n--)s+=va_arg(ap,double);va_end(ap);return s;}',
 '#include <stdio.h>\ndouble sum(int,...);int main(void){printf("%.2f\\n",sum(4,1.0,2.25,3.5,4.75));return 0;}',"11.50\n"),
}
failed=0
with tempfile.TemporaryDirectory() as td:
 root=pathlib.Path(td)
 for name,(provider,caller,expected) in CASES.items():
  p=root/(name+"-provider.c"); c=root/(name+"-caller.c"); p.write_text(provider); c.write_text(caller)
  for pc,ccaller,tag in [(str(rcc),cc,"rcc-to-cc"),(cc,str(rcc),"cc-to-rcc")]:
   po=root/(name+"-p-"+tag+".o"); co=root/(name+"-c-"+tag+".o"); exe=root/(name+"-"+tag)
   commands=[[pc,"-std=gnu17","-O2","-c",str(p),"-o",str(po)],
             [ccaller,"-std=gnu17","-O2","-c",str(c),"-o",str(co)],
             [str(rcc),str(po),str(co),"-o",str(exe)]]
   ok=True; detail=""
   for cmd in commands:
    cp=subprocess.run(cmd,text=True,capture_output=True,timeout=45); detail+=cp.stdout+cp.stderr
    if cp.returncode: ok=False; break
   if ok:
    rp=subprocess.run([str(exe)],text=True,capture_output=True,timeout=10); detail+=rp.stdout+rp.stderr
    ok=rp.returncode==0 and rp.stdout==expected
   print(("PASS" if ok else "FAIL"),name,tag)
   if not ok: print(detail); failed+=1
sys.exit(1 if failed else 0)
