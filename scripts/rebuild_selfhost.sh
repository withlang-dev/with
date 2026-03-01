#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-stage2}"
TIMEOUT_SECS="${WITH_BUILD_TIMEOUT_SECS:-300}"

run_cmd() {
  local log_file="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    (
      cd "$ROOT_DIR"
      timeout "$TIMEOUT_SECS" "$@" >"$log_file" 2>&1
    )
  else
    (
      cd "$ROOT_DIR"
      "$@" >"$log_file" 2>&1
    )
  fi
}

run_local_build() {
  local compiler_bin="$1"
  local stage_name="$2"
  local tmp_dir
  local tmp_bin
  local compiler_dir
  local log_file

  tmp_dir="$(mktemp -d /tmp/with-${stage_name}-XXXXXX)"
  tmp_bin="${tmp_dir}/with"
  compiler_dir="$(cd "$(dirname "$compiler_bin")" && pwd)"
  log_file="${ROOT_DIR}/.with/build/.${stage_name}.log"
  cp "$compiler_bin" "$tmp_bin"
  chmod +x "$tmp_bin"
  if [ -d "${compiler_dir}/runtime" ]; then
    ln -s "${compiler_dir}/runtime" "${tmp_dir}/runtime"
  else
    ln -s "${ROOT_DIR}/runtime" "${tmp_dir}/runtime"
  fi

  echo "[${stage_name}] compiler: $compiler_bin"
  echo "[${stage_name}] local runner: $tmp_bin"
  echo "[${stage_name}] timeout: ${TIMEOUT_SECS}s"

  if ! run_cmd "$log_file" "$tmp_bin" build "${ROOT_DIR}/src/main.w"; then
    echo "[${stage_name}] build failed (see $log_file)" >&2
    tail -n 80 "$log_file" >&2 || true
    rm -rf "$tmp_dir"
    return 1
  fi

  rm -rf "$tmp_dir"
}

ensure_bootstrap() {
  if [ ! -x "${ROOT_DIR}/bootstrap/zig-out/bin/with" ]; then
    echo "[bootstrap] building bootstrap compiler"
    (cd "${ROOT_DIR}/bootstrap" && zig build)
  fi
}

stage1() {
  ensure_bootstrap
  mkdir -p "${ROOT_DIR}/.with/build"
  run_local_build "${ROOT_DIR}/bootstrap/zig-out/bin/with" "stage1"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with-stage1"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with"
  echo "[stage1] wrote with-stage1"
}

stage2() {
  stage1
  run_local_build "${ROOT_DIR}/with-stage1" "stage2"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with-stage2"
  echo "[stage2] wrote with-stage2"
}

stage3() {
  stage2
  run_local_build "${ROOT_DIR}/with-stage2" "stage3"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with-stage3"
  echo "[stage3] wrote with-stage3"
}

case "$MODE" in
  stage1)
    stage1
    ;;
  stage2)
    stage2
    ;;
  stage3)
    stage3
    ;;
  all)
    stage3
    ;;
  *)
    echo "usage: $0 [stage1|stage2|stage3|all]" >&2
    exit 2
    ;;
esac

if [ "$MODE" = "stage2" ] || [ "$MODE" = "stage3" ] || [ "$MODE" = "all" ]; then
  if [ -x "${ROOT_DIR}/with-stage2" ]; then
    tmpv="$(mktemp /tmp/with-ver-XXXXXX)"
    cp "${ROOT_DIR}/with-stage2" "$tmpv"
    chmod +x "$tmpv"
    echo "[stage2] version: $($tmpv version 2>/dev/null || true)"
    rm -f "$tmpv"
  fi
fi
