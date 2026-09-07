use BuildGraphModel

fn target(name: str, output: str) -> BuildGraphTarget:
    var t = empty_build_graph_target()
    t.kind = 16
    t.name = name
    t.output = output
    t

fn assert_target_name(graph: &BuildGraph, index: i64, name: &str):
    let t = &graph.targets[index]
    assert(t.name == name)

var diamond = empty_build_graph()
diamond.ok = true
var a = target("a", "out/a")
a.deps.push("b")
a.deps.push("c")
var b = target("b", "out/b")
b.deps.push("d")
var c = target("c", "out/c")
c.deps.push("d")
let d = target("d", "out/d")
diamond.targets.push(move a)
diamond.targets.push(move c)
diamond.targets.push(move b)
diamond.targets.push(d)
let selected = build_graph_filter_target(&diamond, "a")
assert(selected.ok)
assert(selected.targets.len() == 4)
assert_target_name(&selected, 0, "d")
assert_target_name(&selected, 1, "b")
assert_target_name(&selected, 2, "c")
assert_target_name(&selected, 3, "a")

let single = build_graph_filter_single_target(&diamond, "a")
assert(single.ok)
assert(single.targets.len() == 1)
assert_target_name(&single, 0, "a")

let all = build_graph_filter_target(&diamond, "")
assert(all.ok)
assert(all.targets.len() == 4)
assert_target_name(&all, 0, "a")
assert_target_name(&all, 1, "c")
assert_target_name(&all, 2, "b")
assert_target_name(&all, 3, "d")

var cycle = empty_build_graph()
cycle.ok = true
var cycle_a = target("cycle-a", "out/cycle-a")
cycle_a.deps.push("cycle-b")
var cycle_b = target("cycle-b", "out/cycle-b")
cycle_b.deps.push("cycle-a")
cycle.targets.push(move cycle_a)
cycle.targets.push(move cycle_b)
let cycle_selected = build_graph_filter_target(&cycle, "cycle-a")
assert(not cycle_selected.ok)
assert(cycle_selected.error_msg.contains("cycle"))

var missing = empty_build_graph()
missing.ok = true
var missing_a = target("missing-a", "out/missing-a")
missing_a.deps.push("absent")
missing.targets.push(move missing_a)
let missing_selected = build_graph_filter_target(&missing, "missing-a")
assert(not missing_selected.ok)
assert(missing_selected.error_msg.contains("absent"))
let unknown_selected = build_graph_filter_target(&missing, "unknown")
assert(not unknown_selected.ok)
assert(unknown_selected.error_msg.contains("unknown"))

let valid_text = "WITH_BUILD_GRAPH\t2\npackage\tp\tv\ntarget\t16\tone\t\t0\t0\tout/one\narg\t0\tvalue\n"
let valid = parse_build_graph(valid_text)
assert(valid.ok)
assert(valid.targets.len() == 1)
assert(valid.targets[0].args.len() == 1)

let wrong_index_text = "WITH_BUILD_GRAPH\t2\npackage\tp\tv\ntarget\t16\tone\t\t0\t0\tout/one\narg\t999\tmisattached\n"
let wrong_index = parse_build_graph(wrong_index_text)
assert(wrong_index.ok)
assert(wrong_index.targets[0].args.len() == 1)
assert(wrong_index.targets[0].args[0] == "misattached")

let partial_integer_text = "WITH_BUILD_GRAPH\t2\npackage\tp\tv\ntarget\t16junk\tpartial\t\t0oops\t0more\tout/partial\n"
let partial_integer = parse_build_graph(partial_integer_text)
assert(partial_integer.ok)
assert(partial_integer.targets[0].kind == 16)
assert(partial_integer.targets[0].target_kind == 0)
assert(partial_integer.targets[0].optimize_mode == 0)

let empty_integer_text = "WITH_BUILD_GRAPH\t2\npackage\tp\tv\ntarget\t\tempty\t\t\t\tout/empty\n"
let empty_integer = parse_build_graph(empty_integer_text)
assert(empty_integer.ok)
assert(empty_integer.targets[0].kind == 0)

let duplicate_text = "WITH_BUILD_GRAPH\t2\npackage\tp\tv\ntarget\t16\tsame\t\t0\t0\tout/one\ntarget\t16\tsame\t\t0\t0\tout/two\n"
let duplicate = parse_build_graph(duplicate_text)
assert(duplicate.ok)
assert(duplicate.targets.len() == 2)

var roundtrip_source = empty_build_graph()
roundtrip_source.ok = true
roundtrip_source.package_name = "p"
roundtrip_source.package_version = "v"
var parallel_target = target("parallel", "out/parallel")
parallel_target.parallel = 1
roundtrip_source.targets.push(move parallel_target)
let emitted = build_graph_emit(&roundtrip_source)
let roundtrip = parse_build_graph(emitted)
assert(not roundtrip.ok)
assert(roundtrip.error_msg.contains("parallel"))

print("build-graph-model-matrix: ok")
