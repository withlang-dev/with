// Focused probe: dump raw ovector after pcre2_dfa_match_8 regardless of rc.
use std.builtins.print_i32
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_maketables
use std.re.pcre2_match_data
use std.re.pcre2_dfa_match

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

fn run(idx: i32, pat: &str, subj: &str):
    print("DFAV ")
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
    let code = unsafe { pcre2_compile_8(cpat, pat.len() as c_ulong, 0 as c_uint, &raw mut ec, &raw mut eo, &raw mut cc) }
    with_free(cpat as *mut u8)
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, g) }
    let ws = with_alloc(400)
    for i in 0..100 as i32:
        unsafe { *((ws as i64 + (i * 4) as i64) as *mut c_int) = 0 }
    let drc = unsafe { pcre2_dfa_match_8(code, str_data(subj), subj.len() as c_ulong, 0 as c_ulong, 0 as c_uint, md, null, ws as *mut c_int, 100 as c_ulong) }
    print("WS")
    for i in 0..8 as i32:
        print(" ")
        print_i32(unsafe { *((ws as i64 + (i * 4) as i64) as *const c_int) })
    print("\n")
    with_free(ws as *mut u8)
    print("RC ")
    print_i32(drc)
    print("\n")
    print("MDRC ")
    print_i32(unsafe { (*md).rc })
    print("\n")
    print("OVCOUNT ")
    print_i32(unsafe { pcre2_get_ovector_count_8(md) } as i32)
    print("\n")
    let ov = unsafe { pcre2_get_ovector_pointer_8(md) }
    print("RAW")
    for i in 0..4 as i32:
        let start = unsafe { *(ov + ((i * 2) as isize)) }
        let end_pos = unsafe { *(ov + ((i * 2 + 1) as isize)) }
        print(" ")
        if start == (0 -% 1) as c_ulong:
            print("U")
        else:
            print_i32(start as i32)
            print(":")
            print_i32(end_pos as i32)
    print("\n")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_code_free_8(code) }
    unsafe { pcre2_general_context_free_8(g) }

fn main:
    run(0, "a|ab", "ab")
    run(1, "(ab|a)(c)", "abc")
    run(2, "foo|foobar", "xfoobarx")
