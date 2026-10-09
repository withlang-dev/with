// Migrated from C
use std.zl.defs
use std.zl.zutil
use std.zl.inflate
use std.zl.infback
use std.zl.compress
use std.zl.uncompr
use std.zl.gzlib
use std.zl.gzwrite
use std.zl.gzread
use std.zl.gzclose
use std.zl.adler32
use std.zl.crc32
use std.zl.inftrees
use std.zl.trees
use std.option

pub unsafe fn deflate(__param_strm: *mut z_stream_s, __param_flush: c_int) -> c_int {
    var __local_old_flush: c_int

    var __local_s: *mut internal_state

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if (deflateStateCheck(__param_strm) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_flush > 5: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_flush < 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -2

    }


    (__local_s = (*__param_strm).state)

    var __ci_expr_logic_5: c_int

    var __ci_expr_logic_3: c_int

    if ((if (*__param_strm).next_out == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_2: c_int = 0

        if ((if (*__param_strm).avail_in != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (*__param_strm).next_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_5 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_4: c_int = 0

        if ((if (*__local_s).status == 666: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_5 != 0) {
        var __ci_expr_ternary_7: c_int = 0

        var __ci_expr_logic_6: c_int

        if ((if -2 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if -2 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_ternary_7 = ((9 as c_int)))
        } else {
            (__ci_expr_ternary_7 = (((2 - -2) as c_int)))
        }

        ((*__param_strm).msg = ((z_errmsg[__ci_expr_ternary_7] as *mut c_char)))

        return -2


    }


    if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
        var __ci_expr_ternary_9: c_int = 0

        var __ci_expr_logic_8: c_int

        if ((if -5 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_ternary_9 = ((9 as c_int)))
        } else {
            (__ci_expr_ternary_9 = (((2 - -5) as c_int)))
        }

        ((*__param_strm).msg = ((z_errmsg[__ci_expr_ternary_9] as *mut c_char)))

        return -5

    }

    (__local_old_flush = (*__local_s).last_flush)

    ((*__local_s).last_flush = __param_flush)

    if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
        flush_pending(__param_strm)

        if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
            ((*__local_s).last_flush = ((-1 as c_int)))

            return 0

        }

    } else {
        var __ci_expr_logic_11: c_int = 0

        var __ci_expr_logic_10: c_int = 0

        if ((if (*__param_strm).avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if ((__param_flush * 2) - (if (if __param_flush > 4: 1 else: 0) != 0: (9 as c_int) else: (0 as c_int))) <= ((__local_old_flush * 2) - (if (if __local_old_flush > 4: 1 else: 0) != 0: (9 as c_int) else: (0 as c_int))): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_11 != 0) {
            var __ci_expr_ternary_13: c_int = 0

            var __ci_expr_logic_12: c_int

            if ((if -5 < -6: 1 else: 0) != 0) {
                (__ci_expr_logic_12 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_12 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_12 != 0) {
                (__ci_expr_ternary_13 = ((9 as c_int)))
            } else {
                (__ci_expr_ternary_13 = (((2 - -5) as c_int)))
            }

            ((*__param_strm).msg = ((z_errmsg[__ci_expr_ternary_13] as *mut c_char)))

            return -5


        }

    }

    var __ci_expr_logic_14: c_int = 0

    if ((if (*__local_s).status == 666: 1 else: 0) != 0) {
        (__ci_expr_logic_14 = (if (if (*__param_strm).avail_in != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_14 != 0) {
        var __ci_expr_ternary_16: c_int = 0

        var __ci_expr_logic_15: c_int

        if ((if -5 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_15 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_ternary_16 = ((9 as c_int)))
        } else {
            (__ci_expr_ternary_16 = (((2 - -5) as c_int)))
        }

        ((*__param_strm).msg = ((z_errmsg[__ci_expr_ternary_16] as *mut c_char)))

        return -5


    }


    var __ci_expr_logic_17: c_int = 0

    if ((if (*__local_s).status == 42: 1 else: 0) != 0) {
        (__ci_expr_logic_17 = (if (if (*__local_s).wrap == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_17 != 0) {
        ((*__local_s).status = ((113 as c_int)))
    }


    if ((if (*__local_s).status == 42: 1 else: 0) != 0) {
        var __local_header: c_uint = ((((((8 as c_uint) +% ((((((*__local_s).w_bits as c_uint) -% (8 as c_uint)) as c_uint) << (4 as c_uint)) as c_uint)) as c_uint) << (8 as c_uint)) as c_uint))

        var __local_level_flags: c_uint

        var __ci_expr_logic_18: c_int

        if ((if (*__local_s).strategy >= 2: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_18 = (if (if (*__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_18 != 0) {
            (__local_level_flags = ((0 as c_uint)))
        } else {
            if ((if (*__local_s).level < 6: 1 else: 0) != 0) {
                (__local_level_flags = ((1 as c_uint)))
            } else {
                if ((if (*__local_s).level == 6: 1 else: 0) != 0) {
                    (__local_level_flags = ((2 as c_uint)))
                } else {
                    (__local_level_flags = ((3 as c_uint)))
                }
            }
        }


        (__local_header = (__local_header as c_uint) | (((__local_level_flags as c_uint) << (6 as c_uint)) as c_uint))

        if ((if (*__local_s).strstart != 0: 1 else: 0) != 0) {
            (__local_header = (__local_header as c_uint) | (32 as c_uint))
        }

        (__local_header = (__local_header +% ((31 as c_uint) -% (((__local_header as c_uint) % (31 as c_uint)) as c_uint))))

        putShortMSB(__local_s, __local_header)

        if ((if (*__local_s).strstart != 0: 1 else: 0) != 0) {
            putShortMSB(__local_s, ((((*__param_strm).adler as c_ulong) >> (16 as c_uint)) as c_uint))

            putShortMSB(__local_s, ((((*__param_strm).adler as c_ulong) & (65535 as c_ulong)) as c_uint))

        }

        ((*__param_strm).adler = ((adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        ((*__local_s).status = ((113 as c_int)))

        flush_pending(__param_strm)

        if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
            ((*__local_s).last_flush = ((-1 as c_int)))

            return 0

        }

    }

    if ((if (*__local_s).status == 57: 1 else: 0) != 0) {
        ((*__param_strm).adler = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        var __ci_expr_old_19: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_19]) = ((31 as u8)))




        var __ci_expr_old_20: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_20]) = ((139 as u8)))




        var __ci_expr_old_21: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_21]) = ((8 as u8)))




        if ((if (*__local_s).gzhead == 0: 1 else: 0) != 0) {
            var __ci_expr_old_22: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_22]) = ((0 as u8)))




            var __ci_expr_old_23: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_23]) = ((0 as u8)))




            var __ci_expr_old_24: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_24]) = ((0 as u8)))




            var __ci_expr_old_25: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_25]) = ((0 as u8)))




            var __ci_expr_old_26: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_26]) = ((0 as u8)))




            var __ci_expr_old_27: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            var __ci_expr_ternary_30: c_int = 0

            if ((if (*__local_s).level == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_30 = ((2 as c_int)))
            } else {
                var __ci_expr_ternary_29: c_int = 0

                var __ci_expr_logic_28: c_int

                if ((if (*__local_s).strategy >= 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_28 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_28 = (if (if (*__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_28 != 0) {
                    (__ci_expr_ternary_29 = ((4 as c_int)))
                } else {
                    (__ci_expr_ternary_29 = ((0 as c_int)))
                }

                (__ci_expr_ternary_30 = __ci_expr_ternary_29)

            }

            (((*__local_s).pending_buf[__ci_expr_old_27]) = ((__ci_expr_ternary_30 as u8)))




            var __ci_expr_old_31: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_31]) = ((19 as u8)))




            ((*__local_s).status = ((113 as c_int)))

            flush_pending(__param_strm)

            if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                ((*__local_s).last_flush = ((-1 as c_int)))

                return 0

            }

        } else {
            var __ci_expr_old_32: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_32]) = (((((((if (*__local_s).gzhead.text != 0: (1 as c_int) else: (0 as c_int)) + (if (*__local_s).gzhead.hcrc != 0: (2 as c_int) else: (0 as c_int))) + (if (if (*__local_s).gzhead.extra == 0: 1 else: 0) != 0: (0 as c_int) else: (4 as c_int))) + (if (if (*__local_s).gzhead.name == 0: 1 else: 0) != 0: (0 as c_int) else: (8 as c_int))) + (if (if (*__local_s).gzhead.comment == 0: 1 else: 0) != 0: (0 as c_int) else: (16 as c_int))) as u8)))




            var __ci_expr_old_33: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_33]) = (((((*__local_s).gzhead.time as c_ulong) & (255 as c_ulong)) as u8)))




            var __ci_expr_old_34: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_34]) = (((((((*__local_s).gzhead.time as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




            var __ci_expr_old_35: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_35]) = (((((((*__local_s).gzhead.time as c_ulong) >> (16 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




            var __ci_expr_old_36: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_36]) = (((((((*__local_s).gzhead.time as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




            var __ci_expr_old_37: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            var __ci_expr_ternary_40: c_int = 0

            if ((if (*__local_s).level == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_40 = ((2 as c_int)))
            } else {
                var __ci_expr_ternary_39: c_int = 0

                var __ci_expr_logic_38: c_int

                if ((if (*__local_s).strategy >= 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_38 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_38 = (if (if (*__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_38 != 0) {
                    (__ci_expr_ternary_39 = ((4 as c_int)))
                } else {
                    (__ci_expr_ternary_39 = ((0 as c_int)))
                }

                (__ci_expr_ternary_40 = __ci_expr_ternary_39)

            }

            (((*__local_s).pending_buf[__ci_expr_old_37]) = ((__ci_expr_ternary_40 as u8)))




            var __ci_expr_old_41: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_41]) = (((((*__local_s).gzhead.os as c_int) & (255 as c_int)) as u8)))




            if ((if (*__local_s).gzhead.extra != 0: 1 else: 0) != 0) {
                var __ci_expr_old_42: c_ulong = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_42]) = (((((*__local_s).gzhead.extra_len as c_uint) & (255 as c_uint)) as u8)))




                var __ci_expr_old_43: c_ulong = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_43]) = (((((((*__local_s).gzhead.extra_len as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))




            }

            if ((*__local_s).gzhead.hcrc != 0) {
                ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, ((*__local_s).pending_buf as *const u8), (*__local_s).pending) as c_ulong)))
            }

            ((*__local_s).gzindex = ((0 as c_ulong)))

            ((*__local_s).status = ((69 as c_int)))

        }

    }

    if ((if (*__local_s).status == 69: 1 else: 0) != 0) {
        if ((if (*__local_s).gzhead.extra != 0: 1 else: 0) != 0) {
            var __local_beg: c_ulong = (*__local_s).pending

            var __local_left: c_ulong = (((((((*__local_s).gzhead.extra_len as c_uint) & (65535 as c_uint)) as c_ulong) -% ((*__local_s).gzindex as c_ulong)) as c_ulong))

            while ((if (((*__local_s).pending as c_ulong) +% (__local_left as c_ulong)) > (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                var __local_copy_: c_ulong = (((((*__local_s).pending_buf_size as c_ulong) -% ((*__local_s).pending as c_ulong)) as c_ulong))

                with_memcpy(((((*__local_s).pending_buf + ((*__local_s).pending as usize)) as *mut c_void) as *mut u8), ((((*__local_s).gzhead.extra + ((*__local_s).gzindex as usize)) as *const c_void) as *const u8), (__local_copy_ as i64))

                ((*__local_s).pending = (*__local_s).pending_buf_size)

                loop {
                    var __ci_expr_logic_44: c_int = 0

                    if ((*__local_s).gzhead.hcrc != 0) {
                        (__ci_expr_logic_44 = (if (if (*__local_s).pending > __local_beg: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_44 != 0) {
                        ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg as usize)) as *const u8), ((((*__local_s).pending as c_ulong) -% (__local_beg as c_ulong)) as c_ulong)) as c_ulong)))
                    }


                    if not ((0 != 0)) {
                        break
                    }
                }

                ((*__local_s).gzindex = ((*__local_s).gzindex +% __local_copy_))

                flush_pending(__param_strm)

                if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                    ((*__local_s).last_flush = ((-1 as c_int)))

                    return 0

                }

                (__local_beg = ((0 as c_ulong)))

                (__local_left = (__local_left -% __local_copy_))

            }

            with_memcpy(((((*__local_s).pending_buf + ((*__local_s).pending as usize)) as *mut c_void) as *mut u8), ((((*__local_s).gzhead.extra + ((*__local_s).gzindex as usize)) as *const c_void) as *const u8), (__local_left as i64))

            ((*__local_s).pending = ((*__local_s).pending +% __local_left))

            loop {
                var __ci_expr_logic_45: c_int = 0

                if ((*__local_s).gzhead.hcrc != 0) {
                    (__ci_expr_logic_45 = (if (if (*__local_s).pending > __local_beg: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_45 != 0) {
                    ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg as usize)) as *const u8), ((((*__local_s).pending as c_ulong) -% (__local_beg as c_ulong)) as c_ulong)) as c_ulong)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

            ((*__local_s).gzindex = ((0 as c_ulong)))

        }

        ((*__local_s).status = ((73 as c_int)))

    }

    if ((if (*__local_s).status == 73: 1 else: 0) != 0) {
        if ((if (*__local_s).gzhead.name != 0: 1 else: 0) != 0) {
            var __local_beg_1: c_ulong = (*__local_s).pending

            var __local_val: c_int

            loop {
                if ((if (*__local_s).pending == (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                    loop {
                        var __ci_expr_logic_46: c_int = 0

                        if ((*__local_s).gzhead.hcrc != 0) {
                            (__ci_expr_logic_46 = (if (if (*__local_s).pending > __local_beg_1: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_46 != 0) {
                            ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_1 as usize)) as *const u8), ((((*__local_s).pending as c_ulong) -% (__local_beg_1 as c_ulong)) as c_ulong)) as c_ulong)))
                        }


                        if not ((0 != 0)) {
                            break
                        }
                    }

                    flush_pending(__param_strm)

                    if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                        ((*__local_s).last_flush = ((-1 as c_int)))

                        return 0

                    }

                    (__local_beg_1 = ((0 as c_ulong)))

                }

                var __ci_expr_old_47: c_ulong = (*__local_s).gzindex

                ((*__local_s).gzindex = ((*__local_s).gzindex +% 1))

                (__local_val = ((((*__local_s).gzhead.name[__ci_expr_old_47]) as c_int)))


                var __ci_expr_old_48: c_ulong = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_48]) = ((__local_val as u8)))




                if not (((if __local_val != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            loop {
                var __ci_expr_logic_49: c_int = 0

                if ((*__local_s).gzhead.hcrc != 0) {
                    (__ci_expr_logic_49 = (if (if (*__local_s).pending > __local_beg_1: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_49 != 0) {
                    ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_1 as usize)) as *const u8), ((((*__local_s).pending as c_ulong) -% (__local_beg_1 as c_ulong)) as c_ulong)) as c_ulong)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

            ((*__local_s).gzindex = ((0 as c_ulong)))

        }

        ((*__local_s).status = ((91 as c_int)))

    }

    if ((if (*__local_s).status == 91: 1 else: 0) != 0) {
        if ((if (*__local_s).gzhead.comment != 0: 1 else: 0) != 0) {
            var __local_beg_2: c_ulong = (*__local_s).pending

            var __local_val_1: c_int

            loop {
                if ((if (*__local_s).pending == (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                    loop {
                        var __ci_expr_logic_50: c_int = 0

                        if ((*__local_s).gzhead.hcrc != 0) {
                            (__ci_expr_logic_50 = (if (if (*__local_s).pending > __local_beg_2: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_50 != 0) {
                            ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_2 as usize)) as *const u8), ((((*__local_s).pending as c_ulong) -% (__local_beg_2 as c_ulong)) as c_ulong)) as c_ulong)))
                        }


                        if not ((0 != 0)) {
                            break
                        }
                    }

                    flush_pending(__param_strm)

                    if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                        ((*__local_s).last_flush = ((-1 as c_int)))

                        return 0

                    }

                    (__local_beg_2 = ((0 as c_ulong)))

                }

                var __ci_expr_old_51: c_ulong = (*__local_s).gzindex

                ((*__local_s).gzindex = ((*__local_s).gzindex +% 1))

                (__local_val_1 = ((((*__local_s).gzhead.comment[__ci_expr_old_51]) as c_int)))


                var __ci_expr_old_52: c_ulong = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_52]) = ((__local_val_1 as u8)))




                if not (((if __local_val_1 != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            loop {
                var __ci_expr_logic_53: c_int = 0

                if ((*__local_s).gzhead.hcrc != 0) {
                    (__ci_expr_logic_53 = (if (if (*__local_s).pending > __local_beg_2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_53 != 0) {
                    ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_2 as usize)) as *const u8), ((((*__local_s).pending as c_ulong) -% (__local_beg_2 as c_ulong)) as c_ulong)) as c_ulong)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

        }

        ((*__local_s).status = ((103 as c_int)))

    }

    if ((if (*__local_s).status == 103: 1 else: 0) != 0) {
        if ((*__local_s).gzhead.hcrc != 0) {
            if ((if (((*__local_s).pending as c_ulong) +% (2 as c_ulong)) > (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                flush_pending(__param_strm)

                if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                    ((*__local_s).last_flush = ((-1 as c_int)))

                    return 0

                }

            }

            var __ci_expr_old_54: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_54]) = (((((*__param_strm).adler as c_ulong) & (255 as c_ulong)) as u8)))




            var __ci_expr_old_55: c_ulong = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_55]) = (((((((*__param_strm).adler as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




            ((*__param_strm).adler = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        }

        ((*__local_s).status = ((113 as c_int)))

        flush_pending(__param_strm)

        if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
            ((*__local_s).last_flush = ((-1 as c_int)))

            return 0

        }

    }

    var __ci_expr_logic_58: c_int

    var __ci_expr_logic_56: c_int

    if ((if (*__param_strm).avail_in != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_56 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_56 = (if (if (*__local_s).lookahead != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_56 != 0) {
        (__ci_expr_logic_58 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_57: c_int = 0

        if ((if __param_flush != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_57 = (if (if (*__local_s).status != 666: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_58 = (if __ci_expr_logic_57 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_58 != 0) {
        var __local_bstate: i32

        (__local_bstate = (((if (if (*__local_s).level == 0: 1 else: 0) != 0: (deflate_stored(__local_s, __param_flush) as c_uint) else: ((if (if (*__local_s).strategy == 2: 1 else: 0) != 0: (deflate_huff(__local_s, __param_flush) as c_uint) else: ((if (if (*__local_s).strategy == 3: 1 else: 0) != 0: (deflate_rle(__local_s, __param_flush) as c_uint) else: (configuration_table[(*__local_s).level].func.unwrap()(__local_s, __param_flush) as c_uint)) as c_uint)) as c_uint)) as i32)))

        var __ci_expr_logic_59: c_int

        if ((if __local_bstate == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_59 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_59 = (if (if __local_bstate == 3: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_59 != 0) {
            ((*__local_s).status = ((666 as c_int)))

        }


        var __ci_expr_logic_60: c_int

        if ((if __local_bstate == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_60 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_60 = (if (if __local_bstate == 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_60 != 0) {
            if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
                ((*__local_s).last_flush = ((-1 as c_int)))

            }

            return 0

        }


        if ((if __local_bstate == 1: 1 else: 0) != 0) {
            if ((if __param_flush == 1: 1 else: 0) != 0) {
                _tr_align(__local_s)

            } else {
                if ((if __param_flush != 5: 1 else: 0) != 0) {
                    _tr_stored_block(__local_s, null, (0 as c_ulong), (0 as c_int))

                    if ((if __param_flush == 3: 1 else: 0) != 0) {
                        loop {
                            (((*__local_s).head[(((*__local_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

                            with_memset((((*__local_s).head as *mut c_void) as *mut u8), (0 as c_int), (((((((*__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

                            ((*__local_s).slid = ((0 as c_int)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if ((if (*__local_s).lookahead == 0: 1 else: 0) != 0) {
                            ((*__local_s).strstart = ((0 as c_uint)))

                            ((*__local_s).block_start = ((0 as c_long)))

                            ((*__local_s).insert = ((0 as c_uint)))

                        }

                    }

                }
            }

            flush_pending(__param_strm)

            if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
                ((*__local_s).last_flush = ((-1 as c_int)))

                return 0

            }

        }

    }


    if ((if __param_flush != 4: 1 else: 0) != 0) {
        return 0
    }

    if ((if (*__local_s).wrap <= 0: 1 else: 0) != 0) {
        return 1
    }

    if ((if (*__local_s).wrap == 2: 1 else: 0) != 0) {
        var __ci_expr_old_61: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_61]) = (((((*__param_strm).adler as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_62: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_62]) = (((((((*__param_strm).adler as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_63: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_63]) = (((((((*__param_strm).adler as c_ulong) >> (16 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_64: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_64]) = (((((((*__param_strm).adler as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_65: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_65]) = (((((*__param_strm).total_in as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_66: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_66]) = (((((((*__param_strm).total_in as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_67: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_67]) = (((((((*__param_strm).total_in as c_ulong) >> (16 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




        var __ci_expr_old_68: c_ulong = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_68]) = (((((((*__param_strm).total_in as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))




    } else {
        putShortMSB(__local_s, ((((*__param_strm).adler as c_ulong) >> (16 as c_uint)) as c_uint))

        putShortMSB(__local_s, ((((*__param_strm).adler as c_ulong) & (65535 as c_ulong)) as c_uint))

    }

    flush_pending(__param_strm)

    if ((if (*__local_s).wrap > 0: 1 else: 0) != 0) {
        ((*__local_s).wrap = (((0 - (*__local_s).wrap) as c_int)))
    }

    return (if (if (*__local_s).pending != 0: 1 else: 0) != 0: (0 as c_int) else: (1 as c_int))

}

pub unsafe fn deflateEnd(__param_strm: *mut z_stream_s) -> c_int {
    var __local_status: c_int

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_status = (*(*__param_strm).state).status)

    if ((*(*__param_strm).state).pending_buf != null) {
        (*__param_strm).zfree.unwrap()((*__param_strm).opaque_, ((*(*__param_strm).state).pending_buf as *mut c_void))
    }



    if ((*(*__param_strm).state).head != null) {
        (*__param_strm).zfree.unwrap()((*__param_strm).opaque_, ((*(*__param_strm).state).head as *mut c_void))
    }



    if ((*(*__param_strm).state).prev != null) {
        (*__param_strm).zfree.unwrap()((*__param_strm).opaque_, ((*(*__param_strm).state).prev as *mut c_void))
    }



    if ((*(*__param_strm).state).window != null) {
        (*__param_strm).zfree.unwrap()((*__param_strm).opaque_, ((*(*__param_strm).state).window as *mut c_void))
    }



    (*__param_strm).zfree.unwrap()((*__param_strm).opaque_, ((*__param_strm).state as *mut c_void))

    ((*__param_strm).state = null)

    return (if (if __local_status == 113: 1 else: 0) != 0: (-3 as c_int) else: (0 as c_int))

}

pub unsafe fn deflateSetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *const u8, __param_dictLength: c_uint) -> c_int {
    var __local_dictionary = __param_dictionary
    var __local_dictLength = __param_dictLength
    var __local_s: *mut internal_state

    var __local_str: c_uint

    var __local_n: c_uint


    var __local_wrap: c_int

    var __local_avail: c_uint

    var __local_next: *mut u8

    var __ci_expr_logic_0: c_int

    if (deflateStateCheck(__param_strm) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_dictionary == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2
    }


    (__local_s = (*__param_strm).state)

    (__local_wrap = (*__local_s).wrap)

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if __local_wrap == 2: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_1: c_int = 0

        if ((if __local_wrap == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__local_s).status != 42: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (*__local_s).lookahead != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return -2
    }


    if ((if __local_wrap == 1: 1 else: 0) != 0) {
        ((*__param_strm).adler = ((adler32((*__param_strm).adler, __local_dictionary, __local_dictLength) as c_ulong)))
    }

    ((*__local_s).wrap = ((0 as c_int)))

    if ((if __local_dictLength >= (*__local_s).w_size: 1 else: 0) != 0) {
        if ((if __local_wrap == 0: 1 else: 0) != 0) {
            loop {
                (((*__local_s).head[(((*__local_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

                with_memset((((*__local_s).head as *mut c_void) as *mut u8), (0 as c_int), (((((((*__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

                ((*__local_s).slid = ((0 as c_int)))

                if not ((0 != 0)) {
                    break
                }
            }

            ((*__local_s).strstart = ((0 as c_uint)))

            ((*__local_s).block_start = ((0 as c_long)))

            ((*__local_s).insert = ((0 as c_uint)))

        }

        (__local_dictionary = __local_dictionary + (((__local_dictLength as c_uint) -% ((*__local_s).w_size as c_uint)) as usize))

        (__local_dictLength = (*__local_s).w_size)

    }

    (__local_avail = (*__param_strm).avail_in)

    (__local_next = (*__param_strm).next_in)

    ((*__param_strm).avail_in = __local_dictLength)

    ((*__param_strm).next_in = ((__local_dictionary as *mut u8)))

    fill_window(__local_s)

    while ((if (*__local_s).lookahead >= 3: 1 else: 0) != 0) {
        (__local_str = (*__local_s).strstart)

        (__local_n = (((((*__local_s).lookahead as c_uint) -% (2 as c_uint)) as c_uint)))

        loop {
            ((*__local_s).ins_h = (((((((((*__local_s).ins_h as c_uint) << ((*__local_s).hash_shift as c_uint)) as c_uint) ^ ((((*__local_s).window[((((__local_str as c_uint) +% (3 as c_uint)) as c_uint) -% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__local_s).hash_mask as c_uint)) as c_uint)))

            (((*__local_s).prev[((__local_str as c_uint) & ((*__local_s).w_mask as c_uint))]) = ((((*__local_s).head[(*__local_s).ins_h]) as c_ushort)))

            (((*__local_s).head[(*__local_s).ins_h]) = ((__local_str as c_ushort)))

            (__local_str = (__local_str +% 1))

            (__local_n = (__local_n -% 1))
            if not ((__local_n != 0)) {
                break
            }
        }

        ((*__local_s).strstart = __local_str)

        ((*__local_s).lookahead = ((2 as c_uint)))

        fill_window(__local_s)

    }

    ((*__local_s).strstart = ((*__local_s).strstart +% (*__local_s).lookahead))

    ((*__local_s).block_start = (((*__local_s).strstart as c_long)))

    ((*__local_s).insert = (*__local_s).lookahead)

    ((*__local_s).lookahead = ((0 as c_uint)))

    ((*__local_s).prev_length = ((2 as c_uint)))

    ((*__local_s).match_length = (*__local_s).prev_length)


    ((*__local_s).match_available = ((0 as c_int)))

    ((*__param_strm).next_in = __local_next)

    ((*__param_strm).avail_in = __local_avail)

    ((*__local_s).wrap = __local_wrap)

    return 0

}

pub unsafe fn deflateGetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *mut u8, __param_dictLength: *mut c_uint) -> c_int {
    var __local_s: *mut internal_state

    var __local_len: c_uint

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    (__local_len = (((((*__local_s).strstart as c_uint) +% ((*__local_s).lookahead as c_uint)) as c_uint)))

    if ((if __local_len > (*__local_s).w_size: 1 else: 0) != 0) {
        (__local_len = (*__local_s).w_size)
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_dictionary != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if __local_len != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy(((__param_dictionary as *mut c_void) as *mut u8), ((((((*__local_s).window + ((*__local_s).strstart as usize)) + ((*__local_s).lookahead as usize)) - (__local_len as usize)) as *const c_void) as *const u8), ((__local_len as c_ulong) as i64))
    }


    if ((if __param_dictLength != 0: 1 else: 0) != 0) {
        ((*__param_dictLength) = __local_len)
    }

    return 0

}

pub unsafe fn deflateCopy(__param_dest: *mut z_stream_s, __param_source: *mut z_stream_s) -> c_int {
    var __local_ds: *mut internal_state

    var __local_ss: *mut internal_state

    var __ci_expr_logic_0: c_int

    if (deflateStateCheck(__param_source) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_dest == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2

    }


    (__local_ss = (*__param_source).state)

    with_memcpy(((__param_dest as *mut c_void) as *mut u8), ((__param_source as *const c_void) as *const u8), ((sizeof[z_stream_s]() as c_ulong) as i64))

    (__local_ds = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (1 as c_uint), (5968 as c_uint)) as *mut internal_state)))

    if ((if __local_ds == 0: 1 else: 0) != 0) {
        return -4
    }

    (*__local_ds) = internal_state.zeroed()

    ((*__param_dest).state = __local_ds)

    with_memcpy(((__local_ds as *mut c_void) as *mut u8), ((__local_ss as *const c_void) as *const u8), ((sizeof[internal_state]() as c_ulong) as i64))

    ((*__local_ds).strm = __param_dest)

    ((*__local_ds).window = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).w_size, (2 as c_uint)) as *mut u8)))

    ((*__local_ds).prev = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).w_size, (2 as c_uint)) as *mut c_ushort)))

    ((*__local_ds).head = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).hash_size, (2 as c_uint)) as *mut c_ushort)))

    ((*__local_ds).pending_buf = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).lit_bufsize, (4 as c_uint)) as *mut u8)))

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    if ((if (*__local_ds).window == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__local_ds).prev == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (*__local_ds).head == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (*__local_ds).pending_buf == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        deflateEnd(__param_dest)

        return -4

    }


    with_memcpy((((*__local_ds).window as *mut c_void) as *mut u8), (((*__local_ss).window as *const c_void) as *const u8), ((*__local_ss).high_water as i64))

    var __ci_expr_ternary_5: c_uint = 0

    var __ci_expr_logic_4: c_int

    if ((*__local_ss).slid != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if (((*__local_ss).strstart as c_uint) -% ((*__local_ss).insert as c_uint)) > (*__local_ds).w_size: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_ternary_5 = (*__local_ds).w_size)
    } else {
        (__ci_expr_ternary_5 = (((((*__local_ss).strstart as c_uint) -% ((*__local_ss).insert as c_uint)) as c_uint)))
    }

    with_memcpy((((*__local_ds).prev as *mut c_void) as *mut u8), (((*__local_ss).prev as *const c_void) as *const u8), ((((__ci_expr_ternary_5 as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))


    with_memcpy((((*__local_ds).head as *mut c_void) as *mut u8), (((*__local_ss).head as *const c_void) as *const u8), (((((*__local_ds).hash_size as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

    ((*__local_ds).pending_out = (*__local_ds).pending_buf + (((((((*__local_ss).pending_out as usize) -% ((*__local_ss).pending_buf as usize)) as c_long) / (sizeof[u8]() as c_long)) as isize) as usize))

    with_memcpy((((*__local_ds).pending_out as *mut c_void) as *mut u8), (((*__local_ss).pending_out as *const c_void) as *const u8), ((*__local_ss).pending as i64))

    ((*__local_ds).sym_buf = (*__local_ds).pending_buf + ((*__local_ds).lit_bufsize as usize))

    with_memcpy((((*__local_ds).sym_buf as *mut c_void) as *mut u8), (((*__local_ss).sym_buf as *const c_void) as *const u8), (((*__local_ss).sym_next as c_ulong) as i64))

    ((*__local_ds).l_desc.dyn_tree = (&(*__local_ds).dyn_ltree[0] as *mut ct_data_s))

    ((*__local_ds).d_desc.dyn_tree = (&(*__local_ds).dyn_dtree[0] as *mut ct_data_s))

    ((*__local_ds).bl_desc.dyn_tree = (&(*__local_ds).bl_tree[0] as *mut ct_data_s))

    return 0

}

pub unsafe fn deflateReset(__param_strm: *mut z_stream_s) -> c_int {
    var __local_ret: c_int

    (__local_ret = ((deflateResetKeep(__param_strm) as c_int)))

    if ((if __local_ret == 0: 1 else: 0) != 0) {
        lm_init((*__param_strm).state)
    }

    return __local_ret

}

pub unsafe fn deflateParams(__param_strm: *mut z_stream_s, __param_level: c_int, __param_strategy: c_int) -> c_int {
    var __local_level = __param_level
    var __local_s: *mut internal_state

    var __local_func: Option[unsafe extern "C" fn(*mut internal_state, c_int) -> i32]

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    if ((if __local_level == -1: 1 else: 0) != 0) {
        (__local_level = ((6 as c_int)))
    }

    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __local_level < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_level > 9: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_strategy < 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __param_strategy > 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -2

    }


    (__local_func = configuration_table[(*__local_s).level].func)

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_3: c_int

    if ((if __param_strategy != (*__local_s).strategy: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if __local_func != configuration_table[__local_level].func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if (if (*__local_s).last_flush != -2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        var __local_err: c_int = ((deflate(__param_strm, (5 as c_int)) as c_int))

        if ((if __local_err == -2: 1 else: 0) != 0) {
            return __local_err
        }

        var __ci_expr_logic_5: c_int

        if ((*__param_strm).avail_in != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_5 = (if (((*__local_s).strstart - (*__local_s).block_start) + (*__local_s).lookahead) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            return -5
        }


    }


    if ((if (*__local_s).level != __local_level: 1 else: 0) != 0) {
        var __ci_expr_logic_6: c_int = 0

        if ((if (*__local_s).level == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (*__local_s).matches != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            if ((if (*__local_s).matches == 1: 1 else: 0) != 0) {
                slide_hash(__local_s)
            } else {
                loop {
                    (((*__local_s).head[(((*__local_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

                    with_memset((((*__local_s).head as *mut c_void) as *mut u8), (0 as c_int), (((((((*__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

                    ((*__local_s).slid = ((0 as c_int)))

                    if not ((0 != 0)) {
                        break
                    }
                }
            }

            ((*__local_s).matches = ((0 as c_uint)))

        }


        ((*__local_s).level = __local_level)

        ((*__local_s).max_lazy_match = ((configuration_table[__local_level].max_lazy as c_uint)))

        ((*__local_s).good_match = ((configuration_table[__local_level].good_length as c_uint)))

        ((*__local_s).nice_match = ((configuration_table[__local_level].nice_length as c_int)))

        ((*__local_s).max_chain_length = ((configuration_table[__local_level].max_chain as c_uint)))

    }

    ((*__local_s).strategy = __param_strategy)

    return 0

}

pub unsafe fn deflateTune(__param_strm: *mut z_stream_s, __param_good_length: c_int, __param_max_lazy: c_int, __param_nice_length: c_int, __param_max_chain: c_int) -> c_int {
    var __local_s: *mut internal_state

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    ((*__local_s).good_match = ((__param_good_length as c_uint)))

    ((*__local_s).max_lazy_match = ((__param_max_lazy as c_uint)))

    ((*__local_s).nice_match = __param_nice_length)

    ((*__local_s).max_chain_length = ((__param_max_chain as c_uint)))

    return 0

}

pub unsafe fn deflateBound(__param_strm: *mut z_stream_s, __param_sourceLen: c_ulong) -> c_ulong {
    var __local_bound: c_ulong = ((deflateBound_z(__param_strm, __param_sourceLen) as c_ulong))

    return (if (if __local_bound != __local_bound: 1 else: 0) != 0: (-1 as c_ulong) else: __local_bound)

}

pub unsafe fn deflateBound_z(__param_strm: *mut z_stream_s, __param_sourceLen: c_ulong) -> c_ulong {
    var __local_s: *mut internal_state

    var __local_fixedlen: c_ulong

    var __local_storelen: c_ulong

    var __local_wraplen: c_ulong

    var __local_bound: c_ulong


    (__local_fixedlen = ((((((((((__param_sourceLen as c_ulong) +% (((__param_sourceLen as c_ulong) >> (3 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (8 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (9 as c_uint)) as c_ulong)) as c_ulong) +% (4 as c_ulong)) as c_ulong)))

    if ((if __local_fixedlen < __param_sourceLen: 1 else: 0) != 0) {
        (__local_fixedlen = ((-1 as c_ulong)))
    }

    (__local_storelen = ((((((((((__param_sourceLen as c_ulong) +% (((__param_sourceLen as c_ulong) >> (5 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (7 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (11 as c_uint)) as c_ulong)) as c_ulong) +% (7 as c_ulong)) as c_ulong)))

    if ((if __local_storelen < __param_sourceLen: 1 else: 0) != 0) {
        (__local_storelen = ((-1 as c_ulong)))
    }

    if (deflateStateCheck(__param_strm) != 0) {
        (__local_bound = (((if (if __local_fixedlen > __local_storelen: 1 else: 0) != 0: __local_fixedlen else: __local_storelen) as c_ulong)))

        return (if (if ((__local_bound as c_ulong) +% (18 as c_ulong)) < __local_bound: 1 else: 0) != 0: (-1 as c_ulong) else: (((__local_bound as c_ulong) +% (18 as c_ulong)) as c_ulong))

    }

    (__local_s = (*__param_strm).state)

    while true {
        match (if (if (*__local_s).wrap < 0: 1 else: 0) != 0: ((0 - (*__local_s).wrap) as c_int) else: (*__local_s).wrap) {
            0 => {
                (__local_wraplen = ((0 as c_ulong)))
            },
            1 => {
                (__local_wraplen = (((6 + (if (*__local_s).strstart != 0: (4 as c_int) else: (0 as c_int))) as c_ulong)))
            },
            2 => {
                (__local_wraplen = ((18 as c_ulong)))

                if ((if (*__local_s).gzhead != 0: 1 else: 0) != 0) {
                    var __local_str: *mut u8

                    if ((if (*__local_s).gzhead.extra != 0: 1 else: 0) != 0) {
                        (__local_wraplen = (__local_wraplen +% ((2 as c_uint) +% ((*__local_s).gzhead.extra_len as c_uint))))
                    }

                    (__local_str = (*__local_s).gzhead.name)

                    if ((if __local_str != 0: 1 else: 0) != 0) {
                        loop {
                            (__local_wraplen = (__local_wraplen +% 1))

                            var __ci_expr_old_0: *mut u8 = __local_str

                            (__local_str = __local_str + 1)

                            if not (((*__ci_expr_old_0) != 0)) {
                                break
                            }
                        }
                    }

                    (__local_str = (*__local_s).gzhead.comment)

                    if ((if __local_str != 0: 1 else: 0) != 0) {
                        loop {
                            (__local_wraplen = (__local_wraplen +% 1))

                            var __ci_expr_old_1: *mut u8 = __local_str

                            (__local_str = __local_str + 1)

                            if not (((*__ci_expr_old_1) != 0)) {
                                break
                            }
                        }
                    }

                    if ((*__local_s).gzhead.hcrc != 0) {
                        (__local_wraplen = (__local_wraplen +% 2))
                    }

                }

            },
            _ => {
                (__local_wraplen = ((18 as c_ulong)))
            },
        }

        break

    }

    var __ci_expr_logic_3: c_int

    if ((if (*__local_s).w_bits != 15: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (*__local_s).hash_bits != 15: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        var __ci_expr_ternary_5: c_ulong = 0

        var __ci_expr_logic_4: c_int = 0

        if ((if (*__local_s).w_bits <= (*__local_s).hash_bits: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (*__local_s).level != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_ternary_5 = __local_fixedlen)
        } else {
            (__ci_expr_ternary_5 = __local_storelen)
        }

        (__local_bound = __ci_expr_ternary_5)


        return (if (if ((__local_bound as c_ulong) +% (__local_wraplen as c_ulong)) < __local_bound: 1 else: 0) != 0: (-1 as c_ulong) else: (((__local_bound as c_ulong) +% (__local_wraplen as c_ulong)) as c_ulong))

    }


    (__local_bound = ((((((((((((((__param_sourceLen as c_ulong) +% (((__param_sourceLen as c_ulong) >> (12 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (14 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (25 as c_uint)) as c_ulong)) as c_ulong) +% (13 as c_ulong)) as c_ulong) -% (6 as c_ulong)) as c_ulong) +% (__local_wraplen as c_ulong)) as c_ulong)))

    return (if (if __local_bound < __param_sourceLen: 1 else: 0) != 0: (-1 as c_ulong) else: __local_bound)

}

pub unsafe fn deflatePending(__param_strm: *mut z_stream_s, __param_pending: *mut c_uint, __param_bits: *mut c_int) -> c_int {
    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    if ((if __param_bits != 0: 1 else: 0) != 0) {
        ((*__param_bits) = (*(*__param_strm).state).bi_valid)
    }

    if ((if __param_pending != 0: 1 else: 0) != 0) {
        ((*__param_pending) = (((*(*__param_strm).state).pending as c_uint)))

        if ((if (*__param_pending) != (*(*__param_strm).state).pending: 1 else: 0) != 0) {
            ((*__param_pending) = ((-1 as c_uint)))

            return -5

        }

    }

    return 0

}

pub unsafe fn deflateUsed(__param_strm: *mut z_stream_s, __param_bits: *mut c_int) -> c_int {
    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    if ((if __param_bits != 0: 1 else: 0) != 0) {
        ((*__param_bits) = (*(*__param_strm).state).bi_used)
    }

    return 0

}

pub unsafe fn deflatePrime(__param_strm: *mut z_stream_s, __param_bits: c_int, __param_value: c_int) -> c_int {
    var __local_bits = __param_bits
    var __local_value = __param_value
    var __local_s: *mut internal_state

    var __local_put: c_int

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __local_bits < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_bits > 16: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__local_s).sym_buf < ((*__local_s).pending_out + (((((16 + 7) as c_int) >> (3 as c_uint)) as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -5
    }


    loop {
        (__local_put = (((16 - (*__local_s).bi_valid) as c_int)))

        if ((if __local_put > __local_bits: 1 else: 0) != 0) {
            (__local_put = __local_bits)
        }

        ((*__local_s).bi_buf = ((*__local_s).bi_buf as c_ushort) | (((((__local_value as c_int) & ((((1 as c_int) << (__local_put as c_uint)) - 1) as c_int)) as c_int) << ((*__local_s).bi_valid as c_uint)) as c_ushort))

        ((*__local_s).bi_valid = (*__local_s).bi_valid + __local_put)

        _tr_flush_bits(__local_s)

        (__local_value = __local_value >> (__local_put as c_uint))

        (__local_bits = __local_bits - __local_put)

        if not ((__local_bits != 0)) {
            break
        }
    }

    return 0

}

pub unsafe fn deflateSetHeader(__param_strm: *mut z_stream_s, __param_head: *mut gz_header_s) -> c_int {
    var __ci_expr_logic_0: c_int

    if (deflateStateCheck(__param_strm) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*(*__param_strm).state).wrap != 2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2
    }


    ((*(*__param_strm).state).gzhead = __param_head)

    return 0

}

pub unsafe fn deflateInit_(__param_strm: *mut z_stream_s, __param_level: c_int, __param_version: *const i8, __param_stream_size: c_int) -> c_int {
    return deflateInit2_(__param_strm, __param_level, (8 as c_int), (15 as c_int), (8 as c_int), (0 as c_int), __param_version, __param_stream_size)

}

pub unsafe fn deflateInit2_(__param_strm: *mut z_stream_s, __param_level: c_int, __param_method: c_int, __param_windowBits: c_int, __param_memLevel: c_int, __param_strategy: c_int, __param_version: *const i8, __param_stream_size: c_int) -> c_int {
    var __local_level = __param_level
    var __local_windowBits = __param_windowBits
    var __local_s: *mut internal_state

    var __local_wrap: c_int = ((1 as c_int))

    var __local_my_version: [6]c_char = [(49 as c_char), (46 as c_char), (51 as c_char), (46 as c_char), (50 as c_char), (0 as c_char)]

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __param_version == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (__param_version[0]) != 49: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if ((__param_stream_size as c_ulong)) != (sizeof[z_stream_s]() as usize): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -6

    }


    if ((if __param_strm == 0: 1 else: 0) != 0) {
        return -2
    }

    ((*__param_strm).msg = null)

    if ((if (*__param_strm).zalloc == ((0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)): 1 else: 0) != 0) {
        ((*__param_strm).zalloc = Some(zcalloc))

        ((*__param_strm).opaque_ = ((0 as *mut c_void)))

    }

    if ((if (*__param_strm).zfree == ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)): 1 else: 0) != 0) {
        ((*__param_strm).zfree = Some(zcfree))
    }

    if ((if __local_level == -1: 1 else: 0) != 0) {
        (__local_level = ((6 as c_int)))
    }

    if ((if __local_windowBits < 0: 1 else: 0) != 0) {
        (__local_wrap = ((0 as c_int)))

        if ((if __local_windowBits < -15: 1 else: 0) != 0) {
            return -2
        }

        (__local_windowBits = (((0 - __local_windowBits) as c_int)))

    } else {
        if ((if __local_windowBits > 15: 1 else: 0) != 0) {
            (__local_wrap = ((2 as c_int)))

            (__local_windowBits = __local_windowBits - 16)

        }
    }

    var __ci_expr_logic_11: c_int

    var __ci_expr_logic_9: c_int

    var __ci_expr_logic_8: c_int

    var __ci_expr_logic_7: c_int

    var __ci_expr_logic_6: c_int

    var __ci_expr_logic_5: c_int

    var __ci_expr_logic_4: c_int

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if __param_memLevel < 1: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __param_memLevel > 9: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if __param_method != 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if __local_windowBits < 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_logic_5 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_5 = (if (if __local_windowBits > 15: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__ci_expr_logic_6 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_6 = (if (if __local_level < 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_7 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_7 = (if (if __local_level > 9: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        (__ci_expr_logic_8 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_8 = (if (if __param_strategy < 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_8 != 0) {
        (__ci_expr_logic_9 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_9 = (if (if __param_strategy > 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_9 != 0) {
        (__ci_expr_logic_11 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_10: c_int = 0

        if ((if __local_windowBits == 8: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if __local_wrap != 1: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_11 = (if __ci_expr_logic_10 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_11 != 0) {
        return -2

    }


    if ((if __local_windowBits == 8: 1 else: 0) != 0) {
        (__local_windowBits = ((9 as c_int)))
    }

    (__local_s = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (1 as c_uint), (5968 as c_uint)) as *mut internal_state)))

    if ((if __local_s == 0: 1 else: 0) != 0) {
        return -4
    }

    (*__local_s) = internal_state.zeroed()

    ((*__param_strm).state = __local_s)

    ((*__local_s).strm = __param_strm)

    ((*__local_s).status = ((42 as c_int)))

    ((*__local_s).wrap = __local_wrap)

    ((*__local_s).gzhead = null)

    ((*__local_s).w_bits = ((__local_windowBits as c_uint)))

    ((*__local_s).w_size = ((((1 as c_int) << ((*__local_s).w_bits as c_uint)) as c_uint)))

    ((*__local_s).w_mask = (((((*__local_s).w_size as c_uint) -% (1 as c_uint)) as c_uint)))

    ((*__local_s).hash_bits = ((((__param_memLevel as c_uint) +% (7 as c_uint)) as c_uint)))

    ((*__local_s).hash_size = ((((1 as c_int) << ((*__local_s).hash_bits as c_uint)) as c_uint)))

    ((*__local_s).hash_mask = (((((*__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_uint)))

    ((*__local_s).hash_shift = (((((((((*__local_s).hash_bits as c_uint) +% (3 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint) / (3 as c_uint)) as c_uint)))

    ((*__local_s).window = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).w_size, (2 as c_uint)) as *mut u8)))

    ((*__local_s).prev = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).w_size, (2 as c_uint)) as *mut c_ushort)))

    ((*__local_s).head = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).hash_size, (2 as c_uint)) as *mut c_ushort)))

    ((*__local_s).high_water = ((0 as c_ulong)))

    ((*__local_s).lit_bufsize = ((((1 as c_int) << ((__param_memLevel + 6) as c_uint)) as c_uint)))

    ((*__local_s).pending_buf = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).lit_bufsize, (4 as c_uint)) as *mut u8)))

    ((*__local_s).pending_buf_size = (((((*__local_s).lit_bufsize as c_ulong) *% (4 as c_ulong)) as c_ulong)))

    var __ci_expr_logic_14: c_int

    var __ci_expr_logic_13: c_int

    var __ci_expr_logic_12: c_int

    if ((if (*__local_s).window == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_12 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_12 = (if (if (*__local_s).prev == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_12 != 0) {
        (__ci_expr_logic_13 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_13 = (if (if (*__local_s).head == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_13 != 0) {
        (__ci_expr_logic_14 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_14 = (if (if (*__local_s).pending_buf == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_14 != 0) {
        ((*__local_s).status = ((666 as c_int)))

        var __ci_expr_ternary_16: c_int = 0

        var __ci_expr_logic_15: c_int

        if ((if -4 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_15 = (if (if -4 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_ternary_16 = ((9 as c_int)))
        } else {
            (__ci_expr_ternary_16 = (((2 - -4) as c_int)))
        }

        ((*__param_strm).msg = ((z_errmsg[__ci_expr_ternary_16] as *mut c_char)))


        deflateEnd(__param_strm)

        return -4

    }


    ((*__local_s).sym_buf = (*__local_s).pending_buf + ((*__local_s).lit_bufsize as usize))

    ((*__local_s).sym_end = (((((((*__local_s).lit_bufsize as c_uint) -% (1 as c_uint)) as c_uint) *% (3 as c_uint)) as c_uint)))

    ((*__local_s).level = __local_level)

    ((*__local_s).strategy = __param_strategy)

    ((*__local_s).method = ((__param_method as u8)))

    return deflateReset(__param_strm)

}

pub unsafe fn deflateResetKeep(__param_strm: *mut z_stream_s) -> c_int {
    var __local_s: *mut internal_state

    if (deflateStateCheck(__param_strm) != 0) {
        return -2

    }

    ((*__param_strm).total_out = ((0 as c_ulong)))

    ((*__param_strm).total_in = (*__param_strm).total_out)


    ((*__param_strm).msg = null)

    ((*__param_strm).data_type = ((2 as c_int)))

    (__local_s = (*__param_strm).state)

    ((*__local_s).pending = ((0 as c_ulong)))

    ((*__local_s).pending_out = (*__local_s).pending_buf)

    if ((if (*__local_s).wrap < 0: 1 else: 0) != 0) {
        ((*__local_s).wrap = (((0 - (*__local_s).wrap) as c_int)))

    }

    ((*__local_s).status = (((if (if (*__local_s).wrap == 2: 1 else: 0) != 0: (57 as c_int) else: (42 as c_int)) as c_int)))

    ((*__param_strm).adler = (((if (if (*__local_s).wrap == 2: 1 else: 0) != 0: (crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong) else: (adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)) as c_ulong)))

    ((*__local_s).last_flush = ((-2 as c_int)))

    _tr_init(__local_s)

    return 0

}

unsafe fn deflate_stored(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_min_block: c_uint = (((if (if (((*__param_s).pending_buf_size as c_ulong) -% (5 as c_ulong)) > (*__param_s).w_size: 1 else: 0) != 0: ((*__param_s).w_size as c_ulong) else: ((((*__param_s).pending_buf_size as c_ulong) -% (5 as c_ulong)) as c_ulong)) as c_uint))

    var __local_last: c_int = ((0 as c_int))

    var __local_len: c_uint

    var __local_left: c_uint

    var __local_have: c_uint


    var __local_used: c_uint = (*__param_s).strm.avail_in

    loop {
        (__local_len = ((65535 as c_uint)))

        (__local_have = (((((((*__param_s).bi_valid as c_uint) +% (42 as c_uint)) as c_uint) >> (3 as c_uint)) as c_uint)))

        if ((if (*__param_s).strm.avail_out < __local_have: 1 else: 0) != 0) {
            break
        }

        (__local_have = (((((*__param_s).strm.avail_out as c_uint) -% (__local_have as c_uint)) as c_uint)))

        (__local_left = ((((*__param_s).strstart - (*__param_s).block_start) as c_uint)))

        if ((if __local_len > ((__local_left as c_ulong) +% ((*__param_s).strm.avail_in as c_ulong)): 1 else: 0) != 0) {
            (__local_len = ((((__local_left as c_uint) +% ((*__param_s).strm.avail_in as c_uint)) as c_uint)))
        }

        if ((if __local_len > __local_have: 1 else: 0) != 0) {
            (__local_len = __local_have)
        }

        var __ci_expr_logic_3: c_int = 0

        if ((if __local_len < __local_min_block: 1 else: 0) != 0) {
            var __ci_expr_logic_2: c_int

            var __ci_expr_logic_1: c_int

            var __ci_expr_logic_0: c_int = 0

            if ((if __local_len == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if __local_len != ((__local_left as c_uint) +% ((*__param_s).strm.avail_in as c_uint)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_3 != 0) {
            break
        }


        var __ci_expr_ternary_5: c_int = 0

        var __ci_expr_logic_4: c_int = 0

        if ((if __param_flush == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_len == ((__local_left as c_uint) +% ((*__param_s).strm.avail_in as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_ternary_5 = ((1 as c_int)))
        } else {
            (__ci_expr_ternary_5 = ((0 as c_int)))
        }

        (__local_last = __ci_expr_ternary_5)


        _tr_stored_block(__param_s, null, (0 as c_ulong), __local_last)

        (((*__param_s).pending_buf[(((*__param_s).pending as c_ulong) -% (4 as c_ulong))]) = ((__local_len as u8)))

        (((*__param_s).pending_buf[(((*__param_s).pending as c_ulong) -% (3 as c_ulong))]) = ((((__local_len as c_uint) >> (8 as c_uint)) as u8)))

        (((*__param_s).pending_buf[(((*__param_s).pending as c_ulong) -% (2 as c_ulong))]) = (((~__local_len) as u8)))

        (((*__param_s).pending_buf[(((*__param_s).pending as c_ulong) -% (1 as c_ulong))]) = (((((~__local_len) as c_uint) >> (8 as c_uint)) as u8)))

        flush_pending((*__param_s).strm)

        if (__local_left != 0) {
            if ((if __local_left > __local_len: 1 else: 0) != 0) {
                (__local_left = __local_len)
            }

            with_memcpy((((*__param_s).strm.next_out as *mut c_void) as *mut u8), ((((*__param_s).window + (((*__param_s).block_start as isize) as usize)) as *const c_void) as *const u8), ((__local_left as c_ulong) as i64))

            ((*__param_s).strm.next_out = (*__param_s).strm.next_out + (__local_left as usize))

            ((*__param_s).strm.avail_out = ((*__param_s).strm.avail_out -% __local_left))

            ((*__param_s).strm.total_out = ((*__param_s).strm.total_out +% __local_left))

            ((*__param_s).block_start = (*__param_s).block_start + __local_left)

            (__local_len = (__local_len -% __local_left))

        }

        if (__local_len != 0) {
            read_buf((*__param_s).strm, (*__param_s).strm.next_out, __local_len)

            ((*__param_s).strm.next_out = (*__param_s).strm.next_out + (__local_len as usize))

            ((*__param_s).strm.avail_out = ((*__param_s).strm.avail_out -% __local_len))

            ((*__param_s).strm.total_out = ((*__param_s).strm.total_out +% __local_len))

        }

        if not (((if __local_last == 0: 1 else: 0) != 0)) {
            break
        }
    }

    (__local_used = (__local_used -% (*__param_s).strm.avail_in))

    if (__local_used != 0) {
        if ((if __local_used >= (*__param_s).w_size: 1 else: 0) != 0) {
            ((*__param_s).matches = ((2 as c_uint)))

            with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).strm.next_in - ((*__param_s).w_size as usize)) as *const c_void) as *const u8), (((*__param_s).w_size as c_ulong) as i64))

            ((*__param_s).strstart = (*__param_s).w_size)

            ((*__param_s).insert = (*__param_s).strstart)

        } else {
            if ((if (((*__param_s).window_size as c_ulong) -% ((*__param_s).strstart as c_ulong)) <= __local_used: 1 else: 0) != 0) {
                ((*__param_s).strstart = ((*__param_s).strstart -% (*__param_s).w_size))

                with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).window + ((*__param_s).w_size as usize)) as *const c_void) as *const u8), (((*__param_s).strstart as c_ulong) as i64))

                if ((if (*__param_s).matches < 2: 1 else: 0) != 0) {
                    ((*__param_s).matches = ((*__param_s).matches +% 1))
                }

                if ((if (*__param_s).insert > (*__param_s).strstart: 1 else: 0) != 0) {
                    ((*__param_s).insert = (*__param_s).strstart)
                }

            }

            with_memcpy(((((*__param_s).window + ((*__param_s).strstart as usize)) as *mut c_void) as *mut u8), ((((*__param_s).strm.next_in - (__local_used as usize)) as *const c_void) as *const u8), ((__local_used as c_ulong) as i64))

            ((*__param_s).strstart = ((*__param_s).strstart +% __local_used))

            ((*__param_s).insert = ((*__param_s).insert +% (if (if __local_used > (((*__param_s).w_size as c_uint) -% ((*__param_s).insert as c_uint)): 1 else: 0) != 0: ((((*__param_s).w_size as c_uint) -% ((*__param_s).insert as c_uint)) as c_uint) else: __local_used)))

        }

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

    }

    if ((if (*__param_s).high_water < (*__param_s).strstart: 1 else: 0) != 0) {
        ((*__param_s).high_water = (((*__param_s).strstart as c_ulong)))
    }

    if (__local_last != 0) {
        ((*__param_s).bi_used = ((8 as c_int)))

        return 3

    }

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    if ((if __param_flush != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_6 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_7 = (if (if (*__param_s).strm.avail_in == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        (__ci_expr_logic_8 = (if (if (((*__param_s).strstart as c_long)) == (*__param_s).block_start: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_8 != 0) {
        return 1
    }


    (__local_have = (((((*__param_s).window_size as c_ulong) -% ((*__param_s).strstart as c_ulong)) as c_uint)))

    var __ci_expr_logic_9: c_int = 0

    if ((if (*__param_s).strm.avail_in > __local_have: 1 else: 0) != 0) {
        (__ci_expr_logic_9 = (if (if (*__param_s).block_start >= (((*__param_s).w_size as c_long)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_9 != 0) {
        ((*__param_s).block_start = (*__param_s).block_start - (*__param_s).w_size)

        ((*__param_s).strstart = ((*__param_s).strstart -% (*__param_s).w_size))

        with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).window + ((*__param_s).w_size as usize)) as *const c_void) as *const u8), (((*__param_s).strstart as c_ulong) as i64))

        if ((if (*__param_s).matches < 2: 1 else: 0) != 0) {
            ((*__param_s).matches = ((*__param_s).matches +% 1))
        }

        (__local_have = (__local_have +% (*__param_s).w_size))

        if ((if (*__param_s).insert > (*__param_s).strstart: 1 else: 0) != 0) {
            ((*__param_s).insert = (*__param_s).strstart)
        }

    }


    if ((if __local_have > (*__param_s).strm.avail_in: 1 else: 0) != 0) {
        (__local_have = (*__param_s).strm.avail_in)
    }

    if (__local_have != 0) {
        read_buf((*__param_s).strm, ((*__param_s).window + ((*__param_s).strstart as usize)), __local_have)

        ((*__param_s).strstart = ((*__param_s).strstart +% __local_have))

        ((*__param_s).insert = ((*__param_s).insert +% (if (if __local_have > (((*__param_s).w_size as c_uint) -% ((*__param_s).insert as c_uint)): 1 else: 0) != 0: ((((*__param_s).w_size as c_uint) -% ((*__param_s).insert as c_uint)) as c_uint) else: __local_have)))

    }

    if ((if (*__param_s).high_water < (*__param_s).strstart: 1 else: 0) != 0) {
        ((*__param_s).high_water = (((*__param_s).strstart as c_ulong)))
    }

    (__local_have = (((((((*__param_s).bi_valid as c_uint) +% (42 as c_uint)) as c_uint) >> (3 as c_uint)) as c_uint)))

    (__local_have = (((if (if (((*__param_s).pending_buf_size as c_ulong) -% (__local_have as c_ulong)) > 65535: 1 else: 0) != 0: (65535 as c_ulong) else: ((((*__param_s).pending_buf_size as c_ulong) -% (__local_have as c_ulong)) as c_ulong)) as c_uint)))

    (__local_min_block = (((if (if __local_have > (*__param_s).w_size: 1 else: 0) != 0: (*__param_s).w_size else: __local_have) as c_uint)))

    (__local_left = ((((*__param_s).strstart - (*__param_s).block_start) as c_uint)))

    var __ci_expr_logic_14: c_int

    if ((if __local_left >= __local_min_block: 1 else: 0) != 0) {
        (__ci_expr_logic_14 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_13: c_int = 0

        var __ci_expr_logic_12: c_int = 0

        var __ci_expr_logic_11: c_int = 0

        var __ci_expr_logic_10: c_int

        if (__local_left != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if (if __param_flush == 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if __param_flush != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_11 != 0) {
            (__ci_expr_logic_12 = (if (if (*__param_s).strm.avail_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_logic_13 = (if (if __local_left <= __local_have: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_14 = (if __ci_expr_logic_13 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_14 != 0) {
        (__local_len = (((if (if __local_left > __local_have: 1 else: 0) != 0: __local_have else: __local_left) as c_uint)))

        var __ci_expr_ternary_17: c_int = 0

        var __ci_expr_logic_16: c_int = 0

        var __ci_expr_logic_15: c_int = 0

        if ((if __param_flush == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if (*__param_s).strm.avail_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_logic_16 = (if (if __local_len == __local_left: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_16 != 0) {
            (__ci_expr_ternary_17 = ((1 as c_int)))
        } else {
            (__ci_expr_ternary_17 = ((0 as c_int)))
        }

        (__local_last = __ci_expr_ternary_17)


        _tr_stored_block(__param_s, (((*__param_s).window as *mut c_char) + (((*__param_s).block_start as isize) as usize)), (__local_len as c_ulong), __local_last)

        ((*__param_s).block_start = (*__param_s).block_start + __local_len)

        flush_pending((*__param_s).strm)

    }


    if (__local_last != 0) {
        ((*__param_s).bi_used = ((8 as c_int)))
    }

    return (if __local_last != 0: finish_started else: need_more)

}

unsafe fn deflate_fast(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_hash_head: c_uint

    var __local_bflush: c_int

    while true {
        if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: c_int = 0

            if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                return 0

            }


            if ((if (*__param_s).lookahead == 0: 1 else: 0) != 0) {
                break
            }

        }

        (__local_hash_head = ((0 as c_uint)))

        if ((if (*__param_s).lookahead >= 3: 1 else: 0) != 0) {
            ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[(((*__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

            (((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) = ((((*__param_s).head[(*__param_s).ins_h]) as c_ushort)))

            (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) as c_uint)))

            (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as c_ushort)))


        }

        var __ci_expr_logic_1: c_int = 0

        if ((if __local_hash_head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (((*__param_s).strstart as c_uint) -% (__local_hash_head as c_uint)) <= (((*__param_s).w_size as c_uint) -% (262 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            ((*__param_s).match_length = ((longest_match(__param_s, __local_hash_head) as c_uint)))

        }


        if ((if (*__param_s).match_length >= 3: 1 else: 0) != 0) {

            var __local_len: u8 = (((((*__param_s).match_length as c_uint) -% (3 as c_uint)) as u8))

            var __local_dist: c_ushort = (((((*__param_s).strstart as c_uint) -% ((*__param_s).match_start as c_uint)) as c_ushort))

            var __ci_expr_old_2: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_2]) = ((__local_dist as u8)))


            var __ci_expr_old_3: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_3]) = ((((__local_dist as c_int) >> (8 as c_uint)) as u8)))


            var __ci_expr_old_4: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_4]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((*__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq = ((*__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq +% 1))

            ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as c_int) else: (_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int))].fc.freq = ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as c_int) else: (_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int))].fc.freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% (*__param_s).match_length))

            var __ci_expr_logic_5: c_int = 0

            if ((if (*__param_s).match_length <= (*__param_s).max_lazy_match: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if (if (*__param_s).lookahead >= 3: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                ((*__param_s).match_length = ((*__param_s).match_length -% 1))

                loop {
                    ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                    ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[(((*__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

                    (((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) = ((((*__param_s).head[(*__param_s).ins_h]) as c_ushort)))

                    (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) as c_uint)))

                    (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as c_ushort)))


                    ((*__param_s).match_length = ((*__param_s).match_length -% 1))
                    if not (((if (*__param_s).match_length != 0: 1 else: 0) != 0)) {
                        break
                    }
                }

                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

            } else {
                ((*__param_s).strstart = ((*__param_s).strstart +% (*__param_s).match_length))

                ((*__param_s).match_length = ((0 as c_uint)))

                ((*__param_s).ins_h = ((((*__param_s).window[(*__param_s).strstart]) as c_uint)))

                ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[(((*__param_s).strstart as c_uint) +% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

            }


        } else {

            var __local_cc: u8 = ((((*__param_s).window[(*__param_s).strstart]) as u8))

            var __ci_expr_old_6: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_6]) = ((0 as u8)))


            var __ci_expr_old_7: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_7]) = ((0 as u8)))


            var __ci_expr_old_8: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_8]) = __local_cc)


            ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

            ((*__param_s).strstart = ((*__param_s).strstart +% 1))

        }

        if (__local_bflush != 0) {
            _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

            ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

            flush_pending((*__param_s).strm)




            if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }


    }

    ((*__param_s).insert = (((if (if (*__param_s).strstart < 2: 1 else: 0) != 0: (*__param_s).strstart else: (2 as c_uint)) as c_uint)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (1 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn deflate_slow(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_hash_head: c_uint

    var __local_bflush: c_int

    while true {
        if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: c_int = 0

            if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                return 0

            }


            if ((if (*__param_s).lookahead == 0: 1 else: 0) != 0) {
                break
            }

        }

        (__local_hash_head = ((0 as c_uint)))

        if ((if (*__param_s).lookahead >= 3: 1 else: 0) != 0) {
            ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[(((*__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

            (((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) = ((((*__param_s).head[(*__param_s).ins_h]) as c_ushort)))

            (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) as c_uint)))

            (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as c_ushort)))


        }

        ((*__param_s).prev_length = (*__param_s).match_length)

        ((*__param_s).prev_match = (*__param_s).match_start)


        ((*__param_s).match_length = ((2 as c_uint)))

        var __ci_expr_logic_2: c_int = 0

        var __ci_expr_logic_1: c_int = 0

        if ((if __local_hash_head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__param_s).prev_length < (*__param_s).max_lazy_match: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if (if (((*__param_s).strstart as c_uint) -% (__local_hash_head as c_uint)) <= (((*__param_s).w_size as c_uint) -% (262 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            ((*__param_s).match_length = ((longest_match(__param_s, __local_hash_head) as c_uint)))

            var __ci_expr_logic_5: c_int = 0

            if ((if (*__param_s).match_length <= 5: 1 else: 0) != 0) {
                var __ci_expr_logic_4: c_int

                if ((if (*__param_s).strategy == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if (*__param_s).match_length == 3: 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if (if (((*__param_s).strstart as c_uint) -% ((*__param_s).match_start as c_uint)) > 4096: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

                }

                (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_5 != 0) {
                ((*__param_s).match_length = ((2 as c_uint)))

            }


        }


        var __ci_expr_logic_6: c_int = 0

        if ((if (*__param_s).prev_length >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (*__param_s).match_length <= (*__param_s).prev_length: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            var __local_max_insert: c_uint = (((((((*__param_s).strstart as c_uint) +% ((*__param_s).lookahead as c_uint)) as c_uint) -% (3 as c_uint)) as c_uint))


            var __local_len: u8 = (((((*__param_s).prev_length as c_uint) -% (3 as c_uint)) as u8))

            var __local_dist: c_ushort = (((((((*__param_s).strstart as c_uint) -% (1 as c_uint)) as c_uint) -% ((*__param_s).prev_match as c_uint)) as c_ushort))

            var __ci_expr_old_7: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_7]) = ((__local_dist as u8)))


            var __ci_expr_old_8: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_8]) = ((((__local_dist as c_int) >> (8 as c_uint)) as u8)))


            var __ci_expr_old_9: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_9]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((*__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq = ((*__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq +% 1))

            ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as c_int) else: (_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int))].fc.freq = ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as c_int) else: (_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int))].fc.freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% (((*__param_s).prev_length as c_uint) -% (1 as c_uint))))

            ((*__param_s).prev_length = ((*__param_s).prev_length -% 2))

            loop {
                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                if ((if (*__param_s).strstart <= __local_max_insert: 1 else: 0) != 0) {
                    ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[(((*__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

                    (((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) = ((((*__param_s).head[(*__param_s).ins_h]) as c_ushort)))

                    (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as c_uint) & ((*__param_s).w_mask as c_uint))]) as c_uint)))

                    (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as c_ushort)))


                }


                ((*__param_s).prev_length = ((*__param_s).prev_length -% 1))
                if not (((if (*__param_s).prev_length != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            ((*__param_s).match_available = ((0 as c_int)))

            ((*__param_s).match_length = ((2 as c_uint)))

            ((*__param_s).strstart = ((*__param_s).strstart +% 1))

            if (__local_bflush != 0) {
                _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

                ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

                flush_pending((*__param_s).strm)




                if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                    return 0
                }

            }


        } else {
            if ((*__param_s).match_available != 0) {

                var __local_cc: u8 = ((((*__param_s).window[(((*__param_s).strstart as c_uint) -% (1 as c_uint))]) as u8))

                var __ci_expr_old_10: c_uint = (*__param_s).sym_next

                ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

                (((*__param_s).sym_buf[__ci_expr_old_10]) = ((0 as u8)))


                var __ci_expr_old_11: c_uint = (*__param_s).sym_next

                ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

                (((*__param_s).sym_buf[__ci_expr_old_11]) = ((0 as u8)))


                var __ci_expr_old_12: c_uint = (*__param_s).sym_next

                ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

                (((*__param_s).sym_buf[__ci_expr_old_12]) = __local_cc)


                ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

                (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



                if (__local_bflush != 0) {
                    _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

                    ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

                    flush_pending((*__param_s).strm)




                }

                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

                if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                    return 0
                }

            } else {
                ((*__param_s).match_available = ((1 as c_int)))

                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

            }
        }


    }


    if ((*__param_s).match_available != 0) {

        var __local_cc_1: u8 = ((((*__param_s).window[(((*__param_s).strstart as c_uint) -% (1 as c_uint))]) as u8))

        var __ci_expr_old_13: c_uint = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_13]) = ((0 as u8)))


        var __ci_expr_old_14: c_uint = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_14]) = ((0 as u8)))


        var __ci_expr_old_15: c_uint = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_15]) = __local_cc_1)


        ((*__param_s).dyn_ltree[__local_cc_1].fc.freq = ((*__param_s).dyn_ltree[__local_cc_1].fc.freq +% 1))

        (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



        ((*__param_s).match_available = ((0 as c_int)))

    }

    ((*__param_s).insert = (((if (if (*__param_s).strstart < 2: 1 else: 0) != 0: (*__param_s).strstart else: (2 as c_uint)) as c_uint)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (1 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn deflate_rle(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_bflush: c_int

    var __local_prev: c_uint

    var __local_scan: *mut u8

    var __local_strend: *mut u8


    while true {
        if ((if (*__param_s).lookahead <= 258: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: c_int = 0

            if ((if (*__param_s).lookahead <= 258: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                return 0

            }


            if ((if (*__param_s).lookahead == 0: 1 else: 0) != 0) {
                break
            }

        }

        ((*__param_s).match_length = ((0 as c_uint)))

        var __ci_expr_logic_1: c_int = 0

        if ((if (*__param_s).lookahead >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__param_s).strstart > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_scan = ((*__param_s).window + ((*__param_s).strstart as usize)) - ((1 as isize) as usize))

            (__local_prev = (((*__local_scan) as c_uint)))

            var __ci_expr_logic_3: c_int = 0

            var __ci_expr_logic_2: c_int = 0

            (__local_scan = __local_scan + 1)

            if ((if __local_prev == (*__local_scan): 1 else: 0) != 0) {
                (__local_scan = __local_scan + 1)

                (__ci_expr_logic_2 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_2 != 0) {
                (__local_scan = __local_scan + 1)

                (__ci_expr_logic_3 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_3 != 0) {
                (__local_strend = ((*__param_s).window + ((*__param_s).strstart as usize)) + ((258 as isize) as usize))

                loop {
                    0
                    var __ci_expr_logic_11: c_int = 0

                    var __ci_expr_logic_10: c_int = 0

                    var __ci_expr_logic_9: c_int = 0

                    var __ci_expr_logic_8: c_int = 0

                    var __ci_expr_logic_7: c_int = 0

                    var __ci_expr_logic_6: c_int = 0

                    var __ci_expr_logic_5: c_int = 0

                    var __ci_expr_logic_4: c_int = 0

                    (__local_scan = __local_scan + 1)

                    if ((if __local_prev == (*__local_scan): 1 else: 0) != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_4 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_5 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_5 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_6 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_6 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_7 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_7 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_8 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_8 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_9 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_9 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_10 = (if (if __local_prev == (*__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_10 != 0) {
                        (__ci_expr_logic_11 = (if (if __local_scan < __local_strend: 1 else: 0) != 0: 1 else: 0))
                    }

                    if not ((__ci_expr_logic_11 != 0)) {
                        break
                    }
                }

                ((*__param_s).match_length = ((((258 as c_uint) -% (((((__local_strend as usize) -% (__local_scan as usize)) as c_long) / (sizeof[u8]() as c_long)) as c_uint)) as c_uint)))

                if ((if (*__param_s).match_length > (*__param_s).lookahead: 1 else: 0) != 0) {
                    ((*__param_s).match_length = (*__param_s).lookahead)
                }

            }



        }


        if ((if (*__param_s).match_length >= 3: 1 else: 0) != 0) {

            var __local_len: u8 = (((((*__param_s).match_length as c_uint) -% (3 as c_uint)) as u8))

            var __local_dist: c_ushort = ((1 as c_ushort))

            var __ci_expr_old_12: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_12]) = ((__local_dist as u8)))


            var __ci_expr_old_13: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_13]) = ((((__local_dist as c_int) >> (8 as c_uint)) as u8)))


            var __ci_expr_old_14: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_14]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((*__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq = ((*__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq +% 1))

            ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as c_int) else: (_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int))].fc.freq = ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as c_int) else: (_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int))].fc.freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% (*__param_s).match_length))

            ((*__param_s).strstart = ((*__param_s).strstart +% (*__param_s).match_length))

            ((*__param_s).match_length = ((0 as c_uint)))

        } else {

            var __local_cc: u8 = ((((*__param_s).window[(*__param_s).strstart]) as u8))

            var __ci_expr_old_15: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_15]) = ((0 as u8)))


            var __ci_expr_old_16: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_16]) = ((0 as u8)))


            var __ci_expr_old_17: c_uint = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_17]) = __local_cc)


            ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

            ((*__param_s).strstart = ((*__param_s).strstart +% 1))

        }

        if (__local_bflush != 0) {
            _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

            ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

            flush_pending((*__param_s).strm)




            if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }


    }

    ((*__param_s).insert = ((0 as c_uint)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (1 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn deflate_huff(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_bflush: c_int

    while true {
        if ((if (*__param_s).lookahead == 0: 1 else: 0) != 0) {
            fill_window(__param_s)

            if ((if (*__param_s).lookahead == 0: 1 else: 0) != 0) {
                if ((if __param_flush == 0: 1 else: 0) != 0) {
                    return 0
                }

                break

            }

        }

        ((*__param_s).match_length = ((0 as c_uint)))


        var __local_cc: u8 = ((((*__param_s).window[(*__param_s).strstart]) as u8))

        var __ci_expr_old_0: c_uint = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_0]) = ((0 as u8)))


        var __ci_expr_old_1: c_uint = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_1]) = ((0 as u8)))


        var __ci_expr_old_2: c_uint = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_2]) = __local_cc)


        ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

        (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as c_int)))



        ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

        ((*__param_s).strstart = ((*__param_s).strstart +% 1))

        if (__local_bflush != 0) {
            _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

            ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

            flush_pending((*__param_s).strm)




            if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }


    }

    ((*__param_s).insert = ((0 as c_uint)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (1 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as c_long) - (*__param_s).block_start) as c_ulong), (0 as c_int))

        ((*__param_s).block_start = (((*__param_s).strstart as c_long)))

        flush_pending((*__param_s).strm)




        if ((if (*__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn slide_hash(__param_s: *mut internal_state) {
    var __local_n: c_uint

    var __local_m: c_uint


    var __local_p: *mut c_ushort

    var __local_wsize: c_uint = (*__param_s).w_size

    (__local_n = (*__param_s).hash_size)

    (__local_p = (((&raw const ((*__param_s).head[__local_n]) as *const c_ushort) as *mut c_ushort)))

    loop {
        (__local_p = __local_p - 1)

        (__local_m = (((*__local_p) as c_uint)))


        ((*__local_p) = (((if (if __local_m >= __local_wsize: 1 else: 0) != 0: (((__local_m as c_uint) -% (__local_wsize as c_uint)) as c_uint) else: (0 as c_uint)) as c_ushort)))

        (__local_n = (__local_n -% 1))
        if not ((__local_n != 0)) {
            break
        }
    }

    (__local_n = __local_wsize)

    (__local_p = (((&raw const ((*__param_s).prev[__local_n]) as *const c_ushort) as *mut c_ushort)))

    loop {
        (__local_p = __local_p - 1)

        (__local_m = (((*__local_p) as c_uint)))


        ((*__local_p) = (((if (if __local_m >= __local_wsize: 1 else: 0) != 0: (((__local_m as c_uint) -% (__local_wsize as c_uint)) as c_uint) else: (0 as c_uint)) as c_ushort)))

        (__local_n = (__local_n -% 1))
        if not ((__local_n != 0)) {
            break
        }
    }

    ((*__param_s).slid = ((1 as c_int)))

}

unsafe fn read_buf(__param_strm: *mut z_stream_s, __param_buf: *mut u8, __param_size: c_uint) -> c_uint {
    var __local_len: c_uint = (*__param_strm).avail_in

    if ((if __local_len > __param_size: 1 else: 0) != 0) {
        (__local_len = __param_size)
    }

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return 0
    }

    ((*__param_strm).avail_in = ((*__param_strm).avail_in -% __local_len))

    with_memcpy(((__param_buf as *mut c_void) as *mut u8), (((*__param_strm).next_in as *const c_void) as *const u8), ((__local_len as c_ulong) as i64))

    if ((if (*(*__param_strm).state).wrap == 1: 1 else: 0) != 0) {
        ((*__param_strm).adler = ((adler32((*__param_strm).adler, (__param_buf as *const u8), __local_len) as c_ulong)))

    } else {
        if ((if (*(*__param_strm).state).wrap == 2: 1 else: 0) != 0) {
            ((*__param_strm).adler = ((crc32((*__param_strm).adler, (__param_buf as *const u8), __local_len) as c_ulong)))

        }
    }

    ((*__param_strm).next_in = (*__param_strm).next_in + (__local_len as usize))

    ((*__param_strm).total_in = ((*__param_strm).total_in +% __local_len))

    return __local_len

}

unsafe fn fill_window(__param_s: *mut internal_state) {
    var __local_n: c_uint

    var __local_more: c_uint

    var __local_wsize: c_uint = (*__param_s).w_size


    loop {
        (__local_more = (((((((*__param_s).window_size as c_ulong) -% ((*__param_s).lookahead as c_ulong)) as c_ulong) -% ((*__param_s).strstart as c_ulong)) as c_uint)))

        if ((if (sizeof[c_int]() as usize) <= 2: 1 else: 0) != 0) {
            var __ci_expr_logic_2: c_int = 0

            var __ci_expr_logic_1: c_int = 0

            if ((if __local_more == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if (*__param_s).strstart == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_2 = (if (if (*__param_s).lookahead == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__local_more = __local_wsize)

            } else {
                if ((if __local_more == ((-1 as c_uint)): 1 else: 0) != 0) {
                    (__local_more = (__local_more -% 1))

                }
            }


        }

        if ((if (*__param_s).strstart >= ((__local_wsize as c_uint) +% ((((*__param_s).w_size as c_uint) -% (262 as c_uint)) as c_uint)): 1 else: 0) != 0) {
            with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).window + (__local_wsize as usize)) as *const c_void) as *const u8), ((((__local_wsize as c_uint) -% (__local_more as c_uint)) as c_ulong) as i64))

            ((*__param_s).match_start = ((*__param_s).match_start -% __local_wsize))

            ((*__param_s).strstart = ((*__param_s).strstart -% __local_wsize))

            ((*__param_s).block_start = (*__param_s).block_start - (__local_wsize as c_long))

            if ((if (*__param_s).insert > (*__param_s).strstart: 1 else: 0) != 0) {
                ((*__param_s).insert = (*__param_s).strstart)
            }

            slide_hash(__param_s)

            (__local_more = (__local_more +% __local_wsize))

        }

        if ((if (*__param_s).strm.avail_in == 0: 1 else: 0) != 0) {
            break
        }


        (__local_n = ((read_buf((*__param_s).strm, (((*__param_s).window + ((*__param_s).strstart as usize)) + ((*__param_s).lookahead as usize)), __local_more) as c_uint)))

        ((*__param_s).lookahead = ((*__param_s).lookahead +% __local_n))

        if ((if (((*__param_s).lookahead as c_uint) +% ((*__param_s).insert as c_uint)) >= 3: 1 else: 0) != 0) {
            var __local_str: c_uint = (((((*__param_s).strstart as c_uint) -% ((*__param_s).insert as c_uint)) as c_uint))

            ((*__param_s).ins_h = ((((*__param_s).window[__local_str]) as c_uint)))

            ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[((__local_str as c_uint) +% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

            while ((*__param_s).insert != 0) {
                ((*__param_s).ins_h = (((((((((*__param_s).ins_h as c_uint) << ((*__param_s).hash_shift as c_uint)) as c_uint) ^ ((((*__param_s).window[((((__local_str as c_uint) +% (3 as c_uint)) as c_uint) -% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((*__param_s).hash_mask as c_uint)) as c_uint)))

                (((*__param_s).prev[((__local_str as c_uint) & ((*__param_s).w_mask as c_uint))]) = ((((*__param_s).head[(*__param_s).ins_h]) as c_ushort)))

                (((*__param_s).head[(*__param_s).ins_h]) = ((__local_str as c_ushort)))

                (__local_str = (__local_str +% 1))

                ((*__param_s).insert = ((*__param_s).insert -% 1))

                if ((if (((*__param_s).lookahead as c_uint) +% ((*__param_s).insert as c_uint)) < 3: 1 else: 0) != 0) {
                    break
                }

            }

        }

        var __ci_expr_logic_0: c_int = 0

        if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (*__param_s).strm.avail_in != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    if ((if (*__param_s).high_water < (*__param_s).window_size: 1 else: 0) != 0) {
        var __local_curr: c_ulong = (((((*__param_s).strstart as c_ulong) +% ((*__param_s).lookahead as c_ulong)) as c_ulong))

        var __local_init: c_ulong

        if ((if (*__param_s).high_water < __local_curr: 1 else: 0) != 0) {
            (__local_init = (((((*__param_s).window_size as c_ulong) -% (__local_curr as c_ulong)) as c_ulong)))

            if ((if __local_init > 258: 1 else: 0) != 0) {
                (__local_init = ((258 as c_ulong)))
            }

            with_memset(((((*__param_s).window + (__local_curr as usize)) as *mut c_void) as *mut u8), (0 as c_int), (((__local_init as c_uint) as c_ulong) as i64))

            ((*__param_s).high_water = ((((__local_curr as c_ulong) +% (__local_init as c_ulong)) as c_ulong)))

        } else {
            if ((if (*__param_s).high_water < ((__local_curr as c_ulong) +% (258 as c_ulong)): 1 else: 0) != 0) {
                (__local_init = ((((((__local_curr as c_ulong) +% (258 as c_ulong)) as c_ulong) -% ((*__param_s).high_water as c_ulong)) as c_ulong)))

                if ((if __local_init > (((*__param_s).window_size as c_ulong) -% ((*__param_s).high_water as c_ulong)): 1 else: 0) != 0) {
                    (__local_init = (((((*__param_s).window_size as c_ulong) -% ((*__param_s).high_water as c_ulong)) as c_ulong)))
                }

                with_memset(((((*__param_s).window + ((*__param_s).high_water as usize)) as *mut c_void) as *mut u8), (0 as c_int), (((__local_init as c_uint) as c_ulong) as i64))

                ((*__param_s).high_water = ((*__param_s).high_water +% __local_init))

            }
        }

    }


}

unsafe fn deflateStateCheck(__param_strm: *mut z_stream_s) -> c_int {
    var __local_s: *mut internal_state

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __param_strm == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_strm).zalloc == ((0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__param_strm).zfree == ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return 1
    }


    (__local_s = (*__param_strm).state)

    var __ci_expr_logic_10: c_int

    var __ci_expr_logic_2: c_int

    if ((if __local_s == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (*__local_s).strm != __param_strm: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_10 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_9: c_int = 0

        var __ci_expr_logic_8: c_int = 0

        var __ci_expr_logic_7: c_int = 0

        var __ci_expr_logic_6: c_int = 0

        var __ci_expr_logic_5: c_int = 0

        var __ci_expr_logic_4: c_int = 0

        var __ci_expr_logic_3: c_int = 0

        if ((if (*__local_s).status != 42: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if (*__local_s).status != 57: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if (if (*__local_s).status != 69: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if (*__local_s).status != 73: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if (*__local_s).status != 91: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_logic_7 = (if (if (*__local_s).status != 103: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_logic_8 = (if (if (*__local_s).status != 113: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_logic_9 = (if (if (*__local_s).status != 666: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_10 != 0) {
        return 1
    }


    return 0

}

unsafe fn lm_init(__param_s: *mut internal_state) {
    ((*__param_s).window_size = ((((2 as c_ulong) *% ((*__param_s).w_size as c_ulong)) as c_ulong)))

    loop {
        (((*__param_s).head[(((*__param_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

        with_memset((((*__param_s).head as *mut c_void) as *mut u8), (0 as c_int), (((((((*__param_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

        ((*__param_s).slid = ((0 as c_int)))

        if not ((0 != 0)) {
            break
        }
    }

    ((*__param_s).max_lazy_match = ((configuration_table[(*__param_s).level].max_lazy as c_uint)))

    ((*__param_s).good_match = ((configuration_table[(*__param_s).level].good_length as c_uint)))

    ((*__param_s).nice_match = ((configuration_table[(*__param_s).level].nice_length as c_int)))

    ((*__param_s).max_chain_length = ((configuration_table[(*__param_s).level].max_chain as c_uint)))

    ((*__param_s).strstart = ((0 as c_uint)))

    ((*__param_s).block_start = ((0 as c_long)))

    ((*__param_s).lookahead = ((0 as c_uint)))

    ((*__param_s).insert = ((0 as c_uint)))

    ((*__param_s).prev_length = ((2 as c_uint)))

    ((*__param_s).match_length = (*__param_s).prev_length)


    ((*__param_s).match_available = ((0 as c_int)))

    ((*__param_s).ins_h = ((0 as c_uint)))

}

unsafe fn putShortMSB(__param_s: *mut internal_state, __param_b: c_uint) {
    var __ci_expr_old_0: c_ulong = (*__param_s).pending

    ((*__param_s).pending = ((*__param_s).pending +% 1))

    (((*__param_s).pending_buf[__ci_expr_old_0]) = ((((__param_b as c_uint) >> (8 as c_uint)) as u8)))




    var __ci_expr_old_1: c_ulong = (*__param_s).pending

    ((*__param_s).pending = ((*__param_s).pending +% 1))

    (((*__param_s).pending_buf[__ci_expr_old_1]) = ((((__param_b as c_uint) & (255 as c_uint)) as u8)))




}

unsafe fn flush_pending(__param_strm: *mut z_stream_s) {
    var __local_len: c_uint

    var __local_s: *mut internal_state = (*__param_strm).state

    _tr_flush_bits(__local_s)

    (__local_len = (((if (if (*__local_s).pending > (*__param_strm).avail_out: 1 else: 0) != 0: (*__param_strm).avail_out else: ((*__local_s).pending as c_uint)) as c_uint)))

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return
    }

    with_memcpy((((*__param_strm).next_out as *mut c_void) as *mut u8), (((*__local_s).pending_out as *const c_void) as *const u8), ((__local_len as c_ulong) as i64))

    ((*__param_strm).next_out = (*__param_strm).next_out + (__local_len as usize))

    ((*__local_s).pending_out = (*__local_s).pending_out + (__local_len as usize))

    ((*__param_strm).total_out = ((*__param_strm).total_out +% __local_len))

    ((*__param_strm).avail_out = ((*__param_strm).avail_out -% __local_len))

    ((*__local_s).pending = ((*__local_s).pending -% __local_len))

    if ((if (*__local_s).pending == 0: 1 else: 0) != 0) {
        ((*__local_s).pending_out = (*__local_s).pending_buf)

    }

}

unsafe fn longest_match(__param_s: *mut internal_state, __param_cur_match: c_uint) -> c_uint {
    var __local_cur_match = __param_cur_match
    var __local_chain_length: c_uint = (*__param_s).max_chain_length

    var __local_scan: *mut u8 = ((*__param_s).window + ((*__param_s).strstart as usize))

    var __local_match_: *mut u8

    var __local_len: c_int

    var __local_best_len: c_int = (((*__param_s).prev_length as c_int))

    var __local_nice_match: c_int = (*__param_s).nice_match

    var __local_limit: c_uint = (((if (if (*__param_s).strstart > (((*__param_s).w_size as c_uint) -% (262 as c_uint)): 1 else: 0) != 0: ((((*__param_s).strstart as c_uint) -% ((((*__param_s).w_size as c_uint) -% (262 as c_uint)) as c_uint)) as c_uint) else: (0 as c_uint)) as c_uint))

    var __local_prev: *mut c_ushort = (*__param_s).prev

    var __local_wmask: c_uint = (*__param_s).w_mask

    var __local_strend: *mut u8 = (((*__param_s).window + ((*__param_s).strstart as usize)) + ((258 as isize) as usize))

    var __local_scan_end1: u8 = (((__local_scan[(__local_best_len - 1)]) as u8))

    var __local_scan_end: u8 = (((__local_scan[__local_best_len]) as u8))


    if ((if (*__param_s).prev_length >= (*__param_s).good_match: 1 else: 0) != 0) {
        (__local_chain_length = __local_chain_length >> (2 as c_uint))

    }

    if ((if ((__local_nice_match as c_uint)) > (*__param_s).lookahead: 1 else: 0) != 0) {
        (__local_nice_match = (((*__param_s).lookahead as c_int)))
    }


    loop {

        (__local_match_ = (*__param_s).window + (__local_cur_match as usize))

        var __ci_expr_logic_3: c_int

        var __ci_expr_logic_2: c_int

        var __ci_expr_logic_1: c_int

        if ((if (__local_match_[__local_best_len]) != __local_scan_end: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if (__local_match_[(__local_best_len - 1)]) != __local_scan_end1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (*__local_match_) != (*__local_scan): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__local_match_ = __local_match_ + 1)

            (__ci_expr_logic_3 = (if (if (*__local_match_) != (__local_scan[1]): 1 else: 0) != 0: 1 else: 0))

        }

        if (__ci_expr_logic_3 != 0) {
            var __ci_expr_logic_0: c_int = 0

            (__local_cur_match = (((__local_prev[((__local_cur_match as c_uint) & (__local_wmask as c_uint))]) as c_uint)))

            if ((if __local_cur_match > __local_limit: 1 else: 0) != 0) {
                (__local_chain_length = (__local_chain_length -% 1))

                (__ci_expr_logic_0 = (if (if __local_chain_length != 0: 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_0 != 0) {
                continue
            }
            break

        }


        (__local_scan = __local_scan + ((2 as isize) as usize))

        (__local_match_ = __local_match_ + 1)



        loop {
            0
            var __ci_expr_logic_11: c_int = 0

            var __ci_expr_logic_10: c_int = 0

            var __ci_expr_logic_9: c_int = 0

            var __ci_expr_logic_8: c_int = 0

            var __ci_expr_logic_7: c_int = 0

            var __ci_expr_logic_6: c_int = 0

            var __ci_expr_logic_5: c_int = 0

            var __ci_expr_logic_4: c_int = 0

            (__local_scan = __local_scan + 1)

            (__local_match_ = __local_match_ + 1)

            if ((if (*__local_scan) == (*__local_match_): 1 else: 0) != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_4 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_4 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_5 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_5 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_6 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_6 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_7 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_7 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_8 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_8 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_9 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_9 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_10 = (if (if (*__local_scan) == (*__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_10 != 0) {
                (__ci_expr_logic_11 = (if (if __local_scan < __local_strend: 1 else: 0) != 0: 1 else: 0))
            }

            if not ((__ci_expr_logic_11 != 0)) {
                break
            }
        }


        (__local_len = (((258 - (((((__local_strend as usize) -% (__local_scan as usize)) as c_long) / (sizeof[u8]() as c_long)) as c_int)) as c_int)))

        (__local_scan = __local_strend - ((258 as isize) as usize))

        if ((if __local_len > __local_best_len: 1 else: 0) != 0) {
            ((*__param_s).match_start = __local_cur_match)

            (__local_best_len = __local_len)

            if ((if __local_len >= __local_nice_match: 1 else: 0) != 0) {
                break
            }

            (__local_scan_end1 = (((__local_scan[(__local_best_len - 1)]) as u8)))

            (__local_scan_end = (((__local_scan[__local_best_len]) as u8)))

        }

        var __ci_expr_logic_0: c_int = 0

        (__local_cur_match = (((__local_prev[((__local_cur_match as c_uint) & (__local_wmask as c_uint))]) as c_uint)))

        if ((if __local_cur_match > __local_limit: 1 else: 0) != 0) {
            (__local_chain_length = (__local_chain_length -% 1))

            (__ci_expr_logic_0 = (if (if __local_chain_length != 0: 1 else: 0) != 0: 1 else: 0))

        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    if ((if ((__local_best_len as c_uint)) <= (*__param_s).lookahead: 1 else: 0) != 0) {
        return ((__local_best_len as c_uint))
    }

    return (*__param_s).lookahead

}

let configuration_table: [10]config_s = [config_s { good_length: 0, max_lazy: 0, nice_length: 0, max_chain: 0, func: Some(deflate_stored) }, config_s { good_length: 4, max_lazy: 4, nice_length: 8, max_chain: 4, func: Some(deflate_fast) }, config_s { good_length: 4, max_lazy: 5, nice_length: 16, max_chain: 8, func: Some(deflate_fast) }, config_s { good_length: 4, max_lazy: 6, nice_length: 32, max_chain: 32, func: Some(deflate_fast) }, config_s { good_length: 4, max_lazy: 4, nice_length: 16, max_chain: 16, func: Some(deflate_slow) }, config_s { good_length: 8, max_lazy: 16, nice_length: 32, max_chain: 32, func: Some(deflate_slow) }, config_s { good_length: 8, max_lazy: 16, nice_length: 128, max_chain: 128, func: Some(deflate_slow) }, config_s { good_length: 8, max_lazy: 32, nice_length: 128, max_chain: 256, func: Some(deflate_slow) }, config_s { good_length: 32, max_lazy: 128, nice_length: 258, max_chain: 1024, func: Some(deflate_slow) }, config_s { good_length: 32, max_lazy: 258, nice_length: 258, max_chain: 4096, func: Some(deflate_slow) }]
