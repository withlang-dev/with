// LockFile — deterministic `.with/lock.json` handling for fetched packages.
//
// Manual `[deps.c.X]` entries are intentionally not represented here: they
// point at user-owned paths and have no fetched artifact to hash-pin.

use compiler.Runtime
use compiler.ConanClient
use std.crypto.sha256

type LockEntry {
    name: str,
    source: str,
    version: str,
    recipe_rev: str,
    package_id: str,
    package_rev: str,
    sha256: str,
}

type LockFile {
    entries: Vec[LockEntry],
}

pub fn lock_file_path(project_root: str) -> str:
    project_root ++ "/.with/lock.json"

fn lock_empty -> LockFile:
    LockFile { entries: Vec.new() }

fn lock_str_compare(a: str, b: str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        let ca = a.byte_at(i as i64) as i32
        let cb = b.byte_at(i as i64) as i32
        if ca < cb:
            return -1
        if ca > cb:
            return 1
    if a.len() < b.len():
        return -1
    if a.len() > b.len():
        return 1
    0

fn lock_json_escape(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 34 or ch == 92:
            out = out ++ "\\"
        out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn lock_json_string(key: str, value: str, comma: bool) -> str:
    let q = "\x22"
    let suffix = if comma: "," else: ""
    "      " ++ q ++ key ++ q ++ ": " ++ q ++ lock_json_escape(value) ++ q ++ suffix ++ "\n"

fn lock_find_text(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    let n = text.len() as i32
    let m = needle.len() as i32
    var i = 0
    while i <= n - m:
        var ok = true
        for j in 0..m:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                ok = false
                break
        if ok:
            return i
        i = i + 1
    -1

fn lock_json_extract_string(json: str, key: str) -> str:
    let needle = "\"" ++ key ++ "\""
    let json_len = json.len() as i32
    var pos = 0
    while pos < json_len - needle.len() as i32:
        var found = true
        for ni in 0..needle.len() as i32:
            if json.byte_at((pos + ni) as i64) != needle.byte_at(ni as i64):
                found = false
                break
        if found:
            var vi = pos + needle.len() as i32
            while vi < json_len and json.byte_at(vi as i64) != 58:
                vi = vi + 1
            while vi < json_len and json.byte_at(vi as i64) != 34:
                vi = vi + 1
            if vi >= json_len:
                return ""
            vi = vi + 1
            let start = vi
            var escaped = false
            while vi < json_len:
                let ch = json.byte_at(vi as i64)
                if escaped:
                    escaped = false
                else if ch == 92:
                    escaped = true
                else if ch == 34:
                    break
                vi = vi + 1
            return json.slice(start as i64, vi as i64)
        pos = pos + 1
    ""

fn lock_json_extract_string_array(json: str, key: str) -> Vec[str]:
    let result: Vec[str] = Vec.new()
    let needle = "\"" ++ key ++ "\""
    let json_len = json.len() as i32
    var pos = 0
    while pos < json_len - needle.len() as i32:
        var found = true
        for ni in 0..needle.len() as i32:
            if json.byte_at((pos + ni) as i64) != needle.byte_at(ni as i64):
                found = false
                break
        if found:
            var ai = pos + needle.len() as i32
            while ai < json_len and json.byte_at(ai as i64) != 91:
                ai = ai + 1
            if ai >= json_len:
                return result
            ai = ai + 1
            while ai < json_len and json.byte_at(ai as i64) != 93:
                if json.byte_at(ai as i64) == 34:
                    let start = ai + 1
                    var end = start
                    var escaped = false
                    while end < json_len:
                        let ch = json.byte_at(end as i64)
                        if escaped:
                            escaped = false
                        else if ch == 92:
                            escaped = true
                        else if ch == 34:
                            break
                        end = end + 1
                    if end > start:
                        result.push(json.slice(start as i64, end as i64))
                    ai = end + 1
                else:
                    ai = ai + 1
            return result
        pos = pos + 1
    result

fn lock_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let n = text.len() as i32
    var start = 0
    var i = 0
    while i <= n:
        let at_end = i == n
        let ch = if at_end: 10 else: text.byte_at(i as i64)
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn lock_line_string_value(line: str, key: str) -> str:
    let needle = "\"" ++ key ++ "\""
    let key_pos = lock_find_text(line, needle)
    if key_pos < 0:
        return ""
    var pos = key_pos + needle.len() as i32
    let n = line.len() as i32
    while pos < n and line.byte_at(pos as i64) != 58:
        pos = pos + 1
    while pos < n and line.byte_at(pos as i64) != 34:
        pos = pos + 1
    if pos >= n:
        return ""
    let start = pos + 1
    var end = start
    while end < n and line.byte_at(end as i64) != 34:
        end = end + 1
    line.slice(start as i64, end as i64)

fn lock_line_entry_name(line: str) -> str:
    if lock_find_text(line, "\": {") < 0:
        return ""
    if lock_find_text(line, "\"c.") < 0:
        return ""
    var start = 0
    let n = line.len() as i32
    while start < n and line.byte_at(start as i64) != 34:
        start = start + 1
    if start >= n:
        return ""
    start = start + 1
    var end = start
    while end < n and line.byte_at(end as i64) != 34:
        end = end + 1
    line.slice(start as i64, end as i64)

pub fn lock_load(project_root: str) -> LockFile:
    let path = lock_file_path(project_root)
    if runtime_file_exists(path) == 0:
        return lock_empty()
    let json = runtime_read_file(path)
    var lock = lock_empty()
    var current = LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
    let lines = lock_split_nonempty_lines(json)
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        let entry_name = lock_line_entry_name(line)
        if entry_name.len() > 0:
            current = LockEntry { name: entry_name, source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
            continue
        if current.name.len() == 0:
            continue
        let source = lock_line_string_value(line, "source")
        if source.len() > 0:
            current.source = source
            continue
        let version = lock_line_string_value(line, "version")
        if version.len() > 0:
            current.version = version
            continue
        let recipe_rev = lock_line_string_value(line, "recipe_rev")
        if recipe_rev.len() > 0:
            current.recipe_rev = recipe_rev
            continue
        let package_id = lock_line_string_value(line, "package_id")
        if package_id.len() > 0:
            current.package_id = package_id
            continue
        let package_rev = lock_line_string_value(line, "package_rev")
        if package_rev.len() > 0:
            current.package_rev = package_rev
            continue
        let digest = lock_line_string_value(line, "sha256")
        if digest.len() > 0:
            current.sha256 = digest
            continue
        if lock_find_text(line, "}") >= 0:
            lock = lock_upsert(lock, current)
            current = LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
    lock

pub fn lock_upsert(lock: LockFile, entry: LockEntry) -> LockFile:
    let out_entries: Vec[LockEntry] = Vec.new()
    var inserted = false
    for i in 0..lock.entries.len() as i32:
        let existing = lock.entries.get(i as i64)
        let cmp = lock_str_compare(entry.name, existing.name)
        if cmp == 0:
            if not inserted:
                out_entries.push(entry)
                inserted = true
        else:
            if not inserted and cmp < 0:
                out_entries.push(entry)
                inserted = true
            out_entries.push(existing)
    if not inserted:
        out_entries.push(entry)
    LockFile { entries: out_entries }

pub fn lock_remove(lock: LockFile, name: str) -> LockFile:
    let out_entries: Vec[LockEntry] = Vec.new()
    for i in 0..lock.entries.len() as i32:
        let entry = lock.entries.get(i as i64)
        if entry.name != name:
            out_entries.push(entry)
    LockFile { entries: out_entries }

pub fn lock_write(project_root: str, lock: LockFile) -> i32:
    let dir = project_root ++ "/.with"
    if runtime_mkdir_p(dir) != 0:
        runtime_eprint("error: failed to create .with directory")
        return 1
    let q = "\x22"
    var text = "{\n"
    text = text ++ "  " ++ q ++ "version" ++ q ++ ": 1,\n"
    text = text ++ "  " ++ q ++ "deps" ++ q ++ ": {\n"
    for i in 0..lock.entries.len() as i32:
        let entry = lock.entries.get(i as i64)
        text = text ++ "    " ++ q ++ lock_json_escape(entry.name) ++ q ++ ": {\n"
        text = text ++ lock_json_string("source", entry.source, true)
        text = text ++ lock_json_string("version", entry.version, entry.source == "conan")
        if entry.source == "conan":
            text = text ++ lock_json_string("recipe_rev", entry.recipe_rev, true)
            text = text ++ lock_json_string("package_id", entry.package_id, true)
            text = text ++ lock_json_string("package_rev", entry.package_rev, true)
            text = text ++ lock_json_string("sha256", entry.sha256, false)
        let suffix = if i + 1 < lock.entries.len() as i32: "," else: ""
        text = text ++ "    }" ++ suffix ++ "\n"
    text = text ++ "  }\n"
    text = text ++ "}\n"
    runtime_write_file(lock_file_path(project_root), text)

pub fn lock_sha256_text(data: str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

pub fn lock_sha256_file(path: str) -> str:
    if runtime_file_exists(path) == 0:
        return ""
    lock_sha256_text(runtime_read_file(path))

fn lock_c_dep_dir(project_root: str, name: str, version: str) -> str:
    project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version

fn lock_ref_name(req: str) -> str:
    let slash = lock_find_text(req, "/")
    if slash <= 0:
        return ""
    req.slice(0, slash as i64)

fn lock_ref_version(req: str) -> str:
    let slash = lock_find_text(req, "/")
    if slash <= 0:
        return ""
    var end = req.len() as i32
    let at = lock_find_text(req, "@")
    if at > slash:
        end = at
    req.slice((slash + 1) as i64, end as i64)

fn lock_entry_from_installed_c_dep(project_root: str, name: str, version: str) -> LockEntry:
    let dep_dir = lock_c_dep_dir(project_root, name, version)
    let meta = runtime_read_file(dep_dir ++ "/metadata.json")
    if meta.len() == 0:
        return LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
    let recipe_rev = lock_json_extract_string(meta, "recipe_revision")
    let package_id = lock_json_extract_string(meta, "package_id")
    let package_rev = lock_json_extract_string(meta, "package_revision")
    let dep_name = "c." ++ name
    if recipe_rev == "system" and package_id == "system" and package_rev == "system":
        return LockEntry { name: dep_name, source: "system", version, recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
    let tgz_path = dep_dir ++ "/conan_package.tgz"
    let digest = lock_sha256_file(tgz_path)
    if digest.len() == 0:
        runtime_eprint("error: cannot lock c." ++ name ++ "@" ++ version ++ ": missing fetched archive " ++ tgz_path)
        return LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
    LockEntry { name: dep_name, source: "conan", version, recipe_rev, package_id, package_rev, sha256: digest }

fn lock_upsert_installed_c_dep_tree_seen(lock: LockFile, project_root: str, name: str, version: str, seen: Vec[str]) -> LockFile:
    let key = name ++ "/" ++ version
    for i in 0..seen.len() as i32:
        if seen.get(i as i64) == key:
            return lock
    seen.push(key)
    let entry = lock_entry_from_installed_c_dep(project_root, name, version)
    if entry.name.len() == 0:
        return LockFile { entries: Vec.new() }
    var out = lock_upsert(lock, entry)
    let meta = runtime_read_file(lock_c_dep_dir(project_root, name, version) ++ "/metadata.json")
    let requirements = lock_json_extract_string_array(meta, "requires")
    for i in 0..requirements.len() as i32:
        let req = requirements.get(i as i64)
        let req_name = lock_ref_name(req)
        let req_version = lock_ref_version(req)
        if req_name.len() == 0 or req_version.len() == 0:
            runtime_eprint("error: unsupported locked Conan requirement reference: " ++ req)
            return LockFile { entries: Vec.new() }
        out = lock_upsert_installed_c_dep_tree_seen(out, project_root, req_name, req_version, seen)
        if out.entries.len() == 0:
            return out
    out

pub fn lock_upsert_installed_c_dep_tree(lock: LockFile, project_root: str, name: str, version: str) -> LockFile:
    let seen: Vec[str] = Vec.new()
    lock_upsert_installed_c_dep_tree_seen(move lock, project_root, name, version, seen)

fn lock_c_name(entry_name: str) -> str:
    if entry_name.starts_with("c."):
        return entry_name.slice(2, entry_name.len())
    ""

fn lock_cached_archive_matches(entry: LockEntry, project_root: str, dep_dir: str) -> bool:
    let meta_path = dep_dir ++ "/metadata.json"
    let tgz_path = dep_dir ++ "/conan_package.tgz"
    if runtime_file_exists(meta_path) == 0 or runtime_file_exists(tgz_path) == 0:
        return false
    let actual = lock_sha256_file(tgz_path)
    actual.len() > 0 and actual == entry.sha256

fn lock_restore_entry(project_root: str, entry: LockEntry) -> i32:
    let c_name = lock_c_name(entry.name)
    if c_name.len() == 0:
        runtime_eprint("error: unsupported lock entry '" ++ entry.name ++ "'")
        return 1
    if entry.source == "registry":
        runtime_eprint("error: With package registry restore is not available yet for " ++ entry.name)
        return 1
    if entry.source == "system":
        if conan_write_known_system_package(c_name, entry.version, project_root):
            runtime_eprint("restored " ++ entry.name ++ "@" ++ entry.version ++ " (system)")
            return 0
        runtime_eprint("error: unsupported system package in lock file: " ++ entry.name ++ "@" ++ entry.version)
        return 1
    if entry.source != "conan":
        runtime_eprint("error: unsupported lock source '" ++ entry.source ++ "' for " ++ entry.name)
        return 1
    let dep_dir = lock_c_dep_dir(project_root, c_name, entry.version)
    if lock_cached_archive_matches(entry, project_root, dep_dir):
        runtime_eprint("restored " ++ entry.name ++ "@" ++ entry.version ++ " (cached)")
        return 0
    let tgz_path = dep_dir ++ "/conan_package.tgz"
    if runtime_file_exists(tgz_path) != 0:
        let actual = lock_sha256_file(tgz_path)
        runtime_eprint("error: hash mismatch for " ++ entry.name ++ "@" ++ entry.version ++ ": expected " ++ entry.sha256 ++ ", got " ++ actual)
        let _remove = runtime_remove_tree(dep_dir)
        return 1
    if entry.sha256.len() == 0 or entry.recipe_rev.len() == 0 or entry.package_id.len() == 0 or entry.package_rev.len() == 0:
        runtime_eprint("error: incomplete lock entry for " ++ entry.name ++ "@" ++ entry.version)
        return 1
    if conan_restore_locked_binary_package(c_name, entry.version, entry.recipe_rev, entry.package_id, entry.package_rev, entry.sha256, project_root):
        runtime_eprint("restored " ++ entry.name ++ "@" ++ entry.version)
        return 0
    1

pub fn lock_restore(project_root: str) -> i32:
    let path = lock_file_path(project_root)
    if runtime_file_exists(path) == 0:
        runtime_eprint("error: no lock file at .with/lock.json; run 'with get c.<name>' to add dependencies first")
        return 1
    let lock = lock_load(project_root)
    if lock.entries.len() == 0:
        runtime_eprint("error: lock file has no dependencies: .with/lock.json")
        return 1
    for i in 0..lock.entries.len() as i32:
        let entry = lock.entries.get(i as i64)
        let rc = lock_restore_entry(project_root, entry)
        if rc != 0:
            return rc
    0
