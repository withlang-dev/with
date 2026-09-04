use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.executable("mystery", "main.w")
    out.default("mystery")
