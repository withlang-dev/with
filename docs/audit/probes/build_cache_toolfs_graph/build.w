use std.build

pub fn build(ctx: BuildCtx) -> Build:
    let text = ctx.fs().read_text("variant.txt")
    let variant = if text.starts_with("A"): "A" else: "B"
    ctx.new_build().executable("app-" ++ variant, "main.w")
