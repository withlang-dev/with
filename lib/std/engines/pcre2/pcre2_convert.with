// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
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
use std.engines.pcre2.pcre2_xclass
use std.collections

// contract: stored-unknown:0,unproved:3:out-parameter a return before the write,unproved:4:out-parameter written conditionally,unproved:5:read only — stores an argument; ownership not modeled
pub unsafe fn pcre2_pattern_convert_8(__param_pattern: *const u8, __param_plength: u64, __param_options: u32, __param_buffptr: *mut *mut u8, __param_bufflenptr: *mut u64, __param_ccontext: *mut pcre2_real_convert_context_8) -> i32 writes _pcre2_default_convert_context_8 {
    var __local_pattern = __param_pattern
    var __local_plength = __param_plength
    var __local_ccontext = __param_ccontext
    var __local_rc: i32

    var __local_null_str: List[u8] = [205]

    var __local_dummy_buffer: List[u8] = [0; 100]

    var __local_use_buffer: *mut u8 = ((&raw const __local_dummy_buffer[0] as *mut u8))

    var __local_use_length: u64 = ((100 as u64))

    var __local_utf: i32 = (((if ((__param_options as u32) & (1 as u32)) != 0: 1 else: 0) as i32))

    var __local_pattype: u32 = ((((__param_options as u32) & (((((16 as u32) | (4 as u32)) as u32) | (8 as u32)) as u32)) as u32))

    var __ci_expr_logic_0: i32 = 0

    if (__local_pattern == null) {
        (__ci_expr_logic_0 = (if __local_plength == 0: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__local_pattern = (&__local_null_str[0] as *const u8))
    }


    var __ci_expr_logic_1: i32

    if (__local_pattern == null) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if __param_bufflenptr == null: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        if (__param_bufflenptr != null) {
            ((*__param_bufflenptr) = ((0 as u64)))
        }

        return -51

    }


    var __ci_expr_logic_3: i32

    var __ci_expr_logic_2: i32

    if (((__param_options as u32) & ((~((((((((1 as u32) | (2 as u32)) as u32) | (48 as u32)) as u32) | (80 as u32)) as u32) | (((((16 as u32) | (4 as u32)) as u32) | (8 as u32)) as u32))) as u32)) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if ((__local_pattype as u32) & ((((~__local_pattype) as u32) +% (1 as u32)) as u32)) != __local_pattype: 1 else: 0))
    }

    if __ci_expr_logic_2 {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if __local_pattype == 0: 1 else: 0))
    }

    if __ci_expr_logic_3 {
        ((*__param_bufflenptr) = ((0 as u64)))

        return -34

    }


    if (__local_plength == (~(0 as u64))) {
        (__local_plength = ((_pcre2_strlen_8(__local_pattern) as u64)))
    }

    if (__local_ccontext == null) {
        (__local_ccontext = ((&raw mut _pcre2_default_convert_context_8 as *mut pcre2_real_convert_context_8)))
    }

    var __ci_expr_logic_4: i32 = 0

    if __local_utf {
        (__ci_expr_logic_4 = (if ((__param_options as u32) & (2 as u32)) == 0: 1 else: 0))
    }

    if __ci_expr_logic_4 {
        var __local_erroroffset: u64

        (__local_rc = ((_pcre2_valid_utf_8(__local_pattern, __local_plength, (&raw mut __local_erroroffset as *mut u64)) as i32)))

        if (__local_rc != 0) {
            ((*__param_bufflenptr) = __local_erroroffset)

            return __local_rc

        }

    }


    var __ci_expr_logic_5: i32 = 0

    if (__param_buffptr != null) {
        (__ci_expr_logic_5 = (if (*__param_buffptr) != null: 1 else: 0))
    }

    if __ci_expr_logic_5 {
        (__local_use_buffer = (*__param_buffptr))

        (__local_use_length = (*__param_bufflenptr))

    }


    var __local_i: i32 = ((0 as i32))

    while (__local_i < 2) {
        var __local_allocated: *mut u8

        var __local_dummyrun: i32 = with 0 as __ci_expr_seq_117 {
            var __ci_expr_logic_6: i32
            if (__param_buffptr == null) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (*__param_buffptr) == null: 1 else: 0))
            }
            __ci_expr_logic_6
        }

        while true {
            match __local_pattype {
                16 => {
                    (__local_rc = ((convert_glob((((__param_options as u32) & ((~16) as u32)) as u32), __local_pattern, __local_plength, __local_utf, __local_use_buffer, __local_use_length, __param_bufflenptr, __local_dummyrun, __local_ccontext) as i32)))
                },
                4 => {
                    (__local_rc = ((convert_posix(__local_pattype, __local_pattern, __local_plength, __local_utf, __local_use_buffer, __local_use_length, __param_bufflenptr, __local_dummyrun, __local_ccontext) as i32)))
                },
                8 => {
                    (__local_rc = ((convert_posix(__local_pattype, __local_pattern, __local_plength, __local_utf, __local_use_buffer, __local_use_length, __param_bufflenptr, __local_dummyrun, __local_ccontext) as i32)))
                },
                _ => {
                    loop {
                        0
                        if not (false) {
                            break
                        }
                    }

                    ((*__param_bufflenptr) = ((0 as u64)))

                    return -44

                },
            }

            break

        }

        var __ci_expr_logic_9: i32

        var __ci_expr_logic_8: i32

        if (__local_rc != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if __param_buffptr == null: 1 else: 0))
        }

        if __ci_expr_logic_8 {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_9 = (if (*__param_buffptr) != null: 1 else: 0))
        }

        if __ci_expr_logic_9 {
            return __local_rc
        }


        (__local_allocated = ((_pcre2_memctl_malloc_8((((sizeof[pcre2_memctl]() as u64) +% ((((((*__param_bufflenptr) as u64) +% (1 as u64)) as u64) *% (8 as u64)) as u64)) as u64), (__local_ccontext as *mut pcre2_memctl)) as *mut u8)))

        if (__local_allocated == null) {
            ((*__param_bufflenptr) = ((0 as u64)))

            return -48

        }

        ((*__param_buffptr) = ((((__local_allocated as *mut c_char) + (sizeof[pcre2_memctl]() as usize)) as *mut u8)))

        (__local_use_buffer = (*__param_buffptr))

        (__local_use_length = (((((*__param_bufflenptr) as u64) +% (1 as u64)) as u64)))


        (__local_i = __local_i + 1)

    }


    loop {
        0
        if not (false) {
            break
        }
    }

    ((*__param_bufflenptr) = ((0 as u64)))

    return -44

}

// contract: unproved:0:read only
pub unsafe fn pcre2_converted_pattern_free_8(__param_converted: *mut u8) {
    if (__param_converted != null) {
        var __local_memctl: *mut pcre2_memctl = ((((__param_converted as *mut c_char) - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        (*__local_memctl).free.unwrap()((__local_memctl as *mut c_void), (*__local_memctl).memory_data)

    }

}

// contract: unproved:1:read only,stored-unknown:4,out:6:u64,unproved:8:read only — stores an argument; ownership not modeled
unsafe fn convert_posix(__param_pattype: u32, __param_pattern: *const u8, __param_plength: u64, __param_utf: i32, __param_use_buffer: *mut u8, __param_use_length: u64, __param_bufflenptr: *mut u64, __param_dummyrun: i32, __param_ccontext: *mut pcre2_real_convert_context_8) -> i32 {
    var __local_plength = __param_plength
    var __local_posix__goto_154_12: *const u8 = null

    var __local_p__goto_155_14: *mut u8 = null

    var __local_pp__goto_156_14: *mut u8 = null

    var __local_endp__goto_157_14: *mut u8 = null

    var __local_convlength__goto_158_12: u64 = 0

    var __local_bracount__goto_160_10: u32 = 0

    var __local_posix_state__goto_161_10: u32 = 0

    var __local_lastspecial__goto_162_10: u32 = 0

    var __local_extended__goto_163_6: i32 = 0

    var __local_nextisliteral__goto_164_6: i32 = 0

    var __local_s__goto_172_1: *const c_char = null

    var __local_c__goto_178_12: u32 = 0

    var __local_sc__goto_178_15: u32 = 0

    var __local_clength__goto_179_7: i32 = 0

    var __local_s__goto_208_7: *const c_char = null

    var __local_s__goto_224_11: *const c_char = null

    var __local_s__goto_241_32: *const c_char = null

    var __local_s__goto_253_5: *const c_char = null

    var __local_s__goto_291_9: *const c_char = null

    var __local_s__goto_297_9: *const c_char = null

    var __local_s__goto_308_51: *const c_char = null

    var __local_s__goto_367_7: *const c_char = null

    var __ci_expr_old_0: *mut u8 = null

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_old_2: *mut u8 = null

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_old_6: *mut u8 = null

    var __ci_expr_old_7: *mut u8 = null

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_old_9: *mut u8 = null

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_old_11: *mut u8 = null

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_old_14: *mut u8 = null

    var __ci_expr_old_15: *mut u8 = null

    var __ci_expr_old_16: *const u8 = null

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_old_18: *mut u8 = null

    var __ci_expr_logic_20: i32 = 0

    var __ci_expr_logic_21: i32 = 0

    var __ci_expr_logic_22: i32 = 0

    var __ci_expr_old_23: *mut u8 = null

    var __ci_expr_old_24: *mut u8 = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_posix__goto_154_12 = __param_pattern)
        (__local_p__goto_155_14 = __param_use_buffer)
        (__local_pp__goto_156_14 = __local_p__goto_155_14)
        (__local_endp__goto_157_14 = (__local_p__goto_155_14 + (__param_use_length as usize)) - ((1 as isize) as usize))
        (__local_convlength__goto_158_12 = ((0 as u64)))
        (__local_bracount__goto_160_10 = ((0 as u32)))
        (__local_posix_state__goto_161_10 = ((0 as u32)))
        (__local_lastspecial__goto_162_10 = ((0 as u32)))
        (__local_extended__goto_163_6 = (((if ((__param_pattype as u32) & (8 as u32)) != 0: 1 else: 0) as i32)))
        (__local_nextisliteral__goto_164_6 = ((0 as i32)))
        ((*__param_bufflenptr) = __local_plength)
        (__local_s__goto_172_1 = c"(*NUL)".ptr)
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((*__local_s__goto_172_1) != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        (__local_s__goto_172_1 = __local_s__goto_172_1 + 1)
        goto '__ci_bb_1
    }

    '__ci_bb_4 {
        goto '__ci_bb_7
    }

    '__ci_bb_5 {
        return -48
    }

    '__ci_bb_6 {
        (__ci_expr_old_0 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_0) = (((*__local_s__goto_172_1) as u8)))
        goto '__ci_bb_3
    }

    '__ci_bb_7 {
        if (__local_plength > 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        (__local_clength__goto_179_7 = ((1 as i32)))
        (__local_convlength__goto_158_12 = (__local_convlength__goto_158_12 +% (((((__local_p__goto_155_14 as usize) -% (__local_pp__goto_156_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        if __param_dummyrun {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_9 {
        if (__local_posix_state__goto_161_10 >= 3) {
            goto '__ci_bb_160
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_10 {
        (__local_p__goto_155_14 = __param_use_buffer)
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        (__local_pp__goto_156_14 = __local_p__goto_155_14)
        (__local_c__goto_178_12 = (((*__local_posix__goto_154_12) as u32)))
        (__ci_expr_logic_1 = 0)
        if __param_utf {
            (__ci_expr_logic_1 = (if __local_c__goto_178_12 >= 192: 1 else: 0))
        }
        if __ci_expr_logic_1 {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_12 {
        if (((__local_c__goto_178_12 as u32) & (32 as u32)) == 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + ((__local_clength__goto_179_7 as isize) as usize))
        (__local_plength = (__local_plength -% (__local_clength__goto_179_7 as u64)))
        (__local_sc__goto_178_15 = (((if __local_nextisliteral__goto_164_6: (0 as u32) else: __local_c__goto_178_12) as u32)))
        (__local_nextisliteral__goto_164_6 = ((0 as i32)))
        if (__local_posix_state__goto_161_10 >= 3) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_14 {
        (__local_c__goto_178_12 = ((((((((__local_c__goto_178_12 as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((__local_posix__goto_154_12[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 1)
        goto '__ci_bb_16
    }

    '__ci_bb_15 {
        if (((__local_c__goto_178_12 as u32) & (16 as u32)) == 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_16 {
        goto '__ci_bb_13
    }

    '__ci_bb_17 {
        (__local_c__goto_178_12 = ((((((((((__local_c__goto_178_12 as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((__local_posix__goto_154_12[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_posix__goto_154_12[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 2)
        goto '__ci_bb_19
    }

    '__ci_bb_18 {
        if (((__local_c__goto_178_12 as u32) & (8 as u32)) == 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_19 {
        goto '__ci_bb_16
    }

    '__ci_bb_20 {
        (__local_c__goto_178_12 = ((((((((((((__local_c__goto_178_12 as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((__local_posix__goto_154_12[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_posix__goto_154_12[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_posix__goto_154_12[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 3)
        goto '__ci_bb_22
    }

    '__ci_bb_21 {
        if (((__local_c__goto_178_12 as u32) & (4 as u32)) == 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_22 {
        goto '__ci_bb_19
    }

    '__ci_bb_23 {
        (__local_c__goto_178_12 = ((((((((((((((__local_c__goto_178_12 as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((__local_posix__goto_154_12[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_posix__goto_154_12[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_posix__goto_154_12[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_posix__goto_154_12[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 4)
        goto '__ci_bb_25
    }

    '__ci_bb_24 {
        (__local_c__goto_178_12 = ((((((((((((((((__local_c__goto_178_12 as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((__local_posix__goto_154_12[1]) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_posix__goto_154_12[2]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_posix__goto_154_12[3]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_posix__goto_154_12[4]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_posix__goto_154_12[5]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 5)
        goto '__ci_bb_25
    }

    '__ci_bb_25 {
        goto '__ci_bb_22
    }

    '__ci_bb_26 {
        if (__local_c__goto_178_12 == 93) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_27 {
        goto '__ci_bb_69
    }

    '__ci_bb_28 {
        goto '__ci_bb_7
    }

    '__ci_bb_29 {
        (__local_s__goto_208_7 = c"\x5d".ptr)
        goto '__ci_bb_32
    }

    '__ci_bb_30 {
        goto '__ci_bb_38
    }

    '__ci_bb_31 {
        goto '__ci_bb_28
    }

    '__ci_bb_32 {
        if ((*__local_s__goto_208_7) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_33 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_34 {
        (__local_s__goto_208_7 = __local_s__goto_208_7 + 1)
        goto '__ci_bb_32
    }

    '__ci_bb_35 {
        (__local_posix_state__goto_161_10 = ((2 as u32)))
        goto '__ci_bb_31
    }

    '__ci_bb_36 {
        return -48
    }

    '__ci_bb_37 {
        (__ci_expr_old_2 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_2) = (((*__local_s__goto_208_7) as u8)))
        goto '__ci_bb_34
    }

    '__ci_bb_38 {
        if (__local_posix_state__goto_161_10 == 5) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_39 {
        if (__local_c__goto_178_12 == 92) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_40 {
        (__ci_expr_logic_3 = 0)
        if (__local_c__goto_178_12 >= 97) {
            (__ci_expr_logic_3 = (if __local_c__goto_178_12 <= 122: 1 else: 0))
        }
        if __ci_expr_logic_3 {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_41 {
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        (__local_posix_state__goto_161_10 = ((3 as u32)))
        (__ci_expr_logic_5 = 0)
        (__ci_expr_logic_4 = 0)
        if (__local_c__goto_178_12 == 58) {
            (__ci_expr_logic_4 = (if __local_plength > 0: 1 else: 0))
        }
        if __ci_expr_logic_4 {
            (__ci_expr_logic_5 = (if (*__local_posix__goto_154_12) == 93: 1 else: 0))
        }
        if __ci_expr_logic_5 {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        (__local_s__goto_224_11 = c":]".ptr)
        goto '__ci_bb_45
    }

    '__ci_bb_44 {
        goto '__ci_bb_51
    }

    '__ci_bb_45 {
        if ((*__local_s__goto_224_11) != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_46 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_47 {
        (__local_s__goto_224_11 = __local_s__goto_224_11 + 1)
        goto '__ci_bb_45
    }

    '__ci_bb_48 {
        (__local_plength = (__local_plength -% 1))
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        goto '__ci_bb_7
    }

    '__ci_bb_49 {
        return -48
    }

    '__ci_bb_50 {
        (__ci_expr_old_6 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_6) = (((*__local_s__goto_224_11) as u8)))
        goto '__ci_bb_47
    }

    '__ci_bb_51 {
        if (__local_c__goto_178_12 == 91) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_52 {
        (__local_posix_state__goto_161_10 = ((4 as u32)))
        goto '__ci_bb_53
    }

    '__ci_bb_53 {
        goto '__ci_bb_39
    }

    '__ci_bb_54 {
        if (__local_c__goto_178_12 == 58) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_55 {
        (__local_posix_state__goto_161_10 = ((5 as u32)))
        goto '__ci_bb_56
    }

    '__ci_bb_56 {
        goto '__ci_bb_39
    }

    '__ci_bb_57 {
        if (__local_posix_state__goto_161_10 == 3) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_58 {
        if (__local_posix_state__goto_161_10 == 4) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_59 {
        (__local_s__goto_241_32 = c"\x5c".ptr)
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        if ((__local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize)) > __local_endp__goto_157_14) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_61 {
        if ((*__local_s__goto_241_32) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_62 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_63 {
        (__local_s__goto_241_32 = __local_s__goto_241_32 + 1)
        goto '__ci_bb_61
    }

    '__ci_bb_64 {
        goto '__ci_bb_60
    }

    '__ci_bb_65 {
        return -48
    }

    '__ci_bb_66 {
        (__ci_expr_old_7 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_7) = (((*__local_s__goto_241_32) as u8)))
        goto '__ci_bb_63
    }

    '__ci_bb_67 {
        return -48
    }

    '__ci_bb_68 {
        with_memcpy(((__local_p__goto_155_14 as *mut c_void) as *mut u8), (((__local_posix__goto_154_12 - ((__local_clength__goto_179_7 as isize) as usize)) as *const c_void) as *const u8), (((__local_clength__goto_179_7 * (8 / 8)) as u64) as i64))
        (__local_p__goto_155_14 = __local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize))
        goto '__ci_bb_31
    }

    '__ci_bb_69 {
        if (__local_sc__goto_178_15 == 91) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_70 {
        goto '__ci_bb_28
    }

    '__ci_bb_71 {
        (__local_s__goto_253_5 = c"\x5b".ptr)
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        if ((*__local_s__goto_253_5) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_73 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_74 {
        (__local_s__goto_253_5 = __local_s__goto_253_5 + 1)
        goto '__ci_bb_72
    }

    '__ci_bb_75 {
        (__local_posix_state__goto_161_10 = ((3 as u32)))
        if (__local_plength > 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_76 {
        return -48
    }

    '__ci_bb_77 {
        (__ci_expr_old_8 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_8) = (((*__local_s__goto_253_5) as u8)))
        goto '__ci_bb_74
    }

    '__ci_bb_78 {
        if ((*__local_posix__goto_154_12) == 94) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_79 {
        goto '__ci_bb_70
    }

    '__ci_bb_80 {
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        (__local_plength = (__local_plength -% 1))
        (__local_s__goto_291_9 = c"\x5e".ptr)
        goto '__ci_bb_82
    }

    '__ci_bb_81 {
        (__ci_expr_logic_10 = 0)
        if (__local_plength > 0) {
            (__ci_expr_logic_10 = (if (*__local_posix__goto_154_12) == 93: 1 else: 0))
        }
        if __ci_expr_logic_10 {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_82 {
        if ((*__local_s__goto_291_9) != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_83 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_84 {
        (__local_s__goto_291_9 = __local_s__goto_291_9 + 1)
        goto '__ci_bb_82
    }

    '__ci_bb_85 {
        goto '__ci_bb_81
    }

    '__ci_bb_86 {
        return -48
    }

    '__ci_bb_87 {
        (__ci_expr_old_9 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_9) = (((*__local_s__goto_291_9) as u8)))
        goto '__ci_bb_84
    }

    '__ci_bb_88 {
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        (__local_plength = (__local_plength -% 1))
        (__local_s__goto_297_9 = c"\x5d".ptr)
        goto '__ci_bb_90
    }

    '__ci_bb_89 {
        goto '__ci_bb_79
    }

    '__ci_bb_90 {
        if ((*__local_s__goto_297_9) != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_91 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_92 {
        (__local_s__goto_297_9 = __local_s__goto_297_9 + 1)
        goto '__ci_bb_90
    }

    '__ci_bb_93 {
        goto '__ci_bb_89
    }

    '__ci_bb_94 {
        return -48
    }

    '__ci_bb_95 {
        (__ci_expr_old_11 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_11) = (((*__local_s__goto_297_9) as u8)))
        goto '__ci_bb_92
    }

    '__ci_bb_96 {
        if (__local_plength == 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_97 {
        return 101
    }

    '__ci_bb_98 {
        if __local_extended__goto_163_6 {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_100
        }
    }

    '__ci_bb_99 {
        (__local_nextisliteral__goto_164_6 = ((1 as i32)))
        goto '__ci_bb_101
    }

    '__ci_bb_100 {
        (__ci_expr_logic_12 = 0)
        if ((*__local_posix__goto_154_12) < 255) {
            (__ci_expr_logic_12 = (if strchr(posix_meta_escapes, ((*__local_posix__goto_154_12) as i32)) != null: 1 else: 0))
        }
        if __ci_expr_logic_12 {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_101 {
        goto '__ci_bb_70
    }

    '__ci_bb_102 {
        (__ci_expr_logic_13 = 0)
        if ((*__local_posix__goto_154_12) >= 48) {
            (__ci_expr_logic_13 = (if (*__local_posix__goto_154_12) <= 57: 1 else: 0))
        }
        if __ci_expr_logic_13 {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_103 {
        (__local_nextisliteral__goto_164_6 = ((1 as i32)))
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        goto '__ci_bb_101
    }

    '__ci_bb_105 {
        (__local_s__goto_308_51 = c"\x5c".ptr)
        goto '__ci_bb_107
    }

    '__ci_bb_106 {
        if ((__local_p__goto_155_14 + ((1 as isize) as usize)) > __local_endp__goto_157_14) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_107 {
        if ((*__local_s__goto_308_51) != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_108 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_112
        }
    }

    '__ci_bb_109 {
        (__local_s__goto_308_51 = __local_s__goto_308_51 + 1)
        goto '__ci_bb_107
    }

    '__ci_bb_110 {
        goto '__ci_bb_106
    }

    '__ci_bb_111 {
        return -48
    }

    '__ci_bb_112 {
        (__ci_expr_old_14 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_14) = (((*__local_s__goto_308_51) as u8)))
        goto '__ci_bb_109
    }

    '__ci_bb_113 {
        return -48
    }

    '__ci_bb_114 {
        (__ci_expr_old_15 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        (__ci_expr_old_16 = __local_posix__goto_154_12)
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        ((*__ci_expr_old_15) = (*__ci_expr_old_16))
        (__local_lastspecial__goto_162_10 = (((*__ci_expr_old_15) as u32)))
        (__local_plength = (__local_plength -% 1))
        goto '__ci_bb_104
    }

    '__ci_bb_115 {
        if (not __local_extended__goto_163_6) {
            (__ci_expr_logic_17 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_17 = (if __local_bracount__goto_160_10 == 0: 1 else: 0))
        }
        if __ci_expr_logic_17 {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_116 {
        goto '__ci_bb_118
    }

    '__ci_bb_117 {
        (__local_bracount__goto_160_10 = (__local_bracount__goto_160_10 -% 1))
        goto '__ci_bb_119
    }

    '__ci_bb_118 {
        (__local_s__goto_367_7 = c"\x5c".ptr)
        goto '__ci_bb_140
    }

    '__ci_bb_119 {
        (__local_lastspecial__goto_162_10 = __local_c__goto_178_12)
        if ((__local_p__goto_155_14 + ((1 as isize) as usize)) > __local_endp__goto_157_14) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_120 {
        (__local_bracount__goto_160_10 = (__local_bracount__goto_160_10 +% 1))
        goto '__ci_bb_121
    }

    '__ci_bb_121 {
        if (not __local_extended__goto_163_6) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_123
        }
    }

    '__ci_bb_122 {
        goto '__ci_bb_118
    }

    '__ci_bb_123 {
        goto '__ci_bb_124
    }

    '__ci_bb_124 {
        (__local_posix_state__goto_161_10 = ((2 as u32)))
        goto '__ci_bb_119
    }

    '__ci_bb_125 {
        return -48
    }

    '__ci_bb_126 {
        (__ci_expr_old_18 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_18) = ((__local_c__goto_178_12 as u8)))
        goto '__ci_bb_70
    }

    '__ci_bb_127 {
        if (__local_lastspecial__goto_162_10 != 42) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_128 {
        (__ci_expr_logic_20 = 0)
        if (not __local_extended__goto_163_6) {
            var __ci_expr_logic_19: i32

            if (__local_posix_state__goto_161_10 < 2) {
                (__ci_expr_logic_19 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_19 = (if __local_lastspecial__goto_162_10 == 40: 1 else: 0))
            }

            (__ci_expr_logic_20 = (if __ci_expr_logic_19: 1 else: 0))

        }
        if __ci_expr_logic_20 {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_129 {
        goto '__ci_bb_70
    }

    '__ci_bb_130 {
        goto '__ci_bb_118
    }

    '__ci_bb_131 {
        goto '__ci_bb_119
    }

    '__ci_bb_132 {
        if __local_extended__goto_163_6 {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_133 {
        goto '__ci_bb_119
    }

    '__ci_bb_134 {
        if (__local_posix_state__goto_161_10 == 0) {
            (__ci_expr_logic_21 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_21 = (if __local_lastspecial__goto_162_10 == 40: 1 else: 0))
        }
        if __ci_expr_logic_21 {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_135 {
        (__local_posix_state__goto_161_10 = ((1 as u32)))
        goto '__ci_bb_119
    }

    '__ci_bb_136 {
        goto '__ci_bb_137
    }

    '__ci_bb_137 {
        (__ci_expr_logic_22 = 0)
        if (__local_c__goto_178_12 < 255) {
            (__ci_expr_logic_22 = (if strchr(pcre2_escaped_literals, (__local_c__goto_178_12 as i32)) != null: 1 else: 0))
        }
        if __ci_expr_logic_22 {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_138 {
        goto '__ci_bb_118
    }

    '__ci_bb_139 {
        (__local_lastspecial__goto_162_10 = ((255 as u32)))
        if ((__local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize)) > __local_endp__goto_157_14) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_140 {
        if ((*__local_s__goto_367_7) != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_141 {
        if (__local_p__goto_155_14 >= __local_endp__goto_157_14) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_142 {
        (__local_s__goto_367_7 = __local_s__goto_367_7 + 1)
        goto '__ci_bb_140
    }

    '__ci_bb_143 {
        goto '__ci_bb_139
    }

    '__ci_bb_144 {
        return -48
    }

    '__ci_bb_145 {
        (__ci_expr_old_23 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_23) = (((*__local_s__goto_367_7) as u8)))
        goto '__ci_bb_142
    }

    '__ci_bb_146 {
        return -48
    }

    '__ci_bb_147 {
        with_memcpy(((__local_p__goto_155_14 as *mut c_void) as *mut u8), (((__local_posix__goto_154_12 - ((__local_clength__goto_179_7 as isize) as usize)) as *const c_void) as *const u8), (((__local_clength__goto_179_7 * (8 / 8)) as u64) as i64))
        (__local_p__goto_155_14 = __local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize))
        (__local_posix_state__goto_161_10 = ((2 as u32)))
        goto '__ci_bb_70
    }

    '__ci_bb_148 {
        if (__local_sc__goto_178_15 == 92) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_149 {
        if (__local_sc__goto_178_15 == 41) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_150 {
        if (__local_sc__goto_178_15 == 40) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_151 {
        if (__local_sc__goto_178_15 == 63) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_152 {
        if (__local_sc__goto_178_15 == 43) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_153 {
        if (__local_sc__goto_178_15 == 123) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_154 {
        if (__local_sc__goto_178_15 == 125) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_155 {
        if (__local_sc__goto_178_15 == 124) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_156 {
        if (__local_sc__goto_178_15 == 46) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_157 {
        if (__local_sc__goto_178_15 == 36) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_158 {
        if (__local_sc__goto_178_15 == 42) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_159 {
        if (__local_sc__goto_178_15 == 94) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_160 {
        return 106
    }

    '__ci_bb_161 {
        (__local_convlength__goto_158_12 = (__local_convlength__goto_158_12 +% (((((__local_p__goto_155_14 as usize) -% (__local_pp__goto_156_14 as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))
        ((*__param_bufflenptr) = __local_convlength__goto_158_12)
        (__ci_expr_old_24 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((*__ci_expr_old_24) = ((0 as u8)))
        return 0
    }

    __ci_unreachable()

}

unsafe fn convert_glob_write(__param_out: *mut pcre2_output_context, __param_chr: u8) {
    ((*__param_out).output_size = ((*__param_out).output_size +% 1))

    if ((*__param_out).output < (*__param_out).output_end) {
        var __ci_expr_old_0: *mut u8 = (*__param_out).output

        ((*__param_out).output = (*__param_out).output + 1)

        ((*__ci_expr_old_0) = __param_chr)

    }

}

unsafe fn convert_glob_write_str(__param_out: *mut pcre2_output_context, __param_length: u64) {
    var __local_length = __param_length
    var __local_out_str: *mut u8 = ((&raw const (*__param_out).out_str[0] as *mut u8))

    var __local_output: *mut u8 = (*__param_out).output

    var __local_output_end: *const u8 = (*__param_out).output_end

    var __local_output_size: u64 = (*__param_out).output_size

    loop {
        (__local_output_size = (__local_output_size +% 1))

        if (__local_output < __local_output_end) {
            var __ci_expr_old_0: *mut u8 = __local_output

            (__local_output = __local_output + 1)

            var __ci_expr_old_1: *mut u8 = __local_out_str

            (__local_out_str = __local_out_str + 1)

            ((*__ci_expr_old_0) = (*__ci_expr_old_1))

        }

        (__local_length = (__local_length -% 1))
        if not ((__local_length != 0)) {
            break
        }
    }

    ((*__param_out).output = __local_output)

    ((*__param_out).output_size = __local_output_size)

}

unsafe fn convert_glob_print_separator(__param_out: *mut pcre2_output_context, __param_separator: u8, __param_with_escape: i32) {
    if __param_with_escape {
        convert_glob_write(__param_out, (92 as u8))
    }

    convert_glob_write(__param_out, __param_separator)

}

unsafe fn convert_glob_print_wildcard(__param_out: *mut pcre2_output_context, __param_separator: u8, __param_with_escape: i32) {
    ((*__param_out).out_str[0] = ((91 as u8)))

    ((*__param_out).out_str[1] = ((94 as u8)))

    convert_glob_write_str(__param_out, (2 as u64))

    convert_glob_print_separator(__param_out, __param_separator, __param_with_escape)

    convert_glob_write(__param_out, (93 as u8))

}

// contract: unproved:0:out-parameter read before the write,unproved:1:read only,unproved:2:out-parameter a return before the write
unsafe fn convert_glob_parse_class(__param_from: *mut *const u8, __param_pattern_end: *const u8, __param_out: *mut pcre2_output_context) -> i32 {
    var __local_start: *const u8 = ((*__param_from) + ((1 as isize) as usize))

    var __local_pattern: *const u8 = __local_start

    var __local_class_ptr: *const c_char

    var __local_c: u8

    var __local_class_index: i32

    while true {
        if (__local_pattern >= __param_pattern_end) {
            return 0
        }

        var __ci_expr_old_0: *const u8 = __local_pattern

        (__local_pattern = __local_pattern + 1)

        (__local_c = (*__ci_expr_old_0))


        var __ci_expr_logic_1: i32

        if (__local_c < 97) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if __local_c > 122: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            break
        }


    }

    var __ci_expr_logic_3: i32

    var __ci_expr_logic_2: i32

    if (__local_c != 58) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if __local_pattern >= __param_pattern_end: 1 else: 0))
    }

    if __ci_expr_logic_2 {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (*__local_pattern) != 93: 1 else: 0))
    }

    if __ci_expr_logic_3 {
        return 0
    }


    (__local_class_ptr = posix_classes)

    (__local_class_index = ((1 as i32)))

    while true {
        if ((*__local_class_ptr) == 0) {
            return 0
        }

        (__local_pattern = __local_start)

        while ((*__local_pattern) == (((*__local_class_ptr) as u8))) {
            if ((*__local_pattern) == 58) {
                (__local_pattern = __local_pattern + ((2 as isize) as usize))

                (__local_start = __local_start - ((2 as isize) as usize))

                loop {
                    var __ci_expr_old_4: *const u8 = __local_start

                    (__local_start = __local_start + 1)

                    convert_glob_write(__param_out, (*__ci_expr_old_4))

                    if not ((__local_start < __local_pattern)) {
                        break
                    }
                }

                ((*__param_from) = __local_pattern)

                return __local_class_index

            }

            (__local_pattern = __local_pattern + 1)

            (__local_class_ptr = __local_class_ptr + 1)

        }

        while ((*__local_class_ptr) != 58) {
            (__local_class_ptr = __local_class_ptr + 1)
        }

        (__local_class_ptr = __local_class_ptr + 1)

        (__local_class_index = __local_class_index + 1)

    }

}

fn convert_glob_char_in_class(__param_class_index: i32, __param_c: u8) -> i32 {
    var __local_cbits: *const u8 = ((&_pcre2_default_tables_8[0] as *const u8) + ((512 as isize) as usize))

    var __local_cbit: i32

    while true {
        match __param_class_index {
            1 => {
                if (__param_c == 95) {
                    return 0
                }

                if (((((unsafe (__local_cbits + ((64 as isize) as usize))[((__param_c as i32) / 8)]) as i32) as u32) & (((1 as u32) << (((__param_c as i32) & (7 as i32)) as u32)) as u32)) != 0) {
                    return 0
                }

                (__local_cbit = ((160 as i32)))

            },
            2 => {
                (__local_cbit = ((128 as i32)))
            },
            3 => {
                (__local_cbit = ((96 as i32)))
            },
            4 => {
                if (__param_c == 95) {
                    return 0
                }

                (__local_cbit = ((160 as i32)))

            },
            5 => {
                if (((((unsafe (__local_cbits + ((288 as isize) as usize))[((__param_c as i32) / 8)]) as i32) as u32) & (((1 as u32) << (((__param_c as i32) & (7 as i32)) as u32)) as u32)) != 0) {
                    return 1
                }

                (__local_cbit = ((224 as i32)))

            },
            6 => {
                var __ci_expr_logic_2: i32

                var __ci_expr_logic_1: i32

                var __ci_expr_logic_0: i32

                if (__param_c == 10) {
                    (__ci_expr_logic_0 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_0 = (if __param_c == 11: 1 else: 0))
                }

                if __ci_expr_logic_0 {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if __param_c == 12: 1 else: 0))
                }

                if __ci_expr_logic_1 {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if __param_c == 13: 1 else: 0))
                }

                if __ci_expr_logic_2 {
                    return 0
                }


                (__local_cbit = ((0 as i32)))

            },
            7 => {
                (__local_cbit = ((288 as i32)))
            },
            8 => {
                (__local_cbit = ((64 as i32)))
            },
            9 => {
                (__local_cbit = ((192 as i32)))
            },
            10 => {
                (__local_cbit = ((224 as i32)))
            },
            11 => {
                (__local_cbit = ((256 as i32)))
            },
            12 => {
                (__local_cbit = ((0 as i32)))
            },
            13 => {
                (__local_cbit = ((160 as i32)))
            },
            14 => {
                (__local_cbit = ((32 as i32)))
            },
            _ => {
                return 0
            },
        }

        break

    }

    return (if ((((unsafe (__local_cbits + ((__local_cbit as isize) as usize))[((__param_c as i32) / 8)]) as i32) as u32) & (((1 as u32) << (((__param_c as i32) & (7 as i32)) as u32)) as u32)) != 0: 1 else: 0)

}

// contract: unproved:0:out-parameter read before the write,unproved:1:read only,unproved:2:out-parameter a return before the write
unsafe fn convert_glob_parse_range(__param_from: *mut *const u8, __param_pattern_end: *const u8, __param_out: *mut pcre2_output_context, __param_utf: i32, __param_separator: u8, __param_with_escape: i32, __param_escape: u8, __param_no_wildsep: i32) -> i32 {
    var __local_is_negative: i32 = ((0 as i32))

    var __local_separator_seen: i32 = ((0 as i32))

    var __local_has_prev_c: i32

    var __local_pattern: *const u8 = (*__param_from)

    var __local_char_start: *const u8 = ((null as *const u8))

    var __local_c: u32

    var __local_prev_c: u32


    var __local_len: i32

    var __local_class_index: i32



    if (__local_pattern >= __param_pattern_end) {
        ((*__param_from) = __local_pattern)

        return 106

    }

    var __ci_expr_logic_0: i32

    if ((*__local_pattern) == 33) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (*__local_pattern) == 94: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__local_pattern = __local_pattern + 1)

        if (__local_pattern >= __param_pattern_end) {
            ((*__param_from) = __local_pattern)

            return 106

        }

        (__local_is_negative = ((1 as i32)))

        ((*__param_out).out_str[0] = ((91 as u8)))

        ((*__param_out).out_str[1] = ((94 as u8)))

        (__local_len = ((2 as i32)))

        if (not __param_no_wildsep) {
            if __param_with_escape {
                ((*__param_out).out_str[__local_len] = ((92 as u8)))

                (__local_len = __local_len + 1)

            }

            ((*__param_out).out_str[__local_len] = __param_separator)

        }

        convert_glob_write_str(__param_out, ((__local_len + 1) as u64))

    } else {
        convert_glob_write(__param_out, (91 as u8))
    }


    (__local_has_prev_c = ((0 as i32)))

    (__local_prev_c = ((0 as u32)))

    if ((*__local_pattern) == 93) {
        ((*__param_out).out_str[0] = ((92 as u8)))

        ((*__param_out).out_str[1] = ((93 as u8)))

        convert_glob_write_str(__param_out, (2 as u64))

        (__local_has_prev_c = ((1 as i32)))

        (__local_prev_c = ((93 as u32)))

        (__local_pattern = __local_pattern + 1)

    }

    while (__local_pattern < __param_pattern_end) {
        (__local_char_start = __local_pattern)

        var __ci_expr_old_1: *const u8 = __local_pattern

        (__local_pattern = __local_pattern + 1)

        (__local_c = (((*__ci_expr_old_1) as u32)))


        var __ci_expr_logic_2: i32 = 0

        if __param_utf {
            (__ci_expr_logic_2 = (if __local_c >= 192: 1 else: 0))
        }

        if __ci_expr_logic_2 {
            if (((__local_c as u32) & (32 as u32)) == 0) {
                var __ci_expr_old_3: *const u8 = __local_pattern

                (__local_pattern = __local_pattern + 1)

                (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_3) as i32) as u32) & (63 as u32)) as u32)) as u32)))

            } else {
                if (((__local_c as u32) & (16 as u32)) == 0) {
                    (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    (__local_pattern = __local_pattern + ((2 as isize) as usize))

                } else {
                    if (((__local_c as u32) & (8 as u32)) == 0) {
                        (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_pattern = __local_pattern + ((3 as isize) as usize))

                    } else {
                        if (((__local_c as u32) & (4 as u32)) == 0) {
                            (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_pattern = __local_pattern + ((4 as isize) as usize))

                        } else {
                            (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_pattern = __local_pattern + ((5 as isize) as usize))

                        }
                    }
                }
            }

        }




        if (__local_c == 93) {
            convert_glob_write(__param_out, (__local_c as u8))

            var __ci_expr_logic_5: i32 = 0

            var __ci_expr_logic_4: i32 = 0

            if (not __local_is_negative) {
                (__ci_expr_logic_4 = (if not __param_no_wildsep: 1 else: 0))
            }

            if __ci_expr_logic_4 {
                (__ci_expr_logic_5 = (if __local_separator_seen: 1 else: 0))
            }

            if __ci_expr_logic_5 {
                ((*__param_out).out_str[0] = ((40 as u8)))

                ((*__param_out).out_str[1] = ((63 as u8)))

                ((*__param_out).out_str[2] = ((60 as u8)))

                ((*__param_out).out_str[3] = ((33 as u8)))

                convert_glob_write_str(__param_out, (4 as u64))

                convert_glob_print_separator(__param_out, __param_separator, __param_with_escape)

                convert_glob_write(__param_out, (41 as u8))

            }


            ((*__param_from) = __local_pattern)

            return 0

        }

        if (__local_pattern >= __param_pattern_end) {
            break
        }

        var __ci_expr_logic_6: i32 = 0

        if (__local_c == 91) {
            (__ci_expr_logic_6 = (if (*__local_pattern) == 58: 1 else: 0))
        }

        if __ci_expr_logic_6 {
            ((*__param_from) = __local_pattern)

            (__local_class_index = ((convert_glob_parse_class(__param_from, __param_pattern_end, __param_out) as i32)))

            if (__local_class_index != 0) {
                (__local_pattern = (*__param_from))

                (__local_has_prev_c = ((0 as i32)))

                (__local_prev_c = ((0 as u32)))

                var __ci_expr_logic_7: i32 = 0

                if (not __local_is_negative) {
                    (__ci_expr_logic_7 = (if convert_glob_char_in_class(__local_class_index, __param_separator): 1 else: 0))
                }

                if __ci_expr_logic_7 {
                    (__local_separator_seen = ((1 as i32)))
                }


                continue

            }

        } else {
            var __ci_expr_logic_9: i32 = 0

            var __ci_expr_logic_8: i32 = 0

            if (__local_c == 45) {
                (__ci_expr_logic_8 = (if __local_has_prev_c: 1 else: 0))
            }

            if __ci_expr_logic_8 {
                (__ci_expr_logic_9 = (if (*__local_pattern) != 93: 1 else: 0))
            }

            if __ci_expr_logic_9 {
                convert_glob_write(__param_out, (45 as u8))

                (__local_char_start = __local_pattern)

                var __ci_expr_old_10: *const u8 = __local_pattern

                (__local_pattern = __local_pattern + 1)

                (__local_c = (((*__ci_expr_old_10) as u32)))


                var __ci_expr_logic_11: i32 = 0

                if __param_utf {
                    (__ci_expr_logic_11 = (if __local_c >= 192: 1 else: 0))
                }

                if __ci_expr_logic_11 {
                    if (((__local_c as u32) & (32 as u32)) == 0) {
                        var __ci_expr_old_12: *const u8 = __local_pattern

                        (__local_pattern = __local_pattern + 1)

                        (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_12) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    } else {
                        if (((__local_c as u32) & (16 as u32)) == 0) {
                            (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_pattern = __local_pattern + ((2 as isize) as usize))

                        } else {
                            if (((__local_c as u32) & (8 as u32)) == 0) {
                                (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_pattern = __local_pattern + ((3 as isize) as usize))

                            } else {
                                if (((__local_c as u32) & (4 as u32)) == 0) {
                                    (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_pattern = __local_pattern + ((4 as isize) as usize))

                                } else {
                                    (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_pattern = __local_pattern + ((5 as isize) as usize))

                                }
                            }
                        }
                    }

                }




                if (__local_pattern >= __param_pattern_end) {
                    break
                }

                var __ci_expr_logic_13: i32 = 0

                if (__param_escape != 0) {
                    (__ci_expr_logic_13 = (if __local_c == __param_escape: 1 else: 0))
                }

                if __ci_expr_logic_13 {
                    (__local_char_start = __local_pattern)

                    var __ci_expr_old_14: *const u8 = __local_pattern

                    (__local_pattern = __local_pattern + 1)

                    (__local_c = (((*__ci_expr_old_14) as u32)))


                    var __ci_expr_logic_15: i32 = 0

                    if __param_utf {
                        (__ci_expr_logic_15 = (if __local_c >= 192: 1 else: 0))
                    }

                    if __ci_expr_logic_15 {
                        if (((__local_c as u32) & (32 as u32)) == 0) {
                            var __ci_expr_old_16: *const u8 = __local_pattern

                            (__local_pattern = __local_pattern + 1)

                            (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_16) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        } else {
                            if (((__local_c as u32) & (16 as u32)) == 0) {
                                (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_pattern = __local_pattern + ((2 as isize) as usize))

                            } else {
                                if (((__local_c as u32) & (8 as u32)) == 0) {
                                    (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_pattern = __local_pattern + ((3 as isize) as usize))

                                } else {
                                    if (((__local_c as u32) & (4 as u32)) == 0) {
                                        (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                        (__local_pattern = __local_pattern + ((4 as isize) as usize))

                                    } else {
                                        (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                        (__local_pattern = __local_pattern + ((5 as isize) as usize))

                                    }
                                }
                            }
                        }

                    }




                } else {
                    var __ci_expr_logic_17: i32 = 0

                    if (__local_c == 91) {
                        (__ci_expr_logic_17 = (if (*__local_pattern) == 58: 1 else: 0))
                    }

                    if __ci_expr_logic_17 {
                        ((*__param_from) = __local_pattern)

                        return -64

                    }

                }


                if (__local_prev_c > __local_c) {
                    ((*__param_from) = __local_pattern)

                    return -64

                }

                var __ci_expr_logic_18: i32 = 0

                if (__local_prev_c < __param_separator) {
                    (__ci_expr_logic_18 = (if __param_separator < __local_c: 1 else: 0))
                }

                if __ci_expr_logic_18 {
                    (__local_separator_seen = ((1 as i32)))
                }


                (__local_has_prev_c = ((0 as i32)))

                (__local_prev_c = ((0 as u32)))

            } else {
                var __ci_expr_logic_19: i32 = 0

                if (__param_escape != 0) {
                    (__ci_expr_logic_19 = (if __local_c == __param_escape: 1 else: 0))
                }

                if __ci_expr_logic_19 {
                    (__local_char_start = __local_pattern)

                    var __ci_expr_old_20: *const u8 = __local_pattern

                    (__local_pattern = __local_pattern + 1)

                    (__local_c = (((*__ci_expr_old_20) as u32)))


                    var __ci_expr_logic_21: i32 = 0

                    if __param_utf {
                        (__ci_expr_logic_21 = (if __local_c >= 192: 1 else: 0))
                    }

                    if __ci_expr_logic_21 {
                        if (((__local_c as u32) & (32 as u32)) == 0) {
                            var __ci_expr_old_22: *const u8 = __local_pattern

                            (__local_pattern = __local_pattern + 1)

                            (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_22) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        } else {
                            if (((__local_c as u32) & (16 as u32)) == 0) {
                                (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_pattern = __local_pattern + ((2 as isize) as usize))

                            } else {
                                if (((__local_c as u32) & (8 as u32)) == 0) {
                                    (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                    (__local_pattern = __local_pattern + ((3 as isize) as usize))

                                } else {
                                    if (((__local_c as u32) & (4 as u32)) == 0) {
                                        (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                        (__local_pattern = __local_pattern + ((4 as isize) as usize))

                                    } else {
                                        (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_pattern) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_pattern[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_pattern[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_pattern[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_pattern[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                        (__local_pattern = __local_pattern + ((5 as isize) as usize))

                                    }
                                }
                            }
                        }

                    }




                    if (__local_pattern >= __param_pattern_end) {
                        break
                    }

                }


                (__local_has_prev_c = ((1 as i32)))

                (__local_prev_c = __local_c)

            }

        }


        var __ci_expr_logic_25: i32

        var __ci_expr_logic_24: i32

        var __ci_expr_logic_23: i32

        if (__local_c == 91) {
            (__ci_expr_logic_23 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_23 = (if __local_c == 93: 1 else: 0))
        }

        if __ci_expr_logic_23 {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if __local_c == 92: 1 else: 0))
        }

        if __ci_expr_logic_24 {
            (__ci_expr_logic_25 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_25 = (if __local_c == 45: 1 else: 0))
        }

        if __ci_expr_logic_25 {
            convert_glob_write(__param_out, (92 as u8))
        }


        if (__local_c == __param_separator) {
            (__local_separator_seen = ((1 as i32)))
        }

        loop {
            var __ci_expr_old_26: *const u8 = __local_char_start

            (__local_char_start = __local_char_start + 1)

            convert_glob_write(__param_out, (*__ci_expr_old_26))

            if not ((__local_char_start < __local_pattern)) {
                break
            }
        }

    }

    ((*__param_from) = __local_pattern)

    return 106

}

unsafe fn convert_glob_print_commit(__param_out: *mut pcre2_output_context) {
    ((*__param_out).out_str[0] = ((40 as u8)))

    ((*__param_out).out_str[1] = ((42 as u8)))

    ((*__param_out).out_str[2] = ((67 as u8)))

    ((*__param_out).out_str[3] = ((79 as u8)))

    ((*__param_out).out_str[4] = ((77 as u8)))

    ((*__param_out).out_str[5] = ((77 as u8)))

    ((*__param_out).out_str[6] = ((73 as u8)))

    ((*__param_out).out_str[7] = ((84 as u8)))

    convert_glob_write_str(__param_out, (8 as u64))

    convert_glob_write(__param_out, (41 as u8))

}

// contract: unproved:1:read only,stored-unknown:4,unproved:6:out-parameter written conditionally,unproved:8:read only — stores an argument; ownership not modeled
unsafe fn convert_glob(__param_options: u32, __param_pattern: *const u8, __param_plength: u64, __param_utf: i32, __param_use_buffer: *mut u8, __param_use_length: u64, __param_bufflenptr: *mut u64, __param_dummyrun: i32, __param_ccontext: *mut pcre2_real_convert_context_8) -> i32 {
    var __local_pattern = __param_pattern
    var __local_out: pcre2_output_context

    var __local_pattern_start: *const u8 = __local_pattern

    var __local_pattern_end: *const u8 = (__local_pattern + (__param_plength as usize))

    var __local_separator: u8 = (((*__param_ccontext).glob_separator as u8))

    var __local_escape: u8 = (((*__param_ccontext).glob_escape as u8))

    var __local_c: u8

    var __local_no_wildsep: i32 = (((if ((__param_options as u32) & (48 as u32)) != 0: 1 else: 0) as i32))

    var __local_no_starstar: i32 = (((if ((__param_options as u32) & (80 as u32)) != 0: 1 else: 0) as i32))

    var __local_in_atomic: i32 = ((0 as i32))

    var __local_after_starstar: i32 = ((0 as i32))

    var __local_no_slash_z: i32 = ((0 as i32))

    var __local_with_escape: i32

    var __local_is_start: i32

    var __local_after_separator: i32


    var __local_result: i32 = ((0 as i32))


    var __ci_expr_logic_1: i32 = 0

    if __param_utf {
        var __ci_expr_logic_0: i32

        if (__local_separator >= 128) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if __local_escape >= 128: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0: 1 else: 0))

    }

    if __ci_expr_logic_1 {
        ((*__param_bufflenptr) = ((0 as u64)))

        return -64

    }


    (__local_with_escape = (((if strchr(pcre2_escaped_literals, (__local_separator as i32)) != null: 1 else: 0) as i32)))

    (__local_out.output = __param_use_buffer)

    (__local_out.output_end = (((__param_use_buffer + (__param_use_length as usize)) as *const u8)))

    (__local_out.output_size = ((0 as u64)))

    (__local_out.out_str[0] = ((40 as u8)))

    (__local_out.out_str[1] = ((63 as u8)))

    (__local_out.out_str[2] = ((115 as u8)))

    (__local_out.out_str[3] = ((41 as u8)))

    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (4 as u64))

    (__local_is_start = ((1 as i32)))

    var __ci_expr_logic_2: i32 = 0

    if (__local_pattern < __local_pattern_end) {
        (__ci_expr_logic_2 = (if (__local_pattern[0]) == 42: 1 else: 0))
    }

    if __ci_expr_logic_2 {
        if __local_no_wildsep {
            (__local_is_start = ((0 as i32)))
        } else {
            var __ci_expr_logic_4: i32 = 0

            var __ci_expr_logic_3: i32 = 0

            if (not __local_no_starstar) {
                (__ci_expr_logic_3 = (if (__local_pattern + ((1 as isize) as usize)) < __local_pattern_end: 1 else: 0))
            }

            if __ci_expr_logic_3 {
                (__ci_expr_logic_4 = (if (__local_pattern[1]) == 42: 1 else: 0))
            }

            if __ci_expr_logic_4 {
                (__local_is_start = ((0 as i32)))
            }

        }

    }


    if __local_is_start {
        (__local_out.out_str[0] = ((92 as u8)))

        (__local_out.out_str[1] = ((65 as u8)))

        convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (2 as u64))

    }

    while (__local_pattern < __local_pattern_end) {
        var __ci_expr_old_5: *const u8 = __local_pattern

        (__local_pattern = __local_pattern + 1)

        (__local_c = (*__ci_expr_old_5))


        if (__local_c == 42) {
            (__local_is_start = (((if __local_pattern == (__local_pattern_start + ((1 as isize) as usize)): 1 else: 0) as i32)))

            if __local_in_atomic {
                convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (41 as u8))

                (__local_in_atomic = ((0 as i32)))

            }

            var __ci_expr_logic_7: i32 = 0

            var __ci_expr_logic_6: i32 = 0

            if (not __local_no_starstar) {
                (__ci_expr_logic_6 = (if __local_pattern < __local_pattern_end: 1 else: 0))
            }

            if __ci_expr_logic_6 {
                (__ci_expr_logic_7 = (if (*__local_pattern) == 42: 1 else: 0))
            }

            if __ci_expr_logic_7 {
                var __ci_expr_logic_8: i32

                if __local_is_start {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_8 = (if (__local_pattern[-2]) == __local_separator: 1 else: 0))
                }

                (__local_after_separator = __ci_expr_logic_8)


                loop {
                    (__local_pattern = __local_pattern + 1)
                    var __ci_expr_logic_9: i32 = 0

                    if (__local_pattern < __local_pattern_end) {
                        (__ci_expr_logic_9 = (if (*__local_pattern) == 42: 1 else: 0))
                    }

                    if not (__ci_expr_logic_9) {
                        break
                    }
                }

                if (__local_pattern >= __local_pattern_end) {
                    (__local_no_slash_z = ((1 as i32)))

                    break

                }

                (__local_after_starstar = ((1 as i32)))

                var __ci_expr_logic_13: i32 = 0

                var __ci_expr_logic_12: i32 = 0

                var __ci_expr_logic_11: i32 = 0

                var __ci_expr_logic_10: i32 = 0

                if __local_after_separator {
                    (__ci_expr_logic_10 = (if __local_escape != 0: 1 else: 0))
                }

                if __ci_expr_logic_10 {
                    (__ci_expr_logic_11 = (if (*__local_pattern) == __local_escape: 1 else: 0))
                }

                if __ci_expr_logic_11 {
                    (__ci_expr_logic_12 = (if (__local_pattern + ((1 as isize) as usize)) < __local_pattern_end: 1 else: 0))
                }

                if __ci_expr_logic_12 {
                    (__ci_expr_logic_13 = (if (__local_pattern[1]) == __local_separator: 1 else: 0))
                }

                if __ci_expr_logic_13 {
                    (__local_pattern = __local_pattern + 1)
                }


                if __local_is_start {
                    if ((*__local_pattern) != __local_separator) {
                        continue
                    }

                    (__local_out.out_str[0] = ((40 as u8)))

                    (__local_out.out_str[1] = ((63 as u8)))

                    (__local_out.out_str[2] = ((58 as u8)))

                    (__local_out.out_str[3] = ((92 as u8)))

                    (__local_out.out_str[4] = ((65 as u8)))

                    (__local_out.out_str[5] = ((124 as u8)))

                    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (6 as u64))

                    convert_glob_print_separator((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)

                    convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (41 as u8))

                    (__local_pattern = __local_pattern + 1)

                    continue

                }

                convert_glob_print_commit((&raw mut __local_out as *mut pcre2_output_context))

                var __ci_expr_logic_14: i32

                if (not __local_after_separator) {
                    (__ci_expr_logic_14 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_14 = (if (*__local_pattern) != __local_separator: 1 else: 0))
                }

                if __ci_expr_logic_14 {
                    (__local_out.out_str[0] = ((46 as u8)))

                    (__local_out.out_str[1] = ((42 as u8)))

                    (__local_out.out_str[2] = ((63 as u8)))

                    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (3 as u64))

                    continue

                }


                (__local_out.out_str[0] = ((40 as u8)))

                (__local_out.out_str[1] = ((63 as u8)))

                (__local_out.out_str[2] = ((58 as u8)))

                (__local_out.out_str[3] = ((46 as u8)))

                (__local_out.out_str[4] = ((42 as u8)))

                (__local_out.out_str[5] = ((63 as u8)))

                convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (6 as u64))

                convert_glob_print_separator((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)

                (__local_out.out_str[0] = ((41 as u8)))

                (__local_out.out_str[1] = ((63 as u8)))

                (__local_out.out_str[2] = ((63 as u8)))

                convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (3 as u64))

                (__local_pattern = __local_pattern + 1)

                continue

            }


            var __ci_expr_logic_15: i32 = 0

            if (__local_pattern < __local_pattern_end) {
                (__ci_expr_logic_15 = (if (*__local_pattern) == 42: 1 else: 0))
            }

            if __ci_expr_logic_15 {
                loop {
                    (__local_pattern = __local_pattern + 1)
                    var __ci_expr_logic_16: i32 = 0

                    if (__local_pattern < __local_pattern_end) {
                        (__ci_expr_logic_16 = (if (*__local_pattern) == 42: 1 else: 0))
                    }

                    if not (__ci_expr_logic_16) {
                        break
                    }
                }

            }


            if __local_no_wildsep {
                if (__local_pattern >= __local_pattern_end) {
                    (__local_no_slash_z = ((1 as i32)))

                    break

                }

                if __local_is_start {
                    continue
                }

            }

            if (not __local_is_start) {
                if __local_after_starstar {
                    (__local_out.out_str[0] = ((40 as u8)))

                    (__local_out.out_str[1] = ((63 as u8)))

                    (__local_out.out_str[2] = ((62 as u8)))

                    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (3 as u64))

                    (__local_in_atomic = ((1 as i32)))

                } else {
                    convert_glob_print_commit((&raw mut __local_out as *mut pcre2_output_context))
                }

            }

            if __local_no_wildsep {
                convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (46 as u8))
            } else {
                convert_glob_print_wildcard((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)
            }

            (__local_out.out_str[0] = ((42 as u8)))

            (__local_out.out_str[1] = ((63 as u8)))

            if (__local_pattern >= __local_pattern_end) {
                (__local_out.out_str[1] = ((43 as u8)))
            }

            convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (2 as u64))

            continue

        }

        if (__local_c == 63) {
            if __local_no_wildsep {
                convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (46 as u8))
            } else {
                convert_glob_print_wildcard((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)
            }

            continue

        }

        if (__local_c == 91) {
            (__local_result = ((convert_glob_parse_range((&raw mut __local_pattern as *mut *const u8), __local_pattern_end, (&raw mut __local_out as *mut pcre2_output_context), __param_utf, __local_separator, __local_with_escape, __local_escape, __local_no_wildsep) as i32)))

            if (__local_result != 0) {
                break
            }

            continue

        }

        var __ci_expr_logic_17: i32 = 0

        if (__local_escape != 0) {
            (__ci_expr_logic_17 = (if __local_c == __local_escape: 1 else: 0))
        }

        if __ci_expr_logic_17 {
            if (__local_pattern >= __local_pattern_end) {
                (__local_result = ((-64 as i32)))

                break

            }

            var __ci_expr_old_18: *const u8 = __local_pattern

            (__local_pattern = __local_pattern + 1)

            (__local_c = (*__ci_expr_old_18))


        }


        var __ci_expr_logic_19: i32 = 0

        if (__local_c < 255) {
            (__ci_expr_logic_19 = (if strchr(pcre2_escaped_literals, (__local_c as i32)) != null: 1 else: 0))
        }

        if __ci_expr_logic_19 {
            convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (92 as u8))
        }


        convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), __local_c)

    }

    if (__local_result == 0) {
        if (not __local_no_slash_z) {
            (__local_out.out_str[0] = ((92 as u8)))

            (__local_out.out_str[1] = ((122 as u8)))

            convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), (2 as u64))

        }

        if __local_in_atomic {
            convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (41 as u8))
        }

        convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), (0 as u8))

        var __ci_expr_logic_20: i32 = 0

        if (not __param_dummyrun) {
            (__ci_expr_logic_20 = (if (*(&raw const __local_out as *const pcre2_output_context)).output_size != (((((((*(&raw const __local_out as *const pcre2_output_context)).output as usize) -% (__param_use_buffer as usize)) as i64) / (sizeof[u8]() as i64)) as u64)): 1 else: 0))
        }

        if __ci_expr_logic_20 {
            (__local_result = ((-48 as i32)))
        }


    }

    if (__local_result != 0) {
        ((*__param_bufflenptr) = ((((((__local_pattern as usize) -% (__local_pattern_start as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))

        return __local_result

    }

    ((*__param_bufflenptr) = (((((*(&raw const __local_out as *const pcre2_output_context)).output_size as u64) -% (1 as u64)) as u64)))

    return 0

}

var pcre2_escaped_literals: *const c_char = c"\x5c\x3f\x2a\x2b\x7c\x2e\x5e\x24\x7b\x7d\x5b\x5d\x28\x29".ptr as *const c_char
var posix_meta_escapes: *const c_char = c"\x28\x29\x7b\x7d\x31\x32\x33\x34\x35\x36\x37\x38\x39".ptr as *const c_char
var posix_classes: *const c_char = c"\x61\x6c\x70\x68\x61\x3a\x6c\x6f\x77\x65\x72\x3a\x75\x70\x70\x65\x72\x3a\x61\x6c\x6e\x75\x6d\x3a\x61\x73\x63\x69\x69\x3a\x62\x6c\x61\x6e\x6b\x3a\x63\x6e\x74\x72\x6c\x3a\x64\x69\x67\x69\x74\x3a\x67\x72\x61\x70\x68\x3a\x70\x72\x69\x6e\x74\x3a\x70\x75\x6e\x63\x74\x3a\x73\x70\x61\x63\x65\x3a\x77\x6f\x72\x64\x3a\x78\x64\x69\x67\x69\x74\x3a".ptr as *const c_char
