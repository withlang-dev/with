//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("action_filesystem", "p7fs")
    p7_write(case_dir, "src/input.txt", "hello")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn generate(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    assert(ctx.fs().exists(\"src/input.txt\"))\n"
    build_text = build_text ++ "    assert(ctx.fs().read_text(\"src/input.txt\") == \"hello\")\n"
    build_text = build_text ++ "    assert(ctx.fs().mkdir_all(\"out/action\") == 0)\n"
    build_text = build_text ++ "    assert(ctx.fs().write_text(ctx.output(), \"value:\" ++ ctx.fs().read_text(\"src/input.txt\")) == 0)\n"
    build_text = build_text ++ "    assert(ctx.fs().write_text(ctx.outputs().get(1), \"extra\") == 0)\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"generate\", \"\").output(\"out/action/value.txt\")\n"
    build_text = build_text ++ "    target = target.input(\"src/input.txt\")\n"
    build_text = build_text ++ "    target = target.extra_output(\"out/action/extra.txt\")\n"
    build_text = build_text ++ "    target.action = generate\n"
    build_text = build_text ++ "    out = out.add_target(target)\n"
    build_text = build_text ++ "    out.default(\"generate\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "action-filesystem", p7_build_args())
    p7_assert_success(result, "action filesystem")
    p7_assert_file_contains(case_dir, "out/action/value.txt", "value:hello")
    p7_assert_file_contains(case_dir, "out/action/extra.txt", "extra")
    print("ok")
