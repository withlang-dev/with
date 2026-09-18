use std.build

pub fn build(ctx: BuildCtx) -> Build:
    assert(ctx.fs().mkdir_all("out") == 0)
    let args: Vec[str] = Vec.new()
    args.push("/usr/bin/head")
    args.push("-c")
    args.push("1")
    args.push("/home/shawn/workspace2/with/.audit/probes/build_cache_process_graph/variant.txt")
    let result = ctx.process_runner().run_capture(args, "out/value.stdout", "out/value.stderr", 1000)
    if result.rc != 0:
        ctx.diagnostics().error("probe process failed")
    let variant = if result.stdout.starts_with("A"): "A" else: "B"
    ctx.new_build().executable("app-" ++ variant, "main.w")
