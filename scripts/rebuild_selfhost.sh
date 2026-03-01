#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-stage2}"
TIMEOUT_SECS="${WITH_BUILD_TIMEOUT_SECS:-300}"
TIMEOUT_BIN=""
LAST_RUNTIME_DIR=""

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
fi

run_cmd() {
  local log_file="$1"
  shift
  if [ -n "$TIMEOUT_BIN" ]; then
    (
      cd "$ROOT_DIR"
      "$TIMEOUT_BIN" -k 15s "${TIMEOUT_SECS}s" "$@" >"$log_file" 2>&1
    )
  else
    echo "[warn] no timeout command found; running without timeout" >&2
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
  local runtime_dir
  local log_file

  tmp_dir="$(mktemp -d /tmp/with-${stage_name}-XXXXXX)"
  tmp_bin="${tmp_dir}/with"
  compiler_dir="$(cd "$(dirname "$compiler_bin")" && pwd)"
  log_file="${ROOT_DIR}/.with/build/.${stage_name}.log"
  cp "$compiler_bin" "$tmp_bin"
  chmod +x "$tmp_bin"
  if [ "$stage_name" = "stage1" ]; then
    if [ -d "${compiler_dir}/runtime" ] && [ -f "${compiler_dir}/runtime/libwith_llvm_bridge.dylib" ]; then
      runtime_dir="${compiler_dir}/runtime"
    elif [ -d "${ROOT_DIR}/bootstrap/zig-out/bin/runtime" ] && [ -f "${ROOT_DIR}/bootstrap/zig-out/bin/runtime/libwith_llvm_bridge.dylib" ]; then
      runtime_dir="${ROOT_DIR}/bootstrap/zig-out/bin/runtime"
    elif [ -d "${compiler_dir}/runtime" ]; then
      runtime_dir="${compiler_dir}/runtime"
    else
      runtime_dir="${ROOT_DIR}/runtime"
    fi
  else
    if [ -d "${ROOT_DIR}/bootstrap/zig-out/bin/runtime" ] && [ -f "${ROOT_DIR}/bootstrap/zig-out/bin/runtime/libwith_llvm_bridge.dylib" ]; then
      runtime_dir="${ROOT_DIR}/bootstrap/zig-out/bin/runtime"
    elif [ -d "${compiler_dir}/runtime" ] && [ -f "${compiler_dir}/runtime/libwith_llvm_bridge.dylib" ]; then
      runtime_dir="${compiler_dir}/runtime"
    elif [ -d "${compiler_dir}/runtime" ]; then
      runtime_dir="${compiler_dir}/runtime"
    else
      runtime_dir="${ROOT_DIR}/runtime"
    fi
  fi
  ln -s "${runtime_dir}" "${tmp_dir}/runtime"

  echo "[${stage_name}] compiler: $compiler_bin"
  echo "[${stage_name}] local runner: $tmp_bin"
  echo "[${stage_name}] runtime dir: $runtime_dir"
  echo "[${stage_name}] timeout: ${TIMEOUT_SECS}s"

  local rc=0
  run_cmd "$log_file" "$tmp_bin" build "${ROOT_DIR}/src/main.w" || rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
      echo "[${stage_name}] build timed out after ${TIMEOUT_SECS}s" >&2
    fi
    echo "[${stage_name}] build failed (see $log_file)" >&2
    if [ -s "$log_file" ]; then
      tail -n 80 "$log_file" >&2 || true
    else
      echo "[${stage_name}] build failed with no compiler output (silent failure)" >&2
    fi
    rm -rf "$tmp_dir"
    return 1
  fi

  if [ ! -s "${ROOT_DIR}/.with/build/main" ]; then
    echo "[${stage_name}] build failed: missing .with/build/main (silent failure)" >&2
    if [ -s "$log_file" ]; then
      tail -n 80 "$log_file" >&2 || true
    else
      echo "[${stage_name}] build log is empty" >&2
    fi
    rm -rf "$tmp_dir"
    return 1
  fi

  LAST_RUNTIME_DIR="$runtime_dir"

  rm -rf "$tmp_dir"
}

ensure_bootstrap() {
  if [ ! -x "${ROOT_DIR}/bootstrap/zig-out/bin/with" ]; then
    echo "[bootstrap] building bootstrap compiler"
    (cd "${ROOT_DIR}/bootstrap" && zig build)
  fi
}

sync_runtime_artifacts() {
  local stage_name="$1"
  local build_runtime="${ROOT_DIR}/.with/build/runtime"
  local src_runtime=""
  local repo_runtime="${ROOT_DIR}/runtime"

  if [ -d "$build_runtime" ] && [ -f "${build_runtime}/libwith_llvm_bridge.dylib" ]; then
    src_runtime="$build_runtime"
  elif [ -n "$LAST_RUNTIME_DIR" ] && [ -d "$LAST_RUNTIME_DIR" ] && [ -f "${LAST_RUNTIME_DIR}/libwith_llvm_bridge.dylib" ]; then
    src_runtime="$LAST_RUNTIME_DIR"
  else
    echo "[${stage_name}] build failed: no runtime dir with libwith_llvm_bridge.dylib found" >&2
    return 1
  fi

  mkdir -p "$repo_runtime"

  cp "${src_runtime}/libwith_llvm_bridge.dylib" "${repo_runtime}/libwith_llvm_bridge.dylib"

  for f in llvm_bridge.o helpers.o fiber.o fiber_asm.o llvm_cc llvm_link.rsp; do
    if [ -f "${src_runtime}/${f}" ]; then
      cp "${src_runtime}/${f}" "${repo_runtime}/${f}"
    fi
  done
}

stage1() {
  ensure_bootstrap
  mkdir -p "${ROOT_DIR}/.with/build"
  rm -f "${ROOT_DIR}/with-stage1" "${ROOT_DIR}/with"
  run_local_build "${ROOT_DIR}/bootstrap/zig-out/bin/with" "stage1"
  sync_runtime_artifacts "stage1"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with-stage1"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with"
  echo "[stage1] wrote with-stage1"
}

stage2() {
  stage1
  rm -f "${ROOT_DIR}/with-stage2"
  run_local_build "${ROOT_DIR}/with-stage1" "stage2"
  sync_runtime_artifacts "stage2"
  cp "${ROOT_DIR}/.with/build/main" "${ROOT_DIR}/with-stage2"
  echo "[stage2] wrote with-stage2"
}

stage3() {
  stage2
  rm -f "${ROOT_DIR}/with-stage3"
  run_local_build "${ROOT_DIR}/with-stage2" "stage3"
  sync_runtime_artifacts "stage3"
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
    tmpd="$(mktemp -d /tmp/with-ver-XXXXXX)"
    tmpv="${tmpd}/with"
    cp "${ROOT_DIR}/with-stage2" "$tmpv"
    chmod +x "$tmpv"
    if [ -d "${ROOT_DIR}/runtime" ]; then
      ln -s "${ROOT_DIR}/runtime" "${tmpd}/runtime"
    fi
    if version_out="$("$tmpv" version 2>&1)"; then
      echo "[stage2] version: ${version_out}"
    else
      echo "[stage2] error: version probe failed" >&2
      if [ -n "$version_out" ]; then
        echo "$version_out" >&2
      fi
      rm -rf "$tmpd"
      exit 1
    fi
    rm -rf "$tmpd"
  fi
fi
