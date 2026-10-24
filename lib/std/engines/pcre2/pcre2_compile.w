// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
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
use std.engines.pcre2.pcre2_xclass
use std.engines.pcre2.pcre2_compile_class
use std.engines.pcre2.pcre2_compile_cgroup
use std.libc
use std.collections

pub unsafe fn pcre2_compile_8(__param_pattern: *const u8, __param_patlen: u64, __param_options: u32, __param_errorptr: *mut i32, __param_erroroffset: *mut u64, __param_ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8 writes _pcre2_default_compile_context_8 {
    var __local_pattern = __param_pattern
    var __local_patlen = __param_patlen
    var __local_options = __param_options
    var __local_ccontext = __param_ccontext
    var __local_utf__goto_10276_6: i32 = 0

    var __local_ucp__goto_10277_6: i32 = 0

    var __local_has_lookbehind__goto_10278_6: i32 = 0

    var __local_zero_terminated__goto_10279_6: i32 = 0

    var __local_re__goto_10280_18: *mut pcre2_real_code_8 = null

    var __local_cb__goto_10281_15: compile_block_8

    var __local_tables__goto_10282_16: *const u8 = null

    var __local_null_str__goto_10284_13: List[u8] = [0; 1]

    var __local_code__goto_10285_14: *mut u8 = null

    var __local_codestart__goto_10286_14: *mut u8 = null

    var __local_ptr__goto_10287_12: *const u8 = null

    var __local_pptr__goto_10288_11: *mut u32 = null

    var __local_length__goto_10290_12: u64 = 0

    var __local_usedlength__goto_10291_12: u64 = 0

    var __local_re_blocksize__goto_10292_12: u64 = 0

    var __local_parsed_size_needed__goto_10293_12: u64 = 0

    var __local_firstcuflags__goto_10295_10: u32 = 0

    var __local_reqcuflags__goto_10295_24: u32 = 0

    var __local_firstcu__goto_10296_10: u32 = 0

    var __local_reqcu__goto_10296_19: u32 = 0

    var __local_setflags__goto_10297_10: u32 = 0

    var __local_xoptions__goto_10298_10: u32 = 0

    var __local_skipatstart__goto_10300_10: u32 = 0

    var __local_limit_heap__goto_10301_10: u32 = 0

    var __local_limit_match__goto_10302_10: u32 = 0

    var __local_limit_depth__goto_10303_10: u32 = 0

    var __local_newline__goto_10305_5: i32 = 0

    var __local_bsr__goto_10306_5: i32 = 0

    var __local_errorcode__goto_10307_5: i32 = 0

    var __local_regexrc__goto_10308_5: i32 = 0

    var __local_i__goto_10310_10: u32 = 0

    var __local_optim_flags__goto_10313_10: u32 = 0

    var __local_stack_groupinfo__goto_10318_10: List[u32] = [0; 256]

    var __local_stack_parsed_pattern__goto_10319_10: List[u32] = [0; 1024]

    var __local_named_groups__goto_10320_13: List[named_group_8] = [named_group_8.zeroed(); 20]

    var __local_c16workspace__goto_10325_10: List[u32] = [0; 3000]

    var __local_cworkspace__goto_10326_14: *mut u8 = null

    var __local_p__goto_10498_18: *const pso = null

    var __local_c__goto_10503_18: u32 = 0

    var __local_pp__goto_10503_21: u32 = 0

    var __local_heap_parsed_pattern__goto_10741_13: *mut u32 = null

    var __local_loopcount__goto_10769_7: i32 = 0

    var __local_ng__goto_10944_16: *mut named_group_8 = null

    var __local_tablecount__goto_10945_12: u32 = 0

    var __local_rcode__goto_11007_16: *mut u8 = null

    var __local_rgroup__goto_11008_14: *const u8 = null

    var __local_ccount__goto_11009_16: u32 = 0

    var __local_start__goto_11010_7: i32 = 0

    var __local_rc__goto_11011_17: List[recurse_cache] = [recurse_cache.zeroed(); 8]

    var __local_p__goto_11017_9: i32 = 0

    var __local_groupnumber__goto_11017_12: i32 = 0

    var __local_search_from__goto_11022_18: *const u8 = null

    var __local_temp__goto_11079_16: *mut u8 = null

    var __local_possessify_rc__goto_11080_7: i32 = 0

    var __local_dotstar_anchor__goto_11103_8: i32 = 0

    var __local_minminlength__goto_11117_7: i32 = 0

    var __local_study_rc__goto_11118_7: i32 = 0

    var __local_assertedcuflags__goto_11125_14: u32 = 0

    var __local_assertedcu__goto_11126_14: u32 = 0

    var __local_dotstar_anchor__goto_11181_10: i32 = 0

    var __local_current_data__goto_11324_17: *mut compile_data = null

    var __local_next_data__goto_11327_19: *mut compile_data = null

    var __ci_expr_logic_0: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_old_8: u32 = 0

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_14: i32 = 0

    var __ci_expr_old_15: *mut u8 = null

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_logic_18: i32 = 0

    var __ci_expr_logic_21: i32 = 0

    var __ci_expr_logic_23: i32 = 0

    var __ci_expr_logic_22: i32 = 0

    var __ci_expr_logic_26: i32 = 0

    var __ci_expr_logic_25: i32 = 0

    var __ci_expr_logic_24: i32 = 0

    var __ci_expr_logic_27: i32 = 0

    var __ci_expr_logic_30: i32 = 0

    var __ci_expr_logic_32: i32 = 0

    var __ci_expr_logic_31: i32 = 0

    var __ci_expr_logic_33: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_has_lookbehind__goto_10278_6 = ((0 as i32)))
        (__local_re__goto_10280_18 = ((null as *mut pcre2_real_code_8)))
        (__local_null_str__goto_10284_13 = [205])
        (__local_length__goto_10290_12 = ((1 as u64)))
        (__local_setflags__goto_10297_10 = ((0 as u32)))
        (__local_limit_heap__goto_10301_10 = ((libc.UINT32_MAX as u32)))
        (__local_limit_match__goto_10302_10 = ((libc.UINT32_MAX as u32)))
        (__local_limit_depth__goto_10303_10 = ((libc.UINT32_MAX as u32)))
        (__local_newline__goto_10305_5 = ((0 as i32)))
        (__local_bsr__goto_10306_5 = ((0 as i32)))
        (__local_errorcode__goto_10307_5 = ((0 as i32)))
        (__local_optim_flags__goto_10313_10 = (((if (if __local_ccontext != null: 1 else: 0) != 0: (*__local_ccontext).optimization_flags else: (7 as u32)) as u32)))
        (__local_cworkspace__goto_10326_14 = (&__local_c16workspace__goto_10325_10[0] as *mut u8))
        if ((if __param_errorptr == null: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        if ((if __param_erroroffset != null: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        if ((if __param_erroroffset == null: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        ((*__param_erroroffset) = ((0 as u64)))
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        return ((null as *mut pcre2_real_code_8))
    }

    '__ci_bb_5 {
        if ((if __param_errorptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        ((*__param_errorptr) = ERR0)
        ((*__param_erroroffset) = ((0 as u64)))
        if ((if __local_pattern == null: 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_7 {
        ((*__param_errorptr) = ERR120)
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        return ((null as *mut pcre2_real_code_8))
    }

    '__ci_bb_9 {
        if ((if __local_patlen == 0: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_10 {
        if ((if __local_ccontext == null: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_11 {
        (__local_pattern = (&__local_null_str__goto_10284_13[0] as *const u8))
        goto '__ci_bb_13
    }

    '__ci_bb_12 {
        ((*__param_errorptr) = ERR16)
        return ((null as *mut pcre2_real_code_8))
    }

    '__ci_bb_13 {
        goto '__ci_bb_10
    }

    '__ci_bb_14 {
        (__local_ccontext = ((&raw mut _pcre2_default_compile_context_8 as *mut pcre2_real_compile_context_8)))
        goto '__ci_bb_15
    }

    '__ci_bb_15 {
        if ((if ((__local_options as u32) & (67108864 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        (__local_options = (__local_options as u32) | (524288 as u32))
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((if ((__local_options as u32) & ((~((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((2147483648 as u32) | (4 as u32)) as u32) | (8 as u32)) as u32) | (536870912 as u32)) as u32) | (256 as u32)) as u32) | (33554432 as u32)) as u32) | (67108864 as u32)) as u32) | (65536 as u32)) as u32) | (1073741824 as u32)) as u32) | (8388608 as u32)) as u32) | (524288 as u32)) as u32) | (1 as u32)) as u32) | (2 as u32)) as u32) | (2097152 as u32)) as u32) | (4194304 as u32)) as u32) | (16 as u32)) as u32) | (32 as u32)) as u32) | (64 as u32)) as u32) | (128 as u32)) as u32) | (16777216 as u32)) as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (1048576 as u32)) as u32) | (2048 as u32)) as u32) | (4096 as u32)) as u32) | (8192 as u32)) as u32) | (16384 as u32)) as u32) | (32768 as u32)) as u32) | (131072 as u32)) as u32) | (262144 as u32)) as u32) | (134217728 as u32))) as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (((*__local_ccontext).extra_options as u32) & ((~((((((((((((((((((((((((((((((((8 as u32) | (4 as u32)) as u32) | (128 as u32)) as u32) | (65536 as u32)) as u32) | (1 as u32)) as u32) | (2 as u32)) as u32) | (16 as u32)) as u32) | (32 as u32)) as u32) | (64 as u32)) as u32) | (256 as u32)) as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (2048 as u32)) as u32) | (4096 as u32)) as u32) | (8192 as u32)) as u32) | (16384 as u32)) as u32) | (32768 as u32))) as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        ((*__param_errorptr) = ERR17)
        return ((null as *mut pcre2_real_code_8))
    }

    '__ci_bb_19 {
        (__ci_expr_logic_2 = 0)
        if ((if ((__local_options as u32) & (33554432 as u32)) != 0: 1 else: 0) != 0) {
            var __ci_expr_logic_1: i32

            if ((if ((__local_options as u32) & ((~((((((((((((((((((((2147483648 as u32) | (4 as u32)) as u32) | (8 as u32)) as u32) | (536870912 as u32)) as u32) | (256 as u32)) as u32) | (33554432 as u32)) as u32) | (67108864 as u32)) as u32) | (65536 as u32)) as u32) | (1073741824 as u32)) as u32) | (8388608 as u32)) as u32) | (524288 as u32))) as u32)) != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (((*__local_ccontext).extra_options as u32) & ((~((((((8 as u32) | (4 as u32)) as u32) | (128 as u32)) as u32) | (65536 as u32))) as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        ((*__param_errorptr) = ERR92)
        return ((null as *mut pcre2_real_code_8))
    }

    '__ci_bb_21 {
        (__local_zero_terminated__goto_10279_6 = (((if __local_patlen == (~(0 as u64)): 1 else: 0) as i32)))
        if (__local_zero_terminated__goto_10279_6 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_22 {
        (__local_patlen = ((_pcre2_strlen_8(__local_pattern) as u64)))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        if ((if __local_patlen > (*__local_ccontext).max_pattern_length: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_24 {
        ((*__param_errorptr) = ERR88)
        return ((null as *mut pcre2_real_code_8))
    }

    '__ci_bb_25 {
        if ((if ((__local_options as u32) & (16384 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_26 {
        (__local_optim_flags__goto_10313_10 = (__local_optim_flags__goto_10313_10 as u32) & ((~1) as u32))
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        if ((if ((__local_options as u32) & (32768 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_28 {
        (__local_optim_flags__goto_10313_10 = (__local_optim_flags__goto_10313_10 as u32) & ((~2) as u32))
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        if ((if ((__local_options as u32) & (65536 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        (__local_optim_flags__goto_10313_10 = (__local_optim_flags__goto_10313_10 as u32) & ((~4) as u32))
        goto '__ci_bb_31
    }

    '__ci_bb_31 {
        (__local_tables__goto_10282_16 = (if (if (*__local_ccontext).tables != null: 1 else: 0) != 0: (*__local_ccontext).tables else: (&_pcre2_default_tables_8[0] as *const u8)))
        (__local_cb__goto_10281_15.lcc = __local_tables__goto_10282_16 + ((0 as isize) as usize))
        (__local_cb__goto_10281_15.fcc = __local_tables__goto_10282_16 + ((256 as isize) as usize))
        (__local_cb__goto_10281_15.cbits = __local_tables__goto_10282_16 + ((512 as isize) as usize))
        (__local_cb__goto_10281_15.ctypes = __local_tables__goto_10282_16 + (((512 + 320) as isize) as usize))
        (__local_cb__goto_10281_15.assert_depth = ((0 as u16)))
        (__local_cb__goto_10281_15.bracount = ((0 as u32)))
        (__local_cb__goto_10281_15.cx = __local_ccontext)
        (__local_cb__goto_10281_15.dupnames = ((0 as i32)))
        (__local_cb__goto_10281_15.end_pattern = __local_pattern + (__local_patlen as usize))
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        (__local_cb__goto_10281_15.external_flags = ((0 as u32)))
        (__local_cb__goto_10281_15.external_options = __local_options)
        (__local_cb__goto_10281_15.groupinfo = (&__local_stack_groupinfo__goto_10318_10[0] as *mut u32))
        (__local_cb__goto_10281_15.had_recurse = ((0 as i32)))
        (__local_cb__goto_10281_15.lastcapture = ((0 as u32)))
        (__local_cb__goto_10281_15.max_lookbehind = ((0 as i32)))
        (__local_cb__goto_10281_15.max_varlookbehind = (*__local_ccontext).max_varlookbehind)
        (__local_cb__goto_10281_15.name_entry_size = ((0 as u16)))
        (__local_cb__goto_10281_15.name_table = ((null as *mut u8)))
        (__local_cb__goto_10281_15.named_groups = (&__local_named_groups__goto_10320_13[0] as *mut named_group_8))
        (__local_cb__goto_10281_15.named_group_list_size = ((20 as u32)))
        (__local_cb__goto_10281_15.names_found = ((0 as u16)))
        (__local_cb__goto_10281_15.parens_depth = ((0 as u16)))
        (__local_cb__goto_10281_15.parsed_pattern = (&__local_stack_parsed_pattern__goto_10319_10[0] as *mut u32))
        (__local_cb__goto_10281_15.req_varyopt = ((0 as u32)))
        (__local_cb__goto_10281_15.start_code = __local_cworkspace__goto_10326_14)
        (__local_cb__goto_10281_15.start_pattern = __local_pattern)
        (__local_cb__goto_10281_15.start_workspace = __local_cworkspace__goto_10326_14)
        (__local_cb__goto_10281_15.workspace_size = ((6000 as u64)))
        (__local_cb__goto_10281_15.first_data = ((null as *mut compile_data)))
        (__local_cb__goto_10281_15.last_data = ((null as *mut compile_data)))
        (__local_cb__goto_10281_15.char_lists_size = ((0 as u64)))
        (__local_cb__goto_10281_15.top_backref = ((0 as u32)))
        (__local_cb__goto_10281_15.backref_map = ((0 as u32)))
        (__local_i__goto_10310_10 = ((0 as u32)))
        goto '__ci_bb_32
    }

    '__ci_bb_32 {
        if ((if __local_i__goto_10310_10 < 10: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_33 {
        (__local_cb__goto_10281_15.small_ref_offset[__local_i__goto_10310_10] = (((~(0 as u64)) as u64)))
        goto '__ci_bb_34
    }

    '__ci_bb_34 {
        (__local_i__goto_10310_10 = (__local_i__goto_10310_10 +% 1))
        goto '__ci_bb_32
    }

    '__ci_bb_35 {
        (__local_xoptions__goto_10298_10 = (*__local_ccontext).extra_options)
        (__local_ptr__goto_10287_12 = __local_pattern)
        (__local_skipatstart__goto_10300_10 = ((0 as u32)))
        if ((if ((__local_options as u32) & (33554432 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_36 {
        goto '__ci_bb_38
    }

    '__ci_bb_37 {
        (__local_ptr__goto_10287_12 = __local_ptr__goto_10287_12 + (__local_skipatstart__goto_10300_10 as usize))
        (__local_utf__goto_10276_6 = (((if (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) & (524288 as u32)) != 0: 1 else: 0) as i32)))
        if (__local_utf__goto_10276_6 != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_38 {
        (__ci_expr_logic_4 = 0)
        (__ci_expr_logic_3 = 0)
        if ((if ((__local_patlen as u64) -% (__local_skipatstart__goto_10300_10 as u64)) >= 2: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if (__local_ptr__goto_10287_12[__local_skipatstart__goto_10300_10]) == 40: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if (if (__local_ptr__goto_10287_12[((__local_skipatstart__goto_10300_10 as u32) +% (1 as u32))]) == 42: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_39 {
        (__local_i__goto_10310_10 = ((0 as u32)))
        goto '__ci_bb_41
    }

    '__ci_bb_40 {
        goto '__ci_bb_91
    }

    '__ci_bb_41 {
        if ((if __local_i__goto_10310_10 < ((pso_list.len() as u64)): 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_42 {
        (__local_p__goto_10498_18 = (&pso_list[0] as *const pso) + (__local_i__goto_10310_10 as usize))
        (__ci_expr_logic_5 = 0)
        if ((if ((((__local_patlen as u64) -% (__local_skipatstart__goto_10300_10 as u64)) as u64) -% (2 as u64)) >= (*__local_p__goto_10498_18).length: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if _pcre2_strncmp_c8_8(((__local_ptr__goto_10287_12 + (__local_skipatstart__goto_10300_10 as usize)) + ((2 as isize) as usize)), (*__local_p__goto_10498_18).name, ((*__local_p__goto_10498_18).length as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_43 {
        (__local_i__goto_10310_10 = (__local_i__goto_10310_10 +% 1))
        goto '__ci_bb_41
    }

    '__ci_bb_44 {
        if ((if __local_i__goto_10310_10 >= ((pso_list.len() as u64)): 1 else: 0) != 0) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_45 {
        (__local_skipatstart__goto_10300_10 = (__local_skipatstart__goto_10300_10 +% ((((*__local_p__goto_10498_18).length as i32) + 2) as u32)))
        goto '__ci_bb_47
    }

    '__ci_bb_46 {
        goto '__ci_bb_43
    }

    '__ci_bb_47 {
        if ((*__local_p__goto_10498_18).type_ == 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_48 {
        goto '__ci_bb_44
    }

    '__ci_bb_49 {
        (__local_cb__goto_10281_15.external_options = ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) | ((*__local_p__goto_10498_18).value as u32))
        goto '__ci_bb_48
    }

    '__ci_bb_50 {
        (__local_xoptions__goto_10298_10 = (__local_xoptions__goto_10298_10 as u32) | ((*__local_p__goto_10498_18).value as u32))
        goto '__ci_bb_48
    }

    '__ci_bb_51 {
        (__local_setflags__goto_10297_10 = (__local_setflags__goto_10297_10 as u32) | ((*__local_p__goto_10498_18).value as u32))
        goto '__ci_bb_48
    }

    '__ci_bb_52 {
        (__local_newline__goto_10305_5 = (((*__local_p__goto_10498_18).value as i32)))
        (__local_setflags__goto_10297_10 = (__local_setflags__goto_10297_10 as u32) | (32768 as u32))
        goto '__ci_bb_48
    }

    '__ci_bb_53 {
        (__local_bsr__goto_10306_5 = (((*__local_p__goto_10498_18).value as i32)))
        (__local_setflags__goto_10297_10 = (__local_setflags__goto_10297_10 as u32) | (16384 as u32))
        goto '__ci_bb_48
    }

    '__ci_bb_54 {
        (__local_c__goto_10503_18 = ((0 as u32)))
        (__local_pp__goto_10503_21 = __local_skipatstart__goto_10300_10)
        goto '__ci_bb_55
    }

    '__ci_bb_55 {
        (__ci_expr_logic_7 = 0)
        if ((if __local_pp__goto_10503_21 < __local_patlen: 1 else: 0) != 0) {
            var __ci_expr_logic_6: i32 = 0

            if ((if (__local_ptr__goto_10287_12[__local_pp__goto_10503_21]) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if (__local_ptr__goto_10287_12[__local_pp__goto_10503_21]) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_7 = (if __ci_expr_logic_6 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_56 {
        if ((if __local_c__goto_10503_18 > ((((libc.UINT32_MAX as u32) / (10 as u32)) as u32) -% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_57 {
        if ((if __local_pp__goto_10503_21 >= __local_patlen: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_9 = (if (if __local_pp__goto_10503_21 == __local_skipatstart__goto_10300_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if (if (__local_ptr__goto_10287_12[__local_pp__goto_10503_21]) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_58 {
        goto '__ci_bb_57
    }

    '__ci_bb_59 {
        (__ci_expr_old_8 = __local_pp__goto_10503_21)
        (__local_pp__goto_10503_21 = (__local_pp__goto_10503_21 +% 1))
        (__local_c__goto_10503_18 = ((((((__local_c__goto_10503_18 as u32) *% (10 as u32)) as u32) +% ((((__local_ptr__goto_10287_12[__ci_expr_old_8]) as i32) - 48) as u32)) as u32)))
        goto '__ci_bb_55
    }

    '__ci_bb_60 {
        (__local_errorcode__goto_10307_5 = ERR60)
        (__local_ptr__goto_10287_12 = __local_ptr__goto_10287_12 + (__local_pp__goto_10503_21 as usize))
        (__local_utf__goto_10276_6 = ((0 as i32)))
        goto '__ci_bb_62
    }

    '__ci_bb_61 {
        if ((if (*__local_p__goto_10498_18).type_ == PSO_LIMH: 1 else: 0) != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_62 {
        goto '__ci_bb_281
    }

    '__ci_bb_63 {
        (__local_limit_heap__goto_10301_10 = __local_c__goto_10503_18)
        goto '__ci_bb_65
    }

    '__ci_bb_64 {
        if ((if (*__local_p__goto_10498_18).type_ == PSO_LIMM: 1 else: 0) != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_65 {
        (__local_pp__goto_10503_21 = (__local_pp__goto_10503_21 +% 1))
        (__local_skipatstart__goto_10300_10 = __local_pp__goto_10503_21)
        goto '__ci_bb_48
    }

    '__ci_bb_66 {
        (__local_limit_match__goto_10302_10 = __local_c__goto_10503_18)
        goto '__ci_bb_68
    }

    '__ci_bb_67 {
        (__local_limit_depth__goto_10303_10 = __local_c__goto_10503_18)
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        goto '__ci_bb_65
    }

    '__ci_bb_69 {
        (__local_optim_flags__goto_10313_10 = (__local_optim_flags__goto_10313_10 as u32) & ((~(*__local_p__goto_10498_18).value) as u32))
        goto '__ci_bb_70
    }

    '__ci_bb_70 {
        if ((*__local_p__goto_10498_18).value == 1) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_71 {
        goto '__ci_bb_48
    }

    '__ci_bb_72 {
        (__local_cb__goto_10281_15.external_options = ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) | (16384 as u32))
        goto '__ci_bb_71
    }

    '__ci_bb_73 {
        (__local_cb__goto_10281_15.external_options = ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) | (32768 as u32))
        goto '__ci_bb_71
    }

    '__ci_bb_74 {
        (__local_cb__goto_10281_15.external_options = ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) | (65536 as u32))
        goto '__ci_bb_71
    }

    '__ci_bb_75 {
        if ((*__local_p__goto_10498_18).value == 2) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_76 {
        if ((*__local_p__goto_10498_18).value == 4) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_78
    }

    '__ci_bb_78 {
        goto '__ci_bb_79
    }

    '__ci_bb_79 {
        if (0 != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_80 {
        goto '__ci_bb_48
    }

    '__ci_bb_81 {
        if ((*__local_p__goto_10498_18).type_ == 1) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_82 {
        if ((*__local_p__goto_10498_18).type_ == 2) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_83
        }
    }

    '__ci_bb_83 {
        if ((*__local_p__goto_10498_18).type_ == 3) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_84 {
        if ((*__local_p__goto_10498_18).type_ == 4) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_85 {
        if ((*__local_p__goto_10498_18).type_ == 6) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_86 {
        if ((*__local_p__goto_10498_18).type_ == 7) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_87 {
        if ((*__local_p__goto_10498_18).type_ == 5) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_88
        }
    }

    '__ci_bb_88 {
        if ((*__local_p__goto_10498_18).type_ == 8) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_89 {
        goto '__ci_bb_40
    }

    '__ci_bb_90 {
        goto '__ci_bb_38
    }

    '__ci_bb_91 {
        goto '__ci_bb_92
    }

    '__ci_bb_92 {
        if (0 != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_93 {
        goto '__ci_bb_37
    }

    '__ci_bb_94 {
        if ((if ((__local_options as u32) & (4096 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_95 {
        (__local_ucp__goto_10277_6 = (((if (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) & (131072 as u32)) != 0: 1 else: 0) as i32)))
        (__ci_expr_logic_12 = 0)
        if (__local_ucp__goto_10277_6 != 0) {
            (__ci_expr_logic_12 = (if (if (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options as u32) & (2048 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_96 {
        (__local_errorcode__goto_10307_5 = ERR74)
        goto '__ci_bb_62
    }

    '__ci_bb_97 {
        (__ci_expr_logic_11 = 0)
        if ((if ((__local_options as u32) & (1073741824 as u32)) == 0: 1 else: 0) != 0) {
            (__local_errorcode__goto_10307_5 = ((_pcre2_valid_utf_8(__local_pattern, __local_patlen, __param_erroroffset) as i32)))

            (__ci_expr_logic_11 = (if (if __local_errorcode__goto_10307_5 != 0: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_98 {
        goto '__ci_bb_100
    }

    '__ci_bb_99 {
        goto '__ci_bb_95
    }

    '__ci_bb_100 {
        ((*__param_errorptr) = __local_errorcode__goto_10307_5)
        pcre2_code_free_8(__local_re__goto_10280_18)
        (__local_re__goto_10280_18 = ((null as *mut pcre2_real_code_8)))
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).first_data != null: 1 else: 0) != 0) {
            goto '__ci_bb_287
        } else {
            goto '__ci_bb_288
        }
    }

    '__ci_bb_101 {
        (__local_errorcode__goto_10307_5 = ERR75)
        goto '__ci_bb_62
    }

    '__ci_bb_102 {
        if ((if ((__local_xoptions__goto_10298_10 as u32) & (65536 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_103 {
        (__ci_expr_logic_13 = 0)
        if ((if not (__local_utf__goto_10276_6 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if (if not (__local_ucp__goto_10277_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_104 {
        if ((if __local_bsr__goto_10306_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_112
        }
    }

    '__ci_bb_105 {
        (__local_errorcode__goto_10307_5 = ERR104)
        goto '__ci_bb_62
    }

    '__ci_bb_106 {
        if ((if not (__local_utf__goto_10276_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_108
        }
    }

    '__ci_bb_107 {
        (__local_errorcode__goto_10307_5 = ERR105)
        goto '__ci_bb_62
    }

    '__ci_bb_108 {
        if ((if ((__local_xoptions__goto_10298_10 as u32) & (128 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_109 {
        (__local_errorcode__goto_10307_5 = ERR106)
        goto '__ci_bb_62
    }

    '__ci_bb_110 {
        goto '__ci_bb_104
    }

    '__ci_bb_111 {
        (__local_bsr__goto_10306_5 = (((*__local_ccontext).bsr_convention as i32)))
        goto '__ci_bb_112
    }

    '__ci_bb_112 {
        if ((if __local_newline__goto_10305_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_113 {
        (__local_newline__goto_10305_5 = (((*__local_ccontext).newline_convention as i32)))
        goto '__ci_bb_114
    }

    '__ci_bb_114 {
        (__local_cb__goto_10281_15.nltype = ((0 as u32)))
        goto '__ci_bb_115
    }

    '__ci_bb_115 {
        if (__local_newline__goto_10305_5 == 1) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_116 {
        (__local_parsed_size_needed__goto_10293_12 = ((max_parsed_pattern(__local_ptr__goto_10287_12, (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).end_pattern, __local_utf__goto_10276_6, __local_options) as u64)))
        if ((if (((*__local_ccontext).extra_options as u32) & (((4 as u32) | (8 as u32)) as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_117 {
        (__local_cb__goto_10281_15.nllen = ((1 as u32)))
        (__local_cb__goto_10281_15.nl[0] = ((13 as u8)))
        goto '__ci_bb_116
    }

    '__ci_bb_118 {
        (__local_cb__goto_10281_15.nllen = ((1 as u32)))
        (__local_cb__goto_10281_15.nl[0] = ((10 as u8)))
        goto '__ci_bb_116
    }

    '__ci_bb_119 {
        (__local_cb__goto_10281_15.nllen = ((1 as u32)))
        (__local_cb__goto_10281_15.nl[0] = ((0 as u8)))
        goto '__ci_bb_116
    }

    '__ci_bb_120 {
        (__local_cb__goto_10281_15.nllen = ((2 as u32)))
        (__local_cb__goto_10281_15.nl[0] = ((13 as u8)))
        (__local_cb__goto_10281_15.nl[1] = ((10 as u8)))
        goto '__ci_bb_116
    }

    '__ci_bb_121 {
        (__local_cb__goto_10281_15.nltype = ((1 as u32)))
        goto '__ci_bb_116
    }

    '__ci_bb_122 {
        (__local_cb__goto_10281_15.nltype = ((2 as u32)))
        goto '__ci_bb_116
    }

    '__ci_bb_123 {
        goto '__ci_bb_124
    }

    '__ci_bb_124 {
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        if (0 != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_126 {
        (__local_errorcode__goto_10307_5 = ERR56)
        goto '__ci_bb_62
    }

    '__ci_bb_127 {
        if (__local_newline__goto_10305_5 == 2) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_128 {
        if (__local_newline__goto_10305_5 == 6) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_129 {
        if (__local_newline__goto_10305_5 == 3) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_130 {
        if (__local_newline__goto_10305_5 == 4) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_131 {
        if (__local_newline__goto_10305_5 == 5) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_123
        }
    }

    '__ci_bb_132 {
        (__local_parsed_size_needed__goto_10293_12 = (__local_parsed_size_needed__goto_10293_12 +% 4))
        goto '__ci_bb_133
    }

    '__ci_bb_133 {
        if ((if ((__local_options as u32) & (4 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_134 {
        (__local_parsed_size_needed__goto_10293_12 = (__local_parsed_size_needed__goto_10293_12 +% 4))
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        (__local_parsed_size_needed__goto_10293_12 = (__local_parsed_size_needed__goto_10293_12 +% 1))
        if ((if __local_parsed_size_needed__goto_10293_12 > 1024: 1 else: 0) != 0) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_136 {
        (__local_heap_parsed_pattern__goto_10741_13 = (((*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).malloc.unwrap()((((__local_parsed_size_needed__goto_10293_12 as u64) *% (sizeof[u32]() as u64)) as u64), (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).memory_data) as *mut u32)))
        if ((if __local_heap_parsed_pattern__goto_10741_13 == null: 1 else: 0) != 0) {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_137 {
        (__local_cb__goto_10281_15.parsed_pattern_end = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).parsed_pattern + (__local_parsed_size_needed__goto_10293_12 as usize))
        (__local_errorcode__goto_10307_5 = ((parse_regex(__local_ptr__goto_10287_12, (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options, __local_xoptions__goto_10298_10, (&raw mut __local_has_lookbehind__goto_10278_6 as *mut i32), (&raw mut __local_cb__goto_10281_15 as *mut compile_block_8)) as i32)))
        if ((if __local_errorcode__goto_10307_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_138 {
        ((*__param_errorptr) = ERR21)
        goto '__ci_bb_140
    }

    '__ci_bb_139 {
        (__local_cb__goto_10281_15.parsed_pattern = __local_heap_parsed_pattern__goto_10741_13)
        goto '__ci_bb_137
    }

    '__ci_bb_140 {
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).parsed_pattern != (&__local_stack_parsed_pattern__goto_10319_10[0] as *mut u32): 1 else: 0) != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_141 {
        goto '__ci_bb_143
    }

    '__ci_bb_142 {
        if (__local_has_lookbehind__goto_10278_6 != 0) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_143 {
        (__local_ptr__goto_10287_12 = __local_pattern + ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).erroroffset as usize))
        goto '__ci_bb_62
    }

    '__ci_bb_144 {
        (__local_loopcount__goto_10769_7 = ((0 as i32)))
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).bracount >= 128: 1 else: 0) != 0) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_145 {
        (__local_cb__goto_10281_15.erroroffset = __local_patlen)
        (__local_pptr__goto_10288_11 = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).parsed_pattern)
        (__local_code__goto_10285_14 = __local_cworkspace__goto_10326_14)
        ((*__local_code__goto_10285_14) = ((137 as u8)))
        compile_regex((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options, __local_xoptions__goto_10298_10, (&raw mut __local_code__goto_10285_14 as *mut *mut u8), (&raw mut __local_pptr__goto_10288_11 as *mut *mut u32), (&raw mut __local_errorcode__goto_10307_5 as *mut i32), (0 as u32), (&raw mut __local_firstcu__goto_10296_10 as *mut u32), (&raw mut __local_firstcuflags__goto_10295_10 as *mut u32), (&raw mut __local_reqcu__goto_10296_19 as *mut u32), (&raw mut __local_reqcuflags__goto_10295_24 as *mut u32), (null as *mut branch_chain_8), (null as *mut open_capitem), (&raw mut __local_cb__goto_10281_15 as *mut compile_block_8), (&raw mut __local_length__goto_10290_12 as *mut u64))
        if ((if __local_errorcode__goto_10307_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_146 {
        (__local_cb__goto_10281_15.groupinfo = (((*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).malloc.unwrap()((((((2 as u32) *% ((((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).bracount as u32) +% (1 as u32)) as u32)) as u64) *% (sizeof[u32]() as u64)) as u64), (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).memory_data) as *mut u32)))
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).groupinfo == null: 1 else: 0) != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_147 {
        with_memset((((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).groupinfo as *mut c_void) as *mut u8), (0 as i32), ((((((((2 as u32) *% ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).bracount as u32)) as u32) +% (1 as u32)) as u64) *% (sizeof[u32]() as u64)) as u64) as i64))
        (__local_errorcode__goto_10307_5 = ((check_lookbehinds((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).parsed_pattern, (null as *mut *mut u32), (null as *mut parsed_recurse_check), (&raw mut __local_cb__goto_10281_15 as *mut compile_block_8), (&raw mut __local_loopcount__goto_10769_7 as *mut i32)) as i32)))
        if ((if __local_errorcode__goto_10307_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_148 {
        (__local_errorcode__goto_10307_5 = ERR21)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_143
    }

    '__ci_bb_149 {
        goto '__ci_bb_147
    }

    '__ci_bb_150 {
        goto '__ci_bb_143
    }

    '__ci_bb_151 {
        goto '__ci_bb_145
    }

    '__ci_bb_152 {
        goto '__ci_bb_143
    }

    '__ci_bb_153 {
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        goto '__ci_bb_155
    }

    '__ci_bb_155 {
        if (0 != 0) {
            goto '__ci_bb_154
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_156 {
        if ((if __local_length__goto_10290_12 > 65536: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_14 = (if (if ((65536 as u64) -% (__local_length__goto_10290_12 as u64)) < (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).char_lists_size as u64) / (sizeof[u8]() as u64)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_157 {
        (__local_errorcode__goto_10307_5 = ERR20)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_143
    }

    '__ci_bb_158 {
        (__local_re_blocksize__goto_10292_12 = (((((((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).names_found as u64) *% ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).name_entry_size as u64)) as u64) *% (1 as u64)) as u64)))
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).char_lists_size != 0: 1 else: 0) != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_159 {
        (__local_re_blocksize__goto_10292_12 = ((((((__local_re_blocksize__goto_10292_12 as u64) +% (((sizeof[u32]() as u64) -% (1 as u64)) as u64)) as u64) & ((~((sizeof[u32]() as u64) -% (1 as u64))) as u64)) as u64)))
        (__local_re_blocksize__goto_10292_12 = (__local_re_blocksize__goto_10292_12 +% (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).char_lists_size))
        goto '__ci_bb_160
    }

    '__ci_bb_160 {
        (__local_re_blocksize__goto_10292_12 = (__local_re_blocksize__goto_10292_12 +% ((__local_length__goto_10290_12 as u64) *% (1 as u64))))
        if ((if __local_re_blocksize__goto_10292_12 > (*__local_ccontext).max_pattern_compiled_length: 1 else: 0) != 0) {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_161 {
        (__local_errorcode__goto_10307_5 = ERR101)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_143
    }

    '__ci_bb_162 {
        (__local_re_blocksize__goto_10292_12 = (__local_re_blocksize__goto_10292_12 +% (sizeof[pcre2_real_code_8]() as usize)))
        (__local_re__goto_10280_18 = (((*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).malloc.unwrap()(__local_re_blocksize__goto_10292_12, (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).memory_data) as *mut pcre2_real_code_8)))
        if ((if __local_re__goto_10280_18 == null: 1 else: 0) != 0) {
            goto '__ci_bb_163
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_163 {
        (__local_errorcode__goto_10307_5 = ERR21)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_143
    }

    '__ci_bb_164 {
        with_memset((((((__local_re__goto_10280_18 as *mut c_char) + (sizeof[pcre2_real_code_8]() as usize)) - ((8 as isize) as usize)) as *mut c_void) as *mut u8), (0 as i32), ((8 as u64) as i64))
        with_memcpy((&raw mut (*__local_re__goto_10280_18).memctl as *mut u8), (&raw const (*__local_ccontext).memctl as *const u8), sizeof[pcre2_memctl]())
        ((*__local_re__goto_10280_18).tables = __local_tables__goto_10282_16)
        ((*__local_re__goto_10280_18).executable_jit = null)
        with_memset(((&(*__local_re__goto_10280_18).start_bitmap[0] as *mut u8) as *mut u8), (0 as i32), ((((32 as u64) *% (sizeof[u8]() as u64)) as u64) as i64))
        ((*__local_re__goto_10280_18).blocksize = __local_re_blocksize__goto_10292_12)
        ((*__local_re__goto_10280_18).code_start = ((((__local_re_blocksize__goto_10292_12 as u64) -% (((__local_length__goto_10290_12 as u64) *% (1 as u64)) as u64)) as u64)))
        ((*__local_re__goto_10280_18).magic_number = ((1346589253 as u32)))
        ((*__local_re__goto_10280_18).compile_options = __local_options)
        ((*__local_re__goto_10280_18).overall_options = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_options)
        ((*__local_re__goto_10280_18).extra_options = __local_xoptions__goto_10298_10)
        ((*__local_re__goto_10280_18).flags = ((((((1 as u32) | ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).external_flags as u32)) as u32) | (__local_setflags__goto_10297_10 as u32)) as u32)))
        ((*__local_re__goto_10280_18).limit_heap = __local_limit_heap__goto_10301_10)
        ((*__local_re__goto_10280_18).limit_match = __local_limit_match__goto_10302_10)
        ((*__local_re__goto_10280_18).limit_depth = __local_limit_depth__goto_10303_10)
        ((*__local_re__goto_10280_18).first_codeunit = ((0 as u32)))
        ((*__local_re__goto_10280_18).last_codeunit = ((0 as u32)))
        ((*__local_re__goto_10280_18).bsr_convention = ((__local_bsr__goto_10306_5 as u16)))
        ((*__local_re__goto_10280_18).newline_convention = ((__local_newline__goto_10305_5 as u16)))
        ((*__local_re__goto_10280_18).max_lookbehind = ((0 as u16)))
        ((*__local_re__goto_10280_18).minlength = ((0 as u16)))
        ((*__local_re__goto_10280_18).top_bracket = ((0 as u16)))
        ((*__local_re__goto_10280_18).top_backref = ((0 as u16)))
        ((*__local_re__goto_10280_18).name_entry_size = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).name_entry_size)
        ((*__local_re__goto_10280_18).name_count = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).names_found)
        ((*__local_re__goto_10280_18).optimization_flags = __local_optim_flags__goto_10313_10)
        (__local_codestart__goto_10286_14 = (__local_re__goto_10280_18 as *mut u8) + ((*__local_re__goto_10280_18).code_start as usize))
        (__local_cb__goto_10281_15.parens_depth = ((0 as u16)))
        (__local_cb__goto_10281_15.assert_depth = ((0 as u16)))
        (__local_cb__goto_10281_15.lastcapture = ((0 as u32)))
        (__local_cb__goto_10281_15.name_table = (__local_re__goto_10280_18 as *mut u8) + (sizeof[pcre2_real_code_8]() as usize))
        (__local_cb__goto_10281_15.start_code = __local_codestart__goto_10286_14)
        (__local_cb__goto_10281_15.req_varyopt = ((0 as u32)))
        (__local_cb__goto_10281_15.had_accept = ((0 as i32)))
        (__local_cb__goto_10281_15.had_pruneorskip = ((0 as i32)))
        (__local_cb__goto_10281_15.char_lists_size = ((0 as u64)))
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).names_found > 0: 1 else: 0) != 0) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_165 {
        (__local_ng__goto_10944_16 = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).named_groups)
        (__local_tablecount__goto_10945_12 = ((0 as u32)))
        (__local_i__goto_10310_10 = ((0 as u32)))
        goto '__ci_bb_167
    }

    '__ci_bb_166 {
        (__local_pptr__goto_10288_11 = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).parsed_pattern)
        (__local_code__goto_10285_14 = __local_codestart__goto_10286_14)
        ((*__local_code__goto_10285_14) = ((137 as u8)))
        (__local_regexrc__goto_10308_5 = ((compile_regex((*__local_re__goto_10280_18).overall_options, (*__local_re__goto_10280_18).extra_options, (&raw mut __local_code__goto_10285_14 as *mut *mut u8), (&raw mut __local_pptr__goto_10288_11 as *mut *mut u32), (&raw mut __local_errorcode__goto_10307_5 as *mut i32), (0 as u32), (&raw mut __local_firstcu__goto_10296_10 as *mut u32), (&raw mut __local_firstcuflags__goto_10295_10 as *mut u32), (&raw mut __local_reqcu__goto_10296_19 as *mut u32), (&raw mut __local_reqcuflags__goto_10295_24 as *mut u32), (null as *mut branch_chain_8), (null as *mut open_capitem), (&raw mut __local_cb__goto_10281_15 as *mut compile_block_8), (null as *mut u64)) as i32)))
        if ((if __local_regexrc__goto_10308_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_167 {
        if ((if __local_i__goto_10310_10 < (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).names_found: 1 else: 0) != 0) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_168 {
        if ((if (*__local_ng__goto_10944_16).length > 0: 1 else: 0) != 0) {
            goto '__ci_bb_171
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_169 {
        (__local_i__goto_10310_10 = (__local_i__goto_10310_10 +% 1))
        (__local_ng__goto_10944_16 = __local_ng__goto_10944_16 + 1)
        goto '__ci_bb_167
    }

    '__ci_bb_170 {
        goto '__ci_bb_173
    }

    '__ci_bb_171 {
        (__local_tablecount__goto_10945_12 = ((_pcre2_compile_add_name_to_table8((&raw mut __local_cb__goto_10281_15 as *mut compile_block_8), __local_ng__goto_10944_16, __local_tablecount__goto_10945_12) as u32)))
        goto '__ci_bb_172
    }

    '__ci_bb_172 {
        goto '__ci_bb_169
    }

    '__ci_bb_173 {
        goto '__ci_bb_174
    }

    '__ci_bb_174 {
        if (0 != 0) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_175 {
        goto '__ci_bb_166
    }

    '__ci_bb_176 {
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (8192 as u32))
        goto '__ci_bb_177
    }

    '__ci_bb_177 {
        ((*__local_re__goto_10280_18).top_bracket = (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).bracount as u16)))
        ((*__local_re__goto_10280_18).top_backref = (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).top_backref as u16)))
        ((*__local_re__goto_10280_18).max_lookbehind = (((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).max_lookbehind as u16)))
        if ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).had_accept != 0) {
            goto '__ci_bb_178
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_178 {
        (__local_reqcu__goto_10296_19 = ((0 as u32)))
        (__local_reqcuflags__goto_10295_24 = ((4294967294 as u32)))
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (8388608 as u32))
        goto '__ci_bb_179
    }

    '__ci_bb_179 {
        (__ci_expr_old_15 = __local_code__goto_10285_14)
        (__local_code__goto_10285_14 = __local_code__goto_10285_14 + 1)
        ((*__ci_expr_old_15) = ((0 as u8)))
        (__local_usedlength__goto_10291_12 = ((((((__local_code__goto_10285_14 as usize) -% (__local_codestart__goto_10286_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        if ((if __local_usedlength__goto_10291_12 > __local_length__goto_10290_12: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_180 {
        goto '__ci_bb_182
    }

    '__ci_bb_181 {
        ((*__local_re__goto_10280_18).blocksize = ((*__local_re__goto_10280_18).blocksize -% ((((__local_length__goto_10290_12 as u64) -% (__local_usedlength__goto_10291_12 as u64)) as u64) *% (1 as u64))))
        (__ci_expr_logic_16 = 0)
        if ((if __local_errorcode__goto_10307_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).had_recurse != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_182 {
        goto '__ci_bb_183
    }

    '__ci_bb_183 {
        if (0 != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_184 {
        (__local_errorcode__goto_10307_5 = ERR23)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_143
    }

    '__ci_bb_185 {
        (__local_ccount__goto_11009_16 = ((0 as u32)))
        (__local_start__goto_11010_7 = ((8 as i32)))
        (__local_rcode__goto_11007_16 = find_recurse(__local_codestart__goto_10286_14, __local_utf__goto_10276_6))
        goto '__ci_bb_187
    }

    '__ci_bb_186 {
        (__ci_expr_logic_17 = 0)
        if ((if __local_errorcode__goto_10307_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if ((__local_optim_flags__goto_10313_10 as u32) & (1 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_213
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_187 {
        if ((if __local_rcode__goto_11007_16 != null: 1 else: 0) != 0) {
            goto '__ci_bb_188
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_188 {
        (__local_groupnumber__goto_11017_12 = ((((((((__local_rcode__goto_11007_16[1]) as i32) << (8 as u32)) as i32) | ((__local_rcode__goto_11007_16[(1 + 1)]) as i32)) as u32) as i32)))
        if ((if __local_groupnumber__goto_11017_12 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_189 {
        (__local_rcode__goto_11007_16 = find_recurse(((__local_rcode__goto_11007_16 + ((1 as isize) as usize)) + ((2 as isize) as usize)), __local_utf__goto_10276_6))
        goto '__ci_bb_187
    }

    '__ci_bb_190 {
        goto '__ci_bb_186
    }

    '__ci_bb_191 {
        (__local_rgroup__goto_11008_14 = ((__local_codestart__goto_10286_14 as *const u8)))
        goto '__ci_bb_193
    }

    '__ci_bb_192 {
        (__local_search_from__goto_11022_18 = ((__local_codestart__goto_10286_14 as *const u8)))
        (__local_rgroup__goto_11008_14 = ((null as *const u8)))
        (__local_i__goto_10310_10 = ((0 as u32)))
        (__local_p__goto_11017_9 = __local_start__goto_11010_7)
        goto '__ci_bb_194
    }

    '__ci_bb_193 {
        ((__local_rcode__goto_11007_16[1]) = ((((((((__local_rgroup__goto_11008_14 as usize) -% (__local_codestart__goto_10286_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u32) >> (8 as u32)) as u8)))
        ((__local_rcode__goto_11007_16[(1 + 1)]) = ((((((((__local_rgroup__goto_11008_14 as usize) -% (__local_codestart__goto_10286_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u32) & (255 as u32)) as u8)))
        goto '__ci_bb_189
    }

    '__ci_bb_194 {
        if ((if __local_i__goto_10310_10 < __local_ccount__goto_11009_16: 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_197
        }
    }

    '__ci_bb_195 {
        if ((if __local_groupnumber__goto_11017_12 == __local_rc__goto_11011_17[__local_p__goto_11017_9].groupnumber: 1 else: 0) != 0) {
            goto '__ci_bb_198
        } else {
            goto '__ci_bb_199
        }
    }

    '__ci_bb_196 {
        (__local_i__goto_10310_10 = (__local_i__goto_10310_10 +% 1))
        (__local_p__goto_11017_9 = (((((__local_p__goto_11017_9 + 1) as i32) & (7 as i32)) as i32)))
        goto '__ci_bb_194
    }

    '__ci_bb_197 {
        if ((if __local_rgroup__goto_11008_14 == null: 1 else: 0) != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_203
        }
    }

    '__ci_bb_198 {
        (__local_rgroup__goto_11008_14 = __local_rc__goto_11011_17[__local_p__goto_11017_9].group)
        goto '__ci_bb_197
    }

    '__ci_bb_199 {
        if ((if __local_groupnumber__goto_11017_12 > __local_rc__goto_11011_17[__local_p__goto_11017_9].groupnumber: 1 else: 0) != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_200 {
        (__local_search_from__goto_11022_18 = __local_rc__goto_11011_17[__local_p__goto_11017_9].group)
        goto '__ci_bb_201
    }

    '__ci_bb_201 {
        goto '__ci_bb_196
    }

    '__ci_bb_202 {
        (__local_rgroup__goto_11008_14 = _pcre2_find_bracket_8(__local_search_from__goto_11022_18, __local_utf__goto_10276_6, __local_groupnumber__goto_11017_12))
        if ((if __local_rgroup__goto_11008_14 == null: 1 else: 0) != 0) {
            goto '__ci_bb_204
        } else {
            goto '__ci_bb_205
        }
    }

    '__ci_bb_203 {
        goto '__ci_bb_193
    }

    '__ci_bb_204 {
        goto '__ci_bb_206
    }

    '__ci_bb_205 {
        (__local_start__goto_11010_7 = __local_start__goto_11010_7 - 1)
        if ((if __local_start__goto_11010_7 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_206 {
        goto '__ci_bb_207
    }

    '__ci_bb_207 {
        if (0 != 0) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_208
        }
    }

    '__ci_bb_208 {
        (__local_errorcode__goto_10307_5 = ERR53)
        goto '__ci_bb_190
    }

    '__ci_bb_209 {
        (__local_start__goto_11010_7 = (((8 - 1) as i32)))
        goto '__ci_bb_210
    }

    '__ci_bb_210 {
        (__local_rc__goto_11011_17[__local_start__goto_11010_7].groupnumber = __local_groupnumber__goto_11017_12)
        (__local_rc__goto_11011_17[__local_start__goto_11010_7].group = __local_rgroup__goto_11008_14)
        if ((if __local_ccount__goto_11009_16 < 8: 1 else: 0) != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_211 {
        (__local_ccount__goto_11009_16 = (__local_ccount__goto_11009_16 +% 1))
        goto '__ci_bb_212
    }

    '__ci_bb_212 {
        goto '__ci_bb_203
    }

    '__ci_bb_213 {
        (__local_temp__goto_11079_16 = __local_codestart__goto_10286_14)
        (__local_possessify_rc__goto_11080_7 = ((_pcre2_auto_possessify_8(__local_temp__goto_11079_16, ((&raw mut __local_cb__goto_10281_15 as *mut compile_block_8) as *const compile_block_8)) as i32)))
        if ((if __local_possessify_rc__goto_11080_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_214 {
        if ((if __local_errorcode__goto_10307_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_215 {
        goto '__ci_bb_217
    }

    '__ci_bb_216 {
        goto '__ci_bb_214
    }

    '__ci_bb_217 {
        goto '__ci_bb_218
    }

    '__ci_bb_218 {
        if (0 != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_219
        }
    }

    '__ci_bb_219 {
        (__local_errorcode__goto_10307_5 = ERR80)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_216
    }

    '__ci_bb_220 {
        goto '__ci_bb_143
    }

    '__ci_bb_221 {
        if ((if (((*__local_re__goto_10280_18).overall_options as u32) & (2147483648 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_222
        } else {
            goto '__ci_bb_223
        }
    }

    '__ci_bb_222 {
        (__local_dotstar_anchor__goto_11103_8 = (((if ((__local_optim_flags__goto_10313_10 as u32) & (2 as u32)) != 0: 1 else: 0) as i32)))
        if (is_anchored((__local_codestart__goto_10286_14 as *const u8), (0 as u32), (&raw mut __local_cb__goto_10281_15 as *mut compile_block_8), (0 as i32), (0 as i32), __local_dotstar_anchor__goto_11103_8) != 0) {
            goto '__ci_bb_224
        } else {
            goto '__ci_bb_225
        }
    }

    '__ci_bb_223 {
        if ((if ((__local_optim_flags__goto_10313_10 as u32) & (4 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_226
        } else {
            goto '__ci_bb_227
        }
    }

    '__ci_bb_224 {
        ((*__local_re__goto_10280_18).overall_options = ((*__local_re__goto_10280_18).overall_options as u32) | (2147483648 as u32))
        goto '__ci_bb_225
    }

    '__ci_bb_225 {
        goto '__ci_bb_223
    }

    '__ci_bb_226 {
        (__local_minminlength__goto_11117_7 = ((0 as i32)))
        if ((if __local_firstcuflags__goto_10295_10 >= 4294967294: 1 else: 0) != 0) {
            goto '__ci_bb_228
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_227 {
        goto '__ci_bb_272
    }

    '__ci_bb_228 {
        (__local_assertedcuflags__goto_11125_14 = ((0 as u32)))
        (__local_assertedcu__goto_11126_14 = ((find_firstassertedcu((__local_codestart__goto_10286_14 as *const u8), (&raw mut __local_assertedcuflags__goto_11125_14 as *mut u32), (0 as u32)) as u32)))
        (__ci_expr_logic_18 = 0)
        if ((if __local_assertedcuflags__goto_11125_14 < 4294967294: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if (if __local_assertedcu__goto_11126_14 != __local_reqcu__goto_10296_19: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_229 {
        if ((if __local_firstcuflags__goto_10295_10 < 4294967294: 1 else: 0) != 0) {
            goto '__ci_bb_232
        } else {
            goto '__ci_bb_233
        }
    }

    '__ci_bb_230 {
        (__local_firstcu__goto_10296_10 = __local_assertedcu__goto_11126_14)
        (__local_firstcuflags__goto_10295_10 = __local_assertedcuflags__goto_11125_14)
        goto '__ci_bb_231
    }

    '__ci_bb_231 {
        goto '__ci_bb_229
    }

    '__ci_bb_232 {
        ((*__local_re__goto_10280_18).first_codeunit = __local_firstcu__goto_10296_10)
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (16 as u32))
        (__local_minminlength__goto_11117_7 = __local_minminlength__goto_11117_7 + 1)
        if ((if ((__local_firstcuflags__goto_10295_10 as u32) & (1 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_235
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_233 {
        if ((if (((*__local_re__goto_10280_18).overall_options as u32) & (2147483648 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_244
        } else {
            goto '__ci_bb_245
        }
    }

    '__ci_bb_234 {
        if ((if __local_reqcuflags__goto_10295_24 < 4294967294: 1 else: 0) != 0) {
            goto '__ci_bb_248
        } else {
            goto '__ci_bb_249
        }
    }

    '__ci_bb_235 {
        if ((if __local_firstcu__goto_10296_10 < 128: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_20: i32 = 0

            var __ci_expr_logic_19: i32 = 0

            if ((if not (__local_utf__goto_10276_6 != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_19 = (if (if not (__local_ucp__goto_10277_6 != 0): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_19 != 0) {
                (__ci_expr_logic_20 = (if (if __local_firstcu__goto_10296_10 < 255: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_21 = (if __ci_expr_logic_20 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_21 != 0) {
            goto '__ci_bb_237
        } else {
            goto '__ci_bb_238
        }
    }

    '__ci_bb_236 {
        goto '__ci_bb_234
    }

    '__ci_bb_237 {
        if ((if ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).fcc[__local_firstcu__goto_10296_10]) != __local_firstcu__goto_10296_10: 1 else: 0) != 0) {
            goto '__ci_bb_240
        } else {
            goto '__ci_bb_241
        }
    }

    '__ci_bb_238 {
        (__ci_expr_logic_23 = 0)
        (__ci_expr_logic_22 = 0)
        if (__local_ucp__goto_10277_6 != 0) {
            (__ci_expr_logic_22 = (if (if not (__local_utf__goto_10276_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_logic_23 = (if (if ((((__local_firstcu__goto_10296_10 as i32) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_firstcu__goto_10296_10 as i32) / 128)] as i32) * 128) + ((__local_firstcu__goto_10296_10 as i32) % 128))] as u32) as usize)).other_case) as u32)) != __local_firstcu__goto_10296_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_242
        } else {
            goto '__ci_bb_243
        }
    }

    '__ci_bb_239 {
        goto '__ci_bb_236
    }

    '__ci_bb_240 {
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (32 as u32))
        goto '__ci_bb_241
    }

    '__ci_bb_241 {
        goto '__ci_bb_239
    }

    '__ci_bb_242 {
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (32 as u32))
        goto '__ci_bb_243
    }

    '__ci_bb_243 {
        goto '__ci_bb_239
    }

    '__ci_bb_244 {
        (__local_dotstar_anchor__goto_11181_10 = (((if ((__local_optim_flags__goto_10313_10 as u32) & (2 as u32)) != 0: 1 else: 0) as i32)))
        if (is_startline((__local_codestart__goto_10286_14 as *const u8), (0 as u32), (&raw mut __local_cb__goto_10281_15 as *mut compile_block_8), (0 as i32), (0 as i32), __local_dotstar_anchor__goto_11181_10) != 0) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_245 {
        goto '__ci_bb_234
    }

    '__ci_bb_246 {
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (512 as u32))
        goto '__ci_bb_247
    }

    '__ci_bb_247 {
        goto '__ci_bb_245
    }

    '__ci_bb_248 {
        if ((if (((*__local_re__goto_10280_18).overall_options as u32) & (524288 as u32)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if (if __local_firstcuflags__goto_10295_10 >= 4294967294: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            (__ci_expr_logic_25 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_25 = (if (if ((__local_firstcu__goto_10296_10 as u32) & (128 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            (__ci_expr_logic_26 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_26 = (if (if ((__local_reqcu__goto_10296_19 as u32) & (128 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_250
        } else {
            goto '__ci_bb_251
        }
    }

    '__ci_bb_249 {
        (__local_study_rc__goto_11118_7 = ((_pcre2_study_8(__local_re__goto_10280_18) as i32)))
        if ((if __local_study_rc__goto_11118_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_263
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_250 {
        (__local_minminlength__goto_11117_7 = __local_minminlength__goto_11117_7 + 1)
        goto '__ci_bb_251
    }

    '__ci_bb_251 {
        if ((if (((*__local_re__goto_10280_18).overall_options as u32) & (2147483648 as u32)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_27 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_27 = (if (if ((__local_reqcuflags__goto_10295_24 as u32) & (2 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_27 != 0) {
            goto '__ci_bb_252
        } else {
            goto '__ci_bb_253
        }
    }

    '__ci_bb_252 {
        ((*__local_re__goto_10280_18).last_codeunit = __local_reqcu__goto_10296_19)
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (128 as u32))
        if ((if ((__local_reqcuflags__goto_10295_24 as u32) & (1 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_254
        } else {
            goto '__ci_bb_255
        }
    }

    '__ci_bb_253 {
        goto '__ci_bb_249
    }

    '__ci_bb_254 {
        if ((if __local_reqcu__goto_10296_19 < 128: 1 else: 0) != 0) {
            (__ci_expr_logic_30 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_29: i32 = 0

            var __ci_expr_logic_28: i32 = 0

            if ((if not (__local_utf__goto_10276_6 != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_28 = (if (if not (__local_ucp__goto_10277_6 != 0): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_28 != 0) {
                (__ci_expr_logic_29 = (if (if __local_reqcu__goto_10296_19 < 255: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_30 = (if __ci_expr_logic_29 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_30 != 0) {
            goto '__ci_bb_256
        } else {
            goto '__ci_bb_257
        }
    }

    '__ci_bb_255 {
        goto '__ci_bb_253
    }

    '__ci_bb_256 {
        if ((if ((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).fcc[__local_reqcu__goto_10296_19]) != __local_reqcu__goto_10296_19: 1 else: 0) != 0) {
            goto '__ci_bb_259
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_257 {
        (__ci_expr_logic_32 = 0)
        (__ci_expr_logic_31 = 0)
        if (__local_ucp__goto_10277_6 != 0) {
            (__ci_expr_logic_31 = (if (if not (__local_utf__goto_10276_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            (__ci_expr_logic_32 = (if (if ((((__local_reqcu__goto_10296_19 as i32) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_reqcu__goto_10296_19 as i32) / 128)] as i32) * 128) + ((__local_reqcu__goto_10296_19 as i32) % 128))] as u32) as usize)).other_case) as u32)) != __local_reqcu__goto_10296_19: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            goto '__ci_bb_261
        } else {
            goto '__ci_bb_262
        }
    }

    '__ci_bb_258 {
        goto '__ci_bb_255
    }

    '__ci_bb_259 {
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (256 as u32))
        goto '__ci_bb_260
    }

    '__ci_bb_260 {
        goto '__ci_bb_258
    }

    '__ci_bb_261 {
        ((*__local_re__goto_10280_18).flags = ((*__local_re__goto_10280_18).flags as u32) | (256 as u32))
        goto '__ci_bb_262
    }

    '__ci_bb_262 {
        goto '__ci_bb_258
    }

    '__ci_bb_263 {
        goto '__ci_bb_265
    }

    '__ci_bb_264 {
        (__ci_expr_logic_33 = 0)
        if ((if (((*__local_re__goto_10280_18).flags as u32) & (64 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_33 = (if (if __local_minminlength__goto_11117_7 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_33 != 0) {
            goto '__ci_bb_268
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_265 {
        goto '__ci_bb_266
    }

    '__ci_bb_266 {
        if (0 != 0) {
            goto '__ci_bb_265
        } else {
            goto '__ci_bb_267
        }
    }

    '__ci_bb_267 {
        (__local_errorcode__goto_10307_5 = ERR31)
        (__local_cb__goto_10281_15.erroroffset = ((0 as u64)))
        goto '__ci_bb_143
    }

    '__ci_bb_268 {
        (__local_minminlength__goto_11117_7 = ((1 as i32)))
        goto '__ci_bb_269
    }

    '__ci_bb_269 {
        if ((if (*__local_re__goto_10280_18).minlength < __local_minminlength__goto_11117_7: 1 else: 0) != 0) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_271
        }
    }

    '__ci_bb_270 {
        ((*__local_re__goto_10280_18).minlength = ((__local_minminlength__goto_11117_7 as u16)))
        goto '__ci_bb_271
    }

    '__ci_bb_271 {
        goto '__ci_bb_227
    }

    '__ci_bb_272 {
        goto '__ci_bb_273
    }

    '__ci_bb_273 {
        if (0 != 0) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_274
        }
    }

    '__ci_bb_274 {
        goto '__ci_bb_140
    }

    '__ci_bb_275 {
        (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).free.unwrap()(((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).parsed_pattern as *mut c_void), (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).memory_data)
        goto '__ci_bb_276
    }

    '__ci_bb_276 {
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).named_group_list_size > 20: 1 else: 0) != 0) {
            goto '__ci_bb_277
        } else {
            goto '__ci_bb_278
        }
    }

    '__ci_bb_277 {
        (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).free.unwrap()(((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).named_groups as *mut c_void), (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).memory_data)
        goto '__ci_bb_278
    }

    '__ci_bb_278 {
        if ((if (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).groupinfo != (&__local_stack_groupinfo__goto_10318_10[0] as *mut u32): 1 else: 0) != 0) {
            goto '__ci_bb_279
        } else {
            goto '__ci_bb_280
        }
    }

    '__ci_bb_279 {
        (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).free.unwrap()(((*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).groupinfo as *mut c_void), (*(&raw const (*__local_ccontext).memctl as *const pcre2_memctl)).memory_data)
        goto '__ci_bb_280
    }

    '__ci_bb_280 {
        return __local_re__goto_10280_18
    }

    '__ci_bb_281 {
        goto '__ci_bb_282
    }

    '__ci_bb_282 {
        if (0 != 0) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_283
        }
    }

    '__ci_bb_283 {
        goto '__ci_bb_284
    }

    '__ci_bb_284 {
        goto '__ci_bb_285
    }

    '__ci_bb_285 {
        if (0 != 0) {
            goto '__ci_bb_284
        } else {
            goto '__ci_bb_286
        }
    }

    '__ci_bb_286 {
        ((*__param_erroroffset) = ((((((__local_ptr__goto_10287_12 as usize) -% (__local_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        goto '__ci_bb_100
    }

    '__ci_bb_287 {
        (__local_current_data__goto_11324_17 = (*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).first_data)
        goto '__ci_bb_289
    }

    '__ci_bb_288 {
        goto '__ci_bb_140
    }

    '__ci_bb_289 {
        (__local_next_data__goto_11327_19 = (*__local_current_data__goto_11324_17).next)
        (*(&raw const (*(*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).cx).memctl as *const pcre2_memctl)).free.unwrap()((__local_current_data__goto_11324_17 as *mut c_void), (*(&raw const (*(*(&raw const __local_cb__goto_10281_15 as *const compile_block_8)).cx).memctl as *const pcre2_memctl)).memory_data)
        (__local_current_data__goto_11324_17 = __local_next_data__goto_11327_19)
        goto '__ci_bb_290
    }

    '__ci_bb_290 {
        if ((if __local_current_data__goto_11324_17 != null: 1 else: 0) != 0) {
            goto '__ci_bb_289
        } else {
            goto '__ci_bb_291
        }
    }

    '__ci_bb_291 {
        goto '__ci_bb_288
    }

    __ci_unreachable()

}

pub unsafe fn pcre2_code_free_8(__param_code: *mut pcre2_real_code_8) {
    var __local_ref_count: *mut u64

    if ((if __param_code != null: 1 else: 0) != 0) {
        if ((if (((*__param_code).flags as u32) & (262144 as u32)) != 0: 1 else: 0) != 0) {
            (__local_ref_count = ((((*__param_code).tables + ((((512 + 320) + 256) as isize) as usize)) as *mut u64)))

            if ((if (*__local_ref_count) > 0: 1 else: 0) != 0) {
                ((*__local_ref_count) = ((*__local_ref_count) -% 1))

                if ((if (*__local_ref_count) == 0: 1 else: 0) != 0) {
                    (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).free.unwrap()(((*__param_code).tables as *mut c_void), (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).memory_data)
                }

            }

        }

        (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).free.unwrap()((__param_code as *mut c_void), (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).memory_data)

    }

}

pub unsafe fn pcre2_code_copy_8(__param_code: *const pcre2_real_code_8) -> *mut pcre2_real_code_8 {
    var __local_ref_count: *mut u64

    var __local_newcode: *mut pcre2_real_code_8

    if ((if __param_code == null: 1 else: 0) != 0) {
        return ((null as *mut pcre2_real_code_8))
    }

    (__local_newcode = (((*(&raw const (*__param_code).memctl as *const pcre2_memctl)).malloc.unwrap()((*__param_code).blocksize, (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).memory_data) as *mut pcre2_real_code_8)))

    if ((if __local_newcode == null: 1 else: 0) != 0) {
        return ((null as *mut pcre2_real_code_8))
    }

    with_memcpy(((__local_newcode as *mut c_void) as *mut u8), ((__param_code as *const c_void) as *const u8), ((*__param_code).blocksize as i64))

    ((*__local_newcode).executable_jit = null)

    if ((if (((*__param_code).flags as u32) & (262144 as u32)) != 0: 1 else: 0) != 0) {
        (__local_ref_count = ((((*__param_code).tables + ((((512 + 320) + 256) as isize) as usize)) as *mut u64)))

        ((*__local_ref_count) = ((*__local_ref_count) +% 1))

    }

    return __local_newcode

}

pub unsafe fn pcre2_code_copy_with_tables_8(__param_code: *const pcre2_real_code_8) -> *mut pcre2_real_code_8 {
    var __local_ref_count: *mut u64

    var __local_newcode: *mut pcre2_real_code_8

    var __local_newtables: *mut u8

    if ((if __param_code == null: 1 else: 0) != 0) {
        return ((null as *mut pcre2_real_code_8))
    }

    (__local_newcode = (((*(&raw const (*__param_code).memctl as *const pcre2_memctl)).malloc.unwrap()((*__param_code).blocksize, (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).memory_data) as *mut pcre2_real_code_8)))

    if ((if __local_newcode == null: 1 else: 0) != 0) {
        return ((null as *mut pcre2_real_code_8))
    }

    with_memcpy(((__local_newcode as *mut c_void) as *mut u8), ((__param_code as *const c_void) as *const u8), ((*__param_code).blocksize as i64))

    ((*__local_newcode).executable_jit = null)

    (__local_newtables = (((*(&raw const (*__param_code).memctl as *const pcre2_memctl)).malloc.unwrap()((((1088 as u64) +% (sizeof[u64]() as u64)) as u64), (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).memory_data) as *mut u8)))

    if ((if __local_newtables == null: 1 else: 0) != 0) {
        (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).free.unwrap()((__local_newcode as *mut c_void), (*(&raw const (*__param_code).memctl as *const pcre2_memctl)).memory_data)

        return ((null as *mut pcre2_real_code_8))

    }

    with_memcpy(((__local_newtables as *mut c_void) as *mut u8), (((*__param_code).tables as *const c_void) as *const u8), ((1088 as u64) as i64))

    (__local_ref_count = (((__local_newtables + ((((512 + 320) + 256) as isize) as usize)) as *mut u64)))

    ((*__local_ref_count) = ((1 as u64)))

    ((*__local_newcode).tables = ((__local_newtables as *const u8)))

    ((*__local_newcode).flags = ((*__local_newcode).flags as u32) | (262144 as u32))

    return __local_newcode

}

pub unsafe fn _pcre2_check_escape_8(__param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_chptr: *mut u32, __param_errorcodeptr: *mut i32, __param_options: u32, __param_xoptions: u32, __param_bracount: u32, __param_isclass: i32, __param_cb: *mut compile_block_8) -> i32 {
    var __local_utf__goto_1494_6: i32 = 0

    var __local_alt_bsux__goto_1495_6: i32 = 0

    var __local_ptr__goto_1497_12: *const u8 = null

    var __local_c__goto_1498_10: u32 = 0

    var __local_cc__goto_1498_13: u32 = 0

    var __local_escape__goto_1499_5: i32 = 0

    var __local_i__goto_1500_5: i32 = 0

    var __local_p__goto_1546_18: *const u8 = null

    var __local_s__goto_1611_7: i32 = 0

    var __local_oldptr__goto_1612_14: *const u8 = null

    var __local_overflow__goto_1613_8: i32 = 0

    var __local_xc__goto_1652_16: u32 = 0

    var __local_hptr__goto_1658_20: *const u8 = null

    var __local_p__goto_1757_18: *const u8 = null

    var __local_p__goto_1800_18: *const u8 = null

    var __local_xc__goto_2033_16: u32 = 0

    var __ci_expr_old_0: *const u8 = null

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_old_2: *const u8 = null

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_8: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_14: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_logic_18: i32 = 0

    var __ci_expr_logic_19: i32 = 0

    var __ci_expr_logic_24: i32 = 0

    var __ci_expr_logic_23: i32 = 0

    var __ci_expr_logic_22: i32 = 0

    var __ci_expr_logic_21: i32 = 0

    var __ci_expr_logic_20: i32 = 0

    var __ci_expr_logic_25: i32 = 0

    var __ci_expr_logic_26: i32 = 0

    var __ci_expr_logic_28: i32 = 0

    var __ci_expr_logic_27: i32 = 0

    var __ci_expr_logic_30: i32 = 0

    var __ci_expr_logic_29: i32 = 0

    var __ci_expr_logic_31: i32 = 0

    var __ci_expr_logic_32: i32 = 0

    var __ci_expr_logic_34: i32 = 0

    var __ci_expr_logic_36: i32 = 0

    var __ci_expr_logic_37: i32 = 0

    var __ci_expr_logic_42: i32 = 0

    var __ci_expr_logic_41: i32 = 0

    var __ci_expr_logic_40: i32 = 0

    var __ci_expr_logic_39: i32 = 0

    var __ci_expr_logic_38: i32 = 0

    var __ci_expr_logic_44: i32 = 0

    var __ci_expr_logic_43: i32 = 0

    var __ci_expr_logic_48: i32 = 0

    var __ci_expr_logic_47: i32 = 0

    var __ci_expr_logic_46: i32 = 0

    var __ci_expr_old_45: i32 = 0

    var __ci_expr_old_49: *const u8 = null

    var __ci_expr_logic_51: i32 = 0

    var __ci_expr_logic_50: i32 = 0

    var __ci_expr_logic_52: i32 = 0

    var __ci_expr_logic_54: i32 = 0

    var __ci_expr_logic_55: i32 = 0

    var __ci_expr_logic_57: i32 = 0

    var __ci_expr_logic_56: i32 = 0

    var __ci_expr_old_58: *const u8 = null

    var __ci_expr_logic_59: i32 = 0

    var __ci_expr_logic_61: i32 = 0

    var __ci_expr_logic_63: i32 = 0

    var __ci_expr_logic_62: i32 = 0

    var __ci_expr_logic_66: i32 = 0

    var __ci_expr_logic_65: i32 = 0

    var __ci_expr_logic_64: i32 = 0

    var __ci_expr_logic_67: i32 = 0

    var __ci_expr_logic_68: i32 = 0

    var __ci_expr_logic_70: i32 = 0

    var __ci_expr_logic_71: i32 = 0

    var __ci_expr_logic_72: i32 = 0

    var __ci_expr_logic_73: i32 = 0

    var __ci_expr_logic_76: i32 = 0

    var __ci_expr_logic_74: i32 = 0

    var __ci_expr_logic_78: i32 = 0

    var __ci_expr_logic_79: i32 = 0

    var __ci_expr_logic_82: i32 = 0

    var __ci_expr_logic_81: i32 = 0

    var __ci_expr_logic_80: i32 = 0

    var __ci_expr_logic_83: i32 = 0

    var __ci_expr_logic_84: i32 = 0

    var __ci_expr_logic_85: i32 = 0

    var __ci_expr_logic_86: i32 = 0

    var __ci_expr_logic_87: i32 = 0

    var __ci_expr_logic_88: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_utf__goto_1494_6 = (((if ((__param_options as u32) & (524288 as u32)) != 0: 1 else: 0) as i32)))
        (__local_alt_bsux__goto_1495_6 = (((if ((((__param_options as u32) & (2 as u32)) as u32) | (((__param_xoptions as u32) & (32 as u32)) as u32)) != 0: 1 else: 0) as i32)))
        (__local_ptr__goto_1497_12 = (*__param_ptrptr))
        (__local_escape__goto_1499_5 = ((0 as i32)))
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        ((*__param_errorcodeptr) = ERR1)
        return 0
    }

    '__ci_bb_2 {
        (__ci_expr_old_0 = __local_ptr__goto_1497_12)
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__local_c__goto_1498_10 = (((*__ci_expr_old_0) as u32)))
        (__ci_expr_logic_1 = 0)
        if (__local_utf__goto_1494_6 != 0) {
            (__ci_expr_logic_1 = (if (if __local_c__goto_1498_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_3 {
        if ((if ((__local_c__goto_1498_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_4 {
        ((*__param_errorcodeptr) = ((0 as i32)))
        if ((if __local_c__goto_1498_10 < 48: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_c__goto_1498_10 > 122: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_5 {
        (__ci_expr_old_2 = __local_ptr__goto_1497_12)
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__local_c__goto_1498_10 = ((((((((__local_c__goto_1498_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_2) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_7
    }

    '__ci_bb_6 {
        if ((if ((__local_c__goto_1498_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_7 {
        goto '__ci_bb_4
    }

    '__ci_bb_8 {
        (__local_c__goto_1498_10 = ((((((((((__local_c__goto_1498_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr__goto_1497_12) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_1497_12[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + ((2 as isize) as usize))
        goto '__ci_bb_10
    }

    '__ci_bb_9 {
        if ((if ((__local_c__goto_1498_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_10 {
        goto '__ci_bb_7
    }

    '__ci_bb_11 {
        (__local_c__goto_1498_10 = ((((((((((((__local_c__goto_1498_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr__goto_1497_12) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_1497_12[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_1497_12[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + ((3 as isize) as usize))
        goto '__ci_bb_13
    }

    '__ci_bb_12 {
        if ((if ((__local_c__goto_1498_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        goto '__ci_bb_10
    }

    '__ci_bb_14 {
        (__local_c__goto_1498_10 = ((((((((((((((__local_c__goto_1498_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr__goto_1497_12) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_1497_12[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_1497_12[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_1497_12[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + ((4 as isize) as usize))
        goto '__ci_bb_16
    }

    '__ci_bb_15 {
        (__local_c__goto_1498_10 = ((((((((((((((((__local_c__goto_1498_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr__goto_1497_12) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_1497_12[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_1497_12[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_1497_12[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_1497_12[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + ((5 as isize) as usize))
        goto '__ci_bb_16
    }

    '__ci_bb_16 {
        goto '__ci_bb_13
    }

    '__ci_bb_17 {
        goto '__ci_bb_19
    }

    '__ci_bb_18 {
        (__local_i__goto_1500_5 = ((escapes[((__local_c__goto_1498_10 as u32) -% (48 as u32))] as i32)))
        if ((if __local_i__goto_1500_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_19 {
        goto '__ci_bb_58
    }

    '__ci_bb_20 {
        if ((if __local_i__goto_1500_5 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_21 {
        if ((if __param_cb == null: 1 else: 0) != 0) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_22 {
        goto '__ci_bb_19
    }

    '__ci_bb_23 {
        (__local_c__goto_1498_10 = ((__local_i__goto_1500_5 as u32)))
        (__ci_expr_logic_4 = 0)
        if ((if __local_c__goto_1498_10 == 13: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if ((__param_xoptions as u32) & (16 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_24 {
        (__local_escape__goto_1499_5 = (((0 - __local_i__goto_1500_5) as i32)))
        (__ci_expr_logic_7 = 0)
        if ((if __param_cb != null: 1 else: 0) != 0) {
            var __ci_expr_logic_6: i32

            var __ci_expr_logic_5: i32

            if ((if __local_escape__goto_1499_5 == ESC_P: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if __local_escape__goto_1499_5 == ESC_p: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if __local_escape__goto_1499_5 == ESC_X: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_7 = (if __ci_expr_logic_6 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_25 {
        goto '__ci_bb_22
    }

    '__ci_bb_26 {
        (__local_c__goto_1498_10 = ((10 as u32)))
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        goto '__ci_bb_25
    }

    '__ci_bb_28 {
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (1048576 as u32))
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        (__ci_expr_logic_9 = 0)
        (__ci_expr_logic_8 = 0)
        if ((if __local_escape__goto_1499_5 == ESC_N: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_logic_9 = (if (if (*__local_ptr__goto_1497_12) == 123: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        (__local_p__goto_1546_18 = __local_ptr__goto_1497_12 + ((1 as isize) as usize))
        goto '__ci_bb_32
    }

    '__ci_bb_31 {
        goto '__ci_bb_25
    }

    '__ci_bb_32 {
        (__ci_expr_logic_11 = 0)
        if ((if __local_p__goto_1546_18 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_10: i32

            if ((if (*__local_p__goto_1546_18) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_10 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_10 = (if (if (*__local_p__goto_1546_18) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_11 = (if __ci_expr_logic_10 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_33 {
        (__local_p__goto_1546_18 = __local_p__goto_1546_18 + 1)
        goto '__ci_bb_32
    }

    '__ci_bb_34 {
        (__ci_expr_logic_13 = 0)
        (__ci_expr_logic_12 = 0)
        if ((if ((((__param_ptrend as usize) -% (__local_p__goto_1546_18 as usize)) as i64) / (sizeof[u8]() as i64)) > 1: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if (if (*__local_p__goto_1546_18) == 85: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_logic_13 = (if (if (__local_p__goto_1546_18[1]) == 43: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_35 {
        if (__local_utf__goto_1494_6 != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_36 {
        if (__param_isclass != 0) {
            (__ci_expr_logic_18 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_18 = (if (if __param_cb == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_37 {
        goto '__ci_bb_31
    }

    '__ci_bb_38 {
        (__local_ptr__goto_1497_12 = __local_p__goto_1546_18 + ((2 as isize) as usize))
        (__local_escape__goto_1499_5 = ((0 as i32)))
        goto '__ci_bb_40
    }

    '__ci_bb_39 {
        (__local_ptr__goto_1497_12 = __local_p__goto_1546_18 + ((2 as isize) as usize))
        goto '__ci_bb_41
    }

    '__ci_bb_40 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_71 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_71 = (if (if (*__local_ptr__goto_1497_12) == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_71 != 0) {
            goto '__ci_bb_225
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_41 {
        (__ci_expr_logic_14 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if xdigitab[(*__local_ptr__goto_1497_12)] != 255: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_42 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_41
    }

    '__ci_bb_43 {
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        (__ci_expr_logic_16 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_15: i32

            if ((if (*__local_ptr__goto_1497_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_15 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_15 = (if (if (*__local_ptr__goto_1497_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_16 = (if __ci_expr_logic_15 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_45 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_44
    }

    '__ci_bb_46 {
        (__ci_expr_logic_17 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if (*__local_ptr__goto_1497_12) == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_47 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        ((*__param_errorcodeptr) = ERR93)
        goto '__ci_bb_37
    }

    '__ci_bb_49 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        ((*__param_errorcodeptr) = ERR37)
        goto '__ci_bb_51
    }

    '__ci_bb_50 {
        (__ci_expr_logic_19 = 0)
        if ((if not (read_repeat_counts((&raw mut __local_p__goto_1546_18 as *mut *const u8), __param_ptrend, (null as *mut u32), (null as *mut u32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if (if (*__param_errorcodeptr) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_51 {
        goto '__ci_bb_37
    }

    '__ci_bb_52 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        ((*__param_errorcodeptr) = ERR37)
        goto '__ci_bb_53
    }

    '__ci_bb_53 {
        goto '__ci_bb_51
    }

    '__ci_bb_54 {
        (__ci_expr_logic_24 = 0)
        (__ci_expr_logic_23 = 0)
        (__ci_expr_logic_22 = 0)
        (__ci_expr_logic_21 = 0)
        (__ci_expr_logic_20 = 0)
        if ((if __local_c__goto_1498_10 >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if __local_c__goto_1498_10 <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_20 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if (if __local_c__goto_1498_10 != 99: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_logic_22 = (if (if __local_c__goto_1498_10 != 111: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_logic_23 = (if (if __local_c__goto_1498_10 != 120: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            (__ci_expr_logic_24 = (if (if __local_c__goto_1498_10 != 103: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_55 {
        goto '__ci_bb_59
    }

    '__ci_bb_56 {
        ((*__param_errorcodeptr) = ERR3)
        goto '__ci_bb_58
    }

    '__ci_bb_57 {
        (__local_alt_bsux__goto_1495_6 = ((0 as i32)))
        goto '__ci_bb_55
    }

    '__ci_bb_58 {
        ((*__param_ptrptr) = __local_ptr__goto_1497_12)
        ((*__param_chptr) = __local_c__goto_1498_10)
        return __local_escape__goto_1499_5
    }

    '__ci_bb_59 {
        if (__local_c__goto_1498_10 == 70) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_261
        }
    }

    '__ci_bb_60 {
        goto '__ci_bb_22
    }

    '__ci_bb_61 {
        ((*__param_errorcodeptr) = ERR37)
        goto '__ci_bb_60
    }

    '__ci_bb_62 {
        if ((if not (__local_alt_bsux__goto_1495_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_63 {
        ((*__param_errorcodeptr) = ERR37)
        goto '__ci_bb_65
    }

    '__ci_bb_64 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_65 {
        goto '__ci_bb_60
    }

    '__ci_bb_66 {
        goto '__ci_bb_60
    }

    '__ci_bb_67 {
        (__ci_expr_logic_25 = 0)
        if ((if (*__local_ptr__goto_1497_12) == 123: 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if (if ((__param_xoptions as u32) & (32 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_68 {
        (__local_hptr__goto_1658_20 = __local_ptr__goto_1497_12 + ((1 as isize) as usize))
        (__local_cc__goto_1498_13 = ((0 as u32)))
        goto '__ci_bb_71
    }

    '__ci_bb_69 {
        if ((if ((((__param_ptrend as usize) -% (__local_ptr__goto_1497_12 as usize)) as i64) / (sizeof[u8]() as i64)) < 4: 1 else: 0) != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_70 {
        if (__local_utf__goto_1494_6 != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_91
        }
    }

    '__ci_bb_71 {
        (__ci_expr_logic_26 = 0)
        if ((if __local_hptr__goto_1658_20 < __param_ptrend: 1 else: 0) != 0) {
            (__local_xc__goto_1652_16 = ((xdigitab[(*__local_hptr__goto_1658_20)] as u32)))

            (__ci_expr_logic_26 = (if (if __local_xc__goto_1652_16 != 255: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_72 {
        if ((if ((__local_cc__goto_1498_13 as u32) & (4026531840 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_73 {
        if ((if __local_hptr__goto_1658_20 == (__local_ptr__goto_1497_12 + ((1 as isize) as usize)): 1 else: 0) != 0) {
            (__ci_expr_logic_27 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_27 = (if (if __local_hptr__goto_1658_20 >= __param_ptrend: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_27 != 0) {
            (__ci_expr_logic_28 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_28 = (if (if (*__local_hptr__goto_1658_20) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_28 != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_74 {
        ((*__param_errorcodeptr) = ERR77)
        (__local_ptr__goto_1497_12 = __local_hptr__goto_1658_20)
        goto '__ci_bb_73
    }

    '__ci_bb_75 {
        (__local_cc__goto_1498_13 = ((((((__local_cc__goto_1498_13 as u32) << (4 as u32)) as u32) | (__local_xc__goto_1652_16 as u32)) as u32)))
        (__local_hptr__goto_1658_20 = __local_hptr__goto_1658_20 + 1)
        goto '__ci_bb_71
    }

    '__ci_bb_76 {
        if (__param_isclass != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_77 {
        (__local_c__goto_1498_10 = __local_cc__goto_1498_13)
        (__local_ptr__goto_1497_12 = __local_hptr__goto_1658_20 + ((1 as isize) as usize))
        goto '__ci_bb_70
    }

    '__ci_bb_78 {
        goto '__ci_bb_60
    }

    '__ci_bb_79 {
        (__local_escape__goto_1499_5 = ESC_ub)
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_60
    }

    '__ci_bb_80 {
        goto '__ci_bb_60
    }

    '__ci_bb_81 {
        (__local_cc__goto_1498_13 = ((xdigitab[(__local_ptr__goto_1497_12[0])] as u32)))
        if ((if __local_cc__goto_1498_13 == 255: 1 else: 0) != 0) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_83
        }
    }

    '__ci_bb_82 {
        goto '__ci_bb_60
    }

    '__ci_bb_83 {
        (__local_xc__goto_1652_16 = ((xdigitab[(__local_ptr__goto_1497_12[1])] as u32)))
        if ((if __local_xc__goto_1652_16 == 255: 1 else: 0) != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_84 {
        goto '__ci_bb_60
    }

    '__ci_bb_85 {
        (__local_cc__goto_1498_13 = ((((((__local_cc__goto_1498_13 as u32) << (4 as u32)) as u32) | (__local_xc__goto_1652_16 as u32)) as u32)))
        (__local_xc__goto_1652_16 = ((xdigitab[(__local_ptr__goto_1497_12[2])] as u32)))
        if ((if __local_xc__goto_1652_16 == 255: 1 else: 0) != 0) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_86 {
        goto '__ci_bb_60
    }

    '__ci_bb_87 {
        (__local_cc__goto_1498_13 = ((((((__local_cc__goto_1498_13 as u32) << (4 as u32)) as u32) | (__local_xc__goto_1652_16 as u32)) as u32)))
        (__local_xc__goto_1652_16 = ((xdigitab[(__local_ptr__goto_1497_12[3])] as u32)))
        if ((if __local_xc__goto_1652_16 == 255: 1 else: 0) != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_88 {
        goto '__ci_bb_60
    }

    '__ci_bb_89 {
        (__local_c__goto_1498_10 = ((((((__local_cc__goto_1498_13 as u32) << (4 as u32)) as u32) | (__local_xc__goto_1652_16 as u32)) as u32)))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + ((4 as isize) as usize))
        goto '__ci_bb_70
    }

    '__ci_bb_90 {
        if ((if __local_c__goto_1498_10 > 1114111: 1 else: 0) != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_94
        }
    }

    '__ci_bb_91 {
        if ((if __local_c__goto_1498_10 > ((4294967295 as u32) >> ((32 - 8) as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_92 {
        goto '__ci_bb_65
    }

    '__ci_bb_93 {
        ((*__param_errorcodeptr) = ERR77)
        goto '__ci_bb_95
    }

    '__ci_bb_94 {
        (__ci_expr_logic_30 = 0)
        (__ci_expr_logic_29 = 0)
        if ((if __local_c__goto_1498_10 >= 55296: 1 else: 0) != 0) {
            (__ci_expr_logic_29 = (if (if __local_c__goto_1498_10 <= 57343: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_29 != 0) {
            (__ci_expr_logic_30 = (if (if ((__param_xoptions as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_30 != 0) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_95 {
        goto '__ci_bb_92
    }

    '__ci_bb_96 {
        ((*__param_errorcodeptr) = ERR73)
        goto '__ci_bb_97
    }

    '__ci_bb_97 {
        goto '__ci_bb_95
    }

    '__ci_bb_98 {
        ((*__param_errorcodeptr) = ERR77)
        goto '__ci_bb_99
    }

    '__ci_bb_99 {
        goto '__ci_bb_92
    }

    '__ci_bb_100 {
        if ((if not (__local_alt_bsux__goto_1495_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_101 {
        ((*__param_errorcodeptr) = ERR37)
        goto '__ci_bb_102
    }

    '__ci_bb_102 {
        goto '__ci_bb_60
    }

    '__ci_bb_103 {
        if (__param_isclass != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_105
        }
    }

    '__ci_bb_104 {
        goto '__ci_bb_60
    }

    '__ci_bb_105 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_107
        }
    }

    '__ci_bb_106 {
        ((*__param_errorcodeptr) = ERR57)
        goto '__ci_bb_60
    }

    '__ci_bb_107 {
        if ((if __param_cb == null: 1 else: 0) != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_108 {
        if ((if (*__local_ptr__goto_1497_12) != 60: 1 else: 0) != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_109 {
        if ((if (*__local_ptr__goto_1497_12) == 60: 1 else: 0) != 0) {
            (__ci_expr_logic_32 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_32 = (if (if (*__local_ptr__goto_1497_12) == 39: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_110 {
        ((*__param_errorcodeptr) = ERR57)
        goto '__ci_bb_60
    }

    '__ci_bb_111 {
        (__local_p__goto_1757_18 = __local_ptr__goto_1497_12 + ((1 as isize) as usize))
        if ((if not (read_number((&raw mut __local_p__goto_1757_18 as *mut *const u8), __param_ptrend, (-1 as i32), (65535 as u32), (161 as u32), (&raw mut __local_s__goto_1611_7 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_112 {
        if ((if (*__param_errorcodeptr) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_115
        }
    }

    '__ci_bb_113 {
        if ((if __local_p__goto_1757_18 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_31 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_31 = (if (if (*__local_p__goto_1757_18) != 62: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_114 {
        (__local_escape__goto_1499_5 = ESC_g)
        goto '__ci_bb_115
    }

    '__ci_bb_115 {
        goto '__ci_bb_60
    }

    '__ci_bb_116 {
        (__local_ptr__goto_1497_12 = __local_p__goto_1757_18)
        ((*__param_errorcodeptr) = ERR119)
        goto '__ci_bb_60
    }

    '__ci_bb_117 {
        (__local_ptr__goto_1497_12 = __local_p__goto_1757_18 + ((1 as isize) as usize))
        (__local_escape__goto_1499_5 = (((0 - (__local_s__goto_1611_7 + 1)) as i32)))
        goto '__ci_bb_60
    }

    '__ci_bb_118 {
        (__local_escape__goto_1499_5 = ESC_g)
        goto '__ci_bb_60
    }

    '__ci_bb_119 {
        if ((if (*__local_ptr__goto_1497_12) == 123: 1 else: 0) != 0) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_121
        }
    }

    '__ci_bb_120 {
        (__local_p__goto_1800_18 = __local_ptr__goto_1497_12 + ((1 as isize) as usize))
        goto '__ci_bb_123
    }

    '__ci_bb_121 {
        if ((if not (read_number((&raw mut __local_ptr__goto_1497_12 as *mut *const u8), __param_ptrend, (__param_bracount as i32), (65535 as u32), (161 as u32), (&raw mut __local_s__goto_1611_7 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_122 {
        if ((if __local_s__goto_1611_7 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_139
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_123 {
        (__ci_expr_logic_34 = 0)
        if ((if __local_p__goto_1800_18 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_33: i32

            if ((if (*__local_p__goto_1800_18) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_33 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_33 = (if (if (*__local_p__goto_1800_18) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_34 = (if __ci_expr_logic_33 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_124 {
        (__local_p__goto_1800_18 = __local_p__goto_1800_18 + 1)
        goto '__ci_bb_123
    }

    '__ci_bb_125 {
        if ((if not (read_number((&raw mut __local_p__goto_1800_18 as *mut *const u8), __param_ptrend, (__param_bracount as i32), (65535 as u32), (161 as u32), (&raw mut __local_s__goto_1611_7 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_126 {
        if ((if (*__param_errorcodeptr) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_127 {
        goto '__ci_bb_130
    }

    '__ci_bb_128 {
        (__local_escape__goto_1499_5 = ESC_k)
        goto '__ci_bb_129
    }

    '__ci_bb_129 {
        goto '__ci_bb_60
    }

    '__ci_bb_130 {
        (__ci_expr_logic_36 = 0)
        if ((if __local_p__goto_1800_18 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_35: i32

            if ((if (*__local_p__goto_1800_18) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_35 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_35 = (if (if (*__local_p__goto_1800_18) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_36 = (if __ci_expr_logic_35 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_131
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_131 {
        (__local_p__goto_1800_18 = __local_p__goto_1800_18 + 1)
        goto '__ci_bb_130
    }

    '__ci_bb_132 {
        if ((if __local_p__goto_1800_18 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_37 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_37 = (if (if (*__local_p__goto_1800_18) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_133 {
        (__local_ptr__goto_1497_12 = __local_p__goto_1800_18)
        ((*__param_errorcodeptr) = ERR119)
        goto '__ci_bb_60
    }

    '__ci_bb_134 {
        (__local_ptr__goto_1497_12 = __local_p__goto_1800_18 + ((1 as isize) as usize))
        goto '__ci_bb_122
    }

    '__ci_bb_135 {
        if ((if (*__param_errorcodeptr) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_136 {
        goto '__ci_bb_122
    }

    '__ci_bb_137 {
        ((*__param_errorcodeptr) = ERR57)
        goto '__ci_bb_138
    }

    '__ci_bb_138 {
        goto '__ci_bb_60
    }

    '__ci_bb_139 {
        ((*__param_errorcodeptr) = ERR15)
        goto '__ci_bb_60
    }

    '__ci_bb_140 {
        (__local_escape__goto_1499_5 = (((0 - (__local_s__goto_1611_7 + 1)) as i32)))
        goto '__ci_bb_60
    }

    '__ci_bb_141 {
        if (__param_isclass != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_142 {
        goto '__ci_bb_144
    }

    '__ci_bb_143 {
        if ((if ((__param_xoptions as u32) & (8192 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_145
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_144 {
        if ((if __local_c__goto_1498_10 >= 56: 1 else: 0) != 0) {
            goto '__ci_bb_163
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_145 {
        (__ci_expr_logic_42 = 0)
        (__ci_expr_logic_41 = 0)
        (__ci_expr_logic_40 = 0)
        (__ci_expr_logic_39 = 0)
        (__ci_expr_logic_38 = 0)
        if ((if (__local_ptr__goto_1497_12[-1]) <= 55: 1 else: 0) != 0) {
            (__ci_expr_logic_38 = (if (if (__local_ptr__goto_1497_12 + ((1 as isize) as usize)) < __param_ptrend: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_38 != 0) {
            (__ci_expr_logic_39 = (if (if (__local_ptr__goto_1497_12[0]) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_39 != 0) {
            (__ci_expr_logic_40 = (if (if (__local_ptr__goto_1497_12[0]) <= 55: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_40 != 0) {
            (__ci_expr_logic_41 = (if (if (__local_ptr__goto_1497_12[1]) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_41 != 0) {
            (__ci_expr_logic_42 = (if (if (__local_ptr__goto_1497_12[1]) <= 55: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_42 != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_146 {
        (__local_oldptr__goto_1612_14 = __local_ptr__goto_1497_12)
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 - 1)
        if ((if not (read_number((&raw mut __local_ptr__goto_1497_12 as *mut *const u8), __param_ptrend, (-1 as i32), (65535 as u32), (0 as u32), (&raw mut __local_s__goto_1611_7 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_147 {
        goto '__ci_bb_144
    }

    '__ci_bb_148 {
        goto '__ci_bb_150
    }

    '__ci_bb_149 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 - 1)
        if ((if not (read_number((&raw mut __local_ptr__goto_1497_12 as *mut *const u8), __param_ptrend, (-1 as i32), (65535 as u32), (0 as u32), (&raw mut __local_s__goto_1611_7 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_151
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_150 {
        goto '__ci_bb_147
    }

    '__ci_bb_151 {
        ((*__param_errorcodeptr) = ERR61)
        goto '__ci_bb_60
    }

    '__ci_bb_152 {
        (__local_escape__goto_1499_5 = (((0 - (__local_s__goto_1611_7 + 1)) as i32)))
        goto '__ci_bb_60
    }

    '__ci_bb_153 {
        (__local_s__goto_1611_7 = ((libc.INT_MAX as i32)))
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        if ((if __local_s__goto_1611_7 < 10: 1 else: 0) != 0) {
            (__ci_expr_logic_43 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_43 = (if (if __local_c__goto_1498_10 >= 56: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_43 != 0) {
            (__ci_expr_logic_44 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_44 = (if (if ((__local_s__goto_1611_7 as u32)) <= __param_bracount: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_44 != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_155 {
        if ((if ((__local_s__goto_1611_7 as u32)) > 65535: 1 else: 0) != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_156 {
        (__local_ptr__goto_1497_12 = __local_oldptr__goto_1612_14)
        goto '__ci_bb_147
    }

    '__ci_bb_157 {
        goto '__ci_bb_160
    }

    '__ci_bb_158 {
        (__local_escape__goto_1499_5 = (((0 - (__local_s__goto_1611_7 + 1)) as i32)))
        goto '__ci_bb_159
    }

    '__ci_bb_159 {
        goto '__ci_bb_60
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
        ((*__param_errorcodeptr) = ERR61)
        goto '__ci_bb_159
    }

    '__ci_bb_163 {
        goto '__ci_bb_60
    }

    '__ci_bb_164 {
        goto '__ci_bb_165
    }

    '__ci_bb_165 {
        (__local_c__goto_1498_10 = (__local_c__goto_1498_10 -% 48))
        goto '__ci_bb_166
    }

    '__ci_bb_166 {
        (__ci_expr_logic_48 = 0)
        (__ci_expr_logic_47 = 0)
        (__ci_expr_logic_46 = 0)
        (__ci_expr_old_45 = __local_i__goto_1500_5)
        (__local_i__goto_1500_5 = __local_i__goto_1500_5 + 1)
        if ((if __ci_expr_old_45 < 2: 1 else: 0) != 0) {
            (__ci_expr_logic_46 = (if (if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_46 != 0) {
            (__ci_expr_logic_47 = (if (if (*__local_ptr__goto_1497_12) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_47 != 0) {
            (__ci_expr_logic_48 = (if (if (*__local_ptr__goto_1497_12) <= 55: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_48 != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_167 {
        (__ci_expr_old_49 = __local_ptr__goto_1497_12)
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__local_c__goto_1498_10 = ((((((((__local_c__goto_1498_10 as u32) *% (8 as u32)) as u32) +% (((*__ci_expr_old_49) as i32) as u32)) as u32) -% (48 as u32)) as u32)))
        goto '__ci_bb_166
    }

    '__ci_bb_168 {
        if ((if __local_c__goto_1498_10 > 255: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_169 {
        if ((if ((__param_xoptions as u32) & (8192 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_171
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_170 {
        (__ci_expr_logic_51 = 0)
        (__ci_expr_logic_50 = 0)
        if ((if ((__param_xoptions as u32) & (16384 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_50 = (if (if __local_c__goto_1498_10 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_50 != 0) {
            (__ci_expr_logic_51 = (if (if __local_i__goto_1500_5 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_51 != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_171 {
        ((*__param_errorcodeptr) = ERR102)
        goto '__ci_bb_173
    }

    '__ci_bb_172 {
        if ((if not (__local_utf__goto_1494_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_173 {
        goto '__ci_bb_170
    }

    '__ci_bb_174 {
        ((*__param_errorcodeptr) = ERR51)
        goto '__ci_bb_175
    }

    '__ci_bb_175 {
        goto '__ci_bb_173
    }

    '__ci_bb_176 {
        ((*__param_errorcodeptr) = ERR98)
        goto '__ci_bb_177
    }

    '__ci_bb_177 {
        goto '__ci_bb_60
    }

    '__ci_bb_178 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_52 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_52 = (if (if (*__local_ptr__goto_1497_12) != 123: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_52 != 0) {
            goto '__ci_bb_179
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_179 {
        ((*__param_errorcodeptr) = ERR55)
        goto '__ci_bb_60
    }

    '__ci_bb_180 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_181
    }

    '__ci_bb_181 {
        (__ci_expr_logic_54 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_53: i32

            if ((if (*__local_ptr__goto_1497_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_53 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_53 = (if (if (*__local_ptr__goto_1497_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_54 = (if __ci_expr_logic_53 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_54 != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_182 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_181
    }

    '__ci_bb_183 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_55 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_55 = (if (if (*__local_ptr__goto_1497_12) == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_55 != 0) {
            goto '__ci_bb_184
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_184 {
        ((*__param_errorcodeptr) = ERR78)
        goto '__ci_bb_60
    }

    '__ci_bb_185 {
        (__local_c__goto_1498_10 = ((0 as u32)))
        (__local_overflow__goto_1613_8 = ((0 as i32)))
        goto '__ci_bb_186
    }

    '__ci_bb_186 {
        (__ci_expr_logic_57 = 0)
        (__ci_expr_logic_56 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_56 = (if (if (*__local_ptr__goto_1497_12) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_56 != 0) {
            (__ci_expr_logic_57 = (if (if (*__local_ptr__goto_1497_12) <= 55: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_57 != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_187 {
        (__ci_expr_old_58 = __local_ptr__goto_1497_12)
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__local_cc__goto_1498_13 = (((*__ci_expr_old_58) as u32)))
        (__ci_expr_logic_59 = 0)
        if ((if __local_c__goto_1498_10 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_59 = (if (if __local_cc__goto_1498_13 == 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_59 != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_188 {
        goto '__ci_bb_193
    }

    '__ci_bb_189 {
        goto '__ci_bb_186
    }

    '__ci_bb_190 {
        (__local_c__goto_1498_10 = ((((((__local_c__goto_1498_10 as u32) << (3 as u32)) as u32) +% (((__local_cc__goto_1498_13 as u32) -% (48 as u32)) as u32)) as u32)))
        if ((if __local_c__goto_1498_10 > (if __local_utf__goto_1494_6 != 0: (1114111 as u32) else: (255 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_191 {
        (__local_overflow__goto_1613_8 = ((1 as i32)))
        goto '__ci_bb_188
    }

    '__ci_bb_192 {
        goto '__ci_bb_186
    }

    '__ci_bb_193 {
        (__ci_expr_logic_61 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_60: i32

            if ((if (*__local_ptr__goto_1497_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_60 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_60 = (if (if (*__local_ptr__goto_1497_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_61 = (if __ci_expr_logic_60 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_61 != 0) {
            goto '__ci_bb_194
        } else {
            goto '__ci_bb_195
        }
    }

    '__ci_bb_194 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_193
    }

    '__ci_bb_195 {
        if (__local_overflow__goto_1613_8 != 0) {
            goto '__ci_bb_196
        } else {
            goto '__ci_bb_197
        }
    }

    '__ci_bb_196 {
        goto '__ci_bb_199
    }

    '__ci_bb_197 {
        (__ci_expr_logic_66 = 0)
        (__ci_expr_logic_65 = 0)
        (__ci_expr_logic_64 = 0)
        if (__local_utf__goto_1494_6 != 0) {
            (__ci_expr_logic_64 = (if (if __local_c__goto_1498_10 >= 55296: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_64 != 0) {
            (__ci_expr_logic_65 = (if (if __local_c__goto_1498_10 <= 57343: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_65 != 0) {
            (__ci_expr_logic_66 = (if (if ((__param_xoptions as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_66 != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_203
        }
    }

    '__ci_bb_198 {
        goto '__ci_bb_60
    }

    '__ci_bb_199 {
        (__ci_expr_logic_63 = 0)
        (__ci_expr_logic_62 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_62 = (if (if (*__local_ptr__goto_1497_12) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_62 != 0) {
            (__ci_expr_logic_63 = (if (if (*__local_ptr__goto_1497_12) <= 55: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_63 != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_200 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_199
    }

    '__ci_bb_201 {
        ((*__param_errorcodeptr) = ERR34)
        goto '__ci_bb_198
    }

    '__ci_bb_202 {
        ((*__param_errorcodeptr) = ERR73)
        goto '__ci_bb_204
    }

    '__ci_bb_203 {
        (__ci_expr_logic_67 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_67 = (if (if (*__local_ptr__goto_1497_12) == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_67 != 0) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_204 {
        goto '__ci_bb_198
    }

    '__ci_bb_205 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_207
    }

    '__ci_bb_206 {
        ((*__param_errorcodeptr) = ERR64)
        goto '__ci_bb_208
    }

    '__ci_bb_207 {
        goto '__ci_bb_204
    }

    '__ci_bb_208 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        if (__local_utf__goto_1494_6 != 0) {
            goto '__ci_bb_279
        } else {
            goto '__ci_bb_280
        }
    }

    '__ci_bb_209 {
        if (__local_alt_bsux__goto_1495_6 != 0) {
            goto '__ci_bb_210
        } else {
            goto '__ci_bb_211
        }
    }

    '__ci_bb_210 {
        if ((if ((((__param_ptrend as usize) -% (__local_ptr__goto_1497_12 as usize)) as i64) / (sizeof[u8]() as i64)) < 2: 1 else: 0) != 0) {
            goto '__ci_bb_213
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_211 {
        (__ci_expr_logic_68 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_68 = (if (if (*__local_ptr__goto_1497_12) == 123: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_68 != 0) {
            goto '__ci_bb_219
        } else {
            goto '__ci_bb_220
        }
    }

    '__ci_bb_212 {
        goto '__ci_bb_60
    }

    '__ci_bb_213 {
        goto '__ci_bb_60
    }

    '__ci_bb_214 {
        (__local_cc__goto_1498_13 = ((xdigitab[(__local_ptr__goto_1497_12[0])] as u32)))
        if ((if __local_cc__goto_1498_13 == 255: 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_215 {
        goto '__ci_bb_60
    }

    '__ci_bb_216 {
        (__local_xc__goto_2033_16 = ((xdigitab[(__local_ptr__goto_1497_12[1])] as u32)))
        if ((if __local_xc__goto_2033_16 == 255: 1 else: 0) != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_217 {
        goto '__ci_bb_60
    }

    '__ci_bb_218 {
        (__local_c__goto_1498_10 = ((((((__local_cc__goto_1498_13 as u32) << (4 as u32)) as u32) | (__local_xc__goto_2033_16 as u32)) as u32)))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + ((2 as isize) as usize))
        goto '__ci_bb_212
    }

    '__ci_bb_219 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_222
    }

    '__ci_bb_220 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_84 = (if true: 1 else: 0))
        } else {
            (__local_cc__goto_1498_13 = ((xdigitab[(*__local_ptr__goto_1497_12)] as u32)))

            (__ci_expr_logic_84 = (if (if __local_cc__goto_1498_13 == 255: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_84 != 0) {
            goto '__ci_bb_249
        } else {
            goto '__ci_bb_250
        }
    }

    '__ci_bb_221 {
        goto '__ci_bb_212
    }

    '__ci_bb_222 {
        (__ci_expr_logic_70 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_69: i32

            if ((if (*__local_ptr__goto_1497_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_69 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_69 = (if (if (*__local_ptr__goto_1497_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_70 = (if __ci_expr_logic_69 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_70 != 0) {
            goto '__ci_bb_223
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_223 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_222
    }

    '__ci_bb_224 {
        goto '__ci_bb_40
    }

    '__ci_bb_225 {
        ((*__param_errorcodeptr) = ERR78)
        goto '__ci_bb_60
    }

    '__ci_bb_226 {
        (__local_c__goto_1498_10 = ((0 as u32)))
        (__local_overflow__goto_1613_8 = ((0 as i32)))
        goto '__ci_bb_227
    }

    '__ci_bb_227 {
        (__ci_expr_logic_72 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__local_cc__goto_1498_13 = ((xdigitab[(*__local_ptr__goto_1497_12)] as u32)))

            (__ci_expr_logic_72 = (if (if __local_cc__goto_1498_13 != 255: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_72 != 0) {
            goto '__ci_bb_228
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_228 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__ci_expr_logic_73 = 0)
        if ((if __local_c__goto_1498_10 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_73 = (if (if __local_cc__goto_1498_13 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_73 != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_229 {
        goto '__ci_bb_234
    }

    '__ci_bb_230 {
        goto '__ci_bb_227
    }

    '__ci_bb_231 {
        (__local_c__goto_1498_10 = ((((((__local_c__goto_1498_10 as u32) << (4 as u32)) as u32) | (__local_cc__goto_1498_13 as u32)) as u32)))
        (__ci_expr_logic_74 = 0)
        if (__local_utf__goto_1494_6 != 0) {
            (__ci_expr_logic_74 = (if (if __local_c__goto_1498_10 > 1114111: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_74 != 0) {
            (__ci_expr_logic_76 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_75: i32 = 0

            if ((if not (__local_utf__goto_1494_6 != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_75 = (if (if __local_c__goto_1498_10 > ((4294967295 as u32) >> ((32 - 8) as u32)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_76 = (if __ci_expr_logic_75 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_76 != 0) {
            goto '__ci_bb_232
        } else {
            goto '__ci_bb_233
        }
    }

    '__ci_bb_232 {
        (__local_overflow__goto_1613_8 = ((1 as i32)))
        goto '__ci_bb_229
    }

    '__ci_bb_233 {
        goto '__ci_bb_227
    }

    '__ci_bb_234 {
        (__ci_expr_logic_78 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_77: i32

            if ((if (*__local_ptr__goto_1497_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_77 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_77 = (if (if (*__local_ptr__goto_1497_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_78 = (if __ci_expr_logic_77 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_78 != 0) {
            goto '__ci_bb_235
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_235 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_234
    }

    '__ci_bb_236 {
        if (__local_overflow__goto_1613_8 != 0) {
            goto '__ci_bb_237
        } else {
            goto '__ci_bb_238
        }
    }

    '__ci_bb_237 {
        goto '__ci_bb_240
    }

    '__ci_bb_238 {
        (__ci_expr_logic_82 = 0)
        (__ci_expr_logic_81 = 0)
        (__ci_expr_logic_80 = 0)
        if (__local_utf__goto_1494_6 != 0) {
            (__ci_expr_logic_80 = (if (if __local_c__goto_1498_10 >= 55296: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_80 != 0) {
            (__ci_expr_logic_81 = (if (if __local_c__goto_1498_10 <= 57343: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_81 != 0) {
            (__ci_expr_logic_82 = (if (if ((__param_xoptions as u32) & (1 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_82 != 0) {
            goto '__ci_bb_243
        } else {
            goto '__ci_bb_244
        }
    }

    '__ci_bb_239 {
        goto '__ci_bb_221
    }

    '__ci_bb_240 {
        (__ci_expr_logic_79 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_79 = (if (if xdigitab[(*__local_ptr__goto_1497_12)] != 255: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_79 != 0) {
            goto '__ci_bb_241
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_241 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_240
    }

    '__ci_bb_242 {
        ((*__param_errorcodeptr) = ERR34)
        goto '__ci_bb_239
    }

    '__ci_bb_243 {
        ((*__param_errorcodeptr) = ERR73)
        goto '__ci_bb_245
    }

    '__ci_bb_244 {
        (__ci_expr_logic_83 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_83 = (if (if (*__local_ptr__goto_1497_12) == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_83 != 0) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_245 {
        goto '__ci_bb_239
    }

    '__ci_bb_246 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_248
    }

    '__ci_bb_247 {
        ((*__param_errorcodeptr) = ERR67)
        goto '__ci_bb_208
    }

    '__ci_bb_248 {
        goto '__ci_bb_245
    }

    '__ci_bb_249 {
        ((*__param_errorcodeptr) = ERR78)
        goto '__ci_bb_60
    }

    '__ci_bb_250 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__local_c__goto_1498_10 = __local_cc__goto_1498_13)
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_85 = (if true: 1 else: 0))
        } else {
            (__local_cc__goto_1498_13 = ((xdigitab[(*__local_ptr__goto_1497_12)] as u32)))

            (__ci_expr_logic_85 = (if (if __local_cc__goto_1498_13 == 255: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_85 != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_251 {
        goto '__ci_bb_60
    }

    '__ci_bb_252 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        (__local_c__goto_1498_10 = ((((((__local_c__goto_1498_10 as u32) << (4 as u32)) as u32) | (__local_cc__goto_1498_13 as u32)) as u32)))
        goto '__ci_bb_221
    }

    '__ci_bb_253 {
        if ((if __local_ptr__goto_1497_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_254
        } else {
            goto '__ci_bb_255
        }
    }

    '__ci_bb_254 {
        ((*__param_errorcodeptr) = ERR2)
        goto '__ci_bb_60
    }

    '__ci_bb_255 {
        (__local_c__goto_1498_10 = (((*__local_ptr__goto_1497_12) as u32)))
        (__ci_expr_logic_86 = 0)
        if ((if __local_c__goto_1498_10 >= 97: 1 else: 0) != 0) {
            (__ci_expr_logic_86 = (if (if __local_c__goto_1498_10 <= 122: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_86 != 0) {
            goto '__ci_bb_256
        } else {
            goto '__ci_bb_257
        }
    }

    '__ci_bb_256 {
        (__local_c__goto_1498_10 = ((((__local_c__goto_1498_10 as u32) -% (32 as u32)) as u32)))
        goto '__ci_bb_257
    }

    '__ci_bb_257 {
        if ((if __local_c__goto_1498_10 < 32: 1 else: 0) != 0) {
            (__ci_expr_logic_87 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_87 = (if (if __local_c__goto_1498_10 > 126: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_87 != 0) {
            goto '__ci_bb_258
        } else {
            goto '__ci_bb_259
        }
    }

    '__ci_bb_258 {
        ((*__param_errorcodeptr) = ERR68)
        goto '__ci_bb_208
    }

    '__ci_bb_259 {
        (__local_c__goto_1498_10 = (__local_c__goto_1498_10 as u32) ^ (64 as u32))
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_60
    }

    '__ci_bb_260 {
        ((*__param_errorcodeptr) = ERR3)
        goto '__ci_bb_60
    }

    '__ci_bb_261 {
        if (__local_c__goto_1498_10 == 108) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_262
        }
    }

    '__ci_bb_262 {
        if (__local_c__goto_1498_10 == 76) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_263
        }
    }

    '__ci_bb_263 {
        if (__local_c__goto_1498_10 == 117) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_264 {
        if (__local_c__goto_1498_10 == 85) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_265
        }
    }

    '__ci_bb_265 {
        if (__local_c__goto_1498_10 == 103) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_266
        }
    }

    '__ci_bb_266 {
        if (__local_c__goto_1498_10 == 49) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_267
        }
    }

    '__ci_bb_267 {
        if (__local_c__goto_1498_10 == 50) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_268
        }
    }

    '__ci_bb_268 {
        if (__local_c__goto_1498_10 == 51) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_269 {
        if (__local_c__goto_1498_10 == 52) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_270
        }
    }

    '__ci_bb_270 {
        if (__local_c__goto_1498_10 == 53) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_271
        }
    }

    '__ci_bb_271 {
        if (__local_c__goto_1498_10 == 54) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_272
        }
    }

    '__ci_bb_272 {
        if (__local_c__goto_1498_10 == 55) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_273
        }
    }

    '__ci_bb_273 {
        if (__local_c__goto_1498_10 == 56) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_274
        }
    }

    '__ci_bb_274 {
        if (__local_c__goto_1498_10 == 57) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_275
        }
    }

    '__ci_bb_275 {
        if (__local_c__goto_1498_10 == 48) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_276 {
        if (__local_c__goto_1498_10 == 111) {
            goto '__ci_bb_178
        } else {
            goto '__ci_bb_277
        }
    }

    '__ci_bb_277 {
        if (__local_c__goto_1498_10 == 120) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_278
        }
    }

    '__ci_bb_278 {
        if (__local_c__goto_1498_10 == 99) {
            goto '__ci_bb_253
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_279 {
        goto '__ci_bb_281
    }

    '__ci_bb_280 {
        goto '__ci_bb_58
    }

    '__ci_bb_281 {
        (__ci_expr_logic_88 = 0)
        if ((if __local_ptr__goto_1497_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_88 = (if (if ((((*__local_ptr__goto_1497_12) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_88 != 0) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_283
        }
    }

    '__ci_bb_282 {
        (__local_ptr__goto_1497_12 = __local_ptr__goto_1497_12 + 1)
        goto '__ci_bb_281
    }

    '__ci_bb_283 {
        goto '__ci_bb_280
    }

    __ci_unreachable()

}

unsafe fn compile_regex(__param_options: u32, __param_xoptions: u32, __param_codeptr: *mut *mut u8, __param_pptrptr: *mut *mut u32, __param_errorcodeptr: *mut i32, __param_skipunits: u32, __param_firstcuptr: *mut u32, __param_firstcuflagsptr: *mut u32, __param_reqcuptr: *mut u32, __param_reqcuflagsptr: *mut u32, __param_bcptr: *mut branch_chain_8, __param_open_caps: *mut open_capitem, __param_cb: *mut compile_block_8, __param_lengthptr: *mut u64) -> i32 {
    var __local_open_caps = __param_open_caps
    var __local_code: *mut u8 = (*__param_codeptr)

    var __local_last_branch: *mut u8 = __local_code

    var __local_start_bracket: *mut u8 = __local_code

    var __local_lookbehind: i32

    var __local_capitem: open_capitem

    var __local_capnumber: i32 = ((0 as i32))

    var __local_okreturn: i32 = ((1 as i32))

    var __local_pptr: *mut u32 = (*__param_pptrptr)

    var __local_firstcu: u32

    var __local_reqcu: u32


    var __local_lookbehindlength: u32

    var __local_lookbehindminlength: u32

    var __local_firstcuflags: u32

    var __local_reqcuflags: u32


    var __local_length: u64

    var __local_bc: branch_chain_8

    var __ci_expr_logic_0: i32 = 0

    if ((if (*(*__param_cb).cx).stack_guard != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (*(*__param_cb).cx).stack_guard.unwrap()(((*__param_cb).parens_depth as u32), (*(*__param_cb).cx).stack_guard_data) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__param_errorcodeptr) = ERR33)

        ((*__param_cb).erroroffset = ((0 as u64)))

        return 0

    }


    (__local_bc.outer = __param_bcptr)

    (__local_bc.current_branch = __local_code)

    (__local_reqcu = ((0 as u32)))

    (__local_firstcu = __local_reqcu)


    (__local_reqcuflags = ((4294967295 as u32)))

    (__local_firstcuflags = __local_reqcuflags)


    (__local_length = ((((6 as u32) +% (__param_skipunits as u32)) as u64)))

    var __ci_expr_logic_2: i32

    var __ci_expr_logic_1: i32

    if ((if (*__local_code) == OP_ASSERTBACK: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__local_code) == OP_ASSERTBACK_NOT: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (*__local_code) == OP_ASSERTBACK_NA: 1 else: 0) != 0: 1 else: 0))
    }

    (__local_lookbehind = __ci_expr_logic_2)


    if (__local_lookbehind != 0) {
        (__local_lookbehindlength = (((((__local_pptr[-1]) as u32) & (65535 as u32)) as u32)))

        (__local_lookbehindminlength = (*__local_pptr))

        (__local_pptr = __local_pptr + ((2 as isize) as usize))

    } else {
        (__local_lookbehindminlength = ((0 as u32)))

        (__local_lookbehindlength = __local_lookbehindminlength)

    }

    if ((if (*__local_code) == OP_CBRA: 1 else: 0) != 0) {
        (__local_capnumber = ((((((((__local_code[(1 + 2)]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + 2) + 1)]) as i32)) as u32) as i32)))

        (__local_capitem.number = ((__local_capnumber as u16)))

        (__local_capitem.next = __local_open_caps)

        (__local_capitem.assert_depth = (*__param_cb).assert_depth)

        (__local_open_caps = ((&raw mut __local_capitem as *mut open_capitem)))

    }

    ((__local_code[1]) = ((((0 as i32) >> (8 as u32)) as u8)))

    ((__local_code[(1 + 1)]) = ((((0 as i32) & (255 as i32)) as u8)))


    (__local_code = __local_code + (((3 as u32) +% (__param_skipunits as u32)) as usize))

    while true {
        var __local_branch_return: i32

        var __local_branchfirstcu: u32 = ((0 as u32))

        var __local_branchreqcu: u32 = ((0 as u32))


        var __local_branchfirstcuflags: u32 = ((4294967295 as u32))

        var __local_branchreqcuflags: u32 = ((4294967295 as u32))


        var __ci_expr_logic_3: i32 = 0

        if (__local_lookbehind != 0) {
            (__ci_expr_logic_3 = (if (if __local_lookbehindlength > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            var __ci_expr_logic_4: i32

            if ((if __local_lookbehindminlength == 65535: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if __local_lookbehindminlength == __local_lookbehindlength: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                var __ci_expr_old_5: *mut u8 = __local_code

                (__local_code = __local_code + 1)

                ((*__ci_expr_old_5) = ((126 as u8)))


                ((__local_code[0]) = ((((__local_lookbehindlength as u32) >> (8 as u32)) as u8)))

                ((__local_code[(0 + 1)]) = ((((__local_lookbehindlength as u32) & (255 as u32)) as u8)))

                (__local_code = __local_code + ((2 as isize) as usize))


                (__local_length = (__local_length +% 3))

            } else {
                var __ci_expr_old_6: *mut u8 = __local_code

                (__local_code = __local_code + 1)

                ((*__ci_expr_old_6) = ((127 as u8)))


                ((__local_code[0]) = ((((__local_lookbehindminlength as u32) >> (8 as u32)) as u8)))

                ((__local_code[(0 + 1)]) = ((((__local_lookbehindminlength as u32) & (255 as u32)) as u8)))

                (__local_code = __local_code + ((2 as isize) as usize))


                ((__local_code[0]) = ((((__local_lookbehindlength as u32) >> (8 as u32)) as u8)))

                ((__local_code[(0 + 1)]) = ((((__local_lookbehindlength as u32) & (255 as u32)) as u8)))

                (__local_code = __local_code + ((2 as isize) as usize))


                (__local_length = (__local_length +% 5))

            }


        }


        (__local_branch_return = ((compile_branch((&raw mut __param_options as *mut u32), (&raw mut __param_xoptions as *mut u32), (&raw mut __local_code as *mut *mut u8), (&raw mut __local_pptr as *mut *mut u32), __param_errorcodeptr, (&raw mut __local_branchfirstcu as *mut u32), (&raw mut __local_branchfirstcuflags as *mut u32), (&raw mut __local_branchreqcu as *mut u32), (&raw mut __local_branchreqcuflags as *mut u32), (&raw mut __local_bc as *mut branch_chain_8), __local_open_caps, __param_cb, (if (if __param_lengthptr == null: 1 else: 0) != 0: (null as *mut u64) else: (&raw mut __local_length as *mut u64))) as i32)))

        if ((if __local_branch_return == 0: 1 else: 0) != 0) {
            return 0
        }


        if ((if __local_branch_return < 0: 1 else: 0) != 0) {
            (__local_okreturn = ((-1 as i32)))
        }

        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            if ((if (*__local_last_branch) != OP_ALT: 1 else: 0) != 0) {
                (__local_firstcu = __local_branchfirstcu)

                (__local_firstcuflags = __local_branchfirstcuflags)

                (__local_reqcu = __local_branchreqcu)

                (__local_reqcuflags = __local_branchreqcuflags)

            } else {
                var __ci_expr_logic_7: i32

                if ((if __local_firstcuflags != __local_branchfirstcuflags: 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_7 = (if (if __local_firstcu != __local_branchfirstcu: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_7 != 0) {
                    if ((if __local_firstcuflags < 4294967294: 1 else: 0) != 0) {
                        if ((if __local_reqcuflags >= 4294967294: 1 else: 0) != 0) {
                            (__local_reqcu = __local_firstcu)

                            (__local_reqcuflags = __local_firstcuflags)

                        }

                    }

                    (__local_firstcuflags = ((4294967294 as u32)))

                }


                var __ci_expr_logic_9: i32 = 0

                var __ci_expr_logic_8: i32 = 0

                if ((if __local_firstcuflags >= 4294967294: 1 else: 0) != 0) {
                    (__ci_expr_logic_8 = (if (if __local_branchfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_8 != 0) {
                    (__ci_expr_logic_9 = (if (if __local_branchreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_9 != 0) {
                    (__local_branchreqcu = __local_branchfirstcu)

                    (__local_branchreqcuflags = __local_branchfirstcuflags)

                }


                var __ci_expr_logic_10: i32

                if ((if ((__local_reqcuflags as u32) & ((~2) as u32)) != ((__local_branchreqcuflags as u32) & ((~2) as u32)): 1 else: 0) != 0) {
                    (__ci_expr_logic_10 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_10 = (if (if __local_reqcu != __local_branchreqcu: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_10 != 0) {
                    (__local_reqcuflags = ((4294967294 as u32)))
                } else {
                    (__local_reqcu = __local_branchreqcu)

                    (__local_reqcuflags = (__local_reqcuflags as u32) | (__local_branchreqcuflags as u32))

                }


            }

        }

        if ((if (((*__local_pptr) as u32) & (4294901760 as u32)) != 2147549184: 1 else: 0) != 0) {
            if ((if __param_lengthptr == null: 1 else: 0) != 0) {
                var __local_branch_length: u32 = ((((((__local_code as usize) -% (__local_last_branch as usize)) as i64) / (sizeof[u8]() as i64)) as u32))

                loop {
                    var __local_prev_length: u32 = (((((((__local_last_branch[1]) as i32) << (8 as u32)) as i32) | ((__local_last_branch[(1 + 1)]) as i32)) as u32))

                    ((__local_last_branch[1]) = ((((__local_branch_length as u32) >> (8 as u32)) as u8)))

                    ((__local_last_branch[(1 + 1)]) = ((((__local_branch_length as u32) & (255 as u32)) as u8)))


                    (__local_branch_length = __local_prev_length)

                    (__local_last_branch = __local_last_branch - (__local_branch_length as usize))

                    if not (((if __local_branch_length > 0: 1 else: 0) != 0)) {
                        break
                    }
                }

            }

            ((*__local_code) = ((122 as u8)))

            ((__local_code[1]) = ((((((((__local_code as usize) -% (__local_start_bracket as usize)) as i64) / (sizeof[u8]() as i64)) as u32) >> (8 as u32)) as u8)))

            ((__local_code[(1 + 1)]) = ((((((((__local_code as usize) -% (__local_start_bracket as usize)) as i64) / (sizeof[u8]() as i64)) as u32) & (255 as u32)) as u8)))


            (__local_code = __local_code + (((1 + 2) as isize) as usize))

            ((*__param_codeptr) = __local_code)

            ((*__param_pptrptr) = __local_pptr)

            ((*__param_firstcuptr) = __local_firstcu)

            ((*__param_firstcuflagsptr) = __local_firstcuflags)

            ((*__param_reqcuptr) = __local_reqcu)

            ((*__param_reqcuflagsptr) = __local_reqcuflags)

            if ((if __param_lengthptr != null: 1 else: 0) != 0) {
                if ((if ((2147483627 as u64) -% ((*__param_lengthptr) as u64)) < __local_length: 1 else: 0) != 0) {
                    ((*__param_errorcodeptr) = ERR20)

                    return 0

                }

                ((*__param_lengthptr) = ((*__param_lengthptr) +% __local_length))

            }

            return __local_okreturn

        }

        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            (__local_code = (((*__param_codeptr) + ((1 as isize) as usize)) + ((2 as isize) as usize)) + (__param_skipunits as usize))

            (__local_length = (__local_length +% 3))

        } else {
            ((*__local_code) = ((121 as u8)))

            ((__local_code[1]) = ((((((((__local_code as usize) -% (__local_last_branch as usize)) as i64) / (sizeof[u8]() as i64)) as i32) >> (8 as u32)) as u8)))

            ((__local_code[(1 + 1)]) = ((((((((__local_code as usize) -% (__local_last_branch as usize)) as i64) / (sizeof[u8]() as i64)) as i32) & (255 as i32)) as u8)))


            (__local_last_branch = __local_code)

            (__local_bc.current_branch = __local_last_branch)


            (__local_code = __local_code + (((1 + 2) as isize) as usize))

        }

        (__local_lookbehindlength = (((((*__local_pptr) as u32) & (65535 as u32)) as u32)))

        (__local_pptr = __local_pptr + 1)

    }

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    return 0

}

unsafe fn get_branchlength(__param_pptrptr: *mut *mut u32, __param_minptr: *mut i32, __param_errcodeptr: *mut i32, __param_lcptr: *mut i32, __param_recurses: *mut parsed_recurse_check, __param_cb: *mut compile_block_8) -> i32 {
    var __local_branchlength__goto_9580_5: i32 = 0

    var __local_branchminlength__goto_9581_5: i32 = 0

    var __local_grouplength__goto_9582_5: i32 = 0

    var __local_groupminlength__goto_9582_18: i32 = 0

    var __local_lastitemlength__goto_9583_10: u32 = 0

    var __local_lastitemminlength__goto_9584_10: u32 = 0

    var __local_pptr__goto_9585_11: *mut u32 = null

    var __local_offset__goto_9586_12: u64 = 0

    var __local_this_recurse__goto_9587_22: parsed_recurse_check = parsed_recurse_check.zeroed()

    var __local_r__goto_9603_25: *mut parsed_recurse_check = null

    var __local_gptr__goto_9604_13: *mut u32 = null

    var __local_gptrend__goto_9604_20: *mut u32 = null

    var __local_escape__goto_9605_12: u32 = 0

    var __local_min__goto_9606_12: u32 = 0

    var __local_max__goto_9606_17: u32 = 0

    var __local_group__goto_9607_12: u32 = 0

    var __local_itemlength__goto_9608_12: u32 = 0

    var __local_itemminlength__goto_9609_12: u32 = 0

    var __local_name__goto_9764_18: *const u8 = null

    var __local_is_dupname__goto_9765_12: i32 = 0

    var __local_ng__goto_9766_20: *mut named_group_8 = null

    var __local_meta_code__goto_9767_16: u32 = 0

    var __local_length__goto_9768_16: u32 = 0

    var __ci_expr_old_0: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_8: i32 = 0

    var __ci_expr_logic_10: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_branchlength__goto_9580_5 = ((0 as i32)))
        (__local_branchminlength__goto_9581_5 = ((0 as i32)))
        (__local_lastitemlength__goto_9583_10 = ((0 as u32)))
        (__local_lastitemminlength__goto_9584_10 = ((0 as u32)))
        (__local_pptr__goto_9585_11 = (*__param_pptrptr))
        (__ci_expr_old_0 = (*__param_lcptr))
        ((*__param_lcptr) = (*__param_lcptr) + 1)
        if ((if __ci_expr_old_0 > 2000: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        ((*__param_errcodeptr) = ERR35)
        return -1
    }

    '__ci_bb_2 {
        goto '__ci_bb_3
    }

    '__ci_bb_3 {
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        (__local_group__goto_9607_12 = ((0 as u32)))
        (__local_itemlength__goto_9608_12 = ((0 as u32)))
        (__local_itemminlength__goto_9609_12 = ((0 as u32)))
        if ((if (*__local_pptr__goto_9585_11) < 2147483648: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_5 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + 1)
        goto '__ci_bb_3
    }

    '__ci_bb_7 {
        (__local_itemminlength__goto_9609_12 = ((1 as u32)))
        (__local_itemlength__goto_9608_12 = __local_itemminlength__goto_9609_12)
        goto '__ci_bb_9
    }

    '__ci_bb_8 {
        goto '__ci_bb_10
    }

    '__ci_bb_9 {
        if ((if (libc.INT_MAX - __local_branchlength__goto_9580_5) < ((__local_itemlength__goto_9608_12 as i32)): 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__local_branchlength__goto_9580_5 = ((((__local_branchlength__goto_9580_5 as u32) + __local_itemlength__goto_9608_12) as i32)))

            (__ci_expr_logic_10 = (if (if __local_branchlength__goto_9580_5 > libc.UINT16_MAX: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_181
        } else {
            goto '__ci_bb_182
        }
    }

    '__ci_bb_10 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149384192) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_11 {
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        ((*__param_pptrptr) = __local_pptr__goto_9585_11)
        ((*__param_minptr) = __local_branchminlength__goto_9581_5)
        return __local_branchlength__goto_9580_5
    }

    '__ci_bb_14 {
        (__local_pptr__goto_9585_11 = parsed_skip(__local_pptr__goto_9585_11, (0 as u32)))
        if ((if __local_pptr__goto_9585_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_15 {
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        goto '__ci_bb_13
    }

    '__ci_bb_17 {
        goto '__ci_bb_183
    }

    '__ci_bb_18 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((((__local_pptr__goto_9585_11[1]) as u32) +% (1 as u32)) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_19 {
        goto '__ci_bb_11
    }

    '__ci_bb_20 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((2 as isize) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_21 {
        (__local_itemminlength__goto_9609_12 = ((1 as u32)))
        (__local_itemlength__goto_9608_12 = __local_itemminlength__goto_9609_12)
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((1 as isize) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_22 {
        (__local_itemminlength__goto_9609_12 = ((1 as u32)))
        (__local_itemlength__goto_9608_12 = __local_itemminlength__goto_9609_12)
        (__local_pptr__goto_9585_11 = parsed_skip(__local_pptr__goto_9585_11, (1 as u32)))
        if ((if __local_pptr__goto_9585_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_23 {
        goto '__ci_bb_17
    }

    '__ci_bb_24 {
        goto '__ci_bb_11
    }

    '__ci_bb_25 {
        (__local_itemminlength__goto_9609_12 = ((1 as u32)))
        (__local_itemlength__goto_9608_12 = __local_itemminlength__goto_9609_12)
        goto '__ci_bb_11
    }

    '__ci_bb_26 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((3 as isize) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_27 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + (((3 + 2) as isize) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_28 {
        (__local_escape__goto_9605_12 = (((((*__local_pptr__goto_9585_11) as u32) & (65535 as u32)) as u32)))
        if ((if __local_escape__goto_9605_12 == 22: 1 else: 0) != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_29 {
        return -1
    }

    '__ci_bb_30 {
        if ((if __local_escape__goto_9605_12 == 17: 1 else: 0) != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_31 {
        (__local_itemminlength__goto_9609_12 = ((1 as u32)))
        (__local_itemlength__goto_9608_12 = ((2 as u32)))
        goto '__ci_bb_33
    }

    '__ci_bb_32 {
        (__ci_expr_logic_1 = 0)
        if ((if __local_escape__goto_9605_12 > 5: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_escape__goto_9605_12 < 23: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_33 {
        goto '__ci_bb_11
    }

    '__ci_bb_34 {
        (__ci_expr_logic_2 = 0)
        if ((if (((*__param_cb).external_options as u32) & (524288 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_escape__goto_9605_12 == 14: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_35 {
        goto '__ci_bb_33
    }

    '__ci_bb_36 {
        ((*__param_errcodeptr) = ERR36)
        return -1
    }

    '__ci_bb_37 {
        (__local_itemminlength__goto_9609_12 = ((1 as u32)))
        (__local_itemlength__goto_9608_12 = __local_itemminlength__goto_9609_12)
        if ((if __local_escape__goto_9605_12 == 16: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_escape__goto_9605_12 == 15: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_38 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + 1)
        goto '__ci_bb_39
    }

    '__ci_bb_39 {
        goto '__ci_bb_35
    }

    '__ci_bb_40 {
        ((*__param_errcodeptr) = ((check_lookbehinds((__local_pptr__goto_9585_11 + ((1 as isize) as usize)), (&raw mut __local_pptr__goto_9585_11 as *mut *mut u32), __param_recurses, __param_cb, __param_lcptr) as i32)))
        if ((if (*__param_errcodeptr) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_41 {
        return -1
    }

    '__ci_bb_42 {
        goto '__ci_bb_43
    }

    '__ci_bb_43 {
        if ((__local_pptr__goto_9585_11[1]) == 2151153664) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_44 {
        goto '__ci_bb_11
    }

    '__ci_bb_45 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + 1)
        goto '__ci_bb_44
    }

    '__ci_bb_46 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((3 as isize) as usize))
        goto '__ci_bb_44
    }

    '__ci_bb_47 {
        goto '__ci_bb_44
    }

    '__ci_bb_48 {
        if ((__local_pptr__goto_9585_11[1]) == 2151219200) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_49 {
        if ((__local_pptr__goto_9585_11[1]) == 2151284736) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_50 {
        if ((__local_pptr__goto_9585_11[1]) == 2151350272) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_51 {
        if ((__local_pptr__goto_9585_11[1]) == 2151415808) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_52 {
        if ((__local_pptr__goto_9585_11[1]) == 2151481344) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_53 {
        if ((__local_pptr__goto_9585_11[1]) == 2151546880) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        if ((__local_pptr__goto_9585_11[1]) == 2151612416) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_55 {
        if ((__local_pptr__goto_9585_11[1]) == 2151677952) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_56 {
        if ((__local_pptr__goto_9585_11[1]) == 2151743488) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_57 {
        if ((__local_pptr__goto_9585_11[1]) == 2151809024) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_58 {
        if ((__local_pptr__goto_9585_11[1]) == 2151874560) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_59 {
        if ((if not (set_lookbehind_lengths((&raw mut __local_pptr__goto_9585_11 as *mut *mut u32), __param_errcodeptr, __param_lcptr, __param_recurses, __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_60 {
        return -1
    }

    '__ci_bb_61 {
        goto '__ci_bb_11
    }

    '__ci_bb_62 {
        if ((if (((*__param_cb).external_options as u32) & (512 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_63 {
        goto '__ci_bb_65
    }

    '__ci_bb_64 {
        goto '__ci_bb_66
    }

    '__ci_bb_65 {
        ((*__param_errcodeptr) = ERR25)
        return -1
    }

    '__ci_bb_66 {
        (__local_is_dupname__goto_9765_12 = ((0 as i32)))
        (__local_meta_code__goto_9767_16 = (((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) as u32)))
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + 1)
        (__local_length__goto_9768_16 = (*__local_pptr__goto_9585_11))
        (__local_offset__goto_9586_12 = (((((((__local_pptr__goto_9585_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_9585_11[2]) as u64)) as u64)))
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((2 as isize) as usize))
        (__local_name__goto_9764_18 = (*__param_cb).start_pattern + (__local_offset__goto_9586_12 as usize))
        (__local_ng__goto_9766_20 = _pcre2_compile_find_named_group8(__local_name__goto_9764_18, __local_length__goto_9768_16, __param_cb))
        if ((if __local_ng__goto_9766_20 == null: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_67 {
        ((*__param_errcodeptr) = ERR15)
        ((*__param_cb).erroroffset = __local_offset__goto_9586_12)
        return -1
    }

    '__ci_bb_68 {
        (__local_group__goto_9607_12 = (*__local_ng__goto_9766_20).number)
        (__local_is_dupname__goto_9765_12 = (((if (((*__local_ng__goto_9766_20).hash_dup as i32) & (32768 as i32)) != 0: 1 else: 0) as i32)))
        if ((if __local_meta_code__goto_9767_16 == 2149908480: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_4: i32 = 0

            if ((if not (__local_is_dupname__goto_9765_12 != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if (((*__param_cb).external_flags as u32) & (2097152 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_69 {
        goto '__ci_bb_71
    }

    '__ci_bb_70 {
        goto '__ci_bb_65
    }

    '__ci_bb_71 {
        if ((if __local_group__goto_9607_12 > (*__param_cb).bracount: 1 else: 0) != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_72 {
        if ((if (((*__param_cb).external_options as u32) & (512 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if (((*__param_cb).external_flags as u32) & (2097152 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_73 {
        goto '__ci_bb_65
    }

    '__ci_bb_74 {
        (__local_group__goto_9607_12 = (((((*__local_pptr__goto_9585_11) as u32) & (65535 as u32)) as u32)))
        if ((if __local_group__goto_9607_12 < 10: 1 else: 0) != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_75 {
        (__local_offset__goto_9586_12 = (((*__param_cb).small_ref_offset[__local_group__goto_9607_12] as u64)))
        goto '__ci_bb_71
    }

    '__ci_bb_76 {
        goto '__ci_bb_77
    }

    '__ci_bb_77 {
        (__local_group__goto_9607_12 = (((((*__local_pptr__goto_9585_11) as u32) & (65535 as u32)) as u32)))
        (__local_offset__goto_9586_12 = (((((((__local_pptr__goto_9585_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_9585_11[2]) as u64)) as u64)))
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((2 as isize) as usize))
        goto '__ci_bb_71
    }

    '__ci_bb_78 {
        ((*__param_cb).erroroffset = __local_offset__goto_9586_12)
        ((*__param_errcodeptr) = ERR15)
        return -1
    }

    '__ci_bb_79 {
        if ((if __local_group__goto_9607_12 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_80 {
        goto '__ci_bb_65
    }

    '__ci_bb_81 {
        (__local_gptr__goto_9604_13 = (*__param_cb).parsed_pattern)
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        if ((if (*__local_gptr__goto_9604_13) != 2147483648: 1 else: 0) != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_83 {
        if ((if (((*__local_gptr__goto_9604_13) as u32) & (4294901760 as u32)) == 2147811328: 1 else: 0) != 0) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_84 {
        (__local_gptr__goto_9604_13 = __local_gptr__goto_9604_13 + 1)
        goto '__ci_bb_82
    }

    '__ci_bb_85 {
        (__local_gptrend__goto_9604_20 = parsed_skip((__local_gptr__goto_9604_13 + ((1 as isize) as usize)), (2 as u32)))
        if ((if __local_gptrend__goto_9604_20 == null: 1 else: 0) != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_86 {
        (__local_gptr__goto_9604_13 = __local_gptr__goto_9604_13 + 1)
        goto '__ci_bb_88
    }

    '__ci_bb_87 {
        if ((if (*__local_gptr__goto_9604_13) == ((2148007936 as u32) | (__local_group__goto_9607_12 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_88 {
        goto '__ci_bb_84
    }

    '__ci_bb_89 {
        goto '__ci_bb_85
    }

    '__ci_bb_90 {
        goto '__ci_bb_88
    }

    '__ci_bb_91 {
        goto '__ci_bb_17
    }

    '__ci_bb_92 {
        (__ci_expr_logic_7 = 0)
        if ((if __local_pptr__goto_9585_11 > __local_gptr__goto_9604_13: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if __local_pptr__goto_9585_11 < __local_gptrend__goto_9604_20: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_94
        }
    }

    '__ci_bb_93 {
        goto '__ci_bb_65
    }

    '__ci_bb_94 {
        (__local_r__goto_9603_25 = __param_recurses)
        goto '__ci_bb_95
    }

    '__ci_bb_95 {
        if ((if __local_r__goto_9603_25 != null: 1 else: 0) != 0) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_96 {
        if ((if (*__local_r__goto_9603_25).groupptr == __local_gptr__goto_9604_13: 1 else: 0) != 0) {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_100
        }
    }

    '__ci_bb_97 {
        (__local_r__goto_9603_25 = (*__local_r__goto_9603_25).prev)
        goto '__ci_bb_95
    }

    '__ci_bb_98 {
        if ((if __local_r__goto_9603_25 != null: 1 else: 0) != 0) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_99 {
        goto '__ci_bb_98
    }

    '__ci_bb_100 {
        goto '__ci_bb_97
    }

    '__ci_bb_101 {
        goto '__ci_bb_65
    }

    '__ci_bb_102 {
        (__local_this_recurse__goto_9587_22.prev = __param_recurses)
        (__local_this_recurse__goto_9587_22.groupptr = __local_gptr__goto_9604_13)
        (__local_gptr__goto_9604_13 = __local_gptr__goto_9604_13 + 1)
        (__local_grouplength__goto_9582_5 = ((get_grouplength((&raw mut __local_gptr__goto_9604_13 as *mut *mut u32), (&raw mut __local_groupminlength__goto_9582_18 as *mut i32), (0 as i32), __param_errcodeptr, __param_lcptr, (__local_group__goto_9607_12 as i32), (&raw mut __local_this_recurse__goto_9587_22 as *mut parsed_recurse_check), __param_cb) as i32)))
        if ((if __local_grouplength__goto_9582_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_103 {
        if ((if (*__param_errcodeptr) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_104 {
        (__local_itemlength__goto_9608_12 = ((__local_grouplength__goto_9582_5 as u32)))
        (__local_itemminlength__goto_9609_12 = ((__local_groupminlength__goto_9582_18 as u32)))
        goto '__ci_bb_11
    }

    '__ci_bb_105 {
        goto '__ci_bb_65
    }

    '__ci_bb_106 {
        return -1
    }

    '__ci_bb_107 {
        (__local_pptr__goto_9585_11 = parsed_skip((__local_pptr__goto_9585_11 + ((1 as isize) as usize)), (2 as u32)))
        goto '__ci_bb_11
    }

    '__ci_bb_108 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + (((2 + 2) as isize) as usize))
        goto '__ci_bb_109
    }

    '__ci_bb_109 {
        (__local_grouplength__goto_9582_5 = ((get_grouplength((&raw mut __local_pptr__goto_9585_11 as *mut *mut u32), (&raw mut __local_groupminlength__goto_9582_18 as *mut i32), (1 as i32), __param_errcodeptr, __param_lcptr, (__local_group__goto_9607_12 as i32), __param_recurses, __param_cb) as i32)))
        if ((if __local_grouplength__goto_9582_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_115
        }
    }

    '__ci_bb_110 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((1 as isize) as usize))
        goto '__ci_bb_109
    }

    '__ci_bb_111 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((4 as isize) as usize))
        goto '__ci_bb_109
    }

    '__ci_bb_112 {
        (__local_group__goto_9607_12 = (((((*__local_pptr__goto_9585_11) as u32) & (65535 as u32)) as u32)))
        goto '__ci_bb_113
    }

    '__ci_bb_113 {
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + 1)
        goto '__ci_bb_109
    }

    '__ci_bb_114 {
        return -1
    }

    '__ci_bb_115 {
        (__local_itemlength__goto_9608_12 = ((__local_grouplength__goto_9582_5 as u32)))
        (__local_itemminlength__goto_9609_12 = ((__local_groupminlength__goto_9582_18 as u32)))
        goto '__ci_bb_11
    }

    '__ci_bb_116 {
        (__local_min__goto_9606_12 = ((0 as u32)))
        (__local_max__goto_9606_17 = ((1 as u32)))
        goto '__ci_bb_117
    }

    '__ci_bb_117 {
        if ((if __local_max__goto_9606_17 != ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_118 {
        (__local_min__goto_9606_12 = (((__local_pptr__goto_9585_11[1]) as u32)))
        (__local_max__goto_9606_17 = (((__local_pptr__goto_9585_11[2]) as u32)))
        (__local_pptr__goto_9585_11 = __local_pptr__goto_9585_11 + ((2 as isize) as usize))
        goto '__ci_bb_117
    }

    '__ci_bb_119 {
        (__ci_expr_logic_9 = 0)
        (__ci_expr_logic_8 = 0)
        if ((if __local_lastitemlength__goto_9583_10 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if __local_max__goto_9606_17 != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_logic_9 = (if (if (((libc.INT_MAX - __local_branchlength__goto_9580_5) as u32) / (__local_lastitemlength__goto_9583_10 as u32)) < ((__local_max__goto_9606_17 as u32) -% (1 as u32)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_120 {
        goto '__ci_bb_129
    }

    '__ci_bb_121 {
        ((*__param_errcodeptr) = ERR87)
        return -1
    }

    '__ci_bb_122 {
        if ((if __local_min__goto_9606_12 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_123
        } else {
            goto '__ci_bb_124
        }
    }

    '__ci_bb_123 {
        (__local_branchminlength__goto_9581_5 = ((((__local_branchminlength__goto_9581_5 as u32) - __local_lastitemminlength__goto_9584_10) as i32)))
        goto '__ci_bb_125
    }

    '__ci_bb_124 {
        (__local_itemminlength__goto_9609_12 = ((((((__local_min__goto_9606_12 as u32) -% (1 as u32)) as u32) *% (__local_lastitemminlength__goto_9584_10 as u32)) as u32)))
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        if ((if __local_max__goto_9606_17 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_126 {
        (__local_branchlength__goto_9580_5 = ((((__local_branchlength__goto_9580_5 as u32) - __local_lastitemlength__goto_9583_10) as i32)))
        goto '__ci_bb_128
    }

    '__ci_bb_127 {
        (__local_itemlength__goto_9608_12 = ((((((__local_max__goto_9606_17 as u32) -% (1 as u32)) as u32) *% (__local_lastitemlength__goto_9583_10 as u32)) as u32)))
        goto '__ci_bb_128
    }

    '__ci_bb_128 {
        goto '__ci_bb_11
    }

    '__ci_bb_129 {
        goto '__ci_bb_65
    }

    '__ci_bb_130 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147549184) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_131 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150498304) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_132 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150563840) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_133 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150432768) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_134 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150694912) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_135 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150825984) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_136 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150957056) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_137 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151088128) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_138 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148073472) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_139 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150629376) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_140 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149187584) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_141 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150760448) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_142 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150891520) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_143 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151022592) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_144 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149515264) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_145 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147811328) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_146 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148139008) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_147 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148401152) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_148 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148270080) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_149 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149253120) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_150 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147876864) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_151 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147942400) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_152 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149318656) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_153 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150039552) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_154 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150105088) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_155 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150301696) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_156 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148990976) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_157 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150170624) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_158 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150236160) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_159 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2150367232) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_160 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147745792) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_161 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149908480) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_162 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147680256) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_163 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149842944) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_164 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148532224) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_165 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148597760) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_166 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148663296) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_167 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148728832) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_168 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148794368) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_169
        }
    }

    '__ci_bb_169 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148466688) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_170 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148859904) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_171 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2148007936) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_172 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2147614720) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_173 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149449728) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_174 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2149974016) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_175 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151546880) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_176 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151612416) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_177 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151677952) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_178 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151743488) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_179 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151809024) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_180 {
        if ((((*__local_pptr__goto_9585_11) as u32) & (4294901760 as u32)) == 2151874560) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_181 {
        ((*__param_errcodeptr) = ERR87)
        return -1
    }

    '__ci_bb_182 {
        (__local_branchminlength__goto_9581_5 = ((((__local_branchminlength__goto_9581_5 as u32) + __local_itemminlength__goto_9609_12) as i32)))
        (__local_lastitemlength__goto_9583_10 = __local_itemlength__goto_9608_12)
        (__local_lastitemminlength__goto_9584_10 = __local_itemminlength__goto_9609_12)
        goto '__ci_bb_5
    }

    '__ci_bb_183 {
        goto '__ci_bb_184
    }

    '__ci_bb_184 {
        if (0 != 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_185 {
        ((*__param_errcodeptr) = ERR90)
        return -1
    }

    __ci_unreachable()

}

unsafe fn set_lookbehind_lengths(__param_pptrptr: *mut *mut u32, __param_errcodeptr: *mut i32, __param_lcptr: *mut i32, __param_recurses: *mut parsed_recurse_check, __param_cb: *mut compile_block_8) -> i32 {
    var __local_offset: u64

    var __local_bptr: *mut u32 = (*__param_pptrptr)

    var __local_gbptr: *mut u32 = __local_bptr

    var __local_maxlength: i32 = ((0 as i32))

    var __local_minlength: i32 = ((libc.INT_MAX as i32))

    var __local_variable: i32 = ((0 as i32))

    (__local_offset = (((((((__local_bptr[1]) as u64) << (32 as u32)) as u64) | ((__local_bptr[2]) as u64)) as u64)))



    ((*__param_pptrptr) = (*__param_pptrptr) + ((2 as isize) as usize))

    loop {
        var __local_branchlength: i32

        var __local_branchminlength: i32


        ((*__param_pptrptr) = (*__param_pptrptr) + ((1 as isize) as usize))

        (__local_branchlength = ((get_branchlength(__param_pptrptr, (&raw mut __local_branchminlength as *mut i32), __param_errcodeptr, __param_lcptr, __param_recurses, __param_cb) as i32)))

        if ((if __local_branchlength < 0: 1 else: 0) != 0) {
            if ((if (*__param_errcodeptr) == 0: 1 else: 0) != 0) {
                ((*__param_errcodeptr) = ERR25)
            }

            if ((if (*__param_cb).erroroffset == (~(0 as u64)): 1 else: 0) != 0) {
                ((*__param_cb).erroroffset = __local_offset)
            }

            return 0

        }

        if ((if __local_branchlength != __local_branchminlength: 1 else: 0) != 0) {
            (__local_variable = ((1 as i32)))
        }

        if ((if __local_branchminlength < __local_minlength: 1 else: 0) != 0) {
            (__local_minlength = __local_branchminlength)
        }

        if ((if __local_branchlength > __local_maxlength: 1 else: 0) != 0) {
            (__local_maxlength = __local_branchlength)
        }

        if ((if __local_branchlength > (*__param_cb).max_lookbehind: 1 else: 0) != 0) {
            ((*__param_cb).max_lookbehind = __local_branchlength)
        }

        ((*__local_bptr) = ((*__local_bptr) as u32) | (__local_branchlength as u32))

        (__local_bptr = (*__param_pptrptr))

        if not (((if (((*__local_bptr) as u32) & (4294901760 as u32)) == 2147549184: 1 else: 0) != 0)) {
            break
        }
    }

    if (__local_variable != 0) {
        ((__local_gbptr[1]) = ((__local_minlength as u32)))

        if ((if ((__local_maxlength as u64)) > (*__param_cb).max_varlookbehind: 1 else: 0) != 0) {
            ((*__param_errcodeptr) = ERR100)

            ((*__param_cb).erroroffset = __local_offset)

            return 0

        }

    } else {
        ((__local_gbptr[1]) = ((65535 as u32)))
    }

    return 1

}

unsafe fn check_lookbehinds(__param_pptr: *mut u32, __param_retptr: *mut *mut u32, __param_recurses: *mut parsed_recurse_check, __param_cb: *mut compile_block_8, __param_lcptr: *mut i32) -> i32 {
    var __local_pptr = __param_pptr
    var __local_errorcode: i32 = ((0 as i32))

    var __local_nestlevel: i32 = ((0 as i32))

    ((*__param_cb).erroroffset = (((~(0 as u64)) as u64)))

    while ((if (*__local_pptr) != 2147483648: 1 else: 0) != 0) {
        if ((if (*__local_pptr) < 2147483648: 1 else: 0) != 0) {
            (__local_pptr = __local_pptr + 1)

            continue

        }

        while true {
            match (((*__local_pptr) as u32) & (4294901760 as u32)) {
                2149318656 => {
                    var __ci_expr_logic_0: i32

                    if ((if (((*__local_pptr) as u32) -% (2149318656 as u32)) == 15: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_0 = (if (if (((*__local_pptr) as u32) -% (2149318656 as u32)) == 16: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_pptr = __local_pptr + ((1 as isize) as usize))
                    }

                },
                2149384192 => {
                    (__local_nestlevel = __local_nestlevel - 1)

                    if ((if __local_nestlevel < 0: 1 else: 0) != 0) {
                        if ((if __param_retptr != null: 1 else: 0) != 0) {
                            ((*__param_retptr) = __local_pptr)
                        }

                        return 0

                    }

                },
                2147614720 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2148007936 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2148466688 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2148990976 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2150039552 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2150105088 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2150301696 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2149449728 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2149974016 => {
                    (__local_nestlevel = __local_nestlevel + 1)
                },
                2150498304 => {
                    0
                },
                2147549184 => {
                    0
                },
                2151153664 => {
                    0
                },
                2151219200 => {
                    0
                },
                2151284736 => {
                    0
                },
                2147680256 => {
                    0
                },
                2148073472 => {
                    0
                },
                2148139008 => {
                    0
                },
                2148204544 => {
                    0
                },
                2148270080 => {
                    0
                },
                2148335616 => {
                    0
                },
                2148401152 => {
                    0
                },
                2150629376 => {
                    0
                },
                2149187584 => {
                    0
                },
                2149253120 => {
                    0
                },
                2150563840 => {
                    0
                },
                2151350272 => {
                    0
                },
                2151415808 => {
                    0
                },
                2151481344 => {
                    0
                },
                2150760448 => {
                    0
                },
                2151546880 => {
                    0
                },
                2151612416 => {
                    0
                },
                2151677952 => {
                    0
                },
                2149711872 => {
                    0
                },
                2149777408 => {
                    0
                },
                2150891520 => {
                    0
                },
                2151022592 => {
                    0
                },
                2148925440 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))
                },
                2149842944 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))
                },
                2147745792 => {
                    (__local_pptr = __local_pptr + (((1 + 2) as isize) as usize))
                },
                2149908480 => {
                    (__local_pptr = __local_pptr + (((1 + 2) as isize) as usize))
                },
                2148532224 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__local_nestlevel = __local_nestlevel + 1)

                },
                2148597760 => {
                    (__local_pptr = __local_pptr + (((1 + 2) as isize) as usize))

                    (__local_nestlevel = __local_nestlevel + 1)

                },
                2148663296 => {
                    (__local_pptr = __local_pptr + (((1 + 2) as isize) as usize))

                    (__local_nestlevel = __local_nestlevel + 1)

                },
                2148728832 => {
                    (__local_pptr = __local_pptr + (((1 + 2) as isize) as usize))

                    (__local_nestlevel = __local_nestlevel + 1)

                },
                2148794368 => {
                    (__local_pptr = __local_pptr + (((1 + 2) as isize) as usize))

                    (__local_nestlevel = __local_nestlevel + 1)

                },
                2148859904 => {
                    (__local_pptr = __local_pptr + ((3 as isize) as usize))

                    (__local_nestlevel = __local_nestlevel + 1)

                },
                2147942400 => {
                    (__local_pptr = __local_pptr + (((3 + 2) as isize) as usize))
                },
                2147811328 => {
                    (__local_pptr = __local_pptr + ((1 as isize) as usize))
                },
                2149580800 => {
                    (__local_pptr = __local_pptr + ((1 as isize) as usize))
                },
                2149646336 => {
                    (__local_pptr = __local_pptr + ((1 as isize) as usize))
                },
                2149056512 => {
                    (__local_pptr = __local_pptr + ((1 as isize) as usize))
                },
                2149122048 => {
                    (__local_pptr = __local_pptr + ((1 as isize) as usize))
                },
                2151743488 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))
                },
                2151874560 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))
                },
                2151809024 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))
                },
                2149515264 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))
                },
                2147876864 => {
                    (__local_pptr = __local_pptr + ((3 as isize) as usize))
                },
                2150432768 => {
                    (__local_pptr = __local_pptr + (((1 as u32) +% ((__local_pptr[1]) as u32)) as usize))
                },
                2150694912 => {
                    (__local_pptr = __local_pptr + (((1 as u32) +% ((__local_pptr[1]) as u32)) as usize))
                },
                2150825984 => {
                    (__local_pptr = __local_pptr + (((1 as u32) +% ((__local_pptr[1]) as u32)) as usize))
                },
                2150957056 => {
                    (__local_pptr = __local_pptr + (((1 as u32) +% ((__local_pptr[1]) as u32)) as usize))
                },
                2151088128 => {
                    (__local_pptr = __local_pptr + (((1 as u32) +% ((__local_pptr[1]) as u32)) as usize))
                },
                2150170624 => {
                    if ((if not (set_lookbehind_lengths((&raw mut __local_pptr as *mut *mut u32), (&raw mut __local_errorcode as *mut i32), __param_lcptr, __param_recurses, __param_cb) != 0): 1 else: 0) != 0) {
                        return __local_errorcode
                    }
                },
                2150236160 => {
                    if ((if not (set_lookbehind_lengths((&raw mut __local_pptr as *mut *mut u32), (&raw mut __local_errorcode as *mut i32), __param_lcptr, __param_recurses, __param_cb) != 0): 1 else: 0) != 0) {
                        return __local_errorcode
                    }
                },
                2150367232 => {
                    if ((if not (set_lookbehind_lengths((&raw mut __local_pptr as *mut *mut u32), (&raw mut __local_errorcode as *mut i32), __param_lcptr, __param_recurses, __param_cb) != 0): 1 else: 0) != 0) {
                        return __local_errorcode
                    }
                },
                _ => {
                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    ((*__param_cb).erroroffset = ((0 as u64)))

                    return ERR70

                },
            }

            break

        }


        (__local_pptr = __local_pptr + 1)

    }

    return 0

}

unsafe fn read_number(__param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_allow_sign: i32, __param_max_value: u32, __param_max_error: u32, __param_intptr: *mut i32, __param_errorcodeptr: *mut i32) -> i32 {
    var __local_max_value = __param_max_value
    var __local_sign__goto_1263_5: i32 = 0

    var __local_n__goto_1264_10: u32 = 0

    var __local_ptr__goto_1265_12: *const u8 = null

    var __local_yield___goto_1266_6: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_old_5: *const u8 = null

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_8: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_sign__goto_1263_5 = ((0 as i32)))
        (__local_n__goto_1264_10 = ((0 as u32)))
        (__local_ptr__goto_1265_12 = (*__param_ptrptr))
        (__local_yield___goto_1266_6 = ((0 as i32)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        if (0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        ((*__param_errorcodeptr) = ((0 as i32)))
        (__ci_expr_logic_0 = 0)
        if ((if __param_allow_sign >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_ptr__goto_1265_12 < __param_ptrend: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        if ((if (*__local_ptr__goto_1265_12) == 43: 1 else: 0) != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_5 {
        if ((if __local_ptr__goto_1265_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_1: i32 = 0

            if ((if (*__local_ptr__goto_1265_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if (*__local_ptr__goto_1265_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_2 = (if (if not (__ci_expr_logic_1 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_6 {
        (__local_sign__goto_1263_5 = ((1 as i32)))
        (__local_max_value = (__local_max_value -% (__param_allow_sign as u32)))
        (__local_ptr__goto_1265_12 = __local_ptr__goto_1265_12 + 1)
        goto '__ci_bb_8
    }

    '__ci_bb_7 {
        if ((if (*__local_ptr__goto_1265_12) == 45: 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_5
    }

    '__ci_bb_9 {
        (__local_sign__goto_1263_5 = ((-1 as i32)))
        (__local_ptr__goto_1265_12 = __local_ptr__goto_1265_12 + 1)
        goto '__ci_bb_10
    }

    '__ci_bb_10 {
        goto '__ci_bb_8
    }

    '__ci_bb_11 {
        return 0
    }

    '__ci_bb_12 {
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        (__ci_expr_logic_4 = 0)
        if ((if __local_ptr__goto_1265_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_3: i32 = 0

            if ((if (*__local_ptr__goto_1265_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if (*__local_ptr__goto_1265_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_14 {
        (__ci_expr_old_5 = __local_ptr__goto_1265_12)
        (__local_ptr__goto_1265_12 = __local_ptr__goto_1265_12 + 1)
        (__local_n__goto_1264_10 = ((((((__local_n__goto_1264_10 as u32) *% (10 as u32)) as u32) +% ((((*__ci_expr_old_5) as i32) - 48) as u32)) as u32)))
        if ((if __local_n__goto_1264_10 > __local_max_value: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_15 {
        (__ci_expr_logic_8 = 0)
        if ((if __param_allow_sign >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if __local_sign__goto_1263_5 != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_8 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_16 {
        ((*__param_errorcodeptr) = ((__param_max_error as i32)))
        goto '__ci_bb_18
    }

    '__ci_bb_17 {
        goto '__ci_bb_13
    }

    '__ci_bb_18 {
        (__ci_expr_logic_7 = 0)
        if ((if __local_ptr__goto_1265_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_6: i32 = 0

            if ((if (*__local_ptr__goto_1265_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if (*__local_ptr__goto_1265_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_7 = (if __ci_expr_logic_6 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_19 {
        (__local_ptr__goto_1265_12 = __local_ptr__goto_1265_12 + 1)
        goto '__ci_bb_18
    }

    '__ci_bb_20 {
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        ((*__param_intptr) = ((__local_n__goto_1264_10 as i32)))
        ((*__param_ptrptr) = __local_ptr__goto_1265_12)
        return __local_yield___goto_1266_6
    }

    '__ci_bb_22 {
        if ((if __local_n__goto_1264_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        (__local_yield___goto_1266_6 = ((1 as i32)))
        goto '__ci_bb_21
    }

    '__ci_bb_24 {
        ((*__param_errorcodeptr) = ERR26)
        goto '__ci_bb_21
    }

    '__ci_bb_25 {
        if ((if __local_sign__goto_1263_5 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_26 {
        (__local_n__goto_1264_10 = (__local_n__goto_1264_10 +% (__param_allow_sign as u32)))
        goto '__ci_bb_28
    }

    '__ci_bb_27 {
        if ((if __local_n__goto_1264_10 > ((__param_allow_sign as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_23
    }

    '__ci_bb_29 {
        ((*__param_errorcodeptr) = ERR15)
        goto '__ci_bb_21
    }

    '__ci_bb_30 {
        (__local_n__goto_1264_10 = (((((__param_allow_sign + 1) as u32) -% (__local_n__goto_1264_10 as u32)) as u32)))
        goto '__ci_bb_31
    }

    '__ci_bb_31 {
        goto '__ci_bb_28
    }

    __ci_unreachable()

}

unsafe fn read_repeat_counts(__param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_minp: *mut u32, __param_maxp: *mut u32, __param_errorcodeptr: *mut i32) -> i32 {
    var __local_p__goto_1353_12: *const u8 = null

    var __local_pp__goto_1354_12: *const u8 = null

    var __local_yield___goto_1355_6: i32 = 0

    var __local_had_minimum__goto_1356_6: i32 = 0

    var __local_min__goto_1357_9: i32 = 0

    var __local_max__goto_1358_9: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_old_8: *const u8 = null

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_15: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_logic_18: i32 = 0

    var __ci_expr_logic_20: i32 = 0

    var __ci_expr_logic_22: i32 = 0

    var __ci_expr_logic_24: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_p__goto_1353_12 = (*__param_ptrptr))
        (__local_yield___goto_1355_6 = ((0 as i32)))
        (__local_had_minimum__goto_1356_6 = ((0 as i32)))
        (__local_min__goto_1357_9 = ((0 as i32)))
        (__local_max__goto_1358_9 = ((65536 as i32)))
        ((*__param_errorcodeptr) = ((0 as i32)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__ci_expr_logic_1 = 0)
        if ((if __local_p__goto_1353_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_0: i32

            if ((if (*__local_p__goto_1353_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if (*__local_p__goto_1353_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_1
    }

    '__ci_bb_3 {
        (__local_pp__goto_1354_12 = __local_p__goto_1353_12)
        (__ci_expr_logic_3 = 0)
        if ((if __local_pp__goto_1354_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_2: i32 = 0

            if ((if (*__local_pp__goto_1354_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if (*__local_pp__goto_1354_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_had_minimum__goto_1356_6 = ((1 as i32)))
        goto '__ci_bb_6
    }

    '__ci_bb_5 {
        goto '__ci_bb_9
    }

    '__ci_bb_6 {
        (__ci_expr_logic_5 = 0)
        (__local_pp__goto_1354_12 = __local_pp__goto_1354_12 + 1)
        if ((if __local_pp__goto_1354_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_4: i32 = 0

            if ((if (*__local_pp__goto_1354_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if (*__local_pp__goto_1354_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_7 {
        goto '__ci_bb_6
    }

    '__ci_bb_8 {
        goto '__ci_bb_5
    }

    '__ci_bb_9 {
        (__ci_expr_logic_7 = 0)
        if ((if __local_pp__goto_1354_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_6: i32

            if ((if (*__local_pp__goto_1354_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if (*__local_pp__goto_1354_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_7 = (if __ci_expr_logic_6 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_10 {
        (__local_pp__goto_1354_12 = __local_pp__goto_1354_12 + 1)
        goto '__ci_bb_9
    }

    '__ci_bb_11 {
        if ((if __local_pp__goto_1354_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_12 {
        return 0
    }

    '__ci_bb_13 {
        if ((if (*__local_pp__goto_1354_12) == 125: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_14 {
        if ((if not (__local_had_minimum__goto_1356_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_15 {
        (__ci_expr_old_8 = __local_pp__goto_1354_12)
        (__local_pp__goto_1354_12 = __local_pp__goto_1354_12 + 1)
        if ((if (*__ci_expr_old_8) != 44: 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_16 {
        if ((if not (read_number((&raw mut __local_p__goto_1353_12 as *mut *const u8), __param_ptrend, (-1 as i32), (65535 as u32), (105 as u32), (&raw mut __local_min__goto_1357_9 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_17 {
        return 0
    }

    '__ci_bb_18 {
        goto '__ci_bb_16
    }

    '__ci_bb_19 {
        return 0
    }

    '__ci_bb_20 {
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        (__ci_expr_logic_10 = 0)
        if ((if __local_pp__goto_1354_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_9: i32

            if ((if (*__local_pp__goto_1354_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_9 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_9 = (if (if (*__local_pp__goto_1354_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_22 {
        (__local_pp__goto_1354_12 = __local_pp__goto_1354_12 + 1)
        goto '__ci_bb_21
    }

    '__ci_bb_23 {
        if ((if __local_pp__goto_1354_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_24 {
        return 0
    }

    '__ci_bb_25 {
        (__ci_expr_logic_11 = 0)
        if ((if (*__local_pp__goto_1354_12) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_11 = (if (if (*__local_pp__goto_1354_12) <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_26 {
        goto '__ci_bb_29
    }

    '__ci_bb_27 {
        if ((if not (__local_had_minimum__goto_1356_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_34
    }

    '__ci_bb_29 {
        (__ci_expr_logic_13 = 0)
        (__local_pp__goto_1354_12 = __local_pp__goto_1354_12 + 1)
        if ((if __local_pp__goto_1354_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_12: i32 = 0

            if ((if (*__local_pp__goto_1354_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_12 = (if (if (*__local_pp__goto_1354_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_13 = (if __ci_expr_logic_12 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_29
    }

    '__ci_bb_31 {
        goto '__ci_bb_28
    }

    '__ci_bb_32 {
        return 0
    }

    '__ci_bb_33 {
        goto '__ci_bb_28
    }

    '__ci_bb_34 {
        (__ci_expr_logic_15 = 0)
        if ((if __local_pp__goto_1354_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_14: i32

            if ((if (*__local_pp__goto_1354_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_14 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_14 = (if (if (*__local_pp__goto_1354_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_15 = (if __ci_expr_logic_14 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_35 {
        (__local_pp__goto_1354_12 = __local_pp__goto_1354_12 + 1)
        goto '__ci_bb_34
    }

    '__ci_bb_36 {
        if ((if __local_pp__goto_1354_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_16 = (if (if (*__local_pp__goto_1354_12) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_37 {
        return 0
    }

    '__ci_bb_38 {
        goto '__ci_bb_16
    }

    '__ci_bb_39 {
        if ((if (*__param_errorcodeptr) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_40 {
        goto '__ci_bb_52
    }

    '__ci_bb_41 {
        goto '__ci_bb_67
    }

    '__ci_bb_42 {
        goto '__ci_bb_44
    }

    '__ci_bb_43 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_45
    }

    '__ci_bb_44 {
        ((*__param_ptrptr) = __local_p__goto_1353_12)
        return __local_yield___goto_1355_6
    }

    '__ci_bb_45 {
        (__ci_expr_logic_18 = 0)
        if ((if __local_p__goto_1353_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_17: i32

            if ((if (*__local_p__goto_1353_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_17 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_17 = (if (if (*__local_p__goto_1353_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_18 = (if __ci_expr_logic_17 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_45
    }

    '__ci_bb_47 {
        if ((if not (read_number((&raw mut __local_p__goto_1353_12 as *mut *const u8), __param_ptrend, (-1 as i32), (65535 as u32), (105 as u32), (&raw mut __local_max__goto_1358_9 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_48 {
        if ((if (*__param_errorcodeptr) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_49 {
        goto '__ci_bb_41
    }

    '__ci_bb_50 {
        goto '__ci_bb_44
    }

    '__ci_bb_51 {
        goto '__ci_bb_49
    }

    '__ci_bb_52 {
        (__ci_expr_logic_20 = 0)
        if ((if __local_p__goto_1353_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_19: i32

            if ((if (*__local_p__goto_1353_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_19 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_19 = (if (if (*__local_p__goto_1353_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_20 = (if __ci_expr_logic_19 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_20 != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_53 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_52
    }

    '__ci_bb_54 {
        if ((if (*__local_p__goto_1353_12) == 125: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_55 {
        (__local_max__goto_1358_9 = __local_min__goto_1357_9)
        goto '__ci_bb_57
    }

    '__ci_bb_56 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_58
    }

    '__ci_bb_57 {
        goto '__ci_bb_41
    }

    '__ci_bb_58 {
        (__ci_expr_logic_22 = 0)
        if ((if __local_p__goto_1353_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_21: i32

            if ((if (*__local_p__goto_1353_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_21 = (if (if (*__local_p__goto_1353_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_22 != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_59 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_58
    }

    '__ci_bb_60 {
        if ((if not (read_number((&raw mut __local_p__goto_1353_12 as *mut *const u8), __param_ptrend, (-1 as i32), (65535 as u32), (105 as u32), (&raw mut __local_max__goto_1358_9 as *mut i32), __param_errorcodeptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_61 {
        if ((if (*__param_errorcodeptr) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_62 {
        if ((if __local_max__goto_1358_9 < __local_min__goto_1357_9: 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_63 {
        goto '__ci_bb_44
    }

    '__ci_bb_64 {
        goto '__ci_bb_62
    }

    '__ci_bb_65 {
        ((*__param_errorcodeptr) = ERR4)
        goto '__ci_bb_44
    }

    '__ci_bb_66 {
        goto '__ci_bb_57
    }

    '__ci_bb_67 {
        (__ci_expr_logic_24 = 0)
        if ((if __local_p__goto_1353_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_23: i32

            if ((if (*__local_p__goto_1353_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_23 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_23 = (if (if (*__local_p__goto_1353_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_24 = (if __ci_expr_logic_23 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_68 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        goto '__ci_bb_67
    }

    '__ci_bb_69 {
        (__local_p__goto_1353_12 = __local_p__goto_1353_12 + 1)
        (__local_yield___goto_1355_6 = ((1 as i32)))
        if ((if __param_minp != null: 1 else: 0) != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_70 {
        ((*__param_minp) = ((__local_min__goto_1357_9 as u32)))
        goto '__ci_bb_71
    }

    '__ci_bb_71 {
        if ((if __param_maxp != null: 1 else: 0) != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_72 {
        ((*__param_maxp) = ((__local_max__goto_1358_9 as u32)))
        goto '__ci_bb_73
    }

    '__ci_bb_73 {
        goto '__ci_bb_44
    }

    __ci_unreachable()

}

unsafe fn get_ucp(__param_ptrptr: *mut *const u8, __param_utf: i32, __param_negptr: *mut i32, __param_ptypeptr: *mut u16, __param_pdataptr: *mut u16, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8) -> i32 {
    var __local_c__goto_2262_10: u32 = 0

    var __local_i__goto_2263_11: i64 = 0

    var __local_bot__goto_2264_12: u64 = 0

    var __local_top__goto_2264_17: u64 = 0

    var __local_ptr__goto_2265_12: *const u8 = null

    var __local_name__goto_2266_13: List[u8] = [0; 50]

    var __local_vptr__goto_2267_14: *mut u8 = null

    var __local_ptscript__goto_2268_10: u16 = 0

    var __local_offset__goto_2374_7: i32 = 0

    var __local_sname__goto_2375_15: List[u8] = [0; 8]

    var __local_r__goto_2415_7: i32 = 0

    var __ci_expr_old_0: *const u8 = null

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_old_2: *const u8 = null

    var __ci_expr_old_3: *const u8 = null

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_old_5: *const u8 = null

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_15: i32 = 0

    var __ci_expr_logic_14: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_logic_18: i32 = 0

    var __ci_expr_logic_19: i32 = 0

    var __ci_expr_logic_20: i32 = 0

    var __ci_expr_logic_21: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_ptr__goto_2265_12 = (*__param_ptrptr))
        (__local_vptr__goto_2267_14 = ((null as *mut u8)))
        (__local_ptscript__goto_2268_10 = ((255 as u16)))
        if ((if __local_ptr__goto_2265_12 >= (*__param_cb).end_pattern: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        (__ci_expr_old_0 = __local_ptr__goto_2265_12)
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + 1)
        (__local_c__goto_2262_10 = (((*__ci_expr_old_0) as u32)))
        (__ci_expr_logic_1 = 0)
        if (__param_utf != 0) {
            (__ci_expr_logic_1 = (if (if __local_c__goto_2262_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_3 {
        ((*__param_errorcodeptr) = ERR46)
        ((*__param_ptrptr) = __local_ptr__goto_2265_12)
        return 0
    }

    '__ci_bb_4 {
        if ((if ((__local_c__goto_2262_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_5 {
        ((*__param_negptr) = ((0 as i32)))
        if ((if __local_c__goto_2262_10 == 123: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_6 {
        (__ci_expr_old_2 = __local_ptr__goto_2265_12)
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + 1)
        (__local_c__goto_2262_10 = ((((((((__local_c__goto_2262_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_2) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_8
    }

    '__ci_bb_7 {
        if ((if ((__local_c__goto_2262_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_5
    }

    '__ci_bb_9 {
        (__local_c__goto_2262_10 = ((((((((((__local_c__goto_2262_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((2 as isize) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_10 {
        if ((if ((__local_c__goto_2262_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_11 {
        goto '__ci_bb_8
    }

    '__ci_bb_12 {
        (__local_c__goto_2262_10 = ((((((((((((__local_c__goto_2262_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((3 as isize) as usize))
        goto '__ci_bb_14
    }

    '__ci_bb_13 {
        if ((if ((__local_c__goto_2262_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_14 {
        goto '__ci_bb_11
    }

    '__ci_bb_15 {
        (__local_c__goto_2262_10 = ((((((((((((((__local_c__goto_2262_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((4 as isize) as usize))
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        (__local_c__goto_2262_10 = ((((((((((((((((__local_c__goto_2262_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((5 as isize) as usize))
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        goto '__ci_bb_14
    }

    '__ci_bb_18 {
        if ((if __local_ptr__goto_2265_12 >= (*__param_cb).end_pattern: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_19 {
        (__ci_expr_logic_16 = 0)
        if ((if __local_c__goto_2262_10 >= 65: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if __local_c__goto_2262_10 <= 90: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_20 {
        ((*__param_ptrptr) = __local_ptr__goto_2265_12)
        if ((if __local_vptr__goto_2267_14 != null: 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_21 {
        goto '__ci_bb_3
    }

    '__ci_bb_22 {
        (__local_i__goto_2263_11 = ((0 as i64)))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        if ((if __local_i__goto_2263_11 < 49: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_24 {
        goto '__ci_bb_27
    }

    '__ci_bb_25 {
        (__local_i__goto_2263_11 = __local_i__goto_2263_11 + 1)
        goto '__ci_bb_23
    }

    '__ci_bb_26 {
        if ((if __local_c__goto_2262_10 != 125: 1 else: 0) != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_27 {
        if ((if __local_ptr__goto_2265_12 >= (*__param_cb).end_pattern: 1 else: 0) != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_3
    }

    '__ci_bb_29 {
        (__ci_expr_old_3 = __local_ptr__goto_2265_12)
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + 1)
        (__local_c__goto_2262_10 = (((*__ci_expr_old_3) as u32)))
        (__ci_expr_logic_4 = 0)
        if (__param_utf != 0) {
            (__ci_expr_logic_4 = (if (if __local_c__goto_2262_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        if ((if ((__local_c__goto_2262_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_31 {
        if ((if __local_c__goto_2262_10 == 95: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if __local_c__goto_2262_10 == 45: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_logic_7 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_7 = (if (if __local_c__goto_2262_10 == 32: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_8: i32 = 0

            if ((if __local_c__goto_2262_10 >= 9: 1 else: 0) != 0) {
                (__ci_expr_logic_8 = (if (if __local_c__goto_2262_10 <= 13: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_9 = (if __ci_expr_logic_8 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_32 {
        (__ci_expr_old_5 = __local_ptr__goto_2265_12)
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + 1)
        (__local_c__goto_2262_10 = ((((((((__local_c__goto_2262_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_5) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_34
    }

    '__ci_bb_33 {
        if ((if ((__local_c__goto_2262_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_34 {
        goto '__ci_bb_31
    }

    '__ci_bb_35 {
        (__local_c__goto_2262_10 = ((((((((((__local_c__goto_2262_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((2 as isize) as usize))
        goto '__ci_bb_37
    }

    '__ci_bb_36 {
        if ((if ((__local_c__goto_2262_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_37 {
        goto '__ci_bb_34
    }

    '__ci_bb_38 {
        (__local_c__goto_2262_10 = ((((((((((((__local_c__goto_2262_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((3 as isize) as usize))
        goto '__ci_bb_40
    }

    '__ci_bb_39 {
        if ((if ((__local_c__goto_2262_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_40 {
        goto '__ci_bb_37
    }

    '__ci_bb_41 {
        (__local_c__goto_2262_10 = ((((((((((((((__local_c__goto_2262_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((4 as isize) as usize))
        goto '__ci_bb_43
    }

    '__ci_bb_42 {
        (__local_c__goto_2262_10 = ((((((((((((((((__local_c__goto_2262_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr__goto_2265_12) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr__goto_2265_12[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr__goto_2265_12[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr__goto_2265_12 = __local_ptr__goto_2265_12 + ((5 as isize) as usize))
        goto '__ci_bb_43
    }

    '__ci_bb_43 {
        goto '__ci_bb_40
    }

    '__ci_bb_44 {
        goto '__ci_bb_27
    }

    '__ci_bb_45 {
        (__ci_expr_logic_11 = 0)
        (__ci_expr_logic_10 = 0)
        if ((if __local_i__goto_2263_11 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if not ((*__param_negptr) != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if __local_c__goto_2262_10 == 94: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        ((*__param_negptr) = ((1 as i32)))
        goto '__ci_bb_27
    }

    '__ci_bb_47 {
        if ((if __local_c__goto_2262_10 == 125: 1 else: 0) != 0) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_48 {
        goto '__ci_bb_26
    }

    '__ci_bb_49 {
        if ((if __local_c__goto_2262_10 < 38: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_12 = (if (if __local_c__goto_2262_10 > 122: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_50 {
        goto '__ci_bb_3
    }

    '__ci_bb_51 {
        (__ci_expr_logic_13 = 0)
        if ((if __local_c__goto_2262_10 >= 65: 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if (if __local_c__goto_2262_10 <= 90: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_52 {
        (__local_c__goto_2262_10 = (__local_c__goto_2262_10 as u32) | (32 as u32))
        goto '__ci_bb_54
    }

    '__ci_bb_53 {
        (__ci_expr_logic_15 = 0)
        if ((if __local_c__goto_2262_10 == 58: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_14 = (if (if __local_c__goto_2262_10 == 61: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            (__ci_expr_logic_15 = (if (if __local_vptr__goto_2267_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_54 {
        (__local_name__goto_2266_13[__local_i__goto_2263_11] = ((__local_c__goto_2262_10 as u8)))
        goto '__ci_bb_25
    }

    '__ci_bb_55 {
        (__local_vptr__goto_2267_14 = (&__local_name__goto_2266_13[0] as *mut u8) + ((__local_i__goto_2263_11 as isize) as usize))
        goto '__ci_bb_56
    }

    '__ci_bb_56 {
        goto '__ci_bb_54
    }

    '__ci_bb_57 {
        goto '__ci_bb_3
    }

    '__ci_bb_58 {
        (__local_name__goto_2266_13[__local_i__goto_2263_11] = ((0 as u8)))
        goto '__ci_bb_20
    }

    '__ci_bb_59 {
        (__local_name__goto_2266_13[0] = ((((__local_c__goto_2262_10 as u32) | (32 as u32)) as u8)))
        (__local_name__goto_2266_13[1] = ((0 as u8)))
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        (__ci_expr_logic_17 = 0)
        if ((if __local_c__goto_2262_10 >= 97: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if __local_c__goto_2262_10 <= 122: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_61 {
        goto '__ci_bb_20
    }

    '__ci_bb_62 {
        (__local_name__goto_2266_13[0] = ((__local_c__goto_2262_10 as u8)))
        (__local_name__goto_2266_13[1] = ((0 as u8)))
        goto '__ci_bb_64
    }

    '__ci_bb_63 {
        goto '__ci_bb_3
    }

    '__ci_bb_64 {
        goto '__ci_bb_61
    }

    '__ci_bb_65 {
        (__local_offset__goto_2374_7 = ((0 as i32)))
        ((*__local_vptr__goto_2267_14) = ((0 as u8)))
        if ((if _pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), c"\x62\x69\x64\x69\x63\x6c\x61\x73\x73".ptr) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_18 = (if (if _pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), c"\x62\x63".ptr) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_66 {
        (__local_bot__goto_2264_12 = ((0 as u64)))
        (__local_top__goto_2264_17 = _pcre2_utt_size_8)
        goto '__ci_bb_78
    }

    '__ci_bb_67 {
        (__local_offset__goto_2374_7 = ((4 as i32)))
        (__local_sname__goto_2375_15[0] = ((98 as u8)))
        (__local_sname__goto_2375_15[1] = ((105 as u8)))
        (__local_sname__goto_2375_15[2] = ((100 as u8)))
        (__local_sname__goto_2375_15[3] = ((105 as u8)))
        goto '__ci_bb_69
    }

    '__ci_bb_68 {
        if ((if _pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), c"\x73\x63\x72\x69\x70\x74".ptr) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_19 = (if (if _pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), c"\x73\x63".ptr) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_69 {
        with_memmove(((((&__local_name__goto_2266_13[0] as *mut u8) + ((__local_offset__goto_2374_7 as isize) as usize)) as *mut c_void) as *mut u8), (((__local_vptr__goto_2267_14 + ((1 as isize) as usize)) as *const c_void) as *const u8), ((((((((((&__local_name__goto_2266_13[0] as *mut u8) + ((__local_i__goto_2263_11 as isize) as usize)) as usize) -% (__local_vptr__goto_2267_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u64) *% (sizeof[u8]() as u64)) as u64) as i64))
        if ((if __local_offset__goto_2374_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_70 {
        (__local_ptscript__goto_2268_10 = ((3 as u16)))
        goto '__ci_bb_72
    }

    '__ci_bb_71 {
        if ((if _pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), c"\x73\x63\x72\x69\x70\x74\x65\x78\x74\x65\x6e\x73\x69\x6f\x6e\x73".ptr) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_20 = (if (if _pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), c"\x73\x63\x78".ptr) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_20 != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_72 {
        goto '__ci_bb_69
    }

    '__ci_bb_73 {
        (__local_ptscript__goto_2268_10 = ((4 as u16)))
        goto '__ci_bb_75
    }

    '__ci_bb_74 {
        ((*__param_errorcodeptr) = ERR47)
        return 0
    }

    '__ci_bb_75 {
        goto '__ci_bb_72
    }

    '__ci_bb_76 {
        with_memmove(((&__local_name__goto_2266_13[0] as *mut u8) as *mut u8), ((&__local_sname__goto_2375_15[0] as *mut u8) as *const u8), ((((__local_offset__goto_2374_7 as u64) *% (sizeof[u8]() as u64)) as u64) as i64))
        goto '__ci_bb_77
    }

    '__ci_bb_77 {
        goto '__ci_bb_66
    }

    '__ci_bb_78 {
        if ((if __local_bot__goto_2264_12 < __local_top__goto_2264_17: 1 else: 0) != 0) {
            goto '__ci_bb_79
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_79 {
        (__local_i__goto_2263_11 = ((((((__local_bot__goto_2264_12 as u64) +% (__local_top__goto_2264_17 as u64)) as u64) >> (1 as u32)) as i64)))
        (__local_r__goto_2415_7 = ((_pcre2_strcmp_c8_8((&__local_name__goto_2266_13[0] as *mut u8), ((&_pcre2_utt_names_8[0] as *const c_char) + ((_pcre2_utt_8[__local_i__goto_2263_11].name_offset as u32) as usize))) as i32)))
        if ((if __local_r__goto_2415_7 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_80 {
        ((*__param_errorcodeptr) = ERR47)
        return 0
    }

    '__ci_bb_81 {
        ((*__param_pdataptr) = _pcre2_utt_8[__local_i__goto_2263_11].value)
        if ((if __local_vptr__goto_2267_14 == null: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_21 = (if (if __local_ptscript__goto_2268_10 == 255: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_82 {
        if ((if __local_r__goto_2415_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_91
        }
    }

    '__ci_bb_83 {
        ((*__param_ptypeptr) = _pcre2_utt_8[__local_i__goto_2263_11].type_)
        return 1
    }

    '__ci_bb_84 {
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        if (_pcre2_utt_8[__local_i__goto_2263_11].type_ == 3) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_86 {
        goto '__ci_bb_80
    }

    '__ci_bb_87 {
        ((*__param_ptypeptr) = ((3 as u16)))
        return 1
    }

    '__ci_bb_88 {
        ((*__param_ptypeptr) = __local_ptscript__goto_2268_10)
        return 1
    }

    '__ci_bb_89 {
        if (_pcre2_utt_8[__local_i__goto_2263_11].type_ == 4) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_90 {
        (__local_bot__goto_2264_12 = (((__local_i__goto_2263_11 + 1) as u64)))
        goto '__ci_bb_92
    }

    '__ci_bb_91 {
        (__local_top__goto_2264_17 = ((__local_i__goto_2263_11 as u64)))
        goto '__ci_bb_92
    }

    '__ci_bb_92 {
        goto '__ci_bb_78
    }

    __ci_unreachable()

}

unsafe fn check_posix_syntax(__param_ptr: *const u8, __param_ptrend: *const u8, __param_endptr: *mut *const u8) -> i32 {
    var __local_ptr = __param_ptr
    var __local_terminator: u8

    var __ci_expr_old_0: *const u8 = __local_ptr

    (__local_ptr = __local_ptr + 1)

    (__local_terminator = (*__ci_expr_old_0))


    while ((if ((((__param_ptrend as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 2: 1 else: 0) != 0) {
        var __ci_expr_logic_2: i32 = 0

        if ((if (*__local_ptr) == 92: 1 else: 0) != 0) {
            var __ci_expr_logic_1: i32

            if ((if (__local_ptr[1]) == 93: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (__local_ptr[1]) == 92: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_2 != 0) {
            (__local_ptr = __local_ptr + 1)
        } else {
            var __ci_expr_logic_4: i32

            var __ci_expr_logic_3: i32 = 0

            if ((if (*__local_ptr) == 91: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if (__local_ptr[1]) == __local_terminator: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if (*__local_ptr) == 93: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                return 0
            }
            var __ci_expr_logic_5: i32 = 0

            if ((if (*__local_ptr) == __local_terminator: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if (if (__local_ptr[1]) == 93: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                ((*__param_endptr) = __local_ptr)

                return 1

            }


        }



        (__local_ptr = __local_ptr + 1)

    }

    return 0

}

unsafe fn check_posix_name(__param_ptr: *const u8, __param_len: i32) -> i32 {
    var __local_pn: *const c_char = ((&raw const posix_names[0] as *const c_char))

    var __local_yield_: i32 = ((0 as i32))

    while ((if posix_name_lengths[__local_yield_] != 0: 1 else: 0) != 0) {
        var __ci_expr_logic_0: i32 = 0

        if ((if __param_len == posix_name_lengths[__local_yield_]: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if _pcre2_strncmp_c8_8(__param_ptr, __local_pn, ((__param_len as u32) as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return __local_yield_
        }


        (__local_pn = __local_pn + ((((posix_name_lengths[__local_yield_] as i32) + 1) as isize) as usize))

        (__local_yield_ = __local_yield_ + 1)

    }

    return -1

}

unsafe fn read_name(__param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_utf: i32, __param_terminator: u32, __param_offsetptr: *mut u64, __param_nameptr: *mut *const u8, __param_namelenptr: *mut u32, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8) -> i32 {
    var __local_ptr__goto_2597_12: *const u8 = null

    var __local_is_group__goto_2598_6: i32 = 0

    var __local_is_braced__goto_2599_6: i32 = 0

    var __local_c__goto_2623_12: u32 = 0

    var __local_type___goto_2623_15: u32 = 0

    var __local_p__goto_2624_14: *const u8 = null

    var __ci_expr_old_0: *const u8 = null

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_old_4: *const u8 = null

    var __ci_expr_old_5: *const u8 = null

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    var __ci_expr_old_8: *const u8 = null

    var __ci_expr_old_9: *const u8 = null

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_15: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_ptr__goto_2597_12 = (*__param_ptrptr))
        (__ci_expr_old_0 = __local_ptr__goto_2597_12)
        (__local_ptr__goto_2597_12 = __local_ptr__goto_2597_12 + 1)
        (__local_is_group__goto_2598_6 = (((if (*__ci_expr_old_0) != 42: 1 else: 0) as i32)))
        (__local_is_braced__goto_2599_6 = (((if __param_terminator == 125: 1 else: 0) as i32)))
        if (__local_is_braced__goto_2599_6 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        if ((if __local_ptr__goto_2597_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_3 {
        (__ci_expr_logic_2 = 0)
        if ((if __local_ptr__goto_2597_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_1: i32

            if ((if (*__local_ptr__goto_2597_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (*__local_ptr__goto_2597_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_ptr__goto_2597_12 = __local_ptr__goto_2597_12 + 1)
        goto '__ci_bb_3
    }

    '__ci_bb_5 {
        goto '__ci_bb_2
    }

    '__ci_bb_6 {
        ((*__param_errorcodeptr) = (((if __local_is_group__goto_2598_6 != 0: ERR62 else: ERR60) as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_7 {
        ((*__param_nameptr) = __local_ptr__goto_2597_12)
        ((*__param_offsetptr) = ((((((__local_ptr__goto_2597_12 as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        (__ci_expr_logic_3 = 0)
        if (__param_utf != 0) {
            (__ci_expr_logic_3 = (if __local_is_group__goto_2598_6 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_8 {
        ((*__param_ptrptr) = __local_ptr__goto_2597_12)
        return 0
    }

    '__ci_bb_9 {
        (__local_p__goto_2624_14 = __local_ptr__goto_2597_12)
        (__ci_expr_old_4 = __local_p__goto_2624_14)
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + 1)
        (__local_c__goto_2623_12 = (((*__ci_expr_old_4) as u32)))
        if ((if __local_c__goto_2623_12 >= 192: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_10 {
        (__ci_expr_logic_11 = 0)
        if (__local_is_group__goto_2598_6 != 0) {
            var __ci_expr_logic_10: i32 = 0

            if ((if (*__local_ptr__goto_2597_12) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_10 = (if (if (*__local_ptr__goto_2597_12) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_11 = (if __ci_expr_logic_10 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_11 {
        if ((if ((((__local_ptr__goto_2597_12 as usize) -% ((*__param_nameptr) as usize)) as i64) / (sizeof[u8]() as i64)) > 128: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_12 {
        if ((if ((__local_c__goto_2623_12 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        (__local_type___goto_2623_15 = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_2623_12 as i32) / 128)] as i32) * 128) + ((__local_c__goto_2623_12 as i32) % 128))] as u32) as usize)).chartype as u32)))
        if ((if __local_type___goto_2623_15 == 13: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_14 {
        (__ci_expr_old_5 = __local_p__goto_2624_14)
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + 1)
        (__local_c__goto_2623_12 = ((((((((__local_c__goto_2623_12 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_5) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_16
    }

    '__ci_bb_15 {
        if ((if ((__local_c__goto_2623_12 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_16 {
        goto '__ci_bb_13
    }

    '__ci_bb_17 {
        (__local_c__goto_2623_12 = ((((((((((__local_c__goto_2623_12 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((2 as isize) as usize))
        goto '__ci_bb_19
    }

    '__ci_bb_18 {
        if ((if ((__local_c__goto_2623_12 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_19 {
        goto '__ci_bb_16
    }

    '__ci_bb_20 {
        (__local_c__goto_2623_12 = ((((((((((((__local_c__goto_2623_12 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((3 as isize) as usize))
        goto '__ci_bb_22
    }

    '__ci_bb_21 {
        if ((if ((__local_c__goto_2623_12 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_22 {
        goto '__ci_bb_19
    }

    '__ci_bb_23 {
        (__local_c__goto_2623_12 = ((((((((((((((__local_c__goto_2623_12 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((4 as isize) as usize))
        goto '__ci_bb_25
    }

    '__ci_bb_24 {
        (__local_c__goto_2623_12 = ((((((((((((((((__local_c__goto_2623_12 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((5 as isize) as usize))
        goto '__ci_bb_25
    }

    '__ci_bb_25 {
        goto '__ci_bb_22
    }

    '__ci_bb_26 {
        (__local_ptr__goto_2597_12 = __local_p__goto_2624_14)
        ((*__param_errorcodeptr) = ERR44)
        goto '__ci_bb_8
    }

    '__ci_bb_27 {
        goto '__ci_bb_28
    }

    '__ci_bb_28 {
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        (__ci_expr_logic_7 = 0)
        (__ci_expr_logic_6 = 0)
        if ((if __local_type___goto_2623_15 != 13: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if _pcre2_ucp_gentype_8[__local_type___goto_2623_15] != 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_logic_7 = (if (if __local_c__goto_2623_12 != 95: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_28
    }

    '__ci_bb_31 {
        goto '__ci_bb_11
    }

    '__ci_bb_32 {
        goto '__ci_bb_31
    }

    '__ci_bb_33 {
        (__local_ptr__goto_2597_12 = __local_p__goto_2624_14)
        if ((if __local_p__goto_2624_14 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_34 {
        goto '__ci_bb_31
    }

    '__ci_bb_35 {
        (__ci_expr_old_8 = __local_p__goto_2624_14)
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + 1)
        (__local_c__goto_2623_12 = (((*__ci_expr_old_8) as u32)))
        if ((if __local_c__goto_2623_12 >= 192: 1 else: 0) != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_36 {
        if ((if ((__local_c__goto_2623_12 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_37 {
        (__local_type___goto_2623_15 = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_2623_12 as i32) / 128)] as i32) * 128) + ((__local_c__goto_2623_12 as i32) % 128))] as u32) as usize)).chartype as u32)))
        goto '__ci_bb_30
    }

    '__ci_bb_38 {
        (__ci_expr_old_9 = __local_p__goto_2624_14)
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + 1)
        (__local_c__goto_2623_12 = ((((((((__local_c__goto_2623_12 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_9) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_40
    }

    '__ci_bb_39 {
        if ((if ((__local_c__goto_2623_12 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_40 {
        goto '__ci_bb_37
    }

    '__ci_bb_41 {
        (__local_c__goto_2623_12 = ((((((((((__local_c__goto_2623_12 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((2 as isize) as usize))
        goto '__ci_bb_43
    }

    '__ci_bb_42 {
        if ((if ((__local_c__goto_2623_12 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_43 {
        goto '__ci_bb_40
    }

    '__ci_bb_44 {
        (__local_c__goto_2623_12 = ((((((((((((__local_c__goto_2623_12 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((3 as isize) as usize))
        goto '__ci_bb_46
    }

    '__ci_bb_45 {
        if ((if ((__local_c__goto_2623_12 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_46 {
        goto '__ci_bb_43
    }

    '__ci_bb_47 {
        (__local_c__goto_2623_12 = ((((((((((((((__local_c__goto_2623_12 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((4 as isize) as usize))
        goto '__ci_bb_49
    }

    '__ci_bb_48 {
        (__local_c__goto_2623_12 = ((((((((((((((((__local_c__goto_2623_12 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_p__goto_2624_14) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_p__goto_2624_14[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_p__goto_2624_14[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_p__goto_2624_14 = __local_p__goto_2624_14 + ((5 as isize) as usize))
        goto '__ci_bb_49
    }

    '__ci_bb_49 {
        goto '__ci_bb_46
    }

    '__ci_bb_50 {
        (__local_ptr__goto_2597_12 = __local_ptr__goto_2597_12 + 1)
        ((*__param_errorcodeptr) = ERR44)
        goto '__ci_bb_8
    }

    '__ci_bb_51 {
        goto '__ci_bb_52
    }

    '__ci_bb_52 {
        (__ci_expr_logic_13 = 0)
        (__ci_expr_logic_12 = 0)
        if ((if __local_ptr__goto_2597_12 < __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if 1 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_logic_13 = (if (if ((((*__param_cb).ctypes[(*__local_ptr__goto_2597_12)]) as i32) & (16 as i32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_53 {
        (__local_ptr__goto_2597_12 = __local_ptr__goto_2597_12 + 1)
        goto '__ci_bb_52
    }

    '__ci_bb_54 {
        goto '__ci_bb_11
    }

    '__ci_bb_55 {
        ((*__param_errorcodeptr) = ERR48)
        goto '__ci_bb_8
    }

    '__ci_bb_56 {
        ((*__param_namelenptr) = ((((((__local_ptr__goto_2597_12 as usize) -% ((*__param_nameptr) as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))
        if (__local_is_group__goto_2598_6 != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_57 {
        if ((if __local_ptr__goto_2597_12 == (*__param_nameptr): 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_58 {
        ((*__param_ptrptr) = __local_ptr__goto_2597_12)
        return 1
    }

    '__ci_bb_59 {
        ((*__param_errorcodeptr) = ERR62)
        goto '__ci_bb_8
    }

    '__ci_bb_60 {
        if (__local_is_braced__goto_2599_6 != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_61 {
        goto '__ci_bb_63
    }

    '__ci_bb_62 {
        if ((if __param_terminator != 0: 1 else: 0) != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_63 {
        (__ci_expr_logic_15 = 0)
        if ((if __local_ptr__goto_2597_12 < __param_ptrend: 1 else: 0) != 0) {
            var __ci_expr_logic_14: i32

            if ((if (*__local_ptr__goto_2597_12) == 32: 1 else: 0) != 0) {
                (__ci_expr_logic_14 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_14 = (if (if (*__local_ptr__goto_2597_12) == 9: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_15 = (if __ci_expr_logic_14 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_65
        }
    }

    '__ci_bb_64 {
        (__local_ptr__goto_2597_12 = __local_ptr__goto_2597_12 + 1)
        goto '__ci_bb_63
    }

    '__ci_bb_65 {
        goto '__ci_bb_62
    }

    '__ci_bb_66 {
        if ((if __local_ptr__goto_2597_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_16 = (if (if (*__local_ptr__goto_2597_12) != ((__param_terminator as u8)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_67 {
        goto '__ci_bb_58
    }

    '__ci_bb_68 {
        ((*__param_errorcodeptr) = ERR42)
        goto '__ci_bb_8
    }

    '__ci_bb_69 {
        (__local_ptr__goto_2597_12 = __local_ptr__goto_2597_12 + 1)
        goto '__ci_bb_67
    }

    __ci_unreachable()

}

unsafe fn parse_capture_list(__param_ptrptr: *mut *const u8, __param_ptrend: *const u8, __param_utf: i32, __param_parsed_pattern: *mut u32, __param_offset: u64, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8) -> *mut u32 {
    var __local_parsed_pattern = __param_parsed_pattern
    var __local_offset = __param_offset
    var __local_next_offset__goto_2736_12: u64 = 0

    var __local_ptr__goto_2737_12: *const u8 = null

    var __local_name__goto_2738_12: *const u8 = null

    var __local_terminator__goto_2739_13: u8 = 0

    var __local_meta__goto_2740_10: u32 = 0

    var __local_namelen__goto_2740_16: u32 = 0

    var __local_i__goto_2741_5: i32 = 0

    var __ci_expr_logic_0: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_old_2: *mut u32 = null

    var __ci_expr_old_3: *mut u32 = null

    var __ci_expr_old_4: *mut u32 = null

    var __ci_expr_old_5: *mut u32 = null

    var __ci_expr_old_6: *mut u32 = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_ptr__goto_2737_12 = (*__param_ptrptr))
        if ((if __local_ptr__goto_2737_12 >= __param_ptrend: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (*__local_ptr__goto_2737_12) != 40: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        ((*__param_errorcodeptr) = ERR118)
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        goto '__ci_bb_4
    }

    '__ci_bb_3 {
        ((*__param_ptrptr) = __local_ptr__goto_2737_12)
        return ((null as *mut u32))
    }

    '__ci_bb_4 {
        goto '__ci_bb_5
    }

    '__ci_bb_5 {
        (__local_ptr__goto_2737_12 = __local_ptr__goto_2737_12 + 1)
        (__local_next_offset__goto_2736_12 = ((((((__local_ptr__goto_2737_12 as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        if ((if __local_ptr__goto_2737_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_6 {
        goto '__ci_bb_4
    }

    '__ci_bb_7 {
        ((*__param_ptrptr) = __local_ptr__goto_2737_12 + ((1 as isize) as usize))
        return __local_parsed_pattern
    }

    '__ci_bb_8 {
        ((*__param_errorcodeptr) = ERR117)
        goto '__ci_bb_3
    }

    '__ci_bb_9 {
        if (read_number((&raw mut __local_ptr__goto_2737_12 as *mut *const u8), __param_ptrend, ((*__param_cb).bracount as i32), (65535 as u32), (161 as u32), (&raw mut __local_i__goto_2741_5 as *mut i32), __param_errorcodeptr) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_10 {
        goto '__ci_bb_13
    }

    '__ci_bb_11 {
        if ((if (*__param_errorcodeptr) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_12 {
        goto '__ci_bb_29
    }

    '__ci_bb_13 {
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        if (0 != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_15 {
        if ((if __local_i__goto_2741_5 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        ((*__param_errorcodeptr) = ERR15)
        goto '__ci_bb_3
    }

    '__ci_bb_17 {
        (__local_meta__goto_2740_10 = ((2149122048 as u32)))
        (__local_namelen__goto_2740_16 = ((__local_i__goto_2741_5 as u32)))
        goto '__ci_bb_12
    }

    '__ci_bb_18 {
        goto '__ci_bb_3
    }

    '__ci_bb_19 {
        if ((if (*__local_ptr__goto_2737_12) == 60: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_20 {
        goto '__ci_bb_12
    }

    '__ci_bb_21 {
        (__local_terminator__goto_2739_13 = ((62 as u8)))
        goto '__ci_bb_23
    }

    '__ci_bb_22 {
        if ((if (*__local_ptr__goto_2737_12) == 39: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        if ((if not (read_name((&raw mut __local_ptr__goto_2737_12 as *mut *const u8), __param_ptrend, __param_utf, (__local_terminator__goto_2739_13 as u32), (&raw mut __local_next_offset__goto_2736_12 as *mut u64), (&raw mut __local_name__goto_2738_12 as *mut *const u8), (&raw mut __local_namelen__goto_2740_16 as *mut u32), __param_errorcodeptr, __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_24 {
        (__local_terminator__goto_2739_13 = ((39 as u8)))
        goto '__ci_bb_26
    }

    '__ci_bb_25 {
        ((*__param_errorcodeptr) = ERR117)
        goto '__ci_bb_3
    }

    '__ci_bb_26 {
        goto '__ci_bb_23
    }

    '__ci_bb_27 {
        goto '__ci_bb_3
    }

    '__ci_bb_28 {
        (__local_meta__goto_2740_10 = ((2149056512 as u32)))
        goto '__ci_bb_20
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
        if ((if __local_offset == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if ((__local_next_offset__goto_2736_12 as u64) -% (__local_offset as u64)) >= 65536: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_32 {
        (__ci_expr_old_2 = __local_parsed_pattern)
        (__local_parsed_pattern = __local_parsed_pattern + 1)
        ((*__ci_expr_old_2) = ((2148925440 as u32)))
        (__ci_expr_old_3 = __local_parsed_pattern)
        (__local_parsed_pattern = __local_parsed_pattern + 1)
        ((*__ci_expr_old_3) = ((((__local_next_offset__goto_2736_12 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_4 = __local_parsed_pattern)
        (__local_parsed_pattern = __local_parsed_pattern + 1)
        ((*__ci_expr_old_4) = ((((__local_next_offset__goto_2736_12 as u64) & (4294967295 as u64)) as u32)))
        (__local_offset = __local_next_offset__goto_2736_12)
        goto '__ci_bb_33
    }

    '__ci_bb_33 {
        (__ci_expr_old_5 = __local_parsed_pattern)
        (__local_parsed_pattern = __local_parsed_pattern + 1)
        ((*__ci_expr_old_5) = ((((__local_meta__goto_2740_10 as u32) | (((__local_next_offset__goto_2736_12 as u64) -% (__local_offset as u64)) as u32)) as u32)))
        (__ci_expr_old_6 = __local_parsed_pattern)
        (__local_parsed_pattern = __local_parsed_pattern + 1)
        ((*__ci_expr_old_6) = __local_namelen__goto_2740_16)
        (__local_offset = __local_next_offset__goto_2736_12)
        if ((if __local_ptr__goto_2737_12 >= __param_ptrend: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_34 {
        goto '__ci_bb_36
    }

    '__ci_bb_35 {
        if ((if (*__local_ptr__goto_2737_12) == 41: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_36 {
        ((*__param_errorcodeptr) = ERR14)
        goto '__ci_bb_3
    }

    '__ci_bb_37 {
        goto '__ci_bb_7
    }

    '__ci_bb_38 {
        if ((if (*__local_ptr__goto_2737_12) != 44: 1 else: 0) != 0) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_39 {
        ((*__param_errorcodeptr) = ERR24)
        goto '__ci_bb_3
    }

    '__ci_bb_40 {
        goto '__ci_bb_6
    }

    __ci_unreachable()

}

unsafe fn manage_callouts(__param_ptr: *const u8, __param_pcalloutptr: *mut *mut u32, __param_auto_callout: i32, __param_parsed_pattern: *mut u32, __param_cb: *mut compile_block_8) -> *mut u32 {
    var __local_parsed_pattern = __param_parsed_pattern
    var __local_previous_callout: *mut u32 = (*__param_pcalloutptr)

    if ((if __local_previous_callout != null: 1 else: 0) != 0) {
        ((__local_previous_callout[2]) = ((((((((__param_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64) -% ((__local_previous_callout[1]) as u64)) as u32)))
    }

    if ((if not (__param_auto_callout != 0): 1 else: 0) != 0) {
        (__local_previous_callout = ((null as *mut u32)))
    } else {
        var __ci_expr_logic_1: i32

        var __ci_expr_logic_0: i32

        if ((if __local_previous_callout == null: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_previous_callout != (__local_parsed_pattern - ((4 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if (__local_previous_callout[3]) != 255: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_previous_callout = __local_parsed_pattern)

            (__local_parsed_pattern = __local_parsed_pattern + ((4 as isize) as usize))

            ((__local_previous_callout[0]) = ((2147876864 as u32)))

            ((__local_previous_callout[2]) = ((0 as u32)))

            ((__local_previous_callout[3]) = ((255 as u32)))

        }


        ((__local_previous_callout[1]) = ((((((__param_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))

    }

    ((*__param_pcalloutptr) = __local_previous_callout)

    return __local_parsed_pattern

}

unsafe fn handle_escdsw(__param_escape: i32, __param_parsed_pattern: *mut u32, __param_options: u32, __param_xoptions: u32) -> *mut u32 {
    var __local_parsed_pattern = __param_parsed_pattern
    var __local_ascii_option: u32 = ((0 as u32))

    var __local_prop: u32 = ((16 as u32))

    while true {
        match __param_escape {
            6 => {
                (__local_prop = ((15 as u32)))

                (__local_ascii_option = ((256 as u32)))

            },
            7 => {
                (__local_ascii_option = ((256 as u32)))
            },
            8 => {
                (__local_prop = ((15 as u32)))

                (__local_ascii_option = ((512 as u32)))

            },
            9 => {
                (__local_ascii_option = ((512 as u32)))
            },
            10 => {
                (__local_prop = ((15 as u32)))

                (__local_ascii_option = ((1024 as u32)))

            },
            11 => {
                (__local_ascii_option = ((1024 as u32)))
            },
        }

        break

    }

    var __ci_expr_logic_1: i32

    if ((if ((__param_options as u32) & (131072 as u32)) == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if ((__param_xoptions as u32) & (__local_ascii_option as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        var __ci_expr_old_2: *mut u32 = __local_parsed_pattern

        (__local_parsed_pattern = __local_parsed_pattern + 1)

        ((*__ci_expr_old_2) = ((((2149318656 as u32) +% (__param_escape as u32)) as u32)))


    } else {
        var __ci_expr_old_3: *mut u32 = __local_parsed_pattern

        (__local_parsed_pattern = __local_parsed_pattern + 1)

        ((*__ci_expr_old_3) = ((((2149318656 as u32) +% (__local_prop as u32)) as u32)))


        while true {
            match __param_escape {
                7 => {
                    var __ci_expr_old_4: *mut u32 = __local_parsed_pattern

                    (__local_parsed_pattern = __local_parsed_pattern + 1)

                    ((*__ci_expr_old_4) = ((131085 as u32)))

                },
                6 => {
                    var __ci_expr_old_4: *mut u32 = __local_parsed_pattern

                    (__local_parsed_pattern = __local_parsed_pattern + 1)

                    ((*__ci_expr_old_4) = ((131085 as u32)))

                },
                9 => {
                    var __ci_expr_old_5: *mut u32 = __local_parsed_pattern

                    (__local_parsed_pattern = __local_parsed_pattern + 1)

                    ((*__ci_expr_old_5) = ((393216 as u32)))

                },
                8 => {
                    var __ci_expr_old_5: *mut u32 = __local_parsed_pattern

                    (__local_parsed_pattern = __local_parsed_pattern + 1)

                    ((*__ci_expr_old_5) = ((393216 as u32)))

                },
                11 => {
                    var __ci_expr_old_6: *mut u32 = __local_parsed_pattern

                    (__local_parsed_pattern = __local_parsed_pattern + 1)

                    ((*__ci_expr_old_6) = ((524288 as u32)))

                },
                10 => {
                    var __ci_expr_old_6: *mut u32 = __local_parsed_pattern

                    (__local_parsed_pattern = __local_parsed_pattern + 1)

                    ((*__ci_expr_old_6) = ((524288 as u32)))

                },
            }

            break

        }

    }


    return __local_parsed_pattern

}

unsafe fn max_parsed_pattern(__param_ptr: *const u8, __param_ptrend: *const u8, __param_utf: i32, __param_options: u32) -> i64 {
    var __local_big32count: u64 = ((0 as u64))

    var __local_parsed_size_needed: i64


    (__local_parsed_size_needed = ((((((((__param_ptrend as usize) -% (__param_ptr as usize)) as i64) / (sizeof[u8]() as i64)) as u64) +% (__local_big32count as u64)) as i64)))

    if ((if ((__param_options as u32) & (4 as u32)) != 0: 1 else: 0) != 0) {
        (__local_parsed_size_needed = __local_parsed_size_needed + (((((__param_ptrend as usize) -% (__param_ptr as usize)) as i64) / (sizeof[u8]() as i64)) * 4))
    }

    return __local_parsed_size_needed

}

unsafe fn parse_regex(__param_ptr: *const u8, __param_options: u32, __param_xoptions: u32, __param_has_lookbehind: *mut i32, __param_cb: *mut compile_block_8) -> i32 {
    var __local_ptr = __param_ptr
    var __local_options = __param_options
    var __local_xoptions = __param_xoptions
    var __local_c__goto_3115_10: u32 = 0

    var __local_delimiter__goto_3116_10: u32 = 0

    var __local_namelen__goto_3117_10: u32 = 0

    var __local_class_range_state__goto_3118_10: u32 = 0

    var __local_class_op_state__goto_3119_10: u32 = 0

    var __local_class_mode_state__goto_3120_10: u32 = 0

    var __local_class_start__goto_3121_11: *mut u32 = null

    var __local_verblengthptr__goto_3122_11: *mut u32 = null

    var __local_verbstartptr__goto_3123_11: *mut u32 = null

    var __local_previous_callout__goto_3124_11: *mut u32 = null

    var __local_parsed_pattern__goto_3125_11: *mut u32 = null

    var __local_parsed_pattern_end__goto_3126_11: *mut u32 = null

    var __local_this_parsed_item__goto_3127_11: *mut u32 = null

    var __local_prev_parsed_item__goto_3128_11: *mut u32 = null

    var __local_meta_quantifier__goto_3129_10: u32 = 0

    var __local_add_after_mark__goto_3130_10: u32 = 0

    var __local_nest_depth__goto_3131_10: u16 = 0

    var __local_class_depth_m1__goto_3132_9: i16 = 0

    var __local_class_maxdepth_m1__goto_3133_9: i16 = 0

    var __local_hash__goto_3134_10: u16 = 0

    var __local_after_manual_callout__goto_3135_5: i32 = 0

    var __local_expect_cond_assert__goto_3136_5: i32 = 0

    var __local_errorcode__goto_3137_5: i32 = 0

    var __local_escape__goto_3138_5: i32 = 0

    var __local_i__goto_3139_5: i32 = 0

    var __local_inescq__goto_3140_6: i32 = 0

    var __local_inverbname__goto_3141_6: i32 = 0

    var __local_utf__goto_3142_6: i32 = 0

    var __local_auto_callout__goto_3143_6: i32 = 0

    var __local_is_dupname__goto_3144_6: i32 = 0

    var __local_negate_class__goto_3145_6: i32 = 0

    var __local_okquantifier__goto_3146_6: i32 = 0

    var __local_thisptr__goto_3147_12: *const u8 = null

    var __local_name__goto_3148_12: *const u8 = null

    var __local_ptrend__goto_3149_12: *const u8 = null

    var __local_verbnamestart__goto_3150_12: *const u8 = null

    var __local_class_range_forbid_ptr__goto_3151_12: *const u8 = null

    var __local_ng__goto_3152_14: *mut named_group_8 = null

    var __local_top_nest__goto_3153_12: *mut nest_save = null

    var __local_end_nests__goto_3153_23: *mut nest_save = null

    var __local_prev_expect_cond_assert__goto_3228_7: i32 = 0

    var __local_min_repeat__goto_3229_12: u32 = 0

    var __local_max_repeat__goto_3229_28: u32 = 0

    var __local_set__goto_3230_12: u32 = 0

    var __local_unset__goto_3230_17: u32 = 0

    var __local_optset__goto_3230_25: *mut u32 = null

    var __local_xset__goto_3231_12: u32 = 0

    var __local_xunset__goto_3231_18: u32 = 0

    var __local_xoptset__goto_3231_27: *mut u32 = null

    var __local_terminator__goto_3232_12: u32 = 0

    var __local_prev_meta_quantifier__goto_3233_12: u32 = 0

    var __local_prev_okquantifier__goto_3234_8: i32 = 0

    var __local_tempptr__goto_3235_14: *const u8 = null

    var __local_offset__goto_3236_14: u64 = 0

    var __local_verbnamelength__goto_3348_16: u64 = 0

    var __local_ok__goto_3519_10: i32 = 0

    var __local_negated__goto_3722_14: i32 = 0

    var __local_ptype__goto_3723_18: u16 = 0

    var __local_pdata__goto_3723_29: u16 = 0

    var __local_p__goto_3759_20: *const u8 = null

    var __local_p__goto_3862_17: *mut u32 = null

    var __local_char_is_literal__goto_3974_12: i32 = 0

    var __local_posix_negate__goto_4021_14: i32 = 0

    var __local_posix_class__goto_4022_13: i32 = 0

    var __local_ptype__goto_4104_15: i32 = 0

    var __local_pvalue__goto_4105_15: i32 = 0

    var __local_start_c__goto_4138_18: u32 = 0

    var __local_new_class_mode_state__goto_4139_18: u32 = 0

    var __local_negated__goto_4538_18: i32 = 0

    var __local_ptype__goto_4539_22: u16 = 0

    var __local_pdata__goto_4539_33: u16 = 0

    var __local_vn__goto_4725_19: *const c_char = null

    var __local_meta__goto_4760_18: u32 = 0

    var __local_hyphenok__goto_5025_14: i32 = 0

    var __local_oldoptions__goto_5026_18: u32 = 0

    var __local_oldxoptions__goto_5027_18: u32 = 0

    var __local_calloutlength__goto_5328_20: u64 = 0

    var __local_startptr__goto_5329_20: *const u8 = null

    var __local_n__goto_5377_13: i32 = 0

    var __local_ge__goto_5472_18: u32 = 0

    var __local_major__goto_5473_13: i32 = 0

    var __local_minor__goto_5474_13: i32 = 0

    var __local_was_r_ampersand__goto_5528_14: i32 = 0

    var __local_newsize__goto_5771_18: u32 = 0

    var __local_newspace__goto_5772_22: *mut named_group_8 = null

    var __ci_expr_old_0: *mut u32 = null

    var __ci_expr_old_1: *mut u32 = null

    var __ci_expr_old_2: *mut u32 = null

    var __ci_expr_old_3: *mut u32 = null

    var __ci_expr_old_4: *const u8 = null

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_old_6: *const u8 = null

    var __ci_expr_old_7: *mut u32 = null

    var __ci_expr_old_8: *const u8 = null

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_old_10: *const u8 = null

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_old_13: *mut u32 = null

    var __ci_expr_old_14: i32 = 0

    var __ci_expr_old_15: *mut u32 = null

    var __ci_expr_logic_23: i32 = 0

    var __ci_expr_old_24: *mut u32 = null

    var __ci_expr_old_25: *mut u32 = null

    var __ci_expr_old_26: *mut u32 = null

    var __ci_expr_old_27: *mut u32 = null

    var __ci_expr_old_28: *mut u32 = null

    var __ci_expr_logic_29: i32 = 0

    var __ci_expr_logic_30: i32 = 0

    var __ci_expr_logic_34: i32 = 0

    var __ci_expr_logic_31: i32 = 0

    var __ci_expr_logic_35: i32 = 0

    var __ci_expr_logic_37: i32 = 0

    var __ci_expr_logic_36: i32 = 0

    var __ci_expr_ternary_42: i32 = 0

    var __ci_expr_logic_43: i32 = 0

    var __ci_expr_logic_46: i32 = 0

    var __ci_expr_logic_45: i32 = 0

    var __ci_expr_logic_44: i32 = 0

    var __ci_expr_logic_47: i32 = 0

    var __ci_expr_logic_51: i32 = 0

    var __ci_expr_logic_49: i32 = 0

    var __ci_expr_logic_48: i32 = 0

    var __ci_expr_old_52: i32 = 0

    var __ci_expr_logic_55: i32 = 0

    var __ci_expr_logic_53: i32 = 0

    var __ci_expr_logic_56: i32 = 0

    var __ci_expr_logic_57: i32 = 0

    var __ci_expr_logic_59: i32 = 0

    var __ci_expr_old_60: *mut u32 = null

    var __ci_expr_old_61: *const u8 = null

    var __ci_expr_logic_62: i32 = 0

    var __ci_expr_old_63: *const u8 = null

    var __ci_expr_old_64: *mut u32 = null

    var __ci_expr_old_65: *mut u32 = null

    var __ci_expr_old_66: *mut u32 = null

    var __ci_expr_old_67: *mut u32 = null

    var __ci_expr_old_68: *mut u32 = null

    var __ci_expr_old_69: *mut u32 = null

    var __ci_expr_old_70: *mut u32 = null

    var __ci_expr_old_71: *mut u32 = null

    var __ci_expr_old_72: *mut u32 = null

    var __ci_expr_old_73: *mut u32 = null

    var __ci_expr_old_74: *mut u32 = null

    var __ci_expr_logic_77: i32 = 0

    var __ci_expr_logic_78: i32 = 0

    var __ci_expr_logic_79: i32 = 0

    var __ci_expr_old_80: *mut u32 = null

    var __ci_expr_ternary_82: u32 = 0

    var __ci_expr_logic_81: i32 = 0

    var __ci_expr_old_83: *mut u32 = null

    var __ci_expr_old_84: *mut u32 = null

    var __ci_expr_old_85: *mut u32 = null

    var __ci_expr_old_86: *mut u32 = null

    var __ci_expr_old_87: *mut u32 = null

    var __ci_expr_old_88: *mut u32 = null

    var __ci_expr_old_89: *mut u32 = null

    var __ci_expr_old_90: *mut u32 = null

    var __ci_expr_old_91: *mut u32 = null

    var __ci_expr_old_92: *mut u32 = null

    var __ci_expr_logic_94: i32 = 0

    var __ci_expr_old_95: *mut u32 = null

    var __ci_expr_old_96: *mut u32 = null

    var __ci_expr_old_97: *mut u32 = null

    var __ci_expr_old_98: *mut u32 = null

    var __ci_expr_old_99: *mut u32 = null

    var __ci_expr_old_100: *mut u32 = null

    var __ci_expr_old_101: *mut u32 = null

    var __ci_expr_old_102: *mut u32 = null

    var __ci_expr_old_103: *mut u32 = null

    var __ci_expr_logic_107: i32 = 0

    var __ci_expr_logic_106: i32 = 0

    var __ci_expr_ternary_109: i32 = 0

    var __ci_expr_old_108: *const u8 = null

    var __ci_expr_logic_111: i32 = 0

    var __ci_expr_logic_110: i32 = 0

    var __ci_expr_logic_114: i32 = 0

    var __ci_expr_logic_112: i32 = 0

    var __ci_expr_logic_120: i32 = 0

    var __ci_expr_logic_119: i32 = 0

    var __ci_expr_logic_116: i32 = 0

    var __ci_expr_logic_115: i32 = 0

    var __ci_expr_logic_121: i32 = 0

    var __ci_expr_logic_125: i32 = 0

    var __ci_expr_logic_122: i32 = 0

    var __ci_expr_old_126: *mut u32 = null

    var __ci_expr_old_127: *mut u32 = null

    var __ci_expr_old_128: *mut u32 = null

    var __ci_expr_old_129: *mut u32 = null

    var __ci_expr_old_130: *mut u32 = null

    var __ci_expr_logic_135: i32 = 0

    var __ci_expr_logic_133: i32 = 0

    var __ci_expr_logic_137: i32 = 0

    var __ci_expr_logic_136: i32 = 0

    var __ci_expr_logic_138: i32 = 0

    var __ci_expr_old_139: *const u8 = null

    var __ci_expr_logic_140: i32 = 0

    var __ci_expr_old_141: *const u8 = null

    var __ci_expr_logic_142: i32 = 0

    var __ci_expr_logic_143: i32 = 0

    var __ci_expr_logic_146: i32 = 0

    var __ci_expr_logic_144: i32 = 0

    var __ci_expr_logic_147: i32 = 0

    var __ci_expr_logic_149: i32 = 0

    var __ci_expr_logic_148: i32 = 0

    var __ci_expr_old_150: *mut u32 = null

    var __ci_expr_old_151: *mut u32 = null

    var __ci_expr_logic_152: i32 = 0

    var __ci_expr_old_153: *mut u32 = null

    var __ci_expr_logic_155: i32 = 0

    var __ci_expr_logic_156: i32 = 0

    var __ci_expr_logic_157: i32 = 0

    var __ci_expr_logic_158: i32 = 0

    var __ci_expr_old_159: *mut u32 = null

    var __ci_expr_logic_160: i32 = 0

    var __ci_expr_logic_165: i32 = 0

    var __ci_expr_old_166: *mut u32 = null

    var __ci_expr_logic_167: i32 = 0

    var __ci_expr_old_168: *mut u32 = null

    var __ci_expr_logic_174: i32 = 0

    var __ci_expr_logic_173: i32 = 0

    var __ci_expr_logic_172: i32 = 0

    var __ci_expr_logic_175: i32 = 0

    var __ci_expr_logic_176: i32 = 0

    var __ci_expr_logic_177: i32 = 0

    var __ci_expr_old_178: *mut u32 = null

    var __ci_expr_logic_179: i32 = 0

    var __ci_expr_old_180: *const u8 = null

    var __ci_expr_logic_181: i32 = 0

    var __ci_expr_old_182: *const u8 = null

    var __ci_expr_old_183: *mut u32 = null

    var __ci_expr_logic_187: i32 = 0

    var __ci_expr_logic_184: i32 = 0

    var __ci_expr_old_188: *mut u32 = null

    var __ci_expr_old_189: *mut u32 = null

    var __ci_expr_logic_190: i32 = 0

    var __ci_expr_logic_191: i32 = 0

    var __ci_expr_old_192: *mut u32 = null

    var __ci_expr_logic_193: i32 = 0

    var __ci_expr_old_194: *mut u32 = null

    var __ci_expr_logic_195: i32 = 0

    var __ci_expr_logic_196: i32 = 0

    var __ci_expr_old_197: *mut u32 = null

    var __ci_expr_old_198: *mut u32 = null

    var __ci_expr_logic_199: i32 = 0

    var __ci_expr_logic_201: i32 = 0

    var __ci_expr_logic_200: i32 = 0

    var __ci_expr_old_202: *const u8 = null

    var __ci_expr_logic_203: i32 = 0

    var __ci_expr_old_204: *const u8 = null

    var __ci_expr_old_205: *mut u32 = null

    var __ci_expr_old_206: *mut u32 = null

    var __ci_expr_logic_207: i32 = 0

    var __ci_expr_logic_208: i32 = 0

    var __ci_expr_logic_209: i32 = 0

    var __ci_expr_logic_211: i32 = 0

    var __ci_expr_old_212: *mut u32 = null

    var __ci_expr_old_213: *mut u32 = null

    var __ci_expr_old_214: *mut u32 = null

    var __ci_expr_old_215: *mut u32 = null

    var __ci_expr_logic_217: i32 = 0

    var __ci_expr_logic_218: i32 = 0

    var __ci_expr_logic_220: i32 = 0

    var __ci_expr_logic_219: i32 = 0

    var __ci_expr_logic_221: i32 = 0

    var __ci_expr_old_222: *const u8 = null

    var __ci_expr_old_223: *mut u32 = null

    var __ci_expr_old_224: *mut u32 = null

    var __ci_expr_old_225: *mut u32 = null

    var __ci_expr_old_226: *mut u32 = null

    var __ci_expr_logic_229: i32 = 0

    var __ci_expr_logic_227: i32 = 0

    var __ci_expr_old_230: *mut u32 = null

    var __ci_expr_logic_231: i32 = 0

    var __ci_expr_logic_233: i32 = 0

    var __ci_expr_logic_232: i32 = 0

    var __ci_expr_old_234: *const u8 = null

    var __ci_expr_switch_235: i32 = 0

    var __ci_expr_logic_236: i32 = 0

    var __ci_expr_logic_237: i32 = 0

    var __ci_expr_old_238: *const u8 = null

    var __ci_expr_logic_239: i32 = 0

    var __ci_expr_old_240: *mut u32 = null

    var __ci_expr_logic_241: i32 = 0

    var __ci_expr_old_242: *mut u32 = null

    var __ci_expr_old_243: *mut u32 = null

    var __ci_expr_old_244: *mut u32 = null

    var __ci_expr_old_245: *mut u32 = null

    var __ci_expr_old_246: *mut u32 = null

    var __ci_expr_old_247: *mut u32 = null

    var __ci_expr_old_248: *mut u32 = null

    var __ci_expr_logic_250: i32 = 0

    var __ci_expr_logic_251: i32 = 0

    var __ci_expr_ternary_253: i32 = 0

    var __ci_expr_logic_252: i32 = 0

    var __ci_expr_old_254: *mut u32 = null

    var __ci_expr_old_255: *mut u32 = null

    var __ci_expr_old_256: *mut u32 = null

    var __ci_expr_old_257: *mut u32 = null

    var __ci_expr_old_258: *mut u32 = null

    var __ci_expr_logic_259: i32 = 0

    var __ci_expr_logic_260: i32 = 0

    var __ci_expr_logic_263: i32 = 0

    var __ci_expr_logic_262: i32 = 0

    var __ci_expr_logic_261: i32 = 0

    var __ci_expr_logic_265: i32 = 0

    var __ci_expr_logic_267: i32 = 0

    var __ci_expr_old_268: *mut u32 = null

    var __ci_expr_old_269: *mut u32 = null

    var __ci_expr_old_270: *mut u32 = null

    var __ci_expr_logic_272: i32 = 0

    var __ci_expr_old_273: *const u8 = null

    var __ci_expr_old_274: *mut u32 = null

    var __ci_expr_logic_275: i32 = 0

    var __ci_expr_logic_276: i32 = 0

    var __ci_expr_old_277: *mut u32 = null

    var __ci_expr_old_278: *mut u32 = null

    var __ci_expr_old_279: *mut u32 = null

    var __ci_expr_old_280: *mut u32 = null

    var __ci_expr_old_281: *mut u32 = null

    var __ci_expr_logic_283: i32 = 0

    var __ci_expr_logic_282: i32 = 0

    var __ci_expr_logic_285: i32 = 0

    var __ci_expr_logic_286: i32 = 0

    var __ci_expr_logic_288: i32 = 0

    var __ci_expr_logic_289: i32 = 0

    var __ci_expr_old_290: *mut u32 = null

    var __ci_expr_old_291: *mut u32 = null

    var __ci_expr_old_292: *mut u32 = null

    var __ci_expr_old_293: *mut u32 = null

    var __ci_expr_logic_295: i32 = 0

    var __ci_expr_logic_294: i32 = 0

    var __ci_expr_logic_296: i32 = 0

    var __ci_expr_logic_297: i32 = 0

    var __ci_expr_ternary_299: u32 = 0

    var __ci_expr_logic_298: i32 = 0

    var __ci_expr_old_300: *mut u32 = null

    var __ci_expr_old_301: *mut u32 = null

    var __ci_expr_old_302: *mut u32 = null

    var __ci_expr_old_303: *mut u32 = null

    var __ci_expr_logic_304: i32 = 0

    var __ci_expr_old_305: *mut u32 = null

    var __ci_expr_old_306: *mut u32 = null

    var __ci_expr_old_307: *mut u32 = null

    var __ci_expr_old_308: *mut u32 = null

    var __ci_expr_logic_311: i32 = 0

    var __ci_expr_old_312: *mut u32 = null

    var __ci_expr_old_313: *mut u32 = null

    var __ci_expr_old_314: *mut u32 = null

    var __ci_expr_old_315: *mut u32 = null

    var __ci_expr_logic_317: i32 = 0

    var __ci_expr_logic_316: i32 = 0

    var __ci_expr_logic_318: i32 = 0

    var __ci_expr_old_319: *const u8 = null

    var __ci_expr_logic_321: i32 = 0

    var __ci_expr_logic_320: i32 = 0

    var __ci_expr_old_322: *mut u32 = null

    var __ci_expr_logic_323: i32 = 0

    var __ci_expr_logic_324: i32 = 0

    var __ci_expr_old_325: *mut u32 = null

    var __ci_expr_old_326: *mut u32 = null

    var __ci_expr_logic_327: i32 = 0

    var __ci_expr_old_328: *mut u32 = null

    var __ci_expr_old_329: *mut u32 = null

    var __ci_expr_old_330: *mut u32 = null

    var __ci_expr_old_331: *mut u32 = null

    var __ci_expr_logic_332: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_verblengthptr__goto_3122_11 = ((null as *mut u32)))
        (__local_verbstartptr__goto_3123_11 = ((null as *mut u32)))
        (__local_previous_callout__goto_3124_11 = ((null as *mut u32)))
        (__local_parsed_pattern__goto_3125_11 = (*__param_cb).parsed_pattern)
        (__local_parsed_pattern_end__goto_3126_11 = (*__param_cb).parsed_pattern_end)
        (__local_this_parsed_item__goto_3127_11 = ((null as *mut u32)))
        (__local_prev_parsed_item__goto_3128_11 = ((null as *mut u32)))
        (__local_meta_quantifier__goto_3129_10 = ((0 as u32)))
        (__local_add_after_mark__goto_3130_10 = ((0 as u32)))
        (__local_nest_depth__goto_3131_10 = ((0 as u16)))
        (__local_class_depth_m1__goto_3132_9 = ((-1 as i16)))
        (__local_class_maxdepth_m1__goto_3133_9 = ((-1 as i16)))
        (__local_after_manual_callout__goto_3135_5 = ((0 as i32)))
        (__local_expect_cond_assert__goto_3136_5 = ((0 as i32)))
        (__local_errorcode__goto_3137_5 = ((0 as i32)))
        (__local_inescq__goto_3140_6 = ((0 as i32)))
        (__local_inverbname__goto_3141_6 = ((0 as i32)))
        (__local_utf__goto_3142_6 = (((if ((__local_options as u32) & (524288 as u32)) != 0: 1 else: 0) as i32)))
        (__local_auto_callout__goto_3143_6 = (((if ((__local_options as u32) & (4 as u32)) != 0: 1 else: 0) as i32)))
        (__local_okquantifier__goto_3146_6 = ((0 as i32)))
        (__local_ptrend__goto_3149_12 = (*__param_cb).end_pattern)
        (__local_verbnamestart__goto_3150_12 = ((null as *const u8)))
        (__local_class_range_forbid_ptr__goto_3151_12 = ((null as *const u8)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        if (0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        if ((if ((__local_xoptions as u32) & (8 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__ci_expr_old_0 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_0) = ((2148073472 as u32)))
        (__ci_expr_old_1 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_1) = ((2149449728 as u32)))
        goto '__ci_bb_6
    }

    '__ci_bb_5 {
        if ((if ((__local_xoptions as u32) & (4 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        if ((if ((__local_options as u32) & (33554432 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_7 {
        (__ci_expr_old_2 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_2) = ((((2149318656 as u32) +% (5 as u32)) as u32)))
        (__ci_expr_old_3 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_3) = ((2149449728 as u32)))
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        goto '__ci_bb_6
    }

    '__ci_bb_9 {
        goto '__ci_bb_11
    }

    '__ci_bb_10 {
        (__local_top_nest__goto_3153_12 = ((null as *mut nest_save)))
        (__local_end_nests__goto_3153_23 = ((((*__param_cb).start_workspace + ((*__param_cb).workspace_size as usize)) as *mut nest_save)))
        (__local_end_nests__goto_3153_23 = ((((__local_end_nests__goto_3153_23 as *mut c_char) - ((((((*__param_cb).workspace_size as u64) *% (sizeof[u8]() as u64)) as u64) % (sizeof[nest_save]() as u64)) as usize)) as *mut nest_save)))
        if ((if ((__local_options as u32) & (16777216 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_11 {
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_12 {
        if ((if __local_parsed_pattern__goto_3125_11 >= __local_parsed_pattern_end__goto_3126_11: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        goto '__ci_bb_36
    }

    '__ci_bb_14 {
        goto '__ci_bb_16
    }

    '__ci_bb_15 {
        (__local_thisptr__goto_3147_12 = __local_ptr)
        (__ci_expr_old_4 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_4) as u32)))
        (__ci_expr_logic_5 = 0)
        if (__local_utf__goto_3142_6 != 0) {
            (__ci_expr_logic_5 = (if (if __local_c__goto_3115_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_16 {
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if (0 != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_18 {
        (__local_errorcode__goto_3137_5 = ERR63)
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        ((*__param_cb).erroroffset = ((((((__local_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        return __local_errorcode__goto_3137_5
    }

    '__ci_bb_20 {
        if ((if ((__local_c__goto_3115_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_21 {
        if (__local_auto_callout__goto_3143_6 != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_22 {
        (__ci_expr_old_6 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = ((((((((__local_c__goto_3115_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_6) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_24
    }

    '__ci_bb_23 {
        if ((if ((__local_c__goto_3115_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_24 {
        goto '__ci_bb_21
    }

    '__ci_bb_25 {
        (__local_c__goto_3115_10 = ((((((((((__local_c__goto_3115_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_27
    }

    '__ci_bb_26 {
        if ((if ((__local_c__goto_3115_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_27 {
        goto '__ci_bb_24
    }

    '__ci_bb_28 {
        (__local_c__goto_3115_10 = ((((((((((((__local_c__goto_3115_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_30
    }

    '__ci_bb_29 {
        if ((if ((__local_c__goto_3115_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_27
    }

    '__ci_bb_31 {
        (__local_c__goto_3115_10 = ((((((((((((((__local_c__goto_3115_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((4 as isize) as usize))
        goto '__ci_bb_33
    }

    '__ci_bb_32 {
        (__local_c__goto_3115_10 = ((((((((((((((((__local_c__goto_3115_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((5 as isize) as usize))
        goto '__ci_bb_33
    }

    '__ci_bb_33 {
        goto '__ci_bb_30
    }

    '__ci_bb_34 {
        (__local_parsed_pattern__goto_3125_11 = manage_callouts(__local_thisptr__goto_3147_12, (&raw mut __local_previous_callout__goto_3124_11 as *mut *mut u32), __local_auto_callout__goto_3143_6, __local_parsed_pattern__goto_3125_11, __param_cb))
        goto '__ci_bb_35
    }

    '__ci_bb_35 {
        (__ci_expr_old_7 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_7) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_11
    }

    '__ci_bb_36 {
        goto '__ci_bb_999
    }

    '__ci_bb_37 {
        (__local_options = (__local_options as u32) | (128 as u32))
        goto '__ci_bb_38
    }

    '__ci_bb_38 {
        goto '__ci_bb_39
    }

    '__ci_bb_39 {
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_40 {
        (__local_min_repeat__goto_3229_12 = ((0 as u32)))
        (__local_max_repeat__goto_3229_28 = ((0 as u32)))
        if ((if __local_nest_depth__goto_3131_10 > (*(*__param_cb).cx).parens_nest_limit: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_41 {
        (__ci_expr_logic_327 = 0)
        if (__local_inverbname__goto_3141_6 != 0) {
            (__ci_expr_logic_327 = (if (if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_327 != 0) {
            goto '__ci_bb_997
        } else {
            goto '__ci_bb_998
        }
    }

    '__ci_bb_42 {
        (__local_errorcode__goto_3137_5 = ERR19)
        goto '__ci_bb_19
    }

    '__ci_bb_43 {
        if ((if __local_parsed_pattern__goto_3125_11 >= __local_parsed_pattern_end__goto_3126_11: 1 else: 0) != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_44 {
        goto '__ci_bb_46
    }

    '__ci_bb_45 {
        if ((if __local_this_parsed_item__goto_3127_11 != __local_parsed_pattern__goto_3125_11: 1 else: 0) != 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_46 {
        goto '__ci_bb_47
    }

    '__ci_bb_47 {
        if (0 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_48 {
        (__local_errorcode__goto_3137_5 = ERR63)
        goto '__ci_bb_19
    }

    '__ci_bb_49 {
        (__local_prev_parsed_item__goto_3128_11 = __local_this_parsed_item__goto_3127_11)
        (__local_this_parsed_item__goto_3127_11 = __local_parsed_pattern__goto_3125_11)
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        (__local_thisptr__goto_3147_12 = __local_ptr)
        (__ci_expr_old_8 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_8) as u32)))
        (__ci_expr_logic_9 = 0)
        if (__local_utf__goto_3142_6 != 0) {
            (__ci_expr_logic_9 = (if (if __local_c__goto_3115_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_51 {
        if ((if ((__local_c__goto_3115_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_52 {
        if (__local_inescq__goto_3140_6 != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_53 {
        (__ci_expr_old_10 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = ((((((((__local_c__goto_3115_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_10) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_55
    }

    '__ci_bb_54 {
        if ((if ((__local_c__goto_3115_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_55 {
        goto '__ci_bb_52
    }

    '__ci_bb_56 {
        (__local_c__goto_3115_10 = ((((((((((__local_c__goto_3115_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_58
    }

    '__ci_bb_57 {
        if ((if ((__local_c__goto_3115_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_58 {
        goto '__ci_bb_55
    }

    '__ci_bb_59 {
        (__local_c__goto_3115_10 = ((((((((((((__local_c__goto_3115_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        if ((if ((__local_c__goto_3115_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_61 {
        goto '__ci_bb_58
    }

    '__ci_bb_62 {
        (__local_c__goto_3115_10 = ((((((((((((((__local_c__goto_3115_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((4 as isize) as usize))
        goto '__ci_bb_64
    }

    '__ci_bb_63 {
        (__local_c__goto_3115_10 = ((((((((((((((((__local_c__goto_3115_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((5 as isize) as usize))
        goto '__ci_bb_64
    }

    '__ci_bb_64 {
        goto '__ci_bb_61
    }

    '__ci_bb_65 {
        (__ci_expr_logic_12 = 0)
        (__ci_expr_logic_11 = 0)
        if ((if __local_c__goto_3115_10 == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_11 = (if (if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            (__ci_expr_logic_12 = (if (if (*__local_ptr) == 69: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_66 {
        (__ci_expr_logic_23 = 0)
        if (__local_inverbname__goto_3141_6 != 0) {
            var __ci_expr_logic_22: i32

            var __ci_expr_logic_18: i32

            if ((if ((__local_options as u32) & (((128 as u32) | (4194304 as u32)) as u32)) != ((128 as u32) | (4194304 as u32)): 1 else: 0) != 0) {
                (__ci_expr_logic_18 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_17: i32 = 0

                var __ci_expr_logic_16: i32 = 0

                if ((if __local_c__goto_3115_10 > 255: 1 else: 0) != 0) {
                    (__ci_expr_logic_16 = (if (if ((__local_c__goto_3115_10 as u32) | (1 as u32)) != 8207: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_16 != 0) {
                    (__ci_expr_logic_17 = (if (if ((__local_c__goto_3115_10 as u32) | (1 as u32)) != 8233: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_18 = (if __ci_expr_logic_17 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_18 != 0) {
                (__ci_expr_logic_22 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_21: i32 = 0

                var __ci_expr_logic_20: i32 = 0

                var __ci_expr_logic_19: i32 = 0

                if ((if __local_c__goto_3115_10 < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_19 = (if (if __local_c__goto_3115_10 != 35: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_19 != 0) {
                    (__ci_expr_logic_20 = (if (if ((((*__param_cb).ctypes[__local_c__goto_3115_10]) as i32) & (1 as i32)) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_20 != 0) {
                    (__ci_expr_logic_21 = (if (if __local_c__goto_3115_10 != 133: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

            }

            (__ci_expr_logic_23 = (if __ci_expr_logic_22 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_67 {
        (__local_inescq__goto_3140_6 = ((0 as i32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_69
    }

    '__ci_bb_68 {
        if (__local_inverbname__goto_3141_6 != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_69 {
        goto '__ci_bb_39
    }

    '__ci_bb_70 {
        (__ci_expr_old_13 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_13) = __local_c__goto_3115_10)
        goto '__ci_bb_72
    }

    '__ci_bb_71 {
        (__ci_expr_old_14 = __local_after_manual_callout__goto_3135_5)
        (__local_after_manual_callout__goto_3135_5 = __local_after_manual_callout__goto_3135_5 - 1)
        if ((if __ci_expr_old_14 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_72 {
        (__local_meta_quantifier__goto_3129_10 = ((0 as u32)))
        goto '__ci_bb_69
    }

    '__ci_bb_73 {
        (__local_parsed_pattern__goto_3125_11 = manage_callouts(__local_thisptr__goto_3147_12, (&raw mut __local_previous_callout__goto_3124_11 as *mut *mut u32), __local_auto_callout__goto_3143_6, __local_parsed_pattern__goto_3125_11, __param_cb))
        goto '__ci_bb_74
    }

    '__ci_bb_74 {
        (__ci_expr_old_15 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_15) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_72
    }

    '__ci_bb_75 {
        goto '__ci_bb_77
    }

    '__ci_bb_76 {
        (__ci_expr_logic_29 = 0)
        if ((if __local_c__goto_3115_10 == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_29 = (if (if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_29 != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_77 {
        if (__local_c__goto_3115_10 == 41) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_78 {
        goto '__ci_bb_39
    }

    '__ci_bb_79 {
        (__ci_expr_old_24 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_24) = __local_c__goto_3115_10)
        goto '__ci_bb_78
    }

    '__ci_bb_80 {
        (__local_inverbname__goto_3141_6 = ((0 as i32)))
        (__local_verbnamelength__goto_3348_16 = (((((((__local_parsed_pattern__goto_3125_11 as usize) -% (__local_verblengthptr__goto_3122_11 as usize)) as i64) / (sizeof[u32]() as i64)) - 1) as u64)))
        if ((if (((((__local_ptr as usize) -% (__local_verbnamestart__goto_3150_12 as usize)) as i64) / (sizeof[u8]() as i64)) - 1) > 255: 1 else: 0) != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_81 {
        (__local_ptr = __local_ptr - 1)
        (__local_errorcode__goto_3137_5 = ERR76)
        goto '__ci_bb_19
    }

    '__ci_bb_82 {
        ((*__local_verblengthptr__goto_3122_11) = ((__local_verbnamelength__goto_3348_16 as u32)))
        if ((if __local_add_after_mark__goto_3130_10 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_83 {
        (__ci_expr_old_25 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_25) = __local_add_after_mark__goto_3130_10)
        (__local_add_after_mark__goto_3130_10 = ((0 as u32)))
        goto '__ci_bb_84
    }

    '__ci_bb_84 {
        goto '__ci_bb_78
    }

    '__ci_bb_85 {
        if ((if ((__local_options as u32) & (4194304 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_86 {
        (__local_escape__goto_3138_5 = ((_pcre2_check_escape_8((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, (&raw mut __local_c__goto_3115_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __local_options, __local_xoptions, (*__param_cb).bracount, (0 as i32), __param_cb) as i32)))
        if ((if __local_errorcode__goto_3137_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_87 {
        (__local_escape__goto_3138_5 = ((0 as i32)))
        goto '__ci_bb_88
    }

    '__ci_bb_88 {
        goto '__ci_bb_91
    }

    '__ci_bb_89 {
        goto '__ci_bb_19
    }

    '__ci_bb_90 {
        goto '__ci_bb_88
    }

    '__ci_bb_91 {
        if (__local_escape__goto_3138_5 == 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_92 {
        goto '__ci_bb_78
    }

    '__ci_bb_93 {
        (__ci_expr_old_26 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_26) = __local_c__goto_3115_10)
        goto '__ci_bb_92
    }

    '__ci_bb_94 {
        (__ci_expr_old_27 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_27) = ((117 as u32)))
        (__ci_expr_old_28 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_28) = ((123 as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_92
    }

    '__ci_bb_95 {
        (__local_inescq__goto_3140_6 = ((1 as i32)))
        goto '__ci_bb_92
    }

    '__ci_bb_96 {
        goto '__ci_bb_92
    }

    '__ci_bb_97 {
        (__local_errorcode__goto_3137_5 = ERR40)
        goto '__ci_bb_19
    }

    '__ci_bb_98 {
        if (__local_escape__goto_3138_5 == 29) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_99 {
        if (__local_escape__goto_3138_5 == 26) {
            goto '__ci_bb_95
        } else {
            goto '__ci_bb_100
        }
    }

    '__ci_bb_100 {
        if (__local_escape__goto_3138_5 == 25) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_101 {
        if (__local_c__goto_3115_10 == 92) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_102 {
        if ((if (*__local_ptr) == 81: 1 else: 0) != 0) {
            (__ci_expr_logic_30 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_30 = (if (if (*__local_ptr) == 69: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_30 != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_105
        }
    }

    '__ci_bb_103 {
        if ((if ((__local_options as u32) & (128 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_104 {
        (__ci_expr_logic_34 = 0)
        (__ci_expr_logic_31 = 0)
        if ((if __local_expect_cond_assert__goto_3136_5 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_31 = (if (if (*__local_ptr) == 81: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            var __ci_expr_logic_33: i32 = 0

            var __ci_expr_logic_32: i32 = 0

            if ((if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 3: 1 else: 0) != 0) {
                (__ci_expr_logic_32 = (if (if (__local_ptr[1]) == 92: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_32 != 0) {
                (__ci_expr_logic_33 = (if (if (__local_ptr[2]) == 69: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_34 = (if (if not (__ci_expr_logic_33 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_107
        }
    }

    '__ci_bb_105 {
        goto '__ci_bb_103
    }

    '__ci_bb_106 {
        (__local_ptr = __local_ptr - 1)
        (__local_errorcode__goto_3137_5 = ERR28)
        goto '__ci_bb_19
    }

    '__ci_bb_107 {
        (__local_inescq__goto_3140_6 = (((if (*__local_ptr) == 81: 1 else: 0) as i32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_39
    }

    '__ci_bb_108 {
        (__ci_expr_logic_35 = 0)
        if ((if __local_c__goto_3115_10 < 256: 1 else: 0) != 0) {
            (__ci_expr_logic_35 = (if (if ((((*__param_cb).ctypes[__local_c__goto_3115_10]) as i32) & (1 as i32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_35 != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_109 {
        (__ci_expr_logic_46 = 0)
        (__ci_expr_logic_45 = 0)
        (__ci_expr_logic_44 = 0)
        if ((if __local_c__goto_3115_10 == 40: 1 else: 0) != 0) {
            (__ci_expr_logic_44 = (if (if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_44 != 0) {
            (__ci_expr_logic_45 = (if (if (__local_ptr[0]) == 63: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_45 != 0) {
            (__ci_expr_logic_46 = (if (if (__local_ptr[1]) == 35: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_46 != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_110 {
        goto '__ci_bb_39
    }

    '__ci_bb_111 {
        if ((if __local_c__goto_3115_10 == 133: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_36 = (if (if ((__local_c__goto_3115_10 as u32) | (1 as u32)) == 8207: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            (__ci_expr_logic_37 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_37 = (if (if ((__local_c__goto_3115_10 as u32) | (1 as u32)) == 8233: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_112 {
        goto '__ci_bb_39
    }

    '__ci_bb_113 {
        if ((if __local_c__goto_3115_10 == 35: 1 else: 0) != 0) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_115
        }
    }

    '__ci_bb_114 {
        goto '__ci_bb_116
    }

    '__ci_bb_115 {
        goto '__ci_bb_109
    }

    '__ci_bb_116 {
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_118
        }
    }

    '__ci_bb_117 {
        (__ci_expr_ternary_42 = 0)
        if ((if (*__param_cb).nltype != 0: 1 else: 0) != 0) {
            var __ci_expr_logic_38: i32 = 0

            if ((if __local_ptr < (*__param_cb).end_pattern: 1 else: 0) != 0) {
                (__ci_expr_logic_38 = (if _pcre2_is_newline_8(__local_ptr, (*__param_cb).nltype, (*__param_cb).end_pattern, ((&raw const (*__param_cb).nllen as *const u32) as *mut u32), __local_utf__goto_3142_6) != 0: 1 else: 0))
            }

            (__ci_expr_ternary_42 = __ci_expr_logic_38)

        } else {
            var __ci_expr_logic_41: i32 = 0

            var __ci_expr_logic_39: i32 = 0

            if ((if __local_ptr <= ((*__param_cb).end_pattern - ((*__param_cb).nllen as usize)): 1 else: 0) != 0) {
                (__ci_expr_logic_39 = (if (if (*__local_ptr) == (*__param_cb).nl[0]: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_39 != 0) {
                var __ci_expr_logic_40: i32

                if ((if (*__param_cb).nllen == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_40 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_40 = (if (if (*(__local_ptr + ((1 as isize) as usize))) == (*__param_cb).nl[1]: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_41 = (if __ci_expr_logic_40 != 0: 1 else: 0))

            }

            (__ci_expr_ternary_42 = __ci_expr_logic_41)

        }
        if (__ci_expr_ternary_42 != 0) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_118 {
        goto '__ci_bb_39
    }

    '__ci_bb_119 {
        (__local_ptr = __local_ptr + ((*__param_cb).nllen as usize))
        goto '__ci_bb_118
    }

    '__ci_bb_120 {
        (__local_ptr = __local_ptr + 1)
        if (__local_utf__goto_3142_6 != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_121 {
        goto '__ci_bb_123
    }

    '__ci_bb_122 {
        goto '__ci_bb_116
    }

    '__ci_bb_123 {
        (__ci_expr_logic_43 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_43 = (if (if ((((*__local_ptr) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_43 != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_124 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_123
    }

    '__ci_bb_125 {
        goto '__ci_bb_122
    }

    '__ci_bb_126 {
        goto '__ci_bb_128
    }

    '__ci_bb_127 {
        (__ci_expr_logic_51 = 0)
        (__ci_expr_logic_49 = 0)
        (__ci_expr_logic_48 = 0)
        if ((if __local_c__goto_3115_10 != 42: 1 else: 0) != 0) {
            (__ci_expr_logic_48 = (if (if __local_c__goto_3115_10 != 43: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_48 != 0) {
            (__ci_expr_logic_49 = (if (if __local_c__goto_3115_10 != 63: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_49 != 0) {
            var __ci_expr_logic_50: i32

            if ((if __local_c__goto_3115_10 != 123: 1 else: 0) != 0) {
                (__ci_expr_logic_50 = (if true: 1 else: 0))
            } else {
                (__local_tempptr__goto_3235_14 = __local_ptr)

                (__ci_expr_logic_50 = (if (if not (read_repeat_counts((&raw mut __local_tempptr__goto_3235_14 as *mut *const u8), __local_ptrend__goto_3149_12, (null as *mut u32), (null as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0): 1 else: 0) != 0: 1 else: 0))

            }

            (__ci_expr_logic_51 = (if __ci_expr_logic_50 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_51 != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_128 {
        (__ci_expr_logic_47 = 0)
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_47 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_47 != 0) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_129 {
        goto '__ci_bb_128
    }

    '__ci_bb_130 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_131
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_131 {
        (__local_errorcode__goto_3137_5 = ERR18)
        goto '__ci_bb_19
    }

    '__ci_bb_132 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_39
    }

    '__ci_bb_133 {
        (__ci_expr_old_52 = __local_after_manual_callout__goto_3135_5)
        (__local_after_manual_callout__goto_3135_5 = __local_after_manual_callout__goto_3135_5 - 1)
        if ((if __ci_expr_old_52 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_134 {
        if ((if __local_expect_cond_assert__goto_3136_5 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_135 {
        (__local_parsed_pattern__goto_3125_11 = manage_callouts(__local_thisptr__goto_3147_12, (&raw mut __local_previous_callout__goto_3124_11 as *mut *mut u32), __local_auto_callout__goto_3143_6, __local_parsed_pattern__goto_3125_11, __param_cb))
        (__local_this_parsed_item__goto_3127_11 = __local_parsed_pattern__goto_3125_11)
        goto '__ci_bb_136
    }

    '__ci_bb_136 {
        goto '__ci_bb_134
    }

    '__ci_bb_137 {
        (__ci_expr_logic_55 = 0)
        (__ci_expr_logic_53 = 0)
        if ((if __local_c__goto_3115_10 == 40: 1 else: 0) != 0) {
            (__ci_expr_logic_53 = (if (if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_53 != 0) {
            var __ci_expr_logic_54: i32

            if ((if (__local_ptr[0]) == 63: 1 else: 0) != 0) {
                (__ci_expr_logic_54 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_54 = (if (if (__local_ptr[0]) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_55 = (if __ci_expr_logic_54 != 0: 1 else: 0))

        }
        (__local_ok__goto_3519_10 = __ci_expr_logic_55)
        if (__local_ok__goto_3519_10 != 0) {
            goto '__ci_bb_139
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_138 {
        (__local_prev_expect_cond_assert__goto_3228_7 = __local_expect_cond_assert__goto_3136_5)
        (__local_expect_cond_assert__goto_3136_5 = ((0 as i32)))
        (__local_prev_okquantifier__goto_3234_8 = __local_okquantifier__goto_3146_6)
        (__local_prev_meta_quantifier__goto_3233_12 = __local_meta_quantifier__goto_3129_10)
        (__local_okquantifier__goto_3146_6 = ((0 as i32)))
        (__local_meta_quantifier__goto_3129_10 = ((0 as u32)))
        (__ci_expr_logic_59 = 0)
        if ((if __local_prev_meta_quantifier__goto_3233_12 != 0: 1 else: 0) != 0) {
            var __ci_expr_logic_58: i32

            if ((if __local_c__goto_3115_10 == 63: 1 else: 0) != 0) {
                (__ci_expr_logic_58 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_58 = (if (if __local_c__goto_3115_10 == 43: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_59 = (if __ci_expr_logic_58 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_59 != 0) {
            goto '__ci_bb_158
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_139 {
        if ((if (__local_ptr[0]) == 42: 1 else: 0) != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_140 {
        if ((if not (__local_ok__goto_3519_10 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_141 {
        (__ci_expr_logic_56 = 0)
        if (1 != 0) {
            (__ci_expr_logic_56 = (if (if ((((*__param_cb).ctypes[(__local_ptr[1])]) as i32) & (4 as i32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_ok__goto_3519_10 = __ci_expr_logic_56)
        goto '__ci_bb_143
    }

    '__ci_bb_142 {
        goto '__ci_bb_144
    }

    '__ci_bb_143 {
        goto '__ci_bb_140
    }

    '__ci_bb_144 {
        if ((__local_ptr[1]) == 67) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_145 {
        goto '__ci_bb_143
    }

    '__ci_bb_146 {
        (__local_ok__goto_3519_10 = (((if __local_expect_cond_assert__goto_3136_5 == 2: 1 else: 0) as i32)))
        goto '__ci_bb_145
    }

    '__ci_bb_147 {
        goto '__ci_bb_145
    }

    '__ci_bb_148 {
        if ((if (__local_ptr[2]) == 61: 1 else: 0) != 0) {
            (__ci_expr_logic_57 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_57 = (if (if (__local_ptr[2]) == 33: 1 else: 0) != 0: 1 else: 0))
        }
        (__local_ok__goto_3519_10 = __ci_expr_logic_57)
        goto '__ci_bb_145
    }

    '__ci_bb_149 {
        (__local_ok__goto_3519_10 = ((0 as i32)))
        goto '__ci_bb_145
    }

    '__ci_bb_150 {
        if ((__local_ptr[1]) == 61) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_151 {
        if ((__local_ptr[1]) == 33) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_152 {
        if ((__local_ptr[1]) == 60) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_153 {
        (__local_errorcode__goto_3137_5 = ERR28)
        if ((if __local_expect_cond_assert__goto_3136_5 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_154 {
        goto '__ci_bb_138
    }

    '__ci_bb_155 {
        goto '__ci_bb_19
    }

    '__ci_bb_156 {
        goto '__ci_bb_157
    }

    '__ci_bb_157 {
        (__local_ptr = __local_ptr - 1)
        if (__local_utf__goto_3142_6 != 0) {
            goto '__ci_bb_1014
        } else {
            goto '__ci_bb_1015
        }
    }

    '__ci_bb_158 {
        ((__local_parsed_pattern__goto_3125_11[(if (if __local_prev_meta_quantifier__goto_3233_12 == 2151743488: 1 else: 0) != 0: (-3 as i32) else: (-1 as i32))]) = ((((__local_prev_meta_quantifier__goto_3233_12 as u32) +% ((if (if __local_c__goto_3115_10 == 63: 1 else: 0) != 0: (131072 as u32) else: (65536 as u32)) as u32)) as u32)))
        goto '__ci_bb_39
    }

    '__ci_bb_159 {
        goto '__ci_bb_160
    }

    '__ci_bb_160 {
        if (__local_c__goto_3115_10 == 92) {
            goto '__ci_bb_163
        } else {
            goto '__ci_bb_986
        }
    }

    '__ci_bb_161 {
        goto '__ci_bb_39
    }

    '__ci_bb_162 {
        (__ci_expr_old_60 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_60) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_161
    }

    '__ci_bb_163 {
        (__local_tempptr__goto_3235_14 = __local_ptr)
        (__local_escape__goto_3138_5 = ((_pcre2_check_escape_8((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, (&raw mut __local_c__goto_3115_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __local_options, __local_xoptions, (*__param_cb).bracount, (0 as i32), __param_cb) as i32)))
        if ((if __local_errorcode__goto_3137_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_164 {
        goto '__ci_bb_166
    }

    '__ci_bb_165 {
        if ((if __local_escape__goto_3138_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_166 {
        if ((if ((__local_xoptions as u32) & (2 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_167 {
        goto '__ci_bb_19
    }

    '__ci_bb_168 {
        (__local_ptr = __local_tempptr__goto_3235_14)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_169 {
        (__local_c__goto_3115_10 = ((92 as u32)))
        goto '__ci_bb_171
    }

    '__ci_bb_170 {
        (__ci_expr_old_61 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_61) as u32)))
        (__ci_expr_logic_62 = 0)
        if (__local_utf__goto_3142_6 != 0) {
            (__ci_expr_logic_62 = (if (if __local_c__goto_3115_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_62 != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_171 {
        (__local_escape__goto_3138_5 = ((0 as i32)))
        goto '__ci_bb_165
    }

    '__ci_bb_172 {
        if ((if ((__local_c__goto_3115_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_173 {
        goto '__ci_bb_171
    }

    '__ci_bb_174 {
        (__ci_expr_old_63 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = ((((((((__local_c__goto_3115_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_63) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_176
    }

    '__ci_bb_175 {
        if ((if ((__local_c__goto_3115_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_176 {
        goto '__ci_bb_173
    }

    '__ci_bb_177 {
        (__local_c__goto_3115_10 = ((((((((((__local_c__goto_3115_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_179
    }

    '__ci_bb_178 {
        if ((if ((__local_c__goto_3115_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_179 {
        goto '__ci_bb_176
    }

    '__ci_bb_180 {
        (__local_c__goto_3115_10 = ((((((((((((__local_c__goto_3115_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_182
    }

    '__ci_bb_181 {
        if ((if ((__local_c__goto_3115_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_182 {
        goto '__ci_bb_179
    }

    '__ci_bb_183 {
        (__local_c__goto_3115_10 = ((((((((((((((__local_c__goto_3115_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((4 as isize) as usize))
        goto '__ci_bb_185
    }

    '__ci_bb_184 {
        (__local_c__goto_3115_10 = ((((((((((((((((__local_c__goto_3115_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((5 as isize) as usize))
        goto '__ci_bb_185
    }

    '__ci_bb_185 {
        goto '__ci_bb_182
    }

    '__ci_bb_186 {
        (__ci_expr_old_64 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_64) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_188
    }

    '__ci_bb_187 {
        if ((if __local_escape__goto_3138_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_188 {
        goto '__ci_bb_161
    }

    '__ci_bb_189 {
        (__local_offset__goto_3236_14 = ((((((__local_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        (__local_escape__goto_3138_5 = ((((0 - __local_escape__goto_3138_5) - 1) as i32)))
        (__ci_expr_old_65 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_65) = ((((2147680256 as u32) | (__local_escape__goto_3138_5 as u32)) as u32)))
        if ((if __local_escape__goto_3138_5 < 10: 1 else: 0) != 0) {
            goto '__ci_bb_192
        } else {
            goto '__ci_bb_193
        }
    }

    '__ci_bb_190 {
        goto '__ci_bb_197
    }

    '__ci_bb_191 {
        goto '__ci_bb_188
    }

    '__ci_bb_192 {
        if ((if (*__param_cb).small_ref_offset[__local_escape__goto_3138_5] == (~(0 as u64)): 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_193 {
        (__ci_expr_old_66 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_66) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_67 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_67) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        goto '__ci_bb_194
    }

    '__ci_bb_194 {
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_191
    }

    '__ci_bb_195 {
        ((*__param_cb).small_ref_offset[__local_escape__goto_3138_5] = __local_offset__goto_3236_14)
        goto '__ci_bb_196
    }

    '__ci_bb_196 {
        goto '__ci_bb_194
    }

    '__ci_bb_197 {
        if (__local_escape__goto_3138_5 == 14) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_225
        }
    }

    '__ci_bb_198 {
        goto '__ci_bb_191
    }

    '__ci_bb_199 {
        if ((if ((__local_options as u32) & (1048576 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_200 {
        (__local_errorcode__goto_3137_5 = ERR83)
        goto '__ci_bb_166
    }

    '__ci_bb_201 {
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        (__ci_expr_old_68 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_68) = ((((2149318656 as u32) +% (__local_escape__goto_3138_5 as u32)) as u32)))
        goto '__ci_bb_198
    }

    '__ci_bb_202 {
        (__ci_expr_old_69 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_69) = ((117 as u32)))
        (__ci_expr_old_70 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_70) = ((123 as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_198
    }

    '__ci_bb_203 {
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        (__ci_expr_old_71 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_71) = ((((2149318656 as u32) +% (__local_escape__goto_3138_5 as u32)) as u32)))
        goto '__ci_bb_198
    }

    '__ci_bb_204 {
        (__ci_expr_old_72 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_72) = ((((2149318656 as u32) +% (__local_escape__goto_3138_5 as u32)) as u32)))
        goto '__ci_bb_198
    }

    '__ci_bb_205 {
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        (__local_parsed_pattern__goto_3125_11 = handle_escdsw(__local_escape__goto_3138_5, __local_parsed_pattern__goto_3125_11, __local_options, __local_xoptions))
        goto '__ci_bb_198
    }

    '__ci_bb_206 {
        (__local_ptype__goto_3723_18 = ((0 as u16)))
        (__local_pdata__goto_3723_29 = ((0 as u16)))
        if ((if not (get_ucp((&raw mut __local_ptr as *mut *const u8), __local_utf__goto_3142_6, (&raw mut __local_negated__goto_3722_14 as *mut i32), (&raw mut __local_ptype__goto_3723_18 as *mut u16), (&raw mut __local_pdata__goto_3723_29 as *mut u16), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_207
        } else {
            goto '__ci_bb_208
        }
    }

    '__ci_bb_207 {
        goto '__ci_bb_166
    }

    '__ci_bb_208 {
        if (__local_negated__goto_3722_14 != 0) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_209 {
        (__local_escape__goto_3138_5 = (((if (if __local_escape__goto_3138_5 == ESC_P: 1 else: 0) != 0: ESC_p else: ESC_P) as i32)))
        goto '__ci_bb_210
    }

    '__ci_bb_210 {
        (__ci_expr_old_73 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_73) = ((((2149318656 as u32) +% (__local_escape__goto_3138_5 as u32)) as u32)))
        (__ci_expr_old_74 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_74) = ((((((__local_ptype__goto_3723_18 as i32) << (16 as u32)) as i32) | (__local_pdata__goto_3723_29 as i32)) as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_198
    }

    '__ci_bb_211 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_77 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_76: i32 = 0

            var __ci_expr_logic_75: i32 = 0

            if ((if (*__local_ptr) != 123: 1 else: 0) != 0) {
                (__ci_expr_logic_75 = (if (if (*__local_ptr) != 60: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_75 != 0) {
                (__ci_expr_logic_76 = (if (if (*__local_ptr) != 39: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_77 = (if __ci_expr_logic_76 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_77 != 0) {
            goto '__ci_bb_212
        } else {
            goto '__ci_bb_213
        }
    }

    '__ci_bb_212 {
        (__local_errorcode__goto_3137_5 = (((if (if __local_escape__goto_3138_5 == ESC_g: 1 else: 0) != 0: ERR57 else: ERR69) as i32)))
        goto '__ci_bb_166
    }

    '__ci_bb_213 {
        (__local_terminator__goto_3232_12 = (((if (if (*__local_ptr) == 60: 1 else: 0) != 0: (62 as i32) else: ((if (if (*__local_ptr) == 39: 1 else: 0) != 0: (39 as i32) else: (125 as i32)) as i32)) as u32)))
        (__ci_expr_logic_78 = 0)
        if ((if __local_escape__goto_3138_5 == ESC_g: 1 else: 0) != 0) {
            (__ci_expr_logic_78 = (if (if __local_terminator__goto_3232_12 != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_78 != 0) {
            goto '__ci_bb_214
        } else {
            goto '__ci_bb_215
        }
    }

    '__ci_bb_214 {
        (__local_p__goto_3759_20 = __local_ptr + ((1 as isize) as usize))
        if (read_number((&raw mut __local_p__goto_3759_20 as *mut *const u8), __local_ptrend__goto_3149_12, ((*__param_cb).bracount as i32), (65535 as u32), (161 as u32), (&raw mut __local_i__goto_3139_5 as *mut i32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0) {
            goto '__ci_bb_216
        } else {
            goto '__ci_bb_217
        }
    }

    '__ci_bb_215 {
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, __local_terminator__goto_3232_12, (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_223
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_216 {
        if ((if __local_p__goto_3759_20 >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_79 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_79 = (if (if (*__local_p__goto_3759_20) != __local_terminator__goto_3232_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_79 != 0) {
            goto '__ci_bb_218
        } else {
            goto '__ci_bb_219
        }
    }

    '__ci_bb_217 {
        if ((if __local_errorcode__goto_3137_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_221
        } else {
            goto '__ci_bb_222
        }
    }

    '__ci_bb_218 {
        (__local_ptr = __local_p__goto_3759_20)
        (__local_errorcode__goto_3137_5 = ERR119)
        goto '__ci_bb_166
    }

    '__ci_bb_219 {
        (__local_ptr = __local_p__goto_3759_20 + ((1 as isize) as usize))
        goto '__ci_bb_220
    }

    '__ci_bb_220 {
        (__ci_expr_old_254 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_254) = ((((2149842944 as u32) | (__local_i__goto_3139_5 as u32)) as u32)))
        (__local_offset__goto_3236_14 = ((((((__local_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        goto '__ci_bb_776
    }

    '__ci_bb_221 {
        goto '__ci_bb_166
    }

    '__ci_bb_222 {
        goto '__ci_bb_215
    }

    '__ci_bb_223 {
        goto '__ci_bb_166
    }

    '__ci_bb_224 {
        (__ci_expr_old_80 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        (__ci_expr_ternary_82 = 0)
        if ((if __local_escape__goto_3138_5 == ESC_k: 1 else: 0) != 0) {
            (__ci_expr_logic_81 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_81 = (if (if __local_terminator__goto_3232_12 == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_81 != 0) {
            (__ci_expr_ternary_82 = ((2147745792 as u32)))
        } else {
            (__ci_expr_ternary_82 = ((2149908480 as u32)))
        }
        ((*__ci_expr_old_80) = __ci_expr_ternary_82)
        (__ci_expr_old_83 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_83) = __local_namelen__goto_3117_10)
        (__ci_expr_old_84 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_84) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_85 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_85) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_198
    }

    '__ci_bb_225 {
        if (__local_escape__goto_3138_5 == 29) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_226 {
        if (__local_escape__goto_3138_5 == 22) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_227
        }
    }

    '__ci_bb_227 {
        if (__local_escape__goto_3138_5 == 18) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_228
        }
    }

    '__ci_bb_228 {
        if (__local_escape__goto_3138_5 == 19) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_229 {
        if (__local_escape__goto_3138_5 == 12) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_230
        }
    }

    '__ci_bb_230 {
        if (__local_escape__goto_3138_5 == 17) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_231 {
        if (__local_escape__goto_3138_5 == 20) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_232 {
        if (__local_escape__goto_3138_5 == 21) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_233
        }
    }

    '__ci_bb_233 {
        if (__local_escape__goto_3138_5 == 7) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_234
        }
    }

    '__ci_bb_234 {
        if (__local_escape__goto_3138_5 == 6) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_235
        }
    }

    '__ci_bb_235 {
        if (__local_escape__goto_3138_5 == 9) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_236 {
        if (__local_escape__goto_3138_5 == 8) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_237 {
        if (__local_escape__goto_3138_5 == 11) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_238
        }
    }

    '__ci_bb_238 {
        if (__local_escape__goto_3138_5 == 10) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_239
        }
    }

    '__ci_bb_239 {
        if (__local_escape__goto_3138_5 == 15) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_240
        }
    }

    '__ci_bb_240 {
        if (__local_escape__goto_3138_5 == 16) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_241
        }
    }

    '__ci_bb_241 {
        if (__local_escape__goto_3138_5 == 27) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_242 {
        if (__local_escape__goto_3138_5 == 28) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_204
        }
    }

    '__ci_bb_243 {
        (__ci_expr_old_86 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_86) = ((2148073472 as u32)))
        goto '__ci_bb_161
    }

    '__ci_bb_244 {
        (__ci_expr_old_87 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_87) = ((2149187584 as u32)))
        goto '__ci_bb_161
    }

    '__ci_bb_245 {
        (__ci_expr_old_88 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_88) = ((2149253120 as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_161
    }

    '__ci_bb_246 {
        (__local_meta_quantifier__goto_3129_10 = ((2151153664 as u32)))
        goto '__ci_bb_247
    }

    '__ci_bb_247 {
        if ((if not (__local_prev_okquantifier__goto_3234_8 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_248 {
        (__local_meta_quantifier__goto_3129_10 = ((2151350272 as u32)))
        goto '__ci_bb_247
    }

    '__ci_bb_249 {
        (__local_meta_quantifier__goto_3129_10 = ((2151546880 as u32)))
        goto '__ci_bb_247
    }

    '__ci_bb_250 {
        if ((if not (read_repeat_counts((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, (&raw mut __local_min_repeat__goto_3229_12 as *mut u32), (&raw mut __local_max_repeat__goto_3229_28 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_251 {
        if ((if __local_errorcode__goto_3137_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_253
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_252 {
        (__local_meta_quantifier__goto_3129_10 = ((2151743488 as u32)))
        goto '__ci_bb_247
    }

    '__ci_bb_253 {
        goto '__ci_bb_19
    }

    '__ci_bb_254 {
        (__ci_expr_old_89 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_89) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_161
    }

    '__ci_bb_255 {
        (__local_errorcode__goto_3137_5 = ERR9)
        goto '__ci_bb_19
    }

    '__ci_bb_256 {
        if ((if (*__local_prev_parsed_item__goto_3128_11) == 2150498304: 1 else: 0) != 0) {
            goto '__ci_bb_257
        } else {
            goto '__ci_bb_258
        }
    }

    '__ci_bb_257 {
        (__local_p__goto_3862_17 = __local_parsed_pattern__goto_3125_11 - ((1 as isize) as usize))
        goto '__ci_bb_259
    }

    '__ci_bb_258 {
        (__ci_expr_old_90 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_90) = __local_meta_quantifier__goto_3129_10)
        if ((if __local_c__goto_3115_10 == 123: 1 else: 0) != 0) {
            goto '__ci_bb_263
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_259 {
        if ((if __local_p__goto_3862_17 >= __local_verbstartptr__goto_3123_11: 1 else: 0) != 0) {
            goto '__ci_bb_260
        } else {
            goto '__ci_bb_262
        }
    }

    '__ci_bb_260 {
        ((__local_p__goto_3862_17[1]) = (((__local_p__goto_3862_17[0]) as u32)))
        goto '__ci_bb_261
    }

    '__ci_bb_261 {
        (__local_p__goto_3862_17 = __local_p__goto_3862_17 - 1)
        goto '__ci_bb_259
    }

    '__ci_bb_262 {
        ((*__local_verbstartptr__goto_3123_11) = ((2149449728 as u32)))
        ((__local_parsed_pattern__goto_3125_11[1]) = ((2149384192 as u32)))
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + ((2 as isize) as usize))
        goto '__ci_bb_258
    }

    '__ci_bb_263 {
        (__ci_expr_old_91 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_91) = __local_min_repeat__goto_3229_12)
        (__ci_expr_old_92 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_92) = __local_max_repeat__goto_3229_28)
        goto '__ci_bb_264
    }

    '__ci_bb_264 {
        goto '__ci_bb_161
    }

    '__ci_bb_265 {
        (__ci_expr_logic_94 = 0)
        if ((if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 6: 1 else: 0) != 0) {
            var __ci_expr_logic_93: i32

            if ((if _pcre2_strncmp_c8_8(__local_ptr, c"\x5b\x3a\x3c\x3a\x5d\x5d".ptr, (6 as u64)) == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_93 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_93 = (if (if _pcre2_strncmp_c8_8(__local_ptr, c"\x5b\x3a\x3e\x3a\x5d\x5d".ptr, (6 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_94 = (if __ci_expr_logic_93 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_94 != 0) {
            goto '__ci_bb_266
        } else {
            goto '__ci_bb_267
        }
    }

    '__ci_bb_266 {
        (__ci_expr_old_95 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_95) = ((((2149318656 as u32) +% (5 as u32)) as u32)))
        if ((if (__local_ptr[2]) == 60: 1 else: 0) != 0) {
            goto '__ci_bb_268
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_267 {
        (__ci_expr_logic_107 = 0)
        (__ci_expr_logic_106 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            var __ci_expr_logic_105: i32

            var __ci_expr_logic_104: i32

            if ((if (*__local_ptr) == 58: 1 else: 0) != 0) {
                (__ci_expr_logic_104 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_104 = (if (if (*__local_ptr) == 46: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_104 != 0) {
                (__ci_expr_logic_105 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_105 = (if (if (*__local_ptr) == 61: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_106 = (if __ci_expr_logic_105 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_106 != 0) {
            (__ci_expr_logic_107 = (if check_posix_syntax(__local_ptr, __local_ptrend__goto_3149_12, (&raw mut __local_tempptr__goto_3235_14 as *mut *const u8)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_107 != 0) {
            goto '__ci_bb_274
        } else {
            goto '__ci_bb_275
        }
    }

    '__ci_bb_268 {
        (__ci_expr_old_96 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_96) = ((2150039552 as u32)))
        goto '__ci_bb_270
    }

    '__ci_bb_269 {
        (__ci_expr_old_97 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_97) = ((2150170624 as u32)))
        ((*__param_has_lookbehind) = ((1 as i32)))
        (__ci_expr_old_98 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_98) = ((((0 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_99 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_99) = ((((0 as u64) & (4294967295 as u64)) as u32)))
        goto '__ci_bb_270
    }

    '__ci_bb_270 {
        if ((if ((__local_options as u32) & (131072 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_271
        } else {
            goto '__ci_bb_272
        }
    }

    '__ci_bb_271 {
        (__ci_expr_old_100 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_100) = ((((2149318656 as u32) +% (11 as u32)) as u32)))
        goto '__ci_bb_273
    }

    '__ci_bb_272 {
        (__ci_expr_old_101 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_101) = ((((2149318656 as u32) +% (16 as u32)) as u32)))
        (__ci_expr_old_102 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_102) = ((524288 as u32)))
        goto '__ci_bb_273
    }

    '__ci_bb_273 {
        (__ci_expr_old_103 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_103) = ((2149384192 as u32)))
        (__local_ptr = __local_ptr + ((6 as isize) as usize))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_161
    }

    '__ci_bb_274 {
        (__ci_expr_ternary_109 = 0)
        (__ci_expr_old_108 = __local_ptr)
        (__local_ptr = __local_ptr - 1)
        if ((if (*__ci_expr_old_108) == 58: 1 else: 0) != 0) {
            (__ci_expr_ternary_109 = ERR12)
        } else {
            (__ci_expr_ternary_109 = ERR13)
        }
        (__local_errorcode__goto_3137_5 = __ci_expr_ternary_109)
        (__local_ptr = __local_tempptr__goto_3235_14 + ((2 as isize) as usize))
        goto '__ci_bb_19
    }

    '__ci_bb_275 {
        (__local_class_mode_state__goto_3120_10 = (((if (if ((__local_options as u32) & (134217728 as u32)) != 0: 1 else: 0) != 0: CLASS_MODE_ALT_EXT else: CLASS_MODE_NORMAL) as u32)))
        goto '__ci_bb_276
    }

    '__ci_bb_276 {
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        (__local_class_depth_m1__goto_3132_9 = ((-1 as i16)))
        (__local_class_maxdepth_m1__goto_3133_9 = ((-1 as i16)))
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((0 as u32)))
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_277
    }

    '__ci_bb_277 {
        goto '__ci_bb_278
    }

    '__ci_bb_278 {
        (__local_char_is_literal__goto_3974_12 = ((1 as i32)))
        if (__local_inescq__goto_3140_6 != 0) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_282
        }
    }

    '__ci_bb_279 {
        goto '__ci_bb_277
    }

    '__ci_bb_280 {
        goto '__ci_bb_161
    }

    '__ci_bb_281 {
        (__ci_expr_logic_111 = 0)
        (__ci_expr_logic_110 = 0)
        if ((if __local_c__goto_3115_10 == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_110 = (if (if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_110 != 0) {
            (__ci_expr_logic_111 = (if (if (*__local_ptr) == 69: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_111 != 0) {
            goto '__ci_bb_283
        } else {
            goto '__ci_bb_284
        }
    }

    '__ci_bb_282 {
        (__ci_expr_logic_114 = 0)
        if ((if __local_c__goto_3115_10 == 32: 1 else: 0) != 0) {
            (__ci_expr_logic_112 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_112 = (if (if __local_c__goto_3115_10 == 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_112 != 0) {
            var __ci_expr_logic_113: i32

            if ((if ((__local_options as u32) & (16777216 as u32)) != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_113 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_113 = (if (if __local_class_mode_state__goto_3120_10 >= 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_114 = (if __ci_expr_logic_113 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_114 != 0) {
            goto '__ci_bb_289
        } else {
            goto '__ci_bb_290
        }
    }

    '__ci_bb_283 {
        (__local_inescq__goto_3140_6 = ((0 as i32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_285
    }

    '__ci_bb_284 {
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_286
        } else {
            goto '__ci_bb_287
        }
    }

    '__ci_bb_285 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_561
        } else {
            goto '__ci_bb_562
        }
    }

    '__ci_bb_286 {
        (__local_errorcode__goto_3137_5 = ERR116)
        goto '__ci_bb_19
    }

    '__ci_bb_287 {
        goto '__ci_bb_288
    }

    '__ci_bb_288 {
        (__ci_expr_logic_195 = 0)
        if ((if __local_class_op_state__goto_3119_10 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_195 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_195 != 0) {
            goto '__ci_bb_545
        } else {
            goto '__ci_bb_546
        }
    }

    '__ci_bb_289 {
        goto '__ci_bb_285
    }

    '__ci_bb_290 {
        (__ci_expr_logic_120 = 0)
        (__ci_expr_logic_119 = 0)
        (__ci_expr_logic_116 = 0)
        (__ci_expr_logic_115 = 0)
        if ((if __local_class_depth_m1__goto_3132_9 >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_115 = (if (if __local_c__goto_3115_10 == 91: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_115 != 0) {
            (__ci_expr_logic_116 = (if (if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_116 != 0) {
            var __ci_expr_logic_118: i32

            var __ci_expr_logic_117: i32

            if ((if (*__local_ptr) == 58: 1 else: 0) != 0) {
                (__ci_expr_logic_117 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_117 = (if (if (*__local_ptr) == 46: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_117 != 0) {
                (__ci_expr_logic_118 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_118 = (if (if (*__local_ptr) == 61: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_119 = (if __ci_expr_logic_118 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_119 != 0) {
            (__ci_expr_logic_120 = (if check_posix_syntax(__local_ptr, __local_ptrend__goto_3149_12, (&raw mut __local_tempptr__goto_3235_14 as *mut *const u8)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_120 != 0) {
            goto '__ci_bb_291
        } else {
            goto '__ci_bb_292
        }
    }

    '__ci_bb_291 {
        (__local_posix_negate__goto_4021_14 = ((0 as i32)))
        if ((if __local_class_range_state__goto_3118_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_294
        } else {
            goto '__ci_bb_295
        }
    }

    '__ci_bb_292 {
        (__ci_expr_logic_133 = 0)
        if ((if __local_c__goto_3115_10 == 91: 1 else: 0) != 0) {
            var __ci_expr_logic_132: i32

            var __ci_expr_logic_131: i32

            if ((if __local_class_depth_m1__goto_3132_9 < 0: 1 else: 0) != 0) {
                (__ci_expr_logic_131 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_131 = (if (if __local_class_mode_state__goto_3120_10 == 1: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_131 != 0) {
                (__ci_expr_logic_132 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_132 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_133 = (if __ci_expr_logic_132 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_133 != 0) {
            (__ci_expr_logic_135 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_134: i32 = 0

            if ((if __local_c__goto_3115_10 == 40: 1 else: 0) != 0) {
                (__ci_expr_logic_134 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_135 = (if __ci_expr_logic_134 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_135 != 0) {
            goto '__ci_bb_312
        } else {
            goto '__ci_bb_313
        }
    }

    '__ci_bb_293 {
        goto '__ci_bb_285
    }

    '__ci_bb_294 {
        (__local_ptr = __local_tempptr__goto_3235_14 + ((2 as isize) as usize))
        (__local_errorcode__goto_3137_5 = ERR50)
        goto '__ci_bb_19
    }

    '__ci_bb_295 {
        if ((if __local_class_range_state__goto_3118_10 == 3: 1 else: 0) != 0) {
            goto '__ci_bb_296
        } else {
            goto '__ci_bb_297
        }
    }

    '__ci_bb_296 {
        (__local_ptr = __local_class_range_forbid_ptr__goto_3151_12)
        (__local_errorcode__goto_3137_5 = ERR50)
        goto '__ci_bb_19
    }

    '__ci_bb_297 {
        (__ci_expr_logic_121 = 0)
        if ((if __local_class_op_state__goto_3119_10 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_121 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_121 != 0) {
            goto '__ci_bb_298
        } else {
            goto '__ci_bb_299
        }
    }

    '__ci_bb_298 {
        (__local_ptr = __local_tempptr__goto_3235_14 + ((2 as isize) as usize))
        (__local_errorcode__goto_3137_5 = ERR113)
        goto '__ci_bb_19
    }

    '__ci_bb_299 {
        if ((if (*__local_ptr) != 58: 1 else: 0) != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_300 {
        (__local_ptr = __local_tempptr__goto_3235_14 + ((2 as isize) as usize))
        (__local_errorcode__goto_3137_5 = ERR13)
        goto '__ci_bb_19
    }

    '__ci_bb_301 {
        (__local_ptr = __local_ptr + 1)
        if ((if (*__local_ptr) == 94: 1 else: 0) != 0) {
            goto '__ci_bb_302
        } else {
            goto '__ci_bb_303
        }
    }

    '__ci_bb_302 {
        (__local_posix_negate__goto_4021_14 = ((1 as i32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_303
    }

    '__ci_bb_303 {
        (__local_posix_class__goto_4022_13 = ((check_posix_name(__local_ptr, (((((__local_tempptr__goto_3235_14 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) as i32)) as i32)))
        (__local_ptr = __local_tempptr__goto_3235_14 + ((2 as isize) as usize))
        if ((if __local_posix_class__goto_4022_13 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_305
        }
    }

    '__ci_bb_304 {
        (__local_errorcode__goto_3137_5 = ERR30)
        goto '__ci_bb_19
    }

    '__ci_bb_305 {
        (__local_class_range_state__goto_3118_10 = ((2 as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        (__ci_expr_logic_125 = 0)
        (__ci_expr_logic_122 = 0)
        if ((if ((__local_options as u32) & (131072 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_122 = (if (if ((__local_xoptions as u32) & (2048 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_122 != 0) {
            var __ci_expr_logic_124: i32 = 0

            if ((if ((__local_xoptions as u32) & (4096 as u32)) != 0: 1 else: 0) != 0) {
                var __ci_expr_logic_123: i32

                if ((if __local_posix_class__goto_4022_13 == 7: 1 else: 0) != 0) {
                    (__ci_expr_logic_123 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_123 = (if (if __local_posix_class__goto_4022_13 == 13: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_124 = (if __ci_expr_logic_123 != 0: 1 else: 0))

            }

            (__ci_expr_logic_125 = (if (if not (__ci_expr_logic_124 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_125 != 0) {
            goto '__ci_bb_306
        } else {
            goto '__ci_bb_307
        }
    }

    '__ci_bb_306 {
        (__local_ptype__goto_4104_15 = ((posix_substitutes[(2 * __local_posix_class__goto_4022_13)] as i32)))
        (__local_pvalue__goto_4105_15 = ((posix_substitutes[((2 * __local_posix_class__goto_4022_13) + 1)] as i32)))
        if ((if __local_ptype__goto_4104_15 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_308
        } else {
            goto '__ci_bb_309
        }
    }

    '__ci_bb_307 {
        (__ci_expr_old_129 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_129) = (((if __local_posix_negate__goto_4021_14 != 0: (2149646336 as u32) else: (2149580800 as u32)) as u32)))
        (__ci_expr_old_130 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_130) = ((__local_posix_class__goto_4022_13 as u32)))
        goto '__ci_bb_293
    }

    '__ci_bb_308 {
        (__ci_expr_old_126 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_126) = ((((2149318656 as u32) +% ((if __local_posix_negate__goto_4021_14 != 0: ESC_P else: ESC_p) as u32)) as u32)))
        (__ci_expr_old_127 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_127) = ((((((__local_ptype__goto_4104_15 as i32) << (16 as u32)) as i32) | (__local_pvalue__goto_4105_15 as i32)) as u32)))
        goto '__ci_bb_285
    }

    '__ci_bb_309 {
        if ((if __local_pvalue__goto_4105_15 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_311
        }
    }

    '__ci_bb_310 {
        (__ci_expr_old_128 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_128) = ((((2149318656 as u32) +% ((if __local_posix_negate__goto_4021_14 != 0: ESC_H else: ESC_h) as u32)) as u32)))
        goto '__ci_bb_285
    }

    '__ci_bb_311 {
        goto '__ci_bb_307
    }

    '__ci_bb_312 {
        (__local_start_c__goto_4138_18 = __local_c__goto_3115_10)
        (__ci_expr_logic_137 = 0)
        (__ci_expr_logic_136 = 0)
        if ((if __local_start_c__goto_4138_18 == 91: 1 else: 0) != 0) {
            (__ci_expr_logic_136 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_136 != 0) {
            (__ci_expr_logic_137 = (if (if __local_class_depth_m1__goto_3132_9 >= 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_137 != 0) {
            goto '__ci_bb_315
        } else {
            goto '__ci_bb_316
        }
    }

    '__ci_bb_313 {
        if ((if __local_c__goto_3115_10 == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_155 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_154: i32 = 0

            if ((if __local_c__goto_3115_10 == 41: 1 else: 0) != 0) {
                (__ci_expr_logic_154 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_155 = (if __ci_expr_logic_154 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_155 != 0) {
            goto '__ci_bb_386
        } else {
            goto '__ci_bb_387
        }
    }

    '__ci_bb_314 {
        goto '__ci_bb_293
    }

    '__ci_bb_315 {
        (__local_new_class_mode_state__goto_4139_18 = ((3 as u32)))
        goto '__ci_bb_317
    }

    '__ci_bb_316 {
        (__local_new_class_mode_state__goto_4139_18 = __local_class_mode_state__goto_3120_10)
        goto '__ci_bb_317
    }

    '__ci_bb_317 {
        if ((if __local_class_range_state__goto_3118_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_318
        } else {
            goto '__ci_bb_319
        }
    }

    '__ci_bb_318 {
        ((__local_parsed_pattern__goto_3125_11[-1]) = ((45 as u32)))
        goto '__ci_bb_319
    }

    '__ci_bb_319 {
        (__ci_expr_logic_138 = 0)
        if ((if __local_class_op_state__goto_3119_10 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_138 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_138 != 0) {
            goto '__ci_bb_320
        } else {
            goto '__ci_bb_321
        }
    }

    '__ci_bb_320 {
        (__local_errorcode__goto_3137_5 = ERR113)
        goto '__ci_bb_19
    }

    '__ci_bb_321 {
        if ((if __local_class_depth_m1__goto_3132_9 >= (15 - 1): 1 else: 0) != 0) {
            goto '__ci_bb_322
        } else {
            goto '__ci_bb_323
        }
    }

    '__ci_bb_322 {
        (__local_ptr = __local_ptr - 1)
        (__local_errorcode__goto_3137_5 = ERR107)
        goto '__ci_bb_19
    }

    '__ci_bb_323 {
        (__local_negate_class__goto_3145_6 = ((0 as i32)))
        goto '__ci_bb_324
    }

    '__ci_bb_324 {
        goto '__ci_bb_325
    }

    '__ci_bb_325 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_328
        } else {
            goto '__ci_bb_329
        }
    }

    '__ci_bb_326 {
        goto '__ci_bb_324
    }

    '__ci_bb_327 {
        (__ci_expr_logic_149 = 0)
        (__ci_expr_logic_148 = 0)
        if ((if __local_c__goto_3115_10 == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_148 = (if (if (((*__param_cb).external_options as u32) & (1 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_148 != 0) {
            (__ci_expr_logic_149 = (if (if __local_new_class_mode_state__goto_4139_18 < 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_149 != 0) {
            goto '__ci_bb_365
        } else {
            goto '__ci_bb_366
        }
    }

    '__ci_bb_328 {
        if ((if __local_start_c__goto_4138_18 == 40: 1 else: 0) != 0) {
            goto '__ci_bb_330
        } else {
            goto '__ci_bb_331
        }
    }

    '__ci_bb_329 {
        (__ci_expr_old_139 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_139) as u32)))
        (__ci_expr_logic_140 = 0)
        if (__local_utf__goto_3142_6 != 0) {
            (__ci_expr_logic_140 = (if (if __local_c__goto_3115_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_140 != 0) {
            goto '__ci_bb_333
        } else {
            goto '__ci_bb_334
        }
    }

    '__ci_bb_330 {
        (__local_errorcode__goto_3137_5 = ERR14)
        goto '__ci_bb_332
    }

    '__ci_bb_331 {
        (__local_errorcode__goto_3137_5 = ERR6)
        goto '__ci_bb_332
    }

    '__ci_bb_332 {
        goto '__ci_bb_19
    }

    '__ci_bb_333 {
        if ((if ((__local_c__goto_3115_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_335
        } else {
            goto '__ci_bb_336
        }
    }

    '__ci_bb_334 {
        if ((if __local_new_class_mode_state__goto_4139_18 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_348
        }
    }

    '__ci_bb_335 {
        (__ci_expr_old_141 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = ((((((((__local_c__goto_3115_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_141) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_337
    }

    '__ci_bb_336 {
        if ((if ((__local_c__goto_3115_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_338
        } else {
            goto '__ci_bb_339
        }
    }

    '__ci_bb_337 {
        goto '__ci_bb_334
    }

    '__ci_bb_338 {
        (__local_c__goto_3115_10 = ((((((((((__local_c__goto_3115_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_340
    }

    '__ci_bb_339 {
        if ((if ((__local_c__goto_3115_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_341
        } else {
            goto '__ci_bb_342
        }
    }

    '__ci_bb_340 {
        goto '__ci_bb_337
    }

    '__ci_bb_341 {
        (__local_c__goto_3115_10 = ((((((((((((__local_c__goto_3115_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_343
    }

    '__ci_bb_342 {
        if ((if ((__local_c__goto_3115_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_344
        } else {
            goto '__ci_bb_345
        }
    }

    '__ci_bb_343 {
        goto '__ci_bb_340
    }

    '__ci_bb_344 {
        (__local_c__goto_3115_10 = ((((((((((((((__local_c__goto_3115_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((4 as isize) as usize))
        goto '__ci_bb_346
    }

    '__ci_bb_345 {
        (__local_c__goto_3115_10 = ((((((((((((((((__local_c__goto_3115_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((5 as isize) as usize))
        goto '__ci_bb_346
    }

    '__ci_bb_346 {
        goto '__ci_bb_343
    }

    '__ci_bb_347 {
        goto '__ci_bb_327
    }

    '__ci_bb_348 {
        if ((if __local_c__goto_3115_10 == 92: 1 else: 0) != 0) {
            goto '__ci_bb_350
        } else {
            goto '__ci_bb_351
        }
    }

    '__ci_bb_349 {
        goto '__ci_bb_326
    }

    '__ci_bb_350 {
        (__ci_expr_logic_142 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_142 = (if (if (*__local_ptr) == 69: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_142 != 0) {
            goto '__ci_bb_353
        } else {
            goto '__ci_bb_354
        }
    }

    '__ci_bb_351 {
        (__ci_expr_logic_146 = 0)
        if ((if __local_c__goto_3115_10 == 32: 1 else: 0) != 0) {
            (__ci_expr_logic_144 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_144 = (if (if __local_c__goto_3115_10 == 9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_144 != 0) {
            var __ci_expr_logic_145: i32

            if ((if ((__local_options as u32) & (16777216 as u32)) != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_145 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_145 = (if (if __local_new_class_mode_state__goto_4139_18 >= 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_146 = (if __ci_expr_logic_145 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_146 != 0) {
            goto '__ci_bb_359
        } else {
            goto '__ci_bb_360
        }
    }

    '__ci_bb_352 {
        goto '__ci_bb_349
    }

    '__ci_bb_353 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_355
    }

    '__ci_bb_354 {
        (__ci_expr_logic_143 = 0)
        if ((if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_143 = (if (if _pcre2_strncmp_c8_8(__local_ptr, c"\x51\x5c\x45".ptr, (3 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_143 != 0) {
            goto '__ci_bb_356
        } else {
            goto '__ci_bb_357
        }
    }

    '__ci_bb_355 {
        goto '__ci_bb_352
    }

    '__ci_bb_356 {
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_358
    }

    '__ci_bb_357 {
        goto '__ci_bb_327
    }

    '__ci_bb_358 {
        goto '__ci_bb_355
    }

    '__ci_bb_359 {
        goto '__ci_bb_326
    }

    '__ci_bb_360 {
        (__ci_expr_logic_147 = 0)
        if ((if not (__local_negate_class__goto_3145_6 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_147 = (if (if __local_c__goto_3115_10 == 94: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_147 != 0) {
            goto '__ci_bb_362
        } else {
            goto '__ci_bb_363
        }
    }

    '__ci_bb_361 {
        goto '__ci_bb_352
    }

    '__ci_bb_362 {
        (__local_negate_class__goto_3145_6 = ((1 as i32)))
        goto '__ci_bb_364
    }

    '__ci_bb_363 {
        goto '__ci_bb_327
    }

    '__ci_bb_364 {
        goto '__ci_bb_361
    }

    '__ci_bb_365 {
        goto '__ci_bb_367
    }

    '__ci_bb_366 {
        if ((if __local_class_start__goto_3121_11 != null: 1 else: 0) != 0) {
            goto '__ci_bb_377
        } else {
            goto '__ci_bb_378
        }
    }

    '__ci_bb_367 {
        goto '__ci_bb_368
    }

    '__ci_bb_368 {
        if (0 != 0) {
            goto '__ci_bb_367
        } else {
            goto '__ci_bb_369
        }
    }

    '__ci_bb_369 {
        if ((if __local_class_start__goto_3121_11 != null: 1 else: 0) != 0) {
            goto '__ci_bb_370
        } else {
            goto '__ci_bb_371
        }
    }

    '__ci_bb_370 {
        goto '__ci_bb_372
    }

    '__ci_bb_371 {
        (__ci_expr_old_150 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_150) = (((if __local_negate_class__goto_3145_6 != 0: (2148270080 as u32) else: (2148204544 as u32)) as u32)))
        if ((if __local_class_depth_m1__goto_3132_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_375
        } else {
            goto '__ci_bb_376
        }
    }

    '__ci_bb_372 {
        goto '__ci_bb_373
    }

    '__ci_bb_373 {
        if (0 != 0) {
            goto '__ci_bb_372
        } else {
            goto '__ci_bb_374
        }
    }

    '__ci_bb_374 {
        ((*__local_class_start__goto_3121_11) = ((*__local_class_start__goto_3121_11) as u32) | (1 as u32))
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_371
    }

    '__ci_bb_375 {
        goto '__ci_bb_280
    }

    '__ci_bb_376 {
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        goto '__ci_bb_285
    }

    '__ci_bb_377 {
        goto '__ci_bb_379
    }

    '__ci_bb_378 {
        (__local_class_start__goto_3121_11 = __local_parsed_pattern__goto_3125_11)
        (__ci_expr_old_151 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_151) = (((if __local_negate_class__goto_3145_6 != 0: (2148401152 as u32) else: (2148139008 as u32)) as u32)))
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((0 as u32)))
        (__local_class_mode_state__goto_3120_10 = __local_new_class_mode_state__goto_4139_18)
        (__local_class_depth_m1__goto_3132_9 = __local_class_depth_m1__goto_3132_9 + 1)
        if ((if __local_class_maxdepth_m1__goto_3133_9 < __local_class_depth_m1__goto_3132_9: 1 else: 0) != 0) {
            goto '__ci_bb_382
        } else {
            goto '__ci_bb_383
        }
    }

    '__ci_bb_379 {
        goto '__ci_bb_380
    }

    '__ci_bb_380 {
        if (0 != 0) {
            goto '__ci_bb_379
        } else {
            goto '__ci_bb_381
        }
    }

    '__ci_bb_381 {
        ((*__local_class_start__goto_3121_11) = ((*__local_class_start__goto_3121_11) as u32) | (1 as u32))
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_378
    }

    '__ci_bb_382 {
        (__local_class_maxdepth_m1__goto_3133_9 = __local_class_depth_m1__goto_3132_9)
        goto '__ci_bb_383
    }

    '__ci_bb_383 {
        ((*__param_cb).class_op_used[__local_class_depth_m1__goto_3132_9] = ((0 as u8)))
        (__ci_expr_logic_152 = 0)
        if ((if __local_c__goto_3115_10 == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_152 = (if (if __local_new_class_mode_state__goto_4139_18 != 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_152 != 0) {
            goto '__ci_bb_384
        } else {
            goto '__ci_bb_385
        }
    }

    '__ci_bb_384 {
        (__local_class_range_state__goto_3118_10 = ((5 as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        (__ci_expr_old_153 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_153) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_285
    }

    '__ci_bb_385 {
        goto '__ci_bb_279
    }

    '__ci_bb_386 {
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_389
        } else {
            goto '__ci_bb_390
        }
    }

    '__ci_bb_387 {
        (__ci_expr_logic_165 = 0)
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            var __ci_expr_logic_164: i32

            var __ci_expr_logic_163: i32

            var __ci_expr_logic_162: i32

            var __ci_expr_logic_161: i32

            if ((if __local_c__goto_3115_10 == 43: 1 else: 0) != 0) {
                (__ci_expr_logic_161 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_161 = (if (if __local_c__goto_3115_10 == 124: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_161 != 0) {
                (__ci_expr_logic_162 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_162 = (if (if __local_c__goto_3115_10 == 45: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_162 != 0) {
                (__ci_expr_logic_163 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_163 = (if (if __local_c__goto_3115_10 == 38: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_163 != 0) {
                (__ci_expr_logic_164 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_164 = (if (if __local_c__goto_3115_10 == 94: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_165 = (if __ci_expr_logic_164 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_165 != 0) {
            goto '__ci_bb_412
        } else {
            goto '__ci_bb_413
        }
    }

    '__ci_bb_388 {
        goto '__ci_bb_314
    }

    '__ci_bb_389 {
        (__ci_expr_logic_156 = 0)
        if ((if __local_c__goto_3115_10 == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_156 = (if (if __local_class_depth_m1__goto_3132_9 != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_156 != 0) {
            goto '__ci_bb_391
        } else {
            goto '__ci_bb_392
        }
    }

    '__ci_bb_390 {
        if ((if __local_class_op_state__goto_3119_10 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_395
        } else {
            goto '__ci_bb_396
        }
    }

    '__ci_bb_391 {
        (__local_errorcode__goto_3137_5 = ERR14)
        (__local_ptr = __local_ptr - 1)
        goto '__ci_bb_19
    }

    '__ci_bb_392 {
        (__ci_expr_logic_157 = 0)
        if ((if __local_c__goto_3115_10 == 41: 1 else: 0) != 0) {
            (__ci_expr_logic_157 = (if (if __local_class_depth_m1__goto_3132_9 < 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_157 != 0) {
            goto '__ci_bb_393
        } else {
            goto '__ci_bb_394
        }
    }

    '__ci_bb_393 {
        (__local_errorcode__goto_3137_5 = ERR22)
        goto '__ci_bb_19
    }

    '__ci_bb_394 {
        goto '__ci_bb_390
    }

    '__ci_bb_395 {
        (__local_errorcode__goto_3137_5 = ERR110)
        goto '__ci_bb_19
    }

    '__ci_bb_396 {
        (__ci_expr_logic_158 = 0)
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_158 = (if (if __local_class_op_state__goto_3119_10 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_158 != 0) {
            goto '__ci_bb_397
        } else {
            goto '__ci_bb_398
        }
    }

    '__ci_bb_397 {
        (__local_errorcode__goto_3137_5 = ERR114)
        goto '__ci_bb_19
    }

    '__ci_bb_398 {
        if ((if __local_class_range_state__goto_3118_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_399
        } else {
            goto '__ci_bb_400
        }
    }

    '__ci_bb_399 {
        ((__local_parsed_pattern__goto_3125_11[-1]) = ((45 as u32)))
        goto '__ci_bb_400
    }

    '__ci_bb_400 {
        (__ci_expr_old_159 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_159) = ((2148335616 as u32)))
        (__local_class_depth_m1__goto_3132_9 = __local_class_depth_m1__goto_3132_9 - 1)
        if ((if __local_class_depth_m1__goto_3132_9 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_401
        } else {
            goto '__ci_bb_402
        }
    }

    '__ci_bb_401 {
        goto '__ci_bb_403
    }

    '__ci_bb_402 {
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        if ((if __local_class_mode_state__goto_3120_10 == 3: 1 else: 0) != 0) {
            goto '__ci_bb_410
        } else {
            goto '__ci_bb_411
        }
    }

    '__ci_bb_403 {
        goto '__ci_bb_404
    }

    '__ci_bb_404 {
        if (0 != 0) {
            goto '__ci_bb_403
        } else {
            goto '__ci_bb_405
        }
    }

    '__ci_bb_405 {
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_406
        } else {
            goto '__ci_bb_407
        }
    }

    '__ci_bb_406 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_160 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_160 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_160 != 0) {
            goto '__ci_bb_408
        } else {
            goto '__ci_bb_409
        }
    }

    '__ci_bb_407 {
        goto '__ci_bb_280
    }

    '__ci_bb_408 {
        (__local_errorcode__goto_3137_5 = ERR115)
        goto '__ci_bb_19
    }

    '__ci_bb_409 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_407
    }

    '__ci_bb_410 {
        (__local_class_mode_state__goto_3120_10 = ((2 as u32)))
        goto '__ci_bb_411
    }

    '__ci_bb_411 {
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_388
    }

    '__ci_bb_412 {
        if ((if __local_class_op_state__goto_3119_10 != 1: 1 else: 0) != 0) {
            goto '__ci_bb_415
        } else {
            goto '__ci_bb_416
        }
    }

    '__ci_bb_413 {
        (__ci_expr_logic_167 = 0)
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_167 = (if (if __local_c__goto_3115_10 == 33: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_167 != 0) {
            goto '__ci_bb_425
        } else {
            goto '__ci_bb_426
        }
    }

    '__ci_bb_414 {
        goto '__ci_bb_388
    }

    '__ci_bb_415 {
        (__local_errorcode__goto_3137_5 = ERR109)
        goto '__ci_bb_19
    }

    '__ci_bb_416 {
        if ((if __local_class_start__goto_3121_11 != null: 1 else: 0) != 0) {
            goto '__ci_bb_417
        } else {
            goto '__ci_bb_418
        }
    }

    '__ci_bb_417 {
        goto '__ci_bb_419
    }

    '__ci_bb_418 {
        goto '__ci_bb_422
    }

    '__ci_bb_419 {
        goto '__ci_bb_420
    }

    '__ci_bb_420 {
        if (0 != 0) {
            goto '__ci_bb_419
        } else {
            goto '__ci_bb_421
        }
    }

    '__ci_bb_421 {
        ((*__local_class_start__goto_3121_11) = ((*__local_class_start__goto_3121_11) as u32) | (1 as u32))
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_418
    }

    '__ci_bb_422 {
        goto '__ci_bb_423
    }

    '__ci_bb_423 {
        if (0 != 0) {
            goto '__ci_bb_422
        } else {
            goto '__ci_bb_424
        }
    }

    '__ci_bb_424 {
        (__ci_expr_old_166 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_166) = (((if (if __local_c__goto_3115_10 == 43: 1 else: 0) != 0: (2152005632 as u32) else: ((if (if __local_c__goto_3115_10 == 124: 1 else: 0) != 0: (2152005632 as u32) else: ((if (if __local_c__goto_3115_10 == 45: 1 else: 0) != 0: (2152071168 as u32) else: ((if (if __local_c__goto_3115_10 == 38: 1 else: 0) != 0: (2151940096 as u32) else: (2152136704 as u32)) as u32)) as u32)) as u32)) as u32)))
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((2 as u32)))
        goto '__ci_bb_414
    }

    '__ci_bb_425 {
        if ((if __local_class_op_state__goto_3119_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_428
        } else {
            goto '__ci_bb_429
        }
    }

    '__ci_bb_426 {
        (__ci_expr_logic_174 = 0)
        (__ci_expr_logic_173 = 0)
        (__ci_expr_logic_172 = 0)
        if ((if __local_class_mode_state__goto_3120_10 == 1: 1 else: 0) != 0) {
            var __ci_expr_logic_171: i32

            var __ci_expr_logic_170: i32

            var __ci_expr_logic_169: i32

            if ((if __local_c__goto_3115_10 == 124: 1 else: 0) != 0) {
                (__ci_expr_logic_169 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_169 = (if (if __local_c__goto_3115_10 == 45: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_169 != 0) {
                (__ci_expr_logic_170 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_170 = (if (if __local_c__goto_3115_10 == 38: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_170 != 0) {
                (__ci_expr_logic_171 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_171 = (if (if __local_c__goto_3115_10 == 126: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_172 = (if __ci_expr_logic_171 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_172 != 0) {
            (__ci_expr_logic_173 = (if (if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_173 != 0) {
            (__ci_expr_logic_174 = (if (if (*__local_ptr) == __local_c__goto_3115_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_174 != 0) {
            goto '__ci_bb_438
        } else {
            goto '__ci_bb_439
        }
    }

    '__ci_bb_427 {
        goto '__ci_bb_414
    }

    '__ci_bb_428 {
        (__local_errorcode__goto_3137_5 = ERR113)
        goto '__ci_bb_19
    }

    '__ci_bb_429 {
        if ((if __local_class_start__goto_3121_11 != null: 1 else: 0) != 0) {
            goto '__ci_bb_430
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_430 {
        goto '__ci_bb_432
    }

    '__ci_bb_431 {
        goto '__ci_bb_435
    }

    '__ci_bb_432 {
        goto '__ci_bb_433
    }

    '__ci_bb_433 {
        if (0 != 0) {
            goto '__ci_bb_432
        } else {
            goto '__ci_bb_434
        }
    }

    '__ci_bb_434 {
        ((*__local_class_start__goto_3121_11) = ((*__local_class_start__goto_3121_11) as u32) | (1 as u32))
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_431
    }

    '__ci_bb_435 {
        goto '__ci_bb_436
    }

    '__ci_bb_436 {
        if (0 != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_437
        }
    }

    '__ci_bb_437 {
        (__ci_expr_old_168 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_168) = ((2152202240 as u32)))
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((2 as u32)))
        goto '__ci_bb_427
    }

    '__ci_bb_438 {
        (__local_ptr = __local_ptr + 1)
        (__ci_expr_logic_175 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_175 = (if (if (*__local_ptr) == __local_c__goto_3115_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_175 != 0) {
            goto '__ci_bb_441
        } else {
            goto '__ci_bb_442
        }
    }

    '__ci_bb_439 {
        if ((if __local_c__goto_3115_10 == 92: 1 else: 0) != 0) {
            goto '__ci_bb_457
        } else {
            goto '__ci_bb_458
        }
    }

    '__ci_bb_440 {
        goto '__ci_bb_427
    }

    '__ci_bb_441 {
        goto '__ci_bb_443
    }

    '__ci_bb_442 {
        if ((if __local_class_op_state__goto_3119_10 != 1: 1 else: 0) != 0) {
            goto '__ci_bb_446
        } else {
            goto '__ci_bb_447
        }
    }

    '__ci_bb_443 {
        (__ci_expr_logic_176 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_176 = (if (if (*__local_ptr) == __local_c__goto_3115_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_176 != 0) {
            goto '__ci_bb_444
        } else {
            goto '__ci_bb_445
        }
    }

    '__ci_bb_444 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_443
    }

    '__ci_bb_445 {
        (__local_errorcode__goto_3137_5 = ERR108)
        goto '__ci_bb_19
    }

    '__ci_bb_446 {
        (__local_errorcode__goto_3137_5 = ERR109)
        goto '__ci_bb_19
    }

    '__ci_bb_447 {
        (__ci_expr_logic_177 = 0)
        if ((if (*__param_cb).class_op_used[__local_class_depth_m1__goto_3132_9] != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_177 = (if (if (*__param_cb).class_op_used[__local_class_depth_m1__goto_3132_9] != ((__local_c__goto_3115_10 as u8)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_177 != 0) {
            goto '__ci_bb_448
        } else {
            goto '__ci_bb_449
        }
    }

    '__ci_bb_448 {
        (__local_errorcode__goto_3137_5 = ERR111)
        goto '__ci_bb_19
    }

    '__ci_bb_449 {
        if ((if __local_class_start__goto_3121_11 != null: 1 else: 0) != 0) {
            goto '__ci_bb_450
        } else {
            goto '__ci_bb_451
        }
    }

    '__ci_bb_450 {
        goto '__ci_bb_452
    }

    '__ci_bb_451 {
        if ((if __local_class_range_state__goto_3118_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_455
        } else {
            goto '__ci_bb_456
        }
    }

    '__ci_bb_452 {
        goto '__ci_bb_453
    }

    '__ci_bb_453 {
        if (0 != 0) {
            goto '__ci_bb_452
        } else {
            goto '__ci_bb_454
        }
    }

    '__ci_bb_454 {
        ((*__local_class_start__goto_3121_11) = ((*__local_class_start__goto_3121_11) as u32) | (1 as u32))
        (__local_class_start__goto_3121_11 = ((null as *mut u32)))
        goto '__ci_bb_451
    }

    '__ci_bb_455 {
        ((__local_parsed_pattern__goto_3125_11[-1]) = ((45 as u32)))
        goto '__ci_bb_456
    }

    '__ci_bb_456 {
        (__ci_expr_old_178 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_178) = (((if (if __local_c__goto_3115_10 == 124: 1 else: 0) != 0: (2152005632 as u32) else: ((if (if __local_c__goto_3115_10 == 45: 1 else: 0) != 0: (2152071168 as u32) else: ((if (if __local_c__goto_3115_10 == 38: 1 else: 0) != 0: (2151940096 as u32) else: (2152136704 as u32)) as u32)) as u32)) as u32)))
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((2 as u32)))
        ((*__param_cb).class_op_used[__local_class_depth_m1__goto_3132_9] = ((__local_c__goto_3115_10 as u8)))
        goto '__ci_bb_440
    }

    '__ci_bb_457 {
        (__local_tempptr__goto_3235_14 = __local_ptr)
        (__local_escape__goto_3138_5 = ((_pcre2_check_escape_8((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, (&raw mut __local_c__goto_3115_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __local_options, __local_xoptions, (*__param_cb).bracount, (1 as i32), __param_cb) as i32)))
        if ((if __local_errorcode__goto_3137_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_460
        } else {
            goto '__ci_bb_461
        }
    }

    '__ci_bb_458 {
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            goto '__ci_bb_536
        } else {
            goto '__ci_bb_537
        }
    }

    '__ci_bb_459 {
        goto '__ci_bb_440
    }

    '__ci_bb_460 {
        if ((if ((__local_xoptions as u32) & (2 as u32)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_179 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_179 = (if (if __local_class_mode_state__goto_3120_10 >= 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_179 != 0) {
            goto '__ci_bb_462
        } else {
            goto '__ci_bb_463
        }
    }

    '__ci_bb_461 {
        goto '__ci_bb_481
    }

    '__ci_bb_462 {
        goto '__ci_bb_19
    }

    '__ci_bb_463 {
        (__local_ptr = __local_tempptr__goto_3235_14)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_464
        } else {
            goto '__ci_bb_465
        }
    }

    '__ci_bb_464 {
        (__local_c__goto_3115_10 = ((92 as u32)))
        goto '__ci_bb_466
    }

    '__ci_bb_465 {
        (__ci_expr_old_180 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_180) as u32)))
        (__ci_expr_logic_181 = 0)
        if (__local_utf__goto_3142_6 != 0) {
            (__ci_expr_logic_181 = (if (if __local_c__goto_3115_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_181 != 0) {
            goto '__ci_bb_467
        } else {
            goto '__ci_bb_468
        }
    }

    '__ci_bb_466 {
        (__local_escape__goto_3138_5 = ((0 as i32)))
        goto '__ci_bb_461
    }

    '__ci_bb_467 {
        if ((if ((__local_c__goto_3115_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_469
        } else {
            goto '__ci_bb_470
        }
    }

    '__ci_bb_468 {
        goto '__ci_bb_466
    }

    '__ci_bb_469 {
        (__ci_expr_old_182 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = ((((((((__local_c__goto_3115_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_182) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_471
    }

    '__ci_bb_470 {
        if ((if ((__local_c__goto_3115_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_472
        } else {
            goto '__ci_bb_473
        }
    }

    '__ci_bb_471 {
        goto '__ci_bb_468
    }

    '__ci_bb_472 {
        (__local_c__goto_3115_10 = ((((((((((__local_c__goto_3115_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_474
    }

    '__ci_bb_473 {
        if ((if ((__local_c__goto_3115_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_475
        } else {
            goto '__ci_bb_476
        }
    }

    '__ci_bb_474 {
        goto '__ci_bb_471
    }

    '__ci_bb_475 {
        (__local_c__goto_3115_10 = ((((((((((((__local_c__goto_3115_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_477
    }

    '__ci_bb_476 {
        if ((if ((__local_c__goto_3115_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_478
        } else {
            goto '__ci_bb_479
        }
    }

    '__ci_bb_477 {
        goto '__ci_bb_474
    }

    '__ci_bb_478 {
        (__local_c__goto_3115_10 = ((((((((((((((__local_c__goto_3115_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((4 as isize) as usize))
        goto '__ci_bb_480
    }

    '__ci_bb_479 {
        (__local_c__goto_3115_10 = ((((((((((((((((__local_c__goto_3115_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((5 as isize) as usize))
        goto '__ci_bb_480
    }

    '__ci_bb_480 {
        goto '__ci_bb_477
    }

    '__ci_bb_481 {
        if (__local_escape__goto_3138_5 == 0) {
            goto '__ci_bb_483
        } else {
            goto '__ci_bb_504
        }
    }

    '__ci_bb_482 {
        if ((if __local_class_range_state__goto_3118_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_530
        } else {
            goto '__ci_bb_531
        }
    }

    '__ci_bb_483 {
        (__local_char_is_literal__goto_3974_12 = ((0 as i32)))
        goto '__ci_bb_288
    }

    '__ci_bb_484 {
        (__local_c__goto_3115_10 = ((8 as u32)))
        (__local_char_is_literal__goto_3974_12 = ((0 as i32)))
        goto '__ci_bb_288
    }

    '__ci_bb_485 {
        (__local_c__goto_3115_10 = ((107 as u32)))
        (__local_char_is_literal__goto_3974_12 = ((0 as i32)))
        goto '__ci_bb_288
    }

    '__ci_bb_486 {
        (__local_inescq__goto_3140_6 = ((1 as i32)))
        goto '__ci_bb_285
    }

    '__ci_bb_487 {
        goto '__ci_bb_285
    }

    '__ci_bb_488 {
        (__local_errorcode__goto_3137_5 = ERR7)
        goto '__ci_bb_19
    }

    '__ci_bb_489 {
        (__local_errorcode__goto_3137_5 = ERR71)
        goto '__ci_bb_19
    }

    '__ci_bb_490 {
        (__ci_expr_old_183 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_183) = ((((2149318656 as u32) +% (__local_escape__goto_3138_5 as u32)) as u32)))
        goto '__ci_bb_482
    }

    '__ci_bb_491 {
        (__local_parsed_pattern__goto_3125_11 = handle_escdsw(__local_escape__goto_3138_5, __local_parsed_pattern__goto_3125_11, __local_options, __local_xoptions))
        goto '__ci_bb_482
    }

    '__ci_bb_492 {
        (__local_ptype__goto_4539_22 = ((0 as u16)))
        (__local_pdata__goto_4539_33 = ((0 as u16)))
        if ((if not (get_ucp((&raw mut __local_ptr as *mut *const u8), __local_utf__goto_3142_6, (&raw mut __local_negated__goto_4538_18 as *mut i32), (&raw mut __local_ptype__goto_4539_22 as *mut u16), (&raw mut __local_pdata__goto_4539_33 as *mut u16), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_493
        } else {
            goto '__ci_bb_494
        }
    }

    '__ci_bb_493 {
        goto '__ci_bb_19
    }

    '__ci_bb_494 {
        (__ci_expr_logic_187 = 0)
        (__ci_expr_logic_184 = 0)
        if ((if ((__local_options as u32) & (8 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_184 = (if (if __local_ptype__goto_4539_22 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_184 != 0) {
            var __ci_expr_logic_186: i32

            var __ci_expr_logic_185: i32

            if ((if __local_pdata__goto_4539_33 == ucp_Lu: 1 else: 0) != 0) {
                (__ci_expr_logic_185 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_185 = (if (if __local_pdata__goto_4539_33 == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_185 != 0) {
                (__ci_expr_logic_186 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_186 = (if (if __local_pdata__goto_4539_33 == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_187 = (if __ci_expr_logic_186 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_187 != 0) {
            goto '__ci_bb_495
        } else {
            goto '__ci_bb_496
        }
    }

    '__ci_bb_495 {
        (__local_ptype__goto_4539_22 = ((0 as u16)))
        (__local_pdata__goto_4539_33 = ((0 as u16)))
        goto '__ci_bb_496
    }

    '__ci_bb_496 {
        if (__local_negated__goto_4538_18 != 0) {
            goto '__ci_bb_497
        } else {
            goto '__ci_bb_498
        }
    }

    '__ci_bb_497 {
        (__local_escape__goto_3138_5 = (((if (if __local_escape__goto_3138_5 == ESC_P: 1 else: 0) != 0: ESC_p else: ESC_P) as i32)))
        goto '__ci_bb_498
    }

    '__ci_bb_498 {
        (__ci_expr_old_188 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_188) = ((((2149318656 as u32) +% (__local_escape__goto_3138_5 as u32)) as u32)))
        (__ci_expr_old_189 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_189) = ((((((__local_ptype__goto_4539_22 as i32) << (16 as u32)) as i32) | (__local_pdata__goto_4539_33 as i32)) as u32)))
        goto '__ci_bb_482
    }

    '__ci_bb_499 {
        goto '__ci_bb_500
    }

    '__ci_bb_500 {
        goto '__ci_bb_501
    }

    '__ci_bb_501 {
        if (0 != 0) {
            goto '__ci_bb_500
        } else {
            goto '__ci_bb_502
        }
    }

    '__ci_bb_502 {
        goto '__ci_bb_503
    }

    '__ci_bb_503 {
        (__local_errorcode__goto_3137_5 = ERR7)
        goto '__ci_bb_19
    }

    '__ci_bb_504 {
        if (__local_escape__goto_3138_5 == 5) {
            goto '__ci_bb_484
        } else {
            goto '__ci_bb_505
        }
    }

    '__ci_bb_505 {
        if (__local_escape__goto_3138_5 == 28) {
            goto '__ci_bb_485
        } else {
            goto '__ci_bb_506
        }
    }

    '__ci_bb_506 {
        if (__local_escape__goto_3138_5 == 26) {
            goto '__ci_bb_486
        } else {
            goto '__ci_bb_507
        }
    }

    '__ci_bb_507 {
        if (__local_escape__goto_3138_5 == 25) {
            goto '__ci_bb_487
        } else {
            goto '__ci_bb_508
        }
    }

    '__ci_bb_508 {
        if (__local_escape__goto_3138_5 == 4) {
            goto '__ci_bb_488
        } else {
            goto '__ci_bb_509
        }
    }

    '__ci_bb_509 {
        if (__local_escape__goto_3138_5 == 17) {
            goto '__ci_bb_488
        } else {
            goto '__ci_bb_510
        }
    }

    '__ci_bb_510 {
        if (__local_escape__goto_3138_5 == 22) {
            goto '__ci_bb_488
        } else {
            goto '__ci_bb_511
        }
    }

    '__ci_bb_511 {
        if (__local_escape__goto_3138_5 == 12) {
            goto '__ci_bb_489
        } else {
            goto '__ci_bb_512
        }
    }

    '__ci_bb_512 {
        if (__local_escape__goto_3138_5 == 18) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_513
        }
    }

    '__ci_bb_513 {
        if (__local_escape__goto_3138_5 == 19) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_514
        }
    }

    '__ci_bb_514 {
        if (__local_escape__goto_3138_5 == 20) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_515
        }
    }

    '__ci_bb_515 {
        if (__local_escape__goto_3138_5 == 21) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_516
        }
    }

    '__ci_bb_516 {
        if (__local_escape__goto_3138_5 == 7) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_517
        }
    }

    '__ci_bb_517 {
        if (__local_escape__goto_3138_5 == 6) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_518
        }
    }

    '__ci_bb_518 {
        if (__local_escape__goto_3138_5 == 9) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_519
        }
    }

    '__ci_bb_519 {
        if (__local_escape__goto_3138_5 == 8) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_520
        }
    }

    '__ci_bb_520 {
        if (__local_escape__goto_3138_5 == 11) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_521
        }
    }

    '__ci_bb_521 {
        if (__local_escape__goto_3138_5 == 10) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_522
        }
    }

    '__ci_bb_522 {
        if (__local_escape__goto_3138_5 == 15) {
            goto '__ci_bb_492
        } else {
            goto '__ci_bb_523
        }
    }

    '__ci_bb_523 {
        if (__local_escape__goto_3138_5 == 16) {
            goto '__ci_bb_492
        } else {
            goto '__ci_bb_524
        }
    }

    '__ci_bb_524 {
        if (__local_escape__goto_3138_5 == 1) {
            goto '__ci_bb_503
        } else {
            goto '__ci_bb_525
        }
    }

    '__ci_bb_525 {
        if (__local_escape__goto_3138_5 == 23) {
            goto '__ci_bb_503
        } else {
            goto '__ci_bb_526
        }
    }

    '__ci_bb_526 {
        if (__local_escape__goto_3138_5 == 24) {
            goto '__ci_bb_503
        } else {
            goto '__ci_bb_527
        }
    }

    '__ci_bb_527 {
        if (__local_escape__goto_3138_5 == 2) {
            goto '__ci_bb_503
        } else {
            goto '__ci_bb_528
        }
    }

    '__ci_bb_528 {
        if (__local_escape__goto_3138_5 == 3) {
            goto '__ci_bb_503
        } else {
            goto '__ci_bb_529
        }
    }

    '__ci_bb_529 {
        if (__local_escape__goto_3138_5 == 14) {
            goto '__ci_bb_503
        } else {
            goto '__ci_bb_499
        }
    }

    '__ci_bb_530 {
        (__local_errorcode__goto_3137_5 = ERR50)
        goto '__ci_bb_19
    }

    '__ci_bb_531 {
        if ((if __local_class_range_state__goto_3118_10 == 3: 1 else: 0) != 0) {
            goto '__ci_bb_532
        } else {
            goto '__ci_bb_533
        }
    }

    '__ci_bb_532 {
        (__local_ptr = __local_class_range_forbid_ptr__goto_3151_12)
        (__local_errorcode__goto_3137_5 = ERR50)
        goto '__ci_bb_19
    }

    '__ci_bb_533 {
        (__ci_expr_logic_190 = 0)
        if ((if __local_class_op_state__goto_3119_10 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_190 = (if (if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_190 != 0) {
            goto '__ci_bb_534
        } else {
            goto '__ci_bb_535
        }
    }

    '__ci_bb_534 {
        (__local_errorcode__goto_3137_5 = ERR113)
        goto '__ci_bb_19
    }

    '__ci_bb_535 {
        (__local_class_range_state__goto_3118_10 = ((2 as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        goto '__ci_bb_459
    }

    '__ci_bb_536 {
        (__local_errorcode__goto_3137_5 = ERR116)
        goto '__ci_bb_19
    }

    '__ci_bb_537 {
        (__ci_expr_logic_191 = 0)
        if ((if __local_c__goto_3115_10 == 45: 1 else: 0) != 0) {
            (__ci_expr_logic_191 = (if (if __local_class_range_state__goto_3118_10 >= 4: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_191 != 0) {
            goto '__ci_bb_539
        } else {
            goto '__ci_bb_540
        }
    }

    '__ci_bb_538 {
        goto '__ci_bb_459
    }

    '__ci_bb_539 {
        (__ci_expr_old_192 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_192) = (((if (if __local_class_range_state__goto_3118_10 == 5: 1 else: 0) != 0: (2149777408 as u32) else: (2149711872 as u32)) as u32)))
        (__local_class_range_state__goto_3118_10 = ((1 as u32)))
        goto '__ci_bb_541
    }

    '__ci_bb_540 {
        (__ci_expr_logic_193 = 0)
        if ((if __local_c__goto_3115_10 == 45: 1 else: 0) != 0) {
            (__ci_expr_logic_193 = (if (if __local_class_range_state__goto_3118_10 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_193 != 0) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_543
        }
    }

    '__ci_bb_541 {
        goto '__ci_bb_538
    }

    '__ci_bb_542 {
        (__ci_expr_old_194 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_194) = ((45 as u32)))
        (__local_class_range_state__goto_3118_10 = ((3 as u32)))
        (__local_class_range_forbid_ptr__goto_3151_12 = __local_ptr)
        goto '__ci_bb_544
    }

    '__ci_bb_543 {
        goto '__ci_bb_288
    }

    '__ci_bb_544 {
        goto '__ci_bb_541
    }

    '__ci_bb_545 {
        (__local_errorcode__goto_3137_5 = ERR113)
        goto '__ci_bb_19
    }

    '__ci_bb_546 {
        if ((if __local_class_range_state__goto_3118_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_547
        } else {
            goto '__ci_bb_548
        }
    }

    '__ci_bb_547 {
        if ((if __local_c__goto_3115_10 == (__local_parsed_pattern__goto_3125_11[-2]): 1 else: 0) != 0) {
            goto '__ci_bb_550
        } else {
            goto '__ci_bb_551
        }
    }

    '__ci_bb_548 {
        if ((if __local_class_range_state__goto_3118_10 == 3: 1 else: 0) != 0) {
            goto '__ci_bb_558
        } else {
            goto '__ci_bb_559
        }
    }

    '__ci_bb_549 {
        goto '__ci_bb_544
    }

    '__ci_bb_550 {
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 - 1)
        goto '__ci_bb_552
    }

    '__ci_bb_551 {
        if ((if (__local_parsed_pattern__goto_3125_11[-2]) > __local_c__goto_3115_10: 1 else: 0) != 0) {
            goto '__ci_bb_553
        } else {
            goto '__ci_bb_554
        }
    }

    '__ci_bb_552 {
        (__local_class_range_state__goto_3118_10 = ((0 as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        goto '__ci_bb_549
    }

    '__ci_bb_553 {
        (__local_errorcode__goto_3137_5 = ERR8)
        goto '__ci_bb_19
    }

    '__ci_bb_554 {
        (__ci_expr_logic_196 = 0)
        if ((if not (__local_char_is_literal__goto_3974_12 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_196 = (if (if (__local_parsed_pattern__goto_3125_11[-1]) == 2149777408: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_196 != 0) {
            goto '__ci_bb_556
        } else {
            goto '__ci_bb_557
        }
    }

    '__ci_bb_555 {
        goto '__ci_bb_552
    }

    '__ci_bb_556 {
        ((__local_parsed_pattern__goto_3125_11[-1]) = ((2149711872 as u32)))
        goto '__ci_bb_557
    }

    '__ci_bb_557 {
        (__ci_expr_old_197 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_197) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_555
    }

    '__ci_bb_558 {
        (__local_ptr = __local_class_range_forbid_ptr__goto_3151_12)
        (__local_errorcode__goto_3137_5 = ERR50)
        goto '__ci_bb_19
    }

    '__ci_bb_559 {
        (__local_class_range_state__goto_3118_10 = (((if __local_char_is_literal__goto_3974_12 != 0: RANGE_OK_LITERAL else: RANGE_OK_ESCAPED) as u32)))
        (__local_class_op_state__goto_3119_10 = ((1 as u32)))
        (__ci_expr_old_198 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_198) = __local_c__goto_3115_10)
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_560
    }

    '__ci_bb_560 {
        goto '__ci_bb_549
    }

    '__ci_bb_561 {
        (__ci_expr_logic_199 = 0)
        if ((if __local_class_mode_state__goto_3120_10 == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_199 = (if (if __local_class_depth_m1__goto_3132_9 > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_199 != 0) {
            goto '__ci_bb_563
        } else {
            goto '__ci_bb_564
        }
    }

    '__ci_bb_562 {
        (__ci_expr_old_202 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_202) as u32)))
        (__ci_expr_logic_203 = 0)
        if (__local_utf__goto_3142_6 != 0) {
            (__ci_expr_logic_203 = (if (if __local_c__goto_3115_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_203 != 0) {
            goto '__ci_bb_568
        } else {
            goto '__ci_bb_569
        }
    }

    '__ci_bb_563 {
        (__local_errorcode__goto_3137_5 = ERR14)
        goto '__ci_bb_564
    }

    '__ci_bb_564 {
        (__ci_expr_logic_201 = 0)
        (__ci_expr_logic_200 = 0)
        if ((if __local_class_mode_state__goto_3120_10 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_200 = (if (if __local_class_depth_m1__goto_3132_9 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_200 != 0) {
            (__ci_expr_logic_201 = (if (if __local_class_maxdepth_m1__goto_3133_9 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_201 != 0) {
            goto '__ci_bb_565
        } else {
            goto '__ci_bb_566
        }
    }

    '__ci_bb_565 {
        (__local_errorcode__goto_3137_5 = ERR112)
        goto '__ci_bb_567
    }

    '__ci_bb_566 {
        (__local_errorcode__goto_3137_5 = ERR6)
        goto '__ci_bb_567
    }

    '__ci_bb_567 {
        goto '__ci_bb_19
    }

    '__ci_bb_568 {
        if ((if ((__local_c__goto_3115_10 as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_570
        } else {
            goto '__ci_bb_571
        }
    }

    '__ci_bb_569 {
        goto '__ci_bb_279
    }

    '__ci_bb_570 {
        (__ci_expr_old_204 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = ((((((((__local_c__goto_3115_10 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_204) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        goto '__ci_bb_572
    }

    '__ci_bb_571 {
        if ((if ((__local_c__goto_3115_10 as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_573
        } else {
            goto '__ci_bb_574
        }
    }

    '__ci_bb_572 {
        goto '__ci_bb_569
    }

    '__ci_bb_573 {
        (__local_c__goto_3115_10 = ((((((((((__local_c__goto_3115_10 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_575
    }

    '__ci_bb_574 {
        if ((if ((__local_c__goto_3115_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_576
        } else {
            goto '__ci_bb_577
        }
    }

    '__ci_bb_575 {
        goto '__ci_bb_572
    }

    '__ci_bb_576 {
        (__local_c__goto_3115_10 = ((((((((((((__local_c__goto_3115_10 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((3 as isize) as usize))
        goto '__ci_bb_578
    }

    '__ci_bb_577 {
        if ((if ((__local_c__goto_3115_10 as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_579
        } else {
            goto '__ci_bb_580
        }
    }

    '__ci_bb_578 {
        goto '__ci_bb_575
    }

    '__ci_bb_579 {
        (__local_c__goto_3115_10 = ((((((((((((((__local_c__goto_3115_10 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((4 as isize) as usize))
        goto '__ci_bb_581
    }

    '__ci_bb_580 {
        (__local_c__goto_3115_10 = ((((((((((((((((__local_c__goto_3115_10 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_ptr = __local_ptr + ((5 as isize) as usize))
        goto '__ci_bb_581
    }

    '__ci_bb_581 {
        goto '__ci_bb_578
    }

    '__ci_bb_582 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_583
        } else {
            goto '__ci_bb_584
        }
    }

    '__ci_bb_583 {
        goto '__ci_bb_585
    }

    '__ci_bb_584 {
        if ((if (*__local_ptr) != 63: 1 else: 0) != 0) {
            goto '__ci_bb_586
        } else {
            goto '__ci_bb_587
        }
    }

    '__ci_bb_585 {
        (__local_errorcode__goto_3137_5 = ERR14)
        goto '__ci_bb_19
    }

    '__ci_bb_586 {
        if ((if (*__local_ptr) != 42: 1 else: 0) != 0) {
            goto '__ci_bb_588
        } else {
            goto '__ci_bb_589
        }
    }

    '__ci_bb_587 {
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_678
        } else {
            goto '__ci_bb_679
        }
    }

    '__ci_bb_588 {
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        if ((if ((__local_options as u32) & (8192 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_591
        } else {
            goto '__ci_bb_592
        }
    }

    '__ci_bb_589 {
        if ((if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) <= 1: 1 else: 0) != 0) {
            (__ci_expr_logic_207 = (if true: 1 else: 0))
        } else {
            (__local_c__goto_3115_10 = (((__local_ptr[1]) as u32)))

            (__ci_expr_logic_207 = (if (if __local_c__goto_3115_10 == 41: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_207 != 0) {
            goto '__ci_bb_596
        } else {
            goto '__ci_bb_597
        }
    }

    '__ci_bb_590 {
        goto '__ci_bb_161
    }

    '__ci_bb_591 {
        if ((if (*__param_cb).bracount >= 65535: 1 else: 0) != 0) {
            goto '__ci_bb_594
        } else {
            goto '__ci_bb_595
        }
    }

    '__ci_bb_592 {
        (__ci_expr_old_206 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_206) = ((2149449728 as u32)))
        goto '__ci_bb_593
    }

    '__ci_bb_593 {
        goto '__ci_bb_590
    }

    '__ci_bb_594 {
        (__local_errorcode__goto_3137_5 = ERR97)
        goto '__ci_bb_19
    }

    '__ci_bb_595 {
        ((*__param_cb).bracount = ((*__param_cb).bracount +% 1))
        (__ci_expr_old_205 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_205) = ((((2148007936 as u32) | ((*__param_cb).bracount as u32)) as u32)))
        goto '__ci_bb_593
    }

    '__ci_bb_596 {
        goto '__ci_bb_161
    }

    '__ci_bb_597 {
        (__ci_expr_logic_208 = 0)
        if ((if __local_c__goto_3115_10 <= 255: 1 else: 0) != 0) {
            (__ci_expr_logic_208 = (if (if ((((*__param_cb).ctypes[__local_c__goto_3115_10]) as i32) & (4 as i32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_208 != 0) {
            goto '__ci_bb_599
        } else {
            goto '__ci_bb_600
        }
    }

    '__ci_bb_598 {
        goto '__ci_bb_590
    }

    '__ci_bb_599 {
        (__local_vn__goto_4725_19 = (&alasnames[0] as *const c_char))
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, (0 as u32), (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_603
        }
    }

    '__ci_bb_600 {
        (__local_vn__goto_4725_19 = (&verbnames[0] as *const c_char))
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, (0 as u32), (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_656
        } else {
            goto '__ci_bb_657
        }
    }

    '__ci_bb_601 {
        goto '__ci_bb_598
    }

    '__ci_bb_602 {
        goto '__ci_bb_19
    }

    '__ci_bb_603 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_604
        } else {
            goto '__ci_bb_605
        }
    }

    '__ci_bb_604 {
        goto '__ci_bb_585
    }

    '__ci_bb_605 {
        if ((if (*__local_ptr) != 58: 1 else: 0) != 0) {
            goto '__ci_bb_606
        } else {
            goto '__ci_bb_607
        }
    }

    '__ci_bb_606 {
        (__local_errorcode__goto_3137_5 = ERR95)
        goto '__ci_bb_608
    }

    '__ci_bb_607 {
        (__local_i__goto_3139_5 = ((0 as i32)))
        goto '__ci_bb_609
    }

    '__ci_bb_608 {
        (__local_ptr = __local_ptr + 1)
        if (__local_utf__goto_3142_6 != 0) {
            goto '__ci_bb_1019
        } else {
            goto '__ci_bb_1020
        }
    }

    '__ci_bb_609 {
        if ((if __local_i__goto_3139_5 < 19: 1 else: 0) != 0) {
            goto '__ci_bb_610
        } else {
            goto '__ci_bb_612
        }
    }

    '__ci_bb_610 {
        (__ci_expr_logic_209 = 0)
        if ((if __local_namelen__goto_3117_10 == alasmeta[__local_i__goto_3139_5].len: 1 else: 0) != 0) {
            (__ci_expr_logic_209 = (if (if _pcre2_strncmp_c8_8(__local_name__goto_3148_12, __local_vn__goto_4725_19, (__local_namelen__goto_3117_10 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_209 != 0) {
            goto '__ci_bb_613
        } else {
            goto '__ci_bb_614
        }
    }

    '__ci_bb_611 {
        (__local_i__goto_3139_5 = __local_i__goto_3139_5 + 1)
        goto '__ci_bb_609
    }

    '__ci_bb_612 {
        if ((if __local_i__goto_3139_5 >= 19: 1 else: 0) != 0) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_616
        }
    }

    '__ci_bb_613 {
        goto '__ci_bb_612
    }

    '__ci_bb_614 {
        (__local_vn__goto_4725_19 = __local_vn__goto_4725_19 + (((alasmeta[__local_i__goto_3139_5].len as u32) +% (1 as u32)) as usize))
        goto '__ci_bb_611
    }

    '__ci_bb_615 {
        (__local_errorcode__goto_3137_5 = ERR95)
        goto '__ci_bb_19
    }

    '__ci_bb_616 {
        (__local_meta__goto_4760_18 = alasmeta[__local_i__goto_3139_5].meta)
        (__ci_expr_logic_211 = 0)
        if ((if __local_prev_expect_cond_assert__goto_3228_7 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_210: i32

            if ((if __local_meta__goto_4760_18 < 2150039552: 1 else: 0) != 0) {
                (__ci_expr_logic_210 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_210 = (if (if __local_meta__goto_4760_18 > 2150236160: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_211 = (if __ci_expr_logic_210 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_211 != 0) {
            goto '__ci_bb_617
        } else {
            goto '__ci_bb_618
        }
    }

    '__ci_bb_617 {
        (__local_errorcode__goto_3137_5 = ERR28)
        goto '__ci_bb_19
    }

    '__ci_bb_618 {
        goto '__ci_bb_619
    }

    '__ci_bb_619 {
        if (__local_meta__goto_4760_18 == 2147614720) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_647
        }
    }

    '__ci_bb_620 {
        goto '__ci_bb_601
    }

    '__ci_bb_621 {
        goto '__ci_bb_622
    }

    '__ci_bb_622 {
        goto '__ci_bb_623
    }

    '__ci_bb_623 {
        if (0 != 0) {
            goto '__ci_bb_622
        } else {
            goto '__ci_bb_624
        }
    }

    '__ci_bb_624 {
        (__local_errorcode__goto_3137_5 = ERR89)
        goto '__ci_bb_19
    }

    '__ci_bb_625 {
        goto '__ci_bb_626
    }

    '__ci_bb_626 {
        (__ci_expr_old_305 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_305) = ((2147614720 as u32)))
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_681
    }

    '__ci_bb_627 {
        goto '__ci_bb_628
    }

    '__ci_bb_628 {
        (__ci_expr_old_306 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_306) = ((2150039552 as u32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_636
    }

    '__ci_bb_629 {
        goto '__ci_bb_630
    }

    '__ci_bb_630 {
        (__ci_expr_old_307 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_307) = ((2150301696 as u32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_636
    }

    '__ci_bb_631 {
        goto '__ci_bb_632
    }

    '__ci_bb_632 {
        (__ci_expr_old_308 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_308) = ((2150105088 as u32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_636
    }

    '__ci_bb_633 {
        (__local_ptr = __local_ptr + 1)
        (__ci_expr_old_212 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_212) = ((2148990976 as u32)))
        (__local_parsed_pattern__goto_3125_11 = parse_capture_list((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, __local_parsed_pattern__goto_3125_11, (0 as u64), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb))
        if ((if __local_parsed_pattern__goto_3125_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_634
        } else {
            goto '__ci_bb_635
        }
    }

    '__ci_bb_634 {
        goto '__ci_bb_19
    }

    '__ci_bb_635 {
        goto '__ci_bb_636
    }

    '__ci_bb_636 {
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        if ((if __local_prev_expect_cond_assert__goto_3228_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_899
        } else {
            goto '__ci_bb_900
        }
    }

    '__ci_bb_637 {
        (__ci_expr_old_213 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_213) = __local_meta__goto_4760_18)
        (__local_ptr = __local_ptr - 1)
        goto '__ci_bb_638
    }

    '__ci_bb_638 {
        ((*__param_has_lookbehind) = ((1 as i32)))
        (__local_offset__goto_3236_14 = (((((((__local_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) - 2) as u64)))
        (__ci_expr_old_313 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_313) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_314 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_314) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        (__local_ptr = __local_ptr + ((2 as isize) as usize))
        goto '__ci_bb_636
    }

    '__ci_bb_639 {
        (__ci_expr_old_214 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_214) = ((2149974016 as u32)))
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        (__local_ptr = __local_ptr + 1)
        if ((if __local_meta__goto_4760_18 == 2415853568: 1 else: 0) != 0) {
            goto '__ci_bb_640
        } else {
            goto '__ci_bb_641
        }
    }

    '__ci_bb_640 {
        (__ci_expr_old_215 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_215) = ((2147614720 as u32)))
        if ((if __local_top_nest__goto_3153_12 == null: 1 else: 0) != 0) {
            goto '__ci_bb_642
        } else {
            goto '__ci_bb_643
        }
    }

    '__ci_bb_641 {
        goto '__ci_bb_620
    }

    '__ci_bb_642 {
        (__local_top_nest__goto_3153_12 = (((*__param_cb).start_workspace as *mut nest_save)))
        goto '__ci_bb_644
    }

    '__ci_bb_643 {
        (__local_top_nest__goto_3153_12 = __local_top_nest__goto_3153_12 + 1)
        if ((if __local_top_nest__goto_3153_12 >= __local_end_nests__goto_3153_23: 1 else: 0) != 0) {
            goto '__ci_bb_645
        } else {
            goto '__ci_bb_646
        }
    }

    '__ci_bb_644 {
        ((*__local_top_nest__goto_3153_12).nest_depth = __local_nest_depth__goto_3131_10)
        ((*__local_top_nest__goto_3153_12).flags = ((4 as u16)))
        ((*__local_top_nest__goto_3153_12).options = ((((__local_options as u32) & (((((((((((((((8 as u32) | (32 as u32)) as u32) | (64 as u32)) as u32) | (128 as u32)) as u32) | (16777216 as u32)) as u32) | (1024 as u32)) as u32) | (8192 as u32)) as u32) | (262144 as u32)) as u32)) as u32)))
        ((*__local_top_nest__goto_3153_12).xoptions = ((((__local_xoptions as u32) & (((((((((((128 as u32) | (256 as u32)) as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (4096 as u32)) as u32) | (2048 as u32)) as u32)) as u32)))
        goto '__ci_bb_641
    }

    '__ci_bb_645 {
        (__local_errorcode__goto_3137_5 = ERR84)
        goto '__ci_bb_19
    }

    '__ci_bb_646 {
        goto '__ci_bb_644
    }

    '__ci_bb_647 {
        if (__local_meta__goto_4760_18 == 2150039552) {
            goto '__ci_bb_627
        } else {
            goto '__ci_bb_648
        }
    }

    '__ci_bb_648 {
        if (__local_meta__goto_4760_18 == 2150301696) {
            goto '__ci_bb_629
        } else {
            goto '__ci_bb_649
        }
    }

    '__ci_bb_649 {
        if (__local_meta__goto_4760_18 == 2150105088) {
            goto '__ci_bb_631
        } else {
            goto '__ci_bb_650
        }
    }

    '__ci_bb_650 {
        if (__local_meta__goto_4760_18 == 2148990976) {
            goto '__ci_bb_633
        } else {
            goto '__ci_bb_651
        }
    }

    '__ci_bb_651 {
        if (__local_meta__goto_4760_18 == 2150170624) {
            goto '__ci_bb_637
        } else {
            goto '__ci_bb_652
        }
    }

    '__ci_bb_652 {
        if (__local_meta__goto_4760_18 == 2150236160) {
            goto '__ci_bb_637
        } else {
            goto '__ci_bb_653
        }
    }

    '__ci_bb_653 {
        if (__local_meta__goto_4760_18 == 2150367232) {
            goto '__ci_bb_637
        } else {
            goto '__ci_bb_654
        }
    }

    '__ci_bb_654 {
        if (__local_meta__goto_4760_18 == 2149974016) {
            goto '__ci_bb_639
        } else {
            goto '__ci_bb_655
        }
    }

    '__ci_bb_655 {
        if (__local_meta__goto_4760_18 == 2415853568) {
            goto '__ci_bb_639
        } else {
            goto '__ci_bb_621
        }
    }

    '__ci_bb_656 {
        goto '__ci_bb_19
    }

    '__ci_bb_657 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_217 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_216: i32 = 0

            if ((if (*__local_ptr) != 58: 1 else: 0) != 0) {
                (__ci_expr_logic_216 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_217 = (if __ci_expr_logic_216 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_217 != 0) {
            goto '__ci_bb_658
        } else {
            goto '__ci_bb_659
        }
    }

    '__ci_bb_658 {
        (__local_errorcode__goto_3137_5 = ERR60)
        goto '__ci_bb_19
    }

    '__ci_bb_659 {
        (__local_i__goto_3139_5 = ((0 as i32)))
        goto '__ci_bb_660
    }

    '__ci_bb_660 {
        if ((if __local_i__goto_3139_5 < 9: 1 else: 0) != 0) {
            goto '__ci_bb_661
        } else {
            goto '__ci_bb_663
        }
    }

    '__ci_bb_661 {
        (__ci_expr_logic_218 = 0)
        if ((if __local_namelen__goto_3117_10 == verbs[__local_i__goto_3139_5].len: 1 else: 0) != 0) {
            (__ci_expr_logic_218 = (if (if _pcre2_strncmp_c8_8(__local_name__goto_3148_12, __local_vn__goto_4725_19, (__local_namelen__goto_3117_10 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_218 != 0) {
            goto '__ci_bb_664
        } else {
            goto '__ci_bb_665
        }
    }

    '__ci_bb_662 {
        (__local_i__goto_3139_5 = __local_i__goto_3139_5 + 1)
        goto '__ci_bb_660
    }

    '__ci_bb_663 {
        if ((if __local_i__goto_3139_5 >= 9: 1 else: 0) != 0) {
            goto '__ci_bb_666
        } else {
            goto '__ci_bb_667
        }
    }

    '__ci_bb_664 {
        goto '__ci_bb_663
    }

    '__ci_bb_665 {
        (__local_vn__goto_4725_19 = __local_vn__goto_4725_19 + (((verbs[__local_i__goto_3139_5].len as u32) +% (1 as u32)) as usize))
        goto '__ci_bb_662
    }

    '__ci_bb_666 {
        (__local_errorcode__goto_3137_5 = ERR60)
        goto '__ci_bb_19
    }

    '__ci_bb_667 {
        (__ci_expr_logic_220 = 0)
        (__ci_expr_logic_219 = 0)
        if ((if (*__local_ptr) == 58: 1 else: 0) != 0) {
            (__ci_expr_logic_219 = (if (if (__local_ptr + ((1 as isize) as usize)) < __local_ptrend__goto_3149_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_219 != 0) {
            (__ci_expr_logic_220 = (if (if (__local_ptr[1]) == 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_220 != 0) {
            goto '__ci_bb_668
        } else {
            goto '__ci_bb_669
        }
    }

    '__ci_bb_668 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_669
    }

    '__ci_bb_669 {
        (__ci_expr_logic_221 = 0)
        if ((if verbs[__local_i__goto_3139_5].has_arg > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_221 = (if (if (*__local_ptr) != 58: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_221 != 0) {
            goto '__ci_bb_670
        } else {
            goto '__ci_bb_671
        }
    }

    '__ci_bb_670 {
        (__local_errorcode__goto_3137_5 = ERR66)
        goto '__ci_bb_19
    }

    '__ci_bb_671 {
        (__local_verbstartptr__goto_3123_11 = __local_parsed_pattern__goto_3125_11)
        (__local_okquantifier__goto_3146_6 = (((if verbs[__local_i__goto_3139_5].meta == 2150498304: 1 else: 0) as i32)))
        (__ci_expr_old_222 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        if ((if (*__ci_expr_old_222) == 58: 1 else: 0) != 0) {
            goto '__ci_bb_672
        } else {
            goto '__ci_bb_673
        }
    }

    '__ci_bb_672 {
        if ((if verbs[__local_i__goto_3139_5].has_arg < 0: 1 else: 0) != 0) {
            goto '__ci_bb_675
        } else {
            goto '__ci_bb_676
        }
    }

    '__ci_bb_673 {
        (__ci_expr_old_226 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_226) = verbs[__local_i__goto_3139_5].meta)
        goto '__ci_bb_674
    }

    '__ci_bb_674 {
        goto '__ci_bb_601
    }

    '__ci_bb_675 {
        (__local_add_after_mark__goto_3130_10 = verbs[__local_i__goto_3139_5].meta)
        (__ci_expr_old_223 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_223) = ((2150432768 as u32)))
        goto '__ci_bb_677
    }

    '__ci_bb_676 {
        (__ci_expr_old_224 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_224) = ((((verbs[__local_i__goto_3139_5].meta as u32) +% ((if (if verbs[__local_i__goto_3139_5].meta != 2150432768: 1 else: 0) != 0: (65536 as u32) else: (0 as u32)) as u32)) as u32)))
        goto '__ci_bb_677
    }

    '__ci_bb_677 {
        (__ci_expr_old_225 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        (__local_verblengthptr__goto_3122_11 = __ci_expr_old_225)
        (__local_verbnamestart__goto_3150_12 = __local_ptr)
        (__local_inverbname__goto_3141_6 = ((1 as i32)))
        goto '__ci_bb_674
    }

    '__ci_bb_678 {
        goto '__ci_bb_585
    }

    '__ci_bb_679 {
        goto '__ci_bb_680
    }

    '__ci_bb_680 {
        if ((*__local_ptr) == 80) {
            goto '__ci_bb_749
        } else {
            goto '__ci_bb_945
        }
    }

    '__ci_bb_681 {
        goto '__ci_bb_161
    }

    '__ci_bb_682 {
        (__ci_expr_logic_229 = 0)
        (__ci_expr_logic_227 = 0)
        if ((if (*__local_ptr) == 45: 1 else: 0) != 0) {
            (__ci_expr_logic_227 = (if (if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) > 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_227 != 0) {
            var __ci_expr_logic_228: i32 = 0

            if ((if (__local_ptr[1]) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_228 = (if (if (__local_ptr[1]) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_229 = (if __ci_expr_logic_228 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_229 != 0) {
            goto '__ci_bb_683
        } else {
            goto '__ci_bb_684
        }
    }

    '__ci_bb_683 {
        goto '__ci_bb_685
    }

    '__ci_bb_684 {
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        if ((if __local_top_nest__goto_3153_12 == null: 1 else: 0) != 0) {
            goto '__ci_bb_686
        } else {
            goto '__ci_bb_687
        }
    }

    '__ci_bb_685 {
        (__ci_expr_ternary_253 = 0)
        (__ci_expr_logic_252 = 0)
        if ((if (*__local_ptr) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_252 = (if (if (*__local_ptr) <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_252 != 0) {
            (__ci_expr_ternary_253 = ((-1 as i32)))
        } else {
            (__ci_expr_ternary_253 = (((*__param_cb).bracount as i32)))
        }
        if ((if not (read_number((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __ci_expr_ternary_253, (65535 as u32), (161 as u32), (&raw mut __local_i__goto_3139_5 as *mut i32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_771
        } else {
            goto '__ci_bb_772
        }
    }

    '__ci_bb_686 {
        (__local_top_nest__goto_3153_12 = (((*__param_cb).start_workspace as *mut nest_save)))
        goto '__ci_bb_688
    }

    '__ci_bb_687 {
        (__local_top_nest__goto_3153_12 = __local_top_nest__goto_3153_12 + 1)
        if ((if __local_top_nest__goto_3153_12 >= __local_end_nests__goto_3153_23: 1 else: 0) != 0) {
            goto '__ci_bb_689
        } else {
            goto '__ci_bb_690
        }
    }

    '__ci_bb_688 {
        ((*__local_top_nest__goto_3153_12).nest_depth = __local_nest_depth__goto_3131_10)
        ((*__local_top_nest__goto_3153_12).flags = ((0 as u16)))
        ((*__local_top_nest__goto_3153_12).options = ((((__local_options as u32) & (((((((((((((((8 as u32) | (32 as u32)) as u32) | (64 as u32)) as u32) | (128 as u32)) as u32) | (16777216 as u32)) as u32) | (1024 as u32)) as u32) | (8192 as u32)) as u32) | (262144 as u32)) as u32)) as u32)))
        ((*__local_top_nest__goto_3153_12).xoptions = ((((__local_xoptions as u32) & (((((((((((128 as u32) | (256 as u32)) as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (4096 as u32)) as u32) | (2048 as u32)) as u32)) as u32)))
        if ((if (*__local_ptr) == 124: 1 else: 0) != 0) {
            goto '__ci_bb_691
        } else {
            goto '__ci_bb_692
        }
    }

    '__ci_bb_689 {
        (__local_errorcode__goto_3137_5 = ERR84)
        goto '__ci_bb_19
    }

    '__ci_bb_690 {
        goto '__ci_bb_688
    }

    '__ci_bb_691 {
        ((*__local_top_nest__goto_3153_12).reset_group = (((*__param_cb).bracount as u16)))
        ((*__local_top_nest__goto_3153_12).max_group = (((*__param_cb).bracount as u16)))
        ((*__local_top_nest__goto_3153_12).flags = ((*__local_top_nest__goto_3153_12).flags as u16) | (1 as u16))
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (2097152 as u32))
        (__ci_expr_old_230 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_230) = ((2149449728 as u32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_693
    }

    '__ci_bb_692 {
        (__local_hyphenok__goto_5025_14 = ((1 as i32)))
        (__local_oldoptions__goto_5026_18 = __local_options)
        (__local_oldxoptions__goto_5027_18 = __local_xoptions)
        ((*__local_top_nest__goto_3153_12).reset_group = ((0 as u16)))
        ((*__local_top_nest__goto_3153_12).max_group = ((0 as u16)))
        (__local_unset__goto_3230_17 = ((0 as u32)))
        (__local_set__goto_3230_12 = __local_unset__goto_3230_17)
        (__local_optset__goto_3230_25 = ((&raw mut __local_set__goto_3230_12 as *mut u32)))
        (__local_xunset__goto_3231_18 = ((0 as u32)))
        (__local_xset__goto_3231_12 = __local_xunset__goto_3231_18)
        (__local_xoptset__goto_3231_27 = ((&raw mut __local_xset__goto_3231_12 as *mut u32)))
        (__ci_expr_logic_231 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_231 = (if (if (*__local_ptr) == 94: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_231 != 0) {
            goto '__ci_bb_694
        } else {
            goto '__ci_bb_695
        }
    }

    '__ci_bb_693 {
        goto '__ci_bb_681
    }

    '__ci_bb_694 {
        (__local_options = (__local_options as u32) & ((~((((((((((8 as u32) | (1024 as u32)) as u32) | (8192 as u32)) as u32) | (32 as u32)) as u32) | (128 as u32)) as u32) | (16777216 as u32))) as u32))
        (__local_xoptions = (__local_xoptions as u32) & ((~128) as u32))
        (__local_hyphenok__goto_5025_14 = ((0 as i32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_695
    }

    '__ci_bb_695 {
        goto '__ci_bb_696
    }

    '__ci_bb_696 {
        (__ci_expr_logic_233 = 0)
        (__ci_expr_logic_232 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_232 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_232 != 0) {
            (__ci_expr_logic_233 = (if (if (*__local_ptr) != 58: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_233 != 0) {
            goto '__ci_bb_697
        } else {
            goto '__ci_bb_698
        }
    }

    '__ci_bb_697 {
        (__ci_expr_old_234 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__ci_expr_switch_235 = (*__ci_expr_old_234))
        goto '__ci_bb_699
    }

    '__ci_bb_698 {
        if ((if ((__local_set__goto_3230_12 as u32) & (((128 as u32) | (16777216 as u32)) as u32)) == 128: 1 else: 0) != 0) {
            (__ci_expr_logic_237 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_237 = (if (if ((__local_unset__goto_3230_17 as u32) & (128 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_237 != 0) {
            goto '__ci_bb_737
        } else {
            goto '__ci_bb_738
        }
    }

    '__ci_bb_699 {
        if (__ci_expr_switch_235 == 45) {
            goto '__ci_bb_701
        } else {
            goto '__ci_bb_728
        }
    }

    '__ci_bb_700 {
        goto '__ci_bb_696
    }

    '__ci_bb_701 {
        if ((if not (__local_hyphenok__goto_5025_14 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_702
        } else {
            goto '__ci_bb_703
        }
    }

    '__ci_bb_702 {
        (__local_errorcode__goto_3137_5 = ERR94)
        goto '__ci_bb_19
    }

    '__ci_bb_703 {
        (__local_optset__goto_3230_25 = ((&raw mut __local_unset__goto_3230_17 as *mut u32)))
        (__local_xoptset__goto_3231_27 = ((&raw mut __local_xunset__goto_3231_18 as *mut u32)))
        (__local_hyphenok__goto_5025_14 = ((0 as i32)))
        goto '__ci_bb_700
    }

    '__ci_bb_704 {
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_705
        } else {
            goto '__ci_bb_706
        }
    }

    '__ci_bb_705 {
        if ((if (*__local_ptr) == 68: 1 else: 0) != 0) {
            goto '__ci_bb_707
        } else {
            goto '__ci_bb_708
        }
    }

    '__ci_bb_706 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (((((((((256 as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (4096 as u32)) as u32) | (2048 as u32)) as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_707 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (256 as u32))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_700
    }

    '__ci_bb_708 {
        if ((if (*__local_ptr) == 80: 1 else: 0) != 0) {
            goto '__ci_bb_709
        } else {
            goto '__ci_bb_710
        }
    }

    '__ci_bb_709 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (((2048 as u32) | (4096 as u32)) as u32))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_700
    }

    '__ci_bb_710 {
        if ((if (*__local_ptr) == 83: 1 else: 0) != 0) {
            goto '__ci_bb_711
        } else {
            goto '__ci_bb_712
        }
    }

    '__ci_bb_711 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (512 as u32))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_700
    }

    '__ci_bb_712 {
        if ((if (*__local_ptr) == 84: 1 else: 0) != 0) {
            goto '__ci_bb_713
        } else {
            goto '__ci_bb_714
        }
    }

    '__ci_bb_713 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (4096 as u32))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_700
    }

    '__ci_bb_714 {
        if ((if (*__local_ptr) == 87: 1 else: 0) != 0) {
            goto '__ci_bb_715
        } else {
            goto '__ci_bb_716
        }
    }

    '__ci_bb_715 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (1024 as u32))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_700
    }

    '__ci_bb_716 {
        goto '__ci_bb_706
    }

    '__ci_bb_717 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (64 as u32))
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (1024 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_718 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (8 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_719 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (1024 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_720 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (8192 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_721 {
        ((*__local_xoptset__goto_3231_27) = ((*__local_xoptset__goto_3231_27) as u32) | (128 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_722 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (32 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_723 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (262144 as u32))
        goto '__ci_bb_700
    }

    '__ci_bb_724 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (128 as u32))
        (__ci_expr_logic_236 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_236 = (if (if (*__local_ptr) == 120: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_236 != 0) {
            goto '__ci_bb_725
        } else {
            goto '__ci_bb_726
        }
    }

    '__ci_bb_725 {
        ((*__local_optset__goto_3230_25) = ((*__local_optset__goto_3230_25) as u32) | (16777216 as u32))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_726
    }

    '__ci_bb_726 {
        goto '__ci_bb_700
    }

    '__ci_bb_727 {
        (__local_errorcode__goto_3137_5 = ERR11)
        goto '__ci_bb_19
    }

    '__ci_bb_728 {
        if (__ci_expr_switch_235 == 97) {
            goto '__ci_bb_704
        } else {
            goto '__ci_bb_729
        }
    }

    '__ci_bb_729 {
        if (__ci_expr_switch_235 == 74) {
            goto '__ci_bb_717
        } else {
            goto '__ci_bb_730
        }
    }

    '__ci_bb_730 {
        if (__ci_expr_switch_235 == 105) {
            goto '__ci_bb_718
        } else {
            goto '__ci_bb_731
        }
    }

    '__ci_bb_731 {
        if (__ci_expr_switch_235 == 109) {
            goto '__ci_bb_719
        } else {
            goto '__ci_bb_732
        }
    }

    '__ci_bb_732 {
        if (__ci_expr_switch_235 == 110) {
            goto '__ci_bb_720
        } else {
            goto '__ci_bb_733
        }
    }

    '__ci_bb_733 {
        if (__ci_expr_switch_235 == 114) {
            goto '__ci_bb_721
        } else {
            goto '__ci_bb_734
        }
    }

    '__ci_bb_734 {
        if (__ci_expr_switch_235 == 115) {
            goto '__ci_bb_722
        } else {
            goto '__ci_bb_735
        }
    }

    '__ci_bb_735 {
        if (__ci_expr_switch_235 == 85) {
            goto '__ci_bb_723
        } else {
            goto '__ci_bb_736
        }
    }

    '__ci_bb_736 {
        if (__ci_expr_switch_235 == 120) {
            goto '__ci_bb_724
        } else {
            goto '__ci_bb_727
        }
    }

    '__ci_bb_737 {
        (__local_unset__goto_3230_17 = (__local_unset__goto_3230_17 as u32) | (16777216 as u32))
        goto '__ci_bb_738
    }

    '__ci_bb_738 {
        (__local_options = ((((((__local_options as u32) | (__local_set__goto_3230_12 as u32)) as u32) & ((~__local_unset__goto_3230_17) as u32)) as u32)))
        (__local_xoptions = ((((((__local_xoptions as u32) | (__local_xset__goto_3231_12 as u32)) as u32) & ((~__local_xunset__goto_3231_18) as u32)) as u32)))
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_739
        } else {
            goto '__ci_bb_740
        }
    }

    '__ci_bb_739 {
        goto '__ci_bb_585
    }

    '__ci_bb_740 {
        (__ci_expr_old_238 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        if ((if (*__ci_expr_old_238) == 41: 1 else: 0) != 0) {
            goto '__ci_bb_741
        } else {
            goto '__ci_bb_742
        }
    }

    '__ci_bb_741 {
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 -% 1))
        (__ci_expr_logic_239 = 0)
        if ((if __local_top_nest__goto_3153_12 > (((*__param_cb).start_workspace as *mut nest_save)): 1 else: 0) != 0) {
            (__ci_expr_logic_239 = (if (if (__local_top_nest__goto_3153_12 - ((1 as isize) as usize)).nest_depth == __local_nest_depth__goto_3131_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_239 != 0) {
            goto '__ci_bb_744
        } else {
            goto '__ci_bb_745
        }
    }

    '__ci_bb_742 {
        (__ci_expr_old_240 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_240) = ((2149449728 as u32)))
        goto '__ci_bb_743
    }

    '__ci_bb_743 {
        if ((if __local_options != __local_oldoptions__goto_5026_18: 1 else: 0) != 0) {
            (__ci_expr_logic_241 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_241 = (if (if __local_xoptions != __local_oldxoptions__goto_5027_18: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_241 != 0) {
            goto '__ci_bb_747
        } else {
            goto '__ci_bb_748
        }
    }

    '__ci_bb_744 {
        (__local_top_nest__goto_3153_12 = __local_top_nest__goto_3153_12 - 1)
        goto '__ci_bb_746
    }

    '__ci_bb_745 {
        ((*__local_top_nest__goto_3153_12).nest_depth = __local_nest_depth__goto_3131_10)
        goto '__ci_bb_746
    }

    '__ci_bb_746 {
        goto '__ci_bb_743
    }

    '__ci_bb_747 {
        (__ci_expr_old_242 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_242) = ((2149515264 as u32)))
        (__ci_expr_old_243 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_243) = __local_options)
        (__ci_expr_old_244 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_244) = __local_xoptions)
        goto '__ci_bb_748
    }

    '__ci_bb_748 {
        goto '__ci_bb_693
    }

    '__ci_bb_749 {
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_750
        } else {
            goto '__ci_bb_751
        }
    }

    '__ci_bb_750 {
        goto '__ci_bb_585
    }

    '__ci_bb_751 {
        if ((if (*__local_ptr) == 60: 1 else: 0) != 0) {
            goto '__ci_bb_752
        } else {
            goto '__ci_bb_753
        }
    }

    '__ci_bb_752 {
        (__local_terminator__goto_3232_12 = ((62 as u32)))
        goto '__ci_bb_754
    }

    '__ci_bb_753 {
        if ((if (*__local_ptr) == 62: 1 else: 0) != 0) {
            goto '__ci_bb_755
        } else {
            goto '__ci_bb_756
        }
    }

    '__ci_bb_754 {
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, __local_terminator__goto_3232_12, (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_907
        } else {
            goto '__ci_bb_908
        }
    }

    '__ci_bb_755 {
        goto '__ci_bb_757
    }

    '__ci_bb_756 {
        if ((if (*__local_ptr) != 61: 1 else: 0) != 0) {
            goto '__ci_bb_758
        } else {
            goto '__ci_bb_759
        }
    }

    '__ci_bb_757 {
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, (0 as u32), (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_778
        } else {
            goto '__ci_bb_779
        }
    }

    '__ci_bb_758 {
        (__local_errorcode__goto_3137_5 = ERR41)
        goto '__ci_bb_608
    }

    '__ci_bb_759 {
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, (41 as u32), (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_760
        } else {
            goto '__ci_bb_761
        }
    }

    '__ci_bb_760 {
        goto '__ci_bb_19
    }

    '__ci_bb_761 {
        (__ci_expr_old_245 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_245) = ((2147745792 as u32)))
        (__ci_expr_old_246 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_246) = __local_namelen__goto_3117_10)
        (__ci_expr_old_247 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_247) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_248 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_248) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        goto '__ci_bb_681
    }

    '__ci_bb_762 {
        (__local_i__goto_3139_5 = ((0 as i32)))
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_250 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_249: i32 = 0

            if ((if (*__local_ptr) != 41: 1 else: 0) != 0) {
                (__ci_expr_logic_249 = (if (if (*__local_ptr) != 40: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_250 = (if __ci_expr_logic_249 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_250 != 0) {
            goto '__ci_bb_763
        } else {
            goto '__ci_bb_764
        }
    }

    '__ci_bb_763 {
        (__local_errorcode__goto_3137_5 = ERR58)
        goto '__ci_bb_19
    }

    '__ci_bb_764 {
        (__local_terminator__goto_3232_12 = ((0 as u32)))
        goto '__ci_bb_220
    }

    '__ci_bb_765 {
        if ((if (__local_ptr + ((1 as isize) as usize)) >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_766
        } else {
            goto '__ci_bb_767
        }
    }

    '__ci_bb_766 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_585
    }

    '__ci_bb_767 {
        (__ci_expr_logic_251 = 0)
        if ((if (__local_ptr[1]) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_251 = (if (if (__local_ptr[1]) <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_251 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_768
        } else {
            goto '__ci_bb_769
        }
    }

    '__ci_bb_768 {
        (__local_errorcode__goto_3137_5 = ERR29)
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_608
    }

    '__ci_bb_769 {
        goto '__ci_bb_770
    }

    '__ci_bb_770 {
        goto '__ci_bb_685
    }

    '__ci_bb_771 {
        goto '__ci_bb_19
    }

    '__ci_bb_772 {
        goto '__ci_bb_773
    }

    '__ci_bb_773 {
        goto '__ci_bb_774
    }

    '__ci_bb_774 {
        if (0 != 0) {
            goto '__ci_bb_773
        } else {
            goto '__ci_bb_775
        }
    }

    '__ci_bb_775 {
        (__local_terminator__goto_3232_12 = ((0 as u32)))
        goto '__ci_bb_220
    }

    '__ci_bb_776 {
        (__ci_expr_old_257 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_257) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_258 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_258) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        if ((if __local_terminator__goto_3232_12 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_780
        } else {
            goto '__ci_bb_781
        }
    }

    '__ci_bb_777 {
        goto '__ci_bb_757
    }

    '__ci_bb_778 {
        goto '__ci_bb_19
    }

    '__ci_bb_779 {
        (__ci_expr_old_255 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_255) = ((2149908480 as u32)))
        (__ci_expr_old_256 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_256) = __local_namelen__goto_3117_10)
        (__local_terminator__goto_3232_12 = ((0 as u32)))
        goto '__ci_bb_776
    }

    '__ci_bb_780 {
        goto '__ci_bb_681
    }

    '__ci_bb_781 {
        (__ci_expr_logic_259 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_259 = (if (if (*__local_ptr) == 40: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_259 != 0) {
            goto '__ci_bb_782
        } else {
            goto '__ci_bb_783
        }
    }

    '__ci_bb_782 {
        (__local_parsed_pattern__goto_3125_11 = parse_capture_list((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, __local_parsed_pattern__goto_3125_11, __local_offset__goto_3236_14, (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb))
        if ((if __local_parsed_pattern__goto_3125_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_784
        } else {
            goto '__ci_bb_785
        }
    }

    '__ci_bb_783 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_260 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_260 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_260 != 0) {
            goto '__ci_bb_786
        } else {
            goto '__ci_bb_787
        }
    }

    '__ci_bb_784 {
        goto '__ci_bb_19
    }

    '__ci_bb_785 {
        goto '__ci_bb_783
    }

    '__ci_bb_786 {
        goto '__ci_bb_585
    }

    '__ci_bb_787 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_681
    }

    '__ci_bb_788 {
        if ((if ((__local_xoptions as u32) & (32768 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_789
        } else {
            goto '__ci_bb_790
        }
    }

    '__ci_bb_789 {
        (__local_ptr = __local_ptr + 1)
        (__local_errorcode__goto_3137_5 = ERR103)
        goto '__ci_bb_19
    }

    '__ci_bb_790 {
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_791
        } else {
            goto '__ci_bb_792
        }
    }

    '__ci_bb_791 {
        goto '__ci_bb_585
    }

    '__ci_bb_792 {
        (__local_expect_cond_assert__goto_3136_5 = (((__local_prev_expect_cond_assert__goto_3228_7 - 1) as i32)))
        (__ci_expr_logic_263 = 0)
        (__ci_expr_logic_262 = 0)
        (__ci_expr_logic_261 = 0)
        if ((if __local_previous_callout__goto_3124_11 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_261 = (if (if ((__local_options as u32) & (4 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_261 != 0) {
            (__ci_expr_logic_262 = (if (if __local_previous_callout__goto_3124_11 == (__local_parsed_pattern__goto_3125_11 - ((4 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_262 != 0) {
            (__ci_expr_logic_263 = (if (if (__local_parsed_pattern__goto_3125_11[-1]) == 255: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_263 != 0) {
            goto '__ci_bb_793
        } else {
            goto '__ci_bb_794
        }
    }

    '__ci_bb_793 {
        (__local_parsed_pattern__goto_3125_11 = __local_previous_callout__goto_3124_11)
        goto '__ci_bb_794
    }

    '__ci_bb_794 {
        (__local_previous_callout__goto_3124_11 = __local_parsed_pattern__goto_3125_11)
        (__local_after_manual_callout__goto_3135_5 = ((1 as i32)))
        (__ci_expr_logic_265 = 0)
        if ((if (*__local_ptr) != 41: 1 else: 0) != 0) {
            var __ci_expr_logic_264: i32 = 0

            if ((if (*__local_ptr) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_264 = (if (if (*__local_ptr) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_265 = (if (if not (__ci_expr_logic_264 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_265 != 0) {
            goto '__ci_bb_795
        } else {
            goto '__ci_bb_796
        }
    }

    '__ci_bb_795 {
        (__local_startptr__goto_5329_20 = __local_ptr)
        (__local_delimiter__goto_3116_10 = ((0 as u32)))
        (__local_i__goto_3139_5 = ((0 as i32)))
        goto '__ci_bb_798
    }

    '__ci_bb_796 {
        (__local_n__goto_5377_13 = ((0 as i32)))
        ((*__local_parsed_pattern__goto_3125_11) = ((2147876864 as u32)))
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + ((3 as isize) as usize))
        goto '__ci_bb_816
    }

    '__ci_bb_797 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_275 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_275 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_275 != 0) {
            goto '__ci_bb_821
        } else {
            goto '__ci_bb_822
        }
    }

    '__ci_bb_798 {
        if ((if _pcre2_callout_start_delims_8[__local_i__goto_3139_5] != 0: 1 else: 0) != 0) {
            goto '__ci_bb_799
        } else {
            goto '__ci_bb_801
        }
    }

    '__ci_bb_799 {
        if ((if (*__local_ptr) == _pcre2_callout_start_delims_8[__local_i__goto_3139_5]: 1 else: 0) != 0) {
            goto '__ci_bb_802
        } else {
            goto '__ci_bb_803
        }
    }

    '__ci_bb_800 {
        (__local_i__goto_3139_5 = __local_i__goto_3139_5 + 1)
        goto '__ci_bb_798
    }

    '__ci_bb_801 {
        if ((if __local_delimiter__goto_3116_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_804
        } else {
            goto '__ci_bb_805
        }
    }

    '__ci_bb_802 {
        (__local_delimiter__goto_3116_10 = ((_pcre2_callout_end_delims_8[__local_i__goto_3139_5] as u32)))
        goto '__ci_bb_801
    }

    '__ci_bb_803 {
        goto '__ci_bb_800
    }

    '__ci_bb_804 {
        (__local_errorcode__goto_3137_5 = ERR82)
        goto '__ci_bb_608
    }

    '__ci_bb_805 {
        ((*__local_parsed_pattern__goto_3125_11) = ((2147942400 as u32)))
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + ((3 as isize) as usize))
        goto '__ci_bb_806
    }

    '__ci_bb_806 {
        goto '__ci_bb_807
    }

    '__ci_bb_807 {
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_810
        } else {
            goto '__ci_bb_811
        }
    }

    '__ci_bb_808 {
        goto '__ci_bb_806
    }

    '__ci_bb_809 {
        (__local_calloutlength__goto_5328_20 = ((((((__local_ptr as usize) -% (__local_startptr__goto_5329_20 as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        if ((if __local_calloutlength__goto_5328_20 > 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_814
        } else {
            goto '__ci_bb_815
        }
    }

    '__ci_bb_810 {
        (__local_errorcode__goto_3137_5 = ERR81)
        (__local_ptr = __local_startptr__goto_5329_20)
        goto '__ci_bb_19
    }

    '__ci_bb_811 {
        (__ci_expr_logic_267 = 0)
        if ((if (*__local_ptr) == __local_delimiter__goto_3116_10: 1 else: 0) != 0) {
            var __ci_expr_logic_266: i32

            (__local_ptr = __local_ptr + 1)

            if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
                (__ci_expr_logic_266 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_266 = (if (if (*__local_ptr) != __local_delimiter__goto_3116_10: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_267 = (if __ci_expr_logic_266 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_267 != 0) {
            goto '__ci_bb_812
        } else {
            goto '__ci_bb_813
        }
    }

    '__ci_bb_812 {
        goto '__ci_bb_809
    }

    '__ci_bb_813 {
        goto '__ci_bb_808
    }

    '__ci_bb_814 {
        (__local_errorcode__goto_3137_5 = ERR72)
        goto '__ci_bb_19
    }

    '__ci_bb_815 {
        (__ci_expr_old_268 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_268) = ((__local_calloutlength__goto_5328_20 as u32)))
        (__local_offset__goto_3236_14 = ((((((__local_startptr__goto_5329_20 as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        (__ci_expr_old_269 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_269) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_270 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_270) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        goto '__ci_bb_797
    }

    '__ci_bb_816 {
        (__ci_expr_logic_272 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            var __ci_expr_logic_271: i32 = 0

            if ((if (*__local_ptr) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_271 = (if (if (*__local_ptr) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_272 = (if __ci_expr_logic_271 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_272 != 0) {
            goto '__ci_bb_817
        } else {
            goto '__ci_bb_818
        }
    }

    '__ci_bb_817 {
        (__ci_expr_old_273 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_n__goto_5377_13 = ((((__local_n__goto_5377_13 * 10) + (((*__ci_expr_old_273) as i32) - 48)) as i32)))
        if ((if __local_n__goto_5377_13 > 255: 1 else: 0) != 0) {
            goto '__ci_bb_819
        } else {
            goto '__ci_bb_820
        }
    }

    '__ci_bb_818 {
        (__ci_expr_old_274 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_274) = ((__local_n__goto_5377_13 as u32)))
        goto '__ci_bb_797
    }

    '__ci_bb_819 {
        (__local_errorcode__goto_3137_5 = ERR38)
        goto '__ci_bb_19
    }

    '__ci_bb_820 {
        goto '__ci_bb_816
    }

    '__ci_bb_821 {
        (__local_errorcode__goto_3137_5 = ERR39)
        goto '__ci_bb_19
    }

    '__ci_bb_822 {
        (__local_ptr = __local_ptr + 1)
        ((__local_previous_callout__goto_3124_11[1]) = ((((((__local_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))
        ((__local_previous_callout__goto_3124_11[2]) = ((0 as u32)))
        goto '__ci_bb_681
    }

    '__ci_bb_823 {
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_824
        } else {
            goto '__ci_bb_825
        }
    }

    '__ci_bb_824 {
        goto '__ci_bb_585
    }

    '__ci_bb_825 {
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        if ((if (*__local_ptr) == 63: 1 else: 0) != 0) {
            (__ci_expr_logic_276 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_276 = (if (if (*__local_ptr) == 42: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_276 != 0) {
            goto '__ci_bb_826
        } else {
            goto '__ci_bb_827
        }
    }

    '__ci_bb_826 {
        (__ci_expr_old_277 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_277) = ((2148466688 as u32)))
        (__local_ptr = __local_ptr - 1)
        (__local_expect_cond_assert__goto_3136_5 = ((2 as i32)))
        goto '__ci_bb_681
    }

    '__ci_bb_827 {
        if (read_number((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, ((*__param_cb).bracount as i32), (65535 as u32), (161 as u32), (&raw mut __local_i__goto_3139_5 as *mut i32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0) {
            goto '__ci_bb_828
        } else {
            goto '__ci_bb_829
        }
    }

    '__ci_bb_828 {
        goto '__ci_bb_831
    }

    '__ci_bb_829 {
        if ((if __local_errorcode__goto_3137_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_836
        } else {
            goto '__ci_bb_837
        }
    }

    '__ci_bb_830 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_304 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_304 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_304 != 0) {
            goto '__ci_bb_890
        } else {
            goto '__ci_bb_891
        }
    }

    '__ci_bb_831 {
        goto '__ci_bb_832
    }

    '__ci_bb_832 {
        if (0 != 0) {
            goto '__ci_bb_831
        } else {
            goto '__ci_bb_833
        }
    }

    '__ci_bb_833 {
        if ((if __local_i__goto_3139_5 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_834
        } else {
            goto '__ci_bb_835
        }
    }

    '__ci_bb_834 {
        (__local_errorcode__goto_3137_5 = ERR15)
        goto '__ci_bb_19
    }

    '__ci_bb_835 {
        (__ci_expr_old_278 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_278) = ((2148663296 as u32)))
        (__local_offset__goto_3236_14 = (((((((__local_ptr as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) - 2) as u64)))
        (__ci_expr_old_279 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_279) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_280 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_280) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        (__ci_expr_old_281 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_281) = ((__local_i__goto_3139_5 as u32)))
        goto '__ci_bb_830
    }

    '__ci_bb_836 {
        goto '__ci_bb_19
    }

    '__ci_bb_837 {
        (__ci_expr_logic_283 = 0)
        (__ci_expr_logic_282 = 0)
        if ((if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) >= 10: 1 else: 0) != 0) {
            (__ci_expr_logic_282 = (if (if _pcre2_strncmp_c8_8(__local_ptr, c"\x56\x45\x52\x53\x49\x4f\x4e".ptr, (7 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_282 != 0) {
            (__ci_expr_logic_283 = (if (if (__local_ptr[7]) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_283 != 0) {
            goto '__ci_bb_839
        } else {
            goto '__ci_bb_840
        }
    }

    '__ci_bb_838 {
        goto '__ci_bb_830
    }

    '__ci_bb_839 {
        (__local_ge__goto_5472_18 = ((0 as u32)))
        (__local_major__goto_5473_13 = ((0 as i32)))
        (__local_minor__goto_5474_13 = ((0 as i32)))
        (__local_ptr = __local_ptr + ((7 as isize) as usize))
        if ((if (*__local_ptr) == 62: 1 else: 0) != 0) {
            goto '__ci_bb_842
        } else {
            goto '__ci_bb_843
        }
    }

    '__ci_bb_840 {
        (__local_was_r_ampersand__goto_5528_14 = ((0 as i32)))
        (__ci_expr_logic_295 = 0)
        (__ci_expr_logic_294 = 0)
        if ((if (*__local_ptr) == 82: 1 else: 0) != 0) {
            (__ci_expr_logic_294 = (if (if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) > 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_294 != 0) {
            (__ci_expr_logic_295 = (if (if (__local_ptr[1]) == 38: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_295 != 0) {
            goto '__ci_bb_862
        } else {
            goto '__ci_bb_863
        }
    }

    '__ci_bb_841 {
        goto '__ci_bb_838
    }

    '__ci_bb_842 {
        (__local_ge__goto_5472_18 = ((1 as u32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_843
    }

    '__ci_bb_843 {
        if ((if (*__local_ptr) != 61: 1 else: 0) != 0) {
            (__ci_expr_logic_285 = (if true: 1 else: 0))
        } else {
            (__local_ptr = __local_ptr + 1)

            var __ci_expr_logic_284: i32 = 0

            if ((if (*__local_ptr) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_284 = (if (if (*__local_ptr) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_285 = (if (if not (__ci_expr_logic_284 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_285 != 0) {
            goto '__ci_bb_844
        } else {
            goto '__ci_bb_845
        }
    }

    '__ci_bb_844 {
        (__local_errorcode__goto_3137_5 = ERR79)
        if ((if not (__local_ge__goto_5472_18 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_846
        } else {
            goto '__ci_bb_847
        }
    }

    '__ci_bb_845 {
        if ((if not (read_number((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, (-1 as i32), (1000 as u32), (179 as u32), (&raw mut __local_major__goto_5473_13 as *mut i32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_848
        } else {
            goto '__ci_bb_849
        }
    }

    '__ci_bb_846 {
        goto '__ci_bb_608
    }

    '__ci_bb_847 {
        goto '__ci_bb_19
    }

    '__ci_bb_848 {
        goto '__ci_bb_19
    }

    '__ci_bb_849 {
        (__ci_expr_logic_286 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_286 = (if (if (*__local_ptr) == 46: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_286 != 0) {
            goto '__ci_bb_850
        } else {
            goto '__ci_bb_851
        }
    }

    '__ci_bb_850 {
        (__local_ptr = __local_ptr + 1)
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_288 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_287: i32 = 0

            if ((if (*__local_ptr) >= 48: 1 else: 0) != 0) {
                (__ci_expr_logic_287 = (if (if (*__local_ptr) <= 57: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_288 = (if (if not (__ci_expr_logic_287 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_288 != 0) {
            goto '__ci_bb_852
        } else {
            goto '__ci_bb_853
        }
    }

    '__ci_bb_851 {
        if ((if __local_ptr >= __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_289 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_289 = (if (if (*__local_ptr) != 41: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_289 != 0) {
            goto '__ci_bb_858
        } else {
            goto '__ci_bb_859
        }
    }

    '__ci_bb_852 {
        (__local_errorcode__goto_3137_5 = ERR79)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_854
        } else {
            goto '__ci_bb_855
        }
    }

    '__ci_bb_853 {
        if ((if not (read_number((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, (-1 as i32), (1000 as u32), (179 as u32), (&raw mut __local_minor__goto_5474_13 as *mut i32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_856
        } else {
            goto '__ci_bb_857
        }
    }

    '__ci_bb_854 {
        goto '__ci_bb_608
    }

    '__ci_bb_855 {
        goto '__ci_bb_19
    }

    '__ci_bb_856 {
        goto '__ci_bb_19
    }

    '__ci_bb_857 {
        goto '__ci_bb_851
    }

    '__ci_bb_858 {
        (__local_errorcode__goto_3137_5 = ERR79)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            goto '__ci_bb_860
        } else {
            goto '__ci_bb_861
        }
    }

    '__ci_bb_859 {
        (__ci_expr_old_290 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_290) = ((2148859904 as u32)))
        (__ci_expr_old_291 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_291) = __local_ge__goto_5472_18)
        (__ci_expr_old_292 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_292) = ((__local_major__goto_5473_13 as u32)))
        (__ci_expr_old_293 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_293) = ((__local_minor__goto_5474_13 as u32)))
        goto '__ci_bb_841
    }

    '__ci_bb_860 {
        goto '__ci_bb_608
    }

    '__ci_bb_861 {
        goto '__ci_bb_19
    }

    '__ci_bb_862 {
        (__local_terminator__goto_3232_12 = ((41 as u32)))
        (__local_was_r_ampersand__goto_5528_14 = ((1 as i32)))
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_864
    }

    '__ci_bb_863 {
        if ((if (*__local_ptr) == 60: 1 else: 0) != 0) {
            goto '__ci_bb_865
        } else {
            goto '__ci_bb_866
        }
    }

    '__ci_bb_864 {
        if ((if not (read_name((&raw mut __local_ptr as *mut *const u8), __local_ptrend__goto_3149_12, __local_utf__goto_3142_6, __local_terminator__goto_3232_12, (&raw mut __local_offset__goto_3236_14 as *mut u64), (&raw mut __local_name__goto_3148_12 as *mut *const u8), (&raw mut __local_namelen__goto_3117_10 as *mut u32), (&raw mut __local_errorcode__goto_3137_5 as *mut i32), __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_871
        } else {
            goto '__ci_bb_872
        }
    }

    '__ci_bb_865 {
        (__local_terminator__goto_3232_12 = ((62 as u32)))
        goto '__ci_bb_867
    }

    '__ci_bb_866 {
        if ((if (*__local_ptr) == 39: 1 else: 0) != 0) {
            goto '__ci_bb_868
        } else {
            goto '__ci_bb_869
        }
    }

    '__ci_bb_867 {
        goto '__ci_bb_864
    }

    '__ci_bb_868 {
        (__local_terminator__goto_3232_12 = ((39 as u32)))
        goto '__ci_bb_870
    }

    '__ci_bb_869 {
        (__local_terminator__goto_3232_12 = ((41 as u32)))
        (__local_ptr = __local_ptr - 1)
        goto '__ci_bb_870
    }

    '__ci_bb_870 {
        goto '__ci_bb_867
    }

    '__ci_bb_871 {
        goto '__ci_bb_19
    }

    '__ci_bb_872 {
        if (__local_was_r_ampersand__goto_5528_14 != 0) {
            goto '__ci_bb_873
        } else {
            goto '__ci_bb_874
        }
    }

    '__ci_bb_873 {
        ((*__local_parsed_pattern__goto_3125_11) = ((2148728832 as u32)))
        (__local_ptr = __local_ptr - 1)
        goto '__ci_bb_875
    }

    '__ci_bb_874 {
        if ((if __local_terminator__goto_3232_12 == 41: 1 else: 0) != 0) {
            goto '__ci_bb_876
        } else {
            goto '__ci_bb_877
        }
    }

    '__ci_bb_875 {
        (__ci_expr_old_300 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        if ((if (*__ci_expr_old_300) != 2148532224: 1 else: 0) != 0) {
            goto '__ci_bb_888
        } else {
            goto '__ci_bb_889
        }
    }

    '__ci_bb_876 {
        (__ci_expr_logic_296 = 0)
        if ((if __local_namelen__goto_3117_10 == 6: 1 else: 0) != 0) {
            (__ci_expr_logic_296 = (if (if _pcre2_strncmp_c8_8(__local_name__goto_3148_12, c"\x44\x45\x46\x49\x4e\x45".ptr, (6 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_296 != 0) {
            goto '__ci_bb_879
        } else {
            goto '__ci_bb_880
        }
    }

    '__ci_bb_877 {
        ((*__local_parsed_pattern__goto_3125_11) = ((2148597760 as u32)))
        goto '__ci_bb_878
    }

    '__ci_bb_878 {
        goto '__ci_bb_875
    }

    '__ci_bb_879 {
        ((*__local_parsed_pattern__goto_3125_11) = ((2148532224 as u32)))
        goto '__ci_bb_881
    }

    '__ci_bb_880 {
        (__local_i__goto_3139_5 = ((1 as i32)))
        goto '__ci_bb_882
    }

    '__ci_bb_881 {
        (__local_ptr = __local_ptr - 1)
        goto '__ci_bb_878
    }

    '__ci_bb_882 {
        if ((if __local_i__goto_3139_5 < ((__local_namelen__goto_3117_10 as i32)): 1 else: 0) != 0) {
            goto '__ci_bb_883
        } else {
            goto '__ci_bb_885
        }
    }

    '__ci_bb_883 {
        (__ci_expr_logic_297 = 0)
        if ((if (__local_name__goto_3148_12[__local_i__goto_3139_5]) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_297 = (if (if (__local_name__goto_3148_12[__local_i__goto_3139_5]) <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_297 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_886
        } else {
            goto '__ci_bb_887
        }
    }

    '__ci_bb_884 {
        (__local_i__goto_3139_5 = __local_i__goto_3139_5 + 1)
        goto '__ci_bb_882
    }

    '__ci_bb_885 {
        (__ci_expr_ternary_299 = 0)
        (__ci_expr_logic_298 = 0)
        if ((if (*__local_name__goto_3148_12) == 82: 1 else: 0) != 0) {
            (__ci_expr_logic_298 = (if (if __local_i__goto_3139_5 >= ((__local_namelen__goto_3117_10 as i32)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_298 != 0) {
            (__ci_expr_ternary_299 = ((2148794368 as u32)))
        } else {
            (__ci_expr_ternary_299 = ((2148597760 as u32)))
        }
        ((*__local_parsed_pattern__goto_3125_11) = __ci_expr_ternary_299)
        goto '__ci_bb_881
    }

    '__ci_bb_886 {
        goto '__ci_bb_885
    }

    '__ci_bb_887 {
        goto '__ci_bb_884
    }

    '__ci_bb_888 {
        (__ci_expr_old_301 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_301) = __local_namelen__goto_3117_10)
        goto '__ci_bb_889
    }

    '__ci_bb_889 {
        (__ci_expr_old_302 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_302) = ((((__local_offset__goto_3236_14 as u64) >> (32 as u32)) as u32)))
        (__ci_expr_old_303 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_303) = ((((__local_offset__goto_3236_14 as u64) & (4294967295 as u64)) as u32)))
        goto '__ci_bb_841
    }

    '__ci_bb_890 {
        (__local_errorcode__goto_3137_5 = ERR24)
        goto '__ci_bb_19
    }

    '__ci_bb_891 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_681
    }

    '__ci_bb_892 {
        goto '__ci_bb_626
    }

    '__ci_bb_893 {
        goto '__ci_bb_628
    }

    '__ci_bb_894 {
        goto '__ci_bb_630
    }

    '__ci_bb_895 {
        goto '__ci_bb_632
    }

    '__ci_bb_896 {
        if ((if ((((__local_ptrend__goto_3149_12 as usize) -% (__local_ptr as usize)) as i64) / (sizeof[u8]() as i64)) <= 1: 1 else: 0) != 0) {
            (__ci_expr_logic_311 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_310: i32 = 0

            var __ci_expr_logic_309: i32 = 0

            if ((if (__local_ptr[1]) != 61: 1 else: 0) != 0) {
                (__ci_expr_logic_309 = (if (if (__local_ptr[1]) != 33: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_309 != 0) {
                (__ci_expr_logic_310 = (if (if (__local_ptr[1]) != 42: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_311 = (if __ci_expr_logic_310 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_311 != 0) {
            goto '__ci_bb_897
        } else {
            goto '__ci_bb_898
        }
    }

    '__ci_bb_897 {
        (__local_terminator__goto_3232_12 = ((62 as u32)))
        goto '__ci_bb_754
    }

    '__ci_bb_898 {
        (__ci_expr_old_312 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_312) = (((if (if (__local_ptr[1]) == 61: 1 else: 0) != 0: (2150170624 as u32) else: ((if (if (__local_ptr[1]) == 33: 1 else: 0) != 0: (2150236160 as u32) else: (2150367232 as u32)) as u32)) as u32)))
        goto '__ci_bb_638
    }

    '__ci_bb_899 {
        if ((if __local_top_nest__goto_3153_12 == null: 1 else: 0) != 0) {
            goto '__ci_bb_901
        } else {
            goto '__ci_bb_902
        }
    }

    '__ci_bb_900 {
        goto '__ci_bb_681
    }

    '__ci_bb_901 {
        (__local_top_nest__goto_3153_12 = (((*__param_cb).start_workspace as *mut nest_save)))
        goto '__ci_bb_903
    }

    '__ci_bb_902 {
        (__local_top_nest__goto_3153_12 = __local_top_nest__goto_3153_12 + 1)
        if ((if __local_top_nest__goto_3153_12 >= __local_end_nests__goto_3153_23: 1 else: 0) != 0) {
            goto '__ci_bb_904
        } else {
            goto '__ci_bb_905
        }
    }

    '__ci_bb_903 {
        ((*__local_top_nest__goto_3153_12).nest_depth = __local_nest_depth__goto_3131_10)
        ((*__local_top_nest__goto_3153_12).flags = ((2 as u16)))
        ((*__local_top_nest__goto_3153_12).options = ((((__local_options as u32) & (((((((((((((((8 as u32) | (32 as u32)) as u32) | (64 as u32)) as u32) | (128 as u32)) as u32) | (16777216 as u32)) as u32) | (1024 as u32)) as u32) | (8192 as u32)) as u32) | (262144 as u32)) as u32)) as u32)))
        ((*__local_top_nest__goto_3153_12).xoptions = ((((__local_xoptions as u32) & (((((((((((128 as u32) | (256 as u32)) as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (4096 as u32)) as u32) | (2048 as u32)) as u32)) as u32)))
        goto '__ci_bb_900
    }

    '__ci_bb_904 {
        (__local_errorcode__goto_3137_5 = ERR84)
        goto '__ci_bb_19
    }

    '__ci_bb_905 {
        goto '__ci_bb_903
    }

    '__ci_bb_906 {
        (__local_terminator__goto_3232_12 = ((39 as u32)))
        goto '__ci_bb_754
    }

    '__ci_bb_907 {
        goto '__ci_bb_19
    }

    '__ci_bb_908 {
        if ((if (*__param_cb).bracount >= 65535: 1 else: 0) != 0) {
            goto '__ci_bb_909
        } else {
            goto '__ci_bb_910
        }
    }

    '__ci_bb_909 {
        (__local_errorcode__goto_3137_5 = ERR97)
        goto '__ci_bb_19
    }

    '__ci_bb_910 {
        ((*__param_cb).bracount = ((*__param_cb).bracount +% 1))
        (__ci_expr_old_315 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_315) = ((((2148007936 as u32) | ((*__param_cb).bracount as u32)) as u32)))
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 +% 1))
        if ((if (*__param_cb).names_found >= 10000: 1 else: 0) != 0) {
            goto '__ci_bb_911
        } else {
            goto '__ci_bb_912
        }
    }

    '__ci_bb_911 {
        (__local_errorcode__goto_3137_5 = ERR49)
        goto '__ci_bb_19
    }

    '__ci_bb_912 {
        if ((if ((((__local_namelen__goto_3117_10 as u32) +% (2 as u32)) as u32) +% (1 as u32)) > (*__param_cb).name_entry_size: 1 else: 0) != 0) {
            goto '__ci_bb_913
        } else {
            goto '__ci_bb_914
        }
    }

    '__ci_bb_913 {
        ((*__param_cb).name_entry_size = ((((((__local_namelen__goto_3117_10 as u32) +% (2 as u32)) as u32) +% (1 as u32)) as u16)))
        goto '__ci_bb_914
    }

    '__ci_bb_914 {
        (__local_is_dupname__goto_3144_6 = ((0 as i32)))
        (__local_hash__goto_3134_10 = ((_pcre2_compile_get_hash_from_name8(__local_name__goto_3148_12, __local_namelen__goto_3117_10) as u16)))
        (__local_ng__goto_3152_14 = (*__param_cb).named_groups)
        (__local_i__goto_3139_5 = ((0 as i32)))
        goto '__ci_bb_915
    }

    '__ci_bb_915 {
        if ((if __local_i__goto_3139_5 < (*__param_cb).names_found: 1 else: 0) != 0) {
            goto '__ci_bb_916
        } else {
            goto '__ci_bb_918
        }
    }

    '__ci_bb_916 {
        (__ci_expr_logic_317 = 0)
        (__ci_expr_logic_316 = 0)
        if ((if __local_namelen__goto_3117_10 == (*__local_ng__goto_3152_14).length: 1 else: 0) != 0) {
            (__ci_expr_logic_316 = (if (if __local_hash__goto_3134_10 == (((*__local_ng__goto_3152_14).hash_dup as i32) & (32767 as i32)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_316 != 0) {
            (__ci_expr_logic_317 = (if (if _pcre2_strncmp_8(__local_name__goto_3148_12, (*__local_ng__goto_3152_14).name, (__local_namelen__goto_3117_10 as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_317 != 0) {
            goto '__ci_bb_919
        } else {
            goto '__ci_bb_920
        }
    }

    '__ci_bb_917 {
        (__local_i__goto_3139_5 = __local_i__goto_3139_5 + 1)
        (__local_ng__goto_3152_14 = __local_ng__goto_3152_14 + 1)
        goto '__ci_bb_915
    }

    '__ci_bb_918 {
        if ((if __local_i__goto_3139_5 < (*__param_cb).names_found: 1 else: 0) != 0) {
            goto '__ci_bb_934
        } else {
            goto '__ci_bb_935
        }
    }

    '__ci_bb_919 {
        if ((if (*__local_ng__goto_3152_14).number == (*__param_cb).bracount: 1 else: 0) != 0) {
            goto '__ci_bb_922
        } else {
            goto '__ci_bb_923
        }
    }

    '__ci_bb_920 {
        if ((if (*__local_ng__goto_3152_14).number == (*__param_cb).bracount: 1 else: 0) != 0) {
            goto '__ci_bb_932
        } else {
            goto '__ci_bb_933
        }
    }

    '__ci_bb_921 {
        goto '__ci_bb_917
    }

    '__ci_bb_922 {
        goto '__ci_bb_918
    }

    '__ci_bb_923 {
        if ((if ((__local_options as u32) & (64 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_924
        } else {
            goto '__ci_bb_925
        }
    }

    '__ci_bb_924 {
        (__local_errorcode__goto_3137_5 = ERR43)
        goto '__ci_bb_19
    }

    '__ci_bb_925 {
        ((*__local_ng__goto_3152_14).hash_dup = ((*__local_ng__goto_3152_14).hash_dup as u16) | (32768 as u16))
        (__local_is_dupname__goto_3144_6 = ((1 as i32)))
        ((*__param_cb).dupnames = ((1 as i32)))
        (__local_name__goto_3148_12 = (*__local_ng__goto_3152_14).name)
        (__local_namelen__goto_3117_10 = ((0 as u32)))
        goto '__ci_bb_926
    }

    '__ci_bb_926 {
        if ((if __local_i__goto_3139_5 < (*__param_cb).names_found: 1 else: 0) != 0) {
            goto '__ci_bb_927
        } else {
            goto '__ci_bb_929
        }
    }

    '__ci_bb_927 {
        (__ci_expr_logic_318 = 0)
        if ((if (*__local_ng__goto_3152_14).name == __local_name__goto_3148_12: 1 else: 0) != 0) {
            (__ci_expr_logic_318 = (if (if (*__local_ng__goto_3152_14).number == (*__param_cb).bracount: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_318 != 0) {
            goto '__ci_bb_930
        } else {
            goto '__ci_bb_931
        }
    }

    '__ci_bb_928 {
        (__local_i__goto_3139_5 = __local_i__goto_3139_5 + 1)
        (__local_ng__goto_3152_14 = __local_ng__goto_3152_14 + 1)
        goto '__ci_bb_926
    }

    '__ci_bb_929 {
        goto '__ci_bb_918
    }

    '__ci_bb_930 {
        goto '__ci_bb_929
    }

    '__ci_bb_931 {
        goto '__ci_bb_928
    }

    '__ci_bb_932 {
        (__local_errorcode__goto_3137_5 = ERR65)
        goto '__ci_bb_19
    }

    '__ci_bb_933 {
        goto '__ci_bb_921
    }

    '__ci_bb_934 {
        goto '__ci_bb_681
    }

    '__ci_bb_935 {
        if ((if (*__param_cb).names_found >= (*__param_cb).named_group_list_size: 1 else: 0) != 0) {
            goto '__ci_bb_936
        } else {
            goto '__ci_bb_937
        }
    }

    '__ci_bb_936 {
        (__local_newsize__goto_5771_18 = (((((*__param_cb).named_group_list_size as u32) *% (2 as u32)) as u32)))
        (__local_newspace__goto_5772_22 = (((*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).malloc.unwrap()((((__local_newsize__goto_5771_18 as u64) *% (sizeof[named_group_8]() as u64)) as u64), (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).memory_data) as *mut named_group_8)))
        if ((if __local_newspace__goto_5772_22 == null: 1 else: 0) != 0) {
            goto '__ci_bb_938
        } else {
            goto '__ci_bb_939
        }
    }

    '__ci_bb_937 {
        if (__local_is_dupname__goto_3144_6 != 0) {
            goto '__ci_bb_942
        } else {
            goto '__ci_bb_943
        }
    }

    '__ci_bb_938 {
        (__local_errorcode__goto_3137_5 = ERR21)
        goto '__ci_bb_19
    }

    '__ci_bb_939 {
        with_memcpy(((__local_newspace__goto_5772_22 as *mut c_void) as *mut u8), (((*__param_cb).named_groups as *const c_void) as *const u8), (((((*__param_cb).named_group_list_size as u64) *% (sizeof[named_group_8]() as u64)) as u64) as i64))
        if ((if (*__param_cb).named_group_list_size > 20: 1 else: 0) != 0) {
            goto '__ci_bb_940
        } else {
            goto '__ci_bb_941
        }
    }

    '__ci_bb_940 {
        (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).free.unwrap()(((*__param_cb).named_groups as *mut c_void), (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).memory_data)
        goto '__ci_bb_941
    }

    '__ci_bb_941 {
        ((*__param_cb).named_groups = __local_newspace__goto_5772_22)
        ((*__param_cb).named_group_list_size = __local_newsize__goto_5771_18)
        goto '__ci_bb_937
    }

    '__ci_bb_942 {
        (__local_hash__goto_3134_10 = (__local_hash__goto_3134_10 as u16) | (32768 as u16))
        goto '__ci_bb_943
    }

    '__ci_bb_943 {
        (((*__param_cb).named_groups[(*__param_cb).names_found]).name = __local_name__goto_3148_12)
        (((*__param_cb).named_groups[(*__param_cb).names_found]).length = ((__local_namelen__goto_3117_10 as u16)))
        (((*__param_cb).named_groups[(*__param_cb).names_found]).number = (*__param_cb).bracount)
        (((*__param_cb).named_groups[(*__param_cb).names_found]).hash_dup = __local_hash__goto_3134_10)
        ((*__param_cb).names_found = ((*__param_cb).names_found +% 1))
        goto '__ci_bb_681
    }

    '__ci_bb_944 {
        (__local_class_mode_state__goto_3120_10 = ((2 as u32)))
        (__ci_expr_old_319 = __local_ptr)
        (__local_ptr = __local_ptr + 1)
        (__local_c__goto_3115_10 = (((*__ci_expr_old_319) as u32)))
        goto '__ci_bb_276
    }

    '__ci_bb_945 {
        if ((*__local_ptr) == 82) {
            goto '__ci_bb_762
        } else {
            goto '__ci_bb_946
        }
    }

    '__ci_bb_946 {
        if ((*__local_ptr) == 43) {
            goto '__ci_bb_765
        } else {
            goto '__ci_bb_947
        }
    }

    '__ci_bb_947 {
        if ((*__local_ptr) == 48) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_948
        }
    }

    '__ci_bb_948 {
        if ((*__local_ptr) == 49) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_949
        }
    }

    '__ci_bb_949 {
        if ((*__local_ptr) == 50) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_950
        }
    }

    '__ci_bb_950 {
        if ((*__local_ptr) == 51) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_951
        }
    }

    '__ci_bb_951 {
        if ((*__local_ptr) == 52) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_952
        }
    }

    '__ci_bb_952 {
        if ((*__local_ptr) == 53) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_953
        }
    }

    '__ci_bb_953 {
        if ((*__local_ptr) == 54) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_954
        }
    }

    '__ci_bb_954 {
        if ((*__local_ptr) == 55) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_955
        }
    }

    '__ci_bb_955 {
        if ((*__local_ptr) == 56) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_956
        }
    }

    '__ci_bb_956 {
        if ((*__local_ptr) == 57) {
            goto '__ci_bb_770
        } else {
            goto '__ci_bb_957
        }
    }

    '__ci_bb_957 {
        if ((*__local_ptr) == 38) {
            goto '__ci_bb_777
        } else {
            goto '__ci_bb_958
        }
    }

    '__ci_bb_958 {
        if ((*__local_ptr) == 67) {
            goto '__ci_bb_788
        } else {
            goto '__ci_bb_959
        }
    }

    '__ci_bb_959 {
        if ((*__local_ptr) == 40) {
            goto '__ci_bb_823
        } else {
            goto '__ci_bb_960
        }
    }

    '__ci_bb_960 {
        if ((*__local_ptr) == 62) {
            goto '__ci_bb_892
        } else {
            goto '__ci_bb_961
        }
    }

    '__ci_bb_961 {
        if ((*__local_ptr) == 61) {
            goto '__ci_bb_893
        } else {
            goto '__ci_bb_962
        }
    }

    '__ci_bb_962 {
        if ((*__local_ptr) == 42) {
            goto '__ci_bb_894
        } else {
            goto '__ci_bb_963
        }
    }

    '__ci_bb_963 {
        if ((*__local_ptr) == 33) {
            goto '__ci_bb_895
        } else {
            goto '__ci_bb_964
        }
    }

    '__ci_bb_964 {
        if ((*__local_ptr) == 60) {
            goto '__ci_bb_896
        } else {
            goto '__ci_bb_965
        }
    }

    '__ci_bb_965 {
        if ((*__local_ptr) == 39) {
            goto '__ci_bb_906
        } else {
            goto '__ci_bb_966
        }
    }

    '__ci_bb_966 {
        if ((*__local_ptr) == 91) {
            goto '__ci_bb_944
        } else {
            goto '__ci_bb_682
        }
    }

    '__ci_bb_967 {
        (__ci_expr_logic_321 = 0)
        (__ci_expr_logic_320 = 0)
        if ((if __local_top_nest__goto_3153_12 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_320 = (if (if (*__local_top_nest__goto_3153_12).nest_depth == __local_nest_depth__goto_3131_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_320 != 0) {
            (__ci_expr_logic_321 = (if (if ((((*__local_top_nest__goto_3153_12).flags as i32) as u32) & (1 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_321 != 0) {
            goto '__ci_bb_968
        } else {
            goto '__ci_bb_969
        }
    }

    '__ci_bb_968 {
        if ((if (*__param_cb).bracount > (*__local_top_nest__goto_3153_12).max_group: 1 else: 0) != 0) {
            goto '__ci_bb_970
        } else {
            goto '__ci_bb_971
        }
    }

    '__ci_bb_969 {
        (__ci_expr_old_322 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_322) = ((2147549184 as u32)))
        goto '__ci_bb_161
    }

    '__ci_bb_970 {
        ((*__local_top_nest__goto_3153_12).max_group = (((*__param_cb).bracount as u16)))
        goto '__ci_bb_971
    }

    '__ci_bb_971 {
        ((*__param_cb).bracount = (((*__local_top_nest__goto_3153_12).reset_group as u32)))
        goto '__ci_bb_969
    }

    '__ci_bb_972 {
        (__local_okquantifier__goto_3146_6 = ((1 as i32)))
        (__ci_expr_logic_323 = 0)
        if ((if __local_top_nest__goto_3153_12 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_323 = (if (if (*__local_top_nest__goto_3153_12).nest_depth == __local_nest_depth__goto_3131_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_323 != 0) {
            goto '__ci_bb_973
        } else {
            goto '__ci_bb_974
        }
    }

    '__ci_bb_973 {
        (__local_options = ((((((__local_options as u32) & ((~((((((((((((((8 as u32) | (32 as u32)) as u32) | (64 as u32)) as u32) | (128 as u32)) as u32) | (16777216 as u32)) as u32) | (1024 as u32)) as u32) | (8192 as u32)) as u32) | (262144 as u32))) as u32)) as u32) | ((*__local_top_nest__goto_3153_12).options as u32)) as u32)))
        (__local_xoptions = ((((((__local_xoptions as u32) & ((~((((((((((128 as u32) | (256 as u32)) as u32) | (512 as u32)) as u32) | (1024 as u32)) as u32) | (4096 as u32)) as u32) | (2048 as u32))) as u32)) as u32) | ((*__local_top_nest__goto_3153_12).xoptions as u32)) as u32)))
        (__ci_expr_logic_324 = 0)
        if ((if ((((*__local_top_nest__goto_3153_12).flags as i32) as u32) & (1 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_324 = (if (if (*__local_top_nest__goto_3153_12).max_group > (*__param_cb).bracount: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_324 != 0) {
            goto '__ci_bb_975
        } else {
            goto '__ci_bb_976
        }
    }

    '__ci_bb_974 {
        if ((if __local_nest_depth__goto_3131_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_984
        } else {
            goto '__ci_bb_985
        }
    }

    '__ci_bb_975 {
        ((*__param_cb).bracount = (((*__local_top_nest__goto_3153_12).max_group as u32)))
        goto '__ci_bb_976
    }

    '__ci_bb_976 {
        if ((if ((((*__local_top_nest__goto_3153_12).flags as i32) as u32) & (2 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_977
        } else {
            goto '__ci_bb_978
        }
    }

    '__ci_bb_977 {
        (__local_okquantifier__goto_3146_6 = ((0 as i32)))
        goto '__ci_bb_978
    }

    '__ci_bb_978 {
        if ((if ((((*__local_top_nest__goto_3153_12).flags as i32) as u32) & (4 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_979
        } else {
            goto '__ci_bb_980
        }
    }

    '__ci_bb_979 {
        (__ci_expr_old_325 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_325) = ((2149384192 as u32)))
        goto '__ci_bb_980
    }

    '__ci_bb_980 {
        if ((if __local_top_nest__goto_3153_12 == (((*__param_cb).start_workspace as *mut nest_save)): 1 else: 0) != 0) {
            goto '__ci_bb_981
        } else {
            goto '__ci_bb_982
        }
    }

    '__ci_bb_981 {
        (__local_top_nest__goto_3153_12 = ((null as *mut nest_save)))
        goto '__ci_bb_983
    }

    '__ci_bb_982 {
        (__local_top_nest__goto_3153_12 = __local_top_nest__goto_3153_12 - 1)
        goto '__ci_bb_983
    }

    '__ci_bb_983 {
        goto '__ci_bb_974
    }

    '__ci_bb_984 {
        (__local_errorcode__goto_3137_5 = ERR22)
        goto '__ci_bb_19
    }

    '__ci_bb_985 {
        (__local_nest_depth__goto_3131_10 = (__local_nest_depth__goto_3131_10 -% 1))
        (__ci_expr_old_326 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_326) = ((2149384192 as u32)))
        goto '__ci_bb_161
    }

    '__ci_bb_986 {
        if (__local_c__goto_3115_10 == 94) {
            goto '__ci_bb_243
        } else {
            goto '__ci_bb_987
        }
    }

    '__ci_bb_987 {
        if (__local_c__goto_3115_10 == 36) {
            goto '__ci_bb_244
        } else {
            goto '__ci_bb_988
        }
    }

    '__ci_bb_988 {
        if (__local_c__goto_3115_10 == 46) {
            goto '__ci_bb_245
        } else {
            goto '__ci_bb_989
        }
    }

    '__ci_bb_989 {
        if (__local_c__goto_3115_10 == 42) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_990
        }
    }

    '__ci_bb_990 {
        if (__local_c__goto_3115_10 == 43) {
            goto '__ci_bb_248
        } else {
            goto '__ci_bb_991
        }
    }

    '__ci_bb_991 {
        if (__local_c__goto_3115_10 == 63) {
            goto '__ci_bb_249
        } else {
            goto '__ci_bb_992
        }
    }

    '__ci_bb_992 {
        if (__local_c__goto_3115_10 == 123) {
            goto '__ci_bb_250
        } else {
            goto '__ci_bb_993
        }
    }

    '__ci_bb_993 {
        if (__local_c__goto_3115_10 == 91) {
            goto '__ci_bb_265
        } else {
            goto '__ci_bb_994
        }
    }

    '__ci_bb_994 {
        if (__local_c__goto_3115_10 == 40) {
            goto '__ci_bb_582
        } else {
            goto '__ci_bb_995
        }
    }

    '__ci_bb_995 {
        if (__local_c__goto_3115_10 == 124) {
            goto '__ci_bb_967
        } else {
            goto '__ci_bb_996
        }
    }

    '__ci_bb_996 {
        if (__local_c__goto_3115_10 == 41) {
            goto '__ci_bb_972
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_997 {
        (__local_errorcode__goto_3137_5 = ERR60)
        goto '__ci_bb_19
    }

    '__ci_bb_998 {
        goto '__ci_bb_36
    }

    '__ci_bb_999 {
        goto '__ci_bb_1000
    }

    '__ci_bb_1000 {
        if (0 != 0) {
            goto '__ci_bb_999
        } else {
            goto '__ci_bb_1001
        }
    }

    '__ci_bb_1001 {
        (__local_parsed_pattern__goto_3125_11 = manage_callouts(__local_ptr, (&raw mut __local_previous_callout__goto_3124_11 as *mut *mut u32), __local_auto_callout__goto_3143_6, __local_parsed_pattern__goto_3125_11, __param_cb))
        if ((if ((__local_xoptions as u32) & (8 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1002
        } else {
            goto '__ci_bb_1003
        }
    }

    '__ci_bb_1002 {
        (__ci_expr_old_328 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_328) = ((2149384192 as u32)))
        (__ci_expr_old_329 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_329) = ((2149187584 as u32)))
        goto '__ci_bb_1004
    }

    '__ci_bb_1003 {
        if ((if ((__local_xoptions as u32) & (4 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_1005
        } else {
            goto '__ci_bb_1006
        }
    }

    '__ci_bb_1004 {
        if ((if __local_parsed_pattern__goto_3125_11 >= __local_parsed_pattern_end__goto_3126_11: 1 else: 0) != 0) {
            goto '__ci_bb_1007
        } else {
            goto '__ci_bb_1008
        }
    }

    '__ci_bb_1005 {
        (__ci_expr_old_330 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_330) = ((2149384192 as u32)))
        (__ci_expr_old_331 = __local_parsed_pattern__goto_3125_11)
        (__local_parsed_pattern__goto_3125_11 = __local_parsed_pattern__goto_3125_11 + 1)
        ((*__ci_expr_old_331) = ((((2149318656 as u32) +% (5 as u32)) as u32)))
        goto '__ci_bb_1006
    }

    '__ci_bb_1006 {
        goto '__ci_bb_1004
    }

    '__ci_bb_1007 {
        goto '__ci_bb_1009
    }

    '__ci_bb_1008 {
        ((*__local_parsed_pattern__goto_3125_11) = ((2147483648 as u32)))
        if ((if __local_nest_depth__goto_3131_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_1012
        } else {
            goto '__ci_bb_1013
        }
    }

    '__ci_bb_1009 {
        goto '__ci_bb_1010
    }

    '__ci_bb_1010 {
        if (0 != 0) {
            goto '__ci_bb_1009
        } else {
            goto '__ci_bb_1011
        }
    }

    '__ci_bb_1011 {
        (__local_errorcode__goto_3137_5 = ERR63)
        goto '__ci_bb_19
    }

    '__ci_bb_1012 {
        return 0
    }

    '__ci_bb_1013 {
        goto '__ci_bb_585
    }

    '__ci_bb_1014 {
        goto '__ci_bb_1016
    }

    '__ci_bb_1015 {
        goto '__ci_bb_19
    }

    '__ci_bb_1016 {
        if ((if ((((*__local_ptr) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0) {
            goto '__ci_bb_1017
        } else {
            goto '__ci_bb_1018
        }
    }

    '__ci_bb_1017 {
        (__local_ptr = __local_ptr - 1)
        goto '__ci_bb_1016
    }

    '__ci_bb_1018 {
        goto '__ci_bb_1015
    }

    '__ci_bb_1019 {
        goto '__ci_bb_1021
    }

    '__ci_bb_1020 {
        goto '__ci_bb_19
    }

    '__ci_bb_1021 {
        (__ci_expr_logic_332 = 0)
        if ((if __local_ptr < __local_ptrend__goto_3149_12: 1 else: 0) != 0) {
            (__ci_expr_logic_332 = (if (if ((((*__local_ptr) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_332 != 0) {
            goto '__ci_bb_1022
        } else {
            goto '__ci_bb_1023
        }
    }

    '__ci_bb_1022 {
        (__local_ptr = __local_ptr + 1)
        goto '__ci_bb_1021
    }

    '__ci_bb_1023 {
        goto '__ci_bb_1020
    }

    __ci_unreachable()

}

unsafe fn first_significant_code(__param_code: *const u8, __param_skipassert: i32) -> *const u8 {
    var __local_code = __param_code
    while true {
        while true {
            match ((*__local_code) as i32) {
                129 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    loop {
                        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
                            break
                        }
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                130 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    loop {
                        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
                            break
                        }
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                131 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    loop {
                        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
                            break
                        }
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                133 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    loop {
                        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
                        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
                            break
                        }
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                5 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                4 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                172 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                171 => {
                    if ((if not (__param_skipassert != 0): 1 else: 0) != 0) {
                        return __local_code
                    }

                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))

                },
                119 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                147 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                148 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                149 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                150 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                151 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                152 => {
                    (__local_code = __local_code + (((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize) as i32))
                },
                120 => {
                    (__local_code = __local_code + (((((((__local_code[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))
                },
                169 => {
                    (__local_code = __local_code + (((((2 as u32) +% ((((((__local_code[2]) as i32) << (8 as u32)) as i32) | ((__local_code[(2 + 1)]) as i32)) as u32)) as u32) +% (2 as u32)) as usize))
                },
                141 => {
                    var __ci_expr_logic_0: i32

                    if ((if (__local_code[(1 + 2)]) != OP_FALSE: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_0 = (if (if (__local_code[((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32)]) != OP_KET: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        return __local_code
                    }


                    (__local_code = __local_code + ((((((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) +% (1 as u32)) as u32) +% (2 as u32)) as usize))

                },
                146 => {
                    var __ci_expr_logic_0: i32

                    if ((if (__local_code[(1 + 2)]) != OP_FALSE: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_0 = (if (if (__local_code[((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32)]) != OP_KET: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        return __local_code
                    }


                    (__local_code = __local_code + ((((((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) +% (1 as u32)) as u32) +% (2 as u32)) as usize))

                },
                156 => {
                    (__local_code = __local_code + (((((__local_code[1]) as i32) + (_pcre2_OP_lengths_8[(*__local_code)] as i32)) as isize) as usize))
                },
                164 => {
                    (__local_code = __local_code + (((((__local_code[1]) as i32) + (_pcre2_OP_lengths_8[(*__local_code)] as i32)) as isize) as usize))
                },
                158 => {
                    (__local_code = __local_code + (((((__local_code[1]) as i32) + (_pcre2_OP_lengths_8[(*__local_code)] as i32)) as isize) as usize))
                },
                160 => {
                    (__local_code = __local_code + (((((__local_code[1]) as i32) + (_pcre2_OP_lengths_8[(*__local_code)] as i32)) as isize) as usize))
                },
                162 => {
                    (__local_code = __local_code + (((((__local_code[1]) as i32) + (_pcre2_OP_lengths_8[(*__local_code)] as i32)) as isize) as usize))
                },
                _ => {
                    return __local_code
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

}

unsafe fn compile_branch(__param_optionsptr: *mut u32, __param_xoptionsptr: *mut u32, __param_codeptr: *mut *mut u8, __param_pptrptr: *mut *mut u32, __param_errorcodeptr: *mut i32, __param_firstcuptr: *mut u32, __param_firstcuflagsptr: *mut u32, __param_reqcuptr: *mut u32, __param_reqcuflagsptr: *mut u32, __param_bcptr: *mut branch_chain_8, __param_open_caps: *mut open_capitem, __param_cb: *mut compile_block_8, __param_lengthptr: *mut u64) -> i32 {
    var __local_bravalue__goto_6074_5: i32 = 0

    var __local_okreturn__goto_6075_5: i32 = 0

    var __local_group_return__goto_6076_5: i32 = 0

    var __local_repeat_min__goto_6077_10: u32 = 0

    var __local_repeat_max__goto_6077_26: u32 = 0

    var __local_greedy_default__goto_6078_10: u32 = 0

    var __local_greedy_non_default__goto_6078_26: u32 = 0

    var __local_repeat_type__goto_6079_10: u32 = 0

    var __local_op_type__goto_6079_23: u32 = 0

    var __local_options__goto_6080_10: u32 = 0

    var __local_xoptions__goto_6081_10: u32 = 0

    var __local_firstcu__goto_6082_10: u32 = 0

    var __local_reqcu__goto_6082_19: u32 = 0

    var __local_zeroreqcu__goto_6083_10: u32 = 0

    var __local_zerofirstcu__goto_6083_21: u32 = 0

    var __local_pptr__goto_6084_11: *mut u32 = null

    var __local_meta__goto_6085_10: u32 = 0

    var __local_meta_arg__goto_6085_16: u32 = 0

    var __local_firstcuflags__goto_6086_10: u32 = 0

    var __local_reqcuflags__goto_6086_24: u32 = 0

    var __local_zeroreqcuflags__goto_6087_10: u32 = 0

    var __local_zerofirstcuflags__goto_6087_26: u32 = 0

    var __local_req_caseopt__goto_6088_10: u32 = 0

    var __local_reqvary__goto_6088_23: u32 = 0

    var __local_tempreqvary__goto_6088_32: u32 = 0

    var __local_offset__goto_6091_12: u64 = 0

    var __local_length_prevgroup__goto_6092_12: u64 = 0

    var __local_code__goto_6093_14: *mut u8 = null

    var __local_last_code__goto_6094_14: *mut u8 = null

    var __local_orig_code__goto_6095_14: *mut u8 = null

    var __local_tempcode__goto_6096_14: *mut u8 = null

    var __local_previous__goto_6097_14: *mut u8 = null

    var __local_op_previous__goto_6098_13: u8 = 0

    var __local_groupsetfirstcu__goto_6099_6: i32 = 0

    var __local_had_accept__goto_6100_6: i32 = 0

    var __local_matched_char__goto_6101_6: i32 = 0

    var __local_previous_matched_char__goto_6102_6: i32 = 0

    var __local_reset_caseful__goto_6103_6: i32 = 0

    var __local_utf__goto_6110_6: i32 = 0

    var __local_ucp__goto_6111_6: i32 = 0

    var __local_possessive_quantifier__goto_6145_8: i32 = 0

    var __local_note_group_empty__goto_6146_8: i32 = 0

    var __local_mclength__goto_6147_12: u32 = 0

    var __local_skipunits__goto_6148_12: u32 = 0

    var __local_subreqcu__goto_6149_12: u32 = 0

    var __local_subfirstcu__goto_6149_22: u32 = 0

    var __local_groupnumber__goto_6150_12: u32 = 0

    var __local_verbarglen__goto_6151_12: u32 = 0

    var __local_verbculen__goto_6151_24: u32 = 0

    var __local_subreqcuflags__goto_6152_12: u32 = 0

    var __local_subfirstcuflags__goto_6152_27: u32 = 0

    var __local_oc__goto_6153_17: *mut open_capitem = null

    var __local_mcbuffer__goto_6154_15: List[u8] = [0; 8]

    var __local_c__goto_6350_16: u32 = 0

    var __local_caseset__goto_6377_18: u32 = 0

    var __local_c__goto_6419_16: u32 = 0

    var __local_d__goto_6430_18: u32 = 0

    var __local_i__goto_6545_14: i32 = 0

    var __local_count__goto_6597_11: i32 = 0

    var __local_index__goto_6597_18: i32 = 0

    var __local_ng__goto_6598_20: *mut named_group_8 = null

    var __local_i__goto_6660_16: u32 = 0

    var __local_name__goto_6661_18: *const u8 = null

    var __local_ng__goto_6662_20: *mut named_group_8 = null

    var __local_start_pptr__goto_6663_17: *mut u32 = null

    var __local_length__goto_6664_16: u32 = 0

    var __local_count__goto_6747_11: i32 = 0

    var __local_index__goto_6747_18: i32 = 0

    var __local_ng__goto_6748_20: *mut named_group_8 = null

    var __local_tc__goto_6973_20: *mut u8 = null

    var __local_condcount__goto_6974_11: i32 = 0

    var __local_count__goto_7125_11: i32 = 0

    var __local_index__goto_7125_18: i32 = 0

    var __local_name__goto_7126_18: *const u8 = null

    var __local_ng__goto_7127_20: *mut named_group_8 = null

    var __local_length__goto_7128_16: u32 = 0

    var __local_pp__goto_7232_18: *const u8 = null

    var __local_delimiter__goto_7233_16: u32 = 0

    var __local_length__goto_7234_16: u32 = 0

    var __local_callout_string__goto_7235_20: *mut u8 = null

    var __local_lastchar__goto_7382_22: *mut u8 = null

    var __local_replicate__goto_7466_13: i32 = 0

    var __local_delta__goto_7476_22: u64 = 0

    var __local_i__goto_7485_23: i32 = 0

    var __local_length__goto_7502_20: u64 = 0

    var __local_len__goto_7537_13: i32 = 0

    var __local_bralink__goto_7538_22: *mut u8 = null

    var __local_brazeroptr__goto_7539_22: *mut u8 = null

    var __local_linkoffset__goto_7615_17: i32 = 0

    var __local_delta__goto_7646_26: u64 = 0

    var __local_i__goto_7668_29: u32 = 0

    var __local_delta__goto_7696_24: u64 = 0

    var __local_i__goto_7710_30: u32 = 0

    var __local_linkoffset__goto_7719_19: i32 = 0

    var __local_oldlinkoffset__goto_7735_17: i32 = 0

    var __local_linkoffset__goto_7736_17: i32 = 0

    var __local_bra__goto_7737_26: *mut u8 = null

    var __local_ketcode__goto_7774_24: *mut u8 = null

    var __local_bracode__goto_7775_24: *mut u8 = null

    var __local_nlen__goto_7814_21: i32 = 0

    var __local_prop_type__goto_7866_13: i32 = 0

    var __local_prop_value__goto_7866_24: i32 = 0

    var __local_oldcode__goto_7867_22: *mut u8 = null

    var __local_len__goto_8022_11: i32 = 0

    var __local_repcode__goto_8080_22: u32 = 0

    var __local_args__goto_8195_26: *mut recurse_arguments = null

    var __local_current__goto_8209_19: *mut u16 = null

    var __local_end__goto_8209_29: *mut u16 = null

    var __local_ptype__goto_8290_16: u32 = 0

    var __local_pdata__goto_8291_16: u32 = 0

    var __local_caseset__goto_8414_16: u32 = 0

    var __ci_expr_logic_0: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_old_3: *mut u8 = null

    var __ci_expr_old_4: *mut u8 = null

    var __ci_expr_old_5: *mut u8 = null

    var __ci_expr_old_6: *mut u8 = null

    var __ci_expr_old_7: *mut u8 = null

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_ternary_15: i32 = 0

    var __ci_expr_logic_14: i32 = 0

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_old_18: *mut u8 = null

    var __ci_expr_old_19: *mut u8 = null

    var __ci_expr_old_20: *mut u8 = null

    var __ci_expr_old_21: *mut u8 = null

    var __ci_expr_ternary_23: u32 = 0

    var __ci_expr_logic_22: i32 = 0

    var __ci_expr_logic_26: i32 = 0

    var __ci_expr_logic_25: i32 = 0

    var __ci_expr_logic_24: i32 = 0

    var __ci_expr_logic_32: i32 = 0

    var __ci_expr_logic_29: i32 = 0

    var __ci_expr_logic_34: i32 = 0

    var __ci_expr_logic_33: i32 = 0

    var __ci_expr_logic_35: i32 = 0

    var __ci_expr_logic_36: i32 = 0

    var __ci_expr_old_37: *mut u8 = null

    var __ci_expr_old_38: *mut u8 = null

    var __ci_expr_old_39: *mut u8 = null

    var __ci_expr_old_40: *mut u8 = null

    var __ci_expr_old_41: *mut u8 = null

    var __ci_expr_old_42: *mut u8 = null

    var __ci_expr_old_43: *mut u8 = null

    var __ci_expr_logic_44: i32 = 0

    var __ci_expr_ternary_47: i32 = 0

    var __ci_expr_logic_46: i32 = 0

    var __ci_expr_ternary_49: i32 = 0

    var __ci_expr_logic_48: i32 = 0

    var __ci_expr_logic_51: i32 = 0

    var __ci_expr_old_52: *mut u8 = null

    var __ci_expr_logic_54: i32 = 0

    var __ci_expr_logic_53: i32 = 0

    var __ci_expr_logic_55: i32 = 0

    var __ci_expr_logic_56: i32 = 0

    var __ci_expr_old_57: *mut u8 = null

    var __ci_expr_logic_58: i32 = 0

    var __ci_expr_logic_59: i32 = 0

    var __ci_expr_logic_62: i32 = 0

    var __ci_expr_logic_61: i32 = 0

    var __ci_expr_logic_60: i32 = 0

    var __ci_expr_logic_63: i32 = 0

    var __ci_expr_old_64: *mut u8 = null

    var __ci_expr_old_65: *mut u8 = null

    var __ci_expr_old_66: *mut u8 = null

    var __ci_expr_old_67: *const u8 = null

    var __ci_expr_logic_68: i32 = 0

    var __ci_expr_old_69: *mut u8 = null

    var __ci_expr_old_70: *mut u8 = null

    var __ci_expr_old_71: *const u8 = null

    var __ci_expr_old_72: *mut u8 = null

    var __ci_expr_logic_73: i32 = 0

    var __ci_expr_logic_74: i32 = 0

    var __ci_expr_logic_75: i32 = 0

    var __ci_expr_logic_76: i32 = 0

    var __ci_expr_logic_77: i32 = 0

    var __ci_expr_logic_78: i32 = 0

    var __ci_expr_old_79: *mut u8 = null

    var __ci_expr_logic_80: i32 = 0

    var __ci_expr_old_81: *mut u8 = null

    var __ci_expr_logic_82: i32 = 0

    var __ci_expr_old_83: *mut u8 = null

    var __ci_expr_old_84: *mut u8 = null

    var __ci_expr_logic_86: i32 = 0

    var __ci_expr_logic_85: i32 = 0

    var __ci_expr_logic_88: i32 = 0

    var __ci_expr_logic_89: i32 = 0

    var __ci_expr_logic_91: i32 = 0

    var __ci_expr_logic_90: i32 = 0

    var __ci_expr_logic_93: i32 = 0

    var __ci_expr_logic_92: i32 = 0

    var __ci_expr_logic_94: i32 = 0

    var __ci_expr_old_95: *mut u8 = null

    var __ci_expr_old_96: *mut u8 = null

    var __ci_expr_old_97: *mut u8 = null

    var __ci_expr_old_98: *mut u8 = null

    var __ci_expr_logic_99: i32 = 0

    var __ci_expr_logic_100: i32 = 0

    var __ci_expr_logic_101: i32 = 0

    var __ci_expr_logic_102: i32 = 0

    var __ci_expr_old_103: *mut u8 = null

    var __ci_expr_old_104: *mut u8 = null

    var __ci_expr_old_105: *mut u8 = null

    var __ci_expr_logic_106: i32 = 0

    var __ci_expr_logic_107: i32 = 0

    var __ci_expr_logic_108: i32 = 0

    var __ci_expr_logic_109: i32 = 0

    var __ci_expr_old_110: *mut u8 = null

    var __ci_expr_logic_111: i32 = 0

    var __ci_expr_logic_112: i32 = 0

    var __ci_expr_logic_113: i32 = 0

    var __ci_expr_old_114: *mut u8 = null

    var __ci_expr_old_115: *mut u8 = null

    var __ci_expr_old_116: *mut u8 = null

    var __ci_expr_old_117: *mut u8 = null

    var __ci_expr_old_118: *mut u8 = null

    var __ci_expr_old_119: *mut u8 = null

    var __ci_expr_old_120: *mut u8 = null

    var __ci_expr_old_121: *mut u8 = null

    var __ci_expr_old_122: *mut u8 = null

    var __ci_expr_old_123: *mut u8 = null

    var __ci_expr_old_124: *mut u8 = null

    var __ci_expr_old_125: *mut u8 = null

    var __ci_expr_old_126: *mut u8 = null

    var __ci_expr_old_127: *mut u8 = null

    var __ci_expr_old_128: *mut u8 = null

    var __ci_expr_ternary_130: i32 = 0

    var __ci_expr_logic_129: i32 = 0

    var __ci_expr_logic_131: i32 = 0

    var __ci_expr_logic_132: i32 = 0

    var __ci_expr_old_133: *mut u8 = null

    var __ci_expr_old_134: *mut u8 = null

    var __ci_expr_old_135: *mut u8 = null

    var __ci_expr_logic_137: i32 = 0

    var __ci_expr_logic_136: i32 = 0

    var __ci_expr_logic_138: i32 = 0

    var __ci_expr_logic_139: i32 = 0

    var __ci_expr_logic_143: i32 = 0

    var __ci_expr_logic_140: i32 = 0

    var __ci_expr_old_144: *mut u8 = null

    var __ci_expr_old_145: *mut u8 = null

    var __ci_expr_old_146: *mut u8 = null

    var __ci_expr_old_147: *mut u8 = null

    var __ci_expr_old_148: *mut u8 = null

    var __ci_expr_logic_150: i32 = 0

    var __ci_expr_logic_149: i32 = 0

    var __ci_expr_logic_151: i32 = 0

    var __ci_expr_old_152: *mut u8 = null

    var __ci_expr_logic_154: i32 = 0

    var __ci_expr_logic_153: i32 = 0

    var __ci_expr_logic_156: i32 = 0

    var __ci_expr_ternary_158: i32 = 0

    var __ci_expr_logic_157: i32 = 0

    var __ci_expr_logic_160: i32 = 0

    var __ci_expr_logic_159: i32 = 0

    var __ci_expr_old_161: *mut u8 = null

    var __ci_expr_old_162: *mut u8 = null

    var __ci_expr_old_163: *mut u8 = null

    var __ci_expr_old_164: *mut u8 = null

    var __ci_expr_logic_165: i32 = 0

    var __ci_expr_logic_166: i32 = 0

    var __ci_expr_logic_167: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_bravalue__goto_6074_5 = ((0 as i32)))
        (__local_okreturn__goto_6075_5 = ((-1 as i32)))
        (__local_group_return__goto_6076_5 = ((0 as i32)))
        (__local_repeat_min__goto_6077_10 = ((0 as u32)))
        (__local_repeat_max__goto_6077_26 = ((0 as u32)))
        (__local_options__goto_6080_10 = (*__param_optionsptr))
        (__local_xoptions__goto_6081_10 = (*__param_xoptionsptr))
        (__local_pptr__goto_6084_11 = (*__param_pptrptr))
        (__local_offset__goto_6091_12 = ((0 as u64)))
        (__local_length_prevgroup__goto_6092_12 = ((0 as u64)))
        (__local_code__goto_6093_14 = (*__param_codeptr))
        (__local_last_code__goto_6094_14 = __local_code__goto_6093_14)
        (__local_orig_code__goto_6095_14 = __local_code__goto_6093_14)
        (__local_previous__goto_6097_14 = ((null as *mut u8)))
        (__local_groupsetfirstcu__goto_6099_6 = ((0 as i32)))
        (__local_had_accept__goto_6100_6 = ((0 as i32)))
        (__local_matched_char__goto_6101_6 = ((0 as i32)))
        (__local_previous_matched_char__goto_6102_6 = ((0 as i32)))
        (__local_reset_caseful__goto_6103_6 = ((0 as i32)))
        (__local_utf__goto_6110_6 = (((if ((__local_options__goto_6080_10 as u32) & (524288 as u32)) != 0: 1 else: 0) as i32)))
        (__local_ucp__goto_6111_6 = (((if ((__local_options__goto_6080_10 as u32) & (131072 as u32)) != 0: 1 else: 0) as i32)))
        (__local_greedy_default__goto_6078_10 = (((if ((__local_options__goto_6080_10 as u32) & (262144 as u32)) != 0: 1 else: 0) as u32)))
        (__local_greedy_non_default__goto_6078_26 = ((((__local_greedy_default__goto_6078_10 as u32) ^ (1 as u32)) as u32)))
        (__local_zeroreqcu__goto_6083_10 = ((0 as u32)))
        (__local_zerofirstcu__goto_6083_21 = __local_zeroreqcu__goto_6083_10)
        (__local_reqcu__goto_6082_19 = __local_zerofirstcu__goto_6083_21)
        (__local_firstcu__goto_6082_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = ((4294967295 as u32)))
        (__local_zerofirstcuflags__goto_6087_26 = __local_zeroreqcuflags__goto_6087_10)
        (__local_reqcuflags__goto_6086_24 = __local_zerofirstcuflags__goto_6087_26)
        (__local_firstcuflags__goto_6086_10 = __local_reqcuflags__goto_6086_24)
        (__local_req_caseopt__goto_6088_10 = (((if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: (1 as u32) else: (0 as u32)) as u32)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        (__local_meta__goto_6085_10 = (((((*__local_pptr__goto_6084_11) as u32) & (4294901760 as u32)) as u32)))
        (__local_meta_arg__goto_6085_16 = (((((*__local_pptr__goto_6084_11) as u32) & (65535 as u32)) as u32)))
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        goto '__ci_bb_1
    }

    '__ci_bb_5 {
        if ((if __local_code__goto_6093_14 >= ((*__param_cb).start_workspace + ((*__param_cb).workspace_size as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        if ((if __local_meta__goto_6085_10 < 2151153664: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_meta__goto_6085_10 > 2151874560: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_7 {
        goto '__ci_bb_9
    }

    '__ci_bb_8 {
        if ((if __local_code__goto_6093_14 > (((*__param_cb).start_workspace + ((*__param_cb).workspace_size as usize)) - ((100 as isize) as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_9 {
        goto '__ci_bb_10
    }

    '__ci_bb_10 {
        if (0 != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_11 {
        ((*__param_errorcodeptr) = ERR52)
        ((*__param_cb).erroroffset = ((0 as u64)))
        return 0
    }

    '__ci_bb_12 {
        ((*__param_errorcodeptr) = ERR86)
        ((*__param_cb).erroroffset = ((0 as u64)))
        return 0
    }

    '__ci_bb_13 {
        if ((if __local_code__goto_6093_14 < __local_last_code__goto_6094_14: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_14 {
        (__local_code__goto_6093_14 = __local_last_code__goto_6094_14)
        goto '__ci_bb_15
    }

    '__ci_bb_15 {
        if ((if __local_meta__goto_6085_10 < 2151153664: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_meta__goto_6085_10 > 2151874560: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        if ((if ((2147483627 as u64) -% ((*__param_lengthptr) as u64)) < ((((((__local_code__goto_6093_14 as usize) -% (__local_orig_code__goto_6095_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u64)): 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_17 {
        (__local_last_code__goto_6094_14 = __local_code__goto_6093_14)
        goto '__ci_bb_6
    }

    '__ci_bb_18 {
        ((*__param_errorcodeptr) = ERR20)
        ((*__param_cb).erroroffset = ((0 as u64)))
        return 0
    }

    '__ci_bb_19 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% (((((__local_code__goto_6093_14 as usize) -% (__local_orig_code__goto_6095_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        if ((if (*__param_lengthptr) > 65536: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        ((*__param_errorcodeptr) = ERR20)
        ((*__param_cb).erroroffset = ((0 as u64)))
        return 0
    }

    '__ci_bb_21 {
        (__local_code__goto_6093_14 = __local_orig_code__goto_6095_14)
        goto '__ci_bb_17
    }

    '__ci_bb_22 {
        (__local_previous__goto_6097_14 = __local_code__goto_6093_14)
        (__ci_expr_logic_2 = 0)
        if (__local_matched_char__goto_6101_6 != 0) {
            (__ci_expr_logic_2 = (if (if not (__local_had_accept__goto_6100_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        (__local_previous_matched_char__goto_6102_6 = __local_matched_char__goto_6101_6)
        (__local_matched_char__goto_6101_6 = ((0 as i32)))
        (__local_note_group_empty__goto_6146_8 = ((0 as i32)))
        (__local_skipunits__goto_6148_12 = ((0 as u32)))
        goto '__ci_bb_26
    }

    '__ci_bb_24 {
        (__local_okreturn__goto_6075_5 = ((1 as i32)))
        goto '__ci_bb_25
    }

    '__ci_bb_25 {
        goto '__ci_bb_23
    }

    '__ci_bb_26 {
        if (__local_meta__goto_6085_10 == 2147483648) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_621
        }
    }

    '__ci_bb_27 {
        goto '__ci_bb_3
    }

    '__ci_bb_28 {
        ((*__param_firstcuptr) = __local_firstcu__goto_6082_10)
        ((*__param_firstcuflagsptr) = __local_firstcuflags__goto_6086_10)
        ((*__param_reqcuptr) = __local_reqcu__goto_6082_19)
        ((*__param_reqcuflagsptr) = __local_reqcuflags__goto_6086_24)
        ((*__param_codeptr) = __local_code__goto_6093_14)
        ((*__param_pptrptr) = __local_pptr__goto_6084_11)
        return __local_okreturn__goto_6075_5
    }

    '__ci_bb_29 {
        if ((if ((__local_options__goto_6080_10 as u32) & (1024 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_30 {
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_31 {
        (__ci_expr_old_4 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_4) = ((27 as u8)))
        goto '__ci_bb_32
    }

    '__ci_bb_32 {
        goto '__ci_bb_27
    }

    '__ci_bb_33 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        goto '__ci_bb_34
    }

    '__ci_bb_34 {
        (__ci_expr_old_3 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_3) = ((28 as u8)))
        goto '__ci_bb_32
    }

    '__ci_bb_35 {
        (__ci_expr_old_5 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_5) = (((if (if ((__local_options__goto_6080_10 as u32) & (1024 as u32)) != 0: 1 else: 0) != 0: OP_DOLLM else: OP_DOLL) as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_36 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_37 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_38
    }

    '__ci_bb_38 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        (__ci_expr_old_6 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_6) = (((if (if ((__local_options__goto_6080_10 as u32) & (32 as u32)) != 0: 1 else: 0) != 0: OP_ALLANY else: OP_ANY) as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_39 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        if ((if __local_meta__goto_6085_10 == 2148270080: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_40 {
        (__ci_expr_old_7 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_7) = ((13 as u8)))
        goto '__ci_bb_42
    }

    '__ci_bb_41 {
        (__ci_expr_old_8 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_8) = ((110 as u8)))
        with_memset(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), (0 as i32), ((32 as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
        goto '__ci_bb_42
    }

    '__ci_bb_42 {
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        goto '__ci_bb_27
    }

    '__ci_bb_45 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        if ((if (((*__local_pptr__goto_6084_11) as u32) & (1 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        if ((if not (_pcre2_compile_class_nested_8(__local_options__goto_6080_10, __local_xoptions__goto_6081_10, (&raw mut __local_pptr__goto_6084_11 as *mut *mut u32), (&raw mut __local_code__goto_6093_14 as *mut *mut u8), __param_errorcodeptr, __param_cb, __param_lengthptr) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_47 {
        (__ci_expr_logic_9 = 0)
        if ((if (__local_pptr__goto_6084_11[1]) < 2147483648: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if (__local_pptr__goto_6084_11[2]) == 2148335616: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_48 {
        return 0
    }

    '__ci_bb_49 {
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_51 {
        (__local_c__goto_6350_16 = (((__local_pptr__goto_6084_11[1]) as u32)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        if ((if __local_meta__goto_6085_10 == 2148139008: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_52 {
        (__ci_expr_logic_26 = 0)
        (__ci_expr_logic_25 = 0)
        (__ci_expr_logic_24 = 0)
        if ((if __local_meta__goto_6085_10 == 2148139008: 1 else: 0) != 0) {
            (__ci_expr_logic_24 = (if (if (__local_pptr__goto_6084_11[1]) < 2147483648: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            (__ci_expr_logic_25 = (if (if (__local_pptr__goto_6084_11[2]) < 2147483648: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            (__ci_expr_logic_26 = (if (if (__local_pptr__goto_6084_11[3]) == 2148335616: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_53 {
        (__local_meta__goto_6085_10 = __local_c__goto_6350_16)
        goto '__ci_bb_55
    }

    '__ci_bb_54 {
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_55 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        (__ci_expr_logic_154 = 0)
        if (__local_utf__goto_6110_6 != 0) {
            (__ci_expr_logic_153 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_153 = (if __local_ucp__goto_6111_6 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_153 != 0) {
            (__ci_expr_logic_154 = (if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_154 != 0) {
            goto '__ci_bb_593
        } else {
            goto '__ci_bb_594
        }
    }

    '__ci_bb_56 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_57
    }

    '__ci_bb_57 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        (__ci_expr_logic_11 = 0)
        if (__local_utf__goto_6110_6 != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if __local_ucp__goto_6111_6 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_58 {
        (__ci_expr_logic_13 = 0)
        if ((if ((__local_xoptions__goto_6081_10 as u32) & (((65536 as u32) | (128 as u32)) as u32)) == 65536: 1 else: 0) != 0) {
            var __ci_expr_logic_12: i32

            if ((if ((__local_c__goto_6350_16 as u32) | (32 as u32)) == 105: 1 else: 0) != 0) {
                (__ci_expr_logic_12 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_12 = (if (if ((__local_c__goto_6350_16 as u32) | (1 as u32)) == 305: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_13 = (if __ci_expr_logic_12 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_59 {
        (__ci_expr_old_21 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_21) = (((if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: OP_NOTI else: OP_NOT) as u8)))
        (__ci_expr_ternary_23 = 0)
        (__ci_expr_logic_22 = 0)
        if (__local_utf__goto_6110_6 != 0) {
            (__ci_expr_logic_22 = (if (if __local_c__goto_6350_16 > 127: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_ternary_23 = ((_pcre2_ord2utf_8(__local_c__goto_6350_16, __local_code__goto_6093_14) as u32)))
        } else {
            ((*__local_code__goto_6093_14) = ((__local_c__goto_6350_16 as u8)))

            (__ci_expr_ternary_23 = ((1 as u32)))

        }
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (__ci_expr_ternary_23 as usize))
        goto '__ci_bb_27
    }

    '__ci_bb_60 {
        (__ci_expr_ternary_15 = 0)
        if ((if __local_c__goto_6350_16 == 105: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_14 = (if (if __local_c__goto_6350_16 == 304: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            (__ci_expr_ternary_15 = ((0 as i32)))
        } else {
            (__ci_expr_ternary_15 = ((3 as i32)))
        }
        (__local_caseset__goto_6377_18 = ((((_pcre2_ucd_turkish_dotted_i_caseset_8 as u32) +% (__ci_expr_ternary_15 as u32)) as u32)))
        goto '__ci_bb_62
    }

    '__ci_bb_61 {
        (__ci_expr_logic_17 = 0)
        (__ci_expr_logic_16 = 0)
        (__local_caseset__goto_6377_18 = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_6350_16 as i32) / 128)] as i32) * 128) + ((__local_c__goto_6350_16 as i32) % 128))] as u32) as usize)).caseset as u32)))
        if ((if __local_caseset__goto_6377_18 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if ((__local_xoptions__goto_6081_10 as u32) & (128 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            (__ci_expr_logic_17 = (if (if _pcre2_ucd_caseless_sets_8[__local_caseset__goto_6377_18] < 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_62 {
        if ((if __local_caseset__goto_6377_18 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_63 {
        (__local_caseset__goto_6377_18 = ((0 as u32)))
        goto '__ci_bb_64
    }

    '__ci_bb_64 {
        goto '__ci_bb_62
    }

    '__ci_bb_65 {
        (__ci_expr_old_18 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_18) = ((15 as u8)))
        (__ci_expr_old_19 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_19) = ((9 as u8)))
        (__ci_expr_old_20 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_20) = ((__local_caseset__goto_6377_18 as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_66 {
        goto '__ci_bb_59
    }

    '__ci_bb_67 {
        (__local_c__goto_6419_16 = (((__local_pptr__goto_6084_11[1]) as u32)))
        (__ci_expr_logic_32 = 0)
        if ((if ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_6419_16 as i32) / 128)] as i32) * 128) + ((__local_c__goto_6419_16 as i32) % 128))] as u32) as usize)).caseset == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_29 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_28: i32 = 0

            var __ci_expr_logic_27: i32 = 0

            if ((if ((__local_xoptions__goto_6081_10 as u32) & (128 as u32)) != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_27 = (if (if __local_c__goto_6419_16 < 128: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_27 != 0) {
                (__ci_expr_logic_28 = (if (if (__local_pptr__goto_6084_11[2]) < 128: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_29 != 0) {
            var __ci_expr_logic_31: i32 = 0

            if ((if ((__local_xoptions__goto_6081_10 as u32) & (((65536 as u32) | (128 as u32)) as u32)) == 65536: 1 else: 0) != 0) {
                var __ci_expr_logic_30: i32

                if ((if ((__local_c__goto_6419_16 as u32) | (32 as u32)) == 105: 1 else: 0) != 0) {
                    (__ci_expr_logic_30 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_30 = (if (if ((__local_c__goto_6419_16 as u32) | (1 as u32)) == 305: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_31 = (if __ci_expr_logic_30 != 0: 1 else: 0))

            }

            (__ci_expr_logic_32 = (if (if not (__ci_expr_logic_31 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_32 != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_68 {
        (__local_pptr__goto_6084_11 = _pcre2_compile_class_not_nested_8(__local_options__goto_6080_10, __local_xoptions__goto_6081_10, (__local_pptr__goto_6084_11 + ((1 as isize) as usize)), (&raw mut __local_code__goto_6093_14 as *mut *mut u8), ((if __local_meta__goto_6085_10 == 2148401152: 1 else: 0) as i32), (null as *mut i32), __param_errorcodeptr, __param_cb, __param_lengthptr))
        if ((if __local_pptr__goto_6084_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_79
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_69 {
        (__ci_expr_logic_34 = 0)
        if (__local_utf__goto_6110_6 != 0) {
            (__ci_expr_logic_33 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_33 = (if __local_ucp__goto_6111_6 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_33 != 0) {
            (__ci_expr_logic_34 = (if (if __local_c__goto_6419_16 > 127: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_70 {
        goto '__ci_bb_68
    }

    '__ci_bb_71 {
        (__local_d__goto_6430_18 = ((((__local_c__goto_6419_16 as i32) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c__goto_6419_16 as i32) / 128)] as i32) * 128) + ((__local_c__goto_6419_16 as i32) % 128))] as u32) as usize)).other_case) as u32)))
        goto '__ci_bb_73
    }

    '__ci_bb_72 {
        (__local_d__goto_6430_18 = ((((*__param_cb).fcc[__local_c__goto_6419_16]) as u32)))
        goto '__ci_bb_73
    }

    '__ci_bb_73 {
        (__ci_expr_logic_35 = 0)
        if ((if __local_c__goto_6419_16 != __local_d__goto_6430_18: 1 else: 0) != 0) {
            (__ci_expr_logic_35 = (if (if (__local_pptr__goto_6084_11[2]) == __local_d__goto_6430_18: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_35 != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_74 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((3 as isize) as usize))
        (__local_meta__goto_6085_10 = __local_c__goto_6419_16)
        if ((if ((__local_options__goto_6080_10 as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_75 {
        goto '__ci_bb_70
    }

    '__ci_bb_76 {
        (__local_reset_caseful__goto_6103_6 = ((1 as i32)))
        (__local_options__goto_6080_10 = (__local_options__goto_6080_10 as u32) | (8 as u32))
        (__local_req_caseopt__goto_6088_10 = ((1 as u32)))
        goto '__ci_bb_77
    }

    '__ci_bb_77 {
        goto '__ci_bb_78
    }

    '__ci_bb_78 {
        if (__local_utf__goto_6110_6 != 0) {
            goto '__ci_bb_604
        } else {
            goto '__ci_bb_605
        }
    }

    '__ci_bb_79 {
        return 0
    }

    '__ci_bb_80 {
        goto '__ci_bb_81
    }

    '__ci_bb_81 {
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        if (0 != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_83
        }
    }

    '__ci_bb_83 {
        goto '__ci_bb_50
    }

    '__ci_bb_84 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        goto '__ci_bb_27
    }

    '__ci_bb_86 {
        (__local_had_accept__goto_6100_6 = ((1 as i32)))
        ((*__param_cb).had_accept = __local_had_accept__goto_6100_6)
        (__local_oc__goto_6153_17 = __param_open_caps)
        goto '__ci_bb_87
    }

    '__ci_bb_87 {
        (__ci_expr_logic_36 = 0)
        if ((if __local_oc__goto_6153_17 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if (if (*__local_oc__goto_6153_17).assert_depth >= (*__param_cb).assert_depth: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_88 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_89 {
        (__local_oc__goto_6153_17 = (*__local_oc__goto_6153_17).next)
        goto '__ci_bb_87
    }

    '__ci_bb_90 {
        (__ci_expr_old_38 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_38) = (((if (if (*__param_cb).assert_depth > 0: 1 else: 0) != 0: OP_ASSERT_ACCEPT else: OP_ACCEPT) as u8)))
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_91 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% 3))
        goto '__ci_bb_93
    }

    '__ci_bb_92 {
        (__ci_expr_old_37 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_37) = ((168 as u8)))
        ((__local_code__goto_6093_14[0]) = (((((*__local_oc__goto_6153_17).number as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = (((((*__local_oc__goto_6153_17).number as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_93
    }

    '__ci_bb_93 {
        goto '__ci_bb_89
    }

    '__ci_bb_94 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_95
    }

    '__ci_bb_95 {
        goto '__ci_bb_27
    }

    '__ci_bb_96 {
        ((*__param_cb).had_pruneorskip = ((1 as i32)))
        goto '__ci_bb_97
    }

    '__ci_bb_97 {
        (__ci_expr_old_39 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_39) = ((verbops[((((__local_meta__goto_6085_10 as u32) -% (2150432768 as u32)) as u32) >> (16 as u32))] as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_98 {
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (4096 as u32))
        (__ci_expr_old_40 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_40) = ((161 as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_99 {
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (4096 as u32))
        goto '__ci_bb_100
    }

    '__ci_bb_100 {
        (__ci_expr_old_41 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_41) = ((verbops[((((__local_meta__goto_6085_10 as u32) -% (2150432768 as u32)) as u32) >> (16 as u32))] as u8)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_verbarglen__goto_6151_12 = (*__local_pptr__goto_6084_11))
        (__local_verbculen__goto_6151_24 = ((0 as u32)))
        (__ci_expr_old_42 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        (__local_tempcode__goto_6096_14 = __ci_expr_old_42)
        (__local_i__goto_6545_14 = ((0 as i32)))
        goto '__ci_bb_103
    }

    '__ci_bb_101 {
        ((*__param_cb).had_pruneorskip = ((1 as i32)))
        goto '__ci_bb_102
    }

    '__ci_bb_102 {
        goto '__ci_bb_100
    }

    '__ci_bb_103 {
        if ((if __local_i__goto_6545_14 < ((__local_verbarglen__goto_6151_12 as i32)): 1 else: 0) != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_104 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_meta__goto_6085_10 = (*__local_pptr__goto_6084_11))
        if (__local_utf__goto_6110_6 != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_108
        }
    }

    '__ci_bb_105 {
        (__local_i__goto_6545_14 = __local_i__goto_6545_14 + 1)
        goto '__ci_bb_103
    }

    '__ci_bb_106 {
        ((*__local_tempcode__goto_6096_14) = ((__local_verbculen__goto_6151_24 as u8)))
        (__ci_expr_old_43 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_43) = ((0 as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_107 {
        (__local_mclength__goto_6147_12 = ((_pcre2_ord2utf_8(__local_meta__goto_6085_10, (&__local_mcbuffer__goto_6154_15[0] as *mut u8)) as u32)))
        goto '__ci_bb_109
    }

    '__ci_bb_108 {
        (__local_mclength__goto_6147_12 = ((1 as u32)))
        (__local_mcbuffer__goto_6154_15[0] = ((__local_meta__goto_6085_10 as u8)))
        goto '__ci_bb_109
    }

    '__ci_bb_109 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_110 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% __local_mclength__goto_6147_12))
        goto '__ci_bb_112
    }

    '__ci_bb_111 {
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((&__local_mcbuffer__goto_6154_15[0] as *mut u8) as *const u8), ((((__local_mclength__goto_6147_12 as u32) *% (1 as u32)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (__local_mclength__goto_6147_12 as usize))
        (__local_verbculen__goto_6151_24 = (__local_verbculen__goto_6151_24 +% __local_mclength__goto_6147_12))
        goto '__ci_bb_112
    }

    '__ci_bb_112 {
        goto '__ci_bb_105
    }

    '__ci_bb_113 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_options__goto_6080_10 = (*__local_pptr__goto_6084_11))
        ((*__param_optionsptr) = __local_options__goto_6080_10)
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_xoptions__goto_6081_10 = (*__local_pptr__goto_6084_11))
        ((*__param_xoptionsptr) = __local_xoptions__goto_6081_10)
        (__local_greedy_default__goto_6078_10 = (((if ((__local_options__goto_6080_10 as u32) & (262144 as u32)) != 0: 1 else: 0) as u32)))
        (__local_greedy_non_default__goto_6078_26 = ((((__local_greedy_default__goto_6078_10 as u32) ^ (1 as u32)) as u32)))
        (__local_req_caseopt__goto_6088_10 = (((if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: (1 as u32) else: (0 as u32)) as u32)))
        goto '__ci_bb_27
    }

    '__ci_bb_114 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_115 {
        (__local_pptr__goto_6084_11 = _pcre2_compile_parse_scan_substr_args8(__local_pptr__goto_6084_11, __param_errorcodeptr, __param_cb, __param_lengthptr))
        if ((if __local_pptr__goto_6084_11 == null: 1 else: 0) != 0) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_118
        }
    }

    '__ci_bb_116 {
        goto '__ci_bb_119
    }

    '__ci_bb_117 {
        return 0
    }

    '__ci_bb_118 {
        goto '__ci_bb_27
    }

    '__ci_bb_119 {
        if (1 != 0) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_121
        }
    }

    '__ci_bb_120 {
        goto '__ci_bb_122
    }

    '__ci_bb_121 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 - 1)
        goto '__ci_bb_27
    }

    '__ci_bb_122 {
        if ((((*__local_pptr__goto_6084_11) as u32) & (4294901760 as u32)) == 2148925440) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_123 {
        goto '__ci_bb_121
    }

    '__ci_bb_124 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        goto '__ci_bb_119
    }

    '__ci_bb_125 {
        (__local_ng__goto_6598_20 = (*__param_cb).named_groups + ((__local_pptr__goto_6084_11[1]) as usize))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        (__local_count__goto_6597_11 = ((0 as i32)))
        (__local_index__goto_6597_18 = ((0 as i32)))
        if ((if not (_pcre2_compile_find_dupname_details8((*__local_ng__goto_6598_20).name, ((*__local_ng__goto_6598_20).length as u32), (&raw mut __local_index__goto_6597_18 as *mut i32), (&raw mut __local_count__goto_6597_11 as *mut i32), __param_errorcodeptr, __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_126 {
        return 0
    }

    '__ci_bb_127 {
        ((__local_code__goto_6093_14[0]) = ((148 as u8)))
        ((__local_code__goto_6093_14[1]) = ((((__local_index__goto_6597_18 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 1)]) = ((((__local_index__goto_6597_18 as i32) & (255 as i32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 2)]) = ((((__local_count__goto_6597_11 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((1 + 2) + 1)]) = ((((__local_count__goto_6597_11 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((1 + (2 * 2)) as isize) as usize))
        goto '__ci_bb_119
    }

    '__ci_bb_128 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        if ((if (__local_pptr__goto_6084_11[-1]) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_129 {
        goto '__ci_bb_119
    }

    '__ci_bb_130 {
        ((__local_code__goto_6093_14[0]) = ((147 as u8)))
        ((__local_code__goto_6093_14[1]) = (((((__local_pptr__goto_6084_11[-1]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 1)]) = (((((__local_pptr__goto_6084_11[-1]) as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((1 + 2) as isize) as usize))
        goto '__ci_bb_119
    }

    '__ci_bb_131 {
        goto '__ci_bb_123
    }

    '__ci_bb_132 {
        if ((((*__local_pptr__goto_6084_11) as u32) & (4294901760 as u32)) == 2149056512) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_133 {
        if ((((*__local_pptr__goto_6084_11) as u32) & (4294901760 as u32)) == 2149122048) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_134 {
        (__local_bravalue__goto_6074_5 = OP_ASSERT_SCS)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        ((*__param_cb).parens_depth = (((((*__param_cb).parens_depth as i32) +% 1) as u16)))
        ((*__local_code__goto_6093_14) = ((__local_bravalue__goto_6074_5 as u8)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_tempcode__goto_6096_14 = __local_code__goto_6093_14)
        (__local_tempreqvary__goto_6088_32 = (*__param_cb).req_varyopt)
        (__local_length_prevgroup__goto_6092_12 = ((0 as u64)))
        (__local_group_return__goto_6076_5 = ((compile_regex(__local_options__goto_6080_10, __local_xoptions__goto_6081_10, (&raw mut __local_tempcode__goto_6096_14 as *mut *mut u8), (&raw mut __local_pptr__goto_6084_11 as *mut *mut u32), __param_errorcodeptr, __local_skipunits__goto_6148_12, (&raw mut __local_subfirstcu__goto_6149_22 as *mut u32), (&raw mut __local_subfirstcuflags__goto_6152_27 as *mut u32), (&raw mut __local_subreqcu__goto_6149_12 as *mut u32), (&raw mut __local_subreqcuflags__goto_6152_12 as *mut u32), __param_bcptr, __param_open_caps, __param_cb, (if (if __param_lengthptr == null: 1 else: 0) != 0: (null as *mut u64) else: (&raw mut __local_length_prevgroup__goto_6092_12 as *mut u64))) as i32)))
        if ((if __local_group_return__goto_6076_5 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_196
        } else {
            goto '__ci_bb_197
        }
    }

    '__ci_bb_136 {
        (__local_bravalue__goto_6074_5 = OP_COND)
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_137 {
        (__local_start_pptr__goto_6663_17 = __local_pptr__goto_6084_11)
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_length__goto_6664_16 = (*__local_pptr__goto_6084_11))
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        (__local_name__goto_6661_18 = (*__param_cb).start_pattern + (__local_offset__goto_6091_12 as usize))
        (__local_ng__goto_6662_20 = _pcre2_compile_find_named_group8(__local_name__goto_6661_18, __local_length__goto_6664_16, __param_cb))
        if ((if __local_ng__goto_6662_20 == null: 1 else: 0) != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_138 {
        if ((if __local_meta__goto_6085_10 == 2148794368: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_139 {
        goto '__ci_bb_170
    }

    '__ci_bb_140 {
        (__local_groupnumber__goto_6150_12 = ((0 as u32)))
        if ((if __local_meta__goto_6085_10 == 2148794368: 1 else: 0) != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_141 {
        if ((if __local_meta__goto_6085_10 == 2148794368: 1 else: 0) != 0) {
            goto '__ci_bb_158
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_142 {
        (__local_i__goto_6660_16 = ((1 as u32)))
        goto '__ci_bb_144
    }

    '__ci_bb_143 {
        if ((if __local_meta__goto_6085_10 != 2148794368: 1 else: 0) != 0) {
            (__ci_expr_logic_44 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_44 = (if (if __local_groupnumber__goto_6150_12 > (*__param_cb).bracount: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_44 != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_144 {
        if ((if __local_i__goto_6660_16 < __local_length__goto_6664_16: 1 else: 0) != 0) {
            goto '__ci_bb_145
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_145 {
        (__local_groupnumber__goto_6150_12 = ((((((__local_groupnumber__goto_6150_12 as u32) *% (10 as u32)) as u32) +% ((((__local_name__goto_6661_18[__local_i__goto_6660_16]) as i32) - 48) as u32)) as u32)))
        if ((if __local_groupnumber__goto_6150_12 > 65535: 1 else: 0) != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_146 {
        (__local_i__goto_6660_16 = (__local_i__goto_6660_16 +% 1))
        goto '__ci_bb_144
    }

    '__ci_bb_147 {
        goto '__ci_bb_143
    }

    '__ci_bb_148 {
        ((*__param_errorcodeptr) = ERR61)
        ((*__param_cb).erroroffset = ((((__local_offset__goto_6091_12 as u64) +% (__local_i__goto_6660_16 as u64)) as u64)))
        return 0
    }

    '__ci_bb_149 {
        goto '__ci_bb_146
    }

    '__ci_bb_150 {
        ((*__param_errorcodeptr) = ERR15)
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        return 0
    }

    '__ci_bb_151 {
        if ((if __local_groupnumber__goto_6150_12 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_152 {
        (__local_groupnumber__goto_6150_12 = ((65535 as u32)))
        goto '__ci_bb_153
    }

    '__ci_bb_153 {
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        goto '__ci_bb_155
    }

    '__ci_bb_155 {
        if (0 != 0) {
            goto '__ci_bb_154
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_156 {
        ((__local_start_pptr__goto_6663_17[1]) = __local_groupnumber__goto_6150_12)
        (__local_skipunits__goto_6148_12 = ((3 as u32)))
        goto '__ci_bb_157
    }

    '__ci_bb_157 {
        (__local_note_group_empty__goto_6146_8 = ((1 as i32)))
        goto '__ci_bb_135
    }

    '__ci_bb_158 {
        (__local_meta__goto_6085_10 = ((2148597760 as u32)))
        goto '__ci_bb_159
    }

    '__ci_bb_159 {
        if ((if (((*__local_ng__goto_6662_20).hash_dup as i32) & (32768 as i32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_160
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_160 {
        if ((if (*__local_ng__goto_6662_20).number > (*__param_cb).top_backref: 1 else: 0) != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_161 {
        ((__local_start_pptr__goto_6663_17[0]) = ((((__local_meta__goto_6085_10 as u32) | (1 as u32)) as u32)))
        ((__local_start_pptr__goto_6663_17[1]) = ((((((__local_ng__goto_6662_20 as usize) -% ((*__param_cb).named_groups as usize)) as i64) / (sizeof[named_group_8]() as i64)) as u32)))
        (__local_skipunits__goto_6148_12 = ((5 as u32)))
        goto '__ci_bb_139
    }

    '__ci_bb_162 {
        ((*__param_cb).top_backref = (*__local_ng__goto_6662_20).number)
        goto '__ci_bb_163
    }

    '__ci_bb_163 {
        ((__local_start_pptr__goto_6663_17[0]) = __local_meta__goto_6085_10)
        ((__local_start_pptr__goto_6663_17[1]) = (*__local_ng__goto_6662_20).number)
        (__local_skipunits__goto_6148_12 = ((3 as u32)))
        goto '__ci_bb_157
    }

    '__ci_bb_164 {
        ((__local_code__goto_6093_14[(1 + 2)]) = ((149 as u8)))
        ((__local_code__goto_6093_14[(2 + 2)]) = (((((__local_pptr__goto_6084_11[1]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((2 + 2) + 1)]) = (((((__local_pptr__goto_6084_11[1]) as u32) & (255 as u32)) as u8)))
        (__local_skipunits__goto_6148_12 = ((3 as u32)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + (((1 + 2) as isize) as usize))
        goto '__ci_bb_157
    }

    '__ci_bb_165 {
        if ((if __local_meta_arg__goto_6085_16 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_166 {
        ((__local_code__goto_6093_14[(1 + 2)]) = (((if (if __local_meta__goto_6085_10 == 2148728832: 1 else: 0) != 0: OP_RREF else: OP_CREF) as u8)))
        ((__local_code__goto_6093_14[(2 + 2)]) = (((((__local_pptr__goto_6084_11[1]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((2 + 2) + 1)]) = (((((__local_pptr__goto_6084_11[1]) as u32) & (255 as u32)) as u8)))
        (__local_skipunits__goto_6148_12 = ((3 as u32)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + (((1 + 2) as isize) as usize))
        goto '__ci_bb_157
    }

    '__ci_bb_167 {
        (__local_ng__goto_6748_20 = (*__param_cb).named_groups + ((__local_pptr__goto_6084_11[1]) as usize))
        (__local_count__goto_6747_11 = ((0 as i32)))
        (__local_index__goto_6747_18 = ((0 as i32)))
        if ((if not (_pcre2_compile_find_dupname_details8((*__local_ng__goto_6748_20).name, ((*__local_ng__goto_6748_20).length as u32), (&raw mut __local_index__goto_6747_18 as *mut i32), (&raw mut __local_count__goto_6747_11 as *mut i32), __param_errorcodeptr, __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_169
        }
    }

    '__ci_bb_168 {
        return 0
    }

    '__ci_bb_169 {
        ((__local_code__goto_6093_14[(1 + 2)]) = (((if (if __local_meta__goto_6085_10 == 2148728832: 1 else: 0) != 0: OP_DNRREF else: OP_DNCREF) as u8)))
        ((__local_code__goto_6093_14[(2 + 2)]) = ((((__local_index__goto_6747_18 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((2 + 2) + 1)]) = ((((__local_index__goto_6747_18 as i32) & (255 as i32)) as u8)))
        ((__local_code__goto_6093_14[((2 + 2) + 2)]) = ((((__local_count__goto_6747_11 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(((2 + 2) + 2) + 1)]) = ((((__local_count__goto_6747_11 as i32) & (255 as i32)) as u8)))
        (__local_skipunits__goto_6148_12 = ((5 as u32)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + (((1 + 2) as isize) as usize))
        goto '__ci_bb_139
    }

    '__ci_bb_170 {
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        if (0 != 0) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_172 {
        goto '__ci_bb_157
    }

    '__ci_bb_173 {
        (__local_bravalue__goto_6074_5 = OP_COND)
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        ((__local_code__goto_6093_14[(1 + 2)]) = ((170 as u8)))
        (__local_skipunits__goto_6148_12 = ((1 as u32)))
        goto '__ci_bb_135
    }

    '__ci_bb_174 {
        (__local_bravalue__goto_6074_5 = OP_COND)
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_groupnumber__goto_6150_12 = (*__local_pptr__goto_6084_11))
        if ((if __local_groupnumber__goto_6150_12 > (*__param_cb).bracount: 1 else: 0) != 0) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_175 {
        ((*__param_errorcodeptr) = ERR15)
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        return 0
    }

    '__ci_bb_176 {
        if ((if __local_groupnumber__goto_6150_12 > (*__param_cb).top_backref: 1 else: 0) != 0) {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_177 {
        ((*__param_cb).top_backref = __local_groupnumber__goto_6150_12)
        goto '__ci_bb_178
    }

    '__ci_bb_178 {
        (__local_offset__goto_6091_12 = (__local_offset__goto_6091_12 -% 2))
        ((__local_code__goto_6093_14[(1 + 2)]) = ((147 as u8)))
        (__local_skipunits__goto_6148_12 = ((3 as u32)))
        ((__local_code__goto_6093_14[(2 + 2)]) = ((((__local_groupnumber__goto_6150_12 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((2 + 2) + 1)]) = ((((__local_groupnumber__goto_6150_12 as u32) & (255 as u32)) as u8)))
        goto '__ci_bb_157
    }

    '__ci_bb_179 {
        (__local_bravalue__goto_6074_5 = OP_COND)
        if ((if (__local_pptr__goto_6084_11[1]) > 0: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_180 {
        (__ci_expr_ternary_47 = 0)
        if ((if 10 > (__local_pptr__goto_6084_11[2]): 1 else: 0) != 0) {
            (__ci_expr_logic_46 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_45: i32 = 0

            if ((if 10 == (__local_pptr__goto_6084_11[2]): 1 else: 0) != 0) {
                (__ci_expr_logic_45 = (if (if 47 >= (__local_pptr__goto_6084_11[3]): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_46 = (if __ci_expr_logic_45 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_46 != 0) {
            (__ci_expr_ternary_47 = OP_TRUE)
        } else {
            (__ci_expr_ternary_47 = OP_FALSE)
        }
        ((__local_code__goto_6093_14[(1 + 2)]) = ((__ci_expr_ternary_47 as u8)))
        goto '__ci_bb_182
    }

    '__ci_bb_181 {
        (__ci_expr_ternary_49 = 0)
        (__ci_expr_logic_48 = 0)
        if ((if 10 == (__local_pptr__goto_6084_11[2]): 1 else: 0) != 0) {
            (__ci_expr_logic_48 = (if (if 47 == (__local_pptr__goto_6084_11[3]): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_48 != 0) {
            (__ci_expr_ternary_49 = OP_TRUE)
        } else {
            (__ci_expr_ternary_49 = OP_FALSE)
        }
        ((__local_code__goto_6093_14[(1 + 2)]) = ((__ci_expr_ternary_49 as u8)))
        goto '__ci_bb_182
    }

    '__ci_bb_182 {
        (__local_skipunits__goto_6148_12 = ((1 as u32)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((3 as isize) as usize))
        goto '__ci_bb_157
    }

    '__ci_bb_183 {
        (__local_bravalue__goto_6074_5 = OP_COND)
        goto '__ci_bb_157
    }

    '__ci_bb_184 {
        (__local_bravalue__goto_6074_5 = OP_ASSERT)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_185 {
        (__local_bravalue__goto_6074_5 = OP_ASSERT_NA)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_186 {
        (__ci_expr_logic_51 = 0)
        if ((if (__local_pptr__goto_6084_11[1]) == 2149384192: 1 else: 0) != 0) {
            var __ci_expr_logic_50: i32

            if ((if (__local_pptr__goto_6084_11[2]) < 2151153664: 1 else: 0) != 0) {
                (__ci_expr_logic_50 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_50 = (if (if (__local_pptr__goto_6084_11[2]) > 2151874560: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_51 = (if __ci_expr_logic_50 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_51 != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_187 {
        (__ci_expr_old_52 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_52) = ((165 as u8)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        goto '__ci_bb_189
    }

    '__ci_bb_188 {
        (__local_bravalue__goto_6074_5 = OP_ASSERT_NOT)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_189 {
        goto '__ci_bb_27
    }

    '__ci_bb_190 {
        (__local_bravalue__goto_6074_5 = OP_ASSERTBACK)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_191 {
        (__local_bravalue__goto_6074_5 = OP_ASSERTBACK_NOT)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_192 {
        (__local_bravalue__goto_6074_5 = OP_ASSERTBACK_NA)
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) +% 1) as u16)))
        goto '__ci_bb_135
    }

    '__ci_bb_193 {
        (__local_bravalue__goto_6074_5 = OP_ONCE)
        goto '__ci_bb_157
    }

    '__ci_bb_194 {
        (__local_bravalue__goto_6074_5 = OP_SCRIPT_RUN)
        goto '__ci_bb_157
    }

    '__ci_bb_195 {
        (__local_bravalue__goto_6074_5 = OP_BRA)
        goto '__ci_bb_157
    }

    '__ci_bb_196 {
        return 0
    }

    '__ci_bb_197 {
        ((*__param_cb).parens_depth = (((((*__param_cb).parens_depth as i32) -% 1) as u16)))
        (__ci_expr_logic_54 = 0)
        (__ci_expr_logic_53 = 0)
        if (__local_note_group_empty__goto_6146_8 != 0) {
            (__ci_expr_logic_53 = (if (if __local_bravalue__goto_6074_5 != OP_COND: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_53 != 0) {
            (__ci_expr_logic_54 = (if (if __local_group_return__goto_6076_5 > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_54 != 0) {
            goto '__ci_bb_198
        } else {
            goto '__ci_bb_199
        }
    }

    '__ci_bb_198 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        goto '__ci_bb_199
    }

    '__ci_bb_199 {
        (__ci_expr_logic_55 = 0)
        if ((if __local_bravalue__goto_6074_5 >= OP_ASSERT: 1 else: 0) != 0) {
            (__ci_expr_logic_55 = (if (if __local_bravalue__goto_6074_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_55 != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_200 {
        ((*__param_cb).assert_depth = (((((*__param_cb).assert_depth as i32) -% 1) as u16)))
        goto '__ci_bb_201
    }

    '__ci_bb_201 {
        (__ci_expr_logic_56 = 0)
        if ((if __local_bravalue__goto_6074_5 == OP_COND: 1 else: 0) != 0) {
            (__ci_expr_logic_56 = (if (if __param_lengthptr == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_56 != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_203
        }
    }

    '__ci_bb_202 {
        (__local_tc__goto_6973_20 = __local_code__goto_6093_14)
        (__local_condcount__goto_6974_11 = ((0 as i32)))
        goto '__ci_bb_204
    }

    '__ci_bb_203 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_219
        } else {
            goto '__ci_bb_220
        }
    }

    '__ci_bb_204 {
        (__local_condcount__goto_6974_11 = __local_condcount__goto_6974_11 + 1)
        (__local_tc__goto_6973_20 = __local_tc__goto_6973_20 + (((((((__local_tc__goto_6973_20[1]) as i32) << (8 as u32)) as i32) | ((__local_tc__goto_6973_20[(1 + 1)]) as i32)) as u32) as usize))
        goto '__ci_bb_205
    }

    '__ci_bb_205 {
        if ((if (*__local_tc__goto_6973_20) != OP_KET: 1 else: 0) != 0) {
            goto '__ci_bb_204
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_206 {
        if ((if (__local_code__goto_6093_14[(2 + 1)]) == OP_DEFINE: 1 else: 0) != 0) {
            goto '__ci_bb_207
        } else {
            goto '__ci_bb_208
        }
    }

    '__ci_bb_207 {
        if ((if __local_condcount__goto_6974_11 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_210
        } else {
            goto '__ci_bb_211
        }
    }

    '__ci_bb_208 {
        if ((if __local_condcount__goto_6974_11 > 2: 1 else: 0) != 0) {
            goto '__ci_bb_212
        } else {
            goto '__ci_bb_213
        }
    }

    '__ci_bb_209 {
        goto '__ci_bb_203
    }

    '__ci_bb_210 {
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        ((*__param_errorcodeptr) = ERR54)
        return 0
    }

    '__ci_bb_211 {
        ((__local_code__goto_6093_14[(2 + 1)]) = ((151 as u8)))
        (__local_bravalue__goto_6074_5 = OP_DEFINE)
        goto '__ci_bb_209
    }

    '__ci_bb_212 {
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        ((*__param_errorcodeptr) = ERR27)
        return 0
    }

    '__ci_bb_213 {
        if ((if __local_condcount__goto_6974_11 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_214
        } else {
            goto '__ci_bb_215
        }
    }

    '__ci_bb_214 {
        (__local_subreqcuflags__goto_6152_12 = ((4294967294 as u32)))
        (__local_subfirstcuflags__goto_6152_27 = __local_subreqcuflags__goto_6152_12)
        goto '__ci_bb_216
    }

    '__ci_bb_215 {
        if ((if __local_group_return__goto_6076_5 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_216 {
        goto '__ci_bb_209
    }

    '__ci_bb_217 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        goto '__ci_bb_218
    }

    '__ci_bb_218 {
        goto '__ci_bb_216
    }

    '__ci_bb_219 {
        if ((if ((2147483627 as u64) -% ((*__param_lengthptr) as u64)) < ((((__local_length_prevgroup__goto_6092_12 as u64) -% (2 as u64)) as u64) -% (4 as u64)): 1 else: 0) != 0) {
            goto '__ci_bb_221
        } else {
            goto '__ci_bb_222
        }
    }

    '__ci_bb_220 {
        (__local_code__goto_6093_14 = __local_tempcode__goto_6096_14)
        if ((if __local_bravalue__goto_6074_5 == OP_DEFINE: 1 else: 0) != 0) {
            goto '__ci_bb_223
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_221 {
        ((*__param_errorcodeptr) = ERR20)
        return 0
    }

    '__ci_bb_222 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% ((((__local_length_prevgroup__goto_6092_12 as u64) -% (2 as u64)) as u64) -% (4 as u64))))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((__local_code__goto_6093_14[0]) = (((((1 + 2) as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = (((((1 + 2) as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        (__ci_expr_old_57 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_57) = ((122 as u8)))
        ((__local_code__goto_6093_14[0]) = (((((1 + 2) as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = (((((1 + 2) as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_27
    }

    '__ci_bb_223 {
        goto '__ci_bb_27
    }

    '__ci_bb_224 {
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        (__local_groupsetfirstcu__goto_6099_6 = ((0 as i32)))
        if ((if __local_bravalue__goto_6074_5 >= OP_ONCE: 1 else: 0) != 0) {
            goto '__ci_bb_225
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_225 {
        (__ci_expr_logic_58 = 0)
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            (__ci_expr_logic_58 = (if (if __local_subfirstcuflags__goto_6152_27 != 4294967295: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_58 != 0) {
            goto '__ci_bb_228
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_226 {
        (__ci_expr_logic_62 = 0)
        (__ci_expr_logic_61 = 0)
        if ((if __local_bravalue__goto_6074_5 == OP_ASSERT: 1 else: 0) != 0) {
            (__ci_expr_logic_60 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_60 = (if (if __local_bravalue__goto_6074_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_60 != 0) {
            (__ci_expr_logic_61 = (if (if __local_subreqcuflags__goto_6152_12 < 4294967294: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_61 != 0) {
            (__ci_expr_logic_62 = (if (if __local_subfirstcuflags__goto_6152_27 < 4294967294: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_62 != 0) {
            goto '__ci_bb_238
        } else {
            goto '__ci_bb_239
        }
    }

    '__ci_bb_227 {
        goto '__ci_bb_27
    }

    '__ci_bb_228 {
        if ((if __local_subfirstcuflags__goto_6152_27 < 4294967294: 1 else: 0) != 0) {
            goto '__ci_bb_231
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_229 {
        (__ci_expr_logic_59 = 0)
        if ((if __local_subfirstcuflags__goto_6152_27 < 4294967294: 1 else: 0) != 0) {
            (__ci_expr_logic_59 = (if (if __local_subreqcuflags__goto_6152_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_59 != 0) {
            goto '__ci_bb_234
        } else {
            goto '__ci_bb_235
        }
    }

    '__ci_bb_230 {
        if ((if __local_subreqcuflags__goto_6152_12 < 4294967294: 1 else: 0) != 0) {
            goto '__ci_bb_236
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_231 {
        (__local_firstcu__goto_6082_10 = __local_subfirstcu__goto_6149_22)
        (__local_firstcuflags__goto_6086_10 = __local_subfirstcuflags__goto_6152_27)
        (__local_groupsetfirstcu__goto_6099_6 = ((1 as i32)))
        goto '__ci_bb_233
    }

    '__ci_bb_232 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_233
    }

    '__ci_bb_233 {
        (__local_zerofirstcuflags__goto_6087_26 = ((4294967294 as u32)))
        goto '__ci_bb_230
    }

    '__ci_bb_234 {
        (__local_subreqcu__goto_6149_12 = __local_subfirstcu__goto_6149_22)
        (__local_subreqcuflags__goto_6152_12 = ((((__local_subfirstcuflags__goto_6152_27 as u32) | (__local_tempreqvary__goto_6088_32 as u32)) as u32)))
        goto '__ci_bb_235
    }

    '__ci_bb_235 {
        goto '__ci_bb_230
    }

    '__ci_bb_236 {
        (__local_reqcu__goto_6082_19 = __local_subreqcu__goto_6149_12)
        (__local_reqcuflags__goto_6086_24 = __local_subreqcuflags__goto_6152_12)
        goto '__ci_bb_237
    }

    '__ci_bb_237 {
        goto '__ci_bb_227
    }

    '__ci_bb_238 {
        (__local_reqcu__goto_6082_19 = __local_subreqcu__goto_6149_12)
        (__local_reqcuflags__goto_6086_24 = __local_subreqcuflags__goto_6152_12)
        goto '__ci_bb_239
    }

    '__ci_bb_239 {
        goto '__ci_bb_227
    }

    '__ci_bb_240 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_length__goto_7128_16 = (*__local_pptr__goto_6084_11))
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        (__local_name__goto_7126_18 = (*__param_cb).start_pattern + (__local_offset__goto_6091_12 as usize))
        (__local_ng__goto_7127_20 = _pcre2_compile_find_named_group8(__local_name__goto_7126_18, __local_length__goto_7128_16, __param_cb))
        if ((if __local_ng__goto_7127_20 == null: 1 else: 0) != 0) {
            goto '__ci_bb_241
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_241 {
        ((*__param_errorcodeptr) = ERR15)
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        return 0
    }

    '__ci_bb_242 {
        (__local_groupnumber__goto_6150_12 = (*__local_ng__goto_7127_20).number)
        if ((if __local_meta__goto_6085_10 == 2149908480: 1 else: 0) != 0) {
            goto '__ci_bb_243
        } else {
            goto '__ci_bb_244
        }
    }

    '__ci_bb_243 {
        (__local_meta_arg__goto_6085_16 = __local_groupnumber__goto_6150_12)
        goto '__ci_bb_245
    }

    '__ci_bb_244 {
        ((*__param_cb).backref_map = ((*__param_cb).backref_map as u32) | ((if (if __local_groupnumber__goto_6150_12 < 32: 1 else: 0) != 0: (((1 as u32) << (__local_groupnumber__goto_6150_12 as u32)) as u32) else: (1 as u32)) as u32))
        if ((if __local_groupnumber__goto_6150_12 > (*__param_cb).top_backref: 1 else: 0) != 0) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_245 {
        ((*__local_code__goto_6093_14) = ((118 as u8)))
        ((__local_code__goto_6093_14[1]) = ((((__local_meta_arg__goto_6085_16 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 1)]) = ((((__local_meta_arg__goto_6085_16 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((1 + 2) as isize) as usize))
        (__local_length_prevgroup__goto_6092_12 = ((3 as u64)))
        if ((if (((__local_pptr__goto_6084_11[1]) as u32) & (4294901760 as u32)) == 2148925440: 1 else: 0) != 0) {
            (__ci_expr_logic_136 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_136 = (if (if (((__local_pptr__goto_6084_11[1]) as u32) & (4294901760 as u32)) == 2149056512: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_136 != 0) {
            (__ci_expr_logic_137 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_137 = (if (if (((__local_pptr__goto_6084_11[1]) as u32) & (4294901760 as u32)) == 2149122048: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_137 != 0) {
            goto '__ci_bb_535
        } else {
            goto '__ci_bb_536
        }
    }

    '__ci_bb_246 {
        ((*__param_cb).top_backref = __local_groupnumber__goto_6150_12)
        goto '__ci_bb_247
    }

    '__ci_bb_247 {
        if ((if (((*__local_ng__goto_7127_20).hash_dup as i32) & (32768 as i32)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_248
        } else {
            goto '__ci_bb_249
        }
    }

    '__ci_bb_248 {
        (__local_meta_arg__goto_6085_16 = __local_groupnumber__goto_6150_12)
        goto '__ci_bb_250
    }

    '__ci_bb_249 {
        (__local_count__goto_7125_11 = ((0 as i32)))
        (__local_index__goto_7125_18 = ((0 as i32)))
        (__ci_expr_logic_63 = 0)
        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            (__ci_expr_logic_63 = (if (if not (_pcre2_compile_find_dupname_details8(__local_name__goto_7126_18, __local_length__goto_7128_16, (&raw mut __local_index__goto_7125_18 as *mut i32), (&raw mut __local_count__goto_7125_11 as *mut i32), __param_errorcodeptr, __param_cb) != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_63 != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_250 {
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_526
        } else {
            goto '__ci_bb_527
        }
    }

    '__ci_bb_251 {
        return 0
    }

    '__ci_bb_252 {
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_253
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_253 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_254
    }

    '__ci_bb_254 {
        (__ci_expr_old_64 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_64) = (((if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: OP_DNREFI else: OP_DNREF) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_index__goto_7125_18 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_index__goto_7125_18 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        ((__local_code__goto_6093_14[0]) = ((((__local_count__goto_7125_11 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_count__goto_7125_11 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        if ((if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_255 {
        (__ci_expr_old_65 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_65) = (((((if (if ((__local_xoptions__goto_6081_10 as u32) & (128 as u32)) != 0: 1 else: 0) != 0: (1 as i32) else: (0 as i32)) as i32) | ((if (if ((__local_xoptions__goto_6081_10 as u32) & (65536 as u32)) != 0: 1 else: 0) != 0: (2 as i32) else: (0 as i32)) as i32)) as u8)))
        goto '__ci_bb_256
    }

    '__ci_bb_256 {
        goto '__ci_bb_27
    }

    '__ci_bb_257 {
        ((__local_code__goto_6093_14[0]) = ((119 as u8)))
        ((__local_code__goto_6093_14[1]) = (((((__local_pptr__goto_6084_11[1]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 1)]) = (((((__local_pptr__goto_6084_11[1]) as u32) & (255 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 2)]) = (((((__local_pptr__goto_6084_11[2]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((1 + 2) + 1)]) = (((((__local_pptr__goto_6084_11[2]) as u32) & (255 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + (2 * 2))]) = (((__local_pptr__goto_6084_11[3]) as u8)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((3 as isize) as usize))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((_pcre2_OP_lengths_8[OP_CALLOUT] as u32) as usize) as i32))
        goto '__ci_bb_27
    }

    '__ci_bb_258 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_259
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_259 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% (((__local_pptr__goto_6084_11[3]) as u32) +% (9 as u32))))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((3 as isize) as usize))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        goto '__ci_bb_261
    }

    '__ci_bb_260 {
        (__local_length__goto_7234_16 = (((__local_pptr__goto_6084_11[3]) as u32)))
        (__local_callout_string__goto_7235_20 = __local_code__goto_6093_14 + (((1 + (4 * 2)) as isize) as usize))
        ((__local_code__goto_6093_14[0]) = ((120 as u8)))
        ((__local_code__goto_6093_14[1]) = (((((__local_pptr__goto_6084_11[1]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 1)]) = (((((__local_pptr__goto_6084_11[1]) as u32) & (255 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 2)]) = (((((__local_pptr__goto_6084_11[2]) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((1 + 2) + 1)]) = (((((__local_pptr__goto_6084_11[2]) as u32) & (255 as u32)) as u8)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((3 as isize) as usize))
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        (__local_pp__goto_7232_18 = (*__param_cb).start_pattern + (__local_offset__goto_6091_12 as usize))
        (__ci_expr_old_66 = __local_callout_string__goto_7235_20)
        (__local_callout_string__goto_7235_20 = __local_callout_string__goto_7235_20 + 1)
        (__ci_expr_old_67 = __local_pp__goto_7232_18)
        (__local_pp__goto_7232_18 = __local_pp__goto_7232_18 + 1)
        ((*__ci_expr_old_66) = (*__ci_expr_old_67))
        (__local_delimiter__goto_7233_16 = (((*__ci_expr_old_66) as u32)))
        if ((if __local_delimiter__goto_7233_16 == 123: 1 else: 0) != 0) {
            goto '__ci_bb_262
        } else {
            goto '__ci_bb_263
        }
    }

    '__ci_bb_261 {
        goto '__ci_bb_27
    }

    '__ci_bb_262 {
        (__local_delimiter__goto_7233_16 = ((125 as u32)))
        goto '__ci_bb_263
    }

    '__ci_bb_263 {
        ((__local_code__goto_6093_14[(1 + (3 * 2))]) = ((((((__local_offset__goto_6091_12 as u64) +% (1 as u64)) as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((1 + (3 * 2)) + 1)]) = ((((((__local_offset__goto_6091_12 as u64) +% (1 as u64)) as i32) & (255 as i32)) as u8)))
        goto '__ci_bb_264
    }

    '__ci_bb_264 {
        (__local_length__goto_7234_16 = (__local_length__goto_7234_16 -% 1))
        if ((if __local_length__goto_7234_16 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_265
        } else {
            goto '__ci_bb_266
        }
    }

    '__ci_bb_265 {
        (__ci_expr_logic_68 = 0)
        if ((if (*__local_pp__goto_7232_18) == __local_delimiter__goto_7233_16: 1 else: 0) != 0) {
            (__ci_expr_logic_68 = (if (if (__local_pp__goto_7232_18[1]) == __local_delimiter__goto_7233_16: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_68 != 0) {
            goto '__ci_bb_267
        } else {
            goto '__ci_bb_268
        }
    }

    '__ci_bb_266 {
        (__ci_expr_old_72 = __local_callout_string__goto_7235_20)
        (__local_callout_string__goto_7235_20 = __local_callout_string__goto_7235_20 + 1)
        ((*__ci_expr_old_72) = ((0 as u8)))
        ((__local_code__goto_6093_14[(1 + (2 * 2))]) = ((((((((__local_callout_string__goto_7235_20 as usize) -% (__local_code__goto_6093_14 as usize)) as i64) / (sizeof[u8]() as i64)) as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((1 + (2 * 2)) + 1)]) = ((((((((__local_callout_string__goto_7235_20 as usize) -% (__local_code__goto_6093_14 as usize)) as i64) / (sizeof[u8]() as i64)) as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_callout_string__goto_7235_20)
        goto '__ci_bb_261
    }

    '__ci_bb_267 {
        (__ci_expr_old_69 = __local_callout_string__goto_7235_20)
        (__local_callout_string__goto_7235_20 = __local_callout_string__goto_7235_20 + 1)
        ((*__ci_expr_old_69) = ((__local_delimiter__goto_7233_16 as u8)))
        (__local_pp__goto_7232_18 = __local_pp__goto_7232_18 + ((2 as isize) as usize))
        (__local_length__goto_7234_16 = (__local_length__goto_7234_16 -% 1))
        goto '__ci_bb_269
    }

    '__ci_bb_268 {
        (__ci_expr_old_70 = __local_callout_string__goto_7235_20)
        (__local_callout_string__goto_7235_20 = __local_callout_string__goto_7235_20 + 1)
        (__ci_expr_old_71 = __local_pp__goto_7232_18)
        (__local_pp__goto_7232_18 = __local_pp__goto_7232_18 + 1)
        ((*__ci_expr_old_70) = (*__ci_expr_old_71))
        goto '__ci_bb_269
    }

    '__ci_bb_269 {
        goto '__ci_bb_264
    }

    '__ci_bb_270 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_repeat_min__goto_6077_10 = (*__local_pptr__goto_6084_11))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_repeat_max__goto_6077_26 = (*__local_pptr__goto_6084_11))
        goto '__ci_bb_271
    }

    '__ci_bb_271 {
        (__ci_expr_logic_73 = 0)
        if (__local_previous_matched_char__goto_6102_6 != 0) {
            (__ci_expr_logic_73 = (if (if __local_repeat_min__goto_6077_10 > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_73 != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_272 {
        (__local_repeat_min__goto_6077_10 = ((0 as u32)))
        (__local_repeat_max__goto_6077_26 = ((((65535 as u32) +% (1 as u32)) as u32)))
        goto '__ci_bb_271
    }

    '__ci_bb_273 {
        (__local_repeat_min__goto_6077_10 = ((1 as u32)))
        (__local_repeat_max__goto_6077_26 = ((((65535 as u32) +% (1 as u32)) as u32)))
        goto '__ci_bb_271
    }

    '__ci_bb_274 {
        (__local_repeat_min__goto_6077_10 = ((0 as u32)))
        (__local_repeat_max__goto_6077_26 = ((1 as u32)))
        goto '__ci_bb_271
    }

    '__ci_bb_275 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        goto '__ci_bb_276
    }

    '__ci_bb_276 {
        (__local_reqvary__goto_6088_23 = (((if (if __local_repeat_min__goto_6077_10 == __local_repeat_max__goto_6077_26: 1 else: 0) != 0: (0 as u32) else: (2 as u32)) as u32)))
        if ((if __local_repeat_min__goto_6077_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_277
        } else {
            goto '__ci_bb_278
        }
    }

    '__ci_bb_277 {
        (__local_firstcu__goto_6082_10 = __local_zerofirstcu__goto_6083_21)
        (__local_firstcuflags__goto_6086_10 = __local_zerofirstcuflags__goto_6087_26)
        (__local_reqcu__goto_6082_19 = __local_zeroreqcu__goto_6083_10)
        (__local_reqcuflags__goto_6086_24 = __local_zeroreqcuflags__goto_6087_10)
        goto '__ci_bb_278
    }

    '__ci_bb_278 {
        goto '__ci_bb_279
    }

    '__ci_bb_279 {
        if (__local_meta__goto_6085_10 == 2151809024) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_284
        }
    }

    '__ci_bb_280 {
        goto '__ci_bb_291
    }

    '__ci_bb_281 {
        (__local_repeat_type__goto_6079_10 = ((0 as u32)))
        (__local_possessive_quantifier__goto_6145_8 = ((1 as i32)))
        goto '__ci_bb_280
    }

    '__ci_bb_282 {
        (__local_repeat_type__goto_6079_10 = __local_greedy_non_default__goto_6078_26)
        (__local_possessive_quantifier__goto_6145_8 = ((0 as i32)))
        goto '__ci_bb_280
    }

    '__ci_bb_283 {
        (__local_repeat_type__goto_6079_10 = __local_greedy_default__goto_6078_10)
        (__local_possessive_quantifier__goto_6145_8 = ((0 as i32)))
        goto '__ci_bb_280
    }

    '__ci_bb_284 {
        if (__local_meta__goto_6085_10 == 2151219200) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_285
        }
    }

    '__ci_bb_285 {
        if (__local_meta__goto_6085_10 == 2151415808) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_286
        }
    }

    '__ci_bb_286 {
        if (__local_meta__goto_6085_10 == 2151612416) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_287
        }
    }

    '__ci_bb_287 {
        if (__local_meta__goto_6085_10 == 2151874560) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_288
        }
    }

    '__ci_bb_288 {
        if (__local_meta__goto_6085_10 == 2151284736) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_289
        }
    }

    '__ci_bb_289 {
        if (__local_meta__goto_6085_10 == 2151481344) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_290
        }
    }

    '__ci_bb_290 {
        if (__local_meta__goto_6085_10 == 2151677952) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_283
        }
    }

    '__ci_bb_291 {
        goto '__ci_bb_292
    }

    '__ci_bb_292 {
        if (0 != 0) {
            goto '__ci_bb_291
        } else {
            goto '__ci_bb_293
        }
    }

    '__ci_bb_293 {
        (__local_tempcode__goto_6096_14 = __local_previous__goto_6097_14)
        (__local_op_previous__goto_6098_13 = (*__local_previous__goto_6097_14))
        goto '__ci_bb_294
    }

    '__ci_bb_294 {
        if (__local_op_previous__goto_6098_13 == 29) {
            goto '__ci_bb_296
        } else {
            goto '__ci_bb_467
        }
    }

    '__ci_bb_295 {
        if (__local_possessive_quantifier__goto_6145_8 != 0) {
            goto '__ci_bb_491
        } else {
            goto '__ci_bb_492
        }
    }

    '__ci_bb_296 {
        (__ci_expr_logic_74 = 0)
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_74 = (if (if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_74 != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_298
        }
    }

    '__ci_bb_297 {
        goto '__ci_bb_299
    }

    '__ci_bb_298 {
        (__local_op_type__goto_6079_23 = ((chartypeoffset[((__local_op_previous__goto_6098_13 as i32) - OP_CHAR)] as u32)))
        (__ci_expr_logic_75 = 0)
        if (__local_utf__goto_6110_6 != 0) {
            (__ci_expr_logic_75 = (if (if ((((__local_code__goto_6093_14[-1]) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_75 != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_299 {
        ((*__param_cb).req_varyopt = ((*__param_cb).req_varyopt as u32) | (__local_reqvary__goto_6088_23 as u32))
        goto '__ci_bb_27
    }

    '__ci_bb_300 {
        (__local_lastchar__goto_7382_22 = __local_code__goto_6093_14 - ((1 as isize) as usize))
        goto '__ci_bb_303
    }

    '__ci_bb_301 {
        (__local_mcbuffer__goto_6154_15[0] = (((__local_code__goto_6093_14[-1]) as u8)))
        (__local_mclength__goto_6147_12 = ((1 as u32)))
        (__ci_expr_logic_76 = 0)
        if ((if __local_op_previous__goto_6098_13 <= OP_CHARI: 1 else: 0) != 0) {
            (__ci_expr_logic_76 = (if (if __local_repeat_min__goto_6077_10 > 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_76 != 0) {
            goto '__ci_bb_306
        } else {
            goto '__ci_bb_307
        }
    }

    '__ci_bb_302 {
        goto '__ci_bb_310
    }

    '__ci_bb_303 {
        if ((if ((((*__local_lastchar__goto_7382_22) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_305
        }
    }

    '__ci_bb_304 {
        (__local_lastchar__goto_7382_22 = __local_lastchar__goto_7382_22 - 1)
        goto '__ci_bb_303
    }

    '__ci_bb_305 {
        (__local_mclength__goto_6147_12 = ((((((__local_code__goto_6093_14 as usize) -% (__local_lastchar__goto_7382_22 as usize)) as i64) / (sizeof[u8]() as i64)) as u32)))
        with_memcpy(((&__local_mcbuffer__goto_6154_15[0] as *mut u8) as *mut u8), ((__local_lastchar__goto_7382_22 as *const c_void) as *const u8), ((((__local_mclength__goto_6147_12 as u32) *% (1 as u32)) as u64) as i64))
        goto '__ci_bb_302
    }

    '__ci_bb_306 {
        (__local_reqcu__goto_6082_19 = ((__local_mcbuffer__goto_6154_15[0] as u32)))
        (__local_reqcuflags__goto_6086_24 = (*__param_cb).req_varyopt)
        if ((if __local_op_previous__goto_6098_13 == OP_CHARI: 1 else: 0) != 0) {
            goto '__ci_bb_308
        } else {
            goto '__ci_bb_309
        }
    }

    '__ci_bb_307 {
        goto '__ci_bb_302
    }

    '__ci_bb_308 {
        (__local_reqcuflags__goto_6086_24 = (__local_reqcuflags__goto_6086_24 as u32) | (1 as u32))
        goto '__ci_bb_309
    }

    '__ci_bb_309 {
        goto '__ci_bb_307
    }

    '__ci_bb_310 {
        (__local_prop_value__goto_7866_24 = ((-1 as i32)))
        (__local_prop_type__goto_7866_13 = __local_prop_value__goto_7866_24)
        goto '__ci_bb_429
    }

    '__ci_bb_311 {
        if ((if __local_repeat_max__goto_6077_26 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_312
        } else {
            goto '__ci_bb_313
        }
    }

    '__ci_bb_312 {
        (__local_code__goto_6093_14 = __local_previous__goto_6097_14)
        goto '__ci_bb_299
    }

    '__ci_bb_313 {
        (__ci_expr_logic_77 = 0)
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_77 = (if (if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_77 != 0) {
            goto '__ci_bb_314
        } else {
            goto '__ci_bb_315
        }
    }

    '__ci_bb_314 {
        goto '__ci_bb_299
    }

    '__ci_bb_315 {
        (__ci_expr_logic_78 = 0)
        if ((if __local_repeat_min__goto_6077_10 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_78 = (if (if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_78 != 0) {
            goto '__ci_bb_316
        } else {
            goto '__ci_bb_317
        }
    }

    '__ci_bb_316 {
        (__ci_expr_old_79 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_79) = ((((98 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_318
    }

    '__ci_bb_317 {
        (__ci_expr_logic_80 = 0)
        if ((if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_80 = (if (if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_80 != 0) {
            goto '__ci_bb_319
        } else {
            goto '__ci_bb_320
        }
    }

    '__ci_bb_318 {
        goto '__ci_bb_295
    }

    '__ci_bb_319 {
        (__ci_expr_old_81 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_81) = ((((100 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_321
    }

    '__ci_bb_320 {
        (__ci_expr_logic_82 = 0)
        if ((if __local_repeat_min__goto_6077_10 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_82 = (if (if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_82 != 0) {
            goto '__ci_bb_322
        } else {
            goto '__ci_bb_323
        }
    }

    '__ci_bb_321 {
        goto '__ci_bb_318
    }

    '__ci_bb_322 {
        (__ci_expr_old_83 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_83) = ((((102 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_324
    }

    '__ci_bb_323 {
        (__ci_expr_old_84 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_84) = ((((104 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_repeat_min__goto_6077_10 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_repeat_min__goto_6077_10 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        if ((if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_325
        } else {
            goto '__ci_bb_326
        }
    }

    '__ci_bb_324 {
        goto '__ci_bb_321
    }

    '__ci_bb_325 {
        (__local_repeat_max__goto_6077_26 = ((0 as u32)))
        goto '__ci_bb_326
    }

    '__ci_bb_326 {
        ((__local_code__goto_6093_14[0]) = ((((__local_repeat_max__goto_6077_26 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_repeat_max__goto_6077_26 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_324
    }

    '__ci_bb_327 {
        (__ci_expr_logic_86 = 0)
        (__ci_expr_logic_85 = 0)
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_85 = (if (if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_85 != 0) {
            (__ci_expr_logic_86 = (if (if not (__local_possessive_quantifier__goto_6145_8 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_86 != 0) {
            goto '__ci_bb_328
        } else {
            goto '__ci_bb_329
        }
    }

    '__ci_bb_328 {
        goto '__ci_bb_299
    }

    '__ci_bb_329 {
        (__ci_expr_logic_88 = 0)
        if ((if __local_repeat_min__goto_6077_10 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_87: i32

            if ((if __local_repeat_min__goto_6077_10 != 1: 1 else: 0) != 0) {
                (__ci_expr_logic_87 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_87 = (if (if __local_repeat_max__goto_6077_26 != ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_88 = (if __ci_expr_logic_87 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_88 != 0) {
            goto '__ci_bb_330
        } else {
            goto '__ci_bb_331
        }
    }

    '__ci_bb_330 {
        (__local_replicate__goto_7466_13 = ((__local_repeat_min__goto_6077_10 as i32)))
        if ((if __local_repeat_min__goto_6077_10 == __local_repeat_max__goto_6077_26: 1 else: 0) != 0) {
            goto '__ci_bb_332
        } else {
            goto '__ci_bb_333
        }
    }

    '__ci_bb_331 {
        (__local_length__goto_7502_20 = (((if (if __param_lengthptr != null: 1 else: 0) != 0: (3 as u64) else: __local_length_prevgroup__goto_6092_12) as u64)))
        with_memmove(((((__local_previous__goto_6097_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_previous__goto_6097_14 as *const c_void) as *const u8), ((((__local_length__goto_7502_20 as u64) *% (1 as u64)) as u64) as i64))
        ((*__local_previous__goto_6097_14) = ((137 as u8)))
        (__local_op_previous__goto_6098_13 = (*__local_previous__goto_6097_14))
        ((__local_previous__goto_6097_14[1]) = ((((((3 as u64) +% (__local_length__goto_7502_20 as u64)) as u64) >> (8 as u32)) as u8)))
        ((__local_previous__goto_6097_14[(1 + 1)]) = ((((((3 as u64) +% (__local_length__goto_7502_20 as u64)) as u64) & (255 as u64)) as u8)))
        ((__local_previous__goto_6097_14[((3 as u64) +% (__local_length__goto_7502_20 as u64))]) = ((122 as u8)))
        ((__local_previous__goto_6097_14[((4 as u64) +% (__local_length__goto_7502_20 as u64))]) = ((((((3 as u64) +% (__local_length__goto_7502_20 as u64)) as u64) >> (8 as u32)) as u8)))
        ((__local_previous__goto_6097_14[((((4 as u64) +% (__local_length__goto_7502_20 as u64)) as u64) +% (1 as u64))]) = ((((((3 as u64) +% (__local_length__goto_7502_20 as u64)) as u64) & (255 as u64)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((2 + (2 * 2)) as isize) as usize))
        (__local_length_prevgroup__goto_6092_12 = (__local_length_prevgroup__goto_6092_12 +% 6))
        (__local_group_return__goto_6076_5 = ((-1 as i32)))
        goto '__ci_bb_347
    }

    '__ci_bb_332 {
        (__local_replicate__goto_7466_13 = __local_replicate__goto_7466_13 - 1)
        goto '__ci_bb_333
    }

    '__ci_bb_333 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_334
        } else {
            goto '__ci_bb_335
        }
    }

    '__ci_bb_334 {
        if (_pcre2_ckd_smul_8((&raw mut __local_delta__goto_7476_22 as *mut u64), __local_replicate__goto_7466_13, (__local_length_prevgroup__goto_6092_12 as i32)) != 0) {
            (__ci_expr_logic_89 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_89 = (if (if ((2147483627 as u64) -% ((*__param_lengthptr) as u64)) < __local_delta__goto_7476_22: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_89 != 0) {
            goto '__ci_bb_337
        } else {
            goto '__ci_bb_338
        }
    }

    '__ci_bb_335 {
        (__local_i__goto_7485_23 = ((0 as i32)))
        goto '__ci_bb_339
    }

    '__ci_bb_336 {
        if ((if __local_repeat_min__goto_6077_10 == __local_repeat_max__goto_6077_26: 1 else: 0) != 0) {
            goto '__ci_bb_343
        } else {
            goto '__ci_bb_344
        }
    }

    '__ci_bb_337 {
        ((*__param_errorcodeptr) = ERR20)
        return 0
    }

    '__ci_bb_338 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% __local_delta__goto_7476_22))
        goto '__ci_bb_336
    }

    '__ci_bb_339 {
        if ((if __local_i__goto_7485_23 < __local_replicate__goto_7466_13: 1 else: 0) != 0) {
            goto '__ci_bb_340
        } else {
            goto '__ci_bb_342
        }
    }

    '__ci_bb_340 {
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((__local_previous__goto_6097_14 as *const c_void) as *const u8), ((((__local_length_prevgroup__goto_6092_12 as u64) *% (1 as u64)) as u64) as i64))
        (__local_previous__goto_6097_14 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (__local_length_prevgroup__goto_6092_12 as usize))
        goto '__ci_bb_341
    }

    '__ci_bb_341 {
        (__local_i__goto_7485_23 = __local_i__goto_7485_23 + 1)
        goto '__ci_bb_339
    }

    '__ci_bb_342 {
        goto '__ci_bb_336
    }

    '__ci_bb_343 {
        goto '__ci_bb_295
    }

    '__ci_bb_344 {
        if ((if __local_repeat_max__goto_6077_26 != ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_345
        } else {
            goto '__ci_bb_346
        }
    }

    '__ci_bb_345 {
        (__local_repeat_max__goto_6077_26 = (__local_repeat_max__goto_6077_26 -% __local_repeat_min__goto_6077_10))
        goto '__ci_bb_346
    }

    '__ci_bb_346 {
        (__local_repeat_min__goto_6077_10 = ((0 as u32)))
        goto '__ci_bb_331
    }

    '__ci_bb_347 {
        (__local_len__goto_7537_13 = ((((((__local_code__goto_6093_14 as usize) -% (__local_previous__goto_6097_14 as usize)) as i64) / (sizeof[u8]() as i64)) as i32)))
        (__local_bralink__goto_7538_22 = ((null as *mut u8)))
        (__local_brazeroptr__goto_7539_22 = ((null as *mut u8)))
        (__ci_expr_logic_91 = 0)
        (__ci_expr_logic_90 = 0)
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_90 = (if (if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_90 != 0) {
            (__ci_expr_logic_91 = (if (if not (__local_possessive_quantifier__goto_6145_8 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_91 != 0) {
            goto '__ci_bb_348
        } else {
            goto '__ci_bb_349
        }
    }

    '__ci_bb_348 {
        goto '__ci_bb_299
    }

    '__ci_bb_349 {
        (__ci_expr_logic_93 = 0)
        (__ci_expr_logic_92 = 0)
        if ((if __local_op_previous__goto_6098_13 == OP_COND: 1 else: 0) != 0) {
            (__ci_expr_logic_92 = (if (if (__local_previous__goto_6097_14[(2 + 1)]) == OP_FALSE: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_92 != 0) {
            (__ci_expr_logic_93 = (if (if (__local_previous__goto_6097_14[((((((__local_previous__goto_6097_14[1]) as i32) << (8 as u32)) as i32) | ((__local_previous__goto_6097_14[(1 + 1)]) as i32)) as u32)]) != OP_ALT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_93 != 0) {
            goto '__ci_bb_350
        } else {
            goto '__ci_bb_351
        }
    }

    '__ci_bb_350 {
        goto '__ci_bb_299
    }

    '__ci_bb_351 {
        if ((if __local_op_previous__goto_6098_13 < OP_ONCE: 1 else: 0) != 0) {
            goto '__ci_bb_352
        } else {
            goto '__ci_bb_353
        }
    }

    '__ci_bb_352 {
        if ((if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_354
        } else {
            goto '__ci_bb_355
        }
    }

    '__ci_bb_353 {
        if ((if __local_repeat_min__goto_6077_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_356
        } else {
            goto '__ci_bb_357
        }
    }

    '__ci_bb_354 {
        (__local_repeat_max__goto_6077_26 = ((((__local_repeat_min__goto_6077_10 as u32) +% (1 as u32)) as u32)))
        goto '__ci_bb_355
    }

    '__ci_bb_355 {
        goto '__ci_bb_353
    }

    '__ci_bb_356 {
        if ((if __local_repeat_max__goto_6077_26 <= 1: 1 else: 0) != 0) {
            (__ci_expr_logic_94 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_94 = (if (if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_94 != 0) {
            goto '__ci_bb_359
        } else {
            goto '__ci_bb_360
        }
    }

    '__ci_bb_357 {
        if ((if __local_repeat_min__goto_6077_10 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_366
        } else {
            goto '__ci_bb_367
        }
    }

    '__ci_bb_358 {
        if ((if __local_repeat_max__goto_6077_26 != ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_381
        } else {
            goto '__ci_bb_382
        }
    }

    '__ci_bb_359 {
        with_memmove((((__local_previous__goto_6097_14 + ((1 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_previous__goto_6097_14 as *const c_void) as *const u8), (((__local_len__goto_7537_13 * (8 / 8)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        if ((if __local_repeat_max__goto_6077_26 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_362
        } else {
            goto '__ci_bb_363
        }
    }

    '__ci_bb_360 {
        with_memmove(((((__local_previous__goto_6097_14 + ((2 as isize) as usize)) + ((2 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_previous__goto_6097_14 as *const c_void) as *const u8), (((__local_len__goto_7537_13 * (8 / 8)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((2 + 2) as isize) as usize))
        (__ci_expr_old_97 = __local_previous__goto_6097_14)
        (__local_previous__goto_6097_14 = __local_previous__goto_6097_14 + 1)
        ((*__ci_expr_old_97) = ((((153 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        (__ci_expr_old_98 = __local_previous__goto_6097_14)
        (__local_previous__goto_6097_14 = __local_previous__goto_6097_14 + 1)
        ((*__ci_expr_old_98) = ((137 as u8)))
        (__local_linkoffset__goto_7615_17 = (((if (if __local_bralink__goto_7538_22 == null: 1 else: 0) != 0: (0 as i32) else: (((((__local_previous__goto_6097_14 as usize) -% (__local_bralink__goto_7538_22 as usize)) as i64) / (sizeof[u8]() as i64)) as i32)) as i32)))
        (__local_bralink__goto_7538_22 = __local_previous__goto_6097_14)
        ((__local_previous__goto_6097_14[0]) = ((((__local_linkoffset__goto_7615_17 as i32) >> (8 as u32)) as u8)))
        ((__local_previous__goto_6097_14[(0 + 1)]) = ((((__local_linkoffset__goto_7615_17 as i32) & (255 as i32)) as u8)))
        (__local_previous__goto_6097_14 = __local_previous__goto_6097_14 + ((2 as isize) as usize))
        goto '__ci_bb_361
    }

    '__ci_bb_361 {
        if ((if __local_repeat_max__goto_6077_26 != ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_364
        } else {
            goto '__ci_bb_365
        }
    }

    '__ci_bb_362 {
        (__ci_expr_old_95 = __local_previous__goto_6097_14)
        (__local_previous__goto_6097_14 = __local_previous__goto_6097_14 + 1)
        ((*__ci_expr_old_95) = ((169 as u8)))
        goto '__ci_bb_299
    }

    '__ci_bb_363 {
        (__local_brazeroptr__goto_7539_22 = __local_previous__goto_6097_14)
        (__ci_expr_old_96 = __local_previous__goto_6097_14)
        (__local_previous__goto_6097_14 = __local_previous__goto_6097_14 + 1)
        ((*__ci_expr_old_96) = ((((153 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_361
    }

    '__ci_bb_364 {
        (__local_repeat_max__goto_6077_26 = (__local_repeat_max__goto_6077_26 -% 1))
        goto '__ci_bb_365
    }

    '__ci_bb_365 {
        goto '__ci_bb_358
    }

    '__ci_bb_366 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_368
        } else {
            goto '__ci_bb_369
        }
    }

    '__ci_bb_367 {
        if ((if __local_repeat_max__goto_6077_26 != ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_379
        } else {
            goto '__ci_bb_380
        }
    }

    '__ci_bb_368 {
        if (_pcre2_ckd_smul_8((&raw mut __local_delta__goto_7646_26 as *mut u64), (((__local_repeat_min__goto_6077_10 as u32) -% (1 as u32)) as i32), (__local_length_prevgroup__goto_6092_12 as i32)) != 0) {
            (__ci_expr_logic_99 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_99 = (if (if ((2147483627 as u64) -% ((*__param_lengthptr) as u64)) < __local_delta__goto_7646_26: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_99 != 0) {
            goto '__ci_bb_371
        } else {
            goto '__ci_bb_372
        }
    }

    '__ci_bb_369 {
        (__ci_expr_logic_100 = 0)
        if (__local_groupsetfirstcu__goto_6099_6 != 0) {
            (__ci_expr_logic_100 = (if (if __local_reqcuflags__goto_6086_24 >= 4294967294: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_100 != 0) {
            goto '__ci_bb_373
        } else {
            goto '__ci_bb_374
        }
    }

    '__ci_bb_370 {
        goto '__ci_bb_367
    }

    '__ci_bb_371 {
        ((*__param_errorcodeptr) = ERR20)
        return 0
    }

    '__ci_bb_372 {
        ((*__param_lengthptr) = ((*__param_lengthptr) +% __local_delta__goto_7646_26))
        goto '__ci_bb_370
    }

    '__ci_bb_373 {
        (__local_reqcu__goto_6082_19 = __local_firstcu__goto_6082_10)
        (__local_reqcuflags__goto_6086_24 = __local_firstcuflags__goto_6086_10)
        goto '__ci_bb_374
    }

    '__ci_bb_374 {
        (__local_i__goto_7668_29 = ((1 as u32)))
        goto '__ci_bb_375
    }

    '__ci_bb_375 {
        if ((if __local_i__goto_7668_29 < __local_repeat_min__goto_6077_10: 1 else: 0) != 0) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_378
        }
    }

    '__ci_bb_376 {
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((__local_previous__goto_6097_14 as *const c_void) as *const u8), (((__local_len__goto_7537_13 * (8 / 8)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((__local_len__goto_7537_13 as isize) as usize))
        goto '__ci_bb_377
    }

    '__ci_bb_377 {
        (__local_i__goto_7668_29 = (__local_i__goto_7668_29 +% 1))
        goto '__ci_bb_375
    }

    '__ci_bb_378 {
        goto '__ci_bb_370
    }

    '__ci_bb_379 {
        (__local_repeat_max__goto_6077_26 = (__local_repeat_max__goto_6077_26 -% __local_repeat_min__goto_6077_10))
        goto '__ci_bb_380
    }

    '__ci_bb_380 {
        goto '__ci_bb_358
    }

    '__ci_bb_381 {
        (__ci_expr_logic_101 = 0)
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            (__ci_expr_logic_101 = (if (if __local_repeat_max__goto_6077_26 > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_101 != 0) {
            goto '__ci_bb_384
        } else {
            goto '__ci_bb_385
        }
    }

    '__ci_bb_382 {
        (__local_ketcode__goto_7774_24 = (__local_code__goto_6093_14 - ((1 as isize) as usize)) - ((2 as isize) as usize))
        (__local_bracode__goto_7775_24 = __local_ketcode__goto_7774_24 - (((((((__local_ketcode__goto_7774_24[1]) as i32) << (8 as u32)) as i32) | ((__local_ketcode__goto_7774_24[(1 + 1)]) as i32)) as u32) as usize))
        (__ci_expr_logic_106 = 0)
        if ((if (*__local_bracode__goto_7775_24) == OP_ONCE: 1 else: 0) != 0) {
            (__ci_expr_logic_106 = (if __local_possessive_quantifier__goto_6145_8 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_106 != 0) {
            goto '__ci_bb_398
        } else {
            goto '__ci_bb_399
        }
    }

    '__ci_bb_383 {
        goto '__ci_bb_295
    }

    '__ci_bb_384 {
        if (_pcre2_ckd_smul_8((&raw mut __local_delta__goto_7696_24 as *mut u64), (__local_repeat_max__goto_6077_26 as i32), (((((__local_length_prevgroup__goto_6092_12 as i32) + 1) + 2) + (2 * 2)) as i32)) != 0) {
            (__ci_expr_logic_102 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_102 = (if (if ((2147483633 as u64) -% ((*__param_lengthptr) as u64)) < __local_delta__goto_7696_24: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_102 != 0) {
            goto '__ci_bb_387
        } else {
            goto '__ci_bb_388
        }
    }

    '__ci_bb_385 {
        (__local_i__goto_7710_30 = __local_repeat_max__goto_6077_26)
        goto '__ci_bb_389
    }

    '__ci_bb_386 {
        goto '__ci_bb_395
    }

    '__ci_bb_387 {
        ((*__param_errorcodeptr) = ERR20)
        return 0
    }

    '__ci_bb_388 {
        (__local_delta__goto_7696_24 = (__local_delta__goto_7696_24 -% 6))
        ((*__param_lengthptr) = ((*__param_lengthptr) +% __local_delta__goto_7696_24))
        goto '__ci_bb_386
    }

    '__ci_bb_389 {
        if ((if __local_i__goto_7710_30 >= 1: 1 else: 0) != 0) {
            goto '__ci_bb_390
        } else {
            goto '__ci_bb_392
        }
    }

    '__ci_bb_390 {
        (__ci_expr_old_103 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_103) = ((((153 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        if ((if __local_i__goto_7710_30 != 1: 1 else: 0) != 0) {
            goto '__ci_bb_393
        } else {
            goto '__ci_bb_394
        }
    }

    '__ci_bb_391 {
        (__local_i__goto_7710_30 = (__local_i__goto_7710_30 -% 1))
        goto '__ci_bb_389
    }

    '__ci_bb_392 {
        goto '__ci_bb_386
    }

    '__ci_bb_393 {
        (__ci_expr_old_104 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_104) = ((137 as u8)))
        (__local_linkoffset__goto_7719_19 = (((if (if __local_bralink__goto_7538_22 == null: 1 else: 0) != 0: (0 as i32) else: (((((__local_code__goto_6093_14 as usize) -% (__local_bralink__goto_7538_22 as usize)) as i64) / (sizeof[u8]() as i64)) as i32)) as i32)))
        (__local_bralink__goto_7538_22 = __local_code__goto_6093_14)
        ((__local_code__goto_6093_14[0]) = ((((__local_linkoffset__goto_7719_19 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_linkoffset__goto_7719_19 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_394
    }

    '__ci_bb_394 {
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((__local_previous__goto_6097_14 as *const c_void) as *const u8), (((__local_len__goto_7537_13 * (8 / 8)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((__local_len__goto_7537_13 as isize) as usize))
        goto '__ci_bb_391
    }

    '__ci_bb_395 {
        if ((if __local_bralink__goto_7538_22 != null: 1 else: 0) != 0) {
            goto '__ci_bb_396
        } else {
            goto '__ci_bb_397
        }
    }

    '__ci_bb_396 {
        (__local_linkoffset__goto_7736_17 = (((((((__local_code__goto_6093_14 as usize) -% (__local_bralink__goto_7538_22 as usize)) as i64) / (sizeof[u8]() as i64)) + 1) as i32)))
        (__local_bra__goto_7737_26 = __local_code__goto_6093_14 - ((__local_linkoffset__goto_7736_17 as isize) as usize))
        (__local_oldlinkoffset__goto_7735_17 = ((((((((__local_bra__goto_7737_26[1]) as i32) << (8 as u32)) as i32) | ((__local_bra__goto_7737_26[(1 + 1)]) as i32)) as u32) as i32)))
        (__local_bralink__goto_7538_22 = (if (if __local_oldlinkoffset__goto_7735_17 == 0: 1 else: 0) != 0: (null as *mut u8) else: (__local_bralink__goto_7538_22 - ((__local_oldlinkoffset__goto_7735_17 as isize) as usize))))
        (__ci_expr_old_105 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_105) = ((122 as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_linkoffset__goto_7736_17 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_linkoffset__goto_7736_17 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        ((__local_bra__goto_7737_26[1]) = ((((__local_linkoffset__goto_7736_17 as i32) >> (8 as u32)) as u8)))
        ((__local_bra__goto_7737_26[(1 + 1)]) = ((((__local_linkoffset__goto_7736_17 as i32) & (255 as i32)) as u8)))
        goto '__ci_bb_395
    }

    '__ci_bb_397 {
        goto '__ci_bb_383
    }

    '__ci_bb_398 {
        ((*__local_bracode__goto_7775_24) = ((137 as u8)))
        goto '__ci_bb_399
    }

    '__ci_bb_399 {
        if ((if (*__local_bracode__goto_7775_24) == OP_ONCE: 1 else: 0) != 0) {
            (__ci_expr_logic_107 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_107 = (if (if (*__local_bracode__goto_7775_24) == OP_SCRIPT_RUN: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_107 != 0) {
            goto '__ci_bb_400
        } else {
            goto '__ci_bb_401
        }
    }

    '__ci_bb_400 {
        ((*__local_ketcode__goto_7774_24) = ((((123 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_402
    }

    '__ci_bb_401 {
        if ((if __param_lengthptr == null: 1 else: 0) != 0) {
            goto '__ci_bb_403
        } else {
            goto '__ci_bb_404
        }
    }

    '__ci_bb_402 {
        goto '__ci_bb_383
    }

    '__ci_bb_403 {
        if ((if __local_group_return__goto_6076_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_405
        } else {
            goto '__ci_bb_406
        }
    }

    '__ci_bb_404 {
        if (__local_possessive_quantifier__goto_6145_8 != 0) {
            goto '__ci_bb_409
        } else {
            goto '__ci_bb_410
        }
    }

    '__ci_bb_405 {
        ((*__local_bracode__goto_7775_24) = (((((*__local_bracode__goto_7775_24) as i32) +% (OP_SBRA - OP_BRA)) as u8)))
        goto '__ci_bb_406
    }

    '__ci_bb_406 {
        (__ci_expr_logic_108 = 0)
        if ((if (*__local_bracode__goto_7775_24) == OP_COND: 1 else: 0) != 0) {
            (__ci_expr_logic_108 = (if (if (__local_bracode__goto_7775_24[((((((__local_bracode__goto_7775_24[1]) as i32) << (8 as u32)) as i32) | ((__local_bracode__goto_7775_24[(1 + 1)]) as i32)) as u32)]) != OP_ALT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_108 != 0) {
            goto '__ci_bb_407
        } else {
            goto '__ci_bb_408
        }
    }

    '__ci_bb_407 {
        ((*__local_bracode__goto_7775_24) = ((146 as u8)))
        goto '__ci_bb_408
    }

    '__ci_bb_408 {
        goto '__ci_bb_404
    }

    '__ci_bb_409 {
        if ((if (*__local_bracode__goto_7775_24) == OP_COND: 1 else: 0) != 0) {
            (__ci_expr_logic_109 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_109 = (if (if (*__local_bracode__goto_7775_24) == OP_SCOND: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_109 != 0) {
            goto '__ci_bb_412
        } else {
            goto '__ci_bb_413
        }
    }

    '__ci_bb_410 {
        ((*__local_ketcode__goto_7774_24) = ((((123 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_411
    }

    '__ci_bb_411 {
        goto '__ci_bb_402
    }

    '__ci_bb_412 {
        (__local_nlen__goto_7814_21 = ((((((__local_code__goto_6093_14 as usize) -% (__local_bracode__goto_7775_24 as usize)) as i64) / (sizeof[u8]() as i64)) as i32)))
        with_memmove(((((__local_bracode__goto_7775_24 + ((1 as isize) as usize)) + ((2 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_bracode__goto_7775_24 as *const c_void) as *const u8), (((__local_nlen__goto_7814_21 * (8 / 8)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((1 + 2) as isize) as usize))
        (__local_nlen__goto_7814_21 = __local_nlen__goto_7814_21 + (1 + 2))
        ((*__local_bracode__goto_7775_24) = (((if (if (*__local_bracode__goto_7775_24) == OP_COND: 1 else: 0) != 0: OP_BRAPOS else: OP_SBRAPOS) as u8)))
        (__ci_expr_old_110 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_110) = ((125 as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_nlen__goto_7814_21 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_nlen__goto_7814_21 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        ((__local_bracode__goto_7775_24[1]) = ((((__local_nlen__goto_7814_21 as i32) >> (8 as u32)) as u8)))
        ((__local_bracode__goto_7775_24[(1 + 1)]) = ((((__local_nlen__goto_7814_21 as i32) & (255 as i32)) as u8)))
        goto '__ci_bb_414
    }

    '__ci_bb_413 {
        ((*__local_bracode__goto_7775_24) = (((((*__local_bracode__goto_7775_24) as i32) +% 1) as u8)))
        ((*__local_ketcode__goto_7774_24) = ((125 as u8)))
        goto '__ci_bb_414
    }

    '__ci_bb_414 {
        if ((if __local_brazeroptr__goto_7539_22 != null: 1 else: 0) != 0) {
            goto '__ci_bb_415
        } else {
            goto '__ci_bb_416
        }
    }

    '__ci_bb_415 {
        ((*__local_brazeroptr__goto_7539_22) = ((155 as u8)))
        goto '__ci_bb_416
    }

    '__ci_bb_416 {
        if ((if __local_repeat_min__goto_6077_10 < 2: 1 else: 0) != 0) {
            goto '__ci_bb_417
        } else {
            goto '__ci_bb_418
        }
    }

    '__ci_bb_417 {
        (__local_possessive_quantifier__goto_6145_8 = ((0 as i32)))
        goto '__ci_bb_418
    }

    '__ci_bb_418 {
        goto '__ci_bb_411
    }

    '__ci_bb_419 {
        if ((if __local_op_previous__goto_6098_13 >= OP_EODN: 1 else: 0) != 0) {
            (__ci_expr_logic_111 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_111 = (if (if __local_op_previous__goto_6098_13 <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_111 != 0) {
            goto '__ci_bb_420
        } else {
            goto '__ci_bb_421
        }
    }

    '__ci_bb_420 {
        goto '__ci_bb_422
    }

    '__ci_bb_421 {
        (__ci_expr_logic_112 = 0)
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_112 = (if (if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_112 != 0) {
            goto '__ci_bb_425
        } else {
            goto '__ci_bb_426
        }
    }

    '__ci_bb_422 {
        goto '__ci_bb_423
    }

    '__ci_bb_423 {
        if (0 != 0) {
            goto '__ci_bb_422
        } else {
            goto '__ci_bb_424
        }
    }

    '__ci_bb_424 {
        ((*__param_errorcodeptr) = ERR10)
        return 0
    }

    '__ci_bb_425 {
        goto '__ci_bb_299
    }

    '__ci_bb_426 {
        (__local_op_type__goto_6079_23 = ((52 as u32)))
        (__local_mclength__goto_6147_12 = ((0 as u32)))
        if ((if __local_op_previous__goto_6098_13 == OP_PROP: 1 else: 0) != 0) {
            (__ci_expr_logic_113 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_113 = (if (if __local_op_previous__goto_6098_13 == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_113 != 0) {
            goto '__ci_bb_427
        } else {
            goto '__ci_bb_428
        }
    }

    '__ci_bb_427 {
        (__local_prop_type__goto_7866_13 = (((__local_previous__goto_6097_14[1]) as i32)))
        (__local_prop_value__goto_7866_24 = (((__local_previous__goto_6097_14[2]) as i32)))
        goto '__ci_bb_429
    }

    '__ci_bb_428 {
        goto '__ci_bb_310
    }

    '__ci_bb_429 {
        (__local_oldcode__goto_7867_22 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_previous__goto_6097_14)
        if ((if __local_repeat_max__goto_6077_26 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_430
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_430 {
        goto '__ci_bb_299
    }

    '__ci_bb_431 {
        (__local_repeat_type__goto_6079_10 = (__local_repeat_type__goto_6079_10 +% __local_op_type__goto_6079_23))
        if ((if __local_repeat_min__goto_6077_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_432
        } else {
            goto '__ci_bb_433
        }
    }

    '__ci_bb_432 {
        if ((if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_436
        }
    }

    '__ci_bb_433 {
        if ((if __local_repeat_min__goto_6077_10 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_441
        } else {
            goto '__ci_bb_442
        }
    }

    '__ci_bb_434 {
        if ((if __local_mclength__goto_6147_12 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_462
        } else {
            goto '__ci_bb_463
        }
    }

    '__ci_bb_435 {
        (__ci_expr_old_114 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_114) = ((((33 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_437
    }

    '__ci_bb_436 {
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_438
        } else {
            goto '__ci_bb_439
        }
    }

    '__ci_bb_437 {
        goto '__ci_bb_434
    }

    '__ci_bb_438 {
        (__ci_expr_old_115 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_115) = ((((37 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_440
    }

    '__ci_bb_439 {
        (__ci_expr_old_116 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_116) = ((((39 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_repeat_max__goto_6077_26 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_repeat_max__goto_6077_26 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_440
    }

    '__ci_bb_440 {
        goto '__ci_bb_437
    }

    '__ci_bb_441 {
        if ((if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_444
        } else {
            goto '__ci_bb_445
        }
    }

    '__ci_bb_442 {
        (__ci_expr_old_119 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_119) = ((((41 as u32) +% (__local_op_type__goto_6079_23 as u32)) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_repeat_min__goto_6077_10 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_repeat_min__goto_6077_10 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        if ((if __local_repeat_max__goto_6077_26 != __local_repeat_min__goto_6077_10: 1 else: 0) != 0) {
            goto '__ci_bb_449
        } else {
            goto '__ci_bb_450
        }
    }

    '__ci_bb_443 {
        goto '__ci_bb_434
    }

    '__ci_bb_444 {
        (__ci_expr_old_117 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_117) = ((((35 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_446
    }

    '__ci_bb_445 {
        (__local_code__goto_6093_14 = __local_oldcode__goto_7867_22)
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_447
        } else {
            goto '__ci_bb_448
        }
    }

    '__ci_bb_446 {
        goto '__ci_bb_443
    }

    '__ci_bb_447 {
        goto '__ci_bb_299
    }

    '__ci_bb_448 {
        (__ci_expr_old_118 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_118) = ((((39 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((((__local_repeat_max__goto_6077_26 as u32) -% (1 as u32)) as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((((__local_repeat_max__goto_6077_26 as u32) -% (1 as u32)) as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_446
    }

    '__ci_bb_449 {
        if ((if __local_mclength__goto_6147_12 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_451
        } else {
            goto '__ci_bb_452
        }
    }

    '__ci_bb_450 {
        goto '__ci_bb_443
    }

    '__ci_bb_451 {
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((&__local_mcbuffer__goto_6154_15[0] as *mut u8) as *const u8), ((((__local_mclength__goto_6147_12 as u32) *% (1 as u32)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (__local_mclength__goto_6147_12 as usize))
        goto '__ci_bb_453
    }

    '__ci_bb_452 {
        (__ci_expr_old_120 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_120) = __local_op_previous__goto_6098_13)
        if ((if __local_prop_type__goto_7866_13 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_454
        } else {
            goto '__ci_bb_455
        }
    }

    '__ci_bb_453 {
        if ((if __local_repeat_max__goto_6077_26 == ((65535 as u32) +% (1 as u32)): 1 else: 0) != 0) {
            goto '__ci_bb_456
        } else {
            goto '__ci_bb_457
        }
    }

    '__ci_bb_454 {
        (__ci_expr_old_121 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_121) = ((__local_prop_type__goto_7866_13 as u8)))
        (__ci_expr_old_122 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_122) = ((__local_prop_value__goto_7866_24 as u8)))
        goto '__ci_bb_455
    }

    '__ci_bb_455 {
        goto '__ci_bb_453
    }

    '__ci_bb_456 {
        (__ci_expr_old_123 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_123) = ((((33 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_458
    }

    '__ci_bb_457 {
        (__local_repeat_max__goto_6077_26 = (__local_repeat_max__goto_6077_26 -% __local_repeat_min__goto_6077_10))
        if ((if __local_repeat_max__goto_6077_26 == 1: 1 else: 0) != 0) {
            goto '__ci_bb_459
        } else {
            goto '__ci_bb_460
        }
    }

    '__ci_bb_458 {
        goto '__ci_bb_450
    }

    '__ci_bb_459 {
        (__ci_expr_old_124 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_124) = ((((37 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        goto '__ci_bb_461
    }

    '__ci_bb_460 {
        (__ci_expr_old_125 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_125) = ((((39 as u32) +% (__local_repeat_type__goto_6079_10 as u32)) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_repeat_max__goto_6077_26 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_repeat_max__goto_6077_26 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        goto '__ci_bb_461
    }

    '__ci_bb_461 {
        goto '__ci_bb_458
    }

    '__ci_bb_462 {
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((&__local_mcbuffer__goto_6154_15[0] as *mut u8) as *const u8), ((((__local_mclength__goto_6147_12 as u32) *% (1 as u32)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (__local_mclength__goto_6147_12 as usize))
        goto '__ci_bb_464
    }

    '__ci_bb_463 {
        (__ci_expr_old_126 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_126) = __local_op_previous__goto_6098_13)
        if ((if __local_prop_type__goto_7866_13 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_465
        } else {
            goto '__ci_bb_466
        }
    }

    '__ci_bb_464 {
        goto '__ci_bb_295
    }

    '__ci_bb_465 {
        (__ci_expr_old_127 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_127) = ((__local_prop_type__goto_7866_13 as u8)))
        (__ci_expr_old_128 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_128) = ((__local_prop_value__goto_7866_24 as u8)))
        goto '__ci_bb_466
    }

    '__ci_bb_466 {
        goto '__ci_bb_464
    }

    '__ci_bb_467 {
        if (__local_op_previous__goto_6098_13 == 30) {
            goto '__ci_bb_296
        } else {
            goto '__ci_bb_468
        }
    }

    '__ci_bb_468 {
        if (__local_op_previous__goto_6098_13 == 31) {
            goto '__ci_bb_296
        } else {
            goto '__ci_bb_469
        }
    }

    '__ci_bb_469 {
        if (__local_op_previous__goto_6098_13 == 32) {
            goto '__ci_bb_296
        } else {
            goto '__ci_bb_470
        }
    }

    '__ci_bb_470 {
        if (__local_op_previous__goto_6098_13 == 112) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_471
        }
    }

    '__ci_bb_471 {
        if (__local_op_previous__goto_6098_13 == 113) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_472
        }
    }

    '__ci_bb_472 {
        if (__local_op_previous__goto_6098_13 == 110) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_473
        }
    }

    '__ci_bb_473 {
        if (__local_op_previous__goto_6098_13 == 111) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_474
        }
    }

    '__ci_bb_474 {
        if (__local_op_previous__goto_6098_13 == 114) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_475
        }
    }

    '__ci_bb_475 {
        if (__local_op_previous__goto_6098_13 == 115) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_476
        }
    }

    '__ci_bb_476 {
        if (__local_op_previous__goto_6098_13 == 116) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_477
        }
    }

    '__ci_bb_477 {
        if (__local_op_previous__goto_6098_13 == 117) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_478
        }
    }

    '__ci_bb_478 {
        if (__local_op_previous__goto_6098_13 == 118) {
            goto '__ci_bb_327
        } else {
            goto '__ci_bb_479
        }
    }

    '__ci_bb_479 {
        if (__local_op_previous__goto_6098_13 == 128) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_480
        }
    }

    '__ci_bb_480 {
        if (__local_op_previous__goto_6098_13 == 129) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_481
        }
    }

    '__ci_bb_481 {
        if (__local_op_previous__goto_6098_13 == 132) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_482
        }
    }

    '__ci_bb_482 {
        if (__local_op_previous__goto_6098_13 == 130) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_483
        }
    }

    '__ci_bb_483 {
        if (__local_op_previous__goto_6098_13 == 131) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_484
        }
    }

    '__ci_bb_484 {
        if (__local_op_previous__goto_6098_13 == 133) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_485
        }
    }

    '__ci_bb_485 {
        if (__local_op_previous__goto_6098_13 == 134) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_486
        }
    }

    '__ci_bb_486 {
        if (__local_op_previous__goto_6098_13 == 135) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_487
        }
    }

    '__ci_bb_487 {
        if (__local_op_previous__goto_6098_13 == 136) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_488
        }
    }

    '__ci_bb_488 {
        if (__local_op_previous__goto_6098_13 == 137) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_489
        }
    }

    '__ci_bb_489 {
        if (__local_op_previous__goto_6098_13 == 139) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_490
        }
    }

    '__ci_bb_490 {
        if (__local_op_previous__goto_6098_13 == 141) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_419
        }
    }

    '__ci_bb_491 {
        goto '__ci_bb_493
    }

    '__ci_bb_492 {
        goto '__ci_bb_299
    }

    '__ci_bb_493 {
        if ((*__local_tempcode__goto_6096_14) == 93) {
            goto '__ci_bb_495
        } else {
            goto '__ci_bb_501
        }
    }

    '__ci_bb_494 {
        (__local_len__goto_8022_11 = ((((((__local_code__goto_6093_14 as usize) -% (__local_tempcode__goto_6096_14 as usize)) as i64) / (sizeof[u8]() as i64)) as i32)))
        if ((if __local_len__goto_8022_11 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_513
        } else {
            goto '__ci_bb_514
        }
    }

    '__ci_bb_495 {
        (__ci_expr_ternary_130 = 0)
        if ((if (__local_tempcode__goto_6096_14[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
            (__ci_expr_logic_129 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_129 = (if (if (__local_tempcode__goto_6096_14[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_129 != 0) {
            (__ci_expr_ternary_130 = ((2 as i32)))
        } else {
            (__ci_expr_ternary_130 = ((0 as i32)))
        }
        (__local_tempcode__goto_6096_14 = __local_tempcode__goto_6096_14 + ((((_pcre2_OP_lengths_8[(*__local_tempcode__goto_6096_14)] as i32) + __ci_expr_ternary_130) as isize) as usize))
        goto '__ci_bb_494
    }

    '__ci_bb_496 {
        (__local_tempcode__goto_6096_14 = __local_tempcode__goto_6096_14 + (((_pcre2_OP_lengths_8[(*__local_tempcode__goto_6096_14)] as u32) as usize) as i32))
        (__ci_expr_logic_131 = 0)
        if (__local_utf__goto_6110_6 != 0) {
            (__ci_expr_logic_131 = (if (if (__local_tempcode__goto_6096_14[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_131 != 0) {
            goto '__ci_bb_497
        } else {
            goto '__ci_bb_498
        }
    }

    '__ci_bb_497 {
        (__local_tempcode__goto_6096_14 = __local_tempcode__goto_6096_14 + (((_pcre2_utf8_table4[((((__local_tempcode__goto_6096_14[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
        goto '__ci_bb_498
    }

    '__ci_bb_498 {
        goto '__ci_bb_494
    }

    '__ci_bb_499 {
        (__local_tempcode__goto_6096_14 = __local_tempcode__goto_6096_14 + (((1 as u64) +% (((32 as u64) / (sizeof[u8]() as u64)) as u64)) as usize))
        goto '__ci_bb_494
    }

    '__ci_bb_500 {
        (__local_tempcode__goto_6096_14 = __local_tempcode__goto_6096_14 + (((((((__local_tempcode__goto_6096_14[1]) as i32) << (8 as u32)) as i32) | ((__local_tempcode__goto_6096_14[(1 + 1)]) as i32)) as u32) as usize))
        goto '__ci_bb_494
    }

    '__ci_bb_501 {
        if ((*__local_tempcode__goto_6096_14) == 29) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_502
        }
    }

    '__ci_bb_502 {
        if ((*__local_tempcode__goto_6096_14) == 30) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_503
        }
    }

    '__ci_bb_503 {
        if ((*__local_tempcode__goto_6096_14) == 31) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_504
        }
    }

    '__ci_bb_504 {
        if ((*__local_tempcode__goto_6096_14) == 32) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_505
        }
    }

    '__ci_bb_505 {
        if ((*__local_tempcode__goto_6096_14) == 41) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_506
        }
    }

    '__ci_bb_506 {
        if ((*__local_tempcode__goto_6096_14) == 54) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_507
        }
    }

    '__ci_bb_507 {
        if ((*__local_tempcode__goto_6096_14) == 67) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_508
        }
    }

    '__ci_bb_508 {
        if ((*__local_tempcode__goto_6096_14) == 80) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_509
        }
    }

    '__ci_bb_509 {
        if ((*__local_tempcode__goto_6096_14) == 110) {
            goto '__ci_bb_499
        } else {
            goto '__ci_bb_510
        }
    }

    '__ci_bb_510 {
        if ((*__local_tempcode__goto_6096_14) == 111) {
            goto '__ci_bb_499
        } else {
            goto '__ci_bb_511
        }
    }

    '__ci_bb_511 {
        if ((*__local_tempcode__goto_6096_14) == 112) {
            goto '__ci_bb_500
        } else {
            goto '__ci_bb_512
        }
    }

    '__ci_bb_512 {
        if ((*__local_tempcode__goto_6096_14) == 113) {
            goto '__ci_bb_500
        } else {
            goto '__ci_bb_494
        }
    }

    '__ci_bb_513 {
        (__local_repcode__goto_8080_22 = (((*__local_tempcode__goto_6096_14) as u32)))
        (__ci_expr_logic_132 = 0)
        if ((if __local_repcode__goto_8080_22 < 119: 1 else: 0) != 0) {
            (__ci_expr_logic_132 = (if (if opcode_possessify[__local_repcode__goto_8080_22] > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_132 != 0) {
            goto '__ci_bb_515
        } else {
            goto '__ci_bb_516
        }
    }

    '__ci_bb_514 {
        goto '__ci_bb_492
    }

    '__ci_bb_515 {
        ((*__local_tempcode__goto_6096_14) = ((opcode_possessify[__local_repcode__goto_8080_22] as u8)))
        goto '__ci_bb_517
    }

    '__ci_bb_516 {
        with_memmove(((((__local_tempcode__goto_6096_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_tempcode__goto_6096_14 as *const c_void) as *const u8), (((__local_len__goto_8022_11 * (8 / 8)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((1 + 2) as isize) as usize))
        (__local_len__goto_8022_11 = __local_len__goto_8022_11 + (1 + 2))
        ((__local_tempcode__goto_6096_14[0]) = ((135 as u8)))
        (__ci_expr_old_133 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_133) = ((122 as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_len__goto_8022_11 as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_len__goto_8022_11 as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        ((__local_tempcode__goto_6096_14[1]) = ((((__local_len__goto_8022_11 as i32) >> (8 as u32)) as u8)))
        ((__local_tempcode__goto_6096_14[(1 + 1)]) = ((((__local_len__goto_8022_11 as i32) & (255 as i32)) as u8)))
        goto '__ci_bb_517
    }

    '__ci_bb_517 {
        goto '__ci_bb_514
    }

    '__ci_bb_518 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        goto '__ci_bb_519
    }

    '__ci_bb_519 {
        (__local_meta__goto_6085_10 = (*__local_pptr__goto_6084_11))
        goto '__ci_bb_55
    }

    '__ci_bb_520 {
        if ((if __local_meta_arg__goto_6085_16 < 10: 1 else: 0) != 0) {
            goto '__ci_bb_521
        } else {
            goto '__ci_bb_522
        }
    }

    '__ci_bb_521 {
        (__local_offset__goto_6091_12 = (((*__param_cb).small_ref_offset[__local_meta_arg__goto_6085_16] as u64)))
        goto '__ci_bb_523
    }

    '__ci_bb_522 {
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        goto '__ci_bb_523
    }

    '__ci_bb_523 {
        if ((if __local_meta_arg__goto_6085_16 > (*__param_cb).bracount: 1 else: 0) != 0) {
            goto '__ci_bb_524
        } else {
            goto '__ci_bb_525
        }
    }

    '__ci_bb_524 {
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        ((*__param_errorcodeptr) = ERR15)
        return 0
    }

    '__ci_bb_525 {
        goto '__ci_bb_250
    }

    '__ci_bb_526 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        goto '__ci_bb_527
    }

    '__ci_bb_527 {
        (__ci_expr_old_134 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_134) = (((if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: OP_REFI else: OP_REF) as u8)))
        ((__local_code__goto_6093_14[0]) = ((((__local_meta_arg__goto_6085_16 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(0 + 1)]) = ((((__local_meta_arg__goto_6085_16 as u32) & (255 as u32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + ((2 as isize) as usize))
        if ((if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_528
        } else {
            goto '__ci_bb_529
        }
    }

    '__ci_bb_528 {
        (__ci_expr_old_135 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_135) = (((((if (if ((__local_xoptions__goto_6081_10 as u32) & (128 as u32)) != 0: 1 else: 0) != 0: (1 as i32) else: (0 as i32)) as i32) | ((if (if ((__local_xoptions__goto_6081_10 as u32) & (65536 as u32)) != 0: 1 else: 0) != 0: (2 as i32) else: (0 as i32)) as i32)) as u8)))
        goto '__ci_bb_529
    }

    '__ci_bb_529 {
        ((*__param_cb).backref_map = ((*__param_cb).backref_map as u32) | ((if (if __local_meta_arg__goto_6085_16 < 32: 1 else: 0) != 0: (((1 as u32) << (__local_meta_arg__goto_6085_16 as u32)) as u32) else: (1 as u32)) as u32))
        if ((if __local_meta_arg__goto_6085_16 > (*__param_cb).top_backref: 1 else: 0) != 0) {
            goto '__ci_bb_530
        } else {
            goto '__ci_bb_531
        }
    }

    '__ci_bb_530 {
        ((*__param_cb).top_backref = __local_meta_arg__goto_6085_16)
        goto '__ci_bb_531
    }

    '__ci_bb_531 {
        goto '__ci_bb_27
    }

    '__ci_bb_532 {
        (__local_offset__goto_6091_12 = (((((((__local_pptr__goto_6084_11[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr__goto_6084_11[2]) as u64)) as u64)))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((2 as isize) as usize))
        if ((if __local_meta_arg__goto_6085_16 > (*__param_cb).bracount: 1 else: 0) != 0) {
            goto '__ci_bb_533
        } else {
            goto '__ci_bb_534
        }
    }

    '__ci_bb_533 {
        ((*__param_cb).erroroffset = __local_offset__goto_6091_12)
        ((*__param_errorcodeptr) = ERR15)
        return 0
    }

    '__ci_bb_534 {
        goto '__ci_bb_245
    }

    '__ci_bb_535 {
        if ((if __param_lengthptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_537
        } else {
            goto '__ci_bb_538
        }
    }

    '__ci_bb_536 {
        (__local_groupsetfirstcu__goto_6099_6 = ((0 as i32)))
        ((*__param_cb).had_recurse = ((1 as i32)))
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_551
        } else {
            goto '__ci_bb_552
        }
    }

    '__ci_bb_537 {
        if ((if not (_pcre2_compile_parse_recurse_args8(__local_pptr__goto_6084_11, __local_offset__goto_6091_12, __param_errorcodeptr, __param_cb) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_540
        } else {
            goto '__ci_bb_541
        }
    }

    '__ci_bb_538 {
        (__local_args__goto_8195_26 = (((*__param_cb).first_data as *mut recurse_arguments)))
        goto '__ci_bb_542
    }

    '__ci_bb_539 {
        goto '__ci_bb_536
    }

    '__ci_bb_540 {
        return 0
    }

    '__ci_bb_541 {
        (__local_args__goto_8195_26 = (((*__param_cb).last_data as *mut recurse_arguments)))
        (__local_length_prevgroup__goto_6092_12 = (__local_length_prevgroup__goto_6092_12 +% (((*__local_args__goto_8195_26).size as u64) *% (3 as u64))))
        ((*__param_lengthptr) = ((*__param_lengthptr) +% (((*__local_args__goto_8195_26).size as u64) *% (3 as u64))))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((*__local_args__goto_8195_26).skip_size as usize))
        goto '__ci_bb_539
    }

    '__ci_bb_542 {
        goto '__ci_bb_543
    }

    '__ci_bb_543 {
        if (0 != 0) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_544
        }
    }

    '__ci_bb_544 {
        (__local_current__goto_8209_19 = (((__local_args__goto_8195_26 + ((1 as isize) as usize)) as *mut u16)))
        (__local_end__goto_8209_29 = __local_current__goto_8209_19 + ((*__local_args__goto_8195_26).size as usize))
        goto '__ci_bb_545
    }

    '__ci_bb_545 {
        goto '__ci_bb_546
    }

    '__ci_bb_546 {
        if (0 != 0) {
            goto '__ci_bb_545
        } else {
            goto '__ci_bb_547
        }
    }

    '__ci_bb_547 {
        goto '__ci_bb_548
    }

    '__ci_bb_548 {
        ((__local_code__goto_6093_14[0]) = ((147 as u8)))
        ((__local_code__goto_6093_14[1]) = (((((*__local_current__goto_8209_19) as i32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[(1 + 1)]) = (((((*__local_current__goto_8209_19) as i32) & (255 as i32)) as u8)))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((1 + 2) as isize) as usize))
        goto '__ci_bb_549
    }

    '__ci_bb_549 {
        (__local_current__goto_8209_19 = __local_current__goto_8209_19 + 1)
        if ((if __local_current__goto_8209_19 < __local_end__goto_8209_29: 1 else: 0) != 0) {
            goto '__ci_bb_548
        } else {
            goto '__ci_bb_550
        }
    }

    '__ci_bb_550 {
        (__local_length_prevgroup__goto_6092_12 = (__local_length_prevgroup__goto_6092_12 +% (((*__local_args__goto_8195_26).size as u64) *% (3 as u64))))
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + ((*__local_args__goto_8195_26).skip_size as usize))
        ((*__param_cb).first_data = (*(&raw const (*__local_args__goto_8195_26).header as *const compile_data)).next)
        (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).free.unwrap()((__local_args__goto_8195_26 as *mut c_void), (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).memory_data)
        goto '__ci_bb_539
    }

    '__ci_bb_551 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_552
    }

    '__ci_bb_552 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        goto '__ci_bb_27
    }

    '__ci_bb_553 {
        (__local_bravalue__goto_6074_5 = OP_CBRA)
        (__local_skipunits__goto_6148_12 = ((2 as u32)))
        ((__local_code__goto_6093_14[(1 + 2)]) = ((((__local_meta_arg__goto_6085_16 as u32) >> (8 as u32)) as u8)))
        ((__local_code__goto_6093_14[((1 + 2) + 1)]) = ((((__local_meta_arg__goto_6085_16 as u32) & (255 as u32)) as u8)))
        ((*__param_cb).lastcapture = __local_meta_arg__goto_6085_16)
        goto '__ci_bb_157
    }

    '__ci_bb_554 {
        (__ci_expr_logic_138 = 0)
        if ((if __local_meta_arg__goto_6085_16 > 5: 1 else: 0) != 0) {
            (__ci_expr_logic_138 = (if (if __local_meta_arg__goto_6085_16 < 23: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_138 != 0) {
            goto '__ci_bb_555
        } else {
            goto '__ci_bb_556
        }
    }

    '__ci_bb_555 {
        (__local_matched_char__goto_6101_6 = ((1 as i32)))
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_557
        } else {
            goto '__ci_bb_558
        }
    }

    '__ci_bb_556 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        if ((if __local_meta_arg__goto_6085_16 == 15: 1 else: 0) != 0) {
            (__ci_expr_logic_139 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_139 = (if (if __local_meta_arg__goto_6085_16 == 16: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_139 != 0) {
            goto '__ci_bb_559
        } else {
            goto '__ci_bb_560
        }
    }

    '__ci_bb_557 {
        (__local_firstcuflags__goto_6086_10 = ((4294967294 as u32)))
        goto '__ci_bb_558
    }

    '__ci_bb_558 {
        goto '__ci_bb_556
    }

    '__ci_bb_559 {
        (__local_pptr__goto_6084_11 = __local_pptr__goto_6084_11 + 1)
        (__local_ptype__goto_8290_16 = (((((*__local_pptr__goto_6084_11) as u32) >> (16 as u32)) as u32)))
        (__local_pdata__goto_8291_16 = (((((*__local_pptr__goto_6084_11) as u32) & (65535 as u32)) as u32)))
        (__ci_expr_logic_143 = 0)
        (__ci_expr_logic_140 = 0)
        if ((if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_140 = (if (if __local_ptype__goto_8290_16 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_140 != 0) {
            var __ci_expr_logic_142: i32

            var __ci_expr_logic_141: i32

            if ((if __local_pdata__goto_8291_16 == 9: 1 else: 0) != 0) {
                (__ci_expr_logic_141 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_141 = (if (if __local_pdata__goto_8291_16 == 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_141 != 0) {
                (__ci_expr_logic_142 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_142 = (if (if __local_pdata__goto_8291_16 == 8: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_143 = (if __ci_expr_logic_142 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_143 != 0) {
            goto '__ci_bb_561
        } else {
            goto '__ci_bb_562
        }
    }

    '__ci_bb_560 {
        (__ci_expr_logic_150 = 0)
        (__ci_expr_logic_149 = 0)
        if ((if (*__param_cb).assert_depth > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_149 = (if (if __local_meta_arg__goto_6085_16 == 3: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_149 != 0) {
            (__ci_expr_logic_150 = (if (if ((__local_xoptions__goto_6081_10 as u32) & (64 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_150 != 0) {
            goto '__ci_bb_569
        } else {
            goto '__ci_bb_570
        }
    }

    '__ci_bb_561 {
        (__local_ptype__goto_8290_16 = ((0 as u32)))
        (__local_pdata__goto_8291_16 = ((0 as u32)))
        goto '__ci_bb_562
    }

    '__ci_bb_562 {
        if ((if __local_ptype__goto_8290_16 == 13: 1 else: 0) != 0) {
            goto '__ci_bb_563
        } else {
            goto '__ci_bb_564
        }
    }

    '__ci_bb_563 {
        if ((if __local_meta_arg__goto_6085_16 == 15: 1 else: 0) != 0) {
            goto '__ci_bb_566
        } else {
            goto '__ci_bb_567
        }
    }

    '__ci_bb_564 {
        (__ci_expr_old_146 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_146) = (((if (if __local_meta_arg__goto_6085_16 == 16: 1 else: 0) != 0: OP_PROP else: OP_NOTPROP) as u8)))
        (__ci_expr_old_147 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_147) = ((__local_ptype__goto_8290_16 as u8)))
        (__ci_expr_old_148 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_148) = ((__local_pdata__goto_8291_16 as u8)))
        goto '__ci_bb_565
    }

    '__ci_bb_565 {
        goto '__ci_bb_27
    }

    '__ci_bb_566 {
        (__ci_expr_old_144 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_144) = ((110 as u8)))
        with_memset(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), (0 as i32), ((32 as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (((32 as u64) / (sizeof[u8]() as u64)) as usize))
        goto '__ci_bb_568
    }

    '__ci_bb_567 {
        (__ci_expr_old_145 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_145) = ((13 as u8)))
        goto '__ci_bb_568
    }

    '__ci_bb_568 {
        goto '__ci_bb_565
    }

    '__ci_bb_569 {
        ((*__param_errorcodeptr) = ERR99)
        return 0
    }

    '__ci_bb_570 {
        goto '__ci_bb_571
    }

    '__ci_bb_571 {
        if (__local_meta_arg__goto_6085_16 == 14) {
            goto '__ci_bb_573
        } else {
            goto '__ci_bb_583
        }
    }

    '__ci_bb_572 {
        (__ci_expr_old_152 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_152) = ((__local_meta_arg__goto_6085_16 as u8)))
        goto '__ci_bb_27
    }

    '__ci_bb_573 {
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (4194304 as u32))
        if ((if not (__local_utf__goto_6110_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_574
        } else {
            goto '__ci_bb_575
        }
    }

    '__ci_bb_574 {
        (__local_meta_arg__goto_6085_16 = ((13 as u32)))
        goto '__ci_bb_575
    }

    '__ci_bb_575 {
        goto '__ci_bb_572
    }

    '__ci_bb_576 {
        (__ci_expr_logic_151 = 0)
        if ((if ((__local_options__goto_6080_10 as u32) & (131072 as u32)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_151 = (if (if ((__local_xoptions__goto_6081_10 as u32) & (1024 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_151 != 0) {
            goto '__ci_bb_577
        } else {
            goto '__ci_bb_578
        }
    }

    '__ci_bb_577 {
        (__local_meta_arg__goto_6085_16 = (((if (if __local_meta_arg__goto_6085_16 == 4: 1 else: 0) != 0: OP_NOT_UCP_WORD_BOUNDARY else: OP_UCP_WORD_BOUNDARY) as u32)))
        goto '__ci_bb_578
    }

    '__ci_bb_578 {
        goto '__ci_bb_579
    }

    '__ci_bb_579 {
        if ((if (*__param_cb).max_lookbehind == 0: 1 else: 0) != 0) {
            goto '__ci_bb_580
        } else {
            goto '__ci_bb_581
        }
    }

    '__ci_bb_580 {
        ((*__param_cb).max_lookbehind = ((1 as i32)))
        goto '__ci_bb_581
    }

    '__ci_bb_581 {
        goto '__ci_bb_572
    }

    '__ci_bb_582 {
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (16777216 as u32))
        goto '__ci_bb_572
    }

    '__ci_bb_583 {
        if (__local_meta_arg__goto_6085_16 == 4) {
            goto '__ci_bb_576
        } else {
            goto '__ci_bb_584
        }
    }

    '__ci_bb_584 {
        if (__local_meta_arg__goto_6085_16 == 5) {
            goto '__ci_bb_576
        } else {
            goto '__ci_bb_585
        }
    }

    '__ci_bb_585 {
        if (__local_meta_arg__goto_6085_16 == 1) {
            goto '__ci_bb_579
        } else {
            goto '__ci_bb_586
        }
    }

    '__ci_bb_586 {
        if (__local_meta_arg__goto_6085_16 == 3) {
            goto '__ci_bb_582
        } else {
            goto '__ci_bb_572
        }
    }

    '__ci_bb_587 {
        if ((if __local_meta__goto_6085_10 >= 2147483648: 1 else: 0) != 0) {
            goto '__ci_bb_588
        } else {
            goto '__ci_bb_589
        }
    }

    '__ci_bb_588 {
        goto '__ci_bb_590
    }

    '__ci_bb_589 {
        goto '__ci_bb_519
    }

    '__ci_bb_590 {
        goto '__ci_bb_591
    }

    '__ci_bb_591 {
        if (0 != 0) {
            goto '__ci_bb_590
        } else {
            goto '__ci_bb_592
        }
    }

    '__ci_bb_592 {
        ((*__param_errorcodeptr) = ERR89)
        return 0
    }

    '__ci_bb_593 {
        (__ci_expr_logic_156 = 0)
        if ((if ((__local_xoptions__goto_6081_10 as u32) & (((65536 as u32) | (128 as u32)) as u32)) == 65536: 1 else: 0) != 0) {
            var __ci_expr_logic_155: i32

            if ((if ((__local_meta__goto_6085_10 as u32) | (32 as u32)) == 105: 1 else: 0) != 0) {
                (__ci_expr_logic_155 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_155 = (if (if ((__local_meta__goto_6085_10 as u32) | (1 as u32)) == 305: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_156 = (if __ci_expr_logic_155 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_156 != 0) {
            goto '__ci_bb_595
        } else {
            goto '__ci_bb_596
        }
    }

    '__ci_bb_594 {
        goto '__ci_bb_78
    }

    '__ci_bb_595 {
        (__ci_expr_ternary_158 = 0)
        if ((if __local_meta__goto_6085_10 == 105: 1 else: 0) != 0) {
            (__ci_expr_logic_157 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_157 = (if (if __local_meta__goto_6085_10 == 304: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_157 != 0) {
            (__ci_expr_ternary_158 = ((0 as i32)))
        } else {
            (__ci_expr_ternary_158 = ((3 as i32)))
        }
        (__local_caseset__goto_8414_16 = ((((_pcre2_ucd_turkish_dotted_i_caseset_8 as u32) +% (__ci_expr_ternary_158 as u32)) as u32)))
        goto '__ci_bb_597
    }

    '__ci_bb_596 {
        (__ci_expr_logic_160 = 0)
        (__ci_expr_logic_159 = 0)
        (__local_caseset__goto_8414_16 = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_meta__goto_6085_10 as i32) / 128)] as i32) * 128) + ((__local_meta__goto_6085_10 as i32) % 128))] as u32) as usize)).caseset as u32)))
        if ((if __local_caseset__goto_8414_16 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_159 = (if (if ((__local_xoptions__goto_6081_10 as u32) & (128 as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_159 != 0) {
            (__ci_expr_logic_160 = (if (if _pcre2_ucd_caseless_sets_8[__local_caseset__goto_8414_16] < 128: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_160 != 0) {
            goto '__ci_bb_598
        } else {
            goto '__ci_bb_599
        }
    }

    '__ci_bb_597 {
        if ((if __local_caseset__goto_8414_16 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_600
        } else {
            goto '__ci_bb_601
        }
    }

    '__ci_bb_598 {
        (__local_caseset__goto_8414_16 = ((0 as u32)))
        goto '__ci_bb_599
    }

    '__ci_bb_599 {
        goto '__ci_bb_597
    }

    '__ci_bb_600 {
        (__ci_expr_old_161 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_161) = ((16 as u8)))
        (__ci_expr_old_162 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_162) = ((9 as u8)))
        (__ci_expr_old_163 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_163) = ((__local_caseset__goto_8414_16 as u8)))
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_603
        }
    }

    '__ci_bb_601 {
        goto '__ci_bb_594
    }

    '__ci_bb_602 {
        (__local_zerofirstcuflags__goto_6087_26 = ((4294967294 as u32)))
        (__local_firstcuflags__goto_6086_10 = __local_zerofirstcuflags__goto_6087_26)
        goto '__ci_bb_603
    }

    '__ci_bb_603 {
        goto '__ci_bb_27
    }

    '__ci_bb_604 {
        (__local_mclength__goto_6147_12 = ((_pcre2_ord2utf_8(__local_meta__goto_6085_10, (&__local_mcbuffer__goto_6154_15[0] as *mut u8)) as u32)))
        goto '__ci_bb_606
    }

    '__ci_bb_605 {
        (__local_mclength__goto_6147_12 = ((1 as u32)))
        (__local_mcbuffer__goto_6154_15[0] = ((__local_meta__goto_6085_10 as u8)))
        goto '__ci_bb_606
    }

    '__ci_bb_606 {
        (__ci_expr_old_164 = __local_code__goto_6093_14)
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + 1)
        ((*__ci_expr_old_164) = (((if (if ((__local_options__goto_6080_10 as u32) & (8 as u32)) != 0: 1 else: 0) != 0: OP_CHARI else: OP_CHAR) as u8)))
        with_memcpy(((__local_code__goto_6093_14 as *mut c_void) as *mut u8), ((&__local_mcbuffer__goto_6154_15[0] as *mut u8) as *const u8), ((((__local_mclength__goto_6147_12 as u32) *% (1 as u32)) as u64) as i64))
        (__local_code__goto_6093_14 = __local_code__goto_6093_14 + (__local_mclength__goto_6147_12 as usize))
        if ((if __local_mcbuffer__goto_6154_15[0] == 13: 1 else: 0) != 0) {
            (__ci_expr_logic_165 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_165 = (if (if __local_mcbuffer__goto_6154_15[0] == 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_165 != 0) {
            goto '__ci_bb_607
        } else {
            goto '__ci_bb_608
        }
    }

    '__ci_bb_607 {
        ((*__param_cb).external_flags = ((*__param_cb).external_flags as u32) | (2048 as u32))
        goto '__ci_bb_608
    }

    '__ci_bb_608 {
        if ((if __local_firstcuflags__goto_6086_10 == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_609
        } else {
            goto '__ci_bb_610
        }
    }

    '__ci_bb_609 {
        (__local_zerofirstcuflags__goto_6087_26 = ((4294967294 as u32)))
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        if ((if __local_mclength__goto_6147_12 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_166 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_166 = (if (if __local_req_caseopt__goto_6088_10 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_166 != 0) {
            goto '__ci_bb_612
        } else {
            goto '__ci_bb_613
        }
    }

    '__ci_bb_610 {
        (__local_zerofirstcu__goto_6083_21 = __local_firstcu__goto_6082_10)
        (__local_zerofirstcuflags__goto_6087_26 = __local_firstcuflags__goto_6086_10)
        (__local_zeroreqcu__goto_6083_10 = __local_reqcu__goto_6082_19)
        (__local_zeroreqcuflags__goto_6087_10 = __local_reqcuflags__goto_6086_24)
        if ((if __local_mclength__goto_6147_12 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_167 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_167 = (if (if __local_req_caseopt__goto_6088_10 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_167 != 0) {
            goto '__ci_bb_617
        } else {
            goto '__ci_bb_618
        }
    }

    '__ci_bb_611 {
        if (__local_reset_caseful__goto_6103_6 != 0) {
            goto '__ci_bb_619
        } else {
            goto '__ci_bb_620
        }
    }

    '__ci_bb_612 {
        (__local_firstcu__goto_6082_10 = ((__local_mcbuffer__goto_6154_15[0] as u32)))
        (__local_firstcuflags__goto_6086_10 = __local_req_caseopt__goto_6088_10)
        if ((if __local_mclength__goto_6147_12 != 1: 1 else: 0) != 0) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_616
        }
    }

    '__ci_bb_613 {
        (__local_reqcuflags__goto_6086_24 = ((4294967294 as u32)))
        (__local_firstcuflags__goto_6086_10 = __local_reqcuflags__goto_6086_24)
        goto '__ci_bb_614
    }

    '__ci_bb_614 {
        goto '__ci_bb_611
    }

    '__ci_bb_615 {
        (__local_reqcu__goto_6082_19 = (((__local_code__goto_6093_14[-1]) as u32)))
        (__local_reqcuflags__goto_6086_24 = (*__param_cb).req_varyopt)
        goto '__ci_bb_616
    }

    '__ci_bb_616 {
        goto '__ci_bb_614
    }

    '__ci_bb_617 {
        (__local_reqcu__goto_6082_19 = (((__local_code__goto_6093_14[-1]) as u32)))
        (__local_reqcuflags__goto_6086_24 = ((((__local_req_caseopt__goto_6088_10 as u32) | ((*__param_cb).req_varyopt as u32)) as u32)))
        goto '__ci_bb_618
    }

    '__ci_bb_618 {
        goto '__ci_bb_611
    }

    '__ci_bb_619 {
        (__local_options__goto_6080_10 = (__local_options__goto_6080_10 as u32) & ((~8) as u32))
        (__local_req_caseopt__goto_6088_10 = ((0 as u32)))
        (__local_reset_caseful__goto_6103_6 = ((0 as i32)))
        goto '__ci_bb_620
    }

    '__ci_bb_620 {
        goto '__ci_bb_27
    }

    '__ci_bb_621 {
        if (__local_meta__goto_6085_10 == 2147549184) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_622
        }
    }

    '__ci_bb_622 {
        if (__local_meta__goto_6085_10 == 2149384192) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_623
        }
    }

    '__ci_bb_623 {
        if (__local_meta__goto_6085_10 == 2148073472) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_624
        }
    }

    '__ci_bb_624 {
        if (__local_meta__goto_6085_10 == 2149187584) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_625
        }
    }

    '__ci_bb_625 {
        if (__local_meta__goto_6085_10 == 2149253120) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_626
        }
    }

    '__ci_bb_626 {
        if (__local_meta__goto_6085_10 == 2148204544) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_627
        }
    }

    '__ci_bb_627 {
        if (__local_meta__goto_6085_10 == 2148270080) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_628
        }
    }

    '__ci_bb_628 {
        if (__local_meta__goto_6085_10 == 2148401152) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_629
        }
    }

    '__ci_bb_629 {
        if (__local_meta__goto_6085_10 == 2148139008) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_630
        }
    }

    '__ci_bb_630 {
        if (__local_meta__goto_6085_10 == 2150498304) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_631
        }
    }

    '__ci_bb_631 {
        if (__local_meta__goto_6085_10 == 2150760448) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_632
        }
    }

    '__ci_bb_632 {
        if (__local_meta__goto_6085_10 == 2150891520) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_633
        }
    }

    '__ci_bb_633 {
        if (__local_meta__goto_6085_10 == 2150629376) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_634
        }
    }

    '__ci_bb_634 {
        if (__local_meta__goto_6085_10 == 2150563840) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_635
        }
    }

    '__ci_bb_635 {
        if (__local_meta__goto_6085_10 == 2151022592) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_636
        }
    }

    '__ci_bb_636 {
        if (__local_meta__goto_6085_10 == 2151088128) {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_637
        }
    }

    '__ci_bb_637 {
        if (__local_meta__goto_6085_10 == 2150825984) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_638
        }
    }

    '__ci_bb_638 {
        if (__local_meta__goto_6085_10 == 2150957056) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_639
        }
    }

    '__ci_bb_639 {
        if (__local_meta__goto_6085_10 == 2150432768) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_640
        }
    }

    '__ci_bb_640 {
        if (__local_meta__goto_6085_10 == 2150694912) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_641
        }
    }

    '__ci_bb_641 {
        if (__local_meta__goto_6085_10 == 2149515264) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_642
        }
    }

    '__ci_bb_642 {
        if (__local_meta__goto_6085_10 == 2148925440) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_643
        }
    }

    '__ci_bb_643 {
        if (__local_meta__goto_6085_10 == 2148990976) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_644
        }
    }

    '__ci_bb_644 {
        if (__local_meta__goto_6085_10 == 2148794368) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_645
        }
    }

    '__ci_bb_645 {
        if (__local_meta__goto_6085_10 == 2148597760) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_646
        }
    }

    '__ci_bb_646 {
        if (__local_meta__goto_6085_10 == 2148728832) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_647
        }
    }

    '__ci_bb_647 {
        if (__local_meta__goto_6085_10 == 2148532224) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_648
        }
    }

    '__ci_bb_648 {
        if (__local_meta__goto_6085_10 == 2148663296) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_649
        }
    }

    '__ci_bb_649 {
        if (__local_meta__goto_6085_10 == 2148859904) {
            goto '__ci_bb_179
        } else {
            goto '__ci_bb_650
        }
    }

    '__ci_bb_650 {
        if (__local_meta__goto_6085_10 == 2148466688) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_651
        }
    }

    '__ci_bb_651 {
        if (__local_meta__goto_6085_10 == 2150039552) {
            goto '__ci_bb_184
        } else {
            goto '__ci_bb_652
        }
    }

    '__ci_bb_652 {
        if (__local_meta__goto_6085_10 == 2150301696) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_653
        }
    }

    '__ci_bb_653 {
        if (__local_meta__goto_6085_10 == 2150105088) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_654
        }
    }

    '__ci_bb_654 {
        if (__local_meta__goto_6085_10 == 2150170624) {
            goto '__ci_bb_190
        } else {
            goto '__ci_bb_655
        }
    }

    '__ci_bb_655 {
        if (__local_meta__goto_6085_10 == 2150236160) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_656
        }
    }

    '__ci_bb_656 {
        if (__local_meta__goto_6085_10 == 2150367232) {
            goto '__ci_bb_192
        } else {
            goto '__ci_bb_657
        }
    }

    '__ci_bb_657 {
        if (__local_meta__goto_6085_10 == 2147614720) {
            goto '__ci_bb_193
        } else {
            goto '__ci_bb_658
        }
    }

    '__ci_bb_658 {
        if (__local_meta__goto_6085_10 == 2149974016) {
            goto '__ci_bb_194
        } else {
            goto '__ci_bb_659
        }
    }

    '__ci_bb_659 {
        if (__local_meta__goto_6085_10 == 2149449728) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_660
        }
    }

    '__ci_bb_660 {
        if (__local_meta__goto_6085_10 == 2147745792) {
            goto '__ci_bb_240
        } else {
            goto '__ci_bb_661
        }
    }

    '__ci_bb_661 {
        if (__local_meta__goto_6085_10 == 2149908480) {
            goto '__ci_bb_240
        } else {
            goto '__ci_bb_662
        }
    }

    '__ci_bb_662 {
        if (__local_meta__goto_6085_10 == 2147876864) {
            goto '__ci_bb_257
        } else {
            goto '__ci_bb_663
        }
    }

    '__ci_bb_663 {
        if (__local_meta__goto_6085_10 == 2147942400) {
            goto '__ci_bb_258
        } else {
            goto '__ci_bb_664
        }
    }

    '__ci_bb_664 {
        if (__local_meta__goto_6085_10 == 2151809024) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_665
        }
    }

    '__ci_bb_665 {
        if (__local_meta__goto_6085_10 == 2151874560) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_666
        }
    }

    '__ci_bb_666 {
        if (__local_meta__goto_6085_10 == 2151743488) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_667
        }
    }

    '__ci_bb_667 {
        if (__local_meta__goto_6085_10 == 2151153664) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_668
        }
    }

    '__ci_bb_668 {
        if (__local_meta__goto_6085_10 == 2151219200) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_669
        }
    }

    '__ci_bb_669 {
        if (__local_meta__goto_6085_10 == 2151284736) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_670
        }
    }

    '__ci_bb_670 {
        if (__local_meta__goto_6085_10 == 2151350272) {
            goto '__ci_bb_273
        } else {
            goto '__ci_bb_671
        }
    }

    '__ci_bb_671 {
        if (__local_meta__goto_6085_10 == 2151415808) {
            goto '__ci_bb_273
        } else {
            goto '__ci_bb_672
        }
    }

    '__ci_bb_672 {
        if (__local_meta__goto_6085_10 == 2151481344) {
            goto '__ci_bb_273
        } else {
            goto '__ci_bb_673
        }
    }

    '__ci_bb_673 {
        if (__local_meta__goto_6085_10 == 2151546880) {
            goto '__ci_bb_274
        } else {
            goto '__ci_bb_674
        }
    }

    '__ci_bb_674 {
        if (__local_meta__goto_6085_10 == 2151612416) {
            goto '__ci_bb_274
        } else {
            goto '__ci_bb_675
        }
    }

    '__ci_bb_675 {
        if (__local_meta__goto_6085_10 == 2151677952) {
            goto '__ci_bb_274
        } else {
            goto '__ci_bb_676
        }
    }

    '__ci_bb_676 {
        if (__local_meta__goto_6085_10 == 2147811328) {
            goto '__ci_bb_518
        } else {
            goto '__ci_bb_677
        }
    }

    '__ci_bb_677 {
        if (__local_meta__goto_6085_10 == 2147680256) {
            goto '__ci_bb_520
        } else {
            goto '__ci_bb_678
        }
    }

    '__ci_bb_678 {
        if (__local_meta__goto_6085_10 == 2149842944) {
            goto '__ci_bb_532
        } else {
            goto '__ci_bb_679
        }
    }

    '__ci_bb_679 {
        if (__local_meta__goto_6085_10 == 2148007936) {
            goto '__ci_bb_553
        } else {
            goto '__ci_bb_680
        }
    }

    '__ci_bb_680 {
        if (__local_meta__goto_6085_10 == 2149318656) {
            goto '__ci_bb_554
        } else {
            goto '__ci_bb_587
        }
    }

    __ci_unreachable()

}

unsafe fn is_anchored(__param_code: *const u8, __param_bracket_map: u32, __param_cb: *mut compile_block_8, __param_atomcount: i32, __param_inassert: i32, __param_dotstar_anchor: i32) -> i32 {
    var __local_code = __param_code
    loop {
        var __local_scode: *const u8 = first_significant_code((__local_code + ((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize)), (0 as i32))

        var __local_op: i32 = (((*__local_scode) as i32))

        var __ci_expr_logic_2: i32

        var __ci_expr_logic_1: i32

        var __ci_expr_logic_0: i32

        if ((if __local_op == OP_BRA: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_op == OP_SBRA: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            if ((if not (is_anchored(__local_scode, __param_bracket_map, __param_cb, __param_atomcount, __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            var __ci_expr_logic_5: i32

            var __ci_expr_logic_4: i32

            var __ci_expr_logic_3: i32

            if ((if __local_op == OP_CBRA: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if __local_op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if __local_op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if __local_op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                var __local_n: i32 = ((((((((__local_scode[(1 + 2)]) as i32) << (8 as u32)) as i32) | ((__local_scode[((1 + 2) + 1)]) as i32)) as u32) as i32))

                var __local_new_map: u32 = ((((__param_bracket_map as u32) | ((if (if __local_n < 32: 1 else: 0) != 0: (((1 as u32) << (__local_n as u32)) as u32) else: (1 as u32)) as u32)) as u32))

                if ((if not (is_anchored(__local_scode, __local_new_map, __param_cb, __param_atomcount, __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                    return 0
                }

            } else {
                var __ci_expr_logic_6: i32

                if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_6 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_6 != 0) {
                    if ((if not (is_anchored(__local_scode, __param_bracket_map, __param_cb, __param_atomcount, (1 as i32), __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                        return 0
                    }

                } else {
                    var __ci_expr_logic_7: i32

                    if ((if __local_op == OP_COND: 1 else: 0) != 0) {
                        (__ci_expr_logic_7 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_7 = (if (if __local_op == OP_SCOND: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_7 != 0) {
                        if ((if (__local_scode[((((((__local_scode[1]) as i32) << (8 as u32)) as i32) | ((__local_scode[(1 + 1)]) as i32)) as u32)]) != OP_ALT: 1 else: 0) != 0) {
                            return 0
                        }

                        if ((if not (is_anchored(__local_scode, __param_bracket_map, __param_cb, __param_atomcount, __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                    } else {
                        if ((if __local_op == OP_ONCE: 1 else: 0) != 0) {
                            if ((if not (is_anchored(__local_scode, __param_bracket_map, __param_cb, ((__param_atomcount + 1) as i32), __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                                return 0
                            }

                        } else {
                            var __ci_expr_logic_9: i32

                            var __ci_expr_logic_8: i32

                            if ((if __local_op == OP_TYPESTAR: 1 else: 0) != 0) {
                                (__ci_expr_logic_8 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_8 = (if (if __local_op == OP_TYPEMINSTAR: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (__ci_expr_logic_9 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_9 = (if (if __local_op == OP_TYPEPOSSTAR: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_9 != 0) {
                                var __ci_expr_logic_14: i32

                                var __ci_expr_logic_13: i32

                                var __ci_expr_logic_12: i32

                                var __ci_expr_logic_11: i32

                                var __ci_expr_logic_10: i32

                                if ((if (__local_scode[1]) != OP_ALLANY: 1 else: 0) != 0) {
                                    (__ci_expr_logic_10 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_10 = (if (if ((__param_bracket_map as u32) & ((*__param_cb).backref_map as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_10 != 0) {
                                    (__ci_expr_logic_11 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_11 = (if (if __param_atomcount > 0: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_11 != 0) {
                                    (__ci_expr_logic_12 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_12 = (if (*__param_cb).had_pruneorskip != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_12 != 0) {
                                    (__ci_expr_logic_13 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_13 = (if __param_inassert != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_13 != 0) {
                                    (__ci_expr_logic_14 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_14 = (if (if not (__param_dotstar_anchor != 0): 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_14 != 0) {
                                    return 0
                                }


                            } else {
                                var __ci_expr_logic_16: i32 = 0

                                var __ci_expr_logic_15: i32 = 0

                                if ((if __local_op != OP_SOD: 1 else: 0) != 0) {
                                    (__ci_expr_logic_15 = (if (if __local_op != OP_SOM: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_15 != 0) {
                                    (__ci_expr_logic_16 = (if (if __local_op != OP_CIRC: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_16 != 0) {
                                    return 0
                                }

                            }

                        }
                    }

                }

            }

        }


        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
            break
        }
    }

    return 1

}

unsafe fn is_startline(__param_code: *const u8, __param_bracket_map: u32, __param_cb: *mut compile_block_8, __param_atomcount: i32, __param_inassert: i32, __param_dotstar_anchor: i32) -> i32 {
    var __local_code = __param_code
    loop {
        var __local_scode: *const u8 = first_significant_code((__local_code + ((_pcre2_OP_lengths_8[(*__local_code)] as u32) as usize)), (0 as i32))

        var __local_op: i32 = (((*__local_scode) as i32))

        if ((if __local_op == OP_COND: 1 else: 0) != 0) {
            (__local_scode = __local_scode + (((1 + 2) as isize) as usize))

            if ((if (*__local_scode) == OP_CALLOUT: 1 else: 0) != 0) {
                (__local_scode = __local_scode + (((_pcre2_OP_lengths_8[OP_CALLOUT] as u32) as usize) as i32))
            } else {
                if ((if (*__local_scode) == OP_CALLOUT_STR: 1 else: 0) != 0) {
                    (__local_scode = __local_scode + (((((((__local_scode[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_scode[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))
                }
            }

            while true {
                match (*__local_scode) {
                    147 => {
                        return 0
                    },
                    148 => {
                        return 0
                    },
                    149 => {
                        return 0
                    },
                    150 => {
                        return 0
                    },
                    165 => {
                        return 0
                    },
                    151 => {
                        return 0
                    },
                    152 => {
                        return 0
                    },
                    _ => {
                        if ((if not (is_startline(__local_scode, __param_bracket_map, __param_cb, __param_atomcount, (1 as i32), __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        loop {
                            (__local_scode = __local_scode + (((((((__local_scode[1]) as i32) << (8 as u32)) as i32) | ((__local_scode[(1 + 1)]) as i32)) as u32) as usize))
                            if not (((if (*__local_scode) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }
                        }

                        (__local_scode = __local_scode + (((1 + 2) as isize) as usize))

                    },
                }

                break

            }

            (__local_scode = first_significant_code(__local_scode, (0 as i32)))

            (__local_op = (((*__local_scode) as i32)))

        }

        var __ci_expr_logic_3: i32

        var __ci_expr_logic_2: i32

        var __ci_expr_logic_1: i32

        if ((if __local_op == OP_BRA: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_op == OP_SBRA: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            if ((if not (is_startline(__local_scode, __param_bracket_map, __param_cb, __param_atomcount, __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            var __ci_expr_logic_6: i32

            var __ci_expr_logic_5: i32

            var __ci_expr_logic_4: i32

            if ((if __local_op == OP_CBRA: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if __local_op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if __local_op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if __local_op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                var __local_n: i32 = ((((((((__local_scode[(1 + 2)]) as i32) << (8 as u32)) as i32) | ((__local_scode[((1 + 2) + 1)]) as i32)) as u32) as i32))

                var __local_new_map: u32 = ((((__param_bracket_map as u32) | ((if (if __local_n < 32: 1 else: 0) != 0: (((1 as u32) << (__local_n as u32)) as u32) else: (1 as u32)) as u32)) as u32))

                if ((if not (is_startline(__local_scode, __local_new_map, __param_cb, __param_atomcount, __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                    return 0
                }

            } else {
                var __ci_expr_logic_7: i32

                if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_7 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_7 != 0) {
                    if ((if not (is_startline(__local_scode, __param_bracket_map, __param_cb, __param_atomcount, (1 as i32), __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                        return 0
                    }

                } else {
                    if ((if __local_op == OP_ONCE: 1 else: 0) != 0) {
                        if ((if not (is_startline(__local_scode, __param_bracket_map, __param_cb, ((__param_atomcount + 1) as i32), __param_inassert, __param_dotstar_anchor) != 0): 1 else: 0) != 0) {
                            return 0
                        }

                    } else {
                        var __ci_expr_logic_9: i32

                        var __ci_expr_logic_8: i32

                        if ((if __local_op == OP_TYPESTAR: 1 else: 0) != 0) {
                            (__ci_expr_logic_8 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_8 = (if (if __local_op == OP_TYPEMINSTAR: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (__ci_expr_logic_9 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_9 = (if (if __local_op == OP_TYPEPOSSTAR: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            var __ci_expr_logic_14: i32

                            var __ci_expr_logic_13: i32

                            var __ci_expr_logic_12: i32

                            var __ci_expr_logic_11: i32

                            var __ci_expr_logic_10: i32

                            if ((if (__local_scode[1]) != OP_ANY: 1 else: 0) != 0) {
                                (__ci_expr_logic_10 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_10 = (if (if ((__param_bracket_map as u32) & ((*__param_cb).backref_map as u32)) != 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_10 != 0) {
                                (__ci_expr_logic_11 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_11 = (if (if __param_atomcount > 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_11 != 0) {
                                (__ci_expr_logic_12 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_12 = (if (*__param_cb).had_pruneorskip != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_12 != 0) {
                                (__ci_expr_logic_13 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_13 = (if __param_inassert != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_13 != 0) {
                                (__ci_expr_logic_14 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_14 = (if (if not (__param_dotstar_anchor != 0): 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_14 != 0) {
                                return 0
                            }


                        } else {
                            var __ci_expr_logic_15: i32 = 0

                            if ((if __local_op != OP_CIRC: 1 else: 0) != 0) {
                                (__ci_expr_logic_15 = (if (if __local_op != OP_CIRCM: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_15 != 0) {
                                return 0
                            }

                        }

                    }
                }

            }

        }


        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
            break
        }
    }

    return 1

}

unsafe fn find_recurse(__param_code: *mut u8, __param_utf: i32) -> *mut u8 {
    var __local_code = __param_code
    while true {
        var __local_c: u8 = (*__local_code)

        if ((if __local_c == OP_END: 1 else: 0) != 0) {
            return ((null as *mut u8))
        }

        if ((if __local_c == OP_RECURSE: 1 else: 0) != 0) {
            return __local_code
        }

        var __ci_expr_logic_0: i32

        if ((if __local_c == OP_XCLASS: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))
        } else {
            if ((if __local_c == OP_CALLOUT_STR: 1 else: 0) != 0) {
                (__local_code = __local_code + (((((((__local_code[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_code[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))
            } else {
                while true {
                    match __local_c {
                        85 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        86 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        87 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        88 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        89 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        90 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        94 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        95 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        96 => {
                            var __ci_expr_logic_1: i32

                            if ((if (__local_code[1]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_1 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_1 = (if (if (__local_code[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_1 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        97 => {
                            var __ci_expr_logic_2: i32

                            if ((if (__local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_2 = (if (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_2 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        91 => {
                            var __ci_expr_logic_2: i32

                            if ((if (__local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_2 = (if (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_2 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        92 => {
                            var __ci_expr_logic_2: i32

                            if ((if (__local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_2 = (if (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_2 != 0) {
                                (__local_code = __local_code + ((2 as isize) as usize))
                            }

                        },
                        93 => {
                            var __ci_expr_logic_2: i32

                            if ((if (__local_code[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_2 = (if (if (__local_code[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_2 != 0) {
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

                if (__param_utf != 0) {
                    while true {
                        match __local_c {
                            29 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            30 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            31 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            32 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            41 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            54 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            67 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            80 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            39 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            52 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            65 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            78 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            40 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            53 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            66 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            79 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            45 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            58 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            71 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            84 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            33 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            46 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            59 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            72 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            34 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            47 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            60 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            73 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            42 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            55 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            68 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            81 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            35 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            48 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            61 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            74 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            36 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            49 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            62 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            75 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            43 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            56 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            69 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            82 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            37 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            50 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            63 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            76 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            38 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            51 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            64 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            77 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            44 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            57 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            70 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
                                    (__local_code = __local_code + (((_pcre2_utf8_table4[((((__local_code[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                                }
                            },
                            83 => {
                                if ((if (__local_code[-1]) >= 192: 1 else: 0) != 0) {
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

unsafe fn find_firstassertedcu(__param_code: *const u8, __param_flags: *mut u32, __param_inassert: u32) -> u32 {
    var __local_code = __param_code
    var __local_c: u32 = ((0 as u32))

    var __local_cflags: u32 = ((4294967294 as u32))

    ((*__param_flags) = ((4294967294 as u32)))

    loop {
        var __local_d: u32

        var __local_dflags: u32

        var __local_xl: i32 = with 0 as __ci_expr_seq_119 {
            var __ci_expr_ternary_3: i32 = 0
            var __ci_expr_logic_2: i32
            var __ci_expr_logic_1: i32
            var __ci_expr_logic_0: i32
            if ((if (*__local_code) == OP_CBRA: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if (*__local_code) == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
            }
            if (__ci_expr_logic_0 != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (*__local_code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
            }
            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if (*__local_code) == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
            }
            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_ternary_3 = ((2 as i32)))
            } else {
                (__ci_expr_ternary_3 = ((0 as i32)))
            }
            __ci_expr_ternary_3
        }

        var __local_scode: *const u8 = first_significant_code((((__local_code + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((__local_xl as isize) as usize)), (1 as i32))

        var __local_op: u8 = (*__local_scode)

        while true {
            match __local_op {
                137 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                138 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                139 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                144 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                140 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                145 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                128 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                132 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                135 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                136 => {
                    var __ci_expr_ternary_5: i32 = 0

                    var __ci_expr_logic_4: i32

                    if ((if __local_op == OP_ASSERT: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_4 = (if (if __local_op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__ci_expr_ternary_5 = ((1 as i32)))
                    } else {
                        (__ci_expr_ternary_5 = ((0 as i32)))
                    }

                    (__local_d = ((find_firstassertedcu(__local_scode, (&raw mut __local_dflags as *mut u32), (((__param_inassert as u32) +% (__ci_expr_ternary_5 as u32)) as u32)) as u32)))


                    if ((if __local_dflags >= 4294967294: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = __local_d)

                        (__local_cflags = __local_dflags)

                    } else {
                        var __ci_expr_logic_6: i32

                        if ((if __local_c != __local_d: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if __local_cflags != __local_dflags: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return ((0 as u32))
                        }

                    }

                },
                41 => {
                    (__local_scode = __local_scode + ((2 as isize) as usize))

                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((0 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }


                },
                29 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((0 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                35 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((0 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                36 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((0 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                43 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((0 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                54 => {
                    (__local_scode = __local_scode + ((2 as isize) as usize))

                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if (__local_scode[1]) >= 128: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((1 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }


                },
                30 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if (__local_scode[1]) >= 128: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((1 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                48 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if (__local_scode[1]) >= 128: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((1 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                49 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if (__local_scode[1]) >= 128: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((1 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                56 => {
                    if ((if __param_inassert == 0: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if (__local_scode[1]) >= 128: 1 else: 0) != 0) {
                        return ((0 as u32))
                    }

                    if ((if __local_cflags >= 4294967294: 1 else: 0) != 0) {
                        (__local_c = (((__local_scode[1]) as u32)))

                        (__local_cflags = ((1 as u32)))

                    } else {
                        if ((if __local_c != (__local_scode[1]): 1 else: 0) != 0) {
                            return ((0 as u32))
                        }
                    }

                },
                _ => {
                    return ((0 as u32))
                },
            }

            break

        }

        (__local_code = __local_code + (((((((__local_code[1]) as i32) << (8 as u32)) as i32) | ((__local_code[(1 + 1)]) as i32)) as u32) as usize))

        if not (((if (*__local_code) == OP_ALT: 1 else: 0) != 0)) {
            break
        }
    }

    ((*__param_flags) = __local_cflags)

    return __local_c

}

unsafe fn parsed_skip(__param_pptr: *mut u32, __param_skiptype: u32) -> *mut u32 {
    var __local_pptr = __param_pptr
    var __local_nestlevel: u32 = ((0 as u32))

    while true {
        var __local_meta: u32 = (((((*__local_pptr) as u32) & (4294901760 as u32)) as u32))

        var __ci_expr_switch_continue_2: i32 = 0

        while true {
            match __local_meta {
                2147483648 => {
                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    return ((null as *mut u32))

                },
                2147680256 => {
                    if ((if (((*__local_pptr) as u32) & (65535 as u32)) >= 10: 1 else: 0) != 0) {
                        (__local_pptr = __local_pptr + ((2 as isize) as usize))
                    }
                },
                2149318656 => {
                    var __ci_expr_logic_0: i32

                    if ((if (((*__local_pptr) as u32) -% (2149318656 as u32)) == 15: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_0 = (if (if (((*__local_pptr) as u32) -% (2149318656 as u32)) == 16: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_pptr = __local_pptr + ((1 as isize) as usize))
                    }

                },
                2150432768 => {
                    (__local_pptr = __local_pptr + ((__local_pptr[1]) as usize))
                },
                2150694912 => {
                    (__local_pptr = __local_pptr + ((__local_pptr[1]) as usize))
                },
                2150825984 => {
                    (__local_pptr = __local_pptr + ((__local_pptr[1]) as usize))
                },
                2150957056 => {
                    (__local_pptr = __local_pptr + ((__local_pptr[1]) as usize))
                },
                2151088128 => {
                    (__local_pptr = __local_pptr + ((__local_pptr[1]) as usize))
                },
                2148335616 => {
                    if ((if __param_skiptype == 1: 1 else: 0) != 0) {
                        return __local_pptr
                    }
                },
                2147614720 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148007936 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148466688 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148532224 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148597760 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148663296 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148728832 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148794368 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148859904 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2148990976 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2150039552 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2150105088 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2150301696 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2150170624 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2150236160 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2150367232 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2149449728 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2149974016 => {
                    (__local_nestlevel = (__local_nestlevel +% 1))
                },
                2147549184 => {
                    var __ci_expr_logic_1: i32 = 0

                    if ((if __local_nestlevel == 0: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if (if __param_skiptype == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        return __local_pptr
                    }

                },
                2149384192 => {
                    if ((if __local_nestlevel == 0: 1 else: 0) != 0) {
                        return __local_pptr
                    }

                    (__local_nestlevel = (__local_nestlevel -% 1))

                },
                _ => {
                    if ((if __local_meta < 2147483648: 1 else: 0) != 0) {
                        (__ci_expr_switch_continue_2 = 1)

                        break

                    }
                },
            }

            break

        }

        if (__ci_expr_switch_continue_2 != 0) {
            (__local_pptr = __local_pptr + 1)

            continue

        }


        (__local_meta = ((((((__local_meta as u32) >> (16 as u32)) as u32) & (32767 as u32)) as u32)))

        if ((if __local_meta >= (73 * (sizeof[u8]() as usize)): 1 else: 0) != 0) {
            return ((null as *mut u32))
        }

        (__local_pptr = __local_pptr + (((meta_extra_lengths[__local_meta] as u32) as usize) as i32))


        (__local_pptr = __local_pptr + 1)

    }

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn get_grouplength(__param_pptrptr: *mut *mut u32, __param_minptr: *mut i32, __param_isinline: i32, __param_errcodeptr: *mut i32, __param_lcptr: *mut i32, __param_group: i32, __param_recurses: *mut parsed_recurse_check, __param_cb: *mut compile_block_8) -> i32 {
    var __local_gi__goto_9506_11: *mut u32 = null

    var __local_branchlength__goto_9507_5: i32 = 0

    var __local_branchminlength__goto_9507_19: i32 = 0

    var __local_grouplength__goto_9508_5: i32 = 0

    var __local_groupminlength__goto_9509_5: i32 = 0

    var __local_groupinfo__goto_9518_12: u32 = 0

    var __ci_expr_logic_0: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_gi__goto_9506_11 = (*__param_cb).groupinfo + (((2 * __param_group) as isize) as usize))
        (__local_grouplength__goto_9508_5 = ((-1 as i32)))
        (__local_groupminlength__goto_9509_5 = ((libc.INT_MAX as i32)))
        (__ci_expr_logic_0 = 0)
        if ((if __param_group > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (((*__param_cb).external_flags as u32) & (2097152 as u32)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        (__local_groupinfo__goto_9518_12 = (((__local_gi__goto_9506_11[0]) as u32)))
        if ((if ((__local_groupinfo__goto_9518_12 as u32) & (1073741824 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        goto '__ci_bb_9
    }

    '__ci_bb_3 {
        return -1
    }

    '__ci_bb_4 {
        if ((if ((__local_groupinfo__goto_9518_12 as u32) & (2147483648 as u32)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_5 {
        if (__param_isinline != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        goto '__ci_bb_2
    }

    '__ci_bb_7 {
        ((*__param_pptrptr) = parsed_skip((*__param_pptrptr), (2 as u32)))
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        ((*__param_minptr) = (((__local_gi__goto_9506_11[1]) as i32)))
        return ((((__local_groupinfo__goto_9518_12 as u32) & (65535 as u32)) as i32))
    }

    '__ci_bb_9 {
        goto '__ci_bb_10
    }

    '__ci_bb_10 {
        (__local_branchlength__goto_9507_5 = ((get_branchlength(__param_pptrptr, (&raw mut __local_branchminlength__goto_9507_19 as *mut i32), __param_errcodeptr, __param_lcptr, __param_recurses, __param_cb) as i32)))
        if ((if __local_branchlength__goto_9507_5 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_11 {
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        if ((if __param_group > 0: 1 else: 0) != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_13 {
        goto '__ci_bb_15
    }

    '__ci_bb_14 {
        if ((if __local_branchlength__goto_9507_5 > __local_grouplength__goto_9508_5: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_15 {
        if ((if __param_group > 0: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_16 {
        (__local_grouplength__goto_9508_5 = __local_branchlength__goto_9507_5)
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((if __local_branchminlength__goto_9507_19 < __local_groupminlength__goto_9509_5: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        (__local_groupminlength__goto_9509_5 = __local_branchminlength__goto_9507_19)
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        if ((if (*(*__param_pptrptr)) == 2149384192: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        goto '__ci_bb_12
    }

    '__ci_bb_21 {
        ((*__param_pptrptr) = (*__param_pptrptr) + ((1 as isize) as usize))
        goto '__ci_bb_11
    }

    '__ci_bb_22 {
        ((__local_gi__goto_9506_11[0]) = ((__local_gi__goto_9506_11[0]) as u32) | (((2147483648 as u32) | (__local_grouplength__goto_9508_5 as u32)) as u32))
        ((__local_gi__goto_9506_11[1]) = ((__local_groupminlength__goto_9509_5 as u32)))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        ((*__param_minptr) = __local_groupminlength__goto_9509_5)
        return __local_grouplength__goto_9508_5
    }

    '__ci_bb_24 {
        ((__local_gi__goto_9506_11[0]) = ((__local_gi__goto_9506_11[0]) as u32) | (1073741824 as u32))
        goto '__ci_bb_25
    }

    '__ci_bb_25 {
        return -1
    }

    __ci_unreachable()

}

let meta_extra_lengths: List[u8] = [0, 0, 0, 0, (1 + 2), 1, 3, (3 + 2), 0, 0, 0, 0, 0, 0, 0, 0, 2, (1 + 2), (1 + 2), (1 + 2), (1 + 2), 3, 2, 0, 1, 1, 0, 0, 0, 0, 0, 2, 1, 1, 0, 0, 2, (1 + 2), 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0]
let xdigitab: List[u8] = [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 255, 255, 255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]
let escapes: List[i16] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, (48 + 0x0a), (48 + 0x0b), (48 + 0x0c), (48 + 0x0d), (48 + 0x0e), (48 + 0x0f), (48 + 0x10), ((0 - ESC_A) as i16), ((0 - ESC_B) as i16), ((0 - ESC_C) as i16), ((0 - ESC_D) as i16), ((0 - ESC_E) as i16), 0, ((0 - ESC_G) as i16), ((0 - ESC_H) as i16), 0, 0, ((0 - ESC_K) as i16), 0, 0, ((0 - ESC_N) as i16), 0, ((0 - ESC_P) as i16), ((0 - ESC_Q) as i16), ((0 - ESC_R) as i16), ((0 - ESC_S) as i16), 0, 0, ((0 - ESC_V) as i16), ((0 - ESC_W) as i16), ((0 - ESC_X) as i16), 0, ((0 - ESC_Z) as i16), (48 + 0x2b), (48 + 0x2c), (48 + 0x2d), (48 + 0x2e), (48 + 0x2f), (48 + 0x30), 7, ((0 - ESC_b) as i16), 0, ((0 - ESC_d) as i16), 27, 12, 0, ((0 - ESC_h) as i16), 0, 0, ((0 - ESC_k) as i16), 0, 0, 10, 0, ((0 - ESC_p) as i16), 0, 13, ((0 - ESC_s) as i16), 9, 0, ((0 - ESC_v) as i16), ((0 - ESC_w) as i16), 0, 0, ((0 - ESC_z) as i16)]
let verbnames: List[c_char] = [0, 77, 65, 82, 75, 0, 65, 67, 67, 69, 80, 84, 0, 70, 0, 70, 65, 73, 76, 0, 67, 79, 77, 77, 73, 84, 0, 80, 82, 85, 78, 69, 0, 83, 75, 73, 80, 0, 84, 72, 69, 78, 0]
let verbs: List[verbitem] = [verbitem { len: 0, meta: 2150432768, has_arg: 1 }, verbitem { len: 4, meta: 2150432768, has_arg: 1 }, verbitem { len: 6, meta: 2150498304, has_arg: -1 }, verbitem { len: 1, meta: 2150563840, has_arg: -1 }, verbitem { len: 4, meta: 2150563840, has_arg: -1 }, verbitem { len: 6, meta: 2150629376, has_arg: 0 }, verbitem { len: 5, meta: 2150760448, has_arg: 0 }, verbitem { len: 4, meta: 2150891520, has_arg: 0 }, verbitem { len: 4, meta: 2151022592, has_arg: 0 }]
let verbcount: i32 = 9
let verbops: List[u32] = [156, 166, 165, 163, 164, 157, 158, 159, 160, 161, 162]
let alasnames: List[c_char] = [112, 108, 97, 0, 112, 108, 98, 0, 110, 97, 112, 108, 97, 0, 110, 97, 112, 108, 98, 0, 110, 108, 97, 0, 110, 108, 98, 0, 112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 97, 104, 101, 97, 100, 0, 112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 98, 101, 104, 105, 110, 100, 0, 110, 111, 110, 95, 97, 116, 111, 109, 105, 99, 95, 112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 97, 104, 101, 97, 100, 0, 110, 111, 110, 95, 97, 116, 111, 109, 105, 99, 95, 112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 98, 101, 104, 105, 110, 100, 0, 110, 101, 103, 97, 116, 105, 118, 101, 95, 108, 111, 111, 107, 97, 104, 101, 97, 100, 0, 110, 101, 103, 97, 116, 105, 118, 101, 95, 108, 111, 111, 107, 98, 101, 104, 105, 110, 100, 0, 115, 99, 115, 0, 115, 99, 97, 110, 95, 115, 117, 98, 115, 116, 114, 105, 110, 103, 0, 97, 116, 111, 109, 105, 99, 0, 115, 114, 0, 97, 115, 114, 0, 115, 99, 114, 105, 112, 116, 95, 114, 117, 110, 0, 97, 116, 111, 109, 105, 99, 95, 115, 99, 114, 105, 112, 116, 95, 114, 117, 110, 0]
let alasmeta: List[alasitem] = [alasitem { len: 3, meta: 0x80270000u32 }, alasitem { len: 3, meta: 0x80290000u32 }, alasitem { len: 5, meta: 0x802b0000u32 }, alasitem { len: 5, meta: 0x802c0000u32 }, alasitem { len: 3, meta: 0x80280000u32 }, alasitem { len: 3, meta: 0x802a0000u32 }, alasitem { len: 18, meta: 0x80270000u32 }, alasitem { len: 19, meta: 0x80290000u32 }, alasitem { len: 29, meta: 0x802b0000u32 }, alasitem { len: 30, meta: 0x802c0000u32 }, alasitem { len: 18, meta: 0x80280000u32 }, alasitem { len: 19, meta: 0x802a0000u32 }, alasitem { len: 3, meta: 0x80170000u32 }, alasitem { len: 14, meta: 0x80170000u32 }, alasitem { len: 6, meta: 0x80020000u32 }, alasitem { len: 2, meta: 0x80260000u32 }, alasitem { len: 3, meta: 0x8fff0000u32 }, alasitem { len: 10, meta: 0x80260000u32 }, alasitem { len: 17, meta: 0x8fff0000u32 }]
let alascount: i32 = 19
let chartypeoffset: List[u32] = [0, 13, 26, 39]
let posix_names: List[c_char] = [97, 108, 112, 104, 97, 0, 108, 111, 119, 101, 114, 0, 117, 112, 112, 101, 114, 0, 97, 108, 110, 117, 109, 0, 97, 115, 99, 105, 105, 0, 98, 108, 97, 110, 107, 0, 99, 110, 116, 114, 108, 0, 100, 105, 103, 105, 116, 0, 103, 114, 97, 112, 104, 0, 112, 114, 105, 110, 116, 0, 112, 117, 110, 99, 116, 0, 115, 112, 97, 99, 101, 0, 119, 111, 114, 100, 0, 120, 100, 105, 103, 105, 116, 0]
let posix_name_lengths: List[u8] = [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 6, 0]
let posix_substitutes: List[i32] = [1, ucp_L, 2, ucp_Ll, 2, ucp_Lu, 5, 0, -1, 0, -1, 1, 2, ucp_Cc, 2, ucp_Nd, 14, 0, 15, 0, 16, 0, 7, 0, 8, 0, 17, 0]
let pso_list: List[pso] = [pso { name: c"\x55\x54\x46\x38\x29".ptr as *const c_char, length: 5, type_: (PSO_OPT as u16), value: 0x00080000u32 }, pso { name: c"\x55\x54\x46\x29".ptr as *const c_char, length: 4, type_: (PSO_OPT as u16), value: 0x00080000u32 }, pso { name: c"\x55\x43\x50\x29".ptr as *const c_char, length: 4, type_: (PSO_OPT as u16), value: 0x00020000u32 }, pso { name: c"\x4e\x4f\x54\x45\x4d\x50\x54\x59\x29".ptr as *const c_char, length: 9, type_: (PSO_FLG as u16), value: 0x00010000u32 }, pso { name: c"\x4e\x4f\x54\x45\x4d\x50\x54\x59\x5f\x41\x54\x53\x54\x41\x52\x54\x29".ptr as *const c_char, length: 17, type_: (PSO_FLG as u16), value: 0x00020000u32 }, pso { name: c"\x4e\x4f\x5f\x41\x55\x54\x4f\x5f\x50\x4f\x53\x53\x45\x53\x53\x29".ptr as *const c_char, length: 16, type_: (PSO_OPTMZ as u16), value: 0x00000001u32 }, pso { name: c"\x4e\x4f\x5f\x44\x4f\x54\x53\x54\x41\x52\x5f\x41\x4e\x43\x48\x4f\x52\x29".ptr as *const c_char, length: 18, type_: (PSO_OPTMZ as u16), value: 0x00000002u32 }, pso { name: c"\x4e\x4f\x5f\x4a\x49\x54\x29".ptr as *const c_char, length: 7, type_: (PSO_FLG as u16), value: 0x00080000u32 }, pso { name: c"\x4e\x4f\x5f\x53\x54\x41\x52\x54\x5f\x4f\x50\x54\x29".ptr as *const c_char, length: 13, type_: (PSO_OPTMZ as u16), value: 0x00000004u32 }, pso { name: c"\x43\x41\x53\x45\x4c\x45\x53\x53\x5f\x52\x45\x53\x54\x52\x49\x43\x54\x29".ptr as *const c_char, length: 18, type_: (PSO_XOPT as u16), value: 0x00000080u32 }, pso { name: c"\x54\x55\x52\x4b\x49\x53\x48\x5f\x43\x41\x53\x49\x4e\x47\x29".ptr as *const c_char, length: 15, type_: (PSO_XOPT as u16), value: 0x00010000u32 }, pso { name: c"\x4c\x49\x4d\x49\x54\x5f\x48\x45\x41\x50\x3d".ptr as *const c_char, length: 11, type_: (PSO_LIMH as u16), value: 0 }, pso { name: c"\x4c\x49\x4d\x49\x54\x5f\x4d\x41\x54\x43\x48\x3d".ptr as *const c_char, length: 12, type_: (PSO_LIMM as u16), value: 0 }, pso { name: c"\x4c\x49\x4d\x49\x54\x5f\x44\x45\x50\x54\x48\x3d".ptr as *const c_char, length: 12, type_: (PSO_LIMD as u16), value: 0 }, pso { name: c"\x4c\x49\x4d\x49\x54\x5f\x52\x45\x43\x55\x52\x53\x49\x4f\x4e\x3d".ptr as *const c_char, length: 16, type_: (PSO_LIMD as u16), value: 0 }, pso { name: c"\x43\x52\x29".ptr as *const c_char, length: 3, type_: (PSO_NL as u16), value: 1 }, pso { name: c"\x4c\x46\x29".ptr as *const c_char, length: 3, type_: (PSO_NL as u16), value: 2 }, pso { name: c"\x43\x52\x4c\x46\x29".ptr as *const c_char, length: 5, type_: (PSO_NL as u16), value: 3 }, pso { name: c"\x41\x4e\x59\x29".ptr as *const c_char, length: 4, type_: (PSO_NL as u16), value: 4 }, pso { name: c"\x4e\x55\x4c\x29".ptr as *const c_char, length: 4, type_: (PSO_NL as u16), value: 6 }, pso { name: c"\x41\x4e\x59\x43\x52\x4c\x46\x29".ptr as *const c_char, length: 8, type_: (PSO_NL as u16), value: 5 }, pso { name: c"\x42\x53\x52\x5f\x41\x4e\x59\x43\x52\x4c\x46\x29".ptr as *const c_char, length: 12, type_: (PSO_BSR as u16), value: 2 }, pso { name: c"\x42\x53\x52\x5f\x55\x4e\x49\x43\x4f\x44\x45\x29".ptr as *const c_char, length: 12, type_: (PSO_BSR as u16), value: 1 }]
let opcode_possessify: List[u8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 43, 0, 44, 0, 45, 0, 0, 0, 0, 0, 0, 55, 0, 56, 0, 57, 0, 58, 0, 0, 0, 0, 0, 0, 68, 0, 69, 0, 70, 0, 71, 0, 0, 0, 0, 0, 0, 81, 0, 82, 0, 83, 0, 84, 0, 0, 0, 0, 0, 0, 94, 0, 95, 0, 96, 0, 97, 0, 0, 0, 0, 0, 0, 106, 0, 107, 0, 108, 0, 109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
