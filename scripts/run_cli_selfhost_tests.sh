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
      if (name == "explicit_global" || name == "zero_global") {
        if ($2 == "U") bad = 1
        seen[name] = 1
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
EOF

  cat >"$user_src" <<'EOF'
use shared
@[c_export("use_shared")]
fn use_shared() -> i32: shared_var
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

  if ! /usr/bin/nm -g "$shared_obj" | awk '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name == "shared_var") {
        if (type == "U") bad = 1
        seen[name] = 1
      }
    }
    END {
      exit !(seen["shared_var"]) || bad
    }
  '; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) emit_obj_import_owner"
    /usr/bin/nm -g "$shared_obj" || true
    failures=$((failures + 1))
    return
  fi

  if ! /usr/bin/nm -g "$user_obj" | awk '
    {
      type = (NF >= 2 ? $(NF - 1) : "")
      name = $NF
      sub(/^_/, "", name)
      if (name == "use_shared") {
        if (type == "U") bad = 1
        seen[name] = 1
      } else if (name == "shared_var") {
        if (type != "U") bad = 1
        seen[name] = 1
      }
    }
    END {
      exit !(seen["use_shared"] && seen["shared_var"]) || bad
    }
  '; then
    echo "FAIL(cli-selfhost-emit-obj-symbols) emit_obj_import_user"
    /usr/bin/nm -g "$user_obj" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(cli-selfhost-emit-obj) emit_obj_imported_symbols"
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

expect_init_in_cwd
expect_init_named_dir
expect_emit_obj_global_symbols
expect_emit_obj_imported_symbols
expect_migrate_global_init_list
expect_migrate_host_header_compat
expect_pcre2_prepare_shared_externs

if [[ "$failures" -ne 0 ]]; then
  echo "cli selfhost tests: $failures failure(s)"
  exit 1
fi

echo "cli selfhost tests: PASS"
