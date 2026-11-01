// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
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
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass
use std.collections

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn _pcre2_script_run_8(__param_ptr: *const u8, __param_endptr: *const u8, __param_utf: i32) -> i32 {
    var __local_ptr = __param_ptr
    var __local_require_state: u32 = ((0 as u32))

    var __local_require_map: List[u32] = [0; 6]

    var __local_map: List[u32] = [0; 6]

    var __local_require_digitset: u32 = ((0 as u32))

    var __local_c: u32

    if (__local_ptr >= __param_endptr) {
        return 1
    }

    var __ci_expr_old_0: *const u8 = __local_ptr

    (__local_ptr = __local_ptr + 1)

    (__local_c = (((*__ci_expr_old_0) as u32)))


    var __ci_expr_logic_1: i32 = 0

    if __param_utf {
        (__ci_expr_logic_1 = (if __local_c >= 192: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        if (((__local_c as u32) & (32 as u32)) == 0) {
            var __ci_expr_old_2: *const u8 = __local_ptr

            (__local_ptr = __local_ptr + 1)

            (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_2) as i32) as u32) & (63 as u32)) as u32)) as u32)))

        } else {
            if (((__local_c as u32) & (16 as u32)) == 0) {
                (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                (__local_ptr = __local_ptr + ((2 as isize) as usize))

            } else {
                if (((__local_c as u32) & (8 as u32)) == 0) {
                    (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    (__local_ptr = __local_ptr + ((3 as isize) as usize))

                } else {
                    if (((__local_c as u32) & (4 as u32)) == 0) {
                        (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_ptr = __local_ptr + ((4 as isize) as usize))

                    } else {
                        (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_ptr = __local_ptr + ((5 as isize) as usize))

                    }
                }
            }
        }

    }




    if (__local_ptr >= __param_endptr) {
        return 1
    }

    var __local_i: i32 = ((0 as i32))

    while (__local_i < ((ucp_Script_Count / 32) + 1)) {
        (__local_require_map[__local_i] = ((0 as u32)))

        (__local_i = __local_i + 1)

    }


    while true {
        var __local_ucd: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as i32) / 128)] as i32) * 128) + ((__local_c as i32) % 128))] as u32) as usize))

        var __local_script: u32 = (((*__local_ucd).script as u32))

        if (__local_script == 98) {
            return 0
        }

        var __ci_expr_logic_4: i32

        if ((((*__local_ucd).scriptx_bidiclass as i32) & (1023 as i32)) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_3: i32 = 0

            if (__local_script != 106) {
                (__ci_expr_logic_3 = (if __local_script != 99: 1 else: 0))
            }

            (__ci_expr_logic_4 = (if __ci_expr_logic_3: 1 else: 0))

        }

        if __ci_expr_logic_4 {
            var __local_OK: i32

            with_memcpy(((&__local_map[0] as *mut u32) as *mut u8), ((((&_pcre2_ucd_script_sets_8[0] as *const u32) + (((((*__local_ucd).scriptx_bidiclass as i32) & (1023 as i32)) as isize) as usize)) as *const c_void) as *const u8), ((((4 as u64) *% (sizeof[u32]() as u64)) as u64) as i64))

            with_memset(((((&__local_map[0] as *mut u32) + ((((ucp_Unknown / 32) + 1) as isize) as usize)) as *mut c_void) as *mut u8), (0 as i32), ((((2 as u64) *% (sizeof[u32]() as u64)) as u64) as i64))

            var __ci_expr_logic_5: i32 = 0

            if (__local_script != 99) {
                (__ci_expr_logic_5 = (if __local_script != 106: 1 else: 0))
            }

            if __ci_expr_logic_5 {
                (__local_map[((__local_script as u32) / (32 as u32))] = (__local_map[((__local_script as u32) / (32 as u32))] as u32) | (((1 as u32) << (((__local_script as u32) % (32 as u32)) as u32)) as u32))
            }


            while true {
                match __local_require_state {
                    0 => {
                        while true {
                            match __local_script {
                                30 => {
                                    (__local_require_state = ((2 as u32)))
                                },
                                27 => {
                                    (__local_require_state = ((3 as u32)))
                                },
                                28 => {
                                    (__local_require_state = ((3 as u32)))
                                },
                                29 => {
                                    (__local_require_state = ((4 as u32)))
                                },
                                22 => {
                                    (__local_require_state = ((5 as u32)))
                                },
                                _ => {
                                    with_memcpy(((&__local_require_map[0] as *mut u32) as *mut u8), ((&__local_map[0] as *mut u32) as *const u8), ((((6 as u64) *% (sizeof[u32]() as u64)) as u64) as i64))

                                    (__local_require_state = ((1 as u32)))

                                },
                            }

                            break

                        }
                    },
                    2 => {
                        if (__local_script != 30) {
                            var __local_chspecial: u32 = ((0 as u32))

                            if (((__local_map[(ucp_Bopomofo / 32)] as u32) & (((1 as u32) << ((ucp_Bopomofo % 32) as u32)) as u32)) != 0) {
                                (__local_chspecial = (__local_chspecial as u32) | (1 as u32))
                            }

                            if (((__local_map[(ucp_Hiragana / 32)] as u32) & (((1 as u32) << ((ucp_Hiragana % 32) as u32)) as u32)) != 0) {
                                (__local_chspecial = (__local_chspecial as u32) | (2 as u32))
                            }

                            if (((__local_map[(ucp_Katakana / 32)] as u32) & (((1 as u32) << ((ucp_Katakana % 32) as u32)) as u32)) != 0) {
                                (__local_chspecial = (__local_chspecial as u32) | (4 as u32))
                            }

                            if (((__local_map[(ucp_Hangul / 32)] as u32) & (((1 as u32) << ((ucp_Hangul % 32) as u32)) as u32)) != 0) {
                                (__local_chspecial = (__local_chspecial as u32) | (8 as u32))
                            }

                            if (__local_chspecial == 0) {
                                return 0
                            }

                            if (__local_chspecial == 1) {
                                (__local_require_state = ((4 as u32)))
                            } else {
                                if (__local_chspecial == 6) {
                                    (__local_require_state = ((3 as u32)))
                                }
                            }

                        }
                    },
                    3 => {
                        if (((((((__local_map[(ucp_Han / 32)] as u32) & (((1 as u32) << ((ucp_Han % 32) as u32)) as u32)) as u32) +% (((__local_map[(ucp_Hiragana / 32)] as u32) & (((1 as u32) << ((ucp_Hiragana % 32) as u32)) as u32)) as u32)) as u32) +% (((__local_map[(ucp_Katakana / 32)] as u32) & (((1 as u32) << ((ucp_Katakana % 32) as u32)) as u32)) as u32)) == 0) {
                            return 0
                        }
                    },
                    4 => {
                        if (((((__local_map[(ucp_Han / 32)] as u32) & (((1 as u32) << ((ucp_Han % 32) as u32)) as u32)) as u32) +% (((__local_map[(ucp_Bopomofo / 32)] as u32) & (((1 as u32) << ((ucp_Bopomofo % 32) as u32)) as u32)) as u32)) == 0) {
                            return 0
                        }
                    },
                    5 => {
                        if (((((__local_map[(ucp_Han / 32)] as u32) & (((1 as u32) << ((ucp_Han % 32) as u32)) as u32)) as u32) +% (((__local_map[(ucp_Hangul / 32)] as u32) & (((1 as u32) << ((ucp_Hangul % 32) as u32)) as u32)) as u32)) == 0) {
                            return 0
                        }
                    },
                    1 => {
                        (__local_OK = ((0 as i32)))

                        var __local_i_1: i32 = ((0 as i32))

                        while (__local_i_1 < ((ucp_Script_Count / 32) + 1)) {
                            if (((__local_require_map[__local_i_1] as u32) & (__local_map[__local_i_1] as u32)) != 0) {
                                (__local_OK = ((1 as i32)))

                                break

                            }


                            (__local_i_1 = __local_i_1 + 1)

                        }


                        if (not __local_OK) {
                            return 0
                        }

                        while true {
                            match __local_script {
                                30 => {
                                    (__local_require_state = ((2 as u32)))
                                },
                                27 => {
                                    (__local_require_state = ((3 as u32)))
                                },
                                28 => {
                                    (__local_require_state = ((3 as u32)))
                                },
                                29 => {
                                    (__local_require_state = ((4 as u32)))
                                },
                                22 => {
                                    (__local_require_state = ((5 as u32)))
                                },
                                _ => {
                                    var __local_i_2: i32 = ((0 as i32))

                                    while (__local_i_2 < ((ucp_Script_Count / 32) + 1)) {
                                        (__local_require_map[__local_i_2] = (__local_require_map[__local_i_2] as u32) & (__local_map[__local_i_2] as u32))

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


        if ((*__local_ucd).chartype == ucp_Nd) {
            var __local_digitset: u32

            if (__local_c <= _pcre2_ucd_digit_sets_8[1]) {
                (__local_digitset = ((1 as u32)))
            } else {
                var __local_mid: i32

                var __local_bot: i32 = ((1 as i32))

                var __local_top: i32 = ((_pcre2_ucd_digit_sets_8[0] as i32))

                while true {
                    if (__local_top <= (__local_bot + 1)) {
                        (__local_digitset = ((__local_top as u32)))

                        break

                    }

                    (__local_mid = ((((__local_top + __local_bot) / 2) as i32)))

                    if (__local_c <= _pcre2_ucd_digit_sets_8[__local_mid]) {
                        (__local_top = __local_mid)
                    } else {
                        (__local_bot = __local_mid)
                    }

                }

            }

            if (__local_require_digitset == 0) {
                (__local_require_digitset = __local_digitset)
            } else {
                if (__local_digitset != __local_require_digitset) {
                    return 0
                }
            }

        }

        if (__local_ptr >= __param_endptr) {
            return 1
        }

        var __ci_expr_old_9: *const u8 = __local_ptr

        (__local_ptr = __local_ptr + 1)

        (__local_c = (((*__ci_expr_old_9) as u32)))


        var __ci_expr_logic_10: i32 = 0

        if __param_utf {
            (__ci_expr_logic_10 = (if __local_c >= 192: 1 else: 0))
        }

        if __ci_expr_logic_10 {
            if (((__local_c as u32) & (32 as u32)) == 0) {
                var __ci_expr_old_11: *const u8 = __local_ptr

                (__local_ptr = __local_ptr + 1)

                (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((*__ci_expr_old_11) as i32) as u32) & (63 as u32)) as u32)) as u32)))

            } else {
                if (((__local_c as u32) & (16 as u32)) == 0) {
                    (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    (__local_ptr = __local_ptr + ((2 as isize) as usize))

                } else {
                    if (((__local_c as u32) & (8 as u32)) == 0) {
                        (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_ptr = __local_ptr + ((3 as isize) as usize))

                    } else {
                        if (((__local_c as u32) & (4 as u32)) == 0) {
                            (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_ptr = __local_ptr + ((4 as isize) as usize))

                        } else {
                            (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((*__local_ptr) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_ptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_ptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_ptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_ptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_ptr = __local_ptr + ((5 as isize) as usize))

                        }
                    }
                }
            }

        }




    }

}
