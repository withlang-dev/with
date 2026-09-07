use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_compile
use std.re.pcre2_match
use std.re.pcre2_match_data
use std.re.pcre2_jit_compile
use std.re.pcre2_maketables

// r9: JIT stub on a live compiled code + maketables non-null path.
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

unsafe fn main:
    var ec: c_int = 0
    var eo: c_ulong = 0
    let code = pcre2_compile_8(to_cstr("a+b"), 3, 0, &raw mut ec, &raw mut eo, null)
    let md = pcre2_match_data_create_from_pattern_8(code, null)
    let jrc = pcre2_jit_compile_8(code, 1)
    let jmrc = pcre2_jit_match_8(code, str_data("aaab"), 4, 0, 0, md, null)
    let mrc = unsafe { (*md).rc }
    printf(c"jitcompile=%d jitmatch=%d mdrc=%d\n".ptr, jrc, jmrc, mrc)
    pcre2_jit_free_unused_memory_8(null)
    printf(c"jitfree-ok=1 jitstack-assign-null=1\n".ptr)
    pcre2_jit_stack_assign_8(null, null, null)
    // normal match still works (stub did not corrupt code)
    printf(c"plain rc=%d\n".ptr, pcre2_match_8(code, str_data("aaab"), 4, 0, 0, md, null))
    pcre2_match_data_free_8(md)
    pcre2_code_free_8(code)
    // maketables(gcontext): fresh tables equal default; free takes (g, tables)
    let g2 = pcre2_general_context_create_8(null as unsafe extern "C" fn(c_ulong, *mut c_void) -> *mut c_void, null as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, null)
    let t2 = pcre2_maketables_8(g2)
    var bad2: i32 = 0
    var j: i32 = 0
    while j < 1088:
        if unsafe { t2[j] } != _pcre2_default_tables_8[j]: bad2 = bad2 + 1
        j = j + 1
    printf(c"ctx-tables-bad=%d\n".ptr, bad2)
    pcre2_maketables_free_8(g2, t2)
    pcre2_general_context_free_8(g2)
    let _done = 0
