use compiler.Runtime

// Where a Linux host keeps the libraries a program links (`-lGL`), and which
// file `-l<name>` means there. One owner for the link and for `with get`.
//
// No distribution is named. The directories are the host's own answer: the
// toolchain's LIBRARY_PATH, the dynamic loader's trusted directories (glibc's
// ld.so searches them on every distribution; Debian adds its multiarch pair,
// 64-bit Fedora/SUSE/Gentoo lib64) and every directory /etc/ld.so.conf names.
// Those last include other architectures' libraries (SteamOS lists
// /usr/lib32), and lld refuses an incompatible library rather than skipping
// it as GNU ld does, so each candidate is checked against the target machine.

fn host_lib_multiarch(arch: &str): if arch == "aarch64": "aarch64-linux-gnu" else: "x86_64-linux-gnu"

// ELF e_machine: EM_AARCH64, EM_X86_64.
fn host_lib_elf_machine(arch: &str): if arch == "aarch64": 183 else: 62

fn host_lib_push_dir(dirs: List[str], dir: &str) -> List[str]:
    var out = dirs
    if dir.len() == 0 or runtime_is_dir(dir) == 0: return out
    for d in out:
        if d == dir: return out
    out.push(dir)
    out

fn host_lib_sorted(xs: List[str]) -> List[str]:
    var out: List[str] = List.new()
    for x in xs:
        var i = out.len()
        out.push(x)
        while i > 0 and out[i - 1] > out[i]:
            let prev = out[i - 1].clone()
            out[i - 1] = out[i].clone()
            out[i] = prev
            i -= 1
    out

// The `include` operand's files: a path, or a `*` pattern in the final
// component (`/etc/ld.so.conf.d/*.conf`), in name order as ldconfig reads them.
fn host_lib_conf_includes(root: &str, pattern: &str) -> List[str]:
    var out: List[str] = List.new()
    let path = if pattern.starts_with("/"): root ++ pattern else: root ++ "/etc/" ++ pattern
    let star = path.find("*")
    if star < 0:
        out.push(path)
        return out
    let slash = path.slice(0, star).rfind("/")
    if slash < 0: return out
    let prefix = path.slice(0, star)
    let suffix = path.slice(star + 1, path.len())
    if suffix.contains("/") or suffix.contains("*"): return out
    for file in runtime_list_files(path.slice(0, slash)).split("\n"):
        if file.len() > prefix.len() + suffix.len() and file.starts_with(prefix) and file.ends_with(suffix):
            out.push(file)
    host_lib_sorted(out)

fn host_lib_read_conf(root: &str, conf: &str, depth: i32, dirs: List[str]) -> List[str]:
    var out = dirs
    if depth > 8: return out
    for raw in runtime_read_file(conf).split("\n"):
        let hash = raw.find("#")
        let text = if hash >= 0: raw.slice(0, hash) else: raw
        let line = text.trim()
        if line.len() == 0 or line.starts_with("hwcap "): continue
        if line.starts_with("include ") or line.starts_with("include\t"):
            for operand in line.slice(8, line.len()).fields():
                for file in host_lib_conf_includes(root, operand):
                    out = host_lib_read_conf(root, file, depth + 1, out)
        else:
            for dir in line.split(":"):
                let d = dir.trim()
                if d.starts_with("/"): out = host_lib_push_dir(out, root ++ d)
    out

fn host_lib_push_trusted(dirs: List[str], root: &str, arch: &str) -> List[str]:
    var out = dirs
    let multiarch = host_lib_multiarch(arch)
    for dir in ["/usr/lib/" ++ multiarch, "/lib/" ++ multiarch, "/usr/lib64", "/lib64", "/usr/lib", "/lib"]:
        out = host_lib_push_dir(out, root ++ dir)
    out

/// The loader's trusted directories that exist under `root` ("" for the
/// running host): where the C library itself lives, whatever the layout.
pub fn host_library_trusted_dirs(root: &str, arch: &str): host_lib_push_trusted(List.new(), root, arch)

/// The directories a link searches for a library the program names, in
/// order, each existing once. `root` is "" for the running host, else a
/// sysroot; LIBRARY_PATH is the running host's alone.
pub fn host_library_dirs(root: &str, arch: &str) -> List[str]:
    var dirs: List[str] = List.new()
    if root.len() == 0:
        for dir in runtime_getenv("LIBRARY_PATH").split(":"):
            if dir.starts_with("/"): dirs = host_lib_push_dir(dirs, dir)
    dirs = host_lib_push_trusted(dirs, root, arch)
    host_lib_read_conf(root, root ++ "/etc/ld.so.conf", 0, dirs)

fn host_lib_u16_le(data: &str, offset: i64) -> i64:
    if offset + 1 >= data.len(): -1 else: (data[offset] as i64) | ((data[offset + 1] as i64) << 8)

// An ELF header at `offset` that names another machine. Text (a linker
// script) and anything unreadable are not provably foreign: the linker reads
// those and says what it finds.
fn host_lib_elf_foreign(data: &str, offset: i64, arch: &str) -> bool:
    if offset + 20 > data.len(): return false
    if data[offset] != 0x7f or data[offset + 1] != 'E' or data[offset + 2] != 'L' or data[offset + 3] != 'F': return false
    data[offset + 4] != 2 or host_lib_u16_le(data, offset + 18) != host_lib_elf_machine(arch)

// An ar header's decimal field, -1 when it is not one.
fn host_lib_decimal(text: &str) -> i64:
    if text.len() == 0: return -1
    var value: i64 = 0
    for i in 0..text.len():
        let ch = text[i]
        if ch < '0' or ch > '9': return -1
        value = value * 10 + (ch - '0') as i64
    value

// An ar archive's first object member names another machine (the symbol
// table "/", "/SYM64/" and the long-name table "//" carry no machine).
fn host_lib_archive_foreign(data: &str, arch: &str) -> bool:
    var offset: i64 = 8
    var members = 0
    while offset + 60 <= data.len() and members < 16:
        let header = data.slice(offset, offset + 60)
        let name = header.slice(0, 16)
        let size = host_lib_decimal(header.slice(48, 58).trim())
        if size < 0: return false
        let body = offset + 60
        if not name.starts_with("/ ") and not name.starts_with("// ") and not name.starts_with("/SYM64/ "): return host_lib_elf_foreign(data, body, arch)
        offset = body + size + (size & 1)
        members += 1
    false

/// The file is a library a link for `arch` can use: it exists, and it is
/// neither an ELF file nor an archive built for another machine.
pub fn host_library_usable(path: &str, arch: &str) -> bool:
    if runtime_file_exists(path) == 0 or runtime_is_dir(path) != 0: return false
    let data = runtime_read_file(path)
    if data.starts_with("!<arch>\n"): not host_lib_archive_foreign(data, arch) else: not host_lib_elf_foreign(data, 0, arch)

/// The file `-l<name>` means in `dirs`, "" when none (the link keeps
/// `-l<name>` so the linker's own "unable to find" is the diagnostic). A
/// directory's `lib<name>.so`, then its `lib<name>.a`, as ld searches; else,
/// since `lib<name>.so` comes only with a development package and a runtime
/// package installs `lib<name>.so.<N>` alone, the highest such soname, as the
/// symlink would name. `:<file>` names the file itself.
pub fn host_library_path(dirs: &List[str], name: &str, arch: &str) -> str:
    if name.starts_with(":"):
        for dir in dirs:
            let path = dir ++ "/" ++ name.slice(1, name.len())
            if host_library_usable(path, arch): return path
        return ""
    for dir in dirs:
        for ext in [".so", ".a"]:
            let path = dir ++ "/lib" ++ name ++ ext
            if host_library_usable(path, arch): return path
    for dir in dirs:
        var n = 63
        while n >= 0:
            let path = dir ++ "/lib" ++ name ++ ".so." ++ f"{n}"
            if host_library_usable(path, arch): return path
            n -= 1
    ""

/// The directory part of a resolved library path.
pub fn host_library_dir(path: &str) -> str:
    let slash = path.rfind("/")
    if slash <= 0: "/" else: path.slice(0, slash)
