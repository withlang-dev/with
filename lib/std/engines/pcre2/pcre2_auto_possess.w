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
use std.engines.pcre2.pcre2_chkdint
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass
use std.collections

// contract: unproved:0:out-parameter written conditionally,unproved:1:read only
pub unsafe fn _pcre2_auto_possessify_8(__param_code: *mut u8, __param_cb: *const compile_block_8) -> i32 {
    var __local_code = __param_code
    var __local_c: u8

    var __local_end: *const u8

    var __local_repeat_opcode: *mut u8

    var __local_list: List[u32] = [0; 8]

    var __local_rec_limit: i32 = ((1000 as i32))

    var __local_utf: i32 = (((if (((*__param_cb).external_options as u32) & (524288 as u32)) != 0: 1 else: 0) as i32))

    var __local_ucp: i32 = (((if (((*__param_cb).external_options as u32) & (131072 as u32)) != 0: 1 else: 0) as i32))

    while true {
        (__local_c = (*__local_code))

        if (__local_c >= OP_TABLE_LENGTH) {
            loop {
                0
                if not (false) {
                    break
                }
            }

            return -1

        }

        var __ci_expr_logic_0: i32 = 0

        if (__local_c >= OP_STAR) {
            (__ci_expr_logic_0 = (if __local_c <= OP_TYPEPOSUPTO: 1 else: 0))
        }

        if __ci_expr_logic_0 {
            (__local_c = ((((__local_c as i32) -% ((get_repeat_base(__local_c) as i32) - OP_STAR)) as u8)))

            (__local_end = (if __local_c <= OP_MINUPTO: get_chr_property_list((__local_code as *const u8), __local_utf, __local_ucp, (*__param_cb).fcc, (&__local_list[0] as *mut u32)) else: (null as *const u8)))

            var __ci_expr_logic_3: i32

            var __ci_expr_logic_2: i32

            var __ci_expr_logic_1: i32

            if (__local_c == OP_STAR) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if __local_c == OP_PLUS: 1 else: 0))
            }

            if __ci_expr_logic_1 {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if __local_c == OP_QUERY: 1 else: 0))
            }

            if __ci_expr_logic_2 {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if __local_c == OP_UPTO: 1 else: 0))
            }

            (__local_list[1] = ((__ci_expr_logic_3 as u32)))


            var __ci_expr_logic_4: i32 = 0

            if (__local_end != null) {
                (__ci_expr_logic_4 = (if compare_opcodes(__local_end, __local_utf, __local_ucp, __param_cb, (&__local_list[0] as *mut u32), __local_end, (&raw mut __local_rec_limit as *mut i32)): 1 else: 0))
            }

            if __ci_expr_logic_4 {
                while true {
                    match __local_c {
                        33 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSSTAR - OP_STAR)) as u8)))
                        },
                        34 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSSTAR - OP_MINSTAR)) as u8)))
                        },
                        35 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSPLUS - OP_PLUS)) as u8)))
                        },
                        36 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSPLUS - OP_MINPLUS)) as u8)))
                        },
                        37 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSQUERY - OP_QUERY)) as u8)))
                        },
                        38 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSQUERY - OP_MINQUERY)) as u8)))
                        },
                        39 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSUPTO - OP_UPTO)) as u8)))
                        },
                        40 => {
                            ((*__local_code) = (((((*__local_code) as i32) +% (OP_POSUPTO - OP_MINUPTO)) as u8)))
                        },
                    }

                    break

                }

            }


            (__local_c = (*__local_code))

        } else {
            var __ci_expr_logic_8: i32

            var __ci_expr_logic_7: i32

            var __ci_expr_logic_6: i32

            if (__local_c == OP_CLASS) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if __local_c == OP_NCLASS: 1 else: 0))
            }

            if __ci_expr_logic_6 {
                (__ci_expr_logic_7 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_7 = (if __local_c == OP_XCLASS: 1 else: 0))
            }

            if __ci_expr_logic_7 {
                (__ci_expr_logic_8 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_8 = (if __local_c == OP_ECLASS: 1 else: 0))
            }

            if __ci_expr_logic_8 {
                var __ci_expr_logic_9: i32

                if (__local_c == OP_XCLASS) {
                    (__ci_expr_logic_9 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_9 = (if __local_c == OP_ECLASS: 1 else: 0))
                }

                if __ci_expr_logic_9 {
                    (__local_repeat_opcode = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                } else {
                    (__local_repeat_opcode = (__local_code + ((1 as isize) as usize)) + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
                }


                (__local_c = (*__local_repeat_opcode))

                var __ci_expr_logic_10: i32 = 0

                if (__local_c >= OP_CRSTAR) {
                    (__ci_expr_logic_10 = (if __local_c <= OP_CRMINRANGE: 1 else: 0))
                }

                if __ci_expr_logic_10 {
                    (__local_end = get_chr_property_list((__local_code as *const u8), __local_utf, __local_ucp, (*__param_cb).fcc, (&__local_list[0] as *mut u32)))

                    (__local_list[1] = (((if ((__local_c as i32) & (1 as i32)) == 0: 1 else: 0) as u32)))

                    var __ci_expr_logic_11: i32 = 0

                    if (__local_end != null) {
                        (__ci_expr_logic_11 = (if compare_opcodes(__local_end, __local_utf, __local_ucp, __param_cb, (&__local_list[0] as *mut u32), __local_end, (&raw mut __local_rec_limit as *mut i32)): 1 else: 0))
                    }

                    if __ci_expr_logic_11 {
                        while true {
                            match __local_c {
                                98 => {
                                    ((*__local_repeat_opcode) = ((106 as u8)))
                                },
                                99 => {
                                    ((*__local_repeat_opcode) = ((106 as u8)))
                                },
                                100 => {
                                    ((*__local_repeat_opcode) = ((107 as u8)))
                                },
                                101 => {
                                    ((*__local_repeat_opcode) = ((107 as u8)))
                                },
                                102 => {
                                    ((*__local_repeat_opcode) = ((108 as u8)))
                                },
                                103 => {
                                    ((*__local_repeat_opcode) = ((108 as u8)))
                                },
                                104 => {
                                    ((*__local_repeat_opcode) = ((109 as u8)))
                                },
                                105 => {
                                    ((*__local_repeat_opcode) = ((109 as u8)))
                                },
                            }

                            break

                        }

                    }


                }


                (__local_c = (*__local_code))

            }

        }


        while true {
            match __local_c {
                0 => {
                    return 0
                },
                85 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                86 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                87 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                88 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                89 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                90 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                94 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                95 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                96 => {
                    var __ci_expr_logic_13: i32

                    if ((__local_code[1]) == OP_PROP) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_13 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                91 => {
                    var __ci_expr_logic_14: i32

                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_14 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                92 => {
                    var __ci_expr_logic_14: i32

                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_14 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                93 => {
                    var __ci_expr_logic_14: i32

                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_14 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                97 => {
                    var __ci_expr_logic_14: i32

                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                        (__ci_expr_logic_14 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_14 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                    }

                    if __ci_expr_logic_14 {
                        (__local_code = __local_code + ((2 as isize) as usize))
                    }

                },
                120 => {
                    (__local_code = __local_code + (((((((__local_code[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))
                },
                112 => {
                    (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                },
                113 => {
                    (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                },
                156 => {
                    (__local_code = __local_code + ((((__local_code[1]) as u32) as usize) as i32))
                },
                164 => {
                    (__local_code = __local_code + ((((__local_code[1]) as u32) as usize) as i32))
                },
                158 => {
                    (__local_code = __local_code + ((((__local_code[1]) as u32) as usize) as i32))
                },
                160 => {
                    (__local_code = __local_code + ((((__local_code[1]) as u32) as usize) as i32))
                },
                162 => {
                    (__local_code = __local_code + ((((__local_code[1]) as u32) as usize) as i32))
                },
            }

            break

        }

        (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

        if __local_utf {
            while true {
                match __local_c {
                    29 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    30 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    31 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    32 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    33 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    34 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    35 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    36 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    37 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    38 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    39 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    40 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    41 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    42 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    43 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    44 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    45 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    46 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    47 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    48 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    49 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    50 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    51 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    52 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    53 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    54 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    55 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    56 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    57 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    58 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    59 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    60 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    61 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    62 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    63 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    64 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    65 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    66 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    67 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    68 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    69 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    70 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    71 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    72 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    73 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    74 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    75 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    76 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    77 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    78 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    79 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    80 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    81 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    82 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    83 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                    84 => {
                        if ((__local_code[-1]) >= 192) {
                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                        }
                    },
                }

                break

            }
        }

    }

}

fn check_char_prop(__param_c: u32, __param_ptype: u32, __param_pdata: u32, __param_negated: i32) -> i32 {
    var __local_ok: i32

    var __local_rc: i32


    var __local_p: *const u32

    var __local_prop: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__param_c as i32) / 128)] as i32) * 128) + ((__param_c as i32) % 128))] as u32) as usize))

    while true {
        match __param_ptype {
            0 => {
                var __ci_expr_logic_1: i32

                var __ci_expr_logic_0: i32

                if ((unsafe *__local_prop).chartype == ucp_Lu) {
                    (__ci_expr_logic_0 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_0 = (if (unsafe *__local_prop).chartype == ucp_Ll: 1 else: 0))
                }

                if __ci_expr_logic_0 {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (unsafe *__local_prop).chartype == ucp_Lt: 1 else: 0))
                }

                return (if __ci_expr_logic_1 == __param_negated: 1 else: 0)

            },
            1 => {
                return (if (if __param_pdata == _pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype]: 1 else: 0) == __param_negated: 1 else: 0)
            },
            2 => {
                return (if (if __param_pdata == (unsafe *__local_prop).chartype: 1 else: 0) == __param_negated: 1 else: 0)
            },
            3 => {
                return (if (if __param_pdata == (unsafe *__local_prop).script: 1 else: 0) == __param_negated: 1 else: 0)
            },
            4 => {
                var __ci_expr_logic_2: i32

                if (__param_pdata == (unsafe *__local_prop).script) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const u32) + (((((*__local_prop).scriptx_bidiclass as i32) & (1023 as i32)) as isize) as usize))[((__param_pdata as u32) / (32 as u32))]) as u32) & (((1 as u32) << (((__param_pdata as u32) % (32 as u32)) as u32)) as u32)) != 0: 1 else: 0))
                }

                (__local_ok = __ci_expr_logic_2)


                return (if __local_ok == __param_negated: 1 else: 0)

            },
            5 => {
                var __ci_expr_logic_3: i32

                if (_pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype] == 1) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if _pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype] == 3: 1 else: 0))
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
                            (__local_rc = (((if (if _pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype] == 6: 1 else: 0) == __param_negated: 1 else: 0) as i32)))
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
                            (__local_rc = (((if (if _pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype] == 6: 1 else: 0) == __param_negated: 1 else: 0) as i32)))
                        },
                    }

                    break

                }

                return __local_rc

            },
            8 => {
                var __ci_expr_logic_6: i32

                var __ci_expr_logic_5: i32

                if (_pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype] == 1) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if _pcre2_ucp_gentype_8[(unsafe *__local_prop).chartype] == 3: 1 else: 0))
                }

                if __ci_expr_logic_5 {
                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_6 = (if __param_c == 95: 1 else: 0))
                }

                return (if __ci_expr_logic_6 == __param_negated: 1 else: 0)

            },
            9 => {
                (__local_p = (&_pcre2_ucd_caseless_sets_8[0] as *const u32) + (((unsafe *__local_prop).caseset as u32) as usize))

                while true {
                    if (__param_c < (unsafe *__local_p)) {
                        return (if not __param_negated: 1 else: 0)
                    }

                    var __ci_expr_old_7: *const u32 = __local_p

                    (__local_p = __local_p + 1)

                    if (__param_c == (unsafe *__ci_expr_old_7)) {
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
    return (((if __param_c > OP_TYPEPOSUPTO: (__param_c as i32) else: ((if __param_c >= OP_TYPESTAR: OP_TYPESTAR else: ((if __param_c >= OP_NOTSTARI: OP_NOTSTARI else: ((if __param_c >= OP_NOTSTAR: OP_NOTSTAR else: ((if __param_c >= OP_STARI: OP_STARI else: OP_STAR) as i32)) as i32)) as i32)) as i32)) as u8))

}

// contract: unproved:0:read only,unproved:3:read only,unproved:4:out-parameter read before the write
unsafe fn get_chr_property_list(__param_code: *const u8, __param_utf: i32, __param_ucp: i32, __param_fcc: *const u8, __param_list: *mut u32) -> *const u8 {
    var __local_code = __param_code
    var __local_c: u8 = (*__local_code)

    var __local_base: u8

    var __local_end: *const u8

    var __local_class_end: *const u8

    var __local_chr: u32

    var __local_clist_dest: *mut u32

    var __local_clist_src: *const u32

    ((__param_list[0]) = ((__local_c as u32)))

    ((__param_list[1]) = ((0 as u32)))

    (__local_code = __local_code + 1)

    var __ci_expr_logic_0: i32 = 0

    if (__local_c >= OP_STAR) {
        (__ci_expr_logic_0 = (if __local_c <= OP_TYPEPOSUPTO: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__local_base = ((get_repeat_base(__local_c) as u8)))

        (__local_c = ((((__local_c as i32) -% ((__local_base as i32) - OP_STAR)) as u8)))

        var __ci_expr_logic_3: i32

        var __ci_expr_logic_2: i32

        var __ci_expr_logic_1: i32

        if (__local_c == OP_UPTO) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if __local_c == OP_MINUPTO: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if __local_c == OP_EXACT: 1 else: 0))
        }

        if __ci_expr_logic_2 {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if __local_c == OP_POSUPTO: 1 else: 0))
        }

        if __ci_expr_logic_3 {
            (__local_code = __local_code + ((2 as isize) as usize))
        }


        var __ci_expr_logic_6: i32 = 0

        var __ci_expr_logic_5: i32 = 0

        var __ci_expr_logic_4: i32 = 0

        if (__local_c != OP_PLUS) {
            (__ci_expr_logic_4 = (if __local_c != OP_MINPLUS: 1 else: 0))
        }

        if __ci_expr_logic_4 {
            (__ci_expr_logic_5 = (if __local_c != OP_EXACT: 1 else: 0))
        }

        if __ci_expr_logic_5 {
            (__ci_expr_logic_6 = (if __local_c != OP_POSPLUS: 1 else: 0))
        }

        ((__param_list[1]) = ((__ci_expr_logic_6 as u32)))


        while true {
            match __local_base {
                33 => {
                    ((__param_list[0]) = ((29 as u32)))
                },
                46 => {
                    ((__param_list[0]) = ((30 as u32)))
                },
                59 => {
                    ((__param_list[0]) = ((31 as u32)))
                },
                72 => {
                    ((__param_list[0]) = ((32 as u32)))
                },
                85 => {
                    ((__param_list[0]) = (((*__local_code) as u32)))

                    (__local_code = __local_code + 1)

                },
            }

            break

        }

        (__local_c = (((__param_list[0]) as u8)))

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

            (__local_chr = (((*__ci_expr_old_8) as u32)))


            var __ci_expr_logic_9: i32 = 0

            if __param_utf {
                (__ci_expr_logic_9 = (if __local_chr >= 192: 1 else: 0))
            }

            if __ci_expr_logic_9 {
                if (((__local_chr as u32) & (32 as u32)) == 0) {
                    var __ci_expr_old_10: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = ((((((((__local_chr as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_10) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                } else {
                    if (((__local_chr as u32) & (16 as u32)) == 0) {
                        (__local_chr = ((((((((((__local_chr as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if (((__local_chr as u32) & (8 as u32)) == 0) {
                            (__local_chr = ((((((((((((__local_chr as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if (((__local_chr as u32) & (4 as u32)) == 0) {
                                (__local_chr = ((((((((((((((__local_chr as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = ((((((((((((((((__local_chr as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((__param_list[2]) = __local_chr)

            ((__param_list[3]) = ((4294967295 as u32)))

            return __local_code

        },
        31 => {
            var __ci_expr_old_8: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (((*__ci_expr_old_8) as u32)))


            var __ci_expr_logic_9: i32 = 0

            if __param_utf {
                (__ci_expr_logic_9 = (if __local_chr >= 192: 1 else: 0))
            }

            if __ci_expr_logic_9 {
                if (((__local_chr as u32) & (32 as u32)) == 0) {
                    var __ci_expr_old_10: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = ((((((((__local_chr as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_10) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                } else {
                    if (((__local_chr as u32) & (16 as u32)) == 0) {
                        (__local_chr = ((((((((((__local_chr as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if (((__local_chr as u32) & (8 as u32)) == 0) {
                            (__local_chr = ((((((((((((__local_chr as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if (((__local_chr as u32) & (4 as u32)) == 0) {
                                (__local_chr = ((((((((((((((__local_chr as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = ((((((((((((((((__local_chr as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((__param_list[2]) = __local_chr)

            ((__param_list[3]) = ((4294967295 as u32)))

            return __local_code

        },
        30 => {
            ((__param_list[0]) = (((if __local_c == OP_CHARI: OP_CHAR else: OP_NOT) as u32)))

            var __ci_expr_old_11: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (((*__ci_expr_old_11) as u32)))


            var __ci_expr_logic_12: i32 = 0

            if __param_utf {
                (__ci_expr_logic_12 = (if __local_chr >= 192: 1 else: 0))
            }

            if __ci_expr_logic_12 {
                if (((__local_chr as u32) & (32 as u32)) == 0) {
                    var __ci_expr_old_13: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = ((((((((__local_chr as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_13) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                } else {
                    if (((__local_chr as u32) & (16 as u32)) == 0) {
                        (__local_chr = ((((((((((__local_chr as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if (((__local_chr as u32) & (8 as u32)) == 0) {
                            (__local_chr = ((((((((((((__local_chr as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if (((__local_chr as u32) & (4 as u32)) == 0) {
                                (__local_chr = ((((((((((((((__local_chr as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = ((((((((((((((((__local_chr as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((__param_list[2]) = __local_chr)

            var __ci_expr_logic_16: i32

            if (__local_chr < 128) {
                (__ci_expr_logic_16 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_15: i32 = 0

                var __ci_expr_logic_14: i32 = 0

                if (__local_chr < 256) {
                    (__ci_expr_logic_14 = (if not __param_utf: 1 else: 0))
                }

                if __ci_expr_logic_14 {
                    (__ci_expr_logic_15 = (if not __param_ucp: 1 else: 0))
                }

                (__ci_expr_logic_16 = (if __ci_expr_logic_15: 1 else: 0))

            }

            if __ci_expr_logic_16 {
                ((__param_list[3]) = (((__param_fcc[__local_chr]) as u32)))
            } else {
                ((__param_list[3]) = ((((__local_chr as i32) + (*((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_chr as i32) / 128)] as i32) * 128) + ((__local_chr as i32) % 128))] as u32) as usize))).other_case) as u32)))
            }


            if (__local_chr == (__param_list[3])) {
                ((__param_list[3]) = ((4294967295 as u32)))
            } else {
                ((__param_list[4]) = ((4294967295 as u32)))
            }

            return __local_code

        },
        32 => {
            ((__param_list[0]) = (((if __local_c == OP_CHARI: OP_CHAR else: OP_NOT) as u32)))

            var __ci_expr_old_11: *const u8 = __local_code

            (__local_code = __local_code + 1)

            (__local_chr = (((*__ci_expr_old_11) as u32)))


            var __ci_expr_logic_12: i32 = 0

            if __param_utf {
                (__ci_expr_logic_12 = (if __local_chr >= 192: 1 else: 0))
            }

            if __ci_expr_logic_12 {
                if (((__local_chr as u32) & (32 as u32)) == 0) {
                    var __ci_expr_old_13: *const u8 = __local_code

                    (__local_code = __local_code + 1)

                    (__local_chr = ((((((((__local_chr as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_13) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                } else {
                    if (((__local_chr as u32) & (16 as u32)) == 0) {
                        (__local_chr = ((((((((((__local_chr as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_code = __local_code + ((2 as isize) as usize))

                    } else {
                        if (((__local_chr as u32) & (8 as u32)) == 0) {
                            (__local_chr = ((((((((((((__local_chr as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_code = __local_code + ((3 as isize) as usize))

                        } else {
                            if (((__local_chr as u32) & (4 as u32)) == 0) {
                                (__local_chr = ((((((((((((((__local_chr as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((4 as isize) as usize))

                            } else {
                                (__local_chr = ((((((((((((((((__local_chr as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_code) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_code[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_code[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_code[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_code[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_code = __local_code + ((5 as isize) as usize))

                            }
                        }
                    }
                }

            }


            ((__param_list[2]) = __local_chr)

            var __ci_expr_logic_16: i32

            if (__local_chr < 128) {
                (__ci_expr_logic_16 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_15: i32 = 0

                var __ci_expr_logic_14: i32 = 0

                if (__local_chr < 256) {
                    (__ci_expr_logic_14 = (if not __param_utf: 1 else: 0))
                }

                if __ci_expr_logic_14 {
                    (__ci_expr_logic_15 = (if not __param_ucp: 1 else: 0))
                }

                (__ci_expr_logic_16 = (if __ci_expr_logic_15: 1 else: 0))

            }

            if __ci_expr_logic_16 {
                ((__param_list[3]) = (((__param_fcc[__local_chr]) as u32)))
            } else {
                ((__param_list[3]) = ((((__local_chr as i32) + (*((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_chr as i32) / 128)] as i32) * 128) + ((__local_chr as i32) % 128))] as u32) as usize))).other_case) as u32)))
            }


            if (__local_chr == (__param_list[3])) {
                ((__param_list[3]) = ((4294967295 as u32)))
            } else {
                ((__param_list[4]) = ((4294967295 as u32)))
            }

            return __local_code

        },
        16 => {
            if ((__local_code[0]) != 9) {
                ((__param_list[2]) = (((__local_code[0]) as u32)))

                ((__param_list[3]) = (((__local_code[1]) as u32)))

                return (__local_code + ((2 as isize) as usize))

            }

            (__local_clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const u32) + (((__local_code[1]) as u32) as usize))

            (__local_clist_dest = __param_list + ((2 as isize) as usize))

            (__local_code = __local_code + ((2 as isize) as usize))

            loop {
                if (__local_clist_dest >= (__param_list + ((8 as isize) as usize))) {
                    loop {
                        0
                        if not (false) {
                            break
                        }
                    }

                    ((__param_list[2]) = (((__local_code[0]) as u32)))

                    ((__param_list[3]) = (((__local_code[1]) as u32)))

                    return __local_code

                }

                var __ci_expr_old_18: *mut u32 = __local_clist_dest

                (__local_clist_dest = __local_clist_dest + 1)

                ((*__ci_expr_old_18) = (*__local_clist_src))


                var __ci_expr_old_17: *const u32 = __local_clist_src

                (__local_clist_src = __local_clist_src + 1)

                if not (((*__ci_expr_old_17) != 4294967295)) {
                    break
                }
            }

            ((__param_list[0]) = (((if __local_c == OP_PROP: OP_CHAR else: OP_NOT) as u32)))

            return __local_code

        },
        15 => {
            if ((__local_code[0]) != 9) {
                ((__param_list[2]) = (((__local_code[0]) as u32)))

                ((__param_list[3]) = (((__local_code[1]) as u32)))

                return (__local_code + ((2 as isize) as usize))

            }

            (__local_clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const u32) + (((__local_code[1]) as u32) as usize))

            (__local_clist_dest = __param_list + ((2 as isize) as usize))

            (__local_code = __local_code + ((2 as isize) as usize))

            loop {
                if (__local_clist_dest >= (__param_list + ((8 as isize) as usize))) {
                    loop {
                        0
                        if not (false) {
                            break
                        }
                    }

                    ((__param_list[2]) = (((__local_code[0]) as u32)))

                    ((__param_list[3]) = (((__local_code[1]) as u32)))

                    return __local_code

                }

                var __ci_expr_old_18: *mut u32 = __local_clist_dest

                (__local_clist_dest = __local_clist_dest + 1)

                ((*__ci_expr_old_18) = (*__local_clist_src))


                var __ci_expr_old_17: *const u32 = __local_clist_src

                (__local_clist_src = __local_clist_src + 1)

                if not (((*__ci_expr_old_17) != 4294967295)) {
                    break
                }
            }

            ((__param_list[0]) = (((if __local_c == OP_PROP: OP_CHAR else: OP_NOT) as u32)))

            return __local_code

        },
        111 => {
            var __ci_expr_logic_19: i32

            if (__local_c == OP_XCLASS) {
                (__ci_expr_logic_19 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_19 = (if __local_c == OP_ECLASS: 1 else: 0))
            }

            if __ci_expr_logic_19 {
                (__local_end = (__local_code + (((((((__local_code[0]) as i32) << (8 as u32)) as i32) | ((__local_code[(0 + 1)]) as i32)) as u32) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (*__local_end) {
                    98 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((__param_list[1]) = ((1 as u32)))

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
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((__param_list[2]) = ((((((__local_end as usize) -% (__local_code as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            ((__param_list[3]) = ((((((__local_end as usize) -% (__local_class_end as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            return __local_end

        },
        110 => {
            var __ci_expr_logic_19: i32

            if (__local_c == OP_XCLASS) {
                (__ci_expr_logic_19 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_19 = (if __local_c == OP_ECLASS: 1 else: 0))
            }

            if __ci_expr_logic_19 {
                (__local_end = (__local_code + (((((((__local_code[0]) as i32) << (8 as u32)) as i32) | ((__local_code[(0 + 1)]) as i32)) as u32) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (*__local_end) {
                    98 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((__param_list[1]) = ((1 as u32)))

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
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((__param_list[2]) = ((((((__local_end as usize) -% (__local_code as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            ((__param_list[3]) = ((((((__local_end as usize) -% (__local_class_end as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            return __local_end

        },
        112 => {
            var __ci_expr_logic_19: i32

            if (__local_c == OP_XCLASS) {
                (__ci_expr_logic_19 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_19 = (if __local_c == OP_ECLASS: 1 else: 0))
            }

            if __ci_expr_logic_19 {
                (__local_end = (__local_code + (((((((__local_code[0]) as i32) << (8 as u32)) as i32) | ((__local_code[(0 + 1)]) as i32)) as u32) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (*__local_end) {
                    98 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((__param_list[1]) = ((1 as u32)))

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
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((__param_list[2]) = ((((((__local_end as usize) -% (__local_code as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            ((__param_list[3]) = ((((((__local_end as usize) -% (__local_class_end as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            return __local_end

        },
        113 => {
            var __ci_expr_logic_19: i32

            if (__local_c == OP_XCLASS) {
                (__ci_expr_logic_19 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_19 = (if __local_c == OP_ECLASS: 1 else: 0))
            }

            if __ci_expr_logic_19 {
                (__local_end = (__local_code + (((((((__local_code[0]) as i32) << (8 as u32)) as i32) | ((__local_code[(0 + 1)]) as i32)) as u32) as usize)) - ((1 as isize) as usize))
            } else {
                (__local_end = __local_code + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
            }


            (__local_class_end = __local_end)

            while true {
                match (*__local_end) {
                    98 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    99 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    102 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    103 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    106 => {
                        ((__param_list[1]) = ((1 as u32)))

                        (__local_end = __local_end + 1)

                    },
                    108 => {
                        ((__param_list[1]) = ((1 as u32)))

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
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    105 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                    109 => {
                        ((__param_list[1]) = (((if (((((((__local_end[1]) as i32) << (8 as u32)) as i32) | ((__local_end[(1 + 1)]) as i32)) as u32)) == 0: 1 else: 0) as u32)))

                        (__local_end = __local_end + (((1 + (2 * 2)) as isize) as usize))

                    },
                }

                break

            }

            ((__param_list[2]) = ((((((__local_end as usize) -% (__local_code as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            ((__param_list[3]) = ((((((__local_end as usize) -% (__local_class_end as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

            return __local_end

        },
    }

    return ((null as *const u8))

}

// contract: unproved:0:read only,unproved:3:read only,stored-unknown:4,unproved:5:read only,unproved:6:out-parameter written conditionally — stores an argument; ownership not modeled
unsafe fn compare_opcodes(__param_code: *const u8, __param_utf: i32, __param_ucp: i32, __param_cb: *const compile_block_8, __param_base_list: *const u32, __param_base_end: *const u8, __param_rec_limit: *mut i32) -> i32 {
    var __local_code = __param_code
    var __local_c: u8

    var __local_list: List[u32] = [0; 8]

    var __local_chr_ptr: *const u32

    var __local_ochr_ptr: *const u32

    var __local_list_ptr: *const u32

    var __local_next_code: *const u8

    var __local_xclass_flags: *const u8

    var __local_class_bitset: *const u8

    var __local_set1: *const u8

    var __local_set2: *const u8

    var __local_set_end: *const u8


    var __local_chr: u32

    var __local_accepted: i32

    var __local_invert_bits: i32


    var __local_entered_a_group: i32 = ((0 as i32))

    ((*__param_rec_limit) = (*__param_rec_limit) - 1)

    if ((*__param_rec_limit) <= 0) {
        return 0
    }


    while true {
        var __local_bracode: *const u8

        (__local_c = (*__local_code))

        if (__local_c == OP_CALLOUT) {
            (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

            continue

        }

        if (__local_c == OP_CALLOUT_STR) {
            (__local_code = __local_code + (((((((__local_code[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))

            continue

        }

        if (__local_c == OP_ALT) {
            loop {
                (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                if not (((*__local_code) == OP_ALT)) {
                    break
                }
            }

            (__local_c = (*__local_code))

        }

        var __ci_expr_switch_continue_4: i32 = 0

        while true {
            match __local_c {
                0 => {
                    return (if (__param_base_list[1]) != 0: 1 else: 0)
                },
                122 => {
                    if ((__param_base_list[1]) == 0) {
                        return 0
                    }

                    (__local_bracode = __local_code - (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

                    while true {
                        match (*__local_bracode) {
                            139 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            144 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            140 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            145 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            136 => {
                                var __ci_expr_logic_0: i32 = 0

                                if ((__param_base_list[0]) != 29) {
                                    (__ci_expr_logic_0 = (if (__param_base_list[0]) != 30: 1 else: 0))
                                }

                                if __ci_expr_logic_0 {
                                    return 0
                                }

                            },
                            128 => {
                                return (if not __local_entered_a_group: 1 else: 0)
                            },
                            129 => {
                                return (if not __local_entered_a_group: 1 else: 0)
                            },
                            135 => {
                                return (if not __local_entered_a_group: 1 else: 0)
                            },
                            130 => {
                                loop {
                                    if ((__local_bracode[(1 + 2)]) == OP_VREVERSE) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + (((((((__local_bracode[1]) as i32) << (8 as u32)) as i32) | ((__local_bracode[(1 + 1)]) as i32)) as u32) as usize))

                                    if not (((*__local_bracode) == OP_ALT)) {
                                        break
                                    }
                                }

                                return (if not __local_entered_a_group: 1 else: 0)

                            },
                            131 => {
                                loop {
                                    if ((__local_bracode[(1 + 2)]) == OP_VREVERSE) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + (((((((__local_bracode[1]) as i32) << (8 as u32)) as i32) | ((__local_bracode[(1 + 1)]) as i32)) as u32) as usize))

                                    if not (((*__local_bracode) == OP_ALT)) {
                                        break
                                    }
                                }

                                return (if not __local_entered_a_group: 1 else: 0)

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

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                125 => {
                    if ((__param_base_list[1]) == 0) {
                        return 0
                    }

                    (__local_bracode = __local_code - (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

                    while true {
                        match (*__local_bracode) {
                            139 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            144 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            140 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            145 => {
                                if (*__param_cb).had_recurse {
                                    return 0
                                }
                            },
                            136 => {
                                var __ci_expr_logic_0: i32 = 0

                                if ((__param_base_list[0]) != 29) {
                                    (__ci_expr_logic_0 = (if (__param_base_list[0]) != 30: 1 else: 0))
                                }

                                if __ci_expr_logic_0 {
                                    return 0
                                }

                            },
                            128 => {
                                return (if not __local_entered_a_group: 1 else: 0)
                            },
                            129 => {
                                return (if not __local_entered_a_group: 1 else: 0)
                            },
                            135 => {
                                return (if not __local_entered_a_group: 1 else: 0)
                            },
                            130 => {
                                loop {
                                    if ((__local_bracode[(1 + 2)]) == OP_VREVERSE) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + (((((((__local_bracode[1]) as i32) << (8 as u32)) as i32) | ((__local_bracode[(1 + 1)]) as i32)) as u32) as usize))

                                    if not (((*__local_bracode) == OP_ALT)) {
                                        break
                                    }
                                }

                                return (if not __local_entered_a_group: 1 else: 0)

                            },
                            131 => {
                                loop {
                                    if ((__local_bracode[(1 + 2)]) == OP_VREVERSE) {
                                        return 0
                                    }

                                    (__local_bracode = __local_bracode + (((((((__local_bracode[1]) as i32) << (8 as u32)) as i32) | ((__local_bracode[(1 + 1)]) as i32)) as u32) as usize))

                                    if not (((*__local_bracode) == OP_ALT)) {
                                        break
                                    }
                                }

                                return (if not __local_entered_a_group: 1 else: 0)

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

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                135 => {
                    (__local_next_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    while ((*__local_next_code) == OP_ALT) {
                        if (not compare_opcodes(__local_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit)) {
                            return 0
                        }

                        (__local_code = (__local_next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (__local_next_code = __local_next_code + (((((((__local_next_code[1]) as i32) << (8 as u32)) as i32) | ((__local_next_code[(1 + 1)]) as i32)) as u32) as usize))

                    }

                    (__local_entered_a_group = ((1 as i32)))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                137 => {
                    (__local_next_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    while ((*__local_next_code) == OP_ALT) {
                        if (not compare_opcodes(__local_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit)) {
                            return 0
                        }

                        (__local_code = (__local_next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (__local_next_code = __local_next_code + (((((((__local_next_code[1]) as i32) << (8 as u32)) as i32) | ((__local_next_code[(1 + 1)]) as i32)) as u32) as usize))

                    }

                    (__local_entered_a_group = ((1 as i32)))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                139 => {
                    (__local_next_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    while ((*__local_next_code) == OP_ALT) {
                        if (not compare_opcodes(__local_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit)) {
                            return 0
                        }

                        (__local_code = (__local_next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))

                        (__local_next_code = __local_next_code + (((((((__local_next_code[1]) as i32) << (8 as u32)) as i32) | ((__local_next_code[(1 + 1)]) as i32)) as u32) as usize))

                    }

                    (__local_entered_a_group = ((1 as i32)))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                153 => {
                    (__local_next_code = __local_code + ((1 as isize) as usize))

                    var __ci_expr_logic_3: i32 = 0

                    var __ci_expr_logic_2: i32 = 0

                    if ((*__local_next_code) != OP_BRA) {
                        (__ci_expr_logic_2 = (if (*__local_next_code) != OP_CBRA: 1 else: 0))
                    }

                    if __ci_expr_logic_2 {
                        (__ci_expr_logic_3 = (if (*__local_next_code) != OP_ONCE: 1 else: 0))
                    }

                    if __ci_expr_logic_3 {
                        return 0
                    }


                    loop {
                        (__local_next_code = __local_next_code + (((((((__local_next_code[1]) as i32) << (8 as u32)) as i32) | ((__local_next_code[(1 + 1)]) as i32)) as u32) as usize))
                        if not (((*__local_next_code) == OP_ALT)) {
                            break
                        }
                    }

                    (__local_next_code = __local_next_code + (((1 + 2) as isize) as usize))

                    if (not compare_opcodes(__local_next_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit)) {
                        return 0
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    (__ci_expr_switch_continue_4 = 1)

                    break


                },
                154 => {
                    (__local_next_code = __local_code + ((1 as isize) as usize))

                    var __ci_expr_logic_3: i32 = 0

                    var __ci_expr_logic_2: i32 = 0

                    if ((*__local_next_code) != OP_BRA) {
                        (__ci_expr_logic_2 = (if (*__local_next_code) != OP_CBRA: 1 else: 0))
                    }

                    if __ci_expr_logic_2 {
                        (__ci_expr_logic_3 = (if (*__local_next_code) != OP_ONCE: 1 else: 0))
                    }

                    if __ci_expr_logic_3 {
                        return 0
                    }


                    loop {
                        (__local_next_code = __local_next_code + (((((((__local_next_code[1]) as i32) << (8 as u32)) as i32) | ((__local_next_code[(1 + 1)]) as i32)) as u32) as usize))
                        if not (((*__local_next_code) == OP_ALT)) {
                            break
                        }
                    }

                    (__local_next_code = __local_next_code + (((1 + 2) as isize) as usize))

                    if (not compare_opcodes(__local_next_code, __param_utf, __param_ucp, __param_cb, __param_base_list, __param_base_end, __param_rec_limit)) {
                        return 0
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

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


        (__local_code = get_chr_property_list(__local_code, __param_utf, __param_ucp, (*__param_cb).fcc, (&__local_list[0] as *mut u32)))

        if (__local_code == null) {
            return 0
        }

        if ((__param_base_list[0]) == 29) {
            (__local_chr_ptr = __param_base_list + ((2 as isize) as usize))

            (__local_list_ptr = (&__local_list[0] as *const u32))

        } else {
            if (__local_list[0] == 29) {
                (__local_chr_ptr = ((((&__local_list[0] as *mut u32) + ((2 as isize) as usize)) as *const u32)))

                (__local_list_ptr = __param_base_list)

            } else {
                var __ci_expr_logic_8: i32

                var __ci_expr_logic_5: i32

                if ((__param_base_list[0]) == 110) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if __local_list[0] == 110: 1 else: 0))
                }

                if __ci_expr_logic_5 {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_7: i32 = 0

                    if (not __param_utf) {
                        var __ci_expr_logic_6: i32

                        if ((__param_base_list[0]) == 111) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if __local_list[0] == 111: 1 else: 0))
                        }

                        (__ci_expr_logic_7 = (if __ci_expr_logic_6: 1 else: 0))

                    }

                    (__ci_expr_logic_8 = (if __ci_expr_logic_7: 1 else: 0))

                }

                if __ci_expr_logic_8 {
                    var __ci_expr_logic_10: i32

                    if ((__param_base_list[0]) == 110) {
                        (__ci_expr_logic_10 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_9: i32 = 0

                        if (not __param_utf) {
                            (__ci_expr_logic_9 = (if (__param_base_list[0]) == 111: 1 else: 0))
                        }

                        (__ci_expr_logic_10 = (if __ci_expr_logic_9: 1 else: 0))

                    }

                    if __ci_expr_logic_10 {
                        (__local_set1 = __param_base_end - ((__param_base_list[2]) as usize))

                        (__local_list_ptr = (&__local_list[0] as *const u32))

                    } else {
                        (__local_set1 = __local_code - (__local_list[2] as usize))

                        (__local_list_ptr = __param_base_list)

                    }


                    (__local_invert_bits = ((0 as i32)))

                    var __ci_expr_switch_continue_11: i32 = 0

                    while true {
                        match (__local_list_ptr[0]) {
                            110 => {
                                (__local_set2 = (if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize))
                            },
                            111 => {
                                (__local_set2 = (if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize))
                            },
                            112 => {
                                (__local_xclass_flags = ((if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize)) + ((2 as isize) as usize))

                                if ((((*__local_xclass_flags) as i32) & (4 as i32)) != 0) {
                                    return 0
                                }

                                if ((((*__local_xclass_flags) as i32) & (2 as i32)) == 0) {
                                    if (__local_list[1] == 0) {
                                        return (if (((*__local_xclass_flags) as i32) & (1 as i32)) == 0: 1 else: 0)
                                    }

                                    (__ci_expr_switch_continue_11 = 1)

                                    break


                                }

                                (__local_set2 = __local_xclass_flags + ((1 as isize) as usize))

                            },
                            6 => {
                                (__local_invert_bits = ((1 as i32)))

                                (__local_set2 = (*__param_cb).cbits + ((64 as isize) as usize))

                            },
                            7 => {
                                (__local_set2 = (*__param_cb).cbits + ((64 as isize) as usize))
                            },
                            8 => {
                                (__local_invert_bits = ((1 as i32)))

                                (__local_set2 = (*__param_cb).cbits + ((0 as isize) as usize))

                            },
                            9 => {
                                (__local_set2 = (*__param_cb).cbits + ((0 as isize) as usize))
                            },
                            10 => {
                                (__local_invert_bits = ((1 as i32)))

                                (__local_set2 = (*__param_cb).cbits + ((160 as isize) as usize))

                            },
                            11 => {
                                (__local_set2 = (*__param_cb).cbits + ((160 as isize) as usize))
                            },
                            _ => {
                                return 0
                            },
                        }

                        break

                    }

                    if (__ci_expr_switch_continue_11 != 0) {
                        continue
                    }


                    (__local_set_end = __local_set1 + ((32 as isize) as usize))

                    if __local_invert_bits {
                        loop {
                            var __ci_expr_old_12: *const u8 = __local_set1

                            (__local_set1 = __local_set1 + 1)

                            var __ci_expr_old_13: *const u8 = __local_set2

                            (__local_set2 = __local_set2 + 1)

                            if ((((*__ci_expr_old_12) as i32) & ((~(*__ci_expr_old_13)) as i32)) != 0) {
                                return 0
                            }


                            if not ((__local_set1 < __local_set_end)) {
                                break
                            }
                        }

                    } else {
                        loop {
                            var __ci_expr_old_14: *const u8 = __local_set1

                            (__local_set1 = __local_set1 + 1)

                            var __ci_expr_old_15: *const u8 = __local_set2

                            (__local_set2 = __local_set2 + 1)

                            if ((((*__ci_expr_old_14) as i32) & ((*__ci_expr_old_15) as i32)) != 0) {
                                return 0
                            }


                            if not ((__local_set1 < __local_set_end)) {
                                break
                            }
                        }

                    }

                    if (__local_list[1] == 0) {
                        return 1
                    }

                    continue

                }
                var __local_leftop: u32

                var __local_rightop: u32


                (__local_leftop = (((__param_base_list[0]) as u32)))

                (__local_rightop = ((__local_list[0] as u32)))

                (__local_accepted = ((0 as i32)))

                var __ci_expr_logic_16: i32

                if (__local_leftop == 16) {
                    (__ci_expr_logic_16 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_16 = (if __local_leftop == 15: 1 else: 0))
                }

                if __ci_expr_logic_16 {
                    if (__local_rightop == 24) {
                        (__local_accepted = ((1 as i32)))
                    } else {
                        var __ci_expr_logic_17: i32

                        if (__local_rightop == 16) {
                            (__ci_expr_logic_17 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_17 = (if __local_rightop == 15: 1 else: 0))
                        }

                        if __ci_expr_logic_17 {
                            var __local_n: i32

                            var __local_p: *const u8

                            var __local_same: i32 = (((if __local_leftop == __local_rightop: 1 else: 0) as i32))

                            var __local_lisprop: i32 = (((if __local_leftop == 16: 1 else: 0) as i32))

                            var __local_risprop: i32 = (((if __local_rightop == 16: 1 else: 0) as i32))

                            var __local_bothprop: i32 = with 0 as __ci_expr_seq_291 {
                                var __ci_expr_logic_18: i32 = 0
                                if __local_lisprop {
                                    (__ci_expr_logic_18 = (if __local_risprop: 1 else: 0))
                                }
                                __ci_expr_logic_18
                            }

                            (__local_n = ((propposstab[(__param_base_list[2])][__local_list[2]] as i32)))

                            while true {
                                match __local_n {
                                    0 => {
                                        0
                                    },
                                    1 => {
                                        (__local_accepted = __local_bothprop)
                                    },
                                    2 => {
                                        (__local_accepted = (((if (if (__param_base_list[3]) == __local_list[3]: 1 else: 0) != __local_same: 1 else: 0) as i32)))
                                    },
                                    3 => {
                                        (__local_accepted = (((if not __local_same: 1 else: 0) as i32)))
                                    },
                                    4 => {
                                        var __ci_expr_logic_19: i32 = 0

                                        if __local_risprop {
                                            (__ci_expr_logic_19 = (if catposstab[(__param_base_list[3])][__local_list[3]] == __local_same: 1 else: 0))
                                        }

                                        (__local_accepted = __ci_expr_logic_19)

                                    },
                                    5 => {
                                        var __ci_expr_logic_20: i32 = 0

                                        if __local_lisprop {
                                            (__ci_expr_logic_20 = (if catposstab[__local_list[3]][(__param_base_list[3])] == __local_same: 1 else: 0))
                                        }

                                        (__local_accepted = __ci_expr_logic_20)

                                    },
                                    6 => {
                                        (__local_p = (&posspropstab[(__local_n - 6)][0] as *const u8))

                                        var __ci_expr_logic_24: i32 = 0

                                        if __local_risprop {
                                            var __ci_expr_logic_23: i32 = 0

                                            var __ci_expr_logic_21: i32 = 0

                                            if (__local_list[3] != (__local_p[0])) {
                                                (__ci_expr_logic_21 = (if __local_list[3] != (__local_p[1]): 1 else: 0))
                                            }

                                            if __ci_expr_logic_21 {
                                                var __ci_expr_logic_22: i32

                                                if (__local_list[3] != (__local_p[2])) {
                                                    (__ci_expr_logic_22 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_22 = (if not __local_lisprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_23 = (if __ci_expr_logic_22: 1 else: 0))

                                            }

                                            (__ci_expr_logic_24 = (if __local_lisprop == __ci_expr_logic_23: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_24)


                                    },
                                    7 => {
                                        (__local_p = (&posspropstab[(__local_n - 6)][0] as *const u8))

                                        var __ci_expr_logic_24: i32 = 0

                                        if __local_risprop {
                                            var __ci_expr_logic_23: i32 = 0

                                            var __ci_expr_logic_21: i32 = 0

                                            if (__local_list[3] != (__local_p[0])) {
                                                (__ci_expr_logic_21 = (if __local_list[3] != (__local_p[1]): 1 else: 0))
                                            }

                                            if __ci_expr_logic_21 {
                                                var __ci_expr_logic_22: i32

                                                if (__local_list[3] != (__local_p[2])) {
                                                    (__ci_expr_logic_22 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_22 = (if not __local_lisprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_23 = (if __ci_expr_logic_22: 1 else: 0))

                                            }

                                            (__ci_expr_logic_24 = (if __local_lisprop == __ci_expr_logic_23: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_24)


                                    },
                                    8 => {
                                        (__local_p = (&posspropstab[(__local_n - 6)][0] as *const u8))

                                        var __ci_expr_logic_24: i32 = 0

                                        if __local_risprop {
                                            var __ci_expr_logic_23: i32 = 0

                                            var __ci_expr_logic_21: i32 = 0

                                            if (__local_list[3] != (__local_p[0])) {
                                                (__ci_expr_logic_21 = (if __local_list[3] != (__local_p[1]): 1 else: 0))
                                            }

                                            if __ci_expr_logic_21 {
                                                var __ci_expr_logic_22: i32

                                                if (__local_list[3] != (__local_p[2])) {
                                                    (__ci_expr_logic_22 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_22 = (if not __local_lisprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_23 = (if __ci_expr_logic_22: 1 else: 0))

                                            }

                                            (__ci_expr_logic_24 = (if __local_lisprop == __ci_expr_logic_23: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_24)


                                    },
                                    9 => {
                                        (__local_p = (&posspropstab[(__local_n - 9)][0] as *const u8))

                                        var __ci_expr_logic_28: i32 = 0

                                        if __local_lisprop {
                                            var __ci_expr_logic_27: i32 = 0

                                            var __ci_expr_logic_25: i32 = 0

                                            if ((__param_base_list[3]) != (__local_p[0])) {
                                                (__ci_expr_logic_25 = (if (__param_base_list[3]) != (__local_p[1]): 1 else: 0))
                                            }

                                            if __ci_expr_logic_25 {
                                                var __ci_expr_logic_26: i32

                                                if ((__param_base_list[3]) != (__local_p[2])) {
                                                    (__ci_expr_logic_26 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_26 = (if not __local_risprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_27 = (if __ci_expr_logic_26: 1 else: 0))

                                            }

                                            (__ci_expr_logic_28 = (if __local_risprop == __ci_expr_logic_27: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_28)


                                    },
                                    10 => {
                                        (__local_p = (&posspropstab[(__local_n - 9)][0] as *const u8))

                                        var __ci_expr_logic_28: i32 = 0

                                        if __local_lisprop {
                                            var __ci_expr_logic_27: i32 = 0

                                            var __ci_expr_logic_25: i32 = 0

                                            if ((__param_base_list[3]) != (__local_p[0])) {
                                                (__ci_expr_logic_25 = (if (__param_base_list[3]) != (__local_p[1]): 1 else: 0))
                                            }

                                            if __ci_expr_logic_25 {
                                                var __ci_expr_logic_26: i32

                                                if ((__param_base_list[3]) != (__local_p[2])) {
                                                    (__ci_expr_logic_26 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_26 = (if not __local_risprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_27 = (if __ci_expr_logic_26: 1 else: 0))

                                            }

                                            (__ci_expr_logic_28 = (if __local_risprop == __ci_expr_logic_27: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_28)


                                    },
                                    11 => {
                                        (__local_p = (&posspropstab[(__local_n - 9)][0] as *const u8))

                                        var __ci_expr_logic_28: i32 = 0

                                        if __local_lisprop {
                                            var __ci_expr_logic_27: i32 = 0

                                            var __ci_expr_logic_25: i32 = 0

                                            if ((__param_base_list[3]) != (__local_p[0])) {
                                                (__ci_expr_logic_25 = (if (__param_base_list[3]) != (__local_p[1]): 1 else: 0))
                                            }

                                            if __ci_expr_logic_25 {
                                                var __ci_expr_logic_26: i32

                                                if ((__param_base_list[3]) != (__local_p[2])) {
                                                    (__ci_expr_logic_26 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_26 = (if not __local_risprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_27 = (if __ci_expr_logic_26: 1 else: 0))

                                            }

                                            (__ci_expr_logic_28 = (if __local_risprop == __ci_expr_logic_27: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_28)


                                    },
                                    12 => {
                                        (__local_p = (&posspropstab[(__local_n - 12)][0] as *const u8))

                                        var __ci_expr_logic_32: i32 = 0

                                        if __local_risprop {
                                            var __ci_expr_logic_31: i32 = 0

                                            var __ci_expr_logic_29: i32 = 0

                                            if catposstab[(__local_p[0])][__local_list[3]] {
                                                (__ci_expr_logic_29 = (if catposstab[(__local_p[1])][__local_list[3]]: 1 else: 0))
                                            }

                                            if __ci_expr_logic_29 {
                                                var __ci_expr_logic_30: i32

                                                if (__local_list[3] != (__local_p[3])) {
                                                    (__ci_expr_logic_30 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_30 = (if not __local_lisprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_31 = (if __ci_expr_logic_30: 1 else: 0))

                                            }

                                            (__ci_expr_logic_32 = (if __local_lisprop == __ci_expr_logic_31: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_32)


                                    },
                                    13 => {
                                        (__local_p = (&posspropstab[(__local_n - 12)][0] as *const u8))

                                        var __ci_expr_logic_32: i32 = 0

                                        if __local_risprop {
                                            var __ci_expr_logic_31: i32 = 0

                                            var __ci_expr_logic_29: i32 = 0

                                            if catposstab[(__local_p[0])][__local_list[3]] {
                                                (__ci_expr_logic_29 = (if catposstab[(__local_p[1])][__local_list[3]]: 1 else: 0))
                                            }

                                            if __ci_expr_logic_29 {
                                                var __ci_expr_logic_30: i32

                                                if (__local_list[3] != (__local_p[3])) {
                                                    (__ci_expr_logic_30 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_30 = (if not __local_lisprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_31 = (if __ci_expr_logic_30: 1 else: 0))

                                            }

                                            (__ci_expr_logic_32 = (if __local_lisprop == __ci_expr_logic_31: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_32)


                                    },
                                    14 => {
                                        (__local_p = (&posspropstab[(__local_n - 12)][0] as *const u8))

                                        var __ci_expr_logic_32: i32 = 0

                                        if __local_risprop {
                                            var __ci_expr_logic_31: i32 = 0

                                            var __ci_expr_logic_29: i32 = 0

                                            if catposstab[(__local_p[0])][__local_list[3]] {
                                                (__ci_expr_logic_29 = (if catposstab[(__local_p[1])][__local_list[3]]: 1 else: 0))
                                            }

                                            if __ci_expr_logic_29 {
                                                var __ci_expr_logic_30: i32

                                                if (__local_list[3] != (__local_p[3])) {
                                                    (__ci_expr_logic_30 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_30 = (if not __local_lisprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_31 = (if __ci_expr_logic_30: 1 else: 0))

                                            }

                                            (__ci_expr_logic_32 = (if __local_lisprop == __ci_expr_logic_31: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_32)


                                    },
                                    15 => {
                                        (__local_p = (&posspropstab[(__local_n - 15)][0] as *const u8))

                                        var __ci_expr_logic_36: i32 = 0

                                        if __local_lisprop {
                                            var __ci_expr_logic_35: i32 = 0

                                            var __ci_expr_logic_33: i32 = 0

                                            if catposstab[(__local_p[0])][(__param_base_list[3])] {
                                                (__ci_expr_logic_33 = (if catposstab[(__local_p[1])][(__param_base_list[3])]: 1 else: 0))
                                            }

                                            if __ci_expr_logic_33 {
                                                var __ci_expr_logic_34: i32

                                                if ((__param_base_list[3]) != (__local_p[3])) {
                                                    (__ci_expr_logic_34 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_34 = (if not __local_risprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_35 = (if __ci_expr_logic_34: 1 else: 0))

                                            }

                                            (__ci_expr_logic_36 = (if __local_risprop == __ci_expr_logic_35: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_36)


                                    },
                                    16 => {
                                        (__local_p = (&posspropstab[(__local_n - 15)][0] as *const u8))

                                        var __ci_expr_logic_36: i32 = 0

                                        if __local_lisprop {
                                            var __ci_expr_logic_35: i32 = 0

                                            var __ci_expr_logic_33: i32 = 0

                                            if catposstab[(__local_p[0])][(__param_base_list[3])] {
                                                (__ci_expr_logic_33 = (if catposstab[(__local_p[1])][(__param_base_list[3])]: 1 else: 0))
                                            }

                                            if __ci_expr_logic_33 {
                                                var __ci_expr_logic_34: i32

                                                if ((__param_base_list[3]) != (__local_p[3])) {
                                                    (__ci_expr_logic_34 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_34 = (if not __local_risprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_35 = (if __ci_expr_logic_34: 1 else: 0))

                                            }

                                            (__ci_expr_logic_36 = (if __local_risprop == __ci_expr_logic_35: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_36)


                                    },
                                    17 => {
                                        (__local_p = (&posspropstab[(__local_n - 15)][0] as *const u8))

                                        var __ci_expr_logic_36: i32 = 0

                                        if __local_lisprop {
                                            var __ci_expr_logic_35: i32 = 0

                                            var __ci_expr_logic_33: i32 = 0

                                            if catposstab[(__local_p[0])][(__param_base_list[3])] {
                                                (__ci_expr_logic_33 = (if catposstab[(__local_p[1])][(__param_base_list[3])]: 1 else: 0))
                                            }

                                            if __ci_expr_logic_33 {
                                                var __ci_expr_logic_34: i32

                                                if ((__param_base_list[3]) != (__local_p[3])) {
                                                    (__ci_expr_logic_34 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_34 = (if not __local_risprop: 1 else: 0))
                                                }

                                                (__ci_expr_logic_35 = (if __ci_expr_logic_34: 1 else: 0))

                                            }

                                            (__ci_expr_logic_36 = (if __local_risprop == __ci_expr_logic_35: 1 else: 0))

                                        }

                                        (__local_accepted = __ci_expr_logic_36)


                                    },
                                }

                                break

                            }

                        }

                    }

                } else {
                    var __ci_expr_logic_41: i32 = 0

                    var __ci_expr_logic_40: i32 = 0

                    var __ci_expr_logic_39: i32 = 0

                    var __ci_expr_logic_38: i32 = 0

                    if (__local_leftop >= 6) {
                        (__ci_expr_logic_38 = (if __local_leftop <= 22: 1 else: 0))
                    }

                    if __ci_expr_logic_38 {
                        (__ci_expr_logic_39 = (if __local_rightop >= 6: 1 else: 0))
                    }

                    if __ci_expr_logic_39 {
                        (__ci_expr_logic_40 = (if __local_rightop <= 26: 1 else: 0))
                    }

                    if __ci_expr_logic_40 {
                        (__ci_expr_logic_41 = (if autoposstab[((__local_leftop as u32) -% (6 as u32))][((__local_rightop as u32) -% (6 as u32))]: 1 else: 0))
                    }

                    (__local_accepted = __ci_expr_logic_41)

                }


                if (not __local_accepted) {
                    return 0
                }

                if (__local_list[1] == 0) {
                    return 1
                }

                continue


            }
        }

        loop {
            (__local_chr = (*__local_chr_ptr))

            while true {
                match (__local_list_ptr[0]) {
                    29 => {
                        (__local_ochr_ptr = __local_list_ptr + ((2 as isize) as usize))

                        loop {
                            if (__local_chr == (*__local_ochr_ptr)) {
                                return 0
                            }

                            (__local_ochr_ptr = __local_ochr_ptr + 1)

                            if not (((*__local_ochr_ptr) != 4294967295)) {
                                break
                            }
                        }

                    },
                    31 => {
                        (__local_ochr_ptr = __local_list_ptr + ((2 as isize) as usize))

                        loop {
                            if (__local_chr == (*__local_ochr_ptr)) {
                                break
                            }

                            (__local_ochr_ptr = __local_ochr_ptr + 1)

                            if not (((*__local_ochr_ptr) != 4294967295)) {
                                break
                            }
                        }

                        if ((*__local_ochr_ptr) == 4294967295) {
                            return 0
                        }

                    },
                    7 => {
                        var __ci_expr_logic_42: i32 = 0

                        if (__local_chr < 256) {
                            (__ci_expr_logic_42 = (if ((((*__param_cb).ctypes[__local_chr]) as i32) & (8 as i32)) != 0: 1 else: 0))
                        }

                        if __ci_expr_logic_42 {
                            return 0
                        }

                    },
                    6 => {
                        var __ci_expr_logic_43: i32

                        if (__local_chr > 255) {
                            (__ci_expr_logic_43 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_43 = (if ((((*__param_cb).ctypes[__local_chr]) as i32) & (8 as i32)) == 0: 1 else: 0))
                        }

                        if __ci_expr_logic_43 {
                            return 0
                        }

                    },
                    9 => {
                        var __ci_expr_logic_44: i32 = 0

                        if (__local_chr < 256) {
                            (__ci_expr_logic_44 = (if ((((*__param_cb).ctypes[__local_chr]) as i32) & (1 as i32)) != 0: 1 else: 0))
                        }

                        if __ci_expr_logic_44 {
                            return 0
                        }

                    },
                    8 => {
                        var __ci_expr_logic_45: i32

                        if (__local_chr > 255) {
                            (__ci_expr_logic_45 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_45 = (if ((((*__param_cb).ctypes[__local_chr]) as i32) & (1 as i32)) == 0: 1 else: 0))
                        }

                        if __ci_expr_logic_45 {
                            return 0
                        }

                    },
                    11 => {
                        var __ci_expr_logic_46: i32 = 0

                        if (__local_chr < 255) {
                            (__ci_expr_logic_46 = (if ((((*__param_cb).ctypes[__local_chr]) as i32) & (16 as i32)) != 0: 1 else: 0))
                        }

                        if __ci_expr_logic_46 {
                            return 0
                        }

                    },
                    10 => {
                        var __ci_expr_logic_47: i32

                        if (__local_chr > 255) {
                            (__ci_expr_logic_47 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_47 = (if ((((*__param_cb).ctypes[__local_chr]) as i32) & (16 as i32)) == 0: 1 else: 0))
                        }

                        if __ci_expr_logic_47 {
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
                        if (not check_char_prop(__local_chr, ((__local_list_ptr[2]) as u32), ((__local_list_ptr[3]) as u32), ((if (__local_list_ptr[0]) == 15: 1 else: 0) as i32))) {
                            return 0
                        }
                    },
                    15 => {
                        if (not check_char_prop(__local_chr, ((__local_list_ptr[2]) as u32), ((__local_list_ptr[3]) as u32), ((if (__local_list_ptr[0]) == 15: 1 else: 0) as i32))) {
                            return 0
                        }
                    },
                    111 => {
                        if (__local_chr > 255) {
                            return 0
                        }

                        if (__local_chr > 255) {
                            break
                        }

                        (__local_class_bitset = (if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize))

                        if (((((__local_class_bitset[((__local_chr as u32) >> (3 as u32))]) as i32) as u32) & (((1 as u32) << (((__local_chr as u32) & (7 as u32)) as u32)) as u32)) != 0) {
                            return 0
                        }


                    },
                    110 => {
                        if (__local_chr > 255) {
                            break
                        }

                        (__local_class_bitset = (if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize))

                        if (((((__local_class_bitset[((__local_chr as u32) >> (3 as u32))]) as i32) as u32) & (((1 as u32) << (((__local_chr as u32) & (7 as u32)) as u32)) as u32)) != 0) {
                            return 0
                        }

                    },
                    112 => {
                        if _pcre2_xclass_8(__local_chr, (((if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize)) + ((2 as isize) as usize)), ((*__param_cb).start_code as *const u8), __param_utf) {
                            return 0
                        }
                    },
                    113 => {
                        if _pcre2_eclass_8(__local_chr, (((if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[2]) as usize)) + ((2 as isize) as usize)), ((if __local_list_ptr == (&__local_list[0] as *const u32): __local_code else: __param_base_end) - ((__local_list_ptr[3]) as usize)), ((*__param_cb).start_code as *const u8), __param_utf) {
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

            if not (((*__local_chr_ptr) != 4294967295)) {
                break
            }
        }

        if (__local_list[1] == 0) {
            return 1
        }

    }

    loop {
        0
        if not (false) {
            break
        }
    }

    return 0

}

let autoposstab: List[[u8; 21]] = [[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]]
let propposstab: List[[u8; 13]] = [[3, 0, 0, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0], [0, 2, 4, 0, 0, 9, 10, 10, 11, 0, 0, 0, 0], [0, 5, 2, 0, 0, 15, 16, 16, 17, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0], [3, 6, 12, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0], [1, 7, 13, 0, 0, 1, 3, 3, 1, 0, 0, 0, 0], [1, 7, 13, 0, 0, 1, 3, 3, 1, 0, 0, 0, 0], [0, 8, 14, 0, 0, 0, 1, 1, 3, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
let catposstab: List[[u8; 30]] = [[0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0]]
let posspropstab: List[[u8; 4]] = [[1, 3, 3, 14], [6, 6, 0, 0], [1, 3, 4, 21]]
