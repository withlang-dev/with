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
use std.re.pcre2_maketables
// use std.re.pcre2posix  // excluded — needs opaque type fix

extern fn malloc(size: c_ulong) -> *mut c_void
extern fn free(ptr: *mut c_void)

fn pcre2_malloc(size: c_ulong, data: *mut c_void) -> *mut c_void:
    malloc(size)

fn pcre2_free(ptr: *mut c_void, data: *mut c_void):
    free(ptr)

fn main:
    // The migrator doesn't translate static array initializers (#102), so the
    // PCRE2 OP_LENGTHS table that several internal functions index by opcode
    // is null until we manually point it at the static data.
    pcre2_init_op_lengths_8()
    // Create contexts with real malloc/free (bypasses zero-initialized defaults)
    let gcontext = pcre2_general_context_create_8(pcre2_malloc, pcre2_free, null)
    if gcontext as i64 == 0:
        print("gcontext creation failed")
        return
    print("gcontext ok")
    // Context fields are correctly stored (verified via raw read)
    let ccontext = pcre2_compile_context_create_8(gcontext)
    if ccontext as i64 == 0:
        print("ccontext creation failed")
        pcre2_general_context_free_8(gcontext)
        return
    // Set required defaults directly on struct fields (#102: struct initializers not migrated)
    (ccontext.max_pattern_length = (0 -% 1) as c_ulong)
    (ccontext.max_pattern_compiled_length = (0 -% 1) as c_ulong)
    (ccontext.parens_nest_limit = 250)
    (ccontext.max_varlookbehind = 255)
    (ccontext.newline_convention = 2)  // PCRE2_NEWLINE_LF
    (ccontext.bsr_convention = 0)
    (ccontext.optimization_flags = 4294967295)  // PCRE2_OPTIMIZATION_ALL
    // Generate character tables at runtime (the static tables weren't migrated, #102)
    let tables = pcre2_maketables_8(gcontext)
    (ccontext.tables = tables)
    print("ccontext ok")

    // Compile a simple pattern
    var error_code: c_int = 0
    var error_offset: c_ulong = 0
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
        var err_msg: [256]u8
        pcre2_get_error_message_8(error_code, (&mut err_msg[0] as *mut u8), 256 as c_ulong)
        print(f"compile failed: error {error_code} at offset {error_offset}")
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
