#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="${WITH:-${ROOT_DIR}/out/bin/with-stage2}"
CLI_TIMEOUT_SECS="${PARITY_CLI_TIMEOUT_SECS:-25}"

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0

run_cli() {
  local out_file="$1"
  local err_file="$2"
  shift 2
  runner_exec_capture "$CLI_TIMEOUT_SECS" "$out_file" "$err_file" "$SELFHOST_BIN" "$@"
}

file_has_literal() {
  local path="$1"
  local needle="$2"
  grep -Fq "$needle" "$path"
}

file_has_regex() {
  local path="$1"
  local pattern="$2"
  grep -Eq "$pattern" "$path"
}

file_forbid_literal() {
  local path="$1"
  local needle="$2"
  ! grep -Fq "$needle" "$path"
}

file_forbid_regex() {
  local path="$1"
  local pattern="$2"
  ! grep -Eq "$pattern" "$path"
}

# Module-object symbol contract:
# - ordinary With imports are referenced through module-scoped link names
# - C ABI imports keep their canonical raw linker names
nm_has_defined_exact() {
  local obj="$1"
  local want="$2"
  /usr/bin/nm "$obj" | awk -v want="$want" '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name == want && type != "U") found = 1
    }
    END {
      exit !found
    }
  '
}

nm_has_undefined_exact() {
  local obj="$1"
  local want="$2"
  /usr/bin/nm "$obj" | awk -v want="$want" '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name == want && type == "U") found = 1
    }
    END {
      exit !found
    }
  '
}

nm_has_undefined_regex() {
  local obj="$1"
  local want_regex="$2"
  /usr/bin/nm "$obj" | awk -v want_regex="$want_regex" '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name ~ want_regex && type == "U") found = 1
    }
    END {
      exit !found
    }
  '
}

nm_forbid_exact() {
  local obj="$1"
  local forbidden="$2"
  ! /usr/bin/nm "$obj" | awk -v forbidden="$forbidden" '
    {
      name = $NF
      sub(/^_/, "", name)
      if (name == forbidden) bad = 1
    }
    END {
      exit !bad
    }
  '
}

nm_forbid_regex() {
  local obj="$1"
  local forbidden_regex="$2"
  ! /usr/bin/nm "$obj" | awk -v forbidden_regex="$forbidden_regex" '
    {
      name = $NF
      sub(/^_/, "", name)
      if (name ~ forbidden_regex) bad = 1
    }
    END {
      exit !bad
    }
  '
}

expect_emit_obj_global_symbols() {
  local case_dir="$tmpdir/emit_obj_globals_case"
  local src="$case_dir/emit_obj_globals.w"
  local obj="$case_dir/emit_obj_globals.o"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
var explicit_global: i32 = 42
var zero_global: i32
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$src" --emit-obj -o "$obj"; then
    echo "FAIL(cli-selfhost-emit-obj-build) emit_obj_globals"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! /usr/bin/nm -g "$obj" | awk '
    {
      name = $NF
      sub(/^_/, "", name)
      if (name ~ /explicit_global$/ || name ~ /zero_global$/) {
        if ($2 == "U") bad = 1
        if (name ~ /explicit_global$/) seen["explicit_global"] = 1
        if (name ~ /zero_global$/) seen["zero_global"] = 1
      }
    }
    END {
      exit !(seen["explicit_global"] && seen["zero_global"]) || bad
    }
  '; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) emit_obj_globals"
    /usr/bin/nm -g "$obj" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-emit-obj) emit_obj_globals"
}

expect_emit_obj_imported_symbols() {
  local case_dir="$tmpdir/emit_obj_imports_case"
  local shared_src="$case_dir/shared.w"
  local user_src="$case_dir/user.w"
  local shared_obj="$case_dir/shared.o"
  local user_obj="$case_dir/user.o"
  mkdir -p "$case_dir"

  cat >"$shared_src" <<'EOF'
var shared_var: i32 = 42
let shared_let: i32 = 7
fn shared_fn() -> i32: shared_var + shared_let
EOF

  cat >"$user_src" <<'EOF'
use shared
@[c_export("use_shared")]
fn use_shared() -> i32: shared_fn()
@[c_export("shared_let_addr")]
fn shared_let_addr() -> *const i32: &shared_let
@[c_export("shared_var_addr")]
fn shared_var_addr() -> *const i32: &shared_var
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$shared_src" --emit-obj -O0 -o "$shared_obj"; then
    echo "FAIL(cli-selfhost-emit-obj-build) emit_obj_import_owner"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$user_src" --emit-obj -O0 -o "$user_obj"; then
    echo "FAIL(cli-selfhost-emit-obj-build) emit_obj_import_user"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! /usr/bin/nm "$shared_obj" | awk '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name ~ /shared_var$/ || name ~ /shared_let$/ || name ~ /shared_fn$/) {
        if (type == "U") bad = 1
        if (name ~ /shared_var$/) seen["shared_var"] = 1
        if (name ~ /shared_let$/) seen["shared_let"] = 1
        if (name ~ /shared_fn$/) seen["shared_fn"] = 1
      }
    }
    END {
      exit !(seen["shared_var"] && seen["shared_let"] && seen["shared_fn"]) || bad
    }
  '; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) emit_obj_import_owner"
    /usr/bin/nm "$shared_obj" || true
    failures=$((failures + 1))
    return
  fi

  if ! /usr/bin/nm "$user_obj" | awk '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name == "use_shared" || name == "shared_let_addr" || name == "shared_var_addr") {
        if (type == "U") bad = 1
        seen[name] = 1
      } else if (name ~ /shared_var$/ || name ~ /shared_let$/ || name ~ /shared_fn$/) {
        if (type != "U") bad = 1
        if (name ~ /shared_var$/) seen["shared_var"] = 1
        if (name ~ /shared_let$/) seen["shared_let"] = 1
        if (name ~ /shared_fn$/) seen["shared_fn"] = 1
      }
    }
    END {
      exit !(seen["use_shared"] && seen["shared_let_addr"] && seen["shared_var_addr"] && seen["shared_var"] && seen["shared_let"] && seen["shared_fn"]) || bad
    }
  '; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) emit_obj_import_user"
    /usr/bin/nm "$user_obj" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-emit-obj) emit_obj_imported_symbols"
}

expect_whole_program_extern_var_redecl() {
  local case_dir="$tmpdir/whole_program_extern_var_redecl_case"
  local defs_src="$case_dir/defs.w"
  local user_src="$case_dir/user.w"
  local main_src="$case_dir/main.w"
  local bin="$case_dir/whole_program_extern_var_redecl"
  mkdir -p "$case_dir"

  cat >"$defs_src" <<'EOF'
var shared_counter: i32 = 41
EOF

  cat >"$user_src" <<'EOF'
extern var shared_counter: i32
fn read_counter() -> i32: shared_counter + 1
EOF

  cat >"$main_src" <<'EOF'
use user
use defs

fn main:
    if read_counter() == 42:
        print("ok")
    else:
        print("bad")
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$main_src" -o "$bin"; then
    echo "FAIL(cli-selfhost-build) whole_program_extern_var_redecl"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  local output
  output="$("$bin" 2>&1 || true)"
  if [[ "$output" != "ok" ]]; then
    echo "FAIL(cli-selfhost-run) whole_program_extern_var_redecl"
    printf '%s\n' "$output"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-build) whole_program_extern_var_redecl"
}

expect_imported_module_dependency_order() {
  local case_dir="$tmpdir/imported_module_dependency_order_case"
  local defs_src="$case_dir/defs.w"
  local module_src="$case_dir/m.w"
  local user_src="$case_dir/user.w"
  mkdir -p "$case_dir"

  cat >"$defs_src" <<'EOF'
type T = opaque
EOF

  cat >"$module_src" <<'EOF'
use defs
extern var gv: T
type T { x: i32 = 0 }
EOF

  cat >"$user_src" <<'EOF'
use m
fn main: let _ = 0
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$user_src"; then
    echo "FAIL(cli-selfhost-import-order-check) imported_module_dependency_order"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-import-order) imported_module_dependency_order"
}

expect_imported_fn_beats_extern_redecl() {
  local case_dir="$tmpdir/imported_fn_beats_extern_redecl_case"
  local shared_src="$case_dir/shared.w"
  local wrapper_src="$case_dir/wrapper.w"
  local user_src="$case_dir/user.w"
  local user_obj="$case_dir/user.o"
  mkdir -p "$case_dir"

  cat >"$shared_src" <<'EOF'
fn shared_fn() -> i32: 1
EOF

  cat >"$wrapper_src" <<'EOF'
extern fn shared_fn() -> i32
EOF

  cat >"$user_src" <<'EOF'
use shared
use wrapper
@[c_export("call_shared")]
fn call_shared() -> i32: shared_fn()
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$user_src" --emit-obj -O0 -o "$user_obj"; then
    echo "FAIL(cli-selfhost-emit-obj-build) imported_fn_beats_extern_redecl"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! nm_has_defined_exact "$user_obj" "call_shared" \
    || ! nm_has_undefined_regex "$user_obj" '^__with_mod_.*__shared_fn$' \
    || ! nm_forbid_exact "$user_obj" "shared_fn"; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) imported_fn_beats_extern_redecl"
    /usr/bin/nm "$user_obj" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-emit-obj) imported_fn_beats_extern_redecl"
}

expect_emit_obj_imported_pcre2_symbol() {
  local case_dir="$tmpdir/imported_pcre2_symbol_case"
  local src="$case_dir/test106.w"
  local obj="$case_dir/test106.o"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
use std.re.pcre2_compile

@[c_export("call_compile")]
fn call_compile() -> *mut pcre2_real_code_8:
    pcre2_compile_8((null as *const u8), 0, 0, (null as *mut c_int), (null as *mut c_ulong), (null as *mut pcre2_real_compile_context_8))
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$src" --emit-obj -O0 -o "$obj"; then
    echo "FAIL(cli-selfhost-emit-obj-build) imported_pcre2_symbol"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! nm_has_defined_exact "$obj" "call_compile" \
    || ! nm_has_undefined_regex "$obj" '^__with_mod_.*__pcre2_compile_8$' \
    || ! nm_forbid_exact "$obj" "pcre2_compile_8"; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) imported_pcre2_symbol"
    /usr/bin/nm "$obj" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-emit-obj) imported_pcre2_symbol"
}

expect_emit_obj_imported_pcre2_symbol_multi_import() {
  local case_dir="$tmpdir/imported_pcre2_symbol_multi_case"
  local src="$case_dir/test106_multi.w"
  local obj="$case_dir/test106_multi.o"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
use std.re.defs
use std.re.pcre2_compile
use std.re.pcre2_match

@[c_export("call_compile")]
fn call_compile() -> *mut pcre2_real_code_8:
    pcre2_compile_8((null as *const u8), 0, 0, (null as *mut c_int), (null as *mut c_ulong), (null as *mut pcre2_real_compile_context_8))
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$src" --emit-obj -O0 -o "$obj"; then
    echo "FAIL(cli-selfhost-emit-obj-build) imported_pcre2_symbol_multi_import"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! nm_has_defined_exact "$obj" "call_compile" \
    || ! nm_has_undefined_regex "$obj" '^__with_mod_.*__pcre2_compile_8$' \
    || ! nm_forbid_exact "$obj" "pcre2_compile_8"; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) imported_pcre2_symbol_multi_import"
    /usr/bin/nm "$obj" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-emit-obj) imported_pcre2_symbol_multi_import"
}

expect_migrate_global_init_list() {
  local case_dir="$tmpdir/migrate_global_init_list_case"
  local src="$case_dir/initlist.c"
  local out_w="$case_dir/initlist.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef int (*callback_t)(int);
typedef struct inner { callback_t cb; void *data; } inner;
typedef struct outer { inner in; int limit; } outer;
int add1(int x) { return x + 1; }
outer g = { { add1, 0 }, 7 };
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) global_init_list"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'var g: outer = outer { in_: inner { cb: add1, data: null }, limit: 7 }' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) global_init_list"
    sed -n '1,200p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) global_init_list"
}

expect_migrate_host_header_compat() {
  local case_dir="$tmpdir/migrate_host_header_compat_case"
  local src="$case_dir/uses_isatty.c"
  local config_h="$case_dir/config.h"
  local out_w="$case_dir/uses_isatty.w"
  mkdir -p "$case_dir"

  cat >"$config_h" <<'EOF'
/* Simulate an unconfigured config.h template. */
EOF

  cat >"$src" <<'EOF'
#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#ifndef HAVE_UNISTD_H
#error "missing HAVE_UNISTD_H"
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <stdio.h>

int tty_status(FILE *f) { return isatty(fileno(f)); }
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" -I "$case_dir" -D HAVE_CONFIG_H=1 -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) host_header_compat"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'tty_status' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) host_header_compat"
    sed -n '1,200p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) host_header_compat"
}

expect_migrate_pcre2_config_template() {
  local case_dir="$tmpdir/migrate_pcre2_config_template_case"
  local src_dir="$case_dir/src"
  local src="$src_dir/pcre2test_min.c"
  local out_w="$case_dir/pcre2test_min.w"
  mkdir -p "$src_dir"

  cat >"$src_dir/config.h.generic" <<'EOF'
/* Template config.h, not a configured build. */
/* #undef HAVE_UNISTD_H */
/* #undef SUPPORT_PCRE2_8 */
EOF

  cat >"$src_dir/pcre2.h.generic" <<'EOF'
/* stub */
EOF

  cat >"$src_dir/pcre2_chartables.c.dist" <<'EOF'
/* stub */
EOF

  cat >"$src" <<'EOF'
#if defined HAVE_CONFIG_H && !defined PCRE2_CONFIG_H_IDEMPOTENT_GUARD
#define PCRE2_CONFIG_H_IDEMPOTENT_GUARD
#include "config.h"
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef SUPPORT_PCRE2_8
typedef struct pcre2_real_compile_context_8 {
  int dummy;
} pcre2_real_compile_context_8;
#define PCRE2_REAL_COMPILE_CONTEXT pcre2_real_compile_context_8
#endif

int tty_status(int fd) { return isatty(fd); }
int size_of_ctx(void) { return sizeof(PCRE2_REAL_COMPILE_CONTEXT); }
EOF

  if ! bash "$ROOT_DIR/scripts/prepare_pcre2_reference.sh" "$src_dir" >"$tmpdir/out" 2>"$tmpdir/err"; then
    echo "FAIL(cli-selfhost-regex-prepare) config_template"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq '#define SUPPORT_PCRE2_8 1' "$src_dir/config.h" \
    || ! grep -Fq '#define HAVE_UNISTD_H 1' "$src_dir/config.h"; then
    echo "FAIL(cli-selfhost-regex-output) config_template_prepare"
    sed -n '1,80p' "$src_dir/config.h" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" -o "$out_w" -I "$src_dir" -D PCRE2_CODE_UNIT_WIDTH=8 -D HAVE_CONFIG_H=1; then
    echo "FAIL(cli-selfhost-migrate) pcre2_config_template"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'fn tty_status' "$out_w" || ! grep -Fq 'fn size_of_ctx' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) pcre2_config_template"
    sed -n '1,200p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) pcre2_config_template"
}

expect_migrate_assignment_compat() {
  local case_dir="$tmpdir/migrate_assignment_compat_case"
  local src="$case_dir/assignments.c"
  local out_w="$case_dir/assignments.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef unsigned int c_uint;
typedef struct {
  c_uint *groupinfo;
  c_uint *parsed_pattern;
} compile_block;

void f(void) {
  compile_block cb;
  c_uint stack_groupinfo[32];
  c_uint stack_parsed_pattern[64];
  c_uint pp = 0;
  c_uint skipatstart = 0;
  cb.groupinfo = stack_groupinfo;
  cb.parsed_pattern = stack_parsed_pattern;
  skipatstart = (pp = pp + 1);
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) assignment_compat"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! file_has_literal "$out_w" '(cb.groupinfo = (&stack_groupinfo[0] as *mut c_uint))' \
    || ! file_has_literal "$out_w" '(cb.parsed_pattern = (&stack_parsed_pattern[0] as *mut c_uint))' \
    || ! file_has_literal "$out_w" '(pp = (pp +% 1))' \
    || ! file_has_regex "$out_w" '\(skipatstart = \(*pp\)*\)' \
    || ! file_forbid_regex "$out_w" '\(skipatstart = \((pp) = ' \
    || ! awk '
      /\(pp = \(pp \+% 1\)\)/ { seen_pp = NR }
      /\(skipatstart = \(*pp\)*\)/ { seen_skip = NR }
      END {
        exit !(seen_pp > 0 && seen_skip > 0 && seen_pp < seen_skip)
      }
    ' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) assignment_compat"
    sed -n '1,220p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) assignment_compat"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) assignment_compat"
}

expect_migrate_rvalue_sequencing() {
  local case_dir="$tmpdir/migrate_rvalue_sequencing_case"
  local src="$case_dir/rvalue_sequencing.c"
  local out_w="$case_dir/rvalue_sequencing.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef unsigned char u8;

static int issue120_id(int x) {
  return x;
}

int init_expr(void) {
  const u8 *buf = (const u8 *)"AB";
  const u8 *p = buf;
  int c = *p++;
  return c * 10 + (int)(p - buf);
}

int assign_expr(void) {
  const u8 *buf = (const u8 *)"AB";
  const u8 *p = buf;
  int c = 0;
  c = *p++;
  return c * 10 + (int)(p - buf);
}

int binary_expr(void) {
  const u8 *buf = (const u8 *)"AB";
  const u8 *p = buf;
  int c = (*p++) + 0;
  return c * 10 + (int)(p - buf);
}

int call_arg_expr(void) {
  const u8 *buf = (const u8 *)"AB";
  const u8 *p = buf;
  int c = issue120_id(*p++);
  return c * 10 + (int)(p - buf);
}

#define ISSUE120_GETCHARINCTEST(ch, ptr) \
  ch = *ptr++;                           \
  if (utf && ch >= 66u) ch += 1000

int macro_expr(int utf) {
  const u8 *buf = (const u8 *)"BA";
  const u8 *p = buf;
  int c = 0;
  ISSUE120_GETCHARINCTEST(c, p);
  return c * 10 + (int)(p - buf);
}

int main(void) {
  if (init_expr() != 651) return 1;
  if (assign_expr() != 651) return 2;
  if (binary_expr() != 651) return 3;
  if (call_arg_expr() != 651) return 4;
  if (macro_expr(0) != 661) return 5;
  if (macro_expr(1) != 10661) return 6;
  return 0;
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) rvalue_sequencing"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'with 0 as __ci_expr_seq_' "$out_w" \
    || ! grep -Fq 'var __ci_expr_old_' "$out_w" \
    || ! grep -Fq '(p = p + 1)' "$out_w" \
    || ! grep -Fq '(unsafe: *__ci_expr_old_' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) rvalue_sequencing"
    sed -n '1,260p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) rvalue_sequencing"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" run "$out_w"; then
    echo "FAIL(cli-selfhost-run) rvalue_sequencing"
    cat "$tmpdir/out" || true
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) rvalue_sequencing"
}

expect_migrate_cross_file_global_owner_arrays() {
  local case_dir="$tmpdir/migrate_cross_file_global_owner_arrays_case"
  local generated_dir="$case_dir/generated"
  local header="$case_dir/tables.h"
  local owner_c="$case_dir/owner.c"
  local user_c="$case_dir/user.c"
  mkdir -p "$case_dir"

  cat >"$header" <<'EOF'
extern const unsigned char issue121_table[];
int issue121_value(int idx);
int issue121_sum(void);
EOF

  cat >"$owner_c" <<'EOF'
#include "tables.h"

const unsigned char issue121_table[] = {7, 9, 11};

int issue121_value(int idx) {
  return issue121_table[idx];
}
EOF

  cat >"$user_c" <<'EOF'
#include "tables.h"

int issue121_sum(void) {
  return issue121_table[2] + issue121_value(1);
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$case_dir" --no-c-export -o "$generated_dir"; then
    echo "FAIL(cli-selfhost-migrate) cross_file_global_owner_arrays"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Eq '^let issue121_table: \[3\]u8' "$generated_dir/owner.w" \
    || ! grep -Eq '^extern let issue121_table: \[3\]u8' "$generated_dir/user.w" \
    || grep -Eq 'issue121_table: \*' "$generated_dir/owner.w" \
    || grep -Eq 'issue121_table: \*' "$generated_dir/user.w"; then
    echo "FAIL(cli-selfhost-migrate-output) cross_file_global_owner_arrays"
    echo "--- owner.w"
    sed -n '1,200p' "$generated_dir/owner.w" || true
    echo "--- user.w"
    sed -n '1,200p' "$generated_dir/user.w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$generated_dir/owner.w"; then
    echo "FAIL(cli-selfhost-check) cross_file_global_owner_arrays owner"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$generated_dir/user.w"; then
    echo "FAIL(cli-selfhost-check) cross_file_global_owner_arrays user"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$generated_dir/owner.w" --emit-obj -o "$generated_dir/owner.o"; then
    echo "FAIL(cli-selfhost-build) cross_file_global_owner_arrays owner"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build "$generated_dir/user.w" --emit-obj -o "$generated_dir/user.o"; then
    echo "FAIL(cli-selfhost-build) cross_file_global_owner_arrays user"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) cross_file_global_owner_arrays"
}

expect_pcre2_prepare_shared_externs() {
  local case_dir="$tmpdir/pcre2_prepare_case"
  local raw_dir="$case_dir/raw"
  local generated_dir="$case_dir/generated"
  mkdir -p "$raw_dir"

  cat >"$raw_dir/pcre2_tables.w" <<'EOF'
// raw tables
extern fn preamble_helper() -> void
type BOOL = c_int
var _pcre2_utf8_table1: *c_int
var _pcre2_OP_lengths_8: *u8
EOF

  cat >"$raw_dir/pcre2_compile.w" <<'EOF'
// raw compile
extern fn preamble_helper() -> void
type BOOL = c_int
var _pcre2_utf8_table1: *c_int
var _pcre2_posix_class_maps8: *c_int
EOF

  cat >"$raw_dir/pcre2_compile_class.w" <<'EOF'
// raw compile_class
extern fn preamble_helper() -> void
type BOOL = c_int
var _pcre2_utf8_table1: *c_int
var _pcre2_posix_class_maps8: *c_int
EOF

  if ! bash "$ROOT_DIR/scripts/pcre2_generated_workflow.sh" prepare "$raw_dir" "$generated_dir" >"$tmpdir/out" 2>"$tmpdir/err"; then
    echo "FAIL(cli-selfhost-regex-prepare) shared_externs"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'var _pcre2_utf8_table1: *c_int' "$generated_dir/pcre2_tables.w" \
    || ! grep -Fq 'var _pcre2_OP_lengths_8: *u8' "$generated_dir/pcre2_tables.w" \
    || grep -Fq '_pcre2_utf8_table1' "$generated_dir/defs.w" \
    || ! grep -Fq 'extern var _pcre2_utf8_table1: *c_int' "$generated_dir/pcre2_compile.w" \
    || ! grep -Fq 'var _pcre2_posix_class_maps8: *c_int' "$generated_dir/pcre2_compile.w" \
    || ! grep -Fq 'extern var _pcre2_utf8_table1: *c_int' "$generated_dir/pcre2_compile_class.w" \
    || ! grep -Fq 'extern var _pcre2_posix_class_maps8: *c_int' "$generated_dir/pcre2_compile_class.w"; then
    echo "FAIL(cli-selfhost-regex-output) shared_externs"
    find "$generated_dir" -maxdepth 1 -type f -print | sort | while read -r f; do
      echo "--- $f"
      sed -n '1,80p' "$f"
    done
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-regex) shared_externs"
}

expect_pcre2_prepare_width_prunes_whole_decls() {
  local case_dir="$tmpdir/pcre2_prepare_width_prune_case"
  local raw_dir="$case_dir/raw"
  local generated_dir="$case_dir/generated"
  local wrapper="$case_dir/wrapper.w"
  mkdir -p "$raw_dir"

  cat >"$raw_dir/pcre2_tables.w" <<'EOF'
// raw tables
type c_void = opaque
type c_int = i32
type c_uint = u32
type c_ushort = u16
extern fn strlen(s: *const i8) -> i64
extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void
extern fn preamble_helper() -> void
type BOOL = c_int
type PCRE2_UCHAR16 = c_ushort
EOF

  cat >"$raw_dir/pcre2_compile.w" <<'EOF'
// raw compile
type c_int = i32
type c_uint = u32
extern fn preamble_helper() -> void
type BOOL = c_int
type PCRE2_UCHAR16 = c_ushort
extern fn _pcre2_keep_8(ch: c_uint) -> c_uint
extern fn pcre2_drop_16(ch: c_uint) -> c_uint
fn keep_body(flag: c_int) -> c_int:
    var c__goto_6350_16: c_uint = 0
    if flag != 0:
        (c__goto_6350_16 = _pcre2_keep_8(c__goto_6350_16))
    else:
        (c__goto_6350_16 = 1)
    (c__goto_6350_16 as c_int)
EOF

  if ! bash "$ROOT_DIR/scripts/pcre2_generated_workflow.sh" prepare "$raw_dir" "$generated_dir" >"$tmpdir/out" 2>"$tmpdir/err"; then
    echo "FAIL(cli-selfhost-regex-prepare) width_prunes_whole_decls"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if grep -Fq 'pcre2_drop_16' "$generated_dir/pcre2_compile.w" \
    || grep -Fq 'PCRE2_UCHAR16' "$generated_dir/pcre2_compile.w" \
    || ! grep -Fq '(c__goto_6350_16 = _pcre2_keep_8(c__goto_6350_16))' "$generated_dir/pcre2_compile.w" \
    || ! grep -Fq 'else:' "$generated_dir/pcre2_compile.w"; then
    echo "FAIL(cli-selfhost-regex-output) width_prunes_whole_decls"
    find "$generated_dir" -maxdepth 1 -type f -print | sort | while read -r f; do
      echo "--- $f"
      sed -n '1,120p' "$f"
    done
    failures=$((failures + 1))
    return
  fi

  {
    tail -n +2 "$generated_dir/defs.w"
    tail -n +3 "$generated_dir/pcre2_compile.w"
    printf '\nfn main: print("ok")\n'
  } >"$wrapper"

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$wrapper"; then
    echo "FAIL(cli-selfhost-check) width_prunes_whole_decls"
    cat "$tmpdir/err" || true
    echo "--- wrapper"
    sed -n '1,160p' "$wrapper" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-regex) width_prunes_whole_decls"
}

expect_pcre2_prepare_shared_lets() {
  local case_dir="$tmpdir/pcre2_prepare_shared_lets_case"
  local raw_dir="$case_dir/raw"
  local generated_dir="$case_dir/generated"
  mkdir -p "$raw_dir"

  cat >"$raw_dir/pcre2_tables.w" <<'EOF'
// raw tables
extern fn preamble_helper() -> void
type BOOL = c_int
let ucp_C: c_uint = 0
let ucp_L: c_uint = 1
let LOCAL_TABLE_ONLY: c_uint = 99
EOF

  cat >"$raw_dir/pcre2_compile.w" <<'EOF'
// raw compile
extern fn preamble_helper() -> void
type BOOL = c_int
let ucp_C: c_uint = 0
let ucp_L: c_uint = 1
let COMPILE_ONLY: c_uint = 7
EOF

  cat >"$raw_dir/pcre2_match.w" <<'EOF'
// raw match
extern fn preamble_helper() -> void
type BOOL = c_int
let ucp_C: c_uint = 0
let ucp_L: c_uint = 1
let MATCH_ONLY: c_uint = 8
EOF

  if ! bash "$ROOT_DIR/scripts/pcre2_generated_workflow.sh" prepare "$raw_dir" "$generated_dir" >"$tmpdir/out" 2>"$tmpdir/err"; then
    echo "FAIL(cli-selfhost-regex-prepare) shared_lets"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'let ucp_C: c_uint = 0' "$generated_dir/defs.w" \
    || ! grep -Fq 'let ucp_L: c_uint = 1' "$generated_dir/defs.w" \
    || grep -Fq 'let ucp_C: c_uint = 0' "$generated_dir/pcre2_tables.w" \
    || grep -Fq 'let ucp_C: c_uint = 0' "$generated_dir/pcre2_compile.w" \
    || grep -Fq 'let ucp_C: c_uint = 0' "$generated_dir/pcre2_match.w" \
    || ! grep -Fq 'let LOCAL_TABLE_ONLY: c_uint = 99' "$generated_dir/pcre2_tables.w" \
    || ! grep -Fq 'let COMPILE_ONLY: c_uint = 7' "$generated_dir/pcre2_compile.w" \
    || ! grep -Fq 'let MATCH_ONLY: c_uint = 8' "$generated_dir/pcre2_match.w"; then
    echo "FAIL(cli-selfhost-regex-output) shared_lets"
    find "$generated_dir" -maxdepth 1 -type f -print | sort | while read -r f; do
      echo "--- $f"
      sed -n '1,80p' "$f"
    done
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-regex) shared_lets"
}

expect_std_re_shared_dependency_imports() {
  local case_dir="$tmpdir/std_re_shared_dependency_case"
  local src="$case_dir/main.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
use std.re.defs
use std.re.pcre2_compile
use std.re.pcre2_match

fn main:
    print("ok")
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$src"; then
    echo "FAIL(cli-selfhost-check) std_re_shared_dependency_imports"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-check) std_re_shared_dependency_imports"
}

expect_migrate_initializer_regressions() {
  local case_dir="$tmpdir/migrate_initializer_regressions_case"
  local src="$case_dir/initializer_regressions.c"
  local out_w="$case_dir/initializer_regressions.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
#define STR_A "A"
#define STR_B "B"
#define STR_p "p"
#define STR_l "l"
#define STR_b "b"
#define STR_EXCLAMATION_MARK "!"
#define STR_QUESTION_MARK "?"
#define STRING_AB0 STR_A STR_B "\0"
#define STRING_plb0 STR_p STR_l STR_b "\0"

static const char names[] = "\0" /* comment between fragments */ STRING_AB0;
static const char alias_names[] = STRING_plb0;
static const char *punct = STR_EXCLAMATION_MARK STR_QUESTION_MARK;

int f(int x) {
label:
  unsigned char temp[6];
  unsigned char null_str[1] = { 0xcd };
  if (x) goto label;
  return temp[0] + null_str[0];
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) initializer_regressions"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'names:' "$out_w" \
    || ! grep -Fq '"\0AB\0"' "$out_w" \
    || ! grep -Fq 'alias_names:' "$out_w" \
    || ! grep -Fq '"plb\0"' "$out_w" \
    || ! grep -Fq 'var punct: *const i8 = "!?"' "$out_w" \
    || ! grep -Eq 'var temp(__goto_[0-9]+_[0-9]+)?: \[6\]u8' "$out_w" \
    || ! grep -Eq 'null_str(__goto_[0-9]+_[0-9]+)? = \[205\]' "$out_w" \
    || grep -Fq 'temp = 6' "$out_w" \
    || grep -Fq '/*' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) initializer_regressions"
    sed -n '1,220p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) initializer_regressions"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) initializer_regressions"
}

expect_migrate_tentative_global_owner() {
  local case_dir="$tmpdir/migrate_tentative_global_owner_case"
  local src="$case_dir/tentative_global_owner.c"
  local out_w="$case_dir/tentative_global_owner.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef struct ctx { int x; } ctx;
ctx g;
int issue127_read(void) { return g.x; }
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) tentative_global_owner"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Eq '^var g: ctx' "$out_w" \
    || grep -Eq '^extern var g: ctx' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) tentative_global_owner"
    sed -n '1,200p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) tentative_global_owner"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) tentative_global_owner"
}

expect_migrate_cross_file_tentative_global_owner() {
  local case_dir="$tmpdir/migrate_cross_file_tentative_global_owner_case"
  local generated_dir="$case_dir/generated"
  mkdir -p "$case_dir"

  cat >"$case_dir/a.c" <<'EOF'
int issue127_counter;
int issue127_get(void) { return issue127_counter; }
EOF

  cat >"$case_dir/b.c" <<'EOF'
int issue127_counter;
int issue127_bump(void) {
  issue127_counter = issue127_counter + 1;
  return issue127_counter;
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$case_dir" --no-c-export -o "$generated_dir"; then
    echo "FAIL(cli-selfhost-migrate) cross_file_tentative_global_owner"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Eq '^var issue127_counter: c_int' "$generated_dir/a.w" \
    || ! grep -Eq '^extern var issue127_counter: c_int' "$generated_dir/b.w"; then
    echo "FAIL(cli-selfhost-migrate-output) cross_file_tentative_global_owner"
    echo "--- a.w"
    sed -n '1,200p' "$generated_dir/a.w" || true
    echo "--- b.w"
    sed -n '1,200p' "$generated_dir/b.w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$generated_dir/a.w"; then
    echo "FAIL(cli-selfhost-check) cross_file_tentative_global_owner a"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$generated_dir/b.w"; then
    echo "FAIL(cli-selfhost-check) cross_file_tentative_global_owner b"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) cross_file_tentative_global_owner"
}

expect_migrate_noop_pointer_cast_exprs() {
  local case_dir="$tmpdir/migrate_noop_pointer_cast_exprs_case"
  local src="$case_dir/noop_pointer_cast_exprs.c"
  local out_w="$case_dir/noop_pointer_cast_exprs.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef struct ctx { int x; } ctx;
ctx g;

ctx *ret_ctx(void) {
  return (ctx *)(&g);
}

int f(ctx *ccontext) {
  ctx *local = (ctx *)(&g);
  ccontext = (ctx *)(&g);
  return local->x + ccontext->x;
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) noop_pointer_cast_exprs"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'fn ret_ctx() -> *mut ctx:' "$out_w" \
    || grep -Fq 'extern fn ret_ctx()' "$out_w" \
    || grep -Fq 'as *const ctx' "$out_w" \
    || grep -Fq 'as *mut ctx)) as *mut ctx' "$out_w" \
    || ! grep -Fq 'return ((&mut g as *mut ctx))' "$out_w" \
    || ! grep -Fq 'var local: *mut ctx = ((&mut g as *mut ctx))' "$out_w" \
    || ! grep -Fq '(ccontext = ((&mut g as *mut ctx)))' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) noop_pointer_cast_exprs"
    sed -n '1,220p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) noop_pointer_cast_exprs"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) noop_pointer_cast_exprs"
}

expect_migrate_typed_cast_macros() {
  local case_dir="$tmpdir/migrate_typed_cast_macros_case"
  local src="$case_dir/typed_cast_macros.c"
  local out_w="$case_dir/typed_cast_macros.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef unsigned long usize;
#define ZERO_TERM ((usize)-1)

int f(usize patlen) {
  int zero_terminated = 0;
  if ((zero_terminated = (patlen == ZERO_TERM)))
    patlen = 7;
  return zero_terminated + (int)patlen;
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) typed_cast_macros"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'let ZERO_TERM: c_ulong = (-1 as c_ulong)' "$out_w" \
    || ! grep -Fq 'patlen == ((-1 as c_ulong))' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) typed_cast_macros"
    sed -n '1,220p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) typed_cast_macros"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) typed_cast_macros"
}

expect_migrate_goto_shadowed_local() {
  local case_dir="$tmpdir/migrate_goto_shadowed_local_case"
  local src="$case_dir/shadowed_local.c"
  local out_w="$case_dir/shadowed_local.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef struct rec { int groupnumber; int group; } rec;

int f(int start, int ccount) {
  const rec *p;
  int groupnumber = 0;
  rec rc[8];
  goto label;
label:
  {
    int i;
    int p;
    for (i = 0, p = start; i < ccount; i++, p = (p + 1) & 7) {
      if (groupnumber == rc[p].groupnumber) return rc[p].group;
    }
  }
  return p == 0;
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) goto_shadowed_local"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! python3 - "$out_w" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
decls = re.findall(r"\bvar (p__goto_\d+_\d+):", text)
index_uses = set(re.findall(r"\[(p__goto_\d+_\d+)\]\.groupnumber", text))
outer_match = re.search(r"return \(if (p__goto_\d+_\d+) == 0: 1 else: 0\)", text)

if len(set(decls)) < 2 or len(index_uses) != 1 or outer_match is None:
    raise SystemExit(1)

if outer_match.group(1) in index_uses:
    raise SystemExit(1)
PY
  then
    echo "FAIL(cli-selfhost-migrate-output) goto_shadowed_local"
    sed -n '1,220p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) goto_shadowed_local"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) goto_shadowed_local"
}

expect_migrate_recursive_anonymous_records() {
  local case_dir="$tmpdir/migrate_recursive_anonymous_records_case"
  local src="$case_dir/anon_records.c"
  local out_w="$case_dir/anon_records.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
typedef struct outer {
  int tag;
  union {
    struct {
      int x;
      union {
        int y;
        unsigned char bytes[4];
      } inner;
    } named;
    struct {
      const char *p;
      int n;
    } other;
  } fields;
  int tail;
} outer;

int probe(outer *o) {
  return o->fields.named.inner.y + o->tail;
}
EOF

  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate "$src" --no-c-export -o "$out_w"; then
    echo "FAIL(cli-selfhost-migrate) recursive_anonymous_records"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq 'type outer_fields {' "$out_w" \
    || ! grep -Fq 'type outer_fields_named {' "$out_w" \
    || ! grep -Fq 'type outer_fields_named_inner {' "$out_w" \
    || ! grep -Fq 'fn probe' "$out_w" \
    || grep -Fq 'type outer = opaque' "$out_w" \
    || grep -Fq 'type outer_fields = opaque' "$out_w" \
    || grep -Fq 'type outer_fields_named = opaque' "$out_w" \
    || grep -Fq 'type outer_fields_named_inner = opaque' "$out_w"; then
    echo "FAIL(cli-selfhost-migrate-output) recursive_anonymous_records"
    sed -n '1,260p' "$out_w" || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" check "$out_w"; then
    echo "FAIL(cli-selfhost-check) recursive_anonymous_records"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) recursive_anonymous_records"
}

expect_migrate_ir_roundtrip() {
  # Exercises CiIR constructors and CiPrint output against golden strings.
  # Phase-A harness: grows as Phase-B lowering arms land. Invoked via the
  # hidden `with migrate --ir-roundtrip` developer flag.
  if ! run_cli "$tmpdir/out" "$tmpdir/err" migrate --ir-roundtrip; then
    echo "FAIL(cli-selfhost-migrate) ir_roundtrip (nonzero exit)"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "ci-roundtrip: PASS" "$tmpdir/out"; then
    echo "FAIL(cli-selfhost-migrate) ir_roundtrip (missing PASS marker)"
    echo "stdout:"; cat "$tmpdir/out" || true
    echo "stderr:"; cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-migrate) ir_roundtrip"
}

expect_opaque_field_access_is_rejected() {
  local case_dir="$tmpdir/opaque_field_access_case"
  local src="$case_dir/opaque_field_access.w"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
type T = opaque

fn f(p: *mut T):
    (p.x = 1)

fn main:
    let _ = 0
EOF

  if run_cli "$tmpdir/out" "$tmpdir/err" check "$src"; then
    echo "FAIL(cli-selfhost-check) opaque_field_access"
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "field access requires a concrete struct or union type; this type is opaque" "$tmpdir/err"; then
    echo "FAIL(cli-selfhost-diagnostic) opaque_field_access"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-check) opaque_field_access"
}

expect_pcre2_match_heapframe_is_concrete() {
  local obj="$tmpdir/pcre2_match_issue111.o"

  if grep -Fq 'type heapframe = opaque' lib/std/re/pcre2_match.w \
    || grep -Fq 'type heapframe_align = opaque' lib/std/re/pcre2_match.w; then
    echo "FAIL(cli-selfhost-stdlib) pcre2_match_heapframe"
    rg -n 'type heapframe|type heapframe_align' lib/std/re/pcre2_match.w || true
    failures=$((failures + 1))
    return
  fi

  if ! run_cli "$tmpdir/out" "$tmpdir/err" build lib/std/re/pcre2_match.w --emit-obj --no-prelude -O0 -o "$obj"; then
    echo "FAIL(cli-selfhost-build) pcre2_match_heapframe"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-build) pcre2_match_heapframe"
}

expect_build_reports_pcre2_link_failure() {
  local case_dir="$tmpdir/pcre2_link_failure_case"
  local src="$case_dir/pcre2_link_failure.w"
  local bin="$case_dir/pcre2_link_failure"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
use std.re.defs
use std.re.pcre2_compile

fn main:
    let _ = pcre2_compile_8((null as *const u8), 0, 0, (null as *mut c_int), (null as *mut c_ulong), (null as *mut pcre2_real_compile_context_8))
    print("ok")
EOF

  if run_cli "$tmpdir/out" "$tmpdir/err" build "$src" -o "$bin"; then
    echo "FAIL(cli-selfhost-build) pcre2_link_failure"
    if [[ -f "$bin" ]]; then
      ls -lh "$bin" || true
    fi
    failures=$((failures + 1))
    return
  fi

  if [[ -e "$bin" ]]; then
    echo "FAIL(cli-selfhost-build-artifact) pcre2_link_failure"
    ls -lh "$bin" || true
    failures=$((failures + 1))
    return
  fi

  if ! file_has_literal "$tmpdir/err" "Undefined symbols for architecture arm64:" \
    || ! file_has_literal "$tmpdir/err" "__pcre2_OP_lengths_8" \
    || ! file_has_literal "$tmpdir/err" "__pcre2_default_compile_context_8" \
    || ! file_has_literal "$tmpdir/err" "__pcre2_strlen_8" \
    || ! file_has_literal "$tmpdir/err" "ld: symbol(s) not found for architecture arm64" \
    || ! file_has_literal "$tmpdir/err" "error: build failed" \
    || ! file_forbid_literal "$tmpdir/err" "error: MIR lowering failed for function 'pcre2_compile_8'" \
    || ! file_forbid_literal "$tmpdir/err" "AST codegen was removed"; then
    echo "FAIL(cli-selfhost-build-diagnostic) pcre2_link_failure"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-build) pcre2_link_failure"
}

expect_init_in_cwd() {
  local case_dir="$tmpdir/init_in_cwd_case"
  local expected_name
  expected_name="$(basename "$case_dir")"
  mkdir -p "$case_dir"

  if ! (
    cd "$case_dir"
    run_cli "$tmpdir/out" "$tmpdir/err" init
  ); then
    echo "FAIL(cli-selfhost-init-run) init_in_cwd"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if [[ ! -f "$case_dir/with.toml" || ! -f "$case_dir/src/main.w" ]]; then
    echo "FAIL(cli-selfhost-init-layout) init_in_cwd"
    find "$case_dir" -maxdepth 3 -print | sort
    failures=$((failures + 1))
    return
  fi

  if [[ -e "$case_dir/$expected_name/with.toml" || -e "$case_dir/$expected_name/src/main.w" ]]; then
    echo "FAIL(cli-selfhost-init-nested) init_in_cwd"
    find "$case_dir" -maxdepth 3 -print | sort
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "name = \"$expected_name\"" "$case_dir/with.toml"; then
    echo "FAIL(cli-selfhost-init-manifest) init_in_cwd"
    cat "$case_dir/with.toml" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "created $expected_name" "$tmpdir/err"; then
    echo "FAIL(cli-selfhost-init-stderr) init_in_cwd"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-init) init_in_cwd"
}

expect_init_named_dir() {
  local case_dir="$tmpdir/init_named_dir_case"
  local project_name="sqlite"
  mkdir -p "$case_dir"

  if ! (
    cd "$case_dir"
    run_cli "$tmpdir/out" "$tmpdir/err" init "$project_name"
  ); then
    echo "FAIL(cli-selfhost-init-run) init_named_dir"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if [[ ! -f "$case_dir/$project_name/with.toml" || ! -f "$case_dir/$project_name/src/main.w" ]]; then
    echo "FAIL(cli-selfhost-init-layout) init_named_dir"
    find "$case_dir" -maxdepth 4 -print | sort
    failures=$((failures + 1))
    return
  fi

  if [[ -e "$case_dir/with.toml" || -e "$case_dir/src/main.w" ]]; then
    echo "FAIL(cli-selfhost-init-root-layout) init_named_dir"
    find "$case_dir" -maxdepth 4 -print | sort
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "name = \"$project_name\"" "$case_dir/$project_name/with.toml"; then
    echo "FAIL(cli-selfhost-init-manifest) init_named_dir"
    cat "$case_dir/$project_name/with.toml" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "created $project_name" "$tmpdir/err"; then
    echo "FAIL(cli-selfhost-init-stderr) init_named_dir"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "  $project_name/with.toml" "$tmpdir/err" || ! grep -Fq "  $project_name/src/main.w" "$tmpdir/err"; then
    echo "FAIL(cli-selfhost-init-paths) init_named_dir"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-init) init_named_dir"
}

expect_pointer_index_is_rejected() {
  local case_dir="$tmpdir/pointer_index_rejected_case"
  local src="$case_dir/pointer_index_rejected.w"
  local obj="$case_dir/pointer_index_rejected.o"
  mkdir -p "$case_dir"

  cat >"$src" <<'EOF'
fn main:
    var arr: [4]i32 = [0 as i32; 4]
    var p: *const i32 = null
    let value = arr[p]
    value
EOF

  if run_cli "$tmpdir/out" "$tmpdir/err" build "$src" --emit-obj -O0 -o "$obj"; then
    echo "FAIL(cli-selfhost-invalid-index-build) pointer_index_rejected"
    failures=$((failures + 1))
    return
  fi

  if ! grep -Fq "index expression must be an integer" "$tmpdir/err"; then
    echo "FAIL(cli-selfhost-invalid-index-diagnostic) pointer_index_rejected"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  if grep -Fq "LLVM verify error" "$tmpdir/err"; then
    echo "FAIL(cli-selfhost-invalid-index-verifier) pointer_index_rejected"
    cat "$tmpdir/err" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-invalid-index) pointer_index_rejected"
}

expect_init_in_cwd
expect_init_named_dir
expect_pointer_index_is_rejected
expect_emit_obj_global_symbols
expect_emit_obj_imported_symbols
expect_whole_program_extern_var_redecl
expect_imported_module_dependency_order
expect_imported_fn_beats_extern_redecl
expect_emit_obj_imported_pcre2_symbol
expect_emit_obj_imported_pcre2_symbol_multi_import
expect_migrate_global_init_list
expect_migrate_host_header_compat
expect_migrate_pcre2_config_template
expect_migrate_assignment_compat
expect_migrate_rvalue_sequencing
expect_migrate_cross_file_global_owner_arrays
expect_pcre2_prepare_shared_externs
expect_pcre2_prepare_width_prunes_whole_decls
expect_pcre2_prepare_shared_lets
expect_std_re_shared_dependency_imports
expect_migrate_initializer_regressions
expect_migrate_tentative_global_owner
expect_migrate_cross_file_tentative_global_owner
expect_migrate_noop_pointer_cast_exprs
expect_migrate_typed_cast_macros
expect_migrate_goto_shadowed_local
expect_migrate_recursive_anonymous_records
expect_migrate_ir_roundtrip
expect_opaque_field_access_is_rejected
expect_pcre2_match_heapframe_is_concrete
expect_build_reports_pcre2_link_failure

if [[ "$failures" -ne 0 ]]; then
  echo "cli selfhost tests: $failures failure(s)"
  exit 1
fi

echo "cli selfhost tests: PASS"
