// Migrated from PCRE2
use std.re.defs
use std.re.pcre2_xclass

fn _pcre2_auto_possessify_8(__param_code: *mut u8, __param_cb: *const compile_block_8) -> c_int {
    var __local_code = __param_code
    var __local_c: u8

    var __local_end: *const u8

    var __local_repeat_opcode: *mut u8

    var __local_list: [8]c_uint

    var __local_rec_limit: c_int = 1000

    var __local_utf: c_int = (if ((__param_cb.external_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0)

    var __local_ucp: c_int = (if ((__param_cb.external_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0)

    while true {
        (__local_c = (unsafe *__local_code))

        if ((if __local_c >= OP_TABLE_LENGTH: 1 else: 0) != 0) {
            do {
                0
            } while (0 != 0)

            return -1

        }

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_c >= OP_STAR: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_c <= OP_TYPEPOSUPTO: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_c = __local_c - ((get_repeat_base(__local_c) as c_int) - OP_STAR))

            var __ci_expr_ternary_1: *const u8 = null

            if ((if __local_c <= OP_MINUPTO: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = get_chr_property_list(__local_code, __local_utf, __local_ucp, __param_cb.fcc, (&__local_list[0] as *mut c_uint)))
            } else {
                (__ci_expr_ternary_1 = null)
            }

            (__local_end = __ci_expr_ternary_1)


            var __ci_expr_logic_4: c_int

            var __ci_expr_logic_3: c_int

            var __ci_expr_logic_2: c_int

            if ((if __local_c == OP_STAR: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if __local_c == OP_PLUS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if __local_c == OP_QUERY: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if __local_c == OP_UPTO: 1 else: 0) != 0: 1 else: 0))
            }

            (__local_list[1] = __ci_expr_logic_4)


            var __ci_expr_logic_5: c_int = 0

            if ((if __local_end != null: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if compare_opcodes(__local_end, __local_utf, __local_ucp, __param_cb, (&__local_list[0] as *mut c_uint), __local_end, (&raw mut __local_rec_limit as *mut c_int)) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                while true {
                    match __local_c {
                        33 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSSTAR - OP_STAR))
                        },
                        34 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSSTAR - OP_MINSTAR))
                        },
                        35 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSPLUS - OP_PLUS))
                        },
                        36 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSPLUS - OP_MINPLUS))
                        },
                        37 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSQUERY - OP_QUERY))
                        },
                        38 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSQUERY - OP_MINQUERY))
                        },
                        39 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSUPTO - OP_UPTO))
                        },
                        40 => {
                            ((unsafe *__local_code) = (unsafe *__local_code) + (OP_POSUPTO - OP_MINUPTO))
                        },
                    }

                    break

                }

            }


            (__local_c = (unsafe *__local_code))

        } else {
            var __ci_expr_logic_9: c_int

            var __ci_expr_logic_8: c_int

            var __ci_expr_logic_7: c_int

            if ((if __local_c == OP_CLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_7 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_7 = (if (if __local_c == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_7 != 0) {
                (__ci_expr_logic_8 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_8 = (if (if __local_c == OP_XCLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_8 != 0) {
                (__ci_expr_logic_9 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_9 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                var __ci_expr_logic_10: c_int

                if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
                    (__ci_expr_logic_10 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_10 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_10 != 0) {
                    (__local_repeat_opcode = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))
                } else {
                    (__local_repeat_opcode = (__local_code + ((1 as isize) as usize)) + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
                }


                (__local_c = (unsafe *__local_repeat_opcode))

                var __ci_expr_logic_11: c_int = 0

                if ((if __local_c >= OP_CRSTAR: 1 else: 0) != 0) {
                    (__ci_expr_logic_11 = (if (if __local_c <= OP_CRMINRANGE: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    (__local_end = get_chr_property_list(__local_code, __local_utf, __local_ucp, __param_cb.fcc, (&__local_list[0] as *mut c_uint)))

                    (__local_list[1] = (if ((__local_c as c_int) & 1) == 0: 1 else: 0))

                    var __ci_expr_logic_12: c_int = 0

                    if ((if __local_end != null: 1 else: 0) != 0) {
                        (__ci_expr_logic_12 = (if compare_opcodes(__local_end, __local_utf, __local_ucp, __param_cb, (&__local_list[0] as *mut c_uint), __local_end, (&raw mut __local_rec_limit as *mut c_int)) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_12 != 0) {
                        while true {
                            match __local_c {
                                98 => {
                                    ((unsafe *__local_repeat_opcode) = 106)
                                },
                                99 => {
                                    ((unsafe *__local_repeat_opcode) = 106)
                                },
                                100 => {
                                    ((unsafe *__local_repeat_opcode) = 107)
                                },
                                101 => {
                                    ((unsafe *__local_repeat_opcode) = 107)
                                },
                                102 => {
                                    ((unsafe *__local_repeat_opcode) = 108)
                                },
                                103 => {
                                    ((unsafe *__local_repeat_opcode) = 108)
                                },
                                104 => {
                                    ((unsafe *__local_repeat_opcode) = 109)
                                },
                                105 => {
                                    ((unsafe *__local_repeat_opcode) = 109)
                                },
                            }

                            break

                        }

                    }


                }


                (__local_c = (unsafe *__local_code))

            }

        }


        while true {
            match __local_c {
                0 => {
                    return 0
                },
                85 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                86 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                87 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                88 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                89 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                90 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                94 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                95 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                96 => {
                    var __ci_expr_logic_14: c_int

                    if ((if (unsafe __local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (if (unsafe __local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_14 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                91 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                92 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                93 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                97 => {
                    var __ci_expr_logic_15: c_int

                    if ((if (unsafe __local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if (unsafe __local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                120 => {
                    (__local_code = __local_code + ((((((unsafe __local_code[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[((1 + (2 * 2)) + 1)]) as c_int)) as c_uint) as usize))
                },
                112 => {
                    (__local_code = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))
                },
                113 => {
                    (__local_code = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))
                },
                156 => {
                    (__local_code = __local_code + (((unsafe __local_code[1]) as c_uint) as usize))
                },
                164 => {
                    (__local_code = __local_code + (((unsafe __local_code[1]) as c_uint) as usize))
                },
                158 => {
                    (__local_code = __local_code + (((unsafe __local_code[1]) as c_uint) as usize))
                },
                160 => {
                    (__local_code = __local_code + (((unsafe __local_code[1]) as c_uint) as usize))
                },
                162 => {
                    (__local_code = __local_code + (((unsafe __local_code[1]) as c_uint) as usize))
                },
            }

            break

        }

        (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

        if (__local_utf != 0) {
            while true {
                match __local_c {
                    29 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    30 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    31 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    32 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    33 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    34 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    35 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    36 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    37 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    38 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    39 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    40 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    41 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    42 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    43 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    44 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    45 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    46 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    47 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    48 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    49 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    50 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    51 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    52 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    53 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    54 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    55 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    56 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    57 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    58 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    59 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    60 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    61 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    62 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    63 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    64 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    65 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    66 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    67 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    68 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    69 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    70 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    71 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    72 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    73 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    74 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    75 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    76 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    77 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    78 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    79 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    80 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    81 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    82 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    83 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                    84 => {
                        if ((if (unsafe __local_code[-1]) >= 192: 1 else: 0) != 0) {
                            (__local_code = __local_code + ((_pcre2_utf8_table4[((((unsafe __local_code[-1]) as c_int) as c_uint) & (63 as c_uint))] as c_uint) as usize))
                        }
                    },
                }

                break

            }
        }

    }

}

fn check_char_prop(__param_c: c_uint, __param_ptype: c_uint, __param_pdata: c_uint, __param_negated: c_int) -> c_int {
    var __local_ok: c_int

    var __local_rc: c_int


    var __local_p: *const c_uint

    var __local_prop: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__param_c as c_int) / 128)] as c_int) * 128) + ((__param_c as c_int) % 128))] as c_uint) as usize))

    while true {
        match __param_ptype {
            0 => {
                var __ci_expr_logic_1: c_int

                var __ci_expr_logic_0: c_int

                if ((if __local_prop.chartype == ucp_Lu: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_0 = (if (if __local_prop.chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if __local_prop.chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_1 == __param_negated: 1 else: 0)

            },
            1 => {
                return (if (if __param_pdata == _pcre2_ucp_gentype_8[__local_prop.chartype]: 1 else: 0) == __param_negated: 1 else: 0)
            },
            2 => {
                return (if (if __param_pdata == __local_prop.chartype: 1 else: 0) == __param_negated: 1 else: 0)
            },
            3 => {
                return (if (if __param_pdata == __local_prop.script: 1 else: 0) == __param_negated: 1 else: 0)
            },
            4 => {
                var __ci_expr_logic_2: c_int

                if ((if __param_pdata == __local_prop.script: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_prop.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[((__param_pdata as c_uint) / (32 as c_uint))]) as c_uint) & (((1 as c_uint) << (((__param_pdata as c_uint) % (32 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
                }

                (__local_ok = __ci_expr_logic_2)


                return (if __local_ok == __param_negated: 1 else: 0)

            },
            5 => {
                var __ci_expr_logic_3: c_int

                if ((if _pcre2_ucp_gentype_8[__local_prop.chartype] == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_3 == __param_negated: 1 else: 0)

            },
            6 => {
                while true {
                    match __param_c {
                        9 => {
                            (__local_rc = __param_negated)
                        },
                        32 => {
                            (__local_rc = __param_negated)
                        },
                        160 => {
                            (__local_rc = __param_negated)
                        },
                        5760 => {
                            (__local_rc = __param_negated)
                        },
                        6158 => {
                            (__local_rc = __param_negated)
                        },
                        8192 => {
                            (__local_rc = __param_negated)
                        },
                        8193 => {
                            (__local_rc = __param_negated)
                        },
                        8194 => {
                            (__local_rc = __param_negated)
                        },
                        8195 => {
                            (__local_rc = __param_negated)
                        },
                        8196 => {
                            (__local_rc = __param_negated)
                        },
                        8197 => {
                            (__local_rc = __param_negated)
                        },
                        8198 => {
                            (__local_rc = __param_negated)
                        },
                        8199 => {
                            (__local_rc = __param_negated)
                        },
                        8200 => {
                            (__local_rc = __param_negated)
                        },
                        8201 => {
                            (__local_rc = __param_negated)
                        },
                        8202 => {
                            (__local_rc = __param_negated)
                        },
                        8239 => {
                            (__local_rc = __param_negated)
                        },
                        8287 => {
                            (__local_rc = __param_negated)
                        },
                        12288 => {
                            (__local_rc = __param_negated)
                        },
                        10 => {
                            (__local_rc = __param_negated)
                        },
                        11 => {
                            (__local_rc = __param_negated)
                        },
                        12 => {
                            (__local_rc = __param_negated)
                        },
                        13 => {
                            (__local_rc = __param_negated)
                        },
                        133 => {
                            (__local_rc = __param_negated)
                        },
                        8232 => {
                            (__local_rc = __param_negated)
                        },
                        8233 => {
                            (__local_rc = __param_negated)
                        },
                        _ => {
                            (__local_rc = (if (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 6: 1 else: 0) == __param_negated: 1 else: 0))
                        },
                    }

                    break

                }

                return __local_rc

            },
            7 => {
                while true {
                    match __param_c {
                        9 => {
                            (__local_rc = __param_negated)
                        },
                        32 => {
                            (__local_rc = __param_negated)
                        },
                        160 => {
                            (__local_rc = __param_negated)
                        },
                        5760 => {
                            (__local_rc = __param_negated)
                        },
                        6158 => {
                            (__local_rc = __param_negated)
                        },
                        8192 => {
                            (__local_rc = __param_negated)
                        },
                        8193 => {
                            (__local_rc = __param_negated)
                        },
                        8194 => {
                            (__local_rc = __param_negated)
                        },
                        8195 => {
                            (__local_rc = __param_negated)
                        },
                        8196 => {
                            (__local_rc = __param_negated)
                        },
                        8197 => {
                            (__local_rc = __param_negated)
                        },
                        8198 => {
                            (__local_rc = __param_negated)
                        },
                        8199 => {
                            (__local_rc = __param_negated)
                        },
                        8200 => {
                            (__local_rc = __param_negated)
                        },
                        8201 => {
                            (__local_rc = __param_negated)
                        },
                        8202 => {
                            (__local_rc = __param_negated)
                        },
                        8239 => {
                            (__local_rc = __param_negated)
                        },
                        8287 => {
                            (__local_rc = __param_negated)
                        },
                        12288 => {
                            (__local_rc = __param_negated)
                        },
                        10 => {
                            (__local_rc = __param_negated)
                        },
                        11 => {
                            (__local_rc = __param_negated)
                        },
                        12 => {
                            (__local_rc = __param_negated)
                        },
                        13 => {
                            (__local_rc = __param_negated)
                        },
                        133 => {
                            (__local_rc = __param_negated)
                        },
                        8232 => {
                            (__local_rc = __param_negated)
                        },
                        8233 => {
                            (__local_rc = __param_negated)
                        },
                        _ => {
                            (__local_rc = (if (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 6: 1 else: 0) == __param_negated: 1 else: 0))
                        },
                    }

                    break

                }

                return __local_rc

            },
            8 => {
                var __ci_expr_logic_6: c_int

                var __ci_expr_logic_5: c_int

                if ((if _pcre2_ucp_gentype_8[__local_prop.chartype] == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_6 = (if (if __param_c == 95: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_6 == __param_negated: 1 else: 0)

            },
            9 => {
                (__local_p = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + ((__local_prop.caseset as c_uint) as usize))

                while true {
                    if ((if __param_c < (unsafe *__local_p): 1 else: 0) != 0) {
                        return (if not (__param_negated != 0): 1 else: 0)
                    }

                    var __ci_expr_old_7: *const c_uint = __local_p

                    (__local_p = __local_p + 1)

                    if ((if __param_c == (unsafe *__ci_expr_old_7): 1 else: 0) != 0) {
                        return __param_negated
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

fn get_repeat_base(__param_c: u8) -> u8 {
    var __ci_expr_ternary_4: c_int = 0

    if ((if __param_c > OP_TYPEPOSUPTO: 1 else: 0) != 0) {
        (__ci_expr_ternary_4 = __param_c)
    } else {
        var __ci_expr_ternary_3: c_int = 0

        if ((if __param_c >= OP_TYPESTAR: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = OP_TYPESTAR)
        } else {
            var __ci_expr_ternary_2: c_int = 0

            if ((if __param_c >= OP_NOTSTARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = OP_NOTSTARI)
            } else {
                var __ci_expr_ternary_1: c_int = 0

                if ((if __param_c >= OP_NOTSTAR: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = OP_NOTSTAR)
                } else {
                    var __ci_expr_ternary_0: c_int = 0

                    if ((if __param_c >= OP_STARI: 1 else: 0) != 0) {
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

fn get_chr_property_list(__param_code: *const u8, __param_utf: c_int, __param_ucp: c_int, __param_fcc: *const u8, __param_list: *mut c_uint) -> *const u8 {
    var __local_code = __param_code
    var __local_c: u8 = (unsafe *__local_code)

    var __local_base: u8

    var __local_end: *const u8

    var __local_class_end: *const u8

    var __local_chr: c_uint

    var __local_clist_dest: *mut c_uint

    var __local_clist_src: *const c_uint

    ((unsafe __param_list[0]) = __local_c)

    ((unsafe __param_list[1]) = 0)

    (__local_code = __local_code + 1)

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_c >= OP_STAR: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_c <= OP_TYPEPOSUPTO: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_base = get_repeat_base(__local_c))

        (__local_c = __local_c - ((__local_base as c_int) - OP_STAR))

        var __ci_expr_logic_3: c_int

        var __ci_expr_logic_2: c_int

        var __ci_expr_logic_1: c_int

        if ((if __local_c == OP_UPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_c == OP_MINUPTO: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_c == OP_EXACT: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_c == OP_POSUPTO: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__local_code = __local_code + ((2 as isize) as usize))
        }


        var __ci_expr_logic_6: c_int = 0

        var __ci_expr_logic_5: c_int = 0

        var __ci_expr_logic_4: c_int = 0

        if ((if __local_c != OP_PLUS: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_c != OP_MINPLUS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if __local_c != OP_EXACT: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if __local_c != OP_POSPLUS: 1 else: 0) != 0: 1 else: 0))
        }

        ((unsafe __param_list[1]) = __ci_expr_logic_6)


        while true {
            match __local_base {
                33 => {
                    ((unsafe __param_list[0]) = 29)
                },
                46 => {
                    ((unsafe __param_list[0]) = 30)
                },
                59 => {
                    ((unsafe __param_list[0]) = 31)
                },
                72 => {
                    ((unsafe __param_list[0]) = 32)
                },
                85 => {
                    ((unsafe __param_list[0]) = (unsafe *__local_code))

                    (__local_code = __local_code + 1)

                },
            }

            break

        }

        (__local_c = (unsafe __param_list[0]))

    }


    match __local_c {
        6 => {
            return __local_code
        },
        7 => {
            return __local_code
        },
        8 => {
            return __local_code
        },
        9 => {
            return __local_code
        },
        10 => {
            return __local_code
        },
        11 => {
            return __local_code
        },
        12 => {
            return __local_code
        },
        13 => {
            return __local_code
        },
        17 => {
            return __local_code
        },
        18 => {
            return __local_code
        },
        19 => {
            return __local_code
        },
        20 => {
            return __local_code
        },
        21 => {
            return __local_code
        },
        22 => {
            return __local_code
        },
        23 => {
            return __local_code
        },
        24 => {
            return __local_code
        },
        25 => {
            return __local_code
        },
        26 => {
            return __local_code
        },
        29 => {
            var __ci_expr_old_8: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (unsafe *__ci_expr_old_8))


            var __ci_expr_logic_9: c_int = 0

            if (__param_utf != 0) {
                (__ci_expr_logic_9 = (if (if __local_chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                if ((if ((__local_chr as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_10: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = (((((__local_chr as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_10) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                } else {
                    if ((if ((__local_chr as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_chr = (((((((__local_chr as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if ((if ((__local_chr as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_chr = (((((((((__local_chr as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if ((if ((__local_chr as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_chr = (((((((((((__local_chr as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = (((((((((((((__local_chr as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((unsafe __param_list[2]) = __local_chr)

            ((unsafe __param_list[3]) = 4294967295)

            return __local_code

        },
        31 => {
            var __ci_expr_old_8: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (unsafe *__ci_expr_old_8))


            var __ci_expr_logic_9: c_int = 0

            if (__param_utf != 0) {
                (__ci_expr_logic_9 = (if (if __local_chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                if ((if ((__local_chr as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_10: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = (((((__local_chr as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_10) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                } else {
                    if ((if ((__local_chr as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_chr = (((((((__local_chr as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if ((if ((__local_chr as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_chr = (((((((((__local_chr as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if ((if ((__local_chr as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_chr = (((((((((((__local_chr as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = (((((((((((((__local_chr as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((unsafe __param_list[2]) = __local_chr)

            ((unsafe __param_list[3]) = 4294967295)

            return __local_code

        },
        30 => {
            var __ci_expr_ternary_11: c_int = 0

            if ((if __local_c == OP_CHARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_11 = OP_CHAR)
            } else {
                (__ci_expr_ternary_11 = OP_NOT)
            }

            ((unsafe __param_list[0]) = __ci_expr_ternary_11)


            var __ci_expr_old_12: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (unsafe *__ci_expr_old_12))


            var __ci_expr_logic_13: c_int = 0

            if (__param_utf != 0) {
                (__ci_expr_logic_13 = (if (if __local_chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_13 != 0) {
                if ((if ((__local_chr as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_14: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = (((((__local_chr as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_14) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                } else {
                    if ((if ((__local_chr as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_chr = (((((((__local_chr as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if ((if ((__local_chr as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_chr = (((((((((__local_chr as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if ((if ((__local_chr as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_chr = (((((((((((__local_chr as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = (((((((((((((__local_chr as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((unsafe __param_list[2]) = __local_chr)

            var __ci_expr_logic_17: c_int

            if ((if __local_chr < 128: 1 else: 0) != 0) {
                (__ci_expr_logic_17 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_16: c_int = 0

                var __ci_expr_logic_15: c_int = 0

                if ((if __local_chr < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_15 = (if (if not (__param_utf != 0): 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_15 != 0) {
                    (__ci_expr_logic_16 = (if (if not (__param_ucp != 0): 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_17 != 0) {
                ((unsafe __param_list[3]) = (unsafe __param_fcc[__local_chr]))
            } else {
                ((unsafe __param_list[3]) = ((((__local_chr as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_chr as c_int) / 128)] as c_int) * 128) + ((__local_chr as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
            }


            if ((if __local_chr == (unsafe __param_list[3]): 1 else: 0) != 0) {
                ((unsafe __param_list[3]) = 4294967295)
            } else {
                ((unsafe __param_list[4]) = 4294967295)
            }

            return __local_code

        },
        32 => {
            var __ci_expr_ternary_11: c_int = 0

            if ((if __local_c == OP_CHARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_11 = OP_CHAR)
            } else {
                (__ci_expr_ternary_11 = OP_NOT)
            }

            ((unsafe __param_list[0]) = __ci_expr_ternary_11)


            var __ci_expr_old_12: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (unsafe *__ci_expr_old_12))


            var __ci_expr_logic_13: c_int = 0

            if (__param_utf != 0) {
                (__ci_expr_logic_13 = (if (if __local_chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_13 != 0) {
                if ((if ((__local_chr as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_14: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = (((((__local_chr as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_14) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                } else {
                    if ((if ((__local_chr as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_chr = (((((((__local_chr as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if ((if ((__local_chr as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_chr = (((((((((__local_chr as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if ((if ((__local_chr as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_chr = (((((((((((__local_chr as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = (((((((((((((__local_chr as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_code) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_code[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_code[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((unsafe __param_list[2]) = __local_chr)

            var __ci_expr_logic_17: c_int

            if ((if __local_chr < 128: 1 else: 0) != 0) {
                (__ci_expr_logic_17 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_16: c_int = 0

                var __ci_expr_logic_15: c_int = 0

                if ((if __local_chr < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_15 = (if (if not (__param_utf != 0): 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_15 != 0) {
                    (__ci_expr_logic_16 = (if (if not (__param_ucp != 0): 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_17 != 0) {
                ((unsafe __param_list[3]) = (unsafe __param_fcc[__local_chr]))
            } else {
                ((unsafe __param_list[3]) = ((((__local_chr as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_chr as c_int) / 128)] as c_int) * 128) + ((__local_chr as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
            }


            if ((if __local_chr == (unsafe __param_list[3]): 1 else: 0) != 0) {
                ((unsafe __param_list[3]) = 4294967295)
            } else {
                ((unsafe __param_list[4]) = 4294967295)
            }

            return __local_code

        },
        16 => {
            if ((if (unsafe __local_code[0]) != 9: 1 else: 0) != 0) {
                ((unsafe __param_list[2]) = (unsafe __local_code[0]))

                ((unsafe __param_list[3]) = (unsafe __local_code[1]))

                return (__local_code + ((2 as isize) as usize))

            }

            (__local_clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe __local_code[1]) as c_uint) as usize))

            (__local_clist_dest = __param_list + ((2 as isize) as usize))

            (__local_code = __local_code + ((2 as isize) as usize))

            do {
                if ((if __local_clist_dest >= (__param_list + ((8 as isize) as usize)): 1 else: 0) != 0) {
                    do {
                        0
                    } while (0 != 0)

                    ((unsafe __param_list[2]) = (unsafe __local_code[0]))

                    ((unsafe __param_list[3]) = (unsafe __local_code[1]))

                    return __local_code

                }

                var __ci_expr_old_19: *mut c_uint = __local_clist_dest

                (__local_clist_dest = __local_clist_dest + 1)

                ((unsafe *__ci_expr_old_19) = (unsafe *__local_clist_src))


            } while { var __ci_expr_old_18: *const c_uint = __local_clist_src

            (__local_clist_src = __local_clist_src + 1); ((if (unsafe *__ci_expr_old_18) != 4294967295: 1 else: 0) != 0) }

            var __ci_expr_ternary_20: c_int = 0

            if ((if __local_c == OP_PROP: 1 else: 0) != 0) {
                (__ci_expr_ternary_20 = OP_CHAR)
            } else {
                (__ci_expr_ternary_20 = OP_NOT)
            }

            ((unsafe __param_list[0]) = __ci_expr_ternary_20)


            return __local_code

        },
        15 => {
            if ((if (unsafe __local_code[0]) != 9: 1 else: 0) != 0) {
                ((unsafe __param_list[2]) = (unsafe __local_code[0]))

                ((unsafe __param_list[3]) = (unsafe __local_code[1]))

                return (__local_code + ((2 as isize) as usize))

            }

            (__local_clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe __local_code[1]) as c_uint) as usize))

            (__local_clist_dest = __param_list + ((2 as isize) as usize))

            (__local_code = __local_code + ((2 as isize) as usize))

            do {
                if ((if __local_clist_dest >= (__param_list + ((8 as isize) as usize)): 1 else: 0) != 0) {
                    do {
                        0
                    } while (0 != 0)

                    ((unsafe __param_list[2]) = (unsafe __local_code[0]))

                    ((unsafe __param_list[3]) = (unsafe __local_code[1]))

                    return __local_code

                }

                var __ci_expr_old_19: *mut c_uint = __local_clist_dest

                (__local_clist_dest = __local_clist_dest + 1)

                ((unsafe *__ci_expr_old_19) = (unsafe *__local_clist_src))


            } while { var __ci_expr_old_18: *const c_uint = __local_clist_src

            (__local_clist_src = __local_clist_src + 1); ((if (unsafe *__ci_expr_old_18) != 4294967295: 1 else: 0) != 0) }

            var __ci_expr_ternary_20: c_int = 0

            if ((if __local_c == OP_PROP: 1 else: 0) != 0) {
                (__ci_expr_ternary_20 = OP_CHAR)
            } else {
                (__ci_expr_ternary_20 = OP_NOT)
            }

            ((unsafe __param_list[0]) = __ci_expr_ternary_20)


            return __local_code

        },
        111 => {
            var __ci_expr_logic_21: c_int

            if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (__local_end = (__local_code + ((((((unsafe __local_code[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(0 + 1)]) as c_int)) as c_uint) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (unsafe *__local_end) {
                    98 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    100 => {
                        (__local_end = __local_end + 1)
                    },
                    101 => {
                        (__local_end = __local_end + 1)
                    },
                    107 => {
                        (__local_end = __local_end + 1)
                    },
                    104 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((unsafe __param_list[2]) = (((((__local_end as usize) -% (__local_code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe __param_list[3]) = (((((__local_end as usize) -% (__local_class_end as usize)) / sizeof[u8]()) as c_uint)))

            return __local_end

        },
        110 => {
            var __ci_expr_logic_21: c_int

            if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (__local_end = (__local_code + ((((((unsafe __local_code[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(0 + 1)]) as c_int)) as c_uint) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (unsafe *__local_end) {
                    98 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    100 => {
                        (__local_end = __local_end + 1)
                    },
                    101 => {
                        (__local_end = __local_end + 1)
                    },
                    107 => {
                        (__local_end = __local_end + 1)
                    },
                    104 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((unsafe __param_list[2]) = (((((__local_end as usize) -% (__local_code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe __param_list[3]) = (((((__local_end as usize) -% (__local_class_end as usize)) / sizeof[u8]()) as c_uint)))

            return __local_end

        },
        112 => {
            var __ci_expr_logic_21: c_int

            if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (__local_end = (__local_code + ((((((unsafe __local_code[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(0 + 1)]) as c_int)) as c_uint) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (unsafe *__local_end) {
                    98 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    100 => {
                        (__local_end = __local_end + 1)
                    },
                    101 => {
                        (__local_end = __local_end + 1)
                    },
                    107 => {
                        (__local_end = __local_end + 1)
                    },
                    104 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((unsafe __param_list[2]) = (((((__local_end as usize) -% (__local_code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe __param_list[3]) = (((((__local_end as usize) -% (__local_class_end as usize)) / sizeof[u8]()) as c_uint)))

            return __local_end

        },
        113 => {
            var __ci_expr_logic_21: c_int

            if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_21 != 0) {
                (__local_end = (__local_code + ((((((unsafe __local_code[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(0 + 1)]) as c_int)) as c_uint) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (unsafe *__local_end) {
                    98 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((unsafe __param_list[1]) = 1)

                        (__local_end = __local_end + 1)

                    },
                    100 => {
                        (__local_end = __local_end + 1)
                    },
                    101 => {
                        (__local_end = __local_end + 1)
                    },
                    107 => {
                        (__local_end = __local_end + 1)
                    },
                    104 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((unsafe __param_list[1]) = (if ((((((unsafe __local_end[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end[(1 + 1)]) as c_int)) as c_uint)) == 0: 1 else: 0))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((unsafe __param_list[2]) = (((((__local_end as usize) -% (__local_code as usize)) / sizeof[u8]()) as c_uint)))

            ((unsafe __param_list[3]) = (((((__local_end as usize) -% (__local_class_end as usize)) / sizeof[u8]()) as c_uint)))

            return __local_end

        },
    }

    return null

}

fn compare_opcodes(__param_code: *const u8, __param_utf: c_int, __param_ucp: c_int, __param_cb: *const compile_block_8, __param_base_list: *const c_uint, __param_base_end: *const u8, __param_rec_limit: *mut c_int) -> c_int {
    var __local_code = __param_code
    var __local_c: u8

    var __local_list: [8]c_uint

    var __local_chr_ptr: *const c_uint

    var __local_ochr_ptr: *const c_uint

    var __local_list_ptr: *const c_uint

    var __local_next_code: *const u8

    var __local_xclass_flags: *const u8

    var __local_class_bitset: *const u8

    var __local_set1: *const u8

    var __local_set2: *const u8

    var __local_set_end: *const u8


    var __local_chr: c_uint

    var __local_accepted: c_int

    var __local_invert_bits: c_int


    var __local_entered_a_group: c_int = 0

    ((unsafe *__param_rec_limit) = (unsafe *__param_rec_limit) - 1)

    if ((if (unsafe *__param_rec_limit) <= 0: 1 else: 0) != 0) {
        return 0
    }


    while true {
        var __local_bracode: *const u8

        (__local_c = (unsafe *__local_code))

        if ((if __local_c == OP_CALLOUT: 1 else: 0) != 0) {
            (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

            continue

        }

        if ((if __local_c == OP_CALLOUT_STR: 1 else: 0) != 0) {
            (__local_code = __local_code + ((((((unsafe __local_code[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[((1 + (2 * 2)) + 1)]) as c_int)) as c_uint) as usize))

            continue

        }

        if ((if __local_c == OP_ALT: 1 else: 0) != 0) {
            do {
                (__local_code = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))
            } while ((if (unsafe *__local_code) == OP_ALT: 1 else: 0) != 0)

            (__local_c = (unsafe *__local_code))

        }

        var __ci_expr_switch_continue_4: i32 = 0

        while true {
            match __local_c {
                0 => {
                    return (if (unsafe __param_base_list[1]) != 0: 1 else: 0)
                },
                122 => {
                    if ((if (unsafe __param_base_list[1]) == 0: 1 else: 0) != 0) {
                        return 0
                    }

                    (__local_bracode = __local_code - ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    while true {
                        match (unsafe *__local_bracode) {
                            139 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            144 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            140 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            145 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            136 => {
                                var __ci_expr_logic_0: c_int = 0

                                if ((if (unsafe __param_base_list[0]) != 29: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (unsafe __param_base_list[0]) != 30: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    return 0
                                }

                            },
                            128 => {
                                return (if not (__local_entered_a_group != 0): 1 else: 0)
                            },
                            129 => {
                                return (if not (__local_entered_a_group != 0): 1 else: 0)
                            },
                            135 => {
                                return (if not (__local_entered_a_group != 0): 1 else: 0)
                            },
                            130 => {
                                do {
                                    if ((if (unsafe __local_bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + ((((((unsafe __local_bracode[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_bracode[(1 + 1)]) as c_int)) as c_uint) as usize))

                                } while ((if (unsafe *__local_bracode) == OP_ALT: 1 else: 0) != 0)

                                return (if not (__local_entered_a_group != 0): 1 else: 0)

                            },
                            131 => {
                                do {
                                    if ((if (unsafe __local_bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + ((((((unsafe __local_bracode[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_bracode[(1 + 1)]) as c_int)) as c_uint) as usize))

                                } while ((if (unsafe *__local_bracode) == OP_ALT: 1 else: 0) != 0)

                                return (if not (__local_entered_a_group != 0): 1 else: 0)

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

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                125 => {
                    if ((if (unsafe __param_base_list[1]) == 0: 1 else: 0) != 0) {
                        return 0
                    }

                    (__local_bracode = __local_code - ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    while true {
                        match (unsafe *__local_bracode) {
                            139 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            144 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            140 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            145 => {
                                if (__param_cb.had_recurse != 0) {
                                    return 0
                                }
                            },
                            136 => {
                                var __ci_expr_logic_0: c_int = 0

                                if ((if (unsafe __param_base_list[0]) != 29: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (unsafe __param_base_list[0]) != 30: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    return 0
                                }

                            },
                            128 => {
                                return (if not (__local_entered_a_group != 0): 1 else: 0)
                            },
                            129 => {
                                return (if not (__local_entered_a_group != 0): 1 else: 0)
                            },
                            135 => {
                                return (if not (__local_entered_a_group != 0): 1 else: 0)
                            },
                            130 => {
                                do {
                                    if ((if (unsafe __local_bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + ((((((unsafe __local_bracode[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_bracode[(1 + 1)]) as c_int)) as c_uint) as usize))

                                } while ((if (unsafe *__local_bracode) == OP_ALT: 1 else: 0) != 0)

                                return (if not (__local_entered_a_group != 0): 1 else: 0)

                            },
                            131 => {
                                do {
                                    if ((if (unsafe __local_bracode[(1 + 2)]) == OP_VREVERSE: 1 else: 0) != 0) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + ((((((unsafe __local_bracode[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_bracode[(1 + 1)]) as c_int)) as c_uint) as usize))

                                } while ((if (unsafe *__local_bracode) == OP_ALT: 1 else: 0) != 0)

                                return (if not (__local_entered_a_group != 0): 1 else: 0)

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

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                135 => {
                    (__local_next_code = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    while ((if (unsafe *__local_next_code) == OP_ALT: 1 else: 0) != 0) {
                        if ((if not (compare_opcodes(__local_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        (__local_code = (__local_next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (__local_next_code = __local_next_code + ((((((unsafe __local_next_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_next_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    }

                    (__local_entered_a_group = 1)

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                137 => {
                    (__local_next_code = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    while ((if (unsafe *__local_next_code) == OP_ALT: 1 else: 0) != 0) {
                        if ((if not (compare_opcodes(__local_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        (__local_code = (__local_next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (__local_next_code = __local_next_code + ((((((unsafe __local_next_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_next_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    }

                    (__local_entered_a_group = 1)

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                139 => {
                    (__local_next_code = __local_code + ((((((unsafe __local_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    while ((if (unsafe *__local_next_code) == OP_ALT: 1 else: 0) != 0) {
                        if ((if not (compare_opcodes(__local_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        (__local_code = (__local_next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (__local_next_code = __local_next_code + ((((((unsafe __local_next_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_next_code[(1 + 1)]) as c_int)) as c_uint) as usize))

                    }

                    (__local_entered_a_group = 1)

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                153 => {
                    (__local_next_code = __local_code + ((1 as isize) as usize))

                    var __ci_expr_logic_3: c_int = 0

                    var __ci_expr_logic_2: c_int = 0

                    if ((if (unsafe *__local_next_code) != OP_BRA: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if (unsafe *__local_next_code) != OP_CBRA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if (if (unsafe *__local_next_code) != OP_ONCE: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_3 != 0) {
                        return 0
                    }


                    do {
                        (__local_next_code = __local_next_code + ((((((unsafe __local_next_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_next_code[(1 + 1)]) as c_int)) as c_uint) as usize))
                    } while ((if (unsafe *__local_next_code) == OP_ALT: 1 else: 0) != 0)

                    (__local_next_code = __local_next_code + (((1 + 2) as isize) as usize))

                    if ((if not (compare_opcodes(__local_next_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit) != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                154 => {
                    (__local_next_code = __local_code + ((1 as isize) as usize))

                    var __ci_expr_logic_3: c_int = 0

                    var __ci_expr_logic_2: c_int = 0

                    if ((if (unsafe *__local_next_code) != OP_BRA: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if (unsafe *__local_next_code) != OP_CBRA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if (if (unsafe *__local_next_code) != OP_ONCE: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_3 != 0) {
                        return 0
                    }


                    do {
                        (__local_next_code = __local_next_code + ((((((unsafe __local_next_code[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_next_code[(1 + 1)]) as c_int)) as c_uint) as usize))
                    } while ((if (unsafe *__local_next_code) == OP_ALT: 1 else: 0) != 0)

                    (__local_next_code = __local_next_code + (((1 + 2) as isize) as usize))

                    if ((if not (compare_opcodes(__local_next_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit) != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    (__local_code = __local_code + ((_pcre2_OP_lengths_8[__local_c] as c_uint) as usize))

                    (__ci_expr_switch_continue_4 = 1)

                    break


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


        (__local_code = get_chr_property_list(__local_code, __param_utf, __param_ucp, __param_cb.fcc, (&__local_list[0] as *mut c_uint)))

        if ((if __local_code == null: 1 else: 0) != 0) {
            return 0
        }

        if ((if (unsafe __param_base_list[0]) == 29: 1 else: 0) != 0) {
            (__local_chr_ptr = __param_base_list + ((2 as isize) as usize))

            (__local_list_ptr = (&__local_list[0] as *const c_uint))

        } else {
            if ((if __local_list[0] == 29: 1 else: 0) != 0) {
                (__local_chr_ptr = ((((&__local_list[0] as *mut c_uint) + ((2 as isize) as usize)) as *const c_uint)))

                (__local_list_ptr = __param_base_list)

            } else {
                var __ci_expr_logic_8: c_int

                var __ci_expr_logic_5: c_int

                if ((if (unsafe __param_base_list[0]) == 110: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if (if __local_list[0] == 110: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_7: c_int = 0

                    if ((if not (__param_utf != 0): 1 else: 0) != 0) {
                        var __ci_expr_logic_6: c_int

                        if ((if (unsafe __param_base_list[0]) == 111: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_list[0] == 111: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_7 = (if __ci_expr_logic_6 != 0: 1 else: 0))

                    }

                    (__ci_expr_logic_8 = (if __ci_expr_logic_7 != 0: 1 else: 0))

                }

                if (__ci_expr_logic_8 != 0) {
                    var __ci_expr_logic_10: c_int

                    if ((if (unsafe __param_base_list[0]) == 110: 1 else: 0) != 0) {
                        (__ci_expr_logic_10 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_9: c_int = 0

                        if ((if not (__param_utf != 0): 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if (if (unsafe __param_base_list[0]) == 111: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_10 != 0) {
                        (__local_set1 = __param_base_end - ((unsafe __param_base_list[2]) as usize))

                        (__local_list_ptr = (&__local_list[0] as *const c_uint))

                    } else {
                        (__local_set1 = __local_code - (__local_list[2] as usize))

                        (__local_list_ptr = __param_base_list)

                    }


                    (__local_invert_bits = 0)

                    var __ci_expr_switch_continue_13: i32 = 0

                    while true {
                        match (unsafe __local_list_ptr[0]) {
                            110 => {
                                var __ci_expr_ternary_11: *const u8 = null

                                if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                                    (__ci_expr_ternary_11 = __local_code)
                                } else {
                                    (__ci_expr_ternary_11 = __param_base_end)
                                }

                                (__local_set2 = __ci_expr_ternary_11 - ((unsafe __local_list_ptr[2]) as usize))

                            },
                            111 => {
                                var __ci_expr_ternary_11: *const u8 = null

                                if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                                    (__ci_expr_ternary_11 = __local_code)
                                } else {
                                    (__ci_expr_ternary_11 = __param_base_end)
                                }

                                (__local_set2 = __ci_expr_ternary_11 - ((unsafe __local_list_ptr[2]) as usize))

                            },
                            112 => {
                                var __ci_expr_ternary_12: *const u8 = null

                                if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                                    (__ci_expr_ternary_12 = __local_code)
                                } else {
                                    (__ci_expr_ternary_12 = __param_base_end)
                                }

                                (__local_xclass_flags = (__ci_expr_ternary_12 - ((unsafe __local_list_ptr[2]) as usize)) + ((2 as isize) as usize))


                                if ((if (((unsafe *__local_xclass_flags) as c_int) & 4) != 0: 1 else: 0) != 0) {
                                    return 0
                                }

                                if ((if (((unsafe *__local_xclass_flags) as c_int) & 2) == 0: 1 else: 0) != 0) {
                                    if ((if __local_list[1] == 0: 1 else: 0) != 0) {
                                        return (if (((unsafe *__local_xclass_flags) as c_int) & 1) == 0: 1 else: 0)
                                    }

                                    (__ci_expr_switch_continue_13 = 1)

                                    break


                                }

                                (__local_set2 = __local_xclass_flags + ((1 as isize) as usize))

                            },
                            6 => {
                                (__local_invert_bits = 1)

                                (__local_set2 = __param_cb.cbits + ((64 as isize) as usize))

                            },
                            7 => {
                                (__local_set2 = __param_cb.cbits + ((64 as isize) as usize))
                            },
                            8 => {
                                (__local_invert_bits = 1)

                                (__local_set2 = __param_cb.cbits + ((0 as isize) as usize))

                            },
                            9 => {
                                (__local_set2 = __param_cb.cbits + ((0 as isize) as usize))
                            },
                            10 => {
                                (__local_invert_bits = 1)

                                (__local_set2 = __param_cb.cbits + ((160 as isize) as usize))

                            },
                            11 => {
                                (__local_set2 = __param_cb.cbits + ((160 as isize) as usize))
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


                    (__local_set_end = __local_set1 + ((32 as isize) as usize))

                    if (__local_invert_bits != 0) {
                        do {
                            var __ci_expr_old_14: *const u8 = __local_set1

                            (__local_set1 = __local_set1 + 1)

                            var __ci_expr_old_15: *const u8 = __local_set2

                            (__local_set2 = __local_set2 + 1)

                            if ((if (((unsafe *__ci_expr_old_14) as c_int) & ((~(unsafe *__ci_expr_old_15)) as c_int)) != 0: 1 else: 0) != 0) {
                                return 0
                            }


                        } while ((if __local_set1 < __local_set_end: 1 else: 0) != 0)

                    } else {
                        do {
                            var __ci_expr_old_16: *const u8 = __local_set1

                            (__local_set1 = __local_set1 + 1)

                            var __ci_expr_old_17: *const u8 = __local_set2

                            (__local_set2 = __local_set2 + 1)

                            if ((if (((unsafe *__ci_expr_old_16) as c_int) & ((unsafe *__ci_expr_old_17) as c_int)) != 0: 1 else: 0) != 0) {
                                return 0
                            }


                        } while ((if __local_set1 < __local_set_end: 1 else: 0) != 0)

                    }

                    if ((if __local_list[1] == 0: 1 else: 0) != 0) {
                        return 1
                    }

                    continue

                } else {
                    var __local_leftop: c_uint

                    var __local_rightop: c_uint


                    (__local_leftop = (unsafe __param_base_list[0]))

                    (__local_rightop = __local_list[0])

                    (__local_accepted = 0)

                    var __ci_expr_logic_18: c_int

                    if ((if __local_leftop == 16: 1 else: 0) != 0) {
                        (__ci_expr_logic_18 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_18 = (if (if __local_leftop == 15: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_18 != 0) {
                        if ((if __local_rightop == 24: 1 else: 0) != 0) {
                            (__local_accepted = 1)
                        } else {
                            var __ci_expr_logic_19: c_int

                            if ((if __local_rightop == 16: 1 else: 0) != 0) {
                                (__ci_expr_logic_19 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_19 = (if (if __local_rightop == 15: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_19 != 0) {
                                var __local_n: c_int

                                var __local_p: *const u8

                                var __local_same: c_int = (if __local_leftop == __local_rightop: 1 else: 0)

                                var __local_lisprop: c_int = (if __local_leftop == 16: 1 else: 0)

                                var __local_risprop: c_int = (if __local_rightop == 16: 1 else: 0)

                                var __local_bothprop: c_int = with 0 as __ci_expr_seq_299 {
                                    var __ci_expr_logic_20: c_int = 0
                                    if (__local_lisprop != 0) {
                                        (__ci_expr_logic_20 = (if __local_risprop != 0: 1 else: 0))
                                    }
                                    __ci_expr_logic_20
                                }

                                (__local_n = propposstab[(unsafe __param_base_list[2])][__local_list[2]])

                                while true {
                                    match __local_n {
                                        0 => {
                                            0
                                        },
                                        1 => {
                                            (__local_accepted = __local_bothprop)
                                        },
                                        2 => {
                                            (__local_accepted = (if (if (unsafe __param_base_list[3]) == __local_list[3]: 1 else: 0) != __local_same: 1 else: 0))
                                        },
                                        3 => {
                                            (__local_accepted = (if not (__local_same != 0): 1 else: 0))
                                        },
                                        4 => {
                                            var __ci_expr_logic_21: c_int = 0

                                            if (__local_risprop != 0) {
                                                (__ci_expr_logic_21 = (if (if catposstab[(unsafe __param_base_list[3])][__local_list[3]] == __local_same: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            (__local_accepted = __ci_expr_logic_21)

                                        },
                                        5 => {
                                            var __ci_expr_logic_22: c_int = 0

                                            if (__local_lisprop != 0) {
                                                (__ci_expr_logic_22 = (if (if catposstab[__local_list[3]][(unsafe __param_base_list[3])] == __local_same: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            (__local_accepted = __ci_expr_logic_22)

                                        },
                                        6 => {
                                            (__local_p = (&posspropstab[(__local_n - 6)][0] as *const u8))

                                            var __ci_expr_logic_26: c_int = 0

                                            if (__local_risprop != 0) {
                                                var __ci_expr_logic_25: c_int = 0

                                                var __ci_expr_logic_23: c_int = 0

                                                if ((if __local_list[3] != (unsafe __local_p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_23 = (if (if __local_list[3] != (unsafe __local_p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_23 != 0) {
                                                    var __ci_expr_logic_24: c_int

                                                    if ((if __local_list[3] != (unsafe __local_p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_24 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_24 = (if (if not (__local_lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_26 = (if (if __local_lisprop == __ci_expr_logic_25: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_26)


                                        },
                                        7 => {
                                            (__local_p = (&posspropstab[(__local_n - 6)][0] as *const u8))

                                            var __ci_expr_logic_26: c_int = 0

                                            if (__local_risprop != 0) {
                                                var __ci_expr_logic_25: c_int = 0

                                                var __ci_expr_logic_23: c_int = 0

                                                if ((if __local_list[3] != (unsafe __local_p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_23 = (if (if __local_list[3] != (unsafe __local_p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_23 != 0) {
                                                    var __ci_expr_logic_24: c_int

                                                    if ((if __local_list[3] != (unsafe __local_p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_24 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_24 = (if (if not (__local_lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_26 = (if (if __local_lisprop == __ci_expr_logic_25: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_26)


                                        },
                                        8 => {
                                            (__local_p = (&posspropstab[(__local_n - 6)][0] as *const u8))

                                            var __ci_expr_logic_26: c_int = 0

                                            if (__local_risprop != 0) {
                                                var __ci_expr_logic_25: c_int = 0

                                                var __ci_expr_logic_23: c_int = 0

                                                if ((if __local_list[3] != (unsafe __local_p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_23 = (if (if __local_list[3] != (unsafe __local_p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_23 != 0) {
                                                    var __ci_expr_logic_24: c_int

                                                    if ((if __local_list[3] != (unsafe __local_p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_24 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_24 = (if (if not (__local_lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_26 = (if (if __local_lisprop == __ci_expr_logic_25: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_26)


                                        },
                                        9 => {
                                            (__local_p = (&posspropstab[(__local_n - 9)][0] as *const u8))

                                            var __ci_expr_logic_30: c_int = 0

                                            if (__local_lisprop != 0) {
                                                var __ci_expr_logic_29: c_int = 0

                                                var __ci_expr_logic_27: c_int = 0

                                                if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_27 = (if (if (unsafe __param_base_list[3]) != (unsafe __local_p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_27 != 0) {
                                                    var __ci_expr_logic_28: c_int

                                                    if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_28 = (if (if not (__local_risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_30 = (if (if __local_risprop == __ci_expr_logic_29: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_30)


                                        },
                                        10 => {
                                            (__local_p = (&posspropstab[(__local_n - 9)][0] as *const u8))

                                            var __ci_expr_logic_30: c_int = 0

                                            if (__local_lisprop != 0) {
                                                var __ci_expr_logic_29: c_int = 0

                                                var __ci_expr_logic_27: c_int = 0

                                                if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_27 = (if (if (unsafe __param_base_list[3]) != (unsafe __local_p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_27 != 0) {
                                                    var __ci_expr_logic_28: c_int

                                                    if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_28 = (if (if not (__local_risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_30 = (if (if __local_risprop == __ci_expr_logic_29: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_30)


                                        },
                                        11 => {
                                            (__local_p = (&posspropstab[(__local_n - 9)][0] as *const u8))

                                            var __ci_expr_logic_30: c_int = 0

                                            if (__local_lisprop != 0) {
                                                var __ci_expr_logic_29: c_int = 0

                                                var __ci_expr_logic_27: c_int = 0

                                                if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[0]): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_27 = (if (if (unsafe __param_base_list[3]) != (unsafe __local_p[1]): 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_27 != 0) {
                                                    var __ci_expr_logic_28: c_int

                                                    if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[2]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_28 = (if (if not (__local_risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_30 = (if (if __local_risprop == __ci_expr_logic_29: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_30)


                                        },
                                        12 => {
                                            (__local_p = (&posspropstab[(__local_n - 12)][0] as *const u8))

                                            var __ci_expr_logic_34: c_int = 0

                                            if (__local_risprop != 0) {
                                                var __ci_expr_logic_33: c_int = 0

                                                var __ci_expr_logic_31: c_int = 0

                                                if (catposstab[(unsafe __local_p[0])][__local_list[3]] != 0) {
                                                    (__ci_expr_logic_31 = (if catposstab[(unsafe __local_p[1])][__local_list[3]] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_31 != 0) {
                                                    var __ci_expr_logic_32: c_int

                                                    if ((if __local_list[3] != (unsafe __local_p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_32 = (if (if not (__local_lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_34 = (if (if __local_lisprop == __ci_expr_logic_33: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_34)


                                        },
                                        13 => {
                                            (__local_p = (&posspropstab[(__local_n - 12)][0] as *const u8))

                                            var __ci_expr_logic_34: c_int = 0

                                            if (__local_risprop != 0) {
                                                var __ci_expr_logic_33: c_int = 0

                                                var __ci_expr_logic_31: c_int = 0

                                                if (catposstab[(unsafe __local_p[0])][__local_list[3]] != 0) {
                                                    (__ci_expr_logic_31 = (if catposstab[(unsafe __local_p[1])][__local_list[3]] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_31 != 0) {
                                                    var __ci_expr_logic_32: c_int

                                                    if ((if __local_list[3] != (unsafe __local_p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_32 = (if (if not (__local_lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_34 = (if (if __local_lisprop == __ci_expr_logic_33: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_34)


                                        },
                                        14 => {
                                            (__local_p = (&posspropstab[(__local_n - 12)][0] as *const u8))

                                            var __ci_expr_logic_34: c_int = 0

                                            if (__local_risprop != 0) {
                                                var __ci_expr_logic_33: c_int = 0

                                                var __ci_expr_logic_31: c_int = 0

                                                if (catposstab[(unsafe __local_p[0])][__local_list[3]] != 0) {
                                                    (__ci_expr_logic_31 = (if catposstab[(unsafe __local_p[1])][__local_list[3]] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_31 != 0) {
                                                    var __ci_expr_logic_32: c_int

                                                    if ((if __local_list[3] != (unsafe __local_p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_32 = (if (if not (__local_lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_34 = (if (if __local_lisprop == __ci_expr_logic_33: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_34)


                                        },
                                        15 => {
                                            (__local_p = (&posspropstab[(__local_n - 15)][0] as *const u8))

                                            var __ci_expr_logic_38: c_int = 0

                                            if (__local_lisprop != 0) {
                                                var __ci_expr_logic_37: c_int = 0

                                                var __ci_expr_logic_35: c_int = 0

                                                if (catposstab[(unsafe __local_p[0])][(unsafe __param_base_list[3])] != 0) {
                                                    (__ci_expr_logic_35 = (if catposstab[(unsafe __local_p[1])][(unsafe __param_base_list[3])] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_35 != 0) {
                                                    var __ci_expr_logic_36: c_int

                                                    if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_36 = (if (if not (__local_risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_38 = (if (if __local_risprop == __ci_expr_logic_37: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_38)


                                        },
                                        16 => {
                                            (__local_p = (&posspropstab[(__local_n - 15)][0] as *const u8))

                                            var __ci_expr_logic_38: c_int = 0

                                            if (__local_lisprop != 0) {
                                                var __ci_expr_logic_37: c_int = 0

                                                var __ci_expr_logic_35: c_int = 0

                                                if (catposstab[(unsafe __local_p[0])][(unsafe __param_base_list[3])] != 0) {
                                                    (__ci_expr_logic_35 = (if catposstab[(unsafe __local_p[1])][(unsafe __param_base_list[3])] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_35 != 0) {
                                                    var __ci_expr_logic_36: c_int

                                                    if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_36 = (if (if not (__local_risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_38 = (if (if __local_risprop == __ci_expr_logic_37: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_38)


                                        },
                                        17 => {
                                            (__local_p = (&posspropstab[(__local_n - 15)][0] as *const u8))

                                            var __ci_expr_logic_38: c_int = 0

                                            if (__local_lisprop != 0) {
                                                var __ci_expr_logic_37: c_int = 0

                                                var __ci_expr_logic_35: c_int = 0

                                                if (catposstab[(unsafe __local_p[0])][(unsafe __param_base_list[3])] != 0) {
                                                    (__ci_expr_logic_35 = (if catposstab[(unsafe __local_p[1])][(unsafe __param_base_list[3])] != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_35 != 0) {
                                                    var __ci_expr_logic_36: c_int

                                                    if ((if (unsafe __param_base_list[3]) != (unsafe __local_p[3]): 1 else: 0) != 0) {
                                                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                                                    } else {
                                                        (__ci_expr_logic_36 = (if (if not (__local_risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                                                }

                                                (__ci_expr_logic_38 = (if (if __local_risprop == __ci_expr_logic_37: 1 else: 0) != 0: 1 else: 0))

                                            }

                                            (__local_accepted = __ci_expr_logic_38)


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

                        if ((if __local_leftop >= 6: 1 else: 0) != 0) {
                            (__ci_expr_logic_40 = (if (if __local_leftop <= 22: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_40 != 0) {
                            (__ci_expr_logic_41 = (if (if __local_rightop >= 6: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_41 != 0) {
                            (__ci_expr_logic_42 = (if (if __local_rightop <= 26: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_42 != 0) {
                            (__ci_expr_logic_43 = (if autoposstab[((__local_leftop as c_uint) -% (6 as c_uint))][((__local_rightop as c_uint) -% (6 as c_uint))] != 0: 1 else: 0))
                        }

                        (__local_accepted = __ci_expr_logic_43)

                    }


                    if ((if not (__local_accepted != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    if ((if __local_list[1] == 0: 1 else: 0) != 0) {
                        return 1
                    }

                    continue

                }

            }
        }

        do {
            (__local_chr = (unsafe *__local_chr_ptr))

            while true {
                match (unsafe __local_list_ptr[0]) {
                    29 => {
                        (__local_ochr_ptr = __local_list_ptr + ((2 as isize) as usize))

                        do {
                            if ((if __local_chr == (unsafe *__local_ochr_ptr): 1 else: 0) != 0) {
                                return 0
                            }

                            (__local_ochr_ptr = __local_ochr_ptr + 1)

                        } while ((if (unsafe *__local_ochr_ptr) != 4294967295: 1 else: 0) != 0)

                    },
                    31 => {
                        (__local_ochr_ptr = __local_list_ptr + ((2 as isize) as usize))

                        do {
                            if ((if __local_chr == (unsafe *__local_ochr_ptr): 1 else: 0) != 0) {
                                break
                            }

                            (__local_ochr_ptr = __local_ochr_ptr + 1)

                        } while ((if (unsafe *__local_ochr_ptr) != 4294967295: 1 else: 0) != 0)

                        if ((if (unsafe *__local_ochr_ptr) == 4294967295: 1 else: 0) != 0) {
                            return 0
                        }

                    },
                    7 => {
                        var __ci_expr_logic_44: c_int = 0

                        if ((if __local_chr < 256: 1 else: 0) != 0) {
                            (__ci_expr_logic_44 = (if (if (((unsafe __param_cb.ctypes[__local_chr]) as c_int) & 8) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_44 != 0) {
                            return 0
                        }

                    },
                    6 => {
                        var __ci_expr_logic_45: c_int

                        if ((if __local_chr > 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_45 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_45 = (if (if (((unsafe __param_cb.ctypes[__local_chr]) as c_int) & 8) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_45 != 0) {
                            return 0
                        }

                    },
                    9 => {
                        var __ci_expr_logic_46: c_int = 0

                        if ((if __local_chr < 256: 1 else: 0) != 0) {
                            (__ci_expr_logic_46 = (if (if (((unsafe __param_cb.ctypes[__local_chr]) as c_int) & 1) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_46 != 0) {
                            return 0
                        }

                    },
                    8 => {
                        var __ci_expr_logic_47: c_int

                        if ((if __local_chr > 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_47 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_47 = (if (if (((unsafe __param_cb.ctypes[__local_chr]) as c_int) & 1) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_47 != 0) {
                            return 0
                        }

                    },
                    11 => {
                        var __ci_expr_logic_48: c_int = 0

                        if ((if __local_chr < 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_48 = (if (if (((unsafe __param_cb.ctypes[__local_chr]) as c_int) & 16) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_48 != 0) {
                            return 0
                        }

                    },
                    10 => {
                        var __ci_expr_logic_49: c_int

                        if ((if __local_chr > 255: 1 else: 0) != 0) {
                            (__ci_expr_logic_49 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_49 = (if (if (((unsafe __param_cb.ctypes[__local_chr]) as c_int) & 16) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_49 != 0) {
                            return 0
                        }

                    },
                    19 => {
                        while true {
                            match __local_chr {
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
                            match __local_chr {
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
                            match __local_chr {
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
                            match __local_chr {
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
                            match __local_chr {
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
                        match __local_chr {
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
                        match __local_chr {
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
                        if ((if not (check_char_prop(__local_chr, (unsafe __local_list_ptr[2]), (unsafe __local_list_ptr[3]), (if (unsafe __local_list_ptr[0]) == 15: 1 else: 0)) != 0): 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    15 => {
                        if ((if not (check_char_prop(__local_chr, (unsafe __local_list_ptr[2]), (unsafe __local_list_ptr[3]), (if (unsafe __local_list_ptr[0]) == 15: 1 else: 0)) != 0): 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    111 => {
                        if ((if __local_chr > 255: 1 else: 0) != 0) {
                            return 0
                        }

                        if ((if __local_chr > 255: 1 else: 0) != 0) {
                            break
                        }

                        var __ci_expr_ternary_54: *const u8 = null

                        if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_54 = __local_code)
                        } else {
                            (__ci_expr_ternary_54 = __param_base_end)
                        }

                        (__local_class_bitset = __ci_expr_ternary_54 - ((unsafe __local_list_ptr[2]) as usize))


                        if ((if ((((unsafe __local_class_bitset[((__local_chr as c_uint) >> (3 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_chr as c_uint) & (7 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                            return 0
                        }


                    },
                    110 => {
                        if ((if __local_chr > 255: 1 else: 0) != 0) {
                            break
                        }

                        var __ci_expr_ternary_54: *const u8 = null

                        if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_54 = __local_code)
                        } else {
                            (__ci_expr_ternary_54 = __param_base_end)
                        }

                        (__local_class_bitset = __ci_expr_ternary_54 - ((unsafe __local_list_ptr[2]) as usize))


                        if ((if ((((unsafe __local_class_bitset[((__local_chr as c_uint) >> (3 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_chr as c_uint) & (7 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                            return 0
                        }

                    },
                    112 => {
                        var __ci_expr_ternary_55: *const u8 = null

                        if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_55 = __local_code)
                        } else {
                            (__ci_expr_ternary_55 = __param_base_end)
                        }

                        if (_pcre2_xclass_8(__local_chr, ((__ci_expr_ternary_55 - ((unsafe __local_list_ptr[2]) as usize)) + ((2 as isize) as usize)), (__param_cb.start_code as *const u8), __param_utf) != 0) {
                            return 0
                        }

                    },
                    113 => {
                        var __ci_expr_ternary_56: *const u8 = null

                        if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_56 = __local_code)
                        } else {
                            (__ci_expr_ternary_56 = __param_base_end)
                        }

                        var __ci_expr_ternary_57: *const u8 = null

                        if ((if __local_list_ptr == (&__local_list[0] as *const c_uint): 1 else: 0) != 0) {
                            (__ci_expr_ternary_57 = __local_code)
                        } else {
                            (__ci_expr_ternary_57 = __param_base_end)
                        }

                        if (_pcre2_eclass_8(__local_chr, ((__ci_expr_ternary_56 - ((unsafe __local_list_ptr[2]) as usize)) + ((2 as isize) as usize)), (__ci_expr_ternary_57 - ((unsafe __local_list_ptr[3]) as usize)), (__param_cb.start_code as *const u8), __param_utf) != 0) {
                            return 0
                        }

                    },
                    _ => {
                        return 0
                    },
                }

                break

            }

            (__local_chr_ptr = __local_chr_ptr + 1)

        } while ((if (unsafe *__local_chr_ptr) != 4294967295: 1 else: 0) != 0)

        if ((if __local_list[1] == 0: 1 else: 0) != 0) {
            return 1
        }

    }

    do {
        0
    } while (0 != 0)

    return 0

}

let autoposstab: [17][21]u8 = [[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]]
let propposstab: [13][13]u8 = [[3, 0, 0, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0], [0, 2, 4, 0, 0, 9, 10, 10, 11, 0, 0, 0, 0], [0, 5, 2, 0, 0, 15, 16, 16, 17, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0], [3, 6, 12, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0], [1, 7, 13, 0, 0, 1, 3, 3, 1, 0, 0, 0, 0], [1, 7, 13, 0, 0, 1, 3, 3, 1, 0, 0, 0, 0], [0, 8, 14, 0, 0, 0, 1, 1, 3, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
let catposstab: [7][30]u8 = [[0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0]]
let posspropstab: [3][4]u8 = [[1, 3, 3, 14], [6, 6, 0, 0], [1, 3, 4, 21]]
