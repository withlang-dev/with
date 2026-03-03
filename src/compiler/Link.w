extern fn with_system(cmd: str) -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_read_file(path: str) -> str

fn link_stage_link(obj_path: str, bin_path: str) -> bool:
    let result = ("cc " ++ obj_path ++ " -o " ++ bin_path) |> with_system
    result == 0

fn link_stage_link_with_extras(obj_path: str, bin_path: str, extras: Vec[str]) -> bool:
    var cmd = "cc " ++ obj_path
    for i in 0..extras.len() as i32:
        cmd = cmd ++ " " ++ extras.get(i as i64)
    cmd = cmd ++ " -o " ++ bin_path
    let result = cmd |> with_system
    result == 0

fn link_stage_compiler_runtime_dir() -> str:
    let argv0 = with_arg_at(0)
    if argv0.len() == 0:
        return "runtime"
    link_stage_dirname(argv0) ++ "/runtime"

fn link_stage_find_llvm_bridge_path() -> str:
    let p1 = link_stage_compiler_runtime_dir() ++ "/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p1).len() > 0:
        return p1

    let p2 = "bootstrap/zig-out/bin/runtime/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p2).len() > 0:
        return p2

    let p3 = "runtime/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p3).len() > 0:
        return p3

    ""

fn link_stage_should_link_llvm_bridge(source_path: str) -> bool:
    source_path == "src/main.w" or source_path.ends_with("/src/main.w") or source_path.ends_with("\\src\\main.w")

fn link_stage_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47: // '/'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)
