//! expect-stdout: ok

use pre_d_build_runner

fn rejected_path(name: str, body: str, diagnostic: str):
    let case_dir = p7_prepare_case("action_absolute_" ++ name, "absolute_rejected")
    let action = "use std.build\nfn generate(ctx: ActionCtx) -> i32:\n    let fs = ctx.fs()\n    let root = ctx.project_info().project_root()\n    " ++ body ++ "\n    0\npub fn build(ctx: BuildCtx) -> Build:\n    var build = ctx.new_build()\n    var target = target_new(.Action, \"generate\", \"\").output(\"out/result.txt\")\n    target.action = generate\n    build = build.add_target(move target)\n    build.default(\"generate\")\n"
    p7_write(case_dir, "build.w", action)
    p7_assert_failure_contains(p7_run(case_dir, name, p7_build_args()), diagnostic, name)

fn main:
    let case_dir = p7_prepare_case("action_absolute_paths", "absolute_paths")
    p7_write(case_dir, "src/input.txt", "input")
    let action = "use std.build\nfn generate(ctx: ActionCtx) -> i32:\n    let fs = ctx.fs()\n    let root = ctx.project_info().project_root()\n    let input = root ++ \"/src/input.txt\"\n    assert(fs.read_text(input) == \"input\")\n    assert(fs.exists(input))\n    assert(fs.read_text(root ++ \"/src/./input.txt\") == \"input\")\n    assert(fs.write_text(root ++ \"/\" ++ ctx.output(), \"result\") == 0)\n    assert(fs.read_text(ctx.output()) == \"result\")\n    0\npub fn build(ctx: BuildCtx) -> Build:\n    var build = ctx.new_build()\n    var target = target_new(.Action, \"generate\", \"\").input(\"src/input.txt\").output(\"out/result.txt\")\n    target.action = generate\n    build = build.add_target(move target)\n    build.default(\"generate\")\n"
    p7_write(case_dir, "build.w", action)
    p7_assert_success(p7_run(case_dir, "action_absolute_paths", p7_build_args()), "absolute paths inside project")
    p7_assert_file_contains(case_dir, "out/result.txt", "result")
    rejected_path("outside", "fs.read_text(root ++ \"/../outside.txt\")", "ToolFs path escapes project root")
    rejected_path("drive", "fs.read_text(\"Z:/outside.txt\")", "ToolFs path escapes project root")
    rejected_path("undeclared", "fs.write_text(root ++ \"/src/undeclared.txt\", \"bad\")", "not a declared action output")
    rejected_path("mkdir", "fs.mkdir_all(root ++ \"/src/undeclared\")", "not a declared action output")
    print("ok")
