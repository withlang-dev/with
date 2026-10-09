// ConanClient — native Conan Center client for C package management.
//
// Uses Conan's v2 REST API directly. No dependency on the conan CLI.

use Archive
use compiler.Runtime
use compiler.ConanRecipe
use compiler.RecipeInterp
use compiler.ProjectConfig
use compiler.ConanPatch
use compiler.ClangDriver
use compiler.FrameworkStubs
use compiler.WindowsImportLibs
use compiler.TarExtract
use compiler.EmbeddedSysroot
use std.http
use compiler.Link
use std.crypto.sha256
use std.string.StringBuilder
extern fn with_str_clone_ref(s: &str) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_fs_chmod(path: &str, mode: i32) -> i32

fn CONAN_CENTER_URL -> str: "https://center2.conan.io"
fn CONAN_INDEX_RAW -> str: "https://raw.githubusercontent.com/conan-io/conan-center-index/master/recipes"

pub type ConanPackagePick {
    package_id: str,
    shared: bool,
}

pub type ConanLibraryScan {
    lib_paths: List[str],
    libs: List[str],
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
    let rc = conan_https_to_file(url, tmp, 300000)
    if rc != 0:
        runtime_remove_tree(scratch)
        return ""
    let body = runtime_read_file(tmp)
    runtime_remove_tree(scratch)
    body

fn conan_http_download(url: &str, path: &str) -> i32:
    conan_https_to_file(url, path, 300000)

fn conan_sha256_file(path: &str) -> str:
    if runtime_file_exists(path) == 0:
        return ""
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(runtime_read_file(path), &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

fn conan_argv_append(argv: &str, arg: &str) -> str:
    argv ++ arg ++ "\0"

// #1915: downloads are this compiler's own HTTPS client (std.http over
// std.tls), not the host's curl. A dropped connection is retried, as
// build/https_fetch.w does.
// A file:// URL — a local mirror, or a test's fixture — is copied the way an
// HTTPS fetch writes its body; an absent file is a failed download.
fn conan_https_to_file(url: &str, path: &str, timeout_ms: i32) -> i32:
    if url.starts_with("file://"):
        let local = conan_file_url_path(url)
        if runtime_file_exists(local) == 0 or runtime_is_dir(local) != 0: return 1
        return if runtime_write_file(path, runtime_read_file(local)) == 0: 0 else: 1
    if not url.starts_with("https://"):
        runtime_eprint("error: Conan download needs an https:// or file:// URL: " ++ url)
        return 1
    for attempt in 1..4:
        if https_download(url.to_owned(), path.to_owned()) == 0: return 0
        if attempt < 3: let _ = runtime_nanosleep(attempt as i64 * 1000000000)
    runtime_eprint("error: Conan download failed after 3 attempts: " ++ url ++ " -> " ++ path)
    1

// The local path a file:// URL names: percent-escapes decoded, and a Windows
// drive path (file:///C:/…) without its leading slash.
fn conan_file_url_path(url: &str) -> str:
    let raw = url.slice(7, url.len())
    var decoded = StringBuilder.new()
    var i = 0
    while i < raw.len() as i32:
        if raw[i] == '%' and i + 2 < raw.len() as i32:
            let hi = conan_hex_digit(raw[i + 1])
            let lo = conan_hex_digit(raw[i + 2])
            if hi >= 0 and lo >= 0:
                decoded.push_byte((hi * 16 + lo) as u8)
                i = i + 3
                continue
        decoded.push_byte(raw[i])
        i = i + 1
    let out = decoded.to_str()
    if out.len() > 2 and out[0] == '/' and out[2] == ':': return out.slice(1, out.len())
    out

fn conan_hex_digit(c: u8) -> i32:
    if c >= '0' and c <= '9': return (c - '0') as i32
    if c >= 'a' and c <= 'f': return (c - 'a' + 10) as i32
    if c >= 'A' and c <= 'F': return (c - 'A' + 10) as i32
    -1

// #1915: a package archive is unpacked in-process (compiler.TarExtract).
fn conan_extract_tgz(archive: &str, dest: &str) -> i32:
    let problem = tar_gz_extract(archive, dest, 0)
    if problem.len() > 0:
        runtime_eprint("error: could not unpack " ++ problem)
        return 1
    0

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

fn conan_list_contains(values: &List[str], value: &str) -> bool:
    for i in 0..values.len() as i32:
        if values[i] == value:
            return true
    false

fn conan_sorted_insert_unique(values: List[str], value: &str) -> List[str]:
    if value.len() == 0 or conan_list_contains(values, value):
        return values
    let out: List[str] = List.new()
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

fn conan_split_nonempty_lines(text: &str) -> List[str]:
    let lines: List[str] = List.new()
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

fn json_extract_string_array(json: &str, key: &str) -> List[str]:
    var result: List[str] = List.new()
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

// Numeric order of two versions, component by component; a missing
// component is 0, so `3` and `3.0.0` are the same version.
fn conan_version_order(a: &str, b: &str) -> i32:
    let pa = a.split(".")
    let pb = b.split(".")
    let n = if pa.len() > pb.len(): pa.len() as i32 else: pb.len() as i32
    for i in 0..n:
        let x: &str = if i < pa.len() as i32: &pa[i] else: "0"
        let y: &str = if i < pb.len() as i32: &pb[i] else: "0"
        let c = conan_version_compare(x, y)
        if c != 0: return c
    0

// The first version past what `base` admits: its minor bumped for a tilde
// (`1.2` and `1.2.3` -> `1.3`, `1` -> `2`), its major for a caret (`1.2` -> `2`).
fn conan_version_bump(base: &str, caret: bool) -> str:
    let parts = base.split(".")
    let keep = if caret or parts.len() < 2: 0 else: 1
    var out = ""
    for i in 0..keep: out = out ++ parts[i] ++ "."
    let (_, n) = conan_parse_leading_int(parts[keep])
    out ++ f"{n + 1}"

fn conan_parse_leading_int(text: &str) -> (bool, i32):
    var n = 0
    var any = false
    for i in 0..text.len() as i32:
        if text[i] < '0' or text[i] > '9': break
        n = n * 10 + (text[i] - '0') as i32
        any = true
    (any, n)

// One term of a Conan version range: `>=3`, `>3`, `<4`, `<=4`, `=1.0`,
// `~1.2` (>=1.2 <1.3), `^1.2` (>=1.2 <2), or a bare version (that version).
fn conan_range_term_holds(version: &str, term: &str) -> bool:
    if term.starts_with(">="): return conan_version_order(version, term.slice(2, term.len())) >= 0
    if term.starts_with("<="): return conan_version_order(version, term.slice(2, term.len())) <= 0
    if term.starts_with(">"): return conan_version_order(version, term.slice(1, term.len())) > 0
    if term.starts_with("<"): return conan_version_order(version, term.slice(1, term.len())) < 0
    if term.starts_with("~") or term.starts_with("^"):
        let base = term.slice(1, term.len())
        return conan_version_order(version, base) >= 0 and conan_version_order(version, conan_version_bump(base, term.starts_with("^"))) < 0
    if term.starts_with("="): return conan_version_order(version, term.slice(1, term.len())) == 0
    conan_version_order(version, term) == 0

// Whether `version` is in the range a recipe writes as `[>=3 <4]`: terms
// separated by spaces all hold, `||` separates alternatives, and what follows
// a `,` is an option (`include_prerelease`), without which a pre-release
// (`3.0.0-beta`) is in no range.
pub fn conan_version_in_range(version: &str, range: &str) -> bool:
    var body: str = range.trim().to_owned()
    if body.starts_with("["): body = body.slice(1, body.len())
    if body.ends_with("]"): body = body.slice(0, body.len() - 1)
    let comma = body.find(",")
    let prerelease = comma >= 0 and body.slice(comma + 1, body.len()).contains("include_prerelease")
    if comma >= 0: body = body.slice(0, comma)
    if version.contains("-") and not prerelease: return false
    for alternative in body.split("||"):
        var holds = true
        var any = false
        for term in alternative.split(" "):
            if term.len() == 0: continue
            any = true
            if not conan_range_term_holds(version, term): holds = false
        if holds and any: return true
    // `[*]` and an empty range accept every release.
    body.trim().len() == 0 or body.trim() == "*"

// `version_hint` is an exact version, a `1.2.Z` prefix, a range as a recipe
// writes one (`[>=3 <4]`) or empty; a range or a prefix asks for the newest
// release Conan Center has that satisfies it.
fn conan_resolve_version(name: &str, version_hint: &str) -> str:
    if version_hint.len() > 0 and not version_hint.ends_with(".Z") and not version_hint.starts_with("["):
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
        if not (if version_hint.starts_with("["): conan_version_in_range(version, version_hint) else: conan_version_matches_hint(version, version_hint)):
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

fn conan_parse_requires_from_info(info: &str) -> List[str]:
    let requires: List[str] = List.new()
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

// A requirement names `name/version`, optionally followed by `@user/channel`,
// `#recipe_revision` and `:package_id` (pulseaudio pins
// `flac/1.4.2#<revision>:<package id>`). The version ends at the first of them.
pub fn conan_ref_version(req: &str) -> str:
    let slash = conan_find_char(req, 47)
    if slash <= 0:
        return ""
    var end = req.len() as i32
    for i in (slash + 1)..(req.len() as i32):
        let ch = req[i]
        if ch == 64 or ch == 35 or ch == 58:
            end = i
            break
    req.slice((slash + 1) as i64, end as i64)

fn conan_json_escape(value: &str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value[i]
        if ch == 34 or ch == 92:
            out = out ++ "\\"
        out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn conan_json_array(values: &List[str]) -> str:
    let q = "\x22"
    var out = "["
    for i in 0..values.len() as i32:
        if i > 0:
            out = out ++ ", "
        out = out ++ q ++ conan_json_escape(values[i]) ++ q
    out ++ "]"

fn conan_write_metadata(dest_dir: &str, name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, include_paths: &List[str], lib_paths: &List[str], libs: &List[str], defines: &List[str], link_args: &List[str], requires: &List[str]) -> i32:
    let none: List[ConanComponentLink] = List.new()
    conan_write_metadata_components(dest_dir, name, version, recipe_rev, package_id, package_rev, include_paths, lib_paths, libs, defines, link_args, requires, &none)

// `components`, when the package has them, are written beside the package's
// own lists as `libs:<name>`, `lib_paths:<name>`, `link_args:<name>` and
// `requires:<name>`: the build links a package by its components and what
// each requires (compiler.ProjectConfig), and the package-level lists stay
// what c_import and the lock read.
fn conan_write_metadata_components(dest_dir: &str, name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, include_paths: &List[str], lib_paths: &List[str], libs: &List[str], defines: &List[str], link_args: &List[str], requires: &List[str], components: &List[ConanComponentLink]) -> i32:
    let q = "\x22"
    let nl = "\n"
    var meta = "{" ++ nl
    meta = meta ++ "  " ++ q ++ "name" ++ q ++ ": " ++ q ++ conan_json_escape(name) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "version" ++ q ++ ": " ++ q ++ conan_json_escape(version) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "recipe_revision" ++ q ++ ": " ++ q ++ conan_json_escape(recipe_rev) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "package_id" ++ q ++ ": " ++ q ++ conan_json_escape(package_id) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "package_revision" ++ q ++ ": " ++ q ++ conan_json_escape(package_rev) ++ q ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "include_paths" ++ q ++ ": " ++ conan_json_array(include_paths) ++ "," ++ nl
    // #1915 (Eric, 2026-09-30): a package that links in-box Windows DLLs the
    // SDK has no import library for (gdi32, opengl32, winmm) gets them,
    // generated from mingw-w64's definitions (compiler.WindowsImportLibs).
    var all_lib_paths = lib_paths.clone()
    if runtime_sysinfo_os() == "Windows":
        let wanted = conan_windows_libs_without_import_lib(dest_dir, lib_paths, libs)
        if wanted.len() > 0:
            let made = windows_import_libs_write(dest_dir ++ "/windows-libs", &wanted)
            if made.problem.len() > 0:
                runtime_eprint("error: " ++ name ++ "/" ++ version ++ " links Windows DLLs whose import libraries could not be written: " ++ made.problem)
                return 1
            if made.written.len() > 0: all_lib_paths.push("windows-libs")
    meta = meta ++ "  " ++ q ++ "lib_paths" ++ q ++ ": " ++ conan_json_array(&all_lib_paths) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "libs" ++ q ++ ": " ++ conan_json_array(libs) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "defines" ++ q ++ ": " ++ conan_json_array(defines) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "link_args" ++ q ++ ": " ++ conan_json_array(link_args) ++ "," ++ nl
    // #1915: a package that links Apple frameworks gets their link stubs,
    // written from this machine's dyld shared cache: the toolchain reads no
    // Apple SDK, so the stubs are the package's (compiler.FrameworkStubs).
    let frameworks = framework_names_in_link_args(link_args)
    if runtime_sysinfo_os() == "Macos" and frameworks.len() > 0:
        let problem = framework_stubs_write(dest_dir ++ "/Frameworks", &frameworks)
        if problem.len() > 0:
            runtime_eprint("error: " ++ name ++ "/" ++ version ++ " links Apple frameworks, and their link stubs could not be written: " ++ problem)
            return 1
        meta = meta ++ "  " ++ q ++ "framework_paths" ++ q ++ ": [" ++ q ++ "Frameworks" ++ q ++ "]," ++ nl
    if components.len() > 0:
        var names: List[str] = List.new()
        for c in components: names.push(c.name.clone())
        meta = meta ++ "  " ++ q ++ "components" ++ q ++ ": " ++ conan_json_array(&names) ++ "," ++ nl
        for c in components:
            var paths = c.lib_paths.clone()
            if conan_list_contains(all_lib_paths, "windows-libs"): paths.push("windows-libs")
            meta = meta ++ "  " ++ q ++ "libs:" ++ c.name ++ q ++ ": " ++ conan_json_array(&c.libs) ++ "," ++ nl
            meta = meta ++ "  " ++ q ++ "lib_paths:" ++ c.name ++ q ++ ": " ++ conan_json_array(&paths) ++ "," ++ nl
            meta = meta ++ "  " ++ q ++ "link_args:" ++ c.name ++ q ++ ": " ++ conan_json_array(&c.link_args) ++ "," ++ nl
            meta = meta ++ "  " ++ q ++ "requires:" ++ c.name ++ q ++ ": " ++ conan_json_array(&c.requires) ++ "," ++ nl
    meta = meta ++ "  " ++ q ++ "requires" ++ q ++ ": " ++ conan_json_array(requires) ++ nl
    meta = meta ++ "}" ++ nl
    runtime_write_file(dest_dir ++ "/metadata.json", meta)

// The libraries a Windows package names that neither the package's own
// library directories nor the SDK's C runtime provide: the in-box DLLs
// `with get` writes import libraries for.
fn conan_windows_libs_without_import_lib(dest_dir: &str, lib_paths: &List[str], libs: &List[str]) -> List[str]:
    var dirs: List[str] = List.new()
    for p in lib_paths: dirs.push(dest_dir ++ "/" ++ p)
    let libc_root = link_stage_windows_libc_root()
    if libc_root.len() > 0: dirs.push(libc_root ++ "/" ++ link_stage_windows_arch() ++ "-w64-mingw32/lib")
    let out: List[str] = List.new()
    for lib in libs:
        if not windows_lib_in_dirs(lib, &dirs): out.push(lib.clone())
    out

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
    var lib_paths: List[str] = List.new()
    var libs: List[str] = List.new()
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

// ── What a consumer links ────────────────────────────────────────────
//
// A package's link interface has one owner. For a binary Conan Center
// built, it is the recipe's `package_info`, read against the settings and
// options that binary was built with (its conaninfo) — Conan's own
// consumers get nothing else, since the recipe deletes the build's
// pkg-config and CMake files from the package. For a package built here,
// it is what the build itself installed: its pkg-config files, which name
// the libraries this build produced and what they need on this platform;
// the recipe's `package_info` stands in when the build installs none.
//
// Either way the recipe is evaluated (compiler.RecipeInterp), never matched
// line by line, and nothing here names a package: components, their
// libraries, the directories they live in, the frameworks and system
// libraries they need, and which components of which other packages they
// require are all the recipe's or the build's to say. A library the recipe
// names that the package does not hold is an error, and so is a recipe that
// cannot be read: an incomplete link interface is never written.

// conaninfo's `key=value` lines under `[section]`.
pub fn conan_info_section(info: &str, section: &str) -> List[str]:
    let out: List[str] = List.new()
    let lines = conan_split_nonempty_lines(info)
    var inside = false
    for i in 0..lines.len() as i32:
        let line = lines[i]
        if line.starts_with("["):
            inside = line == "[" ++ section ++ "]"
            continue
        if inside and conan_find_char(line, 61) > 0:
            out.push(with_str_clone_ref(line))
    out

fn conan_info_setting(info: &str, key: &str) -> str:
    let prefix = key ++ "="
    for line in conan_info_section(info, "settings"):
        if line.starts_with(prefix): return line.slice(prefix.len(), line.len()).to_owned()
    ""

// The option values a package binary was built with (#2084).
pub fn conan_parse_options_from_info(info: &str) -> List[str]: conan_info_section(info, "options")

// What a binary was built with, as its conaninfo states it.
pub fn conan_binary_recipe_env(info: &str, version: &str, dep_dir: &str) -> RecipeEnv:
    RecipeEnv { os: conan_info_setting(info, "os"), arch: conan_info_setting(info, "arch"), compiler: conan_info_setting(info, "compiler"), compiler_version: conan_info_setting(info, "compiler.version"), build_type: conan_info_setting(info, "build_type"), version: version.to_owned(), package_folder: dep_dir.to_owned(), source_folder: "", options: conan_parse_options_from_info(info), options_known: true }

// What a package built here is built with: this platform, the SDK's clang,
// and the recipe's own default options.
pub fn conan_built_recipe_env(version: &str, dep_dir: &str) -> RecipeEnv:
    let os = conan_detect_os()
    RecipeEnv { os: os.clone(), arch: conan_detect_arch(), compiler: if os == "Macos": "apple-clang" else: "clang", compiler_version: "", build_type: "Release", version: version.to_owned(), package_folder: dep_dir.to_owned(), source_folder: "", options: List.new(), options_known: false }

// One component of a package, as the build links it: `requires` names a
// sibling component, or `name/version:component` of another package.
pub type ConanComponentLink { name: str, libs: List[str], lib_paths: List[str], link_args: List[str], defines: List[str], include_paths: List[str], requires: List[str] }

pub type ConanPackageLink { problem: str, warnings: List[str], components: List[ConanComponentLink] }

// The component that stands for a package without components.
pub fn CONAN_WHOLE_COMPONENT -> str: "*"

// Whether `lib` is a library file in one of the package's directories.
fn conan_package_has_lib(dep_dir: &str, libdirs: &List[str], lib: &str) -> bool:
    for d in libdirs:
        let base = dep_dir ++ "/" ++ d ++ "/"
        for candidate in ["lib" ++ lib ++ ".a", "lib" ++ lib ++ ".so", "lib" ++ lib ++ ".dylib", "lib" ++ lib ++ ".tbd", lib ++ ".lib", "lib" ++ lib ++ ".dll.a"]:
            if runtime_file_exists(base ++ candidate) != 0: return true
    false

// A link flag as a recipe or a pkg-config file spells it, as the arguments
// the build passes: a framework, linked or weakly linked. Empty when the
// flag is something else.
fn conan_framework_flag_args(flag: &str) -> List[str]:
    let out: List[str] = List.new()
    for prefix in ["-Wl,-weak_framework,", "-Wl,-framework,"]:
        if flag.starts_with(prefix) and flag.len() > prefix.len():
            out.push(if prefix.contains("weak"): "-weak_framework" else: "-framework")
            out.push(flag.slice(prefix.len(), flag.len()).to_owned())
    out

// `other::component` as `name/version:component`, by the versions this
// package was resolved against; "" when it names no requirement of the package.
fn conan_component_requirement(reference: &str, requirements: &List[str]) -> str:
    let sep = reference.find("::")
    if sep < 0: return reference.to_owned()
    let package = reference.slice(0, sep)
    for req in requirements:
        if conan_ref_name(req) == package: return package ++ "/" ++ conan_ref_version(req) ++ ":" ++ reference.slice(sep + 2, reference.len())
    ""

fn conan_component_link(dep_dir: &str, requirements: &List[str], c: &RecipeComponent, name: &str, whole: bool, warnings0: List[str]) -> (ConanComponentLink, List[str], str):
    var warnings = warnings0
    var out = ConanComponentLink { name: name.to_owned(), libs: List.new(), lib_paths: List.new(), link_args: List.new(), defines: c.defines.clone(), include_paths: List.new(), requires: List.new() }
    for d in c.libdirs:
        if runtime_is_dir(dep_dir ++ "/" ++ d) != 0: out.lib_paths.push(d.clone())
    for d in c.includedirs:
        if runtime_is_dir(dep_dir ++ "/" ++ d) != 0: out.include_paths.push(d.clone())
    for lib in c.libs:
        if not conan_package_has_lib(dep_dir, &c.libdirs, lib):
            return (out, warnings, "its recipe names the library '" ++ lib ++ "'" ++ (if whole: "" else: " (component '" ++ name ++ "')") ++ ", which the package does not hold in " ++ conan_json_array(&c.libdirs))
        out.libs.push(lib.clone())
    for lib in c.system_libs: out.libs.push(lib.clone())
    for fw in c.frameworks:
        out.link_args.push("-framework")
        out.link_args.push(fw.clone())
    for flag in c.exelinkflags:
        let args = conan_framework_flag_args(flag)
        if args.len() == 0: warnings.push("link flag '" ++ flag ++ "' is not passed on")
        for a in args: out.link_args.push(a.clone())
    for r in c.requires:
        let resolved = conan_component_requirement(r, requirements)
        if resolved.len() == 0: warnings.push("'" ++ r ++ "' names a package this one was not resolved against; it is not linked")
        else: out.requires.push(resolved)
    // A package that states no requirement of its own links all of them.
    if whole and c.requires.len() == 0:
        for req in requirements: out.requires.push(conan_ref_name(req) ++ "/" ++ conan_ref_version(req))
    (out, warnings, "")

// The link interface `package_info` describes for the package in `dep_dir`.
pub fn conan_package_link(dep_dir: &str, requirements: &List[str], info: &RecipePackageInfo) -> ConanPackageLink:
    var out = ConanPackageLink { problem: "", warnings: List.new(), components: List.new() }
    for n in info.notes: out.warnings.push("recipe " ++ n)
    if info.components.len() == 0:
        let (link, warnings, problem) = conan_component_link(dep_dir, requirements, &info.root, CONAN_WHOLE_COMPONENT(), true, move out.warnings)
        out.warnings = warnings
        out.problem = problem
        out.components.push(link)
        return out
    for i in 0..info.components.len() as i32:
        let (link, warnings, problem) = conan_component_link(dep_dir, requirements, &info.components[i], info.components[i].name, false, move out.warnings)
        out.warnings = warnings
        if problem.len() > 0:
            out.problem = problem
            return out
        out.components.push(link)
    out

// A pkg-config file's `field:` value with its variables substituted.
pub fn conan_pc_field(text: &str, field: &str) -> str:
    let names: List[str] = List.new()
    let values: List[str] = List.new()
    var found = ""
    for raw in text.split("\n"):
        let line = raw.trim()
        if line.len() == 0 or line.starts_with("#"): continue
        let colon = line.find(":")
        let eq = line.find("=")
        if eq > 0 and (colon < 0 or eq < colon):
            names.push(line.slice(0, eq).trim().to_owned())
            values.push(line.slice(eq + 1, line.len()).trim().to_owned())
        else if colon > 0 and line.slice(0, colon) == field: found = line.slice(colon + 1, line.len()).trim().to_owned()
    // Variables refer to earlier ones; a few rounds settle them.
    for _round in 0..8:
        if found.find("${") < 0: break
        for i in 0..names.len() as i32: found = found.replace("${" ++ names[i] ++ "}", values[i])
    found

// What the pkg-config files a build installed say a static consumer links:
// every file's `Libs` and `Libs.private`. `-L` is the package's own
// directory, which `lib_paths` already names.
pub fn conan_pc_link(dep_dir: &str, requirements: &List[str], pc_texts: &List[str]) -> ConanPackageLink:
    var out = ConanPackageLink { problem: "", warnings: List.new(), components: List.new() }
    var link = ConanComponentLink { name: CONAN_WHOLE_COMPONENT(), libs: List.new(), lib_paths: List.new(), link_args: List.new(), defines: List.new(), include_paths: List.new(), requires: List.new() }
    if runtime_is_dir(dep_dir ++ "/lib") != 0: link.lib_paths.push("lib")
    if runtime_is_dir(dep_dir ++ "/include") != 0: link.include_paths.push("include")
    for text in pc_texts:
        let flags = conan_pc_field(text, "Libs") ++ " " ++ conan_pc_field(text, "Libs.private")
        var framework_next = false
        for raw in flags.split(" "):
            let token = raw.trim().replace("\"", "")
            if token.len() == 0: continue
            if framework_next:
                framework_next = false
                if not conan_list_contains(link.link_args, token):
                    link.link_args.push("-framework")
                    link.link_args.push(token)
            else if token == "-framework": framework_next = true
            else if token.starts_with("-l") and token.len() > 2:
                let lib = token.slice(2, token.len())
                if not conan_list_contains(link.libs, lib): link.libs.push(lib.to_owned())
            else if token.starts_with("-L"): continue
            else if token == "-pthread":
                if conan_detect_os() != "Windows" and not conan_list_contains(link.libs, "pthread"): link.libs.push("pthread")
            else:
                let args = conan_framework_flag_args(token)
                if args.len() == 0: out.warnings.push("link flag '" ++ token ++ "' of its pkg-config file is not passed on")
                else if not conan_list_contains(link.link_args, args[1]):
                    for a in args: link.link_args.push(a.clone())
    for req in requirements: link.requires.push(conan_ref_name(req) ++ "/" ++ conan_ref_version(req))
    out.components.push(link)
    out

// The pkg-config files the package in `dep_dir` holds.
fn conan_package_pc_texts(dep_dir: &str) -> List[str]:
    let out: List[str] = List.new()
    let files = conan_split_nonempty_lines(runtime_list_files(dep_dir))
    for i in 0..files.len() as i32:
        if files[i].ends_with(".pc") and files[i].contains("/pkgconfig/"): out.push(runtime_read_file(files[i]))
    out

fn conan_fetch_recipe_text(name: &str, version: &str) -> str:
    let folder = conan_recipe_folder(name, version)
    if folder.len() == 0:
        return ""
    conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py"))

// The recipe a binary was built from: its recipe revision's own conanfile.py.
fn conan_fetch_recipe_revision_text(name: &str, version: &str, recipe_rev: &str) -> str:
    conan_http_get(CONAN_CENTER_URL() ++ "/v2/conans/" ++ name ++ "/" ++ version ++ "/_/_/revisions/" ++ recipe_rev ++ "/files/conanfile.py")

// A `<name>/system` recipe that stands for one library the host provides:
// Conan Center has no binary and no source for it, only the name to link.
pub fn conan_system_package_lib(name: &str) -> str:
    if name == "egl": return "EGL"
    if name == "libudev": return "udev"
    ""

// The host library a Linux `<name>/system` package links, given the dirs to
// search. `-l<name>` needs `lib<name>.so`, which only the -dev package
// installs; the runtime package installs `lib<name>.so.<N>` alone. So on a
// host with no development packages, `with get c.raylib` wrote `-lGL` and the
// program did not link ("cannot find -lGL") though libGL was installed. Returns
// "" to keep `-l<name>` when the dev symlink is there, and when no soname is
// either, so the linker's own "cannot find -l<name>" stays the diagnostic;
// else the path of the highest `lib<name>.so.<N>`, as the symlink would name.
// Only system packages come here: a Conan package's own archive never gives
// way to a same-named host library.
pub fn conan_host_lib_path(dirs: &List[str], name: &str) -> str:
    for d in 0..dirs.len() as i32:
        if runtime_file_exists(dirs[d] ++ "/lib" ++ name ++ ".so") != 0:
            return ""
    for d in 0..dirs.len() as i32:
        var n = 63
        while n >= 0:
            let path = dirs[d] ++ "/lib" ++ name ++ ".so." ++ f"{n}"
            if runtime_file_exists(path) != 0:
                return path
            n = n - 1
    ""

fn conan_linux_lib_dirs -> List[str]:
    let dirs: List[str] = List.new()
    dirs.push("/usr/lib/" ++ (if conan_detect_arch() == "armv8": "aarch64-linux-gnu" else: "x86_64-linux-gnu"))
    dirs.push("/usr/lib64")
    dirs.push("/usr/lib")
    dirs

// A system package's libs, with each one the host has only as a runtime
// soname moved to a link input by path (conan_host_lib_path).
fn conan_host_link_inputs(libs: List[str], link_args: List[str]) -> ConanLibraryScan:
    if conan_detect_os() != "Linux":
        return ConanLibraryScan { lib_paths: link_args, libs }
    let dirs = conan_linux_lib_dirs()
    var out_libs: List[str] = List.new()
    var out_args = link_args
    for i in 0..libs.len() as i32:
        let path = conan_host_lib_path(&dirs, libs[i])
        if path.len() > 0:
            out_args.push(path)
        else:
            out_libs.push(with_str_clone_ref(libs[i]))
    ConanLibraryScan { lib_paths: out_args, libs: out_libs }

fn conan_known_link_metadata(name: &str, version: &str, libs: List[str], link_args: List[str]) -> ConanLibraryScan:
    let os = conan_detect_os()
    var out_libs = libs
    var out_args = link_args
    if version == "system" and conan_system_package_lib(name).len() > 0:
        out_libs = conan_sorted_insert_unique(move out_libs, conan_system_package_lib(name))
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }
    if name == "opengl" and version == "system":
        if os == "Macos":
            out_args.push("-framework")
            out_args.push("OpenGL")
        else if os == "Windows":
            out_libs = conan_sorted_insert_unique(move out_libs, "opengl32")
        else if os == "Linux":
            out_libs = conan_sorted_insert_unique(move out_libs, "GL")
        return ConanLibraryScan { lib_paths: out_args, libs: out_libs }

    if name == "xorg" and version == "system" and os == "Linux":
        let xlibs: List[str] = List.new()
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
    if name != "opengl" and name != "xorg" and conan_system_package_lib(name).len() == 0:
        return false
    let dep_dir = project_root ++ "/.with/deps/c/" ++ name ++ "/" ++ version
    let _clean = runtime_remove_tree(dep_dir)
    if runtime_mkdir_p(dep_dir) != 0:
        runtime_eprint("error: failed to create dependency directory for " ++ name ++ "/" ++ version)
        return false
    let include_paths: List[str] = List.new()
    let lib_paths: List[str] = List.new()
    var libs: List[str] = List.new()
    var defines: List[str] = List.new()
    var link_args: List[str] = List.new()
    if name == "opengl" and conan_detect_os() == "Macos":
        defines = conan_sorted_insert_unique(move defines, "GL_SILENCE_DEPRECATION=1")
    var known = conan_known_link_metadata(name, version, move libs, move link_args)
    let host = conan_host_link_inputs(move known.libs, move known.lib_paths)
    let host_libs = host.libs
    let host_link_args = host.lib_paths
    let requires: List[str] = List.new()
    conan_write_metadata(dep_dir, name, version, "system", "system", "system", include_paths, lib_paths, host_libs, defines, host_link_args, requires) == 0

fn conan_resolve_and_install_requirements(requirements: &List[str], project_root: &str, depth: i32, force_reinstall: bool) -> List[str]:
    let resolved: List[str] = List.new()
    for i in 0..requirements.len() as i32:
        let req = requirements[i]
        let req_name = conan_ref_name(req)
        let req_hint = conan_ref_version(req)
        if req_name.len() == 0 or req_hint.len() == 0:
            runtime_eprint("error: unsupported Conan requirement reference: " ++ req)
            return List.new()
        let actual = conan_install_internal(req_name, req_hint, project_root, depth + 1, force_reinstall)
        if actual.len() == 0:
            return List.new()
        resolved.push(req_name ++ "/" ++ actual)
    resolved

// Adds to `into` what `more` links that it does not: a library, or a
// `-framework X` pair.
fn conan_component_add_links(into0: ConanComponentLink, libs: &List[str], link_args: &List[str]) -> ConanComponentLink:
    var into = into0
    for lib in libs:
        if not conan_list_contains(into.libs, lib): into.libs.push(lib.clone())
    var i = 0
    while i + 1 < link_args.len() as i32:
        var seen = false
        var j = 0
        while j + 1 < into.link_args.len() as i32:
            if into.link_args[j + 1] == link_args[i + 1]: seen = true
            j = j + 2
        if not seen:
            into.link_args.push(link_args[i].clone())
            into.link_args.push(link_args[i + 1].clone())
        i = i + 2
    into

// A package built here has two statements of what a consumer links beyond
// its own libraries: the pkg-config files its build installed, written by
// its authors for this build, and the recipe's `package_info`, written by
// its packager for every platform. Each leaves things out (raylib's
// pkg-config file names no winmm on Windows; SDL's recipe names no cfgmgr32
// outside MSVC), and a library a static archive needs and nobody names is a
// link error in the user's program. Both are honored: the system libraries
// and frameworks either names are linked. The package's own libraries and
// its components are the recipe's when the build produced the libraries it
// names, and the build's otherwise.
fn conan_built_package_link(dep_dir: &str, requirements: &List[str], pc_texts: &List[str], info: &RecipePackageInfo) -> ConanPackageLink:
    let recipe_link = if info.ok: conan_package_link(dep_dir, requirements, info) else: ConanPackageLink { problem: info.problem.clone(), warnings: List.new(), components: List.new() }
    if pc_texts.len() == 0: return recipe_link
    let pc_link = conan_pc_link(dep_dir, requirements, pc_texts)
    if recipe_link.problem.len() == 0:
        // What the pkg-config files add, to every component that links a library.
        var extra_libs: List[str] = List.new()
        for lib in pc_link.components[0].libs:
            if not conan_package_has_lib(dep_dir, &pc_link.components[0].lib_paths, lib): extra_libs.push(lib.clone())
        var out = ConanPackageLink { problem: "", warnings: List.new(), components: List.new() }
        for w in recipe_link.warnings: out.warnings.push(w.clone())
        for w in pc_link.warnings: out.warnings.push(w.clone())
        for c in recipe_link.components:
            var merged = ConanComponentLink { name: c.name.clone(), libs: c.libs.clone(), lib_paths: c.lib_paths.clone(), link_args: c.link_args.clone(), defines: c.defines.clone(), include_paths: c.include_paths.clone(), requires: c.requires.clone() }
            if c.libs.len() > 0: merged = conan_component_add_links(move merged, &extra_libs, &pc_link.components[0].link_args)
            out.components.push(merged)
        return out
    // The build did not produce the libraries the recipe names: the build's
    // own files say what it produced, and the recipe's system libraries and
    // frameworks are added to them.
    var out = ConanPackageLink { problem: "", warnings: List.new(), components: List.new() }
    for w in pc_link.warnings: out.warnings.push(w.clone())
    var whole = ConanComponentLink { name: pc_link.components[0].name.clone(), libs: pc_link.components[0].libs.clone(), lib_paths: pc_link.components[0].lib_paths.clone(), link_args: pc_link.components[0].link_args.clone(), defines: pc_link.components[0].defines.clone(), include_paths: pc_link.components[0].include_paths.clone(), requires: pc_link.components[0].requires.clone() }
    if info.ok:
        var frameworks: List[str] = List.new()
        for fw in info.root.frameworks:
            frameworks.push("-framework")
            frameworks.push(fw.clone())
        whole = conan_component_add_links(move whole, &info.root.system_libs, &frameworks)
        for c in info.components:
            var component_frameworks: List[str] = List.new()
            for fw in c.frameworks:
                component_frameworks.push("-framework")
                component_frameworks.push(fw.clone())
            whole = conan_component_add_links(move whole, &c.system_libs, &component_frameworks)
        for n in info.notes: out.warnings.push("recipe " ++ n)
    out.components.push(whole)
    out

// Writes the metadata of the package in `dep_dir` from its link interface
// (above). `built` says the package was built here, so the pkg-config files
// its build installed speak beside its recipe; a Conan Center binary is read
// through `recipe` alone, the conanfile.py of its recipe revision.
fn conan_write_binary_metadata(name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, dep_dir: &str, requirements: &List[str], env: &RecipeEnv, recipe: &str, built: bool) -> i32:
    if recipe.len() == 0:
        runtime_eprint("error: could not read the recipe of " ++ name ++ "/" ++ version ++ ", which says what the package links")
        return 1
    let info = recipe_package_info(recipe, env)
    var pc: List[str] = List.new()
    if built: pc = conan_package_pc_texts(dep_dir)
    if not info.ok and pc.len() == 0:
        runtime_eprint("error: " ++ name ++ "/" ++ version ++ ": " ++ info.problem)
        return 1
    let link = if built: conan_built_package_link(dep_dir, requirements, &pc, &info) else: conan_package_link(dep_dir, requirements, &info)
    if link.problem.len() > 0:
        runtime_eprint("error: " ++ name ++ "/" ++ version ++ " cannot be linked: " ++ link.problem)
        return 1
    for w in link.warnings: runtime_eprint("warning: " ++ name ++ "/" ++ version ++ ": " ++ w)
    // The package as a whole: every component's, in the recipe's order.
    var include_paths: List[str] = List.new()
    var lib_paths: List[str] = List.new()
    var libs: List[str] = List.new()
    var defines: List[str] = List.new()
    var link_args: List[str] = List.new()
    for c in link.components:
        for p in c.include_paths:
            if not conan_list_contains(include_paths, p): include_paths.push(p.clone())
        for p in c.lib_paths:
            if not conan_list_contains(lib_paths, p): lib_paths.push(p.clone())
        for l in c.libs:
            if not conan_list_contains(libs, l): libs.push(l.clone())
        for d in c.defines:
            if not conan_list_contains(defines, d): defines.push(d.clone())
        var i = 0
        while i + 1 < c.link_args.len() as i32:
            // Flag and name travel together: `-framework X`.
            var seen = false
            var j = 0
            while j + 1 < link_args.len() as i32:
                if link_args[j + 1] == c.link_args[i + 1]: seen = true
                j = j + 2
            if not seen:
                link_args.push(c.link_args[i].clone())
                link_args.push(c.link_args[i + 1].clone())
            i = i + 2
    conan_write_metadata_components(dep_dir, name, version, recipe_rev, package_id, package_rev, include_paths, lib_paths, libs, defines, link_args, requirements, &link.components)

// On Windows every C package is built from source with the SDK's toolchain
// (#1915; Eric, 2026-09-30: "with get builds packages from source in
// windows"). Conan Center's Windows binaries are MSVC builds: they name
// Visual Studio's CRT libraries and need its /GS runtime
// (__security_cookie, __GSHandlerCheck), which neither Windows nor the SDK
// ships.
fn conan_builds_from_source_only() -> bool: conan_detect_os() == "Windows"

pub fn conan_restore_locked_binary_package(name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, expected_sha256: &str, project_root: &str) -> bool:
    if conan_builds_from_source_only():
        runtime_eprint("error: the lock pins c." ++ name ++ "@" ++ version ++ " to a Conan Center binary; on Windows packages are built from source (#1915): run `with get c." ++ name ++ "` again to lock the source build")
        return false
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
    let restored_env = conan_binary_recipe_env(info, version, dep_dir)
    if conan_write_binary_metadata(name, version, recipe_rev, package_id, package_rev, dep_dir, requirements, &restored_env, conan_fetch_recipe_revision_text(name, version, recipe_rev), false) != 0:
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
    let binary_env = conan_binary_recipe_env(info, version, dep_dir)
    if conan_write_binary_metadata(name, version, recipe_rev, pick.package_id, package_rev, dep_dir, resolved_requirements, &binary_env, conan_fetch_recipe_revision_text(name, version, recipe_rev), false) != 0:
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

// `WITH_GET_CMAKE_<PACKAGE>` (the name uppercased, `-` as `_`): CMake cache
// variables for the package's source build, `NAME=VALUE` entries separated by
// `;`, appended after the recipe's own so they win. A Conan Center binary
// cannot honor a build variable, so a set variable means the package builds
// from source. A host provision, like LIBGL_ALWAYS_SOFTWARE: the darwin
// release lane renders raylib through its software rasterizer (rlsw) with
// `WITH_GET_CMAKE_RAYLIB=PLATFORM=RGFW;OPENGL_VERSION=Software;USE_EXTERNAL_GLFW=OFF`
// (#1375; the RGFW window backend has no GLFW to import).
pub fn conan_package_cmake_env_name(name: &str) -> str:
    var out = "WITH_GET_CMAKE_"
    for i in 0..name.len() as i32:
        let c = name[i]
        if c == '-': out = out ++ "_"
        else if c >= 'a' and c <= 'z': out = out ++ str_from_byte(c - 32)
        else: out = out ++ name.slice(i, i + 1)
    out

pub type ConanCMakeEnv {
    defines: List[str],   // `-DNAME=VALUE`, in the order written
    problem: str,        // "" or the entry that is not `NAME=VALUE`
}

pub fn conan_cmake_env_parse(text: &str) -> ConanCMakeEnv:
    var defines: List[str] = List.new()
    for raw in text.split(";"):
        let entry = raw.trim()
        if entry.len() == 0: continue
        let eq = entry.find("=")
        if eq <= 0: return ConanCMakeEnv { defines: List.new(), problem: entry.to_owned() }
        defines.push("-D" ++ entry)
    ConanCMakeEnv { defines, problem: "" }

fn conan_package_cmake_env(name: &str) -> ConanCMakeEnv:
    conan_cmake_env_parse(runtime_getenv(conan_package_cmake_env_name(name)))

// No linkable binary on Conan Center: build the package from source.
//
// Nothing here knows any package. The recipe Conan Center publishes is read as
// data (src/compiler/ConanRecipe.w): conandata.yml gives the tarball, its
// digest and the patches; conanfile.py gives the requirements and the CMake
// variables. The package's own CMake build does the rest, driven by `cmake`
// and `ninja` with `with cc` as the C compiler and `with __ar` as the archiver.
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
    let cwd = runtime_cwd()
    if runtime_path_is_absolute(path) or cwd.len() == 0: path.to_owned() else: cwd ++ "/" ++ path

// `name` on PATH, or "".
fn conan_find_program(name: &str) -> str:
    let windows = runtime_sysinfo_os() == "Windows"
    for dir in runtime_getenv("PATH").split(if windows: ";" else: ":"):
        if dir.len() == 0: continue
        let candidate = dir ++ "/" ++ name ++ (if windows and not name.ends_with(".exe"): ".exe" else: "")
        if runtime_file_exists(candidate) != 0: return candidate
    ""

// A build tool: WITH_<NAME> names it outright; otherwise it is this
// compiler's own (#1915, D81): the SDK's cmake and ninja, which the compiler
// carries and unpacks to its cache (compiler.EmbeddedSysroot), never the
// machine's. A compiler that carries none — a host whose #1915 slice has not
// landed — still looks on PATH.
fn conan_build_tool(name: &str, env_name: &str) -> str:
    let named = runtime_getenv(env_name)
    if named.len() > 0: return named
    let tools = embedded_sdk_tools_dir()
    if tools.len() > 0:
        let path = tools ++ "/bin/" ++ name ++ (if runtime_sysinfo_os() == "Windows": ".exe" else: "")
        return if runtime_file_exists(path) != 0: path else: ""
    // Windows (#1915): the SDK's own cmake and ninja, never a host install.
    if conan_builds_from_source_only():
        let sdk_tool = link_stage_windows_sdk_dir() ++ "/bin/" ++ name ++ ".exe"
        return if runtime_file_exists(sdk_tool) != 0: sdk_tool else: ""
    conan_find_program(name)

// `<dir>/<tool>`: a launcher that runs `<self> <tool> ...`. CMake wants one
// program path for a compiler; `with cc` is two words.
fn conan_write_launcher(dir: &str, tool: &str, self_exe: &str) -> str:
    conan_write_launcher_named(dir, tool, self_exe, tool)

// `<dir>/<name>`: runs `<self> <command> ...`; the command may carry its own
// leading arguments (`cc --driver-mode=g++`).
fn conan_write_launcher_named(dir: &str, name: &str, self_exe: &str, command: &str) -> str:
    if runtime_sysinfo_os() == "Windows":
        let path = dir ++ "/" ++ name ++ ".cmd"
        let _w = runtime_write_file(path, "@\"" ++ self_exe ++ "\" " ++ command ++ " %*\r\n")
        return path
    let path = dir ++ "/" ++ name
    let _w = runtime_write_file(path, "#!/bin/sh\nexec \"" ++ self_exe ++ "\" " ++ command ++ " \"$@\"\n")
    let _x = with_fs_chmod(path, 0o755)
    path

// #1915: every archive is unpacked in-process (compiler.TarExtract): gzip,
// xz and bzip2 tarballs and zips, told apart by their first bytes.
fn conan_extract_any(archive: &str, dest: &str) -> i32:
    let problem = archive_extract(archive, dest)
    if problem.len() > 0:
        runtime_eprint("error: could not unpack " ++ problem)
        return 1
    0

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

fn conan_archive_download(url: &str, path: &str) -> i32: conan_http_download(url, path)

fn conan_archive_digest(path: &str) -> str: conan_sha256_file(path)

fn conan_patch_read(path: &str) -> str: runtime_read_file(path)

fn conan_patch_write(path: &str, text: &str) -> i32: runtime_write_file(path, text)

// What the recipe says about a build we cannot drive, for the error.
fn conan_recipe_build_system(recipe: &str) -> str:
    if recipe.contains("Configure") and recipe.contains("perl"): return "its own Configure script, which needs Perl"
    if recipe.contains("Autotools(") or recipe.contains("AutotoolsToolchain"): return "autotools (sh and make)"
    if recipe.contains("Meson("): return "Meson"
    if recipe.contains("MSBuild("): return "MSBuild"
    "a build system other than CMake"

// ── CMake package configs for requirements (#1900) ─────────────────────
// A source build finds a requirement with find_package(<file name>), and a
// Conan Center binary package carries no config for it: Conan's CMakeDeps
// generator writes one at install time. `with get` writes the same from what
// it recorded for the package (metadata.json): `<file>Config.cmake`
// declaring the recipe's CMake target over the package's libraries, include
// directories, defines and link options — its requirements' folded in, as
// CMakeDeps' target links theirs — and `<file>ConfigVersion.cmake` answering
// find_package's version request (SameMajorVersion, CMakeDeps' default). The
// names are the requirement recipe's own `cmake_file_name` and
// `cmake_target_name`, else CMakeDeps' defaults (the package name;
// `<name>::<name>`). A requirement built from source installed its own
// config, and gets none from here.

type ConanCMakeLinkSet {
    visited: List[str],
    includes: List[str],
    defines: List[str],
    libraries: List[str],
    options: List[str],
    problem: str,
}

/// The value of `self.cpp_info.set_property("<property>", "<value>")` in a
/// recipe, or "" when it sets none (a component's property is not the
/// package's).
pub fn conan_recipe_cpp_info_property(recipe: &str, property: &str) -> str:
    for quote in ["\"", "'"]:
        let needle = "self.cpp_info.set_property(" ++ quote ++ property ++ quote ++ ","
        let at = recipe.find(needle)
        if at < 0: continue
        var i = at + needle.len()
        while i < recipe.len() and (recipe[i] == ' ' or recipe[i] == '\t'): i = i + 1
        if i >= recipe.len() or (recipe[i] != '"' and recipe[i] != '\''): return ""
        let close = recipe[i]
        let start = i + 1
        var end = start
        while end < recipe.len() and recipe[end] != close and recipe[end] != '\n': end = end + 1
        if end >= recipe.len() or recipe[end] != close: return ""
        return recipe.slice(start, end)
    ""

// The file a package's library `name` is, under its recorded library
// directories; "" when none is there (the link then names it, -l<name>).
fn conan_cmake_library_file(lib_dirs: &List[str], name: &str) -> str:
    for dir in lib_dirs:
        for file in ["lib" ++ name ++ ".a", name ++ ".lib", "lib" ++ name ++ ".lib", "lib" ++ name ++ ".dylib", "lib" ++ name ++ ".so"]:
            let path = dir ++ "/" ++ file
            if runtime_file_exists(path) != 0: return path
    ""

fn conan_cmake_push_unique(items: List[str], item: &str) -> List[str]:
    var out = items
    if not out.contains(item): out.push(item.to_owned())
    out

/// Folds the package `reference` ("name/version") and its requirements into `set`.
fn conan_cmake_collect(project_root: &str, reference: &str, set: ConanCMakeLinkSet, depth: i32) -> ConanCMakeLinkSet:
    var out = set
    if out.problem.len() > 0 or out.visited.contains(reference): return out
    if depth > 32:
        out.problem = "the requirements of " ++ reference ++ " nest more than 32 deep"
        return out
    out.visited.push(reference.to_owned())
    let dep_dir = conan_absolute(project_root ++ "/.with/deps/c/" ++ reference)
    let meta = runtime_read_file(dep_dir ++ "/metadata.json")
    if meta.len() == 0:
        out.problem = "no metadata.json for " ++ reference ++ " under " ++ dep_dir
        return out
    for include in project_config_json_str_array(meta, "include_paths"): out.includes = conan_cmake_push_unique(move out.includes, dep_dir ++ "/" ++ include)
    for define in project_config_json_str_array(meta, "defines"): out.defines = conan_cmake_push_unique(move out.defines, define)
    var lib_dirs: List[str] = List.new()
    for lib_path in project_config_json_str_array(meta, "lib_paths"): lib_dirs.push(dep_dir ++ "/" ++ lib_path)
    for lib in project_config_json_str_array(meta, "libs"):
        let file = conan_cmake_library_file(&lib_dirs, lib)
        if file.len() > 0:
            out.libraries = conan_cmake_push_unique(move out.libraries, file)
        else:
            for dir in lib_dirs: out.options = conan_cmake_push_unique(move out.options, "-L" ++ dir)
            out.libraries = conan_cmake_push_unique(move out.libraries, lib)
    for framework_path in project_config_json_str_array(meta, "framework_paths"): out.options = conan_cmake_push_unique(move out.options, "-F" ++ dep_dir ++ "/" ++ framework_path)
    // `-framework X` (and the other two-token Apple flags) stays one option:
    // CMake de-duplicates and reorders bare options, which tears the pair.
    let link_args = project_config_json_str_array(meta, "link_args")
    var i = 0
    while i < link_args.len() as i32:
        let arg = link_args[i]
        if (arg == "-framework" or arg == "-weak_framework" or arg == "-Xlinker") and i + 1 < link_args.len() as i32:
            out.options = conan_cmake_push_unique(move out.options, "SHELL:" ++ arg ++ " " ++ link_args[i + 1])
            i = i + 2
            continue
        out.options = conan_cmake_push_unique(move out.options, arg)
        i = i + 1
    for required in project_config_json_str_array(meta, "requires"):
        out = conan_cmake_collect(project_root, required, move out, depth + 1)
    out

// One element of a CMake list inside a quoted argument; "" when it cannot be
// one (a `;` would split it).
fn conan_cmake_element(text: &str) -> str:
    if text.contains(";"): return ""
    text.replace("\\", "/").replace("\"", "\\\"").replace("$", "\\$")

fn conan_cmake_list(items: &List[str]) -> str:
    var out = ""
    for item in items:
        if out.len() > 0: out = out ++ ";"
        out = out ++ conan_cmake_element(item)
    out

fn conan_cmake_list_problem(items: &List[str]) -> str:
    for item in items:
        if item.contains(";"): return "'" ++ item ++ "' holds a `;`, which a CMake list cannot carry"
    ""

/// A package's own CMake config, as a source build's `cmake --install` leaves it.
fn conan_package_has_cmake_config(dep_dir: &str) -> bool:
    for dir in ["lib/cmake", "share", "cmake", "lib"]:
        for path in runtime_list_files(dep_dir ++ "/" ++ dir).split("\n"):
            if path.ends_with("Config.cmake") or path.ends_with("-config.cmake"): return true
    false

/// Writes the config for requirement `reference` under `cmake_deps_dir` and
/// returns the `-D<file>_DIR=<dir>` define CMake finds it by; "" when the
/// package brought its own config. `problem` is set when it cannot.
fn conan_write_cmake_package_config(project_root: &str, reference: &str, cmake_deps_dir: &str) -> ConanCMakeConfig:
    let name = conan_ref_name(reference)
    let version = conan_ref_version(reference)
    let dep_dir = conan_absolute(project_root ++ "/.with/deps/c/" ++ reference)
    if conan_package_has_cmake_config(dep_dir): return ConanCMakeConfig { define: "", problem: "" }
    let folder = conan_recipe_folder(name, version)
    let recipe = if folder.len() > 0: conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py")) else: ""
    var file_name = conan_recipe_cpp_info_property(recipe, "cmake_file_name")
    if file_name.len() == 0: file_name = name.to_owned()
    var target_name = conan_recipe_cpp_info_property(recipe, "cmake_target_name")
    if target_name.len() == 0: target_name = name ++ "::" ++ name
    let empty = ConanCMakeLinkSet { visited: List.new(), includes: List.new(), defines: List.new(), libraries: List.new(), options: List.new(), problem: "" }
    let set = conan_cmake_collect(project_root, reference, empty, 0)
    if set.problem.len() > 0: return ConanCMakeConfig { define: "", problem: set.problem.clone() }
    for list in [&set.includes, &set.defines, &set.libraries, &set.options]:
        let problem = conan_cmake_list_problem(list)
        if problem.len() > 0: return ConanCMakeConfig { define: "", problem: reference ++ ": " ++ problem }
    let dir = cmake_deps_dir ++ "/" ++ file_name
    if runtime_mkdir_p(dir) != 0: return ConanCMakeConfig { define: "", problem: "could not create " ++ dir }
    let target = conan_cmake_element(&target_name)
    var config = "# Written by `with get` from " ++ reference ++ "'s package metadata: what Conan's CMakeDeps writes at install time (#1900).\n"
    config = config ++ "if(NOT TARGET " ++ target ++ ")\n"
    config = config ++ "  add_library(" ++ target ++ " INTERFACE IMPORTED)\n"
    config = config ++ "  set_target_properties(" ++ target ++ " PROPERTIES\n"
    config = config ++ "    INTERFACE_INCLUDE_DIRECTORIES \"" ++ conan_cmake_list(&set.includes) ++ "\"\n"
    config = config ++ "    INTERFACE_COMPILE_DEFINITIONS \"" ++ conan_cmake_list(&set.defines) ++ "\"\n"
    config = config ++ "    INTERFACE_LINK_LIBRARIES \"" ++ conan_cmake_list(&set.libraries) ++ "\"\n"
    config = config ++ "    INTERFACE_LINK_OPTIONS \"" ++ conan_cmake_list(&set.options) ++ "\")\n"
    config = config ++ "endif()\n"
    config = config ++ "set(" ++ file_name ++ "_INCLUDE_DIRS \"" ++ conan_cmake_list(&set.includes) ++ "\")\n"
    config = config ++ "set(" ++ file_name ++ "_LIBRARIES " ++ target ++ ")\n"
    if runtime_write_file(dir ++ "/" ++ file_name ++ "Config.cmake", config) != 0:
        return ConanCMakeConfig { define: "", problem: "could not write " ++ dir ++ "/" ++ file_name ++ "Config.cmake" }
    // A version that is not a number ("system") answers no version request.
    if version.len() > 0 and version[0] >= '0' and version[0] <= '9':
        var major = version.to_owned()
        let dot = version.find(".")
        if dot > 0: major = version.slice(0, dot)
        var check = "set(PACKAGE_VERSION \"" ++ conan_cmake_element(version) ++ "\")\n"
        check = check ++ "if(PACKAGE_FIND_VERSION VERSION_GREATER PACKAGE_VERSION)\n  set(PACKAGE_VERSION_COMPATIBLE FALSE)\n"
        check = check ++ "elseif(PACKAGE_FIND_VERSION_MAJOR STREQUAL \"" ++ conan_cmake_element(&major) ++ "\")\n  set(PACKAGE_VERSION_COMPATIBLE TRUE)\n"
        check = check ++ "  if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)\n    set(PACKAGE_VERSION_EXACT TRUE)\n  endif()\n"
        check = check ++ "else()\n  set(PACKAGE_VERSION_COMPATIBLE FALSE)\nendif()\n"
        if runtime_write_file(dir ++ "/" ++ file_name ++ "ConfigVersion.cmake", check) != 0:
            return ConanCMakeConfig { define: "", problem: "could not write " ++ dir ++ "/" ++ file_name ++ "ConfigVersion.cmake" }
    ConanCMakeConfig { define: "-D" ++ file_name ++ "_DIR=" ++ dir, problem: "" }

type ConanCMakeConfig { define: str, problem: str }

fn conan_install_from_source(name: &str, version: &str, project_root: &str, depth: i32) -> str:
    let platform = conan_detect_os() ++ "/" ++ conan_detect_arch()
    let cmake_env_name = conan_package_cmake_env_name(name)
    let cmake_env = conan_package_cmake_env(name)
    if cmake_env.problem.len() > 0:
        return conan_source_fail("", cmake_env_name ++ " entry '" ++ cmake_env.problem ++ "' is not NAME=VALUE (entries are separated by `;`)")
    let why = if g_conan_from_source: "--from-source" else: if cmake_env.defines.len() > 0: cmake_env_name ++ " is set" else: if conan_builds_from_source_only(): "on Windows every C package is built by the SDK's toolchain" else: "Conan Center has no binary for " ++ platform ++ " that this toolchain can link"
    runtime_eprint("  " ++ why ++ "; building " ++ name ++ "/" ++ version ++ " from source")
    let folder = conan_recipe_folder(name, version)
    let data = if folder.len() > 0: conan_http_get(conan_recipe_file_url(name, folder, "conandata.yml")) else: ""
    let recipe = if folder.len() > 0: conan_http_get(conan_recipe_file_url(name, folder, "conanfile.py")) else: ""
    if data.len() == 0 or recipe.len() == 0:
        return conan_source_fail("", "could not read the Conan Center recipe of " ++ name ++ "/" ++ version)
    let source = conan_data_source(data, version)
    if source.urls.len() == 0 or source.sha256.len() == 0:
        return conan_source_fail("", "the recipe of " ++ name ++ " lists no source archive for " ++ version)
    // A recipe that ships its own CMakeLists.txt exports it; asking for one
    // that is not there is a 404 printed at the user.
    let exports_cmake = recipe.contains("\"CMakeLists.txt\", self.recipe_folder") or recipe.contains("\"CMakeLists.txt\", src=self.recipe_folder") or recipe.contains("exports_sources = \"CMakeLists.txt\"") or recipe.contains("exports_sources = [\"CMakeLists.txt\"")
    let patch_problem = conan_data_patch_problem(data, version)
    if patch_problem.len() > 0: return conan_source_fail("", name ++ "/" ++ version ++ " cannot be built from source: " ++ patch_problem)
    let recipe_cmake = if exports_cmake: conan_http_get(conan_recipe_file_url(name, folder, "CMakeLists.txt")) else: ""

    // Prerequisites first: say what is missing before downloading anything.
    if not with_cc_available():
        return conan_source_fail("", "building " ++ name ++ " from source needs `with cc`, and this build of `with` has none: the LLVM SDK it was linked against predates it")
    let cmake = conan_build_tool("cmake", "WITH_CMAKE")
    let ninja = conan_build_tool("ninja", "WITH_NINJA")
    if cmake.len() == 0 or ninja.len() == 0:
        let missing = if cmake.len() == 0 and ninja.len() == 0: "cmake and ninja" else: if cmake.len() == 0: "cmake" else: "ninja"
        if embedded_sdk_tools_dir().len() > 0:
            return conan_source_fail("", "building " ++ name ++ " from source needs " ++ missing ++ ", which this compiler's SDK tools (" ++ embedded_sdk_tools_dir() ++ ") lack; set WITH_CMAKE / WITH_NINJA to name them")
        if conan_builds_from_source_only():
            return conan_source_fail("", "building " ++ name ++ " from source needs the LLVM SDK's " ++ missing ++ " (" ++ link_stage_windows_sdk_dir() ++ "/bin), which it does not carry (or set WITH_CMAKE / WITH_NINJA)")
        return conan_source_fail("", "building " ++ name ++ " from source needs " ++ missing ++ ", which " ++ (if missing.contains(" and "): "are" else: "is") ++ " not on PATH; install " ++ (if missing.contains(" and "): "them" else: "it") ++ " (or set WITH_CMAKE / WITH_NINJA) and run `with get` again")
    let self_exe = conan_self_exe()
    if self_exe.len() == 0: return conan_source_fail("", "could not locate this `with` executable to use as the C compiler")

    var recipe_env = conan_built_recipe_env(version, "")
    let requires = recipe_requirements(recipe, &recipe_env)
    if not requires.ok: return conan_source_fail("", name ++ "/" ++ version ++ ": " ++ requires.problem)
    for undecided in requires.notes:
        runtime_eprint("  note: " ++ name ++ " recipe " ++ undecided ++ "; a requirement under it is not installed")
    let resolved: List[str] = List.new()
    for reference in requires.requires:
        let required = conan_ref_name(reference)
        let written = conan_ref_version(reference)
        // A version range asks for the newest release Conan Center has in it.
        let installed = conan_install_internal(required, written, project_root, depth + 1, false)
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
    runtime_eprint("  downloading " ++ source.urls[0])
    let picked = conan_pick_archive(&source, work, conan_archive_download, conan_archive_digest)
    let archive = picked.path.clone()
    let tried = picked.tried.clone()
    if archive.len() == 0: return conan_source_fail(dep_dir, "no source archive of " ++ name ++ "/" ++ version ++ " could be used:" ++ tried)
    if conan_extract_any(archive, raw_dir) != 0:
        return conan_source_fail(dep_dir, "could not extract " ++ conan_path_basename(archive) ++ " (it needs `tar`" ++ (if archive.ends_with(".zip"): " with zip support, or `unzip`" else: if archive.ends_with(".xz"): " and `xz`" else: "") ++ ")")
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

    recipe_env.source_folder = source_dir.clone()
    let variables = recipe_cmake_variables(recipe, &recipe_env)
    if not variables.ok: return conan_source_fail(dep_dir, name ++ "/" ++ version ++ ": " ++ variables.problem)
    for undecided in variables.notes: runtime_eprint("  note: " ++ name ++ " recipe " ++ undecided ++ "; a CMake variable under it is not set")
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
    // #1915: a project that declares C++ (raylib's `project(raylib C CXX)`)
    // gets clang's C++ driver too, never the host's c++.
    configure = conan_argv_append(configure, "-DCMAKE_CXX_COMPILER=" ++ conan_write_launcher_named(tools_dir, "c++", self_exe, "cc --driver-mode=g++"))
    configure = conan_argv_append(configure, "-DCMAKE_AR=" ++ conan_write_launcher(tools_dir, "__ar", self_exe))
    configure = conan_argv_append(configure, "-DCMAKE_RANLIB=" ++ conan_write_launcher(tools_dir, "__ranlib", self_exe))
    configure = conan_argv_append(configure, "-DCMAKE_BUILD_TYPE=Release")
    configure = conan_argv_append(configure, "-DBUILD_SHARED_LIBS=OFF")
    configure = conan_argv_append(configure, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
    configure = conan_argv_append(configure, "-DCMAKE_INSTALL_PREFIX=" ++ dep_dir)
    configure = conan_argv_append(configure, "-DCMAKE_INSTALL_LIBDIR=lib")
    // Windows (#1915): CMake's Windows-Clang module links every program with
    // Visual Studio's default library set; gdi32, winspool and comdlg32 are
    // not in the SDK (a package that uses them names them itself). Its
    // try_compile checks link programs too.
    if conan_builds_from_source_only():
        let standard_libraries = "-lkernel32 -luser32 -lshell32 -lole32 -loleaut32 -luuid -ladvapi32"
        configure = conan_argv_append(configure, "-DCMAKE_C_STANDARD_LIBRARIES=" ++ standard_libraries)
        configure = conan_argv_append(configure, "-DCMAKE_CXX_STANDARD_LIBRARIES=" ++ standard_libraries)
        configure = conan_argv_append(configure, "-DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES=CMAKE_C_STANDARD_LIBRARIES;CMAKE_CXX_STANDARD_LIBRARIES")
    if prefix_path.len() > 0: configure = conan_argv_append(configure, "-DCMAKE_PREFIX_PATH=" ++ prefix_path)
    // #1900: each requirement's CMake package config, as CMakeDeps writes it.
    for reference in resolved:
        let written = conan_write_cmake_package_config(project_root, reference, work ++ "/cmake-deps")
        if written.problem.len() > 0:
            return conan_source_fail(dep_dir, "could not write the CMake package config of " ++ reference ++ " for " ++ name ++ "/" ++ version ++ ": " ++ written.problem)
        if written.define.len() > 0: configure = conan_argv_append(configure, written.define)
    for i in 0..variables.names.len() as i32: configure = conan_argv_append(configure, "-D" ++ variables.names[i] ++ "=" ++ variables.values[i])
    for define in cmake_env.defines:
        runtime_eprint("  " ++ cmake_env_name ++ ": " ++ define)
        configure = conan_argv_append(configure, define)
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
    let package_env = conan_built_recipe_env(version, dep_dir)
    if conan_write_binary_metadata(name, version, "built", "built", source.sha256, dep_dir, resolved, &package_env, recipe, true) != 0:
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
    let cmake_env = conan_package_cmake_env(name)
    if g_conan_from_source or conan_builds_from_source_only() or cmake_env.defines.len() > 0 or cmake_env.problem.len() > 0:
        return conan_install_from_source(name, version, project_root, depth)
    let installed_binary = conan_install_binary(name, version, recipe_rev, project_root, depth, force_reinstall)
    if installed_binary.len() > 0:
        return installed_binary
    conan_install_from_source(name, version, project_root, depth)

// Public API. Returns the concrete installed version, or "" on failure.
pub fn conan_install(name: &str, version_hint: &str, project_root: &str, force_reinstall: bool) -> str:
    conan_install_internal(name, version_hint, project_root, 0, force_reinstall)
