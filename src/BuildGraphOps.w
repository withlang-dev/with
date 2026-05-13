// BuildGraphOps -- generic executable build graph node operations.

use Resolve
use BuildGraphKinds
use BuildGraphModel
use BuildGraphSupport
use BuildGraphTools

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_eprint(s: str) -> void

fn build_graph_target_input_path(root: str, target: BuildGraphTarget, index: i32) -> str:
    if index == 0:
        if target.entry.len() == 0:
            return ""
        return build_graph_resolve_project_path(root, target.entry)
    let input_index = index - 1
    if input_index < 0 or input_index >= target.inputs.len() as i32:
        return ""
    build_graph_resolve_project_path(root, target.inputs.get(input_index as i64))

pub fn build_graph_compare_files(root: str, target: BuildGraphTarget, operation_name: str) -> i32:
    let left_path = build_graph_target_input_path(root, target, 0)
    let right_path = if target.args.len() > 0:
        build_graph_resolve_project_path(root, target.args.get(0))
    else:
        build_graph_target_input_path(root, target, 1)
    if left_path.len() == 0 or right_path.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires two input paths")
        return 1
    if with_fs_file_exists(left_path) == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing left input: " ++ left_path)
        return 1
    if with_fs_file_exists(right_path) == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing right input: " ++ right_path)
        return 1
    let left = with_fs_read_file(left_path)
    let right = with_fs_read_file(right_path)
    let min_len = if left.len() < right.len(): left.len() else: right.len()
    var diff_at = -1
    var i = 0
    while i < min_len:
        if left.byte_at(i as i64) != right.byte_at(i as i64):
            diff_at = i
            break
        i = i + 1
    if diff_at < 0 and left.len() != right.len():
        diff_at = min_len
    if diff_at >= 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' failed: " ++ left_path ++ " and " ++ right_path ++ f" differ at byte {diff_at}")
        return 1
    0

fn build_graph_response_arg_valid(arg: str) -> bool:
    for i in 0..arg.len() as i32:
        let ch = arg.byte_at(i as i64)
        if ch == 10 or ch == 13:
            return false
    true

fn build_graph_quote_response_arg(arg: str) -> str:
    var out = "\""
    for i in 0..arg.len() as i32:
        let ch = arg.byte_at(i as i64)
        if ch == 92 or ch == 34:
            out = out ++ "\\"
        out = out ++ arg.slice(i as i64, (i + 1) as i64)
    out ++ "\""

pub fn build_graph_write_response_file(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        with_eprint("error: generate_response_file target '" ++ target.name ++ "' requires an output path")
        return 1
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create response file directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var text = ""
    for ai in 0..target.args.len() as i32:
        let arg = target.args.get(ai as i64)
        if not build_graph_response_arg_valid(arg):
            with_eprint("error: generate_response_file target '" ++ target.name ++ "' contains an argument with a newline")
            return 1
        text = text ++ build_graph_quote_response_arg(arg) ++ "\n"
    if with_fs_write_file(output_path, text) != 0:
        with_eprint("error: could not write response file for target '" ++ target.name ++ "': " ++ output_path)
        return 1
    0

fn build_graph_append_common_compile_args(root: str, target: BuildGraphTarget, argv_blob: str) -> str:
    var out = argv_blob
    for ii in 0..target.include_paths.len() as i32:
        out = build_graph_argv_append(out, "-I" ++ build_graph_resolve_project_path(root, target.include_paths.get(ii as i64)))
    for di in 0..target.defines.len() as i32:
        out = build_graph_argv_append(out, "-D" ++ target.defines.get(di as i64))
    for ai in 0..target.args.len() as i32:
        out = build_graph_argv_append(out, target.args.get(ai as i64))
    out

pub fn build_graph_compile_object(root: str, target: BuildGraphTarget, operation_name: str, compiler: str) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires source and output paths")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let source_path = build_graph_resolve_project_path(root, target.entry)
    let output_path = build_graph_resolve_project_path(root, target.output)
    if with_fs_file_exists(source_path) == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create object output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var argv = ""
    argv = build_graph_argv_append(argv, compiler)
    argv = build_graph_append_common_compile_args(root, target, argv)
    argv = build_graph_argv_append(argv, "-c")
    argv = build_graph_argv_append(argv, source_path)
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_path)
    build_graph_exec_argv(target, operation_name, argv)

fn build_graph_archive_member_seen(inputs: Vec[str], count: i32, basename: str) -> bool:
    for i in 0..count:
        if build_graph_path_basename(inputs.get(i as i64)) == basename:
            return true
    false

pub fn build_graph_create_archive(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        with_eprint("error: create_static_archive target '" ++ target.name ++ "' requires an output path")
        return 1
    if target.inputs.len() == 0:
        with_eprint("error: create_static_archive target '" ++ target.name ++ "' requires at least one input object")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create archive output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    let resolved_inputs: Vec[str] = Vec.new()
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: create_static_archive target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
        let member = build_graph_path_basename(input_path)
        if build_graph_archive_member_seen(resolved_inputs, resolved_inputs.len() as i32, member):
            with_eprint("error: create_static_archive target '" ++ target.name ++ "' has duplicate archive member name: " ++ member)
            return 1
        resolved_inputs.push(input_path)
    let _remove_old_archive = with_fs_remove_file(output_path)
    var argv = ""
    argv = build_graph_argv_append(argv, build_graph_ar_tool().executable)
    argv = build_graph_argv_append(argv, "rcs")
    argv = build_graph_argv_append(argv, output_path)
    for ri in 0..resolved_inputs.len() as i32:
        argv = build_graph_argv_append(argv, resolved_inputs.get(ri as i64))
    build_graph_exec_argv(target, "create_static_archive", argv)

fn build_graph_asm_quote_path(path: str) -> str:
    var out = "\""
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 92 or ch == 34:
            out = out ++ "\\"
        out = out ++ path.slice(i as i64, (i + 1) as i64)
    out ++ "\""

fn build_graph_symbol_char_ok(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57) or ch == 95

fn build_graph_symbol_name_valid(sym: str) -> bool:
    if sym.len() == 0:
        return false
    let first = sym.byte_at(0)
    if first >= 48 and first <= 57:
        return false
    for i in 0..sym.len() as i32:
        if not build_graph_symbol_char_ok(sym.byte_at(i as i64)):
            return false
    true

fn build_graph_emit_embedded_blob(sym: str, input_path: str) -> str:
    ".globl _with_embedded_" ++ sym ++ "_start\n" ++
    ".globl with_embedded_" ++ sym ++ "_start\n" ++
    ".globl _with_embedded_" ++ sym ++ "_end\n" ++
    ".globl with_embedded_" ++ sym ++ "_end\n" ++
    ".p2align 4\n" ++
    "_with_embedded_" ++ sym ++ "_start:\n" ++
    "with_embedded_" ++ sym ++ "_start:\n" ++
    "    .incbin " ++ build_graph_asm_quote_path(input_path) ++ "\n" ++
    "_with_embedded_" ++ sym ++ "_end:\n" ++
    "with_embedded_" ++ sym ++ "_end:\n\n"

pub fn build_graph_embed_object_files(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        with_eprint("error: embed_object_files target '" ++ target.name ++ "' requires an output path")
        return 1
    if target.inputs.len() == 0:
        with_eprint("error: embed_object_files target '" ++ target.name ++ "' requires at least one input object")
        return 1
    if target.args.len() != target.inputs.len():
        with_eprint("error: embed_object_files target '" ++ target.name ++ "' requires one stable symbol name per input")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create embedded-object output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var asm_text = "// Auto-generated by with build embed_object_files - do not edit.\n\n"
    if build_graph_host_target_kind() == 3 or build_graph_host_target_kind() == 4:
        asm_text = asm_text ++ ".section __TEXT,__const\n.subsections_via_symbols\n\n"
    else:
        asm_text = asm_text ++ ".section .rodata\n\n"
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: embed_object_files target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
        let sym = target.args.get(ii as i64)
        if not build_graph_symbol_name_valid(sym):
            with_eprint("error: embed_object_files target '" ++ target.name ++ "' has invalid symbol name: " ++ sym)
            return 1
        asm_text = asm_text ++ build_graph_emit_embedded_blob(sym, input_path)
    if with_fs_write_file(output_path, asm_text) != 0:
        with_eprint("error: could not write embedded-object assembly for target '" ++ target.name ++ "': " ++ output_path)
        return 1
    0

pub fn build_graph_copy_manifest_files(root: str, target: BuildGraphTarget, operation_name: str) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires source and output directories")
        return 1
    if target.inputs.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires explicit relative input paths")
        return 1
    let source_dir = build_graph_resolve_project_path(root, target.entry)
    let output_dir = build_graph_resolve_project_path(root, target.output)
    for ii in 0..target.inputs.len() as i32:
        let rel = target.inputs.get(ii as i64)
        if not build_graph_manifest_relative_path_valid(rel):
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' has invalid relative input path: " ++ rel)
            return 1
        let source_path = resolve_join(source_dir, rel)
        let dest_path = resolve_join(output_dir, rel)
        if with_fs_file_exists(source_path) == 0:
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing input: " ++ source_path)
            return 1
        let dest_dir = build_graph_dirname(dest_path)
        if with_fs_mkdir_p(dest_dir) != 0:
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' could not create destination directory: " ++ dest_dir)
            return 1
        let contents = with_fs_read_file(source_path)
        if with_fs_write_file(dest_path, contents) != 0:
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' could not write destination: " ++ dest_path)
            return 1
    0

pub fn build_graph_run_corpus_test(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        with_eprint("error: run_corpus_test target '" ++ target.name ++ "' requires a runner")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: run_corpus_test target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    let output_dir = if target.output.len() > 0:
        build_graph_resolve_project_path(root, target.output)
    else:
        resolve_join(resolve_join(root, "out/corpus"), target.name)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create corpus output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    let stdout_path = resolve_join(output_dir, "stdout.txt")
    let stderr_path = resolve_join(output_dir, "stderr.txt")
    var argv = ""
    let runner_path = if target.entry.byte_at(0) == 47 or with_str_contains(target.entry, "/") != 0:
        build_graph_resolve_project_path(root, target.entry)
    else:
        target.entry
    argv = build_graph_argv_append(argv, runner_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let timeout_ms = 300000
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        with_eprint("error: run_corpus_test target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        with_eprint("error: run_corpus_test target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    0

pub fn build_graph_run_command(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        with_eprint("error: command target '" ++ target.name ++ "' requires an executable")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: command target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    if target.output.len() > 0:
        let output_path = build_graph_resolve_project_path(root, target.output)
        let output_dir = build_graph_dirname(output_path)
        if with_fs_mkdir_p(output_dir) != 0:
            with_eprint("error: command target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
            return 1
    let capture_dir = resolve_join(resolve_join(root, "out/command"), target.name)
    if with_fs_mkdir_p(capture_dir) != 0:
        with_eprint("error: could not create command output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let stdout_path = resolve_join(capture_dir, "stdout.txt")
    let stderr_path = resolve_join(capture_dir, "stderr.txt")
    var argv = ""
    let runner_path = if target.entry.byte_at(0) == 47 or with_str_contains(target.entry, "/") != 0:
        build_graph_resolve_project_path(root, target.entry)
    else:
        target.entry
    argv = build_graph_argv_append(argv, runner_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let timeout_ms = 300000
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        with_eprint("error: command target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        with_eprint("error: command target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    if target.output.len() > 0:
        let output_path = build_graph_resolve_project_path(root, target.output)
        if with_fs_file_exists(output_path) == 0:
            with_eprint("error: command target '" ++ target.name ++ "' did not produce declared output: " ++ output_path)
            return 1
    0

pub fn build_graph_copy_file_to_path(source_path: str, dest_path: str, mode: i32) -> i32:
    if with_fs_file_exists(source_path) == 0:
        with_eprint("error: missing file to copy: " ++ source_path)
        return 1
    let dest_dir = build_graph_dirname(dest_path)
    if with_fs_mkdir_p(dest_dir) != 0:
        with_eprint("error: could not create copy destination directory: " ++ dest_dir)
        return 1
    let contents = with_fs_read_file(source_path)
    if contents.len() == 0:
        with_eprint("error: could not read file to copy: " ++ source_path)
        return 1
    if with_fs_write_file(dest_path, contents) != 0:
        with_eprint("error: could not write copied file: " ++ dest_path)
        return 1
    if mode >= 0 and with_fs_chmod(dest_path, mode) != 0:
        with_eprint("error: could not chmod copied file: " ++ dest_path)
        return 1
    0

pub fn build_graph_expand_install_path(root: str, path: str) -> str:
    if with_str_starts_with(path, "$HOME/") != 0:
        let home = with_getenv_str("HOME")
        if home.len() > 0:
            return resolve_join(home, path.slice(6, path.len()))
    build_graph_resolve_project_path(root, path)

pub fn build_graph_parse_octal_mode(text: str) -> i32:
    if text.len() == 0:
        return -1
    var mode = 0
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 55:
            return -1
        mode = mode * 8 + (ch - 48)
    mode

pub fn build_graph_install_file(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        with_eprint("error: install target '" ++ target.name ++ "' requires source and destination paths")
        return 1
    if target.args.len() > 1:
        with_eprint("error: install target '" ++ target.name ++ "' accepts at most one mode argument")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let source_path = build_graph_resolve_project_path(root, target.entry)
    if with_fs_file_exists(source_path) == 0:
        with_eprint("error: install target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    let dest_path = build_graph_expand_install_path(root, target.output)
    if dest_path.len() == 0 or dest_path == target.output and with_str_starts_with(dest_path, "$HOME/") != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not resolve destination: " ++ target.output)
        return 1
    let dest_dir = build_graph_dirname(dest_path)
    if with_fs_mkdir_p(dest_dir) != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not create destination directory: " ++ dest_dir)
        return 1
    let contents = with_fs_read_file(source_path)
    if with_fs_write_file(dest_path, contents) != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not write destination: " ++ dest_path)
        return 1
    let mode = if target.args.len() == 0: 0o644 else: build_graph_parse_octal_mode(target.args.get(0))
    if mode < 0:
        with_eprint("error: install target '" ++ target.name ++ "' has invalid octal mode: " ++ target.args.get(0))
        return 1
    if with_fs_chmod(dest_path, mode) != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not chmod destination: " ++ dest_path)
        return 1
    0
