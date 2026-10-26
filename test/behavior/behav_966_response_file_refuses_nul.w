//! expect-stdout: ok
// #966: a response file argument is one process argument, so a NUL in one is
// refused as it is for every other target, before any file is written. The
// response file took it verbatim and a consumer truncated the argument.
use pre_d_build_runner
use std.fs

fn main:
    let root = p7_prepare_case("response nul", "rspnul")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    p7_write(root, "build.w", "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n    let rsp = target_new(.GenerateResponseFile, \"rsp\", \"\").output(\"gen/nul.rsp\").arg(\"before\\0after\")\n    ctx.new_build().add_target(rsp).default(\"rsp\")\n")
    let result = p7_run(root, ":rsp", p7_build_target_args(":rsp"))
    p7_assert_failure_contains(&result, "contains a NUL byte", ":rsp")
    assert(not file_exists(p7_join(root, "gen/nul.rsp")))
    print("ok")
