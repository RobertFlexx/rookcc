#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import shutil
import struct
import subprocess
import sys


ELF_MACHINES = {"x86_64": 62, "aarch64": 183, "riscv64": 243}
ELF_OSABI = {"freebsd": 9, "openbsd": 12, "netbsd": 0}
MACH_CPUS = {"x86_64": 0x01000007, "aarch64": 0x0100000C}
PT_OPENBSD_SYSCALLS = 0x65A3DBE9
LC_SEGMENT_64 = 0x19
LC_SYMTAB = 0x2


def run(*args: str, expect: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode != expect:
        command = " ".join(args)
        raise SystemExit(
            f"{command}: exit {result.returncode}, expected {expect}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def inspect_elf(
    path: pathlib.Path,
    machine: int,
    osabi: int,
    kind: int,
    *,
    check_startup: bool = False,
    required_syscalls: set[int] | None = None,
) -> None:
    data = path.read_bytes()
    if len(data) < 64 or data[:4] != b"\x7fELF":
        raise SystemExit(f"{path}: missing ELF magic")
    if data[4:7] != bytes((2, 1, 1)):
        raise SystemExit(f"{path}: expected ELF64 little-endian version 1")
    if data[7] != osabi:
        raise SystemExit(f"{path}: OSABI {data[7]}, expected {osabi}")
    e_type, e_machine = struct.unpack_from("<HH", data, 16)
    if (e_type, e_machine) != (kind, machine):
        raise SystemExit(
            f"{path}: type/machine {(e_type, e_machine)}, "
            f"expected {(kind, machine)}"
        )
    if kind != 2:
        return
    entry, phoff = struct.unpack_from("<QQ", data, 24)
    phentsize, phnum = struct.unpack_from("<HH", data, 54)
    if entry == 0 or phentsize != 56:
        raise SystemExit(f"{path}: invalid executable entry/program headers")
    program_headers: list[tuple[int, int, int, int, int, int, int, int]] = []
    for index in range(phnum):
        offset = phoff + index * phentsize
        if offset + 56 > len(data):
            raise SystemExit(f"{path}: truncated program header")
        program_headers.append(struct.unpack_from("<IIQQQQQQ", data, offset))
    if osabi == 12:
        pins = [header for header in program_headers if header[0] == PT_OPENBSD_SYSCALLS]
        if len(pins) != 1:
            raise SystemExit(f"{path}: expected one PT_OPENBSD_SYSCALLS segment")
        _, _, file_offset, _, _, file_size, memory_size, alignment = pins[0]
        if file_size < 8 or file_size % 8 or memory_size != file_size or alignment != 4:
            raise SystemExit(f"{path}: malformed OpenBSD syscall pin segment")
        if file_offset + file_size > len(data):
            raise SystemExit(f"{path}: truncated OpenBSD syscall pin table")
        entries = [
            struct.unpack_from("<II", data, file_offset + item)
            for item in range(0, file_size, 8)
        ]
        expected_syscalls = required_syscalls or {1}
        syscall_opcode = {
            62: b"\x0f\x05",
            183: b"\x01\x00\x00\xd4",
            243: b"\x73\x00\x00\x00",
        }[machine]
        for syscall in expected_syscalls:
            syscall_sites = [
                address for address, pinned_syscall in entries
                if pinned_syscall == syscall
            ]
            if not syscall_sites or any(address == 0 for address in syscall_sites):
                raise SystemExit(f"{path}: syscall {syscall} is not pinned")
            for address in syscall_sites:
                executable_segments = [
                    header
                    for header in program_headers
                    if header[0] == 1
                    and header[1] & 1
                    and header[3] <= address < header[3] + header[5]
                ]
                if len(executable_segments) != 1:
                    raise SystemExit(f"{path}: syscall pin is outside executable text")
                text_segment = executable_segments[0]
                instruction_offset = text_segment[2] + address - text_segment[3]
                if data[
                    instruction_offset : instruction_offset + len(syscall_opcode)
                ] != syscall_opcode:
                    raise SystemExit(
                        f"{path}: syscall pin does not name a trap instruction"
                    )
    elif any(header[0] == PT_OPENBSD_SYSCALLS for header in program_headers):
        raise SystemExit(f"{path}: non-OpenBSD image has an OpenBSD syscall segment")

    if check_startup:
        executable_data = b"".join(
            data[header[2] : header[2] + header[5]]
            for header in program_headers
            if header[0] == 1 and header[1] & 1
        )
        expected_syscalls = required_syscalls or {1}
        if machine == 62:
            for syscall in expected_syscalls:
                sequence = b"\xb8" + struct.pack("<I", syscall) + b"\x0f\x05"
                if sequence not in executable_data:
                    raise SystemExit(
                        f"{path}: missing x86-64 syscall sequence {syscall}"
                    )
        elif machine == 183:
            if osabi == 0:
                sequence = struct.pack("<I", 0xD4000021)  # svc #SYS_exit
            else:
                sequence = struct.pack("<II", 0xD2800028, 0xD4000001)
            if sequence not in executable_data:
                raise SystemExit(f"{path}: incorrect AArch64 BSD syscall ABI")
        elif machine == 243:
            syscall_register = 31 if osabi == 0 else 5
            addi = (1 << 20) | (syscall_register << 7) | 0x13
            sequence = struct.pack("<II", addi, 0x00000073)
            if sequence not in executable_data:
                raise SystemExit(f"{path}: incorrect RISC-V BSD syscall ABI")


def elf_relocation_types(path: pathlib.Path) -> set[int]:
    data = path.read_bytes()
    section_offset = struct.unpack_from("<Q", data, 40)[0]
    section_entry_size, section_count = struct.unpack_from("<HH", data, 58)
    if section_entry_size != 64 or section_offset + section_count * 64 > len(data):
        raise SystemExit(f"{path}: invalid ELF section table")
    result: set[int] = set()
    for index in range(section_count):
        header = struct.unpack_from("<IIQQQQIIQQ", data, section_offset + index * 64)
        section_type, file_offset, size, entry_size = header[1], header[4], header[5], header[9]
        if section_type != 4:
            continue
        if entry_size != 24 or file_offset + size > len(data) or size % entry_size:
            raise SystemExit(f"{path}: malformed ELF RELA section")
        for relocation_offset in range(file_offset, file_offset + size, entry_size):
            info = struct.unpack_from("<Q", data, relocation_offset + 8)[0]
            result.add(info & 0xFFFFFFFF)
    return result


def macho_commands(data: bytes) -> list[tuple[int, int, int]]:
    if len(data) < 32:
        raise SystemExit("truncated Mach-O header")
    _, _, _, _, ncmds, sizeofcmds, _, _ = struct.unpack_from("<8I", data, 0)
    if 32 + sizeofcmds > len(data):
        raise SystemExit("truncated Mach-O load commands")
    commands: list[tuple[int, int, int]] = []
    offset = 32
    for _ in range(ncmds):
        command, size = struct.unpack_from("<II", data, offset)
        if size < 8 or offset + size > 32 + sizeofcmds:
            raise SystemExit("invalid Mach-O load command")
        commands.append((command, size, offset))
        offset += size
    if offset != 32 + sizeofcmds:
        raise SystemExit("Mach-O load-command size mismatch")
    return commands


def macho_section_data(path: pathlib.Path, section_name: bytes) -> bytes:
    data = path.read_bytes()
    segments = [entry for entry in macho_commands(data) if entry[0] == LC_SEGMENT_64]
    if len(segments) != 1:
        raise SystemExit(f"{path}: expected one Mach-O segment")
    _, segment_size, segment_offset = segments[0]
    section_count = struct.unpack_from("<I", data, segment_offset + 64)[0]
    if segment_size != 72 + section_count * 80:
        raise SystemExit(f"{path}: malformed Mach-O segment")
    for index in range(section_count):
        section_offset = segment_offset + 72 + index * 80
        fields = struct.unpack_from("<16s16sQQIIIIIIII", data, section_offset)
        name = fields[0].split(b"\0", 1)[0]
        if name == section_name:
            file_offset, size = fields[4], fields[3]
            if file_offset + size > len(data):
                raise SystemExit(f"{path}: truncated Mach-O section")
            return data[file_offset : file_offset + size]
    raise SystemExit(f"{path}: missing Mach-O section {section_name!r}")


def inspect_macho(
    path: pathlib.Path,
    cpu: int,
    required_relocs: set[int],
    required_symbols: set[str] | None = None,
) -> None:
    data = path.read_bytes()
    if len(data) < 32:
        raise SystemExit(f"{path}: truncated Mach-O object")
    magic, actual_cpu, _, file_type, ncmds, _, flags, reserved = struct.unpack_from(
        "<8I", data, 0
    )
    if magic != 0xFEEDFACF or actual_cpu != cpu or file_type != 1:
        raise SystemExit(f"{path}: invalid Mach-O header")
    if ncmds != 4 or not flags & 0x2000 or reserved != 0:
        raise SystemExit(f"{path}: invalid Mach-O object flags/load-command count")
    commands = macho_commands(data)
    segments = [entry for entry in commands if entry[0] == LC_SEGMENT_64]
    symtabs = [entry for entry in commands if entry[0] == LC_SYMTAB]
    if len(segments) != 1 or len(symtabs) != 1:
        raise SystemExit(f"{path}: missing Mach-O segment or symbol table")

    _, segment_size, segment_offset = segments[0]
    section_count = struct.unpack_from("<I", data, segment_offset + 64)[0]
    if segment_size != 72 + section_count * 80 or section_count < 1:
        raise SystemExit(f"{path}: malformed LC_SEGMENT_64")
    relocation_types: set[int] = set()
    saw_text = False
    for index in range(section_count):
        section_offset = segment_offset + 72 + index * 80
        fields = struct.unpack_from("<16s16sQQIIIIIIII", data, section_offset)
        name = fields[0].split(b"\0", 1)[0]
        file_offset, relocation_offset, relocation_count, section_flags = (
            fields[4],
            fields[6],
            fields[7],
            fields[8],
        )
        size = fields[3]
        if name == b"__text":
            saw_text = True
            if section_flags & 0xFF:
                raise SystemExit(f"{path}: __text is not S_REGULAR")
            if section_flags & 0x80000400 != 0x80000400:
                raise SystemExit(f"{path}: __text lacks instruction attributes")
        if size and file_offset + size > len(data):
            raise SystemExit(f"{path}: section data is truncated")
        if relocation_offset + relocation_count * 8 > len(data):
            raise SystemExit(f"{path}: relocation data is truncated")
        for relocation_index in range(relocation_count):
            address, word = struct.unpack_from(
                "<II", data, relocation_offset + relocation_index * 8
            )
            relocation_type = word >> 28
            relocation_types.add(relocation_type)
            symbol_number = word & 0xFFFFFF
            pc_relative = (word >> 24) & 1
            length = (word >> 25) & 3
            external = (word >> 27) & 1
            if (
                cpu == MACH_CPUS["x86_64"]
                and relocation_type == 1
                and pc_relative
                and length == 2
                and not external
            ):
                if not 1 <= symbol_number <= section_count or address + 4 > size:
                    raise SystemExit(f"{path}: invalid local signed relocation")
                displacement = struct.unpack_from(
                    "<i", data, file_offset + address
                )[0]
                target_address = fields[2] + address + 4 + displacement
                target_command_offset = (
                    segment_offset + 72 + (symbol_number - 1) * 80
                )
                target_fields = struct.unpack_from(
                    "<16s16sQQIIIIIIII", data, target_command_offset
                )
                if not target_fields[2] <= target_address < (
                    target_fields[2] + target_fields[3]
                ):
                    raise SystemExit(
                        f"{path}: local signed relocation resolves outside "
                        "its target section"
                    )
            if (
                relocation_type == 0
                and not pc_relative
                and length == 3
                and not external
            ):
                if not 1 <= symbol_number <= section_count or address + 8 > size:
                    raise SystemExit(f"{path}: invalid local absolute relocation")
                target_address = struct.unpack_from(
                    "<Q", data, file_offset + address
                )[0]
                target_command_offset = (
                    segment_offset + 72 + (symbol_number - 1) * 80
                )
                target_fields = struct.unpack_from(
                    "<16s16sQQIIIIIIII", data, target_command_offset
                )
                if not target_fields[2] <= target_address < (
                    target_fields[2] + target_fields[3]
                ):
                    raise SystemExit(
                        f"{path}: local absolute relocation resolves outside "
                        "its target section"
                    )
    if not saw_text:
        raise SystemExit(f"{path}: missing __TEXT,__text")
    if not required_relocs.issubset(relocation_types):
        raise SystemExit(
            f"{path}: relocations {sorted(relocation_types)}, "
            f"expected {sorted(required_relocs)}"
        )

    _, _, symtab_offset = symtabs[0]
    symbol_offset, symbol_count, string_offset, string_size = struct.unpack_from(
        "<IIII", data, symtab_offset + 8
    )
    if symbol_offset + symbol_count * 16 > len(data) or string_offset + string_size > len(data):
        raise SystemExit(f"{path}: truncated Mach-O symbol/string table")
    names: set[str] = set()
    for index in range(symbol_count):
        string_index = struct.unpack_from("<I", data, symbol_offset + index * 16)[0]
        if string_index >= string_size:
            raise SystemExit(f"{path}: invalid Mach-O string index")
        start = string_offset + string_index
        end = data.find(b"\0", start, string_offset + string_size)
        if end < 0:
            raise SystemExit(f"{path}: unterminated Mach-O symbol")
        names.add(data[start:end].decode("ascii"))
    if "_main" not in names:
        raise SystemExit(f"{path}: C symbol _main was not emitted")
    if required_symbols and not required_symbols.issubset(names):
        raise SystemExit(
            f"{path}: symbols {sorted(names)}, expected "
            f"{sorted(required_symbols)}"
        )


def find_ld64() -> str | None:
    found = shutil.which("ld64.lld")
    if found:
        return found
    candidate = pathlib.Path("/usr/lib/llvm/22/bin/ld64.lld")
    return str(candidate) if candidate.is_file() else None


def find_lld() -> str | None:
    found = shutil.which("ld.lld")
    if found:
        return found
    candidate = pathlib.Path("/usr/lib/llvm/22/bin/ld.lld")
    return str(candidate) if candidate.is_file() else None


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: target_format_matrix.py RCC TMPDIR", file=sys.stderr)
        return 2
    compiler = str(pathlib.Path(argv[1]).resolve())
    output = pathlib.Path(argv[2]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    return_source = output / "return42.c"
    globals_source = output / "globals.c"
    external_user_source = output / "external_user.c"
    external_definition_source = output / "external_definition.c"
    macros_source = output / "target_macros.c"
    sysroot_probe_source = output / "sysroot_probe.c"
    mac_layout_source = output / "mac_layout.c"
    mac_hello_source = output / "mac_hello.c"
    mac_variadic_source = output / "mac_variadic.c"
    printf_stub_source = output / "printf_stub.c"
    lseek_source = output / "lseek.c"
    return_source.write_text("int main(void) { return 42; }\n", encoding="utf-8")
    globals_source.write_text(
        "long global_counter = 40;\n"
        "static long global_step = 2;\n"
        "static long bump(void) { global_counter += global_step; "
        "return global_counter; }\n"
        "int main(void) { return (int)bump(); }\n",
        encoding="utf-8",
    )
    external_user_source.write_text(
        "long external_add(long value);\n"
        "int main(void) { return (int)external_add(41); }\n",
        encoding="utf-8",
    )
    external_definition_source.write_text(
        "long external_add(long value) { return value + 1; }\n",
        encoding="utf-8",
    )
    macros_source.write_text(
        "#if defined(__FreeBSD__)\nTARGET_FREEBSD\n"
        "#elif defined(__OpenBSD__)\nTARGET_OPENBSD\n"
        "#elif defined(__NetBSD__)\nTARGET_NETBSD\n"
        "#elif defined(__APPLE__) && defined(__MACH__)\nTARGET_MACOS\n"
        "#else\nTARGET_UNKNOWN\n#endif\n"
        "#ifdef __ELF__\nFORMAT_ELF\n#else\nFORMAT_NOT_ELF\n#endif\n"
        "#ifdef __unix__\nTARGET_UNIX_MACRO\n#else\nTARGET_NO_UNIX_MACRO\n#endif\n",
        encoding="utf-8",
    )
    sysroot_probe_source.write_text(
        "#include <stdint.h>\nSYSROOT_TARGET_HEADER\n", encoding="utf-8"
    )
    mac_layout_source.write_text(
        "#if defined(__aarch64__)\n"
        "_Static_assert(sizeof(long double) == 8, "
        '"Apple arm64 long double layout");\n'
        "#else\n"
        "_Static_assert(sizeof(long double) == 16, "
        '"Apple x86-64 long double layout");\n'
        "#endif\n"
        "int main(void) { return __SIZEOF_LONG_DOUBLE__; }\n",
        encoding="utf-8",
    )
    mac_hello_source.write_text(
        "int printf(const char *format, ...);\n"
        'int main(void) { printf("Hello World!\\n"); return 0; }\n',
        encoding="utf-8",
    )
    mac_variadic_source.write_text(
        "int printf(const char *format, ...);\n"
        'int main(void) { return printf("%d %d", 1, 2); }\n',
        encoding="utf-8",
    )
    printf_stub_source.write_text(
        "int printf(const char *text) { return text != 0; }\n"
        "long write(int descriptor, const void *text, unsigned long size) "
        "{ return size; }\n",
        encoding="utf-8",
    )
    lseek_source.write_text(
        "long lseek(int descriptor, long offset, int origin);\n"
        "int main(void) { return lseek(0, 0, 0) < 0; }\n",
        encoding="utf-8",
    )

    probe_sysroot = output / "probe-sysroot"
    (probe_sysroot / "usr" / "include").mkdir(parents=True, exist_ok=True)
    (probe_sysroot / "usr" / "include" / "stdint.h").write_text(
        "SYSROOT_STDINT_HEADER\n", encoding="utf-8"
    )
    probe_output = output / "sysroot_probe.i"
    run(
        compiler,
        "--target=x86_64-freebsd",
        f"--sysroot={probe_sysroot}",
        "-E",
        str(sysroot_probe_source),
        "-o",
        str(probe_output),
    )
    if "SYSROOT_STDINT_HEADER" not in probe_output.read_text(encoding="utf-8"):
        raise SystemExit("target sysroot headers do not precede generic shims")

    lld = find_lld()
    for os_name, osabi in ELF_OSABI.items():
        preprocessed = output / f"{os_name}-macros.i"
        run(
            compiler,
            f"--target=x86_64-{os_name}",
            "-nostdinc",
            "-E",
            str(macros_source),
            "-o",
            str(preprocessed),
        )
        macro_text = preprocessed.read_text(encoding="utf-8")
        if f"TARGET_{os_name.upper()}" not in macro_text or "FORMAT_ELF" not in macro_text:
            raise SystemExit(f"{os_name}: target predefined macros are incorrect")
        for architecture, machine in ELF_MACHINES.items():
            target = f"{architecture}-unknown-{os_name}-rcc"
            object_path = output / f"{architecture}-{os_name}.o"
            executable_path = output / f"{architecture}-{os_name}"
            external_path = output / f"{architecture}-{os_name}-external.o"
            external_definition_path = (
                output / f"{architecture}-{os_name}-external-definition.o"
            )
            run(
                compiler,
                f"--target={target}",
                "-ffreestanding",
                "-nostdinc",
                "-c",
                str(return_source),
                "-o",
                str(object_path),
            )
            run(
                compiler,
                f"--target={target}",
                "-ffreestanding",
                "-nostdinc",
                str(return_source),
                "-o",
                str(executable_path),
            )
            run(
                compiler,
                f"--target={target}",
                "-nostdinc",
                "-c",
                str(external_user_source),
                "-o",
                str(external_path),
            )
            run(
                compiler,
                f"--target={target}",
                "-nostdinc",
                "-c",
                str(external_definition_source),
                "-o",
                str(external_definition_path),
            )
            inspect_elf(object_path, machine, osabi, 1)
            inspect_elf(external_path, machine, osabi, 1)
            inspect_elf(
                executable_path,
                machine,
                osabi,
                2,
                check_startup=True,
                required_syscalls={1},
            )
            if architecture == "x86_64":
                lseek_path = output / f"{architecture}-{os_name}-lseek"
                run(
                    compiler,
                    f"--target={target}",
                    "-ffreestanding",
                    "-nostdinc",
                    str(lseek_source),
                    "-o",
                    str(lseek_path),
                )
                lseek_syscall = 478 if os_name == "freebsd" else 199
                inspect_elf(
                    lseek_path,
                    machine,
                    osabi,
                    2,
                    check_startup=True,
                    required_syscalls={1, lseek_syscall},
                )
            expected_call_relocation = {
                "x86_64": 4,
                "aarch64": 283,
                "riscv64": 17,
            }[architecture]
            if expected_call_relocation not in elf_relocation_types(external_path):
                raise SystemExit(
                    f"{external_path}: missing external call relocation "
                    f"{expected_call_relocation}"
                )
            if lld:
                linked_path = output / f"{architecture}-{os_name}-object-linked"
                emulation = {
                    "x86_64": "elf_x86_64",
                    "aarch64": "aarch64elf",
                    "riscv64": "elf64lriscv",
                }[architecture]
                run(
                    lld,
                    "-m",
                    emulation,
                    "-e",
                    "main",
                    "-o",
                    str(linked_path),
                    str(external_path),
                    str(external_definition_path),
                )
                linked_osabi = linked_path.read_bytes()[7]
                inspect_elf(linked_path, machine, linked_osabi, 2)

    mac_objects: dict[str, pathlib.Path] = {}
    mac_external_objects: dict[str, tuple[pathlib.Path, pathlib.Path]] = {}
    mac_hello_objects: dict[str, tuple[pathlib.Path, pathlib.Path]] = {}
    mac_preprocessed = output / "macos-macros.i"
    run(
        compiler,
        "--target=x86_64-macos",
        "-nostdinc",
        "-E",
        str(macros_source),
        "-o",
        str(mac_preprocessed),
    )
    mac_macro_text = mac_preprocessed.read_text(encoding="utf-8")
    if (
        "TARGET_MACOS" not in mac_macro_text
        or "FORMAT_NOT_ELF" not in mac_macro_text
        or "TARGET_NO_UNIX_MACRO" not in mac_macro_text
    ):
        raise SystemExit("macOS target predefined macros are incorrect")
    for architecture, cpu in MACH_CPUS.items():
        object_path = output / f"{architecture}-macos.o"
        globals_path = output / f"{architecture}-macos-globals.o"
        external_user_path = output / f"{architecture}-macos-external-user.o"
        external_definition_path = output / f"{architecture}-macos-external-definition.o"
        hello_path = output / f"{architecture}-macos-hello.o"
        printf_stub_path = output / f"{architecture}-macos-printf-stub.o"
        run(
            compiler,
            f"--target={architecture}-macos",
            "-nostdinc",
            "-c",
            str(return_source),
            "-o",
            str(object_path),
        )
        run(
            compiler,
            f"--target={architecture}-macos",
            "-nostdinc",
            "-c",
            str(mac_layout_source),
            "-o",
            str(output / f"{architecture}-macos-layout.o"),
        )
        run(
            compiler,
            f"--target={architecture}-apple-darwin",
            "-nostdinc",
            "-c",
            str(globals_source),
            "-o",
            str(globals_path),
        )
        run(
            compiler,
            f"--target={architecture}-macos",
            "-nostdinc",
            "-c",
            str(external_user_source),
            "-o",
            str(external_user_path),
        )
        run(
            compiler,
            f"--target={architecture}-macos",
            "-nostdinc",
            "-c",
            str(external_definition_source),
            "-o",
            str(external_definition_path),
        )
        run(
            compiler,
            f"--target={architecture}-macos",
            "-nostdinc",
            "-c",
            str(mac_hello_source),
            "-o",
            str(hello_path),
        )
        run(
            compiler,
            f"--target={architecture}-macos",
            "-nostdinc",
            "-c",
            str(printf_stub_source),
            "-o",
            str(printf_stub_path),
        )
        inspect_macho(object_path, cpu, set())
        inspect_macho(
            globals_path,
            cpu,
            {1} if architecture == "x86_64" else {3, 4},
        )
        inspect_macho(external_user_path, cpu, {2})
        inspect_macho(
            hello_path,
            cpu,
            {1, 2} if architecture == "x86_64" else {2, 3, 4},
            {"_main", "_write"} if architecture == "x86_64"
            else {"_main", "_printf"},
        )
        mac_objects[architecture] = object_path
        mac_external_objects[architecture] = (
            external_user_path,
            external_definition_path,
        )
        mac_hello_objects[architecture] = (hello_path, printf_stub_path)

    arm_variadic_path = output / "aarch64-macos-variadic.o"
    run(
        compiler,
        "--target=arm64-macos",
        "-nostdinc",
        "-c",
        str(mac_variadic_source),
        "-o",
        str(arm_variadic_path),
    )
    inspect_macho(arm_variadic_path, MACH_CPUS["aarch64"], {2, 3, 4})
    arm_variadic_text = macho_section_data(arm_variadic_path, b"__text")
    apple_variadic_sequence = struct.pack(
        "<IIII", 0xF9400BE9, 0xF90007E9, 0x94000000, 0x910083FF
    )
    if apple_variadic_sequence not in arm_variadic_text:
        raise SystemExit(
            f"{arm_variadic_path}: Darwin arm64 variadic arguments are not "
            "packed on the stack"
        )

    rejected = subprocess.run(
        [
            compiler,
            "--target=x86_64-macos",
            "-ffreestanding",
            "-nostdinc",
            str(return_source),
            "-o",
            str(output / "invalid-macos-executable"),
        ],
        text=True,
        capture_output=True,
    )
    if rejected.returncode == 0 or "Mach-O object with -c" not in rejected.stderr:
        raise SystemExit("macOS direct-executable diagnostic is missing")

    ld64 = find_ld64()
    if ld64:
        for architecture in mac_objects:
            linked = output / f"{architecture}-macos-linked"
            linker_arch = "arm64" if architecture == "aarch64" else architecture
            external_user_path, external_definition_path = mac_external_objects[
                architecture
            ]
            run(
                ld64,
                "-arch",
                linker_arch,
                "-platform_version",
                "macos",
                "11.0",
                "11.0",
                "-e",
                "_main",
                "-o",
                str(linked),
                str(external_user_path),
                str(external_definition_path),
            )
            header = linked.read_bytes()[:16]
            magic, actual_cpu, _, file_type = struct.unpack("<4I", header)
            if magic != 0xFEEDFACF or actual_cpu != MACH_CPUS[architecture] or file_type != 2:
                raise SystemExit(f"{linked}: ld64.lld did not produce a Mach-O executable")
            hello_linked = output / f"{architecture}-macos-hello-linked"
            hello_path, printf_stub_path = mac_hello_objects[architecture]
            run(
                ld64,
                "-arch",
                linker_arch,
                "-platform_version",
                "macos",
                "11.0",
                "11.0",
                "-e",
                "_main",
                "-o",
                str(hello_linked),
                str(hello_path),
                str(printf_stub_path),
            )
            if b"Hello World!\n\0" not in hello_linked.read_bytes():
                raise SystemExit(f"{hello_linked}: string literal was not linked")

    print("BSD ELF and macOS Mach-O target matrix passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
