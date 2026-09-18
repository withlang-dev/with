use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var negative = target_new(.Executable, "negative", "main.w")
    negative = negative.optimize((-1 as i32) as OptimizeMode)
    var above = target_new(.Executable, "above", "main.w")
    above = above.optimize(2 as OptimizeMode)
    var maximum = target_new(.Executable, "maximum", "main.w")
    maximum = maximum.optimize(2147483647 as OptimizeMode)
    var out = ctx.new_build().add_target(negative)
    out = out.add_target(above)
    out = out.add_target(maximum)
    out.default("above")
