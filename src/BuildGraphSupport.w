// BuildGraphSupport -- path and argv helpers shared by build graph execution.

use Resolve
use BuildGraphModel

extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_eprint(s: str) -> void

pub fn build_graph_output_path(root: str, target: BuildGraphTarget, output_path: str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return output_path
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/bin"), target.name)

pub fn build_graph_library_output_path(root: str, target: BuildGraphTarget, output_path: str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return output_path
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/lib"), "lib" ++ target.name ++ ".a")

pub fn build_graph_resolve_project_path(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    resolve_join(root, path)

pub fn build_graph_resolve_paths(root: str, paths: Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..paths.len() as i32:
        out.push(build_graph_resolve_project_path(root, paths.get(i as i64)))
    out

pub fn build_graph_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

pub fn build_graph_path_basename(path: str) -> str:
    let dir = build_graph_dirname(path)
    if dir == ".":
        return path
    path.slice((dir.len() + 1) as i64, path.len())

pub fn build_graph_path_has_glob(path: str) -> bool:
    with_str_contains(path, "*") != 0

pub fn build_graph_single_star_pattern_matches(pattern: str, name: str) -> bool:
    var star = -1
    for i in 0..pattern.len() as i32:
        if pattern.byte_at(i as i64) == 42:
            if star >= 0:
                return false
            star = i
    if star < 0:
        return pattern == name
    let prefix = pattern.slice(0, star as i64)
    let suffix = pattern.slice((star + 1) as i64, pattern.len())
    if name.len() < prefix.len() + suffix.len():
        return false
    if prefix.len() > 0 and name.slice(0, prefix.len()) != prefix:
        return false
    if suffix.len() > 0:
        let suffix_start = name.len() - suffix.len()
        if name.slice(suffix_start, name.len()) != suffix:
            return false
    true

pub fn build_graph_path_for_child_process(root: str, path: str) -> str:
    var normalized_root = root
    while normalized_root.len() > 1 and normalized_root.ends_with("/"):
        normalized_root = normalized_root.slice(0, normalized_root.len() - 1)
    if normalized_root.ends_with("/."):
        normalized_root = normalized_root.slice(0, normalized_root.len() - 2)
    let dot_prefix = normalized_root ++ "/./"
    if with_str_starts_with(path, dot_prefix) != 0:
        return path.slice(dot_prefix.len(), path.len())
    let prefix = normalized_root ++ "/"
    if with_str_starts_with(path, prefix) != 0:
        return path.slice(prefix.len(), path.len())
    path

pub fn build_graph_generated_path_valid(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if with_str_contains(path, "..") != 0:
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 10 or ch == 13 or ch == 9:
            return false
    true

pub fn build_graph_manifest_relative_path_valid(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if with_str_contains(path, "..") != 0:
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 0 or ch == 10 or ch == 13 or ch == 9:
            return false
    true

pub fn build_graph_define_valid(define: str) -> bool:
    if define.len() == 0:
        return false
    for i in 0..define.len() as i32:
        let ch = define.byte_at(i as i64)
        if ch == 10 or ch == 13:
            return false
    true

pub fn build_graph_process_arg_valid(arg: str) -> bool:
    for i in 0..arg.len() as i32:
        if arg.byte_at(i as i64) == 0:
            return false
    true

pub fn build_graph_argv_append(argv_blob: str, arg: str) -> str:
    argv_blob ++ arg ++ "\0"

pub fn build_graph_exec_argv(target: BuildGraphTarget, operation_name: str, argv_blob: str) -> i32:
    let rc = with_exec_argv(argv_blob)
    if rc != 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ f"' failed with exit code {rc}")
        return if rc == 0: 1 else: rc
    0

pub fn build_graph_validate_process_args(target: BuildGraphTarget) -> i32:
    if not build_graph_process_arg_valid(target.entry):
        with_eprint("error: build.w target '" ++ target.name ++ "' entry contains a NUL byte")
        return 1
    if not build_graph_process_arg_valid(target.output):
        with_eprint("error: build.w target '" ++ target.name ++ "' output contains a NUL byte")
        return 1
    for ii in 0..target.inputs.len() as i32:
        if not build_graph_process_arg_valid(target.inputs.get(ii as i64)):
            with_eprint("error: build.w target '" ++ target.name ++ "' input contains a NUL byte")
            return 1
    for ai in 0..target.args.len() as i32:
        if not build_graph_process_arg_valid(target.args.get(ai as i64)):
            with_eprint("error: build.w target '" ++ target.name ++ "' arg contains a NUL byte")
            return 1
    0
