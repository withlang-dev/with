use Archive
use compiler.Runtime
use std.collections.Atomic
use TargetSpec

extern fn with_str_clone_ref(s: &str) -> str

extern let with_embedded_cimport_stubs_o_start: u8
extern let with_embedded_cimport_stubs_o_end: u8
extern let with_embedded_compat_runtime_o_start: u8
extern let with_embedded_compat_runtime_o_end: u8
extern let with_embedded_panic_runtime_o_start: u8
extern let with_embedded_panic_runtime_o_end: u8
extern let with_embedded_regex_runtime_o_start: u8
extern let with_embedded_regex_runtime_o_end: u8
extern let with_embedded_fiber_stubs_o_start: u8
extern let with_embedded_fiber_stubs_o_end: u8
extern let with_embedded_channel_runtime_o_start: u8
extern let with_embedded_channel_runtime_o_end: u8
extern let with_embedded_fiber_runtime_o_start: u8
extern let with_embedded_fiber_runtime_o_end: u8
extern let with_embedded_fiber_o_start: u8
extern let with_embedded_fiber_o_end: u8
extern let with_embedded_fiber_asm_o_start: u8
extern let with_embedded_fiber_asm_o_end: u8
extern let with_embedded_rt_core_o_start: u8
extern let with_embedded_rt_core_o_end: u8
extern let with_embedded_rt_darwin_aarch64_o_start: u8
extern let with_embedded_rt_darwin_aarch64_o_end: u8
extern let with_embedded_rt_linux_x86_64_o_start: u8
extern let with_embedded_rt_linux_x86_64_o_end: u8
extern let with_embedded_rt_windows_x86_64_o_start: u8
extern let with_embedded_rt_windows_x86_64_o_end: u8

var link_stage_temp_archives: Vec[str] = Vec.new()
var link_stage_temp_archives_lock: Atomic[i32]

fn link_stage_temp_archives_lock_acquire():
    while link_stage_temp_archives_lock.swap(1, .Acquire) != 0:
        let _ = 0

fn link_stage_temp_archives_lock_release():
    link_stage_temp_archives_lock.store(0, .Release)

type LinkStageEnvVar {
    name: str,
    value: str,
}

type LinkStageCommand {
    linker: str,
    args: Vec[str],
    cwd: str,
    env: Vec[LinkStageEnvVar],
    inputs: Vec[str],
    outputs: Vec[str],
    cleanup_files: Vec[str],
}

type LinkStageResult {
    ok: bool,
    rc: i32,
    command: LinkStageCommand,
}

type LinkStagePlan {
    ok: bool,
    command: LinkStageCommand,
}

fn link_stage_empty_command() -> LinkStageCommand:
    LinkStageCommand {
        linker: "",
        args: Vec.new(),
        cwd: "",
        env: Vec.new(),
        inputs: Vec.new(),
        outputs: Vec.new(),
        cleanup_files: Vec.new(),
    }

fn link_stage_result_fail() -> LinkStageResult:
    LinkStageResult { ok: false, rc: 1, command: link_stage_empty_command() }

fn link_stage_plan_fail() -> LinkStagePlan:
    LinkStagePlan { ok: false, command: link_stage_empty_command() }

fn link_stage_plan_for_command(command: LinkStageCommand) -> LinkStagePlan:
    LinkStagePlan { ok: true, command }

fn link_stage_result_for_command(command: LinkStageCommand) -> LinkStageResult:
    let rc = command.run()
    link_stage_cleanup_files(command.cleanup_files)
    LinkStageResult { ok: rc == 0, rc, command }

fn link_stage_result_for_plan(plan: LinkStagePlan) -> LinkStageResult:
    if not plan.ok:
        return link_stage_result_fail()
    link_stage_result_for_command(move plan.command)

fn link_stage_argv_append(argv: &str, arg: &str) -> str:
    argv ++ arg ++ "\0"

fn link_stage_is_digit(ch: i32) -> bool:
    ch >= 48 and ch <= 57

fn link_stage_read_u32_le(data: &str, offset: i32) -> i64:
    if offset < 0 or offset + 3 >= data.len() as i32:
        return -1
    (data.byte_at(offset as i64) as i64) |
        ((data.byte_at((offset + 1) as i64) as i64) << 8) |
        ((data.byte_at((offset + 2) as i64) as i64) << 16) |
        ((data.byte_at((offset + 3) as i64) as i64) << 24)

fn link_stage_macho_macos_minos(path: &str) -> i64:
    let data = runtime_read_file(path)
    if data.len() < 32:
        return 0
    // 64-bit little-endian Mach-O object.
    if link_stage_read_u32_le(data, 0) != 0xfeedfacf:
        return 0
    let ncmds = link_stage_read_u32_le(data, 16) as i32
    var offset = 32
    var best: i64 = 0
    var i = 0
    while i < ncmds and offset + 8 <= data.len() as i32:
        let cmd = link_stage_read_u32_le(data, offset)
        let cmdsize = link_stage_read_u32_le(data, offset + 4) as i32
        if cmdsize < 8 or offset + cmdsize > data.len() as i32:
            break
        if cmd == 0x32 and cmdsize >= 24:
            let platform = link_stage_read_u32_le(data, offset + 8)
            let minos = link_stage_read_u32_le(data, offset + 12)
            if platform == 1 and minos > best:
                best = minos
        else if cmd == 0x24 and cmdsize >= 16:
            let minos = link_stage_read_u32_le(data, offset + 8)
            if minos > best:
                best = minos
        offset = offset + cmdsize
        i = i + 1
    best

fn link_stage_darwin_version_string(encoded: i64) -> str:
    let major = encoded / 65536
    let minor = (encoded / 256) % 256
    let patch = encoded % 256
    if patch != 0:
        return f"{major}.{minor}.{patch}"
    f"{major}.{minor}"

fn link_stage_darwin_platform_version(obj_path: &str, extras: &Vec[str]) -> str:
    var best: i64 = 11 * 65536
    let obj_minos = link_stage_macho_macos_minos(obj_path)
    if obj_minos > best:
        best = obj_minos
    for i in 0..extras.len() as i32:
        let extra_minos = link_stage_macho_macos_minos(extras.get(i as i64))
        if extra_minos > best:
            best = extra_minos
    link_stage_darwin_version_string(best)

fn link_stage_is_temp_archive_path(path: &str) -> bool:
    if not path.ends_with(".a"):
        return false
    var i = 0
    while i + 3 < path.len():
        if path.slice(i as i64, (i + 3) as i64) == ".o.":
            return link_stage_is_digit(path.byte_at((i + 3) as i64))
        i = i + 1
    false

// #357: a `link:` entry of the form "framework:Name" links an Apple framework
// (`-framework Name`) instead of a plain library (`-l<name>`). Darwin-only —
// the caller guards other platforms. Returns "" for a non-framework entry.
pub fn link_stage_framework_name(lib: &str) -> str:
    let prefix = "framework:"
    if lib.len() as i32 > prefix.len() as i32 and lib.slice(0, prefix.len()) == prefix:
        return lib.slice(prefix.len(), lib.len())
    ""

// The linker args for one `link:` entry. On Darwin a "framework:Name" entry
// becomes `-framework Name` (two args); everything else `-l<lib>`. On a
// non-Darwin target a framework entry is a loud error (frameworks are macOS)
// and yields no args. (Returns a Vec because With has no safe mutable-ref
// param to push through.)
pub fn link_stage_lib_args(lib: &str, is_darwin: i32) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let fw = link_stage_framework_name(lib)
    if fw.len() > 0:
        if is_darwin == 0:
            with_eprint("error: link: \"" ++ lib ++ "\" — Apple frameworks are only available on macOS targets\n")
            return out
        out.push("-framework")
        out.push(fw)
        return out
    out.push("-l" ++ lib)
    out

fn link_stage_collect_cleanup_files(extras: &Vec[str]) -> Vec[str]:
    let cleanup: Vec[str] = Vec.new()
    for i in 0..extras.len() as i32:
        let extra = extras.get(i as i64)
        if link_stage_is_temp_archive_path(extra):
            cleanup.push(with_str_clone_ref(extra))
    cleanup

fn link_stage_cleanup_files(files: &Vec[str]):
    for i in 0..files.len() as i32:
        let _remove = runtime_remove_file(files.get(i as i64))

fn link_stage_register_temp_archive(path: &str):
    // Comptime parallel() links on concurrent threads; an unguarded push to this
    // shared registry races vec_grow (double free of the old buffer, #617).
    link_stage_temp_archives_lock_acquire()
    link_stage_temp_archives.push(with_str_clone_ref(path))
    link_stage_temp_archives_lock_release()

fn link_stage_basename(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return with_str_clone_ref(path)
    path.slice((last_slash + 1) as i64, path.len())

fn link_stage_owned_temp_archive(path: &str, pid_text: &str) -> bool:
    let name = link_stage_basename(path)
    if not name.ends_with(".a"):
        return false
    link_stage_str_contains(name, ".o." ++ pid_text ++ ".")

fn link_stage_cleanup_owned_temp_archives_in(dir: &str, pid_text: &str):
    let listing = runtime_list_files(dir)
    var start = 0
    for i in 0..listing.len() as i32:
        let ch = listing.byte_at(i as i64)
        if ch == 10 or ch == 13:
            if i > start:
                let path = listing.slice(start as i64, i as i64)
                if link_stage_owned_temp_archive(path, pid_text):
                    let remove_path = if link_stage_str_contains(path, "/"): path else: dir ++ "/" ++ path
                    let _remove = runtime_remove_file(remove_path)
            start = i + 1
    if start < listing.len() as i32:
        let path = listing.slice(start as i64, listing.len())
        if link_stage_owned_temp_archive(path, pid_text):
            let remove_path = if link_stage_str_contains(path, "/"): path else: dir ++ "/" ++ path
            let _remove = runtime_remove_file(remove_path)

pub fn link_stage_cleanup_current_process_temp_archives() -> Unit:
    link_stage_temp_archives_lock_acquire()
    link_stage_cleanup_files(link_stage_temp_archives)
    link_stage_temp_archives = Vec.new()
    link_stage_temp_archives_lock_release()
    let root = link_stage_artifact_root()
    let pid_text = f"{runtime_getpid()}"
    link_stage_cleanup_owned_temp_archives_in(root ++ "/lib", pid_text)
    link_stage_cleanup_owned_temp_archives_in(root ++ "/bootstrap-lib", pid_text)

type LinkStageSavedEnv {
    names: Vec[str],
    values: Vec[str],
}

fn link_stage_apply_env(env: &Vec[LinkStageEnvVar]) -> LinkStageSavedEnv:
    let names: Vec[str] = Vec.new()
    let values: Vec[str] = Vec.new()
    for i in 0..env.len() as i32:
        let item = env.get(i as i64)
        names.push(with_str_clone_ref(item.name))
        values.push(runtime_getenv(item.name) ++ "")
        let _ = runtime_setenv(item.name, item.value)
    LinkStageSavedEnv { names, values }

fn link_stage_restore_env(saved: &LinkStageSavedEnv):
    for i in 0..saved.names.len() as i32:
        let _ = runtime_setenv(saved.names.get(i as i64), saved.values.get(i as i64))

impl LinkStageCommand:
    fn run() -> i32:
        var argv = ""
        argv = link_stage_argv_append(argv, self.linker)
        for i in 0..self.args.len() as i32:
            argv = link_stage_argv_append(argv, self.args.get(i as i64))
        let saved = link_stage_apply_env(&self.env)
        let rc = if self.cwd.len() > 0:
            runtime_exec_argv_cwd(argv, self.cwd)
        else:
            runtime_exec_argv(argv)
        link_stage_restore_env(saved)
        rc

fn link_stage_make_link_command(linker: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras.get(i as i64)
        args.push(with_str_clone_ref(extra))
        inputs.push(with_str_clone_ref(extra))
    if runtime_sysinfo_os() == "Macos":
        args.push("-Wl,-dead_strip")
    else if runtime_sysinfo_os() == "Linux":
        args.push("-fuse-ld=lld")
        args.push("-no-pie")
        args.push("-Wl,--gc-sections")
        args.push("-Wl,--icf=all")
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))
    let cc_is_darwin = if runtime_sysinfo_os() == "Macos": 1 else: 0
    for i in 0..link_libs.len() as i32:
        let cc_la = link_stage_lib_args(link_libs.get(i as i64), cc_is_darwin)
        for j in 0..cc_la.len() as i32:
            args.push(with_str_clone_ref(cc_la.get(j as i64)))
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args.get(i as i64)))
    if runtime_sysinfo_os() == "Linux":
        args.push("-lm")
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(linker), args, cwd: "", env, inputs, outputs, cleanup_files }

fn link_stage_file_exists(path: &str) -> bool:
    runtime_file_exists(path) != 0

// Sysroot prefix for Linux link inputs. Native Linux hosts link
// against the real root (""); a cross host must supply a Linux sysroot
// (crt objects, libc, libgcc) via WITH_LINUX_SYSROOT.
fn link_stage_linux_sysroot() -> str:
    let explicit = runtime_getenv("WITH_LINUX_SYSROOT")
    if explicit.len() > 0:
        return explicit
    ""

// The Linux target arch this link is for: the --target selection when
// cross, else the host arch (native Linux links).
fn link_stage_linux_arch() -> str:
    if not target_spec_is_native():
        return target_spec_arch()
    runtime_sysinfo_arch()

// Debian-style multiarch directory name for the Linux target arch.
fn link_stage_linux_multiarch() -> str:
    if link_stage_linux_arch() == "aarch64":
        return "aarch64-linux-gnu"
    "x86_64-linux-gnu"

fn link_stage_linux_emulation() -> str:
    if link_stage_linux_arch() == "aarch64":
        return "aarch64linux"
    "elf_x86_64"

fn link_stage_linux_dynamic_linker(sysroot: &str) -> str:
    if link_stage_linux_arch() == "aarch64":
        if link_stage_file_exists(sysroot ++ "/lib/ld-linux-aarch64.so.1"):
            return "/lib/ld-linux-aarch64.so.1"
        if link_stage_file_exists(sysroot ++ "/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1"):
            return "/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1"
        return ""
    if link_stage_file_exists(sysroot ++ "/lib64/ld-linux-x86-64.so.2"):
        return "/lib64/ld-linux-x86-64.so.2"
    if link_stage_file_exists(sysroot ++ "/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"):
        return "/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
    ""

fn link_stage_linux_crt_object(sysroot: &str, name: &str) -> str:
    let multiarch = link_stage_linux_multiarch()
    let usr = sysroot ++ "/usr/lib/" ++ multiarch ++ "/" ++ name
    if link_stage_file_exists(usr):
        return usr
    let lib = sysroot ++ "/lib/" ++ multiarch ++ "/" ++ name
    if link_stage_file_exists(lib):
        return lib
    ""

fn link_stage_linux_gcc_dir(sysroot: &str) -> str:
    let base = sysroot ++ "/usr/lib/gcc/" ++ link_stage_linux_multiarch() ++ "/"
    let candidates: Vec[str] = Vec.new()
    candidates.push(base ++ "15")
    candidates.push(base ++ "14")
    candidates.push(base ++ "13")
    candidates.push(base ++ "12")
    candidates.push(base ++ "11")
    candidates.push(base ++ "10")
    candidates.push(base ++ "9")
    for i in 0..candidates.len() as i32:
        let dir = candidates.get(i as i64)
        if link_stage_file_exists(dir ++ "/crtbegin.o"):
            return with_str_clone_ref(dir)
    ""

fn link_stage_linux_system_lib_path(sysroot: &str, name: &str) -> str:
    let libdir = sysroot ++ "/usr/lib/" ++ link_stage_linux_multiarch()
    if name == "z":
        if link_stage_file_exists(libdir ++ "/libz.so"):
            return ""
        if link_stage_file_exists(libdir ++ "/libz.so.1"):
            return libdir ++ "/libz.so.1"
    if name == "zstd":
        if link_stage_file_exists(libdir ++ "/libzstd.so"):
            return ""
        if link_stage_file_exists(libdir ++ "/libzstd.so.1"):
            return libdir ++ "/libzstd.so.1"
    if name == "xml2":
        if link_stage_file_exists(libdir ++ "/libxml2.so"):
            return ""
        if link_stage_file_exists(libdir ++ "/libxml2.so.16"):
            return libdir ++ "/libxml2.so.16"
    ""

fn link_stage_make_darwin_llvm_link_command(llvm_ld: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    let platform_version = link_stage_darwin_platform_version(obj_path, extras)
    args.push("-arch")
    args.push("arm64")
    args.push("-platform_version")
    args.push("macos")
    args.push(with_str_clone_ref(platform_version))
    args.push(platform_version)
    args.push("-dead_strip")
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras.get(i as i64)
        args.push(with_str_clone_ref(extra))
        inputs.push(with_str_clone_ref(extra))
    for i in 0..link_libs.len() as i32:
        let dw_la = link_stage_lib_args(link_libs.get(i as i64), 1)
        for j in 0..dw_la.len() as i32:
            args.push(with_str_clone_ref(dw_la.get(j as i64)))
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args.get(i as i64)))
    args.push("-lSystem")
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(llvm_ld), args, cwd: "", env, inputs, outputs, cleanup_files }

fn link_stage_make_linux_llvm_link_command(llvm_ld: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    let sysroot = link_stage_linux_sysroot()
    let dynamic_linker = link_stage_linux_dynamic_linker(sysroot)
    let crt1 = link_stage_linux_crt_object(sysroot, "crt1.o")
    let crti = link_stage_linux_crt_object(sysroot, "crti.o")
    let crtn = link_stage_linux_crt_object(sysroot, "crtn.o")
    let gcc_dir = link_stage_linux_gcc_dir(sysroot)
    if dynamic_linker.len() == 0 or crt1.len() == 0 or crti.len() == 0 or crtn.len() == 0 or gcc_dir.len() == 0:
        if sysroot.len() > 0:
            with_eprint("error: could not locate Linux " ++ link_stage_linux_arch() ++ " crt/linker files under sysroot " ++ sysroot)
        else if runtime_sysinfo_os() == "Linux":
            with_eprint("error: could not locate Linux " ++ link_stage_linux_arch() ++ " crt/linker files for direct ld.lld link")
        else:
            with_eprint("error: linking a Linux " ++ link_stage_linux_arch() ++ " binary from this host needs a Linux sysroot (crt1.o, libc, libgcc); set WITH_LINUX_SYSROOT=<dir>")
        return LinkStageCommand { linker: "", args, cwd: "", env, inputs, outputs, cleanup_files: Vec.new() }

    args.push("-m")
    args.push(link_stage_linux_emulation())
    args.push("--eh-frame-hdr")
    args.push("--hash-style=gnu")
    args.push("--build-id")
    args.push("--gc-sections")
    args.push("--icf=all")
    args.push("--as-needed")
    if sysroot.len() > 0:
        // Keep every implicit library search inside the sysroot; the
        // embedded dynamic-linker path below stays the target's own.
        args.push("--sysroot=" ++ sysroot)
    args.push("-dynamic-linker")
    args.push(dynamic_linker)
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))

    args.push(with_str_clone_ref(crt1))
    inputs.push(crt1)
    args.push(with_str_clone_ref(crti))
    inputs.push(crti)
    let crtbegin = gcc_dir ++ "/crtbegin.o"
    args.push(with_str_clone_ref(crtbegin))
    inputs.push(crtbegin)

    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras.get(i as i64)
        args.push(with_str_clone_ref(extra))
        inputs.push(with_str_clone_ref(extra))

    args.push("-L" ++ gcc_dir)
    args.push("-L" ++ sysroot ++ "/usr/lib/" ++ link_stage_linux_multiarch())
    args.push("-L" ++ sysroot ++ "/lib/" ++ link_stage_linux_multiarch())
    args.push("-L" ++ sysroot ++ "/usr/lib")
    args.push("-L" ++ sysroot ++ "/lib")
    for i in 0..link_libs.len() as i32:
        let lib = link_libs.get(i as i64)
        if link_stage_framework_name(lib).len() > 0:
            with_eprint("error: link: \"" ++ lib ++ "\" — Apple frameworks are only available on macOS targets\n")
        else:
            let fallback_lib = link_stage_linux_system_lib_path(sysroot, lib)
            if fallback_lib.len() > 0:
                args.push(with_str_clone_ref(fallback_lib))
                inputs.push(fallback_lib)
            else:
                args.push("-l" ++ lib)
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args.get(i as i64)))
    args.push("-lc")
    args.push("-lgcc")

    let crtend = gcc_dir ++ "/crtend.o"
    args.push(with_str_clone_ref(crtend))
    inputs.push(crtend)
    args.push(with_str_clone_ref(crtn))
    inputs.push(crtn)
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(llvm_ld), args, cwd: "", env, inputs, outputs, cleanup_files }

fn link_stage_windows_libpath(var_name: &str, fallback: &str) -> str:
    let v = runtime_getenv(var_name)
    if v.len() > 0:
        return v
    fallback ++ ""

fn link_stage_make_windows_llvm_link_command(llvm_ld: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    args.push("/nologo")
    args.push("/subsystem:console")
    args.push("/debug")
    args.push("/pdb:" ++ bin_path ++ ".pdb")
    args.push("/stack:8388608")
    args.push("/opt:ref")
    args.push("/opt:icf")
    // Library search paths. On a Windows host these are the standard
    // MSVC/WinSDK install locations; for a cross link from another host
    // point them at a splatted lib tree (e.g. xwin output) via the
    // WITH_WINDOWS_* env vars.
    args.push("/libpath:" ++ link_stage_windows_libpath("WITH_WINDOWS_UM_LIBDIR", "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64"))
    args.push("/libpath:" ++ link_stage_windows_libpath("WITH_WINDOWS_UCRT_LIBDIR", "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64"))
    args.push("/libpath:" ++ link_stage_windows_libpath("WITH_WINDOWS_MSVC_LIBDIR", "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/lib/x64"))
    args.push("/out:" ++ bin_path)
    outputs.push(with_str_clone_ref(bin_path))
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras.get(i as i64)
        if extra.starts_with("-L"):
            args.push("/libpath:" ++ extra.slice(2, extra.len()))
        else if extra.starts_with("@"):
            args.push(with_str_clone_ref(extra))
        else:
            args.push(with_str_clone_ref(extra))
            inputs.push(with_str_clone_ref(extra))
    for i in 0..link_libs.len() as i32:
        let lib = link_libs.get(i as i64)
        if lib.ends_with(".lib"):
            args.push(with_str_clone_ref(lib))
        else:
            args.push(lib ++ ".lib")
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args.get(i as i64)))
    args.push("libcpmt.lib")
    args.push("libcmt.lib")
    args.push("oldnames.lib")
    args.push("kernel32.lib")
    args.push("advapi32.lib")
    args.push("bcrypt.lib")
    args.push("shell32.lib")
    args.push("user32.lib")
    args.push("ole32.lib")
    args.push("oleaut32.lib")
    args.push("uuid.lib")
    args.push("ws2_32.lib")
    args.push("version.lib")
    args.push("psapi.lib")
    args.push("dbghelp.lib")
    args.push("ntdll.lib")
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(llvm_ld), args, cwd: "", env, inputs, outputs, cleanup_files }

// The lld flavor for a Linux ELF link. The build's llvm_ld metadata
// records the host flavor (ld64.lld on macOS); the ELF driver ships
// beside it in the same SDK bin directory.
fn link_stage_elf_lld_for(llvm_ld: &str) -> str:
    if link_stage_basename(llvm_ld) == "ld.lld":
        return llvm_ld ++ ""
    let sibling = link_stage_dirname(llvm_ld) ++ "/ld.lld"
    if link_stage_file_exists(sibling):
        return sibling
    ""

// The lld flavor for a Windows COFF/PE link. `lld-link` ships beside
// the host llvm_ld in the same SDK bin directory (a symlink to `lld`
// in the published SDKs); invoking lld as lld-link performs a native
// COFF link from any host, so no wine is needed for the link itself.
fn link_stage_coff_lld_for(llvm_ld: &str) -> str:
    if link_stage_basename(llvm_ld) == "lld-link" or link_stage_basename(llvm_ld) == "lld-link.exe":
        return llvm_ld ++ ""
    let sibling = link_stage_dirname(llvm_ld) ++ "/lld-link"
    if link_stage_file_exists(sibling):
        return sibling
    ""

fn link_stage_make_llvm_link_command(llvm_ld: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    // A --target selection overrides the host: pick the target's link
    // recipe and lld flavor (§18.5 — cross-compilation is a normal mode).
    if not target_spec_is_native():
        let cross_kind = target_spec_active_kind()
        if cross_kind == 1 or cross_kind == 2:
            let elf_ld = link_stage_elf_lld_for(llvm_ld)
            if elf_ld.len() == 0:
                with_eprint("error: cross link needs the ELF lld driver (ld.lld) next to " ++ llvm_ld)
                return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
            return link_stage_make_linux_llvm_link_command(elf_ld, obj_path, bin_path, extras, link_libs, link_args)
        if target_spec_active_kind() == 5:
            let coff_ld = link_stage_coff_lld_for(llvm_ld)
            if coff_ld.len() == 0:
                with_eprint("error: cross link needs the COFF lld driver (lld-link) next to " ++ llvm_ld)
                return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
            return link_stage_make_windows_llvm_link_command(coff_ld, obj_path, bin_path, extras, link_libs, link_args)
        with_eprint("error: unsupported cross link target: " ++ target_spec_name())
        return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
    let os = runtime_sysinfo_os()
    let arch = runtime_sysinfo_arch()
    if os == "Linux" and arch == "x86_64":
        return link_stage_make_linux_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if os == "Linux" and (arch == "armv8" or arch == "aarch64"):
        return link_stage_make_linux_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if os == "Macos" and (arch == "armv8" or arch == "aarch64"):
        return link_stage_make_darwin_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if os == "Windows" and arch == "x86_64":
        return link_stage_make_windows_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    with_eprint("error: unsupported host LLVM linker platform: " ++ os ++ "/" ++ arch)
    LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }

fn link_stage_str_from_raw_parts(ptr: *const u8, len: i64) -> str:
    if ptr as i64 == 0 or len <= 0:
        return ""
    var out: str = ""
    unsafe:
        let sp = &raw mut out as *mut u8
        *(sp as *mut u64) = ptr as u64
        *((sp + 8u64) as *mut i64) = len
    out

fn link_stage_embedded_obj_slice(start: *const u8, end: *const u8) -> str:
    let len = end as i64 - start as i64
    if len <= 0:
        return ""
    link_stage_str_from_raw_parts(start, len)

fn link_stage_embedded_runtime_object(name: &str) -> str:
    if name == "cimport_stubs.o":
        return link_stage_embedded_obj_slice(&with_embedded_cimport_stubs_o_start as *const u8, &with_embedded_cimport_stubs_o_end as *const u8)
    if name == "compat_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_compat_runtime_o_start as *const u8, &with_embedded_compat_runtime_o_end as *const u8)
    if name == "panic_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_panic_runtime_o_start as *const u8, &with_embedded_panic_runtime_o_end as *const u8)
    if name == "regex_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_regex_runtime_o_start as *const u8, &with_embedded_regex_runtime_o_end as *const u8)
    if name == "fiber_stubs.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_stubs_o_start as *const u8, &with_embedded_fiber_stubs_o_end as *const u8)
    if name == "channel_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_channel_runtime_o_start as *const u8, &with_embedded_channel_runtime_o_end as *const u8)
    if name == "fiber_runtime.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_runtime_o_start as *const u8, &with_embedded_fiber_runtime_o_end as *const u8)
    if name == "fiber.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_o_start as *const u8, &with_embedded_fiber_o_end as *const u8)
    if name == "fiber_asm.o":
        return link_stage_embedded_obj_slice(&with_embedded_fiber_asm_o_start as *const u8, &with_embedded_fiber_asm_o_end as *const u8)
    if name == "rt_core.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_core_o_start as *const u8, &with_embedded_rt_core_o_end as *const u8)
    if name == "rt_darwin_aarch64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_darwin_aarch64_o_start as *const u8, &with_embedded_rt_darwin_aarch64_o_end as *const u8)
    if name == "rt_linux_x86_64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_linux_x86_64_o_start as *const u8, &with_embedded_rt_linux_x86_64_o_end as *const u8)
    if name == "rt_windows_x86_64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_windows_x86_64_o_start as *const u8, &with_embedded_rt_windows_x86_64_o_end as *const u8)
    ""

fn link_stage_extract_runtime_obj(name: &str, path: &str) -> i32:
    let data = link_stage_embedded_runtime_object(name)
    if data.len() == 0:
        return 1
    // Concurrent links (comptime parallel() threads and separate processes)
    // extract to this shared path. Writing it directly truncates the file under
    // a concurrent reader mid-link — empty reads ("cannot read member") or
    // partial-object parses (#617). Reuse a complete matching extraction, else
    // write a unique temp file and rename it into place: rename replaces
    // atomically, so readers only ever observe a complete file.
    let existing = runtime_read_file(path)
    if existing.len() == data.len() and existing == data:
        return 0
    let tmp_path = path ++ f".{runtime_getpid()}.{runtime_clock_nanos()}.tmp"
    if runtime_write_file(tmp_path, data) != 0:
        return 1
    if runtime_rename(tmp_path, path) != 0:
        let _ = runtime_remove_file(tmp_path)
        // A concurrent extractor may have won the rename; accept its complete copy.
        let after = runtime_read_file(path)
        if after.len() == data.len() and after == data:
            return 0
        return 1
    0

fn link_stage_link(obj_path: &str, bin_path: &str) -> bool:
    let extras: Vec[str] = Vec.new()
    let link_libs: Vec[str] = Vec.new()
    link_stage_link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)

fn link_stage_link_with_extras(obj_path: &str, bin_path: &str, extras: Vec[str]) -> bool:
    let link_libs: Vec[str] = Vec.new()
    link_stage_link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)

fn link_stage_link_with_extras_and_libs(obj_path: &str, bin_path: &str, extras: Vec[str], link_libs: Vec[str]) -> bool:
    link_stage_link_with_extras_and_libs_result(obj_path, bin_path, extras, link_libs).ok

fn link_stage_link_with_extras_and_libs_result(obj_path: &str, bin_path: &str, extras: Vec[str], link_libs: Vec[str]) -> LinkStageResult:
    link_stage_result_for_plan(link_stage_link_with_extras_and_libs_plan(obj_path, bin_path, extras, link_libs))

fn link_stage_link_with_extras_and_libs_plan(obj_path: &str, bin_path: &str, extras: Vec[str], link_libs: Vec[str]) -> LinkStagePlan:
    let link_args: Vec[str] = Vec.new()
    link_stage_link_with_extras_libs_args_plan(obj_path, bin_path, extras, link_libs, link_args)

fn link_stage_link_with_extras_libs_args_plan(obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStagePlan:
    // Cross links never go through the host cc driver: route to the
    // LLVM linker plan, which dispatches on the active target.
    if runtime_sysinfo_os() == "Windows" or not target_spec_is_native():
        let root = link_stage_resolve_runtime_root()
        let ld_path = link_stage_read_file_trimmed(root ++ "/llvm_ld")
        if ld_path.len() == 0:
            if runtime_sysinfo_os() == "Windows":
                with_eprint("error: missing Windows LLVM linker metadata")
            else:
                with_eprint("error: cross-target link requires LLVM linker metadata (" ++ root ++ "/llvm_ld)")
            return link_stage_plan_fail()
        return link_stage_link_with_llvm_args_plan(obj_path, bin_path, extras, link_libs, link_args, ld_path)
    let command = link_stage_make_link_command("cc", obj_path, bin_path, extras, link_libs, link_args)
    link_stage_plan_for_command(move command)

fn link_stage_link_with_llvm(obj_path: &str, bin_path: &str, extras: Vec[str], link_libs: Vec[str], llvm_ld: &str) -> bool:
    link_stage_link_with_llvm_result(obj_path, bin_path, extras, link_libs, llvm_ld).ok

fn link_stage_link_with_llvm_result(obj_path: &str, bin_path: &str, extras: Vec[str], link_libs: Vec[str], llvm_ld: &str) -> LinkStageResult:
    link_stage_result_for_plan(link_stage_link_with_llvm_plan(obj_path, bin_path, extras, link_libs, llvm_ld))

fn link_stage_link_with_llvm_plan(obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], llvm_ld: &str) -> LinkStagePlan:
    let link_args: Vec[str] = Vec.new()
    link_stage_link_with_llvm_args_plan(obj_path, bin_path, extras, link_libs, link_args, llvm_ld)

fn link_stage_link_with_llvm_args_plan(obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str], llvm_ld: &str) -> LinkStagePlan:
    let command = link_stage_make_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if command.linker.len() == 0:
        return link_stage_plan_fail()
    link_stage_plan_for_command(move command)

fn link_stage_str_contains(hay: &str, needle: &str) -> bool:
    let hay_len = hay.len() as i32
    let needle_len = needle.len() as i32
    if needle_len <= 0:
        return true
    if hay_len < needle_len:
        return false

    var i = 0
    while i <= hay_len - needle_len:
        var matched = true
        var j = 0
        while j < needle_len:
            if hay.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
            j = j + 1
        if matched:
            return true
        i = i + 1
    false

fn link_stage_undef_contains_symbol(undef: &str, name: &str) -> bool:
    if link_stage_str_contains(undef, "_" ++ name):
        return true
    link_stage_str_contains(undef, name)

fn link_stage_undefined_symbols_for_object(obj_path: &str) -> str:
    let report_path = obj_path ++ ".undef"
    let null_path = if runtime_sysinfo_os() == "Windows": "NUL" else: "/dev/null"
    var argv = ""
    var nm_tool = "nm"
    if runtime_sysinfo_os() == "Windows":
        let root = link_stage_resolve_runtime_root()
        let ld_path = link_stage_read_file_trimmed(root ++ "/llvm_ld")
        if ld_path.len() > 0:
            nm_tool = link_stage_dirname(ld_path) ++ "/llvm-nm.exe"
        else:
            nm_tool = "llvm-nm.exe"
    else if not target_spec_is_native():
        // Cross objects are foreign to the host toolchain; use the
        // SDK's llvm-nm (beside lld) when it's available.
        let root = link_stage_resolve_runtime_root()
        let ld_path = link_stage_read_file_trimmed(root ++ "/llvm_ld")
        if ld_path.len() > 0:
            let llvm_nm = link_stage_dirname(ld_path) ++ "/llvm-nm"
            if link_stage_file_exists(llvm_nm):
                nm_tool = llvm_nm
    argv = link_stage_argv_append(argv, nm_tool)
    argv = link_stage_argv_append(argv, "-u")
    argv = link_stage_argv_append(argv, obj_path)
    let probe_rc = runtime_exec_argv_capture(argv, report_path, null_path, 0)
    if probe_rc != 0:
        let _ = runtime_remove_file(report_path)
        return "<probe-failed>"
    let symbols = runtime_read_file(report_path)
    let _ = runtime_remove_file(report_path)
    symbols

fn link_stage_undefined_symbols_need_helpers_runtime(undef: &str) -> i32:
    if undef == "<probe-failed>":
        return 1
    if undef.len() == 0:
        return 0
    if link_stage_undef_contains_symbol(undef, "with_"):
        return 1
    if link_stage_undef_contains_symbol(undef, "int_to_string"):
        return 1
    if link_stage_undef_contains_symbol(undef, "i32_to_str"):
        return 1
    if link_stage_undef_contains_symbol(undef, "str_from_byte"):
        return 1
    0

fn link_stage_undefined_symbols_need_fiber_runtime(undef: &str) -> i32:
    if undef == "<probe-failed>":
        return 0
    if undef.len() == 0:
        return 0
    if link_stage_undef_contains_symbol(undef, "with_channel_"):
        return 1
    if link_stage_undef_contains_symbol(undef, "with_fiber_"):
        return 1
    0

fn link_stage_undefined_symbols_need_regex_runtime(undef: &str) -> i32:
    if undef == "<probe-failed>":
        return 1
    if undef.len() == 0:
        return 0
    if link_stage_undef_contains_symbol(undef, "with_regex_"):
        return 1
    0

fn link_stage_undefined_symbols_need_compat_runtime(undef: &str) -> i32:
    if undef == "<probe-failed>":
        return 1
    if undef.len() == 0:
        return 0
    if link_stage_undef_contains_symbol(undef, "with_exec_"):
        return 1
    if link_stage_undef_contains_symbol(undef, "with_setenv_str"):
        return 1
    0

fn link_stage_compiler_runtime_dir() -> str:
    let argv0 = runtime_arg_at(0)
    if argv0.len() == 0:
        return "runtime"
    link_stage_dirname(argv0) ++ "/runtime"

fn link_stage_resolve_runtime_root() -> str:
    let argv0 = runtime_arg_at(0)
    let compiler_dir = if argv0.len() > 0: link_stage_dirname(argv0) else: "."
    let platform_object = link_stage_host_platform_runtime_object()
    let candidates: Vec[str] = Vec.new()
    // Prefer the current workspace artifact root during bootstrap. This lets
    // external seed compilers link against the runtime objects generated for
    // the active tree instead of whatever stdlib/runtime payload the seed
    // binary happens to carry.
    candidates.push(link_stage_artifact_root() ++ "/lib")
    // Seed-built bootstrap runtime for cold direct `with build` invocations.
    // The canonical stage2-refreshed runtime overwrites out/lib later.
    candidates.push(link_stage_artifact_root() ++ "/bootstrap-lib")
    // <compiler_dir>/runtime/ (symlink to ../lib in out/bin/)
    candidates.push(compiler_dir ++ "/runtime")
    // <compiler_dir>/../lib/ (direct FHS-style path)
    candidates.push(compiler_dir ++ "/../lib")
    for i in 0..candidates.len() as i32:
        let dir = candidates.get(i as i64)
        let probe = dir ++ "/cimport_stubs.o"
        let platform_probe = if platform_object.len() > 0: dir ++ "/" ++ platform_object else: ""
        if runtime_read_file(probe).len() > 0 and (platform_probe.len() == 0 or runtime_read_file(platform_probe).len() > 0):
            return with_str_clone_ref(dir)
    // Fall back to compiler-relative runtime dir.
    compiler_dir ++ "/runtime"

// Directory holding the link inputs built FOR the active target:
// the runtime root itself for native, its cross/<target>/ subdir
// for a cross target (bridge objects, embedded objects, lld rsp).
fn link_stage_runtime_variant_dir() -> str:
    let root = link_stage_resolve_runtime_root()
    if target_spec_is_native():
        return root
    root ++ "/cross/" ++ target_spec_name()

fn link_stage_find_llvm_static_bridge() -> str:
    let root = link_stage_resolve_runtime_root()
    let variant = link_stage_runtime_variant_dir()
    let bridge_o = variant ++ "/llvm_bridge.o"
    let rsp = variant ++ "/llvm_ld.rsp"
    let ld_file = root ++ "/llvm_ld"
    if runtime_read_file(bridge_o).len() > 0 and runtime_read_file(rsp).len() > 0 and runtime_read_file(ld_file).len() > 0:
        return bridge_o
    ""

fn link_stage_read_file_trimmed(path: &str) -> str:
    let content = runtime_read_file(path)
    if content.len() == 0:
        return ""
    // Trim trailing whitespace: CR and LF (a CRLF-authored metadata file on
    // Windows must not leave a stray \r in the linker path — CreateProcessW
    // cannot launch "…lld-link.exe\r"), plus spaces/tabs.
    var end = content.len() as i32
    while end > 0:
        let b = content.byte_at((end - 1) as i64)
        if b == 10 or b == 13 or b == 32 or b == 9:
            end = end - 1
        else:
            break
    content.slice(0, end as i64)

fn link_stage_artifact_root() -> str:
    let env_root = runtime_getenv("WITH_OUT_DIR")
    if env_root.len() > 0:
        return env_root
    "out"

fn link_stage_find_runtime_object_path(name: &str) -> str:
    let root = link_stage_resolve_runtime_root()
    // Cross targets only ever link runtime objects built for the
    // target; the embedded objects are host-built and never a valid
    // fallback here (§18.5: fail loudly, never link native output).
    if not target_spec_is_native():
        let cross_path = root ++ "/cross/" ++ target_spec_name() ++ "/" ++ name
        if runtime_read_file(cross_path).len() > 0:
            return cross_path
        with_eprint("error: missing " ++ target_spec_name() ++ " runtime object: " ++ cross_path ++ " (run `with build :cross-rt` first)")
        return ""
    let p = root ++ "/" ++ name
    if runtime_read_file(p).len() > 0:
        return p
    // Fall back to embedded runtime objects (self-contained binary)
    let tmp_dir = link_stage_artifact_root() ++ "/tmp/with_runtime"
    if runtime_mkdir_p(tmp_dir) != 0:
        return ""
    let tmp_path = tmp_dir ++ "/" ++ name
    if link_stage_extract_runtime_obj(name, tmp_path) == 0:
        return tmp_path
    ""

// The platform runtime object for the ACTIVE target (native resolves
// to the host's, exactly as before cross targets existed).
fn link_stage_platform_runtime_object() -> str:
    if not target_spec_is_native():
        if target_spec_active_kind() == 1:
            return "rt_linux_x86_64.o"
        if target_spec_active_kind() == 2:
            return "rt_linux_aarch64.o"
        if target_spec_active_kind() == 5:
            return "rt_windows_x86_64.o"
        with_eprint("error: unsupported cross runtime platform: " ++ target_spec_name())
        return ""
    link_stage_host_platform_runtime_object()

fn link_stage_host_platform_runtime_object() -> str:
    let os = runtime_sysinfo_os()
    let arch = runtime_sysinfo_arch()
    if os == "Linux" and arch == "x86_64":
        return "rt_linux_x86_64.o"
    if os == "Linux" and (arch == "armv8" or arch == "aarch64"):
        // No embedded slot yet — resolved from the on-disk runtime root
        // only (see link_stage_embedded_runtime_object).
        return "rt_linux_aarch64.o"
    if os == "Macos" and (arch == "armv8" or arch == "aarch64"):
        return "rt_darwin_aarch64.o"
    if os == "Windows" and arch == "x86_64":
        return "rt_windows_x86_64.o"
    with_eprint("error: unsupported host runtime platform: " ++ os ++ "/" ++ arch)
    ""

fn link_stage_make_archive(obj_path: &str) -> str:
    if runtime_sysinfo_os() == "Windows" or target_spec_active_kind() == 5:
        return with_str_clone_ref(obj_path)
    // Wrap a .o file in a .a archive so the linker treats it as a library
    // (only pulling in symbols that aren't already defined).
    let ar_path = obj_path ++ f".{runtime_getpid()}.{runtime_clock_nanos()}.a"
    let out = link_stage_make_archive_to_path(obj_path, ar_path)
    if out.len() > 0:
        link_stage_register_temp_archive(out)
    out

fn link_stage_make_archive_to_path(obj_path: &str, ar_path: &str) -> str:
    let members: Vec[str] = Vec.new()
    members.push(with_str_clone_ref(obj_path))
    let rc = create_static_archive(ar_path, members)
    if rc == 0:
        return with_str_clone_ref(ar_path)
    ""

fn link_stage_should_use_rt_core_from_undef(undef: &str) -> bool:
    // Use the libc-free runtime for user programs that don't need LLVM bridge
    // or c_import. The compiler itself needs LLVM/libclang symbols and always
    // uses the libc-backed cimport_stubs.o runtime.
    if undef == "<probe-failed>":
        return false
    // If it needs LLVM/libclang, it's the compiler — use libc runtime.
    if link_stage_undefined_symbols_need_llvm_bridge(undef):
        return false
    // If it uses c_import symbols or libc functions directly, use libc runtime
    if link_stage_undef_contains_symbol(undef, "fopen"):
        return false
    if link_stage_undef_contains_symbol(undef, "fwrite"):
        return false
    if link_stage_undef_contains_symbol(undef, "printf"):
        return false
    if link_stage_undef_contains_symbol(undef, "malloc"):
        return false
    if link_stage_undef_contains_symbol(undef, "fclose"):
        return false
    // Check if it needs with_* symbols (which we provide in rt_core)
    if link_stage_undef_contains_symbol(undef, "with_"):
        return true
    false

fn link_stage_undefined_symbols_need_llvm_bridge(undef: &str) -> bool:
    link_stage_undef_contains_symbol(undef, "wl_") or
        link_stage_undef_contains_symbol(undef, "LLVM") or
        link_stage_undef_contains_symbol(undef, "clang_")

fn link_stage_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47 or path[i] == 92: // '/' or '\'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

fn link_stage_source_stem(source_path: &str) -> str:
    var last_slash = -1
    for i in 0..source_path.len():
        if source_path[i] == 47 or source_path[i] == 92: // '/' or '\'
            last_slash = i as i32
    let base = if last_slash >= 0:
        source_path.slice((last_slash + 1) as i64, source_path.len() as i64)
    else:
        with_str_clone_ref(source_path)
    if base.len() > 2 and base.ends_with(".w"):
        return base.slice(0, (base.len() - 2) as i64)
    base

fn link_stage_sanitize_relative_dir(path: &str) -> str:
    var out = ""
    var segment_start = 0
    var i = 0
    while i <= path.len():
        let at_end = i == path.len()
        let ch = if at_end: 47 else: path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            if i > segment_start:
                let segment = path.slice(segment_start as i64, i as i64)
                if segment != ".":
                    if out.len() > 0:
                        out = out ++ "/"
                    if segment == "..":
                        out = out ++ "__up__"
                    else:
                        // A Windows source carries a drive-letter segment ("C:")
                        // whose colon is illegal in a path component; left intact
                        // it yields an uncreatable artifact dir (out/C:/wt/...) and
                        // mkdir fails before the program runs. Colons never appear
                        // in this compiler's own source paths, so stripping them is
                        // a no-op off Windows — fixpoint output stays byte-identical.
                        out = out ++ segment.replace(":", "")
            segment_start = i + 1
        i = i + 1
    out

fn link_stage_output_dir_for_source(source_path: &str) -> str:
    let artifact_root = link_stage_artifact_root()
    let dir = link_stage_sanitize_relative_dir(link_stage_dirname(source_path))
    if dir.len() == 0:
        return artifact_root
    artifact_root ++ "/" ++ dir

fn link_stage_output_path_for_source(source_path: &str) -> str:
    let base = link_stage_output_dir_for_source(source_path) ++ "/" ++ link_stage_source_stem(source_path)
    if runtime_sysinfo_os() == "Windows":
        return base ++ ".exe"
    base

fn link_stage_link_object_to_binary(obj_path: &str, bin_path: &str, link_libs: Vec[str], link_search_paths: &Vec[str], needs_async_runtime: bool) -> bool:
    let link_args: Vec[str] = Vec.new()
    link_stage_link_object_to_binary_result(obj_path, bin_path, link_libs, link_search_paths, move link_args, needs_async_runtime).ok

fn link_stage_link_object_to_binary_result(obj_path: &str, bin_path: &str, link_libs: Vec[str], link_search_paths: &Vec[str], link_args: Vec[str], needs_async_runtime: bool) -> LinkStageResult:
    let no_extra_objects: Vec[str] = Vec.new()
    link_stage_result_for_plan(link_stage_link_object_to_binary_plan_with_units(obj_path, no_extra_objects, bin_path, link_libs, link_search_paths, move link_args, needs_async_runtime))

fn link_stage_link_object_to_binary_plan(obj_path: &str, bin_path: &str, link_libs: Vec[str], link_search_paths: &Vec[str], link_args: Vec[str], needs_async_runtime: bool) -> LinkStagePlan:
    let no_extra_objects: Vec[str] = Vec.new()
    link_stage_link_object_to_binary_plan_with_units(obj_path, no_extra_objects, bin_path, link_libs, link_search_paths, move link_args, needs_async_runtime)

fn link_stage_link_object_to_binary_plan_with_units(obj_path: &str, extra_objects: &Vec[str], bin_path: &str, link_libs: Vec[str], link_search_paths: &Vec[str], link_args: Vec[str], needs_async_runtime: bool) -> LinkStagePlan:
    let extras: Vec[str] = Vec.new()
    // #650 codegen units: sibling .o files are full linker inputs like the
    // primary object (objects always load wholly, so position is irrelevant).
    for ui in 0..extra_objects.len() as i32:
        extras.push(with_str_clone_ref(extra_objects.get(ui as i64)))
    for i in 0..link_search_paths.len() as i32:
        extras.push("-L" ++ link_search_paths.get(i as i64))
    var undef = link_stage_undefined_symbols_for_object(obj_path)
    // Runtime-need detection must see undefined symbols from every unit, not
    // just the primary object. A failed probe stays the pure sentinel so the
    // conservative "<probe-failed>" equality checks keep firing.
    for uu in 0..extra_objects.len() as i32:
        if undef == "<probe-failed>":
            break
        let unit_undef = link_stage_undefined_symbols_for_object(extra_objects.get(uu as i64))
        if unit_undef == "<probe-failed>":
            undef = "<probe-failed>"
        else:
            undef = undef ++ unit_undef
    let needs_fiber_runtime = if needs_async_runtime: 1 else: link_stage_undefined_symbols_need_fiber_runtime(undef)
    let needs_regex_runtime = link_stage_undefined_symbols_need_regex_runtime(undef)
    let needs_compat_runtime = link_stage_undefined_symbols_need_compat_runtime(undef)
    if needs_fiber_runtime != 0:
        let channel_runtime_path = link_stage_find_runtime_object_path("channel_runtime.o")
        if channel_runtime_path.len() == 0:
            with_eprint("error: missing runtime/channel_runtime.o")
            return link_stage_plan_fail()
        extras.push(channel_runtime_path)
        let fiber_runtime_path = link_stage_find_runtime_object_path("fiber_runtime.o")
        if fiber_runtime_path.len() == 0:
            with_eprint("error: missing runtime/fiber_runtime.o")
            return link_stage_plan_fail()
        extras.push(fiber_runtime_path)
        let fiber_path = link_stage_find_runtime_object_path("fiber.o")
        if fiber_path.len() == 0:
            with_eprint("error: missing runtime/fiber.o")
            return link_stage_plan_fail()
        extras.push(fiber_path)
        let fiber_asm_path = link_stage_find_runtime_object_path("fiber_asm.o")
        if fiber_asm_path.len() == 0:
            with_eprint("error: missing runtime/fiber_asm.o")
            return link_stage_plan_fail()
        extras.push(fiber_asm_path)

    let needs_helpers_runtime = link_stage_undefined_symbols_need_helpers_runtime(undef)
    if needs_helpers_runtime != 0:
        let use_rt_core = link_stage_should_use_rt_core_from_undef(undef)
        let needs_llvm = link_stage_undefined_symbols_need_llvm_bridge(undef)
        if use_rt_core:
            // Pure With program — rt_core.o + platform backend + panic runtime.
            // Non-async builds also link fiber_stubs.o for lifecycle and fiber
            // fallback symbols; async builds bring fiber.o instead.
            let rt_core_path = link_stage_find_runtime_object_path("rt_core.o")
            if rt_core_path.len() == 0:
                with_eprint("error: missing rt_core.o")
                return link_stage_plan_fail()
            extras.push(rt_core_path)
            let rt_platform_object = link_stage_platform_runtime_object()
            if rt_platform_object.len() == 0:
                return link_stage_plan_fail()
            let rt_platform_path = link_stage_find_runtime_object_path(rt_platform_object)
            if rt_platform_path.len() == 0:
                with_eprint("error: missing " ++ rt_platform_object)
                return link_stage_plan_fail()
            extras.push(rt_platform_path)
            let panic_rt_path = link_stage_find_runtime_object_path("panic_runtime.o")
            if panic_rt_path.len() == 0:
                with_eprint("error: missing runtime/panic_runtime.o")
                return link_stage_plan_fail()
            let panic_ar = link_stage_make_archive(panic_rt_path)
            extras.push(if panic_ar.len() > 0: panic_ar else: panic_rt_path)
            if needs_regex_runtime != 0:
                let regex_runtime_path = link_stage_find_runtime_object_path("regex_runtime.o")
                if regex_runtime_path.len() == 0:
                    with_eprint("error: missing runtime/regex_runtime.o")
                    return link_stage_plan_fail()
                let regex_runtime_ar = link_stage_make_archive(regex_runtime_path)
                extras.push(if regex_runtime_ar.len() > 0: regex_runtime_ar else: regex_runtime_path)
            if needs_compat_runtime != 0:
                let compat_runtime_path = link_stage_find_runtime_object_path("compat_runtime.o")
                if compat_runtime_path.len() == 0:
                    with_eprint("error: missing runtime/compat_runtime.o")
                    return link_stage_plan_fail()
                let compat_runtime_ar = link_stage_make_archive(compat_runtime_path)
                extras.push(if compat_runtime_ar.len() > 0: compat_runtime_ar else: compat_runtime_path)
            if needs_fiber_runtime == 0:
                let fiber_stubs_path = link_stage_find_runtime_object_path("fiber_stubs.o")
                if fiber_stubs_path.len() == 0:
                    with_eprint("error: missing runtime/fiber_stubs.o")
                    return link_stage_plan_fail()
                let fiber_stubs_ar = link_stage_make_archive(fiber_stubs_path)
                extras.push(if fiber_stubs_ar.len() > 0: fiber_stubs_ar else: fiber_stubs_path)
        else if needs_llvm:
            // Compiler build (lld path) — rt_core.o provides the runtime,
            // compat_runtime.o has libc-dependent functions (system, signals),
            // cimport_stubs.o has c_import/fiber weak stubs.
            let rt_core_path = link_stage_find_runtime_object_path("rt_core.o")
            if rt_core_path.len() == 0:
                with_eprint("error: missing rt_core.o")
                return link_stage_plan_fail()
            extras.push(rt_core_path)
            let rt_platform_object = link_stage_platform_runtime_object()
            if rt_platform_object.len() == 0:
                return link_stage_plan_fail()
            let rt_platform_path = link_stage_find_runtime_object_path(rt_platform_object)
            if rt_platform_path.len() == 0:
                with_eprint("error: missing " ++ rt_platform_object)
                return link_stage_plan_fail()
            extras.push(rt_platform_path)
            let compat_runtime_path = link_stage_find_runtime_object_path("compat_runtime.o")
            if compat_runtime_path.len() == 0:
                with_eprint("error: missing runtime/compat_runtime.o")
                return link_stage_plan_fail()
            extras.push(compat_runtime_path)
            let panic_runtime_path = link_stage_find_runtime_object_path("panic_runtime.o")
            if panic_runtime_path.len() == 0:
                with_eprint("error: missing runtime/panic_runtime.o")
                return link_stage_plan_fail()
            extras.push(panic_runtime_path)
            if needs_regex_runtime != 0:
                let regex_runtime_path = link_stage_find_runtime_object_path("regex_runtime.o")
                if regex_runtime_path.len() == 0:
                    with_eprint("error: missing runtime/regex_runtime.o")
                    return link_stage_plan_fail()
                extras.push(regex_runtime_path)
            if needs_fiber_runtime == 0:
                let fiber_stubs_path = link_stage_find_runtime_object_path("fiber_stubs.o")
                if fiber_stubs_path.len() == 0:
                    with_eprint("error: missing runtime/fiber_stubs.o")
                    return link_stage_plan_fail()
                extras.push(fiber_stubs_path)
            let helpers_path = link_stage_find_runtime_object_path("cimport_stubs.o")
            if helpers_path.len() == 0:
                with_eprint("error: missing runtime/cimport_stubs.o")
                return link_stage_plan_fail()
            extras.push(helpers_path)
        else:
            // User program with c_import (cc/Apple ld64 path) — rt_core.o first,
            // then cimport_stubs as archive. Apple's ld64 resolves archives correctly:
            // rt_core.o definitions win, cimport_stubs.a fills in C-only symbols.
            let rt_core_path = link_stage_find_runtime_object_path("rt_core.o")
            if rt_core_path.len() == 0:
                with_eprint("error: missing rt_core.o")
                return link_stage_plan_fail()
            extras.push(rt_core_path)
            let rt_platform_object = link_stage_platform_runtime_object()
            if rt_platform_object.len() == 0:
                return link_stage_plan_fail()
            let rt_platform_path = link_stage_find_runtime_object_path(rt_platform_object)
            if rt_platform_path.len() == 0:
                with_eprint("error: missing " ++ rt_platform_object)
                return link_stage_plan_fail()
            extras.push(rt_platform_path)
            let panic_runtime_path = link_stage_find_runtime_object_path("panic_runtime.o")
            if panic_runtime_path.len() == 0:
                with_eprint("error: missing runtime/panic_runtime.o")
                return link_stage_plan_fail()
            let panic_ar = link_stage_make_archive(panic_runtime_path)
            extras.push(if panic_ar.len() > 0: panic_ar else: panic_runtime_path)
            if needs_regex_runtime != 0:
                let regex_runtime_path = link_stage_find_runtime_object_path("regex_runtime.o")
                if regex_runtime_path.len() == 0:
                    with_eprint("error: missing runtime/regex_runtime.o")
                    return link_stage_plan_fail()
                let regex_runtime_ar = link_stage_make_archive(regex_runtime_path)
                extras.push(if regex_runtime_ar.len() > 0: regex_runtime_ar else: regex_runtime_path)
            if needs_compat_runtime != 0:
                let compat_runtime_path = link_stage_find_runtime_object_path("compat_runtime.o")
                if compat_runtime_path.len() == 0:
                    with_eprint("error: missing runtime/compat_runtime.o")
                    return link_stage_plan_fail()
                let compat_runtime_ar = link_stage_make_archive(compat_runtime_path)
                extras.push(if compat_runtime_ar.len() > 0: compat_runtime_ar else: compat_runtime_path)
            if needs_fiber_runtime == 0:
                let fiber_stubs_path = link_stage_find_runtime_object_path("fiber_stubs.o")
                if fiber_stubs_path.len() == 0:
                    with_eprint("error: missing runtime/fiber_stubs.o")
                    return link_stage_plan_fail()
                let fiber_stubs_ar = link_stage_make_archive(fiber_stubs_path)
                extras.push(if fiber_stubs_ar.len() > 0: fiber_stubs_ar else: fiber_stubs_path)
            let helpers_path = link_stage_find_runtime_object_path("cimport_stubs.o")
            if helpers_path.len() == 0:
                with_eprint("error: missing runtime/cimport_stubs.o")
                return link_stage_plan_fail()
            let helpers_ar = link_stage_make_archive(helpers_path)
            extras.push(if helpers_ar.len() > 0: helpers_ar else: helpers_path)

    if link_stage_undefined_symbols_need_llvm_bridge(undef):
        let static_bridge = link_stage_find_llvm_static_bridge()
        if static_bridge.len() > 0:
            // Static LLVM linking: use llvm_bridge.o + LLVM static libs.
            // All target-built inputs come from the variant dir (the
            // cross/<target>/ subdir on a cross link); only the linker
            // path metadata is the host's.
            let root = link_stage_resolve_runtime_root()
            let variant = link_stage_runtime_variant_dir()
            let rsp_path = variant ++ "/llvm_ld.rsp"
            let ld_path = link_stage_read_file_trimmed(root ++ "/llvm_ld")
            extras.push(static_bridge)
            // Include embedded runtime objects for self-contained binary
            let embedded_path = variant ++ "/embedded_objects.o"
            if runtime_read_file(embedded_path).len() > 0:
                extras.push(embedded_path)
            // Include clang bridge for c_import support
            let clang_bridge_path = variant ++ "/clang_bridge.o"
            if runtime_read_file(clang_bridge_path).len() > 0:
                extras.push(clang_bridge_path)
            extras.push("@" ++ rsp_path)
            let all_link_args = link_args
            return link_stage_link_with_llvm_args_plan(obj_path, bin_path, extras, link_libs, all_link_args, ld_path)
        with_eprint("error: missing LLVM static bridge (need llvm_bridge.o + llvm_ld.rsp + llvm_ld)")
        return link_stage_plan_fail()

    if extras.len() == 0 and link_libs.len() == 0 and link_args.len() == 0:
        return link_stage_link_with_extras_libs_args_plan(obj_path, bin_path, extras, link_libs, link_args)
    link_stage_link_with_extras_libs_args_plan(obj_path, bin_path, extras, link_libs, link_args)
