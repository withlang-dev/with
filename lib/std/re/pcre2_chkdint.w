// Migrated from C
use std.re.defs
use std.re.pcre2_config
use std.re.pcre2_context
use std.re.pcre2_convert
use std.re.pcre2_compile
use std.re.pcre2_pattern_info
use std.re.pcre2_match_data
use std.re.pcre2_dfa_match
use std.re.pcre2_match
use std.re.pcre2_match_next
use std.re.pcre2_substring
use std.re.pcre2_serialize
use std.re.pcre2_substitute
use std.re.pcre2_jit_compile
use std.re.pcre2_error
use std.re.pcre2_maketables
use std.re.pcre2_tables
use std.re.pcre2_chartables
use std.re.pcre2_ucd
use std.re.pcre2_auto_possess
use std.re.pcre2_extuni
use std.re.pcre2_find_bracket
use std.re.pcre2_newline
use std.re.pcre2_ord2utf
use std.re.pcre2_script_run
use std.re.pcre2_string_utils
use std.re.pcre2_study
use std.re.pcre2_valid_utf
use std.re.pcre2_xclass

pub unsafe fn _pcre2_ckd_smul_8(__param_r: *mut c_ulong, __param_a: c_int, __param_b: c_int) -> c_int {
    var __local_m: c_longlong

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    (__local_m = ((((__param_a as c_longlong) * (__param_b as c_longlong)) as c_longlong)))

    var __ci_expr_logic_0: c_int = 0

    if ((if sizeof[c_longlong]() > sizeof[c_ulong](): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_m > ((((0 as c_ulong) -% 1) as c_longlong)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 1
    }


    ((unsafe *__param_r) = ((__local_m as c_ulong)))

    return 0

}
