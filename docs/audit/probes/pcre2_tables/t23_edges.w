use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_valid_utf
use std.re.pcre2_ord2utf
use std.re.pcre2_string_utils
use std.re.pcre2_newline

// T23b: pointer-based edge paths — valid_utf, ord2utf, str utils, newline.
unsafe fn main:
    var eo: u64 = 0
    printf(c"valid_ascii=%d\n".ptr, (_pcre2_valid_utf_8((c"hello".ptr as *const u8), (5 as c_ulong), (&raw mut eo as *mut c_ulong)) as i32))
    printf(c"valid_lone_cont=%d off=%d\n".ptr, (_pcre2_valid_utf_8((c"\x80".ptr as *const u8), (1 as c_ulong), (&raw mut eo as *mut c_ulong)) as i32), (eo as i32))
    printf(c"valid_trunc2=%d off=%d\n".ptr, (_pcre2_valid_utf_8((c"\xc3".ptr as *const u8), (1 as c_ulong), (&raw mut eo as *mut c_ulong)) as i32), (eo as i32))
    var buf: [8]u8 = [0, 0, 0, 0, 0, 0, 0, 0]
    printf(c"ord2utf_A=%d b0=%d\n".ptr, (_pcre2_ord2utf_8((65 as c_uint), (&raw mut buf[0] as *mut u8)) as i32), (buf[0] as i32))
    printf(c"ord2utf_e9=%d b0=%d b1=%d\n".ptr, (_pcre2_ord2utf_8((233 as c_uint), (&raw mut buf[0] as *mut u8)) as i32), (buf[0] as i32), (buf[1] as i32))
    printf(c"strcmp_eq=%d\n".ptr, (_pcre2_strcmp_8((c"abc".ptr as *const u8), (c"abc".ptr as *const u8)) as i32))
    printf(c"strcmp_lt=%d\n".ptr, (_pcre2_strcmp_8((c"abc".ptr as *const u8), (c"abd".ptr as *const u8)) as i32))
    printf(c"strlen=%d\n".ptr, (_pcre2_strlen_8((c"hello".ptr as *const u8)) as i32))
    var nlen: u32 = 0
    let lf = (c"\n".ptr as *const u8)
    printf(c"isnl_lf=%d len=%d\n".ptr, (_pcre2_is_newline_8(lf, (2 as c_uint), (lf + (1 as usize)), (&raw mut nlen as *mut c_uint), (0 as c_int)) as i32), (nlen as i32))
    let aa = (c"a".ptr as *const u8)
    printf(c"isnl_a=%d\n".ptr, (_pcre2_is_newline_8(aa, (2 as c_uint), (aa + (1 as usize)), (&raw mut nlen as *mut c_uint), (0 as c_int)) as i32))
    printf(c"wasnl_lf=%d len=%d\n".ptr, (_pcre2_was_newline_8((lf + (1 as usize)), (2 as c_uint), lf, (&raw mut nlen as *mut c_uint), (0 as c_int)) as i32), (nlen as i32))
