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

fn str_data(s: &str) -> *const u8:
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
