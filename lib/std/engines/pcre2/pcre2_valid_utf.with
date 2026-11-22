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
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_xclass

// contract: stored-unknown:0,unproved:2:out-parameter written conditionally — stores an argument; ownership not modeled
pub unsafe fn _pcre2_valid_utf_8(__param_string: *const u8, __param_length: u64, __param_erroroffset: *mut u64) -> i32 {
    var __local_length = __param_length
    var __local_p: *const u8

    var __local_c: u32

    (__local_p = __param_string)

    while (__local_length > 0) {
        var __local_ab: u32

        var __local_d: u32


        (__local_c = (((*__local_p) as u32)))

        (__local_length = (__local_length -% 1))

        if (__local_c < 128) {
            (__local_p = __local_p + 1)

            continue

        }

        if (__local_c < 192) {
            ((*__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))

            return -22

        }

        if (__local_c >= 254) {
            ((*__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))

            return -23

        }

        (__local_ab = ((_pcre2_utf8_table4[((__local_c as u32) & (63 as u32))] as u32)))

        if (__local_length < __local_ab) {
            ((*__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))

            match ((__local_ab as u64) -% (__local_length as u64)) {
                1 => {
                    return -3
                },
                2 => {
                    return -4
                },
                3 => {
                    return -5
                },
                4 => {
                    return -6
                },
                5 => {
                    return -7
                },
            }

        }

        (__local_length = (__local_length -% __local_ab))

        (__local_p = __local_p + 1)

        (__local_d = (((*__local_p) as u32)))

        if (((__local_d as u32) & (192 as u32)) != 128) {
            ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (1 as u64)) as u64)))

            return -8

        }


        while true {
            match __local_ab {
                1 => {
                    if (((__local_c as u32) & (62 as u32)) == 0) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (1 as u64)) as u64)))

                        return -17

                    }
                },
                2 => {
                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (2 as u64)) as u64)))

                        return -9

                    }


                    var __ci_expr_logic_0: i32 = 0

                    if (__local_c == 224) {
                        (__ci_expr_logic_0 = (if ((__local_d as u32) & (32 as u32)) == 0: 1 else: 0))
                    }

                    if __ci_expr_logic_0 {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (2 as u64)) as u64)))

                        return -18

                    }


                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c == 237) {
                        (__ci_expr_logic_1 = (if __local_d >= 160: 1 else: 0))
                    }

                    if __ci_expr_logic_1 {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (2 as u64)) as u64)))

                        return -16

                    }


                },
                3 => {
                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (2 as u64)) as u64)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (3 as u64)) as u64)))

                        return -10

                    }


                    var __ci_expr_logic_2: i32 = 0

                    if (__local_c == 240) {
                        (__ci_expr_logic_2 = (if ((__local_d as u32) & (48 as u32)) == 0: 1 else: 0))
                    }

                    if __ci_expr_logic_2 {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (3 as u64)) as u64)))

                        return -19

                    }


                    var __ci_expr_logic_4: i32

                    if (__local_c > 244) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_3: i32 = 0

                        if (__local_c == 244) {
                            (__ci_expr_logic_3 = (if __local_d > 143: 1 else: 0))
                        }

                        (__ci_expr_logic_4 = (if __ci_expr_logic_3: 1 else: 0))

                    }

                    if __ci_expr_logic_4 {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (3 as u64)) as u64)))

                        return -15

                    }


                },
                4 => {
                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (2 as u64)) as u64)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (3 as u64)) as u64)))

                        return -10

                    }


                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (4 as u64)) as u64)))

                        return -11

                    }


                    var __ci_expr_logic_5: i32 = 0

                    if (__local_c == 248) {
                        (__ci_expr_logic_5 = (if ((__local_d as u32) & (56 as u32)) == 0: 1 else: 0))
                    }

                    if __ci_expr_logic_5 {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (4 as u64)) as u64)))

                        return -20

                    }


                },
                5 => {
                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (2 as u64)) as u64)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (3 as u64)) as u64)))

                        return -10

                    }


                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (4 as u64)) as u64)))

                        return -11

                    }


                    (__local_p = __local_p + 1)

                    if ((((*__local_p) as i32) & (192 as i32)) != 128) {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (5 as u64)) as u64)))

                        return -12

                    }


                    var __ci_expr_logic_6: i32 = 0

                    if (__local_c == 252) {
                        (__ci_expr_logic_6 = (if ((__local_d as u32) & (60 as u32)) == 0: 1 else: 0))
                    }

                    if __ci_expr_logic_6 {
                        ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (5 as u64)) as u64)))

                        return -21

                    }


                },
            }

            break

        }

        if (__local_ab > 3) {
            ((*__param_erroroffset) = ((((((((__local_p as usize) -% (__param_string as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% (__local_ab as u64)) as u64)))

            return (if __local_ab == 4: (-13 as i32) else: (-14 as i32))

        }


        (__local_p = __local_p + 1)

    }


    return 0

}
