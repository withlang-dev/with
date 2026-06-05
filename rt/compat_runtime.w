// rt/compat_runtime.w -- portable compiler-only runtime surface.
//
// Keep the public with_* ABI here. Platform-specific process, environment,
// signal, and stack-limit behavior lives in the platform runtime backend.

extern fn rt_compat_setenv_str(name: str, value: str) -> i32
extern fn rt_compat_install_interrupt_handlers() -> void
extern fn rt_compat_raise_stack_limit() -> void
extern fn rt_compat_interrupt_requested() -> i32
extern fn rt_compat_exec_binary(path: str) -> i32
extern fn rt_compat_exec_argv(args: str) -> i32
extern fn rt_compat_exec_argv_cwd(args: str, cwd: str) -> i32
extern fn rt_compat_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn rt_compat_exec_argv_capture_input(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> i32
extern fn rt_compat_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn rt_compat_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32
extern fn rt_compat_exec_wait(pid: i32, timeout_ms: i32) -> i32

@[c_export("with_setenv_str")]
pub fn setenv_str(name: str, value: str) -> i32:
    rt_compat_setenv_str(name, value)

@[c_export("with_install_interrupt_handlers")]
pub fn install_interrupt_handlers():
    rt_compat_install_interrupt_handlers()

@[c_export("with_raise_stack_limit")]
pub fn raise_stack_limit():
    rt_compat_raise_stack_limit()

@[c_export("with_interrupt_requested")]
pub fn interrupt_requested() -> i32:
    rt_compat_interrupt_requested()

@[c_export("with_exec_binary")]
pub fn exec_binary(path: str) -> i32:
    rt_compat_exec_binary(path)

@[c_export("with_exec_argv")]
pub fn exec_argv(args: str) -> i32:
    rt_compat_exec_argv(args)

@[c_export("with_exec_argv_cwd")]
pub fn exec_argv_cwd(args: str, cwd: str) -> i32:
    rt_compat_exec_argv_cwd(args, cwd)

@[c_export("with_exec_argv_capture")]
pub fn exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    rt_compat_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

@[c_export("with_exec_argv_capture_input")]
pub fn exec_argv_capture_input(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> i32:
    rt_compat_exec_argv_capture_input(args, stdout_path, stderr_path, timeout_ms, stdin_path)

@[c_export("with_exec_argv_capture_cwd")]
pub fn exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32:
    rt_compat_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, cwd)

@[c_export("with_exec_argv_capture_spawn")]
pub fn exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32:
    rt_compat_exec_argv_capture_spawn(args, stdout_path, stderr_path)

@[c_export("with_exec_wait")]
pub fn exec_wait(pid: i32, timeout_ms: i32) -> i32:
    rt_compat_exec_wait(pid, timeout_ms)
