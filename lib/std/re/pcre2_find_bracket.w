// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_find_bracket_8")]
fn _pcre2_find_bracket_8(__param_code: *const u8, __param_utf: c_int, __param_number: c_int) -> *const u8 {
    var __local_code = __param_code
    while true {
        var __local_c: u8 = (unsafe: *__local_code)

        if ((if __local_c == OP_END: 1 else: 0) != 0) {
            return null
        }

        var __ci_expr_logic_0: c_int

        if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_code = __local_code + ((((((unsafe: __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))
        } else {
            if ((if __local_c == OP_CALLOUT_STR: 1 else: 0) != 0) {
                (__local_code = __local_code + ((((((unsafe: __local_code[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code[((1 + (2 * 2)) + 1)]) as c_int)) as c_uint) as usize))
            } else {
                var __ci_expr_logic_1: c_int

                if ((if __local_c == OP_REVERSE: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if __local_c == OP_VREVERSE: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    if ((if __param_number < 0: 1 else: 0) != 0) {
                        return __local_code
                    }

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                } else {
                    var __ci_expr_logic_4: c_int

                    var __ci_expr_logic_3: c_int

                    var __ci_expr_logic_2: c_int

                    if ((if __local_c == OP_CBRA: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if (if __local_c == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_3 = (if (if __local_c == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_c == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        var __local_n: c_int = (((((((unsafe: __local_code[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code[((1 + 2) + 1)]) as c_int)) as c_uint) as c_int))

                        if ((if __local_n == __param_number: 1 else: 0) != 0) {
                            return __local_code
                        }

                        (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    } else {
                        while true {
                            match __local_c {
                                85 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                86 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                87 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                88 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                89 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                90 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                94 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                95 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                96 => {
                                    var __ci_expr_logic_5: c_int

                                    if ((if (unsafe: __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (if (unsafe: __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                91 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                92 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                93 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                97 => {
                                    var __ci_expr_logic_6: c_int

                                    if ((if (unsafe: __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (if (unsafe: __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                156 => {
                                    (__local_code = __local_code + (((unsafe: __local_code[1]) as c_uint) as usize))
                                },
                                164 => {
                                    (__local_code = __local_code + (((unsafe: __local_code[1]) as c_uint) as usize))
                                },
                                158 => {
                                    (__local_code = __local_code + (((unsafe: __local_code[1]) as c_uint) as usize))
                                },
                                160 => {
                                    (__local_code = __local_code + (((unsafe: __local_code[1]) as c_uint) as usize))
                                },
                                162 => {
                                    (__local_code = __local_code + (((unsafe: __local_code[1]) as c_uint) as usize))
                                },
                            }

                            break

                        }

                        (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                        if (__param_utf != 0) {
                            while true {
                                match __local_c {
                                    29 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    30 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    31 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    32 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    41 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    54 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    67 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    80 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    39 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    52 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    65 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    78 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    40 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    53 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    66 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    79 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    45 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    58 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    71 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    84 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    33 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    46 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    59 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    72 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    34 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    47 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    60 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    73 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    42 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    55 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    68 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    81 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    35 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    48 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    61 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    74 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    36 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    49 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    62 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    75 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    43 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    56 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    69 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    82 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    37 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    50 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    63 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    76 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    38 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    51 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    64 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    77 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    44 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    57 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    70 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                                        }
                                    },
                                    83 => {
                                        if ((if (unsafe: __local_code[-1]) >= 192: 1 else: 0) != 0) {
                                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe: __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
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
