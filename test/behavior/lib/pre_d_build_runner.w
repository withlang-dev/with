use std.fs
use std.process

extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32

pub type P7Run {
    rc: i32,
    stdout: str,
    stderr: str,
}

pub fn p7_repo_root -> str:
    let root = env("PWD")
    if root.len() > 0:
        return root
    "."

pub fn p7_join(a: str, b: str) -> str:
    if a.len() == 0:
        return b
    if b.len() == 0:
        return a
    if a.byte_at(a.len() - 1) == 47:
        return a ++ b
    a ++ "/" ++ b

pub fn p7_abs(path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    p7_join(p7_repo_root(), path)

fn p7_argv_append(blob: str, arg: str) -> str:
    blob ++ arg ++ "\0"

pub fn p7_compiler_path -> str:
    let staged_stage2 = p7_abs("out/stage/bin/with-stage2")
    if file_exists(staged_stage2):
        return staged_stage2
    let release = p7_abs("out/release/bin/with")
    if file_exists(release):
        return release
    let stage2 = p7_abs("out/bin/with-stage2")
    if file_exists(stage2):
        return stage2
    p7_abs("out/bin/with")

pub fn p7_case_dir(name: str) -> str:
    p7_abs("out/tmp/pre-d-p7/" ++ name)

pub fn p7_prepare_case(name: str, package_name: str) -> str:
    let case_dir = p7_case_dir(name)
    let _remove = remove_tree(case_dir)
    assert(mkdir_p(p7_join(case_dir, "src")) == 0)
    assert(write_file(p7_join(case_dir, "with.toml"), "[package]\nname = \"" ++ package_name ++ "\"\nversion = \"0.1.0\"\n") == 0)
    assert(write_file(p7_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n") == 0)
    case_dir

pub fn p7_write(case_dir: str, rel_path: str, contents: str) -> Unit:
    let full = p7_join(case_dir, rel_path)
    let dir = p7_dirname(full)
    assert(mkdir_p(dir) == 0)
    assert(write_file(full, contents) == 0)

pub fn p7_dirname(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

pub fn p7_run(case_dir: str, label: str, args_blob: str) -> P7Run:
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

pub fn p7_build_target_args(target: str) -> str:
    p7_argv_append(p7_argv_append("", "build"), target)

pub fn p7_build_target_no_deps_args(target: str) -> str:
    p7_argv_append(p7_argv_append(p7_argv_append("", "build"), target), "--no-deps")

pub fn p7_assert_success(result: P7Run, label: str) -> Unit:
    if result.rc != 0:
        print("stdout:\n" ++ result.stdout)
        print("stderr:\n" ++ result.stderr)
    assert(result.rc == 0)

pub fn p7_assert_failure_contains(result: P7Run, needle: str, label: str) -> Unit:
    let _ = label
    assert(result.rc != 0)
    assert(result.stderr.contains(needle) or result.stdout.contains(needle))

pub fn p7_assert_file_contains(case_dir: str, rel_path: str, needle: str) -> Unit:
    let text = read_file(p7_join(case_dir, rel_path))
    assert(text.contains(needle))
