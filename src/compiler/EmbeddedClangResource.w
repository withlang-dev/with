// Materialize clang's builtin headers — embedded in this binary at build time
// (out/gen/compiler/EmbeddedClangResourceData.w) — into a versioned on-disk
// cache, and return the resource dir for clang's -resource-dir. This is what
// makes c_import self-contained at runtime: no external LLVM resource dir,
// llvm-config, or system clang is consulted (#312).
//
// libclang reads headers from real files, so the embedded bytes must be written
// to disk; we cache them under <cache>/with/clang-resource/<v>/include and skip
// the work once a completion stamp exists. clang_bridge calls the exported
// with_ensure_clang_resource_dir() via extern.

use compiler.EmbeddedClangResourceData

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_getenv_str(name: str) -> str

fn ecr_dirname(path: str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return ""
    path.slice(0, last as i64)

fn ecr_cache_root() -> str:
    let version = embedded_clang_resource_version()
    var base = with_getenv_str("XDG_CACHE_HOME")
    if base.len() == 0:
        let home = with_getenv_str("HOME")
        if home.len() == 0:
            base = "/tmp/with-cache"
        else:
            base = home ++ "/.cache"
    base ++ "/with/clang-resource/" ++ version

@[c_export("with_ensure_clang_resource_dir")]
pub fn ensure_clang_resource_dir() -> str:
    let root = ecr_cache_root()
    let include_dir = root ++ "/include"
    let stamp = root ++ "/.with-resource-ready"
    if with_fs_file_exists(stamp) != 0:
        return root
    let listing = embedded_clang_resource_list()
    // Each line of the listing is an include-dir-relative path; write its
    // embedded contents, creating parent directories as needed.
    var start = 0
    var i = 0
    while i <= listing.len() as i32:
        let at_end = i == listing.len() as i32
        if at_end or listing.byte_at(i as i64) == 10:
            if i > start:
                let rel = listing.slice(start as i64, i as i64)
                let dest = include_dir ++ "/" ++ rel
                let parent = ecr_dirname(dest)
                if parent.len() > 0:
                    let _mk = with_fs_mkdir_p(parent)
                let _w = with_fs_write_file(dest, embedded_clang_resource_data(rel))
            start = i + 1
        i = i + 1
    // Stamp last, so a concurrent reader only takes the fast path once complete.
    let _stamp = with_fs_write_file(stamp, "ok\n")
    root
