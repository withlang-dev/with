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
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf

pub unsafe fn _pcre2_xclass_8(__param_c: u32, __param_data: *const u8, __param_char_lists_end: *const u8, __param_utf: i32) -> i32 {
    var __local_c = __param_c
    var __local_data = __param_data
    var __local_utf = __param_utf
    var __local_t: u8

    var __local_not_negated: i32 = (((if (((*__local_data) as i32) & (1 as i32)) == 0: 1 else: 0) as i32))

    var __local_type_: u32

    var __local_max_index: u32

    var __local_min_index: u32

    var __local_value: u32


    var __local_next_char: *const u8

    (__local_utf = ((1 as i32)))

    var __ci_expr_old_0: *const u8 = __local_data

    (__local_data = __local_data + 1)

    if ((if (((*__ci_expr_old_0) as i32) & (2 as i32)) != 0: 1 else: 0) != 0) {
        if ((if __local_c < 256: 1 else: 0) != 0) {
            return (if ((((__local_data[((__local_c as u32) / (8 as u32))]) as i32) as u32) & (((1 as u32) << (((__local_c as u32) & (7 as u32)) as u32)) as u32)) != 0: 1 else: 0)
        }

        (__local_data = __local_data + (((32 as u64) / (sizeof[u8]() as u64)) as usize))

    }


    var __ci_expr_logic_1: i32

    if ((if (*__local_data) == 3: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__local_data) == 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        var __local_prop: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as i32) / 128)] as i32) * 128) + ((__local_c as i32) % 128))] as u32) as usize))

        loop {
            var __local_chartype: i32

            var __local_isprop: i32 = with 0 as __ci_expr_seq_304 {
                var __ci_expr_old_3: *const u8 = __local_data
                (__local_data = __local_data + 1)
                ((if (*__ci_expr_old_3) == 3: 1 else: 0) as i32)
            }

            var __local_ok: i32

            while true {
                match (*__local_data) {
                    0 => {
                        (__local_chartype = (((*__local_prop).chartype as i32)))

                        var __ci_expr_logic_5: i32

                        var __ci_expr_logic_4: i32

                        if ((if __local_chartype == ucp_Lu: 1 else: 0) != 0) {
                            (__ci_expr_logic_4 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_4 = (if (if __local_chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_4 != 0) {
                            (__ci_expr_logic_5 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_5 = (if (if __local_chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
                        }

                        if ((if __ci_expr_logic_5 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }


                    },
                    1 => {
                        if ((if (if (__local_data[1]) == _pcre2_ucp_gentype_8[(*__local_prop).chartype]: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    2 => {
                        if ((if (if (__local_data[1]) == (*__local_prop).chartype: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    3 => {
                        if ((if (if (__local_data[1]) == (*__local_prop).script: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    4 => {
                        var __ci_expr_logic_6: i32

                        if ((if (__local_data[1]) == (*__local_prop).script: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if (((((&_pcre2_ucd_script_sets_8[0] as *const u32) + (((((*__local_prop).scriptx_bidiclass as i32) & (1023 as i32)) as isize) as usize))[(((__local_data[1]) as i32) / 32)]) as u32) & (((1 as u32) << ((((__local_data[1]) as i32) % 32) as u32)) as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__local_ok = __ci_expr_logic_6)


                        if ((if __local_ok == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }

                    },
                    5 => {
                        (__local_chartype = (((*__local_prop).chartype as i32)))

                        var __ci_expr_logic_7: i32

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] == 1: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if _pcre2_ucp_gentype_8[__local_chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                        }

                        if ((if __ci_expr_logic_7 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }


                    },
                    6 => {
                        while true {
                            match __local_c {
                                9 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                32 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                160 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                5760 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                6158 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8192 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8193 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8194 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8195 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8196 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8197 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8198 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8199 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8200 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8201 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8202 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8239 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8287 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                12288 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                10 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                11 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                12 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                13 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                133 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8232 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8233 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                _ => {
                                    if ((if (if _pcre2_ucp_gentype_8[(*__local_prop).chartype] == 6: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                                        return __local_not_negated
                                    }
                                },
                            }

                            break

                        }
                    },
                    7 => {
                        while true {
                            match __local_c {
                                9 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                32 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                160 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                5760 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                6158 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8192 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8193 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8194 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8195 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8196 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8197 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8198 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8199 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8200 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8201 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8202 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8239 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8287 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                12288 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                10 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                11 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                12 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                13 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                133 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8232 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                8233 => {
                                    if (__local_isprop != 0) {
                                        return __local_not_negated
                                    }
                                },
                                _ => {
                                    if ((if (if _pcre2_ucp_gentype_8[(*__local_prop).chartype] == 6: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                                        return __local_not_negated
                                    }
                                },
                            }

                            break

                        }
                    },
                    8 => {
                        (__local_chartype = (((*__local_prop).chartype as i32)))

                        var __ci_expr_logic_11: i32

                        var __ci_expr_logic_10: i32

                        var __ci_expr_logic_9: i32

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] == 1: 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_9 = (if (if _pcre2_ucp_gentype_8[__local_chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            (__ci_expr_logic_10 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_10 = (if (if __local_chartype == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_10 != 0) {
                            (__ci_expr_logic_11 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_11 = (if (if __local_chartype == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
                        }

                        if ((if __ci_expr_logic_11 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }


                    },
                    10 => {
                        if ((if __local_c < 160: 1 else: 0) != 0) {
                            var __ci_expr_logic_13: i32

                            var __ci_expr_logic_12: i32

                            if ((if __local_c == 36: 1 else: 0) != 0) {
                                (__ci_expr_logic_12 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_12 = (if (if __local_c == 64: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_12 != 0) {
                                (__ci_expr_logic_13 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_13 = (if (if __local_c == 96: 1 else: 0) != 0: 1 else: 0))
                            }

                            if ((if __ci_expr_logic_13 == __local_isprop: 1 else: 0) != 0) {
                                return __local_not_negated
                            }


                        } else {
                            var __ci_expr_logic_14: i32

                            if ((if __local_c < 55296: 1 else: 0) != 0) {
                                (__ci_expr_logic_14 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_14 = (if (if __local_c > 57343: 1 else: 0) != 0: 1 else: 0))
                            }

                            if ((if __ci_expr_logic_14 == __local_isprop: 1 else: 0) != 0) {
                                return __local_not_negated
                            }


                        }
                    },
                    11 => {
                        if ((if (if (((*__local_prop).scriptx_bidiclass as i32) >> (11 as u32)) == (__local_data[1]): 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    12 => {
                        (__local_ok = (((if (((((&_pcre2_ucd_boolprop_sets_8[0] as *const u32) + (((((*__local_prop).bprops as i32) & (4095 as i32)) as isize) as usize))[(((__local_data[1]) as i32) / 32)]) as u32) & (((1 as u32) << ((((__local_data[1]) as i32) % 32) as u32)) as u32)) != 0: 1 else: 0) as i32)))

                        if ((if __local_ok == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }

                    },
                    14 => {
                        (__local_chartype = (((*__local_prop).chartype as i32)))

                        var __ci_expr_logic_20: i32 = 0

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] != 6: 1 else: 0) != 0) {
                            var __ci_expr_logic_19: i32

                            if ((if _pcre2_ucp_gentype_8[__local_chartype] != 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_19 = (if true: 1 else: 0))
                            } else {
                                var __ci_expr_logic_18: i32 = 0

                                var __ci_expr_logic_16: i32 = 0

                                var __ci_expr_logic_15: i32 = 0

                                if ((if __local_chartype == ucp_Cf: 1 else: 0) != 0) {
                                    (__ci_expr_logic_15 = (if (if __local_c != 1564: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_15 != 0) {
                                    (__ci_expr_logic_16 = (if (if __local_c != 6158: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_16 != 0) {
                                    var __ci_expr_logic_17: i32

                                    if ((if __local_c < 8294: 1 else: 0) != 0) {
                                        (__ci_expr_logic_17 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_17 = (if (if __local_c > 8297: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    (__ci_expr_logic_18 = (if __ci_expr_logic_17 != 0: 1 else: 0))

                                }

                                (__ci_expr_logic_19 = (if __ci_expr_logic_18 != 0: 1 else: 0))

                            }

                            (__ci_expr_logic_20 = (if __ci_expr_logic_19 != 0: 1 else: 0))

                        }

                        if ((if __ci_expr_logic_20 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }


                    },
                    15 => {
                        (__local_chartype = (((*__local_prop).chartype as i32)))

                        var __ci_expr_logic_26: i32 = 0

                        var __ci_expr_logic_21: i32 = 0

                        if ((if __local_chartype != ucp_Zl: 1 else: 0) != 0) {
                            (__ci_expr_logic_21 = (if (if __local_chartype != ucp_Zp: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_21 != 0) {
                            var __ci_expr_logic_25: i32

                            if ((if _pcre2_ucp_gentype_8[__local_chartype] != 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_25 = (if true: 1 else: 0))
                            } else {
                                var __ci_expr_logic_24: i32 = 0

                                var __ci_expr_logic_22: i32 = 0

                                if ((if __local_chartype == ucp_Cf: 1 else: 0) != 0) {
                                    (__ci_expr_logic_22 = (if (if __local_c != 1564: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_22 != 0) {
                                    var __ci_expr_logic_23: i32

                                    if ((if __local_c < 8294: 1 else: 0) != 0) {
                                        (__ci_expr_logic_23 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_23 = (if (if __local_c > 8297: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    (__ci_expr_logic_24 = (if __ci_expr_logic_23 != 0: 1 else: 0))

                                }

                                (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                            }

                            (__ci_expr_logic_26 = (if __ci_expr_logic_25 != 0: 1 else: 0))

                        }

                        if ((if __ci_expr_logic_26 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }


                    },
                    16 => {
                        (__local_chartype = (((*__local_prop).chartype as i32)))

                        var __ci_expr_logic_28: i32

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] == 4: 1 else: 0) != 0) {
                            (__ci_expr_logic_28 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_27: i32 = 0

                            if ((if __local_c < 128: 1 else: 0) != 0) {
                                (__ci_expr_logic_27 = (if (if _pcre2_ucp_gentype_8[__local_chartype] == 5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_28 = (if __ci_expr_logic_27 != 0: 1 else: 0))

                        }

                        if ((if __ci_expr_logic_28 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }


                    },
                    17 => {
                        var __ci_expr_logic_39: i32

                        var __ci_expr_logic_37: i32

                        var __ci_expr_logic_35: i32

                        var __ci_expr_logic_33: i32

                        var __ci_expr_logic_31: i32

                        var __ci_expr_logic_29: i32 = 0

                        if ((if __local_c >= 48: 1 else: 0) != 0) {
                            (__ci_expr_logic_29 = (if (if __local_c <= 57: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_29 != 0) {
                            (__ci_expr_logic_31 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_30: i32 = 0

                            if ((if __local_c >= 65: 1 else: 0) != 0) {
                                (__ci_expr_logic_30 = (if (if __local_c <= 70: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_31 = (if __ci_expr_logic_30 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_31 != 0) {
                            (__ci_expr_logic_33 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_32: i32 = 0

                            if ((if __local_c >= 97: 1 else: 0) != 0) {
                                (__ci_expr_logic_32 = (if (if __local_c <= 102: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_33 != 0) {
                            (__ci_expr_logic_35 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_34: i32 = 0

                            if ((if __local_c >= 65296: 1 else: 0) != 0) {
                                (__ci_expr_logic_34 = (if (if __local_c <= 65305: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_35 = (if __ci_expr_logic_34 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_35 != 0) {
                            (__ci_expr_logic_37 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_36: i32 = 0

                            if ((if __local_c >= 65313: 1 else: 0) != 0) {
                                (__ci_expr_logic_36 = (if (if __local_c <= 65318: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_37 != 0) {
                            (__ci_expr_logic_39 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_38: i32 = 0

                            if ((if __local_c >= 65345: 1 else: 0) != 0) {
                                (__ci_expr_logic_38 = (if (if __local_c <= 65350: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_39 = (if __ci_expr_logic_38 != 0: 1 else: 0))

                        }

                        if ((if __ci_expr_logic_39 == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }

                    },
                    _ => {
                        loop {
                            0
                            if not ((0 != 0)) {
                                break
                            }
                        }

                        return 0

                    },
                }

                break

            }

            (__local_data = __local_data + ((2 as isize) as usize))

            var __ci_expr_logic_2: i32

            if ((if (*__local_data) == 3: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if (*__local_data) == 4: 1 else: 0) != 0: 1 else: 0))
            }

            if not ((__ci_expr_logic_2 != 0)) {
                break
            }
        }

    }


    if ((if (*__local_data) < (if (if (sizeof[u8]() as usize) == 1: 1 else: 0) != 0: (16 as i32) else: (4096 as i32)): 1 else: 0) != 0) {
        while true {
            var __ci_expr_old_41: *const u8 = __local_data

            (__local_data = __local_data + 1)

            (__local_t = (*__ci_expr_old_41))

            if (not ((if __local_t != 0: 1 else: 0) != 0)) {
                break
            }

            var __local_x: u32

            var __local_y: u32

            if (__local_utf != 0) {
                var __ci_expr_old_42: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_x = (((*__ci_expr_old_42) as u32)))


                if ((if __local_x >= 192: 1 else: 0) != 0) {
                    if ((if ((__local_x as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_43: *const u8 = __local_data

                        (__local_data = __local_data + 1)

                        (__local_x = ((((((((__local_x as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_43) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    } else {
                        if ((if ((__local_x as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
                            (__local_x = ((((((((((__local_x as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_data = __local_data + ((2 as isize) as usize))

                        } else {
                            if ((if ((__local_x as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
                                (__local_x = ((((((((((((__local_x as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_data = __local_data + ((3 as isize) as usize))

                            } else {
                                if ((if ((__local_x as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
                                    (__local_x = ((((((((((((((__local_x as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_data[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_data = __local_data + ((4 as isize) as usize))

                                } else {
                                    (__local_x = ((((((((((((((((__local_x as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_data[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_data[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_data = __local_data + ((5 as isize) as usize))

                                }
                            }
                        }
                    }

                }



            } else {
                var __ci_expr_old_44: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_x = (((*__ci_expr_old_44) as u32)))

            }

            if ((if __local_t == 1: 1 else: 0) != 0) {
                if ((if __local_c <= __local_x: 1 else: 0) != 0) {
                    return (if (if __local_c == __local_x: 1 else: 0) != 0: __local_not_negated else: ((if not (__local_not_negated != 0): 1 else: 0) as i32))
                }

                continue

            }

            loop {
                0
                if not ((0 != 0)) {
                    break
                }
            }

            if (__local_utf != 0) {
                var __ci_expr_old_45: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_y = (((*__ci_expr_old_45) as u32)))


                if ((if __local_y >= 192: 1 else: 0) != 0) {
                    if ((if ((__local_y as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_46: *const u8 = __local_data

                        (__local_data = __local_data + 1)

                        (__local_y = ((((((((__local_y as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_46) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    } else {
                        if ((if ((__local_y as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
                            (__local_y = ((((((((((__local_y as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_data = __local_data + ((2 as isize) as usize))

                        } else {
                            if ((if ((__local_y as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
                                (__local_y = ((((((((((((__local_y as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_data = __local_data + ((3 as isize) as usize))

                            } else {
                                if ((if ((__local_y as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
                                    (__local_y = ((((((((((((((__local_y as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_data[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_data = __local_data + ((4 as isize) as usize))

                                } else {
                                    (__local_y = ((((((((((((((((__local_y as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_data) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_data[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_data[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_data[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_data[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_data = __local_data + ((5 as isize) as usize))

                                }
                            }
                        }
                    }

                }



            } else {
                var __ci_expr_old_47: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_y = (((*__ci_expr_old_47) as u32)))

            }

            if ((if __local_c <= __local_y: 1 else: 0) != 0) {
                return (if (if __local_c >= __local_x: 1 else: 0) != 0: __local_not_negated else: ((if not (__local_not_negated != 0): 1 else: 0) as i32))
            }

        }

        return (if not (__local_not_negated != 0): 1 else: 0)

    }

    (__local_type_ = (((((((__local_data[0]) as i32) << (8 as u32)) as u32) | (((__local_data[1]) as i32) as u32)) as u32)))

    (__local_data = __local_data + ((2 as isize) as usize))

    (__local_next_char = __param_char_lists_end - ((((((((__local_data[0]) as i32) << (8 as u32)) as i32) | ((__local_data[(0 + 1)]) as i32)) as u32) << (1 as u32)) as usize))

    (__local_type_ = (__local_type_ as u32) & (4095 as u32))

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    if ((if __local_c >= 32768: 1 else: 0) != 0) {
        (__local_max_index = ((((__local_type_ as u32) & (3 as u32)) as u32)))

        if ((if __local_max_index == 3: 1 else: 0) != 0) {
            (__local_max_index = (((*(__local_next_char as *const u16)) as u32)))

            loop {
                0
                if not ((0 != 0)) {
                    break
                }
            }

            (__local_next_char = __local_next_char + ((2 as isize) as usize))

        }

        (__local_next_char = __local_next_char + (((__local_max_index as u32) << (1 as u32)) as usize))

        (__local_type_ = __local_type_ >> (3 as u32))

    }

    if ((if __local_c < 65536: 1 else: 0) != 0) {
        (__local_max_index = ((((__local_type_ as u32) & (3 as u32)) as u32)))

        (__local_c = (((((((__local_c as u32) << (1 as u32)) as u32) | (1 as u32)) as u16) as u32)))

        if ((if __local_max_index == 3: 1 else: 0) != 0) {
            (__local_max_index = (((*(__local_next_char as *const u16)) as u32)))

            loop {
                0
                if not ((0 != 0)) {
                    break
                }
            }

            (__local_next_char = __local_next_char + ((2 as isize) as usize))

        }

        var __ci_expr_logic_48: i32

        if ((if __local_max_index == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_48 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_48 = (if (if __local_c < (*(__local_next_char as *const u16)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_48 != 0) {
            return (if (if ((__local_type_ as u32) & (4 as u32)) != 0: 1 else: 0) == __local_not_negated: 1 else: 0)
        }


        (__local_min_index = ((0 as u32)))

        (__local_max_index = (__local_max_index -% 1))

        (__local_value = ((((__local_next_char as *const u16)[__local_max_index]) as u32)))


        if ((if __local_c >= __local_value: 1 else: 0) != 0) {
            var __ci_expr_logic_49: i32

            if ((if __local_value == __local_c: 1 else: 0) != 0) {
                (__ci_expr_logic_49 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_49 = (if (if ((__local_value as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            return (if __ci_expr_logic_49 == __local_not_negated: 1 else: 0)

        }

        (__local_max_index = (__local_max_index -% 1))

        while (1 != 0) {
            var __local_mid_index: u32 = ((((((__local_min_index as u32) +% (__local_max_index as u32)) as u32) >> (1 as u32)) as u32))

            (__local_value = ((((__local_next_char as *const u16)[__local_mid_index]) as u32)))

            if ((if __local_c < __local_value: 1 else: 0) != 0) {
                (__local_max_index = ((((__local_mid_index as u32) -% (1 as u32)) as u32)))
            } else {
                if ((if ((__local_next_char as *const u16)[((__local_mid_index as u32) +% (1 as u32))]) <= __local_c: 1 else: 0) != 0) {
                    (__local_min_index = ((((__local_mid_index as u32) +% (1 as u32)) as u32)))
                } else {
                    var __ci_expr_logic_50: i32

                    if ((if __local_value == __local_c: 1 else: 0) != 0) {
                        (__ci_expr_logic_50 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_50 = (if (if ((__local_value as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    return (if __ci_expr_logic_50 == __local_not_negated: 1 else: 0)

                }
            }

        }

    }

    (__local_max_index = ((((__local_type_ as u32) & (3 as u32)) as u32)))

    if ((if __local_max_index == 3: 1 else: 0) != 0) {
        (__local_max_index = (((*(__local_next_char as *const u16)) as u32)))

        loop {
            0
            if not ((0 != 0)) {
                break
            }
        }

        (__local_next_char = __local_next_char + ((2 as isize) as usize))

    }

    (__local_next_char = __local_next_char + (((__local_max_index as u32) << (1 as u32)) as usize))

    (__local_type_ = __local_type_ >> (3 as u32))

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    (__local_max_index = ((((__local_type_ as u32) & (3 as u32)) as u32)))

    (__local_c = ((((((__local_c as u32) << (1 as u32)) as u32) | (1 as u32)) as u32)))

    if ((if __local_max_index == 3: 1 else: 0) != 0) {
        (__local_max_index = (*(__local_next_char as *const u32)))

        (__local_next_char = __local_next_char + ((4 as isize) as usize))

    }

    var __ci_expr_logic_51: i32

    if ((if __local_max_index == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_51 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_51 = (if (if __local_c < (*(__local_next_char as *const u32)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_51 != 0) {
        return (if (if ((__local_type_ as u32) & (4 as u32)) != 0: 1 else: 0) == __local_not_negated: 1 else: 0)
    }


    (__local_min_index = ((0 as u32)))

    (__local_max_index = (__local_max_index -% 1))

    (__local_value = ((((__local_next_char as *const u32)[__local_max_index]) as u32)))


    if ((if __local_c >= __local_value: 1 else: 0) != 0) {
        var __ci_expr_logic_52: i32

        if ((if __local_value == __local_c: 1 else: 0) != 0) {
            (__ci_expr_logic_52 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_52 = (if (if ((__local_value as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        return (if __ci_expr_logic_52 == __local_not_negated: 1 else: 0)

    }

    (__local_max_index = (__local_max_index -% 1))

    while (1 != 0) {
        var __local_mid_index_1: u32 = ((((((__local_min_index as u32) +% (__local_max_index as u32)) as u32) >> (1 as u32)) as u32))

        (__local_value = ((((__local_next_char as *const u32)[__local_mid_index_1]) as u32)))

        if ((if __local_c < __local_value: 1 else: 0) != 0) {
            (__local_max_index = ((((__local_mid_index_1 as u32) -% (1 as u32)) as u32)))
        } else {
            if ((if ((__local_next_char as *const u32)[((__local_mid_index_1 as u32) +% (1 as u32))]) <= __local_c: 1 else: 0) != 0) {
                (__local_min_index = ((((__local_mid_index_1 as u32) +% (1 as u32)) as u32)))
            } else {
                var __ci_expr_logic_53: i32

                if ((if __local_value == __local_c: 1 else: 0) != 0) {
                    (__ci_expr_logic_53 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_53 = (if (if ((__local_value as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_53 == __local_not_negated: 1 else: 0)

            }
        }

    }

}

pub unsafe fn _pcre2_eclass_8(__param_c: u32, __param_data_start: *const u8, __param_data_end: *const u8, __param_char_lists_end: *const u8, __param_utf: i32) -> i32 {
    var __local_ptr: *const u8 = __param_data_start

    var __local_flags: u8

    var __local_stack: u32 = ((0 as u32))

    var __local_stack_depth: i32 = ((0 as i32))

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    var __ci_expr_old_0: *const u8 = __local_ptr

    (__local_ptr = __local_ptr + 1)

    (__local_flags = (*__ci_expr_old_0))


    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    if ((if ((__local_flags as i32) & (1 as i32)) != 0: 1 else: 0) != 0) {
        if ((if __param_c < 256: 1 else: 0) != 0) {
            return (if ((((__local_ptr[((__param_c as u32) / (8 as u32))]) as i32) as u32) & (((1 as u32) << (((__param_c as u32) & (7 as u32)) as u32)) as u32)) != 0: 1 else: 0)
        }

        (__local_ptr = __local_ptr + (((32 as u64) / (sizeof[u8]() as u64)) as usize))

    }

    while ((if __local_ptr < __param_data_end: 1 else: 0) != 0) {
        while true {
            match (*__local_ptr) {
                1 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = ((((((__local_stack as u32) >> (1 as u32)) as u32) & (((__local_stack as u32) | ((~1) as u32)) as u32)) as u32)))

                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    (__local_stack_depth = __local_stack_depth - 1)

                },
                2 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = ((((((__local_stack as u32) >> (1 as u32)) as u32) | (((__local_stack as u32) & (1 as u32)) as u32)) as u32)))

                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    (__local_stack_depth = __local_stack_depth - 1)

                },
                3 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = ((((((__local_stack as u32) >> (1 as u32)) as u32) ^ (((__local_stack as u32) & (1 as u32)) as u32)) as u32)))

                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    (__local_stack_depth = __local_stack_depth - 1)

                },
                4 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = (__local_stack as u32) ^ (1 as u32))

                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                },
                5 => {
                    var __local_matched: u32 = ((_pcre2_xclass_8(__param_c, ((__local_ptr + ((1 as isize) as usize)) + ((2 as isize) as usize)), __param_char_lists_end, __param_utf) as u32))

                    (__local_ptr = __local_ptr + (((((((__local_ptr[1]) as i32) << (8 as u32)) as i32) | ((__local_ptr[(1 + 1)]) as i32)) as u32) as usize))

                    (__local_stack = ((((((__local_stack as u32) << (1 as u32)) as u32) | (__local_matched as u32)) as u32)))

                    (__local_stack_depth = __local_stack_depth + 1)

                },
                _ => {
                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    return 0

                },
            }

            break

        }

    }

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }


    return (if ((__local_stack as u32) & (1 as u32)) != 0: 1 else: 0)

}
