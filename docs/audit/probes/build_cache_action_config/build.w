use std.build
use build.actions

pub fn build(ctx: BuildCtx) -> Build:
    var target = target_new(.Action, "write-context", "")
    target.action = write_context
    target = target.output("out/context.txt")
    target = target.working_dir("B")
    var out = ctx.new_build().add_target(target)
    out.default("write-context")
