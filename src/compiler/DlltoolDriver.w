// `with __dlltool`: LLVM's dlltool, linked into this binary (#1915, D81).
//
// `with get` writes the import libraries of the in-box DLLs a Windows
// package links (compiler.WindowsImportLibs) with dlltool. The compiler
// carries it as it carries lld: a Windows compiler link pulls the SDK's
// lib/libLLVMDlltoolDriver.a in and aliases `int llvm::dlltoolDriverMain(
// ArrayRef<const char *>)` to with_dlltool_main (build/compiler.w
// comp_dlltool_link_lines). Every other compiler links a stand-in, and
// embedded_dlltool_linked() says so.

use compiler.EmbeddedClangResourceData
use compiler.Runtime

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str

// llvm::ArrayRef<const char *>: a pointer and a count, passed by value.
type DlltoolArgs { data: *const *mut u8, len: i64 }

extern fn with_dlltool_main(args: DlltoolArgs) -> i32

pub fn with_dlltool_available() -> bool: embedded_dlltool_linked()

unsafe fn dt_c_string(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if s.len() > 0:
        with_memcpy(out, *(s as *const str as *const *const u8), s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

// argv[0] is `with`, argv[1] is `__dlltool`; the rest is dlltool's.
pub fn with_dlltool_cli_main() -> i32:
    if not with_dlltool_available():
        runtime_eprint("error: this build of `with` has no dlltool: only a Windows compiler linked against a windows-gnu LLVM SDK carries one (#1915)")
        return 127
    let args: Vec[str] = Vec.new()
    args.push("llvm-dlltool")
    for i in 2..with_arg_count(): args.push(with_arg_at(i))
    unsafe:
        let argv = with_alloc((args.len() + 1) * 8) as *mut *mut u8
        for i in 0..args.len() as i32:
            *((argv as i64 + i as i64 * 8) as *mut *mut u8) = dt_c_string(args[i])
        *((argv as i64 + args.len() * 8) as *mut *mut u8) = 0 as *mut u8
        with_dlltool_main(DlltoolArgs { data: argv as *const *mut u8, len: args.len() })
