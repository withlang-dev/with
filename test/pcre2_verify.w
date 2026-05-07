// pcre2_verify — ground-truth integration harness for migrated PCRE2.
//
// Takes pattern and subject from argv, compiles with the migrated
// PCRE2 library in lib/std/re, matches once, and prints output in
// the same line format as upstream pcre2test:
//   " N: <matched text>"     — capture group N
//   "No match"               — subject doesn't match pattern
//   "Error: compile failed at offset M (code C)"  — compile error
//
// This lets scripts/verify_pcre2_works.sh diff our output against
// `pcre2test` byte-for-byte across a corpus of patterns.

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
use std.re.pcre2_maketables

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn malloc(size: c_ulong) -> *mut c_void
extern fn free(ptr: *mut c_void)

fn pcre2_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    malloc(size)

fn pcre2_free(ptr: *mut c_void, data: *mut c_void):
    free(ptr)

fn main:
    if with_arg_count() < 3:
        print("usage: pcre2_verify <pattern> <subject>\n")
        return

    let pattern = with_arg_at(1)
    let subject = with_arg_at(2)

    // Runtime init: set context defaults by hand. These steps are independent
    // of the pattern/subject under test — they set up PCRE2's runtime state.
    let gcontext = pcre2_general_context_create_8(pcre2_malloc, pcre2_free, null)
    if gcontext as i64 == 0:
        print("Error: gcontext creation failed\n")
        return

    let ccontext = pcre2_compile_context_create_8(gcontext)
    if ccontext as i64 == 0:
        print("Error: ccontext creation failed\n")
        pcre2_general_context_free_8(gcontext)
        return

    (ccontext.max_pattern_length = (0 -% 1) as c_ulong)
    (ccontext.max_pattern_compiled_length = (0 -% 1) as c_ulong)
    (ccontext.parens_nest_limit = 250)
    (ccontext.max_varlookbehind = 255)
    (ccontext.newline_convention = 2)
    (ccontext.bsr_convention = 0)
    (ccontext.optimization_flags = 4294967295)
    let tables = pcre2_maketables_8(gcontext)
    (ccontext.tables = tables)

    // Compile
    var error_code: c_int = 0
    var error_offset: c_ulong = 0
    let code = pcre2_compile_8(
        (pattern as *const u8),
        pattern.len() as c_ulong,
        0 as c_uint,
        (&raw mut error_code as *mut c_int),
        (&raw mut error_offset as *mut c_ulong),
        ccontext
    )
    if code as i64 == 0:
        print(f"Error: compile failed at offset {error_offset} (code {error_code})\n")
        pcre2_compile_context_free_8(ccontext)
        pcre2_general_context_free_8(gcontext)
        return

    // Match
    let mcontext = pcre2_match_context_create_8(gcontext)
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
        print("No match\n")
    else:
        // Print matched text for each capture group, pcre2test-style.
        // pcre2test right-aligns group numbers in a 2-char field:
        //   " 0: ..."  for single-digit groups
        //   "10: ..."  for two-digit groups
        let ov = pcre2_get_ovector_pointer_8(md)
        var i: c_uint = 0
        let group_count = rc as c_uint
        while i < group_count:
            let start = unsafe: *(ov + ((i * 2) as isize))
            let end_pos = unsafe: *(ov + ((i * 2 + 1) as isize))
            let prefix = if i < 10: f" {i}: " else: f"{i}: "
            // Group didn't participate: offset is PCRE2_UNSET (~0)
            if start == (0 -% 1) as c_ulong:
                print(f"{prefix}<unset>\n")
            else:
                let matched = subject.slice(start as i64, end_pos as i64)
                print(f"{prefix}{matched}\n")
            i = i + 1

    pcre2_match_data_free_8(md)
    pcre2_match_context_free_8(mcontext)
    pcre2_code_free_8(code)
    pcre2_compile_context_free_8(ccontext)
    pcre2_general_context_free_8(gcontext)
