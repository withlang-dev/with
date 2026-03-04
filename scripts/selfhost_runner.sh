#!/usr/bin/env bash
set -euo pipefail

# macOS on external volumes can leave direct executions of with-stage2 stuck in
# uninterruptible launcher state. Run tests via a local tmp copy instead.

SELFHOST_RUNNER_DIR=""

prepare_selfhost_runner() {
  local root_dir="$1"
  local bin_path="$2"
  local dylib_path=""
  local cand=""

  for cand in \
    "${root_dir}/runtime/libwith_llvm_bridge.dylib" \
    "${root_dir}/.with/build/runtime/libwith_llvm_bridge.dylib" \
    "${root_dir}/bootstrap/zig-out/bin/runtime/libwith_llvm_bridge.dylib"; do
    if [[ -f "$cand" ]]; then
      dylib_path="$cand"
      break
    fi
  done

  if [[ -z "$dylib_path" ]]; then
    echo "$bin_path"
    return 0
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d /tmp/with-selfhost-runner.XXXXXX)"
  mkdir -p "${tmp_dir}/runtime"
  cp "$bin_path" "${tmp_dir}/with-stage2"
  chmod +x "${tmp_dir}/with-stage2"
  cp "$dylib_path" "${tmp_dir}/runtime/libwith_llvm_bridge.dylib"
  SELFHOST_RUNNER_DIR="$tmp_dir"
  echo "${tmp_dir}/with-stage2"
}

cleanup_selfhost_runner() {
  if [[ -n "${SELFHOST_RUNNER_DIR}" && -d "${SELFHOST_RUNNER_DIR}" ]]; then
    rm -rf "${SELFHOST_RUNNER_DIR}"
  fi
  SELFHOST_RUNNER_DIR=""
}

