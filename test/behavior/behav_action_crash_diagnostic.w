//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("action_crash", "p7crash")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn crash(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    let _ = ctx\n"
    build_text = build_text ++ "    assert(false)\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"panic-action\", \"\").output(\"out/action/value.txt\")\n"
    build_text = build_text ++ "    target.action = crash\n"
    build_text = build_text ++ "    out = out.add_target(target)\n"
    build_text = build_text ++ "    out.default(\"panic-action\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "action-crash", p7_build_args())
    p7_assert_failure_contains(result, "panic-action", "action crash target")
    p7_assert_failure_contains(result, "failed with exit code", "action crash rc")
    p7_assert_failure_contains(result, "build.w:5:5", "action crash source location")
    print("ok")
