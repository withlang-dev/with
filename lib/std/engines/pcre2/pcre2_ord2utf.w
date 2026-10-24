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
use std.engines.pcre2.pcre2_chkdint
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass

pub unsafe fn _pcre2_ord2utf_8(__param_cvalue: u32, __param_buffer: *mut u8) -> u32 {
    var __local_cvalue = __param_cvalue
    var __local_buffer = __param_buffer
    var __local_i: u32

    (__local_i = ((0 as u32)))

    while ((if __local_i < _pcre2_utf8_table1_size: 1 else: 0) != 0) {
        if ((if ((__local_cvalue as i32)) <= _pcre2_utf8_table1[__local_i]: 1 else: 0) != 0) {
            break
        }

        (__local_i = (__local_i +% 1))

    }


    (__local_buffer = __local_buffer + (__local_i as usize))

    var __local_j: u32 = __local_i

    while ((if __local_j != 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = __local_buffer

        (__local_buffer = __local_buffer - 1)

        ((*__ci_expr_old_0) = ((((128 as u32) | (((__local_cvalue as u32) & (63 as u32)) as u32)) as u8)))


        (__local_cvalue = __local_cvalue >> (6 as u32))


        (__local_j = (__local_j -% 1))

    }


    ((*__local_buffer) = ((((_pcre2_utf8_table2[__local_i] as i32) | (__local_cvalue as i32)) as u8)))

    return ((__local_i as u32) +% (1 as u32))

}
