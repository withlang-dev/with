use std.build

pub fn build(ctx: BuildCtx) -> Build:
    let variant = ctx.env_input("WITH_AUDIT_GRAPH_VARIANT")
    ctx.new_build().executable("app-" ++ variant, "main.w")

