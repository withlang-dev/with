// rt/compat_runtime.w -- portable compiler-only runtime surface.
//
// Keep the public with_* ABI here. Platform-specific process, environment,
// signal, and stack-limit behavior lives in the platform runtime backend.

extern fn rt_compat_setenv_str(name: &str, value: &str) -> i32
extern fn rt_compat_install_interrupt_handlers() -> Unit
extern fn rt_compat_raise_stack_limit() -> Unit
extern fn rt_compat_interrupt_requested() -> i32
extern fn rt_compat_exec_binary(path: &str) -> i32
extern fn rt_compat_exec_argv(args: &str) -> i32
extern fn rt_compat_exec_argv_cwd(args: &str, cwd: &str) -> i32
extern fn rt_compat_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32
extern fn rt_compat_exec_argv_capture_input(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, stdin_path: &str) -> i32
extern fn rt_compat_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32
extern fn rt_compat_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32
extern fn rt_compat_exec_wait(pid: i32, timeout_ms: i32) -> i32
extern fn rt_compat_exec_try_wait(pid: i32) -> i32
extern fn rt_compat_exec_child_maxrss() -> i64
extern fn rt_compat_self_maxrss() -> i64

pub fn with_setenv_str(name: &str, value: &str) -> i32:
    rt_compat_setenv_str(name, value)

pub fn with_install_interrupt_handlers() -> Unit:
    rt_compat_install_interrupt_handlers()

pub fn with_raise_stack_limit() -> Unit:
    rt_compat_raise_stack_limit()

pub fn with_interrupt_requested() -> i32:
    rt_compat_interrupt_requested()

pub fn with_exec_binary(path: &str) -> i32:
    rt_compat_exec_binary(path)

pub fn with_exec_argv(args: &str) -> i32:
    rt_compat_exec_argv(args)

pub fn with_exec_argv_cwd(args: &str, cwd: &str) -> i32:
    rt_compat_exec_argv_cwd(args, cwd)

pub fn with_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32:
    rt_compat_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

pub fn with_exec_argv_capture_input(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, stdin_path: &str) -> i32:
    rt_compat_exec_argv_capture_input(args, stdout_path, stderr_path, timeout_ms, stdin_path)

pub fn with_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32:
    rt_compat_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, cwd)

pub fn with_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32:
    rt_compat_exec_argv_capture_spawn(args, stdout_path, stderr_path)

pub fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    rt_compat_exec_wait(pid, timeout_ms)

// #921: nonblocking reap probe — -2 while the child still runs; on death
// reaps it (recording child maxrss) and returns the decoded exit code.
pub fn with_exec_try_wait(pid: i32) -> i32:
    rt_compat_exec_try_wait(pid)

pub fn with_exec_child_maxrss() -> i64:
    rt_compat_exec_child_maxrss()

pub fn with_self_maxrss() -> i64:
    rt_compat_self_maxrss()
