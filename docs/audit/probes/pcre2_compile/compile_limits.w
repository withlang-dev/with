// compile_limits — nest-limit + huge-repeat stress for pcre2_compile half.
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

unsafe fn run_case(tag: str, pattern: str, subject: str, gcontext: *mut pcre2_real_general_context_8, ccontext: *mut pcre2_real_compile_context_8):
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
        print(f"CASE {tag} COMPILE_FAIL code={error_code} off={error_offset} patlen={pattern.len()} subjlen={subject.len()}")
        return
    print(f"CASE {tag} COMPILE_OK patlen={pattern.len()} subjlen={subject.len()}")
    pcre2_code_free_8(code)

fn main:
    unsafe {
        let gcontext = pcre2_general_context_create_8(null, null, null)
        let ccontext = pcre2_compile_context_create_8(gcontext)
        (ccontext.max_pattern_length = (0 -% 1) as c_ulong)
        (ccontext.max_pattern_compiled_length = (0 -% 1) as c_ulong)
        (ccontext.parens_nest_limit = 250)
        (ccontext.max_varlookbehind = 255)
        (ccontext.newline_convention = 2)
        (ccontext.bsr_convention = 0)
        (ccontext.optimization_flags = 4294967295)
        let tables = pcre2_maketables_8(gcontext)
        (ccontext.tables = tables)
        run_case("deep200", "((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((a))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))", "a", gcontext, ccontext)
        run_case("deep300", "((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((a))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))", "a", gcontext, ccontext)
        run_case("bigrep-ok", "a{65535}", "a", gcontext, ccontext)
        run_case("bigrep-huge", "a{100000}", "a", gcontext, ccontext)
        pcre2_compile_context_free_8(ccontext)
        pcre2_general_context_free_8(gcontext)
        print("DONE")
    }
