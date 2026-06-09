//! expect-stdout: ok

extern fn with_regex_compile(pattern: str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_error_message(code: i32) -> str
extern fn with_panic(msg: str, file: str, line: i32) -> void

unsafe fn literal_code(slot: *mut *const i8, pattern: str, options: i32) -> *const i8:
    if slot as i64 == 0:
        return null
    let existing = *slot
    if existing as i64 != 0:
        return existing
    var err_code: i32 = 0
    var err_offset: i32 = 0
    let compiled = with_regex_compile(pattern, options, &raw mut err_code, &raw mut err_offset)
    if compiled as i64 == 0:
        with_panic("invalid regex literal: " ++ with_regex_error_message(err_code), "", 0)
        return null
    *slot = compiled
    compiled

fn main:
    print("ok")
