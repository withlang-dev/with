// Migrated from C
use std.re.defs
use std.re.pcre2_config
use std.re.pcre2_context
use std.re.pcre2_convert
use std.re.pcre2_compile
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

pub unsafe fn pcre2_pattern_info_8(__param_code: *const pcre2_real_code_8, __param_what: c_uint, __param_where_: *mut c_void) -> c_int {
    var __local_re: *const pcre2_real_code_8 = __param_code

    if ((if __param_where_ == null: 1 else: 0) != 0) {
        match __param_what {
            0 => {
                return 4
            },
            1 => {
                return 4
            },
            2 => {
                return 4
            },
            3 => {
                return 4
            },
            4 => {
                return 4
            },
            21 => {
                return 4
            },
            26 => {
                return 4
            },
            6 => {
                return 4
            },
            5 => {
                return 4
            },
            23 => {
                return 4
            },
            8 => {
                return 4
            },
            25 => {
                return 4
            },
            9 => {
                return 4
            },
            12 => {
                return 4
            },
            11 => {
                return 4
            },
            13 => {
                return 4
            },
            14 => {
                return 4
            },
            15 => {
                return 4
            },
            16 => {
                return 4
            },
            18 => {
                return 4
            },
            17 => {
                return 4
            },
            20 => {
                return 4
            },
            7 => {
                return 8
            },
            10 => {
                return 8
            },
            22 => {
                return 8
            },
            24 => {
                return 8
            },
            19 => {
                return 8
            },
        }

    }

    if ((if __local_re == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if (unsafe *__local_re).magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if (((unsafe *__local_re).flags as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0) {
        return -32
    }

    while true {
        match __param_what {
            0 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (unsafe *__local_re).overall_options)
            },
            1 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (unsafe *__local_re).compile_options)
            },
            2 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).top_backref as c_uint)))
            },
            3 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).bsr_convention as c_uint)))
            },
            4 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).top_bracket as c_uint)))
            },
            21 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (unsafe *__local_re).limit_depth)

                if ((if (unsafe *__local_re).limit_depth == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            26 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (unsafe *__local_re).extra_options)
            },
            6 => {
                var __ci_expr_ternary_1: c_int = 0

                if ((if (((unsafe *__local_re).flags as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = ((1 as c_int)))
                } else {
                    var __ci_expr_ternary_0: c_int = 0

                    if ((if (((unsafe *__local_re).flags as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_0 = ((2 as c_int)))
                    } else {
                        (__ci_expr_ternary_0 = ((0 as c_int)))
                    }

                    (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                }

                ((unsafe *(__param_where_ as *mut c_uint)) = ((__ci_expr_ternary_1 as c_uint)))

            },
            5 => {
                var __ci_expr_ternary_2: c_uint = 0

                if ((if (((unsafe *__local_re).flags as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_2 = (unsafe *__local_re).first_codeunit)
                } else {
                    (__ci_expr_ternary_2 = ((0 as c_uint)))
                }

                ((unsafe *(__param_where_ as *mut c_uint)) = __ci_expr_ternary_2)

            },
            7 => {
                var __ci_expr_ternary_3: *const u8 = null

                if ((if (((unsafe *__local_re).flags as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = ((&raw const (unsafe *__local_re).start_bitmap[0] as *const u8)))
                } else {
                    (__ci_expr_ternary_3 = ((null as *const u8)))
                }

                ((unsafe *(__param_where_ as *mut *const u8)) = __ci_expr_ternary_3)

            },
            24 => {
                ((unsafe *(__param_where_ as *mut c_ulong)) = ((((136 as c_ulong) +% ((((((unsafe *__local_re).top_bracket as c_int) * 2) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong)) as c_ulong)))
            },
            23 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((if (((unsafe *__local_re).flags as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) as c_uint)))
            },
            8 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((if (((unsafe *__local_re).flags as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) as c_uint)))
            },
            25 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (unsafe *__local_re).limit_heap)

                if ((if (unsafe *__local_re).limit_heap == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            9 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((if (((unsafe *__local_re).flags as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) as c_uint)))
            },
            10 => {
                ((unsafe *(__param_where_ as *mut c_ulong)) = ((0 as c_ulong)))
            },
            12 => {
                var __ci_expr_ternary_4: c_int = 0

                if ((if (((unsafe *__local_re).flags as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_4 = ((1 as c_int)))
                } else {
                    (__ci_expr_ternary_4 = ((0 as c_int)))
                }

                ((unsafe *(__param_where_ as *mut c_uint)) = ((__ci_expr_ternary_4 as c_uint)))

            },
            11 => {
                var __ci_expr_ternary_5: c_uint = 0

                if ((if (((unsafe *__local_re).flags as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_5 = (unsafe *__local_re).last_codeunit)
                } else {
                    (__ci_expr_ternary_5 = ((0 as c_uint)))
                }

                ((unsafe *(__param_where_ as *mut c_uint)) = __ci_expr_ternary_5)

            },
            13 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((if (((unsafe *__local_re).flags as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) as c_uint)))
            },
            14 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (unsafe *__local_re).limit_match)

                if ((if (unsafe *__local_re).limit_match == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            15 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).max_lookbehind as c_uint)))
            },
            16 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).minlength as c_uint)))
            },
            18 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).name_entry_size as c_uint)))
            },
            17 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).name_count as c_uint)))
            },
            19 => {
                ((unsafe *(__param_where_ as *mut *const u8)) = ((((__local_re as *const c_char) + (sizeof[pcre2_real_code_8]() as usize)) as *const u8)))
            },
            20 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = (((unsafe *__local_re).newline_convention as c_uint)))
            },
            22 => {
                ((unsafe *(__param_where_ as *mut c_ulong)) = (unsafe *__local_re).blocksize)
            },
            _ => {
                return -34
            },
        }

        break

    }

    return 0

}

pub unsafe fn pcre2_callout_enumerate_8(__param_code: *const pcre2_real_code_8, __param_callback: unsafe extern "C" fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, __param_callout_data: *mut c_void) -> c_int {
    var __local_re: *const pcre2_real_code_8 = __param_code

    var __local_cb: pcre2_callout_enumerate_block_8

    var __local_cc: *const u8

    var __local_utf: c_int

    if ((if __local_re == null: 1 else: 0) != 0) {
        return -51
    }

    (__local_utf = (((if (((unsafe *__local_re).overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) as c_int)))

    if ((if (unsafe *__local_re).magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if (((unsafe *__local_re).flags as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0) {
        return -32
    }

    (__local_cb.version = ((0 as c_uint)))

    (__local_cc = ((((__local_re as *mut u8) + ((unsafe *__local_re).code_start as usize)) as *const u8)))

    while (1 != 0) {
        var __local_rc: c_int

        while true {
            match (unsafe *__local_cc) {
                0 => {
                    return 0
                },
                29 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                30 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                31 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                32 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                33 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                34 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                35 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                36 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                37 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                38 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                39 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                40 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                41 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                42 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                43 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                44 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                45 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                46 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                47 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                48 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                49 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                50 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                51 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                52 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                53 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                54 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                55 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                56 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                57 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                58 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                59 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                60 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                61 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                62 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                63 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                64 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                65 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                66 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                67 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                68 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                69 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                70 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                71 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                72 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                73 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                74 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                75 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                76 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                77 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                78 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                79 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                80 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                81 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                82 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                83 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                84 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((unsafe __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize) as c_int))
                    }


                },
                85 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                86 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                87 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                88 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                89 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                90 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                91 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                92 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                93 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                94 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                95 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                96 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                97 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                112 => {
                    (__local_cc = __local_cc + (((((((unsafe __local_cc[1]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[(1 + 1)]) as c_int) as c_int)) as c_uint) as usize))
                },
                113 => {
                    (__local_cc = __local_cc + (((((((unsafe __local_cc[1]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[(1 + 1)]) as c_int) as c_int)) as c_uint) as usize))
                },
                156 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_int) + ((unsafe __local_cc[1]) as c_int)) as isize) as usize))
                },
                164 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_int) + ((unsafe __local_cc[1]) as c_int)) as isize) as usize))
                },
                158 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_int) + ((unsafe __local_cc[1]) as c_int)) as isize) as usize))
                },
                160 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_int) + ((unsafe __local_cc[1]) as c_int)) as isize) as usize))
                },
                162 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_int) + ((unsafe __local_cc[1]) as c_int)) as isize) as usize))
                },
                119 => {
                    (__local_cb.pattern_position = ((((((((unsafe __local_cc[1]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[(1 + 1)]) as c_int) as c_int)) as c_uint) as c_ulong)))

                    (__local_cb.next_item_length = ((((((((unsafe __local_cc[(1 + 2)]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[((1 + 2) + 1)]) as c_int) as c_int)) as c_uint) as c_ulong)))

                    (__local_cb.callout_number = (((unsafe __local_cc[(1 + (2 * 2))]) as c_uint)))

                    (__local_cb.callout_string_offset = ((0 as c_ulong)))

                    (__local_cb.callout_string_length = ((0 as c_ulong)))

                    (__local_cb.callout_string = ((null as *const u8)))

                    (__local_rc = ((__param_callback((&raw mut __local_cb as *mut pcre2_callout_enumerate_block_8), __param_callout_data) as c_int)))

                    if ((if __local_rc != 0: 1 else: 0) != 0) {
                        return __local_rc
                    }

                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))

                },
                120 => {
                    (__local_cb.pattern_position = ((((((((unsafe __local_cc[1]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[(1 + 1)]) as c_int) as c_int)) as c_uint) as c_ulong)))

                    (__local_cb.next_item_length = ((((((((unsafe __local_cc[(1 + 2)]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[((1 + 2) + 1)]) as c_int) as c_int)) as c_uint) as c_ulong)))

                    (__local_cb.callout_number = ((0 as c_uint)))

                    (__local_cb.callout_string_offset = ((((((((unsafe __local_cc[(1 + (3 * 2))]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[((1 + (3 * 2)) + 1)]) as c_int) as c_int)) as c_uint) as c_ulong)))

                    (__local_cb.callout_string_length = ((((((((((((unsafe __local_cc[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[((1 + (2 * 2)) + 1)]) as c_int) as c_int)) as c_uint) as c_uint) -% (9 as c_uint)) as c_uint) -% (2 as c_uint)) as c_ulong)))

                    (__local_cb.callout_string = (__local_cc + (((1 + (4 * 2)) as isize) as usize)) + ((1 as isize) as usize))

                    (__local_rc = ((__param_callback((&raw mut __local_cb as *mut pcre2_callout_enumerate_block_8), __param_callout_data) as c_int)))

                    if ((if __local_rc != 0: 1 else: 0) != 0) {
                        return __local_rc
                    }

                    (__local_cc = __local_cc + (((((((unsafe __local_cc[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) as c_int) | (((unsafe __local_cc[((1 + (2 * 2)) + 1)]) as c_int) as c_int)) as c_uint) as usize))

                },
                _ => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(unsafe *__local_cc)] as c_uint) as usize) as c_int))
                },
            }

            break

        }

    }

}
