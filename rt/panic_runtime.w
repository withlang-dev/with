// rt/panic_runtime.w -- small runtime panic surface for the compiler and
// non-libc-free link paths. Built early with the seed compiler.
//
// This replaces the handwritten support_runtime.c panic implementation.

extern fn with_ewrite(s: str) -> void
extern fn with_i64_to_str(n: i64) -> str
extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_panic_capture(msg: *const u8, msg_len: i32) -> void
extern fn _exit(code: i32) -> void

fn str_data(s: str) -> *const u8:
    let p = &s as *const *const u8
    unsafe *p

fn panic_render(msg: str, file: str, line: i32) -> str:
    if file.len() > 0:
        if line > 0:
            return "panic at " ++ file ++ ":" ++ with_i64_to_str(line as i64) ++ ": " ++ msg
        return "panic at " ++ file ++ ": " ++ msg
    "panic: " ++ msg

pub fn with_panic(msg: str, file: str, line: i32) -> void:
    let rendered = panic_render(msg, file, line)
    if with_fiber_in_fiber() != 0:
        with_fiber_panic_capture(str_data(rendered), rendered.len() as i32)
        _exit(134)
    with_ewrite(rendered)
    with_ewrite("\n")
    _exit(134)
