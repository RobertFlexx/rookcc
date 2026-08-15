#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

printf '%s\n' '== clean source build =='
make clean
make all

printf '%s\n' '== mandatory correctness suites =='
make test

printf '%s\n' '== optimized host build =='
make optimized

printf '%s\n' '== optimized-build correctness suites =='
make test

printf '%s\n' '== benchmark report =='
make bench

printf '%s\n' '== package completeness =='
make package-check

printf '%s\n' 'PASS: RCC release gate completed'
