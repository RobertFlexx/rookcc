rookcc

rookcc is a small c compiler for linux and the command is rcc

the compiler is written in free pascal and builds into one native program

once built rcc does its own preprocessing parsing type checking optimization machine code encoding object writing executable writing archive reading and shared library resolution

it does not start gcc clang an assembler or a linker

free pascal is only needed to build rcc from source

programs linked to libc or another shared library still use the normal linux loader and the libraries selected by the program

building

    make

or

    ./scripts/build.sh

installing for the current user

    ./scripts/install.sh

installing with make

    make PREFIX=$HOME/.local INSTALL_ROOKCC=1 install

the install script puts rcc and the optional rookcc alias in the selected bin directory and installs the bundled headers man page and shell completions

basic use

    rcc hello.c -O2 -o hello
    ./hello

    rcc main.c math.c -O2 -o app

    rcc -run hello.c one two

    rcc -E hello.c -o hello.i
    rcc --emit-ir -O2 hello.c -o hello.rir
    rcc -c source.c -o source.o

shared libraries use the usual l option

    rcc numbers.c -lm -o numbers

the editor in this tree declares its wide ncurses library in the source

    rcc repltxt.c -O2 --gnu-source -o repltxt
    ./repltxt --help

wide ncurses keeps some data in libtinfow and rcc follows that dependency itself so a separate ltinfow option is not needed

programs can declare an rcc library dependency while staying quiet on other compilers

    #ifdef __ROOKCC__
    #pragma rcc link ncursesw
    #endif

language support

rcc has c90 c99 c11 c17 and c23 modes plus gnu99 gnu11 gnu17 and gnu23 modes

the gnu surface includes common alternate keywords typeof statement expressions computed goto case ranges function attributes builtin operations and extended inline assembly

the bundled headers cover the c library common posix interfaces linux interfaces threads dynamic loading wide characters and wide ncurses

the x86 64 backend follows the sysv amd64 calling convention including variadic calls function pointers integer and floating point aggregates register exhaustion stack values and hidden return storage for large aggregates

optimization includes constant folding propagation dead code removal branch cleanup common expression reuse algebraic simplification strength reduction local load and store cleanup peephole work and target instruction selection

targets

x86 64 linux is the complete hosted target and writes executables and relocatable objects directly

aarch64 linux and riscv64 linux are experimental freestanding integer targets for executable and object output

use these commands for the exact installed target surface

    rcc --print-targets
    rcc --print-backends
    rcc --print-target-info

current limits

x86 64 pic relocatable objects work but pie executables and shared object output are still outside the current release

the cross targets do not yet provide hosted libc linking and are not replacements for the hosted x86 64 path

long double tls unwind tables and full statement level debug locations are not advertised

small patches are easiest to review when they include a focused c regression and keep the compiler independent from other c toolchains

the license is mit


originally made with 3 people over the span of years for an educational reason.
but it aims to be auditable, simple architecture, and cross-arch compilation.
i did most of the work to get it working, and where it is now. (RobertFlexx)
