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

if [[ "$failures" -ne 0 ]]; then
  echo "cli selfhost tests: $failures failure(s)"
  exit 1
fi

echo "cli selfhost tests: PASS"
