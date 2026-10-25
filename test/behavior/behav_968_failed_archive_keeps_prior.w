//! expect-stdout: ok
// #968: a static archive that fails to build leaves the last good one. The
// output was removed before the archiver read its members, so a member it
// could not read (here a directory) destroyed the prior artifact.
use pre_d_build_runner
use std.fs

fn main:
    let root = p7_prepare_case("archive keeps prior", "arkeep")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    p7_write(root, "lib.a", "sentinel")
    assert(mkdir_p(p7_join(root, "adir")) == 0)
    p7_write(root, "build.w", "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n    let ar = target_new(.CreateStaticArchive, \"ar\", \"\").output(\"lib.a\").input(\"adir\")\n    ctx.new_build().add_target(ar).default(\"ar\")\n")
    let result = p7_run(root, ":ar", p7_build_target_args(":ar"))
    p7_assert_failure_contains(&result, "create_static_archive target 'ar' failed", ":ar")
    let kept = read_file(p7_join(root, "lib.a")) ?? "(gone)"
    assert(kept == "sentinel")
    print("ok")
