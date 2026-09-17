// Installed as build.w in the isolated CI DLL-copy project.
use std.build

fn copy_dll(ctx: ActionCtx) -> i32:
    let external = ctx.env_input("WITH_UAT_OPENGL32_DLL")
    let source = if external.len() > 0: external else: "source.dll"
    ctx.fs().copy_file(source, "out/copied.dll")

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    var target = target_new(.Action, "copy-dll", "").output("out/copied.dll")
    target = target.input("source.dll")
    target.action = copy_dll
    out = out.add_target(target)
    out.default("copy-dll")
