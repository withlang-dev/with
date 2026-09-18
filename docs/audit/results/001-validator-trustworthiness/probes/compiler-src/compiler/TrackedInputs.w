use compiler.Runtime
extern fn with_str_clone_ref(s: &str) -> str

pub type TrackedReadResult {
    ok: bool,
    resolved_path: str,
    contents: str,
    error_msg: str,
}

fn tracked_read_ok(path: &str, contents: &str) -> TrackedReadResult:
    TrackedReadResult { true, with_str_clone_ref(path), with_str_clone_ref(contents), "" }

fn tracked_read_error(path: &str, msg: &str) -> TrackedReadResult:
    TrackedReadResult { false, with_str_clone_ref(path), "", with_str_clone_ref(msg) }

pub fn tracked_input_str_compare(a: &str, b: &str) -> i32:
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

pub fn tracked_input_insert_unique(paths: Vec[str], path: &str) -> Vec[str]:
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
            out.push(with_str_clone_ref(path))
            inserted = true
        out.push(with_str_clone_ref(existing))
    if not inserted:
        out.push(with_str_clone_ref(path))
    out

pub fn tracked_input_merge_unique(left: Vec[str], right: &Vec[str]) -> Vec[str]:
    var out = left
    for i in 0..right.len() as i32:
        out = tracked_input_insert_unique(move out, right.get(i as i64))
    out

fn tracked_dirname(path: &str) -> str:
    // Separator-agnostic: a native Windows source path is '\'-separated, so a
    // '/'-only split returns "" and the embed target resolves against the cwd
    // instead of the source's directory (#801). Matches the '\'-aware sibling
    // helpers below.
    var last_slash = -1
    for i in 0..path.len() as i32:
        let b = path.byte_at(i as i64)
        if b == 47 or b == 92:
            last_slash = i
    if last_slash < 0:
        return ""
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn tracked_path_is_absolute(path: &str) -> bool:
    if path.len() > 0 and path.byte_at(0) == 47:
        return true
    path.len() >= 3 and path.byte_at(1) == 58 and (path.byte_at(2) == 47 or path.byte_at(2) == 92)

fn tracked_path_has_parent_segment(path: &str) -> bool:
    path == ".." or path.starts_with("../") or path.starts_with("..\\") or
        path.ends_with("/..") or path.ends_with("\\..") or
        path.contains("/../") or path.contains("\\..\\") or
        path.contains("/..\\") or path.contains("\\../")

fn tracked_resolve_source_relative(source_path: &str, raw_path: &str) -> str:
    if tracked_path_is_absolute(raw_path):
        return with_str_clone_ref(raw_path)
    let dir = tracked_dirname(source_path)
    if dir.len() == 0:
        return with_str_clone_ref(raw_path)
    dir ++ "/" ++ raw_path

fn tracked_inside_root(path: &str, root: &str) -> bool:
    if root.len() == 0:
        return true
    if path == root:
        return true
    // Root "." contains every relative path (normalization strips the "./"
    // prefix from the path, so the prefix comparison below would miss).
    if root == "." and path.len() > 0 and path.byte_at(0) != 47:
        return true
    let prefix = if root.ends_with("/"): with_str_clone_ref(root) else: root ++ "/"
    path.starts_with(prefix)

// Lexically collapse '.' and '..' segments so containment is checked against
// the path a read would actually touch (#585). A '..' that would climb above
// the start of a relative path is kept (it escapes the resolution base and the
// caller's containment/parent-segment checks reject it); on an absolute path a
// leading '..' is dropped (cannot go above '/').
fn tracked_normalize_path(path: &str) -> str:
    if path.len() == 0:
        return with_str_clone_ref(path)
    let is_abs = path.len() > 0 and path.byte_at(0) == 47
    let parts: Vec[str] = Vec.new()
    var start = 0
    for i in 0..(path.len() as i32 + 1):
        let at_end = i == path.len() as i32
        // Split on both '/' and '\' so a '\'-separated Windows path normalizes
        // to the same '/'-form the containment checks expect (#801).
        if at_end or path.byte_at(i as i64) == 47 or path.byte_at(i as i64) == 92:
            if i > start:
                // Flat decision (no inner chain ending in else-if): the seed
                // compiler predates the #629 dangling-else fix and miscompiles
                // that shape — the ordinary-segment push became dead code.
                let part = path.slice(start as i64, i as i64)
                var keep = true
                if part == ".":
                    keep = false
                if part == "..":
                    keep = false
                    if parts.len() > 0 and parts.get(parts.len() - 1) != "..":
                        parts.pop()
                    else if not is_abs:
                        parts.push(with_str_clone_ref(part))
                if keep:
                    parts.push(part)
            start = i + 1
    if parts.len() == 0:
        if is_abs:
            return "/"
        return "."
    var result = if is_abs: "/" else: ""
    for pi in 0..parts.len() as i32:
        if pi > 0:
            result = result ++ "/"
        result = result ++ parts.get(pi as i64)
    result

fn tracked_authorized_root(source_path: &str, package_root: &str) -> str:
    if package_root.len() > 0:
        return with_str_clone_ref(package_root)
    let dir = tracked_dirname(source_path)
    if dir.len() == 0:
        return ""
    dir

pub fn tracked_embed_resolve(source_path: &str, raw_path: &str) -> str:
    tracked_resolve_source_relative(source_path, raw_path)

pub fn tracked_embed_read(source_path: &str, raw_path: &str, package_root: &str) -> TrackedReadResult:
    // #585: resolve relative to the source file, NORMALIZE, then enforce that
    // the normalized path stays inside the authorized root — so an internal
    // '..' that resolves back inside the package (src/main.w embedding
    // ../resources/x) is legal, while true escapes are still rejected. After
    // normalization an in-root path has no remaining parent segments; any
    // leftover '..' (or a rootless path with parent segments) escapes.
    var resolved = tracked_normalize_path(tracked_embed_resolve(source_path, raw_path))
    let root = tracked_normalize_path(tracked_authorized_root(source_path, package_root))
    // The project root is absolute (with.toml discovery absolutizes it) while a
    // CLI-relative source path resolves to a relative embed path; anchor the
    // relative path to the working directory so containment compares like with
    // like. Leading '..' segments collapse against the cwd here, turning a true
    // escape into an absolute path outside the root.
    if root.len() > 0 and tracked_path_is_absolute(root) and not tracked_path_is_absolute(resolved):
        let cwd = runtime_getenv("PWD")
        if cwd.len() > 0:
            resolved = tracked_normalize_path(cwd ++ "/" ++ resolved)
    if tracked_path_has_parent_segment(resolved) or (root.len() > 0 and not tracked_inside_root(resolved, root)):
        let display_root = if root.len() > 0: root else: tracked_dirname(source_path)
        return tracked_read_error(resolved, "embed_file: '" ++ resolved ++ "' is outside the package root '" ++ display_root ++ "'; embed_file reads only tracked inputs inside the package (broader access requires an explicit build capability)")
    if runtime_file_exists(resolved) == 0:
        return tracked_read_error(resolved, "embed_file: could not read '" ++ resolved ++ "'")
    tracked_read_ok(resolved, runtime_read_file(resolved))
