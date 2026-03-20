#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MODE="${1:-stage2}"
TIMEOUT_SECS="${WITH_BUILD_TIMEOUT_SECS:-300}"
TIMEOUT_BIN=""
LAST_RUNTIME_DIR=""
LAST_STAGE_BIN=""
LAST_STAGE_LOG=""
OUT_DIR="${ROOT_DIR}/out"
OUT_BIN_DIR="${OUT_DIR}/bin"
OUT_LIB_DIR="${OUT_DIR}/lib"
OUT_LOG_DIR="${OUT_DIR}/log"
OUT_TMP_DIR="${OUT_DIR}/tmp"
OUT_RUNTIME_LINK="${OUT_BIN_DIR}/runtime"
OUT_GEN_DIR="${OUT_DIR}/gen"
GEN_MAIN_ENTRY="${OUT_GEN_DIR}/main.w"
STAGE1_BIN="${OUT_BIN_DIR}/with-stage1"
STAGE2_BIN="${OUT_BIN_DIR}/with-stage2"
STAGE3_BIN="${OUT_BIN_DIR}/with-stage3"
CANONICAL_BIN="${OUT_BIN_DIR}/with"

mkdir -p "${OUT_TMP_DIR}"
export TMPDIR="${OUT_TMP_DIR}"

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
fi

run_cmd() {
  local log_file="$1"
  local run_dir="$2"
  shift
  shift
  (
    cd "$run_dir"

    local child_pid=0
    local started=0
    local now=0
    local elapsed=0
    local pgid=""

    if command -v setsid >/dev/null 2>&1; then
      setsid "$@" >"$log_file" 2>&1 &
    else
      "$@" >"$log_file" 2>&1 &
    fi
    child_pid=$!
    started="$(date +%s)"

    if [ "${TIMEOUT_SECS}" -le 0 ]; then
      wait "$child_pid"
      exit $?
    fi

    while kill -0 "$child_pid" 2>/dev/null; do
      now="$(date +%s)"
      elapsed=$((now - started))
      if [ "$elapsed" -ge "${TIMEOUT_SECS}" ]; then
        pgid="$(ps -o pgid= -p "$child_pid" 2>/dev/null | tr -d '[:space:]')"
        if [ -n "$pgid" ]; then
          kill -TERM -- "-${pgid}" 2>/dev/null || true
        fi
        kill -TERM "$child_pid" 2>/dev/null || true
        sleep 1
        if [ -n "$pgid" ]; then
          kill -KILL -- "-${pgid}" 2>/dev/null || true
        fi
        kill -KILL "$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
        exit 124
      fi
      sleep 0.1
    done

    wait "$child_pid"
    exit $?
  )
}

validate_stage_binary() {
  local stage_name="$1"
  local compiler_bin="$2"
  local run_dir="$3"
  local wrapped_path="$4"
  local probe_log

  probe_log="${OUT_LOG_DIR}/${stage_name}.probe.log"

  local rc=0
  run_cmd "${probe_log}" "${run_dir}" env PATH="${wrapped_path}" "${compiler_bin}" version || rc=$?
  if [ "${rc}" -ne 0 ]; then
    if [ "${rc}" -eq 124 ] || [ "${rc}" -eq 137 ]; then
      echo "[${stage_name}] health probe timed out after ${TIMEOUT_SECS}s" >&2
    else
      echo "[${stage_name}] health probe failed" >&2
    fi
    if [ -s "${probe_log}" ]; then
      tail -n 80 "${probe_log}" >&2 || true
    else
      echo "[${stage_name}] health probe produced no compiler output" >&2
    fi
    return 1
  fi
}

copy_lib_artifacts_if_present() {
  local src_lib="$1"
  local dst_lib="$2"
  local name=""

  mkdir -p "${dst_lib}"
  for name in \
    libwith_llvm_bridge.dylib \
    llvm_bridge.o \
    helpers.o \
    support_runtime.o \
    with_runtime.o \
    fiber.o \
    fiber_asm.o \
    llvm_cc \
    llvm_link.rsp; do
    if [ -f "${src_lib}/${name}" ] && [ "${src_lib}/${name}" != "${dst_lib}/${name}" ]; then
      cp "${src_lib}/${name}" "${dst_lib}/${name}"
    fi
  done
}

# Find a directory containing compiled runtime artifacts (libwith_llvm_bridge.dylib).
resolve_lib_dir() {
  local compiler_bin="${1:-}"
  local compiler_dir=""
  local candidate=""

  if [ -n "${compiler_bin}" ]; then
    compiler_dir="$(cd "$(dirname "${compiler_bin}")" && pwd -P)"
  fi

  for candidate in \
    "${OUT_LIB_DIR}" \
    "${compiler_dir}/runtime" \
    "${compiler_dir}/../lib"; do
    if [ -n "${candidate}" ] && [ -d "${candidate}" ] && [ -f "${candidate}/libwith_llvm_bridge.dylib" ]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

# Compile runtime C sources into out/lib/.
refresh_lib_objects() {
  local runtime_src="${ROOT_DIR}/runtime"
  local lib_dir="${OUT_LIB_DIR}"
  local sdk_path=""
  local embedded_inc="${lib_dir}/embedded_stdlib.inc.h"

  mkdir -p "${lib_dir}"

  if ! command -v cc >/dev/null 2>&1; then
    return 0
  fi

  python3 "${ROOT_DIR}/scripts/generate_embedded_stdlib.py" "${ROOT_DIR}" "${embedded_inc}"
  sdk_path="$(xcrun --show-sdk-path 2>/dev/null || true)"
  if [ -n "${sdk_path}" ]; then
    cc -isysroot "${sdk_path}" -c "${runtime_src}/helpers.c" -o "${lib_dir}/helpers.o" >/dev/null 2>&1 || true
    cc -isysroot "${sdk_path}" -c "${runtime_src}/support_runtime.c" -o "${lib_dir}/support_runtime.o" >/dev/null 2>&1 || true
    cc -isysroot "${sdk_path}" -c "${runtime_src}/with_runtime.c" -o "${lib_dir}/with_runtime.o" >/dev/null 2>&1 || true
  else
    cc -c "${runtime_src}/helpers.c" -o "${lib_dir}/helpers.o" >/dev/null 2>&1 || true
    cc -c "${runtime_src}/support_runtime.c" -o "${lib_dir}/support_runtime.o" >/dev/null 2>&1 || true
    cc -c "${runtime_src}/with_runtime.c" -o "${lib_dir}/with_runtime.o" >/dev/null 2>&1 || true
  fi
}

ensure_lib_seeded() {
  local lib_dir="${OUT_LIB_DIR}"
  local src_lib=""

  mkdir -p "${lib_dir}"
  if [ ! -f "${lib_dir}/libwith_llvm_bridge.dylib" ]; then
    src_lib="$(resolve_lib_dir "${1:-}" || true)"
    if [ -n "${src_lib}" ] && [ "${src_lib}" != "${lib_dir}" ]; then
      copy_lib_artifacts_if_present "${src_lib}" "${lib_dir}"
    fi
  fi

  refresh_lib_objects
}

emit_workspace_seed_candidates() {
  if [ "${WITH_ALLOW_WORKSPACE_SEEDS:-0}" != "1" ]; then
    return 0
  fi
  local candidate=""
  local seed_dir=""

  candidate="${OUT_DIR}/main"
  if [ -x "${candidate}" ]; then
    echo "${candidate}"
  fi

  for seed_dir in "${OUT_DIR}"/build.*; do
    if [ -x "${seed_dir}/main" ]; then
      echo "${seed_dir}/main"
    fi
  done
}

emit_stage_entry_candidates() {
  local stage_name="$1"
  local compiler_bin="$2"
  local main_entry="${GEN_MAIN_ENTRY}"

  if [ -f "${main_entry}" ]; then
    printf '%s\n' "${main_entry}"
  elif [ -f "${ROOT_DIR}/src/main.w" ]; then
    printf '%s\n' "${ROOT_DIR}/src/main.w"
  fi
}

run_local_build() {
  local compiler_bin="$1"
  local stage_name="$2"
  local source_entry="$3"
  local tmp_dir
  local tmp_bin
  local compiler_dir
  local lib_dir
  local log_file
  local build_entry
  local host_cc
  local cc_wrapper_dir
  local wrapped_path
  local exec_dir
  local entry_name
  local entry_stem

  tmp_dir="$(mktemp -d "${OUT_TMP_DIR}/with-${stage_name}-XXXXXX")"
  tmp_bin="${tmp_dir}/with"
  compiler_dir="$(cd "$(dirname "$compiler_bin")" && pwd)"
  entry_name="$(basename "${source_entry}")"
  entry_stem="${entry_name%.w}"
  log_file="${OUT_LOG_DIR}/${stage_name}.${entry_stem}.log"
  LAST_STAGE_LOG="${log_file}"
  cp "$compiler_bin" "$tmp_bin"
  chmod +x "$tmp_bin"
  lib_dir="$(resolve_lib_dir "${compiler_bin}" || true)"
  if [ -z "${lib_dir}" ]; then
    lib_dir="${OUT_LIB_DIR}"
  fi
  # The compiler resolves runtime at <argv0>/runtime/ — symlink to lib_dir.
  ln -s "${lib_dir}" "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/out"
  ln -s "${lib_dir}" "${tmp_dir}/out/lib"
  ln -s "${ROOT_DIR}/lib" "${tmp_dir}/lib"
  ln -s "${ROOT_DIR}/src" "${tmp_dir}/src"
  rm -f "${tmp_dir}/main.w"
  ln -s "${source_entry}" "${tmp_dir}/main.w"
  build_entry="${tmp_dir}/main.w"
  exec_dir="${tmp_dir}"
  host_cc="$(command -v cc 2>/dev/null || true)"
  cc_wrapper_dir=""
  wrapped_path="${PATH}"
  if [ -n "$host_cc" ]; then
    cc_wrapper_dir="${tmp_dir}/.cc-wrap"
    mkdir -p "${cc_wrapper_dir}"
    cat >"${cc_wrapper_dir}/cc" <<EOF
#!/usr/bin/env bash
set -euo pipefail
real_cc="${host_cc}"
need_bridge=0
need_runtime=0
need_fiber=0
have_bridge=0
have_helpers=0
have_support_runtime=0
have_fiber=0
have_fiber_asm=0
for arg in "\$@"; do
  case "\$arg" in
    *libwith_llvm_bridge.dylib)
      have_bridge=1
      ;;
    *support_runtime.o)
      have_support_runtime=1
      ;;
    *helpers.o)
      have_helpers=1
      ;;
    *fiber.o)
      have_fiber=1
      ;;
    *fiber_asm.o)
      have_fiber_asm=1
      ;;
    *.o)
      if nm -u "\$arg" 2>/dev/null | grep -q '_wl_'; then
        need_bridge=1
      fi
      if nm -u "\$arg" 2>/dev/null | grep -Eq '(_with_|_int_to_string|_i32_to_str|_str_from_byte)'; then
        need_runtime=1
      fi
      if nm -u "\$arg" 2>/dev/null | grep -q '_with_channel_'; then
        need_fiber=1
      fi
      ;;
  esac
done
extra_args=()
if [ "\$need_runtime" -eq 1 ] && [ "\$have_support_runtime" -eq 0 ] && [ -f ./runtime/support_runtime.o ]; then
  extra_args+=(./runtime/support_runtime.o)
fi
if [ "\$need_runtime" -eq 1 ] && [ "\$have_helpers" -eq 0 ] && [ -f ./runtime/helpers.o ]; then
  extra_args+=(./runtime/helpers.o)
fi
if [ "\$need_fiber" -eq 1 ] && [ "\$have_fiber" -eq 0 ] && [ -f ./runtime/fiber.o ]; then
  extra_args+=(./runtime/fiber.o)
fi
if [ "\$need_fiber" -eq 1 ] && [ "\$have_fiber_asm" -eq 0 ] && [ -f ./runtime/fiber_asm.o ]; then
  extra_args+=(./runtime/fiber_asm.o)
fi
if [ "\$need_bridge" -eq 1 ] && [ "\$have_bridge" -eq 0 ] && [ -f ./runtime/libwith_llvm_bridge.dylib ]; then
  extra_args+=(./runtime/libwith_llvm_bridge.dylib)
fi
if [ "\${#extra_args[@]}" -gt 0 ]; then
  exec "\$real_cc" "\$@" "\${extra_args[@]}"
fi
exec "\$real_cc" "\$@"
EOF
    chmod +x "${cc_wrapper_dir}/cc"
    wrapped_path="${cc_wrapper_dir}:${PATH}"
  fi

  echo "[${stage_name}] compiler: $compiler_bin"
  echo "[${stage_name}] local runner: $tmp_bin"
  echo "[${stage_name}] entry: $source_entry"
  echo "[${stage_name}] lib dir: $lib_dir"
  echo "[${stage_name}] timeout: ${TIMEOUT_SECS}s"

  local rc=0
  run_cmd "$log_file" "$exec_dir" env PATH="${wrapped_path}" "$tmp_bin" build "${build_entry}" -o "${tmp_dir}/main" || rc=$?
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

  # The compiler outputs binary to cwd or out/ depending on version.
  local tmp_main="${tmp_dir}/main"
  if [ ! -s "$tmp_main" ]; then
    tmp_main="${tmp_dir}/out/main"
  fi
  if [ ! -s "$tmp_main" ]; then
    # Legacy: older seeds output to .with/build/
    tmp_main="${tmp_dir}/.with/build/main"
  fi
  if [ ! -s "$tmp_main" ]; then
    echo "[${stage_name}] build failed: no output binary found (silent failure)" >&2
    if [ -s "$log_file" ]; then
      tail -n 80 "$log_file" >&2 || true
    else
      echo "[${stage_name}] build log is empty" >&2
    fi
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! validate_stage_binary "${stage_name}" "${tmp_main}" "${exec_dir}" "${wrapped_path}"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  local staged_bin
  staged_bin="$(mktemp "${OUT_TMP_DIR}/with-${stage_name}-bin.XXXXXX")"
  cp "$tmp_main" "$staged_bin"
  chmod +x "$staged_bin"
  LAST_STAGE_BIN="$staged_bin"

  # Check if the build produced new runtime artifacts.
  local build_runtime=""
  for build_runtime in \
    "${tmp_dir}/out/lib" \
    "${tmp_dir}/.with/build/runtime"; do
    if [ -d "${build_runtime}" ] && [ -f "${build_runtime}/libwith_llvm_bridge.dylib" ]; then
      LAST_RUNTIME_DIR="${build_runtime}"
      # Keep temp dir alive for sync call.
      return 0
    fi
  done

  LAST_RUNTIME_DIR="$lib_dir"
  rm -rf "$tmp_dir"
}

install_stage_binary() {
  local src_bin="$1"
  local dst_bin="$2"
  local tmp_bin=""

  mkdir -p "$(dirname "${dst_bin}")"
  tmp_bin="$(mktemp "${dst_bin}.tmp.XXXXXX")"
  cp "${src_bin}" "${tmp_bin}"
  chmod +x "${tmp_bin}"
  mv -f "${tmp_bin}" "${dst_bin}"
}

resolve_seed_compiler() {
  local candidate=""
  if [ -n "${WITH_SELFHOST_SEED:-}" ] && [ -x "${WITH_SELFHOST_SEED}" ]; then
    echo "${WITH_SELFHOST_SEED}"
  fi
  for candidate in \
    "${WITH:-}" \
    "${STAGE3_BIN}" \
    "${STAGE2_BIN}" \
    "${CANONICAL_BIN}" \
    "${STAGE1_BIN}"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      echo "$candidate"
    fi
  done

  candidate="$(command -v with 2>/dev/null || true)"
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    echo "$candidate"
  fi

  emit_workspace_seed_candidates

  # Last resort: downloaded seed binary (not checked into git)
  if [ -x "${ROOT_DIR}/src/main" ]; then
    echo "${ROOT_DIR}/src/main"
  fi
}

ensure_out_layout() {
  ensure_lib_seeded
  mkdir -p "${OUT_BIN_DIR}" "${OUT_LIB_DIR}" "${OUT_LOG_DIR}"
  "${ROOT_DIR}/scripts/generate_versioned_sources.sh" "${OUT_DIR}" >/dev/null
  if [ -L "${OUT_RUNTIME_LINK}" ]; then
    rm -f "${OUT_RUNTIME_LINK}"
  elif [ -e "${OUT_RUNTIME_LINK}" ]; then
    rm -rf "${OUT_RUNTIME_LINK}"
  fi
  ln -s ../lib "${OUT_RUNTIME_LINK}"
}

sync_lib_artifacts() {
  local stage_name="$1"
  local src_lib=""
  local dst_lib="${OUT_LIB_DIR}"
  local src_lib_real=""
  local dst_lib_real=""

  if [ -n "$LAST_RUNTIME_DIR" ] && [ -d "$LAST_RUNTIME_DIR" ] && [ -f "${LAST_RUNTIME_DIR}/libwith_llvm_bridge.dylib" ]; then
    src_lib="$LAST_RUNTIME_DIR"
  else
    echo "[${stage_name}] build failed: no lib dir with libwith_llvm_bridge.dylib found" >&2
    return 1
  fi

  mkdir -p "$dst_lib"
  src_lib_real="$(cd "$src_lib" && pwd -P)"
  dst_lib_real="$(cd "$dst_lib" && pwd -P)"

  if [ "$src_lib_real" != "$dst_lib_real" ]; then
    cp "${src_lib}/libwith_llvm_bridge.dylib" "${dst_lib}/libwith_llvm_bridge.dylib"

    for f in llvm_bridge.o helpers.o support_runtime.o with_runtime.o fiber.o fiber_asm.o llvm_cc llvm_link.rsp; do
      if [ -f "${src_lib}/${f}" ]; then
        cp "${src_lib}/${f}" "${dst_lib}/${f}"
      fi
    done
  fi

  # Keep runtime helper objects aligned with source symbols.
  refresh_lib_objects

  case "$src_lib" in
    "${OUT_TMP_DIR}"/with-stage*/.with/build/runtime|"${OUT_TMP_DIR}"/with-stage*/out/lib)
      rm -rf "$(dirname "$(dirname "$src_lib")")" >/dev/null 2>&1 || true
      ;;
  esac
}

stage1() {
  ensure_out_layout
  mkdir -p "${OUT_LOG_DIR}"
  local seed_bin=""
  local source_entry=""
  local built=0
  while IFS= read -r seed_bin; do
    if [ -z "${seed_bin}" ]; then
      continue
    fi
    echo "[stage1] seed candidate: ${seed_bin}"
    while IFS= read -r source_entry; do
      if [ -z "${source_entry}" ]; then
        continue
      fi
      echo "[stage1] trying entry: ${source_entry}"
      if run_local_build "${seed_bin}" "stage1" "${source_entry}"; then
        built=1
        break 2
      fi
    done < <(emit_stage_entry_candidates "stage1" "${seed_bin}")
  done < <(resolve_seed_compiler)
  if [ "${built}" -eq 0 ]; then
    echo "[stage1] no working seed compiler found" >&2
    return 1
  fi
  echo "[stage1] selected seed: ${seed_bin}"
  sync_lib_artifacts "stage1"
  install_stage_binary "${LAST_STAGE_BIN}" "${STAGE1_BIN}"
  install_stage_binary "${LAST_STAGE_BIN}" "${CANONICAL_BIN}"
  rm -f "${LAST_STAGE_BIN}"
  LAST_STAGE_BIN=""
  echo "[stage1] wrote ${STAGE1_BIN}"
}

stage2() {
  stage1
  ensure_out_layout
  run_local_build "${STAGE1_BIN}" "stage2" "${GEN_MAIN_ENTRY}"
  sync_lib_artifacts "stage2"
  install_stage_binary "${LAST_STAGE_BIN}" "${STAGE2_BIN}"
  install_stage_binary "${LAST_STAGE_BIN}" "${CANONICAL_BIN}"
  rm -f "${LAST_STAGE_BIN}"
  LAST_STAGE_BIN=""
  echo "[stage2] wrote ${STAGE2_BIN}"
}

stage3() {
  stage2
  ensure_out_layout
  run_local_build "${STAGE2_BIN}" "stage3" "${GEN_MAIN_ENTRY}"
  sync_lib_artifacts "stage3"
  install_stage_binary "${LAST_STAGE_BIN}" "${STAGE3_BIN}"
  rm -f "${LAST_STAGE_BIN}"
  LAST_STAGE_BIN=""
  echo "[stage3] wrote ${STAGE3_BIN}"
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
  if [ -x "${STAGE2_BIN}" ]; then
    tmpd="$(mktemp -d "${OUT_TMP_DIR}/with-ver-XXXXXX")"
    tmpv="${tmpd}/with"
    cp "${STAGE2_BIN}" "$tmpv"
    chmod +x "$tmpv"
    if [ -d "${OUT_LIB_DIR}" ]; then
      ln -s "${OUT_LIB_DIR}" "${tmpd}/runtime"
    fi
    if version_out="$("$tmpv" version 2>&1)"; then
      echo "[stage2] version: ${version_out}"
    else
      echo "[stage2] warn: version probe failed" >&2
      if [ -n "$version_out" ]; then
        echo "$version_out" >&2
      fi
      if [ -x "${STAGE1_BIN}" ]; then
        cp "${STAGE1_BIN}" "${CANONICAL_BIN}"
        echo "[stage2] canonical fallback: ${STAGE1_BIN}" >&2
      fi
    fi
    rm -rf "$tmpd"
  fi
fi
