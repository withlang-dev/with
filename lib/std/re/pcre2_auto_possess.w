// Migrated from PCRE2
use std.re.defs
use std.re.pcre2_xclass

fn _pcre2_auto_possessify_8(__param_code: *mut u8, cb: *const compile_block_8) -> c_int {
    var code = __param_code
    var c: u8

    var end: *const u8

    var repeat_opcode: *mut u8

    var list: [8]c_uint

    var rec_limit: c_int = 1000

    var utf: c_int = (if (cb.external_options & 524288) != 0: 1 else: 0)

    var ucp: c_int = (if (cb.external_options & 131072) != 0: 1 else: 0)

    while true {
        (c = (unsafe: *code))

        if ((if c >= OP_TABLE_LENGTH: 1 else: 0) != 0) {
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            return -1

        }

        var __ci_expr_logic_0: c_int = 0

        if ((if c >= OP_STAR: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if c <= OP_TYPEPOSUPTO: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (c = c - (get_repeat_base(c) - OP_STAR))

            var __ci_expr_ternary_1: *const u8 = null

            if ((if c <= OP_MINUPTO: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))
            } else {
                (__ci_expr_ternary_1 = null)
            }

            (end = __ci_expr_ternary_1)


            var __ci_expr_logic_4: c_int

            var __ci_expr_logic_3: c_int

            var __ci_expr_logic_2: c_int

            if ((if c == OP_STAR: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if c == OP_PLUS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if c == OP_QUERY: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if c == OP_UPTO: 1 else: 0) != 0: 1 else: 0))
            }

            (list[1] = __ci_expr_logic_4)


            var __ci_expr_logic_5: c_int = 0

            if ((if end != null: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if compare_opcodes(end, utf, ucp, cb, (&list[0] as *mut c_uint), end, (&mut rec_limit as *mut c_int)) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                while true {
                    match c {
                        33 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSSTAR - OP_STAR))
                        },
                        34 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSSTAR - OP_MINSTAR))
                        },
                        35 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSPLUS - OP_PLUS))
                        },
                        36 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSPLUS - OP_MINPLUS))
                        },
                        37 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSQUERY - OP_QUERY))
                        },
                        38 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSQUERY - OP_MINQUERY))
                        },
                        39 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSUPTO - OP_UPTO))
                        },
                        40 => {
                            ((unsafe: *code) = (unsafe: *code) + (OP_POSUPTO - OP_MINUPTO))
                        },
                    }

                    break

                }

            }


            (c = (unsafe: *code))

        } else {
            var __ci_expr_logic_9: c_int

            var __ci_expr_logic_8: c_int

            var __ci_expr_logic_7: c_int

            if ((if c == OP_CLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_7 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_7 = (if (if c == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_7 != 0) {
                (__ci_expr_logic_8 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_8 = (if (if c == OP_XCLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_8 != 0) {
                (__ci_expr_logic_9 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_9 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                var __ci_expr_logic_10: c_int

                if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                    (__ci_expr_logic_10 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_10 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_10 != 0) {
                    (repeat_opcode = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))
                } else {
                    (repeat_opcode = (code + ((1 as isize) as usize)) + (32 / sizeof[u8]()))
                }


                (c = (unsafe: *repeat_opcode))

                var __ci_expr_logic_11: c_int = 0

                if ((if c >= OP_CRSTAR: 1 else: 0) != 0) {
                    (__ci_expr_logic_11 = (if (if c <= OP_CRMINRANGE: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    (end = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))

                    (list[1] = (if (c & 1) == 0: 1 else: 0))

                    var __ci_expr_logic_12: c_int = 0

                    if ((if end != null: 1 else: 0) != 0) {
                        (__ci_expr_logic_12 = (if compare_opcodes(end, utf, ucp, cb, (&list[0] as *mut c_uint), end, (&mut rec_limit as *mut c_int)) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_12 != 0) {
                        while true {
                            match c {
                                98 => {
                                    ((unsafe: *repeat_opcode) = 106)
                                },
                                99 => {
                                    ((unsafe: *repeat_opcode) = 106)
                                },
                                100 => {
                                    ((unsafe: *repeat_opcode) = 107)
                                },
                                101 => {
                                    ((unsafe: *repeat_opcode) = 107)
                                },
                                102 => {
                                    ((unsafe: *repeat_opcode) = 108)
                                },
                                103 => {
                                    ((unsafe: *repeat_opcode) = 108)
                                },
                                104 => {
                                    ((unsafe: *repeat_opcode) = 109)
                                },
                                105 => {
                                    ((unsafe: *repeat_opcode) = 109)
                                },
                            }

                            break

                        }

                    }


                }


                (c = (unsafe: *code))

            }

        }


        while true {
            match c {
                0 => {
                    return 0
                },
                85 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                86 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                87 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                88 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                89 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                90 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                94 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                95 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                96 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe: code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe: code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (code = code + 2)
                    }

                },
                91 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (code = code + 2)
                    }

                },
                92 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (code = code + 2)
                    }

                },
                93 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (code = code + 2)
                    }

                },
                97 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe: code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe: code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (code = code + 2)
                    }

                },
                120 => {
                    (code = code + (((((unsafe: code[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: code[((1 + (2 * 2)) + 1)])) as c_uint))
                },
                112 => {
                    (code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))
                },
                113 => {
                    (code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))
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
                    33 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    34 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    35 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    36 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    37 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    38 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    39 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    40 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    41 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    42 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    43 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    44 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    45 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    46 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    47 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    48 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    49 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    50 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    51 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    52 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    53 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    54 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    55 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    56 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    57 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    58 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    59 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    60 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    61 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    62 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    63 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    64 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    65 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    66 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    67 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    68 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    69 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    70 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    71 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    72 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    73 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    74 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    75 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    76 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    77 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    78 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    79 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    80 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    81 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    82 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    83 => {
                        if ((if (unsafe: code[-1]) >= 192: 1 else: 0) != 0) {
                            (code = code + _pcre2_utf8_table4[((unsafe: code[-1]) & 63)])
                        }
                    },
                    84 => {
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

fn check_char_prop(c: c_uint, ptype: c_uint, pdata: c_uint, negated: c_int) -> c_int {
    var ok: c_int

    var rc: c_int


    var p: *const c_uint

    var prop: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize))

    while true {
        match ptype {
            0 => {
                var __ci_expr_logic_1: c_int

                var __ci_expr_logic_0: c_int

                if ((if prop.chartype == ucp_Lu: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_0 = (if (if prop.chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if prop.chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_1 == negated: 1 else: 0)

            },
            1 => {
                return (if (if pdata == _pcre2_ucp_gentype_8[prop.chartype]: 1 else: 0) == negated: 1 else: 0)
            },
            2 => {
                return (if (if pdata == prop.chartype: 1 else: 0) == negated: 1 else: 0)
            },
            3 => {
                return (if (if pdata == prop.script: 1 else: 0) == negated: 1 else: 0)
            },
            4 => {
                var __ci_expr_logic_2: c_int

                if ((if pdata == prop.script: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (if ((unsafe: ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + (((prop.scriptx_bidiclass & 1023) as isize) as usize))[(pdata / 32)]) & ((1 as c_uint) << ((pdata % 32) as c_uint))) != 0: 1 else: 0) != 0: 1 else: 0))
                }

                (ok = __ci_expr_logic_2)


                return (if ok == negated: 1 else: 0)

            },
            5 => {
                var __ci_expr_logic_3: c_int

                if ((if _pcre2_ucp_gentype_8[prop.chartype] == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_3 == negated: 1 else: 0)

            },
            6 => {
                while true {
                    match c {
                        9 => {
                            (rc = negated)
                        },
                        32 => {
                            (rc = negated)
                        },
                        160 => {
                            (rc = negated)
                        },
                        5760 => {
                            (rc = negated)
                        },
                        6158 => {
                            (rc = negated)
                        },
                        8192 => {
                            (rc = negated)
                        },
                        8193 => {
                            (rc = negated)
                        },
                        8194 => {
                            (rc = negated)
                        },
                        8195 => {
                            (rc = negated)
                        },
                        8196 => {
                            (rc = negated)
                        },
                        8197 => {
                            (rc = negated)
                        },
                        8198 => {
                            (rc = negated)
                        },
                        8199 => {
                            (rc = negated)
                        },
                        8200 => {
                            (rc = negated)
                        },
                        8201 => {
                            (rc = negated)
                        },
                        8202 => {
                            (rc = negated)
                        },
                        8239 => {
                            (rc = negated)
                        },
                        8287 => {
                            (rc = negated)
                        },
                        12288 => {
                            (rc = negated)
                        },
                        10 => {
                            (rc = negated)
                        },
                        11 => {
                            (rc = negated)
                        },
                        12 => {
                            (rc = negated)
                        },
                        13 => {
                            (rc = negated)
                        },
                        133 => {
                            (rc = negated)
                        },
                        8232 => {
                            (rc = negated)
                        },
                        8233 => {
                            (rc = negated)
                        },
                        _ => {
                            (rc = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0) == negated: 1 else: 0))
                        },
                    }

                    break

                }

                return rc

            },
            7 => {
                while true {
                    match c {
                        9 => {
                            (rc = negated)
                        },
                        32 => {
                            (rc = negated)
                        },
                        160 => {
                            (rc = negated)
                        },
                        5760 => {
                            (rc = negated)
                        },
                        6158 => {
                            (rc = negated)
                        },
                        8192 => {
                            (rc = negated)
                        },
                        8193 => {
                            (rc = negated)
                        },
                        8194 => {
                            (rc = negated)
                        },
                        8195 => {
                            (rc = negated)
                        },
                        8196 => {
                            (rc = negated)
                        },
                        8197 => {
                            (rc = negated)
                        },
                        8198 => {
                            (rc = negated)
                        },
                        8199 => {
                            (rc = negated)
                        },
                        8200 => {
                            (rc = negated)
                        },
                        8201 => {
                            (rc = negated)
                        },
                        8202 => {
                            (rc = negated)
                        },
                        8239 => {
                            (rc = negated)
                        },
                        8287 => {
                            (rc = negated)
                        },
                        12288 => {
                            (rc = negated)
                        },
                        10 => {
                            (rc = negated)
                        },
                        11 => {
                            (rc = negated)
                        },
                        12 => {
                            (rc = negated)
                        },
                        13 => {
                            (rc = negated)
                        },
                        133 => {
                            (rc = negated)
                        },
                        8232 => {
                            (rc = negated)
                        },
                        8233 => {
                            (rc = negated)
                        },
                        _ => {
                            (rc = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0) == negated: 1 else: 0))
                        },
                    }

                    break

                }

                return rc

            },
            8 => {
                var __ci_expr_logic_6: c_int

                var __ci_expr_logic_5: c_int

                if ((if _pcre2_ucp_gentype_8[prop.chartype] == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_6 = (if (if c == 95: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_6 == negated: 1 else: 0)

            },
            9 => {
                (p = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + ((prop.caseset as isize) as usize))

                while true {
                    if ((if c < (unsafe: *p): 1 else: 0) != 0) {
                        return (if not (negated != 0): 1 else: 0)
                    }

                    var __ci_expr_old_7: *const c_uint = p

                    (p = p + 1)

                    if ((if c == (unsafe: *__ci_expr_old_7): 1 else: 0) != 0) {
                        return negated
                    }


                }

            },
            11 => {
                return 0
            },
            12 => {
                return 0
            },
        }

        break

    }

    return 0

}

fn get_repeat_base(c: u8) -> u8 {
    var __ci_expr_ternary_4: c_int = 0

    if ((if c > OP_TYPEPOSUPTO: 1 else: 0) != 0) {
        (__ci_expr_ternary_4 = c)
    } else {
        var __ci_expr_ternary_3: c_int = 0

        if ((if c >= OP_TYPESTAR: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = OP_TYPESTAR)
        } else {
            var __ci_expr_ternary_2: c_int = 0

            if ((if c >= OP_NOTSTARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = OP_NOTSTARI)
            } else {
                var __ci_expr_ternary_1: c_int = 0

                if ((if c >= OP_NOTSTAR: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = OP_NOTSTAR)
                } else {
                    var __ci_expr_ternary_0: c_int = 0

                    if ((if c >= OP_STARI: 1 else: 0) != 0) {
                        (__ci_expr_ternary_0 = OP_STARI)
                    } else {
                        (__ci_expr_ternary_0 = OP_STAR)
                    }

                    (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                }

                (__ci_expr_ternary_2 = __ci_expr_ternary_1)

            }

            (__ci_expr_ternary_3 = __ci_expr_ternary_2)

        }

        (__ci_expr_ternary_4 = __ci_expr_ternary_3)

    }

    return __ci_expr_ternary_4


}

fn get_chr_property_list(__param_code: *const u8, utf: c_int, ucp: c_int, fcc: *const u8, list: *mut c_uint) -> *const u8 {
    var code = __param_code
    var c: u8 = (unsafe: *code)

    var base: u8

    var end: *const u8

    var class_end: *const u8

    var chr: c_uint

    var clist_dest: *mut c_uint

    var clist_src: *const c_uint

    ((unsafe: list[0]) = c)

    ((unsafe: list[1]) = 0)

    (code = code + 1)

    var __ci_expr_logic_0: c_int = 0

    if ((if c >= OP_STAR: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if c <= OP_TYPEPOSUPTO: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (base = get_repeat_base(c))

        (c = c - (base - OP_STAR))

        var __ci_expr_logic_3: c_int

        var __ci_expr_logic_2: c_int

        var __ci_expr_logic_1: c_int

        if ((if c == OP_UPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if c == OP_MINUPTO: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if c == OP_EXACT: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if c == OP_POSUPTO: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (code = code + 2)
        }


        var __ci_expr_logic_6: c_int = 0

        var __ci_expr_logic_5: c_int = 0

        var __ci_expr_logic_4: c_int = 0

        if ((if c != OP_PLUS: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if c != OP_MINPLUS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if c != OP_EXACT: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if c != OP_POSPLUS: 1 else: 0) != 0: 1 else: 0))
        }

        ((unsafe: list[1]) = __ci_expr_logic_6)


        while true {
            match base {
                33 => {
                    ((unsafe: list[0]) = 29)
                },
                46 => {
                    ((unsafe: list[0]) = 30)
                },
                59 => {
                    ((unsafe: list[0]) = 31)
                },
                72 => {
                    ((unsafe: list[0]) = 32)
                },
                85 => {
                    ((unsafe: list[0]) = (unsafe: *code))

                    (code = code + 1)

                },
            }

            break

        }

        (c = (unsafe: list[0]))

    }


    match c {
        6 => {
            return code
        },
        7 => {
            return code
        },
        8 => {
            return code
        },
        9 => {
            return code
        },
        10 => {
            return code
        },
        11 => {
            return code
        },
        12 => {
            return code
        },
        13 => {
            return code
        },
        17 => {
            return code
        },
        18 => {
            return code
        },
        19 => {
            return code
        },
        20 => {
            return code
        },
        21 => {
            return code
        },
        22 => {
            return code
        },
        23 => {
            return code
        },
        24 => {
            return code
        },
        25 => {
            return code
        },
        26 => {
            return code
        },
        29 => {
            var __ci_expr_old_8: *const u8 = code

            (code = code + 1)

            (chr = (unsafe: *__ci_expr_old_8))


            var __ci_expr_logic_9: c_int = 0

            if (utf != 0) {
                (__ci_expr_logic_9 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_10: *const u8 = code

                    (code = code + 1)

                    (chr = (((chr & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_10) & 63))

                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = ((((chr & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[1]) & 63))

                        (code = code + 2)

                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = (((((chr & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[2]) & 63))

                            (code = code + 3)

                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = ((((((chr & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[3]) & 63))

                                (code = code + 4)

                            } else {
                                (chr = (((((((chr & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[4]) & 63))

                                (code = code + 5)

                            }
                        }
                    }
                }

            }


            ((unsafe: list[2]) = chr)

            ((unsafe: list[3]) = 4294967295)

            return code

        },
        31 => {
            var __ci_expr_old_8: *const u8 = code

            (code = code + 1)

            (chr = (unsafe: *__ci_expr_old_8))


            var __ci_expr_logic_9: c_int = 0

            if (utf != 0) {
                (__ci_expr_logic_9 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_10: *const u8 = code

                    (code = code + 1)

                    (chr = (((chr & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_10) & 63))

                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = ((((chr & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[1]) & 63))

                        (code = code + 2)

                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = (((((chr & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[2]) & 63))

                            (code = code + 3)

                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = ((((((chr & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[3]) & 63))

                                (code = code + 4)

                            } else {
                                (chr = (((((((chr & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[4]) & 63))

                                (code = code + 5)

                            }
                        }
                    }
                }

            }


            ((unsafe: list[2]) = chr)

            ((unsafe: list[3]) = 4294967295)

            return code

        },
        30 => {
            var __ci_expr_ternary_11: c_int = 0

            if ((if c == OP_CHARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_11 = OP_CHAR)
            } else {
                (__ci_expr_ternary_11 = OP_NOT)
            }

            ((unsafe: list[0]) = __ci_expr_ternary_11)


            var __ci_expr_old_12: *const u8 = code

            (code = code + 1)

            (chr = (unsafe: *__ci_expr_old_12))


            var __ci_expr_logic_13: c_int = 0

            if (utf != 0) {
                (__ci_expr_logic_13 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_13 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_14: *const u8 = code

                    (code = code + 1)

                    (chr = (((chr & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_14) & 63))

                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = ((((chr & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[1]) & 63))

                        (code = code + 2)

                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = (((((chr & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[2]) & 63))

                            (code = code + 3)

                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = ((((((chr & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[3]) & 63))

                                (code = code + 4)

                            } else {
                                (chr = (((((((chr & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[4]) & 63))

                                (code = code + 5)

                            }
                        }
                    }
                }

            }


            ((unsafe: list[2]) = chr)

            var __ci_expr_logic_17: c_int

            if ((if chr < 128: 1 else: 0) != 0) {
                (__ci_expr_logic_17 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_16: c_int = 0

                var __ci_expr_logic_15: c_int = 0

                if ((if chr < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_15 = (if (if not (utf != 0): 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_15 != 0) {
                    (__ci_expr_logic_16 = (if (if not (ucp != 0): 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_17 != 0) {
                ((unsafe: list[3]) = (unsafe: fcc[chr]))
            } else {
                ((unsafe: list[3]) = ((((chr as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((chr as c_int) / 128)] * 128) + ((chr as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))
            }


            if ((if chr == (unsafe: list[3]): 1 else: 0) != 0) {
                ((unsafe: list[3]) = 4294967295)
            } else {
                ((unsafe: list[4]) = 4294967295)
            }

            return code

        },
        32 => {
            var __ci_expr_ternary_11: c_int = 0

            if ((if c == OP_CHARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_11 = OP_CHAR)
            } else {
                (__ci_expr_ternary_11 = OP_NOT)
            }

            ((unsafe: list[0]) = __ci_expr_ternary_11)


            var __ci_expr_old_12: *const u8 = code

            (code = code + 1)

            (chr = (unsafe: *__ci_expr_old_12))


            var __ci_expr_logic_13: c_int = 0

            if (utf != 0) {
                (__ci_expr_logic_13 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_13 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_14: *const u8 = code

                    (code = code + 1)

                    (chr = (((chr & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_14) & 63))

                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = ((((chr & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[1]) & 63))

                        (code = code + 2)

                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = (((((chr & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[2]) & 63))

                            (code = code + 3)

                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = ((((((chr & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[3]) & 63))

                                (code = code + 4)

                            } else {
                                (chr = (((((((chr & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *code) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: code[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: code[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: code[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: code[4]) & 63))

                                (code = code + 5)

                            }
                        }
                    }
                }

            }


            ((unsafe: list[2]) = chr)

            var __ci_expr_logic_17: c_int

            if ((if chr < 128: 1 else: 0) != 0) {
                (__ci_expr_logic_17 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_16: c_int = 0

                var __ci_expr_logic_15: c_int = 0

                if ((if chr < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_15 = (if (if not (utf != 0): 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_15 != 0) {
                    (__ci_expr_logic_16 = (if (if not (ucp != 0): 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_17 != 0) {
                ((unsafe: list[3]) = (unsafe: fcc[chr]))
            } else {
                ((unsafe: list[3]) = ((((chr as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((chr as c_int) / 128)] * 128) + ((chr as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))
            }


            if ((if chr == (unsafe: list[3]): 1 else: 0) != 0) {
                ((unsafe: list[3]) = 4294967295)
            } else {
                ((unsafe: list[4]) = 4294967295)
            }

            return code

        },
        16 => {
            if ((if (unsafe: code[0]) != 9: 1 else: 0) != 0) {
                ((unsafe: list[2]) = (unsafe: code[0]))

                ((unsafe: list[3]) = (unsafe: code[1]))

                return (code + ((2 as isize) as usize))

            }

            (clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe: code[1]) as isize) as usize))

            (clist_dest = list + ((2 as isize) as usize))

            (code = code + 2)

            while true {
                if ((if clist_dest >= (list + ((8 as isize) as usize)): 1 else: 0) != 0) {
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    ((unsafe: list[2]) = (unsafe: code[0]))

                    ((unsafe: list[3]) = (unsafe: code[1]))

                    return code

                }

                var __ci_expr_old_19: *mut c_uint = clist_dest

                (clist_dest = clist_dest + 1)

                ((unsafe: *__ci_expr_old_19) = (unsafe: *clist_src))

                var __ci_expr_old_18: *const c_uint = clist_src

                (clist_src = clist_src + 1)

                if (not ((if (unsafe: *__ci_expr_old_18) != 4294967295: 1 else: 0) != 0)) {
                    break
                }

            }

            var __ci_expr_ternary_20: c_int = 0

            if ((if c == OP_PROP: 1 else: 0) != 0) {
                (__ci_expr_ternary_20 = OP_CHAR)
            } else {
                (__ci_expr_ternary_20 = OP_NOT)
            }

            ((unsafe: list[0]) = __ci_expr_ternary_20)


            return code

        },
        15 => {
            if ((if (unsafe: code[0]) != 9: 1 else: 0) != 0) {
                ((unsafe: list[2]) = (unsafe: code[0]))

                ((unsafe: list[3]) = (unsafe: code[1]))

                return (code + ((2 as isize) as usize))

            }

            (clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe: code[1]) as isize) as usize))

            (clist_dest = list + ((2 as isize) as usize))

            (code = code + 2)

            while true {
                if ((if clist_dest >= (list + ((8 as isize) as usize)): 1 else: 0) != 0) {
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    ((unsafe: list[2]) = (unsafe: code[0]))

                    ((unsafe: list[3]) = (unsafe: code[1]))

                    return code

                }

                var __ci_expr_old_19: *mut c_uint = clist_dest

                (clist_dest = clist_dest + 1)

                ((unsafe: *__ci_expr_old_19) = (unsafe: *clist_src))

                var __ci_expr_old_18: *const c_uint = clist_src

                (clist_src = clist_src + 1)

                if (not ((if (unsafe: *__ci_expr_old_18) != 4294967295: 1 else: 0) != 0)) {
                    break
                }

            }

            var __ci_expr_ternary_20: c_int = 0

            if ((if c == OP_PROP: 1 else: 0) != 0) {
                (__ci_expr_ternary_20 = OP_CHAR)
            } else {
                (__ci_expr_ternary_20 = OP_NOT)
            }

            ((unsafe: list[0]) = __ci_expr_ternary_20)


            return code

        },
        111 => {
            var __ci_expr_logic_21: c_int

            if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (end = (code + (((((unsafe: code[0]) as c_int) << (8 as c_uint)) | (unsafe: code[(0 + 1)])) as c_uint)) - ((1 as isize) as usize))
            } else {
                (end = code + (32 / sizeof[u8]()))
            }


            (class_end = end)

            while true {
                match (unsafe: *end) {
                    98 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    99 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    102 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    103 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    106 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    108 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    100 => {
                        (end = end + 1)
                    },
                    101 => {
                        (end = end + 1)
                    },
                    107 => {
                        (end = end + 1)
                    },
                    104 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    105 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    109 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                }

                break

            }

            ((unsafe: list[2]) = (((((end as usize) -% (code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe: list[3]) = (((((end as usize) -% (class_end as usize)) / sizeof[u8]()) as c_uint)))

            return end

        },
        110 => {
            var __ci_expr_logic_21: c_int

            if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (end = (code + (((((unsafe: code[0]) as c_int) << (8 as c_uint)) | (unsafe: code[(0 + 1)])) as c_uint)) - ((1 as isize) as usize))
            } else {
                (end = code + (32 / sizeof[u8]()))
            }


            (class_end = end)

            while true {
                match (unsafe: *end) {
                    98 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    99 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    102 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    103 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    106 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    108 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    100 => {
                        (end = end + 1)
                    },
                    101 => {
                        (end = end + 1)
                    },
                    107 => {
                        (end = end + 1)
                    },
                    104 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    105 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    109 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                }

                break

            }

            ((unsafe: list[2]) = (((((end as usize) -% (code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe: list[3]) = (((((end as usize) -% (class_end as usize)) / sizeof[u8]()) as c_uint)))

            return end

        },
        112 => {
            var __ci_expr_logic_21: c_int

            if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (end = (code + (((((unsafe: code[0]) as c_int) << (8 as c_uint)) | (unsafe: code[(0 + 1)])) as c_uint)) - ((1 as isize) as usize))
            } else {
                (end = code + (32 / sizeof[u8]()))
            }


            (class_end = end)

            while true {
                match (unsafe: *end) {
                    98 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    99 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    102 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    103 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    106 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    108 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    100 => {
                        (end = end + 1)
                    },
                    101 => {
                        (end = end + 1)
                    },
                    107 => {
                        (end = end + 1)
                    },
                    104 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    105 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    109 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                }

                break

            }

            ((unsafe: list[2]) = (((((end as usize) -% (code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe: list[3]) = (((((end as usize) -% (class_end as usize)) / sizeof[u8]()) as c_uint)))

            return end

        },
        113 => {
            var __ci_expr_logic_21: c_int

            if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (end = (code + (((((unsafe: code[0]) as c_int) << (8 as c_uint)) | (unsafe: code[(0 + 1)])) as c_uint)) - ((1 as isize) as usize))
            } else {
                (end = code + (32 / sizeof[u8]()))
            }


            (class_end = end)

            while true {
                match (unsafe: *end) {
                    98 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    99 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    102 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    103 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    106 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    108 => {
                        ((unsafe: list[1]) = 1)

                        (end = end + 1)

                    },
                    100 => {
                        (end = end + 1)
                    },
                    101 => {
                        (end = end + 1)
                    },
                    107 => {
                        (end = end + 1)
                    },
                    104 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    105 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                    109 => {
                        ((unsafe: list[1]) = (if ((((((unsafe: end[1]) as c_int) << (8 as c_uint)) | (unsafe: end[(1 + 1)])) as c_uint)) == 0: 1 else: 0))

                        (end = end + (1 + (2 * 2)))

                    },
                }

                break

            }

            ((unsafe: list[2]) = (((((end as usize) -% (code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe: list[3]) = (((((end as usize) -% (class_end as usize)) / sizeof[u8]()) as c_uint)))

            return end

        },
    }

    return null

}

fn compare_opcodes(__param_code: *const u8, utf: c_int, ucp: c_int, cb: *const compile_block_8, base_list: *const c_uint, base_end: *const u8, rec_limit: *mut c_int) -> c_int {
    var code = __param_code
    var c: u8

    var list: [8]c_uint

    var chr_ptr: *const c_uint

    var ochr_ptr: *const c_uint

    var list_ptr: *const c_uint

    var next_code: *const u8

    var xclass_flags: *const u8

    var class_bitset: *const u8

    var set1: *const u8

    var set2: *const u8

    var set_end: *const u8


    var chr: c_uint

    var accepted: c_int

    var invert_bits: c_int


    var entered_a_group: c_int = 0

    ((unsafe: *rec_limit) = (unsafe: *rec_limit) - 1)

    if ((if (unsafe: *rec_limit) <= 0: 1 else: 0) != 0) {
        return 0
    }


    while true {
        var bracode: *const u8

        (c = (unsafe: *code))

        if ((if c == OP_CALLOUT: 1 else: 0) != 0) {
            (code = code + _pcre2_OP_lengths_8[c])

            continue

        }

        if ((if c == OP_CALLOUT_STR: 1 else: 0) != 0) {
            (code = code + (((((unsafe: code[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: code[((1 + (2 * 2)) + 1)])) as c_uint))

            continue

        }

        if ((if c == OP_ALT: 1 else: 0) != 0) {
            while true {
                (code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))

                if (not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0)) {
                    break
                }

            }

            (c = (unsafe: *code))

        }

        var __ci_expr_switch_continue_4: i32 = 0

        while true {
            match c {
                0 => {
                    return (if (unsafe: base_list[1]) != 0: 1 else: 0)
                },
                122 => {
                    if ((if (unsafe: base_list[1]) == 0: 1 else: 0) != 0) {
                        return 0
                    }

                    (bracode = code - (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))

                    while true {
                        match (unsafe: *bracode) {
                            139 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            144 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            140 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            145 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            136 => {
                                var __ci_expr_logic_0: c_int = 0

                                if ((if (unsafe: base_list[0]) != 29: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (unsafe: base_list[0]) != 30: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    return 0
                                }

                            },
                            128 => {
                                return (if not (entered_a_group != 0): 1 else: 0)
                            },
                            129 => {
                                return (if not (entered_a_group != 0): 1 else: 0)
                            },
                            135 => {
                                return (if not (entered_a_group != 0): 1 else: 0)
                            },
                            130 => {
                                while true {
                                    if ((if (unsafe: bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (bracode = bracode + (((((unsafe: bracode[1]) as c_int) << (8 as c_uint)) | (unsafe: bracode[(1 + 1)])) as c_uint))

                                    if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                return (if not (entered_a_group != 0): 1 else: 0)

                            },
                            131 => {
                                while true {
                                    if ((if (unsafe: bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (bracode = bracode + (((((unsafe: bracode[1]) as c_int) << (8 as c_uint)) | (unsafe: bracode[(1 + 1)])) as c_uint))

                                    if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                return (if not (entered_a_group != 0): 1 else: 0)

                            },
                            132 => {
                                return 0
                            },
                            133 => {
                                return 0
                            },
                        }

                        break

                    }

                    (code = code + _pcre2_OP_lengths_8[c])

                    continue

                },
                125 => {
                    if ((if (unsafe: base_list[1]) == 0: 1 else: 0) != 0) {
                        return 0
                    }

                    (bracode = code - (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))

                    while true {
                        match (unsafe: *bracode) {
                            139 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            144 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            140 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            145 => {
                                if (cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            136 => {
                                var __ci_expr_logic_0: c_int = 0

                                if ((if (unsafe: base_list[0]) != 29: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (unsafe: base_list[0]) != 30: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    return 0
                                }

                            },
                            128 => {
                                return (if not (entered_a_group != 0): 1 else: 0)
                            },
                            129 => {
                                return (if not (entered_a_group != 0): 1 else: 0)
                            },
                            135 => {
                                return (if not (entered_a_group != 0): 1 else: 0)
                            },
                            130 => {
                                while true {
                                    if ((if (unsafe: bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (bracode = bracode + (((((unsafe: bracode[1]) as c_int) << (8 as c_uint)) | (unsafe: bracode[(1 + 1)])) as c_uint))

                                    if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                return (if not (entered_a_group != 0): 1 else: 0)

                            },
                            131 => {
                                while true {
                                    if ((if (unsafe: bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (bracode = bracode + (((((unsafe: bracode[1]) as c_int) << (8 as c_uint)) | (unsafe: bracode[(1 + 1)])) as c_uint))

                                    if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                return (if not (entered_a_group != 0): 1 else: 0)

                            },
                            132 => {
                                return 0
                            },
                            133 => {
                                return 0
                            },
                        }

                        break

                    }

                    (code = code + _pcre2_OP_lengths_8[c])

                    continue

                },
                135 => {
                    (next_code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))

                    (code = code + _pcre2_OP_lengths_8[c])

                    while ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0) {
                        if ((if not (compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        (code = (next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (next_code = next_code + (((((unsafe: next_code[1]) as c_int) << (8 as c_uint)) | (unsafe: next_code[(1 + 1)])) as c_uint))

                    }

                    (entered_a_group = 1)

                    continue

                },
                137 => {
                    (next_code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))

                    (code = code + _pcre2_OP_lengths_8[c])

                    while ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0) {
                        if ((if not (compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        (code = (next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (next_code = next_code + (((((unsafe: next_code[1]) as c_int) << (8 as c_uint)) | (unsafe: next_code[(1 + 1)])) as c_uint))

                    }

                    (entered_a_group = 1)

                    continue

                },
                139 => {
                    (next_code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))

                    (code = code + _pcre2_OP_lengths_8[c])

                    while ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0) {
                        if ((if not (compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        (code = (next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (next_code = next_code + (((((unsafe: next_code[1]) as c_int) << (8 as c_uint)) | (unsafe: next_code[(1 + 1)])) as c_uint))

                    }

                    (entered_a_group = 1)

                    continue

                },
                153 => {
                    (next_code = code + ((1 as isize) as usize))

                    var __ci_expr_logic_3: c_int = 0

                    var __ci_expr_logic_2: c_int = 0

                    if ((if (unsafe: *next_code) != OP_BRA: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if (unsafe: *next_code) != OP_CBRA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if (if (unsafe: *next_code) != OP_ONCE: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_3 != 0) {
                        return 0
                    }


                    while true {
                        (next_code = next_code + (((((unsafe: next_code[1]) as c_int) << (8 as c_uint)) | (unsafe: next_code[(1 + 1)])) as c_uint))

                        if (not ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0)) {
                            break
                        }

                    }

                    (next_code = next_code + (1 + 2))

                    if ((if not (compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    (code = code + _pcre2_OP_lengths_8[c])

                    continue

                },
                154 => {
                    (next_code = code + ((1 as isize) as usize))

                    var __ci_expr_logic_3: c_int = 0

                    var __ci_expr_logic_2: c_int = 0

                    if ((if (unsafe: *next_code) != OP_BRA: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if (unsafe: *next_code) != OP_CBRA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if (if (unsafe: *next_code) != OP_ONCE: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_3 != 0) {
                        return 0
                    }


                    while true {
                        (next_code = next_code + (((((unsafe: next_code[1]) as c_int) << (8 as c_uint)) | (unsafe: next_code[(1 + 1)])) as c_uint))

                        if (not ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0)) {
                            break
                        }

                    }

                    (next_code = next_code + (1 + 2))

                    if ((if not (compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    (code = code + _pcre2_OP_lengths_8[c])

                    continue

                },
                _ => {
                    0
                },
            }

            break

        }

        if (__ci_expr_switch_continue_4 != 0) {
            continue
        }


        (code = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))

        if ((if code == null: 1 else: 0) != 0) {
            return 0
        }

        if ((if (unsafe: base_list[0]) == 29: 1 else: 0) != 0) {
            (chr_ptr = base_list + ((2 as isize) as usize))

            (list_ptr = (&list[0] as *const c_uint))

        } else {
            if ((if list[0] == 29: 1 else: 0) != 0) {
                (chr_ptr = ((((&list[0] as *mut c_uint) + ((2 as isize) as usize)) as *const c_uint)))

                (list_ptr = base_list)

            } else {
                var __ci_expr_logic_8: c_int

                var __ci_expr_logic_5: c_int

                if ((if (unsafe: base_list[0]) == 110: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if (if list[0] == 110: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_7: c_int = 0

                    if ((if not (utf != 0): 1 else: 0) != 0) {
                        var __ci_expr_logic_6: c_int

                        if ((if (unsafe: base_list[0]) == 111: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if list[0] == 111: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_7 = (if __ci_expr_logic_6 != 0: 1 else: 0))

                    }

                    (__ci_expr_logic_8 = (if __ci_expr_logic_7 != 0: 1 else: 0))

                }

                if (__ci_expr_logic_8 != 0) {
                    var __ci_expr_logic_10: c_int

                    if ((if (unsafe: base_list[0]) == 110: 1 else: 0) != 0) {
                        (__ci_expr_logic_10 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_9: c_int = 0

                        if ((if not (utf != 0): 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if (if (unsafe: base_list[0]) == 111: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_10 != 0) {
                        (set1 = base_end - (unsafe: base_list[2]))

                        (list_ptr = (&list[0] as *const c_uint))

                    } else {
                        (set1 = code - list[2])

                        (list_ptr = base_list)

                    }


                    (invert_bits = 0)

                    var __ci_expr_switch_continue_13: i32 = 0

                    while true {
                        match (unsafe: list_ptr[0]) {
                            110 => {
                                var __ci_expr_ternary_11: *const u8 = null

                                if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                                    (__ci_expr_ternary_11 = code)
                                } else {
                                    (__ci_expr_ternary_11 = base_end)
                                }

                                (set2 = __ci_expr_ternary_11 - (unsafe: list_ptr[2]))

                            },
                            111 => {
                                var __ci_expr_ternary_11: *const u8 = null

                                if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                                    (__ci_expr_ternary_11 = code)
                                } else {
                                    (__ci_expr_ternary_11 = base_end)
                                }

                                (set2 = __ci_expr_ternary_11 - (unsafe: list_ptr[2]))

                            },
                            112 => {
                                var __ci_expr_ternary_12: *const u8 = null

                                if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                                    (__ci_expr_ternary_12 = code)
                                } else {
                                    (__ci_expr_ternary_12 = base_end)
                                }

                                (xclass_flags = (__ci_expr_ternary_12 - (unsafe: list_ptr[2])) + ((2 as isize) as usize))


                                if ((if ((unsafe: *xclass_flags) & 4) != 0: 1 else: 0) != 0) {
                                    return 0
                                }

                                if ((if ((unsafe: *xclass_flags) & 2) == 0: 1 else: 0) != 0) {
                                    if ((if list[1] == 0: 1 else: 0) != 0) {
                                        return (if ((unsafe: *xclass_flags) & 1) == 0: 1 else: 0)
                                    }

                                    continue

                                }

                                (set2 = xclass_flags + ((1 as isize) as usize))

                            },
                            6 => {
                                (invert_bits = 1)

                                (set2 = cb.cbits + ((64 as isize) as usize))

                            },
                            7 => {
                                (set2 = cb.cbits + ((64 as isize) as usize))
                            },
                            8 => {
                                (invert_bits = 1)

                                (set2 = cb.cbits + ((0 as isize) as usize))

                            },
                            9 => {
                                (set2 = cb.cbits + ((0 as isize) as usize))
                            },
                            10 => {
                                (invert_bits = 1)

                                (set2 = cb.cbits + ((160 as isize) as usize))

                            },
                            11 => {
                                (set2 = cb.cbits + ((160 as isize) as usize))
                            },
                            _ => {
                                return 0
                            },
                        }

                        break

                    }

                    if (__ci_expr_switch_continue_13 != 0) {
                        continue
                    }


                    (set_end = set1 + ((32 as isize) as usize))

                    if (invert_bits != 0) {
                        while true {
                            var __ci_expr_old_14: *const u8 = set1

                            (set1 = set1 + 1)

                            var __ci_expr_old_15: *const u8 = set2

                            (set2 = set2 + 1)

                            if ((if ((unsafe: *__ci_expr_old_14) & (~(unsafe: *__ci_expr_old_15))) != 0: 1 else: 0) != 0) {
                                return 0
                            }

                            if (not ((if set1 < set_end: 1 else: 0) != 0)) {
                                break
                            }

                        }

                    } else {
                        while true {
                            var __ci_expr_old_16: *const u8 = set1

                            (set1 = set1 + 1)

                            var __ci_expr_old_17: *const u8 = set2

                            (set2 = set2 + 1)

                            if ((if ((unsafe: *__ci_expr_old_16) & (unsafe: *__ci_expr_old_17)) != 0: 1 else: 0) != 0) {
                                return 0
                            }

                            if (not ((if set1 < set_end: 1 else: 0) != 0)) {
                                break
                            }

                        }

                    }

                    if ((if list[1] == 0: 1 else: 0) != 0) {
                        return 1
                    }

                    continue

                } else {
                    var leftop: c_uint

                    var rightop: c_uint


                    (leftop = (unsafe: base_list[0]))

                    (rightop = list[0])

                    (accepted = 0)

                    var __ci_expr_logic_18: c_int

                    if ((if leftop == 16: 1 else: 0) != 0) {
                        (__ci_expr_logic_18 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_18 = (if (if leftop == 15: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_18 != 0) {
                        if ((if rightop == 24: 1 else: 0) != 0) {
                            (accepted = 1)
                        } else {
                            var __ci_expr_logic_19: c_int

                            if ((if rightop == 16: 1 else: 0) != 0) {
                                (__ci_expr_logic_19 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_19 = (if (if rightop == 15: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_19 != 0) {
                                var n: c_int

                                var p: *const u8

                                var same: c_int = (if leftop == rightop: 1 else: 0)

                                var lisprop: c_int = (if leftop == 16: 1 else: 0)

                                var risprop: c_int = (if rightop == 16: 1 else: 0)

                                var bothprop: c_int = with 0 as __ci_expr_seq_279 {
                                    var __ci_expr_logic_20: c_int = 0
                                    if (lisprop != 0) {
                                        (__ci_expr_logic_20 = (if risprop != 0: 1 else: 0))
                                    }
                                    __ci_expr_logic_20
                                }

                                (n = propposstab[(unsafe: base_list[2])][list[2]])

                                while true {
                                    match n {
                                        0 => {
                                            0
                                        },
                                        1 => {
                                            (accepted = bothprop)
                                        },
                                        2 => {
                                            (accepted = (if (if (unsafe: base_list[3]) == list[3]: 1 else: 0) != same: 1 else: 0))
                                        },
                                        3 => {
                                            (accepted = (if not (same != 0): 1 else: 0))
                                        },
                                        4 => {
                                            var __ci_expr_logic_21: c_int = 0

                                            if (risprop != 0) {
                                                (__ci_expr_logic_21 = (if (if catposstab[(unsafe: base_list[3])][list[3]] == same: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            (accepted = __ci_expr_logic_21)

                                        },
                                        5 => {
                                            var __ci_expr_logic_22: c_int = 0

                                            if (lisprop != 0) {
                                                (__ci_expr_logic_22 = (if (if catposstab[list[3]][(unsafe: base_list[3])] == same: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            (accepted = __ci_expr_logic_22)

                                        },
                                        6 => {
                                            (p = (&posspropstab[(n - 6)][0] as *const u8))

                                            var __ci_expr_logic_26: c_int = 0

                                            if (risprop != 0) {
                                                var __ci_expr_logic_25: c_int = 0

                                                var __ci_expr_logic_23: c_int = 0

                                                if ((if list[3] != (unsafe: p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_23 = (if (if list[3] != (unsafe: p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_23 != 0) {
                                                    var __ci_expr_logic_24: c_int

                                                    if ((if list[3] != (unsafe: p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_24 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_24 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_26 = (if (if lisprop == __ci_expr_logic_25: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_26)


                                        },
                                        7 => {
                                            (p = (&posspropstab[(n - 6)][0] as *const u8))

                                            var __ci_expr_logic_26: c_int = 0

                                            if (risprop != 0) {
                                                var __ci_expr_logic_25: c_int = 0

                                                var __ci_expr_logic_23: c_int = 0

                                                if ((if list[3] != (unsafe: p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_23 = (if (if list[3] != (unsafe: p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_23 != 0) {
                                                    var __ci_expr_logic_24: c_int

                                                    if ((if list[3] != (unsafe: p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_24 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_24 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_26 = (if (if lisprop == __ci_expr_logic_25: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_26)


                                        },
                                        8 => {
                                            (p = (&posspropstab[(n - 6)][0] as *const u8))

                                            var __ci_expr_logic_26: c_int = 0

                                            if (risprop != 0) {
                                                var __ci_expr_logic_25: c_int = 0

                                                var __ci_expr_logic_23: c_int = 0

                                                if ((if list[3] != (unsafe: p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_23 = (if (if list[3] != (unsafe: p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_23 != 0) {
                                                    var __ci_expr_logic_24: c_int

                                                    if ((if list[3] != (unsafe: p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_24 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_24 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_26 = (if (if lisprop == __ci_expr_logic_25: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_26)


                                        },
                                        9 => {
                                            (p = (&posspropstab[(n - 9)][0] as *const u8))

                                            var __ci_expr_logic_30: c_int = 0

                                            if (lisprop != 0) {
                                                var __ci_expr_logic_29: c_int = 0

                                                var __ci_expr_logic_27: c_int = 0

                                                if ((if (unsafe: base_list[3]) != (unsafe: p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_27 = (if (if (unsafe: base_list[3]) != (unsafe: p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_27 != 0) {
                                                    var __ci_expr_logic_28: c_int

                                                    if ((if (unsafe: base_list[3]) != (unsafe: p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_28 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_30 = (if (if risprop == __ci_expr_logic_29: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_30)


                                        },
                                        10 => {
                                            (p = (&posspropstab[(n - 9)][0] as *const u8))

                                            var __ci_expr_logic_30: c_int = 0

                                            if (lisprop != 0) {
                                                var __ci_expr_logic_29: c_int = 0

                                                var __ci_expr_logic_27: c_int = 0

                                                if ((if (unsafe: base_list[3]) != (unsafe: p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_27 = (if (if (unsafe: base_list[3]) != (unsafe: p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_27 != 0) {
                                                    var __ci_expr_logic_28: c_int

                                                    if ((if (unsafe: base_list[3]) != (unsafe: p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_28 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_30 = (if (if risprop == __ci_expr_logic_29: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_30)


                                        },
                                        11 => {
                                            (p = (&posspropstab[(n - 9)][0] as *const u8))

                                            var __ci_expr_logic_30: c_int = 0

                                            if (lisprop != 0) {
                                                var __ci_expr_logic_29: c_int = 0

                                                var __ci_expr_logic_27: c_int = 0

                                                if ((if (unsafe: base_list[3]) != (unsafe: p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_27 = (if (if (unsafe: base_list[3]) != (unsafe: p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_27 != 0) {
                                                    var __ci_expr_logic_28: c_int

                                                    if ((if (unsafe: base_list[3]) != (unsafe: p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_28 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_30 = (if (if risprop == __ci_expr_logic_29: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_30)


                                        },
                                        12 => {
                                            (p = (&posspropstab[(n - 12)][0] as *const u8))

                                            var __ci_expr_logic_34: c_int = 0

                                            if (risprop != 0) {
                                                var __ci_expr_logic_33: c_int = 0

                                                var __ci_expr_logic_31: c_int = 0

                                                if (catposstab[(unsafe: p[0])][list[3]] != 0) {
                                                    (__ci_expr_logic_31 = (if catposstab[(unsafe: p[1])][list[3]] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_31 != 0) {
                                                    var __ci_expr_logic_32: c_int

                                                    if ((if list[3] != (unsafe: p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_32 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_34 = (if (if lisprop == __ci_expr_logic_33: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_34)


                                        },
                                        13 => {
                                            (p = (&posspropstab[(n - 12)][0] as *const u8))

                                            var __ci_expr_logic_34: c_int = 0

                                            if (risprop != 0) {
                                                var __ci_expr_logic_33: c_int = 0

                                                var __ci_expr_logic_31: c_int = 0

                                                if (catposstab[(unsafe: p[0])][list[3]] != 0) {
                                                    (__ci_expr_logic_31 = (if catposstab[(unsafe: p[1])][list[3]] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_31 != 0) {
                                                    var __ci_expr_logic_32: c_int

                                                    if ((if list[3] != (unsafe: p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_32 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_34 = (if (if lisprop == __ci_expr_logic_33: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_34)


                                        },
                                        14 => {
                                            (p = (&posspropstab[(n - 12)][0] as *const u8))

                                            var __ci_expr_logic_34: c_int = 0

                                            if (risprop != 0) {
                                                var __ci_expr_logic_33: c_int = 0

                                                var __ci_expr_logic_31: c_int = 0

                                                if (catposstab[(unsafe: p[0])][list[3]] != 0) {
                                                    (__ci_expr_logic_31 = (if catposstab[(unsafe: p[1])][list[3]] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_31 != 0) {
                                                    var __ci_expr_logic_32: c_int

                                                    if ((if list[3] != (unsafe: p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_32 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_34 = (if (if lisprop == __ci_expr_logic_33: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_34)


                                        },
                                        15 => {
                                            (p = (&posspropstab[(n - 15)][0] as *const u8))

                                            var __ci_expr_logic_38: c_int = 0

                                            if (lisprop != 0) {
                                                var __ci_expr_logic_37: c_int = 0

                                                var __ci_expr_logic_35: c_int = 0

                                                if (catposstab[(unsafe: p[0])][(unsafe: base_list[3])] != 0) {
                                                    (__ci_expr_logic_35 = (if catposstab[(unsafe: p[1])][(unsafe: base_list[3])] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_35 != 0) {
                                                    var __ci_expr_logic_36: c_int

                                                    if ((if (unsafe: base_list[3]) != (unsafe: p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_36 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_38 = (if (if risprop == __ci_expr_logic_37: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_38)


                                        },
                                        16 => {
                                            (p = (&posspropstab[(n - 15)][0] as *const u8))

                                            var __ci_expr_logic_38: c_int = 0

                                            if (lisprop != 0) {
                                                var __ci_expr_logic_37: c_int = 0

                                                var __ci_expr_logic_35: c_int = 0

                                                if (catposstab[(unsafe: p[0])][(unsafe: base_list[3])] != 0) {
                                                    (__ci_expr_logic_35 = (if catposstab[(unsafe: p[1])][(unsafe: base_list[3])] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_35 != 0) {
                                                    var __ci_expr_logic_36: c_int

                                                    if ((if (unsafe: base_list[3]) != (unsafe: p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_36 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_38 = (if (if risprop == __ci_expr_logic_37: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_38)


                                        },
                                        17 => {
                                            (p = (&posspropstab[(n - 15)][0] as *const u8))

                                            var __ci_expr_logic_38: c_int = 0

                                            if (lisprop != 0) {
                                                var __ci_expr_logic_37: c_int = 0

                                                var __ci_expr_logic_35: c_int = 0

                                                if (catposstab[(unsafe: p[0])][(unsafe: base_list[3])] != 0) {
                                                    (__ci_expr_logic_35 = (if catposstab[(unsafe: p[1])][(unsafe: base_list[3])] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_35 != 0) {
                                                    var __ci_expr_logic_36: c_int

                                                    if ((if (unsafe: base_list[3]) != (unsafe: p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_36 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_38 = (if (if risprop == __ci_expr_logic_37: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (accepted = __ci_expr_logic_38)


                                        },
                                    }

                                    break

                                }

                            }

                        }

                    } else {
                        var __ci_expr_logic_43: c_int = 0

                        var __ci_expr_logic_42: c_int = 0

                        var __ci_expr_logic_41: c_int = 0

                        var __ci_expr_logic_40: c_int = 0

                        if ((if leftop >= 6: 1 else: 0) != 0) {
                            (__ci_expr_logic_40 = (if (if leftop <= 22: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_40 != 0) {
                            (__ci_expr_logic_41 = (if (if rightop >= 6: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_41 != 0) {
                            (__ci_expr_logic_42 = (if (if rightop <= 26: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_42 != 0) {
                            (__ci_expr_logic_43 = (if autoposstab[(leftop -% 6)][(rightop -% 6)] != 0: 1 else: 0))
                        }

                        (accepted = __ci_expr_logic_43)

                    }


                    if ((if not (accepted != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    if ((if list[1] == 0: 1 else: 0) != 0) {
                        return 1
                    }

                    continue

                }

            }
        }

        while true {
            (chr = (unsafe: *chr_ptr))

            while true {
                match (unsafe: list_ptr[0]) {
                    29 => {
                        (ochr_ptr = list_ptr + ((2 as isize) as usize))

                        while true {
                            if ((if chr == (unsafe: *ochr_ptr): 1 else: 0) != 0) {
                                return 0
                            }

                            (ochr_ptr = ochr_ptr + 1)

                            if (not ((if (unsafe: *ochr_ptr) != 4294967295: 1 else: 0) != 0)) {
                                break
                            }

                        }

                    },
                    31 => {
                        (ochr_ptr = list_ptr + ((2 as isize) as usize))

                        while true {
                            if ((if chr == (unsafe: *ochr_ptr): 1 else: 0) != 0) {
                                break
                            }

                            (ochr_ptr = ochr_ptr + 1)

                            if (not ((if (unsafe: *ochr_ptr) != 4294967295: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        if ((if (unsafe: *ochr_ptr) == 4294967295: 1 else: 0) != 0) {
                            return 0
                        }

                    },
                    7 => {
                        var __ci_expr_logic_44: c_int = 0

                        if ((if chr < 256: 1 else: 0) != 0) {
                            (__ci_expr_logic_44 = (if (if ((unsafe: cb.ctypes[chr]) & 8) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_44 != 0) {
                            return 0
                        }

                    },
                    6 => {
                        var __ci_expr_logic_45: c_int

                        if ((if chr > 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_45 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_45 = (if (if ((unsafe: cb.ctypes[chr]) & 8) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_45 != 0) {
                            return 0
                        }

                    },
                    9 => {
                        var __ci_expr_logic_46: c_int = 0

                        if ((if chr < 256: 1 else: 0) != 0) {
                            (__ci_expr_logic_46 = (if (if ((unsafe: cb.ctypes[chr]) & 1) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_46 != 0) {
                            return 0
                        }

                    },
                    8 => {
                        var __ci_expr_logic_47: c_int

                        if ((if chr > 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_47 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_47 = (if (if ((unsafe: cb.ctypes[chr]) & 1) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_47 != 0) {
                            return 0
                        }

                    },
                    11 => {
                        var __ci_expr_logic_48: c_int = 0

                        if ((if chr < 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_48 = (if (if ((unsafe: cb.ctypes[chr]) & 16) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_48 != 0) {
                            return 0
                        }

                    },
                    10 => {
                        var __ci_expr_logic_49: c_int

                        if ((if chr > 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_49 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_49 = (if (if ((unsafe: cb.ctypes[chr]) & 16) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_49 != 0) {
                            return 0
                        }

                    },
                    19 => {
                        while true {
                            match chr {
                                9 => {
                                    return 0
                                },
                                32 => {
                                    return 0
                                },
                                160 => {
                                    return 0
                                },
                                5760 => {
                                    return 0
                                },
                                6158 => {
                                    return 0
                                },
                                8192 => {
                                    return 0
                                },
                                8193 => {
                                    return 0
                                },
                                8194 => {
                                    return 0
                                },
                                8195 => {
                                    return 0
                                },
                                8196 => {
                                    return 0
                                },
                                8197 => {
                                    return 0
                                },
                                8198 => {
                                    return 0
                                },
                                8199 => {
                                    return 0
                                },
                                8200 => {
                                    return 0
                                },
                                8201 => {
                                    return 0
                                },
                                8202 => {
                                    return 0
                                },
                                8239 => {
                                    return 0
                                },
                                8287 => {
                                    return 0
                                },
                                12288 => {
                                    return 0
                                },
                                _ => {
                                    0
                                },
                            }

                            break

                        }
                    },
                    18 => {
                        while true {
                            match chr {
                                9 => {
                                    0
                                },
                                32 => {
                                    0
                                },
                                160 => {
                                    0
                                },
                                5760 => {
                                    0
                                },
                                6158 => {
                                    0
                                },
                                8192 => {
                                    0
                                },
                                8193 => {
                                    0
                                },
                                8194 => {
                                    0
                                },
                                8195 => {
                                    0
                                },
                                8196 => {
                                    0
                                },
                                8197 => {
                                    0
                                },
                                8198 => {
                                    0
                                },
                                8199 => {
                                    0
                                },
                                8200 => {
                                    0
                                },
                                8201 => {
                                    0
                                },
                                8202 => {
                                    0
                                },
                                8239 => {
                                    0
                                },
                                8287 => {
                                    0
                                },
                                12288 => {
                                    0
                                },
                                _ => {
                                    return 0
                                },
                            }

                            break

                        }
                    },
                    17 => {
                        while true {
                            match chr {
                                10 => {
                                    return 0
                                },
                                11 => {
                                    return 0
                                },
                                12 => {
                                    return 0
                                },
                                13 => {
                                    return 0
                                },
                                133 => {
                                    return 0
                                },
                                8232 => {
                                    return 0
                                },
                                8233 => {
                                    return 0
                                },
                                _ => {
                                    0
                                },
                            }

                            break

                        }
                    },
                    21 => {
                        while true {
                            match chr {
                                10 => {
                                    return 0
                                },
                                11 => {
                                    return 0
                                },
                                12 => {
                                    return 0
                                },
                                13 => {
                                    return 0
                                },
                                133 => {
                                    return 0
                                },
                                8232 => {
                                    return 0
                                },
                                8233 => {
                                    return 0
                                },
                                _ => {
                                    0
                                },
                            }

                            break

                        }
                    },
                    20 => {
                        while true {
                            match chr {
                                10 => {
                                    0
                                },
                                11 => {
                                    0
                                },
                                12 => {
                                    0
                                },
                                13 => {
                                    0
                                },
                                133 => {
                                    0
                                },
                                8232 => {
                                    0
                                },
                                8233 => {
                                    0
                                },
                                _ => {
                                    return 0
                                },
                            }

                            break

                        }
                    },
                    25 => {
                        match chr {
                            13 => {
                                return 0
                            },
                            10 => {
                                return 0
                            },
                            11 => {
                                return 0
                            },
                            12 => {
                                return 0
                            },
                            133 => {
                                return 0
                            },
                            8232 => {
                                return 0
                            },
                            8233 => {
                                return 0
                            },
                        }
                    },
                    23 => {
                        match chr {
                            13 => {
                                return 0
                            },
                            10 => {
                                return 0
                            },
                            11 => {
                                return 0
                            },
                            12 => {
                                return 0
                            },
                            133 => {
                                return 0
                            },
                            8232 => {
                                return 0
                            },
                            8233 => {
                                return 0
                            },
                        }
                    },
                    24 => {
                        0
                    },
                    16 => {
                        if ((if not (check_char_prop(chr, (unsafe: list_ptr[2]), (unsafe: list_ptr[3]), (if (unsafe: list_ptr[0]) == 15: 1 else: 0)) != 0): 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    15 => {
                        if ((if not (check_char_prop(chr, (unsafe: list_ptr[2]), (unsafe: list_ptr[3]), (if (unsafe: list_ptr[0]) == 15: 1 else: 0)) != 0): 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    111 => {
                        if ((if chr > 255: 1 else: 0) != 0) {
                            return 0
                        }

                        if ((if chr > 255: 1 else: 0) != 0) {
                            break
                        }

                        var __ci_expr_ternary_54: *const u8 = null

                        if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_54 = code)
                        } else {
                            (__ci_expr_ternary_54 = base_end)
                        }

                        (class_bitset = __ci_expr_ternary_54 - (unsafe: list_ptr[2]))


                        if ((if ((unsafe: class_bitset[((chr as c_uint) >> (3 as c_uint))]) & ((1 as c_uint) << ((chr & 7) as c_uint))) != 0: 1 else: 0) != 0) {
                            return 0
                        }


                    },
                    110 => {
                        if ((if chr > 255: 1 else: 0) != 0) {
                            break
                        }

                        var __ci_expr_ternary_54: *const u8 = null

                        if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_54 = code)
                        } else {
                            (__ci_expr_ternary_54 = base_end)
                        }

                        (class_bitset = __ci_expr_ternary_54 - (unsafe: list_ptr[2]))


                        if ((if ((unsafe: class_bitset[((chr as c_uint) >> (3 as c_uint))]) & ((1 as c_uint) << ((chr & 7) as c_uint))) != 0: 1 else: 0) != 0) {
                            return 0
                        }

                    },
                    112 => {
                        var __ci_expr_ternary_55: *const u8 = null

                        if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_55 = code)
                        } else {
                            (__ci_expr_ternary_55 = base_end)
                        }

                        if (_pcre2_xclass_8(chr, ((__ci_expr_ternary_55 - (unsafe: list_ptr[2])) + ((2 as isize) as usize)), (cb.start_code as *const u8), utf) != 0) {
                            return 0
                        }

                    },
                    113 => {
                        var __ci_expr_ternary_56: *const u8 = null

                        if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_56 = code)
                        } else {
                            (__ci_expr_ternary_56 = base_end)
                        }

                        var __ci_expr_ternary_57: *const u8 = null

                        if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_57 = code)
                        } else {
                            (__ci_expr_ternary_57 = base_end)
                        }

                        if (_pcre2_eclass_8(chr, ((__ci_expr_ternary_56 - (unsafe: list_ptr[2])) + ((2 as isize) as usize)), (__ci_expr_ternary_57 - (unsafe: list_ptr[3])), (cb.start_code as *const u8), utf) != 0) {
                            return 0
                        }

                    },
                    _ => {
                        return 0
                    },
                }

                break

            }

            (chr_ptr = chr_ptr + 1)

            if (not ((if (unsafe: *chr_ptr) != 4294967295: 1 else: 0) != 0)) {
                break
            }

        }

        if ((if list[1] == 0: 1 else: 0) != 0) {
            return 1
        }

    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    return 0

}

let autoposstab: [17][21]u8 = [[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]]
let propposstab: [13][13]u8 = [[3, 0, 0, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0], [0, 2, 4, 0, 0, 9, 10, 10, 11, 0, 0, 0, 0], [0, 5, 2, 0, 0, 15, 16, 16, 17, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0], [3, 6, 12, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0], [1, 7, 13, 0, 0, 1, 3, 3, 1, 0, 0, 0, 0], [1, 7, 13, 0, 0, 1, 3, 3, 1, 0, 0, 0, 0], [0, 8, 14, 0, 0, 0, 1, 1, 3, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
let catposstab: [7][30]u8 = [[0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0]]
let posspropstab: [3][4]u8 = [[ucp_L, ucp_N, ucp_N, ucp_Nl], [ucp_Z, ucp_Z, ucp_C, ucp_Cc], [ucp_L, ucp_N, ucp_P, ucp_Po]]
