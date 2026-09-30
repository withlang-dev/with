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
extern fn with_sysinfo_arch() -> str

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

// #1915: clang's driver links by running a linker program, the host's `ld`
// unless told otherwise. It is handed this binary instead, as `ld64.lld` on
// macOS and `ld.lld` on Linux: a link to it in the cache, which src/main.w
// runs as lld. "" (and the reason printed) when the link cannot be made;
// the driver is then not run at all rather than let it reach for the host's
// linker.
fn cc_self_linker(name: &str) -> str:
    var self_exe = with_self_exe()
    if self_exe.len() > 0 and not self_exe.starts_with("/"):
        let cwd = runtime_cwd()
        self_exe = if cwd.len() > 0: cwd ++ "/" ++ self_exe else: ""
    if self_exe.len() == 0:
        with_eprint("error: with cc: cannot find this compiler's own executable by an absolute path to hand clang as its linker (argv[0] is '" ++ with_arg_at(0) ++ "')")
        return ""
    let dir = with_user_cache_dir() ++ "/with/lld-tool/" ++ f"{with_str_hash(self_exe)}"
    let link = dir ++ "/" ++ name
    if with_fs_file_exists(link) == 0:
        let _mk = with_fs_mkdir_p(dir)
        let _ln = with_fs_symlink(self_exe, link)
        if with_fs_file_exists(link) == 0:
            with_eprint("error: with cc: could not link " ++ link ++ " to " ++ self_exe ++ " for clang's linker")
            return ""
    link

// linux-x86_64 (#1915): clang finds compiler-rt (builtins, crtbegin/crtend)
// under its resource directory; the embedded one holds only headers. This
// directory holds both, as links: include/ to the embedded headers, and
// lib/<triple>/ to the compiler-rt files the linux sysroot carries. "" (and
// the reason printed) when it cannot be made.
fn cc_linux_resource_dir(headers: &str, sysroot: &str) -> str:
    let dir = with_user_cache_dir() ++ "/with/cc-resource/" ++ f"{with_str_hash(headers ++ "|" ++ sysroot)}"
    let rt = dir ++ "/lib/x86_64-unknown-linux-gnu"
    if with_fs_file_exists(rt ++ "/libclang_rt.builtins.a") != 0:
        return dir
    let _mk = with_fs_mkdir_p(rt)
    let _inc = with_fs_symlink(headers ++ "/include", dir ++ "/include")
    for name in ["clang_rt.crtbegin.o", "clang_rt.crtend.o", "libclang_rt.builtins.a"]:
        let _ln = with_fs_symlink(sysroot ++ "/usr/lib/" ++ name, rt ++ "/" ++ name)
    if with_fs_file_exists(rt ++ "/libclang_rt.builtins.a") == 0 or with_fs_file_exists(dir ++ "/include/stddef.h") == 0:
        with_eprint("error: with cc: could not make clang's resource directory " ++ dir ++ " from " ++ headers ++ " and " ++ sysroot)
        return ""
    dir

// argv[0] is `with`, argv[1] is `cc`; everything after it is clang's.
pub fn with_cc_main() -> i32:
    if not with_cc_available():
        with_eprint("error: this build of `with` has no C compiler: the LLVM SDK it was linked against predates `with cc`")
        return 127
    let args: Vec[str] = Vec.new()
    args.push("clang")
    let first = if with_arg_count() > 2: with_arg_at(2) else: ""
    // The driver passes -resource-dir down to its own -cc1 invocations.
    let linux = with_sysinfo_os() == "Linux" and with_sysinfo_arch() == "x86_64"
    if not first.starts_with("-cc1"):
        var resource_dir = ensure_clang_resource_dir()
        // A Linux link reads compiler-rt beside the headers.
        if linux and resource_dir.len() > 0 and host_c_sysroot().len() > 0:
            resource_dir = cc_linux_resource_dir(resource_dir, host_c_sysroot())
            if resource_dir.len() == 0:
                return 1
        if resource_dir.len() > 0:
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
    for i in 2..with_arg_count(): args.push(with_arg_at(i))
    if not first.starts_with("-cc1") and with_sysinfo_os() == "Macos" and cc_may_link():
        let ld = cc_self_linker("ld64.lld")
        if ld.len() == 0:
            return 1
        args.push("-fuse-ld=lld")
        args.push("--ld-path=" ++ ld)
    // Linux: this binary's lld over the sysroot, compiler-rt where gcc's
    // driver takes libgcc and gcc's crt objects.
    if not first.starts_with("-cc1") and linux and cc_may_link():
        let ld = cc_self_linker("ld.lld")
        if ld.len() == 0:
            return 1
        for a in ["-fuse-ld=lld", "--rtlib=compiler-rt", "--unwindlib=none"]: args.push(a.to_owned())
        args.push("--ld-path=" ++ ld)
        // libc++ (the sysroot's, libc++abi and libunwind in it) uses
        // pthreads and dl, separate libraries in glibc 2.28; only a link that
        // needs them records them.
        for a in ["-Wl,--as-needed", "-lpthread", "-ldl", "-Wl,--no-as-needed"]: args.push(a.to_owned())
    // Linux C++ is the sysroot's libc++, never the host's libstdc++.
    var names_stdlib = false
    for i in 2..with_arg_count():
        if with_arg_at(i).starts_with("-stdlib="): names_stdlib = true
    if not first.starts_with("-cc1") and linux and not names_stdlib:
        for a in ["--start-no-unused-arguments", "-stdlib=libc++", "--end-no-unused-arguments"]: args.push(a.to_owned())
    unsafe:
        let argv = with_alloc((args.len() + 1) * 8) as *mut *mut u8
        for i in 0..args.len() as i32:
            *((argv as i64 + i as i64 * 8) as *mut *mut u8) = cc_c_string(args[i])
        *((argv as i64 + args.len() * 8) as *mut *mut u8) = 0 as *mut u8
        let ctx = ClangToolContext { path: cc_c_string(with_arg_at(0)), prepend_arg: cc_c_string("cc"), needs_prepend_arg: true }
        with_clang_main(args.len() as i32, argv, &raw const ctx)
