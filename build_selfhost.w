module build_selfhost

use std.build

type SelfhostRunResult {
    rc: i32,
    stdout: str,
    stderr: str,
}

fn bs_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn bs_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn bs_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn bs_basename(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    path.slice((last_slash + 1) as i64, path.len())

fn bs_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    bs_join(root, path)

fn bs_capture_path(root: str, output_dir: str, label: str, suffix: str) -> str:
    bs_abs(root, bs_join(output_dir, label ++ "." ++ suffix))

fn bs_run_cli_capture(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str], timeout_ms: i32) -> SelfhostRunResult:
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let stdout_path = bs_capture_path(root, output_dir, label, "stdout")
    let stderr_path = bs_capture_path(root, output_dir, label, "stderr")
    var argv: Vec[str] = Vec.new()
    argv |> push(compiler_path)
    for i in 0..args.len() as i32:
        argv |> push(args.get(i as i64))
    let result = ctx.process_runner().run_capture(argv, stdout_path, stderr_path, timeout_ms)
    if result.rc == 0:
        let _remove_stdout = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stdout"))
        let _remove_stderr = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stderr"))
    SelfhostRunResult { result.rc, result.stdout, result.stderr }

fn bs_run_cli_capture_input(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str], stdin_text: str, timeout_ms: i32) -> SelfhostRunResult:
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let stdin_rel = bs_join(output_dir, label ++ ".stdin")
    let stdout_path = bs_capture_path(root, output_dir, label, "stdout")
    let stderr_path = bs_capture_path(root, output_dir, label, "stderr")
    let stdin_path = bs_abs(root, stdin_rel)
    if ctx.fs().write_text(stdin_rel, stdin_text) != 0:
        return SelfhostRunResult { 1, "", "could not write stdin fixture: " ++ stdin_rel }
    var argv: Vec[str] = Vec.new()
    argv |> push(compiler_path)
    for i in 0..args.len() as i32:
        argv |> push(args.get(i as i64))
    let result = ctx.process_runner().run_capture_input(argv, stdout_path, stderr_path, timeout_ms, stdin_path)
    if result.rc == 0:
        let _remove_stdin = ctx.fs().remove_file(stdin_rel)
        let _remove_stdout = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stdout"))
        let _remove_stderr = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stderr"))
    SelfhostRunResult { result.rc, result.stdout, result.stderr }

fn bs_run_cli_capture_cwd(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str], timeout_ms: i32, cwd: str) -> SelfhostRunResult:
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let stdout_path = bs_capture_path(root, output_dir, label, "stdout")
    let stderr_path = bs_capture_path(root, output_dir, label, "stderr")
    var argv: Vec[str] = Vec.new()
    argv |> push(compiler_path)
    for i in 0..args.len() as i32:
        argv |> push(args.get(i as i64))
    let result = ctx.process_runner().run_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, bs_abs(root, cwd))
    if result.rc == 0:
        let _remove_stdout = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stdout"))
        let _remove_stderr = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stderr"))
    SelfhostRunResult { result.rc, result.stdout, result.stderr }

fn bs_run_cli_expect_success(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture(ctx, compiler_path, label, args, 120000)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": cli selfhost command '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bs_trim_trailing_line_endings(text: str) -> str:
    var end = text.len()
    while end > 0:
        let ch = text.byte_at(end - 1)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end)

fn bs_assert_stdout_exact(ctx: ActionCtx, result: SelfhostRunResult, expected: str, label: str) -> i32:
    let actual = bs_trim_trailing_line_endings(result.stdout)
    if actual == expected:
        return 0
    bs_fail(ctx, "stdout mismatch for " ++ label ++ ": expected '" ++ expected ++ "' got '" ++ actual ++ "'")

fn bs_expect_cli_success_exact(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str], expected: str) -> i32:
    let result = bs_run_cli_capture(ctx, compiler_path, label, args, 120000)
    if result.rc != 0:
        return bs_fail(ctx, "one-liner '" ++ label ++ f"' failed with exit code {result.rc}")
    bs_assert_stdout_exact(ctx, result, expected, label)

fn bs_expect_cli_input_success_exact(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str], stdin_text: str, expected: str) -> i32:
    let result = bs_run_cli_capture_input(ctx, compiler_path, label, args, stdin_text, 120000)
    if result.rc != 0:
        return bs_fail(ctx, "one-liner '" ++ label ++ f"' failed with exit code {result.rc}")
    bs_assert_stdout_exact(ctx, result, expected, label)

fn bs_assert_contains(ctx: ActionCtx, text: str, needle: str, label: str) -> i32:
    if text.contains(needle):
        return 0
    bs_fail(ctx, "missing expected output for " ++ label ++ ": " ++ needle)

fn bs_assert_not_contains(ctx: ActionCtx, text: str, needle: str, label: str) -> i32:
    if not text.contains(needle):
        return 0
    bs_fail(ctx, "found forbidden output for " ++ label ++ ": " ++ needle)

fn bs_check_help(ctx: ActionCtx, compiler_path: str) -> i32:
    var args: Vec[str] = Vec.new()
    args |> push("--help")
    let result = bs_run_cli_expect_success(ctx, compiler_path, "help", args)
    if result.rc != 0:
        return if result.rc == 0: 1 else: result.rc

    let checks: Vec[str] = Vec.new()
    checks |> push("Usage: with [command] [options]")
    checks |> push("  lsp              Start the language server")
    checks |> push("  -e <code>        Compile and run code as top-level statements")
    for i in 0..checks.len() as i32:
        let rc = bs_assert_contains(ctx, result.stdout, checks.get(i as i64), "top_level_help")
        if rc != 0:
            return rc

    let forbid_reference = bs_assert_not_contains(ctx, result.stdout, "Language quick reference:", "top_level_help")
    if forbid_reference != 0:
        return forbid_reference
    let forbid_help_use = bs_assert_not_contains(ctx, result.stdout, "with help use", "top_level_help")
    if forbid_help_use != 0:
        return forbid_help_use
    bs_assert_not_contains(ctx, result.stdout, "--prefer-curly", "top_level_help")

fn bs_test_args(source_path: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args |> push("test")
    args |> push(source_path)
    args

fn bs_check_test_directives(ctx: ActionCtx, compiler_path: str, test_dir: str) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all(test_dir) != 0:
        return bs_fail(ctx, "could not create smoke test directory: " ++ test_dir)

    let good_src = bs_join(test_dir, "test_directives_good.w")
    if fs.write_text(good_src, "//! expect-exit: 134\n//! expect-stderr: panic: expected boom\n\nfn main:\n    assert(false, \"expected boom\")\n") != 0:
        return bs_fail(ctx, "could not write " ++ good_src)
    let good_result = bs_run_cli_expect_success(ctx, compiler_path, "test-directives-good", bs_test_args(good_src))
    if good_result.rc != 0:
        return if good_result.rc == 0: 1 else: good_result.rc

    let bad_stdout_src = bs_join(test_dir, "test_directives_bad_stdout.w")
    if fs.write_text(bad_stdout_src, "//! expect-stdout: missing\n\nfn main:\n    print(\"ok\")\n") != 0:
        return bs_fail(ctx, "could not write " ++ bad_stdout_src)
    let bad_stdout_result = bs_run_cli_capture(ctx, compiler_path, "test-directives-bad-stdout", bs_test_args(bad_stdout_src), 120000)
    if bad_stdout_result.rc == 0:
        return bs_fail(ctx, "expected stdout directive failure")
    let stdout_diag = bs_assert_contains(ctx, bad_stdout_result.stderr, "stdout mismatch; missing expected output: missing", "test_runtime_directives")
    if stdout_diag != 0:
        return stdout_diag

    let bad_exit_src = bs_join(test_dir, "test_directives_bad_exit.w")
    if fs.write_text(bad_exit_src, "//! expect-exit: 7\n\nfn main:\n    print(\"ok\")\n") != 0:
        return bs_fail(ctx, "could not write " ++ bad_exit_src)
    let bad_exit_result = bs_run_cli_capture(ctx, compiler_path, "test-directives-bad-exit", bs_test_args(bad_exit_src), 120000)
    if bad_exit_result.rc == 0:
        return bs_fail(ctx, "expected exit directive failure")
    bs_assert_contains(ctx, bad_exit_result.stderr, "exit code 0, expected 7", "test_runtime_directives")

pub fn run_cli_selfhost_smoke_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return bs_fail(ctx, "missing compiler input")

    let fs = ctx.fs()
    let output_dir = ctx.output()
    if output_dir.len() == 0:
        return bs_fail(ctx, "missing output directory")
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return bs_fail(ctx, "could not remove previous output directory: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return bs_fail(ctx, "could not create output directory: " ++ output_dir)

    let compiler_input = inputs.get(0)
    if not fs.exists(compiler_input):
        return bs_fail(ctx, "missing compiler: " ++ compiler_input)
    let compiler_path = bs_abs(ctx.project_info().project_root(), compiler_input)

    let help_rc = bs_check_help(ctx, compiler_path)
    if help_rc != 0:
        return help_rc

    let test_dir = bs_join(output_dir, "test-directives")
    bs_check_test_directives(ctx, compiler_path, test_dir)

fn bs_one_liner_args(first: str, second: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args |> push(first)
    args |> push(second)
    args

pub fn run_cli_selfhost_one_liner_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return bs_fail(ctx, "missing compiler input")

    let fs = ctx.fs()
    let output_dir = ctx.output()
    if output_dir.len() == 0:
        return bs_fail(ctx, "missing output directory")
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return bs_fail(ctx, "could not remove previous output directory: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return bs_fail(ctx, "could not create output directory: " ++ output_dir)

    let compiler_input = inputs.get(0)
    if not fs.exists(compiler_input):
        return bs_fail(ctx, "missing compiler: " ++ compiler_input)
    let compiler_path = bs_abs(ctx.project_info().project_root(), compiler_input)

    var rc = bs_expect_cli_success_exact(ctx, compiler_path, "one-liner-e", bs_one_liner_args("-e", "print(\"hello\")"), "hello")
    if rc != 0: return rc

    var args: Vec[str] = Vec.new()
    args |> push("-e")
    args |> push("var x = 0")
    args |> push("-e")
    args |> push("x = x + 2")
    args |> push("-e")
    args |> push("print(f\"{x}\")")
    rc = bs_expect_cli_success_exact(ctx, compiler_path, "one-liner-repeat-e", args, "2")
    if rc != 0: return rc

    rc = bs_expect_cli_success_exact(ctx, compiler_path, "one-liner-semicolon", bs_one_liner_args("-e", "var x = 0; x = x + 1; print(f\"{x}\")"), "1")
    if rc != 0: return rc

    rc = bs_expect_cli_success_exact(ctx, compiler_path, "one-liner-semicolon-string", bs_one_liner_args("-e", "print(\"a;b\")"), "a;b")
    if rc != 0: return rc

    args = Vec.new()
    args |> push("-e")
    args |> push("for a in args: print(a)")
    args |> push("--")
    args |> push("foo")
    args |> push("bar")
    rc = bs_expect_cli_success_exact(ctx, compiler_path, "one-liner-args", args, "foo\nbar")
    if rc != 0: return rc

    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "one-liner-n", bs_one_liner_args("-n", "print(f\"{nr}: {line}\")"), "a\nb\n", "1: a\n2: b")
    if rc != 0: return rc

    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "one-liner-p", bs_one_liner_args("-p", "line = line.upper()"), "a\r\nb\n", "A\nB")
    if rc != 0: return rc

    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "one-liner-regex-numbered", bs_one_liner_args("-n", "if line =~ /error (\\d+)/: print($1)"), "error 42\n", "42")
    if rc != 0: return rc

    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "one-liner-regex-named", bs_one_liner_args("-n", "if line =~ /email=(?<email>\\S+)/: print($email)"), "email=a@b\n", "a@b")
    if rc != 0: return rc

    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "one-liner-regex-fstring", bs_one_liner_args("-n", "if line =~ /(?<kind>error|warning) (\\d+)/: print(f\"{nr}: {$kind.upper()} code={$2}\")"), "error 42\nok\nwarning 7\n", "1: ERROR code=42\n3: WARNING code=7")
    if rc != 0: return rc

    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "one-liner-regex-escaped-named", bs_one_liner_args("-n", "if line =~ /^\\[(?<level>ERROR|WARN)\\]\\s+(?<msg>.*)$/: print(f\"{nr}: {$level} {$msg}\")"), "[INFO] boot\n[WARN] slow query\n[ERROR] db timeout\n", "2: WARN slow query\n3: ERROR db timeout")
    if rc != 0: return rc

    let implicit_src = bs_join(output_dir, "implicit_regex_fstring.w")
    let implicit_text =
        "use std.io\n" ++
        "use std.regex\n" ++
        "for line in stdin.lines():\n" ++
        "    if line =~ /(?<kind>error|warning) (\\d+)/:\n" ++
        "        print(f\"{$kind.upper()} code={$2}\")\n"
    if fs.write_text(implicit_src, implicit_text) != 0:
        return bs_fail(ctx, "could not write one-liner fixture source: " ++ implicit_src)
    rc = bs_expect_cli_input_success_exact(ctx, compiler_path, "implicit-main-regex-fstring", bs_one_liner_args("run", implicit_src), "error 42\nok\n", "ERROR code=42")
    if rc != 0: return rc

    args = Vec.new()
    args |> push("-e")
    args |> push("print(\"x\")")
    args |> push("-n")
    args |> push("print(line)")
    let mutual = bs_run_cli_capture(ctx, compiler_path, "one-liner-mutual-exclusion", args, 120000)
    if mutual.rc == 0:
        return bs_fail(ctx, "one-liner mutual exclusion unexpectedly succeeded")
    rc = bs_assert_contains(ctx, mutual.stderr, "mutually exclusive", "one_liners")
    if rc != 0: return rc

    let diag_e = bs_run_cli_capture(ctx, compiler_path, "one-liner-diag-e", bs_one_liner_args("-e", "let x = "), 120000)
    if diag_e.rc == 0:
        return bs_fail(ctx, "one-liner malformed -e unexpectedly succeeded")
    rc = bs_assert_contains(ctx, diag_e.stderr, "<cli -e #1>:1:9", "one_liners")
    if rc != 0: return rc

    let diag_n = bs_run_cli_capture_input(ctx, compiler_path, "one-liner-diag-n", bs_one_liner_args("-n", "if line =~ /x/: print($1)"), "x\n", 120000)
    if diag_n.rc == 0:
        return bs_fail(ctx, "one-liner malformed capture unexpectedly succeeded")
    rc = bs_assert_contains(ctx, diag_n.stderr, "<cli -n #1>:1:23", "one_liners")
    if rc != 0: return rc

    let diag_capture = bs_run_cli_capture_input(ctx, compiler_path, "one-liner-diag-fstring-capture", bs_one_liner_args("-n", "if line =~ /(?<kind>error|warning) (\\d+)/: print(f\"{kind}\")"), "error 42\n", 120000)
    if diag_capture.rc == 0:
        return bs_fail(ctx, "one-liner f-string capture diagnostic unexpectedly succeeded")
    rc = bs_assert_contains(ctx, diag_capture.stderr, "<cli -n #1>:1:", "one_liners")
    if rc != 0: return rc
    rc = bs_assert_not_contains(ctx, diag_capture.stderr, "use std.", "one_liners")
    if rc != 0: return rc
    bs_assert_not_contains(ctx, diag_capture.stderr, "one-liner compilation failed", "one_liners")

fn bs_project_args(command: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args |> push(command)
    args

fn bs_project_expect_success(ctx: ActionCtx, compiler_path: str, case_dir: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, label, args, 120000, case_dir)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": project selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bs_check_init_ai_docs(ctx: ActionCtx, project_dir: str, label: str) -> i32:
    let expected = ctx.fs().read_text("docs/with_for_ai.md")
    if expected.len() == 0:
        return bs_fail(ctx, "could not read docs/with_for_ai.md")
    let agents = ctx.fs().read_text(bs_join(project_dir, "AGENTS.md"))
    if agents != expected:
        return bs_fail(ctx, "AGENTS.md did not match docs/with_for_ai.md for " ++ label)
    let claude = ctx.fs().read_text(bs_join(project_dir, "CLAUDE.md"))
    if claude != expected:
        return bs_fail(ctx, "CLAUDE.md did not match docs/with_for_ai.md for " ++ label)
    0

fn bs_check_init_common_files(ctx: ActionCtx, project_dir: str, package_name: str, label: str) -> i32:
    var rc = bs_expect_file(ctx, bs_join(project_dir, "build.w"), label ++ " build")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(project_dir, "README.md"), label ++ " readme")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(project_dir, ".gitignore"), label ++ " gitignore")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(project_dir, "AGENTS.md"), label ++ " agents")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(project_dir, "CLAUDE.md"), label ++ " claude")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(project_dir, "tests/smoke.w"), label ++ " smoke test")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(project_dir, "with.toml"), "[package]", label ++ " manifest package section")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(project_dir, "build.w"), "out.default(\"" ++ package_name ++ "\")", label ++ " build default")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(project_dir, "README.md"), "# " ++ package_name, label ++ " readme title")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(project_dir, ".gitignore"), ".with/", label ++ " gitignore with cache")
    if rc != 0: return rc
    bs_check_init_ai_docs(ctx, project_dir, label)

fn bs_check_init_in_cwd(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    if ctx.fs().mkdir_all(case_dir) != 0:
        return bs_fail(ctx, "could not create init case directory: " ++ case_dir)
    let expected_name = bs_basename(case_dir)
    let result = bs_project_expect_success(ctx, compiler_path, case_dir, "init-in-cwd", bs_project_args("init"))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    var rc = bs_expect_file(ctx, bs_join(case_dir, "with.toml"), "init_in_cwd manifest")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(case_dir, "src/main.w"), "init_in_cwd main")
    if rc != 0: return rc
    rc = bs_check_init_common_files(ctx, case_dir, expected_name, "init_in_cwd")
    if rc != 0: return rc
    rc = bs_expect_absent(ctx, bs_join(bs_join(case_dir, expected_name), "with.toml"), "init_in_cwd nested manifest")
    if rc != 0: return rc
    rc = bs_expect_absent(ctx, bs_join(bs_join(bs_join(case_dir, expected_name), "src"), "main.w"), "init_in_cwd nested main")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(case_dir, "with.toml"), "name = \"" ++ expected_name ++ "\"", "init_in_cwd manifest name")
    if rc != 0: return rc
    bs_assert_contains(ctx, result.stderr, "created " ++ expected_name, "init_in_cwd stderr")

fn bs_check_init_named_dir(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    if ctx.fs().mkdir_all(case_dir) != 0:
        return bs_fail(ctx, "could not create init named case directory: " ++ case_dir)
    let project_name = "sqlite"
    var args: Vec[str] = Vec.new()
    args |> push("init")
    args |> push(project_name)
    let result = bs_project_expect_success(ctx, compiler_path, case_dir, "init-named-dir", args)
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    let project_dir = bs_join(case_dir, project_name)
    var rc = bs_expect_file(ctx, bs_join(project_dir, "with.toml"), "init_named_dir manifest")
    if rc != 0: return rc
    rc = bs_expect_file(ctx, bs_join(project_dir, "src/main.w"), "init_named_dir main")
    if rc != 0: return rc
    rc = bs_check_init_common_files(ctx, project_dir, project_name, "init_named_dir")
    if rc != 0: return rc
    rc = bs_expect_absent(ctx, bs_join(case_dir, "with.toml"), "init_named_dir root manifest")
    if rc != 0: return rc
    rc = bs_expect_absent(ctx, bs_join(case_dir, "src/main.w"), "init_named_dir root main")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(project_dir, "with.toml"), "name = \"" ++ project_name ++ "\"", "init_named_dir manifest name")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, result.stderr, "created " ++ project_name, "init_named_dir stderr")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, result.stderr, "  " ++ project_name ++ "/with.toml", "init_named_dir manifest path")
    if rc != 0: return rc
    bs_assert_contains(ctx, result.stderr, "  " ++ project_name ++ "/src/main.w", "init_named_dir main path")

fn bs_check_build_uses_package_section_name(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_project_manifest(ctx, case_dir, "pkgdemo")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(case_dir, "src/main.w"), "fn main:\n    print(\"ok\")\n", "package_section_name main")
    if rc != 0: return rc
    let result = bs_project_expect_success(ctx, compiler_path, case_dir, "package-section-name", bs_project_args("build"))
    if result.rc != 0: return if result.rc == 0: 1 else: result.rc
    bs_expect_file(ctx, bs_join(case_dir, "out/bin/pkgdemo"), "package_section_name output")

fn bs_check_build_rejects_imperative_manifest(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_fixture(ctx, bs_join(case_dir, "with.toml"), "[package]\nname = \"badmanifest\"\nversion = \"0.1.0\"\n\n[build]\ncommand = \"echo nope\"\n", "imperative manifest")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(case_dir, "src/main.w"), "fn main:\n    print(\"ok\")\n", "imperative main")
    if rc != 0: return rc
    let implicit = bs_run_cli_capture_cwd(ctx, compiler_path, "imperative-manifest", bs_project_args("build"), 120000, case_dir)
    if implicit.rc == 0:
        return bs_fail(ctx, "imperative manifest unexpectedly succeeded")
    rc = bs_assert_contains(ctx, implicit.stderr, "error: invalid with.toml: imperative build configuration belongs in build.w", "imperative manifest diagnostic")
    if rc != 0: return rc

    var explicit_args: Vec[str] = Vec.new()
    explicit_args |> push("build")
    explicit_args |> push(bs_abs(ctx.project_info().project_root(), bs_join(case_dir, "src/main.w")))
    let explicit = bs_run_cli_capture_cwd(ctx, compiler_path, "imperative-manifest-explicit-source", explicit_args, 120000, case_dir)
    if explicit.rc == 0:
        return bs_fail(ctx, "imperative manifest explicit source unexpectedly succeeded")
    bs_assert_contains(ctx, explicit.stderr, "error: invalid with.toml: imperative build configuration belongs in build.w", "imperative manifest explicit source diagnostic")

pub fn run_cli_selfhost_project_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return bs_fail(ctx, "missing compiler input")

    let fs = ctx.fs()
    let output_dir = ctx.output()
    if output_dir.len() == 0:
        return bs_fail(ctx, "missing output directory")
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return bs_fail(ctx, "could not remove previous output directory: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return bs_fail(ctx, "could not create output directory: " ++ output_dir)

    let compiler_input = inputs.get(0)
    if not fs.exists(compiler_input):
        return bs_fail(ctx, "missing compiler: " ++ compiler_input)
    let compiler_path = bs_abs(ctx.project_info().project_root(), compiler_input)

    var rc = bs_check_init_in_cwd(ctx, compiler_path, bs_join(output_dir, "init_in_cwd_case"))
    if rc != 0: return rc
    rc = bs_check_init_named_dir(ctx, compiler_path, bs_join(output_dir, "init_named_dir_case"))
    if rc != 0: return rc
    rc = bs_check_build_uses_package_section_name(ctx, compiler_path, bs_join(output_dir, "build_package_section_case"))
    if rc != 0: return rc
    bs_check_build_rejects_imperative_manifest(ctx, compiler_path, bs_join(output_dir, "build_imperative_manifest_case"))

fn bs_split_words(line: str) -> Vec[str]:
    let words: Vec[str] = Vec.new()
    var start = 0
    var in_word = false
    var i = 0
    while i <= line.len() as i32:
        let at_end = i == line.len() as i32
        let ch = if at_end: 32 else: line.byte_at(i as i64)
        let is_space = ch == 32 or ch == 9
        if at_end or is_space:
            if in_word:
                words.push(line.slice(start as i64, i as i64))
                in_word = false
            start = i + 1
        else if not in_word:
            start = i
            in_word = true
        i = i + 1
    words

fn bs_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    var i = 0
    while i <= text.len() as i32:
        let at_end = i == text.len() as i32
        if at_end or text.byte_at(i as i64) == 10:
            var end = i
            if end > start and text.byte_at((end - 1) as i64) == 13:
                end = end - 1
            if end > start:
                lines.push(text.slice(start as i64, end as i64))
            start = i + 1
        i = i + 1
    lines

fn bs_strip_mach_o_underscore(name: str) -> str:
    if name.len() > 0 and name.byte_at(0) == 95:
        return name.slice(1, name.len())
    name

fn bs_nm_symbol_name(line: str) -> str:
    let words = bs_split_words(line)
    if words.len() == 0:
        return ""
    bs_strip_mach_o_underscore(words.get(words.len() - 1))

fn bs_nm_symbol_type(line: str) -> str:
    let words = bs_split_words(line)
    if words.len() < 2:
        return ""
    words.get(words.len() - 2)

fn bs_nm_output(ctx: ActionCtx, nm_tool: str, obj_path: str, label: str) -> SelfhostRunResult:
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let stdout_rel = bs_join(output_dir, label ++ ".nm.stdout")
    let stderr_rel = bs_join(output_dir, label ++ ".nm.stderr")
    var argv: Vec[str] = Vec.new()
    argv |> push(nm_tool)
    argv |> push(bs_abs(root, obj_path))
    let result = ctx.process_runner().run_capture(argv, bs_abs(root, stdout_rel), bs_abs(root, stderr_rel), 120000)
    if result.rc == 0:
        let _remove_stdout = ctx.fs().remove_file(stdout_rel)
        let _remove_stderr = ctx.fs().remove_file(stderr_rel)
    SelfhostRunResult { result.rc, result.stdout, result.stderr }

fn bs_nm_has_symbol(nm_text: str, exact: str, suffix: str, prefix: str, type_required: str, type_forbidden: str) -> bool:
    let lines = bs_split_nonempty_lines(nm_text)
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        let name = bs_nm_symbol_name(line)
        if name.len() == 0:
            continue
        var matched = true
        if exact.len() > 0 and name != exact:
            matched = false
        if suffix.len() > 0 and not name.ends_with(suffix):
            matched = false
        if prefix.len() > 0 and not name.starts_with(prefix):
            matched = false
        if matched:
            let ty = bs_nm_symbol_type(line)
            if type_required.len() > 0 and ty != type_required:
                continue
            if type_forbidden.len() > 0 and ty == type_forbidden:
                continue
            return true
    false

fn bs_expect_nm_symbol(ctx: ActionCtx, nm_text: str, label: str, exact: str, suffix: str, prefix: str, required_type: str, forbidden_type: str) -> i32:
    if bs_nm_has_symbol(nm_text, exact, suffix, prefix, required_type, forbidden_type):
        return 0
    let want = if exact.len() > 0: exact else: prefix ++ "*" ++ suffix
    bs_fail(ctx, "missing expected symbol for " ++ label ++ ": " ++ want)

fn bs_expect_nm_forbid(ctx: ActionCtx, nm_text: str, label: str, exact: str, suffix: str, prefix: str) -> i32:
    if not bs_nm_has_symbol(nm_text, exact, suffix, prefix, "", ""):
        return 0
    let want = if exact.len() > 0: exact else: prefix ++ "*" ++ suffix
    bs_fail(ctx, "found forbidden symbol for " ++ label ++ ": " ++ want)

fn bs_write_fixture(ctx: ActionCtx, path: str, contents: str, label: str) -> i32:
    let dir = bs_dirname(path)
    if ctx.fs().mkdir_all(dir) != 0:
        return bs_fail(ctx, "could not create fixture directory for " ++ label ++ ": " ++ dir)
    if ctx.fs().write_text(path, contents) != 0:
        return bs_fail(ctx, "could not write fixture for " ++ label ++ ": " ++ path)
    0

fn bs_write_project_manifest(ctx: ActionCtx, case_dir: str, package_name: str) -> i32:
    bs_write_fixture(ctx, bs_join(case_dir, "with.toml"), "[package]\nname = \"" ++ package_name ++ "\"\nversion = \"0.1.0\"\n", package_name ++ " manifest")

fn bs_expect_file(ctx: ActionCtx, path: str, label: str) -> i32:
    if ctx.fs().exists(path):
        return 0
    bs_fail(ctx, "missing file for " ++ label ++ ": " ++ path)

fn bs_expect_absent(ctx: ActionCtx, path: str, label: str) -> i32:
    if not ctx.fs().exists(path):
        return 0
    bs_fail(ctx, "found unexpected file for " ++ label ++ ": " ++ path)

fn bs_expect_file_contains(ctx: ActionCtx, path: str, needle: str, label: str) -> i32:
    if not ctx.fs().exists(path):
        return bs_fail(ctx, "missing file for " ++ label ++ ": " ++ path)
    if ctx.fs().read_text(path).contains(needle):
        return 0
    bs_fail(ctx, "file mismatch for " ++ label ++ ": missing '" ++ needle ++ "' in " ++ path)

fn bs_build_emit_obj(ctx: ActionCtx, compiler_path: str, label: str, src_path: str, obj_path: str) -> i32:
    var args: Vec[str] = Vec.new()
    args |> push("build")
    args |> push(src_path)
    args |> push("--emit-obj")
    args |> push("-O0")
    args |> push("-o")
    args |> push(obj_path)
    let result = bs_run_cli_capture(ctx, compiler_path, label, args, 120000)
    if result.rc != 0:
        return bs_fail(ctx, f"failed to build object for {label} with exit code {result.rc}")
    0

fn bs_check_object_symbols(ctx: ActionCtx, compiler_path: str, nm_tool: str, case_dir: str) -> i32:
    let globals_src = bs_join(case_dir, "emit_obj_globals.w")
    let globals_obj = bs_join(case_dir, "emit_obj_globals.o")
    var rc = bs_write_fixture(ctx, globals_src, "var explicit_global: i32 = 42\nvar zero_global: i32\n", "emit_obj_globals")
    if rc != 0: return rc
    rc = bs_build_emit_obj(ctx, compiler_path, "emit-obj-globals-build", globals_src, globals_obj)
    if rc != 0: return rc
    let globals_nm = bs_nm_output(ctx, nm_tool, globals_obj, "emit-obj-globals")
    if globals_nm.rc != 0:
        return bs_fail(ctx, "nm failed for emit_obj_globals")
    rc = bs_expect_nm_symbol(ctx, globals_nm.stdout, "emit_obj_globals explicit_global", "", "explicit_global", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, globals_nm.stdout, "emit_obj_globals zero_global", "", "zero_global", "", "", "U")
    if rc != 0: return rc

    let shared_src = bs_join(case_dir, "shared.w")
    let user_src = bs_join(case_dir, "user.w")
    let shared_obj = bs_join(case_dir, "shared.o")
    let user_obj = bs_join(case_dir, "user.o")
    rc = bs_write_fixture(ctx, shared_src, "var shared_var: i32 = 42\nlet shared_let: i32 = 7\nfn shared_fn() -> i32: shared_var + shared_let\n", "emit_obj_import_owner")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, user_src, "use shared\n@[c_export(\"use_shared\")]\nfn use_shared() -> i32: shared_fn()\n@[c_export(\"shared_let_addr\")]\nfn shared_let_addr() -> *const i32: &shared_let\n@[c_export(\"shared_var_addr\")]\nfn shared_var_addr() -> *const i32: &shared_var\n", "emit_obj_import_user")
    if rc != 0: return rc
    rc = bs_build_emit_obj(ctx, compiler_path, "emit-obj-import-owner-build", shared_src, shared_obj)
    if rc != 0: return rc
    rc = bs_build_emit_obj(ctx, compiler_path, "emit-obj-import-user-build", user_src, user_obj)
    if rc != 0: return rc
    let shared_nm = bs_nm_output(ctx, nm_tool, shared_obj, "emit-obj-import-owner")
    if shared_nm.rc != 0: return if shared_nm.rc == 0: 1 else: shared_nm.rc
    rc = bs_expect_nm_symbol(ctx, shared_nm.stdout, "emit_obj_import_owner shared_var", "", "shared_var", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, shared_nm.stdout, "emit_obj_import_owner shared_let", "", "shared_let", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, shared_nm.stdout, "emit_obj_import_owner shared_fn", "", "shared_fn", "", "", "U")
    if rc != 0: return rc
    let user_nm = bs_nm_output(ctx, nm_tool, user_obj, "emit-obj-import-user")
    if user_nm.rc != 0: return if user_nm.rc == 0: 1 else: user_nm.rc
    rc = bs_expect_nm_symbol(ctx, user_nm.stdout, "emit_obj_import_user use_shared", "use_shared", "", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, user_nm.stdout, "emit_obj_import_user shared_let_addr", "shared_let_addr", "", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, user_nm.stdout, "emit_obj_import_user shared_var_addr", "shared_var_addr", "", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, user_nm.stdout, "emit_obj_import_user shared_var", "", "shared_var", "", "U", "")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, user_nm.stdout, "emit_obj_import_user shared_let", "", "shared_let", "", "U", "")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, user_nm.stdout, "emit_obj_import_user shared_fn", "", "shared_fn", "", "U", "")
    if rc != 0: return rc

    let wrapper_src = bs_join(case_dir, "wrapper.w")
    let redecl_user_src = bs_join(case_dir, "redecl_user.w")
    let redecl_obj = bs_join(case_dir, "redecl_user.o")
    rc = bs_write_fixture(ctx, shared_src, "fn shared_fn() -> i32: 1\n", "imported_fn_owner")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, wrapper_src, "extern fn shared_fn() -> i32\n", "imported_fn_wrapper")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, redecl_user_src, "use shared\nuse wrapper\n@[c_export(\"call_shared\")]\nfn call_shared() -> i32: shared_fn()\n", "imported_fn_user")
    if rc != 0: return rc
    rc = bs_build_emit_obj(ctx, compiler_path, "imported-fn-beats-extern-build", redecl_user_src, redecl_obj)
    if rc != 0: return rc
    let redecl_nm = bs_nm_output(ctx, nm_tool, redecl_obj, "imported-fn-beats-extern")
    if redecl_nm.rc != 0: return if redecl_nm.rc == 0: 1 else: redecl_nm.rc
    rc = bs_expect_nm_symbol(ctx, redecl_nm.stdout, "imported_fn_beats_extern call_shared", "call_shared", "", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, redecl_nm.stdout, "imported_fn_beats_extern shared_fn", "", "__shared_fn", "__with_mod_", "U", "")
    if rc != 0: return rc
    rc = bs_expect_nm_forbid(ctx, redecl_nm.stdout, "imported_fn_beats_extern raw shared_fn", "shared_fn", "", "")
    if rc != 0: return rc

    for pi in 0..2:
        let label = if pi == 0: "imported_pcre2_symbol" else: "imported_pcre2_symbol_multi_import"
        let pcre_src = bs_join(case_dir, label ++ ".w")
        let pcre_obj = bs_join(case_dir, label ++ ".o")
        let imports = if pi == 0:
            "use std.re.pcre2_compile\n"
        else:
            "use std.re.defs\nuse std.re.pcre2_compile\nuse std.re.pcre2_match\n"
        let pcre_text = imports ++ "\n@[c_export(\"call_compile\")]\nfn call_compile() -> *mut pcre2_real_code_8:\n    pcre2_compile_8((null as *const u8), 0, 0, (null as *mut c_int), (null as *mut c_ulong), (null as *mut pcre2_real_compile_context_8))\n"
        rc = bs_write_fixture(ctx, pcre_src, pcre_text, label)
        if rc != 0: return rc
        rc = bs_build_emit_obj(ctx, compiler_path, label ++ "-build", pcre_src, pcre_obj)
        if rc != 0: return rc
        let pcre_nm = bs_nm_output(ctx, nm_tool, pcre_obj, label)
        if pcre_nm.rc != 0: return if pcre_nm.rc == 0: 1 else: pcre_nm.rc
        rc = bs_expect_nm_symbol(ctx, pcre_nm.stdout, label ++ " call_compile", "call_compile", "", "", "", "U")
        if rc != 0: return rc
        rc = bs_expect_nm_symbol(ctx, pcre_nm.stdout, label ++ " module pcre2_compile_8", "", "__pcre2_compile_8", "__with_mod_", "U", "")
        if rc != 0: return rc
        rc = bs_expect_nm_forbid(ctx, pcre_nm.stdout, label ++ " raw pcre2_compile_8", "pcre2_compile_8", "", "")
        if rc != 0: return rc
    0

pub fn run_cli_selfhost_object_symbol_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return bs_fail(ctx, "missing compiler input")

    let fs = ctx.fs()
    let output_dir = ctx.output()
    if output_dir.len() == 0:
        return bs_fail(ctx, "missing output directory")
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return bs_fail(ctx, "could not remove previous output directory: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return bs_fail(ctx, "could not create output directory: " ++ output_dir)

    let compiler_input = inputs.get(0)
    if not fs.exists(compiler_input):
        return bs_fail(ctx, "missing compiler: " ++ compiler_input)
    let compiler_path = bs_abs(ctx.project_info().project_root(), compiler_input)

    let args = ctx.args()
    let nm_tool = if args.len() > 0: args.get(0) else: "nm"
    bs_check_object_symbols(ctx, compiler_path, nm_tool, bs_join(output_dir, "cases"))
