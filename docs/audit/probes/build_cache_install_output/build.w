use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build().install("install-probe", "source.txt", "$INSTALL_BINDIR/probe.txt")
    out.default("install-probe")
