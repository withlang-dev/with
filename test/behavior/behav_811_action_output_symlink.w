//! expect-stdout: ok
// #811: an action output tree containing a directory symlink crashed
// the build driver after the action succeeded (stack overflow,
// 0xC00000FD on Windows): rt_file_mode there never reported S_IFLNK,
// so the output fingerprint descended into the link — and listing the
// link yields the link itself, recursing forever. The build must
// complete, and complete again over the existing output (the
// freshness walk takes the same path).
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("action output symlink", "outsymlink")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn probe(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    let fs = ctx.fs()\n"
    build_text = build_text ++ "    let out = ctx.output()\n"
    build_text = build_text ++ "    let _m = fs.mkdir_all(out ++ \"/repo/src/deep\")\n"
    build_text = build_text ++ "    let _w = fs.write_text(out ++ \"/repo/src/deep/f.w\", \"fn main: print(1)\\n\")\n"
    build_text = build_text ++ "    let _link = fs.symlink(\"src\", out ++ \"/repo/lib\")\n"
    build_text = build_text ++ "    fs.write_text(out ++ \"/stamp.txt\", \"ok\")\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"probe\", \"\").output(\"out/probe\")\n"
    build_text = build_text ++ "    target.action = probe\n"
    build_text = build_text ++ "    target = target.write_scope(\"out\")\n"
    build_text = build_text ++ "    ctx.new_build().add_target(move target).default(\"probe\")\n"
    p7_write(root, "build.w", build_text)
    let first = p7_run(root, "output-symlink-first", p7_build_args())
    p7_assert_success(first, "action output with a symlink, first build")
    let second = p7_run(root, "output-symlink-second", p7_build_args())
    p7_assert_success(second, "action output with a symlink, freshness walk")
    print("ok")
