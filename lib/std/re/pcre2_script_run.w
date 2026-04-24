// Migrated from PCRE2
use std.re.defs

fn _pcre2_script_run_8(__param_ptr: *const u8, endptr: *const u8, utf: c_int) -> c_int {
    var ptr = __param_ptr
    var require_state: c_uint = 0

    var require_map: [6]c_uint

    var map: [6]c_uint

    var require_digitset: c_uint = 0

    var c: c_uint

    if ((if ptr >= endptr: 1 else: 0) != 0) {
        return 1
    }

    var __ci_expr_old_0: *const u8 = ptr

    (ptr = ptr + 1)

    (c = (unsafe: *__ci_expr_old_0))


    var __ci_expr_logic_1: c_int = 0

    if (utf != 0) {
        (__ci_expr_logic_1 = (if (if c >= 192: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        if ((if (c & 32) == 0: 1 else: 0) != 0) {
            var __ci_expr_old_2: *const u8 = ptr

            (ptr = ptr + 1)

            (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_2) & 63))

        } else {
            if ((if (c & 16) == 0: 1 else: 0) != 0) {
                (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[1]) & 63))

                (ptr = ptr + 2)

            } else {
                if ((if (c & 8) == 0: 1 else: 0) != 0) {
                    (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[2]) & 63))

                    (ptr = ptr + 3)

                } else {
                    if ((if (c & 4) == 0: 1 else: 0) != 0) {
                        (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[3]) & 63))

                        (ptr = ptr + 4)

                    } else {
                        (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: ptr[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[4]) & 63))

                        (ptr = ptr + 5)

                    }
                }
            }
        }

    }


    if ((if ptr >= endptr: 1 else: 0) != 0) {
        return 1
    }

    var i: c_int = 0

    while ((if i < ((ucp_Script_Count / 32) + 1): 1 else: 0) != 0) {
        (require_map[i] = 0)

        (i = i + 1)

    }


    while true {
        var ucd: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize))

        var script: c_uint = ucd.script

        if ((if script == 99: 1 else: 0) != 0) {
            return 0
        }

        var __ci_expr_logic_4: c_int

        if ((if (ucd.scriptx_bidiclass & 1023) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_3: c_int = 0

            if ((if script != 107: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if script != 100: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_4 != 0) {
            var OK: c_int

            with_memcpy(((&map[0] as *mut c_uint) as *i8), (((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + (((ucd.scriptx_bidiclass & 1023) as isize) as usize)) as *i8), ((4 *% sizeof[c_uint]()) as i64))

            with_memset((((&map[0] as *mut c_uint) + ((((ucp_Unknown / 32) + 1) as isize) as usize)) as *i8), 0, ((2 *% sizeof[c_uint]()) as i64))

            var __ci_expr_logic_5: c_int = 0

            if ((if script != 100: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if (if script != 107: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                (map[(script / 32)] = map[(script / 32)] | ((1 as c_uint) << ((script % 32) as c_uint)))
            }


            match require_state {
                0 => {
                    match script {
                        30 => {
                            (require_state = 2)
                        },
                        27 | 28 => {
                            (require_state = 3)
                        },
                        29 => {
                            (require_state = 4)
                        },
                        22 => {
                            (require_state = 5)
                        },
                        _ => {
                            with_memcpy(((&require_map[0] as *mut c_uint) as *i8), ((&map[0] as *mut c_uint) as *i8), ((6 *% sizeof[c_uint]()) as i64))

                            (require_state = 1)

                        },
                    }
                },
                2 => {
                    if ((if script != 30: 1 else: 0) != 0) {
                        var chspecial: c_uint = 0

                        if ((if (map[(ucp_Bopomofo / 32)] & ((1 as c_uint) << ((ucp_Bopomofo % 32) as c_uint))) != 0: 1 else: 0) != 0) {
                            (chspecial = chspecial | 1)
                        }

                        if ((if (map[(ucp_Hiragana / 32)] & ((1 as c_uint) << ((ucp_Hiragana % 32) as c_uint))) != 0: 1 else: 0) != 0) {
                            (chspecial = chspecial | 2)
                        }

                        if ((if (map[(ucp_Katakana / 32)] & ((1 as c_uint) << ((ucp_Katakana % 32) as c_uint))) != 0: 1 else: 0) != 0) {
                            (chspecial = chspecial | 4)
                        }

                        if ((if (map[(ucp_Hangul / 32)] & ((1 as c_uint) << ((ucp_Hangul % 32) as c_uint))) != 0: 1 else: 0) != 0) {
                            (chspecial = chspecial | 8)
                        }

                        if ((if chspecial == 0: 1 else: 0) != 0) {
                            return 0
                        }

                        if ((if chspecial == 1: 1 else: 0) != 0) {
                            (require_state = 4)
                        } else {
                            if ((if chspecial == 6: 1 else: 0) != 0) {
                                (require_state = 3)
                            }
                        }

                    }
                },
                3 => {
                    if ((if (((map[(ucp_Han / 32)] & ((1 as c_uint) << ((ucp_Han % 32) as c_uint))) +% (map[(ucp_Hiragana / 32)] & ((1 as c_uint) << ((ucp_Hiragana % 32) as c_uint)))) +% (map[(ucp_Katakana / 32)] & ((1 as c_uint) << ((ucp_Katakana % 32) as c_uint)))) == 0: 1 else: 0) != 0) {
                        return 0
                    }
                },
                4 => {
                    if ((if ((map[(ucp_Han / 32)] & ((1 as c_uint) << ((ucp_Han % 32) as c_uint))) +% (map[(ucp_Bopomofo / 32)] & ((1 as c_uint) << ((ucp_Bopomofo % 32) as c_uint)))) == 0: 1 else: 0) != 0) {
                        return 0
                    }
                },
                5 => {
                    if ((if ((map[(ucp_Han / 32)] & ((1 as c_uint) << ((ucp_Han % 32) as c_uint))) +% (map[(ucp_Hangul / 32)] & ((1 as c_uint) << ((ucp_Hangul % 32) as c_uint)))) == 0: 1 else: 0) != 0) {
                        return 0
                    }
                },
                1 => {
                    (OK = 0)

                    var i_1: c_int = 0

                    while ((if i_1 < ((ucp_Script_Count / 32) + 1): 1 else: 0) != 0) {
                        if ((if (require_map[i_1] & map[i_1]) != 0: 1 else: 0) != 0) {
                            (OK = 1)

                            break

                        }


                        (i_1 = i_1 + 1)

                    }


                    if ((if not (OK != 0): 1 else: 0) != 0) {
                        return 0
                    }

                    match script {
                        30 => {
                            (require_state = 2)
                        },
                        27 | 28 => {
                            (require_state = 3)
                        },
                        29 => {
                            (require_state = 4)
                        },
                        22 => {
                            (require_state = 5)
                        },
                        _ => {
                            var i_2: c_int = 0

                            while ((if i_2 < ((ucp_Script_Count / 32) + 1): 1 else: 0) != 0) {
                                (require_map[i_2] = require_map[i_2] & map[i_2])

                                (i_2 = i_2 + 1)

                            }

                        },
                    }

                },
            }

        }


        if ((if ucd.chartype == ucp_Nd: 1 else: 0) != 0) {
            var digitset: c_uint

            if ((if c <= _pcre2_ucd_digit_sets_8[1]: 1 else: 0) != 0) {
                (digitset = 1)
            } else {
                var mid: c_int

                var bot: c_int = 1

                var top: c_int = _pcre2_ucd_digit_sets_8[0]

                while true {
                    if ((if top <= (bot + 1): 1 else: 0) != 0) {
                        (digitset = top)

                        break

                    }

                    (mid = (top + bot) / 2)

                    if ((if c <= _pcre2_ucd_digit_sets_8[mid]: 1 else: 0) != 0) {
                        (top = mid)
                    } else {
                        (bot = mid)
                    }

                }

            }

            if ((if require_digitset == 0: 1 else: 0) != 0) {
                (require_digitset = digitset)
            } else {
                if ((if digitset != require_digitset: 1 else: 0) != 0) {
                    return 0
                }
            }

        }

        if ((if ptr >= endptr: 1 else: 0) != 0) {
            return 1
        }

        var __ci_expr_old_6: *const u8 = ptr

        (ptr = ptr + 1)

        (c = (unsafe: *__ci_expr_old_6))


        var __ci_expr_logic_7: c_int = 0

        if (utf != 0) {
            (__ci_expr_logic_7 = (if (if c >= 192: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_7 != 0) {
            if ((if (c & 32) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_8: *const u8 = ptr

                (ptr = ptr + 1)

                (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_8) & 63))

            } else {
                if ((if (c & 16) == 0: 1 else: 0) != 0) {
                    (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[1]) & 63))

                    (ptr = ptr + 2)

                } else {
                    if ((if (c & 8) == 0: 1 else: 0) != 0) {
                        (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[2]) & 63))

                        (ptr = ptr + 3)

                    } else {
                        if ((if (c & 4) == 0: 1 else: 0) != 0) {
                            (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[3]) & 63))

                            (ptr = ptr + 4)

                        } else {
                            (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *ptr) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: ptr[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[4]) & 63))

                            (ptr = ptr + 5)

                        }
                    }
                }
            }

        }


    }

}
