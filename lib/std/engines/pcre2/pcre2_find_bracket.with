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
use std.engines.pcre2.pcre2_auto_possess
use std.engines.pcre2.pcre2_chkdint
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass

// contract: unproved:0:read only
pub unsafe fn _pcre2_find_bracket_8(__param_code: *const u8, __param_utf: i32, __param_number: i32) -> *const u8 {
    var __local_code = __param_code
    while true {
        var __local_c: u8 = (*__local_code)

        if (__local_c == OP_END) {
            return ((null as *const u8))
        }

        var __ci_expr_logic_0: i32

        if (__local_c == OP_XCLASS) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if __local_c == OP_ECLASS: 1 else: 0))
        }

        if __ci_expr_logic_0 {
            (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
        } else {
            if (__local_c == OP_CALLOUT_STR) {
                (__local_code = __local_code + (((((((__local_code[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))
            } else {
                var __ci_expr_logic_1: i32

                if (__local_c == OP_REVERSE) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if __local_c == OP_VREVERSE: 1 else: 0))
                }

                if __ci_expr_logic_1 {
                    if (__param_number < 0) {
                        return __local_code
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                } else {
                    var __ci_expr_logic_4: i32

                    var __ci_expr_logic_3: i32

                    var __ci_expr_logic_2: i32

                    if (__local_c == OP_CBRA) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if __local_c == OP_SCBRA: 1 else: 0))
                    }

                    if __ci_expr_logic_2 {
                        (__ci_expr_logic_3 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_3 = (if __local_c == OP_CBRAPOS: 1 else: 0))
                    }

                    if __ci_expr_logic_3 {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if __local_c == OP_SCBRAPOS: 1 else: 0))
                    }

                    if __ci_expr_logic_4 {
                        var __local_n: i32 = ((((((((__local_code[(1 + 2)]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + 2) + 1)]) as i32)) as u32) as i32))

                        if (__local_n == __param_number) {
                            return __local_code
                        }

                        (__local_code = __local_code + (((_pcre2_OP_lengths_8[__local_c] as u32) as usize) as i32))

                    } else {
                        while true {
                            match __local_c {
                                85 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                86 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                87 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                88 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                89 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                90 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                94 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                95 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                96 => {
                                    var __ci_expr_logic_5: i32

                                    if ((__local_code[1]) == OP_PROP) {
                                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_5 = (if (__local_code[1]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_5 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                91 => {
                                    var __ci_expr_logic_6: i32

                                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_6 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                92 => {
                                    var __ci_expr_logic_6: i32

                                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_6 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                93 => {
                                    var __ci_expr_logic_6: i32

                                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_6 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

                                },
                                97 => {
                                    var __ci_expr_logic_6: i32

                                    if ((__local_code[(1 + 2)]) == OP_PROP) {
                                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_6 = (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0))
                                    }

                                    if __ci_expr_logic_6 {
                                        (__local_code = __local_code + ((2 as isize) as usize))
                                    }

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

                        if __param_utf {
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
                                    41 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    54 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    67 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    80 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    39 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    52 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    65 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    78 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    40 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    53 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    66 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    79 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    45 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    58 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    71 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    84 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    33 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    46 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    59 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    72 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    34 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    47 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    60 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    73 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    42 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    55 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    68 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    81 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    35 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    48 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    61 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    74 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    36 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    49 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    62 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    75 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    43 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    56 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    69 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    82 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    37 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    50 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    63 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    76 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    38 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    51 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    64 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    77 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    44 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    57 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    70 => {
                                        if ((__local_code[-1]) >= 192) {
                                            (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                        }
                                    },
                                    83 => {
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

            }
        }


    }

}
