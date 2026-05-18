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
