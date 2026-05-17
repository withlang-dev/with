// BuildGraphEmitC -- emitted-C parity checks for the repository compiler.

use Resolve
use BuildGraphModel
use BuildGraphSupport
use BuildGraphTools
use BuildGraphRuntime
use BuildGraphTests

type EmitCParam {
    name: str,
    c_type: str,
}

type EmitCFunction {
    symbol: str,
    return_type: str,
    params: Vec[EmitCParam],
    ok: i32,
}

fn emitc_index_of(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if text.len() < needle.len():
        return -1
    var i = 0
    while i <= text.len() as i32 - needle.len() as i32:
        var j = 0
        var matched = true
        while j < needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
            j = j + 1
        if matched:
            return i
        i = i + 1
    -1

fn emitc_trim(text: str) -> str:
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

fn emitc_split_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    var i = 0
    while i <= text.len() as i32:
        let at_end = i == text.len() as i32
        if at_end or text.byte_at(i as i64) == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() - 1) == 13:
                line = line.slice(0, line.len() - 1)
            lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn emitc_c_export_symbol(line: str) -> str:
    let prefix = "@[c_export(\""
    let start = emitc_index_of(line, prefix)
    if start < 0:
        return ""
    let symbol_start = start + prefix.len() as i32
    var i = symbol_start
    while i < line.len() as i32:
        if line.byte_at(i as i64) == 34:
            return line.slice(symbol_start as i64, i as i64)
        i = i + 1
    ""

fn emitc_find_matching_paren(text: str, open_at: i32) -> i32:
    var depth = 0
    var i = open_at
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 40:
            depth = depth + 1
        else if ch == 41:
            depth = depth - 1
            if depth == 0:
                return i
        i = i + 1
    -1

fn emitc_c_type(with_type: str) -> str:
    if with_type == "i32": return "int32_t"
    if with_type == "i64": return "int64_t"
    if with_type == "u32": return "uint32_t"
    if with_type == "u64": return "uint64_t"
    if with_type == "f64": return "double"
    if with_type == "str": return "with_str"
    if with_type == "WithVec": return "with_vec"
    if with_type == "*const WithVec": return "const with_vec *"
    if with_type == "*mut WithVec": return "with_vec *"
    if with_type == "*const i8": return "const int8_t *"
    if with_type == "*const i32": return "const int32_t *"
    if with_type == "*mut i32": return "int32_t *"
    if with_type == "*mut i64": return "int64_t *"
    if with_type == "*mut f64": return "double *"
    if with_type == "void": return "void"
    ""

fn emitc_stub_return(c_type: str) -> str:
    if c_type == "void":
        return ""
    if c_type == "with_str":
        return "    return (with_str){0};\n"
    if c_type == "with_vec":
        return "    return (with_vec){0};\n"
    "    return 0;\n"

fn emitc_parse_param(param_text: str) -> EmitCParam:
    let trimmed = emitc_trim(param_text)
    var colon = -1
    for i in 0..trimmed.len() as i32:
        if trimmed.byte_at(i as i64) == 58:
            colon = i
            break
    if colon < 0:
        return EmitCParam { name: "", c_type: "" }
    let name = emitc_trim(trimmed.slice(0, colon as i64))
    let with_type = emitc_trim(trimmed.slice((colon + 1) as i64, trimmed.len()))
    let c_type = emitc_c_type(with_type)
    EmitCParam { name, c_type }

fn emitc_parse_params(text: str) -> Vec[EmitCParam]:
    let params: Vec[EmitCParam] = Vec.new()
    var start = 0
    var i = 0
    while i <= text.len() as i32:
        let at_end = i == text.len() as i32
        if at_end or text.byte_at(i as i64) == 44:
            let piece = emitc_trim(text.slice(start as i64, i as i64))
            if piece.len() > 0:
                params.push(emitc_parse_param(piece))
            start = i + 1
        i = i + 1
    params

fn emitc_parse_export_function(symbol: str, line: str) -> EmitCFunction:
    let params: Vec[EmitCParam] = Vec.new()
    let fn_at = emitc_index_of(line, "fn ")
    if fn_at < 0:
        return EmitCFunction { symbol, return_type: "", params, ok: 0 }
    var open_at = -1
    var i = fn_at
    while i < line.len() as i32:
        if line.byte_at(i as i64) == 40:
            open_at = i
            break
        i = i + 1
    if open_at < 0:
        return EmitCFunction { symbol, return_type: "", params, ok: 0 }
    let close_at = emitc_find_matching_paren(line, open_at)
    if close_at < 0:
        return EmitCFunction { symbol, return_type: "", params, ok: 0 }
    let parsed_params = emitc_parse_params(line.slice((open_at + 1) as i64, close_at as i64))
    for pi in 0..parsed_params.len() as i32:
        let param = parsed_params.get(pi as i64)
        if param.name.len() == 0 or param.c_type.len() == 0:
            return EmitCFunction { symbol, return_type: "", params: parsed_params, ok: 0 }
    var return_type = "void"
    let rest = line.slice((close_at + 1) as i64, line.len())
    let arrow = emitc_index_of(rest, "->")
    if arrow >= 0:
        let after_arrow = rest.slice((arrow + 2) as i64, rest.len())
        var colon = -1
        for ci in 0..after_arrow.len() as i32:
            if after_arrow.byte_at(ci as i64) == 58:
                colon = ci
                break
        if colon < 0:
            return EmitCFunction { symbol, return_type: "", params: parsed_params, ok: 0 }
        return_type = emitc_c_type(emitc_trim(after_arrow.slice(0, colon as i64)))
        if return_type.len() == 0:
            return EmitCFunction { symbol, return_type: "", params: parsed_params, ok: 0 }
    EmitCFunction { symbol, return_type, params: parsed_params, ok: 1 }

fn emitc_collect_exports_from_text(text: str, source_path: str, target_name: str) -> Vec[EmitCFunction]:
    let exports: Vec[EmitCFunction] = Vec.new()
    let lines = emitc_split_lines(text)
    var pending_symbol = ""
    for li in 0..lines.len() as i32:
        let line = emitc_trim(lines.get(li as i64))
        let symbol = emitc_c_export_symbol(line)
        if symbol.len() > 0:
            pending_symbol = symbol
            continue
        if pending_symbol.len() > 0:
            if line.starts_with("pub fn ") or line.starts_with("pub unsafe fn "):
                let fn_sig = emitc_parse_export_function(pending_symbol, line)
                if fn_sig.ok == 0:
                    build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' could not parse c_export signature for " ++ pending_symbol ++ " in " ++ source_path)
                    return Vec.new()
                exports.push(fn_sig)
                pending_symbol = ""
                continue
            if line.len() > 0 and not line.starts_with("//"):
                build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' c_export is not followed by a function in " ++ source_path ++ ": " ++ pending_symbol)
                return Vec.new()
    if pending_symbol.len() > 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' unterminated c_export in " ++ source_path ++ ": " ++ pending_symbol)
        return Vec.new()
    exports

fn emitc_collect_bridge_exports(root: str, target_name: str) -> Vec[EmitCFunction]:
    let all: Vec[EmitCFunction] = Vec.new()
    let sources: [3]str = ["rt/llvm_bridge.w", "rt/clang_bridge.w", "rt/regex_runtime.w"]
    for si in 0..3:
        let path = build_graph_resolve_project_path(root, sources[si])
        let text = build_graph_rt_read_file(path)
        if text.len() == 0:
            build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' could not read bridge source: " ++ path)
            return Vec.new()
        let exports = emitc_collect_exports_from_text(text, path, target_name)
        if exports.len() == 0:
            return Vec.new()
        for ei in 0..exports.len() as i32:
            all.push(exports.get(ei as i64))
    all

fn emitc_function_proto(fn_sig: EmitCFunction) -> str:
    var out = fn_sig.return_type ++ " " ++ fn_sig.symbol ++ "("
    if fn_sig.params.len() == 0:
        out = out ++ "void"
    else:
        for pi in 0..fn_sig.params.len() as i32:
            if pi > 0:
                out = out ++ ", "
            let param = fn_sig.params.get(pi as i64)
            out = out ++ param.c_type ++ " " ++ param.name
    out ++ ")"

fn emitc_generate_stub_files(root: str, target_name: str) -> i32:
    let exports = emitc_collect_bridge_exports(root, target_name)
    if exports.len() == 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' found no bridge exports")
        return 1
    let out_gen = build_graph_resolve_project_path(root, "out/gen")
    if build_graph_rt_mkdir_p(out_gen) != 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' could not create out/gen")
        return 1
    var decls = "// Auto-generated by with build emit-c.\n"
    decls = decls ++ "#ifndef WITH_EMIT_C_BRIDGE_DECLS_H\n"
    decls = decls ++ "#define WITH_EMIT_C_BRIDGE_DECLS_H\n\n"
    decls = decls ++ "#include \"with_runtime.h\"\n\n"
    var stubs = "// Auto-generated by with build emit-c.\n"
    stubs = stubs ++ "#include \"wl_decls.h\"\n\n"
    for ei in 0..exports.len() as i32:
        let fn_sig = exports.get(ei as i64)
        let proto = emitc_function_proto(fn_sig)
        decls = decls ++ proto ++ ";\n"
        stubs = stubs ++ proto ++ " {\n"
        for pi in 0..fn_sig.params.len() as i32:
            let param = fn_sig.params.get(pi as i64)
            stubs = stubs ++ "    (void)" ++ param.name ++ ";\n"
        stubs = stubs ++ emitc_stub_return(fn_sig.return_type)
        stubs = stubs ++ "}\n\n"
    decls = decls ++ "\n#endif\n"
    let decls_path = resolve_join(out_gen, "wl_decls.h")
    let stubs_path = resolve_join(out_gen, "wl_stubs.c")
    if build_graph_rt_write_file(decls_path, decls) != 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' could not write " ++ decls_path)
        return 1
    if build_graph_rt_write_file(stubs_path, stubs) != 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target_name ++ "' could not write " ++ stubs_path)
        return 1
    0

fn emitc_run_capture(root: str, target_name: str, label: str, argv: str, timeout_ms: i32) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/command"), target_name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: emit-c target '" ++ target_name ++ "' could not create capture directory: " ++ capture_dir)
        return 1
    let stdout_path = resolve_join(capture_dir, label ++ ".stdout")
    let stderr_path = resolve_join(capture_dir, label ++ ".stderr")
    let old_out_dir = build_graph_rt_getenv("WITH_OUT_DIR")
    let _set_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", resolve_join(root, "out"))
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    let _restore_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", old_out_dir)
    if rc == 0:
        let _remove_stdout = build_graph_rt_remove_file(stdout_path)
        let _remove_stderr = build_graph_rt_remove_file(stderr_path)
        return 0
    let stderr = build_graph_rt_read_file(stderr_path)
    if stderr.len() > 0:
        build_graph_rt_eprint(stderr)
    build_graph_rt_eprint("error: emit-c target '" ++ target_name ++ "' step '" ++ label ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if rc == 0:
        return 1
    rc

fn emitc_compile_runtime_args(root: str, argv: str) -> str:
    var out = argv
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/rt_core.o"))
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/rt_darwin_aarch64.o"))
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/compat_runtime.o"))
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/panic_runtime.o"))
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/regex_runtime.o"))
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/fiber_stubs.o"))
    out = build_graph_argv_append(out, build_graph_resolve_project_path(root, "out/lib/cimport_stubs.o"))
    out

fn emitc_build_compiler_c(root: str, target: BuildGraphTarget, compiler_path: str, main_c: str) -> i32:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "build")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/gen/main.w"))
    argv = build_graph_argv_append(argv, "--emit-c")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, main_c)
    emitc_run_capture(root, target.name, "emit-compiler-c", argv, 600000)

fn emitc_compile_c_compiler(root: str, target: BuildGraphTarget, main_c: str, output_path: str) -> i32:
    let zig = build_graph_zig_tool().executable
    var argv = ""
    argv = build_graph_argv_append(argv, zig)
    argv = build_graph_argv_append(argv, "cc")
    argv = build_graph_argv_append(argv, "-O2")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_path)
    argv = build_graph_argv_append(argv, main_c)
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/gen/wl_stubs.c"))
    argv = emitc_compile_runtime_args(root, argv)
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/lib/embedded_objects.o"))
    argv = build_graph_argv_append(argv, "-I")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "runtime"))
    argv = build_graph_argv_append(argv, "-include")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/gen/wl_decls.h"))
    argv = build_graph_argv_append(argv, "-lc")
    emitc_run_capture(root, target.name, "compile-with-from-c", argv, 600000)

fn emitc_compile_c_compiler_with_bridges(root: str, target: BuildGraphTarget, main_c: str, output_path: str) -> i32:
    let cc_path = emitc_trim(build_graph_rt_read_file(build_graph_resolve_project_path(root, "out/lib/llvm_cc")))
    if cc_path.len() == 0:
        build_graph_rt_eprint("error: emit-c roundtrip target '" ++ target.name ++ "' missing LLVM compiler metadata: out/lib/llvm_cc")
        return 1
    var argv = ""
    argv = build_graph_argv_append(argv, cc_path)
    argv = build_graph_argv_append(argv, "-O2")
    argv = build_graph_argv_append(argv, "-fuse-ld=lld")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_path)
    argv = build_graph_argv_append(argv, main_c)
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/lib/llvm_bridge.o"))
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/lib/clang_bridge.o"))
    argv = emitc_compile_runtime_args(root, argv)
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/lib/embedded_objects.o"))
    argv = build_graph_argv_append(argv, "-I")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "runtime"))
    argv = build_graph_argv_append(argv, "-include")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/gen/wl_decls.h"))
    argv = build_graph_argv_append(argv, "@" ++ build_graph_resolve_project_path(root, "out/lib/llvm_link.rsp"))
    argv = build_graph_argv_append(argv, "-lc")
    emitc_run_capture(root, target.name, "compile-with-from-c-full", argv, 900000)

fn emitc_migrate_compiler_c(root: str, target: BuildGraphTarget, compiler_path: str, main_c: str, output_w: str) -> i32:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "migrate")
    argv = build_graph_argv_append(argv, main_c)
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_w)
    argv = build_graph_argv_append(argv, "-I")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "runtime"))
    argv = build_graph_argv_append(argv, "-include")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "out/gen/wl_decls.h"))
    argv = build_graph_argv_append(argv, "--no-c-export")
    emitc_run_capture(root, target.name, "migrate-compiler-c", argv, 900000)

fn emitc_build_with_compiler(root: str, target: BuildGraphTarget, compiler_path: str, source_w: str, output_path: str, label: str) -> i32:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "build")
    argv = build_graph_argv_append(argv, source_w)
    argv = build_graph_argv_append(argv, "-O0")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_path)
    emitc_run_capture(root, target.name, label, argv, 900000)

fn emitc_run_single_test(root: str, target: BuildGraphTarget, compiler_path: str, test_path: str, label: str) -> i32:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "test")
    argv = build_graph_argv_append(argv, "--quiet")
    argv = build_graph_argv_append(argv, build_graph_path_for_child_process(root, test_path))
    emitc_run_capture(root, target.name, label, argv, 300000)

fn emitc_run_test_group(root: str, target: BuildGraphTarget, compiler_path: str, entry: str, label: str) -> i32:
    let files = build_graph_test_target_files(root, entry)
    if files.len() == 0:
        build_graph_rt_eprint("error: emit-c roundtrip target '" ++ target.name ++ "' matched no tests: " ++ entry)
        return 1
    for fi in 0..files.len() as i32:
        let test_path = files.get(fi as i64)
        let base = build_graph_path_basename(test_path)
        let rc = emitc_run_single_test(root, target, compiler_path, test_path, label ++ "-" ++ base)
        if rc != 0:
            return rc
    0

fn emitc_run_compiler_test_suite(root: str, target: BuildGraphTarget, compiler_path: str, label: str) -> i32:
    let groups: [5]str = [
        "test/behavior/*.w",
        "test/compile_errors/*.w",
        "test/codegen/*.w",
        "test/spec/*.w",
        "test/phase/*.w",
    ]
    for gi in 0..5:
        let rc = emitc_run_test_group(root, target, compiler_path, groups[gi], label)
        if rc != 0:
            return rc
    0

fn emitc_build_hello_c(root: str, target: BuildGraphTarget, compiler_path: str, hello_c: str) -> i32:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "build")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "test/hello.w"))
    argv = build_graph_argv_append(argv, "--emit-c")
    argv = build_graph_argv_append(argv, "--no-prelude")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, hello_c)
    emitc_run_capture(root, target.name, "emit-hello-c", argv, 600000)

fn emitc_compile_hello(root: str, target: BuildGraphTarget, hello_c: str, output_path: str) -> i32:
    let zig = build_graph_zig_tool().executable
    var argv = ""
    argv = build_graph_argv_append(argv, zig)
    argv = build_graph_argv_append(argv, "cc")
    argv = build_graph_argv_append(argv, "-O2")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_path)
    argv = build_graph_argv_append(argv, hello_c)
    argv = emitc_compile_runtime_args(root, argv)
    argv = build_graph_argv_append(argv, "-I")
    argv = build_graph_argv_append(argv, build_graph_resolve_project_path(root, "runtime"))
    argv = build_graph_argv_append(argv, "-lc")
    emitc_run_capture(root, target.name, "compile-hello", argv, 600000)

fn emitc_run_hello(root: str, target: BuildGraphTarget, hello_path: str) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/command"), target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        return 1
    let stdout_path = resolve_join(capture_dir, "hello.stdout")
    let stderr_path = resolve_join(capture_dir, "hello.stderr")
    var argv = ""
    argv = build_graph_argv_append(argv, hello_path)
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, 120000)
    if rc != 0:
        let stderr = build_graph_rt_read_file(stderr_path)
        if stderr.len() > 0:
            build_graph_rt_eprint(stderr)
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ f"' hello binary failed with exit code {rc}")
        return if rc == 0: 1 else: rc
    let stdout = emitc_trim(build_graph_rt_read_file(stdout_path))
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    if stdout != "hello":
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' hello output mismatch: " ++ stdout)
        return 1
    0

fn emitc_compare_files(left_path: str, right_path: str, target_name: str) -> i32:
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
        build_graph_rt_eprint("error: emit-c comparison target '" ++ target_name ++ f"' failed: files differ at byte {diff_at}: " ++ left_path ++ " vs " ++ right_path)
        return 1
    0

pub fn build_graph_run_emit_c_test(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' requires a compiler path")
        return 1
    if target.output.len() == 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' requires a stamp output")
        return 1
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    if build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return 1
    let out_dir = build_graph_resolve_project_path(root, "out/emit-c-test")
    let _clean = build_graph_rt_remove_tree(out_dir)
    if build_graph_rt_mkdir_p(out_dir) != 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' could not create output directory: " ++ out_dir)
        return 1
    let main_c = resolve_join(out_dir, "main.c")
    let with_from_c = resolve_join(out_dir, "with-from-c")
    let hello_c = resolve_join(out_dir, "hello_test.c")
    let hello_bin = resolve_join(out_dir, "hello_test")
    let emit_rc = emitc_build_compiler_c(root, target, compiler_path, main_c)
    if emit_rc != 0:
        return emit_rc
    let stubs_rc = emitc_generate_stub_files(root, target.name)
    if stubs_rc != 0:
        return stubs_rc
    let compile_rc = emitc_compile_c_compiler(root, target, main_c, with_from_c)
    if compile_rc != 0:
        return compile_rc
    var version_argv = ""
    version_argv = build_graph_argv_append(version_argv, with_from_c)
    version_argv = build_graph_argv_append(version_argv, "--version")
    let version_rc = emitc_run_capture(root, target.name, "with-from-c-version", version_argv, 120000)
    if version_rc != 0:
        return version_rc
    let hello_emit_rc = emitc_build_hello_c(root, target, with_from_c, hello_c)
    if hello_emit_rc != 0:
        return hello_emit_rc
    let hello_compile_rc = emitc_compile_hello(root, target, hello_c, hello_bin)
    if hello_compile_rc != 0:
        return hello_compile_rc
    let hello_rc = emitc_run_hello(root, target, hello_bin)
    if hello_rc != 0:
        return hello_rc
    let stamp_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_mkdir_p(build_graph_dirname(stamp_path)) != 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' could not create stamp directory")
        return 1
    if build_graph_rt_write_file(stamp_path, "ok\n") != 0:
        build_graph_rt_eprint("error: emit_c_test target '" ++ target.name ++ "' could not write stamp: " ++ stamp_path)
        return 1
    build_graph_rt_write("EMIT-C OK\n")
    0

pub fn build_graph_run_emit_c_fixpoint(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: emit_c_fixpoint target '" ++ target.name ++ "' requires emitted compiler path")
        return 1
    if target.output.len() == 0:
        build_graph_rt_eprint("error: emit_c_fixpoint target '" ++ target.name ++ "' requires a stamp output")
        return 1
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    let main_c = build_graph_resolve_project_path(root, "out/emit-c-test/main.c")
    let main2_c = build_graph_resolve_project_path(root, "out/emit-c-test/main2.c")
    if build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: emit_c_fixpoint target '" ++ target.name ++ "' missing emitted compiler: " ++ compiler_path)
        return 1
    if build_graph_rt_file_exists(main_c) == 0:
        build_graph_rt_eprint("error: emit_c_fixpoint target '" ++ target.name ++ "' missing first emitted C file: " ++ main_c)
        return 1
    let emit_rc = emitc_build_compiler_c(root, target, compiler_path, main2_c)
    if emit_rc != 0:
        return emit_rc
    let compare_rc = emitc_compare_files(main_c, main2_c, target.name)
    if compare_rc != 0:
        build_graph_rt_eprint("EMIT-C DIVERGED")
        return compare_rc
    let stamp_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_mkdir_p(build_graph_dirname(stamp_path)) != 0:
        build_graph_rt_eprint("error: emit_c_fixpoint target '" ++ target.name ++ "' could not create stamp directory")
        return 1
    if build_graph_rt_write_file(stamp_path, "ok\n") != 0:
        build_graph_rt_eprint("error: emit_c_fixpoint target '" ++ target.name ++ "' could not write stamp: " ++ stamp_path)
        return 1
    build_graph_rt_write("EMIT-C FIXPOINT\n")
    0

pub fn build_graph_run_emit_c_roundtrip(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: emit_c_roundtrip target '" ++ target.name ++ "' requires a compiler path")
        return 1
    if target.output.len() == 0:
        build_graph_rt_eprint("error: emit_c_roundtrip target '" ++ target.name ++ "' requires a stamp output")
        return 1
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    if build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: emit_c_roundtrip target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return 1

    let out_dir = build_graph_resolve_project_path(root, "out/emit-c-roundtrip")
    let _clean = build_graph_rt_remove_tree(out_dir)
    if build_graph_rt_mkdir_p(out_dir) != 0:
        build_graph_rt_eprint("error: emit_c_roundtrip target '" ++ target.name ++ "' could not create output directory: " ++ out_dir)
        return 1

    let main_c = resolve_join(out_dir, "main.c")
    let with_from_c = resolve_join(out_dir, "with-from-c")
    let migrated_w = resolve_join(out_dir, "main_roundtrip.w")
    let with_roundtrip = resolve_join(out_dir, "with-roundtrip")
    let with_rebuilt_by_roundtrip = resolve_join(out_dir, "with-rebuilt-by-roundtrip")

    let emit_rc = emitc_build_compiler_c(root, target, compiler_path, main_c)
    if emit_rc != 0:
        return emit_rc

    let stubs_rc = emitc_generate_stub_files(root, target.name)
    if stubs_rc != 0:
        return stubs_rc

    let compile_c_rc = emitc_compile_c_compiler_with_bridges(root, target, main_c, with_from_c)
    if compile_c_rc != 0:
        return compile_c_rc

    let migrate_rc = emitc_migrate_compiler_c(root, target, compiler_path, main_c, migrated_w)
    if migrate_rc != 0:
        return migrate_rc

    let build_migrated_rc = emitc_build_with_compiler(root, target, compiler_path, migrated_w, with_roundtrip, "build-migrated-compiler")
    if build_migrated_rc != 0:
        return build_migrated_rc

    let c_tests_rc = emitc_run_compiler_test_suite(root, target, with_from_c, "with-from-c")
    if c_tests_rc != 0:
        return c_tests_rc

    let migrated_tests_rc = emitc_run_compiler_test_suite(root, target, with_roundtrip, "with-roundtrip")
    if migrated_tests_rc != 0:
        return migrated_tests_rc

    let selfhost_rebuild_rc = emitc_build_with_compiler(root, target, with_roundtrip, build_graph_resolve_project_path(root, "out/gen/main.w"), with_rebuilt_by_roundtrip, "build-compiler-with-roundtrip")
    if selfhost_rebuild_rc != 0:
        return selfhost_rebuild_rc

    let selfhost_compare_rc = emitc_compare_files(compiler_path, with_rebuilt_by_roundtrip, target.name)
    if selfhost_compare_rc != 0:
        build_graph_rt_eprint("EMIT-C ROUNDTRIP SELFHOST DIVERGED")
        return selfhost_compare_rc

    let stamp_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_mkdir_p(build_graph_dirname(stamp_path)) != 0:
        build_graph_rt_eprint("error: emit_c_roundtrip target '" ++ target.name ++ "' could not create stamp directory")
        return 1
    if build_graph_rt_write_file(stamp_path, "ok\n") != 0:
        build_graph_rt_eprint("error: emit_c_roundtrip target '" ++ target.name ++ "' could not write stamp: " ++ stamp_path)
        return 1
    build_graph_rt_write("EMIT-C ROUNDTRIP OK\n")
    0
