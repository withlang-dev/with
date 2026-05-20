// BuildGraphCompiler -- With compiler project build graph handlers.

use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport

fn bgc_trim_space_and_newlines(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn bgc_capture_text(root: str, label: str, argv: str, timeout_ms: i32) -> str:
    let capture_dir = build_graph_resolve_project_path(root, "out/tmp")
    let _mkdir = build_graph_rt_mkdir_p(capture_dir)
    let stamp = f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let stdout_path = build_graph_resolve_project_path(capture_dir, label ++ "." ++ stamp ++ ".stdout")
    let stderr_path = build_graph_resolve_project_path(capture_dir, label ++ "." ++ stamp ++ ".stderr")
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc != 0:
        let _remove_stdout = build_graph_rt_remove_file(stdout_path)
        let _remove_stderr = build_graph_rt_remove_file(stderr_path)
        return ""
    let stdout = bgc_trim_space_and_newlines(build_graph_rt_read_file(stdout_path))
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    stdout

fn bgc_resolve_seed_compiler(root: str) -> str:
    let explicit = build_graph_rt_getenv("WITH")
    if explicit.len() > 0:
        return explicit
    let canonical = build_graph_resolve_project_path(root, "out/bin/with")
    if build_graph_rt_file_exists(canonical) != 0:
        return canonical
    var path_probe = ""
    path_probe = build_graph_argv_append(path_probe, "with")
    path_probe = build_graph_argv_append(path_probe, "--version")
    let installed_version = bgc_capture_text(root, "with-version", path_probe, 30000)
    if installed_version.len() > 0:
        return "with"
    let seed = build_graph_resolve_project_path(root, "src/main")
    if build_graph_rt_file_exists(seed) != 0:
        return seed
    "with"

fn bgc_compiler_path(root: str, entry: str) -> str:
    if entry == "seed":
        return bgc_resolve_seed_compiler(root)
    build_graph_resolve_project_path(root, entry)

pub fn build_graph_run_with_compiler_build(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' requires a compiler path or 'seed'")
        return 1
    if target.inputs.len() == 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' requires a source input")
        return 1
    if target.output.len() == 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' requires an output path")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = bgc_compiler_path(root, target.entry)
    let source_path = build_graph_resolve_project_path(root, target.inputs.get(0))
    let output_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_file_exists(source_path) == 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    if compiler_path != "with" and build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return 1
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
        return 1
    let tmp_output = output_path ++ ".tmp." ++ f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let _remove_tmp = build_graph_rt_remove_file(tmp_output)
    let _remove_tmp_dsym = build_graph_rt_remove_dir(tmp_output ++ ".dSYM")
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "build")
    argv = build_graph_argv_append(argv, source_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, tmp_output)
    let capture_dir = build_graph_resolve_project_path(root, "out/command/" ++ target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' could not create capture directory: " ++ capture_dir)
        return 1
    let stdout_path = build_graph_resolve_project_path(capture_dir, "stdout.txt")
    let stderr_path = build_graph_resolve_project_path(capture_dir, "stderr.txt")
    let old_out_dir = build_graph_rt_getenv("WITH_OUT_DIR")
    let _set_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", build_graph_resolve_project_path(root, "out"))
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, 600000)
    let _restore_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", old_out_dir)
    if rc == 124:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return rc
    if build_graph_rt_file_exists(tmp_output) == 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' did not produce output: " ++ tmp_output)
        return 1
    let _remove_old = build_graph_rt_remove_file(output_path)
    let _remove_old_dsym = build_graph_rt_remove_dir(output_path ++ ".dSYM")
    if build_graph_rt_rename_file(tmp_output, output_path) != 0:
        build_graph_rt_eprint("error: with_compiler_build target '" ++ target.name ++ "' could not move output to: " ++ output_path)
        return 1
    let _move_dsym = build_graph_rt_rename_file(tmp_output ++ ".dSYM", output_path ++ ".dSYM")
    if not target.output.contains(".o"):
        build_graph_rt_write("[" ++ target.name ++ "] wrote " ++ target.output ++ "\n")
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    0

pub fn build_graph_run_with_compiler_ir(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' requires a compiler path")
        return 1
    if target.inputs.len() == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' requires a source input")
        return 1
    if target.output.len() == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' requires an output path")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = bgc_compiler_path(root, target.entry)
    let source_path = build_graph_resolve_project_path(root, target.inputs.get(0))
    let output_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_file_exists(source_path) == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    if compiler_path != "with" and build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return 1
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
        return 1
    let tmp_output = output_path ++ ".tmp." ++ f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let stderr_path = tmp_output ++ ".stderr"
    let _remove_tmp = build_graph_rt_remove_file(tmp_output)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "ir")
    argv = build_graph_argv_append(argv, source_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let old_out_dir = build_graph_rt_getenv("WITH_OUT_DIR")
    let _set_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", build_graph_resolve_project_path(root, "out"))
    let rc = build_graph_rt_exec_argv_capture(argv, tmp_output, stderr_path, 600000)
    let _restore_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", old_out_dir)
    if rc == 124:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' timed out; output=" ++ tmp_output ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ f"' failed with exit code {rc}; output=" ++ tmp_output ++ " stderr=" ++ stderr_path)
        return rc
    if build_graph_rt_file_exists(tmp_output) == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' did not produce output: " ++ tmp_output)
        return 1
    let _remove_old = build_graph_rt_remove_file(output_path)
    if build_graph_rt_rename_file(tmp_output, output_path) != 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' could not move output to: " ++ output_path)
        return 1
    let _remove_stderr_done = build_graph_rt_remove_file(stderr_path)
    0
