// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
use std.engines.pcre2.pcre2_compile
use std.engines.pcre2.pcre2_pattern_info
use std.engines.pcre2.pcre2_match_data
use std.engines.pcre2.pcre2_dfa_match
use std.engines.pcre2.pcre2_match
use std.engines.pcre2.pcre2_match_next
use std.engines.pcre2.pcre2_substring
use std.engines.pcre2.pcre2_serialize
use std.engines.pcre2.pcre2_substitute
use std.engines.pcre2.pcre2_jit_compile
use std.engines.pcre2.pcre2_error
use std.engines.pcre2.pcre2_maketables
use std.engines.pcre2.pcre2_tables
use std.engines.pcre2.pcre2_chartables
use std.engines.pcre2.pcre2_ucd
use std.engines.pcre2.pcre2_auto_possess
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass
use std.libc

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

    if ((if (sizeof[c_longlong]() as usize) > (sizeof[c_ulong]() as usize): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_m > ((libc.UINTPTR_MAX as c_longlong)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 1
    }


    ((*__param_r) = ((__local_m as c_ulong)))

    return 0

}
