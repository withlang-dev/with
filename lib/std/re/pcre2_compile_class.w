// Migrated from PCRE2
use std.re.defs

fn _pcre2_update_classbits_8(__param_ptype: c_uint, __param_pdata: c_uint, __param_negated: c_int, __param_classbits: *mut u8) {
    var __local_classbits = __param_classbits
    var __local_c: c_int

    var __local_chartype: c_int


    var __local_prop: *const ucd_record

    var __local_gentype: c_uint

    var __local_set_bit: c_int

    if ((if __param_ptype == 13: 1 else: 0) != 0) {
        if ((if not (__param_negated != 0): 1 else: 0) != 0) {
            with_memset((__local_classbits as *i8), 255, (32 as i64))
        }

        return

    }

    (__local_c = 0)

    while ((if __local_c < 256: 1 else: 0) != 0) {
        (__local_prop = (&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[(__local_c / 128)] as c_int) * 128) + (__local_c % 128))] as c_uint) as usize))

        (__local_set_bit = 0)

        __local_set_bit

        while true {
            match __param_ptype {
                0 => {
                    (__local_chartype = __local_prop.chartype)

                    var __ci_expr_logic_1: c_int

                    var __ci_expr_logic_0: c_int

                    if ((if __local_chartype == ucp_Lu: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_0 = (if (if __local_chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if __local_chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__local_set_bit = __ci_expr_logic_1)


                },
                1 => {
                    (__local_set_bit = (if _pcre2_ucp_gentype_8[__local_prop.chartype] == __param_pdata: 1 else: 0))
                },
                2 => {
                    (__local_set_bit = (if __local_prop.chartype == __param_pdata: 1 else: 0))
                },
                3 => {
                    (__local_set_bit = (if __local_prop.script == __param_pdata: 1 else: 0))
                },
                4 => {
                    var __ci_expr_logic_2: c_int

                    if ((if __local_prop.script == __param_pdata: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_prop.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[((__param_pdata as c_uint) / (32 as c_uint))]) as c_uint) & (((1 as c_uint) << (((__param_pdata as c_uint) % (32 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__local_set_bit = __ci_expr_logic_2)

                },
                5 => {
                    (__local_gentype = _pcre2_ucp_gentype_8[__local_prop.chartype])

                    var __ci_expr_logic_3: c_int

                    if ((if __local_gentype == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_3 = (if (if __local_gentype == 3: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__local_set_bit = __ci_expr_logic_3)


                },
                6 => {
                    while true {
                        match __local_c {
                            9 => {
                                (__local_set_bit = 1)
                            },
                            32 => {
                                (__local_set_bit = 1)
                            },
                            160 => {
                                (__local_set_bit = 1)
                            },
                            10 => {
                                (__local_set_bit = 1)
                            },
                            11 => {
                                (__local_set_bit = 1)
                            },
                            12 => {
                                (__local_set_bit = 1)
                            },
                            13 => {
                                (__local_set_bit = 1)
                            },
                            133 => {
                                (__local_set_bit = 1)
                            },
                            _ => {
                                (__local_set_bit = (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 6: 1 else: 0))
                            },
                        }

                        break

                    }
                },
                7 => {
                    while true {
                        match __local_c {
                            9 => {
                                (__local_set_bit = 1)
                            },
                            32 => {
                                (__local_set_bit = 1)
                            },
                            160 => {
                                (__local_set_bit = 1)
                            },
                            10 => {
                                (__local_set_bit = 1)
                            },
                            11 => {
                                (__local_set_bit = 1)
                            },
                            12 => {
                                (__local_set_bit = 1)
                            },
                            13 => {
                                (__local_set_bit = 1)
                            },
                            133 => {
                                (__local_set_bit = 1)
                            },
                            _ => {
                                (__local_set_bit = (if _pcre2_ucp_gentype_8[__local_prop.chartype] == 6: 1 else: 0))
                            },
                        }

                        break

                    }
                },
                8 => {
                    (__local_chartype = __local_prop.chartype)

                    (__local_gentype = _pcre2_ucp_gentype_8[__local_chartype])

                    var __ci_expr_logic_7: c_int

                    var __ci_expr_logic_6: c_int

                    var __ci_expr_logic_5: c_int

                    if ((if __local_gentype == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_5 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_5 = (if (if __local_gentype == 3: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_5 != 0) {
                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_6 = (if (if __local_chartype == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_6 != 0) {
                        (__ci_expr_logic_7 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_7 = (if (if __local_chartype == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__local_set_bit = __ci_expr_logic_7)


                },
                10 => {
                    var __ci_expr_logic_10: c_int

                    var __ci_expr_logic_9: c_int

                    var __ci_expr_logic_8: c_int

                    if ((if __local_c == 36: 1 else: 0) != 0) {
                        (__ci_expr_logic_8 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_8 = (if (if __local_c == 64: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_8 != 0) {
                        (__ci_expr_logic_9 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_9 = (if (if __local_c == 96: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_9 != 0) {
                        (__ci_expr_logic_10 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_10 = (if (if __local_c >= 160: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__local_set_bit = __ci_expr_logic_10)

                },
                11 => {
                    (__local_set_bit = (if ((__local_prop.scriptx_bidiclass as c_int) >> (11 as c_uint)) == __param_pdata: 1 else: 0))
                },
                12 => {
                    (__local_set_bit = (if (((unsafe ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + ((((__local_prop.bprops as c_int) & 4095) as isize) as usize))[((__param_pdata as c_uint) / (32 as c_uint))]) as c_uint) & (((1 as c_uint) << (((__param_pdata as c_uint) % (32 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0))
                },
                14 => {
                    (__local_chartype = __local_prop.chartype)

                    (__local_gentype = _pcre2_ucp_gentype_8[__local_chartype])

                    var __ci_expr_logic_12: c_int = 0

                    if ((if __local_gentype != 6: 1 else: 0) != 0) {
                        var __ci_expr_logic_11: c_int

                        if ((if __local_gentype != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_11 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_11 = (if (if __local_chartype == ucp_Cf: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_12 = (if __ci_expr_logic_11 != 0: 1 else: 0))

                    }

                    (__local_set_bit = __ci_expr_logic_12)


                },
                15 => {
                    (__local_chartype = __local_prop.chartype)

                    var __ci_expr_logic_15: c_int = 0

                    var __ci_expr_logic_13: c_int = 0

                    if ((if __local_chartype != ucp_Zl: 1 else: 0) != 0) {
                        (__ci_expr_logic_13 = (if (if __local_chartype != ucp_Zp: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_13 != 0) {
                        var __ci_expr_logic_14: c_int

                        if ((if _pcre2_ucp_gentype_8[__local_chartype] != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if __local_chartype == ucp_Cf: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_15 = (if __ci_expr_logic_14 != 0: 1 else: 0))

                    }

                    (__local_set_bit = __ci_expr_logic_15)


                },
                16 => {
                    (__local_gentype = _pcre2_ucp_gentype_8[__local_prop.chartype])

                    var __ci_expr_logic_17: c_int

                    if ((if __local_gentype == 4: 1 else: 0) != 0) {
                        (__ci_expr_logic_17 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_16: c_int = 0

                        if ((if __local_c < 128: 1 else: 0) != 0) {
                            (__ci_expr_logic_16 = (if (if __local_gentype == 5: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_17 = (if __ci_expr_logic_16 != 0: 1 else: 0))

                    }

                    (__local_set_bit = __ci_expr_logic_17)


                },
                _ => {
                    do {
                        0
                    } while (0 != 0)

                    var __ci_expr_logic_22: c_int

                    var __ci_expr_logic_20: c_int

                    var __ci_expr_logic_18: c_int = 0

                    if ((if __local_c >= 48: 1 else: 0) != 0) {
                        (__ci_expr_logic_18 = (if (if __local_c <= 57: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_18 != 0) {
                        (__ci_expr_logic_20 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_19: c_int = 0

                        if ((if __local_c >= 65: 1 else: 0) != 0) {
                            (__ci_expr_logic_19 = (if (if __local_c <= 70: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_20 = (if __ci_expr_logic_19 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_20 != 0) {
                        (__ci_expr_logic_22 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_21: c_int = 0

                        if ((if __local_c >= 97: 1 else: 0) != 0) {
                            (__ci_expr_logic_21 = (if (if __local_c <= 102: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

                    }

                    (__local_set_bit = __ci_expr_logic_22)


                },
            }

            break

        }

        if (__param_negated != 0) {
            (__local_set_bit = (if not (__local_set_bit != 0): 1 else: 0))
        }

        if (__local_set_bit != 0) {
            ((unsafe *__local_classbits) = (unsafe *__local_classbits) | (((1 as c_int) << ((__local_c & 7) as c_uint)) as u8))
        }

        if ((if (__local_c & 7) == 7: 1 else: 0) != 0) {
            (__local_classbits = __local_classbits + 1)
        }


        (__local_c = __local_c + 1)

    }


}

fn _pcre2_compile_class_not_nested_8(__param_options: c_uint, __param_xoptions: c_uint, __param_start_ptr: *mut c_uint, __param_pcode: *mut *mut u8, __param_negate_class: c_int, __param_has_bitmap: *mut c_int, __param_errorcodeptr: *mut c_int, __param_cb: *mut compile_block_8, __param_lengthptr: *mut c_ulong) -> *mut c_uint {
    var __local_pptr__goto_1072_11: *mut c_uint = null

    var __local_code__goto_1073_14: *mut u8 = null

    var __local_should_flip_negation__goto_1074_6: c_int = 0

    var __local_cbits__goto_1075_16: *const u8 = null

    var __local_classbits__goto_1078_16: *mut u8 = null

    var __local_utf__goto_1081_6: c_int = 0

    var __local_xclass_props__goto_1089_10: c_uint = 0

    var __local_class_uchardata__goto_1090_14: *mut u8 = null

    var __local_cranges__goto_1091_15: *mut class_ranges = null

    var __local_ranges__goto_1145_21: *const c_uint = null

    var __local_meta__goto_1170_12: c_uint = 0

    var __local_local_negate__goto_1171_8: c_int = 0

    var __local_posix_class__goto_1172_7: c_int = 0

    var __local_taboffset__goto_1173_7: c_int = 0

    var __local_tabopt__goto_1173_18: c_int = 0

    var __local_pbits__goto_1174_22: class_bits_storage

    var __local_escape__goto_1175_12: c_uint = 0

    var __local_c__goto_1175_20: c_uint = 0

    var __local_ptype__goto_1207_16: c_uint = 0

    var __local_i__goto_1275_18: c_int = 0

    var __local_i__goto_1278_18: c_int = 0

    var __local_classwords__goto_1308_17: *mut c_uint = null

    var __local_i__goto_1311_18: c_int = 0

    var __local_i__goto_1314_18: c_int = 0

    var __local_i__goto_1336_16: c_int = 0

    var __local_i__goto_1341_16: c_int = 0

    var __local_i__goto_1346_16: c_int = 0

    var __local_i__goto_1351_16: c_int = 0

    var __local_i__goto_1363_16: c_int = 0

    var __local_i__goto_1368_16: c_int = 0

    var __local_ptype__goto_1433_18: c_uint = 0

    var __local_pdata__goto_1434_18: c_uint = 0

    var __local_d__goto_1493_14: c_uint = 0

    var __local_range__goto_1577_13: *mut c_uint = null

    var __local_end__goto_1578_13: *mut c_uint = null

    var __local_range_start__goto_1612_16: c_uint = 0

    var __local_range_end__goto_1613_16: c_uint = 0

    var __local_previous__goto_1703_16: *mut u8 = null

    var __local_classwords__goto_1719_17: *mut c_uint = null

    var __local_i__goto_1720_16: c_int = 0

    var __local_char_lists_size__goto_1744_12: c_ulong = 0

    var __local_data__goto_1773_16: *mut u8 = null

    var __local_classwords__goto_1839_13: *mut c_uint = null

    var __local_i__goto_1841_12: c_int = 0

    var __local_classwords__goto_1847_19: *const c_uint = null

    var __local_i__goto_1848_7: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_ternary_0: c_uint = 0

    var __ci_expr_old_2: *mut c_uint = null

    var __ci_expr_old_3: *mut c_uint = null

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_ternary_7: c_int = 0

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_ternary_9: c_int = 0

    var __ci_expr_old_10: *mut u8 = null

    var __ci_expr_old_11: *mut u8 = null

    var __ci_expr_old_12: *mut c_uint = null

    var __ci_expr_old_13: *mut c_uint = null

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_old_15: *mut u8 = null

    var __ci_expr_ternary_16: c_int = 0

    var __ci_expr_old_17: *mut u8 = null

    var __ci_expr_old_18: *mut u8 = null

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_logic_20: c_int = 0

    var __ci_expr_old_21: *mut c_uint = null

    var __ci_expr_old_22: *mut c_uint = null

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_ternary_25: c_uint = 0

    var __ci_expr_ternary_26: c_int = 0

    var __ci_expr_old_27: *mut u8 = null

    var __ci_expr_old_28: *mut u8 = null

    var __ci_expr_old_29: *mut u8 = null

    var __ci_expr_old_30: *mut u8 = null

    var __ci_expr_ternary_31: c_int = 0

    var __ci_expr_logic_32: c_int = 0

    var __ci_expr_old_33: *mut u8 = null

    var __ci_expr_logic_34: c_int = 0

    var __ci_expr_ternary_35: c_int = 0

    var __ci_expr_logic_37: c_int = 0

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_old_38: *mut u8 = null

    var __ci_expr_old_39: *mut u8 = null

    var __ci_expr_ternary_40: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_pptr__goto_1072_11 = __param_start_ptr)
        (__local_code__goto_1073_14 = (unsafe *__param_pcode))
        (__local_cbits__goto_1075_16 = __param_cb.cbits)
        (__local_classbits__goto_1078_16 = ((&raw const (unsafe *__param_cb).classbits.classbits[0] as *mut u8)))
        (__local_utf__goto_1081_6 = (if ((__param_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        (__local_should_flip_negation__goto_1074_6 = 0)
        (__local_xclass_props__goto_1089_10 = 0)
        (__local_cranges__goto_1091_15 = ((null as *mut class_ranges)))
        if (__local_utf__goto_1081_6 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        (__local_class_uchardata__goto_1090_14 = (__local_code__goto_1073_14 + ((2 as isize) as usize)) + ((2 as isize) as usize))
        with_memset((__local_classbits__goto_1078_16 as *i8), 0, (32 as i64))
        goto '__ci_bb_20
    }

    '__ci_bb_3 {
        (__local_cranges__goto_1091_15 = compile_optimize_class(__local_pptr__goto_1072_11, __param_options, __param_xoptions, __param_cb))
        if ((if __local_cranges__goto_1091_15 == null: 1 else: 0) != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_4 {
        (__local_cranges__goto_1091_15 = ((__param_cb.first_data as *mut class_ranges)))
        goto '__ci_bb_11
    }

    '__ci_bb_5 {
        if ((if __local_cranges__goto_1091_15.range_list_size > 0: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_6 {
        ((unsafe *__param_errorcodeptr) = ERR21)
        return null
    }

    '__ci_bb_7 {
        if ((if __param_cb.last_data != null: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        ((unsafe *__param_cb.last_data).next = (((&raw const (unsafe *__local_cranges__goto_1091_15).header as *const compile_data) as *mut compile_data)))
        goto '__ci_bb_10
    }

    '__ci_bb_9 {
        ((unsafe *__param_cb).first_data = (((&raw const (unsafe *__local_cranges__goto_1091_15).header as *const compile_data) as *mut compile_data)))
        goto '__ci_bb_10
    }

    '__ci_bb_10 {
        ((unsafe *__param_cb).last_data = (((&raw const (unsafe *__local_cranges__goto_1091_15).header as *const compile_data) as *mut compile_data)))
        goto '__ci_bb_5
    }

    '__ci_bb_11 {
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        if (0 != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_13 {
        ((unsafe *__param_cb).first_data = (&raw const (unsafe *__local_cranges__goto_1091_15).header as *const compile_data).next)
        goto '__ci_bb_5
    }

    '__ci_bb_14 {
        (__local_ranges__goto_1145_21 = (((__local_cranges__goto_1091_15 + ((1 as isize) as usize)) as *const c_uint)))
        if ((if (unsafe __local_ranges__goto_1145_21[0]) <= 255: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_15 {
        goto '__ci_bb_2
    }

    '__ci_bb_16 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 2)
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        (__ci_expr_logic_1 = 0)
        (__ci_expr_ternary_0 = 0)
        if (__local_utf__goto_1081_6 != 0) {
            (__ci_expr_ternary_0 = 1114111)
        } else {
            (__ci_expr_ternary_0 = 255)
        }
        if ((if (unsafe __local_ranges__goto_1145_21[((__local_cranges__goto_1091_15.range_list_size as c_int) - 1)]) == __ci_expr_ternary_0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe __local_ranges__goto_1145_21[((__local_cranges__goto_1091_15.range_list_size as c_int) - 2)]) <= 256: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 16)
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        goto '__ci_bb_15
    }

    '__ci_bb_20 {
        if (1 != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_21 {
        (__ci_expr_old_2 = __local_pptr__goto_1072_11)
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__local_meta__goto_1170_12 = (unsafe *__ci_expr_old_2))
        goto '__ci_bb_23
    }

    '__ci_bb_22 {
        goto '__ci_bb_144
    }

    '__ci_bb_23 {
        if (((__local_meta__goto_1170_12 as c_uint) & ((4294901760 as c_uint) as c_uint)) == 2149580800) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_24 {
        (__local_c__goto_1175_20 = __local_meta__goto_1170_12)
        if ((if __local_c__goto_1175_20 == 13: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_19 = (if (if __local_c__goto_1175_20 == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_25 {
        (__local_local_negate__goto_1171_8 = (if __local_meta__goto_1170_12 == 2149646336: 1 else: 0))
        (__ci_expr_old_3 = __local_pptr__goto_1072_11)
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__local_posix_class__goto_1172_7 = (unsafe *__ci_expr_old_3))
        if (__local_local_negate__goto_1171_8 != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_26 {
        (__local_should_flip_negation__goto_1074_6 = 1)
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        (__ci_expr_logic_4 = 0)
        if ((if ((__param_options as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_posix_class__goto_1172_7 <= 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_28 {
        (__local_posix_class__goto_1172_7 = 0)
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        (__ci_expr_logic_5 = 0)
        if ((if ((__param_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if ((__param_xoptions as c_uint) & (2048 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_32
    }

    '__ci_bb_31 {
        (__local_posix_class__goto_1172_7 = __local_posix_class__goto_1172_7 * 3)
        with_memcpy(((&(unsafe (&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), ((__local_cbits__goto_1075_16 + ((_pcre2_posix_class_maps8[__local_posix_class__goto_1172_7] as isize) as usize)) as *i8), (32 as i64))
        (__local_taboffset__goto_1173_7 = _pcre2_posix_class_maps8[(__local_posix_class__goto_1172_7 + 1)])
        (__local_tabopt__goto_1173_18 = _pcre2_posix_class_maps8[(__local_posix_class__goto_1172_7 + 2)])
        if ((if __local_taboffset__goto_1173_7 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_32 {
        if (__local_posix_class__goto_1172_7 == 8) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_33 {
        goto '__ci_bb_31
    }

    '__ci_bb_34 {
        (__ci_expr_ternary_7 = 0)
        if ((if __local_posix_class__goto_1172_7 == 8: 1 else: 0) != 0) {
            (__ci_expr_ternary_7 = 14)
        } else {
            var __ci_expr_ternary_6: c_int = 0

            if ((if __local_posix_class__goto_1172_7 == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_6 = 15)
            } else {
                (__ci_expr_ternary_6 = 16)
            }

            (__ci_expr_ternary_7 = __ci_expr_ternary_6)

        }
        (__local_ptype__goto_1207_16 = __ci_expr_ternary_7)
        _pcre2_update_classbits_8(__local_ptype__goto_1207_16, 0, __local_local_negate__goto_1171_8, __local_classbits__goto_1078_16)
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_35 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_36 {
        goto '__ci_bb_20
    }

    '__ci_bb_37 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 3)
        goto '__ci_bb_39
    }

    '__ci_bb_38 {
        (__ci_expr_old_8 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        (__ci_expr_ternary_9 = 0)
        if (__local_local_negate__goto_1171_8 != 0) {
            (__ci_expr_ternary_9 = 4)
        } else {
            (__ci_expr_ternary_9 = 3)
        }
        ((unsafe *__ci_expr_old_8) = __ci_expr_ternary_9)
        (__ci_expr_old_10 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_10) = ((__local_ptype__goto_1207_16 as u8)))
        (__ci_expr_old_11 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_11) = 0)
        goto '__ci_bb_39
    }

    '__ci_bb_39 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 5)
        goto '__ci_bb_36
    }

    '__ci_bb_40 {
        goto '__ci_bb_33
    }

    '__ci_bb_41 {
        if (__local_posix_class__goto_1172_7 == 9) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_42 {
        if (__local_posix_class__goto_1172_7 == 10) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_43 {
        if ((if __local_tabopt__goto_1173_18 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_44 {
        if ((if __local_tabopt__goto_1173_18 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_45 {
        (__local_i__goto_1275_18 = 0)
        goto '__ci_bb_48
    }

    '__ci_bb_46 {
        (__local_i__goto_1278_18 = 0)
        goto '__ci_bb_52
    }

    '__ci_bb_47 {
        goto '__ci_bb_44
    }

    '__ci_bb_48 {
        if ((if __local_i__goto_1275_18 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_49 {
        (__local_pbits__goto_1174_22.classbits[__local_i__goto_1275_18] = (&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classbits[__local_i__goto_1275_18] | (unsafe __local_cbits__goto_1075_16[(__local_i__goto_1275_18 + __local_taboffset__goto_1173_7)]))
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        (__local_i__goto_1275_18 = __local_i__goto_1275_18 + 1)
        goto '__ci_bb_48
    }

    '__ci_bb_51 {
        goto '__ci_bb_47
    }

    '__ci_bb_52 {
        if ((if __local_i__goto_1278_18 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_53 {
        (__local_pbits__goto_1174_22.classbits[__local_i__goto_1278_18] = (&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classbits[__local_i__goto_1278_18] & ((~(unsafe __local_cbits__goto_1075_16[(__local_i__goto_1278_18 + __local_taboffset__goto_1173_7)])) as u8))
        goto '__ci_bb_54
    }

    '__ci_bb_54 {
        (__local_i__goto_1278_18 = __local_i__goto_1278_18 + 1)
        goto '__ci_bb_52
    }

    '__ci_bb_55 {
        goto '__ci_bb_47
    }

    '__ci_bb_56 {
        (__local_tabopt__goto_1173_18 = 0 - __local_tabopt__goto_1173_18)
        goto '__ci_bb_57
    }

    '__ci_bb_57 {
        if ((if __local_tabopt__goto_1173_18 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_58 {
        (__local_pbits__goto_1174_22.classbits[1] = (&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classbits[1] & (~60))
        goto '__ci_bb_60
    }

    '__ci_bb_59 {
        if ((if __local_tabopt__goto_1173_18 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_60 {
        (__local_classwords__goto_1308_17 = ((&raw const (unsafe *__param_cb).classbits.classwords[0] as *mut c_uint)))
        if (__local_local_negate__goto_1171_8 != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_61 {
        (__local_pbits__goto_1174_22.classbits[11] = (&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classbits[11] & 127)
        goto '__ci_bb_62
    }

    '__ci_bb_62 {
        goto '__ci_bb_60
    }

    '__ci_bb_63 {
        (__local_i__goto_1311_18 = 0)
        goto '__ci_bb_66
    }

    '__ci_bb_64 {
        (__local_i__goto_1314_18 = 0)
        goto '__ci_bb_70
    }

    '__ci_bb_65 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 2)
        goto '__ci_bb_20
    }

    '__ci_bb_66 {
        if ((if __local_i__goto_1311_18 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_67 {
        ((unsafe __local_classwords__goto_1308_17[__local_i__goto_1311_18]) = (unsafe __local_classwords__goto_1308_17[__local_i__goto_1311_18]) | (~(&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classwords[__local_i__goto_1311_18]))
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        (__local_i__goto_1311_18 = __local_i__goto_1311_18 + 1)
        goto '__ci_bb_66
    }

    '__ci_bb_69 {
        goto '__ci_bb_65
    }

    '__ci_bb_70 {
        if ((if __local_i__goto_1314_18 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_71 {
        ((unsafe __local_classwords__goto_1308_17[__local_i__goto_1314_18]) = (unsafe __local_classwords__goto_1308_17[__local_i__goto_1314_18]) | (&raw const __local_pbits__goto_1174_22 as *const class_bits_storage).classwords[__local_i__goto_1314_18])
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        (__local_i__goto_1314_18 = __local_i__goto_1314_18 + 1)
        goto '__ci_bb_70
    }

    '__ci_bb_73 {
        goto '__ci_bb_65
    }

    '__ci_bb_74 {
        (__ci_expr_old_12 = __local_pptr__goto_1072_11)
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__local_meta__goto_1170_12 = (unsafe *__ci_expr_old_12))
        goto '__ci_bb_24
    }

    '__ci_bb_75 {
        (__local_escape__goto_1175_12 = (__local_meta__goto_1170_12 as c_uint) & (65535 as c_uint))
        goto '__ci_bb_76
    }

    '__ci_bb_76 {
        if (__local_escape__goto_1175_12 == 7) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_77 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 2)
        goto '__ci_bb_20
    }

    '__ci_bb_78 {
        (__local_i__goto_1336_16 = 0)
        goto '__ci_bb_79
    }

    '__ci_bb_79 {
        if ((if __local_i__goto_1336_16 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_80 {
        ((unsafe __local_classbits__goto_1078_16[__local_i__goto_1336_16]) = (unsafe __local_classbits__goto_1078_16[__local_i__goto_1336_16]) | (unsafe __local_cbits__goto_1075_16[(__local_i__goto_1336_16 + 64)]))
        goto '__ci_bb_81
    }

    '__ci_bb_81 {
        (__local_i__goto_1336_16 = __local_i__goto_1336_16 + 1)
        goto '__ci_bb_79
    }

    '__ci_bb_82 {
        goto '__ci_bb_77
    }

    '__ci_bb_83 {
        (__local_should_flip_negation__goto_1074_6 = 1)
        (__local_i__goto_1341_16 = 0)
        goto '__ci_bb_84
    }

    '__ci_bb_84 {
        if ((if __local_i__goto_1341_16 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_85 {
        ((unsafe __local_classbits__goto_1078_16[__local_i__goto_1341_16]) = (unsafe __local_classbits__goto_1078_16[__local_i__goto_1341_16]) | ((~(unsafe __local_cbits__goto_1075_16[(__local_i__goto_1341_16 + 64)])) as u8))
        goto '__ci_bb_86
    }

    '__ci_bb_86 {
        (__local_i__goto_1341_16 = __local_i__goto_1341_16 + 1)
        goto '__ci_bb_84
    }

    '__ci_bb_87 {
        goto '__ci_bb_77
    }

    '__ci_bb_88 {
        (__local_i__goto_1346_16 = 0)
        goto '__ci_bb_89
    }

    '__ci_bb_89 {
        if ((if __local_i__goto_1346_16 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_90 {
        ((unsafe __local_classbits__goto_1078_16[__local_i__goto_1346_16]) = (unsafe __local_classbits__goto_1078_16[__local_i__goto_1346_16]) | (unsafe __local_cbits__goto_1075_16[(__local_i__goto_1346_16 + 160)]))
        goto '__ci_bb_91
    }

    '__ci_bb_91 {
        (__local_i__goto_1346_16 = __local_i__goto_1346_16 + 1)
        goto '__ci_bb_89
    }

    '__ci_bb_92 {
        goto '__ci_bb_77
    }

    '__ci_bb_93 {
        (__local_should_flip_negation__goto_1074_6 = 1)
        (__local_i__goto_1351_16 = 0)
        goto '__ci_bb_94
    }

    '__ci_bb_94 {
        if ((if __local_i__goto_1351_16 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_95
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_95 {
        ((unsafe __local_classbits__goto_1078_16[__local_i__goto_1351_16]) = (unsafe __local_classbits__goto_1078_16[__local_i__goto_1351_16]) | ((~(unsafe __local_cbits__goto_1075_16[(__local_i__goto_1351_16 + 160)])) as u8))
        goto '__ci_bb_96
    }

    '__ci_bb_96 {
        (__local_i__goto_1351_16 = __local_i__goto_1351_16 + 1)
        goto '__ci_bb_94
    }

    '__ci_bb_97 {
        goto '__ci_bb_77
    }

    '__ci_bb_98 {
        (__local_i__goto_1363_16 = 0)
        goto '__ci_bb_99
    }

    '__ci_bb_99 {
        if ((if __local_i__goto_1363_16 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_100 {
        ((unsafe __local_classbits__goto_1078_16[__local_i__goto_1363_16]) = (unsafe __local_classbits__goto_1078_16[__local_i__goto_1363_16]) | (unsafe __local_cbits__goto_1075_16[(__local_i__goto_1363_16 + 0)]))
        goto '__ci_bb_101
    }

    '__ci_bb_101 {
        (__local_i__goto_1363_16 = __local_i__goto_1363_16 + 1)
        goto '__ci_bb_99
    }

    '__ci_bb_102 {
        goto '__ci_bb_77
    }

    '__ci_bb_103 {
        (__local_should_flip_negation__goto_1074_6 = 1)
        (__local_i__goto_1368_16 = 0)
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        if ((if __local_i__goto_1368_16 < 32: 1 else: 0) != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_107
        }
    }

    '__ci_bb_105 {
        ((unsafe __local_classbits__goto_1078_16[__local_i__goto_1368_16]) = (unsafe __local_classbits__goto_1078_16[__local_i__goto_1368_16]) | ((~(unsafe __local_cbits__goto_1075_16[(__local_i__goto_1368_16 + 0)])) as u8))
        goto '__ci_bb_106
    }

    '__ci_bb_106 {
        (__local_i__goto_1368_16 = __local_i__goto_1368_16 + 1)
        goto '__ci_bb_104
    }

    '__ci_bb_107 {
        goto '__ci_bb_77
    }

    '__ci_bb_108 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_109 {
        goto '__ci_bb_77
    }

    '__ci_bb_110 {
        add_list_to_class(((__param_options as c_uint) & ((~8) as c_uint)), __param_xoptions, __param_cb, (&_pcre2_hspace_list_8[0] as *mut c_uint))
        goto '__ci_bb_77
    }

    '__ci_bb_111 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_112 {
        goto '__ci_bb_77
    }

    '__ci_bb_113 {
        add_not_list_to_class(((__param_options as c_uint) & ((~8) as c_uint)), __param_xoptions, __param_cb, (&_pcre2_hspace_list_8[0] as *mut c_uint))
        goto '__ci_bb_77
    }

    '__ci_bb_114 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_115 {
        goto '__ci_bb_77
    }

    '__ci_bb_116 {
        add_list_to_class(((__param_options as c_uint) & ((~8) as c_uint)), __param_xoptions, __param_cb, (&_pcre2_vspace_list_8[0] as *mut c_uint))
        goto '__ci_bb_77
    }

    '__ci_bb_117 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_118 {
        goto '__ci_bb_77
    }

    '__ci_bb_119 {
        add_not_list_to_class(((__param_options as c_uint) & ((~8) as c_uint)), __param_xoptions, __param_cb, (&_pcre2_vspace_list_8[0] as *mut c_uint))
        goto '__ci_bb_77
    }

    '__ci_bb_120 {
        (__local_ptype__goto_1433_18 = ((unsafe *__local_pptr__goto_1072_11) as c_uint) >> (16 as c_uint))
        (__ci_expr_old_13 = __local_pptr__goto_1072_11)
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__local_pdata__goto_1434_18 = ((unsafe *__ci_expr_old_13) as c_uint) & (65535 as c_uint))
        if ((if __local_ptype__goto_1433_18 == 13: 1 else: 0) != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_121 {
        (__ci_expr_logic_14 = 0)
        if ((if not (__local_utf__goto_1081_6 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if __local_escape__goto_1175_12 == 16: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_123
        } else {
            goto '__ci_bb_124
        }
    }

    '__ci_bb_122 {
        _pcre2_update_classbits_8(__local_ptype__goto_1433_18, __local_pdata__goto_1434_18, (if __local_escape__goto_1175_12 == 15: 1 else: 0), __local_classbits__goto_1078_16)
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_123 {
        with_memset((__local_classbits__goto_1078_16 as *i8), 255, (32 as i64))
        goto '__ci_bb_124
    }

    '__ci_bb_124 {
        goto '__ci_bb_20
    }

    '__ci_bb_125 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_126 {
        goto '__ci_bb_20
    }

    '__ci_bb_127 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 3)
        goto '__ci_bb_129
    }

    '__ci_bb_128 {
        (__ci_expr_old_15 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        (__ci_expr_ternary_16 = 0)
        if ((if __local_escape__goto_1175_12 == 16: 1 else: 0) != 0) {
            (__ci_expr_ternary_16 = 3)
        } else {
            (__ci_expr_ternary_16 = 4)
        }
        ((unsafe *__ci_expr_old_15) = __ci_expr_ternary_16)
        (__ci_expr_old_17 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_17) = __local_ptype__goto_1433_18)
        (__ci_expr_old_18 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_18) = __local_pdata__goto_1434_18)
        goto '__ci_bb_129
    }

    '__ci_bb_129 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 5)
        goto '__ci_bb_126
    }

    '__ci_bb_130 {
        if (__local_escape__goto_1175_12 == 6) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_131 {
        if (__local_escape__goto_1175_12 == 11) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_132 {
        if (__local_escape__goto_1175_12 == 10) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_133 {
        if (__local_escape__goto_1175_12 == 9) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_134 {
        if (__local_escape__goto_1175_12 == 8) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_135 {
        if (__local_escape__goto_1175_12 == 19) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_136 {
        if (__local_escape__goto_1175_12 == 18) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_137 {
        if (__local_escape__goto_1175_12 == 21) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_138 {
        if (__local_escape__goto_1175_12 == 20) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_139 {
        if (__local_escape__goto_1175_12 == 16) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_140 {
        if (__local_escape__goto_1175_12 == 15) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_141 {
        if ((if __local_meta__goto_1170_12 < 2147483648: 1 else: 0) != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_142 {
        goto '__ci_bb_24
    }

    '__ci_bb_143 {
        goto '__ci_bb_144
    }

    '__ci_bb_144 {
        goto '__ci_bb_160
    }

    '__ci_bb_145 {
        if (((__local_meta__goto_1170_12 as c_uint) & ((4294901760 as c_uint) as c_uint)) == 2149646336) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_146 {
        if (((__local_meta__goto_1170_12 as c_uint) & ((4294901760 as c_uint) as c_uint)) == 2147811328) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_147 {
        if (((__local_meta__goto_1170_12 as c_uint) & ((4294901760 as c_uint) as c_uint)) == 2149318656) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_148 {
        ((unsafe *__param_cb).external_flags = __param_cb.external_flags | 2048)
        goto '__ci_bb_149
    }

    '__ci_bb_149 {
        if ((if (unsafe *__local_pptr__goto_1072_11) == 2149777408: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_20 = (if (if (unsafe *__local_pptr__goto_1072_11) == 2149711872: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_20 != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_150 {
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__ci_expr_old_21 = __local_pptr__goto_1072_11)
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__local_d__goto_1493_14 = (unsafe *__ci_expr_old_21))
        if ((if __local_d__goto_1493_14 == 2147811328: 1 else: 0) != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_151 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_158
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_152 {
        (__ci_expr_old_22 = __local_pptr__goto_1072_11)
        (__local_pptr__goto_1072_11 = __local_pptr__goto_1072_11 + 1)
        (__local_d__goto_1493_14 = (unsafe *__ci_expr_old_22))
        goto '__ci_bb_153
    }

    '__ci_bb_153 {
        if ((if __local_d__goto_1493_14 == 13: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_23 = (if (if __local_d__goto_1493_14 == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_154
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_154 {
        ((unsafe *__param_cb).external_flags = __param_cb.external_flags | 2048)
        goto '__ci_bb_155
    }

    '__ci_bb_155 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_156
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_156 {
        goto '__ci_bb_20
    }

    '__ci_bb_157 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 2)
        add_to_class(__param_options, __param_xoptions, __param_cb, __local_c__goto_1175_20, __local_d__goto_1493_14)
        goto '__ci_bb_20
    }

    '__ci_bb_158 {
        goto '__ci_bb_20
    }

    '__ci_bb_159 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 2)
        add_to_class(__param_options, __param_xoptions, __param_cb, __local_meta__goto_1170_12, __local_meta__goto_1170_12)
        goto '__ci_bb_20
    }

    '__ci_bb_160 {
        goto '__ci_bb_161
    }

    '__ci_bb_161 {
        if (0 != 0) {
            goto '__ci_bb_160
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_162 {
        if ((if __local_cranges__goto_1091_15 != null: 1 else: 0) != 0) {
            goto '__ci_bb_163
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_163 {
        (__local_range__goto_1577_13 = (((__local_cranges__goto_1091_15 + ((1 as isize) as usize)) as *mut c_uint)))
        (__local_end__goto_1578_13 = __local_range__goto_1577_13 + ((__local_cranges__goto_1091_15.range_list_size as c_uint) as usize))
        goto '__ci_bb_165
    }

    '__ci_bb_164 {
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_203
        }
    }

    '__ci_bb_165 {
        (__ci_expr_logic_24 = 0)
        if ((if __local_range__goto_1577_13 < __local_end__goto_1578_13: 1 else: 0) != 0) {
            (__ci_expr_logic_24 = (if (if (unsafe __local_range__goto_1577_13[0]) < 256: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_166 {
        goto '__ci_bb_168
    }

    '__ci_bb_167 {
        if ((if __local_cranges__goto_1091_15.char_lists_size > 0: 1 else: 0) != 0) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_168 {
        goto '__ci_bb_169
    }

    '__ci_bb_169 {
        if (0 != 0) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_170 {
        (__ci_expr_ternary_25 = 0)
        if ((if ((__param_options as c_uint) & (((524288 as c_uint) | (131072 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_25 = (__param_options as c_uint) & ((~8) as c_uint))
        } else {
            (__ci_expr_ternary_25 = __param_options)
        }
        add_to_class(__ci_expr_ternary_25, __param_xoptions, __param_cb, (unsafe __local_range__goto_1577_13[0]), (unsafe __local_range__goto_1577_13[1]))
        if ((if (unsafe __local_range__goto_1577_13[1]) > 255: 1 else: 0) != 0) {
            goto '__ci_bb_171
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_171 {
        goto '__ci_bb_167
    }

    '__ci_bb_172 {
        (__local_range__goto_1577_13 = __local_range__goto_1577_13 + ((2 as isize) as usize))
        goto '__ci_bb_165
    }

    '__ci_bb_173 {
        goto '__ci_bb_176
    }

    '__ci_bb_174 {
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_179
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_175 {
        goto '__ci_bb_164
    }

    '__ci_bb_176 {
        goto '__ci_bb_177
    }

    '__ci_bb_177 {
        if (0 != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_178 {
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 9)
        goto '__ci_bb_175
    }

    '__ci_bb_179 {
        goto '__ci_bb_181
    }

    '__ci_bb_180 {
        goto '__ci_bb_184
    }

    '__ci_bb_181 {
        goto '__ci_bb_182
    }

    '__ci_bb_182 {
        if (0 != 0) {
            goto '__ci_bb_181
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_183 {
        (__local_should_flip_negation__goto_1074_6 = 1)
        (__local_range__goto_1577_13 = __local_end__goto_1578_13)
        goto '__ci_bb_180
    }

    '__ci_bb_184 {
        if ((if __local_range__goto_1577_13 < __local_end__goto_1578_13: 1 else: 0) != 0) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_185 {
        (__local_range_start__goto_1612_16 = (unsafe __local_range__goto_1577_13[0]))
        (__local_range_end__goto_1613_16 = (unsafe __local_range__goto_1577_13[1]))
        (__local_range__goto_1577_13 = __local_range__goto_1577_13 + ((2 as isize) as usize))
        (__local_xclass_props__goto_1089_10 = __local_xclass_props__goto_1089_10 | 1)
        if ((if __local_range_start__goto_1612_16 < 256: 1 else: 0) != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_186 {
        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_187 {
        (__local_range_start__goto_1612_16 = 256)
        goto '__ci_bb_188
    }

    '__ci_bb_188 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_189 {
        if (__local_utf__goto_1081_6 != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_190 {
        if (__local_utf__goto_1081_6 != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_191 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 1)
        if ((if __local_range_start__goto_1612_16 < __local_range_end__goto_1613_16: 1 else: 0) != 0) {
            goto '__ci_bb_193
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_192 {
        (__ci_expr_ternary_26 = 0)
        if ((if __local_range_start__goto_1612_16 < __local_range_end__goto_1613_16: 1 else: 0) != 0) {
            (__ci_expr_ternary_26 = 3)
        } else {
            (__ci_expr_ternary_26 = 2)
        }
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + __ci_expr_ternary_26)
        goto '__ci_bb_184
    }

    '__ci_bb_193 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + _pcre2_ord2utf_8(__local_range_start__goto_1612_16, __local_class_uchardata__goto_1090_14))
        goto '__ci_bb_194
    }

    '__ci_bb_194 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + _pcre2_ord2utf_8(__local_range_end__goto_1613_16, __local_class_uchardata__goto_1090_14))
        goto '__ci_bb_184
    }

    '__ci_bb_195 {
        if ((if __local_range_start__goto_1612_16 < __local_range_end__goto_1613_16: 1 else: 0) != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_196 {
        goto '__ci_bb_184
    }

    '__ci_bb_197 {
        (__ci_expr_old_27 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_27) = 2)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + (_pcre2_ord2utf_8(__local_range_start__goto_1612_16, __local_class_uchardata__goto_1090_14) as usize))
        goto '__ci_bb_199
    }

    '__ci_bb_198 {
        (__ci_expr_old_28 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_28) = 1)
        goto '__ci_bb_199
    }

    '__ci_bb_199 {
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + (_pcre2_ord2utf_8(__local_range_end__goto_1613_16, __local_class_uchardata__goto_1090_14) as usize))
        goto '__ci_bb_184
    }

    '__ci_bb_200 {
        (&raw const (unsafe *__param_cb.cx).memctl as *const pcre2_memctl).free(__local_cranges__goto_1091_15, (&raw const (unsafe *__param_cb.cx).memctl as *const pcre2_memctl).memory_data)
        goto '__ci_bb_201
    }

    '__ci_bb_201 {
        goto '__ci_bb_175
    }

    '__ci_bb_202 {
        (__local_previous__goto_1703_16 = __local_code__goto_1073_14)
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_204
        } else {
            goto '__ci_bb_205
        }
    }

    '__ci_bb_203 {
        if (__param_negate_class != 0) {
            goto '__ci_bb_236
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_204 {
        (__ci_expr_old_29 = __local_class_uchardata__goto_1090_14)
        (__local_class_uchardata__goto_1090_14 = __local_class_uchardata__goto_1090_14 + 1)
        ((unsafe *__ci_expr_old_29) = 0)
        goto '__ci_bb_205
    }

    '__ci_bb_205 {
        (__ci_expr_old_30 = __local_code__goto_1073_14)
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + 1)
        ((unsafe *__ci_expr_old_30) = 112)
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + ((2 as isize) as usize))
        (__ci_expr_ternary_31 = 0)
        if (__param_negate_class != 0) {
            (__ci_expr_ternary_31 = 1)
        } else {
            (__ci_expr_ternary_31 = 0)
        }
        ((unsafe *__local_code__goto_1073_14) = __ci_expr_ternary_31)
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_207
        }
    }

    '__ci_bb_206 {
        ((unsafe *__local_code__goto_1073_14) = (unsafe *__local_code__goto_1073_14) | 4)
        goto '__ci_bb_207
    }

    '__ci_bb_207 {
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_32 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_32 = (if (if __param_has_bitmap != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            goto '__ci_bb_208
        } else {
            goto '__ci_bb_209
        }
    }

    '__ci_bb_208 {
        if (__param_negate_class != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_209 {
        (__local_code__goto_1073_14 = __local_class_uchardata__goto_1090_14)
        goto '__ci_bb_210
    }

    '__ci_bb_210 {
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_222
        } else {
            goto '__ci_bb_223
        }
    }

    '__ci_bb_211 {
        (__local_classwords__goto_1719_17 = ((&raw const (unsafe *__param_cb).classbits.classwords[0] as *mut c_uint)))
        (__local_i__goto_1720_16 = 0)
        goto '__ci_bb_213
    }

    '__ci_bb_212 {
        if ((if __param_has_bitmap == null: 1 else: 0) != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_213 {
        if ((if __local_i__goto_1720_16 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_214
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_214 {
        ((unsafe __local_classwords__goto_1719_17[__local_i__goto_1720_16]) = (~(unsafe __local_classwords__goto_1719_17[__local_i__goto_1720_16])))
        goto '__ci_bb_215
    }

    '__ci_bb_215 {
        (__local_i__goto_1720_16 = __local_i__goto_1720_16 + 1)
        goto '__ci_bb_213
    }

    '__ci_bb_216 {
        goto '__ci_bb_212
    }

    '__ci_bb_217 {
        (__ci_expr_old_33 = __local_code__goto_1073_14)
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + 1)
        ((unsafe *__ci_expr_old_33) = (unsafe *__ci_expr_old_33) | 2)
        with_memmove(((__local_code__goto_1073_14 + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize)) as *i8), (__local_code__goto_1073_14 as *i8), (((((__local_class_uchardata__goto_1090_14 as usize) -% (__local_code__goto_1073_14 as usize)) / sizeof[u8]()) * 1) as i64))
        with_memcpy((__local_code__goto_1073_14 as *i8), (__local_classbits__goto_1078_16 as *i8), (32 as i64))
        (__local_code__goto_1073_14 = __local_class_uchardata__goto_1090_14 + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
        goto '__ci_bb_219
    }

    '__ci_bb_218 {
        (__local_code__goto_1073_14 = __local_class_uchardata__goto_1090_14)
        if ((if ((__local_xclass_props__goto_1089_10 as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_219 {
        goto '__ci_bb_210
    }

    '__ci_bb_220 {
        ((unsafe *__param_has_bitmap) = 1)
        goto '__ci_bb_221
    }

    '__ci_bb_221 {
        goto '__ci_bb_219
    }

    '__ci_bb_222 {
        (__local_char_lists_size__goto_1744_12 = __local_cranges__goto_1091_15.char_lists_size)
        goto '__ci_bb_224
    }

    '__ci_bb_223 {
        ((unsafe __local_previous__goto_1703_16[1]) = ((((((((__local_code__goto_1073_14 as usize) -% (__local_previous__goto_1703_16 as usize)) / sizeof[u8]()) as c_int) as c_int) >> (8 as c_uint)) as u8)))
        ((unsafe __local_previous__goto_1703_16[(1 + 1)]) = (((((((__local_code__goto_1073_14 as usize) -% (__local_previous__goto_1703_16 as usize)) / sizeof[u8]()) as c_int) & 255) as u8)))
        goto '__ci_bb_235
    }

    '__ci_bb_224 {
        goto '__ci_bb_225
    }

    '__ci_bb_225 {
        if (0 != 0) {
            goto '__ci_bb_224
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_226 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_227
        } else {
            goto '__ci_bb_228
        }
    }

    '__ci_bb_227 {
        (__local_char_lists_size__goto_1744_12 = (((__local_char_lists_size__goto_1744_12 as c_ulong) +% (((sizeof[u32]() as c_ulong) -% (1 as c_ulong)) as c_ulong)) as c_ulong) & ((~((sizeof[u32]() as c_ulong) -% (1 as c_ulong))) as c_ulong))
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 4)
        ((unsafe *__param_cb).char_lists_size = __param_cb.char_lists_size + __local_char_lists_size__goto_1744_12)
        (__local_char_lists_size__goto_1744_12 = __local_char_lists_size__goto_1744_12 / sizeof[u8]())
        if ((if (unsafe *__param_lengthptr) > 65536: 1 else: 0) != 0) {
            (__ci_expr_logic_34 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_34 = (if (if ((65536 as c_ulong) -% ((unsafe *__param_lengthptr) as c_ulong)) < __local_char_lists_size__goto_1744_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_228 {
        goto '__ci_bb_232
    }

    '__ci_bb_229 {
        goto '__ci_bb_223
    }

    '__ci_bb_230 {
        ((unsafe *__param_errorcodeptr) = ERR20)
        return null
    }

    '__ci_bb_231 {
        goto '__ci_bb_229
    }

    '__ci_bb_232 {
        goto '__ci_bb_233
    }

    '__ci_bb_233 {
        if (0 != 0) {
            goto '__ci_bb_232
        } else {
            goto '__ci_bb_234
        }
    }

    '__ci_bb_234 {
        (__ci_expr_ternary_35 = 0)
        if (1 != 0) {
            (__ci_expr_ternary_35 = 16)
        } else {
            (__ci_expr_ternary_35 = 4096)
        }
        ((unsafe __local_code__goto_1073_14[0]) = (((__ci_expr_ternary_35 | ((__local_cranges__goto_1091_15.char_lists_types as c_int) >> (8 as c_uint))) as u8)))
        ((unsafe __local_code__goto_1073_14[1]) = ((__local_cranges__goto_1091_15.char_lists_types as u8)))
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + ((2 as isize) as usize))
        ((unsafe *__param_cb).char_lists_size = __param_cb.char_lists_size + __local_char_lists_size__goto_1744_12)
        (__local_data__goto_1773_16 = __param_cb.start_code - (__param_cb.char_lists_size as usize))
        with_memcpy((__local_data__goto_1773_16 as *i8), ((((__local_cranges__goto_1091_15 + ((1 as isize) as usize)) as *mut u8) + (__local_cranges__goto_1091_15.char_lists_start as usize)) as *i8), (__local_char_lists_size__goto_1744_12 as i64))
        (__local_char_lists_size__goto_1744_12 = __param_cb.char_lists_size)
        ((unsafe __local_code__goto_1073_14[0]) = (((((((__local_char_lists_size__goto_1744_12 as c_ulong) >> (1 as c_uint)) as c_uint) as c_uint) >> (8 as c_uint)) as u8)))
        ((unsafe __local_code__goto_1073_14[(0 + 1)]) = (((((((__local_char_lists_size__goto_1744_12 as c_ulong) >> (1 as c_uint)) as c_uint) as c_uint) & (255 as c_uint)) as u8)))
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + ((2 as isize) as usize))
        ((unsafe *__param_cb).char_lists_size = (((__local_char_lists_size__goto_1744_12 as c_ulong) +% (((sizeof[u32]() as c_ulong) -% (1 as c_ulong)) as c_ulong)) as c_ulong) & ((~((sizeof[u32]() as c_ulong) -% (1 as c_ulong))) as c_ulong))
        (&raw const (unsafe *__param_cb.cx).memctl as *const pcre2_memctl).free(__local_cranges__goto_1091_15, (&raw const (unsafe *__param_cb.cx).memctl as *const pcre2_memctl).memory_data)
        goto '__ci_bb_229
    }

    '__ci_bb_235 {
        ((unsafe *__param_pcode) = __local_code__goto_1073_14)
        return (__local_pptr__goto_1072_11 - ((1 as isize) as usize))
    }

    '__ci_bb_236 {
        (__local_classwords__goto_1839_13 = ((&raw const (unsafe *__param_cb).classbits.classwords[0] as *mut c_uint)))
        (__local_i__goto_1841_12 = 0)
        goto '__ci_bb_238
    }

    '__ci_bb_237 {
        (__ci_expr_logic_37 = 0)
        if ((if not (__local_utf__goto_1081_6 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_36 = (if (if __param_negate_class != __local_should_flip_negation__goto_1074_6: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            (__ci_expr_logic_37 = (if (if (&raw const (unsafe *__param_cb).classbits as *const class_bits_storage).classwords[0] == (~(0 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_242
        } else {
            goto '__ci_bb_243
        }
    }

    '__ci_bb_238 {
        if ((if __local_i__goto_1841_12 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_239
        } else {
            goto '__ci_bb_241
        }
    }

    '__ci_bb_239 {
        ((unsafe __local_classwords__goto_1839_13[__local_i__goto_1841_12]) = (~(unsafe __local_classwords__goto_1839_13[__local_i__goto_1841_12])))
        goto '__ci_bb_240
    }

    '__ci_bb_240 {
        (__local_i__goto_1841_12 = __local_i__goto_1841_12 + 1)
        goto '__ci_bb_238
    }

    '__ci_bb_241 {
        goto '__ci_bb_237
    }

    '__ci_bb_242 {
        (__local_classwords__goto_1847_19 = ((&raw const (unsafe *__param_cb).classbits.classwords[0] as *const c_uint)))
        (__local_i__goto_1848_7 = 0)
        goto '__ci_bb_244
    }

    '__ci_bb_243 {
        (__ci_expr_old_39 = __local_code__goto_1073_14)
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + 1)
        (__ci_expr_ternary_40 = 0)
        if ((if __param_negate_class == __local_should_flip_negation__goto_1074_6: 1 else: 0) != 0) {
            (__ci_expr_ternary_40 = OP_CLASS)
        } else {
            (__ci_expr_ternary_40 = OP_NCLASS)
        }
        ((unsafe *__ci_expr_old_39) = __ci_expr_ternary_40)
        with_memcpy((__local_code__goto_1073_14 as *i8), (__local_classbits__goto_1078_16 as *i8), (32 as i64))
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
        goto '__ci_bb_235
    }

    '__ci_bb_244 {
        if ((if __local_i__goto_1848_7 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_245
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_245 {
        if ((if (unsafe __local_classwords__goto_1847_19[__local_i__goto_1848_7]) != (~(0 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_248
        } else {
            goto '__ci_bb_249
        }
    }

    '__ci_bb_246 {
        (__local_i__goto_1848_7 = __local_i__goto_1848_7 + 1)
        goto '__ci_bb_244
    }

    '__ci_bb_247 {
        if ((if __local_i__goto_1848_7 == 8: 1 else: 0) != 0) {
            goto '__ci_bb_250
        } else {
            goto '__ci_bb_251
        }
    }

    '__ci_bb_248 {
        goto '__ci_bb_247
    }

    '__ci_bb_249 {
        goto '__ci_bb_246
    }

    '__ci_bb_250 {
        (__ci_expr_old_38 = __local_code__goto_1073_14)
        (__local_code__goto_1073_14 = __local_code__goto_1073_14 + 1)
        ((unsafe *__ci_expr_old_38) = 13)
        goto '__ci_bb_235
    }

    '__ci_bb_251 {
        goto '__ci_bb_243
    }

}

fn _pcre2_compile_class_nested_8(__param_options: c_uint, __param_xoptions: c_uint, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_errorcodeptr: *mut c_int, __param_cb: *mut compile_block_8, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_context: eclass_context

    var __local_op_info: eclass_op_info

    var __local_previous_length: c_ulong = with 0 as __ci_expr_seq_11 {
        var __ci_expr_ternary_0: c_ulong = 0
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (unsafe *__param_lengthptr))
        } else {
            (__ci_expr_ternary_0 = 0)
        }
        __ci_expr_ternary_0
    }

    var __local_code: *mut u8 = (unsafe *__param_pcode)

    var __local_previous: *mut u8

    var __local_allbitsone: c_int = 1

    (__local_context.needs_bitmap = 0)

    (__local_context.options = __param_options)

    (__local_context.xoptions = __param_xoptions)

    (__local_context.errorcodeptr = __param_errorcodeptr)

    (__local_context.cb = __param_cb)

    (__local_previous = __local_code)

    var __ci_expr_old_1: *mut u8 = __local_code

    (__local_code = __local_code + 1)

    ((unsafe *__ci_expr_old_1) = 113)


    (__local_code = __local_code + ((2 as isize) as usize))

    var __ci_expr_old_2: *mut u8 = __local_code

    (__local_code = __local_code + 1)

    ((unsafe *__ci_expr_old_2) = 0)


    if ((if not (compile_eclass_nested((&raw mut __local_context as *mut eclass_context), 0, __param_pptr, (&raw mut __local_code as *mut *mut u8), (&raw mut __local_op_info as *mut eclass_op_info), __param_lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    if ((if __param_lengthptr != null: 1 else: 0) != 0) {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + (((__local_code as usize) -% (__local_previous as usize)) / sizeof[u8]()))

        (__local_code = __local_previous)

    }

    var __local_i: c_int = 0

    while ((if __local_i < 8: 1 else: 0) != 0) {
        if ((if (&raw const __local_op_info.bits as *const class_bits_storage).classwords[__local_i] != 4294967295: 1 else: 0) != 0) {
            (__local_allbitsone = 0)

            break

        }

        (__local_i = __local_i + 1)

    }


    if ((if (&raw const __local_op_info as *const eclass_op_info).op_single_type != 0: 1 else: 0) != 0) {
        (__local_code = __local_previous)

        var __ci_expr_logic_3: c_int = 0

        if ((if (&raw const __local_op_info as *const eclass_op_info).op_single_type == 6: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if __local_allbitsone != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) - 1)
            }

            var __ci_expr_old_4: *mut u8 = __local_code

            (__local_code = __local_code + 1)

            ((unsafe *__ci_expr_old_4) = 13)


        } else {
            var __ci_expr_logic_5: c_int

            if ((if (&raw const __local_op_info as *const eclass_op_info).op_single_type == 6: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if (&raw const __local_op_info as *const eclass_op_info).op_single_type == 7: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                var __local_required_len: c_ulong = ((1 as c_ulong) +% (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as c_ulong))

                if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                    if ((if __local_required_len > (((unsafe *__param_lengthptr) as c_ulong) -% (__local_previous_length as c_ulong)): 1 else: 0) != 0) {
                        ((unsafe *__param_lengthptr) = ((__local_previous_length as c_ulong) +% (__local_required_len as c_ulong)))
                    }

                }

                if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                    ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) - __local_required_len)
                }

                var __ci_expr_old_6: *mut u8 = __local_code

                (__local_code = __local_code + 1)

                var __ci_expr_ternary_7: c_int = 0

                if ((if (&raw const __local_op_info as *const eclass_op_info).op_single_type == 6: 1 else: 0) != 0) {
                    (__ci_expr_ternary_7 = OP_NCLASS)
                } else {
                    (__ci_expr_ternary_7 = OP_CLASS)
                }

                ((unsafe *__ci_expr_old_6) = __ci_expr_ternary_7)


                with_memcpy((__local_code as *i8), ((&(unsafe (&raw const __local_op_info.bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), (32 as i64))

                (__local_code = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))

            } else {
                var __local_need_map: c_int = (&raw const __local_context as *const eclass_context).needs_bitmap

                var __local_required_len_1: c_ulong

                do {
                    0
                } while (0 != 0)

                var __ci_expr_ternary_8: c_ulong = 0

                if (__local_need_map != 0) {
                    (__ci_expr_ternary_8 = (32 as c_ulong) / (sizeof[u8]() as c_ulong))
                } else {
                    (__ci_expr_ternary_8 = 0)
                }

                (__local_required_len_1 = (((&raw const __local_op_info as *const eclass_op_info).length as c_ulong) +% (__ci_expr_ternary_8 as c_ulong)))


                if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                    if ((if __local_required_len_1 > (((unsafe *__param_lengthptr) as c_ulong) -% (__local_previous_length as c_ulong)): 1 else: 0) != 0) {
                        ((unsafe *__param_lengthptr) = ((__local_previous_length as c_ulong) +% (__local_required_len_1 as c_ulong)))
                    }

                    ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) - 4)

                    var __ci_expr_old_9: *mut u8 = __local_code

                    (__local_code = __local_code + 1)

                    ((unsafe *__ci_expr_old_9) = 112)


                    ((unsafe __local_code[0]) = ((((((1 + 2) + 1) as c_int) >> (8 as c_uint)) as u8)))

                    ((unsafe __local_code[(0 + 1)]) = (((((1 + 2) + 1) & 255) as u8)))


                    (__local_code = __local_code + ((2 as isize) as usize))

                    var __ci_expr_old_10: *mut u8 = __local_code

                    (__local_code = __local_code + 1)

                    ((unsafe *__ci_expr_old_10) = 0)


                } else {
                    var __local_rest: *mut u8

                    var __local_rest_len: c_ulong

                    var __local_flags: u8

                    do {
                        0
                    } while (0 != 0)

                    (__local_rest = (((&raw const __local_op_info as *const eclass_op_info).code_start + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))

                    (__local_rest_len = ((((&raw const __local_op_info as *const eclass_op_info).code_start + ((&raw const __local_op_info as *const eclass_op_info).length as usize)) as usize) -% (__local_rest as usize)) / sizeof[u8]())

                    (__local_flags = (unsafe (&raw const __local_op_info as *const eclass_op_info).code_start[(1 + 2)]))

                    do {
                        0
                    } while (0 != 0)

                    var __ci_expr_ternary_11: c_ulong = 0

                    if (__local_need_map != 0) {
                        (__ci_expr_ternary_11 = (32 as c_ulong) / (sizeof[u8]() as c_ulong))
                    } else {
                        (__ci_expr_ternary_11 = 0)
                    }

                    with_memmove((((((__local_code + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize)) + (__ci_expr_ternary_11 as usize)) as *i8), (__local_rest as *i8), (((__local_rest_len as c_ulong) *% (1 as c_ulong)) as i64))


                    var __ci_expr_old_12: *mut u8 = __local_code

                    (__local_code = __local_code + 1)

                    ((unsafe *__ci_expr_old_12) = 112)


                    ((unsafe __local_code[0]) = (((((__local_required_len_1 as c_int) as c_int) >> (8 as c_uint)) as u8)))

                    ((unsafe __local_code[(0 + 1)]) = ((((__local_required_len_1 as c_int) & 255) as u8)))


                    (__local_code = __local_code + ((2 as isize) as usize))

                    var __ci_expr_old_13: *mut u8 = __local_code

                    (__local_code = __local_code + 1)

                    var __ci_expr_ternary_14: c_int = 0

                    if (__local_need_map != 0) {
                        (__ci_expr_ternary_14 = 2)
                    } else {
                        (__ci_expr_ternary_14 = 0)
                    }

                    ((unsafe *__ci_expr_old_13) = (__local_flags as c_int) | __ci_expr_ternary_14)


                    if (__local_need_map != 0) {
                        with_memcpy((__local_code as *i8), ((&(unsafe (&raw const __local_op_info.bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), (32 as i64))

                        (__local_code = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))

                    }

                    (__local_code = __local_code + (__local_rest_len as usize))

                }

            }

        }


    } else {
        var __local_need_map_1: c_int = (&raw const __local_context as *const eclass_context).needs_bitmap

        var __local_required_len_2: c_ulong = with 0 as __ci_expr_seq_176 {
            var __ci_expr_ternary_15: c_ulong = 0
            if (__local_need_map_1 != 0) {
                (__ci_expr_ternary_15 = (32 as c_ulong) / (sizeof[u8]() as c_ulong))
            } else {
                (__ci_expr_ternary_15 = 0)
            }
            ((((4 as c_ulong) +% (__ci_expr_ternary_15 as c_ulong)) as c_ulong) +% ((&raw const __local_op_info as *const eclass_op_info).length as c_ulong))
        }

        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            if ((if __local_required_len_2 > (((unsafe *__param_lengthptr) as c_ulong) -% (__local_previous_length as c_ulong)): 1 else: 0) != 0) {
                ((unsafe *__param_lengthptr) = ((__local_previous_length as c_ulong) +% (__local_required_len_2 as c_ulong)))
            }

            ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) - 4)

            var __ci_expr_old_16: *mut u8 = __local_code

            (__local_code = __local_code + 1)

            ((unsafe *__ci_expr_old_16) = 113)


            ((unsafe __local_code[0]) = ((((((1 + 2) + 1) as c_int) >> (8 as c_uint)) as u8)))

            ((unsafe __local_code[(0 + 1)]) = (((((1 + 2) + 1) & 255) as u8)))


            (__local_code = __local_code + ((2 as isize) as usize))

            var __ci_expr_old_17: *mut u8 = __local_code

            (__local_code = __local_code + 1)

            ((unsafe *__ci_expr_old_17) = 0)


        } else {
            if (__local_need_map_1 != 0) {
                var __local_map_start: *mut u8 = (((__local_previous + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))

                ((unsafe __local_previous[(1 + 2)]) = (unsafe __local_previous[(1 + 2)]) | 1)

                with_memmove(((__local_map_start + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize)) as *i8), (__local_map_start as *i8), (((((__local_code as usize) -% (__local_map_start as usize)) / sizeof[u8]()) * 1) as i64))

                with_memcpy((__local_map_start as *i8), ((&(unsafe (&raw const __local_op_info.bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), (32 as i64))

                (__local_code = __local_code + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))

            }

            ((unsafe __local_previous[1]) = ((((((((__local_code as usize) -% (__local_previous as usize)) / sizeof[u8]()) as c_int) as c_int) >> (8 as c_uint)) as u8)))

            ((unsafe __local_previous[(1 + 1)]) = (((((((__local_code as usize) -% (__local_previous as usize)) / sizeof[u8]()) as c_int) & 255) as u8)))


        }

    }

    ((unsafe *__param_pcode) = __local_code)

    return 1

}

fn do_heapify(__param_buffer: *mut c_uint, __param_size: c_ulong, __param_i: c_ulong) {
    var __local_i = __param_i
    var __local_max: c_ulong

    var __local_left: c_ulong

    var __local_right: c_ulong

    var __local_tmp1: c_uint

    var __local_tmp2: c_uint


    while (1 != 0) {
        (__local_max = __local_i)

        (__local_left = ((((__local_i as c_ulong) << (1 as c_uint)) as c_ulong) +% (2 as c_ulong)))

        (__local_right = ((__local_left as c_ulong) +% (2 as c_ulong)))

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_left < __param_size: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe __param_buffer[__local_left]) > (unsafe __param_buffer[__local_max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_max = __local_left)
        }


        var __ci_expr_logic_1: c_int = 0

        if ((if __local_right < __param_size: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe __param_buffer[__local_right]) > (unsafe __param_buffer[__local_max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_max = __local_right)
        }


        if ((if __local_i == __local_max: 1 else: 0) != 0) {
            return
        }

        (__local_tmp1 = (unsafe __param_buffer[__local_i]))

        (__local_tmp2 = (unsafe __param_buffer[((__local_i as c_ulong) +% (1 as c_ulong))]))

        ((unsafe __param_buffer[__local_i]) = (unsafe __param_buffer[__local_max]))

        ((unsafe __param_buffer[((__local_i as c_ulong) +% (1 as c_ulong))]) = (unsafe __param_buffer[((__local_max as c_ulong) +% (1 as c_ulong))]))

        ((unsafe __param_buffer[__local_max]) = __local_tmp1)

        ((unsafe __param_buffer[((__local_max as c_ulong) +% (1 as c_ulong))]) = __local_tmp2)

        (__local_i = __local_max)

    }

}

fn get_nocase_range(__param_c: c_uint) -> *const c_uint {
    var __local_left: c_uint = 0

    var __local_right: c_uint = _pcre2_ucd_nocase_ranges_size_8

    var __local_middle: c_uint

    if ((if __param_c > 1114111: 1 else: 0) != 0) {
        return ((&_pcre2_ucd_nocase_ranges_8[0] as *const c_uint) + (__local_right as usize))
    }

    while (1 != 0) {
        (__local_middle = (((((__local_left as c_uint) +% (__local_right as c_uint)) as c_uint) >> (1 as c_uint)) as c_uint) | (1 as c_uint))

        if ((if _pcre2_ucd_nocase_ranges_8[__local_middle] <= __param_c: 1 else: 0) != 0) {
            (__local_left = ((__local_middle as c_uint) +% (1 as c_uint)))
        } else {
            var __ci_expr_logic_0: c_int = 0

            if ((if __local_middle > 1: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if _pcre2_ucd_nocase_ranges_8[((__local_middle as c_uint) -% (2 as c_uint))] > __param_c: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (__local_right = ((__local_middle as c_uint) -% (1 as c_uint)))
            } else {
                return ((&_pcre2_ucd_nocase_ranges_8[0] as *const c_uint) + (((__local_middle as c_uint) -% (1 as c_uint)) as usize))
            }

        }

    }

}

fn utf_caseless_extend(__param_start: c_uint, __param_end: c_uint, __param_options: c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var __local_buffer = __param_buffer
    var __local_new_start: c_uint = __param_start

    var __local_new_end: c_uint = __param_end

    var __local_c: c_uint = __param_start

    var __local_list: *const c_uint

    var __local_tmp: [3]c_uint

    var __local_result: c_ulong = 2

    var __local_skip_range: *const c_uint = get_nocase_range(__local_c)

    var __local_skip_start: c_uint = (unsafe __local_skip_range[0])

    do {
        0
    } while (0 != 0)

    while ((if __local_c <= __param_end: 1 else: 0) != 0) {
        var __local_co: c_uint

        if ((if __local_c > __local_skip_start: 1 else: 0) != 0) {
            (__local_c = (unsafe __local_skip_range[1]))

            (__local_skip_range = __local_skip_range + ((2 as isize) as usize))

            (__local_skip_start = (unsafe __local_skip_range[0]))

            continue

        }

        var __ci_expr_logic_1: c_int = 0

        if ((if ((__param_options as c_uint) & (12 as c_uint)) == 8: 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int

            if ((if ((__local_c as c_uint) | (32 as c_uint)) == 105: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if ((__local_c as c_uint) | (1 as c_uint)) == 305: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_1 != 0) {
            var __ci_expr_ternary_3: c_int = 0

            var __ci_expr_logic_2: c_int

            if ((if __local_c == 105: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if __local_c == 304: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_ternary_3 = 0)
            } else {
                (__ci_expr_ternary_3 = 3)
            }

            (__local_co = ((_pcre2_ucd_turkish_dotted_i_caseset_8 as c_uint) +% (__ci_expr_ternary_3 as c_uint)))


        } else {
            var __ci_expr_logic_5: c_int = 0

            var __ci_expr_logic_4: c_int = 0

            (__local_co = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize)).caseset)

            if ((if __local_co != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if ((__param_options as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if (if _pcre2_ucd_caseless_sets_8[__local_co] < 128: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (__local_co = 0)

            }

        }


        if ((if __local_co != 0: 1 else: 0) != 0) {
            (__local_list = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (__local_co as usize))
        } else {
            (__local_co = ((((__local_c as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))

            (__local_list = (&__local_tmp[0] as *const c_uint))

            (__local_tmp[0] = __local_c)

            (__local_tmp[1] = 4294967295)

            if ((if __local_co != __local_c: 1 else: 0) != 0) {
                (__local_tmp[1] = __local_co)

                (__local_tmp[2] = 4294967295)

            }

        }

        (__local_c = __local_c + 1)

        do {
            if ((if (unsafe *__local_list) < __local_new_start: 1 else: 0) != 0) {
                if ((if (((unsafe *__local_list) as c_uint) +% (1 as c_uint)) == __local_new_start: 1 else: 0) != 0) {
                    (__local_new_start = __local_new_start - 1)

                    continue

                }

            } else {
                if ((if (unsafe *__local_list) > __local_new_end: 1 else: 0) != 0) {
                    if ((if (((unsafe *__local_list) as c_uint) -% (1 as c_uint)) == __local_new_end: 1 else: 0) != 0) {
                        (__local_new_end = __local_new_end + 1)

                        continue

                    }

                } else {
                    continue
                }
            }

            (__local_result = __local_result + 2)

            if ((if __local_buffer != null: 1 else: 0) != 0) {
                ((unsafe __local_buffer[0]) = (unsafe *__local_list))

                ((unsafe __local_buffer[1]) = (unsafe *__local_list))

                (__local_buffer = __local_buffer + ((2 as isize) as usize))

            }

        } while { (__local_list = __local_list + 1); ((if (unsafe *__local_list) != 4294967295: 1 else: 0) != 0) }

    }

    if ((if __local_buffer != null: 1 else: 0) != 0) {
        ((unsafe __local_buffer[0]) = __local_new_start)

        ((unsafe __local_buffer[1]) = __local_new_end)

        (__local_buffer = __local_buffer + ((2 as isize) as usize))

        __local_buffer

    }

    return __local_result

}

fn append_char_list(__param_p: *const c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var __local_p = __param_p
    var __local_buffer = __param_buffer
    var __local_n: *const c_uint

    var __local_result: c_ulong = 0

    while ((if (unsafe *__local_p) != 4294967295: 1 else: 0) != 0) {
        (__local_n = __local_p)

        while ((if (unsafe __local_n[0]) == (((unsafe __local_n[1]) as c_uint) -% (1 as c_uint)): 1 else: 0) != 0) {
            (__local_n = __local_n + 1)
        }

        do {
            0
        } while (0 != 0)

        if ((if __local_buffer != null: 1 else: 0) != 0) {
            ((unsafe __local_buffer[0]) = (unsafe *__local_p))

            ((unsafe __local_buffer[1]) = (unsafe *__local_n))

            (__local_buffer = __local_buffer + ((2 as isize) as usize))

        }

        (__local_result = __local_result + 2)

        (__local_p = __local_n + ((1 as isize) as usize))

    }

    return __local_result

}

fn get_highest_char(__param_options: c_uint) -> c_uint {
    __param_options

    return 1114111

}

fn append_negated_char_list(__param_p: *const c_uint, __param_options: c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var __local_p = __param_p
    var __local_buffer = __param_buffer
    var __local_n: *const c_uint

    var __local_start: c_uint = 0

    var __local_result: c_ulong = 2

    do {
        0
    } while (0 != 0)

    while ((if (unsafe *__local_p) != 4294967295: 1 else: 0) != 0) {
        (__local_n = __local_p)

        while ((if (unsafe __local_n[0]) == (((unsafe __local_n[1]) as c_uint) -% (1 as c_uint)): 1 else: 0) != 0) {
            (__local_n = __local_n + 1)
        }

        do {
            0
        } while (0 != 0)

        if ((if __local_buffer != null: 1 else: 0) != 0) {
            ((unsafe __local_buffer[0]) = __local_start)

            ((unsafe __local_buffer[1]) = (((unsafe *__local_p) as c_uint) -% (1 as c_uint)))

            (__local_buffer = __local_buffer + ((2 as isize) as usize))

        }

        (__local_result = __local_result + 2)

        (__local_start = (((unsafe *__local_n) as c_uint) +% (1 as c_uint)))

        (__local_p = __local_n + ((1 as isize) as usize))

    }

    if ((if __local_buffer != null: 1 else: 0) != 0) {
        ((unsafe __local_buffer[0]) = __local_start)

        ((unsafe __local_buffer[1]) = get_highest_char(__param_options))

        (__local_buffer = __local_buffer + ((2 as isize) as usize))

        __local_buffer

    }

    return __local_result

}

fn append_non_ascii_range(__param_options: c_uint, __param_buffer: *mut c_uint) -> *mut c_uint {
    if ((if __param_buffer == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe __param_buffer[0]) = 256)

    ((unsafe __param_buffer[1]) = get_highest_char(__param_options))

    return (__param_buffer + ((2 as isize) as usize))

}

fn parse_class(__param_ptr: *mut c_uint, __param_options: c_uint, __param_buffer: *mut c_uint) -> c_ulong {
    var __local_ptr = __param_ptr
    var __local_buffer = __param_buffer
    var __local_total_size: c_ulong = 0

    var __local_size: c_ulong

    var __local_meta_arg: c_uint

    var __local_start_char: c_uint

    while (1 != 0) {
        var __ci_expr_switch_continue_2: i32 = 0

        while true {
            match (((unsafe *__local_ptr) as c_uint) & ((4294901760 as c_uint) as c_uint)) {
                2149318656 => {
                    (__local_meta_arg = ((unsafe *__local_ptr) as c_uint) & (65535 as c_uint))

                    while true {
                        match __local_meta_arg {
                            6 => {
                                (__local_buffer = append_non_ascii_range(__param_options, __local_buffer))

                                (__local_total_size = __local_total_size + 2)

                            },
                            10 => {
                                (__local_buffer = append_non_ascii_range(__param_options, __local_buffer))

                                (__local_total_size = __local_total_size + 2)

                            },
                            8 => {
                                (__local_buffer = append_non_ascii_range(__param_options, __local_buffer))

                                (__local_total_size = __local_total_size + 2)

                            },
                            19 => {
                                (__local_size = append_char_list((&_pcre2_hspace_list_8[0] as *mut c_uint), __local_buffer))

                                (__local_total_size = __local_total_size + __local_size)

                                if ((if __local_buffer != null: 1 else: 0) != 0) {
                                    (__local_buffer = __local_buffer + (__local_size as usize))
                                }

                            },
                            18 => {
                                (__local_size = append_negated_char_list((&_pcre2_hspace_list_8[0] as *mut c_uint), __param_options, __local_buffer))

                                (__local_total_size = __local_total_size + __local_size)

                                if ((if __local_buffer != null: 1 else: 0) != 0) {
                                    (__local_buffer = __local_buffer + (__local_size as usize))
                                }

                            },
                            21 => {
                                (__local_size = append_char_list((&_pcre2_vspace_list_8[0] as *mut c_uint), __local_buffer))

                                (__local_total_size = __local_total_size + __local_size)

                                if ((if __local_buffer != null: 1 else: 0) != 0) {
                                    (__local_buffer = __local_buffer + (__local_size as usize))
                                }

                            },
                            20 => {
                                (__local_size = append_negated_char_list((&_pcre2_vspace_list_8[0] as *mut c_uint), __param_options, __local_buffer))

                                (__local_total_size = __local_total_size + __local_size)

                                if ((if __local_buffer != null: 1 else: 0) != 0) {
                                    (__local_buffer = __local_buffer + (__local_size as usize))
                                }

                            },
                            16 => {
                                (__local_ptr = __local_ptr + 1)

                                var __ci_expr_logic_0: c_int = 0

                                if ((if __local_meta_arg == 16: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (((unsafe *__local_ptr) as c_uint) >> (16 as c_uint)) == 13: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    if ((if __local_buffer != null: 1 else: 0) != 0) {
                                        ((unsafe __local_buffer[0]) = 0)

                                        ((unsafe __local_buffer[1]) = get_highest_char(__param_options))

                                        (__local_buffer = __local_buffer + ((2 as isize) as usize))

                                    }

                                    (__local_total_size = __local_total_size + 2)

                                }


                            },
                            15 => {
                                (__local_ptr = __local_ptr + 1)

                                var __ci_expr_logic_0: c_int = 0

                                if ((if __local_meta_arg == 16: 1 else: 0) != 0) {
                                    (__ci_expr_logic_0 = (if (if (((unsafe *__local_ptr) as c_uint) >> (16 as c_uint)) == 13: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_0 != 0) {
                                    if ((if __local_buffer != null: 1 else: 0) != 0) {
                                        ((unsafe __local_buffer[0]) = 0)

                                        ((unsafe __local_buffer[1]) = get_highest_char(__param_options))

                                        (__local_buffer = __local_buffer + ((2 as isize) as usize))

                                    }

                                    (__local_total_size = __local_total_size + 2)

                                }


                            },
                        }

                        break

                    }

                    (__local_ptr = __local_ptr + 1)

                    (__ci_expr_switch_continue_2 = 1)

                    break


                },
                2149646336 => {
                    (__local_buffer = append_non_ascii_range(__param_options, __local_buffer))

                    (__local_total_size = __local_total_size + 2)

                    (__local_ptr = __local_ptr + ((2 as isize) as usize))

                    (__ci_expr_switch_continue_2 = 1)

                    break


                },
                2149580800 => {
                    (__local_ptr = __local_ptr + ((2 as isize) as usize))

                    (__ci_expr_switch_continue_2 = 1)

                    break


                },
                2147811328 => {
                    (__local_ptr = __local_ptr + 1)
                },
                _ => {
                    if ((if (unsafe *__local_ptr) >= 2147483648: 1 else: 0) != 0) {
                        return __local_total_size
                    }
                },
            }

            break

        }

        if (__ci_expr_switch_continue_2 != 0) {
            continue
        }


        (__local_start_char = (unsafe *__local_ptr))

        var __ci_expr_logic_3: c_int

        if ((if (unsafe __local_ptr[1]) == 2149777408: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if (unsafe __local_ptr[1]) == 2149711872: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__local_ptr = __local_ptr + ((2 as isize) as usize))

            do {
                0
            } while (0 != 0)

            if ((if (unsafe *__local_ptr) == 2147811328: 1 else: 0) != 0) {
                (__local_ptr = __local_ptr + 1)
            }

        }


        if (((__param_options as c_uint) & (2 as c_uint)) != 0) {
            var __ci_expr_old_4: *mut c_uint = __local_ptr

            (__local_ptr = __local_ptr + 1)

            (__local_size = utf_caseless_extend(__local_start_char, (unsafe *__ci_expr_old_4), __param_options, __local_buffer))


            if ((if __local_buffer != null: 1 else: 0) != 0) {
                (__local_buffer = __local_buffer + (__local_size as usize))
            }

            (__local_total_size = __local_total_size + __local_size)

            continue

        }

        if ((if __local_buffer != null: 1 else: 0) != 0) {
            ((unsafe __local_buffer[0]) = __local_start_char)

            ((unsafe __local_buffer[1]) = (unsafe *__local_ptr))

            (__local_buffer = __local_buffer + ((2 as isize) as usize))

        }

        (__local_ptr = __local_ptr + 1)

        (__local_total_size = __local_total_size + 2)

    }

    return __local_total_size

}

fn compile_optimize_class(__param_start_ptr: *mut c_uint, __param_options: c_uint, __param_xoptions: c_uint, __param_cb: *mut compile_block_8) -> *mut class_ranges {
    var __local_cranges: *mut class_ranges

    var __local_ptr: *mut c_uint

    var __local_buffer: *mut c_uint

    var __local_dst: *mut c_uint

    var __local_class_options: c_uint = 0

    var __local_range_list_size: c_ulong = 0

    var __local_total_size: c_ulong

    var __local_i: c_ulong


    var __local_tmp1: c_uint

    var __local_tmp2: c_uint


    var __local_char_list_next: *const c_uint

    var __local_next_char: *mut c_ushort

    var __local_char_list_start: c_uint

    var __local_char_list_end: c_uint


    var __local_range_start: c_uint

    var __local_range_end: c_uint


    if (((__param_options as c_uint) & (524288 as c_uint)) != 0) {
        (__local_class_options = __local_class_options | 1)
    }

    var __ci_expr_logic_0: c_int = 0

    if (((__param_options as c_uint) & (8 as c_uint)) != 0) {
        (__ci_expr_logic_0 = (if ((__param_options as c_uint) & (((524288 as c_uint) | (131072 as c_uint)) as c_uint)) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_class_options = __local_class_options | 2)
    }


    if (((__param_xoptions as c_uint) & (128 as c_uint)) != 0) {
        (__local_class_options = __local_class_options | 4)
    }

    if (((__param_xoptions as c_uint) & (65536 as c_uint)) != 0) {
        (__local_class_options = __local_class_options | 8)
    }

    (__local_range_list_size = parse_class(__param_start_ptr, __local_class_options, null))

    do {
        0
    } while (0 != 0)

    var __ci_expr_ternary_1: c_int = 0

    if ((if __local_range_list_size >= 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = 3)
    } else {
        (__ci_expr_ternary_1 = 0)
    }

    (__local_total_size = ((__local_range_list_size as c_ulong) +% (__ci_expr_ternary_1 as c_ulong)))


    (__local_cranges = (((&raw const (unsafe *__param_cb.cx).memctl as *const pcre2_memctl).malloc(((sizeof[class_ranges]() as c_ulong) +% (((__local_total_size as c_ulong) *% (sizeof[u32]() as c_ulong)) as c_ulong)), (&raw const (unsafe *__param_cb.cx).memctl as *const pcre2_memctl).memory_data) as *mut class_ranges)))

    if ((if __local_cranges == null: 1 else: 0) != 0) {
        return null
    }

    ((unsafe *__local_cranges).header.next = ((null as *mut compile_data)))

    ((unsafe *__local_cranges).range_list_size = ((__local_range_list_size as c_ushort)))

    ((unsafe *__local_cranges).char_lists_types = 0)

    ((unsafe *__local_cranges).char_lists_size = 0)

    ((unsafe *__local_cranges).char_lists_start = 0)

    if ((if __local_range_list_size == 0: 1 else: 0) != 0) {
        return __local_cranges
    }

    (__local_buffer = (((__local_cranges + ((1 as isize) as usize)) as *mut c_uint)))

    parse_class(__param_start_ptr, __local_class_options, __local_buffer)

    if ((if __local_range_list_size <= 2: 1 else: 0) != 0) {
        return __local_cranges
    }

    (__local_i = (((((__local_range_list_size as c_ulong) >> (2 as c_uint)) as c_ulong) -% (1 as c_ulong)) as c_ulong) << (1 as c_uint))

    while (1 != 0) {
        do_heapify(__local_buffer, __local_range_list_size, __local_i)

        if ((if __local_i == 0: 1 else: 0) != 0) {
            break
        }

        (__local_i = __local_i - 2)

    }

    (__local_i = ((__local_range_list_size as c_ulong) -% (2 as c_ulong)))

    while (1 != 0) {
        (__local_tmp1 = (unsafe __local_buffer[__local_i]))

        (__local_tmp2 = (unsafe __local_buffer[((__local_i as c_ulong) +% (1 as c_ulong))]))

        ((unsafe __local_buffer[__local_i]) = (unsafe __local_buffer[0]))

        ((unsafe __local_buffer[((__local_i as c_ulong) +% (1 as c_ulong))]) = (unsafe __local_buffer[1]))

        ((unsafe __local_buffer[0]) = __local_tmp1)

        ((unsafe __local_buffer[1]) = __local_tmp2)

        do_heapify(__local_buffer, __local_i, 0)

        if ((if __local_i == 0: 1 else: 0) != 0) {
            break
        }

        (__local_i = __local_i - 2)

    }

    (__local_dst = __local_buffer)

    (__local_ptr = __local_buffer + ((2 as isize) as usize))

    (__local_range_list_size = __local_range_list_size - 2)

    while true {
        var __ci_expr_logic_2: c_int = 0

        if ((if __local_range_list_size > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (unsafe __local_dst[1]) != (~(0 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_2 != 0)) {
            break
        }

        if ((if (((unsafe __local_dst[1]) as c_uint) +% (1 as c_uint)) < (unsafe __local_ptr[0]): 1 else: 0) != 0) {
            (__local_dst = __local_dst + ((2 as isize) as usize))

            ((unsafe __local_dst[0]) = (unsafe __local_ptr[0]))

            ((unsafe __local_dst[1]) = (unsafe __local_ptr[1]))

        } else {
            if ((if (unsafe __local_dst[1]) < (unsafe __local_ptr[1]): 1 else: 0) != 0) {
                ((unsafe __local_dst[1]) = (unsafe __local_ptr[1]))
            }
        }

        (__local_ptr = __local_ptr + ((2 as isize) as usize))

        (__local_range_list_size = __local_range_list_size - 2)

    }

    do {
        0
    } while (0 != 0)

    (__local_ptr = __local_buffer)

    while true {
        var __ci_expr_logic_3: c_int = 0

        if ((if __local_ptr < __local_dst: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if (unsafe __local_ptr[1]) < 256: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_3 != 0)) {
            break
        }

        (__local_ptr = __local_ptr + ((2 as isize) as usize))

    }

    if ((if (((__local_dst as usize) -% (__local_ptr as usize)) / sizeof[c_uint]()) < 10: 1 else: 0) != 0) {
        ((unsafe *__local_cranges).range_list_size = ((((((__local_dst + ((2 as isize) as usize)) as usize) -% (__local_buffer as usize)) / sizeof[c_uint]()) as c_ushort)))

        return __local_cranges

    }

    (__local_char_list_next = (&char_list_starts[0] as *const c_uint))

    var __ci_expr_old_4: *const c_uint = __local_char_list_next

    (__local_char_list_next = __local_char_list_next + 1)

    (__local_char_list_start = (unsafe *__ci_expr_old_4))


    (__local_char_list_end = 2147483647)

    (__local_next_char = (((__local_buffer + (__local_total_size as usize)) as *mut c_ushort)))

    (__local_tmp1 = 0)

    (__local_tmp2 = 6)

    do {
        0
    } while (0 != 0)

    (__local_range_start = (unsafe __local_dst[0]))

    (__local_range_end = (unsafe __local_dst[1]))

    while (1 != 0) {
        if ((if __local_range_start >= __local_char_list_start: 1 else: 0) != 0) {
            var __ci_expr_logic_5: c_int

            if ((if __local_range_start == __local_range_end: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if __local_range_end < __local_char_list_end: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (__local_tmp1 = __local_tmp1 + 1)

                (__local_next_char = __local_next_char - 1)

                if ((if __local_char_list_start < 65536: 1 else: 0) != 0) {
                    ((unsafe *__local_next_char) = ((((((__local_range_end as c_uint) << (1 as c_uint)) as c_uint) | (1 as c_uint)) as c_ushort)))
                } else {
                    (__local_next_char = __local_next_char - 1)

                    ((unsafe *(__local_next_char as *mut c_uint)) = (((__local_range_end as c_uint) << (1 as c_uint)) as c_uint) | (1 as c_uint))

                }

            }


            if ((if __local_range_start < __local_range_end: 1 else: 0) != 0) {
                if ((if __local_range_start > __local_char_list_start: 1 else: 0) != 0) {
                    (__local_tmp1 = __local_tmp1 + 1)

                    (__local_next_char = __local_next_char - 1)

                    if ((if __local_char_list_start < 65536: 1 else: 0) != 0) {
                        ((unsafe *__local_next_char) = ((((__local_range_start as c_uint) << (1 as c_uint)) as c_ushort)))
                    } else {
                        (__local_next_char = __local_next_char - 1)

                        ((unsafe *(__local_next_char as *mut c_uint)) = (__local_range_start as c_uint) << (1 as c_uint))

                    }

                } else {
                    ((unsafe *__local_cranges).char_lists_types = __local_cranges.char_lists_types | (((4 as c_ushort) << (__local_tmp2 as c_uint)) as c_ushort))
                }

            }

            do {
                0
            } while (0 != 0)

            if ((if __local_dst > __local_buffer: 1 else: 0) != 0) {
                (__local_dst = __local_dst - ((2 as isize) as usize))

                (__local_range_start = (unsafe __local_dst[0]))

                (__local_range_end = (unsafe __local_dst[1]))

                continue

            }

            (__local_range_start = 0)

            (__local_range_end = 0)

        }

        if ((if __local_range_end >= __local_char_list_start: 1 else: 0) != 0) {
            do {
                0
            } while (0 != 0)

            if ((if __local_range_end < __local_char_list_end: 1 else: 0) != 0) {
                (__local_tmp1 = __local_tmp1 + 1)

                (__local_next_char = __local_next_char - 1)

                if ((if __local_char_list_start < 65536: 1 else: 0) != 0) {
                    ((unsafe *__local_next_char) = ((((((__local_range_end as c_uint) << (1 as c_uint)) as c_uint) | (1 as c_uint)) as c_ushort)))
                } else {
                    (__local_next_char = __local_next_char - 1)

                    ((unsafe *(__local_next_char as *mut c_uint)) = (((__local_range_end as c_uint) << (1 as c_uint)) as c_uint) | (1 as c_uint))

                }

                do {
                    0
                } while (0 != 0)

            }

            ((unsafe *__local_cranges).char_lists_types = __local_cranges.char_lists_types | (((4 as c_ushort) << (__local_tmp2 as c_uint)) as c_ushort))

        }

        if ((if __local_tmp1 >= 3: 1 else: 0) != 0) {
            ((unsafe *__local_cranges).char_lists_types = __local_cranges.char_lists_types | (((3 as c_ushort) << (__local_tmp2 as c_uint)) as c_ushort))

            (__local_next_char = __local_next_char - 1)

            if ((if __local_char_list_start < 65536: 1 else: 0) != 0) {
                ((unsafe *__local_next_char) = ((__local_tmp1 as c_ushort)))
            } else {
                (__local_next_char = __local_next_char - 1)

                ((unsafe *(__local_next_char as *mut c_uint)) = __local_tmp1)

            }

        } else {
            ((unsafe *__local_cranges).char_lists_types = __local_cranges.char_lists_types | ((__local_tmp1 as c_uint) << (__local_tmp2 as c_uint)))
        }

        if ((if __local_range_start < 256: 1 else: 0) != 0) {
            break
        }

        do {
            0
        } while (0 != 0)

        (__local_char_list_end = ((__local_char_list_start as c_uint) -% (1 as c_uint)))

        var __ci_expr_old_6: *const c_uint = __local_char_list_next

        (__local_char_list_next = __local_char_list_next + 1)

        (__local_char_list_start = (unsafe *__ci_expr_old_6))


        (__local_tmp1 = 0)

        (__local_tmp2 = __local_tmp2 - 3)

    }

    if ((if (unsafe __local_dst[0]) < 256: 1 else: 0) != 0) {
        (__local_dst = __local_dst + ((2 as isize) as usize))
    }

    do {
        0
    } while (0 != 0)

    ((unsafe *__local_cranges).char_lists_size = (((((((__local_buffer + (__local_total_size as usize)) as *mut u8) as usize) -% ((__local_next_char as *mut u8) as usize)) / sizeof[u8]()) as c_ulong)))

    ((unsafe *__local_cranges).char_lists_start = ((((((__local_next_char as *mut u8) as usize) -% ((__local_buffer as *mut u8) as usize)) / sizeof[u8]()) as c_ulong)))

    ((unsafe *__local_cranges).range_list_size = (((((__local_dst as usize) -% (__local_buffer as usize)) / sizeof[c_uint]()) as c_ushort)))

    return __local_cranges

}

fn add_to_class(__param_options: c_uint, __param_xoptions: c_uint, __param_cb: *mut compile_block_8, __param_start: c_uint, __param_end: c_uint) {
    var __local_classbits: *mut u8 = ((&raw const (unsafe *__param_cb).classbits.classbits[0] as *mut u8))

    var __local_c: c_uint

    var __local_byte_start: c_uint

    var __local_byte_end: c_uint


    var __local_classbits_end: c_uint = with 0 as __ci_expr_seq_14 {
        var __ci_expr_ternary_0: c_uint = 0
        if ((if __param_end <= 255: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = __param_end)
        } else {
            (__ci_expr_ternary_0 = 255)
        }
        __ci_expr_ternary_0
    }

    if ((if ((__param_options as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
        if ((if ((__param_options as c_uint) & (((524288 as c_uint) | (131072 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            var __local_turkish_i: c_int = (if ((__param_xoptions as c_uint) & (((65536 as c_uint) | (128 as c_uint)) as c_uint)) == 65536: 1 else: 0)

            if ((if __param_start < 128: 1 else: 0) != 0) {
                var __local_lo_end: c_uint = with 0 as __ci_expr_seq_24 {
                    var __ci_expr_ternary_1: c_uint = 0
                    if ((if __local_classbits_end < 127: 1 else: 0) != 0) {
                        (__ci_expr_ternary_1 = __local_classbits_end)
                    } else {
                        (__ci_expr_ternary_1 = 127)
                    }
                    __ci_expr_ternary_1
                }

                (__local_c = __param_start)

                while ((if __local_c <= __local_lo_end: 1 else: 0) != 0) {
                    var __ci_expr_logic_3: c_int = 0

                    if (__local_turkish_i != 0) {
                        var __ci_expr_logic_2: c_int

                        if ((if ((__local_c as c_uint) | (32 as c_uint)) == 105: 1 else: 0) != 0) {
                            (__ci_expr_logic_2 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_2 = (if (if ((__local_c as c_uint) | (1 as c_uint)) == 305: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__local_c = __local_c + 1)

                        continue

                    }


                    ((unsafe __local_classbits[(((unsafe __param_cb.fcc[__local_c]) as c_int) >> (3 as c_uint))]) = (unsafe __local_classbits[(((unsafe __param_cb.fcc[__local_c]) as c_int) >> (3 as c_uint))]) | (((1 as c_uint) << ((((unsafe __param_cb.fcc[__local_c]) as c_int) & 7) as c_uint)) as u8))


                    (__local_c = __local_c + 1)

                }


            }

            if ((if __local_classbits_end >= 128: 1 else: 0) != 0) {
                var __local_hi_start: c_uint = with 0 as __ci_expr_seq_63 {
                    var __ci_expr_ternary_4: c_uint = 0
                    if ((if __param_start > 128: 1 else: 0) != 0) {
                        (__ci_expr_ternary_4 = __param_start)
                    } else {
                        (__ci_expr_ternary_4 = 128)
                    }
                    __ci_expr_ternary_4
                }

                (__local_c = __local_hi_start)

                while ((if __local_c <= __local_classbits_end: 1 else: 0) != 0) {
                    var __local_co: c_uint = ((((__local_c as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint))

                    if ((if __local_co <= 255: 1 else: 0) != 0) {
                        ((unsafe __local_classbits[((__local_co as c_uint) >> (3 as c_uint))]) = (unsafe __local_classbits[((__local_co as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << (((__local_co as c_uint) & (7 as c_uint)) as c_uint)) as u8))
                    }


                    (__local_c = __local_c + 1)

                }


            }

        } else {
            (__local_c = __param_start)

            while ((if __local_c <= __local_classbits_end: 1 else: 0) != 0) {
                ((unsafe __local_classbits[(((unsafe __param_cb.fcc[__local_c]) as c_int) >> (3 as c_uint))]) = (unsafe __local_classbits[(((unsafe __param_cb.fcc[__local_c]) as c_int) >> (3 as c_uint))]) | (((1 as c_uint) << ((((unsafe __param_cb.fcc[__local_c]) as c_int) & 7) as c_uint)) as u8))

                (__local_c = __local_c + 1)

            }


        }

    }

    (__local_byte_start = (((__param_start as c_uint) +% (7 as c_uint)) as c_uint) >> (3 as c_uint))

    (__local_byte_end = (((__local_classbits_end as c_uint) +% (1 as c_uint)) as c_uint) >> (3 as c_uint))

    if ((if __local_byte_start >= __local_byte_end: 1 else: 0) != 0) {
        (__local_c = __param_start)

        while ((if __local_c <= __local_classbits_end: 1 else: 0) != 0) {
            ((unsafe __local_classbits[((__local_c as c_uint) >> (3 as c_uint))]) = (unsafe __local_classbits[((__local_c as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << (((__local_c as c_uint) & (7 as c_uint)) as c_uint)) as u8))

            (__local_c = __local_c + 1)

        }


        return

    }

    (__local_c = __local_byte_start)

    while ((if __local_c < __local_byte_end: 1 else: 0) != 0) {
        ((unsafe __local_classbits[__local_c]) = 255)

        (__local_c = __local_c + 1)

    }


    (__local_byte_start = __local_byte_start << (3 as c_uint))

    (__local_byte_end = __local_byte_end << (3 as c_uint))

    (__local_c = __param_start)

    while ((if __local_c < __local_byte_start: 1 else: 0) != 0) {
        ((unsafe __local_classbits[((__local_c as c_uint) >> (3 as c_uint))]) = (unsafe __local_classbits[((__local_c as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << (((__local_c as c_uint) & (7 as c_uint)) as c_uint)) as u8))

        (__local_c = __local_c + 1)

    }


    (__local_c = __local_byte_end)

    while ((if __local_c <= __local_classbits_end: 1 else: 0) != 0) {
        ((unsafe __local_classbits[((__local_c as c_uint) >> (3 as c_uint))]) = (unsafe __local_classbits[((__local_c as c_uint) >> (3 as c_uint))]) | (((1 as c_uint) << (((__local_c as c_uint) & (7 as c_uint)) as c_uint)) as u8))

        (__local_c = __local_c + 1)

    }


}

fn add_list_to_class(__param_options: c_uint, __param_xoptions: c_uint, __param_cb: *mut compile_block_8, __param_p: *const c_uint) {
    var __local_p = __param_p
    while ((if (unsafe __local_p[0]) < 256: 1 else: 0) != 0) {
        var __local_n: c_uint = 0

        while ((if (unsafe __local_p[((__local_n as c_uint) +% (1 as c_uint))]) == (((((unsafe __local_p[0]) as c_uint) +% (__local_n as c_uint)) as c_uint) +% (1 as c_uint)): 1 else: 0) != 0) {
            (__local_n = __local_n + 1)
        }

        add_to_class(__param_options, __param_xoptions, __param_cb, (unsafe __local_p[0]), (unsafe __local_p[__local_n]))

        (__local_p = __local_p + (((__local_n as c_uint) +% (1 as c_uint)) as usize))

    }

}

fn add_not_list_to_class(__param_options: c_uint, __param_xoptions: c_uint, __param_cb: *mut compile_block_8, __param_p: *const c_uint) {
    var __local_p = __param_p
    if ((if (unsafe __local_p[0]) > 0: 1 else: 0) != 0) {
        add_to_class(__param_options, __param_xoptions, __param_cb, 0, (((unsafe __local_p[0]) as c_uint) -% (1 as c_uint)))
    }

    while ((if (unsafe __local_p[0]) < 256: 1 else: 0) != 0) {
        while ((if (unsafe __local_p[1]) == (((unsafe __local_p[0]) as c_uint) +% (1 as c_uint)): 1 else: 0) != 0) {
            (__local_p = __local_p + 1)
        }

        var __ci_expr_ternary_0: c_uint = 0

        if ((if (unsafe __local_p[1]) > 255: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = 255)
        } else {
            (__ci_expr_ternary_0 = (((unsafe __local_p[1]) as c_uint) -% (1 as c_uint)))
        }

        add_to_class(__param_options, __param_xoptions, __param_cb, (((unsafe __local_p[0]) as c_uint) +% (1 as c_uint)), __ci_expr_ternary_0)


        (__local_p = __local_p + 1)

    }

}

fn fold_negation(__param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong, __param_preserve_classbits: c_int) {
    if ((if __param_pop_info.op_single_type == 0: 1 else: 0) != 0) {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 1)
        } else {
            ((unsafe (unsafe *__param_pop_info).code_start[__param_pop_info.length]) = 4)
        }

        ((unsafe *__param_pop_info).length = __param_pop_info.length + 1)

    } else {
        var __ci_expr_logic_0: c_int

        if ((if __param_pop_info.op_single_type == 6: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __param_pop_info.op_single_type == 7: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            var __ci_expr_ternary_1: c_int = 0

            if ((if __param_pop_info.op_single_type == 7: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = 6)
            } else {
                (__ci_expr_ternary_1 = 7)
            }

            ((unsafe *__param_pop_info).op_single_type = __ci_expr_ternary_1)


            if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                ((unsafe *__param_pop_info.code_start) = __param_pop_info.op_single_type)
            }

        } else {
            do {
                0
            } while (0 != 0)

            if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                ((unsafe (unsafe *__param_pop_info).code_start[(1 + 2)]) = (unsafe __param_pop_info.code_start[(1 + 2)]) ^ 1)
            }

        }

    }

    if ((if not (__param_preserve_classbits != 0): 1 else: 0) != 0) {
        var __local_i: c_int = 0

        while ((if __local_i < 8: 1 else: 0) != 0) {
            ((unsafe *__param_pop_info).bits.classwords[__local_i] = (~(&raw const (unsafe *__param_pop_info).bits as *const class_bits_storage).classwords[__local_i]))

            (__local_i = __local_i + 1)

        }


    }

}

fn fold_binary(__param_op: c_int, __param_lhs_op_info: *mut eclass_op_info, __param_rhs_op_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) {
    while true {
        match __param_op {
            1 => {
                if (not ((if __param_rhs_op_info.op_single_type == 6: 1 else: 0) != 0)) {
                    if ((if __param_lhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                            with_memmove((__param_lhs_op_info.code_start as *i8), (__param_rhs_op_info.code_start as *i8), (((__param_rhs_op_info.length as c_ulong) *% (1 as c_ulong)) as i64))
                        }

                        ((unsafe *__param_lhs_op_info).length = __param_rhs_op_info.length)

                        ((unsafe *__param_lhs_op_info).op_single_type = __param_rhs_op_info.op_single_type)

                    } else {
                        if ((if __param_rhs_op_info.op_single_type == 7: 1 else: 0) != 0) {
                            if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                                ((unsafe (unsafe *__param_lhs_op_info).code_start[0]) = 7)
                            }

                            ((unsafe *__param_lhs_op_info).length = 1)

                            ((unsafe *__param_lhs_op_info).op_single_type = 7)

                        } else {
                            if (not ((if __param_lhs_op_info.op_single_type == 7: 1 else: 0) != 0)) {
                                if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                                    ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 1)
                                } else {
                                    do {
                                        0
                                    } while (0 != 0)

                                    ((unsafe (unsafe *__param_rhs_op_info).code_start[__param_rhs_op_info.length]) = 1)

                                }

                                ((unsafe *__param_lhs_op_info).length = __param_lhs_op_info.length + ((__param_rhs_op_info.length as c_ulong) +% (1 as c_ulong)))

                                ((unsafe *__param_lhs_op_info).op_single_type = 0)

                            }
                        }
                    }
                }

                var __local_i: c_int = 0

                while ((if __local_i < 8: 1 else: 0) != 0) {
                    ((unsafe *__param_lhs_op_info).bits.classwords[__local_i] = (&raw const (unsafe *__param_lhs_op_info).bits as *const class_bits_storage).classwords[__local_i] & (&raw const (unsafe *__param_rhs_op_info).bits as *const class_bits_storage).classwords[__local_i])

                    (__local_i = __local_i + 1)

                }


            },
            2 => {
                if (not ((if __param_rhs_op_info.op_single_type == 7: 1 else: 0) != 0)) {
                    if ((if __param_lhs_op_info.op_single_type == 7: 1 else: 0) != 0) {
                        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                            with_memmove((__param_lhs_op_info.code_start as *i8), (__param_rhs_op_info.code_start as *i8), (((__param_rhs_op_info.length as c_ulong) *% (1 as c_ulong)) as i64))
                        }

                        ((unsafe *__param_lhs_op_info).length = __param_rhs_op_info.length)

                        ((unsafe *__param_lhs_op_info).op_single_type = __param_rhs_op_info.op_single_type)

                    } else {
                        if ((if __param_rhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                            if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                                ((unsafe (unsafe *__param_lhs_op_info).code_start[0]) = 6)
                            }

                            ((unsafe *__param_lhs_op_info).length = 1)

                            ((unsafe *__param_lhs_op_info).op_single_type = 6)

                        } else {
                            if (not ((if __param_lhs_op_info.op_single_type == 6: 1 else: 0) != 0)) {
                                if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                                    ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 1)
                                } else {
                                    do {
                                        0
                                    } while (0 != 0)

                                    ((unsafe (unsafe *__param_rhs_op_info).code_start[__param_rhs_op_info.length]) = 2)

                                }

                                ((unsafe *__param_lhs_op_info).length = __param_lhs_op_info.length + ((__param_rhs_op_info.length as c_ulong) +% (1 as c_ulong)))

                                ((unsafe *__param_lhs_op_info).op_single_type = 0)

                            }
                        }
                    }
                }

                var __local_i_1: c_int = 0

                while ((if __local_i_1 < 8: 1 else: 0) != 0) {
                    ((unsafe *__param_lhs_op_info).bits.classwords[__local_i_1] = (&raw const (unsafe *__param_lhs_op_info).bits as *const class_bits_storage).classwords[__local_i_1] | (&raw const (unsafe *__param_rhs_op_info).bits as *const class_bits_storage).classwords[__local_i_1])

                    (__local_i_1 = __local_i_1 + 1)

                }


            },
            3 => {
                if (not ((if __param_rhs_op_info.op_single_type == 7: 1 else: 0) != 0)) {
                    if ((if __param_lhs_op_info.op_single_type == 7: 1 else: 0) != 0) {
                        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                            with_memmove((__param_lhs_op_info.code_start as *i8), (__param_rhs_op_info.code_start as *i8), (((__param_rhs_op_info.length as c_ulong) *% (1 as c_ulong)) as i64))
                        }

                        ((unsafe *__param_lhs_op_info).length = __param_rhs_op_info.length)

                        ((unsafe *__param_lhs_op_info).op_single_type = __param_rhs_op_info.op_single_type)

                    } else {
                        if ((if __param_rhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                            fold_negation(__param_lhs_op_info, __param_lengthptr, 1)

                        } else {
                            if ((if __param_lhs_op_info.op_single_type == 6: 1 else: 0) != 0) {
                                if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                                    with_memmove((__param_lhs_op_info.code_start as *i8), (__param_rhs_op_info.code_start as *i8), (((__param_rhs_op_info.length as c_ulong) *% (1 as c_ulong)) as i64))
                                }

                                ((unsafe *__param_lhs_op_info).length = __param_rhs_op_info.length)

                                ((unsafe *__param_lhs_op_info).op_single_type = __param_rhs_op_info.op_single_type)

                                fold_negation(__param_lhs_op_info, __param_lengthptr, 1)

                            } else {
                                if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                                    ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + 1)
                                } else {
                                    do {
                                        0
                                    } while (0 != 0)

                                    ((unsafe (unsafe *__param_rhs_op_info).code_start[__param_rhs_op_info.length]) = 3)

                                }

                                ((unsafe *__param_lhs_op_info).length = __param_lhs_op_info.length + ((__param_rhs_op_info.length as c_ulong) +% (1 as c_ulong)))

                                ((unsafe *__param_lhs_op_info).op_single_type = 0)

                            }
                        }
                    }
                }

                var __local_i_2: c_int = 0

                while ((if __local_i_2 < 8: 1 else: 0) != 0) {
                    ((unsafe *__param_lhs_op_info).bits.classwords[__local_i_2] = (&raw const (unsafe *__param_lhs_op_info).bits as *const class_bits_storage).classwords[__local_i_2] ^ (&raw const (unsafe *__param_rhs_op_info).bits as *const class_bits_storage).classwords[__local_i_2])

                    (__local_i_2 = __local_i_2 + 1)

                }


            },
            _ => {
                do {
                    0
                } while (0 != 0)
            },
        }

        break

    }

}

fn compile_eclass_nested(__param_context: *mut eclass_context, __param_negated: c_int, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_negated = __param_negated
    var __local_ptr: *mut c_uint = (unsafe *__param_pptr)

    do {
        0
    } while (0 != 0)

    var __ci_expr_old_0: *mut c_uint = __local_ptr

    (__local_ptr = __local_ptr + 1)

    if ((if (unsafe *__ci_expr_old_0) == (((2148401152 as c_uint) as c_uint) | (1 as c_uint)): 1 else: 0) != 0) {
        (__local_negated = (if not (__local_negated != 0): 1 else: 0))
    }


    ((unsafe *__param_pptr) = (unsafe *__param_pptr) + 1)

    if ((if not (compile_class_binary_loose(__param_context, __local_negated, __param_pptr, __param_pcode, __param_pop_info, __param_lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    do {
        0
    } while (0 != 0)

    do {
        0
    } while (0 != 0)

    return 1

}

fn compile_class_operand(__param_context: *mut eclass_context, __param_negated: c_int, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_ptr__goto_2134_11: *mut c_uint = null

    var __local_prev_ptr__goto_2135_11: *mut c_uint = null

    var __local_code__goto_2136_14: *mut u8 = null

    var __local_code_start__goto_2137_14: *mut u8 = null

    var __local_prev_length__goto_2138_12: c_ulong = 0

    var __local_extra_length__goto_2139_12: c_ulong = 0

    var __local_meta__goto_2140_10: c_uint = 0

    var __local_classwords__goto_2241_17: *mut c_uint = null

    var __local_i__goto_2243_16: c_int = 0

    var __ci_expr_ternary_0: c_ulong = 0

    var __ci_expr_old_1: *mut u8 = null

    var __ci_expr_old_2: *mut u8 = null

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_ternary_4: c_ulong = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_ternary_6: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_ternary_8: *mut u8 = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_ptr__goto_2134_11 = (unsafe *__param_pptr))
        (__local_code__goto_2136_14 = (unsafe *__param_pcode))
        (__local_code_start__goto_2137_14 = __local_code__goto_2136_14)
        (__ci_expr_ternary_0 = 0)
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (unsafe *__param_lengthptr))
        } else {
            (__ci_expr_ternary_0 = 0)
        }
        (__local_prev_length__goto_2138_12 = __ci_expr_ternary_0)
        (__local_meta__goto_2140_10 = ((unsafe *__local_ptr__goto_2134_11) as c_uint) & ((4294901760 as c_uint) as c_uint))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if (__local_meta__goto_2140_10 == 2148270080) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_2 {
        (__ci_expr_ternary_8 = null)
        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_8 = __local_code_start__goto_2137_14)
        } else {
            (__ci_expr_ternary_8 = ((null as *mut u8)))
        }
        ((unsafe *__param_pop_info).code_start = __ci_expr_ternary_8)
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_65
        }
    }

    '__ci_bb_3 {
        (__local_ptr__goto_2134_11 = __local_ptr__goto_2134_11 + 1)
        ((unsafe *__param_pop_info).length = 1)
        if ((if (if __local_meta__goto_2140_10 == 2148204544: 1 else: 0) == __param_negated: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__ci_expr_old_1 = __local_code__goto_2136_14)
        (__local_code__goto_2136_14 = __local_code__goto_2136_14 + 1)
        ((unsafe *__param_pop_info).op_single_type = 6)
        ((unsafe *__ci_expr_old_1) = __param_pop_info.op_single_type)
        with_memset(((&(unsafe (&raw const (unsafe *__param_pop_info).bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), 255, (32 as i64))
        goto '__ci_bb_6
    }

    '__ci_bb_5 {
        (__ci_expr_old_2 = __local_code__goto_2136_14)
        (__local_code__goto_2136_14 = __local_code__goto_2136_14 + 1)
        ((unsafe *__param_pop_info).op_single_type = 7)
        ((unsafe *__ci_expr_old_2) = __param_pop_info.op_single_type)
        with_memset(((&(unsafe (&raw const (unsafe *__param_pop_info).bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), 0, (32 as i64))
        goto '__ci_bb_6
    }

    '__ci_bb_6 {
        goto '__ci_bb_2
    }

    '__ci_bb_7 {
        if ((if (((unsafe *__local_ptr__goto_2134_11) as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        if ((if not (compile_eclass_nested(__param_context, __param_negated, (&raw mut __local_ptr__goto_2134_11 as *mut *mut c_uint), (&raw mut __local_code__goto_2136_14 as *mut *mut u8), __param_pop_info, __param_lengthptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_9 {
        (__local_ptr__goto_2134_11 = __local_ptr__goto_2134_11 + 1)
        goto '__ci_bb_16
    }

    '__ci_bb_10 {
        return 0
    }

    '__ci_bb_11 {
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        if (0 != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_14 {
        (__local_ptr__goto_2134_11 = __local_ptr__goto_2134_11 + 1)
        goto '__ci_bb_15
    }

    '__ci_bb_15 {
        goto '__ci_bb_66
    }

    '__ci_bb_16 {
        (__local_prev_ptr__goto_2135_11 = __local_ptr__goto_2134_11)
        (__local_ptr__goto_2134_11 = _pcre2_compile_class_not_nested_8(__param_context.options, __param_context.xoptions, __local_ptr__goto_2134_11, (&raw mut __local_code__goto_2136_14 as *mut *mut u8), (if (if __local_meta__goto_2140_10 != 2148401152: 1 else: 0) == __param_negated: 1 else: 0), ((&raw const (unsafe *__param_context).needs_bitmap as *const c_int) as *mut c_int), __param_context.errorcodeptr, __param_context.cb, __param_lengthptr))
        if ((if __local_ptr__goto_2134_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_17 {
        return 0
    }

    '__ci_bb_18 {
        if ((if __local_ptr__goto_2134_11 <= __local_prev_ptr__goto_2135_11: 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_19 {
        goto '__ci_bb_21
    }

    '__ci_bb_20 {
        if ((if __local_meta__goto_2140_10 == 2148139008: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_meta__goto_2140_10 == 2148401152: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_21 {
        goto '__ci_bb_22
    }

    '__ci_bb_22 {
        if (0 != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_23 {
        return 0
    }

    '__ci_bb_24 {
        goto '__ci_bb_26
    }

    '__ci_bb_25 {
        goto '__ci_bb_29
    }

    '__ci_bb_26 {
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        if (0 != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_28 {
        (__local_ptr__goto_2134_11 = __local_ptr__goto_2134_11 + 1)
        goto '__ci_bb_25
    }

    '__ci_bb_29 {
        goto '__ci_bb_30
    }

    '__ci_bb_30 {
        if (0 != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_31 {
        (__ci_expr_ternary_4 = 0)
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_4 = (((unsafe *__param_lengthptr) as c_ulong) -% (__local_prev_length__goto_2138_12 as c_ulong)))
        } else {
            (__ci_expr_ternary_4 = 0)
        }
        (__local_extra_length__goto_2139_12 = __ci_expr_ternary_4)
        if ((if (unsafe *__local_code_start__goto_2137_14) == OP_ALLANY: 1 else: 0) != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_32 {
        goto '__ci_bb_35
    }

    '__ci_bb_33 {
        if ((if (unsafe *__local_code_start__goto_2137_14) == OP_CLASS: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_5 = (if (if (unsafe *__local_code_start__goto_2137_14) == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_34 {
        goto '__ci_bb_2
    }

    '__ci_bb_35 {
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        if (0 != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_37 {
        ((unsafe *__param_pop_info).length = 1)
        ((unsafe *__param_pop_info).op_single_type = 6)
        ((unsafe *__local_code_start__goto_2137_14) = __param_pop_info.op_single_type)
        with_memset(((&(unsafe (&raw const (unsafe *__param_pop_info).bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), 255, (32 as i64))
        goto '__ci_bb_34
    }

    '__ci_bb_38 {
        goto '__ci_bb_41
    }

    '__ci_bb_39 {
        goto '__ci_bb_55
    }

    '__ci_bb_40 {
        goto '__ci_bb_34
    }

    '__ci_bb_41 {
        goto '__ci_bb_42
    }

    '__ci_bb_42 {
        if (0 != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_43 {
        ((unsafe *__param_pop_info).length = 1)
        (__ci_expr_ternary_6 = 0)
        if ((if (unsafe *__local_code_start__goto_2137_14) == OP_CLASS: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = 7)
        } else {
            (__ci_expr_ternary_6 = 6)
        }
        ((unsafe *__param_pop_info).op_single_type = __ci_expr_ternary_6)
        ((unsafe *__local_code_start__goto_2137_14) = __param_pop_info.op_single_type)
        with_memcpy(((&(unsafe (&raw const (unsafe *__param_pop_info).bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), ((__local_code_start__goto_2137_14 + ((1 as isize) as usize)) as *i8), (32 as i64))
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_44 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + (((__local_code__goto_2136_14 as usize) -% ((__local_code_start__goto_2137_14 + ((1 as isize) as usize)) as usize)) / sizeof[u8]()))
        goto '__ci_bb_45
    }

    '__ci_bb_45 {
        (__local_code__goto_2136_14 = __local_code_start__goto_2137_14 + ((1 as isize) as usize))
        (__ci_expr_logic_7 = 0)
        if ((if not (__param_context.needs_bitmap != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if (unsafe *__local_code_start__goto_2137_14) == 7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        (__local_classwords__goto_2241_17 = ((&raw const (unsafe *__param_pop_info).bits.classwords[0] as *mut c_uint)))
        (__local_i__goto_2243_16 = 0)
        goto '__ci_bb_49
    }

    '__ci_bb_47 {
        ((unsafe *__param_context).needs_bitmap = 1)
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        goto '__ci_bb_40
    }

    '__ci_bb_49 {
        if ((if __local_i__goto_2243_16 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_50 {
        if ((if (unsafe __local_classwords__goto_2241_17[__local_i__goto_2243_16]) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_51 {
        (__local_i__goto_2243_16 = __local_i__goto_2243_16 + 1)
        goto '__ci_bb_49
    }

    '__ci_bb_52 {
        goto '__ci_bb_48
    }

    '__ci_bb_53 {
        ((unsafe *__param_context).needs_bitmap = 1)
        goto '__ci_bb_52
    }

    '__ci_bb_54 {
        goto '__ci_bb_51
    }

    '__ci_bb_55 {
        goto '__ci_bb_56
    }

    '__ci_bb_56 {
        if (0 != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_57 {
        ((unsafe *__param_pop_info).op_single_type = 5)
        ((unsafe *__local_code_start__goto_2137_14) = __param_pop_info.op_single_type)
        goto '__ci_bb_58
    }

    '__ci_bb_58 {
        goto '__ci_bb_59
    }

    '__ci_bb_59 {
        if (0 != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_60 {
        with_memcpy(((&(unsafe (&raw const (unsafe *__param_pop_info).bits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), ((&(unsafe (&raw const (unsafe *__param_context.cb).classbits as *const class_bits_storage).classbits[0]) as *mut u8) as *i8), (32 as i64))
        ((unsafe *__param_pop_info).length = (((((__local_code__goto_2136_14 as usize) -% (__local_code_start__goto_2137_14 as usize)) / sizeof[u8]()) as c_ulong) +% (__local_extra_length__goto_2139_12 as c_ulong)))
        goto '__ci_bb_40
    }

    '__ci_bb_61 {
        if (__local_meta__goto_2140_10 == 2148204544) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_62 {
        if (__local_meta__goto_2140_10 == 2148139008) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_63 {
        if (__local_meta__goto_2140_10 == 2148401152) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_64 {
        ((unsafe *__param_lengthptr) = (unsafe *__param_lengthptr) + (((__local_code__goto_2136_14 as usize) -% (__local_code_start__goto_2137_14 as usize)) / sizeof[u8]()))
        (__local_code__goto_2136_14 = __local_code_start__goto_2137_14)
        goto '__ci_bb_65
    }

    '__ci_bb_65 {
        goto '__ci_bb_15
    }

    '__ci_bb_66 {
        goto '__ci_bb_67
    }

    '__ci_bb_67 {
        if (0 != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_68 {
        ((unsafe *__param_pptr) = __local_ptr__goto_2134_11)
        ((unsafe *__param_pcode) = __local_code__goto_2136_14)
        return 1
    }

}

fn compile_class_juxtaposition(__param_context: *mut eclass_context, __param_negated: c_int, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_ptr: *mut c_uint = (unsafe *__param_pptr)

    var __local_code: *mut u8 = (unsafe *__param_pcode)

    if ((if not (compile_class_operand(__param_context, __param_negated, (&raw mut __local_ptr as *mut *mut c_uint), (&raw mut __local_code as *mut *mut u8), __param_pop_info, __param_lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while true {
        var __ci_expr_logic_1: c_int = 0

        if ((if (unsafe *__local_ptr) != 2148335616: 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int = 0

            if ((if (unsafe *__local_ptr) >= 2151940096: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if (unsafe *__local_ptr) <= 2152202240: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if (if not (__ci_expr_logic_0 != 0): 1 else: 0) != 0: 1 else: 0))

        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        var __local_op: c_uint

        var __local_rhs_negated: c_int

        var __local_rhs_op_info: eclass_op_info

        if (__param_negated != 0) {
            (__local_op = 1)

            (__local_rhs_negated = 1)

        } else {
            (__local_op = 2)

            (__local_rhs_negated = 0)

        }

        if ((if not (compile_class_operand(__param_context, __local_rhs_negated, (&raw mut __local_ptr as *mut *mut c_uint), (&raw mut __local_code as *mut *mut u8), (&raw mut __local_rhs_op_info as *mut eclass_op_info), __param_lengthptr) != 0): 1 else: 0) != 0) {
            return 0
        }

        fold_binary(__local_op, __param_pop_info, (&raw mut __local_rhs_op_info as *mut eclass_op_info), __param_lengthptr)

        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            (__local_code = __param_pop_info.code_start + (__param_pop_info.length as usize))
        }

    }

    do {
        0
    } while (0 != 0)

    ((unsafe *__param_pptr) = __local_ptr)

    ((unsafe *__param_pcode) = __local_code)

    return 1

}

fn compile_class_unary(__param_context: *mut eclass_context, __param_negated: c_int, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_negated = __param_negated
    var __local_ptr: *mut c_uint = (unsafe *__param_pptr)

    while ((if (unsafe *__local_ptr) == 2152202240: 1 else: 0) != 0) {
        (__local_ptr = __local_ptr + 1)

        (__local_negated = (if not (__local_negated != 0): 1 else: 0))

    }

    ((unsafe *__param_pptr) = __local_ptr)

    if ((if not (compile_class_juxtaposition(__param_context, __local_negated, __param_pptr, __param_pcode, __param_pop_info, __param_lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    do {
        0
    } while (0 != 0)

    return 1

}

fn compile_class_binary_tight(__param_context: *mut eclass_context, __param_negated: c_int, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_ptr: *mut c_uint = (unsafe *__param_pptr)

    var __local_code: *mut u8 = (unsafe *__param_pcode)

    if ((if not (compile_class_unary(__param_context, __param_negated, (&raw mut __local_ptr as *mut *mut c_uint), (&raw mut __local_code as *mut *mut u8), __param_pop_info, __param_lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while ((if (unsafe *__local_ptr) == 2151940096: 1 else: 0) != 0) {
        var __local_op: c_uint

        var __local_rhs_negated: c_int

        var __local_rhs_op_info: eclass_op_info

        if (__param_negated != 0) {
            (__local_op = 2)

            (__local_rhs_negated = 1)

        } else {
            (__local_op = 1)

            (__local_rhs_negated = 0)

        }

        (__local_ptr = __local_ptr + 1)

        if ((if not (compile_class_unary(__param_context, __local_rhs_negated, (&raw mut __local_ptr as *mut *mut c_uint), (&raw mut __local_code as *mut *mut u8), (&raw mut __local_rhs_op_info as *mut eclass_op_info), __param_lengthptr) != 0): 1 else: 0) != 0) {
            return 0
        }

        fold_binary(__local_op, __param_pop_info, (&raw mut __local_rhs_op_info as *mut eclass_op_info), __param_lengthptr)

        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            (__local_code = __param_pop_info.code_start + (__param_pop_info.length as usize))
        }

    }

    do {
        0
    } while (0 != 0)

    ((unsafe *__param_pptr) = __local_ptr)

    ((unsafe *__param_pcode) = __local_code)

    return 1

}

fn compile_class_binary_loose(__param_context: *mut eclass_context, __param_negated: c_int, __param_pptr: *mut *mut c_uint, __param_pcode: *mut *mut u8, __param_pop_info: *mut eclass_op_info, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_ptr: *mut c_uint = (unsafe *__param_pptr)

    var __local_code: *mut u8 = (unsafe *__param_pcode)

    if ((if not (compile_class_binary_tight(__param_context, __param_negated, (&raw mut __local_ptr as *mut *mut c_uint), (&raw mut __local_code as *mut *mut u8), __param_pop_info, __param_lengthptr) != 0): 1 else: 0) != 0) {
        return 0
    }

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *__local_ptr) >= 2152005632: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *__local_ptr) <= 2152136704: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __local_op: c_uint

        var __local_op_neg: c_int

        var __local_rhs_negated: c_int

        var __local_rhs_op_info: eclass_op_info

        if (__param_negated != 0) {
            var __ci_expr_ternary_2: c_int = 0

            if ((if (unsafe *__local_ptr) == 2152005632: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = 1)
            } else {
                var __ci_expr_ternary_1: c_int = 0

                if ((if (unsafe *__local_ptr) == 2152071168: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = 2)
                } else {
                    (__ci_expr_ternary_1 = 3)
                }

                (__ci_expr_ternary_2 = __ci_expr_ternary_1)

            }

            (__local_op = __ci_expr_ternary_2)


            (__local_op_neg = (if (unsafe *__local_ptr) == 2152136704: 1 else: 0))

            (__local_rhs_negated = (if (unsafe *__local_ptr) != 2152071168: 1 else: 0))

        } else {
            var __ci_expr_ternary_4: c_int = 0

            if ((if (unsafe *__local_ptr) == 2152005632: 1 else: 0) != 0) {
                (__ci_expr_ternary_4 = 2)
            } else {
                var __ci_expr_ternary_3: c_int = 0

                if ((if (unsafe *__local_ptr) == 2152071168: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = 1)
                } else {
                    (__ci_expr_ternary_3 = 3)
                }

                (__ci_expr_ternary_4 = __ci_expr_ternary_3)

            }

            (__local_op = __ci_expr_ternary_4)


            (__local_op_neg = 0)

            (__local_rhs_negated = (if (unsafe *__local_ptr) == 2152071168: 1 else: 0))

        }

        (__local_ptr = __local_ptr + 1)

        if ((if not (compile_class_binary_tight(__param_context, __local_rhs_negated, (&raw mut __local_ptr as *mut *mut c_uint), (&raw mut __local_code as *mut *mut u8), (&raw mut __local_rhs_op_info as *mut eclass_op_info), __param_lengthptr) != 0): 1 else: 0) != 0) {
            return 0
        }

        fold_binary(__local_op, __param_pop_info, (&raw mut __local_rhs_op_info as *mut eclass_op_info), __param_lengthptr)

        if (__local_op_neg != 0) {
            fold_negation(__param_pop_info, __param_lengthptr, 0)
        }

        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            (__local_code = __param_pop_info.code_start + (__param_pop_info.length as usize))
        }

    }

    do {
        0
    } while (0 != 0)

    ((unsafe *__param_pptr) = __local_ptr)

    ((unsafe *__param_pcode) = __local_code)

    return 1

}

let char_list_starts: [3]c_uint = [0x10000, 0x8000, 0x100]
