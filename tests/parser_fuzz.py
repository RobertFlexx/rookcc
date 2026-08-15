#!/usr/bin/env python3
"""Deterministic malformed-input crash/hang gate."""
from __future__ import annotations
import pathlib, random, subprocess, sys, tempfile
rcc=pathlib.Path(sys.argv[1]).resolve(); rnd=random.Random(0x52434332)
tokens=['int','long','unsigned','struct','if','else','for','while','return','(',')','{','}','[',']',';',',','+','-','*','/','=','==','&&','||','x','y','42','"s"','__attribute__','packed']
failed=0
with tempfile.TemporaryDirectory() as td:
 root=pathlib.Path(td)
 for i in range(400):
  n=rnd.randrange(1,90); src=' '.join(rnd.choice(tokens) for _ in range(n))
  p=root/f'fuzz-{i}.c'; p.write_text(src)
  try:
   cp=subprocess.run([str(rcc),'--check',str(p)],text=True,capture_output=True,timeout=3)
   ok=cp.returncode in (0,1)
  except subprocess.TimeoutExpired:
   ok=False; cp=None
  if not ok:
   print('FAIL',i,'hang/crash',src[:160]); failed+=1
   if failed>=10: break
print(('PASS' if failed==0 else 'FAIL'),f'parser-fuzz cases={400 if failed==0 else i+1}')
sys.exit(1 if failed else 0)
