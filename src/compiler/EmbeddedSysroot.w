// The darwin sysroot (#1915): the macOS libc headers and the libSystem /
// libc++ link stubs, embedded in this binary at build time (build/sdk.w
// run_darwin_sysroot_action writes the pack; build.w embeds it as the
// `darwin_sysroot` blob) and materialized to a cache directory on first use.
// A macOS link (-syslibroot) and c_import (-isysroot) read this directory, so
// building a With program reads nothing from Xcode, the Command Line Tools
// or an Apple SDK. Only the program names another SDK: with.toml's
// [c_import] sdk_path (§16.1, D81: "No host SDK is consulted unless the
// program names one"). An environment variable (SDKROOT, which Xcode's
// tools and many shells set) is not the program naming one.
//
// The pack is text: "WITH-SYSROOT 1\n", then per file "F <path> <size>\n"
// and its bytes, per alias "A <path> <target>\n" (the target's bytes again).
// A compiler built off macOS carries an empty pack.

use compiler.Runtime

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_str_hash(s: &str) -> u64

extern let with_embedded_darwin_sysroot_start: u8
extern let with_embedded_darwin_sysroot_end: u8

// with.toml [c_import] sdk_path (§16.1), set by the frontend.
var g_darwin_configured_sdk: str = ""
var g_darwin_sysroot_dir: str = ""
var g_darwin_sysroot_resolved: bool = false

pub fn darwin_sdk_set_configured(path: &str):
    g_darwin_configured_sdk = with_str_clone_ref(path)

fn es_str_from_raw_parts(ptr: *const u8, len: i64) -> str:
    if ptr as i64 == 0 or len <= 0:
        return ""
    var out: str = ""
    unsafe:
        let sp = &raw mut out as *mut u8
        *(sp as *mut u64) = ptr as u64
        *((sp + 8u64) as *mut i64) = len
    out

fn es_pack() -> str:
    let start = &with_embedded_darwin_sysroot_start as *const u8
    let end = &with_embedded_darwin_sysroot_end as *const u8
    es_str_from_raw_parts(start, end as i64 - start as i64)

fn es_dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path[i] == '/':
            last = i
    if last <= 0: "" else: path.slice(0, last as i64)

// The user's cache directory for what this compiler materializes.
pub fn with_user_cache_dir() -> str:
    let xdg = runtime_getenv("XDG_CACHE_HOME")
    if xdg.len() > 0:
        return xdg
    let home = runtime_getenv("HOME")
    if home.len() == 0: "/tmp/with-cache" else: home ++ "/.cache"

// A path in the pack is relative and stays inside the sysroot.
fn es_path_ok(rel: &str) -> bool:
    rel.len() > 0 and rel[0] != '/' and rel.find("..") < 0

fn es_parse_size(text: &str) -> i64:
    if text.len() == 0:
        return -1
    var n: i64 = 0
    for i in 0..text.len() as i32:
        let ch = text[i]
        if ch < '0' or ch > '9':
            return -1
        n = n * 10 + (ch - '0') as i64
    n

// Writes every entry of `pack` under `dir`; "" on success, else the reason.
fn es_unpack(pack: &str, dir: &str) -> str:
    let magic = "WITH-SYSROOT 1\n"
    if not pack.starts_with(magic):
        return "the embedded darwin sysroot is not a sysroot pack"
    var at = magic.len() as i64
    while at < pack.len():
        let rest = pack.slice(at, pack.len())
        let eol = rest.find("\n")
        if eol < 0:
            return "truncated entry header in the embedded darwin sysroot"
        let header = rest.slice(0, eol as i64)
        at = at + eol as i64 + 1
        let fields = header.split(" ")
        if fields.len() != 3 or not es_path_ok(fields[1]):
            return "bad entry in the embedded darwin sysroot: " ++ header
        let dest = dir ++ "/" ++ fields[1]
        let parent = es_dirname(dest)
        if parent.len() > 0 and runtime_mkdir_p(parent) != 0:
            return "could not create " ++ parent
        var bytes = ""
        if fields[0] == "F":
            let size = es_parse_size(fields[2])
            if size < 0 or at + size > pack.len():
                return "bad size in the embedded darwin sysroot: " ++ header
            bytes = pack.slice(at, at + size)
            at = at + size
        else if fields[0] == "A" and es_path_ok(fields[2]):
            bytes = runtime_read_file(dir ++ "/" ++ fields[2])
        else:
            return "bad entry in the embedded darwin sysroot: " ++ header
        if with_fs_write_file(dest, bytes) != 0:
            return "could not write " ++ dest
    ""

// The materialized embedded sysroot, or "" when this binary carries none
// (built off macOS) or it could not be written (the reason is printed).
// The directory is keyed by the pack's hash: a compiler with other stubs or
// headers never reads this one's. It is unpacked beside its final name and
// renamed into place, so a concurrent build sees it complete or not at all.
pub fn embedded_darwin_sysroot_dir() -> str:
    if g_darwin_sysroot_resolved:
        return with_str_clone_ref(g_darwin_sysroot_dir)
    g_darwin_sysroot_resolved = true
    let pack = es_pack()
    if pack.len() == 0:
        return ""
    let root = with_user_cache_dir() ++ "/with/sysroot/darwin-" ++ f"{with_str_hash(pack)}"
    let stamp = root ++ "/.with-sysroot-ready"
    if with_fs_file_exists(stamp) == 0:
        let tmp = root ++ f".tmp.{runtime_getpid()}.{runtime_clock_nanos()}"
        let problem = es_unpack(pack, tmp)
        if problem.len() > 0:
            let _ = runtime_remove_tree(tmp)
            runtime_eprint("error: could not materialize the darwin sysroot at " ++ root ++ ": " ++ problem)
            return ""
        if with_fs_write_file(tmp ++ "/.with-sysroot-ready", "ok\n") != 0:
            let _ = runtime_remove_tree(tmp)
            runtime_eprint("error: could not write " ++ tmp ++ "/.with-sysroot-ready")
            return ""
        if runtime_rename(tmp, root) != 0:
            // Another build won the rename; its copy is complete.
            let _ = runtime_remove_tree(tmp)
            if with_fs_file_exists(stamp) == 0:
                runtime_eprint("error: could not move the darwin sysroot into " ++ root)
                return ""
    g_darwin_sysroot_dir = root
    with_str_clone_ref(g_darwin_sysroot_dir)

// The macOS SDK a link and c_import read: with.toml [c_import] sdk_path when
// the program names one, else the embedded sysroot. "" only when this
// compiler carries no sysroot and the program names none.
pub fn darwin_sdk_root() -> str:
    if g_darwin_configured_sdk.len() > 0:
        return with_str_clone_ref(g_darwin_configured_sdk)
    embedded_darwin_sysroot_dir()

// darwin_sdk_root() on a macOS host, "" elsewhere (c_import on another host
// reads that host's headers; a cross target names its own).
pub fn host_darwin_sdk_root() -> str:
    if runtime_sysinfo_os() != "Macos": "" else: darwin_sdk_root()
