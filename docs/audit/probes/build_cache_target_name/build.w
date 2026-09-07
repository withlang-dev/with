use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var target = target_new(.GenerateResponseFile, "../escaped", "")
    target = target.output("out/probe.rsp")
    target = target.arg("hello")
    var out = ctx.new_build().add_target(target)
    out.default("../escaped")
