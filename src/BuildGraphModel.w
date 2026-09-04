extern fn with_str_clone_ref(s: &str) -> str
extern fn with_getenv_str(name: &str) -> str
extern fn with_eprint(s: &str) -> Unit
// BuildGraphModel -- parsed build.w graph data and serialization.

pub type BuildGraphTarget {
    kind: i32,
    name: str,
    entry: str,
    output: str,
    target_kind: i32,
    optimize_mode: i32,
    system_libs: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    inputs: Vec[str],
    extra_outputs: Vec[str],
    write_scopes: Vec[str],
    deps: Vec[str],
    args: Vec[str],
    action_fn: i32,
    timeout_ms: i32,
    cwd: str,
    env: Vec[str],
    network: i32,
    parallel: i32,
    action_source_paths: Vec[str],
}

pub type BuildGraphGeneratedSource {
    path: str,
    contents: str,
}

pub type BuildGraph {
    ok: bool,
    error_msg: str,
    raw_text: str,
    package_name: str,
    package_version: str,
    default_target: str,
    targets: Vec[BuildGraphTarget],
    generated_sources: Vec[BuildGraphGeneratedSource],
}

type BuildGraphSelectedTargets {
    ok: bool,
    error_msg: str,
    targets: Vec[BuildGraphTarget],
    selected_names: Vec[str],
    visiting_names: Vec[str],
}

pub fn empty_build_graph -> BuildGraph:
    BuildGraph {
        ok: false,
        error_msg: "",
        raw_text: "",
        package_name: "",
        package_version: "",
        default_target: "",
        targets: Vec.new(),
        generated_sources: Vec.new(),
    }

fn build_graph_generated_source_new(path: &str, contents: &str) -> BuildGraphGeneratedSource:
    BuildGraphGeneratedSource { path: with_str_clone_ref(path), contents: with_str_clone_ref(contents) }

fn build_graph_target_new(kind: i32, name: &str, entry: &str, target_kind: i32, optimize_mode: i32, output: &str) -> BuildGraphTarget:
    BuildGraphTarget {
        kind,
        name: with_str_clone_ref(name),
        entry: with_str_clone_ref(entry),
        output: with_str_clone_ref(output),
        target_kind,
        optimize_mode,
        system_libs: Vec.new(),
        include_paths: Vec.new(),
        defines: Vec.new(),
        inputs: Vec.new(),
        extra_outputs: Vec.new(),
        write_scopes: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
        action_fn: 0,
        timeout_ms: 0,
        cwd: "",
        env: Vec.new(),
        network: 0,
        parallel: 0,
        action_source_paths: Vec.new(),
    }

pub fn empty_build_graph_target -> BuildGraphTarget:
    build_graph_target_new(-1, "", "", 0, 0, "")

fn build_graph_split_nonempty_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let text_len = text.len() as i32
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text[i]
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line[line.len() as i64 - 1] == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn build_graph_split_fields(line: &str) -> Vec[str]:
    let fields: Vec[str] = Vec.new()
    var cur = ""
    var escaped = false
    for i in 0..line.len() as i32:
        let ch = line[i]
        if escaped:
            if ch == 110:
                cur = cur ++ "\n"
            else if ch == 116:
                cur = cur ++ "\t"
            else if ch == 114:
                cur = cur ++ "\r"
            else:
                cur = cur ++ line.slice(i as i64, (i + 1) as i64)
            escaped = false
        else if ch == 92:
            escaped = true
        else if ch == 9:
            fields.push(cur)
            cur = ""
        else:
            cur = cur ++ line.slice(i as i64, (i + 1) as i64)
    fields.push(cur)
    fields

fn build_graph_escape(value: &str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value[i]
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 9:
            out = out ++ "\\t"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

pub fn build_graph_emit(graph: &BuildGraph) -> str:
    var out = "WITH_BUILD_GRAPH\t2\n"
    out = out ++ "package\t" ++ build_graph_escape(graph.package_name) ++ "\t" ++ build_graph_escape(graph.package_version) ++ "\n"
    if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
        with_eprint(f"[emit] dt.len={graph.default_target.len()} dt=" ++ graph.default_target)
    if graph.default_target.len() > 0:
        out = out ++ "default_target\t" ++ build_graph_escape(graph.default_target) ++ "\n"
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources[gi]
        out = out ++ "generated_source\t" ++ build_graph_escape(generated.path) ++ "\t" ++ build_graph_escape(generated.contents) ++ "\n"
    for ti in 0..graph.targets.len() as i32:
        let target = &graph.targets[ti]
        out = out ++ "target\t"
        out = out ++ f"{target.kind}\t"
        out = out ++ build_graph_escape(target.name) ++ "\t"
        out = out ++ build_graph_escape(target.entry) ++ "\t"
        out = out ++ f"{target.target_kind}\t"
        out = out ++ f"{target.optimize_mode}\t"
        out = out ++ build_graph_escape(target.output) ++ "\n"
        for li in 0..target.system_libs.len() as i32:
            out = out ++ "system_lib\t" ++ f"{ti}\t" ++ build_graph_escape(target.system_libs[li]) ++ "\n"
        for ii in 0..target.include_paths.len() as i32:
            out = out ++ "include_path\t" ++ f"{ti}\t" ++ build_graph_escape(target.include_paths[ii]) ++ "\n"
        for di in 0..target.defines.len() as i32:
            out = out ++ "define\t" ++ f"{ti}\t" ++ build_graph_escape(target.defines[di]) ++ "\n"
        for ini in 0..target.inputs.len() as i32:
            out = out ++ "input\t" ++ f"{ti}\t" ++ build_graph_escape(target.inputs[ini]) ++ "\n"
        for outi in 0..target.extra_outputs.len() as i32:
            out = out ++ "extra_output\t" ++ f"{ti}\t" ++ build_graph_escape(target.extra_outputs[outi]) ++ "\n"
        for wsi in 0..target.write_scopes.len() as i32:
            out = out ++ "write_scope\t" ++ f"{ti}\t" ++ build_graph_escape(target.write_scopes[wsi]) ++ "\n"
        for depi in 0..target.deps.len() as i32:
            out = out ++ "dep\t" ++ f"{ti}\t" ++ build_graph_escape(target.deps[depi]) ++ "\n"
        for ai in 0..target.args.len() as i32:
            out = out ++ "arg\t" ++ f"{ti}\t" ++ build_graph_escape(target.args[ai]) ++ "\n"
        if target.timeout_ms != 0:
            out = out ++ "timeout_ms\t" ++ f"{ti}\t" ++ f"{target.timeout_ms}" ++ "\n"
        if target.cwd.len() > 0:
            out = out ++ "cwd\t" ++ f"{ti}\t" ++ build_graph_escape(target.cwd) ++ "\n"
        for ei in 0..target.env.len() as i32:
            out = out ++ "env\t" ++ f"{ti}\t" ++ build_graph_escape(target.env[ei]) ++ "\n"
        if target.network != 0:
            out = out ++ "network\t" ++ f"{ti}\t1\n"
        if target.parallel != 0:
            out = out ++ "parallel\t" ++ f"{ti}\t1\n"
    out

fn build_graph_parse_i32(text: &str) -> i32:
    var sign = 1
    var i = 0
    if text.len() > 0 and text[0] == 45:
        sign = -1
        i = 1
    var value = 0
    while i < text.len() as i32:
        let ch = text[i]
        if ch < 48 or ch > 57:
            break
        value = value * 10 + (ch - 48)
        i = i + 1
    value * sign

pub fn parse_build_graph(text: &str) -> BuildGraph:
    var graph = empty_build_graph()
    graph.raw_text = with_str_clone_ref(text)
    if text.len() == 0:
        graph.error_msg = "build.w produced an empty build graph"
        return graph
    let lines = build_graph_split_nonempty_lines(text)
    if lines.len() == 0:
        graph.error_msg = "build.w produced an empty build graph"
        return graph
    let header = build_graph_split_fields(lines.get(0))
    if header.len() != 2 or header.get(0) != "WITH_BUILD_GRAPH" or (header.get(1) != "1" and header.get(1) != "2"):
        graph.error_msg = "build.w produced an invalid build graph header"
        return graph
    let graph_version = build_graph_parse_i32(header.get(1))

    var has_current = false
    var current = build_graph_target_new(0, "", "", 0, 0, "")
    var i = 1
    while i < lines.len() as i32:
        let fields = build_graph_split_fields(lines[i])
        if fields.len() == 0:
            i = i + 1
            continue
        let tag = fields.get(0)
        if tag == "package":
            if fields.len() != 3:
                graph.error_msg = "invalid package line in build graph"
                return graph
            graph.package_name = with_str_clone_ref(fields.get(1))
            graph.package_version = with_str_clone_ref(fields.get(2))
        else if tag == "default_target":
            if fields.len() != 2:
                graph.error_msg = "invalid default_target line in build graph"
                return graph
            graph.default_target = with_str_clone_ref(fields.get(1))
        else if tag == "generated_source":
            if fields.len() != 3:
                graph.error_msg = "invalid generated_source line in build graph"
                return graph
            graph.generated_sources.push(build_graph_generated_source_new(fields.get(1), fields.get(2)))
        else if tag == "target":
            if (graph_version == 1 and fields.len() != 6) or (graph_version == 2 and fields.len() != 7):
                graph.error_msg = "invalid target line in build graph"
                return graph
            if has_current:
                graph.targets.push(move current)
            let output = if graph_version == 2: with_str_clone_ref(fields.get(6)) else: ""
            current = build_graph_target_new(
                build_graph_parse_i32(fields.get(1)),
                fields.get(2),
                fields.get(3),
                build_graph_parse_i32(fields.get(4)),
                build_graph_parse_i32(fields.get(5)),
                output,
            )
            has_current = true
        else if tag == "system_lib":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid system_lib line in build graph"
                return graph
            current.system_libs.push(with_str_clone_ref(fields.get(2)))
        else if tag == "include_path":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid include_path line in build graph"
                return graph
            current.include_paths.push(with_str_clone_ref(fields.get(2)))
        else if tag == "define":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid define line in build graph"
                return graph
            current.defines.push(with_str_clone_ref(fields.get(2)))
        else if tag == "input":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid input line in build graph"
                return graph
            current.inputs.push(with_str_clone_ref(fields.get(2)))
        else if tag == "extra_output":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid extra_output line in build graph"
                return graph
            current.extra_outputs.push(with_str_clone_ref(fields.get(2)))
        else if tag == "write_scope":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid write_scope line in build graph"
                return graph
            current.write_scopes.push(with_str_clone_ref(fields.get(2)))
        else if tag == "dep":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid dep line in build graph"
                return graph
            current.deps.push(with_str_clone_ref(fields.get(2)))
        else if tag == "arg":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid arg line in build graph"
                return graph
            current.args.push(with_str_clone_ref(fields.get(2)))
        else if tag == "timeout_ms":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid timeout_ms line in build graph"
                return graph
            current.timeout_ms = build_graph_parse_i32(fields.get(2))
        else if tag == "cwd":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid cwd line in build graph"
                return graph
            current.cwd = with_str_clone_ref(fields.get(2))
        else if tag == "env":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid env line in build graph"
                return graph
            current.env.push(with_str_clone_ref(fields.get(2)))
        else if tag == "network":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid network line in build graph"
                return graph
            current.network = build_graph_parse_i32(fields.get(2))
        else:
            graph.error_msg = "unknown build graph line: " ++ tag
            return graph
        i = i + 1
    if has_current:
        graph.targets.push(move current)
    graph.ok = true
    graph

pub fn bg_clone_str_vec(values: &Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..values.len() as i32:
        out.push(with_str_clone_ref(values[i]))
    out

// A stored element copy must own its buffers: BuildGraphTarget carries nine
// Vec[str] fields, and a bitwise element copy aliases them (#715 class), so
// two graphs dropping both free the same buffers.
fn build_graph_target_deep_copy(t: &BuildGraphTarget) -> BuildGraphTarget:
    BuildGraphTarget {
        kind: t.kind,
        name: with_str_clone_ref(t.name),
        entry: with_str_clone_ref(t.entry),
        output: with_str_clone_ref(t.output),
        target_kind: t.target_kind,
        optimize_mode: t.optimize_mode,
        system_libs: bg_clone_str_vec(&t.system_libs),
        include_paths: bg_clone_str_vec(&t.include_paths),
        defines: bg_clone_str_vec(&t.defines),
        inputs: bg_clone_str_vec(&t.inputs),
        extra_outputs: bg_clone_str_vec(&t.extra_outputs),
        write_scopes: bg_clone_str_vec(&t.write_scopes),
        deps: bg_clone_str_vec(&t.deps),
        args: bg_clone_str_vec(&t.args),
        action_fn: t.action_fn,
        timeout_ms: t.timeout_ms,
        cwd: with_str_clone_ref(t.cwd),
        env: bg_clone_str_vec(&t.env),
        network: t.network,
        parallel: t.parallel,
        action_source_paths: bg_clone_str_vec(&t.action_source_paths),
    }

fn build_graph_output_index(paths: &Vec[str], path: &str) -> i64:
    for i in 0..paths.len() as i32:
        if paths[i] == path:
            return i as i64
    -1

// A consumer of a produced path depends on its producer whether or not
// build.w spelled the edge: the graph already knows who writes the file, so
// it declares the edge itself (#700) instead of making the author repeat it.
// Without the edge, consumption is declaration-order dependent and skips
// dep_rebuilt propagation, so a consumer can be served a pre-swap artifact
// while its producer is rebuilt — a binary assembled from two tree states
// that never coexisted. Inferred edges are data edges (the consumer reads the
// file), so they feed dep_rebuilt exactly as a written .dep() does; an
// ordering-only edge stays the author's to declare. Runs once, before the
// graph is emitted, so cached graph text and every filtered subgraph carry
// the completed edges.
pub fn build_graph_complete_edges(graph: BuildGraph) -> BuildGraph:
    var out = graph
    let out_paths: Vec[str] = Vec.new()
    let out_owners: Vec[str] = Vec.new()
    for i in 0..out.targets.len() as i32:
        let t = &out.targets[i]
        if t.output.len() > 0:
            out_paths.push(with_str_clone_ref(t.output))
            out_owners.push(with_str_clone_ref(t.name))
        for oi in 0..t.extra_outputs.len() as i32:
            out_paths.push(with_str_clone_ref(t.extra_outputs[oi]))
            out_owners.push(with_str_clone_ref(t.name))
    for i in 0..out.targets.len() as i32:
        let to_add: Vec[str] = Vec.new()
        let t = &out.targets[i]
        let consumed: Vec[str] = Vec.new()
        if t.entry.len() > 0:
            consumed.push(with_str_clone_ref(t.entry))
        for ii in 0..t.inputs.len() as i32:
            consumed.push(with_str_clone_ref(t.inputs[ii]))
        for ci in 0..consumed.len() as i32:
            let producer_idx = build_graph_output_index(&out_paths, consumed[ci])
            if producer_idx < 0:
                continue
            let producer = out_owners.get(producer_idx)
            if producer == t.name or t.deps.contains(producer) or to_add.contains(producer):
                continue
            if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
                with_eprint("[graph] inferred edge " ++ t.name ++ " -> " ++ producer)
            to_add.push(with_str_clone_ref(producer))
        for ai in 0..to_add.len() as i32:
            out.targets[i].deps.push(with_str_clone_ref(to_add[ai]))
    out

pub fn build_graph_filter_target(graph: &BuildGraph, target_name: &str) -> BuildGraph:
    var out = empty_build_graph()
    out.ok = graph.ok
    out.error_msg = with_str_clone_ref(graph.error_msg)
    out.raw_text = with_str_clone_ref(graph.raw_text)
    out.package_name = with_str_clone_ref(graph.package_name)
    out.package_version = with_str_clone_ref(graph.package_version)
    out.default_target = with_str_clone_ref(graph.default_target)
    for gi in 0..graph.generated_sources.len() as i32:
        let bgm_gen = &graph.generated_sources[gi]
        out.generated_sources.push(BuildGraphGeneratedSource { path: with_str_clone_ref(bgm_gen.path), contents: with_str_clone_ref(bgm_gen.contents) })
    if target_name.len() == 0:
        for ti_all in 0..graph.targets.len() as i32:
            out.targets.push(build_graph_target_deep_copy(&graph.targets[ti_all]))
        out.raw_text = build_graph_emit(out)
        return out
    var selected = build_graph_select_target_closure(graph, target_name)
    if not selected.ok:
        out.ok = false
        out.error_msg = move selected.error_msg
    else:
        for ti in 0..selected.targets.len() as i32:
            out.targets.push(build_graph_target_deep_copy(&selected.targets[ti]))
        if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
            with_eprint("[filt] pre-emit dt=" ++ out.default_target)
        out.raw_text = build_graph_emit(out)
    out

pub fn build_graph_filter_single_target(graph: &BuildGraph, target_name: &str) -> BuildGraph:
    var out = empty_build_graph()
    out.ok = graph.ok
    out.error_msg = with_str_clone_ref(graph.error_msg)
    out.raw_text = with_str_clone_ref(graph.raw_text)
    out.package_name = with_str_clone_ref(graph.package_name)
    out.package_version = with_str_clone_ref(graph.package_version)
    out.default_target = with_str_clone_ref(graph.default_target)
    for gi in 0..graph.generated_sources.len() as i32:
        let bgm_gen = &graph.generated_sources[gi]
        out.generated_sources.push(BuildGraphGeneratedSource { path: with_str_clone_ref(bgm_gen.path), contents: with_str_clone_ref(bgm_gen.contents) })
    if target_name.len() == 0:
        out.ok = false
        out.error_msg = "--no-deps requires an explicit build.w target"
        return out
    let index = build_graph_find_target_index(graph, target_name)
    if index < 0:
        out.ok = false
        out.error_msg = "build.w did not declare target '" ++ target_name ++ "'"
        return out
    out.targets.push(build_graph_target_deep_copy(&graph.targets[index]))
    out.raw_text = build_graph_emit(out)
    out

fn build_graph_selected_targets_new -> BuildGraphSelectedTargets:
    BuildGraphSelectedTargets {
        ok: true,
        error_msg: "",
        targets: Vec.new(),
        selected_names: Vec.new(),
        visiting_names: Vec.new(),
    }

fn build_graph_name_vec_contains(names: &Vec[str], name: &str) -> bool:
    for i in 0..names.len() as i32:
        if names[i] == name:
            return true
    false

fn build_graph_find_target_index(graph: &BuildGraph, name: &str) -> i32:
    for i in 0..graph.targets.len() as i32:
        // Borrow the stored target. Vec.get currently materializes an owned
        // aggregate here, so merely searching would drop aliases of its nine
        // owned vectors and corrupt the graph before dependency traversal.
        let candidate = &graph.targets[i]
        if candidate.name == name:
            return i
    -1

fn build_graph_find_output_producer_index(graph: &BuildGraph, path: &str, consumer_name: &str) -> i32:
    if path.len() == 0:
        return -1
    for i in 0..graph.targets.len() as i32:
        let target = &graph.targets[i]
        if target.name != consumer_name and target.output.len() > 0 and target.output == path:
            return i
    -1

fn build_graph_selected_targets_add(selected: BuildGraphSelectedTargets, graph: &BuildGraph, name: &str) -> BuildGraphSelectedTargets:
    var out = selected
    if not out.ok:
        return out
    if build_graph_name_vec_contains(out.selected_names, name):
        return out
    if build_graph_name_vec_contains(out.visiting_names, name):
        out.ok = false
        out.error_msg = "build.w target dependency cycle includes '" ++ name ++ "'"
        return out
    let index = build_graph_find_target_index(graph, name)
    if index < 0:
        out.ok = false
        out.error_msg = "build.w did not declare target '" ++ name ++ "'"
        return out
    let target = &graph.targets[index]
    out.visiting_names.push(with_str_clone_ref(name))
    for di in 0..target.deps.len() as i32:
        out = build_graph_selected_targets_add(move out, graph, target.deps[di])
        if not out.ok:
            return out
    let entry_producer = build_graph_find_output_producer_index(graph, target.entry, target.name)
    if entry_producer >= 0:
        let producer = &graph.targets[entry_producer]
        out = build_graph_selected_targets_add(move out, graph, producer.name)
        if not out.ok:
            return out
    for ii in 0..target.inputs.len() as i32:
        let input_producer = build_graph_find_output_producer_index(graph, target.inputs[ii], target.name)
        if input_producer >= 0:
            let producer = &graph.targets[input_producer]
            out = build_graph_selected_targets_add(move out, graph, producer.name)
            if not out.ok:
                return out
    out.selected_names.push(with_str_clone_ref(name))
    out.targets.push(build_graph_target_deep_copy(target))
    out

fn build_graph_select_target_closure(graph: &BuildGraph, target_name: &str) -> BuildGraphSelectedTargets:
    var selected = build_graph_selected_targets_new()
    build_graph_selected_targets_add(move selected, graph, target_name)
