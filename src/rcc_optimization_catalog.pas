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
    ImplementationUnit: string;
    Status: string;
  end;
  TOptimizationRecipeArray = array of TOptimizationRecipe;

function BuildOptimizationRecipeCatalog: TOptimizationRecipeArray;
function FindOptimizationRecipe(const ACatalog: TOptimizationRecipeArray;
  const AName: string; out ARecipe: TOptimizationRecipe): Boolean;
function OptimizationRecipeSummary(const ACatalog: TOptimizationRecipeArray): string;

implementation

procedure AddRecipe(var AValues: TOptimizationRecipeArray;
  const AName, APhase, APattern, AReplacement, ATarget, ASafety,
  AImplementation, AStatus: string; AProfitability: LongInt);
var
  N: LongInt;
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
  AValues[N].ImplementationUnit := AImplementation;
  AValues[N].Status := AStatus;
end;

function BuildOptimizationRecipeCatalog: TOptimizationRecipeArray;
begin
  Result := nil;

  AddRecipe(Result, 'ast-local-cleanup', 'ast',
    'constant and redundant scalar expressions',
    'fold constants simplify expressions and remove dead local work',
    'generic', 'preserve c integer and side effect rules',
    'rcc_opt', 'active', 0);

  AddRecipe(Result, 'ast-inline', 'ast',
    'small side-effect-safe function calls',
    'clone the callee expression into the caller',
    'generic', 'reject volatile and unsafe expression trees',
    'rcc_ast_inline', 'active', 0);

  AddRecipe(Result, 'ast-reachability', 'ast',
    'unreachable static functions and globals',
    'remove objects not reachable from externally visible roots',
    'generic', 'disabled when inline asm makes references opaque',
    'rcc_ast_reachability', 'active', 0);

  AddRecipe(Result, 'ir-core', 'ir',
    'constant copies branches algebraic identities and dead instructions',
    'fold propagate simplify renumber and delete dead ir',
    'generic', 'avoid undefined or trapping constant folds',
    'rcc_ir_opt', 'active', 0);

  AddRecipe(Result, 'cfg-cleanup', 'ir',
    'constant branches redundant branches empty and unreachable blocks',
    'rewrite control flow and remove dead blocks',
    'generic', 'only rewrite proven control flow equivalences',
    'rcc_cfg_cleanup', 'active', 0);

  AddRecipe(Result, 'sccp', 'ir',
    'ssa values and executable control flow',
    'propagate lattice constants and simplify branches',
    'generic', 'overdefine values when constant proof is lost',
    'rcc_sparse_propagation', 'active', 0);

  AddRecipe(Result, 'instcombine', 'ir',
    'algebraic identities casts selects comparisons and power-of-two operations',
    'canonicalize fold and strength reduce',
    'generic', 'apply only identities implemented by the ir combiner',
    'rcc_instcombine', 'active', 0);

  AddRecipe(Result, 'local-value-numbering', 'ir',
    'equivalent expressions within dominance-safe local scope',
    'reuse an existing value and remove redundant computation',
    'generic', 'respect memory and side-effect boundaries',
    'rcc_value_numbering', 'active', 0);

  AddRecipe(Result, 'licm', 'ir',
    'loop invariant non-trapping instructions',
    'move invariant work to the loop preheader',
    'generic', 'requires loop invariance alias safety and non-trapping behavior',
    'rcc_licm', 'active', 0);

  AddRecipe(Result, 'inline-plan', 'ir-analysis',
    'call graph edges and estimated callee cost',
    'rank possible inline candidates',
    'generic', 'planning only no ir rewrite is performed here',
    'rcc_inline_plan', 'analysis-only', 0);

  AddRecipe(Result, 'linear-scan-register-plan', 'machine-analysis',
    'live intervals after ir lowering',
    'assign target registers and spill slots',
    'target', 'respect target register classes reserved and saved registers',
    'rcc_liveness;rcc_regalloc', 'analysis-only', 0);
end;

function FindOptimizationRecipe(const ACatalog: TOptimizationRecipeArray;
  const AName: string; out ARecipe: TOptimizationRecipe): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Name, AName) then
    begin
      ARecipe := ACatalog[I];
      Exit(True);
    end;
  ARecipe := Default(TOptimizationRecipe);
  Result := False;
end;

function OptimizationRecipeSummary(const ACatalog: TOptimizationRecipeArray): string;
var
  I, Active, AnalysisOnly: LongInt;
begin
  Active := 0;
  AnalysisOnly := 0;
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Status, 'active') then Inc(Active)
    else if SameText(ACatalog[I].Status, 'analysis-only') then Inc(AnalysisOnly);
  Result := Format('%d real optimization components (%d active transforms, %d analysis-only)',
    [Length(ACatalog), Active, AnalysisOnly]);
end;

end.
