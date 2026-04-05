#!/bin/bash
# Generate stubs + declarations for C-only builds.
# Captures all undeclared functions: wl_* (LLVM), with_cimport_*, with_ci_*, etc.
# Usage: generate_wl_stubs.sh <llvm_bridge.c> <emitted_main.c> <out_dir>
set -euo pipefail

bridge="$1"
emitted="$2"
outdir="$3"

mkdir -p "$outdir"

# Extract all undeclared function names from compiling the emitted C
cc -c "$emitted" -I runtime -o /dev/null -ferror-limit=0 -w 2>&1 \
  | grep "call to undeclared function" \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u > "$outdir/undeclared_fns.txt"

# Generate declarations header
{
  echo '#include <stdint.h>'
  echo 'typedef struct { const char *ptr; long long len; } with_str;'
  while IFS= read -r fn; do
    echo "int64_t ${fn}();"
  done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_decls.h"

# Generate stub implementations
{
  echo '#include <stdint.h>'
  while IFS= read -r fn; do
    echo "int64_t ${fn}() { return 0; }"
  done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_stubs.c"

echo "generated $(wc -l < "$outdir/undeclared_fns.txt" | tr -d ' ') stubs"
