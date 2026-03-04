#!/usr/bin/env bash
set -euo pipefail

# macOS on external volumes can leave direct executions of with-stage2 stuck in
# uninterruptible launcher state. Run tests via a local tmp copy instead.

SELFHOST_RUNNER_DIR=""
SELFHOST_RUNNER_ACTIVE_PID=""

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

_runner_restore_trap() {
  local sig="$1"
  local old_trap="$2"
  if [[ -n "$old_trap" ]]; then
    eval "$old_trap"
  else
    trap - "$sig"
  fi
}

_runner_kill_tree() {
  local pid="$1"
  local signal_name="$2"
  local children=""
  local child=""

  children="$(pgrep -P "$pid" 2>/dev/null || true)"
  for child in $children; do
    _runner_kill_tree "$child" "$signal_name"
  done
  kill "-${signal_name}" "$pid" 2>/dev/null || kill -"$signal_name" "$pid" 2>/dev/null || true
}

# Run command in a controllable background child with optional timeout.
# Returns:
#   0+ command status
#   124 on timeout
#   130 on interrupt/termination signal
runner_exec_capture() {
  local timeout_secs="$1"
  local out_file="$2"
  local err_file="$3"
  shift 3

  local old_int old_term
  local interrupted=0
  local timed_out=0
  local child_pid=0
  local start_time=0
  local now=0
  local elapsed=0
  local rc=0

  old_int="$(trap -p INT || true)"
  old_term="$(trap -p TERM || true)"
  trap 'interrupted=1' INT TERM

  "$@" >"$out_file" 2>"$err_file" &
  child_pid=$!
  SELFHOST_RUNNER_ACTIVE_PID="$child_pid"
  start_time="$(date +%s)"

  while kill -0 "$child_pid" 2>/dev/null; do
    if [[ "$interrupted" -ne 0 ]]; then
      _runner_kill_tree "$child_pid" TERM
      sleep 1
      _runner_kill_tree "$child_pid" KILL
      rc=130
      SELFHOST_RUNNER_ACTIVE_PID=""
      _runner_restore_trap INT "$old_int"
      _runner_restore_trap TERM "$old_term"
      return "$rc"
    fi

    if [[ "$timeout_secs" -gt 0 ]]; then
      now="$(date +%s)"
      elapsed=$((now - start_time))
      if [[ "$elapsed" -ge "$timeout_secs" ]]; then
        timed_out=1
        break
      fi
    fi

    sleep 0.1
  done

  if [[ "$timed_out" -ne 0 ]]; then
    _runner_kill_tree "$child_pid" TERM
    sleep 1
    _runner_kill_tree "$child_pid" KILL
    rc=124
    SELFHOST_RUNNER_ACTIVE_PID=""
    _runner_restore_trap INT "$old_int"
    _runner_restore_trap TERM "$old_term"
    return "$rc"
  fi

  wait "$child_pid"
  rc=$?
  SELFHOST_RUNNER_ACTIVE_PID=""
  _runner_restore_trap INT "$old_int"
  _runner_restore_trap TERM "$old_term"
  return "$rc"
}

runner_exec_quiet() {
  local timeout_secs="$1"
  shift
  runner_exec_capture "$timeout_secs" /dev/null /dev/null "$@"
}
