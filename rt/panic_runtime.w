// rt/panic_runtime.w -- small runtime panic surface for the compiler and
// non-libc-free link paths. Built early with the seed compiler.
//
// This replaces the handwritten support_runtime.c panic implementation.

extern fn with_ewrite(s: &str) -> Unit
extern fn with_i64_to_str(n: i64) -> str
extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_panic_capture(msg: *const u8, msg_len: i32) -> Unit
@[link_name("_exit")]
extern fn rt_libc_exit(code: i32) -> Never

pub fn str_data(s: &str) -> *const u8:
    unsafe **(&s as *const *const *const u8)

fn panic_render(msg: &str, file: &str, line: i32) -> str:
    if file.len() > 0:
        if line > 0:
            return "panic at " ++ file ++ ":" ++ with_i64_to_str(line as i64) ++ ": " ++ msg
        return "panic at " ++ file ++ ": " ++ msg
    "panic: " ++ msg

pub fn with_panic(msg: str, file: str, line: i32) -> Never:
    with_panic_ref(msg, file, line)

pub fn with_panic_ref(msg: &str, file: &str, line: i32) -> Never:
    let rendered = panic_render(msg, file, line)
    if with_fiber_in_fiber() != 0:
        with_fiber_panic_capture(str_data(rendered), rendered.len() as i32)
        rt_libc_exit(134)
    with_ewrite(rendered)
    with_ewrite("\n")
    rt_libc_exit(134)

// ── Foreign-state domain rows (ruling §52, spec §16.2b.14) ────────────────
// The runtime is not exempt from the foreign-state model: every foreign
// call above is described here, and the `runtime-domain-audit` lane
// (build/compiler.w) refuses a foreign extern without a row. A row states
// the view effect of the call on each domain the C library owns; "unknown
// effect means invalidate" (§38), so a row that says nothing invalidates.
// `preserves` appears only where the C standard says so:
//   errno   (thread)  — C11 7.5p3: any library function may set errno, so
//                       no call preserves it; the errno accessor is the
//                       macro's lvalue itself (7.5p2) and preserves it.
//   environ (process) — C11 7.22.4.6: altering the environment list is the
//                       implementation's method — POSIX.1-2017 setenv,
//                       unsetenv, putenv — and getenv may overwrite the
//                       text it returned (XSH getenv); those rows do not
//                       preserve it, every other call does.
//   locale  (process) — C11 7.11.1.1: setlocale is the function that
//                       changes the locale; the runtime never calls it.
c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    fn rt_libc_exit
        preserves domain environ
        preserves domain locale
