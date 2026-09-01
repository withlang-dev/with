//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

// #921 C1: a plain (non-migrate, non-intercept) Workspace flow inside an
// Action runs NATIVELY in the compiled build runner — create_workspace,
// add_string, options round-trip, and compile() through a spawned
// `with __workspace-compile` child. Pins the file-backed workspace state
// and the WITH_BUILD_COMPILER env seam.

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("workspace_native", "p7wsnative")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn ws_action(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    let ws = ctx.create_workspace(\"hello-ws\")\n"
    build_text = build_text ++ "    ws.add_string(\"hello_main.w\", \"fn main:\\n    print(\\\"ws native ok\\\")\\n\")\n"
    build_text = build_text ++ "    var opts = ws.options()\n"
    build_text = build_text ++ "    opts.output_path = \"out/wsbin\"\n"
    build_text = build_text ++ "    ws.set_options(opts)\n"
    build_text = build_text ++ "    let result = ws.compile()\n"
    build_text = build_text ++ "    assert(result.rc == 0)\n"
    build_text = build_text ++ "    assert(result.artifacts.len() == 1)\n"
    build_text = build_text ++ "    assert(ctx.fs().exists(\"out/wsbin\"))\n"
    build_text = build_text ++ "    assert(ctx.fs().write_text(ctx.output(), ws.name()) == 0)\n"
    build_text = build_text ++ "    0\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"ws-check\", \"\").output(\"out/action/ws-check.txt\")\n"
    build_text = build_text ++ "    target.action = ws_action\n"
    build_text = build_text ++ "    target = target.write_scope(\"out\")\n"
    build_text = build_text ++ "    out = out.add_target(move target)\n"
    build_text = build_text ++ "    out.default(\"ws-check\")\n"
    p7_write(case_dir, "build.w", build_text)
    let result = p7_run(case_dir, "workspace-native", p7_build_args())
    p7_assert_success(result, "native workspace compile")
    p7_assert_file_contains(case_dir, "out/action/ws-check.txt", "hello-ws")
    print("ok")
