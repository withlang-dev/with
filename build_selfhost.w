module build_selfhost

use build_pcre2
use std.build
use std.process

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

fn bs_with_string_literal(value: str) -> str:
    var out = "\""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 34:
            out = out ++ "\\\""
        else if ch == 92:
            out = out ++ "\\\\"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out ++ "\""

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

fn bs_run_binary_capture(ctx: ActionCtx, exe_path: str, label: str, timeout_ms: i32) -> SelfhostRunResult:
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let stdout_path = bs_capture_path(root, output_dir, label, "stdout")
    let stderr_path = bs_capture_path(root, output_dir, label, "stderr")
    var argv: Vec[str] = Vec.new()
    argv |> push(bs_abs(root, exe_path))
    let result = ctx.process_runner().run_capture(argv, stdout_path, stderr_path, timeout_ms)
    if result.rc == 0:
        let _remove_stdout = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stdout"))
        let _remove_stderr = ctx.fs().remove_file(bs_join(output_dir, label ++ ".stderr"))
    SelfhostRunResult { result.rc, result.stdout, result.stderr }

pub fn run_embedded_runtime_regression_action(ctx: ActionCtx) -> i32:
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

    let copied_compiler = bs_join(output_dir, "with")
    if fs.copy_file(compiler_input, copied_compiler) != 0:
        return bs_fail(ctx, "could not copy compiler to embedded runtime fixture")
    if fs.chmod(copied_compiler, 0o755) != 0:
        return bs_fail(ctx, "could not make copied compiler executable")

    let source_path = bs_join(output_dir, "hello.w")
    if fs.write_text(source_path, "fn main:\n    print(\"hello\")\n") != 0:
        return bs_fail(ctx, "could not write embedded runtime fixture source")

    let root = ctx.project_info().project_root()
    let bin_path = bs_join(output_dir, "hello")
    let build_stdout = bs_join(output_dir, "build.stdout")
    let build_stderr = bs_join(output_dir, "build.stderr")
    var build_args: Vec[str] = Vec.new()
    build_args |> push(bs_abs(root, copied_compiler))
    build_args |> push("build")
    build_args |> push(bs_abs(root, source_path))
    build_args |> push("-o")
    build_args |> push(bs_abs(root, bin_path))

    let old_out_dir = env("WITH_OUT_DIR") ++ ""
    if set_env("WITH_OUT_DIR", bs_abs(root, bs_join(output_dir, "no-out"))) != 0:
        return bs_fail(ctx, "could not set WITH_OUT_DIR for embedded runtime test")
    let build_result = ctx.process_runner().run_capture(build_args, bs_abs(root, build_stdout), bs_abs(root, build_stderr), 300000)
    let _restore_out_dir = set_env("WITH_OUT_DIR", old_out_dir)
    if build_result.rc == 124:
        return bs_fail(ctx, "embedded runtime build timed out; stdout=" ++ build_stdout ++ " stderr=" ++ build_stderr)
    if build_result.rc != 0:
        return bs_fail(ctx, f"embedded runtime build failed with exit code {build_result.rc}; stdout=" ++ build_stdout ++ " stderr=" ++ build_stderr)

    let run_stdout = bs_join(output_dir, "run.stdout")
    let run_stderr = bs_join(output_dir, "run.stderr")
    var run_args: Vec[str] = Vec.new()
    run_args |> push(bs_abs(root, bin_path))
    let run_result = ctx.process_runner().run_capture(run_args, bs_abs(root, run_stdout), bs_abs(root, run_stderr), 60000)
    if run_result.rc == 124:
        return bs_fail(ctx, "embedded runtime output run timed out; stdout=" ++ run_stdout ++ " stderr=" ++ run_stderr)
    if run_result.rc != 0:
        return bs_fail(ctx, f"embedded runtime output run failed with exit code {run_result.rc}; stdout=" ++ run_stdout ++ " stderr=" ++ run_stderr)
    let output = bs_trim_trailing_line_endings(run_result.stdout)
    if output != "hello":
        return bs_fail(ctx, "embedded runtime output produced unexpected stdout: " ++ output)
    0

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
        return result.rc

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
    if fs.write_text(good_src, "//! expect-exit: 134\n//! expect-stderr: expected boom\n\nfn main:\n    assert(false, \"expected boom\")\n") != 0:
        return bs_fail(ctx, "could not write " ++ good_src)
    let good_result = bs_run_cli_expect_success(ctx, compiler_path, "test-directives-good", bs_test_args(good_src))
    if good_result.rc != 0:
        return good_result.rc

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
    if result.rc != 0: return result.rc
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
    if result.rc != 0: return result.rc
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
    if result.rc != 0: return result.rc
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

fn bs_edge_assert_exact(ctx: ActionCtx, actual: str, expected: str, label: str, stream_name: str) -> i32:
    if actual == expected:
        return 0
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ stream_name ++ " mismatch for " ++ label)
    ctx.diagnostics().error("expected: '" ++ expected ++ "'")
    ctx.diagnostics().error("actual: '" ++ actual ++ "'")
    1

fn bs_edge_expect_success(ctx: ActionCtx, compiler_path: str, case_dir: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, label, args, 120000, case_dir)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": edge selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bs_edge_build_obj_args(src: str, obj: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args |> push("build")
    args |> push(src)
    args |> push("--emit-obj")
    args |> push("-O0")
    args |> push("-o")
    args |> push(obj)
    args

fn bs_check_pointer_index_rejected(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "pointer_index_rejected.w")
    let obj = bs_join(case_dir, "pointer_index_rejected.o")
    var rc = bs_write_fixture(ctx, src, "fn main:\n    var arr: [4]i32 = [0 as i32; 4]\n    var p: *const i32 = null\n    let value = arr[p]\n    value\n", "pointer index source")
    if rc != 0: return rc
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, "pointer-index-rejected", bs_edge_build_obj_args(bs_abs(root, src), bs_abs(root, obj)), 120000, case_dir)
    if result.rc == 0:
        return bs_fail(ctx, "accepted pointer index expression")
    rc = bs_assert_contains(ctx, result.stderr, "index expression must be an integer", "pointer_index_rejected")
    if rc != 0: return rc
    bs_assert_not_contains(ctx, result.stderr, "LLVM verify error", "pointer_index_rejected")

fn bs_check_prelude_output_functions(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "prelude_output_functions.w")
    var rc = bs_write_fixture(ctx, src, "fn main:\n    write(\"A\")\n    print(\"B\")\n    write(\"C\")\n    ewrite(\"D\")\n    eprint(\"E\")\n    ewrite(\"F\")\n", "prelude output source")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("run")
    args |> push(bs_abs(root, src))
    let result = bs_edge_expect_success(ctx, compiler_path, case_dir, "prelude-output-functions", args)
    if result.rc != 0: return result.rc
    rc = bs_edge_assert_exact(ctx, result.stdout, "AB\nC", "prelude_output_functions", "stdout")
    if rc != 0: return rc
    bs_edge_assert_exact(ctx, result.stderr, "DE\nF", "prelude_output_functions", "stderr")

fn bs_check_build_options_cli(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "hello_build_options.w")
    var rc = bs_write_fixture(ctx, src, "fn main:\n    print(\"build-options\")\n", "build options source")
    if rc != 0: return rc

    let bin_path = bs_join(case_dir, "hello_build_options")
    var build_args: Vec[str] = Vec.new()
    build_args |> push("build")
    build_args |> push(bs_abs(root, src))
    build_args |> push("-O0")
    build_args |> push("-o")
    build_args |> push(bs_abs(root, bin_path))
    let built = bs_edge_expect_success(ctx, compiler_path, case_dir, "build-options-binary", build_args)
    if built.rc != 0: return built.rc
    if not ctx.fs().exists(bin_path):
        return bs_fail(ctx, "build options binary output missing: " ++ bin_path)
    let run_result = bs_run_binary_capture(ctx, bin_path, "build-options-binary-run", 120000)
    if run_result.rc != 0:
        return bs_fail(ctx, f"build options binary failed with exit code {run_result.rc}: " ++ run_result.stderr)
    rc = bs_edge_assert_exact(ctx, bs_trim_trailing_line_endings(run_result.stdout), "build-options", "build_options_binary", "stdout")
    if rc != 0: return rc

    let c_path = bs_join(case_dir, "hello_build_options.c")
    var emit_c_args: Vec[str] = Vec.new()
    emit_c_args |> push("build")
    emit_c_args |> push(bs_abs(root, src))
    emit_c_args |> push("--emit-c")
    emit_c_args |> push("-o")
    emit_c_args |> push(bs_abs(root, c_path))
    let emitted_c = bs_edge_expect_success(ctx, compiler_path, case_dir, "build-options-emit-c", emit_c_args)
    if emitted_c.rc != 0: return emitted_c.rc
    if not ctx.fs().exists(c_path):
        return bs_fail(ctx, "build options emit-c output missing: " ++ c_path)

    let obj_path = bs_join(case_dir, "hello_build_options.o")
    var emit_obj_args: Vec[str] = Vec.new()
    emit_obj_args |> push("build")
    emit_obj_args |> push(bs_abs(root, src))
    emit_obj_args |> push("--emit-obj")
    emit_obj_args |> push("-o")
    emit_obj_args |> push(bs_abs(root, obj_path))
    let emitted_obj = bs_edge_expect_success(ctx, compiler_path, case_dir, "build-options-emit-obj", emit_obj_args)
    if emitted_obj.rc != 0: return emitted_obj.rc
    if not ctx.fs().exists(obj_path):
        return bs_fail(ctx, "build options emit-obj output missing: " ++ obj_path)

    var release_args: Vec[str] = Vec.new()
    release_args |> push("build")
    release_args |> push(bs_abs(root, src))
    release_args |> push("--release")
    release_args |> push("-o")
    release_args |> push(bs_abs(root, bs_join(case_dir, "hello_build_options_release")))
    let release_build = bs_edge_expect_success(ctx, compiler_path, case_dir, "build-options-release", release_args)
    if release_build.rc != 0: return release_build.rc

    var conflict_args: Vec[str] = Vec.new()
    conflict_args |> push("build")
    conflict_args |> push(bs_abs(root, src))
    conflict_args |> push("--emit-c")
    conflict_args |> push("--emit-obj")
    let conflict = bs_run_cli_capture_cwd(ctx, compiler_path, "build-options-emit-conflict", conflict_args, 120000, case_dir)
    if conflict.rc == 0:
        return bs_fail(ctx, "build options emit conflict unexpectedly succeeded")
    rc = bs_assert_contains(ctx, conflict.stderr, "--emit-c and --emit-obj are mutually exclusive", "build_options_emit_conflict")
    if rc != 0: return rc

    var bad_prelude_args: Vec[str] = Vec.new()
    bad_prelude_args |> push("build")
    bad_prelude_args |> push(bs_abs(root, src))
    bad_prelude_args |> push("--prelude=bogus")
    let bad_prelude = bs_run_cli_capture_cwd(ctx, compiler_path, "build-options-bad-prelude", bad_prelude_args, 120000, case_dir)
    if bad_prelude.rc == 0:
        return bs_fail(ctx, "build options bad prelude unexpectedly succeeded")
    bs_assert_contains(ctx, bad_prelude.stderr, "invalid --prelude value 'bogus' (expected full|core|none)", "build_options_bad_prelude")

fn bs_check_whole_program_extern_var_redecl(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let defs_src = bs_join(case_dir, "defs.w")
    let user_src = bs_join(case_dir, "user.w")
    let main_src = bs_join(case_dir, "main.w")
    let bin = bs_join(case_dir, "whole_program_extern_var_redecl")
    var rc = bs_write_fixture(ctx, defs_src, "var shared_counter: i32 = 41\n", "extern redecl defs")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, user_src, "extern var shared_counter: i32\nfn read_counter() -> i32: shared_counter + 1\n", "extern redecl user")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, main_src, "use user\nuse defs\n\nfn main:\n    if read_counter() == 42:\n        print(\"ok\")\n    else:\n        print(\"bad\")\n", "extern redecl main")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("build")
    args |> push(bs_abs(root, main_src))
    args |> push("-o")
    args |> push(bs_abs(root, bin))
    let build_result = bs_edge_expect_success(ctx, compiler_path, case_dir, "whole-program-extern-var-redecl", args)
    if build_result.rc != 0: return build_result.rc
    let run_result = bs_run_binary_capture(ctx, bin, "whole-program-extern-var-redecl-run", 120000)
    if run_result.rc != 0: return run_result.rc
    bs_edge_assert_exact(ctx, bs_trim_trailing_line_endings(run_result.stdout), "ok", "whole_program_extern_var_redecl", "stdout")

fn bs_check_imported_module_dependency_order(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let defs_src = bs_join(case_dir, "defs.w")
    let module_src = bs_join(case_dir, "m.w")
    let user_src = bs_join(case_dir, "user.w")
    var rc = bs_write_fixture(ctx, defs_src, "type T = opaque\n", "dependency order defs")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, module_src, "use defs\nextern var gv: T\ntype T { x: i32 = 0 }\n", "dependency order module")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, user_src, "use m\nfn main: let _ = 0\n", "dependency order user")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("check")
    args |> push(bs_abs(root, user_src))
    let result = bs_edge_expect_success(ctx, compiler_path, case_dir, "imported-module-dependency-order", args)
    if result.rc != 0: return result.rc
    0

fn bs_compile_emit_c_output(ctx: ActionCtx, root: str, case_dir: str, c_path: str, bin: str, label: str) -> i32:
    let stdout_path = bs_capture_path(root, case_dir, label ++ "-compile", "stdout")
    let stderr_path = bs_capture_path(root, case_dir, label ++ "-compile", "stderr")
    var cc_args: Vec[str] = Vec.new()
    cc_args |> push("zig")
    cc_args |> push("cc")
    cc_args |> push("-O2")
    cc_args |> push("-o")
    cc_args |> push(bs_abs(root, bin))
    cc_args |> push(bs_abs(root, c_path))
    cc_args |> push(bs_abs(root, "out/lib/rt_core.o"))
    cc_args |> push(bs_abs(root, "out/lib/rt_darwin_aarch64.o"))
    cc_args |> push(bs_abs(root, "out/lib/compat_runtime.o"))
    cc_args |> push(bs_abs(root, "out/lib/panic_runtime.o"))
    cc_args |> push(bs_abs(root, "out/lib/fiber_stubs.o"))
    cc_args |> push(bs_abs(root, "out/lib/cimport_stubs.o"))
    cc_args |> push(bs_abs(root, "out/lib/embedded_objects.o"))
    cc_args |> push("-I")
    cc_args |> push(bs_abs(root, "runtime"))
    let cc_result = ctx.process_runner().run_capture(cc_args, stdout_path, stderr_path, 120000)
    if cc_result.rc == 0:
        return 0
    ctx.diagnostics().error(ctx.target_name() ++ f": {label} C compile failed with exit code {cc_result.rc}")
    ctx.diagnostics().error(cc_result.stderr)
    cc_result.rc

fn bs_check_emit_c_receiver_abi(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "receiver_abi.w")
    let c_path = bs_join(case_dir, "receiver_abi.c")
    let bin = bs_join(case_dir, "receiver_abi")
    let source = "extern fn with_print_str(s: str) -> void\n\n" ++
        "type Counter {\n" ++
        "    value: i32,\n" ++
        "}\n\n" ++
        "fn Counter.bump(mut self: Counter, amount: i32) -> Counter:\n" ++
        "    self.value = self.value + amount\n" ++
        "    self\n\n" ++
        "fn main() -> i32:\n" ++
        "    var c = Counter { value: 0 }\n" ++
        "    c = c.bump(2)\n" ++
        "    c = c.bump(5)\n" ++
        "    if c.value != 7:\n" ++
        "        return c.value\n" ++
        "    with_print_str(\"ok\")\n" ++
        "    0\n"
    var rc = bs_write_fixture(ctx, src, source, "emit-c receiver ABI source")
    if rc != 0: return rc
    var emit_args: Vec[str] = Vec.new()
    emit_args |> push("build")
    emit_args |> push(bs_abs(root, src))
    emit_args |> push("--emit-c")
    emit_args |> push("--no-prelude")
    emit_args |> push("-o")
    emit_args |> push(bs_abs(root, c_path))
    let emit_result = bs_edge_expect_success(ctx, compiler_path, case_dir, "emit-c-receiver-abi", emit_args)
    if emit_result.rc != 0: return emit_result.rc

    rc = bs_compile_emit_c_output(ctx, root, case_dir, c_path, bin, "emit-c-receiver-abi")
    if rc != 0: return rc
    let run_result = bs_run_binary_capture(ctx, bin, "emit-c-receiver-abi-run", 120000)
    if run_result.rc != 0: return run_result.rc
    bs_edge_assert_exact(ctx, run_result.stdout, "ok", "emit_c_receiver_abi", "stdout")

fn bs_check_emit_c_hashmap_new_field(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "hashmap_new_field.w")
    let c_path = bs_join(case_dir, "hashmap_new_field.c")
    let bin = bs_join(case_dir, "hashmap_new_field")
    let source = "use std.prelude_core\n\n" ++
        "extern fn with_print_str(s: str) -> void\n\n" ++
        "type Registry {\n" ++
        "    names: HashMap[str, i32],\n" ++
        "}\n\n" ++
        "fn Registry.new() -> Registry:\n" ++
        "    Registry { names: HashMap.new() }\n\n" ++
        "fn main() -> i32:\n" ++
        "    let registry = Registry.new()\n" ++
        "    registry.names.insert(\"name00\", 0)\n" ++
        "    registry.names.insert(\"name01\", 1)\n" ++
        "    registry.names.insert(\"name02\", 2)\n" ++
        "    registry.names.insert(\"name03\", 3)\n" ++
        "    registry.names.insert(\"name04\", 4)\n" ++
        "    registry.names.insert(\"name05\", 5)\n" ++
        "    registry.names.insert(\"name06\", 6)\n" ++
        "    registry.names.insert(\"name07\", 7)\n" ++
        "    registry.names.insert(\"name08\", 8)\n" ++
        "    registry.names.insert(\"name09\", 9)\n" ++
        "    registry.names.insert(\"name10\", 10)\n" ++
        "    registry.names.insert(\"name11\", 11)\n" ++
        "    registry.names.insert(\"name12\", 12)\n" ++
        "    registry.names.insert(\"name13\", 13)\n" ++
        "    registry.names.insert(\"name14\", 14)\n" ++
        "    registry.names.insert(\"name15\", 15)\n" ++
        "    registry.names.insert(\"name16\", 16)\n" ++
        "    registry.names.insert(\"name17\", 17)\n" ++
        "    registry.names.insert(\"name18\", 18)\n" ++
        "    registry.names.insert(\"name19\", 19)\n" ++
        "    if not registry.names.contains(\"name19\"):\n" ++
        "        return 77\n" ++
        "    with_print_str(\"ok\")\n" ++
        "    0\n"
    var rc = bs_write_fixture(ctx, src, source, "emit-c hashmap aggregate field source")
    if rc != 0: return rc
    var emit_args: Vec[str] = Vec.new()
    emit_args |> push("build")
    emit_args |> push(bs_abs(root, src))
    emit_args |> push("--emit-c")
    emit_args |> push("--no-prelude")
    emit_args |> push("-o")
    emit_args |> push(bs_abs(root, c_path))
    let emit_result = bs_edge_expect_success(ctx, compiler_path, case_dir, "emit-c-hashmap-new-field", emit_args)
    if emit_result.rc != 0: return emit_result.rc
    rc = bs_compile_emit_c_output(ctx, root, case_dir, c_path, bin, "emit-c-hashmap-new-field")
    if rc != 0: return rc
    let run_result = bs_run_binary_capture(ctx, bin, "emit-c-hashmap-new-field-run", 120000)
    if run_result.rc != 0: return run_result.rc
    bs_edge_assert_exact(ctx, run_result.stdout, "ok", "emit_c_hashmap_new_field", "stdout")

pub fn run_emit_c_smoke_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() < 2:
        return bs_fail(ctx, "missing compiler and source inputs")
    let fs = ctx.fs()
    let output_dir = ctx.output()
    if output_dir.len() == 0:
        return bs_fail(ctx, "missing output directory")
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return bs_fail(ctx, "could not remove previous output directory: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return bs_fail(ctx, "could not create output directory: " ++ output_dir)

    let root = ctx.project_info().project_root()
    let compiler_input = inputs.get(0)
    let source_input = inputs.get(1)
    if not fs.exists(compiler_input):
        return bs_fail(ctx, "missing compiler: " ++ compiler_input)
    if not fs.exists(source_input):
        return bs_fail(ctx, "missing source: " ++ source_input)
    let compiler_path = bs_abs(root, compiler_input)
    let c_path = bs_join(output_dir, "hello.c")
    let bin_path = bs_join(output_dir, "hello")

    let workspace = ctx.create_workspace("emit-c-smoke")
    workspace.add_file(source_input)
    var options = workspace.options()
    options.output_kind = BuildOutputKind.C
    options.output_path = c_path
    options.prelude_mode = PreludeMode.None
    workspace.set_options(options)
    let emit_result = workspace.compile()
    if emit_result.rc != 0:
        return bs_fail(ctx, f"emit-c workspace compile failed with exit code {emit_result.rc}")
    if not fs.exists(c_path):
        return bs_fail(ctx, "emit-c did not produce " ++ c_path)

    let compile_stdout = bs_capture_path(root, output_dir, "emit-c-smoke-compile", "stdout")
    let compile_stderr = bs_capture_path(root, output_dir, "emit-c-smoke-compile", "stderr")
    var cc_args: Vec[str] = Vec.new()
    cc_args |> push("zig")
    cc_args |> push("cc")
    cc_args |> push("-O2")
    cc_args |> push("-o")
    cc_args |> push(bs_abs(root, bin_path))
    cc_args |> push(bs_abs(root, c_path))
    cc_args |> push(bs_abs(root, "out/lib/rt_core.o"))
    cc_args |> push(bs_abs(root, "out/lib/rt_darwin_aarch64.o"))
    cc_args |> push(bs_abs(root, "out/lib/compat_runtime.o"))
    cc_args |> push(bs_abs(root, "out/lib/panic_runtime.o"))
    cc_args |> push(bs_abs(root, "out/lib/fiber_stubs.o"))
    cc_args |> push(bs_abs(root, "out/lib/cimport_stubs.o"))
    cc_args |> push(bs_abs(root, "out/lib/embedded_objects.o"))
    cc_args |> push("-I")
    cc_args |> push(bs_abs(root, "runtime"))
    let compile_result = ctx.process_runner().run_capture(cc_args, compile_stdout, compile_stderr, 120000)
    if compile_result.rc != 0:
        return bs_fail(ctx, f"zig cc failed with exit code {compile_result.rc}; stdout=" ++ compile_stdout ++ " stderr=" ++ compile_stderr)
    if not fs.exists(bin_path):
        return bs_fail(ctx, "zig cc did not produce " ++ bin_path)

    let run_result = bs_run_binary_capture(ctx, bin_path, "emit-c-smoke-run", 120000)
    if run_result.rc != 0:
        return bs_fail(ctx, f"emitted C binary failed with exit code {run_result.rc}: " ++ run_result.stderr)
    let output = bs_trim_trailing_line_endings(run_result.stdout)
    if output != "hello":
        return bs_fail(ctx, "emitted C binary output mismatch: " ++ output)
    var rc = bs_check_emit_c_hashmap_new_field(ctx, compiler_path, bs_join(output_dir, "emit_c_hashmap_new_field_case"))
    if rc != 0: return rc
    print("EMIT-C SMOKE OK")
    0

pub fn run_cli_selfhost_edge_action(ctx: ActionCtx) -> i32:
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

    var rc = bs_check_pointer_index_rejected(ctx, compiler_path, bs_join(output_dir, "pointer_index_rejected_case"))
    if rc != 0: return rc
    rc = bs_check_prelude_output_functions(ctx, compiler_path, bs_join(output_dir, "prelude_output_functions_case"))
    if rc != 0: return rc
    rc = bs_check_build_options_cli(ctx, compiler_path, bs_join(output_dir, "build_options_cli_case"))
    if rc != 0: return rc
    rc = bs_check_whole_program_extern_var_redecl(ctx, compiler_path, bs_join(output_dir, "whole_program_extern_var_redecl_case"))
    if rc != 0: return rc
    rc = bs_check_imported_module_dependency_order(ctx, compiler_path, bs_join(output_dir, "imported_module_dependency_order_case"))
    if rc != 0: return rc
    bs_check_emit_c_receiver_abi(ctx, compiler_path, bs_join(output_dir, "emit_c_receiver_abi_case"))

pub fn run_cli_selfhost_parallel_action(ctx: ActionCtx) -> i32:
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
    let root = ctx.project_info().project_root()
    let compiler_path = bs_abs(root, compiler_input)
    let src = bs_join(output_dir, "attr_only.w")
    if bs_write_fixture(ctx, src, "@[test]\nfn attr_only:\n    assert(1 == 1)\n", "parallel same-source test") != 0:
        return 1

    var args: Vec[str] = Vec.new()
    args |> push("test")
    args |> push(bs_abs(root, src))
    let single = bs_run_cli_capture_cwd(ctx, compiler_path, "parallel-same-source-single", args, 120000, root)
    if single.rc != 0:
        return single.rc
    if single.stderr.len() != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": single run produced stderr")
        ctx.diagnostics().error(single.stderr)
        return 1

    var argv: Vec[str] = Vec.new()
    argv |> push(compiler_path)
    argv |> push("test")
    argv |> push(bs_abs(root, src))

    let jobs = 32
    let pids: Vec[i32] = Vec.new()
    for i in 0..jobs:
        let stdout_rel = bs_join(output_dir, f"job-{i}.stdout")
        let stderr_rel = bs_join(output_dir, f"job-{i}.stderr")
        let pid = ctx.process_runner().spawn_capture(argv, bs_abs(root, stdout_rel), bs_abs(root, stderr_rel))
        if pid <= 0:
            return bs_fail(ctx, f"could not spawn job {i}")
        pids.push(pid)

    var failed = false
    for i in 0..jobs:
        let pid = pids.get(i as i64)
        let job_rc = ctx.process_runner().wait(pid, 120000)
        if job_rc != 0:
            let stdout_rel = bs_join(output_dir, f"job-{i}.stdout")
            let stderr_rel = bs_join(output_dir, f"job-{i}.stderr")
            ctx.diagnostics().error(ctx.target_name() ++ f": job {i} failed with exit code {job_rc}")
            let stdout_text = fs.read_text(stdout_rel)
            if stdout_text.len() > 0:
                ctx.diagnostics().error(stdout_text)
            let stderr_text = fs.read_text(stderr_rel)
            if stderr_text.len() > 0:
                ctx.diagnostics().error(stderr_text)
            failed = true
    if failed:
        return 1
    0

fn bs_file_contains(ctx: ActionCtx, path: str, needle: str, label: str) -> i32:
    if not ctx.fs().exists(path):
        return bs_fail(ctx, "missing file for " ++ label ++ ": " ++ path)
    bs_assert_contains(ctx, ctx.fs().read_text(path), needle, label)

fn bs_file_forbids(ctx: ActionCtx, path: str, needle: str, label: str) -> i32:
    if not ctx.fs().exists(path):
        return bs_fail(ctx, "missing file for " ++ label ++ ": " ++ path)
    bs_assert_not_contains(ctx, ctx.fs().read_text(path), needle, label)

fn bs_index_of(text: str, needle: str) -> i32:
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

fn bs_count_occurrences(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    var count = 0
    var offset = 0
    while offset < text.len() as i32:
        let found = bs_index_of(text.slice(offset as i64, text.len()), needle)
        if found < 0:
            break
        count = count + 1
        offset = offset + found + needle.len() as i32
    count

fn bs_migrate_expect_success(ctx: ActionCtx, compiler_path: str, case_dir: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, label, args, 180000, case_dir)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": migrator selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bs_check_migrate_global_init_list(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "initlist.c")
    let out_w = bs_join(case_dir, "initlist.w")
    var rc = bs_write_fixture(ctx, src, "typedef int (*callback_t)(int);\ntypedef struct inner { callback_t cb; void *data; } inner;\ntypedef struct outer { inner in; int limit; } outer;\nint add1(int x) { return x + 1; }\nouter g = { { add1, 0 }, 7 };\n", "migrate global init list")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-global-init-list", args)
    if result.rc != 0: return result.rc
    bs_file_contains(ctx, out_w, "var g: outer = outer { in_: inner { cb: add1, data: null }, limit: 7 }", "global_init_list")

fn bs_check_migrate_host_header_compat(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "uses_isatty.c")
    let out_w = bs_join(case_dir, "uses_isatty.w")
    var rc = bs_write_fixture(ctx, bs_join(case_dir, "config.h"), "/* Simulate an unconfigured config.h template. */\n", "migrate host header config")
    if rc != 0: return rc
    let c_text = "#if defined HAVE_CONFIG_H\n#include \"config.h\"\n#endif\n\n#ifndef HAVE_UNISTD_H\n#error \"missing HAVE_UNISTD_H\"\n#endif\n\n#ifdef HAVE_UNISTD_H\n#include <unistd.h>\n#endif\n\n#include <stdio.h>\n\nint tty_status(FILE *f) { return isatty(fileno(f)); }\n"
    rc = bs_write_fixture(ctx, src, c_text, "migrate host header source")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("-I")
    args |> push(bs_abs(root, case_dir))
    args |> push("-D")
    args |> push("HAVE_CONFIG_H=1")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-host-header-compat", args)
    if result.rc != 0: return result.rc
    bs_file_contains(ctx, out_w, "tty_status", "host_header_compat")

fn bs_check_migrate_assignment_compat(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "assignments.c")
    let out_w = bs_join(case_dir, "assignments.w")
    let c_text = "typedef unsigned int c_uint;\ntypedef struct {\n  c_uint *groupinfo;\n  c_uint *parsed_pattern;\n} compile_block;\n\nvoid f(void) {\n  compile_block cb;\n  c_uint stack_groupinfo[32];\n  c_uint stack_parsed_pattern[64];\n  c_uint pp = 0;\n  c_uint skipatstart = 0;\n  cb.groupinfo = stack_groupinfo;\n  cb.parsed_pattern = stack_parsed_pattern;\n  skipatstart = (pp = pp + 1);\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "migrate assignment compat")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-assignment-compat", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    rc = bs_assert_contains(ctx, out_text, "(__local_cb.groupinfo = (&(unsafe: __local_stack_groupinfo[0]) as *mut c_uint))", "assignment_compat")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "(__local_cb.parsed_pattern = (&(unsafe: __local_stack_parsed_pattern[0]) as *mut c_uint))", "assignment_compat")
    if rc != 0: return rc
    let pp_simple = "(__local_pp = (__local_pp +% 1))"
    let pp_casted = "(__local_pp = ((__local_pp as c_uint) +% (1 as c_uint)))"
    let pp_index = if bs_index_of(out_text, pp_simple) >= 0: bs_index_of(out_text, pp_simple) else: bs_index_of(out_text, pp_casted)
    let skip_index = bs_index_of(out_text, "(__local_skipatstart = __local_pp)")
    if pp_index < 0 or skip_index < 0 or pp_index >= skip_index:
        return bs_fail(ctx, "assignment_compat did not preserve assignment sequencing")
    rc = bs_assert_not_contains(ctx, out_text, "(__local_skipatstart = ((__local_pp) =", "assignment_compat")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check_result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-assignment-compat", check_args)
    if check_result.rc != 0: return check_result.rc
    0

fn bs_check_migrate_rvalue_sequencing(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "rvalue_sequencing.c")
    let out_w = bs_join(case_dir, "rvalue_sequencing.w")
    let c_text = "typedef unsigned char u8;\n\nstatic int issue120_id(int x) { return x; }\n\nint init_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = *p++;\n  return c * 10 + (int)(p - buf);\n}\n\nint assign_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = 0;\n  c = *p++;\n  return c * 10 + (int)(p - buf);\n}\n\nint binary_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = (*p++) + 0;\n  return c * 10 + (int)(p - buf);\n}\n\nint call_arg_expr(void) {\n  const u8 *buf = (const u8 *)\"AB\";\n  const u8 *p = buf;\n  int c = issue120_id(*p++);\n  return c * 10 + (int)(p - buf);\n}\n\n#define ISSUE120_GETCHARINCTEST(ch, ptr) ch = *ptr++; if (utf && ch >= 66u) ch += 1000\n\nint macro_expr(int utf) {\n  const u8 *buf = (const u8 *)\"BA\";\n  const u8 *p = buf;\n  int c = 0;\n  ISSUE120_GETCHARINCTEST(c, p);\n  return c * 10 + (int)(p - buf);\n}\n\nstatic unsigned int issue120_ord2utf(unsigned int c, u8 *p) {\n  *p = (u8)c;\n  return 1;\n}\n\n#define ISSUE120_PUTCHAR(c, p) ((utf && c > 127u) ? issue120_ord2utf(c, p) : (*p = c, 1))\n\nint macro_ternary_comma_expr(int utf) {\n  u8 buf[1] = { 0 };\n  u8 *p = buf;\n  unsigned int c = 65u;\n  p += ISSUE120_PUTCHAR(c, p);\n  return ((int)buf[0]) * 10 + (int)(p - buf);\n}\n\nint main(void) {\n  if (init_expr() != 651) return 1;\n  if (assign_expr() != 651) return 2;\n  if (binary_expr() != 651) return 3;\n  if (call_arg_expr() != 651) return 4;\n  if (macro_expr(0) != 661) return 5;\n  if (macro_expr(1) != 10661) return 6;\n  if (macro_ternary_comma_expr(0) != 651) return 7;\n  return 0;\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "migrate rvalue sequencing")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-rvalue-sequencing", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    rc = bs_assert_contains(ctx, out_text, "with 0 as __ci_expr_seq_", "rvalue_sequencing")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "var __ci_expr_old_", "rvalue_sequencing")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "(__local_p = __local_p + 1)", "rvalue_sequencing")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "(unsafe: *__ci_expr_old_", "rvalue_sequencing")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "((unsafe: *__local_p) = __local_c)", "rvalue_sequencing")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check_result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-rvalue-sequencing", check_args)
    if check_result.rc != 0: return check_result.rc
    var run_args: Vec[str] = Vec.new()
    run_args |> push("run")
    run_args |> push(bs_abs(root, out_w))
    let run_result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "run-rvalue-sequencing", run_args)
    if run_result.rc != 0: return run_result.rc
    0

fn bs_check_migrate_directory_progress(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src_dir = bs_join(case_dir, "src")
    let out_dir = bs_join(case_dir, "out")
    var rc = bs_write_fixture(ctx, bs_join(src_dir, "a.c"), "int a_value(void) { return 1; }\n", "directory progress a")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(src_dir, "b.c"), "int b_value(void) { return 2; }\n", "directory progress b")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src_dir))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, out_dir))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-directory-progress", args)
    if result.rc != 0: return result.rc
    rc = bs_assert_contains(ctx, result.stdout, "migrate: processing a.c - 1/2, 50% completed", "directory_progress_stdout")
    if rc != 0: return rc
    bs_assert_contains(ctx, result.stdout, "migrate: processing b.c - 2/2, 100% completed", "directory_progress_stdout")

fn bs_check_migrate_cross_file_global_owner_arrays(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let generated_dir = bs_join(case_dir, "generated")
    var rc = bs_write_fixture(ctx, bs_join(case_dir, "tables.h"), "extern const unsigned char issue121_table[];\nint issue121_value(int idx);\nint issue121_sum(void);\n", "cross file table header")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(case_dir, "owner.c"), "#include \"tables.h\"\n\nconst unsigned char issue121_table[] = {7, 9, 11};\n\nint issue121_value(int idx) {\n  return issue121_table[idx];\n}\n", "cross file owner")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(case_dir, "user.c"), "#include \"tables.h\"\n\nint issue121_sum(void) {\n  return issue121_table[2] + issue121_value(1);\n}\n", "cross file user")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, case_dir))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, generated_dir))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-cross-file-global-owner-arrays", args)
    if result.rc != 0: return result.rc
    let owner_w = bs_join(generated_dir, "owner.w")
    let user_w = bs_join(generated_dir, "user.w")
    rc = bs_file_contains(ctx, owner_w, "let issue121_table: [3]u8", "cross_file_global_owner_arrays owner")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, user_w, "extern let issue121_table: [3]u8", "cross_file_global_owner_arrays user")
    if rc != 0: return rc
    rc = bs_file_forbids(ctx, owner_w, "issue121_table: *", "cross_file_global_owner_arrays owner")
    if rc != 0: return rc
    rc = bs_file_forbids(ctx, user_w, "issue121_table: *", "cross_file_global_owner_arrays user")
    if rc != 0: return rc
    var owner_check_args: Vec[str] = Vec.new()
    owner_check_args |> push("check")
    owner_check_args |> push(bs_abs(root, owner_w))
    let owner_check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-cross-file-owner", owner_check_args)
    if owner_check.rc != 0: return owner_check.rc
    var user_check_args: Vec[str] = Vec.new()
    user_check_args |> push("check")
    user_check_args |> push(bs_abs(root, user_w))
    let user_check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-cross-file-user", user_check_args)
    if user_check.rc != 0: return user_check.rc
    var owner_build_args: Vec[str] = Vec.new()
    owner_build_args |> push("build")
    owner_build_args |> push(bs_abs(root, owner_w))
    owner_build_args |> push("--emit-obj")
    owner_build_args |> push("-o")
    owner_build_args |> push(bs_abs(root, bs_join(generated_dir, "owner.o")))
    let owner_build = bs_migrate_expect_success(ctx, compiler_path, case_dir, "build-cross-file-owner", owner_build_args)
    if owner_build.rc != 0: return owner_build.rc
    var user_build_args: Vec[str] = Vec.new()
    user_build_args |> push("build")
    user_build_args |> push(bs_abs(root, user_w))
    user_build_args |> push("--emit-obj")
    user_build_args |> push("-o")
    user_build_args |> push(bs_abs(root, bs_join(generated_dir, "user.o")))
    let user_build = bs_migrate_expect_success(ctx, compiler_path, case_dir, "build-cross-file-user", user_build_args)
    if user_build.rc != 0: return user_build.rc
    0

fn bs_check_migrate_shared_defs_ownerless_extern(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let generated_dir = bs_join(case_dir, "generated")
    var rc = bs_write_fixture(ctx, bs_join(case_dir, "tables.h"), "extern const unsigned char issue140_unused_external[];\nextern const unsigned char issue140_owned_table[];\nint issue140_read_owned(void);\n", "shared defs table header")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(case_dir, "owner.c"), "#include \"tables.h\"\n\nconst unsigned char issue140_owned_table[] = {3, 5, 8};\n\nint issue140_read_owned(void) {\n  return issue140_owned_table[1];\n}\n", "shared defs owner")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, case_dir))
    args |> push("--no-c-export")
    args |> push("--shared-defs")
    args |> push("defs")
    args |> push("-I")
    args |> push(bs_abs(root, case_dir))
    args |> push("-o")
    args |> push(bs_abs(root, generated_dir))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-shared-defs-ownerless-extern", args)
    if result.rc != 0: return result.rc
    let defs_w = bs_join(generated_dir, "defs.w")
    let defs_text = ctx.fs().read_text(defs_w)
    rc = bs_assert_contains(ctx, defs_text, "let issue140_owned_table:", "shared_defs_ownerless_extern")
    if rc != 0: return rc
    rc = bs_assert_not_contains(ctx, defs_text, "issue140_unused_external", "shared_defs_ownerless_extern")
    if rc != 0: return rc
    if bs_count_occurrences(defs_text, "fn string_find_char(") != 1:
        return bs_fail(ctx, "shared_defs_ownerless_extern emitted duplicate or missing string_find_char helper")
    0

pub fn run_cli_selfhost_migrate_basic_action(ctx: ActionCtx) -> i32:
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

    var rc = bs_check_migrate_global_init_list(ctx, compiler_path, bs_join(output_dir, "global_init_list"))
    if rc != 0: return rc
    rc = bs_check_migrate_host_header_compat(ctx, compiler_path, bs_join(output_dir, "host_header_compat"))
    if rc != 0: return rc
    rc = bs_check_migrate_assignment_compat(ctx, compiler_path, bs_join(output_dir, "assignment_compat"))
    if rc != 0: return rc
    rc = bs_check_migrate_rvalue_sequencing(ctx, compiler_path, bs_join(output_dir, "rvalue_sequencing"))
    if rc != 0: return rc
    rc = bs_check_migrate_directory_progress(ctx, compiler_path, bs_join(output_dir, "directory_progress"))
    if rc != 0: return rc
    rc = bs_check_migrate_cross_file_global_owner_arrays(ctx, compiler_path, bs_join(output_dir, "cross_file_global_owner_arrays"))
    if rc != 0: return rc
    bs_check_migrate_shared_defs_ownerless_extern(ctx, compiler_path, bs_join(output_dir, "shared_defs_ownerless_extern"))

fn bs_check_migrate_libc_ctype(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "libc_ctype.c")
    let out_w = bs_join(case_dir, "libc_ctype.w")
    let c_text = "#include <ctype.h>\n\nint classify(int c) {\n  return isalpha(c) + isdigit(c) + isalnum(c) + isspace(c) +\n    isupper(c) + islower(c) + isxdigit(c) + isprint(c) +\n    isgraph(c) + ispunct(c) + iscntrl(c) + tolower(c) + toupper(c);\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "libc ctype source")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-libc-ctype", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    let required: Vec[str] = Vec.new()
    required |> push("extern fn isalpha(c: i32) -> i32")
    required |> push("extern fn tolower(c: i32) -> i32")
    required |> push("isalpha(__param_c)")
    required |> push("isalnum(__param_c)")
    required |> push("isgraph(__param_c)")
    required |> push("tolower(__param_c)")
    for i in 0..required.len() as i32:
        rc = bs_assert_contains(ctx, out_text, required.get(i as i64), "libc_ctype_calls")
        if rc != 0: return rc
    let forbidden: Vec[str] = Vec.new()
    forbidden |> push("is_alpha(__param_c)")
    forbidden |> push("is_alnum(__param_c)")
    forbidden |> push("to_lower(__param_c)")
    for i in 0..forbidden.len() as i32:
        rc = bs_assert_not_contains(ctx, out_text, forbidden.get(i as i64), "libc_ctype_calls")
        if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-libc-ctype", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_macro_unsigned_minus(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "macro_initializer_unsigned_minus.c")
    let out_w = bs_join(case_dir, "macro_initializer_unsigned_minus.w")
    let c_text = "typedef unsigned long size_t;\n\n#define MY_SIZE_MAX ((size_t)-1)\n#define COPY_ONE(dst_, src_, length_) do { size_t chkmc_length = length_; if (chkmc_length > 0) { (dst_)[0] = (src_)[0]; } } while (0)\n\nint too_large(size_t current, size_t need) {\n  return current > (MY_SIZE_MAX - need) / 2;\n}\n\nint repeat_too_large(size_t replen, size_t need, int count) {\n  return count > 0 && replen > (MY_SIZE_MAX - need) / count;\n}\n\nint copy_after_goto(char *dst, const char *src, int flag) {\n  if (flag) goto copy;\n  return 0;\ncopy:\n  COPY_ONE(dst, src, 3);\n  return (int)dst[0];\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "macro unsigned source")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-macro-unsigned-minus", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    if not out_text.contains("(-1 as ") and not out_text.contains("(0 as "):
        return bs_fail(ctx, "macro_initializer_unsigned_minus missing typed unsigned -1")
    rc = bs_assert_not_contains(ctx, out_text, "((0 -% 1)", "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "/ (__param_count as ", "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "__local_chkmc_length", "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "= 3)", "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-macro-unsigned-minus", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_ulong_max_width(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "ulong_max_width.c")
    let out_w = bs_join(case_dir, "ulong_max_width.w")
    let c_text = "#include <limits.h>\n#include <stdlib.h>\n\nint cmp_ulong_max(unsigned long x) {\n  return x == ULONG_MAX;\n}\n\nint parse_overflow(char *s) {\n  char *end;\n  unsigned long value = strtoul(s, &end, 10);\n  return value == ULONG_MAX;\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "ulong max width source")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-ulong-max-width", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    rc = bs_assert_contains(ctx, out_text, "9223372036854775807 as c_ulong", "ulong_max_width")
    if rc != 0: return rc
    rc = bs_assert_not_contains(ctx, out_text, "9223372036854775807 as c_uint", "ulong_max_width")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-ulong-max-width", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_tentative_global_owner(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "tentative_global_owner.c")
    let out_w = bs_join(case_dir, "tentative_global_owner.w")
    var rc = bs_write_fixture(ctx, src, "typedef struct ctx { int x; } ctx;\nctx g;\nint issue127_read(void) { return g.x; }\n", "tentative global owner")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-tentative-global-owner", args)
    if result.rc != 0: return result.rc
    rc = bs_file_contains(ctx, out_w, "var g: ctx", "tentative_global_owner")
    if rc != 0: return rc
    rc = bs_file_forbids(ctx, out_w, "extern var g: ctx", "tentative_global_owner")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-tentative-global-owner", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_cross_file_tentative_global_owner(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let generated_dir = bs_join(case_dir, "generated")
    var rc = bs_write_fixture(ctx, bs_join(case_dir, "a.c"), "int issue127_counter;\nint issue127_get(void) { return issue127_counter; }\n", "cross tentative a")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(case_dir, "b.c"), "int issue127_counter;\nint issue127_bump(void) {\n  issue127_counter = issue127_counter + 1;\n  return issue127_counter;\n}\n", "cross tentative b")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, case_dir))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, generated_dir))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-cross-file-tentative", args)
    if result.rc != 0: return result.rc
    let a_w = bs_join(generated_dir, "a.w")
    let b_w = bs_join(generated_dir, "b.w")
    rc = bs_file_contains(ctx, a_w, "var issue127_counter: c_int", "cross_file_tentative_global_owner")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, b_w, "extern var issue127_counter: c_int", "cross_file_tentative_global_owner")
    if rc != 0: return rc
    var check_a_args: Vec[str] = Vec.new()
    check_a_args |> push("check")
    check_a_args |> push(bs_abs(root, a_w))
    let check_a = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-cross-file-tentative-a", check_a_args)
    if check_a.rc != 0: return check_a.rc
    var check_b_args: Vec[str] = Vec.new()
    check_b_args |> push("check")
    check_b_args |> push(bs_abs(root, b_w))
    let check_b = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-cross-file-tentative-b", check_b_args)
    if check_b.rc != 0: return check_b.rc
    0

fn bs_check_migrate_noop_pointer_casts(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "noop_pointer_cast_exprs.c")
    let out_w = bs_join(case_dir, "noop_pointer_cast_exprs.w")
    let c_text = "typedef struct ctx { int x; } ctx;\nctx g;\n\nctx *ret_ctx(void) { return (ctx *)(&g); }\n\nint f(ctx *ccontext) {\n  ctx *local = (ctx *)(&g);\n  ccontext = (ctx *)(&g);\n  return local->x + ccontext->x;\n}\n\nstatic void callback(void *p) { (void)p; }\n\ntypedef void (*callback_fn)(void *);\n\ncallback_fn ret_callback(void) { return &callback; }\n"
    var rc = bs_write_fixture(ctx, src, c_text, "noop pointer casts")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-noop-pointer-casts", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    let required: Vec[str] = Vec.new()
    required |> push("fn ret_ctx() -> *mut ctx:")
    required |> push("return ((&raw mut g as *mut ctx))")
    required |> push("var __local_local: *mut ctx = ((&raw mut g as *mut ctx))")
    required |> push("(&raw mut g as *mut ctx)")
    required |> push("return callback")
    for i in 0..required.len() as i32:
        rc = bs_assert_contains(ctx, out_text, required.get(i as i64), "noop_pointer_cast_exprs")
        if rc != 0: return rc
    let forbidden: Vec[str] = Vec.new()
    forbidden |> push("extern fn ret_ctx()")
    forbidden |> push("as *mut ctx)) as *mut ctx")
    forbidden |> push("&raw const callback")
    for i in 0..forbidden.len() as i32:
        rc = bs_assert_not_contains(ctx, out_text, forbidden.get(i as i64), "noop_pointer_cast_exprs")
        if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-noop-pointer-casts", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_raw_pointer_index(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "raw_pointer_index_unsafe.c")
    let out_w = bs_join(case_dir, "raw_pointer_index_unsafe.w")
    var rc = bs_write_fixture(ctx, src, "int issue146_ptr_ops(int *p, int *q) {\n  int *r = p + 1;\n  int d = (int)(q - p);\n  r[0] = r[0] + d;\n  return p[1];\n}\n", "raw pointer index")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-raw-pointer-index", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    rc = bs_assert_contains(ctx, out_text, "__param_p +", "raw_pointer_index_unsafe")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "(unsafe: __local_r[0])", "raw_pointer_index_unsafe")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "(unsafe: __param_p[1])", "raw_pointer_index_unsafe")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-raw-pointer-index", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_prefer_brace_ws(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "prefer_brace_ws.c")
    let out_w = bs_join(case_dir, "prefer_brace_ws.w")
    let c_text = "int prefer_brace_ws(int *p) {\n  while (*p != 0) {\n    if (*p < 3) {\n      p++;\n      continue;\n    }\n    p++;\n  }\n  return 0;\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "prefer brace source")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-prefer-brace-ws", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)

    var saw_while_brace = false
    var saw_if_brace = false
    var line_start = 0
    while line_start < out_text.len() as i32:
        var line_end = line_start
        while line_end < out_text.len() as i32 and out_text.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        if line_end > line_start:
            let last = out_text.byte_at((line_end - 1) as i64)
            if last == 32 or last == 9:
                return bs_fail(ctx, "prefer_brace_ws emitted trailing whitespace")
        var trimmed_start = line_start
        while trimmed_start < line_end:
            let ch = out_text.byte_at(trimmed_start as i64)
            if ch != 32 and ch != 9:
                break
            trimmed_start = trimmed_start + 1
        let line = out_text.slice(trimmed_start as i64, line_end as i64)
        if line.starts_with("while"):
            if line.ends_with("{"):
                saw_while_brace = true
            if line.ends_with(":"):
                return bs_fail(ctx, "prefer_brace_ws emitted colon-style while")
        if line.starts_with("if"):
            if line.ends_with("{"):
                saw_if_brace = true
            if line.ends_with(":"):
                return bs_fail(ctx, "prefer_brace_ws emitted colon-style if")
        line_start = line_end + 1
    if not saw_while_brace:
        return bs_fail(ctx, "prefer_brace_ws missing brace-style while")
    if not saw_if_brace:
        return bs_fail(ctx, "prefer_brace_ws missing brace-style if")
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-prefer-brace-ws", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_typed_cast_macros(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "typed_cast_macros.c")
    let out_w = bs_join(case_dir, "typed_cast_macros.w")
    let c_text = "typedef unsigned long usize;\n#define ZERO_TERM ((usize)-1)\n\nint f(usize patlen) {\n  int zero_terminated = 0;\n  if ((zero_terminated = (patlen == ZERO_TERM)))\n    patlen = 7;\n  return zero_terminated + (int)patlen;\n}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "typed cast macros")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-typed-cast-macros", args)
    if result.rc != 0: return result.rc
    let out_text = ctx.fs().read_text(out_w)
    rc = bs_assert_contains(ctx, out_text, "let ZERO_TERM: c_ulong = (-1 as c_ulong)", "typed_cast_macros")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, out_text, "patlen == ((-1 as c_ulong))", "typed_cast_macros")
    if rc != 0: return rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-typed-cast-macros", check_args)
    if check.rc != 0: return check.rc
    0

fn bs_check_migrate_switch_case_scope(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(case_dir, "switch_case_scope.c")
    let out_w = bs_join(case_dir, "switch_case_scope.w")
    var cases = ""
    for i in 0..48:
        cases = cases ++ "    case " ++ f"{i}" ++ ": {\n"
        cases = cases ++ f"      int local_{i} = {i + 1};\n"
        cases = cases ++ f"      acc += local_{i};\n"
        cases = cases ++ "      goto done;\n"
        cases = cases ++ "    }\n"
    let c_text = "int switch_scope(int x) {\n" ++
        "  int acc = 0;\n" ++
        "  switch (x) {\n" ++
        cases ++
        "    default: {\n" ++
        "      int fallback = 99;\n" ++
        "      acc += fallback;\n" ++
        "      goto done;\n" ++
        "    }\n" ++
        "  }\n" ++
        "done:\n" ++
        "  return acc;\n" ++
        "}\n\n" ++
        "int main(void) {\n" ++
        "  if (switch_scope(0) != 1) return 1;\n" ++
        "  if (switch_scope(17) != 18) return 2;\n" ++
        "  if (switch_scope(47) != 48) return 3;\n" ++
        "  if (switch_scope(99) != 99) return 4;\n" ++
        "  return 0;\n" ++
        "}\n"
    var rc = bs_write_fixture(ctx, src, c_text, "migrate switch case scope")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("migrate")
    args |> push(bs_abs(root, src))
    args |> push("--no-c-export")
    args |> push("--prefer-brace")
    args |> push("-o")
    args |> push(bs_abs(root, out_w))
    let result = bs_migrate_expect_success(ctx, compiler_path, case_dir, "migrate-switch-case-scope", args)
    if result.rc != 0: return result.rc
    var check_args: Vec[str] = Vec.new()
    check_args |> push("check")
    check_args |> push(bs_abs(root, out_w))
    let check = bs_migrate_expect_success(ctx, compiler_path, case_dir, "check-switch-case-scope", check_args)
    if check.rc != 0: return check.rc
    var run_args: Vec[str] = Vec.new()
    run_args |> push("run")
    run_args |> push(bs_abs(root, out_w))
    let run = bs_migrate_expect_success(ctx, compiler_path, case_dir, "run-switch-case-scope", run_args)
    if run.rc != 0: return run.rc
    0

pub fn run_cli_selfhost_migrate_core_action(ctx: ActionCtx) -> i32:
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

    var rc = bs_check_migrate_libc_ctype(ctx, compiler_path, bs_join(output_dir, "libc_ctype"))
    if rc != 0: return rc
    rc = bs_check_migrate_macro_unsigned_minus(ctx, compiler_path, bs_join(output_dir, "macro_unsigned_minus"))
    if rc != 0: return rc
    rc = bs_check_migrate_ulong_max_width(ctx, compiler_path, bs_join(output_dir, "ulong_max_width"))
    if rc != 0: return rc
    rc = bs_check_migrate_tentative_global_owner(ctx, compiler_path, bs_join(output_dir, "tentative_global_owner"))
    if rc != 0: return rc
    rc = bs_check_migrate_cross_file_tentative_global_owner(ctx, compiler_path, bs_join(output_dir, "cross_file_tentative_global_owner"))
    if rc != 0: return rc
    rc = bs_check_migrate_noop_pointer_casts(ctx, compiler_path, bs_join(output_dir, "noop_pointer_casts"))
    if rc != 0: return rc
    rc = bs_check_migrate_raw_pointer_index(ctx, compiler_path, bs_join(output_dir, "raw_pointer_index"))
    if rc != 0: return rc
    rc = bs_check_migrate_prefer_brace_ws(ctx, compiler_path, bs_join(output_dir, "prefer_brace_ws"))
    if rc != 0: return rc
    rc = bs_check_migrate_typed_cast_macros(ctx, compiler_path, bs_join(output_dir, "typed_cast_macros"))
    if rc != 0: return rc
    bs_check_migrate_switch_case_scope(ctx, compiler_path, bs_join(output_dir, "switch_case_scope"))


fn bs_build_w_write_fixture(ctx: ActionCtx, path: str, contents: str, _target_name: str, label: str) -> i32:
    let _ = _target_name
    bs_write_fixture(ctx, path, contents, label)

fn bs_argv_append(argv_blob: str, arg: str) -> str:
    argv_blob ++ arg ++ "\0"

fn bs_blob_to_args(blob: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    var start = 0
    for i in 0..blob.len() as i32:
        if blob.byte_at(i as i64) == 0:
            if i > start:
                args.push(blob.slice(start as i64, i as i64))
            start = i + 1
    args

fn bs_build_w_expect_success(ctx: ActionCtx, compiler_path: str, case_dir: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, label, args, 120000, case_dir)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": build.w selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bs_build_w_tool_from_env(env_name: str, fallback: str) -> str:
    let value = env(env_name)
    if value.len() > 0:
        return value
    fallback

fn bs_build_w_nm_smoke(ctx: ActionCtx, obj_path: str, label: str) -> i32:
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let stdout_rel = bs_join(output_dir, label ++ ".nm.stdout")
    let stderr_rel = bs_join(output_dir, label ++ ".nm.stderr")
    var args: Vec[str] = Vec.new()
    args |> push(bs_build_w_tool_from_env("NM", "nm"))
    args |> push(bs_abs(root, obj_path))
    let result = ctx.process_runner().run_capture(args, bs_abs(root, stdout_rel), bs_abs(root, stderr_rel), 120000)
    if result.rc != 0:
        return bs_fail(ctx, "nm failed for " ++ label)
    let _remove_stdout = ctx.fs().remove_file(stdout_rel)
    let _remove_stderr = ctx.fs().remove_file(stderr_rel)
    0

fn bs_check_build_w_not_ignored(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_project_manifest(ctx, case_dir, "buildwdemo")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/main.w"), "fn main:\n    print(\"default main\")\n", ctx.target_name(), "default main")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/custom.w"), "use c_import(\"answer.h\")\n\nfn main:\n    assert(ANSWER == 42)\n    print(\"custom build\")\n", ctx.target_name(), "custom main")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", ctx.target_name(), "answer.h")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Executable, \"custom-build\", \"src/custom.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    target = target.link_system_lib(\"m\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", ctx.target_name(), "build.w")
    if rc != 0: return rc
    let result = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-not-ignored", bs_blob_to_args(bs_argv_append("", "build")))
    if result.rc != 0: return result.rc
    let custom_bin = bs_join(case_dir, "out/bin/custom-build")
    if not ctx.fs().exists(custom_bin):
        ctx.diagnostics().error("error: build_w_not_ignored missing custom-build output")
        return 1
    if ctx.fs().exists(bs_join(case_dir, "out/bin/buildwdemo")):
        ctx.diagnostics().error("error: build_w_not_ignored unexpectedly produced default package output")
        return 1
    let run_result = bs_run_binary_capture(ctx, custom_bin, "build-w-not-ignored-run", 120000)
    if run_result.rc != 0: return run_result.rc
    rc = bs_assert_contains(ctx, run_result.stdout, "custom build", "build_w_not_ignored")
    if rc != 0: return rc
    let explicit = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-explicit-source", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), bs_abs(ctx.project_info().project_root(), bs_join(case_dir, "src/main.w")))))
    if explicit.rc != 0: return explicit.rc
    0

fn bs_check_build_w_comptime_with_entry(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let canonical_dir = bs_join(base_dir, "canonical")
    var rc = bs_write_project_manifest(ctx, canonical_dir, "comptimewithcanonical")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(canonical_dir, "src/main.w"), "fn main:\n    print(\"canonical comptime with\")\n", ctx.target_name(), "canonical source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(canonical_dir, "build.w"), "use std.build\n\ncomptime with BuildCtx as ctx:\npub fn build -> Build:\n    var out = ctx.new_build()\n    out.executable(\"canonical\", \"src/main.w\")\n", ctx.target_name(), "canonical comptime-with build.w")
    if rc != 0: return rc
    let canonical = bs_build_w_expect_success(ctx, compiler_path, canonical_dir, "build-w-comptime-with-canonical", bs_blob_to_args(bs_argv_append("", "build")))
    if canonical.rc != 0: return canonical.rc
    let canonical_bin = bs_join(canonical_dir, "out/bin/canonical")
    if not ctx.fs().exists(canonical_bin):
        return bs_fail(ctx, "missing canonical comptime-with output")
    let canonical_run = bs_run_binary_capture(ctx, canonical_bin, "build-w-comptime-with-canonical-run", 120000)
    if canonical_run.rc != 0: return canonical_run.rc
    rc = bs_assert_contains(ctx, canonical_run.stdout, "canonical comptime with", "build_w_comptime_with_canonical")
    if rc != 0: return rc

    let shorthand_dir = bs_join(base_dir, "shorthand")
    rc = bs_write_project_manifest(ctx, shorthand_dir, "comptimewithshorthand")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(shorthand_dir, "src/main.w"), "fn main:\n    print(\"shorthand comptime with\")\n", ctx.target_name(), "shorthand source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(shorthand_dir, "build.w"), "use std.build\n\ncomptime with BuildCtx:\npub fn build -> Build:\n    ctx.new_build().executable(\"shorthand\", \"src/main.w\")\n", ctx.target_name(), "shorthand comptime-with build.w")
    if rc != 0: return rc
    let shorthand = bs_build_w_expect_success(ctx, compiler_path, shorthand_dir, "build-w-comptime-with-shorthand", bs_blob_to_args(bs_argv_append("", "build")))
    if shorthand.rc != 0: return shorthand.rc
    let shorthand_bin = bs_join(shorthand_dir, "out/bin/shorthand")
    if not ctx.fs().exists(shorthand_bin):
        return bs_fail(ctx, "missing shorthand comptime-with output")
    let shorthand_run = bs_run_binary_capture(ctx, shorthand_bin, "build-w-comptime-with-shorthand-run", 120000)
    if shorthand_run.rc != 0: return shorthand_run.rc
    rc = bs_assert_contains(ctx, shorthand_run.stdout, "shorthand comptime with", "build_w_comptime_with_shorthand")
    if rc != 0: return rc

    let duplicate_dir = bs_join(base_dir, "duplicate_default")
    rc = bs_write_project_manifest(ctx, duplicate_dir, "comptimewithduplicate")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(duplicate_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", ctx.target_name(), "duplicate source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(duplicate_dir, "build.w"), "use std.build\n\ncomptime with BuildCtx, ActionCtx:\npub fn build -> Build:\n    ctx.new_build().executable(\"duplicate\", \"src/main.w\")\n", ctx.target_name(), "duplicate comptime-with build.w")
    if rc != 0: return rc
    let duplicate = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-comptime-with-duplicate", bs_blob_to_args(bs_argv_append("", "build")), 120000, duplicate_dir)
    if duplicate.rc == 0:
        return bs_fail(ctx, "duplicate comptime-with default binding unexpectedly succeeded")
    bs_assert_contains(ctx, duplicate.stderr, "duplicate capability binding", "build_w_comptime_with_duplicate")

fn bs_check_build_w_workspace_api(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let file_dir = bs_join(base_dir, "file_workspace")
    var rc = bs_write_project_manifest(ctx, file_dir, "workspacefile")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(file_dir, "src/workspace_file.w"), "fn main:\n    print(\"workspace file\")\n", ctx.target_name(), "workspace file source")
    if rc != 0: return rc
    let file_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let ws = ctx.create_workspace(\"workspace-file\")\n" ++
        "    if ws.name() != \"workspace-file\":\n" ++
        "        ctx.diagnostics().error(\"workspace name mismatch\")\n" ++
        "    ws.add_file(\"src/workspace_file.w\")\n" ++
        "    var opts = ws.options()\n" ++
        "    opts.output_path = \"out/bin/workspace-file\"\n" ++
        "    ws.set_options(opts)\n" ++
        "    let result = ws.compile()\n" ++
        "    if result.rc != 0:\n" ++
        "        ctx.diagnostics().error(\"workspace file compile failed\")\n" ++
        "    if result.status != BuildStatus.ok:\n" ++
        "        ctx.diagnostics().error(\"workspace file status mismatch\")\n" ++
        "    if result.workspace_name != \"workspace-file\":\n" ++
        "        ctx.diagnostics().error(\"workspace file result name mismatch\")\n" ++
        "    if result.artifacts.len() != 1:\n" ++
        "        ctx.diagnostics().error(\"workspace file artifact count mismatch\")\n" ++
        "    else if result.artifacts.get(0).path != \"out/bin/workspace-file\":\n" ++
        "        ctx.diagnostics().error(\"workspace file artifact path mismatch\")\n" ++
        "    ctx.new_build().command(\"run-workspace-file\", \"out/bin/workspace-file\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(file_dir, "build.w"), file_build, ctx.target_name(), "workspace file build.w")
    if rc != 0: return rc
    let file_result = bs_build_w_expect_success(ctx, compiler_path, file_dir, "build-w-workspace-file", bs_blob_to_args(bs_argv_append("", "build")))
    if file_result.rc != 0: return file_result.rc
    rc = bs_expect_file_contains(ctx, bs_join(file_dir, "out/command/run-workspace-file/stdout.txt"), "workspace file", "build_w_workspace_file")
    if rc != 0: return rc
    if not ctx.fs().exists(bs_join(file_dir, "out/bin/workspace-file")):
        return bs_fail(ctx, "missing workspace file compile output")

    let string_dir = bs_join(base_dir, "string_workspace")
    rc = bs_write_project_manifest(ctx, string_dir, "workspacestring")
    if rc != 0: return rc
    let string_source = bs_with_string_literal("fn main:\n    print(\"workspace string\")\n")
    let string_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let ws = ctx.create_workspace(\"workspace-string\")\n" ++
        "    ws.add_string(\"generated/workspace_string.w\", " ++ string_source ++ ")\n" ++
        "    var opts = ws.options()\n" ++
        "    opts.output_path = \"out/bin/workspace-string\"\n" ++
        "    ws.set_options(opts)\n" ++
        "    let result = ws.compile()\n" ++
        "    if result.status != BuildStatus.ok:\n" ++
        "        ctx.diagnostics().error(\"workspace string status mismatch\")\n" ++
        "    if result.artifacts.len() != 1:\n" ++
        "        ctx.diagnostics().error(\"workspace string artifact count mismatch\")\n" ++
        "    ctx.new_build().command(\"run-workspace-string\", \"out/bin/workspace-string\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(string_dir, "build.w"), string_build, ctx.target_name(), "workspace string build.w")
    if rc != 0: return rc
    let string_result = bs_build_w_expect_success(ctx, compiler_path, string_dir, "build-w-workspace-string", bs_blob_to_args(bs_argv_append("", "build")))
    if string_result.rc != 0: return string_result.rc
    rc = bs_expect_file_contains(ctx, bs_join(string_dir, "out/command/run-workspace-string/stdout.txt"), "workspace string", "build_w_workspace_string")
    if rc != 0: return rc

    let message_dir = bs_join(base_dir, "workspace_message_complete")
    rc = bs_write_project_manifest(ctx, message_dir, "workspacemessage")
    if rc != 0: return rc
    let message_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let ws = ctx.create_workspace(\"message-complete\")\n" ++
        "    ws.add_string(\"src/message_complete.w\", \"fn main:\\n    print(\\\"workspace message\\\")\\n\")\n" ++
        "    var opts = ws.options()\n" ++
        "    opts.output_path = \"out/bin/message-complete\"\n" ++
        "    ws.set_options(opts)\n" ++
        "    ws.begin_intercept()\n" ++
        "    let result = ws.compile()\n" ++
        "    if result.rc != 0:\n" ++
        "        ctx.diagnostics().error(\"workspace message compile failed\")\n" ++
        "    let pre_parse_envelope = ws.wait_for_message()\n" ++
        "    var saw_pre_parse = false\n" ++
        "    match pre_parse_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_pre_parse = phase == CompilerPhase.pre_parse\n" ++
        "        _ => saw_pre_parse = false\n" ++
        "    if not saw_pre_parse:\n" ++
        "        ctx.diagnostics().error(\"workspace pre-parse phase message missing\")\n" ++
        "    let parsed_envelope = ws.wait_for_message()\n" ++
        "    var saw_parsed = false\n" ++
        "    match parsed_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_parsed = phase == CompilerPhase.parsed\n" ++
        "        _ => saw_parsed = false\n" ++
        "    if not saw_parsed:\n" ++
        "        ctx.diagnostics().error(\"workspace parsed phase message missing\")\n" ++
        "    let pre_typecheck_envelope = ws.wait_for_message()\n" ++
        "    var saw_pre_typecheck = false\n" ++
        "    match pre_typecheck_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_pre_typecheck = phase == CompilerPhase.pre_typecheck\n" ++
        "        _ => saw_pre_typecheck = false\n" ++
        "    if not saw_pre_typecheck:\n" ++
        "        ctx.diagnostics().error(\"workspace pre-typecheck phase message missing\")\n" ++
        "    let type_phase_envelope = ws.wait_for_message()\n" ++
        "    var saw_type_phase = false\n" ++
        "    match type_phase_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_type_phase = phase == CompilerPhase.typechecked\n" ++
        "        _ => saw_type_phase = false\n" ++
        "    if not saw_type_phase:\n" ++
        "        ctx.diagnostics().error(\"workspace typechecked phase message missing\")\n" ++
        "    let type_envelope = ws.wait_for_message()\n" ++
        "    var saw_typechecked = false\n" ++
        "    match type_envelope.message:\n" ++
        "        CompilerMessage.Typechecked(decls) =>\n" ++
        "            for decl in decls:\n" ++
        "                if decl.name == \"main\" and decl.kind == DeclKind.function and decl.source.file.ends_with(\"src/message_complete.w\"):\n" ++
        "                    saw_typechecked = true\n" ++
        "        _ => saw_typechecked = false\n" ++
        "    if not saw_typechecked:\n" ++
        "        ctx.diagnostics().error(\"workspace typechecked message missing main declaration\")\n" ++
        "    let lowered_envelope = ws.wait_for_message()\n" ++
        "    var saw_lowered = false\n" ++
        "    match lowered_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_lowered = phase == CompilerPhase.lowered_to_mir\n" ++
        "        _ => saw_lowered = false\n" ++
        "    if not saw_lowered:\n" ++
        "        ctx.diagnostics().error(\"workspace lowered-to-mir phase message missing\")\n" ++
        "    let pre_codegen_envelope = ws.wait_for_message()\n" ++
        "    var saw_pre_codegen = false\n" ++
        "    match pre_codegen_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_pre_codegen = phase == CompilerPhase.pre_codegen\n" ++
        "        _ => saw_pre_codegen = false\n" ++
        "    if not saw_pre_codegen:\n" ++
        "        ctx.diagnostics().error(\"workspace pre-codegen phase message missing\")\n" ++
        "    let codegen_envelope = ws.wait_for_message()\n" ++
        "    var saw_codegen = false\n" ++
        "    match codegen_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_codegen = phase == CompilerPhase.codegen_done\n" ++
        "        _ => saw_codegen = false\n" ++
        "    if not saw_codegen:\n" ++
        "        ctx.diagnostics().error(\"workspace codegen-done phase message missing\")\n" ++
        "    let artifact_envelope = ws.wait_for_message()\n" ++
        "    var saw_artifact = false\n" ++
        "    match artifact_envelope.message:\n" ++
        "        CompilerMessage.Artifact(artifact) => saw_artifact = artifact.kind == ArtifactKind.executable and artifact.path == \"out/bin/message-complete\"\n" ++
        "        _ => saw_artifact = false\n" ++
        "    if not saw_artifact:\n" ++
        "        ctx.diagnostics().error(\"workspace artifact message missing\")\n" ++
        "    let phase_envelope = ws.wait_for_message()\n" ++
        "    var saw_phase = false\n" ++
        "    match phase_envelope.message:\n" ++
        "        CompilerMessage.Phase(phase) => saw_phase = phase == CompilerPhase.complete\n" ++
        "        _ => saw_phase = false\n" ++
        "    if not saw_phase:\n" ++
        "        ctx.diagnostics().error(\"workspace complete phase message missing\")\n" ++
        "    let envelope = ws.wait_for_message()\n" ++
        "    var saw_complete = false\n" ++
        "    match envelope.message:\n" ++
        "        CompilerMessage.Complete(done) => saw_complete = done.rc == 0 and done.workspace_name == \"message-complete\"\n" ++
        "        _ => saw_complete = false\n" ++
        "    if not saw_complete:\n" ++
        "        ctx.diagnostics().error(\"workspace complete message missing\")\n" ++
        "    let closed_envelope = ws.wait_for_message()\n" ++
        "    var saw_closed = false\n" ++
        "    match closed_envelope.message:\n" ++
        "        CompilerMessage.Error(code, message, _) => saw_closed = code == 1 and message == \"Workspace message queue is closed\"\n" ++
        "        _ => saw_closed = false\n" ++
        "    if not saw_closed:\n" ++
        "        ctx.diagnostics().error(\"workspace closed queue message missing\")\n" ++
        "    ws.end_intercept()\n" ++
        "    ctx.new_build().command(\"run-message-complete\", \"out/bin/message-complete\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(message_dir, "build.w"), message_build, ctx.target_name(), "workspace message build.w")
    if rc != 0: return rc
    let message_result = bs_build_w_expect_success(ctx, compiler_path, message_dir, "build-w-workspace-message-complete", bs_blob_to_args(bs_argv_append("", "build")))
    if message_result.rc != 0: return message_result.rc
    rc = bs_expect_file_contains(ctx, bs_join(message_dir, "out/command/run-message-complete/stdout.txt"), "workspace message", "build_w_workspace_message_complete")
    if rc != 0: return rc

    let open_intercept_dir = bs_join(base_dir, "workspace_intercept_open")
    rc = bs_write_project_manifest(ctx, open_intercept_dir, "workspaceopen")
    if rc != 0: return rc
    let open_intercept_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let ws = ctx.create_workspace(\"open-intercept\")\n" ++
        "    ws.begin_intercept()\n" ++
        "    ctx.new_build()\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(open_intercept_dir, "build.w"), open_intercept_build, ctx.target_name(), "workspace open intercept build.w")
    if rc != 0: return rc
    let open_intercept_result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-workspace-intercept-open", bs_blob_to_args(bs_argv_append("", "build")), 120000, open_intercept_dir)
    if open_intercept_result.rc == 0:
        ctx.diagnostics().error("error: build_w_workspace_intercept_open unexpectedly succeeded")
    rc = bs_assert_contains(ctx, open_intercept_result.stderr, "incomplete workspace interception for 'open-intercept'", "build_w_workspace_intercept_open")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, open_intercept_result.stderr, "workspace did not reach a terminal message", "build_w_workspace_intercept_open")
    if rc != 0: return rc

    let unread_intercept_dir = bs_join(base_dir, "workspace_intercept_unread")
    rc = bs_write_project_manifest(ctx, unread_intercept_dir, "workspaceunread")
    if rc != 0: return rc
    let unread_intercept_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let ws = ctx.create_workspace(\"unread-intercept\")\n" ++
        "    ws.add_string(\"src/unread.w\", \"fn main:\\n    print(\\\"unread\\\")\\n\")\n" ++
        "    var opts = ws.options()\n" ++
        "    opts.output_path = \"out/bin/unread\"\n" ++
        "    ws.set_options(opts)\n" ++
        "    ws.begin_intercept()\n" ++
        "    let result = ws.compile()\n" ++
        "    if result.rc != 0:\n" ++
        "        ctx.diagnostics().error(\"workspace unread compile failed\")\n" ++
        "    ctx.new_build()\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(unread_intercept_dir, "build.w"), unread_intercept_build, ctx.target_name(), "workspace unread intercept build.w")
    if rc != 0: return rc
    let unread_intercept_result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-workspace-intercept-unread", bs_blob_to_args(bs_argv_append("", "build")), 120000, unread_intercept_dir)
    if unread_intercept_result.rc == 0:
        ctx.diagnostics().error("error: build_w_workspace_intercept_unread unexpectedly succeeded")
    rc = bs_assert_contains(ctx, unread_intercept_result.stderr, "incomplete workspace interception for 'unread-intercept'", "build_w_workspace_intercept_unread")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, unread_intercept_result.stderr, "terminal message was not consumed", "build_w_workspace_intercept_unread")
    if rc != 0: return rc

    let end_unread_dir = bs_join(base_dir, "workspace_intercept_end_unread")
    rc = bs_write_project_manifest(ctx, end_unread_dir, "workspaceendunread")
    if rc != 0: return rc
    let end_unread_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let ws = ctx.create_workspace(\"end-unread-intercept\")\n" ++
        "    ws.add_string(\"src/end_unread.w\", \"fn main:\\n    print(\\\"end unread\\\")\\n\")\n" ++
        "    var opts = ws.options()\n" ++
        "    opts.output_path = \"out/bin/end-unread\"\n" ++
        "    ws.set_options(opts)\n" ++
        "    ws.begin_intercept()\n" ++
        "    let result = ws.compile()\n" ++
        "    if result.rc != 0:\n" ++
        "        ctx.diagnostics().error(\"workspace end unread compile failed\")\n" ++
        "    ws.end_intercept()\n" ++
        "    ctx.new_build()\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(end_unread_dir, "build.w"), end_unread_build, ctx.target_name(), "workspace end unread intercept build.w")
    if rc != 0: return rc
    let end_unread_result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-workspace-intercept-end-unread", bs_blob_to_args(bs_argv_append("", "build")), 120000, end_unread_dir)
    if end_unread_result.rc == 0:
        ctx.diagnostics().error("error: build_w_workspace_intercept_end_unread unexpectedly succeeded")
    rc = bs_assert_contains(ctx, end_unread_result.stderr, "Workspace.end_intercept called before terminal message was consumed", "build_w_workspace_intercept_end_unread")
    if rc != 0: return rc

    let enum_dir = bs_join(base_dir, "comptime_payload_enum")
    rc = bs_write_project_manifest(ctx, enum_dir, "workspaceenum")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(enum_dir, "src/main.w"), "fn main:\n    print(\"workspace enum\")\n", ctx.target_name(), "workspace enum source")
    if rc != 0: return rc
    let enum_build =
        "use std.build\n\n" ++
        "enum LocalMessage:\n" ++
        "    Phase(i32)\n" ++
        "    Complete(str)\n\n" ++
        "comptime fn local_message -> LocalMessage:\n" ++
        "    Phase(7)\n\n" ++
        "comptime fn public_message -> CompilerMessage:\n" ++
        "    let unknown = SourceSpan { file: \"\", start: -1, end: -1, line: -1, column: -1 }\n" ++
        "    let summary = DeclSummary { version: 1, kind: DeclKind.function, module_name: \"main\", name: \"build\", qualified_name: \"main.build\", public_value: true, docs: \"\", type_text: \"fn\", return_type_text: \"Build\", param_count: 0, generic_param_count: 0, receiver_type_text: \"\", source: unknown, notes: Vec.new() }\n" ++
        "    var decls: Vec[DeclSummary] = Vec.new()\n" ++
        "    decls.push(summary)\n" ++
        "    CompilerMessage.Typechecked(decls)\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    var matched = false\n" ++
        "    match local_message():\n" ++
        "        Phase(n) => matched = n == 7\n" ++
        "        Complete(_) => matched = false\n" ++
        "    if not matched:\n" ++
        "        ctx.diagnostics().error(\"payload enum comptime match failed\")\n" ++
        "    var public_matched = false\n" ++
        "    match public_message():\n" ++
        "        CompilerMessage.Typechecked(decls) => public_matched = decls.len() == 1 and decls.get(0).name == \"build\"\n" ++
        "        _ => public_matched = false\n" ++
        "    if not public_matched:\n" ++
        "        ctx.diagnostics().error(\"public compiler message comptime match failed\")\n" ++
        "    ctx.new_build().executable(\"workspace-enum\", \"src/main.w\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(enum_dir, "build.w"), enum_build, ctx.target_name(), "workspace enum build.w")
    if rc != 0: return rc
    let enum_result = bs_build_w_expect_success(ctx, compiler_path, enum_dir, "build-w-comptime-payload-enum", bs_blob_to_args(bs_argv_append("", "build")))
    if enum_result.rc != 0: return enum_result.rc
    let enum_bin = bs_join(enum_dir, "out/bin/workspace-enum")
    if not ctx.fs().exists(enum_bin):
        return bs_fail(ctx, "missing workspace enum output")
    let enum_run = bs_run_binary_capture(ctx, enum_bin, "build-w-comptime-payload-enum-run", 120000)
    if enum_run.rc != 0: return enum_run.rc
    rc = bs_assert_contains(ctx, enum_run.stdout, "workspace enum", "build_w_comptime_payload_enum")
    if rc != 0: return rc

    let current_dir = bs_join(base_dir, "current_workspace_before_create")
    rc = bs_write_project_manifest(ctx, current_dir, "workspacecurrent")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(current_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", ctx.target_name(), "workspace current source")
    if rc != 0: return rc
    let current_build =
        "use std.build\n\n" ++
        "comptime with BuildCtx as ctx:\n" ++
        "pub fn build -> Build:\n" ++
        "    let _ = ctx.current_workspace()\n" ++
        "    ctx.new_build().executable(\"should-not-build\", \"src/main.w\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(current_dir, "build.w"), current_build, ctx.target_name(), "workspace current build.w")
    if rc != 0: return rc
    let current_result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-workspace-current-before-create", bs_blob_to_args(bs_argv_append("", "build")), 120000, current_dir)
    if current_result.rc == 0:
        return bs_fail(ctx, "current_workspace before create unexpectedly succeeded")
    bs_assert_contains(ctx, current_result.stderr, "current_workspace called before create_workspace", "build_w_workspace_current")

fn bs_check_build_w_test_targets(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let single_dir = bs_join(base_dir, "single")
    var rc = bs_write_project_manifest(ctx, single_dir, "buildwtest")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(single_dir, "src/build_test.w"), "use c_import(\"answer.h\")\n\n@[test]\nfn build_w_test_target_uses_settings:\n    assert(ANSWER == 42)\n", ctx.target_name(), "test source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(single_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w test target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", ctx.target_name(), "test header")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(single_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Test, \"configured-test\", \"src/build_test.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", ctx.target_name(), "test build.w")
    if rc != 0: return rc
    let single_result = bs_build_w_expect_success(ctx, compiler_path, single_dir, "build-w-test-target", bs_blob_to_args(bs_argv_append("", "build")))
    if single_result.rc != 0: return single_result.rc
    rc = bs_assert_contains(ctx, single_result.stdout, "ok: 1 test passed", "build_w_test_target")
    if rc != 0: return rc

    let glob_dir = bs_join(base_dir, "glob")
    rc = bs_write_project_manifest(ctx, glob_dir, "buildwtestglob")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(glob_dir, "tests/first.w"), "use c_import(\"answer.h\")\n\n@[test]\nfn first_build_w_glob_test_uses_settings:\n    assert(ANSWER == 42)\n", ctx.target_name(), "glob first")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(glob_dir, "tests/second.w"), "@[test]\nfn second_build_w_glob_test_runs:\n    assert(2 + 2 == 4)\n", ctx.target_name(), "glob second")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(glob_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w test glob target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", ctx.target_name(), "glob header")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(glob_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Test, \"glob-tests\", \"tests/*.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", ctx.target_name(), "glob build.w")
    if rc != 0: return rc
    let glob_result = bs_build_w_expect_success(ctx, compiler_path, glob_dir, "build-w-test-target-glob", bs_blob_to_args(bs_argv_append("", "build")))
    if glob_result.rc != 0: return glob_result.rc
    bs_assert_contains(ctx, glob_result.stdout, "ok: 2 files passed in build.w test target glob-tests", "build_w_test_target_glob")

fn bs_check_build_w_library_and_targets(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let lib_dir = bs_join(base_dir, "library")
    var rc = bs_write_project_manifest(ctx, lib_dir, "buildwlib")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(lib_dir, "src/lib.w"), "use c_import(\"answer.h\")\n\npub fn answer_from_header -> i32:\n    ANSWER\n", ctx.target_name(), "library source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(lib_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w library target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", ctx.target_name(), "library header")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(lib_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Library, \"configured\", \"src/lib.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", ctx.target_name(), "library build.w")
    if rc != 0: return rc
    let lib_result = bs_build_w_expect_success(ctx, compiler_path, lib_dir, "build-w-library-target", bs_blob_to_args(bs_argv_append("", "build")))
    if lib_result.rc != 0: return lib_result.rc
    let archive = bs_join(lib_dir, "out/lib/libconfigured.a")
    if not ctx.fs().exists(archive):
        ctx.diagnostics().error("error: build_w_library_target missing archive: " ++ archive)
        return 1
    rc = bs_build_w_nm_smoke(ctx, archive, "build-w-library-nm")
    if rc != 0: return rc

    let host_dir = bs_join(base_dir, "host")
    rc = bs_write_project_manifest(ctx, host_dir, "buildwhosttarget")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(host_dir, "src/main.w"), "fn main:\n    print(\"explicit host target\")\n", ctx.target_name(), "host source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(host_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(ctx: BuildCtx) -> Build:\n    var host = BuildTarget.native\n    if os() == \"Macos\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.darwin_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.darwin_x86_64\n    else if os() == \"Linux\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.linux_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.linux_x86_64\n    else if os() == \"Windows\":\n        if arch() == \"x86_64\":\n            host = BuildTarget.windows_x86_64\n    var target = target_new(.Executable, \"host-target\", \"src/main.w\")\n    target = target.target(host)\n    var out = ctx.new_build()\n    out.add_target(target)\n", ctx.target_name(), "host build.w")
    if rc != 0: return rc
    let host_result = bs_build_w_expect_success(ctx, compiler_path, host_dir, "build-w-explicit-host-target", bs_blob_to_args(bs_argv_append("", "build")))
    if host_result.rc != 0: return host_result.rc
    let host_bin = bs_join(host_dir, "out/bin/host-target")
    if not ctx.fs().exists(host_bin):
        ctx.diagnostics().error("error: build_w_explicit_host_target missing binary: " ++ host_bin)
        return 1
    let host_run = bs_run_binary_capture(ctx, host_bin, "build-w-explicit-host-run", 120000)
    if host_run.rc != 0: return host_run.rc
    rc = bs_assert_contains(ctx, host_run.stdout, "explicit host target", "build_w_explicit_host_target")
    if rc != 0: return rc

    let non_native_dir = bs_join(base_dir, "non_native")
    rc = bs_write_project_manifest(ctx, non_native_dir, "buildwnonnative")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(non_native_dir, "src/main.w"), "fn main:\n    print(\"wrong target\")\n", ctx.target_name(), "non-native source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(non_native_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(ctx: BuildCtx) -> Build:\n    var non_native = BuildTarget.linux_x86_64\n    if os() == \"Linux\" and arch() == \"x86_64\":\n        non_native = BuildTarget.darwin_aarch64\n    var target = target_new(.Executable, \"wrong-target\", \"src/main.w\")\n    target = target.target(non_native)\n    var out = ctx.new_build()\n    out.add_target(target)\n", ctx.target_name(), "non-native build.w")
    if rc != 0: return rc
    let non_native_result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-non-native-target", bs_blob_to_args(bs_argv_append("", "build")), 120000, non_native_dir)
    if non_native_result.rc == 0:
        ctx.diagnostics().error("error: build_w_non_native_target unexpectedly succeeded")
        return 1
    bs_assert_contains(ctx, non_native_result.stderr, "build.w cross-target platform", "build_w_non_native_target")

fn bs_check_build_w_generated_source(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let gen_dir = bs_join(base_dir, "generated")
    var rc = bs_write_project_manifest(ctx, gen_dir, "buildwgenerated")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(gen_dir, "templates/generated_main.w"), "fn main:\n    print(\"generated source\")\n", ctx.target_name(), "generated template")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(gen_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    let emitter = ctx.source_emitter()\n    let source = emitter.generated_source(\"out/gen/generated_main.w\", fs.read_text(\"templates/generated_main.w\"))\n    var generated = ctx.new_build()\n    generated = generated.add_generated_source(source)\n    generated.executable(\"generated-app\", \"out/gen/generated_main.w\")\n", ctx.target_name(), "generated build.w")
    if rc != 0: return rc
    let gen_result = bs_build_w_expect_success(ctx, compiler_path, gen_dir, "build-w-generated-source", bs_blob_to_args(bs_argv_append("", "build")))
    if gen_result.rc != 0: return gen_result.rc
    let generated_source = bs_join(gen_dir, "out/gen/generated_main.w")
    let generated_bin = bs_join(gen_dir, "out/bin/generated-app")
    if not ctx.fs().exists(generated_source) or not ctx.fs().exists(generated_bin):
        ctx.diagnostics().error("error: build_w_generated_source missing generated source or binary")
        return 1
    let run_result = bs_run_binary_capture(ctx, generated_bin, "build-w-generated-source-run", 120000)
    if run_result.rc != 0: return run_result.rc
    rc = bs_assert_contains(ctx, run_result.stdout, "generated source", "build_w_generated_source")
    if rc != 0: return rc

    let invalid_dir = bs_join(base_dir, "invalid_generated")
    rc = bs_write_project_manifest(ctx, invalid_dir, "buildwinvalidgenerated")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(invalid_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", ctx.target_name(), "invalid generated source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(invalid_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var generated = ctx.new_build()\n    generated = generated.generated_source(\"../outside.w\", \"fn main: print(\\\"bad\\\")\n\")\n    generated.executable(\"invalid-generated\", \"src/main.w\")\n", ctx.target_name(), "invalid generated build.w")
    if rc != 0: return rc
    let invalid_result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-invalid-generated-source", bs_blob_to_args(bs_argv_append("", "build")), 120000, invalid_dir)
    if invalid_result.rc == 0:
        ctx.diagnostics().error("error: build_w_invalid_generated_source unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, invalid_result.stderr, "invalid build.w generated source path", "build_w_invalid_generated_source")
    if rc != 0: return rc

    let toolfs_ok_dir = bs_join(base_dir, "toolfs_ok")
    rc = bs_write_project_manifest(ctx, toolfs_ok_dir, "buildwtoolfsok")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_ok_dir, "src/main.w"), "fn main:\n    print(\"toolfs ok\")\n", ctx.target_name(), "toolfs ok source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_ok_dir, "fixtures/tree/a.txt"), "tree", ctx.target_name(), "toolfs ok tree fixture")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_ok_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    assert(fs.mkdir_all(\"out/toolfs\") == 0)\n    assert(fs.write_text(\"out/toolfs/value.txt\", \"inside\") == 0)\n    assert(fs.read_text(\"out/toolfs/value.txt\") == \"inside\")\n    let files = fs.list_files(\"fixtures/tree\")\n    assert(files.len() == 1)\n    assert(files.get(0) == \"fixtures/tree/a.txt\")\n    assert(fs.copy_file(\"fixtures/tree/a.txt\", \"out/toolfs/copied-file.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/copied-file.txt\") == \"tree\")\n    assert(fs.chmod(\"out/toolfs/copied-file.txt\", 0o644) == 0)\n    assert(fs.rename(\"out/toolfs/copied-file.txt\", \"out/toolfs/renamed-file.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/renamed-file.txt\") == \"tree\")\n    assert(fs.copy_tree(\"fixtures/tree\", \"out/toolfs/tree-copy\") == 0)\n    assert(fs.read_text(\"out/toolfs/tree-copy/a.txt\") == \"tree\")\n    assert(fs.symlink(\"fixtures/tree/a.txt\", \"out/toolfs/link-a.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/link-a.txt\") == \"tree\")\n    assert(fs.remove_tree(\"out/toolfs/tree-copy\") == 0)\n    assert(not fs.exists(\"out/toolfs/tree-copy/a.txt\"))\n    ctx.new_build().executable(\"toolfs-ok\", \"src/main.w\")\n", ctx.target_name(), "toolfs ok build.w")
    if rc != 0: return rc
    let toolfs_ok = bs_build_w_expect_success(ctx, compiler_path, toolfs_ok_dir, "build-w-toolfs-ok", bs_blob_to_args(bs_argv_append("", "build")))
    if toolfs_ok.rc != 0: return toolfs_ok.rc
    if not ctx.fs().exists(bs_join(toolfs_ok_dir, "out/toolfs/value.txt")):
        ctx.diagnostics().error("error: build_w_toolfs_ok missing sandboxed ToolFs output")
        return 1

    let toolfs_escape_dir = bs_join(base_dir, "toolfs_escape")
    rc = bs_write_project_manifest(ctx, toolfs_escape_dir, "buildwtoolfsescape")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_escape_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", ctx.target_name(), "toolfs escape source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_escape_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let _ = ctx.fs().read_text(\"../outside.txt\")\n    ctx.new_build().executable(\"toolfs-escape\", \"src/main.w\")\n", ctx.target_name(), "toolfs escape build.w")
    if rc != 0: return rc
    let toolfs_escape = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-toolfs-escape", bs_blob_to_args(bs_argv_append("", "build")), 120000, toolfs_escape_dir)
    if toolfs_escape.rc == 0:
        ctx.diagnostics().error("error: build_w_toolfs_escape unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, toolfs_escape.stderr, "ToolFs path escapes project root", "build_w_toolfs_escape")
    if rc != 0: return rc

    let toolfs_file_escape_dir = bs_join(base_dir, "toolfs_file_escape")
    rc = bs_write_project_manifest(ctx, toolfs_file_escape_dir, "buildwtoolfsfileescape")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_file_escape_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", ctx.target_name(), "toolfs file escape source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_file_escape_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let _ = ctx.fs().copy_file(\"../outside.txt\", \"out/bad.txt\")\n    ctx.new_build().executable(\"toolfs-file-escape\", \"src/main.w\")\n", ctx.target_name(), "toolfs file escape build.w")
    if rc != 0: return rc
    let toolfs_file_escape = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-toolfs-file-escape", bs_blob_to_args(bs_argv_append("", "build")), 120000, toolfs_file_escape_dir)
    if toolfs_file_escape.rc == 0:
        ctx.diagnostics().error("error: build_w_toolfs_file_escape unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, toolfs_file_escape.stderr, "ToolFs path escapes project root", "build_w_toolfs_file_escape")
    if rc != 0: return rc

    let toolfs_tree_escape_dir = bs_join(base_dir, "toolfs_tree_escape")
    rc = bs_write_project_manifest(ctx, toolfs_tree_escape_dir, "buildwtoolfstreeescape")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_tree_escape_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", ctx.target_name(), "toolfs tree escape source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_tree_escape_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let _ = ctx.fs().copy_tree(\"../outside\", \"out/bad\")\n    ctx.new_build().executable(\"toolfs-tree-escape\", \"src/main.w\")\n", ctx.target_name(), "toolfs tree escape build.w")
    if rc != 0: return rc
    let toolfs_tree_escape = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-toolfs-tree-escape", bs_blob_to_args(bs_argv_append("", "build")), 120000, toolfs_tree_escape_dir)
    if toolfs_tree_escape.rc == 0:
        ctx.diagnostics().error("error: build_w_toolfs_tree_escape unexpectedly succeeded")
        return 1
    bs_assert_contains(ctx, toolfs_tree_escape.stderr, "ToolFs path escapes project root", "build_w_toolfs_tree_escape")

fn bs_graph_build_file() -> str:
    "use std.build\n\n" ++
    "pub fn build(ctx: BuildCtx) -> Build:\n" ++
    "    var out = ctx.new_build().executable(\"one\", \"src/one.w\")\n" ++
    "    out = out.executable(\"two\", \"src/two.w\")\n" ++
    "    out = out.object(\"one-o\", \"src/one.w\")\n" ++
    "    out = out.archive(\"one-a\", \"src/one.w\")\n" ++
    "    out = out.generated_source(\"out/tmp/a.txt\", \"same\")\n" ++
    "    out = out.generated_source(\"out/tmp/b.txt\", \"same\")\n" ++
    "    out = out.binary_compare(\"bytes-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n" ++
    "    out = out.fixpoint_compare(\"fix-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n" ++
    "    var rsp = target_new(.GenerateResponseFile, \"rsp\", \"\").output(\"out/tmp/args.rsp\")\n" ++
    "    rsp = rsp.arg(\"-L/some path\")\n" ++
    "    rsp = rsp.arg(\"plain\")\n" ++
    "    out = out.add_target(rsp)\n" ++
    "    out = out.compile_c_object(\"helper-o\", \"runtime/helper.c\", \"out/lib/helper.o\")\n" ++
    "    var archive = target_new(.CreateStaticArchive, \"helper-a\", \"\").output(\"out/lib/libhelper.a\")\n" ++
    "    archive = archive.input(\"out/lib/helper.o\")\n" ++
    "    out = out.add_target(archive)\n" ++
    "    var embedded = target_new(.EmbedObjectFiles, \"embed-helper\", \"\").output(\"out/lib/embedded_helper.s\")\n" ++
    "    embedded = embedded.input(\"out/lib/helper.o\")\n" ++
    "    embedded = embedded.arg(\"helper_o\")\n" ++
    "    out = out.add_target(embedded)\n" ++
    "    out = out.compile_asm_object(\"embedded-helper-o\", \"out/lib/embedded_helper.s\", \"out/lib/embedded_helper.o\")\n" ++
    "    out = out.copy_file(\"helper-copy\", \"runtime/helper.c\", \"out/copied/helper.c\")\n" ++
    "    var copy_target = target_new(.CopyTree, \"runtime-copy\", \"runtime\").output(\"out/runtime\")\n" ++
    "    copy_target = copy_target.input(\"helper.c\")\n" ++
    "    out = out.add_target(copy_target)\n" ++
    "    var promote = target_new(.PromoteTreeIfVerified, \"promote-runtime\", \"out/runtime\").output(\"promoted-runtime\")\n" ++
    "    promote = promote.input(\"helper.c\")\n" ++
    "    promote = promote.dep(\"runtime-copy\")\n" ++
    "    out = out.add_target(promote)\n" ++
    "    var corpus = target_new(.RunCorpusTest, \"corpus\", \"out/bin/two\")\n" ++
    "    corpus = corpus.dep(\"two\")\n" ++
    "    out = out.add_target(corpus)\n" ++
    "    var command = target_new(.Command, \"run-two\", \"out/bin/two\")\n" ++
    "    command = command.dep(\"two\")\n" ++
    "    out = out.add_target(command)\n" ++
    "    var install = target_new(.Install, \"install-two\", \"out/bin/two\").output(\"out/install/two\")\n" ++
    "    install = install.dep(\"two\")\n" ++
    "    install = install.arg(\"0755\")\n" ++
    "    out = out.add_target(install)\n" ++
    "    var aggregate = target_new(.Group, \"toolchain\", \"\")\n" ++
    "    aggregate = aggregate.dep(\"bytes-same\")\n" ++
    "    aggregate = aggregate.dep(\"fix-same\")\n" ++
    "    aggregate = aggregate.dep(\"rsp\")\n" ++
    "    aggregate = aggregate.dep(\"one-o\")\n" ++
    "    aggregate = aggregate.dep(\"one-a\")\n" ++
    "    aggregate = aggregate.dep(\"helper-a\")\n" ++
    "    aggregate = aggregate.dep(\"embedded-helper-o\")\n" ++
    "    aggregate = aggregate.dep(\"helper-copy\")\n" ++
    "    aggregate = aggregate.dep(\"promote-runtime\")\n" ++
    "    aggregate = aggregate.dep(\"corpus\")\n" ++
    "    aggregate = aggregate.dep(\"run-two\")\n" ++
    "    aggregate = aggregate.dep(\"install-two\")\n" ++
    "    out = out.add_target(aggregate)\n" ++
    "    out.default(\"toolchain\")\n"

fn bs_require_case_file(ctx: ActionCtx, case_dir: str, rel_path: str, label: str) -> i32:
    let path = bs_join(case_dir, rel_path)
    if ctx.fs().exists(path):
        return 0
    ctx.diagnostics().error("error: " ++ ctx.target_name() ++ " " ++ label ++ " missing expected output: " ++ rel_path)
    1

fn bs_forbid_case_file(ctx: ActionCtx, case_dir: str, rel_path: str, label: str) -> i32:
    let path = bs_join(case_dir, rel_path)
    if not ctx.fs().exists(path):
        return 0
    ctx.diagnostics().error("error: " ++ ctx.target_name() ++ " " ++ label ++ " produced unexpected output: " ++ rel_path)
    1

fn bs_check_build_w_graph_v2(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_project_manifest(ctx, case_dir, "buildwgraphv2")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/one.w"), "fn main:\n    print(\"one\")\n", ctx.target_name(), "graph one")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/two.w"), "fn main:\n    print(\"two\")\n", ctx.target_name(), "graph two")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "runtime/helper.c"), "int helper(void) {\n  return 42;\n}\n", ctx.target_name(), "graph helper")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "build.w"), bs_graph_build_file(), ctx.target_name(), "graph build.w")
    if rc != 0: return rc
    let graph_result = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-graph-v2", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), "--graph")))
    if graph_result.rc != 0: return graph_result.rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "WITH_BUILD_GRAPH\t2", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "default_target\ttoolchain", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t3\tone-o\tsrc/one.w\t0\t0\t", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t4\tone-a\tsrc/one.w\t0\t0\t", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t12\thelper-o\truntime/helper.c\t0\t0\tout/lib/helper.o", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t15\thelper-a\t\t0\t0\tout/lib/libhelper.a", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t17\tembed-helper\t\t0\t0\tout/lib/embedded_helper.s", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t10\tbytes-same\tout/tmp/a.txt\t0\t0\t", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t16\trsp\t\t0\t0\tout/tmp/args.rsp", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t7\trun-two\tout/bin/two\t0\t0\t", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t8\tinstall-two\tout/bin/two\t0\t0\tout/install/two", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, graph_result.stdout, "target\t22\thelper-copy\truntime/helper.c\t0\t0\tout/copied/helper.c", "build_w_graph_v2")
    if rc != 0: return rc
    let selected = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-graph-selected", bs_blob_to_args(bs_argv_append(bs_argv_append(bs_argv_append("", "build"), ":two"), "--graph")))
    if selected.rc != 0: return selected.rc
    rc = bs_assert_not_contains(ctx, selected.stdout, "target\t12\thelper-o", "build_w_graph_selected")
    if rc != 0: return rc
    var no_deps_args: Vec[str] = Vec.new()
    no_deps_args |> push("build")
    no_deps_args |> push(":two")
    no_deps_args |> push("--no-deps")
    let non_action = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-no-deps-non-action", no_deps_args, 120000, case_dir)
    if non_action.rc == 0:
        ctx.diagnostics().error("error: build_w_no_deps_non_action unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, non_action.stderr, "--no-deps is only supported for build.w action targets", "build_w_no_deps_non_action")
    if rc != 0: return rc
    let deps = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-graph-deps", bs_blob_to_args(bs_argv_append(bs_argv_append(bs_argv_append("", "build"), ":toolchain"), "--graph")))
    if deps.rc != 0: return deps.rc
    rc = bs_assert_contains(ctx, deps.stdout, "target\t12\thelper-o", "build_w_graph_deps")
    if rc != 0: return rc
    rc = bs_assert_contains(ctx, deps.stdout, "target\t9\ttoolchain\t\t0\t0\t", "build_w_graph_deps")
    if rc != 0: return rc
    rc = bs_assert_not_contains(ctx, deps.stdout, "target\t0\tone\t", "build_w_graph_deps")
    if rc != 0: return rc
    let full = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-full-graph", bs_blob_to_args(bs_argv_append("", "build")))
    if full.rc != 0: return full.rc
    rc = bs_require_case_file(ctx, case_dir, "out/obj/one-o.o", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/libone-a.a", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/helper.o", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/libhelper.a", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/embedded_helper.s", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/embedded_helper.o", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/copied/helper.c", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/runtime/helper.c", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "promoted-runtime/helper.c", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/corpus/corpus/stdout.txt", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/command/run-two/stdout.txt", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/install/two", "build_w_graph_v2")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(case_dir, "out/corpus/corpus/stdout.txt"), "two", "build_w_graph_corpus")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(case_dir, "out/command/run-two/stdout.txt"), "two", "build_w_graph_command")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(case_dir, "out/lib/embedded_helper.s"), "with_embedded_helper_o_start", "build_w_graph_embed")
    if rc != 0: return rc
    let _remove_out1 = ctx.fs().remove_tree(bs_join(case_dir, "out"))
    let group = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-group-deps", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), ":toolchain")))
    if group.rc != 0: return group.rc
    rc = bs_require_case_file(ctx, case_dir, "out/bin/two", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_forbid_case_file(ctx, case_dir, "out/bin/one", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/obj/one-o.o", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/libone-a.a", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/lib/libhelper.a", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/copied/helper.c", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/corpus/corpus/stdout.txt", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/command/run-two/stdout.txt", "build_w_graph_group")
    if rc != 0: return rc
    rc = bs_require_case_file(ctx, case_dir, "out/install/two", "build_w_graph_group")
    if rc != 0: return rc
    let _remove_out2 = ctx.fs().remove_tree(bs_join(case_dir, "out"))
    let bytes = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-binary-compare", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), ":bytes-same")))
    if bytes.rc != 0: return bytes.rc
    let fix = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-fixpoint-compare", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), ":fix-same")))
    if fix.rc != 0: return fix.rc
    let rsp = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-response-file", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), ":rsp")))
    if rsp.rc != 0: return rsp.rc
    let rsp_text = bs_trim_trailing_line_endings(ctx.fs().read_text(bs_join(case_dir, "out/tmp/args.rsp")))
    if rsp_text != "\"-L/some path\"\n\"plain\"":
        ctx.diagnostics().error("error: build_w_graph_v2 response file contents mismatch: " ++ rsp_text)
        return 1
    let _remove_out3 = ctx.fs().remove_tree(bs_join(case_dir, "out"))
    let two = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-target-select", bs_blob_to_args(bs_argv_append(bs_argv_append("", "build"), ":two")))
    if two.rc != 0: return two.rc
    if not ctx.fs().exists(bs_join(case_dir, "out/bin/two")) or ctx.fs().exists(bs_join(case_dir, "out/bin/one")):
        ctx.diagnostics().error("error: build_w_graph_v2 target selection outputs were wrong")
        return 1
    0

fn bs_check_removed_build_kind_diagnostic(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_project_manifest(ctx, case_dir, "removedkind")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "removed kind source")
    if rc != 0: return rc
    let build_text =
        "use std.build\n\n" ++
        "fn removed_kind() -> BuildKind: 5 as BuildKind\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    out = out.add_target(target_new(removed_kind(), \"old-generated-source\", \"\"))\n" ++
        "    out.default(\"old-generated-source\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "build.w"), build_text, ctx.target_name(), "removed kind build.w")
    if rc != 0: return rc
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-removed-kind", bs_blob_to_args(bs_argv_append("", "build")), 120000, case_dir)
    if result.rc == 0:
        ctx.diagnostics().error("error: build_w_removed_kind unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, result.stderr, "removed_generated_source", "build_w_removed_kind")
    if rc != 0: return rc
    bs_assert_contains(ctx, result.stderr, "regenerate your build graph", "build_w_removed_kind")

fn bs_check_build_w_action_target(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_project_manifest(ctx, case_dir, "buildwaction")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "action source")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/input.txt"), "input", ctx.target_name(), "action input")
    if rc != 0: return rc
    let build_text =
        "use std.build\n\n" ++
        "fn generate(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.target_name() == \"generate\")\n" ++
        "    assert(ctx.project_info().package_name() == \"buildwaction\")\n" ++
        "    assert(ctx.inputs().get(0) == \"src/input.txt\")\n" ++
        "    assert(ctx.args().get(0) == \"hello\")\n" ++
        "    assert(ctx.fs().read_text(ctx.inputs().get(0)) == \"input\")\n" ++
        "    assert(ctx.fs().mkdir_all(\"out/action\") == 0)\n" ++
        "    assert(ctx.fs().write_text(ctx.output(), \"action:\" ++ ctx.args().get(0)) == 0)\n" ++
        "    assert(ctx.fs().write_text(ctx.outputs().get(1), \"extra:\" ++ ctx.args().get(0)) == 0)\n" ++
        "    var env_args: Vec[str] = Vec.new()\n" ++
        "    env_args |> push(\"/usr/bin/env\")\n" ++
        "    var child_env = process_env()\n" ++
        "    child_env = child_env.set(\"WITH_ACTION_TEST_ENV\", \"present\")\n" ++
        "    let env_result = ctx.process_runner().run_capture_with_env(env_args, \"out/action/env.txt\", \"out/action/env.err\", 120000, child_env)\n" ++
        "    assert(env_result.rc == 0)\n" ++
        "    assert(env_result.stdout.contains(\"WITH_ACTION_TEST_ENV=present\"))\n" ++
        "    var direct_args: Vec[str] = Vec.new()\n" ++
        "    direct_args |> push(\"/bin/echo\")\n" ++
        "    direct_args |> push(\"streamed-process-run\")\n" ++
        "    assert(ctx.process_runner().run(direct_args) == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var generate_target = target_new(.Action, \"generate\", \"\").output(\"out/action/value.txt\")\n" ++
        "    generate_target = generate_target.extra_output(\"out/action/extra.txt\")\n" ++
        "    generate_target = generate_target.input(\"src/input.txt\")\n" ++
        "    generate_target = generate_target.arg(\"hello\")\n" ++
        "    generate_target.action = generate\n" ++
        "    out = out.add_target(generate_target)\n" ++
        "    var all = target_new(.Group, \"all\", \"\")\n" ++
        "    all = all.dep(\"generate\")\n" ++
        "    out = out.add_target(all)\n" ++
        "    out.default(\"all\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "build.w"), build_text, ctx.target_name(), "action build.w")
    if rc != 0: return rc
    let result = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-action-target", bs_blob_to_args(bs_argv_append("", "build")))
    if result.rc != 0: return result.rc
    rc = bs_assert_contains(ctx, result.stdout, "streamed-process-run", "build_w_action_process_run")
    if rc != 0: return rc
    rc = bs_expect_file_contains(ctx, bs_join(case_dir, "out/action/value.txt"), "action:hello", "build_w_action_target")
    if rc != 0: return rc
    bs_expect_file_contains(ctx, bs_join(case_dir, "out/action/extra.txt"), "extra:hello", "build_w_action_extra_output")

fn bs_check_build_w_action_no_deps(ctx: ActionCtx, compiler_path: str, case_dir: str) -> i32:
    var rc = bs_write_project_manifest(ctx, case_dir, "actionnodeps")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "action no-deps source")
    if rc != 0: return rc
    let build_text =
        "use std.build\n\n" ++
        "fn prepare(ctx: ActionCtx) -> i32:\n" ++
        "    let _ = ctx\n" ++
        "    17\n\n" ++
        "fn leaf(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(ctx.output(), \"leaf\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var prepare_target = target_new(.Action, \"prepare\", \"\").output(\"out/action/prepare.txt\")\n" ++
        "    prepare_target.action = prepare\n" ++
        "    out = out.add_target(prepare_target)\n" ++
        "    var leaf_target = target_new(.Action, \"leaf\", \"\").output(\"out/action/leaf.txt\")\n" ++
        "    leaf_target = leaf_target.dep(\"prepare\")\n" ++
        "    leaf_target.action = leaf\n" ++
        "    out = out.add_target(leaf_target)\n" ++
        "    out.default(\"leaf\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(case_dir, "build.w"), build_text, ctx.target_name(), "action no-deps build.w")
    if rc != 0: return rc

    var args: Vec[str] = Vec.new()
    args |> push("build")
    args |> push(":leaf")
    args |> push("--no-deps")
    let no_deps = bs_build_w_expect_success(ctx, compiler_path, case_dir, "build-w-action-no-deps", args)
    if no_deps.rc != 0: return no_deps.rc
    rc = bs_expect_file_contains(ctx, bs_join(case_dir, "out/action/leaf.txt"), "leaf", "build_w_action_no_deps")
    if rc != 0: return rc
    if ctx.fs().exists(bs_join(case_dir, "out/action/prepare.txt")):
        ctx.diagnostics().error("error: build_w_action_no_deps unexpectedly ran dependency action")
        return 1

    var dep_args: Vec[str] = Vec.new()
    dep_args |> push("build")
    dep_args |> push(":leaf")
    let with_deps = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-action-with-deps-fails", dep_args, 120000, case_dir)
    if with_deps.rc == 0:
        ctx.diagnostics().error("error: build_w_action_no_deps normal dependency build unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, with_deps.stderr, "prepare", "build_w_action_no_deps_failure")
    if rc != 0: return rc
    bs_assert_contains(ctx, with_deps.stderr, "failed with exit code 17", "build_w_action_no_deps_failure")

fn bs_check_build_w_action_failures(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let missing_dir = bs_join(base_dir, "missing_input")
    var rc = bs_write_project_manifest(ctx, missing_dir, "actionmissing")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(missing_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "action missing source")
    if rc != 0: return rc
    let missing_build =
        "use std.build\n\n" ++
        "fn generate(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(ctx.output(), \"should not run\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"generate\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target = target.input(\"src/missing.txt\")\n" ++
        "    target.action = generate\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"generate\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(missing_dir, "build.w"), missing_build, ctx.target_name(), "action missing build.w")
    if rc != 0: return rc
    let missing = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-action-missing-input", bs_blob_to_args(bs_argv_append("", "build")), 120000, missing_dir)
    if missing.rc == 0:
        ctx.diagnostics().error("error: build_w_action_missing_input unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, missing.stderr, "missing declared input", "build_w_action_missing_input")
    if rc != 0: return rc

    let failure_dir = bs_join(base_dir, "failure")
    rc = bs_write_project_manifest(ctx, failure_dir, "actionfailure")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(failure_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "action failure source")
    if rc != 0: return rc
    let failure_build =
        "use std.build\n\n" ++
        "fn fail_action(ctx: ActionCtx) -> i32:\n" ++
        "    7\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"fail\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target.action = fail_action\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"fail\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(failure_dir, "build.w"), failure_build, ctx.target_name(), "action failure build.w")
    if rc != 0: return rc
    let failure = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-action-failure", bs_blob_to_args(bs_argv_append("", "build")), 120000, failure_dir)
    if failure.rc == 0:
        ctx.diagnostics().error("error: build_w_action_failure unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, failure.stderr, "failed with exit code 7", "build_w_action_failure")
    if rc != 0: return rc

    let undeclared_dir = bs_join(base_dir, "undeclared_output")
    rc = bs_write_project_manifest(ctx, undeclared_dir, "actionundeclared")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(undeclared_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "action undeclared source")
    if rc != 0: return rc
    let undeclared_build =
        "use std.build\n\n" ++
        "fn bad_write(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(\"out/action/other.txt\", \"bad\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"bad-write\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target.action = bad_write\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"bad-write\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(undeclared_dir, "build.w"), undeclared_build, ctx.target_name(), "action undeclared build.w")
    if rc != 0: return rc
    let undeclared = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-action-undeclared-output", bs_blob_to_args(bs_argv_append("", "build")), 120000, undeclared_dir)
    if undeclared.rc == 0:
        ctx.diagnostics().error("error: build_w_action_undeclared_output unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, undeclared.stderr, "not a declared action output", "build_w_action_undeclared_output")
    if rc != 0: return rc

    let escape_dir = bs_join(base_dir, "escape_output")
    rc = bs_write_project_manifest(ctx, escape_dir, "actionescape")
    if rc != 0: return rc
    rc = bs_build_w_write_fixture(ctx, bs_join(escape_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", ctx.target_name(), "action escape source")
    if rc != 0: return rc
    let escape_build =
        "use std.build\n\n" ++
        "fn bad_escape(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(\"../outside.txt\", \"bad\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"bad-escape\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target.action = bad_escape\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"bad-escape\")\n"
    rc = bs_build_w_write_fixture(ctx, bs_join(escape_dir, "build.w"), escape_build, ctx.target_name(), "action escape build.w")
    if rc != 0: return rc
    let escape = bs_run_cli_capture_cwd(ctx, compiler_path, "build-w-action-escape-output", bs_blob_to_args(bs_argv_append("", "build")), 120000, escape_dir)
    if escape.rc == 0:
        ctx.diagnostics().error("error: build_w_action_escape_output unexpectedly succeeded")
        return 1
    rc = bs_assert_contains(ctx, escape.stderr, "ToolFs path escapes project root", "build_w_action_escape_output")
    if rc != 0: return rc

    0

pub fn run_cli_selfhost_build_w_action(ctx: ActionCtx) -> i32:
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
    let base_dir = output_dir
    var rc = bs_check_build_w_not_ignored(ctx, compiler_path, bs_join(base_dir, "not_ignored"))
    if rc != 0: return rc
    rc = bs_check_build_w_comptime_with_entry(ctx, compiler_path, bs_join(base_dir, "comptime_with"))
    if rc != 0: return rc
    rc = bs_check_build_w_workspace_api(ctx, compiler_path, bs_join(base_dir, "workspace_api"))
    if rc != 0: return rc
    rc = bs_check_build_w_test_targets(ctx, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bs_check_build_w_library_and_targets(ctx, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bs_check_build_w_generated_source(ctx, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bs_check_build_w_graph_v2(ctx, compiler_path, bs_join(base_dir, "graph_v2"))
    if rc != 0: return rc
    rc = bs_check_removed_build_kind_diagnostic(ctx, compiler_path, bs_join(base_dir, "removed_kind"))
    if rc != 0: return rc
    rc = bs_check_build_w_action_target(ctx, compiler_path, bs_join(base_dir, "action"))
    if rc != 0: return rc
    rc = bs_check_build_w_action_no_deps(ctx, compiler_path, bs_join(base_dir, "action_no_deps"))
    if rc != 0: return rc
    bs_check_build_w_action_failures(ctx, compiler_path, bs_join(base_dir, "action_failures"))


fn bs_copy_fixture_file(ctx: ActionCtx, src: str, dst: str, label: str) -> i32:
    if not ctx.fs().exists(src):
        return bs_fail(ctx, "missing source file for " ++ label ++ ": " ++ src)
    bs_write_fixture(ctx, dst, ctx.fs().read_text(src), label)

fn bs_drop_first_lines(text: str, count: i32) -> str:
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

fn bs_pcre2_expect_success(ctx: ActionCtx, compiler_path: str, case_dir: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, label, args, 180000, case_dir)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": pcre2 prep selfhost case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bs_check_pcre2_defs_prune_ebcdic_tables(ctx: ActionCtx) -> i32:
    let defs = "lib/std/re/defs.w"
    var rc = bs_file_forbids(ctx, defs, "_pcre2_ebcdic_1047_to_ascii_8", "ebcdic table externs")
    if rc != 0: return rc
    bs_file_forbids(ctx, defs, "_pcre2_ascii_to_ebcdic_1047_8", "ebcdic table externs")

fn bs_check_pcre2_prepare_shared_externs(ctx: ActionCtx, base_dir: str) -> i32:
    let raw_dir = bs_join(base_dir, "raw")
    let generated_dir = bs_join(base_dir, "generated")
    var rc = bs_write_fixture(ctx, bs_join(raw_dir, "defs.w"), "// std.re.defs - shared definitions\nextern fn preamble_helper() -> void\n", "shared externs defs")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_tables.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nvar _pcre2_utf8_table1: *c_int\nvar _pcre2_OP_lengths_8: *u8\n", "shared externs tables")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_compile.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nextern var _pcre2_utf8_table1: *c_int\nvar _pcre2_posix_class_maps8: *c_int\n", "shared externs compile")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_compile_class.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nextern var _pcre2_utf8_table1: *c_int\nextern var _pcre2_posix_class_maps8: *c_int\n", "shared externs compile class")
    if rc != 0: return rc

    let files: Vec[str] = Vec.new()
    files |> push("defs.w")
    files |> push("pcre2_tables.w")
    files |> push("pcre2_compile.w")
    files |> push("pcre2_compile_class.w")
    for i in 0..files.len() as i32:
        let file = files.get(i as i64)
        rc = bs_copy_fixture_file(ctx, bs_join(raw_dir, file), bs_join(generated_dir, file), "shared externs copy")
        if rc != 0: return rc

    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_tables.w"), "var _pcre2_utf8_table1: *c_int", "shared externs tables")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_tables.w"), "var _pcre2_OP_lengths_8: *u8", "shared externs tables")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile.w"), "extern var _pcre2_utf8_table1: *c_int", "shared externs compile")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile.w"), "var _pcre2_posix_class_maps8: *c_int", "shared externs compile")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile_class.w"), "extern var _pcre2_utf8_table1: *c_int", "shared externs class")
    if rc != 0: return rc
    bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile_class.w"), "extern var _pcre2_posix_class_maps8: *c_int", "shared externs class")

fn bs_check_pcre2_prepare_width_prunes(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let raw_dir = bs_join(base_dir, "raw")
    let generated_dir = bs_join(base_dir, "generated")
    let compile_text = "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nextern fn _pcre2_keep_8(ch: c_uint) -> c_uint\nfn keep_body(flag: c_int) -> c_int {\n    var c__goto_6350_16: c_uint = 0\n    if flag != 0 {\n        (c__goto_6350_16 = _pcre2_keep_8(c__goto_6350_16))\n    } else {\n        (c__goto_6350_16 = 1)\n    }\n    (c__goto_6350_16 as c_int)\n}\n"
    var rc = bs_write_fixture(ctx, bs_join(raw_dir, "defs.w"), "// std.re.defs - shared definitions\ntype c_void = opaque\ntype c_int = i32\ntype c_uint = u32\ntype c_ushort = u16\nextern fn strlen(s: *const i8) -> i64\nextern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void\n", "width prune defs")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_compile.w"), compile_text, "width prune compile")
    if rc != 0: return rc
    rc = bs_copy_fixture_file(ctx, bs_join(raw_dir, "defs.w"), bs_join(generated_dir, "defs.w"), "width prune defs copy")
    if rc != 0: return rc
    rc = bs_copy_fixture_file(ctx, bs_join(raw_dir, "pcre2_compile.w"), bs_join(generated_dir, "pcre2_compile.w"), "width prune compile copy")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile.w"), "(c__goto_6350_16 = _pcre2_keep_8(c__goto_6350_16))", "width prune local")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile.w"), "} else {", "width prune else")
    if rc != 0: return rc

    let wrapper = bs_join(base_dir, "wrapper.w")
    let wrapper_text = ctx.fs().read_text(bs_join(generated_dir, "defs.w")) ++ bs_drop_first_lines(ctx.fs().read_text(bs_join(generated_dir, "pcre2_compile.w")), 2) ++ "\nfn main { print(\"ok\") }\n"
    rc = bs_write_fixture(ctx, wrapper, wrapper_text, "width prune wrapper")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("check")
    args |> push(bs_abs(root, wrapper))
    let result = bs_pcre2_expect_success(ctx, compiler_path, base_dir, "width-prunes-whole-decls", args)
    if result.rc != 0: return result.rc
    0

fn bs_check_pcre2_prepare_shared_lets(ctx: ActionCtx, base_dir: str) -> i32:
    let raw_dir = bs_join(base_dir, "raw")
    let generated_dir = bs_join(base_dir, "generated")
    var rc = bs_write_fixture(ctx, bs_join(raw_dir, "defs.w"), "// std.re.defs - shared definitions\nlet ucp_C: c_uint = 0\nlet ucp_L: c_uint = 1\n", "shared lets defs")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_tables.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nlet LOCAL_TABLE_ONLY: c_uint = 99\n", "shared lets tables")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_compile.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nlet COMPILE_ONLY: c_uint = 7\n", "shared lets compile")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(raw_dir, "pcre2_match.w"), "// Migrated from PCRE2\nuse std.re.defs\n\ntype BOOL = c_int\nlet MATCH_ONLY: c_uint = 8\n", "shared lets match")
    if rc != 0: return rc

    let files: Vec[str] = Vec.new()
    files |> push("defs.w")
    files |> push("pcre2_tables.w")
    files |> push("pcre2_compile.w")
    files |> push("pcre2_match.w")
    for i in 0..files.len() as i32:
        let file = files.get(i as i64)
        rc = bs_copy_fixture_file(ctx, bs_join(raw_dir, file), bs_join(generated_dir, file), "shared lets copy")
        if rc != 0: return rc

    rc = bs_file_contains(ctx, bs_join(generated_dir, "defs.w"), "let ucp_C: c_uint = 0", "shared lets defs")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "defs.w"), "let ucp_L: c_uint = 1", "shared lets defs")
    if rc != 0: return rc
    rc = bs_file_forbids(ctx, bs_join(generated_dir, "pcre2_tables.w"), "let ucp_C: c_uint = 0", "shared lets tables")
    if rc != 0: return rc
    rc = bs_file_forbids(ctx, bs_join(generated_dir, "pcre2_compile.w"), "let ucp_C: c_uint = 0", "shared lets compile")
    if rc != 0: return rc
    rc = bs_file_forbids(ctx, bs_join(generated_dir, "pcre2_match.w"), "let ucp_C: c_uint = 0", "shared lets match")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_tables.w"), "let LOCAL_TABLE_ONLY: c_uint = 99", "shared lets tables")
    if rc != 0: return rc
    rc = bs_file_contains(ctx, bs_join(generated_dir, "pcre2_compile.w"), "let COMPILE_ONLY: c_uint = 7", "shared lets compile")
    if rc != 0: return rc
    bs_file_contains(ctx, bs_join(generated_dir, "pcre2_match.w"), "let MATCH_ONLY: c_uint = 8", "shared lets match")

fn bs_check_std_re_shared_dependency_imports(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(base_dir, "main.w")
    var rc = bs_write_fixture(ctx, src, "use std.re.defs\nuse std.re.pcre2_compile\nuse std.re.pcre2_match\n\nfn main:\n    print(\"ok\")\n", "std re dependency imports")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("check")
    args |> push(bs_abs(root, src))
    let result = bs_pcre2_expect_success(ctx, compiler_path, base_dir, "std-re-shared-dependency-imports", args)
    if result.rc != 0: return result.rc
    0

fn bs_check_opaque_field_access_rejected(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(base_dir, "opaque_field_access.w")
    var rc = bs_write_fixture(ctx, src, "type T = opaque\n\nfn f(p: *mut T):\n    (p.x = 1)\n\nfn main:\n    let _ = 0\n", "opaque field access")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("check")
    args |> push(bs_abs(root, src))
    let result = bs_run_cli_capture_cwd(ctx, compiler_path, "opaque-field-access", args, 120000, base_dir)
    if result.rc == 0:
        return bs_fail(ctx, "accepted opaque field access")
    bs_assert_contains(ctx, result.stderr, "field access requires a concrete struct or union type; this type is opaque", "opaque_field_access")

fn bs_check_pcre2_match_heapframe(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let match_path = "lib/std/re/pcre2_match.w"
    let match_text = ctx.fs().read_text(match_path)
    var rc = bs_assert_not_contains(ctx, match_text, "type heapframe = opaque", "pcre2 match heapframe")
    if rc != 0: return rc
    rc = bs_assert_not_contains(ctx, match_text, "type heapframe_align = opaque", "pcre2 match heapframe")
    if rc != 0: return rc
    let obj = bs_join(base_dir, "pcre2_match_issue111.o")
    var args: Vec[str] = Vec.new()
    args |> push("build")
    args |> push(bs_abs(root, match_path))
    args |> push("--emit-obj")
    args |> push("--no-prelude")
    args |> push("-O0")
    args |> push("-o")
    args |> push(bs_abs(root, obj))
    let result = bs_pcre2_expect_success(ctx, compiler_path, root, "pcre2-match-heapframe", args)
    if result.rc != 0: return result.rc
    0

fn bs_check_pcre2_compile_builds(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(base_dir, "pcre2_compile_builds.w")
    let bin = bs_join(base_dir, "pcre2_compile_builds")
    var rc = bs_write_fixture(ctx, src, "use std.re.defs\nuse std.re.pcre2_compile\n\nfn main:\n    let _ = pcre2_compile_8((null as *const u8), 0, 0, (null as *mut c_int), (null as *mut c_ulong), (null as *mut pcre2_real_compile_context_8))\n    print(\"ok\")\n", "pcre2 compile builds")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("build")
    args |> push(bs_abs(root, src))
    args |> push("-o")
    args |> push(bs_abs(root, bin))
    let result = bs_pcre2_expect_success(ctx, compiler_path, base_dir, "pcre2-compile-builds", args)
    if result.rc != 0: return result.rc
    rc = bs_assert_not_contains(ctx, result.stderr, "MIR lowering failed", "pcre2 compile builds")
    if rc != 0: return rc
    rc = bs_assert_not_contains(ctx, result.stderr, "AST codegen was removed", "pcre2 compile builds")
    if rc != 0: return rc
    if not ctx.fs().exists(bin):
        return bs_fail(ctx, "missing pcre2_compile_builds output: " ++ bin)
    0

fn bs_check_pcre2_jit_no_support(ctx: ActionCtx, compiler_path: str, base_dir: str) -> i32:
    let root = ctx.project_info().project_root()
    let src = bs_join(base_dir, "pcre2_jit_no_support.w")
    let text = "use std.re.defs\nuse std.re.pcre2_jit_compile\n\nfn main() -> i32:\n    let rc_null = pcre2_jit_compile_8((null as *mut pcre2_real_code_8), 0)\n    if rc_null != PCRE2_ERROR_NULL: return 1\n\n    let rc_test_alloc = pcre2_jit_compile_8((null as *mut pcre2_real_code_8), PCRE2_JIT_TEST_ALLOC)\n    if rc_test_alloc != PCRE2_ERROR_JIT_UNSUPPORTED: return 2\n\n    let stack = pcre2_jit_stack_create_8(1, 1024, (null as *mut pcre2_real_general_context_8))\n    if stack != null: return 3\n\n    pcre2_jit_stack_assign_8((null as *mut pcre2_real_match_context_8), (null as *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8), (null as *mut c_void))\n    pcre2_jit_stack_free_8(stack)\n    pcre2_jit_free_unused_memory_8((null as *mut pcre2_real_general_context_8))\n    _pcre2_jit_free_rodata_8((null as *mut c_void), (null as *mut c_void))\n    _pcre2_jit_free_8((null as *mut c_void), (null as *mut pcre2_memctl))\n\n    if _pcre2_jit_get_size_8((null as *mut c_void)) != 0: return 4\n    if _pcre2_jit_get_target_8() == null: return 5\n    return 0\n"
    var rc = bs_write_fixture(ctx, src, text, "pcre2 jit no support")
    if rc != 0: return rc
    var args: Vec[str] = Vec.new()
    args |> push("run")
    args |> push(bs_abs(root, src))
    let result = bs_pcre2_expect_success(ctx, compiler_path, base_dir, "pcre2-jit-no-support", args)
    if result.rc != 0: return result.rc
    0

fn bs_check_pcre2_generated_existing_main(ctx: ActionCtx, compiler_input: str, case_dir: str) -> i32:
    let generated_dir = bs_join(case_dir, "generated")
    var rc = bs_write_fixture(ctx, bs_join(generated_dir, "defs.w"), "// std.re.defs\ntype c_int = i32\n", "pcre2 generated defs")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(generated_dir, "pcre2_helper.w"), "// Migrated from PCRE2\nuse std.re.defs\n\nfn helper_value() -> c_int:\n    7\n", "pcre2 generated helper")
    if rc != 0: return rc
    rc = bs_write_fixture(ctx, bs_join(generated_dir, "pcre2test.w"), "// Migrated from PCRE2\nuse std.re.defs\n\nfn main() -> i32:\n    0\n", "pcre2 generated existing main")
    if rc != 0: return rc
    let errors = pcre2_count_generated_errors(ctx, compiler_input, generated_dir, true)
    if errors < 0:
        return 1
    if errors != 0:
        return bs_fail(ctx, f"pcre2 generated existing main reported {errors} errors")
    0

pub fn run_cli_selfhost_pcre2_prep_action(ctx: ActionCtx) -> i32:
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

    var rc = bs_check_pcre2_defs_prune_ebcdic_tables(ctx)
    if rc != 0: return rc
    rc = bs_check_pcre2_prepare_shared_externs(ctx, bs_join(output_dir, "pcre2_prepare_case"))
    if rc != 0: return rc
    rc = bs_check_pcre2_prepare_width_prunes(ctx, compiler_path, bs_join(output_dir, "pcre2_prepare_width_prune_case"))
    if rc != 0: return rc
    rc = bs_check_pcre2_prepare_shared_lets(ctx, bs_join(output_dir, "pcre2_prepare_shared_lets_case"))
    if rc != 0: return rc
    rc = bs_check_std_re_shared_dependency_imports(ctx, compiler_path, bs_join(output_dir, "std_re_shared_dependency_case"))
    if rc != 0: return rc
    rc = bs_check_opaque_field_access_rejected(ctx, compiler_path, bs_join(output_dir, "opaque_field_access_case"))
    if rc != 0: return rc
    rc = bs_check_pcre2_match_heapframe(ctx, compiler_path, bs_join(output_dir, "pcre2_match_heapframe_case"))
    if rc != 0: return rc
    rc = bs_check_pcre2_compile_builds(ctx, compiler_path, bs_join(output_dir, "pcre2_compile_builds_case"))
    if rc != 0: return rc
    rc = bs_check_pcre2_jit_no_support(ctx, compiler_path, bs_join(output_dir, "pcre2_jit_no_support_case"))
    if rc != 0: return rc
    bs_check_pcre2_generated_existing_main(ctx, compiler_input, bs_join(output_dir, "pcre2_generated_existing_main_case"))

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
    if shared_nm.rc != 0: return shared_nm.rc
    rc = bs_expect_nm_symbol(ctx, shared_nm.stdout, "emit_obj_import_owner shared_var", "", "shared_var", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, shared_nm.stdout, "emit_obj_import_owner shared_let", "", "shared_let", "", "", "U")
    if rc != 0: return rc
    rc = bs_expect_nm_symbol(ctx, shared_nm.stdout, "emit_obj_import_owner shared_fn", "", "shared_fn", "", "", "U")
    if rc != 0: return rc
    let user_nm = bs_nm_output(ctx, nm_tool, user_obj, "emit-obj-import-user")
    if user_nm.rc != 0: return user_nm.rc
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
    if redecl_nm.rc != 0: return redecl_nm.rc
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
        if pcre_nm.rc != 0: return pcre_nm.rc
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
