unit rcc_object_writer;

{$mode objfpc}{$H+}

interface

uses
  rcc_object_model;

procedure WriteRelocatableObject(const AFileName: string;
  AObject: TObjectFile);

implementation

uses
  rcc_types, rcc_arch, rcc_elf_image, rcc_macho;

procedure WriteRelocatableObject(const AFileName: string;
  AObject: TObjectFile);
begin
  if AObject = nil then
    raise ERCCError.Create('internal error: nil relocatable object');
  case AObject.Target.ObjectFormat of
    ofELF64: WriteELF64Relocatable(AFileName, AObject);
    ofMachO64: WriteMachO64Relocatable(AFileName, AObject);
  else
    raise ERCCError.Create('error: unsupported object format ' +
      ObjectFormatName(AObject.Target.ObjectFormat));
  end;
end;

end.
