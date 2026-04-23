// Migrated from PCRE2
use std.re.defs

fn _pcre2_xclass_8(__param_c: c_uint, __param_data: *const u8, char_lists_end: *const u8, __param_utf: c_int) -> c_int {
    var c = __param_c
    var data = __param_data
    var utf = __param_utf
    var t: u8

    var not_negated: c_int = (if ((unsafe: *data) & 1) == 0: 1 else: 0)

    var type_: c_uint

    var max_index: c_uint

    var min_index: c_uint

    var value: c_uint


    var next_char: *const u8

    (utf = 1)

    var __ci_expr_old_0: *const u8 = data

    (data = data + 1)

    if ((if ((unsafe: *__ci_expr_old_0) & 2) != 0: 1 else: 0) != 0) {
        if ((if c < 256: 1 else: 0) != 0) {
            return (if ((unsafe: data[(c / 8)]) & ((1 as c_uint) << ((c & 7) as c_uint))) != 0: 1 else: 0)
        }

        (data = data + (32 / sizeof[u8]()))

    }


    var __ci_expr_logic_1: c_int

    if ((if (unsafe: *data) == 3: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe: *data) == 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        var prop: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize))

        while true {
            var chartype: c_int

            var isprop: c_int

            var __ci_expr_old_3: *const u8 = data

            (data = data + 1)

            (isprop = (if (unsafe: *__ci_expr_old_3) == 3: 1 else: 0))

            var ok: c_int

            match (unsafe: *data):
                0 =>
                    (chartype = prop.chartype)

                    var __ci_expr_logic_5: c_int

                    var __ci_expr_logic_4: c_int

                    if ((if chartype == ucp_Lu: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_5 = (if (if chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
                    }

                    if ((if __ci_expr_logic_5 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }


                1 =>
                    if ((if (if (unsafe: data[1]) == _pcre2_ucp_gentype_8[prop.chartype]: 1 else: 0) == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }
                2 =>
                    if ((if (if (unsafe: data[1]) == prop.chartype: 1 else: 0) == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }
                3 =>
                    if ((if (if (unsafe: data[1]) == prop.script: 1 else: 0) == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }
                4 =>
                    var __ci_expr_logic_6: c_int

                    if ((if (unsafe: data[1]) == prop.script: 1 else: 0) != 0) {
                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_6 = (if (if ((unsafe: ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + (((prop.scriptx_bidiclass & 1023) as isize) as usize))[((unsafe: data[1]) / 32)]) & ((1 as c_uint) << (((unsafe: data[1]) % 32) as c_uint))) != 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    (ok = __ci_expr_logic_6)


                    if ((if ok == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }

                5 =>
                    (chartype = prop.chartype)

                    var __ci_expr_logic_7: c_int

                    if ((if _pcre2_ucp_gentype_8[chartype] == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_7 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_7 = (if (if _pcre2_ucp_gentype_8[chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                    }

                    if ((if __ci_expr_logic_7 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }


                6 | 7 =>
                    match c:
                        9 | 32 | 160 | 5760 | 6158 | 8192 | 8193 | 8194 | 8195 | 8196 | 8197 | 8198 | 8199 | 8200 | 8201 | 8202 | 8239 | 8287 | 12288 | 10 | 11 | 12 | 13 | 133 | 8232 | 8233 =>
                            if (isprop != 0) {
                                return not_negated
                            }
                        _ =>
                            if ((if (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0) == isprop: 1 else: 0) != 0) {
                                return not_negated
                            }
                8 =>
                    (chartype = prop.chartype)

                    var __ci_expr_logic_10: c_int

                    var __ci_expr_logic_9: c_int

                    var __ci_expr_logic_8: c_int

                    if ((if _pcre2_ucp_gentype_8[chartype] == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_8 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_8 = (if (if _pcre2_ucp_gentype_8[chartype] == 3: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_8 != 0) {
                        (__ci_expr_logic_9 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_9 = (if (if chartype == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_9 != 0) {
                        (__ci_expr_logic_10 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_10 = (if (if chartype == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
                    }

                    if ((if __ci_expr_logic_10 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }


                10 =>
                    if ((if c < 160: 1 else: 0) != 0) {
                        var __ci_expr_logic_12: c_int

                        var __ci_expr_logic_11: c_int

                        if ((if c == 36: 1 else: 0) != 0) {
                            (__ci_expr_logic_11 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_11 = (if (if c == 64: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_11 != 0) {
                            (__ci_expr_logic_12 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_12 = (if (if c == 96: 1 else: 0) != 0: 1 else: 0))
                        }

                        if ((if __ci_expr_logic_12 == isprop: 1 else: 0) != 0) {
                            return not_negated
                        }


                    } else {
                        var __ci_expr_logic_13: c_int

                        if ((if c < 55296: 1 else: 0) != 0) {
                            (__ci_expr_logic_13 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_13 = (if (if c > 57343: 1 else: 0) != 0: 1 else: 0))
                        }

                        if ((if __ci_expr_logic_13 == isprop: 1 else: 0) != 0) {
                            return not_negated
                        }


                    }
                11 =>
                    if ((if (if ((prop.scriptx_bidiclass as c_int) >> (11 as c_uint)) == (unsafe: data[1]): 1 else: 0) == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }
                12 =>
                    (ok = (if ((unsafe: ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + (((prop.bprops & 4095) as isize) as usize))[((unsafe: data[1]) / 32)]) & ((1 as c_uint) << (((unsafe: data[1]) % 32) as c_uint))) != 0: 1 else: 0))

                    if ((if ok == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }

                14 =>
                    (chartype = prop.chartype)

                    var __ci_expr_logic_19: c_int = 0

                    if ((if _pcre2_ucp_gentype_8[chartype] != 6: 1 else: 0) != 0) {
                        var __ci_expr_logic_18: c_int

                        if ((if _pcre2_ucp_gentype_8[chartype] != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_18 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_17: c_int = 0

                            var __ci_expr_logic_15: c_int = 0

                            var __ci_expr_logic_14: c_int = 0

                            if ((if chartype == ucp_Cf: 1 else: 0) != 0) {
                                (__ci_expr_logic_14 = (if (if c != 1564: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_14 != 0) {
                                (__ci_expr_logic_15 = (if (if c != 6158: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_15 != 0) {
                                var __ci_expr_logic_16: c_int

                                if ((if c < 8294: 1 else: 0) != 0) {
                                    (__ci_expr_logic_16 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_16 = (if (if c > 8297: 1 else: 0) != 0: 1 else: 0))
                                }

                                (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

                            }

                            (__ci_expr_logic_18 = (if __ci_expr_logic_17 != 0: 1 else: 0))

                        }

                        (__ci_expr_logic_19 = (if __ci_expr_logic_18 != 0: 1 else: 0))

                    }

                    if ((if __ci_expr_logic_19 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }


                15 =>
                    (chartype = prop.chartype)

                    var __ci_expr_logic_25: c_int = 0

                    var __ci_expr_logic_20: c_int = 0

                    if ((if chartype != ucp_Zl: 1 else: 0) != 0) {
                        (__ci_expr_logic_20 = (if (if chartype != ucp_Zp: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_20 != 0) {
                        var __ci_expr_logic_24: c_int

                        if ((if _pcre2_ucp_gentype_8[chartype] != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_24 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_23: c_int = 0

                            var __ci_expr_logic_21: c_int = 0

                            if ((if chartype == ucp_Cf: 1 else: 0) != 0) {
                                (__ci_expr_logic_21 = (if (if c != 1564: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_21 != 0) {
                                var __ci_expr_logic_22: c_int

                                if ((if c < 8294: 1 else: 0) != 0) {
                                    (__ci_expr_logic_22 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_22 = (if (if c > 8297: 1 else: 0) != 0: 1 else: 0))
                                }

                                (__ci_expr_logic_23 = (if __ci_expr_logic_22 != 0: 1 else: 0))

                            }

                            (__ci_expr_logic_24 = (if __ci_expr_logic_23 != 0: 1 else: 0))

                        }

                        (__ci_expr_logic_25 = (if __ci_expr_logic_24 != 0: 1 else: 0))

                    }

                    if ((if __ci_expr_logic_25 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }


                16 =>
                    (chartype = prop.chartype)

                    var __ci_expr_logic_27: c_int

                    if ((if _pcre2_ucp_gentype_8[chartype] == 4: 1 else: 0) != 0) {
                        (__ci_expr_logic_27 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_26: c_int = 0

                        if ((if c < 128: 1 else: 0) != 0) {
                            (__ci_expr_logic_26 = (if (if _pcre2_ucp_gentype_8[chartype] == 5: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_27 = (if __ci_expr_logic_26 != 0: 1 else: 0))

                    }

                    if ((if __ci_expr_logic_27 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }


                17 =>
                    var __ci_expr_logic_38: c_int

                    var __ci_expr_logic_36: c_int

                    var __ci_expr_logic_34: c_int

                    var __ci_expr_logic_32: c_int

                    var __ci_expr_logic_30: c_int

                    var __ci_expr_logic_28: c_int = 0

                    if ((if c >= 48: 1 else: 0) != 0) {
                        (__ci_expr_logic_28 = (if (if c <= 57: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_28 != 0) {
                        (__ci_expr_logic_30 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_29: c_int = 0

                        if ((if c >= 65: 1 else: 0) != 0) {
                            (__ci_expr_logic_29 = (if (if c <= 70: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_30 = (if __ci_expr_logic_29 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_30 != 0) {
                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_31: c_int = 0

                        if ((if c >= 97: 1 else: 0) != 0) {
                            (__ci_expr_logic_31 = (if (if c <= 102: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_32 = (if __ci_expr_logic_31 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_32 != 0) {
                        (__ci_expr_logic_34 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_33: c_int = 0

                        if ((if c >= 65296: 1 else: 0) != 0) {
                            (__ci_expr_logic_33 = (if (if c <= 65305: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_34 = (if __ci_expr_logic_33 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_34 != 0) {
                        (__ci_expr_logic_36 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_35: c_int = 0

                        if ((if c >= 65313: 1 else: 0) != 0) {
                            (__ci_expr_logic_35 = (if (if c <= 65318: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_36 = (if __ci_expr_logic_35 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_36 != 0) {
                        (__ci_expr_logic_38 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_37: c_int = 0

                        if ((if c >= 65345: 1 else: 0) != 0) {
                            (__ci_expr_logic_37 = (if (if c <= 65350: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_38 = (if __ci_expr_logic_37 != 0: 1 else: 0))

                    }

                    if ((if __ci_expr_logic_38 == isprop: 1 else: 0) != 0) {
                        return not_negated
                    }

                _ =>
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    return 0


            (data = data + 2)

            var __ci_expr_logic_2: c_int

            if ((if (unsafe: *data) == 3: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if (unsafe: *data) == 4: 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_2 != 0)) {
                break
            }

        }

    }


    var __ci_expr_ternary_39: c_int = 0

    if (1 != 0) {
        (__ci_expr_ternary_39 = 16)
    } else {
        (__ci_expr_ternary_39 = 4096)
    }

    if ((if (unsafe: *data) < __ci_expr_ternary_39: 1 else: 0) != 0) {
        while true {
            var __ci_expr_old_40: *const u8 = data

            (data = data + 1)

            (t = (unsafe: *__ci_expr_old_40))

            if (not ((if t != 0: 1 else: 0) != 0)) {
                break
            }

            var x: c_uint

            var y: c_uint

            if (utf != 0) {
                var __ci_expr_old_41: *const u8 = data

                (data = data + 1)

                (x = (unsafe: *__ci_expr_old_41))


                if ((if x >= 192: 1 else: 0) != 0) {
                    if ((if (x & 32) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_42: *const u8 = data

                        (data = data + 1)

                        (x = (((x & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_42) & 63))

                    } else {
                        if ((if (x & 16) == 0: 1 else: 0) != 0) {
                            (x = ((((x & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[1]) & 63))

                            (data = data + 2)

                        } else {
                            if ((if (x & 8) == 0: 1 else: 0) != 0) {
                                (x = (((((x & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: data[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[2]) & 63))

                                (data = data + 3)

                            } else {
                                if ((if (x & 4) == 0: 1 else: 0) != 0) {
                                    (x = ((((((x & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: data[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: data[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[3]) & 63))

                                    (data = data + 4)

                                } else {
                                    (x = (((((((x & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: data[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: data[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: data[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[4]) & 63))

                                    (data = data + 5)

                                }
                            }
                        }
                    }

                }

            } else {
                var __ci_expr_old_43: *const u8 = data

                (data = data + 1)

                (x = (unsafe: *__ci_expr_old_43))

            }

            if ((if t == 1: 1 else: 0) != 0) {
                if ((if c <= x: 1 else: 0) != 0) {
                    var __ci_expr_ternary_44: c_int = 0

                    if ((if c == x: 1 else: 0) != 0) {
                        (__ci_expr_ternary_44 = not_negated)
                    } else {
                        (__ci_expr_ternary_44 = (if not (not_negated != 0): 1 else: 0))
                    }

                    return __ci_expr_ternary_44

                }

                continue

            }

            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            if (utf != 0) {
                var __ci_expr_old_45: *const u8 = data

                (data = data + 1)

                (y = (unsafe: *__ci_expr_old_45))


                if ((if y >= 192: 1 else: 0) != 0) {
                    if ((if (y & 32) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_46: *const u8 = data

                        (data = data + 1)

                        (y = (((y & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_46) & 63))

                    } else {
                        if ((if (y & 16) == 0: 1 else: 0) != 0) {
                            (y = ((((y & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[1]) & 63))

                            (data = data + 2)

                        } else {
                            if ((if (y & 8) == 0: 1 else: 0) != 0) {
                                (y = (((((y & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: data[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[2]) & 63))

                                (data = data + 3)

                            } else {
                                if ((if (y & 4) == 0: 1 else: 0) != 0) {
                                    (y = ((((((y & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: data[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: data[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[3]) & 63))

                                    (data = data + 4)

                                } else {
                                    (y = (((((((y & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *data) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: data[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: data[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: data[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: data[4]) & 63))

                                    (data = data + 5)

                                }
                            }
                        }
                    }

                }

            } else {
                var __ci_expr_old_47: *const u8 = data

                (data = data + 1)

                (y = (unsafe: *__ci_expr_old_47))

            }

            if ((if c <= y: 1 else: 0) != 0) {
                var __ci_expr_ternary_48: c_int = 0

                if ((if c >= x: 1 else: 0) != 0) {
                    (__ci_expr_ternary_48 = not_negated)
                } else {
                    (__ci_expr_ternary_48 = (if not (not_negated != 0): 1 else: 0))
                }

                return __ci_expr_ternary_48

            }

        }

        return (if not (not_negated != 0): 1 else: 0)

    }


    (type_ = ((((unsafe: data[0]) as c_int) << (8 as c_uint)) as c_uint) | (unsafe: data[1]))

    (data = data + 2)

    (next_char = char_lists_end - (((((((unsafe: data[0]) as c_int) << (8 as c_uint)) | (unsafe: data[(0 + 1)])) as c_uint) as c_uint) << (1 as c_uint)))

    (type_ = type_ & 4095)

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    if ((if c >= 32768: 1 else: 0) != 0) {
        (max_index = type_ & 3)

        if ((if max_index == 3: 1 else: 0) != 0) {
            (max_index = (unsafe: *(next_char as *const c_ushort)))

            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            (next_char = next_char + 2)

        }

        (next_char = next_char + ((max_index as c_uint) << (1 as c_uint)))

        (type_ = type_ >> (3 as c_uint))

    }

    if ((if c < 65536: 1 else: 0) != 0) {
        (max_index = type_ & 3)

        (c = (((((c as c_uint) << (1 as c_uint)) | 1) as c_ushort)))

        if ((if max_index == 3: 1 else: 0) != 0) {
            (max_index = (unsafe: *(next_char as *const c_ushort)))

            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            (next_char = next_char + 2)

        }

        var __ci_expr_logic_49: c_int

        if ((if max_index == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_49 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_49 = (if (if c < (unsafe: *(next_char as *const c_ushort)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_49 != 0) {
            return (if (if (type_ & 4) != 0: 1 else: 0) == not_negated: 1 else: 0)
        }


        (min_index = 0)

        (max_index = max_index - 1)

        (value = (unsafe: (next_char as *const c_ushort)[max_index]))


        if ((if c >= value: 1 else: 0) != 0) {
            var __ci_expr_logic_50: c_int

            if ((if value == c: 1 else: 0) != 0) {
                (__ci_expr_logic_50 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_50 = (if (if (value & 1) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            return (if __ci_expr_logic_50 == not_negated: 1 else: 0)

        }

        (max_index = max_index - 1)

        while (1 != 0) {
            var mid_index: c_uint = (((min_index +% max_index) as c_uint) >> (1 as c_uint))

            (value = (unsafe: (next_char as *const c_ushort)[mid_index]))

            if ((if c < value: 1 else: 0) != 0) {
                (max_index = (mid_index -% 1))
            } else {
                if ((if (unsafe: (next_char as *const c_ushort)[(mid_index +% 1)]) <= c: 1 else: 0) != 0) {
                    (min_index = (mid_index +% 1))
                } else {
                    var __ci_expr_logic_51: c_int

                    if ((if value == c: 1 else: 0) != 0) {
                        (__ci_expr_logic_51 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_51 = (if (if (value & 1) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    return (if __ci_expr_logic_51 == not_negated: 1 else: 0)

                }
            }

        }

    }

    (max_index = type_ & 3)

    if ((if max_index == 3: 1 else: 0) != 0) {
        (max_index = (unsafe: *(next_char as *const c_ushort)))

        while true {
            if (not (0 != 0)) {
                break
            }
        }

        (next_char = next_char + 2)

    }

    (next_char = next_char + ((max_index as c_uint) << (1 as c_uint)))

    (type_ = type_ >> (3 as c_uint))

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (max_index = type_ & 3)

    (c = ((c as c_uint) << (1 as c_uint)) | 1)

    if ((if max_index == 3: 1 else: 0) != 0) {
        (max_index = (unsafe: *(next_char as *const c_uint)))

        (next_char = next_char + 4)

    }

    var __ci_expr_logic_52: c_int

    if ((if max_index == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_52 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_52 = (if (if c < (unsafe: *(next_char as *const c_uint)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_52 != 0) {
        return (if (if (type_ & 4) != 0: 1 else: 0) == not_negated: 1 else: 0)
    }


    (min_index = 0)

    (max_index = max_index - 1)

    (value = (unsafe: (next_char as *const c_uint)[max_index]))


    if ((if c >= value: 1 else: 0) != 0) {
        var __ci_expr_logic_53: c_int

        if ((if value == c: 1 else: 0) != 0) {
            (__ci_expr_logic_53 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_53 = (if (if (value & 1) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        return (if __ci_expr_logic_53 == not_negated: 1 else: 0)

    }

    (max_index = max_index - 1)

    while (1 != 0) {
        var mid_index_1: c_uint = (((min_index +% max_index) as c_uint) >> (1 as c_uint))

        (value = (unsafe: (next_char as *const c_uint)[mid_index_1]))

        if ((if c < value: 1 else: 0) != 0) {
            (max_index = (mid_index_1 -% 1))
        } else {
            if ((if (unsafe: (next_char as *const c_uint)[(mid_index_1 +% 1)]) <= c: 1 else: 0) != 0) {
                (min_index = (mid_index_1 +% 1))
            } else {
                var __ci_expr_logic_54: c_int

                if ((if value == c: 1 else: 0) != 0) {
                    (__ci_expr_logic_54 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_54 = (if (if (value & 1) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                return (if __ci_expr_logic_54 == not_negated: 1 else: 0)

            }
        }

    }

}

fn _pcre2_eclass_8(c: c_uint, data_start: *const u8, data_end: *const u8, char_lists_end: *const u8, utf: c_int) -> c_int {
    var ptr: *const u8 = data_start

    var flags: u8

    var stack: c_uint = 0

    var stack_depth: c_int = 0

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    var __ci_expr_old_0: *const u8 = ptr

    (ptr = ptr + 1)

    (flags = (unsafe: *__ci_expr_old_0))


    while true {
        if (not (0 != 0)) {
            break
        }
    }

    if ((if (flags & 1) != 0: 1 else: 0) != 0) {
        if ((if c < 256: 1 else: 0) != 0) {
            return (if ((unsafe: ptr[(c / 8)]) & ((1 as c_uint) << ((c & 7) as c_uint))) != 0: 1 else: 0)
        }

        (ptr = ptr + (32 / sizeof[u8]()))

    }

    while ((if ptr < data_end: 1 else: 0) != 0) {
        match (unsafe: *ptr):
            1 =>
                (ptr = ptr + 1)

                (stack = ((stack as c_uint) >> (1 as c_uint)) & (stack | (~1)))

                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

                (stack_depth = stack_depth - 1)

            2 =>
                (ptr = ptr + 1)

                (stack = ((stack as c_uint) >> (1 as c_uint)) | (stack & 1))

                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

                (stack_depth = stack_depth - 1)

            3 =>
                (ptr = ptr + 1)

                (stack = ((stack as c_uint) >> (1 as c_uint)) ^ (stack & 1))

                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

                (stack_depth = stack_depth - 1)

            4 =>
                (ptr = ptr + 1)

                (stack = stack ^ 1)

                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

            5 =>
                var matched: c_uint = _pcre2_xclass_8(c, ((ptr + ((1 as isize) as usize)) + ((2 as isize) as usize)), char_lists_end, utf)

                (ptr = ptr + (((((unsafe: ptr[1]) as c_int) << (8 as c_uint)) | (unsafe: ptr[(1 + 1)])) as c_uint))

                (stack = ((stack as c_uint) << (1 as c_uint)) | matched)

                (stack_depth = stack_depth + 1)

            _ =>
                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

                return 0


    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    stack_depth

    return (if (stack & 1) != 0: 1 else: 0)

}
