//! expect-error: tool capability fields are private

use std.build

fn leak(ctx: BuildCtx) -> str:
    ctx.token
