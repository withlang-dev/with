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

fn bs_run_cli_expect_success(ctx: ActionCtx, compiler_path: str, label: str, args: Vec[str]) -> SelfhostRunResult:
    let result = bs_run_cli_capture(ctx, compiler_path, label, args, 120000)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": cli selfhost command '" ++ label ++ f"' failed with exit code {result.rc}")
    result

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
