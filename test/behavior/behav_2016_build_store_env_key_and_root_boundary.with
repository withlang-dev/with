//! expect-stdout: ok

// #2016: two facts the build store keys a target on.
// - A target's declared environment shapes what it builds (with-sha256's
//   WITH_FILE_PREFIX_MAP), so the same target under another environment is
//   another entry.
// - An output names its worktree only where the root is a whole path: a
//   sibling that shares its prefix (the root /x/wt beside /x/wt-drivers/with,
//   a driver path stage1 records in seed-input.json) is another directory,
//   and refusing to store it made a second worktree rebuild stage1.

use BuildGraphCache
use BuildGraphModel
use std.fs
use std.process

fn action(name: str, output: str) -> BuildGraphTarget:
    var target = empty_build_graph_target()
    target.kind = 23
    target.name = name
    target.output = output
    target.inputs.push("in.txt")
    target

fn worktree(base: &str, name: &str) -> str:
    let root = base ++ "/" ++ name
    assert(mkdir_p(root ++ "/out") == 0)
    assert(write_file(root ++ "/in.txt", "input\n") == 0)
    root

fn run(root: &str, target: &BuildGraphTarget, text: &str):
    let empty: List[str] = List.new()
    assert(write_file(root ++ "/" ++ target.output, text) == 0)
    build_cache_record(root, target, empty, empty)
    assert(build_cache_freshness_reason(root, target, false) == "fresh")

fn main:
    let base = f"out/tmp/build-store-2016-keys-{pid()}"
    assert(set_env("WITH_BUILD_CACHE_DIR", base ++ "/store") == 0)
    let a = worktree(base, "wt")

    // The declared environment keys the entry.
    var mapped = action("mapped", "out/mapped.txt")
    mapped.env.push("WITH_FILE_PREFIX_MAP=" ++ a ++ "=/src-a")
    run(a, &mapped, "mapped\n")
    let b = worktree(base, "other")
    var mapped_b = action("mapped", "out/mapped.txt")
    mapped_b.env.push("WITH_FILE_PREFIX_MAP=" ++ b ++ "=/src-a")
    assert(build_cache_store_restore(b, &mapped_b))
    var remapped = action("mapped", "out/mapped.txt")
    remapped.env.push("WITH_FILE_PREFIX_MAP=" ++ b ++ "=/src-b")
    let c = worktree(base, "third")
    if build_cache_store_restore(c, &remapped):
        print("FAILED: a target under another declared environment was served this one's entry")
        assert(false)

    // A sibling sharing the root's prefix is not the root.
    let sibling = action("sibling", "out/sibling.txt")
    run(a, &sibling, "{\"driver\": \"" ++ a ++ "-drivers/with\"}\n")
    if not build_cache_store_restore(b, &sibling):
        print("FAILED: an output naming " ++ a ++ "-drivers, a sibling of the root, was not stored")
        assert(false)
    // The root itself, whole, still is.
    let named = action("named", "out/named.txt")
    run(a, &named, "{\"driver\": \"" ++ a ++ "\"}\n")
    assert(not build_cache_store_restore(b, &named))

    assert(remove_tree(base) == 0)
    print("ok")
