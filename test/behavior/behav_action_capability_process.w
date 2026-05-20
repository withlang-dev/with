//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("action_process", "p7process")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn generate(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    var args: Vec[str] = Vec.new()\n"
    build_text = build_text ++ "    args |> push(\"/bin/echo\")\n"
    build_text = build_text ++ "    args |> push(\"process-ok\")\n"
    build_text = build_text ++ "    let result = ctx.process_runner().run_capture(args, \"out/process.stdout\", \"out/process.stderr\", 120000)\n"
    build_text = build_text ++ "    assert(result.rc == 0)\n"
    build_text = build_text ++ "    assert(result.stdout.contains(\"process-ok\"))\n"
    build_text = build_text ++ "    assert(result.stderr == \"\")\n"
    build_text = build_text ++ "    assert(ctx.fs().write_text(ctx.output(), result.stdout) == 0)\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"generate\", \"\").output(\"out/action/process.txt\")\n"
    build_text = build_text ++ "    target.action = generate\n"
    build_text = build_text ++ "    out = out.add_target(target)\n"
    build_text = build_text ++ "    out.default(\"generate\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "action-process", p7_build_args())
    p7_assert_success(result, "action process")
    p7_assert_file_contains(case_dir, "out/action/process.txt", "process-ok")
    print("ok")
