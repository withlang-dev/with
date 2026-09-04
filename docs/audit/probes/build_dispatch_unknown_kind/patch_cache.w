use BuildGraphRuntime

let path = "/home/shawn/workspace2/with/.audit/probes/build_dispatch_unknown_kind/out/.build-state/build-graph.cache"
let before = build_graph_rt_read_file(path)
let after = before.replace("i 0 0 0 0 0 0 0\n", "i 999 0 0 0 0 0 0\n")
assert(after != before)
assert(build_graph_rt_write_file(path, after) == 0)
