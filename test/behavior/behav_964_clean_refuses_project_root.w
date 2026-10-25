//! expect-stdout: ok
// #964: `clean` with `.` is refused and the project stays. `.` resolved to
// the project root, every file under it was removed, and only the final
// remove of the root itself failed.
use pre_d_build_runner
use std.fs

fn main:
    let root = p7_prepare_case("clean root", "clean964")
    p7_write(root, "src/main.w", "fn main: print(1)\n")
    p7_write(root, "sub/marker.txt", "keep")
    p7_write(root, "build.w", "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n    let wipe = target_new(.Clean, \"wipe\", \"\").arg(\".\")\n    ctx.new_build().add_target(wipe).default(\"wipe\")\n")
    p7_assert_failure_contains(&p7_run(root, ":wipe", p7_build_target_args(":wipe")), "has unsafe path: .", ":wipe")
    assert(file_exists(p7_join(root, "sub/marker.txt")))
    assert(file_exists(p7_join(root, "build.w")))
    print("ok")
