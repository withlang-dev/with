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
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass

pub unsafe fn _pcre2_is_newline_8(__param_ptr: *const u8, __param_type_: u32, __param_endptr: *const u8, __param_lenptr: *mut u32, __param_utf: i32) -> i32 {
    var __local_c: u32

    if (__param_utf != 0) {
        (__local_c = (((*__param_ptr) as u32)))

        if ((if __local_c >= 192: 1 else: 0) != 0) {
            if ((if ((__local_c as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
                (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((__param_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
            } else {
                if ((if ((__local_c as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
                    (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((__param_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__param_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                } else {
                    if ((if ((__local_c as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
                        (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((__param_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__param_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__param_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                    } else {
                        if ((if ((__local_c as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
                            (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((__param_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__param_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__param_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__param_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                        } else {
                            (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((__param_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__param_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__param_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__param_ptr[4]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__param_ptr[5]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                        }
                    }
                }
            }

        }



    } else {
        (__local_c = (((*__param_ptr) as u32)))
    }

    if ((if __param_type_ == 2: 1 else: 0) != 0) {
        match __local_c {
            10 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            13 => {
                var __ci_expr_ternary_1: i32 = 0

                var __ci_expr_logic_0: i32 = 0

                if ((if __param_ptr < (__param_endptr - ((1 as isize) as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (__param_ptr[1]) == 10: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_ternary_1 = ((2 as i32)))
                } else {
                    (__ci_expr_ternary_1 = ((1 as i32)))
                }

                ((*__param_lenptr) = ((__ci_expr_ternary_1 as u32)))


                return 1

            },
            _ => {
                return 0
            },
        }
    } else {
        match __local_c {
            10 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            11 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            12 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            13 => {
                var __ci_expr_ternary_3: i32 = 0

                var __ci_expr_logic_2: i32 = 0

                if ((if __param_ptr < (__param_endptr - ((1 as isize) as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (__param_ptr[1]) == 10: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_ternary_3 = ((2 as i32)))
                } else {
                    (__ci_expr_ternary_3 = ((1 as i32)))
                }

                ((*__param_lenptr) = ((__ci_expr_ternary_3 as u32)))


                return 1

            },
            133 => {
                ((*__param_lenptr) = (((if __param_utf != 0: (2 as i32) else: (1 as i32)) as u32)))

                return 1

            },
            8232 => {
                ((*__param_lenptr) = ((3 as u32)))

                return 1

            },
            8233 => {
                ((*__param_lenptr) = ((3 as u32)))

                return 1

            },
            _ => {
                return 0
            },
        }
    }

}

pub unsafe fn _pcre2_was_newline_8(__param_ptr: *const u8, __param_type_: u32, __param_startptr: *const u8, __param_lenptr: *mut u32, __param_utf: i32) -> i32 {
    var __local_ptr = __param_ptr
    var __local_c: u32

    (__local_ptr = __local_ptr - 1)

    if (__param_utf != 0) {
        while ((if ((((*__local_ptr) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0) {
            (__local_ptr = __local_ptr - 1)
        }

        (__local_c = (((*__local_ptr) as u32)))

        if ((if __local_c >= 192: 1 else: 0) != 0) {
            if ((if ((__local_c as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
                (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
            } else {
                if ((if ((__local_c as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
                    (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                } else {
                    if ((if ((__local_c as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
                        (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                    } else {
                        if ((if ((__local_c as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
                            (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                        } else {
                            (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[5]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                        }
                    }
                }
            }

        }



    } else {
        (__local_c = (((*__local_ptr) as u32)))
    }

    if ((if __param_type_ == 2: 1 else: 0) != 0) {
        match __local_c {
            10 => {
                var __ci_expr_ternary_1: i32 = 0

                var __ci_expr_logic_0: i32 = 0

                if ((if __local_ptr > __param_startptr: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (__local_ptr[-1]) == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_ternary_1 = ((2 as i32)))
                } else {
                    (__ci_expr_ternary_1 = ((1 as i32)))
                }

                ((*__param_lenptr) = ((__ci_expr_ternary_1 as u32)))


                return 1

            },
            13 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            _ => {
                return 0
            },
        }
    } else {
        match __local_c {
            10 => {
                var __ci_expr_ternary_3: i32 = 0

                var __ci_expr_logic_2: i32 = 0

                if ((if __local_ptr > __param_startptr: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (__local_ptr[-1]) == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_ternary_3 = ((2 as i32)))
                } else {
                    (__ci_expr_ternary_3 = ((1 as i32)))
                }

                ((*__param_lenptr) = ((__ci_expr_ternary_3 as u32)))


                return 1

            },
            11 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            12 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            13 => {
                ((*__param_lenptr) = ((1 as u32)))

                return 1

            },
            133 => {
                ((*__param_lenptr) = (((if __param_utf != 0: (2 as i32) else: (1 as i32)) as u32)))

                return 1

            },
            8232 => {
                ((*__param_lenptr) = ((3 as u32)))

                return 1

            },
            8233 => {
                ((*__param_lenptr) = ((3 as u32)))

                return 1

            },
            _ => {
                return 0
            },
        }
    }

}
