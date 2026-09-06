use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var target = target_new(.Command, "run-tool", "probe-tool")
    target = target.output("out/result.txt")
    target = target.arg("out/result.txt")
    var out = ctx.new_build().add_target(target)
    out.default("run-tool")
