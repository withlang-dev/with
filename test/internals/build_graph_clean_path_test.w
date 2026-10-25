//! expect-stdout: ok
// #964: clean removes only strict descendants of the project root. `.`
// passed the old filter (empty, absolute, `..`) and resolved to the root, and
// the project was removed before the final remove failed.
use BuildGraphOps

fn main:
    for good in ["out", "out/tmp", "build/gen.w"]:
        assert(build_graph_clean_path_is_descendant(good))
    for bad in ["", ".", "./", "out/.", "out/../src", "..", "/tmp", "out//x", "a/./b"]:
        assert(not build_graph_clean_path_is_descendant(bad))
    print("ok")
