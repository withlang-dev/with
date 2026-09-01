// BuildGraphMaterialize -- convert comptime std.build values into BuildGraph.

use BuildGraphKinds
use BuildGraphModel
use BuildGraphRuntime
use ComptimeValue
use Sema

extern fn with_getenv_str(name: &str) -> str
extern fn with_eprint(s: &str) -> Unit
extern fn with_str_clone_ref(s: &str) -> str

type BuildGraphMaterializer {
    sema: Sema,
    extras: Vec[ComptimeValue],
}

fn build_graph_materializer(sema: Sema, extras: Vec[ComptimeValue]) -> BuildGraphMaterializer:
    BuildGraphMaterializer { sema, extras }

impl BuildGraphMaterializer:
    fn error(message: str) -> BuildGraph:
        var graph = empty_build_graph()
        graph.error_msg = message
        graph

    fn field_index(type_id: i32, field_name: &str) -> i32:
        let field_sym = self.sema.pool_lookup_symbol(field_name)
        if field_sym == 0:
            return -1
        let field_count = self.sema.type_reflection_field_count(type_id)
        for i in 0..field_count:
            if self.sema.type_reflection_field_name(type_id, i) == field_sym:
                return i
        -1

    fn field_value(value: &ComptimeValue, field_name: &str) -> ComptimeValue:
        if value.kind != ComptimeValueKind.CV_STRUCT:
            return comptime_value_invalid()
        let index = self.field_index(value.type_id, field_name)
        if index < 0 or index >= value.extra_count:
            return comptime_value_invalid()
        comptime_value_clone(self.extras.get((value.extra_start + index) as i64))

    fn expect_str_field(value: &ComptimeValue, field_name: &str) -> ComptimeValue:
        let field = self.field_value(value, field_name)
        if field.kind != ComptimeValueKind.CV_STR:
            return comptime_value_invalid()
        field

    fn expect_i32_field(value: &ComptimeValue, field_name: &str) -> ComptimeValue:
        let field = self.field_value(value, field_name)
        if field.kind != ComptimeValueKind.CV_INT:
            return comptime_value_invalid()
        field

    fn string_vec_field(value: &ComptimeValue, field_name: &str) -> Vec[str]:
        let out: Vec[str] = Vec.new()
        let field = self.field_value(value, field_name)
        if field.kind != ComptimeValueKind.CV_VEC and field.kind != ComptimeValueKind.CV_ARRAY:
            return out
        for i in 0..field.extra_count:
            let item = self.extras.get((field.extra_start + i) as i64)
            if item.kind == ComptimeValueKind.CV_STR:
                out.push(with_str_clone_ref(item.text))
        out

fn build_graph_materialized_target(kind: i32, name: &str, entry: &str, target_kind: i32, optimize_mode: i32, output: &str) -> BuildGraphTarget:
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

impl BuildGraphMaterializer:
    fn target_name_exists(graph: &BuildGraph, name: &str) -> bool:
        for i in 0..graph.targets.len() as i32:
            if graph.targets.get(i as i64).name == name:
                return true
        false

    fn materialize_target(value: &ComptimeValue, graph: BuildGraph) -> BuildGraph:
        var out = graph
        if value.kind != ComptimeValueKind.CV_STRUCT:
            out.error_msg = "build target is not a struct value"
            return out
        let kind_value = self.expect_i32_field(value, "kind")
        let name_value = self.expect_str_field(value, "name")
        let entry_value = self.expect_str_field(value, "entry")
        let output_value = self.expect_str_field(value, "output")
        let target_kind_value = self.expect_i32_field(value, "target_kind")
        let optimize_value = self.expect_i32_field(value, "optimize_mode")
        if kind_value.kind == ComptimeValueKind.CV_INVALID or name_value.kind == ComptimeValueKind.CV_INVALID or entry_value.kind == ComptimeValueKind.CV_INVALID or output_value.kind == ComptimeValueKind.CV_INVALID or target_kind_value.kind == ComptimeValueKind.CV_INVALID or optimize_value.kind == ComptimeValueKind.CV_INVALID:
            out.error_msg = "build target has a field with the wrong comptime value type"
            return out
        if name_value.text.len() == 0:
            out.error_msg = "build target name cannot be empty"
            return out
        if self.target_name_exists(out, name_value.text):
            out.error_msg = "duplicate build target name: " ++ name_value.text
            return out
        let kind = kind_value.data0 as i32
        if build_graph_kind_removed(kind):
            out.error_msg = "build target '" ++ name_value.text ++ "' kind " ++ build_graph_kind_name(kind) ++ f" ({kind}) was removed; regenerate your build graph"
            return out
        if not build_graph_kind_valid(kind):
            out.error_msg = "build target '" ++ name_value.text ++ "' has invalid kind " ++ f"{kind}"
            return out
        if not build_graph_kind_implemented(kind):
            out.error_msg = "build target '" ++ name_value.text ++ "' kind is not implemented: " ++ build_graph_kind_name(kind)
            return out
        let target_kind = target_kind_value.data0 as i32
        if not build_graph_target_valid(target_kind):
            out.error_msg = "build target '" ++ name_value.text ++ "' has invalid target platform"
            return out
        var target = build_graph_materialized_target(kind, name_value.text, entry_value.text, target_kind, optimize_value.data0 as i32, output_value.text)
        target.system_libs = self.string_vec_field(value, "system_libs")
        target.include_paths = self.string_vec_field(value, "include_paths")
        target.defines = self.string_vec_field(value, "defines")
        target.inputs = self.string_vec_field(value, "inputs")
        target.extra_outputs = self.string_vec_field(value, "extra_outputs")
        target.write_scopes = self.string_vec_field(value, "write_scopes")
        target.deps = self.string_vec_field(value, "deps")
        target.args = self.string_vec_field(value, "args")
        let timeout_field = self.field_value(value, "timeout_ms")
        if timeout_field.kind == ComptimeValueKind.CV_INT:
            target.timeout_ms = timeout_field.data0 as i32
        let cwd_field = self.field_value(value, "cwd")
        if cwd_field.kind == ComptimeValueKind.CV_STR:
            target.cwd = with_str_clone_ref(cwd_field.text)
        target.env = self.string_vec_field(value, "env")
        let network_field = self.field_value(value, "network")
        if network_field.kind == ComptimeValueKind.CV_BOOL:
            target.network = if network_field.data0 != 0: 1 else: 0
        let parallel_field = self.field_value(value, "parallel")
        if parallel_field.kind == ComptimeValueKind.CV_BOOL:
            target.parallel = if parallel_field.data0 != 0: 1 else: 0
        let action = self.field_value(value, "action")
        if kind == 23:
            if action.kind != ComptimeValueKind.CV_FN:
                out.error_msg = "action target '" ++ name_value.text ++ "' is missing an action function"
                return out
            target.action_fn = action.data0 as i32
            target.action_source_paths = self.action_source_closure(action.data0 as i32)
        else if action.kind == ComptimeValueKind.CV_FN and action.data0 != 0:
            let action_name = self.sema.pool_resolve(action.data0 as i32)
            if action_name != "build_noop_action":
                out.error_msg = "non-action target '" ++ name_value.text ++ "' has an action function"
                return out
        out.targets.push(move target)
        out

    // #686: the module files an action's code can reach — its defining file
    // plus the transitive use closure from Sema's retained module graph. A
    // file-granular over-approximation of the call closure: it can
    // over-invalidate, never under-invalidate. Empty result = caller falls
    // back to hashing all build-graph sources.
    fn action_source_closure(action_sym: i32) -> Vec[str]:
        let empty: Vec[str] = Vec.new()
        let found = self.sema.fn_decl_source_paths.get(action_sym)
        if not found.is_some():
            build_graph_rt_eprint("[graph] action closure MISS (no source path) for '" ++ self.sema.pool_resolve(action_sym) ++ "'")
            return empty
        let defining = found.unwrap()
        var start_module = -1
        for mi in 0..self.sema.module_paths.len() as i32:
            if self.sema.module_paths.get(mi as i64) == defining:
                start_module = mi
                break
        if start_module < 0:
            build_graph_rt_eprint("[graph] action closure MISS (module not found) for '" ++ self.sema.pool_resolve(action_sym) ++ "' defined in '" ++ defining ++ "'")
            return empty
        let visited: Vec[i32] = Vec.new()
        let queue: Vec[i32] = Vec.new()
        visited.push(start_module)
        queue.push(start_module)
        var qi = 0
        while qi < queue.len() as i32:
            let m = queue.get(qi as i64)
            qi = qi + 1
            let istart = self.sema.module_import_starts.get(m as i64)
            let icount = self.sema.module_import_counts.get(m as i64)
            for ii in 0..icount:
                let t = self.sema.module_import_targets.get((istart + ii) as i64)
                if t < 0:
                    continue
                var seen = false
                for vi in 0..visited.len() as i32:
                    if visited.get(vi as i64) == t:
                        seen = true
                        break
                if not seen:
                    visited.push(t)
                    queue.push(t)
        let paths: Vec[str] = Vec.new()
        for i in 0..visited.len() as i32:
            paths.push(with_str_clone_ref(self.sema.module_paths.get(visited.get(i as i64) as i64)))
        paths

    fn materialize_generated_source(value: &ComptimeValue, graph: BuildGraph) -> BuildGraph:
        var out = graph
        if value.kind != ComptimeValueKind.CV_STRUCT:
            out.error_msg = "generated source is not a struct value"
            return out
        let path = self.expect_str_field(value, "path")
        let contents = self.expect_str_field(value, "contents")
        if path.kind == ComptimeValueKind.CV_INVALID or contents.kind == ComptimeValueKind.CV_INVALID:
            out.error_msg = "generated source has a field with the wrong comptime value type"
            return out
        // D32: take intended; clone until the D32 compiler is the seed
        // (old §2.4 Drop-owner gate on ComptimeValue).
        out.generated_sources.push(BuildGraphGeneratedSource { path: path.text.clone(), contents: contents.text.clone() })
        out

pub type BuildGraphMaterializeResult {
    graph: BuildGraph,
    sema: Sema,
}

impl BuildGraphMaterializer:
    fn materialize_build(value: &ComptimeValue) -> BuildGraph:
        if value.kind != ComptimeValueKind.CV_STRUCT:
            return self.error("build(ctx) did not return a Build value")
        var graph = empty_build_graph()
        let package = self.field_value(value, "package")
        if package.kind != ComptimeValueKind.CV_STRUCT:
            return self.error("Build.package is not a Package value")
        let package_name = self.expect_str_field(package, "name")
        let package_version = self.expect_str_field(package, "version")
        if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
            with_eprint(f"[graph] build value start={value.extra_start} count={value.extra_count} extras_len={self.extras.len()}")
            for tf in 0..value.extra_count:
                let tfv = self.extras.get((value.extra_start + tf) as i64)
                with_eprint(f"[graph] field[{tf}] kind={tfv.kind as i32} text=" ++ (if tfv.kind == ComptimeValueKind.CV_STR: tfv.text else: ""))
        let default_target = self.expect_str_field(value, "default_target")
        if package_name.kind == ComptimeValueKind.CV_INVALID or package_version.kind == ComptimeValueKind.CV_INVALID or default_target.kind == ComptimeValueKind.CV_INVALID:
            return self.error("Build has a field with the wrong comptime value type")
        graph.package_name = with_str_clone_ref(package_name.text)
        graph.package_version = with_str_clone_ref(package_version.text)
        graph.default_target = with_str_clone_ref(default_target.text)
        if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
            with_eprint("[graph] after-assign dt=" ++ graph.default_target)

        let generated_sources = self.field_value(value, "generated_sources")
        if generated_sources.kind != ComptimeValueKind.CV_VEC and generated_sources.kind != ComptimeValueKind.CV_ARRAY:
            return self.error("Build.generated_sources is not a vector")
        for i in 0..generated_sources.extra_count:
            graph = self.materialize_generated_source(self.extras.get((generated_sources.extra_start + i) as i64), move graph)
            if graph.error_msg.len() > 0:
                return graph

        let targets = self.field_value(value, "targets")
        if targets.kind != ComptimeValueKind.CV_VEC and targets.kind != ComptimeValueKind.CV_ARRAY:
            return self.error("Build.targets is not a vector")
        for i in 0..targets.extra_count:
            graph = self.materialize_target(self.extras.get((targets.extra_start + i) as i64), move graph)
            if graph.error_msg.len() > 0:
                return graph
            if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
                with_eprint(f"[graph] after-target-{i} dt=" ++ graph.default_target)
        graph = build_graph_complete_edges(move graph)
        graph.ok = true
        if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
            with_eprint("[graph] after-ok dt=" ++ graph.default_target)
        graph.raw_text = build_graph_emit(graph)
        if with_getenv_str("WITH_TRACE_GRAPH").len() > 0:
            with_eprint("[graph] after-emit dt=" ++ graph.default_target)
        graph

// Returns the materialized graph alongside the Sema handed in: the
// materializer stores the Sema (refs cannot be struct fields), so the
// caller gets it back instead of reusing a moved value (§3.8).
pub fn materialize_build_graph_from_comptime(sema: Sema, value: &ComptimeValue, extras: Vec[ComptimeValue]) -> BuildGraphMaterializeResult:
    var mat = build_graph_materializer(move sema, move extras)
    let graph = mat.materialize_build(value)
    BuildGraphMaterializeResult { graph, sema: move mat.sema }
