// Compiler runtime boundary. Raw runtime exports are declared here; compiler
// modules should depend on these typed wrappers instead of redeclaring externs.

extern fn with_eprint(s: str) -> void
extern fn with_exec_binary(path: str) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_exec_argv_cwd(args: str, cwd: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_tree(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32

pub fn runtime_eprint(s: str):
    with_eprint(s)

pub fn runtime_exec_binary(path: str) -> i32:
    with_exec_binary(path)

pub fn runtime_exec_argv(args: str) -> i32:
    with_exec_argv(args)

pub fn runtime_exec_argv_cwd(args: str, cwd: str) -> i32:
    with_exec_argv_cwd(args, cwd)

pub fn runtime_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    with_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

pub fn runtime_arg_at(idx: i32) -> str:
    with_arg_at(idx)

pub fn runtime_write_file(path: str, data: str) -> i32:
    with_fs_write_file(path, data)

pub fn runtime_read_file(path: str) -> str:
    with_fs_read_file(path)

pub fn runtime_remove_file(path: str) -> i32:
    with_fs_remove_file(path)

pub fn runtime_remove_dir(path: str) -> i32:
    with_fs_remove_dir(path)

pub fn runtime_remove_tree(path: str) -> i32:
    with_fs_remove_tree(path)

pub fn runtime_mkdir_p(path: str) -> i32:
    with_fs_mkdir_p(path)

pub fn runtime_getenv(name: str) -> str:
    with_getenv_str(name)

pub fn runtime_setenv(name: str, value: str) -> i32:
    with_setenv_str(name, value)

pub fn runtime_clock_nanos() -> i64:
    with_clock_nanos()

pub fn runtime_getpid() -> i32:
    with_getpid()
