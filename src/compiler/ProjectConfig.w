use Resolve

extern fn with_fs_read_file(path: str) -> str
extern fn with_getenv_str(name: str) -> str

type ProjectConfig = {
    root_dir: str,
    manifest_path: str,
    c_import_include_paths: Vec[str],
    link_search_paths: Vec[str],
}

fn project_config_default -> ProjectConfig:
    ProjectConfig {
        root_dir: "",
        manifest_path: "",
        c_import_include_paths: Vec.new(),
        link_search_paths: Vec.new(),
    }

fn project_config_file_exists(path: str) -> bool:
    with_fs_read_file(path).len() > 0

fn project_config_find_root(start_dir: str) -> str:
    var cur = if start_dir.len() > 0: start_dir else: "."
    while true:
        let manifest = resolve_join(cur, "with.toml")
        if project_config_file_exists(manifest):
            return cur
        let parent = resolve_dirname(cur)
        if parent == cur:
            break
        cur = parent
    ""

fn project_config_load_for_source(source_path_raw: str) -> ProjectConfig:
    let source_path = project_config_absolutize_path(source_path_raw)
    let root = project_config_find_root(resolve_dirname(source_path))
    if root.len() == 0:
        return project_config_default()

    let manifest_path = resolve_join(root, "with.toml")
    let text = with_fs_read_file(manifest_path)

    var cfg = project_config_default()
    cfg.root_dir = root
    cfg.manifest_path = manifest_path
    if text.len() == 0:
        return cfg

    var section = ""
    var pending_key = ""
    var pending_value = ""

    var line_start = 0
    var i = 0
    let total = text.len() as i32
    while i <= total:
        if i == total or text.byte_at(i as i64) == 10:
            var line = text.slice(line_start as i64, i as i64)
            line = project_config_trim(project_config_strip_comment(line))
            if line.len() > 0:
                if pending_key.len() > 0:
                    if pending_value.len() > 0:
                        pending_value = pending_value ++ " "
                    pending_value = pending_value ++ line
                    if project_config_value_complete(pending_value):
                        cfg = project_config_apply_entry(cfg, section, pending_key, pending_value)
                        pending_key = ""
                        pending_value = ""
                else if line.byte_at(0) == 91 and line.byte_at(line.len() as i64 - 1) == 93:
                    section = project_config_trim(line.slice(1, line.len() - 1))
                else:
                    let eq = project_config_find_char(line, 61)
                    if eq > 0:
                        let key = project_config_trim(line.slice(0, eq as i64))
                        let value = project_config_trim(line.slice((eq + 1) as i64, line.len()))
                        if project_config_wants_key(section, key):
                            if project_config_value_complete(value):
                                cfg = project_config_apply_entry(cfg, section, key, value)
                            else:
                                pending_key = key
                                pending_value = value
            line_start = i + 1
        i = i + 1

    if pending_key.len() > 0 and project_config_value_complete(pending_value):
        cfg = project_config_apply_entry(cfg, section, pending_key, pending_value)

    cfg

fn project_config_apply_entry(cfg: ProjectConfig, section: str, key: str, value: str) -> ProjectConfig:
    var out = cfg
    if section == "c_import" and key == "include_paths":
        out.c_import_include_paths = project_config_parse_path_array(value, out.root_dir)
    else if section == "link" and key == "search_paths":
        out.link_search_paths = project_config_parse_path_array(value, out.root_dir)
    out

fn project_config_wants_key(section: str, key: str) -> bool:
    if section == "c_import" and key == "include_paths":
        return true
    if section == "link" and key == "search_paths":
        return true
    false

fn project_config_value_complete(value: str) -> bool:
    project_config_find_char(value, 93) >= 0

fn project_config_parse_path_array(value: str, root_dir: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var i = 0
    let total = value.len() as i32
    while i < total:
        if value.byte_at(i as i64) == 34:
            i = i + 1
            var entry = ""
            var escaped = 0
            while i < total:
                let ch = value.byte_at(i as i64)
                if escaped != 0:
                    if ch == 110:
                        entry = entry ++ "\n"
                    else if ch == 116:
                        entry = entry ++ "\t"
                    else if ch == 114:
                        entry = entry ++ "\r"
                    else:
                        entry = entry ++ value.slice(i as i64, (i + 1) as i64)
                    escaped = 0
                else if ch == 92:
                    escaped = 1
                else if ch == 34:
                    break
                else:
                    entry = entry ++ value.slice(i as i64, (i + 1) as i64)
                i = i + 1
            if entry.len() > 0:
                out.push(project_config_resolve_path(root_dir, entry))
        i = i + 1
    out

fn project_config_resolve_c_import_header(cfg: ProjectConfig, decl_dir: str, header_spec_raw: str) -> str:
    let header_spec = project_config_trim(header_spec_raw)
    if header_spec.len() == 0:
        return header_spec_raw
    if project_config_str_contains(header_spec, "\n"):
        return header_spec_raw
    if project_config_str_contains(header_spec, ";"):
        return header_spec_raw
    if header_spec.byte_at(0) == 35:
        return header_spec_raw

    var header_name = header_spec
    var preserve_angle = 0
    var preserve_quote = 0
    if header_spec.len() >= 2 and header_spec.byte_at(0) == 60 and header_spec.byte_at(header_spec.len() as i64 - 1) == 62:
        header_name = header_spec.slice(1, header_spec.len() - 1)
        preserve_angle = 1
    else if header_spec.len() >= 2 and header_spec.byte_at(0) == 34 and header_spec.byte_at(header_spec.len() as i64 - 1) == 34:
        header_name = header_spec.slice(1, header_spec.len() - 1)
        preserve_quote = 1

    let resolved = project_config_resolve_header_path(cfg, decl_dir, header_name)
    if resolved.len() > 0:
        return "\"" ++ resolved ++ "\""
    if project_config_is_absolute_path(header_name):
        return "\"" ++ header_name ++ "\""
    if preserve_quote != 0:
        return "\"" ++ header_name ++ "\""
    if preserve_angle != 0:
        return "<" ++ header_name ++ ">"
    header_spec_raw

fn project_config_resolve_header_path(cfg: ProjectConfig, decl_dir: str, header_name: str) -> str:
    if header_name.len() == 0:
        return ""
    if project_config_is_absolute_path(header_name):
        if project_config_file_exists(header_name):
            return header_name
        return ""

    let base_dir = if decl_dir.len() > 0:
        project_config_absolutize_path(decl_dir)
    else:
        if cfg.root_dir.len() > 0: cfg.root_dir else: project_config_absolutize_path(".")
    let local_candidate = resolve_join(base_dir, header_name)
    if project_config_file_exists(local_candidate):
        return local_candidate

    for i in 0..cfg.c_import_include_paths.len() as i32:
        let include_dir = cfg.c_import_include_paths.get(i as i64)
        let candidate = resolve_join(include_dir, header_name)
        if project_config_file_exists(candidate):
            return candidate
    ""

fn project_config_resolve_path(root_dir: str, path: str) -> str:
    if path.len() == 0:
        return path
    if project_config_is_absolute_path(path):
        return path
    if root_dir.len() == 0:
        return project_config_absolutize_path(path)
    resolve_join(root_dir, path)

fn project_config_is_absolute_path(path: str) -> bool:
    path.len() > 0 and path.byte_at(0) == 47

fn project_config_absolutize_path(path: str) -> str:
    if path.len() == 0:
        return path
    if project_config_is_absolute_path(path):
        return path
    let cwd = with_getenv_str("PWD")
    if cwd.len() == 0:
        return path
    resolve_join(cwd, path)

fn project_config_find_char(text: str, ch: i32) -> i32:
    var i = 0
    while i < text.len() as i32:
        if text.byte_at(i as i64) == ch:
            return i
        i = i + 1
    -1

fn project_config_strip_comment(line: str) -> str:
    var in_string = 0
    var escaped = 0
    var i = 0
    while i < line.len() as i32:
        let ch = line.byte_at(i as i64)
        if escaped != 0:
            escaped = 0
        else if in_string != 0 and ch == 92:
            escaped = 1
        else if ch == 34:
            if in_string != 0:
                in_string = 0
            else:
                in_string = 1
        else if ch == 35 and in_string == 0:
            return line.slice(0, i as i64)
        i = i + 1
    line

fn project_config_trim(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end and project_config_is_space(text.byte_at(start as i64)):
        start = start + 1
    while end > start and project_config_is_space(text.byte_at((end - 1) as i64)):
        end = end - 1
    text.slice(start as i64, end as i64)

fn project_config_is_space(ch: i32) -> bool:
    ch == 32 or ch == 9 or ch == 10 or ch == 13

fn project_config_str_contains(text: str, needle: str) -> bool:
    if needle.len() == 0:
        return true
    if needle.len() > text.len():
        return false
    var i = 0
    let limit = text.len() as i32 - needle.len() as i32
    while i <= limit:
        if text.slice(i as i64, (i + needle.len() as i32) as i64) == needle:
            return true
        i = i + 1
    false
