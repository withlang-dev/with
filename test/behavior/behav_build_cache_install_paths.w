use BuildGraphCache
use BuildGraphModel
use BuildGraphOps
use std.fs
use std.process

fn check_install(root: &str, destination: str):
    var target = empty_build_graph_target()
    target.kind = 8
    target.name = "install-path"
    target.entry = "source"
    target.output = destination
    let path = build_graph_expand_install_path(root, target.output)
    let empty: Vec[str] = Vec.new()
    assert(build_graph_install_file(root, target) == 0)
    build_cache_record(root, target, empty, empty)
    let reason = build_cache_freshness_reason(root, target, false)
    if reason != "fresh": print(reason)
    assert(reason == "fresh")
    if target.output.starts_with("$INSTALL_"):
        assert(set_env("BINDIR", "other/bin") == 0)
        build_cache_forget_fingerprints()
        assert(build_cache_freshness_reason(root, target, false).starts_with("stale: output missing:"))
        assert(set_env("BINDIR", "installed/bin") == 0)
    assert(write_file(path, "changed") == 0)
    build_cache_forget_fingerprints()
    assert(build_cache_freshness_reason(root, target, false).starts_with("stale: output changed:"))
    assert(build_graph_install_file(root, target) == 0)
    build_cache_record(root, target, empty, empty)
    assert(remove_file(path) == 0)
    build_cache_forget_fingerprints()
    assert(build_cache_freshness_reason(root, target, false).starts_with("stale: output missing:"))

fn main:
    let root = f"out/build-cache-install-paths-{pid()}"
    assert(mkdir_p(root) == 0)
    assert(write_file(root ++ "/source", "installed payload") == 0)
    assert(set_env("DESTDIR", "") == 0)
    assert(set_env("BINDIR", "installed/bin") == 0)
    check_install(root, "installed/plain")
    check_install(root, "$INSTALL_BINDIR/artifact")
    check_install(root, "$INSTALL_LIBDIR/artifact")
    if env("HOME").len() > 0:
        let home_dir = f".cache/with-install-paths-{pid()}"
        check_install(root, "$HOME/" ++ home_dir ++ "/artifact")
        assert(remove_dir(env("HOME") ++ "/" ++ home_dir) == 0)
    assert(remove_tree(root) == 0)
