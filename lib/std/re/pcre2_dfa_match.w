// Migrated from PCRE2
use std.re.defs

fn pcre2_dfa_match_8(__param_code: *const pcre2_real_code_8, __param_subject: *const u8, __param_length: c_ulong, __param_start_offset: c_ulong, __param_options: c_uint, __param_match_data: *mut pcre2_real_match_data_8, __param_mcontext: *mut pcre2_real_match_context_8, __param_workspace: *mut c_int, __param_wscount: c_ulong) -> c_int {
    var __local_subject = __param_subject
    var __local_length = __param_length
    var __local_options = __param_options
    var __local_rc__goto_3344_5: c_int = 0

    var __local_re__goto_3346_24: *const pcre2_real_code_8 = null

    var __local_original_options__goto_3347_10: c_uint = 0

    var __local_null_str__goto_3349_13: [1]u8

    var __local_original_subject__goto_3350_12: *const u8 = null

    var __local_start_match__goto_3351_12: *const u8 = null

    var __local_end_subject__goto_3352_12: *const u8 = null

    var __local_bumpalong_limit__goto_3353_12: *const u8 = null

    var __local_req_cu_ptr__goto_3354_12: *const u8 = null

    var __local_utf__goto_3356_6: c_int = 0

    var __local_anchored__goto_3356_11: c_int = 0

    var __local_startline__goto_3356_21: c_int = 0

    var __local_firstline__goto_3356_32: c_int = 0

    var __local_has_first_cu__goto_3357_6: c_int = 0

    var __local_has_req_cu__goto_3358_6: c_int = 0

    var __local_memchr_found_first_cu__goto_3361_12: *const u8 = null

    var __local_memchr_found_first_cu2__goto_3362_12: *const u8 = null

    var __local_first_cu__goto_3365_13: u8 = 0

    var __local_first_cu2__goto_3366_13: u8 = 0

    var __local_req_cu__goto_3367_13: u8 = 0

    var __local_req_cu2__goto_3368_13: u8 = 0

    var __local_start_bits__goto_3370_16: *const u8 = null

    var __local_cb__goto_3375_21: pcre2_callout_block_8

    var __local_actual_match_block__goto_3376_17: dfa_match_block_8

    var __local_mb__goto_3377_18: *mut dfa_match_block_8 = null

    var __local_base_recursion_workspace__goto_3384_5: [7680]c_int

    var __local_rws__goto_3385_13: *mut RWS_anchor = null

    var __local_check_subject__goto_3592_14: *const u8 = null

    var __local_i__goto_3597_18: c_uint = 0

    var __local_t__goto_3721_18: *const u8 = null

    var __local_ok__goto_3745_14: c_int = 0

    var __local_c__goto_3748_23: u8 = 0

    var __local_pp1__goto_3787_22: *const u8 = null

    var __local_pp2__goto_3788_22: *const u8 = null

    var __local_searchlength__goto_3789_22: c_ulong = 0

    var __local_c__goto_3902_20: c_uint = 0

    var __local_p__goto_3926_18: *const u8 = null

    var __local_check_length__goto_3960_20: c_ulong = 0

    var __local_pp__goto_3974_24: *const u8 = null

    var __local_next__goto_4119_15: *mut RWS_anchor = null

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_logic_32: c_int = 0

    var __ci_expr_logic_34: c_int = 0

    var __ci_expr_logic_35: c_int = 0

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_ternary_37: *const u8 = null

    var __ci_expr_ternary_38: *const u8 = null

    var __ci_expr_logic_39: c_int = 0

    var __ci_expr_ternary_40: *const u8 = null

    var __ci_expr_ternary_41: *const u8 = null

    var __ci_expr_ternary_42: *const u8 = null

    var __ci_expr_ternary_44: *const u8 = null

    var __ci_expr_logic_43: c_int = 0

    var __ci_expr_logic_45: c_int = 0

    var __ci_expr_logic_51: c_int = 0

    var __ci_expr_logic_52: c_int = 0

    var __ci_expr_logic_58: c_int = 0

    var __ci_expr_logic_62: c_int = 0

    var __ci_expr_logic_61: c_int = 0

    var __ci_expr_logic_60: c_int = 0

    var __ci_expr_logic_63: c_int = 0

    var __ci_expr_ternary_64: c_int = 0

    var __ci_expr_logic_65: c_int = 0

    var __ci_expr_logic_67: c_int = 0

    var __ci_expr_logic_68: c_int = 0

    var __ci_expr_logic_69: c_int = 0

    var __ci_expr_logic_70: c_int = 0

    var __ci_expr_logic_71: c_int = 0

    var __ci_expr_logic_72: c_int = 0

    var __ci_expr_logic_78: c_int = 0

    var __ci_expr_logic_79: c_int = 0

    var __ci_expr_logic_85: c_int = 0

    var __ci_expr_logic_82: c_int = 0

    var __ci_expr_logic_81: c_int = 0

    var __ci_expr_logic_80: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_re__goto_3346_24 = __param_code)
        (__local_original_options__goto_3347_10 = __local_options)
        (__local_null_str__goto_3349_13 = [205])
        (__local_original_subject__goto_3350_12 = __local_subject)
        (__local_has_first_cu__goto_3357_6 = 0)
        (__local_has_req_cu__goto_3358_6 = 0)
        (__local_memchr_found_first_cu__goto_3361_12 = null)
        (__local_memchr_found_first_cu2__goto_3362_12 = null)
        (__local_first_cu__goto_3365_13 = 0)
        (__local_first_cu2__goto_3366_13 = 0)
        (__local_req_cu__goto_3367_13 = 0)
        (__local_req_cu2__goto_3368_13 = 0)
        (__local_start_bits__goto_3370_16 = ((null as *const u8)))
        (__local_mb__goto_3377_18 = ((&raw mut __local_actual_match_block__goto_3376_17 as *mut dfa_match_block_8)))
        (__local_rws__goto_3385_13 = (&__local_base_recursion_workspace__goto_3384_5[0] as *mut RWS_anchor))
        ((unsafe *__local_rws__goto_3385_13).next = ((null as *mut RWS_anchor)))
        ((unsafe *__local_rws__goto_3385_13).size = 7680)
        ((unsafe *__local_rws__goto_3385_13).free = 7676)
        (__ci_expr_logic_0 = 0)
        if ((if __local_subject == null: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_length == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        (__local_subject = (&__local_null_str__goto_3349_13[0] as *mut u8))
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        if ((if __param_match_data == null: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_3 {
        return -51
    }

    '__ci_bb_4 {
        if ((if __local_re__goto_3346_24 == null: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_subject == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __param_workspace == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_5 {
        (__local_rc__goto_3344_5 = -51)
        goto '__ci_bb_7
    }

    '__ci_bb_6 {
        if ((if ((__local_options as c_uint) & ((~(((((((((((((((((((((((2147483648 as c_uint) as c_uint) | (536870912 as c_uint)) as c_uint) | (1 as c_uint)) as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint)) as c_uint) | (8 as c_uint)) as c_uint) | (1073741824 as c_uint)) as c_uint) | (32 as c_uint)) as c_uint) | (16 as c_uint)) as c_uint) | (128 as c_uint)) as c_uint) | (64 as c_uint)) as c_uint) | (16384 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_7 {
        goto '__ci_bb_219
    }

    '__ci_bb_8 {
        (__local_rc__goto_3344_5 = -34)
        goto '__ci_bb_7
    }

    '__ci_bb_9 {
        if ((if __local_length == (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_10 {
        (__local_length = _pcre2_strlen_8(__local_subject))
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        if ((if __param_wscount < 20: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_12 {
        (__local_rc__goto_3344_5 = -43)
        goto '__ci_bb_7
    }

    '__ci_bb_13 {
        if ((if __param_start_offset > __local_length: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_14 {
        (__local_rc__goto_3344_5 = -33)
        goto '__ci_bb_7
    }

    '__ci_bb_15 {
        (__ci_expr_logic_3 = 0)
        if ((if ((__local_options as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if ((((__local_re__goto_3346_24.overall_options as c_uint) | (__local_options as c_uint)) as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        (__local_rc__goto_3344_5 = -34)
        goto '__ci_bb_7
    }

    '__ci_bb_17 {
        if ((if ((__local_re__goto_3346_24.overall_options as c_uint) & (67108864 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        (__local_rc__goto_3344_5 = -66)
        goto '__ci_bb_7
    }

    '__ci_bb_19 {
        if ((if __local_re__goto_3346_24.magic_number != 1346589253: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        (__local_rc__goto_3344_5 = -31)
        goto '__ci_bb_7
    }

    '__ci_bb_21 {
        if ((if ((__local_re__goto_3346_24.flags as c_uint) & (((((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint)) as c_uint)) != 1: 1 else: 0) != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_22 {
        (__local_rc__goto_3344_5 = -32)
        goto '__ci_bb_7
    }

    '__ci_bb_23 {
        (__local_options = __local_options | ((((__local_re__goto_3346_24.flags as c_uint) & (((65536 as c_uint) | (131072 as c_uint)) as c_uint)) as c_uint) / (((((((65536 as c_uint) | (131072 as c_uint)) as c_uint) & ((((~((65536 as c_uint) | (131072 as c_uint))) as c_uint) +% (1 as c_uint)) as c_uint)) as c_uint) / (((((4 as c_uint) | (8 as c_uint)) as c_uint) & ((((~((4 as c_uint) | (8 as c_uint))) as c_uint) +% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        if ((if ((__local_options as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_24 {
        if ((if ((unsafe __param_workspace[0]) & (-2 as c_int)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if (unsafe __param_workspace[1]) < 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_5 = (if (if (unsafe __param_workspace[1]) > ((((((__param_wscount as c_ulong) -% (2 as c_ulong)) as c_ulong) / (3 as c_ulong)) as c_int)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_25 {
        (__local_utf__goto_3356_6 = (if ((__local_re__goto_3346_24.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        (__local_start_match__goto_3351_12 = __local_subject + (__param_start_offset as usize))
        (__local_end_subject__goto_3352_12 = __local_subject + (__local_length as usize))
        (__local_req_cu_ptr__goto_3354_12 = __local_start_match__goto_3351_12 - ((1 as isize) as usize))
        if ((if ((__local_options as c_uint) & ((((2147483648 as c_uint) as c_uint) | (64 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if ((__local_re__goto_3346_24.overall_options as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_anchored__goto_3356_11 = __ci_expr_logic_6)
        (__local_startline__goto_3356_21 = (if ((__local_re__goto_3346_24.flags as c_uint) & (512 as c_uint)) != 0: 1 else: 0))
        (__ci_expr_logic_7 = 0)
        if ((if not (__local_anchored__goto_3356_11 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if ((__local_re__goto_3346_24.overall_options as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_firstline__goto_3356_32 = __ci_expr_logic_7)
        (__local_bumpalong_limit__goto_3353_12 = __local_end_subject__goto_3352_12)
        ((unsafe *__local_mb__goto_3377_18).cb = ((&raw mut __local_cb__goto_3375_21 as *mut pcre2_callout_block_8)))
        (__local_cb__goto_3375_21.version = 2)
        (__local_cb__goto_3375_21.subject = __local_subject)
        (__local_cb__goto_3375_21.subject_length = (((((__local_end_subject__goto_3352_12 as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong)))
        (__local_cb__goto_3375_21.callout_flags = 0)
        (__local_cb__goto_3375_21.capture_top = 1)
        (__local_cb__goto_3375_21.capture_last = 0)
        (__local_cb__goto_3375_21.mark = null)
        if ((if __param_mcontext == null: 1 else: 0) != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_26 {
        (__local_rc__goto_3344_5 = -38)
        goto '__ci_bb_7
    }

    '__ci_bb_27 {
        goto '__ci_bb_25
    }

    '__ci_bb_28 {
        ((unsafe *__local_mb__goto_3377_18).callout = ((null as *mut fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int)))
        with_memcpy((&raw mut (unsafe *__local_mb__goto_3377_18).memctl as *i8), (&raw const (unsafe *__local_re__goto_3346_24).memctl as *i8), sizeof[pcre2_memctl]())
        ((unsafe *__local_mb__goto_3377_18).match_limit = (&raw const _pcre2_default_match_context_8 as *const pcre2_real_match_context_8).match_limit)
        ((unsafe *__local_mb__goto_3377_18).match_limit_depth = (&raw const _pcre2_default_match_context_8 as *const pcre2_real_match_context_8).depth_limit)
        ((unsafe *__local_mb__goto_3377_18).heap_limit = (&raw const _pcre2_default_match_context_8 as *const pcre2_real_match_context_8).heap_limit)
        goto '__ci_bb_30
    }

    '__ci_bb_29 {
        if ((if __param_mcontext.offset_limit != (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_30 {
        if ((if __local_mb__goto_3377_18.match_limit > __local_re__goto_3346_24.limit_match: 1 else: 0) != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_31 {
        if ((if ((__local_re__goto_3346_24.overall_options as c_uint) & (8388608 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_32 {
        ((unsafe *__local_mb__goto_3377_18).callout = ((__param_mcontext.callout as *mut fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int)))
        ((unsafe *__local_mb__goto_3377_18).callout_data = __param_mcontext.callout_data)
        with_memcpy((&raw mut (unsafe *__local_mb__goto_3377_18).memctl as *i8), (&raw const (unsafe *__param_mcontext).memctl as *i8), sizeof[pcre2_memctl]())
        ((unsafe *__local_mb__goto_3377_18).match_limit = __param_mcontext.match_limit)
        ((unsafe *__local_mb__goto_3377_18).match_limit_depth = __param_mcontext.depth_limit)
        ((unsafe *__local_mb__goto_3377_18).heap_limit = __param_mcontext.heap_limit)
        goto '__ci_bb_30
    }

    '__ci_bb_33 {
        (__local_rc__goto_3344_5 = -56)
        goto '__ci_bb_7
    }

    '__ci_bb_34 {
        (__local_bumpalong_limit__goto_3353_12 = __local_subject + (__param_mcontext.offset_limit as usize))
        goto '__ci_bb_32
    }

    '__ci_bb_35 {
        ((unsafe *__local_mb__goto_3377_18).match_limit = __local_re__goto_3346_24.limit_match)
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        if ((if __local_mb__goto_3377_18.match_limit_depth > __local_re__goto_3346_24.limit_depth: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_37 {
        ((unsafe *__local_mb__goto_3377_18).match_limit_depth = __local_re__goto_3346_24.limit_depth)
        goto '__ci_bb_38
    }

    '__ci_bb_38 {
        if ((if __local_mb__goto_3377_18.heap_limit > __local_re__goto_3346_24.limit_heap: 1 else: 0) != 0) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_39 {
        ((unsafe *__local_mb__goto_3377_18).heap_limit = __local_re__goto_3346_24.limit_heap)
        goto '__ci_bb_40
    }

    '__ci_bb_40 {
        ((unsafe *__local_mb__goto_3377_18).start_code = (__local_re__goto_3346_24 as *const u8) + (__local_re__goto_3346_24.code_start as usize))
        ((unsafe *__local_mb__goto_3377_18).tables = __local_re__goto_3346_24.tables)
        ((unsafe *__local_mb__goto_3377_18).start_subject = __local_subject)
        ((unsafe *__local_mb__goto_3377_18).end_subject = __local_end_subject__goto_3352_12)
        ((unsafe *__local_mb__goto_3377_18).start_offset = __param_start_offset)
        if ((if __local_re__goto_3346_24.max_lookbehind > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if (if ((__local_re__goto_3346_24.flags as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        ((unsafe *__local_mb__goto_3377_18).allowemptypartial = __ci_expr_logic_8)
        ((unsafe *__local_mb__goto_3377_18).moptions = __local_options)
        ((unsafe *__local_mb__goto_3377_18).poptions = __local_re__goto_3346_24.overall_options)
        ((unsafe *__local_mb__goto_3377_18).match_call_count = 0)
        ((unsafe *__local_mb__goto_3377_18).heap_used = 0)
        ((unsafe *__local_mb__goto_3377_18).bsr_convention = __local_re__goto_3346_24.bsr_convention)
        ((unsafe *__local_mb__goto_3377_18).nltype = 0)
        goto '__ci_bb_41
    }

    '__ci_bb_41 {
        if (__local_re__goto_3346_24.newline_convention == 1) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_42 {
        (__ci_expr_logic_9 = 0)
        if (__local_utf__goto_3356_6 != 0) {
            (__ci_expr_logic_9 = (if (if ((__local_options as c_uint) & (1073741824 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_43 {
        ((unsafe *__local_mb__goto_3377_18).nllen = 1)
        ((unsafe *__local_mb__goto_3377_18).nl[0] = 13)
        goto '__ci_bb_42
    }

    '__ci_bb_44 {
        ((unsafe *__local_mb__goto_3377_18).nllen = 1)
        ((unsafe *__local_mb__goto_3377_18).nl[0] = 10)
        goto '__ci_bb_42
    }

    '__ci_bb_45 {
        ((unsafe *__local_mb__goto_3377_18).nllen = 1)
        ((unsafe *__local_mb__goto_3377_18).nl[0] = 0)
        goto '__ci_bb_42
    }

    '__ci_bb_46 {
        ((unsafe *__local_mb__goto_3377_18).nllen = 2)
        ((unsafe *__local_mb__goto_3377_18).nl[0] = 13)
        ((unsafe *__local_mb__goto_3377_18).nl[1] = 10)
        goto '__ci_bb_42
    }

    '__ci_bb_47 {
        ((unsafe *__local_mb__goto_3377_18).nltype = 1)
        goto '__ci_bb_42
    }

    '__ci_bb_48 {
        ((unsafe *__local_mb__goto_3377_18).nltype = 2)
        goto '__ci_bb_42
    }

    '__ci_bb_49 {
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        goto '__ci_bb_51
    }

    '__ci_bb_51 {
        if (0 != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_52 {
        (__local_rc__goto_3344_5 = -44)
        goto '__ci_bb_7
    }

    '__ci_bb_53 {
        if (__local_re__goto_3346_24.newline_convention == 2) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        if (__local_re__goto_3346_24.newline_convention == 6) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_55 {
        if (__local_re__goto_3346_24.newline_convention == 3) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_56 {
        if (__local_re__goto_3346_24.newline_convention == 4) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_57 {
        if (__local_re__goto_3346_24.newline_convention == 5) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_58 {
        (__local_check_subject__goto_3592_14 = __local_start_match__goto_3351_12)
        if ((if __param_start_offset > 0: 1 else: 0) != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_59 {
        if ((if ((__local_re__goto_3346_24.flags as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_60 {
        (__ci_expr_logic_10 = 0)
        if ((if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if ((((unsafe *__local_start_match__goto_3351_12) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_61 {
        (__local_rc__goto_3344_5 = _pcre2_valid_utf_8(__local_check_subject__goto_3592_14, ((__local_length as c_ulong) -% (((((__local_check_subject__goto_3592_14 as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong) as c_ulong)), ((&raw const (unsafe *__param_match_data).startchar as *const c_ulong) as *mut c_ulong)))
        if ((if __local_rc__goto_3344_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_62 {
        (__local_rc__goto_3344_5 = -36)
        goto '__ci_bb_7
    }

    '__ci_bb_63 {
        (__local_i__goto_3597_18 = __local_re__goto_3346_24.max_lookbehind)
        goto '__ci_bb_64
    }

    '__ci_bb_64 {
        (__ci_expr_logic_11 = 0)
        if ((if __local_i__goto_3597_18 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_11 = (if (if __local_check_subject__goto_3592_14 > __local_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_65 {
        (__local_check_subject__goto_3592_14 = __local_check_subject__goto_3592_14 - 1)
        goto '__ci_bb_68
    }

    '__ci_bb_66 {
        (__local_i__goto_3597_18 = __local_i__goto_3597_18 - 1)
        goto '__ci_bb_64
    }

    '__ci_bb_67 {
        goto '__ci_bb_61
    }

    '__ci_bb_68 {
        (__ci_expr_logic_12 = 0)
        if ((if __local_check_subject__goto_3592_14 > __local_subject: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if (if (((unsafe *__local_check_subject__goto_3592_14) as c_int) & 192) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_69 {
        (__local_check_subject__goto_3592_14 = __local_check_subject__goto_3592_14 - 1)
        goto '__ci_bb_68
    }

    '__ci_bb_70 {
        goto '__ci_bb_66
    }

    '__ci_bb_71 {
        ((unsafe *__param_match_data).startchar = __param_match_data.startchar + ((((__local_check_subject__goto_3592_14 as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong))
        goto '__ci_bb_7
    }

    '__ci_bb_72 {
        goto '__ci_bb_59
    }

    '__ci_bb_73 {
        (__local_has_first_cu__goto_3357_6 = 1)
        (__local_first_cu2__goto_3366_13 = ((__local_re__goto_3346_24.first_codeunit as u8)))
        (__local_first_cu__goto_3365_13 = __local_first_cu2__goto_3366_13)
        if ((if ((__local_re__goto_3346_24.flags as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_74 {
        (__ci_expr_logic_15 = 0)
        if ((if not (__local_startline__goto_3356_21 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if ((__local_re__goto_3346_24.flags as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_75 {
        if ((if ((__local_re__goto_3346_24.flags as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_83
        }
    }

    '__ci_bb_76 {
        (__local_first_cu2__goto_3366_13 = (unsafe (__local_mb__goto_3377_18.tables + ((256 as isize) as usize))[__local_first_cu__goto_3365_13]))
        (__ci_expr_logic_14 = 0)
        (__ci_expr_logic_13 = 0)
        if ((if __local_first_cu__goto_3365_13 > 127: 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if (if not (__local_utf__goto_3356_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            (__ci_expr_logic_14 = (if (if ((__local_re__goto_3346_24.overall_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_75
    }

    '__ci_bb_78 {
        (__local_first_cu2__goto_3366_13 = (((((__local_first_cu__goto_3365_13 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_first_cu__goto_3365_13 as c_int) / 128)] as c_int) * 128) + ((__local_first_cu__goto_3365_13 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint) as u8)))
        goto '__ci_bb_79
    }

    '__ci_bb_79 {
        goto '__ci_bb_77
    }

    '__ci_bb_80 {
        (__local_start_bits__goto_3370_16 = (&(unsafe __local_re__goto_3346_24.start_bitmap[0]) as *const u8))
        goto '__ci_bb_81
    }

    '__ci_bb_81 {
        goto '__ci_bb_75
    }

    '__ci_bb_82 {
        (__local_has_req_cu__goto_3358_6 = 1)
        (__local_req_cu2__goto_3368_13 = ((__local_re__goto_3346_24.last_codeunit as u8)))
        (__local_req_cu__goto_3367_13 = __local_req_cu2__goto_3368_13)
        if ((if ((__local_re__goto_3346_24.flags as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_83 {
        if ((if (((__param_match_data.flags as c_int) as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_84 {
        (__local_req_cu2__goto_3368_13 = (unsafe (__local_mb__goto_3377_18.tables + ((256 as isize) as usize))[__local_req_cu__goto_3367_13]))
        (__ci_expr_logic_17 = 0)
        (__ci_expr_logic_16 = 0)
        if ((if __local_req_cu__goto_3367_13 > 127: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if not (__local_utf__goto_3356_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            (__ci_expr_logic_17 = (if (if ((__local_re__goto_3346_24.overall_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_85 {
        goto '__ci_bb_83
    }

    '__ci_bb_86 {
        (__local_req_cu2__goto_3368_13 = (((((__local_req_cu__goto_3367_13 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_req_cu__goto_3367_13 as c_int) / 128)] as c_int) * 128) + ((__local_req_cu__goto_3367_13 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint) as u8)))
        goto '__ci_bb_87
    }

    '__ci_bb_87 {
        goto '__ci_bb_85
    }

    '__ci_bb_88 {
        (&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl).free((__param_match_data.subject as *mut c_void), (&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl).memory_data)
        ((unsafe *__param_match_data).flags = __param_match_data.flags & (~1))
        goto '__ci_bb_89
    }

    '__ci_bb_89 {
        ((unsafe *__param_match_data).code = __local_re__goto_3346_24)
        ((unsafe *__param_match_data).subject = null)
        ((unsafe *__param_match_data).mark = null)
        ((unsafe *__param_match_data).matchedby = 1)
        ((unsafe *__param_match_data).options = __local_original_options__goto_3347_10)
        goto '__ci_bb_90
    }

    '__ci_bb_90 {
        goto '__ci_bb_91
    }

    '__ci_bb_91 {
        (__ci_expr_logic_18 = 0)
        if ((if ((__local_re__goto_3346_24.optimization_flags as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if (if ((__local_options as c_uint) & (64 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_92 {
        goto '__ci_bb_90
    }

    '__ci_bb_93 {
        goto '__ci_bb_172
    }

    '__ci_bb_94 {
        if (__local_firstline__goto_3356_32 != 0) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_95 {
        if ((if __local_start_match__goto_3351_12 > __local_bumpalong_limit__goto_3353_12: 1 else: 0) != 0) {
            goto '__ci_bb_188
        } else {
            goto '__ci_bb_189
        }
    }

    '__ci_bb_96 {
        (__local_t__goto_3721_18 = __local_start_match__goto_3351_12)
        if (__local_utf__goto_3356_6 != 0) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_97 {
        if (__local_anchored__goto_3356_11 != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_98 {
        goto '__ci_bb_101
    }

    '__ci_bb_99 {
        goto '__ci_bb_107
    }

    '__ci_bb_100 {
        (__local_end_subject__goto_3352_12 = __local_t__goto_3721_18)
        goto '__ci_bb_97
    }

    '__ci_bb_101 {
        (__ci_expr_logic_24 = 0)
        if ((if __local_t__goto_3721_18 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            var __ci_expr_ternary_23: c_int = 0

            if ((if __local_mb__goto_3377_18.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_19: c_int = 0

                if ((if __local_t__goto_3721_18 < __local_mb__goto_3377_18.end_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_19 = (if _pcre2_is_newline_8(__local_t__goto_3721_18, __local_mb__goto_3377_18.nltype, __local_mb__goto_3377_18.end_subject, ((&raw const (unsafe *__local_mb__goto_3377_18).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_3356_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_23 = __ci_expr_logic_19)

            } else {
                var __ci_expr_logic_22: c_int = 0

                var __ci_expr_logic_20: c_int = 0

                if ((if __local_t__goto_3721_18 <= (__local_mb__goto_3377_18.end_subject - (__local_mb__goto_3377_18.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_20 = (if (if (unsafe *__local_t__goto_3721_18) == __local_mb__goto_3377_18.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_20 != 0) {
                    var __ci_expr_logic_21: c_int

                    if ((if __local_mb__goto_3377_18.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_21 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_21 = (if (if (unsafe *(__local_t__goto_3721_18 + ((1 as isize) as usize))) == __local_mb__goto_3377_18.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_23 = __ci_expr_logic_22)

            }

            (__ci_expr_logic_24 = (if (if not (__ci_expr_ternary_23 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_102 {
        (__local_t__goto_3721_18 = __local_t__goto_3721_18 + 1)
        goto '__ci_bb_104
    }

    '__ci_bb_103 {
        goto '__ci_bb_100
    }

    '__ci_bb_104 {
        (__ci_expr_logic_25 = 0)
        if ((if __local_t__goto_3721_18 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if (if ((((unsafe *__local_t__goto_3721_18) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_105 {
        (__local_t__goto_3721_18 = __local_t__goto_3721_18 + 1)
        goto '__ci_bb_104
    }

    '__ci_bb_106 {
        goto '__ci_bb_101
    }

    '__ci_bb_107 {
        (__ci_expr_logic_31 = 0)
        if ((if __local_t__goto_3721_18 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            var __ci_expr_ternary_30: c_int = 0

            if ((if __local_mb__goto_3377_18.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_26: c_int = 0

                if ((if __local_t__goto_3721_18 < __local_mb__goto_3377_18.end_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_26 = (if _pcre2_is_newline_8(__local_t__goto_3721_18, __local_mb__goto_3377_18.nltype, __local_mb__goto_3377_18.end_subject, ((&raw const (unsafe *__local_mb__goto_3377_18).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_3356_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_30 = __ci_expr_logic_26)

            } else {
                var __ci_expr_logic_29: c_int = 0

                var __ci_expr_logic_27: c_int = 0

                if ((if __local_t__goto_3721_18 <= (__local_mb__goto_3377_18.end_subject - (__local_mb__goto_3377_18.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_27 = (if (if (unsafe *__local_t__goto_3721_18) == __local_mb__goto_3377_18.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_27 != 0) {
                    var __ci_expr_logic_28: c_int

                    if ((if __local_mb__goto_3377_18.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_28 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_28 = (if (if (unsafe *(__local_t__goto_3721_18 + ((1 as isize) as usize))) == __local_mb__goto_3377_18.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_30 = __ci_expr_logic_29)

            }

            (__ci_expr_logic_31 = (if (if not (__ci_expr_ternary_30 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_108 {
        (__local_t__goto_3721_18 = __local_t__goto_3721_18 + 1)
        goto '__ci_bb_107
    }

    '__ci_bb_109 {
        goto '__ci_bb_100
    }

    '__ci_bb_110 {
        if (__local_has_first_cu__goto_3357_6 != 0) {
            (__ci_expr_logic_32 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_32 = (if (if __local_start_bits__goto_3370_16 != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_111 {
        if (__local_has_first_cu__goto_3357_6 != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_112 {
        (__local_end_subject__goto_3352_12 = __local_mb__goto_3377_18.end_subject)
        if ((if ((__local_mb__goto_3377_18.moptions as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_169
        }
    }

    '__ci_bb_113 {
        (__local_ok__goto_3745_14 = (if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0))
        if (__local_ok__goto_3745_14 != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_114 {
        goto '__ci_bb_112
    }

    '__ci_bb_115 {
        (__local_c__goto_3748_23 = (unsafe *__local_start_match__goto_3351_12))
        (__ci_expr_logic_34 = 0)
        if (__local_has_first_cu__goto_3357_6 != 0) {
            var __ci_expr_logic_33: c_int

            if ((if __local_c__goto_3748_23 == __local_first_cu__goto_3365_13: 1 else: 0) != 0) {
                (__ci_expr_logic_33 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_33 = (if (if __local_c__goto_3748_23 == __local_first_cu2__goto_3366_13: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_34 = (if __ci_expr_logic_33 != 0: 1 else: 0))

        }
        (__local_ok__goto_3745_14 = __ci_expr_logic_34)
        (__ci_expr_logic_35 = 0)
        if ((if not (__local_ok__goto_3745_14 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_35 = (if (if __local_start_bits__goto_3370_16 != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_35 != 0) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_118
        }
    }

    '__ci_bb_116 {
        if ((if not (__local_ok__goto_3745_14 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_117 {
        (__local_ok__goto_3745_14 = (if ((((unsafe __local_start_bits__goto_3370_16[((__local_c__goto_3748_23 as c_int) / 8)]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_c__goto_3748_23 as c_int) & 7) as c_uint)) as c_uint)) != 0: 1 else: 0))
        goto '__ci_bb_118
    }

    '__ci_bb_118 {
        goto '__ci_bb_116
    }

    '__ci_bb_119 {
        goto '__ci_bb_93
    }

    '__ci_bb_120 {
        goto '__ci_bb_114
    }

    '__ci_bb_121 {
        if ((if __local_first_cu__goto_3365_13 != __local_first_cu2__goto_3366_13: 1 else: 0) != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_122 {
        if (__local_startline__goto_3356_21 != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_123 {
        goto '__ci_bb_112
    }

    '__ci_bb_124 {
        (__local_pp1__goto_3787_22 = null)
        (__local_pp2__goto_3788_22 = null)
        (__local_searchlength__goto_3789_22 = ((__local_end_subject__goto_3352_12 as usize) -% (__local_start_match__goto_3351_12 as usize)) / sizeof[u8]())
        if ((if __local_memchr_found_first_cu__goto_3361_12 == null: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_36 = (if (if __local_start_match__goto_3351_12 > __local_memchr_found_first_cu__goto_3361_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_125 {
        (__local_start_match__goto_3351_12 = ((memchr((__local_start_match__goto_3351_12 as *mut c_void), __local_first_cu__goto_3365_13, (((__local_end_subject__goto_3352_12 as usize) -% (__local_start_match__goto_3351_12 as usize)) / sizeof[u8]())) as *const u8)))
        if ((if __local_start_match__goto_3351_12 == null: 1 else: 0) != 0) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_126 {
        (__ci_expr_logic_45 = 0)
        if ((if ((__local_mb__goto_3377_18.moptions as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_45 = (if (if __local_start_match__goto_3351_12 >= __local_mb__goto_3377_18.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_45 != 0) {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_127 {
        (__local_pp1__goto_3787_22 = ((memchr((__local_start_match__goto_3351_12 as *mut c_void), __local_first_cu__goto_3365_13, __local_searchlength__goto_3789_22) as *const u8)))
        (__ci_expr_ternary_37 = null)
        if ((if __local_pp1__goto_3787_22 == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_37 = __local_end_subject__goto_3352_12)
        } else {
            (__ci_expr_ternary_37 = __local_pp1__goto_3787_22)
        }
        (__local_memchr_found_first_cu__goto_3361_12 = __ci_expr_ternary_37)
        goto '__ci_bb_129
    }

    '__ci_bb_128 {
        (__ci_expr_ternary_38 = null)
        if ((if __local_memchr_found_first_cu__goto_3361_12 == __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            (__ci_expr_ternary_38 = null)
        } else {
            (__ci_expr_ternary_38 = __local_memchr_found_first_cu__goto_3361_12)
        }
        (__local_pp1__goto_3787_22 = __ci_expr_ternary_38)
        goto '__ci_bb_129
    }

    '__ci_bb_129 {
        if ((if __local_memchr_found_first_cu2__goto_3362_12 == null: 1 else: 0) != 0) {
            (__ci_expr_logic_39 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_39 = (if (if __local_start_match__goto_3351_12 > __local_memchr_found_first_cu2__goto_3362_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_39 != 0) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_130 {
        (__local_pp2__goto_3788_22 = ((memchr((__local_start_match__goto_3351_12 as *mut c_void), __local_first_cu2__goto_3366_13, __local_searchlength__goto_3789_22) as *const u8)))
        (__ci_expr_ternary_40 = null)
        if ((if __local_pp2__goto_3788_22 == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_40 = __local_end_subject__goto_3352_12)
        } else {
            (__ci_expr_ternary_40 = __local_pp2__goto_3788_22)
        }
        (__local_memchr_found_first_cu2__goto_3362_12 = __ci_expr_ternary_40)
        goto '__ci_bb_132
    }

    '__ci_bb_131 {
        (__ci_expr_ternary_41 = null)
        if ((if __local_memchr_found_first_cu2__goto_3362_12 == __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            (__ci_expr_ternary_41 = null)
        } else {
            (__ci_expr_ternary_41 = __local_memchr_found_first_cu2__goto_3362_12)
        }
        (__local_pp2__goto_3788_22 = __ci_expr_ternary_41)
        goto '__ci_bb_132
    }

    '__ci_bb_132 {
        if ((if __local_pp1__goto_3787_22 == null: 1 else: 0) != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_133 {
        (__ci_expr_ternary_42 = null)
        if ((if __local_pp2__goto_3788_22 == null: 1 else: 0) != 0) {
            (__ci_expr_ternary_42 = __local_end_subject__goto_3352_12)
        } else {
            (__ci_expr_ternary_42 = __local_pp2__goto_3788_22)
        }
        (__local_start_match__goto_3351_12 = __ci_expr_ternary_42)
        goto '__ci_bb_135
    }

    '__ci_bb_134 {
        (__ci_expr_ternary_44 = null)
        if ((if __local_pp2__goto_3788_22 == null: 1 else: 0) != 0) {
            (__ci_expr_logic_43 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_43 = (if (if __local_pp1__goto_3787_22 < __local_pp2__goto_3788_22: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_43 != 0) {
            (__ci_expr_ternary_44 = __local_pp1__goto_3787_22)
        } else {
            (__ci_expr_ternary_44 = __local_pp2__goto_3788_22)
        }
        (__local_start_match__goto_3351_12 = __ci_expr_ternary_44)
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        goto '__ci_bb_126
    }

    '__ci_bb_136 {
        (__local_start_match__goto_3351_12 = __local_end_subject__goto_3352_12)
        goto '__ci_bb_137
    }

    '__ci_bb_137 {
        goto '__ci_bb_126
    }

    '__ci_bb_138 {
        goto '__ci_bb_93
    }

    '__ci_bb_139 {
        goto '__ci_bb_123
    }

    '__ci_bb_140 {
        if ((if __local_start_match__goto_3351_12 > (__local_mb__goto_3377_18.start_subject + (__param_start_offset as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_143
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_141 {
        if ((if __local_start_bits__goto_3370_16 != null: 1 else: 0) != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_142 {
        goto '__ci_bb_123
    }

    '__ci_bb_143 {
        if (__local_utf__goto_3356_6 != 0) {
            goto '__ci_bb_145
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_144 {
        goto '__ci_bb_142
    }

    '__ci_bb_145 {
        goto '__ci_bb_148
    }

    '__ci_bb_146 {
        goto '__ci_bb_154
    }

    '__ci_bb_147 {
        (__ci_expr_logic_62 = 0)
        (__ci_expr_logic_61 = 0)
        (__ci_expr_logic_60 = 0)
        if ((if (unsafe __local_start_match__goto_3351_12[-1]) == 13: 1 else: 0) != 0) {
            var __ci_expr_logic_59: c_int

            if ((if __local_mb__goto_3377_18.nltype == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_59 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_59 = (if (if __local_mb__goto_3377_18.nltype == 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_60 = (if __ci_expr_logic_59 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_60 != 0) {
            (__ci_expr_logic_61 = (if (if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_61 != 0) {
            (__ci_expr_logic_62 = (if (if (unsafe *__local_start_match__goto_3351_12) == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_62 != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_148 {
        (__ci_expr_logic_51 = 0)
        if ((if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            var __ci_expr_ternary_50: c_int = 0

            if ((if __local_mb__goto_3377_18.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_46: c_int = 0

                if ((if __local_start_match__goto_3351_12 > __local_mb__goto_3377_18.start_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_46 = (if _pcre2_was_newline_8(__local_start_match__goto_3351_12, __local_mb__goto_3377_18.nltype, __local_mb__goto_3377_18.start_subject, ((&raw const (unsafe *__local_mb__goto_3377_18).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_3356_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_50 = __ci_expr_logic_46)

            } else {
                var __ci_expr_logic_49: c_int = 0

                var __ci_expr_logic_47: c_int = 0

                if ((if __local_start_match__goto_3351_12 >= (__local_mb__goto_3377_18.start_subject + (__local_mb__goto_3377_18.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_47 = (if (if (unsafe *(__local_start_match__goto_3351_12 - (__local_mb__goto_3377_18.nllen as usize))) == __local_mb__goto_3377_18.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_47 != 0) {
                    var __ci_expr_logic_48: c_int

                    if ((if __local_mb__goto_3377_18.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_48 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_48 = (if (if (unsafe *((__local_start_match__goto_3351_12 - (__local_mb__goto_3377_18.nllen as usize)) + ((1 as isize) as usize))) == __local_mb__goto_3377_18.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_49 = (if __ci_expr_logic_48 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_50 = __ci_expr_logic_49)

            }

            (__ci_expr_logic_51 = (if (if not (__ci_expr_ternary_50 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_51 != 0) {
            goto '__ci_bb_149
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_149 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_151
    }

    '__ci_bb_150 {
        goto '__ci_bb_147
    }

    '__ci_bb_151 {
        (__ci_expr_logic_52 = 0)
        if ((if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            (__ci_expr_logic_52 = (if (if ((((unsafe *__local_start_match__goto_3351_12) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_52 != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_152 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_151
    }

    '__ci_bb_153 {
        goto '__ci_bb_148
    }

    '__ci_bb_154 {
        (__ci_expr_logic_58 = 0)
        if ((if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            var __ci_expr_ternary_57: c_int = 0

            if ((if __local_mb__goto_3377_18.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_53: c_int = 0

                if ((if __local_start_match__goto_3351_12 > __local_mb__goto_3377_18.start_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_53 = (if _pcre2_was_newline_8(__local_start_match__goto_3351_12, __local_mb__goto_3377_18.nltype, __local_mb__goto_3377_18.start_subject, ((&raw const (unsafe *__local_mb__goto_3377_18).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_3356_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_57 = __ci_expr_logic_53)

            } else {
                var __ci_expr_logic_56: c_int = 0

                var __ci_expr_logic_54: c_int = 0

                if ((if __local_start_match__goto_3351_12 >= (__local_mb__goto_3377_18.start_subject + (__local_mb__goto_3377_18.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_54 = (if (if (unsafe *(__local_start_match__goto_3351_12 - (__local_mb__goto_3377_18.nllen as usize))) == __local_mb__goto_3377_18.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_54 != 0) {
                    var __ci_expr_logic_55: c_int

                    if ((if __local_mb__goto_3377_18.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_55 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_55 = (if (if (unsafe *((__local_start_match__goto_3351_12 - (__local_mb__goto_3377_18.nllen as usize)) + ((1 as isize) as usize))) == __local_mb__goto_3377_18.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_56 = (if __ci_expr_logic_55 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_57 = __ci_expr_logic_56)

            }

            (__ci_expr_logic_58 = (if (if not (__ci_expr_ternary_57 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_58 != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_155 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_154
    }

    '__ci_bb_156 {
        goto '__ci_bb_147
    }

    '__ci_bb_157 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_158
    }

    '__ci_bb_158 {
        goto '__ci_bb_144
    }

    '__ci_bb_159 {
        goto '__ci_bb_161
    }

    '__ci_bb_160 {
        goto '__ci_bb_142
    }

    '__ci_bb_161 {
        if ((if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_162 {
        (__local_c__goto_3902_20 = (unsafe *__local_start_match__goto_3351_12))
        if ((if ((((unsafe __local_start_bits__goto_3370_16[((__local_c__goto_3902_20 as c_uint) / (8 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_c__goto_3902_20 as c_uint) & (7 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_163 {
        (__ci_expr_logic_63 = 0)
        if ((if ((__local_mb__goto_3377_18.moptions as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_63 = (if (if __local_start_match__goto_3351_12 >= __local_mb__goto_3377_18.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_63 != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_164 {
        goto '__ci_bb_163
    }

    '__ci_bb_165 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_161
    }

    '__ci_bb_166 {
        goto '__ci_bb_93
    }

    '__ci_bb_167 {
        goto '__ci_bb_160
    }

    '__ci_bb_168 {
        if ((if (((__local_end_subject__goto_3352_12 as usize) -% (__local_start_match__goto_3351_12 as usize)) / sizeof[u8]()) < __local_re__goto_3346_24.minlength: 1 else: 0) != 0) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_169 {
        goto '__ci_bb_95
    }

    '__ci_bb_170 {
        goto '__ci_bb_172
    }

    '__ci_bb_171 {
        (__ci_expr_ternary_64 = 0)
        if (__local_has_first_cu__goto_3357_6 != 0) {
            (__ci_expr_ternary_64 = 1)
        } else {
            (__ci_expr_ternary_64 = 0)
        }
        (__local_p__goto_3926_18 = __local_start_match__goto_3351_12 + ((__ci_expr_ternary_64 as isize) as usize))
        (__ci_expr_logic_65 = 0)
        if (__local_has_req_cu__goto_3358_6 != 0) {
            (__ci_expr_logic_65 = (if (if __local_p__goto_3926_18 > __local_req_cu_ptr__goto_3354_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_65 != 0) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_172 {
        ((unsafe *__param_match_data).subject = __local_original_subject__goto_3350_12)
        ((unsafe *__param_match_data).subject_length = __local_length)
        ((unsafe *__param_match_data).start_offset = __param_start_offset)
        (__local_rc__goto_3344_5 = -1)
        goto '__ci_bb_7
    }

    '__ci_bb_173 {
        (__local_check_length__goto_3960_20 = ((__local_end_subject__goto_3352_12 as usize) -% (__local_start_match__goto_3351_12 as usize)) / sizeof[u8]())
        if ((if __local_check_length__goto_3960_20 < 5000: 1 else: 0) != 0) {
            (__ci_expr_logic_67 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_66: c_int = 0

            if ((if not (__local_anchored__goto_3356_11 != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_66 = (if (if __local_check_length__goto_3960_20 < 5000000: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_67 = (if __ci_expr_logic_66 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_67 != 0) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_174 {
        goto '__ci_bb_169
    }

    '__ci_bb_175 {
        if ((if __local_req_cu__goto_3367_13 != __local_req_cu2__goto_3368_13: 1 else: 0) != 0) {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_176 {
        goto '__ci_bb_174
    }

    '__ci_bb_177 {
        (__local_pp__goto_3974_24 = __local_p__goto_3926_18)
        (__local_p__goto_3926_18 = ((memchr((__local_pp__goto_3974_24 as *mut c_void), __local_req_cu__goto_3367_13, (((__local_end_subject__goto_3352_12 as usize) -% (__local_pp__goto_3974_24 as usize)) / sizeof[u8]())) as *const u8)))
        if ((if __local_p__goto_3926_18 == null: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_178 {
        (__local_p__goto_3926_18 = ((memchr((__local_p__goto_3926_18 as *mut c_void), __local_req_cu__goto_3367_13, (((__local_end_subject__goto_3352_12 as usize) -% (__local_p__goto_3926_18 as usize)) / sizeof[u8]())) as *const u8)))
        if ((if __local_p__goto_3926_18 == null: 1 else: 0) != 0) {
            goto '__ci_bb_184
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_179 {
        if ((if __local_p__goto_3926_18 >= __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_180 {
        (__local_p__goto_3926_18 = ((memchr((__local_pp__goto_3974_24 as *mut c_void), __local_req_cu2__goto_3368_13, (((__local_end_subject__goto_3352_12 as usize) -% (__local_pp__goto_3974_24 as usize)) / sizeof[u8]())) as *const u8)))
        if ((if __local_p__goto_3926_18 == null: 1 else: 0) != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_181 {
        goto '__ci_bb_179
    }

    '__ci_bb_182 {
        (__local_p__goto_3926_18 = __local_end_subject__goto_3352_12)
        goto '__ci_bb_183
    }

    '__ci_bb_183 {
        goto '__ci_bb_181
    }

    '__ci_bb_184 {
        (__local_p__goto_3926_18 = __local_end_subject__goto_3352_12)
        goto '__ci_bb_185
    }

    '__ci_bb_185 {
        goto '__ci_bb_179
    }

    '__ci_bb_186 {
        goto '__ci_bb_93
    }

    '__ci_bb_187 {
        (__local_req_cu_ptr__goto_3354_12 = __local_p__goto_3926_18)
        goto '__ci_bb_176
    }

    '__ci_bb_188 {
        goto '__ci_bb_93
    }

    '__ci_bb_189 {
        ((unsafe *__local_mb__goto_3377_18).start_used_ptr = __local_start_match__goto_3351_12)
        ((unsafe *__local_mb__goto_3377_18).last_used_ptr = __local_start_match__goto_3351_12)
        ((unsafe *__local_mb__goto_3377_18).recursive = ((null as *mut dfa_recursion_info)))
        (__local_rc__goto_3344_5 = internal_dfa_match(__local_mb__goto_3377_18, __local_mb__goto_3377_18.start_code, __local_start_match__goto_3351_12, __param_start_offset, (&__param_match_data.ovector[0] as *mut c_ulong), (((__param_match_data.oveccount as c_uint) as c_uint) *% (2 as c_uint)), __param_workspace, (__param_wscount as c_int), 0, (&__local_base_recursion_workspace__goto_3384_5[0] as *mut c_int)))
        if ((if __local_rc__goto_3344_5 != -1: 1 else: 0) != 0) {
            (__ci_expr_logic_68 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_68 = (if __local_anchored__goto_3356_11 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_68 != 0) {
            goto '__ci_bb_190
        } else {
            goto '__ci_bb_191
        }
    }

    '__ci_bb_190 {
        if ((if __local_rc__goto_3344_5 == -1: 1 else: 0) != 0) {
            goto '__ci_bb_192
        } else {
            goto '__ci_bb_193
        }
    }

    '__ci_bb_191 {
        (__ci_expr_logic_78 = 0)
        if (__local_firstline__goto_3356_32 != 0) {
            var __ci_expr_ternary_77: c_int = 0

            if ((if __local_mb__goto_3377_18.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_73: c_int = 0

                if ((if __local_start_match__goto_3351_12 < __local_mb__goto_3377_18.end_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_73 = (if _pcre2_is_newline_8(__local_start_match__goto_3351_12, __local_mb__goto_3377_18.nltype, __local_mb__goto_3377_18.end_subject, ((&raw const (unsafe *__local_mb__goto_3377_18).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_3356_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_77 = __ci_expr_logic_73)

            } else {
                var __ci_expr_logic_76: c_int = 0

                var __ci_expr_logic_74: c_int = 0

                if ((if __local_start_match__goto_3351_12 <= (__local_mb__goto_3377_18.end_subject - (__local_mb__goto_3377_18.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_74 = (if (if (unsafe *__local_start_match__goto_3351_12) == __local_mb__goto_3377_18.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_74 != 0) {
                    var __ci_expr_logic_75: c_int

                    if ((if __local_mb__goto_3377_18.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_75 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_75 = (if (if (unsafe *(__local_start_match__goto_3351_12 + ((1 as isize) as usize))) == __local_mb__goto_3377_18.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_76 = (if __ci_expr_logic_75 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_77 = __ci_expr_logic_76)

            }

            (__ci_expr_logic_78 = (if __ci_expr_ternary_77 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_78 != 0) {
            goto '__ci_bb_208
        } else {
            goto '__ci_bb_209
        }
    }

    '__ci_bb_192 {
        goto '__ci_bb_172
    }

    '__ci_bb_193 {
        (__ci_expr_logic_69 = 0)
        if ((if __local_rc__goto_3344_5 == -2: 1 else: 0) != 0) {
            (__ci_expr_logic_69 = (if (if __param_match_data.oveccount > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_69 != 0) {
            goto '__ci_bb_194
        } else {
            goto '__ci_bb_195
        }
    }

    '__ci_bb_194 {
        ((unsafe *__param_match_data).ovector[0] = (((((__local_start_match__goto_3351_12 as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong)))
        ((unsafe *__param_match_data).ovector[1] = (((((__local_end_subject__goto_3352_12 as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong)))
        goto '__ci_bb_195
    }

    '__ci_bb_195 {
        if ((if __local_rc__goto_3344_5 >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_70 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_70 = (if (if __local_rc__goto_3344_5 == -2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_70 != 0) {
            goto '__ci_bb_196
        } else {
            goto '__ci_bb_197
        }
    }

    '__ci_bb_196 {
        ((unsafe *__param_match_data).subject_length = __local_length)
        ((unsafe *__param_match_data).start_offset = __param_start_offset)
        ((unsafe *__param_match_data).leftchar = (((((__local_mb__goto_3377_18.start_used_ptr as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong)))
        ((unsafe *__param_match_data).rightchar = (((((__local_mb__goto_3377_18.last_used_ptr as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong)))
        ((unsafe *__param_match_data).startchar = (((((__local_start_match__goto_3351_12 as usize) -% (__local_subject as usize)) / sizeof[u8]()) as c_ulong)))
        goto '__ci_bb_197
    }

    '__ci_bb_197 {
        (__ci_expr_logic_71 = 0)
        if ((if __local_rc__goto_3344_5 >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_71 = (if (if ((__local_options as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_71 != 0) {
            goto '__ci_bb_198
        } else {
            goto '__ci_bb_199
        }
    }

    '__ci_bb_198 {
        if ((if __local_length != 0: 1 else: 0) != 0) {
            goto '__ci_bb_201
        } else {
            goto '__ci_bb_202
        }
    }

    '__ci_bb_199 {
        if ((if __local_rc__goto_3344_5 >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_72 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_72 = (if (if __local_rc__goto_3344_5 == -2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_72 != 0) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_207
        }
    }

    '__ci_bb_200 {
        goto '__ci_bb_7
    }

    '__ci_bb_201 {
        ((unsafe *__param_match_data).subject = (&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl).malloc(((__local_length as c_ulong) *% (1 as c_ulong)), (&raw const (unsafe *__param_match_data).memctl as *const pcre2_memctl).memory_data))
        if ((if __param_match_data.subject == null: 1 else: 0) != 0) {
            goto '__ci_bb_204
        } else {
            goto '__ci_bb_205
        }
    }

    '__ci_bb_202 {
        ((unsafe *__param_match_data).subject = null)
        goto '__ci_bb_203
    }

    '__ci_bb_203 {
        ((unsafe *__param_match_data).flags = __param_match_data.flags | 1)
        goto '__ci_bb_200
    }

    '__ci_bb_204 {
        (__local_rc__goto_3344_5 = -48)
        goto '__ci_bb_7
    }

    '__ci_bb_205 {
        with_memcpy(((__param_match_data.subject as *mut c_void) as *i8), (__local_subject as *i8), (((__local_length as c_ulong) *% (1 as c_ulong)) as i64))
        goto '__ci_bb_203
    }

    '__ci_bb_206 {
        ((unsafe *__param_match_data).subject = __local_original_subject__goto_3350_12)
        goto '__ci_bb_207
    }

    '__ci_bb_207 {
        goto '__ci_bb_200
    }

    '__ci_bb_208 {
        goto '__ci_bb_93
    }

    '__ci_bb_209 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        if (__local_utf__goto_3356_6 != 0) {
            goto '__ci_bb_210
        } else {
            goto '__ci_bb_211
        }
    }

    '__ci_bb_210 {
        goto '__ci_bb_212
    }

    '__ci_bb_211 {
        if ((if __local_start_match__goto_3351_12 > __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_212 {
        (__ci_expr_logic_79 = 0)
        if ((if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0) {
            (__ci_expr_logic_79 = (if (if ((((unsafe *__local_start_match__goto_3351_12) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_79 != 0) {
            goto '__ci_bb_213
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_213 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_212
    }

    '__ci_bb_214 {
        goto '__ci_bb_211
    }

    '__ci_bb_215 {
        goto '__ci_bb_93
    }

    '__ci_bb_216 {
        (__ci_expr_logic_85 = 0)
        (__ci_expr_logic_82 = 0)
        (__ci_expr_logic_81 = 0)
        (__ci_expr_logic_80 = 0)
        if ((if (unsafe *(__local_start_match__goto_3351_12 - ((1 as isize) as usize))) == 13: 1 else: 0) != 0) {
            (__ci_expr_logic_80 = (if (if __local_start_match__goto_3351_12 < __local_end_subject__goto_3352_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_80 != 0) {
            (__ci_expr_logic_81 = (if (if (unsafe *__local_start_match__goto_3351_12) == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_81 != 0) {
            (__ci_expr_logic_82 = (if (if ((__local_re__goto_3346_24.flags as c_uint) & (2048 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_82 != 0) {
            var __ci_expr_logic_84: c_int

            var __ci_expr_logic_83: c_int

            if ((if __local_mb__goto_3377_18.nltype == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_83 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_83 = (if (if __local_mb__goto_3377_18.nltype == 2: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_83 != 0) {
                (__ci_expr_logic_84 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_84 = (if (if __local_mb__goto_3377_18.nllen == 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_85 = (if __ci_expr_logic_84 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_85 != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_217 {
        (__local_start_match__goto_3351_12 = __local_start_match__goto_3351_12 + 1)
        goto '__ci_bb_218
    }

    '__ci_bb_218 {
        goto '__ci_bb_92
    }

    '__ci_bb_219 {
        if ((if __local_rws__goto_3385_13.next != null: 1 else: 0) != 0) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_220 {
        (__local_next__goto_4119_15 = __local_rws__goto_3385_13.next)
        ((unsafe *__local_rws__goto_3385_13).next = __local_next__goto_4119_15.next)
        (&raw const (unsafe *__local_mb__goto_3377_18).memctl as *const pcre2_memctl).free(__local_next__goto_4119_15, (&raw const (unsafe *__local_mb__goto_3377_18).memctl as *const pcre2_memctl).memory_data)
        goto '__ci_bb_219
    }

    '__ci_bb_221 {
        ((unsafe *__param_match_data).rc = __local_rc__goto_3344_5)
        return __local_rc__goto_3344_5
    }

}

fn do_callout_dfa(__param_code: *const u8, __param_offsets: *mut c_ulong, __param_current_subject: *const u8, __param_ptr: *const u8, __param_mb: *mut dfa_match_block_8, __param_extracode: c_ulong, __param_lengthptr: *mut c_ulong) -> c_int {
    var __local_cb: *mut pcre2_callout_block_8 = __param_mb.cb

    var __ci_expr_ternary_0: c_ulong = 0

    if ((if (unsafe __param_code[__param_extracode]) == OP_CALLOUT: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((_pcre2_OP_lengths_8[OP_CALLOUT] as c_ulong)))
    } else {
        (__ci_expr_ternary_0 = (((((((unsafe __param_code[((5 as c_ulong) +% (__param_extracode as c_ulong))]) as c_int) << (8 as c_uint)) | ((unsafe __param_code[((((5 as c_ulong) +% (__param_extracode as c_ulong)) as c_ulong) +% (1 as c_ulong))]) as c_int)) as c_uint) as c_ulong)))
    }

    ((unsafe *__param_lengthptr) = __ci_expr_ternary_0)


    if ((if __param_mb.callout == null: 1 else: 0) != 0) {
        return 0
    }

    ((unsafe *__local_cb).offset_vector = __param_offsets)

    ((unsafe *__local_cb).start_match = (((((__param_current_subject as usize) -% (__param_mb.start_subject as usize)) / sizeof[u8]()) as c_ulong)))

    ((unsafe *__local_cb).current_position = (((((__param_ptr as usize) -% (__param_mb.start_subject as usize)) / sizeof[u8]()) as c_ulong)))

    ((unsafe *__local_cb).pattern_position = ((((((unsafe __param_code[((1 as c_ulong) +% (__param_extracode as c_ulong))]) as c_int) << (8 as c_uint)) | ((unsafe __param_code[((((1 as c_ulong) +% (__param_extracode as c_ulong)) as c_ulong) +% (1 as c_ulong))]) as c_int)) as c_uint)))

    ((unsafe *__local_cb).next_item_length = ((((((unsafe __param_code[((3 as c_ulong) +% (__param_extracode as c_ulong))]) as c_int) << (8 as c_uint)) | ((unsafe __param_code[((((3 as c_ulong) +% (__param_extracode as c_ulong)) as c_ulong) +% (1 as c_ulong))]) as c_int)) as c_uint)))

    if ((if (unsafe __param_code[__param_extracode]) == OP_CALLOUT: 1 else: 0) != 0) {
        ((unsafe *__local_cb).callout_number = (unsafe __param_code[((5 as c_ulong) +% (__param_extracode as c_ulong))]))

        ((unsafe *__local_cb).callout_string_offset = 0)

        ((unsafe *__local_cb).callout_string = null)

        ((unsafe *__local_cb).callout_string_length = 0)

    } else {
        ((unsafe *__local_cb).callout_number = 0)

        ((unsafe *__local_cb).callout_string_offset = ((((((unsafe __param_code[((7 as c_ulong) +% (__param_extracode as c_ulong))]) as c_int) << (8 as c_uint)) | ((unsafe __param_code[((((7 as c_ulong) +% (__param_extracode as c_ulong)) as c_ulong) +% (1 as c_ulong))]) as c_int)) as c_uint)))

        ((unsafe *__local_cb).callout_string = (__param_code + (((9 as c_ulong) +% (__param_extracode as c_ulong)) as usize)) + ((1 as isize) as usize))

        ((unsafe *__local_cb).callout_string_length = (((((unsafe *__param_lengthptr) as c_ulong) -% (9 as c_ulong)) as c_ulong) -% (2 as c_ulong)))

    }

    return __param_mb.callout(__local_cb, __param_mb.callout_data)

}

fn more_workspace(__param_rwsptr: *mut *mut RWS_anchor, __param_ovecsize: c_uint, __param_mb: *mut dfa_match_block_8) -> c_int {
    var __local_rws: *mut RWS_anchor = (unsafe *__param_rwsptr)

    var __local_new: *mut RWS_anchor

    if ((if __local_rws.next != null: 1 else: 0) != 0) {
        (__local_new = __local_rws.next)

    } else {
        var __local_newsize: c_uint = with 0 as __ci_expr_seq_13 {
            var __ci_expr_ternary_0: c_ulong = 0
            if ((if __local_rws.size >= ((4294967295 as c_ulong) / (((sizeof[c_int]() as c_ulong) *% (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
                (__ci_expr_ternary_0 = (4294967295 as c_ulong) / (sizeof[c_int]() as c_ulong))
            } else {
                (__ci_expr_ternary_0 = ((__local_rws.size as c_uint) *% (2 as c_uint)))
            }
            __ci_expr_ternary_0 as c_uint
        }

        var __local_newsizeK: c_uint = (((__local_newsize as c_ulong) / (((1024 as c_ulong) / (sizeof[c_int]() as c_ulong)) as c_ulong))) as c_uint

        if ((if ((__local_newsizeK as c_ulong) +% (__param_mb.heap_used as c_ulong)) > __param_mb.heap_limit: 1 else: 0) != 0) {
            (__local_newsizeK = ((((__param_mb.heap_limit as c_ulong) -% (__param_mb.heap_used as c_ulong)) as c_uint)))
        }

        (__local_newsize = ((__local_newsizeK as c_ulong) *% (((1024 as c_ulong) / (sizeof[c_int]() as c_ulong)) as c_ulong)))

        if ((if __local_newsize < ((((1000 as c_uint) +% (__param_ovecsize as c_uint)) as c_ulong) +% (4 as c_ulong)): 1 else: 0) != 0) {
            return -63
        }

        (__local_new = (((&raw const (unsafe *__param_mb).memctl as *const pcre2_memctl).malloc(((__local_newsize as c_ulong) *% (sizeof[c_int]() as c_ulong)), (&raw const (unsafe *__param_mb).memctl as *const pcre2_memctl).memory_data) as *mut RWS_anchor)))

        if ((if __local_new == null: 1 else: 0) != 0) {
            return -48
        }

        ((unsafe *__param_mb).heap_used = __param_mb.heap_used + __local_newsizeK)

        ((unsafe *__local_new).next = ((null as *mut RWS_anchor)))

        ((unsafe *__local_new).size = __local_newsize)

        ((unsafe *__local_rws).next = __local_new)

    }

    ((unsafe *__local_new).free = ((__local_new.size as c_ulong) -% (4 as c_ulong)))

    ((unsafe *__param_rwsptr) = __local_new)

    return 0

}

fn internal_dfa_match(__param_mb: *mut dfa_match_block_8, __param_this_start_code: *const u8, __param_current_subject: *const u8, __param_start_offset: c_ulong, __param_offsets: *mut c_ulong, __param_offsetcount: c_uint, __param_workspace: *mut c_int, __param_wscount: c_int, __param_rlevel: c_uint, __param_RWS: *mut c_int) -> c_int {
    var __local_current_subject = __param_current_subject
    var __local_offsetcount = __param_offsetcount
    var __local_wscount = __param_wscount
    var __local_rlevel = __param_rlevel
    var __local_RWS = __param_RWS
    var __local_active_states__goto_542_13: *mut stateblock = null

    var __local_new_states__goto_542_29: *mut stateblock = null

    var __local_temp_states__goto_542_42: *mut stateblock = null

    var __local_next_active_state__goto_543_13: *mut stateblock = null

    var __local_next_new_state__goto_543_33: *mut stateblock = null

    var __local_ctypes__goto_544_16: *const u8 = null

    var __local_lcc__goto_544_25: *const u8 = null

    var __local_fcc__goto_544_31: *const u8 = null

    var __local_ptr__goto_545_12: *const u8 = null

    var __local_end_code__goto_546_12: *const u8 = null

    var __local_new_recursive__goto_547_20: dfa_recursion_info

    var __local_active_count__goto_548_5: c_int = 0

    var __local_new_count__goto_548_19: c_int = 0

    var __local_match_count__goto_548_30: c_int = 0

    var __local_start_subject__goto_553_12: *const u8 = null

    var __local_end_subject__goto_554_12: *const u8 = null

    var __local_start_code__goto_555_12: *const u8 = null

    var __local_utf__goto_558_6: c_int = 0

    var __local_utf_or_ucp__goto_559_6: c_int = 0

    var __local_reset_could_continue__goto_564_6: c_int = 0

    var __local_max_back__goto_594_10: c_ulong = 0

    var __local_gone_back__goto_595_10: c_ulong = 0

    var __local_back__goto_600_12: c_ulong = 0

    var __local_current_offset__goto_628_12: c_ulong = 0

    var __local_revlen__goto_644_14: c_uint = 0

    var __local_back__goto_645_12: c_ulong = 0

    var __local_bstate__goto_648_11: c_int = 0

    var __local_length__goto_680_9: c_int = 0

    var __local_i__goto_701_7: c_int = 0

    var __local_j__goto_701_10: c_int = 0

    var __local_clen__goto_702_7: c_int = 0

    var __local_dlen__goto_702_13: c_int = 0

    var __local_c__goto_703_12: c_uint = 0

    var __local_d__goto_703_15: c_uint = 0

    var __local_partial_newline__goto_704_8: c_int = 0

    var __local_could_continue__goto_705_8: c_int = 0

    var __local_current_state__goto_753_17: *mut stateblock = null

    var __local_caseless__goto_754_10: c_int = 0

    var __local_code__goto_755_16: *const u8 = null

    var __local_codevalue__goto_756_14: c_uint = 0

    var __local_state_offset__goto_757_9: c_int = 0

    var __local_rrc__goto_758_9: c_int = 0

    var __local_count__goto_759_9: c_int = 0

    var __local_left_word__goto_1100_13: c_int = 0

    var __local_right_word__goto_1100_24: c_int = 0

    var __local_temp__goto_1104_22: *const u8 = null

    var __local_chartype__goto_1114_17: c_int = 0

    var __local_category__goto_1115_17: c_int = 0

    var __local_temp__goto_1129_24: *const u8 = null

    var __local_chartype__goto_1139_17: c_int = 0

    var __local_category__goto_1140_17: c_int = 0

    var __local_OK__goto_1168_14: c_int = 0

    var __local_chartype__goto_1169_13: c_int = 0

    var __local_cp__goto_1170_25: *const c_uint = null

    var __local_prop__goto_1171_28: *const ucd_record = null

    var __local_OK__goto_1447_14: c_int = 0

    var __local_chartype__goto_1448_13: c_int = 0

    var __local_cp__goto_1449_25: *const c_uint = null

    var __local_prop__goto_1450_28: *const ucd_record = null

    var __local_ncount__goto_1568_13: c_int = 0

    var __local_ncount__goto_1590_13: c_int = 0

    var __local_OK__goto_1632_14: c_int = 0

    var __local_OK__goto_1665_14: c_int = 0

    var __local_OK__goto_1708_14: c_int = 0

    var __local_chartype__goto_1709_13: c_int = 0

    var __local_cp__goto_1710_25: *const c_uint = null

    var __local_prop__goto_1711_28: *const ucd_record = null

    var __local_ncount__goto_1838_13: c_int = 0

    var __local_ncount__goto_1868_13: c_int = 0

    var __local_OK__goto_1918_14: c_int = 0

    var __local_OK__goto_1958_14: c_int = 0

    var __local_OK__goto_1994_14: c_int = 0

    var __local_chartype__goto_1995_13: c_int = 0

    var __local_cp__goto_1996_25: *const c_uint = null

    var __local_prop__goto_1997_28: *const ucd_record = null

    var __local_nptr__goto_2120_20: *const u8 = null

    var __local_ncount__goto_2121_13: c_int = 0

    var __local_ncount__goto_2149_13: c_int = 0

    var __local_OK__goto_2195_14: c_int = 0

    var __local_OK__goto_2231_14: c_int = 0

    var __local_othercase__goto_2278_24: c_uint = 0

    var __local_ncount__goto_2305_13: c_int = 0

    var __local_nptr__goto_2306_20: *const u8 = null

    var __local_otherd__goto_2421_18: c_uint = 0

    var __local_otherd__goto_2454_18: c_uint = 0

    var __local_otherd__goto_2497_18: c_uint = 0

    var __local_otherd__goto_2538_18: c_uint = 0

    var __local_otherd__goto_2571_18: c_uint = 0

    var __local_otherd__goto_2611_18: c_uint = 0

    var __local_isinclass__goto_2647_14: c_int = 0

    var __local_next_state_offset__goto_2648_13: c_int = 0

    var __local_ecode__goto_2649_20: *const u8 = null

    var __local_max__goto_2753_17: c_int = 0

    var __local_rc__goto_2789_13: c_int = 0

    var __local_local_workspace__goto_2790_14: *mut c_int = null

    var __local_local_offsets__goto_2791_21: *mut c_ulong = null

    var __local_endasscode__goto_2792_20: *const u8 = null

    var __local_rws__goto_2793_21: *mut RWS_anchor = null

    var __local_codelink__goto_2832_13: c_int = 0

    var __local_condcode__goto_2833_21: u8 = 0

    var __local_callout_length__goto_2842_22: c_ulong = 0

    var __local_value__goto_2876_24: c_uint = 0

    var __local_rc__goto_2887_15: c_int = 0

    var __local_local_workspace__goto_2888_16: *mut c_int = null

    var __local_local_offsets__goto_2889_23: *mut c_ulong = null

    var __local_asscode__goto_2890_22: *const u8 = null

    var __local_endasscode__goto_2891_22: *const u8 = null

    var __local_rws__goto_2892_23: *mut RWS_anchor = null

    var __local_rc__goto_2934_13: c_int = 0

    var __local_local_workspace__goto_2935_14: *mut c_int = null

    var __local_local_offsets__goto_2936_21: *mut c_ulong = null

    var __local_rws__goto_2937_21: *mut RWS_anchor = null

    var __local_callpat__goto_2938_20: *const u8 = null

    var __local_recno__goto_2939_18: c_uint = 0

    var __local_ri__goto_2960_34: *mut dfa_recursion_info = null

    var __local_charcount__goto_3005_24: c_ulong = 0

    var __local_p__goto_3009_26: *const u8 = null

    var __local_pp__goto_3010_26: *const u8 = null

    var __local_rc__goto_3036_13: c_int = 0

    var __local_local_workspace__goto_3037_14: *mut c_int = null

    var __local_local_offsets__goto_3038_21: *mut c_ulong = null

    var __local_charcount__goto_3039_20: c_ulong = 0

    var __local_matched_count__goto_3039_31: c_ulong = 0

    var __local_local_ptr__goto_3040_20: *const u8 = null

    var __local_rws__goto_3041_21: *mut RWS_anchor = null

    var __local_allow_zero__goto_3042_14: c_int = 0

    var __local_end_subpattern__goto_3102_22: *const u8 = null

    var __local_next_state_offset__goto_3103_15: c_int = 0

    var __local_p__goto_3123_24: *const u8 = null

    var __local_pp__goto_3124_24: *const u8 = null

    var __local_rc__goto_3138_13: c_int = 0

    var __local_local_workspace__goto_3139_14: *mut c_int = null

    var __local_local_offsets__goto_3140_21: *mut c_ulong = null

    var __local_rws__goto_3141_21: *mut RWS_anchor = null

    var __local_end_subpattern__goto_3170_22: *const u8 = null

    var __local_charcount__goto_3171_22: c_ulong = 0

    var __local_next_state_offset__goto_3172_15: c_int = 0

    var __local_repeat_state_offset__goto_3172_34: c_int = 0

    var __local_p__goto_3226_26: *const u8 = null

    var __local_pp__goto_3227_26: *const u8 = null

    var __local_callout_length__goto_3247_20: c_ulong = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_old_1: c_uint = 0

    var __ci_expr_old_2: c_uint = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_ternary_5: c_ulong = 0

    var __ci_expr_ternary_6: c_int = 0

    var __ci_expr_ternary_7: c_ulong = 0

    var __ci_expr_old_8: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_ternary_13: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_old_14: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_old_16: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_old_19: c_int = 0

    var __ci_expr_old_20: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_ternary_24: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_ternary_26: c_int = 0

    var __ci_expr_old_27: c_int = 0

    var __ci_expr_old_28: c_int = 0

    var __ci_expr_old_29: c_int = 0

    var __ci_expr_old_30: c_int = 0

    var __ci_expr_old_31: c_int = 0

    var __ci_expr_old_32: c_int = 0

    var __ci_expr_old_33: c_int = 0

    var __ci_expr_logic_34: c_int = 0

    var __ci_expr_old_35: c_int = 0

    var __ci_expr_logic_44: c_int = 0

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_old_45: c_int = 0

    var __ci_expr_old_46: c_int = 0

    var __ci_expr_old_47: c_int = 0

    var __ci_expr_old_48: c_int = 0

    var __ci_expr_logic_54: c_int = 0

    var __ci_expr_logic_58: c_int = 0

    var __ci_expr_logic_57: c_int = 0

    var __ci_expr_logic_56: c_int = 0

    var __ci_expr_logic_55: c_int = 0

    var __ci_expr_old_59: c_int = 0

    var __ci_expr_old_60: c_int = 0

    var __ci_expr_logic_67: c_int = 0

    var __ci_expr_old_68: c_int = 0

    var __ci_expr_logic_69: c_int = 0

    var __ci_expr_logic_77: c_int = 0

    var __ci_expr_old_78: c_int = 0

    var __ci_expr_logic_82: c_int = 0

    var __ci_expr_logic_81: c_int = 0

    var __ci_expr_logic_80: c_int = 0

    var __ci_expr_logic_79: c_int = 0

    var __ci_expr_old_83: c_int = 0

    var __ci_expr_logic_84: c_int = 0

    var __ci_expr_logic_91: c_int = 0

    var __ci_expr_old_92: c_int = 0

    var __ci_expr_logic_96: c_int = 0

    var __ci_expr_logic_95: c_int = 0

    var __ci_expr_logic_94: c_int = 0

    var __ci_expr_logic_93: c_int = 0

    var __ci_expr_old_97: c_int = 0

    var __ci_expr_ternary_102: c_int = 0

    var __ci_expr_old_103: c_int = 0

    var __ci_expr_logic_105: c_int = 0

    var __ci_expr_logic_104: c_int = 0

    var __ci_expr_old_106: c_int = 0

    var __ci_expr_logic_108: c_int = 0

    var __ci_expr_old_109: c_int = 0

    var __ci_expr_logic_110: c_int = 0

    var __ci_expr_logic_111: c_int = 0

    var __ci_expr_logic_114: c_int = 0

    var __ci_expr_logic_113: c_int = 0

    var __ci_expr_logic_112: c_int = 0

    var __ci_expr_logic_115: c_int = 0

    var __ci_expr_logic_116: c_int = 0

    var __ci_expr_logic_117: c_int = 0

    var __ci_expr_logic_120: c_int = 0

    var __ci_expr_logic_119: c_int = 0

    var __ci_expr_logic_118: c_int = 0

    var __ci_expr_logic_121: c_int = 0

    var __ci_expr_logic_122: c_int = 0

    var __ci_expr_old_123: c_int = 0

    var __ci_expr_logic_125: c_int = 0

    var __ci_expr_logic_124: c_int = 0

    var __ci_expr_logic_126: c_int = 0

    var __ci_expr_logic_127: c_int = 0

    var __ci_expr_logic_130: c_int = 0

    var __ci_expr_logic_129: c_int = 0

    var __ci_expr_logic_128: c_int = 0

    var __ci_expr_old_131: *const c_uint = null

    var __ci_expr_logic_136: c_int = 0

    var __ci_expr_logic_135: c_int = 0

    var __ci_expr_logic_133: c_int = 0

    var __ci_expr_logic_132: c_int = 0

    var __ci_expr_old_137: c_int = 0

    var __ci_expr_old_138: c_int = 0

    var __ci_expr_logic_143: c_int = 0

    var __ci_expr_logic_142: c_int = 0

    var __ci_expr_logic_141: c_int = 0

    var __ci_expr_logic_140: c_int = 0

    var __ci_expr_logic_139: c_int = 0

    var __ci_expr_logic_155: c_int = 0

    var __ci_expr_logic_146: c_int = 0

    var __ci_expr_logic_145: c_int = 0

    var __ci_expr_logic_144: c_int = 0

    var __ci_expr_logic_156: c_int = 0

    var __ci_expr_old_157: c_int = 0

    var __ci_expr_old_158: c_int = 0

    var __ci_expr_logic_163: c_int = 0

    var __ci_expr_logic_162: c_int = 0

    var __ci_expr_logic_161: c_int = 0

    var __ci_expr_logic_160: c_int = 0

    var __ci_expr_logic_159: c_int = 0

    var __ci_expr_logic_175: c_int = 0

    var __ci_expr_logic_166: c_int = 0

    var __ci_expr_logic_165: c_int = 0

    var __ci_expr_logic_164: c_int = 0

    var __ci_expr_old_176: c_int = 0

    var __ci_expr_old_177: c_int = 0

    var __ci_expr_logic_182: c_int = 0

    var __ci_expr_logic_181: c_int = 0

    var __ci_expr_logic_180: c_int = 0

    var __ci_expr_logic_179: c_int = 0

    var __ci_expr_logic_178: c_int = 0

    var __ci_expr_logic_194: c_int = 0

    var __ci_expr_logic_185: c_int = 0

    var __ci_expr_logic_184: c_int = 0

    var __ci_expr_logic_183: c_int = 0

    var __ci_expr_old_195: c_int = 0

    var __ci_expr_logic_200: c_int = 0

    var __ci_expr_logic_199: c_int = 0

    var __ci_expr_logic_198: c_int = 0

    var __ci_expr_logic_197: c_int = 0

    var __ci_expr_logic_196: c_int = 0

    var __ci_expr_logic_212: c_int = 0

    var __ci_expr_logic_203: c_int = 0

    var __ci_expr_logic_202: c_int = 0

    var __ci_expr_logic_201: c_int = 0

    var __ci_expr_old_213: c_int = 0

    var __ci_expr_old_214: c_int = 0

    var __ci_expr_old_215: c_int = 0

    var __ci_expr_logic_220: c_int = 0

    var __ci_expr_logic_219: c_int = 0

    var __ci_expr_logic_218: c_int = 0

    var __ci_expr_logic_217: c_int = 0

    var __ci_expr_logic_216: c_int = 0

    var __ci_expr_logic_232: c_int = 0

    var __ci_expr_logic_223: c_int = 0

    var __ci_expr_logic_222: c_int = 0

    var __ci_expr_logic_221: c_int = 0

    var __ci_expr_old_233: c_int = 0

    var __ci_expr_old_234: c_int = 0

    var __ci_expr_old_235: c_int = 0

    var __ci_expr_logic_237: c_int = 0

    var __ci_expr_logic_236: c_int = 0

    var __ci_expr_logic_238: c_int = 0

    var __ci_expr_logic_239: c_int = 0

    var __ci_expr_logic_242: c_int = 0

    var __ci_expr_logic_241: c_int = 0

    var __ci_expr_logic_240: c_int = 0

    var __ci_expr_old_243: *const c_uint = null

    var __ci_expr_logic_248: c_int = 0

    var __ci_expr_logic_247: c_int = 0

    var __ci_expr_logic_245: c_int = 0

    var __ci_expr_logic_244: c_int = 0

    var __ci_expr_logic_249: c_int = 0

    var __ci_expr_old_250: c_int = 0

    var __ci_expr_old_251: c_int = 0

    var __ci_expr_logic_252: c_int = 0

    var __ci_expr_old_253: c_int = 0

    var __ci_expr_old_254: c_int = 0

    var __ci_expr_logic_255: c_int = 0

    var __ci_expr_logic_256: c_int = 0

    var __ci_expr_old_257: c_int = 0

    var __ci_expr_old_258: c_int = 0

    var __ci_expr_logic_259: c_int = 0

    var __ci_expr_old_260: c_int = 0

    var __ci_expr_old_261: c_int = 0

    var __ci_expr_logic_262: c_int = 0

    var __ci_expr_old_263: c_int = 0

    var __ci_expr_old_264: c_int = 0

    var __ci_expr_logic_266: c_int = 0

    var __ci_expr_logic_265: c_int = 0

    var __ci_expr_logic_267: c_int = 0

    var __ci_expr_logic_268: c_int = 0

    var __ci_expr_logic_271: c_int = 0

    var __ci_expr_logic_270: c_int = 0

    var __ci_expr_logic_269: c_int = 0

    var __ci_expr_old_272: *const c_uint = null

    var __ci_expr_logic_277: c_int = 0

    var __ci_expr_logic_276: c_int = 0

    var __ci_expr_logic_274: c_int = 0

    var __ci_expr_logic_273: c_int = 0

    var __ci_expr_logic_278: c_int = 0

    var __ci_expr_old_279: c_int = 0

    var __ci_expr_old_280: c_int = 0

    var __ci_expr_logic_281: c_int = 0

    var __ci_expr_old_282: c_int = 0

    var __ci_expr_old_283: c_int = 0

    var __ci_expr_logic_284: c_int = 0

    var __ci_expr_logic_285: c_int = 0

    var __ci_expr_old_286: c_int = 0

    var __ci_expr_old_287: c_int = 0

    var __ci_expr_logic_288: c_int = 0

    var __ci_expr_old_289: c_int = 0

    var __ci_expr_old_290: c_int = 0

    var __ci_expr_logic_291: c_int = 0

    var __ci_expr_old_292: c_int = 0

    var __ci_expr_old_293: c_int = 0

    var __ci_expr_logic_295: c_int = 0

    var __ci_expr_logic_294: c_int = 0

    var __ci_expr_logic_296: c_int = 0

    var __ci_expr_logic_297: c_int = 0

    var __ci_expr_logic_300: c_int = 0

    var __ci_expr_logic_299: c_int = 0

    var __ci_expr_logic_298: c_int = 0

    var __ci_expr_old_301: *const c_uint = null

    var __ci_expr_logic_306: c_int = 0

    var __ci_expr_logic_305: c_int = 0

    var __ci_expr_logic_303: c_int = 0

    var __ci_expr_logic_302: c_int = 0

    var __ci_expr_old_307: c_int = 0

    var __ci_expr_old_308: c_int = 0

    var __ci_expr_old_309: c_int = 0

    var __ci_expr_logic_310: c_int = 0

    var __ci_expr_old_311: c_int = 0

    var __ci_expr_old_312: c_int = 0

    var __ci_expr_old_313: c_int = 0

    var __ci_expr_logic_314: c_int = 0

    var __ci_expr_old_315: c_int = 0

    var __ci_expr_old_316: c_int = 0

    var __ci_expr_old_317: c_int = 0

    var __ci_expr_old_318: c_int = 0

    var __ci_expr_old_319: c_int = 0

    var __ci_expr_old_320: c_int = 0

    var __ci_expr_old_321: c_int = 0

    var __ci_expr_old_322: c_int = 0

    var __ci_expr_logic_323: c_int = 0

    var __ci_expr_old_324: c_int = 0

    var __ci_expr_old_325: c_int = 0

    var __ci_expr_old_326: c_int = 0

    var __ci_expr_old_327: c_int = 0

    var __ci_expr_logic_328: c_int = 0

    var __ci_expr_old_329: c_int = 0

    var __ci_expr_old_330: c_int = 0

    var __ci_expr_old_331: c_int = 0

    var __ci_expr_old_332: c_int = 0

    var __ci_expr_old_333: c_int = 0

    var __ci_expr_old_334: c_int = 0

    var __ci_expr_old_335: c_int = 0

    var __ci_expr_old_336: c_int = 0

    var __ci_expr_old_337: c_int = 0

    var __ci_expr_logic_338: c_int = 0

    var __ci_expr_old_339: c_int = 0

    var __ci_expr_logic_340: c_int = 0

    var __ci_expr_logic_341: c_int = 0

    var __ci_expr_old_342: c_int = 0

    var __ci_expr_old_343: c_int = 0

    var __ci_expr_logic_344: c_int = 0

    var __ci_expr_logic_345: c_int = 0

    var __ci_expr_logic_347: c_int = 0

    var __ci_expr_old_348: c_int = 0

    var __ci_expr_old_349: c_int = 0

    var __ci_expr_logic_350: c_int = 0

    var __ci_expr_logic_351: c_int = 0

    var __ci_expr_logic_352: c_int = 0

    var __ci_expr_old_353: c_int = 0

    var __ci_expr_old_354: c_int = 0

    var __ci_expr_logic_355: c_int = 0

    var __ci_expr_logic_356: c_int = 0

    var __ci_expr_logic_357: c_int = 0

    var __ci_expr_old_358: c_int = 0

    var __ci_expr_logic_359: c_int = 0

    var __ci_expr_logic_360: c_int = 0

    var __ci_expr_old_361: c_int = 0

    var __ci_expr_old_362: c_int = 0

    var __ci_expr_old_363: c_int = 0

    var __ci_expr_logic_364: c_int = 0

    var __ci_expr_logic_365: c_int = 0

    var __ci_expr_logic_366: c_int = 0

    var __ci_expr_old_367: c_int = 0

    var __ci_expr_old_368: c_int = 0

    var __ci_expr_ternary_369: c_int = 0

    var __ci_expr_old_370: c_int = 0

    var __ci_expr_old_371: c_int = 0

    var __ci_expr_old_372: c_int = 0

    var __ci_expr_logic_373: c_int = 0

    var __ci_expr_old_374: c_int = 0

    var __ci_expr_old_375: c_int = 0

    var __ci_expr_old_376: c_int = 0

    var __ci_expr_old_377: c_int = 0

    var __ci_expr_logic_378: c_int = 0

    var __ci_expr_logic_379: c_int = 0

    var __ci_expr_old_380: c_int = 0

    var __ci_expr_old_381: c_int = 0

    var __ci_expr_old_382: c_int = 0

    var __ci_expr_logic_383: c_int = 0

    var __ci_expr_logic_384: c_int = 0

    var __ci_expr_old_385: c_int = 0

    var __ci_expr_logic_386: c_int = 0

    var __ci_expr_logic_388: c_int = 0

    var __ci_expr_logic_387: c_int = 0

    var __ci_expr_logic_389: c_int = 0

    var __ci_expr_old_390: c_int = 0

    var __ci_expr_old_391: c_int = 0

    var __ci_expr_old_392: c_int = 0

    var __ci_expr_old_393: c_int = 0

    var __ci_expr_logic_394: c_int = 0

    var __ci_expr_logic_395: c_int = 0

    var __ci_expr_old_396: c_int = 0

    var __ci_expr_old_397: c_int = 0

    var __ci_expr_ternary_398: c_uint = 0

    var __ci_expr_logic_400: c_int = 0

    var __ci_expr_logic_399: c_int = 0

    var __ci_expr_old_401: *const u8 = null

    var __ci_expr_old_402: c_int = 0

    var __ci_expr_old_403: c_int = 0

    var __ci_expr_logic_404: c_int = 0

    var __ci_expr_logic_405: c_int = 0

    var __ci_expr_old_406: c_int = 0

    var __ci_expr_old_407: *const u8 = null

    var __ci_expr_old_408: c_int = 0

    var __ci_expr_ternary_410: c_int = 0

    var __ci_expr_logic_409: c_int = 0

    var __ci_expr_old_411: c_int = 0

    var __ci_expr_logic_412: c_int = 0

    var __ci_expr_old_413: c_int = 0

    var __ci_expr_old_414: c_int = 0

    var __ci_expr_old_415: *const u8 = null

    var __ci_expr_old_416: c_int = 0

    var __ci_expr_old_417: c_int = 0

    var __ci_expr_old_418: c_int = 0

    var __ci_expr_logic_425: c_int = 0

    var __ci_expr_logic_421: c_int = 0

    var __ci_expr_logic_427: c_int = 0

    var __ci_expr_logic_426: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_start_subject__goto_553_12 = __param_mb.start_subject)
        (__local_end_subject__goto_554_12 = __param_mb.end_subject)
        (__local_start_code__goto_555_12 = __param_mb.start_code)
        (__local_utf__goto_558_6 = (if ((__param_mb.poptions as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        if (__local_utf__goto_558_6 != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if ((__param_mb.poptions as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_utf_or_ucp__goto_559_6 = __ci_expr_logic_0)
        (__local_reset_could_continue__goto_564_6 = 0)
        (__ci_expr_old_1 = __param_mb.match_call_count)
        ((unsafe *__param_mb).match_call_count = __param_mb.match_call_count + 1)
        if ((if __ci_expr_old_1 >= __param_mb.match_limit: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        return -47
    }

    '__ci_bb_2 {
        (__ci_expr_old_2 = __local_rlevel)
        (__local_rlevel = __local_rlevel + 1)
        if ((if __ci_expr_old_2 > __param_mb.match_limit_depth: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_3 {
        return -53
    }

    '__ci_bb_4 {
        (__local_offsetcount = __local_offsetcount & (-2 as c_uint))
        (__local_wscount = __local_wscount - 2)
        (__local_wscount = (__local_wscount - (__local_wscount % ((3 as c_int) * 2))) / (2 * (3 as c_int)))
        (__local_ctypes__goto_544_16 = __param_mb.tables + (((512 + 320) as isize) as usize))
        (__local_lcc__goto_544_25 = __param_mb.tables + ((0 as isize) as usize))
        (__local_fcc__goto_544_31 = __param_mb.tables + ((256 as isize) as usize))
        (__local_match_count__goto_548_30 = -1)
        (__local_active_states__goto_542_13 = (((__param_workspace + ((2 as isize) as usize)) as *mut stateblock)))
        (__local_new_states__goto_542_29 = __local_active_states__goto_542_13 + ((__local_wscount as isize) as usize))
        (__local_next_new_state__goto_543_33 = __local_new_states__goto_542_29)
        (__local_new_count__goto_548_19 = 0)
        if ((if (unsafe *__param_this_start_code) == OP_ASSERTBACK: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if (unsafe *__param_this_start_code) == OP_ASSERTBACK_NOT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_5 {
        (__local_max_back__goto_594_10 = 0)
        (__local_end_code__goto_546_12 = __param_this_start_code)
        goto '__ci_bb_8
    }

    '__ci_bb_6 {
        (__local_end_code__goto_546_12 = __param_this_start_code)
        (__ci_expr_logic_9 = 0)
        if ((if __local_rlevel == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if ((__param_mb.moptions as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_7 {
        ((unsafe __param_workspace[0]) = 0)
        (__local_ptr__goto_545_12 = __local_current_subject)
        goto '__ci_bb_49
    }

    '__ci_bb_8 {
        (__local_back__goto_600_12 = (((((((unsafe __local_end_code__goto_546_12[(2 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_code__goto_546_12[((2 + 2) + 1)]) as c_int)) as c_uint) as c_ulong)))
        if ((if __local_back__goto_600_12 > __local_max_back__goto_594_10: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_9 {
        if ((if (unsafe *__local_end_code__goto_546_12) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_10 {
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_11 {
        (__local_max_back__goto_594_10 = __local_back__goto_600_12)
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        (__local_end_code__goto_546_12 = __local_end_code__goto_546_12 + ((((((unsafe __local_end_code__goto_546_12[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_code__goto_546_12[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_9
    }

    '__ci_bb_13 {
        (__local_gone_back__goto_595_10 = 0)
        goto '__ci_bb_16
    }

    '__ci_bb_14 {
        (__local_current_offset__goto_628_12 = (((((__local_current_subject as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong)))
        (__ci_expr_ternary_5 = 0)
        if ((if __local_current_offset__goto_628_12 < __local_max_back__goto_594_10: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = __local_current_offset__goto_628_12)
        } else {
            (__ci_expr_ternary_5 = __local_max_back__goto_594_10)
        }
        (__local_gone_back__goto_595_10 = __ci_expr_ternary_5)
        (__local_current_subject = __local_current_subject - (__local_gone_back__goto_595_10 as usize))
        goto '__ci_bb_15
    }

    '__ci_bb_15 {
        if ((if __local_current_subject < __param_mb.start_used_ptr: 1 else: 0) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_16 {
        if ((if __local_gone_back__goto_595_10 < __local_max_back__goto_594_10: 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_17 {
        if ((if __local_current_subject <= __local_start_subject__goto_553_12: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_18 {
        (__local_gone_back__goto_595_10 = __local_gone_back__goto_595_10 + 1)
        goto '__ci_bb_16
    }

    '__ci_bb_19 {
        goto '__ci_bb_15
    }

    '__ci_bb_20 {
        goto '__ci_bb_19
    }

    '__ci_bb_21 {
        (__local_current_subject = __local_current_subject - 1)
        goto '__ci_bb_22
    }

    '__ci_bb_22 {
        (__ci_expr_logic_4 = 0)
        if ((if __local_current_subject > __local_start_subject__goto_553_12: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if ((((unsafe *__local_current_subject) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_23 {
        (__local_current_subject = __local_current_subject - 1)
        goto '__ci_bb_22
    }

    '__ci_bb_24 {
        goto '__ci_bb_18
    }

    '__ci_bb_25 {
        ((unsafe *__param_mb).start_used_ptr = __local_current_subject)
        goto '__ci_bb_26
    }

    '__ci_bb_26 {
        (__local_end_code__goto_546_12 = __param_this_start_code)
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        (__ci_expr_ternary_6 = 0)
        if ((if (unsafe __local_end_code__goto_546_12[(1 + 2)]) == OP_REVERSE: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = 1 + 2)
        } else {
            (__ci_expr_ternary_6 = 0)
        }
        (__local_revlen__goto_644_14 = __ci_expr_ternary_6)
        (__ci_expr_ternary_7 = 0)
        if ((if __local_revlen__goto_644_14 == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_7 = 0)
        } else {
            (__ci_expr_ternary_7 = (((((((unsafe __local_end_code__goto_546_12[(2 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_code__goto_546_12[((2 + 2) + 1)]) as c_int)) as c_uint) as c_ulong)))
        }
        (__local_back__goto_645_12 = __ci_expr_ternary_7)
        if ((if __local_back__goto_645_12 <= __local_gone_back__goto_595_10: 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_28 {
        if ((if (unsafe *__local_end_code__goto_546_12) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_29 {
        goto '__ci_bb_7
    }

    '__ci_bb_30 {
        (__local_bstate__goto_648_11 = ((((((((__local_end_code__goto_546_12 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 1) + 2) + __local_revlen__goto_644_14) as c_int)))
        (__ci_expr_old_8 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_8 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_31 {
        (__local_end_code__goto_546_12 = __local_end_code__goto_546_12 + ((((((unsafe __local_end_code__goto_546_12[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_code__goto_546_12[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_28
    }

    '__ci_bb_32 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_bstate__goto_648_11)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = ((((__local_gone_back__goto_595_10 as c_ulong) -% (__local_back__goto_645_12 as c_ulong)) as c_int)))
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_34
    }

    '__ci_bb_33 {
        return -43
    }

    '__ci_bb_34 {
        goto '__ci_bb_31
    }

    '__ci_bb_35 {
        goto '__ci_bb_38
    }

    '__ci_bb_36 {
        (__ci_expr_ternary_13 = 0)
        if ((if (unsafe *__param_this_start_code) == OP_CBRA: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if (if (unsafe *__param_this_start_code) == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_11 = (if (if (unsafe *__param_this_start_code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            (__ci_expr_logic_12 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_12 = (if (if (unsafe *__param_this_start_code) == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_ternary_13 = 2)
        } else {
            (__ci_expr_ternary_13 = 0)
        }
        (__local_length__goto_680_9 = (1 + 2) + __ci_expr_ternary_13)
        goto '__ci_bb_43
    }

    '__ci_bb_37 {
        goto '__ci_bb_7
    }

    '__ci_bb_38 {
        (__local_end_code__goto_546_12 = __local_end_code__goto_546_12 + ((((((unsafe __local_end_code__goto_546_12[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_code__goto_546_12[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_39
    }

    '__ci_bb_39 {
        if ((if (unsafe *__local_end_code__goto_546_12) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_40 {
        (__local_new_count__goto_548_19 = (unsafe __param_workspace[1]))
        if ((if not ((unsafe __param_workspace[0]) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_41 {
        with_memcpy((__local_new_states__goto_542_29 as *i8), (__local_active_states__goto_542_13 as *i8), ((((__local_new_count__goto_548_19 as c_ulong) as c_ulong) *% (sizeof[stateblock]() as c_ulong)) as i64))
        goto '__ci_bb_42
    }

    '__ci_bb_42 {
        goto '__ci_bb_37
    }

    '__ci_bb_43 {
        (__ci_expr_old_14 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_14 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_44 {
        if ((if (unsafe *__local_end_code__goto_546_12) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_45 {
        goto '__ci_bb_37
    }

    '__ci_bb_46 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = ((((((__local_end_code__goto_546_12 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + __local_length__goto_680_9) as c_int)))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_48
    }

    '__ci_bb_47 {
        return -43
    }

    '__ci_bb_48 {
        (__local_end_code__goto_546_12 = __local_end_code__goto_546_12 + ((((((unsafe __local_end_code__goto_546_12[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_code__goto_546_12[(1 + 1)]) as c_int)) as c_uint) as usize))
        (__local_length__goto_680_9 = 1 + 2)
        goto '__ci_bb_44
    }

    '__ci_bb_49 {
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        (__local_partial_newline__goto_704_8 = 0)
        (__local_could_continue__goto_705_8 = __local_reset_could_continue__goto_564_6)
        (__local_reset_could_continue__goto_564_6 = 0)
        if ((if __local_ptr__goto_545_12 > __param_mb.last_used_ptr: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_51 {
        goto '__ci_bb_49
    }

    '__ci_bb_52 {
        (__ci_expr_logic_427 = 0)
        (__ci_expr_logic_426 = 0)
        if ((if __local_match_count__goto_548_30 >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_426 = (if (if ((((__param_mb.moptions as c_uint) | (__param_mb.poptions as c_uint)) as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_426 != 0) {
            (__ci_expr_logic_427 = (if (if __local_ptr__goto_545_12 < __local_end_subject__goto_554_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_427 != 0) {
            goto '__ci_bb_1873
        } else {
            goto '__ci_bb_1874
        }
    }

    '__ci_bb_53 {
        ((unsafe *__param_mb).last_used_ptr = __local_ptr__goto_545_12)
        goto '__ci_bb_54
    }

    '__ci_bb_54 {
        (__local_temp_states__goto_542_42 = __local_active_states__goto_542_13)
        (__local_active_states__goto_542_13 = __local_new_states__goto_542_29)
        (__local_new_states__goto_542_29 = __local_temp_states__goto_542_42)
        (__local_active_count__goto_548_5 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = 0)
        ((unsafe __param_workspace[0]) = (unsafe __param_workspace[0]) ^ 1)
        ((unsafe __param_workspace[1]) = __local_active_count__goto_548_5)
        (__local_next_active_state__goto_543_13 = __local_active_states__goto_542_13 + ((__local_active_count__goto_548_5 as isize) as usize))
        (__local_next_new_state__goto_543_33 = __local_new_states__goto_542_29)
        if ((if __local_ptr__goto_545_12 < __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_55 {
        (__local_clen__goto_702_7 = 1)
        (__local_c__goto_703_12 = (unsafe *__local_ptr__goto_545_12))
        (__ci_expr_logic_15 = 0)
        if (__local_utf__goto_558_6 != 0) {
            (__ci_expr_logic_15 = (if (if __local_c__goto_703_12 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_56 {
        (__local_clen__goto_702_7 = 0)
        (__local_c__goto_703_12 = 4294967295)
        goto '__ci_bb_57
    }

    '__ci_bb_57 {
        (__local_i__goto_701_7 = 0)
        goto '__ci_bb_72
    }

    '__ci_bb_58 {
        if ((if ((__local_c__goto_703_12 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_59 {
        goto '__ci_bb_57
    }

    '__ci_bb_60 {
        (__local_c__goto_703_12 = (((((__local_c__goto_703_12 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __local_ptr__goto_545_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clen__goto_702_7 = __local_clen__goto_702_7 + 1)
        goto '__ci_bb_62
    }

    '__ci_bb_61 {
        if ((if ((__local_c__goto_703_12 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_62 {
        goto '__ci_bb_59
    }

    '__ci_bb_63 {
        (__local_c__goto_703_12 = (((((((__local_c__goto_703_12 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr__goto_545_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clen__goto_702_7 = __local_clen__goto_702_7 + 2)
        goto '__ci_bb_65
    }

    '__ci_bb_64 {
        if ((if ((__local_c__goto_703_12 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_65 {
        goto '__ci_bb_62
    }

    '__ci_bb_66 {
        (__local_c__goto_703_12 = (((((((((__local_c__goto_703_12 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr__goto_545_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clen__goto_702_7 = __local_clen__goto_702_7 + 3)
        goto '__ci_bb_68
    }

    '__ci_bb_67 {
        if ((if ((__local_c__goto_703_12 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_68 {
        goto '__ci_bb_65
    }

    '__ci_bb_69 {
        (__local_c__goto_703_12 = (((((((((((__local_c__goto_703_12 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr__goto_545_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clen__goto_702_7 = __local_clen__goto_702_7 + 4)
        goto '__ci_bb_71
    }

    '__ci_bb_70 {
        (__local_c__goto_703_12 = (((((((((((((__local_c__goto_703_12 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr__goto_545_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr__goto_545_12[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clen__goto_702_7 = __local_clen__goto_702_7 + 5)
        goto '__ci_bb_71
    }

    '__ci_bb_71 {
        goto '__ci_bb_68
    }

    '__ci_bb_72 {
        if ((if __local_i__goto_701_7 < __local_active_count__goto_548_5: 1 else: 0) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_73 {
        (__local_current_state__goto_753_17 = __local_active_states__goto_542_13 + ((__local_i__goto_701_7 as isize) as usize))
        (__local_caseless__goto_754_10 = 0)
        (__local_state_offset__goto_757_9 = __local_current_state__goto_753_17.offset)
        if ((if __local_state_offset__goto_757_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_74 {
        (__local_i__goto_701_7 = __local_i__goto_701_7 + 1)
        goto '__ci_bb_72
    }

    '__ci_bb_75 {
        if ((if __local_new_count__goto_548_19 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_1869
        } else {
            goto '__ci_bb_1870
        }
    }

    '__ci_bb_76 {
        if ((if __local_current_state__goto_753_17.data > 0: 1 else: 0) != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_77 {
        (__local_j__goto_701_10 = 0)
        goto '__ci_bb_86
    }

    '__ci_bb_78 {
        (__ci_expr_old_16 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_16 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_79 {
        (__local_state_offset__goto_757_9 = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_current_state__goto_753_17).offset = __local_state_offset__goto_757_9)
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        goto '__ci_bb_77
    }

    '__ci_bb_81 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_current_state__goto_753_17.count)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_current_state__goto_753_17.data - 1)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_83
    }

    '__ci_bb_82 {
        return -43
    }

    '__ci_bb_83 {
        if (__local_could_continue__goto_705_8 != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_84 {
        (__local_reset_could_continue__goto_564_6 = 1)
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        goto '__ci_bb_74
    }

    '__ci_bb_86 {
        if ((if __local_j__goto_701_10 < __local_i__goto_701_7: 1 else: 0) != 0) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_87 {
        (__ci_expr_logic_17 = 0)
        if ((if (unsafe __local_active_states__goto_542_13[__local_j__goto_701_10]).offset == __local_state_offset__goto_757_9: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if (unsafe __local_active_states__goto_542_13[__local_j__goto_701_10]).count == __local_current_state__goto_753_17.count: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_91
        }
    }

    '__ci_bb_88 {
        (__local_j__goto_701_10 = __local_j__goto_701_10 + 1)
        goto '__ci_bb_86
    }

    '__ci_bb_89 {
        (__local_code__goto_755_16 = __local_start_code__goto_555_12 + ((__local_state_offset__goto_757_9 as isize) as usize))
        (__local_codevalue__goto_756_14 = (unsafe *__local_code__goto_755_16))
        (__ci_expr_logic_18 = 0)
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if (if poptable[__local_codevalue__goto_756_14] != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_94
        }
    }

    '__ci_bb_90 {
        goto '__ci_bb_92
    }

    '__ci_bb_91 {
        goto '__ci_bb_88
    }

    '__ci_bb_92 {
        goto '__ci_bb_74
    }

    '__ci_bb_93 {
        (__local_could_continue__goto_705_8 = 1)
        goto '__ci_bb_94
    }

    '__ci_bb_94 {
        if ((if coptable[__local_codevalue__goto_756_14] > 0: 1 else: 0) != 0) {
            goto '__ci_bb_95
        } else {
            goto '__ci_bb_96
        }
    }

    '__ci_bb_95 {
        (__local_dlen__goto_702_13 = 1)
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_96 {
        (__local_dlen__goto_702_13 = 0)
        (__local_d__goto_703_15 = 4294967295)
        goto '__ci_bb_97
    }

    '__ci_bb_97 {
        goto '__ci_bb_134
    }

    '__ci_bb_98 {
        (__local_d__goto_703_15 = (unsafe *(__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))))
        if ((if __local_d__goto_703_15 >= 192: 1 else: 0) != 0) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_99 {
        (__local_d__goto_703_15 = (unsafe __local_code__goto_755_16[coptable[__local_codevalue__goto_756_14]]))
        goto '__ci_bb_100
    }

    '__ci_bb_100 {
        if ((if __local_codevalue__goto_756_14 >= 85: 1 else: 0) != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_101 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_102 {
        goto '__ci_bb_100
    }

    '__ci_bb_103 {
        (__local_d__goto_703_15 = (((((__local_d__goto_703_15 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_dlen__goto_702_13 = __local_dlen__goto_702_13 + 1)
        goto '__ci_bb_105
    }

    '__ci_bb_104 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_107
        }
    }

    '__ci_bb_105 {
        goto '__ci_bb_102
    }

    '__ci_bb_106 {
        (__local_d__goto_703_15 = (((((((__local_d__goto_703_15 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_dlen__goto_702_13 = __local_dlen__goto_702_13 + 2)
        goto '__ci_bb_108
    }

    '__ci_bb_107 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_108 {
        goto '__ci_bb_105
    }

    '__ci_bb_109 {
        (__local_d__goto_703_15 = (((((((((__local_d__goto_703_15 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_dlen__goto_702_13 = __local_dlen__goto_702_13 + 3)
        goto '__ci_bb_111
    }

    '__ci_bb_110 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_111 {
        goto '__ci_bb_108
    }

    '__ci_bb_112 {
        (__local_d__goto_703_15 = (((((((((((__local_d__goto_703_15 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_dlen__goto_702_13 = __local_dlen__goto_702_13 + 4)
        goto '__ci_bb_114
    }

    '__ci_bb_113 {
        (__local_d__goto_703_15 = (((((((((((((__local_d__goto_703_15 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe (__local_code__goto_755_16 + ((coptable[__local_codevalue__goto_756_14] as c_uint) as usize))[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_dlen__goto_702_13 = __local_dlen__goto_702_13 + 5)
        goto '__ci_bb_114
    }

    '__ci_bb_114 {
        goto '__ci_bb_111
    }

    '__ci_bb_115 {
        goto '__ci_bb_117
    }

    '__ci_bb_116 {
        goto '__ci_bb_97
    }

    '__ci_bb_117 {
        if (__local_d__goto_703_15 == 14) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_118 {
        goto '__ci_bb_116
    }

    '__ci_bb_119 {
        return -42
    }

    '__ci_bb_120 {
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 + 300)
        goto '__ci_bb_118
    }

    '__ci_bb_121 {
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 + 340)
        goto '__ci_bb_118
    }

    '__ci_bb_122 {
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 + 320)
        goto '__ci_bb_118
    }

    '__ci_bb_123 {
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 + 360)
        goto '__ci_bb_118
    }

    '__ci_bb_124 {
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 + 380)
        goto '__ci_bb_118
    }

    '__ci_bb_125 {
        goto '__ci_bb_118
    }

    '__ci_bb_126 {
        if (__local_d__goto_703_15 == 15) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_127 {
        if (__local_d__goto_703_15 == 16) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_128 {
        if (__local_d__goto_703_15 == 17) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_129 {
        if (__local_d__goto_703_15 == 22) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_130 {
        if (__local_d__goto_703_15 == 18) {
            goto '__ci_bb_123
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_131 {
        if (__local_d__goto_703_15 == 19) {
            goto '__ci_bb_123
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_132 {
        if (__local_d__goto_703_15 == 20) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_133 {
        if (__local_d__goto_703_15 == 21) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_134 {
        if (__local_codevalue__goto_756_14 == 122) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_1676
        }
    }

    '__ci_bb_135 {
        goto '__ci_bb_92
    }

    '__ci_bb_136 {
        if ((if __local_code__goto_755_16 != __local_end_code__goto_546_12: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_137 {
        (__ci_expr_old_19 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_19 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_138 {
        if ((if __local_ptr__goto_545_12 > __local_current_subject: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_22: c_int = 0

            if ((if ((__param_mb.moptions as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                var __ci_expr_logic_21: c_int

                if ((if ((__param_mb.moptions as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_21 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_21 = (if (if __local_current_subject > (__local_start_subject__goto_553_12 + (__param_mb.start_offset as usize)): 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

            }

            (__ci_expr_logic_23 = (if __ci_expr_logic_22 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_139 {
        goto '__ci_bb_135
    }

    '__ci_bb_140 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 1) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_142
    }

    '__ci_bb_141 {
        return -43
    }

    '__ci_bb_142 {
        if ((if __local_codevalue__goto_756_14 != 122: 1 else: 0) != 0) {
            goto '__ci_bb_143
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_143 {
        (__ci_expr_old_20 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_20 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_145
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_144 {
        goto '__ci_bb_139
    }

    '__ci_bb_145 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 - ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_147
    }

    '__ci_bb_146 {
        return -43
    }

    '__ci_bb_147 {
        goto '__ci_bb_144
    }

    '__ci_bb_148 {
        if ((if __local_match_count__goto_548_30 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_149 {
        goto '__ci_bb_139
    }

    '__ci_bb_150 {
        (__ci_expr_ternary_24 = 0)
        if ((if __local_offsetcount >= 2: 1 else: 0) != 0) {
            (__ci_expr_ternary_24 = 1)
        } else {
            (__ci_expr_ternary_24 = 0)
        }
        (__local_match_count__goto_548_30 = __ci_expr_ternary_24)
        goto '__ci_bb_152
    }

    '__ci_bb_151 {
        (__ci_expr_logic_25 = 0)
        if ((if __local_match_count__goto_548_30 > 0: 1 else: 0) != 0) {
            (__local_match_count__goto_548_30 = __local_match_count__goto_548_30 + 1)

            (__ci_expr_logic_25 = (if (if (__local_match_count__goto_548_30 * 2) > ((__local_offsetcount as c_int)): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_152 {
        (__ci_expr_ternary_26 = 0)
        if ((if __local_match_count__goto_548_30 == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_26 = ((__local_offsetcount as c_int)))
        } else {
            (__ci_expr_ternary_26 = __local_match_count__goto_548_30 * 2)
        }
        (__local_count__goto_759_9 = __ci_expr_ternary_26 - 2)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_153 {
        (__local_match_count__goto_548_30 = 0)
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        goto '__ci_bb_152
    }

    '__ci_bb_155 {
        with_memmove(((__param_offsets + ((2 as isize) as usize)) as *i8), (__param_offsets as *i8), ((((__local_count__goto_759_9 as c_ulong) as c_ulong) *% (sizeof[usize]() as c_ulong)) as i64))
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        if ((if __local_offsetcount >= 2: 1 else: 0) != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_157 {
        ((unsafe __param_offsets[0]) = (((((__local_current_subject as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong)))
        ((unsafe __param_offsets[1]) = (((((__local_ptr__goto_545_12 as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong)))
        goto '__ci_bb_158
    }

    '__ci_bb_158 {
        if ((if ((__param_mb.moptions as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_159 {
        return __local_match_count__goto_548_30
    }

    '__ci_bb_160 {
        goto '__ci_bb_149
    }

    '__ci_bb_161 {
        goto '__ci_bb_162
    }

    '__ci_bb_162 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_163
    }

    '__ci_bb_163 {
        if ((if (unsafe *__local_code__goto_755_16) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_164 {
        (__ci_expr_old_27 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_27 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_165 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((__local_code__goto_755_16 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_167
    }

    '__ci_bb_166 {
        return -43
    }

    '__ci_bb_167 {
        goto '__ci_bb_135
    }

    '__ci_bb_168 {
        goto '__ci_bb_169
    }

    '__ci_bb_169 {
        (__ci_expr_old_28 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_28 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_170 {
        if ((if (unsafe *__local_code__goto_755_16) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_171 {
        goto '__ci_bb_135
    }

    '__ci_bb_172 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((((__local_code__goto_755_16 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 1) + 2) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_174
    }

    '__ci_bb_173 {
        return -43
    }

    '__ci_bb_174 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_170
    }

    '__ci_bb_175 {
        (__ci_expr_old_29 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_29 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_176 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((((((((__local_code__goto_755_16 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 1) + 2) + 2) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_178
    }

    '__ci_bb_177 {
        return -43
    }

    '__ci_bb_178 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_179
    }

    '__ci_bb_179 {
        if ((if (unsafe *__local_code__goto_755_16) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_180 {
        (__ci_expr_old_30 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_30 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_181 {
        goto '__ci_bb_135
    }

    '__ci_bb_182 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((((__local_code__goto_755_16 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 1) + 2) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_184
    }

    '__ci_bb_183 {
        return -43
    }

    '__ci_bb_184 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_179
    }

    '__ci_bb_185 {
        (__ci_expr_old_31 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_31 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_186 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_188
    }

    '__ci_bb_187 {
        return -43
    }

    '__ci_bb_188 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + (((1 as c_uint) +% ((((((unsafe __local_code__goto_755_16[2]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(2 + 1)]) as c_int)) as c_uint) as c_uint)) as usize))
        goto '__ci_bb_189
    }

    '__ci_bb_189 {
        if ((if (unsafe *__local_code__goto_755_16) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_190
        } else {
            goto '__ci_bb_191
        }
    }

    '__ci_bb_190 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_189
    }

    '__ci_bb_191 {
        (__ci_expr_old_32 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_32 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_192
        } else {
            goto '__ci_bb_193
        }
    }

    '__ci_bb_192 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((((__local_code__goto_755_16 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 1) + 2) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_194
    }

    '__ci_bb_193 {
        return -43
    }

    '__ci_bb_194 {
        goto '__ci_bb_135
    }

    '__ci_bb_195 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + (((1 as c_uint) +% ((((((unsafe __local_code__goto_755_16[2]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(2 + 1)]) as c_int)) as c_uint) as c_uint)) as usize))
        goto '__ci_bb_196
    }

    '__ci_bb_196 {
        if ((if (unsafe *__local_code__goto_755_16) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_197 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_196
    }

    '__ci_bb_198 {
        (__ci_expr_old_33 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_33 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_200
        }
    }

    '__ci_bb_199 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((((__local_code__goto_755_16 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 1) + 2) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_201
    }

    '__ci_bb_200 {
        return -43
    }

    '__ci_bb_201 {
        goto '__ci_bb_135
    }

    '__ci_bb_202 {
        (__ci_expr_logic_34 = 0)
        if ((if __local_ptr__goto_545_12 == __local_start_subject__goto_553_12: 1 else: 0) != 0) {
            (__ci_expr_logic_34 = (if (if ((__param_mb.moptions as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_204
        }
    }

    '__ci_bb_203 {
        (__ci_expr_old_35 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_35 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_204 {
        goto '__ci_bb_135
    }

    '__ci_bb_205 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_207
    }

    '__ci_bb_206 {
        return -43
    }

    '__ci_bb_207 {
        goto '__ci_bb_204
    }

    '__ci_bb_208 {
        (__ci_expr_logic_36 = 0)
        if ((if __local_ptr__goto_545_12 == __local_start_subject__goto_553_12: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if (if ((__param_mb.moptions as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            (__ci_expr_logic_44 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_43: c_int = 0

            var __ci_expr_logic_37: c_int

            if ((if __local_ptr__goto_545_12 != __local_end_subject__goto_554_12: 1 else: 0) != 0) {
                (__ci_expr_logic_37 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_37 = (if (if ((__param_mb.poptions as c_uint) & (2097152 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_37 != 0) {
                var __ci_expr_ternary_42: c_int = 0

                if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_38: c_int = 0

                    if ((if __local_ptr__goto_545_12 > __param_mb.start_subject: 1 else: 0) != 0) {
                        (__ci_expr_logic_38 = (if _pcre2_was_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.start_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                    }

                    (__ci_expr_ternary_42 = __ci_expr_logic_38)

                } else {
                    var __ci_expr_logic_41: c_int = 0

                    var __ci_expr_logic_39: c_int = 0

                    if ((if __local_ptr__goto_545_12 >= (__param_mb.start_subject + (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                        (__ci_expr_logic_39 = (if (if (unsafe *(__local_ptr__goto_545_12 - (__param_mb.nllen as usize))) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_39 != 0) {
                        var __ci_expr_logic_40: c_int

                        if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                            (__ci_expr_logic_40 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_40 = (if (if (unsafe *((__local_ptr__goto_545_12 - (__param_mb.nllen as usize)) + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_41 = (if __ci_expr_logic_40 != 0: 1 else: 0))

                    }

                    (__ci_expr_ternary_42 = __ci_expr_logic_41)

                }

                (__ci_expr_logic_43 = (if __ci_expr_ternary_42 != 0: 1 else: 0))

            }

            (__ci_expr_logic_44 = (if __ci_expr_logic_43 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_44 != 0) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_209 {
        (__ci_expr_old_45 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_45 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_210 {
        goto '__ci_bb_135
    }

    '__ci_bb_211 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_213
    }

    '__ci_bb_212 {
        return -43
    }

    '__ci_bb_213 {
        goto '__ci_bb_210
    }

    '__ci_bb_214 {
        if ((if __local_ptr__goto_545_12 >= __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_215 {
        if ((if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_216 {
        goto '__ci_bb_135
    }

    '__ci_bb_217 {
        return -2
    }

    '__ci_bb_218 {
        (__ci_expr_old_46 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_46 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_219 {
        goto '__ci_bb_216
    }

    '__ci_bb_220 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_222
    }

    '__ci_bb_221 {
        return -43
    }

    '__ci_bb_222 {
        goto '__ci_bb_219
    }

    '__ci_bb_223 {
        if ((if __local_ptr__goto_545_12 == __local_start_subject__goto_553_12: 1 else: 0) != 0) {
            goto '__ci_bb_224
        } else {
            goto '__ci_bb_225
        }
    }

    '__ci_bb_224 {
        (__ci_expr_old_47 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_47 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_226
        } else {
            goto '__ci_bb_227
        }
    }

    '__ci_bb_225 {
        goto '__ci_bb_135
    }

    '__ci_bb_226 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_228
    }

    '__ci_bb_227 {
        return -43
    }

    '__ci_bb_228 {
        goto '__ci_bb_225
    }

    '__ci_bb_229 {
        if ((if __local_ptr__goto_545_12 == (__local_start_subject__goto_553_12 + (__param_start_offset as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_230 {
        (__ci_expr_old_48 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_48 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_232
        } else {
            goto '__ci_bb_233
        }
    }

    '__ci_bb_231 {
        goto '__ci_bb_135
    }

    '__ci_bb_232 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_234
    }

    '__ci_bb_233 {
        return -43
    }

    '__ci_bb_234 {
        goto '__ci_bb_231
    }

    '__ci_bb_235 {
        (__ci_expr_logic_54 = 0)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            var __ci_expr_ternary_53: c_int = 0

            if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_49: c_int = 0

                if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_49 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_53 = __ci_expr_logic_49)

            } else {
                var __ci_expr_logic_52: c_int = 0

                var __ci_expr_logic_50: c_int = 0

                if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_50 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_50 != 0) {
                    var __ci_expr_logic_51: c_int

                    if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_51 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_51 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_52 = (if __ci_expr_logic_51 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_53 = __ci_expr_logic_52)

            }

            (__ci_expr_logic_54 = (if (if not (__ci_expr_ternary_53 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_54 != 0) {
            goto '__ci_bb_236
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_236 {
        (__ci_expr_logic_58 = 0)
        (__ci_expr_logic_57 = 0)
        (__ci_expr_logic_56 = 0)
        (__ci_expr_logic_55 = 0)
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0) {
            (__ci_expr_logic_55 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_55 != 0) {
            (__ci_expr_logic_56 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_56 != 0) {
            (__ci_expr_logic_57 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_57 != 0) {
            (__ci_expr_logic_58 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_58 != 0) {
            goto '__ci_bb_238
        } else {
            goto '__ci_bb_239
        }
    }

    '__ci_bb_237 {
        goto '__ci_bb_135
    }

    '__ci_bb_238 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_240
    }

    '__ci_bb_239 {
        (__ci_expr_old_59 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_59 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_241
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_240 {
        goto '__ci_bb_237
    }

    '__ci_bb_241 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_243
    }

    '__ci_bb_242 {
        return -43
    }

    '__ci_bb_243 {
        goto '__ci_bb_240
    }

    '__ci_bb_244 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_245
        } else {
            goto '__ci_bb_246
        }
    }

    '__ci_bb_245 {
        (__ci_expr_old_60 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_60 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_247
        } else {
            goto '__ci_bb_248
        }
    }

    '__ci_bb_246 {
        goto '__ci_bb_135
    }

    '__ci_bb_247 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_249
    }

    '__ci_bb_248 {
        return -43
    }

    '__ci_bb_249 {
        goto '__ci_bb_246
    }

    '__ci_bb_250 {
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_67 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_66: c_int = 0

            var __ci_expr_ternary_65: c_int = 0

            if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_61: c_int = 0

                if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                    (__ci_expr_logic_61 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                }

                (__ci_expr_ternary_65 = __ci_expr_logic_61)

            } else {
                var __ci_expr_logic_64: c_int = 0

                var __ci_expr_logic_62: c_int = 0

                if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_62 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_62 != 0) {
                    var __ci_expr_logic_63: c_int

                    if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                        (__ci_expr_logic_63 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_63 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_64 = (if __ci_expr_logic_63 != 0: 1 else: 0))

                }

                (__ci_expr_ternary_65 = __ci_expr_logic_64)

            }

            if (__ci_expr_ternary_65 != 0) {
                (__ci_expr_logic_66 = (if (if __local_ptr__goto_545_12 == (__local_end_subject__goto_554_12 - (__param_mb.nllen as usize)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_67 = (if __ci_expr_logic_66 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_67 != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_251 {
        if ((if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_253
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_252 {
        goto '__ci_bb_135
    }

    '__ci_bb_253 {
        return -2
    }

    '__ci_bb_254 {
        (__ci_expr_old_68 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_68 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_255 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_257
    }

    '__ci_bb_256 {
        return -43
    }

    '__ci_bb_257 {
        goto '__ci_bb_252
    }

    '__ci_bb_258 {
        if ((if ((__param_mb.moptions as c_uint) & (2 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_259
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_259 {
        (__ci_expr_logic_69 = 0)
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_69 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_69 != 0) {
            goto '__ci_bb_261
        } else {
            goto '__ci_bb_262
        }
    }

    '__ci_bb_260 {
        goto '__ci_bb_135
    }

    '__ci_bb_261 {
        (__local_could_continue__goto_705_8 = 1)
        goto '__ci_bb_263
    }

    '__ci_bb_262 {
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_77 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_76: c_int = 0

            var __ci_expr_logic_75: c_int = 0

            if ((if ((__param_mb.poptions as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                var __ci_expr_ternary_74: c_int = 0

                if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_70: c_int = 0

                    if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                        (__ci_expr_logic_70 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                    }

                    (__ci_expr_ternary_74 = __ci_expr_logic_70)

                } else {
                    var __ci_expr_logic_73: c_int = 0

                    var __ci_expr_logic_71: c_int = 0

                    if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                        (__ci_expr_logic_71 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_71 != 0) {
                        var __ci_expr_logic_72: c_int

                        if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                            (__ci_expr_logic_72 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_72 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_73 = (if __ci_expr_logic_72 != 0: 1 else: 0))

                    }

                    (__ci_expr_ternary_74 = __ci_expr_logic_73)

                }

                (__ci_expr_logic_75 = (if __ci_expr_ternary_74 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_75 != 0) {
                (__ci_expr_logic_76 = (if (if __local_ptr__goto_545_12 == (__local_end_subject__goto_554_12 - (__param_mb.nllen as usize)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_77 = (if __ci_expr_logic_76 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_77 != 0) {
            goto '__ci_bb_264
        } else {
            goto '__ci_bb_265
        }
    }

    '__ci_bb_263 {
        goto '__ci_bb_260
    }

    '__ci_bb_264 {
        (__ci_expr_old_78 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_78 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_267
        } else {
            goto '__ci_bb_268
        }
    }

    '__ci_bb_265 {
        (__ci_expr_logic_82 = 0)
        (__ci_expr_logic_81 = 0)
        (__ci_expr_logic_80 = 0)
        (__ci_expr_logic_79 = 0)
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0) {
            (__ci_expr_logic_79 = (if (if ((__param_mb.moptions as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_79 != 0) {
            (__ci_expr_logic_80 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_80 != 0) {
            (__ci_expr_logic_81 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_81 != 0) {
            (__ci_expr_logic_82 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_82 != 0) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_271
        }
    }

    '__ci_bb_266 {
        goto '__ci_bb_263
    }

    '__ci_bb_267 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_269
    }

    '__ci_bb_268 {
        return -43
    }

    '__ci_bb_269 {
        goto '__ci_bb_266
    }

    '__ci_bb_270 {
        if ((if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_273
        }
    }

    '__ci_bb_271 {
        goto '__ci_bb_266
    }

    '__ci_bb_272 {
        (__local_reset_could_continue__goto_564_6 = 1)
        (__ci_expr_old_83 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_83 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_273 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_274
    }

    '__ci_bb_274 {
        goto '__ci_bb_271
    }

    '__ci_bb_275 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + 1))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 1)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_277
    }

    '__ci_bb_276 {
        return -43
    }

    '__ci_bb_277 {
        goto '__ci_bb_274
    }

    '__ci_bb_278 {
        if ((if ((__param_mb.moptions as c_uint) & (2 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_279
        } else {
            goto '__ci_bb_280
        }
    }

    '__ci_bb_279 {
        (__ci_expr_logic_84 = 0)
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_84 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_84 != 0) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_283
        }
    }

    '__ci_bb_280 {
        (__ci_expr_ternary_102 = 0)
        if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
            var __ci_expr_logic_98: c_int = 0

            if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                (__ci_expr_logic_98 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
            }

            (__ci_expr_ternary_102 = __ci_expr_logic_98)

        } else {
            var __ci_expr_logic_101: c_int = 0

            var __ci_expr_logic_99: c_int = 0

            if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                (__ci_expr_logic_99 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_99 != 0) {
                var __ci_expr_logic_100: c_int

                if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_100 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_100 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_101 = (if __ci_expr_logic_100 != 0: 1 else: 0))

            }

            (__ci_expr_ternary_102 = __ci_expr_logic_101)

        }
        if (__ci_expr_ternary_102 != 0) {
            goto '__ci_bb_299
        } else {
            goto '__ci_bb_300
        }
    }

    '__ci_bb_281 {
        goto '__ci_bb_135
    }

    '__ci_bb_282 {
        (__local_could_continue__goto_705_8 = 1)
        goto '__ci_bb_284
    }

    '__ci_bb_283 {
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_91 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_90: c_int = 0

            if ((if ((__param_mb.poptions as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                var __ci_expr_ternary_89: c_int = 0

                if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_85: c_int = 0

                    if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                        (__ci_expr_logic_85 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                    }

                    (__ci_expr_ternary_89 = __ci_expr_logic_85)

                } else {
                    var __ci_expr_logic_88: c_int = 0

                    var __ci_expr_logic_86: c_int = 0

                    if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                        (__ci_expr_logic_86 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_86 != 0) {
                        var __ci_expr_logic_87: c_int

                        if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                            (__ci_expr_logic_87 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_87 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_88 = (if __ci_expr_logic_87 != 0: 1 else: 0))

                    }

                    (__ci_expr_ternary_89 = __ci_expr_logic_88)

                }

                (__ci_expr_logic_90 = (if __ci_expr_ternary_89 != 0: 1 else: 0))

            }

            (__ci_expr_logic_91 = (if __ci_expr_logic_90 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_91 != 0) {
            goto '__ci_bb_285
        } else {
            goto '__ci_bb_286
        }
    }

    '__ci_bb_284 {
        goto '__ci_bb_281
    }

    '__ci_bb_285 {
        (__ci_expr_old_92 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_92 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_288
        } else {
            goto '__ci_bb_289
        }
    }

    '__ci_bb_286 {
        (__ci_expr_logic_96 = 0)
        (__ci_expr_logic_95 = 0)
        (__ci_expr_logic_94 = 0)
        (__ci_expr_logic_93 = 0)
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0) {
            (__ci_expr_logic_93 = (if (if ((__param_mb.moptions as c_uint) & (((32 as c_uint) | (16 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_93 != 0) {
            (__ci_expr_logic_94 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_94 != 0) {
            (__ci_expr_logic_95 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_95 != 0) {
            (__ci_expr_logic_96 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_96 != 0) {
            goto '__ci_bb_291
        } else {
            goto '__ci_bb_292
        }
    }

    '__ci_bb_287 {
        goto '__ci_bb_284
    }

    '__ci_bb_288 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_290
    }

    '__ci_bb_289 {
        return -43
    }

    '__ci_bb_290 {
        goto '__ci_bb_287
    }

    '__ci_bb_291 {
        if ((if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_293
        } else {
            goto '__ci_bb_294
        }
    }

    '__ci_bb_292 {
        goto '__ci_bb_287
    }

    '__ci_bb_293 {
        (__local_reset_could_continue__goto_564_6 = 1)
        (__ci_expr_old_97 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_97 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_296
        } else {
            goto '__ci_bb_297
        }
    }

    '__ci_bb_294 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_295
    }

    '__ci_bb_295 {
        goto '__ci_bb_292
    }

    '__ci_bb_296 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + 1))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 1)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_298
    }

    '__ci_bb_297 {
        return -43
    }

    '__ci_bb_298 {
        goto '__ci_bb_295
    }

    '__ci_bb_299 {
        (__ci_expr_old_103 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_103 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_301
        } else {
            goto '__ci_bb_302
        }
    }

    '__ci_bb_300 {
        goto '__ci_bb_281
    }

    '__ci_bb_301 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_303
    }

    '__ci_bb_302 {
        return -43
    }

    '__ci_bb_303 {
        goto '__ci_bb_300
    }

    '__ci_bb_304 {
        (__ci_expr_logic_105 = 0)
        (__ci_expr_logic_104 = 0)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_104 = (if (if __local_c__goto_703_12 < 256: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_104 != 0) {
            (__ci_expr_logic_105 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_codevalue__goto_756_14] as c_int)) ^ (toptable2[__local_codevalue__goto_756_14] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_105 != 0) {
            goto '__ci_bb_305
        } else {
            goto '__ci_bb_306
        }
    }

    '__ci_bb_305 {
        (__ci_expr_old_106 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_106 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_307
        } else {
            goto '__ci_bb_308
        }
    }

    '__ci_bb_306 {
        goto '__ci_bb_135
    }

    '__ci_bb_307 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_309
    }

    '__ci_bb_308 {
        return -43
    }

    '__ci_bb_309 {
        goto '__ci_bb_306
    }

    '__ci_bb_310 {
        (__ci_expr_logic_108 = 0)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_107: c_int

            if ((if __local_c__goto_703_12 >= 256: 1 else: 0) != 0) {
                (__ci_expr_logic_107 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_107 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_codevalue__goto_756_14] as c_int)) ^ (toptable2[__local_codevalue__goto_756_14] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_108 = (if __ci_expr_logic_107 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_108 != 0) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_312
        }
    }

    '__ci_bb_311 {
        (__ci_expr_old_109 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_109 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_313
        } else {
            goto '__ci_bb_314
        }
    }

    '__ci_bb_312 {
        goto '__ci_bb_135
    }

    '__ci_bb_313 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_315
    }

    '__ci_bb_314 {
        return -43
    }

    '__ci_bb_315 {
        goto '__ci_bb_312
    }

    '__ci_bb_316 {
        if ((if __local_ptr__goto_545_12 > __local_start_subject__goto_553_12: 1 else: 0) != 0) {
            goto '__ci_bb_317
        } else {
            goto '__ci_bb_318
        }
    }

    '__ci_bb_317 {
        (__local_temp__goto_1104_22 = __local_ptr__goto_545_12 - ((1 as isize) as usize))
        if ((if __local_temp__goto_1104_22 < __param_mb.start_used_ptr: 1 else: 0) != 0) {
            goto '__ci_bb_320
        } else {
            goto '__ci_bb_321
        }
    }

    '__ci_bb_318 {
        (__local_left_word__goto_1100_13 = 0)
        goto '__ci_bb_319
    }

    '__ci_bb_319 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_344
        } else {
            goto '__ci_bb_345
        }
    }

    '__ci_bb_320 {
        ((unsafe *__param_mb).start_used_ptr = __local_temp__goto_1104_22)
        goto '__ci_bb_321
    }

    '__ci_bb_321 {
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_322
        } else {
            goto '__ci_bb_323
        }
    }

    '__ci_bb_322 {
        goto '__ci_bb_324
    }

    '__ci_bb_323 {
        (__local_d__goto_703_15 = (unsafe *__local_temp__goto_1104_22))
        (__ci_expr_logic_110 = 0)
        if (__local_utf__goto_558_6 != 0) {
            (__ci_expr_logic_110 = (if (if __local_d__goto_703_15 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_110 != 0) {
            goto '__ci_bb_327
        } else {
            goto '__ci_bb_328
        }
    }

    '__ci_bb_324 {
        if ((if ((((unsafe *__local_temp__goto_1104_22) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
            goto '__ci_bb_325
        } else {
            goto '__ci_bb_326
        }
    }

    '__ci_bb_325 {
        (__local_temp__goto_1104_22 = __local_temp__goto_1104_22 - 1)
        goto '__ci_bb_324
    }

    '__ci_bb_326 {
        goto '__ci_bb_323
    }

    '__ci_bb_327 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_329
        } else {
            goto '__ci_bb_330
        }
    }

    '__ci_bb_328 {
        if ((if __local_codevalue__goto_756_14 == 172: 1 else: 0) != 0) {
            (__ci_expr_logic_111 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_111 = (if (if __local_codevalue__goto_756_14 == 171: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_111 != 0) {
            goto '__ci_bb_341
        } else {
            goto '__ci_bb_342
        }
    }

    '__ci_bb_329 {
        (__local_d__goto_703_15 = (((((__local_d__goto_703_15 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __local_temp__goto_1104_22[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_331
    }

    '__ci_bb_330 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_332
        } else {
            goto '__ci_bb_333
        }
    }

    '__ci_bb_331 {
        goto '__ci_bb_328
    }

    '__ci_bb_332 {
        (__local_d__goto_703_15 = (((((((__local_d__goto_703_15 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_temp__goto_1104_22[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_334
    }

    '__ci_bb_333 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_335
        } else {
            goto '__ci_bb_336
        }
    }

    '__ci_bb_334 {
        goto '__ci_bb_331
    }

    '__ci_bb_335 {
        (__local_d__goto_703_15 = (((((((((__local_d__goto_703_15 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_temp__goto_1104_22[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_337
    }

    '__ci_bb_336 {
        if ((if ((__local_d__goto_703_15 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_338
        } else {
            goto '__ci_bb_339
        }
    }

    '__ci_bb_337 {
        goto '__ci_bb_334
    }

    '__ci_bb_338 {
        (__local_d__goto_703_15 = (((((((((((__local_d__goto_703_15 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_temp__goto_1104_22[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_340
    }

    '__ci_bb_339 {
        (__local_d__goto_703_15 = (((((((((((((__local_d__goto_703_15 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_temp__goto_1104_22[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_temp__goto_1104_22[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_340
    }

    '__ci_bb_340 {
        goto '__ci_bb_337
    }

    '__ci_bb_341 {
        (__local_chartype__goto_1114_17 = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).chartype)
        (__local_category__goto_1115_17 = _pcre2_ucp_gentype_8[__local_chartype__goto_1114_17])
        if ((if __local_category__goto_1115_17 == ucp_L: 1 else: 0) != 0) {
            (__ci_expr_logic_112 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_112 = (if (if __local_category__goto_1115_17 == ucp_N: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_112 != 0) {
            (__ci_expr_logic_113 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_113 = (if (if __local_chartype__goto_1114_17 == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_113 != 0) {
            (__ci_expr_logic_114 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_114 = (if (if __local_chartype__goto_1114_17 == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_left_word__goto_1100_13 = __ci_expr_logic_114)
        goto '__ci_bb_343
    }

    '__ci_bb_342 {
        (__ci_expr_logic_115 = 0)
        if ((if __local_d__goto_703_15 < 256: 1 else: 0) != 0) {
            (__ci_expr_logic_115 = (if (if (((unsafe __local_ctypes__goto_544_16[__local_d__goto_703_15]) as c_int) & 16) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_left_word__goto_1100_13 = __ci_expr_logic_115)
        goto '__ci_bb_343
    }

    '__ci_bb_343 {
        goto '__ci_bb_319
    }

    '__ci_bb_344 {
        if ((if __local_ptr__goto_545_12 >= __param_mb.last_used_ptr: 1 else: 0) != 0) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_348
        }
    }

    '__ci_bb_345 {
        (__local_right_word__goto_1100_24 = 0)
        goto '__ci_bb_346
    }

    '__ci_bb_346 {
        if ((if __local_codevalue__goto_756_14 == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_122 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_122 = (if (if __local_codevalue__goto_756_14 == 171: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if (if __local_left_word__goto_1100_13 == __local_right_word__goto_1100_24: 1 else: 0) == __ci_expr_logic_122: 1 else: 0) != 0) {
            goto '__ci_bb_357
        } else {
            goto '__ci_bb_358
        }
    }

    '__ci_bb_347 {
        (__local_temp__goto_1129_24 = __local_ptr__goto_545_12 + ((1 as isize) as usize))
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_349
        } else {
            goto '__ci_bb_350
        }
    }

    '__ci_bb_348 {
        if ((if __local_codevalue__goto_756_14 == 172: 1 else: 0) != 0) {
            (__ci_expr_logic_117 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_117 = (if (if __local_codevalue__goto_756_14 == 171: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_117 != 0) {
            goto '__ci_bb_354
        } else {
            goto '__ci_bb_355
        }
    }

    '__ci_bb_349 {
        goto '__ci_bb_351
    }

    '__ci_bb_350 {
        ((unsafe *__param_mb).last_used_ptr = __local_temp__goto_1129_24)
        goto '__ci_bb_348
    }

    '__ci_bb_351 {
        (__ci_expr_logic_116 = 0)
        if ((if __local_temp__goto_1129_24 < __param_mb.end_subject: 1 else: 0) != 0) {
            (__ci_expr_logic_116 = (if (if ((((unsafe *__local_temp__goto_1129_24) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_116 != 0) {
            goto '__ci_bb_352
        } else {
            goto '__ci_bb_353
        }
    }

    '__ci_bb_352 {
        (__local_temp__goto_1129_24 = __local_temp__goto_1129_24 + 1)
        goto '__ci_bb_351
    }

    '__ci_bb_353 {
        goto '__ci_bb_350
    }

    '__ci_bb_354 {
        (__local_chartype__goto_1139_17 = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize)).chartype)
        (__local_category__goto_1140_17 = _pcre2_ucp_gentype_8[__local_chartype__goto_1139_17])
        if ((if __local_category__goto_1140_17 == ucp_L: 1 else: 0) != 0) {
            (__ci_expr_logic_118 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_118 = (if (if __local_category__goto_1140_17 == ucp_N: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_118 != 0) {
            (__ci_expr_logic_119 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_119 = (if (if __local_chartype__goto_1139_17 == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_119 != 0) {
            (__ci_expr_logic_120 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_120 = (if (if __local_chartype__goto_1139_17 == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_right_word__goto_1100_24 = __ci_expr_logic_120)
        goto '__ci_bb_356
    }

    '__ci_bb_355 {
        (__ci_expr_logic_121 = 0)
        if ((if __local_c__goto_703_12 < 256: 1 else: 0) != 0) {
            (__ci_expr_logic_121 = (if (if (((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & 16) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_right_word__goto_1100_24 = __ci_expr_logic_121)
        goto '__ci_bb_356
    }

    '__ci_bb_356 {
        goto '__ci_bb_346
    }

    '__ci_bb_357 {
        (__ci_expr_old_123 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_123 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_359
        } else {
            goto '__ci_bb_360
        }
    }

    '__ci_bb_358 {
        goto '__ci_bb_135
    }

    '__ci_bb_359 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_361
    }

    '__ci_bb_360 {
        return -43
    }

    '__ci_bb_361 {
        goto '__ci_bb_358
    }

    '__ci_bb_362 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_363
        } else {
            goto '__ci_bb_364
        }
    }

    '__ci_bb_363 {
        (__local_prop__goto_1171_28 = (&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize))
        goto '__ci_bb_365
    }

    '__ci_bb_364 {
        goto '__ci_bb_135
    }

    '__ci_bb_365 {
        if ((unsafe __local_code__goto_755_16[1]) == 0) {
            goto '__ci_bb_367
        } else {
            goto '__ci_bb_417
        }
    }

    '__ci_bb_366 {
        if ((if __local_OK__goto_1168_14 == (if __local_codevalue__goto_756_14 == 16: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_429
        } else {
            goto '__ci_bb_430
        }
    }

    '__ci_bb_367 {
        (__local_chartype__goto_1169_13 = __local_prop__goto_1171_28.chartype)
        if ((if __local_chartype__goto_1169_13 == ucp_Lu: 1 else: 0) != 0) {
            (__ci_expr_logic_124 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_124 = (if (if __local_chartype__goto_1169_13 == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_124 != 0) {
            (__ci_expr_logic_125 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_125 = (if (if __local_chartype__goto_1169_13 == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1168_14 = __ci_expr_logic_125)
        goto '__ci_bb_366
    }

    '__ci_bb_368 {
        (__local_OK__goto_1168_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1171_28.chartype] == (unsafe __local_code__goto_755_16[2]): 1 else: 0))
        goto '__ci_bb_366
    }

    '__ci_bb_369 {
        (__local_OK__goto_1168_14 = (if __local_prop__goto_1171_28.chartype == (unsafe __local_code__goto_755_16[2]): 1 else: 0))
        goto '__ci_bb_366
    }

    '__ci_bb_370 {
        (__local_OK__goto_1168_14 = (if __local_prop__goto_1171_28.script == (unsafe __local_code__goto_755_16[2]): 1 else: 0))
        goto '__ci_bb_366
    }

    '__ci_bb_371 {
        if ((if __local_prop__goto_1171_28.script == (unsafe __local_code__goto_755_16[2]): 1 else: 0) != 0) {
            (__ci_expr_logic_126 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_126 = (if (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1171_28.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[(((unsafe __local_code__goto_755_16[2]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[2]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1168_14 = __ci_expr_logic_126)
        goto '__ci_bb_366
    }

    '__ci_bb_372 {
        (__local_chartype__goto_1169_13 = __local_prop__goto_1171_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1169_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_127 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_127 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1169_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1168_14 = __ci_expr_logic_127)
        goto '__ci_bb_366
    }

    '__ci_bb_373 {
        goto '__ci_bb_374
    }

    '__ci_bb_374 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_378
        }
    }

    '__ci_bb_375 {
        goto '__ci_bb_366
    }

    '__ci_bb_376 {
        (__local_OK__goto_1168_14 = 1)
        goto '__ci_bb_375
    }

    '__ci_bb_377 {
        (__local_OK__goto_1168_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1171_28.chartype] == 6: 1 else: 0))
        goto '__ci_bb_375
    }

    '__ci_bb_378 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_379
        }
    }

    '__ci_bb_379 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_380
        }
    }

    '__ci_bb_380 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_381
        }
    }

    '__ci_bb_381 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_382
        }
    }

    '__ci_bb_382 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_383
        }
    }

    '__ci_bb_383 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_384
        }
    }

    '__ci_bb_384 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_385
        }
    }

    '__ci_bb_385 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_386
        }
    }

    '__ci_bb_386 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_387
        }
    }

    '__ci_bb_387 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_388
        }
    }

    '__ci_bb_388 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_389
        }
    }

    '__ci_bb_389 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_390
        }
    }

    '__ci_bb_390 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_391
        }
    }

    '__ci_bb_391 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_392
        }
    }

    '__ci_bb_392 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_393
        }
    }

    '__ci_bb_393 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_394
        }
    }

    '__ci_bb_394 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_395
        }
    }

    '__ci_bb_395 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_396
        }
    }

    '__ci_bb_396 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_397
        }
    }

    '__ci_bb_397 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_398
        }
    }

    '__ci_bb_398 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_399
        }
    }

    '__ci_bb_399 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_400
        }
    }

    '__ci_bb_400 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_401
        }
    }

    '__ci_bb_401 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_402
        }
    }

    '__ci_bb_402 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_377
        }
    }

    '__ci_bb_403 {
        (__local_chartype__goto_1169_13 = __local_prop__goto_1171_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1169_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_128 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_128 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1169_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_128 != 0) {
            (__ci_expr_logic_129 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_129 = (if (if __local_chartype__goto_1169_13 == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_129 != 0) {
            (__ci_expr_logic_130 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_130 = (if (if __local_chartype__goto_1169_13 == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1168_14 = __ci_expr_logic_130)
        goto '__ci_bb_366
    }

    '__ci_bb_404 {
        (__local_cp__goto_1170_25 = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe __local_code__goto_755_16[2]) as c_uint) as usize))
        goto '__ci_bb_405
    }

    '__ci_bb_405 {
        goto '__ci_bb_406
    }

    '__ci_bb_406 {
        if ((if __local_c__goto_703_12 < (unsafe *__local_cp__goto_1170_25): 1 else: 0) != 0) {
            goto '__ci_bb_409
        } else {
            goto '__ci_bb_410
        }
    }

    '__ci_bb_407 {
        goto '__ci_bb_405
    }

    '__ci_bb_408 {
        goto '__ci_bb_366
    }

    '__ci_bb_409 {
        (__local_OK__goto_1168_14 = 0)
        goto '__ci_bb_408
    }

    '__ci_bb_410 {
        (__ci_expr_old_131 = __local_cp__goto_1170_25)
        (__local_cp__goto_1170_25 = __local_cp__goto_1170_25 + 1)
        if ((if __local_c__goto_703_12 == (unsafe *__ci_expr_old_131): 1 else: 0) != 0) {
            goto '__ci_bb_411
        } else {
            goto '__ci_bb_412
        }
    }

    '__ci_bb_411 {
        (__local_OK__goto_1168_14 = 1)
        goto '__ci_bb_408
    }

    '__ci_bb_412 {
        goto '__ci_bb_407
    }

    '__ci_bb_413 {
        if ((if __local_c__goto_703_12 == 36: 1 else: 0) != 0) {
            (__ci_expr_logic_132 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_132 = (if (if __local_c__goto_703_12 == 64: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_132 != 0) {
            (__ci_expr_logic_133 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_133 = (if (if __local_c__goto_703_12 == 96: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_133 != 0) {
            (__ci_expr_logic_135 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_134: c_int = 0

            if ((if __local_c__goto_703_12 >= 160: 1 else: 0) != 0) {
                (__ci_expr_logic_134 = (if (if __local_c__goto_703_12 <= 55295: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_135 = (if __ci_expr_logic_134 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_135 != 0) {
            (__ci_expr_logic_136 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_136 = (if (if __local_c__goto_703_12 >= 57344: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1168_14 = __ci_expr_logic_136)
        goto '__ci_bb_366
    }

    '__ci_bb_414 {
        (__local_OK__goto_1168_14 = (if ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize)).scriptx_bidiclass as c_int) >> (11 as c_uint)) == (unsafe __local_code__goto_755_16[2]): 1 else: 0))
        goto '__ci_bb_366
    }

    '__ci_bb_415 {
        (__local_OK__goto_1168_14 = (if (((unsafe ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1171_28.bprops as c_int) & 4095) as isize) as usize))[(((unsafe __local_code__goto_755_16[2]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[2]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0))
        goto '__ci_bb_366
    }

    '__ci_bb_416 {
        (__local_OK__goto_1168_14 = (if __local_codevalue__goto_756_14 != 16: 1 else: 0))
        goto '__ci_bb_366
    }

    '__ci_bb_417 {
        if ((unsafe __local_code__goto_755_16[1]) == 1) {
            goto '__ci_bb_368
        } else {
            goto '__ci_bb_418
        }
    }

    '__ci_bb_418 {
        if ((unsafe __local_code__goto_755_16[1]) == 2) {
            goto '__ci_bb_369
        } else {
            goto '__ci_bb_419
        }
    }

    '__ci_bb_419 {
        if ((unsafe __local_code__goto_755_16[1]) == 3) {
            goto '__ci_bb_370
        } else {
            goto '__ci_bb_420
        }
    }

    '__ci_bb_420 {
        if ((unsafe __local_code__goto_755_16[1]) == 4) {
            goto '__ci_bb_371
        } else {
            goto '__ci_bb_421
        }
    }

    '__ci_bb_421 {
        if ((unsafe __local_code__goto_755_16[1]) == 5) {
            goto '__ci_bb_372
        } else {
            goto '__ci_bb_422
        }
    }

    '__ci_bb_422 {
        if ((unsafe __local_code__goto_755_16[1]) == 6) {
            goto '__ci_bb_373
        } else {
            goto '__ci_bb_423
        }
    }

    '__ci_bb_423 {
        if ((unsafe __local_code__goto_755_16[1]) == 7) {
            goto '__ci_bb_373
        } else {
            goto '__ci_bb_424
        }
    }

    '__ci_bb_424 {
        if ((unsafe __local_code__goto_755_16[1]) == 8) {
            goto '__ci_bb_403
        } else {
            goto '__ci_bb_425
        }
    }

    '__ci_bb_425 {
        if ((unsafe __local_code__goto_755_16[1]) == 9) {
            goto '__ci_bb_404
        } else {
            goto '__ci_bb_426
        }
    }

    '__ci_bb_426 {
        if ((unsafe __local_code__goto_755_16[1]) == 10) {
            goto '__ci_bb_413
        } else {
            goto '__ci_bb_427
        }
    }

    '__ci_bb_427 {
        if ((unsafe __local_code__goto_755_16[1]) == 11) {
            goto '__ci_bb_414
        } else {
            goto '__ci_bb_428
        }
    }

    '__ci_bb_428 {
        if ((unsafe __local_code__goto_755_16[1]) == 12) {
            goto '__ci_bb_415
        } else {
            goto '__ci_bb_416
        }
    }

    '__ci_bb_429 {
        (__ci_expr_old_137 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_137 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_431
        } else {
            goto '__ci_bb_432
        }
    }

    '__ci_bb_430 {
        goto '__ci_bb_364
    }

    '__ci_bb_431 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 3)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_433
    }

    '__ci_bb_432 {
        return -43
    }

    '__ci_bb_433 {
        goto '__ci_bb_430
    }

    '__ci_bb_434 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_436
        }
    }

    '__ci_bb_435 {
        (__ci_expr_old_138 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_138 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_437
        } else {
            goto '__ci_bb_438
        }
    }

    '__ci_bb_436 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_440
        } else {
            goto '__ci_bb_441
        }
    }

    '__ci_bb_437 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_439
    }

    '__ci_bb_438 {
        return -43
    }

    '__ci_bb_439 {
        goto '__ci_bb_436
    }

    '__ci_bb_440 {
        (__ci_expr_logic_143 = 0)
        (__ci_expr_logic_142 = 0)
        (__ci_expr_logic_141 = 0)
        (__ci_expr_logic_140 = 0)
        (__ci_expr_logic_139 = 0)
        if ((if __local_d__goto_703_15 == 12: 1 else: 0) != 0) {
            (__ci_expr_logic_139 = (if (if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_139 != 0) {
            (__ci_expr_logic_140 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_140 != 0) {
            (__ci_expr_logic_141 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_141 != 0) {
            (__ci_expr_logic_142 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_142 != 0) {
            (__ci_expr_logic_143 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_143 != 0) {
            goto '__ci_bb_442
        } else {
            goto '__ci_bb_443
        }
    }

    '__ci_bb_441 {
        goto '__ci_bb_135
    }

    '__ci_bb_442 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_444
    }

    '__ci_bb_443 {
        (__ci_expr_logic_146 = 0)
        (__ci_expr_logic_145 = 0)
        (__ci_expr_logic_144 = 0)
        if ((if __local_c__goto_703_12 >= 256: 1 else: 0) != 0) {
            (__ci_expr_logic_144 = (if (if __local_d__goto_703_15 != 7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_144 != 0) {
            (__ci_expr_logic_145 = (if (if __local_d__goto_703_15 != 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_145 != 0) {
            (__ci_expr_logic_146 = (if (if __local_d__goto_703_15 != 11: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_146 != 0) {
            (__ci_expr_logic_155 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_154: c_int = 0

            var __ci_expr_logic_153: c_int = 0

            if ((if __local_c__goto_703_12 < 256: 1 else: 0) != 0) {
                var __ci_expr_logic_152: c_int

                if ((if __local_d__goto_703_15 != 12: 1 else: 0) != 0) {
                    (__ci_expr_logic_152 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_ternary_151: c_int = 0

                    if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                        var __ci_expr_logic_147: c_int = 0

                        if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                            (__ci_expr_logic_147 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                        }

                        (__ci_expr_ternary_151 = __ci_expr_logic_147)

                    } else {
                        var __ci_expr_logic_150: c_int = 0

                        var __ci_expr_logic_148: c_int = 0

                        if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                            (__ci_expr_logic_148 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_148 != 0) {
                            var __ci_expr_logic_149: c_int

                            if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                                (__ci_expr_logic_149 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_149 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_150 = (if __ci_expr_logic_149 != 0: 1 else: 0))

                        }

                        (__ci_expr_ternary_151 = __ci_expr_logic_150)

                    }

                    (__ci_expr_logic_152 = (if (if not (__ci_expr_ternary_151 != 0): 1 else: 0) != 0: 1 else: 0))

                }

                (__ci_expr_logic_153 = (if __ci_expr_logic_152 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_153 != 0) {
                (__ci_expr_logic_154 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_d__goto_703_15] as c_int)) ^ (toptable2[__local_d__goto_703_15] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_155 = (if __ci_expr_logic_154 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_155 != 0) {
            goto '__ci_bb_445
        } else {
            goto '__ci_bb_446
        }
    }

    '__ci_bb_444 {
        goto '__ci_bb_441
    }

    '__ci_bb_445 {
        (__ci_expr_logic_156 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_156 = (if (if __local_codevalue__goto_756_14 == 95: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_156 != 0) {
            goto '__ci_bb_447
        } else {
            goto '__ci_bb_448
        }
    }

    '__ci_bb_446 {
        goto '__ci_bb_444
    }

    '__ci_bb_447 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_448
    }

    '__ci_bb_448 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_157 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_157 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_449
        } else {
            goto '__ci_bb_450
        }
    }

    '__ci_bb_449 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_451
    }

    '__ci_bb_450 {
        return -43
    }

    '__ci_bb_451 {
        goto '__ci_bb_446
    }

    '__ci_bb_452 {
        (__ci_expr_old_158 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_158 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_453
        } else {
            goto '__ci_bb_454
        }
    }

    '__ci_bb_453 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_455
    }

    '__ci_bb_454 {
        return -43
    }

    '__ci_bb_455 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_456
        } else {
            goto '__ci_bb_457
        }
    }

    '__ci_bb_456 {
        (__ci_expr_logic_163 = 0)
        (__ci_expr_logic_162 = 0)
        (__ci_expr_logic_161 = 0)
        (__ci_expr_logic_160 = 0)
        (__ci_expr_logic_159 = 0)
        if ((if __local_d__goto_703_15 == 12: 1 else: 0) != 0) {
            (__ci_expr_logic_159 = (if (if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_159 != 0) {
            (__ci_expr_logic_160 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_160 != 0) {
            (__ci_expr_logic_161 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_161 != 0) {
            (__ci_expr_logic_162 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_162 != 0) {
            (__ci_expr_logic_163 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_163 != 0) {
            goto '__ci_bb_458
        } else {
            goto '__ci_bb_459
        }
    }

    '__ci_bb_457 {
        goto '__ci_bb_135
    }

    '__ci_bb_458 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_460
    }

    '__ci_bb_459 {
        (__ci_expr_logic_166 = 0)
        (__ci_expr_logic_165 = 0)
        (__ci_expr_logic_164 = 0)
        if ((if __local_c__goto_703_12 >= 256: 1 else: 0) != 0) {
            (__ci_expr_logic_164 = (if (if __local_d__goto_703_15 != 7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_164 != 0) {
            (__ci_expr_logic_165 = (if (if __local_d__goto_703_15 != 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_165 != 0) {
            (__ci_expr_logic_166 = (if (if __local_d__goto_703_15 != 11: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_166 != 0) {
            (__ci_expr_logic_175 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_174: c_int = 0

            var __ci_expr_logic_173: c_int = 0

            if ((if __local_c__goto_703_12 < 256: 1 else: 0) != 0) {
                var __ci_expr_logic_172: c_int

                if ((if __local_d__goto_703_15 != 12: 1 else: 0) != 0) {
                    (__ci_expr_logic_172 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_ternary_171: c_int = 0

                    if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                        var __ci_expr_logic_167: c_int = 0

                        if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                            (__ci_expr_logic_167 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                        }

                        (__ci_expr_ternary_171 = __ci_expr_logic_167)

                    } else {
                        var __ci_expr_logic_170: c_int = 0

                        var __ci_expr_logic_168: c_int = 0

                        if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                            (__ci_expr_logic_168 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_168 != 0) {
                            var __ci_expr_logic_169: c_int

                            if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                                (__ci_expr_logic_169 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_169 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_170 = (if __ci_expr_logic_169 != 0: 1 else: 0))

                        }

                        (__ci_expr_ternary_171 = __ci_expr_logic_170)

                    }

                    (__ci_expr_logic_172 = (if (if not (__ci_expr_ternary_171 != 0): 1 else: 0) != 0: 1 else: 0))

                }

                (__ci_expr_logic_173 = (if __ci_expr_logic_172 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_173 != 0) {
                (__ci_expr_logic_174 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_d__goto_703_15] as c_int)) ^ (toptable2[__local_d__goto_703_15] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_175 = (if __ci_expr_logic_174 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_175 != 0) {
            goto '__ci_bb_461
        } else {
            goto '__ci_bb_462
        }
    }

    '__ci_bb_460 {
        goto '__ci_bb_457
    }

    '__ci_bb_461 {
        if ((if __local_codevalue__goto_756_14 == 96: 1 else: 0) != 0) {
            goto '__ci_bb_463
        } else {
            goto '__ci_bb_464
        }
    }

    '__ci_bb_462 {
        goto '__ci_bb_460
    }

    '__ci_bb_463 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_464
    }

    '__ci_bb_464 {
        (__ci_expr_old_176 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_176 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_465
        } else {
            goto '__ci_bb_466
        }
    }

    '__ci_bb_465 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_467
    }

    '__ci_bb_466 {
        return -43
    }

    '__ci_bb_467 {
        goto '__ci_bb_462
    }

    '__ci_bb_468 {
        (__ci_expr_old_177 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_177 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_469
        } else {
            goto '__ci_bb_470
        }
    }

    '__ci_bb_469 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_471
    }

    '__ci_bb_470 {
        return -43
    }

    '__ci_bb_471 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_472
        } else {
            goto '__ci_bb_473
        }
    }

    '__ci_bb_472 {
        (__ci_expr_logic_182 = 0)
        (__ci_expr_logic_181 = 0)
        (__ci_expr_logic_180 = 0)
        (__ci_expr_logic_179 = 0)
        (__ci_expr_logic_178 = 0)
        if ((if __local_d__goto_703_15 == 12: 1 else: 0) != 0) {
            (__ci_expr_logic_178 = (if (if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_178 != 0) {
            (__ci_expr_logic_179 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_179 != 0) {
            (__ci_expr_logic_180 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_180 != 0) {
            (__ci_expr_logic_181 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_181 != 0) {
            (__ci_expr_logic_182 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_182 != 0) {
            goto '__ci_bb_474
        } else {
            goto '__ci_bb_475
        }
    }

    '__ci_bb_473 {
        goto '__ci_bb_135
    }

    '__ci_bb_474 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_476
    }

    '__ci_bb_475 {
        (__ci_expr_logic_185 = 0)
        (__ci_expr_logic_184 = 0)
        (__ci_expr_logic_183 = 0)
        if ((if __local_c__goto_703_12 >= 256: 1 else: 0) != 0) {
            (__ci_expr_logic_183 = (if (if __local_d__goto_703_15 != 7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_183 != 0) {
            (__ci_expr_logic_184 = (if (if __local_d__goto_703_15 != 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_184 != 0) {
            (__ci_expr_logic_185 = (if (if __local_d__goto_703_15 != 11: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_185 != 0) {
            (__ci_expr_logic_194 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_193: c_int = 0

            var __ci_expr_logic_192: c_int = 0

            if ((if __local_c__goto_703_12 < 256: 1 else: 0) != 0) {
                var __ci_expr_logic_191: c_int

                if ((if __local_d__goto_703_15 != 12: 1 else: 0) != 0) {
                    (__ci_expr_logic_191 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_ternary_190: c_int = 0

                    if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                        var __ci_expr_logic_186: c_int = 0

                        if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                            (__ci_expr_logic_186 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                        }

                        (__ci_expr_ternary_190 = __ci_expr_logic_186)

                    } else {
                        var __ci_expr_logic_189: c_int = 0

                        var __ci_expr_logic_187: c_int = 0

                        if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                            (__ci_expr_logic_187 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_187 != 0) {
                            var __ci_expr_logic_188: c_int

                            if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                                (__ci_expr_logic_188 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_188 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_189 = (if __ci_expr_logic_188 != 0: 1 else: 0))

                        }

                        (__ci_expr_ternary_190 = __ci_expr_logic_189)

                    }

                    (__ci_expr_logic_191 = (if (if not (__ci_expr_ternary_190 != 0): 1 else: 0) != 0: 1 else: 0))

                }

                (__ci_expr_logic_192 = (if __ci_expr_logic_191 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_192 != 0) {
                (__ci_expr_logic_193 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_d__goto_703_15] as c_int)) ^ (toptable2[__local_d__goto_703_15] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_194 = (if __ci_expr_logic_193 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_194 != 0) {
            goto '__ci_bb_477
        } else {
            goto '__ci_bb_478
        }
    }

    '__ci_bb_476 {
        goto '__ci_bb_473
    }

    '__ci_bb_477 {
        if ((if __local_codevalue__goto_756_14 == 94: 1 else: 0) != 0) {
            goto '__ci_bb_479
        } else {
            goto '__ci_bb_480
        }
    }

    '__ci_bb_478 {
        goto '__ci_bb_476
    }

    '__ci_bb_479 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_480
    }

    '__ci_bb_480 {
        (__ci_expr_old_195 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_195 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_481
        } else {
            goto '__ci_bb_482
        }
    }

    '__ci_bb_481 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_483
    }

    '__ci_bb_482 {
        return -43
    }

    '__ci_bb_483 {
        goto '__ci_bb_478
    }

    '__ci_bb_484 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_485
        } else {
            goto '__ci_bb_486
        }
    }

    '__ci_bb_485 {
        (__ci_expr_logic_200 = 0)
        (__ci_expr_logic_199 = 0)
        (__ci_expr_logic_198 = 0)
        (__ci_expr_logic_197 = 0)
        (__ci_expr_logic_196 = 0)
        if ((if __local_d__goto_703_15 == 12: 1 else: 0) != 0) {
            (__ci_expr_logic_196 = (if (if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_196 != 0) {
            (__ci_expr_logic_197 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_197 != 0) {
            (__ci_expr_logic_198 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_198 != 0) {
            (__ci_expr_logic_199 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_199 != 0) {
            (__ci_expr_logic_200 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_200 != 0) {
            goto '__ci_bb_487
        } else {
            goto '__ci_bb_488
        }
    }

    '__ci_bb_486 {
        goto '__ci_bb_135
    }

    '__ci_bb_487 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_489
    }

    '__ci_bb_488 {
        (__ci_expr_logic_203 = 0)
        (__ci_expr_logic_202 = 0)
        (__ci_expr_logic_201 = 0)
        if ((if __local_c__goto_703_12 >= 256: 1 else: 0) != 0) {
            (__ci_expr_logic_201 = (if (if __local_d__goto_703_15 != 7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_201 != 0) {
            (__ci_expr_logic_202 = (if (if __local_d__goto_703_15 != 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_202 != 0) {
            (__ci_expr_logic_203 = (if (if __local_d__goto_703_15 != 11: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_203 != 0) {
            (__ci_expr_logic_212 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_211: c_int = 0

            var __ci_expr_logic_210: c_int = 0

            if ((if __local_c__goto_703_12 < 256: 1 else: 0) != 0) {
                var __ci_expr_logic_209: c_int

                if ((if __local_d__goto_703_15 != 12: 1 else: 0) != 0) {
                    (__ci_expr_logic_209 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_ternary_208: c_int = 0

                    if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                        var __ci_expr_logic_204: c_int = 0

                        if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                            (__ci_expr_logic_204 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                        }

                        (__ci_expr_ternary_208 = __ci_expr_logic_204)

                    } else {
                        var __ci_expr_logic_207: c_int = 0

                        var __ci_expr_logic_205: c_int = 0

                        if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                            (__ci_expr_logic_205 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_205 != 0) {
                            var __ci_expr_logic_206: c_int

                            if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                                (__ci_expr_logic_206 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_206 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_207 = (if __ci_expr_logic_206 != 0: 1 else: 0))

                        }

                        (__ci_expr_ternary_208 = __ci_expr_logic_207)

                    }

                    (__ci_expr_logic_209 = (if (if not (__ci_expr_ternary_208 != 0): 1 else: 0) != 0: 1 else: 0))

                }

                (__ci_expr_logic_210 = (if __ci_expr_logic_209 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_210 != 0) {
                (__ci_expr_logic_211 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_d__goto_703_15] as c_int)) ^ (toptable2[__local_d__goto_703_15] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_212 = (if __ci_expr_logic_211 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_212 != 0) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_491
        }
    }

    '__ci_bb_489 {
        goto '__ci_bb_486
    }

    '__ci_bb_490 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_492
        } else {
            goto '__ci_bb_493
        }
    }

    '__ci_bb_491 {
        goto '__ci_bb_489
    }

    '__ci_bb_492 {
        (__ci_expr_old_213 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_213 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_495
        } else {
            goto '__ci_bb_496
        }
    }

    '__ci_bb_493 {
        (__ci_expr_old_214 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_214 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_498
        } else {
            goto '__ci_bb_499
        }
    }

    '__ci_bb_494 {
        goto '__ci_bb_491
    }

    '__ci_bb_495 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = ((__local_state_offset__goto_757_9 + 1) + 2) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_497
    }

    '__ci_bb_496 {
        return -43
    }

    '__ci_bb_497 {
        goto '__ci_bb_494
    }

    '__ci_bb_498 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_500
    }

    '__ci_bb_499 {
        return -43
    }

    '__ci_bb_500 {
        goto '__ci_bb_494
    }

    '__ci_bb_501 {
        (__ci_expr_old_215 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_215 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_502
        } else {
            goto '__ci_bb_503
        }
    }

    '__ci_bb_502 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_504
    }

    '__ci_bb_503 {
        return -43
    }

    '__ci_bb_504 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_505
        } else {
            goto '__ci_bb_506
        }
    }

    '__ci_bb_505 {
        (__ci_expr_logic_220 = 0)
        (__ci_expr_logic_219 = 0)
        (__ci_expr_logic_218 = 0)
        (__ci_expr_logic_217 = 0)
        (__ci_expr_logic_216 = 0)
        if ((if __local_d__goto_703_15 == 12: 1 else: 0) != 0) {
            (__ci_expr_logic_216 = (if (if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __param_mb.end_subject: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_216 != 0) {
            (__ci_expr_logic_217 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_217 != 0) {
            (__ci_expr_logic_218 = (if (if __param_mb.nltype == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_218 != 0) {
            (__ci_expr_logic_219 = (if (if __param_mb.nllen == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_219 != 0) {
            (__ci_expr_logic_220 = (if (if __local_c__goto_703_12 == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_220 != 0) {
            goto '__ci_bb_507
        } else {
            goto '__ci_bb_508
        }
    }

    '__ci_bb_506 {
        goto '__ci_bb_135
    }

    '__ci_bb_507 {
        (__local_partial_newline__goto_704_8 = 1)
        (__local_could_continue__goto_705_8 = __local_partial_newline__goto_704_8)
        goto '__ci_bb_509
    }

    '__ci_bb_508 {
        (__ci_expr_logic_223 = 0)
        (__ci_expr_logic_222 = 0)
        (__ci_expr_logic_221 = 0)
        if ((if __local_c__goto_703_12 >= 256: 1 else: 0) != 0) {
            (__ci_expr_logic_221 = (if (if __local_d__goto_703_15 != 7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_221 != 0) {
            (__ci_expr_logic_222 = (if (if __local_d__goto_703_15 != 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_222 != 0) {
            (__ci_expr_logic_223 = (if (if __local_d__goto_703_15 != 11: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_223 != 0) {
            (__ci_expr_logic_232 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_231: c_int = 0

            var __ci_expr_logic_230: c_int = 0

            if ((if __local_c__goto_703_12 < 256: 1 else: 0) != 0) {
                var __ci_expr_logic_229: c_int

                if ((if __local_d__goto_703_15 != 12: 1 else: 0) != 0) {
                    (__ci_expr_logic_229 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_ternary_228: c_int = 0

                    if ((if __param_mb.nltype != 0: 1 else: 0) != 0) {
                        var __ci_expr_logic_224: c_int = 0

                        if ((if __local_ptr__goto_545_12 < __param_mb.end_subject: 1 else: 0) != 0) {
                            (__ci_expr_logic_224 = (if _pcre2_is_newline_8(__local_ptr__goto_545_12, __param_mb.nltype, __param_mb.end_subject, ((&raw const (unsafe *__param_mb).nllen as *const c_uint) as *mut c_uint), __local_utf__goto_558_6) != 0: 1 else: 0))
                        }

                        (__ci_expr_ternary_228 = __ci_expr_logic_224)

                    } else {
                        var __ci_expr_logic_227: c_int = 0

                        var __ci_expr_logic_225: c_int = 0

                        if ((if __local_ptr__goto_545_12 <= (__param_mb.end_subject - (__param_mb.nllen as usize)): 1 else: 0) != 0) {
                            (__ci_expr_logic_225 = (if (if (unsafe *__local_ptr__goto_545_12) == __param_mb.nl[0]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_225 != 0) {
                            var __ci_expr_logic_226: c_int

                            if ((if __param_mb.nllen == 1: 1 else: 0) != 0) {
                                (__ci_expr_logic_226 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_226 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == __param_mb.nl[1]: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_227 = (if __ci_expr_logic_226 != 0: 1 else: 0))

                        }

                        (__ci_expr_ternary_228 = __ci_expr_logic_227)

                    }

                    (__ci_expr_logic_229 = (if (if not (__ci_expr_ternary_228 != 0): 1 else: 0) != 0: 1 else: 0))

                }

                (__ci_expr_logic_230 = (if __ci_expr_logic_229 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_230 != 0) {
                (__ci_expr_logic_231 = (if (if ((((unsafe __local_ctypes__goto_544_16[__local_c__goto_703_12]) as c_int) & (toptable1[__local_d__goto_703_15] as c_int)) ^ (toptable2[__local_d__goto_703_15] as c_int)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_232 = (if __ci_expr_logic_231 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_232 != 0) {
            goto '__ci_bb_510
        } else {
            goto '__ci_bb_511
        }
    }

    '__ci_bb_509 {
        goto '__ci_bb_506
    }

    '__ci_bb_510 {
        if ((if __local_codevalue__goto_756_14 == 97: 1 else: 0) != 0) {
            goto '__ci_bb_512
        } else {
            goto '__ci_bb_513
        }
    }

    '__ci_bb_511 {
        goto '__ci_bb_509
    }

    '__ci_bb_512 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_513
    }

    '__ci_bb_513 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_514
        } else {
            goto '__ci_bb_515
        }
    }

    '__ci_bb_514 {
        (__ci_expr_old_233 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_233 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_517
        } else {
            goto '__ci_bb_518
        }
    }

    '__ci_bb_515 {
        (__ci_expr_old_234 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_234 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_520
        } else {
            goto '__ci_bb_521
        }
    }

    '__ci_bb_516 {
        goto '__ci_bb_511
    }

    '__ci_bb_517 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_519
    }

    '__ci_bb_518 {
        return -43
    }

    '__ci_bb_519 {
        goto '__ci_bb_516
    }

    '__ci_bb_520 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_522
    }

    '__ci_bb_521 {
        return -43
    }

    '__ci_bb_522 {
        goto '__ci_bb_516
    }

    '__ci_bb_523 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_524
        } else {
            goto '__ci_bb_525
        }
    }

    '__ci_bb_524 {
        (__ci_expr_old_235 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_235 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_526
        } else {
            goto '__ci_bb_527
        }
    }

    '__ci_bb_525 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_529
        } else {
            goto '__ci_bb_530
        }
    }

    '__ci_bb_526 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 4)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_528
    }

    '__ci_bb_527 {
        return -43
    }

    '__ci_bb_528 {
        goto '__ci_bb_525
    }

    '__ci_bb_529 {
        (__local_prop__goto_1450_28 = (&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize))
        goto '__ci_bb_531
    }

    '__ci_bb_530 {
        goto '__ci_bb_135
    }

    '__ci_bb_531 {
        if ((unsafe __local_code__goto_755_16[2]) == 0) {
            goto '__ci_bb_533
        } else {
            goto '__ci_bb_583
        }
    }

    '__ci_bb_532 {
        if ((if __local_OK__goto_1447_14 == (if __local_d__goto_703_15 == 16: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_595
        } else {
            goto '__ci_bb_596
        }
    }

    '__ci_bb_533 {
        (__local_chartype__goto_1448_13 = __local_prop__goto_1450_28.chartype)
        if ((if __local_chartype__goto_1448_13 == ucp_Lu: 1 else: 0) != 0) {
            (__ci_expr_logic_236 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_236 = (if (if __local_chartype__goto_1448_13 == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_236 != 0) {
            (__ci_expr_logic_237 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_237 = (if (if __local_chartype__goto_1448_13 == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1447_14 = __ci_expr_logic_237)
        goto '__ci_bb_532
    }

    '__ci_bb_534 {
        (__local_OK__goto_1447_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1450_28.chartype] == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_532
    }

    '__ci_bb_535 {
        (__local_OK__goto_1447_14 = (if __local_prop__goto_1450_28.chartype == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_532
    }

    '__ci_bb_536 {
        (__local_OK__goto_1447_14 = (if __local_prop__goto_1450_28.script == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_532
    }

    '__ci_bb_537 {
        if ((if __local_prop__goto_1450_28.script == (unsafe __local_code__goto_755_16[3]): 1 else: 0) != 0) {
            (__ci_expr_logic_238 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_238 = (if (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1450_28.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[(((unsafe __local_code__goto_755_16[3]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[3]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1447_14 = __ci_expr_logic_238)
        goto '__ci_bb_532
    }

    '__ci_bb_538 {
        (__local_chartype__goto_1448_13 = __local_prop__goto_1450_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1448_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_239 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_239 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1448_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1447_14 = __ci_expr_logic_239)
        goto '__ci_bb_532
    }

    '__ci_bb_539 {
        goto '__ci_bb_540
    }

    '__ci_bb_540 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_544
        }
    }

    '__ci_bb_541 {
        goto '__ci_bb_532
    }

    '__ci_bb_542 {
        (__local_OK__goto_1447_14 = 1)
        goto '__ci_bb_541
    }

    '__ci_bb_543 {
        (__local_OK__goto_1447_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1450_28.chartype] == 6: 1 else: 0))
        goto '__ci_bb_541
    }

    '__ci_bb_544 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_545
        }
    }

    '__ci_bb_545 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_546
        }
    }

    '__ci_bb_546 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_547
        }
    }

    '__ci_bb_547 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_548
        }
    }

    '__ci_bb_548 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_549
        }
    }

    '__ci_bb_549 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_550
        }
    }

    '__ci_bb_550 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_551
        }
    }

    '__ci_bb_551 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_552
        }
    }

    '__ci_bb_552 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_553
        }
    }

    '__ci_bb_553 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_554
        }
    }

    '__ci_bb_554 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_555
        }
    }

    '__ci_bb_555 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_556
        }
    }

    '__ci_bb_556 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_557
        }
    }

    '__ci_bb_557 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_558
        }
    }

    '__ci_bb_558 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_559
        }
    }

    '__ci_bb_559 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_560
        }
    }

    '__ci_bb_560 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_561
        }
    }

    '__ci_bb_561 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_562
        }
    }

    '__ci_bb_562 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_563
        }
    }

    '__ci_bb_563 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_564
        }
    }

    '__ci_bb_564 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_565
        }
    }

    '__ci_bb_565 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_566
        }
    }

    '__ci_bb_566 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_567
        }
    }

    '__ci_bb_567 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_568
        }
    }

    '__ci_bb_568 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_543
        }
    }

    '__ci_bb_569 {
        (__local_chartype__goto_1448_13 = __local_prop__goto_1450_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1448_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_240 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_240 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1448_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_240 != 0) {
            (__ci_expr_logic_241 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_241 = (if (if __local_chartype__goto_1448_13 == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_241 != 0) {
            (__ci_expr_logic_242 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_242 = (if (if __local_chartype__goto_1448_13 == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1447_14 = __ci_expr_logic_242)
        goto '__ci_bb_532
    }

    '__ci_bb_570 {
        (__local_cp__goto_1449_25 = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe __local_code__goto_755_16[3]) as c_uint) as usize))
        goto '__ci_bb_571
    }

    '__ci_bb_571 {
        goto '__ci_bb_572
    }

    '__ci_bb_572 {
        if ((if __local_c__goto_703_12 < (unsafe *__local_cp__goto_1449_25): 1 else: 0) != 0) {
            goto '__ci_bb_575
        } else {
            goto '__ci_bb_576
        }
    }

    '__ci_bb_573 {
        goto '__ci_bb_571
    }

    '__ci_bb_574 {
        goto '__ci_bb_532
    }

    '__ci_bb_575 {
        (__local_OK__goto_1447_14 = 0)
        goto '__ci_bb_574
    }

    '__ci_bb_576 {
        (__ci_expr_old_243 = __local_cp__goto_1449_25)
        (__local_cp__goto_1449_25 = __local_cp__goto_1449_25 + 1)
        if ((if __local_c__goto_703_12 == (unsafe *__ci_expr_old_243): 1 else: 0) != 0) {
            goto '__ci_bb_577
        } else {
            goto '__ci_bb_578
        }
    }

    '__ci_bb_577 {
        (__local_OK__goto_1447_14 = 1)
        goto '__ci_bb_574
    }

    '__ci_bb_578 {
        goto '__ci_bb_573
    }

    '__ci_bb_579 {
        if ((if __local_c__goto_703_12 == 36: 1 else: 0) != 0) {
            (__ci_expr_logic_244 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_244 = (if (if __local_c__goto_703_12 == 64: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_244 != 0) {
            (__ci_expr_logic_245 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_245 = (if (if __local_c__goto_703_12 == 96: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_245 != 0) {
            (__ci_expr_logic_247 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_246: c_int = 0

            if ((if __local_c__goto_703_12 >= 160: 1 else: 0) != 0) {
                (__ci_expr_logic_246 = (if (if __local_c__goto_703_12 <= 55295: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_247 = (if __ci_expr_logic_246 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_247 != 0) {
            (__ci_expr_logic_248 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_248 = (if (if __local_c__goto_703_12 >= 57344: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1447_14 = __ci_expr_logic_248)
        goto '__ci_bb_532
    }

    '__ci_bb_580 {
        (__local_OK__goto_1447_14 = (if ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize)).scriptx_bidiclass as c_int) >> (11 as c_uint)) == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_532
    }

    '__ci_bb_581 {
        (__local_OK__goto_1447_14 = (if (((unsafe ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1450_28.bprops as c_int) & 4095) as isize) as usize))[(((unsafe __local_code__goto_755_16[3]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[3]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0))
        goto '__ci_bb_532
    }

    '__ci_bb_582 {
        (__local_OK__goto_1447_14 = (if __local_codevalue__goto_756_14 != 16: 1 else: 0))
        goto '__ci_bb_532
    }

    '__ci_bb_583 {
        if ((unsafe __local_code__goto_755_16[2]) == 1) {
            goto '__ci_bb_534
        } else {
            goto '__ci_bb_584
        }
    }

    '__ci_bb_584 {
        if ((unsafe __local_code__goto_755_16[2]) == 2) {
            goto '__ci_bb_535
        } else {
            goto '__ci_bb_585
        }
    }

    '__ci_bb_585 {
        if ((unsafe __local_code__goto_755_16[2]) == 3) {
            goto '__ci_bb_536
        } else {
            goto '__ci_bb_586
        }
    }

    '__ci_bb_586 {
        if ((unsafe __local_code__goto_755_16[2]) == 4) {
            goto '__ci_bb_537
        } else {
            goto '__ci_bb_587
        }
    }

    '__ci_bb_587 {
        if ((unsafe __local_code__goto_755_16[2]) == 5) {
            goto '__ci_bb_538
        } else {
            goto '__ci_bb_588
        }
    }

    '__ci_bb_588 {
        if ((unsafe __local_code__goto_755_16[2]) == 6) {
            goto '__ci_bb_539
        } else {
            goto '__ci_bb_589
        }
    }

    '__ci_bb_589 {
        if ((unsafe __local_code__goto_755_16[2]) == 7) {
            goto '__ci_bb_539
        } else {
            goto '__ci_bb_590
        }
    }

    '__ci_bb_590 {
        if ((unsafe __local_code__goto_755_16[2]) == 8) {
            goto '__ci_bb_569
        } else {
            goto '__ci_bb_591
        }
    }

    '__ci_bb_591 {
        if ((unsafe __local_code__goto_755_16[2]) == 9) {
            goto '__ci_bb_570
        } else {
            goto '__ci_bb_592
        }
    }

    '__ci_bb_592 {
        if ((unsafe __local_code__goto_755_16[2]) == 10) {
            goto '__ci_bb_579
        } else {
            goto '__ci_bb_593
        }
    }

    '__ci_bb_593 {
        if ((unsafe __local_code__goto_755_16[2]) == 11) {
            goto '__ci_bb_580
        } else {
            goto '__ci_bb_594
        }
    }

    '__ci_bb_594 {
        if ((unsafe __local_code__goto_755_16[2]) == 12) {
            goto '__ci_bb_581
        } else {
            goto '__ci_bb_582
        }
    }

    '__ci_bb_595 {
        (__ci_expr_logic_249 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_249 = (if (if __local_codevalue__goto_756_14 == 395: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_249 != 0) {
            goto '__ci_bb_597
        } else {
            goto '__ci_bb_598
        }
    }

    '__ci_bb_596 {
        goto '__ci_bb_530
    }

    '__ci_bb_597 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_598
    }

    '__ci_bb_598 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_250 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_250 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_599
        } else {
            goto '__ci_bb_600
        }
    }

    '__ci_bb_599 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_601
    }

    '__ci_bb_600 {
        return -43
    }

    '__ci_bb_601 {
        goto '__ci_bb_596
    }

    '__ci_bb_602 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_603
        } else {
            goto '__ci_bb_604
        }
    }

    '__ci_bb_603 {
        (__ci_expr_old_251 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_251 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_605
        } else {
            goto '__ci_bb_606
        }
    }

    '__ci_bb_604 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_608
        } else {
            goto '__ci_bb_609
        }
    }

    '__ci_bb_605 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_607
    }

    '__ci_bb_606 {
        return -43
    }

    '__ci_bb_607 {
        goto '__ci_bb_604
    }

    '__ci_bb_608 {
        (__local_ncount__goto_1568_13 = 0)
        (__ci_expr_logic_252 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_252 = (if (if __local_codevalue__goto_756_14 == 415: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_252 != 0) {
            goto '__ci_bb_610
        } else {
            goto '__ci_bb_611
        }
    }

    '__ci_bb_609 {
        goto '__ci_bb_135
    }

    '__ci_bb_610 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_611
    }

    '__ci_bb_611 {
        _pcre2_extuni_8(__local_c__goto_703_12, (__local_ptr__goto_545_12 + ((__local_clen__goto_702_7 as isize) as usize)), __param_mb.start_subject, __local_end_subject__goto_554_12, __local_utf__goto_558_6, (&raw mut __local_ncount__goto_1568_13 as *mut c_int))
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_253 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_253 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_612
        } else {
            goto '__ci_bb_613
        }
    }

    '__ci_bb_612 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_1568_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_614
    }

    '__ci_bb_613 {
        return -43
    }

    '__ci_bb_614 {
        goto '__ci_bb_609
    }

    '__ci_bb_615 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_616
        } else {
            goto '__ci_bb_617
        }
    }

    '__ci_bb_616 {
        (__ci_expr_old_254 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_254 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_618
        } else {
            goto '__ci_bb_619
        }
    }

    '__ci_bb_617 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_621
        } else {
            goto '__ci_bb_622
        }
    }

    '__ci_bb_618 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_620
    }

    '__ci_bb_619 {
        return -43
    }

    '__ci_bb_620 {
        goto '__ci_bb_617
    }

    '__ci_bb_621 {
        (__local_ncount__goto_1590_13 = 0)
        goto '__ci_bb_623
    }

    '__ci_bb_622 {
        goto '__ci_bb_135
    }

    '__ci_bb_623 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_638
        }
    }

    '__ci_bb_624 {
        goto '__ci_bb_622
    }

    '__ci_bb_625 {
        if ((if __param_mb.bsr_convention == 2: 1 else: 0) != 0) {
            goto '__ci_bb_626
        } else {
            goto '__ci_bb_627
        }
    }

    '__ci_bb_626 {
        goto '__ci_bb_624
    }

    '__ci_bb_627 {
        goto '__ci_bb_628
    }

    '__ci_bb_628 {
        (__ci_expr_logic_256 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_256 = (if (if __local_codevalue__goto_756_14 == 435: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_256 != 0) {
            goto '__ci_bb_632
        } else {
            goto '__ci_bb_633
        }
    }

    '__ci_bb_629 {
        (__ci_expr_logic_255 = 0)
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) < __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            (__ci_expr_logic_255 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_255 != 0) {
            goto '__ci_bb_630
        } else {
            goto '__ci_bb_631
        }
    }

    '__ci_bb_630 {
        (__local_ncount__goto_1590_13 = 1)
        goto '__ci_bb_631
    }

    '__ci_bb_631 {
        goto '__ci_bb_628
    }

    '__ci_bb_632 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_633
    }

    '__ci_bb_633 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_257 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_257 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_634
        } else {
            goto '__ci_bb_635
        }
    }

    '__ci_bb_634 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_1590_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_636
    }

    '__ci_bb_635 {
        return -43
    }

    '__ci_bb_636 {
        goto '__ci_bb_624
    }

    '__ci_bb_637 {
        goto '__ci_bb_624
    }

    '__ci_bb_638 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_639
        }
    }

    '__ci_bb_639 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_640
        }
    }

    '__ci_bb_640 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_641
        }
    }

    '__ci_bb_641 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_642
        }
    }

    '__ci_bb_642 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_629
        } else {
            goto '__ci_bb_643
        }
    }

    '__ci_bb_643 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_628
        } else {
            goto '__ci_bb_637
        }
    }

    '__ci_bb_644 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_645
        } else {
            goto '__ci_bb_646
        }
    }

    '__ci_bb_645 {
        (__ci_expr_old_258 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_258 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_647
        } else {
            goto '__ci_bb_648
        }
    }

    '__ci_bb_646 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_650
        } else {
            goto '__ci_bb_651
        }
    }

    '__ci_bb_647 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_649
    }

    '__ci_bb_648 {
        return -43
    }

    '__ci_bb_649 {
        goto '__ci_bb_646
    }

    '__ci_bb_650 {
        goto '__ci_bb_652
    }

    '__ci_bb_651 {
        goto '__ci_bb_135
    }

    '__ci_bb_652 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_656
        }
    }

    '__ci_bb_653 {
        if ((if __local_OK__goto_1632_14 == (if __local_d__goto_703_15 == 21: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_662
        } else {
            goto '__ci_bb_663
        }
    }

    '__ci_bb_654 {
        (__local_OK__goto_1632_14 = 1)
        goto '__ci_bb_653
    }

    '__ci_bb_655 {
        (__local_OK__goto_1632_14 = 0)
        goto '__ci_bb_653
    }

    '__ci_bb_656 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_657
        }
    }

    '__ci_bb_657 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_658
        }
    }

    '__ci_bb_658 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_659
        }
    }

    '__ci_bb_659 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_660
        }
    }

    '__ci_bb_660 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_661
        }
    }

    '__ci_bb_661 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_655
        }
    }

    '__ci_bb_662 {
        (__ci_expr_logic_259 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_259 = (if (if __local_codevalue__goto_756_14 == 475: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_259 != 0) {
            goto '__ci_bb_664
        } else {
            goto '__ci_bb_665
        }
    }

    '__ci_bb_663 {
        goto '__ci_bb_651
    }

    '__ci_bb_664 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_665
    }

    '__ci_bb_665 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_260 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_260 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_666
        } else {
            goto '__ci_bb_667
        }
    }

    '__ci_bb_666 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_668
    }

    '__ci_bb_667 {
        return -43
    }

    '__ci_bb_668 {
        goto '__ci_bb_663
    }

    '__ci_bb_669 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_670
        } else {
            goto '__ci_bb_671
        }
    }

    '__ci_bb_670 {
        (__ci_expr_old_261 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_261 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_672
        } else {
            goto '__ci_bb_673
        }
    }

    '__ci_bb_671 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_675
        } else {
            goto '__ci_bb_676
        }
    }

    '__ci_bb_672 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_674
    }

    '__ci_bb_673 {
        return -43
    }

    '__ci_bb_674 {
        goto '__ci_bb_671
    }

    '__ci_bb_675 {
        goto '__ci_bb_677
    }

    '__ci_bb_676 {
        goto '__ci_bb_135
    }

    '__ci_bb_677 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_681
        }
    }

    '__ci_bb_678 {
        if ((if __local_OK__goto_1665_14 == (if __local_d__goto_703_15 == 19: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_699
        } else {
            goto '__ci_bb_700
        }
    }

    '__ci_bb_679 {
        (__local_OK__goto_1665_14 = 1)
        goto '__ci_bb_678
    }

    '__ci_bb_680 {
        (__local_OK__goto_1665_14 = 0)
        goto '__ci_bb_678
    }

    '__ci_bb_681 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_682
        }
    }

    '__ci_bb_682 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_683
        }
    }

    '__ci_bb_683 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_684
        }
    }

    '__ci_bb_684 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_685
        }
    }

    '__ci_bb_685 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_686
        }
    }

    '__ci_bb_686 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_687
        }
    }

    '__ci_bb_687 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_688
        }
    }

    '__ci_bb_688 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_689
        }
    }

    '__ci_bb_689 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_690
        }
    }

    '__ci_bb_690 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_691
        }
    }

    '__ci_bb_691 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_692
        }
    }

    '__ci_bb_692 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_693
        }
    }

    '__ci_bb_693 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_694
        }
    }

    '__ci_bb_694 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_695
        }
    }

    '__ci_bb_695 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_696
        }
    }

    '__ci_bb_696 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_697
        }
    }

    '__ci_bb_697 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_698
        }
    }

    '__ci_bb_698 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_679
        } else {
            goto '__ci_bb_680
        }
    }

    '__ci_bb_699 {
        (__ci_expr_logic_262 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_262 = (if (if __local_codevalue__goto_756_14 == 455: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_262 != 0) {
            goto '__ci_bb_701
        } else {
            goto '__ci_bb_702
        }
    }

    '__ci_bb_700 {
        goto '__ci_bb_676
    }

    '__ci_bb_701 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_702
    }

    '__ci_bb_702 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_263 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_263 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_703
        } else {
            goto '__ci_bb_704
        }
    }

    '__ci_bb_703 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_705
    }

    '__ci_bb_704 {
        return -43
    }

    '__ci_bb_705 {
        goto '__ci_bb_700
    }

    '__ci_bb_706 {
        (__local_count__goto_759_9 = 4)
        goto '__ci_bb_707
    }

    '__ci_bb_707 {
        (__ci_expr_old_264 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_264 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_709
        } else {
            goto '__ci_bb_710
        }
    }

    '__ci_bb_708 {
        (__local_count__goto_759_9 = 0)
        goto '__ci_bb_707
    }

    '__ci_bb_709 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 4)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_711
    }

    '__ci_bb_710 {
        return -43
    }

    '__ci_bb_711 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_712
        } else {
            goto '__ci_bb_713
        }
    }

    '__ci_bb_712 {
        (__local_prop__goto_1711_28 = (&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize))
        goto '__ci_bb_714
    }

    '__ci_bb_713 {
        goto '__ci_bb_135
    }

    '__ci_bb_714 {
        if ((unsafe __local_code__goto_755_16[2]) == 0) {
            goto '__ci_bb_716
        } else {
            goto '__ci_bb_766
        }
    }

    '__ci_bb_715 {
        if ((if __local_OK__goto_1708_14 == (if __local_d__goto_703_15 == 16: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_778
        } else {
            goto '__ci_bb_779
        }
    }

    '__ci_bb_716 {
        (__local_chartype__goto_1709_13 = __local_prop__goto_1711_28.chartype)
        if ((if __local_chartype__goto_1709_13 == ucp_Lu: 1 else: 0) != 0) {
            (__ci_expr_logic_265 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_265 = (if (if __local_chartype__goto_1709_13 == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_265 != 0) {
            (__ci_expr_logic_266 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_266 = (if (if __local_chartype__goto_1709_13 == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1708_14 = __ci_expr_logic_266)
        goto '__ci_bb_715
    }

    '__ci_bb_717 {
        (__local_OK__goto_1708_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1711_28.chartype] == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_715
    }

    '__ci_bb_718 {
        (__local_OK__goto_1708_14 = (if __local_prop__goto_1711_28.chartype == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_715
    }

    '__ci_bb_719 {
        (__local_OK__goto_1708_14 = (if __local_prop__goto_1711_28.script == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_715
    }

    '__ci_bb_720 {
        if ((if __local_prop__goto_1711_28.script == (unsafe __local_code__goto_755_16[3]): 1 else: 0) != 0) {
            (__ci_expr_logic_267 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_267 = (if (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1711_28.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[(((unsafe __local_code__goto_755_16[3]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[3]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1708_14 = __ci_expr_logic_267)
        goto '__ci_bb_715
    }

    '__ci_bb_721 {
        (__local_chartype__goto_1709_13 = __local_prop__goto_1711_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1709_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_268 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_268 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1709_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1708_14 = __ci_expr_logic_268)
        goto '__ci_bb_715
    }

    '__ci_bb_722 {
        goto '__ci_bb_723
    }

    '__ci_bb_723 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_727
        }
    }

    '__ci_bb_724 {
        goto '__ci_bb_715
    }

    '__ci_bb_725 {
        (__local_OK__goto_1708_14 = 1)
        goto '__ci_bb_724
    }

    '__ci_bb_726 {
        (__local_OK__goto_1708_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1711_28.chartype] == 6: 1 else: 0))
        goto '__ci_bb_724
    }

    '__ci_bb_727 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_728
        }
    }

    '__ci_bb_728 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_729
        }
    }

    '__ci_bb_729 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_730
        }
    }

    '__ci_bb_730 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_731
        }
    }

    '__ci_bb_731 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_732
        }
    }

    '__ci_bb_732 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_733
        }
    }

    '__ci_bb_733 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_734
        }
    }

    '__ci_bb_734 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_735
        }
    }

    '__ci_bb_735 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_736
        }
    }

    '__ci_bb_736 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_737
        }
    }

    '__ci_bb_737 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_738
        }
    }

    '__ci_bb_738 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_739
        }
    }

    '__ci_bb_739 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_740
        }
    }

    '__ci_bb_740 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_741
        }
    }

    '__ci_bb_741 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_742
        }
    }

    '__ci_bb_742 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_743
        }
    }

    '__ci_bb_743 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_744
        }
    }

    '__ci_bb_744 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_745
        }
    }

    '__ci_bb_745 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_746
        }
    }

    '__ci_bb_746 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_747
        }
    }

    '__ci_bb_747 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_748
        }
    }

    '__ci_bb_748 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_749
        }
    }

    '__ci_bb_749 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_750
        }
    }

    '__ci_bb_750 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_751
        }
    }

    '__ci_bb_751 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_726
        }
    }

    '__ci_bb_752 {
        (__local_chartype__goto_1709_13 = __local_prop__goto_1711_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1709_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_269 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_269 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1709_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_269 != 0) {
            (__ci_expr_logic_270 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_270 = (if (if __local_chartype__goto_1709_13 == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_270 != 0) {
            (__ci_expr_logic_271 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_271 = (if (if __local_chartype__goto_1709_13 == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1708_14 = __ci_expr_logic_271)
        goto '__ci_bb_715
    }

    '__ci_bb_753 {
        (__local_cp__goto_1710_25 = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe __local_code__goto_755_16[3]) as c_uint) as usize))
        goto '__ci_bb_754
    }

    '__ci_bb_754 {
        goto '__ci_bb_755
    }

    '__ci_bb_755 {
        if ((if __local_c__goto_703_12 < (unsafe *__local_cp__goto_1710_25): 1 else: 0) != 0) {
            goto '__ci_bb_758
        } else {
            goto '__ci_bb_759
        }
    }

    '__ci_bb_756 {
        goto '__ci_bb_754
    }

    '__ci_bb_757 {
        goto '__ci_bb_715
    }

    '__ci_bb_758 {
        (__local_OK__goto_1708_14 = 0)
        goto '__ci_bb_757
    }

    '__ci_bb_759 {
        (__ci_expr_old_272 = __local_cp__goto_1710_25)
        (__local_cp__goto_1710_25 = __local_cp__goto_1710_25 + 1)
        if ((if __local_c__goto_703_12 == (unsafe *__ci_expr_old_272): 1 else: 0) != 0) {
            goto '__ci_bb_760
        } else {
            goto '__ci_bb_761
        }
    }

    '__ci_bb_760 {
        (__local_OK__goto_1708_14 = 1)
        goto '__ci_bb_757
    }

    '__ci_bb_761 {
        goto '__ci_bb_756
    }

    '__ci_bb_762 {
        if ((if __local_c__goto_703_12 == 36: 1 else: 0) != 0) {
            (__ci_expr_logic_273 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_273 = (if (if __local_c__goto_703_12 == 64: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_273 != 0) {
            (__ci_expr_logic_274 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_274 = (if (if __local_c__goto_703_12 == 96: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_274 != 0) {
            (__ci_expr_logic_276 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_275: c_int = 0

            if ((if __local_c__goto_703_12 >= 160: 1 else: 0) != 0) {
                (__ci_expr_logic_275 = (if (if __local_c__goto_703_12 <= 55295: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_276 = (if __ci_expr_logic_275 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_276 != 0) {
            (__ci_expr_logic_277 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_277 = (if (if __local_c__goto_703_12 >= 57344: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1708_14 = __ci_expr_logic_277)
        goto '__ci_bb_715
    }

    '__ci_bb_763 {
        (__local_OK__goto_1708_14 = (if ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize)).scriptx_bidiclass as c_int) >> (11 as c_uint)) == (unsafe __local_code__goto_755_16[3]): 1 else: 0))
        goto '__ci_bb_715
    }

    '__ci_bb_764 {
        (__local_OK__goto_1708_14 = (if (((unsafe ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1711_28.bprops as c_int) & 4095) as isize) as usize))[(((unsafe __local_code__goto_755_16[3]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[3]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0))
        goto '__ci_bb_715
    }

    '__ci_bb_765 {
        (__local_OK__goto_1708_14 = (if __local_codevalue__goto_756_14 != 16: 1 else: 0))
        goto '__ci_bb_715
    }

    '__ci_bb_766 {
        if ((unsafe __local_code__goto_755_16[2]) == 1) {
            goto '__ci_bb_717
        } else {
            goto '__ci_bb_767
        }
    }

    '__ci_bb_767 {
        if ((unsafe __local_code__goto_755_16[2]) == 2) {
            goto '__ci_bb_718
        } else {
            goto '__ci_bb_768
        }
    }

    '__ci_bb_768 {
        if ((unsafe __local_code__goto_755_16[2]) == 3) {
            goto '__ci_bb_719
        } else {
            goto '__ci_bb_769
        }
    }

    '__ci_bb_769 {
        if ((unsafe __local_code__goto_755_16[2]) == 4) {
            goto '__ci_bb_720
        } else {
            goto '__ci_bb_770
        }
    }

    '__ci_bb_770 {
        if ((unsafe __local_code__goto_755_16[2]) == 5) {
            goto '__ci_bb_721
        } else {
            goto '__ci_bb_771
        }
    }

    '__ci_bb_771 {
        if ((unsafe __local_code__goto_755_16[2]) == 6) {
            goto '__ci_bb_722
        } else {
            goto '__ci_bb_772
        }
    }

    '__ci_bb_772 {
        if ((unsafe __local_code__goto_755_16[2]) == 7) {
            goto '__ci_bb_722
        } else {
            goto '__ci_bb_773
        }
    }

    '__ci_bb_773 {
        if ((unsafe __local_code__goto_755_16[2]) == 8) {
            goto '__ci_bb_752
        } else {
            goto '__ci_bb_774
        }
    }

    '__ci_bb_774 {
        if ((unsafe __local_code__goto_755_16[2]) == 9) {
            goto '__ci_bb_753
        } else {
            goto '__ci_bb_775
        }
    }

    '__ci_bb_775 {
        if ((unsafe __local_code__goto_755_16[2]) == 10) {
            goto '__ci_bb_762
        } else {
            goto '__ci_bb_776
        }
    }

    '__ci_bb_776 {
        if ((unsafe __local_code__goto_755_16[2]) == 11) {
            goto '__ci_bb_763
        } else {
            goto '__ci_bb_777
        }
    }

    '__ci_bb_777 {
        if ((unsafe __local_code__goto_755_16[2]) == 12) {
            goto '__ci_bb_764
        } else {
            goto '__ci_bb_765
        }
    }

    '__ci_bb_778 {
        if ((if __local_codevalue__goto_756_14 == 394: 1 else: 0) != 0) {
            (__ci_expr_logic_278 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_278 = (if (if __local_codevalue__goto_756_14 == 396: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_278 != 0) {
            goto '__ci_bb_780
        } else {
            goto '__ci_bb_781
        }
    }

    '__ci_bb_779 {
        goto '__ci_bb_713
    }

    '__ci_bb_780 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_781
    }

    '__ci_bb_781 {
        (__ci_expr_old_279 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_279 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_782
        } else {
            goto '__ci_bb_783
        }
    }

    '__ci_bb_782 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_784
    }

    '__ci_bb_783 {
        return -43
    }

    '__ci_bb_784 {
        goto '__ci_bb_779
    }

    '__ci_bb_785 {
        (__local_count__goto_759_9 = 2)
        goto '__ci_bb_786
    }

    '__ci_bb_786 {
        (__ci_expr_old_280 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_280 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_788
        } else {
            goto '__ci_bb_789
        }
    }

    '__ci_bb_787 {
        (__local_count__goto_759_9 = 0)
        goto '__ci_bb_786
    }

    '__ci_bb_788 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_790
    }

    '__ci_bb_789 {
        return -43
    }

    '__ci_bb_790 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_791
        } else {
            goto '__ci_bb_792
        }
    }

    '__ci_bb_791 {
        (__local_ncount__goto_1838_13 = 0)
        if ((if __local_codevalue__goto_756_14 == 414: 1 else: 0) != 0) {
            (__ci_expr_logic_281 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_281 = (if (if __local_codevalue__goto_756_14 == 416: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_281 != 0) {
            goto '__ci_bb_793
        } else {
            goto '__ci_bb_794
        }
    }

    '__ci_bb_792 {
        goto '__ci_bb_135
    }

    '__ci_bb_793 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_794
    }

    '__ci_bb_794 {
        _pcre2_extuni_8(__local_c__goto_703_12, (__local_ptr__goto_545_12 + ((__local_clen__goto_702_7 as isize) as usize)), __param_mb.start_subject, __local_end_subject__goto_554_12, __local_utf__goto_558_6, (&raw mut __local_ncount__goto_1838_13 as *mut c_int))
        (__ci_expr_old_282 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_282 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_795
        } else {
            goto '__ci_bb_796
        }
    }

    '__ci_bb_795 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + __local_count__goto_759_9))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_1838_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_797
    }

    '__ci_bb_796 {
        return -43
    }

    '__ci_bb_797 {
        goto '__ci_bb_792
    }

    '__ci_bb_798 {
        (__local_count__goto_759_9 = 2)
        goto '__ci_bb_799
    }

    '__ci_bb_799 {
        (__ci_expr_old_283 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_283 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_801
        } else {
            goto '__ci_bb_802
        }
    }

    '__ci_bb_800 {
        (__local_count__goto_759_9 = 0)
        goto '__ci_bb_799
    }

    '__ci_bb_801 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_803
    }

    '__ci_bb_802 {
        return -43
    }

    '__ci_bb_803 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_804
        } else {
            goto '__ci_bb_805
        }
    }

    '__ci_bb_804 {
        (__local_ncount__goto_1868_13 = 0)
        goto '__ci_bb_806
    }

    '__ci_bb_805 {
        goto '__ci_bb_135
    }

    '__ci_bb_806 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_808
        } else {
            goto '__ci_bb_821
        }
    }

    '__ci_bb_807 {
        goto '__ci_bb_805
    }

    '__ci_bb_808 {
        if ((if __param_mb.bsr_convention == 2: 1 else: 0) != 0) {
            goto '__ci_bb_809
        } else {
            goto '__ci_bb_810
        }
    }

    '__ci_bb_809 {
        goto '__ci_bb_807
    }

    '__ci_bb_810 {
        goto '__ci_bb_811
    }

    '__ci_bb_811 {
        if ((if __local_codevalue__goto_756_14 == 434: 1 else: 0) != 0) {
            (__ci_expr_logic_285 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_285 = (if (if __local_codevalue__goto_756_14 == 436: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_285 != 0) {
            goto '__ci_bb_815
        } else {
            goto '__ci_bb_816
        }
    }

    '__ci_bb_812 {
        (__ci_expr_logic_284 = 0)
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) < __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            (__ci_expr_logic_284 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_284 != 0) {
            goto '__ci_bb_813
        } else {
            goto '__ci_bb_814
        }
    }

    '__ci_bb_813 {
        (__local_ncount__goto_1868_13 = 1)
        goto '__ci_bb_814
    }

    '__ci_bb_814 {
        goto '__ci_bb_811
    }

    '__ci_bb_815 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_816
    }

    '__ci_bb_816 {
        (__ci_expr_old_286 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_286 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_817
        } else {
            goto '__ci_bb_818
        }
    }

    '__ci_bb_817 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + __local_count__goto_759_9))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_1868_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_819
    }

    '__ci_bb_818 {
        return -43
    }

    '__ci_bb_819 {
        goto '__ci_bb_807
    }

    '__ci_bb_820 {
        goto '__ci_bb_807
    }

    '__ci_bb_821 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_808
        } else {
            goto '__ci_bb_822
        }
    }

    '__ci_bb_822 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_808
        } else {
            goto '__ci_bb_823
        }
    }

    '__ci_bb_823 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_808
        } else {
            goto '__ci_bb_824
        }
    }

    '__ci_bb_824 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_808
        } else {
            goto '__ci_bb_825
        }
    }

    '__ci_bb_825 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_812
        } else {
            goto '__ci_bb_826
        }
    }

    '__ci_bb_826 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_811
        } else {
            goto '__ci_bb_820
        }
    }

    '__ci_bb_827 {
        (__local_count__goto_759_9 = 2)
        goto '__ci_bb_828
    }

    '__ci_bb_828 {
        (__ci_expr_old_287 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_287 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_830
        } else {
            goto '__ci_bb_831
        }
    }

    '__ci_bb_829 {
        (__local_count__goto_759_9 = 0)
        goto '__ci_bb_828
    }

    '__ci_bb_830 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_832
    }

    '__ci_bb_831 {
        return -43
    }

    '__ci_bb_832 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_833
        } else {
            goto '__ci_bb_834
        }
    }

    '__ci_bb_833 {
        goto '__ci_bb_835
    }

    '__ci_bb_834 {
        goto '__ci_bb_135
    }

    '__ci_bb_835 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_839
        }
    }

    '__ci_bb_836 {
        if ((if __local_OK__goto_1918_14 == (if __local_d__goto_703_15 == 21: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_845
        } else {
            goto '__ci_bb_846
        }
    }

    '__ci_bb_837 {
        (__local_OK__goto_1918_14 = 1)
        goto '__ci_bb_836
    }

    '__ci_bb_838 {
        (__local_OK__goto_1918_14 = 0)
        goto '__ci_bb_836
    }

    '__ci_bb_839 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_840
        }
    }

    '__ci_bb_840 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_841
        }
    }

    '__ci_bb_841 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_842
        }
    }

    '__ci_bb_842 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_843
        }
    }

    '__ci_bb_843 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_844
        }
    }

    '__ci_bb_844 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_837
        } else {
            goto '__ci_bb_838
        }
    }

    '__ci_bb_845 {
        if ((if __local_codevalue__goto_756_14 == 474: 1 else: 0) != 0) {
            (__ci_expr_logic_288 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_288 = (if (if __local_codevalue__goto_756_14 == 476: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_288 != 0) {
            goto '__ci_bb_847
        } else {
            goto '__ci_bb_848
        }
    }

    '__ci_bb_846 {
        goto '__ci_bb_834
    }

    '__ci_bb_847 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_848
    }

    '__ci_bb_848 {
        (__ci_expr_old_289 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_289 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_849
        } else {
            goto '__ci_bb_850
        }
    }

    '__ci_bb_849 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + __local_count__goto_759_9))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_851
    }

    '__ci_bb_850 {
        return -43
    }

    '__ci_bb_851 {
        goto '__ci_bb_846
    }

    '__ci_bb_852 {
        (__local_count__goto_759_9 = 2)
        goto '__ci_bb_853
    }

    '__ci_bb_853 {
        (__ci_expr_old_290 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_290 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_855
        } else {
            goto '__ci_bb_856
        }
    }

    '__ci_bb_854 {
        (__local_count__goto_759_9 = 0)
        goto '__ci_bb_853
    }

    '__ci_bb_855 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_857
    }

    '__ci_bb_856 {
        return -43
    }

    '__ci_bb_857 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_858
        } else {
            goto '__ci_bb_859
        }
    }

    '__ci_bb_858 {
        goto '__ci_bb_860
    }

    '__ci_bb_859 {
        goto '__ci_bb_135
    }

    '__ci_bb_860 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_864
        }
    }

    '__ci_bb_861 {
        if ((if __local_OK__goto_1958_14 == (if __local_d__goto_703_15 == 19: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_882
        } else {
            goto '__ci_bb_883
        }
    }

    '__ci_bb_862 {
        (__local_OK__goto_1958_14 = 1)
        goto '__ci_bb_861
    }

    '__ci_bb_863 {
        (__local_OK__goto_1958_14 = 0)
        goto '__ci_bb_861
    }

    '__ci_bb_864 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_865
        }
    }

    '__ci_bb_865 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_866
        }
    }

    '__ci_bb_866 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_867
        }
    }

    '__ci_bb_867 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_868
        }
    }

    '__ci_bb_868 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_869
        }
    }

    '__ci_bb_869 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_870
        }
    }

    '__ci_bb_870 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_871
        }
    }

    '__ci_bb_871 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_872
        }
    }

    '__ci_bb_872 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_873
        }
    }

    '__ci_bb_873 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_874
        }
    }

    '__ci_bb_874 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_875
        }
    }

    '__ci_bb_875 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_876
        }
    }

    '__ci_bb_876 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_877
        }
    }

    '__ci_bb_877 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_878
        }
    }

    '__ci_bb_878 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_879
        }
    }

    '__ci_bb_879 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_880
        }
    }

    '__ci_bb_880 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_881
        }
    }

    '__ci_bb_881 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_863
        }
    }

    '__ci_bb_882 {
        if ((if __local_codevalue__goto_756_14 == 454: 1 else: 0) != 0) {
            (__ci_expr_logic_291 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_291 = (if (if __local_codevalue__goto_756_14 == 456: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_291 != 0) {
            goto '__ci_bb_884
        } else {
            goto '__ci_bb_885
        }
    }

    '__ci_bb_883 {
        goto '__ci_bb_859
    }

    '__ci_bb_884 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_885
    }

    '__ci_bb_885 {
        (__ci_expr_old_292 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_292 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_886
        } else {
            goto '__ci_bb_887
        }
    }

    '__ci_bb_886 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + __local_count__goto_759_9))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_888
    }

    '__ci_bb_887 {
        return -43
    }

    '__ci_bb_888 {
        goto '__ci_bb_883
    }

    '__ci_bb_889 {
        if ((if __local_codevalue__goto_756_14 != 393: 1 else: 0) != 0) {
            goto '__ci_bb_890
        } else {
            goto '__ci_bb_891
        }
    }

    '__ci_bb_890 {
        (__ci_expr_old_293 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_293 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_892
        } else {
            goto '__ci_bb_893
        }
    }

    '__ci_bb_891 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_895
        } else {
            goto '__ci_bb_896
        }
    }

    '__ci_bb_892 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((__local_state_offset__goto_757_9 + 1) + 2) + 3)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_894
    }

    '__ci_bb_893 {
        return -43
    }

    '__ci_bb_894 {
        goto '__ci_bb_891
    }

    '__ci_bb_895 {
        (__local_prop__goto_1997_28 = (&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize))
        goto '__ci_bb_897
    }

    '__ci_bb_896 {
        goto '__ci_bb_135
    }

    '__ci_bb_897 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 0) {
            goto '__ci_bb_899
        } else {
            goto '__ci_bb_949
        }
    }

    '__ci_bb_898 {
        if ((if __local_OK__goto_1994_14 == (if __local_d__goto_703_15 == 16: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_961
        } else {
            goto '__ci_bb_962
        }
    }

    '__ci_bb_899 {
        (__local_chartype__goto_1995_13 = __local_prop__goto_1997_28.chartype)
        if ((if __local_chartype__goto_1995_13 == ucp_Lu: 1 else: 0) != 0) {
            (__ci_expr_logic_294 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_294 = (if (if __local_chartype__goto_1995_13 == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_294 != 0) {
            (__ci_expr_logic_295 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_295 = (if (if __local_chartype__goto_1995_13 == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1994_14 = __ci_expr_logic_295)
        goto '__ci_bb_898
    }

    '__ci_bb_900 {
        (__local_OK__goto_1994_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1997_28.chartype] == (unsafe __local_code__goto_755_16[((1 + 2) + 2)]): 1 else: 0))
        goto '__ci_bb_898
    }

    '__ci_bb_901 {
        (__local_OK__goto_1994_14 = (if __local_prop__goto_1997_28.chartype == (unsafe __local_code__goto_755_16[((1 + 2) + 2)]): 1 else: 0))
        goto '__ci_bb_898
    }

    '__ci_bb_902 {
        (__local_OK__goto_1994_14 = (if __local_prop__goto_1997_28.script == (unsafe __local_code__goto_755_16[((1 + 2) + 2)]): 1 else: 0))
        goto '__ci_bb_898
    }

    '__ci_bb_903 {
        if ((if __local_prop__goto_1997_28.script == (unsafe __local_code__goto_755_16[((1 + 2) + 2)]): 1 else: 0) != 0) {
            (__ci_expr_logic_296 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_296 = (if (if (((unsafe ((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1997_28.scriptx_bidiclass as c_int) & 1023) as isize) as usize))[(((unsafe __local_code__goto_755_16[((1 + 2) + 2)]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[((1 + 2) + 2)]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1994_14 = __ci_expr_logic_296)
        goto '__ci_bb_898
    }

    '__ci_bb_904 {
        (__local_chartype__goto_1995_13 = __local_prop__goto_1997_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1995_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_297 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_297 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1995_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1994_14 = __ci_expr_logic_297)
        goto '__ci_bb_898
    }

    '__ci_bb_905 {
        goto '__ci_bb_906
    }

    '__ci_bb_906 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_910
        }
    }

    '__ci_bb_907 {
        goto '__ci_bb_898
    }

    '__ci_bb_908 {
        (__local_OK__goto_1994_14 = 1)
        goto '__ci_bb_907
    }

    '__ci_bb_909 {
        (__local_OK__goto_1994_14 = (if _pcre2_ucp_gentype_8[__local_prop__goto_1997_28.chartype] == 6: 1 else: 0))
        goto '__ci_bb_907
    }

    '__ci_bb_910 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_911
        }
    }

    '__ci_bb_911 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_912
        }
    }

    '__ci_bb_912 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_913
        }
    }

    '__ci_bb_913 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_914
        }
    }

    '__ci_bb_914 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_915
        }
    }

    '__ci_bb_915 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_916
        }
    }

    '__ci_bb_916 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_917
        }
    }

    '__ci_bb_917 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_918
        }
    }

    '__ci_bb_918 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_919
        }
    }

    '__ci_bb_919 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_920
        }
    }

    '__ci_bb_920 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_921
        }
    }

    '__ci_bb_921 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_922
        }
    }

    '__ci_bb_922 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_923
        }
    }

    '__ci_bb_923 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_924
        }
    }

    '__ci_bb_924 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_925
        }
    }

    '__ci_bb_925 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_926
        }
    }

    '__ci_bb_926 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_927
        }
    }

    '__ci_bb_927 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_928
        }
    }

    '__ci_bb_928 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_929
        }
    }

    '__ci_bb_929 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_930
        }
    }

    '__ci_bb_930 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_931
        }
    }

    '__ci_bb_931 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_932
        }
    }

    '__ci_bb_932 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_933
        }
    }

    '__ci_bb_933 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_934
        }
    }

    '__ci_bb_934 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_908
        } else {
            goto '__ci_bb_909
        }
    }

    '__ci_bb_935 {
        (__local_chartype__goto_1995_13 = __local_prop__goto_1997_28.chartype)
        if ((if _pcre2_ucp_gentype_8[__local_chartype__goto_1995_13] == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_298 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_298 = (if (if _pcre2_ucp_gentype_8[__local_chartype__goto_1995_13] == 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_298 != 0) {
            (__ci_expr_logic_299 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_299 = (if (if __local_chartype__goto_1995_13 == ucp_Mn: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_299 != 0) {
            (__ci_expr_logic_300 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_300 = (if (if __local_chartype__goto_1995_13 == ucp_Pc: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1994_14 = __ci_expr_logic_300)
        goto '__ci_bb_898
    }

    '__ci_bb_936 {
        (__local_cp__goto_1996_25 = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe __local_code__goto_755_16[((1 + 2) + 2)]) as c_uint) as usize))
        goto '__ci_bb_937
    }

    '__ci_bb_937 {
        goto '__ci_bb_938
    }

    '__ci_bb_938 {
        if ((if __local_c__goto_703_12 < (unsafe *__local_cp__goto_1996_25): 1 else: 0) != 0) {
            goto '__ci_bb_941
        } else {
            goto '__ci_bb_942
        }
    }

    '__ci_bb_939 {
        goto '__ci_bb_937
    }

    '__ci_bb_940 {
        goto '__ci_bb_898
    }

    '__ci_bb_941 {
        (__local_OK__goto_1994_14 = 0)
        goto '__ci_bb_940
    }

    '__ci_bb_942 {
        (__ci_expr_old_301 = __local_cp__goto_1996_25)
        (__local_cp__goto_1996_25 = __local_cp__goto_1996_25 + 1)
        if ((if __local_c__goto_703_12 == (unsafe *__ci_expr_old_301): 1 else: 0) != 0) {
            goto '__ci_bb_943
        } else {
            goto '__ci_bb_944
        }
    }

    '__ci_bb_943 {
        (__local_OK__goto_1994_14 = 1)
        goto '__ci_bb_940
    }

    '__ci_bb_944 {
        goto '__ci_bb_939
    }

    '__ci_bb_945 {
        if ((if __local_c__goto_703_12 == 36: 1 else: 0) != 0) {
            (__ci_expr_logic_302 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_302 = (if (if __local_c__goto_703_12 == 64: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_302 != 0) {
            (__ci_expr_logic_303 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_303 = (if (if __local_c__goto_703_12 == 96: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_303 != 0) {
            (__ci_expr_logic_305 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_304: c_int = 0

            if ((if __local_c__goto_703_12 >= 160: 1 else: 0) != 0) {
                (__ci_expr_logic_304 = (if (if __local_c__goto_703_12 <= 55295: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_305 = (if __ci_expr_logic_304 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_305 != 0) {
            (__ci_expr_logic_306 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_306 = (if (if __local_c__goto_703_12 >= 57344: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_OK__goto_1994_14 = __ci_expr_logic_306)
        goto '__ci_bb_898
    }

    '__ci_bb_946 {
        (__local_OK__goto_1994_14 = (if ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize)).scriptx_bidiclass as c_int) >> (11 as c_uint)) == (unsafe __local_code__goto_755_16[((1 + 2) + 2)]): 1 else: 0))
        goto '__ci_bb_898
    }

    '__ci_bb_947 {
        (__local_OK__goto_1994_14 = (if (((unsafe ((&_pcre2_ucd_boolprop_sets_8[0] as *const c_uint) + ((((__local_prop__goto_1997_28.bprops as c_int) & 4095) as isize) as usize))[(((unsafe __local_code__goto_755_16[((1 + 2) + 2)]) as c_int) / 32)]) as c_uint) & (((1 as c_uint) << ((((unsafe __local_code__goto_755_16[((1 + 2) + 2)]) as c_int) % 32) as c_uint)) as c_uint)) != 0: 1 else: 0))
        goto '__ci_bb_898
    }

    '__ci_bb_948 {
        (__local_OK__goto_1994_14 = (if __local_codevalue__goto_756_14 != 16: 1 else: 0))
        goto '__ci_bb_898
    }

    '__ci_bb_949 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 1) {
            goto '__ci_bb_900
        } else {
            goto '__ci_bb_950
        }
    }

    '__ci_bb_950 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 2) {
            goto '__ci_bb_901
        } else {
            goto '__ci_bb_951
        }
    }

    '__ci_bb_951 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 3) {
            goto '__ci_bb_902
        } else {
            goto '__ci_bb_952
        }
    }

    '__ci_bb_952 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 4) {
            goto '__ci_bb_903
        } else {
            goto '__ci_bb_953
        }
    }

    '__ci_bb_953 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 5) {
            goto '__ci_bb_904
        } else {
            goto '__ci_bb_954
        }
    }

    '__ci_bb_954 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 6) {
            goto '__ci_bb_905
        } else {
            goto '__ci_bb_955
        }
    }

    '__ci_bb_955 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 7) {
            goto '__ci_bb_905
        } else {
            goto '__ci_bb_956
        }
    }

    '__ci_bb_956 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 8) {
            goto '__ci_bb_935
        } else {
            goto '__ci_bb_957
        }
    }

    '__ci_bb_957 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 9) {
            goto '__ci_bb_936
        } else {
            goto '__ci_bb_958
        }
    }

    '__ci_bb_958 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 10) {
            goto '__ci_bb_945
        } else {
            goto '__ci_bb_959
        }
    }

    '__ci_bb_959 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 11) {
            goto '__ci_bb_946
        } else {
            goto '__ci_bb_960
        }
    }

    '__ci_bb_960 {
        if ((unsafe __local_code__goto_755_16[((1 + 2) + 1)]) == 12) {
            goto '__ci_bb_947
        } else {
            goto '__ci_bb_948
        }
    }

    '__ci_bb_961 {
        if ((if __local_codevalue__goto_756_14 == 397: 1 else: 0) != 0) {
            goto '__ci_bb_963
        } else {
            goto '__ci_bb_964
        }
    }

    '__ci_bb_962 {
        goto '__ci_bb_896
    }

    '__ci_bb_963 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_964
    }

    '__ci_bb_964 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_965
        } else {
            goto '__ci_bb_966
        }
    }

    '__ci_bb_965 {
        (__ci_expr_old_307 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_307 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_968
        } else {
            goto '__ci_bb_969
        }
    }

    '__ci_bb_966 {
        (__ci_expr_old_308 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_308 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_971
        } else {
            goto '__ci_bb_972
        }
    }

    '__ci_bb_967 {
        goto '__ci_bb_962
    }

    '__ci_bb_968 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = ((__local_state_offset__goto_757_9 + 1) + 2) + 3)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_970
    }

    '__ci_bb_969 {
        return -43
    }

    '__ci_bb_970 {
        goto '__ci_bb_967
    }

    '__ci_bb_971 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_973
    }

    '__ci_bb_972 {
        return -43
    }

    '__ci_bb_973 {
        goto '__ci_bb_967
    }

    '__ci_bb_974 {
        if ((if __local_codevalue__goto_756_14 != 413: 1 else: 0) != 0) {
            goto '__ci_bb_975
        } else {
            goto '__ci_bb_976
        }
    }

    '__ci_bb_975 {
        (__ci_expr_old_309 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_309 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_977
        } else {
            goto '__ci_bb_978
        }
    }

    '__ci_bb_976 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_980
        } else {
            goto '__ci_bb_981
        }
    }

    '__ci_bb_977 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_979
    }

    '__ci_bb_978 {
        return -43
    }

    '__ci_bb_979 {
        goto '__ci_bb_976
    }

    '__ci_bb_980 {
        (__local_ncount__goto_2121_13 = 0)
        if ((if __local_codevalue__goto_756_14 == 417: 1 else: 0) != 0) {
            goto '__ci_bb_982
        } else {
            goto '__ci_bb_983
        }
    }

    '__ci_bb_981 {
        goto '__ci_bb_135
    }

    '__ci_bb_982 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_983
    }

    '__ci_bb_983 {
        (__local_nptr__goto_2120_20 = _pcre2_extuni_8(__local_c__goto_703_12, (__local_ptr__goto_545_12 + ((__local_clen__goto_702_7 as isize) as usize)), __param_mb.start_subject, __local_end_subject__goto_554_12, __local_utf__goto_558_6, (&raw mut __local_ncount__goto_2121_13 as *mut c_int)))
        (__ci_expr_logic_310 = 0)
        if ((if __local_nptr__goto_2120_20 >= __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            (__ci_expr_logic_310 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_310 != 0) {
            goto '__ci_bb_984
        } else {
            goto '__ci_bb_985
        }
    }

    '__ci_bb_984 {
        (__local_reset_could_continue__goto_564_6 = 1)
        goto '__ci_bb_985
    }

    '__ci_bb_985 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_986
        } else {
            goto '__ci_bb_987
        }
    }

    '__ci_bb_986 {
        (__ci_expr_old_311 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_311 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_989
        } else {
            goto '__ci_bb_990
        }
    }

    '__ci_bb_987 {
        (__ci_expr_old_312 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_312 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_992
        } else {
            goto '__ci_bb_993
        }
    }

    '__ci_bb_988 {
        goto '__ci_bb_981
    }

    '__ci_bb_989 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - ((__local_state_offset__goto_757_9 + 2) + 2))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_2121_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_991
    }

    '__ci_bb_990 {
        return -43
    }

    '__ci_bb_991 {
        goto '__ci_bb_988
    }

    '__ci_bb_992 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_2121_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_994
    }

    '__ci_bb_993 {
        return -43
    }

    '__ci_bb_994 {
        goto '__ci_bb_988
    }

    '__ci_bb_995 {
        if ((if __local_codevalue__goto_756_14 != 433: 1 else: 0) != 0) {
            goto '__ci_bb_996
        } else {
            goto '__ci_bb_997
        }
    }

    '__ci_bb_996 {
        (__ci_expr_old_313 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_313 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_998
        } else {
            goto '__ci_bb_999
        }
    }

    '__ci_bb_997 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1001
        } else {
            goto '__ci_bb_1002
        }
    }

    '__ci_bb_998 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1000
    }

    '__ci_bb_999 {
        return -43
    }

    '__ci_bb_1000 {
        goto '__ci_bb_997
    }

    '__ci_bb_1001 {
        (__local_ncount__goto_2149_13 = 0)
        goto '__ci_bb_1003
    }

    '__ci_bb_1002 {
        goto '__ci_bb_135
    }

    '__ci_bb_1003 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_1005
        } else {
            goto '__ci_bb_1024
        }
    }

    '__ci_bb_1004 {
        goto '__ci_bb_1002
    }

    '__ci_bb_1005 {
        if ((if __param_mb.bsr_convention == 2: 1 else: 0) != 0) {
            goto '__ci_bb_1006
        } else {
            goto '__ci_bb_1007
        }
    }

    '__ci_bb_1006 {
        goto '__ci_bb_1004
    }

    '__ci_bb_1007 {
        goto '__ci_bb_1008
    }

    '__ci_bb_1008 {
        if ((if __local_codevalue__goto_756_14 == 437: 1 else: 0) != 0) {
            goto '__ci_bb_1012
        } else {
            goto '__ci_bb_1013
        }
    }

    '__ci_bb_1009 {
        (__ci_expr_logic_314 = 0)
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) < __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            (__ci_expr_logic_314 = (if (if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_314 != 0) {
            goto '__ci_bb_1010
        } else {
            goto '__ci_bb_1011
        }
    }

    '__ci_bb_1010 {
        (__local_ncount__goto_2149_13 = 1)
        goto '__ci_bb_1011
    }

    '__ci_bb_1011 {
        goto '__ci_bb_1008
    }

    '__ci_bb_1012 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1013
    }

    '__ci_bb_1013 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_1014
        } else {
            goto '__ci_bb_1015
        }
    }

    '__ci_bb_1014 {
        (__ci_expr_old_315 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_315 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1017
        } else {
            goto '__ci_bb_1018
        }
    }

    '__ci_bb_1015 {
        (__ci_expr_old_316 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_316 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1020
        } else {
            goto '__ci_bb_1021
        }
    }

    '__ci_bb_1016 {
        goto '__ci_bb_1004
    }

    '__ci_bb_1017 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - ((__local_state_offset__goto_757_9 + 2) + 2))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_2149_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1019
    }

    '__ci_bb_1018 {
        return -43
    }

    '__ci_bb_1019 {
        goto '__ci_bb_1016
    }

    '__ci_bb_1020 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_2149_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1022
    }

    '__ci_bb_1021 {
        return -43
    }

    '__ci_bb_1022 {
        goto '__ci_bb_1016
    }

    '__ci_bb_1023 {
        goto '__ci_bb_1004
    }

    '__ci_bb_1024 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_1005
        } else {
            goto '__ci_bb_1025
        }
    }

    '__ci_bb_1025 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_1005
        } else {
            goto '__ci_bb_1026
        }
    }

    '__ci_bb_1026 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_1005
        } else {
            goto '__ci_bb_1027
        }
    }

    '__ci_bb_1027 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_1005
        } else {
            goto '__ci_bb_1028
        }
    }

    '__ci_bb_1028 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_1009
        } else {
            goto '__ci_bb_1029
        }
    }

    '__ci_bb_1029 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_1008
        } else {
            goto '__ci_bb_1023
        }
    }

    '__ci_bb_1030 {
        if ((if __local_codevalue__goto_756_14 != 473: 1 else: 0) != 0) {
            goto '__ci_bb_1031
        } else {
            goto '__ci_bb_1032
        }
    }

    '__ci_bb_1031 {
        (__ci_expr_old_317 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_317 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1033
        } else {
            goto '__ci_bb_1034
        }
    }

    '__ci_bb_1032 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1036
        } else {
            goto '__ci_bb_1037
        }
    }

    '__ci_bb_1033 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1035
    }

    '__ci_bb_1034 {
        return -43
    }

    '__ci_bb_1035 {
        goto '__ci_bb_1032
    }

    '__ci_bb_1036 {
        goto '__ci_bb_1038
    }

    '__ci_bb_1037 {
        goto '__ci_bb_135
    }

    '__ci_bb_1038 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1042
        }
    }

    '__ci_bb_1039 {
        if ((if __local_OK__goto_2195_14 == (if __local_d__goto_703_15 == 21: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1048
        } else {
            goto '__ci_bb_1049
        }
    }

    '__ci_bb_1040 {
        (__local_OK__goto_2195_14 = 1)
        goto '__ci_bb_1039
    }

    '__ci_bb_1041 {
        (__local_OK__goto_2195_14 = 0)
        goto '__ci_bb_1039
    }

    '__ci_bb_1042 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1043
        }
    }

    '__ci_bb_1043 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1044
        }
    }

    '__ci_bb_1044 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1045
        }
    }

    '__ci_bb_1045 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1046
        }
    }

    '__ci_bb_1046 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1047
        }
    }

    '__ci_bb_1047 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_1040
        } else {
            goto '__ci_bb_1041
        }
    }

    '__ci_bb_1048 {
        if ((if __local_codevalue__goto_756_14 == 477: 1 else: 0) != 0) {
            goto '__ci_bb_1050
        } else {
            goto '__ci_bb_1051
        }
    }

    '__ci_bb_1049 {
        goto '__ci_bb_1037
    }

    '__ci_bb_1050 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1051
    }

    '__ci_bb_1051 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_1052
        } else {
            goto '__ci_bb_1053
        }
    }

    '__ci_bb_1052 {
        (__ci_expr_old_318 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_318 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1055
        } else {
            goto '__ci_bb_1056
        }
    }

    '__ci_bb_1053 {
        (__ci_expr_old_319 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_319 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1058
        } else {
            goto '__ci_bb_1059
        }
    }

    '__ci_bb_1054 {
        goto '__ci_bb_1049
    }

    '__ci_bb_1055 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - ((__local_state_offset__goto_757_9 + 2) + 2))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1057
    }

    '__ci_bb_1056 {
        return -43
    }

    '__ci_bb_1057 {
        goto '__ci_bb_1054
    }

    '__ci_bb_1058 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1060
    }

    '__ci_bb_1059 {
        return -43
    }

    '__ci_bb_1060 {
        goto '__ci_bb_1054
    }

    '__ci_bb_1061 {
        if ((if __local_codevalue__goto_756_14 != 453: 1 else: 0) != 0) {
            goto '__ci_bb_1062
        } else {
            goto '__ci_bb_1063
        }
    }

    '__ci_bb_1062 {
        (__ci_expr_old_320 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_320 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1064
        } else {
            goto '__ci_bb_1065
        }
    }

    '__ci_bb_1063 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1067
        } else {
            goto '__ci_bb_1068
        }
    }

    '__ci_bb_1064 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1066
    }

    '__ci_bb_1065 {
        return -43
    }

    '__ci_bb_1066 {
        goto '__ci_bb_1063
    }

    '__ci_bb_1067 {
        goto '__ci_bb_1069
    }

    '__ci_bb_1068 {
        goto '__ci_bb_135
    }

    '__ci_bb_1069 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1073
        }
    }

    '__ci_bb_1070 {
        if ((if __local_OK__goto_2231_14 == (if __local_d__goto_703_15 == 19: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1091
        } else {
            goto '__ci_bb_1092
        }
    }

    '__ci_bb_1071 {
        (__local_OK__goto_2231_14 = 1)
        goto '__ci_bb_1070
    }

    '__ci_bb_1072 {
        (__local_OK__goto_2231_14 = 0)
        goto '__ci_bb_1070
    }

    '__ci_bb_1073 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1074
        }
    }

    '__ci_bb_1074 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1075
        }
    }

    '__ci_bb_1075 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1076
        }
    }

    '__ci_bb_1076 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1077
        }
    }

    '__ci_bb_1077 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1078
        }
    }

    '__ci_bb_1078 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1079
        }
    }

    '__ci_bb_1079 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1080
        }
    }

    '__ci_bb_1080 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1081
        }
    }

    '__ci_bb_1081 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1082
        }
    }

    '__ci_bb_1082 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1083
        }
    }

    '__ci_bb_1083 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1084
        }
    }

    '__ci_bb_1084 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1085
        }
    }

    '__ci_bb_1085 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1086
        }
    }

    '__ci_bb_1086 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1087
        }
    }

    '__ci_bb_1087 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1088
        }
    }

    '__ci_bb_1088 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1089
        }
    }

    '__ci_bb_1089 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1090
        }
    }

    '__ci_bb_1090 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_1071
        } else {
            goto '__ci_bb_1072
        }
    }

    '__ci_bb_1091 {
        if ((if __local_codevalue__goto_756_14 == 457: 1 else: 0) != 0) {
            goto '__ci_bb_1093
        } else {
            goto '__ci_bb_1094
        }
    }

    '__ci_bb_1092 {
        goto '__ci_bb_1068
    }

    '__ci_bb_1093 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1094
    }

    '__ci_bb_1094 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_1095
        } else {
            goto '__ci_bb_1096
        }
    }

    '__ci_bb_1095 {
        (__ci_expr_old_321 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_321 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1098
        } else {
            goto '__ci_bb_1099
        }
    }

    '__ci_bb_1096 {
        (__ci_expr_old_322 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_322 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1101
        } else {
            goto '__ci_bb_1102
        }
    }

    '__ci_bb_1097 {
        goto '__ci_bb_1092
    }

    '__ci_bb_1098 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - ((__local_state_offset__goto_757_9 + 2) + 2))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1100
    }

    '__ci_bb_1099 {
        return -43
    }

    '__ci_bb_1100 {
        goto '__ci_bb_1097
    }

    '__ci_bb_1101 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        ((unsafe *__local_next_new_state__goto_543_33).data = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1103
    }

    '__ci_bb_1102 {
        return -43
    }

    '__ci_bb_1103 {
        goto '__ci_bb_1097
    }

    '__ci_bb_1104 {
        (__ci_expr_logic_323 = 0)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_323 = (if (if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_323 != 0) {
            goto '__ci_bb_1105
        } else {
            goto '__ci_bb_1106
        }
    }

    '__ci_bb_1105 {
        (__ci_expr_old_324 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_324 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1107
        } else {
            goto '__ci_bb_1108
        }
    }

    '__ci_bb_1106 {
        goto '__ci_bb_135
    }

    '__ci_bb_1107 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1109
    }

    '__ci_bb_1108 {
        return -43
    }

    '__ci_bb_1109 {
        goto '__ci_bb_1106
    }

    '__ci_bb_1110 {
        if ((if __local_clen__goto_702_7 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_1111
        } else {
            goto '__ci_bb_1112
        }
    }

    '__ci_bb_1111 {
        goto '__ci_bb_135
    }

    '__ci_bb_1112 {
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            goto '__ci_bb_1113
        } else {
            goto '__ci_bb_1114
        }
    }

    '__ci_bb_1113 {
        if ((if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0) {
            goto '__ci_bb_1116
        } else {
            goto '__ci_bb_1117
        }
    }

    '__ci_bb_1114 {
        if ((if (unsafe __local_lcc__goto_544_25[__local_c__goto_703_12]) == (unsafe __local_lcc__goto_544_25[__local_d__goto_703_15]): 1 else: 0) != 0) {
            goto '__ci_bb_1130
        } else {
            goto '__ci_bb_1131
        }
    }

    '__ci_bb_1115 {
        goto '__ci_bb_135
    }

    '__ci_bb_1116 {
        (__ci_expr_old_325 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_325 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1119
        } else {
            goto '__ci_bb_1120
        }
    }

    '__ci_bb_1117 {
        if ((if __local_c__goto_703_12 < 128: 1 else: 0) != 0) {
            goto '__ci_bb_1122
        } else {
            goto '__ci_bb_1123
        }
    }

    '__ci_bb_1118 {
        goto '__ci_bb_1115
    }

    '__ci_bb_1119 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1121
    }

    '__ci_bb_1120 {
        return -43
    }

    '__ci_bb_1121 {
        goto '__ci_bb_1118
    }

    '__ci_bb_1122 {
        (__local_othercase__goto_2278_24 = (unsafe __local_fcc__goto_544_31[__local_c__goto_703_12]))
        goto '__ci_bb_1124
    }

    '__ci_bb_1123 {
        (__local_othercase__goto_2278_24 = ((((__local_c__goto_703_12 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_703_12 as c_int) / 128)] as c_int) * 128) + ((__local_c__goto_703_12 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1124
    }

    '__ci_bb_1124 {
        if ((if __local_d__goto_703_15 == __local_othercase__goto_2278_24: 1 else: 0) != 0) {
            goto '__ci_bb_1125
        } else {
            goto '__ci_bb_1126
        }
    }

    '__ci_bb_1125 {
        (__ci_expr_old_326 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_326 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1127
        } else {
            goto '__ci_bb_1128
        }
    }

    '__ci_bb_1126 {
        goto '__ci_bb_1118
    }

    '__ci_bb_1127 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1129
    }

    '__ci_bb_1128 {
        return -43
    }

    '__ci_bb_1129 {
        goto '__ci_bb_1126
    }

    '__ci_bb_1130 {
        (__ci_expr_old_327 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_327 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1132
        } else {
            goto '__ci_bb_1133
        }
    }

    '__ci_bb_1131 {
        goto '__ci_bb_1115
    }

    '__ci_bb_1132 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 2)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1134
    }

    '__ci_bb_1133 {
        return -43
    }

    '__ci_bb_1134 {
        goto '__ci_bb_1131
    }

    '__ci_bb_1135 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1136
        } else {
            goto '__ci_bb_1137
        }
    }

    '__ci_bb_1136 {
        (__local_ncount__goto_2305_13 = 0)
        (__local_nptr__goto_2306_20 = _pcre2_extuni_8(__local_c__goto_703_12, (__local_ptr__goto_545_12 + ((__local_clen__goto_702_7 as isize) as usize)), __param_mb.start_subject, __local_end_subject__goto_554_12, __local_utf__goto_558_6, (&raw mut __local_ncount__goto_2305_13 as *mut c_int)))
        (__ci_expr_logic_328 = 0)
        if ((if __local_nptr__goto_2306_20 >= __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            (__ci_expr_logic_328 = (if (if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_328 != 0) {
            goto '__ci_bb_1138
        } else {
            goto '__ci_bb_1139
        }
    }

    '__ci_bb_1137 {
        goto '__ci_bb_135
    }

    '__ci_bb_1138 {
        (__local_reset_could_continue__goto_564_6 = 1)
        goto '__ci_bb_1139
    }

    '__ci_bb_1139 {
        (__ci_expr_old_329 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_329 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1140
        } else {
            goto '__ci_bb_1141
        }
    }

    '__ci_bb_1140 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + 1))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = __local_ncount__goto_2305_13)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1142
    }

    '__ci_bb_1141 {
        return -43
    }

    '__ci_bb_1142 {
        goto '__ci_bb_1137
    }

    '__ci_bb_1143 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1144
        } else {
            goto '__ci_bb_1145
        }
    }

    '__ci_bb_1144 {
        goto '__ci_bb_1146
    }

    '__ci_bb_1145 {
        goto '__ci_bb_135
    }

    '__ci_bb_1146 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_1148
        } else {
            goto '__ci_bb_1173
        }
    }

    '__ci_bb_1147 {
        goto '__ci_bb_1145
    }

    '__ci_bb_1148 {
        if ((if __param_mb.bsr_convention == 2: 1 else: 0) != 0) {
            goto '__ci_bb_1149
        } else {
            goto '__ci_bb_1150
        }
    }

    '__ci_bb_1149 {
        goto '__ci_bb_1147
    }

    '__ci_bb_1150 {
        goto '__ci_bb_1151
    }

    '__ci_bb_1151 {
        (__ci_expr_old_330 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_330 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1152
        } else {
            goto '__ci_bb_1153
        }
    }

    '__ci_bb_1152 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1154
    }

    '__ci_bb_1153 {
        return -43
    }

    '__ci_bb_1154 {
        goto '__ci_bb_1147
    }

    '__ci_bb_1155 {
        if ((if (__local_ptr__goto_545_12 + ((1 as isize) as usize)) >= __local_end_subject__goto_554_12: 1 else: 0) != 0) {
            goto '__ci_bb_1156
        } else {
            goto '__ci_bb_1157
        }
    }

    '__ci_bb_1156 {
        (__ci_expr_old_331 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_331 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1159
        } else {
            goto '__ci_bb_1160
        }
    }

    '__ci_bb_1157 {
        if ((if (unsafe *(__local_ptr__goto_545_12 + ((1 as isize) as usize))) == 10: 1 else: 0) != 0) {
            goto '__ci_bb_1164
        } else {
            goto '__ci_bb_1165
        }
    }

    '__ci_bb_1158 {
        goto '__ci_bb_1147
    }

    '__ci_bb_1159 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1161
    }

    '__ci_bb_1160 {
        return -43
    }

    '__ci_bb_1161 {
        if ((if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1162
        } else {
            goto '__ci_bb_1163
        }
    }

    '__ci_bb_1162 {
        (__local_reset_could_continue__goto_564_6 = 1)
        goto '__ci_bb_1163
    }

    '__ci_bb_1163 {
        goto '__ci_bb_1158
    }

    '__ci_bb_1164 {
        (__ci_expr_old_332 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_332 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1167
        } else {
            goto '__ci_bb_1168
        }
    }

    '__ci_bb_1165 {
        (__ci_expr_old_333 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_333 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1170
        } else {
            goto '__ci_bb_1171
        }
    }

    '__ci_bb_1166 {
        goto '__ci_bb_1158
    }

    '__ci_bb_1167 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - (__local_state_offset__goto_757_9 + 1))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = 1)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1169
    }

    '__ci_bb_1168 {
        return -43
    }

    '__ci_bb_1169 {
        goto '__ci_bb_1166
    }

    '__ci_bb_1170 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1172
    }

    '__ci_bb_1171 {
        return -43
    }

    '__ci_bb_1172 {
        goto '__ci_bb_1166
    }

    '__ci_bb_1173 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_1148
        } else {
            goto '__ci_bb_1174
        }
    }

    '__ci_bb_1174 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_1148
        } else {
            goto '__ci_bb_1175
        }
    }

    '__ci_bb_1175 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_1148
        } else {
            goto '__ci_bb_1176
        }
    }

    '__ci_bb_1176 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_1148
        } else {
            goto '__ci_bb_1177
        }
    }

    '__ci_bb_1177 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_1151
        } else {
            goto '__ci_bb_1178
        }
    }

    '__ci_bb_1178 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_1155
        } else {
            goto '__ci_bb_1147
        }
    }

    '__ci_bb_1179 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1180
        } else {
            goto '__ci_bb_1181
        }
    }

    '__ci_bb_1180 {
        goto '__ci_bb_1182
    }

    '__ci_bb_1181 {
        goto '__ci_bb_135
    }

    '__ci_bb_1182 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1189
        }
    }

    '__ci_bb_1183 {
        goto '__ci_bb_1181
    }

    '__ci_bb_1184 {
        goto '__ci_bb_1183
    }

    '__ci_bb_1185 {
        (__ci_expr_old_334 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_334 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1186
        } else {
            goto '__ci_bb_1187
        }
    }

    '__ci_bb_1186 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1188
    }

    '__ci_bb_1187 {
        return -43
    }

    '__ci_bb_1188 {
        goto '__ci_bb_1183
    }

    '__ci_bb_1189 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1190
        }
    }

    '__ci_bb_1190 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1191
        }
    }

    '__ci_bb_1191 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1192
        }
    }

    '__ci_bb_1192 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1193
        }
    }

    '__ci_bb_1193 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1194
        }
    }

    '__ci_bb_1194 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_1184
        } else {
            goto '__ci_bb_1185
        }
    }

    '__ci_bb_1195 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1196
        } else {
            goto '__ci_bb_1197
        }
    }

    '__ci_bb_1196 {
        goto '__ci_bb_1198
    }

    '__ci_bb_1197 {
        goto '__ci_bb_135
    }

    '__ci_bb_1198 {
        if (__local_c__goto_703_12 == 10) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1205
        }
    }

    '__ci_bb_1199 {
        goto '__ci_bb_1197
    }

    '__ci_bb_1200 {
        (__ci_expr_old_335 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_335 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1201
        } else {
            goto '__ci_bb_1202
        }
    }

    '__ci_bb_1201 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1203
    }

    '__ci_bb_1202 {
        return -43
    }

    '__ci_bb_1203 {
        goto '__ci_bb_1199
    }

    '__ci_bb_1204 {
        goto '__ci_bb_1199
    }

    '__ci_bb_1205 {
        if (__local_c__goto_703_12 == 11) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1206
        }
    }

    '__ci_bb_1206 {
        if (__local_c__goto_703_12 == 12) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1207
        }
    }

    '__ci_bb_1207 {
        if (__local_c__goto_703_12 == 13) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1208
        }
    }

    '__ci_bb_1208 {
        if (__local_c__goto_703_12 == 133) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1209
        }
    }

    '__ci_bb_1209 {
        if (__local_c__goto_703_12 == 8232) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1210
        }
    }

    '__ci_bb_1210 {
        if (__local_c__goto_703_12 == 8233) {
            goto '__ci_bb_1200
        } else {
            goto '__ci_bb_1204
        }
    }

    '__ci_bb_1211 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1212
        } else {
            goto '__ci_bb_1213
        }
    }

    '__ci_bb_1212 {
        goto '__ci_bb_1214
    }

    '__ci_bb_1213 {
        goto '__ci_bb_135
    }

    '__ci_bb_1214 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1221
        }
    }

    '__ci_bb_1215 {
        goto '__ci_bb_1213
    }

    '__ci_bb_1216 {
        goto '__ci_bb_1215
    }

    '__ci_bb_1217 {
        (__ci_expr_old_336 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_336 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1218
        } else {
            goto '__ci_bb_1219
        }
    }

    '__ci_bb_1218 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1220
    }

    '__ci_bb_1219 {
        return -43
    }

    '__ci_bb_1220 {
        goto '__ci_bb_1215
    }

    '__ci_bb_1221 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1222
        }
    }

    '__ci_bb_1222 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1223
        }
    }

    '__ci_bb_1223 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1224
        }
    }

    '__ci_bb_1224 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1225
        }
    }

    '__ci_bb_1225 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1226
        }
    }

    '__ci_bb_1226 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1227
        }
    }

    '__ci_bb_1227 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1228
        }
    }

    '__ci_bb_1228 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1229
        }
    }

    '__ci_bb_1229 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1230
        }
    }

    '__ci_bb_1230 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1231
        }
    }

    '__ci_bb_1231 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1232
        }
    }

    '__ci_bb_1232 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1233
        }
    }

    '__ci_bb_1233 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1234
        }
    }

    '__ci_bb_1234 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1235
        }
    }

    '__ci_bb_1235 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1236
        }
    }

    '__ci_bb_1236 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1237
        }
    }

    '__ci_bb_1237 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1238
        }
    }

    '__ci_bb_1238 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_1216
        } else {
            goto '__ci_bb_1217
        }
    }

    '__ci_bb_1239 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1240
        } else {
            goto '__ci_bb_1241
        }
    }

    '__ci_bb_1240 {
        goto '__ci_bb_1242
    }

    '__ci_bb_1241 {
        goto '__ci_bb_135
    }

    '__ci_bb_1242 {
        if (__local_c__goto_703_12 == 9) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1249
        }
    }

    '__ci_bb_1243 {
        goto '__ci_bb_1241
    }

    '__ci_bb_1244 {
        (__ci_expr_old_337 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_337 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1245
        } else {
            goto '__ci_bb_1246
        }
    }

    '__ci_bb_1245 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1247
    }

    '__ci_bb_1246 {
        return -43
    }

    '__ci_bb_1247 {
        goto '__ci_bb_1243
    }

    '__ci_bb_1248 {
        goto '__ci_bb_1243
    }

    '__ci_bb_1249 {
        if (__local_c__goto_703_12 == 32) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1250
        }
    }

    '__ci_bb_1250 {
        if (__local_c__goto_703_12 == 160) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1251
        }
    }

    '__ci_bb_1251 {
        if (__local_c__goto_703_12 == 5760) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1252
        }
    }

    '__ci_bb_1252 {
        if (__local_c__goto_703_12 == 6158) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1253
        }
    }

    '__ci_bb_1253 {
        if (__local_c__goto_703_12 == 8192) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1254
        }
    }

    '__ci_bb_1254 {
        if (__local_c__goto_703_12 == 8193) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1255
        }
    }

    '__ci_bb_1255 {
        if (__local_c__goto_703_12 == 8194) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1256
        }
    }

    '__ci_bb_1256 {
        if (__local_c__goto_703_12 == 8195) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1257
        }
    }

    '__ci_bb_1257 {
        if (__local_c__goto_703_12 == 8196) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1258
        }
    }

    '__ci_bb_1258 {
        if (__local_c__goto_703_12 == 8197) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1259
        }
    }

    '__ci_bb_1259 {
        if (__local_c__goto_703_12 == 8198) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1260
        }
    }

    '__ci_bb_1260 {
        if (__local_c__goto_703_12 == 8199) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1261
        }
    }

    '__ci_bb_1261 {
        if (__local_c__goto_703_12 == 8200) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1262
        }
    }

    '__ci_bb_1262 {
        if (__local_c__goto_703_12 == 8201) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1263
        }
    }

    '__ci_bb_1263 {
        if (__local_c__goto_703_12 == 8202) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1264
        }
    }

    '__ci_bb_1264 {
        if (__local_c__goto_703_12 == 8239) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1265
        }
    }

    '__ci_bb_1265 {
        if (__local_c__goto_703_12 == 8287) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1266
        }
    }

    '__ci_bb_1266 {
        if (__local_c__goto_703_12 == 12288) {
            goto '__ci_bb_1244
        } else {
            goto '__ci_bb_1248
        }
    }

    '__ci_bb_1267 {
        (__ci_expr_logic_338 = 0)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_338 = (if (if __local_c__goto_703_12 != __local_d__goto_703_15: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_338 != 0) {
            goto '__ci_bb_1268
        } else {
            goto '__ci_bb_1269
        }
    }

    '__ci_bb_1268 {
        (__ci_expr_old_339 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_339 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1270
        } else {
            goto '__ci_bb_1271
        }
    }

    '__ci_bb_1269 {
        goto '__ci_bb_135
    }

    '__ci_bb_1270 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1272
    }

    '__ci_bb_1271 {
        return -43
    }

    '__ci_bb_1272 {
        goto '__ci_bb_1269
    }

    '__ci_bb_1273 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1274
        } else {
            goto '__ci_bb_1275
        }
    }

    '__ci_bb_1274 {
        (__ci_expr_logic_340 = 0)
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            (__ci_expr_logic_340 = (if (if __local_d__goto_703_15 >= 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_340 != 0) {
            goto '__ci_bb_1276
        } else {
            goto '__ci_bb_1277
        }
    }

    '__ci_bb_1275 {
        goto '__ci_bb_135
    }

    '__ci_bb_1276 {
        (__local_otherd__goto_2421_18 = ((((__local_d__goto_703_15 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1278
    }

    '__ci_bb_1277 {
        (__local_otherd__goto_2421_18 = (unsafe __local_fcc__goto_544_31[__local_d__goto_703_15]))
        goto '__ci_bb_1278
    }

    '__ci_bb_1278 {
        (__ci_expr_logic_341 = 0)
        if ((if __local_c__goto_703_12 != __local_d__goto_703_15: 1 else: 0) != 0) {
            (__ci_expr_logic_341 = (if (if __local_c__goto_703_12 != __local_otherd__goto_2421_18: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_341 != 0) {
            goto '__ci_bb_1279
        } else {
            goto '__ci_bb_1280
        }
    }

    '__ci_bb_1279 {
        (__ci_expr_old_342 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_342 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1281
        } else {
            goto '__ci_bb_1282
        }
    }

    '__ci_bb_1280 {
        goto '__ci_bb_1275
    }

    '__ci_bb_1281 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1283
    }

    '__ci_bb_1282 {
        return -43
    }

    '__ci_bb_1283 {
        goto '__ci_bb_1280
    }

    '__ci_bb_1284 {
        (__local_caseless__goto_754_10 = 1)
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 - 13)
        goto '__ci_bb_1285
    }

    '__ci_bb_1285 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1286
        } else {
            goto '__ci_bb_1287
        }
    }

    '__ci_bb_1286 {
        (__ci_expr_old_343 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_343 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1288
        } else {
            goto '__ci_bb_1289
        }
    }

    '__ci_bb_1287 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1291
        } else {
            goto '__ci_bb_1292
        }
    }

    '__ci_bb_1288 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1290
    }

    '__ci_bb_1289 {
        return -43
    }

    '__ci_bb_1290 {
        goto '__ci_bb_1287
    }

    '__ci_bb_1291 {
        (__local_otherd__goto_2454_18 = 4294967295)
        if (__local_caseless__goto_754_10 != 0) {
            goto '__ci_bb_1293
        } else {
            goto '__ci_bb_1294
        }
    }

    '__ci_bb_1292 {
        goto '__ci_bb_135
    }

    '__ci_bb_1293 {
        (__ci_expr_logic_344 = 0)
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            (__ci_expr_logic_344 = (if (if __local_d__goto_703_15 >= 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_344 != 0) {
            goto '__ci_bb_1295
        } else {
            goto '__ci_bb_1296
        }
    }

    '__ci_bb_1294 {
        if ((if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0) {
            (__ci_expr_logic_345 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_345 = (if (if __local_c__goto_703_12 == __local_otherd__goto_2454_18: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if __ci_expr_logic_345 == (if __local_codevalue__goto_756_14 < 59: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1298
        } else {
            goto '__ci_bb_1299
        }
    }

    '__ci_bb_1295 {
        (__local_otherd__goto_2454_18 = ((((__local_d__goto_703_15 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1297
    }

    '__ci_bb_1296 {
        (__local_otherd__goto_2454_18 = (unsafe __local_fcc__goto_544_31[__local_d__goto_703_15]))
        goto '__ci_bb_1297
    }

    '__ci_bb_1297 {
        goto '__ci_bb_1294
    }

    '__ci_bb_1298 {
        (__ci_expr_logic_347 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_346: c_int

            if ((if __local_codevalue__goto_756_14 == 43: 1 else: 0) != 0) {
                (__ci_expr_logic_346 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_346 = (if (if __local_codevalue__goto_756_14 == 69: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_347 = (if __ci_expr_logic_346 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_347 != 0) {
            goto '__ci_bb_1300
        } else {
            goto '__ci_bb_1301
        }
    }

    '__ci_bb_1299 {
        goto '__ci_bb_1292
    }

    '__ci_bb_1300 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1301
    }

    '__ci_bb_1301 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_348 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_348 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1302
        } else {
            goto '__ci_bb_1303
        }
    }

    '__ci_bb_1302 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1304
    }

    '__ci_bb_1303 {
        return -43
    }

    '__ci_bb_1304 {
        goto '__ci_bb_1299
    }

    '__ci_bb_1305 {
        (__local_caseless__goto_754_10 = 1)
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 - 13)
        goto '__ci_bb_1306
    }

    '__ci_bb_1306 {
        (__ci_expr_old_349 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_349 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1307
        } else {
            goto '__ci_bb_1308
        }
    }

    '__ci_bb_1307 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1309
    }

    '__ci_bb_1308 {
        return -43
    }

    '__ci_bb_1309 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1310
        } else {
            goto '__ci_bb_1311
        }
    }

    '__ci_bb_1310 {
        (__local_otherd__goto_2497_18 = 4294967295)
        if (__local_caseless__goto_754_10 != 0) {
            goto '__ci_bb_1312
        } else {
            goto '__ci_bb_1313
        }
    }

    '__ci_bb_1311 {
        goto '__ci_bb_135
    }

    '__ci_bb_1312 {
        (__ci_expr_logic_350 = 0)
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            (__ci_expr_logic_350 = (if (if __local_d__goto_703_15 >= 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_350 != 0) {
            goto '__ci_bb_1314
        } else {
            goto '__ci_bb_1315
        }
    }

    '__ci_bb_1313 {
        if ((if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0) {
            (__ci_expr_logic_351 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_351 = (if (if __local_c__goto_703_12 == __local_otherd__goto_2497_18: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if __ci_expr_logic_351 == (if __local_codevalue__goto_756_14 < 59: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1317
        } else {
            goto '__ci_bb_1318
        }
    }

    '__ci_bb_1314 {
        (__local_otherd__goto_2497_18 = ((((__local_d__goto_703_15 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1316
    }

    '__ci_bb_1315 {
        (__local_otherd__goto_2497_18 = (unsafe __local_fcc__goto_544_31[__local_d__goto_703_15]))
        goto '__ci_bb_1316
    }

    '__ci_bb_1316 {
        goto '__ci_bb_1313
    }

    '__ci_bb_1317 {
        if ((if __local_codevalue__goto_756_14 == 44: 1 else: 0) != 0) {
            (__ci_expr_logic_352 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_352 = (if (if __local_codevalue__goto_756_14 == 70: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_352 != 0) {
            goto '__ci_bb_1319
        } else {
            goto '__ci_bb_1320
        }
    }

    '__ci_bb_1318 {
        goto '__ci_bb_1311
    }

    '__ci_bb_1319 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1320
    }

    '__ci_bb_1320 {
        (__ci_expr_old_353 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_353 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1321
        } else {
            goto '__ci_bb_1322
        }
    }

    '__ci_bb_1321 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1323
    }

    '__ci_bb_1322 {
        return -43
    }

    '__ci_bb_1323 {
        goto '__ci_bb_1318
    }

    '__ci_bb_1324 {
        (__local_caseless__goto_754_10 = 1)
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 - 13)
        goto '__ci_bb_1325
    }

    '__ci_bb_1325 {
        (__ci_expr_old_354 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_354 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1326
        } else {
            goto '__ci_bb_1327
        }
    }

    '__ci_bb_1326 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1328
    }

    '__ci_bb_1327 {
        return -43
    }

    '__ci_bb_1328 {
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1329
        } else {
            goto '__ci_bb_1330
        }
    }

    '__ci_bb_1329 {
        (__local_otherd__goto_2538_18 = 4294967295)
        if (__local_caseless__goto_754_10 != 0) {
            goto '__ci_bb_1331
        } else {
            goto '__ci_bb_1332
        }
    }

    '__ci_bb_1330 {
        goto '__ci_bb_135
    }

    '__ci_bb_1331 {
        (__ci_expr_logic_355 = 0)
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            (__ci_expr_logic_355 = (if (if __local_d__goto_703_15 >= 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_355 != 0) {
            goto '__ci_bb_1333
        } else {
            goto '__ci_bb_1334
        }
    }

    '__ci_bb_1332 {
        if ((if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0) {
            (__ci_expr_logic_356 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_356 = (if (if __local_c__goto_703_12 == __local_otherd__goto_2538_18: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if __ci_expr_logic_356 == (if __local_codevalue__goto_756_14 < 59: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1336
        } else {
            goto '__ci_bb_1337
        }
    }

    '__ci_bb_1333 {
        (__local_otherd__goto_2538_18 = ((((__local_d__goto_703_15 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1335
    }

    '__ci_bb_1334 {
        (__local_otherd__goto_2538_18 = (unsafe __local_fcc__goto_544_31[__local_d__goto_703_15]))
        goto '__ci_bb_1335
    }

    '__ci_bb_1335 {
        goto '__ci_bb_1332
    }

    '__ci_bb_1336 {
        if ((if __local_codevalue__goto_756_14 == 42: 1 else: 0) != 0) {
            (__ci_expr_logic_357 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_357 = (if (if __local_codevalue__goto_756_14 == 68: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_357 != 0) {
            goto '__ci_bb_1338
        } else {
            goto '__ci_bb_1339
        }
    }

    '__ci_bb_1337 {
        goto '__ci_bb_1330
    }

    '__ci_bb_1338 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1339
    }

    '__ci_bb_1339 {
        (__ci_expr_old_358 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_358 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1340
        } else {
            goto '__ci_bb_1341
        }
    }

    '__ci_bb_1340 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1342
    }

    '__ci_bb_1341 {
        return -43
    }

    '__ci_bb_1342 {
        goto '__ci_bb_1337
    }

    '__ci_bb_1343 {
        (__local_caseless__goto_754_10 = 1)
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 - 13)
        goto '__ci_bb_1344
    }

    '__ci_bb_1344 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1345
        } else {
            goto '__ci_bb_1346
        }
    }

    '__ci_bb_1345 {
        (__local_otherd__goto_2571_18 = 4294967295)
        if (__local_caseless__goto_754_10 != 0) {
            goto '__ci_bb_1347
        } else {
            goto '__ci_bb_1348
        }
    }

    '__ci_bb_1346 {
        goto '__ci_bb_135
    }

    '__ci_bb_1347 {
        (__ci_expr_logic_359 = 0)
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            (__ci_expr_logic_359 = (if (if __local_d__goto_703_15 >= 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_359 != 0) {
            goto '__ci_bb_1349
        } else {
            goto '__ci_bb_1350
        }
    }

    '__ci_bb_1348 {
        if ((if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0) {
            (__ci_expr_logic_360 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_360 = (if (if __local_c__goto_703_12 == __local_otherd__goto_2571_18: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if __ci_expr_logic_360 == (if __local_codevalue__goto_756_14 < 59: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1352
        } else {
            goto '__ci_bb_1353
        }
    }

    '__ci_bb_1349 {
        (__local_otherd__goto_2571_18 = ((((__local_d__goto_703_15 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1351
    }

    '__ci_bb_1350 {
        (__local_otherd__goto_2571_18 = (unsafe __local_fcc__goto_544_31[__local_d__goto_703_15]))
        goto '__ci_bb_1351
    }

    '__ci_bb_1351 {
        goto '__ci_bb_1348
    }

    '__ci_bb_1352 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_1354
        } else {
            goto '__ci_bb_1355
        }
    }

    '__ci_bb_1353 {
        goto '__ci_bb_1346
    }

    '__ci_bb_1354 {
        (__ci_expr_old_361 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_361 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1357
        } else {
            goto '__ci_bb_1358
        }
    }

    '__ci_bb_1355 {
        (__ci_expr_old_362 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_362 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1360
        } else {
            goto '__ci_bb_1361
        }
    }

    '__ci_bb_1356 {
        goto '__ci_bb_1353
    }

    '__ci_bb_1357 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = ((__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1) + 2)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1359
    }

    '__ci_bb_1358 {
        return -43
    }

    '__ci_bb_1359 {
        goto '__ci_bb_1356
    }

    '__ci_bb_1360 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1362
    }

    '__ci_bb_1361 {
        return -43
    }

    '__ci_bb_1362 {
        goto '__ci_bb_1356
    }

    '__ci_bb_1363 {
        (__local_caseless__goto_754_10 = 1)
        (__local_codevalue__goto_756_14 = __local_codevalue__goto_756_14 - 13)
        goto '__ci_bb_1364
    }

    '__ci_bb_1364 {
        (__ci_expr_old_363 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_363 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1365
        } else {
            goto '__ci_bb_1366
        }
    }

    '__ci_bb_1365 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1367
    }

    '__ci_bb_1366 {
        return -43
    }

    '__ci_bb_1367 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1368
        } else {
            goto '__ci_bb_1369
        }
    }

    '__ci_bb_1368 {
        (__local_otherd__goto_2611_18 = 4294967295)
        if (__local_caseless__goto_754_10 != 0) {
            goto '__ci_bb_1370
        } else {
            goto '__ci_bb_1371
        }
    }

    '__ci_bb_1369 {
        goto '__ci_bb_135
    }

    '__ci_bb_1370 {
        (__ci_expr_logic_364 = 0)
        if (__local_utf_or_ucp__goto_559_6 != 0) {
            (__ci_expr_logic_364 = (if (if __local_d__goto_703_15 >= 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_364 != 0) {
            goto '__ci_bb_1372
        } else {
            goto '__ci_bb_1373
        }
    }

    '__ci_bb_1371 {
        if ((if __local_c__goto_703_12 == __local_d__goto_703_15: 1 else: 0) != 0) {
            (__ci_expr_logic_365 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_365 = (if (if __local_c__goto_703_12 == __local_otherd__goto_2611_18: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if __ci_expr_logic_365 == (if __local_codevalue__goto_756_14 < 59: 1 else: 0): 1 else: 0) != 0) {
            goto '__ci_bb_1375
        } else {
            goto '__ci_bb_1376
        }
    }

    '__ci_bb_1372 {
        (__local_otherd__goto_2611_18 = ((((__local_d__goto_703_15 as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_d__goto_703_15 as c_int) / 128)] as c_int) * 128) + ((__local_d__goto_703_15 as c_int) % 128))] as c_uint) as usize)).other_case) as c_uint)))
        goto '__ci_bb_1374
    }

    '__ci_bb_1373 {
        (__local_otherd__goto_2611_18 = (unsafe __local_fcc__goto_544_31[__local_d__goto_703_15]))
        goto '__ci_bb_1374
    }

    '__ci_bb_1374 {
        goto '__ci_bb_1371
    }

    '__ci_bb_1375 {
        if ((if __local_codevalue__goto_756_14 == 45: 1 else: 0) != 0) {
            (__ci_expr_logic_366 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_366 = (if (if __local_codevalue__goto_756_14 == 71: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_366 != 0) {
            goto '__ci_bb_1377
        } else {
            goto '__ci_bb_1378
        }
    }

    '__ci_bb_1376 {
        goto '__ci_bb_1369
    }

    '__ci_bb_1377 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1378
    }

    '__ci_bb_1378 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_1379
        } else {
            goto '__ci_bb_1380
        }
    }

    '__ci_bb_1379 {
        (__ci_expr_old_367 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_367 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1382
        } else {
            goto '__ci_bb_1383
        }
    }

    '__ci_bb_1380 {
        (__ci_expr_old_368 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_368 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1385
        } else {
            goto '__ci_bb_1386
        }
    }

    '__ci_bb_1381 {
        goto '__ci_bb_1376
    }

    '__ci_bb_1382 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = ((__local_state_offset__goto_757_9 + __local_dlen__goto_702_13) + 1) + 2)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1384
    }

    '__ci_bb_1383 {
        return -43
    }

    '__ci_bb_1384 {
        goto '__ci_bb_1381
    }

    '__ci_bb_1385 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1387
    }

    '__ci_bb_1386 {
        return -43
    }

    '__ci_bb_1387 {
        goto '__ci_bb_1381
    }

    '__ci_bb_1388 {
        (__local_isinclass__goto_2647_14 = 0)
        if ((if __local_codevalue__goto_756_14 == 112: 1 else: 0) != 0) {
            goto '__ci_bb_1389
        } else {
            goto '__ci_bb_1390
        }
    }

    '__ci_bb_1389 {
        (__local_ecode__goto_2649_20 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1392
        } else {
            goto '__ci_bb_1393
        }
    }

    '__ci_bb_1390 {
        if ((if __local_codevalue__goto_756_14 == 113: 1 else: 0) != 0) {
            goto '__ci_bb_1394
        } else {
            goto '__ci_bb_1395
        }
    }

    '__ci_bb_1391 {
        (__local_next_state_offset__goto_2648_13 = (((((__local_ecode__goto_2649_20 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) as c_int)))
        goto '__ci_bb_1401
    }

    '__ci_bb_1392 {
        (__local_isinclass__goto_2647_14 = _pcre2_xclass_8(__local_c__goto_703_12, ((__local_code__goto_755_16 + ((1 as isize) as usize)) + ((2 as isize) as usize)), __param_mb.start_code, __local_utf__goto_558_6))
        goto '__ci_bb_1393
    }

    '__ci_bb_1393 {
        goto '__ci_bb_1391
    }

    '__ci_bb_1394 {
        (__local_ecode__goto_2649_20 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1397
        } else {
            goto '__ci_bb_1398
        }
    }

    '__ci_bb_1395 {
        (__local_ecode__goto_2649_20 = (__local_code__goto_755_16 + ((1 as isize) as usize)) + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
        if ((if __local_clen__goto_702_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1399
        } else {
            goto '__ci_bb_1400
        }
    }

    '__ci_bb_1396 {
        goto '__ci_bb_1391
    }

    '__ci_bb_1397 {
        (__local_isinclass__goto_2647_14 = _pcre2_eclass_8(__local_c__goto_703_12, ((__local_code__goto_755_16 + ((1 as isize) as usize)) + ((2 as isize) as usize)), __local_ecode__goto_2649_20, __param_mb.start_code, __local_utf__goto_558_6))
        goto '__ci_bb_1398
    }

    '__ci_bb_1398 {
        goto '__ci_bb_1396
    }

    '__ci_bb_1399 {
        (__ci_expr_ternary_369 = 0)
        if ((if __local_c__goto_703_12 > 255: 1 else: 0) != 0) {
            (__ci_expr_ternary_369 = (if __local_codevalue__goto_756_14 == 111: 1 else: 0))
        } else {
            (__ci_expr_ternary_369 = (if ((((unsafe (__local_code__goto_755_16 + ((1 as isize) as usize))[((__local_c__goto_703_12 as c_uint) / (8 as c_uint))]) as c_int) as c_uint) & (((1 as c_uint) << (((__local_c__goto_703_12 as c_uint) & (7 as c_uint)) as c_uint)) as c_uint)) != 0: 1 else: 0))
        }
        (__local_isinclass__goto_2647_14 = __ci_expr_ternary_369)
        goto '__ci_bb_1400
    }

    '__ci_bb_1400 {
        goto '__ci_bb_1396
    }

    '__ci_bb_1401 {
        if ((unsafe *__local_ecode__goto_2649_20) == 98) {
            goto '__ci_bb_1403
        } else {
            goto '__ci_bb_1463
        }
    }

    '__ci_bb_1402 {
        goto '__ci_bb_135
    }

    '__ci_bb_1403 {
        (__ci_expr_old_370 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_370 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1404
        } else {
            goto '__ci_bb_1405
        }
    }

    '__ci_bb_1404 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_next_state_offset__goto_2648_13 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1406
    }

    '__ci_bb_1405 {
        return -43
    }

    '__ci_bb_1406 {
        if (__local_isinclass__goto_2647_14 != 0) {
            goto '__ci_bb_1407
        } else {
            goto '__ci_bb_1408
        }
    }

    '__ci_bb_1407 {
        if ((if (unsafe *__local_ecode__goto_2649_20) == OP_CRPOSSTAR: 1 else: 0) != 0) {
            goto '__ci_bb_1409
        } else {
            goto '__ci_bb_1410
        }
    }

    '__ci_bb_1408 {
        goto '__ci_bb_1402
    }

    '__ci_bb_1409 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1410
    }

    '__ci_bb_1410 {
        (__ci_expr_old_371 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_371 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1411
        } else {
            goto '__ci_bb_1412
        }
    }

    '__ci_bb_1411 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1413
    }

    '__ci_bb_1412 {
        return -43
    }

    '__ci_bb_1413 {
        goto '__ci_bb_1408
    }

    '__ci_bb_1414 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1415
        } else {
            goto '__ci_bb_1416
        }
    }

    '__ci_bb_1415 {
        (__ci_expr_old_372 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_372 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1417
        } else {
            goto '__ci_bb_1418
        }
    }

    '__ci_bb_1416 {
        if (__local_isinclass__goto_2647_14 != 0) {
            goto '__ci_bb_1420
        } else {
            goto '__ci_bb_1421
        }
    }

    '__ci_bb_1417 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_next_state_offset__goto_2648_13 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1419
    }

    '__ci_bb_1418 {
        return -43
    }

    '__ci_bb_1419 {
        goto '__ci_bb_1416
    }

    '__ci_bb_1420 {
        (__ci_expr_logic_373 = 0)
        if ((if __local_count__goto_759_9 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_373 = (if (if (unsafe *__local_ecode__goto_2649_20) == OP_CRPOSPLUS: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_373 != 0) {
            goto '__ci_bb_1422
        } else {
            goto '__ci_bb_1423
        }
    }

    '__ci_bb_1421 {
        goto '__ci_bb_1402
    }

    '__ci_bb_1422 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1423
    }

    '__ci_bb_1423 {
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        (__ci_expr_old_374 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_374 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1424
        } else {
            goto '__ci_bb_1425
        }
    }

    '__ci_bb_1424 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1426
    }

    '__ci_bb_1425 {
        return -43
    }

    '__ci_bb_1426 {
        goto '__ci_bb_1421
    }

    '__ci_bb_1427 {
        (__ci_expr_old_375 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_375 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1428
        } else {
            goto '__ci_bb_1429
        }
    }

    '__ci_bb_1428 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_next_state_offset__goto_2648_13 + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1430
    }

    '__ci_bb_1429 {
        return -43
    }

    '__ci_bb_1430 {
        if (__local_isinclass__goto_2647_14 != 0) {
            goto '__ci_bb_1431
        } else {
            goto '__ci_bb_1432
        }
    }

    '__ci_bb_1431 {
        if ((if (unsafe *__local_ecode__goto_2649_20) == OP_CRPOSQUERY: 1 else: 0) != 0) {
            goto '__ci_bb_1433
        } else {
            goto '__ci_bb_1434
        }
    }

    '__ci_bb_1432 {
        goto '__ci_bb_1402
    }

    '__ci_bb_1433 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1434
    }

    '__ci_bb_1434 {
        (__ci_expr_old_376 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_376 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1435
        } else {
            goto '__ci_bb_1436
        }
    }

    '__ci_bb_1435 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_next_state_offset__goto_2648_13 + 1)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1437
    }

    '__ci_bb_1436 {
        return -43
    }

    '__ci_bb_1437 {
        goto '__ci_bb_1432
    }

    '__ci_bb_1438 {
        (__local_count__goto_759_9 = __local_current_state__goto_753_17.count)
        if ((if __local_count__goto_759_9 >= (((((((unsafe __local_ecode__goto_2649_20[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_ecode__goto_2649_20[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0) {
            goto '__ci_bb_1439
        } else {
            goto '__ci_bb_1440
        }
    }

    '__ci_bb_1439 {
        (__ci_expr_old_377 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_377 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1441
        } else {
            goto '__ci_bb_1442
        }
    }

    '__ci_bb_1440 {
        if (__local_isinclass__goto_2647_14 != 0) {
            goto '__ci_bb_1444
        } else {
            goto '__ci_bb_1445
        }
    }

    '__ci_bb_1441 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_next_state_offset__goto_2648_13 + 1) + (2 * 2))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1443
    }

    '__ci_bb_1442 {
        return -43
    }

    '__ci_bb_1443 {
        goto '__ci_bb_1440
    }

    '__ci_bb_1444 {
        (__local_max__goto_2753_17 = (((((((unsafe __local_ecode__goto_2649_20[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe __local_ecode__goto_2649_20[((1 + 2) + 1)]) as c_int)) as c_uint) as c_int)))
        (__ci_expr_logic_378 = 0)
        if ((if (unsafe *__local_ecode__goto_2649_20) == OP_CRPOSRANGE: 1 else: 0) != 0) {
            (__ci_expr_logic_378 = (if (if __local_count__goto_759_9 >= (((((((unsafe __local_ecode__goto_2649_20[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_ecode__goto_2649_20[(1 + 1)]) as c_int)) as c_uint) as c_int)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_378 != 0) {
            goto '__ci_bb_1446
        } else {
            goto '__ci_bb_1447
        }
    }

    '__ci_bb_1445 {
        goto '__ci_bb_1402
    }

    '__ci_bb_1446 {
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 - 1)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 - 1)
        goto '__ci_bb_1447
    }

    '__ci_bb_1447 {
        (__ci_expr_logic_379 = 0)
        (__local_count__goto_759_9 = __local_count__goto_759_9 + 1)
        if ((if __local_count__goto_759_9 >= __local_max__goto_2753_17: 1 else: 0) != 0) {
            (__ci_expr_logic_379 = (if (if __local_max__goto_2753_17 != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_379 != 0) {
            goto '__ci_bb_1448
        } else {
            goto '__ci_bb_1449
        }
    }

    '__ci_bb_1448 {
        (__ci_expr_old_380 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_380 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1451
        } else {
            goto '__ci_bb_1452
        }
    }

    '__ci_bb_1449 {
        (__ci_expr_old_381 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_381 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1454
        } else {
            goto '__ci_bb_1455
        }
    }

    '__ci_bb_1450 {
        goto '__ci_bb_1445
    }

    '__ci_bb_1451 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = (__local_next_state_offset__goto_2648_13 + 1) + (2 * 2))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1453
    }

    '__ci_bb_1452 {
        return -43
    }

    '__ci_bb_1453 {
        goto '__ci_bb_1450
    }

    '__ci_bb_1454 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_state_offset__goto_757_9)
        ((unsafe *__local_next_new_state__goto_543_33).count = __local_count__goto_759_9)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1456
    }

    '__ci_bb_1455 {
        return -43
    }

    '__ci_bb_1456 {
        goto '__ci_bb_1450
    }

    '__ci_bb_1457 {
        if (__local_isinclass__goto_2647_14 != 0) {
            goto '__ci_bb_1458
        } else {
            goto '__ci_bb_1459
        }
    }

    '__ci_bb_1458 {
        (__ci_expr_old_382 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_382 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1460
        } else {
            goto '__ci_bb_1461
        }
    }

    '__ci_bb_1459 {
        goto '__ci_bb_1402
    }

    '__ci_bb_1460 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_next_state_offset__goto_2648_13)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1462
    }

    '__ci_bb_1461 {
        return -43
    }

    '__ci_bb_1462 {
        goto '__ci_bb_1459
    }

    '__ci_bb_1463 {
        if ((unsafe *__local_ecode__goto_2649_20) == 99) {
            goto '__ci_bb_1403
        } else {
            goto '__ci_bb_1464
        }
    }

    '__ci_bb_1464 {
        if ((unsafe *__local_ecode__goto_2649_20) == 106) {
            goto '__ci_bb_1403
        } else {
            goto '__ci_bb_1465
        }
    }

    '__ci_bb_1465 {
        if ((unsafe *__local_ecode__goto_2649_20) == 100) {
            goto '__ci_bb_1414
        } else {
            goto '__ci_bb_1466
        }
    }

    '__ci_bb_1466 {
        if ((unsafe *__local_ecode__goto_2649_20) == 101) {
            goto '__ci_bb_1414
        } else {
            goto '__ci_bb_1467
        }
    }

    '__ci_bb_1467 {
        if ((unsafe *__local_ecode__goto_2649_20) == 107) {
            goto '__ci_bb_1414
        } else {
            goto '__ci_bb_1468
        }
    }

    '__ci_bb_1468 {
        if ((unsafe *__local_ecode__goto_2649_20) == 102) {
            goto '__ci_bb_1427
        } else {
            goto '__ci_bb_1469
        }
    }

    '__ci_bb_1469 {
        if ((unsafe *__local_ecode__goto_2649_20) == 103) {
            goto '__ci_bb_1427
        } else {
            goto '__ci_bb_1470
        }
    }

    '__ci_bb_1470 {
        if ((unsafe *__local_ecode__goto_2649_20) == 108) {
            goto '__ci_bb_1427
        } else {
            goto '__ci_bb_1471
        }
    }

    '__ci_bb_1471 {
        if ((unsafe *__local_ecode__goto_2649_20) == 104) {
            goto '__ci_bb_1438
        } else {
            goto '__ci_bb_1472
        }
    }

    '__ci_bb_1472 {
        if ((unsafe *__local_ecode__goto_2649_20) == 105) {
            goto '__ci_bb_1438
        } else {
            goto '__ci_bb_1473
        }
    }

    '__ci_bb_1473 {
        if ((unsafe *__local_ecode__goto_2649_20) == 109) {
            goto '__ci_bb_1438
        } else {
            goto '__ci_bb_1457
        }
    }

    '__ci_bb_1474 {
        goto '__ci_bb_135
    }

    '__ci_bb_1475 {
        (__local_endasscode__goto_2792_20 = __local_code__goto_755_16 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        (__local_rws__goto_2793_21 = ((__local_RWS as *mut RWS_anchor)))
        if ((if __local_rws__goto_2793_21.free < ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_1476
        } else {
            goto '__ci_bb_1477
        }
    }

    '__ci_bb_1476 {
        (__local_rc__goto_2789_13 = more_workspace((&raw mut __local_rws__goto_2793_21 as *mut *mut RWS_anchor), 4, __param_mb))
        if ((if __local_rc__goto_2789_13 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1478
        } else {
            goto '__ci_bb_1479
        }
    }

    '__ci_bb_1477 {
        (__local_local_offsets__goto_2791_21 = ((((__local_RWS + (__local_rws__goto_2793_21.size as usize)) - (__local_rws__goto_2793_21.free as usize)) as *mut c_ulong)))
        (__local_local_workspace__goto_2790_14 = (__local_local_offsets__goto_2791_21 as *mut c_int) + (((2 as c_ulong) *% (2 as c_ulong)) as usize))
        ((unsafe *__local_rws__goto_2793_21).free = __local_rws__goto_2793_21.free - ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        goto '__ci_bb_1480
    }

    '__ci_bb_1478 {
        return __local_rc__goto_2789_13
    }

    '__ci_bb_1479 {
        (__local_RWS = ((__local_rws__goto_2793_21 as *mut c_int)))
        goto '__ci_bb_1477
    }

    '__ci_bb_1480 {
        if ((if (unsafe *__local_endasscode__goto_2792_20) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_1481
        } else {
            goto '__ci_bb_1482
        }
    }

    '__ci_bb_1481 {
        (__local_endasscode__goto_2792_20 = __local_endasscode__goto_2792_20 + ((((((unsafe __local_endasscode__goto_2792_20[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_endasscode__goto_2792_20[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_1480
    }

    '__ci_bb_1482 {
        (__local_rc__goto_2789_13 = internal_dfa_match(__param_mb, __local_code__goto_755_16, __local_ptr__goto_545_12, ((((__local_ptr__goto_545_12 as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong), __local_local_offsets__goto_2791_21, 2, __local_local_workspace__goto_2790_14, 1000, __local_rlevel, __local_RWS))
        ((unsafe *__local_rws__goto_2793_21).free = __local_rws__goto_2793_21.free + ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        (__ci_expr_logic_383 = 0)
        if ((if __local_rc__goto_2789_13 < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_383 = (if (if __local_rc__goto_2789_13 != -1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_383 != 0) {
            goto '__ci_bb_1483
        } else {
            goto '__ci_bb_1484
        }
    }

    '__ci_bb_1483 {
        return __local_rc__goto_2789_13
    }

    '__ci_bb_1484 {
        if ((if __local_codevalue__goto_756_14 == 128: 1 else: 0) != 0) {
            (__ci_expr_logic_384 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_384 = (if (if __local_codevalue__goto_756_14 == 130: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if (if __local_rc__goto_2789_13 >= 0: 1 else: 0) == __ci_expr_logic_384: 1 else: 0) != 0) {
            goto '__ci_bb_1485
        } else {
            goto '__ci_bb_1486
        }
    }

    '__ci_bb_1485 {
        (__ci_expr_old_385 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_385 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1487
        } else {
            goto '__ci_bb_1488
        }
    }

    '__ci_bb_1486 {
        goto '__ci_bb_135
    }

    '__ci_bb_1487 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((((__local_endasscode__goto_2792_20 + ((2 as isize) as usize)) + ((1 as isize) as usize)) as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1489
    }

    '__ci_bb_1488 {
        return -43
    }

    '__ci_bb_1489 {
        goto '__ci_bb_1486
    }

    '__ci_bb_1490 {
        (__local_codelink__goto_2832_13 = (((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as c_int)))
        if ((if (unsafe __local_code__goto_755_16[(2 + 1)]) == OP_CALLOUT: 1 else: 0) != 0) {
            (__ci_expr_logic_386 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_386 = (if (if (unsafe __local_code__goto_755_16[(2 + 1)]) == OP_CALLOUT_STR: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_386 != 0) {
            goto '__ci_bb_1491
        } else {
            goto '__ci_bb_1492
        }
    }

    '__ci_bb_1491 {
        (__local_rrc__goto_758_9 = do_callout_dfa(__local_code__goto_755_16, __param_offsets, __local_current_subject, __local_ptr__goto_545_12, __param_mb, 3, (&raw mut __local_callout_length__goto_2842_22 as *mut c_ulong)))
        if ((if __local_rrc__goto_758_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_1493
        } else {
            goto '__ci_bb_1494
        }
    }

    '__ci_bb_1492 {
        (__local_condcode__goto_2833_21 = (unsafe __local_code__goto_755_16[(2 + 1)]))
        if ((if __local_condcode__goto_2833_21 == OP_CREF: 1 else: 0) != 0) {
            (__ci_expr_logic_387 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_387 = (if (if __local_condcode__goto_2833_21 == OP_DNCREF: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_387 != 0) {
            (__ci_expr_logic_388 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_388 = (if (if __local_condcode__goto_2833_21 == OP_DNRREF: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_388 != 0) {
            goto '__ci_bb_1497
        } else {
            goto '__ci_bb_1498
        }
    }

    '__ci_bb_1493 {
        return __local_rrc__goto_758_9
    }

    '__ci_bb_1494 {
        if ((if __local_rrc__goto_758_9 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1495
        } else {
            goto '__ci_bb_1496
        }
    }

    '__ci_bb_1495 {
        goto '__ci_bb_135
    }

    '__ci_bb_1496 {
        (__local_code__goto_755_16 = __local_code__goto_755_16 + (__local_callout_length__goto_2842_22 as usize))
        goto '__ci_bb_1492
    }

    '__ci_bb_1497 {
        return -40
    }

    '__ci_bb_1498 {
        if ((if __local_condcode__goto_2833_21 == OP_FALSE: 1 else: 0) != 0) {
            (__ci_expr_logic_389 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_389 = (if (if __local_condcode__goto_2833_21 == OP_FAIL: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_389 != 0) {
            goto '__ci_bb_1499
        } else {
            goto '__ci_bb_1500
        }
    }

    '__ci_bb_1499 {
        (__ci_expr_old_390 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_390 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1502
        } else {
            goto '__ci_bb_1503
        }
    }

    '__ci_bb_1500 {
        if ((if __local_condcode__goto_2833_21 == OP_TRUE: 1 else: 0) != 0) {
            goto '__ci_bb_1505
        } else {
            goto '__ci_bb_1506
        }
    }

    '__ci_bb_1501 {
        goto '__ci_bb_135
    }

    '__ci_bb_1502 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((__local_state_offset__goto_757_9 + __local_codelink__goto_2832_13) + 2) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1504
    }

    '__ci_bb_1503 {
        return -43
    }

    '__ci_bb_1504 {
        goto '__ci_bb_1501
    }

    '__ci_bb_1505 {
        (__ci_expr_old_391 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_391 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1508
        } else {
            goto '__ci_bb_1509
        }
    }

    '__ci_bb_1506 {
        if ((if __local_condcode__goto_2833_21 == OP_RREF: 1 else: 0) != 0) {
            goto '__ci_bb_1511
        } else {
            goto '__ci_bb_1512
        }
    }

    '__ci_bb_1507 {
        goto '__ci_bb_1501
    }

    '__ci_bb_1508 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1510
    }

    '__ci_bb_1509 {
        return -43
    }

    '__ci_bb_1510 {
        goto '__ci_bb_1507
    }

    '__ci_bb_1511 {
        (__local_value__goto_2876_24 = ((((((unsafe __local_code__goto_755_16[(2 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[((2 + 2) + 1)]) as c_int)) as c_uint)))
        if ((if __local_value__goto_2876_24 != 65535: 1 else: 0) != 0) {
            goto '__ci_bb_1514
        } else {
            goto '__ci_bb_1515
        }
    }

    '__ci_bb_1512 {
        (__local_asscode__goto_2890_22 = (__local_code__goto_755_16 + ((2 as isize) as usize)) + ((1 as isize) as usize))
        (__local_endasscode__goto_2891_22 = __local_asscode__goto_2890_22 + ((((((unsafe __local_asscode__goto_2890_22[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_asscode__goto_2890_22[(1 + 1)]) as c_int)) as c_uint) as usize))
        (__local_rws__goto_2892_23 = ((__local_RWS as *mut RWS_anchor)))
        if ((if __local_rws__goto_2892_23.free < ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_1525
        } else {
            goto '__ci_bb_1526
        }
    }

    '__ci_bb_1513 {
        goto '__ci_bb_1507
    }

    '__ci_bb_1514 {
        return -40
    }

    '__ci_bb_1515 {
        if ((if __param_mb.recursive != null: 1 else: 0) != 0) {
            goto '__ci_bb_1516
        } else {
            goto '__ci_bb_1517
        }
    }

    '__ci_bb_1516 {
        (__ci_expr_old_392 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_392 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1519
        } else {
            goto '__ci_bb_1520
        }
    }

    '__ci_bb_1517 {
        (__ci_expr_old_393 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_393 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1522
        } else {
            goto '__ci_bb_1523
        }
    }

    '__ci_bb_1518 {
        goto '__ci_bb_1513
    }

    '__ci_bb_1519 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((__local_state_offset__goto_757_9 + 2) + 2) + 2)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1521
    }

    '__ci_bb_1520 {
        return -43
    }

    '__ci_bb_1521 {
        goto '__ci_bb_1518
    }

    '__ci_bb_1522 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((__local_state_offset__goto_757_9 + __local_codelink__goto_2832_13) + 2) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1524
    }

    '__ci_bb_1523 {
        return -43
    }

    '__ci_bb_1524 {
        goto '__ci_bb_1518
    }

    '__ci_bb_1525 {
        (__local_rc__goto_2887_15 = more_workspace((&raw mut __local_rws__goto_2892_23 as *mut *mut RWS_anchor), 4, __param_mb))
        if ((if __local_rc__goto_2887_15 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1527
        } else {
            goto '__ci_bb_1528
        }
    }

    '__ci_bb_1526 {
        (__local_local_offsets__goto_2889_23 = ((((__local_RWS + (__local_rws__goto_2892_23.size as usize)) - (__local_rws__goto_2892_23.free as usize)) as *mut c_ulong)))
        (__local_local_workspace__goto_2888_16 = (__local_local_offsets__goto_2889_23 as *mut c_int) + (((2 as c_ulong) *% (2 as c_ulong)) as usize))
        ((unsafe *__local_rws__goto_2892_23).free = __local_rws__goto_2892_23.free - ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        goto '__ci_bb_1529
    }

    '__ci_bb_1527 {
        return __local_rc__goto_2887_15
    }

    '__ci_bb_1528 {
        (__local_RWS = ((__local_rws__goto_2892_23 as *mut c_int)))
        goto '__ci_bb_1526
    }

    '__ci_bb_1529 {
        if ((if (unsafe *__local_endasscode__goto_2891_22) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_1530
        } else {
            goto '__ci_bb_1531
        }
    }

    '__ci_bb_1530 {
        (__local_endasscode__goto_2891_22 = __local_endasscode__goto_2891_22 + ((((((unsafe __local_endasscode__goto_2891_22[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_endasscode__goto_2891_22[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_1529
    }

    '__ci_bb_1531 {
        (__local_rc__goto_2887_15 = internal_dfa_match(__param_mb, __local_asscode__goto_2890_22, __local_ptr__goto_545_12, ((((__local_ptr__goto_545_12 as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong), __local_local_offsets__goto_2889_23, 2, __local_local_workspace__goto_2888_16, 1000, __local_rlevel, __local_RWS))
        ((unsafe *__local_rws__goto_2892_23).free = __local_rws__goto_2892_23.free + ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        (__ci_expr_logic_394 = 0)
        if ((if __local_rc__goto_2887_15 < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_394 = (if (if __local_rc__goto_2887_15 != -1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_394 != 0) {
            goto '__ci_bb_1532
        } else {
            goto '__ci_bb_1533
        }
    }

    '__ci_bb_1532 {
        return __local_rc__goto_2887_15
    }

    '__ci_bb_1533 {
        if ((if __local_condcode__goto_2833_21 == OP_ASSERT: 1 else: 0) != 0) {
            (__ci_expr_logic_395 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_395 = (if (if __local_condcode__goto_2833_21 == OP_ASSERTBACK: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if (if __local_rc__goto_2887_15 >= 0: 1 else: 0) == __ci_expr_logic_395: 1 else: 0) != 0) {
            goto '__ci_bb_1534
        } else {
            goto '__ci_bb_1535
        }
    }

    '__ci_bb_1534 {
        (__ci_expr_old_396 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_396 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1537
        } else {
            goto '__ci_bb_1538
        }
    }

    '__ci_bb_1535 {
        (__ci_expr_old_397 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_397 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1540
        } else {
            goto '__ci_bb_1541
        }
    }

    '__ci_bb_1536 {
        goto '__ci_bb_1513
    }

    '__ci_bb_1537 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (((((((__local_endasscode__goto_2891_22 + ((2 as isize) as usize)) + ((1 as isize) as usize)) as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) as c_int)))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1539
    }

    '__ci_bb_1538 {
        return -43
    }

    '__ci_bb_1539 {
        goto '__ci_bb_1536
    }

    '__ci_bb_1540 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = ((__local_state_offset__goto_757_9 + __local_codelink__goto_2832_13) + 2) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1542
    }

    '__ci_bb_1541 {
        return -43
    }

    '__ci_bb_1542 {
        goto '__ci_bb_1536
    }

    '__ci_bb_1543 {
        (__local_rws__goto_2937_21 = ((__local_RWS as *mut RWS_anchor)))
        (__local_callpat__goto_2938_20 = __local_start_code__goto_555_12 + ((((((unsafe __local_code__goto_755_16[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_code__goto_755_16[(1 + 1)]) as c_int)) as c_uint) as usize))
        (__ci_expr_ternary_398 = 0)
        if ((if __local_callpat__goto_2938_20 == __param_mb.start_code: 1 else: 0) != 0) {
            (__ci_expr_ternary_398 = 0)
        } else {
            (__ci_expr_ternary_398 = ((((((unsafe __local_callpat__goto_2938_20[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe __local_callpat__goto_2938_20[((1 + 2) + 1)]) as c_int)) as c_uint)))
        }
        (__local_recno__goto_2939_18 = __ci_expr_ternary_398)
        if ((if (unsafe __local_code__goto_755_16[(1 + 2)]) == OP_CREF: 1 else: 0) != 0) {
            goto '__ci_bb_1544
        } else {
            goto '__ci_bb_1545
        }
    }

    '__ci_bb_1544 {
        return -42
    }

    '__ci_bb_1545 {
        if ((if __local_rws__goto_2937_21.free < ((1000 as c_ulong) +% (((1000 as c_ulong) *% (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_1546
        } else {
            goto '__ci_bb_1547
        }
    }

    '__ci_bb_1546 {
        (__local_rc__goto_2934_13 = more_workspace((&raw mut __local_rws__goto_2937_21 as *mut *mut RWS_anchor), 2000, __param_mb))
        if ((if __local_rc__goto_2934_13 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1548
        } else {
            goto '__ci_bb_1549
        }
    }

    '__ci_bb_1547 {
        (__local_local_offsets__goto_2936_21 = ((((__local_RWS + (__local_rws__goto_2937_21.size as usize)) - (__local_rws__goto_2937_21.free as usize)) as *mut c_ulong)))
        (__local_local_workspace__goto_2935_14 = (__local_local_offsets__goto_2936_21 as *mut c_int) + (((1000 as c_ulong) *% (2 as c_ulong)) as usize))
        ((unsafe *__local_rws__goto_2937_21).free = __local_rws__goto_2937_21.free - ((1000 as c_ulong) +% (((1000 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        (__local_ri__goto_2960_34 = __param_mb.recursive)
        goto '__ci_bb_1550
    }

    '__ci_bb_1548 {
        return __local_rc__goto_2934_13
    }

    '__ci_bb_1549 {
        (__local_RWS = ((__local_rws__goto_2937_21 as *mut c_int)))
        goto '__ci_bb_1547
    }

    '__ci_bb_1550 {
        if ((if __local_ri__goto_2960_34 != null: 1 else: 0) != 0) {
            goto '__ci_bb_1551
        } else {
            goto '__ci_bb_1553
        }
    }

    '__ci_bb_1551 {
        (__ci_expr_logic_400 = 0)
        (__ci_expr_logic_399 = 0)
        if ((if __local_recno__goto_2939_18 == __local_ri__goto_2960_34.group_num: 1 else: 0) != 0) {
            (__ci_expr_logic_399 = (if (if __local_ptr__goto_545_12 == __local_ri__goto_2960_34.subject_position: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_399 != 0) {
            (__ci_expr_logic_400 = (if (if __param_mb.last_used_ptr == __local_ri__goto_2960_34.last_used_ptr: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_400 != 0) {
            goto '__ci_bb_1554
        } else {
            goto '__ci_bb_1555
        }
    }

    '__ci_bb_1552 {
        (__local_ri__goto_2960_34 = __local_ri__goto_2960_34.prevrec)
        goto '__ci_bb_1550
    }

    '__ci_bb_1553 {
        (__local_new_recursive__goto_547_20.group_num = __local_recno__goto_2939_18)
        (__local_new_recursive__goto_547_20.subject_position = __local_ptr__goto_545_12)
        (__local_new_recursive__goto_547_20.last_used_ptr = __param_mb.last_used_ptr)
        (__local_new_recursive__goto_547_20.prevrec = __param_mb.recursive)
        ((unsafe *__param_mb).recursive = ((&raw mut __local_new_recursive__goto_547_20 as *mut dfa_recursion_info)))
        (__local_rc__goto_2934_13 = internal_dfa_match(__param_mb, __local_callpat__goto_2938_20, __local_ptr__goto_545_12, ((((__local_ptr__goto_545_12 as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong), __local_local_offsets__goto_2936_21, 1000, __local_local_workspace__goto_2935_14, 1000, __local_rlevel, __local_RWS))
        ((unsafe *__local_rws__goto_2937_21).free = __local_rws__goto_2937_21.free + ((1000 as c_ulong) +% (((1000 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        ((unsafe *__param_mb).recursive = (&raw const __local_new_recursive__goto_547_20 as *const dfa_recursion_info).prevrec)
        if ((if __local_rc__goto_2934_13 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_1556
        } else {
            goto '__ci_bb_1557
        }
    }

    '__ci_bb_1554 {
        return -52
    }

    '__ci_bb_1555 {
        goto '__ci_bb_1552
    }

    '__ci_bb_1556 {
        return -39
    }

    '__ci_bb_1557 {
        if ((if __local_rc__goto_2934_13 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1558
        } else {
            goto '__ci_bb_1559
        }
    }

    '__ci_bb_1558 {
        (__local_rc__goto_2934_13 = (__local_rc__goto_2934_13 * 2) - 2)
        goto '__ci_bb_1561
    }

    '__ci_bb_1559 {
        if ((if __local_rc__goto_2934_13 != -1: 1 else: 0) != 0) {
            goto '__ci_bb_1581
        } else {
            goto '__ci_bb_1582
        }
    }

    '__ci_bb_1560 {
        goto '__ci_bb_135
    }

    '__ci_bb_1561 {
        if ((if __local_rc__goto_2934_13 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_1562
        } else {
            goto '__ci_bb_1564
        }
    }

    '__ci_bb_1562 {
        (__local_charcount__goto_3005_24 = (((unsafe __local_local_offsets__goto_2936_21[(__local_rc__goto_2934_13 + 1)]) as c_ulong) -% ((unsafe __local_local_offsets__goto_2936_21[__local_rc__goto_2934_13]) as c_ulong)))
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_1565
        } else {
            goto '__ci_bb_1566
        }
    }

    '__ci_bb_1563 {
        (__local_rc__goto_2934_13 = __local_rc__goto_2934_13 - 2)
        goto '__ci_bb_1561
    }

    '__ci_bb_1564 {
        goto '__ci_bb_1560
    }

    '__ci_bb_1565 {
        (__local_p__goto_3009_26 = __local_start_subject__goto_553_12 + ((unsafe __local_local_offsets__goto_2936_21[__local_rc__goto_2934_13]) as usize))
        (__local_pp__goto_3010_26 = __local_start_subject__goto_553_12 + ((unsafe __local_local_offsets__goto_2936_21[(__local_rc__goto_2934_13 + 1)]) as usize))
        goto '__ci_bb_1567
    }

    '__ci_bb_1566 {
        if ((if __local_charcount__goto_3005_24 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_1572
        } else {
            goto '__ci_bb_1573
        }
    }

    '__ci_bb_1567 {
        if ((if __local_p__goto_3009_26 < __local_pp__goto_3010_26: 1 else: 0) != 0) {
            goto '__ci_bb_1568
        } else {
            goto '__ci_bb_1569
        }
    }

    '__ci_bb_1568 {
        (__ci_expr_old_401 = __local_p__goto_3009_26)
        (__local_p__goto_3009_26 = __local_p__goto_3009_26 + 1)
        if ((if ((((unsafe *__ci_expr_old_401) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
            goto '__ci_bb_1570
        } else {
            goto '__ci_bb_1571
        }
    }

    '__ci_bb_1569 {
        goto '__ci_bb_1566
    }

    '__ci_bb_1570 {
        (__local_charcount__goto_3005_24 = __local_charcount__goto_3005_24 - 1)
        goto '__ci_bb_1571
    }

    '__ci_bb_1571 {
        goto '__ci_bb_1567
    }

    '__ci_bb_1572 {
        (__ci_expr_old_402 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_402 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1575
        } else {
            goto '__ci_bb_1576
        }
    }

    '__ci_bb_1573 {
        (__ci_expr_old_403 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_403 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1578
        } else {
            goto '__ci_bb_1579
        }
    }

    '__ci_bb_1574 {
        goto '__ci_bb_1563
    }

    '__ci_bb_1575 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - ((__local_state_offset__goto_757_9 + 2) + 1))
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = ((((__local_charcount__goto_3005_24 as c_ulong) -% (1 as c_ulong)) as c_int)))
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1577
    }

    '__ci_bb_1576 {
        return -43
    }

    '__ci_bb_1577 {
        goto '__ci_bb_1574
    }

    '__ci_bb_1578 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = (__local_state_offset__goto_757_9 + 2) + 1)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1580
    }

    '__ci_bb_1579 {
        return -43
    }

    '__ci_bb_1580 {
        goto '__ci_bb_1574
    }

    '__ci_bb_1581 {
        return __local_rc__goto_2934_13
    }

    '__ci_bb_1582 {
        goto '__ci_bb_1560
    }

    '__ci_bb_1583 {
        (__local_local_ptr__goto_3040_20 = __local_ptr__goto_545_12)
        (__local_rws__goto_3041_21 = ((__local_RWS as *mut RWS_anchor)))
        if ((if __local_rws__goto_3041_21.free < ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_1584
        } else {
            goto '__ci_bb_1585
        }
    }

    '__ci_bb_1584 {
        (__local_rc__goto_3036_13 = more_workspace((&raw mut __local_rws__goto_3041_21 as *mut *mut RWS_anchor), 4, __param_mb))
        if ((if __local_rc__goto_3036_13 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1586
        } else {
            goto '__ci_bb_1587
        }
    }

    '__ci_bb_1585 {
        (__local_local_offsets__goto_3038_21 = ((((__local_RWS + (__local_rws__goto_3041_21.size as usize)) - (__local_rws__goto_3041_21.free as usize)) as *mut c_ulong)))
        (__local_local_workspace__goto_3037_14 = (__local_local_offsets__goto_3038_21 as *mut c_int) + (((2 as c_ulong) *% (2 as c_ulong)) as usize))
        ((unsafe *__local_rws__goto_3041_21).free = __local_rws__goto_3041_21.free - ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        if ((if __local_codevalue__goto_756_14 == 155: 1 else: 0) != 0) {
            goto '__ci_bb_1588
        } else {
            goto '__ci_bb_1589
        }
    }

    '__ci_bb_1586 {
        return __local_rc__goto_3036_13
    }

    '__ci_bb_1587 {
        (__local_RWS = ((__local_rws__goto_3041_21 as *mut c_int)))
        goto '__ci_bb_1585
    }

    '__ci_bb_1588 {
        (__local_allow_zero__goto_3042_14 = 1)
        (__local_code__goto_755_16 = __local_code__goto_755_16 + 1)
        goto '__ci_bb_1590
    }

    '__ci_bb_1589 {
        (__local_allow_zero__goto_3042_14 = 0)
        goto '__ci_bb_1590
    }

    '__ci_bb_1590 {
        (__local_matched_count__goto_3039_31 = 0)
        goto '__ci_bb_1591
    }

    '__ci_bb_1591 {
        goto '__ci_bb_1592
    }

    '__ci_bb_1592 {
        (__local_rc__goto_3036_13 = internal_dfa_match(__param_mb, __local_code__goto_755_16, __local_local_ptr__goto_3040_20, ((((__local_ptr__goto_545_12 as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong), __local_local_offsets__goto_3038_21, 2, __local_local_workspace__goto_3037_14, 1000, __local_rlevel, __local_RWS))
        if ((if __local_rc__goto_3036_13 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_1595
        } else {
            goto '__ci_bb_1596
        }
    }

    '__ci_bb_1593 {
        (__local_matched_count__goto_3039_31 = __local_matched_count__goto_3039_31 + 1)
        goto '__ci_bb_1591
    }

    '__ci_bb_1594 {
        ((unsafe *__local_rws__goto_3041_21).free = __local_rws__goto_3041_21.free + ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        if ((if __local_matched_count__goto_3039_31 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_404 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_404 = (if __local_allow_zero__goto_3042_14 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_404 != 0) {
            goto '__ci_bb_1601
        } else {
            goto '__ci_bb_1602
        }
    }

    '__ci_bb_1595 {
        if ((if __local_rc__goto_3036_13 != -1: 1 else: 0) != 0) {
            goto '__ci_bb_1597
        } else {
            goto '__ci_bb_1598
        }
    }

    '__ci_bb_1596 {
        (__local_charcount__goto_3039_20 = (((unsafe __local_local_offsets__goto_3038_21[1]) as c_ulong) -% ((unsafe __local_local_offsets__goto_3038_21[0]) as c_ulong)))
        if ((if __local_charcount__goto_3039_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_1599
        } else {
            goto '__ci_bb_1600
        }
    }

    '__ci_bb_1597 {
        return __local_rc__goto_3036_13
    }

    '__ci_bb_1598 {
        goto '__ci_bb_1594
    }

    '__ci_bb_1599 {
        goto '__ci_bb_1594
    }

    '__ci_bb_1600 {
        (__local_local_ptr__goto_3040_20 = __local_local_ptr__goto_3040_20 + (__local_charcount__goto_3039_20 as usize))
        goto '__ci_bb_1593
    }

    '__ci_bb_1601 {
        (__local_end_subpattern__goto_3102_22 = __local_code__goto_755_16)
        goto '__ci_bb_1603
    }

    '__ci_bb_1602 {
        goto '__ci_bb_135
    }

    '__ci_bb_1603 {
        (__local_end_subpattern__goto_3102_22 = __local_end_subpattern__goto_3102_22 + ((((((unsafe __local_end_subpattern__goto_3102_22[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_subpattern__goto_3102_22[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_1604
    }

    '__ci_bb_1604 {
        if ((if (unsafe *__local_end_subpattern__goto_3102_22) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_1603
        } else {
            goto '__ci_bb_1605
        }
    }

    '__ci_bb_1605 {
        (__local_next_state_offset__goto_3103_15 = (((((((__local_end_subpattern__goto_3102_22 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 2) + 1) as c_int)))
        (__ci_expr_logic_405 = 0)
        if ((if (__local_i__goto_701_7 + 1) >= __local_active_count__goto_548_5: 1 else: 0) != 0) {
            (__ci_expr_logic_405 = (if (if __local_new_count__goto_548_19 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_405 != 0) {
            goto '__ci_bb_1606
        } else {
            goto '__ci_bb_1607
        }
    }

    '__ci_bb_1606 {
        (__local_ptr__goto_545_12 = __local_local_ptr__goto_3040_20)
        (__local_clen__goto_702_7 = 0)
        (__ci_expr_old_406 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_406 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1609
        } else {
            goto '__ci_bb_1610
        }
    }

    '__ci_bb_1607 {
        (__local_p__goto_3123_24 = __local_ptr__goto_545_12)
        (__local_pp__goto_3124_24 = __local_local_ptr__goto_3040_20)
        (__local_charcount__goto_3039_20 = (((((__local_pp__goto_3124_24 as usize) -% (__local_p__goto_3123_24 as usize)) / sizeof[u8]()) as c_ulong)))
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_1612
        } else {
            goto '__ci_bb_1613
        }
    }

    '__ci_bb_1608 {
        goto '__ci_bb_1602
    }

    '__ci_bb_1609 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_next_state_offset__goto_3103_15)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1611
    }

    '__ci_bb_1610 {
        return -43
    }

    '__ci_bb_1611 {
        goto '__ci_bb_1608
    }

    '__ci_bb_1612 {
        goto '__ci_bb_1614
    }

    '__ci_bb_1613 {
        (__ci_expr_old_408 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_408 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1619
        } else {
            goto '__ci_bb_1620
        }
    }

    '__ci_bb_1614 {
        if ((if __local_p__goto_3123_24 < __local_pp__goto_3124_24: 1 else: 0) != 0) {
            goto '__ci_bb_1615
        } else {
            goto '__ci_bb_1616
        }
    }

    '__ci_bb_1615 {
        (__ci_expr_old_407 = __local_p__goto_3123_24)
        (__local_p__goto_3123_24 = __local_p__goto_3123_24 + 1)
        if ((if ((((unsafe *__ci_expr_old_407) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
            goto '__ci_bb_1617
        } else {
            goto '__ci_bb_1618
        }
    }

    '__ci_bb_1616 {
        goto '__ci_bb_1613
    }

    '__ci_bb_1617 {
        (__local_charcount__goto_3039_20 = __local_charcount__goto_3039_20 - 1)
        goto '__ci_bb_1618
    }

    '__ci_bb_1618 {
        goto '__ci_bb_1614
    }

    '__ci_bb_1619 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_next_state_offset__goto_3103_15)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = ((((__local_charcount__goto_3039_20 as c_ulong) -% (1 as c_ulong)) as c_int)))
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1621
    }

    '__ci_bb_1620 {
        return -43
    }

    '__ci_bb_1621 {
        goto '__ci_bb_1608
    }

    '__ci_bb_1622 {
        (__local_rws__goto_3141_21 = ((__local_RWS as *mut RWS_anchor)))
        if ((if __local_rws__goto_3141_21.free < ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_1623
        } else {
            goto '__ci_bb_1624
        }
    }

    '__ci_bb_1623 {
        (__local_rc__goto_3138_13 = more_workspace((&raw mut __local_rws__goto_3141_21 as *mut *mut RWS_anchor), 4, __param_mb))
        if ((if __local_rc__goto_3138_13 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1625
        } else {
            goto '__ci_bb_1626
        }
    }

    '__ci_bb_1624 {
        (__local_local_offsets__goto_3140_21 = ((((__local_RWS + (__local_rws__goto_3141_21.size as usize)) - (__local_rws__goto_3141_21.free as usize)) as *mut c_ulong)))
        (__local_local_workspace__goto_3139_14 = (__local_local_offsets__goto_3140_21 as *mut c_int) + (((2 as c_ulong) *% (2 as c_ulong)) as usize))
        ((unsafe *__local_rws__goto_3141_21).free = __local_rws__goto_3141_21.free - ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        (__local_rc__goto_3138_13 = internal_dfa_match(__param_mb, __local_code__goto_755_16, __local_ptr__goto_545_12, ((((__local_ptr__goto_545_12 as usize) -% (__local_start_subject__goto_553_12 as usize)) / sizeof[u8]()) as c_ulong), __local_local_offsets__goto_3140_21, 2, __local_local_workspace__goto_3139_14, 1000, __local_rlevel, __local_RWS))
        ((unsafe *__local_rws__goto_3141_21).free = __local_rws__goto_3141_21.free + ((1000 as c_ulong) +% (((2 as c_ulong) *% (2 as c_ulong)) as c_ulong)))
        if ((if __local_rc__goto_3138_13 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_1627
        } else {
            goto '__ci_bb_1628
        }
    }

    '__ci_bb_1625 {
        return __local_rc__goto_3138_13
    }

    '__ci_bb_1626 {
        (__local_RWS = ((__local_rws__goto_3141_21 as *mut c_int)))
        goto '__ci_bb_1624
    }

    '__ci_bb_1627 {
        (__local_end_subpattern__goto_3170_22 = __local_code__goto_755_16)
        (__local_charcount__goto_3171_22 = (((unsafe __local_local_offsets__goto_3140_21[1]) as c_ulong) -% ((unsafe __local_local_offsets__goto_3140_21[0]) as c_ulong)))
        goto '__ci_bb_1630
    }

    '__ci_bb_1628 {
        if ((if __local_rc__goto_3138_13 != -1: 1 else: 0) != 0) {
            goto '__ci_bb_1665
        } else {
            goto '__ci_bb_1666
        }
    }

    '__ci_bb_1629 {
        goto '__ci_bb_135
    }

    '__ci_bb_1630 {
        (__local_end_subpattern__goto_3170_22 = __local_end_subpattern__goto_3170_22 + ((((((unsafe __local_end_subpattern__goto_3170_22[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_subpattern__goto_3170_22[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_1631
    }

    '__ci_bb_1631 {
        if ((if (unsafe *__local_end_subpattern__goto_3170_22) == OP_ALT: 1 else: 0) != 0) {
            goto '__ci_bb_1630
        } else {
            goto '__ci_bb_1632
        }
    }

    '__ci_bb_1632 {
        (__local_next_state_offset__goto_3172_15 = (((((((__local_end_subpattern__goto_3170_22 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) + 2) + 1) as c_int)))
        (__ci_expr_ternary_410 = 0)
        if ((if (unsafe *__local_end_subpattern__goto_3170_22) == OP_KETRMAX: 1 else: 0) != 0) {
            (__ci_expr_logic_409 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_409 = (if (if (unsafe *__local_end_subpattern__goto_3170_22) == OP_KETRMIN: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_409 != 0) {
            (__ci_expr_ternary_410 = ((((((__local_end_subpattern__goto_3170_22 as usize) -% (__local_start_code__goto_555_12 as usize)) / sizeof[u8]()) - (((((unsafe __local_end_subpattern__goto_3170_22[1]) as c_int) << (8 as c_uint)) | ((unsafe __local_end_subpattern__goto_3170_22[(1 + 1)]) as c_int)) as c_uint)) as c_int)))
        } else {
            (__ci_expr_ternary_410 = -1)
        }
        (__local_repeat_state_offset__goto_3172_34 = __ci_expr_ternary_410)
        if ((if __local_charcount__goto_3171_22 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_1633
        } else {
            goto '__ci_bb_1634
        }
    }

    '__ci_bb_1633 {
        (__ci_expr_old_411 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_411 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1636
        } else {
            goto '__ci_bb_1637
        }
    }

    '__ci_bb_1634 {
        (__ci_expr_logic_412 = 0)
        if ((if (__local_i__goto_701_7 + 1) >= __local_active_count__goto_548_5: 1 else: 0) != 0) {
            (__ci_expr_logic_412 = (if (if __local_new_count__goto_548_19 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_412 != 0) {
            goto '__ci_bb_1639
        } else {
            goto '__ci_bb_1640
        }
    }

    '__ci_bb_1635 {
        goto '__ci_bb_1629
    }

    '__ci_bb_1636 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_next_state_offset__goto_3172_15)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1638
    }

    '__ci_bb_1637 {
        return -43
    }

    '__ci_bb_1638 {
        goto '__ci_bb_1635
    }

    '__ci_bb_1639 {
        (__local_ptr__goto_545_12 = __local_ptr__goto_545_12 + (__local_charcount__goto_3171_22 as usize))
        (__local_clen__goto_702_7 = 0)
        (__ci_expr_old_413 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_413 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1642
        } else {
            goto '__ci_bb_1643
        }
    }

    '__ci_bb_1640 {
        if (__local_utf__goto_558_6 != 0) {
            goto '__ci_bb_1650
        } else {
            goto '__ci_bb_1651
        }
    }

    '__ci_bb_1641 {
        goto '__ci_bb_1635
    }

    '__ci_bb_1642 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = __local_next_state_offset__goto_3172_15)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1644
    }

    '__ci_bb_1643 {
        return -43
    }

    '__ci_bb_1644 {
        if ((if __local_repeat_state_offset__goto_3172_34 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_1645
        } else {
            goto '__ci_bb_1646
        }
    }

    '__ci_bb_1645 {
        (__local_next_active_state__goto_543_13 = __local_active_states__goto_542_13)
        (__local_active_count__goto_548_5 = 0)
        (__local_i__goto_701_7 = -1)
        (__ci_expr_old_414 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_414 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1647
        } else {
            goto '__ci_bb_1648
        }
    }

    '__ci_bb_1646 {
        goto '__ci_bb_1641
    }

    '__ci_bb_1647 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_repeat_state_offset__goto_3172_34)
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1649
    }

    '__ci_bb_1648 {
        return -43
    }

    '__ci_bb_1649 {
        goto '__ci_bb_1646
    }

    '__ci_bb_1650 {
        (__local_p__goto_3226_26 = __local_start_subject__goto_553_12 + ((unsafe __local_local_offsets__goto_3140_21[0]) as usize))
        (__local_pp__goto_3227_26 = __local_start_subject__goto_553_12 + ((unsafe __local_local_offsets__goto_3140_21[1]) as usize))
        goto '__ci_bb_1652
    }

    '__ci_bb_1651 {
        (__ci_expr_old_416 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_416 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1657
        } else {
            goto '__ci_bb_1658
        }
    }

    '__ci_bb_1652 {
        if ((if __local_p__goto_3226_26 < __local_pp__goto_3227_26: 1 else: 0) != 0) {
            goto '__ci_bb_1653
        } else {
            goto '__ci_bb_1654
        }
    }

    '__ci_bb_1653 {
        (__ci_expr_old_415 = __local_p__goto_3226_26)
        (__local_p__goto_3226_26 = __local_p__goto_3226_26 + 1)
        if ((if ((((unsafe *__ci_expr_old_415) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
            goto '__ci_bb_1655
        } else {
            goto '__ci_bb_1656
        }
    }

    '__ci_bb_1654 {
        goto '__ci_bb_1651
    }

    '__ci_bb_1655 {
        (__local_charcount__goto_3171_22 = __local_charcount__goto_3171_22 - 1)
        goto '__ci_bb_1656
    }

    '__ci_bb_1656 {
        goto '__ci_bb_1652
    }

    '__ci_bb_1657 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_next_state_offset__goto_3172_15)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = ((((__local_charcount__goto_3171_22 as c_ulong) -% (1 as c_ulong)) as c_int)))
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1659
    }

    '__ci_bb_1658 {
        return -43
    }

    '__ci_bb_1659 {
        if ((if __local_repeat_state_offset__goto_3172_34 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_1660
        } else {
            goto '__ci_bb_1661
        }
    }

    '__ci_bb_1660 {
        (__ci_expr_old_417 = __local_new_count__goto_548_19)
        (__local_new_count__goto_548_19 = __local_new_count__goto_548_19 + 1)
        if ((if __ci_expr_old_417 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1662
        } else {
            goto '__ci_bb_1663
        }
    }

    '__ci_bb_1661 {
        goto '__ci_bb_1641
    }

    '__ci_bb_1662 {
        ((unsafe *__local_next_new_state__goto_543_33).offset = 0 - __local_repeat_state_offset__goto_3172_34)
        ((unsafe *__local_next_new_state__goto_543_33).count = 0)
        ((unsafe *__local_next_new_state__goto_543_33).data = ((((__local_charcount__goto_3171_22 as c_ulong) -% (1 as c_ulong)) as c_int)))
        (__local_next_new_state__goto_543_33 = __local_next_new_state__goto_543_33 + 1)
        goto '__ci_bb_1664
    }

    '__ci_bb_1663 {
        return -43
    }

    '__ci_bb_1664 {
        goto '__ci_bb_1661
    }

    '__ci_bb_1665 {
        return __local_rc__goto_3138_13
    }

    '__ci_bb_1666 {
        goto '__ci_bb_1629
    }

    '__ci_bb_1667 {
        (__local_rrc__goto_758_9 = do_callout_dfa(__local_code__goto_755_16, __param_offsets, __local_current_subject, __local_ptr__goto_545_12, __param_mb, 0, (&raw mut __local_callout_length__goto_3247_20 as *mut c_ulong)))
        if ((if __local_rrc__goto_758_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_1668
        } else {
            goto '__ci_bb_1669
        }
    }

    '__ci_bb_1668 {
        return __local_rrc__goto_758_9
    }

    '__ci_bb_1669 {
        if ((if __local_rrc__goto_758_9 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_1670
        } else {
            goto '__ci_bb_1671
        }
    }

    '__ci_bb_1670 {
        (__ci_expr_old_418 = __local_active_count__goto_548_5)
        (__local_active_count__goto_548_5 = __local_active_count__goto_548_5 + 1)
        if ((if __ci_expr_old_418 < __local_wscount: 1 else: 0) != 0) {
            goto '__ci_bb_1672
        } else {
            goto '__ci_bb_1673
        }
    }

    '__ci_bb_1671 {
        goto '__ci_bb_135
    }

    '__ci_bb_1672 {
        ((unsafe *__local_next_active_state__goto_543_13).offset = __local_state_offset__goto_757_9 + (__local_callout_length__goto_3247_20 as c_int))
        ((unsafe *__local_next_active_state__goto_543_13).count = 0)
        (__local_next_active_state__goto_543_13 = __local_next_active_state__goto_543_13 + 1)
        goto '__ci_bb_1674
    }

    '__ci_bb_1673 {
        return -43
    }

    '__ci_bb_1674 {
        goto '__ci_bb_1671
    }

    '__ci_bb_1675 {
        return -42
    }

    '__ci_bb_1676 {
        if (__local_codevalue__goto_756_14 == 124) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_1677
        }
    }

    '__ci_bb_1677 {
        if (__local_codevalue__goto_756_14 == 123) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_1678
        }
    }

    '__ci_bb_1678 {
        if (__local_codevalue__goto_756_14 == 125) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_1679
        }
    }

    '__ci_bb_1679 {
        if (__local_codevalue__goto_756_14 == 121) {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_1680
        }
    }

    '__ci_bb_1680 {
        if (__local_codevalue__goto_756_14 == 137) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_1681
        }
    }

    '__ci_bb_1681 {
        if (__local_codevalue__goto_756_14 == 142) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_1682
        }
    }

    '__ci_bb_1682 {
        if (__local_codevalue__goto_756_14 == 139) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_1683
        }
    }

    '__ci_bb_1683 {
        if (__local_codevalue__goto_756_14 == 144) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_1684
        }
    }

    '__ci_bb_1684 {
        if (__local_codevalue__goto_756_14 == 153) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_1685
        }
    }

    '__ci_bb_1685 {
        if (__local_codevalue__goto_756_14 == 154) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_1686
        }
    }

    '__ci_bb_1686 {
        if (__local_codevalue__goto_756_14 == 169) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_1687
        }
    }

    '__ci_bb_1687 {
        if (__local_codevalue__goto_756_14 == 27) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_1688
        }
    }

    '__ci_bb_1688 {
        if (__local_codevalue__goto_756_14 == 28) {
            goto '__ci_bb_208
        } else {
            goto '__ci_bb_1689
        }
    }

    '__ci_bb_1689 {
        if (__local_codevalue__goto_756_14 == 24) {
            goto '__ci_bb_214
        } else {
            goto '__ci_bb_1690
        }
    }

    '__ci_bb_1690 {
        if (__local_codevalue__goto_756_14 == 1) {
            goto '__ci_bb_223
        } else {
            goto '__ci_bb_1691
        }
    }

    '__ci_bb_1691 {
        if (__local_codevalue__goto_756_14 == 2) {
            goto '__ci_bb_229
        } else {
            goto '__ci_bb_1692
        }
    }

    '__ci_bb_1692 {
        if (__local_codevalue__goto_756_14 == 12) {
            goto '__ci_bb_235
        } else {
            goto '__ci_bb_1693
        }
    }

    '__ci_bb_1693 {
        if (__local_codevalue__goto_756_14 == 13) {
            goto '__ci_bb_244
        } else {
            goto '__ci_bb_1694
        }
    }

    '__ci_bb_1694 {
        if (__local_codevalue__goto_756_14 == 23) {
            goto '__ci_bb_250
        } else {
            goto '__ci_bb_1695
        }
    }

    '__ci_bb_1695 {
        if (__local_codevalue__goto_756_14 == 25) {
            goto '__ci_bb_258
        } else {
            goto '__ci_bb_1696
        }
    }

    '__ci_bb_1696 {
        if (__local_codevalue__goto_756_14 == 26) {
            goto '__ci_bb_278
        } else {
            goto '__ci_bb_1697
        }
    }

    '__ci_bb_1697 {
        if (__local_codevalue__goto_756_14 == 7) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_1698
        }
    }

    '__ci_bb_1698 {
        if (__local_codevalue__goto_756_14 == 9) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_1699
        }
    }

    '__ci_bb_1699 {
        if (__local_codevalue__goto_756_14 == 11) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_1700
        }
    }

    '__ci_bb_1700 {
        if (__local_codevalue__goto_756_14 == 6) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_1701
        }
    }

    '__ci_bb_1701 {
        if (__local_codevalue__goto_756_14 == 8) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_1702
        }
    }

    '__ci_bb_1702 {
        if (__local_codevalue__goto_756_14 == 10) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_1703
        }
    }

    '__ci_bb_1703 {
        if (__local_codevalue__goto_756_14 == 5) {
            goto '__ci_bb_316
        } else {
            goto '__ci_bb_1704
        }
    }

    '__ci_bb_1704 {
        if (__local_codevalue__goto_756_14 == 4) {
            goto '__ci_bb_316
        } else {
            goto '__ci_bb_1705
        }
    }

    '__ci_bb_1705 {
        if (__local_codevalue__goto_756_14 == 171) {
            goto '__ci_bb_316
        } else {
            goto '__ci_bb_1706
        }
    }

    '__ci_bb_1706 {
        if (__local_codevalue__goto_756_14 == 172) {
            goto '__ci_bb_316
        } else {
            goto '__ci_bb_1707
        }
    }

    '__ci_bb_1707 {
        if (__local_codevalue__goto_756_14 == 16) {
            goto '__ci_bb_362
        } else {
            goto '__ci_bb_1708
        }
    }

    '__ci_bb_1708 {
        if (__local_codevalue__goto_756_14 == 15) {
            goto '__ci_bb_362
        } else {
            goto '__ci_bb_1709
        }
    }

    '__ci_bb_1709 {
        if (__local_codevalue__goto_756_14 == 87) {
            goto '__ci_bb_434
        } else {
            goto '__ci_bb_1710
        }
    }

    '__ci_bb_1710 {
        if (__local_codevalue__goto_756_14 == 88) {
            goto '__ci_bb_434
        } else {
            goto '__ci_bb_1711
        }
    }

    '__ci_bb_1711 {
        if (__local_codevalue__goto_756_14 == 95) {
            goto '__ci_bb_434
        } else {
            goto '__ci_bb_1712
        }
    }

    '__ci_bb_1712 {
        if (__local_codevalue__goto_756_14 == 89) {
            goto '__ci_bb_452
        } else {
            goto '__ci_bb_1713
        }
    }

    '__ci_bb_1713 {
        if (__local_codevalue__goto_756_14 == 90) {
            goto '__ci_bb_452
        } else {
            goto '__ci_bb_1714
        }
    }

    '__ci_bb_1714 {
        if (__local_codevalue__goto_756_14 == 96) {
            goto '__ci_bb_452
        } else {
            goto '__ci_bb_1715
        }
    }

    '__ci_bb_1715 {
        if (__local_codevalue__goto_756_14 == 85) {
            goto '__ci_bb_468
        } else {
            goto '__ci_bb_1716
        }
    }

    '__ci_bb_1716 {
        if (__local_codevalue__goto_756_14 == 86) {
            goto '__ci_bb_468
        } else {
            goto '__ci_bb_1717
        }
    }

    '__ci_bb_1717 {
        if (__local_codevalue__goto_756_14 == 94) {
            goto '__ci_bb_468
        } else {
            goto '__ci_bb_1718
        }
    }

    '__ci_bb_1718 {
        if (__local_codevalue__goto_756_14 == 93) {
            goto '__ci_bb_484
        } else {
            goto '__ci_bb_1719
        }
    }

    '__ci_bb_1719 {
        if (__local_codevalue__goto_756_14 == 91) {
            goto '__ci_bb_501
        } else {
            goto '__ci_bb_1720
        }
    }

    '__ci_bb_1720 {
        if (__local_codevalue__goto_756_14 == 92) {
            goto '__ci_bb_501
        } else {
            goto '__ci_bb_1721
        }
    }

    '__ci_bb_1721 {
        if (__local_codevalue__goto_756_14 == 97) {
            goto '__ci_bb_501
        } else {
            goto '__ci_bb_1722
        }
    }

    '__ci_bb_1722 {
        if (__local_codevalue__goto_756_14 == 387) {
            goto '__ci_bb_523
        } else {
            goto '__ci_bb_1723
        }
    }

    '__ci_bb_1723 {
        if (__local_codevalue__goto_756_14 == 388) {
            goto '__ci_bb_523
        } else {
            goto '__ci_bb_1724
        }
    }

    '__ci_bb_1724 {
        if (__local_codevalue__goto_756_14 == 395) {
            goto '__ci_bb_523
        } else {
            goto '__ci_bb_1725
        }
    }

    '__ci_bb_1725 {
        if (__local_codevalue__goto_756_14 == 407) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_1726
        }
    }

    '__ci_bb_1726 {
        if (__local_codevalue__goto_756_14 == 408) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_1727
        }
    }

    '__ci_bb_1727 {
        if (__local_codevalue__goto_756_14 == 415) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_1728
        }
    }

    '__ci_bb_1728 {
        if (__local_codevalue__goto_756_14 == 427) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_1729
        }
    }

    '__ci_bb_1729 {
        if (__local_codevalue__goto_756_14 == 428) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_1730
        }
    }

    '__ci_bb_1730 {
        if (__local_codevalue__goto_756_14 == 435) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_1731
        }
    }

    '__ci_bb_1731 {
        if (__local_codevalue__goto_756_14 == 467) {
            goto '__ci_bb_644
        } else {
            goto '__ci_bb_1732
        }
    }

    '__ci_bb_1732 {
        if (__local_codevalue__goto_756_14 == 468) {
            goto '__ci_bb_644
        } else {
            goto '__ci_bb_1733
        }
    }

    '__ci_bb_1733 {
        if (__local_codevalue__goto_756_14 == 475) {
            goto '__ci_bb_644
        } else {
            goto '__ci_bb_1734
        }
    }

    '__ci_bb_1734 {
        if (__local_codevalue__goto_756_14 == 447) {
            goto '__ci_bb_669
        } else {
            goto '__ci_bb_1735
        }
    }

    '__ci_bb_1735 {
        if (__local_codevalue__goto_756_14 == 448) {
            goto '__ci_bb_669
        } else {
            goto '__ci_bb_1736
        }
    }

    '__ci_bb_1736 {
        if (__local_codevalue__goto_756_14 == 455) {
            goto '__ci_bb_669
        } else {
            goto '__ci_bb_1737
        }
    }

    '__ci_bb_1737 {
        if (__local_codevalue__goto_756_14 == 389) {
            goto '__ci_bb_706
        } else {
            goto '__ci_bb_1738
        }
    }

    '__ci_bb_1738 {
        if (__local_codevalue__goto_756_14 == 390) {
            goto '__ci_bb_706
        } else {
            goto '__ci_bb_1739
        }
    }

    '__ci_bb_1739 {
        if (__local_codevalue__goto_756_14 == 396) {
            goto '__ci_bb_706
        } else {
            goto '__ci_bb_1740
        }
    }

    '__ci_bb_1740 {
        if (__local_codevalue__goto_756_14 == 385) {
            goto '__ci_bb_708
        } else {
            goto '__ci_bb_1741
        }
    }

    '__ci_bb_1741 {
        if (__local_codevalue__goto_756_14 == 386) {
            goto '__ci_bb_708
        } else {
            goto '__ci_bb_1742
        }
    }

    '__ci_bb_1742 {
        if (__local_codevalue__goto_756_14 == 394) {
            goto '__ci_bb_708
        } else {
            goto '__ci_bb_1743
        }
    }

    '__ci_bb_1743 {
        if (__local_codevalue__goto_756_14 == 409) {
            goto '__ci_bb_785
        } else {
            goto '__ci_bb_1744
        }
    }

    '__ci_bb_1744 {
        if (__local_codevalue__goto_756_14 == 410) {
            goto '__ci_bb_785
        } else {
            goto '__ci_bb_1745
        }
    }

    '__ci_bb_1745 {
        if (__local_codevalue__goto_756_14 == 416) {
            goto '__ci_bb_785
        } else {
            goto '__ci_bb_1746
        }
    }

    '__ci_bb_1746 {
        if (__local_codevalue__goto_756_14 == 405) {
            goto '__ci_bb_787
        } else {
            goto '__ci_bb_1747
        }
    }

    '__ci_bb_1747 {
        if (__local_codevalue__goto_756_14 == 406) {
            goto '__ci_bb_787
        } else {
            goto '__ci_bb_1748
        }
    }

    '__ci_bb_1748 {
        if (__local_codevalue__goto_756_14 == 414) {
            goto '__ci_bb_787
        } else {
            goto '__ci_bb_1749
        }
    }

    '__ci_bb_1749 {
        if (__local_codevalue__goto_756_14 == 429) {
            goto '__ci_bb_798
        } else {
            goto '__ci_bb_1750
        }
    }

    '__ci_bb_1750 {
        if (__local_codevalue__goto_756_14 == 430) {
            goto '__ci_bb_798
        } else {
            goto '__ci_bb_1751
        }
    }

    '__ci_bb_1751 {
        if (__local_codevalue__goto_756_14 == 436) {
            goto '__ci_bb_798
        } else {
            goto '__ci_bb_1752
        }
    }

    '__ci_bb_1752 {
        if (__local_codevalue__goto_756_14 == 425) {
            goto '__ci_bb_800
        } else {
            goto '__ci_bb_1753
        }
    }

    '__ci_bb_1753 {
        if (__local_codevalue__goto_756_14 == 426) {
            goto '__ci_bb_800
        } else {
            goto '__ci_bb_1754
        }
    }

    '__ci_bb_1754 {
        if (__local_codevalue__goto_756_14 == 434) {
            goto '__ci_bb_800
        } else {
            goto '__ci_bb_1755
        }
    }

    '__ci_bb_1755 {
        if (__local_codevalue__goto_756_14 == 469) {
            goto '__ci_bb_827
        } else {
            goto '__ci_bb_1756
        }
    }

    '__ci_bb_1756 {
        if (__local_codevalue__goto_756_14 == 470) {
            goto '__ci_bb_827
        } else {
            goto '__ci_bb_1757
        }
    }

    '__ci_bb_1757 {
        if (__local_codevalue__goto_756_14 == 476) {
            goto '__ci_bb_827
        } else {
            goto '__ci_bb_1758
        }
    }

    '__ci_bb_1758 {
        if (__local_codevalue__goto_756_14 == 465) {
            goto '__ci_bb_829
        } else {
            goto '__ci_bb_1759
        }
    }

    '__ci_bb_1759 {
        if (__local_codevalue__goto_756_14 == 466) {
            goto '__ci_bb_829
        } else {
            goto '__ci_bb_1760
        }
    }

    '__ci_bb_1760 {
        if (__local_codevalue__goto_756_14 == 474) {
            goto '__ci_bb_829
        } else {
            goto '__ci_bb_1761
        }
    }

    '__ci_bb_1761 {
        if (__local_codevalue__goto_756_14 == 449) {
            goto '__ci_bb_852
        } else {
            goto '__ci_bb_1762
        }
    }

    '__ci_bb_1762 {
        if (__local_codevalue__goto_756_14 == 450) {
            goto '__ci_bb_852
        } else {
            goto '__ci_bb_1763
        }
    }

    '__ci_bb_1763 {
        if (__local_codevalue__goto_756_14 == 456) {
            goto '__ci_bb_852
        } else {
            goto '__ci_bb_1764
        }
    }

    '__ci_bb_1764 {
        if (__local_codevalue__goto_756_14 == 445) {
            goto '__ci_bb_854
        } else {
            goto '__ci_bb_1765
        }
    }

    '__ci_bb_1765 {
        if (__local_codevalue__goto_756_14 == 446) {
            goto '__ci_bb_854
        } else {
            goto '__ci_bb_1766
        }
    }

    '__ci_bb_1766 {
        if (__local_codevalue__goto_756_14 == 454) {
            goto '__ci_bb_854
        } else {
            goto '__ci_bb_1767
        }
    }

    '__ci_bb_1767 {
        if (__local_codevalue__goto_756_14 == 393) {
            goto '__ci_bb_889
        } else {
            goto '__ci_bb_1768
        }
    }

    '__ci_bb_1768 {
        if (__local_codevalue__goto_756_14 == 391) {
            goto '__ci_bb_889
        } else {
            goto '__ci_bb_1769
        }
    }

    '__ci_bb_1769 {
        if (__local_codevalue__goto_756_14 == 392) {
            goto '__ci_bb_889
        } else {
            goto '__ci_bb_1770
        }
    }

    '__ci_bb_1770 {
        if (__local_codevalue__goto_756_14 == 397) {
            goto '__ci_bb_889
        } else {
            goto '__ci_bb_1771
        }
    }

    '__ci_bb_1771 {
        if (__local_codevalue__goto_756_14 == 413) {
            goto '__ci_bb_974
        } else {
            goto '__ci_bb_1772
        }
    }

    '__ci_bb_1772 {
        if (__local_codevalue__goto_756_14 == 411) {
            goto '__ci_bb_974
        } else {
            goto '__ci_bb_1773
        }
    }

    '__ci_bb_1773 {
        if (__local_codevalue__goto_756_14 == 412) {
            goto '__ci_bb_974
        } else {
            goto '__ci_bb_1774
        }
    }

    '__ci_bb_1774 {
        if (__local_codevalue__goto_756_14 == 417) {
            goto '__ci_bb_974
        } else {
            goto '__ci_bb_1775
        }
    }

    '__ci_bb_1775 {
        if (__local_codevalue__goto_756_14 == 433) {
            goto '__ci_bb_995
        } else {
            goto '__ci_bb_1776
        }
    }

    '__ci_bb_1776 {
        if (__local_codevalue__goto_756_14 == 431) {
            goto '__ci_bb_995
        } else {
            goto '__ci_bb_1777
        }
    }

    '__ci_bb_1777 {
        if (__local_codevalue__goto_756_14 == 432) {
            goto '__ci_bb_995
        } else {
            goto '__ci_bb_1778
        }
    }

    '__ci_bb_1778 {
        if (__local_codevalue__goto_756_14 == 437) {
            goto '__ci_bb_995
        } else {
            goto '__ci_bb_1779
        }
    }

    '__ci_bb_1779 {
        if (__local_codevalue__goto_756_14 == 473) {
            goto '__ci_bb_1030
        } else {
            goto '__ci_bb_1780
        }
    }

    '__ci_bb_1780 {
        if (__local_codevalue__goto_756_14 == 471) {
            goto '__ci_bb_1030
        } else {
            goto '__ci_bb_1781
        }
    }

    '__ci_bb_1781 {
        if (__local_codevalue__goto_756_14 == 472) {
            goto '__ci_bb_1030
        } else {
            goto '__ci_bb_1782
        }
    }

    '__ci_bb_1782 {
        if (__local_codevalue__goto_756_14 == 477) {
            goto '__ci_bb_1030
        } else {
            goto '__ci_bb_1783
        }
    }

    '__ci_bb_1783 {
        if (__local_codevalue__goto_756_14 == 453) {
            goto '__ci_bb_1061
        } else {
            goto '__ci_bb_1784
        }
    }

    '__ci_bb_1784 {
        if (__local_codevalue__goto_756_14 == 451) {
            goto '__ci_bb_1061
        } else {
            goto '__ci_bb_1785
        }
    }

    '__ci_bb_1785 {
        if (__local_codevalue__goto_756_14 == 452) {
            goto '__ci_bb_1061
        } else {
            goto '__ci_bb_1786
        }
    }

    '__ci_bb_1786 {
        if (__local_codevalue__goto_756_14 == 457) {
            goto '__ci_bb_1061
        } else {
            goto '__ci_bb_1787
        }
    }

    '__ci_bb_1787 {
        if (__local_codevalue__goto_756_14 == 29) {
            goto '__ci_bb_1104
        } else {
            goto '__ci_bb_1788
        }
    }

    '__ci_bb_1788 {
        if (__local_codevalue__goto_756_14 == 30) {
            goto '__ci_bb_1110
        } else {
            goto '__ci_bb_1789
        }
    }

    '__ci_bb_1789 {
        if (__local_codevalue__goto_756_14 == 22) {
            goto '__ci_bb_1135
        } else {
            goto '__ci_bb_1790
        }
    }

    '__ci_bb_1790 {
        if (__local_codevalue__goto_756_14 == 17) {
            goto '__ci_bb_1143
        } else {
            goto '__ci_bb_1791
        }
    }

    '__ci_bb_1791 {
        if (__local_codevalue__goto_756_14 == 20) {
            goto '__ci_bb_1179
        } else {
            goto '__ci_bb_1792
        }
    }

    '__ci_bb_1792 {
        if (__local_codevalue__goto_756_14 == 21) {
            goto '__ci_bb_1195
        } else {
            goto '__ci_bb_1793
        }
    }

    '__ci_bb_1793 {
        if (__local_codevalue__goto_756_14 == 18) {
            goto '__ci_bb_1211
        } else {
            goto '__ci_bb_1794
        }
    }

    '__ci_bb_1794 {
        if (__local_codevalue__goto_756_14 == 19) {
            goto '__ci_bb_1239
        } else {
            goto '__ci_bb_1795
        }
    }

    '__ci_bb_1795 {
        if (__local_codevalue__goto_756_14 == 31) {
            goto '__ci_bb_1267
        } else {
            goto '__ci_bb_1796
        }
    }

    '__ci_bb_1796 {
        if (__local_codevalue__goto_756_14 == 32) {
            goto '__ci_bb_1273
        } else {
            goto '__ci_bb_1797
        }
    }

    '__ci_bb_1797 {
        if (__local_codevalue__goto_756_14 == 48) {
            goto '__ci_bb_1284
        } else {
            goto '__ci_bb_1798
        }
    }

    '__ci_bb_1798 {
        if (__local_codevalue__goto_756_14 == 49) {
            goto '__ci_bb_1284
        } else {
            goto '__ci_bb_1799
        }
    }

    '__ci_bb_1799 {
        if (__local_codevalue__goto_756_14 == 56) {
            goto '__ci_bb_1284
        } else {
            goto '__ci_bb_1800
        }
    }

    '__ci_bb_1800 {
        if (__local_codevalue__goto_756_14 == 74) {
            goto '__ci_bb_1284
        } else {
            goto '__ci_bb_1801
        }
    }

    '__ci_bb_1801 {
        if (__local_codevalue__goto_756_14 == 75) {
            goto '__ci_bb_1284
        } else {
            goto '__ci_bb_1802
        }
    }

    '__ci_bb_1802 {
        if (__local_codevalue__goto_756_14 == 82) {
            goto '__ci_bb_1284
        } else {
            goto '__ci_bb_1803
        }
    }

    '__ci_bb_1803 {
        if (__local_codevalue__goto_756_14 == 35) {
            goto '__ci_bb_1285
        } else {
            goto '__ci_bb_1804
        }
    }

    '__ci_bb_1804 {
        if (__local_codevalue__goto_756_14 == 36) {
            goto '__ci_bb_1285
        } else {
            goto '__ci_bb_1805
        }
    }

    '__ci_bb_1805 {
        if (__local_codevalue__goto_756_14 == 43) {
            goto '__ci_bb_1285
        } else {
            goto '__ci_bb_1806
        }
    }

    '__ci_bb_1806 {
        if (__local_codevalue__goto_756_14 == 61) {
            goto '__ci_bb_1285
        } else {
            goto '__ci_bb_1807
        }
    }

    '__ci_bb_1807 {
        if (__local_codevalue__goto_756_14 == 62) {
            goto '__ci_bb_1285
        } else {
            goto '__ci_bb_1808
        }
    }

    '__ci_bb_1808 {
        if (__local_codevalue__goto_756_14 == 69) {
            goto '__ci_bb_1285
        } else {
            goto '__ci_bb_1809
        }
    }

    '__ci_bb_1809 {
        if (__local_codevalue__goto_756_14 == 50) {
            goto '__ci_bb_1305
        } else {
            goto '__ci_bb_1810
        }
    }

    '__ci_bb_1810 {
        if (__local_codevalue__goto_756_14 == 51) {
            goto '__ci_bb_1305
        } else {
            goto '__ci_bb_1811
        }
    }

    '__ci_bb_1811 {
        if (__local_codevalue__goto_756_14 == 57) {
            goto '__ci_bb_1305
        } else {
            goto '__ci_bb_1812
        }
    }

    '__ci_bb_1812 {
        if (__local_codevalue__goto_756_14 == 76) {
            goto '__ci_bb_1305
        } else {
            goto '__ci_bb_1813
        }
    }

    '__ci_bb_1813 {
        if (__local_codevalue__goto_756_14 == 77) {
            goto '__ci_bb_1305
        } else {
            goto '__ci_bb_1814
        }
    }

    '__ci_bb_1814 {
        if (__local_codevalue__goto_756_14 == 83) {
            goto '__ci_bb_1305
        } else {
            goto '__ci_bb_1815
        }
    }

    '__ci_bb_1815 {
        if (__local_codevalue__goto_756_14 == 37) {
            goto '__ci_bb_1306
        } else {
            goto '__ci_bb_1816
        }
    }

    '__ci_bb_1816 {
        if (__local_codevalue__goto_756_14 == 38) {
            goto '__ci_bb_1306
        } else {
            goto '__ci_bb_1817
        }
    }

    '__ci_bb_1817 {
        if (__local_codevalue__goto_756_14 == 44) {
            goto '__ci_bb_1306
        } else {
            goto '__ci_bb_1818
        }
    }

    '__ci_bb_1818 {
        if (__local_codevalue__goto_756_14 == 63) {
            goto '__ci_bb_1306
        } else {
            goto '__ci_bb_1819
        }
    }

    '__ci_bb_1819 {
        if (__local_codevalue__goto_756_14 == 64) {
            goto '__ci_bb_1306
        } else {
            goto '__ci_bb_1820
        }
    }

    '__ci_bb_1820 {
        if (__local_codevalue__goto_756_14 == 70) {
            goto '__ci_bb_1306
        } else {
            goto '__ci_bb_1821
        }
    }

    '__ci_bb_1821 {
        if (__local_codevalue__goto_756_14 == 46) {
            goto '__ci_bb_1324
        } else {
            goto '__ci_bb_1822
        }
    }

    '__ci_bb_1822 {
        if (__local_codevalue__goto_756_14 == 47) {
            goto '__ci_bb_1324
        } else {
            goto '__ci_bb_1823
        }
    }

    '__ci_bb_1823 {
        if (__local_codevalue__goto_756_14 == 55) {
            goto '__ci_bb_1324
        } else {
            goto '__ci_bb_1824
        }
    }

    '__ci_bb_1824 {
        if (__local_codevalue__goto_756_14 == 72) {
            goto '__ci_bb_1324
        } else {
            goto '__ci_bb_1825
        }
    }

    '__ci_bb_1825 {
        if (__local_codevalue__goto_756_14 == 73) {
            goto '__ci_bb_1324
        } else {
            goto '__ci_bb_1826
        }
    }

    '__ci_bb_1826 {
        if (__local_codevalue__goto_756_14 == 81) {
            goto '__ci_bb_1324
        } else {
            goto '__ci_bb_1827
        }
    }

    '__ci_bb_1827 {
        if (__local_codevalue__goto_756_14 == 33) {
            goto '__ci_bb_1325
        } else {
            goto '__ci_bb_1828
        }
    }

    '__ci_bb_1828 {
        if (__local_codevalue__goto_756_14 == 34) {
            goto '__ci_bb_1325
        } else {
            goto '__ci_bb_1829
        }
    }

    '__ci_bb_1829 {
        if (__local_codevalue__goto_756_14 == 42) {
            goto '__ci_bb_1325
        } else {
            goto '__ci_bb_1830
        }
    }

    '__ci_bb_1830 {
        if (__local_codevalue__goto_756_14 == 59) {
            goto '__ci_bb_1325
        } else {
            goto '__ci_bb_1831
        }
    }

    '__ci_bb_1831 {
        if (__local_codevalue__goto_756_14 == 60) {
            goto '__ci_bb_1325
        } else {
            goto '__ci_bb_1832
        }
    }

    '__ci_bb_1832 {
        if (__local_codevalue__goto_756_14 == 68) {
            goto '__ci_bb_1325
        } else {
            goto '__ci_bb_1833
        }
    }

    '__ci_bb_1833 {
        if (__local_codevalue__goto_756_14 == 54) {
            goto '__ci_bb_1343
        } else {
            goto '__ci_bb_1834
        }
    }

    '__ci_bb_1834 {
        if (__local_codevalue__goto_756_14 == 80) {
            goto '__ci_bb_1343
        } else {
            goto '__ci_bb_1835
        }
    }

    '__ci_bb_1835 {
        if (__local_codevalue__goto_756_14 == 41) {
            goto '__ci_bb_1344
        } else {
            goto '__ci_bb_1836
        }
    }

    '__ci_bb_1836 {
        if (__local_codevalue__goto_756_14 == 67) {
            goto '__ci_bb_1344
        } else {
            goto '__ci_bb_1837
        }
    }

    '__ci_bb_1837 {
        if (__local_codevalue__goto_756_14 == 52) {
            goto '__ci_bb_1363
        } else {
            goto '__ci_bb_1838
        }
    }

    '__ci_bb_1838 {
        if (__local_codevalue__goto_756_14 == 53) {
            goto '__ci_bb_1363
        } else {
            goto '__ci_bb_1839
        }
    }

    '__ci_bb_1839 {
        if (__local_codevalue__goto_756_14 == 58) {
            goto '__ci_bb_1363
        } else {
            goto '__ci_bb_1840
        }
    }

    '__ci_bb_1840 {
        if (__local_codevalue__goto_756_14 == 78) {
            goto '__ci_bb_1363
        } else {
            goto '__ci_bb_1841
        }
    }

    '__ci_bb_1841 {
        if (__local_codevalue__goto_756_14 == 79) {
            goto '__ci_bb_1363
        } else {
            goto '__ci_bb_1842
        }
    }

    '__ci_bb_1842 {
        if (__local_codevalue__goto_756_14 == 84) {
            goto '__ci_bb_1363
        } else {
            goto '__ci_bb_1843
        }
    }

    '__ci_bb_1843 {
        if (__local_codevalue__goto_756_14 == 39) {
            goto '__ci_bb_1364
        } else {
            goto '__ci_bb_1844
        }
    }

    '__ci_bb_1844 {
        if (__local_codevalue__goto_756_14 == 40) {
            goto '__ci_bb_1364
        } else {
            goto '__ci_bb_1845
        }
    }

    '__ci_bb_1845 {
        if (__local_codevalue__goto_756_14 == 45) {
            goto '__ci_bb_1364
        } else {
            goto '__ci_bb_1846
        }
    }

    '__ci_bb_1846 {
        if (__local_codevalue__goto_756_14 == 65) {
            goto '__ci_bb_1364
        } else {
            goto '__ci_bb_1847
        }
    }

    '__ci_bb_1847 {
        if (__local_codevalue__goto_756_14 == 66) {
            goto '__ci_bb_1364
        } else {
            goto '__ci_bb_1848
        }
    }

    '__ci_bb_1848 {
        if (__local_codevalue__goto_756_14 == 71) {
            goto '__ci_bb_1364
        } else {
            goto '__ci_bb_1849
        }
    }

    '__ci_bb_1849 {
        if (__local_codevalue__goto_756_14 == 110) {
            goto '__ci_bb_1388
        } else {
            goto '__ci_bb_1850
        }
    }

    '__ci_bb_1850 {
        if (__local_codevalue__goto_756_14 == 111) {
            goto '__ci_bb_1388
        } else {
            goto '__ci_bb_1851
        }
    }

    '__ci_bb_1851 {
        if (__local_codevalue__goto_756_14 == 112) {
            goto '__ci_bb_1388
        } else {
            goto '__ci_bb_1852
        }
    }

    '__ci_bb_1852 {
        if (__local_codevalue__goto_756_14 == 113) {
            goto '__ci_bb_1388
        } else {
            goto '__ci_bb_1853
        }
    }

    '__ci_bb_1853 {
        if (__local_codevalue__goto_756_14 == 165) {
            goto '__ci_bb_1474
        } else {
            goto '__ci_bb_1854
        }
    }

    '__ci_bb_1854 {
        if (__local_codevalue__goto_756_14 == 128) {
            goto '__ci_bb_1475
        } else {
            goto '__ci_bb_1855
        }
    }

    '__ci_bb_1855 {
        if (__local_codevalue__goto_756_14 == 129) {
            goto '__ci_bb_1475
        } else {
            goto '__ci_bb_1856
        }
    }

    '__ci_bb_1856 {
        if (__local_codevalue__goto_756_14 == 130) {
            goto '__ci_bb_1475
        } else {
            goto '__ci_bb_1857
        }
    }

    '__ci_bb_1857 {
        if (__local_codevalue__goto_756_14 == 131) {
            goto '__ci_bb_1475
        } else {
            goto '__ci_bb_1858
        }
    }

    '__ci_bb_1858 {
        if (__local_codevalue__goto_756_14 == 141) {
            goto '__ci_bb_1490
        } else {
            goto '__ci_bb_1859
        }
    }

    '__ci_bb_1859 {
        if (__local_codevalue__goto_756_14 == 146) {
            goto '__ci_bb_1490
        } else {
            goto '__ci_bb_1860
        }
    }

    '__ci_bb_1860 {
        if (__local_codevalue__goto_756_14 == 118) {
            goto '__ci_bb_1543
        } else {
            goto '__ci_bb_1861
        }
    }

    '__ci_bb_1861 {
        if (__local_codevalue__goto_756_14 == 138) {
            goto '__ci_bb_1583
        } else {
            goto '__ci_bb_1862
        }
    }

    '__ci_bb_1862 {
        if (__local_codevalue__goto_756_14 == 143) {
            goto '__ci_bb_1583
        } else {
            goto '__ci_bb_1863
        }
    }

    '__ci_bb_1863 {
        if (__local_codevalue__goto_756_14 == 140) {
            goto '__ci_bb_1583
        } else {
            goto '__ci_bb_1864
        }
    }

    '__ci_bb_1864 {
        if (__local_codevalue__goto_756_14 == 145) {
            goto '__ci_bb_1583
        } else {
            goto '__ci_bb_1865
        }
    }

    '__ci_bb_1865 {
        if (__local_codevalue__goto_756_14 == 155) {
            goto '__ci_bb_1583
        } else {
            goto '__ci_bb_1866
        }
    }

    '__ci_bb_1866 {
        if (__local_codevalue__goto_756_14 == 135) {
            goto '__ci_bb_1622
        } else {
            goto '__ci_bb_1867
        }
    }

    '__ci_bb_1867 {
        if (__local_codevalue__goto_756_14 == 119) {
            goto '__ci_bb_1667
        } else {
            goto '__ci_bb_1868
        }
    }

    '__ci_bb_1868 {
        if (__local_codevalue__goto_756_14 == 120) {
            goto '__ci_bb_1667
        } else {
            goto '__ci_bb_1675
        }
    }

    '__ci_bb_1869 {
        (__ci_expr_logic_425 = 0)
        (__ci_expr_logic_421 = 0)
        if (__local_could_continue__goto_705_8 != 0) {
            var __ci_expr_logic_420: c_int

            if ((if ((__param_mb.moptions as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_420 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_419: c_int = 0

                if ((if ((__param_mb.moptions as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_419 = (if (if __local_match_count__goto_548_30 < 0: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_420 = (if __ci_expr_logic_419 != 0: 1 else: 0))

            }

            (__ci_expr_logic_421 = (if __ci_expr_logic_420 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_421 != 0) {
            var __ci_expr_logic_424: c_int

            if (__local_partial_newline__goto_704_8 != 0) {
                (__ci_expr_logic_424 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_423: c_int = 0

                if ((if __local_ptr__goto_545_12 >= __local_end_subject__goto_554_12: 1 else: 0) != 0) {
                    var __ci_expr_logic_422: c_int

                    if ((if __local_ptr__goto_545_12 > __param_mb.start_used_ptr: 1 else: 0) != 0) {
                        (__ci_expr_logic_422 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_422 = (if __param_mb.allowemptypartial != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_423 = (if __ci_expr_logic_422 != 0: 1 else: 0))

                }

                (__ci_expr_logic_424 = (if __ci_expr_logic_423 != 0: 1 else: 0))

            }

            (__ci_expr_logic_425 = (if __ci_expr_logic_424 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_425 != 0) {
            goto '__ci_bb_1871
        } else {
            goto '__ci_bb_1872
        }
    }

    '__ci_bb_1870 {
        (__local_ptr__goto_545_12 = __local_ptr__goto_545_12 + ((__local_clen__goto_702_7 as isize) as usize))
        goto '__ci_bb_51
    }

    '__ci_bb_1871 {
        (__local_match_count__goto_548_30 = -2)
        goto '__ci_bb_1872
    }

    '__ci_bb_1872 {
        goto '__ci_bb_52
    }

    '__ci_bb_1873 {
        (__local_match_count__goto_548_30 = -1)
        goto '__ci_bb_1874
    }

    '__ci_bb_1874 {
        return __local_match_count__goto_548_30
    }

}

let coptable: [173]u8 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, (1 + 2), (1 + 2), (1 + 2), 1, 1, 1, (1 + 2), 1, 1, 1, 1, 1, 1, (1 + 2), (1 + 2), (1 + 2), 1, 1, 1, (1 + 2), 1, 1, 1, 1, 1, 1, (1 + 2), (1 + 2), (1 + 2), 1, 1, 1, (1 + 2), 1, 1, 1, 1, 1, 1, (1 + 2), (1 + 2), (1 + 2), 1, 1, 1, (1 + 2), 1, 1, 1, 1, 1, 1, (1 + 2), (1 + 2), (1 + 2), 1, 1, 1, (1 + 2), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
let poptable: [173]u8 = [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
let toptable1: [14]u8 = [0, 0, 0, 0, 0, 0, 0x08, 0x08, 0x01, 0x01, 0x10, 0x10, 0, 0]
let toptable2: [14]u8 = [0, 0, 0, 0, 0, 0, 0x08, 0, 0x01, 0, 0x10, 0, 1, 1]
