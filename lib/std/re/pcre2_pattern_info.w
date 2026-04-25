// Migrated from PCRE2
use std.re.defs

fn pcre2_pattern_info_8(code: *const pcre2_real_code_8, what: c_uint, where_: *mut c_void) -> c_int {
    var re: *const pcre2_real_code_8 = code

    if ((if where_ == null: 1 else: 0) != 0) {
        match what {
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

    if ((if re == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if re.magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if (re.flags & 1) == 0: 1 else: 0) != 0) {
        return -32
    }

    while true {
        match what {
            0 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.overall_options)
            },
            1 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.compile_options)
            },
            2 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.top_backref)
            },
            3 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.bsr_convention)
            },
            4 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.top_bracket)
            },
            21 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.limit_depth)

                if ((if re.limit_depth == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            26 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.extra_options)
            },
            6 => {
                var __ci_expr_ternary_1: c_int = 0

                if ((if (re.flags & 16) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = 1)
                } else {
                    var __ci_expr_ternary_0: c_int = 0

                    if ((if (re.flags & 512) != 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_0 = 2)
                    } else {
                        (__ci_expr_ternary_0 = 0)
                    }

                    (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                }

                ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_1)

            },
            5 => {
                var __ci_expr_ternary_2: c_uint = 0

                if ((if (re.flags & 16) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_2 = re.first_codeunit)
                } else {
                    (__ci_expr_ternary_2 = 0)
                }

                ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_2)

            },
            7 => {
                var __ci_expr_ternary_3: *const u8 = null

                if ((if (re.flags & 64) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = ((&re.start_bitmap[0] as *const u8)))
                } else {
                    (__ci_expr_ternary_3 = ((null as *const u8)))
                }

                ((unsafe: *(where_ as *mut *const u8)) = __ci_expr_ternary_3)

            },
            24 => {
                ((unsafe: *(where_ as *mut c_ulong)) = (120 +% ((re.top_bracket * 2) *% sizeof[c_ulong]())))
            },
            23 => {
                ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 4194304) != 0: 1 else: 0))
            },
            8 => {
                ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 2048) != 0: 1 else: 0))
            },
            25 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.limit_heap)

                if ((if re.limit_heap == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            9 => {
                ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 1024) != 0: 1 else: 0))
            },
            10 => {
                ((unsafe: *(where_ as *mut c_ulong)) = 0)
            },
            12 => {
                var __ci_expr_ternary_4: c_int = 0

                if ((if (re.flags & 128) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_4 = 1)
                } else {
                    (__ci_expr_ternary_4 = 0)
                }

                ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_4)

            },
            11 => {
                var __ci_expr_ternary_5: c_uint = 0

                if ((if (re.flags & 128) != 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_5 = re.last_codeunit)
                } else {
                    (__ci_expr_ternary_5 = 0)
                }

                ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_5)

            },
            13 => {
                ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 8192) != 0: 1 else: 0))
            },
            14 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.limit_match)

                if ((if re.limit_match == 4294967295: 1 else: 0) != 0) {
                    return -55
                }

            },
            15 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.max_lookbehind)
            },
            16 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.minlength)
            },
            18 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.name_entry_size)
            },
            17 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.name_count)
            },
            19 => {
                ((unsafe: *(where_ as *mut *const u8)) = ((((re as *const c_char) + sizeof[pcre2_real_code_8]()) as *const u8)))
            },
            20 => {
                ((unsafe: *(where_ as *mut c_uint)) = re.newline_convention)
            },
            22 => {
                ((unsafe: *(where_ as *mut c_ulong)) = re.blocksize)
            },
            _ => {
                return -34
            },
        }

        break

    }

    return 0

}

fn pcre2_callout_enumerate_8(code: *const pcre2_real_code_8, callback: *const fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, callout_data: *mut c_void) -> c_int {
    var re: *const pcre2_real_code_8 = code

    var cb: pcre2_callout_enumerate_block_8

    var cc: *const u8

    var utf: c_int

    if ((if re == null: 1 else: 0) != 0) {
        return -51
    }

    (utf = (if (re.overall_options & 524288) != 0: 1 else: 0))

    if ((if re.magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if (re.flags & 1) == 0: 1 else: 0) != 0) {
        return -32
    }

    (cb.version = 0)

    (cc = ((((re as *mut u8) + re.code_start) as *const u8)))

    while (1 != 0) {
        var rc: c_int

        while true {
            match (unsafe: *cc) {
                0 => {
                    return 0
                },
                29 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                30 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                31 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                32 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                33 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                34 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                35 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                36 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                37 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                38 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                39 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                40 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                41 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                42 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                43 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                44 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                45 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                46 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                47 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                48 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                49 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                50 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                51 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                52 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                53 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                54 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                55 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                56 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                57 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                58 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                59 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                60 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                61 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                62 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                63 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                64 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                65 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                66 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                67 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                68 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                69 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                70 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                71 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                72 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                73 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                74 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                75 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                76 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                77 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                78 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                79 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                80 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                81 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                82 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                83 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                84 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_0: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                    }


                },
                85 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                86 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                87 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                88 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                89 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                90 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                91 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                92 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                93 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                94 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                95 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                96 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                97 => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                    var __ci_expr_logic_1: c_int

                    if ((if (unsafe: cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (unsafe: cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (cc = cc + 2)
                    }


                },
                112 => {
                    (cc = cc + (((((unsafe: cc[1]) as c_int) << (8 as c_uint)) | (unsafe: cc[(1 + 1)])) as c_uint))
                },
                113 => {
                    (cc = cc + (((((unsafe: cc[1]) as c_int) << (8 as c_uint)) | (unsafe: cc[(1 + 1)])) as c_uint))
                },
                156 => {
                    (cc = cc + (_pcre2_OP_lengths_8[(unsafe: *cc)] + (unsafe: cc[1])))
                },
                164 => {
                    (cc = cc + (_pcre2_OP_lengths_8[(unsafe: *cc)] + (unsafe: cc[1])))
                },
                158 => {
                    (cc = cc + (_pcre2_OP_lengths_8[(unsafe: *cc)] + (unsafe: cc[1])))
                },
                160 => {
                    (cc = cc + (_pcre2_OP_lengths_8[(unsafe: *cc)] + (unsafe: cc[1])))
                },
                162 => {
                    (cc = cc + (_pcre2_OP_lengths_8[(unsafe: *cc)] + (unsafe: cc[1])))
                },
                119 => {
                    (cb.pattern_position = ((((((unsafe: cc[1]) as c_int) << (8 as c_uint)) | (unsafe: cc[(1 + 1)])) as c_uint)))

                    (cb.next_item_length = ((((((unsafe: cc[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc[((1 + 2) + 1)])) as c_uint)))

                    (cb.callout_number = (unsafe: cc[(1 + (2 * 2))]))

                    (cb.callout_string_offset = 0)

                    (cb.callout_string_length = 0)

                    (cb.callout_string = null)

                    (rc = callback((&mut cb as *mut pcre2_callout_enumerate_block_8), callout_data))

                    if ((if rc != 0: 1 else: 0) != 0) {
                        return rc
                    }

                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                },
                120 => {
                    (cb.pattern_position = ((((((unsafe: cc[1]) as c_int) << (8 as c_uint)) | (unsafe: cc[(1 + 1)])) as c_uint)))

                    (cb.next_item_length = ((((((unsafe: cc[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc[((1 + 2) + 1)])) as c_uint)))

                    (cb.callout_number = 0)

                    (cb.callout_string_offset = ((((((unsafe: cc[(1 + (3 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: cc[((1 + (3 * 2)) + 1)])) as c_uint)))

                    (cb.callout_string_length = (((((((unsafe: cc[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: cc[((1 + (2 * 2)) + 1)])) as c_uint) -% 9) -% 2))

                    (cb.callout_string = (cc + (((1 + (4 * 2)) as isize) as usize)) + ((1 as isize) as usize))

                    (rc = callback((&mut cb as *mut pcre2_callout_enumerate_block_8), callout_data))

                    if ((if rc != 0: 1 else: 0) != 0) {
                        return rc
                    }

                    (cc = cc + (((((unsafe: cc[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: cc[((1 + (2 * 2)) + 1)])) as c_uint))

                },
                _ => {
                    (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])
                },
            }

            break

        }

    }

}
