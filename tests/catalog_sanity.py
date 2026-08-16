#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
src = root / 'src'

files = {
    'conformance': src / 'rcc_conformance_catalog.pas',
    'optimizations': src / 'rcc_optimization_catalog.pas',
    'x64': src / 'rcc_x64_patterns.pas',
    'aarch64': src / 'rcc_aarch64_patterns.pas',
    'riscv64': src / 'rcc_riscv_patterns.pas',
    'features': src / 'rcc_target_feature_catalog.pas',
    'libc': src / 'rcc_libc_catalog.pas',
    'syscalls': src / 'rcc_linux_syscalls.pas',
}

for name, path in files.items():
    if not path.is_file():
        raise SystemExit(f'FAIL catalog sanity: missing {name} catalog')

texts = {name: path.read_text() for name, path in files.items()}

if re.search(r'\.0{3,}\d+\b', texts['conformance']):
    raise SystemExit('FAIL catalog sanity: generated conformance ids came back')
if texts['conformance'].count('AddCase(Result') != 13:
    raise SystemExit('FAIL catalog sanity: conformance catalog should track 13 curated features')

for rel in sorted(set(re.findall(r"(?:tests|src)/[A-Za-z0-9_./-]+\.(?:py|pas)", texts['conformance']))):
    if not (root / rel).is_file():
        raise SystemExit(f'FAIL catalog sanity: conformance evidence does not exist: {rel}')

for unit in [
    'rcc_opt', 'rcc_ast_inline', 'rcc_ast_reachability', 'rcc_ir_opt',
    'rcc_cfg_cleanup', 'rcc_sparse_propagation', 'rcc_instcombine',
    'rcc_value_numbering', 'rcc_licm', 'rcc_inline_plan', 'rcc_liveness',
    'rcc_regalloc',
]:
    if unit not in texts['optimizations']:
        raise SystemExit(f'FAIL catalog sanity: missing real optimization unit {unit}')
    if not (src / f'{unit}.pas').is_file():
        raise SystemExit(f'FAIL catalog sanity: catalog points at missing unit {unit}')

if 'core2' in texts['features'] or 'avx512' in texts['features']:
    raise SystemExit('FAIL catalog sanity: guessed cpu feature tables came back')
if 'GetTargetOrRaise' not in texts['features'] or 'CPUFeatures' not in texts['features']:
    raise SystemExit('FAIL catalog sanity: target features are not derived from rcc_arch')

if 'TargetSyscallNumber' not in texts['syscalls']:
    raise SystemExit('FAIL catalog sanity: syscall catalog is not derived from rcc_arch')
if 'RuntimeSymbolCount' not in texts['libc']:
    raise SystemExit('FAIL catalog sanity: libc catalog is not derived from runtime surface')

for arch in ['x64', 'aarch64', 'riscv64']:
    text = texts[arch]
    if text.count('AddPattern(Result') < 20:
        raise SystemExit(f'FAIL catalog sanity: {arch} catalog has too little backend evidence')
    if "'emitted'" not in text:
        raise SystemExit(f'FAIL catalog sanity: {arch} catalog has no emitted status')

if "'mov', 'r64,imm32',\n    'sse2'" in texts['x64']:
    raise SystemExit('FAIL catalog sanity: old synthetic x64 feature rotation came back')

print('catalog sanity: ok')
