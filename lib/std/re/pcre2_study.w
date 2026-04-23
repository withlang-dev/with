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
        match __pc:
            0 =>
                (__goto_pending = 0)
                (count__goto_1917_5 = 0)
                (utf__goto_1919_6 = (if (re.overall_options & 524288) != 0: 1 else: 0))
                (ucp__goto_1920_6 = (if (re.overall_options & 131072) != 0: 1 else: 0))
                (code__goto_1918_14 = (re as *mut u8) + re.code_start)
                if (__goto_pending != 0) {
                    continue
                }
                if ((if (re.flags & (16 | 512)) == 0: 1 else: 0) != 0) {
                    (depth__goto_1932_7 = 0)
                    if (__goto_pending != 0) {
                        continue
                    }
                    (rc__goto_1933_7 = set_start_bits(re, code__goto_1918_14, utf__goto_1919_6, ucp__goto_1920_6, (&mut depth__goto_1932_7 as *mut c_int)))
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if rc__goto_1933_7 == SSB_UNKNOWN: 1 else: 0) != 0) {
                        0
                    }
                    if (__goto_pending != 0) {
                        continue
                    }
                    if ((if rc__goto_1933_7 == SSB_DONE: 1 else: 0) != 0) {
                        (a__goto_1953_9 = -1)
                        if (__goto_pending != 0) {
                            continue
                        }
                        (b__goto_1954_9 = -1)
                        if (__goto_pending != 0) {
                            continue
                        }
                        (p__goto_1955_14 = ((&re.start_bitmap[0] as *mut u8)))
                        if (__goto_pending != 0) {
                            continue
                        }
                        (flags__goto_1956_14 = 64)
                        if (__goto_pending != 0) {
                            continue
                        }
                        (i__goto_1952_9 = 0)
                        while ((if i__goto_1952_9 < 256: 1 else: 0) != 0) {
                            (x__goto_1960_15 = (unsafe: *p__goto_1955_14))
                            if (__goto_pending != 0) {
                                break
                            }
                            if ((if x__goto_1960_15 != 0: 1 else: 0) != 0) {
                                0
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
                            var __ci_expr_logic_2: c_int = 0
                            if ((re.flags & 128) != 0) {
                                var __ci_expr_logic_1: c_int
                                if ((if re.last_codeunit == ((a__goto_1953_9 as c_uint)): 1 else: 0) != 0) {
                                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                                } else {
                                    var __ci_expr_logic_0: c_int = 0
                                    if ((if b__goto_1954_9 >= 0: 1 else: 0) != 0) {
                                        (__ci_expr_logic_0 = (if (if re.last_codeunit == ((b__goto_1954_9 as c_uint)): 1 else: 0) != 0: 1 else: 0))
                                    }
                                    (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))
                                }
                                (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))
                            }
                            if (__ci_expr_logic_2 != 0) {
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
                        (re.flags = re.flags | flags__goto_1956_14)
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
                var __ci_expr_logic_3: c_int = 0
                if ((if (re.flags & (8192 | 8388608)) == 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if (if re.top_backref <= 128: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_3 != 0) {
                    0
                }
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
        match __pc:
            0 =>
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
                (nextbranch__goto_115_12 = code + (((((unsafe: code[1]) as c_int) << 8) | (unsafe: code[(1 + 1)])) as c_uint))
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
                while true {
                    if ((if branchlength__goto_107_5 >= 65535: 1 else: 0) != 0) {
                        (branchlength__goto_107_5 = 65535)
                        if (__goto_pending != 0) {
                            break
                        }
                        (cc__goto_116_12 = nextbranch__goto_115_12)
                        if (__goto_pending != 0) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (op__goto_138_15 = (unsafe: *cc__goto_116_12))
                    if (__goto_pending != 0) {
                        break
                    }
                    match op__goto_138_15:
                        OP_COND =>
                            (cs__goto_139_14 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if ((if (unsafe: *cs__goto_139_14) != OP_ALT: 1 else: 0) != 0) {
                                (cc__goto_116_12 = (cs__goto_139_14 + ((1 as isize) as usize)) + ((2 as isize) as usize))

                                if (__goto_pending != 0) {
                                    break
                                }

                                break

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            __pc = 1
                            __goto_pending = 1

                        OP_SCOND =>
                            (cs__goto_139_14 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            if ((if (unsafe: *cs__goto_139_14) != OP_ALT: 1 else: 0) != 0) {
                                (cc__goto_116_12 = (cs__goto_139_14 + ((1 as isize) as usize)) + ((2 as isize) as usize))

                                if (__goto_pending != 0) {
                                    break
                                }

                                break

                                if (__goto_pending != 0) {
                                    break
                                }

                            }

                            __pc = 1
                            __goto_pending = 1

                        OP_BRA =>
                            var __ci_expr_logic_3: c_int = 0

                            if ((if (unsafe: cc__goto_116_12[(1 + 2)]) == OP_RECURSE: 1 else: 0) != 0) {
                                (__ci_expr_logic_3 = (if (if (unsafe: cc__goto_116_12[(2 * (1 + 2))]) == OP_KET: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_3 != 0) {
                                (once_fudge__goto_112_10 = 3)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                                if (__goto_pending != 0) {
                                    break
                                }

                                break

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                return d__goto_137_7
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))


                        OP_ONCE =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                return d__goto_137_7
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_SCRIPT_RUN =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                return d__goto_137_7
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_SBRA =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                return d__goto_137_7
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_BRAPOS =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                return d__goto_137_7
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_SBRAPOS =>
                            (d__goto_137_7 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                            if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                return d__goto_137_7
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + d__goto_137_7)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_CBRA =>
                            (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                            var __ci_expr_logic_4: c_int

                            if (dupcapused__goto_114_6 != 0) {
                                (__ci_expr_logic_4 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_4 != 0) {
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                    return prev_cap_d__goto_109_5
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_SCBRA =>
                            (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                            var __ci_expr_logic_4: c_int

                            if (dupcapused__goto_114_6 != 0) {
                                (__ci_expr_logic_4 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_4 != 0) {
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                    return prev_cap_d__goto_109_5
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_CBRAPOS =>
                            (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                            var __ci_expr_logic_4: c_int

                            if (dupcapused__goto_114_6 != 0) {
                                (__ci_expr_logic_4 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_4 != 0) {
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                    return prev_cap_d__goto_109_5
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_SCBRAPOS =>
                            (recno__goto_137_15 = (((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint) as c_int)))

                            var __ci_expr_logic_4: c_int

                            if (dupcapused__goto_114_6 != 0) {
                                (__ci_expr_logic_4 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_4 = (if (if recno__goto_137_15 != prev_cap_recno__goto_108_5: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_4 != 0) {
                                (prev_cap_recno__goto_108_5 = recno__goto_137_15)

                                if (__goto_pending != 0) {
                                    break
                                }

                                (prev_cap_d__goto_109_5 = find_minlength(re, cc__goto_116_12, startcode, utf, recurses, countptr, backref_cache))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if prev_cap_d__goto_109_5 < 0: 1 else: 0) != 0) {
                                    return prev_cap_d__goto_109_5
                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_cap_d__goto_109_5)

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_ACCEPT =>
                            return -1
                        OP_ASSERT_ACCEPT =>
                            return -1
                        OP_ALT =>
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


                            (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            (branchlength__goto_107_5 = 0)

                            (had_recurse__goto_113_6 = 0)

                        OP_KET =>
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


                            (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            (branchlength__goto_107_5 = 0)

                            (had_recurse__goto_113_6 = 0)

                        OP_KETRMAX =>
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


                            (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            (branchlength__goto_107_5 = 0)

                            (had_recurse__goto_113_6 = 0)

                        OP_KETRMIN =>
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


                            (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            (branchlength__goto_107_5 = 0)

                            (had_recurse__goto_113_6 = 0)

                        OP_KETRPOS =>
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


                            (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            (branchlength__goto_107_5 = 0)

                            (had_recurse__goto_113_6 = 0)

                        OP_END =>
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


                            (nextbranch__goto_115_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                            (branchlength__goto_107_5 = 0)

                            (had_recurse__goto_113_6 = 0)

                        OP_ASSERT =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_ASSERT_NOT =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_ASSERTBACK =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_ASSERTBACK_NOT =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_ASSERT_NA =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_ASSERT_SCS =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_ASSERTBACK_NA =>
                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                        OP_REVERSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_VREVERSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DNCREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_RREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DNRREF =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_FALSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_TRUE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CALLOUT =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_SOD =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_SOM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_EOD =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_EODN =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CIRC =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CIRCM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DOLL =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_DOLLM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_NOT_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_NOT_UCP_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_UCP_WORD_BOUNDARY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])
                        OP_CALLOUT_STR =>
                            (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[(1 + (2 * 2))]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + (2 * 2)) + 1)])) as c_uint))
                        OP_BRAZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_BRAMINZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_BRAPOSZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_SKIPZERO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            while true {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                if (__goto_pending != 0) {
                                    break
                                }

                                if (not ((if (unsafe: *cc__goto_116_12) == OP_ALT: 1 else: 0) != 0)) {
                                    break
                                }

                            }

                            (cc__goto_116_12 = cc__goto_116_12 + (1 + 2))

                        OP_CHAR =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_CHARI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_PLUS =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_PLUSI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINPLUS =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINPLUSI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSPLUS =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSPLUSI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPLUS =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPLUSI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINPLUS =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINPLUSI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSPLUS =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSPLUSI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            var __ci_expr_logic_8: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_8 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_8 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_TYPEPLUS =>
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


                        OP_TYPEMINPLUS =>
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


                        OP_TYPEPOSPLUS =>
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


                        OP_EXACT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                            var __ci_expr_logic_11: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_11 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_EXACTI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                            var __ci_expr_logic_11: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_11 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTEXACT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                            var __ci_expr_logic_11: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_11 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTEXACTI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cc__goto_116_12 = cc__goto_116_12 + (2 + 2))

                            var __ci_expr_logic_11: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_11 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_11 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_TYPEEXACT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

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


                        OP_PROP =>
                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)


                        OP_NOTPROP =>
                            (cc__goto_116_12 = cc__goto_116_12 + 2)

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)


                        OP_NOT_DIGIT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_DIGIT =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_NOT_WHITESPACE =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_WHITESPACE =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_NOT_WORDCHAR =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_WORDCHAR =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_ANY =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_ALLANY =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_EXTUNI =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_HSPACE =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_NOT_HSPACE =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_VSPACE =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_NOT_VSPACE =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_ANYNL =>
                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_ANYBYTE =>
                            if (utf != 0) {
                                return -1
                            }

                            (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                            (cc__goto_116_12 = cc__goto_116_12 + 1)

                        OP_TYPESTAR =>
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

                        OP_TYPEMINSTAR =>
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

                        OP_TYPEQUERY =>
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

                        OP_TYPEMINQUERY =>
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

                        OP_TYPEPOSSTAR =>
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

                        OP_TYPEPOSQUERY =>
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

                        OP_TYPEUPTO =>
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

                        OP_TYPEMINUPTO =>
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

                        OP_TYPEPOSUPTO =>
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

                        OP_CLASS =>
                            var __ci_expr_logic_16: c_int

                            if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                                (__ci_expr_logic_16 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_16 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                            } else {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            }


                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRMINPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRPOSPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                _ =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        OP_NCLASS =>
                            var __ci_expr_logic_16: c_int

                            if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                                (__ci_expr_logic_16 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_16 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                            } else {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            }


                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRMINPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRPOSPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                _ =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        OP_XCLASS =>
                            var __ci_expr_logic_16: c_int

                            if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                                (__ci_expr_logic_16 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_16 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                            } else {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            }


                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRMINPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRPOSPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                _ =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        OP_ECLASS =>
                            var __ci_expr_logic_16: c_int

                            if ((if op__goto_138_15 == OP_XCLASS: 1 else: 0) != 0) {
                                (__ci_expr_logic_16 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_16 = (if (if op__goto_138_15 == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_16 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))
                            } else {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[OP_CLASS])
                            }


                            match (unsafe: *cc__goto_116_12):
                                OP_CRPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRMINPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRPOSPLUS =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                                    (cc__goto_116_12 = cc__goto_116_12 + 1)

                                OP_CRSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRMINQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSSTAR =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRPOSQUERY =>
                                    (cc__goto_116_12 = cc__goto_116_12 + 1)
                                OP_CRRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRMINRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                OP_CRPOSRANGE =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                                    (cc__goto_116_12 = cc__goto_116_12 + (1 + (2 * 2)))

                                _ =>
                                    (branchlength__goto_107_5 = branchlength__goto_107_5 + 1)

                        OP_DNREF =>
                            var __ci_expr_logic_17: c_int = 0

                            if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_17 = (if (if (re.overall_options & 512) == 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_17 != 0) {
                                (count__goto_481_11 = ((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint)))

                                if (__goto_pending != 0) {
                                    break
                                }

                                (slot__goto_482_18 = ((re as *const u8) + sizeof[pcre2_real_code_8]()) + ((((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint) *% re.name_entry_size))

                                if (__goto_pending != 0) {
                                    break
                                }

                                (d__goto_137_7 = 2147483647)

                                if (__goto_pending != 0) {
                                    break
                                }

                                while true {
                                    var __ci_expr_old_18: c_int = count__goto_481_11

                                    (count__goto_481_11 = count__goto_481_11 - 1)

                                    if (not ((if __ci_expr_old_18 > 0: 1 else: 0) != 0)) {
                                        break
                                    }

                                    (recno__goto_137_15 = ((((((unsafe: slot__goto_482_18[0]) as c_int) << 8) | (unsafe: slot__goto_482_18[(0 + 1)])) as c_uint)))

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
                                            (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << 8) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

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
                                    break
                                }

                            } else {
                                (d__goto_137_7 = 0)
                            }


                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            __pc = 2
                            __goto_pending = 1

                        OP_DNREFI =>
                            var __ci_expr_logic_17: c_int = 0

                            if ((if not (dupcapused__goto_114_6 != 0): 1 else: 0) != 0) {
                                (__ci_expr_logic_17 = (if (if (re.overall_options & 512) == 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_17 != 0) {
                                (count__goto_481_11 = ((((((unsafe: cc__goto_116_12[(1 + 2)]) as c_int) << 8) | (unsafe: cc__goto_116_12[((1 + 2) + 1)])) as c_uint)))

                                if (__goto_pending != 0) {
                                    break
                                }

                                (slot__goto_482_18 = ((re as *const u8) + sizeof[pcre2_real_code_8]()) + ((((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint) *% re.name_entry_size))

                                if (__goto_pending != 0) {
                                    break
                                }

                                (d__goto_137_7 = 2147483647)

                                if (__goto_pending != 0) {
                                    break
                                }

                                while true {
                                    var __ci_expr_old_18: c_int = count__goto_481_11

                                    (count__goto_481_11 = count__goto_481_11 - 1)

                                    if (not ((if __ci_expr_old_18 > 0: 1 else: 0) != 0)) {
                                        break
                                    }

                                    (recno__goto_137_15 = ((((((unsafe: slot__goto_482_18[0]) as c_int) << 8) | (unsafe: slot__goto_482_18[(0 + 1)])) as c_uint)))

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
                                            (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << 8) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

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
                                    break
                                }

                            } else {
                                (d__goto_137_7 = 0)
                            }


                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            __pc = 2
                            __goto_pending = 1

                        OP_REF =>
                            (recno__goto_137_15 = ((((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint)))

                            var __ci_expr_logic_22: c_int = 0

                            if ((if recno__goto_137_15 <= (unsafe: backref_cache[0]): 1 else: 0) != 0) {
                                (__ci_expr_logic_22 = (if (if (unsafe: backref_cache[recno__goto_137_15]) >= 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_22 != 0) {
                                (d__goto_137_7 = (unsafe: backref_cache[recno__goto_137_15]))
                            } else {
                                (d__goto_137_7 = 0)

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if (re.overall_options & 512) == 0: 1 else: 0) != 0) {
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
                                        (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << 8) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

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
                                                break
                                            }

                                        } else {
                                            (r__goto_571_28 = recurses)

                                            if (__goto_pending != 0) {
                                                break
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
                                                break
                                            }

                                            if ((if r__goto_571_28 != null: 1 else: 0) != 0) {
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

                                                (d__goto_137_7 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                                    return d__goto_137_7
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

                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                ((unsafe: backref_cache[recno__goto_137_15]) = d__goto_137_7)

                                if (__goto_pending != 0) {
                                    break
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
                                    break
                                }

                                ((unsafe: backref_cache[0]) = recno__goto_137_15)

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            var __ci_expr_logic_26: c_int

                            var __ci_expr_logic_25: c_int = 0

                            if ((if d__goto_137_7 > 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_25 = (if (if (2147483647 / d__goto_137_7) < min__goto_137_10: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_25 != 0) {
                                (__ci_expr_logic_26 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_26 = (if (if (65535 - branchlength__goto_107_5) < (min__goto_137_10 * d__goto_137_7): 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_26 != 0) {
                                (branchlength__goto_107_5 = 65535)
                            } else {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (min__goto_137_10 * d__goto_137_7))
                            }


                        OP_REFI =>
                            (recno__goto_137_15 = ((((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint)))

                            var __ci_expr_logic_22: c_int = 0

                            if ((if recno__goto_137_15 <= (unsafe: backref_cache[0]): 1 else: 0) != 0) {
                                (__ci_expr_logic_22 = (if (if (unsafe: backref_cache[recno__goto_137_15]) >= 0: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_22 != 0) {
                                (d__goto_137_7 = (unsafe: backref_cache[recno__goto_137_15]))
                            } else {
                                (d__goto_137_7 = 0)

                                if (__goto_pending != 0) {
                                    break
                                }

                                if ((if (re.overall_options & 512) == 0: 1 else: 0) != 0) {
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
                                        (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << 8) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

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
                                                break
                                            }

                                        } else {
                                            (r__goto_571_28 = recurses)

                                            if (__goto_pending != 0) {
                                                break
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
                                                break
                                            }

                                            if ((if r__goto_571_28 != null: 1 else: 0) != 0) {
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

                                                (d__goto_137_7 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                if ((if d__goto_137_7 < 0: 1 else: 0) != 0) {
                                                    return d__goto_137_7
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

                                }

                                if (__goto_pending != 0) {
                                    break
                                }

                                ((unsafe: backref_cache[recno__goto_137_15]) = d__goto_137_7)

                                if (__goto_pending != 0) {
                                    break
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
                                    break
                                }

                                ((unsafe: backref_cache[0]) = recno__goto_137_15)

                                if (__goto_pending != 0) {
                                    break
                                }

                            }


                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[(unsafe: *cc__goto_116_12)])

                            var __ci_expr_logic_26: c_int

                            var __ci_expr_logic_25: c_int = 0

                            if ((if d__goto_137_7 > 0: 1 else: 0) != 0) {
                                (__ci_expr_logic_25 = (if (if (2147483647 / d__goto_137_7) < min__goto_137_10: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_25 != 0) {
                                (__ci_expr_logic_26 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_26 = (if (if (65535 - branchlength__goto_107_5) < (min__goto_137_10 * d__goto_137_7): 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_26 != 0) {
                                (branchlength__goto_107_5 = 65535)
                            } else {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + (min__goto_137_10 * d__goto_137_7))
                            }


                        OP_RECURSE =>
                            (ce__goto_139_18 = startcode + (((((unsafe: cc__goto_116_12[1]) as c_int) << 8) | (unsafe: cc__goto_116_12[(1 + 1)])) as c_uint))

                            (cs__goto_139_14 = ce__goto_139_18)


                            (recno__goto_137_15 = ((((((unsafe: cs__goto_139_14[(1 + 2)]) as c_int) << 8) | (unsafe: cs__goto_139_14[((1 + 2) + 1)])) as c_uint)))

                            if ((if recno__goto_137_15 == prev_recurse_recno__goto_110_5: 1 else: 0) != 0) {
                                (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_recurse_d__goto_111_5)

                                if (__goto_pending != 0) {
                                    break
                                }

                            } else {
                                while true {
                                    (ce__goto_139_18 = ce__goto_139_18 + (((((unsafe: ce__goto_139_18[1]) as c_int) << 8) | (unsafe: ce__goto_139_18[(1 + 1)])) as c_uint))

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

                                var __ci_expr_logic_27: c_int = 0

                                if ((if cc__goto_116_12 > cs__goto_139_14: 1 else: 0) != 0) {
                                    (__ci_expr_logic_27 = (if (if cc__goto_116_12 < ce__goto_139_18: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_27 != 0) {
                                    (had_recurse__goto_113_6 = 1)
                                } else {
                                    (r__goto_657_24 = recurses)

                                    if (__goto_pending != 0) {
                                        break
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
                                        break
                                    }

                                    if ((if r__goto_657_24 != null: 1 else: 0) != 0) {
                                        (had_recurse__goto_113_6 = 1)
                                    } else {
                                        (this_recurse__goto_117_15.prev = recurses)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (this_recurse__goto_117_15.group = cs__goto_139_14)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (prev_recurse_d__goto_111_5 = find_minlength(re, cs__goto_139_14, startcode, utf, (&mut this_recurse__goto_117_15 as *mut recurse_check), countptr, backref_cache))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        if ((if prev_recurse_d__goto_111_5 < 0: 1 else: 0) != 0) {
                                            return prev_recurse_d__goto_111_5
                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (prev_recurse_recno__goto_110_5 = recno__goto_137_15)

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (branchlength__goto_107_5 = branchlength__goto_107_5 + prev_recurse_d__goto_111_5)

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

                            (cc__goto_116_12 = cc__goto_116_12 + (3 +% once_fudge__goto_112_10))

                            (once_fudge__goto_112_10 = 0)

                        OP_UPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_UPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSUPTO =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSUPTOI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_STAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_STARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSSTAR =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSSTARI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_QUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_QUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MINQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTMINQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_POSQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSQUERY =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_NOTPOSQUERYI =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])

                            var __ci_expr_logic_28: c_int = 0

                            if (utf != 0) {
                                (__ci_expr_logic_28 = (if (if (unsafe: cc__goto_116_12[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_28 != 0) {
                                (cc__goto_116_12 = cc__goto_116_12 + _pcre2_utf8_table4[((unsafe: cc__goto_116_12[-1]) & 63)])
                            }


                        OP_MARK =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                        OP_COMMIT_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                        OP_PRUNE_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                        OP_SKIP_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                        OP_THEN_ARG =>
                            (cc__goto_116_12 = cc__goto_116_12 + (_pcre2_OP_lengths_8[op__goto_138_15] + (unsafe: cc__goto_116_12[1])))
                        OP_CLOSE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_COMMIT =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_FAIL =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_PRUNE =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_SET_SOM =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_SKIP =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        OP_THEN =>
                            (cc__goto_116_12 = cc__goto_116_12 + _pcre2_OP_lengths_8[op__goto_138_15])
                        _ =>
                            return -3
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
                return -3
                if (__goto_pending != 0) {
                    continue
                }
            _ => break
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

    (re.start_bitmap[(c / 8)] = re.start_bitmap[(c / 8)] | ((1 as c_uint) << (c & 7)))

    if (utf != 0) {
        if ((if c >= 192: 1 else: 0) != 0) {
            if ((if (c & 32) == 0: 1 else: 0) != 0) {
                var __ci_expr_old_1: *const u8 = p

                (p = p + 1)

                (c = (((c & 31) as c_uint) << 6) | ((unsafe: *__ci_expr_old_1) & 63))

            } else {
                if ((if (c & 16) == 0: 1 else: 0) != 0) {
                    (c = ((((c & 15) as c_uint) << 12) | ((((unsafe: *p) & 63) as c_uint) << 6)) | ((unsafe: p[1]) & 63))

                    (p = p + 2)

                } else {
                    if ((if (c & 8) == 0: 1 else: 0) != 0) {
                        (c = (((((c & 7) as c_uint) << 18) | ((((unsafe: *p) & 63) as c_uint) << 12)) | ((((unsafe: p[1]) & 63) as c_uint) << 6)) | ((unsafe: p[2]) & 63))

                        (p = p + 3)

                    } else {
                        if ((if (c & 4) == 0: 1 else: 0) != 0) {
                            (c = ((((((c & 3) as c_uint) << 24) | ((((unsafe: *p) & 63) as c_uint) << 18)) | ((((unsafe: p[1]) & 63) as c_uint) << 12)) | ((((unsafe: p[2]) & 63) as c_uint) << 6)) | ((unsafe: p[3]) & 63))

                            (p = p + 4)

                        } else {
                            (c = (((((((c & 1) as c_uint) << 30) | ((((unsafe: *p) & 63) as c_uint) << 24)) | ((((unsafe: p[1]) & 63) as c_uint) << 18)) | ((((unsafe: p[2]) & 63) as c_uint) << 12)) | ((((unsafe: p[3]) & 63) as c_uint) << 6)) | ((unsafe: p[4]) & 63))

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

                (re.start_bitmap[(buff[0] / 8)] = re.start_bitmap[(buff[0] / 8)] | ((1 as c_uint) << (buff[0] & 7)))

            } else {
                if ((if c < 256: 1 else: 0) != 0) {
                    (re.start_bitmap[(c / 8)] = re.start_bitmap[(c / 8)] | ((1 as c_uint) << (c & 7)))
                }
            }

        } else {
            if (1 != 0) {
                (re.start_bitmap[((unsafe: re.tables[(256 +% c)]) / 8)] = re.start_bitmap[((unsafe: re.tables[(256 +% c)]) / 8)] | ((1 as c_uint) << ((unsafe: re.tables[(256 +% c)]) & 7)))
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
        if ((if ((unsafe: re.tables[(512 +% (c / 8))]) & ((1 as c_uint) << (c & 7))) != 0: 1 else: 0) != 0) {
            var buff: [6]u8

            _pcre2_ord2utf_8(c, (&buff[0] as *mut u8))

            (re.start_bitmap[(buff[0] / 8)] = re.start_bitmap[(buff[0] / 8)] | ((1 as c_uint) << (buff[0] & 7)))

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


    (type_ = ((((unsafe: code[0]) as c_int) << 8) as c_uint) | (unsafe: code[1]))

    (code = code + 2)

    (next_char = char_lists_end - (((((((unsafe: code[0]) as c_int) << 8) | (unsafe: code[(0 + 1)])) as c_uint) as c_uint) << 1))

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
                (range_end = (char_list_add +% ((range_end as c_uint) >> 1)))

                _pcre2_ord2utf_8(range_end, (&end_buffer[0] as *mut u8))

                (end = end_buffer[0])

                if ((if range_start < range_end: 1 else: 0) != 0) {
                    _pcre2_ord2utf_8(range_start, (&start_buffer[0] as *mut u8))

                    (start = start_buffer[0])

                    while ((if start <= end: 1 else: 0) != 0) {
                        ((unsafe: start_bitmap[(start / 8)]) = (unsafe: start_bitmap[(start / 8)]) | ((1 as c_uint) << (start & 7)))

                        (start = start + 1)

                    }


                } else {
                    ((unsafe: start_bitmap[(end / 8)]) = (unsafe: start_bitmap[(end / 8)]) | ((1 as c_uint) << (end & 7)))
                }

                (range_start = (~(0 as c_uint)))

            } else {
                (range_start = (char_list_add +% ((range_end as c_uint) >> 1)))
            }

            (item_count = item_count - 1)

        }

        (list_ind = list_ind + 1)

        (type_ = type_ >> 3)

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
                    ((unsafe: start_bitmap[(start / 8)]) = (unsafe: start_bitmap[(start / 8)]) | ((1 as c_uint) << (start & 7)))

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
        match __pc:
            0 =>
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
                while true {
                    (try_next__goto_1110_8 = 1)
                    if (__goto_pending != 0) {
                        break
                    }
                    (tcode__goto_1111_14 = (code + ((1 as isize) as usize)) + ((2 as isize) as usize))
                    if (__goto_pending != 0) {
                        break
                    }
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
                        break
                    }
                    while (try_next__goto_1110_8 != 0) {
                        (classmap__goto_1120_20 = ((null as *const u8)))
                        if (__goto_pending != 0) {
                            break
                        }
                        match (unsafe: *tcode__goto_1111_14):
                            OP_ACCEPT =>
                                return SSB_FAIL
                            OP_ASSERT_ACCEPT =>
                                return SSB_FAIL
                            OP_ALLANY =>
                                return SSB_FAIL
                            OP_ANY =>
                                return SSB_FAIL
                            OP_ANYBYTE =>
                                return SSB_FAIL
                            OP_CIRCM =>
                                return SSB_FAIL
                            OP_CLOSE =>
                                return SSB_FAIL
                            OP_COMMIT =>
                                return SSB_FAIL
                            OP_COMMIT_ARG =>
                                return SSB_FAIL
                            OP_COND =>
                                return SSB_FAIL
                            OP_CREF =>
                                return SSB_FAIL
                            OP_FALSE =>
                                return SSB_FAIL
                            OP_TRUE =>
                                return SSB_FAIL
                            OP_DNCREF =>
                                return SSB_FAIL
                            OP_DNREF =>
                                return SSB_FAIL
                            OP_DNREFI =>
                                return SSB_FAIL
                            OP_DNRREF =>
                                return SSB_FAIL
                            OP_DOLL =>
                                return SSB_FAIL
                            OP_DOLLM =>
                                return SSB_FAIL
                            OP_END =>
                                return SSB_FAIL
                            OP_EOD =>
                                return SSB_FAIL
                            OP_EODN =>
                                return SSB_FAIL
                            OP_EXTUNI =>
                                return SSB_FAIL
                            OP_FAIL =>
                                return SSB_FAIL
                            OP_MARK =>
                                return SSB_FAIL
                            OP_NOT =>
                                return SSB_FAIL
                            OP_NOTEXACT =>
                                return SSB_FAIL
                            OP_NOTEXACTI =>
                                return SSB_FAIL
                            OP_NOTI =>
                                return SSB_FAIL
                            OP_NOTMINPLUS =>
                                return SSB_FAIL
                            OP_NOTMINPLUSI =>
                                return SSB_FAIL
                            OP_NOTMINQUERY =>
                                return SSB_FAIL
                            OP_NOTMINQUERYI =>
                                return SSB_FAIL
                            OP_NOTMINSTAR =>
                                return SSB_FAIL
                            OP_NOTMINSTARI =>
                                return SSB_FAIL
                            OP_NOTMINUPTO =>
                                return SSB_FAIL
                            OP_NOTMINUPTOI =>
                                return SSB_FAIL
                            OP_NOTPLUS =>
                                return SSB_FAIL
                            OP_NOTPLUSI =>
                                return SSB_FAIL
                            OP_NOTPOSPLUS =>
                                return SSB_FAIL
                            OP_NOTPOSPLUSI =>
                                return SSB_FAIL
                            OP_NOTPOSQUERY =>
                                return SSB_FAIL
                            OP_NOTPOSQUERYI =>
                                return SSB_FAIL
                            OP_NOTPOSSTAR =>
                                return SSB_FAIL
                            OP_NOTPOSSTARI =>
                                return SSB_FAIL
                            OP_NOTPOSUPTO =>
                                return SSB_FAIL
                            OP_NOTPOSUPTOI =>
                                return SSB_FAIL
                            OP_NOTPROP =>
                                return SSB_FAIL
                            OP_NOTQUERY =>
                                return SSB_FAIL
                            OP_NOTQUERYI =>
                                return SSB_FAIL
                            OP_NOTSTAR =>
                                return SSB_FAIL
                            OP_NOTSTARI =>
                                return SSB_FAIL
                            OP_NOTUPTO =>
                                return SSB_FAIL
                            OP_NOTUPTOI =>
                                return SSB_FAIL
                            OP_NOT_HSPACE =>
                                return SSB_FAIL
                            OP_NOT_VSPACE =>
                                return SSB_FAIL
                            OP_PRUNE =>
                                return SSB_FAIL
                            OP_PRUNE_ARG =>
                                return SSB_FAIL
                            OP_RECURSE =>
                                return SSB_FAIL
                            OP_REF =>
                                return SSB_FAIL
                            OP_REFI =>
                                return SSB_FAIL
                            OP_REVERSE =>
                                return SSB_FAIL
                            OP_VREVERSE =>
                                return SSB_FAIL
                            OP_RREF =>
                                return SSB_FAIL
                            OP_SCOND =>
                                return SSB_FAIL
                            OP_SET_SOM =>
                                return SSB_FAIL
                            OP_SKIP =>
                                return SSB_FAIL
                            OP_SKIP_ARG =>
                                return SSB_FAIL
                            OP_SOD =>
                                return SSB_FAIL
                            OP_SOM =>
                                return SSB_FAIL
                            OP_THEN =>
                                return SSB_FAIL
                            OP_THEN_ARG =>
                                return SSB_FAIL
                            OP_CIRC =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + _pcre2_OP_lengths_8[OP_CIRC])
                            OP_PROP =>
                                if ((if (unsafe: tcode__goto_1111_14[1]) != 9: 1 else: 0) != 0) {
                                    return SSB_FAIL
                                }

                                (p__goto_1225_25 = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + (((unsafe: tcode__goto_1111_14[2]) as isize) as usize))

                                if (__goto_pending != 0) {
                                    break
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
                                        (re.start_bitmap[(255 / 8)] = re.start_bitmap[(255 / 8)] | ((1 as c_uint) << (255 & 7)))
                                    } else {
                                        (re.start_bitmap[(c__goto_1096_10 / 8)] = re.start_bitmap[(c__goto_1096_10 / 8)] | ((1 as c_uint) << (c__goto_1096_10 & 7)))
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


                                (try_next__goto_1110_8 = 0)

                            OP_WORD_BOUNDARY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_NOT_WORD_BOUNDARY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_UCP_WORD_BOUNDARY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_NOT_UCP_WORD_BOUNDARY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_ASSERT =>
                                (ncode__goto_1119_16 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                while ((if (unsafe: *ncode__goto_1119_16) == OP_ALT: 1 else: 0) != 0) {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << 8) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))

                                match (unsafe: *ncode__goto_1119_16):
                                    OP_PROP =>
                                        if ((if (unsafe: ncode__goto_1119_16[1]) != 9: 1 else: 0) != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue


                                    OP_ANYNL =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_CHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_CHARI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_EXACT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_EXACTI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_HSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_MINPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_MINPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_PLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_PLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_POSPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_POSPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_VSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_NOT_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_NOT_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_NOT_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    _ =>
                                        0

                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }


                            OP_ASSERT_NA =>
                                (ncode__goto_1119_16 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                while ((if (unsafe: *ncode__goto_1119_16) == OP_ALT: 1 else: 0) != 0) {
                                    (ncode__goto_1119_16 = ncode__goto_1119_16 + (((((unsafe: ncode__goto_1119_16[1]) as c_int) << 8) | (unsafe: ncode__goto_1119_16[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                (ncode__goto_1119_16 = ncode__goto_1119_16 + (1 + 2))

                                match (unsafe: *ncode__goto_1119_16):
                                    OP_PROP =>
                                        if ((if (unsafe: ncode__goto_1119_16[1]) != 9: 1 else: 0) != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue


                                    OP_ANYNL =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_CHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_CHARI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_EXACT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_EXACTI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_HSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_MINPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_MINPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_PLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_PLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_POSPLUS =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_POSPLUSI =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_VSPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_NOT_DIGIT =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_NOT_WORDCHAR =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    OP_NOT_WHITESPACE =>
                                        (tcode__goto_1111_14 = ncode__goto_1119_16)

                                        continue

                                    _ =>
                                        0

                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }


                            OP_BRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_SBRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_CBRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_SCBRA =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_BRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_SBRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_CBRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_SCBRAPOS =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_ONCE =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_SCRIPT_RUN =>
                                (rc__goto_1118_9 = set_start_bits(re, tcode__goto_1111_14, utf, ucp, depthptr))

                                if ((if rc__goto_1118_9 == SSB_DONE: 1 else: 0) != 0) {
                                    (try_next__goto_1110_8 = 0)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    if ((if rc__goto_1118_9 == SSB_CONTINUE: 1 else: 0) != 0) {
                                        while true {
                                            (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                            if (__goto_pending != 0) {
                                                break
                                            }

                                            if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                                break
                                            }

                                        }

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                        (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                                        if (__goto_pending != 0) {
                                            break
                                        }

                                    } else {
                                        return rc__goto_1118_9
                                    }
                                }

                            OP_ALT =>
                                (yield___goto_1097_5 = SSB_CONTINUE)

                                (try_next__goto_1110_8 = 0)

                            OP_KET =>
                                return SSB_CONTINUE
                            OP_KETRMAX =>
                                return SSB_CONTINUE
                            OP_KETRMIN =>
                                return SSB_CONTINUE
                            OP_KETRPOS =>
                                return SSB_CONTINUE
                            OP_CALLOUT =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + _pcre2_OP_lengths_8[OP_CALLOUT])
                            OP_CALLOUT_STR =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[(1 + (2 * 2))]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[((1 + (2 * 2)) + 1)])) as c_uint))
                            OP_ASSERT_NOT =>
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_ASSERTBACK =>
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_ASSERTBACK_NOT =>
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_ASSERTBACK_NA =>
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_ASSERT_SCS =>
                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_BRAZERO =>
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
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_BRAMINZERO =>
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
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_BRAPOSZERO =>
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
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_SKIPZERO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                                while true {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    if (not ((if (unsafe: *tcode__goto_1111_14) == OP_ALT: 1 else: 0) != 0)) {
                                        break
                                    }

                                }

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))

                            OP_STAR =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                            OP_MINSTAR =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                            OP_POSSTAR =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                            OP_QUERY =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                            OP_MINQUERY =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                            OP_POSQUERY =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp))
                            OP_STARI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                            OP_MINSTARI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                            OP_POSSTARI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                            OP_QUERYI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                            OP_MINQUERYI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                            OP_POSQUERYI =>
                                (tcode__goto_1111_14 = set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp))
                            OP_UPTO =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 0, utf, ucp))
                            OP_MINUPTO =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 0, utf, ucp))
                            OP_POSUPTO =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 0, utf, ucp))
                            OP_UPTOI =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 1, utf, ucp))
                            OP_MINUPTOI =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 1, utf, ucp))
                            OP_POSUPTOI =>
                                (tcode__goto_1111_14 = set_table_bit(re, ((tcode__goto_1111_14 + ((1 as isize) as usize)) + ((2 as isize) as usize)), 1, utf, ucp))
                            OP_EXACT =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                                (try_next__goto_1110_8 = 0)


                            OP_CHAR =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_PLUS =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_MINPLUS =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_POSPLUS =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 0, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_EXACTI =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                                (try_next__goto_1110_8 = 0)


                            OP_CHARI =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_PLUSI =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_MINPLUSI =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_POSPLUSI =>
                                set_table_bit(re, (tcode__goto_1111_14 + ((1 as isize) as usize)), 1, utf, ucp)

                                (try_next__goto_1110_8 = 0)

                            OP_HSPACE =>
                                (re.start_bitmap[(9 / 8)] = re.start_bitmap[(9 / 8)] | ((1 as c_uint) << (9 & 7)))

                                (re.start_bitmap[(32 / 8)] = re.start_bitmap[(32 / 8)] | ((1 as c_uint) << (32 & 7)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << (194 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (re.start_bitmap[(225 / 8)] = re.start_bitmap[(225 / 8)] | ((1 as c_uint) << (225 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << (226 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (re.start_bitmap[(227 / 8)] = re.start_bitmap[(227 / 8)] | ((1 as c_uint) << (227 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    (re.start_bitmap[(160 / 8)] = re.start_bitmap[(160 / 8)] | ((1 as c_uint) << (160 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                (try_next__goto_1110_8 = 0)

                            OP_ANYNL =>
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << (10 & 7)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << (11 & 7)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << (12 & 7)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << (13 & 7)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << (194 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << (226 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << (133 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                (try_next__goto_1110_8 = 0)

                            OP_VSPACE =>
                                (re.start_bitmap[(10 / 8)] = re.start_bitmap[(10 / 8)] | ((1 as c_uint) << (10 & 7)))

                                (re.start_bitmap[(11 / 8)] = re.start_bitmap[(11 / 8)] | ((1 as c_uint) << (11 & 7)))

                                (re.start_bitmap[(12 / 8)] = re.start_bitmap[(12 / 8)] | ((1 as c_uint) << (12 & 7)))

                                (re.start_bitmap[(13 / 8)] = re.start_bitmap[(13 / 8)] | ((1 as c_uint) << (13 & 7)))

                                if (utf != 0) {
                                    (re.start_bitmap[(194 / 8)] = re.start_bitmap[(194 / 8)] | ((1 as c_uint) << (194 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (re.start_bitmap[(226 / 8)] = re.start_bitmap[(226 / 8)] | ((1 as c_uint) << (226 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                } else {
                                    (re.start_bitmap[(133 / 8)] = re.start_bitmap[(133 / 8)] | ((1 as c_uint) << (133 & 7)))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                (try_next__goto_1110_8 = 0)

                            OP_NOT_DIGIT =>
                                set_nottype_bits(re, 64, table_limit__goto_1100_5)

                                (try_next__goto_1110_8 = 0)

                            OP_DIGIT =>
                                set_type_bits(re, 64, table_limit__goto_1100_5)

                                (try_next__goto_1110_8 = 0)

                            OP_NOT_WHITESPACE =>
                                set_nottype_bits(re, 0, table_limit__goto_1100_5)

                                (try_next__goto_1110_8 = 0)

                            OP_WHITESPACE =>
                                set_type_bits(re, 0, table_limit__goto_1100_5)

                                (try_next__goto_1110_8 = 0)

                            OP_NOT_WORDCHAR =>
                                set_nottype_bits(re, 160, table_limit__goto_1100_5)

                                (try_next__goto_1110_8 = 0)

                            OP_WORDCHAR =>
                                set_type_bits(re, 160, table_limit__goto_1100_5)

                                (try_next__goto_1110_8 = 0)

                            OP_TYPEPLUS =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_TYPEMINPLUS =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_TYPEPOSPLUS =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)
                            OP_TYPEEXACT =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + (1 + 2))
                            OP_TYPEUPTO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                            OP_TYPEMINUPTO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                            OP_TYPEPOSUPTO =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)

                            OP_TYPESTAR =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEMINSTAR =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEPOSSTAR =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEQUERY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEMINQUERY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_TYPEPOSQUERY =>
                                (tcode__goto_1111_14 = tcode__goto_1111_14 + 2)
                            OP_ECLASS =>
                                return SSB_FAIL
                            OP_XCLASS =>
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
                                    0
                                }


                                if (utf != 0) {
                                    (re.start_bitmap[24] = re.start_bitmap[24] | 240)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memset((((&re.start_bitmap[0] as *mut u8) + ((25 as isize) as usize)) as *i8), 255, (7 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                if ((if (unsafe: *tcode__goto_1111_14) == OP_XCLASS: 1 else: 0) != 0) {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))
                                } else {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                                    (classmap__goto_1120_20 = tcode__goto_1111_14)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

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
                                            break
                                        }

                                        (c__goto_1096_10 = 128)

                                        while ((if c__goto_1096_10 < 256: 1 else: 0) != 0) {
                                            if ((if ((unsafe: classmap__goto_1120_20[(c__goto_1096_10 / 8)]) & ((1 as c_uint) << (c__goto_1096_10 & 7))) != 0: 1 else: 0) != 0) {
                                                (d__goto_1845_19 = ((c__goto_1096_10 as c_uint) >> 6) | 192)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (re.start_bitmap[(d__goto_1845_19 / 8)] = re.start_bitmap[(d__goto_1845_19 / 8)] | ((1 as c_uint) << (d__goto_1845_19 & 7)))

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
                                            break
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
                                            break
                                        }

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }



                            OP_NCLASS =>
                                if (utf != 0) {
                                    (re.start_bitmap[24] = re.start_bitmap[24] | 240)

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    with_memset((((&re.start_bitmap[0] as *mut u8) + ((25 as isize) as usize)) as *i8), 255, (7 as i64))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                                if ((if (unsafe: *tcode__goto_1111_14) == OP_XCLASS: 1 else: 0) != 0) {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))
                                } else {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                                    (classmap__goto_1120_20 = tcode__goto_1111_14)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

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
                                            break
                                        }

                                        (c__goto_1096_10 = 128)

                                        while ((if c__goto_1096_10 < 256: 1 else: 0) != 0) {
                                            if ((if ((unsafe: classmap__goto_1120_20[(c__goto_1096_10 / 8)]) & ((1 as c_uint) << (c__goto_1096_10 & 7))) != 0: 1 else: 0) != 0) {
                                                (d__goto_1845_19 = ((c__goto_1096_10 as c_uint) >> 6) | 192)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (re.start_bitmap[(d__goto_1845_19 / 8)] = re.start_bitmap[(d__goto_1845_19 / 8)] | ((1 as c_uint) << (d__goto_1845_19 & 7)))

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
                                            break
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
                                            break
                                        }

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }


                            OP_CLASS =>
                                if ((if (unsafe: *tcode__goto_1111_14) == OP_XCLASS: 1 else: 0) != 0) {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (((((unsafe: tcode__goto_1111_14[1]) as c_int) << 8) | (unsafe: tcode__goto_1111_14[(1 + 1)])) as c_uint))
                                } else {
                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + 1)

                                    (classmap__goto_1120_20 = tcode__goto_1111_14)


                                    if (__goto_pending != 0) {
                                        break
                                    }

                                    (tcode__goto_1111_14 = tcode__goto_1111_14 + (32 / sizeof[u8]()))

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

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
                                            break
                                        }

                                        (c__goto_1096_10 = 128)

                                        while ((if c__goto_1096_10 < 256: 1 else: 0) != 0) {
                                            if ((if ((unsafe: classmap__goto_1120_20[(c__goto_1096_10 / 8)]) & ((1 as c_uint) << (c__goto_1096_10 & 7))) != 0: 1 else: 0) != 0) {
                                                (d__goto_1845_19 = ((c__goto_1096_10 as c_uint) >> 6) | 192)

                                                if (__goto_pending != 0) {
                                                    break
                                                }

                                                (re.start_bitmap[(d__goto_1845_19 / 8)] = re.start_bitmap[(d__goto_1845_19 / 8)] | ((1 as c_uint) << (d__goto_1845_19 & 7)))

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
                                            break
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
                                            break
                                        }

                                    }

                                    if (__goto_pending != 0) {
                                        break
                                    }

                                }

                            _ =>
                                return SSB_UNKNOWN
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
                    (code = code + (((((unsafe: code[1]) as c_int) << 8) | (unsafe: code[(1 + 1)])) as c_uint))
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    if (not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0)) {
                        break
                    }
                }
                if (__goto_pending != 0) {
                    continue
                }
                return yield___goto_1097_5
                if (__goto_pending != 0) {
                    continue
                }
            _ => break
    }
}
