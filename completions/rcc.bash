_rcc_complete()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W '-o -E -S -c -run --check --emit-ir --emit-tokens -O0 -O1 -O2 -O3 -Og -Os -Oz -Ofast -I -iquote -isystem -D -U -L -l -R --dynamic-linker= -pthread -nodefaultlibs -static -fPIC -M -MM -MD -MMD -MP -MF -MT -MQ -std= -nostdinc -ffreestanding -fhosted -g -Wall -Wextra -Werror -pedantic --gnu-source --posix-source --rcc-source --sysroot= -isysroot --resource-dir= -print-multiarch -print-sysroot --print-search-dirs --print-resource-dir --print-targets --print-target-info --print-target-features --print-backends --print-toolchain --print-optimizations --print-conformance --print-builtins --print-gnu-compat --stats --color= --target= --target-arm --target-riscv64 -march= -mattr= -dumpmachine -dumpversion --version -### -v --verbose -h --help' -- "$cur") )
}
complete -F _rcc_complete rcc rookcc
