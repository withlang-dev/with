use BuildGraphCache
use BuildGraphRuntime

fn accepts(root: &str, text: &str) -> bool:
    let state = root ++ "/out/.build-state"
    assert(build_graph_rt_mkdir_p(state) == 0)
    assert(build_graph_rt_write_file(state ++ "/build-graph.cache", text) == 0)
    build_cache_graph_try_read(root, "k").ok

let root = "/home/shawn/workspace2/with/.audit/probes/build_cache_graph_parser"
let valid = "WGRAPH1\ns1\nk\ns0\n\ns0\n\ns0\n\ns0\n\nt0\ng0\n"
let bad_separator = "WGRAPH1\ns1\nkXs0\n\ns0\n\ns0\n\ns0\n\nt0\ng0\n"
let bad_target_count = "WGRAPH1\ns1\nk\ns0\n\ns0\n\ns0\n\ns0\n\ntnot-a-number\ng0\n"
let negative_target_count = "WGRAPH1\ns1\nk\ns0\n\ns0\n\ns0\n\ns0\n\nt-1\ng0\n"
assert(accepts(root, valid))
print("bad-separator accepted=" ++ f"{accepts(root, bad_separator)}")
print("bad-target-count accepted=" ++ f"{accepts(root, bad_target_count)}")
print("negative-target-count accepted=" ++ f"{accepts(root, negative_target_count)}")
print("trailing-data accepted=" ++ f"{accepts(root, valid ++ "trailing-data")}")
