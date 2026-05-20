//! expect-stdout: ok

use std.fs
use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("action_no_deps", "p7nodeps")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn prepare(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    assert(ctx.fs().write_text(ctx.output(), \"prepare\") == 0)\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "fn leaf(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    assert(ctx.fs().write_text(ctx.output(), \"leaf\") == 0)\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var prepare_target = target_new(.Action, \"prepare\", \"\").output(\"out/action/prepare.txt\")\n"
    build_text = build_text ++ "    prepare_target.action = prepare\n"
    build_text = build_text ++ "    out = out.add_target(prepare_target)\n"
    build_text = build_text ++ "    var leaf_target = target_new(.Action, \"leaf\", \"\").output(\"out/action/leaf.txt\")\n"
    build_text = build_text ++ "    leaf_target = leaf_target.dep(\"prepare\")\n"
    build_text = build_text ++ "    leaf_target.action = leaf\n"
    build_text = build_text ++ "    out = out.add_target(leaf_target)\n"
    build_text = build_text ++ "    out.default(\"leaf\")\n"
    p7_write(case_dir, "build.w", build_text)
    let no_deps = p7_run(case_dir, "action-no-deps", p7_build_target_no_deps_args(":leaf"))
    p7_assert_success(no_deps, "action no-deps")
    p7_assert_file_contains(case_dir, "out/action/leaf.txt", "leaf")
    assert(not file_exists(p7_join(case_dir, "out/action/prepare.txt")))

    let with_deps = p7_run(case_dir, "action-with-deps", p7_build_target_args(":leaf"))
    p7_assert_success(with_deps, "action with deps")
    p7_assert_file_contains(case_dir, "out/action/prepare.txt", "prepare")
    print("ok")
