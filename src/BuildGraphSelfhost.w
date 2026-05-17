// BuildGraphSelfhost -- bulky selfhost build.w fixture tests used by the
// repository build graph. Kept out of main.w so the CLI entry point remains a
// dispatcher instead of a fixture warehouse.

use BuildGraphSelfhostHarness
use BuildGraphRuntime

extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_eprint(s: str) -> void

pub fn run_cli_selfhost_parallel_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let case_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    let src = bgs_resolve_join(case_dir, "attr_only.w")
    var rc = bgs_write_fixture(src, "@[test]\nfn attr_only:\n    assert(1 == 1)\n", target_name, "parallel same-source test")
    if rc != 0:
        return rc

    let single = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "parallel-same-source-single", bgs_argv_append(bgs_argv_append("", "test"), src), 120000, root)
    if single.rc != 0:
        return if single.rc == 0: 1 else: single.rc
    if single.stderr.len() != 0:
        with_eprint("error: cli selfhost parallel test target '" ++ target_name ++ "' single run produced stderr")
        with_eprint(single.stderr)
        return 1

    var argv = ""
    argv = bgs_argv_append(argv, compiler_path)
    argv = bgs_argv_append(argv, "test")
    argv = bgs_argv_append(argv, src)

    let jobs = 32
    let pids: Vec[i32] = Vec.new()
    for i in 0..jobs:
        let stdout_path = bgs_resolve_join(case_dir, f"job-{i}.stdout")
        let stderr_path = bgs_resolve_join(case_dir, f"job-{i}.stderr")
        let pid = build_graph_rt_exec_argv_capture_spawn(argv, stdout_path, stderr_path)
        if pid <= 0:
            with_eprint("error: cli selfhost parallel test target '" ++ target_name ++ f"' could not spawn job {i}")
            return 1
        pids.push(pid)

    var failed = false
    for i in 0..jobs:
        let pid = pids.get(i as i64)
        let job_rc = build_graph_rt_exec_wait(pid, 120000)
        if job_rc != 0:
            let stdout_path = bgs_resolve_join(case_dir, f"job-{i}.stdout")
            let stderr_path = bgs_resolve_join(case_dir, f"job-{i}.stderr")
            with_eprint("error: cli selfhost parallel test target '" ++ target_name ++ f"' job {i} failed with exit code {job_rc}")
            let stdout_text = with_fs_read_file(stdout_path)
            if stdout_text.len() > 0:
                with_eprint(stdout_text)
            let stderr_text = with_fs_read_file(stderr_path)
            if stderr_text.len() > 0:
                with_eprint(stderr_text)
            failed = true
    if failed:
        return 1
    0

fn bgs_check_init_ai_docs(root: str, project_dir: str, target_name: str, label: str) -> i32:
    let expected = with_fs_read_file(bgs_resolve_join(root, "docs/with_for_ai.md"))
    if expected.len() == 0:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' could not read docs/with_for_ai.md")
        return 1
    let agents = with_fs_read_file(bgs_resolve_join(project_dir, "AGENTS.md"))
    if agents != expected:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' AGENTS.md did not match docs/with_for_ai.md for " ++ label)
        return 1
    let claude = with_fs_read_file(bgs_resolve_join(project_dir, "CLAUDE.md"))
    if claude != expected:
        with_eprint("error: cli_selfhost_project_test target '" ++ target_name ++ "' CLAUDE.md did not match docs/with_for_ai.md for " ++ label)
        return 1
    0

fn bgs_check_init_common_files(root: str, project_dir: str, package_name: str, target_name: str, label: str) -> i32:
    var rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "build.w"), target_name, label ++ " build")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "README.md"), target_name, label ++ " readme")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(project_dir, ".gitignore"), target_name, label ++ " gitignore")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "AGENTS.md"), target_name, label ++ " agents")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "CLAUDE.md"), target_name, label ++ " claude")
    if rc != 0: return rc
    rc = bgs_project_expect_file(bgs_resolve_join(project_dir, "tests/smoke.w"), target_name, label ++ " smoke test")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(project_dir, "with.toml"), "[package]", target_name, label ++ " manifest package section")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(project_dir, "build.w"), "out.default(\"" ++ package_name ++ "\")", target_name, label ++ " build default")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(project_dir, "README.md"), "# " ++ package_name, target_name, label ++ " readme title")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(project_dir, ".gitignore"), ".with/", target_name, label ++ " gitignore with cache")
    if rc != 0: return rc
    bgs_check_init_ai_docs(root, project_dir, target_name, label)

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
    rc = bgs_check_init_common_files(root, case_dir, expected_name, target_name, "init_in_cwd")
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
    rc = bgs_check_init_common_files(root, project_dir, project_name, target_name, "init_named_dir")
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

fn bgs_regex_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' missing expected output for " ++ label ++ ": " ++ needle)
    1

fn bgs_regex_assert_not_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) == 0:
        return 0
    with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' found forbidden output for " ++ label ++ ": " ++ needle)
    1

fn bgs_regex_file_contains(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' missing file for " ++ label ++ ": " ++ path)
        return 1
    bgs_regex_assert_contains(with_fs_read_file(path), needle, target_name, label)

fn bgs_regex_file_forbids(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' missing file for " ++ label ++ ": " ++ path)
        return 1
    bgs_regex_assert_not_contains(with_fs_read_file(path), needle, target_name, label)

fn bgs_copy_fixture_file(src: str, dst: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(src) == 0:
        with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' missing source file for " ++ label ++ ": " ++ src)
        return 1
    bgs_write_fixture(dst, with_fs_read_file(src), target_name, label)

fn bgs_drop_first_lines(text: str, count: i32) -> str:
    var line_start = 0
    var line_no = 1
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if line_no == count:
                return text.slice((i + 1) as i64, text.len())
            line_no = line_no + 1
            line_start = i + 1
    if line_no > count:
        return text.slice(line_start as i64, text.len())
    ""

fn bgs_regex_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 180000, case_dir)
    if result.rc != 0:
        with_eprint("error: pcre2 prep selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bgs_check_pcre2_defs_prune_ebcdic_tables(root: str, target_name: str) -> i32:
    let defs = bgs_resolve_join(root, "lib/std/re/defs.w")
    var rc = bgs_regex_file_forbids(defs, "_pcre2_ebcdic_1047_to_ascii_8", target_name, "ebcdic table externs")
    if rc != 0: return rc
    bgs_regex_file_forbids(defs, "_pcre2_ascii_to_ebcdic_1047_8", target_name, "ebcdic table externs")

fn bgs_check_pcre2_prepare_shared_externs(root: str, target_name: str, base_dir: str) -> i32:
    let raw_dir = bgs_resolve_join(base_dir, "raw")
    let generated_dir = bgs_resolve_join(base_dir, "generated")
    var rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "defs.w"), "// std.re.defs - shared definitions\nextern fn preamble_helper() -> void\n", target_name, "shared externs defs")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_tables.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nvar _pcre2_utf8_table1: *c_int\nvar _pcre2_OP_lengths_8: *u8\n", target_name, "shared externs tables")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_compile.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nextern var _pcre2_utf8_table1: *c_int\nvar _pcre2_posix_class_maps8: *c_int\n", target_name, "shared externs compile")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_compile_class.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nextern var _pcre2_utf8_table1: *c_int\nextern var _pcre2_posix_class_maps8: *c_int\n", target_name, "shared externs compile class")
    if rc != 0: return rc
    let files: Vec[str] = Vec.new()
    files.push("defs.w")
    files.push("pcre2_tables.w")
    files.push("pcre2_compile.w")
    files.push("pcre2_compile_class.w")
    for i in 0..files.len() as i32:
        let file = files.get(i as i64)
        rc = bgs_copy_fixture_file(bgs_resolve_join(raw_dir, file), bgs_resolve_join(generated_dir, file), target_name, "shared externs copy")
        if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_tables.w"), "var _pcre2_utf8_table1: *c_int", target_name, "shared externs tables")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_tables.w"), "var _pcre2_OP_lengths_8: *u8", target_name, "shared externs tables")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile.w"), "extern var _pcre2_utf8_table1: *c_int", target_name, "shared externs compile")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile.w"), "var _pcre2_posix_class_maps8: *c_int", target_name, "shared externs compile")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile_class.w"), "extern var _pcre2_utf8_table1: *c_int", target_name, "shared externs class")
    if rc != 0: return rc
    bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile_class.w"), "extern var _pcre2_posix_class_maps8: *c_int", target_name, "shared externs class")

fn bgs_check_pcre2_prepare_width_prunes(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let raw_dir = bgs_resolve_join(base_dir, "raw")
    let generated_dir = bgs_resolve_join(base_dir, "generated")
    let compile_text = "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nextern fn _pcre2_keep_8(ch: c_uint) -> c_uint\nfn keep_body(flag: c_int) -> c_int {\n    var c__goto_6350_16: c_uint = 0\n    if flag != 0 {\n        (c__goto_6350_16 = _pcre2_keep_8(c__goto_6350_16))\n    } else {\n        (c__goto_6350_16 = 1)\n    }\n    (c__goto_6350_16 as c_int)\n}\n"
    var rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "defs.w"), "// std.re.defs - shared definitions\ntype c_void = opaque\ntype c_int = i32\ntype c_uint = u32\ntype c_ushort = u16\nextern fn strlen(s: *const i8) -> i64\nextern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void\n", target_name, "width prune defs")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_compile.w"), compile_text, target_name, "width prune compile")
    if rc != 0: return rc
    rc = bgs_copy_fixture_file(bgs_resolve_join(raw_dir, "defs.w"), bgs_resolve_join(generated_dir, "defs.w"), target_name, "width prune defs copy")
    if rc != 0: return rc
    rc = bgs_copy_fixture_file(bgs_resolve_join(raw_dir, "pcre2_compile.w"), bgs_resolve_join(generated_dir, "pcre2_compile.w"), target_name, "width prune compile copy")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile.w"), "(c__goto_6350_16 = _pcre2_keep_8(c__goto_6350_16))", target_name, "width prune local")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile.w"), "} else {", target_name, "width prune else")
    if rc != 0: return rc
    let wrapper = bgs_resolve_join(base_dir, "wrapper.w")
    let wrapper_text = with_fs_read_file(bgs_resolve_join(generated_dir, "defs.w")) ++ bgs_drop_first_lines(with_fs_read_file(bgs_resolve_join(generated_dir, "pcre2_compile.w")), 2) ++ "\nfn main { print(\"ok\") }\n"
    rc = bgs_write_fixture(wrapper, wrapper_text, target_name, "width prune wrapper")
    if rc != 0: return rc
    let result = bgs_regex_expect_success(root, target_name, compiler_path, base_dir, "width-prunes-whole-decls", bgs_argv_append(bgs_argv_append("", "check"), wrapper))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    0

fn bgs_check_pcre2_prepare_shared_lets(root: str, target_name: str, base_dir: str) -> i32:
    let raw_dir = bgs_resolve_join(base_dir, "raw")
    let generated_dir = bgs_resolve_join(base_dir, "generated")
    var rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "defs.w"), "// std.re.defs - shared definitions\nlet ucp_C: c_uint = 0\nlet ucp_L: c_uint = 1\n", target_name, "shared lets defs")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_tables.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nlet LOCAL_TABLE_ONLY: c_uint = 99\n", target_name, "shared lets tables")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_compile.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nlet COMPILE_ONLY: c_uint = 7\n", target_name, "shared lets compile")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(raw_dir, "pcre2_match.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nlet MATCH_ONLY: c_uint = 8\n", target_name, "shared lets match")
    if rc != 0: return rc
    let files: Vec[str] = Vec.new()
    files.push("defs.w")
    files.push("pcre2_tables.w")
    files.push("pcre2_compile.w")
    files.push("pcre2_match.w")
    for i in 0..files.len() as i32:
        let file = files.get(i as i64)
        rc = bgs_copy_fixture_file(bgs_resolve_join(raw_dir, file), bgs_resolve_join(generated_dir, file), target_name, "shared lets copy")
        if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "defs.w"), "let ucp_C: c_uint = 0", target_name, "shared lets defs")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "defs.w"), "let ucp_L: c_uint = 1", target_name, "shared lets defs")
    if rc != 0: return rc
    rc = bgs_regex_file_forbids(bgs_resolve_join(generated_dir, "pcre2_tables.w"), "let ucp_C: c_uint = 0", target_name, "shared lets tables")
    if rc != 0: return rc
    rc = bgs_regex_file_forbids(bgs_resolve_join(generated_dir, "pcre2_compile.w"), "let ucp_C: c_uint = 0", target_name, "shared lets compile")
    if rc != 0: return rc
    rc = bgs_regex_file_forbids(bgs_resolve_join(generated_dir, "pcre2_match.w"), "let ucp_C: c_uint = 0", target_name, "shared lets match")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_tables.w"), "let LOCAL_TABLE_ONLY: c_uint = 99", target_name, "shared lets tables")
    if rc != 0: return rc
    rc = bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_compile.w"), "let COMPILE_ONLY: c_uint = 7", target_name, "shared lets compile")
    if rc != 0: return rc
    bgs_regex_file_contains(bgs_resolve_join(generated_dir, "pcre2_match.w"), "let MATCH_ONLY: c_uint = 8", target_name, "shared lets match")

fn bgs_check_std_re_shared_dependency_imports(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let src = bgs_resolve_join(base_dir, "main.w")
    var rc = bgs_write_fixture(src, "use std.re.defs\nuse std.re.pcre2_compile\nuse std.re.pcre2_match\n\nfn main:\n    print(\"ok\")\n", target_name, "std re dependency imports")
    if rc != 0: return rc
    let result = bgs_regex_expect_success(root, target_name, compiler_path, base_dir, "std-re-shared-dependency-imports", bgs_argv_append(bgs_argv_append("", "check"), src))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    0

fn bgs_check_opaque_field_access_rejected(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let src = bgs_resolve_join(base_dir, "opaque_field_access.w")
    var rc = bgs_write_fixture(src, "type T = opaque\n\nfn f(p: *mut T):\n    (p.x = 1)\n\nfn main:\n    let _ = 0\n", target_name, "opaque field access")
    if rc != 0: return rc
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "opaque-field-access", bgs_argv_append(bgs_argv_append("", "check"), src), 120000, base_dir)
    if result.rc == 0:
        with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' accepted opaque field access")
        return 1
    bgs_regex_assert_contains(result.stderr, "field access requires a concrete struct or union type; this type is opaque", target_name, "opaque_field_access")

fn bgs_check_pcre2_match_heapframe(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let match_path = bgs_resolve_join(root, "lib/std/re/pcre2_match.w")
    let match_text = with_fs_read_file(match_path)
    var rc = bgs_regex_assert_not_contains(match_text, "type heapframe = opaque", target_name, "pcre2 match heapframe")
    if rc != 0: return rc
    rc = bgs_regex_assert_not_contains(match_text, "type heapframe_align = opaque", target_name, "pcre2 match heapframe")
    if rc != 0: return rc
    let obj = bgs_resolve_join(base_dir, "pcre2_match_issue111.o")
    var argv = ""
    argv = bgs_argv_append(argv, "build")
    argv = bgs_argv_append(argv, match_path)
    argv = bgs_argv_append(argv, "--emit-obj")
    argv = bgs_argv_append(argv, "--no-prelude")
    argv = bgs_argv_append(argv, "-O0")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, obj)
    let result = bgs_regex_expect_success(root, target_name, compiler_path, root, "pcre2-match-heapframe", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    0

fn bgs_check_pcre2_compile_builds(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let src = bgs_resolve_join(base_dir, "pcre2_compile_builds.w")
    let bin = bgs_resolve_join(base_dir, "pcre2_compile_builds")
    var rc = bgs_write_fixture(src, "use std.re.defs\nuse std.re.pcre2_compile\n\nfn main:\n    let _ = pcre2_compile_8((null as *const u8), 0, 0, (null as *mut c_int), (null as *mut c_ulong), (null as *mut pcre2_real_compile_context_8))\n    print(\"ok\")\n", target_name, "pcre2 compile builds")
    if rc != 0: return rc
    let result = bgs_regex_expect_success(root, target_name, compiler_path, base_dir, "pcre2-compile-builds", bgs_argv_append(bgs_argv_append(bgs_argv_append(bgs_argv_append("", "build"), src), "-o"), bin))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    rc = bgs_regex_assert_not_contains(result.stderr, "MIR lowering failed", target_name, "pcre2 compile builds")
    if rc != 0: return rc
    rc = bgs_regex_assert_not_contains(result.stderr, "AST codegen was removed", target_name, "pcre2 compile builds")
    if rc != 0: return rc
    if with_fs_file_exists(bin) == 0:
        with_eprint("error: cli_selfhost_pcre2_prep_test target '" ++ target_name ++ "' missing pcre2_compile_builds output: " ++ bin)
        return 1
    0

fn bgs_check_pcre2_jit_no_support(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let src = bgs_resolve_join(base_dir, "pcre2_jit_no_support.w")
    let text = "use std.re.defs\nuse std.re.pcre2_jit_compile\n\nfn main() -> i32:\n    let rc_null = pcre2_jit_compile_8((null as *mut pcre2_real_code_8), 0)\n    if rc_null != PCRE2_ERROR_NULL: return 1\n\n    let rc_test_alloc = pcre2_jit_compile_8((null as *mut pcre2_real_code_8), PCRE2_JIT_TEST_ALLOC)\n    if rc_test_alloc != PCRE2_ERROR_JIT_UNSUPPORTED: return 2\n\n    let stack = pcre2_jit_stack_create_8(1, 1024, (null as *mut pcre2_real_general_context_8))\n    if stack != null: return 3\n\n    pcre2_jit_stack_assign_8((null as *mut pcre2_real_match_context_8), (null as *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8), (null as *mut c_void))\n    pcre2_jit_stack_free_8(stack)\n    pcre2_jit_free_unused_memory_8((null as *mut pcre2_real_general_context_8))\n    _pcre2_jit_free_rodata_8((null as *mut c_void), (null as *mut c_void))\n    _pcre2_jit_free_8((null as *mut c_void), (null as *mut pcre2_memctl))\n\n    if _pcre2_jit_get_size_8((null as *mut c_void)) != 0: return 4\n    if _pcre2_jit_get_target_8() == null: return 5\n    return 0\n"
    var rc = bgs_write_fixture(src, text, target_name, "pcre2 jit no support")
    if rc != 0: return rc
    let result = bgs_regex_expect_success(root, target_name, compiler_path, base_dir, "pcre2-jit-no-support", bgs_argv_append(bgs_argv_append("", "run"), src))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    0

fn bgs_check_pcre2_generated_existing_main(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let generated_dir = bgs_resolve_join(case_dir, "generated")
    var rc = bgs_write_project_manifest(case_dir, "pcre2generatedcheck", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(generated_dir, "defs.w"), "// std.re.defs\ntype c_int = i32\n", target_name, "pcre2 generated defs")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(generated_dir, "pcre2_helper.w"), "// Migrated from PCRE2\nuse std.re.defs\n\nfn helper_value() -> c_int:\n    7\n", target_name, "pcre2 generated helper")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(generated_dir, "pcre2test.w"), "// Migrated from PCRE2\nuse std.re.defs\n\nfn main() -> i32:\n    0\n", target_name, "pcre2 generated existing main")
    if rc != 0: return rc
    let build_text =
        "use std.build\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var target = target_new(.Pcre2GeneratedCheck, \"pcre2-check-existing-main\", " ++ bgs_with_string_literal(compiler_path) ++ ")\n" ++
        "    target = target.input(\"generated\")\n" ++
        "    var out = ctx.new_build()\n    out = out.add_target(target)\n" ++
        "    out.default(\"pcre2-check-existing-main\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), build_text, target_name, "pcre2 generated check build.w")
    if rc != 0: return rc
    let result = bgs_regex_expect_success(root, target_name, compiler_path, case_dir, "pcre2-generated-existing-main", bgs_argv_append(bgs_argv_append("", "build"), ":pcre2-check-existing-main"))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    bgs_regex_assert_contains(result.stdout, "OK=2 TOTAL_ERRORS=0", target_name, "pcre2_check_existing_main")

pub fn run_cli_selfhost_pcre2_prep_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_pcre2_defs_prune_ebcdic_tables(root, target_name)
    if rc != 0: return rc
    rc = bgs_check_pcre2_prepare_shared_externs(root, target_name, bgs_resolve_join(base_dir, "pcre2_prepare_case"))
    if rc != 0: return rc
    rc = bgs_check_pcre2_prepare_width_prunes(root, target_name, compiler_path, bgs_resolve_join(base_dir, "pcre2_prepare_width_prune_case"))
    if rc != 0: return rc
    rc = bgs_check_pcre2_prepare_shared_lets(root, target_name, bgs_resolve_join(base_dir, "pcre2_prepare_shared_lets_case"))
    if rc != 0: return rc
    rc = bgs_check_std_re_shared_dependency_imports(root, target_name, compiler_path, bgs_resolve_join(base_dir, "std_re_shared_dependency_case"))
    if rc != 0: return rc
    rc = bgs_check_opaque_field_access_rejected(root, target_name, compiler_path, bgs_resolve_join(base_dir, "opaque_field_access_case"))
    if rc != 0: return rc
    rc = bgs_check_pcre2_match_heapframe(root, target_name, compiler_path, bgs_resolve_join(base_dir, "pcre2_match_heapframe_case"))
    if rc != 0: return rc
    rc = bgs_check_pcre2_compile_builds(root, target_name, compiler_path, bgs_resolve_join(base_dir, "pcre2_compile_builds_case"))
    if rc != 0: return rc
    rc = bgs_check_pcre2_jit_no_support(root, target_name, compiler_path, bgs_resolve_join(base_dir, "pcre2_jit_no_support_case"))
    if rc != 0: return rc
    rc = bgs_check_pcre2_generated_existing_main(root, target_name, compiler_path, bgs_resolve_join(base_dir, "pcre2_generated_existing_main_case"))
    if rc != 0: return rc
    0

fn bgs_migrate_error(target_name: str, message: str) -> void:
    with_eprint("error: cli selfhost migrator test target '" ++ target_name ++ "' " ++ message)

fn bgs_migrate_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    bgs_migrate_error(target_name, "missing expected output for " ++ label ++ ": " ++ needle)
    1

fn bgs_migrate_assert_not_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) == 0:
        return 0
    bgs_migrate_error(target_name, "found forbidden output for " ++ label ++ ": " ++ needle)
    1

fn bgs_migrate_file_contains(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        bgs_migrate_error(target_name, "missing file for " ++ label ++ ": " ++ path)
        return 1
    bgs_migrate_assert_contains(with_fs_read_file(path), needle, target_name, label)

fn bgs_migrate_file_forbids(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        bgs_migrate_error(target_name, "missing file for " ++ label ++ ": " ++ path)
        return 1
    bgs_migrate_assert_not_contains(with_fs_read_file(path), needle, target_name, label)

fn bgs_index_of(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if needle.len() > text.len():
        return -1
    let max_start = (text.len() - needle.len()) as i32
    for i in 0..(max_start + 1):
        var matched = true
        for j in 0..needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
        if matched:
            return i
    -1

fn bgs_count_occurrences(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    var count = 0
    var offset = 0
    while offset < text.len() as i32:
        let found = bgs_index_of(text.slice(offset as i64, text.len()), needle)
        if found < 0:
            break
        count = count + 1
        offset = offset + found + needle.len() as i32
    count

fn bgs_migrate_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 180000, case_dir)
    if result.rc != 0:
        bgs_migrate_error(target_name, "case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bgs_check_migrate_global_init_list(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "initlist.c")
    let out_w = bgs_resolve_join(case_dir, "initlist.w")
    var rc = bgs_write_fixture(src, "typedef int (*callback_t)(int);\ntypedef struct inner { callback_t cb; void *data; } inner;\ntypedef struct outer { inner in; int limit; } outer;\nint add1(int x) { return x + 1; }\nouter g = { { add1, 0 }, 7 };\n", target_name, "migrate global init list")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-global-init-list", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    bgs_migrate_file_contains(out_w, "var g: outer = outer { in_: inner { cb: add1, data: null }, limit: 7 }", target_name, "global_init_list")

fn bgs_check_migrate_host_header_compat(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "uses_isatty.c")
    let out_w = bgs_resolve_join(case_dir, "uses_isatty.w")
    var rc = bgs_write_fixture(bgs_resolve_join(case_dir, "config.h"), "/* Simulate an unconfigured config.h template. */\n", target_name, "migrate host header config")
    if rc != 0: return rc
    let c_text = "#if defined HAVE_CONFIG_H\n#include \"config.h\"\n#endif\n\n#ifndef HAVE_UNISTD_H\n#error \"missing HAVE_UNISTD_H\"\n#endif\n\n#ifdef HAVE_UNISTD_H\n#include <unistd.h>\n#endif\n\n#include <stdio.h>\n\nint tty_status(FILE *f) { return isatty(fileno(f)); }\n"
    rc = bgs_write_fixture(src, c_text, target_name, "migrate host header source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "-I")
    argv = bgs_argv_append(argv, case_dir)
    argv = bgs_argv_append(argv, "-D")
    argv = bgs_argv_append(argv, "HAVE_CONFIG_H=1")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-host-header-compat", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    bgs_migrate_file_contains(out_w, "tty_status", target_name, "host_header_compat")

fn bgs_check_migrate_assignment_compat(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "assignments.c")
    let out_w = bgs_resolve_join(case_dir, "assignments.w")
    let c_text = "typedef unsigned int c_uint;\ntypedef struct {\n  c_uint *groupinfo;\n  c_uint *parsed_pattern;\n} compile_block;\n\nvoid f(void) {\n  compile_block cb;\n  c_uint stack_groupinfo[32];\n  c_uint stack_parsed_pattern[64];\n  c_uint pp = 0;\n  c_uint skipatstart = 0;\n  cb.groupinfo = stack_groupinfo;\n  cb.parsed_pattern = stack_parsed_pattern;\n  skipatstart = (pp = pp + 1);\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "migrate assignment compat")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-assignment-compat", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_migrate_assert_contains(out_text, "(__local_cb.groupinfo = (&(unsafe: __local_stack_groupinfo[0]) as *mut c_uint))", target_name, "assignment_compat")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(__local_cb.parsed_pattern = (&(unsafe: __local_stack_parsed_pattern[0]) as *mut c_uint))", target_name, "assignment_compat")
    if rc != 0: return rc
    let pp_simple = "(__local_pp = (__local_pp +% 1))"
    let pp_casted = "(__local_pp = ((__local_pp as c_uint) +% (1 as c_uint)))"
    let pp_index = if bgs_index_of(out_text, pp_simple) >= 0: bgs_index_of(out_text, pp_simple) else: bgs_index_of(out_text, pp_casted)
    let skip_index = bgs_index_of(out_text, "(__local_skipatstart = __local_pp)")
    if pp_index < 0 or skip_index < 0 or pp_index >= skip_index:
        bgs_migrate_error(target_name, "assignment_compat did not preserve assignment sequencing")
        return 1
    rc = bgs_migrate_assert_not_contains(out_text, "(__local_skipatstart = ((__local_pp) =", target_name, "assignment_compat")
    if rc != 0: return rc
    let check_result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-assignment-compat", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check_result.rc != 0: return if check_result.rc == 0: 1 else: check_result.rc
    0

fn bgs_check_migrate_rvalue_sequencing(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "rvalue_sequencing.c")
    let out_w = bgs_resolve_join(case_dir, "rvalue_sequencing.w")
    let c_text = "typedef unsigned char u8;\n\nstatic int issue120_id(int x) { return x; }\n\nint init_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = *p++;\n  return c * 10 + (int)(p - buf);\n}\n\nint assign_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = 0;\n  c = *p++;\n  return c * 10 + (int)(p - buf);\n}\n\nint binary_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = (*p++) + 0;\n  return c * 10 + (int)(p - buf);\n}\n\nint call_arg_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = issue120_id(*p++);\n  return c * 10 + (int)(p - buf);\n}\n\n#define ISSUE120_GETCHARINCTEST(ch, ptr) ch = *ptr++; if (utf && ch >= 66u) ch += 1000\n\nint macro_expr(int utf) {\n  const u8 *buf = (const u8 *)\"BA\";\n  const u8 *p = buf;\n  int c = 0;\n  ISSUE120_GETCHARINCTEST(c, p);\n  return c * 10 + (int)(p - buf);\n}\n\nstatic unsigned int issue120_ord2utf(unsigned int c, u8 *p) {\n  *p = (u8)c;\n  return 1;\n}\n\n#define ISSUE120_PUTCHAR(c, p) ((utf && c > 127u) ? issue120_ord2utf(c, p) : (*p = c, 1))\n\nint macro_ternary_comma_expr(int utf) {\n  u8 buf[1] = { 0 };\n  u8 *p = buf;\n  unsigned int c = 65u;\n  p += ISSUE120_PUTCHAR(c, p);\n  return ((int)buf[0]) * 10 + (int)(p - buf);\n}\n\nint main(void) {\n  if (init_expr() != 651) return 1;\n  if (assign_expr() != 651) return 2;\n  if (binary_expr() != 651) return 3;\n  if (call_arg_expr() != 651) return 4;\n  if (macro_expr(0) != 661) return 5;\n  if (macro_expr(1) != 10661) return 6;\n  if (macro_ternary_comma_expr(0) != 651) return 7;\n  return 0;\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "migrate rvalue sequencing")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-rvalue-sequencing", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_migrate_assert_contains(out_text, "with 0 as __ci_expr_seq_", target_name, "rvalue_sequencing")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "var __ci_expr_old_", target_name, "rvalue_sequencing")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(__local_p = __local_p + 1)", target_name, "rvalue_sequencing")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(unsafe: *__ci_expr_old_", target_name, "rvalue_sequencing")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "((unsafe: *__local_p) = __local_c)", target_name, "rvalue_sequencing")
    if rc != 0: return rc
    let check_result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-rvalue-sequencing", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check_result.rc != 0: return if check_result.rc == 0: 1 else: check_result.rc
    let run_result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "run-rvalue-sequencing", bgs_argv_append(bgs_argv_append("", "run"), out_w))
    if run_result.rc != 0: return if run_result.rc == 0: 1 else: run_result.rc
    0

fn bgs_check_migrate_directory_progress(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src_dir = bgs_resolve_join(case_dir, "src")
    let out_dir = bgs_resolve_join(case_dir, "out")
    var rc = bgs_write_fixture(bgs_resolve_join(src_dir, "a.c"), "int a_value(void) { return 1; }\n", target_name, "directory progress a")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(src_dir, "b.c"), "int b_value(void) { return 2; }\n", target_name, "directory progress b")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src_dir)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_dir)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-directory-progress", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    rc = bgs_migrate_assert_contains(result.stdout, "migrate: processing a.c - 1/2, 50% completed", target_name, "directory_progress_stdout")
    if rc != 0: return rc
    bgs_migrate_assert_contains(result.stdout, "migrate: processing b.c - 2/2, 100% completed", target_name, "directory_progress_stdout")

fn bgs_check_migrate_cross_file_global_owner_arrays(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let generated_dir = bgs_resolve_join(case_dir, "generated")
    var rc = bgs_write_fixture(bgs_resolve_join(case_dir, "tables.h"), "extern const unsigned char issue121_table[];\nint issue121_value(int idx);\nint issue121_sum(void);\n", target_name, "cross file table header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "owner.c"), "#include \"tables.h\"\n\nconst unsigned char issue121_table[] = {7, 9, 11};\n\nint issue121_value(int idx) {\n  return issue121_table[idx];\n}\n", target_name, "cross file owner")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "user.c"), "#include \"tables.h\"\n\nint issue121_sum(void) {\n  return issue121_table[2] + issue121_value(1);\n}\n", target_name, "cross file user")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, case_dir)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, generated_dir)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-cross-file-global-owner-arrays", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let owner_w = bgs_resolve_join(generated_dir, "owner.w")
    let user_w = bgs_resolve_join(generated_dir, "user.w")
    rc = bgs_migrate_file_contains(owner_w, "let issue121_table: [3]u8", target_name, "cross_file_global_owner_arrays owner")
    if rc != 0: return rc
    rc = bgs_migrate_file_contains(user_w, "extern let issue121_table: [3]u8", target_name, "cross_file_global_owner_arrays user")
    if rc != 0: return rc
    rc = bgs_migrate_file_forbids(owner_w, "issue121_table: *", target_name, "cross_file_global_owner_arrays owner")
    if rc != 0: return rc
    rc = bgs_migrate_file_forbids(user_w, "issue121_table: *", target_name, "cross_file_global_owner_arrays user")
    if rc != 0: return rc
    let owner_check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-cross-file-owner", bgs_argv_append(bgs_argv_append("", "check"), owner_w))
    if owner_check.rc != 0: return if owner_check.rc == 0: 1 else: owner_check.rc
    let user_check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-cross-file-user", bgs_argv_append(bgs_argv_append("", "check"), user_w))
    if user_check.rc != 0: return if user_check.rc == 0: 1 else: user_check.rc
    var owner_build_argv = ""
    owner_build_argv = bgs_argv_append(owner_build_argv, "build")
    owner_build_argv = bgs_argv_append(owner_build_argv, owner_w)
    owner_build_argv = bgs_argv_append(owner_build_argv, "--emit-obj")
    owner_build_argv = bgs_argv_append(owner_build_argv, "-o")
    owner_build_argv = bgs_argv_append(owner_build_argv, bgs_resolve_join(generated_dir, "owner.o"))
    let owner_build = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "build-cross-file-owner", owner_build_argv)
    if owner_build.rc != 0: return if owner_build.rc == 0: 1 else: owner_build.rc
    var user_build_argv = ""
    user_build_argv = bgs_argv_append(user_build_argv, "build")
    user_build_argv = bgs_argv_append(user_build_argv, user_w)
    user_build_argv = bgs_argv_append(user_build_argv, "--emit-obj")
    user_build_argv = bgs_argv_append(user_build_argv, "-o")
    user_build_argv = bgs_argv_append(user_build_argv, bgs_resolve_join(generated_dir, "user.o"))
    let user_build = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "build-cross-file-user", user_build_argv)
    if user_build.rc != 0: return if user_build.rc == 0: 1 else: user_build.rc
    0

fn bgs_check_migrate_shared_defs_ownerless_extern(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let generated_dir = bgs_resolve_join(case_dir, "generated")
    var rc = bgs_write_fixture(bgs_resolve_join(case_dir, "tables.h"), "extern const unsigned char issue140_unused_external[];\nextern const unsigned char issue140_owned_table[];\nint issue140_read_owned(void);\n", target_name, "shared defs table header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "owner.c"), "#include \"tables.h\"\n\nconst unsigned char issue140_owned_table[] = {3, 5, 8};\n\nint issue140_read_owned(void) {\n  return issue140_owned_table[1];\n}\n", target_name, "shared defs owner")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, case_dir)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--shared-defs")
    argv = bgs_argv_append(argv, "defs")
    argv = bgs_argv_append(argv, "-I")
    argv = bgs_argv_append(argv, case_dir)
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, generated_dir)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-shared-defs-ownerless-extern", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let defs_w = bgs_resolve_join(generated_dir, "defs.w")
    let defs_text = with_fs_read_file(defs_w)
    rc = bgs_migrate_assert_contains(defs_text, "let issue140_owned_table:", target_name, "shared_defs_ownerless_extern")
    if rc != 0: return rc
    rc = bgs_migrate_assert_not_contains(defs_text, "issue140_unused_external", target_name, "shared_defs_ownerless_extern")
    if rc != 0: return rc
    if bgs_count_occurrences(defs_text, "fn string_find_char(") != 1:
        bgs_migrate_error(target_name, "shared_defs_ownerless_extern emitted duplicate or missing string_find_char helper")
        return 1
    0

pub fn run_cli_selfhost_migrate_basic_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_migrate_global_init_list(root, target_name, compiler_path, bgs_resolve_join(base_dir, "global_init_list"))
    if rc != 0: return rc
    rc = bgs_check_migrate_host_header_compat(root, target_name, compiler_path, bgs_resolve_join(base_dir, "host_header_compat"))
    if rc != 0: return rc
    rc = bgs_check_migrate_assignment_compat(root, target_name, compiler_path, bgs_resolve_join(base_dir, "assignment_compat"))
    if rc != 0: return rc
    rc = bgs_check_migrate_rvalue_sequencing(root, target_name, compiler_path, bgs_resolve_join(base_dir, "rvalue_sequencing"))
    if rc != 0: return rc
    rc = bgs_check_migrate_directory_progress(root, target_name, compiler_path, bgs_resolve_join(base_dir, "directory_progress"))
    if rc != 0: return rc
    rc = bgs_check_migrate_cross_file_global_owner_arrays(root, target_name, compiler_path, bgs_resolve_join(base_dir, "cross_file_global_owner_arrays"))
    if rc != 0: return rc
    bgs_check_migrate_shared_defs_ownerless_extern(root, target_name, compiler_path, bgs_resolve_join(base_dir, "shared_defs_ownerless_extern"))

fn bgs_check_migrate_libc_ctype(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "libc_ctype.c")
    let out_w = bgs_resolve_join(case_dir, "libc_ctype.w")
    let c_text = "#include <ctype.h>\n\nint classify(int c) {\n  return isalpha(c) + isdigit(c) + isalnum(c) + isspace(c) +\n    isupper(c) + islower(c) + isxdigit(c) + isprint(c) +\n    isgraph(c) + ispunct(c) + iscntrl(c) + tolower(c) + toupper(c);\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "libc ctype source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-libc-ctype", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    let required: Vec[str] = Vec.new()
    required.push("extern fn isalpha(c: i32) -> i32")
    required.push("extern fn tolower(c: i32) -> i32")
    required.push("isalpha(__param_c)")
    required.push("isalnum(__param_c)")
    required.push("isgraph(__param_c)")
    required.push("tolower(__param_c)")
    for i in 0..required.len() as i32:
        rc = bgs_migrate_assert_contains(out_text, required.get(i as i64), target_name, "libc_ctype_calls")
        if rc != 0: return rc
    let forbidden: Vec[str] = Vec.new()
    forbidden.push("is_alpha(__param_c)")
    forbidden.push("is_alnum(__param_c)")
    forbidden.push("to_lower(__param_c)")
    for i in 0..forbidden.len() as i32:
        rc = bgs_migrate_assert_not_contains(out_text, forbidden.get(i as i64), target_name, "libc_ctype_calls")
        if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-libc-ctype", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

fn bgs_check_migrate_macro_unsigned_minus(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "macro_initializer_unsigned_minus.c")
    let out_w = bgs_resolve_join(case_dir, "macro_initializer_unsigned_minus.w")
    let c_text = "typedef unsigned long size_t;\n\n#define MY_SIZE_MAX ((size_t)-1)\n#define COPY_ONE(dst_, src_, length_) do { size_t chkmc_length = length_; if (chkmc_length > 0) { (dst_)[0] = (src_)[0]; } } while (0)\n\nint too_large(size_t current, size_t need) {\n  return current > (MY_SIZE_MAX - need) / 2;\n}\n\nint repeat_too_large(size_t replen, size_t need, int count) {\n  return count > 0 && replen > (MY_SIZE_MAX - need) / count;\n}\n\nint copy_after_goto(char *dst, const char *src, int flag) {\n  if (flag) goto copy;\n  return 0;\ncopy:\n  COPY_ONE(dst, src, 3);\n  return (int)dst[0];\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "macro unsigned source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-macro-unsigned-minus", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    if with_str_contains(out_text, "(-1 as ") == 0 and with_str_contains(out_text, "(0 as ") == 0:
        bgs_migrate_error(target_name, "macro_initializer_unsigned_minus missing typed unsigned -1")
        return 1
    rc = bgs_migrate_assert_not_contains(out_text, "((0 -% 1)", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "/ (__param_count as ", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "__local_chkmc_length", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "= 3)", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-macro-unsigned-minus", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

fn bgs_check_migrate_tentative_global_owner(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "tentative_global_owner.c")
    let out_w = bgs_resolve_join(case_dir, "tentative_global_owner.w")
    var rc = bgs_write_fixture(src, "typedef struct ctx { int x; } ctx;\nctx g;\nint issue127_read(void) { return g.x; }\n", target_name, "tentative global owner")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-tentative-global-owner", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    rc = bgs_migrate_file_contains(out_w, "var g: ctx", target_name, "tentative_global_owner")
    if rc != 0: return rc
    rc = bgs_migrate_file_forbids(out_w, "extern var g: ctx", target_name, "tentative_global_owner")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-tentative-global-owner", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

fn bgs_check_migrate_cross_file_tentative_global_owner(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let generated_dir = bgs_resolve_join(case_dir, "generated")
    var rc = bgs_write_fixture(bgs_resolve_join(case_dir, "a.c"), "int issue127_counter;\nint issue127_get(void) { return issue127_counter; }\n", target_name, "cross tentative a")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "b.c"), "int issue127_counter;\nint issue127_bump(void) {\n  issue127_counter = issue127_counter + 1;\n  return issue127_counter;\n}\n", target_name, "cross tentative b")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, case_dir)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, generated_dir)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-cross-file-tentative", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let a_w = bgs_resolve_join(generated_dir, "a.w")
    let b_w = bgs_resolve_join(generated_dir, "b.w")
    rc = bgs_migrate_file_contains(a_w, "var issue127_counter: c_int", target_name, "cross_file_tentative_global_owner")
    if rc != 0: return rc
    rc = bgs_migrate_file_contains(b_w, "extern var issue127_counter: c_int", target_name, "cross_file_tentative_global_owner")
    if rc != 0: return rc
    let check_a = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-cross-file-tentative-a", bgs_argv_append(bgs_argv_append("", "check"), a_w))
    if check_a.rc != 0: return if check_a.rc == 0: 1 else: check_a.rc
    let check_b = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-cross-file-tentative-b", bgs_argv_append(bgs_argv_append("", "check"), b_w))
    if check_b.rc != 0: return if check_b.rc == 0: 1 else: check_b.rc
    0

fn bgs_check_migrate_noop_pointer_casts(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "noop_pointer_cast_exprs.c")
    let out_w = bgs_resolve_join(case_dir, "noop_pointer_cast_exprs.w")
    let c_text = "typedef struct ctx { int x; } ctx;\nctx g;\n\nctx *ret_ctx(void) { return (ctx *)(&g); }\n\nint f(ctx *ccontext) {\n  ctx *local = (ctx *)(&g);\n  ccontext = (ctx *)(&g);\n  return local->x + ccontext->x;\n}\n\nstatic void callback(void *p) { (void)p; }\n\ntypedef void (*callback_fn)(void *);\n\ncallback_fn ret_callback(void) { return &callback; }\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "noop pointer casts")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-noop-pointer-casts", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    let required: Vec[str] = Vec.new()
    required.push("fn ret_ctx() -> *mut ctx:")
    required.push("return ((&raw mut g as *mut ctx))")
    required.push("var __local_local: *mut ctx = ((&raw mut g as *mut ctx))")
    required.push("(&raw mut g as *mut ctx)")
    required.push("return callback")
    for i in 0..required.len() as i32:
        rc = bgs_migrate_assert_contains(out_text, required.get(i as i64), target_name, "noop_pointer_cast_exprs")
        if rc != 0: return rc
    let forbidden: Vec[str] = Vec.new()
    forbidden.push("extern fn ret_ctx()")
    forbidden.push("as *mut ctx)) as *mut ctx")
    forbidden.push("&raw const callback")
    for i in 0..forbidden.len() as i32:
        rc = bgs_migrate_assert_not_contains(out_text, forbidden.get(i as i64), target_name, "noop_pointer_cast_exprs")
        if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-noop-pointer-casts", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

fn bgs_check_migrate_raw_pointer_index(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "raw_pointer_index_unsafe.c")
    let out_w = bgs_resolve_join(case_dir, "raw_pointer_index_unsafe.w")
    var rc = bgs_write_fixture(src, "int issue146_ptr_ops(int *p, int *q) {\n  int *r = p + 1;\n  int d = (int)(q - p);\n  r[0] = r[0] + d;\n  return p[1];\n}\n", target_name, "raw pointer index")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-raw-pointer-index", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_migrate_assert_contains(out_text, "__param_p +", target_name, "raw_pointer_index_unsafe")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(unsafe: __local_r[0])", target_name, "raw_pointer_index_unsafe")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(unsafe: __param_p[1])", target_name, "raw_pointer_index_unsafe")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-raw-pointer-index", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

fn bgs_check_migrate_prefer_brace_ws(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "prefer_brace_ws.c")
    let out_w = bgs_resolve_join(case_dir, "prefer_brace_ws.w")
    let c_text = "int prefer_brace_ws(int *p) {\n  while (*p != 0) {\n    if (*p < 3) {\n      p++;\n      continue;\n    }\n    p++;\n  }\n  return 0;\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "prefer brace source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-prefer-brace-ws", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_assert_not_matches(out_text, "(?m)[\\t ]$", target_name, "prefer_brace_ws trailing whitespace")
    if rc != 0: return rc
    rc = bgs_assert_matches(out_text, "(?m)^[\\t ]*while\\b[^\\n]*\\{[\\t ]*$", target_name, "prefer_brace_ws while brace")
    if rc != 0: return rc
    rc = bgs_assert_matches(out_text, "(?m)^[\\t ]*if\\b[^\\n]*\\{[\\t ]*$", target_name, "prefer_brace_ws if brace")
    if rc != 0: return rc
    rc = bgs_assert_not_matches(out_text, "(?m)^[\\t ]*(if|while)\\b[^\\n]*:[\\t ]*$", target_name, "prefer_brace_ws colon style")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-prefer-brace-ws", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

fn bgs_check_migrate_typed_cast_macros(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "typed_cast_macros.c")
    let out_w = bgs_resolve_join(case_dir, "typed_cast_macros.w")
    let c_text = "typedef unsigned long usize;\n#define ZERO_TERM ((usize)-1)\n\nint f(usize patlen) {\n  int zero_terminated = 0;\n  if ((zero_terminated = (patlen == ZERO_TERM)))\n    patlen = 7;\n  return zero_terminated + (int)patlen;\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "typed cast macros")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-typed-cast-macros", argv)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_migrate_assert_contains(out_text, "let ZERO_TERM: c_ulong = (-1 as c_ulong)", target_name, "typed_cast_macros")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "patlen == ((-1 as c_ulong))", target_name, "typed_cast_macros")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-typed-cast-macros", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return if check.rc == 0: 1 else: check.rc
    0

pub fn run_cli_selfhost_migrate_core_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_migrate_libc_ctype(root, target_name, compiler_path, bgs_resolve_join(base_dir, "libc_ctype"))
    if rc != 0: return rc
    rc = bgs_check_migrate_macro_unsigned_minus(root, target_name, compiler_path, bgs_resolve_join(base_dir, "macro_unsigned_minus"))
    if rc != 0: return rc
    rc = bgs_check_migrate_tentative_global_owner(root, target_name, compiler_path, bgs_resolve_join(base_dir, "tentative_global_owner"))
    if rc != 0: return rc
    rc = bgs_check_migrate_cross_file_tentative_global_owner(root, target_name, compiler_path, bgs_resolve_join(base_dir, "cross_file_tentative_global_owner"))
    if rc != 0: return rc
    rc = bgs_check_migrate_noop_pointer_casts(root, target_name, compiler_path, bgs_resolve_join(base_dir, "noop_pointer_casts"))
    if rc != 0: return rc
    rc = bgs_check_migrate_raw_pointer_index(root, target_name, compiler_path, bgs_resolve_join(base_dir, "raw_pointer_index"))
    if rc != 0: return rc
    rc = bgs_check_migrate_prefer_brace_ws(root, target_name, compiler_path, bgs_resolve_join(base_dir, "prefer_brace_ws"))
    if rc != 0: return rc
    bgs_check_migrate_typed_cast_macros(root, target_name, compiler_path, bgs_resolve_join(base_dir, "typed_cast_macros"))

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
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Executable, \"custom-build\", \"src/custom.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    target = target.link_system_lib(\"m\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Test, \"configured-test\", \"src/build_test.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "test build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Test, \"glob-tests\", \"tests/*.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "glob build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Library, \"configured\", \"src/lib.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "library build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(host_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(ctx: BuildCtx) -> Build:\n    var host = BuildTarget.native\n    if os() == \"Macos\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.darwin_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.darwin_x86_64\n    else if os() == \"Linux\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.linux_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.linux_x86_64\n    else if os() == \"Windows\":\n        if arch() == \"x86_64\":\n            host = BuildTarget.windows_x86_64\n    var target = target_new(.Executable, \"host-target\", \"src/main.w\")\n    target = target.target(host)\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "host build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(non_native_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(ctx: BuildCtx) -> Build:\n    var non_native = BuildTarget.linux_x86_64\n    if os() == \"Linux\" and arch() == \"x86_64\":\n        non_native = BuildTarget.darwin_aarch64\n    var target = target_new(.Executable, \"wrong-target\", \"src/main.w\")\n    target = target.target(non_native)\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "non-native build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(gen_dir, "templates/generated_main.w"), "fn main:\n    print(\"generated source\")\n", target_name, "generated template")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(gen_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    let emitter = ctx.source_emitter()\n    let source = emitter.generated_source(\"out/gen/generated_main.w\", fs.read_text(\"templates/generated_main.w\"))\n    var generated = ctx.new_build()\n    generated = generated.add_generated_source(source)\n    generated.executable(\"generated-app\", \"out/gen/generated_main.w\")\n", target_name, "generated build.w")
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
    rc = bgs_write_fixture(bgs_resolve_join(invalid_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var generated = ctx.new_build()\n    generated = generated.generated_source(\"../outside.w\", \"fn main: print(\\\"bad\\\")\\n\")\n    generated.executable(\"invalid-generated\", \"src/main.w\")\n", target_name, "invalid generated build.w")
    if rc != 0: return rc
    let invalid_result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-invalid-generated-source", bgs_argv_append("", "build"), 120000, invalid_dir)
    if invalid_result.rc == 0:
        with_eprint("error: build_w_invalid_generated_source unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(invalid_result.stderr, "invalid build.w generated source path", target_name, "build_w_invalid_generated_source")
    if rc != 0: return rc

    let toolfs_ok_dir = bgs_resolve_join(base_dir, "toolfs_ok")
    rc = bgs_write_project_manifest(toolfs_ok_dir, "buildwtoolfsok", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_ok_dir, "src/main.w"), "fn main:\n    print(\"toolfs ok\")\n", target_name, "toolfs ok source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_ok_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    assert(fs.mkdir_all(\"out/toolfs\") == 0)\n    assert(fs.write_text(\"out/toolfs/value.txt\", \"inside\") == 0)\n    assert(fs.read_text(\"out/toolfs/value.txt\") == \"inside\")\n    ctx.new_build().executable(\"toolfs-ok\", \"src/main.w\")\n", target_name, "toolfs ok build.w")
    if rc != 0: return rc
    let toolfs_ok = bgs_build_expect_success(root, target_name, compiler_path, toolfs_ok_dir, "build-w-toolfs-ok", bgs_argv_append("", "build"))
    if toolfs_ok.rc != 0: return if toolfs_ok.rc == 0: 1 else: toolfs_ok.rc
    if with_fs_file_exists(bgs_resolve_join(toolfs_ok_dir, "out/toolfs/value.txt")) == 0:
        with_eprint("error: build_w_toolfs_ok missing sandboxed ToolFs output")
        return 1

    let toolfs_escape_dir = bgs_resolve_join(base_dir, "toolfs_escape")
    rc = bgs_write_project_manifest(toolfs_escape_dir, "buildwtoolfsescape", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_escape_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", target_name, "toolfs escape source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_escape_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let _ = ctx.fs().read_text(\"../outside.txt\")\n    ctx.new_build().executable(\"toolfs-escape\", \"src/main.w\")\n", target_name, "toolfs escape build.w")
    if rc != 0: return rc
    let toolfs_escape = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-toolfs-escape", bgs_argv_append("", "build"), 120000, toolfs_escape_dir)
    if toolfs_escape.rc == 0:
        with_eprint("error: build_w_toolfs_escape unexpectedly succeeded")
        return 1
    bgs_assert_contains(toolfs_escape.stderr, "ToolFs path escapes project root", target_name, "build_w_toolfs_escape")

fn bgs_graph_build_file() -> str:
    "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var out = ctx.new_build().executable(\"one\", \"src/one.w\")\n    out = out.executable(\"two\", \"src/two.w\")\n    out = out.generated_source(\"out/tmp/a.txt\", \"same\")\n    out = out.generated_source(\"out/tmp/b.txt\", \"same\")\n    out = out.binary_compare(\"bytes-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n    out = out.fixpoint_compare(\"fix-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n    var rsp = target_new(.GenerateResponseFile, \"rsp\", \"\").output(\"out/tmp/args.rsp\")\n    rsp = rsp.arg(\"-L/some path\")\n    rsp = rsp.arg(\"plain\")\n    out = out.add_target(rsp)\n    out = out.compile_c_object(\"helper-o\", \"runtime/helper.c\", \"out/lib/helper.o\")\n    var archive = target_new(.CreateStaticArchive, \"helper-a\", \"\").output(\"out/lib/libhelper.a\")\n    archive = archive.input(\"out/lib/helper.o\")\n    out = out.add_target(archive)\n    var embedded = target_new(.EmbedObjectFiles, \"embed-helper\", \"\").output(\"out/lib/embedded_helper.s\")\n    embedded = embedded.input(\"out/lib/helper.o\")\n    embedded = embedded.arg(\"helper_o\")\n    out = out.add_target(embedded)\n    out = out.compile_asm_object(\"embedded-helper-o\", \"out/lib/embedded_helper.s\", \"out/lib/embedded_helper.o\")\n    var copy_target = target_new(.CopyTree, \"runtime-copy\", \"runtime\").output(\"out/runtime\")\n    copy_target = copy_target.input(\"helper.c\")\n    out = out.add_target(copy_target)\n    var promote = target_new(.PromoteTreeIfVerified, \"promote-runtime\", \"out/runtime\").output(\"promoted-runtime\")\n    promote = promote.input(\"helper.c\")\n    promote = promote.dep(\"runtime-copy\")\n    out = out.add_target(promote)\n    var corpus = target_new(.RunCorpusTest, \"corpus\", \"out/bin/two\")\n    corpus = corpus.dep(\"two\")\n    out = out.add_target(corpus)\n    var command = target_new(.Command, \"run-two\", \"out/bin/two\")\n    command = command.dep(\"two\")\n    out = out.add_target(command)\n    var install = target_new(.Install, \"install-two\", \"out/bin/two\").output(\"out/install/two\")\n    install = install.dep(\"two\")\n    install = install.arg(\"0755\")\n    out = out.add_target(install)\n    var aggregate = target_new(.Group, \"toolchain\", \"\")\n    aggregate = aggregate.dep(\"bytes-same\")\n    aggregate = aggregate.dep(\"fix-same\")\n    aggregate = aggregate.dep(\"rsp\")\n    aggregate = aggregate.dep(\"helper-a\")\n    aggregate = aggregate.dep(\"embedded-helper-o\")\n    aggregate = aggregate.dep(\"promote-runtime\")\n    aggregate = aggregate.dep(\"corpus\")\n    aggregate = aggregate.dep(\"run-two\")\n    aggregate = aggregate.dep(\"install-two\")\n    out = out.add_target(aggregate)\n    out.default(\"toolchain\")\n"

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
