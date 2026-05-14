// BuildGraphRuntime -- repository runtime-generation support for build.w.

extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_is_dir(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_tree(path: str) -> i32
extern fn with_fs_rename_file(old_path: str, new_path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getpid() -> i32
extern fn with_clock_nanos() -> i64
extern fn with_write(s: str) -> void
extern fn with_eprint(s: str) -> void

pub fn build_graph_rt_exec_argv(args: str) -> i32:
    with_exec_argv(args)

pub fn build_graph_rt_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    with_exec_argv_capture(args, stdout_path, stderr_path, timeout_ms)

pub fn build_graph_rt_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32:
    with_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, cwd)

pub fn build_graph_rt_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32:
    with_exec_argv_capture_spawn(args, stdout_path, stderr_path)

pub fn build_graph_rt_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    with_exec_wait(pid, timeout_ms)

pub fn build_graph_rt_getenv(name: str) -> str:
    with_getenv_str(name)

pub fn build_graph_rt_setenv(name: str, value: str) -> i32:
    with_setenv_str(name, value)

pub fn build_graph_rt_file_exists(path: str) -> i32:
    with_fs_file_exists(path)

pub fn build_graph_rt_is_dir(path: str) -> i32:
    with_fs_is_dir(path)

pub fn build_graph_rt_mkdir_p(path: str) -> i32:
    with_fs_mkdir_p(path)

pub fn build_graph_rt_read_file(path: str) -> str:
    with_fs_read_file(path)

pub fn build_graph_rt_remove_file(path: str) -> i32:
    with_fs_remove_file(path)

pub fn build_graph_rt_remove_dir(path: str) -> i32:
    with_fs_remove_dir(path)

pub fn build_graph_rt_remove_tree(path: str) -> i32:
    with_fs_remove_tree(path)

pub fn build_graph_rt_rename_file(old_path: str, new_path: str) -> i32:
    with_fs_rename_file(old_path, new_path)

pub fn build_graph_rt_write_file(path: str, data: str) -> i32:
    with_fs_write_file(path, data)

pub fn build_graph_rt_chmod(path: str, mode: i32) -> i32:
    with_fs_chmod(path, mode)

pub fn build_graph_rt_getpid() -> i32:
    with_getpid()

pub fn build_graph_rt_clock_nanos() -> i64:
    with_clock_nanos()

pub fn build_graph_rt_write(s: str):
    with_write(s)

pub fn build_graph_rt_eprint(s: str):
    with_eprint(s)

fn bgr_argv_append(argv_blob: str, arg: str) -> str:
    argv_blob ++ arg ++ "\0"

fn bgr_resolve_join(base: str, child: str) -> str:
    if child.len() == 0:
        return base
    if child.byte_at(0) == 47:
        return child
    if base.len() == 0 or base.ends_with("/"):
        return base ++ child
    base ++ "/" ++ child

fn bgr_dirname(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

fn bgr_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn bgr_str_compare(a: str, b: str) -> i32:
    let n = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < n as i32:
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

fn bgr_sorted_paths(files: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and bgr_str_compare(path, existing) < 0:
                out.push(path)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(path)
        sorted = out
    sorted

fn bgr_collect_stdlib_files(root: str, target_name: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    let tmp_dir = bgr_resolve_join(root, "out/tmp")
    if with_fs_mkdir_p(tmp_dir) != 0:
        return files
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let manifest_path = bgr_resolve_join(tmp_dir, "stdlib-files." ++ stamp ++ ".txt")
    let err_path = manifest_path ++ ".stderr"
    let std_root = bgr_resolve_join(root, "lib/std")
    var argv = ""
    argv = bgr_argv_append(argv, "/usr/bin/find")
    argv = bgr_argv_append(argv, std_root)
    argv = bgr_argv_append(argv, "-type")
    argv = bgr_argv_append(argv, "f")
    argv = bgr_argv_append(argv, "-name")
    argv = bgr_argv_append(argv, "*.w")
    let rc = with_exec_argv_capture(argv, manifest_path, err_path, 60000)
    if rc != 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' could not list stdlib files; stderr=" ++ err_path)
        return files
    let listing = with_fs_read_file(manifest_path)
    let _remove_manifest = with_fs_remove_file(manifest_path)
    let _remove_err = with_fs_remove_file(err_path)
    let all_files = bgr_sorted_paths(bgr_split_nonempty_lines(listing))
    let re_prefix = bgr_resolve_join(root, "lib/std/re/")
    for i in 0..all_files.len() as i32:
        let path = all_files.get(i as i64)
        if not path.starts_with(re_prefix):
            files.push(path)
    files

fn bgr_contains_delimiter(text: str, hashes: str) -> bool:
    let needle = "\"" ++ hashes
    if text.len() < needle.len():
        return false
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
            return true
        i = i + 1
    false

fn bgr_raw_string_literal(text: str) -> str:
    var hashes = ""
    while bgr_contains_delimiter(text, hashes):
        hashes = hashes ++ "#"
    "r" ++ hashes ++ "\"" ++ text ++ "\"" ++ hashes

fn bgr_embedded_rel_path(root: str, path: str) -> str:
    let root_lib = bgr_resolve_join(root, "lib/")
    if path.starts_with(root_lib):
        return path.slice(root_lib.len(), path.len())
    if path.starts_with("lib/"):
        return path.slice(4, path.len())
    path

fn bgr_generate_embedded_stdlib(root: str, target_name: str, files: Vec[str]) -> str:
    var out = "// Auto-generated by with build generate_compat_runtime.\n"
    out = out ++ "// Do not edit by hand.\n\n"
    var listing = ""
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let rel = bgr_embedded_rel_path(root, path)
        let source = with_fs_read_file(path)
        if source.len() == 0:
            with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' failed to read stdlib source: " ++ path)
            return ""
        if source.len() > 500000:
            with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' stdlib source too large: " ++ path)
            return ""
        let sym = f"EMBEDDED_STD_{i}"
        out = out ++ "let " ++ sym ++ ": str = " ++ bgr_raw_string_literal(source) ++ "\n"
        if listing.len() > 0:
            listing = listing ++ "\n"
        listing = listing ++ rel
    out = out ++ "let EMBEDDED_STD_MODULE_LIST: str = " ++ bgr_raw_string_literal(listing) ++ "\n\n"
    out = out ++ "pub fn embedded_std_source_data(path: str) -> str:\n"
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let rel = bgr_embedded_rel_path(root, path)
        let sym = f"EMBEDDED_STD_{i}"
        out = out ++ "    if path == " ++ bgr_raw_string_literal(rel) ++ ":\n"
        out = out ++ "        return " ++ sym ++ "\n"
    out = out ++ "    return \"\"\n\n"
    out = out ++ "pub fn embedded_std_list_modules_data() -> str:\n"
    out = out ++ "    return EMBEDDED_STD_MODULE_LIST\n"
    out

pub fn run_generate_compat_runtime(root: str, target_name: str, compat_source_rel: str, output_rel: str) -> i32:
    if compat_source_rel.len() == 0 or output_rel.len() == 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' requires source and output paths")
        return 1
    let compat_source = bgr_resolve_join(root, compat_source_rel)
    if with_fs_file_exists(compat_source) == 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' missing source: " ++ compat_source)
        return 1
    let files = bgr_collect_stdlib_files(root, target_name)
    if files.len() == 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' found no stdlib sources")
        return 1
    let embedded = bgr_generate_embedded_stdlib(root, target_name, files)
    if embedded.len() == 0:
        return 1
    let output_path = bgr_resolve_join(root, output_rel)
    let output_dir = bgr_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' could not create output directory: " ++ output_dir)
        return 1
    let compat_text = with_fs_read_file(compat_source)
    if compat_text.len() == 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' could not read source: " ++ compat_source)
        return 1
    let embedded_path = bgr_resolve_join(root, "out/gen/compiler/EmbeddedStdlibData.w")
    let embedded_dir = bgr_dirname(embedded_path)
    if with_fs_mkdir_p(embedded_dir) != 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' could not create output directory: " ++ embedded_dir)
        return 1
    if with_fs_write_file(embedded_path, embedded) != 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' could not write: " ++ embedded_path)
        return 1
    if with_fs_write_file(output_path, compat_text) != 0:
        with_eprint("error: generate_compat_runtime target '" ++ target_name ++ "' could not write: " ++ output_path)
        return 1
    0
