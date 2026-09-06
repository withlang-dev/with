// Engine probes, part 2: pcre2_dfa_match_8 and pcre2_next_match_8 global loop.
// Output:
//   DFA <idx> RC <rc|NOMATCH n> OV <s e ...>
//   GLOB <idx> M <s e> ... (one line per global iteration) / GLOB <idx> NOMATCH
use std.builtins.print_i32
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_maketables
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_match_next
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

fn setup() -> *mut pcre2_real_general_context_8:
    unsafe { pcre2_general_context_create_8(my_malloc, my_free, null) }

fn compile_pat(g: *mut pcre2_real_general_context_8, pat: &str) -> *mut pcre2_real_code_8:
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
    code

fn print_ov(md: *mut pcre2_real_match_data_8, rc: c_int):
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

fn run_dfa(idx: i32, pat: &str, subj: &str):
    print("DFA ")
    print_i32(idx)
    print("\n")
    let g = setup()
    let code = compile_pat(g, pat)
    if code as i64 == 0:
        print("RC COMPILEFAIL\n")
        unsafe { pcre2_general_context_free_8(g) }
        return
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, g) }
    let ws = with_alloc(400)
    let drc = unsafe { pcre2_dfa_match_8(code, str_data(subj), subj.len() as c_ulong, 0 as c_ulong, 0 as c_uint, md, null, ws as *mut c_int, 100 as c_ulong) }
    with_free(ws as *mut u8)
    if drc < 0:
        print("RC NOMATCH ")
        print_i32(drc)
        print("\n")
    else:
        print("RC ")
        print_i32(drc)
        print("\n")
        print_ov(md, drc)
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_code_free_8(code) }
    unsafe { pcre2_general_context_free_8(g) }

fn run_global(idx: i32, pat: &str, subj: &str):
    print("GLOB ")
    print_i32(idx)
    print("\n")
    let g = setup()
    let code = compile_pat(g, pat)
    if code as i64 == 0:
        print("COMPILEFAIL\n")
        unsafe { pcre2_general_context_free_8(g) }
        return
    let mcontext = unsafe { pcre2_match_context_create_8(g) }
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, g) }
    let rc = unsafe { pcre2_match_8(code, str_data(subj), subj.len() as c_ulong, 0 as c_ulong, 0 as c_uint, md, mcontext) }
    if rc < 0:
        print("NOMATCH ")
        print_i32(rc)
        print("\n")
    else:
        let ov = unsafe { pcre2_get_ovector_pointer_8(md) }
        print("M ")
        print_i32(unsafe { *ov } as i32)
        print(" ")
        print_i32(unsafe { *(ov + 1) } as i32)
        print("\n")
        var start: c_ulong = 0
        var opts: c_uint = 0
        var guard: i32 = 0
        while unsafe { pcre2_next_match_8(md, &raw mut start, &raw mut opts) } == 1:
            guard = guard + 1
            if guard > 20:
                print("LOOPCAP\n")
                break
            let rc2 = unsafe { pcre2_match_8(code, str_data(subj), subj.len() as c_ulong, start, opts, md, mcontext) }
            if rc2 < 0:
                print("M FAIL ")
                print_i32(rc2)
                print("\n")
                break
            let ov2 = unsafe { pcre2_get_ovector_pointer_8(md) }
            print("M ")
            print_i32(unsafe { *ov2 } as i32)
            print(" ")
            print_i32(unsafe { *(ov2 + 1) } as i32)
            print("\n")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_match_context_free_8(mcontext) }
    unsafe { pcre2_code_free_8(code) }
    unsafe { pcre2_general_context_free_8(g) }

fn main:
    run_dfa(0, "a|ab", "ab")
    run_dfa(1, "foo|foobar", "xfoobarx")
    run_dfa(2, "(ab|a)(c)", "abc")
    run_dfa(3, "a+", "bbb")
    run_global(0, "\\w+", "hi there")
    run_global(1, "a*", "aa")
    run_global(2, "x?", "ab")
