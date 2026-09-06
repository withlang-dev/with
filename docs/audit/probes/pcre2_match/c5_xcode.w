use std.builtins.print
use std.builtins.print_i32
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_match
use std.re.pcre2_match_data
extern fn with_regex_compile(pattern: &str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
fn my_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    let _ = data
    with_alloc(size as i64) as *mut c_void
fn my_free(ptr: *mut c_void, data: *mut c_void):
    let _ = data
    with_free(ptr as *mut u8)
fn str_data(s: &str) -> *const u8:
    unsafe { **(&s as *const *const *const u8) }
fn main:
    var ec: i32 = 0
    var eo: i32 = 0
    // code object from the LINKED (binary) compiler...
    let rtcode = unsafe { with_regex_compile("a", 0, &raw mut ec, &raw mut eo) }
    // ...matched by the FRESH-JIT interpreter from current sources
    let g = unsafe { pcre2_general_context_create_8(my_malloc, my_free, null) }
    let md = unsafe { pcre2_match_data_create_from_pattern_8(rtcode as *const pcre2_real_code_8, g) }
    let rc = unsafe { pcre2_match_8(rtcode as *const pcre2_real_code_8, str_data("a"), 1, 0, 0, md, null) }
    print("xcode rc=")
    print_i32(rc)
    print("\n")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_general_context_free_8(g) }
