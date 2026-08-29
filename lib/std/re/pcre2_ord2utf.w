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
use std.re.pcre2_chkdint
use std.re.pcre2_extuni
use std.re.pcre2_find_bracket
use std.re.pcre2_newline
use std.re.pcre2_script_run
use std.re.pcre2_string_utils
use std.re.pcre2_study
use std.re.pcre2_valid_utf
use std.re.pcre2_xclass

pub unsafe fn _pcre2_ord2utf_8(__param_cvalue: c_uint, __param_buffer: *mut u8) -> c_uint {
    var __local_cvalue = __param_cvalue
    var __local_buffer = __param_buffer
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < _pcre2_utf8_table1_size: 1 else: 0) != 0) {
        if ((if ((__local_cvalue as c_int)) <= _pcre2_utf8_table1[__local_i]: 1 else: 0) != 0) {
            break
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_buffer = __local_buffer + (__local_i as usize))

    var __local_j: c_uint = __local_i

    while ((if __local_j != 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = __local_buffer

        (__local_buffer = __local_buffer - 1)

        ((unsafe *__ci_expr_old_0) = ((((128 as c_uint) | (((__local_cvalue as c_uint) & (63 as c_uint)) as c_uint)) as u8)))


        (__local_cvalue = __local_cvalue >> (6 as c_uint))


        (__local_j = (__local_j -% 1))

    }


    ((unsafe *__local_buffer) = ((((_pcre2_utf8_table2[__local_i] as c_int) | ((__local_cvalue as c_int) as c_int)) as u8)))

    return ((__local_i as c_uint) +% (1 as c_uint))

}
