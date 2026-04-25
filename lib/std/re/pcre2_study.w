// Migrated from PCRE2
use std.re.defs

fn _pcre2_study_8(re: *mut pcre2_real_code_8) -> c_int {
    var count__goto_1917_5: c_int = 0
    var code__goto_1918_14: *mut u8 = null
    var utf__goto_1919_6: c_int = 0
    var ucp__goto_1920_6: c_int = 0
    var depth__goto_1932_7: c_int = 0
    var rc__goto_1933_7: c_int = 0
    var i__goto_1952_9: c_int = 0
    var a__goto_1953_9: c_int = 0
    var b__goto_1954_9: c_int = 0
    var p__goto_1955_14: *mut u8 = null
    var flags__goto_1956_14: c_uint = 0
    var x__goto_1960_15: u8 = 0
    var c__goto_1963_13: c_int = 0
    var y__goto_1964_17: u8 = 0
    var d__goto_1996_15: c_int = 0
    var min__goto_2056_7: c_int = 0
    var backref_cache__goto_2057_7: [129]c_int
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc {
            0 => {
                (__goto_pending = 0)
                (count__goto_1917_5 = 0)
                (utf__goto_1919_6 = (if (re.overall_options & 524288) != 0: 1 else: 0))
                (ucp__goto_1920_6 = (if (re.overall_options & 131072) != 0: 1 else: 0))
                (code__goto_1918_14 = (re as *mut u8) + re.code_start)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if (re.flags & (16 | 512)) == 0: 1 else: 0) != 0) {
                    __pc = 3
                    __goto_pending = 1
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 2
                __goto_pending = 1
                continue
                __pc = 3
                __goto_pending = 1
                continue
            },
            3 => {  // __if_then
                (__goto_pending = 0)
                (depth__goto_1932_7 = 0)
                (rc__goto_1933_7 = set_start_bits(re, code__goto_1918_14, utf__goto_1919_6, ucp__goto_1920_6, (&mut depth__goto_1932_7 as *mut c_int)))
                if ((if rc__goto_1933_7 == SSB_UNKNOWN: 1 else: 0) != 0) {
                    if (__goto_pending != 0) {
                        continue
                    }
                    return 1
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if rc__goto_1933_7 == SSB_DONE: 1 else: 0) != 0) {
                    __pc = 5
                    __goto_pending = 1
                    continue
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 4
                __goto_pending = 1
                continue
                __pc = 5
                __goto_pending = 1
                continue
            },
            5 => {  // __if_then
                (__goto_pending = 0)
                (a__goto_1953_9 = -1)
                (b__goto_1954_9 = -1)
                (p__goto_1955_14 = ((&re.start_bitmap[0] as *mut u8)))
                (flags__goto_1956_14 = 64)
                (i__goto_1952_9 = 0)
                while ((if i__goto_1952_9 < 256: 1 else: 0) != 0) {
                    (x__goto_1960_15 = (unsafe: *p__goto_1955_14))
                    if (__goto_pending != 0) {
                        break
                    }
                    if ((if x__goto_1960_15 != 0: 1 else: 0) != 0) {
                        (y__goto_1964_17 = x__goto_1960_15 & ((~x__goto_1960_15) + 1))
                        if (__goto_pending != 0) {
                            break
                        }
                        if ((if y__goto_1964_17 != x__goto_1960_15: 1 else: 0) != 0) {
                            __pc = 1
                            __goto_pending = 1
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        (c__goto_1963_13 = i__goto_1952_9)
                        if (__goto_pending != 0) {
                            break
                        }
                        match x__goto_1960_15 {
                            1 => {
                                0
                            },
                            2 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 1)
                            },
                            4 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 2)
                            },
                            8 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 3)
                            },
                            16 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 4)
                            },
                            32 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 5)
                            },
                            64 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 6)
                            },
                            128 => {
                                (c__goto_1963_13 = c__goto_1963_13 + 7)
                            },
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        var __ci_expr_logic_0: c_int = 0
                        if (utf__goto_1919_6 != 0) {
                            (__ci_expr_logic_0 = (if (if c__goto_1963_13 > 127: 1 else: 0) != 0: 1 else: 0))
                        }
                        if (__ci_expr_logic_0 != 0) {
                            __pc = 1
                            __goto_pending = 1
                        }
                        if (__goto_pending != 0) {
                            break
                        }
                        if ((if a__goto_1953_9 < 0: 1 else: 0) != 0) {
                            (a__goto_1953_9 = c__goto_1963_13)
                        } else {
                            if ((if b__goto_1954_9 < 0: 1 else: 0) != 0) {
                                (d__goto_1996_15 = (unsafe: (re.tables + ((256 as isize) as usize))[(c__goto_1963_13 as c_uint)]))
                                if (__goto_pending != 0) {
                                    break
                                }
                                var __ci_expr_logic_1: c_int
                                if (utf__goto_1919_6 != 0) {
                                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_1 = (if ucp__goto_1920_6 != 0: 1 else: 0))
                                }
                                if (__ci_expr_logic_1 != 0) {
                                    if ((if ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(c__goto_1963_13 / 128)] * 128) + (c__goto_1963_13 % 128))] as isize) as usize)).caseset != 0: 1 else: 0) != 0) {
                                        __pc = 1
                                        __goto_pending = 1
                                    }
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                    if ((if c__goto_1963_13 > 127: 1 else: 0) != 0) {
                                        (d__goto_1996_15 = (((c__goto_1963_13 + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[(c__goto_1963_13 / 128)] * 128) + (c__goto_1963_13 % 128))] as isize) as usize)).other_case) as c_uint)))
                                    }
                                    if (__goto_pending != 0) {
                                        break
                                    }
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                if ((if d__goto_1996_15 != a__goto_1953_9: 1 else: 0) != 0) {
                                    __pc = 1
                                    __goto_pending = 1
                                }
                                if (__goto_pending != 0) {
                                    break
                                }
                                (b__goto_1954_9 = c__goto_1963_13)
                                if (__goto_pending != 0) {
                                    break
                                }
                            } else {
                                __pc = 1
                                __goto_pending = 1
                            }
                        }
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
                    (p__goto_1955_14 = p__goto_1955_14 + 1)
                    (i__goto_1952_9 = i__goto_1952_9 + 8)
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if a__goto_1953_9 >= 0: 1 else: 0) != 0) {
                    var __ci_expr_logic_4: c_int = 0
                    if ((re.flags & 128) != 0) {
                        var __ci_expr_logic_3: c_int
                        if ((if re.last_codeunit == ((a__goto_1953_9 as c_uint)): 1 else: 0) != 0) {
                            (__ci_expr_logic_3 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_2: c_int = 0
                            if ((if b__goto_1954_9 >= 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_2 = (if (if re.last_codeunit == ((b__goto_1954_9 as c_uint)): 1 else: 0) != 0: 1 else: 0))
                            }
                            (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))
                        }
                        (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_4 != 0) {
                        (re.flags = re.flags & (~(128 | 256)))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (re.last_codeunit = 0)
                        if (__goto_pending != 0) {
                            continue
                        }
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    (re.first_codeunit = a__goto_1953_9)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (flags__goto_1956_14 = 16)
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if b__goto_1954_9 >= 0: 1 else: 0) != 0) {
                        (flags__goto_1956_14 = flags__goto_1956_14 | 32)
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 1
                __goto_pending = 1
                continue
            },
            1 => {  // DONE
                (__goto_pending = 0)
                (re.flags = re.flags | flags__goto_1956_14)
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 4
                __goto_pending = 1
                continue
                __pc = 4
                __goto_pending = 1
                continue
            },
            4 => {  // __after_if
                (__goto_pending = 0)
                __pc = 2
                __goto_pending = 1
                continue
                __pc = 2
                __goto_pending = 1
                continue
            },
            2 => {  // __after_if
                (__goto_pending = 0)
                var __ci_expr_logic_5: c_int = 0
                if ((if (re.flags & (8192 | 8388608)) == 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if re.top_backref <= 128: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_5 != 0) {
                    (backref_cache__goto_2057_7[0] = 0)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (min__goto_2056_7 = find_minlength(re, code__goto_1918_14, code__goto_1918_14, utf__goto_1919_6, null, (&mut count__goto_1917_5 as *mut c_int), (&backref_cache__goto_2057_7[0] as *mut c_int)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    match min__goto_2056_7 {
                        -1 => {
                            0
                        },
                        -2 => {

                            return 2

                        },
                        -3 => {

                            return 3

                        },
                        _ => {
                            var __ci_expr_ternary_6: c_int = 0

                            if ((if min__goto_2056_7 > 65535: 1 else: 0) != 0) {
                                (__ci_expr_ternary_6 = 65535)
                            } else {
                                (__ci_expr_ternary_6 = min__goto_2056_7)
                            }

                            (re.minlength = __ci_expr_ternary_6)

                        },
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                }
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

fn find_minlength(re: *const pcre2_real_code_8, code: *const u8, startcode: *const u8, utf: c_int, recurses: *mut recurse_check, countptr: *mut c_int, backref_cache: *mut c_int) -> c_int {
    var length__goto_106_5: c_int = 0
    var branchlength__goto_107_5: c_int = 0
    var prev_cap_recno__goto_108_5: c_int = 0
    var prev_cap_d__goto_109_5: c_int = 0
    var prev_recurse_recno__goto_110_5: c_int = 0
    var prev_recurse_d__goto_111_5: c_int = 0
    var once_fudge__goto_112_10: c_uint = 0
    var had_recurse__goto_113_6: c_int = 0
    var dupcapused__goto_114_6: c_int = 0
    var nextbranch__goto_115_12: *const u8 = null
    var cc__goto_116_12: *const u8 = null
    var this_recurse__goto_117_15: recurse_check
    var d__goto_137_7: c_int = 0
    var min__goto_137_10: c_int = 0
    var recno__goto_137_15: c_int = 0
    var op__goto_138_15: u8 = 0
    var cs__goto_139_14: *const u8 = null
    var ce__goto_139_18: *const u8 = null
    var count__goto_481_11: c_int = 0
    var slot__goto_482_18: *const u8 = null
    var dd__goto_492_13: c_int = 0
    var i__goto_492_17: c_int = 0
    var r__goto_512_30: *mut recurse_check = null
    var i__goto_554_11: c_int = 0
    var r__goto_571_28: *mut recurse_check = null
    var r__goto_657_24: *mut recurse_check = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc {
            0 => {
                (__goto_pending = 0)
                (length__goto_106_5 = -1)
                (branchlength__goto_107_5 = 0)
                (prev_cap_recno__goto_108_5 = -1)
                (prev_cap_d__goto_109_5 = 0)
                (prev_recurse_recno__goto_110_5 = -1)
                (prev_recurse_d__goto_111_5 = 0)
                (once_fudge__goto_112_10 = 0)
                (had_recurse__goto_113_6 = 0)
                (dupcapused__goto_114_6 = (if (re.flags & 2097152) != 0: 1 else: 0))
                (nextbranch__goto_115_12 = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))
                (cc__goto_116_12 = (code + ((1 as isize) as usize)) + ((2 as isize) as usize))
                var __ci_expr_logic_0: c_int = 0
                if ((if (unsafe: *code) >= OP_SBRA: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe: *code) <= OP_SCOND: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_0 != 0) {
                    return 0
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_logic_1: c_int
                if ((if (unsafe: *code) == OP_CBRA: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if (unsafe: *code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_1 != 0) {
                    (cc__goto_116_12 = cc__goto_116_12 + 2)
                }
                if (__goto_pending != 0) {
                    continue
                }
                var __ci_expr_old_2: c_int = (unsafe: *countptr)
                ((unsafe: *countptr) = (unsafe: *countptr) + 1)
                if ((if __ci_expr_old_2 > 1000: 1 else: 0) != 0) {
                    return -1
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 3
                __goto_pending = 1
                continue
            },
            3 => {  // __loop_top
                (__goto_pending = 0)
                if ((if branchlength__goto_107_5 >= 65535: 1 else: 0) != 0) {
                    (branchlength__goto_107_5 = 65535)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (cc__goto_116_12 = nextbranch__goto_115_12)
                    if (__goto_pending != 0) {
                        continue
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                (op__goto_138_15 = (unsafe: *cc__goto_116_12))
                if (__goto_pending != 0) {
                    continue
                }
                match op__goto_138_15 {
                    141 => {
                        (cs__goto_139_14 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        if ((if (unsafe: *cs__goto_139_14) != OP_ALT: 1 else: 0) != 0) {
                            (cc__goto_116_12 = (cs__goto_139_14 + ((1 as isize) as usize)) + ((2 as isize) as usize))

                            if (__goto_pending != 0) {
                                continue
                            }

                            break

                        }

                        __pc = 1
                        __goto_pending = 1

                    },
                    146 => {
                        (cs__goto_139_14 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        if ((if (unsafe: *cs__goto_139_14) != OP_ALT: 1 else: 0) != 0) {
                            (cc__goto_116_12 = (cs__goto_139_14 + ((1 as isize) as usize)) + ((2 as isize) as usize))

                            if (__goto_pending != 0) {
                                continue
                            }

                            break

                        }

                        __pc = 1
                        __goto_pending = 1

                    },
                    137 => {
                        var __ci_expr_logic_3: c_int = 0

                        if ((if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_RECURSE: 1 else: 0) != 0) {
                            (__ci_expr_logic_3 = (if (if (unsafe: cc__goto_116_12[(2 * (1 + 2))]) == OP_KET: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_3 != 0) {
                            (once_fudge__goto_112_10 = 3)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            if (__goto_pending != 0) {
                                continue
                            }

                            break

                        }


                        __pc = 1
                        __goto_pending = 1

                        continue


                    },
                    135 => {
                        __pc = 1
                        __goto_pending = 1

                        continue

                    },
                    136 => {
                        __pc = 1
                        __goto_pending = 1

                        continue

                    },
                    142 => {
                        __pc = 1
                        __goto_pending = 1

                        continue

                    },
                    138 => {
                        __pc = 1
                        __goto_pending = 1

                        continue

                    },
                    143 => {
                        __pc = 1
                        __goto_pending = 1

                        continue

                    },
                    139 => {
                        (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                        var __ci_expr_logic_4: c_int

                        if (dupcapused__goto_114_6 != 0) {
                            (__ci_expr_logic_4 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_4 != 0) {
                            (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if (__goto_pending != 0) {
                                continue
                            }

                            if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                return prev_cap_d__goto_109_5
                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    144 => {
                        (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                        var __ci_expr_logic_4: c_int

                        if (dupcapused__goto_114_6 != 0) {
                            (__ci_expr_logic_4 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_4 != 0) {
                            (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if (__goto_pending != 0) {
                                continue
                            }

                            if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                return prev_cap_d__goto_109_5
                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    140 => {
                        (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                        var __ci_expr_logic_4: c_int

                        if (dupcapused__goto_114_6 != 0) {
                            (__ci_expr_logic_4 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_4 != 0) {
                            (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if (__goto_pending != 0) {
                                continue
                            }

                            if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                return prev_cap_d__goto_109_5
                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    145 => {
                        (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                        var __ci_expr_logic_4: c_int

                        if (dupcapused__goto_114_6 != 0) {
                            (__ci_expr_logic_4 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_4 != 0) {
                            (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if (__goto_pending != 0) {
                                continue
                            }

                            if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                return prev_cap_d__goto_109_5
                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    166 => {
                        return -1
                    },
                    167 => {
                        return -1
                    },
                    121 => {
                        var __ci_expr_logic_6: c_int

                        if ((if length__goto_106_5 < 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_5: c_int = 0

                            if ((if not (had_recurse__goto_113_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_5 = (if (if branchlength__goto_107_5 < length__goto_106_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_6 != 0) {
                            (length__goto_106_5 = branchlength__goto_107_5)
                        }


                        var __ci_expr_logic_7: c_int

                        if ((if op__goto_138_15 != OP_ALT: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if length__goto_106_5 == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return length__goto_106_5
                        }


                        (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        (branchlength__goto_107_5 = 0)

                        (had_recurse__goto_113_6 = 0)

                    },
                    122 => {
                        var __ci_expr_logic_6: c_int

                        if ((if length__goto_106_5 < 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_5: c_int = 0

                            if ((if not (had_recurse__goto_113_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_5 = (if (if branchlength__goto_107_5 < length__goto_106_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_6 != 0) {
                            (length__goto_106_5 = branchlength__goto_107_5)
                        }


                        var __ci_expr_logic_7: c_int

                        if ((if op__goto_138_15 != OP_ALT: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if length__goto_106_5 == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return length__goto_106_5
                        }


                        (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        (branchlength__goto_107_5 = 0)

                        (had_recurse__goto_113_6 = 0)

                    },
                    123 => {
                        var __ci_expr_logic_6: c_int

                        if ((if length__goto_106_5 < 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_5: c_int = 0

                            if ((if not (had_recurse__goto_113_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_5 = (if (if branchlength__goto_107_5 < length__goto_106_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_6 != 0) {
                            (length__goto_106_5 = branchlength__goto_107_5)
                        }


                        var __ci_expr_logic_7: c_int

                        if ((if op__goto_138_15 != OP_ALT: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if length__goto_106_5 == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return length__goto_106_5
                        }


                        (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        (branchlength__goto_107_5 = 0)

                        (had_recurse__goto_113_6 = 0)

                    },
                    124 => {
                        var __ci_expr_logic_6: c_int

                        if ((if length__goto_106_5 < 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_5: c_int = 0

                            if ((if not (had_recurse__goto_113_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_5 = (if (if branchlength__goto_107_5 < length__goto_106_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_6 != 0) {
                            (length__goto_106_5 = branchlength__goto_107_5)
                        }


                        var __ci_expr_logic_7: c_int

                        if ((if op__goto_138_15 != OP_ALT: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if length__goto_106_5 == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return length__goto_106_5
                        }


                        (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        (branchlength__goto_107_5 = 0)

                        (had_recurse__goto_113_6 = 0)

                    },
                    125 => {
                        var __ci_expr_logic_6: c_int

                        if ((if length__goto_106_5 < 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_5: c_int = 0

                            if ((if not (had_recurse__goto_113_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_5 = (if (if branchlength__goto_107_5 < length__goto_106_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_6 != 0) {
                            (length__goto_106_5 = branchlength__goto_107_5)
                        }


                        var __ci_expr_logic_7: c_int

                        if ((if op__goto_138_15 != OP_ALT: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if length__goto_106_5 == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return length__goto_106_5
                        }


                        (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        (branchlength__goto_107_5 = 0)

                        (had_recurse__goto_113_6 = 0)

                    },
                    0 => {
                        var __ci_expr_logic_6: c_int

                        if ((if length__goto_106_5 < 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            var __ci_expr_logic_5: c_int = 0

                            if ((if not (had_recurse__goto_113_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_5 = (if (if branchlength__goto_107_5 < length__goto_106_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))

                        }

                        if (__ci_expr_logic_6 != 0) {
                            (length__goto_106_5 = branchlength__goto_107_5)
                        }


                        var __ci_expr_logic_7: c_int

                        if ((if op__goto_138_15 != OP_ALT: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if length__goto_106_5 == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return length__goto_106_5
                        }


                        (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        (branchlength__goto_107_5 = 0)

                        (had_recurse__goto_113_6 = 0)

                    },
                    128 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    129 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    130 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    131 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    132 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    134 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    133 => {
                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                    },
                    126 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    127 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    147 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    148 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    149 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    150 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    151 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    152 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    119 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    1 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    2 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    24 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    23 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    27 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    28 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    25 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    26 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    4 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    5 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    171 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    172 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                    },
                    120 => {
                        (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + (2 * 2)) + 1)])) as c_uint))
                    },
                    153 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    154 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    155 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    169 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        while true {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                    },
                    29 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    30 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    31 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    32 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    35 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    48 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    36 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    49 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    43 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    56 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    61 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    74 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    62 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    75 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    69 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    82 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        var __ci_expr_logic_8: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    87 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        var __ci_expr_ternary_10: c_int = 0

                        var __ci_expr_logic_9: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_9 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            (__ci_expr_ternary_10 = 4)
                        } else {
                            (__ci_expr_ternary_10 = 2)
                        }

                        (cc__goto_116_12 = cc__goto_116_12 + __ci_expr_ternary_10)


                    },
                    88 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        var __ci_expr_ternary_10: c_int = 0

                        var __ci_expr_logic_9: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_9 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            (__ci_expr_ternary_10 = 4)
                        } else {
                            (__ci_expr_ternary_10 = 2)
                        }

                        (cc__goto_116_12 = cc__goto_116_12 + __ci_expr_ternary_10)


                    },
                    95 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        var __ci_expr_ternary_10: c_int = 0

                        var __ci_expr_logic_9: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_9 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            (__ci_expr_ternary_10 = 4)
                        } else {
                            (__ci_expr_ternary_10 = 2)
                        }

                        (cc__goto_116_12 = cc__goto_116_12 + __ci_expr_ternary_10)


                    },
                    41 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                        var __ci_expr_logic_11: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_11 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    54 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                        var __ci_expr_logic_11: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_11 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    67 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                        var __ci_expr_logic_11: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_11 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    80 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                        var __ci_expr_logic_11: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_11 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    93 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        var __ci_expr_ternary_13: c_int = 0

                        var __ci_expr_logic_12: c_int

                        if ((if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_12 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_12 = (if (if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_12 != 0) {
                            (__ci_expr_ternary_13 = 2)
                        } else {
                            (__ci_expr_ternary_13 = 0)
                        }

                        (cc__goto_116_12 = cc__goto_116_12 + ((2 + 2) + __ci_expr_ternary_13))


                    },
                    16 => {
                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)


                    },
                    15 => {
                        (cc__goto_116_12 = cc__goto_116_12 + 2)

                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)


                    },
                    6 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    7 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    8 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    9 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    10 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    11 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    12 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    13 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    22 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    19 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    18 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    21 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    20 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    17 => {
                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    14 => {
                        if (utf != 0) {
                            return -1
                        }

                        (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    85 => {
                        var __ci_expr_logic_14: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_14 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    86 => {
                        var __ci_expr_logic_14: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_14 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    89 => {
                        var __ci_expr_logic_14: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_14 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    90 => {
                        var __ci_expr_logic_14: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_14 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    94 => {
                        var __ci_expr_logic_14: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_14 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    96 => {
                        var __ci_expr_logic_14: c_int

                        if ((if (unsafe: cc__goto_116_12[1]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_14 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_14 = (if (if (unsafe: cc__goto_116_12[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_14 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    91 => {
                        var __ci_expr_logic_15: c_int

                        if ((if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_15 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_15 = (if (if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_15 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    92 => {
                        var __ci_expr_logic_15: c_int

                        if ((if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_15 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_15 = (if (if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_15 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    97 => {
                        var __ci_expr_logic_15: c_int

                        if ((if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
                            (__ci_expr_logic_15 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_15 = (if (if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_15 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + 2)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                    },
                    110 => {
                        var __ci_expr_logic_16: c_int

                        if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                            (__ci_expr_logic_16 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_16 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                        } else {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                        }


                        match (unsafe: *cc__goto_116_12) {
                            100 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            101 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            107 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            98 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            99 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            102 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            103 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            106 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            108 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            104 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            105 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            109 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            _ => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            },
                        }

                    },
                    111 => {
                        var __ci_expr_logic_16: c_int

                        if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                            (__ci_expr_logic_16 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_16 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                        } else {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                        }


                        match (unsafe: *cc__goto_116_12) {
                            100 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            101 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            107 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            98 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            99 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            102 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            103 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            106 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            108 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            104 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            105 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            109 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            _ => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            },
                        }

                    },
                    112 => {
                        var __ci_expr_logic_16: c_int

                        if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                            (__ci_expr_logic_16 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_16 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                        } else {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                        }


                        match (unsafe: *cc__goto_116_12) {
                            100 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            101 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            107 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            98 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            99 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            102 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            103 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            106 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            108 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            104 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            105 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            109 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            _ => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            },
                        }

                    },
                    113 => {
                        var __ci_expr_logic_16: c_int

                        if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                            (__ci_expr_logic_16 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_16 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                        } else {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                        }


                        match (unsafe: *cc__goto_116_12) {
                            100 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            101 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            107 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                (cc__goto_116_12 = cc__goto_116_12 + 1)

                            },
                            98 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            99 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            102 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            103 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            106 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            108 => {
                                (cc__goto_116_12 = cc__goto_116_12 + 1)
                            },
                            104 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            105 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            109 => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                            },
                            _ => {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)
                            },
                        }

                    },
                    116 => {
                        var __ci_expr_logic_17: c_int = 0

                        if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                            (__ci_expr_logic_17 = (if (if (re.overall_options & 512) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_17 != 0) {
                            (count__goto_481_11 = ((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (slot__goto_482_18 = ((re as *const u8) + sizeof[pcre2_real_code_8]()) + ((((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint) *% re.name_entry_size))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (d__goto_137_7 = 2147483647)

                            if (__goto_pending != 0) {
                                continue
                            }

                            while true {
                                var __ci_expr_old_18: c_int = count__goto_481_11

                                (count__goto_481_11 = count__goto_481_11 - 1)

                                if (not ((if __ci_expr_old_18 > 0: 1 else: 0) != 0)) {
                                    break
                                }

                                (recno__goto_137_15 = ((((((unsafe: slot__goto_482_18[0]) as c_int) << (8 as c_uint)) | (unsafe: slot__goto_482_18[(0 + 1)])) as c_uint)))

                                if (__goto_pending != 0) {
                                    break
                                }

                                var __ci_expr_logic_19: c_int = 0

                                if ((if recno__goto_137_15 <= (unsafe: backref_cache[0]): 1 else: 0) != 0) {
                                    (__ci_expr_logic_19 = (if (if (unsafe: backref_cache[recno__goto_137_15]) >= 0: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_19 != 0) {
                                    (dd__goto_492_13 = (unsafe: backref_cache[recno__goto_137_15]))
                                } else {
                                    (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))

                                    (ce__goto_139_18 = cs__goto_139_14)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if ((if cs__goto_139_14 == null: 1 else: 0) != 0) {
                                        return -2
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    while true {
                                        (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << (8 as c_uint)) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        if (not ((if (unsafe: *ce__goto_139_18) == OP_ALT: 1 else: 0) != 0)) {
                                            break
                                        }

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (dd__goto_492_13 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_logic_20: c_int

                                    if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                                        (__ci_expr_logic_20 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_20 = (if (if _pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == null: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_20 != 0) {
                                        var __ci_expr_logic_21: c_int = 0

                                        if ((if cc__goto_116_12 > cs__goto_139_14: 1 else: 0) != 0) {
                                            (__ci_expr_logic_21 = (if (if cc__goto_116_12 < ce__goto_139_18: 1 else: 0) != 0: 1 else: 0))
                                        }

                                        if (__ci_expr_logic_21 != 0) {
                                            (had_recurse__goto_113_6 = 1)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        } else {
                                            (r__goto_512_30 = recurses)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (r__goto_512_30 = recurses)

                                            while ((if r__goto_512_30 != null: 1 else: 0) != 0) {
                                                if ((if r__goto_512_30.group == cs__goto_139_14: 1 else: 0) != 0) {
                                                    break
                                                }

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (r__goto_512_30 = r__goto_512_30.prev)

                                            }


                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if ((if r__goto_512_30 != null: 1 else: 0) != 0) {
                                                (had_recurse__goto_113_6 = 1)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                            } else {
                                                (this_recurse__goto_117_15.prev = recurses)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (this_recurse__goto_117_15.group = cs__goto_139_14)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (dd__goto_492_13 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                if ((if dd__goto_492_13 < 0: 1 else: 0) != 0) {
                                                    return dd__goto_492_13
                                                }

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        }


                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    ((unsafe: backref_cache[recno__goto_137_15]) = dd__goto_492_13)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (i__goto_492_17 = (unsafe: backref_cache[0]) + 1)

                                    while ((if i__goto_492_17 < recno__goto_137_15: 1 else: 0) != 0) {
                                        ((unsafe: backref_cache[i__goto_492_17]) = -1)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_492_17 = i__goto_492_17 + 1)

                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    ((unsafe: backref_cache[0]) = recno__goto_137_15)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if dd__goto_492_13 < d__goto_137_7: 1 else: 0) != 0) {
                                    (d__goto_137_7 = dd__goto_492_13)
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if d__goto_137_7 <= 0: 1 else: 0) != 0) {
                                    break
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                (slot__goto_482_18 = slot__goto_482_18 + re.name_entry_size)

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
                            (d__goto_137_7 = 0)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        __pc = 2
                        __goto_pending = 1

                    },
                    117 => {
                        var __ci_expr_logic_17: c_int = 0

                        if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                            (__ci_expr_logic_17 = (if (if (re.overall_options & 512) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_17 != 0) {
                            (count__goto_481_11 = ((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (slot__goto_482_18 = ((re as *const u8) + sizeof[pcre2_real_code_8]()) + ((((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint) *% re.name_entry_size))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (d__goto_137_7 = 2147483647)

                            if (__goto_pending != 0) {
                                continue
                            }

                            while true {
                                var __ci_expr_old_18: c_int = count__goto_481_11

                                (count__goto_481_11 = count__goto_481_11 - 1)

                                if (not ((if __ci_expr_old_18 > 0: 1 else: 0) != 0)) {
                                    break
                                }

                                (recno__goto_137_15 = ((((((unsafe: slot__goto_482_18[0]) as c_int) << (8 as c_uint)) | (unsafe: slot__goto_482_18[(0 + 1)])) as c_uint)))

                                if (__goto_pending != 0) {
                                    break
                                }

                                var __ci_expr_logic_19: c_int = 0

                                if ((if recno__goto_137_15 <= (unsafe: backref_cache[0]): 1 else: 0) != 0) {
                                    (__ci_expr_logic_19 = (if (if (unsafe: backref_cache[recno__goto_137_15]) >= 0: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_19 != 0) {
                                    (dd__goto_492_13 = (unsafe: backref_cache[recno__goto_137_15]))
                                } else {
                                    (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))

                                    (ce__goto_139_18 = cs__goto_139_14)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if ((if cs__goto_139_14 == null: 1 else: 0) != 0) {
                                        return -2
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    while true {
                                        (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << (8 as c_uint)) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        if (not ((if (unsafe: *ce__goto_139_18) == OP_ALT: 1 else: 0) != 0)) {
                                            break
                                        }

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (dd__goto_492_13 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    var __ci_expr_logic_20: c_int

                                    if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                                        (__ci_expr_logic_20 = (if true: 1 else: 0))
                                    } else {
                                        (__ci_expr_logic_20 = (if (if _pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == null: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_20 != 0) {
                                        var __ci_expr_logic_21: c_int = 0

                                        if ((if cc__goto_116_12 > cs__goto_139_14: 1 else: 0) != 0) {
                                            (__ci_expr_logic_21 = (if (if cc__goto_116_12 < ce__goto_139_18: 1 else: 0) != 0: 1 else: 0))
                                        }

                                        if (__ci_expr_logic_21 != 0) {
                                            (had_recurse__goto_113_6 = 1)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        } else {
                                            (r__goto_512_30 = recurses)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (r__goto_512_30 = recurses)

                                            while ((if r__goto_512_30 != null: 1 else: 0) != 0) {
                                                if ((if r__goto_512_30.group == cs__goto_139_14: 1 else: 0) != 0) {
                                                    break
                                                }

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (r__goto_512_30 = r__goto_512_30.prev)

                                            }


                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if ((if r__goto_512_30 != null: 1 else: 0) != 0) {
                                                (had_recurse__goto_113_6 = 1)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                            } else {
                                                (this_recurse__goto_117_15.prev = recurses)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (this_recurse__goto_117_15.group = cs__goto_139_14)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (dd__goto_492_13 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                if ((if dd__goto_492_13 < 0: 1 else: 0) != 0) {
                                                    return dd__goto_492_13
                                                }

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        }


                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    ((unsafe: backref_cache[recno__goto_137_15]) = dd__goto_492_13)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (i__goto_492_17 = (unsafe: backref_cache[0]) + 1)

                                    while ((if i__goto_492_17 < recno__goto_137_15: 1 else: 0) != 0) {
                                        ((unsafe: backref_cache[i__goto_492_17]) = -1)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (i__goto_492_17 = i__goto_492_17 + 1)

                                    }


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    ((unsafe: backref_cache[0]) = recno__goto_137_15)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if dd__goto_492_13 < d__goto_137_7: 1 else: 0) != 0) {
                                    (d__goto_137_7 = dd__goto_492_13)
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if d__goto_137_7 <= 0: 1 else: 0) != 0) {
                                    break
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                (slot__goto_482_18 = slot__goto_482_18 + re.name_entry_size)

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
                            (d__goto_137_7 = 0)
                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        __pc = 2
                        __goto_pending = 1

                    },
                    114 => {
                        (recno__goto_137_15 = ((((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint)))

                        var __ci_expr_logic_22: c_int = 0

                        if ((if recno__goto_137_15 <= (unsafe: backref_cache[0]): 1 else: 0) != 0) {
                            (__ci_expr_logic_22 = (if (if (unsafe: backref_cache[recno__goto_137_15]) >= 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_22 != 0) {
                            (d__goto_137_7 = (unsafe: backref_cache[recno__goto_137_15]))
                        } else {
                            (d__goto_137_7 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                            if ((if (re.overall_options & 512) == 0: 1 else: 0) != 0) {
                                (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))

                                (ce__goto_139_18 = cs__goto_139_14)


                                if (__goto_pending != 0) {
                                    continue
                                }

                                if ((if cs__goto_139_14 == null: 1 else: 0) != 0) {
                                    return -2
                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                while true {
                                    (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << (8 as c_uint)) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *ce__goto_139_18) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                var __ci_expr_logic_23: c_int

                                if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                                    (__ci_expr_logic_23 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_23 = (if (if _pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == null: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_23 != 0) {
                                    var __ci_expr_logic_24: c_int = 0

                                    if ((if cc__goto_116_12 > cs__goto_139_14: 1 else: 0) != 0) {
                                        (__ci_expr_logic_24 = (if (if cc__goto_116_12 < ce__goto_139_18: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_24 != 0) {
                                        (had_recurse__goto_113_6 = 1)

                                        if (__goto_pending != 0) {
                                            continue
                                        }

                                    } else {
                                        (r__goto_571_28 = recurses)

                                        if (__goto_pending != 0) {
                                            continue
                                        }

                                        (r__goto_571_28 = recurses)

                                        while ((if r__goto_571_28 != null: 1 else: 0) != 0) {
                                            if ((if r__goto_571_28.group == cs__goto_139_14: 1 else: 0) != 0) {
                                                break
                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (r__goto_571_28 = r__goto_571_28.prev)

                                        }


                                        if (__goto_pending != 0) {
                                            continue
                                        }

                                        if ((if r__goto_571_28 != null: 1 else: 0) != 0) {
                                            (had_recurse__goto_113_6 = 1)

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                        } else {
                                            (this_recurse__goto_117_15.prev = recurses)

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                            (this_recurse__goto_117_15.group = cs__goto_139_14)

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                            (d__goto_137_7 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                                return d__goto_137_7
                                            }

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

                                }


                                if (__goto_pending != 0) {
                                    continue
                                }

                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                            ((unsafe: backref_cache[recno__goto_137_15]) = d__goto_137_7)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (i__goto_554_11 = (unsafe: backref_cache[0]) + 1)

                            while ((if i__goto_554_11 < recno__goto_137_15: 1 else: 0) != 0) {
                                ((unsafe: backref_cache[i__goto_554_11]) = -1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (i__goto_554_11 = i__goto_554_11 + 1)

                            }


                            if (__goto_pending != 0) {
                                continue
                            }

                            ((unsafe: backref_cache[0]) = recno__goto_137_15)

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        __pc = 2
                        __goto_pending = 1

                        continue


                    },
                    115 => {
                        (recno__goto_137_15 = ((((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint)))

                        var __ci_expr_logic_22: c_int = 0

                        if ((if recno__goto_137_15 <= (unsafe: backref_cache[0]): 1 else: 0) != 0) {
                            (__ci_expr_logic_22 = (if (if (unsafe: backref_cache[recno__goto_137_15]) >= 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_22 != 0) {
                            (d__goto_137_7 = (unsafe: backref_cache[recno__goto_137_15]))
                        } else {
                            (d__goto_137_7 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                            if ((if (re.overall_options & 512) == 0: 1 else: 0) != 0) {
                                (cs__goto_139_14 = _pcre2_find_bracket_8(startcode, utf, recno__goto_137_15))

                                (ce__goto_139_18 = cs__goto_139_14)


                                if (__goto_pending != 0) {
                                    continue
                                }

                                if ((if cs__goto_139_14 == null: 1 else: 0) != 0) {
                                    return -2
                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                while true {
                                    (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << (8 as c_uint)) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *ce__goto_139_18) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                var __ci_expr_logic_23: c_int

                                if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                                    (__ci_expr_logic_23 = (if true: 1 else: 0))
                                } else {
                                    (__ci_expr_logic_23 = (if (if _pcre2_find_bracket_8(ce__goto_139_18, utf, recno__goto_137_15) == null: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_23 != 0) {
                                    var __ci_expr_logic_24: c_int = 0

                                    if ((if cc__goto_116_12 > cs__goto_139_14: 1 else: 0) != 0) {
                                        (__ci_expr_logic_24 = (if (if cc__goto_116_12 < ce__goto_139_18: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_24 != 0) {
                                        (had_recurse__goto_113_6 = 1)

                                        if (__goto_pending != 0) {
                                            continue
                                        }

                                    } else {
                                        (r__goto_571_28 = recurses)

                                        if (__goto_pending != 0) {
                                            continue
                                        }

                                        (r__goto_571_28 = recurses)

                                        while ((if r__goto_571_28 != null: 1 else: 0) != 0) {
                                            if ((if r__goto_571_28.group == cs__goto_139_14: 1 else: 0) != 0) {
                                                break
                                            }

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (r__goto_571_28 = r__goto_571_28.prev)

                                        }


                                        if (__goto_pending != 0) {
                                            continue
                                        }

                                        if ((if r__goto_571_28 != null: 1 else: 0) != 0) {
                                            (had_recurse__goto_113_6 = 1)

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                        } else {
                                            (this_recurse__goto_117_15.prev = recurses)

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                            (this_recurse__goto_117_15.group = cs__goto_139_14)

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                            (d__goto_137_7 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                            if (__goto_pending != 0) {
                                                continue
                                            }

                                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                                return d__goto_137_7
                                            }

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

                                }


                                if (__goto_pending != 0) {
                                    continue
                                }

                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                            ((unsafe: backref_cache[recno__goto_137_15]) = d__goto_137_7)

                            if (__goto_pending != 0) {
                                continue
                            }

                            (i__goto_554_11 = (unsafe: backref_cache[0]) + 1)

                            while ((if i__goto_554_11 < recno__goto_137_15: 1 else: 0) != 0) {
                                ((unsafe: backref_cache[i__goto_554_11]) = -1)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (i__goto_554_11 = i__goto_554_11 + 1)

                            }


                            if (__goto_pending != 0) {
                                continue
                            }

                            ((unsafe: backref_cache[0]) = recno__goto_137_15)

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        __pc = 2
                        __goto_pending = 1

                        continue


                    },
                    118 => {
                        (ce__goto_139_18 = startcode + (((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                        (cs__goto_139_14 = ce__goto_139_18)


                        (recno__goto_137_15 = ((((((unsafe: cs__goto_139_14[(1 + 2)]) as c_int) << (8 as c_uint)) | (unsafe: cs__goto_139_14[((1 + 2) + 1)])) as c_uint)))

                        if ((if recno__goto_137_15 == prev_recurse_recno__goto_110_5: 1 else: 0) != 0) {
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_recurse_d__goto_111_5)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            while true {
                                (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << (8 as c_uint)) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *ce__goto_139_18) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                            var __ci_expr_logic_25: c_int = 0

                            if ((if cc__goto_116_12 > cs__goto_139_14: 1 else: 0) != 0) {
                                (__ci_expr_logic_25 = (if (if cc__goto_116_12 < ce__goto_139_18: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_25 != 0) {
                                (had_recurse__goto_113_6 = 1)
                            } else {
                                (r__goto_657_24 = recurses)

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (r__goto_657_24 = recurses)

                                while ((if r__goto_657_24 != null: 1 else: 0) != 0) {
                                    if ((if r__goto_657_24.group == cs__goto_139_14: 1 else: 0) != 0) {
                                        break
                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (r__goto_657_24 = r__goto_657_24.prev)

                                }


                                if (__goto_pending != 0) {
                                    continue
                                }

                                if ((if r__goto_657_24 != null: 1 else: 0) != 0) {
                                    (had_recurse__goto_113_6 = 1)
                                } else {
                                    (this_recurse__goto_117_15.prev = recurses)

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (this_recurse__goto_117_15.group = cs__goto_139_14)

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (prev_recurse_d__goto_111_5 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    if ((if prev_recurse_d__goto_111_5 < 0: 1 else: 0) != 0) {
                                        return prev_recurse_d__goto_111_5
                                    }

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (prev_recurse_recno__goto_110_5 = recno__goto_137_15)

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_recurse_d__goto_111_5)

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

                        }

                        (cc__goto_116_12 = cc__goto_116_12 + (3 +% once_fudge__goto_112_10))

                        (once_fudge__goto_112_10 = 0)

                    },
                    39 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    52 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    65 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    78 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    40 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    53 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    66 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    79 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    45 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    58 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    71 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    84 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    33 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    46 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    59 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    72 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    34 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    47 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    60 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    73 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    42 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    55 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    68 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    81 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    37 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    50 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    63 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    76 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    38 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    51 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    64 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    77 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    44 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    57 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    70 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    83 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                        var __ci_expr_logic_26: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_26 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_26 != 0) {
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                        }


                    },
                    156 => {
                        (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                    },
                    164 => {
                        (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                    },
                    158 => {
                        (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                    },
                    160 => {
                        (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                    },
                    162 => {
                        (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                    },
                    168 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    163 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    165 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    157 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    3 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    159 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    161 => {
                        (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                    },
                    _ => {

                        return -3

                    },
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 4
                __goto_pending = 1
                continue
            },
            1 => {  // PROCESS_NON_CAPTURE
                (__goto_pending = 0)
                (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 2
                __goto_pending = 1
                continue
            },
            2 => {  // REPEAT_BACK_REFERENCE
                (__goto_pending = 0)
                match (unsafe: *cc__goto_116_12) {
                    98 => {
                        (min__goto_137_10 = 0)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    100 => {
                        (min__goto_137_10 = 1)

                        (cc__goto_116_12 = cc__goto_116_12 + 1)

                    },
                    104 => {
                        (min__goto_137_10 = ((((((unsafe: cc__goto_116_12[1]) as c_int) << (8 as c_uint)) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint)))

                        (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                    },
                    _ => {
                        (min__goto_137_10 = 1)
                    },
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 4
                __goto_pending = 1
                continue
            },
            4 => {  // __after_switch
                (__goto_pending = 0)
                __pc = 3
                __goto_pending = 1
                continue
                __pc = 3
                __goto_pending = 1
                continue
                if (__goto_pending != 0) {
                    continue
                }
                return -3
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

fn set_table_bit(re: *mut pcre2_real_code_8, __param_p: *const u8, caseless: c_int, utf: c_int, ucp: c_int) -> *const u8 {
    var p = __param_p
    var c: c_uint = with 0 as __ci_expr_seq_7 {
        var __ci_expr_old_0: *const u8 = p
        (p = p + 1)
        (unsafe: *__ci_expr_old_0)
    }

    utf

    ucp

    (re.start_bitmap[(c / 8)] = re.start_bitmap[(c / 8)] | ((1 as c_uint) << ((c & 7) as c_uint)))

    if (utf != 0) {
        if ((if c >= 192: 1 else: 0) != 0) {
            if ((if (c & 32) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_1: *const u8 = p

                (p = p + 1)

                (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: *__ci_expr_old_1) & 63))

            } else {
                if ((if (c & 16) == 0: 1 else: 0) != 0) {
                    (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: *p) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: p[1]) & 63))

                    (p = p + 2)

                } else {
                    if ((if (c & 8) == 0: 1 else: 0) != 0) {
                        (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: *p) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: p[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: p[2]) & 63))

                        (p = p + 3)

                    } else {
                        if ((if (c & 4) == 0: 1 else: 0) != 0) {
                            (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: *p) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: p[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: p[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: p[3]) & 63))

                            (p = p + 4)

                        } else {
                            (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: *p) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: p[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: p[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: p[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: p[4]) & 63))

                            (p = p + 5)

                        }
                    }
                }
            }

        }

    }

    if (caseless != 0) {
        var __ci_expr_logic_2: c_int

        if (utf != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if ucp != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (c = ((((c as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))

            if (utf != 0) {
                var buff: [6]u8

                _pcre2_ord2utf_8(c, (&buff[0] as *mut u8))

                (re.start_bitmap[(buff[0] / 8)] = re.start_bitmap[(buff[0] / 8)] | ((1 as c_uint) << ((buff[0] & 7) as c_uint)))

            } else {
                if ((if c < 256: 1 else: 0) != 0) {
                    (re.start_bitmap[(c / 8)] = re.start_bitmap[(c / 8)] | ((1 as c_uint) << ((c & 7) as c_uint)))
                }
            }

        } else {
            if (1 != 0) {
                (re.start_bitmap[((unsafe: re.tables[(256 +% c)]) / 8)] = re.start_bitmap[((unsafe: re.tables[(256 +% c)]) / 8)] | ((1 as c_uint) << (((unsafe: re.tables[(256 +% c)]) & 7) as c_uint)))
            }
        }


    }

    return p

}

fn set_type_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint) {
    var c: c_uint

    (c = 0)

    while ((if c < table_limit: 1 else: 0) != 0) {
        (re.start_bitmap[c] = re.start_bitmap[c] | (unsafe: re.tables[((c +% 512) +% cbit_type)]))

        (c = c + 1)

    }


    if ((if table_limit == 32: 1 else: 0) != 0) {
        return
    }

    (c = 128)

    while ((if c < 256: 1 else: 0) != 0) {
        if ((if ((unsafe: re.tables[(512 +% (c / 8))]) & ((1 as c_uint) << ((c & 7) as c_uint))) != 0: 1 else: 0) != 0) {
            var buff: [6]u8

            _pcre2_ord2utf_8(c, (&buff[0] as *mut u8))

            (re.start_bitmap[(buff[0] / 8)] = re.start_bitmap[(buff[0] / 8)] | ((1 as c_uint) << ((buff[0] & 7) as c_uint)))

        }


        (c = c + 1)

    }


}

fn set_nottype_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint) {
    var c: c_uint

    (c = 0)

    while ((if c < table_limit: 1 else: 0) != 0) {
        (re.start_bitmap[c] = re.start_bitmap[c] | ((~(unsafe: re.tables[((c +% 512) +% cbit_type)])) as u8))

        (c = c + 1)

    }


    if ((if table_limit != 32: 1 else: 0) != 0) {
        (c = 24)

        while ((if c < 32: 1 else: 0) != 0) {
            (re.start_bitmap[c] = 255)

            (c = c + 1)

        }

    }

}

fn study_char_list(__param_code: *const u8, start_bitmap: *mut u8, char_lists_end: *const u8) {
    var code = __param_code
    var type_: c_uint

    var list_ind: c_uint


    var char_list_add: c_uint = 0

    var range_start: c_uint = (~(0 as c_uint))

    var range_end: c_uint = 0


    var next_char: *const u8

    var start_buffer: [6]u8

    var end_buffer: [6]u8


    var start: u8

    var end: u8


    (type_ = ((((unsafe: code[0]) as c_int) << (8 as c_uint)) as c_uint) | (unsafe: code[1]))

    (code = code + 2)

    (next_char = char_lists_end - (((((((unsafe: code[0]) as c_int) << (8 as c_uint)) | (unsafe: code[(0 + 1)])) as c_uint) as c_uint) << (1 as c_uint)))

    (type_ = type_ & 4095)

    (list_ind = 0)

    if ((if (type_ & 4) != 0: 1 else: 0) != 0) {
        (range_start = 256)
    }

    while ((if type_ > 0: 1 else: 0) != 0) {
        var item_count: c_uint = (type_ & 3)

        if ((if item_count == 3: 1 else: 0) != 0) {
            if ((if list_ind <= 1: 1 else: 0) != 0) {
                (item_count = (unsafe: *(next_char as *const c_ushort)))

                (next_char = next_char + 2)

            } else {
                (item_count = (unsafe: *(next_char as *const c_uint)))

                (next_char = next_char + 4)

            }

        }

        while ((if item_count > 0: 1 else: 0) != 0) {
            if ((if list_ind <= 1: 1 else: 0) != 0) {
                (range_end = (unsafe: *(next_char as *const c_ushort)))

                (next_char = next_char + 2)

            } else {
                (range_end = (unsafe: *(next_char as *const c_uint)))

                (next_char = next_char + 4)

            }

            if ((if (range_end & 1) != 0: 1 else: 0) != 0) {
                (range_end = (char_list_add +% ((range_end as c_uint) >> (1 as c_uint))))

                _pcre2_ord2utf_8(range_end, (&end_buffer[0] as *mut u8))

                (end = end_buffer[0])

                if ((if range_start < range_end: 1 else: 0) != 0) {
                    _pcre2_ord2utf_8(range_start, (&start_buffer[0] as *mut u8))

                    (start = start_buffer[0])

                    while ((if start <= end: 1 else: 0) != 0) {
                        ((unsafe: start_bitmap[(start / 8)]) = (unsafe: start_bitmap[(start / 8)]) | ((1 as c_uint) << ((start & 7) as c_uint)))

                        (start = start + 1)

                    }


                } else {
                    ((unsafe: start_bitmap[(end / 8)]) = (unsafe: start_bitmap[(end / 8)]) | ((1 as c_uint) << ((end & 7) as c_uint)))
                }

                (range_start = (~(0 as c_uint)))

            } else {
                (range_start = (char_list_add +% ((range_end as c_uint) >> (1 as c_uint))))
            }

            (item_count = item_count - 1)

        }

        (list_ind = list_ind + 1)

        (type_ = type_ >> (3 as c_uint))

        if ((if range_start == (~(0 as c_uint)): 1 else: 0) != 0) {
            if ((if (type_ & 4) != 0: 1 else: 0) != 0) {
                if ((if list_ind == 1: 1 else: 0) != 0) {
                    (range_start = 32768)
                } else {
                    (range_start = 65536)
                }

            }

        } else {
            if ((if (type_ & 4) == 0: 1 else: 0) != 0) {
                _pcre2_ord2utf_8(range_start, (&start_buffer[0] as *mut u8))

                if ((if list_ind == 1: 1 else: 0) != 0) {
                    (range_end = 32767)
                } else {
                    (range_end = 65535)
                }

                _pcre2_ord2utf_8(range_end, (&end_buffer[0] as *mut u8))

                (end = end_buffer[0])

                (start = start_buffer[0])

                while ((if start <= end: 1 else: 0) != 0) {
                    ((unsafe: start_bitmap[(start / 8)]) = (unsafe: start_bitmap[(start / 8)]) | ((1 as c_uint) << ((start & 7) as c_uint)))

                    (start = start + 1)

                }


                (range_start = (~(0 as c_uint)))

            }
        }

        if ((if list_ind == 1: 1 else: 0) != 0) {
            (char_list_add = 32768)
        } else {
            (char_list_add = 0)
        }

    }

}

fn set_start_bits(re: *mut pcre2_real_code_8, __param_code: *const u8, utf: c_int, ucp: c_int, depthptr: *mut c_int) -> c_int {
    var code = __param_code
    var c__goto_1096_10: c_uint = 0
    var yield___goto_1097_5: c_int = 0
    var table_limit__goto_1100_5: c_int = 0
    var try_next__goto_1110_8: c_int = 0
    var tcode__goto_1111_14: *const u8 = null
    var rc__goto_1118_9: c_int = 0
    var ncode__goto_1119_16: *const u8 = null
    var classmap__goto_1120_20: *const u8 = null
    var xclassflags__goto_1122_17: u8 = 0
    var p__goto_1225_25: *const c_uint = null
    var buff__goto_1231_25: [6]u8
    var done__goto_1264_17: c_int = 0
    var b__goto_1749_21: u8 = 0
    var e__goto_1749_24: u8 = 0
    var p__goto_1750_20: *const u8 = null
    var d__goto_1845_19: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc {
            0 => {
                (__goto_pending = 0)
                (yield___goto_1097_5 = SSB_DONE)
                var __ci_expr_ternary_0: c_int = 0
                if (utf != 0) {
                    (__ci_expr_ternary_0 = 16)
                } else {
                    (__ci_expr_ternary_0 = 32)
                }
                (table_limit__goto_1100_5 = __ci_expr_ternary_0)
                ((unsafe: *depthptr) = (unsafe: *depthptr) + 1)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if (unsafe: *depthptr) > 1000: 1 else: 0) != 0) {
                    return SSB_TOODEEP
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 2
                __goto_pending = 1
                continue
            },
            2 => {  // __do_top
                (__goto_pending = 0)
                (try_next__goto_1110_8 = 1)
                (tcode__goto_1111_14 = (code + ((1 as isize) as usize)) + ((2 as isize) as usize))
                var __ci_expr_logic_3: c_int
                var __ci_expr_logic_2: c_int
                var __ci_expr_logic_1: c_int
                if ((if (unsafe: *code) == OP_CBRA: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if (unsafe: *code) == OP_SCBRA: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_1 != 0) {
                    (__ci_expr_logic_2 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_2 = (if (if (unsafe: *code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if (if (unsafe: *code) == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_3 != 0) {
                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
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
                if (not (try_next__goto_1110_8 != 0)) {
                    break
                }
                __pc = 4
                __goto_pending = 1
                if (__goto_pending != 0) {
                    continue
                }
                (classmap__goto_1120_20 = ((null as *const u8)))
                match (unsafe: *tcode__goto_1111_14) {
                    166 => {
                        return SSB_FAIL
                    },
                    167 => {
                        return SSB_FAIL
                    },
                    13 => {
                        return SSB_FAIL
                    },
                    12 => {
                        return SSB_FAIL
                    },
                    14 => {
                        return SSB_FAIL
                    },
                    28 => {
                        return SSB_FAIL
                    },
                    168 => {
                        return SSB_FAIL
                    },
                    163 => {
                        return SSB_FAIL
                    },
                    164 => {
                        return SSB_FAIL
                    },
                    141 => {
                        return SSB_FAIL
                    },
                    147 => {
                        return SSB_FAIL
                    },
                    151 => {
                        return SSB_FAIL
                    },
                    152 => {
                        return SSB_FAIL
                    },
                    148 => {
                        return SSB_FAIL
                    },
                    116 => {
                        return SSB_FAIL
                    },
                    117 => {
                        return SSB_FAIL
                    },
                    150 => {
                        return SSB_FAIL
                    },
                    25 => {
                        return SSB_FAIL
                    },
                    26 => {
                        return SSB_FAIL
                    },
                    0 => {
                        return SSB_FAIL
                    },
                    24 => {
                        return SSB_FAIL
                    },
                    23 => {
                        return SSB_FAIL
                    },
                    22 => {
                        return SSB_FAIL
                    },
                    165 => {
                        return SSB_FAIL
                    },
                    156 => {
                        return SSB_FAIL
                    },
                    31 => {
                        return SSB_FAIL
                    },
                    67 => {
                        return SSB_FAIL
                    },
                    80 => {
                        return SSB_FAIL
                    },
                    32 => {
                        return SSB_FAIL
                    },
                    62 => {
                        return SSB_FAIL
                    },
                    75 => {
                        return SSB_FAIL
                    },
                    64 => {
                        return SSB_FAIL
                    },
                    77 => {
                        return SSB_FAIL
                    },
                    60 => {
                        return SSB_FAIL
                    },
                    73 => {
                        return SSB_FAIL
                    },
                    66 => {
                        return SSB_FAIL
                    },
                    79 => {
                        return SSB_FAIL
                    },
                    61 => {
                        return SSB_FAIL
                    },
                    74 => {
                        return SSB_FAIL
                    },
                    69 => {
                        return SSB_FAIL
                    },
                    82 => {
                        return SSB_FAIL
                    },
                    70 => {
                        return SSB_FAIL
                    },
                    83 => {
                        return SSB_FAIL
                    },
                    68 => {
                        return SSB_FAIL
                    },
                    81 => {
                        return SSB_FAIL
                    },
                    71 => {
                        return SSB_FAIL
                    },
                    84 => {
                        return SSB_FAIL
                    },
                    15 => {
                        return SSB_FAIL
                    },
                    63 => {
                        return SSB_FAIL
                    },
                    76 => {
                        return SSB_FAIL
                    },
                    59 => {
                        return SSB_FAIL
                    },
                    72 => {
                        return SSB_FAIL
                    },
                    65 => {
                        return SSB_FAIL
                    },
                    78 => {
                        return SSB_FAIL
                    },
                    18 => {
                        return SSB_FAIL
                    },
                    20 => {
                        return SSB_FAIL
                    },
                    157 => {
                        return SSB_FAIL
                    },
                    158 => {
                        return SSB_FAIL
                    },
                    118 => {
                        return SSB_FAIL
                    },
                    114 => {
                        return SSB_FAIL
                    },
                    115 => {
                        return SSB_FAIL
                    },
                    126 => {
                        return SSB_FAIL
                    },
                    127 => {
                        return SSB_FAIL
                    },
                    149 => {
                        return SSB_FAIL
                    },
                    146 => {
                        return SSB_FAIL
                    },
                    3 => {
                        return SSB_FAIL
                    },
                    159 => {
                        return SSB_FAIL
                    },
                    160 => {
                        return SSB_FAIL
                    },
                    1 => {
                        return SSB_FAIL
                    },
                    2 => {
                        return SSB_FAIL
                    },
                    161 => {
                        return SSB_FAIL
                    },
                    162 => {
                        return SSB_FAIL
                    },
                    27 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + _pcre2_OP_lengths_8[OP_CIRC])
                    },
                    16 => {
                        if ((if (unsafe: tcode__goto_1111_14[1]) != 9: 1 else: 0) != 0) {
                            return SSB_FAIL
                        }

                        (p__goto_1225_25 = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe: tcode__goto_1111_14[2]) as isize) as usize))

                        if (__goto_pending != 0) {
                            continue
                        }

                        while true {
                            var __ci_expr_old_4: *const c_uint = p__goto_1225_25

                            (p__goto_1225_25 = p__goto_1225_25 + 1)

                            (c__goto_1096_10 = (unsafe: *__ci_expr_old_4))

                            if (not ((if c__goto_1096_10 < 4294967295: 1 else: 0) != 0)) {
                                break
                            }

                            if (utf != 0) {
                                _pcre2_ord2utf_8(c__goto_1096_10, (&buff__goto_1231_25[0] as *mut u8))

                                if (__goto_pending != 0) {
                                    break
                                }

                                (c__goto_1096_10 = buff__goto_1231_25[0])

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            if (__goto_pending != 0) {
                                break
                            }

                            if ((if c__goto_1096_10 > 255: 1 else: 0) != 0) {
                                (re.start_bitmap[(255 / 8)] = re.start_bitmap[(255 / 8)] | ((1 as c_uint) << ((255 & 7) as c_uint)))
                            } else {
                                (re.start_bitmap[(c__goto_1096_10 / 8)] = re.start_bitmap[(c__goto_1096_10 / 8)] | ((1 as c_uint) << ((c__goto_1096_10 & 7) as c_uint)))
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


                        (try_next__goto_1110_8 = 0)

                    },
                    5 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    4 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    172 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    171 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    128 => {
                        (ncode__goto_1119_16 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                        while ((if (unsafe: *ncode__goto_1119_16) == OP_ALT: 1 else: 0) != 0) {
                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                        }

                        (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))

                        (done__goto_1264_17 = 0)

                        while ((if not (done__goto_1264_17 != 0): 1 else: 0) != 0) {
                            match (unsafe: *ncode__goto_1119_16) {
                                128 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                                    while ((if (unsafe: *ncode__goto_1119_16) == OP_ALT: 1 else: 0) != 0) {
                                        (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    }

                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))

                                },
                                5 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                },
                                119 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + _pcre2_OP_lengths_8[OP_CALLOUT])
                                },
                                120 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[((1 + (2 * 2)) + 1)])) as c_uint))
                                },
                                _ => {
                                    (done__goto_1264_17 = 1)
                                },
                            }

                            if (__goto_pending != 0) {
                                break
                            }

                            if (__goto_pending != 0) {
                                break
                            }

                        }


                        match (unsafe: *ncode__goto_1119_16) {
                            16 => {
                                if ((if (unsafe: ncode__goto_1119_16[1]) != 9: 1 else: 0) != 0) {
                                    break
                                }

                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue


                            },
                            17 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            29 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            30 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            41 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            54 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            19 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            36 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            49 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            35 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            48 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            43 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            56 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            21 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            7 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            6 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            11 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            10 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            9 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            8 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            _ => {
                                0
                            },
                        }

                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }


                    },
                    132 => {
                        (ncode__goto_1119_16 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                        while ((if (unsafe: *ncode__goto_1119_16) == OP_ALT: 1 else: 0) != 0) {
                            (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                        }

                        (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))

                        (done__goto_1264_17 = 0)

                        while ((if not (done__goto_1264_17 != 0): 1 else: 0) != 0) {
                            match (unsafe: *ncode__goto_1119_16) {
                                128 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                                    while ((if (unsafe: *ncode__goto_1119_16) == OP_ALT: 1 else: 0) != 0) {
                                        (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    }

                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))

                                },
                                5 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + 1)
                                },
                                119 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + _pcre2_OP_lengths_8[OP_CALLOUT])
                                },
                                120 => {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: ncode__goto_1119_16[((1 + (2 * 2)) + 1)])) as c_uint))
                                },
                                _ => {
                                    (done__goto_1264_17 = 1)
                                },
                            }

                            if (__goto_pending != 0) {
                                break
                            }

                            if (__goto_pending != 0) {
                                break
                            }

                        }


                        match (unsafe: *ncode__goto_1119_16) {
                            16 => {
                                if ((if (unsafe: ncode__goto_1119_16[1]) != 9: 1 else: 0) != 0) {
                                    break
                                }

                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue


                            },
                            17 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            29 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            30 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            41 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            54 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            19 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            36 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            49 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            35 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            48 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            43 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            56 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            21 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            7 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            6 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            11 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            10 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            9 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            8 => {
                                (tcode__goto_1111_14 = ncode__goto_1119_16)

                                continue

                            },
                            _ => {
                                0
                            },
                        }

                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }


                    },
                    137 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    142 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    139 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    144 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    138 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    143 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    140 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    145 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    135 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    136 => {
                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                        if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                            (try_next__goto_1110_8 = 0)

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                if (__goto_pending != 0) {
                                    continue
                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                if (__goto_pending != 0) {
                                    continue
                                }

                            } else {
                                return rc__goto_1118_9
                            }
                        }

                    },
                    121 => {
                        (yield___goto_1097_5 = SSB_CONTINUE)

                        (try_next__goto_1110_8 = 0)

                    },
                    122 => {
                        return SSB_CONTINUE
                    },
                    123 => {
                        return SSB_CONTINUE
                    },
                    124 => {
                        return SSB_CONTINUE
                    },
                    125 => {
                        return SSB_CONTINUE
                    },
                    119 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + _pcre2_OP_lengths_8[OP_CALLOUT])
                    },
                    120 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[((1 + (2 * 2)) + 1)])) as c_uint))
                    },
                    129 => {
                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    130 => {
                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    131 => {
                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    133 => {
                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    134 => {
                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    153 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))


                        var __ci_expr_logic_6: c_int

                        var __ci_expr_logic_5: c_int

                        if ((if rc__goto_1118_9 == SSB_FAIL: 1 else: 0) != 0) {
                            (__ci_expr_logic_5 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_5 = (if (if rc__goto_1118_9 == SSB_UNKNOWN: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_5 != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if rc__goto_1118_9 == SSB_TOODEEP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return rc__goto_1118_9
                        }


                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    154 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))


                        var __ci_expr_logic_6: c_int

                        var __ci_expr_logic_5: c_int

                        if ((if rc__goto_1118_9 == SSB_FAIL: 1 else: 0) != 0) {
                            (__ci_expr_logic_5 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_5 = (if (if rc__goto_1118_9 == SSB_UNKNOWN: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_5 != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if rc__goto_1118_9 == SSB_TOODEEP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return rc__goto_1118_9
                        }


                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    155 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                        (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))


                        var __ci_expr_logic_6: c_int

                        var __ci_expr_logic_5: c_int

                        if ((if rc__goto_1118_9 == SSB_FAIL: 1 else: 0) != 0) {
                            (__ci_expr_logic_5 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_5 = (if (if rc__goto_1118_9 == SSB_UNKNOWN: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_5 != 0) {
                            (__ci_expr_logic_6 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_6 = (if (if rc__goto_1118_9 == SSB_TOODEEP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_6 != 0) {
                            return rc__goto_1118_9
                        }


                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    169 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                        while true {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                break
                            }

                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }

                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                    },
                    33 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                    },
                    34 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                    },
                    42 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                    },
                    37 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                    },
                    38 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                    },
                    44 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                    },
                    46 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                    },
                    47 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                    },
                    55 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                    },
                    50 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                    },
                    51 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                    },
                    57 => {
                        (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                    },
                    39 => {
                        (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 0, utf, ucp))
                    },
                    40 => {
                        (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 0, utf, ucp))
                    },
                    45 => {
                        (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 0, utf, ucp))
                    },
                    52 => {
                        (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 1, utf, ucp))
                    },
                    53 => {
                        (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 1, utf, ucp))
                    },
                    58 => {
                        (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 1, utf, ucp))
                    },
                    41 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                        (try_next__goto_1110_8 = 0)


                    },
                    29 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    35 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    36 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    43 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    54 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                        (try_next__goto_1110_8 = 0)


                    },
                    30 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    48 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    49 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    56 => {
                        set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                        (try_next__goto_1110_8 = 0)

                    },
                    19 => {
                        (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                        (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                        if (utf != 0) {
                            (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        (try_next__goto_1110_8 = 0)

                    },
                    17 => {
                        (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                        (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                        (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                        (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                        if (utf != 0) {
                            (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        (try_next__goto_1110_8 = 0)

                    },
                    21 => {
                        (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                        (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                        (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                        (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                        if (utf != 0) {
                            (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                            (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                        } else {
                            (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        (try_next__goto_1110_8 = 0)

                    },
                    6 => {
                        set_nottype_bits(re, 64, table_limit__goto_1100_5)

                        (try_next__goto_1110_8 = 0)

                    },
                    7 => {
                        set_type_bits(re, 64, table_limit__goto_1100_5)

                        (try_next__goto_1110_8 = 0)

                    },
                    8 => {
                        set_nottype_bits(re, 0, table_limit__goto_1100_5)

                        (try_next__goto_1110_8 = 0)

                    },
                    9 => {
                        set_type_bits(re, 0, table_limit__goto_1100_5)

                        (try_next__goto_1110_8 = 0)

                    },
                    10 => {
                        set_nottype_bits(re, 160, table_limit__goto_1100_5)

                        (try_next__goto_1110_8 = 0)

                    },
                    11 => {
                        set_type_bits(re, 160, table_limit__goto_1100_5)

                        (try_next__goto_1110_8 = 0)

                    },
                    87 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    88 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    95 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                    },
                    93 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                    },
                    91 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)


                    },
                    92 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)


                    },
                    97 => {
                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)


                    },
                    85 => {
                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                    },
                    86 => {
                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                    },
                    94 => {
                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                    },
                    89 => {
                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                    },
                    90 => {
                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                    },
                    96 => {
                        match (unsafe: tcode__goto_1111_14[1]) {
                            19 => {
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << ((9 & 7) as c_uint)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << ((32 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << ((225 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << ((227 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << ((160 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            17 => {
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << ((10 & 7) as c_uint)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << ((11 & 7) as c_uint)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << ((12 & 7) as c_uint)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << ((13 & 7) as c_uint)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << ((194 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << ((226 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << ((133 & 7) as c_uint)))

                                    if (__goto_pending != 0) {
                                        continue
                                    }

                                }

                            },
                            6 => {
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)
                            },
                            7 => {
                                set_type_bits(re, 64, table_limit__goto_1100_5)
                            },
                            8 => {
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)
                            },
                            9 => {
                                set_type_bits(re, 0, table_limit__goto_1100_5)
                            },
                            10 => {
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)
                            },
                            11 => {
                                set_type_bits(re, 160, table_limit__goto_1100_5)
                            },
                            _ => {
                                return SSB_FAIL
                            },
                        }

                        (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                    },
                    113 => {
                        return SSB_FAIL
                    },
                    112 => {
                        (xclassflags__goto_1122_17 = (unsafe: tcode__goto_1111_14[(1 + 2)]))

                        var __ci_expr_logic_7: c_int

                        if ((if (xclassflags__goto_1122_17 & 4) != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_7 = (if (if (xclassflags__goto_1122_17 & (2 | 1)) == 1: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_7 != 0) {
                            return SSB_FAIL
                        }


                        var __ci_expr_ternary_8: *const u8 = null

                        if ((if (xclassflags__goto_1122_17 & 2) == 0: 1 else: 0) != 0) {
                            (__ci_expr_ternary_8 = ((null as *const u8)))
                        } else {
                            (__ci_expr_ternary_8 = ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))
                        }

                        (classmap__goto_1120_20 = __ci_expr_ternary_8)


                        var __ci_expr_logic_9: c_int = 0

                        if (utf != 0) {
                            (__ci_expr_logic_9 = (if (if (xclassflags__goto_1122_17 & 1) == 0: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            var __ci_expr_ternary_10: c_int = 0

                            if ((if classmap__goto_1120_20 == null: 1 else: 0) != 0) {
                                (__ci_expr_ternary_10 = 0)
                            } else {
                                (__ci_expr_ternary_10 = 32)
                            }

                            (p__goto_1750_20 = (((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize)) + ((__ci_expr_ternary_10 as isize) as usize))


                            if (__goto_pending != 0) {
                                continue
                            }

                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                            if (__goto_pending != 0) {
                                continue
                            }

                            var __ci_expr_ternary_11: c_int = 0

                            if (1 != 0) {
                                (__ci_expr_ternary_11 = 16)
                            } else {
                                (__ci_expr_ternary_11 = 4096)
                            }

                            if ((if (unsafe: *p__goto_1750_20) >= __ci_expr_ternary_11: 1 else: 0) != 0) {
                                study_char_list(p__goto_1750_20, (&re.start_bitmap[0] as *mut u8), ((re as *const u8) + re.code_start))

                                if (__goto_pending != 0) {
                                    continue
                                }

                                __pc = 1
                                __goto_pending = 1

                                if (__goto_pending != 0) {
                                    continue
                                }

                            }


                            if (__goto_pending != 0) {
                                continue
                            }

                            while true {
                                var __ci_expr_old_12: *const u8 = p__goto_1750_20

                                (p__goto_1750_20 = p__goto_1750_20 + 1)

                                var __ci_expr_switch_13: c_int = (unsafe: *__ci_expr_old_12)

                                match __ci_expr_switch_13 {
                                    1 => {
                                        var __ci_expr_old_14: *const u8 = p__goto_1750_20

                                        (p__goto_1750_20 = p__goto_1750_20 + 1)

                                        (b__goto_1749_21 = (unsafe: *__ci_expr_old_14))


                                        while ((if ((unsafe: *p__goto_1750_20) & 192) == 128: 1 else: 0) != 0) {
                                            (p__goto_1750_20 = p__goto_1750_20 + 1)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        }

                                        (re.start_bitmap[(b__goto_1749_21 / 8)] = re.start_bitmap[(b__goto_1749_21 / 8)] | ((1 as c_uint) << ((b__goto_1749_21 & 7) as c_uint)))

                                    },
                                    2 => {
                                        var __ci_expr_old_15: *const u8 = p__goto_1750_20

                                        (p__goto_1750_20 = p__goto_1750_20 + 1)

                                        (b__goto_1749_21 = (unsafe: *__ci_expr_old_15))


                                        while ((if ((unsafe: *p__goto_1750_20) & 192) == 128: 1 else: 0) != 0) {
                                            (p__goto_1750_20 = p__goto_1750_20 + 1)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        }

                                        var __ci_expr_old_16: *const u8 = p__goto_1750_20

                                        (p__goto_1750_20 = p__goto_1750_20 + 1)

                                        (e__goto_1749_24 = (unsafe: *__ci_expr_old_16))


                                        while ((if ((unsafe: *p__goto_1750_20) & 192) == 128: 1 else: 0) != 0) {
                                            (p__goto_1750_20 = p__goto_1750_20 + 1)

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                        }

                                        while ((if b__goto_1749_21 <= e__goto_1749_24: 1 else: 0) != 0) {
                                            (re.start_bitmap[(b__goto_1749_21 / 8)] = re.start_bitmap[(b__goto_1749_21 / 8)] | ((1 as c_uint) << ((b__goto_1749_21 & 7) as c_uint)))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            (b__goto_1749_21 = b__goto_1749_21 + 1)

                                        }

                                    },
                                    0 => {
                                        __pc = 1
                                        __goto_pending = 1
                                    },
                                    _ => {

                                        return SSB_UNKNOWN

                                    },
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            if (__goto_pending != 0) {
                                continue
                            }

                        }


                        if (utf != 0) {
                            (re.start_bitmap[24] = re.start_bitmap[24] | 240)

                            if (__goto_pending != 0) {
                                continue
                            }

                            with_memset((((&re.start_bitmap[0] as *mut u8) + ((25 as isize) as usize)) as *i8), 255, (7 as i64))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        if ((if (unsafe: *tcode__goto_1111_14) == OP_XCLASS: 1 else: 0) != 0) {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))
                        } else {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                            (classmap__goto_1120_20 = tcode__goto_1111_14)


                            if (__goto_pending != 0) {
                                continue
                            }

                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        __pc = 1
                        __goto_pending = 1

                        continue




                    },
                    111 => {
                        if (utf != 0) {
                            (re.start_bitmap[24] = re.start_bitmap[24] | 240)

                            if (__goto_pending != 0) {
                                continue
                            }

                            with_memset((((&re.start_bitmap[0] as *mut u8) + ((25 as isize) as usize)) as *i8), 255, (7 as i64))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        if ((if (unsafe: *tcode__goto_1111_14) == OP_XCLASS: 1 else: 0) != 0) {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))
                        } else {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                            (classmap__goto_1120_20 = tcode__goto_1111_14)


                            if (__goto_pending != 0) {
                                continue
                            }

                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        __pc = 1
                        __goto_pending = 1

                        continue



                    },
                    110 => {
                        if ((if (unsafe: *tcode__goto_1111_14) == OP_XCLASS: 1 else: 0) != 0) {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << (8 as c_uint)) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))
                        } else {
                            (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                            (classmap__goto_1120_20 = tcode__goto_1111_14)


                            if (__goto_pending != 0) {
                                continue
                            }

                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))

                            if (__goto_pending != 0) {
                                continue
                            }

                        }

                        __pc = 1
                        __goto_pending = 1

                        continue


                    },
                    _ => {
                        return SSB_UNKNOWN
                    },
                }
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 5
                __goto_pending = 1
                continue
            },
            1 => {  // HANDLE_CLASSMAP
                (__goto_pending = 0)
                if ((if classmap__goto_1120_20 != null: 1 else: 0) != 0) {
                    if (utf != 0) {
                        (c__goto_1096_10 = 0)
                        while ((if c__goto_1096_10 < 16: 1 else: 0) != 0) {
                            (re.start_bitmap[c__goto_1096_10] = re.start_bitmap[c__goto_1096_10] | (unsafe: classmap__goto_1120_20[c__goto_1096_10]))
                            if (__goto_pending != 0) {
                                break
                            }
                            (c__goto_1096_10 = c__goto_1096_10 + 1)
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                        (c__goto_1096_10 = 128)
                        while ((if c__goto_1096_10 < 256: 1 else: 0) != 0) {
                            if ((if ((unsafe: classmap__goto_1120_20[(c__goto_1096_10 / 8)]) & ((1 as c_uint) << ((c__goto_1096_10 & 7) as c_uint))) != 0: 1 else: 0) != 0) {
                                (d__goto_1845_19 = ((c__goto_1096_10 as c_uint) >> (6 as c_uint)) | 192)
                                if (__goto_pending != 0) {
                                    break
                                }
                                (re.start_bitmap[(d__goto_1845_19 / 8)] = re.start_bitmap[(d__goto_1845_19 / 8)] | ((1 as c_uint) << ((d__goto_1845_19 & 7) as c_uint)))
                                if (__goto_pending != 0) {
                                    break
                                }
                                (c__goto_1096_10 = (((c__goto_1096_10 & 192) +% 64) -% 1))
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
                            (c__goto_1096_10 = c__goto_1096_10 + 1)
                        }
                        if (__goto_pending != 0) {
                            continue
                        }
                    } else {
                        (c__goto_1096_10 = 0)
                        while ((if c__goto_1096_10 < 32: 1 else: 0) != 0) {
                            (re.start_bitmap[c__goto_1096_10] = re.start_bitmap[c__goto_1096_10] | (unsafe: classmap__goto_1120_20[c__goto_1096_10]))
                            if (__goto_pending != 0) {
                                break
                            }
                            (c__goto_1096_10 = c__goto_1096_10 + 1)
                        }
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
                __pc = 5
                __goto_pending = 1
                continue
            },
            5 => {  // __after_switch
                (__goto_pending = 0)
                __pc = 3
                __goto_pending = 1
                continue
                __pc = 3
                __goto_pending = 1
                continue
                __pc = 4
                __goto_pending = 1
                continue
            },
            4 => {  // __after_while
                (__goto_pending = 0)
                (code = code + (((((unsafe: code[1]) as c_int) << (8 as c_uint)) | (unsafe: code[(1 + 1)])) as c_uint))
                if (__goto_pending != 0) {
                    continue
                }
                if (not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0)) {
                    break
                }
                __pc = 6
                __goto_pending = 1
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 2
                __goto_pending = 1
                continue
                __pc = 6
                __goto_pending = 1
                continue
            },
            6 => {  // __after_do
                (__goto_pending = 0)
                return yield___goto_1097_5
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
