#!/usr/bin/env python3
from __future__ import annotations
import pathlib, subprocess, sys, tempfile
rcc = pathlib.Path(sys.argv[1]).resolve()

CASES = [
    ("c90-line-comment", "c90", "int main(void){ // nope\n return 0; }", False),
    ("c90-for-declaration", "c90", "int main(void){for(int i=0;i<1;i++){}return 0;}", False),
    ("c90-inline", "c90", "inline int f(void){return 1;} int main(void){return f()-1;}", False),
    ("c90-bool", "c90", "int main(void){_Bool x=0;return x;}", False),
    ("c99-core", "c99", "inline int f(int * restrict p){for(int i=0;i<1;i++)*p+=i;return *p;} int main(void){int x=0;return f(&x);}", True),
    ("c99-designator", "c99", "struct S{int a,b;}; int main(void){struct S s={.b=2,.a=1};return s.a+s.b-3;}", True),
    ("c99-static-assert", "c99", "_Static_assert(1,\"ok\"); int main(void){return 0;}", False),
    ("c11-static-assert", "c11", "_Static_assert(sizeof(int)==4,\"int\"); int main(void){return 0;}", True),
    ("c11-alignas", "c11", "_Alignas(16) int x; int main(void){return _Alignof(x)!=16;}", True),
    ("c17-reserved-gnu-attribute", "c17", "struct __attribute__((aligned(16))) S{long x,y;}; int main(void){return _Alignof(struct S)!=16;}", True),
    ("c17-nullptr", "c17", "int main(void){void *p=nullptr;return p!=0;}", False),
    ("c23-nullptr", "c23", "int main(void){void *p=nullptr;return p!=0;}", True),
    ("c17-binary", "c17", "int main(void){return 0b1010-10;}", False),
    ("c23-binary-separator", "c23", "int main(void){return 0b1010'0001-161;}", True),
    ("gnu99-binary-extension", "gnu99", "int main(void){return 0b1010-10;}", True),
]

failed=0
with tempfile.TemporaryDirectory() as td:
    root=pathlib.Path(td)
    for name,std,src,should_pass in CASES:
        c=root/f"{name}.c"; c.write_text(src)
        cp=subprocess.run([str(rcc),f"-std={std}","--check",str(c)],text=True,capture_output=True,timeout=20)
        ok=(cp.returncode==0)==should_pass
        print(("PASS" if ok else "FAIL"), name)
        if not ok:
            print(cp.stdout+cp.stderr); failed+=1
sys.exit(1 if failed else 0)
