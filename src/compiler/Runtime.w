// Compiler runtime boundary. Raw runtime exports are declared here; compiler
// modules should depend on these typed wrappers instead of redeclaring externs.

extern fn with_eprint(s: &str) -> Unit
extern fn with_exec_binary(path: &str) -> i32
extern fn with_exec_argv(args: &str) -> i32
extern fn with_exec_argv_cwd(args: &str, cwd: &str) -> i32
extern fn with_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_fs_is_dir(path: &str) -> i32
extern fn with_fs_list_files(path: &str) -> str
extern fn with_fs_remove_file(path: &str) -> i32
extern fn with_fs_remove_dir(path: &str) -> i32
extern fn with_fs_remove_tree(path: &str) -> i32
extern fn with_fs_mkdir_p(path: &str) -> i32
extern fn with_fs_rename_file(old_path: &str, new_path: &str) -> i32
extern fn with_getenv_str(name: &str) -> str
extern fn with_setenv_str(name: &str, value: &str) -> i32
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32
extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_hash(s: &str) -> u64
extern fn with_nanosleep(ns: i64) -> i32
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

pub fn runtime_eprint(s: &str) -> Unit:
    with_eprint(s)

pub fn runtime_exec_binary(path: &str) -> i32:
    with_exec_binary(path)

pub fn runtime_exec_argv(args: &str) -> i32:
    with_exec_argv(args)

pub fn runtime_exec_argv_cwd(args: &str, cwd: &str) -> i32:
    with_exec_argv_cwd(args, cwd)

pub fn runtime_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32:
    with_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

pub fn runtime_arg_at(idx: i32) -> str:
    with_arg_at(idx)

pub fn runtime_write_file(path: &str, data: &str) -> i32:
    with_fs_write_file(path, data)

pub fn runtime_read_file(path: &str) -> str:
    with_fs_read_file(path)

pub fn runtime_file_exists(path: &str) -> i32:
    with_fs_file_exists(path)

pub fn runtime_is_dir(path: &str) -> i32:
    with_fs_is_dir(path)

pub fn runtime_list_files(path: &str) -> str:
    with_fs_list_files(path)

pub fn runtime_remove_file(path: &str) -> i32:
    with_fs_remove_file(path)

pub fn runtime_remove_dir(path: &str) -> i32:
    with_fs_remove_dir(path)

pub fn runtime_remove_tree(path: &str) -> i32:
    with_fs_remove_tree(path)

pub fn runtime_mkdir_p(path: &str) -> i32:
    with_fs_mkdir_p(path)

// Atomic on all platforms: POSIX rename replaces the target; the Windows
// backend uses MoveFileExW with MOVEFILE_REPLACE_EXISTING.
pub fn runtime_rename(old_path: &str, new_path: &str) -> i32:
    with_fs_rename_file(old_path, new_path)

pub fn runtime_getenv(name: &str) -> str:
    with_getenv_str(name)

pub fn runtime_setenv(name: &str, value: &str) -> i32:
    with_setenv_str(name, value)

pub fn runtime_clock_nanos() -> i64:
    with_clock_nanos()

pub fn runtime_getpid() -> i32:
    with_getpid()

pub fn runtime_str_clone(s: &str) -> str:
    with_str_clone_ref(s)

pub fn runtime_str_hash(s: &str) -> i64:
    with_str_hash(s) as i64

pub fn runtime_nanosleep(ns: i64) -> i32:
    with_nanosleep(ns)

pub fn runtime_sysinfo_os() -> str:
    with_sysinfo_os()

pub fn runtime_sysinfo_arch() -> str:
    with_sysinfo_arch()

// A POSIX root (`/`), a UNC path (`\server\share`), or a Windows drive
// (`C:/`, `C:\`). Every "join onto the root unless absolute" and "reject a
// path that escapes the project" decision in the compiler and the build
// graph reads this one predicate. With only the POSIX form, a drive path was
// "relative" on Windows: joined onto the root into a path that does not
// exist, or accepted as project-contained (#1082's with.toml walk, the build
// graph's `compiler=C:/...` test-target argument).
pub fn runtime_path_is_absolute(path: &str) -> bool:
    if path.len() == 0:
        return false
    // A lone leading `\` is drive-root-relative on Windows: never a path
    // inside the project, so it counts as absolute here (UNC starts so too).
    if path[0] == 47 or path[0] == 92:
        return true
    let drive = path[0]
    let is_letter = (drive >= 65 and drive <= 90) or (drive >= 97 and drive <= 122)
    path.len() >= 3 and is_letter and path[1] == 58 and (path[2] == 47 or path[2] == 92)

fn runtime_path_is_unc(path: &str) -> bool:
    path.len() >= 2 and (path[0] == 92 or path[0] == 47) and (path[1] == 92 or path[1] == 47) and path[0] == path[1]

// What a lexical normalizer must keep in front of a `..`: nothing for a
// POSIX root, the drive (`C:`) for a drive path, server and share for UNC.
pub fn runtime_path_root_part_count(path: &str) -> i32:
    if not runtime_path_is_absolute(path):
        return 0
    if runtime_path_is_unc(path):
        return 2
    if path[0] == 47 or path[0] == 92:
        return 0
    1

// The separator prefix the normalizer writes back: `/`, `//` for UNC, and
// nothing for a drive path (its root is the `C:` part).
pub fn runtime_path_root_prefix(path: &str) -> str:
    if not runtime_path_is_absolute(path):
        return ""
    if runtime_path_is_unc(path):
        return "//"
    if path[0] == 47 or path[0] == 92:
        return "/"
    ""

// A program's path on this host: Windows shells run a file only by its
// extension (`out\bin\app` is "not recognized as an internal or external
// command" to cmd.exe and PowerShell), so a default executable output gets
// `.exe` there. An explicit `-o` or `output:` is the user's and is kept.
pub fn runtime_program_path(path: &str) -> str:
    if runtime_sysinfo_os() == "Windows" and not path.ends_with(".exe"):
        return path ++ ".exe"
    path ++ ""
