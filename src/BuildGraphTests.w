// BuildGraphTests -- native test graph target execution.

use Resolve
use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport

pub fn build_graph_test_target_files(root: str, entry: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    if not build_graph_path_has_glob(entry):
        files.push(resolve_join(root, entry))
        return files

    let entry_dir = build_graph_dirname(entry)
    let pattern = build_graph_path_basename(entry)
    let search_dir = if entry_dir == ".": root else: build_graph_resolve_project_path(root, entry_dir)
    let candidates = collect_test_files(search_dir)
    for ci in 0..candidates.len() as i32:
        let candidate = candidates.get(ci as i64)
        let base = build_graph_path_basename(candidate)
        if build_graph_single_star_pattern_matches(pattern, base):
            files.push(candidate)
    files

fn build_graph_test_compiler_arg(arg: str) -> str:
    let prefix = "compiler="
    if arg.starts_with(prefix):
        return arg.slice(prefix.len(), arg.len())
    ""

pub fn build_graph_test_compiler(root: str, target: BuildGraphTarget) -> str:
    for ai in 0..target.args.len() as i32:
        let value = build_graph_test_compiler_arg(target.args.get(ai as i64))
        if value.len() > 0:
            return build_graph_resolve_project_path(root, value)
    ""

fn build_graph_append_test_args(argv: str, target: BuildGraphTarget) -> str:
    var out = argv
    for ai in 0..target.args.len() as i32:
        let arg = target.args.get(ai as i64)
        if build_graph_test_compiler_arg(arg).len() == 0:
            out = build_graph_argv_append(out, arg)
    out

pub fn build_graph_run_external_test_file(root: str, target: BuildGraphTarget, compiler_path: str, test_path: str) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/test-graph"), target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: could not create test output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let base = build_graph_path_basename(test_path)
    let stdout_path = resolve_join(capture_dir, base ++ ".stdout")
    let stderr_path = resolve_join(capture_dir, base ++ ".stderr")
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "test")
    argv = build_graph_append_test_args(argv, target)
    argv = build_graph_argv_append(argv, "--quiet")
    argv = build_graph_argv_append(argv, build_graph_path_for_child_process(root, test_path))
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, 300000)
    if rc == 124:
        build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' timed out in '" ++ test_path ++ "'; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' failed in '" ++ test_path ++ f"' with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return rc
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    0
