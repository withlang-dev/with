use std.builtins.print
use std.builtins.print_i32
extern fn with_regex_compile(pattern: &str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_match_spans_alloc_at(code: *const i8, text: &str, start_offset: i32, out_count: *mut i32) -> *const i32
extern fn with_free(ptr: *mut u8) -> Unit
fn main:
    var ec: i32 = 0
    var eo: i32 = 0
    let code = unsafe { with_regex_compile("a", 0, &raw mut ec, &raw mut eo) }
    print("code-null=")
    print(if code as i64 == 0: "1" else: "0")
    print("\n")
    var n: i32 = -99
    let raw = unsafe { with_regex_match_spans_alloc_at(code, "a", 0, &raw mut n) }
    print("n=")
    print_i32(n)
    print(" ptrnull=")
    print(if raw as i64 == 0: "1" else: "0")
    print("\n")
    if raw as i64 != 0:
        print("s0=")
        print_i32(unsafe { *(raw as *const i32) })
        print(" e0=")
        print_i32(unsafe { *((raw as i64 + 4) as *const i32) })
        print("\n")
        unsafe { with_free(raw as *mut u8) }
