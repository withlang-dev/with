//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

// #2493: a cached build graph (out/.build-state/build-graph.cache) carries
// no Sema; the driver evaluates an action itself only when no runner can be
// spawned, and then needs the live Sema the real evaluation of build.w
// produces. With the cache admitted regardless, the second `build` of a
// cold worktree — every CI lane's `:deps` then `build` — met a placeholder
// and refused every object action with "capability type is not visible to
// comptime evaluator". The cache is admitted only when the runner exists.
//
// The runner cannot be linked here on purpose: the action's unreached arm
// names a `wl_*` extern, so the runner object carries an undefined LLVM
// bridge symbol and a project has no bridge to link it against. Both runs
// then evaluate the action in the driver; the second one from the cache.

use pre_d_build_runner
use std.fs
use std.process

fn project() -> str:
    let root = p7_prepare_case("cached_graph_without_runner", "cachedgraph")
    var text = "use std.build\n\n"
    text = text ++ "extern fn wl_bridge_symbol_the_project_lacks() -> i64\n\n"
    text = text ++ "fn stamp(ctx: ActionCtx) -> i32:\n"
    text = text ++ "    if ctx.args().len() > 99: let _ = wl_bridge_symbol_the_project_lacks()\n"
    text = text ++ "    ctx.fs().write_text(ctx.output(), \"stamped\\n\")\n\n"
    text = text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    text = text ++ "    var out = ctx.new_build()\n"
    text = text ++ "    var target = target_new(.Action, \"stamp\", \"\").output(\"out/stamp.txt\")\n"
    text = text ++ "    target.action = stamp\n"
    text = text ++ "    out = out.add_target(target)\n"
    text = text ++ "    out.default(\"stamp\")\n"
    p7_write(root, "build.w", text)
    root

fn main:
    // No machine-wide runner or store: the project is as cold as a lane's.
    assert(set_env("WITH_BUILD_RUNNER_DIR", p7_abs(f"out/tmp/no-runners-{pid()}")) == 0)
    assert(set_env("WITH_BUILD_CACHE_DIR", "none") == 0)
    let root = project()
    let first = p7_run(root, "first", "build")
    p7_assert_success(first, "first build (live evaluation, writes the graph cache)")
    assert(read_file(p7_join(root, "out/stamp.txt")).unwrap() == "stamped\n")
    assert(file_exists(p7_join(root, "out/.build-state/build-graph.cache")))
    let _rm = remove_file(p7_join(root, "out/stamp.txt"))
    let second = p7_run(root, "second", "build")
    p7_assert_success(second, "second build (the graph cache is on disk, no runner)")
    assert(not second.stderr.contains("capability type"))
    assert(read_file(p7_join(root, "out/stamp.txt")).unwrap() == "stamped\n")
    print("ok")
