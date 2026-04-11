// Smoke test: compile a regex and match against a string using
// the With-migrated PCRE2 library.

use std.re.defs
use std.re.pcre2_tables
use std.re.pcre2_ucd
use std.re.pcre2_chartables
use std.re.pcre2_string_utils
use std.re.pcre2_newline
use std.re.pcre2_valid_utf
use std.re.pcre2_ord2utf
use std.re.pcre2_extuni
use std.re.pcre2_find_bracket
use std.re.pcre2_context
use std.re.pcre2_error
use std.re.pcre2_auto_possess
use std.re.pcre2_study
use std.re.pcre2_xclass
use std.re.pcre2_chkdint
use std.re.pcre2_compile_class
use std.re.pcre2_compile_cgroup
use std.re.pcre2_compile
use std.re.pcre2_config
use std.re.pcre2_match_data
use std.re.pcre2_match_next
use std.re.pcre2_match
use std.re.pcre2_dfa_match
use std.re.pcre2_substitute
use std.re.pcre2_substring
use std.re.pcre2_pattern_info
use std.re.pcre2_serialize
use std.re.pcre2_convert
use std.re.pcre2_script_run
use std.re.pcre2posix

extern fn malloc(size: c_ulong) -> *mut c_void
extern fn free(ptr: *mut c_void)

fn pcre2_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    malloc(size)

fn pcre2_free(ptr: *mut c_void, data: *mut c_void):
    free(ptr)

fn main:
    // Create contexts with real malloc/free (bypasses zero-initialized defaults)
    let gcontext = pcre2_general_context_create_8(pcre2_malloc, pcre2_free, null)
    if gcontext as i64 == 0:
        print("gcontext creation failed")
        return
    print("gcontext ok")
    let ccontext = pcre2_compile_context_create_8(gcontext)
    if ccontext as i64 == 0:
        print("ccontext creation failed")
        pcre2_general_context_free_8(gcontext)
        return
    print("ccontext ok")

    // Compile a simple pattern
    var error_code: c_int
    var error_offset: c_ulong
    let pattern = "abc"
    let code = pcre2_compile_8(
        (pattern as *const u8),
        pattern.len() as c_ulong,
        0 as c_uint,
        (&mut error_code as *mut c_int),
        (&mut error_offset as *mut c_ulong),
        ccontext
    )
    if code as i64 == 0:
        print(f"compile failed: error {error_code} at offset {error_offset}")
        if ccontext as i64 != 0:
            pcre2_compile_context_free_8(ccontext)
        if gcontext as i64 != 0:
            pcre2_general_context_free_8(gcontext)
        return

    print("compile ok")

    // Match against a subject
    let mcontext = pcre2_match_context_create_8(gcontext)
    let subject = "xabcdef"
    let md = pcre2_match_data_create_from_pattern_8(code, gcontext)
    let rc = pcre2_match_8(
        code,
        (subject as *const u8),
        subject.len() as c_ulong,
        0 as c_ulong,
        0 as c_uint,
        md,
        mcontext
    )
    if rc < 0:
        print(f"match failed: {rc}")
    else:
        print(f"match ok: {rc} capture groups")
        let ov = pcre2_get_ovector_pointer_8(md)
        if ov as i64 != 0:
            let start = unsafe: *ov
            let end_pos = unsafe: *(ov + 1)
            print(f"match at [{start}, {end_pos})")

    pcre2_match_data_free_8(md)
    pcre2_match_context_free_8(mcontext)
    pcre2_code_free_8(code)
    pcre2_compile_context_free_8(ccontext)
    pcre2_general_context_free_8(gcontext)
    print("ok")
