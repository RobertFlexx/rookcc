unit rcc_value_numbering;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_ir;

type
  TValueNumberingStats = record
    ExpressionsVisited: QWord;
    RedundantExpressions: QWord;
    LoadsForwarded: QWord;
    TableResets: QWord;
  end;

procedure RunLocalValueNumbering(AFunction: TIRFunction;
  out AStats: TValueNumberingStats);

implementation

function ExpressionKey(AInstruction: TIRInstruction): string;
var
  I: LongInt;
  Left, Right: TIRValue;
begin
  Result := IROpcodeName(AInstruction.Opcode) + ':' +
    IRTypeName(AInstruction.ResultType) + ':' +
    IntToStr(AInstruction.Immediate) + ':' + AInstruction.Symbol;
  if AInstruction.IsCommutative and (Length(AInstruction.Operands) = 2) then
  begin
    Left := AInstruction.Operands[0];
    Right := AInstruction.Operands[1];
    if Left > Right then
    begin
      I := Left;
      Left := Right;
      Right := I;
    end;
    Result := Result + ':' + IntToStr(Left) + ':' + IntToStr(Right);
  end
  else
    for I := 0 to High(AInstruction.Operands) do
      Result := Result + ':' + IntToStr(AInstruction.Operands[I]);
end;

function EligibleForNumbering(AInstruction: TIRInstruction): Boolean;
begin
  Result := (AInstruction <> nil) and AInstruction.HasResult and
    not AInstruction.HasSideEffects and
    not (AInstruction.Opcode in [iroNop, iroOpaque, iroUndef,
      iroParameter, iroAlloca, iroLoad, iroPhi, iroCall, iroIntrinsic]);
end;

procedure MakeCopy(AInstruction: TIRInstruction; AValue: TIRValue);
begin
  AInstruction.Opcode := iroCopy;
  SetLength(AInstruction.Operands, 1);
  AInstruction.Operands[0] := AValue;
  AInstruction.Immediate := 0;
  AInstruction.UnsignedImmediate := 0;
  AInstruction.Symbol := '';
  AInstruction.Text := '';
end;

procedure RunLocalValueNumbering(AFunction: TIRFunction;
  out AStats: TValueNumberingStats);
var
  Table: TStringList;
  I, J, Index: LongInt;
  Instruction: TIRInstruction;
  Key: string;
  ExistingValue: TIRValue;
begin
  AStats.ExpressionsVisited := 0;
  AStats.RedundantExpressions := 0;
  AStats.LoadsForwarded := 0;
  AStats.TableResets := 0;
  Table := TStringList.Create;
  try
    Table.Sorted := True;
    Table.Duplicates := dupIgnore;
    for I := 0 to High(AFunction.Blocks) do
    begin
      Table.Clear;
      Inc(AStats.TableResets);
      for J := 0 to High(AFunction.Blocks[I].Instructions) do
      begin
        Instruction := AFunction.Blocks[I].Instructions[J];
        if Instruction.Opcode in [iroStore, iroCall, iroIntrinsic,
          iroOpaque] then
        begin
          Table.Clear;
          Inc(AStats.TableResets);
          Continue;
        end;
        if not EligibleForNumbering(Instruction) then Continue;
        Inc(AStats.ExpressionsVisited);
        Key := ExpressionKey(Instruction);
        Index := Table.IndexOfName(Key);
        if Index >= 0 then
        begin
          ExistingValue := StrToIntDef(Table.ValueFromIndex[Index], -1);
          if ExistingValue >= 0 then
          begin
            MakeCopy(Instruction, ExistingValue);
            Inc(AStats.RedundantExpressions);
          end;
        end
        else
          Table.Add(Key + '=' + IntToStr(Instruction.ResultValue));
      end;
    end;
  finally
    Table.Free;
  end;
  AFunction.RebuildValueDefinitions;
end;

end.
