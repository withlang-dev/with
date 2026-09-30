module build.benchmarks

// The benchmarks lane: every With workload under benchmarks/workloads/ and
// the runner, benchmarks/run.w, are checked with the release compiler, so a
// benchmark that stops compiling turns the gate red instead of rotting until
// someone runs the comparison (ecs.w did, silently, until 2026-09-30). The
// list is the directory itself, so a new workload is covered on arrival.
// Checked, never built or run: a run takes minutes and drives other
// languages' toolchains. The files are independent, so they check in a
// core-wide window (build/par.w), and every failure is reported after every
// child is reaped.

use std.build
use build.par

fn bm_join(left: &str, right: &str): if left.ends_with("/"): left ++ right else: left ++ "/" ++ right

fn bm_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == '/': return path.clone()
    bm_join(root, path)

/// The diagnostic lines of a compiler's stderr, without the warning flood.
fn bm_error_lines(text: &str) -> str:
    var out = ""
    for line in text.split("\n"):
        if line.starts_with("error") or line.starts_with(" -->") or line.starts_with("panic"):
            out = out ++ line ++ "\n"
    out

fn bm_slug(path: &str): path.replace("/", "_").replace(".w", "")

pub fn run_benchmarks_check_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        ctx.diagnostics().error("benchmarks-check: missing compiler input")
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if out_dir.len() == 0:
        ctx.diagnostics().error("benchmarks-check: missing output directory")
    if fs.exists(out_dir) and fs.remove_tree(out_dir) != 0:
        ctx.diagnostics().error("benchmarks-check: could not remove previous output directory: " ++ out_dir)
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("benchmarks-check: could not create output directory: " ++ out_dir)
    let root = ctx.project_info().project_root()
    if not fs.exists(inputs[0]):
        ctx.diagnostics().error("benchmarks-check: missing compiler: " ++ inputs[0])
    let compiler = bm_abs(root, inputs[0])
    var sources: Vec[str] = Vec.new()
    for source in fs.glob("benchmarks/workloads/*/*.w"): sources.push(source.clone())
    sources.push("benchmarks/run.w")
    var jobs: Vec[ParJob] = Vec.new()
    for source in sources:
        var args: Vec[str] = Vec.new()
        args.push(compiler.clone())
        args.push("check")
        args.push(bm_abs(root, source))
        let label = bm_slug(source) ++ ".check"
        let stdout = bm_abs(root, bm_join(out_dir, label ++ ".stdout"))
        let stderr = bm_abs(root, bm_join(out_dir, label ++ ".stderr"))
        jobs.push(par_job(args, stdout, stderr, 300000))
    let rcs = par_run(&ctx, &jobs, par_width(&jobs))
    var failures = 0
    for i in 0..rcs.len() as i32:
        if rcs[i] == 0: continue
        failures += 1
        print(f"benchmarks-check: {sources[i]} failed `with check` with exit code {rcs[i]}")
        let stderr = fs.read_text_opt(jobs[i].stderr).unwrap_or("")
        let detail = bm_error_lines(stderr)
        if detail.len() > 0: print(detail) else: print(stderr)
    let total = jobs.len() as i32
    if total < 2:
        ctx.diagnostics().error("benchmarks-check: found no workloads under benchmarks/workloads/*/*.w")
    if failures > 0:
        ctx.diagnostics().error(f"benchmarks-check: {failures} of {total} benchmark program(s) failed to check; a benchmark tracks the current language like any program")
    let _ = fs.write_text(bm_join(out_dir, ".stamp"), f"ok: {total} programs\n")
    print(f"benchmarks-check: {total} programs check")
    0
