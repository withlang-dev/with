#!/bin/bash
# Generate LLVM bridge stubs + declarations for C-only builds.
# Usage: generate_wl_stubs.sh <llvm_bridge.c> <emitted_main.c> <out_dir>
set -euo pipefail

bridge="$1"
emitted="$2"
outdir="$3"

mkdir -p "$outdir"

# Extract all undeclared wl_* functions from compiling the emitted C
cc -c "$emitted" -I runtime -o /dev/null -ferror-limit=0 -w 2>&1 \
  | grep "undeclared function 'wl_" \
  | sed "s/.*'wl_/wl_/" | sed "s/'.*//" \
  | sort -u > "$outdir/wl_needed.txt"

# Generate declarations header
{
  echo '#include <stdint.h>'
  awk '{print "int64_t " $1 "(); "}' "$outdir/wl_needed.txt"
} > "$outdir/wl_decls.h"

# Generate stub implementations
{
  echo '#include <stdint.h>'
  awk '{print "int64_t " $1 "() { return 0; }"}' "$outdir/wl_needed.txt"
} > "$outdir/wl_stubs.c"

echo "generated $(wc -l < "$outdir/wl_needed.txt" | tr -d ' ') wl_* stubs"
