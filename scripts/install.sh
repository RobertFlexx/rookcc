#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -eq 0 ]; then default_prefix=/usr/local; else default_prefix=$HOME/.local; fi
prefix=${PREFIX:-$default_prefix}
install_rookcc=${INSTALL_ROOKCC:-1}

usage() {
  cat <<USAGE
usage: scripts/install.sh [--prefix dir] [--no-rookcc]

build and install the standalone rookcc compiler
free pascal is only required for building from source
the installed rcc binary does not invoke it
USAGE
}

while [ "$#" -gt 0 ]; do
  case $1 in
    --prefix) shift; [ "$#" -gt 0 ] || { echo 'error: --prefix requires a directory' >&2; exit 2; }; prefix=$1 ;;
    --prefix=*) prefix=${1#*=} ;;
    --no-rookcc) install_rookcc=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

command -v fpc >/dev/null 2>&1 || { echo 'error: free pascal is required to build rookcc from source' >&2; exit 127; }
make
make PREFIX="$prefix" INSTALL_ROOKCC="$install_rookcc" install
case :$PATH: in *:"$prefix/bin":*) ;; *) printf '\nadd this to your shell profile\n  export PATH="%s/bin:$PATH"\n' "$prefix" ;; esac
