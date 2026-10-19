// BuildGraphRuntime -- repository runtime-generation support for build.w.

extern fn with_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32
extern fn with_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32
extern fn with_exec_try_wait(pid: i32) -> i32
extern fn with_usleep(usecs: i32) -> i32
extern fn with_exec_child_maxrss() -> i64
extern fn with_self_maxrss() -> i64
extern fn with_exec_binary(path: &str) -> i32
extern fn with_exec_argv(args: &str) -> i32
extern fn with_arg_at(idx: isize) -> str
extern fn with_getenv_str(name: &str) -> str
extern fn with_setenv_str(name: &str, value: &str) -> i32
extern fn with_fs_chmod(path: &str, mode: i32) -> i32
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_fs_file_mode(path: &str) -> i32
extern fn with_fs_is_dir(path: &str) -> i32
extern fn with_fs_mkdir_p(path: &str) -> i32
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_read_file_status(path: &str, status: *mut i32) -> str
extern fn with_fs_readlink(path: &str) -> str
extern fn with_fs_remove_dir(path: &str) -> i32
extern fn with_fs_remove_file(path: &str) -> i32
extern fn with_fs_remove_tree(path: &str) -> i32
extern fn with_fs_copy_tree(src: &str, dst: &str) -> i32
extern fn with_time_now() -> i64
extern fn with_fs_list_files(path: &str) -> str
extern fn with_fs_list_dir(path: &str) -> str
extern fn with_fs_rename_file(old_path: &str, new_path: &str) -> i32
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_getpid() -> i32
extern fn with_clock_nanos() -> i64
extern fn with_write(s: &str) -> Unit
extern fn with_eprint(s: &str) -> Unit
// #747: the LlvmBridge definitions take &str; a `str` decl here was an ABI
// mismatch (by-value {ptr,len} pair against a header pointer).
extern fn wl_assemble_to_object(source_path: &str, output_path: &str) -> i32
extern fn wl_assemble_to_object_for_triple(source_path: &str, output_path: &str, triple: &str) -> i32
extern fn wl_compile_ir_to_object(source_path: &str, output_path: &str) -> i32

fn build_graph_rt_exec_argv(args: &str) -> i32:
    with_exec_argv(args)

fn build_graph_rt_arg_at(idx: i32) -> str:
    with_arg_at(idx)

fn build_graph_rt_exec_binary(path: &str) -> i32:
    with_exec_binary(path)

fn build_graph_rt_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32:
    with_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

fn build_graph_rt_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32:
    with_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, cwd)

fn build_graph_rt_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32:
    with_exec_argv_capture_spawn(args, stdout_path, stderr_path)

fn build_graph_rt_child_maxrss() -> i64: with_exec_child_maxrss()

fn build_graph_rt_self_maxrss() -> i64: with_self_maxrss()

fn build_graph_rt_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    with_exec_wait(pid, timeout_ms)

// #921: nonblocking reap probe — -2 while the child still runs.
fn build_graph_rt_exec_try_wait(pid: i32) -> i32:
    with_exec_try_wait(pid)

fn build_graph_rt_usleep(usecs: i32) -> i32: with_usleep(usecs)

fn build_graph_rt_getenv(name: &str) -> str:
    with_getenv_str(name)

fn build_graph_rt_setenv(name: &str, value: &str) -> i32:
    with_setenv_str(name, value)

fn build_graph_rt_file_exists(path: &str) -> i32:
    with_fs_file_exists(path)

fn build_graph_rt_file_mode(path: &str) -> i32:
    with_fs_file_mode(path)

fn build_graph_rt_is_dir(path: &str) -> i32:
    with_fs_is_dir(path)

fn build_graph_rt_mkdir_p(path: &str) -> i32:
    with_fs_mkdir_p(path)

fn build_graph_rt_read_file(path: &str) -> str:
    with_fs_read_file(path)

// The file's text with the OS status (0, or the negated errno) — the read a
// graph operation must not confuse with an empty file (#953).
fn build_graph_rt_read_file_status(path: &str, status: *mut i32) -> str:
    with_fs_read_file_status(path, status)

fn build_graph_rt_readlink(path: &str) -> str:
    with_fs_readlink(path)

fn build_graph_rt_remove_file(path: &str) -> i32:
    with_fs_remove_file(path)

fn build_graph_rt_remove_dir(path: &str) -> i32:
    with_fs_remove_dir(path)

fn build_graph_rt_remove_tree(path: &str) -> i32:
    with_fs_remove_tree(path)

// Recursive copy: a file with its mode, a directory with its entries.
fn build_graph_rt_copy_tree(src: &str, dst: &str) -> i32:
    with_fs_copy_tree(src, dst)

// Wall-clock seconds since the epoch.
fn build_graph_rt_time_now() -> i64: with_time_now()

fn build_graph_rt_list_files(path: &str) -> str:
    with_fs_list_files(path)

// The entries of one directory, names only, no descent.
fn build_graph_rt_list_dir(path: &str) -> str:
    with_fs_list_dir(path)

fn build_graph_rt_rename_file(old_path: &str, new_path: &str) -> i32:
    with_fs_rename_file(old_path, new_path)

fn build_graph_rt_write_file(path: &str, data: &str) -> i32:
    with_fs_write_file(path, data)

fn build_graph_rt_assemble_to_object(source_path: &str, output_path: &str) -> i32:
    wl_assemble_to_object(source_path, output_path)

fn build_graph_rt_assemble_to_object_for_triple(source_path: &str, output_path: &str, triple: &str) -> i32:
    wl_assemble_to_object_for_triple(source_path, output_path, triple)

fn build_graph_rt_compile_ir_to_object(source_path: &str, output_path: &str) -> i32:
    wl_compile_ir_to_object(source_path, output_path)

fn build_graph_rt_chmod(path: &str, mode: i32) -> i32:
    with_fs_chmod(path, mode)

fn build_graph_rt_getpid() -> i32:
    with_getpid()

// Same out-param layout with_sysinfo fills for codegen units.
type BuildGraphSysInfo {
    cpu_cores: i32,
    memory_total: i64,
    page_size: i64,
}
extern fn with_sysinfo(out: *mut u8) -> i32

fn build_graph_rt_cpu_cores() -> i32:
    var info = BuildGraphSysInfo { cpu_cores: 0, memory_total: 0, page_size: 0 }
    let _ = with_sysinfo(&info as *mut u8)
    info.cpu_cores

fn build_graph_rt_clock_nanos() -> i64:
    with_clock_nanos()

fn build_graph_rt_write(s: &str):
    with_write(s)

fn build_graph_rt_eprint(s: &str):
    with_eprint(s)

// This process's id (unique temp names for the install kind).
fn build_graph_rt_pid() -> i32: with_getpid()
