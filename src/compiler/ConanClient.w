// ConanClient — native Conan Center client for C package management.
//
// Uses Conan's v2 REST API directly. No dependency on the conan CLI.

use Archive
use compiler.Runtime
use std.crypto.sha256

fn CONAN_CENTER_URL -> str: "https://center2.conan.io"
fn CONAN_INDEX_RAW -> str: "https://raw.githubusercontent.com/conan-io/conan-center-index/master/recipes"

type ConanPackagePick {
    package_id: str,
    shared: bool,
}

type ConanLibraryScan {
    lib_paths: Vec[str],
    libs: Vec[str],
}

fn conan_http_get(url: str) -> str:
    let tmp = f"/tmp/with-conan-http-{runtime_getpid()}.json"
    let _rm_old = runtime_remove_file(tmp)
    let rc = conan_curl_to_file(url, tmp, 300000)
    if rc != 0:
        let _rm_fail = runtime_remove_file(tmp)
        return ""
    let body = runtime_read_file(tmp)
    let _rm = runtime_remove_file(tmp)
    body

fn conan_http_download(url: str, path: str) -> i32:
    conan_curl_to_file(url, path, 300000)

fn conan_sha256_file(path: str) -> str:
    if runtime_file_exists(path) == 0:
        return ""
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(runtime_read_file(path), &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

fn conan_argv_append(argv: str, arg: str) -> str:
    argv ++ arg ++ "\0"

fn conan_curl_to_file(url: str, path: str, timeout_ms: i32) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, "curl")
    argv = conan_argv_append(argv, "-fsSL")
    argv = conan_argv_append(argv, "--retry")
    argv = conan_argv_append(argv, "2")
    argv = conan_argv_append(argv, "--connect-timeout")
    argv = conan_argv_append(argv, "20")
    argv = conan_argv_append(argv, "--max-time")
    argv = conan_argv_append(argv, "300")
    argv = conan_argv_append(argv, "-o")
    argv = conan_argv_append(argv, path)
    argv = conan_argv_append(argv, url)
    runtime_exec_argv_capture(argv, "/dev/null", "/dev/null", timeout_ms)

fn conan_extract_tgz(archive: str, dest: str) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, "tar")
    argv = conan_argv_append(argv, "xzf")
    argv = conan_argv_append(argv, archive)
    argv = conan_argv_append(argv, "-C")
    argv = conan_argv_append(argv, dest)
    runtime_exec_argv_capture(argv, "/dev/null", "/dev/null", 120000)

fn conan_extract_tgz_strip1(archive: str, dest: str) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, "tar")
    argv = conan_argv_append(argv, "xzf")
    argv = conan_argv_append(argv, archive)
    argv = conan_argv_append(argv, "-C")
    argv = conan_argv_append(argv, dest)
    argv = conan_argv_append(argv, "--strip-components=1")
    runtime_exec_argv_capture(argv, "/dev/null", "/dev/null", 120000)

fn conan_str_compare(a: str, b: str) -> i32:
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

fn conan_vec_contains(values: Vec[str], value: str) -> bool:
    for i in 0..values.len() as i32:
        if values.get(i as i64) == value:
            return true
    false

fn conan_sorted_insert_unique(values: Vec[str], value: str) -> Vec[str]:
    if value.len() == 0 or conan_vec_contains(values, value):
        return values
    let out: Vec[str] = Vec.new()
    var inserted = false
    for i in 0..values.len() as i32:
        let existing = values.get(i as i64)
        if not inserted and conan_str_compare(value, existing) < 0:
            out.push(value)
            inserted = true
        out.push(existing)
    if not inserted:
        out.push(value)
    out

fn conan_trim(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn conan_strip_quotes(value: str) -> str:
    let t = conan_trim(value)
    if t.len() >= 2 and t.byte_at(0) == 34 and t.byte_at(t.len() - 1) == 34:
        return t.slice(1, t.len() - 1)
    t

fn conan_find_char(text: str, ch: i32) -> i32:
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == ch:
            return i
    -1

fn conan_find_text(text: str, needle: str) -> i32:
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

fn conan_path_basename(path: str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            start = i + 1
    path.slice(start as i64, path.len())

fn conan_path_dirname(path: str) -> str:
    var slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            slash = i
    if slash < 0:
        return "."
    path.slice(0, slash as i64)

fn conan_relative_path(base: str, path: str) -> str:
    if path == base:
        return "."
    let prefix = base ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    path

fn conan_split_nonempty_lines(text: str) -> Vec[str]:
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
            line = conan_trim(line)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn json_extract_string(json: str, key: str) -> str:
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

fn json_extract_string_array(json: str, key: str) -> Vec[str]:
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

fn conan_version_compare(a: str, b: str) -> i32:
    var ai = 0
    var bi = 0
    let an = a.len() as i32
    let bn = b.len() as i32
    while ai < an or bi < bn:
        while ai < an and (a.byte_at(ai as i64) < 48 or a.byte_at(ai as i64) > 57):
            ai = ai + 1
        while bi < bn and (b.byte_at(bi as i64) < 48 or b.byte_at(bi as i64) > 57):
            bi = bi + 1
        var av = 0
        var bv = 0
        var ahas = false
        var bhas = false
        while ai < an and a.byte_at(ai as i64) >= 48 and a.byte_at(ai as i64) <= 57:
            ahas = true
            av = av * 10 + (a.byte_at(ai as i64) - 48)
            ai = ai + 1
        while bi < bn and b.byte_at(bi as i64) >= 48 and b.byte_at(bi as i64) <= 57:
            bhas = true
            bv = bv * 10 + (b.byte_at(bi as i64) - 48)
            bi = bi + 1
        if not ahas and not bhas:
            break
        if av < bv:
            return -1
        if av > bv:
            return 1
    conan_str_compare(a, b)

fn conan_version_matches_hint(version: str, hint: str) -> bool:
    if hint.len() == 0:
        return true
    if hint.ends_with(".Z"):
        let prefix = hint.slice(0, hint.len() - 2)
        return version == prefix or version.starts_with(prefix ++ ".")
    version == hint

fn conan_result_version_for_name(result: str, name: str) -> str:
    let slash = conan_find_char(result, 47)
    if slash <= 0:
        return ""
    let got_name = result.slice(0, slash as i64)
    if got_name != name:
        return ""
    let at = conan_find_char(result, 64)
    if at <= slash:
        return ""
    result.slice((slash + 1) as i64, at as i64)

fn conan_resolve_version(name: str, version_hint: str) -> str:
    if version_hint.len() > 0 and not version_hint.ends_with(".Z"):
        return version_hint
    let url = CONAN_CENTER_URL() ++ "/v2/conans/search?q=" ++ name
    let response = conan_http_get(url)
    if response.len() == 0:
        return ""
    let results = json_extract_string_array(response, "results")
    var best = ""
    for i in 0..results.len() as i32:
        let version = conan_result_version_for_name(results.get(i as i64), name)
        if version.len() == 0:
            continue
        if not conan_version_matches_hint(version, version_hint):
            continue
        if best.len() == 0 or conan_version_compare(version, best) > 0:
            best = version
    best

fn conan_get_latest_recipe_rev(name: str, version: str) -> str:
    let url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/latest"
    let response = conan_http_get(url)
    if response.len() == 0:
        return ""
    json_extract_string(response, "revision")

fn conan_detect_os -> str:
    runtime_sysinfo_os()

fn conan_detect_arch -> str:
    let arch = runtime_sysinfo_arch()
    if arch == "aarch64":
        return "armv8"
    arch

fn conan_block_matches_setting(block: str, key: str, value: str) -> bool:
    block.contains("\"" ++ key ++ "\" : \"" ++ value ++ "\"") or block.contains("\"" ++ key ++ "\":\"" ++ value ++ "\"")

fn conan_block_shared(block: str) -> bool:
    block.contains("\"shared\" : \"True\"") or block.contains("\"shared\":\"True\"")

fn conan_find_matching_package(name: str, version: str, rev: str) -> ConanPackagePick:
    let url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/search?list_only=False"
    let response = conan_http_get(url)
    if response.len() == 0:
        return ConanPackagePick { package_id: "", shared: false }
    let target_os = conan_detect_os()
    let target_arch = conan_detect_arch()
    var best_id = ""
    var best_shared = false
    let json_len = response.len() as i32
    var pos = 1
    while pos < json_len:
        if response.byte_at(pos as i64) != 34:
            pos = pos + 1
            continue
        let id_start = pos + 1
        var id_end = id_start
        while id_end < json_len and response.byte_at(id_end as i64) != 34:
            id_end = id_end + 1
        let pkg_id = response.slice(id_start as i64, id_end as i64)
        pos = id_end + 1
        while pos < json_len and response.byte_at(pos as i64) != 123:
            pos = pos + 1
        if pos >= json_len:
            break
        let block_start = pos
        var depth = 1
        pos = pos + 1
        while pos < json_len and depth > 0:
            let ch = response.byte_at(pos as i64)
            if ch == 123:
                depth = depth + 1
            else if ch == 125:
                depth = depth - 1
            pos = pos + 1
        let block = response.slice(block_start as i64, pos as i64)
        let has_os = conan_block_matches_setting(block, "os", target_os)
        let has_arch = conan_block_matches_setting(block, "arch", target_arch)
        if has_os and has_arch:
            let shared = conan_block_shared(block)
            if not shared:
                return ConanPackagePick { package_id: pkg_id, shared }
            if best_id.len() == 0:
                best_id = pkg_id
                best_shared = shared
    ConanPackagePick { package_id: best_id, shared: best_shared }

fn conan_get_latest_package_rev(name: str, version: str, rev: str, pkg_id: str) -> str:
    let latest_url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/packages/" ++ pkg_id ++ "/latest"
    let latest = conan_http_get(latest_url)
    if latest.len() == 0:
        return ""
    json_extract_string(latest, "revision")

fn conan_package_file_url(name: str, version: str, rev: str, pkg_id: str, pkg_rev: str, file_name: str) -> str:
    CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/packages/" ++ pkg_id ++ "/revisions/" ++ pkg_rev ++ "/files/" ++ file_name

fn conan_parse_requires_from_info(info: str) -> Vec[str]:
    let requires: Vec[str] = Vec.new()
    let lines = conan_split_nonempty_lines(info)
    var in_requires = false
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.starts_with("["):
            in_requires = line == "[requires]"
            continue
        if in_requires:
            requires.push(line)
    requires

fn conan_ref_name(req: str) -> str:
    let slash = conan_find_char(req, 47)
    if slash <= 0:
        return ""
    req.slice(0, slash as i64)

fn conan_ref_version(req: str) -> str:
    let slash = conan_find_char(req, 47)
    if slash <= 0:
        return ""
    var end = req.len() as i32
    let at = conan_find_char(req, 64)
    if at > slash:
        end = at
    req.slice((slash + 1) as i64, end as i64)

fn conan_json_escape(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 34 or ch == 92:
            out = out ++ "\\"
        out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn conan_json_array(values: &Vec[str]) -> str:
    let q = "\x22"
    var out = "["
    for i in 0..values.len() as i32:
        if i > 0:
            out = out ++ ", "
        out = out ++ q ++ conan_json_escape(values.get(i as i64)) ++ q
    out ++ "]"

fn conan_write_metadata(dest_dir: str, name: str, version: str, recipe_rev: str, package_id: str, package_rev: str, include_paths: Vec[str], lib_paths: Vec[str], libs: Vec[str], defines: Vec[str], link_args: Vec[str], requires: Vec[str]) -> i32:
    let q = "\x22"
    let nl = "\n"
    var meta = "{" ++ nl
    meta = meta ++ "  " ++ q ++ "name" ++ q ++ ": " ++ q ++ conan_json_escape(name) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "version" ++ q ++ ": " ++ q ++ conan_json_escape(version) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "recipe_revision" ++ q ++ ": " ++ q ++ conan_json_escape(recipe_rev) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "package_id" ++ q ++ ": " ++ q ++ conan_json_escape(package_id) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "package_revision" ++ q ++ ": " ++ q ++ conan_json_escape(package_rev) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "include_paths" ++ q ++ ": " ++ conan_json_array(&include_paths) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "lib_paths" ++ q ++ ": " ++ conan_json_array(&lib_paths) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "libs" ++ q ++ ": " ++ conan_json_array(&libs) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "defines" ++ q ++ ": " ++ conan_json_array(&defines) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "link_args" ++ q ++ ": " ++ conan_json_array(&link_args) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "requires" ++ q ++ ": " ++ conan_json_array(&requires) ++ nl
    meta = meta ++ "}" ++ nl
    runtime_write_file(dest_dir ++ "/metadata.json", meta)

fn conan_library_name_from_path(path: str) -> str:
    let base = conan_path_basename(path)
    var name = ""
    if base.ends_with(".a"):
        name = base.slice(0, base.len() - 2)
    else if base.ends_with(".lib"):
        name = base.slice(0, base.len() - 4)
    else:
        let dylib = conan_find_text(base, ".dylib")
        let so = conan_find_text(base, ".so")
        if dylib > 0:
            name = base.slice(0, dylib as i64)
        else if so > 0:
            name = base.slice(0, so as i64)
    if name.starts_with("lib") and name.len() > 3:
        return name.slice(3, name.len())
    name

fn conan_is_link_library_path(path: str) -> bool:
    let base = conan_path_basename(path)
    if base.ends_with(".lib"):
        return true
    if base.starts_with("lib") and base.len() > 3:
        if base.ends_with(".a") or base.ends_with(".dylib"):
            return true
        if conan_find_text(base, ".so") > 0:
            return true
    false

fn conan_scan_libraries(dep_dir: str) -> ConanLibraryScan:
    var lib_paths: Vec[str] = Vec.new()
    var libs: Vec[str] = Vec.new()
    let listing = runtime_list_files(dep_dir)
    let files = conan_split_nonempty_lines(listing)
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if conan_is_link_library_path(path):
            let lib = conan_library_name_from_path(path)
            if lib.len() > 0:
                libs = conan_sorted_insert_unique(move libs, lib)
                lib_paths = conan_sorted_insert_unique(move lib_paths, conan_relative_path(dep_dir, conan_path_dirname(path)))
    ConanLibraryScan { lib_paths, libs }

// ── Recipe package_info extraction (#550) ────────────────────────────
//
// Conan recipes declare system link requirements in package_info() as
// cpp_info system_libs / frameworks assignments. The compiler cannot run
// Python, but the common declarations are simple enough to read directly:
// indentation-scoped if/elif/else on self.settings.os (or is_apple_os),
// and = / append / extend with string-literal lists. Anything the reader
// cannot resolve — option-dependent conditions, computed values,
// multi-line lists — is skipped, never guessed: under-linking fails
// loudly at link time, and conan_known_link_metadata remains the
// override for packages whose recipes are too dynamic to read.

fn conan_recipe_line_indent(line: str) -> i32:
    var i = 0
    while i < line.len() as i32 and line.byte_at(i as i64) == 32:
        i = i + 1
    i

fn conan_recipe_extract_quoted(text: str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var i = 0
    let n = text.len() as i32
    while i < n:
        let ch = text.byte_at(i as i64)
        if ch == 34 or ch == 39:
            var j = i + 1
            while j < n and text.byte_at(j as i64) != ch:
                j = j + 1
            if j < n:
                out.push(text.slice((i + 1) as i64, j as i64))
                i = j
        i = i + 1
    out

// Evaluate a package_info condition against the target OS.
// Returns 1 (true), 0 (false), or -1 (unresolvable).
fn conan_recipe_eval_condition(cond_raw: str, target_os: str) -> i32:
    var cond = conan_trim(cond_raw)
    while cond.len() >= 2 and cond.byte_at(0) == 40 and cond.byte_at(cond.len() - 1) == 41:
        cond = conan_trim(cond.slice(1, cond.len() - 1))
    if conan_find_text(cond, " and ") >= 0 or conan_find_text(cond, " or ") >= 0:
        return -1
    if cond == "is_apple_os(self)":
        return if target_os == "Macos": 1 else: 0
    if conan_find_text(cond, "self.settings.os") < 0:
        return -1
    let quoted = conan_recipe_extract_quoted(cond)
    if quoted.len() == 0:
        return -1
    if conan_find_text(cond, " not in ") >= 0:
        return if conan_vec_contains(quoted, target_os): 0 else: 1
    if conan_find_text(cond, " in ") >= 0 or conan_find_text(cond, " in[") >= 0:
        return if conan_vec_contains(quoted, target_os): 1 else: 0
    if conan_find_text(cond, "!=") >= 0:
        if quoted.len() as i32 != 1:
            return -1
        return if quoted.get(0) == target_os: 0 else: 1
    if conan_find_text(cond, "==") >= 0:
        if quoted.len() as i32 != 1:
            return -1
        return if quoted.get(0) == target_os: 1 else: 0
    -1

// Pull the string values out of an attribute line:
//   ... .system_libs = ["a", "b"]
//   ... .frameworks.append("X")
//   ... .system_libs.extend(["a", "b"])
// Returns an empty Vec when the right-hand side cannot be read safely.
fn conan_recipe_attr_values(line: str, attr_pos: i32) -> Vec[str]:
    let rhs = line.slice(attr_pos as i64, line.len())
    // Python conditional expressions and multi-line lists are unresolvable.
    if conan_find_text(rhs, " if ") >= 0:
        return Vec.new()
    var opens = 0
    var closes = 0
    for i in 0..rhs.len() as i32:
        let ch = rhs.byte_at(i as i64)
        if ch == 91: opens = opens + 1
        if ch == 93: closes = closes + 1
    if opens != closes:
        return Vec.new()
    conan_recipe_extract_quoted(rhs)

// Read system_libs and frameworks for target_os from a recipe's
// package_info(). Frameworks are returned as ("-framework", name) link
// argument pairs in lib_paths, matching conan_known_link_metadata.
pub fn conan_extract_recipe_link_metadata(recipe: str, target_os: str) -> ConanLibraryScan:
    var sys_libs: Vec[str] = Vec.new()
    var fw_args: Vec[str] = Vec.new()
    var fw_seen: Vec[str] = Vec.new()

    // Parallel frames for nested if/elif/else blocks. Indents are stored
    // as i32; chain_* carry whether an earlier branch of the same chain
    // was taken or unresolvable.
    var frame_indent: Vec[i64] = Vec.new()
    var frame_active: Vec[i64] = Vec.new()
    var frame_unknown: Vec[i64] = Vec.new()
    var frame_chain_taken: Vec[i64] = Vec.new()
    var frame_chain_unknown: Vec[i64] = Vec.new()

    var in_body = false
    var def_indent = 0

    var pos = 0
    let total = recipe.len() as i32
    while pos < total:
        var line_end = pos
        while line_end < total and recipe.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        let raw_line = recipe.slice(pos as i64, line_end as i64)
        pos = line_end + 1

        let stripped = conan_trim(raw_line)
        if stripped.len() == 0 or stripped.byte_at(0) == 35:
            continue
        let indent = conan_recipe_line_indent(raw_line)

        if not in_body:
            if stripped.starts_with("def package_info("):
                in_body = true
                def_indent = indent
            continue
        if indent <= def_indent:
            break

        // Close blocks this line is no longer inside; remember the chain
        // state of a same-indent frame for elif/else continuation.
        var popped_same_indent = false
        var prev_chain_taken = false
        var prev_chain_unknown = false
        while frame_indent.len() > 0:
            let top = frame_indent.len() - 1
            let top_indent = frame_indent.get(top)
            if top_indent < indent as i64:
                break
            if top_indent == indent as i64:
                popped_same_indent = true
                prev_chain_taken = frame_chain_taken.get(top) != 0
                prev_chain_unknown = frame_chain_unknown.get(top) != 0
            let _a = frame_indent.pop()
            let _b = frame_active.pop()
            let _c = frame_unknown.pop()
            let _d = frame_chain_taken.pop()
            let _e = frame_chain_unknown.pop()

        if stripped.starts_with("if ") and stripped.ends_with(":"):
            let r = conan_recipe_eval_condition(stripped.slice(3, stripped.len() - 1), target_os)
            frame_indent.push(indent as i64)
            frame_active.push(if r == 1: 1 else: 0)
            frame_unknown.push(if r == -1: 1 else: 0)
            frame_chain_taken.push(if r == 1: 1 else: 0)
            frame_chain_unknown.push(if r == -1: 1 else: 0)
            continue
        if stripped.starts_with("elif ") and stripped.ends_with(":"):
            if not popped_same_indent:
                // Malformed chain: treat the rest of it as unresolvable.
                prev_chain_taken = false
                prev_chain_unknown = true
            let r = conan_recipe_eval_condition(stripped.slice(5, stripped.len() - 1), target_os)
            let active = r == 1 and not prev_chain_taken and not prev_chain_unknown
            let unknown = not prev_chain_taken and (prev_chain_unknown or r == -1)
            frame_indent.push(indent as i64)
            frame_active.push(if active: 1 else: 0)
            frame_unknown.push(if unknown: 1 else: 0)
            frame_chain_taken.push(if prev_chain_taken or r == 1: 1 else: 0)
            frame_chain_unknown.push(if prev_chain_unknown or r == -1: 1 else: 0)
            continue
        if stripped == "else:":
            if not popped_same_indent:
                prev_chain_taken = false
                prev_chain_unknown = true
            let active = not prev_chain_taken and not prev_chain_unknown
            let unknown = not prev_chain_taken and prev_chain_unknown
            frame_indent.push(indent as i64)
            frame_active.push(if active: 1 else: 0)
            frame_unknown.push(if unknown: 1 else: 0)
            frame_chain_taken.push(1)
            frame_chain_unknown.push(if prev_chain_unknown: 1 else: 0)
            continue

        // Statement line: collect only when every enclosing branch is
        // known-taken.
        var collectible = true
        for i in 0..frame_indent.len() as i32:
            if frame_active.get(i as i64) == 0 or frame_unknown.get(i as i64) != 0:
                collectible = false
        if not collectible:
            continue
        if conan_find_text(stripped, "cpp_info") < 0:
            continue
        let sys_pos = conan_find_text(stripped, ".system_libs")
        let fw_pos = conan_find_text(stripped, ".frameworks")
        if sys_pos >= 0:
            let values = conan_recipe_attr_values(stripped, sys_pos + 12)
            for i in 0..values.len() as i32:
                sys_libs = conan_sorted_insert_unique(move sys_libs, values.get(i as i64))
        else if fw_pos >= 0:
            let values = conan_recipe_attr_values(stripped, fw_pos + 11)
            for i in 0..values.len() as i32:
                let fw = values.get(i as i64)
                if not conan_vec_contains(fw_seen, fw):
                    fw_seen.push(fw)
                    fw_args.push("-framework")
                    fw_args.push(fw)

    ConanLibraryScan { lib_paths: fw_args, libs: sys_libs }

fn conan_fetch_recipe_text(name: str, version: str) -> str:
    let folder = conan_recipe_folder(name, version)
    if folder.len() == 0:
        return ""
    conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py"))

// Packages whose link metadata is still hand-maintained. The table wins
// over recipe extraction for these; the goal is to shrink this list as
// extraction proves itself per package (#550).
fn conan_package_has_table_link_metadata(name: str, version: str) -> bool:
    if name == "opengl" and version == "system":
        return true
    if name == "glfw":
        return true
    if name == "raylib":
        return true
    if name == "xorg" and version == "system":
        return true
    false

fn conan_link_metadata_with_recipe(name: str, version: str, libs: Vec[str], link_args: Vec[str], recipe: str) -> ConanLibraryScan:
    if conan_package_has_table_link_metadata(name, version):
        return conan_known_link_metadata(name, version, libs, link_args)
    if recipe.len() == 0:
        runtime_eprint("warning: no recipe metadata for " ++ name ++ "/" ++ version ++ "; system link requirements may be incomplete")
        return conan_known_link_metadata(name, version, libs, link_args)
    let extracted = conan_extract_recipe_link_metadata(recipe, conan_detect_os())
    var out_libs = libs
    var out_args = link_args
    for i in 0..extracted.libs.len() as i32:
        out_libs = conan_sorted_insert_unique(move out_libs, extracted.libs.get(i as i64))
    for i in 0..extracted.lib_paths.len() as i32:
        out_args.push(extracted.lib_paths.get(i as i64))
    ConanLibraryScan { lib_paths: out_args, libs: out_libs }

fn conan_known_link_metadata(name: str, version: str, libs: Vec[str], link_args: Vec[str]) -> ConanLibraryScan:
    let os = conan_detect_os()
    var out_libs = libs
    var out_args = link_args
    if name == "opengl" and version == "system":
        if os == "Macos":
            out_args.push("-framework")
            out_args.push("OpenGL")
        else if os == "Windows":
            out_libs = conan_sorted_insert_unique(move out_libs, "opengl32")
        else if os == "Linux":
            out_libs = conan_sorted_insert_unique(move out_libs, "GL")
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }

    if name == "glfw":
        if os == "Macos":
            let frameworks: Vec[str] = Vec.new()
            frameworks.push("AppKit")
            frameworks.push("Cocoa")
            frameworks.push("CoreFoundation")
            frameworks.push("CoreGraphics")
            frameworks.push("CoreServices")
            frameworks.push("Foundation")
            frameworks.push("IOKit")
            for i in 0..frameworks.len() as i32:
                out_args.push("-framework")
                out_args.push(frameworks.get(i as i64))
        else if os == "Linux":
            out_libs = conan_sorted_insert_unique(move out_libs, "m")
            out_libs = conan_sorted_insert_unique(move out_libs, "pthread")
            out_libs = conan_sorted_insert_unique(move out_libs, "dl")
            out_libs = conan_sorted_insert_unique(move out_libs, "rt")
        else if os == "Windows":
            out_libs = conan_sorted_insert_unique(move out_libs, "gdi32")
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }

    if name == "raylib":
        if os == "Linux":
            out_libs = conan_sorted_insert_unique(move out_libs, "m")
            out_libs = conan_sorted_insert_unique(move out_libs, "pthread")
        else if os == "Windows":
            out_libs = conan_sorted_insert_unique(move out_libs, "winmm")
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }

    if name == "xorg" and version == "system" and os == "Linux":
        let xlibs: Vec[str] = Vec.new()
        xlibs.push("X11")
        xlibs.push("Xrandr")
        xlibs.push("Xinerama")
        xlibs.push("Xi")
        xlibs.push("Xcursor")
        xlibs.push("Xext")
        xlibs.push("Xfixes")
        for i in 0..xlibs.len() as i32:
            out_libs = conan_sorted_insert_unique(move out_libs, xlibs.get(i as i64))
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }
    ConanLibraryScan { lib_paths: out_args, libs: out_libs }

pub fn conan_write_known_system_package(name: str, version: str, project_root: str) -> bool:
    if version != "system":
        return false
    if name != "opengl" and name != "xorg":
        return false
    let dep_dir = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version
    let _clean = runtime_remove_tree(dep_dir)
    if runtime_mkdir_p(dep_dir) != 0:
        runtime_eprint("error: failed to create dependency directory for " ++ name ++ "/" ++ version)
        return false
    let include_paths: Vec[str] = Vec.new()
    let lib_paths: Vec[str] = Vec.new()
    var libs: Vec[str] = Vec.new()
    var defines: Vec[str] = Vec.new()
    var link_args: Vec[str] = Vec.new()
    if name == "opengl" and conan_detect_os() == "Macos":
        defines = conan_sorted_insert_unique(move defines, "GL_SILENCE_DEPRECATION=1")
    let known = conan_known_link_metadata(name, version, libs, link_args)
    let known_libs = known.libs
    let known_link_args = known.lib_paths
    let requires: Vec[str] = Vec.new()
    conan_write_metadata(dep_dir, name, version, "system", "system", "system", include_paths, lib_paths, known_libs, defines, known_link_args, requires) == 0

fn conan_resolve_and_install_requirements(requirements: Vec[str], project_root: str, depth: i32, force_reinstall: bool) -> Vec[str]:
    let resolved: Vec[str] = Vec.new()
    for i in 0..requirements.len() as i32:
        let req = requirements.get(i as i64)
        let req_name = conan_ref_name(req)
        let req_hint = conan_ref_version(req)
        if req_name.len() == 0 or req_hint.len() == 0:
            runtime_eprint("error: unsupported Conan requirement reference: " ++ req)
            return Vec.new()
        let actual = conan_install_internal(req_name, req_hint, project_root, depth + 1, force_reinstall)
        if actual.len() == 0:
            return Vec.new()
        resolved.push(req_name ++ "/" ++ actual)
    resolved

fn conan_write_binary_metadata(name: str, version: str, recipe_rev: str, package_id: str, package_rev: str, dep_dir: str, requirements: Vec[str]) -> i32:
    var include_paths: Vec[str] = Vec.new()
    if runtime_is_dir(dep_dir ++ "/include") != 0:
        include_paths.push("include")
    let scan = conan_scan_libraries(dep_dir)
    var lib_paths = scan.lib_paths
    var libs = scan.libs
    if libs.len() == 0:
        libs.push(name)
        if runtime_is_dir(dep_dir ++ "/lib") != 0:
            lib_paths.push("lib")
    let defines: Vec[str] = Vec.new()
    let link_args: Vec[str] = Vec.new()
    let known = conan_link_metadata_with_recipe(name, version, libs, link_args, conan_fetch_recipe_text(name, version))
    conan_write_metadata(dep_dir, name, version, recipe_rev, package_id, package_rev, include_paths, lib_paths, known.libs, defines, known.lib_paths, requirements)

pub fn conan_restore_locked_binary_package(name: str, version: str, recipe_rev: str, package_id: str, package_rev: str, expected_sha256: str, project_root: str) -> bool:
    let dep_dir = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version
    let _clean = runtime_remove_tree(dep_dir)
    if runtime_mkdir_p(dep_dir) != 0:
        runtime_eprint("error: failed to create dependency directory for " ++ name ++ "/" ++ version)
        return false
    let info_url = conan_package_file_url(name, version, recipe_rev, package_id, package_rev, "conaninfo.txt")
    let info = conan_http_get(info_url)
    if info.len() == 0:
        runtime_eprint("error: failed to download pinned conaninfo.txt for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return false
    let tgz_url = conan_package_file_url(name, version, recipe_rev, package_id, package_rev, "conan_package.tgz")
    let tgz_path = dep_dir ++ "/conan_package.tgz"
    runtime_eprint("  restoring pinned " ++ name ++ "/" ++ version ++ "...")
    if conan_http_download(tgz_url, tgz_path) != 0:
        runtime_eprint("error: failed to download pinned package for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return false
    let actual_sha256 = conan_sha256_file(tgz_path)
    if actual_sha256 != expected_sha256:
        runtime_eprint("error: hash mismatch for c." ++ name ++ "@" ++ version ++ ": expected " ++ expected_sha256 ++ ", got " ++ actual_sha256)
        let _remove = runtime_remove_tree(dep_dir)
        return false
    runtime_eprint("  extracting...")
    if conan_extract_tgz(tgz_path, dep_dir) != 0:
        runtime_eprint("error: failed to extract pinned package for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return false
    let requirements = conan_parse_requires_from_info(info)
    if conan_write_binary_metadata(name, version, recipe_rev, package_id, package_rev, dep_dir, requirements) != 0:
        runtime_eprint("error: failed to write metadata for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return false
    true

fn conan_install_binary(name: str, version: str, recipe_rev: str, project_root: str, depth: i32, force_reinstall: bool) -> str:
    let pick = conan_find_matching_package(name, version, recipe_rev)
    if pick.package_id.len() == 0:
        return ""
    runtime_eprint("  binary: " ++ pick.package_id.slice(0, if pick.package_id.len() > 12: 12 else: pick.package_id.len()))
    let package_rev = conan_get_latest_package_rev(name, version, recipe_rev, pick.package_id)
    if package_rev.len() == 0:
        runtime_eprint("error: failed to get package revision for " ++ name ++ "/" ++ version)
        return ""
    let dep_dir = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version
    let _clean = runtime_remove_tree(dep_dir)
    if runtime_mkdir_p(dep_dir) != 0:
        runtime_eprint("error: failed to create dependency directory for " ++ name ++ "/" ++ version)
        return ""
    let info_url = conan_package_file_url(name, version, recipe_rev, pick.package_id, package_rev, "conaninfo.txt")
    let info = conan_http_get(info_url)
    if info.len() == 0:
        runtime_eprint("error: failed to download conaninfo.txt for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    let requirements = conan_parse_requires_from_info(info)
    let resolved_requirements = conan_resolve_and_install_requirements(requirements, project_root, depth, force_reinstall)
    if requirements.len() > 0 and resolved_requirements.len() == 0:
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    let tgz_url = conan_package_file_url(name, version, recipe_rev, pick.package_id, package_rev, "conan_package.tgz")
    let tgz_path = dep_dir ++ "/conan_package.tgz"
    runtime_eprint("  downloading " ++ name ++ "/" ++ version ++ "...")
    if conan_http_download(tgz_url, tgz_path) != 0:
        runtime_eprint("error: failed to download package for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    runtime_eprint("  extracting...")
    if conan_extract_tgz(tgz_path, dep_dir) != 0:
        runtime_eprint("error: failed to extract package for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    if conan_write_binary_metadata(name, version, recipe_rev, pick.package_id, package_rev, dep_dir, resolved_requirements) != 0:
        runtime_eprint("error: failed to write metadata for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    runtime_eprint("  installed to .with/deps/c/" ++ name ++ "/" ++ version ++ "/")
    version

fn conan_recipe_config_url(name: str) -> str:
    CONAN_INDEX_RAW() ++ "/" ++ name ++ "/config.yml"

fn conan_recipe_file_url(name: str, folder: str, file_name: str) -> str:
    CONAN_INDEX_RAW() ++ "/" ++ name ++ "/" ++ folder ++ "/" ++ file_name

fn conan_recipe_folder(name: str, version: str) -> str:
    let config = conan_http_get(conan_recipe_config_url(name))
    if config.len() == 0:
        return ""
    let lines = conan_split_nonempty_lines(config)
    var in_version = false
    let version_line_a = "\"" ++ version ++ "\":"
    let version_line_b = version ++ ":"
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line == version_line_a or line == version_line_b:
            in_version = true
        else if in_version and line.starts_with("folder:"):
            return conan_strip_quotes(line.slice(7, line.len()))
        else if in_version and line.ends_with(":") and not line.starts_with("folder:"):
            break
    ""

fn conan_source_url_from_data(data: str, version: str) -> str:
    let lines = conan_split_nonempty_lines(data)
    var in_version = false
    let version_line_a = "\"" ++ version ++ "\":"
    let version_line_b = version ++ ":"
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line == version_line_a or line == version_line_b:
            in_version = true
        else if in_version and line.starts_with("url:"):
            return conan_strip_quotes(line.slice(4, line.len()))
        else if in_version and line.ends_with(":") and not line.starts_with("url:"):
            break
    ""

fn conan_version_has_patches(data: str, version: str) -> bool:
    let patch_pos = conan_find_text(data, "patches:")
    if patch_pos < 0:
        return false
    let after = data.slice(patch_pos as i64, data.len())
    after.contains("\"" ++ version ++ "\":") or after.contains(version ++ ":")

fn conan_source_unsupported_recipe(recipe: str) -> bool:
    recipe.contains("self.requires(") or recipe.contains("apply_conandata_patches") or recipe.contains("configure(")

fn conan_collect_c_sources_and_headers(source_dir: str) -> ConanLibraryScan:
    let listing = runtime_list_files(source_dir)
    let files = conan_split_nonempty_lines(listing)
    var c_files: Vec[str] = Vec.new()
    var header_dirs: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".c"):
            c_files = conan_sorted_insert_unique(move c_files, path)
        else if path.ends_with(".h"):
            header_dirs = conan_sorted_insert_unique(move header_dirs, conan_path_dirname(path))
    ConanLibraryScan { lib_paths: header_dirs, libs: c_files }

fn conan_c_compiler -> str:
    let cc = runtime_getenv("CC")
    if cc.len() > 0:
        return cc
    "cc"

fn conan_compile_c_source(source: str, obj: str, include_dirs: Vec[str]) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, conan_c_compiler())
    argv = conan_argv_append(argv, "-O2")
    for i in 0..include_dirs.len() as i32:
        argv = conan_argv_append(argv, "-I" ++ include_dirs.get(i as i64))
    argv = conan_argv_append(argv, "-c")
    argv = conan_argv_append(argv, source)
    argv = conan_argv_append(argv, "-o")
    argv = conan_argv_append(argv, obj)
    runtime_exec_argv_capture(argv, "/dev/null", "/dev/null", 120000)

fn conan_install_source_fallback(name: str, version: str, project_root: str) -> str:
    let folder = conan_recipe_folder(name, version)
    if folder.len() == 0:
        runtime_eprint("error: no prebuilt binary for your platform, source build not supported for " ++ name ++ "/" ++ version)
        return ""
    let conandata = conan_http_get(conan_recipe_file_url(name, folder, "conandata.yml"))
    if conandata.len() == 0:
        runtime_eprint("error: no prebuilt binary for your platform, source build not supported for " ++ name ++ "/" ++ version)
        return ""
    if conan_version_has_patches(conandata, version):
        runtime_eprint("error: no prebuilt binary for your platform, source build not supported for " ++ name ++ "/" ++ version)
        return ""
    let recipe = conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py"))
    if recipe.len() == 0 or conan_source_unsupported_recipe(recipe):
        runtime_eprint("error: no prebuilt binary for your platform, source build not supported for " ++ name ++ "/" ++ version)
        return ""
    let source_url = conan_source_url_from_data(conandata, version)
    if source_url.len() == 0:
        runtime_eprint("error: no prebuilt binary for your platform, source build not supported for " ++ name ++ "/" ++ version)
        return ""
    let dep_dir = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version
    let _clean = runtime_remove_tree(dep_dir)
    let source_dir = dep_dir ++ "/source"
    let obj_dir = dep_dir ++ "/obj"
    let lib_dir = dep_dir ++ "/lib"
    if runtime_mkdir_p(source_dir) != 0 or runtime_mkdir_p(obj_dir) != 0 or runtime_mkdir_p(lib_dir) != 0:
        runtime_eprint("error: failed to create dependency directory for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    let archive_path = dep_dir ++ "/source.tgz"
    runtime_eprint("  downloading source for " ++ name ++ "/" ++ version ++ "...")
    if conan_http_download(source_url, archive_path) != 0:
        runtime_eprint("error: failed to download source for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    if conan_extract_tgz_strip1(archive_path, source_dir) != 0:
        runtime_eprint("error: failed to extract source for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    let collected = conan_collect_c_sources_and_headers(source_dir)
    let header_dirs_abs = collected.lib_paths
    let c_files = collected.libs
    if c_files.len() == 0 or header_dirs_abs.len() == 0:
        runtime_eprint("error: no prebuilt binary for your platform, source build not supported for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    var include_paths: Vec[str] = Vec.new()
    include_paths.push("source")
    let include_dirs_abs: Vec[str] = Vec.new()
    include_dirs_abs.push(source_dir)
    for i in 0..header_dirs_abs.len() as i32:
        let abs = header_dirs_abs.get(i as i64)
        include_dirs_abs.push(abs)
        include_paths = conan_sorted_insert_unique(move include_paths, conan_relative_path(dep_dir, abs))
    let objects: Vec[str] = Vec.new()
    for i in 0..c_files.len() as i32:
        let obj = obj_dir ++ "/" ++ f"{i}.o"
        if conan_compile_c_source(c_files.get(i as i64), obj, include_dirs_abs) != 0:
            runtime_eprint("error: source build failed for " ++ name ++ "/" ++ version ++ "; source build not supported for this package")
            let _remove = runtime_remove_tree(dep_dir)
            return ""
        objects.push(obj)
    let lib_path = lib_dir ++ "/lib" ++ name ++ ".a"
    if create_static_archive(lib_path, objects) != 0:
        runtime_eprint("error: failed to archive source build for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    let lib_paths: Vec[str] = Vec.new()
    lib_paths.push("lib")
    var libs: Vec[str] = Vec.new()
    libs.push(name)
    let defines: Vec[str] = Vec.new()
    let link_args: Vec[str] = Vec.new()
    let known = conan_link_metadata_with_recipe(name, version, libs, link_args, recipe)
    let requires: Vec[str] = Vec.new()
    if conan_write_metadata(dep_dir, name, version, "source", "source", "source", include_paths, lib_paths, known.libs, defines, known.lib_paths, requires) != 0:
        runtime_eprint("error: failed to write metadata for " ++ name ++ "/" ++ version)
        let _remove = runtime_remove_tree(dep_dir)
        return ""
    runtime_eprint("  built source package at .with/deps/c/" ++ name ++ "/" ++ version ++ "/")
    version

fn conan_install_internal(name: str, version_hint: str, project_root: str, depth: i32, force_reinstall: bool) -> str:
    if depth > 8:
        runtime_eprint("error: Conan dependency graph too deep while resolving " ++ name)
        return ""
    let version = conan_resolve_version(name, version_hint)
    if version.len() == 0:
        runtime_eprint("error: package " ++ name ++ "/" ++ version_hint ++ " not found on Conan Center")
        return ""
    let meta_path = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version ++ "/metadata.json"
    if not force_reinstall and runtime_file_exists(meta_path) != 0:
        return version
    if conan_write_known_system_package(name, version, project_root):
        runtime_eprint("  using system package " ++ name ++ "/" ++ version)
        return version
    runtime_eprint("resolving " ++ name ++ "/" ++ version ++ "...")
    let recipe_rev = conan_get_latest_recipe_rev(name, version)
    if recipe_rev.len() == 0:
        runtime_eprint("error: package " ++ name ++ "/" ++ version ++ " not found on Conan Center")
        return ""
    runtime_eprint("  revision: " ++ recipe_rev.slice(0, if recipe_rev.len() > 12: 12 else: recipe_rev.len()))
    let installed_binary = conan_install_binary(name, version, recipe_rev, project_root, depth, force_reinstall)
    if installed_binary.len() > 0:
        return installed_binary
    conan_install_source_fallback(name, version, project_root)

// Public API. Returns the concrete installed version, or "" on failure.
fn conan_install(name: str, version_hint: str, project_root: str, force_reinstall: bool) -> str:
    conan_install_internal(name, version_hint, project_root, 0, force_reinstall)
