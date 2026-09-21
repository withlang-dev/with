//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// Survey (the default) keeps going past a failed target, never through it:
// a target whose dependency failed does not run, directly or through a
// Group, and an unrelated target still does. zlib-promote once ran after
// zlib-test failed and overwrote lib/std/zl with a corpus that did not
// compile.
fn main:
    let case_dir = p7_prepare_case("survey_skips_dependents", "p7survey")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn fails(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    let _ = ctx\n"
    build_text = build_text ++ "    1\n\n"
    build_text = build_text ++ "fn writes(ctx: ActionCtx) -> i32: ctx.fs().write_text(ctx.output(), \"ran\")\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var gate = target_new(.Action, \"gate\", \"\").output(\"out/action/gate.txt\")\n"
    build_text = build_text ++ "    gate.action = fails\n"
    build_text = build_text ++ "    out = out.add_target(move gate)\n"
    build_text = build_text ++ "    var direct = target_new(.Action, \"direct\", \"\").output(\"out/action/direct.txt\").dep(\"gate\")\n"
    build_text = build_text ++ "    direct.action = writes\n"
    build_text = build_text ++ "    out = out.add_target(move direct)\n"
    build_text = build_text ++ "    out = out.add_target(target_new(.Group, \"gated\", \"\").dep(\"gate\"))\n"
    build_text = build_text ++ "    var through = target_new(.Action, \"through\", \"\").output(\"out/action/through.txt\").dep(\"gated\")\n"
    build_text = build_text ++ "    through.action = writes\n"
    build_text = build_text ++ "    out = out.add_target(move through)\n"
    build_text = build_text ++ "    var apart = target_new(.Action, \"apart\", \"\").output(\"out/action/apart.txt\")\n"
    build_text = build_text ++ "    apart.action = writes\n"
    build_text = build_text ++ "    out = out.add_target(move apart)\n"
    build_text = build_text ++ "    out = out.add_target(target_new(.Group, \"all\", \"\").dep(\"direct\").dep(\"through\").dep(\"apart\"))\n"
    build_text = build_text ++ "    out.default(\"all\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "survey-skips", p7_build_args())
    p7_assert_failure_contains(result, "skipping 'direct' (dependency 'gate'", "a direct dependent is skipped")
    p7_assert_failure_contains(result, "skipping 'through' (dependency 'gated'", "a dependent through a Group is skipped")
    assert(not file_exists(p7_join(case_dir, "out/action/direct.txt")))
    assert(not file_exists(p7_join(case_dir, "out/action/through.txt")))
    assert(file_exists(p7_join(case_dir, "out/action/apart.txt")))
    print("ok")
