// Migrated from PCRE2
use std.re.defs

fn pcre2_substitute_8(code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, __param_start_offset: c_ulong, __param_options: c_uint, __param_match_data: *mut pcre2_real_match_data_8, mcontext: *mut pcre2_real_match_context_8, __param_replacement: *const u8, __param_rlength: c_ulong, buffer: *mut u8, blength: *mut c_ulong) -> c_int {
    var subject = __param_subject
    var length = __param_length
    var start_offset = __param_start_offset
    var options = __param_options
    var match_data = __param_match_data
    var replacement = __param_replacement
    var rlength = __param_rlength
    var rc__goto_748_5: c_int = 0
    var subs__goto_749_5: c_int = 0
    var ovector_count__goto_750_10: c_uint = 0
    var goptions__goto_751_10: c_uint = 0
    var suboptions__goto_752_10: c_uint = 0
    var internal_match_data__goto_753_19: *mut pcre2_real_match_data_8 = null
    var escaped_literal__goto_754_6: c_int = 0
    var overflowed__goto_755_6: c_int = 0
    var use_existing_match__goto_756_6: c_int = 0
    var replacement_only__goto_757_6: c_int = 0
    var utf__goto_758_6: c_int = 0
    var partial__goto_759_6: c_int = 0
    var temp__goto_760_13: [6]u8
    var null_str__goto_761_13: [1]u8
    var original_subject__goto_762_12: *const u8 = null
    var ptr__goto_763_12: *const u8 = null
    var repend__goto_764_12: *const u8 = null
    var extra_needed__goto_765_12: c_ulong = 0
    var buff_offset__goto_766_12: c_ulong = 0
    var buff_length__goto_766_25: c_ulong = 0
    var lengthleft__goto_766_38: c_ulong = 0
    var fraglength__goto_766_50: c_ulong = 0
    var ovector__goto_767_13: *mut c_ulong = null
    var ovecsave__goto_768_12: [2]c_ulong
    var scb__goto_769_32: pcre2_substitute_callout_block_8
    var sub_start_extra_needed__goto_770_12: c_ulong = 0
    var substitute_case_callout__goto_771_14: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null
    var substitute_case_callout_data__goto_773_7: *mut c_void = null
    var gcontext__goto_889_25: pcre2_real_general_context_8
    var pairs__goto_900_7: c_int = 0
    var gcontext__goto_901_25: pcre2_real_general_context_8
    var chkmc_length__goto_965_24: c_ulong = 0
    var ptrstack__goto_973_14: [20]*const u8
    var ptrstackptr__goto_974_12: c_uint = 0
    var forcecase__goto_975_14: case_state
    var casestart_offset__goto_976_14: c_ulong = 0
    var casestart_extra_needed__goto_977_14: c_ulong = 0
    var chkmc_length__goto_1045_26: c_ulong = 0
    var chkmc_length__goto_1056_5: c_ulong = 0
    var ch__goto_1066_14: c_uint = 0
    var chlen__goto_1067_18: c_uint = 0
    var group__goto_1068_9: c_int = 0
    var special__goto_1069_14: c_uint = 0
    var text1_start__goto_1070_16: *const u8 = null
    var text1_end__goto_1071_16: *const u8 = null
    var text2_start__goto_1072_16: *const u8 = null
    var text2_end__goto_1073_16: *const u8 = null
    var name__goto_1074_17: [129]u8
    var inparens__goto_1103_12: c_int = 0
    var inangle__goto_1104_12: c_int = 0
    var star__goto_1105_12: c_int = 0
    var sublength__goto_1106_18: c_ulong = 0
    var next__goto_1107_19: u8 = 0
    var subptr__goto_1108_18: *const u8 = null
    var subptrend__goto_1108_26: *const u8 = null
    var name_len__goto_1273_20: c_ulong = 0
    var name_start__goto_1274_20: *const u8 = null
    var mark__goto_1340_22: *const u8 = null
    var chkcc_length__goto_1348_15: c_ulong = 0
    var chkcc_rc__goto_1348_15: c_ulong = 0
    var chkmc_length__goto_1350_15: c_ulong = 0
    var first__goto_1369_22: *const u8 = null
    var last__goto_1369_29: *const u8 = null
    var entry__goto_1369_35: *const u8 = null
    var ng__goto_1381_24: c_uint = 0
    var chkcc_length__goto_1461_11: c_ulong = 0
    var chkcc_rc__goto_1461_11: c_ulong = 0
    var chkmc_length__goto_1463_11: c_ulong = 0
    var errorcode__goto_1475_11: c_int = 0
    var new_forcecase__goto_1476_18: case_state
    var chars_outstanding__goto_1534_11: c_ulong = 0
    var guess__goto_1534_11: c_ulong = 0
    var chkcc_length__goto_1534_11: c_ulong = 0
    var chkcc_rc__goto_1534_11: c_ulong = 0
    var chkcc_length__goto_1573_11: c_ulong = 0
    var chkcc_rc__goto_1573_11: c_ulong = 0
    var chkmc_length__goto_1575_11: c_ulong = 0
    var name_len__goto_1580_22: c_ulong = 0
    var name_start__goto_1581_22: *const u8 = null
    var ch_start__goto_1619_18: *const u8 = null
    var chkcc_length__goto_1628_9: c_ulong = 0
    var chkcc_rc__goto_1628_9: c_ulong = 0
    var chkmc_length__goto_1630_9: c_ulong = 0
    var chars_outstanding__goto_1643_5: c_ulong = 0
    var guess__goto_1643_5: c_ulong = 0
    var chkcc_length__goto_1643_5: c_ulong = 0
    var chkcc_rc__goto_1643_5: c_ulong = 0
    var newlength__goto_1664_20: c_ulong = 0
    var oldlength__goto_1665_20: c_ulong = 0
    var chkmc_length__goto_1669_32: c_ulong = 0
    var newlength_buf__goto_1688_18: c_ulong = 0
    var newlength_extra__goto_1689_18: c_ulong = 0
    var newlength__goto_1690_18: c_ulong = 0
    var oldlength__goto_1693_18: c_ulong = 0
    var additional__goto_1700_20: c_ulong = 0
    var chkmc_length__goto_1738_3: c_ulong = 0
    var chkmc_length__goto_1742_1: c_ulong = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (goptions__goto_751_10 = 0)
                (internal_match_data__goto_753_19 = ((null as *mut pcre2_real_match_data_8)))
                (escaped_literal__goto_754_6 = 0)
                (overflowed__goto_755_6 = 0)
                (utf__goto_758_6 = (if (code.overall_options & 524288) != 0: 1 else: 0))
                (partial__goto_759_6 = (if (options & (32 | 16)) != 0: 1 else: 0))
                (null_str__goto_761_13 = [205])
                (original_subject__goto_762_12 = subject)
                (repend__goto_764_12 = null)
                (extra_needed__goto_765_12 = 0)
                (ovecsave__goto_768_12 = [0, 0])
                (substitute_case_callout__goto_771_14 = ((null as *mut fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)))
                (substitute_case_callout_data__goto_773_7 = null)
                (buff_offset__goto_766_12 = 0)
                if (__goto_pending != 0) {
                    continue
                }
                (buff_length__goto_766_25 = (unsafe: *blength))
                (lengthleft__goto_766_38 = buff_length__goto_766_25)
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *blength) = (~(0 as c_ulong)))
                if (__goto_pending != 0) {
                    continue
                }
                if ((if mcontext != null: 1 else: 0) != 0) {
                    (substitute_case_callout__goto_771_14 = ((mcontext.substitute_case_callout as *mut fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    (substitute_case_callout_data__goto_773_7 = mcontext.substitute_case_callout_data)
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_logic_0: c_int = 0
                if (partial__goto_759_6 != 0) {
                    (__ci_expr_logic_0 = (if (if (options & 131072) == 0: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_0 != 0) {
                    return -34
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if replacement == null: 1 else: 0) != 0) {
                    if ((if rlength != 0: 1 else: 0) != 0) {
                        return -51
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    (replacement = (&null_str__goto_761_13[0] as *mut u8))
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if rlength == (~(0 as c_ulong)): 1 else: 0) != 0) {
                    (rlength = _pcre2_strlen_8(replacement))
                }
                if (__goto_pending != 0) {
                    continue
                }
                (repend__goto_764_12 = replacement + rlength)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if subject == null: 1 else: 0) != 0) {
                    if ((if length != 0: 1 else: 0) != 0) {
                        return -51
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    (subject = (&null_str__goto_761_13[0] as *mut u8))
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if length == (~(0 as c_ulong)): 1 else: 0) != 0) {
                    (length = _pcre2_strlen_8(subject))
                }
                if (__goto_pending != 0) {
                    continue
                }
                (use_existing_match__goto_756_6 = (if (options & 65536) != 0: 1 else: 0))
                if (__goto_pending != 0) {
                    continue
                }
                (replacement_only__goto_757_6 = (if (options & 131072) != 0: 1 else: 0))
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_logic_1: c_int = 0
                if (use_existing_match__goto_756_6 != 0) {
                    (__ci_expr_logic_1 = (if (if match_data == null: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_1 != 0) {
                    return -51
                }
                if (__goto_pending != 0) {
                    continue
                }
                if (use_existing_match__goto_756_6 != 0) {
                    var __ci_expr_logic_2: c_int = 0
                    if ((if match_data.rc < 0: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if match_data.rc != -1: 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_2 != 0) {
                        return match_data.rc
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
                        return -41
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if code != match_data.code: 1 else: 0) != 0) {
                        return -71
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    var __ci_expr_logic_6: c_int
                    if ((if length != match_data.subject_length: 1 else: 0) != 0) {
                        (__ci_expr_logic_6 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_5: c_int
                        if ((if original_subject__goto_762_12 == match_data.subject: 1 else: 0) != 0) {
                            (__ci_expr_logic_5 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_4: c_int = 0
                            if ((if (match_data.flags & 1) != 0: 1 else: 0) != 0) {
                                var __ci_expr_logic_3: c_int
                                if ((if length == 0: 1 else: 0) != 0) {
                                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_3 = (if (if with_memcmp((subject as *i8), (match_data.subject as *i8), ((length *% 1) as i64)) == 0: 1 else: 0) != 0: 1 else: 0))
                                }
                                (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))
                            }
                            (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))
                        }
                        (__ci_expr_logic_6 = (if (if not (__ci_expr_logic_5 != 0): 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_6 != 0) {
                        return -72
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if start_offset != match_data.start_offset: 1 else: 0) != 0) {
                        return -73
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if (options & (~((((((((512 | 256) | 32768) | 65536) | 4096) | 131072) | 2048) | 1024) | 1073741824))) != (match_data.options & (~1073741824)): 1 else: 0) != 0) {
                        return -74
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if match_data == null: 1 else: 0) != 0) {
                    var __ci_expr_ternary_7: pcre2_memctl
                    if ((if mcontext == null: 1 else: 0) != 0) {
                        (__ci_expr_ternary_7 = (code as *mut pcre2_real_code_8).memctl)
                    } else {
                        (__ci_expr_ternary_7 = mcontext.memctl)
                    }
                    (gcontext__goto_889_25.memctl = __ci_expr_ternary_7)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (internal_match_data__goto_753_19 = pcre2_match_data_create_from_pattern_8(code, (&mut gcontext__goto_889_25 as *mut pcre2_real_general_context_8)))
                    (match_data = internal_match_data__goto_753_19)
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if internal_match_data__goto_753_19 == null: 1 else: 0) != 0) {
                        return -48
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                } else {
                    if (use_existing_match__goto_756_6 != 0) {
                        var __ci_expr_ternary_8: pcre2_memctl
                        if ((if mcontext == null: 1 else: 0) != 0) {
                            (__ci_expr_ternary_8 = (code as *mut pcre2_real_code_8).memctl)
                        } else {
                            (__ci_expr_ternary_8 = mcontext.memctl)
                        }
                        (gcontext__goto_901_25.memctl = __ci_expr_ternary_8)
                        if (__goto_pending != 0) {
                            continue
                        }
                        var __ci_expr_ternary_9: c_int = 0
                        if ((if (code.top_bracket + 1) < match_data.oveccount: 1 else: 0) != 0) {
                            (__ci_expr_ternary_9 = code.top_bracket + 1)
                        } else {
                            (__ci_expr_ternary_9 = match_data.oveccount)
                        }
                        (pairs__goto_900_7 = __ci_expr_ternary_9)
                        if (__goto_pending != 0) {
                            continue
                        }
                        (internal_match_data__goto_753_19 = pcre2_match_data_create_8(match_data.oveccount, (&mut gcontext__goto_901_25 as *mut pcre2_real_general_context_8)))
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if internal_match_data__goto_753_19 == null: 1 else: 0) != 0) {
                            return -48
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        with_memcpy((internal_match_data__goto_753_19 as *i8), (match_data as *i8), ((120 +% ((2 * pairs__goto_900_7) *% sizeof[c_ulong]())) as i64))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (internal_match_data__goto_753_19.heapframes = ((null as *mut heapframe)))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (internal_match_data__goto_753_19.heapframes_size = 0)
                        if (__goto_pending != 0) {
                            continue
                        }
                        (internal_match_data__goto_753_19.flags = internal_match_data__goto_753_19.flags & (~1))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (match_data = internal_match_data__goto_753_19)
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if internal_match_data__goto_753_19 != null: 1 else: 0) != 0) {
                    (options = options & (~16384))
                }
                if (__goto_pending != 0) {
                    continue
                }
                (ovector__goto_767_13 = pcre2_get_ovector_pointer_8(match_data))
                if (__goto_pending != 0) {
                    continue
                }
                (ovector_count__goto_750_10 = pcre2_get_ovector_count_8(match_data))
                if (__goto_pending != 0) {
                    continue
                }
                (scb__goto_769_32.version = 0)
                if (__goto_pending != 0) {
                    continue
                }
                (scb__goto_769_32.input = subject)
                if (__goto_pending != 0) {
                    continue
                }
                (scb__goto_769_32.output = ((buffer as *const u8)))
                if (__goto_pending != 0) {
                    continue
                }
                (scb__goto_769_32.ovector = ovector__goto_767_13)
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_logic_10: c_int = 0
                if (utf__goto_758_6 != 0) {
                    (__ci_expr_logic_10 = (if (if (options & 1073741824) == 0: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_10 != 0) {
                    (rc__goto_748_5 = _pcre2_valid_utf_8(replacement, rlength, ((&match_data.startchar as *const c_ulong) as *mut c_ulong)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if rc__goto_748_5 != 0: 1 else: 0) != 0) {
                        (match_data.leftchar = 0)
                        if (__goto_pending != 0) {
                            continue
                        }
                        __pc = 6
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
                (suboptions__goto_752_10 = options & (((((((512 | 256) | 32768) | 65536) | 4096) | 131072) | 2048) | 1024))
                if (__goto_pending != 0) {
                    continue
                }
                (options = options & (~(((((((512 | 256) | 32768) | 65536) | 4096) | 131072) | 2048) | 1024)))
                if (__goto_pending != 0) {
                    continue
                }
                if ((if start_offset > length: 1 else: 0) != 0) {
                    (match_data.leftchar = 0)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (rc__goto_748_5 = -33)
                    if (__goto_pending != 0) {
                        continue
                    }
                    __pc = 6
                    __goto_pending = 1
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if not (replacement_only__goto_757_6 != 0): 1 else: 0) != 0) {
                    while true {
                        if (overflowed__goto_755_6 != 0) {
                            if ((if chkmc_length__goto_965_24 > ((~(0 as c_ulong)) -% extra_needed__goto_765_12): 1 else: 0) != 0) {
                                __pc = 9
                                __goto_pending = 1
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            (extra_needed__goto_765_12 = extra_needed__goto_765_12 + chkmc_length__goto_965_24)
                            if (__goto_pending != 0) {
                                break
                            }
                        } else {
                            if ((if lengthleft__goto_766_38 < chkmc_length__goto_965_24: 1 else: 0) != 0) {
                                if ((if (suboptions__goto_752_10 & 4096) == 0: 1 else: 0) != 0) {
                                    __pc = 7
                                    __goto_pending = 1
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                (overflowed__goto_755_6 = 1)
                                if (__goto_pending != 0) {
                                    break
                                }
                                (extra_needed__goto_765_12 = (chkmc_length__goto_965_24 -% lengthleft__goto_766_38))
                                if (__goto_pending != 0) {
                                    break
                                }
                            } else {
                                with_memcpy(((buffer + buff_offset__goto_766_12) as *i8), (subject as *i8), ((chkmc_length__goto_965_24 *% 1) as i64))
                                if (__goto_pending != 0) {
                                    break
                                }
                                (buff_offset__goto_766_12 = buff_offset__goto_766_12 + chkmc_length__goto_965_24)
                                if (__goto_pending != 0) {
                                    break
                                }
                                (lengthleft__goto_766_38 = lengthleft__goto_766_38 - chkmc_length__goto_965_24)
                                if (__goto_pending != 0) {
                                    break
                                }
                            }
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        if (not (0 != 0)) {
                            break
                        }
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                (subs__goto_749_5 = 0)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if not (replacement_only__goto_757_6 != 0): 1 else: 0) != 0) {
                    (fraglength__goto_766_50 = (length -% start_offset))
                    if (__goto_pending != 0) {
                        continue
                    }
                    while true {
                        if (overflowed__goto_755_6 != 0) {
                            if ((if chkmc_length__goto_1738_3 > ((~(0 as c_ulong)) -% extra_needed__goto_765_12): 1 else: 0) != 0) {
                                __pc = 9
                                __goto_pending = 1
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            (extra_needed__goto_765_12 = extra_needed__goto_765_12 + chkmc_length__goto_1738_3)
                            if (__goto_pending != 0) {
                                break
                            }
                        } else {
                            if ((if lengthleft__goto_766_38 < chkmc_length__goto_1738_3: 1 else: 0) != 0) {
                                if ((if (suboptions__goto_752_10 & 4096) == 0: 1 else: 0) != 0) {
                                    __pc = 7
                                    __goto_pending = 1
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                (overflowed__goto_755_6 = 1)
                                if (__goto_pending != 0) {
                                    break
                                }
                                (extra_needed__goto_765_12 = (chkmc_length__goto_1738_3 -% lengthleft__goto_766_38))
                                if (__goto_pending != 0) {
                                    break
                                }
                            } else {
                                with_memcpy(((buffer + buff_offset__goto_766_12) as *i8), ((subject + start_offset) as *i8), ((chkmc_length__goto_1738_3 *% 1) as i64))
                                if (__goto_pending != 0) {
                                    break
                                }
                                (buff_offset__goto_766_12 = buff_offset__goto_766_12 + chkmc_length__goto_1738_3)
                                if (__goto_pending != 0) {
                                    break
                                }
                                (lengthleft__goto_766_38 = lengthleft__goto_766_38 - chkmc_length__goto_1738_3)
                                if (__goto_pending != 0) {
                                    break
                                }
                            }
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        if (not (0 != 0)) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                (temp__goto_760_13[0] = 0)
                if (__goto_pending != 0) {
                    continue
                }
                while true {
                    if (overflowed__goto_755_6 != 0) {
                        if ((if chkmc_length__goto_1742_1 > ((~(0 as c_ulong)) -% extra_needed__goto_765_12): 1 else: 0) != 0) {
                            __pc = 9
                            __goto_pending = 1
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (extra_needed__goto_765_12 = extra_needed__goto_765_12 + chkmc_length__goto_1742_1)
                        if (__goto_pending != 0) {
                            break
                        }
                    } else {
                        if ((if lengthleft__goto_766_38 < chkmc_length__goto_1742_1: 1 else: 0) != 0) {
                            if ((if (suboptions__goto_752_10 & 4096) == 0: 1 else: 0) != 0) {
                                __pc = 7
                                __goto_pending = 1
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            (overflowed__goto_755_6 = 1)
                            if (__goto_pending != 0) {
                                break
                            }
                            (extra_needed__goto_765_12 = (chkmc_length__goto_1742_1 -% lengthleft__goto_766_38))
                            if (__goto_pending != 0) {
                                break
                            }
                        } else {
                            with_memcpy(((buffer + buff_offset__goto_766_12) as *i8), ((&temp__goto_760_13[0] as *mut u8) as *i8), ((chkmc_length__goto_1742_1 *% 1) as i64))
                            if (__goto_pending != 0) {
                                break
                            }
                            (buff_offset__goto_766_12 = buff_offset__goto_766_12 + chkmc_length__goto_1742_1)
                            if (__goto_pending != 0) {
                                break
                            }
                            (lengthleft__goto_766_38 = lengthleft__goto_766_38 - chkmc_length__goto_1742_1)
                            if (__goto_pending != 0) {
                                break
                            }
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    if (not (0 != 0)) {
                        break
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if (overflowed__goto_755_6 != 0) {
                    (rc__goto_748_5 = -48)
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if extra_needed__goto_765_12 > ((~(0 as c_ulong)) -% buff_length__goto_766_25): 1 else: 0) != 0) {
                        __pc = 9
                        __goto_pending = 1
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    ((unsafe: *blength) = (buff_length__goto_766_25 +% extra_needed__goto_765_12))
                    if (__goto_pending != 0) {
                        continue
                    }
                } else {
                    (rc__goto_748_5 = subs__goto_749_5)
                    if (__goto_pending != 0) {
                        continue
                    }
                    ((unsafe: *blength) = (buff_offset__goto_766_12 -% 1))
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 6
                __goto_pending = 1
                continue
            6 =>  // EXIT
                (__goto_pending = 0)
                if ((if internal_match_data__goto_753_19 != null: 1 else: 0) != 0) {
                    pcre2_match_data_free_8(internal_match_data__goto_753_19)
                } else {
                    (match_data.rc = rc__goto_748_5)
                }
                if (__goto_pending != 0) {
                    continue
                }
                return rc__goto_748_5
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 7
                __goto_pending = 1
                continue
            7 =>  // NOROOM
                (__goto_pending = 0)
                (rc__goto_748_5 = -48)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 6
                __goto_pending = 1
                continue
                __pc = 8
                __goto_pending = 1
                continue
            8 =>  // CASEERROR
                (__goto_pending = 0)
                (rc__goto_748_5 = -69)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 6
                __goto_pending = 1
                continue
                __pc = 9
                __goto_pending = 1
                continue
            9 =>  // TOOLARGEREPLACE
                (__goto_pending = 0)
                (rc__goto_748_5 = -70)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 6
                __goto_pending = 1
                continue
                __pc = 10
                __goto_pending = 1
                continue
            10 =>  // BAD
                (__goto_pending = 0)
                (rc__goto_748_5 = -35)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 12
                __goto_pending = 1
                continue
                __pc = 11
                __goto_pending = 1
                continue
            11 =>  // BADESCAPE
                (__goto_pending = 0)
                (rc__goto_748_5 = -57)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 12
                __goto_pending = 1
                continue
            12 =>  // PTREXIT
                (__goto_pending = 0)
                ((unsafe: *blength) = (((((ptr__goto_763_12 as usize) -% (replacement as usize)) / sizeof[u8]()) as c_ulong)))
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 6
                __goto_pending = 1
                continue
            _ => break
    }
}

fn find_text_end(code: *const pcre2_real_code_8, ptrptr: *mut *const u8, ptrend: *const u8, last: c_int) -> c_int {
    var rc__goto_80_5: c_int = 0
    var nestlevel__goto_81_10: c_uint = 0
    var literal__goto_82_6: c_int = 0
    var ptr__goto_83_12: *const u8 = null
    var erc__goto_115_9: c_int = 0
    var errorcode__goto_116_9: c_int = 0
    var ch__goto_117_14: c_uint = 0
    var esc_end_ptr__goto_118_16: *const u8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (rc__goto_80_5 = 0)
                (nestlevel__goto_81_10 = 0)
                (literal__goto_82_6 = 0)
                (ptr__goto_83_12 = (unsafe: *ptrptr))
                while ((if ptr__goto_83_12 < ptrend: 1 else: 0) != 0) {
                    if (literal__goto_82_6 != 0) {
                        var __ci_expr_logic_1: c_int = 0
                        var __ci_expr_logic_0: c_int = 0
                        if ((if (unsafe: ptr__goto_83_12[0]) == 92: 1 else: 0) != 0) {
                            (__ci_expr_logic_0 = (if (if ptr__goto_83_12 < (ptrend - ((1 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_0 != 0) {
                            (__ci_expr_logic_1 = (if (if (unsafe: ptr__goto_83_12[1]) == 69: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_1 != 0) {
                            (literal__goto_82_6 = 0)
                            if (__goto_pending != 0) {
                                break
                            }
                            (ptr__goto_83_12 = ptr__goto_83_12 + 1)
                            if (__goto_pending != 0) {
                                break
                            }
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                    } else {
                        if ((if (unsafe: *ptr__goto_83_12) == 125: 1 else: 0) != 0) {
                            if ((if nestlevel__goto_81_10 == 0: 1 else: 0) != 0) {
                                __pc = 1
                                __goto_pending = 1
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            (nestlevel__goto_81_10 = nestlevel__goto_81_10 - 1)
                            if (__goto_pending != 0) {
                                break
                            }
                        } else {
                            var __ci_expr_logic_3: c_int = 0
                            var __ci_expr_logic_2: c_int = 0
                            if ((if (unsafe: *ptr__goto_83_12) == 58: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if (if not (last != 0): 1 else: 0) != 0: 1 else: 0))
                            }
                            if (__ci_expr_logic_2 != 0) {
                                (__ci_expr_logic_3 = (if (if nestlevel__goto_81_10 == 0: 1 else: 0) != 0: 1 else: 0))
                            }
                            if (__ci_expr_logic_3 != 0) {
                                __pc = 1
                                __goto_pending = 1
                            } else {
                                if ((if (unsafe: *ptr__goto_83_12) == 36: 1 else: 0) != 0) {
                                    var __ci_expr_logic_4: c_int = 0
                                    if ((if ptr__goto_83_12 < (ptrend - ((1 as isize) as usize)): 1 else: 0) != 0) {
                                        (__ci_expr_logic_4 = (if (if (unsafe: ptr__goto_83_12[1]) == 123: 1 else: 0) != 0: 1 else: 0))
                                    }
                                    if (__ci_expr_logic_4 != 0) {
                                        (nestlevel__goto_81_10 = nestlevel__goto_81_10 + 1)
                                        if (__goto_pending != 0) {
                                            break
                                        }
                                        (ptr__goto_83_12 = ptr__goto_83_12 + 1)
                                        if (__goto_pending != 0) {
                                            break
                                        }
                                    }
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                } else {
                                    if ((if (unsafe: *ptr__goto_83_12) == 92: 1 else: 0) != 0) {
                                        0
                                    }
                                }
                            }
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (ptr__goto_83_12 = ptr__goto_83_12 + 1)
                }
                if (__goto_pending != 0) {
                    continue
                }
                (rc__goto_80_5 = -58)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 1
                __goto_pending = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr__goto_83_12)
                if (__goto_pending != 0) {
                    continue
                }
                return rc__goto_80_5
                if (__goto_pending != 0) {
                    continue
                }
            _ => break
    }
}

fn read_name_subst(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, ctypes: *const u8) -> c_int {
    var ptr__goto_205_12: *const u8 = null
    var nameptr__goto_206_12: *const u8 = null
    var c__goto_220_12: c_uint = 0
    var type___goto_220_15: c_uint = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (ptr__goto_205_12 = (unsafe: *ptrptr))
                (nameptr__goto_206_12 = ptr__goto_205_12)
                if ((if ptr__goto_205_12 >= ptrend: 1 else: 0) != 0) {
                    __pc = 1
                    __goto_pending = 1
                }
                if (__goto_pending != 0) {
                    continue
                }
                if (utf != 0) {
                    while ((if ptr__goto_205_12 < ptrend: 1 else: 0) != 0) {
                        (c__goto_220_12 = (unsafe: *ptr__goto_205_12))
                        if (__goto_pending != 0) {
                            break
                        }
                        if ((if c__goto_220_12 >= 192: 1 else: 0) != 0) {
                            if ((if (c__goto_220_12 & 32) == 0: 1 else: 0) != 0) {
                                (c__goto_220_12 = (((c__goto_220_12 & 31) as c_uint) << (6 as c_uint)) | ((unsafe: ptr__goto_205_12[1]) & 63))
                            } else {
                                if ((if (c__goto_220_12 & 16) == 0: 1 else: 0) != 0) {
                                    (c__goto_220_12 = ((((c__goto_220_12 & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: ptr__goto_205_12[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr__goto_205_12[2]) & 63))
                                } else {
                                    if ((if (c__goto_220_12 & 8) == 0: 1 else: 0) != 0) {
                                        (c__goto_220_12 = (((((c__goto_220_12 & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: ptr__goto_205_12[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr__goto_205_12[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr__goto_205_12[3]) & 63))
                                    } else {
                                        if ((if (c__goto_220_12 & 4) == 0: 1 else: 0) != 0) {
                                            (c__goto_220_12 = ((((((c__goto_220_12 & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: ptr__goto_205_12[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr__goto_205_12[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr__goto_205_12[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr__goto_205_12[4]) & 63))
                                        } else {
                                            (c__goto_220_12 = (((((((c__goto_220_12 & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: ptr__goto_205_12[1]) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: ptr__goto_205_12[2]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr__goto_205_12[3]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr__goto_205_12[4]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr__goto_205_12[5]) & 63))
                                        }
                                    }
                                }
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (type___goto_220_15 = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c__goto_220_12 as c_int) / 128)] * 128) + ((c__goto_220_12 as c_int) % 128))] as isize) as usize)).chartype)
                        if (__goto_pending != 0) {
                            break
                        }
                        var __ci_expr_logic_1: c_int = 0
                        var __ci_expr_logic_0: c_int = 0
                        if ((if type___goto_220_15 != 13: 1 else: 0) != 0) {
                            (__ci_expr_logic_0 = (if (if _pcre2_ucp_gentype_8[type___goto_220_15] != 1: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_0 != 0) {
                            (__ci_expr_logic_1 = (if (if c__goto_220_12 != 95: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_1 != 0) {
                            break
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (ptr__goto_205_12 = ptr__goto_205_12 + 1)
                        if (__goto_pending != 0) {
                            break
                        }
                        while true {
                            var __ci_expr_logic_2: c_int = 0
                            if ((if ptr__goto_205_12 < ptrend: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if (if ((unsafe: *ptr__goto_205_12) & 192) == 128: 1 else: 0) != 0: 1 else: 0))
                            }
                            if (not (__ci_expr_logic_2 != 0)) {
                                break
                            }
                            (ptr__goto_205_12 = ptr__goto_205_12 + 1)
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
                } else {
                    while true {
                        var __ci_expr_logic_4: c_int = 0
                        var __ci_expr_logic_3: c_int = 0
                        if ((if ptr__goto_205_12 < ptrend: 1 else: 0) != 0) {
                            (__ci_expr_logic_3 = (if 1 != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_3 != 0) {
                            (__ci_expr_logic_4 = (if (if ((unsafe: ctypes[(unsafe: *ptr__goto_205_12)]) & 16) != 0: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (not (__ci_expr_logic_4 != 0)) {
                            break
                        }
                        (ptr__goto_205_12 = ptr__goto_205_12 + 1)
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
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if (((ptr__goto_205_12 as usize) -% (nameptr__goto_206_12 as usize)) / sizeof[u8]()) > 128: 1 else: 0) != 0) {
                    __pc = 1
                    __goto_pending = 1
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if ptr__goto_205_12 == nameptr__goto_206_12: 1 else: 0) != 0) {
                    __pc = 1
                    __goto_pending = 1
                }
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *ptrptr) = ptr__goto_205_12)
                if (__goto_pending != 0) {
                    continue
                }
                return 1
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 1
                __goto_pending = 1
                continue
            1 =>  // FAILED
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr__goto_205_12)
                if (__goto_pending != 0) {
                    continue
                }
                return 0
                if (__goto_pending != 0) {
                    continue
                }
            _ => break
    }
}

fn pessimistic_case_inflation(len: c_ulong) -> c_ulong {
    return (((len as c_ulong) >> (3 as c_uint)) +% 10)

}

fn default_substitute_case_callout(__param_input: *const u8, input_len: c_ulong, __param_output: *mut u8, __param_output_cap: c_ulong, state: *mut case_state, code: *const pcre2_real_code_8) -> c_ulong {
    var input = __param_input
    var output = __param_output
    var output_cap = __param_output_cap
    var input_end: *const u8 = (input + input_len)

    var utf: c_int

    var ucp: c_int

    var temp: [6]u8

    var next_to_upper: c_int

    var rest_to_upper: c_int

    var single_char: c_int

    var overflow: c_int = 0

    var written: c_ulong = 0

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (utf = (if (code.overall_options & 524288) != 0: 1 else: 0))

    (ucp = (if (code.overall_options & 131072) != 0: 1 else: 0))

    if ((if input_len == 0: 1 else: 0) != 0) {
        return 0
    }

    match state.to_case:
        1 | 2 =>
            (rest_to_upper = (if state.to_case == 2: 1 else: 0))

            (next_to_upper = rest_to_upper)

        3 =>
            (next_to_upper = 1)

            (rest_to_upper = 0)

            (state.to_case = 1)

        4 =>
            (next_to_upper = 0)

            (rest_to_upper = 1)

            (state.to_case = 2)

        _ =>
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            return 0

            (rest_to_upper = (if state.to_case == 2: 1 else: 0))

            (next_to_upper = rest_to_upper)



    (single_char = state.single_char)

    if (single_char != 0) {
        (state.to_case = 0)
    }

    while ((if input < input_end: 1 else: 0) != 0) {
        var ch: c_uint

        var chlen: c_uint

        var __ci_expr_old_0: *const u8 = input

        (input = input + 1)

        (ch = (unsafe: *__ci_expr_old_0))


        var __ci_expr_logic_1: c_int = 0

        if (utf != 0) {
            (__ci_expr_logic_1 = (if (if ch >= 192: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            if ((if (ch & 32) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_2: *const u8 = input

                (input = input + 1)

                (ch = (((ch & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_2) & 63))

            } else {
                if ((if (ch & 16) == 0: 1 else: 0) != 0) {
                    (ch = ((((ch & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *input) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: input[1]) & 63))

                    (input = input + 2)

                } else {
                    if ((if (ch & 8) == 0: 1 else: 0) != 0) {
                        (ch = (((((ch & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *input) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: input[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: input[2]) & 63))

                        (input = input + 3)

                    } else {
                        if ((if (ch & 4) == 0: 1 else: 0) != 0) {
                            (ch = ((((((ch & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *input) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: input[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: input[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: input[3]) & 63))

                            (input = input + 4)

                        } else {
                            (ch = (((((((ch & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *input) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: input[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: input[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: input[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: input[4]) & 63))

                            (input = input + 5)

                        }
                    }
                }
            }

        }


        var __ci_expr_logic_4: c_int = 0

        var __ci_expr_logic_3: c_int

        if (utf != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if ucp != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if (if ch >= 128: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            var type_: c_uint = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((ch as c_int) / 128)] * 128) + ((ch as c_int) % 128))] as isize) as usize)).chartype

            var __ci_expr_logic_6: c_int = 0

            if ((if _pcre2_ucp_gentype_8[type_] == 1: 1 else: 0) != 0) {
                var __ci_expr_ternary_5: c_int = 0

                if (next_to_upper != 0) {
                    (__ci_expr_ternary_5 = ucp_Lu)
                } else {
                    (__ci_expr_ternary_5 = ucp_Ll)
                }

                (__ci_expr_logic_6 = (if (if type_ != __ci_expr_ternary_5: 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_6 != 0) {
                (ch = ((((ch as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((ch as c_int) / 128)] * 128) + ((ch as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))
            }


        } else {
            if (1 != 0) {
                var __ci_expr_ternary_7: c_int = 0

                if (next_to_upper != 0) {
                    (__ci_expr_ternary_7 = 96)
                } else {
                    (__ci_expr_ternary_7 = 128)
                }

                if ((if ((unsafe: ((code.tables + ((512 as isize) as usize)) + ((__ci_expr_ternary_7 as isize) as usize))[(ch / 8)]) & ((1 as c_uint) << ((ch % 8) as c_uint))) == 0: 1 else: 0) != 0) {
                    (ch = (unsafe: (code.tables + ((256 as isize) as usize))[ch]))
                }


            }
        }


        if (utf != 0) {
            (chlen = _pcre2_ord2utf_8(ch, (&temp[0] as *mut u8)))
        } else {
            (temp[0] = ch)

            (chlen = 1)

        }

        var __ci_expr_logic_8: c_int = 0

        if ((if not (overflow != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if chlen <= output_cap: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            with_memcpy((output as *i8), ((&temp[0] as *mut u8) as *i8), ((chlen *% 1) as i64))

            (output = output + chlen)

            (output_cap = output_cap - chlen)

        } else {
            (overflow = 1)

        }


        if ((if chlen > ((~(0 as c_ulong)) -% written): 1 else: 0) != 0) {
            return (~(0 as c_ulong))
        }

        (written = written + chlen)

        (next_to_upper = rest_to_upper)

        if (single_char != 0) {
            var rest_len: c_ulong = (((input_end as usize) -% (input as usize)) / sizeof[u8]())

            var __ci_expr_logic_9: c_int = 0

            if ((if not (overflow != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_9 = (if (if rest_len <= output_cap: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                with_memcpy((output as *i8), (input as *i8), ((rest_len *% 1) as i64))
            }


            if ((if rest_len > ((~(0 as c_ulong)) -% written): 1 else: 0) != 0) {
                return (~(0 as c_ulong))
            }

            (written = written + rest_len)

            return written

        }

    }

    return written

}

fn do_case_copy(input_output: *mut u8, input_len: c_ulong, output_cap: c_ulong, state: *mut case_state, utf: c_int, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, substitute_case_callout_data: *mut c_void) -> c_ulong {
    var input: *const u8 = input_output

    var output: *mut u8 = input_output

    var rc: c_ulong

    var rc2: c_ulong

    var ch1_to_case: c_int

    var rest_to_case: c_int

    var ch1: [6]u8

    var ch1_len: c_ulong

    var rest: *const u8

    var rest_len: c_ulong

    var ch1_overflow: c_int = 0

    var rest_overflow: c_int = 0

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    match state.to_case:
        1 | 2 | 3 =>
            if ((if state.single_char == 0: 1 else: 0) != 0) {
                (rc = substitute_case_callout(input, input_len, output, output_cap, state.to_case, substitute_case_callout_data))

                if ((if state.to_case == 3: 1 else: 0) != 0) {
                    (state.to_case = 1)
                }

                return rc

            }

            (ch1_to_case = state.to_case)

            (rest_to_case = 0)

        4 =>
            (ch1_to_case = 1)

            (rest_to_case = 2)

        _ =>
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            return 0

            if ((if state.single_char == 0: 1 else: 0) != 0) {
                (rc = substitute_case_callout(input, input_len, output, output_cap, state.to_case, substitute_case_callout_data))

                if ((if state.to_case == 3: 1 else: 0) != 0) {
                    (state.to_case = 1)
                }

                return rc

            }

            (ch1_to_case = state.to_case)

            (rest_to_case = 0)



    var ch_end: *const u8 = input

    var ch: c_uint

    var __ci_expr_old_0: *const u8 = ch_end

    (ch_end = ch_end + 1)

    (ch = (unsafe: *__ci_expr_old_0))


    var __ci_expr_logic_1: c_int = 0

    if (utf != 0) {
        (__ci_expr_logic_1 = (if (if ch >= 192: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        if ((if (ch & 32) == 0: 1 else: 0) != 0) {
            var __ci_expr_old_2: *const u8 = ch_end

            (ch_end = ch_end + 1)

            (ch = (((ch & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_2) & 63))

        } else {
            if ((if (ch & 16) == 0: 1 else: 0) != 0) {
                (ch = ((((ch & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *ch_end) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ch_end[1]) & 63))

                (ch_end = ch_end + 2)

            } else {
                if ((if (ch & 8) == 0: 1 else: 0) != 0) {
                    (ch = (((((ch & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *ch_end) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ch_end[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ch_end[2]) & 63))

                    (ch_end = ch_end + 3)

                } else {
                    if ((if (ch & 4) == 0: 1 else: 0) != 0) {
                        (ch = ((((((ch & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *ch_end) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ch_end[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ch_end[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ch_end[3]) & 63))

                        (ch_end = ch_end + 4)

                    } else {
                        (ch = (((((((ch & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *ch_end) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: ch_end[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ch_end[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ch_end[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ch_end[4]) & 63))

                        (ch_end = ch_end + 5)

                    }
                }
            }
        }

    }


    ch

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (ch1_len = ((ch_end as usize) -% (input as usize)) / sizeof[u8]())

    with_memcpy(((&ch1[0] as *mut u8) as *i8), (input as *i8), ((ch1_len *% 1) as i64))


    (rest = input + ch1_len)

    (rest_len = (input_len -% ch1_len))

    var ch1_cap: c_ulong

    var max_ch1_cap: c_ulong

    (ch1_cap = ch1_len)

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (max_ch1_cap = (output_cap -% rest_len))

    while (1 != 0) {
        (rc = substitute_case_callout((&ch1[0] as *mut u8), ch1_len, output, ch1_cap, ch1_to_case, substitute_case_callout_data))

        if ((if rc == (~(0 as c_ulong)): 1 else: 0) != 0) {
            return rc
        }

        if ((if rc <= ch1_cap: 1 else: 0) != 0) {
            break
        }

        if ((if rc > max_ch1_cap: 1 else: 0) != 0) {
            (ch1_overflow = 1)

            break

        }

        with_memmove(((input_output + rc) as *i8), (rest as *i8), ((rest_len *% 1) as i64))

        (rest = input + rc)

        (ch1_cap = rc)

    }


    if ((if rest_to_case == 0: 1 else: 0) != 0) {
        if ((if not (ch1_overflow != 0): 1 else: 0) != 0) {
            while true {
                if (not (0 != 0)) {
                    break
                }
            }

            with_memmove(((output + rc) as *i8), (rest as *i8), ((rest_len *% 1) as i64))

        }

        (rc2 = rest_len)

        (state.to_case = 0)

    } else {
        var dummy: [1]u8

        var __ci_expr_ternary_3: *mut u8 = null

        if (ch1_overflow != 0) {
            (__ci_expr_ternary_3 = (&dummy[0] as *mut u8))
        } else {
            (__ci_expr_ternary_3 = output + rc)
        }

        var __ci_expr_ternary_4: c_ulong = 0

        if (ch1_overflow != 0) {
            (__ci_expr_ternary_4 = 0)
        } else {
            (__ci_expr_ternary_4 = (output_cap -% rc))
        }

        (rc2 = substitute_case_callout(rest, rest_len, __ci_expr_ternary_3, __ci_expr_ternary_4, rest_to_case, substitute_case_callout_data))


        if ((if rc2 == (~(0 as c_ulong)): 1 else: 0) != 0) {
            return rc2
        }

        var __ci_expr_logic_5: c_int = 0

        if ((if not (ch1_overflow != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if rc2 > (output_cap -% rc): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (rest_overflow = 1)
        }


        var __ci_expr_logic_6: c_int = 0

        if (ch1_overflow != 0) {
            (__ci_expr_logic_6 = (if (if rc2 < rest_len: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (rc2 = rest_len)
        }


        (state.to_case = 2)

    }

    if ((if rc2 > ((~(0 as c_ulong)) -% rc): 1 else: 0) != 0) {
        return (~(0 as c_ulong))
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    rest_overflow

    return (rc +% rc2)

}
