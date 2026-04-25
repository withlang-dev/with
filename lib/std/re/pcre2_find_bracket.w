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
                        while true {
                            match c {
                                85 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                86 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                87 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                88 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                89 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                90 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                94 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                95 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                96 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                91 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                92 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                93 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                97 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (code = code + 2)
                                    }

                                },
                                156 => {
                                    (code = code + (unsafe: code[1]))
                                },
                                164 => {
                                    (code = code + (unsafe: code[1]))
                                },
                                158 => {
                                    (code = code + (unsafe: code[1]))
                                },
                                160 => {
                                    (code = code + (unsafe: code[1]))
                                },
                                162 => {
                                    (code = code + (unsafe: code[1]))
                                },
                            }

                            break

                        }

                        (code = code + _pcre2_OP_lengths_8[c])

                        if (utf != 0) {
                            while true {
                                match c {
                                    29 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    30 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    31 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    32 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    41 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    54 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    67 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    80 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    39 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    52 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    65 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    78 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    40 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    53 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    66 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    79 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    45 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    58 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    71 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    84 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    33 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    46 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    59 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    72 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    34 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    47 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    60 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    73 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    42 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    55 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    68 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    81 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    35 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    48 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    61 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    74 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    36 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    49 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    62 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    75 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    43 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    56 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    69 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    82 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    37 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    50 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    63 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    76 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    38 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    51 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    64 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    77 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    44 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    57 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    70 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                    83 => {
                                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                                        }
                                    },
                                }

                                break

                            }
                        }

                    }

                }

            }
        }


    }

}
