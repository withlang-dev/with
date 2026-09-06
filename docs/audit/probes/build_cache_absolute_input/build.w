use std.build

pub fn build(ctx: BuildCtx) -> Build:
    let input = "/home/shawn/workspace2/with/.audit/probes/build_cache_absolute_input/input.txt"
    var target = target_new(.Command, "copy", "bin/copy-tool")
    target = target.input(input)
    target = target.output("out/result.txt")
    target = target.arg(input)
    target = target.arg("out/result.txt")
    var out = ctx.new_build().add_target(target)
    out.default("copy")
