#!/bin/bash
# Generate stubs + declarations for C-only builds.
# Usage: generate_wl_stubs.sh <llvm_bridge.c> <emitted_main.c> <out_dir>
set -euo pipefail

bridge="$1"
emitted="$2"
outdir="$3"
runtime_dir="$(cd "$(dirname "$bridge")" && pwd)"
repo_root="$(cd "$runtime_dir/.." && pwd)"

mkdir -p "$outdir"

# Pass 1: find undeclared functions
{ cc -c "$emitted" -I runtime -include "$runtime_dir/with_runtime.h" -o /dev/null -ferror-limit=0 -w -Werror=implicit-function-declaration 2>&1 || true; } \
  | grep "call to undeclared function" \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u > "$outdir/undeclared_fns.txt"

# Temp declarations for pass 2
awk 'BEGIN{print "#include <stdint.h>"} {print "int64_t " $1 "();"}' "$outdir/undeclared_fns.txt" > "$outdir/wl_decls.h"

# Pass 2: find more undeclared functions (grep may find nothing — that's OK)
{ cc -c "$emitted" -I runtime -include "$runtime_dir/with_runtime.h" -include "$outdir/wl_decls.h" -o /dev/null -ferror-limit=0 -w -Werror=implicit-function-declaration 2>&1 || true; } \
  | { grep "call to undeclared function" || true; } \
  | sed "s/.*function '//;s/'.*//" \
  | sort -u >> "$outdir/undeclared_fns.txt"
sort -u -o "$outdir/undeclared_fns.txt" "$outdir/undeclared_fns.txt"

runtime_link_objects=(
  "$repo_root/out/lib/rt_core.o"
  "$repo_root/out/lib/rt_darwin_aarch64.o"
  "$repo_root/out/lib/compat_runtime.o"
  "$repo_root/out/lib/panic_runtime.o"
  "$repo_root/out/lib/fiber_stubs.o"
  "$repo_root/out/lib/helpers.o"
)

runtime_link_exports="$outdir/runtime_link_exports.txt"
{
  for obj in "${runtime_link_objects[@]}"; do
    [ -f "$obj" ] || continue
    nm -gU "$obj" 2>/dev/null | sed -n 's/^.* _//p'
  done
} | sort -u > "$runtime_link_exports"

sig_sources=(
  "$runtime_dir/with_runtime.h"
  "$runtime_dir/helpers.c"
  "$runtime_dir/clang_bridge.c"
  "$bridge"
)

find_known_signature() {
  case "$1" in
    with_fill_random) printf '%s\n' 'void with_fill_random(uint8_t *buf, int64_t len)' ;;
    with_net_close) printf '%s\n' 'int32_t with_net_close(int32_t fd)' ;;
    with_net_recv) printf '%s\n' 'with_str with_net_recv(int32_t fd, int64_t max_len)' ;;
    with_net_send) printf '%s\n' 'int64_t with_net_send(int32_t fd, with_str data)' ;;
    with_net_tcp_accept) printf '%s\n' 'int32_t with_net_tcp_accept(int32_t listen_fd)' ;;
    with_net_tcp_connect) printf '%s\n' 'int32_t with_net_tcp_connect(with_str host, int32_t port)' ;;
    with_net_tcp_listen) printf '%s\n' 'int32_t with_net_tcp_listen(int32_t port, int32_t backlog)' ;;
    with_net_udp_bind) printf '%s\n' 'int32_t with_net_udp_bind(int32_t port)' ;;
    with_parse_float) printf '%s\n' 'double with_parse_float(with_str s)' ;;
    *) return 1 ;;
  esac
}

find_signature() {
  local fn="$1"
  local src line
  line="$(find_known_signature "$fn" || true)"
  if [ -n "$line" ]; then
    printf '%s\n' "$line"
    return 0
  fi
  for src in "${sig_sources[@]}"; do
    [ -f "$src" ] || continue
    line="$(rg -m1 --no-filename -P "^[[:space:]]*(?:__attribute__\\(\\(weak\\)\\)\\s*)?[^;{}=]*\\b${fn}[[:space:]]*\\([^;{}]*\\)[[:space:]]*(?:\\{|;)" "$src" | head -n1 || true)"
    if [ -n "$line" ]; then
      line="${line//__attribute__((weak)) /}"
      line="${line%%\{*}"
      printf '%s\n' "$line" \
        | sed -E 's/^[[:space:]]+//; s/[[:space:]]*;[[:space:]]*$//; s/[[:space:]]+/ /g; s/[[:space:]]+$//'
      return 0
    fi
  done
  return 1
}

stub_return_stmt() {
  local ret="$1"
  if [ "$ret" = "void" ]; then
    printf '%s' '(void)0;'
    return 0
  fi
  if [ "$ret" = "bool" ]; then
    printf '%s' 'return false;'
    return 0
  fi
  if [[ "$ret" == *"*"* ]]; then
    printf '%s' 'return 0;'
    return 0
  fi
  if printf '%s\n' "$ret" | grep -Eq '^(u?int(8|16|32|64)_t|size_t|ssize_t|intptr_t|uintptr_t|float|double|int|long|short|char)$'; then
    printf '%s' 'return 0;'
    return 0
  fi
  printf '%s __with_stub = (%s){0}; return __with_stub;' "$ret" "$ret"
}

{
  echo '#include "with_runtime.h"'
  while IFS= read -r fn; do
    [ -n "$fn" ] || continue
    sig="$(find_signature "$fn" || true)"
    if [ -n "$sig" ]; then
      printf '%s;\n' "$sig"
    else
      printf 'int64_t %s();\n' "$fn"
    fi
  done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_decls.h"

{
  echo '#include "with_runtime.h"'
  while IFS= read -r fn; do
    [ -n "$fn" ] || continue
    if grep -qx "$fn" "$runtime_link_exports"; then
      continue
    fi
    sig="$(find_signature "$fn" || true)"
    if [ -z "$sig" ]; then
      printf 'int64_t %s() { return 0; }\n' "$fn"
      continue
    fi
    ret="$(printf '%s\n' "$sig" | sed -E "s/[[:space:]]*${fn}[[:space:]]*\\(.*$//")"
    printf '%s { %s }\n' "$sig" "$(stub_return_stmt "$ret")"
  done < "$outdir/undeclared_fns.txt"
} > "$outdir/wl_stubs.c"

echo "generated $(wc -l < "$outdir/undeclared_fns.txt" | tr -d ' ') stubs"
