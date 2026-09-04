use std.builtins.print
use std.builtins.print_i32
extern fn with_regex_compile(pattern: &str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
fn main:
    var ec: i32 = 0
    var eo: i32 = 0
    let code = unsafe { with_regex_compile("a", 0, &raw mut ec, &raw mut eo) }
    print("limit_heap=")
    print_i32(unsafe { *((code as i64 + 108) as *const i32) })
    print(" limit_match=")
    print_i32(unsafe { *((code as i64 + 112) as *const i32) })
    print(" limit_depth=")
    print_i32(unsafe { *((code as i64 + 116) as *const i32) })
    print(" first_cu=")
    print_i32(unsafe { *((code as i64 + 120) as *const i32) })
    print(" top_bracket=")
    print_i32(unsafe { *((code as i64 + 136) as *const u8) } as i32)
    print(" minlength=")
    print_i32(unsafe { *((code as i64 + 134) as *const u8) } as i32)
    print("\n")
