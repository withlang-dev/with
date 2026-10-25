//! expect-stdout: ok
// #2452: the evaluated-graph cache key covers the directories build(ctx)
// listed. A build.w that declares one input per file under src/ evaluated
// once; deleting a file there kept the cached graph, whose declared input
// was then missing. Evaluation now records `list\t<dir>` in build.w.effects
// and the key re-lists each such directory.
use BuildGraphCache
use std.fs

fn main:
    let root = "out/tmp/graph_cache_listing_key_test"
    let src = root ++ "/src"
    assert(mkdir_p(src) == 0)
    assert(write_file(src ++ "/a.txt", "a\n") == 0)
    assert(write_file(src ++ "/b.txt", "b\n") == 0)
    let effects = build_cache_build_effects_path(root)
    assert(mkdir_p(build_cache_state_dir(root)) == 0)
    assert(write_file(effects, "list\t" ++ src ++ "\n") == 0)
    let both = build_cache_graph_env_fingerprint(root)
    assert(remove_file(src ++ "/b.txt") == 0)
    let one = build_cache_graph_env_fingerprint(root)
    assert(one != both)
    // The listing is the input, not file contents: editing a file keeps it.
    assert(write_file(src ++ "/a.txt", "a changed\n") == 0)
    assert(build_cache_graph_env_fingerprint(root) == one)
    assert(write_file(src ++ "/b.txt", "b\n") == 0)
    assert(build_cache_graph_env_fingerprint(root) == both)
    print("ok")
