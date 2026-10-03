//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

// #1899: what an action reads through ToolFs is an input of what it makes,
// declared or not. The build store keyed a target on its declared inputs
// alone, so a project whose action read other bytes from the same
// undeclared path was served another project's output: the binary-read
// fixtures got an empty file's output for a binary one, and a successful
// copy where their input was a directory. A served record now names every
// path its action read, and an entry made from other reads is refused
// before it touches the project's outputs, whether the action ran in the
// native runner or in the comptime evaluator (--strict-effects). A project
// whose reads match is still served.

use pre_d_build_runner
use std.fs
use std.process

fn project(mode: &str, name: &str) -> str:
    let root = p7_prepare_case("build_store_undeclared_read_" ++ mode ++ "_" ++ name, "undeclaredread")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "fn copy_input(ctx: ActionCtx) -> i32:\n"
    build_text = build_text ++ "    ctx.fs().write_text(ctx.output(), ctx.fs().read_text(\"input.txt\"))\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    var target = target_new(.Action, \"copy-input\", \"\").output(\"out/result.txt\")\n"
    build_text = build_text ++ "    target.action = copy_input\n"
    build_text = build_text ++ "    out = out.add_target(target)\n"
    build_text = build_text ++ "    out.default(\"copy-input\")\n"
    p7_write(root, "build.w", build_text)
    root

fn result_text(root: &str): read_file(p7_join(root, "out/result.txt")).unwrap()

fn exercise(mode: &str, args: &str, first: &str, second: &str):
    // One store per mode: a store holds one entry per key, and each mode's
    // first project must be the one that publishes it.
    let store = p7_abs(f"out/tmp/build-store-undeclared-read-{pid()}/" ++ mode)
    let _clear = remove_tree(store)
    assert(set_env("WITH_BUILD_CACHE_DIR", store) == 0)

    let a = project(mode, "a")
    p7_write(a, "input.txt", first)
    let made = p7_run(a, mode ++ "-a", args)
    p7_assert_success(made, mode ++ " a")
    assert(result_text(a) == first)

    // Other bytes at the undeclared path: the entry does not apply.
    let b = project(mode, "b")
    p7_write(b, "input.txt", second)
    let other = p7_run(b, mode ++ "-b", args)
    p7_assert_success(other, mode ++ " b")
    if result_text(b) != second:
        print(f"FAILED [{mode} b]: served another project's output: {result_text(b)}")
        print(other.stderr)
        assert(false)
    if not other.stderr.contains("does not apply"):
        print(f"FAILED [{mode} b]: the entry was not refused for its reads")
        print(other.stderr)
        assert(false)

    // A directory there: the action fails, and the entry never replaced the
    // output already on disk.
    let c = project(mode, "c")
    assert(mkdir_p(p7_join(c, "input.txt")) == 0)
    p7_write(c, "out/result.txt", "kept")
    let failed = p7_run(c, mode ++ "-c", args)
    p7_assert_failure_contains(failed, "input.txt", mode ++ " c")
    assert(result_text(c) == "kept")

    // The same bytes: served.
    let d = project(mode, "d")
    p7_write(d, "input.txt", first)
    let served = p7_run(d, mode ++ "-d", args)
    p7_assert_success(served, mode ++ " d")
    if not served.stderr.contains("copy-input: restored from the build store"):
        print(f"FAILED [{mode} d]: the same reads were not served")
        print(served.stderr)
        assert(false)
    assert(result_text(d) == first)

fn main:
    exercise("runner", "build\0", "alpha\n", "beta\n")
    exercise("evaluator", "build\0--strict-effects\0", "gamma\n", "delta\n")
    assert(set_env("WITH_BUILD_CACHE_DIR", "") == 0)
    print("ok")
