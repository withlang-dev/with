// Engine differential probe: drives pcre2_compile_8/pcre2_match_8 directly
// over a matrix and prints machine-parseable results for diffing against
// system pcre2test 10.47 and python3 re.
// Output per case:
//   CASE <idx>
//   RC <rc | NOMATCH | COMPILEFAIL <ec> <eoff>>
//   OV <s0> <e0> <s1> <e1> ...   (UNSET groups print as -1 -1)
use std.builtins.print_i32
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_maketables
use std.re.pcre2_match
use std.re.pcre2_match_data

fn my_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    let _ = data
    with_alloc(size as i64) as *mut c_void

fn my_free(ptr: *mut c_void, data: *mut c_void):
    let _ = data
    with_free(ptr as *mut u8)

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

fn subj_ptr(s: &str) -> *const u8:
    if s.len() == 0:
        with_alloc(1) as *const u8
    else:
        str_data(s)

fn run_case(idx: i32, pat: &str, subj: &str, copts: c_uint):
    print("CASE ")
    print_i32(idx)
    print("\n")
    let g = unsafe { pcre2_general_context_create_8(my_malloc, my_free, null) }
    var cc = _pcre2_default_compile_context_8
    unsafe { ((*(&raw mut cc as *mut pcre2_memctl)) = (*(g as *mut pcre2_memctl))) }
    (cc.max_pattern_length = (0 -% 1) as c_ulong)
    (cc.max_pattern_compiled_length = (0 -% 1) as c_ulong)
    (cc.parens_nest_limit = 250)
    (cc.max_varlookbehind = 255)
    (cc.newline_convention = 2)
    (cc.bsr_convention = 0)
    (cc.optimization_flags = 4294967295)
    let tables = unsafe { pcre2_maketables_8(g) }
    (cc.tables = tables)
    let cpat = to_cstr(pat)
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = unsafe { pcre2_compile_8(cpat, pat.len() as c_ulong, copts, &raw mut ec, &raw mut eo, &raw mut cc) }
    with_free(cpat as *mut u8)
    if code as i64 == 0:
        print("RC COMPILEFAIL ")
        print_i32(ec)
        print(" ")
        print_i32(eo as i32)
        print("\n")
        unsafe { pcre2_general_context_free_8(g) }
        return
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, g) }
    let rc = unsafe { pcre2_match_8(code, subj_ptr(subj), subj.len() as c_ulong, 0 as c_ulong, 0 as c_uint, md, null) }
    if rc < 0:
        print("RC NOMATCH ")
        print_i32(rc)
        print("\n")
    else:
        print("RC ")
        print_i32(rc)
        print("\n")
        let ov = unsafe { pcre2_get_ovector_pointer_8(md) }
        print("OV")
        for i in 0..rc as i32:
            let start = unsafe { *(ov + ((i * 2) as isize)) }
            let end_pos = unsafe { *(ov + ((i * 2 + 1) as isize)) }
            print(" ")
            if start == (0 -% 1) as c_ulong:
                print("-1 -1")
            else:
                print_i32(start as i32)
                print(" ")
                print_i32(end_pos as i32)
        print("\n")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_code_free_8(code) }
    unsafe { pcre2_general_context_free_8(g) }

fn run_utf(idx: i32):
    // subject "caf\xc3\xa9 x" (7 bytes), pattern "\xc3\xa9" (2 bytes), UTF mode
    print("CASE ")
    print_i32(idx)
    print("\n")
    let g = unsafe { pcre2_general_context_create_8(my_malloc, my_free, null) }
    var cc = _pcre2_default_compile_context_8
    unsafe { ((*(&raw mut cc as *mut pcre2_memctl)) = (*(g as *mut pcre2_memctl))) }
    (cc.max_pattern_length = (0 -% 1) as c_ulong)
    (cc.max_pattern_compiled_length = (0 -% 1) as c_ulong)
    (cc.parens_nest_limit = 250)
    (cc.max_varlookbehind = 255)
    (cc.newline_convention = 2)
    (cc.bsr_convention = 0)
    (cc.optimization_flags = 4294967295)
    let tables = unsafe { pcre2_maketables_8(g) }
    (cc.tables = tables)
    let pbuf = with_alloc(2)
    unsafe { *((pbuf as i64) as *mut u8) = 195 as u8 }
    unsafe { *((pbuf as i64 + 1) as *mut u8) = 169 as u8 }
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = unsafe { pcre2_compile_8(pbuf as *const u8, 2 as c_ulong, PCRE2_UTF, &raw mut ec, &raw mut eo, &raw mut cc) }
    with_free(pbuf as *mut u8)
    if code as i64 == 0:
        print("RC COMPILEFAIL ")
        print_i32(ec)
        print(" ")
        print_i32(eo as i32)
        print("\n")
        unsafe { pcre2_general_context_free_8(g) }
        return
    let sbuf = with_alloc(7)
    unsafe { *((sbuf as i64) as *mut u8) = 99 as u8 }
    unsafe { *((sbuf as i64 + 1) as *mut u8) = 97 as u8 }
    unsafe { *((sbuf as i64 + 2) as *mut u8) = 102 as u8 }
    unsafe { *((sbuf as i64 + 3) as *mut u8) = 195 as u8 }
    unsafe { *((sbuf as i64 + 4) as *mut u8) = 169 as u8 }
    unsafe { *((sbuf as i64 + 5) as *mut u8) = 32 as u8 }
    unsafe { *((sbuf as i64 + 6) as *mut u8) = 120 as u8 }
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, g) }
    let rc = unsafe { pcre2_match_8(code, sbuf as *const u8, 7 as c_ulong, 0 as c_ulong, 0 as c_uint, md, null) }
    with_free(sbuf as *mut u8)
    if rc < 0:
        print("RC NOMATCH ")
        print_i32(rc)
        print("\n")
    else:
        print("RC ")
        print_i32(rc)
        print("\n")
        let ov = unsafe { pcre2_get_ovector_pointer_8(md) }
        print("OV")
        for i in 0..rc as i32:
            let start = unsafe { *(ov + ((i * 2) as isize)) }
            let end_pos = unsafe { *(ov + ((i * 2 + 1) as isize)) }
            print(" ")
            if start == (0 -% 1) as c_ulong:
                print("-1 -1")
            else:
                print_i32(start as i32)
                print(" ")
                print_i32(end_pos as i32)
        print("\n")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_code_free_8(code) }
    unsafe { pcre2_general_context_free_8(g) }

fn main:
    run_case(0, "abc", "xabcdef", 0 as c_uint)
    run_case(1, "hello, (\\w+)!", "hello, world!", 0 as c_uint)
    run_case(2, "[a-z]+", "abcXYZ", 0 as c_uint)
    run_case(3, "[^0-9]+", "ab12", 0 as c_uint)
    run_case(4, "\\d+", "ab12cd", 0 as c_uint)
    run_case(5, "a{2,3}", "aaaa", 0 as c_uint)
    run_case(6, "a+?", "aaaa", 0 as c_uint)
    run_case(7, "a++", "aaaa", 0 as c_uint)
    run_case(8, "a++b", "aaab", 0 as c_uint)
    run_case(9, "a+?b", "aaab", 0 as c_uint)
    run_case(10, "colou?r", "colour", 0 as c_uint)
    run_case(11, "a*", "bbb", 0 as c_uint)
    run_case(12, "a+", "bbb", 0 as c_uint)
    run_case(13, "^abc$", "abc", 0 as c_uint)
    run_case(14, "^abc$", "xabc", 0 as c_uint)
    run_case(15, "abc$", "xabc", 0 as c_uint)
    run_case(16, "\\bfoo\\b", "foo bar", 0 as c_uint)
    run_case(17, "\\bfoo\\b", "foobar", 0 as c_uint)
    run_case(18, "(a|b)\\1", "aa", 0 as c_uint)
    run_case(19, "(a|b)\\1", "ab", 0 as c_uint)
    run_case(20, "(a)(b)(c)", "abc", 0 as c_uint)
    run_case(21, "(?:ab)+", "ababab", 0 as c_uint)
    run_case(22, "(?P<w>\\w+)", "hi there", 0 as c_uint)
    run_case(23, "cat|dog", "dog", 0 as c_uint)
    run_case(24, "a|ab", "ab", 0 as c_uint)
    run_case(25, "foo(?=bar)", "foobar", 0 as c_uint)
    run_case(26, "foo(?=bar)", "foobaz", 0 as c_uint)
    run_case(27, "(?<=foo)bar", "foobar", 0 as c_uint)
    run_case(28, "foo(?!bar)", "foobaz", 0 as c_uint)
    run_case(29, "foo(?!bar)", "foobar", 0 as c_uint)
    run_case(30, "()", "abc", 0 as c_uint)
    run_case(31, "x?", "abc", 0 as c_uint)
    run_case(32, "", "abc", 0 as c_uint)
    run_case(33, "a*", "", 0 as c_uint)
    run_case(34, "(a)?b\\1", "b", 0 as c_uint)
    run_case(35, "(", "abc", 0 as c_uint)
    run_case(36, "a{2,1}", "a", 0 as c_uint)
    run_utf(37)
