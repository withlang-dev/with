// `with __ld`: lld's drivers, linked into this binary (#1915).
//
// A link reads no linker from the host: no `cc`, no `ld`, no Xcode. The
// compiler link pulls the SDK's lld driver archives in and aliases each
// driver's entry point, `bool lld::<flavor>::link(ArrayRef<const char *>,
// raw_ostream &stdout, raw_ostream &stderr, bool exitEarly, bool
// disableOutput)`, to a plain name (build/compiler.w comp_lld_alias_lines).
// A native link runs this binary as `with __ld ...`, so each link is its own
// process, as it was with the system linker: lld keeps global state, and
// the build links on several threads at once.
//
// `with __ld [-flavor darwin|gnu|link|wasm] <lld args>`: the host's flavor when
// none is named (ld64.lld on macOS, ld.lld on Linux, lld-link on Windows).

use compiler.EmbeddedClangResourceData
use compiler.Runtime

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: isize) -> str

// llvm::ArrayRef<const char *>: a pointer and a count, passed by value.
type LldArgs { data: *const *mut u8, len: i64 }

extern fn with_lld_macho_link(args: LldArgs, stdout_os: *mut u8, stderr_os: *mut u8, exit_early: bool, disable_output: bool) -> bool
extern fn with_lld_elf_link(args: LldArgs, stdout_os: *mut u8, stderr_os: *mut u8, exit_early: bool, disable_output: bool) -> bool
extern fn with_lld_coff_link(args: LldArgs, stdout_os: *mut u8, stderr_os: *mut u8, exit_early: bool, disable_output: bool) -> bool
extern fn with_lld_mingw_link(args: LldArgs, stdout_os: *mut u8, stderr_os: *mut u8, exit_early: bool, disable_output: bool) -> bool
extern fn with_lld_wasm_link(args: LldArgs, stdout_os: *mut u8, stderr_os: *mut u8, exit_early: bool, disable_output: bool) -> bool
// llvm::outs() and llvm::errs().
extern fn with_llvm_outs() -> *mut u8
extern fn with_llvm_errs() -> *mut u8

// Whether this compiler links lld's `flavor` driver: an SDK without that
// archive leaves the name aliased to a stand-in that must never be called.
pub fn lld_flavor_linked(flavor: &str) -> bool:
    for linked in embedded_lld_flavors().split(" "):
        if linked == flavor: return true
    false

// The lld flavor of a native link on this host.
pub fn lld_host_flavor() -> str:
    let os = runtime_sysinfo_os()
    if os == "Macos": "macho" else if os == "Windows": "coff" else: "elf"

// The name lld's own tool would have for `flavor` (argv[0] of the link).
fn lld_tool_name(flavor: &str) -> str:
    if flavor == "macho": "ld64.lld" else if flavor == "coff": "lld-link" else if flavor == "wasm": "wasm-ld" else: "ld.lld"

// lld's `-flavor` spellings.
fn lld_flavor_from_option(name: &str) -> str:
    if name == "darwin" or name == "darwinnew": return "macho"
    if name == "gnu": return "elf"
    if name == "link": return "coff"
    if name == "wasm": return "wasm"
    ""

// A GNU-flavor link with `-m <x>pe` is MinGW's, as lld decides.
fn lld_gnu_is_mingw(args: &List[str]) -> bool:
    for i in 0..args.len() as i32:
        let emulation = if args[i] == "-m" and i + 1 < args.len() as i32: args[i + 1].clone() else if args[i].starts_with("-m") and args[i] != "-m": args[i].slice(2, args[i].len()) else: ""
        if emulation.ends_with("pe") or emulation.ends_with("pep"):
            return true
    false

// A NUL-terminated copy that lives for the rest of the process, as argv does.
unsafe fn ld_c_string(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if s.len() > 0:
        with_memcpy(out, *(s as *const str as *const *const u8), s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

// Runs lld's `flavor` driver over `args` (args[0] is the tool name) in this
// process; 0 when the link succeeded. lld prints its own diagnostics.
pub fn lld_link(flavor: &str, args: &List[str]) -> i32:
    if not lld_flavor_linked(flavor):
        runtime_eprint("error: this build of `with` has no " ++ lld_tool_name(flavor) ++ " linker: the LLVM SDK it was linked against has no lld " ++ flavor ++ " driver archive")
        return 127
    unsafe:
        let argv = with_alloc((args.len() + 1) * 8) as *mut *mut u8
        for i in 0..args.len() as i32:
            *((argv as i64 + i as i64 * 8) as *mut *mut u8) = ld_c_string(args[i])
        *((argv as i64 + args.len() * 8) as *mut *mut u8) = 0 as *mut u8
        let lld_args = LldArgs { data: argv as *const *mut u8, len: args.len() }
        // exitEarly, as lld's own tool: on success lld flushes and exits
        // without tearing its state down.
        let ok = if flavor == "macho":
            with_lld_macho_link(lld_args, with_llvm_outs(), with_llvm_errs(), true, false)
        else if flavor == "coff":
            with_lld_coff_link(lld_args, with_llvm_outs(), with_llvm_errs(), true, false)
        else if flavor == "mingw":
            with_lld_mingw_link(lld_args, with_llvm_outs(), with_llvm_errs(), true, false)
        else if flavor == "wasm":
            with_lld_wasm_link(lld_args, with_llvm_outs(), with_llvm_errs(), true, false)
        else:
            with_lld_elf_link(lld_args, with_llvm_outs(), with_llvm_errs(), true, false)
        if ok: 0 else: 1

// argv[0] is `with`, argv[1] is `__ld`.
pub fn with_ld_main() -> i32:
    var first = 2
    var flavor = lld_host_flavor()
    if with_arg_count() > 3 and with_arg_at(2) == "-flavor":
        flavor = lld_flavor_from_option(with_arg_at(3))
        if flavor.len() == 0:
            runtime_eprint("error: with __ld: unknown -flavor '" ++ with_arg_at(3) ++ "' (darwin, gnu, link or wasm)")
            return 2
        first = 4
    let rest: List[str] = List.new()
    for i in first..with_arg_count(): rest.push(with_arg_at(i))
    if flavor == "elf" and lld_gnu_is_mingw(&rest):
        flavor = "mingw"
    let args: List[str] = List.new()
    args.push(lld_tool_name(flavor))
    for i in 0..rest.len() as i32: args.push(rest[i].clone())
    lld_link(flavor, &args)

// This executable, to run `with __ld` as a child: argv[0] when it names a
// path, else argv[0] found on PATH.
pub fn with_self_exe() -> str:
    let argv0 = with_arg_at(0)
    if argv0.contains("/") or argv0.contains("\\"): return argv0
    let windows = runtime_sysinfo_os() == "Windows"
    for dir in runtime_getenv("PATH").split(if windows: ";" else: ":"):
        if dir.len() == 0: continue
        let candidate = dir ++ "/" ++ argv0 ++ (if windows and not argv0.ends_with(".exe"): ".exe" else: "")
        if runtime_file_exists(candidate) != 0: return candidate
    ""

// Run as one of lld's own tool names (a link named ld64.lld to this binary,
// the way clang's driver finds its linker, src/compiler/ClangDriver.w), the
// flavor that name selects; "" for any other name.
pub fn lld_flavor_for_tool_name(argv0: &str) -> str:
    var start = 0
    for i in 0..argv0.len() as i32:
        if argv0[i] == '/' or argv0[i] == '\\':
            start = i + 1
    let base = argv0.slice(start, argv0.len())
    if base == "ld64.lld": "macho" else if base == "ld.lld" or base == "ld.lld.exe": "elf" else if base == "lld-link" or base == "lld-link.exe": "coff" else if base == "wasm-ld": "wasm" else: ""

// argv[0] is the tool name; every other argument is lld's.
pub fn with_ld_tool_main(flavor: &str) -> i32:
    let args: List[str] = List.new()
    args.push(lld_tool_name(flavor))
    for i in 1..with_arg_count(): args.push(with_arg_at(i))
    let chosen = if flavor == "elf" and lld_gnu_is_mingw(&args): "mingw" else: flavor.to_owned()
    lld_link(chosen, &args)
