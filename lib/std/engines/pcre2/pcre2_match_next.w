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
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass

// contract: receiver:pcre2_real_match_data_8,unproved:1:out-parameter a return before the write,unproved:2:out-parameter a return before the write
pub unsafe fn pcre2_next_match_8(__param_match_data: *mut pcre2_real_match_data_8, __param_pstart_offset: *mut u64, __param_poptions: *mut u32) -> i32 {
    var __local_rc: i32 = (*__param_match_data).rc

    var __local_start_offset: u64 = (*__param_match_data).start_offset

    var __local_ovector: *mut u64 = ((&raw const (*__param_match_data).ovector[0] as *mut u64))

    if (__local_rc < 0) {
        return 0
    }

    loop {
        0
        if not (false) {
            break
        }
    }

    var __ci_expr_logic_0: i32 = 0

    if ((__local_ovector[0]) != __local_start_offset) {
        (__ci_expr_logic_0 = (if (__local_ovector[1]) == __local_start_offset: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        if (__local_start_offset >= (*__param_match_data).subject_length) {
            return 0
        }

        ((*__param_pstart_offset) = ((do_bumpalong(__param_match_data, ((__local_ovector[1]) as u64)) as u64)))

        ((*__param_poptions) = ((0 as u32)))

        return 1

    }


    if ((__local_ovector[0]) == (__local_ovector[1])) {
        if ((__local_ovector[0]) >= (*__param_match_data).subject_length) {
            return 0
        }

        ((*__param_pstart_offset) = (((__local_ovector[1]) as u64)))

        ((*__param_poptions) = ((8 as u32)))

        return 1

    }

    ((*__param_pstart_offset) = (((__local_ovector[1]) as u64)))

    ((*__param_poptions) = ((0 as u32)))

    return 1

}

unsafe fn do_bumpalong(__param_match_data: *mut pcre2_real_match_data_8, __param_offset: u64) -> u64 {
    var __local_subject: *const u8 = (*__param_match_data).subject

    var __local_subject_length: u64 = (*__param_match_data).subject_length

    var __local_utf: i32 = (((if (((*(*__param_match_data).code).overall_options as u32) & (524288 as u32)) != 0: 1 else: 0) as i32))

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    if ((__local_subject[__param_offset]) == 13) {
        (__ci_expr_logic_0 = (if ((__param_offset as u64) +% (1 as u64)) < __local_subject_length: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_logic_1 = (if (__local_subject[((__param_offset as u64) +% (1 as u64))]) == 10: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        match (*(*__param_match_data).code).newline_convention {
            3 => {
                return ((__param_offset as u64) +% (2 as u64))
            },
            4 => {
                return ((__param_offset as u64) +% (2 as u64))
            },
            5 => {
                return ((__param_offset as u64) +% (2 as u64))
            },
        }

    }


    if __local_utf {
        var __local_next: *const u8 = ((__local_subject + (__param_offset as usize)) + ((1 as isize) as usize))

        var __local_subject_end: *const u8 = (__local_subject + (__local_subject_length as usize))


        while true {
            var __ci_expr_logic_2: i32 = 0

            if (__local_next < __local_subject_end) {
                (__ci_expr_logic_2 = (if ((((*__local_next) as i32) as u32) & (192 as u32)) == 128: 1 else: 0))
            }

            if (not __ci_expr_logic_2) {
                break
            }

            (__local_next = __local_next + 1)

        }

        return ((((((__local_next as usize) -% (__local_subject as usize)) as i64) / (sizeof[u8]() as i64)) as u64))

    }

    return ((__param_offset as u64) +% (1 as u64))

}
