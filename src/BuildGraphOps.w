// BuildGraphOps -- generic executable build graph node operations.

use Resolve
use BuildGraphKinds
use BuildGraphModel
use BuildGraphSupport
use BuildGraphTools
use BuildGraphRuntime

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
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires two input paths")
        return 1
    if build_graph_rt_file_exists(left_path) == 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing left input: " ++ left_path)
        return 1
    if build_graph_rt_file_exists(right_path) == 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing right input: " ++ right_path)
        return 1
    let left = build_graph_rt_read_file(left_path)
    let right = build_graph_rt_read_file(right_path)
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
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' failed: " ++ left_path ++ " and " ++ right_path ++ f" differ at byte {diff_at}")
        return 1
    0

pub fn build_graph_run_clean(root: str, target: BuildGraphTarget) -> i32:
    var removed = 0
    for ai in 0..target.args.len() as i32:
        let rel = target.args.get(ai as i64)
        if rel.len() == 0 or rel.byte_at(0) == 47 or rel.contains(".."):
            build_graph_rt_eprint("error: clean target '" ++ target.name ++ "' has unsafe path: " ++ rel)
            return 1
        let path = build_graph_resolve_project_path(root, rel)
        if build_graph_rt_is_dir(path) != 0:
            let rc = build_graph_rt_remove_tree(path)
            if rc != 0:
                build_graph_rt_eprint("error: clean target '" ++ target.name ++ "' could not remove directory tree: " ++ path)
                return 1
            removed = removed + 1
        else if build_graph_rt_file_exists(path) != 0:
            let rc = build_graph_rt_remove_file(path)
            if rc != 0:
                build_graph_rt_eprint("error: clean target '" ++ target.name ++ "' could not remove file: " ++ path)
                return 1
            removed = removed + 1
    build_graph_rt_write(f"cleaned {removed} build artifact paths\n")
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
        build_graph_rt_eprint("error: generate_response_file target '" ++ target.name ++ "' requires an output path")
        return 1
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: could not create response file directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var text = ""
    for ai in 0..target.args.len() as i32:
        let arg = target.args.get(ai as i64)
        if not build_graph_response_arg_valid(arg):
            build_graph_rt_eprint("error: generate_response_file target '" ++ target.name ++ "' contains an argument with a newline")
            return 1
        text = text ++ build_graph_quote_response_arg(arg) ++ "\n"
    if build_graph_rt_write_file(output_path, text) != 0:
        build_graph_rt_eprint("error: could not write response file for target '" ++ target.name ++ "': " ++ output_path)
        return 1
    0

fn build_graph_trim_space(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn build_graph_split_whitespace(text: str) -> Vec[str]:
    let parts: Vec[str] = Vec.new()
    var start = -1
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let is_space = ch == 9 or ch == 10 or ch == 13 or ch == 32
        if is_space:
            if start >= 0:
                parts.push(text.slice(start as i64, i as i64))
                start = -1
        else if start < 0:
            start = i
    if start >= 0:
        parts.push(text.slice(start as i64, text.len()))
    parts

fn build_graph_capture_stdout(root: str, target_name: str, label: str, argv: str, timeout_ms: i32) -> str:
    let capture_dir = resolve_join(resolve_join(root, "out/command"), target_name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        return ""
    let stamp = f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let stdout_path = resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stdout")
    let stderr_path = resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stderr")
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc != 0:
        let stderr = build_graph_rt_read_file(stderr_path)
        if stderr.len() > 0:
            build_graph_rt_eprint(stderr)
        let _remove_stdout_err = build_graph_rt_remove_file(stdout_path)
        let _remove_stderr_err = build_graph_rt_remove_file(stderr_path)
        return ""
    let stdout = build_graph_trim_space(build_graph_rt_read_file(stdout_path))
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    stdout

fn build_graph_libclang_path() -> str:
    let explicit = build_graph_rt_getenv("WITH_LIBCLANG")
    if explicit.len() > 0:
        return explicit
    let legacy = build_graph_rt_getenv("LIBCLANG_FILE")
    if legacy.len() > 0:
        return legacy
    let lib_dir = build_graph_llvm_prefix() ++ "/lib"
    let dylib = lib_dir ++ "/libclang.dylib"
    if build_graph_rt_file_exists(dylib) != 0:
        return dylib
    let so = lib_dir ++ "/libclang.so"
    if build_graph_rt_file_exists(so) != 0:
        return so
    let dll = lib_dir ++ "/libclang.dll"
    if build_graph_rt_file_exists(dll) != 0:
        return dll
    ""

fn build_graph_host_sdk_path(root: str, target_name: str) -> str:
    let sdkroot = build_graph_rt_getenv("SDKROOT")
    if sdkroot.len() > 0:
        return sdkroot
    let host = build_graph_host_target_kind()
    if host != 3 and host != 4:
        return ""
    let xcrun = "/usr/bin/xcrun"
    if build_graph_rt_file_exists(xcrun) == 0:
        return ""
    var argv = ""
    argv = build_graph_argv_append(argv, xcrun)
    argv = build_graph_argv_append(argv, "--show-sdk-path")
    build_graph_capture_stdout(root, target_name, "xcrun-sdk-path", argv, 30000)

pub fn build_graph_generate_llvm_link_metadata(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' requires a stamp output path")
        return 1
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
        return 1
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if build_graph_rt_file_exists(input_path) == 0:
            build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
    let llvm_config = build_graph_llvm_config_tool().executable
    if build_graph_rt_file_exists(llvm_config) == 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' missing llvm-config: " ++ llvm_config)
        return 1
    let llvm_clang = build_graph_llvm_clang_tool().executable
    if build_graph_rt_file_exists(llvm_clang) == 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' missing LLVM clang: " ++ llvm_clang)
        return 1
    let libclang = build_graph_libclang_path()
    if libclang.len() == 0 or build_graph_rt_file_exists(libclang) == 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' missing libclang under " ++ build_graph_llvm_prefix() ++ "/lib")
        return 1
    var argv = ""
    argv = build_graph_argv_append(argv, llvm_config)
    argv = build_graph_argv_append(argv, "--link-static")
    argv = build_graph_argv_append(argv, "--libfiles")
    let components: [58]str = [
        "core", "support", "analysis", "passes",
        "aarch64codegen", "aarch64asmparser", "aarch64desc", "aarch64info", "aarch64utils",
        "codegen", "mc", "mcparser", "target", "targetparser", "bitwriter",
        "objcarcopts", "linker", "selectiondag", "asmprinter", "globalisel",
        "scalaropts", "instcombine", "ipo", "transformutils", "vectorize",
        "instrumentation", "cfguard", "aggressiveinstcombine",
        "irprinter", "hipstdpar", "coroutines", "sandboxir",
        "frontendopenmp", "frontenddirective", "frontendatomic", "frontendoffloading",
        "objectyaml", "cgdata", "codegentypes", "bitreader", "irreader", "asmparser",
        "profiledata", "symbolize", "debuginfobtf", "debuginfopdb", "debuginfomsf",
        "debuginfocodeview", "debuginfogsym", "debuginfodwarf", "debuginfodwarflowlevel",
        "object", "textapi", "remarks", "bitstreamreader", "binaryformat",
        "frontendhlsl", "demangle",
    ]
    for ci in 0..58:
        argv = build_graph_argv_append(argv, components[ci])
    let libs_text = build_graph_capture_stdout(root, target.name, "llvm-config-libfiles", argv, 120000)
    if libs_text.len() == 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' could not query llvm-config")
        return 1
    var rsp = ""
    let libs = build_graph_split_whitespace(libs_text)
    for li in 0..libs.len() as i32:
        rsp = rsp ++ libs.get(li as i64) ++ "\n"
    let sdk_path = build_graph_host_sdk_path(root, target.name)
    if sdk_path.len() > 0:
        rsp = rsp ++ "-isysroot\n" ++ sdk_path ++ "\n"
    rsp = rsp ++ "-lm\n"
    rsp = rsp ++ "-lz\n"
    let zstd_archive = "/opt/homebrew/lib/libzstd.a"
    if build_graph_rt_file_exists(zstd_archive) != 0:
        rsp = rsp ++ zstd_archive ++ "\n"
    else:
        rsp = rsp ++ "-lzstd\n"
    rsp = rsp ++ "-lxml2\n"
    rsp = rsp ++ "-lc++\n"
    rsp = rsp ++ libclang ++ "\n"
    rsp = rsp ++ "-Wl,-rpath," ++ build_graph_dirname(libclang) ++ "/\n"
    let rsp_path = resolve_join(output_dir, "llvm_link.rsp")
    let cc_path = resolve_join(output_dir, "llvm_cc")
    if build_graph_rt_write_file(rsp_path, rsp) != 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' could not write: " ++ rsp_path)
        return 1
    if build_graph_rt_write_file(cc_path, llvm_clang ++ "\n") != 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' could not write: " ++ cc_path)
        return 1
    if build_graph_rt_write_file(output_path, "ok\n") != 0:
        build_graph_rt_eprint("error: generate_llvm_link_metadata target '" ++ target.name ++ "' could not write stamp: " ++ output_path)
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
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires source and output paths")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let source_path = build_graph_resolve_project_path(root, target.entry)
    let output_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_file_exists(source_path) == 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: could not create object output directory for target '" ++ target.name ++ "': " ++ output_dir)
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
        build_graph_rt_eprint("error: create_static_archive target '" ++ target.name ++ "' requires an output path")
        return 1
    if target.inputs.len() == 0:
        build_graph_rt_eprint("error: create_static_archive target '" ++ target.name ++ "' requires at least one input object")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: could not create archive output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    let resolved_inputs: Vec[str] = Vec.new()
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if build_graph_rt_file_exists(input_path) == 0:
            build_graph_rt_eprint("error: create_static_archive target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
        let member = build_graph_path_basename(input_path)
        if build_graph_archive_member_seen(resolved_inputs, resolved_inputs.len() as i32, member):
            build_graph_rt_eprint("error: create_static_archive target '" ++ target.name ++ "' has duplicate archive member name: " ++ member)
            return 1
        resolved_inputs.push(input_path)
    let _remove_old_archive = build_graph_rt_remove_file(output_path)
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
        build_graph_rt_eprint("error: embed_object_files target '" ++ target.name ++ "' requires an output path")
        return 1
    if target.inputs.len() == 0:
        build_graph_rt_eprint("error: embed_object_files target '" ++ target.name ++ "' requires at least one input object")
        return 1
    if target.args.len() != target.inputs.len():
        build_graph_rt_eprint("error: embed_object_files target '" ++ target.name ++ "' requires one stable symbol name per input")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: could not create embedded-object output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var asm_text = "// Auto-generated by with build embed_object_files - do not edit.\n\n"
    if build_graph_host_target_kind() == 3 or build_graph_host_target_kind() == 4:
        asm_text = asm_text ++ ".section __TEXT,__const\n.subsections_via_symbols\n\n"
    else:
        asm_text = asm_text ++ ".section .rodata\n\n"
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if build_graph_rt_file_exists(input_path) == 0:
            build_graph_rt_eprint("error: embed_object_files target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
        let sym = target.args.get(ii as i64)
        if not build_graph_symbol_name_valid(sym):
            build_graph_rt_eprint("error: embed_object_files target '" ++ target.name ++ "' has invalid symbol name: " ++ sym)
            return 1
        asm_text = asm_text ++ build_graph_emit_embedded_blob(sym, input_path)
    if build_graph_rt_write_file(output_path, asm_text) != 0:
        build_graph_rt_eprint("error: could not write embedded-object assembly for target '" ++ target.name ++ "': " ++ output_path)
        return 1
    0

pub fn build_graph_copy_manifest_files(root: str, target: BuildGraphTarget, operation_name: str) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires source and output directories")
        return 1
    if target.inputs.len() == 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires explicit relative input paths")
        return 1
    let source_dir = build_graph_resolve_project_path(root, target.entry)
    let output_dir = build_graph_resolve_project_path(root, target.output)
    for ii in 0..target.inputs.len() as i32:
        let rel = target.inputs.get(ii as i64)
        if not build_graph_manifest_relative_path_valid(rel):
            build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' has invalid relative input path: " ++ rel)
            return 1
        let source_path = resolve_join(source_dir, rel)
        let dest_path = resolve_join(output_dir, rel)
        if build_graph_rt_file_exists(source_path) == 0:
            build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing input: " ++ source_path)
            return 1
        let dest_dir = build_graph_dirname(dest_path)
        if build_graph_rt_mkdir_p(dest_dir) != 0:
            build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' could not create destination directory: " ++ dest_dir)
            return 1
        let contents = build_graph_rt_read_file(source_path)
        if build_graph_rt_write_file(dest_path, contents) != 0:
            build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' could not write destination: " ++ dest_path)
            return 1
    0

pub fn build_graph_run_corpus_test(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: run_corpus_test target '" ++ target.name ++ "' requires a runner")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if build_graph_rt_file_exists(input_path) == 0:
            build_graph_rt_eprint("error: run_corpus_test target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    let output_dir = if target.output.len() > 0:
        build_graph_resolve_project_path(root, target.output)
    else:
        resolve_join(resolve_join(root, "out/corpus"), target.name)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: could not create corpus output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    let stdout_path = resolve_join(output_dir, "stdout.txt")
    let stderr_path = resolve_join(output_dir, "stderr.txt")
    var argv = ""
    let runner_path = if target.entry.byte_at(0) == 47 or target.entry.contains("/"):
        build_graph_resolve_project_path(root, target.entry)
    else:
        target.entry
    argv = build_graph_argv_append(argv, runner_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let timeout_ms = 300000
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        build_graph_rt_eprint("error: run_corpus_test target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: run_corpus_test target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    0

pub fn build_graph_run_command(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: command target '" ++ target.name ++ "' requires an executable")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if build_graph_rt_file_exists(input_path) == 0:
            build_graph_rt_eprint("error: command target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    if target.output.len() > 0:
        let output_path = build_graph_resolve_project_path(root, target.output)
        let output_dir = build_graph_dirname(output_path)
        if build_graph_rt_mkdir_p(output_dir) != 0:
            build_graph_rt_eprint("error: command target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
            return 1
    let capture_dir = resolve_join(resolve_join(root, "out/command"), target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: could not create command output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let stdout_path = resolve_join(capture_dir, "stdout.txt")
    let stderr_path = resolve_join(capture_dir, "stderr.txt")
    var argv = ""
    let runner_path = if target.entry.byte_at(0) == 47 or target.entry.contains("/"):
        build_graph_resolve_project_path(root, target.entry)
    else:
        target.entry
    argv = build_graph_argv_append(argv, runner_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let timeout_ms = 300000
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        build_graph_rt_eprint("error: command target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: command target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    if target.output.len() > 0:
        let output_path = build_graph_resolve_project_path(root, target.output)
        if build_graph_rt_file_exists(output_path) == 0:
            build_graph_rt_eprint("error: command target '" ++ target.name ++ "' did not produce declared output: " ++ output_path)
            return 1
    0

pub fn build_graph_copy_file_to_path(source_path: str, dest_path: str, mode: i32) -> i32:
    if build_graph_rt_file_exists(source_path) == 0:
        build_graph_rt_eprint("error: missing file to copy: " ++ source_path)
        return 1
    let dest_dir = build_graph_dirname(dest_path)
    if build_graph_rt_mkdir_p(dest_dir) != 0:
        build_graph_rt_eprint("error: could not create copy destination directory: " ++ dest_dir)
        return 1
    let contents = build_graph_rt_read_file(source_path)
    if contents.len() == 0:
        build_graph_rt_eprint("error: could not read file to copy: " ++ source_path)
        return 1
    if build_graph_rt_write_file(dest_path, contents) != 0:
        build_graph_rt_eprint("error: could not write copied file: " ++ dest_path)
        return 1
    if mode >= 0 and build_graph_rt_chmod(dest_path, mode) != 0:
        build_graph_rt_eprint("error: could not chmod copied file: " ++ dest_path)
        return 1
    0

pub fn build_graph_expand_install_path(root: str, path: str) -> str:
    if path.starts_with("$HOME/"):
        let home = build_graph_rt_getenv("HOME")
        if home.len() > 0:
            return resolve_join(home, path.slice(6, path.len()))
    if path.starts_with("$INSTALL_BINDIR/"):
        let install_bindir = build_graph_install_bindir()
        if install_bindir.len() > 0:
            return build_graph_resolve_project_path(root, resolve_join(install_bindir, path.slice(16, path.len())))
    if path.starts_with("$INSTALL_LIBDIR/"):
        let install_libdir = build_graph_install_libdir()
        if install_libdir.len() > 0:
            return build_graph_resolve_project_path(root, resolve_join(install_libdir, path.slice(16, path.len())))
    build_graph_resolve_project_path(root, path)

fn build_graph_json_line_value(line: str, key: str) -> str:
    let marker = "\"" ++ key ++ "\":"
    var pos = -1
    var i = 0
    while i <= line.len() as i32 - marker.len() as i32:
        if line.slice(i as i64, (i + marker.len() as i32) as i64) == marker:
            pos = i + marker.len() as i32
            break
        i = i + 1
    if pos < 0:
        return ""
    while pos < line.len() as i32:
        let ch = line.byte_at(pos as i64)
        if ch != 32 and ch != 9:
            break
        pos = pos + 1
    if pos >= line.len() as i32 or line.byte_at(pos as i64) != 34:
        return ""
    let start = pos + 1
    var end = start
    var escaped = false
    while end < line.len() as i32:
        let ch = line.byte_at(end as i64)
        if escaped:
            escaped = false
        else if ch == 92:
            escaped = true
        else if ch == 34:
            return line.slice(start as i64, end as i64)
        end = end + 1
    ""

fn build_graph_seed_release_from_api(root: str, target_name: str, repo: str, asset_name: str) -> str:
    let tmp_dir = resolve_join(root, "out/tmp")
    if build_graph_rt_mkdir_p(tmp_dir) != 0:
        return ""
    let stamp = f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let body_path = resolve_join(tmp_dir, "seed-releases." ++ stamp ++ ".json")
    let stdout_path = resolve_join(tmp_dir, "seed-releases." ++ stamp ++ ".stdout")
    let err_path = body_path ++ ".stderr"
    var argv = ""
    argv = build_graph_argv_append(argv, build_graph_curl_tool().executable)
    argv = build_graph_argv_append(argv, "-L")
    argv = build_graph_argv_append(argv, "--fail")
    argv = build_graph_argv_append(argv, "--show-error")
    argv = build_graph_argv_append(argv, "--output")
    argv = build_graph_argv_append(argv, body_path)
    argv = build_graph_argv_append(argv, "https://api.github.com/repos/" ++ repo ++ "/releases?per_page=10")
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, err_path, 120000)
    if rc != 0:
        build_graph_rt_eprint("error: seed_download target '" ++ target_name ++ f"' could not query releases for {repo}; curl exit code {rc}; stderr=" ++ err_path)
        return ""
    let body = build_graph_rt_read_file(body_path)
    let _remove_body = build_graph_rt_remove_file(body_path)
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_err = build_graph_rt_remove_file(err_path)
    let lines = build_graph_split_nonempty_lines(body)
    var current_tag = ""
    for li in 0..lines.len() as i32:
        let line = lines.get(li as i64)
        let tag = build_graph_json_line_value(line, "tag_name")
        if tag.len() > 0:
            current_tag = tag
        let name = build_graph_json_line_value(line, "name")
        if current_tag.len() > 0 and name == asset_name:
            return current_tag
    ""

pub fn build_graph_run_seed_download(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        build_graph_rt_eprint("error: seed_download target '" ++ target.name ++ "' requires repo entry and output path")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let asset_name = if target.args.len() > 0: target.args.get(0) else: "main"
    let output_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_file_exists(output_path) != 0:
        build_graph_rt_write("seed binary already exists: " ++ target.output ++ "\n")
        build_graph_rt_write("remove it first if you want to re-download\n")
        return 0
    var tag = build_graph_rt_getenv("SEED_VERSION")
    if tag.len() == 0:
        tag = build_graph_seed_release_from_api(root, target.name, target.entry, asset_name)
        if tag.len() == 0:
            build_graph_rt_eprint("error: seed_download target '" ++ target.name ++ "' could not find a release containing asset '" ++ asset_name ++ "'")
            build_graph_rt_eprint("set SEED_VERSION to a release tag to download a specific seed")
            return 1
        build_graph_rt_write("latest seed release: " ++ tag ++ "\n")
    let url = "https://github.com/" ++ target.entry ++ "/releases/download/" ++ tag ++ "/" ++ asset_name
    if build_graph_rt_mkdir_p(build_graph_dirname(output_path)) != 0:
        build_graph_rt_eprint("error: seed_download target '" ++ target.name ++ "' could not create output directory: " ++ build_graph_dirname(output_path))
        return 1
    let tmp_path = output_path ++ ".tmp." ++ f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let _remove_tmp = build_graph_rt_remove_file(tmp_path)
    build_graph_rt_write("downloading seed from: " ++ url ++ "\n")
    var curl_argv = ""
    curl_argv = build_graph_argv_append(curl_argv, build_graph_curl_tool().executable)
    curl_argv = build_graph_argv_append(curl_argv, "-L")
    curl_argv = build_graph_argv_append(curl_argv, "--fail")
    curl_argv = build_graph_argv_append(curl_argv, "--show-error")
    curl_argv = build_graph_argv_append(curl_argv, "--output")
    curl_argv = build_graph_argv_append(curl_argv, tmp_path)
    curl_argv = build_graph_argv_append(curl_argv, url)
    let curl_rc = build_graph_rt_exec_argv(curl_argv)
    if curl_rc != 0:
        build_graph_rt_eprint("error: seed_download target '" ++ target.name ++ f"' curl failed with exit code {curl_rc}")
        return if curl_rc == 0: 1 else: curl_rc
    if build_graph_rt_rename_file(tmp_path, output_path) != 0:
        build_graph_rt_eprint("error: seed_download target '" ++ target.name ++ "' could not publish seed: " ++ output_path)
        return 1
    if build_graph_rt_chmod(output_path, 0o755) != 0:
        build_graph_rt_eprint("error: seed_download target '" ++ target.name ++ "' could not chmod seed: " ++ output_path)
        return 1
    build_graph_rt_write("seed installed: " ++ target.output ++ "\n")
    0

fn build_graph_env_or_default(name: str, default_value: str) -> str:
    let value = build_graph_rt_getenv(name)
    if value.len() > 0:
        return value
    default_value

fn build_graph_install_bindir() -> str:
    let prefix = build_graph_env_or_default("PREFIX", "/usr/local")
    let bindir = build_graph_env_or_default("BINDIR", resolve_join(prefix, "bin"))
    build_graph_rt_getenv("DESTDIR") ++ bindir

fn build_graph_install_libdir() -> str:
    resolve_join(build_graph_install_bindir(), "runtime")

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
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' requires source and destination paths")
        return 1
    if target.args.len() > 1:
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' accepts at most one mode argument")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let source_path = build_graph_resolve_project_path(root, target.entry)
    if build_graph_rt_file_exists(source_path) == 0:
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    let dest_path = build_graph_expand_install_path(root, target.output)
    if dest_path.len() == 0 or dest_path == target.output and dest_path.starts_with("$HOME/"):
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' could not resolve destination: " ++ target.output)
        return 1
    let dest_dir = build_graph_dirname(dest_path)
    if build_graph_rt_mkdir_p(dest_dir) != 0:
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' could not create destination directory: " ++ dest_dir)
        return 1
    let contents = build_graph_rt_read_file(source_path)
    if build_graph_rt_write_file(dest_path, contents) != 0:
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' could not write destination: " ++ dest_path)
        return 1
    let mode = if target.args.len() == 0: 0o644 else: build_graph_parse_octal_mode(target.args.get(0))
    if mode < 0:
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' has invalid octal mode: " ++ target.args.get(0))
        return 1
    if build_graph_rt_chmod(dest_path, mode) != 0:
        build_graph_rt_eprint("error: install target '" ++ target.name ++ "' could not chmod destination: " ++ dest_path)
        return 1
    0
