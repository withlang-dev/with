use std.fs
use std.process
use std.string
use std.sysinfo

extern fn with_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32
extern fn rt_getcwd(buf: *mut u8, size: i64) -> i32
extern fn with_str_from_cstr(s: *const u8) -> str

// The real working directory as a native path. Unlike `env("PWD")` this is
// correct on Windows cmd.exe (which never sets PWD) and under a bash shell
// whose PWD is a POSIX `/d/...` path that Win32 file/spawn APIs reject.
fn p7_cwd -> str:
    var buf: [4096]u8 = [0 as u8; 4096]
    let rc = unsafe { rt_getcwd(&raw mut buf as *mut [4096]u8 as *mut u8, 4096) }
    if rc != 0:
        return ""
    // with_str_from_cstr wraps the pointer (make_str) without copying, so the
    // returned str aliases `buf`. Copy it off the stack before `buf` dies —
    // otherwise every path derived from p7_repo_root is a use-after-free. On
    // Linux/darwin the reused frame happened to survive the read; on Windows
    // the native stage2's frame layout clobbers it, corrupting case_dir into a
    // path with an interior NUL → "str to C string conversion" panic → the p7
    // exit-134 cluster.
    unsafe { with_str_from_cstr(&buf as *const [4096]u8 as *const u8) }.to_owned()

pub type P7Run {
    rc: i32,
    stdout: str,
    stderr: str,
}

pub fn p7_repo_root -> str:
    let real = p7_cwd()
    if real.len() > 0:
        return real
    let root = env("PWD")
    if root.len() > 0:
        return root
    "."

pub fn p7_join(a: &str, b: &str) -> str:
    if a.len() == 0:
        return b.to_owned()
    if b.len() == 0:
        return a.to_owned()
    if a.byte_at(a.len() - 1) == 47:
        return a ++ b
    a ++ "/" ++ b

pub fn p7_abs(path: &str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path.to_owned()
    p7_join(p7_repo_root(), path)

fn p7_argv_append(blob: &str, arg: &str) -> str:
    blob ++ arg ++ "\0"

pub fn p7_compiler_path -> str:
    let ext = if os() == "Windows": ".exe" else: ""
    let staged_stage2 = p7_abs("out/stage/bin/with-stage2" ++ ext)
    if file_exists(staged_stage2):
        return staged_stage2
    let release = p7_abs("out/release/bin/with" ++ ext)
    if file_exists(release):
        return release
    let stage2 = p7_abs("out/bin/with-stage2" ++ ext)
    if file_exists(stage2):
        return stage2
    p7_abs("out/bin/with" ++ ext)

pub fn p7_case_dir(name: &str) -> str:
    p7_abs("out/tmp/pre-d-p7/" ++ name)

pub fn p7_prepare_case(name: &str, package_name: &str) -> str:
    let case_dir = p7_case_dir(name)
    let _remove = remove_tree(case_dir)
    assert(mkdir_p(p7_join(case_dir, "src")) == 0)
    assert(write_file(p7_join(case_dir, "with.toml"), "[package]\nname = \"" ++ package_name ++ "\"\nversion = \"0.1.0\"\n") == 0)
    assert(write_file(p7_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n") == 0)
    case_dir

pub fn p7_write(case_dir: &str, rel_path: &str, contents: &str) -> Unit:
    let full = p7_join(case_dir, rel_path)
    let dir = p7_dirname(full)
    assert(mkdir_p(dir) == 0)
    assert(write_file(full, contents) == 0)

pub fn p7_dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

pub fn p7_run(case_dir: &str, label: &str, args_blob: &str) -> P7Run:
    let capture_dir = p7_join(p7_abs("out/tmp/pre-d-p7-capture"), label)
    let _remove = remove_tree(capture_dir)
    assert(mkdir_p(capture_dir) == 0)
    let stdout_path = p7_join(capture_dir, "stdout.txt")
    let stderr_path = p7_join(capture_dir, "stderr.txt")
    var argv = ""
    argv = p7_argv_append(argv, p7_compiler_path())
    argv = argv ++ args_blob
    let rc = unsafe { with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, 300000, case_dir) }
    P7Run { rc: rc, stdout: read_file(stdout_path), stderr: read_file(stderr_path) }

pub fn p7_build_args -> str:
    p7_argv_append("", "build")

pub fn p7_build_graph_args -> str:
    p7_argv_append(p7_argv_append("", "build"), "--graph")

pub fn p7_build_target_args(target: &str) -> str:
    p7_argv_append(p7_argv_append("", "build"), target)

pub fn p7_build_target_no_deps_args(target: &str) -> str:
    p7_argv_append(p7_argv_append(p7_argv_append("", "build"), target), "--no-deps")

pub fn p7_assert_success(result: &P7Run, label: &str) -> Unit:
    if result.rc != 0:
        print("stdout:\n" ++ result.stdout)
        print("stderr:\n" ++ result.stderr)
    assert(result.rc == 0)

pub fn p7_assert_failure_contains(result: &P7Run, needle: &str, label: &str) -> Unit:
    let _ = label
    assert(result.rc != 0)
    assert(result.stderr.contains(needle) or result.stdout.contains(needle))

pub fn p7_assert_file_contains(case_dir: &str, rel_path: &str, needle: &str) -> Unit:
    let text = read_file(p7_join(case_dir, rel_path))
    assert(text.contains(needle))
