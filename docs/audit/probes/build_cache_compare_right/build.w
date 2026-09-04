use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.binary_compare("compare", "left.bin", "right.bin")
    out.default("compare")
