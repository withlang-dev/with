// Compiler runtime boundary. Raw runtime exports are declared here; compiler
// modules should depend on these typed wrappers instead of redeclaring externs.

use rt.rt_core
use rt.platform
use rt.compat_runtime

fn runtime_eprint(s: &str):
    with_eprint(s)

fn runtime_exec_binary(path: &str) -> i32:
    with_exec_binary(path)

fn runtime_exec_argv(args: &str) -> i32:
    with_exec_argv(args)

fn runtime_exec_argv_cwd(args: &str, cwd: &str) -> i32:
    with_exec_argv_cwd(args, cwd)

fn runtime_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32:
    with_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

fn runtime_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32:
    with_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, cwd)

fn runtime_arg_at(idx: i32) -> str:
    with_arg_at(idx)

fn runtime_write_file(path: &str, data: &str) -> i32:
    with_fs_write_file(path, data)

fn runtime_read_file(path: &str) -> str:
    with_fs_read_file(path)

fn runtime_file_exists(path: &str) -> i32:
    with_fs_file_exists(path)

fn runtime_is_dir(path: &str) -> i32:
    with_fs_is_dir(path)

fn runtime_list_files(path: &str) -> str:
    with_fs_list_files(path)

fn runtime_remove_file(path: &str) -> i32:
    with_fs_remove_file(path)

fn runtime_remove_dir(path: &str) -> i32:
    with_fs_remove_dir(path)

fn runtime_remove_tree(path: &str) -> i32:
    with_fs_remove_tree(path)

fn runtime_mkdir_p(path: &str) -> i32:
    with_fs_mkdir_p(path)

// Atomic on all platforms: POSIX rename replaces the target; the Windows
// backend uses MoveFileExW with MOVEFILE_REPLACE_EXISTING.
fn runtime_rename(old_path: &str, new_path: &str) -> i32:
    with_fs_rename_file(old_path, new_path)

// The working directory: $PWD, which keeps the path the user typed, else
// the process's own (getcwd) — `env -i` and some launchers set no PWD, and
// a relative path joined onto "" named nothing (#1915).
fn runtime_cwd() -> str:
    let pwd = with_getenv_str("PWD")
    if pwd.len() > 0:
        return pwd
    unsafe:
        let buf = with_alloc(4096)
        if rt_getcwd(buf, 4096) != 0:
            with_free(buf)
            return ""
        var n: i64 = 0
        while n < 4096 and *((buf as i64 + n) as *const u8) != 0:
            n = n + 1
        let out = with_str_from_bytes(buf as *const u8, n)
        with_free(buf)
        out

fn runtime_getenv(name: &str) -> str:
    with_getenv_str(name)

fn runtime_setenv(name: &str, value: &str) -> i32:
    with_setenv_str(name, value)

/// The directory for scratch files, without a trailing slash: TMP, then
/// TEMP on Windows ("" when neither is set); elsewhere TMPDIR, else /tmp.
/// TMPDIR is a macOS login's, not a Linux one's: a path built from it
/// alone was `/with-…` at the filesystem root under ssh on Linux.
fn runtime_temp_dir() -> str:
    var dir = if runtime_sysinfo_os() == "Windows":
        let tmp = runtime_getenv("TMP")
        if tmp.len() > 0: tmp else: runtime_getenv("TEMP")
    else:
        let tmp = runtime_getenv("TMPDIR")
        if tmp.len() > 0: tmp else: "/tmp"
    while dir.len() > 1 and (dir.ends_with("/") or dir.ends_with("\\")): dir = dir.slice(0, dir.len() - 1)
    dir

fn runtime_clock_nanos() -> i64:
    with_clock_nanos()

fn runtime_getpid() -> i32:
    with_getpid()

fn runtime_str_clone(s: &str) -> str:
    with_str_clone_ref(s)

fn runtime_str_hash(s: &str) -> i64:
    with_str_hash(s) as i64

fn runtime_nanosleep(ns: i64) -> i32:
    with_nanosleep(ns)

fn runtime_sysinfo_os() -> str:
    with_sysinfo_os()

fn runtime_sysinfo_arch() -> str:
    with_sysinfo_arch()

// A POSIX root (`/`), a UNC path (`\server\share`), or a Windows drive
// (`C:/`, `C:\`). Every "join onto the root unless absolute" and "reject a
// path that escapes the project" decision in the compiler and the build
// graph reads this one predicate. With only the POSIX form, a drive path was
// "relative" on Windows: joined onto the root into a path that does not
// exist, or accepted as project-contained (#1082's with.toml walk, the build
// graph's `compiler=C:/...` test-target argument).
fn runtime_path_is_absolute(path: &str) -> bool:
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
fn runtime_path_root_part_count(path: &str) -> i32:
    if not runtime_path_is_absolute(path):
        return 0
    if runtime_path_is_unc(path):
        return 2
    if path[0] == 47 or path[0] == 92:
        return 0
    1

// The separator prefix the normalizer writes back: `/`, `//` for UNC, and
// nothing for a drive path (its root is the `C:` part).
fn runtime_path_root_prefix(path: &str) -> str:
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
fn runtime_program_path(path: &str) -> str:
    if runtime_sysinfo_os() == "Windows" and not path.ends_with(".exe"):
        return path ++ ".exe"
    path ++ ""

// A stage compiler's own tree: the directory holding the `out` its executable
// sits under (out/bootstrap/bin/with-stage1 → the checkout), or "" for a
// compiler outside a built tree — an installed release, which embeds the
// stdlib and the bundles. Module resolution tries its out/gen and lib last,
// so a stage compiler compiles a program in any directory the way it does
// from the tree root (stage1 driven from a test's case directory could not
// find std.engines.pcre2, a bundle corpus the embedded stdlib leaves out).
var g_own_tree_resolved: bool = false
var g_own_tree: str = ""

fn runtime_path_parent(path: &str) -> str:
    var last = -1
    for i in 0..path.len():
        if path[i] == '/' or path[i] == '\\': last = i as i32
    if last <= 0: "" else: path.slice(0, last as i64)

fn runtime_own_tree_root() -> str:
    if g_own_tree_resolved: return with_str_clone_ref(g_own_tree)
    g_own_tree_resolved = true
    var exe = with_arg_at(0)
    if not exe.contains("/") and not exe.contains("\\"): return ""
    if not runtime_path_is_absolute(exe):
        let cwd = with_getenv_str("PWD")
        if cwd.len() == 0: return ""
        exe = cwd ++ "/" ++ exe
    var dir = runtime_path_parent(exe)
    while dir.len() > 0:
        if dir.ends_with("/out") or dir.ends_with("\\out"):
            let root = runtime_path_parent(dir)
            if with_fs_is_dir(root ++ "/lib/std") != 0: g_own_tree = root
            break
        dir = runtime_path_parent(dir)
    with_str_clone_ref(g_own_tree)

// This executable, to run `with __ld` (and every other self-invocation) as a
// child: argv[0] when it names a path; on Windows a bare name is first the
// current directory's, as cmd runs it (#2647: a bare `with.exe` resolved
// through PATH re-invoked an older with.exe there, "unknown command
// '__ld'"); else argv[0] found on PATH. The one owner of the answer
// (Frontend's c_import key reads it too). SEED-BOUND: the OS's own answer
// (GetModuleFileNameW, _NSGetExecutablePath, /proc/self/exe) needs a runtime
// function src/ can call only once a seed carrying it is pinned.
fn with_self_exe() -> str:
    let argv0 = with_arg_at(0)
    if argv0.contains("/") or argv0.contains("\\"):
        // Absolute when this process's cwd is the one the spelling was
        // relative to: a child may run in another directory (a build
        // action in the project root), where a relative spelling names
        // nothing or another file. A parent that resolved a relative
        // argv[0] against its own cwd and then chdir'd the child (the
        // test runner) leaves a spelling this cwd cannot absolutize;
        // existence decides, and the raw spelling stands otherwise.
        if runtime_path_is_absolute(argv0):
            return argv0
        let cwd = runtime_cwd()
        if cwd.len() > 0:
            let joined = cwd ++ "/" ++ argv0
            if runtime_file_exists(joined) != 0:
                return joined
        return argv0
    let windows = runtime_sysinfo_os() == "Windows"
    if windows:
        let here = runtime_cwd() ++ "\\" ++ argv0 ++ (if argv0.ends_with(".exe"): "" else: ".exe")
        if runtime_file_exists(here) != 0: return here
    for dir in runtime_getenv("PATH").split(if windows: ";" else: ":"):
        if dir.len() == 0: continue
        let candidate = dir ++ "/" ++ argv0 ++ (if windows and not argv0.ends_with(".exe"): ".exe" else: "")
        if runtime_file_exists(candidate) != 0: return candidate
    ""
