// `with cc`: clang's own driver, linked into this binary.
//
// `with get` has to build a C library when no binary exists for the platform,
// and the toolchain never trusts a system compiler. LLVM's backends are already
// here for With's codegen; the SDK build adds lib/libclangMain.a (the objects of
// clang's driver tool: driver, cc1, cc1as), whose entry point is clang_main.
//
// clang runs a single compile in-process. When it needs a second process (more
// than one job) it re-executes ToolContext.path with prepend_arg inserted, so
// the child is `with cc -cc1 ...` and lands back here.

use compiler.EmbeddedClangResource
use compiler.EmbeddedClangResourceData
use compiler.ClangBridge
use compiler.EmbeddedSysroot
use compiler.LldDriver
use compiler.Runtime
use compiler.Link
use compiler.AbiStamp

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: &str) -> str
extern fn with_str_hash(s: &str) -> u64
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_fs_mkdir_p(path: &str) -> i32
extern fn with_fs_symlink(target: &str, link_path: &str) -> i32
extern fn with_sysinfo_os() -> str

// llvm::ToolContext (llvm/Support/LLVMDriver.h).
type ClangToolContext { path: *const u8, prepend_arg: *const u8, needs_prepend_arg: bool }

// int clang_main(int, char **, const llvm::ToolContext &). The compiler link
// aliases this name to the platform's C++ spelling (build/compiler.w).
extern fn with_clang_main(argc: i32, argv: *mut *mut u8, ctx: *const ClangToolContext) -> i32

// False when this compiler was linked against an SDK published before `with
// cc`: the link then aliases with_clang_main to a stand-in (build/compiler.w),
// which must never be called.
pub fn with_cc_available() -> bool: embedded_clang_driver_linked()

// A NUL-terminated copy that lives for the rest of the process, as argv does.
unsafe fn cc_c_string(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if s.len() > 0:
        with_memcpy(out, *(s as *const str as *const *const u8), s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

// Whether this invocation may run a link job: not a compile-only, preprocess
// or query invocation, and not one that names its own linker.
fn cc_may_link() -> bool:
    for i in 2..with_arg_count():
        let arg = with_arg_at(i)
        if arg == "-c" or arg == "-S" or arg == "-E" or arg == "-M" or arg == "-MM" or arg == "-fsyntax-only":
            return false
        if arg == "--version" or arg == "-dumpversion" or arg == "-dumpmachine" or arg.starts_with("-print-") or arg.starts_with("--print-"):
            return false
        if arg.starts_with("-fuse-ld") or arg.starts_with("--ld-path"):
            return false
    true

// #1915: clang's driver links by running a linker program, on macOS the
// host's `ld` unless told otherwise. It is handed this binary instead, as
// `ld64.lld`: a link to it in the cache, which src/main.w runs as lld. ""
// (and the reason printed) when the link cannot be made; the driver is then
// not run at all rather than let it reach for the host's linker.
fn cc_macos_linker() -> str:
    var self_exe = with_self_exe()
    if self_exe.len() > 0 and not self_exe.starts_with("/"):
        let cwd = runtime_cwd()
        self_exe = if cwd.len() > 0: cwd ++ "/" ++ self_exe else: ""
    if self_exe.len() == 0:
        with_eprint("error: with cc: cannot find this compiler's own executable by an absolute path to hand clang as its linker (argv[0] is '" ++ with_arg_at(0) ++ "')")
        return ""
    let dir = with_user_cache_dir() ++ "/with/lld-tool/" ++ f"{with_str_hash(self_exe)}"
    let link = dir ++ "/ld64.lld"
    if with_fs_file_exists(link) == 0:
        let _mk = with_fs_mkdir_p(dir)
        let _ln = with_fs_symlink(self_exe, link)
        if with_fs_file_exists(link) == 0:
            with_eprint("error: with cc: could not link " ++ link ++ " to " ++ self_exe ++ " for clang's linker")
            return ""
    link

// #1915 (D81): clang's MinGW driver links by running `ld.lld`. With no SDK's,
// it is handed this binary under that name (src/main.w runs a binary named
// ld.lld.exe as lld): a symbolic link in the cache where Windows allows one,
// else a copy, keyed by this binary's stamped identity so a rebuilt compiler
// never runs an older copy. "" (the reason printed) when neither can be made.
fn cc_windows_self_linker() -> str:
    var self_exe = with_self_exe()
    if self_exe.len() > 0 and not runtime_path_is_absolute(self_exe):
        self_exe = runtime_cwd() ++ "/" ++ self_exe
    if self_exe.len() == 0:
        with_eprint("error: with cc: cannot find this compiler's own executable to hand clang as its linker (argv[0] is '" ++ with_arg_at(0) ++ "')")
        return ""
    let identity = if compiler_self_id_is_stamped(): compiler_self_id() else: f"unstamped-{runtime_getpid()}"
    let key = self_exe ++ "|" ++ identity
    let dir = with_user_cache_dir() ++ "/with/lld-tool/" ++ f"{with_str_hash(key)}"
    let link = dir ++ "/ld.lld.exe"
    if with_fs_file_exists(link) != 0:
        return link
    let _mk = with_fs_mkdir_p(dir)
    let _ln = with_fs_symlink(self_exe, link)
    if with_fs_file_exists(link) != 0:
        return link
    let bytes = runtime_read_file(self_exe)
    let tmp = link ++ f".tmp.{runtime_getpid()}"
    if bytes.len() == 0 or runtime_write_file(tmp, bytes) != 0 or runtime_rename(tmp, link) != 0:
        let _rm = runtime_remove_file(tmp)
        if with_fs_file_exists(link) != 0:
            return link
        with_eprint("error: with cc: could not link or copy " ++ self_exe ++ " to " ++ link ++ " for clang's linker")
        return ""
    link

// argv[0] is `with`, argv[1] is `cc`; everything after it is clang's.
pub fn with_cc_main() -> i32:
    if not with_cc_available():
        with_eprint("error: this build of `with` has no C compiler: the LLVM SDK it was linked against predates `with cc`")
        return 127
    let args: Vec[str] = Vec.new()
    args.push("clang")
    let first = if with_arg_count() > 2: with_arg_at(2) else: ""
    // The driver passes -resource-dir down to its own -cc1 invocations.
    if not first.starts_with("-cc1"):
        let windows_sdk = link_stage_windows_c_target_uses_sdk_libc()
        let resource_dir = ensure_clang_resource_dir()
        if resource_dir.len() > 0 and not windows_sdk:
            args.push("-resource-dir")
            args.push(resource_dir)
        // macOS has no /usr/include: the driver reads the sysroot c_import
        // reads (#1915), unless the caller names one.
        var names_sysroot = false
        for i in 2..with_arg_count():
            let a = with_arg_at(i)
            if a == "-isysroot" or a == "--sysroot" or a.starts_with("--sysroot="): names_sysroot = true
        let sdk = host_c_sysroot()
        if sdk.len() > 0 and not names_sysroot:
            args.push(if with_sysinfo_os() == "Linux": "--sysroot" else: "-isysroot")
            args.push(sdk.trim().to_owned())
        // Windows x86_64 (#1915): C compiles for the same windows-gnu target
        // With's objects are, against the SDK's own libc, compiler-rt, libc++
        // and lld — never a host toolchain. The SDK's resource dir replaces
        // the embedded headers because it also holds compiler-rt.
        if windows_sdk:
            let toolchain = cc_windows_toolchain()
            if toolchain.problem.len() > 0:
                with_eprint("error: with cc: " ++ toolchain.problem)
                return 1
            for extra in toolchain.args: args.push(extra.clone())
    for i in 2..with_arg_count(): args.push(with_arg_at(i))
    if not first.starts_with("-cc1") and with_sysinfo_os() == "Macos" and cc_may_link():
        let ld = cc_macos_linker()
        if ld.len() == 0:
            return 1
        args.push("-fuse-ld=lld")
        args.push("--ld-path=" ++ ld)
    unsafe:
        let argv = with_alloc((args.len() + 1) * 8) as *mut *mut u8
        for i in 0..args.len() as i32:
            *((argv as i64 + i as i64 * 8) as *mut *mut u8) = cc_c_string(args[i])
        *((argv as i64 + args.len() * 8) as *mut *mut u8) = 0 as *mut u8
        let ctx = ClangToolContext { path: cc_c_string(with_arg_at(0)), prepend_arg: cc_c_string("cc"), needs_prepend_arg: true }
        with_clang_main(args.len() as i32, argv, &raw const ctx)

// Whether the caller's own arguments spell `name` (as `name`, `name=...` or
// `nameVALUE`).
fn cc_caller_names(prefix: &str) -> bool:
    for i in 2..with_arg_count():
        if with_arg_at(i).starts_with(prefix): return true
    false

// The windows-gnu toolchain `with cc` drives on Windows x86_64, from the SDK
// the link reads: its arguments, or the piece that is missing.
type CcToolchain { problem: str, args: Vec[str] }

fn cc_windows_toolchain() -> CcToolchain:
    var args: Vec[str] = Vec.new()
    // The link-only choices below are not unused in a compile-only run.
    args.push("--start-no-unused-arguments")
    let libc = link_stage_windows_libc_root()
    if libc.len() == 0:
        return CcToolchain { problem: "the LLVM SDK carries no Windows C runtime (libc/windows); build one with `with build :sdk-windows-libc`", args }
    let sdk = link_stage_windows_sdk_dir()
    var ld = sdk ++ "/bin/ld.lld.exe"
    if with_fs_file_exists(ld) == 0:
        // #1915 (D81): the toolchain this compiler carries has no ld.lld.exe;
        // this binary is lld (made only for an invocation that may link).
        ld = if cc_may_link(): cc_windows_self_linker() else: "-"
        if ld.len() == 0:
            return CcToolchain { problem: "no ld.lld.exe for clang's MinGW driver: the toolchain at " ++ sdk ++ " has none, and this compiler could not stand in for it (above)", args }
    let resource = sdk ++ "/lib/clang/" ++ embedded_clang_resource_version()
    if not cc_caller_names("--target") and not cc_caller_names("-target"):
        args.push("--target=" ++ link_stage_windows_c_target())
    if not cc_caller_names("--sysroot"):
        args.push("--sysroot=" ++ libc)
    if not cc_caller_names("-resource-dir") and with_fs_file_exists(resource ++ "/include/stddef.h") != 0:
        args.push("-resource-dir")
        args.push(resource)
    if not cc_caller_names("-rtlib") and not cc_caller_names("--rtlib"):
        args.push("-rtlib=compiler-rt")
    if not cc_caller_names("-unwindlib") and not cc_caller_names("--unwindlib"):
        args.push("-unwindlib=libunwind")
    if not cc_caller_names("-stdlib") and not cc_caller_names("--stdlib"):
        args.push("-stdlib=libc++")
    if ld != "-" and not cc_caller_names("--ld-path") and not cc_caller_names("-fuse-ld"):
        args.push("--ld-path=" ++ ld)
    args.push("--end-no-unused-arguments")
    CcToolchain { problem: "", args }
