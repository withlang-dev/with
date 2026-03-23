// ConanClient — Conan Center REST API client for C package management.
//
// Downloads prebuilt binary packages from Conan Center (center.conan.io)
// using the Conan v2 REST API. No dependency on the conan CLI.

extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_system(cmd: str) -> i32
extern fn with_eprintln(s: str) -> void
fn CONAN_CENTER_URL -> str: "https://center.conan.io"

use std.http

// Native HTTPS via With's TLS stack (no curl dependency)
fn conan_http_get(url: str) -> str:
    https_get(url)

fn conan_http_download(url: str, path: str) -> i32:
    https_download(url, path)

fn conan_extract_tgz(archive: str, dest: str) -> i32:
    let cmd = "tar xzf '" ++ archive ++ "' -C '" ++ dest ++ "' 2>/dev/null"
    with_system(cmd)

// ── JSON helpers (minimal, for machine-generated Conan responses) ──

fn json_extract_string(json: str, key: str) -> str:
    // Extract "key": "value" from JSON. Returns "" if not found.
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
            // Skip past key, find colon, then opening quote
            var vi = pos + needle.len() as i32
            while vi < json_len and json.byte_at(vi as i64) != 34:
                vi = vi + 1
            if vi >= json_len:
                return ""
            vi = vi + 1  // skip opening quote
            let start = vi
            while vi < json_len and json.byte_at(vi as i64) != 34:
                vi = vi + 1
            return json.slice(start as i64, vi as i64)
        pos = pos + 1
    ""

fn json_extract_string_array(json: str, key: str) -> Vec[str]:
    // Extract "key": ["a", "b", ...] from JSON.
    var result: Vec[str] = Vec.new()
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
            while ai < json_len and json.byte_at(ai as i64) != 91:  // '['
                ai = ai + 1
            if ai >= json_len:
                return result
            ai = ai + 1
            while ai < json_len and json.byte_at(ai as i64) != 93:  // ']'
                if json.byte_at(ai as i64) == 34:  // '"'
                    let start = ai + 1
                    var end = start
                    while end < json_len and json.byte_at(end as i64) != 34:
                        end = end + 1
                    if end > start:
                        result.push(json.slice(start as i64, end as i64))
                    ai = end + 1
                else:
                    ai = ai + 1
            return result
        pos = pos + 1
    result

// ── Conan API functions ────────────────────────────────────────────

fn conan_get_latest_recipe_rev(name: str, version: str) -> str:
    let url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/latest"
    let response = conan_http_get(url)
    if response.len() == 0:
        return ""
    json_extract_string(response, "revision")

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

fn conan_detect_os -> str:
    with_sysinfo_os()

fn conan_detect_arch -> str:
    with_sysinfo_arch()

fn conan_find_matching_package(name: str, version: str, rev: str) -> str:
    // Use /search endpoint which returns all packages with inline settings
    let url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/search"
    let response = conan_http_get(url)
    if response.len() == 0:
        return ""
    let target_os = conan_detect_os()
    let target_arch = conan_detect_arch()
    // Parse JSON: top-level keys are package IDs, each has "settings" with "os" and "arch"
    // Also prefer shared=False (static linking)
    var best_id = ""
    let json_len = response.len() as i32
    var pos = 1  // skip opening {
    while pos < json_len:
        // Find next quoted key (package ID)
        if response.byte_at(pos as i64) != 34:
            pos = pos + 1
            continue
        let id_start = pos + 1
        var id_end = id_start
        while id_end < json_len and response.byte_at(id_end as i64) != 34:
            id_end = id_end + 1
        let pkg_id = response.slice(id_start as i64, id_end as i64)
        pos = id_end + 1
        // Find the value object for this key — scan for "os" and "arch" in settings
        var depth = 0
        var obj_start = pos
        // Skip to opening { of the value
        while pos < json_len and response.byte_at(pos as i64) != 123:
            pos = pos + 1
        let block_start = pos
        depth = 1
        pos = pos + 1
        var has_os = false
        var has_arch = false
        var is_static = false
        while pos < json_len and depth > 0:
            let ch = response.byte_at(pos as i64)
            if ch == 123:
                depth = depth + 1
            else if ch == 125:
                depth = depth - 1
            pos = pos + 1
        // Extract settings from the block
        let block = response.slice(block_start as i64, pos as i64)
        if block.contains("\"os\" : \"" ++ target_os ++ "\"") or block.contains("\"os\":\"" ++ target_os ++ "\""):
            has_os = true
        if block.contains("\"arch\" : \"" ++ target_arch ++ "\"") or block.contains("\"arch\":\"" ++ target_arch ++ "\""):
            has_arch = true
        if block.contains("\"shared\" : \"False\"") or block.contains("\"shared\":\"False\""):
            is_static = true
        if has_os and has_arch and is_static:
            return pkg_id
        if has_os and has_arch and best_id.len() == 0:
            best_id = pkg_id
    best_id

fn conan_download_and_extract(name: str, version: str, rev: str, pkg_id: str, dest_dir: str) -> i32:
    // Get latest package revision
    let latest_url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/packages/" ++ pkg_id ++ "/latest"
    let latest = conan_http_get(latest_url)
    if latest.len() == 0:
        with_eprintln("error: failed to get package revision for " ++ name)
        return -1
    let pkg_rev = json_extract_string(latest, "revision")
    if pkg_rev.len() == 0:
        with_eprintln("error: failed to parse package revision for " ++ name)
        return -1
    // Download conan_package.tgz
    let tgz_url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/packages/" ++ pkg_id ++ "/revisions/" ++ pkg_rev ++ "/files/conan_package.tgz"
    let tgz_path = dest_dir ++ "/conan_package.tgz"
    with_eprintln("  downloading " ++ name ++ "/" ++ version ++ "...")
    if conan_http_download(tgz_url, tgz_path) != 0:
        with_eprintln("error: failed to download package for " ++ name)
        return -1
    // Extract
    with_eprintln("  extracting...")
    if conan_extract_tgz(tgz_path, dest_dir) != 0:
        with_eprintln("error: failed to extract package for " ++ name)
        return -1
    0

fn conan_write_metadata(dest_dir: str, name: str, version: str) -> i32:
    let q = "\x22"  // double quote
    let ob = "\x7b" // {
    let cb = "\x7d" // }
    let nl = "\n"
    var meta = ob ++ nl
    meta = meta ++ "  " ++ q ++ "name" ++ q ++ ": " ++ q ++ name ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "version" ++ q ++ ": " ++ q ++ version ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "include_paths" ++ q ++ ": [" ++ q ++ "include" ++ q ++ "]," ++ nl
    meta = meta ++ "  " ++ q ++ "lib_paths" ++ q ++ ": [" ++ q ++ "lib" ++ q ++ "]," ++ nl
    meta = meta ++ "  " ++ q ++ "libs" ++ q ++ ": [" ++ q ++ name ++ q ++ "]" ++ nl
    meta = meta ++ cb ++ nl
    with_fs_write_file(dest_dir ++ "/metadata.json", meta)

// ── Public API ─────────────────────────────────────────────────────

fn conan_install(name: str, version_hint: str, project_root: str) -> i32:
    with_eprintln("resolving " ++ name ++ "...")
    // Use provided version or resolve latest
    var version = version_hint
    if version.len() == 0:
        // TODO: resolve latest version from search API
        with_eprintln("error: version required (latest resolution not yet implemented)")
        with_eprintln("  usage: with get c." ++ name ++ "@<version>")
        return -1
    // Get latest recipe revision
    let rev = conan_get_latest_recipe_rev(name, version)
    if rev.len() == 0:
        with_eprintln("error: package " ++ name ++ "/" ++ version ++ " not found on Conan Center")
        return -1
    with_eprintln("  revision: " ++ rev.slice(0, if rev.len() > 12: 12 else: rev.len()))
    // Find binary for current platform
    let pkg_id = conan_find_matching_package(name, version, rev)
    if pkg_id.len() == 0:
        with_eprintln("error: no prebuilt binary found for " ++ name ++ "/" ++ version ++ " on this platform")
        return -1
    with_eprintln("  binary: " ++ pkg_id.slice(0, if pkg_id.len() > 12: 12 else: pkg_id.len()))
    // Download and extract
    let dep_dir = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version
    with_fs_mkdir_p(dep_dir)
    if conan_download_and_extract(name, version, rev, pkg_id, dep_dir) != 0:
        return -1
    // Write metadata.json
    if conan_write_metadata(dep_dir, name, version) != 0:
        with_eprintln("error: failed to write metadata for " ++ name)
        return -1
    with_eprintln("  installed to .with/deps/c/" ++ name ++ "/" ++ version ++ "/")
    0
