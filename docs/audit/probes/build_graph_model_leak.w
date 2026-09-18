use BuildGraphModel

extern fn with_getenv_str(name: &str) -> str

fn target(name: str, output: str) -> BuildGraphTarget:
    var t = empty_build_graph_target()
    t.kind = 16
    t.name = name
    t.output = output
    t

let mode = unsafe { with_getenv_str("WITH_AUDIT_MODEL_CASE") }
if mode == "baseline":
    let graph = empty_build_graph()
    assert(graph.targets.len() == 0)
else if mode == "one":
    var graph = empty_build_graph()
    graph.ok = true
    graph.targets.push(target("one", "out/one"))
    let selected = build_graph_filter_target(&graph, "one")
    assert(selected.ok)
else if mode == "success":
    var graph = empty_build_graph()
    graph.ok = true
    var a = target("a", "out/a")
    a.deps.push("b")
    graph.targets.push(move a)
    graph.targets.push(target("b", "out/b"))
    let selected = build_graph_filter_target(&graph, "a")
    assert(selected.ok)
else if mode == "missing":
    var graph = empty_build_graph()
    graph.ok = true
    var a = target("a", "out/a")
    a.deps.push("missing")
    graph.targets.push(move a)
    let selected = build_graph_filter_target(&graph, "a")
    assert(not selected.ok)
else if mode == "cycle":
    var graph = empty_build_graph()
    graph.ok = true
    var a = target("a", "out/a")
    a.deps.push("b")
    var b = target("b", "out/b")
    b.deps.push("a")
    graph.targets.push(move a)
    graph.targets.push(move b)
    let selected = build_graph_filter_target(&graph, "a")
    assert(not selected.ok)
else if mode == "parse":
    let parsed = parse_build_graph("WITH_BUILD_GRAPH\t2\npackage\tp\tv\ntarget\t16\tone\t\t0\t0\tout/one\narg\t0\tvalue\n")
    assert(parsed.ok)
else if mode == "single":
    var graph = empty_build_graph()
    graph.ok = true
    var a = target("a", "out/a")
    a.deps.push("b")
    graph.targets.push(move a)
    graph.targets.push(target("b", "out/b"))
    let selected = build_graph_filter_single_target(&graph, "a")
    assert(selected.ok)
else if mode == "all":
    var graph = empty_build_graph()
    graph.ok = true
    graph.targets.push(target("a", "out/a"))
    graph.targets.push(target("b", "out/b"))
    let selected = build_graph_filter_target(&graph, "")
    assert(selected.ok)
else:
    panic("unknown case")

print("build-graph-model-leak-case: " ++ mode)
