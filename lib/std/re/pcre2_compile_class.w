// Migrated from PCRE2
use std.re.defs

fn _pcre2_update_classbits_8(ptype: c_uint, pdata: c_uint, negated: c_int, __param_classbits: *mut u8) {
    var classbits = __param_classbits
    var c: c_int

    var chartype: c_int


    var prop: *const ucd_record

    var gentype: c_uint

    var set_bit: c_int

    if ((if ptype == 13: 1 else: 0) != 0) {
        if ((if not (negated != 0): 1 else: 0) != 0) {
            with_memset((classbits as *i8), 255, (32 as i64))
        }

        return

    }

    (c = 0)

    while ((if c < 256: 1 else: 0) != 0) {
        (prop = (&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(c / 128)] * 128) + (c % 128))] as isize) as usize))

        (set_bit = 0)

        set_bit

        while true {
            match ptype {
                0 => {
                    (chartype = prop.chartype)

                    var __ci_expr_logic_1: c_int

                    var __ci_expr_logic_0: c_int

                    if ((if chartype == ucp_Lu: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_0 = (if (if chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
                    }

                    (set_bit = __ci_expr_logic_1)


                },
                1 => {
                    (set_bit = (if _pcre2_ucp_gentype_8[prop.chartype] == pdata: 1 else: 0))
                },
                2 => {
                    (set_bit = (if prop.chartype == pdata: 1 else: 0))
                },
                3 => {
                    (set_bit = (if prop.script == pdata: 1 else: 0))
                },
                4 => {
                    var __ci_expr_logic_2: c_int

                    if ((if prop.script == pdata: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if (if ((unsafe: ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + (((prop.scriptx_bidiclass & 1023) as isize) as usize))[(pdata / 32)]) & ((1 as c_uint) << ((pdata % 32) as c_uint))) != 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    (set_bit = __ci_expr_logic_2)

                },
                5 => {
                    (gentype = _pcre2_ucp_gentype_8[prop.chartype])

                    var __ci_expr_logic_3: c_int

                    if ((if gentype == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_3 = (if (if gentype == 3: 1 else: 0) != 0: 1 else: 0))
                    }

                    (set_bit = __ci_expr_logic_3)


                },
                6 => {
                    while true {
                        match c {
                            9 => {
                                (set_bit = 1)
                            },
                            32 => {
                                (set_bit = 1)
                            },
                            160 => {
                                (set_bit = 1)
                            },
                            10 => {
                                (set_bit = 1)
                            },
                            11 => {
                                (set_bit = 1)
                            },
                            12 => {
                                (set_bit = 1)
                            },
                            13 => {
                                (set_bit = 1)
                            },
                            133 => {
                                (set_bit = 1)
                            },
                            _ => {
                                (set_bit = (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0))
                            },
                        }

                        break

                    }
                },
                7 => {
                    while true {
                        match c {
                            9 => {
                                (set_bit = 1)
                            },
                            32 => {
                                (set_bit = 1)
                            },
                            160 => {
                                (set_bit = 1)
                            },
                            10 => {
                                (set_bit = 1)
                            },
                            11 => {
                                (set_bit = 1)
                            },
                            12 => {
                                (set_bit = 1)
                            },
                            13 => {
                                (set_bit = 1)
                            },
                            133 => {
                                (set_bit = 1)
                            },
                            _ => {
                                (set_bit = (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0))
                            },
                        }

                        break

                    }
                },
                8 => {
                    (chartype = prop.chartype)

                    (gentype = _pcre2_ucp_gentype_8[chartype])

                    var __ci_expr_logic_7: c_int

                    var __ci_expr_logic_6: c_int

                    var __ci_expr_logic_5: c_int

                    if ((if gentype == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_5 = (if (if gentype == 3: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_5 != 0) {
                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_6 = (if (if chartype == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_6 != 0) {
                        (__ci_expr_logic_7 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_7 = (if (if chartype == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
                    }

                    (set_bit = __ci_expr_logic_7)


                },
                10 => {
                    var __ci_expr_logic_10: c_int

                    var __ci_expr_logic_9: c_int

                    var __ci_expr_logic_8: c_int

                    if ((if c == 36: 1 else: 0) != 0) {
                        (__ci_expr_logic_8 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_8 = (if (if c == 64: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_8 != 0) {
                        (__ci_expr_logic_9 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_9 = (if (if c == 96: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_9 != 0) {
                        (__ci_expr_logic_10 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_10 = (if (if c >= 160: 1 else: 0) != 0: 1 else: 0))
                    }

                    (set_bit = __ci_expr_logic_10)

                },
                11 => {
                    (set_bit = (if ((prop.scriptx_bidiclass as c_int) >> (11 as c_uint)) == pdata: 1 else: 0))
                },
                12 => {
                    (set_bit = (if ((unsafe: ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + (((prop.bprops & 4095) as isize) as usize))[(pdata / 32)]) & ((1 as c_uint) << ((pdata % 32) as c_uint))) != 0: 1 else: 0))
                },
                14 => {
                    (chartype = prop.chartype)

                    (gentype = _pcre2_ucp_gentype_8[chartype])

                    var __ci_expr_logic_12: c_int = 0

                    if ((if gentype != 6: 1 else: 0) != 0) {
                        var __ci_expr_logic_11: c_int

                        if ((if gentype != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_11 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_11 = (if (if chartype == ucp_Cf: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_12 = (if __ci_expr_logic_11 != 0: 1 else: 0))

                    }

                    (set_bit = __ci_expr_logic_12)


                },
                15 => {
                    (chartype = prop.chartype)

                    var __ci_expr_logic_15: c_int = 0

                    var __ci_expr_logic_13: c_int = 0

                    if ((if chartype != ucp_Zl: 1 else: 0) != 0) {
                        (__ci_expr_logic_13 = (if (if chartype != ucp_Zp: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_13 != 0) {
                        var __ci_expr_logic_14: c_int

                        if ((if _pcre2_ucp_gentype_8[chartype] != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if chartype == ucp_Cf: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_15 = (if __ci_expr_logic_14 != 0: 1 else: 0))

                    }

                    (set_bit = __ci_expr_logic_15)


                },
                16 => {
                    (gentype = _pcre2_ucp_gentype_8[prop.chartype])

                    var __ci_expr_logic_17: c_int

                    if ((if gentype == 4: 1 else: 0) != 0) {
                        (__ci_expr_logic_17 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_16: c_int = 0

                        if ((if c < 128: 1 else: 0) != 0) {
                            (__ci_expr_logic_16 = (if (if gentype == 5: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

                    }

                    (set_bit = __ci_expr_logic_17)


                },
                _ => {
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    var __ci_expr_logic_22: c_int

                    var __ci_expr_logic_20: c_int

                    var __ci_expr_logic_18: c_int = 0

                    if ((if c >= 48: 1 else: 0) != 0) {
                        (__ci_expr_logic_18 = (if (if c <= 57: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_18 != 0) {
                        (__ci_expr_logic_20 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_19: c_int = 0

                        if ((if c >= 65: 1 else: 0) != 0) {
                            (__ci_expr_logic_19 = (if (if c <= 70: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_20 = (if __ci_expr_logic_19 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_20 != 0) {
                        (__ci_expr_logic_22 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_21: c_int = 0

                        if ((if c >= 97: 1 else: 0) != 0) {
                            (__ci_expr_logic_21 = (if (if c <= 102: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

                    }

                    (set_bit = __ci_expr_logic_22)


                },
            }

            break

        }

        if (negated != 0) {
            (set_bit = (if not (set_bit != 0): 1 else: 0))
        }

        if (set_bit != 0) {
            ((unsafe: *classbits) = (unsafe: *classbits) | (((1 as c_int) << ((c & 7) as c_uint)) as u8))
        }

        if ((if (c & 7) == 7: 1 else: 0) != 0) {
            (classbits = classbits + 1)
        }


        (c = c + 1)

    }


}

fn _pcre2_compile_class_not_nested_8(options: c_uint, xoptions: c_uint, start_ptr: *mut c_uint, pcode: *mut *mut u8, negate_class: c_int, has_bitmap: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint {
    var pptr__goto_1076_11: *mut c_uint = null
    var code__goto_1077_14: *mut u8 = null
    var should_flip_negation__goto_1078_6: c_int = 0
    var cbits__goto_1079_16: *const u8 = null
    var classbits__goto_1082_16: *mut u8 = null
    var utf__goto_1085_6: c_int = 0
    var xclass_props__goto_1093_10: c_uint = 0
    var class_uchardata__goto_1094_14: *mut u8 = null
    var cranges__goto_1095_15: *mut class_ranges = null
    var ranges__goto_1149_21: *const c_uint = null
    var meta__goto_1174_12: c_uint = 0
    var local_negate__goto_1175_8: c_int = 0
    var posix_class__goto_1176_7: c_int = 0
    var taboffset__goto_1177_7: c_int = 0
    var tabopt__goto_1177_18: c_int = 0
    var pbits__goto_1178_22: class_bits_storage
    var escape__goto_1179_12: c_uint = 0
    var c__goto_1179_20: c_uint = 0
    var ptype__goto_1211_16: c_uint = 0
    var i__goto_1279_18: c_int = 0
    var i__goto_1282_18: c_int = 0
    var classwords__goto_1312_17: *mut c_uint = null
    var i__goto_1315_18: c_int = 0
    var i__goto_1318_18: c_int = 0
    var i__goto_1340_16: c_int = 0
    var i__goto_1345_16: c_int = 0
    var i__goto_1350_16: c_int = 0
    var i__goto_1355_16: c_int = 0
    var i__goto_1367_16: c_int = 0
    var i__goto_1372_16: c_int = 0
    var ptype__goto_1437_18: c_uint = 0
    var pdata__goto_1438_18: c_uint = 0
    var d__goto_1497_14: c_uint = 0
    var range__goto_1581_13: *mut c_uint = null
    var end__goto_1582_13: *mut c_uint = null
    var range_start__goto_1616_16: c_uint = 0
    var range_end__goto_1617_16: c_uint = 0
    var previous__goto_1707_16: *mut u8 = null
    var classwords__goto_1723_17: *mut c_uint = null
    var i__goto_1724_16: c_int = 0
    var char_lists_size__goto_1748_12: c_ulong = 0
    var data__goto_1777_16: *mut u8 = null
    var classwords__goto_1840_13: *mut c_uint = null
    var i__goto_1842_12: c_int = 0
    var classwords__goto_1848_19: *const c_uint = null
    var i__goto_1849_7: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc {
            0 => {
                (__goto_pending = 0)
                (pptr__goto_1076_11 = start_ptr)
                (code__goto_1077_14 = (unsafe: *pcode))
                (cbits__goto_1079_16 = cb.cbits)
                (classbits__goto_1082_16 = ((&cb.classbits.classbits[0] as *mut u8)))
                (utf__goto_1085_6 = (if (options & 524288) != 0: 1 else: 0))
                (should_flip_negation__goto_1078_6 = 0)
                if (__goto_pending != 0) {
                    continue
                }
                (xclass_props__goto_1093_10 = 0)
                if (__goto_pending != 0) {
                    continue
                }
                (cranges__goto_1095_15 = ((null as *mut class_ranges)))
                if (__goto_pending != 0) {
                    continue
                }
                if (utf__goto_1085_6 != 0) {
                    if ((if lengthptr != null: 1 else: 0) != 0) {
                        (cranges__goto_1095_15 = compile_optimize_class(pptr__goto_1076_11, options, xoptions, cb))
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if cranges__goto_1095_15 == null: 1 else: 0) != 0) {
                            ((unsafe: *errorcodeptr) = ERR21)
                            if (__goto_pending != 0) {
                                continue
                            }
                            return null
                            if (__goto_pending != 0) {
                                continue
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if cb.last_data != null: 1 else: 0) != 0) {
                            (cb.last_data.next = (((&cranges__goto_1095_15.header as *const compile_data) as *mut compile_data)))
                        } else {
                            (cb.first_data = (((&cranges__goto_1095_15.header as *const compile_data) as *mut compile_data)))
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        (cb.last_data = (((&cranges__goto_1095_15.header as *const compile_data) as *mut compile_data)))
                        if (__goto_pending != 0) {
                            continue
                        }
                    } else {
                        (cranges__goto_1095_15 = ((cb.first_data as *mut class_ranges)))
                        if (__goto_pending != 0) {
                            continue
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        (cb.first_data = cranges__goto_1095_15.header.next)
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if cranges__goto_1095_15.range_list_size > 0: 1 else: 0) != 0) {
                        (ranges__goto_1149_21 = (((cranges__goto_1095_15 + ((1 as isize) as usize)) as *const c_uint)))
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if (unsafe: ranges__goto_1149_21[0]) <= 255: 1 else: 0) != 0) {
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        var __ci_expr_logic_1: c_int = 0
                        var __ci_expr_ternary_0: c_uint = 0
                        if (utf__goto_1085_6 != 0) {
                            (__ci_expr_ternary_0 = 1114111)
                        } else {
                            (__ci_expr_ternary_0 = 255)
                        }
                        if ((if (unsafe: ranges__goto_1149_21[(cranges__goto_1095_15.range_list_size - 1)]) == __ci_expr_ternary_0: 1 else: 0) != 0) {
                            (__ci_expr_logic_1 = (if (if (unsafe: ranges__goto_1149_21[(cranges__goto_1095_15.range_list_size - 2)]) <= 256: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_1 != 0) {
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 16)
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                (class_uchardata__goto_1094_14 = (code__goto_1077_14 + ((2 as isize) as usize)) + ((2 as isize) as usize))
                if (__goto_pending != 0) {
                    continue
                }
                with_memset((classbits__goto_1082_16 as *i8), 0, (32 as i64))
                if (__goto_pending != 0) {
                    continue
                }
                while (1 != 0) {
                    var __ci_expr_old_2: *mut c_uint = pptr__goto_1076_11
                    (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                    (meta__goto_1174_12 = (unsafe: *__ci_expr_old_2))
                    if (__goto_pending != 0) {
                        break
                    }
                    var __ci_expr_switch_continue_21: i32 = 0
                    while true {
                        match (meta__goto_1174_12 & (4294901760 as c_uint)) {
                            2149580800 => {
                                (local_negate__goto_1175_8 = (if meta__goto_1174_12 == 2149646336: 1 else: 0))

                                var __ci_expr_old_3: *mut c_uint = pptr__goto_1076_11

                                (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)

                                (posix_class__goto_1176_7 = (unsafe: *__ci_expr_old_3))


                                if (local_negate__goto_1175_8 != 0) {
                                    (should_flip_negation__goto_1078_6 = 1)
                                }

                                var __ci_expr_logic_4: c_int = 0

                                if ((if (options & 8) != 0: 1 else: 0) != 0) {
                                    (__ci_expr_logic_4 = (if (if posix_class__goto_1176_7 <= 2: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_4 != 0) {
                                    (posix_class__goto_1176_7 = 0)
                                }


                                var __ci_expr_logic_5: c_int = 0

                                if ((if (options & 131072) != 0: 1 else: 0) != 0) {
                                    (__ci_expr_logic_5 = (if (if (xoptions & 2048) == 0: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_5 != 0) {
                                    var __ci_expr_switch_continue_12: i32 = 0

                                    while true {
                                        match posix_class__goto_1176_7 {
                                            8 => {
                                                var __ci_expr_ternary_7: c_int = 0

                                                if ((if posix_class__goto_1176_7 == 8: 1 else: 0) != 0) {
                                                    (__ci_expr_ternary_7 = 14)
                                                } else {
                                                    var __ci_expr_ternary_6: c_int = 0

                                                    if ((if posix_class__goto_1176_7 == 9: 1 else: 0) != 0) {
                                                        (__ci_expr_ternary_6 = 15)
                                                    } else {
                                                        (__ci_expr_ternary_6 = 16)
                                                    }

                                                    (__ci_expr_ternary_7 = __ci_expr_ternary_6)

                                                }

                                                (ptype__goto_1211_16 = __ci_expr_ternary_7)


                                                _pcre2_update_classbits_8(ptype__goto_1211_16, 0, local_negate__goto_1175_8, classbits__goto_1082_16)

                                                if ((if (xclass_props__goto_1093_10 & 16) == 0: 1 else: 0) != 0) {
                                                    if ((if lengthptr != null: 1 else: 0) != 0) {
                                                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                                    } else {
                                                        var __ci_expr_old_8: *mut u8 = class_uchardata__goto_1094_14

                                                        (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)

                                                        var __ci_expr_ternary_9: c_int = 0

                                                        if (local_negate__goto_1175_8 != 0) {
                                                            (__ci_expr_ternary_9 = 4)
                                                        } else {
                                                            (__ci_expr_ternary_9 = 3)
                                                        }

                                                        ((unsafe: *__ci_expr_old_8) = __ci_expr_ternary_9)


                                                        if (__goto_pending != 0) {
                                                            break
                                                        }

                                                        var __ci_expr_old_10: *mut u8 = class_uchardata__goto_1094_14

                                                        (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)

                                                        ((unsafe: *__ci_expr_old_10) = ((ptype__goto_1211_16 as u8)))


                                                        if (__goto_pending != 0) {
                                                            break
                                                        }

                                                        var __ci_expr_old_11: *mut u8 = class_uchardata__goto_1094_14

                                                        (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)

                                                        ((unsafe: *__ci_expr_old_11) = 0)


                                                        if (__goto_pending != 0) {
                                                            break
                                                        }

                                                    }

                                                    if (__goto_pending != 0) {
                                                        break
                                                    }

                                                    (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)

                                                    if (__goto_pending != 0) {
                                                        break
                                                    }

                                                }

                                                continue

                                            },
                                        }

                                        break

                                    }

                                    if (__ci_expr_switch_continue_12 != 0) {
                                        continue
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }


                                (posix_class__goto_1176_7 = posix_class__goto_1176_7 * 3)

                                with_memcpy(((&pbits__goto_1178_22.classbits[0] as *mut u8) as *i8), ((cbits__goto_1079_16 + ((_pcre2_posix_class_maps8[posix_class__goto_1176_7] as isize) as usize)) as *i8), (32 as i64))

                                (taboffset__goto_1177_7 = _pcre2_posix_class_maps8[(posix_class__goto_1176_7 + 1)])

                                (tabopt__goto_1177_18 = _pcre2_posix_class_maps8[(posix_class__goto_1176_7 + 2)])

                                if ((if taboffset__goto_1177_7 >= 0: 1 else: 0) != 0) {
                                    if ((if tabopt__goto_1177_18 >= 0: 1 else: 0) != 0) {
                                        (i__goto_1279_18 = 0)

                                        while ((if i__goto_1279_18 < 32: 1 else: 0) != 0) {
                                            (pbits__goto_1178_22.classbits[i__goto_1279_18] = pbits__goto_1178_22.classbits[i__goto_1279_18] | (unsafe: cbits__goto_1079_16[(i__goto_1279_18 + taboffset__goto_1177_7)]))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (i__goto_1279_18 = i__goto_1279_18 + 1)

                                        }

                                    } else {
                                        (i__goto_1282_18 = 0)

                                        while ((if i__goto_1282_18 < 32: 1 else: 0) != 0) {
                                            (pbits__goto_1178_22.classbits[i__goto_1282_18] = pbits__goto_1178_22.classbits[i__goto_1282_18] & ((~(unsafe: cbits__goto_1079_16[(i__goto_1282_18 + taboffset__goto_1177_7)])) as u8))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (i__goto_1282_18 = i__goto_1282_18 + 1)

                                        }

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                if ((if tabopt__goto_1177_18 < 0: 1 else: 0) != 0) {
                                    (tabopt__goto_1177_18 = 0 - tabopt__goto_1177_18)
                                }

                                if ((if tabopt__goto_1177_18 == 1: 1 else: 0) != 0) {
                                    (pbits__goto_1178_22.classbits[1] = pbits__goto_1178_22.classbits[1] & (~60))
                                } else {
                                    if ((if tabopt__goto_1177_18 == 2: 1 else: 0) != 0) {
                                        (pbits__goto_1178_22.classbits[11] = pbits__goto_1178_22.classbits[11] & 127)
                                    }
                                }

                                (classwords__goto_1312_17 = ((&cb.classbits.classwords[0] as *mut c_uint)))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (local_negate__goto_1175_8 != 0) {
                                    (i__goto_1315_18 = 0)

                                    while ((if i__goto_1315_18 < 8: 1 else: 0) != 0) {
                                        ((unsafe: classwords__goto_1312_17[i__goto_1315_18]) = (unsafe: classwords__goto_1312_17[i__goto_1315_18]) | (~pbits__goto_1178_22.classwords[i__goto_1315_18]))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_1315_18 = i__goto_1315_18 + 1)

                                    }

                                } else {
                                    (i__goto_1318_18 = 0)

                                    while ((if i__goto_1318_18 < 8: 1 else: 0) != 0) {
                                        ((unsafe: classwords__goto_1312_17[i__goto_1318_18]) = (unsafe: classwords__goto_1312_17[i__goto_1318_18]) | pbits__goto_1178_22.classwords[i__goto_1318_18])

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_1318_18 = i__goto_1318_18 + 1)

                                    }

                                }

                                if (__goto_pending != 0) {
                                    break
                                }


                                (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)

                                continue

                            },
                            2147811328 => {
                                var __ci_expr_old_13: *mut c_uint = pptr__goto_1076_11

                                (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)

                                (meta__goto_1174_12 = (unsafe: *__ci_expr_old_13))

                            },
                            2149318656 => {
                                (escape__goto_1179_12 = meta__goto_1174_12 & 65535)

                                var __ci_expr_switch_continue_20: i32 = 0

                                while true {
                                    match escape__goto_1179_12 {
                                        7 => {
                                            (i__goto_1340_16 = 0)

                                            while ((if i__goto_1340_16 < 32: 1 else: 0) != 0) {
                                                ((unsafe: classbits__goto_1082_16[i__goto_1340_16]) = (unsafe: classbits__goto_1082_16[i__goto_1340_16]) | (unsafe: cbits__goto_1079_16[(i__goto_1340_16 + 64)]))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (i__goto_1340_16 = i__goto_1340_16 + 1)

                                            }

                                        },
                                        6 => {
                                            (should_flip_negation__goto_1078_6 = 1)

                                            (i__goto_1345_16 = 0)

                                            while ((if i__goto_1345_16 < 32: 1 else: 0) != 0) {
                                                ((unsafe: classbits__goto_1082_16[i__goto_1345_16]) = (unsafe: classbits__goto_1082_16[i__goto_1345_16]) | ((~(unsafe: cbits__goto_1079_16[(i__goto_1345_16 + 64)])) as u8))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (i__goto_1345_16 = i__goto_1345_16 + 1)

                                            }


                                        },
                                        11 => {
                                            (i__goto_1350_16 = 0)

                                            while ((if i__goto_1350_16 < 32: 1 else: 0) != 0) {
                                                ((unsafe: classbits__goto_1082_16[i__goto_1350_16]) = (unsafe: classbits__goto_1082_16[i__goto_1350_16]) | (unsafe: cbits__goto_1079_16[(i__goto_1350_16 + 160)]))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (i__goto_1350_16 = i__goto_1350_16 + 1)

                                            }

                                        },
                                        10 => {
                                            (should_flip_negation__goto_1078_6 = 1)

                                            (i__goto_1355_16 = 0)

                                            while ((if i__goto_1355_16 < 32: 1 else: 0) != 0) {
                                                ((unsafe: classbits__goto_1082_16[i__goto_1355_16]) = (unsafe: classbits__goto_1082_16[i__goto_1355_16]) | ((~(unsafe: cbits__goto_1079_16[(i__goto_1355_16 + 160)])) as u8))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (i__goto_1355_16 = i__goto_1355_16 + 1)

                                            }


                                        },
                                        9 => {
                                            (i__goto_1367_16 = 0)

                                            while ((if i__goto_1367_16 < 32: 1 else: 0) != 0) {
                                                ((unsafe: classbits__goto_1082_16[i__goto_1367_16]) = (unsafe: classbits__goto_1082_16[i__goto_1367_16]) | (unsafe: cbits__goto_1079_16[(i__goto_1367_16 + 0)]))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (i__goto_1367_16 = i__goto_1367_16 + 1)

                                            }

                                        },
                                        8 => {
                                            (should_flip_negation__goto_1078_6 = 1)

                                            (i__goto_1372_16 = 0)

                                            while ((if i__goto_1372_16 < 32: 1 else: 0) != 0) {
                                                ((unsafe: classbits__goto_1082_16[i__goto_1372_16]) = (unsafe: classbits__goto_1082_16[i__goto_1372_16]) | ((~(unsafe: cbits__goto_1079_16[(i__goto_1372_16 + 0)])) as u8))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (i__goto_1372_16 = i__goto_1372_16 + 1)

                                            }


                                        },
                                        19 => {
                                            if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                                                break
                                            }

                                            add_list_to_class((options & (~8)), xoptions, cb, (&_pcre2_hspace_list_8[0] as *mut c_uint))

                                        },
                                        18 => {
                                            if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                                                break
                                            }

                                            add_not_list_to_class((options & (~8)), xoptions, cb, (&_pcre2_hspace_list_8[0] as *mut c_uint))

                                        },
                                        21 => {
                                            if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                                                break
                                            }

                                            add_list_to_class((options & (~8)), xoptions, cb, (&_pcre2_vspace_list_8[0] as *mut c_uint))

                                        },
                                        20 => {
                                            if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                                                break
                                            }

                                            add_not_list_to_class((options & (~8)), xoptions, cb, (&_pcre2_vspace_list_8[0] as *mut c_uint))

                                        },
                                        16 => {
                                            (ptype__goto_1437_18 = ((unsafe: *pptr__goto_1076_11) as c_uint) >> (16 as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            var __ci_expr_old_14: *mut c_uint = pptr__goto_1076_11

                                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)

                                            (pdata__goto_1438_18 = (unsafe: *__ci_expr_old_14) & 65535)


                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if ((if ptype__goto_1437_18 == 13: 1 else: 0) != 0) {
                                                var __ci_expr_logic_15: c_int = 0

                                                if ((if not (utf__goto_1085_6 != 0): 1 else: 0) != 0) {
                                                    (__ci_expr_logic_15 = (if (if escape__goto_1179_12 == 16: 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_15 != 0) {
                                                    with_memset((classbits__goto_1082_16 as *i8), 255, (32 as i64))
                                                }


                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                continue

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            _pcre2_update_classbits_8(ptype__goto_1437_18, pdata__goto_1438_18, (if escape__goto_1179_12 == 15: 1 else: 0), classbits__goto_1082_16)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if ((if (xclass_props__goto_1093_10 & 16) == 0: 1 else: 0) != 0) {
                                                if ((if lengthptr != null: 1 else: 0) != 0) {
                                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)
                                                } else {
                                                    var __ci_expr_old_16: *mut u8 = class_uchardata__goto_1094_14

                                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)

                                                    var __ci_expr_ternary_17: c_int = 0

                                                    if ((if escape__goto_1179_12 == 16: 1 else: 0) != 0) {
                                                        (__ci_expr_ternary_17 = 3)
                                                    } else {
                                                        (__ci_expr_ternary_17 = 4)
                                                    }

                                                    ((unsafe: *__ci_expr_old_16) = __ci_expr_ternary_17)


                                                    if (__goto_pending != 0) {
                                                        break
                                                    }

                                                    var __ci_expr_old_18: *mut u8 = class_uchardata__goto_1094_14

                                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)

                                                    ((unsafe: *__ci_expr_old_18) = ptype__goto_1437_18)


                                                    if (__goto_pending != 0) {
                                                        break
                                                    }

                                                    var __ci_expr_old_19: *mut u8 = class_uchardata__goto_1094_14

                                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)

                                                    ((unsafe: *__ci_expr_old_19) = pdata__goto_1438_18)


                                                    if (__goto_pending != 0) {
                                                        break
                                                    }

                                                }

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 5)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }


                                            continue

                                        },
                                    }

                                    break

                                }

                                if (__ci_expr_switch_continue_20 != 0) {
                                    continue
                                }


                                (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)

                                continue

                            },
                            _ => {
                                if ((if meta__goto_1174_12 < 2147483648: 1 else: 0) != 0) {
                                    break
                                }

                                __pc = 1
                                __goto_pending = 1

                            },
                        }
                        break
                    }
                    if (__ci_expr_switch_continue_21 != 0) {
                        continue
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (c__goto_1179_20 = meta__goto_1174_12)
                    if (__goto_pending != 0) {
                        break
                    }
                    var __ci_expr_logic_22: c_int
                    if ((if c__goto_1179_20 == 13: 1 else: 0) != 0) {
                        (__ci_expr_logic_22 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_22 = (if (if c__goto_1179_20 == 10: 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_22 != 0) {
                        (cb.external_flags = cb.external_flags | 2048)
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    var __ci_expr_logic_23: c_int
                    if ((if (unsafe: *pptr__goto_1076_11) == 2149777408: 1 else: 0) != 0) {
                        (__ci_expr_logic_23 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_23 = (if (if (unsafe: *pptr__goto_1076_11) == 2149711872: 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_23 != 0) {
                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                        if (__goto_pending != 0) {
                            break
                        }
                        var __ci_expr_old_24: *mut c_uint = pptr__goto_1076_11
                        (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                        (d__goto_1497_14 = (unsafe: *__ci_expr_old_24))
                        if (__goto_pending != 0) {
                            break
                        }
                        if ((if d__goto_1497_14 == 2147811328: 1 else: 0) != 0) {
                            var __ci_expr_old_25: *mut c_uint = pptr__goto_1076_11
                            (pptr__goto_1076_11 = pptr__goto_1076_11 + 1)
                            (d__goto_1497_14 = (unsafe: *__ci_expr_old_25))
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        var __ci_expr_logic_26: c_int
                        if ((if d__goto_1497_14 == 13: 1 else: 0) != 0) {
                            (__ci_expr_logic_26 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_26 = (if (if d__goto_1497_14 == 10: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_26 != 0) {
                            (cb.external_flags = cb.external_flags | 2048)
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                            continue
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                        if (__goto_pending != 0) {
                            break
                        }
                        add_to_class(options, xoptions, cb, c__goto_1179_20, d__goto_1497_14)
                        if (__goto_pending != 0) {
                            break
                        }
                        continue
                        if (__goto_pending != 0) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                        continue
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 2)
                    if (__goto_pending != 0) {
                        break
                    }
                    add_to_class(options, xoptions, cb, meta__goto_1174_12, meta__goto_1174_12)
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 1
                __goto_pending = 1
                continue
            },
            1 => {  // END_PROCESSING
                (__goto_pending = 0)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if cranges__goto_1095_15 != null: 1 else: 0) != 0) {
                    (range__goto_1581_13 = (((cranges__goto_1095_15 + ((1 as isize) as usize)) as *mut c_uint)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    (end__goto_1582_13 = range__goto_1581_13 + ((cranges__goto_1095_15.range_list_size as isize) as usize))
                    if (__goto_pending != 0) {
                        continue
                    }
                    while true {
                        var __ci_expr_logic_27: c_int = 0
                        if ((if range__goto_1581_13 < end__goto_1582_13: 1 else: 0) != 0) {
                            (__ci_expr_logic_27 = (if (if (unsafe: range__goto_1581_13[0]) < 256: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (not (__ci_expr_logic_27 != 0)) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        var __ci_expr_ternary_28: c_uint = 0
                        if ((if (options & (524288 | 131072)) != 0: 1 else: 0) != 0) {
                            (__ci_expr_ternary_28 = options & (~8))
                        } else {
                            (__ci_expr_ternary_28 = options)
                        }
                        add_to_class(__ci_expr_ternary_28, xoptions, cb, (unsafe: range__goto_1581_13[0]), (unsafe: range__goto_1581_13[1]))
                        if (__goto_pending != 0) {
                            break
                        }
                        if ((if (unsafe: range__goto_1581_13[1]) > 255: 1 else: 0) != 0) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (range__goto_1581_13 = range__goto_1581_13 + 2)
                        if (__goto_pending != 0) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if cranges__goto_1095_15.char_lists_size > 0: 1 else: 0) != 0) {
                        if (__goto_pending != 0) {
                            continue
                        }
                        (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 9)
                        if (__goto_pending != 0) {
                            continue
                        }
                    } else {
                        if ((if (xclass_props__goto_1093_10 & 16) != 0: 1 else: 0) != 0) {
                            if (__goto_pending != 0) {
                                continue
                            }
                            (should_flip_negation__goto_1078_6 = 1)
                            if (__goto_pending != 0) {
                                continue
                            }
                            (range__goto_1581_13 = end__goto_1582_13)
                            if (__goto_pending != 0) {
                                continue
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        while ((if range__goto_1581_13 < end__goto_1582_13: 1 else: 0) != 0) {
                            (range_start__goto_1616_16 = (unsafe: range__goto_1581_13[0]))
                            if (__goto_pending != 0) {
                                break
                            }
                            (range_end__goto_1617_16 = (unsafe: range__goto_1581_13[1]))
                            if (__goto_pending != 0) {
                                break
                            }
                            (range__goto_1581_13 = range__goto_1581_13 + 2)
                            if (__goto_pending != 0) {
                                break
                            }
                            (xclass_props__goto_1093_10 = xclass_props__goto_1093_10 | 1)
                            if (__goto_pending != 0) {
                                break
                            }
                            if ((if range_start__goto_1616_16 < 256: 1 else: 0) != 0) {
                                (range_start__goto_1616_16 = 256)
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            if ((if lengthptr != null: 1 else: 0) != 0) {
                                if (utf__goto_1085_6 != 0) {
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 1)
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                    if ((if range_start__goto_1616_16 < range_end__goto_1617_16: 1 else: 0) != 0) {
                                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + _pcre2_ord2utf_8(range_start__goto_1616_16, class_uchardata__goto_1094_14))
                                    }
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + _pcre2_ord2utf_8(range_end__goto_1617_16, class_uchardata__goto_1094_14))
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                    continue
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                var __ci_expr_ternary_29: c_int = 0
                                if ((if range_start__goto_1616_16 < range_end__goto_1617_16: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_29 = 3)
                                } else {
                                    (__ci_expr_ternary_29 = 2)
                                }
                                ((unsafe: *lengthptr) = (unsafe: *lengthptr) + __ci_expr_ternary_29)
                                if (__goto_pending != 0) {
                                    break
                                }
                                continue
                                if (__goto_pending != 0) {
                                    break
                                }
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            if (utf__goto_1085_6 != 0) {
                                if ((if range_start__goto_1616_16 < range_end__goto_1617_16: 1 else: 0) != 0) {
                                    var __ci_expr_old_30: *mut u8 = class_uchardata__goto_1094_14
                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                    ((unsafe: *__ci_expr_old_30) = 2)
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + _pcre2_ord2utf_8(range_start__goto_1616_16, class_uchardata__goto_1094_14))
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                } else {
                                    var __ci_expr_old_31: *mut u8 = class_uchardata__goto_1094_14
                                    (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                                    ((unsafe: *__ci_expr_old_31) = 1)
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + _pcre2_ord2utf_8(range_end__goto_1617_16, class_uchardata__goto_1094_14))
                                if (__goto_pending != 0) {
                                    break
                                }
                                continue
                                if (__goto_pending != 0) {
                                    break
                                }
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if lengthptr == null: 1 else: 0) != 0) {
                            cb.cx.memctl.free(cranges__goto_1095_15, cb.cx.memctl.memory_data)
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if (xclass_props__goto_1093_10 & 1) != 0: 1 else: 0) != 0) {
                    (previous__goto_1707_16 = code__goto_1077_14)
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if (xclass_props__goto_1093_10 & 8) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_32: *mut u8 = class_uchardata__goto_1094_14
                        (class_uchardata__goto_1094_14 = class_uchardata__goto_1094_14 + 1)
                        ((unsafe: *__ci_expr_old_32) = 0)
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    var __ci_expr_old_33: *mut u8 = code__goto_1077_14
                    (code__goto_1077_14 = code__goto_1077_14 + 1)
                    ((unsafe: *__ci_expr_old_33) = 112)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (code__goto_1077_14 = code__goto_1077_14 + 2)
                    if (__goto_pending != 0) {
                        continue
                    }
                    var __ci_expr_ternary_34: c_int = 0
                    if (negate_class != 0) {
                        (__ci_expr_ternary_34 = 1)
                    } else {
                        (__ci_expr_ternary_34 = 0)
                    }
                    ((unsafe: *code__goto_1077_14) = __ci_expr_ternary_34)
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if (xclass_props__goto_1093_10 & 4) != 0: 1 else: 0) != 0) {
                        ((unsafe: *code__goto_1077_14) = (unsafe: *code__goto_1077_14) | 4)
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    var __ci_expr_logic_35: c_int
                    if ((if (xclass_props__goto_1093_10 & 2) != 0: 1 else: 0) != 0) {
                        (__ci_expr_logic_35 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_35 = (if (if has_bitmap != null: 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_35 != 0) {
                        if (negate_class != 0) {
                            (classwords__goto_1723_17 = ((&cb.classbits.classwords[0] as *mut c_uint)))
                            if (__goto_pending != 0) {
                                continue
                            }
                            (i__goto_1724_16 = 0)
                            while ((if i__goto_1724_16 < 8: 1 else: 0) != 0) {
                                ((unsafe: classwords__goto_1723_17[i__goto_1724_16]) = (~(unsafe: classwords__goto_1723_17[i__goto_1724_16])))
                                if (__goto_pending != 0) {
                                    break
                                }
                                (i__goto_1724_16 = i__goto_1724_16 + 1)
                            }
                            if (__goto_pending != 0) {
                                continue
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if has_bitmap == null: 1 else: 0) != 0) {
                            var __ci_expr_old_36: *mut u8 = code__goto_1077_14
                            (code__goto_1077_14 = code__goto_1077_14 + 1)
                            ((unsafe: *__ci_expr_old_36) = (unsafe: *__ci_expr_old_36) | 2)
                            if (__goto_pending != 0) {
                                continue
                            }
                            with_memmove(((code__goto_1077_14 + (32 / sizeof[u8]())) as *i8), (code__goto_1077_14 as *i8), (((((class_uchardata__goto_1094_14 as usize) -% (code__goto_1077_14 as usize)) / sizeof[u8]()) * 1) as i64))
                            if (__goto_pending != 0) {
                                continue
                            }
                            with_memcpy((code__goto_1077_14 as *i8), (classbits__goto_1082_16 as *i8), (32 as i64))
                            if (__goto_pending != 0) {
                                continue
                            }
                            (code__goto_1077_14 = class_uchardata__goto_1094_14 + (32 / sizeof[u8]()))
                            if (__goto_pending != 0) {
                                continue
                            }
                        } else {
                            (code__goto_1077_14 = class_uchardata__goto_1094_14)
                            if (__goto_pending != 0) {
                                continue
                            }
                            if ((if (xclass_props__goto_1093_10 & 2) != 0: 1 else: 0) != 0) {
                                ((unsafe: *has_bitmap) = 1)
                            }
                            if (__goto_pending != 0) {
                                continue
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                    } else {
                        (code__goto_1077_14 = class_uchardata__goto_1094_14)
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if (xclass_props__goto_1093_10 & 8) != 0: 1 else: 0) != 0) {
                        (char_lists_size__goto_1748_12 = cranges__goto_1095_15.char_lists_size)
                        if (__goto_pending != 0) {
                            continue
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if lengthptr != null: 1 else: 0) != 0) {
                            (char_lists_size__goto_1748_12 = (char_lists_size__goto_1748_12 +% (sizeof[c_uint]() -% 1)) & (~(sizeof[c_uint]() -% 1)))
                            if (__goto_pending != 0) {
                                continue
                            }
                            ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 4)
                            if (__goto_pending != 0) {
                                continue
                            }
                            (cb.char_lists_size = cb.char_lists_size + char_lists_size__goto_1748_12)
                            if (__goto_pending != 0) {
                                continue
                            }
                            (char_lists_size__goto_1748_12 = char_lists_size__goto_1748_12 / sizeof[u8]())
                            if (__goto_pending != 0) {
                                continue
                            }
                            var __ci_expr_logic_37: c_int
                            if ((if (unsafe: *lengthptr) > 65536: 1 else: 0) != 0) {
                                (__ci_expr_logic_37 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_37 = (if (if (65536 -% (unsafe: *lengthptr)) < char_lists_size__goto_1748_12: 1 else: 0) != 0: 1 else: 0))
                            }
                            if (__ci_expr_logic_37 != 0) {
                                ((unsafe: *errorcodeptr) = ERR20)
                                if (__goto_pending != 0) {
                                    continue
                                }
                                return null
                                if (__goto_pending != 0) {
                                    continue
                                }
                            }
                            if (__goto_pending != 0) {
                                continue
                            }
                        } else {
                            if (__goto_pending != 0) {
                                continue
                            }
                            var __ci_expr_ternary_38: c_int = 0
                            if (1 != 0) {
                                (__ci_expr_ternary_38 = 16)
                            } else {
                                (__ci_expr_ternary_38 = 4096)
                            }
                            ((unsafe: code__goto_1077_14[0]) = (((__ci_expr_ternary_38 | ((cranges__goto_1095_15.char_lists_types as c_int) >> (8 as c_uint))) as u8)))
                            if (__goto_pending != 0) {
                                continue
                            }
                            ((unsafe: code__goto_1077_14[1]) = ((cranges__goto_1095_15.char_lists_types as u8)))
                            if (__goto_pending != 0) {
                                continue
                            }
                            (code__goto_1077_14 = code__goto_1077_14 + 2)
                            if (__goto_pending != 0) {
                                continue
                            }
                            (cb.char_lists_size = cb.char_lists_size + char_lists_size__goto_1748_12)
                            if (__goto_pending != 0) {
                                continue
                            }
                            (data__goto_1777_16 = cb.start_code - cb.char_lists_size)
                            if (__goto_pending != 0) {
                                continue
                            }
                            with_memcpy((data__goto_1777_16 as *i8), ((((cranges__goto_1095_15 + ((1 as isize) as usize)) as *mut u8) + cranges__goto_1095_15.char_lists_start) as *i8), (char_lists_size__goto_1748_12 as i64))
                            if (__goto_pending != 0) {
                                continue
                            }
                            (char_lists_size__goto_1748_12 = cb.char_lists_size)
                            if (__goto_pending != 0) {
                                continue
                            }
                            ((unsafe: code__goto_1077_14[0]) = (((((((char_lists_size__goto_1748_12 as c_ulong) >> (1 as c_uint)) as c_uint) as c_uint) >> (8 as c_uint)) as u8)))
                            ((unsafe: code__goto_1077_14[(0 + 1)]) = ((((((char_lists_size__goto_1748_12 as c_ulong) >> (1 as c_uint)) as c_uint) & 255) as u8)))
                            if (__goto_pending != 0) {
                                continue
                            }
                            (code__goto_1077_14 = code__goto_1077_14 + 2)
                            if (__goto_pending != 0) {
                                continue
                            }
                            if ((if (char_lists_size__goto_1748_12 & 2) != 0: 1 else: 0) != 0) {
                                ((unsafe: (data__goto_1777_16 as *mut c_ushort)[-1]) = 57005)
                            }
                            if (__goto_pending != 0) {
                                continue
                            }
                            (cb.char_lists_size = (char_lists_size__goto_1748_12 +% (sizeof[c_uint]() -% 1)) & (~(sizeof[c_uint]() -% 1)))
                            if (__goto_pending != 0) {
                                continue
                            }
                            cb.cx.memctl.free(cranges__goto_1095_15, cb.cx.memctl.memory_data)
                            if (__goto_pending != 0) {
                                continue
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    ((unsafe: previous__goto_1707_16[1]) = ((((((((code__goto_1077_14 as usize) -% (previous__goto_1707_16 as usize)) / sizeof[u8]()) as c_int) as c_int) >> (8 as c_uint)) as u8)))
                    ((unsafe: previous__goto_1707_16[(1 + 1)]) = (((((((code__goto_1077_14 as usize) -% (previous__goto_1707_16 as usize)) / sizeof[u8]()) as c_int) & 255) as u8)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    __pc = 2
                    __goto_pending = 1
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if (negate_class != 0) {
                    (classwords__goto_1840_13 = ((&cb.classbits.classwords[0] as *mut c_uint)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    (i__goto_1842_12 = 0)
                    while ((if i__goto_1842_12 < 8: 1 else: 0) != 0) {
                        ((unsafe: classwords__goto_1840_13[i__goto_1842_12]) = (~(unsafe: classwords__goto_1840_13[i__goto_1842_12])))
                        if (__goto_pending != 0) {
                            break
                        }
                        (i__goto_1842_12 = i__goto_1842_12 + 1)
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_logic_40: c_int = 0
                var __ci_expr_logic_39: c_int
                if ((if not (utf__goto_1085_6 != 0): 1 else: 0) != 0) {
                    (__ci_expr_logic_39 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_39 = (if (if negate_class != should_flip_negation__goto_1078_6: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_39 != 0) {
                    (__ci_expr_logic_40 = (if (if cb.classbits.classwords[0] == (~(0 as c_uint)): 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_40 != 0) {
                    (classwords__goto_1848_19 = ((&cb.classbits.classwords[0] as *const c_uint)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    (i__goto_1849_7 = 0)
                    while ((if i__goto_1849_7 < 8: 1 else: 0) != 0) {
                        if ((if (unsafe: classwords__goto_1848_19[i__goto_1849_7]) != (~(0 as c_uint)): 1 else: 0) != 0) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (i__goto_1849_7 = i__goto_1849_7 + 1)
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if i__goto_1849_7 == 8: 1 else: 0) != 0) {
                        var __ci_expr_old_41: *mut u8 = code__goto_1077_14
                        (code__goto_1077_14 = code__goto_1077_14 + 1)
                        ((unsafe: *__ci_expr_old_41) = 13)
                        if (__goto_pending != 0) {
                            continue
                        }
                        __pc = 2
                        __goto_pending = 1
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_old_42: *mut u8 = code__goto_1077_14
                (code__goto_1077_14 = code__goto_1077_14 + 1)
                var __ci_expr_ternary_43: c_int = 0
                if ((if negate_class == should_flip_negation__goto_1078_6: 1 else: 0) != 0) {
                    (__ci_expr_ternary_43 = OP_CLASS)
                } else {
                    (__ci_expr_ternary_43 = OP_NCLASS)
                }
                ((unsafe: *__ci_expr_old_42) = __ci_expr_ternary_43)
                if (__goto_pending != 0) {
                    continue
                }
                with_memcpy((code__goto_1077_14 as *i8), (classbits__goto_1082_16 as *i8), (32 as i64))
                if (__goto_pending != 0) {
                    continue
                }
                (code__goto_1077_14 = code__goto_1077_14 + (32 / sizeof[u8]()))
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 2
                __goto_pending = 1
                continue
            },
            2 => {  // DONE
                (__goto_pending = 0)
                ((unsafe: *pcode) = code__goto_1077_14)
                if (__goto_pending != 0) {
                    continue
                }
                return (pptr__goto_1076_11 - ((1 as isize) as usize))
                if (__goto_pending != 0) {
                    continue
                }
            },
            _ => {
                break
            },
        }
    }
}

fn _pcre2_compile_class_nested_8(options: c_uint, xoptions: c_uint, pptr: *mut *mut c_uint, pcode: *mut *mut u8, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int {
    var context: eclass_context

    var op_info: eclass_op_info

    var previous_length: c_ulong = with 0 as __ci_expr_seq_11 {
        var __ci_expr_ternary_0: c_ulong = 0
        if ((if lengthptr != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (unsafe: *lengthptr))
        } else {
            (__ci_expr_ternary_0 = 0)
        }
        __ci_expr_ternary_0
    }

    var code: *mut u8 = (unsafe: *pcode)

    var previous: *mut u8

    var allbitsone: c_int = 1

    (context.needs_bitmap = 0)

    (context.options = options)

    (context.xoptions = xoptions)

    (context.errorcodeptr = errorcodeptr)

    (context.cb = cb)

    (previous = code)

    var __ci_expr_old_1: *mut u8 = code

    (code = code + 1)

    ((unsafe: *__ci_expr_old_1) = 113)


    (code = code + 2)

    var __ci_expr_old_2: *mut u8 = code

    (code = code + 1)

    ((unsafe: *__ci_expr_old_2) = 0)


    if ((if not (compile_eclass_nested((&mut context as *mut eclass_context), 0, pptr, (&mut code as *mut *mut u8), (&mut op_info as *mut eclass_op_info), lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    if ((if lengthptr != null: 1 else: 0) != 0) {
        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + (((code as usize) -% (previous as usize)) / sizeof[u8]()))

        (code = previous)

    }

    var i: c_int = 0

    while ((if i < 8: 1 else: 0) != 0) {
        if ((if op_info.bits.classwords[i] != 4294967295: 1 else: 0) != 0) {
            (allbitsone = 0)

            break

        }

        (i = i + 1)

    }


    if ((if op_info.op_single_type != 0: 1 else: 0) != 0) {
        (code = previous)

        var __ci_expr_logic_3: c_int = 0

        if ((if op_info.op_single_type == 6: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if allbitsone != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            if ((if lengthptr != null: 1 else: 0) != 0) {
                ((unsafe: *lengthptr) = (unsafe: *lengthptr) - 1)
            }

            var __ci_expr_old_4: *mut u8 = code

            (code = code + 1)

            ((unsafe: *__ci_expr_old_4) = 13)


        } else {
            var __ci_expr_logic_5: c_int

            if ((if op_info.op_single_type == 6: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if op_info.op_single_type == 7: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                var required_len: c_ulong = (1 +% (32 / sizeof[u8]()))

                if ((if lengthptr != null: 1 else: 0) != 0) {
                    if ((if required_len > ((unsafe: *lengthptr) -% previous_length): 1 else: 0) != 0) {
                        ((unsafe: *lengthptr) = (previous_length +% required_len))
                    }

                }

                if ((if lengthptr != null: 1 else: 0) != 0) {
                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) - required_len)
                }

                var __ci_expr_old_6: *mut u8 = code

                (code = code + 1)

                var __ci_expr_ternary_7: c_int = 0

                if ((if op_info.op_single_type == 6: 1 else: 0) != 0) {
                    (__ci_expr_ternary_7 = OP_NCLASS)
                } else {
                    (__ci_expr_ternary_7 = OP_CLASS)
                }

                ((unsafe: *__ci_expr_old_6) = __ci_expr_ternary_7)


                with_memcpy((code as *i8), ((&op_info.bits.classbits[0] as *mut u8) as *i8), (32 as i64))

                (code = code + (32 / sizeof[u8]()))

            } else {
                var need_map: c_int = context.needs_bitmap

                var required_len_1: c_ulong

                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

                var __ci_expr_ternary_8: c_ulong = 0

                if (need_map != 0) {
                    (__ci_expr_ternary_8 = 32 / sizeof[u8]())
                } else {
                    (__ci_expr_ternary_8 = 0)
                }

                (required_len_1 = (op_info.length +% __ci_expr_ternary_8))


                if ((if lengthptr != null: 1 else: 0) != 0) {
                    if ((if required_len_1 > ((unsafe: *lengthptr) -% previous_length): 1 else: 0) != 0) {
                        ((unsafe: *lengthptr) = (previous_length +% required_len_1))
                    }

                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) - 4)

                    var __ci_expr_old_9: *mut u8 = code

                    (code = code + 1)

                    ((unsafe: *__ci_expr_old_9) = 112)


                    ((unsafe: code[0]) = ((((((1 + 2) + 1) as c_int) >> (8 as c_uint)) as u8)))

                    ((unsafe: code[(0 + 1)]) = (((((1 + 2) + 1) & 255) as u8)))


                    (code = code + 2)

                    var __ci_expr_old_10: *mut u8 = code

                    (code = code + 1)

                    ((unsafe: *__ci_expr_old_10) = 0)


                } else {
                    var rest: *mut u8

                    var rest_len: c_ulong

                    var flags: u8

                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    (rest = ((op_info.code_start + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))

                    (rest_len = (((op_info.code_start + op_info.length) as usize) -% (rest as usize)) / sizeof[u8]())

                    (flags = (unsafe: op_info.code_start[(1 + 2)]))

                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    var __ci_expr_ternary_11: c_ulong = 0

                    if (need_map != 0) {
                        (__ci_expr_ternary_11 = 32 / sizeof[u8]())
                    } else {
                        (__ci_expr_ternary_11 = 0)
                    }

                    with_memmove((((((code + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize)) + __ci_expr_ternary_11) as *i8), (rest as *i8), ((rest_len *% 1) as i64))


                    var __ci_expr_old_12: *mut u8 = code

                    (code = code + 1)

                    ((unsafe: *__ci_expr_old_12) = 112)


                    ((unsafe: code[0]) = (((((required_len_1 as c_int) as c_int) >> (8 as c_uint)) as u8)))

                    ((unsafe: code[(0 + 1)]) = ((((required_len_1 as c_int) & 255) as u8)))


                    (code = code + 2)

                    var __ci_expr_old_13: *mut u8 = code

                    (code = code + 1)

                    var __ci_expr_ternary_14: c_int = 0

                    if (need_map != 0) {
                        (__ci_expr_ternary_14 = 2)
                    } else {
                        (__ci_expr_ternary_14 = 0)
                    }

                    ((unsafe: *__ci_expr_old_13) = flags | __ci_expr_ternary_14)


                    if (need_map != 0) {
                        with_memcpy((code as *i8), ((&op_info.bits.classbits[0] as *mut u8) as *i8), (32 as i64))

                        (code = code + (32 / sizeof[u8]()))

                    }

                    (code = code + rest_len)

                }

            }

        }


    } else {
        var need_map_1: c_int = context.needs_bitmap

        var required_len_2: c_ulong = with 0 as __ci_expr_seq_182 {
            var __ci_expr_ternary_15: c_ulong = 0
            if (need_map_1 != 0) {
                (__ci_expr_ternary_15 = 32 / sizeof[u8]())
            } else {
                (__ci_expr_ternary_15 = 0)
            }
            ((4 +% __ci_expr_ternary_15) +% op_info.length)
        }

        if ((if lengthptr != null: 1 else: 0) != 0) {
            if ((if required_len_2 > ((unsafe: *lengthptr) -% previous_length): 1 else: 0) != 0) {
                ((unsafe: *lengthptr) = (previous_length +% required_len_2))
            }

            ((unsafe: *lengthptr) = (unsafe: *lengthptr) - 4)

            var __ci_expr_old_16: *mut u8 = code

            (code = code + 1)

            ((unsafe: *__ci_expr_old_16) = 113)


            ((unsafe: code[0]) = ((((((1 + 2) + 1) as c_int) >> (8 as c_uint)) as u8)))

            ((unsafe: code[(0 + 1)]) = (((((1 + 2) + 1) & 255) as u8)))


            (code = code + 2)

            var __ci_expr_old_17: *mut u8 = code

            (code = code + 1)

            ((unsafe: *__ci_expr_old_17) = 0)


        } else {
            if (need_map_1 != 0) {
                var map_start: *mut u8 = (((previous + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))

                ((unsafe: previous[(1 + 2)]) = (unsafe: previous[(1 + 2)]) | 1)

                with_memmove(((map_start + (32 / sizeof[u8]())) as *i8), (map_start as *i8), (((((code as usize) -% (map_start as usize)) / sizeof[u8]()) * 1) as i64))

                with_memcpy((map_start as *i8), ((&op_info.bits.classbits[0] as *mut u8) as *i8), (32 as i64))

                (code = code + (32 / sizeof[u8]()))

            }

            ((unsafe: previous[1]) = ((((((((code as usize) -% (previous as usize)) / sizeof[u8]()) as c_int) as c_int) >> (8 as c_uint)) as u8)))

            ((unsafe: previous[(1 + 1)]) = (((((((code as usize) -% (previous as usize)) / sizeof[u8]()) as c_int) & 255) as u8)))


        }

    }

    ((unsafe: *pcode) = code)

    return 1

}

fn do_heapify(buffer: *mut c_uint, size: c_ulong, __param_i: c_ulong) {
    var i = __param_i
    var max: c_ulong

    var left: c_ulong

    var right: c_ulong

    var tmp1: c_uint

    var tmp2: c_uint


    while (1 != 0) {
        (max = i)

        (left = (((i as c_ulong) << (1 as c_uint)) +% 2))

        (right = (left +% 2))

        var __ci_expr_logic_0: c_int = 0

        if ((if left < size: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: buffer[left]) > (unsafe: buffer[max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (max = left)
        }


        var __ci_expr_logic_1: c_int = 0

        if ((if right < size: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: buffer[right]) > (unsafe: buffer[max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (max = right)
        }


        if ((if i == max: 1 else: 0) != 0) {
            return
        }

        (tmp1 = (unsafe: buffer[i]))

        (tmp2 = (unsafe: buffer[(i +% 1)]))

        ((unsafe: buffer[i]) = (unsafe: buffer[max]))

        ((unsafe: buffer[(i +% 1)]) = (unsafe: buffer[(max +% 1)]))

        ((unsafe: buffer[max]) = tmp1)

        ((unsafe: buffer[(max +% 1)]) = tmp2)

        (i = max)

    }

}

fn get_nocase_range(c: c_uint) -> *const c_uint {
    var left: c_uint = 0

    var right: c_uint = _pcre2_ucd_nocase_ranges_size_8

    var middle: c_uint

    if ((if c > 1114111: 1 else: 0) != 0) {
        return ((&_pcre2_ucd_nocase_ranges_8[0] as *const c_uint) + right)
    }

    while (1 != 0) {
        (middle = (((left +% right) as c_uint) >> (1 as c_uint)) | 1)

        if ((if _pcre2_ucd_nocase_ranges_8[middle] <= c: 1 else: 0) != 0) {
            (left = (middle +% 1))
        } else {
            var __ci_expr_logic_0: c_int = 0

            if ((if middle > 1: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if _pcre2_ucd_nocase_ranges_8[(middle -% 2)] > c: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (right = (middle -% 1))
            } else {
                return ((&_pcre2_ucd_nocase_ranges_8[0] as *const c_uint) + (middle -% 1))
            }

        }

    }

}

fn utf_caseless_extend(start: c_uint, end: c_uint, options: c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var buffer = __param_buffer
    var new_start: c_uint = start

    var new_end: c_uint = end

    var c: c_uint = start

    var list: *const c_uint

    var tmp: [3]c_uint

    var result: c_ulong = 2

    var skip_range: *const c_uint = get_nocase_range(c)

    var skip_start: c_uint = (unsafe: skip_range[0])

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    while ((if c <= end: 1 else: 0) != 0) {
        var co: c_uint

        if ((if c > skip_start: 1 else: 0) != 0) {
            (c = (unsafe: skip_range[1]))

            (skip_range = skip_range + 2)

            (skip_start = (unsafe: skip_range[0]))

            continue

        }

        var __ci_expr_logic_1: c_int = 0

        if ((if (options & 12) == 8: 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int

            if ((if (c | 32) == 105: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if (c | 1) == 305: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_1 != 0) {
            var __ci_expr_ternary_3: c_int = 0

            var __ci_expr_logic_2: c_int

            if ((if c == 105: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if c == 304: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_ternary_3 = 0)
            } else {
                (__ci_expr_ternary_3 = 3)
            }

            (co = (_pcre2_ucd_turkish_dotted_i_caseset_8 +% __ci_expr_ternary_3))


        } else {
            var __ci_expr_logic_5: c_int = 0

            var __ci_expr_logic_4: c_int = 0

            (co = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).caseset)

            if ((if co != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if (options & 4) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if (if _pcre2_ucd_caseless_sets_8[co] < 128: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (co = 0)

            }

        }


        if ((if co != 0: 1 else: 0) != 0) {
            (list = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + co)
        } else {
            (co = ((((c as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))

            (list = (&tmp[0] as *const c_uint))

            (tmp[0] = c)

            (tmp[1] = 4294967295)

            if ((if co != c: 1 else: 0) != 0) {
                (tmp[1] = co)

                (tmp[2] = 4294967295)

            }

        }

        (c = c + 1)

        while true {
            if ((if (unsafe: *list) < new_start: 1 else: 0) != 0) {
                if ((if ((unsafe: *list) +% 1) == new_start: 1 else: 0) != 0) {
                    (new_start = new_start - 1)

                    continue

                }

            } else {
                if ((if (unsafe: *list) > new_end: 1 else: 0) != 0) {
                    if ((if ((unsafe: *list) -% 1) == new_end: 1 else: 0) != 0) {
                        (new_end = new_end + 1)

                        continue

                    }

                } else {
                    continue
                }
            }

            (result = result + 2)

            if ((if buffer != null: 1 else: 0) != 0) {
                ((unsafe: buffer[0]) = (unsafe: *list))

                ((unsafe: buffer[1]) = (unsafe: *list))

                (buffer = buffer + 2)

            }

            (list = list + 1)

            if (not ((if (unsafe: *list) != 4294967295: 1 else: 0) != 0)) {
                break
            }

        }

    }

    if ((if buffer != null: 1 else: 0) != 0) {
        ((unsafe: buffer[0]) = new_start)

        ((unsafe: buffer[1]) = new_end)

        (buffer = buffer + 2)

        buffer

    }

    return result

}

fn append_char_list(__param_p: *const c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var p = __param_p
    var buffer = __param_buffer
    var n: *const c_uint

    var result: c_ulong = 0

    while ((if (unsafe: *p) != 4294967295: 1 else: 0) != 0) {
        (n = p)

        while ((if (unsafe: n[0]) == ((unsafe: n[1]) -% 1): 1 else: 0) != 0) {
            (n = n + 1)
        }

        while true {
            if (not (0 != 0)) {
                break
            }
        }

        if ((if buffer != null: 1 else: 0) != 0) {
            ((unsafe: buffer[0]) = (unsafe: *p))

            ((unsafe: buffer[1]) = (unsafe: *n))

            (buffer = buffer + 2)

        }

        (result = result + 2)

        (p = n + ((1 as isize) as usize))

    }

    return result

}

fn get_highest_char(options: c_uint) -> c_uint {
    options

    return 1114111

}

fn append_negated_char_list(__param_p: *const c_uint, options: c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var p = __param_p
    var buffer = __param_buffer
    var n: *const c_uint

    var start: c_uint = 0

    var result: c_ulong = 2

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    while ((if (unsafe: *p) != 4294967295: 1 else: 0) != 0) {
        (n = p)

        while ((if (unsafe: n[0]) == ((unsafe: n[1]) -% 1): 1 else: 0) != 0) {
            (n = n + 1)
        }

        while true {
            if (not (0 != 0)) {
                break
            }
        }

        if ((if buffer != null: 1 else: 0) != 0) {
            ((unsafe: buffer[0]) = start)

            ((unsafe: buffer[1]) = ((unsafe: *p) -% 1))

            (buffer = buffer + 2)

        }

        (result = result + 2)

        (start = ((unsafe: *n) +% 1))

        (p = n + ((1 as isize) as usize))

    }

    if ((if buffer != null: 1 else: 0) != 0) {
        ((unsafe: buffer[0]) = start)

        ((unsafe: buffer[1]) = get_highest_char(options))

        (buffer = buffer + 2)

        buffer

    }

    return result

}

fn append_non_ascii_range(options: c_uint, buffer: *mut c_uint) -> *mut c_uint {
    if ((if buffer == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe: buffer[0]) = 256)

    ((unsafe: buffer[1]) = get_highest_char(options))

    return (buffer + ((2 as isize) as usize))

}

fn parse_class(__param_ptr: *mut c_uint, options: c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var ptr = __param_ptr
    var buffer = __param_buffer
    var total_size: c_ulong = 0

    var size: c_ulong

    var meta_arg: c_uint

    var start_char: c_uint

    while (1 != 0) {
        var __ci_expr_switch_continue_2: i32 = 0

        while true {
            match ((unsafe: *ptr) & (4294901760 as c_uint)) {
                2149318656 => {
                    (meta_arg = (unsafe: *ptr) & 65535)

                    while true {
                        match meta_arg {
                            6 => {
                                (buffer = append_non_ascii_range(options, buffer))

                                (total_size = total_size + 2)

                            },
                            10 => {
                                (buffer = append_non_ascii_range(options, buffer))

                                (total_size = total_size + 2)

                            },
                            8 => {
                                (buffer = append_non_ascii_range(options, buffer))

                                (total_size = total_size + 2)

                            },
                            19 => {
                                (size = append_char_list((&_pcre2_hspace_list_8[0] as *mut c_uint), buffer))

                                (total_size = total_size + size)

                                if ((if buffer != null: 1 else: 0) != 0) {
                                    (buffer = buffer + size)
                                }

                            },
                            18 => {
                                (size = append_negated_char_list((&_pcre2_hspace_list_8[0] as *mut c_uint), options, buffer))

                                (total_size = total_size + size)

                                if ((if buffer != null: 1 else: 0) != 0) {
                                    (buffer = buffer + size)
                                }

                            },
                            21 => {
                                (size = append_char_list((&_pcre2_vspace_list_8[0] as *mut c_uint), buffer))

                                (total_size = total_size + size)

                                if ((if buffer != null: 1 else: 0) != 0) {
                                    (buffer = buffer + size)
                                }

                            },
                            20 => {
                                (size = append_negated_char_list((&_pcre2_vspace_list_8[0] as *mut c_uint), options, buffer))

                                (total_size = total_size + size)

                                if ((if buffer != null: 1 else: 0) != 0) {
                                    (buffer = buffer + size)
                                }

                            },
                            16 => {
                                (ptr = ptr + 1)

                                var __ci_expr_logic_0: c_int = 0

                                if ((if meta_arg == 16: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (((unsafe: *ptr) as c_uint) >> (16 as c_uint)) == 13: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    if ((if buffer != null: 1 else: 0) != 0) {
                                        ((unsafe: buffer[0]) = 0)

                                        ((unsafe: buffer[1]) = get_highest_char(options))

                                        (buffer = buffer + 2)

                                    }

                                    (total_size = total_size + 2)

                                }


                            },
                            15 => {
                                (ptr = ptr + 1)

                                var __ci_expr_logic_0: c_int = 0

                                if ((if meta_arg == 16: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (((unsafe: *ptr) as c_uint) >> (16 as c_uint)) == 13: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    if ((if buffer != null: 1 else: 0) != 0) {
                                        ((unsafe: buffer[0]) = 0)

                                        ((unsafe: buffer[1]) = get_highest_char(options))

                                        (buffer = buffer + 2)

                                    }

                                    (total_size = total_size + 2)

                                }


                            },
                        }

                        break

                    }

                    (ptr = ptr + 1)

                    continue

                },
                2149646336 => {
                    (buffer = append_non_ascii_range(options, buffer))

                    (total_size = total_size + 2)

                    (ptr = ptr + 2)

                    continue

                },
                2149580800 => {
                    (ptr = ptr + 2)

                    continue

                },
                2147811328 => {
                    (ptr = ptr + 1)
                },
                _ => {
                    if ((if (unsafe: *ptr) >= 2147483648: 1 else: 0) != 0) {
                        return total_size
                    }
                },
            }

            break

        }

        if (__ci_expr_switch_continue_2 != 0) {
            continue
        }


        (start_char = (unsafe: *ptr))

        var __ci_expr_logic_3: c_int

        if ((if (unsafe: ptr[1]) == 2149777408: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if (unsafe: ptr[1]) == 2149711872: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (ptr = ptr + 2)

            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            if ((if (unsafe: *ptr) == 2147811328: 1 else: 0) != 0) {
                (ptr = ptr + 1)
            }

        }


        if ((options & 2) != 0) {
            var __ci_expr_old_4: *mut c_uint = ptr

            (ptr = ptr + 1)

            (size = utf_caseless_extend(start_char, (unsafe: *__ci_expr_old_4), options, buffer))


            if ((if buffer != null: 1 else: 0) != 0) {
                (buffer = buffer + size)
            }

            (total_size = total_size + size)

            continue

        }

        if ((if buffer != null: 1 else: 0) != 0) {
            ((unsafe: buffer[0]) = start_char)

            ((unsafe: buffer[1]) = (unsafe: *ptr))

            (buffer = buffer + 2)

        }

        (ptr = ptr + 1)

        (total_size = total_size + 2)

    }

    return total_size

}

fn compile_optimize_class(start_ptr: *mut c_uint, options: c_uint, xoptions: c_uint, cb: *mut compile_block_8) -> *mut class_ranges {
    var cranges: *mut class_ranges

    var ptr: *mut c_uint

    var buffer: *mut c_uint

    var dst: *mut c_uint

    var class_options: c_uint = 0

    var range_list_size: c_ulong = 0

    var total_size: c_ulong

    var i: c_ulong


    var tmp1: c_uint

    var tmp2: c_uint


    var char_list_next: *const c_uint

    var next_char: *mut c_ushort

    var char_list_start: c_uint

    var char_list_end: c_uint


    var range_start: c_uint

    var range_end: c_uint


    if ((options & 524288) != 0) {
        (class_options = class_options | 1)
    }

    var __ci_expr_logic_0: c_int = 0

    if ((options & 8) != 0) {
        (__ci_expr_logic_0 = (if (options & (524288 | 131072)) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (class_options = class_options | 2)
    }


    if ((xoptions & 128) != 0) {
        (class_options = class_options | 4)
    }

    if ((xoptions & 65536) != 0) {
        (class_options = class_options | 8)
    }

    (range_list_size = parse_class(start_ptr, class_options, null))

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    var __ci_expr_ternary_1: c_int = 0

    if ((if range_list_size >= 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = 3)
    } else {
        (__ci_expr_ternary_1 = 0)
    }

    (total_size = (range_list_size +% __ci_expr_ternary_1))


    (cranges = ((cb.cx.memctl.malloc((sizeof[class_ranges]() +% (total_size *% sizeof[c_uint]())), cb.cx.memctl.memory_data) as *mut class_ranges)))

    if ((if cranges == null: 1 else: 0) != 0) {
        return null
    }

    (cranges.header.next = ((null as *mut compile_data)))

    (cranges.range_list_size = ((range_list_size as c_ushort)))

    (cranges.char_lists_types = 0)

    (cranges.char_lists_size = 0)

    (cranges.char_lists_start = 0)

    if ((if range_list_size == 0: 1 else: 0) != 0) {
        return cranges
    }

    (buffer = (((cranges + ((1 as isize) as usize)) as *mut c_uint)))

    parse_class(start_ptr, class_options, buffer)

    if ((if range_list_size <= 2: 1 else: 0) != 0) {
        return cranges
    }

    (i = ((((range_list_size as c_ulong) >> (2 as c_uint)) -% 1) as c_ulong) << (1 as c_uint))

    while (1 != 0) {
        do_heapify(buffer, range_list_size, i)

        if ((if i == 0: 1 else: 0) != 0) {
            break
        }

        (i = i - 2)

    }

    (i = (range_list_size -% 2))

    while (1 != 0) {
        (tmp1 = (unsafe: buffer[i]))

        (tmp2 = (unsafe: buffer[(i +% 1)]))

        ((unsafe: buffer[i]) = (unsafe: buffer[0]))

        ((unsafe: buffer[(i +% 1)]) = (unsafe: buffer[1]))

        ((unsafe: buffer[0]) = tmp1)

        ((unsafe: buffer[1]) = tmp2)

        do_heapify(buffer, i, 0)

        if ((if i == 0: 1 else: 0) != 0) {
            break
        }

        (i = i - 2)

    }

    (dst = buffer)

    (ptr = buffer + ((2 as isize) as usize))

    (range_list_size = range_list_size - 2)

    while true {
        var __ci_expr_logic_2: c_int = 0

        if ((if range_list_size > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (unsafe: dst[1]) != (~(0 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_2 != 0)) {
            break
        }

        if ((if ((unsafe: dst[1]) +% 1) < (unsafe: ptr[0]): 1 else: 0) != 0) {
            (dst = dst + 2)

            ((unsafe: dst[0]) = (unsafe: ptr[0]))

            ((unsafe: dst[1]) = (unsafe: ptr[1]))

        } else {
            if ((if (unsafe: dst[1]) < (unsafe: ptr[1]): 1 else: 0) != 0) {
                ((unsafe: dst[1]) = (unsafe: ptr[1]))
            }
        }

        (ptr = ptr + 2)

        (range_list_size = range_list_size - 2)

    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (ptr = buffer)

    while true {
        var __ci_expr_logic_3: c_int = 0

        if ((if ptr < dst: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if (unsafe: ptr[1]) < 256: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_3 != 0)) {
            break
        }

        (ptr = ptr + 2)

    }

    if ((if (((dst as usize) -% (ptr as usize)) / sizeof[c_uint]()) < 10: 1 else: 0) != 0) {
        (cranges.range_list_size = ((((((dst + ((2 as isize) as usize)) as usize) -% (buffer as usize)) / sizeof[c_uint]()) as c_ushort)))

        return cranges

    }

    (char_list_next = (&char_list_starts[0] as *const c_uint))

    var __ci_expr_old_4: *const c_uint = char_list_next

    (char_list_next = char_list_next + 1)

    (char_list_start = (unsafe: *__ci_expr_old_4))


    (char_list_end = 2147483647)

    (next_char = (((buffer + total_size) as *mut c_ushort)))

    (tmp1 = 0)

    (tmp2 = 6)

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (range_start = (unsafe: dst[0]))

    (range_end = (unsafe: dst[1]))

    while (1 != 0) {
        if ((if range_start >= char_list_start: 1 else: 0) != 0) {
            var __ci_expr_logic_5: c_int

            if ((if range_start == range_end: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if range_end < char_list_end: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (tmp1 = tmp1 + 1)

                (next_char = next_char - 1)

                if ((if char_list_start < 65536: 1 else: 0) != 0) {
                    ((unsafe: *next_char) = (((((range_end as c_uint) << (1 as c_uint)) | 1) as c_ushort)))
                } else {
                    (next_char = next_char - 1)

                    ((unsafe: *(next_char as *mut c_uint)) = ((range_end as c_uint) << (1 as c_uint)) | 1)

                }

            }


            if ((if range_start < range_end: 1 else: 0) != 0) {
                if ((if range_start > char_list_start: 1 else: 0) != 0) {
                    (tmp1 = tmp1 + 1)

                    (next_char = next_char - 1)

                    if ((if char_list_start < 65536: 1 else: 0) != 0) {
                        ((unsafe: *next_char) = ((((range_start as c_uint) << (1 as c_uint)) as c_ushort)))
                    } else {
                        (next_char = next_char - 1)

                        ((unsafe: *(next_char as *mut c_uint)) = (range_start as c_uint) << (1 as c_uint))

                    }

                } else {
                    (cranges.char_lists_types = cranges.char_lists_types | ((4 as c_int) << (tmp2 as c_uint)))
                }

            }

            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            if ((if dst > buffer: 1 else: 0) != 0) {
                (dst = dst - 2)

                (range_start = (unsafe: dst[0]))

                (range_end = (unsafe: dst[1]))

                continue

            }

            (range_start = 0)

            (range_end = 0)

        }

        if ((if range_end >= char_list_start: 1 else: 0) != 0) {
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            if ((if range_end < char_list_end: 1 else: 0) != 0) {
                (tmp1 = tmp1 + 1)

                (next_char = next_char - 1)

                if ((if char_list_start < 65536: 1 else: 0) != 0) {
                    ((unsafe: *next_char) = (((((range_end as c_uint) << (1 as c_uint)) | 1) as c_ushort)))
                } else {
                    (next_char = next_char - 1)

                    ((unsafe: *(next_char as *mut c_uint)) = ((range_end as c_uint) << (1 as c_uint)) | 1)

                }

                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }

            }

            (cranges.char_lists_types = cranges.char_lists_types | ((4 as c_int) << (tmp2 as c_uint)))

        }

        if ((if tmp1 >= 3: 1 else: 0) != 0) {
            (cranges.char_lists_types = cranges.char_lists_types | ((3 as c_int) << (tmp2 as c_uint)))

            (next_char = next_char - 1)

            if ((if char_list_start < 65536: 1 else: 0) != 0) {
                ((unsafe: *next_char) = ((tmp1 as c_ushort)))
            } else {
                (next_char = next_char - 1)

                ((unsafe: *(next_char as *mut c_uint)) = tmp1)

            }

        } else {
            (cranges.char_lists_types = cranges.char_lists_types | ((tmp1 as c_uint) << (tmp2 as c_uint)))
        }

        var __ci_expr_logic_6: c_int

        if ((if range_end < 256: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if tmp2 == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            break

        }


        while true {
            if (not (0 != 0)) {
                break
            }
        }

        (char_list_end = (char_list_start -% 1))

        var __ci_expr_old_7: *const c_uint = char_list_next

        (char_list_next = char_list_next + 1)

        (char_list_start = (unsafe: *__ci_expr_old_7))


        (tmp1 = 0)

        (tmp2 = tmp2 - 3)

    }

    if ((if (unsafe: dst[0]) < 256: 1 else: 0) != 0) {
        (dst = dst + 2)
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (cranges.char_lists_size = (((((((buffer + total_size) as *mut u8) as usize) -% ((next_char as *mut u8) as usize)) / sizeof[u8]()) as c_ulong)))

    (cranges.char_lists_start = ((((((next_char as *mut u8) as usize) -% ((buffer as *mut u8) as usize)) / sizeof[u8]()) as c_ulong)))

    (cranges.range_list_size = (((((dst as usize) -% (buffer as usize)) / sizeof[c_uint]()) as c_ushort)))

    return cranges

}

fn add_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, start: c_uint, end: c_uint) {
    var classbits: *mut u8 = ((&cb.classbits.classbits[0] as *mut u8))

    var c: c_uint

    var byte_start: c_uint

    var byte_end: c_uint


    var classbits_end: c_uint = with 0 as __ci_expr_seq_14 {
        var __ci_expr_ternary_0: c_uint = 0
        if ((if end <= 255: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = end)
        } else {
            (__ci_expr_ternary_0 = 255)
        }
        __ci_expr_ternary_0
    }

    if ((if (options & 8) != 0: 1 else: 0) != 0) {
        if ((if (options & (524288 | 131072)) != 0: 1 else: 0) != 0) {
            var turkish_i: c_int = (if (xoptions & (65536 | 128)) == 65536: 1 else: 0)

            if ((if start < 128: 1 else: 0) != 0) {
                var lo_end: c_uint = with 0 as __ci_expr_seq_24 {
                    var __ci_expr_ternary_1: c_uint = 0
                    if ((if classbits_end < 127: 1 else: 0) != 0) {
                        (__ci_expr_ternary_1 = classbits_end)
                    } else {
                        (__ci_expr_ternary_1 = 127)
                    }
                    __ci_expr_ternary_1
                }

                (c = start)

                while ((if c <= lo_end: 1 else: 0) != 0) {
                    var __ci_expr_logic_3: c_int = 0

                    if (turkish_i != 0) {
                        var __ci_expr_logic_2: c_int

                        if ((if (c | 32) == 105: 1 else: 0) != 0) {
                            (__ci_expr_logic_2 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_2 = (if (if (c | 1) == 305: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_3 != 0) {
                        (c = c + 1)

                        continue

                    }


                    ((unsafe: classbits[(((unsafe: cb.fcc[c]) as c_int) >> (3 as c_uint))]) = (unsafe: classbits[(((unsafe: cb.fcc[c]) as c_int) >> (3 as c_uint))]) | (((1 as c_uint) << (((unsafe: cb.fcc[c]) & 7) as c_uint)) as u8))


                    (c = c + 1)

                }


            }

            if ((if classbits_end >= 128: 1 else: 0) != 0) {
                var hi_start: c_uint = with 0 as __ci_expr_seq_63 {
                    var __ci_expr_ternary_4: c_uint = 0
                    if ((if start > 128: 1 else: 0) != 0) {
                        (__ci_expr_ternary_4 = start)
                    } else {
                        (__ci_expr_ternary_4 = 128)
                    }
                    __ci_expr_ternary_4
                }

                (c = hi_start)

                while ((if c <= classbits_end: 1 else: 0) != 0) {
                    var co: c_uint = ((((c as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).other_case) as c_uint))

                    if ((if co <= 255: 1 else: 0) != 0) {
                        ((unsafe: classbits[((co as c_uint) >> (3 as c_uint))]) = (unsafe: classbits[((co as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << ((co & 7) as c_uint)) as u8))
                    }


                    (c = c + 1)

                }


            }

        } else {
            (c = start)

            while ((if c <= classbits_end: 1 else: 0) != 0) {
                ((unsafe: classbits[(((unsafe: cb.fcc[c]) as c_int) >> (3 as c_uint))]) = (unsafe: classbits[(((unsafe: cb.fcc[c]) as c_int) >> (3 as c_uint))]) | (((1 as c_uint) << (((unsafe: cb.fcc[c]) & 7) as c_uint)) as u8))

                (c = c + 1)

            }


        }

    }

    (byte_start = ((start +% 7) as c_uint) >> (3 as c_uint))

    (byte_end = ((classbits_end +% 1) as c_uint) >> (3 as c_uint))

    if ((if byte_start >= byte_end: 1 else: 0) != 0) {
        (c = start)

        while ((if c <= classbits_end: 1 else: 0) != 0) {
            ((unsafe: classbits[((c as c_uint) >> (3 as c_uint))]) = (unsafe: classbits[((c as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << ((c & 7) as c_uint)) as u8))

            (c = c + 1)

        }


        return

    }

    (c = byte_start)

    while ((if c < byte_end: 1 else: 0) != 0) {
        ((unsafe: classbits[c]) = 255)

        (c = c + 1)

    }


    (byte_start = byte_start << (3 as c_uint))

    (byte_end = byte_end << (3 as c_uint))

    (c = start)

    while ((if c < byte_start: 1 else: 0) != 0) {
        ((unsafe: classbits[((c as c_uint) >> (3 as c_uint))]) = (unsafe: classbits[((c as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << ((c & 7) as c_uint)) as u8))

        (c = c + 1)

    }


    (c = byte_end)

    while ((if c <= classbits_end: 1 else: 0) != 0) {
        ((unsafe: classbits[((c as c_uint) >> (3 as c_uint))]) = (unsafe: classbits[((c as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << ((c & 7) as c_uint)) as u8))

        (c = c + 1)

    }


}

fn add_list_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, __param_p: *const c_uint) {
    var p = __param_p
    while ((if (unsafe: p[0]) < 256: 1 else: 0) != 0) {
        var n: c_uint = 0

        while ((if (unsafe: p[(n +% 1)]) == (((unsafe: p[0]) +% n) +% 1): 1 else: 0) != 0) {
            (n = n + 1)
        }

        add_to_class(options, xoptions, cb, (unsafe: p[0]), (unsafe: p[n]))

        (p = p + (n +% 1))

    }

}

fn add_not_list_to_class(options: c_uint, xoptions: c_uint, cb: *mut compile_block_8, __param_p: *const c_uint) {
    var p = __param_p
    if ((if (unsafe: p[0]) > 0: 1 else: 0) != 0) {
        add_to_class(options, xoptions, cb, 0, ((unsafe: p[0]) -% 1))
    }

    while ((if (unsafe: p[0]) < 256: 1 else: 0) != 0) {
        while ((if (unsafe: p[1]) == ((unsafe: p[0]) +% 1): 1 else: 0) != 0) {
            (p = p + 1)
        }

        var __ci_expr_ternary_0: c_uint = 0

        if ((if (unsafe: p[1]) > 255: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = 255)
        } else {
            (__ci_expr_ternary_0 = ((unsafe: p[1]) -% 1))
        }

        add_to_class(options, xoptions, cb, ((unsafe: p[0]) +% 1), __ci_expr_ternary_0)


        (p = p + 1)

    }

}

fn fold_negation(pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong, preserve_classbits: c_int) {
    if ((if pop_info.op_single_type == 0: 1 else: 0) != 0) {
        if ((if lengthptr != null: 1 else: 0) != 0) {
            ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 1)
        } else {
            ((unsafe: pop_info.code_start[pop_info.length]) = 4)
        }

        (pop_info.length = pop_info.length + 1)

    } else {
        var __ci_expr_logic_0: c_int

        if ((if pop_info.op_single_type == 6: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if pop_info.op_single_type == 7: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            var __ci_expr_ternary_1: c_int = 0

            if ((if pop_info.op_single_type == 7: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = 6)
            } else {
                (__ci_expr_ternary_1 = 7)
            }

            (pop_info.op_single_type = __ci_expr_ternary_1)


            if ((if lengthptr == null: 1 else: 0) != 0) {
                ((unsafe: *pop_info.code_start) = pop_info.op_single_type)
            }

        } else {
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            if ((if lengthptr == null: 1 else: 0) != 0) {
                ((unsafe: pop_info.code_start[(1 + 2)]) = (unsafe: pop_info.code_start[(1 + 2)]) ^ 1)
            }

        }

    }

    if ((if not (preserve_classbits != 0): 1 else: 0) != 0) {
        var i: c_int = 0

        while ((if i < 8: 1 else: 0) != 0) {
            (pop_info.bits.classwords[i] = (~pop_info.bits.classwords[i]))

            (i = i + 1)

        }


    }

}

fn fold_binary(op: c_int, lhs_op_info: *mut eclass_op_info, rhs_op_info: *mut eclass_op_info, lengthptr: *mut c_ulong) {
    while true {
        match op {
            1 => {
                if (not ((if rhs_op_info.op_single_type == 6: 1 else: 0) != 0)) {
                    if ((if lhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                        if ((if lengthptr == null: 1 else: 0) != 0) {
                            with_memmove((lhs_op_info.code_start as *i8), (rhs_op_info.code_start as *i8), ((rhs_op_info.length *% 1) as i64))
                        }

                        (lhs_op_info.length = rhs_op_info.length)

                        (lhs_op_info.op_single_type = rhs_op_info.op_single_type)

                    } else {
                        if ((if rhs_op_info.op_single_type == 7: 1 else: 0) != 0) {
                            if ((if lengthptr == null: 1 else: 0) != 0) {
                                ((unsafe: lhs_op_info.code_start[0]) = 7)
                            }

                            (lhs_op_info.length = 1)

                            (lhs_op_info.op_single_type = 7)

                        } else {
                            if (not ((if lhs_op_info.op_single_type == 7: 1 else: 0) != 0)) {
                                if ((if lengthptr != null: 1 else: 0) != 0) {
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 1)
                                } else {
                                    while true {
                                        if (not (0 != 0)) {
                                            break
                                        }
                                    }

                                    ((unsafe: rhs_op_info.code_start[rhs_op_info.length]) = 1)

                                }

                                (lhs_op_info.length = lhs_op_info.length + (rhs_op_info.length +% 1))

                                (lhs_op_info.op_single_type = 0)

                            }
                        }
                    }
                }

                var i: c_int = 0

                while ((if i < 8: 1 else: 0) != 0) {
                    (lhs_op_info.bits.classwords[i] = lhs_op_info.bits.classwords[i] & rhs_op_info.bits.classwords[i])

                    (i = i + 1)

                }


            },
            2 => {
                if (not ((if rhs_op_info.op_single_type == 7: 1 else: 0) != 0)) {
                    if ((if lhs_op_info.op_single_type == 7: 1 else: 0) != 0) {
                        if ((if lengthptr == null: 1 else: 0) != 0) {
                            with_memmove((lhs_op_info.code_start as *i8), (rhs_op_info.code_start as *i8), ((rhs_op_info.length *% 1) as i64))
                        }

                        (lhs_op_info.length = rhs_op_info.length)

                        (lhs_op_info.op_single_type = rhs_op_info.op_single_type)

                    } else {
                        if ((if rhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                            if ((if lengthptr == null: 1 else: 0) != 0) {
                                ((unsafe: lhs_op_info.code_start[0]) = 6)
                            }

                            (lhs_op_info.length = 1)

                            (lhs_op_info.op_single_type = 6)

                        } else {
                            if (not ((if lhs_op_info.op_single_type == 6: 1 else: 0) != 0)) {
                                if ((if lengthptr != null: 1 else: 0) != 0) {
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 1)
                                } else {
                                    while true {
                                        if (not (0 != 0)) {
                                            break
                                        }
                                    }

                                    ((unsafe: rhs_op_info.code_start[rhs_op_info.length]) = 2)

                                }

                                (lhs_op_info.length = lhs_op_info.length + (rhs_op_info.length +% 1))

                                (lhs_op_info.op_single_type = 0)

                            }
                        }
                    }
                }

                var i_1: c_int = 0

                while ((if i_1 < 8: 1 else: 0) != 0) {
                    (lhs_op_info.bits.classwords[i_1] = lhs_op_info.bits.classwords[i_1] | rhs_op_info.bits.classwords[i_1])

                    (i_1 = i_1 + 1)

                }


            },
            3 => {
                if (not ((if rhs_op_info.op_single_type == 7: 1 else: 0) != 0)) {
                    if ((if lhs_op_info.op_single_type == 7: 1 else: 0) != 0) {
                        if ((if lengthptr == null: 1 else: 0) != 0) {
                            with_memmove((lhs_op_info.code_start as *i8), (rhs_op_info.code_start as *i8), ((rhs_op_info.length *% 1) as i64))
                        }

                        (lhs_op_info.length = rhs_op_info.length)

                        (lhs_op_info.op_single_type = rhs_op_info.op_single_type)

                    } else {
                        if ((if rhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                            fold_negation(lhs_op_info, lengthptr, 1)

                        } else {
                            if ((if lhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                                if ((if lengthptr == null: 1 else: 0) != 0) {
                                    with_memmove((lhs_op_info.code_start as *i8), (rhs_op_info.code_start as *i8), ((rhs_op_info.length *% 1) as i64))
                                }

                                (lhs_op_info.length = rhs_op_info.length)

                                (lhs_op_info.op_single_type = rhs_op_info.op_single_type)

                                fold_negation(lhs_op_info, lengthptr, 1)

                            } else {
                                if ((if lengthptr != null: 1 else: 0) != 0) {
                                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 1)
                                } else {
                                    while true {
                                        if (not (0 != 0)) {
                                            break
                                        }
                                    }

                                    ((unsafe: rhs_op_info.code_start[rhs_op_info.length]) = 3)

                                }

                                (lhs_op_info.length = lhs_op_info.length + (rhs_op_info.length +% 1))

                                (lhs_op_info.op_single_type = 0)

                            }
                        }
                    }
                }

                var i_2: c_int = 0

                while ((if i_2 < 8: 1 else: 0) != 0) {
                    (lhs_op_info.bits.classwords[i_2] = lhs_op_info.bits.classwords[i_2] ^ rhs_op_info.bits.classwords[i_2])

                    (i_2 = i_2 + 1)

                }


            },
            _ => {
                while true {
                    if (not (0 != 0)) {
                        break
                    }
                }
            },
        }

        break

    }

}

fn compile_eclass_nested(context: *mut eclass_context, __param_negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int {
    var negated = __param_negated
    var ptr: *mut c_uint = (unsafe: *pptr)

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    var __ci_expr_old_0: *mut c_uint = ptr

    (ptr = ptr + 1)

    if ((if (unsafe: *__ci_expr_old_0) == ((2148401152 as c_uint) | 1): 1 else: 0) != 0) {
        (negated = (if not (negated != 0): 1 else: 0))
    }


    ((unsafe: *pptr) = (unsafe: *pptr) + 1)

    if ((if not (compile_class_binary_loose(context, negated, pptr, pcode, pop_info, lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    return 1

}

fn compile_class_operand(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int {
    var ptr__goto_2135_11: *mut c_uint = null
    var prev_ptr__goto_2136_11: *mut c_uint = null
    var code__goto_2137_14: *mut u8 = null
    var code_start__goto_2138_14: *mut u8 = null
    var prev_length__goto_2139_12: c_ulong = 0
    var extra_length__goto_2140_12: c_ulong = 0
    var meta__goto_2141_10: c_uint = 0
    var classwords__goto_2242_17: *mut c_uint = null
    var i__goto_2244_16: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc {
            0 => {
                (__goto_pending = 0)
                (ptr__goto_2135_11 = (unsafe: *pptr))
                (code__goto_2137_14 = (unsafe: *pcode))
                (code_start__goto_2138_14 = code__goto_2137_14)
                var __ci_expr_ternary_0: c_ulong = 0
                if ((if lengthptr != null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_0 = (unsafe: *lengthptr))
                } else {
                    (__ci_expr_ternary_0 = 0)
                }
                (prev_length__goto_2139_12 = __ci_expr_ternary_0)
                (meta__goto_2141_10 = (unsafe: *ptr__goto_2135_11) & (4294901760 as c_uint))
                while true {
                    match meta__goto_2141_10 {
                        2148270080 => {
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                            (pop_info.length = 1)

                            if ((if (if meta__goto_2141_10 == 2148204544: 1 else: 0) == negated: 1 else: 0) != 0) {
                                var __ci_expr_old_1: *mut u8 = code__goto_2137_14

                                (code__goto_2137_14 = code__goto_2137_14 + 1)

                                (pop_info.op_single_type = 6)

                                ((unsafe: *__ci_expr_old_1) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 255, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            } else {
                                var __ci_expr_old_2: *mut u8 = code__goto_2137_14

                                (code__goto_2137_14 = code__goto_2137_14 + 1)

                                (pop_info.op_single_type = 7)

                                ((unsafe: *__ci_expr_old_2) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 0, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                        },
                        2148204544 => {
                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                            (pop_info.length = 1)

                            if ((if (if meta__goto_2141_10 == 2148204544: 1 else: 0) == negated: 1 else: 0) != 0) {
                                var __ci_expr_old_1: *mut u8 = code__goto_2137_14

                                (code__goto_2137_14 = code__goto_2137_14 + 1)

                                (pop_info.op_single_type = 6)

                                ((unsafe: *__ci_expr_old_1) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 255, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            } else {
                                var __ci_expr_old_2: *mut u8 = code__goto_2137_14

                                (code__goto_2137_14 = code__goto_2137_14 + 1)

                                (pop_info.op_single_type = 7)

                                ((unsafe: *__ci_expr_old_2) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 0, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                        },
                        2148139008 => {
                            if ((if ((unsafe: *ptr__goto_2135_11) & 1) != 0: 1 else: 0) != 0) {
                                if ((if not (compile_eclass_nested(context, negated, (&mut ptr__goto_2135_11 as *mut *mut c_uint), (&mut code__goto_2137_14 as *mut *mut u8), pop_info, lengthptr) != 0): 1 else: 0) != 0) {
                                    return 0
                                }

                                if (__goto_pending != 0) {
                                    break
                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                                (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                __pc = 1
                                __goto_pending = 1

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                            (prev_ptr__goto_2136_11 = ptr__goto_2135_11)

                            (ptr__goto_2135_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2135_11, (&mut code__goto_2137_14 as *mut *mut u8), (if (if meta__goto_2141_10 != 2148401152: 1 else: 0) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))

                            if ((if ptr__goto_2135_11 == null: 1 else: 0) != 0) {
                                return 0
                            }

                            if ((if ptr__goto_2135_11 <= prev_ptr__goto_2136_11: 1 else: 0) != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                return 0

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            var __ci_expr_logic_3: c_int

                            if ((if meta__goto_2141_10 == 2148139008: 1 else: 0) != 0) {
                                (__ci_expr_logic_3 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_3 = (if (if meta__goto_2141_10 == 2148401152: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_3 != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                            }



                            var __ci_expr_ternary_4: c_ulong = 0

                            if ((if lengthptr != null: 1 else: 0) != 0) {
                                (__ci_expr_ternary_4 = ((unsafe: *lengthptr) -% prev_length__goto_2139_12))
                            } else {
                                (__ci_expr_ternary_4 = 0)
                            }

                            (extra_length__goto_2140_12 = __ci_expr_ternary_4)


                            if ((if (unsafe: *code_start__goto_2138_14) == OP_ALLANY: 1 else: 0) != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                (pop_info.length = 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (pop_info.op_single_type = 6)

                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 255, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            } else {
                                var __ci_expr_logic_5: c_int

                                if ((if (unsafe: *code_start__goto_2138_14) == OP_CLASS: 1 else: 0) != 0) {
                                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_5 = (if (if (unsafe: *code_start__goto_2138_14) == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_5 != 0) {

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.length = 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_ternary_6: c_int = 0

                                    if ((if (unsafe: *code_start__goto_2138_14) == OP_CLASS: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_6 = 7)
                                    } else {
                                        (__ci_expr_ternary_6 = 6)
                                    }

                                    (pop_info.op_single_type = __ci_expr_ternary_6)

                                    ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *i8), ((code_start__goto_2138_14 + ((1 as isize) as usize)) as *i8), (32 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if ((if lengthptr != null: 1 else: 0) != 0) {
                                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + (((code__goto_2137_14 as usize) -% ((code_start__goto_2138_14 + ((1 as isize) as usize)) as usize)) / sizeof[u8]()))
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (code__goto_2137_14 = code_start__goto_2138_14 + ((1 as isize) as usize))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_logic_7: c_int = 0

                                    if ((if not (context.needs_bitmap != 0): 1 else: 0) != 0) {
                                        (__ci_expr_logic_7 = (if (if (unsafe: *code_start__goto_2138_14) == 7: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_7 != 0) {
                                        (classwords__goto_2242_17 = ((&pop_info.bits.classwords[0] as *mut c_uint)))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_2244_16 = 0)

                                        while ((if i__goto_2244_16 < 8: 1 else: 0) != 0) {
                                            if ((if (unsafe: classwords__goto_2242_17[i__goto_2244_16]) != 0: 1 else: 0) != 0) {
                                                (context.needs_bitmap = 1)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                break

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (i__goto_2244_16 = i__goto_2244_16 + 1)

                                        }


                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        (context.needs_bitmap = 1)
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.op_single_type = 5)

                                    ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                    if (__goto_pending != 0) {
                                        break
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *i8), ((&context.cb.classbits.classbits[0] as *mut u8) as *i8), (32 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.length = ((((code__goto_2137_14 as usize) -% (code_start__goto_2138_14 as usize)) / sizeof[u8]()) +% extra_length__goto_2140_12))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                            }


                        },
                        2148401152 => {
                            if ((if ((unsafe: *ptr__goto_2135_11) & 1) != 0: 1 else: 0) != 0) {
                                if ((if not (compile_eclass_nested(context, negated, (&mut ptr__goto_2135_11 as *mut *mut c_uint), (&mut code__goto_2137_14 as *mut *mut u8), pop_info, lengthptr) != 0): 1 else: 0) != 0) {
                                    return 0
                                }

                                if (__goto_pending != 0) {
                                    break
                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                                (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                __pc = 1
                                __goto_pending = 1

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                            (prev_ptr__goto_2136_11 = ptr__goto_2135_11)

                            (ptr__goto_2135_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2135_11, (&mut code__goto_2137_14 as *mut *mut u8), (if (if meta__goto_2141_10 != 2148401152: 1 else: 0) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))

                            if ((if ptr__goto_2135_11 == null: 1 else: 0) != 0) {
                                return 0
                            }

                            if ((if ptr__goto_2135_11 <= prev_ptr__goto_2136_11: 1 else: 0) != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                return 0

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            var __ci_expr_logic_3: c_int

                            if ((if meta__goto_2141_10 == 2148139008: 1 else: 0) != 0) {
                                (__ci_expr_logic_3 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_3 = (if (if meta__goto_2141_10 == 2148401152: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_3 != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                            }



                            var __ci_expr_ternary_4: c_ulong = 0

                            if ((if lengthptr != null: 1 else: 0) != 0) {
                                (__ci_expr_ternary_4 = ((unsafe: *lengthptr) -% prev_length__goto_2139_12))
                            } else {
                                (__ci_expr_ternary_4 = 0)
                            }

                            (extra_length__goto_2140_12 = __ci_expr_ternary_4)


                            if ((if (unsafe: *code_start__goto_2138_14) == OP_ALLANY: 1 else: 0) != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                (pop_info.length = 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (pop_info.op_single_type = 6)

                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 255, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            } else {
                                var __ci_expr_logic_5: c_int

                                if ((if (unsafe: *code_start__goto_2138_14) == OP_CLASS: 1 else: 0) != 0) {
                                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_5 = (if (if (unsafe: *code_start__goto_2138_14) == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_5 != 0) {

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.length = 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_ternary_6: c_int = 0

                                    if ((if (unsafe: *code_start__goto_2138_14) == OP_CLASS: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_6 = 7)
                                    } else {
                                        (__ci_expr_ternary_6 = 6)
                                    }

                                    (pop_info.op_single_type = __ci_expr_ternary_6)

                                    ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *i8), ((code_start__goto_2138_14 + ((1 as isize) as usize)) as *i8), (32 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if ((if lengthptr != null: 1 else: 0) != 0) {
                                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + (((code__goto_2137_14 as usize) -% ((code_start__goto_2138_14 + ((1 as isize) as usize)) as usize)) / sizeof[u8]()))
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (code__goto_2137_14 = code_start__goto_2138_14 + ((1 as isize) as usize))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_logic_7: c_int = 0

                                    if ((if not (context.needs_bitmap != 0): 1 else: 0) != 0) {
                                        (__ci_expr_logic_7 = (if (if (unsafe: *code_start__goto_2138_14) == 7: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_7 != 0) {
                                        (classwords__goto_2242_17 = ((&pop_info.bits.classwords[0] as *mut c_uint)))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_2244_16 = 0)

                                        while ((if i__goto_2244_16 < 8: 1 else: 0) != 0) {
                                            if ((if (unsafe: classwords__goto_2242_17[i__goto_2244_16]) != 0: 1 else: 0) != 0) {
                                                (context.needs_bitmap = 1)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                break

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (i__goto_2244_16 = i__goto_2244_16 + 1)

                                        }


                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        (context.needs_bitmap = 1)
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.op_single_type = 5)

                                    ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                    if (__goto_pending != 0) {
                                        break
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *i8), ((&context.cb.classbits.classbits[0] as *mut u8) as *i8), (32 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.length = ((((code__goto_2137_14 as usize) -% (code_start__goto_2138_14 as usize)) / sizeof[u8]()) +% extra_length__goto_2140_12))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                            }


                        },
                        _ => {
                            (prev_ptr__goto_2136_11 = ptr__goto_2135_11)

                            (ptr__goto_2135_11 = _pcre2_compile_class_not_nested_8(context.options, context.xoptions, ptr__goto_2135_11, (&mut code__goto_2137_14 as *mut *mut u8), (if (if meta__goto_2141_10 != 2148401152: 1 else: 0) == negated: 1 else: 0), ((&context.needs_bitmap as *const c_int) as *mut c_int), context.errorcodeptr, context.cb, lengthptr))

                            if ((if ptr__goto_2135_11 == null: 1 else: 0) != 0) {
                                return 0
                            }

                            if ((if ptr__goto_2135_11 <= prev_ptr__goto_2136_11: 1 else: 0) != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                return 0

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            var __ci_expr_logic_3: c_int

                            if ((if meta__goto_2141_10 == 2148139008: 1 else: 0) != 0) {
                                (__ci_expr_logic_3 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_3 = (if (if meta__goto_2141_10 == 2148401152: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_3 != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                (ptr__goto_2135_11 = ptr__goto_2135_11 + 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                            }



                            var __ci_expr_ternary_4: c_ulong = 0

                            if ((if lengthptr != null: 1 else: 0) != 0) {
                                (__ci_expr_ternary_4 = ((unsafe: *lengthptr) -% prev_length__goto_2139_12))
                            } else {
                                (__ci_expr_ternary_4 = 0)
                            }

                            (extra_length__goto_2140_12 = __ci_expr_ternary_4)


                            if ((if (unsafe: *code_start__goto_2138_14) == OP_ALLANY: 1 else: 0) != 0) {

                                if (__goto_pending != 0) {
                                    break
                                }

                                (pop_info.length = 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (pop_info.op_single_type = 6)

                                ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                if (__goto_pending != 0) {
                                    break
                                }

                                with_memset(((&pop_info.bits.classbits[0] as *mut u8) as *i8), 255, (32 as i64))

                                if (__goto_pending != 0) {
                                    break
                                }

                            } else {
                                var __ci_expr_logic_5: c_int

                                if ((if (unsafe: *code_start__goto_2138_14) == OP_CLASS: 1 else: 0) != 0) {
                                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_5 = (if (if (unsafe: *code_start__goto_2138_14) == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_5 != 0) {

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.length = 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_ternary_6: c_int = 0

                                    if ((if (unsafe: *code_start__goto_2138_14) == OP_CLASS: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_6 = 7)
                                    } else {
                                        (__ci_expr_ternary_6 = 6)
                                    }

                                    (pop_info.op_single_type = __ci_expr_ternary_6)

                                    ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *i8), ((code_start__goto_2138_14 + ((1 as isize) as usize)) as *i8), (32 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if ((if lengthptr != null: 1 else: 0) != 0) {
                                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + (((code__goto_2137_14 as usize) -% ((code_start__goto_2138_14 + ((1 as isize) as usize)) as usize)) / sizeof[u8]()))
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (code__goto_2137_14 = code_start__goto_2138_14 + ((1 as isize) as usize))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_logic_7: c_int = 0

                                    if ((if not (context.needs_bitmap != 0): 1 else: 0) != 0) {
                                        (__ci_expr_logic_7 = (if (if (unsafe: *code_start__goto_2138_14) == 7: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_7 != 0) {
                                        (classwords__goto_2242_17 = ((&pop_info.bits.classwords[0] as *mut c_uint)))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_2244_16 = 0)

                                        while ((if i__goto_2244_16 < 8: 1 else: 0) != 0) {
                                            if ((if (unsafe: classwords__goto_2242_17[i__goto_2244_16]) != 0: 1 else: 0) != 0) {
                                                (context.needs_bitmap = 1)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                break

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (i__goto_2244_16 = i__goto_2244_16 + 1)

                                        }


                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        (context.needs_bitmap = 1)
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.op_single_type = 5)

                                    ((unsafe: *code_start__goto_2138_14) = pop_info.op_single_type)


                                    if (__goto_pending != 0) {
                                        break
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memcpy(((&pop_info.bits.classbits[0] as *mut u8) as *i8), ((&context.cb.classbits.classbits[0] as *mut u8) as *i8), (32 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (pop_info.length = ((((code__goto_2137_14 as usize) -% (code_start__goto_2138_14 as usize)) / sizeof[u8]()) +% extra_length__goto_2140_12))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                            }

                        },
                    }
                    break
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_ternary_9: *mut u8 = null
                if ((if lengthptr == null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_9 = code_start__goto_2138_14)
                } else {
                    (__ci_expr_ternary_9 = ((null as *mut u8)))
                }
                (pop_info.code_start = __ci_expr_ternary_9)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if lengthptr != null: 1 else: 0) != 0) {
                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + (((code__goto_2137_14 as usize) -% (code_start__goto_2138_14 as usize)) / sizeof[u8]()))
                    if (__goto_pending != 0) {
                        continue
                    }
                    (code__goto_2137_14 = code_start__goto_2138_14)
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 1
                __goto_pending = 1
                continue
            },
            1 => {  // DONE
                (__goto_pending = 0)
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *pptr) = ptr__goto_2135_11)
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *pcode) = code__goto_2137_14)
                if (__goto_pending != 0) {
                    continue
                }
                return 1
                if (__goto_pending != 0) {
                    continue
                }
            },
            _ => {
                break
            },
        }
    }
}

fn compile_class_juxtaposition(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int {
    var ptr: *mut c_uint = (unsafe: *pptr)

    var code: *mut u8 = (unsafe: *pcode)

    if ((if not (compile_class_operand(context, negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), pop_info, lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while true {
        var __ci_expr_logic_1: c_int = 0

        if ((if (unsafe: *ptr) != 2148335616: 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int = 0

            if ((if (unsafe: *ptr) >= 2151940096: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if (unsafe: *ptr) <= 2152202240: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if (if not (__ci_expr_logic_0 != 0): 1 else: 0) != 0: 1 else: 0))

        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        var op: c_uint

        var rhs_negated: c_int

        var rhs_op_info: eclass_op_info

        if (negated != 0) {
            (op = 1)

            (rhs_negated = 1)

        } else {
            (op = 2)

            (rhs_negated = 0)

        }

        if ((if not (compile_class_operand(context, rhs_negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), (&mut rhs_op_info as *mut eclass_op_info), lengthptr) != 0): 1 else: 0) != 0) {
            return 0
        }

        fold_binary(op, pop_info, (&mut rhs_op_info as *mut eclass_op_info), lengthptr)

        if ((if lengthptr == null: 1 else: 0) != 0) {
            (code = pop_info.code_start + pop_info.length)
        }

    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    ((unsafe: *pptr) = ptr)

    ((unsafe: *pcode) = code)

    return 1

}

fn compile_class_unary(context: *mut eclass_context, __param_negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int {
    var negated = __param_negated
    var ptr: *mut c_uint = (unsafe: *pptr)

    while ((if (unsafe: *ptr) == 2152202240: 1 else: 0) != 0) {
        (ptr = ptr + 1)

        (negated = (if not (negated != 0): 1 else: 0))

    }

    ((unsafe: *pptr) = ptr)

    if ((if not (compile_class_juxtaposition(context, negated, pptr, pcode, pop_info, lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    return 1

}

fn compile_class_binary_tight(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int {
    var ptr: *mut c_uint = (unsafe: *pptr)

    var code: *mut u8 = (unsafe: *pcode)

    if ((if not (compile_class_unary(context, negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), pop_info, lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while ((if (unsafe: *ptr) == 2151940096: 1 else: 0) != 0) {
        var op: c_uint

        var rhs_negated: c_int

        var rhs_op_info: eclass_op_info

        if (negated != 0) {
            (op = 2)

            (rhs_negated = 1)

        } else {
            (op = 1)

            (rhs_negated = 0)

        }

        (ptr = ptr + 1)

        if ((if not (compile_class_unary(context, rhs_negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), (&mut rhs_op_info as *mut eclass_op_info), lengthptr) != 0): 1 else: 0) != 0) {
            return 0
        }

        fold_binary(op, pop_info, (&mut rhs_op_info as *mut eclass_op_info), lengthptr)

        if ((if lengthptr == null: 1 else: 0) != 0) {
            (code = pop_info.code_start + pop_info.length)
        }

    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    ((unsafe: *pptr) = ptr)

    ((unsafe: *pcode) = code)

    return 1

}

fn compile_class_binary_loose(context: *mut eclass_context, negated: c_int, pptr: *mut *mut c_uint, pcode: *mut *mut u8, pop_info: *mut eclass_op_info, lengthptr: *mut c_ulong) -> c_int {
    var ptr: *mut c_uint = (unsafe: *pptr)

    var code: *mut u8 = (unsafe: *pcode)

    if ((if not (compile_class_binary_tight(context, negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), pop_info, lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe: *ptr) >= 2152005632: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: *ptr) <= 2152136704: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var op: c_uint

        var op_neg: c_int

        var rhs_negated: c_int

        var rhs_op_info: eclass_op_info

        if (negated != 0) {
            var __ci_expr_ternary_2: c_int = 0

            if ((if (unsafe: *ptr) == 2152005632: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = 1)
            } else {
                var __ci_expr_ternary_1: c_int = 0

                if ((if (unsafe: *ptr) == 2152071168: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = 2)
                } else {
                    (__ci_expr_ternary_1 = 3)
                }

                (__ci_expr_ternary_2 = __ci_expr_ternary_1)

            }

            (op = __ci_expr_ternary_2)


            (op_neg = (if (unsafe: *ptr) == 2152136704: 1 else: 0))

            (rhs_negated = (if (unsafe: *ptr) != 2152071168: 1 else: 0))

        } else {
            var __ci_expr_ternary_4: c_int = 0

            if ((if (unsafe: *ptr) == 2152005632: 1 else: 0) != 0) {
                (__ci_expr_ternary_4 = 2)
            } else {
                var __ci_expr_ternary_3: c_int = 0

                if ((if (unsafe: *ptr) == 2152071168: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = 1)
                } else {
                    (__ci_expr_ternary_3 = 3)
                }

                (__ci_expr_ternary_4 = __ci_expr_ternary_3)

            }

            (op = __ci_expr_ternary_4)


            (op_neg = 0)

            (rhs_negated = (if (unsafe: *ptr) == 2152071168: 1 else: 0))

        }

        (ptr = ptr + 1)

        if ((if not (compile_class_binary_tight(context, rhs_negated, (&mut ptr as *mut *mut c_uint), (&mut code as *mut *mut u8), (&mut rhs_op_info as *mut eclass_op_info), lengthptr) != 0): 1 else: 0) != 0) {
            return 0
        }

        fold_binary(op, pop_info, (&mut rhs_op_info as *mut eclass_op_info), lengthptr)

        if (op_neg != 0) {
            fold_negation(pop_info, lengthptr, 0)
        }

        if ((if lengthptr == null: 1 else: 0) != 0) {
            (code = pop_info.code_start + pop_info.length)
        }

    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    ((unsafe: *pptr) = ptr)

    ((unsafe: *pcode) = code)

    return 1

}

let char_list_starts: [3]c_uint = [0x10000, 0x8000, 0x100]
