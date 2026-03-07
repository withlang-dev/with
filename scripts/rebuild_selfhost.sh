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
OUT_RUNTIME_LINK="${OUT_BIN_DIR}/runtime"
STAGE1_BIN="${OUT_BIN_DIR}/with-stage1"
STAGE2_BIN="${OUT_BIN_DIR}/with-stage2"
STAGE3_BIN="${OUT_BIN_DIR}/with-stage3"
CANONICAL_BIN="${OUT_BIN_DIR}/with"

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
  local probe_src
  local probe_log

  probe_src="${run_dir}/probe.w"
  probe_log="${ROOT_DIR}/.with/build/.${stage_name}.probe.log"
  cat >"${probe_src}" <<'EOF'
fn main:
    let x = 1
EOF

  local rc=0
  run_cmd "${probe_log}" "${run_dir}" env PATH="${wrapped_path}" "${compiler_bin}" check "${probe_src}" || rc=$?
  rm -f "${probe_src}"
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

copy_runtime_artifacts_if_present() {
  local src_runtime="$1"
  local dst_runtime="$2"
  local name=""

  mkdir -p "${dst_runtime}"
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
    if [ -f "${src_runtime}/${name}" ] && [ "${src_runtime}/${name}" != "${dst_runtime}/${name}" ]; then
      cp "${src_runtime}/${name}" "${dst_runtime}/${name}"
    fi
  done
}

resolve_runtime_dir() {
  local compiler_bin="${1:-}"
  local compiler_dir=""
  local candidate=""

  if [ -n "${compiler_bin}" ]; then
    compiler_dir="$(cd "$(dirname "${compiler_bin}")" && pwd -P)"
  fi

  for candidate in \
    "${ROOT_DIR}/runtime" \
    "${ROOT_DIR}/src/runtime" \
    "${compiler_dir}/runtime" \
    "${ROOT_DIR}/bootstrap/zig-out/bin/runtime"; do
    if [ -n "${candidate}" ] && [ -d "${candidate}" ] && [ -f "${candidate}/libwith_llvm_bridge.dylib" ]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

refresh_repo_runtime_objects() {
  local repo_runtime="${ROOT_DIR}/runtime"
  local sdk_path=""

  if ! command -v cc >/dev/null 2>&1; then
    return 0
  fi

  sdk_path="$(xcrun --show-sdk-path 2>/dev/null || true)"
  if [ -n "${sdk_path}" ]; then
    cc -isysroot "${sdk_path}" -c "${repo_runtime}/helpers.c" -o "${repo_runtime}/helpers.o" >/dev/null 2>&1 || true
    cc -isysroot "${sdk_path}" -c "${repo_runtime}/support_runtime.c" -o "${repo_runtime}/support_runtime.o" >/dev/null 2>&1 || true
    cc -isysroot "${sdk_path}" -c "${repo_runtime}/with_runtime.c" -o "${repo_runtime}/with_runtime.o" >/dev/null 2>&1 || true
  else
    cc -c "${repo_runtime}/helpers.c" -o "${repo_runtime}/helpers.o" >/dev/null 2>&1 || true
    cc -c "${repo_runtime}/support_runtime.c" -o "${repo_runtime}/support_runtime.o" >/dev/null 2>&1 || true
    cc -c "${repo_runtime}/with_runtime.c" -o "${repo_runtime}/with_runtime.o" >/dev/null 2>&1 || true
  fi
}

ensure_repo_runtime_seeded() {
  local repo_runtime="${ROOT_DIR}/runtime"
  local runtime_dir=""

  mkdir -p "${repo_runtime}"
  if [ ! -f "${repo_runtime}/libwith_llvm_bridge.dylib" ]; then
    runtime_dir="$(resolve_runtime_dir "${1:-}" || true)"
    if [ -n "${runtime_dir}" ] && [ "${runtime_dir}" != "${repo_runtime}" ]; then
      copy_runtime_artifacts_if_present "${runtime_dir}" "${repo_runtime}"
    fi
  fi

  refresh_repo_runtime_objects
}

emit_workspace_seed_candidates() {
  if [ "${WITH_ALLOW_WORKSPACE_SEEDS:-0}" != "1" ]; then
    return 0
  fi
  local candidate=""
  local seed_dir=""

  candidate="${ROOT_DIR}/.with/build/main"
  if [ -x "${candidate}" ]; then
    echo "${candidate}"
  fi

  for seed_dir in "${ROOT_DIR}"/.with/build.*; do
    if [ -x "${seed_dir}/main" ]; then
      echo "${seed_dir}/main"
    fi
  done
}

emit_stage_entry_candidates() {
  local stage_name="$1"
  local compiler_bin="$2"
  local main_entry="${ROOT_DIR}/src/main.w"
  local compat_entry="${ROOT_DIR}/src/main_emit_temp.w"
  local bootstrap_entry="${ROOT_DIR}/src/bootstrap_main.w"

  if is_bootstrap_seed "${compiler_bin}"; then
    if [ -f "${bootstrap_entry}" ]; then
      printf '%s\n' "${bootstrap_entry}"
    fi
    return 0
  fi

  if [ "$stage_name" = "stage1" ]; then
    if [ -f "${main_entry}" ]; then
      printf '%s\n' "${main_entry}"
    fi
    if [ -f "${compat_entry}" ]; then
      printf '%s\n' "${compat_entry}"
    fi
    if [ -f "${bootstrap_entry}" ]; then
      printf '%s\n' "${bootstrap_entry}"
    fi
    return 0
  fi

  if [ -f "${main_entry}" ]; then
    printf '%s\n' "${main_entry}"
  fi
}

run_local_build() {
  local compiler_bin="$1"
  local stage_name="$2"
  local source_entry="$3"
  local tmp_dir
  local tmp_bin
  local compiler_dir
  local runtime_dir
  local log_file
  local build_entry
  local host_cc
  local cc_wrapper_dir
  local wrapped_path
  local exec_dir
  local entry_name
  local entry_stem

  tmp_dir="$(mktemp -d /tmp/with-${stage_name}-XXXXXX)"
  tmp_bin="${tmp_dir}/with"
  compiler_dir="$(cd "$(dirname "$compiler_bin")" && pwd)"
  entry_name="$(basename "${source_entry}")"
  entry_stem="${entry_name%.w}"
  log_file="${ROOT_DIR}/.with/build/.${stage_name}.${entry_stem}.log"
  LAST_STAGE_LOG="${log_file}"
  cp "$compiler_bin" "$tmp_bin"
  chmod +x "$tmp_bin"
  runtime_dir="$(resolve_runtime_dir "${compiler_bin}" || true)"
  if [ -z "${runtime_dir}" ]; then
    runtime_dir="${ROOT_DIR}/runtime"
  fi
  ln -s "${runtime_dir}" "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/.with/build"
  ln -s "${runtime_dir}" "${tmp_dir}/.with/build/runtime"
  ln -s "${ROOT_DIR}/lib" "${tmp_dir}/lib"
  ln -s "${ROOT_DIR}/src" "${tmp_dir}/src"
  if [ -d "${ROOT_DIR}/src/compiler" ]; then
    ln -s "${ROOT_DIR}/src/compiler" "${tmp_dir}/compiler"
  fi
  local src_file=""
  for src_file in "${ROOT_DIR}"/src/*.w; do
    [ -e "${src_file}" ] || continue
    ln -s "${src_file}" "${tmp_dir}/$(basename "${src_file}")"
  done
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
  echo "[${stage_name}] runtime dir: $runtime_dir"
  echo "[${stage_name}] timeout: ${TIMEOUT_SECS}s"

  local rc=0
  run_cmd "$log_file" "$exec_dir" env PATH="${wrapped_path}" "$tmp_bin" build "${build_entry}" || rc=$?
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

  local tmp_main="${tmp_dir}/main"
  if [ ! -s "$tmp_main" ]; then
    tmp_main="${tmp_dir}/.with/build/main"
  fi
  if [ ! -s "$tmp_main" ]; then
    echo "[${stage_name}] build failed: missing ${tmp_main} (silent failure)" >&2
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
  staged_bin="$(mktemp /tmp/with-${stage_name}-bin.XXXXXX)"
  cp "$tmp_main" "$staged_bin"
  chmod +x "$staged_bin"
  LAST_STAGE_BIN="$staged_bin"

  if [ -d "${tmp_dir}/.with/build/runtime" ] && [ -f "${tmp_dir}/.with/build/runtime/libwith_llvm_bridge.dylib" ]; then
    LAST_RUNTIME_DIR="${tmp_dir}/.with/build/runtime"
    # Keep temp dir alive for runtime sync call.
    # It will be removed by sync_runtime_artifacts once copied.
    return 0
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

is_bootstrap_seed() {
  local candidate="$1"
  case "$candidate" in
    "${ROOT_DIR}/bootstrap/zig-out/bin/with"|*/bootstrap/zig-out/bin/with)
      return 0
      ;;
  esac
  return 1
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
    if [ -n "$candidate" ] && [ -x "$candidate" ] && ! is_bootstrap_seed "$candidate"; then
      echo "$candidate"
    fi
  done

  candidate="$(command -v with 2>/dev/null || true)"
  if [ -n "$candidate" ] && [ -x "$candidate" ] && ! is_bootstrap_seed "$candidate"; then
    echo "$candidate"
  fi

  emit_workspace_seed_candidates

  ensure_bootstrap
  echo "${ROOT_DIR}/bootstrap/zig-out/bin/with"
}

ensure_out_layout() {
  ensure_repo_runtime_seeded
  mkdir -p "${OUT_BIN_DIR}"
  if [ -L "${OUT_RUNTIME_LINK}" ]; then
    rm -f "${OUT_RUNTIME_LINK}"
  elif [ -e "${OUT_RUNTIME_LINK}" ]; then
    rm -rf "${OUT_RUNTIME_LINK}"
  fi
  ln -s "${ROOT_DIR}/runtime" "${OUT_RUNTIME_LINK}"
}

sync_runtime_artifacts() {
  local stage_name="$1"
  local build_runtime="${ROOT_DIR}/.with/build/runtime"
  local src_runtime=""
  local repo_runtime="${ROOT_DIR}/runtime"
  local src_runtime_real=""
  local repo_runtime_real=""

  if [ -d "$build_runtime" ] && [ -f "${build_runtime}/libwith_llvm_bridge.dylib" ]; then
    src_runtime="$build_runtime"
  elif [ -n "$LAST_RUNTIME_DIR" ] && [ -d "$LAST_RUNTIME_DIR" ] && [ -f "${LAST_RUNTIME_DIR}/libwith_llvm_bridge.dylib" ]; then
    src_runtime="$LAST_RUNTIME_DIR"
  else
    echo "[${stage_name}] build failed: no runtime dir with libwith_llvm_bridge.dylib found" >&2
    return 1
  fi

  mkdir -p "$repo_runtime"
  src_runtime_real="$(cd "$src_runtime" && pwd -P)"
  repo_runtime_real="$(cd "$repo_runtime" && pwd -P)"

  if [ "$src_runtime_real" != "$repo_runtime_real" ]; then
    cp "${src_runtime}/libwith_llvm_bridge.dylib" "${repo_runtime}/libwith_llvm_bridge.dylib"

    for f in llvm_bridge.o helpers.o support_runtime.o with_runtime.o fiber.o fiber_asm.o llvm_cc llvm_link.rsp; do
      if [ -f "${src_runtime}/${f}" ]; then
        cp "${src_runtime}/${f}" "${repo_runtime}/${f}"
      fi
    done
  fi

  # Keep runtime helper objects aligned with source symbols required by the
  # current std/prelude surface (for example with_lines_out/with_parse_i64).
  refresh_repo_runtime_objects

  case "$src_runtime" in
    /tmp/with-stage*/.with/build/runtime)
      rm -rf "$(dirname "$(dirname "$(dirname "$src_runtime")")")" >/dev/null 2>&1 || true
      ;;
  esac
}

stage1() {
  ensure_out_layout
  mkdir -p "${ROOT_DIR}/.with/build"
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
  sync_runtime_artifacts "stage1"
  cp "${LAST_STAGE_BIN}" "${STAGE1_BIN}"
  cp "${LAST_STAGE_BIN}" "${CANONICAL_BIN}"
  rm -f "${LAST_STAGE_BIN}"
  LAST_STAGE_BIN=""
  echo "[stage1] wrote ${STAGE1_BIN}"
}

stage2() {
  stage1
  ensure_out_layout
  run_local_build "${STAGE1_BIN}" "stage2" "${ROOT_DIR}/src/main.w"
  sync_runtime_artifacts "stage2"
  cp "${LAST_STAGE_BIN}" "${STAGE2_BIN}"
  cp "${LAST_STAGE_BIN}" "${CANONICAL_BIN}"
  rm -f "${LAST_STAGE_BIN}"
  LAST_STAGE_BIN=""
  echo "[stage2] wrote ${STAGE2_BIN}"
}

stage3() {
  stage2
  ensure_out_layout
  run_local_build "${STAGE2_BIN}" "stage3" "${ROOT_DIR}/src/main.w"
  sync_runtime_artifacts "stage3"
  cp "${LAST_STAGE_BIN}" "${STAGE3_BIN}"
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
    tmpd="$(mktemp -d /tmp/with-ver-XXXXXX)"
    tmpv="${tmpd}/with"
    cp "${STAGE2_BIN}" "$tmpv"
    chmod +x "$tmpv"
    if [ -d "${ROOT_DIR}/runtime" ]; then
      ln -s "${ROOT_DIR}/runtime" "${tmpd}/runtime"
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
