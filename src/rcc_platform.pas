unit rcc_platform;

{$mode objfpc}{$H+}

interface





implementation

uses
  rcc_arch,
  rcc_abi,
  rcc_archive,
  rcc_codegen_registry,
  rcc_cross_backend,
  rcc_elf_image,
  rcc_gnu_compat,
  rcc_ir,
  rcc_ir_lower,
  rcc_ir_metrics,
  rcc_ir_opt,
  rcc_ir_verify,
  rcc_cfg,
  rcc_liveness,
  rcc_link_plan,
  rcc_machine_ir,
  rcc_object_model,
  rcc_pass_manager,
  rcc_regalloc,
  rcc_relocations,
  rcc_sysroot;

end.
