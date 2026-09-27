module build.tools_lane

// The tools lane (#1335): every tool under tools/ is compiled with the
// release compiler, so a tool that no longer compiles turns the battery red
// instead of rotting until someone reaches for it. Tools are compiled,
// never run (they rewrite sources, sweep corpora or drive batteries). A
// `build.w` for a scratch project (it defines `pub fn build(ctx:
// BuildCtx)` and no program) is checked; every other file is built. The
// list is the directory itself, so a new tool is covered on arrival.

use std.build

fn tl_join(left: &str, right: &str) -> str:
    if left.ends_with("/"): left ++ right else: left ++ "/" ++ right

fn tl_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == '/': return path.clone()
    tl_join(root, path)

/// The diagnostic lines of a compiler's stderr, without the warning flood.
fn tl_error_lines(text: &str) -> str:
    var out = ""
    for line in text.split("\n"):
        if line.starts_with("error") or line.starts_with(" -->") or line.starts_with("panic"):
            out = out ++ line ++ "\n"
    out

fn tl_slug(path: &str) -> str:
    path.replace("/", "_").replace(".w", "")

fn tl_run(ctx: &ActionCtx, args: Vec[str], label: &str, timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let out_dir = ctx.output()
    let stdout_rel = tl_join(out_dir, label ++ ".stdout")
    let stderr_rel = tl_join(out_dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture_cwd(args, tl_abs(root, stdout_rel), tl_abs(root, stderr_rel), timeout_ms, root)
    if result.rc != 0:
        let stderr = ctx.fs().read_text(stderr_rel)
        let detail = tl_error_lines(stderr)
        print(f"tools-tests: {label} failed with exit code {result.rc}")
        if detail.len() > 0: print(detail) else: print(stderr)
        return 1
    0

pub fn run_tools_tests_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        ctx.diagnostics().error("tools-tests: missing compiler input")
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if out_dir.len() == 0:
        ctx.diagnostics().error("tools-tests: missing output directory")
    if fs.exists(out_dir) and fs.remove_tree(out_dir) != 0:
        ctx.diagnostics().error("tools-tests: could not remove previous output directory: " ++ out_dir)
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("tools-tests: could not create output directory: " ++ out_dir)
    let root = ctx.project_info().project_root()
    if not fs.exists(inputs.get(0)):
        ctx.diagnostics().error("tools-tests: missing compiler: " ++ inputs.get(0))
    let compiler = tl_abs(root, inputs.get(0))
    var failures = 0
    var total = 0
    for source in fs.glob("tools/*.w"):
        total += 1
        let slug = tl_slug(source)
        let text = fs.read_text(source)
        var args: Vec[str] = Vec.new()
        args.push(compiler.clone())
        if text.contains("\npub fn build(ctx: BuildCtx)"):
            args.push("check")
            args.push(tl_abs(root, source))
            failures += tl_run(ctx, args, slug ++ ".check", 300000)
        else:
            args.push("build")
            args.push(tl_abs(root, source))
            args.push("-o")
            args.push(tl_abs(root, tl_join(out_dir, slug)))
            failures += tl_run(ctx, args, slug ++ ".build", 600000)
    if failures > 0:
        ctx.diagnostics().error(f"tools-tests: {failures} of {total} tool(s) failed to compile; a tool tracks the current language like any program (#1335)")
    let _ = fs.write_text(tl_join(out_dir, ".stamp"), f"ok: {total} tools\n")
    print(f"tools-tests: {total} tools compile")
    0
