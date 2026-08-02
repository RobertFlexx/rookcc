unit rcc_relocations;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_arch, rcc_object_model;

type
  TRelocationSemantics = record
    Name: string;
    WidthBits: LongInt;
    Signed: Boolean;
    PCRelative: Boolean;
    UsesAddend: Boolean;
    IsCall: Boolean;
    IsJump: Boolean;
    IsGOT: Boolean;
    IsPLT: Boolean;
    IsTLS: Boolean;
    Scale: LongInt;
    MinValue: Int64;
    MaxValue: Int64;
  end;

function RelocationSemantics(const ATarget: TTargetDescriptor;
  AArchitectureCode: LongWord; AKind: TObjectRelocationKind;
  out ASemantics: TRelocationSemantics): Boolean;
function RelocationFits(const ASemantics: TRelocationSemantics;
  AValue: Int64): Boolean;
function ComputeRelocationValue(const ARelocation: TObjectRelocation;
  ASymbolAddress, APlaceAddress: QWord; out AValue: Int64;
  out AReason: string): Boolean;
function X86RelocationName(ACode: LongWord): string;
function AArch64RelocationName(ACode: LongWord): string;
function RISCVRelocationName(ACode: LongWord): string;
function TargetRelocationName(const ATarget: TTargetDescriptor;
  ACode: LongWord): string;
function RelocationTableText(const ATarget: TTargetDescriptor): string;

implementation

const
  R_X86_64_NONE = 0;
  R_X86_64_64 = 1;
  R_X86_64_PC32 = 2;
  R_X86_64_PLT32 = 4;
  R_X86_64_GOTPCREL = 9;
  R_X86_64_32 = 10;
  R_X86_64_32S = 11;

  R_AARCH64_NONE = 0;
  R_AARCH64_ABS64 = 257;
  R_AARCH64_ABS32 = 258;
  R_AARCH64_PREL64 = 260;
  R_AARCH64_PREL32 = 261;
  R_AARCH64_CALL26 = 283;
  R_AARCH64_JUMP26 = 282;

  R_RISCV_NONE = 0;
  R_RISCV_32 = 1;
  R_RISCV_64 = 2;
  R_RISCV_RELATIVE = 3;
  R_RISCV_BRANCH = 16;
  R_RISCV_JAL = 17;
  R_RISCV_CALL = 18;
  R_RISCV_CALL_PLT = 19;
  R_RISCV_PCREL_HI20 = 23;
  R_RISCV_PCREL_LO12_I = 24;
  R_RISCV_PCREL_LO12_S = 25;

function EmptySemantics: TRelocationSemantics;
begin

  Result.Name := '';
  Result.WidthBits := 0;
  Result.Signed := False;
  Result.PCRelative := False;
  Result.UsesAddend := False;
  Result.IsCall := False;
  Result.IsJump := False;
  Result.IsGOT := False;
  Result.IsPLT := False;
  Result.IsTLS := False;
  Result.Scale := 1;
  Result.MinValue := Low(Int64);
  Result.MaxValue := High(Int64);
end;

procedure SetRange(var S: TRelocationSemantics; ABits: LongInt;
  ASigned: Boolean);
begin
  S.WidthBits := ABits;
  S.Signed := ASigned;
  if ABits >= 64 then
  begin
    S.MinValue := Low(Int64);
    S.MaxValue := High(Int64);
  end
  else if ASigned then
  begin
    S.MinValue := -(Int64(1) shl (ABits - 1));
    S.MaxValue := (Int64(1) shl (ABits - 1)) - 1;
  end
  else
  begin
    S.MinValue := 0;
    S.MaxValue := (Int64(1) shl ABits) - 1;
  end;
end;

function X86RelocationName(ACode: LongWord): string;
begin
  case ACode of
    R_X86_64_NONE: Result := 'R_X86_64_NONE';
    R_X86_64_64: Result := 'R_X86_64_64';
    R_X86_64_PC32: Result := 'R_X86_64_PC32';
    R_X86_64_PLT32: Result := 'R_X86_64_PLT32';
    R_X86_64_GOTPCREL: Result := 'R_X86_64_GOTPCREL';
    R_X86_64_32: Result := 'R_X86_64_32';
    R_X86_64_32S: Result := 'R_X86_64_32S';
  else
    Result := 'R_X86_64_' + IntToStr(ACode);
  end;
end;

function AArch64RelocationName(ACode: LongWord): string;
begin
  case ACode of
    R_AARCH64_NONE: Result := 'R_AARCH64_NONE';
    R_AARCH64_ABS64: Result := 'R_AARCH64_ABS64';
    R_AARCH64_ABS32: Result := 'R_AARCH64_ABS32';
    R_AARCH64_PREL64: Result := 'R_AARCH64_PREL64';
    R_AARCH64_PREL32: Result := 'R_AARCH64_PREL32';
    R_AARCH64_CALL26: Result := 'R_AARCH64_CALL26';
    R_AARCH64_JUMP26: Result := 'R_AARCH64_JUMP26';
  else
    Result := 'R_AARCH64_' + IntToStr(ACode);
  end;
end;

function RISCVRelocationName(ACode: LongWord): string;
begin
  case ACode of
    R_RISCV_NONE: Result := 'R_RISCV_NONE';
    R_RISCV_32: Result := 'R_RISCV_32';
    R_RISCV_64: Result := 'R_RISCV_64';
    R_RISCV_RELATIVE: Result := 'R_RISCV_RELATIVE';
    R_RISCV_BRANCH: Result := 'R_RISCV_BRANCH';
    R_RISCV_JAL: Result := 'R_RISCV_JAL';
    R_RISCV_CALL: Result := 'R_RISCV_CALL';
    R_RISCV_CALL_PLT: Result := 'R_RISCV_CALL_PLT';
    R_RISCV_PCREL_HI20: Result := 'R_RISCV_PCREL_HI20';
    R_RISCV_PCREL_LO12_I: Result := 'R_RISCV_PCREL_LO12_I';
    R_RISCV_PCREL_LO12_S: Result := 'R_RISCV_PCREL_LO12_S';
  else
    Result := 'R_RISCV_' + IntToStr(ACode);
  end;
end;

function TargetRelocationName(const ATarget: TTargetDescriptor;
  ACode: LongWord): string;
begin
  case ATarget.Architecture of
    archX86_64: Result := X86RelocationName(ACode);
    archAArch64: Result := AArch64RelocationName(ACode);
    archRISCV64: Result := RISCVRelocationName(ACode);
  else
    Result := 'R_UNKNOWN_' + IntToStr(ACode);
  end;
end;

function RelocationSemantics(const ATarget: TTargetDescriptor;
  AArchitectureCode: LongWord; AKind: TObjectRelocationKind;
  out ASemantics: TRelocationSemantics): Boolean;
begin
  ASemantics := EmptySemantics;
  ASemantics.Name := TargetRelocationName(ATarget, AArchitectureCode);
  ASemantics.UsesAddend := True;
  ASemantics.PCRelative := AKind in [orkPCRelative8, orkPCRelative16,
    orkPCRelative32, orkPCRelative64, orkCall, orkJump, orkPLT];
  ASemantics.IsCall := AKind = orkCall;
  ASemantics.IsJump := AKind = orkJump;
  ASemantics.IsGOT := AKind = orkGOT;
  ASemantics.IsPLT := AKind = orkPLT;
  ASemantics.IsTLS := AKind = orkTLS;
  case ATarget.Architecture of
    archX86_64:
      case AArchitectureCode of
        R_X86_64_64: SetRange(ASemantics, 64, False);
        R_X86_64_PC32, R_X86_64_PLT32, R_X86_64_GOTPCREL:
          begin SetRange(ASemantics, 32, True); ASemantics.PCRelative := True; end;
        R_X86_64_32: SetRange(ASemantics, 32, False);
        R_X86_64_32S: SetRange(ASemantics, 32, True);
      else Exit(False); end;
    archAArch64:
      case AArchitectureCode of
        R_AARCH64_ABS64: SetRange(ASemantics, 64, False);
        R_AARCH64_ABS32: SetRange(ASemantics, 32, False);
        R_AARCH64_PREL64:
          begin SetRange(ASemantics, 64, True); ASemantics.PCRelative := True; end;
        R_AARCH64_PREL32:
          begin SetRange(ASemantics, 32, True); ASemantics.PCRelative := True; end;
        R_AARCH64_CALL26, R_AARCH64_JUMP26:
          begin
            SetRange(ASemantics, 28, True);
            ASemantics.Scale := 4;
            ASemantics.PCRelative := True;
            ASemantics.IsCall := AArchitectureCode = R_AARCH64_CALL26;
            ASemantics.IsJump := AArchitectureCode = R_AARCH64_JUMP26;
          end;
      else Exit(False); end;
    archRISCV64:
      case AArchitectureCode of
        R_RISCV_32: SetRange(ASemantics, 32, False);
        R_RISCV_64: SetRange(ASemantics, 64, False);
        R_RISCV_RELATIVE:
          begin SetRange(ASemantics, 64, True); ASemantics.PCRelative := True; end;
        R_RISCV_BRANCH:
          begin SetRange(ASemantics, 13, True); ASemantics.Scale := 2; ASemantics.PCRelative := True; end;
        R_RISCV_JAL:
          begin SetRange(ASemantics, 21, True); ASemantics.Scale := 2; ASemantics.PCRelative := True; ASemantics.IsJump := True; end;
        R_RISCV_CALL, R_RISCV_CALL_PLT:
          begin SetRange(ASemantics, 32, True); ASemantics.PCRelative := True; ASemantics.IsCall := True; end;
        R_RISCV_PCREL_HI20, R_RISCV_PCREL_LO12_I, R_RISCV_PCREL_LO12_S:
          begin SetRange(ASemantics, 32, True); ASemantics.PCRelative := True; end;
      else Exit(False); end;
  else
    Exit(False);
  end;
  Result := True;
end;

function RelocationFits(const ASemantics: TRelocationSemantics;
  AValue: Int64): Boolean;
begin
  if ASemantics.Scale > 1 then
    if (AValue mod ASemantics.Scale) <> 0 then Exit(False);
  Result := (AValue >= ASemantics.MinValue) and
    (AValue <= ASemantics.MaxValue);
end;

function ComputeRelocationValue(const ARelocation: TObjectRelocation;
  ASymbolAddress, APlaceAddress: QWord; out AValue: Int64;
  out AReason: string): Boolean;
var
  Base: Int64;
begin
  AReason := '';
  Base := Int64(ASymbolAddress) + ARelocation.Addend;
  if ARelocation.Kind in [orkPCRelative8, orkPCRelative16,
     orkPCRelative32, orkPCRelative64, orkCall, orkJump, orkPLT,
     orkGOT] then
    AValue := Base - Int64(APlaceAddress)
  else AValue := Base;
  Result := True;
end;

function RelocationTableText(const ATarget: TTargetDescriptor): string;
var
  Lines: TStringList;
  Codes: array[0..15] of LongWord;
  I, Count: LongInt;
begin
  Count := 0;
  case ATarget.Architecture of
    archX86_64:
      begin
        Codes[Count] := R_X86_64_64; Inc(Count);
        Codes[Count] := R_X86_64_PC32; Inc(Count);
        Codes[Count] := R_X86_64_PLT32; Inc(Count);
        Codes[Count] := R_X86_64_GOTPCREL; Inc(Count);
        Codes[Count] := R_X86_64_32; Inc(Count);
        Codes[Count] := R_X86_64_32S; Inc(Count);
      end;
    archAArch64:
      begin
        Codes[Count] := R_AARCH64_ABS64; Inc(Count);
        Codes[Count] := R_AARCH64_ABS32; Inc(Count);
        Codes[Count] := R_AARCH64_PREL64; Inc(Count);
        Codes[Count] := R_AARCH64_PREL32; Inc(Count);
        Codes[Count] := R_AARCH64_CALL26; Inc(Count);
        Codes[Count] := R_AARCH64_JUMP26; Inc(Count);
      end;
    archRISCV64:
      begin
        Codes[Count] := R_RISCV_32; Inc(Count);
        Codes[Count] := R_RISCV_64; Inc(Count);
        Codes[Count] := R_RISCV_RELATIVE; Inc(Count);
        Codes[Count] := R_RISCV_BRANCH; Inc(Count);
        Codes[Count] := R_RISCV_JAL; Inc(Count);
        Codes[Count] := R_RISCV_CALL; Inc(Count);
        Codes[Count] := R_RISCV_CALL_PLT; Inc(Count);
        Codes[Count] := R_RISCV_PCREL_HI20; Inc(Count);
        Codes[Count] := R_RISCV_PCREL_LO12_I; Inc(Count);
        Codes[Count] := R_RISCV_PCREL_LO12_S; Inc(Count);
      end;
  end;
  Lines := TStringList.Create;
  try
    Lines.Add('relocations for ' + ATarget.Triple);
    for I := 0 to Count - 1 do
      Lines.Add('  ' + TargetRelocationName(ATarget, Codes[I]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
