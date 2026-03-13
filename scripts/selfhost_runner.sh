#!/usr/bin/env bash
set -euo pipefail

# Some macOS environments can leave direct executions of with-stage2 stuck in
# uninterruptible launcher state. Run tests via a local tmp copy instead.

SELFHOST_RUNNER_DIR=""
SELFHOST_RUNNER_ACTIVE_PID=""
SELFHOST_RUNNER_LOCK_DIR=""
SELFHOST_RUNNER_SPAWN_ISOLATED=0

ensure_selfhost_runner_tmp_root() {
  local root_dir="$1"
  local tmp_root="${root_dir}/out/tmp"
  mkdir -p "${tmp_root}" "${root_dir}/out/locks"
  export TMPDIR="${tmp_root}"
}

acquire_selfhost_runner_lock() {
  local root_dir="$1"
  local lock_dir="${root_dir}/out/locks/selfhost_runner.lock"
  local owner_pid=""

  ensure_selfhost_runner_tmp_root "$root_dir"

  if mkdir "$lock_dir" 2>/dev/null; then
    echo "$$" > "${lock_dir}/pid"
    SELFHOST_RUNNER_LOCK_DIR="$lock_dir"
    return 0
  fi

  if [[ -f "${lock_dir}/pid" ]]; then
    owner_pid="$(cat "${lock_dir}/pid" 2>/dev/null || true)"
  fi

  if [[ -n "$owner_pid" ]] && ! kill -0 "$owner_pid" 2>/dev/null; then
    rm -rf "$lock_dir"
    if mkdir "$lock_dir" 2>/dev/null; then
      echo "$$" > "${lock_dir}/pid"
      SELFHOST_RUNNER_LOCK_DIR="$lock_dir"
      return 0
    fi
  fi

  echo "error: selfhost runner lock is held (${lock_dir}, pid=${owner_pid:-unknown})" >&2
  return 1
}

release_selfhost_runner_lock() {
  if [[ -n "${SELFHOST_RUNNER_LOCK_DIR}" ]] && [[ -d "${SELFHOST_RUNNER_LOCK_DIR}" ]]; then
    rm -rf "${SELFHOST_RUNNER_LOCK_DIR}" >/dev/null 2>&1 || true
  fi
  SELFHOST_RUNNER_LOCK_DIR=""
}

prepare_selfhost_runner() {
  local root_dir="$1"
  local bin_path="$2"
  local dylib_path=""
  local cand=""

  acquire_selfhost_runner_lock "$root_dir"

  for cand in \
    "${root_dir}/out/lib/libwith_llvm_bridge.dylib" \
    "${root_dir}/runtime/libwith_llvm_bridge.dylib"; do
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
  tmp_dir="$(mktemp -d "${root_dir}/out/tmp/with-selfhost-runner.XXXXXX")"
  mkdir -p "${tmp_dir}/runtime"
  cp "$bin_path" "${tmp_dir}/with-stage2"
  chmod +x "${tmp_dir}/with-stage2"
  cp "$dylib_path" "${tmp_dir}/runtime/libwith_llvm_bridge.dylib"
  SELFHOST_RUNNER_DIR="$tmp_dir"
  echo "${tmp_dir}/with-stage2"
}

cleanup_selfhost_runner() {
  if [[ -n "${SELFHOST_RUNNER_ACTIVE_PID}" ]]; then
    _runner_kill_tree "${SELFHOST_RUNNER_ACTIVE_PID}" TERM
    _runner_kill_tree "${SELFHOST_RUNNER_ACTIVE_PID}" KILL
  fi
  SELFHOST_RUNNER_ACTIVE_PID=""
  SELFHOST_RUNNER_SPAWN_ISOLATED=0
  if [[ -n "${SELFHOST_RUNNER_DIR}" && -d "${SELFHOST_RUNNER_DIR}" ]]; then
    rm -rf "${SELFHOST_RUNNER_DIR}"
  fi
  SELFHOST_RUNNER_DIR=""
  release_selfhost_runner_lock
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

_runner_group_id() {
  local pid="$1"
  ps -o pgid= -p "$pid" 2>/dev/null | tr -d '[:space:]'
}

_runner_kill_group() {
  local pid="$1"
  local signal_name="$2"
  local pgid=""
  pgid="$(_runner_group_id "$pid")"
  if [[ -z "$pgid" ]]; then
    return 0
  fi
  kill "-${signal_name}" "--" "-${pgid}" 2>/dev/null || true
}

_runner_wait_briefly_for_exit() {
  local pid="$1"
  local spins="${2:-20}"
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    if [[ "$i" -ge "$spins" ]]; then
      return 1
    fi
    i=$((i + 1))
    sleep 0.1
  done
  return 0
}

_runner_spawn_capture() {
  local out_file="$1"
  local err_file="$2"
  shift 2

  SELFHOST_RUNNER_SPAWN_ISOLATED=0

  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" >"$out_file" 2>"$err_file" &
    SELFHOST_RUNNER_ACTIVE_PID="$!"
    SELFHOST_RUNNER_SPAWN_ISOLATED=1
    return 0
  fi

  if command -v perl >/dev/null 2>&1; then
    perl -MPOSIX=setsid -e 'POSIX::setsid() || die("setsid"); exec @ARGV' "$@" >"$out_file" 2>"$err_file" &
    SELFHOST_RUNNER_ACTIVE_PID="$!"
    SELFHOST_RUNNER_SPAWN_ISOLATED=1
    return 0
  fi

  "$@" >"$out_file" 2>"$err_file" &
  SELFHOST_RUNNER_ACTIVE_PID="$!"
}

_runner_stop_child() {
  local pid="$1"
  local signal_name="$2"

  if [[ "${SELFHOST_RUNNER_SPAWN_ISOLATED}" -ne 0 ]]; then
    _runner_kill_group "$pid" "$signal_name"
  fi
  _runner_kill_tree "$pid" "$signal_name"
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

  _runner_spawn_capture "$out_file" "$err_file" "$@"
  child_pid="$SELFHOST_RUNNER_ACTIVE_PID"
  start_time="$(date +%s)"

  while kill -0 "$child_pid" 2>/dev/null; do
    if [[ "$interrupted" -ne 0 ]]; then
      _runner_stop_child "$child_pid" TERM
      _runner_wait_briefly_for_exit "$child_pid" 20 || true
      _runner_stop_child "$child_pid" KILL
      _runner_wait_briefly_for_exit "$child_pid" 20 || true
      rc=130
      SELFHOST_RUNNER_ACTIVE_PID=""
      SELFHOST_RUNNER_SPAWN_ISOLATED=0
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
    _runner_stop_child "$child_pid" TERM
    _runner_wait_briefly_for_exit "$child_pid" 20 || true
    _runner_stop_child "$child_pid" KILL
    _runner_wait_briefly_for_exit "$child_pid" 20 || true
    rc=124
    SELFHOST_RUNNER_ACTIVE_PID=""
    SELFHOST_RUNNER_SPAWN_ISOLATED=0
    _runner_restore_trap INT "$old_int"
    _runner_restore_trap TERM "$old_term"
    return "$rc"
  fi

  wait "$child_pid"
  rc=$?
  SELFHOST_RUNNER_ACTIVE_PID=""
  SELFHOST_RUNNER_SPAWN_ISOLATED=0
  _runner_restore_trap INT "$old_int"
  _runner_restore_trap TERM "$old_term"
  return "$rc"
}

runner_exec_quiet() {
  local timeout_secs="$1"
  shift
  runner_exec_capture "$timeout_secs" /dev/null /dev/null "$@"
}
