// BuildGraphSupport -- path and argv helpers shared by build graph execution.

use Resolve
use BuildGraphModel
use BuildGraphRuntime

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
    path.contains("*")

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
    if path.starts_with(dot_prefix):
        return path.slice(dot_prefix.len(), path.len())
    let prefix = normalized_root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    path

pub fn build_graph_generated_path_valid(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if path.contains(".."):
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
    if path.contains(".."):
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
    let rc = build_graph_rt_exec_argv(argv_blob)
    if rc != 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ f"' failed with exit code {rc}")
        return if rc == 0: 1 else: rc
    0

pub fn build_graph_validate_process_args(target: BuildGraphTarget) -> i32:
    if not build_graph_process_arg_valid(target.entry):
        build_graph_rt_eprint("error: build.w target '" ++ target.name ++ "' entry contains a NUL byte")
        return 1
    if not build_graph_process_arg_valid(target.output):
        build_graph_rt_eprint("error: build.w target '" ++ target.name ++ "' output contains a NUL byte")
        return 1
    for ii in 0..target.inputs.len() as i32:
        if not build_graph_process_arg_valid(target.inputs.get(ii as i64)):
            build_graph_rt_eprint("error: build.w target '" ++ target.name ++ "' input contains a NUL byte")
            return 1
    for ai in 0..target.args.len() as i32:
        if not build_graph_process_arg_valid(target.args.get(ai as i64)):
            build_graph_rt_eprint("error: build.w target '" ++ target.name ++ "' arg contains a NUL byte")
            return 1
    0

fn build_graph_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let text_len = text.len() as i32
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text.byte_at(i as i64)
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() as i64 - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn build_graph_str_compare(a: str, b: str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < min_len as i32:
        let ac = a.byte_at(i as i64)
        let bc = b.byte_at(i as i64)
        if ac != bc:
            return ac - bc
        i = i + 1
    if a.len() == b.len():
        return 0
    if a.len() < b.len():
        return -1
    1

fn build_graph_sorted_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and build_graph_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted

pub fn collect_test_files(target_dir: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    if build_graph_rt_mkdir_p("out/tmp") != 0:
        return files
    let stamp = f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let manifest_path = "out/tmp/test-files." ++ stamp ++ ".txt"
    let err_path = manifest_path ++ ".stderr"
    var argv = ""
    argv = build_graph_argv_append(argv, "/usr/bin/find")
    argv = build_graph_argv_append(argv, target_dir)
    argv = build_graph_argv_append(argv, "-maxdepth")
    argv = build_graph_argv_append(argv, "1")
    argv = build_graph_argv_append(argv, "-type")
    argv = build_graph_argv_append(argv, "f")
    argv = build_graph_argv_append(argv, "-name")
    argv = build_graph_argv_append(argv, "*.w")
    let rc = build_graph_rt_exec_argv_capture(argv, manifest_path, err_path, 60000)
    if rc != 0:
        let _remove_manifest_on_error = build_graph_rt_remove_file(manifest_path)
        let _remove_err_on_error = build_graph_rt_remove_file(err_path)
        return files
    let listing = build_graph_rt_read_file(manifest_path)
    let _remove_manifest = build_graph_rt_remove_file(manifest_path)
    let _remove_err = build_graph_rt_remove_file(err_path)
    if listing.len() == 0:
        return files
    build_graph_sorted_strings(build_graph_split_nonempty_lines(listing))
