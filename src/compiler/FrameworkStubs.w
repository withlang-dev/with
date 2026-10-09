// Apple framework link stubs from the running OS (#1915).
//
// A macOS program that links Cocoa, IOKit or OpenGL links against text stubs
// (.tbd) of those frameworks. The Apple SDK is where such stubs usually come
// from, and the toolchain reads no Apple SDK (Eric, 2026-09-29: "zero
// dependencies ... except our own SDK and system calls"; "`with get
// c.raylib` should handle that"). The frameworks themselves are part of the
// OS: since macOS 11 their code lives in the dyld shared cache. So `with get`
// writes each stub a package needs from that cache (conan_write_metadata):
// the install name, versions, re-exported libraries and exported symbols of
// the framework and of every library it re-exports, as one multi-document
// .tbd at <dir>/<Name>.framework/<Name>.tbd, which lld finds with -F<dir>.
//
// The cache: a main file and its sub-caches (dyld_shared_cache_<arch> and
// dyld_shared_cache_<arch>.NN*), each with a header, `dyld_v1`, mapping VM
// address ranges to file offsets; the main file lists the images. An image's
// Mach-O header is at its VM address; its exports trie is in the shared
// __LINKEDIT, located through that segment's VM address.

use compiler.Runtime
use std.string.StringBuilder

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_str_from_bytes(s: *const u8, len: i64) -> str
extern fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32
extern fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64
extern fn rt_read(fd: i32, buf: *mut u8, len: i64) -> i64
extern fn rt_close(fd: i32) -> i32

type DscMapping { address: i64, size: i64, file_offset: i64, fd: i32 }
type DscImage { address: i64, path: str }

type DscCache {
    fds: List[i32],
    mappings: List[DscMapping],
    images: List[DscImage],
    problem: str,
}

// One library's stub document.
type DscLibrary {
    install_name: str,
    current_version: str,
    compatibility_version: str,
    reexports: List[str],
    symbols: List[str],
    weak_symbols: List[str],
    tls_symbols: List[str],
    problem: str,
}

fn fs_u32(data: &str, at: i64) -> i64:
    if at < 0 or at + 4 > data.len(): return 0
    data[at] as i64 + data[at + 1] as i64 * 256 + data[at + 2] as i64 * 65536 + data[at + 3] as i64 * 16777216

fn fs_u64(data: &str, at: i64) -> i64:
    fs_u32(data, at) + fs_u32(data, at + 4) * 4294967296

// The NUL-terminated string at `at`.
fn fs_cstr(data: &str, at: i64) -> str:
    if at < 0 or at >= data.len(): return ""
    var end = at
    while end < data.len() and data[end] != 0:
        end = end + 1
    data.slice(at, end)

unsafe fn fs_c_path(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if s.len() > 0:
        with_memcpy(out, *(s as *const str as *const *const u8), s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

fn fs_open(path: &str) -> i32:
    unsafe:
        let c = fs_c_path(path)
        let fd = rt_open(c as *const u8, 0, 0)
        with_free(c)
        fd

// `len` bytes of `fd` at `offset`; fewer only at the end of the file.
fn fs_read_at(fd: i32, offset: i64, len: i64) -> str:
    if len <= 0: return ""
    unsafe:
        if rt_seek(fd, offset, 0) != offset: return ""
        let buf = with_alloc(len)
        var got: i64 = 0
        while got < len:
            let n = rt_read(fd, (buf as i64 + got) as *mut u8, len - got)
            if n <= 0: break
            got = got + n
        let out = with_str_from_bytes(buf as *const u8, got)
        with_free(buf)
        out

// The shared cache of this machine: the Cryptex copy (macOS 13 and later),
// else the one under /System/Library/dyld.
fn fs_cache_path() -> str:
    let arch = if runtime_sysinfo_arch() == "x86_64": "x86_64" else: "arm64e"
    let cryptex = "/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_" ++ arch
    if runtime_file_exists(cryptex) != 0: return cryptex
    let system = "/System/Library/dyld/dyld_shared_cache_" ++ arch
    if runtime_file_exists(system) != 0: return system
    ""

fn fs_basename(path: &str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        if path[i] == '/': start = i + 1
    path.slice(start, path.len())

fn fs_dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path[i] == '/': last = i
    if last <= 0: "/" else: path.slice(0, last)

fn fs_cache_error(message: &str) -> DscCache:
    DscCache { fds: List.new(), mappings: List.new(), images: List.new(), problem: message.to_owned() }

// Opens the main cache file and every sub-cache beside it, and reads their
// mappings and the image list.
fn fs_open_cache() -> DscCache:
    let main_path = fs_cache_path()
    if main_path.len() == 0:
        return fs_cache_error("no dyld shared cache on this machine (looked in /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld and /System/Library/dyld)")
    let base = fs_basename(main_path)
    let files: List[str] = List.new()
    files.push(main_path.clone())
    for line in runtime_list_files(fs_dirname(main_path)).split("\n"):
        let name = fs_basename(line)
        // dyld_shared_cache_arm64e.01, .02.dylddata, ...; not the .map or
        // .atlas side files, and not the local-symbols file.
        if name.starts_with(base ++ ".") and not name.ends_with(".map") and not name.ends_with(".atlas") and not name.ends_with(".symbols"):
            files.push(fs_dirname(main_path) ++ "/" ++ name)
    var cache = DscCache { fds: List.new(), mappings: List.new(), images: List.new(), problem: "" }
    for f in 0..files.len() as i32:
        let fd = fs_open(files[f])
        if fd < 0:
            return fs_cache_error("could not open " ++ files[f])
        cache.fds.push(fd)
        let header = fs_read_at(fd, 0, 0x200)
        if not header.starts_with("dyld_v1"):
            return fs_cache_error(files[f] ++ " is not a dyld shared cache")
        let mapping_offset = fs_u32(header, 0x10)
        let mapping_count = fs_u32(header, 0x14)
        let mappings = fs_read_at(fd, mapping_offset, mapping_count * 32)
        for m in 0..mapping_count:
            let at = m * 32
            cache.mappings.push(DscMapping { address: fs_u64(mappings, at), size: fs_u64(mappings, at + 8), file_offset: fs_u64(mappings, at + 16), fd })
        if f == 0:
            // imagesOffsetOld/imagesCountOld, else imagesOffset/imagesCount.
            var images_offset = fs_u32(header, 0x18)
            var images_count = fs_u32(header, 0x1c)
            if images_offset == 0:
                images_offset = fs_u32(header, 0x1c0)
                images_count = fs_u32(header, 0x1c4)
            if images_offset == 0 or images_count == 0:
                return fs_cache_error(files[f] ++ " lists no images")
            let infos = fs_read_at(fd, images_offset, images_count * 32)
            for i in 0..images_count:
                let path = fs_cstr(fs_read_at(fd, fs_u32(infos, i * 32 + 24), 1024), 0)
                cache.images.push(DscImage { address: fs_u64(infos, i * 32), path })
    cache

fn fs_close_cache(cache: &DscCache):
    for i in 0..cache.fds.len() as i32:
        let _ = rt_close(cache.fds[i])

// `len` bytes at VM address `address`, from the file its mapping lies in.
fn fs_read_vm(cache: &DscCache, address: i64, len: i64) -> str:
    for i in 0..cache.mappings.len() as i32:
        let m = cache.mappings[i]
        if address >= m.address and address < m.address + m.size:
            return fs_read_at(m.fd, m.file_offset + (address - m.address), len)
    ""

fn fs_image_address(cache: &DscCache, install_name: &str) -> i64:
    for i in 0..cache.images.len() as i32:
        if cache.images[i].path == install_name: return cache.images[i].address
    -1

// /System/Library/Frameworks/<Name>.framework/.../<Name>, as the cache lists it.
fn fs_framework_install_name(cache: &DscCache, name: &str) -> str:
    let prefix = "/System/Library/Frameworks/" ++ name ++ ".framework/"
    for i in 0..cache.images.len() as i32:
        let path = cache.images[i].path
        if path.starts_with(prefix) and path.ends_with("/" ++ name):
            return path.clone()
    ""

fn fs_version(v: i64) -> str:
    let major = v / 65536
    let minor = (v / 256) % 256
    let patch = v % 256
    if patch != 0: f"{major}.{minor}.{patch}" else: f"{major}.{minor}"

type FsUleb { value: i64, next: i64 }

fn fs_uleb(data: &str, at: i64) -> FsUleb:
    var value: i64 = 0
    var shift: i64 = 0
    var i = at
    while i < data.len():
        let b = data[i] as i64
        i = i + 1
        if shift < 63:
            var part = b % 128
            var s: i64 = 0
            while s < shift:
                part = part * 2
                s = s + 1
            value = value + part
        shift = shift + 7
        if b < 128: return FsUleb { value, next: i }
    FsUleb { value: -1, next: data.len() }

fn fs_library_error(install_name: &str, message: &str) -> DscLibrary:
    DscLibrary { install_name: install_name.to_owned(), current_version: "", compatibility_version: "", reexports: List.new(), symbols: List.new(), weak_symbols: List.new(), tls_symbols: List.new(), problem: message.to_owned() }

// The exports of the image `install_name`: its load commands for the
// identity and re-exports, its exports trie for the symbols.
fn fs_read_library(cache: &DscCache, install_name: &str) -> DscLibrary:
    let address = fs_image_address(cache, install_name)
    if address < 0:
        return fs_library_error(install_name, "not in the dyld shared cache: " ++ install_name)
    let head = fs_read_vm(cache, address, 32)
    if fs_u32(head, 0) != 0xfeedfacf:
        return fs_library_error(install_name, "no 64-bit Mach-O header for " ++ install_name)
    let ncmds = fs_u32(head, 16)
    let cmds = fs_read_vm(cache, address, 32 + fs_u32(head, 20))
    var library = DscLibrary { install_name: install_name.to_owned(), current_version: "1", compatibility_version: "1", reexports: List.new(), symbols: List.new(), weak_symbols: List.new(), tls_symbols: List.new(), problem: "" }
    var linkedit_vm: i64 = -1
    var linkedit_file: i64 = 0
    var trie_off: i64 = -1
    var trie_size: i64 = 0
    var at: i64 = 32
    for _ in 0..ncmds:
        let cmd = fs_u32(cmds, at)
        let size = fs_u32(cmds, at + 4)
        if size < 8: break
        if cmd == 0x19 and fs_cstr(cmds.slice(at + 8, at + 24), 0) == "__LINKEDIT":
            linkedit_vm = fs_u64(cmds, at + 24)
            linkedit_file = fs_u64(cmds, at + 40)
        else if cmd == 0xd:
            library.current_version = fs_version(fs_u32(cmds, at + 16))
            library.compatibility_version = fs_version(fs_u32(cmds, at + 20))
        else if cmd == 0x8000001f:
            library.reexports.push(fs_cstr(cmds, at + fs_u32(cmds, at + 8)))
        else if cmd == 0x80000033:
            trie_off = fs_u32(cmds, at + 8)
            trie_size = fs_u32(cmds, at + 12)
        else if (cmd == 0x22 or cmd == 0x80000022) and trie_off < 0:
            trie_off = fs_u32(cmds, at + 40)
            trie_size = fs_u32(cmds, at + 44)
        at = at + size
    if trie_off < 0 or trie_size == 0:
        return library
    if linkedit_vm < 0:
        return fs_library_error(install_name, "no __LINKEDIT segment in " ++ install_name)
    let trie = fs_read_vm(cache, linkedit_vm + (trie_off - linkedit_file), trie_size)
    if trie.len() != trie_size:
        return fs_library_error(install_name, "could not read the exports trie of " ++ install_name)
    // Depth-first over the trie: each node is a terminal (its export flags)
    // and edges (a label and a child offset).
    let prefixes: List[str] = List.new()
    let nodes: List[i64] = List.new()
    prefixes.push("")
    nodes.push(0)
    var visited = 0
    while nodes.len() > 0:
        visited = visited + 1
        if visited > trie_size:
            return fs_library_error(install_name, "a cycle in the exports trie of " ++ install_name)
        let node = nodes.pop().unwrap()
        let prefix = prefixes.pop().unwrap()
        let terminal = fs_uleb(trie, node)
        if terminal.value < 0:
            return fs_library_error(install_name, "a malformed exports trie in " ++ install_name)
        if terminal.value > 0:
            let flags = fs_uleb(trie, terminal.next).value
            let kind = flags % 4
            let weak = (flags / 4) % 2 == 1
            if kind == 1:
                library.tls_symbols.push(prefix.clone())
            else if weak:
                library.weak_symbols.push(prefix.clone())
            else:
                library.symbols.push(prefix.clone())
        var child_at = terminal.next + terminal.value
        if child_at >= trie.len(): continue
        let children = trie[child_at] as i64
        child_at = child_at + 1
        for _ in 0..children:
            let label = fs_cstr(trie, child_at)
            child_at = child_at + label.len() + 1
            let child = fs_uleb(trie, child_at)
            child_at = child.next
            if child.value <= 0 or child.value >= trie.len():
                return fs_library_error(install_name, "a malformed exports trie in " ++ install_name)
            prefixes.push(prefix ++ label)
            nodes.push(child.value)
    library

fn fs_str_less(a: &str, b: &str) -> bool:
    let n = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..n:
        if a[i] != b[i]: return a[i] < b[i]
    a.len() < b.len()

fn fs_sorted(items: &List[str]) -> List[str]:
    if items.len() <= 1:
        let one: List[str] = List.new()
        for i in 0..items.len() as i32: one.push(items[i].clone())
        return one
    let mid = items.len() as i32 / 2
    let left: List[str] = List.new()
    let right: List[str] = List.new()
    for i in 0..items.len() as i32:
        if i < mid: left.push(items[i].clone()) else: right.push(items[i].clone())
    let a = fs_sorted(&left)
    let b = fs_sorted(&right)
    let out: List[str] = List.new()
    var i = 0
    var j = 0
    while i < a.len() as i32 or j < b.len() as i32:
        if j >= b.len() as i32 or (i < a.len() as i32 and not fs_str_less(b[j], a[i])):
            out.push(a[i].clone())
            i = i + 1
        else:
            out.push(b[j].clone())
            j = j + 1
    out

fn fs_yaml_list(out: &str, key: &str, items: &List[str]) -> str:
    if items.len() == 0: return out.to_owned()
    var text = StringBuilder.new()
    text.push_str(out)
    text.push_str("    " ++ key ++ ":")
    var pad = 17 - key.len() as i32 - 1
    while pad > 0:
        text.push_str(" ")
        pad = pad - 1
    text.push_str("[ ")
    let sorted = fs_sorted(items)
    for i in 0..sorted.len() as i32:
        if i > 0: text.push_str(",\n                       ")
        text.push_str("'" ++ sorted[i].replace("'", "''") ++ "'")
    text.push_str(" ]\n")
    text.to_str()

fn fs_tbd_document(library: &DscLibrary) -> str:
    // The cache's architecture: arm64e serves arm64 and arm64e links.
    let targets = if runtime_sysinfo_arch() == "x86_64": "[ x86_64-macos ]" else: "[ arm64-macos, arm64e-macos ]"
    var out = "--- !tapi-tbd\ntbd-version:     4\ntargets:         " ++ targets ++ "\n"
    out = out ++ "install-name:    '" ++ library.install_name ++ "'\n"
    out = out ++ "current-version: " ++ library.current_version ++ "\n"
    out = out ++ "compatibility-version: " ++ library.compatibility_version ++ "\n"
    if library.reexports.len() > 0:
        out = out ++ "reexported-libraries:\n  - targets:         " ++ targets ++ "\n"
        out = fs_yaml_list(out, "libraries", &library.reexports)
    if library.symbols.len() + library.weak_symbols.len() + library.tls_symbols.len() > 0:
        out = out ++ "exports:\n  - targets:         " ++ targets ++ "\n"
        out = fs_yaml_list(out, "symbols", &library.symbols)
        out = fs_yaml_list(out, "weak-symbols", &library.weak_symbols)
        out = fs_yaml_list(out, "thread-local-symbols", &library.tls_symbols)
    out

// The .tbd of framework `name`: its document, then one per library it
// re-exports, transitively (Cocoa re-exports AppKit, Foundation, CoreData;
// lld reads re-exports from the documents of the same file). "" and the
// reason in `problem` when the cache cannot answer.
fn fs_framework_tbd(cache: &DscCache, name: &str) -> str:
    let install_name = fs_framework_install_name(cache, name)
    if install_name.len() == 0:
        return "error: no framework " ++ name ++ " in this machine's dyld shared cache"
    let queue: List[str] = List.new()
    let seen: List[str] = List.new()
    queue.push(install_name)
    var text = StringBuilder.new()
    var next = 0
    while next < queue.len() as i32:
        let current = queue[next].clone()
        next = next + 1
        let library = fs_read_library(cache, current)
        if library.problem.len() > 0:
            return "error: " ++ library.problem
        text.push_str(fs_tbd_document(&library))
        for r in 0..library.reexports.len() as i32:
            var known = false
            for s in 0..queue.len() as i32:
                if queue[s] == library.reexports[r]: known = true
            if not known: queue.push(library.reexports[r].clone())
    text.push_str("...\n")
    text.to_str()

// Writes <dir>/<Name>.framework/<Name>.tbd for each framework name, from
// this machine's dyld shared cache. "" when every stub is written, else why
// not.
pub fn framework_stubs_write(dir: &str, names: &List[str]) -> str:
    if runtime_sysinfo_os() != "Macos":
        return "Apple framework stubs are generated on macOS only"
    let cache = fs_open_cache()
    if cache.problem.len() > 0:
        fs_close_cache(&cache)
        return cache.problem.clone()
    for i in 0..names.len() as i32:
        let tbd = fs_framework_tbd(&cache, names[i])
        if tbd.starts_with("error: "):
            fs_close_cache(&cache)
            return tbd.slice(7, tbd.len())
        let framework_dir = dir ++ "/" ++ names[i] ++ ".framework"
        if runtime_mkdir_p(framework_dir) != 0 or runtime_write_file(framework_dir ++ "/" ++ names[i] ++ ".tbd", tbd) != 0:
            fs_close_cache(&cache)
            return "could not write " ++ framework_dir ++ "/" ++ names[i] ++ ".tbd"
    fs_close_cache(&cache)
    ""

// The framework names of `-framework <Name>` and `-weak_framework <Name>`
// pairs in a package's link arguments: a weakly linked framework needs its
// stub at link time as any other does.
pub fn framework_names_in_link_args(link_args: &List[str]) -> List[str]:
    let out: List[str] = List.new()
    for i in 0..link_args.len() as i32:
        if (link_args[i] == "-framework" or link_args[i] == "-weak_framework") and i + 1 < link_args.len() as i32:
            out.push(link_args[i + 1].clone())
    out

// `with __framework-stubs <dir> <Name>...`: the step `with get` runs, on its
// own (the :no-host-toolchain check uses it).
pub fn with_framework_stubs_main(args: &List[str]) -> i32:
    if args.len() < 2:
        runtime_eprint("usage: with __framework-stubs <dir> <Framework>...")
        return 2
    let names: List[str] = List.new()
    for i in 1..args.len() as i32: names.push(args[i].clone())
    let problem = framework_stubs_write(args[0], &names)
    if problem.len() > 0:
        runtime_eprint("error: framework stubs: " ++ problem)
        return 1
    0
