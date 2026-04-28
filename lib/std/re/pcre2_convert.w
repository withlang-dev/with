// Migrated from PCRE2
use std.re.defs

fn pcre2_pattern_convert_8(__param_pattern: *const u8, __param_plength: c_ulong, options: c_uint, buffptr: *mut *mut u8, bufflenptr: *mut c_ulong, __param_ccontext: *mut pcre2_real_convert_context_8) -> c_int {
    var pattern = __param_pattern
    var plength = __param_plength
    var ccontext = __param_ccontext
    var rc: c_int

    var null_str: [1]u8 = [205]

    var dummy_buffer: [100]u8

    var use_buffer: *mut u8 = ((&dummy_buffer[0] as *mut u8))

    var use_length: c_ulong = 100

    var utf: c_int = (if (options & 1) != 0: 1 else: 0)

    var pattype: c_uint = (options & ((16 | 4) | 8))

    var __ci_expr_logic_0: c_int = 0

    if ((if pattern == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if plength == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (pattern = (&null_str[0] as *mut u8))
    }


    var __ci_expr_logic_1: c_int

    if ((if pattern == null: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if bufflenptr == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        if ((if bufflenptr != null: 1 else: 0) != 0) {
            ((unsafe: *bufflenptr) = 0)
        }

        return -51

    }


    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if (options & (~((((1 | 2) | 48) | 80) | ((16 | 4) | 8)))) != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (pattype & ((~pattype) +% 1)) != pattype: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if pattype == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        ((unsafe: *bufflenptr) = 0)

        return -34

    }


    if ((if plength == (~(0 as c_ulong)): 1 else: 0) != 0) {
        (plength = _pcre2_strlen_8(pattern))
    }

    if ((if ccontext == null: 1 else: 0) != 0) {
        (ccontext = ((&raw mut _pcre2_default_convert_context_8 as *mut pcre2_real_convert_context_8)))
    }

    var __ci_expr_logic_4: c_int = 0

    if (utf != 0) {
        (__ci_expr_logic_4 = (if (if (options & 2) == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        var erroroffset: c_ulong

        (rc = _pcre2_valid_utf_8(pattern, plength, (&raw mut erroroffset as *mut c_ulong)))

        if ((if rc != 0: 1 else: 0) != 0) {
            ((unsafe: *bufflenptr) = erroroffset)

            return rc

        }

    }


    var __ci_expr_logic_5: c_int = 0

    if ((if buffptr != null: 1 else: 0) != 0) {
        (__ci_expr_logic_5 = (if (if (unsafe: *buffptr) != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (use_buffer = (unsafe: *buffptr))

        (use_length = (unsafe: *bufflenptr))

    }


    var i: c_int = 0

    while ((if i < 2: 1 else: 0) != 0) {
        var allocated: *mut u8

        var dummyrun: c_int = with 0 as __ci_expr_seq_118 {
            var __ci_expr_logic_6: c_int
            if ((if buffptr == null: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if (unsafe: *buffptr) == null: 1 else: 0) != 0: 1 else: 0))
            }
            __ci_expr_logic_6
        }

        while true {
            match pattype {
                16 => {
                    (rc = convert_glob((options & (~16)), pattern, plength, utf, use_buffer, use_length, bufflenptr, dummyrun, ccontext))
                },
                4 => {
                    (rc = convert_posix(pattype, pattern, plength, utf, use_buffer, use_length, bufflenptr, dummyrun, ccontext))
                },
                8 => {
                    (rc = convert_posix(pattype, pattern, plength, utf, use_buffer, use_length, bufflenptr, dummyrun, ccontext))
                },
                _ => {
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    ((unsafe: *bufflenptr) = 0)

                    return -44

                },
            }

            break

        }

        var __ci_expr_logic_9: c_int

        var __ci_expr_logic_8: c_int

        if ((if rc != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if (if buffptr == null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_9 = (if (if (unsafe: *buffptr) != null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_9 != 0) {
            return rc
        }


        (allocated = ((_pcre2_memctl_malloc_8((sizeof[pcre2_memctl]() +% (((unsafe: *bufflenptr) +% 1) *% 8)), (ccontext as *mut pcre2_memctl)) as *mut u8)))

        if ((if allocated == null: 1 else: 0) != 0) {
            ((unsafe: *bufflenptr) = 0)

            return -48

        }

        ((unsafe: *buffptr) = ((((allocated as *mut c_char) + sizeof[pcre2_memctl]()) as *mut u8)))

        (use_buffer = (unsafe: *buffptr))

        (use_length = ((unsafe: *bufflenptr) +% 1))


        (i = i + 1)

    }


    while true {
        if (not (0 != 0)) {
            break
        }
    }

    ((unsafe: *bufflenptr) = 0)

    return -44

}

fn pcre2_converted_pattern_free_8(converted: *mut u8) {
    if ((if converted != null: 1 else: 0) != 0) {
        var memctl: *mut pcre2_memctl = ((((converted as *mut c_char) - sizeof[pcre2_memctl]()) as *mut pcre2_memctl))

        memctl.free(memctl, memctl.memory_data)

    }

}

fn convert_posix(pattype: c_uint, pattern: *const u8, __param_plength: c_ulong, utf: c_int, use_buffer: *mut u8, use_length: c_ulong, bufflenptr: *mut c_ulong, dummyrun: c_int, ccontext: *mut pcre2_real_convert_context_8) -> c_int {
    var plength = __param_plength
    var posix__goto_154_12: *const u8 = null
    var p__goto_155_14: *mut u8 = null
    var pp__goto_156_14: *mut u8 = null
    var endp__goto_157_14: *mut u8 = null
    var convlength__goto_158_12: c_ulong = 0
    var bracount__goto_160_10: c_uint = 0
    var posix_state__goto_161_10: c_uint = 0
    var lastspecial__goto_162_10: c_uint = 0
    var extended__goto_163_6: c_int = 0
    var nextisliteral__goto_164_6: c_int = 0
    var s__goto_172_1: *const i8 = null
    var c__goto_178_12: c_uint = 0
    var sc__goto_178_15: c_uint = 0
    var clength__goto_179_7: c_int = 0
    var s__goto_208_7: *const i8 = null
    var s__goto_224_11: *const i8 = null
    var s__goto_241_32: *const i8 = null
    var s__goto_253_5: *const i8 = null
    var s__goto_291_9: *const i8 = null
    var s__goto_297_9: *const i8 = null
    var s__goto_308_51: *const i8 = null
    var s__goto_367_7: *const i8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc {
            0 => {
                (__goto_pending = 0)
                (posix__goto_154_12 = pattern)
                (p__goto_155_14 = use_buffer)
                (pp__goto_156_14 = p__goto_155_14)
                (endp__goto_157_14 = (p__goto_155_14 + use_length) - ((1 as isize) as usize))
                (convlength__goto_158_12 = 0)
                (bracount__goto_160_10 = 0)
                (posix_state__goto_161_10 = 0)
                (lastspecial__goto_162_10 = 0)
                (extended__goto_163_6 = (if (pattype & 8) != 0: 1 else: 0))
                (nextisliteral__goto_164_6 = 0)
                utf
                if (__goto_pending != 0) {
                    continue
                }
                ccontext
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *bufflenptr) = plength)
                if (__goto_pending != 0) {
                    continue
                }
                while ((if (unsafe: *s__goto_172_1) != 0: 1 else: 0) != 0) {
                    if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                        return -48
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    var __ci_expr_old_0: *mut u8 = p__goto_155_14
                    (p__goto_155_14 = p__goto_155_14 + 1)
                    ((unsafe: *__ci_expr_old_0) = (unsafe: *s__goto_172_1))
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (s__goto_172_1 = s__goto_172_1 + 1)
                }
                if (__goto_pending != 0) {
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 3
                __goto_pending = 1
                continue
            },
            3 => {  // __while_top
                (__goto_pending = 0)
                if (not ((if plength > 0: 1 else: 0) != 0)) {
                    __pc = 4
                    __goto_pending = 1
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                (clength__goto_179_7 = 1)
                (convlength__goto_158_12 = convlength__goto_158_12 + (((p__goto_155_14 as usize) -% (pp__goto_156_14 as usize)) / sizeof[u8]()))
                if (__goto_pending != 0) {
                    continue
                }
                if (dummyrun != 0) {
                    (p__goto_155_14 = use_buffer)
                }
                if (__goto_pending != 0) {
                    continue
                }
                (pp__goto_156_14 = p__goto_155_14)
                if (__goto_pending != 0) {
                    continue
                }
                (c__goto_178_12 = (unsafe: *posix__goto_154_12))
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_logic_1: c_int = 0
                if (utf != 0) {
                    (__ci_expr_logic_1 = (if (if c__goto_178_12 >= 192: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_1 != 0) {
                    if ((if (c__goto_178_12 & 32) == 0: 1 else: 0) != 0) {
                        (c__goto_178_12 = (((c__goto_178_12 & 31) as c_uint) << (6 as c_uint)) | ((unsafe: posix__goto_154_12[1]) & 63))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (clength__goto_179_7 = clength__goto_179_7 + 1)
                        if (__goto_pending != 0) {
                            continue
                        }
                    } else {
                        if ((if (c__goto_178_12 & 16) == 0: 1 else: 0) != 0) {
                            (c__goto_178_12 = ((((c__goto_178_12 & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: posix__goto_154_12[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: posix__goto_154_12[2]) & 63))
                            if (__goto_pending != 0) {
                                continue
                            }
                            (clength__goto_179_7 = clength__goto_179_7 + 2)
                            if (__goto_pending != 0) {
                                continue
                            }
                        } else {
                            if ((if (c__goto_178_12 & 8) == 0: 1 else: 0) != 0) {
                                (c__goto_178_12 = (((((c__goto_178_12 & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: posix__goto_154_12[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: posix__goto_154_12[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: posix__goto_154_12[3]) & 63))
                                if (__goto_pending != 0) {
                                    continue
                                }
                                (clength__goto_179_7 = clength__goto_179_7 + 3)
                                if (__goto_pending != 0) {
                                    continue
                                }
                            } else {
                                if ((if (c__goto_178_12 & 4) == 0: 1 else: 0) != 0) {
                                    (c__goto_178_12 = ((((((c__goto_178_12 & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: posix__goto_154_12[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: posix__goto_154_12[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: posix__goto_154_12[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: posix__goto_154_12[4]) & 63))
                                    if (__goto_pending != 0) {
                                        continue
                                    }
                                    (clength__goto_179_7 = clength__goto_179_7 + 4)
                                    if (__goto_pending != 0) {
                                        continue
                                    }
                                } else {
                                    (c__goto_178_12 = (((((((c__goto_178_12 & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: posix__goto_154_12[1]) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: posix__goto_154_12[2]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: posix__goto_154_12[3]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: posix__goto_154_12[4]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: posix__goto_154_12[5]) & 63))
                                    if (__goto_pending != 0) {
                                        continue
                                    }
                                    (clength__goto_179_7 = clength__goto_179_7 + 5)
                                    if (__goto_pending != 0) {
                                        continue
                                    }
                                }
                            }
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                (posix__goto_154_12 = posix__goto_154_12 + clength__goto_179_7)
                if (__goto_pending != 0) {
                    continue
                }
                (plength = plength - clength__goto_179_7)
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_ternary_2: c_uint = 0
                if (nextisliteral__goto_164_6 != 0) {
                    (__ci_expr_ternary_2 = 0)
                } else {
                    (__ci_expr_ternary_2 = c__goto_178_12)
                }
                (sc__goto_178_15 = __ci_expr_ternary_2)
                if (__goto_pending != 0) {
                    continue
                }
                (nextisliteral__goto_164_6 = 0)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if posix_state__goto_161_10 >= 3: 1 else: 0) != 0) {
                    if ((if c__goto_178_12 == 93: 1 else: 0) != 0) {
                        while ((if (unsafe: *s__goto_208_7) != 0: 1 else: 0) != 0) {
                            if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                return -48
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            var __ci_expr_old_3: *mut u8 = p__goto_155_14
                            (p__goto_155_14 = p__goto_155_14 + 1)
                            ((unsafe: *__ci_expr_old_3) = (unsafe: *s__goto_208_7))
                            if (__goto_pending != 0) {
                                break
                            }
                            if (__goto_pending != 0) {
                                break
                            }
                            (s__goto_208_7 = s__goto_208_7 + 1)
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        (posix_state__goto_161_10 = 2)
                        if (__goto_pending != 0) {
                            continue
                        }
                    } else {
                        var __ci_expr_switch_continue_8: i32 = 0
                        while true {
                            match posix_state__goto_161_10 {
                                5 => {
                                    var __ci_expr_logic_4: c_int = 0

                                    if ((if c__goto_178_12 >= 97: 1 else: 0) != 0) {
                                        (__ci_expr_logic_4 = (if (if c__goto_178_12 <= 122: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_4 != 0) {
                                        break
                                    }


                                    (posix_state__goto_161_10 = 3)

                                    var __ci_expr_logic_6: c_int = 0

                                    var __ci_expr_logic_5: c_int = 0

                                    if ((if c__goto_178_12 == 58: 1 else: 0) != 0) {
                                        (__ci_expr_logic_5 = (if (if plength > 0: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_5 != 0) {
                                        (__ci_expr_logic_6 = (if (if (unsafe: *posix__goto_154_12) == 93: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_6 != 0) {
                                        while ((if (unsafe: *s__goto_224_11) != 0: 1 else: 0) != 0) {
                                            if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                                return -48
                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            var __ci_expr_old_7: *mut u8 = p__goto_155_14

                                            (p__goto_155_14 = p__goto_155_14 + 1)

                                            ((unsafe: *__ci_expr_old_7) = (unsafe: *s__goto_224_11))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (s__goto_224_11 = s__goto_224_11 + 1)

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }


                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (plength = plength - 1)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (posix__goto_154_12 = posix__goto_154_12 + 1)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        continue

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    }


                                    if ((if c__goto_178_12 == 91: 1 else: 0) != 0) {
                                        (posix_state__goto_161_10 = 4)
                                    }

                                },
                                3 => {
                                    if ((if c__goto_178_12 == 91: 1 else: 0) != 0) {
                                        (posix_state__goto_161_10 = 4)
                                    }
                                },
                                4 => {
                                    if ((if c__goto_178_12 == 58: 1 else: 0) != 0) {
                                        (posix_state__goto_161_10 = 5)
                                    }
                                },
                            }
                            break
                        }
                        if (__ci_expr_switch_continue_8 != 0) {
                            continue
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if c__goto_178_12 == 92: 1 else: 0) != 0) {
                            while ((if (unsafe: *s__goto_241_32) != 0: 1 else: 0) != 0) {
                                if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                    return -48
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                var __ci_expr_old_9: *mut u8 = p__goto_155_14
                                (p__goto_155_14 = p__goto_155_14 + 1)
                                ((unsafe: *__ci_expr_old_9) = (unsafe: *s__goto_241_32))
                                if (__goto_pending != 0) {
                                    break
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                (s__goto_241_32 = s__goto_241_32 + 1)
                            }
                            if (__goto_pending != 0) {
                                continue
                            }
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        if ((if (p__goto_155_14 + ((clength__goto_179_7 as isize) as usize)) > endp__goto_157_14: 1 else: 0) != 0) {
                            return -48
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        with_memcpy((p__goto_155_14 as *i8), ((posix__goto_154_12 - ((clength__goto_179_7 as isize) as usize)) as *i8), ((clength__goto_179_7 * (8 / 8)) as i64))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (p__goto_155_14 = p__goto_155_14 + clength__goto_179_7)
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                } else {
                    __pc = 6
                    __goto_pending = 1
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 5
                __goto_pending = 1
                continue
                __pc = 6
                __goto_pending = 1
                continue
            },
            6 => {  // __if_else
                (__goto_pending = 0)
                while true {
                    match sc__goto_178_15 {
                        91 => {
                            while ((if (unsafe: *s__goto_253_5) != 0: 1 else: 0) != 0) {
                                if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                    return -48
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                var __ci_expr_old_10: *mut u8 = p__goto_155_14

                                (p__goto_155_14 = p__goto_155_14 + 1)

                                ((unsafe: *__ci_expr_old_10) = (unsafe: *s__goto_253_5))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                (s__goto_253_5 = s__goto_253_5 + 1)

                            }

                            if (__goto_pending != 0) {
                                break
                            }


                            (posix_state__goto_161_10 = 3)

                            if ((if plength > 0: 1 else: 0) != 0) {
                                if ((if (unsafe: *posix__goto_154_12) == 94: 1 else: 0) != 0) {
                                    (posix__goto_154_12 = posix__goto_154_12 + 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (plength = plength - 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    while ((if (unsafe: *s__goto_291_9) != 0: 1 else: 0) != 0) {
                                        if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                            return -48
                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        var __ci_expr_old_11: *mut u8 = p__goto_155_14

                                        (p__goto_155_14 = p__goto_155_14 + 1)

                                        ((unsafe: *__ci_expr_old_11) = (unsafe: *s__goto_291_9))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (s__goto_291_9 = s__goto_291_9 + 1)

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                var __ci_expr_logic_12: c_int = 0

                                if ((if plength > 0: 1 else: 0) != 0) {
                                    (__ci_expr_logic_12 = (if (if (unsafe: *posix__goto_154_12) == 93: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_12 != 0) {
                                    (posix__goto_154_12 = posix__goto_154_12 + 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (plength = plength - 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    while ((if (unsafe: *s__goto_297_9) != 0: 1 else: 0) != 0) {
                                        if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                            return -48
                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        var __ci_expr_old_13: *mut u8 = p__goto_155_14

                                        (p__goto_155_14 = p__goto_155_14 + 1)

                                        ((unsafe: *__ci_expr_old_13) = (unsafe: *s__goto_297_9))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (s__goto_297_9 = s__goto_297_9 + 1)

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                        },
                        92 => {
                            if ((if plength == 0: 1 else: 0) != 0) {
                                return 101
                            }

                            if (extended__goto_163_6 != 0) {
                                (nextisliteral__goto_164_6 = 1)
                            } else {
                                var __ci_expr_logic_14: c_int = 0

                                if ((if (unsafe: *posix__goto_154_12) < 255: 1 else: 0) != 0) {
                                    (__ci_expr_logic_14 = (if (if string_find_char(posix_meta_escapes, (unsafe: *posix__goto_154_12)) != null: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_14 != 0) {
                                    var __ci_expr_logic_15: c_int = 0

                                    if ((if (unsafe: *posix__goto_154_12) >= 48: 1 else: 0) != 0) {
                                        (__ci_expr_logic_15 = (if (if (unsafe: *posix__goto_154_12) <= 57: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_15 != 0) {
                                        while ((if (unsafe: *s__goto_308_51) != 0: 1 else: 0) != 0) {
                                            if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                                return -48
                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            var __ci_expr_old_16: *mut u8 = p__goto_155_14

                                            (p__goto_155_14 = p__goto_155_14 + 1)

                                            ((unsafe: *__ci_expr_old_16) = (unsafe: *s__goto_308_51))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (s__goto_308_51 = s__goto_308_51 + 1)

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if ((if (p__goto_155_14 + ((1 as isize) as usize)) > endp__goto_157_14: 1 else: 0) != 0) {
                                        return -48
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_old_17: *mut u8 = p__goto_155_14

                                    (p__goto_155_14 = p__goto_155_14 + 1)

                                    var __ci_expr_old_18: *const u8 = posix__goto_154_12

                                    (posix__goto_154_12 = posix__goto_154_12 + 1)

                                    ((unsafe: *__ci_expr_old_17) = (unsafe: *__ci_expr_old_18))

                                    (lastspecial__goto_162_10 = (unsafe: *__ci_expr_old_17))


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (plength = plength - 1)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    (nextisliteral__goto_164_6 = 1)
                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                        },
                        41 => {
                            var __ci_expr_logic_19: c_int

                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_19 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_19 = (if (if bracount__goto_160_10 == 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_19 != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }


                            (bracount__goto_160_10 = bracount__goto_160_10 - 1)

                            __pc = 1
                            __goto_pending = 1

                        },
                        40 => {
                            (bracount__goto_160_10 = bracount__goto_160_10 + 1)

                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }

                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break




                        },
                        63 => {
                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }

                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break



                        },
                        43 => {
                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }

                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break



                        },
                        123 => {
                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }

                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break



                        },
                        125 => {
                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }

                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break



                        },
                        124 => {
                            if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                __pc = 2
                                __goto_pending = 1
                            }

                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break



                        },
                        46 => {
                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break


                        },
                        36 => {
                            (posix_state__goto_161_10 = 2)

                            __pc = 1
                            __goto_pending = 1

                            break


                        },
                        42 => {
                            if ((if lastspecial__goto_162_10 != 42: 1 else: 0) != 0) {
                                var __ci_expr_logic_21: c_int = 0

                                if ((if not (extended__goto_163_6 != 0): 1 else: 0) != 0) {
                                    var __ci_expr_logic_20: c_int

                                    if ((if posix_state__goto_161_10 < 2: 1 else: 0) != 0) {
                                        (__ci_expr_logic_20 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_20 = (if (if lastspecial__goto_162_10 == 40: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    (__ci_expr_logic_21 = (if __ci_expr_logic_20 != 0: 1 else: 0))

                                }

                                if (__ci_expr_logic_21 != 0) {
                                    __pc = 2
                                    __goto_pending = 1
                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                                __pc = 1
                                __goto_pending = 1

                                if (__goto_pending != 0) {
                                    break
                                }

                            }
                        },
                        94 => {
                            if (extended__goto_163_6 != 0) {
                                __pc = 1
                                __goto_pending = 1
                            }

                            var __ci_expr_logic_22: c_int

                            if ((if posix_state__goto_161_10 == 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_22 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_22 = (if (if lastspecial__goto_162_10 == 40: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_22 != 0) {
                                (posix_state__goto_161_10 = 1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                __pc = 1
                                __goto_pending = 1

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            var __ci_expr_logic_23: c_int = 0

                            if ((if c__goto_178_12 < 255: 1 else: 0) != 0) {
                                (__ci_expr_logic_23 = (if (if string_find_char(pcre2_escaped_literals, c__goto_178_12) != null: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_23 != 0) {
                                while ((if (unsafe: *s__goto_367_7) != 0: 1 else: 0) != 0) {
                                    if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                        return -48
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_old_24: *mut u8 = p__goto_155_14

                                    (p__goto_155_14 = p__goto_155_14 + 1)

                                    ((unsafe: *__ci_expr_old_24) = (unsafe: *s__goto_367_7))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (s__goto_367_7 = s__goto_367_7 + 1)

                                }

                                if (__goto_pending != 0) {
                                    break
                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (lastspecial__goto_162_10 = 255)

                            if ((if (p__goto_155_14 + ((clength__goto_179_7 as isize) as usize)) > endp__goto_157_14: 1 else: 0) != 0) {
                                return -48
                            }

                            with_memcpy((p__goto_155_14 as *i8), ((posix__goto_154_12 - ((clength__goto_179_7 as isize) as usize)) as *i8), ((clength__goto_179_7 * (8 / 8)) as i64))

                            (p__goto_155_14 = p__goto_155_14 + clength__goto_179_7)

                            (posix_state__goto_161_10 = 2)


                        },
                        _ => {
                            var __ci_expr_logic_23: c_int = 0

                            if ((if c__goto_178_12 < 255: 1 else: 0) != 0) {
                                (__ci_expr_logic_23 = (if (if string_find_char(pcre2_escaped_literals, c__goto_178_12) != null: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_23 != 0) {
                                while ((if (unsafe: *s__goto_367_7) != 0: 1 else: 0) != 0) {
                                    if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                                        return -48
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_old_24: *mut u8 = p__goto_155_14

                                    (p__goto_155_14 = p__goto_155_14 + 1)

                                    ((unsafe: *__ci_expr_old_24) = (unsafe: *s__goto_367_7))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (s__goto_367_7 = s__goto_367_7 + 1)

                                }

                                if (__goto_pending != 0) {
                                    break
                                }


                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (lastspecial__goto_162_10 = 255)

                            if ((if (p__goto_155_14 + ((clength__goto_179_7 as isize) as usize)) > endp__goto_157_14: 1 else: 0) != 0) {
                                return -48
                            }

                            with_memcpy((p__goto_155_14 as *i8), ((posix__goto_154_12 - ((clength__goto_179_7 as isize) as usize)) as *i8), ((clength__goto_179_7 * (8 / 8)) as i64))

                            (p__goto_155_14 = p__goto_155_14 + clength__goto_179_7)

                            (posix_state__goto_161_10 = 2)

                        },
                    }
                    break
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 7
                __goto_pending = 1
                continue
            },
            1 => {  // COPY_SPECIAL
                (__goto_pending = 0)
                (lastspecial__goto_162_10 = c__goto_178_12)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if (p__goto_155_14 + ((1 as isize) as usize)) > endp__goto_157_14: 1 else: 0) != 0) {
                    return -48
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_old_26: *mut u8 = p__goto_155_14
                (p__goto_155_14 = p__goto_155_14 + 1)
                ((unsafe: *__ci_expr_old_26) = c__goto_178_12)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 7
                __goto_pending = 1
                continue
                __pc = 7
                __goto_pending = 1
                continue
            },
            9 => {
                (__goto_pending = 0)
                var __ci_expr_logic_23: c_int = 0
                if ((if c__goto_178_12 < 255: 1 else: 0) != 0) {
                    (__ci_expr_logic_23 = (if (if string_find_char(pcre2_escaped_literals, c__goto_178_12) != null: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_23 != 0) {
                    __pc = 11
                    __goto_pending = 1
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 10
                __goto_pending = 1
                continue
                __pc = 11
                __goto_pending = 1
                continue
            },
            2 => {  // ESCAPE_LITERAL
                (__goto_pending = 0)
                while ((if (unsafe: *s__goto_367_7) != 0: 1 else: 0) != 0) {
                    if ((if p__goto_155_14 >= endp__goto_157_14: 1 else: 0) != 0) {
                        return -48
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    var __ci_expr_old_24: *mut u8 = p__goto_155_14
                    (p__goto_155_14 = p__goto_155_14 + 1)
                    ((unsafe: *__ci_expr_old_24) = (unsafe: *s__goto_367_7))
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (s__goto_367_7 = s__goto_367_7 + 1)
                }
                if (__goto_pending != 0) {
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 10
                __goto_pending = 1
                continue
                __pc = 10
                __goto_pending = 1
                continue
            },
            7 => {  // __after_switch
                (__goto_pending = 0)
                __pc = 5
                __goto_pending = 1
                continue
                __pc = 5
                __goto_pending = 1
                continue
            },
            5 => {  // __after_if
                (__goto_pending = 0)
                __pc = 3
                __goto_pending = 1
                continue
                __pc = 4
                __goto_pending = 1
                continue
            },
            4 => {  // __after_while
                (__goto_pending = 0)
                if ((if posix_state__goto_161_10 >= 3: 1 else: 0) != 0) {
                    return 106
                }
                if (__goto_pending != 0) {
                    continue
                }
                (convlength__goto_158_12 = convlength__goto_158_12 + (((p__goto_155_14 as usize) -% (pp__goto_156_14 as usize)) / sizeof[u8]()))
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *bufflenptr) = convlength__goto_158_12)
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_old_27: *mut u8 = p__goto_155_14
                (p__goto_155_14 = p__goto_155_14 + 1)
                ((unsafe: *__ci_expr_old_27) = 0)
                if (__goto_pending != 0) {
                    continue
                }
                return 0
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

fn convert_glob_write(out: *mut pcre2_output_context, chr: u8) {
    (out.output_size = out.output_size + 1)

    if ((if out.output < out.output_end: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = out.output

        (out.output = out.output + 1)

        ((unsafe: *__ci_expr_old_0) = chr)

    }

}

fn convert_glob_write_str(out: *mut pcre2_output_context, __param_length: c_ulong) {
    var length = __param_length
    var out_str: *mut u8 = ((&out.out_str[0] as *mut u8))

    var output: *mut u8 = out.output

    var output_end: *const u8 = out.output_end

    var output_size: c_ulong = out.output_size

    while true {
        (output_size = output_size + 1)

        if ((if output < output_end: 1 else: 0) != 0) {
            var __ci_expr_old_0: *mut u8 = output

            (output = output + 1)

            var __ci_expr_old_1: *mut u8 = out_str

            (out_str = out_str + 1)

            ((unsafe: *__ci_expr_old_0) = (unsafe: *__ci_expr_old_1))

        }

        (length = length - 1)

        if (not ((if length != 0: 1 else: 0) != 0)) {
            break
        }

    }

    (out.output = output)

    (out.output_size = output_size)

}

fn convert_glob_print_separator(out: *mut pcre2_output_context, separator: u8, with_escape: c_int) {
    if (with_escape != 0) {
        convert_glob_write(out, 92)
    }

    convert_glob_write(out, separator)

}

fn convert_glob_print_wildcard(out: *mut pcre2_output_context, separator: u8, with_escape: c_int) {
    (out.out_str[0] = 91)

    (out.out_str[1] = 94)

    convert_glob_write_str(out, 2)

    convert_glob_print_separator(out, separator, with_escape)

    convert_glob_write(out, 93)

}

fn convert_glob_parse_class(from: *mut *const u8, pattern_end: *const u8, out: *mut pcre2_output_context) -> c_int {
    var start: *const u8 = ((unsafe: *from) + ((1 as isize) as usize))

    var pattern: *const u8 = start

    var class_ptr: *const c_char

    var c: u8

    var class_index: c_int

    while (1 != 0) {
        if ((if pattern >= pattern_end: 1 else: 0) != 0) {
            return 0
        }

        var __ci_expr_old_0: *const u8 = pattern

        (pattern = pattern + 1)

        (c = (unsafe: *__ci_expr_old_0))


        var __ci_expr_logic_1: c_int

        if ((if c < 97: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if c > 122: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            break
        }


    }

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if c != 58: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if pattern >= pattern_end: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (unsafe: *pattern) != 93: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return 0
    }


    (class_ptr = ((posix_classes as *const c_char)))

    (class_index = 1)

    while (1 != 0) {
        if ((if (unsafe: *class_ptr) == 0: 1 else: 0) != 0) {
            return 0
        }

        (pattern = start)

        while ((if (unsafe: *pattern) == (((unsafe: *class_ptr) as u8)): 1 else: 0) != 0) {
            if ((if (unsafe: *pattern) == 58: 1 else: 0) != 0) {
                (pattern = pattern + 2)

                (start = start - 2)

                while true {
                    var __ci_expr_old_4: *const u8 = start

                    (start = start + 1)

                    convert_glob_write(out, (unsafe: *__ci_expr_old_4))

                    if (not ((if start < pattern: 1 else: 0) != 0)) {
                        break
                    }

                }

                ((unsafe: *from) = pattern)

                return class_index

            }

            (pattern = pattern + 1)

            (class_ptr = class_ptr + 1)

        }

        while ((if (unsafe: *class_ptr) != 58: 1 else: 0) != 0) {
            (class_ptr = class_ptr + 1)
        }

        (class_ptr = class_ptr + 1)

        (class_index = class_index + 1)

    }

}

fn convert_glob_char_in_class(class_index: c_int, c: u8) -> c_int {
    var cbits: *const u8 = ((&_pcre2_default_tables_8[0] as *const u8) + ((512 as isize) as usize))

    var cbit: c_int

    while true {
        match class_index {
            1 => {
                if ((if c == 95: 1 else: 0) != 0) {
                    return 0
                }

                if ((if ((unsafe: (cbits + ((64 as isize) as usize))[(c / 8)]) & ((1 as c_uint) << ((c & 7) as c_uint))) != 0: 1 else: 0) != 0) {
                    return 0
                }

                (cbit = 160)

            },
            2 => {
                (cbit = 128)
            },
            3 => {
                (cbit = 96)
            },
            4 => {
                if ((if c == 95: 1 else: 0) != 0) {
                    return 0
                }

                (cbit = 160)

            },
            5 => {
                if ((if ((unsafe: (cbits + ((288 as isize) as usize))[(c / 8)]) & ((1 as c_uint) << ((c & 7) as c_uint))) != 0: 1 else: 0) != 0) {
                    return 1
                }

                (cbit = 224)

            },
            6 => {
                var __ci_expr_logic_2: c_int

                var __ci_expr_logic_1: c_int

                var __ci_expr_logic_0: c_int

                if ((if c == 10: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_0 = (if (if c == 11: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if c == 12: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (if c == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    return 0
                }


                (cbit = 0)

            },
            7 => {
                (cbit = 288)
            },
            8 => {
                (cbit = 64)
            },
            9 => {
                (cbit = 192)
            },
            10 => {
                (cbit = 224)
            },
            11 => {
                (cbit = 256)
            },
            12 => {
                (cbit = 0)
            },
            13 => {
                (cbit = 160)
            },
            14 => {
                (cbit = 32)
            },
            _ => {
                return 0
            },
        }

        break

    }

    return (if ((unsafe: (cbits + ((cbit as isize) as usize))[(c / 8)]) & ((1 as c_uint) << ((c & 7) as c_uint))) != 0: 1 else: 0)

}

fn convert_glob_parse_range(from: *mut *const u8, pattern_end: *const u8, out: *mut pcre2_output_context, utf: c_int, separator: u8, with_escape: c_int, escape: u8, no_wildsep: c_int) -> c_int {
    var is_negative: c_int = 0

    var separator_seen: c_int = 0

    var has_prev_c: c_int

    var pattern: *const u8 = (unsafe: *from)

    var char_start: *const u8 = null

    var c: c_uint

    var prev_c: c_uint


    var len: c_int

    var class_index: c_int


    utf

    if ((if pattern >= pattern_end: 1 else: 0) != 0) {
        ((unsafe: *from) = pattern)

        return 106

    }

    var __ci_expr_logic_0: c_int

    if ((if (unsafe: *pattern) == 33: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe: *pattern) == 94: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (pattern = pattern + 1)

        if ((if pattern >= pattern_end: 1 else: 0) != 0) {
            ((unsafe: *from) = pattern)

            return 106

        }

        (is_negative = 1)

        (out.out_str[0] = 91)

        (out.out_str[1] = 94)

        (len = 2)

        if ((if not (no_wildsep != 0): 1 else: 0) != 0) {
            if (with_escape != 0) {
                (out.out_str[len] = 92)

                (len = len + 1)

            }

            (out.out_str[len] = separator)

        }

        convert_glob_write_str(out, (len + 1))

    } else {
        convert_glob_write(out, 91)
    }


    (has_prev_c = 0)

    (prev_c = 0)

    if ((if (unsafe: *pattern) == 93: 1 else: 0) != 0) {
        (out.out_str[0] = 92)

        (out.out_str[1] = 93)

        convert_glob_write_str(out, 2)

        (has_prev_c = 1)

        (prev_c = 93)

        (pattern = pattern + 1)

    }

    while ((if pattern < pattern_end: 1 else: 0) != 0) {
        (char_start = pattern)

        var __ci_expr_old_1: *const u8 = pattern

        (pattern = pattern + 1)

        (c = (unsafe: *__ci_expr_old_1))


        var __ci_expr_logic_2: c_int = 0

        if (utf != 0) {
            (__ci_expr_logic_2 = (if (if c >= 192: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            if ((if (c & 32) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_3: *const u8 = pattern

                (pattern = pattern + 1)

                (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_3) & 63))

            } else {
                if ((if (c & 16) == 0: 1 else: 0) != 0) {
                    (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[1]) & 63))

                    (pattern = pattern + 2)

                } else {
                    if ((if (c & 8) == 0: 1 else: 0) != 0) {
                        (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[2]) & 63))

                        (pattern = pattern + 3)

                    } else {
                        if ((if (c & 4) == 0: 1 else: 0) != 0) {
                            (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[3]) & 63))

                            (pattern = pattern + 4)

                        } else {
                            (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[4]) & 63))

                            (pattern = pattern + 5)

                        }
                    }
                }
            }

        }


        if ((if c == 93: 1 else: 0) != 0) {
            convert_glob_write(out, c)

            var __ci_expr_logic_5: c_int = 0

            var __ci_expr_logic_4: c_int = 0

            if ((if not (is_negative != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if not (no_wildsep != 0): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if separator_seen != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (out.out_str[0] = 40)

                (out.out_str[1] = 63)

                (out.out_str[2] = 60)

                (out.out_str[3] = 33)

                convert_glob_write_str(out, 4)

                convert_glob_print_separator(out, separator, with_escape)

                convert_glob_write(out, 41)

            }


            ((unsafe: *from) = pattern)

            return 0

        }

        if ((if pattern >= pattern_end: 1 else: 0) != 0) {
            break
        }

        var __ci_expr_logic_6: c_int = 0

        if ((if c == 91: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe: *pattern) == 58: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            ((unsafe: *from) = pattern)

            (class_index = convert_glob_parse_class(from, pattern_end, out))

            if ((if class_index != 0: 1 else: 0) != 0) {
                (pattern = (unsafe: *from))

                (has_prev_c = 0)

                (prev_c = 0)

                var __ci_expr_logic_7: c_int = 0

                if ((if not (is_negative != 0): 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if convert_glob_char_in_class(class_index, separator) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_7 != 0) {
                    (separator_seen = 1)
                }


                continue

            }

        } else {
            var __ci_expr_logic_9: c_int = 0

            var __ci_expr_logic_8: c_int = 0

            if ((if c == 45: 1 else: 0) != 0) {
                (__ci_expr_logic_8 = (if has_prev_c != 0: 1 else: 0))
            }

            if (__ci_expr_logic_8 != 0) {
                (__ci_expr_logic_9 = (if (if (unsafe: *pattern) != 93: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_9 != 0) {
                convert_glob_write(out, 45)

                (char_start = pattern)

                var __ci_expr_old_10: *const u8 = pattern

                (pattern = pattern + 1)

                (c = (unsafe: *__ci_expr_old_10))


                var __ci_expr_logic_11: c_int = 0

                if (utf != 0) {
                    (__ci_expr_logic_11 = (if (if c >= 192: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    if ((if (c & 32) == 0: 1 else: 0) != 0) {
                        var __ci_expr_old_12: *const u8 = pattern

                        (pattern = pattern + 1)

                        (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_12) & 63))

                    } else {
                        if ((if (c & 16) == 0: 1 else: 0) != 0) {
                            (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[1]) & 63))

                            (pattern = pattern + 2)

                        } else {
                            if ((if (c & 8) == 0: 1 else: 0) != 0) {
                                (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[2]) & 63))

                                (pattern = pattern + 3)

                            } else {
                                if ((if (c & 4) == 0: 1 else: 0) != 0) {
                                    (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[3]) & 63))

                                    (pattern = pattern + 4)

                                } else {
                                    (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[4]) & 63))

                                    (pattern = pattern + 5)

                                }
                            }
                        }
                    }

                }


                if ((if pattern >= pattern_end: 1 else: 0) != 0) {
                    break
                }

                var __ci_expr_logic_13: c_int = 0

                if ((if escape != 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_13 = (if (if c == escape: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_13 != 0) {
                    (char_start = pattern)

                    var __ci_expr_old_14: *const u8 = pattern

                    (pattern = pattern + 1)

                    (c = (unsafe: *__ci_expr_old_14))


                    var __ci_expr_logic_15: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_15 = (if (if c >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_15 != 0) {
                        if ((if (c & 32) == 0: 1 else: 0) != 0) {
                            var __ci_expr_old_16: *const u8 = pattern

                            (pattern = pattern + 1)

                            (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_16) & 63))

                        } else {
                            if ((if (c & 16) == 0: 1 else: 0) != 0) {
                                (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[1]) & 63))

                                (pattern = pattern + 2)

                            } else {
                                if ((if (c & 8) == 0: 1 else: 0) != 0) {
                                    (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[2]) & 63))

                                    (pattern = pattern + 3)

                                } else {
                                    if ((if (c & 4) == 0: 1 else: 0) != 0) {
                                        (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[3]) & 63))

                                        (pattern = pattern + 4)

                                    } else {
                                        (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[4]) & 63))

                                        (pattern = pattern + 5)

                                    }
                                }
                            }
                        }

                    }


                } else {
                    var __ci_expr_logic_17: c_int = 0

                    if ((if c == 91: 1 else: 0) != 0) {
                        (__ci_expr_logic_17 = (if (if (unsafe: *pattern) == 58: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_17 != 0) {
                        ((unsafe: *from) = pattern)

                        return -64

                    }

                }


                if ((if prev_c > c: 1 else: 0) != 0) {
                    ((unsafe: *from) = pattern)

                    return -64

                }

                var __ci_expr_logic_18: c_int = 0

                if ((if prev_c < separator: 1 else: 0) != 0) {
                    (__ci_expr_logic_18 = (if (if separator < c: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_18 != 0) {
                    (separator_seen = 1)
                }


                (has_prev_c = 0)

                (prev_c = 0)

            } else {
                var __ci_expr_logic_19: c_int = 0

                if ((if escape != 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_19 = (if (if c == escape: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_19 != 0) {
                    (char_start = pattern)

                    var __ci_expr_old_20: *const u8 = pattern

                    (pattern = pattern + 1)

                    (c = (unsafe: *__ci_expr_old_20))


                    var __ci_expr_logic_21: c_int = 0

                    if (utf != 0) {
                        (__ci_expr_logic_21 = (if (if c >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_21 != 0) {
                        if ((if (c & 32) == 0: 1 else: 0) != 0) {
                            var __ci_expr_old_22: *const u8 = pattern

                            (pattern = pattern + 1)

                            (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_22) & 63))

                        } else {
                            if ((if (c & 16) == 0: 1 else: 0) != 0) {
                                (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[1]) & 63))

                                (pattern = pattern + 2)

                            } else {
                                if ((if (c & 8) == 0: 1 else: 0) != 0) {
                                    (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[2]) & 63))

                                    (pattern = pattern + 3)

                                } else {
                                    if ((if (c & 4) == 0: 1 else: 0) != 0) {
                                        (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[3]) & 63))

                                        (pattern = pattern + 4)

                                    } else {
                                        (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *pattern) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: pattern[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: pattern[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: pattern[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: pattern[4]) & 63))

                                        (pattern = pattern + 5)

                                    }
                                }
                            }
                        }

                    }


                    if ((if pattern >= pattern_end: 1 else: 0) != 0) {
                        break
                    }

                }


                (has_prev_c = 1)

                (prev_c = c)

            }

        }


        var __ci_expr_logic_25: c_int

        var __ci_expr_logic_24: c_int

        var __ci_expr_logic_23: c_int

        if ((if c == 91: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_23 = (if (if c == 93: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_23 != 0) {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if (if c == 92: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_24 != 0) {
            (__ci_expr_logic_25 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_25 = (if (if c == 45: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_25 != 0) {
            convert_glob_write(out, 92)
        }


        if ((if c == separator: 1 else: 0) != 0) {
            (separator_seen = 1)
        }

        while true {
            var __ci_expr_old_26: *const u8 = char_start

            (char_start = char_start + 1)

            convert_glob_write(out, (unsafe: *__ci_expr_old_26))

            if (not ((if char_start < pattern: 1 else: 0) != 0)) {
                break
            }

        }

    }

    ((unsafe: *from) = pattern)

    return 106

}

fn convert_glob_print_commit(out: *mut pcre2_output_context) {
    (out.out_str[0] = 40)

    (out.out_str[1] = 42)

    (out.out_str[2] = 67)

    (out.out_str[3] = 79)

    (out.out_str[4] = 77)

    (out.out_str[5] = 77)

    (out.out_str[6] = 73)

    (out.out_str[7] = 84)

    convert_glob_write_str(out, 8)

    convert_glob_write(out, 41)

}

fn convert_glob(options: c_uint, __param_pattern: *const u8, plength: c_ulong, utf: c_int, use_buffer: *mut u8, use_length: c_ulong, bufflenptr: *mut c_ulong, dummyrun: c_int, ccontext: *mut pcre2_real_convert_context_8) -> c_int {
    var pattern = __param_pattern
    var out: pcre2_output_context

    var pattern_start: *const u8 = pattern

    var pattern_end: *const u8 = (pattern + plength)

    var separator: u8 = ccontext.glob_separator

    var escape: u8 = ccontext.glob_escape

    var c: u8

    var no_wildsep: c_int = (if (options & 48) != 0: 1 else: 0)

    var no_starstar: c_int = (if (options & 80) != 0: 1 else: 0)

    var in_atomic: c_int = 0

    var after_starstar: c_int = 0

    var no_slash_z: c_int = 0

    var with_escape: c_int

    var is_start: c_int

    var after_separator: c_int


    var result: c_int = 0

    utf

    var __ci_expr_logic_1: c_int = 0

    if (utf != 0) {
        var __ci_expr_logic_0: c_int

        if ((if separator >= 128: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if escape >= 128: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        ((unsafe: *bufflenptr) = 0)

        return -64

    }


    (with_escape = (if string_find_char(pcre2_escaped_literals, separator) != null: 1 else: 0))

    (out.output = use_buffer)

    (out.output_end = use_buffer + use_length)

    (out.output_size = 0)

    (out.out_str[0] = 40)

    (out.out_str[1] = 63)

    (out.out_str[2] = 115)

    (out.out_str[3] = 41)

    convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 4)

    (is_start = 1)

    var __ci_expr_logic_2: c_int = 0

    if ((if pattern < pattern_end: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (unsafe: pattern[0]) == 42: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        if (no_wildsep != 0) {
            (is_start = 0)
        } else {
            var __ci_expr_logic_4: c_int = 0

            var __ci_expr_logic_3: c_int = 0

            if ((if not (no_starstar != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if (pattern + ((1 as isize) as usize)) < pattern_end: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if (if (unsafe: pattern[1]) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (is_start = 0)
            }

        }

    }


    if (is_start != 0) {
        (out.out_str[0] = 92)

        (out.out_str[1] = 65)

        convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 2)

    }

    while ((if pattern < pattern_end: 1 else: 0) != 0) {
        var __ci_expr_old_5: *const u8 = pattern

        (pattern = pattern + 1)

        (c = (unsafe: *__ci_expr_old_5))


        if ((if c == 42: 1 else: 0) != 0) {
            (is_start = (if pattern == (pattern_start + ((1 as isize) as usize)): 1 else: 0))

            if (in_atomic != 0) {
                convert_glob_write((&raw mut out as *mut pcre2_output_context), 41)

                (in_atomic = 0)

            }

            var __ci_expr_logic_7: c_int = 0

            var __ci_expr_logic_6: c_int = 0

            if ((if not (no_starstar != 0): 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if pattern < pattern_end: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                (__ci_expr_logic_7 = (if (if (unsafe: *pattern) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_7 != 0) {
                var __ci_expr_logic_8: c_int

                if (is_start != 0) {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_8 = (if (if (unsafe: pattern[-2]) == separator: 1 else: 0) != 0: 1 else: 0))
                }

                (after_separator = __ci_expr_logic_8)


                while true {
                    (pattern = pattern + 1)

                    var __ci_expr_logic_9: c_int = 0

                    if ((if pattern < pattern_end: 1 else: 0) != 0) {
                        (__ci_expr_logic_9 = (if (if (unsafe: *pattern) == 42: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (not (__ci_expr_logic_9 != 0)) {
                        break
                    }

                }

                if ((if pattern >= pattern_end: 1 else: 0) != 0) {
                    (no_slash_z = 1)

                    break

                }

                (after_starstar = 1)

                var __ci_expr_logic_13: c_int = 0

                var __ci_expr_logic_12: c_int = 0

                var __ci_expr_logic_11: c_int = 0

                var __ci_expr_logic_10: c_int = 0

                if (after_separator != 0) {
                    (__ci_expr_logic_10 = (if (if escape != 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_10 != 0) {
                    (__ci_expr_logic_11 = (if (if (unsafe: *pattern) == escape: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_11 != 0) {
                    (__ci_expr_logic_12 = (if (if (pattern + ((1 as isize) as usize)) < pattern_end: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_12 != 0) {
                    (__ci_expr_logic_13 = (if (if (unsafe: pattern[1]) == separator: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_13 != 0) {
                    (pattern = pattern + 1)
                }


                if (is_start != 0) {
                    if ((if (unsafe: *pattern) != separator: 1 else: 0) != 0) {
                        continue
                    }

                    (out.out_str[0] = 40)

                    (out.out_str[1] = 63)

                    (out.out_str[2] = 58)

                    (out.out_str[3] = 92)

                    (out.out_str[4] = 65)

                    (out.out_str[5] = 124)

                    convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 6)

                    convert_glob_print_separator((&raw mut out as *mut pcre2_output_context), separator, with_escape)

                    convert_glob_write((&raw mut out as *mut pcre2_output_context), 41)

                    (pattern = pattern + 1)

                    continue

                }

                convert_glob_print_commit((&raw mut out as *mut pcre2_output_context))

                var __ci_expr_logic_14: c_int

                if ((if not (after_separator != 0): 1 else: 0) != 0) {
                    (__ci_expr_logic_14 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_14 = (if (if (unsafe: *pattern) != separator: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_14 != 0) {
                    (out.out_str[0] = 46)

                    (out.out_str[1] = 42)

                    (out.out_str[2] = 63)

                    convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 3)

                    continue

                }


                (out.out_str[0] = 40)

                (out.out_str[1] = 63)

                (out.out_str[2] = 58)

                (out.out_str[3] = 46)

                (out.out_str[4] = 42)

                (out.out_str[5] = 63)

                convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 6)

                convert_glob_print_separator((&raw mut out as *mut pcre2_output_context), separator, with_escape)

                (out.out_str[0] = 41)

                (out.out_str[1] = 63)

                (out.out_str[2] = 63)

                convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 3)

                (pattern = pattern + 1)

                continue

            }


            var __ci_expr_logic_15: c_int = 0

            if ((if pattern < pattern_end: 1 else: 0) != 0) {
                (__ci_expr_logic_15 = (if (if (unsafe: *pattern) == 42: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_15 != 0) {
                while true {
                    (pattern = pattern + 1)

                    var __ci_expr_logic_16: c_int = 0

                    if ((if pattern < pattern_end: 1 else: 0) != 0) {
                        (__ci_expr_logic_16 = (if (if (unsafe: *pattern) == 42: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (not (__ci_expr_logic_16 != 0)) {
                        break
                    }

                }

            }


            if (no_wildsep != 0) {
                if ((if pattern >= pattern_end: 1 else: 0) != 0) {
                    (no_slash_z = 1)

                    break

                }

                if (is_start != 0) {
                    continue
                }

            }

            if ((if not (is_start != 0): 1 else: 0) != 0) {
                if (after_starstar != 0) {
                    (out.out_str[0] = 40)

                    (out.out_str[1] = 63)

                    (out.out_str[2] = 62)

                    convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 3)

                    (in_atomic = 1)

                } else {
                    convert_glob_print_commit((&raw mut out as *mut pcre2_output_context))
                }

            }

            if (no_wildsep != 0) {
                convert_glob_write((&raw mut out as *mut pcre2_output_context), 46)
            } else {
                convert_glob_print_wildcard((&raw mut out as *mut pcre2_output_context), separator, with_escape)
            }

            (out.out_str[0] = 42)

            (out.out_str[1] = 63)

            if ((if pattern >= pattern_end: 1 else: 0) != 0) {
                (out.out_str[1] = 43)
            }

            convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 2)

            continue

        }

        if ((if c == 63: 1 else: 0) != 0) {
            if (no_wildsep != 0) {
                convert_glob_write((&raw mut out as *mut pcre2_output_context), 46)
            } else {
                convert_glob_print_wildcard((&raw mut out as *mut pcre2_output_context), separator, with_escape)
            }

            continue

        }

        if ((if c == 91: 1 else: 0) != 0) {
            (result = convert_glob_parse_range((&raw mut pattern as *mut *const u8), pattern_end, (&raw mut out as *mut pcre2_output_context), utf, separator, with_escape, escape, no_wildsep))

            if ((if result != 0: 1 else: 0) != 0) {
                break
            }

            continue

        }

        var __ci_expr_logic_17: c_int = 0

        if ((if escape != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if c == escape: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_17 != 0) {
            if ((if pattern >= pattern_end: 1 else: 0) != 0) {
                (result = -64)

                break

            }

            var __ci_expr_old_18: *const u8 = pattern

            (pattern = pattern + 1)

            (c = (unsafe: *__ci_expr_old_18))


        }


        var __ci_expr_logic_19: c_int = 0

        if ((if c < 255: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if (if string_find_char(pcre2_escaped_literals, c) != null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_19 != 0) {
            convert_glob_write((&raw mut out as *mut pcre2_output_context), 92)
        }


        convert_glob_write((&raw mut out as *mut pcre2_output_context), c)

    }

    if ((if result == 0: 1 else: 0) != 0) {
        if ((if not (no_slash_z != 0): 1 else: 0) != 0) {
            (out.out_str[0] = 92)

            (out.out_str[1] = 122)

            convert_glob_write_str((&raw mut out as *mut pcre2_output_context), 2)

        }

        if (in_atomic != 0) {
            convert_glob_write((&raw mut out as *mut pcre2_output_context), 41)
        }

        convert_glob_write((&raw mut out as *mut pcre2_output_context), 0)

        var __ci_expr_logic_20: c_int = 0

        if ((if not (dummyrun != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if out.output_size != (((((out.output as usize) -% (use_buffer as usize)) / sizeof[u8]()) as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_20 != 0) {
            (result = -48)
        }


    }

    if ((if result != 0: 1 else: 0) != 0) {
        ((unsafe: *bufflenptr) = ((pattern as usize) -% (pattern_start as usize)) / sizeof[u8]())

        return result

    }

    ((unsafe: *bufflenptr) = (out.output_size -% 1))

    return 0

}

var pcre2_escaped_literals: *const i8 = "\x5c\x3f\x2a\x2b\x7c\x2e\x5e\x24\x7b\x7d\x5b\x5d\x28\x29"
var posix_meta_escapes: *const i8 = "\x28\x29\x7b\x7d\x31\x32\x33\x34\x35\x36\x37\x38\x39"
var posix_classes: *const i8 = "\x61\x6c\x70\x68\x61\x3a\x6c\x6f\x77\x65\x72\x3a\x75\x70\x70\x65\x72\x3a\x61\x6c\x6e\x75\x6d\x3a\x61\x73\x63\x69\x69\x3a\x62\x6c\x61\x6e\x6b\x3a\x63\x6e\x74\x72\x6c\x3a\x64\x69\x67\x69\x74\x3a\x67\x72\x61\x70\x68\x3a\x70\x72\x69\x6e\x74\x3a\x70\x75\x6e\x63\x74\x3a\x73\x70\x61\x63\x65\x3a\x77\x6f\x72\x64\x3a\x78\x64\x69\x67\x69\x74\x3a"
