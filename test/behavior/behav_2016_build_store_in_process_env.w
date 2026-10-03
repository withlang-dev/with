//! expect-stdout: ok

// #2016: a target's declared environment holds for a compile the driver runs
// in-process, as it does for an action's processes. with-sha256 declares
// WITH_FILE_PREFIX_MAP (D50); the driver dropped it, the binary's debug map
// named the worktree, and the build store would not serve it to another.
// Two case directories build the same tool under one store: the binary
// names neither, and the second directory is served the first's bytes.

use pre_d_build_runner
use std.fs
use std.process

fn tool_case(name: &str) -> str:
    let root = p7_prepare_case(name, "prefixmap")
    p7_write(root, "src/tool.w", "fn main: print(42)\n")
    var text = "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n"
    text = text ++ "    let root = ctx.project_info().project_root()\n"
    text = text ++ "    let tool = target_new(.Executable, \"tool\", \"src/tool.w\").output(\"out/bin/tool\").with_env(\"WITH_FILE_PREFIX_MAP\", root ++ \"=/prefixmap-src\")\n"
    text = text ++ "    ctx.new_build().add_target(tool).default(\"tool\")\n"
    p7_write(root, "build.w", text)
    root

fn main:
    let store = p7_abs(f"out/tmp/build-store-2016-{pid()}")
    let _clear = remove_tree(store)
    assert(set_env("WITH_BUILD_CACHE_DIR", store) == 0)

    let a = tool_case("2016-prefix-map-a")
    let built = p7_run(a, "2016-prefix-map-a", p7_build_target_args(":tool"))
    p7_assert_success(built, "tool in a")
    let bin = read_file(p7_join(a, "out/bin/tool")).unwrap()
    if bin.contains(a):
        print("FAILED: out/bin/tool names its case directory " ++ a ++ "\n" ++ built.stderr)
        assert(false)
    assert(not built.stderr.contains("not stored"))

    let b = tool_case("2016-prefix-map-b")
    let served = p7_run(b, "2016-prefix-map-b", p7_build_target_args(":tool"))
    p7_assert_success(served, "tool in b")
    if not served.stderr.contains("[cache] tool: restored from the build store"):
        print("FAILED: b was not served a's tool\n" ++ served.stderr)
        assert(false)
    assert(read_file(p7_join(b, "out/bin/tool")).unwrap() == bin)

    let _done = remove_tree(store)
    print("ok")
