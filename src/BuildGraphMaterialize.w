// BuildGraphMaterialize -- convert comptime std.build values into BuildGraph.

use BuildGraphKinds
use BuildGraphModel
use ComptimeValue
use Sema

type BuildGraphMaterializer {
    sema: Sema,
    extras: Vec[ComptimeValue],
}

fn build_graph_materializer(sema: Sema, extras: Vec[ComptimeValue]) -> BuildGraphMaterializer:
    BuildGraphMaterializer { sema, extras }

fn BuildGraphMaterializer.error(self: BuildGraphMaterializer, message: str) -> BuildGraph:
    var graph = empty_build_graph()
    graph.error_msg = message
    graph

fn BuildGraphMaterializer.field_index(self: BuildGraphMaterializer, type_id: i32, field_name: str) -> i32:
    let field_sym = self.sema.pool_lookup_symbol(field_name)
    if field_sym == 0:
        return -1
    let field_count = self.sema.type_reflection_field_count(type_id)
    for i in 0..field_count:
        if self.sema.type_reflection_field_name(type_id, i) == field_sym:
            return i
    -1

fn BuildGraphMaterializer.field_value(self: BuildGraphMaterializer, value: ComptimeValue, field_name: str) -> ComptimeValue:
    if value.kind != ComptimeValueKind.CV_STRUCT:
        return comptime_value_invalid()
    let index = self.field_index(value.type_id, field_name)
    if index < 0 or index >= value.extra_count:
        return comptime_value_invalid()
    self.extras.get((value.extra_start + index) as i64)

fn BuildGraphMaterializer.expect_str_field(self: BuildGraphMaterializer, value: ComptimeValue, field_name: str) -> ComptimeValue:
    let field = self.field_value(value, field_name)
    if field.kind != ComptimeValueKind.CV_STR:
        return comptime_value_invalid()
    field

fn BuildGraphMaterializer.expect_i32_field(self: BuildGraphMaterializer, value: ComptimeValue, field_name: str) -> ComptimeValue:
    let field = self.field_value(value, field_name)
    if field.kind != ComptimeValueKind.CV_INT:
        return comptime_value_invalid()
    field

fn BuildGraphMaterializer.string_vec_field(self: BuildGraphMaterializer, value: ComptimeValue, field_name: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let field = self.field_value(value, field_name)
    if field.kind != ComptimeValueKind.CV_VEC and field.kind != ComptimeValueKind.CV_ARRAY:
        return out
    for i in 0..field.extra_count:
        let item = self.extras.get((field.extra_start + i) as i64)
        if item.kind == ComptimeValueKind.CV_STR:
            out.push(item.text)
    out

fn build_graph_materialized_target(kind: i32, name: str, entry: str, target_kind: i32, optimize_mode: i32, output: str) -> BuildGraphTarget:
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
        write_scopes: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
        action_fn: 0,
    }

fn BuildGraphMaterializer.target_name_exists(self: BuildGraphMaterializer, graph: BuildGraph, name: str) -> bool:
    for i in 0..graph.targets.len() as i32:
        if graph.targets.get(i as i64).name == name:
            return true
    false

fn BuildGraphMaterializer.materialize_target(self: BuildGraphMaterializer, value: ComptimeValue, graph: BuildGraph) -> BuildGraph:
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
    let action = self.field_value(value, "action")
    if kind == 23:
        if action.kind != ComptimeValueKind.CV_FN:
            out.error_msg = "action target '" ++ name_value.text ++ "' is missing an action function"
            return out
        target.action_fn = action.data0 as i32
    else if action.kind == ComptimeValueKind.CV_FN and action.data0 != 0:
        let action_name = self.sema.pool_resolve(action.data0 as i32)
        if action_name != "build_noop_action":
            out.error_msg = "non-action target '" ++ name_value.text ++ "' has an action function"
            return out
    out.targets.push(target)
    out

fn BuildGraphMaterializer.materialize_generated_source(self: BuildGraphMaterializer, value: ComptimeValue, graph: BuildGraph) -> BuildGraph:
    var out = graph
    if value.kind != ComptimeValueKind.CV_STRUCT:
        out.error_msg = "generated source is not a struct value"
        return out
    let path = self.expect_str_field(value, "path")
    let contents = self.expect_str_field(value, "contents")
    if path.kind == ComptimeValueKind.CV_INVALID or contents.kind == ComptimeValueKind.CV_INVALID:
        out.error_msg = "generated source has a field with the wrong comptime value type"
        return out
    out.generated_sources.push(BuildGraphGeneratedSource { path: path.text, contents: contents.text })
    out

pub fn materialize_build_graph_from_comptime(sema: Sema, value: ComptimeValue, extras: Vec[ComptimeValue]) -> BuildGraph:
    let mat = build_graph_materializer(sema, extras)
    if value.kind != ComptimeValueKind.CV_STRUCT:
        return mat.error("build(ctx) did not return a Build value")
    var graph = empty_build_graph()
    let package = mat.field_value(value, "package")
    if package.kind != ComptimeValueKind.CV_STRUCT:
        return mat.error("Build.package is not a Package value")
    let package_name = mat.expect_str_field(package, "name")
    let package_version = mat.expect_str_field(package, "version")
    let default_target = mat.expect_str_field(value, "default_target")
    if package_name.kind == ComptimeValueKind.CV_INVALID or package_version.kind == ComptimeValueKind.CV_INVALID or default_target.kind == ComptimeValueKind.CV_INVALID:
        return mat.error("Build has a field with the wrong comptime value type")
    graph.package_name = package_name.text
    graph.package_version = package_version.text
    graph.default_target = default_target.text

    let generated_sources = mat.field_value(value, "generated_sources")
    if generated_sources.kind != ComptimeValueKind.CV_VEC and generated_sources.kind != ComptimeValueKind.CV_ARRAY:
        return mat.error("Build.generated_sources is not a vector")
    for i in 0..generated_sources.extra_count:
        graph = mat.materialize_generated_source(extras.get((generated_sources.extra_start + i) as i64), graph)
        if graph.error_msg.len() > 0:
            return graph

    let targets = mat.field_value(value, "targets")
    if targets.kind != ComptimeValueKind.CV_VEC and targets.kind != ComptimeValueKind.CV_ARRAY:
        return mat.error("Build.targets is not a vector")
    for i in 0..targets.extra_count:
        graph = mat.materialize_target(extras.get((targets.extra_start + i) as i64), graph)
        if graph.error_msg.len() > 0:
            return graph
    graph.ok = true
    graph.raw_text = build_graph_emit(graph)
    graph
