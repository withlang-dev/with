use compiler.Runtime

fn link_diagnostic_name_byte(ch: i32):
    (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or
        (ch >= 97 and ch <= 122) or ch == 95 or ch == 45 or ch == 46 or ch == 43

// Read the linker's verdict instead of duplicating its search algorithm.
// This preserves -L, sysroots, linker scripts, and static/shared selection.
pub fn link_missing_libraries(diagnostics: &str) -> Vec[str]:
    let missing: Vec[str] = Vec.new()
    for line in diagnostics.split("\n"):
        for marker in ["unable to find library -l", "cannot find -l"]:
            let parts = line.split(marker)
            if parts.len() < 2: continue
            let tail = parts[1]
            var end = if tail.len() > 0 and tail[0] == 58: 1 else: 0
            let start = end
            while end < tail.len() as i32 and link_diagnostic_name_byte(tail[end]): end += 1
            if end == start: continue
            let name = tail.slice(0, end as i64)
            var seen = false
            for previous in missing:
                if previous == name: seen = true
            if not seen: missing.push(name.clone())
    missing

fn link_debian_library_package(name: &str) -> str:
    match name:
        "GL" => "libgl-dev"
        "X11" => "libx11-dev"
        "Xext" => "libxext-dev"
        "Xfixes" => "libxfixes-dev"
        "Xi" => "libxi-dev"
        "Xinerama" => "libxinerama-dev"
        "Xrandr" => "libxrandr-dev"
        "Xcursor" => "libxcursor-dev"
        "z" => "zlib1g-dev"
        "zstd" => "libzstd-dev"
        "xml2" => "libxml2-dev"
        "ssl" => "libssl-dev"
        "crypto" => "libssl-dev"
        "bz2" => "libbz2-dev"
        "sqlite3" => "libsqlite3-dev"
        _ => ""

pub fn link_missing_library_help(diagnostics: &str) -> str:
    let missing = link_missing_libraries(diagnostics)
    if missing.len() == 0: return ""
    var help = "error: required link libraries are unavailable:\n"
    let packages: Vec[str] = Vec.new()
    for name in missing:
        if name.starts_with(":"):
            help = help ++ "  " ++ name.slice(1, name.len()) ++ "\n"
        else:
            help = help ++ "  lib" ++ name ++ ".so or lib" ++ name ++ ".a\n"
        let package = link_debian_library_package(name)
        if package.len() > 0:
            var seen = false
            for previous in packages:
                if previous == package: seen = true
            if not seen: packages.push(package.clone())
    help = help ++ "Install the development packages providing these files, or add their directory to the project's library search paths.\n"
    if packages.len() > 0:
        help = help ++ "On Debian/Ubuntu, the known packages above can be installed with:\n  sudo apt-get install"
        for package in packages: help = help ++ " " ++ package
        help = help ++ "\n"
    help

pub fn link_run_with_diagnostics(argv: &str, cwd: &str) -> i32:
    var temp = runtime_getenv("TMPDIR")
    if runtime_sysinfo_os() == "Windows":
        temp = runtime_getenv("TMP")
        if temp.len() == 0: temp = runtime_getenv("TEMP")
    else if temp.len() == 0:
        temp = "/tmp"
    if temp.len() == 0:
        runtime_eprint("error: no temporary directory configured for linker diagnostics (set TMP or TEMP)")
        return -1
    let scratch = temp ++ f"/with-link-{runtime_getpid()}.{runtime_clock_nanos()}"
    if runtime_mkdir_p(scratch) != 0:
        runtime_eprint("error: could not create linker diagnostic directory: " ++ scratch)
        return -1
    let stdout_path = scratch ++ "/stdout"
    let stderr_path = scratch ++ "/stderr"
    let rc = runtime_exec_argv_capture_cwd(argv, stdout_path, stderr_path, 0, cwd)
    let output = runtime_read_file(stdout_path)
    let errors = runtime_read_file(stderr_path)
    if output.len() > 0: print(output)
    if errors.len() > 0: runtime_eprint(errors)
    if rc != 0:
        if errors.len() == 0: runtime_eprint(f"error: linker exited with status {rc} without diagnostics")
        let help = link_missing_library_help(errors)
        if help.len() > 0: runtime_eprint(help)
    runtime_remove_tree(scratch)
    rc
