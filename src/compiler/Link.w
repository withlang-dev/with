extern fn with_system(cmd: str) -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_eprint(s: str) -> void
extern fn with_getenv_str(name: str) -> str

extern let with_embedded_helpers_o_start: u8
extern let with_embedded_helpers_o_end: u8
extern let with_embedded_compat_runtime_o_start: u8
extern let with_embedded_compat_runtime_o_end: u8
extern let with_embedded_panic_runtime_o_start: u8
extern let with_embedded_panic_runtime_o_end: u8
extern let with_embedded_fiber_stubs_o_start: u8
extern let with_embedded_fiber_stubs_o_end: u8
extern let with_embedded_channel_runtime_o_start: u8
extern let with_embedded_channel_runtime_o_end: u8
extern let with_embedded_fiber_o_start: u8
extern let with_embedded_fiber_o_end: u8
extern let with_embedded_fiber_asm_o_start: u8
extern let with_embedded_fiber_asm_o_end: u8
extern let with_embedded_rt_core_o_start: u8
extern let with_embedded_rt_core_o_end: u8
extern let with_embedded_rt_darwin_aarch64_o_start: u8
extern let with_embedded_rt_darwin_aarch64_o_end: u8

fn link_stage_str_from_raw_parts(ptr: *const u8, len: i64) -> str:
    if ptr as i64 == 0 or len <= 0:
        return ""
    var out: str = ""
    unsafe:
        let sp = &mut out as *mut u8
        *(sp as *mut u64) = ptr as u64
        *((sp + 8u64) as *mut i64) = len
    out

fn link_stage_embedded_obj_slice(start: *const u8, end: *const u8) -> str:
    let len = end as i64 - start as i64
    if len <= 0:
        return ""
    link_stage_str_from_raw_parts(start, len)

fn link_stage_embedded_runtime_object(name: str) -> str:
    if name == "helpers.o":
        return link_stage_embedded_obj_slice(&with_embedded_helpers_o_start as *const u8, &with_embedded_helpers_o_end as *const u8)
    if name == "compat_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_compat_runtime_o_start as *const u8, &with_embedded_compat_runtime_o_end as *const u8)
    if name == "panic_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_panic_runtime_o_start as *const u8, &with_embedded_panic_runtime_o_end as *const u8)
    if name == "fiber_stubs.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_stubs_o_start as *const u8, &with_embedded_fiber_stubs_o_end as *const u8)
    if name == "channel_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_channel_runtime_o_start as *const u8, &with_embedded_channel_runtime_o_end as *const u8)
    if name == "fiber.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_o_start as *const u8, &with_embedded_fiber_o_end as *const u8)
    if name == "fiber_asm.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_asm_o_start as *const u8, &with_embedded_fiber_asm_o_end as *const u8)
    if name == "rt_core.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_core_o_start as *const u8, &with_embedded_rt_core_o_end as *const u8)
    if name == "rt_darwin_aarch64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_darwin_aarch64_o_start as *const u8, &with_embedded_rt_darwin_aarch64_o_end as *const u8)
    ""

fn link_stage_extract_runtime_obj(name: str, path: str) -> i32:
    let data = link_stage_embedded_runtime_object(name)
    if data.len() == 0:
        return 1
    if with_fs_write_file(path, data) != 0:
        return 1
    0

fn link_stage_link(obj_path: str, bin_path: str) -> bool:
    let extras: Vec[str] = Vec.new()
    let link_libs: Vec[str] = Vec.new()
    link_stage_link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)

fn link_stage_link_with_extras(obj_path: str, bin_path: str, extras: Vec[str]) -> bool:
    let link_libs: Vec[str] = Vec.new()
    link_stage_link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)

fn link_stage_link_with_extras_and_libs(obj_path: str, bin_path: str, extras: Vec[str], link_libs: Vec[str]) -> bool:
    var cmd = "cc " ++ obj_path
    for i in 0..extras.len() as i32:
        cmd = cmd ++ " " ++ extras.get(i as i64)
    cmd = cmd ++ " -Wl,-dead_strip -o " ++ bin_path
    for i in 0..link_libs.len() as i32:
        cmd = cmd ++ " -l" ++ link_libs.get(i as i64)
    let result = cmd |> with_system
    result == 0

fn link_stage_link_with_llvm(obj_path: str, bin_path: str, extras: Vec[str], link_libs: Vec[str], llvm_cc: str) -> bool:
    var cmd = llvm_cc ++ " -fuse-ld=lld " ++ obj_path
    for i in 0..extras.len() as i32:
        cmd = cmd ++ " " ++ extras.get(i as i64)
    cmd = cmd ++ " -Wl,-dead_strip -o " ++ bin_path
    for i in 0..link_libs.len() as i32:
        cmd = cmd ++ " -l" ++ link_libs.get(i as i64)
    let result = cmd |> with_system
    result == 0

fn link_stage_str_contains(hay: str, needle: str) -> bool:
    let hay_len = hay.len() as i32
    let needle_len = needle.len() as i32
    if needle_len <= 0:
        return true
    if hay_len < needle_len:
        return false

    var i = 0
    while i <= hay_len - needle_len:
        var matched = true
        var j = 0
        while j < needle_len:
            if hay.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
            j = j + 1
        if matched:
            return true
        i = i + 1
    false

fn link_stage_undefined_symbols_for_object(obj_path: str) -> str:
    let report_path = obj_path ++ ".undef"
    let probe_cmd = "nm -u " ++ obj_path ++ " > " ++ report_path ++ " 2>/dev/null"
    let probe_rc = probe_cmd |> with_system
    if probe_rc != 0:
        let _ = ("rm -f " ++ report_path) |> with_system
        return "<probe-failed>"
    let symbols = with_fs_read_file(report_path)
    let _ = ("rm -f " ++ report_path) |> with_system
    symbols

fn link_stage_object_needs_helpers_runtime(obj_path: str) -> i32:
    let undef = link_stage_undefined_symbols_for_object(obj_path)
    if undef == "<probe-failed>":
        return 1
    if undef.len() == 0:
        return 0
    if link_stage_str_contains(undef, "_with_"):
        return 1
    if link_stage_str_contains(undef, "_int_to_string"):
        return 1
    if link_stage_str_contains(undef, "_i32_to_str"):
        return 1
    if link_stage_str_contains(undef, "_str_from_byte"):
        return 1
    0

fn link_stage_object_needs_fiber_runtime(obj_path: str) -> i32:
    let undef = link_stage_undefined_symbols_for_object(obj_path)
    if undef == "<probe-failed>":
        return 0
    if undef.len() == 0:
        return 0
    if link_stage_str_contains(undef, "_with_channel_"):
        return 1
    if link_stage_str_contains(undef, "_with_fiber_"):
        return 1
    0

fn link_stage_compiler_runtime_dir() -> str:
    let argv0 = with_arg_at(0)
    if argv0.len() == 0:
        return "runtime"
    link_stage_dirname(argv0) ++ "/runtime"

fn link_stage_resolve_runtime_root() -> str:
    let argv0 = with_arg_at(0)
    let compiler_dir = if argv0.len() > 0: link_stage_dirname(argv0) else: "."
    let candidates: Vec[str] = Vec.new()
    // Prefer the current workspace artifact root during bootstrap. This lets
    // external seed compilers link against the runtime objects generated for
    // the active tree instead of whatever stdlib/runtime payload the seed
    // binary happens to carry.
    candidates.push(link_stage_artifact_root() ++ "/lib")
    // <compiler_dir>/runtime/ (symlink to ../lib in out/bin/)
    candidates.push(compiler_dir ++ "/runtime")
    // <compiler_dir>/../lib/ (direct FHS-style path)
    candidates.push(compiler_dir ++ "/../lib")
    for i in 0..candidates.len() as i32:
        let dir = candidates.get(i as i64)
        let probe = dir ++ "/helpers.o"
        if with_fs_read_file(probe).len() > 0:
            return dir
    // Fall back to compiler-relative runtime dir.
    compiler_dir ++ "/runtime"

fn link_stage_find_llvm_static_bridge() -> str:
    let root = link_stage_resolve_runtime_root()
    let bridge_o = root ++ "/llvm_bridge.o"
    let rsp = root ++ "/llvm_link.rsp"
    let cc_file = root ++ "/llvm_cc"
    if with_fs_read_file(bridge_o).len() > 0 and with_fs_read_file(rsp).len() > 0 and with_fs_read_file(cc_file).len() > 0:
        return bridge_o
    ""

fn link_stage_read_file_trimmed(path: str) -> str:
    let content = with_fs_read_file(path)
    if content.len() == 0:
        return ""
    // Trim trailing newline
    var end = content.len() as i32
    while end > 0 and content.byte_at((end - 1) as i64) == 10:
        end = end - 1
    content.slice(0, end as i64)

fn link_stage_artifact_root() -> str:
    let env_root = with_getenv_str("WITH_OUT_DIR")
    if env_root.len() > 0:
        return env_root
    "out"

fn link_stage_find_runtime_object_path(name: str) -> str:
    let root = link_stage_resolve_runtime_root()
    let p = root ++ "/" ++ name
    if with_fs_read_file(p).len() > 0:
        return p
    // Fall back to embedded runtime objects (self-contained binary)
    let tmp_dir = link_stage_artifact_root() ++ "/tmp/with_runtime"
    let _ = ("mkdir -p " ++ tmp_dir) |> with_system
    let tmp_path = tmp_dir ++ "/" ++ name
    if link_stage_extract_runtime_obj(name, tmp_path) == 0:
        return tmp_path
    ""

fn link_stage_make_archive(obj_path: str) -> str:
    // Wrap a .o file in a .a archive so the linker treats it as a library
    // (only pulling in symbols that aren't already defined).
    let ar_path = obj_path ++ ".a"
    let cmd = "ar rcs " ++ ar_path ++ " " ++ obj_path
    let rc = with_system(cmd)
    if rc == 0:
        return ar_path
    ""

fn link_stage_should_use_rt_core(obj_path: str) -> bool:
    // Use the libc-free runtime for user programs that don't need LLVM bridge
    // or c_import. The compiler itself (which needs wl_* symbols) always uses
    // the libc-backed helpers.o runtime.
    let undef = link_stage_undefined_symbols_for_object(obj_path)
    if undef == "<probe-failed>":
        return false
    // If it needs LLVM bridge, it's the compiler — use libc runtime
    if link_stage_str_contains(undef, "_wl_"):
        return false
    // If it uses c_import symbols or libc functions directly, use libc runtime
    if link_stage_str_contains(undef, "_fopen"):
        return false
    if link_stage_str_contains(undef, "_fwrite"):
        return false
    if link_stage_str_contains(undef, "_printf"):
        return false
    if link_stage_str_contains(undef, "_malloc"):
        return false
    if link_stage_str_contains(undef, "_fclose"):
        return false
    // Check if it needs with_* symbols (which we provide in rt_core)
    if link_stage_str_contains(undef, "_with_"):
        return true
    false

fn link_stage_object_needs_llvm_bridge(obj_path: str) -> bool:
    let probe = "nm -u " ++ obj_path ++ " 2>/dev/null | grep -q '_wl_'"
    (probe |> with_system) == 0

fn link_stage_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47: // '/'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

fn link_stage_source_stem(source_path: str) -> str:
    var last_slash = -1
    for i in 0..source_path.len():
        if source_path[i] == 47: // '/'
            last_slash = i as i32
    let base = if last_slash >= 0:
        source_path.slice((last_slash + 1) as i64, source_path.len() as i64)
    else:
        source_path
    if base.len() > 2 and base.ends_with(".w"):
        return base.slice(0, (base.len() - 2) as i64)
    base

fn link_stage_sanitize_relative_dir(path: str) -> str:
    var out = ""
    var segment_start = 0
    var i = 0
    while i <= path.len():
        let at_end = i == path.len()
        let ch = if at_end: 47 else: path.byte_at(i as i64)
        if ch == 47:
            if i > segment_start:
                let segment = path.slice(segment_start as i64, i as i64)
                if segment != ".":
                    if out.len() > 0:
                        out = out ++ "/"
                    if segment == "..":
                        out = out ++ "__up__"
                    else:
                        out = out ++ segment
            segment_start = i + 1
        i = i + 1
    out

fn link_stage_output_dir_for_source(source_path: str) -> str:
    let artifact_root = link_stage_artifact_root()
    let dir = link_stage_sanitize_relative_dir(link_stage_dirname(source_path))
    if dir.len() == 0:
        return artifact_root
    artifact_root ++ "/" ++ dir

fn link_stage_output_path_for_source(source_path: str) -> str:
    link_stage_output_dir_for_source(source_path) ++ "/" ++ link_stage_source_stem(source_path)

fn link_stage_link_object_to_binary(obj_path: str, bin_path: str, link_libs: Vec[str], link_search_paths: Vec[str], needs_async_runtime: bool) -> bool:
    let extras: Vec[str] = Vec.new()
    for i in 0..link_search_paths.len() as i32:
        extras.push("-L" ++ link_search_paths.get(i as i64))
    let needs_fiber_runtime = if needs_async_runtime: 1 else: link_stage_object_needs_fiber_runtime(obj_path)
    if needs_fiber_runtime != 0:
        let channel_runtime_path = link_stage_find_runtime_object_path("channel_runtime.o")
        if channel_runtime_path.len() == 0:
            with_eprint("error: missing runtime/channel_runtime.o")
            return false
        extras.push(channel_runtime_path)
        let fiber_path = link_stage_find_runtime_object_path("fiber.o")
        if fiber_path.len() == 0:
            with_eprint("error: missing runtime/fiber.o")
            return false
        extras.push(fiber_path)
        let fiber_asm_path = link_stage_find_runtime_object_path("fiber_asm.o")
        if fiber_asm_path.len() == 0:
            with_eprint("error: missing runtime/fiber_asm.o")
            return false
        extras.push(fiber_asm_path)

    let needs_helpers_runtime = link_stage_object_needs_helpers_runtime(obj_path)
    if needs_helpers_runtime != 0:
        let use_rt_core = link_stage_should_use_rt_core(obj_path)
        let needs_llvm = link_stage_object_needs_llvm_bridge(obj_path)
        if use_rt_core:
            // Pure With program — rt_core.o + platform backend + panic runtime.
            // Non-async builds also link fiber_stubs.o for lifecycle and fiber
            // fallback symbols; async builds bring fiber.o instead.
            let rt_core_path = link_stage_find_runtime_object_path("rt_core.o")
            if rt_core_path.len() == 0:
                with_eprint("error: missing rt_core.o")
                return false
            extras.push(rt_core_path)
            let rt_platform_path = link_stage_find_runtime_object_path("rt_darwin_aarch64.o")
            if rt_platform_path.len() == 0:
                with_eprint("error: missing rt_darwin_aarch64.o")
                return false
            extras.push(rt_platform_path)
            let panic_rt_path = link_stage_find_runtime_object_path("panic_runtime.o")
            if panic_rt_path.len() == 0:
                with_eprint("error: missing runtime/panic_runtime.o")
                return false
            let panic_ar = link_stage_make_archive(panic_rt_path)
            extras.push(if panic_ar.len() > 0: panic_ar else: panic_rt_path)
            if needs_fiber_runtime == 0:
                let fiber_stubs_path = link_stage_find_runtime_object_path("fiber_stubs.o")
                if fiber_stubs_path.len() == 0:
                    with_eprint("error: missing runtime/fiber_stubs.o")
                    return false
                let fiber_stubs_ar = link_stage_make_archive(fiber_stubs_path)
                extras.push(if fiber_stubs_ar.len() > 0: fiber_stubs_ar else: fiber_stubs_path)
        else if needs_llvm:
            // Compiler build (lld path) — helpers.o + panic runtime, plus
            // non-async fiber stubs when fiber.o is absent. rt_core.o stays out
            // because helpers.o provides the compiler runtime surface.
            let compat_runtime_path = link_stage_find_runtime_object_path("compat_runtime.o")
            if compat_runtime_path.len() == 0:
                with_eprint("error: missing runtime/compat_runtime.o")
                return false
            extras.push(compat_runtime_path)
            let panic_runtime_path = link_stage_find_runtime_object_path("panic_runtime.o")
            if panic_runtime_path.len() == 0:
                with_eprint("error: missing runtime/panic_runtime.o")
                return false
            extras.push(panic_runtime_path)
            if needs_fiber_runtime == 0:
                let fiber_stubs_path = link_stage_find_runtime_object_path("fiber_stubs.o")
                if fiber_stubs_path.len() == 0:
                    with_eprint("error: missing runtime/fiber_stubs.o")
                    return false
                extras.push(fiber_stubs_path)
            let helpers_path = link_stage_find_runtime_object_path("helpers.o")
            if helpers_path.len() == 0:
                with_eprint("error: missing runtime/helpers.o")
                return false
            extras.push(helpers_path)
        else:
            // User program with c_import (cc/Apple ld64 path) — rt_core.o first,
            // then helpers as archive. Apple's ld64 resolves archives correctly:
            // rt_core.o definitions win, helpers.a fills in C-only symbols.
            let rt_core_path = link_stage_find_runtime_object_path("rt_core.o")
            if rt_core_path.len() == 0:
                with_eprint("error: missing rt_core.o")
                return false
            extras.push(rt_core_path)
            let rt_platform_path = link_stage_find_runtime_object_path("rt_darwin_aarch64.o")
            if rt_platform_path.len() == 0:
                with_eprint("error: missing rt_darwin_aarch64.o")
                return false
            extras.push(rt_platform_path)
            let panic_runtime_path = link_stage_find_runtime_object_path("panic_runtime.o")
            if panic_runtime_path.len() == 0:
                with_eprint("error: missing runtime/panic_runtime.o")
                return false
            let panic_ar = link_stage_make_archive(panic_runtime_path)
            extras.push(if panic_ar.len() > 0: panic_ar else: panic_runtime_path)
            if needs_fiber_runtime == 0:
                let fiber_stubs_path = link_stage_find_runtime_object_path("fiber_stubs.o")
                if fiber_stubs_path.len() == 0:
                    with_eprint("error: missing runtime/fiber_stubs.o")
                    return false
                let fiber_stubs_ar = link_stage_make_archive(fiber_stubs_path)
                extras.push(if fiber_stubs_ar.len() > 0: fiber_stubs_ar else: fiber_stubs_path)
            let helpers_path = link_stage_find_runtime_object_path("helpers.o")
            if helpers_path.len() == 0:
                with_eprint("error: missing runtime/helpers.o")
                return false
            let helpers_ar = link_stage_make_archive(helpers_path)
            extras.push(if helpers_ar.len() > 0: helpers_ar else: helpers_path)

    // Link libcurl when HTTP functions are used (package management)
    let undef_syms = link_stage_undefined_symbols_for_object(obj_path)
    if link_stage_str_contains(undef_syms, "_with_http_") or link_stage_str_contains(undef_syms, "_curl_"):
        link_libs.push("curl")

    if link_stage_object_needs_llvm_bridge(obj_path):
        let static_bridge = link_stage_find_llvm_static_bridge()
        if static_bridge.len() > 0:
            // Static LLVM linking: use llvm_bridge.o + LLVM static libs
            let root = link_stage_resolve_runtime_root()
            let rsp_path = root ++ "/llvm_link.rsp"
            let cc_path = link_stage_read_file_trimmed(root ++ "/llvm_cc")
            extras.push(static_bridge)
            // Include embedded runtime objects for self-contained binary
            let embedded_path = root ++ "/embedded_objects.o"
            if with_fs_read_file(embedded_path).len() > 0:
                extras.push(embedded_path)
            // Include clang bridge for c_import support
            let clang_bridge_path = root ++ "/clang_bridge.o"
            if with_fs_read_file(clang_bridge_path).len() > 0:
                extras.push(clang_bridge_path)
            extras.push("@" ++ rsp_path)
            return link_stage_link_with_llvm(obj_path, bin_path, extras, link_libs, cc_path)
        with_eprint("error: missing LLVM static bridge (need llvm_bridge.o + llvm_link.rsp + llvm_cc)")
        return false

    if extras.len() == 0 and link_libs.len() == 0:
        return link_stage_link(obj_path, bin_path)
    link_stage_link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)
