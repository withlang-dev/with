use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build().executable("spiral", "src/main.w")
    out = out.test("test", "test/*.w")
    out.default("spiral")
