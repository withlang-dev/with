use std.build

pub fn write_context(ctx: ActionCtx) -> i32:
    ctx.fs().write_text(ctx.output(), ctx.working_dir())
