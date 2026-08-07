<img width="1728" height="866" alt="rookcc" src="https://github.com/user-attachments/assets/7afbe89e-0d6a-45ae-b8a9-e92c26041ada" />

rookcc is a small c compiler with native linux bsd and macos cross target output and the command is rcc

the compiler is written in free pascal and builds into one native program. once built rcc does its own preprocessing parsing type checking optimization machine code encoding and object writing. its x86 64 linux backend also writes and links executables directly

when the selected target exactly matches the host architecture and operating system rcc also behaves as a normal compiler driver. on macos bsd and non x86 linux hosts it invokes the platform compiler driver only for the final sdk startup file and system library link. it never sends c source to that driver

**version 3.0.0**

---------------------------

[pawnasm](https://github.com/RobertFlexx/pawnasm) is also a relative to this project. if you **JUST** want an assembler as a separate package.

[kld](https://github.com/RobertFlexx/knightlinker) is another relative, serves as a linker for programs.

(you will need [ofrontplus](https://github.com/Oleg-N-Cher/OfrontPlus) to compile pawnasm)

what each backend supports
--------------------------

the x86-64 backend is the complete one. the aarch64 and riscv64 backends
share the same frontend, type checking and optimizer, and cover the integer
and pointer subset of c. every program in `tests/cross` is compiled for all
three architectures and executed (under qemu-user for the non-host ones) on
every `make test`, so the shared column below is verified, not claimed. this compiler is bullshit.
please enjoy the source code i found and debugged (im not gonna write this all in one night, i found ts lost from time, i just ruled out bugs and fixed them so they compile so i can confidently commit)

| feature | x86-64 | aarch64 / riscv64 |
| --- | --- | --- |
| integers, pointers, casts, all operators | yes | yes |
| arrays incl. multidimensional, `&` `*` `[]` `.` `->` | yes | yes |
| structs, unions, aggregate assignment and copies | yes | yes |
| struct parameters and returns | yes | up to two words |
| loops, `switch`, `goto`, `break`, `continue` | yes | yes |
| function pointers, static dispatch tables | yes | yes |
| more than eight arguments (stack passing) | yes | yes |
| `static` locals, file-scope and zero-init data | yes | yes |
| string literals and pointer initializers | yes | yes |
| floating point | yes | not implemented |
| bit-fields | yes | not implemented |
| variadic function definitions | yes | not implemented |
| inline assembly | yes | not implemented |
| hosted libc linking | yes | freestanding only |

anything in the "not implemented" rows is rejected with a diagnostic naming
the feature. the cross backends never silently emit wrong code for something
they cannot express.

aarch64 and riscv64 executables are static and freestanding, so build them
with `-ffreestanding`; for hosted programs emit an object with `-c` and link
with a target toolchain.

requirements
------------

free pascal is only needed to build rcc from source. apple command line tools
are required for native hosted macos executable links; bsd and non x86 linux
hosted links use the system cc driver. programs linked to libc or another
shared library use the normal loader and system libraries of their target
operating system.

building
--------

    make

or

    ./scripts/build.sh

run the portable format driver and native host release checks with

    make test

the native host check compiles links and executes a formatted libc program, so release builds should run it on every advertised host architecture and operating system.

`make test` also runs the C differential suite, which builds every program in
`tests/c` with rcc at -O0 -O1 -O2 -O3 and -Os and with a reference compiler,
and requires the output to match byte for byte at every level, so a codegen
regression fails the build.

installing for the current user

    ./scripts/install.sh

installing with make

    make PREFIX=$HOME/.local INSTALL_ROOKCC=1 install

the install script puts rcc and the optional rookcc alias in the selected bin
directory and installs the bundled headers man page and shell completions.

basic use
---------

    rcc hello.c -O2 -o hello
    ./hello

    rcc main.c math.c -O2 -o app

    rcc -run hello.c one two

    rcc -E hello.c -o hello.i
    rcc --emit-ir -O2 hello.c -o hello.rir
    rcc -c source.c -o source.o

the default target is detected from the architecture and operating system
that rcc was built on. a matching native build is therefore one command on
linux macos freebsd openbsd and netbsd:

    rcc example.c -o example
    ./example

shared libraries use the usual l option:

    rcc numbers.c -lm -o numbers

programs can declare an rcc library dependency while staying quiet on other
compilers:

    #ifdef __ROOKCC__
    #pragma rcc link ncursesw
    #endif

language support
----------------

rcc has c90 c99 c11 c17 and c23 modes plus gnu99 gnu11 gnu17 and gnu23 modes.

the gnu surface includes common alternate keywords typeof statement expressions
computed goto case ranges function attributes builtin operations and extended
inline assembly. the bundled headers cover the c library common posix
interfaces linux interfaces threads dynamic loading wide characters and
curses.

the x86 64 backend follows the sysv amd64 calling convention including function
pointers integer and floating point aggregates register exhaustion and stack
values. optimization includes constant folding propagation dead code removal
common subexpression reuse, strength reduction, local load and store cleanup
and peephole work.

targets
-------

x86 64 linux is the complete hosted target and writes executables and
relocatable objects directly.

aarch64 linux and riscv64 linux are experimental integer targets. on a matching
native host rcc uses the system cc driver for the final hosted executable link;
cross target executable output remains freestanding.

freebsd openbsd and netbsd have elf64 object and freestanding static executable
targets for x86 64 aarch64 and riscv64. on a matching bsd host `rcc source.c -o
program` performs the final hosted link automatically. openbsd freestanding
executables include the syscall pinning program segment required by current
kernels.

macos has mach o 64 bit relocatable object targets for x86 64 and arm64. on a
matching mac `rcc source.c -o program` invokes apple's clang for the final sdk
and libsystem link and produces a native executable.

when targeting macos from linux or another host that does not match macos,
produce an object with `-c` and finish the link with an apple sdk toolchain. rcc
does not pretend an apple sdk is bundled, and macos does not execute elf files:

    rcc --target x86_64-freebsd -ffreestanding tiny.c -o tiny.freebsd
    rcc --target aarch64-openbsd -ffreestanding tiny.c -o tiny.openbsd
    rcc --target arm64-macos -c source.c -o source.macho.o

set `RCC_PLATFORM_LINKER` to an executable path or command name to override the
native final link driver. this override is never used for cross target output
or for `-c`.

use these commands for the exact installed target surface:

    rcc --print-targets
    rcc --print-backends
    rcc --print-target-info

current limits
--------------

x86 64 pic relocatable objects work but pie executables and shared object
output are still outside the current release.

cross bsd and non-x86 linux executable targets are freestanding and static.
use `-c` plus a target sysroot linker for cross hosted libc programs. when
`--sysroot` is present its platform headers take precedence over the bundled
generic shims.

cross macos executable linking remains outside rcc because sdk selection dyld
metadata and code signing belong to the apple platform link step. native macos
builds delegate that step automatically.

long double tls unwind tables and full statement level debug locations are not
advertised.

small patches are easiest to review when they include a focused c regression
and keep c parsing optimization and machine code generation inside rcc.

the license is mit.

## SUPPORT/CONTRIBUTIONS NEEDED!

im maintaining this huge project **myself**, and i can only do so much so fast.

originally it was made with 3 people over the span of years for an
educational/school reason. but it aims to be auditable, simple to understand
architecture, and cross-arch compilation. i did most of the work to get it
working and where it is now. (RobertFlexx)

something broken? grab a focused c file that reproduces it and give it to me,
that's honestly the most useful contribution. i cant fix what i cant see.

## Credits
thanks to [Kokonico](https://github.com/Kokonico) for the logo!

## more
https://kokonico.me
