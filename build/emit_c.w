module build.emit_c

use std.build
use std.process
use std.sysinfo

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

fn emitc_fail(ctx: &ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn emitc_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn emitc_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    emitc_join(root, path)

fn emitc_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn emitc_basename(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    path.slice((last_slash + 1) as i64, path.len())

fn emitc_exe_name(name: str) -> str:
    if os() == "Windows" and not name.ends_with(".exe"):
        return name ++ ".exe"
    name

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

fn emitc_c_compiler() -> str:
    let explicit = env("WITH_EMIT_C_CC")
    if explicit.len() > 0:
        return explicit
    let cc = env("CC")
    if cc.len() > 0:
        return cc
    let llvm_prefix = env("LLVM_PREFIX")
    if llvm_prefix.len() > 0:
        if os() == "Windows":
            return llvm_prefix ++ "/bin/clang++.exe"
        return llvm_prefix ++ "/bin/clang++"
    if os() == "Windows":
        return ".deps/llvm-22.1.6-windows-x86_64-msvc/bin/clang++.exe"
    if os() == "Linux":
        return ".deps/llvm-22.1.6-linux-x86_64/bin/clang++"
    if os() == "Macos":
        return ".deps/llvm-22.1.6-darwin-arm64/bin/clang++"
    "clang++"

fn emitc_push_c_compiler(argv: Vec[str]) -> Vec[str]:
    argv.push(emitc_c_compiler())
    argv

fn emitc_push_c_source(argv: Vec[str], path: str) -> Vec[str]:
    argv |> push("-x")
    argv |> push("c")
    argv |> push(path)
    argv |> push("-x")
    argv |> push("none")
    argv

fn emitc_host_platform_runtime_object() -> str:
    let host_os = os()
    let host_arch = arch()
    if host_os == "Linux" and host_arch == "x86_64":
        return "rt_linux_x86_64.o"
    if host_os == "Macos" and (host_arch == "armv8" or host_arch == "aarch64"):
        return "rt_darwin_aarch64.o"
    if host_os == "Windows" and host_arch == "x86_64":
        return "rt_windows_x86_64.o"
    ""

fn emitc_push_host_c_flags(argv: Vec[str]) -> Vec[str]:
    if os() == "Linux":
        argv |> push("-no-pie")
        argv |> push("-fuse-ld=lld")
    if os() == "Windows":
        argv |> push("-target")
        argv |> push("x86_64-pc-windows-msvc")
        argv |> push("-fms-runtime-lib=static")
        argv |> push("-D_CRT_SECURE_NO_WARNINGS")
        argv |> push("-fuse-ld=lld")
        argv |> push("-Wl,/stack:8388608")
        argv |> push("-Wl,/libpath:C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64")
        argv |> push("-Wl,/libpath:C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64")
        argv |> push("-Wl,/libpath:C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/lib/x64")
    argv

fn emitc_windows_sdk_um_lib(name: str) -> str:
    "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64/" ++ name

fn emitc_windows_sdk_ucrt_lib(name: str) -> str:
    "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64/" ++ name

fn emitc_windows_msvc_lib(name: str) -> str:
    "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/lib/x64/" ++ name

fn emitc_push_system_libs(argv: Vec[str]) -> Vec[str]:
    if os() == "Windows":
        argv |> push(emitc_windows_msvc_lib("libcpmt.lib"))
        argv |> push(emitc_windows_msvc_lib("libcmt.lib"))
        argv |> push(emitc_windows_msvc_lib("oldnames.lib"))
        argv |> push(emitc_windows_sdk_um_lib("kernel32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("advapi32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("bcrypt.lib"))
        argv |> push(emitc_windows_sdk_um_lib("shell32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("user32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("ole32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("oleaut32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("uuid.lib"))
        argv |> push(emitc_windows_sdk_um_lib("ws2_32.lib"))
        argv |> push(emitc_windows_sdk_um_lib("version.lib"))
        argv |> push(emitc_windows_sdk_um_lib("psapi.lib"))
        argv |> push(emitc_windows_sdk_um_lib("dbghelp.lib"))
        argv |> push(emitc_windows_sdk_um_lib("ntdll.lib"))
    else:
        argv |> push("-lc")
        if os() == "Linux":
            argv |> push("-lm")
    argv

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
    if with_type == "u8": return "uint8_t"
    if with_type == "i32": return "int32_t"
    if with_type == "i64": return "int64_t"
    if with_type == "u32": return "uint32_t"
    if with_type == "u64": return "uint64_t"
    if with_type == "f64": return "double"
    if with_type == "str": return "with_str"
    if with_type == "WithVec": return "with_vec"
    if with_type == "*const WithVec": return "const with_vec *"
    if with_type == "*mut WithVec": return "with_vec *"
    if with_type == "*const u8": return "const uint8_t *"
    if with_type == "*mut u8": return "uint8_t *"
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
    EmitCParam { name, c_type: emitc_c_type(with_type) }

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

fn emitc_collect_exports_from_text(ctx: &ActionCtx, text: str, source_path: str) -> Vec[EmitCFunction]:
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
                    let _ = emitc_fail(ctx, "could not parse c_export signature for " ++ pending_symbol ++ " in " ++ source_path)
                    return Vec.new()
                exports.push(fn_sig)
                pending_symbol = ""
                continue
            if line.len() > 0 and not line.starts_with("//"):
                let _ = emitc_fail(ctx, "c_export is not followed by a function in " ++ source_path ++ ": " ++ pending_symbol)
                return Vec.new()
    if pending_symbol.len() > 0:
        let _ = emitc_fail(ctx, "unterminated c_export in " ++ source_path ++ ": " ++ pending_symbol)
        return Vec.new()
    exports

fn emitc_public_function_name(line: str) -> str:
    var start = -1
    if line.starts_with("pub fn "):
        start = 7
    else if line.starts_with("pub unsafe fn "):
        start = 14
    if start < 0:
        return ""
    var i = start
    while i < line.len() as i32:
        let ch = line.byte_at(i as i64)
        if ch == 40 or ch == 32 or ch == 58:
            break
        i = i + 1
    if i <= start:
        return ""
    line.slice(start as i64, i as i64)

fn emitc_is_bridge_abi_symbol(name: str) -> bool:
    name.starts_with("wl_") or name.starts_with("with_cimport_") or name.starts_with("with_ci_")

fn emitc_is_runtime_abi_symbol(name: str) -> bool:
    name.starts_with("with_regex_")

fn emitc_collect_public_abi_from_text(ctx: &ActionCtx, text: str, source_path: str, runtime: i32) -> Vec[EmitCFunction]:
    let exports: Vec[EmitCFunction] = Vec.new()
    let lines = emitc_split_lines(text)
    for li in 0..lines.len() as i32:
        let line = emitc_trim(lines.get(li as i64))
        let name = emitc_public_function_name(line)
        if name.len() == 0:
            continue
        let include =
            if runtime != 0:
                emitc_is_runtime_abi_symbol(name)
            else:
                emitc_is_bridge_abi_symbol(name)
        if not include:
            continue
        let fn_sig = emitc_parse_export_function(name, line)
        if fn_sig.ok == 0:
            let _ = emitc_fail(ctx, "could not parse public ABI signature for " ++ name ++ " in " ++ source_path)
            return Vec.new()
        exports.push(fn_sig)
    exports

fn emitc_collect_public_abi(ctx: &ActionCtx, sources: Vec[str], runtime: i32) -> Vec[EmitCFunction]:
    let all: Vec[EmitCFunction] = Vec.new()
    let fs = ctx.fs()
    for si in 0..sources.len() as i32:
        let source_path = sources.get(si as i64)
        let text = fs.read_text(source_path)
        if text.len() == 0:
            let _ = emitc_fail(ctx, "could not read source for ABI scan: " ++ source_path)
            return Vec.new()
        let exports = emitc_collect_public_abi_from_text(ctx, text, source_path, runtime)
        if exports.len() == 0:
            return Vec.new()
        for ei in 0..exports.len() as i32:
            all.push(exports.get(ei as i64))
    all

fn emitc_collect_exports(ctx: &ActionCtx, sources: Vec[str]) -> Vec[EmitCFunction]:
    let all: Vec[EmitCFunction] = Vec.new()
    let fs = ctx.fs()
    for si in 0..sources.len() as i32:
        let source_path = sources.get(si as i64)
        let text = fs.read_text(source_path)
        if text.len() == 0:
            let _ = emitc_fail(ctx, "could not read source for export scan: " ++ source_path)
            return Vec.new()
        let exports = emitc_collect_exports_from_text(ctx, text, source_path)
        if exports.len() == 0:
            return Vec.new()
        for ei in 0..exports.len() as i32:
            all.push(exports.get(ei as i64))
    all

fn emitc_function_proto(fn_sig: &EmitCFunction) -> str:
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

fn emitc_generate_stub_files(ctx: &ActionCtx) -> i32:
    let bridge_sources: Vec[str] = Vec.new()
    bridge_sources |> push("src/compiler/LlvmBridge.w")
    bridge_sources |> push("src/compiler/ClangBridge.w")
    let stub_exports = emitc_collect_public_abi(ctx, bridge_sources, 0)
    if stub_exports.len() == 0:
        return emitc_fail(ctx, "found no bridge exports")
    let fs = ctx.fs()
    if fs.mkdir_all("out/gen") != 0:
        return emitc_fail(ctx, "could not create out/gen")
    var decls = "// Auto-generated by with build emit-c.\n"
    decls = decls ++ "#ifndef WITH_EMIT_C_BRIDGE_DECLS_H\n"
    decls = decls ++ "#define WITH_EMIT_C_BRIDGE_DECLS_H\n\n"
    decls = decls ++ "#include \"with_runtime.h\"\n\n"
    var stubs = "// Auto-generated by with build emit-c.\n"
    stubs = stubs ++ "#include \"wl_decls.h\"\n\n"
    for ei in 0..stub_exports.len() as i32:
        let fn_sig = stub_exports.get(ei as i64)
        let proto = emitc_function_proto(fn_sig)
        decls = decls ++ proto ++ ";\n"
        stubs = stubs ++ proto ++ " {\n"
        for pi in 0..fn_sig.params.len() as i32:
            let param = fn_sig.params.get(pi as i64)
            stubs = stubs ++ "    (void)" ++ param.name ++ ";\n"
        stubs = stubs ++ emitc_stub_return(fn_sig.return_type)
        stubs = stubs ++ "}\n\n"
    let runtime_sources: Vec[str] = Vec.new()
    runtime_sources |> push("rt/regex_runtime.w")
    let runtime_exports = emitc_collect_public_abi(ctx, runtime_sources, 1)
    if runtime_exports.len() == 0:
        return emitc_fail(ctx, "found no runtime exports")
    for ei in 0..runtime_exports.len() as i32:
        decls = decls ++ emitc_function_proto(runtime_exports.get(ei as i64)) ++ ";\n"
    decls = decls ++ "\n#endif\n"
    if fs.write_text("out/gen/wl_decls.h", decls) != 0:
        return emitc_fail(ctx, "could not write out/gen/wl_decls.h")
    if fs.write_text("out/gen/wl_stubs.c", stubs) != 0:
        return emitc_fail(ctx, "could not write out/gen/wl_stubs.c")
    0

fn emitc_capture_rel(ctx: &ActionCtx, label: str, suffix: str) -> str:
    emitc_join(emitc_join("out/command", ctx.target_name()), label ++ "." ++ suffix)

fn emitc_run_capture(ctx: &ActionCtx, label: str, argv: Vec[str], timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let fs = ctx.fs()
    let capture_dir = emitc_join("out/command", ctx.target_name())
    if fs.mkdir_all(capture_dir) != 0:
        return emitc_fail(ctx, "could not create capture directory: " ++ capture_dir)
    let stdout_rel = emitc_capture_rel(ctx, label, "stdout")
    let stderr_rel = emitc_capture_rel(ctx, label, "stderr")
    var env = process_env()
    env = env.set("WITH_OUT_DIR", emitc_abs(root, "out"))
    let result = ctx.process_runner().run_capture_with_env(argv, emitc_abs(root, stdout_rel), emitc_abs(root, stderr_rel), timeout_ms, env)
    if result.rc == 0:
        let _remove_stdout = fs.remove_file(stdout_rel)
        let _remove_stderr = fs.remove_file(stderr_rel)
        return 0
    if result.stderr.len() > 0:
        ctx.diagnostics().error(result.stderr)
    emitc_fail(ctx, "step '" ++ label ++ f"' failed with exit code {result.rc}; stdout=" ++ stdout_rel ++ " stderr=" ++ stderr_rel)

fn emitc_compile_runtime_args(root: str, argv: Vec[str], platform_obj: str) -> Vec[str]:
    argv |> push(emitc_abs(root, "out/lib/rt_core.o"))
    argv |> push(emitc_abs(root, "out/lib/" ++ platform_obj))
    argv |> push(emitc_abs(root, "out/lib/compat_runtime.o"))
    argv |> push(emitc_abs(root, "out/lib/panic_runtime.o"))
    argv |> push(emitc_abs(root, "out/lib/regex_runtime.o"))
    argv |> push(emitc_abs(root, "out/lib/fiber_stubs.o"))
    argv |> push(emitc_abs(root, "out/lib/cimport_stubs.o"))
    argv

fn emitc_build_compiler_c(ctx: &ActionCtx, compiler_path: str, main_c: str) -> i32:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv |> push(emitc_abs(root, compiler_path))
    argv |> push("build")
    argv |> push(emitc_abs(root, "out/gen/main.w"))
    argv |> push("--emit-c")
    argv |> push("-o")
    argv |> push(emitc_abs(root, main_c))
    emitc_run_capture(ctx, "emit-compiler-c", argv, 600000)

fn emitc_build_compiler_c_workspace(ctx: &ActionCtx, source_w: str, main_c: str) -> i32:
    let ws = ctx.create_workspace("emit-compiler-c")
    ws.add_file(source_w)
    var options = ws.options()
    options.output_path = main_c
    options.output_kind = BuildOutputKind.C
    ws.set_options(options)
    let result = ws.compile()
    if result.rc != 0:
        return emitc_fail(ctx, f"workspace emit-C failed with exit code {result.rc}")
    if not ctx.fs().exists(main_c):
        return emitc_fail(ctx, "workspace emit-C did not produce output: " ++ main_c)
    0

pub fn run_bootstrap_c_emit_sources_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let main_c = ctx.output()
    let out_dir = emitc_dirname(main_c)
    if fs.mkdir_all(out_dir) != 0:
        return emitc_fail(ctx, "could not create output directory: " ++ out_dir)
    var rc = emitc_build_compiler_c_workspace(ctx, "out/gen/main.w", main_c)
    if rc != 0: return rc
    emitc_generate_stub_files(ctx)

fn emitc_compile_c_compiler(ctx: &ActionCtx, main_c: str, output_path: str) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let platform_obj = emitc_host_platform_runtime_object()
    if platform_obj.len() == 0:
        return emitc_fail(ctx, "unsupported host runtime object for emit-c C compile: " ++ os() ++ "/" ++ arch())
    let llvm_rsp = "out/lib/llvm_link.rsp"
    if fs.read_text(llvm_rsp).len() == 0:
        return emitc_fail(ctx, "missing LLVM link metadata: " ++ llvm_rsp)
    var argv: Vec[str] = Vec.new()
    argv = emitc_push_c_compiler(argv)
    argv |> push("-O2")
    argv = emitc_push_host_c_flags(argv)
    argv |> push("-o")
    argv |> push(emitc_abs(root, output_path))
    argv = emitc_push_c_source(argv, emitc_abs(root, main_c))
    argv = emitc_compile_runtime_args(root, argv, platform_obj)
    argv |> push(emitc_abs(root, "out/lib/embedded_objects.o"))
    argv |> push("-I")
    argv |> push(emitc_abs(root, "runtime"))
    argv |> push("-include")
    argv |> push(emitc_abs(root, "out/gen/wl_decls.h"))
    argv |> push("@" ++ emitc_abs(root, llvm_rsp))
    emitc_run_capture(ctx, "compile-with-from-c", argv, 600000)

fn emitc_compile_c_compiler_with_bridges(ctx: &ActionCtx, main_c: str, output_path: str) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let platform_obj = emitc_host_platform_runtime_object()
    if platform_obj.len() == 0:
        return emitc_fail(ctx, "unsupported host runtime object for full emit-c C compile: " ++ os() ++ "/" ++ arch())
    let cc_path = emitc_trim(fs.read_text("out/lib/llvm_cc"))
    if cc_path.len() == 0:
        return emitc_fail(ctx, "missing LLVM compiler metadata: out/lib/llvm_cc")
    var argv: Vec[str] = Vec.new()
    argv |> push(cc_path)
    argv |> push("-O2")
    argv = emitc_push_host_c_flags(argv)
    argv |> push("-fuse-ld=lld")
    argv |> push("-o")
    argv |> push(emitc_abs(root, output_path))
    argv = emitc_push_c_source(argv, emitc_abs(root, main_c))
    argv = emitc_compile_runtime_args(root, argv, platform_obj)
    argv |> push(emitc_abs(root, "out/lib/embedded_objects.o"))
    argv |> push("-I")
    argv |> push(emitc_abs(root, "runtime"))
    argv |> push("-include")
    argv |> push(emitc_abs(root, "out/gen/wl_decls.h"))
    argv |> push("@" ++ emitc_abs(root, "out/lib/llvm_link.rsp"))
    emitc_run_capture(ctx, "compile-with-from-c-full", argv, 900000)

fn emitc_migrate_compiler_c(ctx: &ActionCtx, compiler_path: str, main_c: str, output_w: str) -> i32:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv |> push(emitc_abs(root, compiler_path))
    argv |> push("migrate")
    argv |> push(emitc_abs(root, main_c))
    argv |> push("-o")
    argv |> push(emitc_abs(root, output_w))
    argv |> push("-I")
    argv |> push(emitc_abs(root, "runtime"))
    argv |> push("-include")
    argv |> push(emitc_abs(root, "out/gen/wl_decls.h"))
    argv |> push("--no-c-export")
    emitc_run_capture(ctx, "migrate-compiler-c", argv, 900000)

fn emitc_build_with_compiler(ctx: &ActionCtx, compiler_path: str, source_w: str, output_path: str, label: str) -> i32:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv |> push(emitc_abs(root, compiler_path))
    argv |> push("build")
    argv |> push(emitc_abs(root, source_w))
    argv |> push("-O0")
    argv |> push("-o")
    argv |> push(emitc_abs(root, output_path))
    emitc_run_capture(ctx, label, argv, 900000)

fn emitc_run_single_test(ctx: &ActionCtx, compiler_path: str, test_path: str, label: str) -> i32:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv |> push(emitc_abs(root, compiler_path))
    argv |> push("test")
    argv |> push("--quiet")
    argv |> push(emitc_abs(root, test_path))
    emitc_run_capture(ctx, label, argv, 300000)

fn emitc_test_target_files(ctx: &ActionCtx, entry: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    let star = emitc_index_of(entry, "*")
    if star < 0:
        files.push(entry)
        return files
    let dir = emitc_dirname(entry)
    let suffix = entry.slice((star + 1) as i64, entry.len())
    let all = ctx.fs().list_files(dir)
    for i in 0..all.len() as i32:
        let path = all.get(i as i64)
        if suffix.len() == 0 or path.ends_with(suffix):
            files.push(path)
    files

fn emitc_run_test_group(ctx: &ActionCtx, compiler_path: str, entry: str, label: str) -> i32:
    let files = emitc_test_target_files(ctx, entry)
    if files.len() == 0:
        return emitc_fail(ctx, "matched no tests: " ++ entry)
    for fi in 0..files.len() as i32:
        let test_path = files.get(fi as i64)
        let base = emitc_basename(test_path)
        let rc = emitc_run_single_test(ctx, compiler_path, test_path, label ++ "-" ++ base)
        if rc != 0:
            return rc
    0

fn emitc_run_compiler_test_suite(ctx: &ActionCtx, compiler_path: str, label: str) -> i32:
    let groups: [5]str = [
        "test/behavior/*.w",
        "test/compile_errors/*.w",
        "test/codegen/*.w",
        "test/spec/*.w",
        "test/phase/*.w",
    ]
    for gi in 0..5:
        let rc = emitc_run_test_group(ctx, compiler_path, groups[gi], label)
        if rc != 0:
            return rc
    0

fn emitc_build_hello_c(ctx: &ActionCtx, compiler_path: str, hello_c: str) -> i32:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv |> push(emitc_abs(root, compiler_path))
    argv |> push("build")
    argv |> push(emitc_abs(root, "test/hello.w"))
    argv |> push("--emit-c")
    argv |> push("--no-prelude")
    argv |> push("-o")
    argv |> push(emitc_abs(root, hello_c))
    emitc_run_capture(ctx, "emit-hello-c", argv, 600000)

fn emitc_compile_hello(ctx: &ActionCtx, hello_c: str, output_path: str) -> i32:
    let root = ctx.project_info().project_root()
    let platform_obj = emitc_host_platform_runtime_object()
    if platform_obj.len() == 0:
        return emitc_fail(ctx, "unsupported host runtime object for emit-c hello compile: " ++ os() ++ "/" ++ arch())
    var argv: Vec[str] = Vec.new()
    argv = emitc_push_c_compiler(argv)
    argv |> push("-O2")
    argv = emitc_push_host_c_flags(argv)
    argv |> push("-o")
    argv |> push(emitc_abs(root, output_path))
    argv = emitc_push_c_source(argv, emitc_abs(root, hello_c))
    argv = emitc_compile_runtime_args(root, argv, platform_obj)
    argv |> push("-I")
    argv |> push(emitc_abs(root, "runtime"))
    argv = emitc_push_system_libs(argv)
    emitc_run_capture(ctx, "compile-hello", argv, 600000)

fn emitc_run_hello(ctx: &ActionCtx, hello_path: str) -> i32:
    let root = ctx.project_info().project_root()
    let fs = ctx.fs()
    let stdout_rel = emitc_capture_rel(ctx, "hello", "stdout")
    let stderr_rel = emitc_capture_rel(ctx, "hello", "stderr")
    var argv: Vec[str] = Vec.new()
    argv |> push(emitc_abs(root, hello_path))
    let result = ctx.process_runner().run_capture(argv, emitc_abs(root, stdout_rel), emitc_abs(root, stderr_rel), 120000)
    if result.rc != 0:
        if result.stderr.len() > 0:
            ctx.diagnostics().error(result.stderr)
        return emitc_fail(ctx, f"hello binary failed with exit code {result.rc}")
    let _remove_stdout = fs.remove_file(stdout_rel)
    let _remove_stderr = fs.remove_file(stderr_rel)
    if emitc_trim(result.stdout) != "hello":
        return emitc_fail(ctx, "hello output mismatch: " ++ result.stdout)
    0

fn emitc_compare_files(ctx: &ActionCtx, left_path: str, right_path: str) -> i32:
    let fs = ctx.fs()
    let left = fs.read_text(left_path)
    let right = fs.read_text(right_path)
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
        return emitc_fail(ctx, f"files differ at byte {diff_at}: " ++ left_path ++ " vs " ++ right_path)
    0

pub fn run_emit_c_test_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return emitc_fail(ctx, "requires compiler input")
    let fs = ctx.fs()
    let out_dir = "out/emit-c-test"
    let stamp_path = ctx.output()
    let compiler_path = inputs.get(0)
    if not fs.exists(compiler_path):
        return emitc_fail(ctx, "missing compiler: " ++ compiler_path)
    let _clean = fs.remove_tree(out_dir)
    if fs.mkdir_all(out_dir) != 0:
        return emitc_fail(ctx, "could not create output directory: " ++ out_dir)
    let main_c = emitc_join(out_dir, "main.c")
    let with_from_c = emitc_join(out_dir, emitc_exe_name("with-from-c"))
    let hello_c = emitc_join(out_dir, "hello_test.c")
    let hello_bin = emitc_join(out_dir, emitc_exe_name("hello_test"))
    var rc = emitc_build_compiler_c(ctx, compiler_path, main_c)
    if rc != 0: return rc
    rc = emitc_generate_stub_files(ctx)
    if rc != 0: return rc
    rc = emitc_compile_c_compiler(ctx, main_c, with_from_c)
    if rc != 0: return rc
    var version_argv: Vec[str] = Vec.new()
    version_argv |> push(emitc_abs(ctx.project_info().project_root(), with_from_c))
    version_argv |> push("--version")
    rc = emitc_run_capture(ctx, "with-from-c-version", version_argv, 120000)
    if rc != 0: return rc
    rc = emitc_build_hello_c(ctx, with_from_c, hello_c)
    if rc != 0: return rc
    rc = emitc_compile_hello(ctx, hello_c, hello_bin)
    if rc != 0: return rc
    rc = emitc_run_hello(ctx, hello_bin)
    if rc != 0: return rc
    if fs.mkdir_all(emitc_dirname(stamp_path)) != 0:
        return emitc_fail(ctx, "could not create stamp directory")
    if fs.write_text(stamp_path, "ok\n") != 0:
        return emitc_fail(ctx, "could not write stamp: " ++ stamp_path)
    print("EMIT-C OK")
    0

pub fn run_emit_c_fixpoint_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() < 2:
        return emitc_fail(ctx, "requires emitted C and compiler inputs")
    let fs = ctx.fs()
    let stamp_path = ctx.output()
    let main_c = inputs.get(0)
    let compiler_path = inputs.get(1)
    let main2_c = "out/emit-c-test/main2.c"
    if not fs.exists(compiler_path):
        return emitc_fail(ctx, "missing emitted compiler: " ++ compiler_path)
    if not fs.exists(main_c):
        return emitc_fail(ctx, "missing first emitted C file: " ++ main_c)
    var rc = emitc_build_compiler_c(ctx, compiler_path, main2_c)
    if rc != 0: return rc
    rc = emitc_compare_files(ctx, main_c, main2_c)
    if rc != 0:
        ctx.diagnostics().error("EMIT-C DIVERGED")
        return rc
    if fs.mkdir_all(emitc_dirname(stamp_path)) != 0:
        return emitc_fail(ctx, "could not create stamp directory")
    if fs.write_text(stamp_path, "ok\n") != 0:
        return emitc_fail(ctx, "could not write stamp: " ++ stamp_path)
    print("EMIT-C FIXPOINT")
    0

pub fn run_emit_c_roundtrip_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return emitc_fail(ctx, "requires compiler input")
    let fs = ctx.fs()
    let out_dir = "out/emit-c-roundtrip"
    let stamp_path = ctx.output()
    let compiler_path = inputs.get(0)
    if not fs.exists(compiler_path):
        return emitc_fail(ctx, "missing compiler: " ++ compiler_path)
    let _clean = fs.remove_tree(out_dir)
    if fs.mkdir_all(out_dir) != 0:
        return emitc_fail(ctx, "could not create output directory: " ++ out_dir)
    let main_c = emitc_join(out_dir, "main.c")
    let with_from_c = emitc_join(out_dir, emitc_exe_name("with-from-c"))
    let migrated_w = emitc_join(out_dir, "main_roundtrip.w")
    let with_roundtrip = emitc_join(out_dir, emitc_exe_name("with-roundtrip"))
    let with_rebuilt_by_roundtrip = emitc_join(out_dir, emitc_exe_name("with-rebuilt-by-roundtrip"))
    var rc = emitc_build_compiler_c_workspace(ctx, "out/gen/main.w", main_c)
    if rc != 0: return rc
    rc = emitc_generate_stub_files(ctx)
    if rc != 0: return rc
    rc = emitc_compile_c_compiler_with_bridges(ctx, main_c, with_from_c)
    if rc != 0: return rc
    rc = emitc_migrate_compiler_c(ctx, compiler_path, main_c, migrated_w)
    if rc != 0: return rc
    rc = emitc_build_with_compiler(ctx, compiler_path, migrated_w, with_roundtrip, "build-migrated-compiler")
    if rc != 0: return rc
    rc = emitc_run_compiler_test_suite(ctx, with_from_c, "with-from-c")
    if rc != 0: return rc
    rc = emitc_run_compiler_test_suite(ctx, with_roundtrip, "with-roundtrip")
    if rc != 0: return rc
    rc = emitc_build_with_compiler(ctx, with_roundtrip, "out/gen/main.w", with_rebuilt_by_roundtrip, "build-compiler-with-roundtrip")
    if rc != 0: return rc
    rc = emitc_compare_files(ctx, compiler_path, with_rebuilt_by_roundtrip)
    if rc != 0:
        ctx.diagnostics().error("EMIT-C ROUNDTRIP SELFHOST DIVERGED")
        return rc
    if fs.mkdir_all(emitc_dirname(stamp_path)) != 0:
        return emitc_fail(ctx, "could not create stamp directory")
    if fs.write_text(stamp_path, "ok\n") != 0:
        return emitc_fail(ctx, "could not write stamp: " ++ stamp_path)
    print("EMIT-C ROUNDTRIP OK")
    0
