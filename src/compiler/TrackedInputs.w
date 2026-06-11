use compiler.Runtime

pub type TrackedReadResult {
    ok: bool,
    resolved_path: str,
    contents: str,
    error_msg: str,
}

fn tracked_read_ok(path: str, contents: str) -> TrackedReadResult:
    TrackedReadResult { true, path, contents, "" }

fn tracked_read_error(path: str, msg: str) -> TrackedReadResult:
    TrackedReadResult { false, path, "", msg }

pub fn tracked_input_str_compare(a: str, b: str) -> i32:
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

pub fn tracked_input_insert_unique(paths: Vec[str], path: str) -> Vec[str]:
    if path.len() == 0:
        return paths
    var out: Vec[str] = Vec.new()
    var inserted = false
    for i in 0..paths.len() as i32:
        let existing = paths.get(i as i64)
        let cmp = tracked_input_str_compare(path, existing)
        if cmp == 0:
            return paths
        if not inserted and cmp < 0:
            out.push(path)
            inserted = true
        out.push(existing)
    if not inserted:
        out.push(path)
    out

pub fn tracked_input_merge_unique(left: Vec[str], right: &Vec[str]) -> Vec[str]:
    var out = left
    for i in 0..right.len() as i32:
        out = tracked_input_insert_unique(move out, right.get(i as i64))
    out

fn tracked_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return ""
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn tracked_path_is_absolute(path: str) -> bool:
    if path.len() > 0 and path.byte_at(0) == 47:
        return true
    path.len() >= 3 and path.byte_at(1) == 58 and (path.byte_at(2) == 47 or path.byte_at(2) == 92)

fn tracked_path_has_parent_segment(path: str) -> bool:
    path == ".." or path.starts_with("../") or path.starts_with("..\\") or
        path.ends_with("/..") or path.ends_with("\\..") or
        path.contains("/../") or path.contains("\\..\\") or
        path.contains("/..\\") or path.contains("\\../")

fn tracked_resolve_source_relative(source_path: str, raw_path: str) -> str:
    if tracked_path_is_absolute(raw_path):
        return raw_path
    let dir = tracked_dirname(source_path)
    if dir.len() == 0:
        return raw_path
    dir ++ "/" ++ raw_path

fn tracked_inside_root(path: str, root: str) -> bool:
    if root.len() == 0:
        return true
    if path == root:
        return true
    let prefix = if root.ends_with("/"): root else: root ++ "/"
    path.starts_with(prefix)

fn tracked_authorized_root(source_path: str, package_root: str) -> str:
    if package_root.len() > 0:
        return package_root
    let dir = tracked_dirname(source_path)
    if dir.len() == 0:
        return ""
    dir

pub fn tracked_embed_resolve(source_path: str, raw_path: str) -> str:
    tracked_resolve_source_relative(source_path, raw_path)

pub fn tracked_embed_read(source_path: str, raw_path: str, package_root: str) -> TrackedReadResult:
    let resolved = tracked_embed_resolve(source_path, raw_path)
    let root = tracked_authorized_root(source_path, package_root)
    if tracked_path_has_parent_segment(raw_path):
        let display_root = if root.len() > 0: root else: tracked_dirname(source_path)
        return tracked_read_error(resolved, "embed_file: '" ++ resolved ++ "' is outside the package root '" ++ display_root ++ "'; embed_file reads only tracked inputs inside the package (broader access requires an explicit build capability)")
    if root.len() > 0 and not tracked_inside_root(resolved, root):
        return tracked_read_error(resolved, "embed_file: '" ++ resolved ++ "' is outside the package root '" ++ root ++ "'; embed_file reads only tracked inputs inside the package (broader access requires an explicit build capability)")
    if runtime_file_exists(resolved) == 0:
        return tracked_read_error(resolved, "embed_file: could not read '" ++ resolved ++ "'")
    tracked_read_ok(resolved, runtime_read_file(resolved))
