// BuildGraphDispatch -- standard build graph target execution.

use BuildGraphKinds
use BuildGraphModel
use BuildGraphOps
use BuildGraphRuntime
use BuildGraphSupport
use BuildGraphTools

pub type BuildGraphDispatchResult {
    handled: bool,
    rc: i32,
}

fn build_graph_dispatch_result(handled: bool, rc: i32) -> BuildGraphDispatchResult:
    BuildGraphDispatchResult { handled, rc }

fn build_graph_output_seen(outputs: Vec[str], path: str) -> bool:
    for i in 0..outputs.len() as i32:
        if outputs.get(i as i64) == path:
            return true
    false

fn build_graph_register_output(outputs: Vec[str], path: str) -> bool:
    if path.len() == 0:
        return true
    if build_graph_output_seen(outputs, path):
        return false
    outputs.push(path)
    true

pub fn build_graph_validate_outputs(root: str, graph: BuildGraph, output_path: str) -> i32:
    let outputs: Vec[str] = Vec.new()
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources.get(gi as i64)
        if not build_graph_register_output(outputs, resolve_join(root, generated.path)):
            build_graph_rt_eprint("error: duplicate build.w output path: " ++ generated.path)
            return 1
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        var path = ""
        if target.kind == 0:
            path = build_graph_output_path(root, target, output_path, graph.targets.len() as i32)
        else if target.kind == 1:
            path = build_graph_library_output_path(root, target, output_path, graph.targets.len() as i32)
        else if target.kind == 3:
            path = build_graph_object_output_path(root, target, output_path, graph.targets.len() as i32)
        else if target.kind == 4:
            path = build_graph_library_output_path(root, target, output_path, graph.targets.len() as i32)
        else if target.kind == 8:
            path = build_graph_expand_install_path(root, target.output)
        else if target.output.len() > 0:
            path = build_graph_resolve_project_path(root, target.output)
        if not build_graph_register_output(outputs, path):
            build_graph_rt_eprint("error: duplicate build.w output path for target '" ++ target.name ++ "': " ++ path)
            return 1
        for oi in 0..target.extra_outputs.len() as i32:
            let extra_path = build_graph_resolve_project_path(root, target.extra_outputs.get(oi as i64))
            if not build_graph_register_output(outputs, extra_path):
                build_graph_rt_eprint("error: duplicate build.w output path for target '" ++ target.name ++ "': " ++ extra_path)
                return 1
    0

pub fn build_graph_write_generated_sources(root: str, graph: BuildGraph) -> i32:
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources.get(gi as i64)
        if not build_graph_generated_path_valid(generated.path):
            build_graph_rt_eprint("error: invalid build.w generated source path: " ++ generated.path)
            return 1
        let output_path = resolve_join(root, generated.path)
        let output_dir = build_graph_dirname(output_path)
        if build_graph_rt_mkdir_p(output_dir) != 0:
            build_graph_rt_eprint("error: could not create generated source directory: " ++ output_dir)
            return 1
        if build_graph_rt_write_file(output_path, generated.contents) != 0:
            build_graph_rt_eprint("error: could not write generated source: " ++ generated.path)
            return 1
    0

fn build_graph_target_completed(completed: Vec[str], name: str) -> bool:
    for i in 0..completed.len() as i32:
        if completed.get(i as i64) == name:
            return true
    false

fn build_graph_verify_completed_deps(target: BuildGraphTarget, completed: Vec[str], operation_name: str, require_deps: bool) -> i32:
    if require_deps and target.deps.len() == 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires verification dependencies")
        return 1
    for di in 0..target.deps.len() as i32:
        let dep = target.deps.get(di as i64)
        if not build_graph_target_completed(completed, dep):
            build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' dependency has not completed: " ++ dep)
            return 1
    0

pub fn build_graph_dispatch_standard_target(root: str, target: BuildGraphTarget, completed_targets: Vec[str]) -> BuildGraphDispatchResult:
    let containment_rc = build_graph_validate_target_containment(target)
    if containment_rc != 0:
        return build_graph_dispatch_result(true, containment_rc)
    if target.kind == 7:
        return build_graph_dispatch_result(true, build_graph_run_command(root, target))
    if target.kind == 8:
        return build_graph_dispatch_result(true, build_graph_install_file(root, target))
    if target.kind == 9:
        let deps_rc = build_graph_verify_completed_deps(target, completed_targets, "group", false)
        return build_graph_dispatch_result(true, deps_rc)
    if target.kind == 10:
        return build_graph_dispatch_result(true, build_graph_compare_files(root, target, "binary_compare"))
    if target.kind == 11:
        let fixpoint_rc = build_graph_compare_files(root, target, "fixpoint_compare")
        if fixpoint_rc == 0:
            build_graph_rt_write("FIXPOINT\n")
        return build_graph_dispatch_result(true, fixpoint_rc)
    if target.kind == 12:
        return build_graph_dispatch_result(true, build_graph_compile_object(root, target, "compile_c_object", build_graph_cc_tool().executable))
    if target.kind == 13:
        return build_graph_dispatch_result(true, build_graph_assemble_to_object(root, target))
    if target.kind == 14:
        return build_graph_dispatch_result(true, build_graph_compile_ir_to_object(root, target))
    if target.kind == 15:
        return build_graph_dispatch_result(true, build_graph_create_archive(root, target))
    if target.kind == 16:
        return build_graph_dispatch_result(true, build_graph_write_response_file(root, target))
    if target.kind == 17:
        return build_graph_dispatch_result(true, build_graph_embed_object_files(root, target))
    if target.kind == 18:
        return build_graph_dispatch_result(true, build_graph_copy_manifest_files(root, target, "copy_tree"))
    if target.kind == 19:
        return build_graph_dispatch_result(true, build_graph_run_corpus_test(root, target))
    if target.kind == 20:
        let deps_rc = build_graph_verify_completed_deps(target, completed_targets, "promote_tree_if_verified", true)
        if deps_rc != 0:
            return build_graph_dispatch_result(true, deps_rc)
        return build_graph_dispatch_result(true, build_graph_promote_tree_if_verified(root, target))
    if target.kind == 21:
        return build_graph_dispatch_result(true, build_graph_run_clean(root, target))
    if target.kind == 22:
        return build_graph_dispatch_result(true, build_graph_copy_file(root, target))
    build_graph_dispatch_result(false, 0)
