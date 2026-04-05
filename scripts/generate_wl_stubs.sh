#!/bin/bash
# Generate stubs + declarations for C-only builds.
# Captures all undeclared functions: wl_* (LLVM), with_cimport_*, with_ci_*, etc.
# Usage: generate_wl_stubs.sh <llvm_bridge.c> <emitted_main.c> <out_dir>
set -euo pipefail

bridge="$1"
emitted="$2"
outdir="$3"

mkdir -p "$outdir"

# Pass 1: compile without declarations to find undeclared functions
cc -c "$emitted" -I runtime -o /dev/null -ferror-limit=0 -w 2>&1 \
  | grep "call to undeclared function" \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u > "$outdir/undeclared_fns.txt"

# Generate initial declarations (all int64_t)
{
  echo '#include <stdint.h>'
  while IFS= read -r fn; do echo "int64_t ${fn}();"; done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_decls.h"

# Pass 2: compile WITH declarations to find more undeclared functions
cc -c "$emitted" -I runtime -include "$outdir/wl_decls.h" -o /dev/null -ferror-limit=0 -w 2>&1 \
  | grep "call to undeclared function" \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u >> "$outdir/undeclared_fns.txt"
sort -u -o "$outdir/undeclared_fns.txt" "$outdir/undeclared_fns.txt"

# Determine return types heuristically:
# - Functions containing _str_ or ending in _str or _name or _value or _error
#   or _type or _underlying return with_str
# - Everything else returns int64_t
emit_decl() {
  local fn="$1"
  case "$fn" in
    *_str|*_name|*_value|*_error|*_type|*_type_translated|*_underlying|*_underlying_translated|*_calling_conv|*_int_type|*_macro_value)
      echo "with_str ${fn}();"
      ;;
    *)
      echo "int64_t ${fn}();"
      ;;
  esac
}

emit_stub() {
  local fn="$1"
  case "$fn" in
    *_str|*_name|*_value|*_error|*_type|*_type_translated|*_underlying|*_underlying_translated|*_calling_conv|*_int_type|*_macro_value)
      echo "with_str ${fn}() { with_str e = {\"\", 0}; return e; }"
      ;;
    *)
      echo "int64_t ${fn}() { return 0; }"
      ;;
  esac
}

# Generate final declarations header
{
  echo '#include <stdint.h>'
  echo '#include "with_runtime.h"'
  while IFS= read -r fn; do emit_decl "$fn"; done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_decls.h"

# Generate stub implementations
{
  echo '#include <stdint.h>'
  echo 'typedef struct { const char *ptr; long long len; } with_str;'
  while IFS= read -r fn; do emit_stub "$fn"; done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_stubs.c"

echo "generated $(wc -l < "$outdir/undeclared_fns.txt" | tr -d ' ') stubs"
