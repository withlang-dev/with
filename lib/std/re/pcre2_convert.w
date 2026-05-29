// Migrated from PCRE2
use std.re.defs

fn pcre2_pattern_convert_8(__param_pattern: *const u8, __param_plength: c_ulong, __param_options: c_uint, __param_buffptr: *mut *mut u8, __param_bufflenptr: *mut c_ulong, __param_ccontext: *mut pcre2_real_convert_context_8) -> c_int {
    var __local_pattern = __param_pattern
    var __local_plength = __param_plength
    var __local_ccontext = __param_ccontext
    var __local_rc: c_int

    var __local_null_str: [1]u8 = [205]

    var __local_dummy_buffer: [100]u8

    var __local_use_buffer: *mut u8 = ((&raw const __local_dummy_buffer[0] as *mut u8))

    var __local_use_length: c_ulong = 100

    var __local_utf: c_int = (if ((__param_options as c_uint) & (1 as c_uint)) != 0: 1 else: 0)

    var __local_pattype: c_uint = ((__param_options as c_uint) & (((((16 as c_uint) | (4 as c_uint)) as c_uint) | (8 as c_uint)) as c_uint))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_pattern == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_plength == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_pattern = (&__local_null_str[0] as *mut u8))
    }


    var __ci_expr_logic_1: c_int

    if ((if __local_pattern == null: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_bufflenptr == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        if ((if __param_bufflenptr != null: 1 else: 0) != 0) {
            ((unsafe *__param_bufflenptr) = 0)
        }

        return -51

    }


    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if ((__param_options as c_uint) & ((~((((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (48 as c_uint)) as c_uint) | (80 as c_uint)) as c_uint) | (((((16 as c_uint) | (4 as c_uint)) as c_uint) | (8 as c_uint)) as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if ((__local_pattype as c_uint) & ((((~__local_pattype) as c_uint) +% (1 as c_uint)) as c_uint)) != __local_pattype: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if __local_pattype == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        ((unsafe *__param_bufflenptr) = 0)

        return -34

    }


    if ((if __local_plength == (~(0 as c_ulong)): 1 else: 0) != 0) {
        (__local_plength = _pcre2_strlen_8(__local_pattern))
    }

    if ((if __local_ccontext == null: 1 else: 0) != 0) {
        (__local_ccontext = ((&raw mut _pcre2_default_convert_context_8 as *mut pcre2_real_convert_context_8)))
    }

    var __ci_expr_logic_4: c_int = 0

    if (__local_utf != 0) {
        (__ci_expr_logic_4 = (if (if ((__param_options as c_uint) & (2 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        var __local_erroroffset: c_ulong

        (__local_rc = _pcre2_valid_utf_8(__local_pattern, __local_plength, (&raw mut __local_erroroffset as *mut c_ulong)))

        if ((if __local_rc != 0: 1 else: 0) != 0) {
            ((unsafe *__param_bufflenptr) = __local_erroroffset)

            return __local_rc

        }

    }


    var __ci_expr_logic_5: c_int = 0

    if ((if __param_buffptr != null: 1 else: 0) != 0) {
        (__ci_expr_logic_5 = (if (if (unsafe *__param_buffptr) != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__local_use_buffer = (unsafe *__param_buffptr))

        (__local_use_length = (unsafe *__param_bufflenptr))

    }


    var __local_i: c_int = 0

    while ((if __local_i < 2: 1 else: 0) != 0) {
        var __local_allocated: *mut u8

        var __local_dummyrun: c_int = with 0 as __ci_expr_seq_116 {
            var __ci_expr_logic_6: c_int
            if ((if __param_buffptr == null: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if (unsafe *__param_buffptr) == null: 1 else: 0) != 0: 1 else: 0))
            }
            __ci_expr_logic_6
        }

        while true {
            match __local_pattype {
                16 => {
                    (__local_rc = convert_glob(((__param_options as c_uint) & ((~16) as c_uint)), __local_pattern, __local_plength, __local_utf, __local_use_buffer, __local_use_length, __param_bufflenptr, __local_dummyrun, __local_ccontext))
                },
                4 => {
                    (__local_rc = convert_posix(__local_pattype, __local_pattern, __local_plength, __local_utf, __local_use_buffer, __local_use_length, __param_bufflenptr, __local_dummyrun, __local_ccontext))
                },
                8 => {
                    (__local_rc = convert_posix(__local_pattype, __local_pattern, __local_plength, __local_utf, __local_use_buffer, __local_use_length, __param_bufflenptr, __local_dummyrun, __local_ccontext))
                },
                _ => {
                    do {
                        0
                    } while (0 != 0)

                    ((unsafe *__param_bufflenptr) = 0)

                    return -44

                },
            }

            break

        }

        var __ci_expr_logic_9: c_int

        var __ci_expr_logic_8: c_int

        if ((if __local_rc != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if (if __param_buffptr == null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_9 = (if (if (unsafe *__param_buffptr) != null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_9 != 0) {
            return __local_rc
        }


        (__local_allocated = ((_pcre2_memctl_malloc_8(((sizeof[pcre2_memctl]() as c_ulong) +% ((((((unsafe *__param_bufflenptr) as c_ulong) +% (1 as c_ulong)) as c_ulong) *% (8 as c_ulong)) as c_ulong)), (__local_ccontext as *mut pcre2_memctl)) as *mut u8)))

        if ((if __local_allocated == null: 1 else: 0) != 0) {
            ((unsafe *__param_bufflenptr) = 0)

            return -48

        }

        ((unsafe *__param_buffptr) = ((((__local_allocated as *mut c_char) + (sizeof[pcre2_memctl]() as usize)) as *mut u8)))

        (__local_use_buffer = (unsafe *__param_buffptr))

        (__local_use_length = (((unsafe *__param_bufflenptr) as c_ulong) +% (1 as c_ulong)))


        (__local_i = __local_i + 1)

    }


    do {
        0
    } while (0 != 0)

    ((unsafe *__param_bufflenptr) = 0)

    return -44

}

fn pcre2_converted_pattern_free_8(__param_converted: *mut u8) {
    if ((if __param_converted != null: 1 else: 0) != 0) {
        var __local_memctl: *mut pcre2_memctl = ((((__param_converted as *mut c_char) - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        __local_memctl.free(__local_memctl, __local_memctl.memory_data)

    }

}

fn convert_posix(__param_pattype: c_uint, __param_pattern: *const u8, __param_plength: c_ulong, __param_utf: c_int, __param_use_buffer: *mut u8, __param_use_length: c_ulong, __param_bufflenptr: *mut c_ulong, __param_dummyrun: c_int, __param_ccontext: *mut pcre2_real_convert_context_8) -> c_int {
    var __local_plength = __param_plength
    var __local_posix__goto_154_12: *const u8 = null

    var __local_p__goto_155_14: *mut u8 = null

    var __local_pp__goto_156_14: *mut u8 = null

    var __local_endp__goto_157_14: *mut u8 = null

    var __local_convlength__goto_158_12: c_ulong = 0

    var __local_bracount__goto_160_10: c_uint = 0

    var __local_posix_state__goto_161_10: c_uint = 0

    var __local_lastspecial__goto_162_10: c_uint = 0

    var __local_extended__goto_163_6: c_int = 0

    var __local_nextisliteral__goto_164_6: c_int = 0

    var __local_s__goto_172_1: *const i8 = null

    var __local_c__goto_178_12: c_uint = 0

    var __local_sc__goto_178_15: c_uint = 0

    var __local_clength__goto_179_7: c_int = 0

    var __local_s__goto_208_7: *const i8 = null

    var __local_s__goto_224_11: *const i8 = null

    var __local_s__goto_241_32: *const i8 = null

    var __local_s__goto_253_5: *const i8 = null

    var __local_s__goto_291_9: *const i8 = null

    var __local_s__goto_297_9: *const i8 = null

    var __local_s__goto_308_51: *const i8 = null

    var __local_s__goto_367_7: *const i8 = null

    var __ci_expr_old_0: *mut u8 = null

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_ternary_2: c_uint = 0

    var __ci_expr_old_3: *mut u8 = null

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_old_7: *mut u8 = null

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_old_9: *mut u8 = null

    var __ci_expr_old_10: *mut u8 = null

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_old_12: *mut u8 = null

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_old_15: *mut u8 = null

    var __ci_expr_old_16: *mut u8 = null

    var __ci_expr_old_17: *const u8 = null

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_old_19: *mut u8 = null

    var __ci_expr_logic_21: c_int = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_old_24: *mut u8 = null

    var __ci_expr_old_25: *mut u8 = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_posix__goto_154_12 = __param_pattern)
        (__local_p__goto_155_14 = __param_use_buffer)
        (__local_pp__goto_156_14 = __local_p__goto_155_14)
        (__local_endp__goto_157_14 = (__local_p__goto_155_14 + (__param_use_length as usize)) - ((1 as isize) as usize))
        (__local_convlength__goto_158_12 = 0)
        (__local_bracount__goto_160_10 = 0)
        (__local_posix_state__goto_161_10 = 0)
        (__local_lastspecial__goto_162_10 = 0)
        (__local_extended__goto_163_6 = (if ((__param_pattype as c_uint) & (8 as c_uint)) != 0: 1 else: 0))
        (__local_nextisliteral__goto_164_6 = 0)
        __param_utf
        __param_ccontext
        ((unsafe *__param_bufflenptr) = __local_plength)
        (__local_s__goto_172_1 = (("\x28\x2a\x4e\x55\x4c\x29" as *const c_char)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((if (unsafe *__local_s__goto_172_1) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        ((unsafe *__ci_expr_old_0) = (unsafe *__local_s__goto_172_1))
        goto '__ci_bb_3
    }

    '__ci_bb_7 {
        if ((if __local_plength > 0: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        (__local_clength__goto_179_7 = 1)
        (__local_convlength__goto_158_12 = __local_convlength__goto_158_12 + (((__local_p__goto_155_14 as usize) -% (__local_pp__goto_156_14 as usize)) / sizeof[u8]()))
        if (__param_dummyrun != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_9 {
        if ((if __local_posix_state__goto_161_10 >= 3: 1 else: 0) != 0) {
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
        (__local_c__goto_178_12 = (unsafe *__local_posix__goto_154_12))
        (__ci_expr_logic_1 = 0)
        if (__param_utf != 0) {
            (__ci_expr_logic_1 = (if (if __local_c__goto_178_12 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_12 {
        if ((if ((__local_c__goto_178_12 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + ((__local_clength__goto_179_7 as isize) as usize))
        (__local_plength = __local_plength - __local_clength__goto_179_7)
        (__ci_expr_ternary_2 = 0)
        if (__local_nextisliteral__goto_164_6 != 0) {
            (__ci_expr_ternary_2 = 0)
        } else {
            (__ci_expr_ternary_2 = __local_c__goto_178_12)
        }
        (__local_sc__goto_178_15 = __ci_expr_ternary_2)
        (__local_nextisliteral__goto_164_6 = 0)
        if ((if __local_posix_state__goto_161_10 >= 3: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_14 {
        (__local_c__goto_178_12 = (((((__local_c__goto_178_12 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __local_posix__goto_154_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 1)
        goto '__ci_bb_16
    }

    '__ci_bb_15 {
        if ((if ((__local_c__goto_178_12 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_16 {
        goto '__ci_bb_13
    }

    '__ci_bb_17 {
        (__local_c__goto_178_12 = (((((((__local_c__goto_178_12 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_posix__goto_154_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 2)
        goto '__ci_bb_19
    }

    '__ci_bb_18 {
        if ((if ((__local_c__goto_178_12 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_19 {
        goto '__ci_bb_16
    }

    '__ci_bb_20 {
        (__local_c__goto_178_12 = (((((((((__local_c__goto_178_12 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_posix__goto_154_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 3)
        goto '__ci_bb_22
    }

    '__ci_bb_21 {
        if ((if ((__local_c__goto_178_12 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_22 {
        goto '__ci_bb_19
    }

    '__ci_bb_23 {
        (__local_c__goto_178_12 = (((((((((((__local_c__goto_178_12 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_posix__goto_154_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 4)
        goto '__ci_bb_25
    }

    '__ci_bb_24 {
        (__local_c__goto_178_12 = (((((((((((((__local_c__goto_178_12 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_posix__goto_154_12[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_posix__goto_154_12[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_clength__goto_179_7 = __local_clength__goto_179_7 + 5)
        goto '__ci_bb_25
    }

    '__ci_bb_25 {
        goto '__ci_bb_22
    }

    '__ci_bb_26 {
        if ((if __local_c__goto_178_12 == 93: 1 else: 0) != 0) {
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
        (__local_s__goto_208_7 = (("\x5d" as *const c_char)))
        goto '__ci_bb_32
    }

    '__ci_bb_30 {
        goto '__ci_bb_38
    }

    '__ci_bb_31 {
        goto '__ci_bb_28
    }

    '__ci_bb_32 {
        if ((if (unsafe *__local_s__goto_208_7) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_33 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__local_posix_state__goto_161_10 = 2)
        goto '__ci_bb_31
    }

    '__ci_bb_36 {
        return -48
    }

    '__ci_bb_37 {
        (__ci_expr_old_3 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_3) = (unsafe *__local_s__goto_208_7))
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
        if ((if __local_c__goto_178_12 == 92: 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_40 {
        (__ci_expr_logic_4 = 0)
        if ((if __local_c__goto_178_12 >= 97: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_c__goto_178_12 <= 122: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_41 {
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        (__local_posix_state__goto_161_10 = 3)
        (__ci_expr_logic_6 = 0)
        (__ci_expr_logic_5 = 0)
        if ((if __local_c__goto_178_12 == 58: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_plength > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe *__local_posix__goto_154_12) == 93: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        (__local_s__goto_224_11 = (("\x3a\x5d" as *const c_char)))
        goto '__ci_bb_45
    }

    '__ci_bb_44 {
        goto '__ci_bb_51
    }

    '__ci_bb_45 {
        if ((if (unsafe *__local_s__goto_224_11) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_46 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__local_plength = __local_plength - 1)
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        goto '__ci_bb_7
    }

    '__ci_bb_49 {
        return -48
    }

    '__ci_bb_50 {
        (__ci_expr_old_7 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_7) = (unsafe *__local_s__goto_224_11))
        goto '__ci_bb_47
    }

    '__ci_bb_51 {
        if ((if __local_c__goto_178_12 == 91: 1 else: 0) != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_52 {
        (__local_posix_state__goto_161_10 = 4)
        goto '__ci_bb_53
    }

    '__ci_bb_53 {
        goto '__ci_bb_39
    }

    '__ci_bb_54 {
        if ((if __local_c__goto_178_12 == 58: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_55 {
        (__local_posix_state__goto_161_10 = 5)
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
        (__local_s__goto_241_32 = (("\x5c" as *const c_char)))
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        if ((if (__local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize)) > __local_endp__goto_157_14: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_61 {
        if ((if (unsafe *__local_s__goto_241_32) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_62 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__ci_expr_old_8 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_8) = (unsafe *__local_s__goto_241_32))
        goto '__ci_bb_63
    }

    '__ci_bb_67 {
        return -48
    }

    '__ci_bb_68 {
        with_memcpy((__local_p__goto_155_14 as *i8), ((__local_posix__goto_154_12 - ((__local_clength__goto_179_7 as isize) as usize)) as *i8), ((__local_clength__goto_179_7 * (8 / 8)) as i64))
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
        (__local_s__goto_253_5 = (("\x5b" as *const c_char)))
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        if ((if (unsafe *__local_s__goto_253_5) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_73 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__local_posix_state__goto_161_10 = 3)
        if ((if __local_plength > 0: 1 else: 0) != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_76 {
        return -48
    }

    '__ci_bb_77 {
        (__ci_expr_old_9 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_9) = (unsafe *__local_s__goto_253_5))
        goto '__ci_bb_74
    }

    '__ci_bb_78 {
        if ((if (unsafe *__local_posix__goto_154_12) == 94: 1 else: 0) != 0) {
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
        (__local_plength = __local_plength - 1)
        (__local_s__goto_291_9 = (("\x5e" as *const c_char)))
        goto '__ci_bb_82
    }

    '__ci_bb_81 {
        (__ci_expr_logic_11 = 0)
        if ((if __local_plength > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_11 = (if (if (unsafe *__local_posix__goto_154_12) == 93: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_82 {
        if ((if (unsafe *__local_s__goto_291_9) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_83 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__ci_expr_old_10 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_10) = (unsafe *__local_s__goto_291_9))
        goto '__ci_bb_84
    }

    '__ci_bb_88 {
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        (__local_plength = __local_plength - 1)
        (__local_s__goto_297_9 = (("\x5d" as *const c_char)))
        goto '__ci_bb_90
    }

    '__ci_bb_89 {
        goto '__ci_bb_79
    }

    '__ci_bb_90 {
        if ((if (unsafe *__local_s__goto_297_9) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_91 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__ci_expr_old_12 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_12) = (unsafe *__local_s__goto_297_9))
        goto '__ci_bb_92
    }

    '__ci_bb_96 {
        if ((if __local_plength == 0: 1 else: 0) != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_97 {
        return 101
    }

    '__ci_bb_98 {
        if (__local_extended__goto_163_6 != 0) {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_100
        }
    }

    '__ci_bb_99 {
        (__local_nextisliteral__goto_164_6 = 1)
        goto '__ci_bb_101
    }

    '__ci_bb_100 {
        (__ci_expr_logic_13 = 0)
        if ((if (unsafe *__local_posix__goto_154_12) < 255: 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if (if string_find_char(posix_meta_escapes, (unsafe *__local_posix__goto_154_12)) != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_101 {
        goto '__ci_bb_70
    }

    '__ci_bb_102 {
        (__ci_expr_logic_14 = 0)
        if ((if (unsafe *__local_posix__goto_154_12) >= 48: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if (unsafe *__local_posix__goto_154_12) <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_103 {
        (__local_nextisliteral__goto_164_6 = 1)
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        goto '__ci_bb_101
    }

    '__ci_bb_105 {
        (__local_s__goto_308_51 = (("\x5c" as *const c_char)))
        goto '__ci_bb_107
    }

    '__ci_bb_106 {
        if ((if (__local_p__goto_155_14 + ((1 as isize) as usize)) > __local_endp__goto_157_14: 1 else: 0) != 0) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_107 {
        if ((if (unsafe *__local_s__goto_308_51) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_108 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__ci_expr_old_15 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_15) = (unsafe *__local_s__goto_308_51))
        goto '__ci_bb_109
    }

    '__ci_bb_113 {
        return -48
    }

    '__ci_bb_114 {
        (__ci_expr_old_16 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        (__ci_expr_old_17 = __local_posix__goto_154_12)
        (__local_posix__goto_154_12 = __local_posix__goto_154_12 + 1)
        ((unsafe *__ci_expr_old_16) = (unsafe *__ci_expr_old_17))
        (__local_lastspecial__goto_162_10 = (unsafe *__ci_expr_old_16))
        (__local_plength = __local_plength - 1)
        goto '__ci_bb_104
    }

    '__ci_bb_115 {
        if ((if not (__local_extended__goto_163_6 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_18 = (if (if __local_bracount__goto_160_10 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_116 {
        goto '__ci_bb_118
    }

    '__ci_bb_117 {
        (__local_bracount__goto_160_10 = __local_bracount__goto_160_10 - 1)
        goto '__ci_bb_119
    }

    '__ci_bb_118 {
        (__local_s__goto_367_7 = (("\x5c" as *const c_char)))
        goto '__ci_bb_140
    }

    '__ci_bb_119 {
        (__local_lastspecial__goto_162_10 = __local_c__goto_178_12)
        if ((if (__local_p__goto_155_14 + ((1 as isize) as usize)) > __local_endp__goto_157_14: 1 else: 0) != 0) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_120 {
        (__local_bracount__goto_160_10 = __local_bracount__goto_160_10 + 1)
        goto '__ci_bb_121
    }

    '__ci_bb_121 {
        if ((if not (__local_extended__goto_163_6 != 0): 1 else: 0) != 0) {
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
        (__local_posix_state__goto_161_10 = 2)
        goto '__ci_bb_119
    }

    '__ci_bb_125 {
        return -48
    }

    '__ci_bb_126 {
        (__ci_expr_old_19 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_19) = __local_c__goto_178_12)
        goto '__ci_bb_70
    }

    '__ci_bb_127 {
        if ((if __local_lastspecial__goto_162_10 != 42: 1 else: 0) != 0) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_128 {
        (__ci_expr_logic_21 = 0)
        if ((if not (__local_extended__goto_163_6 != 0): 1 else: 0) != 0) {
            var __ci_expr_logic_20: c_int

            if ((if __local_posix_state__goto_161_10 < 2: 1 else: 0) != 0) {
                (__ci_expr_logic_20 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_20 = (if (if __local_lastspecial__goto_162_10 == 40: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_21 = (if __ci_expr_logic_20 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_21 != 0) {
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
        if (__local_extended__goto_163_6 != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_133 {
        goto '__ci_bb_119
    }

    '__ci_bb_134 {
        if ((if __local_posix_state__goto_161_10 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_22 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_22 = (if (if __local_lastspecial__goto_162_10 == 40: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_135 {
        (__local_posix_state__goto_161_10 = 1)
        goto '__ci_bb_119
    }

    '__ci_bb_136 {
        goto '__ci_bb_137
    }

    '__ci_bb_137 {
        (__ci_expr_logic_23 = 0)
        if ((if __local_c__goto_178_12 < 255: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if (if string_find_char(pcre2_escaped_literals, __local_c__goto_178_12) != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_138 {
        goto '__ci_bb_118
    }

    '__ci_bb_139 {
        (__local_lastspecial__goto_162_10 = 255)
        if ((if (__local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize)) > __local_endp__goto_157_14: 1 else: 0) != 0) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_140 {
        if ((if (unsafe *__local_s__goto_367_7) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_141 {
        if ((if __local_p__goto_155_14 >= __local_endp__goto_157_14: 1 else: 0) != 0) {
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
        (__ci_expr_old_24 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_24) = (unsafe *__local_s__goto_367_7))
        goto '__ci_bb_142
    }

    '__ci_bb_146 {
        return -48
    }

    '__ci_bb_147 {
        with_memcpy((__local_p__goto_155_14 as *i8), ((__local_posix__goto_154_12 - ((__local_clength__goto_179_7 as isize) as usize)) as *i8), ((__local_clength__goto_179_7 * (8 / 8)) as i64))
        (__local_p__goto_155_14 = __local_p__goto_155_14 + ((__local_clength__goto_179_7 as isize) as usize))
        (__local_posix_state__goto_161_10 = 2)
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
        (__local_convlength__goto_158_12 = __local_convlength__goto_158_12 + (((__local_p__goto_155_14 as usize) -% (__local_pp__goto_156_14 as usize)) / sizeof[u8]()))
        ((unsafe *__param_bufflenptr) = __local_convlength__goto_158_12)
        (__ci_expr_old_25 = __local_p__goto_155_14)
        (__local_p__goto_155_14 = __local_p__goto_155_14 + 1)
        ((unsafe *__ci_expr_old_25) = 0)
        return 0
    }

}

fn convert_glob_write(__param_out: *mut pcre2_output_context, __param_chr: u8) {
    ((unsafe *__param_out).output_size = __param_out.output_size + 1)

    if ((if __param_out.output < __param_out.output_end: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = __param_out.output

        ((unsafe *__param_out).output = __param_out.output + 1)

        ((unsafe *__ci_expr_old_0) = __param_chr)

    }

}

fn convert_glob_write_str(__param_out: *mut pcre2_output_context, __param_length: c_ulong) {
    var __local_length = __param_length
    var __local_out_str: *mut u8 = ((&raw const (unsafe *__param_out).out_str[0] as *mut u8))

    var __local_output: *mut u8 = __param_out.output

    var __local_output_end: *const u8 = __param_out.output_end

    var __local_output_size: c_ulong = __param_out.output_size

    do {
        (__local_output_size = __local_output_size + 1)

        if ((if __local_output < __local_output_end: 1 else: 0) != 0) {
            var __ci_expr_old_0: *mut u8 = __local_output

            (__local_output = __local_output + 1)

            var __ci_expr_old_1: *mut u8 = __local_out_str

            (__local_out_str = __local_out_str + 1)

            ((unsafe *__ci_expr_old_0) = (unsafe *__ci_expr_old_1))

        }

    } while { (__local_length = __local_length - 1); ((if __local_length != 0: 1 else: 0) != 0) }

    ((unsafe *__param_out).output = __local_output)

    ((unsafe *__param_out).output_size = __local_output_size)

}

fn convert_glob_print_separator(__param_out: *mut pcre2_output_context, __param_separator: u8, __param_with_escape: c_int) {
    if (__param_with_escape != 0) {
        convert_glob_write(__param_out, 92)
    }

    convert_glob_write(__param_out, __param_separator)

}

fn convert_glob_print_wildcard(__param_out: *mut pcre2_output_context, __param_separator: u8, __param_with_escape: c_int) {
    ((unsafe *__param_out).out_str[0] = 91)

    ((unsafe *__param_out).out_str[1] = 94)

    convert_glob_write_str(__param_out, 2)

    convert_glob_print_separator(__param_out, __param_separator, __param_with_escape)

    convert_glob_write(__param_out, 93)

}

fn convert_glob_parse_class(__param_from: *mut *const u8, __param_pattern_end: *const u8, __param_out: *mut pcre2_output_context) -> c_int {
    var __local_start: *const u8 = ((unsafe *__param_from) + ((1 as isize) as usize))

    var __local_pattern: *const u8 = __local_start

    var __local_class_ptr: *const c_char

    var __local_c: u8

    var __local_class_index: c_int

    while (1 != 0) {
        if ((if __local_pattern >= __param_pattern_end: 1 else: 0) != 0) {
            return 0
        }

        var __ci_expr_old_0: *const u8 = __local_pattern

        (__local_pattern = __local_pattern + 1)

        (__local_c = (unsafe *__ci_expr_old_0))


        var __ci_expr_logic_1: c_int

        if ((if __local_c < 97: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_c > 122: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            break
        }


    }

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if __local_c != 58: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __local_pattern >= __param_pattern_end: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (unsafe *__local_pattern) != 93: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return 0
    }


    (__local_class_ptr = ((posix_classes as *const c_char)))

    (__local_class_index = 1)

    while (1 != 0) {
        if ((if (unsafe *__local_class_ptr) == 0: 1 else: 0) != 0) {
            return 0
        }

        (__local_pattern = __local_start)

        while ((if (unsafe *__local_pattern) == (((unsafe *__local_class_ptr) as u8)): 1 else: 0) != 0) {
            if ((if (unsafe *__local_pattern) == 58: 1 else: 0) != 0) {
                (__local_pattern = __local_pattern + ((2 as isize) as usize))

                (__local_start = __local_start - ((2 as isize) as usize))

                do {
                    var __ci_expr_old_4: *const u8 = __local_start

                    (__local_start = __local_start + 1)

                    convert_glob_write(__param_out, (unsafe *__ci_expr_old_4))

                } while ((if __local_start < __local_pattern: 1 else: 0) != 0)

                ((unsafe *__param_from) = __local_pattern)

                return __local_class_index

            }

            (__local_pattern = __local_pattern + 1)

            (__local_class_ptr = __local_class_ptr + 1)

        }

        while ((if (unsafe *__local_class_ptr) != 58: 1 else: 0) != 0) {
            (__local_class_ptr = __local_class_ptr + 1)
        }

        (__local_class_ptr = __local_class_ptr + 1)

        (__local_class_index = __local_class_index + 1)

    }

}

fn convert_glob_char_in_class(__param_class_index: c_int, __param_c: u8) -> c_int {
    var __local_cbits: *const u8 = ((&_pcre2_default_tables_8[0] as *const u8) + ((512 as isize) as usize))

    var __local_cbit: c_int

    while true {
        match __param_class_index {
            1 => {
                if ((if __param_c == 95: 1 else: 0) != 0) {
                    return 0
                }

                if ((if ((((unsafe (__local_cbits + ((64 as isize) as usize))[((__param_c as c_int) / 8)]) as c_int) as c_uint) & (((1 as c_uint) << (((__param_c as c_int) & 7) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                    return 0
                }

                (__local_cbit = 160)

            },
            2 => {
                (__local_cbit = 128)
            },
            3 => {
                (__local_cbit = 96)
            },
            4 => {
                if ((if __param_c == 95: 1 else: 0) != 0) {
                    return 0
                }

                (__local_cbit = 160)

            },
            5 => {
                if ((if ((((unsafe (__local_cbits + ((288 as isize) as usize))[((__param_c as c_int) / 8)]) as c_int) as c_uint) & (((1 as c_uint) << (((__param_c as c_int) & 7) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                    return 1
                }

                (__local_cbit = 224)

            },
            6 => {
                var __ci_expr_logic_2: c_int

                var __ci_expr_logic_1: c_int

                var __ci_expr_logic_0: c_int

                if ((if __param_c == 10: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_0 = (if (if __param_c == 11: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if __param_c == 12: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (if __param_c == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    return 0
                }


                (__local_cbit = 0)

            },
            7 => {
                (__local_cbit = 288)
            },
            8 => {
                (__local_cbit = 64)
            },
            9 => {
                (__local_cbit = 192)
            },
            10 => {
                (__local_cbit = 224)
            },
            11 => {
                (__local_cbit = 256)
            },
            12 => {
                (__local_cbit = 0)
            },
            13 => {
                (__local_cbit = 160)
            },
            14 => {
                (__local_cbit = 32)
            },
            _ => {
                return 0
            },
        }

        break

    }

    return (if ((((unsafe (__local_cbits + ((__local_cbit as isize) as usize))[((__param_c as c_int) / 8)]) as c_int) as c_uint) & (((1 as c_uint) << (((__param_c as c_int) & 7) as c_uint)) as c_uint)) != 0: 1 else: 0)

}

fn convert_glob_parse_range(__param_from: *mut *const u8, __param_pattern_end: *const u8, __param_out: *mut pcre2_output_context, __param_utf: c_int, __param_separator: u8, __param_with_escape: c_int, __param_escape: u8, __param_no_wildsep: c_int) -> c_int {
    var __local_is_negative: c_int = 0

    var __local_separator_seen: c_int = 0

    var __local_has_prev_c: c_int

    var __local_pattern: *const u8 = (unsafe *__param_from)

    var __local_char_start: *const u8 = null

    var __local_c: c_uint

    var __local_prev_c: c_uint


    var __local_len: c_int

    var __local_class_index: c_int


    __param_utf

    if ((if __local_pattern >= __param_pattern_end: 1 else: 0) != 0) {
        ((unsafe *__param_from) = __local_pattern)

        return 106

    }

    var __ci_expr_logic_0: c_int

    if ((if (unsafe *__local_pattern) == 33: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__local_pattern) == 94: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_pattern = __local_pattern + 1)

        if ((if __local_pattern >= __param_pattern_end: 1 else: 0) != 0) {
            ((unsafe *__param_from) = __local_pattern)

            return 106

        }

        (__local_is_negative = 1)

        ((unsafe *__param_out).out_str[0] = 91)

        ((unsafe *__param_out).out_str[1] = 94)

        (__local_len = 2)

        if ((if not (__param_no_wildsep != 0): 1 else: 0) != 0) {
            if (__param_with_escape != 0) {
                ((unsafe *__param_out).out_str[__local_len] = 92)

                (__local_len = __local_len + 1)

            }

            ((unsafe *__param_out).out_str[__local_len] = __param_separator)

        }

        convert_glob_write_str(__param_out, (__local_len + 1))

    } else {
        convert_glob_write(__param_out, 91)
    }


    (__local_has_prev_c = 0)

    (__local_prev_c = 0)

    if ((if (unsafe *__local_pattern) == 93: 1 else: 0) != 0) {
        ((unsafe *__param_out).out_str[0] = 92)

        ((unsafe *__param_out).out_str[1] = 93)

        convert_glob_write_str(__param_out, 2)

        (__local_has_prev_c = 1)

        (__local_prev_c = 93)

        (__local_pattern = __local_pattern + 1)

    }

    while ((if __local_pattern < __param_pattern_end: 1 else: 0) != 0) {
        (__local_char_start = __local_pattern)

        var __ci_expr_old_1: *const u8 = __local_pattern

        (__local_pattern = __local_pattern + 1)

        (__local_c = (unsafe *__ci_expr_old_1))


        var __ci_expr_logic_2: c_int = 0

        if (__param_utf != 0) {
            (__ci_expr_logic_2 = (if (if __local_c >= 192: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_3: *const u8 = __local_pattern

                (__local_pattern = __local_pattern + 1)

                (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_3) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

            } else {
                if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    (__local_pattern = __local_pattern + ((2 as isize) as usize))

                } else {
                    if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_pattern = __local_pattern + ((3 as isize) as usize))

                    } else {
                        if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_pattern = __local_pattern + ((4 as isize) as usize))

                        } else {
                            (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_pattern = __local_pattern + ((5 as isize) as usize))

                        }
                    }
                }
            }

        }


        if ((if __local_c == 93: 1 else: 0) != 0) {
            convert_glob_write(__param_out, __local_c)

            var __ci_expr_logic_5: c_int = 0

            var __ci_expr_logic_4: c_int = 0

            if ((if not (__local_is_negative != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if not (__param_no_wildsep != 0): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if __local_separator_seen != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                ((unsafe *__param_out).out_str[0] = 40)

                ((unsafe *__param_out).out_str[1] = 63)

                ((unsafe *__param_out).out_str[2] = 60)

                ((unsafe *__param_out).out_str[3] = 33)

                convert_glob_write_str(__param_out, 4)

                convert_glob_print_separator(__param_out, __param_separator, __param_with_escape)

                convert_glob_write(__param_out, 41)

            }


            ((unsafe *__param_from) = __local_pattern)

            return 0

        }

        if ((if __local_pattern >= __param_pattern_end: 1 else: 0) != 0) {
            break
        }

        var __ci_expr_logic_6: c_int = 0

        if ((if __local_c == 91: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe *__local_pattern) == 58: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            ((unsafe *__param_from) = __local_pattern)

            (__local_class_index = convert_glob_parse_class(__param_from, __param_pattern_end, __param_out))

            if ((if __local_class_index != 0: 1 else: 0) != 0) {
                (__local_pattern = (unsafe *__param_from))

                (__local_has_prev_c = 0)

                (__local_prev_c = 0)

                var __ci_expr_logic_7: c_int = 0

                if ((if not (__local_is_negative != 0): 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if convert_glob_char_in_class(__local_class_index, __param_separator) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_7 != 0) {
                    (__local_separator_seen = 1)
                }


                continue

            }

        } else {
            var __ci_expr_logic_9: c_int = 0

            var __ci_expr_logic_8: c_int = 0

            if ((if __local_c == 45: 1 else: 0) != 0) {
                (__ci_expr_logic_8 = (if __local_has_prev_c != 0: 1 else: 0))
            }

            if (__ci_expr_logic_8 != 0) {
                (__ci_expr_logic_9 = (if (if (unsafe *__local_pattern) != 93: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                convert_glob_write(__param_out, 45)

                (__local_char_start = __local_pattern)

                var __ci_expr_old_10: *const u8 = __local_pattern

                (__local_pattern = __local_pattern + 1)

                (__local_c = (unsafe *__ci_expr_old_10))


                var __ci_expr_logic_11: c_int = 0

                if (__param_utf != 0) {
                    (__ci_expr_logic_11 = (if (if __local_c >= 192: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_12: *const u8 = __local_pattern

                        (__local_pattern = __local_pattern + 1)

                        (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_12) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    } else {
                        if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_pattern = __local_pattern + ((2 as isize) as usize))

                        } else {
                            if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_pattern = __local_pattern + ((3 as isize) as usize))

                            } else {
                                if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                    (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_pattern = __local_pattern + ((4 as isize) as usize))

                                } else {
                                    (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_pattern = __local_pattern + ((5 as isize) as usize))

                                }
                            }
                        }
                    }

                }


                if ((if __local_pattern >= __param_pattern_end: 1 else: 0) != 0) {
                    break
                }

                var __ci_expr_logic_13: c_int = 0

                if ((if __param_escape != 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_13 = (if (if __local_c == __param_escape: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_13 != 0) {
                    (__local_char_start = __local_pattern)

                    var __ci_expr_old_14: *const u8 = __local_pattern

                    (__local_pattern = __local_pattern + 1)

                    (__local_c = (unsafe *__ci_expr_old_14))


                    var __ci_expr_logic_15: c_int = 0

                    if (__param_utf != 0) {
                        (__ci_expr_logic_15 = (if (if __local_c >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                            var __ci_expr_old_16: *const u8 = __local_pattern

                            (__local_pattern = __local_pattern + 1)

                            (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_16) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        } else {
                            if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_pattern = __local_pattern + ((2 as isize) as usize))

                            } else {
                                if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                                    (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_pattern = __local_pattern + ((3 as isize) as usize))

                                } else {
                                    if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                        (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                        (__local_pattern = __local_pattern + ((4 as isize) as usize))

                                    } else {
                                        (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                        (__local_pattern = __local_pattern + ((5 as isize) as usize))

                                    }
                                }
                            }
                        }

                    }


                } else {
                    var __ci_expr_logic_17: c_int = 0

                    if ((if __local_c == 91: 1 else: 0) != 0) {
                        (__ci_expr_logic_17 = (if (if (unsafe *__local_pattern) == 58: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_17 != 0) {
                        ((unsafe *__param_from) = __local_pattern)

                        return -64

                    }

                }


                if ((if __local_prev_c > __local_c: 1 else: 0) != 0) {
                    ((unsafe *__param_from) = __local_pattern)

                    return -64

                }

                var __ci_expr_logic_18: c_int = 0

                if ((if __local_prev_c < __param_separator: 1 else: 0) != 0) {
                    (__ci_expr_logic_18 = (if (if __param_separator < __local_c: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_18 != 0) {
                    (__local_separator_seen = 1)
                }


                (__local_has_prev_c = 0)

                (__local_prev_c = 0)

            } else {
                var __ci_expr_logic_19: c_int = 0

                if ((if __param_escape != 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_19 = (if (if __local_c == __param_escape: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_19 != 0) {
                    (__local_char_start = __local_pattern)

                    var __ci_expr_old_20: *const u8 = __local_pattern

                    (__local_pattern = __local_pattern + 1)

                    (__local_c = (unsafe *__ci_expr_old_20))


                    var __ci_expr_logic_21: c_int = 0

                    if (__param_utf != 0) {
                        (__ci_expr_logic_21 = (if (if __local_c >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_21 != 0) {
                        if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                            var __ci_expr_old_22: *const u8 = __local_pattern

                            (__local_pattern = __local_pattern + 1)

                            (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_22) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        } else {
                            if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_pattern = __local_pattern + ((2 as isize) as usize))

                            } else {
                                if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                                    (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                    (__local_pattern = __local_pattern + ((3 as isize) as usize))

                                } else {
                                    if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                        (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                        (__local_pattern = __local_pattern + ((4 as isize) as usize))

                                    } else {
                                        (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_pattern) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_pattern[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_pattern[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                        (__local_pattern = __local_pattern + ((5 as isize) as usize))

                                    }
                                }
                            }
                        }

                    }


                    if ((if __local_pattern >= __param_pattern_end: 1 else: 0) != 0) {
                        break
                    }

                }


                (__local_has_prev_c = 1)

                (__local_prev_c = __local_c)

            }

        }


        var __ci_expr_logic_25: c_int

        var __ci_expr_logic_24: c_int

        var __ci_expr_logic_23: c_int

        if ((if __local_c == 91: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_23 = (if (if __local_c == 93: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_23 != 0) {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if (if __local_c == 92: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_24 != 0) {
            (__ci_expr_logic_25 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_25 = (if (if __local_c == 45: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_25 != 0) {
            convert_glob_write(__param_out, 92)
        }


        if ((if __local_c == __param_separator: 1 else: 0) != 0) {
            (__local_separator_seen = 1)
        }

        do {
            var __ci_expr_old_26: *const u8 = __local_char_start

            (__local_char_start = __local_char_start + 1)

            convert_glob_write(__param_out, (unsafe *__ci_expr_old_26))

        } while ((if __local_char_start < __local_pattern: 1 else: 0) != 0)

    }

    ((unsafe *__param_from) = __local_pattern)

    return 106

}

fn convert_glob_print_commit(__param_out: *mut pcre2_output_context) {
    ((unsafe *__param_out).out_str[0] = 40)

    ((unsafe *__param_out).out_str[1] = 42)

    ((unsafe *__param_out).out_str[2] = 67)

    ((unsafe *__param_out).out_str[3] = 79)

    ((unsafe *__param_out).out_str[4] = 77)

    ((unsafe *__param_out).out_str[5] = 77)

    ((unsafe *__param_out).out_str[6] = 73)

    ((unsafe *__param_out).out_str[7] = 84)

    convert_glob_write_str(__param_out, 8)

    convert_glob_write(__param_out, 41)

}

fn convert_glob(__param_options: c_uint, __param_pattern: *const u8, __param_plength: c_ulong, __param_utf: c_int, __param_use_buffer: *mut u8, __param_use_length: c_ulong, __param_bufflenptr: *mut c_ulong, __param_dummyrun: c_int, __param_ccontext: *mut pcre2_real_convert_context_8) -> c_int {
    var __local_pattern = __param_pattern
    var __local_out: pcre2_output_context

    var __local_pattern_start: *const u8 = __local_pattern

    var __local_pattern_end: *const u8 = (__local_pattern + (__param_plength as usize))

    var __local_separator: u8 = __param_ccontext.glob_separator

    var __local_escape: u8 = __param_ccontext.glob_escape

    var __local_c: u8

    var __local_no_wildsep: c_int = (if ((__param_options as c_uint) & (48 as c_uint)) != 0: 1 else: 0)

    var __local_no_starstar: c_int = (if ((__param_options as c_uint) & (80 as c_uint)) != 0: 1 else: 0)

    var __local_in_atomic: c_int = 0

    var __local_after_starstar: c_int = 0

    var __local_no_slash_z: c_int = 0

    var __local_with_escape: c_int

    var __local_is_start: c_int

    var __local_after_separator: c_int


    var __local_result: c_int = 0

    __param_utf

    var __ci_expr_logic_1: c_int = 0

    if (__param_utf != 0) {
        var __ci_expr_logic_0: c_int

        if ((if __local_separator >= 128: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_escape >= 128: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        ((unsafe *__param_bufflenptr) = 0)

        return -64

    }


    (__local_with_escape = (if string_find_char(pcre2_escaped_literals, __local_separator) != null: 1 else: 0))

    (__local_out.output = __param_use_buffer)

    (__local_out.output_end = __param_use_buffer + (__param_use_length as usize))

    (__local_out.output_size = 0)

    (__local_out.out_str[0] = 40)

    (__local_out.out_str[1] = 63)

    (__local_out.out_str[2] = 115)

    (__local_out.out_str[3] = 41)

    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 4)

    (__local_is_start = 1)

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_pattern < __local_pattern_end: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (unsafe __local_pattern[0]) == 42: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        if (__local_no_wildsep != 0) {
            (__local_is_start = 0)
        } else {
            var __ci_expr_logic_4: c_int = 0

            var __ci_expr_logic_3: c_int = 0

            if ((if not (__local_no_starstar != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if (__local_pattern + ((1 as isize) as usize)) < __local_pattern_end: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if (if (unsafe __local_pattern[1]) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__local_is_start = 0)
            }

        }

    }


    if (__local_is_start != 0) {
        (__local_out.out_str[0] = 92)

        (__local_out.out_str[1] = 65)

        convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 2)

    }

    while ((if __local_pattern < __local_pattern_end: 1 else: 0) != 0) {
        var __ci_expr_old_5: *const u8 = __local_pattern

        (__local_pattern = __local_pattern + 1)

        (__local_c = (unsafe *__ci_expr_old_5))


        if ((if __local_c == 42: 1 else: 0) != 0) {
            (__local_is_start = (if __local_pattern == (__local_pattern_start + ((1 as isize) as usize)): 1 else: 0))

            if (__local_in_atomic != 0) {
                convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 41)

                (__local_in_atomic = 0)

            }

            var __ci_expr_logic_7: c_int = 0

            var __ci_expr_logic_6: c_int = 0

            if ((if not (__local_no_starstar != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if __local_pattern < __local_pattern_end: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                (__ci_expr_logic_7 = (if (if (unsafe *__local_pattern) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_7 != 0) {
                var __ci_expr_logic_8: c_int

                if (__local_is_start != 0) {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_8 = (if (if (unsafe __local_pattern[-2]) == __local_separator: 1 else: 0) != 0: 1 else: 0))
                }

                (__local_after_separator = __ci_expr_logic_8)


                do {
                    (__local_pattern = __local_pattern + 1)
                } while { var __ci_expr_logic_9: c_int = 0

                if ((if __local_pattern < __local_pattern_end: 1 else: 0) != 0) {
                    (__ci_expr_logic_9 = (if (if (unsafe *__local_pattern) == 42: 1 else: 0) != 0: 1 else: 0))
                }; (__ci_expr_logic_9 != 0) }

                if ((if __local_pattern >= __local_pattern_end: 1 else: 0) != 0) {
                    (__local_no_slash_z = 1)

                    break

                }

                (__local_after_starstar = 1)

                var __ci_expr_logic_13: c_int = 0

                var __ci_expr_logic_12: c_int = 0

                var __ci_expr_logic_11: c_int = 0

                var __ci_expr_logic_10: c_int = 0

                if (__local_after_separator != 0) {
                    (__ci_expr_logic_10 = (if (if __local_escape != 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_10 != 0) {
                    (__ci_expr_logic_11 = (if (if (unsafe *__local_pattern) == __local_escape: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    (__ci_expr_logic_12 = (if (if (__local_pattern + ((1 as isize) as usize)) < __local_pattern_end: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_12 != 0) {
                    (__ci_expr_logic_13 = (if (if (unsafe __local_pattern[1]) == __local_separator: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_13 != 0) {
                    (__local_pattern = __local_pattern + 1)
                }


                if (__local_is_start != 0) {
                    if ((if (unsafe *__local_pattern) != __local_separator: 1 else: 0) != 0) {
                        continue
                    }

                    (__local_out.out_str[0] = 40)

                    (__local_out.out_str[1] = 63)

                    (__local_out.out_str[2] = 58)

                    (__local_out.out_str[3] = 92)

                    (__local_out.out_str[4] = 65)

                    (__local_out.out_str[5] = 124)

                    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 6)

                    convert_glob_print_separator((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)

                    convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 41)

                    (__local_pattern = __local_pattern + 1)

                    continue

                }

                convert_glob_print_commit((&raw mut __local_out as *mut pcre2_output_context))

                var __ci_expr_logic_14: c_int

                if ((if not (__local_after_separator != 0): 1 else: 0) != 0) {
                    (__ci_expr_logic_14 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_14 = (if (if (unsafe *__local_pattern) != __local_separator: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_14 != 0) {
                    (__local_out.out_str[0] = 46)

                    (__local_out.out_str[1] = 42)

                    (__local_out.out_str[2] = 63)

                    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 3)

                    continue

                }


                (__local_out.out_str[0] = 40)

                (__local_out.out_str[1] = 63)

                (__local_out.out_str[2] = 58)

                (__local_out.out_str[3] = 46)

                (__local_out.out_str[4] = 42)

                (__local_out.out_str[5] = 63)

                convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 6)

                convert_glob_print_separator((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)

                (__local_out.out_str[0] = 41)

                (__local_out.out_str[1] = 63)

                (__local_out.out_str[2] = 63)

                convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 3)

                (__local_pattern = __local_pattern + 1)

                continue

            }


            var __ci_expr_logic_15: c_int = 0

            if ((if __local_pattern < __local_pattern_end: 1 else: 0) != 0) {
                (__ci_expr_logic_15 = (if (if (unsafe *__local_pattern) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_15 != 0) {
                do {
                    (__local_pattern = __local_pattern + 1)
                } while { var __ci_expr_logic_16: c_int = 0

                if ((if __local_pattern < __local_pattern_end: 1 else: 0) != 0) {
                    (__ci_expr_logic_16 = (if (if (unsafe *__local_pattern) == 42: 1 else: 0) != 0: 1 else: 0))
                }; (__ci_expr_logic_16 != 0) }

            }


            if (__local_no_wildsep != 0) {
                if ((if __local_pattern >= __local_pattern_end: 1 else: 0) != 0) {
                    (__local_no_slash_z = 1)

                    break

                }

                if (__local_is_start != 0) {
                    continue
                }

            }

            if ((if not (__local_is_start != 0): 1 else: 0) != 0) {
                if (__local_after_starstar != 0) {
                    (__local_out.out_str[0] = 40)

                    (__local_out.out_str[1] = 63)

                    (__local_out.out_str[2] = 62)

                    convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 3)

                    (__local_in_atomic = 1)

                } else {
                    convert_glob_print_commit((&raw mut __local_out as *mut pcre2_output_context))
                }

            }

            if (__local_no_wildsep != 0) {
                convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 46)
            } else {
                convert_glob_print_wildcard((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)
            }

            (__local_out.out_str[0] = 42)

            (__local_out.out_str[1] = 63)

            if ((if __local_pattern >= __local_pattern_end: 1 else: 0) != 0) {
                (__local_out.out_str[1] = 43)
            }

            convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 2)

            continue

        }

        if ((if __local_c == 63: 1 else: 0) != 0) {
            if (__local_no_wildsep != 0) {
                convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 46)
            } else {
                convert_glob_print_wildcard((&raw mut __local_out as *mut pcre2_output_context), __local_separator, __local_with_escape)
            }

            continue

        }

        if ((if __local_c == 91: 1 else: 0) != 0) {
            (__local_result = convert_glob_parse_range((&raw mut __local_pattern as *mut *const u8), __local_pattern_end, (&raw mut __local_out as *mut pcre2_output_context), __param_utf, __local_separator, __local_with_escape, __local_escape, __local_no_wildsep))

            if ((if __local_result != 0: 1 else: 0) != 0) {
                break
            }

            continue

        }

        var __ci_expr_logic_17: c_int = 0

        if ((if __local_escape != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if __local_c == __local_escape: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_17 != 0) {
            if ((if __local_pattern >= __local_pattern_end: 1 else: 0) != 0) {
                (__local_result = -64)

                break

            }

            var __ci_expr_old_18: *const u8 = __local_pattern

            (__local_pattern = __local_pattern + 1)

            (__local_c = (unsafe *__ci_expr_old_18))


        }


        var __ci_expr_logic_19: c_int = 0

        if ((if __local_c < 255: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if (if string_find_char(pcre2_escaped_literals, __local_c) != null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_19 != 0) {
            convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 92)
        }


        convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), __local_c)

    }

    if ((if __local_result == 0: 1 else: 0) != 0) {
        if ((if not (__local_no_slash_z != 0): 1 else: 0) != 0) {
            (__local_out.out_str[0] = 92)

            (__local_out.out_str[1] = 122)

            convert_glob_write_str((&raw mut __local_out as *mut pcre2_output_context), 2)

        }

        if (__local_in_atomic != 0) {
            convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 41)
        }

        convert_glob_write((&raw mut __local_out as *mut pcre2_output_context), 0)

        var __ci_expr_logic_20: c_int = 0

        if ((if not (__param_dummyrun != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if (&raw const __local_out as *const pcre2_output_context).output_size != ((((((&raw const __local_out as *const pcre2_output_context).output as usize) -% (__param_use_buffer as usize)) / sizeof[u8]()) as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_20 != 0) {
            (__local_result = -48)
        }


    }

    if ((if __local_result != 0: 1 else: 0) != 0) {
        ((unsafe *__param_bufflenptr) = ((__local_pattern as usize) -% (__local_pattern_start as usize)) / sizeof[u8]())

        return __local_result

    }

    ((unsafe *__param_bufflenptr) = (((&raw const __local_out as *const pcre2_output_context).output_size as c_ulong) -% (1 as c_ulong)))

    return 0

}

var pcre2_escaped_literals: *const i8 = "\x5c\x3f\x2a\x2b\x7c\x2e\x5e\x24\x7b\x7d\x5b\x5d\x28\x29"
var posix_meta_escapes: *const i8 = "\x28\x29\x7b\x7d\x31\x32\x33\x34\x35\x36\x37\x38\x39"
var posix_classes: *const i8 = "\x61\x6c\x70\x68\x61\x3a\x6c\x6f\x77\x65\x72\x3a\x75\x70\x70\x65\x72\x3a\x61\x6c\x6e\x75\x6d\x3a\x61\x73\x63\x69\x69\x3a\x62\x6c\x61\x6e\x6b\x3a\x63\x6e\x74\x72\x6c\x3a\x64\x69\x67\x69\x74\x3a\x67\x72\x61\x70\x68\x3a\x70\x72\x69\x6e\x74\x3a\x70\x75\x6e\x63\x74\x3a\x73\x70\x61\x63\x65\x3a\x77\x6f\x72\x64\x3a\x78\x64\x69\x67\x69\x74\x3a"
