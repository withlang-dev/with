// ConanClient — native Conan Center client for C package management.
//
// Uses Conan's v2 REST API directly. No dependency on the conan CLI.

use Archive
use compiler.Runtime
use compiler.ConanRecipe
use compiler.ConanPatch
use compiler.ClangDriver
use std.crypto.sha256
extern fn with_str_clone_ref(s: &str) -> str

fn CONAN_CENTER_URL -> str: "https://center2.conan.io"
fn CONAN_INDEX_RAW -> str: "https://raw.githubusercontent.com/conan-io/conan-center-index/master/recipes"

pub type ConanPackagePick {
    package_id: str,
    shared: bool,
}

type ConanLibraryScan {
    lib_paths: Vec[str],
    libs: Vec[str],
}

fn conan_temp_root() -> str:
    if runtime_sysinfo_os() == "Windows":
        let tmp = runtime_getenv("TMP")
        if tmp.len() > 0: return tmp
        return runtime_getenv("TEMP")
    let tmp = runtime_getenv("TMPDIR")
    if tmp.len() > 0: tmp else: "/tmp"

fn conan_scratch_dir() -> str:
    let base = conan_temp_root()
    if base.len() == 0:
        runtime_eprint("error: no temporary directory configured for Conan downloads (set TMP or TEMP)")
        return ""
    let scratch = base ++ f"/with-conan-http-{runtime_getpid()}.{runtime_clock_nanos()}"
    if runtime_mkdir_p(scratch) != 0:
        runtime_eprint("error: could not create Conan download directory: " ++ scratch)
        return ""
    scratch

fn conan_run_tool(argv: &str, timeout_ms: i32) -> i32:
    let scratch = conan_scratch_dir()
    if scratch.len() == 0: return -1
    let stdout_path = scratch ++ "/stdout"
    let stderr_path = scratch ++ "/stderr"
    let rc = runtime_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    let output = runtime_read_file(stdout_path)
    let errors = runtime_read_file(stderr_path)
    if output.len() > 0: print(output)
    if errors.len() > 0: runtime_eprint(errors)
    runtime_remove_tree(scratch)
    rc

pub fn conan_http_get(url: &str) -> str:
    let scratch = conan_scratch_dir()
    if scratch.len() == 0: return ""
    let tmp = scratch ++ "/response.json"
    let rc = conan_curl_to_file(url, tmp, 300000)
    if rc != 0:
        runtime_remove_tree(scratch)
        return ""
    let body = runtime_read_file(tmp)
    runtime_remove_tree(scratch)
    body

fn conan_http_download(url: &str, path: &str) -> i32:
    conan_curl_to_file(url, path, 300000)

fn conan_sha256_file(path: &str) -> str:
    if runtime_file_exists(path) == 0:
        return ""
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(runtime_read_file(path), &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

fn conan_argv_append(argv: &str, arg: &str) -> str:
    argv ++ arg ++ "\0"

fn conan_curl_to_file(url: &str, path: &str, timeout_ms: i32) -> i32:
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
    let rc = conan_run_tool(argv, timeout_ms)
    if rc != 0:
        runtime_eprint(f"error: Conan download failed (curl exit {rc}): " ++ url ++ " -> " ++ path)
    rc

fn conan_extract_tgz(archive: &str, dest: &str) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, "tar")
    argv = conan_argv_append(argv, "xzf")
    argv = conan_argv_append(argv, archive)
    argv = conan_argv_append(argv, "-C")
    argv = conan_argv_append(argv, dest)
    conan_run_tool(argv, 120000)

fn conan_extract_tgz_strip1(archive: &str, dest: &str) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, "tar")
    argv = conan_argv_append(argv, "xzf")
    argv = conan_argv_append(argv, archive)
    argv = conan_argv_append(argv, "-C")
    argv = conan_argv_append(argv, dest)
    argv = conan_argv_append(argv, "--strip-components=1")
    conan_run_tool(argv, 120000)

fn conan_str_compare(a: &str, b: &str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        let ca = a[i] as i32
        let cb = b[i] as i32
        if ca < cb:
            return -1
        if ca > cb:
            return 1
    if a.len() < b.len():
        return -1
    if a.len() > b.len():
        return 1
    0

fn conan_vec_contains(values: &Vec[str], value: &str) -> bool:
    for i in 0..values.len() as i32:
        if values[i] == value:
            return true
    false

fn conan_sorted_insert_unique(values: Vec[str], value: &str) -> Vec[str]:
    if value.len() == 0 or conan_vec_contains(values, value):
        return values
    let out: Vec[str] = Vec.new()
    var inserted = false
    for i in 0..values.len() as i32:
        let existing = values[i]
        if not inserted and conan_str_compare(value, existing) < 0:
            out.push(with_str_clone_ref(value))
            inserted = true
        out.push(with_str_clone_ref(existing))
    if not inserted:
        out.push(with_str_clone_ref(value))
    out

fn conan_trim(text: &str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text[start]
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        start = start + 1
    while end > start:
        let ch = text[(end - 1)]
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn conan_strip_quotes(value: &str) -> str:
    let t = conan_trim(value)
    if t.len() >= 2 and t[0] == 34 and t[t.len() - 1] == 34:
        return t.slice(1, t.len() - 1)
    t

fn conan_find_char(text: &str, ch: i32) -> i32:
    for i in 0..text.len() as i32:
        if text[i] == ch:
            return i
    -1

fn conan_find_text(text: &str, needle: &str) -> i32:
    if needle.len() == 0:
        return 0
    let n = text.len() as i32
    let m = needle.len() as i32
    var i = 0
    while i <= n - m:
        var ok = true
        for j in 0..m:
            if text[(i + j)] != needle[j]:
                ok = false
                break
        if ok:
            return i
        i = i + 1
    -1

fn conan_path_basename(path: &str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        if path[i] == 47:
            start = i + 1
    path.slice(start as i64, path.len())

fn conan_path_dirname(path: &str) -> str:
    var slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            slash = i
    if slash < 0:
        return "."
    path.slice(0, slash as i64)

fn conan_relative_path(base: &str, path: &str) -> str:
    if path == base:
        return "."
    let prefix = base ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    with_str_clone_ref(path)

fn conan_split_nonempty_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let n = text.len() as i32
    var start = 0
    var i = 0
    while i <= n:
        let at_end = i == n
        let ch = if at_end: 10 else: text[i]
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line[line.len() - 1] == 13:
                line = line.slice(0, line.len() - 1)
            line = conan_trim(line)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn json_extract_string(json: &str, key: &str) -> str:
    let needle = "\"" ++ key ++ "\""
    let json_len = json.len() as i32
    var pos = 0
    while pos < json_len - needle.len() as i32:
        var found = true
        for ni in 0..needle.len() as i32:
            if json[(pos + ni)] != needle[ni]:
                found = false
                break
        if found:
            var vi = pos + needle.len() as i32
            while vi < json_len and json[vi] != 58:
                vi = vi + 1
            while vi < json_len and json[vi] != 34:
                vi = vi + 1
            if vi >= json_len:
                return ""
            vi = vi + 1
            let start = vi
            var escaped = false
            while vi < json_len:
                let ch = json[vi]
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

fn json_extract_string_array(json: &str, key: &str) -> Vec[str]:
    var result: Vec[str] = Vec.new()
    let needle = "\"" ++ key ++ "\""
    let json_len = json.len() as i32
    var pos = 0
    while pos < json_len - needle.len() as i32:
        var found = true
        for ni in 0..needle.len() as i32:
            if json[(pos + ni)] != needle[ni]:
                found = false
                break
        if found:
            var ai = pos + needle.len() as i32
            while ai < json_len and json[ai] != 91:
                ai = ai + 1
            if ai >= json_len:
                return result
            ai = ai + 1
            while ai < json_len and json[ai] != 93:
                if json[ai] == 34:
                    let start = ai + 1
                    var end = start
                    var escaped = false
                    while end < json_len:
                        let ch = json[end]
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

fn conan_version_compare(a: &str, b: &str) -> i32:
    var ai = 0
    var bi = 0
    let an = a.len() as i32
    let bn = b.len() as i32
    while ai < an or bi < bn:
        while ai < an and (a[ai] < 48 or a[ai] > 57):
            ai = ai + 1
        while bi < bn and (b[bi] < 48 or b[bi] > 57):
            bi = bi + 1
        var av = 0
        var bv = 0
        var ahas = false
        var bhas = false
        while ai < an and a[ai] >= 48 and a[ai] <= 57:
            ahas = true
            av = av * 10 + (a[ai] - 48)
            ai = ai + 1
        while bi < bn and b[bi] >= 48 and b[bi] <= 57:
            bhas = true
            bv = bv * 10 + (b[bi] - 48)
            bi = bi + 1
        if not ahas and not bhas:
            break
        if av < bv:
            return -1
        if av > bv:
            return 1
    conan_str_compare(a, b)

fn conan_version_matches_hint(version: &str, hint: &str) -> bool:
    if hint.len() == 0:
        return true
    if hint.ends_with(".Z"):
        let prefix = hint.slice(0, hint.len() - 2)
        return version == prefix or version.starts_with(prefix ++ ".")
    version == hint

fn conan_result_version_for_name(result: &str, name: &str) -> str:
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

fn conan_resolve_version(name: &str, version_hint: &str) -> str:
    if version_hint.len() > 0 and not version_hint.ends_with(".Z"):
        return with_str_clone_ref(version_hint)
    let url = CONAN_CENTER_URL() ++ "/v2/conans/search?q=" ++ name
    let response = conan_http_get(url)
    if response.len() == 0:
        return ""
    let results = json_extract_string_array(response, "results")
    var best = ""
    for i in 0..results.len() as i32:
        let version = conan_result_version_for_name(results[i], name)
        if version.len() == 0:
            continue
        if not conan_version_matches_hint(version, version_hint):
            continue
        if best.len() == 0 or conan_version_compare(version, best) > 0:
            best = version
    best

fn conan_get_latest_recipe_rev(name: &str, version: &str) -> str:
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

fn conan_block_matches_setting(block: &str, key: &str, value: &str) -> bool:
    block.contains("\"" ++ key ++ "\" : \"" ++ value ++ "\"") or block.contains("\"" ++ key ++ "\":\"" ++ value ++ "\"")

fn conan_block_shared(block: &str) -> bool:
    block.contains("\"shared\" : \"True\"") or block.contains("\"shared\":\"True\"")

fn conan_find_matching_package(name: &str, version: &str, rev: &str) -> ConanPackagePick:
    let url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/search?list_only=False"
    let response = conan_http_get(url)
    if response.len() == 0:
        return ConanPackagePick { package_id: "", shared: false }
    conan_pick_package(response, conan_detect_os(), conan_detect_arch())

// A binary we can link: built for this os and arch, a Release build when the
// package has build types (a Debug msvc build wants the debug CRT), and on
// Windows an msvc build — `with` links for windows-msvc, and the clang/gcc
// packages there are msys2/MinGW archives (libcrypto.a, not libcrypto.lib).
fn conan_block_is_linkable(block: &str, target_os: &str, target_arch: &str) -> bool:
    if not conan_block_matches_setting(block, "os", target_os) or not conan_block_matches_setting(block, "arch", target_arch): return false
    if block.contains("\"build_type\"") and not conan_block_matches_setting(block, "build_type", "Release"): return false
    target_os != "Windows" or conan_block_matches_setting(block, "compiler", "msvc")

// The first linkable static package of a ConanCenter search listing, else the
// first linkable shared one.
pub fn conan_pick_package(response: &str, target_os: &str, target_arch: &str) -> ConanPackagePick:
    var best_id = ""
    var best_shared = false
    let json_len = response.len() as i32
    var pos = 1
    while pos < json_len:
        if response[pos] != 34:
            pos = pos + 1
            continue
        let id_start = pos + 1
        var id_end = id_start
        while id_end < json_len and response[id_end] != 34:
            id_end = id_end + 1
        let pkg_id = response.slice(id_start as i64, id_end as i64)
        pos = id_end + 1
        while pos < json_len and response[pos] != 123:
            pos = pos + 1
        if pos >= json_len:
            break
        let block_start = pos
        var depth = 1
        pos = pos + 1
        while pos < json_len and depth > 0:
            let ch = response[pos]
            if ch == 123:
                depth = depth + 1
            else if ch == 125:
                depth = depth - 1
            pos = pos + 1
        let block = response.slice(block_start as i64, pos as i64)
        if conan_block_is_linkable(block, target_os, target_arch):
            let shared = conan_block_shared(block)
            if not shared:
                return ConanPackagePick { package_id: pkg_id, shared }
            if best_id.len() == 0:
                best_id = pkg_id
                best_shared = shared
    ConanPackagePick { package_id: best_id, shared: best_shared }

fn conan_get_latest_package_rev(name: &str, version: &str, rev: &str, pkg_id: &str) -> str:
    let latest_url = CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/packages/" ++ pkg_id ++ "/latest"
    let latest = conan_http_get(latest_url)
    if latest.len() == 0:
        return ""
    json_extract_string(latest, "revision")

fn conan_package_file_url(name: &str, version: &str, rev: &str, pkg_id: &str, pkg_rev: &str, file_name: &str) -> str:
    CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ rev ++ "/packages/" ++ pkg_id ++ "/revisions/" ++ pkg_rev ++ "/files/" ++ file_name

fn conan_parse_requires_from_info(info: &str) -> Vec[str]:
    let requires: Vec[str] = Vec.new()
    let lines = conan_split_nonempty_lines(info)
    var in_requires = false
    for i in 0..lines.len() as i32:
        let line = lines[i]
        if line.starts_with("["):
            in_requires = line == "[requires]"
            continue
        if in_requires:
            requires.push(with_str_clone_ref(line))
    requires

fn conan_ref_name(req: &str) -> str:
    let slash = conan_find_char(req, 47)
    if slash <= 0:
        return ""
    req.slice(0, slash as i64)

fn conan_ref_version(req: &str) -> str:
    let slash = conan_find_char(req, 47)
    if slash <= 0:
        return ""
    var end = req.len() as i32
    let at = conan_find_char(req, 64)
    if at > slash:
        end = at
    req.slice((slash + 1) as i64, end as i64)

fn conan_json_escape(value: &str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value[i]
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
        out = out ++ q ++ conan_json_escape(values[i]) ++ q
    out ++ "]"

fn conan_write_metadata(dest_dir: &str, name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, include_paths: &Vec[str], lib_paths: &Vec[str], libs: &Vec[str], defines: &Vec[str], link_args: &Vec[str], requires: &Vec[str]) -> i32:
    let q = "\x22"
    let nl = "\n"
    var meta = "{" ++ nl
    meta = meta ++ "  " ++ q ++ "name" ++ q ++ ": " ++ q ++ conan_json_escape(name) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "version" ++ q ++ ": " ++ q ++ conan_json_escape(version) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "recipe_revision" ++ q ++ ": " ++ q ++ conan_json_escape(recipe_rev) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "package_id" ++ q ++ ": " ++ q ++ conan_json_escape(package_id) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "package_revision" ++ q ++ ": " ++ q ++ conan_json_escape(package_rev) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "include_paths" ++ q ++ ": " ++ conan_json_array(include_paths) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "lib_paths" ++ q ++ ": " ++ conan_json_array(lib_paths) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "libs" ++ q ++ ": " ++ conan_json_array(libs) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "defines" ++ q ++ ": " ++ conan_json_array(defines) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "link_args" ++ q ++ ": " ++ conan_json_array(link_args) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "requires" ++ q ++ ": " ++ conan_json_array(requires) ++ nl
    meta = meta ++ "}" ++ nl
    runtime_write_file(dest_dir ++ "/metadata.json", meta)

pub fn conan_library_name_from_path(path: &str) -> str:
    let base = conan_path_basename(path)
    // Windows linkers append .lib to the supplied name verbatim. The lib
    // prefix convention belongs to Unix -l lookup, not COFF filenames.
    if base.ends_with(".lib"):
        return base.slice(0, base.len() - 4)
    var name = ""
    if base.ends_with(".a"):
        name = base.slice(0, base.len() - 2)
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

fn conan_is_link_library_path(path: &str) -> bool:
    let base = conan_path_basename(path)
    if base.ends_with(".lib"):
        return true
    if base.starts_with("lib") and base.len() > 3:
        if base.ends_with(".a") or base.ends_with(".dylib"):
            return true
        if conan_find_text(base, ".so") > 0:
            return true
    false

fn conan_scan_libraries(dep_dir: &str) -> ConanLibraryScan:
    var lib_paths: Vec[str] = Vec.new()
    var libs: Vec[str] = Vec.new()
    let listing = runtime_list_files(dep_dir)
    let files = conan_split_nonempty_lines(listing)
    for i in 0..files.len() as i32:
        let path = files[i]
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

fn conan_recipe_line_indent(line: &str) -> i32:
    var i = 0
    while i < line.len() as i32 and line[i] == 32:
        i = i + 1
    i

fn conan_recipe_extract_quoted(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var i = 0
    let n = text.len() as i32
    while i < n:
        let ch = text[i]
        if ch == 34 or ch == 39:
            var j = i + 1
            while j < n and text[j] != ch:
                j = j + 1
            if j < n:
                out.push(text.slice((i + 1) as i64, j as i64))
                i = j
        i = i + 1
    out

// Evaluate a package_info condition against the target OS.
// Returns 1 (true), 0 (false), or -1 (unresolvable).
fn conan_recipe_eval_condition(cond_raw: &str, target_os: &str) -> i32:
    var cond = conan_trim(cond_raw)
    while cond.len() >= 2 and cond[0] == 40 and cond[cond.len() - 1] == 41:
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
fn conan_recipe_attr_values(line: &str, attr_pos: i32) -> Vec[str]:
    let rhs = line.slice(attr_pos as i64, line.len())
    // Python conditional expressions and multi-line lists are unresolvable.
    if conan_find_text(rhs, " if ") >= 0:
        return Vec.new()
    var opens = 0
    var closes = 0
    for i in 0..rhs.len() as i32:
        let ch = rhs[i]
        if ch == 91: opens = opens + 1
        if ch == 93: closes = closes + 1
    if opens != closes:
        return Vec.new()
    conan_recipe_extract_quoted(rhs)

// Read system_libs and frameworks for target_os from a recipe's
// package_info(). Frameworks are returned as ("-framework", name) link
// argument pairs in lib_paths, matching conan_known_link_metadata.
pub fn conan_extract_recipe_link_metadata(recipe: &str, target_os: &str) -> ConanLibraryScan:
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
        while line_end < total and recipe[line_end] != 10:
            line_end = line_end + 1
        let raw_line = recipe.slice(pos as i64, line_end as i64)
        pos = line_end + 1

        let stripped = conan_trim(raw_line)
        if stripped.len() == 0 or stripped[0] == 35:
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
            if frame_active[i] == 0 or frame_unknown[i] != 0:
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
                sys_libs = conan_sorted_insert_unique(move sys_libs, values[i])
        else if fw_pos >= 0:
            let values = conan_recipe_attr_values(stripped, fw_pos + 11)
            for i in 0..values.len() as i32:
                let fw = values[i]
                if not conan_vec_contains(fw_seen, fw):
                    fw_seen.push(with_str_clone_ref(fw))
                    fw_args.push("-framework")
                    fw_args.push(with_str_clone_ref(fw))

    ConanLibraryScan { lib_paths: fw_args, libs: sys_libs }

fn conan_fetch_recipe_text(name: &str, version: &str) -> str:
    let folder = conan_recipe_folder(name, version)
    if folder.len() == 0:
        return ""
    conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py"))

// Packages whose link metadata is still hand-maintained. The table wins
// over recipe extraction for these; the goal is to shrink this list as
// extraction proves itself per package (#550).
fn conan_package_has_table_link_metadata(name: &str, version: &str) -> bool:
    if name == "opengl" and version == "system":
        return true
    if name == "glfw":
        return true
    if name == "raylib":
        return true
    if name == "xorg" and version == "system":
        return true
    false

fn conan_link_metadata_with_recipe(name: &str, version: &str, libs: Vec[str], link_args: Vec[str], recipe: &str) -> ConanLibraryScan:
    if conan_package_has_table_link_metadata(name, version):
        return conan_known_link_metadata(name, version, move libs, move link_args)
    if recipe.len() == 0:
        runtime_eprint("warning: no recipe metadata for " ++ name ++ "/" ++ version ++ "; system link requirements may be incomplete")
        return conan_known_link_metadata(name, version, move libs, move link_args)
    let extracted = conan_extract_recipe_link_metadata(recipe, conan_detect_os())
    var out_libs = libs
    var out_args = link_args
    for i in 0..extracted.libs.len() as i32:
        out_libs = conan_sorted_insert_unique(move out_libs, extracted.libs[i])
    for i in 0..extracted.lib_paths.len() as i32:
        out_args.push(with_str_clone_ref(extracted.lib_paths[i]))
    ConanLibraryScan { lib_paths: out_args, libs: out_libs }

fn conan_known_link_metadata(name: &str, version: &str, libs: Vec[str], link_args: Vec[str]) -> ConanLibraryScan:
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
                out_args.push(with_str_clone_ref(frameworks[i]))
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
            out_libs = conan_sorted_insert_unique(move out_libs, xlibs[i])
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }
    ConanLibraryScan { lib_paths: out_args, libs: out_libs }

pub fn conan_write_known_system_package(name: &str, version: &str, project_root: &str) -> bool:
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
    let known = conan_known_link_metadata(name, version, move libs, move link_args)
    let known_libs = known.libs
    let known_link_args = known.lib_paths
    let requires: Vec[str] = Vec.new()
    conan_write_metadata(dep_dir, name, version, "system", "system", "system", include_paths, lib_paths, known_libs, defines, known_link_args, requires) == 0

fn conan_resolve_and_install_requirements(requirements: &Vec[str], project_root: &str, depth: i32, force_reinstall: bool) -> Vec[str]:
    let resolved: Vec[str] = Vec.new()
    for i in 0..requirements.len() as i32:
        let req = requirements[i]
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

fn conan_write_binary_metadata(name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, dep_dir: &str, requirements: &Vec[str]) -> i32:
    var include_paths: Vec[str] = Vec.new()
    if runtime_is_dir(dep_dir ++ "/include") != 0:
        include_paths.push("include")
    var scan = conan_scan_libraries(dep_dir)
    var lib_paths = move scan.lib_paths
    var libs = move scan.libs
    if libs.len() == 0:
        libs.push(with_str_clone_ref(name))
        if runtime_is_dir(dep_dir ++ "/lib") != 0:
            lib_paths.push("lib")
    let defines: Vec[str] = Vec.new()
    let link_args: Vec[str] = Vec.new()
    let known = conan_link_metadata_with_recipe(name, version, move libs, move link_args, conan_fetch_recipe_text(name, version))
    conan_write_metadata(dep_dir, name, version, recipe_rev, package_id, package_rev, include_paths, lib_paths, known.libs, defines, known.lib_paths, requirements)

pub fn conan_restore_locked_binary_package(name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, expected_sha256: &str, project_root: &str) -> bool:
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

fn conan_install_binary(name: &str, version: &str, recipe_rev: &str, project_root: &str, depth: i32, force_reinstall: bool) -> str:
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
    with_str_clone_ref(version)

fn conan_recipe_config_url(name: &str) -> str:
    CONAN_INDEX_RAW() ++ "/" ++ name ++ "/config.yml"

fn conan_recipe_file_url(name: &str, folder: &str, file_name: &str) -> str:
    CONAN_INDEX_RAW() ++ "/" ++ name ++ "/" ++ folder ++ "/" ++ file_name

fn conan_recipe_folder(name: &str, version: &str) -> str:
    let config = conan_http_get(conan_recipe_config_url(name))
    if config.len() == 0:
        return ""
    let lines = conan_split_nonempty_lines(config)
    var in_version = false
    let version_line_a = "\"" ++ version ++ "\":"
    let version_line_b = version ++ ":"
    for i in 0..lines.len() as i32:
        let line = lines[i]
        if line == version_line_a or line == version_line_b:
            in_version = true
        else if in_version and line.starts_with("folder:"):
            return conan_strip_quotes(line.slice(7, line.len()))
        else if in_version and line.ends_with(":") and not line.starts_with("folder:"):
            break
    ""

// ── Building from source ─────────────────────────────────────────────
// `with get --from-source`: skip Conan Center's binaries.
var g_conan_from_source: bool = false

pub fn conan_set_from_source(enabled: bool) -> Unit:
    g_conan_from_source = enabled

// No linkable binary on Conan Center: build the package from source.
//
// Nothing here knows any package. The recipe Conan Center publishes is read as
// data (src/compiler/ConanRecipe.w): conandata.yml gives the tarball, its
// digest and the patches; conanfile.py gives the requirements and the CMake
// variables. The package's own CMake build does the rest, driven by `cmake`
// and `ninja` with `with cc` as the C compiler and `with ar` as the archiver.
// It installs into the dependency directory, which is then scanned exactly as
// an extracted Conan binary is. What the machine lacks is named, not guessed
// around: the user installs it.

fn conan_source_fail(dep_dir: &str, message: &str) -> str:
    runtime_eprint("error: " ++ message)
    if dep_dir.len() > 0:
        let _remove = runtime_remove_tree(dep_dir)
    ""

// This executable, for the `cc` / `ar` / `ranlib` launchers.
fn conan_self_exe() -> str:
    let argv0 = with_arg_at(0)
    if argv0.contains("/") or argv0.contains("\\"): return conan_absolute(argv0)
    conan_find_program(argv0)

// CMake wants absolute paths; a relative one is relative to where we were run.
fn conan_absolute(path: &str) -> str:
    let cwd = runtime_getenv("PWD")
    if runtime_path_is_absolute(path) or cwd.len() == 0: path.to_owned() else: cwd ++ "/" ++ path

// `name` on PATH, or "".
fn conan_find_program(name: &str) -> str:
    let windows = runtime_sysinfo_os() == "Windows"
    for dir in runtime_getenv("PATH").split(if windows: ";" else: ":"):
        if dir.len() == 0: continue
        let candidate = dir ++ "/" ++ name ++ (if windows and not name.ends_with(".exe"): ".exe" else: "")
        if runtime_file_exists(candidate) != 0: return candidate
    ""

// A build tool: WITH_<NAME> names it outright, otherwise PATH.
fn conan_build_tool(name: &str, env_name: &str) -> str:
    let named = runtime_getenv(env_name)
    if named.len() > 0: named else: conan_find_program(name)

// `<dir>/<tool>`: a launcher that runs `<self> <tool> ...`. CMake wants one
// program path for a compiler; `with cc` is two words.
fn conan_write_launcher(dir: &str, tool: &str, self_exe: &str) -> str:
    if runtime_sysinfo_os() == "Windows":
        let path = dir ++ "/" ++ tool ++ ".cmd"
        let _w = runtime_write_file(path, "@\"" ++ self_exe ++ "\" " ++ tool ++ " %*\r\n")
        return path
    let path = dir ++ "/" ++ tool
    let _w = runtime_write_file(path, "#!/bin/sh\nexec \"" ++ self_exe ++ "\" " ++ tool ++ " \"$@\"\n")
    var chmod = ""
    chmod = conan_argv_append(chmod, "chmod")
    chmod = conan_argv_append(chmod, "+x")
    chmod = conan_argv_append(chmod, path)
    let _x = conan_run_tool(chmod, 10000)
    path

// tar reads gzip, xz and bzip2 tarballs, and (bsdtar: macOS, Windows) zip; GNU
// tar does not read zip, so `unzip` is the second try.
fn conan_extract_any(archive: &str, dest: &str) -> i32:
    var argv = ""
    argv = conan_argv_append(argv, "tar")
    argv = conan_argv_append(argv, "xf")
    argv = conan_argv_append(argv, archive)
    argv = conan_argv_append(argv, "-C")
    argv = conan_argv_append(argv, dest)
    if conan_run_tool(argv, 300000) == 0: return 0
    if not archive.ends_with(".zip"): return 1
    var unzip = ""
    unzip = conan_argv_append(unzip, "unzip")
    unzip = conan_argv_append(unzip, "-q")
    unzip = conan_argv_append(unzip, "-o")
    unzip = conan_argv_append(unzip, archive)
    unzip = conan_argv_append(unzip, "-d")
    unzip = conan_argv_append(unzip, dest)
    conan_run_tool(unzip, 300000)

// An archive usually holds one top-level directory; the source is inside it.
fn conan_source_root(raw_dir: &str) -> str:
    var top = ""
    for path in conan_split_nonempty_lines(runtime_list_files(raw_dir)):
        let rel = conan_relative_path(raw_dir, path)
        let slash = rel.find("/")
        if slash <= 0: return raw_dir.to_owned()
        let first = rel.slice(0, slash)
        if top.len() == 0: top = first.to_owned()
        else if top != first: return raw_dir.to_owned()
    if top.len() == 0: raw_dir.to_owned() else: raw_dir ++ "/" ++ top

fn conan_patch_read(path: &str) -> str: runtime_read_file(path)

fn conan_patch_write(path: &str, text: &str) -> i32: runtime_write_file(path, text)

// What the recipe says about a build we cannot drive, for the error.
fn conan_recipe_build_system(recipe: &str) -> str:
    if recipe.contains("Configure") and recipe.contains("perl"): return "its own Configure script, which needs Perl"
    if recipe.contains("Autotools(") or recipe.contains("AutotoolsToolchain"): return "autotools (sh and make)"
    if recipe.contains("Meson("): return "Meson"
    if recipe.contains("MSBuild("): return "MSBuild"
    "a build system other than CMake"

fn conan_install_from_source(name: &str, version: &str, project_root: &str, depth: i32) -> str:
    let platform = conan_detect_os() ++ "/" ++ conan_detect_arch()
    let why = if g_conan_from_source: "--from-source" else: "Conan Center has no binary for " ++ platform ++ " that this toolchain can link"
    runtime_eprint("  " ++ why ++ "; building " ++ name ++ "/" ++ version ++ " from source")
    let folder = conan_recipe_folder(name, version)
    let data = if folder.len() > 0: conan_http_get(conan_recipe_file_url(name, folder, "conandata.yml")) else: ""
    let recipe = if folder.len() > 0: conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py")) else: ""
    if data.len() == 0 or recipe.len() == 0:
        return conan_source_fail("", "could not read the Conan Center recipe of " ++ name ++ "/" ++ version)
    let source = conan_data_source(data, version)
    if source.url.len() == 0 or source.sha256.len() == 0:
        return conan_source_fail("", "the recipe of " ++ name ++ " lists no source archive for " ++ version)
    // A recipe that ships its own CMakeLists.txt exports it; asking for one
    // that is not there is a 404 printed at the user.
    let exports_cmake = recipe.contains("\"CMakeLists.txt\", self.recipe_folder") or recipe.contains("\"CMakeLists.txt\", src=self.recipe_folder") or recipe.contains("exports_sources = \"CMakeLists.txt\"") or recipe.contains("exports_sources = [\"CMakeLists.txt\"")
    let recipe_cmake = if exports_cmake: conan_http_get(conan_recipe_file_url(name, folder, "CMakeLists.txt")) else: ""

    // Prerequisites first: say what is missing before downloading anything.
    if not with_cc_available():
        return conan_source_fail("", "building " ++ name ++ " from source needs `with cc`, and this build of `with` has none: the LLVM SDK it was linked against predates it")
    let cmake = conan_build_tool("cmake", "WITH_CMAKE")
    let ninja = conan_build_tool("ninja", "WITH_NINJA")
    if cmake.len() == 0 or ninja.len() == 0:
        let missing = if cmake.len() == 0 and ninja.len() == 0: "cmake and ninja" else: if cmake.len() == 0: "cmake" else: "ninja"
        return conan_source_fail("", "building " ++ name ++ " from source needs " ++ missing ++ ", which " ++ (if missing.contains(" and "): "are" else: "is") ++ " not on PATH; install " ++ (if missing.contains(" and "): "them" else: "it") ++ " (or set WITH_CMAKE / WITH_NINJA) and run `with get` again")
    let self_exe = conan_self_exe()
    if self_exe.len() == 0: return conan_source_fail("", "could not locate this `with` executable to use as the C compiler")

    let env = CrEnv { recipe: recipe.clone(), version: version.to_owned(), source_dir: "", os: conan_detect_os(), arch: conan_detect_arch() }
    let requires = conan_recipe_requires(&env)
    for undecided in requires.undecided:
        runtime_eprint("  note: not requiring " ++ undecided ++ ": that condition needs the recipe to run")
    let resolved: Vec[str] = Vec.new()
    for reference in requires.refs:
        let required = conan_ref_name(reference)
        let written = conan_ref_version(reference)
        // A version range asks for the newest release Conan Center has.
        let hint = if written.starts_with("["): "" else: written.clone()
        let installed = conan_install_internal(required, hint, project_root, depth + 1, false)
        if installed.len() == 0:
            return conan_source_fail("", name ++ "/" ++ version ++ " requires " ++ reference ++ ", which could not be installed (above)")
        resolved.push(required ++ "/" ++ installed)

    let dep_dir = conan_absolute(project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version)
    let _clean = runtime_remove_tree(dep_dir)
    let work = dep_dir ++ "/.build"
    let raw_dir = work ++ "/src"
    let tools_dir = work ++ "/tools"
    if runtime_mkdir_p(raw_dir) != 0 or runtime_mkdir_p(tools_dir) != 0 or runtime_mkdir_p(work ++ "/recipe") != 0:
        return conan_source_fail(dep_dir, "could not create " ++ work)
    let archive = work ++ "/" ++ conan_path_basename(source.url)
    runtime_eprint("  downloading " ++ source.url)
    if conan_http_download(source.url, archive) != 0: return conan_source_fail(dep_dir, "could not download " ++ source.url)
    let digest = conan_sha256_file(archive)
    if digest != source.sha256:
        return conan_source_fail(dep_dir, source.url ++ " has sha256 " ++ digest ++ "; the recipe expects " ++ source.sha256)
    if conan_extract_any(archive, raw_dir) != 0:
        return conan_source_fail(dep_dir, "could not extract " ++ conan_path_basename(source.url) ++ " (it needs `tar`" ++ (if archive.ends_with(".zip"): " with zip support, or `unzip`" else: if archive.ends_with(".xz"): " and `xz`" else: "") ++ ")")
    let source_dir = conan_source_root(raw_dir)
    for patch_file in conan_data_patches(data, version):
        let patch = conan_http_get(conan_recipe_file_url(name, folder, patch_file))
        if patch.len() == 0: return conan_source_fail(dep_dir, "could not fetch the recipe's " ++ patch_file)
        let problem = conan_apply_patch(patch, source_dir, conan_patch_read, conan_patch_write)
        if problem.len() > 0: return conan_source_fail(dep_dir, patch_file ++ ": " ++ problem)

    // The project's own CMakeLists, or the one the recipe ships for it.
    var cmake_dir = source_dir.clone()
    if recipe_cmake.len() > 0:
        cmake_dir = work ++ "/recipe"
        if runtime_write_file(cmake_dir ++ "/CMakeLists.txt", recipe_cmake) != 0: return conan_source_fail(dep_dir, "could not write the recipe's CMakeLists.txt")
    else if runtime_file_exists(source_dir ++ "/CMakeLists.txt") == 0:
        return conan_source_fail(dep_dir, name ++ "/" ++ version ++ " builds with " ++ conan_recipe_build_system(recipe) ++ "; `with get` builds CMake projects from source, so this package needs a platform Conan Center has a binary for")

    let built_env = CrEnv { recipe: recipe.clone(), version: version.to_owned(), source_dir: source_dir.clone(), os: conan_detect_os(), arch: conan_detect_arch() }
    let variables = conan_recipe_cmake_variables(&built_env)
    var prefix_path = ""
    for reference in resolved:
        if prefix_path.len() > 0: prefix_path = prefix_path ++ ";"
        prefix_path = prefix_path ++ conan_absolute(project_root ++ "/.with/deps/c/" ++ reference)
    var configure = ""
    configure = conan_argv_append(configure, cmake)
    configure = conan_argv_append(configure, "-S")
    configure = conan_argv_append(configure, cmake_dir)
    configure = conan_argv_append(configure, "-B")
    configure = conan_argv_append(configure, work ++ "/b")
    configure = conan_argv_append(configure, "-G")
    configure = conan_argv_append(configure, "Ninja")
    configure = conan_argv_append(configure, "-DCMAKE_MAKE_PROGRAM=" ++ ninja)
    configure = conan_argv_append(configure, "-DCMAKE_C_COMPILER=" ++ conan_write_launcher(tools_dir, "cc", self_exe))
    configure = conan_argv_append(configure, "-DCMAKE_AR=" ++ conan_write_launcher(tools_dir, "ar", self_exe))
    configure = conan_argv_append(configure, "-DCMAKE_RANLIB=" ++ conan_write_launcher(tools_dir, "ranlib", self_exe))
    configure = conan_argv_append(configure, "-DCMAKE_BUILD_TYPE=Release")
    configure = conan_argv_append(configure, "-DBUILD_SHARED_LIBS=OFF")
    configure = conan_argv_append(configure, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
    configure = conan_argv_append(configure, "-DCMAKE_INSTALL_PREFIX=" ++ dep_dir)
    configure = conan_argv_append(configure, "-DCMAKE_INSTALL_LIBDIR=lib")
    if prefix_path.len() > 0: configure = conan_argv_append(configure, "-DCMAKE_PREFIX_PATH=" ++ prefix_path)
    for define in variables.defines: configure = conan_argv_append(configure, define)
    runtime_eprint("  configuring...")
    if conan_run_tool(configure, 900000) != 0:
        for unknown in variables.unknown: runtime_eprint("  note: the recipe also sets " ++ unknown ++ ", which could not be evaluated")
        return conan_source_fail(dep_dir, "CMake could not configure " ++ name ++ "/" ++ version ++ " (its output is above)")
    // Keep going past a test or example program that does not link: the
    // library is what gets installed, and the install step says if it is missing.
    var build = ""
    build = conan_argv_append(build, cmake)
    build = conan_argv_append(build, "--build")
    build = conan_argv_append(build, work ++ "/b")
    build = conan_argv_append(build, "--")
    build = conan_argv_append(build, "-k")
    build = conan_argv_append(build, "0")
    runtime_eprint("  building...")
    let build_rc = conan_run_tool(build, 3600000)
    var install = ""
    install = conan_argv_append(install, cmake)
    install = conan_argv_append(install, "--install")
    install = conan_argv_append(install, work ++ "/b")
    if conan_run_tool(install, 300000) != 0:
        return conan_source_fail(dep_dir, name ++ "/" ++ version ++ " did not build (the compiler's output is above" ++ (if build_rc != 0: "; the build step failed" else: "") ++ ")")
    let _work = runtime_remove_tree(work)
    if conan_write_binary_metadata(name, version, "built", "built", source.sha256, dep_dir, resolved) != 0:
        return conan_source_fail(dep_dir, "could not write metadata for " ++ name ++ "/" ++ version)
    runtime_eprint("  built " ++ name ++ "/" ++ version ++ " into .with/deps/c/" ++ name ++ "/" ++ version ++ "/")
    version.to_owned()

// A lock entry that was built from source: reuse the build, or build the same
// version again; the recipe's digest for it must still be the locked one.
pub fn conan_restore_locked_source(name: &str, version: &str, sha256: &str, project_root: &str) -> bool:
    if runtime_file_exists(project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version ++ "/metadata.json") != 0: return true
    let folder = conan_recipe_folder(name, version)
    let data = if folder.len() > 0: conan_http_get(conan_recipe_file_url(name, folder, "conandata.yml")) else: ""
    let pinned = conan_data_source(data, version)
    let now = pinned.sha256.clone()
    if now != sha256:
        runtime_eprint("error: the lock pins c." ++ name ++ "@" ++ version ++ " to source sha256 " ++ sha256 ++ "; the recipe now says " ++ (if now.len() == 0: "nothing for that version" else: now))
        return false
    conan_install_from_source(name, version, project_root, 0).len() > 0

fn conan_install_internal(name: &str, version_hint: &str, project_root: &str, depth: i32, force_reinstall: bool) -> str:
    if depth > 8:
        runtime_eprint("error: Conan dependency graph too deep while resolving " ++ name)
        return ""
    let version = conan_resolve_version(name, version_hint)
    if version.len() == 0:
        runtime_eprint("error: could not resolve package " ++ name ++ "/" ++ version_hint ++ " on Conan Center")
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
        runtime_eprint("error: could not resolve recipe for " ++ name ++ "/" ++ version ++ " on Conan Center")
        return ""
    runtime_eprint("  revision: " ++ recipe_rev.slice(0, if recipe_rev.len() > 12: 12 else: recipe_rev.len()))
    if g_conan_from_source: return conan_install_from_source(name, version, project_root, depth)
    let installed_binary = conan_install_binary(name, version, recipe_rev, project_root, depth, force_reinstall)
    if installed_binary.len() > 0:
        return installed_binary
    conan_install_from_source(name, version, project_root, depth)

// Public API. Returns the concrete installed version, or "" on failure.
fn conan_install(name: &str, version_hint: &str, project_root: &str, force_reinstall: bool) -> str:
    conan_install_internal(name, version_hint, project_root, 0, force_reinstall)
