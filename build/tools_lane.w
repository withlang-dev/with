module build.tools_lane

// The tools lane (#1335): every tool under tools/ is compiled with the
// release compiler, so a tool that no longer compiles turns the battery red
// instead of rotting until someone reaches for it. Tools are compiled,
// never run (they rewrite sources, sweep corpora or drive batteries). A
// `build.w` for a scratch project (it defines `pub fn build(ctx:
// BuildCtx)` and no program) is checked; every other file is built — a
// link catches the missing symbol a check cannot. A tool that imports
// compiler.Compilation (the whole compiler pipeline) is checked too: its
// build recompiled most of the compiler, ~360 CPU-s each, 1,800 CPU-s for
// the five, and every module it links is linked by every stage build; only
// its own code's codegen goes unexercised (Eric, 2026-09-29). The list is the
// directory itself, so a new tool is covered on arrival. The tools are
// independent, so they compile in a core-wide window (build/par.w), and
// every failure is reported after every child is reaped.

use std.build
use build.par

fn tl_join(left: &str, right: &str): if left.ends_with("/"): left ++ right else: left ++ "/" ++ right

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

fn tl_slug(path: &str): path.replace("/", "_").replace(".w", "")

// A scratch project's build.w, or a tool that imports the whole compiler
// pipeline (see above): checked, not built.
fn tl_checked_only(fs: &ToolFs, source: &str) -> bool:
    let text = fs.read_text(source)
    text.contains("\npub fn build(ctx: BuildCtx)") or text.contains("\nuse compiler.Compilation")

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
    if not fs.exists(inputs[0]):
        ctx.diagnostics().error("tools-tests: missing compiler: " ++ inputs[0])
    let compiler = tl_abs(root, inputs[0])
    var jobs: Vec[ParJob] = Vec.new()
    var labels: Vec[str] = Vec.new()
    for source in fs.glob("tools/*.w"):
        let slug = tl_slug(source)
        var args: Vec[str] = Vec.new()
        args.push(compiler.clone())
        var label = ""
        var timeout_ms = 600000
        if tl_checked_only(fs, source):
            args.push("check")
            args.push(tl_abs(root, source))
            label = slug ++ ".check"
            timeout_ms = 300000
        else:
            args.push("build")
            args.push(tl_abs(root, source))
            args.push("-o")
            args.push(tl_abs(root, tl_join(out_dir, slug)))
            label = slug ++ ".build"
        let stdout = tl_abs(root, tl_join(out_dir, label ++ ".stdout"))
        let stderr = tl_abs(root, tl_join(out_dir, label ++ ".stderr"))
        jobs.push(par_job(args, stdout, stderr, timeout_ms))
        labels.push(label)
    let rcs = par_run(&ctx, &jobs, par_width(&jobs))
    var failures = 0
    for i in 0..rcs.len() as i32:
        if rcs[i] == 0: continue
        failures += 1
        print(f"tools-tests: {labels[i]} failed with exit code {rcs[i]}")
        let stderr = fs.read_text_opt(jobs[i].stderr).unwrap_or("")
        let detail = tl_error_lines(stderr)
        if detail.len() > 0: print(detail) else: print(stderr)
    let total = jobs.len() as i32
    if failures > 0:
        ctx.diagnostics().error(f"tools-tests: {failures} of {total} tool(s) failed to compile; a tool tracks the current language like any program (#1335)")
    let _ = fs.write_text(tl_join(out_dir, ".stamp"), f"ok: {total} tools\n")
    print(f"tools-tests: {total} tools compile")
    0
