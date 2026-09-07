use std.build
use config

pub fn build(ctx: BuildCtx) -> Build:
    ctx.new_build().executable("app-" ++ variant(), "main.w")
