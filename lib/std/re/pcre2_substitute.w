// Migrated from PCRE2
use std.re.defs

fn pcre2_substitute_8(__param_code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, __param_start_offset: c_ulong, __param_options: c_uint, __param_match_data: *mut pcre2_real_match_data_8, __param_mcontext: *mut pcre2_real_match_context_8, __param_replacement: *const u8, __param_rlength: c_ulong, __param_buffer: *mut u8, __param_blength: *mut c_ulong) -> c_int {
    var __local_subject = __param_subject
    var __local_length = __param_length
    var __local_start_offset = __param_start_offset
    var __local_options = __param_options
    var __local_match_data = __param_match_data
    var __local_replacement = __param_replacement
    var __local_rlength = __param_rlength
    var __local_rc__goto_743_5: c_int = 0

    var __local_subs__goto_744_5: c_int = 0

    var __local_ovector_count__goto_745_10: c_uint = 0

    var __local_goptions__goto_746_10: c_uint = 0

    var __local_suboptions__goto_747_10: c_uint = 0

    var __local_internal_match_data__goto_748_19: *mut pcre2_real_match_data_8 = null

    var __local_escaped_literal__goto_749_6: c_int = 0

    var __local_overflowed__goto_750_6: c_int = 0

    var __local_use_existing_match__goto_751_6: c_int = 0

    var __local_replacement_only__goto_752_6: c_int = 0

    var __local_utf__goto_753_6: c_int = 0

    var __local_temp__goto_754_13: [6]u8

    var __local_null_str__goto_755_13: [1]u8

    var __local_original_subject__goto_756_12: *const u8 = null

    var __local_ptr__goto_757_12: *const u8 = null

    var __local_repend__goto_758_12: *const u8 = null

    var __local_extra_needed__goto_759_12: c_ulong = 0

    var __local_buff_offset__goto_760_12: c_ulong = 0

    var __local_buff_length__goto_760_25: c_ulong = 0

    var __local_lengthleft__goto_760_38: c_ulong = 0

    var __local_fraglength__goto_760_50: c_ulong = 0

    var __local_ovector__goto_761_13: *mut c_ulong = null

    var __local_ovecsave__goto_762_12: [2]c_ulong

    var __local_scb__goto_763_32: pcre2_substitute_callout_block_8

    var __local_sub_start_extra_needed__goto_764_12: c_ulong = 0

    var __local_substitute_case_callout__goto_765_14: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null

    var __local_substitute_case_callout_data__goto_767_7: *mut c_void = null

    var __local_gcontext__goto_876_25: pcre2_real_general_context_8

    var __local_pairs__goto_887_7: c_int = 0

    var __local_gcontext__goto_888_25: pcre2_real_general_context_8

    var __local_chkmc_length__goto_952_24: c_ulong = 0

    var __local_ptrstack__goto_960_14: [20]*const u8

    var __local_ptrstackptr__goto_961_12: c_uint = 0

    var __local_forcecase__goto_962_14: case_state

    var __local_casestart_offset__goto_963_14: c_ulong = 0

    var __local_casestart_extra_needed__goto_964_14: c_ulong = 0

    var __local_chkmc_length__goto_1032_26: c_ulong = 0

    var __local_chkmc_length__goto_1043_5: c_ulong = 0

    var __local_ch__goto_1053_14: c_uint = 0

    var __local_chlen__goto_1054_18: c_uint = 0

    var __local_group__goto_1055_9: c_int = 0

    var __local_special__goto_1056_14: c_uint = 0

    var __local_text1_start__goto_1057_16: *const u8 = null

    var __local_text1_end__goto_1058_16: *const u8 = null

    var __local_text2_start__goto_1059_16: *const u8 = null

    var __local_text2_end__goto_1060_16: *const u8 = null

    var __local_name__goto_1061_17: [129]u8

    var __local_inparens__goto_1090_12: c_int = 0

    var __local_inangle__goto_1091_12: c_int = 0

    var __local_star__goto_1092_12: c_int = 0

    var __local_sublength__goto_1093_18: c_ulong = 0

    var __local_next__goto_1094_19: u8 = 0

    var __local_subptr__goto_1095_18: *const u8 = null

    var __local_subptrend__goto_1095_26: *const u8 = null

    var __local_name_len__goto_1239_20: c_ulong = 0

    var __local_name_start__goto_1240_20: *const u8 = null

    var __local_mark__goto_1306_22: *const u8 = null

    var __local_chkcc_length__goto_1314_15: c_ulong = 0

    var __local_chkcc_rc__goto_1314_15: c_ulong = 0

    var __local_chkmc_length__goto_1316_15: c_ulong = 0

    var __local_first__goto_1335_22: *const u8 = null

    var __local_last__goto_1335_29: *const u8 = null

    var __local_entry__goto_1335_35: *const u8 = null

    var __local_ng__goto_1347_24: c_uint = 0

    var __local_chkcc_length__goto_1427_11: c_ulong = 0

    var __local_chkcc_rc__goto_1427_11: c_ulong = 0

    var __local_chkmc_length__goto_1429_11: c_ulong = 0

    var __local_errorcode__goto_1441_11: c_int = 0

    var __local_new_forcecase__goto_1442_18: case_state

    var __local_chars_outstanding__goto_1500_11: c_ulong = 0

    var __local_guess__goto_1500_11: c_ulong = 0

    var __local_chkcc_length__goto_1500_11: c_ulong = 0

    var __local_chkcc_rc__goto_1500_11: c_ulong = 0

    var __local_chkcc_length__goto_1539_11: c_ulong = 0

    var __local_chkcc_rc__goto_1539_11: c_ulong = 0

    var __local_chkmc_length__goto_1541_11: c_ulong = 0

    var __local_name_len__goto_1546_22: c_ulong = 0

    var __local_name_start__goto_1547_22: *const u8 = null

    var __local_ch_start__goto_1585_18: *const u8 = null

    var __local_chkcc_length__goto_1594_9: c_ulong = 0

    var __local_chkcc_rc__goto_1594_9: c_ulong = 0

    var __local_chkmc_length__goto_1596_9: c_ulong = 0

    var __local_chars_outstanding__goto_1609_5: c_ulong = 0

    var __local_guess__goto_1609_5: c_ulong = 0

    var __local_chkcc_length__goto_1609_5: c_ulong = 0

    var __local_chkcc_rc__goto_1609_5: c_ulong = 0

    var __local_newlength__goto_1630_20: c_ulong = 0

    var __local_oldlength__goto_1631_20: c_ulong = 0

    var __local_chkmc_length__goto_1635_32: c_ulong = 0

    var __local_newlength_buf__goto_1654_18: c_ulong = 0

    var __local_newlength_extra__goto_1655_18: c_ulong = 0

    var __local_newlength__goto_1656_18: c_ulong = 0

    var __local_oldlength__goto_1659_18: c_ulong = 0

    var __local_additional__goto_1666_20: c_ulong = 0

    var __local_chkmc_length__goto_1704_3: c_ulong = 0

    var __local_chkmc_length__goto_1708_1: c_ulong = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_ternary_6: pcre2_memctl

    var __ci_expr_ternary_7: pcre2_memctl

    var __ci_expr_ternary_8: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_logic_20: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_21: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_26: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_logic_29: c_int = 0

    var __ci_expr_logic_28: c_int = 0

    var __ci_expr_logic_27: c_int = 0

    var __ci_expr_logic_30: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_logic_32: c_int = 0

    var __ci_expr_logic_33: c_int = 0

    var __ci_expr_logic_34: c_int = 0

    var __ci_expr_ternary_35: c_ulong = 0

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_logic_37: c_int = 0

    var __ci_expr_old_38: c_uint = 0

    var __ci_expr_old_39: c_uint = 0

    var __ci_expr_logic_40: c_int = 0

    var __ci_expr_ternary_41: c_ulong = 0

    var __ci_expr_logic_42: c_int = 0

    var __ci_expr_logic_44: c_int = 0

    var __ci_expr_logic_43: c_int = 0

    var __ci_expr_logic_46: c_int = 0

    var __ci_expr_logic_45: c_int = 0

    var __ci_expr_logic_47: c_int = 0

    var __ci_expr_logic_48: c_int = 0

    var __ci_expr_ternary_49: c_ulong = 0

    var __ci_expr_logic_50: c_int = 0

    var __ci_expr_logic_51: c_int = 0

    var __ci_expr_old_52: *const u8 = null

    var __ci_expr_logic_53: c_int = 0

    var __ci_expr_old_54: *const u8 = null

    var __ci_expr_logic_55: c_int = 0

    var __ci_expr_ternary_56: c_ulong = 0

    var __ci_expr_logic_57: c_int = 0

    var __ci_expr_logic_58: c_int = 0

    var __ci_expr_ternary_59: c_ulong = 0

    var __ci_expr_logic_60: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_goptions__goto_746_10 = 0)
        (__local_internal_match_data__goto_748_19 = ((null as *mut pcre2_real_match_data_8)))
        (__local_escaped_literal__goto_749_6 = 0)
        (__local_overflowed__goto_750_6 = 0)
        (__local_utf__goto_753_6 = (if ((__param_code.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        (__local_null_str__goto_755_13 = [205])
        (__local_original_subject__goto_756_12 = __local_subject)
        (__local_repend__goto_758_12 = null)
        (__local_extra_needed__goto_759_12 = 0)
        (__local_ovecsave__goto_762_12 = [0, 0])
        (__local_substitute_case_callout__goto_765_14 = ((null as *mut fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)))
        (__local_substitute_case_callout_data__goto_767_7 = null)
        (__local_buff_offset__goto_760_12 = 0)
        (__local_buff_length__goto_760_25 = (unsafe: *__param_blength))
        (__local_lengthleft__goto_760_38 = __local_buff_length__goto_760_25)
        ((unsafe: *__param_blength) = (~(0 as c_ulong)))
        if ((if __param_mcontext != null: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        (__local_substitute_case_callout__goto_765_14 = ((__param_mcontext.substitute_case_callout as *mut fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)))
        (__local_substitute_case_callout_data__goto_767_7 = __param_mcontext.substitute_case_callout_data)
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        if ((if ((__local_options as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_3 {
        return -34
    }

    '__ci_bb_4 {
        if ((if __local_replacement == null: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_5 {
        if ((if __local_rlength != 0: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        if ((if __local_rlength == (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_7 {
        return -51
    }

    '__ci_bb_8 {
        (__local_replacement = (&(unsafe: __local_null_str__goto_755_13[0]) as *mut u8))
        goto '__ci_bb_6
    }

    '__ci_bb_9 {
        (__local_rlength = _pcre2_strlen_8(__local_replacement))
        goto '__ci_bb_10
    }

    '__ci_bb_10 {
        (__local_repend__goto_758_12 = __local_replacement + (__local_rlength as usize))
        if ((if __local_subject == null: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_11 {
        if ((if __local_length != 0: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_12 {
        if ((if __local_length == (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_13 {
        return -51
    }

    '__ci_bb_14 {
        (__local_subject = (&(unsafe: __local_null_str__goto_755_13[0]) as *mut u8))
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        (__local_length = _pcre2_strlen_8(__local_subject))
        goto '__ci_bb_16
    }

    '__ci_bb_16 {
        (__local_use_existing_match__goto_751_6 = (if ((__local_options as c_uint) & (65536 as c_uint)) != 0: 1 else: 0))
        (__local_replacement_only__goto_752_6 = (if ((__local_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0))
        (__ci_expr_logic_0 = 0)
        if (__local_use_existing_match__goto_751_6 != 0) {
            (__ci_expr_logic_0 = (if (if __local_match_data == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_17 {
        return -51
    }

    '__ci_bb_18 {
        if (__local_use_existing_match__goto_751_6 != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_19 {
        (__ci_expr_logic_1 = 0)
        if ((if __local_match_data.rc < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_match_data.rc != -1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_20 {
        if ((if __local_match_data == null: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_21 {
        return __local_match_data.rc
    }

    '__ci_bb_22 {
        if ((if __local_match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_23 {
        return -41
    }

    '__ci_bb_24 {
        if ((if __param_code != __local_match_data.code: 1 else: 0) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_25 {
        return -71
    }

    '__ci_bb_26 {
        if ((if __local_length != __local_match_data.subject_length: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_4: c_int

            if ((if __local_original_subject__goto_756_12 == __local_match_data.subject: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_3: c_int = 0

                if ((if (((__local_match_data.flags as c_int) as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_2: c_int

                    if ((if __local_length == 0: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if (if with_memcmp((__local_subject as *i8), (__local_match_data.subject as *i8), (((__local_length as c_ulong) *% (1 as c_ulong)) as i64)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                }

                (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

            }

            (__ci_expr_logic_5 = (if (if not (__ci_expr_logic_4 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_27 {
        return -72
    }

    '__ci_bb_28 {
        if ((if __local_start_offset != __local_match_data.start_offset: 1 else: 0) != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_29 {
        return -73
    }

    '__ci_bb_30 {
        if ((if ((__local_options as c_uint) & ((~((((((((((((((512 as c_uint) | (256 as c_uint)) as c_uint) | (32768 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (4096 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (2048 as c_uint)) as c_uint) | (1024 as c_uint))) as c_uint)) != __local_match_data.options: 1 else: 0) != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_31 {
        return -74
    }

    '__ci_bb_32 {
        goto '__ci_bb_20
    }

    '__ci_bb_33 {
        if ((if __param_mcontext == null: 1 else: 0) != 0) {
            with_memcpy((&raw mut __ci_expr_ternary_6 as *i8), (&raw const (unsafe: *(__param_code as *mut pcre2_real_code_8)).memctl as *i8), sizeof[pcre2_memctl]())
        } else {
            with_memcpy((&raw mut __ci_expr_ternary_6 as *i8), (&raw const (unsafe: *__param_mcontext).memctl as *i8), sizeof[pcre2_memctl]())
        }
        with_memcpy((&raw mut __local_gcontext__goto_876_25.memctl as *i8), (&raw const __ci_expr_ternary_6 as *i8), sizeof[pcre2_memctl]())
        (__local_internal_match_data__goto_748_19 = pcre2_match_data_create_from_pattern_8(__param_code, (&raw mut __local_gcontext__goto_876_25 as *mut pcre2_real_general_context_8)))
        (__local_match_data = __local_internal_match_data__goto_748_19)
        if ((if __local_internal_match_data__goto_748_19 == null: 1 else: 0) != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_34 {
        if (__local_use_existing_match__goto_751_6 != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_35 {
        if ((if __local_internal_match_data__goto_748_19 != null: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_36 {
        return -48
    }

    '__ci_bb_37 {
        goto '__ci_bb_35
    }

    '__ci_bb_38 {
        if ((if __param_mcontext == null: 1 else: 0) != 0) {
            with_memcpy((&raw mut __ci_expr_ternary_7 as *i8), (&raw const (unsafe: *(__param_code as *mut pcre2_real_code_8)).memctl as *i8), sizeof[pcre2_memctl]())
        } else {
            with_memcpy((&raw mut __ci_expr_ternary_7 as *i8), (&raw const (unsafe: *__param_mcontext).memctl as *i8), sizeof[pcre2_memctl]())
        }
        with_memcpy((&raw mut __local_gcontext__goto_888_25.memctl as *i8), (&raw const __ci_expr_ternary_7 as *i8), sizeof[pcre2_memctl]())
        (__ci_expr_ternary_8 = 0)
        if ((if ((__param_code.top_bracket as c_int) + 1) < __local_match_data.oveccount: 1 else: 0) != 0) {
            (__ci_expr_ternary_8 = (__param_code.top_bracket as c_int) + 1)
        } else {
            (__ci_expr_ternary_8 = __local_match_data.oveccount)
        }
        (__local_pairs__goto_887_7 = __ci_expr_ternary_8)
        (__local_internal_match_data__goto_748_19 = pcre2_match_data_create_8(__local_match_data.oveccount, (&raw mut __local_gcontext__goto_888_25 as *mut pcre2_real_general_context_8)))
        if ((if __local_internal_match_data__goto_748_19 == null: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_39 {
        goto '__ci_bb_35
    }

    '__ci_bb_40 {
        return -48
    }

    '__ci_bb_41 {
        with_memcpy((__local_internal_match_data__goto_748_19 as *i8), (__local_match_data as *i8), (((120 as c_ulong) +% ((((2 * __local_pairs__goto_887_7) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong)) as i64))
        ((unsafe: *__local_internal_match_data__goto_748_19).heapframes = ((null as *mut heapframe)))
        ((unsafe: *__local_internal_match_data__goto_748_19).heapframes_size = 0)
        ((unsafe: *__local_internal_match_data__goto_748_19).flags = __local_internal_match_data__goto_748_19.flags & (~1))
        (__local_match_data = __local_internal_match_data__goto_748_19)
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        (__local_options = __local_options & (~16384))
        goto '__ci_bb_43
    }

    '__ci_bb_43 {
        (__local_ovector__goto_761_13 = pcre2_get_ovector_pointer_8(__local_match_data))
        (__local_ovector_count__goto_745_10 = pcre2_get_ovector_count_8(__local_match_data))
        (__local_scb__goto_763_32.version = 0)
        (__local_scb__goto_763_32.input = __local_subject)
        (__local_scb__goto_763_32.output = ((__param_buffer as *const u8)))
        (__local_scb__goto_763_32.ovector = __local_ovector__goto_761_13)
        (__ci_expr_logic_9 = 0)
        if (__local_utf__goto_753_6 != 0) {
            (__ci_expr_logic_9 = (if (if ((__local_options as c_uint) & (1073741824 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_44 {
        (__local_rc__goto_743_5 = _pcre2_valid_utf_8(__local_replacement, __local_rlength, ((&raw const (unsafe: *__local_match_data).startchar as *const c_ulong) as *mut c_ulong)))
        if ((if __local_rc__goto_743_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_45 {
        (__local_suboptions__goto_747_10 = (__local_options as c_uint) & (((((((((((((((512 as c_uint) | (256 as c_uint)) as c_uint) | (32768 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (4096 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (2048 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint))
        (__local_options = __local_options & (~((((((((((((((512 as c_uint) | (256 as c_uint)) as c_uint) | (32768 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (4096 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (2048 as c_uint)) as c_uint) | (1024 as c_uint))))
        if ((if __local_start_offset > __local_length: 1 else: 0) != 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_46 {
        ((unsafe: *__local_match_data).leftchar = 0)
        goto '__ci_bb_48
    }

    '__ci_bb_47 {
        goto '__ci_bb_45
    }

    '__ci_bb_48 {
        if ((if __local_internal_match_data__goto_748_19 != null: 1 else: 0) != 0) {
            goto '__ci_bb_566
        } else {
            goto '__ci_bb_567
        }
    }

    '__ci_bb_49 {
        ((unsafe: *__local_match_data).leftchar = 0)
        (__local_rc__goto_743_5 = -33)
        goto '__ci_bb_48
    }

    '__ci_bb_50 {
        if ((if not (__local_replacement_only__goto_752_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_51 {
        goto '__ci_bb_53
    }

    '__ci_bb_52 {
        (__local_subs__goto_744_5 = 0)
        goto '__ci_bb_68
    }

    '__ci_bb_53 {
        (__local_chkmc_length__goto_952_24 = __local_start_offset)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_54 {
        if (0 != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_55 {
        goto '__ci_bb_52
    }

    '__ci_bb_56 {
        if ((if __local_chkmc_length__goto_952_24 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_57 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_952_24: 1 else: 0) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_58 {
        goto '__ci_bb_54
    }

    '__ci_bb_59 {
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_952_24)
        goto '__ci_bb_58
    }

    '__ci_bb_61 {
        (__local_rc__goto_743_5 = -70)
        goto '__ci_bb_48
    }

    '__ci_bb_62 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_63 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), (__local_subject as *i8), (((__local_chkmc_length__goto_952_24 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_952_24)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_952_24)
        goto '__ci_bb_64
    }

    '__ci_bb_64 {
        goto '__ci_bb_58
    }

    '__ci_bb_65 {
        goto '__ci_bb_67
    }

    '__ci_bb_66 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_952_24 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_64
    }

    '__ci_bb_67 {
        (__local_rc__goto_743_5 = -48)
        goto '__ci_bb_48
    }

    '__ci_bb_68 {
        goto '__ci_bb_69
    }

    '__ci_bb_69 {
        (__local_ptrstackptr__goto_961_12 = 0)
        (__local_forcecase__goto_962_14 = case_state { to_case: 0, single_char: 0 })
        (__local_casestart_offset__goto_963_14 = 0)
        (__local_casestart_extra_needed__goto_964_14 = 0)
        if (__local_use_existing_match__goto_751_6 != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_70 {
        goto '__ci_bb_68
    }

    '__ci_bb_71 {
        if ((if not (__local_replacement_only__goto_752_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_533
        } else {
            goto '__ci_bb_534
        }
    }

    '__ci_bb_72 {
        (__local_rc__goto_743_5 = __local_match_data.rc)
        (__local_use_existing_match__goto_751_6 = 0)
        goto '__ci_bb_74
    }

    '__ci_bb_73 {
        (__local_rc__goto_743_5 = pcre2_match_8(__param_code, __local_subject, __local_length, __local_start_offset, ((__local_options as c_uint) | (__local_goptions__goto_746_10 as c_uint)), __local_match_data, __param_mcontext))
        goto '__ci_bb_74
    }

    '__ci_bb_74 {
        if (__local_utf__goto_753_6 != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_75 {
        (__local_options = __local_options | 1073741824)
        goto '__ci_bb_76
    }

    '__ci_bb_76 {
        if ((if __local_rc__goto_743_5 == -1: 1 else: 0) != 0) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_78
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_71
    }

    '__ci_bb_78 {
        if ((if __local_rc__goto_743_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_79
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_79 {
        goto '__ci_bb_48
    }

    '__ci_bb_80 {
        if ((if (unsafe: __local_ovector__goto_761_13[1]) < (unsafe: __local_ovector__goto_761_13[0]): 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if (if (unsafe: __local_ovector__goto_761_13[0]) < __local_start_offset: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_81 {
        (__local_rc__goto_743_5 = -60)
        goto '__ci_bb_48
    }

    '__ci_bb_82 {
        (__ci_expr_logic_14 = 0)
        if ((if __local_subs__goto_744_5 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_13: c_int

            if ((if (unsafe: __local_ovector__goto_761_13[1]) > __local_ovecsave__goto_762_12[1]: 1 else: 0) != 0) {
                (__ci_expr_logic_13 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_12: c_int = 0

                var __ci_expr_logic_11: c_int = 0

                if ((if (unsafe: __local_ovector__goto_761_13[1]) == (unsafe: __local_ovector__goto_761_13[0]): 1 else: 0) != 0) {
                    (__ci_expr_logic_11 = (if (if __local_ovecsave__goto_762_12[1] > __local_ovecsave__goto_762_12[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    (__ci_expr_logic_12 = (if (if (unsafe: __local_ovector__goto_761_13[1]) == __local_ovecsave__goto_762_12[1]: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_13 = (if __ci_expr_logic_12 != 0: 1 else: 0))

            }

            (__ci_expr_logic_14 = (if (if not (__ci_expr_logic_13 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_83 {
        goto '__ci_bb_85
    }

    '__ci_bb_84 {
        (__local_ovecsave__goto_762_12[0] = (unsafe: __local_ovector__goto_761_13[0]))
        (__local_ovecsave__goto_762_12[1] = (unsafe: __local_ovector__goto_761_13[1]))
        if ((if __local_subs__goto_744_5 == 2147483647: 1 else: 0) != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_85 {
        goto '__ci_bb_86
    }

    '__ci_bb_86 {
        if (0 != 0) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_87 {
        (__local_rc__goto_743_5 = -65)
        goto '__ci_bb_48
    }

    '__ci_bb_88 {
        (__local_rc__goto_743_5 = -61)
        goto '__ci_bb_48
    }

    '__ci_bb_89 {
        (__local_subs__goto_744_5 = __local_subs__goto_744_5 + 1)
        if ((if __local_rc__goto_743_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_91
        }
    }

    '__ci_bb_90 {
        (__local_rc__goto_743_5 = __local_ovector_count__goto_745_10)
        goto '__ci_bb_91
    }

    '__ci_bb_91 {
        (__local_fraglength__goto_760_50 = (((unsafe: __local_ovector__goto_761_13[0]) as c_ulong) -% (__local_start_offset as c_ulong)))
        if ((if not (__local_replacement_only__goto_752_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_92
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_92 {
        goto '__ci_bb_94
    }

    '__ci_bb_93 {
        (__local_scb__goto_763_32.output_offsets[0] = __local_buff_offset__goto_760_12)
        (__local_scb__goto_763_32.oveccount = __local_rc__goto_743_5)
        (__local_sub_start_extra_needed__goto_764_12 = __local_extra_needed__goto_759_12)
        (__local_ptr__goto_757_12 = __local_replacement)
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_108
        }
    }

    '__ci_bb_94 {
        (__local_chkmc_length__goto_1032_26 = __local_fraglength__goto_760_50)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_95 {
        if (0 != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_96
        }
    }

    '__ci_bb_96 {
        goto '__ci_bb_93
    }

    '__ci_bb_97 {
        if ((if __local_chkmc_length__goto_1032_26 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_98 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1032_26: 1 else: 0) != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_99 {
        goto '__ci_bb_95
    }

    '__ci_bb_100 {
        goto '__ci_bb_61
    }

    '__ci_bb_101 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1032_26)
        goto '__ci_bb_99
    }

    '__ci_bb_102 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_103 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), ((__local_subject + (__local_start_offset as usize)) as *i8), (((__local_chkmc_length__goto_1032_26 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1032_26)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1032_26)
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        goto '__ci_bb_99
    }

    '__ci_bb_105 {
        goto '__ci_bb_67
    }

    '__ci_bb_106 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1032_26 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_104
    }

    '__ci_bb_107 {
        goto '__ci_bb_110
    }

    '__ci_bb_108 {
        goto '__ci_bb_123
    }

    '__ci_bb_109 {
        (__ci_expr_logic_57 = 0)
        if ((if __local_substitute_case_callout__goto_765_14 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_57 = (if (if (&raw const __local_forcecase__goto_962_14 as *const case_state).to_case != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_57 != 0) {
            goto '__ci_bb_478
        } else {
            goto '__ci_bb_479
        }
    }

    '__ci_bb_110 {
        (__local_chkmc_length__goto_1043_5 = __local_rlength)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_111 {
        if (0 != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_112
        }
    }

    '__ci_bb_112 {
        goto '__ci_bb_109
    }

    '__ci_bb_113 {
        if ((if __local_chkmc_length__goto_1043_5 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_114 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1043_5: 1 else: 0) != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_115 {
        goto '__ci_bb_111
    }

    '__ci_bb_116 {
        goto '__ci_bb_61
    }

    '__ci_bb_117 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1043_5)
        goto '__ci_bb_115
    }

    '__ci_bb_118 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_119 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), (__local_ptr__goto_757_12 as *i8), (((__local_chkmc_length__goto_1043_5 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1043_5)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1043_5)
        goto '__ci_bb_120
    }

    '__ci_bb_120 {
        goto '__ci_bb_115
    }

    '__ci_bb_121 {
        goto '__ci_bb_67
    }

    '__ci_bb_122 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1043_5 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_120
    }

    '__ci_bb_123 {
        goto '__ci_bb_124
    }

    '__ci_bb_124 {
        (__local_text1_start__goto_1057_16 = null)
        (__local_text1_end__goto_1058_16 = null)
        (__local_text2_start__goto_1059_16 = null)
        (__local_text2_end__goto_1060_16 = null)
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_125 {
        goto '__ci_bb_123
    }

    '__ci_bb_126 {
        goto '__ci_bb_109
    }

    '__ci_bb_127 {
        if ((if __local_ptrstackptr__goto_961_12 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_128 {
        if (__local_escaped_literal__goto_749_6 != 0) {
            goto '__ci_bb_131
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_129 {
        goto '__ci_bb_126
    }

    '__ci_bb_130 {
        (__local_ptrstackptr__goto_961_12 = __local_ptrstackptr__goto_961_12 - 1)
        (__local_repend__goto_758_12 = __local_ptrstack__goto_960_14[__local_ptrstackptr__goto_961_12])
        (__local_ptrstackptr__goto_961_12 = __local_ptrstackptr__goto_961_12 - 1)
        (__local_ptr__goto_757_12 = __local_ptrstack__goto_960_14[__local_ptrstackptr__goto_961_12])
        goto '__ci_bb_125
    }

    '__ci_bb_131 {
        (__ci_expr_logic_16 = 0)
        (__ci_expr_logic_15 = 0)
        if ((if (unsafe: __local_ptr__goto_757_12[0]) == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if __local_ptr__goto_757_12 < (__local_repend__goto_758_12 - ((1 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_logic_16 = (if (if (unsafe: __local_ptr__goto_757_12[1]) == 69: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_132 {
        if ((if (unsafe: *__local_ptr__goto_757_12) == 36: 1 else: 0) != 0) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_133 {
        (__local_escaped_literal__goto_749_6 = 0)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        goto '__ci_bb_125
    }

    '__ci_bb_134 {
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        (__local_ch_start__goto_1585_18 = __local_ptr__goto_757_12)
        (__ci_expr_old_52 = __local_ptr__goto_757_12)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_ch__goto_1053_14 = (unsafe: *__ci_expr_old_52))
        (__ci_expr_logic_53 = 0)
        if (__local_utf__goto_753_6 != 0) {
            (__ci_expr_logic_53 = (if (if __local_ch__goto_1053_14 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_53 != 0) {
            goto '__ci_bb_436
        } else {
            goto '__ci_bb_437
        }
    }

    '__ci_bb_136 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            goto '__ci_bb_139
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_137 {
        (__ci_expr_logic_42 = 0)
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_42 = (if (if (unsafe: *__local_ptr__goto_757_12) == 92: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_42 != 0) {
            goto '__ci_bb_333
        } else {
            goto '__ci_bb_334
        }
    }

    '__ci_bb_138 {
        goto '__ci_bb_125
    }

    '__ci_bb_139 {
        goto '__ci_bb_141
    }

    '__ci_bb_140 {
        (__local_next__goto_1094_19 = (unsafe: *__local_ptr__goto_757_12))
        if ((if __local_next__goto_1094_19 == 36: 1 else: 0) != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_141 {
        (__local_rc__goto_743_5 = -35)
        goto '__ci_bb_151
    }

    '__ci_bb_142 {
        goto '__ci_bb_135
    }

    '__ci_bb_143 {
        (__local_special__goto_1056_14 = 0)
        (__local_text1_start__goto_1057_16 = null)
        (__local_text1_end__goto_1058_16 = null)
        (__local_text2_start__goto_1059_16 = null)
        (__local_text2_end__goto_1060_16 = null)
        (__local_group__goto_1055_9 = -1)
        (__local_inparens__goto_1090_12 = 0)
        (__local_inangle__goto_1091_12 = 0)
        (__local_star__goto_1092_12 = 0)
        (__local_subptr__goto_1095_18 = null)
        (__local_subptrend__goto_1095_26 = null)
        if ((if __local_next__goto_1094_19 == 38: 1 else: 0) != 0) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_144 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_group__goto_1055_9 = 0)
        goto '__ci_bb_146
    }

    '__ci_bb_145 {
        if ((if __local_next__goto_1094_19 == 96: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_17 = (if (if __local_next__goto_1094_19 == 39: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_146 {
        if ((if __local_group__goto_1055_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_264
        } else {
            goto '__ci_bb_265
        }
    }

    '__ci_bb_147 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_rc__goto_743_5 = pcre2_substring_length_bynumber_8(__local_match_data, 0, (&raw mut __local_sublength__goto_1093_18 as *mut c_ulong)))
        if ((if __local_rc__goto_743_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_149
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_148 {
        if ((if __local_next__goto_1094_19 == 95: 1 else: 0) != 0) {
            goto '__ci_bb_156
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_149 {
        goto '__ci_bb_151
    }

    '__ci_bb_150 {
        if ((if __local_next__goto_1094_19 == 96: 1 else: 0) != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_151 {
        ((unsafe: *__param_blength) = (((((__local_ptr__goto_757_12 as usize) -% (__local_replacement as usize)) / sizeof[u8]()) as c_ulong)))
        goto '__ci_bb_48
    }

    '__ci_bb_152 {
        (__local_subptr__goto_1095_18 = __local_subject)
        (__local_subptrend__goto_1095_26 = __local_subject + ((unsafe: __local_ovector__goto_761_13[0]) as usize))
        goto '__ci_bb_154
    }

    '__ci_bb_153 {
        (__local_subptr__goto_1095_18 = __local_subject + ((unsafe: __local_ovector__goto_761_13[1]) as usize))
        (__local_subptrend__goto_1095_26 = __local_subject + (__local_length as usize))
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        goto '__ci_bb_155
    }

    '__ci_bb_155 {
        (__ci_expr_logic_40 = 0)
        if ((if (&raw const __local_forcecase__goto_962_14 as *const case_state).to_case != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_40 = (if (if __local_substitute_case_callout__goto_765_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_40 != 0) {
            goto '__ci_bb_305
        } else {
            goto '__ci_bb_306
        }
    }

    '__ci_bb_156 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_subptr__goto_1095_18 = __local_subject)
        (__local_subptrend__goto_1095_26 = __local_subject + (__local_length as usize))
        goto '__ci_bb_155
    }

    '__ci_bb_157 {
        (__ci_expr_logic_19 = 0)
        if ((if __local_next__goto_1094_19 == 43: 1 else: 0) != 0) {
            var __ci_expr_logic_18: c_int = 0

            if ((if (__local_ptr__goto_757_12 + ((1 as isize) as usize)) < __local_repend__goto_758_12: 1 else: 0) != 0) {
                (__ci_expr_logic_18 = (if (if (unsafe: __local_ptr__goto_757_12[1]) == 123: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_19 = (if (if not (__ci_expr_logic_18 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_158 {
        if ((if __local_next__goto_1094_19 == 123: 1 else: 0) != 0) {
            goto '__ci_bb_178
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_159 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __param_code.top_bracket == 0: 1 else: 0) != 0) {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_160 {
        goto '__ci_bb_158
    }

    '__ci_bb_161 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (2048 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_162 {
        if ((if __local_match_data.oveccount < ((__param_code.top_bracket as c_int) + 1): 1 else: 0) != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_163 {
        if ((if __local_group__goto_1055_9 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_164 {
        (__local_rc__goto_743_5 = -49)
        goto '__ci_bb_151
    }

    '__ci_bb_165 {
        (__local_group__goto_1055_9 = 0)
        goto '__ci_bb_163
    }

    '__ci_bb_166 {
        (__local_rc__goto_743_5 = -54)
        goto '__ci_bb_151
    }

    '__ci_bb_167 {
        (__local_group__goto_1055_9 = __param_code.top_bracket)
        goto '__ci_bb_168
    }

    '__ci_bb_168 {
        if ((if __local_group__goto_1055_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_169 {
        if ((if (unsafe: __local_ovector__goto_761_13[(2 * __local_group__goto_1055_9)]) != (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_170 {
        (__local_group__goto_1055_9 = __local_group__goto_1055_9 - 1)
        goto '__ci_bb_168
    }

    '__ci_bb_171 {
        goto '__ci_bb_163
    }

    '__ci_bb_172 {
        goto '__ci_bb_171
    }

    '__ci_bb_173 {
        goto '__ci_bb_170
    }

    '__ci_bb_174 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_175 {
        goto '__ci_bb_146
    }

    '__ci_bb_176 {
        goto '__ci_bb_125
    }

    '__ci_bb_177 {
        (__local_rc__goto_743_5 = -55)
        goto '__ci_bb_151
    }

    '__ci_bb_178 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            goto '__ci_bb_181
        } else {
            goto '__ci_bb_182
        }
    }

    '__ci_bb_179 {
        if ((if __local_next__goto_1094_19 == 60: 1 else: 0) != 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_180 {
        (__ci_expr_logic_20 = 0)
        if ((if not (__local_inangle__goto_1091_12 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if __local_next__goto_1094_19 == 42: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_20 != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_181 {
        goto '__ci_bb_141
    }

    '__ci_bb_182 {
        (__local_next__goto_1094_19 = (unsafe: *__local_ptr__goto_757_12))
        (__local_inparens__goto_1090_12 = 1)
        goto '__ci_bb_180
    }

    '__ci_bb_183 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_184 {
        goto '__ci_bb_180
    }

    '__ci_bb_185 {
        goto '__ci_bb_141
    }

    '__ci_bb_186 {
        (__local_next__goto_1094_19 = (unsafe: *__local_ptr__goto_757_12))
        (__local_inangle__goto_1091_12 = 1)
        goto '__ci_bb_184
    }

    '__ci_bb_187 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_188 {
        (__ci_expr_logic_23 = 0)
        (__ci_expr_logic_22 = 0)
        (__ci_expr_logic_21 = 0)
        if ((if not (__local_star__goto_1092_12 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if (if not (__local_inangle__goto_1091_12 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_logic_22 = (if (if __local_next__goto_1094_19 >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_logic_23 = (if (if __local_next__goto_1094_19 <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_189 {
        goto '__ci_bb_141
    }

    '__ci_bb_190 {
        (__local_next__goto_1094_19 = (unsafe: *__local_ptr__goto_757_12))
        (__local_star__goto_1092_12 = 1)
        goto '__ci_bb_188
    }

    '__ci_bb_191 {
        (__local_group__goto_1055_9 = (__local_next__goto_1094_19 as c_int) - 48)
        goto '__ci_bb_194
    }

    '__ci_bb_192 {
        (__local_name_start__goto_1240_20 = __local_ptr__goto_757_12)
        if ((if not (read_name_subst((&raw mut __local_ptr__goto_757_12 as *mut *const u8), __local_repend__goto_758_12, __local_utf__goto_753_6, (__param_code.tables + (((512 + 320) as isize) as usize))) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_207
        } else {
            goto '__ci_bb_208
        }
    }

    '__ci_bb_193 {
        (__local_next__goto_1094_19 = 0)
        __local_next__goto_1094_19
        if (__local_inparens__goto_1090_12 != 0) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_194 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __local_ptr__goto_757_12 < __local_repend__goto_758_12: 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_195 {
        (__local_next__goto_1094_19 = (unsafe: *__local_ptr__goto_757_12))
        if ((if __local_next__goto_1094_19 < 48: 1 else: 0) != 0) {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if (if __local_next__goto_1094_19 > 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_196 {
        goto '__ci_bb_193
    }

    '__ci_bb_197 {
        goto '__ci_bb_196
    }

    '__ci_bb_198 {
        (__local_group__goto_1055_9 = (__local_group__goto_1055_9 * 10) + ((__local_next__goto_1094_19 as c_int) - 48))
        if ((if __local_group__goto_1055_9 > __param_code.top_bracket: 1 else: 0) != 0) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_200
        }
    }

    '__ci_bb_199 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_201
        } else {
            goto '__ci_bb_202
        }
    }

    '__ci_bb_200 {
        goto '__ci_bb_194
    }

    '__ci_bb_201 {
        goto '__ci_bb_204
    }

    '__ci_bb_202 {
        (__local_rc__goto_743_5 = -49)
        goto '__ci_bb_151
    }

    '__ci_bb_204 {
        (__ci_expr_logic_26 = 0)
        (__ci_expr_logic_25 = 0)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        if ((if __local_ptr__goto_757_12 < __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if (if (unsafe: *__local_ptr__goto_757_12) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            (__ci_expr_logic_26 = (if (if (unsafe: *__local_ptr__goto_757_12) <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_205 {
        goto '__ci_bb_204
    }

    '__ci_bb_206 {
        goto '__ci_bb_196
    }

    '__ci_bb_207 {
        goto '__ci_bb_141
    }

    '__ci_bb_208 {
        (__local_name_len__goto_1239_20 = ((__local_ptr__goto_757_12 as usize) -% (__local_name_start__goto_1240_20 as usize)) / sizeof[u8]())
        with_memcpy(((&(unsafe: __local_name__goto_1061_17[0]) as *mut u8) as *i8), (__local_name_start__goto_1240_20 as *i8), (((__local_name_len__goto_1239_20 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_name__goto_1061_17[__local_name_len__goto_1239_20] = 0)
        goto '__ci_bb_193
    }

    '__ci_bb_209 {
        (__ci_expr_logic_29 = 0)
        (__ci_expr_logic_28 = 0)
        (__ci_expr_logic_27 = 0)
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_27 = (if (if not (__local_star__goto_1092_12 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_27 != 0) {
            (__ci_expr_logic_28 = (if (if __local_ptr__goto_757_12 < (__local_repend__goto_758_12 - ((2 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_28 != 0) {
            (__ci_expr_logic_29 = (if (if (unsafe: *__local_ptr__goto_757_12) == 58: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_29 != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_210 {
        if (__local_inangle__goto_1091_12 != 0) {
            goto '__ci_bb_224
        } else {
            goto '__ci_bb_225
        }
    }

    '__ci_bb_211 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_special__goto_1056_14 = (unsafe: *__local_ptr__goto_757_12))
        (__ci_expr_logic_30 = 0)
        if ((if __local_special__goto_1056_14 != 43: 1 else: 0) != 0) {
            (__ci_expr_logic_30 = (if (if __local_special__goto_1056_14 != 45: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_30 != 0) {
            goto '__ci_bb_214
        } else {
            goto '__ci_bb_215
        }
    }

    '__ci_bb_212 {
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_32 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_32 = (if (if (unsafe: *__local_ptr__goto_757_12) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            goto '__ci_bb_222
        } else {
            goto '__ci_bb_223
        }
    }

    '__ci_bb_213 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        goto '__ci_bb_210
    }

    '__ci_bb_214 {
        (__local_rc__goto_743_5 = -59)
        goto '__ci_bb_151
    }

    '__ci_bb_215 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_text1_start__goto_1057_16 = __local_ptr__goto_757_12)
        (__local_rc__goto_743_5 = find_text_end(__param_code, (&raw mut __local_ptr__goto_757_12 as *mut *const u8), __local_repend__goto_758_12, (if __local_special__goto_1056_14 == 45: 1 else: 0)))
        if ((if __local_rc__goto_743_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_216
        } else {
            goto '__ci_bb_217
        }
    }

    '__ci_bb_216 {
        goto '__ci_bb_151
    }

    '__ci_bb_217 {
        (__local_text1_end__goto_1058_16 = __local_ptr__goto_757_12)
        (__ci_expr_logic_31 = 0)
        if ((if __local_special__goto_1056_14 == 43: 1 else: 0) != 0) {
            (__ci_expr_logic_31 = (if (if (unsafe: *__local_ptr__goto_757_12) == 58: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_218
        } else {
            goto '__ci_bb_219
        }
    }

    '__ci_bb_218 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_text2_start__goto_1059_16 = __local_ptr__goto_757_12)
        (__local_rc__goto_743_5 = find_text_end(__param_code, (&raw mut __local_ptr__goto_757_12 as *mut *const u8), __local_repend__goto_758_12, 1))
        if ((if __local_rc__goto_743_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_219 {
        goto '__ci_bb_213
    }

    '__ci_bb_220 {
        goto '__ci_bb_151
    }

    '__ci_bb_221 {
        (__local_text2_end__goto_1060_16 = __local_ptr__goto_757_12)
        goto '__ci_bb_219
    }

    '__ci_bb_222 {
        (__local_rc__goto_743_5 = -58)
        goto '__ci_bb_151
    }

    '__ci_bb_223 {
        goto '__ci_bb_213
    }

    '__ci_bb_224 {
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_33 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_33 = (if (if (unsafe: *__local_ptr__goto_757_12) != 62: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_33 != 0) {
            goto '__ci_bb_226
        } else {
            goto '__ci_bb_227
        }
    }

    '__ci_bb_225 {
        if (__local_star__goto_1092_12 != 0) {
            goto '__ci_bb_228
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_226 {
        goto '__ci_bb_141
    }

    '__ci_bb_227 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        goto '__ci_bb_225
    }

    '__ci_bb_228 {
        if ((if _pcre2_strcmp_c8_8((&(unsafe: __local_name__goto_1061_17[0]) as *mut u8), "\x4d\x41\x52\x4b") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_231
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_229 {
        goto '__ci_bb_146
    }

    '__ci_bb_230 {
        goto '__ci_bb_138
    }

    '__ci_bb_231 {
        (__local_mark__goto_1306_22 = pcre2_get_mark_8(__local_match_data))
        if ((if __local_mark__goto_1306_22 != null: 1 else: 0) != 0) {
            goto '__ci_bb_234
        } else {
            goto '__ci_bb_235
        }
    }

    '__ci_bb_232 {
        goto '__ci_bb_141
    }

    '__ci_bb_233 {
        goto '__ci_bb_230
    }

    '__ci_bb_234 {
        (__local_fraglength__goto_760_50 = (unsafe: __local_mark__goto_1306_22[-1]))
        (__ci_expr_logic_34 = 0)
        if ((if (&raw const __local_forcecase__goto_962_14 as *const case_state).to_case != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_34 = (if (if __local_substitute_case_callout__goto_765_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_236
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_235 {
        goto '__ci_bb_233
    }

    '__ci_bb_236 {
        goto '__ci_bb_239
    }

    '__ci_bb_237 {
        goto '__ci_bb_251
    }

    '__ci_bb_238 {
        goto '__ci_bb_235
    }

    '__ci_bb_239 {
        (__local_chkcc_length__goto_1314_15 = __local_fraglength__goto_760_50)
        (__ci_expr_ternary_35 = 0)
        if (__local_overflowed__goto_750_6 != 0) {
            (__ci_expr_ternary_35 = 0)
        } else {
            (__ci_expr_ternary_35 = __local_lengthleft__goto_760_38)
        }
        (__local_chkcc_rc__goto_1314_15 = default_substitute_case_callout(__local_mark__goto_1306_22, __local_chkcc_length__goto_1314_15, (__param_buffer + (__local_buff_offset__goto_760_12 as usize)), __ci_expr_ternary_35, (&raw mut __local_forcecase__goto_962_14 as *mut case_state), __param_code))
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_242
        } else {
            goto '__ci_bb_243
        }
    }

    '__ci_bb_240 {
        if (0 != 0) {
            goto '__ci_bb_239
        } else {
            goto '__ci_bb_241
        }
    }

    '__ci_bb_241 {
        goto '__ci_bb_238
    }

    '__ci_bb_242 {
        if ((if __local_chkcc_rc__goto_1314_15 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_244
        } else {
            goto '__ci_bb_245
        }
    }

    '__ci_bb_243 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkcc_rc__goto_1314_15: 1 else: 0) != 0) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_244 {
        goto '__ci_bb_61
    }

    '__ci_bb_245 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkcc_rc__goto_1314_15)
        goto '__ci_bb_241
    }

    '__ci_bb_246 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_249
        } else {
            goto '__ci_bb_250
        }
    }

    '__ci_bb_247 {
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkcc_rc__goto_1314_15)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkcc_rc__goto_1314_15)
        goto '__ci_bb_248
    }

    '__ci_bb_248 {
        goto '__ci_bb_240
    }

    '__ci_bb_249 {
        goto '__ci_bb_67
    }

    '__ci_bb_250 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkcc_rc__goto_1314_15 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_248
    }

    '__ci_bb_251 {
        (__local_chkmc_length__goto_1316_15 = __local_fraglength__goto_760_50)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_254
        } else {
            goto '__ci_bb_255
        }
    }

    '__ci_bb_252 {
        if (0 != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_253
        }
    }

    '__ci_bb_253 {
        goto '__ci_bb_238
    }

    '__ci_bb_254 {
        if ((if __local_chkmc_length__goto_1316_15 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_257
        } else {
            goto '__ci_bb_258
        }
    }

    '__ci_bb_255 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1316_15: 1 else: 0) != 0) {
            goto '__ci_bb_259
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_256 {
        goto '__ci_bb_252
    }

    '__ci_bb_257 {
        goto '__ci_bb_61
    }

    '__ci_bb_258 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1316_15)
        goto '__ci_bb_256
    }

    '__ci_bb_259 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_262
        } else {
            goto '__ci_bb_263
        }
    }

    '__ci_bb_260 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), (__local_mark__goto_1306_22 as *i8), (((__local_chkmc_length__goto_1316_15 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1316_15)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1316_15)
        goto '__ci_bb_261
    }

    '__ci_bb_261 {
        goto '__ci_bb_256
    }

    '__ci_bb_262 {
        goto '__ci_bb_67
    }

    '__ci_bb_263 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1316_15 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_261
    }

    '__ci_bb_264 {
        (__local_rc__goto_743_5 = pcre2_substring_nametable_scan_8(__param_code, (&(unsafe: __local_name__goto_1061_17[0]) as *mut u8), (&raw mut __local_first__goto_1335_22 as *mut *const u8), (&raw mut __local_last__goto_1335_29 as *mut *const u8)))
        (__ci_expr_logic_36 = 0)
        if ((if __local_rc__goto_743_5 == -49: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if (if ((__local_suboptions__goto_747_10 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_266
        } else {
            goto '__ci_bb_267
        }
    }

    '__ci_bb_265 {
        (__local_rc__goto_743_5 = pcre2_substring_length_bynumber_8(__local_match_data, __local_group__goto_1055_9, (&raw mut __local_sublength__goto_1093_18 as *mut c_ulong)))
        if ((if __local_rc__goto_743_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_283
        } else {
            goto '__ci_bb_284
        }
    }

    '__ci_bb_266 {
        (__local_group__goto_1055_9 = (__param_code.top_bracket as c_int) + 1)
        goto '__ci_bb_268
    }

    '__ci_bb_267 {
        if ((if __local_rc__goto_743_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_269
        } else {
            goto '__ci_bb_270
        }
    }

    '__ci_bb_268 {
        goto '__ci_bb_265
    }

    '__ci_bb_269 {
        goto '__ci_bb_151
    }

    '__ci_bb_270 {
        (__local_entry__goto_1335_35 = __local_first__goto_1335_22)
        goto '__ci_bb_271
    }

    '__ci_bb_271 {
        if ((if __local_entry__goto_1335_35 <= __local_last__goto_1335_29: 1 else: 0) != 0) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_274
        }
    }

    '__ci_bb_272 {
        (__local_ng__goto_1347_24 = ((((((unsafe: __local_entry__goto_1335_35[0]) as c_int) << (8 as c_uint)) | ((unsafe: __local_entry__goto_1335_35[(0 + 1)]) as c_int)) as c_uint)))
        if ((if __local_ng__goto_1347_24 < __local_ovector_count__goto_745_10: 1 else: 0) != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_273 {
        (__local_entry__goto_1335_35 = __local_entry__goto_1335_35 + ((__local_rc__goto_743_5 as isize) as usize))
        goto '__ci_bb_271
    }

    '__ci_bb_274 {
        if ((if __local_group__goto_1055_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_282
        }
    }

    '__ci_bb_275 {
        if ((if __local_group__goto_1055_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_277
        } else {
            goto '__ci_bb_278
        }
    }

    '__ci_bb_276 {
        goto '__ci_bb_273
    }

    '__ci_bb_277 {
        (__local_group__goto_1055_9 = __local_ng__goto_1347_24)
        goto '__ci_bb_278
    }

    '__ci_bb_278 {
        if ((if (unsafe: __local_ovector__goto_761_13[((__local_ng__goto_1347_24 as c_uint) *% (2 as c_uint))]) != (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_279
        } else {
            goto '__ci_bb_280
        }
    }

    '__ci_bb_279 {
        (__local_group__goto_1055_9 = __local_ng__goto_1347_24)
        goto '__ci_bb_274
    }

    '__ci_bb_280 {
        goto '__ci_bb_276
    }

    '__ci_bb_281 {
        (__local_group__goto_1055_9 = ((((((unsafe: __local_first__goto_1335_22[0]) as c_int) << (8 as c_uint)) | ((unsafe: __local_first__goto_1335_22[(0 + 1)]) as c_int)) as c_uint)))
        goto '__ci_bb_282
    }

    '__ci_bb_282 {
        goto '__ci_bb_268
    }

    '__ci_bb_283 {
        (__ci_expr_logic_37 = 0)
        if ((if __local_rc__goto_743_5 == -49: 1 else: 0) != 0) {
            (__ci_expr_logic_37 = (if (if ((__local_suboptions__goto_747_10 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_285
        } else {
            goto '__ci_bb_286
        }
    }

    '__ci_bb_284 {
        if ((if __local_special__goto_1056_14 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_293
        } else {
            goto '__ci_bb_294
        }
    }

    '__ci_bb_285 {
        (__local_rc__goto_743_5 = -55)
        goto '__ci_bb_286
    }

    '__ci_bb_286 {
        if ((if __local_rc__goto_743_5 != -55: 1 else: 0) != 0) {
            goto '__ci_bb_287
        } else {
            goto '__ci_bb_288
        }
    }

    '__ci_bb_287 {
        goto '__ci_bb_151
    }

    '__ci_bb_288 {
        if ((if __local_special__goto_1056_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_289
        } else {
            goto '__ci_bb_290
        }
    }

    '__ci_bb_289 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_291
        } else {
            goto '__ci_bb_292
        }
    }

    '__ci_bb_290 {
        goto '__ci_bb_284
    }

    '__ci_bb_291 {
        goto '__ci_bb_125
    }

    '__ci_bb_292 {
        goto '__ci_bb_151
    }

    '__ci_bb_293 {
        if ((if __local_special__goto_1056_14 == 45: 1 else: 0) != 0) {
            goto '__ci_bb_295
        } else {
            goto '__ci_bb_296
        }
    }

    '__ci_bb_294 {
        goto '__ci_bb_299
    }

    '__ci_bb_295 {
        if ((if __local_rc__goto_743_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_298
        }
    }

    '__ci_bb_296 {
        if ((if __local_ptrstackptr__goto_961_12 >= 20: 1 else: 0) != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_297 {
        goto '__ci_bb_299
    }

    '__ci_bb_298 {
        (__local_text2_start__goto_1059_16 = __local_text1_start__goto_1057_16)
        (__local_text2_end__goto_1060_16 = __local_text1_end__goto_1058_16)
        goto '__ci_bb_296
    }

    '__ci_bb_299 {
        (__local_subptr__goto_1095_18 = __local_subject + ((unsafe: __local_ovector__goto_761_13[(__local_group__goto_1055_9 * 2)]) as usize))
        (__local_subptrend__goto_1095_26 = __local_subject + ((unsafe: __local_ovector__goto_761_13[((__local_group__goto_1055_9 * 2) + 1)]) as usize))
        goto '__ci_bb_155
    }

    '__ci_bb_300 {
        goto '__ci_bb_141
    }

    '__ci_bb_301 {
        (__ci_expr_old_38 = __local_ptrstackptr__goto_961_12)
        (__local_ptrstackptr__goto_961_12 = __local_ptrstackptr__goto_961_12 + 1)
        (__local_ptrstack__goto_960_14[__ci_expr_old_38] = __local_ptr__goto_757_12)
        (__ci_expr_old_39 = __local_ptrstackptr__goto_961_12)
        (__local_ptrstackptr__goto_961_12 = __local_ptrstackptr__goto_961_12 + 1)
        (__local_ptrstack__goto_960_14[__ci_expr_old_39] = __local_repend__goto_758_12)
        if ((if __local_rc__goto_743_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_302
        } else {
            goto '__ci_bb_303
        }
    }

    '__ci_bb_302 {
        (__local_ptr__goto_757_12 = __local_text1_start__goto_1057_16)
        (__local_repend__goto_758_12 = __local_text1_end__goto_1058_16)
        goto '__ci_bb_304
    }

    '__ci_bb_303 {
        (__local_ptr__goto_757_12 = __local_text2_start__goto_1059_16)
        (__local_repend__goto_758_12 = __local_text2_end__goto_1060_16)
        goto '__ci_bb_304
    }

    '__ci_bb_304 {
        goto '__ci_bb_125
    }

    '__ci_bb_305 {
        goto '__ci_bb_308
    }

    '__ci_bb_306 {
        goto '__ci_bb_320
    }

    '__ci_bb_307 {
        goto '__ci_bb_230
    }

    '__ci_bb_308 {
        (__local_chkcc_length__goto_1427_11 = (((((__local_subptrend__goto_1095_26 as usize) -% (__local_subptr__goto_1095_18 as usize)) / sizeof[u8]()) as c_ulong)))
        (__ci_expr_ternary_41 = 0)
        if (__local_overflowed__goto_750_6 != 0) {
            (__ci_expr_ternary_41 = 0)
        } else {
            (__ci_expr_ternary_41 = __local_lengthleft__goto_760_38)
        }
        (__local_chkcc_rc__goto_1427_11 = default_substitute_case_callout(__local_subptr__goto_1095_18, __local_chkcc_length__goto_1427_11, (__param_buffer + (__local_buff_offset__goto_760_12 as usize)), __ci_expr_ternary_41, (&raw mut __local_forcecase__goto_962_14 as *mut case_state), __param_code))
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_312
        }
    }

    '__ci_bb_309 {
        if (0 != 0) {
            goto '__ci_bb_308
        } else {
            goto '__ci_bb_310
        }
    }

    '__ci_bb_310 {
        goto '__ci_bb_307
    }

    '__ci_bb_311 {
        if ((if __local_chkcc_rc__goto_1427_11 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_313
        } else {
            goto '__ci_bb_314
        }
    }

    '__ci_bb_312 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkcc_rc__goto_1427_11: 1 else: 0) != 0) {
            goto '__ci_bb_315
        } else {
            goto '__ci_bb_316
        }
    }

    '__ci_bb_313 {
        goto '__ci_bb_61
    }

    '__ci_bb_314 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkcc_rc__goto_1427_11)
        goto '__ci_bb_310
    }

    '__ci_bb_315 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_318
        } else {
            goto '__ci_bb_319
        }
    }

    '__ci_bb_316 {
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkcc_rc__goto_1427_11)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkcc_rc__goto_1427_11)
        goto '__ci_bb_317
    }

    '__ci_bb_317 {
        goto '__ci_bb_309
    }

    '__ci_bb_318 {
        goto '__ci_bb_67
    }

    '__ci_bb_319 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkcc_rc__goto_1427_11 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_317
    }

    '__ci_bb_320 {
        (__local_chkmc_length__goto_1429_11 = ((__local_subptrend__goto_1095_26 as usize) -% (__local_subptr__goto_1095_18 as usize)) / sizeof[u8]())
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_323
        } else {
            goto '__ci_bb_324
        }
    }

    '__ci_bb_321 {
        if (0 != 0) {
            goto '__ci_bb_320
        } else {
            goto '__ci_bb_322
        }
    }

    '__ci_bb_322 {
        goto '__ci_bb_307
    }

    '__ci_bb_323 {
        if ((if __local_chkmc_length__goto_1429_11 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_326
        } else {
            goto '__ci_bb_327
        }
    }

    '__ci_bb_324 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1429_11: 1 else: 0) != 0) {
            goto '__ci_bb_328
        } else {
            goto '__ci_bb_329
        }
    }

    '__ci_bb_325 {
        goto '__ci_bb_321
    }

    '__ci_bb_326 {
        goto '__ci_bb_61
    }

    '__ci_bb_327 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1429_11)
        goto '__ci_bb_325
    }

    '__ci_bb_328 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_331
        } else {
            goto '__ci_bb_332
        }
    }

    '__ci_bb_329 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), (__local_subptr__goto_1095_18 as *i8), (((__local_chkmc_length__goto_1429_11 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1429_11)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1429_11)
        goto '__ci_bb_330
    }

    '__ci_bb_330 {
        goto '__ci_bb_325
    }

    '__ci_bb_331 {
        goto '__ci_bb_67
    }

    '__ci_bb_332 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1429_11 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_330
    }

    '__ci_bb_333 {
        (__local_new_forcecase__goto_1442_18 = case_state { to_case: 0, single_char: 0 })
        if ((if __local_ptr__goto_757_12 < (__local_repend__goto_758_12 - ((1 as isize) as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_336
        } else {
            goto '__ci_bb_337
        }
    }

    '__ci_bb_334 {
        goto '__ci_bb_135
    }

    '__ci_bb_335 {
        goto '__ci_bb_138
    }

    '__ci_bb_336 {
        goto '__ci_bb_338
    }

    '__ci_bb_337 {
        if ((if (&raw const __local_new_forcecase__goto_1442_18 as *const case_state).to_case != 0: 1 else: 0) != 0) {
            goto '__ci_bb_352
        } else {
            goto '__ci_bb_353
        }
    }

    '__ci_bb_338 {
        if ((unsafe: __local_ptr__goto_757_12[1]) == 76) {
            goto '__ci_bb_340
        } else {
            goto '__ci_bb_349
        }
    }

    '__ci_bb_339 {
        goto '__ci_bb_337
    }

    '__ci_bb_340 {
        (__local_new_forcecase__goto_1442_18.to_case = 1)
        (__local_new_forcecase__goto_1442_18.single_char = 0)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        goto '__ci_bb_339
    }

    '__ci_bb_341 {
        (__local_new_forcecase__goto_1442_18.to_case = 1)
        (__local_new_forcecase__goto_1442_18.single_char = 1)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        (__ci_expr_logic_44 = 0)
        (__ci_expr_logic_43 = 0)
        if ((if (__local_ptr__goto_757_12 + ((2 as isize) as usize)) < __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_43 = (if (if (unsafe: __local_ptr__goto_757_12[0]) == 92: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_43 != 0) {
            (__ci_expr_logic_44 = (if (if (unsafe: __local_ptr__goto_757_12[1]) == 85: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_44 != 0) {
            goto '__ci_bb_342
        } else {
            goto '__ci_bb_343
        }
    }

    '__ci_bb_342 {
        (__local_new_forcecase__goto_1442_18.to_case = 4)
        (__local_new_forcecase__goto_1442_18.single_char = 0)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        goto '__ci_bb_343
    }

    '__ci_bb_343 {
        goto '__ci_bb_339
    }

    '__ci_bb_344 {
        (__local_new_forcecase__goto_1442_18.to_case = 2)
        (__local_new_forcecase__goto_1442_18.single_char = 0)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        goto '__ci_bb_339
    }

    '__ci_bb_345 {
        (__local_new_forcecase__goto_1442_18.to_case = 3)
        (__local_new_forcecase__goto_1442_18.single_char = 1)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        (__ci_expr_logic_46 = 0)
        (__ci_expr_logic_45 = 0)
        if ((if (__local_ptr__goto_757_12 + ((2 as isize) as usize)) < __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_45 = (if (if (unsafe: __local_ptr__goto_757_12[0]) == 92: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_45 != 0) {
            (__ci_expr_logic_46 = (if (if (unsafe: __local_ptr__goto_757_12[1]) == 76: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_46 != 0) {
            goto '__ci_bb_346
        } else {
            goto '__ci_bb_347
        }
    }

    '__ci_bb_346 {
        (__local_new_forcecase__goto_1442_18.to_case = 3)
        (__local_new_forcecase__goto_1442_18.single_char = 0)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        goto '__ci_bb_347
    }

    '__ci_bb_347 {
        goto '__ci_bb_339
    }

    '__ci_bb_348 {
        goto '__ci_bb_339
    }

    '__ci_bb_349 {
        if ((unsafe: __local_ptr__goto_757_12[1]) == 108) {
            goto '__ci_bb_341
        } else {
            goto '__ci_bb_350
        }
    }

    '__ci_bb_350 {
        if ((unsafe: __local_ptr__goto_757_12[1]) == 85) {
            goto '__ci_bb_344
        } else {
            goto '__ci_bb_351
        }
    }

    '__ci_bb_351 {
        if ((unsafe: __local_ptr__goto_757_12[1]) == 117) {
            goto '__ci_bb_345
        } else {
            goto '__ci_bb_348
        }
    }

    '__ci_bb_352 {
        goto '__ci_bb_354
    }

    '__ci_bb_353 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_rc__goto_743_5 = _pcre2_check_escape_8((&raw mut __local_ptr__goto_757_12 as *mut *const u8), __local_repend__goto_758_12, (&raw mut __local_ch__goto_1053_14 as *mut c_uint), (&raw mut __local_errorcode__goto_1441_11 as *mut c_int), __param_code.overall_options, __param_code.extra_options, __param_code.top_bracket, 0, null))
        if ((if __local_errorcode__goto_1441_11 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_378
        } else {
            goto '__ci_bb_379
        }
    }

    '__ci_bb_354 {
        (__ci_expr_logic_47 = 0)
        if ((if __local_substitute_case_callout__goto_765_14 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_47 = (if (if (&raw const __local_forcecase__goto_962_14 as *const case_state).to_case != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_47 != 0) {
            goto '__ci_bb_355
        } else {
            goto '__ci_bb_356
        }
    }

    '__ci_bb_355 {
        goto '__ci_bb_357
    }

    '__ci_bb_356 {
        with_memcpy((&raw mut __local_forcecase__goto_962_14 as *i8), (&raw const __local_new_forcecase__goto_1442_18 as *i8), sizeof[case_state]())
        (__local_casestart_offset__goto_963_14 = __local_buff_offset__goto_760_12)
        (__local_casestart_extra_needed__goto_964_14 = __local_extra_needed__goto_759_12)
        goto '__ci_bb_125
    }

    '__ci_bb_357 {
        (__local_chars_outstanding__goto_1500_11 = ((((__local_buff_offset__goto_760_12 as c_ulong) -% (__local_casestart_offset__goto_963_14 as c_ulong)) as c_ulong) +% (((__local_extra_needed__goto_759_12 as c_ulong) -% (__local_casestart_extra_needed__goto_964_14 as c_ulong)) as c_ulong)))
        if ((if __local_chars_outstanding__goto_1500_11 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_360
        } else {
            goto '__ci_bb_361
        }
    }

    '__ci_bb_358 {
        if (0 != 0) {
            goto '__ci_bb_357
        } else {
            goto '__ci_bb_359
        }
    }

    '__ci_bb_359 {
        goto '__ci_bb_356
    }

    '__ci_bb_360 {
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_362
        } else {
            goto '__ci_bb_363
        }
    }

    '__ci_bb_361 {
        goto '__ci_bb_358
    }

    '__ci_bb_362 {
        (__local_guess__goto_1500_11 = pessimistic_case_inflation(__local_chars_outstanding__goto_1500_11))
        if ((if __local_guess__goto_1500_11 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_365
        } else {
            goto '__ci_bb_366
        }
    }

    '__ci_bb_363 {
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 + ((__local_buff_offset__goto_760_12 as c_ulong) -% (__local_casestart_offset__goto_963_14 as c_ulong)))
        (__local_buff_offset__goto_760_12 = __local_casestart_offset__goto_963_14)
        goto '__ci_bb_367
    }

    '__ci_bb_364 {
        goto '__ci_bb_361
    }

    '__ci_bb_365 {
        goto '__ci_bb_61
    }

    '__ci_bb_366 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_guess__goto_1500_11)
        goto '__ci_bb_364
    }

    '__ci_bb_367 {
        (__local_chkcc_length__goto_1500_11 = __local_chars_outstanding__goto_1500_11)
        (__local_chkcc_rc__goto_1500_11 = do_case_copy((__param_buffer + (__local_buff_offset__goto_760_12 as usize)), __local_chkcc_length__goto_1500_11, __local_lengthleft__goto_760_38, (&raw mut __local_forcecase__goto_962_14 as *mut case_state), __local_utf__goto_753_6, __local_substitute_case_callout__goto_765_14, __local_substitute_case_callout_data__goto_767_7))
        if ((if __local_chkcc_rc__goto_1500_11 == (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_370
        } else {
            goto '__ci_bb_371
        }
    }

    '__ci_bb_368 {
        if (0 != 0) {
            goto '__ci_bb_367
        } else {
            goto '__ci_bb_369
        }
    }

    '__ci_bb_369 {
        goto '__ci_bb_364
    }

    '__ci_bb_370 {
        goto '__ci_bb_372
    }

    '__ci_bb_371 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkcc_rc__goto_1500_11: 1 else: 0) != 0) {
            goto '__ci_bb_373
        } else {
            goto '__ci_bb_374
        }
    }

    '__ci_bb_372 {
        (__local_rc__goto_743_5 = -69)
        goto '__ci_bb_48
    }

    '__ci_bb_373 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_377
        }
    }

    '__ci_bb_374 {
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkcc_rc__goto_1500_11)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkcc_rc__goto_1500_11)
        goto '__ci_bb_375
    }

    '__ci_bb_375 {
        goto '__ci_bb_368
    }

    '__ci_bb_376 {
        goto '__ci_bb_67
    }

    '__ci_bb_377 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkcc_rc__goto_1500_11 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_375
    }

    '__ci_bb_378 {
        goto '__ci_bb_380
    }

    '__ci_bb_379 {
        goto '__ci_bb_381
    }

    '__ci_bb_380 {
        (__local_rc__goto_743_5 = -57)
        goto '__ci_bb_151
    }

    '__ci_bb_381 {
        if (__local_rc__goto_743_5 == 25) {
            goto '__ci_bb_383
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_383 {
        goto '__ci_bb_354
    }

    '__ci_bb_384 {
        (__local_escaped_literal__goto_749_6 = 1)
        goto '__ci_bb_125
    }

    '__ci_bb_385 {
        if ((if __local_rc__goto_743_5 == ESC_b: 1 else: 0) != 0) {
            goto '__ci_bb_386
        } else {
            goto '__ci_bb_387
        }
    }

    '__ci_bb_386 {
        (__local_ch__goto_1053_14 = 8)
        goto '__ci_bb_387
    }

    '__ci_bb_387 {
        if ((if __local_rc__goto_743_5 == ESC_v: 1 else: 0) != 0) {
            goto '__ci_bb_388
        } else {
            goto '__ci_bb_389
        }
    }

    '__ci_bb_388 {
        (__local_ch__goto_1053_14 = 11)
        goto '__ci_bb_389
    }

    '__ci_bb_389 {
        if (__local_utf__goto_753_6 != 0) {
            goto '__ci_bb_390
        } else {
            goto '__ci_bb_391
        }
    }

    '__ci_bb_390 {
        (__local_chlen__goto_1054_18 = _pcre2_ord2utf_8(__local_ch__goto_1053_14, (&(unsafe: __local_temp__goto_754_13[0]) as *mut u8)))
        goto '__ci_bb_392
    }

    '__ci_bb_391 {
        (__local_temp__goto_754_13[0] = __local_ch__goto_1053_14)
        (__local_chlen__goto_1054_18 = 1)
        goto '__ci_bb_392
    }

    '__ci_bb_392 {
        (__ci_expr_logic_48 = 0)
        if ((if (&raw const __local_forcecase__goto_962_14 as *const case_state).to_case != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_48 = (if (if __local_substitute_case_callout__goto_765_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_48 != 0) {
            goto '__ci_bb_393
        } else {
            goto '__ci_bb_394
        }
    }

    '__ci_bb_393 {
        goto '__ci_bb_396
    }

    '__ci_bb_394 {
        goto '__ci_bb_408
    }

    '__ci_bb_395 {
        goto '__ci_bb_125
    }

    '__ci_bb_396 {
        (__local_chkcc_length__goto_1539_11 = ((__local_chlen__goto_1054_18 as c_ulong)))
        (__ci_expr_ternary_49 = 0)
        if (__local_overflowed__goto_750_6 != 0) {
            (__ci_expr_ternary_49 = 0)
        } else {
            (__ci_expr_ternary_49 = __local_lengthleft__goto_760_38)
        }
        (__local_chkcc_rc__goto_1539_11 = default_substitute_case_callout((&(unsafe: __local_temp__goto_754_13[0]) as *mut u8), __local_chkcc_length__goto_1539_11, (__param_buffer + (__local_buff_offset__goto_760_12 as usize)), __ci_expr_ternary_49, (&raw mut __local_forcecase__goto_962_14 as *mut case_state), __param_code))
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_399
        } else {
            goto '__ci_bb_400
        }
    }

    '__ci_bb_397 {
        if (0 != 0) {
            goto '__ci_bb_396
        } else {
            goto '__ci_bb_398
        }
    }

    '__ci_bb_398 {
        goto '__ci_bb_395
    }

    '__ci_bb_399 {
        if ((if __local_chkcc_rc__goto_1539_11 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_401
        } else {
            goto '__ci_bb_402
        }
    }

    '__ci_bb_400 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkcc_rc__goto_1539_11: 1 else: 0) != 0) {
            goto '__ci_bb_403
        } else {
            goto '__ci_bb_404
        }
    }

    '__ci_bb_401 {
        goto '__ci_bb_61
    }

    '__ci_bb_402 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkcc_rc__goto_1539_11)
        goto '__ci_bb_398
    }

    '__ci_bb_403 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_406
        } else {
            goto '__ci_bb_407
        }
    }

    '__ci_bb_404 {
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkcc_rc__goto_1539_11)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkcc_rc__goto_1539_11)
        goto '__ci_bb_405
    }

    '__ci_bb_405 {
        goto '__ci_bb_397
    }

    '__ci_bb_406 {
        goto '__ci_bb_67
    }

    '__ci_bb_407 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkcc_rc__goto_1539_11 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_405
    }

    '__ci_bb_408 {
        (__local_chkmc_length__goto_1541_11 = __local_chlen__goto_1054_18)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_411
        } else {
            goto '__ci_bb_412
        }
    }

    '__ci_bb_409 {
        if (0 != 0) {
            goto '__ci_bb_408
        } else {
            goto '__ci_bb_410
        }
    }

    '__ci_bb_410 {
        goto '__ci_bb_395
    }

    '__ci_bb_411 {
        if ((if __local_chkmc_length__goto_1541_11 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_414
        } else {
            goto '__ci_bb_415
        }
    }

    '__ci_bb_412 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1541_11: 1 else: 0) != 0) {
            goto '__ci_bb_416
        } else {
            goto '__ci_bb_417
        }
    }

    '__ci_bb_413 {
        goto '__ci_bb_409
    }

    '__ci_bb_414 {
        goto '__ci_bb_61
    }

    '__ci_bb_415 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1541_11)
        goto '__ci_bb_413
    }

    '__ci_bb_416 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_419
        } else {
            goto '__ci_bb_420
        }
    }

    '__ci_bb_417 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), ((&(unsafe: __local_temp__goto_754_13[0]) as *mut u8) as *i8), (((__local_chkmc_length__goto_1541_11 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1541_11)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1541_11)
        goto '__ci_bb_418
    }

    '__ci_bb_418 {
        goto '__ci_bb_413
    }

    '__ci_bb_419 {
        goto '__ci_bb_67
    }

    '__ci_bb_420 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1541_11 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_418
    }

    '__ci_bb_421 {
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_50 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_50 = (if (if (unsafe: *__local_ptr__goto_757_12) != 60: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_50 != 0) {
            goto '__ci_bb_422
        } else {
            goto '__ci_bb_423
        }
    }

    '__ci_bb_422 {
        goto '__ci_bb_380
    }

    '__ci_bb_423 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_name_start__goto_1547_22 = __local_ptr__goto_757_12)
        if ((if not (read_name_subst((&raw mut __local_ptr__goto_757_12 as *mut *const u8), __local_repend__goto_758_12, __local_utf__goto_753_6, (__param_code.tables + (((512 + 320) as isize) as usize))) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_424
        } else {
            goto '__ci_bb_425
        }
    }

    '__ci_bb_424 {
        goto '__ci_bb_380
    }

    '__ci_bb_425 {
        (__local_name_len__goto_1546_22 = ((__local_ptr__goto_757_12 as usize) -% (__local_name_start__goto_1547_22 as usize)) / sizeof[u8]())
        if ((if __local_ptr__goto_757_12 >= __local_repend__goto_758_12: 1 else: 0) != 0) {
            (__ci_expr_logic_51 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_51 = (if (if (unsafe: *__local_ptr__goto_757_12) != 62: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_51 != 0) {
            goto '__ci_bb_426
        } else {
            goto '__ci_bb_427
        }
    }

    '__ci_bb_426 {
        goto '__ci_bb_380
    }

    '__ci_bb_427 {
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_special__goto_1056_14 = 0)
        (__local_group__goto_1055_9 = -1)
        with_memcpy(((&(unsafe: __local_name__goto_1061_17[0]) as *mut u8) as *i8), (__local_name_start__goto_1547_22 as *i8), (((__local_name_len__goto_1546_22 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_name__goto_1061_17[__local_name_len__goto_1546_22] = 0)
        goto '__ci_bb_146
    }

    '__ci_bb_428 {
        if ((if __local_rc__goto_743_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_429
        } else {
            goto '__ci_bb_430
        }
    }

    '__ci_bb_429 {
        (__local_special__goto_1056_14 = 0)
        (__local_group__goto_1055_9 = (0 - __local_rc__goto_743_5) - 1)
        goto '__ci_bb_146
    }

    '__ci_bb_430 {
        goto '__ci_bb_380
    }

    '__ci_bb_431 {
        if (__local_rc__goto_743_5 == 26) {
            goto '__ci_bb_384
        } else {
            goto '__ci_bb_432
        }
    }

    '__ci_bb_432 {
        if (__local_rc__goto_743_5 == 0) {
            goto '__ci_bb_385
        } else {
            goto '__ci_bb_433
        }
    }

    '__ci_bb_433 {
        if (__local_rc__goto_743_5 == 5) {
            goto '__ci_bb_385
        } else {
            goto '__ci_bb_434
        }
    }

    '__ci_bb_434 {
        if (__local_rc__goto_743_5 == 21) {
            goto '__ci_bb_385
        } else {
            goto '__ci_bb_435
        }
    }

    '__ci_bb_435 {
        if (__local_rc__goto_743_5 == 27) {
            goto '__ci_bb_421
        } else {
            goto '__ci_bb_428
        }
    }

    '__ci_bb_436 {
        if ((if ((__local_ch__goto_1053_14 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_438
        } else {
            goto '__ci_bb_439
        }
    }

    '__ci_bb_437 {
        __local_ch__goto_1053_14
        (__ci_expr_logic_55 = 0)
        if ((if (&raw const __local_forcecase__goto_962_14 as *const case_state).to_case != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_55 = (if (if __local_substitute_case_callout__goto_765_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_55 != 0) {
            goto '__ci_bb_450
        } else {
            goto '__ci_bb_451
        }
    }

    '__ci_bb_438 {
        (__ci_expr_old_54 = __local_ptr__goto_757_12)
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + 1)
        (__local_ch__goto_1053_14 = (((((__local_ch__goto_1053_14 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_54) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_440
    }

    '__ci_bb_439 {
        if ((if ((__local_ch__goto_1053_14 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_441
        } else {
            goto '__ci_bb_442
        }
    }

    '__ci_bb_440 {
        goto '__ci_bb_437
    }

    '__ci_bb_441 {
        (__local_ch__goto_1053_14 = (((((((__local_ch__goto_1053_14 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_ptr__goto_757_12) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_757_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((2 as isize) as usize))
        goto '__ci_bb_443
    }

    '__ci_bb_442 {
        if ((if ((__local_ch__goto_1053_14 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_444
        } else {
            goto '__ci_bb_445
        }
    }

    '__ci_bb_443 {
        goto '__ci_bb_440
    }

    '__ci_bb_444 {
        (__local_ch__goto_1053_14 = (((((((((__local_ch__goto_1053_14 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_ptr__goto_757_12) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_757_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_757_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((3 as isize) as usize))
        goto '__ci_bb_446
    }

    '__ci_bb_445 {
        if ((if ((__local_ch__goto_1053_14 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_447
        } else {
            goto '__ci_bb_448
        }
    }

    '__ci_bb_446 {
        goto '__ci_bb_443
    }

    '__ci_bb_447 {
        (__local_ch__goto_1053_14 = (((((((((((__local_ch__goto_1053_14 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_ptr__goto_757_12) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_757_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_757_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_757_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((4 as isize) as usize))
        goto '__ci_bb_449
    }

    '__ci_bb_448 {
        (__local_ch__goto_1053_14 = (((((((((((((__local_ch__goto_1053_14 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_ptr__goto_757_12) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_757_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_757_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_757_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_757_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_ptr__goto_757_12 = __local_ptr__goto_757_12 + ((5 as isize) as usize))
        goto '__ci_bb_449
    }

    '__ci_bb_449 {
        goto '__ci_bb_446
    }

    '__ci_bb_450 {
        goto '__ci_bb_453
    }

    '__ci_bb_451 {
        goto '__ci_bb_465
    }

    '__ci_bb_452 {
        goto '__ci_bb_335
    }

    '__ci_bb_453 {
        (__local_chkcc_length__goto_1594_9 = (((((__local_ptr__goto_757_12 as usize) -% (__local_ch_start__goto_1585_18 as usize)) / sizeof[u8]()) as c_ulong)))
        (__ci_expr_ternary_56 = 0)
        if (__local_overflowed__goto_750_6 != 0) {
            (__ci_expr_ternary_56 = 0)
        } else {
            (__ci_expr_ternary_56 = __local_lengthleft__goto_760_38)
        }
        (__local_chkcc_rc__goto_1594_9 = default_substitute_case_callout(__local_ch_start__goto_1585_18, __local_chkcc_length__goto_1594_9, (__param_buffer + (__local_buff_offset__goto_760_12 as usize)), __ci_expr_ternary_56, (&raw mut __local_forcecase__goto_962_14 as *mut case_state), __param_code))
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_456
        } else {
            goto '__ci_bb_457
        }
    }

    '__ci_bb_454 {
        if (0 != 0) {
            goto '__ci_bb_453
        } else {
            goto '__ci_bb_455
        }
    }

    '__ci_bb_455 {
        goto '__ci_bb_452
    }

    '__ci_bb_456 {
        if ((if __local_chkcc_rc__goto_1594_9 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_458
        } else {
            goto '__ci_bb_459
        }
    }

    '__ci_bb_457 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkcc_rc__goto_1594_9: 1 else: 0) != 0) {
            goto '__ci_bb_460
        } else {
            goto '__ci_bb_461
        }
    }

    '__ci_bb_458 {
        goto '__ci_bb_61
    }

    '__ci_bb_459 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkcc_rc__goto_1594_9)
        goto '__ci_bb_455
    }

    '__ci_bb_460 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_463
        } else {
            goto '__ci_bb_464
        }
    }

    '__ci_bb_461 {
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkcc_rc__goto_1594_9)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkcc_rc__goto_1594_9)
        goto '__ci_bb_462
    }

    '__ci_bb_462 {
        goto '__ci_bb_454
    }

    '__ci_bb_463 {
        goto '__ci_bb_67
    }

    '__ci_bb_464 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkcc_rc__goto_1594_9 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_462
    }

    '__ci_bb_465 {
        (__local_chkmc_length__goto_1596_9 = ((__local_ptr__goto_757_12 as usize) -% (__local_ch_start__goto_1585_18 as usize)) / sizeof[u8]())
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_468
        } else {
            goto '__ci_bb_469
        }
    }

    '__ci_bb_466 {
        if (0 != 0) {
            goto '__ci_bb_465
        } else {
            goto '__ci_bb_467
        }
    }

    '__ci_bb_467 {
        goto '__ci_bb_452
    }

    '__ci_bb_468 {
        if ((if __local_chkmc_length__goto_1596_9 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_471
        } else {
            goto '__ci_bb_472
        }
    }

    '__ci_bb_469 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1596_9: 1 else: 0) != 0) {
            goto '__ci_bb_473
        } else {
            goto '__ci_bb_474
        }
    }

    '__ci_bb_470 {
        goto '__ci_bb_466
    }

    '__ci_bb_471 {
        goto '__ci_bb_61
    }

    '__ci_bb_472 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1596_9)
        goto '__ci_bb_470
    }

    '__ci_bb_473 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_476
        } else {
            goto '__ci_bb_477
        }
    }

    '__ci_bb_474 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), (__local_ch_start__goto_1585_18 as *i8), (((__local_chkmc_length__goto_1596_9 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1596_9)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1596_9)
        goto '__ci_bb_475
    }

    '__ci_bb_475 {
        goto '__ci_bb_470
    }

    '__ci_bb_476 {
        goto '__ci_bb_67
    }

    '__ci_bb_477 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1596_9 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_475
    }

    '__ci_bb_478 {
        goto '__ci_bb_480
    }

    '__ci_bb_479 {
        (__ci_expr_logic_58 = 0)
        if ((if __param_mcontext != null: 1 else: 0) != 0) {
            (__ci_expr_logic_58 = (if (if __param_mcontext.substitute_callout != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_58 != 0) {
            goto '__ci_bb_500
        } else {
            goto '__ci_bb_501
        }
    }

    '__ci_bb_480 {
        (__local_chars_outstanding__goto_1609_5 = ((((__local_buff_offset__goto_760_12 as c_ulong) -% (__local_casestart_offset__goto_963_14 as c_ulong)) as c_ulong) +% (((__local_extra_needed__goto_759_12 as c_ulong) -% (__local_casestart_extra_needed__goto_964_14 as c_ulong)) as c_ulong)))
        if ((if __local_chars_outstanding__goto_1609_5 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_483
        } else {
            goto '__ci_bb_484
        }
    }

    '__ci_bb_481 {
        if (0 != 0) {
            goto '__ci_bb_480
        } else {
            goto '__ci_bb_482
        }
    }

    '__ci_bb_482 {
        goto '__ci_bb_479
    }

    '__ci_bb_483 {
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_485
        } else {
            goto '__ci_bb_486
        }
    }

    '__ci_bb_484 {
        goto '__ci_bb_481
    }

    '__ci_bb_485 {
        (__local_guess__goto_1609_5 = pessimistic_case_inflation(__local_chars_outstanding__goto_1609_5))
        if ((if __local_guess__goto_1609_5 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_488
        } else {
            goto '__ci_bb_489
        }
    }

    '__ci_bb_486 {
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 + ((__local_buff_offset__goto_760_12 as c_ulong) -% (__local_casestart_offset__goto_963_14 as c_ulong)))
        (__local_buff_offset__goto_760_12 = __local_casestart_offset__goto_963_14)
        goto '__ci_bb_490
    }

    '__ci_bb_487 {
        goto '__ci_bb_484
    }

    '__ci_bb_488 {
        goto '__ci_bb_61
    }

    '__ci_bb_489 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_guess__goto_1609_5)
        goto '__ci_bb_487
    }

    '__ci_bb_490 {
        (__local_chkcc_length__goto_1609_5 = __local_chars_outstanding__goto_1609_5)
        (__local_chkcc_rc__goto_1609_5 = do_case_copy((__param_buffer + (__local_buff_offset__goto_760_12 as usize)), __local_chkcc_length__goto_1609_5, __local_lengthleft__goto_760_38, (&raw mut __local_forcecase__goto_962_14 as *mut case_state), __local_utf__goto_753_6, __local_substitute_case_callout__goto_765_14, __local_substitute_case_callout_data__goto_767_7))
        if ((if __local_chkcc_rc__goto_1609_5 == (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_493
        } else {
            goto '__ci_bb_494
        }
    }

    '__ci_bb_491 {
        if (0 != 0) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_492
        }
    }

    '__ci_bb_492 {
        goto '__ci_bb_487
    }

    '__ci_bb_493 {
        goto '__ci_bb_372
    }

    '__ci_bb_494 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkcc_rc__goto_1609_5: 1 else: 0) != 0) {
            goto '__ci_bb_495
        } else {
            goto '__ci_bb_496
        }
    }

    '__ci_bb_495 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_498
        } else {
            goto '__ci_bb_499
        }
    }

    '__ci_bb_496 {
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkcc_rc__goto_1609_5)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkcc_rc__goto_1609_5)
        goto '__ci_bb_497
    }

    '__ci_bb_497 {
        goto '__ci_bb_491
    }

    '__ci_bb_498 {
        goto '__ci_bb_67
    }

    '__ci_bb_499 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkcc_rc__goto_1609_5 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_497
    }

    '__ci_bb_500 {
        if ((if not (__local_overflowed__goto_750_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_502
        } else {
            goto '__ci_bb_503
        }
    }

    '__ci_bb_501 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (256 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_60 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_60 = (if (if not (pcre2_next_match_8(__local_match_data, (&raw mut __local_start_offset as *mut c_ulong), (&raw mut __local_goptions__goto_746_10 as *mut c_uint)) != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_60 != 0) {
            goto '__ci_bb_528
        } else {
            goto '__ci_bb_529
        }
    }

    '__ci_bb_502 {
        (__local_scb__goto_763_32.subscount = __local_subs__goto_744_5)
        (__local_scb__goto_763_32.output_offsets[1] = __local_buff_offset__goto_760_12)
        (__local_rc__goto_743_5 = __param_mcontext.substitute_callout((&raw mut __local_scb__goto_763_32 as *mut pcre2_substitute_callout_block_8), __param_mcontext.substitute_callout_data))
        if ((if __local_rc__goto_743_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_505
        } else {
            goto '__ci_bb_506
        }
    }

    '__ci_bb_503 {
        (__local_newlength_buf__goto_1654_18 = ((__local_buff_offset__goto_760_12 as c_ulong) -% ((&raw const __local_scb__goto_763_32 as *const pcre2_substitute_callout_block_8).output_offsets[0] as c_ulong)))
        (__local_newlength_extra__goto_1655_18 = ((__local_extra_needed__goto_759_12 as c_ulong) -% (__local_sub_start_extra_needed__goto_764_12 as c_ulong)))
        (__ci_expr_ternary_59 = 0)
        if ((if __local_newlength_extra__goto_1655_18 > (((~(0 as c_ulong)) as c_ulong) -% (__local_newlength_buf__goto_1654_18 as c_ulong)): 1 else: 0) != 0) {
            (__ci_expr_ternary_59 = (~(0 as c_ulong)))
        } else {
            (__ci_expr_ternary_59 = ((__local_newlength_buf__goto_1654_18 as c_ulong) +% (__local_newlength_extra__goto_1655_18 as c_ulong)))
        }
        (__local_newlength__goto_1656_18 = __ci_expr_ternary_59)
        (__local_oldlength__goto_1659_18 = (((unsafe: __local_ovector__goto_761_13[1]) as c_ulong) -% ((unsafe: __local_ovector__goto_761_13[0]) as c_ulong)))
        if ((if __local_oldlength__goto_1659_18 > __local_newlength__goto_1656_18: 1 else: 0) != 0) {
            goto '__ci_bb_524
        } else {
            goto '__ci_bb_525
        }
    }

    '__ci_bb_504 {
        goto '__ci_bb_501
    }

    '__ci_bb_505 {
        (__local_newlength__goto_1630_20 = (((&raw const __local_scb__goto_763_32 as *const pcre2_substitute_callout_block_8).output_offsets[1] as c_ulong) -% ((&raw const __local_scb__goto_763_32 as *const pcre2_substitute_callout_block_8).output_offsets[0] as c_ulong)))
        (__local_oldlength__goto_1631_20 = (((unsafe: __local_ovector__goto_761_13[1]) as c_ulong) -% ((unsafe: __local_ovector__goto_761_13[0]) as c_ulong)))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 - __local_newlength__goto_1630_20)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 + __local_newlength__goto_1630_20)
        if ((if not (__local_replacement_only__goto_752_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_507
        } else {
            goto '__ci_bb_508
        }
    }

    '__ci_bb_506 {
        goto '__ci_bb_504
    }

    '__ci_bb_507 {
        goto '__ci_bb_509
    }

    '__ci_bb_508 {
        if ((if __local_rc__goto_743_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_522
        } else {
            goto '__ci_bb_523
        }
    }

    '__ci_bb_509 {
        (__local_chkmc_length__goto_1635_32 = __local_oldlength__goto_1631_20)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_512
        } else {
            goto '__ci_bb_513
        }
    }

    '__ci_bb_510 {
        if (0 != 0) {
            goto '__ci_bb_509
        } else {
            goto '__ci_bb_511
        }
    }

    '__ci_bb_511 {
        goto '__ci_bb_508
    }

    '__ci_bb_512 {
        if ((if __local_chkmc_length__goto_1635_32 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_515
        } else {
            goto '__ci_bb_516
        }
    }

    '__ci_bb_513 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1635_32: 1 else: 0) != 0) {
            goto '__ci_bb_517
        } else {
            goto '__ci_bb_518
        }
    }

    '__ci_bb_514 {
        goto '__ci_bb_510
    }

    '__ci_bb_515 {
        goto '__ci_bb_61
    }

    '__ci_bb_516 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1635_32)
        goto '__ci_bb_514
    }

    '__ci_bb_517 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_520
        } else {
            goto '__ci_bb_521
        }
    }

    '__ci_bb_518 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), ((__local_subject + ((unsafe: __local_ovector__goto_761_13[0]) as usize)) as *i8), (((__local_chkmc_length__goto_1635_32 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1635_32)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1635_32)
        goto '__ci_bb_519
    }

    '__ci_bb_519 {
        goto '__ci_bb_514
    }

    '__ci_bb_520 {
        goto '__ci_bb_67
    }

    '__ci_bb_521 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1635_32 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_519
    }

    '__ci_bb_522 {
        (__local_suboptions__goto_747_10 = __local_suboptions__goto_747_10 & (~256))
        goto '__ci_bb_523
    }

    '__ci_bb_523 {
        goto '__ci_bb_506
    }

    '__ci_bb_524 {
        (__local_additional__goto_1666_20 = ((__local_oldlength__goto_1659_18 as c_ulong) -% (__local_newlength__goto_1656_18 as c_ulong)))
        if ((if __local_additional__goto_1666_20 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_526
        } else {
            goto '__ci_bb_527
        }
    }

    '__ci_bb_525 {
        goto '__ci_bb_504
    }

    '__ci_bb_526 {
        goto '__ci_bb_61
    }

    '__ci_bb_527 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_additional__goto_1666_20)
        goto '__ci_bb_525
    }

    '__ci_bb_528 {
        (__local_start_offset = (unsafe: __local_ovector__goto_761_13[1]))
        goto '__ci_bb_71
    }

    '__ci_bb_529 {
        goto '__ci_bb_530
    }

    '__ci_bb_530 {
        goto '__ci_bb_531
    }

    '__ci_bb_531 {
        if (0 != 0) {
            goto '__ci_bb_530
        } else {
            goto '__ci_bb_532
        }
    }

    '__ci_bb_532 {
        goto '__ci_bb_70
    }

    '__ci_bb_533 {
        (__local_fraglength__goto_760_50 = ((__local_length as c_ulong) -% (__local_start_offset as c_ulong)))
        goto '__ci_bb_535
    }

    '__ci_bb_534 {
        (__local_temp__goto_754_13[0] = 0)
        goto '__ci_bb_548
    }

    '__ci_bb_535 {
        (__local_chkmc_length__goto_1704_3 = __local_fraglength__goto_760_50)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_538
        } else {
            goto '__ci_bb_539
        }
    }

    '__ci_bb_536 {
        if (0 != 0) {
            goto '__ci_bb_535
        } else {
            goto '__ci_bb_537
        }
    }

    '__ci_bb_537 {
        goto '__ci_bb_534
    }

    '__ci_bb_538 {
        if ((if __local_chkmc_length__goto_1704_3 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_541
        } else {
            goto '__ci_bb_542
        }
    }

    '__ci_bb_539 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1704_3: 1 else: 0) != 0) {
            goto '__ci_bb_543
        } else {
            goto '__ci_bb_544
        }
    }

    '__ci_bb_540 {
        goto '__ci_bb_536
    }

    '__ci_bb_541 {
        goto '__ci_bb_61
    }

    '__ci_bb_542 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1704_3)
        goto '__ci_bb_540
    }

    '__ci_bb_543 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_546
        } else {
            goto '__ci_bb_547
        }
    }

    '__ci_bb_544 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), ((__local_subject + (__local_start_offset as usize)) as *i8), (((__local_chkmc_length__goto_1704_3 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1704_3)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1704_3)
        goto '__ci_bb_545
    }

    '__ci_bb_545 {
        goto '__ci_bb_540
    }

    '__ci_bb_546 {
        goto '__ci_bb_67
    }

    '__ci_bb_547 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1704_3 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_545
    }

    '__ci_bb_548 {
        (__local_chkmc_length__goto_1708_1 = 1)
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_551
        } else {
            goto '__ci_bb_552
        }
    }

    '__ci_bb_549 {
        if (0 != 0) {
            goto '__ci_bb_548
        } else {
            goto '__ci_bb_550
        }
    }

    '__ci_bb_550 {
        if (__local_overflowed__goto_750_6 != 0) {
            goto '__ci_bb_561
        } else {
            goto '__ci_bb_562
        }
    }

    '__ci_bb_551 {
        if ((if __local_chkmc_length__goto_1708_1 > (((~(0 as c_ulong)) as c_ulong) -% (__local_extra_needed__goto_759_12 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_554
        } else {
            goto '__ci_bb_555
        }
    }

    '__ci_bb_552 {
        if ((if __local_lengthleft__goto_760_38 < __local_chkmc_length__goto_1708_1: 1 else: 0) != 0) {
            goto '__ci_bb_556
        } else {
            goto '__ci_bb_557
        }
    }

    '__ci_bb_553 {
        goto '__ci_bb_549
    }

    '__ci_bb_554 {
        goto '__ci_bb_61
    }

    '__ci_bb_555 {
        (__local_extra_needed__goto_759_12 = __local_extra_needed__goto_759_12 + __local_chkmc_length__goto_1708_1)
        goto '__ci_bb_553
    }

    '__ci_bb_556 {
        if ((if ((__local_suboptions__goto_747_10 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_559
        } else {
            goto '__ci_bb_560
        }
    }

    '__ci_bb_557 {
        with_memcpy(((__param_buffer + (__local_buff_offset__goto_760_12 as usize)) as *i8), ((&(unsafe: __local_temp__goto_754_13[0]) as *mut u8) as *i8), (((__local_chkmc_length__goto_1708_1 as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_buff_offset__goto_760_12 = __local_buff_offset__goto_760_12 + __local_chkmc_length__goto_1708_1)
        (__local_lengthleft__goto_760_38 = __local_lengthleft__goto_760_38 - __local_chkmc_length__goto_1708_1)
        goto '__ci_bb_558
    }

    '__ci_bb_558 {
        goto '__ci_bb_553
    }

    '__ci_bb_559 {
        goto '__ci_bb_67
    }

    '__ci_bb_560 {
        (__local_overflowed__goto_750_6 = 1)
        (__local_extra_needed__goto_759_12 = ((__local_chkmc_length__goto_1708_1 as c_ulong) -% (__local_lengthleft__goto_760_38 as c_ulong)))
        goto '__ci_bb_558
    }

    '__ci_bb_561 {
        (__local_rc__goto_743_5 = -48)
        if ((if __local_extra_needed__goto_759_12 > (((~(0 as c_ulong)) as c_ulong) -% (__local_buff_length__goto_760_25 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_564
        } else {
            goto '__ci_bb_565
        }
    }

    '__ci_bb_562 {
        (__local_rc__goto_743_5 = __local_subs__goto_744_5)
        ((unsafe: *__param_blength) = ((__local_buff_offset__goto_760_12 as c_ulong) -% (1 as c_ulong)))
        goto '__ci_bb_563
    }

    '__ci_bb_563 {
        goto '__ci_bb_48
    }

    '__ci_bb_564 {
        goto '__ci_bb_61
    }

    '__ci_bb_565 {
        ((unsafe: *__param_blength) = ((__local_buff_length__goto_760_25 as c_ulong) +% (__local_extra_needed__goto_759_12 as c_ulong)))
        goto '__ci_bb_563
    }

    '__ci_bb_566 {
        pcre2_match_data_free_8(__local_internal_match_data__goto_748_19)
        goto '__ci_bb_568
    }

    '__ci_bb_567 {
        ((unsafe: *__local_match_data).rc = __local_rc__goto_743_5)
        goto '__ci_bb_568
    }

    '__ci_bb_568 {
        return __local_rc__goto_743_5
    }

}

fn find_text_end(__param_code: *const pcre2_real_code_8, __param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_last: c_int) -> c_int {
    var __local_rc__goto_80_5: c_int = 0

    var __local_nestlevel__goto_81_10: c_uint = 0

    var __local_literal__goto_82_6: c_int = 0

    var __local_ptr__goto_83_12: *const u8 = null

    var __local_erc__goto_115_9: c_int = 0

    var __local_errorcode__goto_116_9: c_int = 0

    var __local_ch__goto_117_14: c_uint = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_rc__goto_80_5 = 0)
        (__local_nestlevel__goto_81_10 = 0)
        (__local_literal__goto_82_6 = 0)
        (__local_ptr__goto_83_12 = (unsafe: *__param_ptrptr))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((if __local_ptr__goto_83_12 < __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        if (__local_literal__goto_82_6 != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        (__local_ptr__goto_83_12 = __local_ptr__goto_83_12 + 1)
        goto '__ci_bb_1
    }

    '__ci_bb_4 {
        (__local_rc__goto_80_5 = -58)
        goto '__ci_bb_15
    }

    '__ci_bb_5 {
        (__ci_expr_logic_1 = 0)
        (__ci_expr_logic_0 = 0)
        if ((if (unsafe: __local_ptr__goto_83_12[0]) == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_ptr__goto_83_12 < (__param_ptrend - ((1 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: __local_ptr__goto_83_12[1]) == 69: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_6 {
        if ((if (unsafe: *__local_ptr__goto_83_12) == 125: 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_7 {
        goto '__ci_bb_3
    }

    '__ci_bb_8 {
        (__local_literal__goto_82_6 = 0)
        (__local_ptr__goto_83_12 = __local_ptr__goto_83_12 + ((1 as isize) as usize))
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        goto '__ci_bb_7
    }

    '__ci_bb_10 {
        if ((if __local_nestlevel__goto_81_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_11 {
        (__ci_expr_logic_3 = 0)
        (__ci_expr_logic_2 = 0)
        if ((if (unsafe: *__local_ptr__goto_83_12) == 58: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if not (__param_last != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if (if __local_nestlevel__goto_81_10 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_12 {
        goto '__ci_bb_7
    }

    '__ci_bb_13 {
        goto '__ci_bb_15
    }

    '__ci_bb_14 {
        (__local_nestlevel__goto_81_10 = __local_nestlevel__goto_81_10 - 1)
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        ((unsafe: *__param_ptrptr) = __local_ptr__goto_83_12)
        return __local_rc__goto_80_5
    }

    '__ci_bb_16 {
        goto '__ci_bb_15
    }

    '__ci_bb_17 {
        if ((if (unsafe: *__local_ptr__goto_83_12) == 36: 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_18 {
        goto '__ci_bb_12
    }

    '__ci_bb_19 {
        (__ci_expr_logic_4 = 0)
        if ((if __local_ptr__goto_83_12 < (__param_ptrend - ((1 as isize) as usize)): 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if (unsafe: __local_ptr__goto_83_12[1]) == 123: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_20 {
        if ((if (unsafe: *__local_ptr__goto_83_12) == 92: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_21 {
        goto '__ci_bb_18
    }

    '__ci_bb_22 {
        (__local_nestlevel__goto_81_10 = __local_nestlevel__goto_81_10 + 1)
        (__local_ptr__goto_83_12 = __local_ptr__goto_83_12 + ((1 as isize) as usize))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        goto '__ci_bb_21
    }

    '__ci_bb_24 {
        if ((if __local_ptr__goto_83_12 < (__param_ptrend - ((1 as isize) as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_25 {
        goto '__ci_bb_21
    }

    '__ci_bb_26 {
        goto '__ci_bb_28
    }

    '__ci_bb_27 {
        (__local_ptr__goto_83_12 = __local_ptr__goto_83_12 + ((1 as isize) as usize))
        (__local_erc__goto_115_9 = _pcre2_check_escape_8((&raw mut __local_ptr__goto_83_12 as *mut *const u8), __param_ptrend, (&raw mut __local_ch__goto_117_14 as *mut c_uint), (&raw mut __local_errorcode__goto_116_9 as *mut c_int), __param_code.overall_options, __param_code.extra_options, __param_code.top_bracket, 0, null))
        if ((if __local_errorcode__goto_116_9 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_28 {
        if ((unsafe: __local_ptr__goto_83_12[1]) == 76) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_29 {
        goto '__ci_bb_27
    }

    '__ci_bb_30 {
        (__local_ptr__goto_83_12 = __local_ptr__goto_83_12 + ((1 as isize) as usize))
        goto '__ci_bb_3
    }

    '__ci_bb_31 {
        if ((unsafe: __local_ptr__goto_83_12[1]) == 108) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_32 {
        if ((unsafe: __local_ptr__goto_83_12[1]) == 85) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_33 {
        if ((unsafe: __local_ptr__goto_83_12[1]) == 117) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_34 {
        (__local_rc__goto_80_5 = -57)
        goto '__ci_bb_15
    }

    '__ci_bb_35 {
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        if (__local_erc__goto_115_9 == 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_37 {
        goto '__ci_bb_25
    }

    '__ci_bb_38 {
        goto '__ci_bb_37
    }

    '__ci_bb_39 {
        (__local_literal__goto_82_6 = 1)
        goto '__ci_bb_37
    }

    '__ci_bb_40 {
        goto '__ci_bb_37
    }

    '__ci_bb_41 {
        if ((if __local_erc__goto_115_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_42 {
        goto '__ci_bb_37
    }

    '__ci_bb_43 {
        (__local_rc__goto_80_5 = -57)
        goto '__ci_bb_15
    }

    '__ci_bb_44 {
        if (__local_erc__goto_115_9 == 5) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_45 {
        if (__local_erc__goto_115_9 == 21) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_46 {
        if (__local_erc__goto_115_9 == 25) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_47 {
        if (__local_erc__goto_115_9 == 26) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_48 {
        if (__local_erc__goto_115_9 == 27) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

}

fn read_name_subst(__param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_utf: c_int, __param_ctypes: *const u8) -> c_int {
    var __local_ptr__goto_200_12: *const u8 = null

    var __local_nameptr__goto_201_12: *const u8 = null

    var __local_c__goto_215_12: c_uint = 0

    var __local_type___goto_215_15: c_uint = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_ptr__goto_200_12 = (unsafe: *__param_ptrptr))
        (__local_nameptr__goto_201_12 = __local_ptr__goto_200_12)
        if ((if __local_ptr__goto_200_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        if (__param_utf != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_3 {
        ((unsafe: *__param_ptrptr) = __local_ptr__goto_200_12)
        return 0
    }

    '__ci_bb_4 {
        goto '__ci_bb_7
    }

    '__ci_bb_5 {
        goto '__ci_bb_29
    }

    '__ci_bb_6 {
        if ((if (((__local_ptr__goto_200_12 as usize) -% (__local_nameptr__goto_201_12 as usize)) / sizeof[u8]()) > 128: 1 else: 0) != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_7 {
        if ((if __local_ptr__goto_200_12 < __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        (__local_c__goto_215_12 = (unsafe: *__local_ptr__goto_200_12))
        if ((if __local_c__goto_215_12 >= 192: 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_9 {
        goto '__ci_bb_6
    }

    '__ci_bb_10 {
        if ((if ((__local_c__goto_215_12 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_11 {
        (__local_type___goto_215_15 = ((&(unsafe: _pcre2_ucd_records_8[0]) as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_215_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_215_12 as c_int) % 128))] as c_uint) as usize)).chartype)
        (__ci_expr_logic_1 = 0)
        (__ci_expr_logic_0 = 0)
        if ((if __local_type___goto_215_15 != 13: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if _pcre2_ucp_gentype_8[__local_type___goto_215_15] != 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if __local_c__goto_215_12 != 95: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_12 {
        (__local_c__goto_215_12 = (((((__local_c__goto_215_12 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_200_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_14
    }

    '__ci_bb_13 {
        if ((if ((__local_c__goto_215_12 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_14 {
        goto '__ci_bb_11
    }

    '__ci_bb_15 {
        (__local_c__goto_215_12 = (((((((__local_c__goto_215_12 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_200_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        if ((if ((__local_c__goto_215_12 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_17 {
        goto '__ci_bb_14
    }

    '__ci_bb_18 {
        (__local_c__goto_215_12 = (((((((((__local_c__goto_215_12 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_200_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_20
    }

    '__ci_bb_19 {
        if ((if ((__local_c__goto_215_12 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_20 {
        goto '__ci_bb_17
    }

    '__ci_bb_21 {
        (__local_c__goto_215_12 = (((((((((((__local_c__goto_215_12 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_200_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_23
    }

    '__ci_bb_22 {
        (__local_c__goto_215_12 = (((((((((((((__local_c__goto_215_12 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ptr__goto_200_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ptr__goto_200_12[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        goto '__ci_bb_20
    }

    '__ci_bb_24 {
        goto '__ci_bb_9
    }

    '__ci_bb_25 {
        (__local_ptr__goto_200_12 = __local_ptr__goto_200_12 + 1)
        goto '__ci_bb_26
    }

    '__ci_bb_26 {
        (__ci_expr_logic_2 = 0)
        if ((if __local_ptr__goto_200_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if ((((unsafe: *__local_ptr__goto_200_12) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_27 {
        (__local_ptr__goto_200_12 = __local_ptr__goto_200_12 + 1)
        goto '__ci_bb_26
    }

    '__ci_bb_28 {
        goto '__ci_bb_7
    }

    '__ci_bb_29 {
        (__ci_expr_logic_4 = 0)
        (__ci_expr_logic_3 = 0)
        if ((if __local_ptr__goto_200_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if 1 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if (if (((unsafe: __param_ctypes[(unsafe: *__local_ptr__goto_200_12)]) as c_int) & 16) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        (__local_ptr__goto_200_12 = __local_ptr__goto_200_12 + 1)
        goto '__ci_bb_29
    }

    '__ci_bb_31 {
        goto '__ci_bb_6
    }

    '__ci_bb_32 {
        goto '__ci_bb_3
    }

    '__ci_bb_33 {
        if ((if __local_ptr__goto_200_12 == __local_nameptr__goto_201_12: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_34 {
        goto '__ci_bb_3
    }

    '__ci_bb_35 {
        ((unsafe: *__param_ptrptr) = __local_ptr__goto_200_12)
        return 1
    }

}

fn pessimistic_case_inflation(__param_len: c_ulong) -> c_ulong {
    return ((((__param_len as c_ulong) >> (3 as c_uint)) as c_ulong) +% (10 as c_ulong))

}

fn default_substitute_case_callout(__param_input: *const u8, __param_input_len: c_ulong, __param_output: *mut u8, __param_output_cap: c_ulong, __param_state: *mut case_state, __param_code: *const pcre2_real_code_8) -> c_ulong {
    var __local_input = __param_input
    var __local_output = __param_output
    var __local_output_cap = __param_output_cap
    var __local_input_end: *const u8 = (__local_input + (__param_input_len as usize))

    var __local_utf: c_int

    var __local_ucp: c_int

    var __local_temp: [6]u8

    var __local_next_to_upper: c_int

    var __local_rest_to_upper: c_int

    var __local_single_char: c_int

    var __local_overflow: c_int = 0

    var __local_written: c_ulong = 0

    do {
        0
    } while (0 != 0)

    (__local_utf = (if ((__param_code.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))

    (__local_ucp = (if ((__param_code.overall_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0))

    if ((if __param_input_len == 0: 1 else: 0) != 0) {
        return 0
    }

    while true {
        match __param_state.to_case {
            1 => {
                (__local_rest_to_upper = (if __param_state.to_case == 2: 1 else: 0))

                (__local_next_to_upper = __local_rest_to_upper)

            },
            2 => {
                (__local_rest_to_upper = (if __param_state.to_case == 2: 1 else: 0))

                (__local_next_to_upper = __local_rest_to_upper)

            },
            3 => {
                (__local_next_to_upper = 1)

                (__local_rest_to_upper = 0)

                ((unsafe: *__param_state).to_case = 1)

            },
            4 => {
                (__local_next_to_upper = 0)

                (__local_rest_to_upper = 1)

                ((unsafe: *__param_state).to_case = 2)

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

    (__local_single_char = __param_state.single_char)

    if (__local_single_char != 0) {
        ((unsafe: *__param_state).to_case = 0)
    }

    while ((if __local_input < __local_input_end: 1 else: 0) != 0) {
        var __local_ch: c_uint

        var __local_chlen: c_uint

        var __ci_expr_old_1: *const u8 = __local_input

        (__local_input = __local_input + 1)

        (__local_ch = (unsafe: *__ci_expr_old_1))


        var __ci_expr_logic_2: c_int = 0

        if (__local_utf != 0) {
            (__ci_expr_logic_2 = (if (if __local_ch >= 192: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            if ((if ((__local_ch as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_3: *const u8 = __local_input

                (__local_input = __local_input + 1)

                (__local_ch = (((((__local_ch as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_3) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

            } else {
                if ((if ((__local_ch as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_ch = (((((((__local_ch as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    (__local_input = __local_input + ((2 as isize) as usize))

                } else {
                    if ((if ((__local_ch as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_ch = (((((((((__local_ch as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_input = __local_input + ((3 as isize) as usize))

                    } else {
                        if ((if ((__local_ch as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_ch = (((((((((((__local_ch as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_input = __local_input + ((4 as isize) as usize))

                        } else {
                            (__local_ch = (((((((((((((__local_ch as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_input = __local_input + ((5 as isize) as usize))

                        }
                    }
                }
            }

        }


        var __ci_expr_logic_5: c_int = 0

        var __ci_expr_logic_4: c_int

        if (__local_utf != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if __local_ucp != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if __local_ch >= 128: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            var __local_type_: c_uint = ((&(unsafe: _pcre2_ucd_records_8[0]) as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_ch as c_int) / 128)] as c_int) * 128) + ((__local_ch as c_int) % 128))] as c_uint) as usize)).chartype

            var __ci_expr_logic_7: c_int = 0

            if ((if _pcre2_ucp_gentype_8[__local_type_] == 1: 1 else: 0) != 0) {
                var __ci_expr_ternary_6: c_int = 0

                if (__local_next_to_upper != 0) {
                    (__ci_expr_ternary_6 = ucp_Lu)
                } else {
                    (__ci_expr_ternary_6 = ucp_Ll)
                }

                (__ci_expr_logic_7 = (if (if __local_type_ != __ci_expr_ternary_6: 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_7 != 0) {
                (__local_ch = ((((__local_ch as c_int) + ((&(unsafe: _pcre2_ucd_records_8[0]) as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_ch as c_int) / 128)] as c_int) * 128) + ((__local_ch as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
            }


        } else {
            if (1 != 0) {
                var __ci_expr_ternary_8: c_int = 0

                if (__local_next_to_upper != 0) {
                    (__ci_expr_ternary_8 = 96)
                } else {
                    (__ci_expr_ternary_8 = 128)
                }

                if ((if ((((unsafe: ((__param_code.tables + ((512 as isize) as usize)) + ((__ci_expr_ternary_8 as isize) as usize))[((__local_ch as c_uint) / (8 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_ch as c_uint) % (8 as c_uint)) as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_ch = (unsafe: (__param_code.tables + ((256 as isize) as usize))[__local_ch]))
                }


            }
        }


        if (__local_utf != 0) {
            (__local_chlen = _pcre2_ord2utf_8(__local_ch, (&(unsafe: __local_temp[0]) as *mut u8)))
        } else {
            (__local_temp[0] = __local_ch)

            (__local_chlen = 1)

        }

        var __ci_expr_logic_9: c_int = 0

        if ((if not (__local_overflow != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if __local_chlen <= __local_output_cap: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_9 != 0) {
            with_memcpy((__local_output as *i8), ((&(unsafe: __local_temp[0]) as *mut u8) as *i8), (((__local_chlen as c_uint) *% (1 as c_uint)) as i64))

            (__local_output = __local_output + (__local_chlen as usize))

            (__local_output_cap = __local_output_cap - __local_chlen)

        } else {
            (__local_overflow = 1)

        }


        if ((if __local_chlen > (((~(0 as c_ulong)) as c_ulong) -% (__local_written as c_ulong)): 1 else: 0) != 0) {
            return (~(0 as c_ulong))
        }

        (__local_written = __local_written + __local_chlen)

        (__local_next_to_upper = __local_rest_to_upper)

        if (__local_single_char != 0) {
            var __local_rest_len: c_ulong = (((__local_input_end as usize) -% (__local_input as usize)) / sizeof[u8]())

            var __ci_expr_logic_10: c_int = 0

            if ((if not (__local_overflow != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_10 = (if (if __local_rest_len <= __local_output_cap: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_10 != 0) {
                with_memcpy((__local_output as *i8), (__local_input as *i8), (((__local_rest_len as c_ulong) *% (1 as c_ulong)) as i64))
            }


            if ((if __local_rest_len > (((~(0 as c_ulong)) as c_ulong) -% (__local_written as c_ulong)): 1 else: 0) != 0) {
                return (~(0 as c_ulong))
            }

            (__local_written = __local_written + __local_rest_len)

            return __local_written

        }

    }

    return __local_written

}

fn do_case_copy(__param_input_output: *mut u8, __param_input_len: c_ulong, __param_output_cap: c_ulong, __param_state: *mut case_state, __param_utf: c_int, __param_substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, __param_substitute_case_callout_data: *mut c_void) -> c_ulong {
    var __local_input: *const u8 = __param_input_output

    var __local_output: *mut u8 = __param_input_output

    var __local_rc: c_ulong

    var __local_rc2: c_ulong

    var __local_ch1_to_case: c_int

    var __local_rest_to_case: c_int

    var __local_ch1: [6]u8

    var __local_ch1_len: c_ulong

    var __local_rest: *const u8

    var __local_rest_len: c_ulong

    var __local_ch1_overflow: c_int = 0

    var __local_rest_overflow: c_int = 0

    do {
        0
    } while (0 != 0)

    while true {
        match __param_state.to_case {
            1 => {
                if ((if __param_state.single_char == 0: 1 else: 0) != 0) {
                    (__local_rc = __param_substitute_case_callout(__local_input, __param_input_len, __local_output, __param_output_cap, __param_state.to_case, __param_substitute_case_callout_data))

                    if ((if __param_state.to_case == 3: 1 else: 0) != 0) {
                        ((unsafe: *__param_state).to_case = 1)
                    }

                    return __local_rc

                }

                (__local_ch1_to_case = __param_state.to_case)

                (__local_rest_to_case = 0)

            },
            2 => {
                if ((if __param_state.single_char == 0: 1 else: 0) != 0) {
                    (__local_rc = __param_substitute_case_callout(__local_input, __param_input_len, __local_output, __param_output_cap, __param_state.to_case, __param_substitute_case_callout_data))

                    if ((if __param_state.to_case == 3: 1 else: 0) != 0) {
                        ((unsafe: *__param_state).to_case = 1)
                    }

                    return __local_rc

                }

                (__local_ch1_to_case = __param_state.to_case)

                (__local_rest_to_case = 0)

            },
            3 => {
                if ((if __param_state.single_char == 0: 1 else: 0) != 0) {
                    (__local_rc = __param_substitute_case_callout(__local_input, __param_input_len, __local_output, __param_output_cap, __param_state.to_case, __param_substitute_case_callout_data))

                    if ((if __param_state.to_case == 3: 1 else: 0) != 0) {
                        ((unsafe: *__param_state).to_case = 1)
                    }

                    return __local_rc

                }

                (__local_ch1_to_case = __param_state.to_case)

                (__local_rest_to_case = 0)

            },
            4 => {
                (__local_ch1_to_case = 1)

                (__local_rest_to_case = 2)

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

    var __local_ch_end: *const u8 = __local_input

    var __local_ch: c_uint

    var __ci_expr_old_1: *const u8 = __local_ch_end

    (__local_ch_end = __local_ch_end + 1)

    (__local_ch = (unsafe: *__ci_expr_old_1))


    var __ci_expr_logic_2: c_int = 0

    if (__param_utf != 0) {
        (__ci_expr_logic_2 = (if (if __local_ch >= 192: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        if ((if ((__local_ch as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            var __ci_expr_old_3: *const u8 = __local_ch_end

            (__local_ch_end = __local_ch_end + 1)

            (__local_ch = (((((__local_ch as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_3) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

        } else {
            if ((if ((__local_ch as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                (__local_ch = (((((((__local_ch as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_ch_end) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ch_end[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                (__local_ch_end = __local_ch_end + ((2 as isize) as usize))

            } else {
                if ((if ((__local_ch as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_ch = (((((((((__local_ch as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_ch_end) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ch_end[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ch_end[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    (__local_ch_end = __local_ch_end + ((3 as isize) as usize))

                } else {
                    if ((if ((__local_ch as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_ch = (((((((((((__local_ch as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_ch_end) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ch_end[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ch_end[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ch_end[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_ch_end = __local_ch_end + ((4 as isize) as usize))

                    } else {
                        (__local_ch = (((((((((((((__local_ch as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_ch_end) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ch_end[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ch_end[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_ch_end[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_ch_end[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_ch_end = __local_ch_end + ((5 as isize) as usize))

                    }
                }
            }
        }

    }


    __local_ch

    do {
        0
    } while (0 != 0)

    (__local_ch1_len = ((__local_ch_end as usize) -% (__local_input as usize)) / sizeof[u8]())

    with_memcpy(((&(unsafe: __local_ch1[0]) as *mut u8) as *i8), (__local_input as *i8), (((__local_ch1_len as c_ulong) *% (1 as c_ulong)) as i64))


    (__local_rest = __local_input + (__local_ch1_len as usize))

    (__local_rest_len = ((__param_input_len as c_ulong) -% (__local_ch1_len as c_ulong)))

    var __local_ch1_cap: c_ulong

    var __local_max_ch1_cap: c_ulong

    (__local_ch1_cap = __local_ch1_len)

    do {
        0
    } while (0 != 0)

    (__local_max_ch1_cap = ((__param_output_cap as c_ulong) -% (__local_rest_len as c_ulong)))

    while (1 != 0) {
        (__local_rc = __param_substitute_case_callout((&(unsafe: __local_ch1[0]) as *mut u8), __local_ch1_len, __local_output, __local_ch1_cap, __local_ch1_to_case, __param_substitute_case_callout_data))

        if ((if __local_rc == (~(0 as c_ulong)): 1 else: 0) != 0) {
            return __local_rc
        }

        if ((if __local_rc <= __local_ch1_cap: 1 else: 0) != 0) {
            break
        }

        if ((if __local_rc > __local_max_ch1_cap: 1 else: 0) != 0) {
            (__local_ch1_overflow = 1)

            break

        }

        with_memmove(((__param_input_output + (__local_rc as usize)) as *i8), (__local_rest as *i8), (((__local_rest_len as c_ulong) *% (1 as c_ulong)) as i64))

        (__local_rest = __local_input + (__local_rc as usize))

        (__local_ch1_cap = __local_rc)

    }


    if ((if __local_rest_to_case == 0: 1 else: 0) != 0) {
        if ((if not (__local_ch1_overflow != 0): 1 else: 0) != 0) {
            do {
                0
            } while (0 != 0)

            with_memmove(((__local_output + (__local_rc as usize)) as *i8), (__local_rest as *i8), (((__local_rest_len as c_ulong) *% (1 as c_ulong)) as i64))

        }

        (__local_rc2 = __local_rest_len)

        ((unsafe: *__param_state).to_case = 0)

    } else {
        var __local_dummy: [1]u8

        var __ci_expr_ternary_4: *mut u8 = null

        if (__local_ch1_overflow != 0) {
            (__ci_expr_ternary_4 = (&(unsafe: __local_dummy[0]) as *mut u8))
        } else {
            (__ci_expr_ternary_4 = __local_output + (__local_rc as usize))
        }

        var __ci_expr_ternary_5: c_ulong = 0

        if (__local_ch1_overflow != 0) {
            (__ci_expr_ternary_5 = 0)
        } else {
            (__ci_expr_ternary_5 = ((__param_output_cap as c_ulong) -% (__local_rc as c_ulong)))
        }

        (__local_rc2 = __param_substitute_case_callout(__local_rest, __local_rest_len, __ci_expr_ternary_4, __ci_expr_ternary_5, __local_rest_to_case, __param_substitute_case_callout_data))


        if ((if __local_rc2 == (~(0 as c_ulong)): 1 else: 0) != 0) {
            return __local_rc2
        }

        var __ci_expr_logic_6: c_int = 0

        if ((if not (__local_ch1_overflow != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if __local_rc2 > ((__param_output_cap as c_ulong) -% (__local_rc as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__local_rest_overflow = 1)
        }


        var __ci_expr_logic_7: c_int = 0

        if (__local_ch1_overflow != 0) {
            (__ci_expr_logic_7 = (if (if __local_rc2 < __local_rest_len: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_7 != 0) {
            (__local_rc2 = __local_rest_len)
        }


        ((unsafe: *__param_state).to_case = 2)

    }

    if ((if __local_rc2 > (((~(0 as c_ulong)) as c_ulong) -% (__local_rc as c_ulong)): 1 else: 0) != 0) {
        return (~(0 as c_ulong))
    }

    do {
        0
    } while (0 != 0)

    __local_rest_overflow

    return ((__local_rc as c_ulong) +% (__local_rc2 as c_ulong))

}
