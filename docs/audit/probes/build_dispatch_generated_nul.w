use BuildGraphDispatch
use BuildGraphModel
use BuildGraphRuntime
use std.string

let root = "/home/shawn/workspace2/with/.audit/probes/build_dispatch_generated_nul_direct"
assert(build_graph_rt_mkdir_p(root ++ "/out/gen") == 0)

var alias = StringBuilder.new()
alias.push_str("out/gen/accepted.w")
alias.push_byte(0 as u8)
alias.push_str("ignored")

var graph = empty_build_graph()
graph.generated_sources.push(BuildGraphGeneratedSource {
    path: "out/gen/accepted.w",
    contents: "first",
})
graph.generated_sources.push(BuildGraphGeneratedSource {
    path: alias.to_str(),
    contents: "second",
})

print("validation-rc=" ++ f"{build_graph_validate_outputs(root, &graph, "")}")
print("write-rc=" ++ f"{build_graph_write_generated_sources(root, &graph)}")
print("actual=" ++ build_graph_rt_read_file(root ++ "/out/gen/accepted.w"))
