// Migrated from C
use std.re.defs
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
use std.re.pcre2_ord2utf
use std.re.pcre2_script_run
use std.re.pcre2_string_utils
use std.re.pcre2_study
use std.re.pcre2_valid_utf
use std.re.pcre2_xclass

pub unsafe fn pcre2_config_8(__param_what: c_uint, __param_where_: *mut c_void) -> c_int {
    if ((if __param_where_ == null: 1 else: 0) != 0) {
        while true {
            match __param_what {
                0 => {
                    return 4
                },
                14 => {
                    return 4
                },
                7 => {
                    return 4
                },
                16 => {
                    return 4
                },
                12 => {
                    return 4
                },
                1 => {
                    return 4
                },
                3 => {
                    return 4
                },
                4 => {
                    return 4
                },
                13 => {
                    return 4
                },
                5 => {
                    return 4
                },
                6 => {
                    return 4
                },
                8 => {
                    return 4
                },
                15 => {
                    return 4
                },
                9 => {
                    return 4
                },
                2 => {
                    0
                },
                10 => {
                    0
                },
                11 => {
                    0
                },
                _ => {
                    return -34
                },
            }

            break

        }

    }

    while true {
        match __param_what {
            0 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((1 as c_uint)))
            },
            14 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((1 as c_uint)))
            },
            7 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((10000000 as c_uint)))
            },
            16 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((2 as c_uint)))
            },
            12 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((20000000 as c_uint)))
            },
            1 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((0 as c_uint)))
            },
            2 => {
                return -34
            },
            3 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((2 as c_uint)))
            },
            4 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((10000000 as c_uint)))
            },
            5 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((2 as c_uint)))
            },
            13 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((0 as c_uint)))
            },
            6 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((250 as c_uint)))
            },
            8 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((0 as c_uint)))
            },
            15 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((1088 as c_uint)))
            },
            10 => {
                var __local_v: *const c_char = ((_pcre2_unicode_version_8 as *const c_char))

                var __ci_expr_ternary_1: c_ulong = 0

                if ((if __param_where_ == null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = ((strlen(__local_v) as c_ulong)))
                } else {
                    (__ci_expr_ternary_1 = ((_pcre2_strcpy_c8_8((__param_where_ as *mut u8), __local_v) as c_ulong)))
                }

                return ((((1 as c_ulong) +% (__ci_expr_ternary_1 as c_ulong)) as c_int))


            },
            9 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((1 as c_uint)))
            },
            11 => {
                var __local_v_1: *const c_char = with 0 as __ci_expr_seq_43 {
                    var __ci_expr_ternary_2: *mut c_char = null
                    if ((if 0 == 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_2 = (("10.47 2025-10-21" as *mut c_char)))
                    } else {
                        (__ci_expr_ternary_2 = (("10.47PCRE2_PRERELEASE 2025-10-21" as *mut c_char)))
                    }
                    (__ci_expr_ternary_2 as *const c_char)
                }

                var __ci_expr_ternary_3: c_ulong = 0

                if ((if __param_where_ == null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = ((strlen(__local_v_1) as c_ulong)))
                } else {
                    (__ci_expr_ternary_3 = ((_pcre2_strcpy_c8_8((__param_where_ as *mut u8), __local_v_1) as c_ulong)))
                }

                return ((((1 as c_ulong) +% (__ci_expr_ternary_3 as c_ulong)) as c_int))


            },
            _ => {
                return -34
            },
        }

        break

    }

    return 0

}
