// BuildGraphSelfhostHarness -- reusable fixtures/process/assertion helpers for
// repository build graph selfhost suites.

extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_eprint(s: str) -> void
extern fn with_regex_error_message(code: i32) -> str
extern fn with_regex_compile(pattern: str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_code_free(code: *const i8) -> void
extern fn with_regex_match_spans_alloc(code: *const i8, text: str, out_count: *mut i32) -> *const i32
extern fn with_free(ptr: *mut u8) -> void

pub type BuildSelfhostRunResult {
    rc: i32,
    stdout: str,
    stderr: str,
}

pub fn bgs_argv_append(argv_blob: str, arg: str) -> str:
    argv_blob ++ arg ++ "\0"

pub fn bgs_resolve_join(base: str, child: str) -> str:
    if child.len() == 0:
        return base
    if child.byte_at(0) == 47:
        return child
    if base.len() == 0 or base.ends_with("/"):
        return base ++ child
    base ++ "/" ++ child

pub fn bgs_dirname(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

pub fn bgs_basename(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    path.slice((last + 1) as i64, path.len())

pub fn bgs_trim_trailing_line_endings(text: str) -> str:
    var end = text.len() as i32
    while end > 0:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end as i64)

pub fn bgs_with_string_literal(value: str) -> str:
    var out = "\""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 34:
            out = out ++ "\\\""
        else if ch == 92:
            out = out ++ "\\\\"
        else if ch == 9:
            out = out ++ "\\t"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out ++ "\""

pub fn bgs_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' missing expected output for " ++ label ++ ": " ++ needle)
    1

pub fn bgs_assert_not_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) == 0:
        return 0
    with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' found forbidden output for " ++ label ++ ": " ++ needle)
    1

pub fn bgs_regex_matches(text: str, pattern: str, target_name: str, label: str) -> bool:
    var err_code: i32 = 0
    var err_offset: i32 = 0
    let code = with_regex_compile(pattern, 0, &raw mut err_code, &raw mut err_offset)
    if code as i64 == 0:
        with_eprint("error: selfhost regex assertion for " ++ label ++ " has invalid pattern at offset " ++ f"{err_offset}: " ++ with_regex_error_message(err_code))
        return false
    var span_count: i32 = 0
    let spans = with_regex_match_spans_alloc(code, text, &raw mut span_count)
    let matched = spans as i64 != 0 and span_count > 0
    if spans as i64 != 0:
        with_free(spans as *mut u8)
    with_regex_code_free(code)
    let _ = target_name
    matched

pub fn bgs_assert_matches(text: str, pattern: str, target_name: str, label: str) -> i32:
    if bgs_regex_matches(text, pattern, target_name, label):
        return 0
    with_eprint("error: selfhost test target '" ++ target_name ++ "' missing regex match for " ++ label ++ ": " ++ pattern)
    1

pub fn bgs_assert_not_matches(text: str, pattern: str, target_name: str, label: str) -> i32:
    if not bgs_regex_matches(text, pattern, target_name, label):
        return 0
    with_eprint("error: selfhost test target '" ++ target_name ++ "' found forbidden regex match for " ++ label ++ ": " ++ pattern)
    1

pub fn bgs_write_fixture(path: str, contents: str, target_name: str, label: str) -> i32:
    let dir = bgs_dirname(path)
    if with_fs_mkdir_p(dir) != 0:
        with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' could not create fixture directory for " ++ label ++ ": " ++ dir)
        return 1
    if with_fs_write_file(path, contents) != 0:
        with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' could not write fixture for " ++ label ++ ": " ++ path)
        return 1
    0

pub fn bgs_write_project_manifest(case_dir: str, package_name: str, target_name: str) -> i32:
    bgs_write_fixture(bgs_resolve_join(case_dir, "with.toml"), "[package]\nname = \"" ++ package_name ++ "\"\nversion = \"0.1.0\"\n", target_name, package_name ++ " manifest")

pub fn bgs_expect_file_contains(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' missing file for " ++ label ++ ": " ++ path)
        return 1
    if with_str_contains(with_fs_read_file(path), needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' file mismatch for " ++ label ++ ": missing '" ++ needle ++ "' in " ++ path)
    1

pub fn bgs_run_cli_capture_cwd(root: str, target_name: str, compiler_path: str, label: str, argv_tail: str, timeout_ms: i32, cwd: str) -> BuildSelfhostRunResult:
    let capture_dir = bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name)
    let _mkdir = with_fs_mkdir_p(capture_dir)
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let stdout_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stdout")
    let stderr_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stderr")
    var argv = ""
    argv = bgs_argv_append(argv, compiler_path)
    argv = argv ++ argv_tail
    let rc = with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, cwd)
    let stdout = with_fs_read_file(stdout_path)
    let stderr = with_fs_read_file(stderr_path)
    if rc == 0:
        let _remove_stdout = with_fs_remove_file(stdout_path)
        let _remove_stderr = with_fs_remove_file(stderr_path)
    BuildSelfhostRunResult { rc, stdout, stderr }

pub fn bgs_run_binary_capture(root: str, target_name: str, label: str, exe_path: str, timeout_ms: i32) -> BuildSelfhostRunResult:
    let capture_dir = bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name)
    let _mkdir = with_fs_mkdir_p(capture_dir)
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let stdout_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stdout")
    let stderr_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stderr")
    var argv = ""
    argv = bgs_argv_append(argv, exe_path)
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    let stdout = with_fs_read_file(stdout_path)
    let stderr = with_fs_read_file(stderr_path)
    if rc == 0:
        let _remove_stdout = with_fs_remove_file(stdout_path)
        let _remove_stderr = with_fs_remove_file(stderr_path)
    BuildSelfhostRunResult { rc, stdout, stderr }

pub fn bgs_build_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 120000, case_dir)
    if result.rc != 0:
        with_eprint("error: build.w selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result
