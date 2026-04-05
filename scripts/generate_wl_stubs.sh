#!/bin/bash
# Generate stubs + declarations for C-only builds.
# Usage: generate_wl_stubs.sh <llvm_bridge.c> <emitted_main.c> <out_dir>
set -euo pipefail

bridge="$1"
emitted="$2"
outdir="$3"

mkdir -p "$outdir"

# Pass 1: find undeclared functions
{ cc -c "$emitted" -I runtime -o /dev/null -ferror-limit=0 -w -Werror=implicit-function-declaration 2>&1 || true; } \
  | grep "call to undeclared function" \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u > "$outdir/undeclared_fns.txt"

# Temp declarations for pass 2
awk 'BEGIN{print "#include <stdint.h>"} {print "int64_t " $1 "();"}' "$outdir/undeclared_fns.txt" > "$outdir/wl_decls.h"

# Pass 2: find more undeclared functions (grep may find nothing — that's OK)
{ cc -c "$emitted" -I runtime -include "$outdir/wl_decls.h" -o /dev/null -ferror-limit=0 -w -Werror=implicit-function-declaration 2>&1 || true; } \
  | { grep "call to undeclared function" || true; } \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u >> "$outdir/undeclared_fns.txt"
sort -u -o "$outdir/undeclared_fns.txt" "$outdir/undeclared_fns.txt"

# Generate declarations (all int64_t — simple and safe)
awk '
BEGIN { print "#include <stdint.h>" }
{ print "int64_t " $1 "();" }
' "$outdir/undeclared_fns.txt" > "$outdir/wl_decls.h"

# Generate stubs
awk '
BEGIN { print "#include <stdint.h>" }
{ print "int64_t " $1 "() { return 0; }" }
' "$outdir/undeclared_fns.txt" > "$outdir/wl_stubs.c"

echo "generated $(wc -l < "$outdir/undeclared_fns.txt" | tr -d ' ') stubs"
