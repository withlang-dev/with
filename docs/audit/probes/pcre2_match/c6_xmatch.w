use std.builtins.print
use std.builtins.print_i32
extern fn with_regex_compile(pattern: &str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn pcre2_match_data_create_from_pattern_8(code: i64, g: i64) -> i64
extern fn pcre2_match_8(code: i64, subj: i64, len: i64, off: i64, opts: i32, md: i64, mc: i64) -> i32
extern fn pcre2_match_data_free_8(md: i64) -> Unit
fn str_ptr(s: &str) -> i64:
    unsafe { **(&s as *const *const *const u8) } as i64
fn main:
    var ec: i32 = 0
    var eo: i32 = 0
    let code = unsafe { with_regex_compile("a", 0, &raw mut ec, &raw mut eo) }
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code as i64, 0) }
    let rc = unsafe { pcre2_match_8(code as i64, str_ptr("a"), 1, 0, 0, md, 0) }
    print("xmatch rc=")
    print_i32(rc)
    print("\n")
    unsafe { pcre2_match_data_free_8(md) }
