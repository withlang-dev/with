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
    deps: Vec[str],
    args: Vec[str],
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

fn build_graph_generated_source_new(path: str, contents: str) -> BuildGraphGeneratedSource:
    BuildGraphGeneratedSource { path, contents }

fn build_graph_target_new(kind: i32, name: str, entry: str, target_kind: i32, optimize_mode: i32, output: str) -> BuildGraphTarget:
    BuildGraphTarget {
        kind,
        name,
        entry,
        output,
        target_kind,
        optimize_mode,
        system_libs: Vec.new(),
        include_paths: Vec.new(),
        defines: Vec.new(),
        inputs: Vec.new(),
        extra_outputs: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
    }

fn build_graph_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let text_len = text.len() as i32
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text.byte_at(i as i64)
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() as i64 - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn build_graph_split_fields(line: str) -> Vec[str]:
    let fields: Vec[str] = Vec.new()
    var cur = ""
    var escaped = false
    for i in 0..line.len() as i32:
        let ch = line.byte_at(i as i64)
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

fn build_graph_escape(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
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

pub fn build_graph_emit(graph: BuildGraph) -> str:
    var out = "WITH_BUILD_GRAPH\t2\n"
    out = out ++ "package\t" ++ build_graph_escape(graph.package_name) ++ "\t" ++ build_graph_escape(graph.package_version) ++ "\n"
    if graph.default_target.len() > 0:
        out = out ++ "default_target\t" ++ build_graph_escape(graph.default_target) ++ "\n"
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources.get(gi as i64)
        out = out ++ "generated_source\t" ++ build_graph_escape(generated.path) ++ "\t" ++ build_graph_escape(generated.contents) ++ "\n"
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        out = out ++ "target\t"
        out = out ++ f"{target.kind}\t"
        out = out ++ build_graph_escape(target.name) ++ "\t"
        out = out ++ build_graph_escape(target.entry) ++ "\t"
        out = out ++ f"{target.target_kind}\t"
        out = out ++ f"{target.optimize_mode}\t"
        out = out ++ build_graph_escape(target.output) ++ "\n"
        for li in 0..target.system_libs.len() as i32:
            out = out ++ "system_lib\t" ++ f"{ti}\t" ++ build_graph_escape(target.system_libs.get(li as i64)) ++ "\n"
        for ii in 0..target.include_paths.len() as i32:
            out = out ++ "include_path\t" ++ f"{ti}\t" ++ build_graph_escape(target.include_paths.get(ii as i64)) ++ "\n"
        for di in 0..target.defines.len() as i32:
            out = out ++ "define\t" ++ f"{ti}\t" ++ build_graph_escape(target.defines.get(di as i64)) ++ "\n"
        for ini in 0..target.inputs.len() as i32:
            out = out ++ "input\t" ++ f"{ti}\t" ++ build_graph_escape(target.inputs.get(ini as i64)) ++ "\n"
        for outi in 0..target.extra_outputs.len() as i32:
            out = out ++ "extra_output\t" ++ f"{ti}\t" ++ build_graph_escape(target.extra_outputs.get(outi as i64)) ++ "\n"
        for depi in 0..target.deps.len() as i32:
            out = out ++ "dep\t" ++ f"{ti}\t" ++ build_graph_escape(target.deps.get(depi as i64)) ++ "\n"
        for ai in 0..target.args.len() as i32:
            out = out ++ "arg\t" ++ f"{ti}\t" ++ build_graph_escape(target.args.get(ai as i64)) ++ "\n"
    out

fn build_graph_parse_i32(text: str) -> i32:
    var sign = 1
    var i = 0
    if text.len() > 0 and text.byte_at(0) == 45:
        sign = -1
        i = 1
    var value = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 57:
            break
        value = value * 10 + (ch - 48)
        i = i + 1
    value * sign

pub fn parse_build_graph(text: str) -> BuildGraph:
    var graph = empty_build_graph()
    graph.raw_text = text
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
        let fields = build_graph_split_fields(lines.get(i as i64))
        if fields.len() == 0:
            i = i + 1
            continue
        let tag = fields.get(0)
        if tag == "package":
            if fields.len() != 3:
                graph.error_msg = "invalid package line in build graph"
                return graph
            graph.package_name = fields.get(1)
            graph.package_version = fields.get(2)
        else if tag == "default_target":
            if fields.len() != 2:
                graph.error_msg = "invalid default_target line in build graph"
                return graph
            graph.default_target = fields.get(1)
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
                graph.targets.push(current)
            let output = if graph_version == 2: fields.get(6) else: ""
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
            current.system_libs.push(fields.get(2))
        else if tag == "include_path":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid include_path line in build graph"
                return graph
            current.include_paths.push(fields.get(2))
        else if tag == "define":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid define line in build graph"
                return graph
            current.defines.push(fields.get(2))
        else if tag == "input":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid input line in build graph"
                return graph
            current.inputs.push(fields.get(2))
        else if tag == "extra_output":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid extra_output line in build graph"
                return graph
            current.extra_outputs.push(fields.get(2))
        else if tag == "dep":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid dep line in build graph"
                return graph
            current.deps.push(fields.get(2))
        else if tag == "arg":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid arg line in build graph"
                return graph
            current.args.push(fields.get(2))
        else:
            graph.error_msg = "unknown build graph line: " ++ tag
            return graph
        i = i + 1
    if has_current:
        graph.targets.push(current)
    graph.ok = true
    graph

pub fn build_graph_filter_target(graph: &BuildGraph, target_name: str) -> BuildGraph:
    var out = empty_build_graph()
    out.ok = graph.ok
    out.error_msg = graph.error_msg
    out.raw_text = graph.raw_text
    out.package_name = graph.package_name
    out.package_version = graph.package_version
    out.default_target = graph.default_target
    for gi in 0..graph.generated_sources.len() as i32:
        out.generated_sources.push(graph.generated_sources.get(gi as i64))
    if target_name.len() == 0:
        for ti_all in 0..graph.targets.len() as i32:
            out.targets.push(graph.targets.get(ti_all as i64))
        out.raw_text = build_graph_emit(out)
        return out
    let selected = build_graph_select_target_closure(graph, target_name)
    if not selected.ok:
        out.ok = false
        out.error_msg = selected.error_msg
    else:
        for ti in 0..selected.targets.len() as i32:
            out.targets.push(selected.targets.get(ti as i64))
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

fn build_graph_name_vec_contains(names: Vec[str], name: str) -> bool:
    for i in 0..names.len() as i32:
        if names.get(i as i64) == name:
            return true
    false

fn build_graph_find_target_index(graph: &BuildGraph, name: str) -> i32:
    for i in 0..graph.targets.len() as i32:
        if graph.targets.get(i as i64).name == name:
            return i
    -1

fn build_graph_find_output_producer_index(graph: &BuildGraph, path: str, consumer_name: str) -> i32:
    if path.len() == 0:
        return -1
    for i in 0..graph.targets.len() as i32:
        let target = graph.targets.get(i as i64)
        if target.name != consumer_name and target.output.len() > 0 and target.output == path:
            return i
    -1

fn build_graph_selected_targets_add(selected: BuildGraphSelectedTargets, graph: &BuildGraph, name: str) -> BuildGraphSelectedTargets:
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
    let target = graph.targets.get(index as i64)
    out.visiting_names.push(name)
    for di in 0..target.deps.len() as i32:
        out = build_graph_selected_targets_add(move out, graph, target.deps.get(di as i64))
        if not out.ok:
            return out
    let entry_producer = build_graph_find_output_producer_index(graph, target.entry, target.name)
    if entry_producer >= 0:
        out = build_graph_selected_targets_add(move out, graph, graph.targets.get(entry_producer as i64).name)
        if not out.ok:
            return out
    for ii in 0..target.inputs.len() as i32:
        let input_producer = build_graph_find_output_producer_index(graph, target.inputs.get(ii as i64), target.name)
        if input_producer >= 0:
            out = build_graph_selected_targets_add(move out, graph, graph.targets.get(input_producer as i64).name)
            if not out.ok:
                return out
    out.selected_names.push(name)
    out.targets.push(target)
    out

fn build_graph_select_target_closure(graph: &BuildGraph, target_name: str) -> BuildGraphSelectedTargets:
    var selected = build_graph_selected_targets_new()
    build_graph_selected_targets_add(move selected, graph, target_name)
