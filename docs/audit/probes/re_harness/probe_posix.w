// POSIX probe: regcomp/regexec/regerror/regfree via migrated pcre2posix.
use std.re.defs
use std.re.pcre2posix

fn show(tag: &str, v: i32):
    print(f"{tag}={v}")

fn main():
    // 1. basic match: pattern "a+b" vs "aaab" -> group 0 = [0,4)
    var preg: regex_t = regex_t { re_pcre2_code: null, re_match_data: null, re_endp: null, re_nsub: 0, re_erroffset: 0, re_cflags: 0 }
    var rc = unsafe { pcre2_regcomp(&raw mut preg as *mut regex_t, c"a+b".ptr, 0) }
    show("comp1", rc)
    var pm0: regmatch_t = regmatch_t { rm_so: -99, rm_eo: -99 }
    var pm1: regmatch_t = regmatch_t { rm_so: -99, rm_eo: -99 }
    var pm: [2]regmatch_t = [pm0, pm1]
    rc = unsafe { pcre2_regexec(&raw const preg as *const regex_t, c"aaab".ptr, 2 as c_ulong, &raw mut pm[0] as *mut regmatch_t, 0) }
    show("exec1", rc)
    show("g0so", pm[0].rm_so)
    show("g0eo", pm[0].rm_eo)
    unsafe { pcre2_regfree(&raw mut preg as *mut regex_t) }

    // 2. captures: "(a)(b)" vs "ab" -> nsub=2, g1=[0,1), g2=[1,2)
    var preg2: regex_t = regex_t { re_pcre2_code: null, re_match_data: null, re_endp: null, re_nsub: 0, re_erroffset: 0, re_cflags: 0 }
    rc = unsafe { pcre2_regcomp(&raw mut preg2 as *mut regex_t, c"(a)(b)".ptr, 0) }
    show("comp2", rc)
    show("nsub", preg2.re_nsub as i32)
    var q: [3]regmatch_t = [regmatch_t { rm_so: -99, rm_eo: -99 }, regmatch_t { rm_so: -99, rm_eo: -99 }, regmatch_t { rm_so: -99, rm_eo: -99 }]
    rc = unsafe { pcre2_regexec(&raw const preg2 as *const regex_t, c"ab".ptr, 3 as c_ulong, &raw mut q[0] as *mut regmatch_t, 0) }
    show("exec2", rc)
    show("q0", q[0].rm_so)
    show("q0e", q[0].rm_eo)
    show("q1", q[1].rm_so)
    show("q1e", q[1].rm_eo)
    show("q2", q[2].rm_so)
    show("q2e", q[2].rm_eo)
    unsafe { pcre2_regfree(&raw mut preg2 as *mut regex_t) }

    // 3. REG_ICASE (1): "abc" vs "ABC" -> match
    var preg3: regex_t = regex_t { re_pcre2_code: null, re_match_data: null, re_endp: null, re_nsub: 0, re_erroffset: 0, re_cflags: 0 }
    rc = unsafe { pcre2_regcomp(&raw mut preg3 as *mut regex_t, c"abc".ptr, 1) }
    show("comp3", rc)
    var r3: [1]regmatch_t = [regmatch_t { rm_so: -99, rm_eo: -99 }]
    rc = unsafe { pcre2_regexec(&raw const preg3 as *const regex_t, c"ABC".ptr, 1 as c_ulong, &raw mut r3[0] as *mut regmatch_t, 0) }
    show("exec3", rc)
    show("r3so", r3[0].rm_so)
    show("r3eo", r3[0].rm_eo)
    unsafe { pcre2_regfree(&raw mut preg3 as *mut regex_t) }

    // 4. no match: "xyz" vs "abc" -> REG_NOMATCH (17)
    var preg4: regex_t = regex_t { re_pcre2_code: null, re_match_data: null, re_endp: null, re_nsub: 0, re_erroffset: 0, re_cflags: 0 }
    rc = unsafe { pcre2_regcomp(&raw mut preg4 as *mut regex_t, c"xyz".ptr, 0) }
    show("comp4", rc)
    var r4: [1]regmatch_t = [regmatch_t { rm_so: -99, rm_eo: -99 }]
    rc = unsafe { pcre2_regexec(&raw const preg4 as *const regex_t, c"abc".ptr, 1 as c_ulong, &raw mut r4[0] as *mut regmatch_t, 0) }
    show("exec4", rc)
    unsafe { pcre2_regfree(&raw mut preg4 as *mut regex_t) }

    // 5. bad pattern: "(" -> nonzero; regerror message length > 0
    var preg5: regex_t = regex_t { re_pcre2_code: null, re_match_data: null, re_endp: null, re_nsub: 0, re_erroffset: 0, re_cflags: 0 }
    rc = unsafe { pcre2_regcomp(&raw mut preg5 as *mut regex_t, c"(".ptr, 0) }
    show("comp5", rc)
    var ebuf: [128]i8 = [0; 128]
    let elen = unsafe { pcre2_regerror(rc, &raw const preg5 as *const regex_t, &raw mut ebuf[0] as *mut i8, 128 as c_ulong) }
    show("elen", elen as i32)
