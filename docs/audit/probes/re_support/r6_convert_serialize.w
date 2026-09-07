use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_convert
use std.re.pcre2_serialize

// r6: pattern_convert (glob+posix) then compile+match converted;
// serialize encode/decode round-trip + tamper paths.
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

unsafe fn try_match(pat: *const u8, patlen: c_ulong, subj: &str) -> c_int:
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = pcre2_compile_8(pat, patlen, 0, &raw mut ec, &raw mut eo, null)
    if (code as i64) == 0:
        printf(c"compile-fail ec=%d\n".ptr, ec)
        return -999
    let md = pcre2_match_data_create_from_pattern_8(code, null)
    let rc = pcre2_match_8(code, str_data(subj), subj.len() as c_ulong, 0, 0, md, null)
    pcre2_match_data_free_8(md)
    pcre2_code_free_8(code)
    rc

unsafe fn convert_show(glob: &str, opts: c_uint, tag: *const i8):
    var buf: *mut u8 = null
    var blen: c_ulong = 0
    let rc = pcre2_pattern_convert_8(str_data(glob), glob.len() as c_ulong, opts, &raw mut buf, &raw mut blen, null)
    if rc != 0:
        printf(c"%s rc=%d\n".ptr, tag, rc)
        return
    printf(c"%s rc=%d len=%lu conv=%s\n".ptr, tag, rc, blen, buf as *const i8)
    printf(c"%s match-txt rc=%d match-dat rc=%d\n".ptr, tag, try_match(buf, blen, "foo.txt"), try_match(buf, blen, "foo.dat"))
    pcre2_converted_pattern_free_8(buf)

unsafe fn main:
    convert_show("*.txt", PCRE2_CONVERT_GLOB, c"glob-star".ptr)
    convert_show("foo.???", PCRE2_CONVERT_GLOB, c"glob-q".ptr)
    convert_show("[a-c]*.txt", PCRE2_CONVERT_GLOB, c"glob-class".ptr)
    // posix basic: a* means literal a then *? in BRE a* is repeat; convert escapes
    var pbuf: *mut u8 = null
    var plen: c_ulong = 0
    printf(c"posix rc=%d len=%lu conv=%s\n".ptr, pcre2_pattern_convert_8(str_data("a(b*)c"), 6, PCRE2_CONVERT_POSIX_BASIC, &raw mut pbuf, &raw mut plen, null), plen, pbuf as *const i8)
    printf(c"posix match rc=%d\n".ptr, try_match(pbuf, plen, "abbbc"))
    pcre2_converted_pattern_free_8(pbuf)
    // bad options / null bufflen
    var b2: *mut u8 = null
    var l2: c_ulong = 0
    printf(c"conv-badopt rc=%d conv-null rc=%d\n".ptr, pcre2_pattern_convert_8(str_data("*.txt"), 5, 0, &raw mut b2, &raw mut l2, null), pcre2_pattern_convert_8(str_data("*.txt"), 5, PCRE2_CONVERT_GLOB, null as *mut *mut u8, null as *mut c_ulong, null))
    // serialize round-trip
    var ec: c_int = 0
    var eo: c_ulong = 0
    let cpat = to_cstr("(a+)(b)?")
    let code = pcre2_compile_8(cpat, 7, 0, &raw mut ec, &raw mut eo, null)
    var codes: [*const pcre2_real_code_8; 1] = [code as *const pcre2_real_code_8]
    var sbytes: *mut u8 = null
    var ssize: c_ulong = 0
    printf(c"enc rc=%d size=%lu ncodes=%d\n".ptr, pcre2_serialize_encode_8(&raw mut codes[0], 1, &raw mut sbytes, &raw mut ssize, null), ssize, pcre2_serialize_get_number_of_codes_8(sbytes))
    var dcodes: [*mut pcre2_real_code_8; 1] = [null]
    printf(c"dec rc=%d\n".ptr, pcre2_serialize_decode_8(&raw mut dcodes[0], 1, sbytes, null))
    let md = pcre2_match_data_create_8(10, null)
    printf(c"rt-match rc=%d\n".ptr, pcre2_match_8(dcodes[0], str_data("aaab"), 4, 0, 0, md, null))
    pcre2_match_data_free_8(md)
    // tamper: bad magic + encode nulls
    unsafe { sbytes[0] = 0 }
    printf(c"dec-badmagic rc=%d enc-null rc=%d\n".ptr, pcre2_serialize_decode_8(&raw mut dcodes[0], 1, sbytes, null), pcre2_serialize_encode_8(null as *mut *const pcre2_real_code_8, 1, &raw mut sbytes, &raw mut ssize, null))
    pcre2_serialize_free_8(sbytes)
    pcre2_code_free_8(code)
    let _done = 0
