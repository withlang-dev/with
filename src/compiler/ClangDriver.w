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

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str

// llvm::ToolContext (llvm/Support/LLVMDriver.h).
type ClangToolContext { path: *const u8, prepend_arg: *const u8, needs_prepend_arg: bool }

// int clang_main(int, char **, const llvm::ToolContext &). The compiler link
// aliases this name to the platform's C++ spelling (build/compiler.w).
extern fn with_clang_main(argc: i32, argv: *mut *mut u8, ctx: *const ClangToolContext) -> i32

// A NUL-terminated copy that lives for the rest of the process, as argv does.
unsafe fn cc_c_string(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if s.len() > 0:
        with_memcpy(out, **(&s as *const *const *const u8), s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

// argv[0] is `with`, argv[1] is `cc`; everything after it is clang's.
pub fn with_cc_main() -> i32:
    let args: Vec[str] = Vec.new()
    args.push("clang")
    let first = if with_arg_count() > 2: with_arg_at(2) else: ""
    // The driver passes -resource-dir down to its own -cc1 invocations.
    if not first.starts_with("-cc1"):
        let resource_dir = ensure_clang_resource_dir()
        if resource_dir.len() > 0:
            args.push("-resource-dir")
            args.push(resource_dir)
    for i in 2..with_arg_count(): args.push(with_arg_at(i))
    unsafe:
        let argv = with_alloc((args.len() + 1) * 8) as *mut *mut u8
        for i in 0..args.len() as i32:
            *((argv as i64 + i as i64 * 8) as *mut *mut u8) = cc_c_string(args[i])
        *((argv as i64 + args.len() * 8) as *mut *mut u8) = 0 as *mut u8
        let ctx = ClangToolContext { path: cc_c_string(with_arg_at(0)), prepend_arg: cc_c_string("cc"), needs_prepend_arg: true }
        with_clang_main(args.len() as i32, argv, &raw const ctx)
