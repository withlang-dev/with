use std.build

pub fn build(ctx: BuildCtx) -> Build:
    ctx.new_build().executable("manifest-target-probe", "main.w")
