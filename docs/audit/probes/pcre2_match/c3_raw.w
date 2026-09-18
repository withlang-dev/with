use std.builtins.print
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

fn try_match(pat: &str, subj: &str):
    print("--- pat=")
    print(pat)
    print(" subj=")
    print(subj)
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
    let code = unsafe { pcre2_compile_8(cpat, pat.len() as c_ulong, 0, &raw mut ec, &raw mut eo, &raw mut cc) }
    with_free(cpat as *mut u8)
    if code as i64 == 0:
        print("compile-fail ec=")
        print_i32(ec)
        print("\n")
        unsafe { pcre2_general_context_free_8(g) }
        return
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, g) }
    let rc = unsafe { pcre2_match_8(code, str_data(subj), subj.len() as c_ulong, 0, 0, md, null) }
    print("rc=")
    print_i32(rc)
    print(" mdrc=")
    print_i32(unsafe { (*md).rc })
    print(" oveccount=")
    print_i32(unsafe { pcre2_get_ovector_count_8(md) } as i32)
    print("\n")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_general_context_free_8(g) }

fn main:
    try_match("", "")
    try_match("a", "a")
    try_match("a*", "bbb")
