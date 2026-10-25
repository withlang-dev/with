//! expect-stdout: ok
// #969: a compile_asm_object target takes no argument (the host) or one
// `triple=<llvm-triple>`. An unknown option, an empty `triple=` and a second
// argument were ignored, and the object was assembled for the host.
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("asm args", "asmargs")
    p7_write(root, "f.s", ".text\n")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    var build_text = "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    let bogus = target_new(.CompileAsmObject, \"bogus\", \"f.s\").output(\"out/bogus.o\").arg(\"--unsupported-option\")\n"
    build_text = build_text ++ "    let empty = target_new(.CompileAsmObject, \"empty\", \"f.s\").output(\"out/empty.o\").arg(\"triple=\")\n"
    build_text = build_text ++ "    let extra = target_new(.CompileAsmObject, \"extra\", \"f.s\").output(\"out/extra.o\").arg(\"triple=x86_64-apple-macosx\").arg(\"ignored\")\n"
    build_text = build_text ++ "    let host = target_new(.CompileAsmObject, \"host\", \"f.s\").output(\"out/host.o\")\n"
    build_text = build_text ++ "    ctx.new_build().add_target(bogus).add_target(empty).add_target(extra).add_target(host).default(\"host\")\n"
    p7_write(root, "build.w", build_text)
    for target in [":bogus", ":empty", ":extra"]:
        let result = p7_run(root, target, p7_build_target_args(target))
        p7_assert_failure_contains(&result, "takes no argument (the host) or one `triple=<llvm-triple>`", target)
    p7_assert_success(&p7_run(root, ":host", p7_build_target_args(":host")), ":host")
    print("ok")
