use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_substitute

// r5: pcre2_substitute_8. Oracle: pcre2test scripts + python re.sub.
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

unsafe fn do_sub(pat: &str, subj: &str, repl: &str, opts: c_uint, tag: *const i8):
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = pcre2_compile_8(to_cstr(pat), pat.len() as c_ulong, 0, &raw mut ec, &raw mut eo, null)
    if (code as i64) == 0:
        printf(c"%s compile-fail\n".ptr, tag)
        return
    let md = pcre2_match_data_create_from_pattern_8(code, null)
    let out = with_alloc(256)
    var blen: c_ulong = 256
    let rc = pcre2_substitute_8(code, str_data(subj), subj.len() as c_ulong, 0, opts, md, null, to_cstr(repl), repl.len() as c_ulong, out, &raw mut blen)
    printf(c"%s rc=%d blen=%lu out=%s\n".ptr, tag, rc, blen, out as *const i8)
    pcre2_match_data_free_8(md)
    pcre2_code_free_8(code)

unsafe fn main:
    do_sub("(?<word>\\w+) (?<other>\\w+)", "hello world foo bar", "$2 $1", PCRE2_SUBSTITUTE_GLOBAL, c"swap-global".ptr)
    do_sub("(\\w+) (\\w+)", "Hello World", "\\L$2\\E $1", PCRE2_SUBSTITUTE_EXTENDED, c"lower-second".ptr)
    do_sub("(a+)(b)?", "aaab", "[$1][$2]", PCRE2_SUBSTITUTE_EXTENDED | PCRE2_SUBSTITUTE_UNSET_EMPTY, c"unset-empty".ptr)
    do_sub("(a+)(b)?", "aaab", "[$1][$2]", PCRE2_SUBSTITUTE_EXTENDED, c"unset-default".ptr)
    do_sub("l+", "hello", "L", 0, c"single".ptr)
    do_sub("(\\w+)", "abc", "<$1>", PCRE2_SUBSTITUTE_GLOBAL | PCRE2_SUBSTITUTE_LITERAL, c"literal".ptr)
    do_sub("(a+)(z)?", "aaa", "[$1][$2]", PCRE2_SUBSTITUTE_EXTENDED, c"unset-err".ptr)
    do_sub("(a+)(z)?", "aaa", "[$1][$2]", PCRE2_SUBSTITUTE_EXTENDED | PCRE2_SUBSTITUTE_UNSET_EMPTY, c"unset-ok".ptr)
    let _done = 0
