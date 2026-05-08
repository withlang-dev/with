// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_xclass_8")]
fn _pcre2_xclass_8(__param_c: c_uint, __param_data: *const u8, __param_char_lists_end: *const u8, __param_utf: c_int) -> c_int {
    var __local_c = __param_c
    var __local_data = __param_data
    var __local_utf = __param_utf
    var __local_t: u8

    var __local_not_negated: c_int = (if (((unsafe: *__local_data) as c_int) & 1) == 0: 1 else: 0)

    var __local_type_: c_uint

    var __local_max_index: c_uint

    var __local_min_index: c_uint

    var __local_value: c_uint


    var __local_next_char: *const u8

    (__local_utf = 1)

    var __ci_expr_old_0: *const u8 = __local_data

    (__local_data = __local_data + 1)

    if ((if (((unsafe: *__ci_expr_old_0) as c_int) & 2) != 0: 1 else: 0) != 0) {
        if ((if __local_c < 256: 1 else: 0) != 0) {
            return (if ((((unsafe: __local_data[((__local_c as c_uint) / (8 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_c as c_uint) & (7 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0)
        }

        (__local_data = __local_data + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))

    }


    var __ci_expr_logic_1: c_int

    if ((if (unsafe: *__local_data) == 3: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe: *__local_data) == 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        var __local_prop: *const ucd_record = ((&(unsafe: _pcre2_ucd_records_8[0]) as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize))

        do {
            var __local_chartype: c_int

            var __local_isprop: c_int = with 0 as __ci_expr_seq_37 {
                var __ci_expr_old_3: *const u8 = __local_data
                (__local_data = __local_data + 1)
                (if (unsafe: *__ci_expr_old_3) == 3: 1 else: 0)
            }

            var __local_ok: c_int

            while true {
                match (unsafe: *__local_data) {
                    0 => {
                        (__local_chartype = __local_prop.chartype)

                        var __ci_expr_logic_5: c_int

                        var __ci_expr_logic_4: c_int

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
                        if ((if (if (unsafe: __local_data[1]) == _pcre2_ucp_gentype_8[__local_prop.chartype]: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    2 => {
                        if ((if (if (unsafe: __local_data[1]) == __local_prop.chartype: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    3 => {
                        if ((if (if (unsafe: __local_data[1]) == __local_prop.script: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    4 => {
                        var __ci_expr_logic_6: c_int

                        if ((if (unsafe: __local_data[1]) == __local_prop.script: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if (((unsafe: ((&(unsafe: _pcre2_ucd_script_sets_8[0]) as *const c_uint) + ((((__local_prop.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[(((unsafe: __local_data[1]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe: __local_data[1]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__local_ok = __ci_expr_logic_6)


                        if ((if __local_ok == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }

                    },
                    5 => {
                        (__local_chartype = __local_prop.chartype)

                        var __ci_expr_logic_7: c_int

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
                                    if ((if (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 6: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
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
                                    if ((if (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 6: 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                                        return __local_not_negated
                                    }
                                },
                            }

                            break

                        }
                    },
                    8 => {
                        (__local_chartype = __local_prop.chartype)

                        var __ci_expr_logic_11: c_int

                        var __ci_expr_logic_10: c_int

                        var __ci_expr_logic_9: c_int

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
                            var __ci_expr_logic_13: c_int

                            var __ci_expr_logic_12: c_int

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
                            var __ci_expr_logic_14: c_int

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
                        if ((if (if ((__local_prop.scriptx_bidiclass as c_int) >> (11 as c_uint)) == (unsafe: __local_data[1]): 1 else: 0) == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }
                    },
                    12 => {
                        (__local_ok = (if (((unsafe: ((&(unsafe: _pcre2_ucd_boolprop_sets_8[0]) as *const c_uint) + ((((__local_prop.bprops as c_int) & 4095) as isize) as usize))[(((unsafe: __local_data[1]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe: __local_data[1]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0))

                        if ((if __local_ok == __local_isprop: 1 else: 0) != 0) {
                            return __local_not_negated
                        }

                    },
                    14 => {
                        (__local_chartype = __local_prop.chartype)

                        var __ci_expr_logic_20: c_int = 0

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] != 6: 1 else: 0) != 0) {
                            var __ci_expr_logic_19: c_int

                            if ((if _pcre2_ucp_gentype_8[__local_chartype] != 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_19 = (if true: 1 else: 0))
                            } else {
                                var __ci_expr_logic_18: c_int = 0

                                var __ci_expr_logic_16: c_int = 0

                                var __ci_expr_logic_15: c_int = 0

                                if ((if __local_chartype == ucp_Cf: 1 else: 0) != 0) {
                                    (__ci_expr_logic_15 = (if (if __local_c != 1564: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_15 != 0) {
                                    (__ci_expr_logic_16 = (if (if __local_c != 6158: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_16 != 0) {
                                    var __ci_expr_logic_17: c_int

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
                        (__local_chartype = __local_prop.chartype)

                        var __ci_expr_logic_26: c_int = 0

                        var __ci_expr_logic_21: c_int = 0

                        if ((if __local_chartype != ucp_Zl: 1 else: 0) != 0) {
                            (__ci_expr_logic_21 = (if (if __local_chartype != ucp_Zp: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_21 != 0) {
                            var __ci_expr_logic_25: c_int

                            if ((if _pcre2_ucp_gentype_8[__local_chartype] != 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_25 = (if true: 1 else: 0))
                            } else {
                                var __ci_expr_logic_24: c_int = 0

                                var __ci_expr_logic_22: c_int = 0

                                if ((if __local_chartype == ucp_Cf: 1 else: 0) != 0) {
                                    (__ci_expr_logic_22 = (if (if __local_c != 1564: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_22 != 0) {
                                    var __ci_expr_logic_23: c_int

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
                        (__local_chartype = __local_prop.chartype)

                        var __ci_expr_logic_28: c_int

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] == 4: 1 else: 0) != 0) {
                            (__ci_expr_logic_28 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_27: c_int = 0

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
                        var __ci_expr_logic_39: c_int

                        var __ci_expr_logic_37: c_int

                        var __ci_expr_logic_35: c_int

                        var __ci_expr_logic_33: c_int

                        var __ci_expr_logic_31: c_int

                        var __ci_expr_logic_29: c_int = 0

                        if ((if __local_c >= 48: 1 else: 0) != 0) {
                            (__ci_expr_logic_29 = (if (if __local_c <= 57: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_29 != 0) {
                            (__ci_expr_logic_31 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_30: c_int = 0

                            if ((if __local_c >= 65: 1 else: 0) != 0) {
                                (__ci_expr_logic_30 = (if (if __local_c <= 70: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_31 = (if __ci_expr_logic_30 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_31 != 0) {
                            (__ci_expr_logic_33 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_32: c_int = 0

                            if ((if __local_c >= 97: 1 else: 0) != 0) {
                                (__ci_expr_logic_32 = (if (if __local_c <= 102: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_33 != 0) {
                            (__ci_expr_logic_35 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_34: c_int = 0

                            if ((if __local_c >= 65296: 1 else: 0) != 0) {
                                (__ci_expr_logic_34 = (if (if __local_c <= 65305: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_35 = (if __ci_expr_logic_34 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_35 != 0) {
                            (__ci_expr_logic_37 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_36: c_int = 0

                            if ((if __local_c >= 65313: 1 else: 0) != 0) {
                                (__ci_expr_logic_36 = (if (if __local_c <= 65318: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_37 = (if __ci_expr_logic_36 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_37 != 0) {
                            (__ci_expr_logic_39 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_38: c_int = 0

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
                        do {
                            0
                        } while (0 != 0)

                        return 0

                    },
                }

                break

            }

            (__local_data = __local_data + ((2 as isize) as usize))

        } while { var __ci_expr_logic_2: c_int

        if ((if (unsafe: *__local_data) == 3: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (unsafe: *__local_data) == 4: 1 else: 0) != 0: 1 else: 0))
        }; (__ci_expr_logic_2 != 0) }

    }


    var __ci_expr_ternary_41: c_int = 0

    if (1 != 0) {
        (__ci_expr_ternary_41 = 16)
    } else {
        (__ci_expr_ternary_41 = 4096)
    }

    if ((if (unsafe: *__local_data) < __ci_expr_ternary_41: 1 else: 0) != 0) {
        while true {
            var __ci_expr_old_42: *const u8 = __local_data

            (__local_data = __local_data + 1)

            (__local_t = (unsafe: *__ci_expr_old_42))

            if (not ((if __local_t != 0: 1 else: 0) != 0)) {
                break
            }

            var __local_x: c_uint

            var __local_y: c_uint

            if (__local_utf != 0) {
                var __ci_expr_old_43: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_x = (unsafe: *__ci_expr_old_43))


                if ((if __local_x >= 192: 1 else: 0) != 0) {
                    if ((if ((__local_x as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_44: *const u8 = __local_data

                        (__local_data = __local_data + 1)

                        (__local_x = (((((__local_x as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_44) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    } else {
                        if ((if ((__local_x as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_x = (((((((__local_x as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_data = __local_data + ((2 as isize) as usize))

                        } else {
                            if ((if ((__local_x as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_x = (((((((((__local_x as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_data = __local_data + ((3 as isize) as usize))

                            } else {
                                if ((if ((__local_x as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                    (__local_x = (((((((((((__local_x as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_data = __local_data + ((4 as isize) as usize))

                                } else {
                                    (__local_x = (((((((((((((__local_x as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_data = __local_data + ((5 as isize) as usize))

                                }
                            }
                        }
                    }

                }

            } else {
                var __ci_expr_old_45: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_x = (unsafe: *__ci_expr_old_45))

            }

            if ((if __local_t == 1: 1 else: 0) != 0) {
                if ((if __local_c <= __local_x: 1 else: 0) != 0) {
                    var __ci_expr_ternary_46: c_int = 0

                    if ((if __local_c == __local_x: 1 else: 0) != 0) {
                        (__ci_expr_ternary_46 = __local_not_negated)
                    } else {
                        (__ci_expr_ternary_46 = (if not (__local_not_negated != 0): 1 else: 0))
                    }

                    return __ci_expr_ternary_46

                }

                continue

            }

            do {
                0
            } while (0 != 0)

            if (__local_utf != 0) {
                var __ci_expr_old_47: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_y = (unsafe: *__ci_expr_old_47))


                if ((if __local_y >= 192: 1 else: 0) != 0) {
                    if ((if ((__local_y as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_48: *const u8 = __local_data

                        (__local_data = __local_data + 1)

                        (__local_y = (((((__local_y as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_48) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    } else {
                        if ((if ((__local_y as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_y = (((((((__local_y as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_data = __local_data + ((2 as isize) as usize))

                        } else {
                            if ((if ((__local_y as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_y = (((((((((__local_y as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_data = __local_data + ((3 as isize) as usize))

                            } else {
                                if ((if ((__local_y as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                    (__local_y = (((((((((((__local_y as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_data = __local_data + ((4 as isize) as usize))

                                } else {
                                    (__local_y = (((((((((((((__local_y as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_data) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_data[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_data[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_data = __local_data + ((5 as isize) as usize))

                                }
                            }
                        }
                    }

                }

            } else {
                var __ci_expr_old_49: *const u8 = __local_data

                (__local_data = __local_data + 1)

                (__local_y = (unsafe: *__ci_expr_old_49))

            }

            if ((if __local_c <= __local_y: 1 else: 0) != 0) {
                var __ci_expr_ternary_50: c_int = 0

                if ((if __local_c >= __local_x: 1 else: 0) != 0) {
                    (__ci_expr_ternary_50 = __local_not_negated)
                } else {
                    (__ci_expr_ternary_50 = (if not (__local_not_negated != 0): 1 else: 0))
                }

                return __ci_expr_ternary_50

            }

        }

        return (if not (__local_not_negated != 0): 1 else: 0)

    }


    (__local_type_ = (((((unsafe: __local_data[0]) as c_int) << (8 as c_uint)) as c_uint) as c_uint) | (((unsafe: __local_data[1]) as c_int) as c_uint))

    (__local_data = __local_data + ((2 as isize) as usize))

    (__local_next_char = __param_char_lists_end - ((((((((unsafe: __local_data[0]) as c_int) << (8 as c_uint)) | ((unsafe: __local_data[(0 + 1)]) as c_int)) as c_uint) as c_uint) << (1 as c_uint)) as usize))

    (__local_type_ = __local_type_ & 4095)

    do {
        0
    } while (0 != 0)

    if ((if __local_c >= 32768: 1 else: 0) != 0) {
        (__local_max_index = (__local_type_ as c_uint) & (3 as c_uint))

        if ((if __local_max_index == 3: 1 else: 0) != 0) {
            (__local_max_index = (unsafe: *(__local_next_char as *const c_ushort)))

            do {
                0
            } while (0 != 0)

            (__local_next_char = __local_next_char + ((2 as isize) as usize))

        }

        (__local_next_char = __local_next_char + (((__local_max_index as c_uint) << (1 as c_uint)) as usize))

        (__local_type_ = __local_type_ >> (3 as c_uint))

    }

    if ((if __local_c < 65536: 1 else: 0) != 0) {
        (__local_max_index = (__local_type_ as c_uint) & (3 as c_uint))

        (__local_c = ((((((__local_c as c_uint) << (1 as c_uint)) as c_uint) | (1 as c_uint)) as c_ushort)))

        if ((if __local_max_index == 3: 1 else: 0) != 0) {
            (__local_max_index = (unsafe: *(__local_next_char as *const c_ushort)))

            do {
                0
            } while (0 != 0)

            (__local_next_char = __local_next_char + ((2 as isize) as usize))

        }

        var __ci_expr_logic_51: c_int

        if ((if __local_max_index == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_51 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_51 = (if (if __local_c < (unsafe: *(__local_next_char as *const c_ushort)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_51 != 0) {
            return (if (if ((__local_type_ as c_uint) & (4 as c_uint)) != 0: 1 else: 0) == __local_not_negated: 1 else: 0)
        }


        (__local_min_index = 0)

        (__local_max_index = __local_max_index - 1)

        (__local_value = (unsafe: (__local_next_char as *const c_ushort)[__local_max_index]))


        if ((if __local_c >= __local_value: 1 else: 0) != 0) {
            var __ci_expr_logic_52: c_int

            if ((if __local_value == __local_c: 1 else: 0) != 0) {
                (__ci_expr_logic_52 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_52 = (if (if ((__local_value as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            return (if __ci_expr_logic_52 == __local_not_negated: 1 else: 0)

        }

        (__local_max_index = __local_max_index - 1)

        while (1 != 0) {
            var __local_mid_index: c_uint = ((((__local_min_index as c_uint) +% (__local_max_index as c_uint)) as c_uint) >> (1 as c_uint))

            (__local_value = (unsafe: (__local_next_char as *const c_ushort)[__local_mid_index]))

            if ((if __local_c < __local_value: 1 else: 0) != 0) {
                (__local_max_index = ((__local_mid_index as c_uint) -% (1 as c_uint)))
            } else {
                if ((if (unsafe: (__local_next_char as *const c_ushort)[((__local_mid_index as c_uint) +% (1 as c_uint))]) <= __local_c: 1 else: 0) != 0) {
                    (__local_min_index = ((__local_mid_index as c_uint) +% (1 as c_uint)))
                } else {
                    var __ci_expr_logic_53: c_int

                    if ((if __local_value == __local_c: 1 else: 0) != 0) {
                        (__ci_expr_logic_53 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_53 = (if (if ((__local_value as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    return (if __ci_expr_logic_53 == __local_not_negated: 1 else: 0)

                }
            }

        }

    }

    (__local_max_index = (__local_type_ as c_uint) & (3 as c_uint))

    if ((if __local_max_index == 3: 1 else: 0) != 0) {
        (__local_max_index = (unsafe: *(__local_next_char as *const c_ushort)))

        do {
            0
        } while (0 != 0)

        (__local_next_char = __local_next_char + ((2 as isize) as usize))

    }

    (__local_next_char = __local_next_char + (((__local_max_index as c_uint) << (1 as c_uint)) as usize))

    (__local_type_ = __local_type_ >> (3 as c_uint))

    do {
        0
    } while (0 != 0)

    (__local_max_index = (__local_type_ as c_uint) & (3 as c_uint))

    (__local_c = (((__local_c as c_uint) << (1 as c_uint)) as c_uint) | (1 as c_uint))

    if ((if __local_max_index == 3: 1 else: 0) != 0) {
        (__local_max_index = (unsafe: *(__local_next_char as *const c_uint)))

        (__local_next_char = __local_next_char + ((4 as isize) as usize))

    }

    var __ci_expr_logic_54: c_int

    if ((if __local_max_index == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_54 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_54 = (if (if __local_c < (unsafe: *(__local_next_char as *const c_uint)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_54 != 0) {
        return (if (if ((__local_type_ as c_uint) & (4 as c_uint)) != 0: 1 else: 0) == __local_not_negated: 1 else: 0)
    }


    (__local_min_index = 0)

    (__local_max_index = __local_max_index - 1)

    (__local_value = (unsafe: (__local_next_char as *const c_uint)[__local_max_index]))


    if ((if __local_c >= __local_value: 1 else: 0) != 0) {
        var __ci_expr_logic_55: c_int

        if ((if __local_value == __local_c: 1 else: 0) != 0) {
            (__ci_expr_logic_55 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_55 = (if (if ((__local_value as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        return (if __ci_expr_logic_55 == __local_not_negated: 1 else: 0)

    }

    (__local_max_index = __local_max_index - 1)

    while (1 != 0) {
        var __local_mid_index_1: c_uint = ((((__local_min_index as c_uint) +% (__local_max_index as c_uint)) as c_uint) >> (1 as c_uint))

        (__local_value = (unsafe: (__local_next_char as *const c_uint)[__local_mid_index_1]))

        if ((if __local_c < __local_value: 1 else: 0) != 0) {
            (__local_max_index = ((__local_mid_index_1 as c_uint) -% (1 as c_uint)))
        } else {
            if ((if (unsafe: (__local_next_char as *const c_uint)[((__local_mid_index_1 as c_uint) +% (1 as c_uint))]) <= __local_c: 1 else: 0) != 0) {
                (__local_min_index = ((__local_mid_index_1 as c_uint) +% (1 as c_uint)))
            } else {
                var __ci_expr_logic_56: c_int

                if ((if __local_value == __local_c: 1 else: 0) != 0) {
                    (__ci_expr_logic_56 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_56 = (if (if ((__local_value as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_56 == __local_not_negated: 1 else: 0)

            }
        }

    }

}

@[c_export("_pcre2_eclass_8")]
fn _pcre2_eclass_8(__param_c: c_uint, __param_data_start: *const u8, __param_data_end: *const u8, __param_char_lists_end: *const u8, __param_utf: c_int) -> c_int {
    var __local_ptr: *const u8 = __param_data_start

    var __local_flags: u8

    var __local_stack: c_uint = 0

    var __local_stack_depth: c_int = 0

    do {
        0
    } while (0 != 0)

    var __ci_expr_old_0: *const u8 = __local_ptr

    (__local_ptr = __local_ptr + 1)

    (__local_flags = (unsafe: *__ci_expr_old_0))


    do {
        0
    } while (0 != 0)

    if ((if ((__local_flags as c_int) & 1) != 0: 1 else: 0) != 0) {
        if ((if __param_c < 256: 1 else: 0) != 0) {
            return (if ((((unsafe: __local_ptr[((__param_c as c_uint) / (8 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__param_c as c_uint) & (7 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0)
        }

        (__local_ptr = __local_ptr + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))

    }

    while ((if __local_ptr < __param_data_end: 1 else: 0) != 0) {
        while true {
            match (unsafe: *__local_ptr) {
                1 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = (((__local_stack as c_uint) >> (1 as c_uint)) as c_uint) & (((__local_stack as c_uint) | ((~1) as c_uint)) as c_uint))

                    do {
                        0
                    } while (0 != 0)

                    (__local_stack_depth = __local_stack_depth - 1)

                },
                2 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = (((__local_stack as c_uint) >> (1 as c_uint)) as c_uint) | (((__local_stack as c_uint) & (1 as c_uint)) as c_uint))

                    do {
                        0
                    } while (0 != 0)

                    (__local_stack_depth = __local_stack_depth - 1)

                },
                3 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = (((__local_stack as c_uint) >> (1 as c_uint)) as c_uint) ^ (((__local_stack as c_uint) & (1 as c_uint)) as c_uint))

                    do {
                        0
                    } while (0 != 0)

                    (__local_stack_depth = __local_stack_depth - 1)

                },
                4 => {
                    (__local_ptr = __local_ptr + 1)

                    (__local_stack = __local_stack ^ 1)

                    do {
                        0
                    } while (0 != 0)

                },
                5 => {
                    var __local_matched: c_uint = _pcre2_xclass_8(__param_c, ((__local_ptr + ((1 as isize) as usize)) + ((2 as isize) as usize)), __param_char_lists_end, __param_utf)

                    (__local_ptr = __local_ptr + ((((((unsafe: __local_ptr[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_ptr[(1 + 1)]) as c_int)) as c_uint) as usize))

                    (__local_stack = (((__local_stack as c_uint) << (1 as c_uint)) as c_uint) | (__local_matched as c_uint))

                    (__local_stack_depth = __local_stack_depth + 1)

                },
                _ => {
                    do {
                        0
                    } while (0 != 0)

                    return 0

                },
            }

            break

        }

    }

    do {
        0
    } while (0 != 0)

    __local_stack_depth

    return (if ((__local_stack as c_uint) & (1 as c_uint)) != 0: 1 else: 0)

}
