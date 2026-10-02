use Archive
use compiler.Runtime
use compiler.LinkDiagnostics
use compiler.EmbeddedBundles
use compiler.BundleInterfaces
use compiler.AbiStamp
use compiler.WasmHost
use compiler.LldDriver
use compiler.EmbeddedSysroot
use std.string.StringBuilder
use std.collections.Atomic
use TargetSpec
use compiler.EmbeddedClangResourceData

extern fn with_str_clone_ref(s: &str) -> str

extern let with_embedded_cimport_stubs_o_start: u8
extern let with_embedded_cimport_stubs_o_end: u8
extern let with_embedded_compat_runtime_o_start: u8
extern let with_embedded_compat_runtime_o_end: u8
extern let with_embedded_panic_runtime_o_start: u8
extern let with_embedded_panic_runtime_o_end: u8
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
extern let with_embedded_rt_linux_aarch64_o_start: u8
extern let with_embedded_rt_linux_aarch64_o_end: u8
extern let with_embedded_rt_linux_x86_64_o_start: u8
extern let with_embedded_rt_linux_x86_64_o_end: u8
extern let with_embedded_rt_windows_x86_64_o_start: u8
extern let with_embedded_rt_windows_x86_64_o_end: u8
extern let with_embedded_rt_windows_aarch64_o_start: u8
extern let with_embedded_rt_windows_aarch64_o_end: u8

// D30 R2c: set by Compilation when THIS compile emitted the runtime
// in-unit (WITH_RT_IN_UNIT lane, prelude on) — the .w-derived rt objects
// must not link (duplicate strong symbols); fiber_asm.o and the on-demand
// cimport archive stay. Compiler knowledge, never an nm/env probe at link
// time.
var link_stage_rt_in_unit_flag: i32 = 0

pub fn link_stage_set_rt_in_unit(on: i32) -> Unit:
    link_stage_rt_in_unit_flag = on

fn link_stage_rt_in_unit() -> i32:
    link_stage_rt_in_unit_flag

var link_stage_temp_archives: Vec[str] = Vec.new()
var link_stage_temp_archives_lock: Atomic[i32]

fn link_stage_temp_archives_lock_acquire():
    while link_stage_temp_archives_lock.swap(1, .Acquire) != 0:
        let _ = 0

fn link_stage_temp_archives_lock_release():
    link_stage_temp_archives_lock.store(0, .Release)

pub type LinkStageEnvVar {
    name: str,
    value: str,
}

pub type LinkStageCommand {
    linker: str,
    args: Vec[str],
    cwd: str,
    env: Vec[LinkStageEnvVar],
    inputs: Vec[str],
    outputs: Vec[str],
    cleanup_files: Vec[str],
}

pub type LinkStageResult {
    ok: bool,
    rc: i32,
    command: LinkStageCommand,
}

pub type LinkStagePlan {
    ok: bool,
    command: LinkStageCommand,
}

pub fn link_stage_empty_command() -> LinkStageCommand:
    LinkStageCommand {
        linker: "",
        args: Vec.new(),
        cwd: "",
        env: Vec.new(),
        inputs: Vec.new(),
        outputs: Vec.new(),
        cleanup_files: Vec.new(),
    }

pub fn link_stage_result_fail() -> LinkStageResult:
    LinkStageResult { ok: false, rc: 1, command: link_stage_empty_command() }

fn link_stage_plan_fail() -> LinkStagePlan:
    LinkStagePlan { ok: false, command: link_stage_empty_command() }

fn link_stage_plan_for_command(command: LinkStageCommand) -> LinkStagePlan:
    LinkStagePlan { ok: true, command }

pub fn link_stage_result_for_command(command: LinkStageCommand) -> LinkStageResult:
    let rc = command.run()
    link_stage_cleanup_files(command.cleanup_files)
    LinkStageResult { ok: rc == 0, rc, command }

fn link_stage_result_for_plan(plan: LinkStagePlan) -> LinkStageResult:
    if not plan.ok:
        return link_stage_result_fail()
    // D32: field vacates need a mutable path — rebind the owned param.
    var owned_plan = plan
    link_stage_result_for_command(move owned_plan.command)

fn link_stage_argv_append(argv: &str, arg: &str) -> str:
    argv ++ arg ++ "\0"

fn link_stage_is_digit(ch: i32) -> bool:
    ch >= 48 and ch <= 57

fn link_stage_read_u32_le(data: &str, offset: i32) -> i64:
    if offset < 0 or offset + 3 >= data.len() as i32:
        return -1
    (data[offset] as i64) |
        ((data[(offset + 1)] as i64) << 8) |
        ((data[(offset + 2)] as i64) << 16) |
        ((data[(offset + 3)] as i64) << 24)

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
        let extra_minos = link_stage_macho_macos_minos(extras[i])
        if extra_minos > best:
            best = extra_minos
    link_stage_darwin_version_string(best)

fn link_stage_is_temp_archive_path(path: &str) -> bool:
    if not path.ends_with(".a"):
        return false
    var i = 0
    while i + 3 < path.len():
        if path.slice(i as i64, (i + 3) as i64) == ".o.":
            return link_stage_is_digit(path[(i + 3)])
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

// #1193: GNU ld and lld resolve static archives left to right, once. A
// package's archives arrive in scan order (libcrypto before libssl), so one
// that depends on a later one leaves undefined references. On an ELF target
// the user's libraries are linked as one group; ld64 and lld-link are
// order-insensitive and take no marker. `via_driver` selects the `-Wl,`
// spelling for a C compiler driver.
pub fn link_stage_archive_group_marker(is_elf: i32, via_driver: i32, open: i32) -> str:
    if is_elf == 0: return ""
    let flag = if open != 0: "--start-group" else: "--end-group"
    if via_driver != 0: "-Wl," ++ flag else: flag

fn link_stage_collect_cleanup_files(extras: &Vec[str]) -> Vec[str]:
    let cleanup: Vec[str] = Vec.new()
    for i in 0..extras.len() as i32:
        let extra = extras[i]
        if link_stage_is_temp_archive_path(extra):
            cleanup.push(with_str_clone_ref(extra))
    cleanup

pub fn link_stage_cleanup_files(files: &Vec[str]):
    for i in 0..files.len() as i32:
        let _remove = runtime_remove_file(files[i])

fn link_stage_register_temp_archive(path: &str):
    // Comptime parallel() links on concurrent threads; an unguarded push to this
    // shared registry races vec_grow (double free of the old buffer, #617).
    link_stage_temp_archives_lock_acquire()
    link_stage_temp_archives.push(with_str_clone_ref(path))
    link_stage_temp_archives_lock_release()

pub fn link_stage_basename(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
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
        let ch = listing[i]
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

pub fn link_stage_cleanup_current_process_temp_archives():
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
        let item = env[i]
        names.push(with_str_clone_ref(item.name))
        values.push(runtime_getenv(item.name) ++ "")
        let _ = runtime_setenv(item.name, item.value)
    LinkStageSavedEnv { names, values }

fn link_stage_restore_env(saved: &LinkStageSavedEnv):
    for i in 0..saved.names.len() as i32:
        let _ = runtime_setenv(saved.names[i], saved.values[i])

// WITH_LINK_VERBOSE=1 prints every link's argv before it runs, and asks a
// COFF link for lld-link's /verbose (each input it reads, each member it
// loads): the evidence of what a link reads, for a toolchain audit (#1915).
fn link_stage_verbose() -> bool: runtime_getenv("WITH_LINK_VERBOSE") == "1"

impl LinkStageCommand:
    fn run() -> i32:
        var argv = ""
        argv = link_stage_argv_append(argv, self.linker)
        var shown = with_str_clone_ref(self.linker)
        for i in 0..self.args.len() as i32:
            argv = link_stage_argv_append(argv, self.args[i])
            shown = shown ++ " " ++ self.args[i]
        if link_stage_verbose():
            with_eprint("link: " ++ shown)
        let saved = link_stage_apply_env(&self.env)
        let linux_target = if target_spec_is_native(): runtime_sysinfo_os() == "Linux" else: target_spec_active_kind() == 1 or target_spec_active_kind() == 2
        // #1915, #1914: a failed macOS or Windows link says why (lld's own
        // diagnostics, or the linker and its exit status), never a bare
        // "build failed".
        let darwin_native = target_spec_is_native() and runtime_sysinfo_os() == "Macos"
        let windows_native = target_spec_is_native() and runtime_sysinfo_os() == "Windows"
        let rc = if linux_target or darwin_native or windows_native:
            link_run_with_diagnostics(argv, self.cwd)
        else if self.cwd.len() > 0:
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
        let extra = extras[i]
        args.push(with_str_clone_ref(extra))
        inputs.push(with_str_clone_ref(extra))
    if runtime_sysinfo_os() == "Macos":
        args.push("-Wl,-dead_strip")
    else if runtime_sysinfo_os() == "Linux":
        // Native user programs use the platform C driver. Requiring lld here
        // makes the release compiler depend on an external LLVM installation.
        // Compiler/cross links use the explicit LLVM plan below, which owns
        // its lld-specific flags (including identical-code folding).
        args.push("-no-pie")
        args.push("-Wl,--gc-sections")
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))
    let cc_is_darwin = if runtime_sysinfo_os() == "Macos": 1 else: 0
    let cc_is_elf = if runtime_sysinfo_os() == "Linux" and link_libs.len() > 0: 1 else: 0
    if cc_is_elf != 0: args.push(link_stage_archive_group_marker(1, 1, 1))
    for i in 0..link_libs.len() as i32:
        let cc_la = link_stage_lib_args(link_libs[i], cc_is_darwin)
        for j in 0..cc_la.len() as i32:
            args.push(with_str_clone_ref(cc_la[j]))
    if cc_is_elf != 0: args.push(link_stage_archive_group_marker(1, 1, 0))
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args[i]))
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
        let dir = candidates[i]
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

/// The `<from>` of WITH_FILE_PREFIX_MAP=<from>=<to> (src/FnAbi.w), or "".
pub fn link_stage_file_prefix_map_root() -> str:
    let mapping = runtime_getenv("WITH_FILE_PREFIX_MAP")
    let eq = mapping.find("=")
    if eq <= 0: "" else: mapping.slice(0, eq)

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
    // The debug map (N_OSO) names every linked object by absolute path, 23
    // checkout paths in the compiler's string table. Under WITH_FILE_PREFIX_MAP
    // the linker drops the mapped root, and dsymutil is told where to look
    // (compilation_run_dsymutil_best_effort).
    let oso_root = link_stage_file_prefix_map_root()
    if oso_root.len() > 0:
        args.push("-oso_prefix")
        args.push(oso_root ++ "/")
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras[i]
        args.push(with_str_clone_ref(extra))
        inputs.push(with_str_clone_ref(extra))
    for i in 0..link_libs.len() as i32:
        let dw_la = link_stage_lib_args(link_libs[i], 1)
        for j in 0..dw_la.len() as i32:
            args.push(with_str_clone_ref(dw_la[j]))
    for arg in link_stage_driver_args_for_ld(link_args):
        args.push(arg.clone())
    args.push("-lSystem")
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(llvm_ld), args, cwd: "", env, inputs, outputs, cleanup_files }

// #1915 (D81): a native linux-x86_64 link reads this compiler's own sysroot
// (compiler.EmbeddedSysroot: glibc 2.28 link stubs, glibc's crt objects,
// compiler-rt's builtins and crtbegin/crtend), never the host's gcc or glibc
// files. WITH_LINUX_SYSROOT names another sysroot explicitly (the host
// layout, as a cross link uses it); a cross target and linux-aarch64 keep
// that path until their slices.
// On linux-x86_64 and linux-aarch64, native or cross.
fn link_stage_linux_uses_own_sysroot() -> bool:
    if runtime_getenv("WITH_LINUX_SYSROOT").len() > 0:
        return false
    let a = link_stage_linux_arch()
    let linux_target = if target_spec_is_native(): runtime_sysinfo_os() == "Linux" else: target_spec_os() == "Linux"
    linux_target and (a == "x86_64" or a == "aarch64")

// The own sysroot a Linux link reads: this compiler's embedded one for a
// native link; for a cross link, the one the cross build put beside the
// target's runtime objects (build.w's cross-*-sysroot). "" when absent.
fn link_stage_linux_own_sysroot_dir() -> str:
    if target_spec_is_native():
        return embedded_linux_sysroot_dir()
    let dir = link_stage_runtime_variant_dir() ++ "/sysroot"
    if link_stage_file_exists(dir ++ "/usr/lib/libc.so.6"): dir else: ""

fn link_stage_linux_own_dynamic_linker() -> str:
    if link_stage_linux_arch() == "aarch64": "/lib/ld-linux-aarch64.so.1" else: "/lib64/ld-linux-x86-64.so.2"

fn link_stage_make_linux_own_sysroot_command(linker: &str, sysroot: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str], compiler_link: bool) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    let lib = sysroot ++ "/usr/lib"
    args.push("-m")
    args.push(link_stage_linux_emulation())
    for a in ["--eh-frame-hdr", "--hash-style=gnu", "--build-id", "--gc-sections", "--as-needed", "-dynamic-linker"]:
        args.push(a.clone())
    args.push(link_stage_linux_own_dynamic_linker())
    // The compiler folds identical code, as its link always has.
    if compiler_link: args.push("--icf=all")
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))
    for crt in ["crt1.o", "crti.o", "clang_rt.crtbegin.o"]:
        args.push(lib ++ "/" ++ crt)
        inputs.push(lib ++ "/" ++ crt)
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        args.push(with_str_clone_ref(extras[i]))
        inputs.push(with_str_clone_ref(extras[i]))
    args.push("-L" ++ lib)
    // A library a program names that the sysroot does not carry (zlib, curl)
    // is the host's, found after every sysroot one, as c_import finds its
    // header (ClangBridge cimport_push_host_library_dirs). The compiler's own
    // link names none.
    if not compiler_link and link_libs.len() > 0 and target_spec_is_native():
        args.push("-L/usr/lib/" ++ link_stage_linux_multiarch())
        args.push("-L/lib/" ++ link_stage_linux_multiarch())
    if link_libs.len() > 0: args.push(link_stage_archive_group_marker(1, 0, 1))
    for i in 0..link_libs.len() as i32:
        let name = link_libs[i]
        if link_stage_framework_name(name).len() > 0:
            with_eprint("error: link: \"" ++ name ++ "\" — Apple frameworks are only available on macOS targets\n")
        else:
            args.push("-l" ++ name)
    if link_libs.len() > 0: args.push(link_stage_archive_group_marker(1, 0, 0))
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args[i]))
    // libm, libpthread and libdl (separate libraries until glibc 2.34, and
    // the sysroot targets 2.28), libc (glibc's script: libc.so.6,
    // libc_nonshared, the dynamic linker), and compiler-rt where a gcc link
    // has libgcc.
    args.push("-lm")
    args.push("-lpthread")
    args.push("-ldl")
    args.push("-lc")
    for rt in ["libclang_rt.builtins.a", "clang_rt.crtend.o", "crtn.o"]:
        args.push(lib ++ "/" ++ rt)
        inputs.push(lib ++ "/" ++ rt)
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(linker), args, cwd: "", env, inputs, outputs, cleanup_files }

// A native linux-x86_64 program: this binary's own lld (`with __ld`) over
// its own sysroot. No cc, no ld, no gcc, no host glibc development files.
fn link_stage_linux_native_link_plan(obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStagePlan:
    let self_exe = with_self_exe()
    if self_exe.len() == 0:
        with_eprint("error: link: cannot find this compiler's own executable to run its linker (argv[0] is '" ++ runtime_arg_at(0) ++ "')")
        return link_stage_plan_fail()
    let sysroot = embedded_linux_sysroot_dir()
    if sysroot.len() == 0:
        with_eprint("error: link: this compiler carries no linux sysroot, and WITH_LINUX_SYSROOT names none")
        return link_stage_plan_fail()
    let ld_link_args = link_stage_linux_driver_args_for_ld(link_args)
    var command = link_stage_make_linux_own_sysroot_command(self_exe, sysroot, obj_path, bin_path, extras, link_libs, &ld_link_args, false)
    let args: Vec[str] = Vec.new()
    args.push("__ld")
    for i in 0..command.args.len() as i32:
        args.push(with_str_clone_ref(command.args[i]))
    command.args = args
    link_stage_plan_for_command(move command)

// The driver spellings a program's link arguments use on Linux, for lld:
// `-Wl,` unwrapped as on macOS, and `-pthread` (a driver flag) its library.
fn link_stage_linux_driver_args_for_ld(link_args: &Vec[str]) -> Vec[str]:
    let unwrapped = link_stage_driver_args_for_ld(link_args)
    let out: Vec[str] = Vec.new()
    for i in 0..unwrapped.len() as i32:
        if unwrapped[i] == "-pthread": out.push("-lpthread") else: out.push(with_str_clone_ref(unwrapped[i]))
    out

fn link_stage_make_linux_llvm_link_command(llvm_ld: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    if link_stage_linux_uses_own_sysroot():
        let own = link_stage_linux_own_sysroot_dir()
        if own.len() == 0:
            if target_spec_is_native():
                with_eprint("error: link: this compiler carries no linux sysroot, and WITH_LINUX_SYSROOT names none")
            else:
                with_eprint("error: link: no linux sysroot for " ++ target_spec_name() ++ " at " ++ link_stage_runtime_variant_dir() ++ "/sysroot (build the cross runtime, which puts it there), and WITH_LINUX_SYSROOT names none")
            return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
        return link_stage_make_linux_own_sysroot_command(llvm_ld, own, obj_path, bin_path, extras, link_libs, link_args, true)
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
        let extra = extras[i]
        args.push(with_str_clone_ref(extra))
        inputs.push(with_str_clone_ref(extra))

    args.push("-L" ++ gcc_dir)
    args.push("-L" ++ sysroot ++ "/usr/lib/" ++ link_stage_linux_multiarch())
    args.push("-L" ++ sysroot ++ "/lib/" ++ link_stage_linux_multiarch())
    args.push("-L" ++ sysroot ++ "/usr/lib")
    args.push("-L" ++ sysroot ++ "/lib")
    if link_libs.len() > 0: args.push(link_stage_archive_group_marker(1, 0, 1))
    for i in 0..link_libs.len() as i32:
        let lib = link_libs[i]
        if link_stage_framework_name(lib).len() > 0:
            with_eprint("error: link: \"" ++ lib ++ "\" — Apple frameworks are only available on macOS targets\n")
        else:
            let fallback_lib = link_stage_linux_system_lib_path(sysroot, lib)
            if fallback_lib.len() > 0:
                args.push(with_str_clone_ref(fallback_lib))
                inputs.push(fallback_lib)
            else:
                args.push("-l" ++ lib)
    if link_libs.len() > 0: args.push(link_stage_archive_group_marker(1, 0, 0))
    for arg in link_stage_driver_args_for_ld(link_args):
        args.push(arg.clone())
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

// Unix-only library spellings that have no Windows import lib and whose
// symbols the C runtime linked below already provides (cos/abs/... in the
// UCRT and mingwex, strlen/malloc/... in the UCRT). A `link:` directive naming
// one of these (e.g. `c_import("math.h", link: "m")`) must be dropped on the
// Windows link, not turned into a nonexistent `m.lib`.
fn link_stage_windows_lib_is_crt_implicit(name: &str): name == "m" or name == "c"

// The compiler's own link (#1267): a link that carries the LLVM static bridge
// response file (`@…/llvm_ld.rsp`) is the compiler being built as a program.
// An SDK whose LLVM is a windows-gnu build against the SDK's own libc++
// (#1915; its archives are GNU-named, lib/libclang.a) links the compiler
// like any program, from the SDK only. The Visual Studio-built SDKs pinned
// before it (lib/libclang.lib) are MultiThreaded (static UCRT) archives
// that need Visual Studio's static C and C++ runtime (libcmt, libcpmt): that
// link, with such an SDK, is the only one that still reads Visual Studio or a
// Windows Kit (WITH_WINDOWS_*_LIBDIR).
fn link_stage_windows_is_compiler_link(extras: &Vec[str]) -> bool:
    for i in 0..extras.len() as i32:
        if link_stage_is_llvm_bridge_rsp(extras[i]):
            return true
    false

fn link_stage_is_llvm_bridge_rsp(extra: &str) -> bool:
    extra.starts_with("@") and extra.ends_with("/llvm_ld.rsp")

// The architecture of a Windows link: the cross target's, else the host's.
pub fn link_stage_windows_arch() -> str:
    if not target_spec_is_native():
        return if target_spec_active_kind() == 6: "aarch64" else: "x86_64"
    let arch = runtime_sysinfo_arch()
    if arch == "armv8" or arch == "aarch64": "aarch64" else: "x86_64"

// The LLVM SDK a link reads: the directory above the bin/ holding the lld it
// runs (.deps/llvm-<ver>-<host>/bin/lld-link.exe).
fn link_stage_sdk_dir_of(llvm_ld: &str) -> str: link_stage_dirname(link_stage_dirname(llvm_ld))

// The SDK's Windows C runtime (#1915; build/sdk.w
// run_sdk_windows_libc_action), the sysroot of the SDK's clang for a
// <arch>-w64-windows-gnu target: include/ holds mingw-w64's headers, which
// c_import parses; <arch>-w64-mingw32/lib holds its UCRT startup objects,
// support libraries and the in-box DLLs' import libraries, which a program
// links. WITH_WINDOWS_LIBC_DIR names another directory laid out the same.
fn link_stage_windows_libc_root_in(sdk_dir: &str) -> str:
    let explicit = runtime_getenv("WITH_WINDOWS_LIBC_DIR")
    if explicit.len() > 0:
        return explicit ++ ""
    sdk_dir ++ "/libc/windows"

fn link_stage_windows_libc_dir(sdk_dir: &str, arch: &str) -> str:
    link_stage_windows_libc_root_in(sdk_dir) ++ "/" ++ arch ++ "-w64-mingw32/lib"

// The C target a Windows c_import parses for: mingw-w64's headers are
// written for the GNU environment, the environment With's own Windows
// x86_64 objects target too (TargetSpec).
pub fn link_stage_windows_c_target() -> str: link_stage_windows_arch() ++ "-w64-windows-gnu"

// Whether this compilation targets Windows x86_64, whose programs and
// c_import read the SDK's libc (windows-aarch64 follows in its own slice).
pub fn link_stage_windows_c_target_uses_sdk_libc() -> bool:
    let windows = if target_spec_is_native(): runtime_sysinfo_os() == "Windows" else: target_spec_active_kind() == 5 or target_spec_active_kind() == 6
    windows and link_stage_windows_arch() == "x86_64"

// The Windows libc c_import reads for this compilation: the SDK's (the same
// one the link will read), "" when the target is not Windows x86_64 or the
// SDK carries none.
// The toolchain a native Windows link and `with cc` read, laid out as the
// LLVM SDK is: the SDK above the lld the link runs (the build's record, or
// the SDK the environment names), else the one this compiler carries
// (compiler.EmbeddedSysroot, #1915 D81). "" when there is neither.
pub fn link_stage_windows_sdk_dir() -> str:
    let ld = link_stage_llvm_ld_path()
    if ld.len() > 0:
        return link_stage_sdk_dir_of(ld)
    if runtime_sysinfo_os() == "Windows" and target_spec_is_native():
        return embedded_windows_sysroot_dir()
    ""

pub fn link_stage_windows_libc_root() -> str:
    if not link_stage_windows_c_target_uses_sdk_libc():
        return ""
    let sdk = link_stage_windows_sdk_dir()
    if sdk.len() == 0:
        return ""
    let root = link_stage_windows_libc_root_in(sdk)
    if not link_stage_file_exists(root ++ "/include/stdio.h"):
        return ""
    root

// The lld a link runs, as link_stage_link_with_extras_libs_args_plan
// resolves it: the build's recorded llvm_ld, else (a native Windows link
// before the metadata exists) the environment's. "" when there is none.
fn link_stage_llvm_ld_path() -> str:
    let root = link_stage_resolve_runtime_root()
    var ld_path = link_stage_read_file_trimmed(root ++ "/llvm_ld")
    if ld_path.len() == 0 and runtime_sysinfo_os() == "Windows" and target_spec_is_native():
        ld_path = link_stage_windows_lld_from_env()
    ld_path

// compiler-rt's builtins for the target, in the SDK's clang resource dir: the
// mingw-w64 runtime's ___chkstk_ms and its 128-bit and soft-float helpers.
fn link_stage_windows_builtins(sdk_dir: &str, arch: &str) -> str:
    sdk_dir ++ "/lib/clang/" ++ embedded_clang_resource_version() ++ "/lib/windows/libclang_rt.builtins-" ++ arch ++ ".a"

// The in-box DLLs every program links, and uuid's GUIDs (their libraries ship
// in the SDK's libc; build/sdk.w sdk_windows_import_libs names the DLLs).
fn link_stage_windows_system_libs() -> Vec[str]:
    let names: Vec[str] = Vec.new()
    names.push("kernel32.lib")
    names.push("ntdll.lib")
    names.push("advapi32.lib")
    names.push("bcrypt.lib")
    names.push("ws2_32.lib")
    names.push("dbghelp.lib")
    names.push("shell32.lib")
    names.push("user32.lib")
    names.push("ole32.lib")
    names.push("oleaut32.lib")
    names.push("version.lib")
    names.push("psapi.lib")
    // GUID_NULL, IID_* and the other GUIDs windows.h declares extern.
    names.push("uuid.lib")
    names

// A `link:` name on the SDK recipe, found as clang's MinGW driver finds `-l`
// (lld MinGW's search order): lib<name>.a, <name>.lib, lib<name>.lib,
// <name>.a in each search path, the extras' -L paths first, then the SDK's
// libc. A library `with get` builds from source on Windows is a GNU-named
// archive (libbz2.a), so `bz2` names it (#1915). A name found nowhere stays
// `<name>.lib`, and lld says it could not open it.
fn link_stage_windows_find_lib(name: &str, libc_dir: &str, extras: &Vec[str]) -> str:
    var dirs: Vec[str] = Vec.new()
    for i in 0..extras.len() as i32:
        if extras[i].starts_with("-L"):
            dirs.push(extras[i].slice(2, extras[i].len()))
    dirs.push(with_str_clone_ref(libc_dir))
    for d in dirs:
        for candidate in ["lib" ++ name ++ ".a", name ++ ".lib", "lib" ++ name ++ ".lib", name ++ ".a"]:
            let path = d ++ "/" ++ candidate
            if link_stage_file_exists(path):
                return path
    name ++ ".lib"

fn link_stage_make_windows_llvm_link_command(llvm_ld: &str, sdk_dir: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    let compiler_link = link_stage_windows_is_compiler_link(extras)
    let arch = link_stage_windows_arch()
    // The SDK recipe covers x86_64; windows-aarch64 programs keep the
    // Visual Studio recipe until its libc slice lands (#1915).
    let sdk_is_gnu = link_stage_file_exists(sdk_dir ++ "/lib/libclang.a")
    let sdk_libc = arch == "x86_64" and (not compiler_link or sdk_is_gnu)
    let libc_dir = if sdk_libc: link_stage_windows_libc_dir(sdk_dir, arch) else: ""
    let builtins = if sdk_libc: link_stage_windows_builtins(sdk_dir, arch) else: ""
    if sdk_libc:
        if not link_stage_file_exists(libc_dir ++ "/crt2.o"):
            with_eprint("error: the LLVM SDK at " ++ sdk_dir ++ " carries no Windows C runtime (" ++ libc_dir ++ "/crt2.o); a Windows link reads the SDK only (#1915). Install an SDK built with `with build :sdk-windows-libc` (or name one with WITH_WINDOWS_LIBC_DIR).")
            return link_stage_empty_command()
        if not link_stage_file_exists(builtins):
            with_eprint("error: the LLVM SDK at " ++ sdk_dir ++ " carries no compiler-rt builtins for Windows (" ++ builtins ++ "); build them with `with build :sdk-compiler-rt-builtins` (#1915).")
            return link_stage_empty_command()
    args.push("/nologo")
    // Reproducible PE output: lld-link derives the header timestamp and the
    // PDB GUID from a hash of the image instead of the wall clock, so
    // relinking the same inputs yields the same bytes. Without it every
    // relink of the release compiler differed, and the seed-driven gates
    // (which relink per step) declared the test-pass marker stale on
    // Windows only: fixpoint compares emitted objects, never the linked
    // image, so the churn was invisible there.
    args.push("/Brepro")
    args.push("/subsystem:console")
    args.push("/debug")
    args.push("/pdb:" ++ bin_path ++ ".pdb")
    args.push("/stack:8388608")
    args.push("/opt:ref")
    args.push("/opt:icf")
    if link_stage_verbose():
        args.push("/verbose")
    if sdk_libc:
        // mingw-w64's startup code (crt2.o) is the entry point, and it reads
        // what lld synthesizes only in MinGW mode: the __CTOR_LIST__ /
        // __DTOR_LIST__ bounds and the runtime pseudo-relocation list.
        args.push("-lldmingw")
        args.push("/entry:mainCRTStartup")
        args.push("/libpath:" ++ libc_dir)
    else:
        // The compiler's own link (and windows-aarch64): Visual Studio's
        // import libraries and CRT, from WITH_WINDOWS_*_LIBDIR.
        args.push("/libpath:" ++ link_stage_windows_libpath("WITH_WINDOWS_UM_LIBDIR", "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64"))
        args.push("/libpath:" ++ link_stage_windows_libpath("WITH_WINDOWS_UCRT_LIBDIR", "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64"))
        args.push("/libpath:" ++ link_stage_windows_libpath("WITH_WINDOWS_MSVC_LIBDIR", "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/lib/x64"))
    args.push("/out:" ++ bin_path)
    outputs.push(with_str_clone_ref(bin_path))
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras[i]
        if extra.starts_with("-L"):
            args.push("/libpath:" ++ extra.slice(2, extra.len()))
        else if extra.starts_with("@"):
            args.push(with_str_clone_ref(extra))
        else:
            args.push(with_str_clone_ref(extra))
            inputs.push(with_str_clone_ref(extra))
    for i in 0..link_libs.len() as i32:
        let lib = link_libs[i]
        if lib.ends_with(".lib"):
            args.push(with_str_clone_ref(lib))
        else if not link_stage_windows_lib_is_crt_implicit(lib):
            args.push(if sdk_libc: link_stage_windows_find_lib(lib, libc_dir, extras) else: lib ++ ".lib")
        // else: `m` (libm) and `c` (libc) are Unix-only spellings — Windows has
        // no `m.lib`/`c.lib`, and their symbols (cos, abs, strlen, …) resolve
        // from the C runtime already linked below. Emitting a bare
        // `<name>.lib` would make lld-link fail to open a nonexistent import
        // lib, so drop it. Any other name still becomes `<name>.lib` so a
        // genuinely missing library fails loudly rather than silently
        // vanishing: an application's own libraries (opengl32, gdi32, ...)
        // come from `with get` or its own link settings, never the SDK.
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args[i]))
    if sdk_libc:
        // The C runtime: mingw-w64's UCRT startup and support code, compiler-rt's
        // builtins under it, and the UCRT itself (ucrtbase and the
        // api-ms-win-crt-* API sets, in the box since Windows 10). No
        // vcruntime140 or msvcp140: those are redistributables.
        args.push(libc_dir ++ "/crt2.o")
        inputs.push(libc_dir ++ "/crt2.o")
        args.push("mingw32.lib")
        args.push(with_str_clone_ref(builtins))
        inputs.push(with_str_clone_ref(builtins))
        args.push("mingwex.lib")
        args.push("ucrt.lib")
        let system = link_stage_windows_system_libs()
        for i in 0..system.len() as i32:
            args.push(with_str_clone_ref(system[i]))
    else:
        // Visual Studio's C runtime: static for the compiler (its LLVM
        // archives are MultiThreaded), the DLL runtime otherwise.
        if compiler_link:
            args.push("libcpmt.lib")
            args.push("libcmt.lib")
        else:
            args.push("msvcprt.lib")
            args.push("msvcrt.lib")
            args.push("ucrt.lib")
            args.push("vcruntime.lib")
        // UCRT exports printf/scanf-family functions such as sprintf and
        // vfprintf only through this archive (they are inline in the headers
        // since VS 2015); Darwin-migrated C (pcre2test.w) calls them by name.
        args.push("legacy_stdio_definitions.lib")
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

// The lld flavor for a WebAssembly link: wasm-ld ships beside the host
// flavor recorded in the llvm_ld metadata.
fn link_stage_wasm_lld_for(llvm_ld: &str) -> str:
    let name = if runtime_sysinfo_os() == "Windows": "wasm-ld.exe" else: "wasm-ld"
    if link_stage_basename(llvm_ld) == name:
        return llvm_ld ++ ""
    let sibling = link_stage_dirname(llvm_ld) ++ "/" ++ name
    if link_stage_file_exists(sibling):
        return sibling
    ""

// The shadow stack a wasm program gets. wasm-ld's 64 KiB default is far
// below what With code with page-sized stack buffers needs; 8 MiB matches
// the native targets' main-thread stack. WITH_WASM_STACK_SIZE overrides.
fn link_stage_wasm_stack_size() -> str:
    let env = with_getenv_str("WITH_WASM_STACK_SIZE")
    if env.len() > 0:
        return env
    "8388608"

fn link_stage_make_wasm_llvm_link_command(wasm_ld: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStageCommand:
    let args: Vec[str] = Vec.new()
    let env: Vec[LinkStageEnvVar] = Vec.new()
    let inputs: Vec[str] = Vec.new()
    let outputs: Vec[str] = Vec.new()
    if target_spec_active_kind() == 8:
        args.push("-mwasm64")
    // rt/wasm.w's with_wasm_startup/with_wasm_exit bracket codegen's
    // `_start`; the stack goes first so an overflow traps on the guard
    // below it instead of silently overwriting data.
    args.push("--entry=_start")
    args.push("--stack-first")
    // A wasm-ld warning is a real defect: a function-signature mismatch
    // between objects would otherwise link into a stub that traps at the
    // first call. Fail the link instead.
    args.push("--fatal-warnings")
    args.push("-z")
    args.push("stack-size=" ++ link_stage_wasm_stack_size())
    args.push("-o")
    args.push(with_str_clone_ref(bin_path))
    outputs.push(with_str_clone_ref(bin_path))
    args.push(with_str_clone_ref(obj_path))
    inputs.push(with_str_clone_ref(obj_path))
    for i in 0..extras.len() as i32:
        let extra = extras[i]
        if extra.starts_with("-L") or extra.starts_with("@"):
            args.push(with_str_clone_ref(extra))
        else:
            args.push(with_str_clone_ref(extra))
            inputs.push(with_str_clone_ref(extra))
    for i in 0..link_libs.len() as i32:
        // There is no libc or libm on this target; a request for one is a
        // no-op, anything else must resolve as a wasm archive or fail loudly.
        let lib = link_libs[i]
        if lib != "m" and lib != "c":
            args.push("-l" ++ lib)
    for i in 0..link_args.len() as i32:
        args.push(with_str_clone_ref(link_args[i]))
    if wasm_host_emit(bin_path) != 0:
        return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
    outputs.push(wasm_host_js_path(bin_path))
    let cleanup_files = link_stage_collect_cleanup_files(extras)
    LinkStageCommand { linker: with_str_clone_ref(wasm_ld), args, cwd: "", env, inputs, outputs, cleanup_files }

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
        if target_spec_active_kind() == 5 or target_spec_active_kind() == 6:
            let coff_ld = link_stage_coff_lld_for(llvm_ld)
            if coff_ld.len() == 0:
                with_eprint("error: cross link needs the COFF lld driver (lld-link) next to " ++ llvm_ld)
                return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
            return link_stage_make_windows_llvm_link_command(coff_ld, link_stage_sdk_dir_of(coff_ld), obj_path, bin_path, extras, link_libs, link_args)
        if target_spec_is_wasm():
            let wasm_ld = link_stage_wasm_lld_for(llvm_ld)
            if wasm_ld.len() == 0:
                with_eprint("error: cross link needs the WebAssembly lld driver (wasm-ld) next to " ++ llvm_ld)
                return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
            return link_stage_make_wasm_llvm_link_command(wasm_ld, obj_path, bin_path, extras, link_libs, link_args)
        with_eprint("error: unsupported cross link target: " ++ target_spec_name())
        return LinkStageCommand { linker: "", args: Vec.new(), cwd: "", env: Vec.new(), inputs: Vec.new(), outputs: Vec.new(), cleanup_files: Vec.new() }
    let os = runtime_sysinfo_os()
    let arch = runtime_sysinfo_arch()
    if os == "Linux" and arch == "x86_64":
        return link_stage_make_linux_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if os == "Linux" and arch == "aarch64":
        return link_stage_make_linux_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if os == "Macos" and arch == "aarch64":
        return link_stage_make_darwin_llvm_link_command(llvm_ld, obj_path, bin_path, extras, link_libs, link_args)
    if os == "Windows" and arch == "x86_64":
        return link_stage_make_windows_llvm_link_command(llvm_ld, link_stage_sdk_dir_of(llvm_ld), obj_path, bin_path, extras, link_libs, link_args)
    if os == "Windows" and (arch == "armv8" or arch == "aarch64"):
        return link_stage_make_windows_llvm_link_command(llvm_ld, link_stage_sdk_dir_of(llvm_ld), obj_path, bin_path, extras, link_libs, link_args)
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
    if name == "rt_linux_aarch64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_linux_aarch64_o_start as *const u8, &with_embedded_rt_linux_aarch64_o_end as *const u8)
    if name == "rt_linux_x86_64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_linux_x86_64_o_start as *const u8, &with_embedded_rt_linux_x86_64_o_end as *const u8)
    if name == "rt_windows_x86_64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_windows_x86_64_o_start as *const u8, &with_embedded_rt_windows_x86_64_o_end as *const u8)
    if name == "rt_windows_aarch64.o":
        return link_stage_embedded_obj_slice(&with_embedded_rt_windows_aarch64_o_start as *const u8, &with_embedded_rt_windows_aarch64_o_end as *const u8)
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
        var ld_path = link_stage_read_file_trimmed(root ++ "/llvm_ld")
        // The `llvm_ld` metadata file only records the lld-link path; the lib
        // dirs and system libs come from the environment already
        // (link_stage_make_windows_llvm_link_command). So a NATIVE Windows
        // link that runs before the metadata target has written the file — a
        // .wo bundle build's --emit-obj link is the case (#1075) — resolves
        // the linker the same way the metadata target does
        // (build/compiler.w comp_llvm_lld_tool): WITH_LLVM_LD, then LLVM_LD,
        // then LLVM_PREFIX/bin/lld-link.exe. A cross link still requires the
        // generated metadata (it also carries the cross SDK's lib response).
        if ld_path.len() == 0 and runtime_sysinfo_os() == "Windows" and target_spec_is_native():
            ld_path = link_stage_windows_lld_from_env()
        // #1915 (D81): with no SDK named, a native Windows link is this
        // binary's own lld over the toolchain it carries, as a macOS link is.
        if ld_path.len() == 0 and runtime_sysinfo_os() == "Windows" and target_spec_is_native() and lld_flavor_linked("coff"):
            let carried = embedded_windows_sysroot_dir()
            if carried.len() > 0:
                return link_stage_windows_native_link_plan(carried, obj_path, bin_path, extras, link_libs, link_args)
        if ld_path.len() == 0:
            if runtime_sysinfo_os() == "Windows":
                with_eprint("error: missing Windows LLVM linker metadata (" ++ root ++ "/llvm_ld), no WITH_LLVM_LD / LLVM_LD / LLVM_PREFIX in the environment, and this compiler carries no Windows linker and C runtime of its own (one cross-linked from another host, or linked against a Visual Studio-built SDK): extract the with-llvm-sdk-<version>-windows-x86_64.tar.gz release asset sdk.lock pins and set LLVM_PREFIX to its llvm-<version>-windows-x86_64-msvc directory")
            else:
                with_eprint("error: cross-target link requires LLVM linker metadata (" ++ root ++ "/llvm_ld)")
            return link_stage_plan_fail()
        return link_stage_link_with_llvm_args_plan(obj_path, bin_path, extras, link_libs, link_args, ld_path)
    if runtime_sysinfo_os() == "Macos":
        return link_stage_darwin_native_link_plan(obj_path, bin_path, extras, link_libs, link_args)
    if link_stage_linux_uses_own_sysroot():
        return link_stage_linux_native_link_plan(obj_path, bin_path, extras, link_libs, link_args)
    let command = link_stage_make_link_command("cc", obj_path, bin_path, extras, link_libs, link_args)
    link_stage_plan_for_command(move command)

// #1915 (D81): a native Windows link with no SDK named is this binary's own
// lld-link (`with __ld -flavor link`, src/compiler/LldDriver.w) over the
// Windows toolchain it carries (compiler.EmbeddedSysroot), read exactly as
// an SDK's: no Visual Studio, no Windows Kits, no LLVM install.
fn link_stage_windows_native_link_plan(toolchain: &str, obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStagePlan:
    let self_exe = with_self_exe()
    if self_exe.len() == 0:
        with_eprint("error: link: cannot find this compiler's own executable to run its linker (argv[0] is '" ++ runtime_arg_at(0) ++ "')")
        return link_stage_plan_fail()
    var command = link_stage_make_windows_llvm_link_command("lld-link", toolchain, obj_path, bin_path, extras, link_libs, link_args)
    if command.linker.len() == 0:
        return link_stage_plan_fail()
    let args: Vec[str] = Vec.new()
    args.push("__ld")
    args.push("-flavor")
    args.push("link")
    for i in 0..command.args.len() as i32:
        args.push(with_str_clone_ref(command.args[i]))
    command.args = args
    command.linker = with_str_clone_ref(self_exe)
    link_stage_plan_for_command(move command)

// #1915: a native macOS link is this binary's own lld (`with __ld`, src/
// compiler/LldDriver.w) over the darwin sysroot (compiler.EmbeddedSysroot):
// no cc, no ld, no Xcode or Command Line Tools, no Apple SDK. A framework is
// found only on the -F paths the program's dependencies give; lld names the
// one it cannot find.
fn link_stage_darwin_native_link_plan(obj_path: &str, bin_path: &str, extras: &Vec[str], link_libs: &Vec[str], link_args: &Vec[str]) -> LinkStagePlan:
    let self_exe = with_self_exe()
    if self_exe.len() == 0:
        with_eprint("error: link: cannot find this compiler's own executable to run its linker (argv[0] is '" ++ runtime_arg_at(0) ++ "')")
        return link_stage_plan_fail()
    let sysroot = darwin_sdk_root()
    if sysroot.len() == 0:
        with_eprint("error: link: no darwin sysroot: this compiler carries none, and WITH_SDKROOT / SDKROOT name none")
        return link_stage_plan_fail()
    var command = link_stage_make_darwin_llvm_link_command(self_exe, obj_path, bin_path, extras, link_libs, link_args)
    let args: Vec[str] = Vec.new()
    args.push("__ld")
    args.push("-syslibroot")
    args.push(sysroot)
    for i in 0..command.args.len() as i32:
        args.push(with_str_clone_ref(command.args[i]))
    command.args = args
    link_stage_plan_for_command(move command)

// A program's link arguments are written for a C compiler driver (`cc`), as
// they were when the native link ran through one: `-Wl,a,b` hands `a` and `b`
// to the linker. The native macOS link is lld itself now (#1915), so the
// driver's wrapper is unwrapped here; every other argument passes as written
// and lld names one it does not know.
pub fn link_stage_driver_args_for_ld(link_args: &Vec[str]) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var i = 0
    while i < link_args.len() as i32:
        let arg = link_args[i]
        if arg == "-Xlinker" and i + 1 < link_args.len() as i32:
            i += 1
            out.push(link_args[i].clone())
        else if arg.starts_with("-Wl,"):
            for part in arg.slice(4, arg.len()).split(","):
                if part.len() > 0: out.push(part.clone())
        else:
            out.push(with_str_clone_ref(arg))
        i += 1
    out

// Separate argv entries protect spaces, commas, dollar signs and loader
// tokens. The command runs directly, so no shell ever expands these values.
// Windows loads beside the executable itself; wasm has no dynamic loader.
pub fn link_stage_rpath_driver_args(paths: &Vec[str], target_os: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    if target_os != "Linux" and target_os != "Macos": return out
    for path in paths:
        out.push("-Xlinker")
        out.push("-rpath")
        out.push("-Xlinker")
        out.push(path.clone())
    out

// The native-Windows lld-link path, resolved from the environment when the
// generated `llvm_ld` metadata file is not present yet (#1075). Mirrors
// build/compiler.w's comp_llvm_lld_tool exactly so a pre-metadata link picks
// the same linker the metadata target would have recorded.
fn link_stage_windows_lld_from_env() -> str:
    let explicit = runtime_getenv("WITH_LLVM_LD")
    if explicit.len() > 0:
        return explicit ++ ""
    let alt = runtime_getenv("LLVM_LD")
    if alt.len() > 0:
        return alt ++ ""
    let prefix = runtime_getenv("LLVM_PREFIX")
    if prefix.len() > 0:
        return prefix ++ "/bin/lld-link.exe"
    ""

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
            if hay[(i + j)] != needle[j]:
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

// #1915: `nm -u` for a 64-bit Mach-O object, read here rather than from a
// host `nm`: each undefined external symbol of LC_SYMTAB, one per line, as
// nm prints them (with Mach-O's leading underscore). "<probe-failed>" when
// the file is not a 64-bit little-endian Mach-O object this can read.
pub fn link_stage_macho_undefined_symbols(path: &str) -> str:
    let data = runtime_read_file(path)
    if data.len() < 32 or link_stage_read_u32_le(data, 0) != 0xfeedfacf:
        return "<probe-failed>"
    let size = data.len() as i32
    let ncmds = link_stage_read_u32_le(data, 16) as i32
    var offset = 32
    for _ in 0..ncmds:
        if offset + 8 > size:
            return "<probe-failed>"
        let cmd = link_stage_read_u32_le(data, offset)
        let cmdsize = link_stage_read_u32_le(data, offset + 4) as i32
        if cmdsize < 8 or offset + cmdsize > size:
            return "<probe-failed>"
        // LC_SYMTAB: symoff, nsyms, stroff, strsize.
        if cmd == 0x2 and cmdsize >= 24:
            let symoff = link_stage_read_u32_le(data, offset + 8) as i32
            let nsyms = link_stage_read_u32_le(data, offset + 12) as i32
            let stroff = link_stage_read_u32_le(data, offset + 16) as i32
            let strsize = link_stage_read_u32_le(data, offset + 20) as i32
            if symoff + nsyms * 16 > size or stroff + strsize > size:
                return "<probe-failed>"
            var out = StringBuilder.new()
            for s in 0..nsyms:
                // nlist_64: n_strx u32, n_type u8, n_sect u8, n_desc u16, n_value u64.
                let entry = symoff + s * 16
                let n_type = data[(entry + 4)] as i32
                let n_value = link_stage_read_u32_le(data, entry + 8) + link_stage_read_u32_le(data, entry + 12)
                // External (N_EXT), not a debugging entry (N_STAB), N_UNDF,
                // and not a common symbol (an undefined one with a size).
                if (n_type & 0xe0) == 0 and (n_type & 0x01) != 0 and (n_type & 0x0e) == 0 and n_value == 0:
                    let strx = link_stage_read_u32_le(data, entry) as i32
                    if strx <= 0 or strx >= strsize:
                        return "<probe-failed>"
                    var end = stroff + strx
                    while end < stroff + strsize and data[end] != 0:
                        end = end + 1
                    out.push_str(data.slice((stroff + strx) as i64, end as i64))
                    out.push_str("\n")
            return out.to_str()
        offset = offset + cmdsize
    ""

fn link_stage_read_u16_le(data: &str, offset: i64) -> i64:
    if offset < 0 or offset + 1 >= data.len():
        return -1
    (data[offset] as i64) | ((data[offset + 1] as i64) << 8)

// The external symbols a COFF object (regular or /bigobj) references and does
// not define, one per line: storage class EXTERNAL, section 0, value 0 (a
// nonzero value is a common symbol). "<probe-failed>" when it is not one.
pub fn link_stage_coff_undefined_symbols(path: &str) -> str:
    let data = runtime_read_file(path)
    if data.len() < 20:
        return "<probe-failed>"
    let bigobj = link_stage_read_u16_le(data, 0) == 0 and link_stage_read_u16_le(data, 2) == 0xffff
    let symtab = if bigobj: link_stage_read_u32_le(data, 48) else: link_stage_read_u32_le(data, 8)
    let count = if bigobj: link_stage_read_u32_le(data, 52) else: link_stage_read_u32_le(data, 12)
    let entry_size: i64 = if bigobj: 20 else: 18
    if symtab <= 0 or count < 0 or symtab + count * entry_size + 4 > data.len():
        return "<probe-failed>"
    let strtab = symtab + count * entry_size
    var out = StringBuilder.new()
    var i: i64 = 0
    while i < count:
        let at = symtab + i * entry_size
        let section = if bigobj: link_stage_read_u32_le(data, (at + 12) as i32) else: link_stage_read_u16_le(data, at + 12)
        let class = data[at + entry_size - 2] as i32
        let aux = data[at + entry_size - 1] as i64
        let value = link_stage_read_u32_le(data, (at + 8) as i32)
        if class == 2 and section == 0 and value == 0:
            var name = ""
            if link_stage_read_u32_le(data, at as i32) == 0:
                var start = strtab + link_stage_read_u32_le(data, (at + 4) as i32)
                var end = start
                while end < data.len() and data[end] != 0:
                    end = end + 1
                name = data.slice(start, end)
            else:
                var end = at
                while end < at + 8 and data[end] != 0:
                    end = end + 1
                name = data.slice(at, end)
            if name.len() > 0:
                out.push_str(name)
                out.push_str("\n")
        i = i + 1 + aux
    out.to_str()

fn link_stage_undefined_symbols_for_object(obj_path: &str) -> str:
    // A native macOS object is read in-process: no host nm (#1915).
    if runtime_sysinfo_os() == "Macos" and target_spec_is_native():
        let symbols = link_stage_macho_undefined_symbols(obj_path)
        if symbols == "<probe-failed>":
            with_eprint(f"warning: link: {obj_path} is not a 64-bit Mach-O object this compiler can read for undefined symbols; linking every embedded bundle\n")
        return symbols
    // So is a native Windows one (#1915, D81): no llvm-nm, the SDK's or
    // the host's.
    if runtime_sysinfo_os() == "Windows" and target_spec_is_native():
        let symbols = link_stage_coff_undefined_symbols(obj_path)
        if symbols == "<probe-failed>":
            with_eprint(f"warning: link: {obj_path} is not a COFF object this compiler can read for undefined symbols; linking every embedded bundle\n")
        return symbols
    let report_path = obj_path ++ ".undef"
    let null_path = if runtime_sysinfo_os() == "Windows": "NUL" else: "/dev/null"
    var argv = ""
    var nm_tool = "nm"
    if runtime_sysinfo_os() == "Windows":
        // The SDK's llvm-nm, beside the lld this link runs (its record, or
        // the environment's SDK, as link_stage_llvm_ld_path resolves it):
        // a PATH lookup found none in a shell without the SDK on PATH, and
        // every such link carried every embedded bundle (#1915).
        let ld_path = link_stage_llvm_ld_path()
        nm_tool = if ld_path.len() > 0: link_stage_dirname(ld_path) ++ "/llvm-nm.exe" else: "llvm-nm.exe"
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
        // A failed probe links EVERY embedded bundle (link_stage_bundle_needed
        // treats it as needed): correct, but the binary carries every corpus
        // and every corpus's externs must resolve on this target — zlib's
        // fcntl on Windows (#1103). Say so, so a broken nm never hides.
        with_eprint(f"warning: link: could not probe {obj_path} for undefined symbols with '{nm_tool}' (exit {probe_rc}); linking every embedded bundle\n")
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

// ── .wo bundles (docs/spec/toolchain/wo_bundles.md, D38) ─────────────────────────────

// The value of the first manifest line `key <value>…` ("" if absent).
pub fn link_stage_bundle_manifest_field(manifest: &str, key: &str) -> str:
    let want = key ++ " "
    var start: i64 = 0
    while start < manifest.len():
        var end = start
        while end < manifest.len() and manifest[end] != '\n':
            end = end + 1
        let line = manifest.slice(start, end)
        if line.starts_with(want):
            let rest = line.slice(want.len(), line.len())
            var sp: i64 = 0
            while sp < rest.len() and rest[sp] != ' ':
                sp = sp + 1
            return rest.slice(0, sp)
        start = end + 1
    ""

// True when an undefined symbol carries one of the manifest's module prefixes.
fn link_stage_bundle_needed(manifest: &str, undef: &str) -> bool:
    if undef == "<probe-failed>":
        return true
    if undef.len() == 0:
        return false
    var start: i64 = 0
    while start < manifest.len():
        var end = start
        while end < manifest.len() and manifest[end] != '\n':
            end = end + 1
        let line = manifest.slice(start, end)
        if line.starts_with("prefix "):
            let rest = line.slice(7, line.len())
            var sp: i64 = 0
            while sp < rest.len() and rest[sp] != ' ':
                sp = sp + 1
            if sp > 0 and link_stage_str_contains(undef, rest.slice(0, sp)):
                return true
        start = end + 1
    false

// Atomic extraction of an embedded blob (the runtime-object discipline: a
// complete matching file is reused, else unique temp + rename).
fn link_stage_extract_blob(data: &str, path: &str) -> i32:
    if data.len() == 0:
        return 1
    let existing = runtime_read_file(path)
    if existing.len() == data.len() and existing == data:
        return 0
    let tmp_path = path ++ f".{runtime_getpid()}.{runtime_clock_nanos()}.tmp"
    if runtime_write_file(tmp_path, data) != 0:
        return 1
    if runtime_rename(tmp_path, path) != 0:
        let _ = runtime_remove_file(tmp_path)
        let after = runtime_read_file(path)
        if after.len() == data.len() and after == data:
            return 0
        return 1
    0

// The extracted objects of every embedded bundle the program needs, in index
// order. A needed bundle whose abi-sha or target differs from this link's,
// whose interface is not its manifest's, or that cannot be extracted, yields
// the single marker LINK_BUNDLE_FAILED (already reported) so the caller
// fails the plan.
fn LINK_BUNDLE_FAILED -> str: "<bundle-failed>"

// Module prefixes of the bundles `--link-bundle` already put on the link
// (Compilation.load_link_bundles): an embedded copy of the same modules
// must not join too.
var link_stage_explicit_bundle_prefixes: Vec[str] = Vec.new()

pub fn link_stage_add_explicit_bundle_prefixes(prefixes: &Vec[str]) -> Unit:
    for i in 0..prefixes.len() as i32:
        let prefix = prefixes[i]
        if not link_stage_explicit_bundle_prefixes.contains(prefix):
            link_stage_explicit_bundle_prefixes.push(with_str_clone_ref(prefix))

fn link_stage_bundle_provided_explicitly(manifest: &str) -> bool:
    let prefixes = bundle_manifest_prefixes(manifest)
    if prefixes.len() == 0:
        return false
    for i in 0..prefixes.len() as i32:
        if not link_stage_explicit_bundle_prefixes.contains(prefixes[i]):
            return false
    true

fn link_stage_select_embedded_bundles(undef: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let count = embedded_bundle_count()
    if count == 0:
        return out
    let tmp_dir = link_stage_artifact_root() ++ "/tmp/with_runtime"
    for bi in 0..count:
        if not embedded_bundle_present(bi):
            continue
        let manifest = link_stage_embedded_obj_slice(embedded_bundle_manifest_start(bi) as *const u8, embedded_bundle_manifest_end(bi) as *const u8)
        if link_stage_bundle_provided_explicitly(manifest) or not link_stage_bundle_needed(manifest, undef):
            continue
        let name = embedded_bundle_name(bi)
        let bundle_abi = link_stage_bundle_manifest_field(manifest, "abi-sha")
        if abi_identity_refuses_bundle(compiler_abi_sha(), bundle_abi):
            with_eprint("error: embedded bundle '" ++ name ++ "' was built for ABI " ++ bundle_abi ++ " but this compiler is " ++ compiler_abi_sha() ++ " (a .wo never links across ABI identities; rebuild the bundle)")
            let failed: Vec[str] = Vec.new()
            failed.push(LINK_BUNDLE_FAILED())
            return failed
        // A bundle is compiled for one platform; a cross link of a program
        // that needs it has no bundle for its target (§18.5: never link
        // native output into a cross binary).
        let bundle_target = link_stage_bundle_manifest_field(manifest, "target")
        if bundle_target != target_spec_resolved_name():
            with_eprint("error: embedded bundle '" ++ name ++ "' was built for target " ++ bundle_target ++ " but this link targets " ++ target_spec_resolved_name() ++ " (this compiler embeds no " ++ name ++ " bundle for that target)")
            let failed: Vec[str] = Vec.new()
            failed.push(LINK_BUNDLE_FAILED())
            return failed
        // D39 pairing: the embedded interface is the one the object was
        // built with, or the binary's embedded bundles are corrupt.
        let manifest_wi_sha = link_stage_bundle_manifest_field(manifest, "interface-sha")
        let embedded_wi_sha = bundle_text_sha256(embedded_bundle_interface_text(bi))
        if manifest_wi_sha.len() == 0 or embedded_wi_sha != manifest_wi_sha:
            with_eprint("error: embedded bundle '" ++ name ++ "': its interface (sha256 " ++ embedded_wi_sha ++ ") is not the one its manifest was built with (" ++ manifest_wi_sha ++ "); this compiler's embedded bundles are corrupt")
            let failed: Vec[str] = Vec.new()
            failed.push(LINK_BUNDLE_FAILED())
            return failed
        let obj_path = tmp_dir ++ "/wo_" ++ name ++ ".o"
        let data = link_stage_embedded_obj_slice(embedded_bundle_object_start(bi) as *const u8, embedded_bundle_object_end(bi) as *const u8)
        if runtime_mkdir_p(tmp_dir) != 0 or link_stage_extract_blob(data, obj_path) != 0:
            with_eprint("error: could not extract embedded bundle '" ++ name ++ "' to " ++ obj_path)
            let failed: Vec[str] = Vec.new()
            failed.push(LINK_BUNDLE_FAILED())
            return failed
        out.push(obj_path)
    out

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

// D30, #1815: a link takes runtime and bridge objects of this compiler's
// generation only (compiler.AbiStamp). Anything else is #761's corruption
// class: the seed-built runtime linked into stage1-compiled stage2 passed
// every check because the build's WITH_OUT_DIR used to vouch for out/lib and
// out/bootstrap-lib whoever had built them. The build now names the root a
// stage link must use (WITH_RUNTIME_ROOT) and every object set it compiles
// records its producer's generation in `<dir>/.producer`, so the say-so is
// checked, not trusted. "" when the build's root is not this generation's:
// the link fails (link_stage_find_runtime_object_path says why) and never
// falls back to another directory or to the embedded objects.
fn link_stage_resolve_runtime_root() -> str:
    let explicit = runtime_getenv("WITH_RUNTIME_ROOT") ++ ""
    if explicit.len() > 0:
        if compiler_generation_is_stamped() and link_stage_runtime_dir_producer(explicit) != compiler_generation():
            return ""
        return explicit
    let argv0 = runtime_arg_at(0)
    let compiler_dir = if argv0.len() > 0: link_stage_dirname(argv0) else: "."
    let platform_object = link_stage_host_platform_runtime_object()
    let candidates: Vec[str] = Vec.new()
    candidates.push(link_stage_artifact_root() ++ "/lib")
    // Seed-built bootstrap runtime: the seed's generation, so only a seed
    // (the build's driver) takes it.
    candidates.push(link_stage_artifact_root() ++ "/bootstrap-lib")
    // <compiler_dir>/runtime/ (symlink to ../lib in out/bin/)
    candidates.push(compiler_dir ++ "/runtime")
    // <compiler_dir>/../lib/ (direct FHS-style path): out/bootstrap/lib is
    // the runtime stage1 compiles for the programs it links (`:dev`).
    candidates.push(compiler_dir ++ "/../lib")
    for i in 0..candidates.len() as i32:
        let dir = candidates[i]
        let probe = dir ++ "/cimport_stubs.o"
        let platform_probe = if platform_object.len() > 0: dir ++ "/" ++ platform_object else: ""
        if runtime_read_file(probe).len() == 0 or (platform_probe.len() > 0 and runtime_read_file(platform_probe).len() == 0):
            continue
        if link_stage_runtime_dir_is_this_generation(dir):
            return with_str_clone_ref(dir)
    // Fall back to compiler-relative runtime dir.
    compiler_dir ++ "/runtime"

// The generation that compiled a runtime object set, as the build recorded it
// (build/compiler.w run_write_runtime_producer_action); "" when none is.
fn link_stage_runtime_dir_producer(dir: &str) -> str:
    link_stage_read_file_trimmed(dir ++ "/.producer")

// A directory is this compiler's runtime when its .producer names this
// compiler's generation. One without a .producer (written before #1815, or
// by hand) is a cache of the embedded runtime, and a cache hit is byte for
// byte — which vouches for it only when the embedded runtime is itself this
// generation's: stage1 embeds the seed's.
pub fn link_stage_runtime_dir_is_this_generation(dir: &str) -> bool:
    if compiler_generation_is_stamped():
        let producer = link_stage_runtime_dir_producer(dir)
        if producer.len() > 0:
            return producer == compiler_generation()
        if not link_stage_embedded_runtime_is_this_generation():
            return false
    let embedded = link_stage_embedded_runtime_object("rt_core.o")
    // A binary that carries no runtime can only link from disk.
    if embedded.len() == 0:
        return true
    let on_disk = runtime_read_file(dir ++ "/rt_core.o")
    on_disk.len() == embedded.len() and on_disk == embedded

// A root whose .producer names another generation: the fallback root
// (compiler_dir/runtime) is returned without passing the candidate check.
fn link_stage_runtime_root_is_foreign(root: &str) -> bool:
    if not compiler_generation_is_stamped():
        return false
    let producer = link_stage_runtime_dir_producer(root)
    producer.len() > 0 and producer != compiler_generation()

fn link_stage_embedded_runtime_is_this_generation() -> bool:
    not compiler_generation_is_stamped() or compiler_runtime_generation() == compiler_generation()

// Why a link has no runtime root of this compiler's generation (#1815).
fn link_stage_runtime_generation_refusal() -> str:
    let explicit = runtime_getenv("WITH_RUNTIME_ROOT") ++ ""
    if explicit.len() > 0:
        let producer = link_stage_runtime_dir_producer(explicit)
        let recorded = if producer.len() > 0: producer else: "none recorded (no .producer)"
        return "error: WITH_RUNTIME_ROOT=" ++ explicit ++ " holds runtime objects of compiler generation " ++ recorded ++ ", but this compiler is generation " ++ compiler_generation() ++ "; linking them would mix compiler generations (D30, #1815). Compile that root with this compiler."
    "error: no runtime objects of this compiler's generation (" ++ compiler_generation() ++ ") to link: its embedded runtime is generation " ++ compiler_runtime_generation() ++ " (a stage1 carries the seed's) and no runtime directory holds this generation's; run `with build :dev`, which compiles out/bootstrap/lib with stage1 (D30, #1815)"

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
    // The bridges' wl_* functions are this generation's ABI too (#1815).
    if root.len() == 0 or link_stage_runtime_root_is_foreign(root):
        return ""
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
        let b = content[(end - 1)]
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
    if root.len() == 0:
        with_eprint(link_stage_runtime_generation_refusal())
        return ""
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
    // The fallback root (compiler_dir/runtime) was not a candidate that
    // passed: a .producer naming another generation keeps its objects out.
    if not link_stage_runtime_root_is_foreign(root) and runtime_read_file(p).len() > 0:
        return p
    // Fall back to embedded runtime objects (self-contained binary) — when
    // they are this compiler's generation (#1815).
    if not link_stage_embedded_runtime_is_this_generation():
        with_eprint(link_stage_runtime_generation_refusal())
        return ""
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
        if target_spec_active_kind() == 6:
            return "rt_windows_aarch64.o"
        if target_spec_is_wasm():
            return "rt_wasm.o"
        with_eprint("error: unsupported cross runtime platform: " ++ target_spec_name())
        return ""
    link_stage_host_platform_runtime_object()

fn link_stage_host_platform_runtime_object() -> str:
    let os = runtime_sysinfo_os()
    let arch = runtime_sysinfo_arch()
    if os == "Linux" and arch == "x86_64":
        return "rt_linux_x86_64.o"
    if os == "Linux" and arch == "aarch64":
        // No embedded slot yet — resolved from the on-disk runtime root
        // only (see link_stage_embedded_runtime_object).
        return "rt_linux_aarch64.o"
    if os == "Macos" and arch == "aarch64":
        return "rt_darwin_aarch64.o"
    if os == "Windows" and arch == "x86_64":
        return "rt_windows_x86_64.o"
    if os == "Windows" and arch == "aarch64":
        return "rt_windows_aarch64.o"
    with_eprint("error: unsupported host runtime platform: " ++ os ++ "/" ++ arch)
    ""

fn link_stage_make_archive(obj_path: &str) -> str:
    // wasm-ld resolves plain objects; the runtime objects carry no
    // overlapping definitions, so nothing needs archive semantics there.
    if runtime_sysinfo_os() == "Windows" or target_spec_active_kind() == 5 or target_spec_active_kind() == 6 or target_spec_is_wasm():
        return with_str_clone_ref(obj_path)
    // Wrap a .o file in a .a archive so the linker treats it as a library
    // (only pulling in symbols that aren't already defined).
    let ar_path = obj_path ++ f".{runtime_getpid()}.{runtime_clock_nanos()}.a"
    let out = link_stage_make_archive_to_path(obj_path, ar_path)
    if out.len() > 0:
        link_stage_register_temp_archive(out)
    out

pub fn link_stage_make_archive_to_path(obj_path: &str, ar_path: &str) -> str:
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

pub fn link_stage_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47 or path[i] == 92: // '/' or '\'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

pub fn link_stage_source_stem(source_path: &str) -> str:
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
        let ch = if at_end: 47 else: path[i]
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

pub fn link_stage_output_dir_for_source(source_path: &str) -> str:
    let artifact_root = link_stage_artifact_root()
    let dir = link_stage_sanitize_relative_dir(link_stage_dirname(source_path))
    if dir.len() == 0:
        return artifact_root
    artifact_root ++ "/" ++ dir

pub fn link_stage_output_path_for_source(source_path: &str) -> str:
    let base = link_stage_output_dir_for_source(source_path) ++ "/" ++ link_stage_source_stem(source_path)
    if target_spec_is_wasm():
        return base ++ ".wasm"
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

pub fn link_stage_link_object_to_binary_plan_with_units(obj_path: &str, extra_objects: &Vec[str], bin_path: &str, link_libs: Vec[str], link_search_paths: &Vec[str], link_args: Vec[str], needs_async_runtime: bool) -> LinkStagePlan:
    let extras: Vec[str] = Vec.new()
    // #650 codegen units: sibling .o files are full linker inputs like the
    // primary object (objects always load wholly, so position is irrelevant).
    for ui in 0..extra_objects.len() as i32:
        extras.push(with_str_clone_ref(extra_objects[ui]))
    for i in 0..link_search_paths.len() as i32:
        extras.push("-L" ++ link_search_paths[i])
    var undef = link_stage_undefined_symbols_for_object(obj_path)
    // Runtime-need detection must see undefined symbols from every unit, not
    // just the primary object. A failed probe stays the pure sentinel so the
    // conservative "<probe-failed>" equality checks keep firing.
    for uu in 0..extra_objects.len() as i32:
        if undef == "<probe-failed>":
            break
        let unit_undef = link_stage_undefined_symbols_for_object(extra_objects[uu])
        if unit_undef == "<probe-failed>":
            undef = "<probe-failed>"
        else:
            undef = undef ++ unit_undef
    var needs_fiber_runtime = if needs_async_runtime: 1 else: link_stage_undefined_symbols_need_fiber_runtime(undef)
    let needs_compat_runtime = link_stage_undefined_symbols_need_compat_runtime(undef)
    // WebAssembly has no stack switching, so the fiber core (context-switch
    // assembly plus guard-page signal handling) cannot exist there yet. A
    // wasm program links fiber_stubs.o: it answers every lifecycle
    // reference a non-spawning program makes, and a program that really
    // spawns fails at wasm-ld with the undefined with_fiber_spawn /
    // with_channel_* symbols the core alone defines. Neither the symbol
    // probe nor the front end's requires_async_runtime can decide it
    // earlier: both fire for any unit that merely contains async bodies
    // (the prelude always does).
    if target_spec_is_wasm():
        needs_fiber_runtime = 0
    // D38: embedded .wo bundles join on demand — an undefined symbol carrying
    // one of a bundle's module prefixes selects it; its abi-sha must equal this
    // compiler's (never a silent mixed-ABI link, #761). The program's own
    // objects carry every such reference: a facade (std.regex) compiles in
    // the unit and calls the corpus by its module link names.
    let bundle_objects = link_stage_select_embedded_bundles(undef)
    if bundle_objects.len() == 1 and bundle_objects.get(0) == LINK_BUNDLE_FAILED():
        return link_stage_plan_fail()
    for boi in 0..bundle_objects.len() as i32:
        extras.push(with_str_clone_ref(bundle_objects[boi]))
    if needs_fiber_runtime != 0 and link_stage_rt_in_unit() != 0:
        // Runtime emitted in-unit: the asm-defined with_fiber_* symbols
        // still trip the predicate, but only fiber_asm.o may link — the
        // .w-derived trio would duplicate the in-unit definitions.
        let fa_path = link_stage_find_runtime_object_path("fiber_asm.o")
        if fa_path.len() == 0:
            with_eprint("error: missing runtime/fiber_asm.o")
            return link_stage_plan_fail()
        extras.push(fa_path)
    else if needs_fiber_runtime != 0:
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
        let rt_in_unit = link_stage_rt_in_unit() != 0
        // Runtime emitted in-unit with rt_core's shape (use_rt_core and
        // rt_in_unit): the program object owns every with_*/rt_* definition
        // and the bundles above are the only objects that join — no branch
        // below adds to that link.
        if use_rt_core and not rt_in_unit:
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
        else if not use_rt_core and needs_llvm:
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
        else if not use_rt_core and rt_in_unit:
            // Runtime emitted in-unit on the cc path (in-unit compat code's
            // raw libc undefs — fopen & co. — flip use_rt_core false): no
            // .w-derived rt objects; only the on-demand archive may join.
            let ricc_stubs_path = link_stage_find_runtime_object_path("cimport_stubs.o")
            if ricc_stubs_path.len() > 0:
                let ricc_stubs_ar = link_stage_make_archive(ricc_stubs_path)
                extras.push(if ricc_stubs_ar.len() > 0: ricc_stubs_ar else: ricc_stubs_path)
        else if not use_rt_core:
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
            // The build supplies the stage's embedding object independently
            // of the bridge/runtime root: stage2 needs populated bundle blobs
            // while its bootstrap root still carries stage1's empty slots.
            let embedded_override = runtime_getenv("WITH_COMPILER_EMBEDDED_OBJECT")
            let embedded_path = if embedded_override.len() > 0: embedded_override else: variant ++ "/embedded_objects.o"
            if runtime_read_file(embedded_path).len() == 0:
                with_eprint("error: missing or empty compiler embedding object: " ++ embedded_path)
                return link_stage_plan_fail()
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
