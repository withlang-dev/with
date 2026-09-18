use std.build

fn succeed_without_output(ctx: ActionCtx) -> i32: 0

pub fn build(ctx: BuildCtx) -> Build:
    var target = target_new(.Action, "missing-output", "")
    target.action = succeed_without_output
    target = target.output("out/required.txt")
    var out = ctx.new_build().add_target(target)
    out.default("missing-output")
