//! expect-stdout: ok
use BuildGraphCache
use BuildGraphModel
use BuildGraphSupport
use std.fs
use std.process

// An executable target (`.executable("spiral", "src/main.w")`) declares no
// output and still makes one, out/bin/<name>. The cache read only the
// declared output, so a deleted binary stayed "fresh": `with build` did
// nothing and `with run` said the target "did not produce executable
// output". The cache now reads the same path the runner and `with run` do.
fn main:
    let root = f"out/build-cache-executable-output-{pid()}"
    assert(mkdir_p(root ++ "/src") == 0)
    assert(write_file(root ++ "/src/main.w", "print(\"hi\")\n") == 0)
    var target = empty_build_graph_target()
    target.kind = 0
    target.name = "game"
    target.entry = "src/main.w"
    let bin = build_graph_output_path(root, &target, "", 0)
    assert(mkdir_p(root ++ "/out/bin") == 0)
    assert(write_file(bin, "binary") == 0)
    let empty: List[str] = List.new()
    build_cache_record(root, &target, &empty, &empty)
    let reason = build_cache_freshness_reason(root, &target, false)
    if reason != "fresh": print(reason)
    assert(reason == "fresh")
    assert(remove_file(bin) == 0)
    build_cache_forget_fingerprints()
    let missing = build_cache_freshness_reason(root, &target, false)
    if not missing.starts_with("stale: output missing:"): print(missing)
    assert(missing.starts_with("stale: output missing:"))
    assert(remove_tree(root) == 0)
    print("ok")
