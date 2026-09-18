use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.executable("exe", "main.w")
    out = out.library("library", "lib.w")
    out = out.object("object", "lib.w")
    out = out.archive("archive", "lib.w")
    out.default("exe")
