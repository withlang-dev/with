// Migrated from PCRE2
use std.re.defs

fn _pcre2_find_bracket_8(__param_code: *const u8, utf: c_int, number: c_int) -> *const u8 {
    var code = __param_code
    while true {
        var c: u8 = (unsafe: *code)

        if ((if c == OP_END: 1 else: 0) != 0) {
            return null
        }

        var __ci_expr_logic_0: c_int

        if ((if c == OP_XCLASS: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))
        } else {
            if ((if c == OP_CALLOUT_STR: 1 else: 0) != 0) {
                (code = code + (((((unsafe: code[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: code[((1 + (2 * 2)) + 1)])) as c_uint))
            } else {
                var __ci_expr_logic_1: c_int

                if ((if c == OP_REVERSE: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if c == OP_VREVERSE: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    if ((if number < 0: 1 else: 0) != 0) {
                        return code
                    }

                    (code = code + _pcre2_OP_lengths_8[c])

                } else {
                    var __ci_expr_logic_4: c_int

                    var __ci_expr_logic_3: c_int

                    var __ci_expr_logic_2: c_int

                    if ((if c == OP_CBRA: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if (if c == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_3 = (if (if c == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if c == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        var n: c_int = (((((((unsafe: code[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: code[((1 + 2) + 1)])) as c_uint) as c_int))

                        if ((if n == number: 1 else: 0) != 0) {
                            return code
                        }

                        (code = code + _pcre2_OP_lengths_8[c])

                    } else {
                        match c:
                            OP_TYPESTAR | OP_TYPEMINSTAR | OP_TYPEPLUS | OP_TYPEMINPLUS | OP_TYPEQUERY | OP_TYPEMINQUERY | OP_TYPEPOSSTAR | OP_TYPEPOSPLUS | OP_TYPEPOSQUERY =>
                                var __ci_expr_logic_5: c_int

                                if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_5 != 0) {
                                    (code = code + 2)
                                }

                            OP_TYPEUPTO | OP_TYPEMINUPTO | OP_TYPEEXACT | OP_TYPEPOSUPTO =>
                                var __ci_expr_logic_6: c_int

                                if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_6 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_6 != 0) {
                                    (code = code + 2)
                                }

                            OP_MARK | OP_COMMIT_ARG | OP_PRUNE_ARG | OP_SKIP_ARG | OP_THEN_ARG =>
                                (code = code + (unsafe: code[1]))

                        (code = code + _pcre2_OP_lengths_8[c])

                        if (utf != 0) {
                            match c:
                                OP_CHAR | OP_CHARI | OP_NOT | OP_NOTI | OP_EXACT | OP_EXACTI | OP_NOTEXACT | OP_NOTEXACTI | OP_UPTO | OP_UPTOI | OP_NOTUPTO | OP_NOTUPTOI | OP_MINUPTO | OP_MINUPTOI | OP_NOTMINUPTO | OP_NOTMINUPTOI | OP_POSUPTO | OP_POSUPTOI | OP_NOTPOSUPTO | OP_NOTPOSUPTOI | OP_STAR | OP_STARI | OP_NOTSTAR | OP_NOTSTARI | OP_MINSTAR | OP_MINSTARI | OP_NOTMINSTAR | OP_NOTMINSTARI | OP_POSSTAR | OP_POSSTARI | OP_NOTPOSSTAR | OP_NOTPOSSTARI | OP_PLUS | OP_PLUSI | OP_NOTPLUS | OP_NOTPLUSI | OP_MINPLUS | OP_MINPLUSI | OP_NOTMINPLUS | OP_NOTMINPLUSI | OP_POSPLUS | OP_POSPLUSI | OP_NOTPOSPLUS | OP_NOTPOSPLUSI | OP_QUERY | OP_QUERYI | OP_NOTQUERY | OP_NOTQUERYI | OP_MINQUERY | OP_MINQUERYI | OP_NOTMINQUERY | OP_NOTMINQUERYI | OP_POSQUERY | OP_POSQUERYI | OP_NOTPOSQUERY | OP_NOTPOSQUERYI =>
                                    if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                        (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                    }
                        }

                    }

                }

            }
        }


    }

}
