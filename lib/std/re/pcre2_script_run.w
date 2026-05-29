// Migrated from PCRE2
use std.re.defs

fn _pcre2_script_run_8(__param_ptr: *const u8, __param_endptr: *const u8, __param_utf: c_int) -> c_int {
    var __local_ptr = __param_ptr
    var __local_require_state: c_uint = 0

    var __local_require_map: [6]c_uint

    var __local_map: [6]c_uint

    var __local_require_digitset: c_uint = 0

    var __local_c: c_uint

    if ((if __local_ptr >= __param_endptr: 1 else: 0) != 0) {
        return 1
    }

    var __ci_expr_old_0: *const u8 = __local_ptr

    (__local_ptr = __local_ptr + 1)

    (__local_c = (unsafe *__ci_expr_old_0))


    var __ci_expr_logic_1: c_int = 0

    if (__param_utf != 0) {
        (__ci_expr_logic_1 = (if (if __local_c >= 192: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            var __ci_expr_old_2: *const u8 = __local_ptr

            (__local_ptr = __local_ptr + 1)

            (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_2) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

        } else {
            if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                (__local_ptr = __local_ptr + ((2 as isize) as usize))

            } else {
                if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    (__local_ptr = __local_ptr + ((3 as isize) as usize))

                } else {
                    if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_ptr = __local_ptr + ((4 as isize) as usize))

                    } else {
                        (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_ptr = __local_ptr + ((5 as isize) as usize))

                    }
                }
            }
        }

    }


    if ((if __local_ptr >= __param_endptr: 1 else: 0) != 0) {
        return 1
    }

    var __local_i: c_int = 0

    while ((if __local_i < ((ucp_Script_Count / 32) + 1): 1 else: 0) != 0) {
        (__local_require_map[__local_i] = 0)

        (__local_i = __local_i + 1)

    }


    while true {
        var __local_ucd: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize))

        var __local_script: c_uint = __local_ucd.script

        if ((if __local_script == 98: 1 else: 0) != 0) {
            return 0
        }

        var __ci_expr_logic_4: c_int

        if ((if ((__local_ucd.scriptx_bidiclass as c_int) & 1023) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_3: c_int = 0

            if ((if __local_script != 106: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if __local_script != 99: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_4 != 0) {
            var __local_OK: c_int

            with_memcpy(((&__local_map[0] as *mut c_uint) as *i8), (((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + ((((__local_ucd.scriptx_bidiclass as c_int) & 1023) as isize) as usize)) as *i8), (((4 as c_ulong) *% (sizeof[u32]() as c_ulong)) as i64))

            with_memset((((&__local_map[0] as *mut c_uint) + ((((ucp_Unknown / 32) + 1) as isize) as usize)) as *i8), 0, (((2 as c_ulong) *% (sizeof[u32]() as c_ulong)) as i64))

            var __ci_expr_logic_5: c_int = 0

            if ((if __local_script != 99: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if (if __local_script != 106: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (__local_map[((__local_script as c_uint) / (32 as c_uint))] = __local_map[((__local_script as c_uint) / (32 as c_uint))] | ((1 as c_uint) << (((__local_script as c_uint) % (32 as c_uint)) as c_uint)))
            }


            while true {
                match __local_require_state {
                    0 => {
                        while true {
                            match __local_script {
                                30 => {
                                    (__local_require_state = 2)
                                },
                                27 => {
                                    (__local_require_state = 3)
                                },
                                28 => {
                                    (__local_require_state = 3)
                                },
                                29 => {
                                    (__local_require_state = 4)
                                },
                                22 => {
                                    (__local_require_state = 5)
                                },
                                _ => {
                                    with_memcpy(((&__local_require_map[0] as *mut c_uint) as *i8), ((&__local_map[0] as *mut c_uint) as *i8), (((6 as c_ulong) *% (sizeof[u32]() as c_ulong)) as i64))

                                    (__local_require_state = 1)

                                },
                            }

                            break

                        }
                    },
                    2 => {
                        if ((if __local_script != 30: 1 else: 0) != 0) {
                            var __local_chspecial: c_uint = 0

                            if ((if ((__local_map[(ucp_Bopomofo / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Bopomofo % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                                (__local_chspecial = __local_chspecial | 1)
                            }

                            if ((if ((__local_map[(ucp_Hiragana / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Hiragana % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                                (__local_chspecial = __local_chspecial | 2)
                            }

                            if ((if ((__local_map[(ucp_Katakana / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Katakana % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                                (__local_chspecial = __local_chspecial | 4)
                            }

                            if ((if ((__local_map[(ucp_Hangul / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Hangul % 32) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                                (__local_chspecial = __local_chspecial | 8)
                            }

                            if ((if __local_chspecial == 0: 1 else: 0) != 0) {
                                return 0
                            }

                            if ((if __local_chspecial == 1: 1 else: 0) != 0) {
                                (__local_require_state = 4)
                            } else {
                                if ((if __local_chspecial == 6: 1 else: 0) != 0) {
                                    (__local_require_state = 3)
                                }
                            }

                        }
                    },
                    3 => {
                        if ((if ((((((__local_map[(ucp_Han / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Han % 32) as c_uint)) as c_uint)) as c_uint) +% (((__local_map[(ucp_Hiragana / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Hiragana % 32) as c_uint)) as c_uint)) as c_uint)) as c_uint) +% (((__local_map[(ucp_Katakana / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Katakana % 32) as c_uint)) as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    4 => {
                        if ((if ((((__local_map[(ucp_Han / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Han % 32) as c_uint)) as c_uint)) as c_uint) +% (((__local_map[(ucp_Bopomofo / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Bopomofo % 32) as c_uint)) as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    5 => {
                        if ((if ((((__local_map[(ucp_Han / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Han % 32) as c_uint)) as c_uint)) as c_uint) +% (((__local_map[(ucp_Hangul / 32)] as c_uint) & (((1 as c_uint) << ((ucp_Hangul % 32) as c_uint)) as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
                            return 0
                        }
                    },
                    1 => {
                        (__local_OK = 0)

                        var __local_i_1: c_int = 0

                        while ((if __local_i_1 < ((ucp_Script_Count / 32) + 1): 1 else: 0) != 0) {
                            if ((if ((__local_require_map[__local_i_1] as c_uint) & (__local_map[__local_i_1] as c_uint)) != 0: 1 else: 0) != 0) {
                                (__local_OK = 1)

                                break

                            }


                            (__local_i_1 = __local_i_1 + 1)

                        }


                        if ((if not (__local_OK != 0): 1 else: 0) != 0) {
                            return 0
                        }

                        while true {
                            match __local_script {
                                30 => {
                                    (__local_require_state = 2)
                                },
                                27 => {
                                    (__local_require_state = 3)
                                },
                                28 => {
                                    (__local_require_state = 3)
                                },
                                29 => {
                                    (__local_require_state = 4)
                                },
                                22 => {
                                    (__local_require_state = 5)
                                },
                                _ => {
                                    var __local_i_2: c_int = 0

                                    while ((if __local_i_2 < ((ucp_Script_Count / 32) + 1): 1 else: 0) != 0) {
                                        (__local_require_map[__local_i_2] = __local_require_map[__local_i_2] & __local_map[__local_i_2])

                                        (__local_i_2 = __local_i_2 + 1)

                                    }

                                },
                            }

                            break

                        }

                    },
                }

                break

            }

        }


        if ((if __local_ucd.chartype == ucp_Nd: 1 else: 0) != 0) {
            var __local_digitset: c_uint

            if ((if __local_c <= _pcre2_ucd_digit_sets_8[1]: 1 else: 0) != 0) {
                (__local_digitset = 1)
            } else {
                var __local_mid: c_int

                var __local_bot: c_int = 1

                var __local_top: c_int = _pcre2_ucd_digit_sets_8[0]

                while true {
                    if ((if __local_top <= (__local_bot + 1): 1 else: 0) != 0) {
                        (__local_digitset = __local_top)

                        break

                    }

                    (__local_mid = (__local_top + __local_bot) / 2)

                    if ((if __local_c <= _pcre2_ucd_digit_sets_8[__local_mid]: 1 else: 0) != 0) {
                        (__local_top = __local_mid)
                    } else {
                        (__local_bot = __local_mid)
                    }

                }

            }

            if ((if __local_require_digitset == 0: 1 else: 0) != 0) {
                (__local_require_digitset = __local_digitset)
            } else {
                if ((if __local_digitset != __local_require_digitset: 1 else: 0) != 0) {
                    return 0
                }
            }

        }

        if ((if __local_ptr >= __param_endptr: 1 else: 0) != 0) {
            return 1
        }

        var __ci_expr_old_9: *const u8 = __local_ptr

        (__local_ptr = __local_ptr + 1)

        (__local_c = (unsafe *__ci_expr_old_9))


        var __ci_expr_logic_10: c_int = 0

        if (__param_utf != 0) {
            (__ci_expr_logic_10 = (if (if __local_c >= 192: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_10 != 0) {
            if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_11: *const u8 = __local_ptr

                (__local_ptr = __local_ptr + 1)

                (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe *__ci_expr_old_11) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

            } else {
                if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                    (__local_ptr = __local_ptr + ((2 as isize) as usize))

                } else {
                    if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_ptr = __local_ptr + ((3 as isize) as usize))

                    } else {
                        if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_ptr = __local_ptr + ((4 as isize) as usize))

                        } else {
                            (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe *__local_ptr) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_ptr = __local_ptr + ((5 as isize) as usize))

                        }
                    }
                }
            }

        }


    }

}
