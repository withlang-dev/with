// BuildGraphSelfhost -- bulky selfhost build.w fixture tests used by the
// repository build graph. Kept out of main.w so the CLI entry point remains a
// dispatcher instead of a fixture warehouse.

extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_eprint(s: str) -> void

type BuildSelfhostRunResult {
    rc: i32,
    stdout: str,
    stderr: str,
}

fn bgs_argv_append(argv_blob: str, arg: str) -> str:
    argv_blob ++ arg ++ "\0"

fn bgs_resolve_join(base: str, child: str) -> str:
    if child.len() == 0:
        return base
    if child.byte_at(0) == 47:
        return child
    if base.len() == 0 or base.ends_with("/"):
        return base ++ child
    base ++ "/" ++ child

fn bgs_dirname(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

fn bgs_basename(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    path.slice((last + 1) as i64, path.len())

fn bgs_trim_trailing_line_endings(text: str) -> str:
    var end = text.len() as i32
    while end > 0:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end as i64)

fn bgs_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' missing expected output for " ++ label ++ ": " ++ needle)
    1

fn bgs_assert_not_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) == 0:
        return 0
    with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' found forbidden output for " ++ label ++ ": " ++ needle)
    1

fn bgs_project_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' missing expected output for " ++ label ++ ": " ++ needle)
    1

fn bgs_project_expect_file(path: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) != 0:
        return 0
    with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' missing file for " ++ label ++ ": " ++ path)
    1

fn bgs_project_expect_absent(path: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        return 0
    with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' found unexpected file for " ++ label ++ ": " ++ path)
    1

fn bgs_write_fixture(path: str, contents: str, target_name: str, label: str) -> i32:
    let dir = bgs_dirname(path)
    if with_fs_mkdir_p(dir) != 0:
        with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' could not create fixture directory for " ++ label ++ ": " ++ dir)
        return 1
    if with_fs_write_file(path, contents) != 0:
        with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' could not write fixture for " ++ label ++ ": " ++ path)
        return 1
    0

fn bgs_write_project_manifest(case_dir: str, package_name: str, target_name: str) -> i32:
    bgs_write_fixture(bgs_resolve_join(case_dir, "with.toml"), "[package]\nname = \"" ++ package_name ++ "\"\nversion = \"0.1.0\"\n", target_name, package_name ++ " manifest")

fn bgs_expect_file_contains(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' missing file for " ++ label ++ ": " ++ path)
        return 1
    if with_str_contains(with_fs_read_file(path), needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_build_w_test target '" ++ target_name ++ "' file mismatch for " ++ label ++ ": missing '" ++ needle ++ "' in " ++ path)
    1

fn bgs_run_cli_capture_cwd(root: str, target_name: str, compiler_path: str, label: str, argv_tail: str, timeout_ms: i32, cwd: str) -> BuildSelfhostRunResult:
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

fn bgs_run_binary_capture(root: str, target_name: str, label: str, exe_path: str, timeout_ms: i32) -> BuildSelfhostRunResult:
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

fn bgs_build_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 120000, case_dir)
    if result.rc != 0:
        with_eprint("error: build.w selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bgs_project_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 120000, case_dir)
    if result.rc != 0:
        with_eprint("error: project selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bgs_check_init_in_cwd(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    if with_fs_mkdir_p(case_dir) != 0:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' could not create init cwd case directory: " ++ case_dir)
        return 1
    let expected_name = bgs_basename(case_dir)
    let result = bgs_project_expect_success(root, target_name, compiler_path, case_dir, "init-in-cwd", bgs_argv_append("", "init"))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    var rc = bgs_project_expect_file(bgs_resolve_join(case_dir, "with.toml"), target_name, "init_in_cwd manifest")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(case_dir, "src/main.w"), target_name, "init_in_cwd main")
    if rc != 0: return rc
    rc = bgs_project_expect_absent(bgs_resolve_join(bgs_resolve_join(case_dir, expected_name), "with.toml"), target_name, "init_in_cwd nested manifest")
    if rc != 0: return rc
    rc = bgs_project_expect_absent(bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(case_dir, expected_name), "src"), "main.w"), target_name, "init_in_cwd nested main")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "with.toml"), "name = \"" ++ expected_name ++ "\"", target_name, "init_in_cwd manifest name")
    if rc != 0: return rc
    bgs_project_assert_contains(result.stderr, "created " ++ expected_name, target_name, "init_in_cwd stderr")

fn bgs_check_init_named_dir(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    if with_fs_mkdir_p(case_dir) != 0:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' could not create init named case directory: " ++ case_dir)
        return 1
    let project_name = "sqlite"
    let result = bgs_project_expect_success(root, target_name, compiler_path, case_dir, "init-named-dir", bgs_argv_append(bgs_argv_append("", "init"), project_name))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let project_dir = bgs_resolve_join(case_dir, project_name)
    var rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "with.toml"), target_name, "init_named_dir manifest")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "src/main.w"), target_name, "init_named_dir main")
    if rc != 0: return rc
    rc = bgs_project_expect_absent(bgs_resolve_join(case_dir, "with.toml"), target_name, "init_named_dir root manifest")
    if rc != 0: return rc
    rc = bgs_project_expect_absent(bgs_resolve_join(case_dir, "src/main.w"), target_name, "init_named_dir root main")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(project_dir, "with.toml"), "name = \"" ++ project_name ++ "\"", target_name, "init_named_dir manifest name")
    if rc != 0: return rc
    rc = bgs_project_assert_contains(result.stderr, "created " ++ project_name, target_name, "init_named_dir stderr")
    if rc != 0: return rc
    rc = bgs_project_assert_contains(result.stderr, "  " ++ project_name ++ "/with.toml", target_name, "init_named_dir manifest path")
    if rc != 0: return rc
    bgs_project_assert_contains(result.stderr, "  " ++ project_name ++ "/src/main.w", target_name, "init_named_dir main path")

fn bgs_check_build_uses_package_section_name(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "pkgdemo", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/main.w"), "fn main:\n    print(\"ok\")\n", target_name, "package_section_name main")
    if rc != 0: return rc
    let result = bgs_project_expect_success(root, target_name, compiler_path, case_dir, "package-section-name", bgs_argv_append("", "build"))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    bgs_project_expect_file(bgs_resolve_join(case_dir, "out/bin/pkgdemo"), target_name, "package_section_name output")

fn bgs_check_build_rejects_imperative_manifest(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_fixture(bgs_resolve_join(case_dir, "with.toml"), "[package]\nname = \"badmanifest\"\nversion = \"0.1.0\"\n\n[build]\ncommand = \"echo nope\"\n", target_name, "imperative manifest")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/main.w"), "fn main:\n    print(\"ok\")\n", target_name, "imperative main")
    if rc != 0: return rc
    let implicit = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "imperative-manifest", bgs_argv_append("", "build"), 120000, case_dir)
    if implicit.rc == 0:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' accepted imperative manifest")
        return 1
    rc = bgs_project_assert_contains(implicit.stderr, "error: invalid with.toml: imperative build configuration belongs in build.w", target_name, "imperative manifest diagnostic")
    if rc != 0: return rc
    let explicit = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "imperative-manifest-explicit-source", bgs_argv_append(bgs_argv_append("", "build"), bgs_resolve_join(case_dir, "src/main.w")), 120000, case_dir)
    if explicit.rc == 0:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' accepted imperative manifest with explicit source")
        return 1
    bgs_project_assert_contains(explicit.stderr, "error: invalid with.toml: imperative build configuration belongs in build.w", target_name, "imperative manifest explicit source diagnostic")

pub fn run_cli_selfhost_project_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_init_in_cwd(root, target_name, compiler_path, bgs_resolve_join(base_dir, "init_in_cwd_case"))
    if rc != 0: return rc
    rc = bgs_check_init_named_dir(root, target_name, compiler_path, bgs_resolve_join(base_dir, "init_named_dir_case"))
    if rc != 0: return rc
    rc = bgs_check_build_uses_package_section_name(root, target_name, compiler_path, bgs_resolve_join(base_dir, "build_package_section_case"))
    if rc != 0: return rc
    bgs_check_build_rejects_imperative_manifest(root, target_name, compiler_path, bgs_resolve_join(base_dir, "build_imperative_manifest_case"))

fn bgs_edge_assert_exact(actual: str, expected: str, target_name: str, label: str, stream_name: str) -> i32:
    if actual == expected:
        return 0
    let prefix = "error: cli_selfhost_edge_test target '" ++ target_name ++ "' "
    with_eprint(prefix ++ stream_name ++ " mismatch for " ++ label)
    with_eprint("expected: '" ++ expected ++ "'")
    with_eprint("actual: '" ++ actual ++ "'")
    1

fn bgs_edge_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_edge_test target '" ++ target_name ++ "' missing expected output for " ++ label ++ ": " ++ needle)
    1

fn bgs_edge_assert_not_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) == 0:
        return 0
    with_eprint("error: cli_selfhost_edge_test target '" ++ target_name ++ "' found forbidden output for " ++ label ++ ": " ++ needle)
    1

fn bgs_edge_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 120000, case_dir)
    if result.rc != 0:
        with_eprint("error: edge selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bgs_check_pointer_index_rejected(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "pointer_index_rejected.w")
    let obj = bgs_resolve_join(case_dir, "pointer_index_rejected.o")
    var rc = bgs_write_fixture(src, "fn main:\n    var arr: [4]i32 = [0 as i32; 4]\n    var p: *const i32 = null\n    let value = arr[p]\n    value\n", target_name, "pointer index source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "build")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--emit-obj")
    argv = bgs_argv_append(argv, "-O0")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, obj)
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "pointer-index-rejected", argv, 120000, case_dir)
    if result.rc == 0:
        with_eprint("error: cli_selfhost_edge_test target '" ++ target_name ++ "' accepted pointer index expression")
        return 1
    rc = bgs_edge_assert_contains(result.stderr, "index expression must be an integer", target_name, "pointer_index_rejected")
    if rc != 0: return rc
    bgs_edge_assert_not_contains(result.stderr, "LLVM verify error", target_name, "pointer_index_rejected")

fn bgs_check_prelude_output_functions(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "prelude_output_functions.w")
    var rc = bgs_write_fixture(src, "fn main:\n    write(\"A\")\n    print(\"B\")\n    write(\"C\")\n    ewrite(\"D\")\n    eprint(\"E\")\n    ewrite(\"F\")\n", target_name, "prelude output source")
    if rc != 0: return rc
    let result = bgs_edge_expect_success(root, target_name, compiler_path, case_dir, "prelude-output-functions", bgs_argv_append(bgs_argv_append("", "run"), src))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    rc = bgs_edge_assert_exact(result.stdout, "AB\nC", target_name, "prelude_output_functions", "stdout")
    if rc != 0: return rc
    bgs_edge_assert_exact(result.stderr, "DE\nF", target_name, "prelude_output_functions", "stderr")

fn bgs_check_whole_program_extern_var_redecl(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let defs_src = bgs_resolve_join(case_dir, "defs.w")
    let user_src = bgs_resolve_join(case_dir, "user.w")
    let main_src = bgs_resolve_join(case_dir, "main.w")
    let bin = bgs_resolve_join(case_dir, "whole_program_extern_var_redecl")
    var rc = bgs_write_fixture(defs_src, "var shared_counter: i32 = 41\n", target_name, "extern redecl defs")
    if rc != 0: return rc
    rc = bgs_write_fixture(user_src, "extern var shared_counter: i32\nfn read_counter() -> i32: shared_counter + 1\n", target_name, "extern redecl user")
    if rc != 0: return rc
    rc = bgs_write_fixture(main_src, "use user\nuse defs\n\nfn main:\n    if read_counter() == 42:\n        print(\"ok\")\n    else:\n        print(\"bad\")\n", target_name, "extern redecl main")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "build")
    argv = bgs_argv_append(argv, main_src)
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, bin)
    let build_result = bgs_edge_expect_success(root, target_name, compiler_path, case_dir, "whole-program-extern-var-redecl", argv)
    if build_result.rc != 0: return if build_result.rc == 0: 1 else: build_result.rc
    let run_result = bgs_run_binary_capture(root, target_name, "whole-program-extern-var-redecl-run", bin, 120000)
    if run_result.rc != 0: return if run_result.rc == 0: 1 else: run_result.rc
    bgs_edge_assert_exact(bgs_trim_trailing_line_endings(run_result.stdout), "ok", target_name, "whole_program_extern_var_redecl", "stdout")

fn bgs_check_imported_module_dependency_order(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let defs_src = bgs_resolve_join(case_dir, "defs.w")
    let module_src = bgs_resolve_join(case_dir, "m.w")
    let user_src = bgs_resolve_join(case_dir, "user.w")
    var rc = bgs_write_fixture(defs_src, "type T = opaque\n", target_name, "dependency order defs")
    if rc != 0: return rc
    rc = bgs_write_fixture(module_src, "use defs\nextern var gv: T\ntype T { x: i32 = 0 }\n", target_name, "dependency order module")
    if rc != 0: return rc
    rc = bgs_write_fixture(user_src, "use m\nfn main: let _ = 0\n", target_name, "dependency order user")
    if rc != 0: return rc
    let result = bgs_edge_expect_success(root, target_name, compiler_path, case_dir, "imported-module-dependency-order", bgs_argv_append(bgs_argv_append("", "check"), user_src))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    0

pub fn run_cli_selfhost_edge_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_pointer_index_rejected(root, target_name, compiler_path, bgs_resolve_join(base_dir, "pointer_index_rejected_case"))
    if rc != 0: return rc
    rc = bgs_check_prelude_output_functions(root, target_name, compiler_path, bgs_resolve_join(base_dir, "prelude_output_functions_case"))
    if rc != 0: return rc
    rc = bgs_check_whole_program_extern_var_redecl(root, target_name, compiler_path, bgs_resolve_join(base_dir, "whole_program_extern_var_redecl_case"))
    if rc != 0: return rc
    bgs_check_imported_module_dependency_order(root, target_name, compiler_path, bgs_resolve_join(base_dir, "imported_module_dependency_order_case"))

fn bgs_tool_from_env(env_name: str, fallback: str) -> str:
    let value = with_getenv_str(env_name)
    if value.len() > 0:
        return value
    fallback

fn bgs_nm_smoke(root: str, target_name: str, obj_path: str, label: str) -> i32:
    let capture_dir = bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name)
    let _mkdir = with_fs_mkdir_p(capture_dir)
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let stdout_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".nm.stdout")
    let stderr_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".nm.stderr")
    var argv = ""
    argv = bgs_argv_append(argv, bgs_tool_from_env("NM", "nm"))
    argv = bgs_argv_append(argv, obj_path)
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, 120000)
    if rc != 0:
        with_eprint("error: nm failed for " ++ label)
        return if rc == 0: 1 else: rc
    let _remove_stdout = with_fs_remove_file(stdout_path)
    let _remove_stderr = with_fs_remove_file(stderr_path)
    0

fn bgs_check_build_w_not_ignored(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "buildwdemo", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/main.w"), "fn main:\n    print(\"default main\")\n", target_name, "default main")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/custom.w"), "use c_import(\"answer.h\")\n\nfn main:\n    assert(ANSWER == 42)\n    print(\"custom build\")\n", target_name, "custom main")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "answer.h")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), "use std.build\n\npub fn build(b: Build) -> Build:\n    var target = target_new(.Executable, \"custom-build\", \"src/custom.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    target = target.link_system_lib(\"m\")\n    b.add_target(target)\n", target_name, "build.w")
    if rc != 0: return rc
    let result = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-not-ignored", bgs_argv_append("", "build"))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let custom_bin = bgs_resolve_join(case_dir, "out/bin/custom-build")
    if with_fs_file_exists(custom_bin) == 0:
        with_eprint("error: build_w_not_ignored missing custom-build output")
        return 1
    if with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/buildwdemo")) != 0:
        with_eprint("error: build_w_not_ignored unexpectedly produced default package output")
        return 1
    let run_result = bgs_run_binary_capture(root, target_name, "build-w-not-ignored-run", custom_bin, 120000)
    if run_result.rc != 0: return if run_result.rc == 0: 1 else: run_result.rc
    rc = bgs_assert_contains(run_result.stdout, "custom build", target_name, "build_w_not_ignored")
    if rc != 0: return rc
    let explicit = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-explicit-source", bgs_argv_append(bgs_argv_append("", "build"), bgs_resolve_join(case_dir, "src/main.w")))
    if explicit.rc != 0: return if explicit.rc == 0: 1 else: explicit.rc
    0

fn bgs_check_build_w_test_targets(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let single_dir = bgs_resolve_join(base_dir, "single")
    var rc = bgs_write_project_manifest(single_dir, "buildwtest", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "src/build_test.w"), "use c_import(\"answer.h\")\n\n@[test]\nfn build_w_test_target_uses_settings:\n    assert(ANSWER == 42)\n", target_name, "test source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w test target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "test header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "build.w"), "use std.build\n\npub fn build(b: Build) -> Build:\n    var target = target_new(.Test, \"configured-test\", \"src/build_test.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    b.add_target(target)\n", target_name, "test build.w")
    if rc != 0: return rc
    let single_result = bgs_build_expect_success(root, target_name, compiler_path, single_dir, "build-w-test-target", bgs_argv_append("", "build"))
    if single_result.rc != 0: return if single_result.rc == 0: 1 else: single_result.rc
    rc = bgs_assert_contains(single_result.stdout, "ok: 1 test passed", target_name, "build_w_test_target")
    if rc != 0: return rc

    let glob_dir = bgs_resolve_join(base_dir, "glob")
    rc = bgs_write_project_manifest(glob_dir, "buildwtestglob", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "tests/first.w"), "use c_import(\"answer.h\")\n\n@[test]\nfn first_build_w_glob_test_uses_settings:\n    assert(ANSWER == 42)\n", target_name, "glob first")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "tests/second.w"), "@[test]\nfn second_build_w_glob_test_runs:\n    assert(2 + 2 == 4)\n", target_name, "glob second")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w test glob target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "glob header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "build.w"), "use std.build\n\npub fn build(b: Build) -> Build:\n    var target = target_new(.Test, \"glob-tests\", \"tests/*.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    b.add_target(target)\n", target_name, "glob build.w")
    if rc != 0: return rc
    let glob_result = bgs_build_expect_success(root, target_name, compiler_path, glob_dir, "build-w-test-target-glob", bgs_argv_append("", "build"))
    if glob_result.rc != 0: return if glob_result.rc == 0: 1 else: glob_result.rc
    bgs_assert_contains(glob_result.stdout, "ok: 2 files passed in build.w test target glob-tests", target_name, "build_w_test_target_glob")

fn bgs_check_build_w_library_and_targets(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let lib_dir = bgs_resolve_join(base_dir, "library")
    var rc = bgs_write_project_manifest(lib_dir, "buildwlib", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "src/lib.w"), "use c_import(\"answer.h\")\n\npub fn answer_from_header -> i32:\n    ANSWER\n", target_name, "library source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w library target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "library header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "build.w"), "use std.build\n\npub fn build(b: Build) -> Build:\n    var target = target_new(.Library, \"configured\", \"src/lib.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    b.add_target(target)\n", target_name, "library build.w")
    if rc != 0: return rc
    let lib_result = bgs_build_expect_success(root, target_name, compiler_path, lib_dir, "build-w-library-target", bgs_argv_append("", "build"))
    if lib_result.rc != 0: return if lib_result.rc == 0: 1 else: lib_result.rc
    let archive = bgs_resolve_join(lib_dir, "out/lib/libconfigured.a")
    if with_fs_file_exists(archive) == 0:
        with_eprint("error: build_w_library_target missing archive: " ++ archive)
        return 1
    rc = bgs_nm_smoke(root, target_name, archive, "build-w-library-nm")
    if rc != 0: return rc

    let host_dir = bgs_resolve_join(base_dir, "host")
    rc = bgs_write_project_manifest(host_dir, "buildwhosttarget", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(host_dir, "src/main.w"), "fn main:\n    print(\"explicit host target\")\n", target_name, "host source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(host_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(b: Build) -> Build:\n    var host = BuildTarget.native\n    if os() == \"Macos\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.darwin_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.darwin_x86_64\n    else if os() == \"Linux\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.linux_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.linux_x86_64\n    else if os() == \"Windows\":\n        if arch() == \"x86_64\":\n            host = BuildTarget.windows_x86_64\n    var target = target_new(.Executable, \"host-target\", \"src/main.w\")\n    target = target.target(host)\n    b.add_target(target)\n", target_name, "host build.w")
    if rc != 0: return rc
    let host_result = bgs_build_expect_success(root, target_name, compiler_path, host_dir, "build-w-explicit-host-target", bgs_argv_append("", "build"))
    if host_result.rc != 0: return if host_result.rc == 0: 1 else: host_result.rc
    let host_bin = bgs_resolve_join(host_dir, "out/bin/host-target")
    if with_fs_file_exists(host_bin) == 0:
        with_eprint("error: build_w_explicit_host_target missing binary: " ++ host_bin)
        return 1
    let host_run = bgs_run_binary_capture(root, target_name, "build-w-explicit-host-run", host_bin, 120000)
    if host_run.rc != 0: return if host_run.rc == 0: 1 else: host_run.rc
    rc = bgs_assert_contains(host_run.stdout, "explicit host target", target_name, "build_w_explicit_host_target")
    if rc != 0: return rc

    let non_native_dir = bgs_resolve_join(base_dir, "non_native")
    rc = bgs_write_project_manifest(non_native_dir, "buildwnonnative", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(non_native_dir, "src/main.w"), "fn main:\n    print(\"wrong target\")\n", target_name, "non-native source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(non_native_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(b: Build) -> Build:\n    var non_native = BuildTarget.linux_x86_64\n    if os() == \"Linux\" and arch() == \"x86_64\":\n        non_native = BuildTarget.darwin_aarch64\n    var target = target_new(.Executable, \"wrong-target\", \"src/main.w\")\n    target = target.target(non_native)\n    b.add_target(target)\n", target_name, "non-native build.w")
    if rc != 0: return rc
    let non_native_result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-non-native-target", bgs_argv_append("", "build"), 120000, non_native_dir)
    if non_native_result.rc == 0:
        with_eprint("error: build_w_non_native_target unexpectedly succeeded")
        return 1
    bgs_assert_contains(non_native_result.stderr, "build.w cross-target platform", target_name, "build_w_non_native_target")

fn bgs_check_build_w_generated_source(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let gen_dir = bgs_resolve_join(base_dir, "generated")
    var rc = bgs_write_project_manifest(gen_dir, "buildwgenerated", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(gen_dir, "build.w"), "use std.build\n\npub fn build(b: Build) -> Build:\n    let generated = b.generated_source(\"out/gen/generated_main.w\", \"fn main:\\n    print(\\\"generated source\\\")\\n\")\n    generated.executable(\"generated-app\", \"out/gen/generated_main.w\")\n", target_name, "generated build.w")
    if rc != 0: return rc
    let gen_result = bgs_build_expect_success(root, target_name, compiler_path, gen_dir, "build-w-generated-source", bgs_argv_append("", "build"))
    if gen_result.rc != 0: return if gen_result.rc == 0: 1 else: gen_result.rc
    let generated_source = bgs_resolve_join(gen_dir, "out/gen/generated_main.w")
    let generated_bin = bgs_resolve_join(gen_dir, "out/bin/generated-app")
    if with_fs_file_exists(generated_source) == 0 or with_fs_file_exists(generated_bin) == 0:
        with_eprint("error: build_w_generated_source missing generated source or binary")
        return 1
    let run_result = bgs_run_binary_capture(root, target_name, "build-w-generated-source-run", generated_bin, 120000)
    if run_result.rc != 0: return if run_result.rc == 0: 1 else: run_result.rc
    rc = bgs_assert_contains(run_result.stdout, "generated source", target_name, "build_w_generated_source")
    if rc != 0: return rc

    let invalid_dir = bgs_resolve_join(base_dir, "invalid_generated")
    rc = bgs_write_project_manifest(invalid_dir, "buildwinvalidgenerated", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(invalid_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", target_name, "invalid generated source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(invalid_dir, "build.w"), "use std.build\n\npub fn build(b: Build) -> Build:\n    let generated = b.generated_source(\"../outside.w\", \"fn main: print(\\\"bad\\\")\\n\")\n    generated.executable(\"invalid-generated\", \"src/main.w\")\n", target_name, "invalid generated build.w")
    if rc != 0: return rc
    let invalid_result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-invalid-generated-source", bgs_argv_append("", "build"), 120000, invalid_dir)
    if invalid_result.rc == 0:
        with_eprint("error: build_w_invalid_generated_source unexpectedly succeeded")
        return 1
    bgs_assert_contains(invalid_result.stderr, "invalid build.w generated source path", target_name, "build_w_invalid_generated_source")

fn bgs_graph_build_file() -> str:
    "use std.build\n\npub fn build(b: Build) -> Build:\n    var out = b.executable(\"one\", \"src/one.w\")\n    out = out.executable(\"two\", \"src/two.w\")\n    out = out.generated_source(\"out/tmp/a.txt\", \"same\")\n    out = out.generated_source(\"out/tmp/b.txt\", \"same\")\n    out = out.binary_compare(\"bytes-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n    out = out.fixpoint_compare(\"fix-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n    var rsp = target_new(.GenerateResponseFile, \"rsp\", \"\").output(\"out/tmp/args.rsp\")\n    rsp = rsp.arg(\"-L/some path\")\n    rsp = rsp.arg(\"plain\")\n    out = out.add_target(rsp)\n    out = out.compile_c_object(\"helper-o\", \"runtime/helper.c\", \"out/lib/helper.o\")\n    var archive = target_new(.CreateStaticArchive, \"helper-a\", \"\").output(\"out/lib/libhelper.a\")\n    archive = archive.input(\"out/lib/helper.o\")\n    out = out.add_target(archive)\n    var embedded = target_new(.EmbedObjectFiles, \"embed-helper\", \"\").output(\"out/lib/embedded_helper.s\")\n    embedded = embedded.input(\"out/lib/helper.o\")\n    embedded = embedded.arg(\"helper_o\")\n    out = out.add_target(embedded)\n    out = out.compile_asm_object(\"embedded-helper-o\", \"out/lib/embedded_helper.s\", \"out/lib/embedded_helper.o\")\n    var copy_target = target_new(.CopyRuntimeTree, \"runtime-copy\", \"runtime\").output(\"out/runtime\")\n    copy_target = copy_target.input(\"helper.c\")\n    out = out.add_target(copy_target)\n    var promote = target_new(.PromoteTreeIfVerified, \"promote-runtime\", \"out/runtime\").output(\"promoted-runtime\")\n    promote = promote.input(\"helper.c\")\n    promote = promote.dep(\"runtime-copy\")\n    out = out.add_target(promote)\n    var corpus = target_new(.RunCorpusTest, \"corpus\", \"out/bin/two\")\n    corpus = corpus.dep(\"two\")\n    out = out.add_target(corpus)\n    var command = target_new(.Command, \"run-two\", \"out/bin/two\")\n    command = command.dep(\"two\")\n    out = out.add_target(command)\n    var install = target_new(.Install, \"install-two\", \"out/bin/two\").output(\"out/install/two\")\n    install = install.dep(\"two\")\n    install = install.arg(\"0755\")\n    out = out.add_target(install)\n    var aggregate = target_new(.Group, \"toolchain\", \"\")\n    aggregate = aggregate.dep(\"bytes-same\")\n    aggregate = aggregate.dep(\"fix-same\")\n    aggregate = aggregate.dep(\"rsp\")\n    aggregate = aggregate.dep(\"helper-a\")\n    aggregate = aggregate.dep(\"embedded-helper-o\")\n    aggregate = aggregate.dep(\"promote-runtime\")\n    aggregate = aggregate.dep(\"corpus\")\n    aggregate = aggregate.dep(\"run-two\")\n    aggregate = aggregate.dep(\"install-two\")\n    out = out.add_target(aggregate)\n    out.default(\"toolchain\")\n"

fn bgs_check_build_w_graph_v2(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "buildwgraphv2", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/one.w"), "fn main:\n    print(\"one\")\n", target_name, "graph one")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/two.w"), "fn main:\n    print(\"two\")\n", target_name, "graph two")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "runtime/helper.c"), "int helper(void) {\n  return 42;\n}\n", target_name, "graph helper")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), bgs_graph_build_file(), target_name, "graph build.w")
    if rc != 0: return rc
    let graph_result = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-graph-v2", bgs_argv_append(bgs_argv_append("", "build"), "--graph"))
    if graph_result.rc != 0: return if graph_result.rc == 0: 1 else: graph_result.rc
    rc = bgs_assert_contains(graph_result.stdout, "WITH_BUILD_GRAPH\t2", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "default_target\ttoolchain", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t12\thelper-o\truntime/helper.c\t0\t0\tout/lib/helper.o", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t15\thelper-a\t\t0\t0\tout/lib/libhelper.a", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t17\tembed-helper\t\t0\t0\tout/lib/embedded_helper.s", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t10\tbytes-same\tout/tmp/a.txt\t0\t0\t", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t16\trsp\t\t0\t0\tout/tmp/args.rsp", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t7\trun-two\tout/bin/two\t0\t0\t", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t8\tinstall-two\tout/bin/two\t0\t0\tout/install/two", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    let selected = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-graph-selected", bgs_argv_append(bgs_argv_append(bgs_argv_append("", "build"), ":two"), "--graph"))
    if selected.rc != 0: return if selected.rc == 0: 1 else: selected.rc
    rc = bgs_assert_not_contains(selected.stdout, "target\t12\thelper-o", target_name, "build_w_graph_selected")
    if rc != 0: return rc
    let deps = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-graph-deps", bgs_argv_append(bgs_argv_append(bgs_argv_append("", "build"), ":toolchain"), "--graph"))
    if deps.rc != 0: return if deps.rc == 0: 1 else: deps.rc
    rc = bgs_assert_contains(deps.stdout, "target\t12\thelper-o", target_name, "build_w_graph_deps")
    if rc != 0: return rc
    rc = bgs_assert_contains(deps.stdout, "target\t9\ttoolchain\t\t0\t0\t", target_name, "build_w_graph_deps")
    if rc != 0: return rc
    rc = bgs_assert_not_contains(deps.stdout, "target\t0\tone\t", target_name, "build_w_graph_deps")
    if rc != 0: return rc
    let full = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-full-graph", bgs_argv_append("", "build"))
    if full.rc != 0: return if full.rc == 0: 1 else: full.rc
    if with_fs_file_exists(bgs_resolve_join(case_dir, "out/lib/helper.o")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/lib/libhelper.a")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/lib/embedded_helper.s")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/lib/embedded_helper.o")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/runtime/helper.c")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "promoted-runtime/helper.c")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/corpus/corpus/stdout.txt")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/command/run-two/stdout.txt")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/install/two")) == 0:
        with_eprint("error: build_w_graph_v2 missing one or more expected outputs")
        return 1
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/corpus/corpus/stdout.txt"), "two", target_name, "build_w_graph_corpus")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/command/run-two/stdout.txt"), "two", target_name, "build_w_graph_command")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/lib/embedded_helper.s"), "with_embedded_helper_o_start", target_name, "build_w_graph_embed")
    if rc != 0: return rc
    let _remove_out1 = with_fs_remove_dir(bgs_resolve_join(case_dir, "out"))
    let group = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-group-deps", bgs_argv_append(bgs_argv_append("", "build"), ":toolchain"))
    if group.rc != 0: return if group.rc == 0: 1 else: group.rc
    if with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/two")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/one")) != 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/lib/libhelper.a")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/corpus/corpus/stdout.txt")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/command/run-two/stdout.txt")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/install/two")) == 0:
        with_eprint("error: build_w_graph_v2 group dependency outputs were wrong")
        return 1
    let _remove_out2 = with_fs_remove_dir(bgs_resolve_join(case_dir, "out"))
    let bytes = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-binary-compare", bgs_argv_append(bgs_argv_append("", "build"), ":bytes-same"))
    if bytes.rc != 0: return if bytes.rc == 0: 1 else: bytes.rc
    let fix = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-fixpoint-compare", bgs_argv_append(bgs_argv_append("", "build"), ":fix-same"))
    if fix.rc != 0: return if fix.rc == 0: 1 else: fix.rc
    let rsp = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-response-file", bgs_argv_append(bgs_argv_append("", "build"), ":rsp"))
    if rsp.rc != 0: return if rsp.rc == 0: 1 else: rsp.rc
    let rsp_text = bgs_trim_trailing_line_endings(with_fs_read_file(bgs_resolve_join(case_dir, "out/tmp/args.rsp")))
    if rsp_text != "\"-L/some path\"\n\"plain\"":
        with_eprint("error: build_w_graph_v2 response file contents mismatch: " ++ rsp_text)
        return 1
    let _remove_out3 = with_fs_remove_dir(bgs_resolve_join(case_dir, "out"))
    let two = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-target-select", bgs_argv_append(bgs_argv_append("", "build"), ":two"))
    if two.rc != 0: return if two.rc == 0: 1 else: two.rc
    if with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/two")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/one")) != 0:
        with_eprint("error: build_w_graph_v2 target selection outputs were wrong")
        return 1
    0

pub fn run_cli_selfhost_build_w_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_build_w_not_ignored(root, target_name, compiler_path, bgs_resolve_join(base_dir, "not_ignored"))
    if rc != 0: return rc
    rc = bgs_check_build_w_test_targets(root, target_name, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bgs_check_build_w_library_and_targets(root, target_name, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bgs_check_build_w_generated_source(root, target_name, compiler_path, base_dir)
    if rc != 0: return rc
    bgs_check_build_w_graph_v2(root, target_name, compiler_path, bgs_resolve_join(base_dir, "graph_v2"))
