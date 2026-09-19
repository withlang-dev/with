// A port: how `with get` builds a C library from source when no binary exists
// for the platform (ConanCenter publishes no Linux armv8 binaries at all).
//
// A port is data, never code — `with get` does not execute what it fetched:
//
//     [port]
//     name = "zlib"
//     version = "1.3.2"
//
//     [source]
//     url = "https://zlib.net/fossils/zlib-1.3.2.tar.gz"
//     sha256 = "..."
//     overlay = ["zconf.h"]                      # files/<path> beside port.toml,
//                                                # written over the extracted source
//
//     [build]
//     sources = ["adler32.c", "contrib/*.c"]     # relative to the source root
//     exclude = ["gzlib.c"]
//     include = ["."]                            # private -I
//     public_include = ["."]                     # what a c_import sees
//     defines = ["HAVE_UNISTD_H"]
//     cflags = ["-fvisibility=hidden"]
//     lib = "z"
//
//     [build.linux]                              # appended on that target
//     defines = ["_GNU_SOURCE"]
//
//     [link]
//     system_libs = ["m"]                        # -l names the platform provides
//
//     [link.macos]
//     link_args = ["-framework", "Cocoa"]        # passed to the link as written
//
// Array keys under [build.<os>] / [link.<os>] (linux, macos, windows) append to
// the unconditional ones. An overlay file is where a generated config.h lives.

pub type CPort {
    name: str,
    version: str,
    source_url: str,
    sha256: str,
    overlay: Vec[str],
    sources: Vec[str],
    exclude: Vec[str],
    include_dirs: Vec[str],
    public_include_dirs: Vec[str],
    defines: Vec[str],
    cflags: Vec[str],
    lib: str,
    system_libs: Vec[str],
    link_args: Vec[str],
    // The first thing wrong with the port, or "".
    problem: str,
}

fn cport_trim(text: &str) -> str: text.trim().to_owned()

fn cport_strip_comment(line: &str) -> str:
    var quoted = false
    for i in 0..line.len() as i32:
        let c = line[i]
        if c == '"': quoted = not quoted
        if c == '#' and not quoted: return line.slice(0, i).to_owned()
    line.to_owned()

fn cport_unquote(value: &str) -> str:
    if value.len() >= 2 and value[0] == '"' and value[value.len() - 1] == '"': return value.slice(1, value.len() - 1).to_owned()
    value.to_owned()

fn cport_string_array(value: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let parts = value.split("\"")
    // Quoted entries are the odd pieces: [ "a" , "b" ] -> `[ `, `a`, ` , `, `b`, ` ]`.
    for i in 0..parts.len() as i32:
        if i % 2 == 1: out.push(parts.get(i).to_owned())
    out

fn cport_os_section(os: &str) -> str:
    if os == "Linux": return "linux"
    if os == "Macos": return "macos"
    if os == "Windows": return "windows"
    ""

impl CPort:
    mut fn append(key: &str, values: &Vec[str]):
        for v in values:
            if key == "sources": self.sources.push(v.to_owned())
            else if key == "exclude": self.exclude.push(v.to_owned())
            else if key == "include": self.include_dirs.push(v.to_owned())
            else if key == "public_include": self.public_include_dirs.push(v.to_owned())
            else if key == "defines": self.defines.push(v.to_owned())
            else if key == "cflags": self.cflags.push(v.to_owned())
            else if key == "system_libs": self.system_libs.push(v.to_owned())
            else if key == "overlay": self.overlay.push(v.to_owned())
            else if key == "link_args": self.link_args.push(v.to_owned())

    mut fn apply(section: &str, key: &str, value: &str, os_section: &str):
        let build = section == "build" or section == "build." ++ os_section
        let link = section == "link" or section == "link." ++ os_section
        if section == "port" and key == "name": self.name = cport_unquote(value)
        else if section == "port" and key == "version": self.version = cport_unquote(value)
        else if section == "source" and key == "url": self.source_url = cport_unquote(value)
        else if section == "source" and key == "sha256": self.sha256 = cport_unquote(value)
        else if section == "source" and key == "overlay": self.append(key, &cport_string_array(value))
        else if build and key == "lib": self.lib = cport_unquote(value)
        else if build and (key == "sources" or key == "exclude" or key == "include" or key == "public_include" or key == "defines" or key == "cflags"): self.append(key, &cport_string_array(value))
        else if link and (key == "system_libs" or key == "link_args"): self.append(key, &cport_string_array(value))
        else if section.starts_with("build.") or section.starts_with("link."):
            // Another target's section: not ours to read, but its keys must be real.
            let known = key == "sources" or key == "exclude" or key == "include" or key == "public_include" or key == "defines" or key == "cflags" or key == "lib" or key == "system_libs" or key == "link_args"
            if not known and self.problem.len() == 0: self.problem = "unknown key `" ++ key ++ "` in [" ++ section ++ "]"
        else if self.problem.len() == 0: self.problem = "unknown key `" ++ key ++ "` in [" ++ section ++ "]"

fn CPort.empty(): CPort {
    name: "", version: "", source_url: "", sha256: "", overlay: Vec.new(),
    sources: Vec.new(), exclude: Vec.new(), include_dirs: Vec.new(), public_include_dirs: Vec.new(),
    defines: Vec.new(), cflags: Vec.new(), lib: "", system_libs: Vec.new(), link_args: Vec.new(), problem: "",
}

// `target_os` is a runtime_sysinfo_os() spelling: Linux, Macos, Windows.
pub fn cport_parse(text: &str, target_os: &str) -> CPort:
    var port = CPort.empty()
    let os_section = cport_os_section(target_os)
    var section = ""
    var pending_key = ""
    var pending_value = ""
    for raw in text.split("\n"):
        let line = cport_trim(cport_strip_comment(raw))
        if line.len() == 0: continue
        if pending_key.len() > 0:
            pending_value = pending_value ++ " " ++ line
            if line.contains("]"):
                port.apply(section, pending_key, pending_value, os_section)
                pending_key = ""
        else if line[0] == '[' and line[line.len() - 1] == ']':
            section = cport_trim(line.slice(1, line.len() - 1))
        else:
            let parts = line.split("=")
            if parts.len() < 2:
                if port.problem.len() == 0: port.problem = "expected `key = value`: " ++ line
                continue
            let key = cport_trim(parts.get(0))
            let value = cport_trim(line.slice(line.find("=") + 1, line.len()))
            if value.starts_with("[") and not value.contains("]"):
                pending_key = key
                pending_value = value
            else: port.apply(section, key, value, os_section)
    if pending_key.len() > 0 and port.problem.len() == 0: port.problem = "unterminated array for `" ++ pending_key ++ "`"
    if port.problem.len() == 0:
        if port.name.len() == 0: port.problem = "missing [port] name"
        else if port.version.len() == 0: port.problem = "missing [port] version"
        else if port.source_url.len() == 0: port.problem = "missing [source] url"
        else if port.sha256.len() != 64: port.problem = "[source] sha256 must be 64 hex digits"
        else if port.sources.len() == 0: port.problem = "[build] sources is empty"
        else if port.lib.len() == 0: port.problem = "missing [build] lib"
        else if port.public_include_dirs.len() == 0: port.problem = "[build] public_include is empty"
    port

// Does `path` (relative to the source root) match `pattern`? A pattern is a
// path with at most one `*`, which matches within one directory level.
pub fn cport_path_matches(pattern: &str, path: &str) -> bool:
    let star = pattern.find("*")
    if star < 0: return pattern == path
    let prefix = pattern.slice(0, star)
    let suffix = pattern.slice(star + 1, pattern.len())
    if path.len() < prefix.len() + suffix.len() or not path.starts_with(prefix) or not path.ends_with(suffix): return false
    not path.slice(prefix.len(), path.len() - suffix.len()).contains("/")

// The source files a port compiles, from the extracted tree's relative paths.
pub fn cport_select_sources(port: &CPort, files: &Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for file in files:
        var wanted = false
        for pattern in port.sources:
            if cport_path_matches(pattern, file): wanted = true
        for pattern in port.exclude:
            if cport_path_matches(pattern, file): wanted = false
        if wanted: out.push(file.to_owned())
    out
