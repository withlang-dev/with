use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_match
use std.re.pcre2_match_data

// r8: xclass / extuni / script_run via match behavior.
// Oracle: python3 re + pcre2test (script_run, \p{Lu}, \X) where supported.
fn to_cstr(s: &str) -> *const u8:
    let out = with_alloc(s.len() + 1)
    var i: i64 = 0
    while i < s.len():
        unsafe { *((out as i64 + i) as *mut u8) = s.byte_at(i) }
        i = i + 1
    unsafe { *((out as i64 + s.len()) as *mut u8) = 0 }
    out as *const u8

fn raw_bytes(s: &str) -> *const u8:
    unsafe { **(&s as *const *const *const u8) }

unsafe fn t(pat: &str, opts: c_uint, subj: &str, slen: i64, tag: *const i8):
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = pcre2_compile_8(to_cstr(pat), pat.len() as c_ulong, opts, &raw mut ec, &raw mut eo, null)
    if (code as i64) == 0:
        printf(c"%s compile-fail ec=%d off=%lu\n".ptr, tag, ec, eo)
        return
    let md = pcre2_match_data_create_from_pattern_8(code, null)
    let rc = pcre2_match_8(code, raw_bytes(subj), slen as c_ulong, 0, 0, md, null)
    if rc >= 0:
        let ovec = pcre2_get_ovector_pointer_8(md)
        printf(c"%s rc=%d span=%lu..%lu\n".ptr, tag, rc, unsafe { ovec[0] }, unsafe { ovec[1] })
    else:
        printf(c"%s rc=%d\n".ptr, tag, rc)
    pcre2_match_data_free_8(md)
    pcre2_code_free_8(code)

unsafe fn main:
    // extended class (system pcre2test rejects these: build lacks eclass;
    // oracle = hand semantics + python for the plain-class equivalents)
    t("(?[[a-z]])", 0, "b", 1, c"perl-nested".ptr)
    t("(?[[a-z]--[aeiou]])", 0, "b", 1, c"perl-diff".ptr)
    t("[a-z--[aeiou]]", PCRE2_ALT_EXTENDED_CLASS, "b", 1, c"alt-diff-y".ptr)
    t("[a-z--[aeiou]]", PCRE2_ALT_EXTENDED_CLASS, "a", 1, c"alt-diff-n".ptr)
    t("[^x]", PCRE2_ALT_EXTENDED_CLASS, "y", 1, c"alt-neg".ptr)
    // classic xclass paths through the same compiler code
    t("[^\\W\\d]", PCRE2_UTF | PCRE2_UCP, "5", 1, c"neg-digit".ptr)
    t("[^\\W\\d]", PCRE2_UTF | PCRE2_UCP, "q", 1, c"neg-letter".ptr)
    t("\\p{Lu}", PCRE2_UTF | PCRE2_UCP, "Ωx", 3, c"uplu".ptr)
    // extuni: \X on NFD e+acute (2 codepoints, 1 cluster) and NFC
    t("\\X", PCRE2_UTF | PCRE2_UCP, "é", 3, c"x-nfd".ptr)
    t("\\X", PCRE2_UTF | PCRE2_UCP, "é", 2, c"x-nfc".ptr)
    // script_run: same script ok, mixed-script break
    t("(*script_run:\\w+)", PCRE2_UTF | PCRE2_UCP, "abc def", 7, c"sr-same".ptr)
    t("(*script_run:\\w+)", PCRE2_UTF | PCRE2_UCP, "abc α", 6, c"sr-mixed".ptr)
    let _done = 0
