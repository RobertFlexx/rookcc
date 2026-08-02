unit rcc_optimization_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TOptimizationRecipe = record
    Name: string;
    Phase: string;
    Pattern: string;
    Replacement: string;
    Target: string;
    SafetyRule: string;
    Profitability: LongInt;
  end;
  TOptimizationRecipeArray = array of TOptimizationRecipe;

function BuildOptimizationRecipeCatalog: TOptimizationRecipeArray;
function FindOptimizationRecipe(const ACatalog: TOptimizationRecipeArray;
  const AName: string; out ARecipe: TOptimizationRecipe): Boolean;
function OptimizationRecipeSummary(const ACatalog: TOptimizationRecipeArray): string;

implementation

procedure AddRecipe(var AValues: TOptimizationRecipeArray;
  const AName, APhase, APattern, AReplacement, ATarget, ASafety: string;
  AProfitability: LongInt);
var N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Name := AName;
  AValues[N].Phase := APhase;
  AValues[N].Pattern := APattern;
  AValues[N].Replacement := AReplacement;
  AValues[N].Target := ATarget;
  AValues[N].SafetyRule := ASafety;
  AValues[N].Profitability := AProfitability;
end;

function BuildOptimizationRecipeCatalog: TOptimizationRecipeArray;
begin
  Result := nil;
  AddRecipe(Result, 'canonicalize.add.i8.0000', 'canonicalize',
    'add:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.add.i8.0001', 'sccp',
    'add:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.add.i8.0002', 'gvn',
    'add:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.add.i8.0003', 'loop',
    'add:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.add.i8.0004', 'machine-combine',
    'add:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.sub.i8.0005', 'canonicalize',
    'sub:i8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.sub.i8.0006', 'sccp',
    'sub:i8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.sub.i8.0007', 'gvn',
    'sub:i8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.sub.i8.0008', 'loop',
    'sub:i8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.sub.i8.0009', 'machine-combine',
    'sub:i8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.mul.i8.0010', 'canonicalize',
    'mul:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.mul.i8.0011', 'sccp',
    'mul:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.mul.i8.0012', 'gvn',
    'mul:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.mul.i8.0013', 'loop',
    'mul:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.mul.i8.0014', 'machine-combine',
    'mul:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.sdiv.i8.0015', 'canonicalize',
    'sdiv:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.sdiv.i8.0016', 'sccp',
    'sdiv:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.sdiv.i8.0017', 'gvn',
    'sdiv:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.sdiv.i8.0018', 'loop',
    'sdiv:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.sdiv.i8.0019', 'machine-combine',
    'sdiv:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.udiv.i8.0020', 'canonicalize',
    'udiv:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.udiv.i8.0021', 'sccp',
    'udiv:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.udiv.i8.0022', 'gvn',
    'udiv:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.udiv.i8.0023', 'loop',
    'udiv:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.udiv.i8.0024', 'machine-combine',
    'udiv:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.srem.i8.0025', 'canonicalize',
    'srem:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.srem.i8.0026', 'sccp',
    'srem:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.srem.i8.0027', 'gvn',
    'srem:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.srem.i8.0028', 'loop',
    'srem:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.srem.i8.0029', 'machine-combine',
    'srem:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.urem.i8.0030', 'canonicalize',
    'urem:i8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.urem.i8.0031', 'sccp',
    'urem:i8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.urem.i8.0032', 'gvn',
    'urem:i8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.urem.i8.0033', 'loop',
    'urem:i8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.urem.i8.0034', 'machine-combine',
    'urem:i8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.shl.i8.0035', 'canonicalize',
    'shl:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.shl.i8.0036', 'sccp',
    'shl:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.shl.i8.0037', 'gvn',
    'shl:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.shl.i8.0038', 'loop',
    'shl:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.shl.i8.0039', 'machine-combine',
    'shl:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.ashr.i8.0040', 'canonicalize',
    'ashr:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.ashr.i8.0041', 'sccp',
    'ashr:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.ashr.i8.0042', 'gvn',
    'ashr:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.ashr.i8.0043', 'loop',
    'ashr:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.ashr.i8.0044', 'machine-combine',
    'ashr:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.lshr.i8.0045', 'canonicalize',
    'lshr:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.lshr.i8.0046', 'sccp',
    'lshr:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.lshr.i8.0047', 'gvn',
    'lshr:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.lshr.i8.0048', 'loop',
    'lshr:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.lshr.i8.0049', 'machine-combine',
    'lshr:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.and.i8.0050', 'canonicalize',
    'and:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 3);
  AddRecipe(Result, 'sccp.and.i8.0051', 'sccp',
    'and:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.and.i8.0052', 'gvn',
    'and:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 5);
  AddRecipe(Result, 'loop.and.i8.0053', 'loop',
    'and:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.and.i8.0054', 'machine-combine',
    'and:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.or.i8.0055', 'canonicalize',
    'or:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 8);
  AddRecipe(Result, 'sccp.or.i8.0056', 'sccp',
    'or:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.or.i8.0057', 'gvn',
    'or:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 10);
  AddRecipe(Result, 'loop.or.i8.0058', 'loop',
    'or:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.or.i8.0059', 'machine-combine',
    'or:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.xor.i8.0060', 'canonicalize',
    'xor:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.xor.i8.0061', 'sccp',
    'xor:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.xor.i8.0062', 'gvn',
    'xor:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.xor.i8.0063', 'loop',
    'xor:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.xor.i8.0064', 'machine-combine',
    'xor:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.icmp.eq.i8.0065', 'canonicalize',
    'icmp.eq:i8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.icmp.eq.i8.0066', 'sccp',
    'icmp.eq:i8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.icmp.eq.i8.0067', 'gvn',
    'icmp.eq:i8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.icmp.eq.i8.0068', 'loop',
    'icmp.eq:i8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.icmp.eq.i8.0069', 'machine-combine',
    'icmp.eq:i8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.icmp.ne.i8.0070', 'canonicalize',
    'icmp.ne:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.icmp.ne.i8.0071', 'sccp',
    'icmp.ne:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.icmp.ne.i8.0072', 'gvn',
    'icmp.ne:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.icmp.ne.i8.0073', 'loop',
    'icmp.ne:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.icmp.ne.i8.0074', 'machine-combine',
    'icmp.ne:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.icmp.slt.i8.0075', 'canonicalize',
    'icmp.slt:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.icmp.slt.i8.0076', 'sccp',
    'icmp.slt:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.icmp.slt.i8.0077', 'gvn',
    'icmp.slt:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.icmp.slt.i8.0078', 'loop',
    'icmp.slt:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.icmp.slt.i8.0079', 'machine-combine',
    'icmp.slt:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.icmp.sle.i8.0080', 'canonicalize',
    'icmp.sle:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.icmp.sle.i8.0081', 'sccp',
    'icmp.sle:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.icmp.sle.i8.0082', 'gvn',
    'icmp.sle:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.icmp.sle.i8.0083', 'loop',
    'icmp.sle:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.icmp.sle.i8.0084', 'machine-combine',
    'icmp.sle:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.icmp.sgt.i8.0085', 'canonicalize',
    'icmp.sgt:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.icmp.sgt.i8.0086', 'sccp',
    'icmp.sgt:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.icmp.sgt.i8.0087', 'gvn',
    'icmp.sgt:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.icmp.sgt.i8.0088', 'loop',
    'icmp.sgt:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.icmp.sgt.i8.0089', 'machine-combine',
    'icmp.sgt:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.icmp.sge.i8.0090', 'canonicalize',
    'icmp.sge:i8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.icmp.sge.i8.0091', 'sccp',
    'icmp.sge:i8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.icmp.sge.i8.0092', 'gvn',
    'icmp.sge:i8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.icmp.sge.i8.0093', 'loop',
    'icmp.sge:i8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.icmp.sge.i8.0094', 'machine-combine',
    'icmp.sge:i8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.fadd.i8.0095', 'canonicalize',
    'fadd:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.fadd.i8.0096', 'sccp',
    'fadd:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.fadd.i8.0097', 'gvn',
    'fadd:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.fadd.i8.0098', 'loop',
    'fadd:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.fadd.i8.0099', 'machine-combine',
    'fadd:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.fsub.i8.0100', 'canonicalize',
    'fsub:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.fsub.i8.0101', 'sccp',
    'fsub:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.fsub.i8.0102', 'gvn',
    'fsub:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.fsub.i8.0103', 'loop',
    'fsub:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.fsub.i8.0104', 'machine-combine',
    'fsub:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.fmul.i8.0105', 'canonicalize',
    'fmul:i8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.fmul.i8.0106', 'sccp',
    'fmul:i8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.fmul.i8.0107', 'gvn',
    'fmul:i8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.fmul.i8.0108', 'loop',
    'fmul:i8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.fmul.i8.0109', 'machine-combine',
    'fmul:i8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.fdiv.i8.0110', 'canonicalize',
    'fdiv:i8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.fdiv.i8.0111', 'sccp',
    'fdiv:i8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.fdiv.i8.0112', 'gvn',
    'fdiv:i8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.fdiv.i8.0113', 'loop',
    'fdiv:i8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.fdiv.i8.0114', 'machine-combine',
    'fdiv:i8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.load.i8.0115', 'canonicalize',
    'load:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.load.i8.0116', 'sccp',
    'load:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.load.i8.0117', 'gvn',
    'load:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.load.i8.0118', 'loop',
    'load:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.load.i8.0119', 'machine-combine',
    'load:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.store.i8.0120', 'canonicalize',
    'store:i8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 1);
  AddRecipe(Result, 'sccp.store.i8.0121', 'sccp',
    'store:i8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.store.i8.0122', 'gvn',
    'store:i8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 3);
  AddRecipe(Result, 'loop.store.i8.0123', 'loop',
    'store:i8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.store.i8.0124', 'machine-combine',
    'store:i8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.gep.i8.0125', 'canonicalize',
    'gep:i8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.gep.i8.0126', 'sccp',
    'gep:i8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.gep.i8.0127', 'gvn',
    'gep:i8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.gep.i8.0128', 'loop',
    'gep:i8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.gep.i8.0129', 'machine-combine',
    'gep:i8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.select.i8.0130', 'canonicalize',
    'select:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 11);
  AddRecipe(Result, 'sccp.select.i8.0131', 'sccp',
    'select:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.select.i8.0132', 'gvn',
    'select:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 1);
  AddRecipe(Result, 'loop.select.i8.0133', 'loop',
    'select:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.select.i8.0134', 'machine-combine',
    'select:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.phi.i8.0135', 'canonicalize',
    'phi:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.phi.i8.0136', 'sccp',
    'phi:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.phi.i8.0137', 'gvn',
    'phi:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.phi.i8.0138', 'loop',
    'phi:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.phi.i8.0139', 'machine-combine',
    'phi:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.call.i8.0140', 'canonicalize',
    'call:i8', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.call.i8.0141', 'sccp',
    'call:i8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.call.i8.0142', 'gvn',
    'call:i8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.call.i8.0143', 'loop',
    'call:i8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.call.i8.0144', 'machine-combine',
    'call:i8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.add.u8.0145', 'canonicalize',
    'add:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.add.u8.0146', 'sccp',
    'add:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.add.u8.0147', 'gvn',
    'add:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.add.u8.0148', 'loop',
    'add:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.add.u8.0149', 'machine-combine',
    'add:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.sub.u8.0150', 'canonicalize',
    'sub:u8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.sub.u8.0151', 'sccp',
    'sub:u8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.sub.u8.0152', 'gvn',
    'sub:u8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.sub.u8.0153', 'loop',
    'sub:u8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.sub.u8.0154', 'machine-combine',
    'sub:u8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.mul.u8.0155', 'canonicalize',
    'mul:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.mul.u8.0156', 'sccp',
    'mul:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.mul.u8.0157', 'gvn',
    'mul:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.mul.u8.0158', 'loop',
    'mul:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.mul.u8.0159', 'machine-combine',
    'mul:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.sdiv.u8.0160', 'canonicalize',
    'sdiv:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.sdiv.u8.0161', 'sccp',
    'sdiv:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.sdiv.u8.0162', 'gvn',
    'sdiv:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.sdiv.u8.0163', 'loop',
    'sdiv:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.sdiv.u8.0164', 'machine-combine',
    'sdiv:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.udiv.u8.0165', 'canonicalize',
    'udiv:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.udiv.u8.0166', 'sccp',
    'udiv:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.udiv.u8.0167', 'gvn',
    'udiv:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.udiv.u8.0168', 'loop',
    'udiv:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.udiv.u8.0169', 'machine-combine',
    'udiv:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.srem.u8.0170', 'canonicalize',
    'srem:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.srem.u8.0171', 'sccp',
    'srem:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.srem.u8.0172', 'gvn',
    'srem:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.srem.u8.0173', 'loop',
    'srem:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.srem.u8.0174', 'machine-combine',
    'srem:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.urem.u8.0175', 'canonicalize',
    'urem:u8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.urem.u8.0176', 'sccp',
    'urem:u8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.urem.u8.0177', 'gvn',
    'urem:u8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.urem.u8.0178', 'loop',
    'urem:u8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.urem.u8.0179', 'machine-combine',
    'urem:u8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.shl.u8.0180', 'canonicalize',
    'shl:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.shl.u8.0181', 'sccp',
    'shl:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.shl.u8.0182', 'gvn',
    'shl:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.shl.u8.0183', 'loop',
    'shl:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.shl.u8.0184', 'machine-combine',
    'shl:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.ashr.u8.0185', 'canonicalize',
    'ashr:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.ashr.u8.0186', 'sccp',
    'ashr:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.ashr.u8.0187', 'gvn',
    'ashr:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.ashr.u8.0188', 'loop',
    'ashr:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.ashr.u8.0189', 'machine-combine',
    'ashr:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.lshr.u8.0190', 'canonicalize',
    'lshr:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.lshr.u8.0191', 'sccp',
    'lshr:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.lshr.u8.0192', 'gvn',
    'lshr:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.lshr.u8.0193', 'loop',
    'lshr:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.lshr.u8.0194', 'machine-combine',
    'lshr:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.and.u8.0195', 'canonicalize',
    'and:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.and.u8.0196', 'sccp',
    'and:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.and.u8.0197', 'gvn',
    'and:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.and.u8.0198', 'loop',
    'and:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.and.u8.0199', 'machine-combine',
    'and:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.or.u8.0200', 'canonicalize',
    'or:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 9);
  AddRecipe(Result, 'sccp.or.u8.0201', 'sccp',
    'or:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.or.u8.0202', 'gvn',
    'or:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 11);
  AddRecipe(Result, 'loop.or.u8.0203', 'loop',
    'or:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.or.u8.0204', 'machine-combine',
    'or:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.xor.u8.0205', 'canonicalize',
    'xor:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.xor.u8.0206', 'sccp',
    'xor:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.xor.u8.0207', 'gvn',
    'xor:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.xor.u8.0208', 'loop',
    'xor:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.xor.u8.0209', 'machine-combine',
    'xor:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.icmp.eq.u8.0210', 'canonicalize',
    'icmp.eq:u8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.icmp.eq.u8.0211', 'sccp',
    'icmp.eq:u8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.icmp.eq.u8.0212', 'gvn',
    'icmp.eq:u8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.icmp.eq.u8.0213', 'loop',
    'icmp.eq:u8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.icmp.eq.u8.0214', 'machine-combine',
    'icmp.eq:u8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.icmp.ne.u8.0215', 'canonicalize',
    'icmp.ne:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.icmp.ne.u8.0216', 'sccp',
    'icmp.ne:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.icmp.ne.u8.0217', 'gvn',
    'icmp.ne:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.icmp.ne.u8.0218', 'loop',
    'icmp.ne:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.icmp.ne.u8.0219', 'machine-combine',
    'icmp.ne:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.icmp.slt.u8.0220', 'canonicalize',
    'icmp.slt:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.icmp.slt.u8.0221', 'sccp',
    'icmp.slt:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.icmp.slt.u8.0222', 'gvn',
    'icmp.slt:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.icmp.slt.u8.0223', 'loop',
    'icmp.slt:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.icmp.slt.u8.0224', 'machine-combine',
    'icmp.slt:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.icmp.sle.u8.0225', 'canonicalize',
    'icmp.sle:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.icmp.sle.u8.0226', 'sccp',
    'icmp.sle:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.icmp.sle.u8.0227', 'gvn',
    'icmp.sle:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.icmp.sle.u8.0228', 'loop',
    'icmp.sle:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.icmp.sle.u8.0229', 'machine-combine',
    'icmp.sle:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.icmp.sgt.u8.0230', 'canonicalize',
    'icmp.sgt:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.icmp.sgt.u8.0231', 'sccp',
    'icmp.sgt:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.icmp.sgt.u8.0232', 'gvn',
    'icmp.sgt:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.icmp.sgt.u8.0233', 'loop',
    'icmp.sgt:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.icmp.sgt.u8.0234', 'machine-combine',
    'icmp.sgt:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.icmp.sge.u8.0235', 'canonicalize',
    'icmp.sge:u8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.icmp.sge.u8.0236', 'sccp',
    'icmp.sge:u8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.icmp.sge.u8.0237', 'gvn',
    'icmp.sge:u8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.icmp.sge.u8.0238', 'loop',
    'icmp.sge:u8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.icmp.sge.u8.0239', 'machine-combine',
    'icmp.sge:u8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.fadd.u8.0240', 'canonicalize',
    'fadd:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.fadd.u8.0241', 'sccp',
    'fadd:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.fadd.u8.0242', 'gvn',
    'fadd:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.fadd.u8.0243', 'loop',
    'fadd:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.fadd.u8.0244', 'machine-combine',
    'fadd:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.fsub.u8.0245', 'canonicalize',
    'fsub:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.fsub.u8.0246', 'sccp',
    'fsub:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.fsub.u8.0247', 'gvn',
    'fsub:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.fsub.u8.0248', 'loop',
    'fsub:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.fsub.u8.0249', 'machine-combine',
    'fsub:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.fmul.u8.0250', 'canonicalize',
    'fmul:u8', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.fmul.u8.0251', 'sccp',
    'fmul:u8', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.fmul.u8.0252', 'gvn',
    'fmul:u8', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.fmul.u8.0253', 'loop',
    'fmul:u8', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.fmul.u8.0254', 'machine-combine',
    'fmul:u8', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.fdiv.u8.0255', 'canonicalize',
    'fdiv:u8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.fdiv.u8.0256', 'sccp',
    'fdiv:u8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.fdiv.u8.0257', 'gvn',
    'fdiv:u8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.fdiv.u8.0258', 'loop',
    'fdiv:u8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.fdiv.u8.0259', 'machine-combine',
    'fdiv:u8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.load.u8.0260', 'canonicalize',
    'load:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.load.u8.0261', 'sccp',
    'load:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.load.u8.0262', 'gvn',
    'load:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.load.u8.0263', 'loop',
    'load:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.load.u8.0264', 'machine-combine',
    'load:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.store.u8.0265', 'canonicalize',
    'store:u8', 'canonical operand order and normalized casts',
    'generic', 'always', 2);
  AddRecipe(Result, 'sccp.store.u8.0266', 'sccp',
    'store:u8', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.store.u8.0267', 'gvn',
    'store:u8', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 4);
  AddRecipe(Result, 'loop.store.u8.0268', 'loop',
    'store:u8', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.store.u8.0269', 'machine-combine',
    'store:u8', 'select compact target instruction sequence',
    'generic', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.gep.u8.0270', 'canonicalize',
    'gep:u8', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.gep.u8.0271', 'sccp',
    'gep:u8', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.gep.u8.0272', 'gvn',
    'gep:u8', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.gep.u8.0273', 'loop',
    'gep:u8', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.gep.u8.0274', 'machine-combine',
    'gep:u8', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.select.u8.0275', 'canonicalize',
    'select:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 12);
  AddRecipe(Result, 'sccp.select.u8.0276', 'sccp',
    'select:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.select.u8.0277', 'gvn',
    'select:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 2);
  AddRecipe(Result, 'loop.select.u8.0278', 'loop',
    'select:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.select.u8.0279', 'machine-combine',
    'select:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.phi.u8.0280', 'canonicalize',
    'phi:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.phi.u8.0281', 'sccp',
    'phi:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.phi.u8.0282', 'gvn',
    'phi:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.phi.u8.0283', 'loop',
    'phi:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.phi.u8.0284', 'machine-combine',
    'phi:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.call.u8.0285', 'canonicalize',
    'call:u8', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.call.u8.0286', 'sccp',
    'call:u8', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.call.u8.0287', 'gvn',
    'call:u8', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.call.u8.0288', 'loop',
    'call:u8', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.call.u8.0289', 'machine-combine',
    'call:u8', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.add.i16.0290', 'canonicalize',
    'add:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 3);
  AddRecipe(Result, 'sccp.add.i16.0291', 'sccp',
    'add:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.add.i16.0292', 'gvn',
    'add:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 5);
  AddRecipe(Result, 'loop.add.i16.0293', 'loop',
    'add:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.add.i16.0294', 'machine-combine',
    'add:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.sub.i16.0295', 'canonicalize',
    'sub:i16', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.sub.i16.0296', 'sccp',
    'sub:i16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.sub.i16.0297', 'gvn',
    'sub:i16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.sub.i16.0298', 'loop',
    'sub:i16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.sub.i16.0299', 'machine-combine',
    'sub:i16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.mul.i16.0300', 'canonicalize',
    'mul:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.mul.i16.0301', 'sccp',
    'mul:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.mul.i16.0302', 'gvn',
    'mul:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.mul.i16.0303', 'loop',
    'mul:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.mul.i16.0304', 'machine-combine',
    'mul:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.sdiv.i16.0305', 'canonicalize',
    'sdiv:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.sdiv.i16.0306', 'sccp',
    'sdiv:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.sdiv.i16.0307', 'gvn',
    'sdiv:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.sdiv.i16.0308', 'loop',
    'sdiv:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.sdiv.i16.0309', 'machine-combine',
    'sdiv:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.udiv.i16.0310', 'canonicalize',
    'udiv:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.udiv.i16.0311', 'sccp',
    'udiv:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.udiv.i16.0312', 'gvn',
    'udiv:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.udiv.i16.0313', 'loop',
    'udiv:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.udiv.i16.0314', 'machine-combine',
    'udiv:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.srem.i16.0315', 'canonicalize',
    'srem:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.srem.i16.0316', 'sccp',
    'srem:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.srem.i16.0317', 'gvn',
    'srem:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.srem.i16.0318', 'loop',
    'srem:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.srem.i16.0319', 'machine-combine',
    'srem:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.urem.i16.0320', 'canonicalize',
    'urem:i16', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.urem.i16.0321', 'sccp',
    'urem:i16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.urem.i16.0322', 'gvn',
    'urem:i16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.urem.i16.0323', 'loop',
    'urem:i16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.urem.i16.0324', 'machine-combine',
    'urem:i16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.shl.i16.0325', 'canonicalize',
    'shl:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.shl.i16.0326', 'sccp',
    'shl:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.shl.i16.0327', 'gvn',
    'shl:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.shl.i16.0328', 'loop',
    'shl:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.shl.i16.0329', 'machine-combine',
    'shl:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.ashr.i16.0330', 'canonicalize',
    'ashr:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.ashr.i16.0331', 'sccp',
    'ashr:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.ashr.i16.0332', 'gvn',
    'ashr:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.ashr.i16.0333', 'loop',
    'ashr:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.ashr.i16.0334', 'machine-combine',
    'ashr:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.lshr.i16.0335', 'canonicalize',
    'lshr:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.lshr.i16.0336', 'sccp',
    'lshr:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.lshr.i16.0337', 'gvn',
    'lshr:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.lshr.i16.0338', 'loop',
    'lshr:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.lshr.i16.0339', 'machine-combine',
    'lshr:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.and.i16.0340', 'canonicalize',
    'and:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.and.i16.0341', 'sccp',
    'and:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.and.i16.0342', 'gvn',
    'and:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.and.i16.0343', 'loop',
    'and:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.and.i16.0344', 'machine-combine',
    'and:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.or.i16.0345', 'canonicalize',
    'or:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 10);
  AddRecipe(Result, 'sccp.or.i16.0346', 'sccp',
    'or:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.or.i16.0347', 'gvn',
    'or:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 12);
  AddRecipe(Result, 'loop.or.i16.0348', 'loop',
    'or:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.or.i16.0349', 'machine-combine',
    'or:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.xor.i16.0350', 'canonicalize',
    'xor:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 3);
  AddRecipe(Result, 'sccp.xor.i16.0351', 'sccp',
    'xor:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.xor.i16.0352', 'gvn',
    'xor:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 5);
  AddRecipe(Result, 'loop.xor.i16.0353', 'loop',
    'xor:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.xor.i16.0354', 'machine-combine',
    'xor:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.icmp.eq.i16.0355', 'canonicalize',
    'icmp.eq:i16', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.icmp.eq.i16.0356', 'sccp',
    'icmp.eq:i16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.icmp.eq.i16.0357', 'gvn',
    'icmp.eq:i16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.icmp.eq.i16.0358', 'loop',
    'icmp.eq:i16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.icmp.eq.i16.0359', 'machine-combine',
    'icmp.eq:i16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.icmp.ne.i16.0360', 'canonicalize',
    'icmp.ne:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.icmp.ne.i16.0361', 'sccp',
    'icmp.ne:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.icmp.ne.i16.0362', 'gvn',
    'icmp.ne:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.icmp.ne.i16.0363', 'loop',
    'icmp.ne:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.icmp.ne.i16.0364', 'machine-combine',
    'icmp.ne:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.icmp.slt.i16.0365', 'canonicalize',
    'icmp.slt:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.icmp.slt.i16.0366', 'sccp',
    'icmp.slt:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.icmp.slt.i16.0367', 'gvn',
    'icmp.slt:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.icmp.slt.i16.0368', 'loop',
    'icmp.slt:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.icmp.slt.i16.0369', 'machine-combine',
    'icmp.slt:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.icmp.sle.i16.0370', 'canonicalize',
    'icmp.sle:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.icmp.sle.i16.0371', 'sccp',
    'icmp.sle:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.icmp.sle.i16.0372', 'gvn',
    'icmp.sle:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.icmp.sle.i16.0373', 'loop',
    'icmp.sle:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.icmp.sle.i16.0374', 'machine-combine',
    'icmp.sle:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.icmp.sgt.i16.0375', 'canonicalize',
    'icmp.sgt:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.icmp.sgt.i16.0376', 'sccp',
    'icmp.sgt:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.icmp.sgt.i16.0377', 'gvn',
    'icmp.sgt:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.icmp.sgt.i16.0378', 'loop',
    'icmp.sgt:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.icmp.sgt.i16.0379', 'machine-combine',
    'icmp.sgt:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.icmp.sge.i16.0380', 'canonicalize',
    'icmp.sge:i16', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.icmp.sge.i16.0381', 'sccp',
    'icmp.sge:i16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.icmp.sge.i16.0382', 'gvn',
    'icmp.sge:i16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.icmp.sge.i16.0383', 'loop',
    'icmp.sge:i16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.icmp.sge.i16.0384', 'machine-combine',
    'icmp.sge:i16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.fadd.i16.0385', 'canonicalize',
    'fadd:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.fadd.i16.0386', 'sccp',
    'fadd:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.fadd.i16.0387', 'gvn',
    'fadd:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.fadd.i16.0388', 'loop',
    'fadd:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.fadd.i16.0389', 'machine-combine',
    'fadd:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.fsub.i16.0390', 'canonicalize',
    'fsub:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.fsub.i16.0391', 'sccp',
    'fsub:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.fsub.i16.0392', 'gvn',
    'fsub:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.fsub.i16.0393', 'loop',
    'fsub:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.fsub.i16.0394', 'machine-combine',
    'fsub:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.fmul.i16.0395', 'canonicalize',
    'fmul:i16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.fmul.i16.0396', 'sccp',
    'fmul:i16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.fmul.i16.0397', 'gvn',
    'fmul:i16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.fmul.i16.0398', 'loop',
    'fmul:i16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.fmul.i16.0399', 'machine-combine',
    'fmul:i16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.fdiv.i16.0400', 'canonicalize',
    'fdiv:i16', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.fdiv.i16.0401', 'sccp',
    'fdiv:i16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.fdiv.i16.0402', 'gvn',
    'fdiv:i16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.fdiv.i16.0403', 'loop',
    'fdiv:i16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.fdiv.i16.0404', 'machine-combine',
    'fdiv:i16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.load.i16.0405', 'canonicalize',
    'load:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.load.i16.0406', 'sccp',
    'load:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.load.i16.0407', 'gvn',
    'load:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.load.i16.0408', 'loop',
    'load:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.load.i16.0409', 'machine-combine',
    'load:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.store.i16.0410', 'canonicalize',
    'store:i16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 3);
  AddRecipe(Result, 'sccp.store.i16.0411', 'sccp',
    'store:i16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.store.i16.0412', 'gvn',
    'store:i16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 5);
  AddRecipe(Result, 'loop.store.i16.0413', 'loop',
    'store:i16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.store.i16.0414', 'machine-combine',
    'store:i16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.gep.i16.0415', 'canonicalize',
    'gep:i16', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.gep.i16.0416', 'sccp',
    'gep:i16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.gep.i16.0417', 'gvn',
    'gep:i16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.gep.i16.0418', 'loop',
    'gep:i16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.gep.i16.0419', 'machine-combine',
    'gep:i16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.select.i16.0420', 'canonicalize',
    'select:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 1);
  AddRecipe(Result, 'sccp.select.i16.0421', 'sccp',
    'select:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.select.i16.0422', 'gvn',
    'select:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 3);
  AddRecipe(Result, 'loop.select.i16.0423', 'loop',
    'select:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.select.i16.0424', 'machine-combine',
    'select:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.phi.i16.0425', 'canonicalize',
    'phi:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.phi.i16.0426', 'sccp',
    'phi:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.phi.i16.0427', 'gvn',
    'phi:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.phi.i16.0428', 'loop',
    'phi:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.phi.i16.0429', 'machine-combine',
    'phi:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.call.i16.0430', 'canonicalize',
    'call:i16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.call.i16.0431', 'sccp',
    'call:i16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.call.i16.0432', 'gvn',
    'call:i16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.call.i16.0433', 'loop',
    'call:i16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.call.i16.0434', 'machine-combine',
    'call:i16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.add.u16.0435', 'canonicalize',
    'add:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.add.u16.0436', 'sccp',
    'add:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.add.u16.0437', 'gvn',
    'add:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.add.u16.0438', 'loop',
    'add:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.add.u16.0439', 'machine-combine',
    'add:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.sub.u16.0440', 'canonicalize',
    'sub:u16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.sub.u16.0441', 'sccp',
    'sub:u16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.sub.u16.0442', 'gvn',
    'sub:u16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.sub.u16.0443', 'loop',
    'sub:u16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.sub.u16.0444', 'machine-combine',
    'sub:u16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.mul.u16.0445', 'canonicalize',
    'mul:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.mul.u16.0446', 'sccp',
    'mul:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.mul.u16.0447', 'gvn',
    'mul:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.mul.u16.0448', 'loop',
    'mul:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.mul.u16.0449', 'machine-combine',
    'mul:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.sdiv.u16.0450', 'canonicalize',
    'sdiv:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.sdiv.u16.0451', 'sccp',
    'sdiv:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.sdiv.u16.0452', 'gvn',
    'sdiv:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.sdiv.u16.0453', 'loop',
    'sdiv:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.sdiv.u16.0454', 'machine-combine',
    'sdiv:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.udiv.u16.0455', 'canonicalize',
    'udiv:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.udiv.u16.0456', 'sccp',
    'udiv:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.udiv.u16.0457', 'gvn',
    'udiv:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.udiv.u16.0458', 'loop',
    'udiv:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.udiv.u16.0459', 'machine-combine',
    'udiv:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.srem.u16.0460', 'canonicalize',
    'srem:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.srem.u16.0461', 'sccp',
    'srem:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.srem.u16.0462', 'gvn',
    'srem:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.srem.u16.0463', 'loop',
    'srem:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.srem.u16.0464', 'machine-combine',
    'srem:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.urem.u16.0465', 'canonicalize',
    'urem:u16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.urem.u16.0466', 'sccp',
    'urem:u16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.urem.u16.0467', 'gvn',
    'urem:u16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.urem.u16.0468', 'loop',
    'urem:u16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.urem.u16.0469', 'machine-combine',
    'urem:u16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.shl.u16.0470', 'canonicalize',
    'shl:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 3);
  AddRecipe(Result, 'sccp.shl.u16.0471', 'sccp',
    'shl:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.shl.u16.0472', 'gvn',
    'shl:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 5);
  AddRecipe(Result, 'loop.shl.u16.0473', 'loop',
    'shl:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.shl.u16.0474', 'machine-combine',
    'shl:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.ashr.u16.0475', 'canonicalize',
    'ashr:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.ashr.u16.0476', 'sccp',
    'ashr:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.ashr.u16.0477', 'gvn',
    'ashr:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.ashr.u16.0478', 'loop',
    'ashr:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.ashr.u16.0479', 'machine-combine',
    'ashr:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.lshr.u16.0480', 'canonicalize',
    'lshr:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.lshr.u16.0481', 'sccp',
    'lshr:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.lshr.u16.0482', 'gvn',
    'lshr:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.lshr.u16.0483', 'loop',
    'lshr:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.lshr.u16.0484', 'machine-combine',
    'lshr:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.and.u16.0485', 'canonicalize',
    'and:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.and.u16.0486', 'sccp',
    'and:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.and.u16.0487', 'gvn',
    'and:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.and.u16.0488', 'loop',
    'and:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.and.u16.0489', 'machine-combine',
    'and:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.or.u16.0490', 'canonicalize',
    'or:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 11);
  AddRecipe(Result, 'sccp.or.u16.0491', 'sccp',
    'or:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.or.u16.0492', 'gvn',
    'or:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 1);
  AddRecipe(Result, 'loop.or.u16.0493', 'loop',
    'or:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.or.u16.0494', 'machine-combine',
    'or:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.xor.u16.0495', 'canonicalize',
    'xor:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.xor.u16.0496', 'sccp',
    'xor:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.xor.u16.0497', 'gvn',
    'xor:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.xor.u16.0498', 'loop',
    'xor:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.xor.u16.0499', 'machine-combine',
    'xor:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.icmp.eq.u16.0500', 'canonicalize',
    'icmp.eq:u16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.icmp.eq.u16.0501', 'sccp',
    'icmp.eq:u16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.icmp.eq.u16.0502', 'gvn',
    'icmp.eq:u16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.icmp.eq.u16.0503', 'loop',
    'icmp.eq:u16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.icmp.eq.u16.0504', 'machine-combine',
    'icmp.eq:u16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.icmp.ne.u16.0505', 'canonicalize',
    'icmp.ne:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.icmp.ne.u16.0506', 'sccp',
    'icmp.ne:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.icmp.ne.u16.0507', 'gvn',
    'icmp.ne:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.icmp.ne.u16.0508', 'loop',
    'icmp.ne:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.icmp.ne.u16.0509', 'machine-combine',
    'icmp.ne:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.icmp.slt.u16.0510', 'canonicalize',
    'icmp.slt:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.icmp.slt.u16.0511', 'sccp',
    'icmp.slt:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.icmp.slt.u16.0512', 'gvn',
    'icmp.slt:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.icmp.slt.u16.0513', 'loop',
    'icmp.slt:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.icmp.slt.u16.0514', 'machine-combine',
    'icmp.slt:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.icmp.sle.u16.0515', 'canonicalize',
    'icmp.sle:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.icmp.sle.u16.0516', 'sccp',
    'icmp.sle:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.icmp.sle.u16.0517', 'gvn',
    'icmp.sle:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.icmp.sle.u16.0518', 'loop',
    'icmp.sle:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.icmp.sle.u16.0519', 'machine-combine',
    'icmp.sle:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.icmp.sgt.u16.0520', 'canonicalize',
    'icmp.sgt:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.icmp.sgt.u16.0521', 'sccp',
    'icmp.sgt:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.icmp.sgt.u16.0522', 'gvn',
    'icmp.sgt:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.icmp.sgt.u16.0523', 'loop',
    'icmp.sgt:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.icmp.sgt.u16.0524', 'machine-combine',
    'icmp.sgt:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.icmp.sge.u16.0525', 'canonicalize',
    'icmp.sge:u16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.icmp.sge.u16.0526', 'sccp',
    'icmp.sge:u16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.icmp.sge.u16.0527', 'gvn',
    'icmp.sge:u16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.icmp.sge.u16.0528', 'loop',
    'icmp.sge:u16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.icmp.sge.u16.0529', 'machine-combine',
    'icmp.sge:u16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.fadd.u16.0530', 'canonicalize',
    'fadd:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.fadd.u16.0531', 'sccp',
    'fadd:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.fadd.u16.0532', 'gvn',
    'fadd:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.fadd.u16.0533', 'loop',
    'fadd:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.fadd.u16.0534', 'machine-combine',
    'fadd:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.fsub.u16.0535', 'canonicalize',
    'fsub:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.fsub.u16.0536', 'sccp',
    'fsub:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.fsub.u16.0537', 'gvn',
    'fsub:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.fsub.u16.0538', 'loop',
    'fsub:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.fsub.u16.0539', 'machine-combine',
    'fsub:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.fmul.u16.0540', 'canonicalize',
    'fmul:u16', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.fmul.u16.0541', 'sccp',
    'fmul:u16', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.fmul.u16.0542', 'gvn',
    'fmul:u16', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.fmul.u16.0543', 'loop',
    'fmul:u16', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.fmul.u16.0544', 'machine-combine',
    'fmul:u16', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.fdiv.u16.0545', 'canonicalize',
    'fdiv:u16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.fdiv.u16.0546', 'sccp',
    'fdiv:u16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.fdiv.u16.0547', 'gvn',
    'fdiv:u16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.fdiv.u16.0548', 'loop',
    'fdiv:u16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.fdiv.u16.0549', 'machine-combine',
    'fdiv:u16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.load.u16.0550', 'canonicalize',
    'load:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.load.u16.0551', 'sccp',
    'load:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.load.u16.0552', 'gvn',
    'load:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.load.u16.0553', 'loop',
    'load:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.load.u16.0554', 'machine-combine',
    'load:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.store.u16.0555', 'canonicalize',
    'store:u16', 'canonical operand order and normalized casts',
    'aarch64', 'always', 4);
  AddRecipe(Result, 'sccp.store.u16.0556', 'sccp',
    'store:u16', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.store.u16.0557', 'gvn',
    'store:u16', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 6);
  AddRecipe(Result, 'loop.store.u16.0558', 'loop',
    'store:u16', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.store.u16.0559', 'machine-combine',
    'store:u16', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.gep.u16.0560', 'canonicalize',
    'gep:u16', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.gep.u16.0561', 'sccp',
    'gep:u16', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.gep.u16.0562', 'gvn',
    'gep:u16', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.gep.u16.0563', 'loop',
    'gep:u16', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.gep.u16.0564', 'machine-combine',
    'gep:u16', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.select.u16.0565', 'canonicalize',
    'select:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 2);
  AddRecipe(Result, 'sccp.select.u16.0566', 'sccp',
    'select:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.select.u16.0567', 'gvn',
    'select:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 4);
  AddRecipe(Result, 'loop.select.u16.0568', 'loop',
    'select:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.select.u16.0569', 'machine-combine',
    'select:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.phi.u16.0570', 'canonicalize',
    'phi:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.phi.u16.0571', 'sccp',
    'phi:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.phi.u16.0572', 'gvn',
    'phi:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.phi.u16.0573', 'loop',
    'phi:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.phi.u16.0574', 'machine-combine',
    'phi:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.call.u16.0575', 'canonicalize',
    'call:u16', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.call.u16.0576', 'sccp',
    'call:u16', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.call.u16.0577', 'gvn',
    'call:u16', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.call.u16.0578', 'loop',
    'call:u16', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.call.u16.0579', 'machine-combine',
    'call:u16', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.add.i32.0580', 'canonicalize',
    'add:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.add.i32.0581', 'sccp',
    'add:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.add.i32.0582', 'gvn',
    'add:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.add.i32.0583', 'loop',
    'add:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.add.i32.0584', 'machine-combine',
    'add:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.sub.i32.0585', 'canonicalize',
    'sub:i32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 10);
  AddRecipe(Result, 'sccp.sub.i32.0586', 'sccp',
    'sub:i32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.sub.i32.0587', 'gvn',
    'sub:i32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 12);
  AddRecipe(Result, 'loop.sub.i32.0588', 'loop',
    'sub:i32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.sub.i32.0589', 'machine-combine',
    'sub:i32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.mul.i32.0590', 'canonicalize',
    'mul:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 3);
  AddRecipe(Result, 'sccp.mul.i32.0591', 'sccp',
    'mul:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.mul.i32.0592', 'gvn',
    'mul:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 5);
  AddRecipe(Result, 'loop.mul.i32.0593', 'loop',
    'mul:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.mul.i32.0594', 'machine-combine',
    'mul:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.sdiv.i32.0595', 'canonicalize',
    'sdiv:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.sdiv.i32.0596', 'sccp',
    'sdiv:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.sdiv.i32.0597', 'gvn',
    'sdiv:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.sdiv.i32.0598', 'loop',
    'sdiv:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.sdiv.i32.0599', 'machine-combine',
    'sdiv:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.udiv.i32.0600', 'canonicalize',
    'udiv:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.udiv.i32.0601', 'sccp',
    'udiv:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.udiv.i32.0602', 'gvn',
    'udiv:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.udiv.i32.0603', 'loop',
    'udiv:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.udiv.i32.0604', 'machine-combine',
    'udiv:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.srem.i32.0605', 'canonicalize',
    'srem:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.srem.i32.0606', 'sccp',
    'srem:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.srem.i32.0607', 'gvn',
    'srem:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.srem.i32.0608', 'loop',
    'srem:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.srem.i32.0609', 'machine-combine',
    'srem:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.urem.i32.0610', 'canonicalize',
    'urem:i32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.urem.i32.0611', 'sccp',
    'urem:i32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.urem.i32.0612', 'gvn',
    'urem:i32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.urem.i32.0613', 'loop',
    'urem:i32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.urem.i32.0614', 'machine-combine',
    'urem:i32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.shl.i32.0615', 'canonicalize',
    'shl:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.shl.i32.0616', 'sccp',
    'shl:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.shl.i32.0617', 'gvn',
    'shl:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.shl.i32.0618', 'loop',
    'shl:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.shl.i32.0619', 'machine-combine',
    'shl:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.ashr.i32.0620', 'canonicalize',
    'ashr:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.ashr.i32.0621', 'sccp',
    'ashr:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.ashr.i32.0622', 'gvn',
    'ashr:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.ashr.i32.0623', 'loop',
    'ashr:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.ashr.i32.0624', 'machine-combine',
    'ashr:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.lshr.i32.0625', 'canonicalize',
    'lshr:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.lshr.i32.0626', 'sccp',
    'lshr:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.lshr.i32.0627', 'gvn',
    'lshr:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.lshr.i32.0628', 'loop',
    'lshr:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.lshr.i32.0629', 'machine-combine',
    'lshr:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.and.i32.0630', 'canonicalize',
    'and:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.and.i32.0631', 'sccp',
    'and:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.and.i32.0632', 'gvn',
    'and:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.and.i32.0633', 'loop',
    'and:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.and.i32.0634', 'machine-combine',
    'and:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.or.i32.0635', 'canonicalize',
    'or:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 12);
  AddRecipe(Result, 'sccp.or.i32.0636', 'sccp',
    'or:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.or.i32.0637', 'gvn',
    'or:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 2);
  AddRecipe(Result, 'loop.or.i32.0638', 'loop',
    'or:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.or.i32.0639', 'machine-combine',
    'or:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.xor.i32.0640', 'canonicalize',
    'xor:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.xor.i32.0641', 'sccp',
    'xor:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.xor.i32.0642', 'gvn',
    'xor:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.xor.i32.0643', 'loop',
    'xor:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.xor.i32.0644', 'machine-combine',
    'xor:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.icmp.eq.i32.0645', 'canonicalize',
    'icmp.eq:i32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 10);
  AddRecipe(Result, 'sccp.icmp.eq.i32.0646', 'sccp',
    'icmp.eq:i32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.icmp.eq.i32.0647', 'gvn',
    'icmp.eq:i32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 12);
  AddRecipe(Result, 'loop.icmp.eq.i32.0648', 'loop',
    'icmp.eq:i32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.icmp.eq.i32.0649', 'machine-combine',
    'icmp.eq:i32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.icmp.ne.i32.0650', 'canonicalize',
    'icmp.ne:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 3);
  AddRecipe(Result, 'sccp.icmp.ne.i32.0651', 'sccp',
    'icmp.ne:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.icmp.ne.i32.0652', 'gvn',
    'icmp.ne:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 5);
  AddRecipe(Result, 'loop.icmp.ne.i32.0653', 'loop',
    'icmp.ne:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.icmp.ne.i32.0654', 'machine-combine',
    'icmp.ne:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.icmp.slt.i32.0655', 'canonicalize',
    'icmp.slt:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.icmp.slt.i32.0656', 'sccp',
    'icmp.slt:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.icmp.slt.i32.0657', 'gvn',
    'icmp.slt:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.icmp.slt.i32.0658', 'loop',
    'icmp.slt:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.icmp.slt.i32.0659', 'machine-combine',
    'icmp.slt:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.icmp.sle.i32.0660', 'canonicalize',
    'icmp.sle:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.icmp.sle.i32.0661', 'sccp',
    'icmp.sle:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.icmp.sle.i32.0662', 'gvn',
    'icmp.sle:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.icmp.sle.i32.0663', 'loop',
    'icmp.sle:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.icmp.sle.i32.0664', 'machine-combine',
    'icmp.sle:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.icmp.sgt.i32.0665', 'canonicalize',
    'icmp.sgt:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.icmp.sgt.i32.0666', 'sccp',
    'icmp.sgt:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.icmp.sgt.i32.0667', 'gvn',
    'icmp.sgt:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.icmp.sgt.i32.0668', 'loop',
    'icmp.sgt:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.icmp.sgt.i32.0669', 'machine-combine',
    'icmp.sgt:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.icmp.sge.i32.0670', 'canonicalize',
    'icmp.sge:i32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.icmp.sge.i32.0671', 'sccp',
    'icmp.sge:i32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.icmp.sge.i32.0672', 'gvn',
    'icmp.sge:i32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.icmp.sge.i32.0673', 'loop',
    'icmp.sge:i32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.icmp.sge.i32.0674', 'machine-combine',
    'icmp.sge:i32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.fadd.i32.0675', 'canonicalize',
    'fadd:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.fadd.i32.0676', 'sccp',
    'fadd:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.fadd.i32.0677', 'gvn',
    'fadd:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.fadd.i32.0678', 'loop',
    'fadd:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.fadd.i32.0679', 'machine-combine',
    'fadd:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.fsub.i32.0680', 'canonicalize',
    'fsub:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.fsub.i32.0681', 'sccp',
    'fsub:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.fsub.i32.0682', 'gvn',
    'fsub:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.fsub.i32.0683', 'loop',
    'fsub:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.fsub.i32.0684', 'machine-combine',
    'fsub:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.fmul.i32.0685', 'canonicalize',
    'fmul:i32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.fmul.i32.0686', 'sccp',
    'fmul:i32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.fmul.i32.0687', 'gvn',
    'fmul:i32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.fmul.i32.0688', 'loop',
    'fmul:i32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.fmul.i32.0689', 'machine-combine',
    'fmul:i32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.fdiv.i32.0690', 'canonicalize',
    'fdiv:i32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.fdiv.i32.0691', 'sccp',
    'fdiv:i32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.fdiv.i32.0692', 'gvn',
    'fdiv:i32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.fdiv.i32.0693', 'loop',
    'fdiv:i32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.fdiv.i32.0694', 'machine-combine',
    'fdiv:i32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.load.i32.0695', 'canonicalize',
    'load:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.load.i32.0696', 'sccp',
    'load:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.load.i32.0697', 'gvn',
    'load:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.load.i32.0698', 'loop',
    'load:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.load.i32.0699', 'machine-combine',
    'load:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.store.i32.0700', 'canonicalize',
    'store:i32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 5);
  AddRecipe(Result, 'sccp.store.i32.0701', 'sccp',
    'store:i32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.store.i32.0702', 'gvn',
    'store:i32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 7);
  AddRecipe(Result, 'loop.store.i32.0703', 'loop',
    'store:i32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.store.i32.0704', 'machine-combine',
    'store:i32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.gep.i32.0705', 'canonicalize',
    'gep:i32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 10);
  AddRecipe(Result, 'sccp.gep.i32.0706', 'sccp',
    'gep:i32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.gep.i32.0707', 'gvn',
    'gep:i32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 12);
  AddRecipe(Result, 'loop.gep.i32.0708', 'loop',
    'gep:i32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.gep.i32.0709', 'machine-combine',
    'gep:i32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.select.i32.0710', 'canonicalize',
    'select:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 3);
  AddRecipe(Result, 'sccp.select.i32.0711', 'sccp',
    'select:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.select.i32.0712', 'gvn',
    'select:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 5);
  AddRecipe(Result, 'loop.select.i32.0713', 'loop',
    'select:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.select.i32.0714', 'machine-combine',
    'select:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.phi.i32.0715', 'canonicalize',
    'phi:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.phi.i32.0716', 'sccp',
    'phi:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.phi.i32.0717', 'gvn',
    'phi:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.phi.i32.0718', 'loop',
    'phi:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.phi.i32.0719', 'machine-combine',
    'phi:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.call.i32.0720', 'canonicalize',
    'call:i32', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.call.i32.0721', 'sccp',
    'call:i32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.call.i32.0722', 'gvn',
    'call:i32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.call.i32.0723', 'loop',
    'call:i32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.call.i32.0724', 'machine-combine',
    'call:i32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.add.u32.0725', 'canonicalize',
    'add:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.add.u32.0726', 'sccp',
    'add:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.add.u32.0727', 'gvn',
    'add:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.add.u32.0728', 'loop',
    'add:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.add.u32.0729', 'machine-combine',
    'add:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.sub.u32.0730', 'canonicalize',
    'sub:u32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.sub.u32.0731', 'sccp',
    'sub:u32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.sub.u32.0732', 'gvn',
    'sub:u32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.sub.u32.0733', 'loop',
    'sub:u32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.sub.u32.0734', 'machine-combine',
    'sub:u32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.mul.u32.0735', 'canonicalize',
    'mul:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.mul.u32.0736', 'sccp',
    'mul:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.mul.u32.0737', 'gvn',
    'mul:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.mul.u32.0738', 'loop',
    'mul:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.mul.u32.0739', 'machine-combine',
    'mul:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.sdiv.u32.0740', 'canonicalize',
    'sdiv:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.sdiv.u32.0741', 'sccp',
    'sdiv:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.sdiv.u32.0742', 'gvn',
    'sdiv:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.sdiv.u32.0743', 'loop',
    'sdiv:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.sdiv.u32.0744', 'machine-combine',
    'sdiv:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.udiv.u32.0745', 'canonicalize',
    'udiv:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.udiv.u32.0746', 'sccp',
    'udiv:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.udiv.u32.0747', 'gvn',
    'udiv:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.udiv.u32.0748', 'loop',
    'udiv:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.udiv.u32.0749', 'machine-combine',
    'udiv:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.srem.u32.0750', 'canonicalize',
    'srem:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.srem.u32.0751', 'sccp',
    'srem:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.srem.u32.0752', 'gvn',
    'srem:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.srem.u32.0753', 'loop',
    'srem:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.srem.u32.0754', 'machine-combine',
    'srem:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.urem.u32.0755', 'canonicalize',
    'urem:u32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.urem.u32.0756', 'sccp',
    'urem:u32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.urem.u32.0757', 'gvn',
    'urem:u32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.urem.u32.0758', 'loop',
    'urem:u32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.urem.u32.0759', 'machine-combine',
    'urem:u32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.shl.u32.0760', 'canonicalize',
    'shl:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.shl.u32.0761', 'sccp',
    'shl:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.shl.u32.0762', 'gvn',
    'shl:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.shl.u32.0763', 'loop',
    'shl:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.shl.u32.0764', 'machine-combine',
    'shl:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.ashr.u32.0765', 'canonicalize',
    'ashr:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.ashr.u32.0766', 'sccp',
    'ashr:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.ashr.u32.0767', 'gvn',
    'ashr:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.ashr.u32.0768', 'loop',
    'ashr:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.ashr.u32.0769', 'machine-combine',
    'ashr:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.lshr.u32.0770', 'canonicalize',
    'lshr:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.lshr.u32.0771', 'sccp',
    'lshr:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.lshr.u32.0772', 'gvn',
    'lshr:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.lshr.u32.0773', 'loop',
    'lshr:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.lshr.u32.0774', 'machine-combine',
    'lshr:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.and.u32.0775', 'canonicalize',
    'and:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.and.u32.0776', 'sccp',
    'and:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.and.u32.0777', 'gvn',
    'and:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.and.u32.0778', 'loop',
    'and:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.and.u32.0779', 'machine-combine',
    'and:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.or.u32.0780', 'canonicalize',
    'or:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 1);
  AddRecipe(Result, 'sccp.or.u32.0781', 'sccp',
    'or:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.or.u32.0782', 'gvn',
    'or:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 3);
  AddRecipe(Result, 'loop.or.u32.0783', 'loop',
    'or:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.or.u32.0784', 'machine-combine',
    'or:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.xor.u32.0785', 'canonicalize',
    'xor:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.xor.u32.0786', 'sccp',
    'xor:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.xor.u32.0787', 'gvn',
    'xor:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.xor.u32.0788', 'loop',
    'xor:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.xor.u32.0789', 'machine-combine',
    'xor:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.icmp.eq.u32.0790', 'canonicalize',
    'icmp.eq:u32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.icmp.eq.u32.0791', 'sccp',
    'icmp.eq:u32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.icmp.eq.u32.0792', 'gvn',
    'icmp.eq:u32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.icmp.eq.u32.0793', 'loop',
    'icmp.eq:u32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.icmp.eq.u32.0794', 'machine-combine',
    'icmp.eq:u32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.icmp.ne.u32.0795', 'canonicalize',
    'icmp.ne:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 4);
  AddRecipe(Result, 'sccp.icmp.ne.u32.0796', 'sccp',
    'icmp.ne:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.icmp.ne.u32.0797', 'gvn',
    'icmp.ne:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 6);
  AddRecipe(Result, 'loop.icmp.ne.u32.0798', 'loop',
    'icmp.ne:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.icmp.ne.u32.0799', 'machine-combine',
    'icmp.ne:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.icmp.slt.u32.0800', 'canonicalize',
    'icmp.slt:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.icmp.slt.u32.0801', 'sccp',
    'icmp.slt:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.icmp.slt.u32.0802', 'gvn',
    'icmp.slt:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.icmp.slt.u32.0803', 'loop',
    'icmp.slt:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.icmp.slt.u32.0804', 'machine-combine',
    'icmp.slt:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.icmp.sle.u32.0805', 'canonicalize',
    'icmp.sle:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.icmp.sle.u32.0806', 'sccp',
    'icmp.sle:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.icmp.sle.u32.0807', 'gvn',
    'icmp.sle:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.icmp.sle.u32.0808', 'loop',
    'icmp.sle:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.icmp.sle.u32.0809', 'machine-combine',
    'icmp.sle:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.icmp.sgt.u32.0810', 'canonicalize',
    'icmp.sgt:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.icmp.sgt.u32.0811', 'sccp',
    'icmp.sgt:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.icmp.sgt.u32.0812', 'gvn',
    'icmp.sgt:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.icmp.sgt.u32.0813', 'loop',
    'icmp.sgt:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.icmp.sgt.u32.0814', 'machine-combine',
    'icmp.sgt:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.icmp.sge.u32.0815', 'canonicalize',
    'icmp.sge:u32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.icmp.sge.u32.0816', 'sccp',
    'icmp.sge:u32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.icmp.sge.u32.0817', 'gvn',
    'icmp.sge:u32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.icmp.sge.u32.0818', 'loop',
    'icmp.sge:u32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.icmp.sge.u32.0819', 'machine-combine',
    'icmp.sge:u32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.fadd.u32.0820', 'canonicalize',
    'fadd:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.fadd.u32.0821', 'sccp',
    'fadd:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.fadd.u32.0822', 'gvn',
    'fadd:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.fadd.u32.0823', 'loop',
    'fadd:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.fadd.u32.0824', 'machine-combine',
    'fadd:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.fsub.u32.0825', 'canonicalize',
    'fsub:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.fsub.u32.0826', 'sccp',
    'fsub:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.fsub.u32.0827', 'gvn',
    'fsub:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.fsub.u32.0828', 'loop',
    'fsub:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.fsub.u32.0829', 'machine-combine',
    'fsub:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.fmul.u32.0830', 'canonicalize',
    'fmul:u32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.fmul.u32.0831', 'sccp',
    'fmul:u32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.fmul.u32.0832', 'gvn',
    'fmul:u32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.fmul.u32.0833', 'loop',
    'fmul:u32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.fmul.u32.0834', 'machine-combine',
    'fmul:u32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.fdiv.u32.0835', 'canonicalize',
    'fdiv:u32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.fdiv.u32.0836', 'sccp',
    'fdiv:u32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.fdiv.u32.0837', 'gvn',
    'fdiv:u32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.fdiv.u32.0838', 'loop',
    'fdiv:u32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.fdiv.u32.0839', 'machine-combine',
    'fdiv:u32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.load.u32.0840', 'canonicalize',
    'load:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.load.u32.0841', 'sccp',
    'load:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.load.u32.0842', 'gvn',
    'load:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.load.u32.0843', 'loop',
    'load:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.load.u32.0844', 'machine-combine',
    'load:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.store.u32.0845', 'canonicalize',
    'store:u32', 'canonical operand order and normalized casts',
    'generic', 'always', 6);
  AddRecipe(Result, 'sccp.store.u32.0846', 'sccp',
    'store:u32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.store.u32.0847', 'gvn',
    'store:u32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 8);
  AddRecipe(Result, 'loop.store.u32.0848', 'loop',
    'store:u32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.store.u32.0849', 'machine-combine',
    'store:u32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.gep.u32.0850', 'canonicalize',
    'gep:u32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.gep.u32.0851', 'sccp',
    'gep:u32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.gep.u32.0852', 'gvn',
    'gep:u32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.gep.u32.0853', 'loop',
    'gep:u32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.gep.u32.0854', 'machine-combine',
    'gep:u32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.select.u32.0855', 'canonicalize',
    'select:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 4);
  AddRecipe(Result, 'sccp.select.u32.0856', 'sccp',
    'select:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.select.u32.0857', 'gvn',
    'select:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 6);
  AddRecipe(Result, 'loop.select.u32.0858', 'loop',
    'select:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.select.u32.0859', 'machine-combine',
    'select:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.phi.u32.0860', 'canonicalize',
    'phi:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.phi.u32.0861', 'sccp',
    'phi:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.phi.u32.0862', 'gvn',
    'phi:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.phi.u32.0863', 'loop',
    'phi:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.phi.u32.0864', 'machine-combine',
    'phi:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.call.u32.0865', 'canonicalize',
    'call:u32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.call.u32.0866', 'sccp',
    'call:u32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.call.u32.0867', 'gvn',
    'call:u32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.call.u32.0868', 'loop',
    'call:u32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.call.u32.0869', 'machine-combine',
    'call:u32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.add.i64.0870', 'canonicalize',
    'add:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.add.i64.0871', 'sccp',
    'add:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.add.i64.0872', 'gvn',
    'add:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.add.i64.0873', 'loop',
    'add:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.add.i64.0874', 'machine-combine',
    'add:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.sub.i64.0875', 'canonicalize',
    'sub:i64', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.sub.i64.0876', 'sccp',
    'sub:i64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.sub.i64.0877', 'gvn',
    'sub:i64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.sub.i64.0878', 'loop',
    'sub:i64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.sub.i64.0879', 'machine-combine',
    'sub:i64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.mul.i64.0880', 'canonicalize',
    'mul:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.mul.i64.0881', 'sccp',
    'mul:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.mul.i64.0882', 'gvn',
    'mul:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.mul.i64.0883', 'loop',
    'mul:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.mul.i64.0884', 'machine-combine',
    'mul:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.sdiv.i64.0885', 'canonicalize',
    'sdiv:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.sdiv.i64.0886', 'sccp',
    'sdiv:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.sdiv.i64.0887', 'gvn',
    'sdiv:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.sdiv.i64.0888', 'loop',
    'sdiv:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.sdiv.i64.0889', 'machine-combine',
    'sdiv:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.udiv.i64.0890', 'canonicalize',
    'udiv:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.udiv.i64.0891', 'sccp',
    'udiv:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.udiv.i64.0892', 'gvn',
    'udiv:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.udiv.i64.0893', 'loop',
    'udiv:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.udiv.i64.0894', 'machine-combine',
    'udiv:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.srem.i64.0895', 'canonicalize',
    'srem:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.srem.i64.0896', 'sccp',
    'srem:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.srem.i64.0897', 'gvn',
    'srem:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.srem.i64.0898', 'loop',
    'srem:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.srem.i64.0899', 'machine-combine',
    'srem:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.urem.i64.0900', 'canonicalize',
    'urem:i64', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.urem.i64.0901', 'sccp',
    'urem:i64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.urem.i64.0902', 'gvn',
    'urem:i64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.urem.i64.0903', 'loop',
    'urem:i64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.urem.i64.0904', 'machine-combine',
    'urem:i64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.shl.i64.0905', 'canonicalize',
    'shl:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.shl.i64.0906', 'sccp',
    'shl:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.shl.i64.0907', 'gvn',
    'shl:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.shl.i64.0908', 'loop',
    'shl:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.shl.i64.0909', 'machine-combine',
    'shl:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.ashr.i64.0910', 'canonicalize',
    'ashr:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.ashr.i64.0911', 'sccp',
    'ashr:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.ashr.i64.0912', 'gvn',
    'ashr:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.ashr.i64.0913', 'loop',
    'ashr:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.ashr.i64.0914', 'machine-combine',
    'ashr:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.lshr.i64.0915', 'canonicalize',
    'lshr:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.lshr.i64.0916', 'sccp',
    'lshr:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.lshr.i64.0917', 'gvn',
    'lshr:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.lshr.i64.0918', 'loop',
    'lshr:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.lshr.i64.0919', 'machine-combine',
    'lshr:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.and.i64.0920', 'canonicalize',
    'and:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.and.i64.0921', 'sccp',
    'and:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.and.i64.0922', 'gvn',
    'and:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.and.i64.0923', 'loop',
    'and:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.and.i64.0924', 'machine-combine',
    'and:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.or.i64.0925', 'canonicalize',
    'or:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 2);
  AddRecipe(Result, 'sccp.or.i64.0926', 'sccp',
    'or:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.or.i64.0927', 'gvn',
    'or:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 4);
  AddRecipe(Result, 'loop.or.i64.0928', 'loop',
    'or:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.or.i64.0929', 'machine-combine',
    'or:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.xor.i64.0930', 'canonicalize',
    'xor:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.xor.i64.0931', 'sccp',
    'xor:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.xor.i64.0932', 'gvn',
    'xor:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.xor.i64.0933', 'loop',
    'xor:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.xor.i64.0934', 'machine-combine',
    'xor:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.icmp.eq.i64.0935', 'canonicalize',
    'icmp.eq:i64', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.icmp.eq.i64.0936', 'sccp',
    'icmp.eq:i64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.icmp.eq.i64.0937', 'gvn',
    'icmp.eq:i64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.icmp.eq.i64.0938', 'loop',
    'icmp.eq:i64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.icmp.eq.i64.0939', 'machine-combine',
    'icmp.eq:i64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.icmp.ne.i64.0940', 'canonicalize',
    'icmp.ne:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 5);
  AddRecipe(Result, 'sccp.icmp.ne.i64.0941', 'sccp',
    'icmp.ne:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.icmp.ne.i64.0942', 'gvn',
    'icmp.ne:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 7);
  AddRecipe(Result, 'loop.icmp.ne.i64.0943', 'loop',
    'icmp.ne:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.icmp.ne.i64.0944', 'machine-combine',
    'icmp.ne:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.icmp.slt.i64.0945', 'canonicalize',
    'icmp.slt:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.icmp.slt.i64.0946', 'sccp',
    'icmp.slt:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.icmp.slt.i64.0947', 'gvn',
    'icmp.slt:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.icmp.slt.i64.0948', 'loop',
    'icmp.slt:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.icmp.slt.i64.0949', 'machine-combine',
    'icmp.slt:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.icmp.sle.i64.0950', 'canonicalize',
    'icmp.sle:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.icmp.sle.i64.0951', 'sccp',
    'icmp.sle:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.icmp.sle.i64.0952', 'gvn',
    'icmp.sle:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.icmp.sle.i64.0953', 'loop',
    'icmp.sle:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.icmp.sle.i64.0954', 'machine-combine',
    'icmp.sle:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.icmp.sgt.i64.0955', 'canonicalize',
    'icmp.sgt:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.icmp.sgt.i64.0956', 'sccp',
    'icmp.sgt:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.icmp.sgt.i64.0957', 'gvn',
    'icmp.sgt:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.icmp.sgt.i64.0958', 'loop',
    'icmp.sgt:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.icmp.sgt.i64.0959', 'machine-combine',
    'icmp.sgt:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.icmp.sge.i64.0960', 'canonicalize',
    'icmp.sge:i64', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.icmp.sge.i64.0961', 'sccp',
    'icmp.sge:i64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.icmp.sge.i64.0962', 'gvn',
    'icmp.sge:i64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.icmp.sge.i64.0963', 'loop',
    'icmp.sge:i64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.icmp.sge.i64.0964', 'machine-combine',
    'icmp.sge:i64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.fadd.i64.0965', 'canonicalize',
    'fadd:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.fadd.i64.0966', 'sccp',
    'fadd:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.fadd.i64.0967', 'gvn',
    'fadd:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.fadd.i64.0968', 'loop',
    'fadd:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.fadd.i64.0969', 'machine-combine',
    'fadd:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.fsub.i64.0970', 'canonicalize',
    'fsub:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.fsub.i64.0971', 'sccp',
    'fsub:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.fsub.i64.0972', 'gvn',
    'fsub:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.fsub.i64.0973', 'loop',
    'fsub:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.fsub.i64.0974', 'machine-combine',
    'fsub:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.fmul.i64.0975', 'canonicalize',
    'fmul:i64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.fmul.i64.0976', 'sccp',
    'fmul:i64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.fmul.i64.0977', 'gvn',
    'fmul:i64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.fmul.i64.0978', 'loop',
    'fmul:i64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.fmul.i64.0979', 'machine-combine',
    'fmul:i64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.fdiv.i64.0980', 'canonicalize',
    'fdiv:i64', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.fdiv.i64.0981', 'sccp',
    'fdiv:i64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.fdiv.i64.0982', 'gvn',
    'fdiv:i64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.fdiv.i64.0983', 'loop',
    'fdiv:i64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.fdiv.i64.0984', 'machine-combine',
    'fdiv:i64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.load.i64.0985', 'canonicalize',
    'load:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.load.i64.0986', 'sccp',
    'load:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.load.i64.0987', 'gvn',
    'load:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.load.i64.0988', 'loop',
    'load:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.load.i64.0989', 'machine-combine',
    'load:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.store.i64.0990', 'canonicalize',
    'store:i64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 7);
  AddRecipe(Result, 'sccp.store.i64.0991', 'sccp',
    'store:i64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.store.i64.0992', 'gvn',
    'store:i64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 9);
  AddRecipe(Result, 'loop.store.i64.0993', 'loop',
    'store:i64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.store.i64.0994', 'machine-combine',
    'store:i64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.gep.i64.0995', 'canonicalize',
    'gep:i64', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.gep.i64.0996', 'sccp',
    'gep:i64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.gep.i64.0997', 'gvn',
    'gep:i64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.gep.i64.0998', 'loop',
    'gep:i64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.gep.i64.0999', 'machine-combine',
    'gep:i64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.select.i64.1000', 'canonicalize',
    'select:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 5);
  AddRecipe(Result, 'sccp.select.i64.1001', 'sccp',
    'select:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.select.i64.1002', 'gvn',
    'select:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 7);
  AddRecipe(Result, 'loop.select.i64.1003', 'loop',
    'select:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.select.i64.1004', 'machine-combine',
    'select:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.phi.i64.1005', 'canonicalize',
    'phi:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 10);
  AddRecipe(Result, 'sccp.phi.i64.1006', 'sccp',
    'phi:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.phi.i64.1007', 'gvn',
    'phi:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 12);
  AddRecipe(Result, 'loop.phi.i64.1008', 'loop',
    'phi:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.phi.i64.1009', 'machine-combine',
    'phi:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.call.i64.1010', 'canonicalize',
    'call:i64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.call.i64.1011', 'sccp',
    'call:i64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.call.i64.1012', 'gvn',
    'call:i64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.call.i64.1013', 'loop',
    'call:i64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.call.i64.1014', 'machine-combine',
    'call:i64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.add.u64.1015', 'canonicalize',
    'add:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.add.u64.1016', 'sccp',
    'add:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.add.u64.1017', 'gvn',
    'add:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.add.u64.1018', 'loop',
    'add:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.add.u64.1019', 'machine-combine',
    'add:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.sub.u64.1020', 'canonicalize',
    'sub:u64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.sub.u64.1021', 'sccp',
    'sub:u64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.sub.u64.1022', 'gvn',
    'sub:u64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.sub.u64.1023', 'loop',
    'sub:u64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.sub.u64.1024', 'machine-combine',
    'sub:u64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.mul.u64.1025', 'canonicalize',
    'mul:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.mul.u64.1026', 'sccp',
    'mul:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.mul.u64.1027', 'gvn',
    'mul:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.mul.u64.1028', 'loop',
    'mul:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.mul.u64.1029', 'machine-combine',
    'mul:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.sdiv.u64.1030', 'canonicalize',
    'sdiv:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.sdiv.u64.1031', 'sccp',
    'sdiv:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.sdiv.u64.1032', 'gvn',
    'sdiv:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.sdiv.u64.1033', 'loop',
    'sdiv:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.sdiv.u64.1034', 'machine-combine',
    'sdiv:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.udiv.u64.1035', 'canonicalize',
    'udiv:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.udiv.u64.1036', 'sccp',
    'udiv:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.udiv.u64.1037', 'gvn',
    'udiv:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.udiv.u64.1038', 'loop',
    'udiv:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.udiv.u64.1039', 'machine-combine',
    'udiv:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.srem.u64.1040', 'canonicalize',
    'srem:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.srem.u64.1041', 'sccp',
    'srem:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.srem.u64.1042', 'gvn',
    'srem:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.srem.u64.1043', 'loop',
    'srem:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.srem.u64.1044', 'machine-combine',
    'srem:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.urem.u64.1045', 'canonicalize',
    'urem:u64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.urem.u64.1046', 'sccp',
    'urem:u64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.urem.u64.1047', 'gvn',
    'urem:u64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.urem.u64.1048', 'loop',
    'urem:u64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.urem.u64.1049', 'machine-combine',
    'urem:u64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.shl.u64.1050', 'canonicalize',
    'shl:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.shl.u64.1051', 'sccp',
    'shl:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.shl.u64.1052', 'gvn',
    'shl:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.shl.u64.1053', 'loop',
    'shl:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.shl.u64.1054', 'machine-combine',
    'shl:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.ashr.u64.1055', 'canonicalize',
    'ashr:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.ashr.u64.1056', 'sccp',
    'ashr:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.ashr.u64.1057', 'gvn',
    'ashr:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.ashr.u64.1058', 'loop',
    'ashr:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.ashr.u64.1059', 'machine-combine',
    'ashr:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.lshr.u64.1060', 'canonicalize',
    'lshr:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.lshr.u64.1061', 'sccp',
    'lshr:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.lshr.u64.1062', 'gvn',
    'lshr:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.lshr.u64.1063', 'loop',
    'lshr:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.lshr.u64.1064', 'machine-combine',
    'lshr:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.and.u64.1065', 'canonicalize',
    'and:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 10);
  AddRecipe(Result, 'sccp.and.u64.1066', 'sccp',
    'and:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.and.u64.1067', 'gvn',
    'and:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 12);
  AddRecipe(Result, 'loop.and.u64.1068', 'loop',
    'and:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.and.u64.1069', 'machine-combine',
    'and:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.or.u64.1070', 'canonicalize',
    'or:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 3);
  AddRecipe(Result, 'sccp.or.u64.1071', 'sccp',
    'or:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.or.u64.1072', 'gvn',
    'or:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 5);
  AddRecipe(Result, 'loop.or.u64.1073', 'loop',
    'or:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.or.u64.1074', 'machine-combine',
    'or:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.xor.u64.1075', 'canonicalize',
    'xor:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.xor.u64.1076', 'sccp',
    'xor:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.xor.u64.1077', 'gvn',
    'xor:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.xor.u64.1078', 'loop',
    'xor:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.xor.u64.1079', 'machine-combine',
    'xor:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.icmp.eq.u64.1080', 'canonicalize',
    'icmp.eq:u64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.icmp.eq.u64.1081', 'sccp',
    'icmp.eq:u64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.icmp.eq.u64.1082', 'gvn',
    'icmp.eq:u64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.icmp.eq.u64.1083', 'loop',
    'icmp.eq:u64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.icmp.eq.u64.1084', 'machine-combine',
    'icmp.eq:u64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.icmp.ne.u64.1085', 'canonicalize',
    'icmp.ne:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 6);
  AddRecipe(Result, 'sccp.icmp.ne.u64.1086', 'sccp',
    'icmp.ne:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.icmp.ne.u64.1087', 'gvn',
    'icmp.ne:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 8);
  AddRecipe(Result, 'loop.icmp.ne.u64.1088', 'loop',
    'icmp.ne:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.icmp.ne.u64.1089', 'machine-combine',
    'icmp.ne:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.icmp.slt.u64.1090', 'canonicalize',
    'icmp.slt:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.icmp.slt.u64.1091', 'sccp',
    'icmp.slt:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.icmp.slt.u64.1092', 'gvn',
    'icmp.slt:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.icmp.slt.u64.1093', 'loop',
    'icmp.slt:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.icmp.slt.u64.1094', 'machine-combine',
    'icmp.slt:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.icmp.sle.u64.1095', 'canonicalize',
    'icmp.sle:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.icmp.sle.u64.1096', 'sccp',
    'icmp.sle:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.icmp.sle.u64.1097', 'gvn',
    'icmp.sle:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.icmp.sle.u64.1098', 'loop',
    'icmp.sle:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.icmp.sle.u64.1099', 'machine-combine',
    'icmp.sle:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.icmp.sgt.u64.1100', 'canonicalize',
    'icmp.sgt:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 9);
  AddRecipe(Result, 'sccp.icmp.sgt.u64.1101', 'sccp',
    'icmp.sgt:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.icmp.sgt.u64.1102', 'gvn',
    'icmp.sgt:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 11);
  AddRecipe(Result, 'loop.icmp.sgt.u64.1103', 'loop',
    'icmp.sgt:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.icmp.sgt.u64.1104', 'machine-combine',
    'icmp.sgt:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.icmp.sge.u64.1105', 'canonicalize',
    'icmp.sge:u64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 2);
  AddRecipe(Result, 'sccp.icmp.sge.u64.1106', 'sccp',
    'icmp.sge:u64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.icmp.sge.u64.1107', 'gvn',
    'icmp.sge:u64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 4);
  AddRecipe(Result, 'loop.icmp.sge.u64.1108', 'loop',
    'icmp.sge:u64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.icmp.sge.u64.1109', 'machine-combine',
    'icmp.sge:u64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.fadd.u64.1110', 'canonicalize',
    'fadd:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 7);
  AddRecipe(Result, 'sccp.fadd.u64.1111', 'sccp',
    'fadd:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.fadd.u64.1112', 'gvn',
    'fadd:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 9);
  AddRecipe(Result, 'loop.fadd.u64.1113', 'loop',
    'fadd:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.fadd.u64.1114', 'machine-combine',
    'fadd:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.fsub.u64.1115', 'canonicalize',
    'fsub:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.fsub.u64.1116', 'sccp',
    'fsub:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.fsub.u64.1117', 'gvn',
    'fsub:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.fsub.u64.1118', 'loop',
    'fsub:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.fsub.u64.1119', 'machine-combine',
    'fsub:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.fmul.u64.1120', 'canonicalize',
    'fmul:u64', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.fmul.u64.1121', 'sccp',
    'fmul:u64', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.fmul.u64.1122', 'gvn',
    'fmul:u64', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.fmul.u64.1123', 'loop',
    'fmul:u64', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.fmul.u64.1124', 'machine-combine',
    'fmul:u64', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.fdiv.u64.1125', 'canonicalize',
    'fdiv:u64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.fdiv.u64.1126', 'sccp',
    'fdiv:u64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.fdiv.u64.1127', 'gvn',
    'fdiv:u64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.fdiv.u64.1128', 'loop',
    'fdiv:u64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.fdiv.u64.1129', 'machine-combine',
    'fdiv:u64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.load.u64.1130', 'canonicalize',
    'load:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.load.u64.1131', 'sccp',
    'load:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.load.u64.1132', 'gvn',
    'load:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.load.u64.1133', 'loop',
    'load:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.load.u64.1134', 'machine-combine',
    'load:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.store.u64.1135', 'canonicalize',
    'store:u64', 'canonical operand order and normalized casts',
    'aarch64', 'always', 8);
  AddRecipe(Result, 'sccp.store.u64.1136', 'sccp',
    'store:u64', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.store.u64.1137', 'gvn',
    'store:u64', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 10);
  AddRecipe(Result, 'loop.store.u64.1138', 'loop',
    'store:u64', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.store.u64.1139', 'machine-combine',
    'store:u64', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.gep.u64.1140', 'canonicalize',
    'gep:u64', 'canonical operand order and normalized casts',
    'riscv64', 'always', 1);
  AddRecipe(Result, 'sccp.gep.u64.1141', 'sccp',
    'gep:u64', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.gep.u64.1142', 'gvn',
    'gep:u64', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 3);
  AddRecipe(Result, 'loop.gep.u64.1143', 'loop',
    'gep:u64', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.gep.u64.1144', 'machine-combine',
    'gep:u64', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.select.u64.1145', 'canonicalize',
    'select:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 6);
  AddRecipe(Result, 'sccp.select.u64.1146', 'sccp',
    'select:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.select.u64.1147', 'gvn',
    'select:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 8);
  AddRecipe(Result, 'loop.select.u64.1148', 'loop',
    'select:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.select.u64.1149', 'machine-combine',
    'select:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.phi.u64.1150', 'canonicalize',
    'phi:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.phi.u64.1151', 'sccp',
    'phi:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.phi.u64.1152', 'gvn',
    'phi:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.phi.u64.1153', 'loop',
    'phi:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.phi.u64.1154', 'machine-combine',
    'phi:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.call.u64.1155', 'canonicalize',
    'call:u64', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.call.u64.1156', 'sccp',
    'call:u64', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.call.u64.1157', 'gvn',
    'call:u64', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.call.u64.1158', 'loop',
    'call:u64', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.call.u64.1159', 'machine-combine',
    'call:u64', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.add.f32.1160', 'canonicalize',
    'add:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.add.f32.1161', 'sccp',
    'add:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.add.f32.1162', 'gvn',
    'add:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.add.f32.1163', 'loop',
    'add:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.add.f32.1164', 'machine-combine',
    'add:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.sub.f32.1165', 'canonicalize',
    'sub:f32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.sub.f32.1166', 'sccp',
    'sub:f32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.sub.f32.1167', 'gvn',
    'sub:f32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.sub.f32.1168', 'loop',
    'sub:f32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.sub.f32.1169', 'machine-combine',
    'sub:f32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.mul.f32.1170', 'canonicalize',
    'mul:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.mul.f32.1171', 'sccp',
    'mul:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.mul.f32.1172', 'gvn',
    'mul:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.mul.f32.1173', 'loop',
    'mul:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.mul.f32.1174', 'machine-combine',
    'mul:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.sdiv.f32.1175', 'canonicalize',
    'sdiv:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.sdiv.f32.1176', 'sccp',
    'sdiv:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.sdiv.f32.1177', 'gvn',
    'sdiv:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.sdiv.f32.1178', 'loop',
    'sdiv:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.sdiv.f32.1179', 'machine-combine',
    'sdiv:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.udiv.f32.1180', 'canonicalize',
    'udiv:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.udiv.f32.1181', 'sccp',
    'udiv:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.udiv.f32.1182', 'gvn',
    'udiv:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.udiv.f32.1183', 'loop',
    'udiv:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.udiv.f32.1184', 'machine-combine',
    'udiv:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.srem.f32.1185', 'canonicalize',
    'srem:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.srem.f32.1186', 'sccp',
    'srem:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.srem.f32.1187', 'gvn',
    'srem:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.srem.f32.1188', 'loop',
    'srem:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.srem.f32.1189', 'machine-combine',
    'srem:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.urem.f32.1190', 'canonicalize',
    'urem:f32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.urem.f32.1191', 'sccp',
    'urem:f32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.urem.f32.1192', 'gvn',
    'urem:f32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.urem.f32.1193', 'loop',
    'urem:f32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.urem.f32.1194', 'machine-combine',
    'urem:f32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.shl.f32.1195', 'canonicalize',
    'shl:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 8);
  AddRecipe(Result, 'sccp.shl.f32.1196', 'sccp',
    'shl:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.shl.f32.1197', 'gvn',
    'shl:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 10);
  AddRecipe(Result, 'loop.shl.f32.1198', 'loop',
    'shl:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.shl.f32.1199', 'machine-combine',
    'shl:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.ashr.f32.1200', 'canonicalize',
    'ashr:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.ashr.f32.1201', 'sccp',
    'ashr:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.ashr.f32.1202', 'gvn',
    'ashr:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.ashr.f32.1203', 'loop',
    'ashr:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.ashr.f32.1204', 'machine-combine',
    'ashr:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.lshr.f32.1205', 'canonicalize',
    'lshr:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.lshr.f32.1206', 'sccp',
    'lshr:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.lshr.f32.1207', 'gvn',
    'lshr:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.lshr.f32.1208', 'loop',
    'lshr:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.lshr.f32.1209', 'machine-combine',
    'lshr:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.and.f32.1210', 'canonicalize',
    'and:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 11);
  AddRecipe(Result, 'sccp.and.f32.1211', 'sccp',
    'and:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.and.f32.1212', 'gvn',
    'and:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 1);
  AddRecipe(Result, 'loop.and.f32.1213', 'loop',
    'and:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.and.f32.1214', 'machine-combine',
    'and:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.or.f32.1215', 'canonicalize',
    'or:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 4);
  AddRecipe(Result, 'sccp.or.f32.1216', 'sccp',
    'or:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.or.f32.1217', 'gvn',
    'or:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 6);
  AddRecipe(Result, 'loop.or.f32.1218', 'loop',
    'or:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.or.f32.1219', 'machine-combine',
    'or:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.xor.f32.1220', 'canonicalize',
    'xor:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 9);
  AddRecipe(Result, 'sccp.xor.f32.1221', 'sccp',
    'xor:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.xor.f32.1222', 'gvn',
    'xor:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 11);
  AddRecipe(Result, 'loop.xor.f32.1223', 'loop',
    'xor:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.xor.f32.1224', 'machine-combine',
    'xor:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.icmp.eq.f32.1225', 'canonicalize',
    'icmp.eq:f32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.icmp.eq.f32.1226', 'sccp',
    'icmp.eq:f32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.icmp.eq.f32.1227', 'gvn',
    'icmp.eq:f32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.icmp.eq.f32.1228', 'loop',
    'icmp.eq:f32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.icmp.eq.f32.1229', 'machine-combine',
    'icmp.eq:f32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.icmp.ne.f32.1230', 'canonicalize',
    'icmp.ne:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 7);
  AddRecipe(Result, 'sccp.icmp.ne.f32.1231', 'sccp',
    'icmp.ne:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.icmp.ne.f32.1232', 'gvn',
    'icmp.ne:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 9);
  AddRecipe(Result, 'loop.icmp.ne.f32.1233', 'loop',
    'icmp.ne:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.icmp.ne.f32.1234', 'machine-combine',
    'icmp.ne:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.icmp.slt.f32.1235', 'canonicalize',
    'icmp.slt:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 12);
  AddRecipe(Result, 'sccp.icmp.slt.f32.1236', 'sccp',
    'icmp.slt:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.icmp.slt.f32.1237', 'gvn',
    'icmp.slt:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 2);
  AddRecipe(Result, 'loop.icmp.slt.f32.1238', 'loop',
    'icmp.slt:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.icmp.slt.f32.1239', 'machine-combine',
    'icmp.slt:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 4);
  AddRecipe(Result, 'canonicalize.icmp.sle.f32.1240', 'canonicalize',
    'icmp.sle:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 5);
  AddRecipe(Result, 'sccp.icmp.sle.f32.1241', 'sccp',
    'icmp.sle:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 6);
  AddRecipe(Result, 'gvn.icmp.sle.f32.1242', 'gvn',
    'icmp.sle:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 7);
  AddRecipe(Result, 'loop.icmp.sle.f32.1243', 'loop',
    'icmp.sle:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 8);
  AddRecipe(Result, 'machine-combine.icmp.sle.f32.1244', 'machine-combine',
    'icmp.sle:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 9);
  AddRecipe(Result, 'canonicalize.icmp.sgt.f32.1245', 'canonicalize',
    'icmp.sgt:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 10);
  AddRecipe(Result, 'sccp.icmp.sgt.f32.1246', 'sccp',
    'icmp.sgt:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 11);
  AddRecipe(Result, 'gvn.icmp.sgt.f32.1247', 'gvn',
    'icmp.sgt:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 12);
  AddRecipe(Result, 'loop.icmp.sgt.f32.1248', 'loop',
    'icmp.sgt:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 1);
  AddRecipe(Result, 'machine-combine.icmp.sgt.f32.1249', 'machine-combine',
    'icmp.sgt:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 2);
  AddRecipe(Result, 'canonicalize.icmp.sge.f32.1250', 'canonicalize',
    'icmp.sge:f32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 3);
  AddRecipe(Result, 'sccp.icmp.sge.f32.1251', 'sccp',
    'icmp.sge:f32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 4);
  AddRecipe(Result, 'gvn.icmp.sge.f32.1252', 'gvn',
    'icmp.sge:f32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 5);
  AddRecipe(Result, 'loop.icmp.sge.f32.1253', 'loop',
    'icmp.sge:f32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 6);
  AddRecipe(Result, 'machine-combine.icmp.sge.f32.1254', 'machine-combine',
    'icmp.sge:f32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 7);
  AddRecipe(Result, 'canonicalize.fadd.f32.1255', 'canonicalize',
    'fadd:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 8);
  AddRecipe(Result, 'sccp.fadd.f32.1256', 'sccp',
    'fadd:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 9);
  AddRecipe(Result, 'gvn.fadd.f32.1257', 'gvn',
    'fadd:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 10);
  AddRecipe(Result, 'loop.fadd.f32.1258', 'loop',
    'fadd:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 11);
  AddRecipe(Result, 'machine-combine.fadd.f32.1259', 'machine-combine',
    'fadd:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 12);
  AddRecipe(Result, 'canonicalize.fsub.f32.1260', 'canonicalize',
    'fsub:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 1);
  AddRecipe(Result, 'sccp.fsub.f32.1261', 'sccp',
    'fsub:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 2);
  AddRecipe(Result, 'gvn.fsub.f32.1262', 'gvn',
    'fsub:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 3);
  AddRecipe(Result, 'loop.fsub.f32.1263', 'loop',
    'fsub:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 4);
  AddRecipe(Result, 'machine-combine.fsub.f32.1264', 'machine-combine',
    'fsub:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 5);
  AddRecipe(Result, 'canonicalize.fmul.f32.1265', 'canonicalize',
    'fmul:f32', 'canonical operand order and normalized casts',
    'riscv64', 'always', 6);
  AddRecipe(Result, 'sccp.fmul.f32.1266', 'sccp',
    'fmul:f32', 'replace with lattice constant when executable inputs agree',
    'aarch64', 'no-overflow', 7);
  AddRecipe(Result, 'gvn.fmul.f32.1267', 'gvn',
    'fmul:f32', 'reuse dominating equivalent expression',
    'x86_64', 'fast-math', 8);
  AddRecipe(Result, 'loop.fmul.f32.1268', 'loop',
    'fmul:f32', 'hoist or strength-reduce invariant operation',
    'generic', 'non-trapping', 9);
  AddRecipe(Result, 'machine-combine.fmul.f32.1269', 'machine-combine',
    'fmul:f32', 'select compact target instruction sequence',
    'riscv64', 'alias-safe', 10);
  AddRecipe(Result, 'canonicalize.fdiv.f32.1270', 'canonicalize',
    'fdiv:f32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 11);
  AddRecipe(Result, 'sccp.fdiv.f32.1271', 'sccp',
    'fdiv:f32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 12);
  AddRecipe(Result, 'gvn.fdiv.f32.1272', 'gvn',
    'fdiv:f32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 1);
  AddRecipe(Result, 'loop.fdiv.f32.1273', 'loop',
    'fdiv:f32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 2);
  AddRecipe(Result, 'machine-combine.fdiv.f32.1274', 'machine-combine',
    'fdiv:f32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 3);
  AddRecipe(Result, 'canonicalize.load.f32.1275', 'canonicalize',
    'load:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 4);
  AddRecipe(Result, 'sccp.load.f32.1276', 'sccp',
    'load:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 5);
  AddRecipe(Result, 'gvn.load.f32.1277', 'gvn',
    'load:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 6);
  AddRecipe(Result, 'loop.load.f32.1278', 'loop',
    'load:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 7);
  AddRecipe(Result, 'machine-combine.load.f32.1279', 'machine-combine',
    'load:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 8);
  AddRecipe(Result, 'canonicalize.store.f32.1280', 'canonicalize',
    'store:f32', 'canonical operand order and normalized casts',
    'x86_64', 'always', 9);
  AddRecipe(Result, 'sccp.store.f32.1281', 'sccp',
    'store:f32', 'replace with lattice constant when executable inputs agree',
    'generic', 'no-overflow', 10);
  AddRecipe(Result, 'gvn.store.f32.1282', 'gvn',
    'store:f32', 'reuse dominating equivalent expression',
    'riscv64', 'fast-math', 11);
  AddRecipe(Result, 'loop.store.f32.1283', 'loop',
    'store:f32', 'hoist or strength-reduce invariant operation',
    'aarch64', 'non-trapping', 12);
  AddRecipe(Result, 'machine-combine.store.f32.1284', 'machine-combine',
    'store:f32', 'select compact target instruction sequence',
    'x86_64', 'alias-safe', 1);
  AddRecipe(Result, 'canonicalize.gep.f32.1285', 'canonicalize',
    'gep:f32', 'canonical operand order and normalized casts',
    'aarch64', 'always', 2);
  AddRecipe(Result, 'sccp.gep.f32.1286', 'sccp',
    'gep:f32', 'replace with lattice constant when executable inputs agree',
    'x86_64', 'no-overflow', 3);
  AddRecipe(Result, 'gvn.gep.f32.1287', 'gvn',
    'gep:f32', 'reuse dominating equivalent expression',
    'generic', 'fast-math', 4);
  AddRecipe(Result, 'loop.gep.f32.1288', 'loop',
    'gep:f32', 'hoist or strength-reduce invariant operation',
    'riscv64', 'non-trapping', 5);
  AddRecipe(Result, 'machine-combine.gep.f32.1289', 'machine-combine',
    'gep:f32', 'select compact target instruction sequence',
    'aarch64', 'alias-safe', 6);
  AddRecipe(Result, 'canonicalize.select.f32.1290', 'canonicalize',
    'select:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 7);
  AddRecipe(Result, 'sccp.select.f32.1291', 'sccp',
    'select:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 8);
  AddRecipe(Result, 'gvn.select.f32.1292', 'gvn',
    'select:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 9);
  AddRecipe(Result, 'loop.select.f32.1293', 'loop',
    'select:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 10);
  AddRecipe(Result, 'machine-combine.select.f32.1294', 'machine-combine',
    'select:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 11);
  AddRecipe(Result, 'canonicalize.phi.f32.1295', 'canonicalize',
    'phi:f32', 'canonical operand order and normalized casts',
    'generic', 'always', 12);
  AddRecipe(Result, 'sccp.phi.f32.1296', 'sccp',
    'phi:f32', 'replace with lattice constant when executable inputs agree',
    'riscv64', 'no-overflow', 1);
  AddRecipe(Result, 'gvn.phi.f32.1297', 'gvn',
    'phi:f32', 'reuse dominating equivalent expression',
    'aarch64', 'fast-math', 2);
  AddRecipe(Result, 'loop.phi.f32.1298', 'loop',
    'phi:f32', 'hoist or strength-reduce invariant operation',
    'x86_64', 'non-trapping', 3);
  AddRecipe(Result, 'machine-combine.phi.f32.1299', 'machine-combine',
    'phi:f32', 'select compact target instruction sequence',
    'generic', 'alias-safe', 4);
end;

function FindOptimizationRecipe(const ACatalog: TOptimizationRecipeArray;
  const AName: string; out ARecipe: TOptimizationRecipe): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if ACatalog[I].Name = AName then begin ARecipe := ACatalog[I]; Exit(True); end;
  ARecipe.Name := ''; ARecipe.Phase := ''; ARecipe.Pattern := '';
  ARecipe.Replacement := ''; ARecipe.Target := ''; ARecipe.SafetyRule := '';
  ARecipe.Profitability := 0; Result := False;
end;

function OptimizationRecipeSummary(const ACatalog: TOptimizationRecipeArray): string;
var I, GenericCount, TargetCount: LongInt;
begin
  GenericCount := 0; TargetCount := 0;
  for I := 0 to High(ACatalog) do if ACatalog[I].Target = 'generic' then Inc(GenericCount) else Inc(TargetCount);
  Result := Format('%d optimization recipes (%d generic, %d target-specific)', [Length(ACatalog), GenericCount, TargetCount]);
end;

end.
