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

fn bgc_first_trimmed_line(text: str) -> str:
    var end = text.len() as i32
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 10 or ch == 13:
            end = i
            break
    bgc_trim_space_and_newlines(text.slice(0, end as i64))

fn bgc_find_substr(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if text.len() < needle.len():
        return -1
    let last = text.len() as i32 - needle.len() as i32
    for i in 0..(last + 1):
        var matched = true
        for j in 0..needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
        if matched:
            return i
    -1

fn bgc_replace_all(text: str, needle: str, replacement: str) -> str:
    if needle.len() == 0:
        return text
    var out = ""
    var start = 0
    while start < text.len() as i32:
        let remaining = text.len() as i32 - start
        if remaining < needle.len() as i32:
            out = out ++ text.slice(start as i64, text.len())
            return out
        let at = bgc_find_substr(text.slice(start as i64, text.len()), needle)
        if at < 0:
            out = out ++ text.slice(start as i64, text.len())
            return out
        let matched_at = start + at
        out = out ++ text.slice(start as i64, matched_at as i64) ++ replacement
        start = matched_at + needle.len() as i32
    out

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

fn bgc_resolve_compiler_version(root: str) -> str:
    let version_path = build_graph_resolve_project_path(root, "src/version")
    let base = bgc_first_trimmed_line(build_graph_rt_read_file(version_path))
    if base.len() == 0:
        return ""
    let override_version = build_graph_rt_getenv("WITH_VERSION")
    if override_version.len() > 0:
        return override_version
    var hash_argv = ""
    hash_argv = build_graph_argv_append(hash_argv, "git")
    hash_argv = build_graph_argv_append(hash_argv, "-C")
    hash_argv = build_graph_argv_append(hash_argv, root)
    hash_argv = build_graph_argv_append(hash_argv, "rev-parse")
    hash_argv = build_graph_argv_append(hash_argv, "--short=9")
    hash_argv = build_graph_argv_append(hash_argv, "HEAD")
    let short_hash = bgc_capture_text(root, "git-hash", hash_argv, 30000)
    var count_argv = ""
    count_argv = build_graph_argv_append(count_argv, "git")
    count_argv = build_graph_argv_append(count_argv, "-C")
    count_argv = build_graph_argv_append(count_argv, root)
    count_argv = build_graph_argv_append(count_argv, "rev-list")
    count_argv = build_graph_argv_append(count_argv, "--count")
    count_argv = build_graph_argv_append(count_argv, "HEAD")
    let commit_count = bgc_capture_text(root, "git-count", count_argv, 30000)
    if short_hash.len() > 0 and commit_count.len() > 0:
        return base ++ "-" ++ commit_count ++ "-g" ++ short_hash
    base

fn bgc_write_versioned_source(root: str, source_rel: str, output_rel: str, version: str) -> i32:
    let source_path = build_graph_resolve_project_path(root, source_rel)
    let output_path = build_graph_resolve_project_path(root, output_rel)
    let text = build_graph_rt_read_file(source_path)
    if text.len() == 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints could not read source: " ++ source_path)
        return 1
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints could not create output directory: " ++ output_dir)
        return 1
    let placeholder = "WITH_VERSION" ++ "_PLACEHOLDER"
    let replaced = bgc_replace_all(text, placeholder, version)
    if build_graph_rt_write_file(output_path, replaced) != 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints could not write: " ++ output_path)
        return 1
    0

pub fn build_graph_generate_compiler_entrypoints(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints target '" ++ target.name ++ "' requires a stamp output")
        return 1
    let version = bgc_resolve_compiler_version(root)
    if version.len() == 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints target '" ++ target.name ++ "' could not resolve compiler version from src/version")
        return 1
    let main_rc = bgc_write_versioned_source(root, "src/main.w", "out/gen/main.w", version)
    if main_rc != 0:
        return main_rc
    let bootstrap_rc = bgc_write_versioned_source(root, "src/bootstrap_main.w", "out/gen/bootstrap_main.w", version)
    if bootstrap_rc != 0:
        return bootstrap_rc
    let emit_temp_rc = bgc_write_versioned_source(root, "src/main_emit_temp.w", "out/gen/main_emit_temp.w", version)
    if emit_temp_rc != 0:
        return emit_temp_rc
    let version_file = build_graph_resolve_project_path(root, "out/gen/version.txt")
    if build_graph_rt_write_file(version_file, version ++ "\n") != 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints could not write: " ++ version_file)
        return 1
    let stamp_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_write_file(stamp_path, version ++ "\n") != 0:
        build_graph_rt_eprint("error: generate_compiler_entrypoints could not write stamp: " ++ stamp_path)
        return 1
    0

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
        return if rc == 0: 1 else: rc
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
        return if rc == 0: 1 else: rc
    if build_graph_rt_file_exists(tmp_output) == 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' did not produce output: " ++ tmp_output)
        return 1
    let _remove_old = build_graph_rt_remove_file(output_path)
    if build_graph_rt_rename_file(tmp_output, output_path) != 0:
        build_graph_rt_eprint("error: with_compiler_ir target '" ++ target.name ++ "' could not move output to: " ++ output_path)
        return 1
    let _remove_stderr_done = build_graph_rt_remove_file(stderr_path)
    0
