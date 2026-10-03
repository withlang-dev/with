module build.acceptance

use std.build
use build.par

// The D acceptance corpus (D29, #750): test/d_acceptance holds the
// import-free originals of the behavior tests the §18.1 scaffolding gave
// explicit `use` lines, quarantined until D activation (#752) un-quarantines
// it as the activation test. Until then nothing compiled it, and it rotted
// silently (#1865). This lane runs it the way the fallback tier will: a copy
// under out/d-acceptance/corpus gains exactly the `use` lines the compiler's
// unique-match fix-it names ("requires an explicit import (§18.1); add: use
// …", applied by tools/insert_std_uses.w, the tool the scaffolding used),
// looped to a fixpoint, and `d-acceptance-tests` then runs every file under
// the exact-stdout runner. The tree's corpus stays import-free; a file that
// needs anything besides those imports is red here. At D activation the
// fix-it step goes and the lane runs test/d_acceptance itself.

const ACC_GATE_MARK: str = "requires an explicit import (§18.1); add: use "
const ACC_MAX_PASSES: i32 = 4

fn acc_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)

fn acc_basename(path: &str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        if path[i] == '/': start = i + 1
    path.slice(start as i64, path.len())

fn acc_abs(ctx: &ActionCtx, path: &str) -> str:
    if path.starts_with("/"): path.clone() else: ctx.project_info().project_root() ++ "/" ++ path

pub fn run_d_acceptance_corpus_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let compiler = acc_abs(&ctx, ctx.inputs()[0])
    let corpus = ctx.output()
    let work = "out/d-acceptance/work"
    // Pushed, not a literal: the pinned seed frees a literal's moved
    // temporaries (#1122).
    var dirs: Vec[str] = Vec.new()
    dirs.push(corpus.clone())
    dirs.push(work.clone())
    for dir in dirs:
        if fs.exists(dir) and fs.remove_tree(dir) != 0: return acc_fail(&ctx, "cannot remove " ++ dir)
        if fs.mkdir_all(dir) != 0: return acc_fail(&ctx, "cannot create " ++ dir)
    var files: Vec[str] = Vec.new()
    for path in fs.list_files("test/d_acceptance"):
        if not path.ends_with(".w") or path.slice("test/d_acceptance/".len(), path.len()).contains("/"): continue
        let dest = corpus ++ "/" ++ acc_basename(path)
        if fs.copy_file(path, dest) != 0: return acc_fail(&ctx, "cannot copy " ++ path)
        files.push(dest)
    if files.len() == 0: return acc_fail(&ctx, "test/d_acceptance holds no fixtures")
    // The forks resolve the behavior corpus's helper modules beside them.
    if fs.copy_tree("test/behavior/lib", corpus ++ "/lib") != 0: return acc_fail(&ctx, "cannot copy test/behavior/lib")

    let tool = work ++ "/insert_std_uses"
    var build_argv: Vec[str] = Vec.new()
    build_argv.push(compiler.clone())
    build_argv.push("build")
    build_argv.push(acc_abs(&ctx, "tools/insert_std_uses.w"))
    build_argv.push("-o")
    build_argv.push(acc_abs(&ctx, tool))
    let built = ctx.process_runner().run_capture(build_argv, acc_abs(&ctx, work ++ "/tool.stdout"), acc_abs(&ctx, work ++ "/tool.stderr"), 600000)
    if built.rc != 0: return acc_fail(&ctx, f"building tools/insert_std_uses.w failed (exit {built.rc}): " ++ built.stderr)

    var pass = 0
    while true:
        var jobs: Vec[ParJob] = Vec.new()
        for i in 0..files.len() as i32:
            var argv: Vec[str] = Vec.new()
            argv.push(compiler.clone())
            argv.push("check")
            argv.push(acc_abs(&ctx, files[i]))
            jobs.push(par_job(argv, acc_abs(&ctx, work ++ f"/{i}.stdout"), acc_abs(&ctx, work ++ f"/{i}.stderr"), 300000))
        let _rcs = par_run(&ctx, &jobs, par_width(&jobs))
        var diagnostics = ""
        var gated = 0
        for i in 0..files.len() as i32:
            let err = fs.read_text(work ++ f"/{i}.stderr")
            if err.contains(ACC_GATE_MARK):
                gated = gated + 1
                diagnostics = diagnostics ++ err ++ "\n"
        if gated == 0: break
        if pass == ACC_MAX_PASSES:
            return acc_fail(&ctx, f"the insert-use fix-it did not converge after {ACC_MAX_PASSES} passes ({gated} files still gated; see " ++ work ++ ")")
        let diags_path = work ++ f"/pass-{pass}.diagnostics"
        if fs.write_text(diags_path, diagnostics) != 0: return acc_fail(&ctx, "cannot write " ++ diags_path)
        var apply_argv: Vec[str] = Vec.new()
        apply_argv.push(acc_abs(&ctx, tool))
        apply_argv.push("--apply")
        apply_argv.push(acc_abs(&ctx, diags_path))
        let applied = ctx.process_runner().run_capture(apply_argv, acc_abs(&ctx, work ++ f"/pass-{pass}.stdout"), acc_abs(&ctx, work ++ f"/pass-{pass}.stderr"), 120000)
        if applied.rc != 0: return acc_fail(&ctx, f"insert_std_uses --apply failed (exit {applied.rc}): " ++ applied.stdout ++ applied.stderr)
        print(f"d-acceptance: pass {pass}: imports inserted into {gated} files")
        pass = pass + 1
    print(f"d-acceptance: {files.len()} fixtures resolved as the std fallback tier will resolve them")
    0
