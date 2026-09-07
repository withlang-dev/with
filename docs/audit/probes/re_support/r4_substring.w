use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_substring

// r4: substring extraction incl. error paths. Oracle: python re groups.
fn to_cstr(s: &str) -> *const u8:
    let out = with_alloc(s.len() + 1)
    var i: i64 = 0
    while i < s.len():
        unsafe { *((out as i64 + i) as *mut u8) = s.byte_at(i) }
        i = i + 1
    unsafe { *((out as i64 + s.len()) as *mut u8) = 0 }
    out as *const u8

fn str_data(s: &str) -> *const u8:
    unsafe { **(&s as *const *const *const u8) }

unsafe fn show_copy(md: *mut pcre2_real_match_data_8, n: c_uint):
    let buf = with_alloc(64)
    var sz: c_ulong = 64
    let rc = pcre2_substring_copy_bynumber_8(md, n, buf, &raw mut sz)
    printf(c"copy[%u] rc=%d len=%lu s=%s\n".ptr, n, rc, sz, buf as *const i8)

unsafe fn main:
    let pat = "(?<word>\\w+)!(?<opt>\\d*)?(?<unset>x)?"
    let cpat = to_cstr(pat)
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = pcre2_compile_8(cpat, pat.len() as c_ulong, 0, &raw mut ec, &raw mut eo, null)
    if (code as i64) == 0:
        printf(c"compile-fail ec=%d\n".ptr, ec)
        return
    let subj = "hello!123"
    let md = pcre2_match_data_create_from_pattern_8(code, null)
    let rc = pcre2_match_8(code, str_data(subj), subj.len() as c_ulong, 0, 0, md, null)
    printf(c"match rc=%d\n".ptr, rc)
    show_copy(md, 0)
    show_copy(md, 1)
    show_copy(md, 2)
    // byname get + length
    var sptr: *mut u8 = null
    var slen: c_ulong = 0
    printf(c"get word rc=%d len=%lu s=%s\n".ptr, pcre2_substring_get_byname_8(md, to_cstr("word"), &raw mut sptr, &raw mut slen), slen, sptr as *const i8)
    pcre2_substring_free_8(sptr)
    printf(c"len opt rc=%d len=%lu\n".ptr, pcre2_substring_length_byname_8(md, to_cstr("opt"), &raw mut slen), slen)
    // unset group (matched nothing, ovector unset): bynumber + byname
    let buf = with_alloc(64)
    var sz2: c_ulong = 64
    printf(c"copy unset rc=%d\n".ptr, pcre2_substring_copy_bynumber_8(md, 3, buf, &raw mut sz2))
    printf(c"get unset rc=%d\n".ptr, pcre2_substring_get_byname_8(md, to_cstr("unset"), &raw mut sptr, &raw mut slen))
    // unknown name / out-of-range number
    printf(c"copy badname rc=%d copy badnum rc=%d len badnum rc=%d\n".ptr, pcre2_substring_copy_byname_8(md, to_cstr("nope"), buf, &raw mut sz2), pcre2_substring_copy_bynumber_8(md, 99, buf, &raw mut sz2), pcre2_substring_length_bynumber_8(md, 99, &raw mut slen))
    // list get
    var listp: *mut *mut u8 = null
    var lensp: *mut c_ulong = null
    printf(c"list rc=%d l0=%s l1=%s l2=%s\n".ptr, pcre2_substring_list_get_8(md, &raw mut listp, &raw mut lensp), unsafe { listp[0] } as *const i8, unsafe { listp[1] } as *const i8, unsafe { listp[2] } as *const i8)
    pcre2_substring_list_free_8(listp)
    pcre2_match_data_free_8(md)
    pcre2_code_free_8(code)
    let _done = 0
