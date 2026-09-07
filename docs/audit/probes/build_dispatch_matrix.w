use BuildGraphDispatch
use BuildGraphModel
use BuildGraphRuntime

fn target(kind: i32, name: str, output: str) -> BuildGraphTarget:
    var t = empty_build_graph_target()
    t.kind = kind
    t.name = name
    t.output = output
    t

let root = "/home/shawn/workspace2/with/.audit/probes/build_dispatch_matrix"

var unique = empty_build_graph()
unique.generated_sources.push(BuildGraphGeneratedSource { path: "out/gen/a.w", contents: "a" })
var unique_target = target(16, "response", "out/response.txt")
unique_target.extra_outputs.push("out/extra.txt")
unique.targets.push(move unique_target)
assert(build_graph_validate_outputs(root, &unique, "") == 0)

var duplicate_generated = empty_build_graph()
duplicate_generated.generated_sources.push(BuildGraphGeneratedSource { path: "out/gen/a.w", contents: "a" })
duplicate_generated.generated_sources.push(BuildGraphGeneratedSource { path: "out/gen/a.w", contents: "b" })
assert(build_graph_validate_outputs(root, &duplicate_generated, "") != 0)

var generated_target_collision = empty_build_graph()
generated_target_collision.generated_sources.push(BuildGraphGeneratedSource { path: "out/shared", contents: "a" })
generated_target_collision.targets.push(target(16, "response", "out/shared"))
assert(build_graph_validate_outputs(root, &generated_target_collision, "") != 0)

var target_collision = empty_build_graph()
target_collision.targets.push(target(16, "one", "out/shared"))
target_collision.targets.push(target(22, "two", "out/shared"))
assert(build_graph_validate_outputs(root, &target_collision, "") != 0)

var extra_collision = empty_build_graph()
var extra_a = target(16, "one", "out/one")
extra_a.extra_outputs.push("out/shared")
extra_collision.targets.push(move extra_a)
extra_collision.targets.push(target(22, "two", "out/shared"))
assert(build_graph_validate_outputs(root, &extra_collision, "") != 0)

assert(build_graph_write_generated_sources(root, &unique) == 0)
assert(build_graph_rt_read_file(root ++ "/out/gen/a.w") == "a")

var invalid_generated = empty_build_graph()
invalid_generated.generated_sources.push(BuildGraphGeneratedSource { path: "../outside.w", contents: "no" })
assert(build_graph_write_generated_sources(root, &invalid_generated) != 0)

print("build-dispatch-matrix: ok")
