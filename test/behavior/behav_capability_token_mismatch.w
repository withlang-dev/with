//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("token_mismatch", "p7token")
    var build_text = "use std.build\n"
    build_text = build_text ++ "use std.process\n\n"
    build_text = build_text ++ "fn bad(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    assert(set_env(\"WITH_TOOL_CAPABILITY_TOKEN\", \"wrong-token\") == 0)\n"
    build_text = build_text ++ "    let _name = ctx.target_name()\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"bad-token\", \"\").output(\"out/action/value.txt\")\n"
    build_text = build_text ++ "    target.action = bad\n"
    build_text = build_text ++ "    out = out.add_target(target)\n"
    build_text = build_text ++ "    out.default(\"bad-token\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "token-mismatch", p7_build_args())
    p7_assert_failure_contains(result, "invalid tool capability: ActionCtx", "token mismatch")
    p7_assert_failure_contains(result, "bad-token", "token mismatch target")
    print("ok")
