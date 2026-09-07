use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    let target = target_new(.Test, "cross-test", "target_test.w").target(BuildTarget.linux_aarch64)
    out.add_target(move target)

