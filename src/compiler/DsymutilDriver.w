// `with __dsymutil`: LLVM's dsymutil, linked into this binary (#1915).
//
// A macOS debug build collects its DWARF into a .dSYM. That was Xcode's
// dsymutil from PATH; the toolchain reads no Xcode. The SDK archives
// dsymutil's objects as lib/libdsymutilMain.a (build/sdk.w), the compiler
// link aliases its entry point to with_dsymutil_main (build/compiler.w), and
// a build runs `<this compiler> __dsymutil <binary>` (compiler.Compilation).
// An SDK published before the archive links a stand-in instead, and
// embedded_dsymutil_linked() says so.

use compiler.EmbeddedClangResourceData
use compiler.Runtime

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str

// llvm::ToolContext (llvm/Support/LLVMDriver.h).
type DsymutilToolContext { path: *const u8, prepend_arg: *const u8, needs_prepend_arg: bool }

// int dsymutil_main(int, char **, const llvm::ToolContext &).
extern fn with_dsymutil_main(argc: i32, argv: *mut *mut u8, ctx: *const DsymutilToolContext) -> i32

pub fn with_dsymutil_available() -> bool: embedded_dsymutil_linked()

unsafe fn ds_c_string(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if s.len() > 0:
        with_memcpy(out, *(s as *const str as *const *const u8), s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

// argv[0] is `with`, argv[1] is `__dsymutil`; the rest is dsymutil's.
pub fn with_dsymutil_cli_main() -> i32:
    if not with_dsymutil_available():
        runtime_eprint("error: this build of `with` has no dsymutil: the LLVM SDK it was linked against predates lib/libdsymutilMain.a (#1915)")
        return 127
    let args: Vec[str] = Vec.new()
    args.push("dsymutil")
    for i in 2..with_arg_count(): args.push(with_arg_at(i))
    unsafe:
        let argv = with_alloc((args.len() + 1) * 8) as *mut *mut u8
        for i in 0..args.len() as i32:
            *((argv as i64 + i as i64 * 8) as *mut *mut u8) = ds_c_string(args[i])
        *((argv as i64 + args.len() * 8) as *mut *mut u8) = 0 as *mut u8
        let ctx = DsymutilToolContext { path: ds_c_string(with_arg_at(0)), prepend_arg: ds_c_string(""), needs_prepend_arg: false }
        with_dsymutil_main(args.len() as i32, argv, &raw const ctx)
