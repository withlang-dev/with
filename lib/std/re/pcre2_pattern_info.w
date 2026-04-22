// Migrated from PCRE2
use std.re.defs

fn pcre2_pattern_info_8(code: *const pcre2_real_code_8, what: c_uint, where_: *mut c_void) -> c_int {
    var re: *const pcre2_real_code_8 = code

    if ((if where_ == null: 1 else: 0) != 0) {
        match what:
            0 | 1 | 2 | 3 | 4 | 21 | 26 | 6 | 5 | 23 | 8 | 25 | 9 | 12 | 11 | 13 | 14 | 15 | 16 | 18 | 17 | 20 =>
                return 4
            7 =>
                return 8
            10 | 22 | 24 =>
                return 8
            19 =>
                return 8

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

    match what:
        0 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.overall_options)
        1 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.compile_options)
        2 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.top_backref)
        3 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.bsr_convention)
        4 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.top_bracket)
        21 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.limit_depth)

            if ((if re.limit_depth == 4294967295: 1 else: 0) != 0) {
                return -55
            }

        26 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.extra_options)
        6 =>
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

        5 =>
            var __ci_expr_ternary_2: c_uint = 0

            if ((if (re.flags & 16) != 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = re.first_codeunit)
            } else {
                (__ci_expr_ternary_2 = 0)
            }

            ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_2)

        7 =>
            var __ci_expr_ternary_3: *const u8 = null

            if ((if (re.flags & 64) != 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_3 = ((&re.start_bitmap[0] as *const u8)))
            } else {
                (__ci_expr_ternary_3 = ((null as *const u8)))
            }

            ((unsafe: *(where_ as *mut *const u8)) = __ci_expr_ternary_3)

        24 =>
            ((unsafe: *(where_ as *mut c_ulong)) = (120 +% ((re.top_bracket * 2) *% sizeof[c_ulong]())))
        23 =>
            ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 4194304) != 0: 1 else: 0))
        8 =>
            ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 2048) != 0: 1 else: 0))
        25 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.limit_heap)

            if ((if re.limit_heap == 4294967295: 1 else: 0) != 0) {
                return -55
            }

        9 =>
            ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 1024) != 0: 1 else: 0))
        10 =>
            ((unsafe: *(where_ as *mut c_ulong)) = 0)
        12 =>
            var __ci_expr_ternary_4: c_int = 0

            if ((if (re.flags & 128) != 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_4 = 1)
            } else {
                (__ci_expr_ternary_4 = 0)
            }

            ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_4)

        11 =>
            var __ci_expr_ternary_5: c_uint = 0

            if ((if (re.flags & 128) != 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = re.last_codeunit)
            } else {
                (__ci_expr_ternary_5 = 0)
            }

            ((unsafe: *(where_ as *mut c_uint)) = __ci_expr_ternary_5)

        13 =>
            ((unsafe: *(where_ as *mut c_uint)) = (if (re.flags & 8192) != 0: 1 else: 0))
        14 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.limit_match)

            if ((if re.limit_match == 4294967295: 1 else: 0) != 0) {
                return -55
            }

        15 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.max_lookbehind)
        16 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.minlength)
        18 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.name_entry_size)
        17 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.name_count)
        19 =>
            ((unsafe: *(where_ as *mut *const u8)) = ((((re as *const c_char) + sizeof[pcre2_real_code_8]()) as *const u8)))
        20 =>
            ((unsafe: *(where_ as *mut c_uint)) = re.newline_convention)
        22 =>
            ((unsafe: *(where_ as *mut c_ulong)) = re.blocksize)
        _ =>
            return -34

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

        match (unsafe: *cc):
            OP_END =>
                return 0
            OP_CHAR | OP_CHARI | OP_NOT | OP_NOTI | OP_STAR | OP_MINSTAR | OP_PLUS | OP_MINPLUS | OP_QUERY | OP_MINQUERY | OP_UPTO | OP_MINUPTO | OP_EXACT | OP_POSSTAR | OP_POSPLUS | OP_POSQUERY | OP_POSUPTO | OP_STARI | OP_MINSTARI | OP_PLUSI | OP_MINPLUSI | OP_QUERYI | OP_MINQUERYI | OP_UPTOI | OP_MINUPTOI | OP_EXACTI | OP_POSSTARI | OP_POSPLUSI | OP_POSQUERYI | OP_POSUPTOI | OP_NOTSTAR | OP_NOTMINSTAR | OP_NOTPLUS | OP_NOTMINPLUS | OP_NOTQUERY | OP_NOTMINQUERY | OP_NOTUPTO | OP_NOTMINUPTO | OP_NOTEXACT | OP_NOTPOSSTAR | OP_NOTPOSPLUS | OP_NOTPOSQUERY | OP_NOTPOSUPTO | OP_NOTSTARI | OP_NOTMINSTARI | OP_NOTPLUSI | OP_NOTMINPLUSI | OP_NOTQUERYI | OP_NOTMINQUERYI | OP_NOTUPTOI | OP_NOTMINUPTOI | OP_NOTEXACTI | OP_NOTPOSSTARI | OP_NOTPOSPLUSI | OP_NOTPOSQUERYI | OP_NOTPOSUPTOI =>
                (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

                var __ci_expr_logic_0: c_int = 0

                if (utf != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe: cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (cc = cc + _pcre2_utf8_table4[((unsafe: cc[-1]) & 63)])
                }


            OP_TYPESTAR | OP_TYPEMINSTAR | OP_TYPEPLUS | OP_TYPEMINPLUS | OP_TYPEQUERY | OP_TYPEMINQUERY | OP_TYPEUPTO | OP_TYPEMINUPTO | OP_TYPEEXACT | OP_TYPEPOSSTAR | OP_TYPEPOSPLUS | OP_TYPEPOSQUERY | OP_TYPEPOSUPTO =>
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


            OP_XCLASS | OP_ECLASS =>
                (cc = cc + ((((unsafe: cc[1]) << 8) | (unsafe: cc[(1 + 1)])) as c_uint))
            OP_MARK | OP_COMMIT_ARG | OP_PRUNE_ARG | OP_SKIP_ARG | OP_THEN_ARG =>
                (cc = cc + (_pcre2_OP_lengths_8[(unsafe: *cc)] + (unsafe: cc[1])))
            OP_CALLOUT =>
                (cb.pattern_position = (((((unsafe: cc[1]) << 8) | (unsafe: cc[(1 + 1)])) as c_uint)))

                (cb.next_item_length = (((((unsafe: cc[(1 + 2)]) << 8) | (unsafe: cc[((1 + 2) + 1)])) as c_uint)))

                (cb.callout_number = (unsafe: cc[(1 + (2 * 2))]))

                (cb.callout_string_offset = 0)

                (cb.callout_string_length = 0)

                (cb.callout_string = null)

                (rc = callback((&mut cb as *mut pcre2_callout_enumerate_block_8), callout_data))

                if ((if rc != 0: 1 else: 0) != 0) {
                    return rc
                }

                (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

            OP_CALLOUT_STR =>
                (cb.pattern_position = (((((unsafe: cc[1]) << 8) | (unsafe: cc[(1 + 1)])) as c_uint)))

                (cb.next_item_length = (((((unsafe: cc[(1 + 2)]) << 8) | (unsafe: cc[((1 + 2) + 1)])) as c_uint)))

                (cb.callout_number = 0)

                (cb.callout_string_offset = (((((unsafe: cc[(1 + (3 * 2))]) << 8) | (unsafe: cc[((1 + (3 * 2)) + 1)])) as c_uint)))

                (cb.callout_string_length = ((((((unsafe: cc[(1 + (2 * 2))]) << 8) | (unsafe: cc[((1 + (2 * 2)) + 1)])) as c_uint) -% 9) -% 2))

                (cb.callout_string = (cc + (((1 + (4 * 2)) as isize) as usize)) + ((1 as isize) as usize))

                (rc = callback((&mut cb as *mut pcre2_callout_enumerate_block_8), callout_data))

                if ((if rc != 0: 1 else: 0) != 0) {
                    return rc
                }

                (cc = cc + ((((unsafe: cc[(1 + (2 * 2))]) << 8) | (unsafe: cc[((1 + (2 * 2)) + 1)])) as c_uint))

            _ =>
                (cc = cc + _pcre2_OP_lengths_8[(unsafe: *cc)])

    }

}
