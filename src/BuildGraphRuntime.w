// BuildGraphRuntime -- repository runtime-generation support for build.w.

extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_is_dir(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_tree(path: str) -> i32
extern fn with_fs_rename_file(old_path: str, new_path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getpid() -> i32
extern fn with_clock_nanos() -> i64
extern fn with_write(s: str) -> void
extern fn with_eprint(s: str) -> void

pub fn build_graph_rt_exec_argv(args: str) -> i32:
    with_exec_argv(args)

pub fn build_graph_rt_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    with_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

pub fn build_graph_rt_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32:
    with_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, cwd)

pub fn build_graph_rt_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32:
    with_exec_argv_capture_spawn(args, stdout_path, stderr_path)

pub fn build_graph_rt_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    with_exec_wait(pid, timeout_ms)

pub fn build_graph_rt_getenv(name: str) -> str:
    with_getenv_str(name)

pub fn build_graph_rt_setenv(name: str, value: str) -> i32:
    with_setenv_str(name, value)

pub fn build_graph_rt_file_exists(path: str) -> i32:
    with_fs_file_exists(path)

pub fn build_graph_rt_is_dir(path: str) -> i32:
    with_fs_is_dir(path)

pub fn build_graph_rt_mkdir_p(path: str) -> i32:
    with_fs_mkdir_p(path)

pub fn build_graph_rt_read_file(path: str) -> str:
    with_fs_read_file(path)

pub fn build_graph_rt_remove_file(path: str) -> i32:
    with_fs_remove_file(path)

pub fn build_graph_rt_remove_dir(path: str) -> i32:
    with_fs_remove_dir(path)

pub fn build_graph_rt_remove_tree(path: str) -> i32:
    with_fs_remove_tree(path)

pub fn build_graph_rt_rename_file(old_path: str, new_path: str) -> i32:
    with_fs_rename_file(old_path, new_path)

pub fn build_graph_rt_write_file(path: str, data: str) -> i32:
    with_fs_write_file(path, data)

pub fn build_graph_rt_chmod(path: str, mode: i32) -> i32:
    with_fs_chmod(path, mode)

pub fn build_graph_rt_getpid() -> i32:
    with_getpid()

pub fn build_graph_rt_clock_nanos() -> i64:
    with_clock_nanos()

pub fn build_graph_rt_write(s: str):
    with_write(s)

pub fn build_graph_rt_eprint(s: str):
    with_eprint(s)
