//! expect-stdout: ok

use pre_d_build_runner
use std.sysinfo

fn main:
    let case_dir = p7_prepare_case("action_process", "p7process")
    let with_suffix = if os() == "Windows": ".exe" else: ""
    let with_path = "../../../../out/release/bin/with" ++ with_suffix
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn generate(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    var args: Vec[str] = Vec.new()\n"
    build_text = build_text ++ "    args |> push(\"" ++ with_path ++ "\")\n"
    build_text = build_text ++ "    args |> push(\"version\")\n"
    build_text = build_text ++ "    var child_env = process_env()\n"
    build_text = build_text ++ "    child_env = child_env.set(\"WITH_OUT_DIR\", \"../../../../out\")\n"
    build_text = build_text ++ "    let result = ctx.process_runner().run_capture_with_env(args, \"out/process.stdout\", \"out/process.stderr\", 120000, child_env)\n"
    build_text = build_text ++ "    assert(result.rc == 0)\n"
    build_text = build_text ++ "    assert(result.stdout.contains(\"with \"))\n"
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
    p7_assert_file_contains(case_dir, "out/action/process.txt", "with ")
    print("ok")
