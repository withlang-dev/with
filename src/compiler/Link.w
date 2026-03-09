extern fn with_system(cmd: str) -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_read_file(path: str) -> str
extern fn with_eprintln(s: str) -> void

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
    cmd = cmd ++ " -o " ++ bin_path
    for i in 0..link_libs.len() as i32:
        cmd = cmd ++ " -l" ++ link_libs.get(i as i64)
    let result = cmd |> with_system
    result == 0

fn link_stage_link_with_llvm(obj_path: str, bin_path: str, extras: Vec[str], link_libs: Vec[str], llvm_cc: str) -> bool:
    var cmd = llvm_cc ++ " -fuse-ld=lld " ++ obj_path
    for i in 0..extras.len() as i32:
        cmd = cmd ++ " " ++ extras.get(i as i64)
    cmd = cmd ++ " -o " ++ bin_path
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
    // <compiler_dir>/runtime/ (symlink to ../lib in out/bin/)
    candidates.push(compiler_dir ++ "/runtime")
    // <compiler_dir>/../lib/ (direct FHS-style path)
    candidates.push(compiler_dir ++ "/../lib")
    // out/lib/ (from repo root)
    candidates.push("out/lib")
    for i in 0..candidates.len() as i32:
        let dir = candidates.get(i as i64)
        let probe = dir ++ "/helpers.o"
        if with_fs_read_file(probe).len() > 0:
            return dir
    // Fall back to compiler-relative runtime dir.
    compiler_dir ++ "/runtime"

fn link_stage_find_llvm_bridge_path() -> str:
    let root = link_stage_resolve_runtime_root()
    let p = root ++ "/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p).len() > 0:
        return p
    ""

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

fn link_stage_find_runtime_object_path(name: str) -> str:
    let root = link_stage_resolve_runtime_root()
    let p = root ++ "/" ++ name
    if with_fs_read_file(p).len() > 0:
        return p
    ""

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

fn link_stage_link_object_to_binary(obj_path: str, bin_path: str, link_libs: Vec[str], needs_async_runtime: bool) -> bool:
    let extras: Vec[str] = Vec.new()
    let needs_fiber_runtime = if needs_async_runtime: 1 else: link_stage_object_needs_fiber_runtime(obj_path)
    if needs_fiber_runtime != 0:
        let fiber_path = link_stage_find_runtime_object_path("fiber.o")
        if fiber_path.len() == 0:
            with_eprintln("error: missing runtime/fiber.o")
            return false
        extras.push(fiber_path)
        let fiber_asm_path = link_stage_find_runtime_object_path("fiber_asm.o")
        if fiber_asm_path.len() == 0:
            with_eprintln("error: missing runtime/fiber_asm.o")
            return false
        extras.push(fiber_asm_path)

    let needs_helpers_runtime = link_stage_object_needs_helpers_runtime(obj_path)
    if needs_helpers_runtime != 0:
        let support_runtime_path = link_stage_find_runtime_object_path("support_runtime.o")
        if support_runtime_path.len() == 0:
            with_eprintln("error: missing runtime/support_runtime.o")
            return false
        extras.push(support_runtime_path)
        let helpers_path = link_stage_find_runtime_object_path("helpers.o")
        if helpers_path.len() == 0:
            with_eprintln("error: missing runtime/helpers.o")
            return false
        extras.push(helpers_path)

    if link_stage_object_needs_llvm_bridge(obj_path):
        let static_bridge = link_stage_find_llvm_static_bridge()
        if static_bridge.len() > 0:
            // Static LLVM linking: use llvm_bridge.o + LLVM static libs
            let root = link_stage_resolve_runtime_root()
            let rsp_path = root ++ "/llvm_link.rsp"
            let cc_path = link_stage_read_file_trimmed(root ++ "/llvm_cc")
            extras.push(static_bridge)
            extras.push("@" ++ rsp_path)
            return link_stage_link_with_llvm(obj_path, bin_path, extras, link_libs, cc_path)
        let bridge_path = link_stage_find_llvm_bridge_path()
        if bridge_path.len() == 0:
            with_eprintln("error: missing LLVM bridge (need llvm_bridge.o + llvm_link.rsp + llvm_cc, or libwith_llvm_bridge.dylib)")
            return false
        extras.push(bridge_path)

    if extras.len() == 0 and link_libs.len() == 0:
        return link_stage_link(obj_path, bin_path)
    link_stage_link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)
