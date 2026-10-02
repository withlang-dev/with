// The action path cases shared by behav_action_absolute_paths.w (native
// runner) and behav_action_absolute_paths_comptime.w (comptime evaluator):
// absolute paths inside the project are accepted, outside it or undeclared
// they are refused. Split by mode so each file stays inside the test
// runner's 120 s limit on a stage compiler (all ten builds took 114 s).
use pre_d_build_runner
use std.process

fn rejected_path(name: str, body: str, diagnostic: str):
    let case_dir = p7_prepare_case("action_absolute_" ++ name, "absolute_rejected")
    let action = "use std.build\nfn generate(ctx: ActionCtx) -> i32:\n    let fs = ctx.fs()\n    let root = ctx.project_info().project_root()\n    " ++ body ++ "\n    0\npub fn build(ctx: BuildCtx) -> Build:\n    var build = ctx.new_build()\n    var target = target_new(.Action, \"generate\", \"\").output(\"out/result.txt\")\n    target.action = generate\n    build = build.add_target(move target)\n    build.default(\"generate\")\n"
    p7_write(case_dir, "build.w", action)
    p7_assert_failure_contains(p7_run(case_dir, name, p7_build_args()), diagnostic, name)

fn accepted_paths(mode: &str):
    let case_dir = p7_prepare_case("action_absolute_paths_" ++ mode, "absolute_paths")
    p7_write(case_dir, "src/input.txt", "input")
    let action = "use std.build\nfn generate(ctx: ActionCtx) -> i32:\n    let fs = ctx.fs()\n    let root = ctx.project_info().project_root()\n    let input = root ++ \"/src/input.txt\"\n    assert(fs.read_text(input) == \"input\")\n    assert(fs.exists(input))\n    assert(fs.read_text(root ++ \"/src/./input.txt\") == \"input\")\n    assert(fs.write_text(root ++ \"/\" ++ ctx.output(), \"result\") == 0)\n    assert(fs.read_text(ctx.output()) == \"result\")\n    0\npub fn build(ctx: BuildCtx) -> Build:\n    var build = ctx.new_build()\n    var target = target_new(.Action, \"generate\", \"\").input(\"src/input.txt\").output(\"out/result.txt\")\n    target.action = generate\n    build = build.add_target(move target)\n    build.default(\"generate\")\n"
    p7_write(case_dir, "build.w", action)
    // The capture label is per mode: the two files that share this case run
    // in the same test batch, and a label names one capture directory that
    // each p7_run removes and recreates. Shared, the sibling's removal landed
    // between this run's mkdir and its child's open of stdout.txt, and the
    // child died with 127 and nothing captured.
    p7_assert_success(p7_run(case_dir, "action_absolute_paths_" ++ mode, p7_build_args()), "absolute paths inside project (" ++ mode ++ ")")
    p7_assert_file_contains(case_dir, "out/result.txt", "result")

pub fn run_mode(mode: &str):
    let previous_worker = env("WITH_BUILD_ACTION_WORKER").clone()
    let previous_force = env("WITH_BUILD_ACTION_FORCE").clone()
    assert(set_env("WITH_BUILD_ACTION_WORKER", if mode == "comptime": "generate" else: "") == 0)
    assert(set_env("WITH_BUILD_ACTION_FORCE", "1") == 0)
    accepted_paths(mode)
    rejected_path(mode ++ "_outside", "fs.read_text(root ++ \"/../outside.txt\")", "ToolFs path escapes project root")
    rejected_path(mode ++ "_drive", "fs.read_text(\"Z:/outside.txt\")", "ToolFs path escapes project root")
    rejected_path(mode ++ "_undeclared", "fs.write_text(root ++ \"/src/undeclared.txt\", \"bad\")", "not a declared action output")
    rejected_path(mode ++ "_mkdir", "fs.mkdir_all(root ++ \"/src/undeclared\")", "not a declared action output")
    assert(set_env("WITH_BUILD_ACTION_WORKER", previous_worker) == 0)
    assert(set_env("WITH_BUILD_ACTION_FORCE", previous_force) == 0)
