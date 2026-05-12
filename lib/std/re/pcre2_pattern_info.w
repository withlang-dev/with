// Migrated from PCRE2
use std.re.defs

@[c_export("pcre2_pattern_info_8")]
fn pcre2_pattern_info_8(__param_code: *const pcre2_real_code_8, __param_what: c_uint, __param_where_: *mut c_void) -> c_int {
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

    if ((if __local_re.magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if ((__local_re.flags as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0) {
        return -32
    }

    while true {
        match __param_what {
            0 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.overall_options)
            },
            1 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.compile_options)
            },
            2 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.top_backref)
            },
            3 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.bsr_convention)
            },
            4 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.top_bracket)
            },
            21 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.limit_depth)

                if ((if __local_re.limit_depth == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            26 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.extra_options)
            },
            6 => {
                var __ci_expr_ternary_1: c_int = 0

                if ((if ((__local_re.flags as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = 1)
                } else {
                    var __ci_expr_ternary_0: c_int = 0

                    if ((if ((__local_re.flags as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_0 = 2)
                    } else {
                        (__ci_expr_ternary_0 = 0)
                    }

                    (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                }

                ((unsafe: *(__param_where_ as *mut c_uint)) = __ci_expr_ternary_1)

            },
            5 => {
                var __ci_expr_ternary_2: c_uint = 0

                if ((if ((__local_re.flags as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_2 = __local_re.first_codeunit)
                } else {
                    (__ci_expr_ternary_2 = 0)
                }

                ((unsafe: *(__param_where_ as *mut c_uint)) = __ci_expr_ternary_2)

            },
            7 => {
                var __ci_expr_ternary_3: *const u8 = null

                if ((if ((__local_re.flags as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = ((&raw const (unsafe: *__local_re).start_bitmap[0] as *const u8)))
                } else {
                    (__ci_expr_ternary_3 = ((null as *const u8)))
                }

                ((unsafe: *(__param_where_ as *mut *const u8)) = __ci_expr_ternary_3)

            },
            24 => {
                ((unsafe: *(__param_where_ as *mut c_ulong)) = ((136 as c_ulong) +% (((((__local_re.top_bracket as c_int) * 2) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong)))
            },
            23 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = (if ((__local_re.flags as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0))
            },
            8 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = (if ((__local_re.flags as c_uint) & (2048 as c_uint)) != 0: 1 else: 0))
            },
            25 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.limit_heap)

                if ((if __local_re.limit_heap == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            9 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = (if ((__local_re.flags as c_uint) & (1024 as c_uint)) != 0: 1 else: 0))
            },
            10 => {
                ((unsafe: *(__param_where_ as *mut c_ulong)) = 0)
            },
            12 => {
                var __ci_expr_ternary_4: c_int = 0

                if ((if ((__local_re.flags as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_4 = 1)
                } else {
                    (__ci_expr_ternary_4 = 0)
                }

                ((unsafe: *(__param_where_ as *mut c_uint)) = __ci_expr_ternary_4)

            },
            11 => {
                var __ci_expr_ternary_5: c_uint = 0

                if ((if ((__local_re.flags as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_5 = __local_re.last_codeunit)
                } else {
                    (__ci_expr_ternary_5 = 0)
                }

                ((unsafe: *(__param_where_ as *mut c_uint)) = __ci_expr_ternary_5)

            },
            13 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = (if ((__local_re.flags as c_uint) & (8192 as c_uint)) != 0: 1 else: 0))
            },
            14 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.limit_match)

                if ((if __local_re.limit_match == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            15 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.max_lookbehind)
            },
            16 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.minlength)
            },
            18 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.name_entry_size)
            },
            17 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.name_count)
            },
            19 => {
                ((unsafe: *(__param_where_ as *mut *const u8)) = ((((__local_re as *const c_char) + (sizeof[pcre2_real_code_8]() as usize)) as *const u8)))
            },
            20 => {
                ((unsafe: *(__param_where_ as *mut c_uint)) = __local_re.newline_convention)
            },
            22 => {
                ((unsafe: *(__param_where_ as *mut c_ulong)) = __local_re.blocksize)
            },
            _ => {
                return -34
            },
        }

        break

    }

    return 0

}

@[c_export("pcre2_callout_enumerate_8")]
fn pcre2_callout_enumerate_8(__param_code: *const pcre2_real_code_8, __param_callback: *const fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, __param_callout_data: *mut c_void) -> c_int {
    var __local_re: *const pcre2_real_code_8 = __param_code

    var __local_cb: pcre2_callout_enumerate_block_8

    var __local_cc: *const u8

    var __local_utf: c_int

    if ((if __local_re == null: 1 else: 0) != 0) {
        return -51
    }

    (__local_utf = (if ((__local_re.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))

    if ((if __local_re.magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if ((__local_re.flags as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0) {
        return -32
    }

    (__local_cb.version = 0)

    (__local_cc = ((((__local_re as *mut u8) + (__local_re.code_start as usize)) as *const u8)))

    while (1 != 0) {
        var __local_rc: c_int

        while true {
            match (unsafe: *__local_cc) {
                0 => {
                    return 0
                },
                29 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                30 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                31 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                32 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                33 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                34 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                35 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                36 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                37 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                38 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                39 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                40 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                41 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                42 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                43 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                44 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                45 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                46 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                47 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                48 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                49 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                50 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                51 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                52 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                53 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                54 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                55 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                56 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                57 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                58 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                59 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                60 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                61 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                62 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                63 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                64 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                65 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                66 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                67 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                68 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                69 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                70 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                71 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                72 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                73 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                74 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                75 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                76 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                77 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                78 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                79 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                80 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                81 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                82 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                83 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                84 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_0: c_int = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: __local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + ((_pcre2_utf8_table4[((((unsafe: __local_cc[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                    }


                },
                85 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                86 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                87 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                88 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                89 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                90 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                91 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                92 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                93 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                94 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                95 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                96 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                97 => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: __local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: __local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                112 => {
                    (__local_cc = __local_cc + ((((((unsafe: __local_cc[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[(1 + 1)]) as c_int)) as c_uint) as usize))
                },
                113 => {
                    (__local_cc = __local_cc + ((((((unsafe: __local_cc[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[(1 + 1)]) as c_int)) as c_uint) as usize))
                },
                156 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_int) + ((unsafe: __local_cc[1]) as c_int)) as isize) as usize))
                },
                164 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_int) + ((unsafe: __local_cc[1]) as c_int)) as isize) as usize))
                },
                158 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_int) + ((unsafe: __local_cc[1]) as c_int)) as isize) as usize))
                },
                160 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_int) + ((unsafe: __local_cc[1]) as c_int)) as isize) as usize))
                },
                162 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_int) + ((unsafe: __local_cc[1]) as c_int)) as isize) as usize))
                },
                119 => {
                    (__local_cb.pattern_position = ((((((unsafe: __local_cc[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[(1 + 1)]) as c_int)) as c_uint)))

                    (__local_cb.next_item_length = ((((((unsafe: __local_cc[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[((1 + 2) + 1)]) as c_int)) as c_uint)))

                    (__local_cb.callout_number = (unsafe: __local_cc[(1 + (2 * 2))]))

                    (__local_cb.callout_string_offset = 0)

                    (__local_cb.callout_string_length = 0)

                    (__local_cb.callout_string = null)

                    (__local_rc = __param_callback((&raw mut __local_cb as *mut pcre2_callout_enumerate_block_8), __param_callout_data))

                    if ((if __local_rc != 0: 1 else: 0) != 0) {
                        return __local_rc
                    }

                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))

                },
                120 => {
                    (__local_cb.pattern_position = ((((((unsafe: __local_cc[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[(1 + 1)]) as c_int)) as c_uint)))

                    (__local_cb.next_item_length = ((((((unsafe: __local_cc[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[((1 + 2) + 1)]) as c_int)) as c_uint)))

                    (__local_cb.callout_number = 0)

                    (__local_cb.callout_string_offset = ((((((unsafe: __local_cc[(1 + (3 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[((1 + (3 * 2)) + 1)]) as c_int)) as c_uint)))

                    (__local_cb.callout_string_length = (((((((((unsafe: __local_cc[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[((1 + (2 * 2)) + 1)]) as c_int)) as c_uint) as c_uint) -% (9 as c_uint)) as c_uint) -% (2 as c_uint)))

                    (__local_cb.callout_string = (__local_cc + (((1 + (4 * 2)) as isize) as usize)) + ((1 as isize) as usize))

                    (__local_rc = __param_callback((&raw mut __local_cb as *mut pcre2_callout_enumerate_block_8), __param_callout_data))

                    if ((if __local_rc != 0: 1 else: 0) != 0) {
                        return __local_rc
                    }

                    (__local_cc = __local_cc + ((((((unsafe: __local_cc[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe: __local_cc[((1 + (2 * 2)) + 1)]) as c_int)) as c_uint) as usize))

                },
                _ => {
                    (__local_cc = __local_cc + ((_pcre2_OP_lengths_8[(unsafe: *__local_cc)] as c_uint) as usize))
                },
            }

            break

        }

    }

}
