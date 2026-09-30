// Import libraries of the in-box Windows DLLs a package links (#1915).
//
// A Windows program links a DLL through the DLL's import library. The SDK
// carries the import libraries With itself links (build/sdk.w
// sdk_windows_import_libs); a package may name any DLL Windows ships (glfw
// links gdi32, raylib winmm and opengl32). Eric, 2026-09-30: `with get`
// writes the ones a package needs, from mingw-w64's .def files, as it writes
// the Apple framework stubs on macOS (compiler.FrameworkStubs); the SDK
// carries only what With itself links.
//
// The .def files come from the mingw-w64 release the SDK's C runtime was
// built from: its PROVENANCE (libc/windows/PROVENANCE) names the archive and
// its sha256, and the definitions are fetched once into the user's cache.
// A .def is found as mingw-w64-crt's Makefile.am finds it (build/sdk.w
// sdk_mingw_def): the architecture's directory first, then lib-common; a
// .def.in is run through the SDK's clang preprocessor, and a lib-common one
// loses the i386 `@N` decorations of its export names. The SDK's
// llvm-dlltool writes <dir>/lib<name>.a, which lld finds with -L<dir>.

use compiler.Runtime
use compiler.TarExtract
use compiler.EmbeddedSysroot
use compiler.Link
use std.http
use std.crypto.sha256

extern fn with_str_clone_ref(s: &str) -> str

// The value after `<key>: ` on a PROVENANCE line, or "".
fn wil_field(text: &str, key: &str) -> str:
    for line in text.split("\n"):
        if line.starts_with(key ++ ": "): return line.slice(key.len() + 2, line.len()).trim().to_owned()
    ""

fn wil_sha256_file(path: &str) -> str:
    if runtime_file_exists(path) == 0: return ""
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(runtime_read_file(path), &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

// The directories of mingw-w64-crt that hold the .def files, unpacked in the
// user's cache from the release PROVENANCE names; the crt directory, or
// "error: <why>".
fn wil_crt_dir(libc_root: &str) -> str:
    let provenance = runtime_read_file(libc_root ++ "/PROVENANCE")
    let url = wil_field(provenance, "source")
    let sha = wil_field(provenance, "sha256")
    if url.len() == 0 or sha.len() != 64:
        return "error: " ++ libc_root ++ "/PROVENANCE names no mingw-w64 source and sha256 (an SDK older than #1915's Windows C runtime)"
    let cache = with_user_cache_dir() ++ "/with/mingw-w64-defs/" ++ sha.slice(0, 16)
    let crt = cache ++ "/mingw-w64-crt"
    let stamp = cache ++ "/.with-defs-ready"
    if runtime_file_exists(stamp) != 0: return crt
    let _clean = runtime_remove_tree(cache)
    if runtime_mkdir_p(cache) != 0: return "error: could not create " ++ cache
    let archive = cache ++ "/source.tar.gz"
    runtime_eprint("  fetching the mingw-w64 import definitions: " ++ url)
    var fetched = false
    for attempt in 1..4:
        if not fetched and https_download(url.to_owned(), archive.to_owned()) == 0: fetched = true
        if not fetched and attempt < 3: let _ = runtime_nanosleep(attempt as i64 * 1000000000)
    if not fetched: return "error: could not download " ++ url
    let actual = wil_sha256_file(archive)
    if actual != sha:
        return "error: " ++ url ++ " has sha256 " ++ actual ++ "; the SDK was built from " ++ sha
    let keep: Vec[str] = Vec.new()
    keep.push("mingw-w64-crt/lib-common/")
    keep.push("mingw-w64-crt/lib64/")
    keep.push("mingw-w64-crt/libarm64/")
    keep.push("mingw-w64-crt/def-include/")
    let problem = tar_gz_extract_keep(archive, cache, 1, &keep)
    if problem.len() > 0: return "error: could not unpack " ++ problem
    let _rm = runtime_remove_file(archive)
    if runtime_write_file(stamp, sha ++ "\n") != 0: return "error: could not write " ++ stamp
    crt

// `Name@12 rest` -> `Name rest`: the first word loses an `@<digits>` tail.
fn wil_strip_stdcall_suffix(line: &str) -> str:
    var end: i64 = 0
    while end < line.len() and line[end] != ' ':
        end = end + 1
    let word = line.slice(0, end)
    var at: i64 = -1
    for i in 0..word.len():
        if word[i] == '@': at = i
    if at <= 0 or at == word.len() - 1: return line.to_owned()
    for i in (at + 1)..word.len():
        if word[i] < '0' or word[i] > '9': return line.to_owned()
    word.slice(0, at) ++ line.slice(end, line.len())

fn wil_run(argv: &Vec[str], work: &str, label: &str) -> str:
    var packed = ""
    for arg in argv: packed = packed ++ arg ++ "\0"
    let out = work ++ "/" ++ label ++ ".stdout"
    let err = work ++ "/" ++ label ++ ".stderr"
    let rc = runtime_exec_argv_capture(packed, out, err, 120000)
    if rc == 0: return ""
    f"{argv[0]} exited {rc}: " ++ runtime_read_file(out) ++ runtime_read_file(err)

// The .def of `name` for `arch`, or "" when mingw-w64 has none; "error: ..."
// when one exists and could not be prepared.
fn wil_def(sdk: &str, crt: &str, arch: &str, name: &str, work: &str) -> str:
    let arch_dir = crt ++ "/" ++ (if arch == "aarch64": "libarm64" else: "lib64")
    let common_dir = crt ++ "/lib-common"
    if runtime_file_exists(arch_dir ++ "/" ++ name ++ ".def") != 0: return arch_dir ++ "/" ++ name ++ ".def"
    var input = arch_dir ++ "/" ++ name ++ ".def.in"
    var common = false
    if runtime_file_exists(input) == 0:
        if runtime_file_exists(common_dir ++ "/" ++ name ++ ".def") != 0: return common_dir ++ "/" ++ name ++ ".def"
        input = common_dir ++ "/" ++ name ++ ".def.in"
        common = true
        if runtime_file_exists(input) == 0: return ""
    let pre = work ++ "/" ++ name ++ ".pre.def"
    let argv: Vec[str] = Vec.new()
    argv.push(sdk ++ "/bin/clang.exe")
    argv.push("--target=" ++ arch ++ "-w64-windows-gnu")
    argv.push("-E")
    argv.push("-P")
    argv.push("-x")
    argv.push("c")
    argv.push("-w")
    argv.push("-I")
    argv.push(crt ++ "/def-include")
    argv.push(input.clone())
    argv.push("-o")
    argv.push(pre.clone())
    let problem = wil_run(&argv, work, "def-" ++ name)
    if problem.len() > 0: return "error: preprocessing " ++ input ++ ": " ++ problem
    if not common: return pre
    var out = ""
    for line in runtime_read_file(pre).split("\n"):
        let text = if line.ends_with("\r"): line.slice(0, line.len() - 1) else: line.to_owned()
        out = out ++ wil_strip_stdcall_suffix(text) ++ "\n"
    let def = work ++ "/" ++ name ++ ".def"
    if runtime_write_file(def, out) != 0: return "error: could not write " ++ def
    def

// Whether `name` resolves to a library in one of `dirs`, as a Windows link
// looks it up (compiler.Link link_stage_windows_find_lib).
pub fn windows_lib_in_dirs(name: &str, dirs: &Vec[str]) -> bool:
    for d in dirs:
        for candidate in ["lib" ++ name ++ ".a", name ++ ".lib", "lib" ++ name ++ ".lib", name ++ ".a"]:
            if runtime_file_exists(d ++ "/" ++ candidate) != 0: return true
    false

// Writes <dir>/lib<name>.a for each name mingw-w64 has a .def for. The names
// written; `problem` says why not, and is "" on success. A name with no .def
// is not an in-box DLL mingw-w64 knows and is left to the link to report.
pub type WindowsImportLibs { written: Vec[str], problem: str }

pub fn windows_import_libs_write(dir: &str, names: &Vec[str]) -> WindowsImportLibs:
    let written: Vec[str] = Vec.new()
    if runtime_sysinfo_os() != "Windows":
        return WindowsImportLibs { written, problem: "Windows import libraries are generated on Windows only" }
    let sdk = link_stage_windows_sdk_dir()
    let libc_root = link_stage_windows_libc_root()
    if sdk.len() == 0 or libc_root.len() == 0:
        return WindowsImportLibs { written, problem: "this `with` has no Windows SDK C runtime to generate import libraries with" }
    let crt = wil_crt_dir(libc_root)
    if crt.starts_with("error: "): return WindowsImportLibs { written, problem: crt.slice(7, crt.len()) }
    let arch = link_stage_windows_arch()
    let work = dir ++ "/.work"
    if runtime_mkdir_p(work) != 0: return WindowsImportLibs { written, problem: "could not create " ++ work }
    for name in names:
        let def = wil_def(sdk, crt, arch, name, work)
        if def.len() == 0: continue
        if def.starts_with("error: "):
            let _rm = runtime_remove_tree(work)
            return WindowsImportLibs { written, problem: def.slice(7, def.len()) }
        let argv: Vec[str] = Vec.new()
        argv.push(sdk ++ "/bin/llvm-dlltool.exe")
        argv.push("-m")
        argv.push(if arch == "aarch64": "arm64" else: "i386:x86-64")
        argv.push("-k")
        argv.push("-d")
        argv.push(def.clone())
        argv.push("-l")
        argv.push(dir ++ "/lib" ++ name ++ ".a")
        let problem = wil_run(&argv, work, "dlltool-" ++ name)
        if problem.len() > 0:
            let _rm = runtime_remove_tree(work)
            return WindowsImportLibs { written, problem: "writing lib" ++ name ++ ".a: " ++ problem }
        written.push(with_str_clone_ref(name))
    let _rm = runtime_remove_tree(work)
    WindowsImportLibs { written, problem: "" }

// `with __windows-import-libs <dir> <name>...`: the step `with get` runs, on
// its own (the :no-host-toolchain check uses it).
pub fn with_windows_import_libs_main(args: &Vec[str]) -> i32:
    if args.len() < 2:
        runtime_eprint("usage: with __windows-import-libs <dir> <dll-name>...")
        return 2
    let names: Vec[str] = Vec.new()
    for i in 1..args.len() as i32: names.push(args[i].clone())
    if runtime_mkdir_p(args[0]) != 0:
        runtime_eprint("error: could not create " ++ args[0])
        return 1
    let made = windows_import_libs_write(args[0], &names)
    if made.problem.len() > 0:
        runtime_eprint("error: Windows import libraries: " ++ made.problem)
        return 1
    for name in names:
        if not made.written.contains(name):
            runtime_eprint("error: mingw-w64 has no import definitions for " ++ name ++ ".dll")
            return 1
    0
