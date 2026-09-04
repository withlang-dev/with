use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_maketables
use std.re.pcre2_match_data
use std.re.pcre2_pattern_info
use std.re.pcre2_substring

// r3: pcre2_pattern_info_8 queries. Oracle: pcre2test /info above.
fn to_cstr(s: &str) -> *const u8:
    let out = with_alloc(s.len() + 1)
    var i: i64 = 0
    while i < s.len():
        unsafe { *((out as i64 + i) as *mut u8) = s.byte_at(i) }
        i = i + 1
    unsafe { *((out as i64 + s.len()) as *mut u8) = 0 }
    out as *const u8

unsafe fn query(code: *const pcre2_real_code_8, what: c_uint, tag: *const i8):
    var w32: c_uint = 0xdeadbeef as c_uint
    let rc = pcre2_pattern_info_8(code, what, &raw mut w32 as *mut c_void)
    printf(c"%s what=%u rc=%d val=%u\n".ptr, tag, what, rc, w32)

unsafe fn info_pat(pat: &str):
    let cpat = to_cstr(pat)
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = pcre2_compile_8(cpat, pat.len() as c_ulong, 0, &raw mut ec, &raw mut eo, null)
    if (code as i64) == 0:
        printf(c"compile-fail ec=%d\n".ptr, ec)
        return
    query(code, 4, c"capcount".ptr)
    query(code, 16, c"minlen".ptr)
    query(code, 17, c"namecount".ptr)
    query(code, 18, c"nameentrysize".ptr)
    query(code, 5, c"firstcu".ptr)
    query(code, 6, c"firsttype".ptr)
    query(code, 11, c"lastcu".ptr)
    query(code, 12, c"lasttype".ptr)
    query(code, 2, c"backrefmax".ptr)
    query(code, 8, c"hascrrorlf".ptr)
    query(code, 13, c"matchempty".ptr)
    query(code, 23, c"hasbslashc".ptr)
    query(code, 0, c"alloptions".ptr)
    var nt: *const u8 = null
    let rcnt = pcre2_pattern_info_8(code, 19, &raw mut nt as *mut c_void)
    printf(c"nametable rc=%d null=%d\n".ptr, rcnt, (nt as i64) == 0)
    var sz: c_ulong = 0
    printf(c"size rc=%d val=%lu\n".ptr, pcre2_pattern_info_8(code, 22, &raw mut sz as *mut c_void), sz)
    // number-from-name + nametable scan errors
    printf(c"numfrom nm=%d bad=%d\n".ptr, pcre2_substring_number_from_name_8(code, to_cstr("nm")), pcre2_substring_number_from_name_8(code, to_cstr("nope")))
    printf(c"badwhat rc=%d nullcode rc=%d\n".ptr, pcre2_pattern_info_8(code, 99, &raw mut sz as *mut c_void), pcre2_pattern_info_8(code as *const pcre2_real_code_8, 4, null))
    pcre2_code_free_8(code)

unsafe fn main:
    info_pat("(a+)(b)?(?<nm>c*)")
    info_pat("abc")
    let _done = 0
