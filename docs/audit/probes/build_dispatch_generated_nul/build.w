use std.build
use std.string

pub fn build(ctx: BuildCtx) -> Build:
    var path = StringBuilder.new()
    path.push_str("out/gen/accepted.w")
    path.push_byte(0 as u8)
    path.push_str("ignored")
    var out = ctx.new_build()
    out = out.generated_source("out/gen/first.w", "first")
    out = out.generated_source(path.to_str(), "accepted")
    out = out.group("all")
    out.default("all")
