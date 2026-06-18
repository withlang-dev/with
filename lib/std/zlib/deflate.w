// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32
use std.zlib.inftrees
use std.zlib.trees

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


    (__local_s = (unsafe *__param_strm).state)

    var __ci_expr_logic_5: c_int

    var __ci_expr_logic_3: c_int

    if ((if (unsafe *__param_strm).next_out == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_2: c_int = 0

        if ((if (unsafe *__param_strm).avail_in != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (unsafe *__param_strm).next_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_5 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_4: c_int = 0

        if ((if (unsafe *__local_s).status == 666: 1 else: 0) != 0) {
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

        ((unsafe *__param_strm).msg = ((z_errmsg[__ci_expr_ternary_7] as *mut c_char)))

        return -2


    }


    if ((if (unsafe *__param_strm).avail_out == 0: 1 else: 0) != 0) {
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

        ((unsafe *__param_strm).msg = ((z_errmsg[__ci_expr_ternary_9] as *mut c_char)))

        return -5

    }

    (__local_old_flush = (unsafe *__local_s).last_flush)

    ((unsafe *__local_s).last_flush = __param_flush)

    if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
        flush_pending(__param_strm)

        if ((if (unsafe *__param_strm).avail_out == 0: 1 else: 0) != 0) {
            ((unsafe *__local_s).last_flush = ((-1 as c_int)))

            return 0

        }

    } else {
        var __ci_expr_logic_13: c_int = 0

        var __ci_expr_logic_12: c_int = 0

        if ((if (unsafe *__param_strm).avail_in == 0: 1 else: 0) != 0) {
            var __ci_expr_ternary_10: c_int = 0

            if ((if __param_flush > 4: 1 else: 0) != 0) {
                (__ci_expr_ternary_10 = ((9 as c_int)))
            } else {
                (__ci_expr_ternary_10 = ((0 as c_int)))
            }

            var __ci_expr_ternary_11: c_int = 0

            if ((if __local_old_flush > 4: 1 else: 0) != 0) {
                (__ci_expr_ternary_11 = ((9 as c_int)))
            } else {
                (__ci_expr_ternary_11 = ((0 as c_int)))
            }

            (__ci_expr_logic_12 = (if (if ((__param_flush * 2) - __ci_expr_ternary_10) <= ((__local_old_flush * 2) - __ci_expr_ternary_11): 1 else: 0) != 0: 1 else: 0))

        }

        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_logic_13 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_13 != 0) {
            var __ci_expr_ternary_15: c_int = 0

            var __ci_expr_logic_14: c_int

            if ((if -5 < -6: 1 else: 0) != 0) {
                (__ci_expr_logic_14 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_14 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_14 != 0) {
                (__ci_expr_ternary_15 = ((9 as c_int)))
            } else {
                (__ci_expr_ternary_15 = (((2 - -5) as c_int)))
            }

            ((unsafe *__param_strm).msg = ((z_errmsg[__ci_expr_ternary_15] as *mut c_char)))

            return -5


        }

    }

    var __ci_expr_logic_16: c_int = 0

    if ((if (unsafe *__local_s).status == 666: 1 else: 0) != 0) {
        (__ci_expr_logic_16 = (if (if (unsafe *__param_strm).avail_in != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_16 != 0) {
        var __ci_expr_ternary_18: c_int = 0

        var __ci_expr_logic_17: c_int

        if ((if -5 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_17 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_17 != 0) {
            (__ci_expr_ternary_18 = ((9 as c_int)))
        } else {
            (__ci_expr_ternary_18 = (((2 - -5) as c_int)))
        }

        ((unsafe *__param_strm).msg = ((z_errmsg[__ci_expr_ternary_18] as *mut c_char)))

        return -5


    }


    var __ci_expr_logic_19: c_int = 0

    if ((if (unsafe *__local_s).status == 42: 1 else: 0) != 0) {
        (__ci_expr_logic_19 = (if (if (unsafe *__local_s).wrap == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_19 != 0) {
        ((unsafe *__local_s).status = ((113 as c_int)))
    }


    if ((if (unsafe *__local_s).status == 42: 1 else: 0) != 0) {
        var __local_header: c_uint = ((((((8 as c_uint) +% ((((((unsafe *__local_s).w_bits as c_uint) -% (8 as c_uint)) as c_uint) << (4 as c_uint)) as c_uint)) as c_uint) << (8 as c_uint)) as c_uint))

        var __local_level_flags: c_uint

        var __ci_expr_logic_20: c_int

        if ((if (unsafe *__local_s).strategy >= 2: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_20 = (if (if (unsafe *__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_20 != 0) {
            (__local_level_flags = ((0 as c_uint)))
        } else {
            if ((if (unsafe *__local_s).level < 6: 1 else: 0) != 0) {
                (__local_level_flags = ((1 as c_uint)))
            } else {
                if ((if (unsafe *__local_s).level == 6: 1 else: 0) != 0) {
                    (__local_level_flags = ((2 as c_uint)))
                } else {
                    (__local_level_flags = ((3 as c_uint)))
                }
            }
        }


        (__local_header = (__local_header as c_uint) | (((__local_level_flags as c_uint) << (6 as c_uint)) as c_uint))

        if ((if (unsafe *__local_s).strstart != 0: 1 else: 0) != 0) {
            (__local_header = (__local_header as c_uint) | (32 as c_uint))
        }

        (__local_header = (__local_header +% ((31 as c_uint) -% (((__local_header as c_uint) % (31 as c_uint)) as c_uint))))

        putShortMSB(__local_s, __local_header)

        if ((if (unsafe *__local_s).strstart != 0: 1 else: 0) != 0) {
            putShortMSB(__local_s, ((((unsafe *__param_strm).adler as c_ulong) >> (16 as c_uint)) as c_uint))

            putShortMSB(__local_s, ((((unsafe *__param_strm).adler as c_ulong) & (65535 as c_ulong)) as c_uint))

        }

        ((unsafe *__param_strm).adler = ((adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        ((unsafe *__local_s).status = ((113 as c_int)))

        flush_pending(__param_strm)

        if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
            ((unsafe *__local_s).last_flush = ((-1 as c_int)))

            return 0

        }

    }

    if ((if (unsafe *__local_s).status == 57: 1 else: 0) != 0) {
        ((unsafe *__param_strm).adler = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        var __ci_expr_old_21: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_21]) = ((31 as u8)))



        var __ci_expr_old_22: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_22]) = ((139 as u8)))



        var __ci_expr_old_23: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_23]) = ((8 as u8)))



        if ((if (unsafe *__local_s).gzhead == 0: 1 else: 0) != 0) {
            var __ci_expr_old_24: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_24]) = ((0 as u8)))



            var __ci_expr_old_25: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_25]) = ((0 as u8)))



            var __ci_expr_old_26: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_26]) = ((0 as u8)))



            var __ci_expr_old_27: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_27]) = ((0 as u8)))



            var __ci_expr_old_28: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_28]) = ((0 as u8)))



            var __ci_expr_old_29: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            var __ci_expr_ternary_32: c_int = 0

            if ((if (unsafe *__local_s).level == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_32 = ((2 as c_int)))
            } else {
                var __ci_expr_ternary_31: c_int = 0

                var __ci_expr_logic_30: c_int

                if ((if (unsafe *__local_s).strategy >= 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_30 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_30 = (if (if (unsafe *__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_30 != 0) {
                    (__ci_expr_ternary_31 = ((4 as c_int)))
                } else {
                    (__ci_expr_ternary_31 = ((0 as c_int)))
                }

                (__ci_expr_ternary_32 = __ci_expr_ternary_31)

            }

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_29]) = ((__ci_expr_ternary_32 as u8)))



            var __ci_expr_old_33: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_33]) = ((19 as u8)))



            ((unsafe *__local_s).status = ((113 as c_int)))

            flush_pending(__param_strm)

            if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
                ((unsafe *__local_s).last_flush = ((-1 as c_int)))

                return 0

            }

        } else {
            var __ci_expr_old_34: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            var __ci_expr_ternary_35: c_int = 0

            if ((unsafe *__local_s).gzhead.text != 0) {
                (__ci_expr_ternary_35 = ((1 as c_int)))
            } else {
                (__ci_expr_ternary_35 = ((0 as c_int)))
            }

            var __ci_expr_ternary_36: c_int = 0

            if ((unsafe *__local_s).gzhead.hcrc != 0) {
                (__ci_expr_ternary_36 = ((2 as c_int)))
            } else {
                (__ci_expr_ternary_36 = ((0 as c_int)))
            }

            var __ci_expr_ternary_37: c_int = 0

            if ((if (unsafe *__local_s).gzhead.extra == 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_37 = ((0 as c_int)))
            } else {
                (__ci_expr_ternary_37 = ((4 as c_int)))
            }

            var __ci_expr_ternary_38: c_int = 0

            if ((if (unsafe *__local_s).gzhead.name == 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_38 = ((0 as c_int)))
            } else {
                (__ci_expr_ternary_38 = ((8 as c_int)))
            }

            var __ci_expr_ternary_39: c_int = 0

            if ((if (unsafe *__local_s).gzhead.comment == 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_39 = ((0 as c_int)))
            } else {
                (__ci_expr_ternary_39 = ((16 as c_int)))
            }

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_34]) = ((((((__ci_expr_ternary_35 + __ci_expr_ternary_36) + __ci_expr_ternary_37) + __ci_expr_ternary_38) + __ci_expr_ternary_39) as u8)))



            var __ci_expr_old_40: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_40]) = (((((unsafe *__local_s).gzhead.time as c_ulong) & (255 as c_ulong)) as u8)))



            var __ci_expr_old_41: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_41]) = (((((((unsafe *__local_s).gzhead.time as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



            var __ci_expr_old_42: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_42]) = (((((((unsafe *__local_s).gzhead.time as c_ulong) >> (16 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



            var __ci_expr_old_43: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_43]) = (((((((unsafe *__local_s).gzhead.time as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



            var __ci_expr_old_44: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            var __ci_expr_ternary_47: c_int = 0

            if ((if (unsafe *__local_s).level == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_47 = ((2 as c_int)))
            } else {
                var __ci_expr_ternary_46: c_int = 0

                var __ci_expr_logic_45: c_int

                if ((if (unsafe *__local_s).strategy >= 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_45 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_45 = (if (if (unsafe *__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_45 != 0) {
                    (__ci_expr_ternary_46 = ((4 as c_int)))
                } else {
                    (__ci_expr_ternary_46 = ((0 as c_int)))
                }

                (__ci_expr_ternary_47 = __ci_expr_ternary_46)

            }

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_44]) = ((__ci_expr_ternary_47 as u8)))



            var __ci_expr_old_48: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_48]) = (((((unsafe *__local_s).gzhead.os as c_int) & (255 as c_int)) as u8)))



            if ((if (unsafe *__local_s).gzhead.extra != 0: 1 else: 0) != 0) {
                var __ci_expr_old_49: c_ulong = (unsafe *__local_s).pending

                ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

                ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_49]) = (((((unsafe *__local_s).gzhead.extra_len as c_uint) & (255 as c_uint)) as u8)))



                var __ci_expr_old_50: c_ulong = (unsafe *__local_s).pending

                ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

                ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_50]) = (((((((unsafe *__local_s).gzhead.extra_len as c_uint) >> (8 as c_uint)) as c_uint) & (255 as c_uint)) as u8)))



            }

            if ((unsafe *__local_s).gzhead.hcrc != 0) {
                ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, ((unsafe *__local_s).pending_buf as *const u8), (unsafe *__local_s).pending) as c_ulong)))
            }

            ((unsafe *__local_s).gzindex = ((0 as c_ulong)))

            ((unsafe *__local_s).status = ((69 as c_int)))

        }

    }

    if ((if (unsafe *__local_s).status == 69: 1 else: 0) != 0) {
        if ((if (unsafe *__local_s).gzhead.extra != 0: 1 else: 0) != 0) {
            var __local_beg: c_ulong = (unsafe *__local_s).pending

            var __local_left: c_ulong = (((((((unsafe *__local_s).gzhead.extra_len as c_uint) & (65535 as c_uint)) as c_ulong) -% ((unsafe *__local_s).gzindex as c_ulong)) as c_ulong))

            while ((if (((unsafe *__local_s).pending as c_ulong) +% (__local_left as c_ulong)) > (unsafe *__local_s).pending_buf_size: 1 else: 0) != 0) {
                var __local_copy_: c_ulong = (((((unsafe *__local_s).pending_buf_size as c_ulong) -% ((unsafe *__local_s).pending as c_ulong)) as c_ulong))

                with_memcpy(((((unsafe *__local_s).pending_buf + ((unsafe *__local_s).pending as usize)) as *mut c_void) as *i8), ((((unsafe *__local_s).gzhead.extra + ((unsafe *__local_s).gzindex as usize)) as *const c_void) as *i8), (__local_copy_ as i64))

                ((unsafe *__local_s).pending = (unsafe *__local_s).pending_buf_size)

                loop {
                    var __ci_expr_logic_51: c_int = 0

                    if ((unsafe *__local_s).gzhead.hcrc != 0) {
                        (__ci_expr_logic_51 = (if (if (unsafe *__local_s).pending > __local_beg: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_51 != 0) {
                        ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, (((unsafe *__local_s).pending_buf + (__local_beg as usize)) as *const u8), ((((unsafe *__local_s).pending as c_ulong) -% (__local_beg as c_ulong)) as c_ulong)) as c_ulong)))
                    }


                    if not ((0 != 0)) {
                        break
                    }
                }

                ((unsafe *__local_s).gzindex = ((unsafe *__local_s).gzindex +% __local_copy_))

                flush_pending(__param_strm)

                if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
                    ((unsafe *__local_s).last_flush = ((-1 as c_int)))

                    return 0

                }

                (__local_beg = ((0 as c_ulong)))

                (__local_left = (__local_left -% __local_copy_))

            }

            with_memcpy(((((unsafe *__local_s).pending_buf + ((unsafe *__local_s).pending as usize)) as *mut c_void) as *i8), ((((unsafe *__local_s).gzhead.extra + ((unsafe *__local_s).gzindex as usize)) as *const c_void) as *i8), (__local_left as i64))

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% __local_left))

            loop {
                var __ci_expr_logic_52: c_int = 0

                if ((unsafe *__local_s).gzhead.hcrc != 0) {
                    (__ci_expr_logic_52 = (if (if (unsafe *__local_s).pending > __local_beg: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_52 != 0) {
                    ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, (((unsafe *__local_s).pending_buf + (__local_beg as usize)) as *const u8), ((((unsafe *__local_s).pending as c_ulong) -% (__local_beg as c_ulong)) as c_ulong)) as c_ulong)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

            ((unsafe *__local_s).gzindex = ((0 as c_ulong)))

        }

        ((unsafe *__local_s).status = ((73 as c_int)))

    }

    if ((if (unsafe *__local_s).status == 73: 1 else: 0) != 0) {
        if ((if (unsafe *__local_s).gzhead.name != 0: 1 else: 0) != 0) {
            var __local_beg_1: c_ulong = (unsafe *__local_s).pending

            var __local_val: c_int

            loop {
                if ((if (unsafe *__local_s).pending == (unsafe *__local_s).pending_buf_size: 1 else: 0) != 0) {
                    loop {
                        var __ci_expr_logic_53: c_int = 0

                        if ((unsafe *__local_s).gzhead.hcrc != 0) {
                            (__ci_expr_logic_53 = (if (if (unsafe *__local_s).pending > __local_beg_1: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_53 != 0) {
                            ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, (((unsafe *__local_s).pending_buf + (__local_beg_1 as usize)) as *const u8), ((((unsafe *__local_s).pending as c_ulong) -% (__local_beg_1 as c_ulong)) as c_ulong)) as c_ulong)))
                        }


                        if not ((0 != 0)) {
                            break
                        }
                    }

                    flush_pending(__param_strm)

                    if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
                        ((unsafe *__local_s).last_flush = ((-1 as c_int)))

                        return 0

                    }

                    (__local_beg_1 = ((0 as c_ulong)))

                }

                var __ci_expr_old_54: c_ulong = (unsafe *__local_s).gzindex

                ((unsafe *__local_s).gzindex = ((unsafe *__local_s).gzindex +% 1))

                (__local_val = (((unsafe (unsafe *__local_s).gzhead.name[__ci_expr_old_54]) as c_int)))


                var __ci_expr_old_55: c_ulong = (unsafe *__local_s).pending

                ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

                ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_55]) = ((__local_val as u8)))



                if not (((if __local_val != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            loop {
                var __ci_expr_logic_56: c_int = 0

                if ((unsafe *__local_s).gzhead.hcrc != 0) {
                    (__ci_expr_logic_56 = (if (if (unsafe *__local_s).pending > __local_beg_1: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_56 != 0) {
                    ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, (((unsafe *__local_s).pending_buf + (__local_beg_1 as usize)) as *const u8), ((((unsafe *__local_s).pending as c_ulong) -% (__local_beg_1 as c_ulong)) as c_ulong)) as c_ulong)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

            ((unsafe *__local_s).gzindex = ((0 as c_ulong)))

        }

        ((unsafe *__local_s).status = ((91 as c_int)))

    }

    if ((if (unsafe *__local_s).status == 91: 1 else: 0) != 0) {
        if ((if (unsafe *__local_s).gzhead.comment != 0: 1 else: 0) != 0) {
            var __local_beg_2: c_ulong = (unsafe *__local_s).pending

            var __local_val_1: c_int

            loop {
                if ((if (unsafe *__local_s).pending == (unsafe *__local_s).pending_buf_size: 1 else: 0) != 0) {
                    loop {
                        var __ci_expr_logic_57: c_int = 0

                        if ((unsafe *__local_s).gzhead.hcrc != 0) {
                            (__ci_expr_logic_57 = (if (if (unsafe *__local_s).pending > __local_beg_2: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_57 != 0) {
                            ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, (((unsafe *__local_s).pending_buf + (__local_beg_2 as usize)) as *const u8), ((((unsafe *__local_s).pending as c_ulong) -% (__local_beg_2 as c_ulong)) as c_ulong)) as c_ulong)))
                        }


                        if not ((0 != 0)) {
                            break
                        }
                    }

                    flush_pending(__param_strm)

                    if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
                        ((unsafe *__local_s).last_flush = ((-1 as c_int)))

                        return 0

                    }

                    (__local_beg_2 = ((0 as c_ulong)))

                }

                var __ci_expr_old_58: c_ulong = (unsafe *__local_s).gzindex

                ((unsafe *__local_s).gzindex = ((unsafe *__local_s).gzindex +% 1))

                (__local_val_1 = (((unsafe (unsafe *__local_s).gzhead.comment[__ci_expr_old_58]) as c_int)))


                var __ci_expr_old_59: c_ulong = (unsafe *__local_s).pending

                ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

                ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_59]) = ((__local_val_1 as u8)))



                if not (((if __local_val_1 != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            loop {
                var __ci_expr_logic_60: c_int = 0

                if ((unsafe *__local_s).gzhead.hcrc != 0) {
                    (__ci_expr_logic_60 = (if (if (unsafe *__local_s).pending > __local_beg_2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_60 != 0) {
                    ((unsafe *__param_strm).adler = ((crc32_z((unsafe *__param_strm).adler, (((unsafe *__local_s).pending_buf + (__local_beg_2 as usize)) as *const u8), ((((unsafe *__local_s).pending as c_ulong) -% (__local_beg_2 as c_ulong)) as c_ulong)) as c_ulong)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

        }

        ((unsafe *__local_s).status = ((103 as c_int)))

    }

    if ((if (unsafe *__local_s).status == 103: 1 else: 0) != 0) {
        if ((unsafe *__local_s).gzhead.hcrc != 0) {
            if ((if (((unsafe *__local_s).pending as c_ulong) +% (2 as c_ulong)) > (unsafe *__local_s).pending_buf_size: 1 else: 0) != 0) {
                flush_pending(__param_strm)

                if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
                    ((unsafe *__local_s).last_flush = ((-1 as c_int)))

                    return 0

                }

            }

            var __ci_expr_old_61: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_61]) = (((((unsafe *__param_strm).adler as c_ulong) & (255 as c_ulong)) as u8)))



            var __ci_expr_old_62: c_ulong = (unsafe *__local_s).pending

            ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

            ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_62]) = (((((((unsafe *__param_strm).adler as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



            ((unsafe *__param_strm).adler = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        }

        ((unsafe *__local_s).status = ((113 as c_int)))

        flush_pending(__param_strm)

        if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
            ((unsafe *__local_s).last_flush = ((-1 as c_int)))

            return 0

        }

    }

    var __ci_expr_logic_65: c_int

    var __ci_expr_logic_63: c_int

    if ((if (unsafe *__param_strm).avail_in != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_63 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_63 = (if (if (unsafe *__local_s).lookahead != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_63 != 0) {
        (__ci_expr_logic_65 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_64: c_int = 0

        if ((if __param_flush != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_64 = (if (if (unsafe *__local_s).status != 666: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_65 = (if __ci_expr_logic_64 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_65 != 0) {
        var __local_bstate: i32

        var __ci_expr_ternary_68: c_uint = 0

        if ((if (unsafe *__local_s).level == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_68 = ((deflate_stored(__local_s, __param_flush) as c_uint)))
        } else {
            var __ci_expr_ternary_67: c_uint = 0

            if ((if (unsafe *__local_s).strategy == 2: 1 else: 0) != 0) {
                (__ci_expr_ternary_67 = ((deflate_huff(__local_s, __param_flush) as c_uint)))
            } else {
                var __ci_expr_ternary_66: c_uint = 0

                if ((if (unsafe *__local_s).strategy == 3: 1 else: 0) != 0) {
                    (__ci_expr_ternary_66 = ((deflate_rle(__local_s, __param_flush) as c_uint)))
                } else {
                    (__ci_expr_ternary_66 = ((configuration_table[(unsafe *__local_s).level].func(__local_s, __param_flush) as c_uint)))
                }

                (__ci_expr_ternary_67 = __ci_expr_ternary_66)

            }

            (__ci_expr_ternary_68 = __ci_expr_ternary_67)

        }

        (__local_bstate = ((__ci_expr_ternary_68 as i32)))


        var __ci_expr_logic_69: c_int

        if ((if __local_bstate == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_69 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_69 = (if (if __local_bstate == 3: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_69 != 0) {
            ((unsafe *__local_s).status = ((666 as c_int)))

        }


        var __ci_expr_logic_70: c_int

        if ((if __local_bstate == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_70 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_70 = (if (if __local_bstate == 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_70 != 0) {
            if ((if (unsafe *__param_strm).avail_out == 0: 1 else: 0) != 0) {
                ((unsafe *__local_s).last_flush = ((-1 as c_int)))

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
                            ((unsafe (unsafe *__local_s).head[(((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

                            with_memset((((unsafe *__local_s).head as *mut c_void) as *i8), (0 as c_int), (((((((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

                            ((unsafe *__local_s).slid = ((0 as c_int)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if ((if (unsafe *__local_s).lookahead == 0: 1 else: 0) != 0) {
                            ((unsafe *__local_s).strstart = ((0 as c_uint)))

                            ((unsafe *__local_s).block_start = ((0 as c_long)))

                            ((unsafe *__local_s).insert = ((0 as c_uint)))

                        }

                    }

                }
            }

            flush_pending(__param_strm)

            if ((if (unsafe *__param_strm).avail_out == 0: 1 else: 0) != 0) {
                ((unsafe *__local_s).last_flush = ((-1 as c_int)))

                return 0

            }

        }

    }


    if ((if __param_flush != 4: 1 else: 0) != 0) {
        return 0
    }

    if ((if (unsafe *__local_s).wrap <= 0: 1 else: 0) != 0) {
        return 1
    }

    if ((if (unsafe *__local_s).wrap == 2: 1 else: 0) != 0) {
        var __ci_expr_old_71: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_71]) = (((((unsafe *__param_strm).adler as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_72: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_72]) = (((((((unsafe *__param_strm).adler as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_73: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_73]) = (((((((unsafe *__param_strm).adler as c_ulong) >> (16 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_74: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_74]) = (((((((unsafe *__param_strm).adler as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_75: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_75]) = (((((unsafe *__param_strm).total_in as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_76: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_76]) = (((((((unsafe *__param_strm).total_in as c_ulong) >> (8 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_77: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_77]) = (((((((unsafe *__param_strm).total_in as c_ulong) >> (16 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



        var __ci_expr_old_78: c_ulong = (unsafe *__local_s).pending

        ((unsafe *__local_s).pending = ((unsafe *__local_s).pending +% 1))

        ((unsafe (unsafe *__local_s).pending_buf[__ci_expr_old_78]) = (((((((unsafe *__param_strm).total_in as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as u8)))



    } else {
        putShortMSB(__local_s, ((((unsafe *__param_strm).adler as c_ulong) >> (16 as c_uint)) as c_uint))

        putShortMSB(__local_s, ((((unsafe *__param_strm).adler as c_ulong) & (65535 as c_ulong)) as c_uint))

    }

    flush_pending(__param_strm)

    if ((if (unsafe *__local_s).wrap > 0: 1 else: 0) != 0) {
        ((unsafe *__local_s).wrap = (((0 - (unsafe *__local_s).wrap) as c_int)))
    }

    var __ci_expr_ternary_79: c_int = 0

    if ((if (unsafe *__local_s).pending != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_79 = ((0 as c_int)))
    } else {
        (__ci_expr_ternary_79 = ((1 as c_int)))
    }

    return __ci_expr_ternary_79


}

pub unsafe fn deflateEnd(__param_strm: *mut z_stream_s) -> c_int {
    var __local_status: c_int

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_status = (unsafe *(unsafe *__param_strm).state).status)

    if ((unsafe *(unsafe *__param_strm).state).pending_buf != null) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *(unsafe *__param_strm).state).pending_buf as *mut c_void))
    }


    if ((unsafe *(unsafe *__param_strm).state).head != null) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *(unsafe *__param_strm).state).head as *mut c_void))
    }


    if ((unsafe *(unsafe *__param_strm).state).prev != null) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *(unsafe *__param_strm).state).prev as *mut c_void))
    }


    if ((unsafe *(unsafe *__param_strm).state).window != null) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *(unsafe *__param_strm).state).window as *mut c_void))
    }


    (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *__param_strm).state as *mut c_void))

    ((unsafe *__param_strm).state = null)

    var __ci_expr_ternary_0: c_int = 0

    if ((if __local_status == 113: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((-3 as c_int)))
    } else {
        (__ci_expr_ternary_0 = ((0 as c_int)))
    }

    return __ci_expr_ternary_0


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


    (__local_s = (unsafe *__param_strm).state)

    (__local_wrap = (unsafe *__local_s).wrap)

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if __local_wrap == 2: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_1: c_int = 0

        if ((if __local_wrap == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe *__local_s).status != 42: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (unsafe *__local_s).lookahead != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return -2
    }


    if ((if __local_wrap == 1: 1 else: 0) != 0) {
        ((unsafe *__param_strm).adler = ((adler32((unsafe *__param_strm).adler, __local_dictionary, __local_dictLength) as c_ulong)))
    }

    ((unsafe *__local_s).wrap = ((0 as c_int)))

    if ((if __local_dictLength >= (unsafe *__local_s).w_size: 1 else: 0) != 0) {
        if ((if __local_wrap == 0: 1 else: 0) != 0) {
            loop {
                ((unsafe (unsafe *__local_s).head[(((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

                with_memset((((unsafe *__local_s).head as *mut c_void) as *i8), (0 as c_int), (((((((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

                ((unsafe *__local_s).slid = ((0 as c_int)))

                if not ((0 != 0)) {
                    break
                }
            }

            ((unsafe *__local_s).strstart = ((0 as c_uint)))

            ((unsafe *__local_s).block_start = ((0 as c_long)))

            ((unsafe *__local_s).insert = ((0 as c_uint)))

        }

        (__local_dictionary = __local_dictionary + (((__local_dictLength as c_uint) -% ((unsafe *__local_s).w_size as c_uint)) as usize))

        (__local_dictLength = (unsafe *__local_s).w_size)

    }

    (__local_avail = (unsafe *__param_strm).avail_in)

    (__local_next = (unsafe *__param_strm).next_in)

    ((unsafe *__param_strm).avail_in = __local_dictLength)

    ((unsafe *__param_strm).next_in = ((__local_dictionary as *mut u8)))

    fill_window(__local_s)

    while ((if (unsafe *__local_s).lookahead >= 3: 1 else: 0) != 0) {
        (__local_str = (unsafe *__local_s).strstart)

        (__local_n = (((((unsafe *__local_s).lookahead as c_uint) -% (2 as c_uint)) as c_uint)))

        loop {
            ((unsafe *__local_s).ins_h = (((((((((unsafe *__local_s).ins_h as c_uint) << ((unsafe *__local_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__local_s).window[((((__local_str as c_uint) +% (3 as c_uint)) as c_uint) -% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__local_s).hash_mask as c_uint)) as c_uint)))

            ((unsafe (unsafe *__local_s).prev[((__local_str as c_uint) & ((unsafe *__local_s).w_mask as c_uint))]) = (((unsafe (unsafe *__local_s).head[(unsafe *__local_s).ins_h]) as c_ushort)))

            ((unsafe (unsafe *__local_s).head[(unsafe *__local_s).ins_h]) = ((__local_str as c_ushort)))

            (__local_str = (__local_str +% 1))

            (__local_n = (__local_n -% 1))
            if not ((__local_n != 0)) {
                break
            }
        }

        ((unsafe *__local_s).strstart = __local_str)

        ((unsafe *__local_s).lookahead = ((2 as c_uint)))

        fill_window(__local_s)

    }

    ((unsafe *__local_s).strstart = ((unsafe *__local_s).strstart +% (unsafe *__local_s).lookahead))

    ((unsafe *__local_s).block_start = (((unsafe *__local_s).strstart as c_long)))

    ((unsafe *__local_s).insert = (unsafe *__local_s).lookahead)

    ((unsafe *__local_s).lookahead = ((0 as c_uint)))

    ((unsafe *__local_s).prev_length = ((2 as c_uint)))

    ((unsafe *__local_s).match_length = (unsafe *__local_s).prev_length)


    ((unsafe *__local_s).match_available = ((0 as c_int)))

    ((unsafe *__param_strm).next_in = __local_next)

    ((unsafe *__param_strm).avail_in = __local_avail)

    ((unsafe *__local_s).wrap = __local_wrap)

    return 0

}

pub unsafe fn deflateGetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *mut u8, __param_dictLength: *mut c_uint) -> c_int {
    var __local_s: *mut internal_state

    var __local_len: c_uint

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (unsafe *__param_strm).state)

    (__local_len = (((((unsafe *__local_s).strstart as c_uint) +% ((unsafe *__local_s).lookahead as c_uint)) as c_uint)))

    if ((if __local_len > (unsafe *__local_s).w_size: 1 else: 0) != 0) {
        (__local_len = (unsafe *__local_s).w_size)
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_dictionary != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if __local_len != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy(((__param_dictionary as *mut c_void) as *i8), ((((((unsafe *__local_s).window + ((unsafe *__local_s).strstart as usize)) + ((unsafe *__local_s).lookahead as usize)) - (__local_len as usize)) as *const c_void) as *i8), ((__local_len as c_ulong) as i64))
    }


    if ((if __param_dictLength != 0: 1 else: 0) != 0) {
        ((unsafe *__param_dictLength) = __local_len)
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


    (__local_ss = (unsafe *__param_source).state)

    with_memcpy(((__param_dest as *mut c_void) as *i8), ((__param_source as *const c_void) as *i8), ((sizeof[z_stream_s]() as c_ulong) as i64))

    (__local_ds = (((unsafe *__param_dest).zalloc((unsafe *__param_dest).opaque_, 1, 5968) as *mut internal_state)))

    if ((if __local_ds == 0: 1 else: 0) != 0) {
        return -4
    }

    with_memset(((__local_ds as *mut c_void) as *i8), (0 as c_int), ((sizeof[internal_state]() as c_ulong) as i64))

    ((unsafe *__param_dest).state = __local_ds)

    with_memcpy(((__local_ds as *mut c_void) as *i8), ((__local_ss as *const c_void) as *i8), ((sizeof[internal_state]() as c_ulong) as i64))

    ((unsafe *__local_ds).strm = __param_dest)

    ((unsafe *__local_ds).window = (((unsafe *__param_dest).zalloc((unsafe *__param_dest).opaque_, (unsafe *__local_ds).w_size, 2) as *mut u8)))

    ((unsafe *__local_ds).prev = (((unsafe *__param_dest).zalloc((unsafe *__param_dest).opaque_, (unsafe *__local_ds).w_size, 2) as *mut c_ushort)))

    ((unsafe *__local_ds).head = (((unsafe *__param_dest).zalloc((unsafe *__param_dest).opaque_, (unsafe *__local_ds).hash_size, 2) as *mut c_ushort)))

    ((unsafe *__local_ds).pending_buf = (((unsafe *__param_dest).zalloc((unsafe *__param_dest).opaque_, (unsafe *__local_ds).lit_bufsize, 4) as *mut u8)))

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    if ((if (unsafe *__local_ds).window == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__local_ds).prev == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (unsafe *__local_ds).head == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (unsafe *__local_ds).pending_buf == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        deflateEnd(__param_dest)

        return -4

    }


    with_memcpy((((unsafe *__local_ds).window as *mut c_void) as *i8), (((unsafe *__local_ss).window as *const c_void) as *i8), ((unsafe *__local_ss).high_water as i64))

    var __ci_expr_ternary_5: c_uint = 0

    var __ci_expr_logic_4: c_int

    if ((unsafe *__local_ss).slid != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if (((unsafe *__local_ss).strstart as c_uint) -% ((unsafe *__local_ss).insert as c_uint)) > (unsafe *__local_ds).w_size: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_ternary_5 = (unsafe *__local_ds).w_size)
    } else {
        (__ci_expr_ternary_5 = (((((unsafe *__local_ss).strstart as c_uint) -% ((unsafe *__local_ss).insert as c_uint)) as c_uint)))
    }

    with_memcpy((((unsafe *__local_ds).prev as *mut c_void) as *i8), (((unsafe *__local_ss).prev as *const c_void) as *i8), ((((__ci_expr_ternary_5 as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))


    with_memcpy((((unsafe *__local_ds).head as *mut c_void) as *i8), (((unsafe *__local_ss).head as *const c_void) as *i8), (((((unsafe *__local_ds).hash_size as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

    ((unsafe *__local_ds).pending_out = (unsafe *__local_ds).pending_buf + ((((((unsafe *__local_ss).pending_out as usize) -% ((unsafe *__local_ss).pending_buf as usize)) / sizeof[u8]()) as isize) as usize))

    with_memcpy((((unsafe *__local_ds).pending_out as *mut c_void) as *i8), (((unsafe *__local_ss).pending_out as *const c_void) as *i8), ((unsafe *__local_ss).pending as i64))

    ((unsafe *__local_ds).sym_buf = (unsafe *__local_ds).pending_buf + ((unsafe *__local_ds).lit_bufsize as usize))

    with_memcpy((((unsafe *__local_ds).sym_buf as *mut c_void) as *i8), (((unsafe *__local_ss).sym_buf as *const c_void) as *i8), (((unsafe *__local_ss).sym_next as c_ulong) as i64))

    ((unsafe *__local_ds).l_desc.dyn_tree = (&(unsafe *__local_ds).dyn_ltree[0] as *mut ct_data_s))

    ((unsafe *__local_ds).d_desc.dyn_tree = (&(unsafe *__local_ds).dyn_dtree[0] as *mut ct_data_s))

    ((unsafe *__local_ds).bl_desc.dyn_tree = (&(unsafe *__local_ds).bl_tree[0] as *mut ct_data_s))

    return 0

}

pub unsafe fn deflateReset(__param_strm: *mut z_stream_s) -> c_int {
    var __local_ret: c_int

    (__local_ret = ((deflateResetKeep(__param_strm) as c_int)))

    if ((if __local_ret == 0: 1 else: 0) != 0) {
        lm_init((unsafe *__param_strm).state)
    }

    return __local_ret

}

pub unsafe fn deflateParams(__param_strm: *mut z_stream_s, __param_level: c_int, __param_strategy: c_int) -> c_int {
    var __local_level = __param_level
    var __local_s: *mut internal_state

    var __local_func: unsafe extern "C" fn(*mut internal_state, c_int) -> i32

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (unsafe *__param_strm).state)

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


    (__local_func = configuration_table[(unsafe *__local_s).level].func)

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_3: c_int

    if ((if __param_strategy != (unsafe *__local_s).strategy: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if __local_func != configuration_table[__local_level].func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if (if (unsafe *__local_s).last_flush != -2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        var __local_err: c_int = ((deflate(__param_strm, (5 as c_int)) as c_int))

        if ((if __local_err == -2: 1 else: 0) != 0) {
            return __local_err
        }

        var __ci_expr_logic_5: c_int

        if ((unsafe *__param_strm).avail_in != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_5 = (if (((unsafe *__local_s).strstart - (unsafe *__local_s).block_start) + (unsafe *__local_s).lookahead) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            return -5
        }


    }


    if ((if (unsafe *__local_s).level != __local_level: 1 else: 0) != 0) {
        var __ci_expr_logic_6: c_int = 0

        if ((if (unsafe *__local_s).level == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe *__local_s).matches != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            if ((if (unsafe *__local_s).matches == 1: 1 else: 0) != 0) {
                slide_hash(__local_s)
            } else {
                loop {
                    ((unsafe (unsafe *__local_s).head[(((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

                    with_memset((((unsafe *__local_s).head as *mut c_void) as *i8), (0 as c_int), (((((((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

                    ((unsafe *__local_s).slid = ((0 as c_int)))

                    if not ((0 != 0)) {
                        break
                    }
                }
            }

            ((unsafe *__local_s).matches = ((0 as c_uint)))

        }


        ((unsafe *__local_s).level = __local_level)

        ((unsafe *__local_s).max_lazy_match = ((configuration_table[__local_level].max_lazy as c_uint)))

        ((unsafe *__local_s).good_match = ((configuration_table[__local_level].good_length as c_uint)))

        ((unsafe *__local_s).nice_match = ((configuration_table[__local_level].nice_length as c_int)))

        ((unsafe *__local_s).max_chain_length = ((configuration_table[__local_level].max_chain as c_uint)))

    }

    ((unsafe *__local_s).strategy = __param_strategy)

    return 0

}

pub unsafe fn deflateTune(__param_strm: *mut z_stream_s, __param_good_length: c_int, __param_max_lazy: c_int, __param_nice_length: c_int, __param_max_chain: c_int) -> c_int {
    var __local_s: *mut internal_state

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (unsafe *__param_strm).state)

    ((unsafe *__local_s).good_match = ((__param_good_length as c_uint)))

    ((unsafe *__local_s).max_lazy_match = ((__param_max_lazy as c_uint)))

    ((unsafe *__local_s).nice_match = __param_nice_length)

    ((unsafe *__local_s).max_chain_length = ((__param_max_chain as c_uint)))

    return 0

}

pub unsafe fn deflateBound(__param_strm: *mut z_stream_s, __param_sourceLen: c_ulong) -> c_ulong {
    var __local_bound: c_ulong = ((deflateBound_z(__param_strm, __param_sourceLen) as c_ulong))

    var __ci_expr_ternary_0: c_ulong = 0

    if ((if __local_bound != __local_bound: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((-1 as c_ulong)))
    } else {
        (__ci_expr_ternary_0 = __local_bound)
    }

    return __ci_expr_ternary_0


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
        var __ci_expr_ternary_0: c_ulong = 0

        if ((if __local_fixedlen > __local_storelen: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = __local_fixedlen)
        } else {
            (__ci_expr_ternary_0 = __local_storelen)
        }

        (__local_bound = __ci_expr_ternary_0)


        var __ci_expr_ternary_1: c_ulong = 0

        if ((if ((__local_bound as c_ulong) +% (18 as c_ulong)) < __local_bound: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = ((-1 as c_ulong)))
        } else {
            (__ci_expr_ternary_1 = ((((__local_bound as c_ulong) +% (18 as c_ulong)) as c_ulong)))
        }

        return __ci_expr_ternary_1


    }

    (__local_s = (unsafe *__param_strm).state)

    var __ci_expr_ternary_2: c_int = 0

    if ((if (unsafe *__local_s).wrap < 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_2 = (((0 - (unsafe *__local_s).wrap) as c_int)))
    } else {
        (__ci_expr_ternary_2 = (unsafe *__local_s).wrap)
    }

    var __ci_expr_switch_2: c_int = __ci_expr_ternary_2

    while true {
        match __ci_expr_switch_2 {
            0 => {
                (__local_wraplen = ((0 as c_ulong)))
            },
            1 => {
                var __ci_expr_ternary_3: c_int = 0

                if ((unsafe *__local_s).strstart != 0) {
                    (__ci_expr_ternary_3 = ((4 as c_int)))
                } else {
                    (__ci_expr_ternary_3 = ((0 as c_int)))
                }

                (__local_wraplen = (((6 + __ci_expr_ternary_3) as c_ulong)))

            },
            2 => {
                (__local_wraplen = ((18 as c_ulong)))

                if ((if (unsafe *__local_s).gzhead != 0: 1 else: 0) != 0) {
                    var __local_str: *mut u8

                    if ((if (unsafe *__local_s).gzhead.extra != 0: 1 else: 0) != 0) {
                        (__local_wraplen = (__local_wraplen +% ((2 as c_uint) +% ((unsafe *__local_s).gzhead.extra_len as c_uint))))
                    }

                    (__local_str = (unsafe *__local_s).gzhead.name)

                    if ((if __local_str != 0: 1 else: 0) != 0) {
                        loop {
                            (__local_wraplen = (__local_wraplen +% 1))

                            var __ci_expr_old_4: *mut u8 = __local_str

                            (__local_str = __local_str + 1)

                            if not (((unsafe *__ci_expr_old_4) != 0)) {
                                break
                            }
                        }
                    }

                    (__local_str = (unsafe *__local_s).gzhead.comment)

                    if ((if __local_str != 0: 1 else: 0) != 0) {
                        loop {
                            (__local_wraplen = (__local_wraplen +% 1))

                            var __ci_expr_old_5: *mut u8 = __local_str

                            (__local_str = __local_str + 1)

                            if not (((unsafe *__ci_expr_old_5) != 0)) {
                                break
                            }
                        }
                    }

                    if ((unsafe *__local_s).gzhead.hcrc != 0) {
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


    var __ci_expr_logic_7: c_int

    if ((if (unsafe *__local_s).w_bits != 15: 1 else: 0) != 0) {
        (__ci_expr_logic_7 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_7 = (if (if (unsafe *__local_s).hash_bits != 15: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        var __ci_expr_ternary_9: c_ulong = 0

        var __ci_expr_logic_8: c_int = 0

        if ((if (unsafe *__local_s).w_bits <= (unsafe *__local_s).hash_bits: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (unsafe *__local_s).level != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_ternary_9 = __local_fixedlen)
        } else {
            (__ci_expr_ternary_9 = __local_storelen)
        }

        (__local_bound = __ci_expr_ternary_9)


        var __ci_expr_ternary_10: c_ulong = 0

        if ((if ((__local_bound as c_ulong) +% (__local_wraplen as c_ulong)) < __local_bound: 1 else: 0) != 0) {
            (__ci_expr_ternary_10 = ((-1 as c_ulong)))
        } else {
            (__ci_expr_ternary_10 = ((((__local_bound as c_ulong) +% (__local_wraplen as c_ulong)) as c_ulong)))
        }

        return __ci_expr_ternary_10


    }


    (__local_bound = ((((((((((((((__param_sourceLen as c_ulong) +% (((__param_sourceLen as c_ulong) >> (12 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (14 as c_uint)) as c_ulong)) as c_ulong) +% (((__param_sourceLen as c_ulong) >> (25 as c_uint)) as c_ulong)) as c_ulong) +% (13 as c_ulong)) as c_ulong) -% (6 as c_ulong)) as c_ulong) +% (__local_wraplen as c_ulong)) as c_ulong)))

    var __ci_expr_ternary_11: c_ulong = 0

    if ((if __local_bound < __param_sourceLen: 1 else: 0) != 0) {
        (__ci_expr_ternary_11 = ((-1 as c_ulong)))
    } else {
        (__ci_expr_ternary_11 = __local_bound)
    }

    return __ci_expr_ternary_11


}

pub unsafe fn deflatePending(__param_strm: *mut z_stream_s, __param_pending: *mut c_uint, __param_bits: *mut c_int) -> c_int {
    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    if ((if __param_bits != 0: 1 else: 0) != 0) {
        ((unsafe *__param_bits) = (unsafe *(unsafe *__param_strm).state).bi_valid)
    }

    if ((if __param_pending != 0: 1 else: 0) != 0) {
        ((unsafe *__param_pending) = (((unsafe *(unsafe *__param_strm).state).pending as c_uint)))

        if ((if (unsafe *__param_pending) != (unsafe *(unsafe *__param_strm).state).pending: 1 else: 0) != 0) {
            ((unsafe *__param_pending) = ((-1 as c_uint)))

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
        ((unsafe *__param_bits) = (unsafe *(unsafe *__param_strm).state).bi_used)
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

    (__local_s = (unsafe *__param_strm).state)

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
        (__ci_expr_logic_1 = (if (if (unsafe *__local_s).sym_buf < ((unsafe *__local_s).pending_out + (((((16 + 7) as c_int) >> (3 as c_uint)) as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -5
    }


    loop {
        (__local_put = (((16 - (unsafe *__local_s).bi_valid) as c_int)))

        if ((if __local_put > __local_bits: 1 else: 0) != 0) {
            (__local_put = __local_bits)
        }

        ((unsafe *__local_s).bi_buf = ((unsafe *__local_s).bi_buf as c_ushort) | ((((((__local_value as c_int) & ((((1 as c_int) << (__local_put as c_uint)) - 1) as c_int)) as c_int) << ((unsafe *__local_s).bi_valid as c_uint)) as c_ushort) as c_ushort))

        ((unsafe *__local_s).bi_valid = (unsafe *__local_s).bi_valid + __local_put)

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
        (__ci_expr_logic_0 = (if (if (unsafe *(unsafe *__param_strm).state).wrap != 2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2
    }


    ((unsafe *(unsafe *__param_strm).state).gzhead = __param_head)

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
        (__ci_expr_logic_0 = (if (if (unsafe __param_version[0]) != 49: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_stream_size != sizeof[z_stream_s](): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -6

    }


    if ((if __param_strm == 0: 1 else: 0) != 0) {
        return -2
    }

    ((unsafe *__param_strm).msg = null)

    if ((if (unsafe *__param_strm).zalloc == ((0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)): 1 else: 0) != 0) {
        ((unsafe *__param_strm).zalloc = zcalloc)

        ((unsafe *__param_strm).opaque_ = ((0 as *mut c_void)))

    }

    if ((if (unsafe *__param_strm).zfree == ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)): 1 else: 0) != 0) {
        ((unsafe *__param_strm).zfree = zcfree)
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

    (__local_s = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, 1, 5968) as *mut internal_state)))

    if ((if __local_s == 0: 1 else: 0) != 0) {
        return -4
    }

    with_memset(((__local_s as *mut c_void) as *i8), (0 as c_int), ((sizeof[internal_state]() as c_ulong) as i64))

    ((unsafe *__param_strm).state = __local_s)

    ((unsafe *__local_s).strm = __param_strm)

    ((unsafe *__local_s).status = ((42 as c_int)))

    ((unsafe *__local_s).wrap = __local_wrap)

    ((unsafe *__local_s).gzhead = null)

    ((unsafe *__local_s).w_bits = ((__local_windowBits as c_uint)))

    ((unsafe *__local_s).w_size = ((((1 as c_int) << ((unsafe *__local_s).w_bits as c_uint)) as c_uint)))

    ((unsafe *__local_s).w_mask = (((((unsafe *__local_s).w_size as c_uint) -% (1 as c_uint)) as c_uint)))

    ((unsafe *__local_s).hash_bits = (((((__param_memLevel as c_uint) as c_uint) +% (7 as c_uint)) as c_uint)))

    ((unsafe *__local_s).hash_size = ((((1 as c_int) << ((unsafe *__local_s).hash_bits as c_uint)) as c_uint)))

    ((unsafe *__local_s).hash_mask = (((((unsafe *__local_s).hash_size as c_uint) -% (1 as c_uint)) as c_uint)))

    ((unsafe *__local_s).hash_shift = (((((((((unsafe *__local_s).hash_bits as c_uint) +% (3 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint) / (3 as c_uint)) as c_uint)))

    ((unsafe *__local_s).window = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, (unsafe *__local_s).w_size, 2) as *mut u8)))

    ((unsafe *__local_s).prev = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, (unsafe *__local_s).w_size, 2) as *mut c_ushort)))

    ((unsafe *__local_s).head = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, (unsafe *__local_s).hash_size, 2) as *mut c_ushort)))

    ((unsafe *__local_s).high_water = ((0 as c_ulong)))

    ((unsafe *__local_s).lit_bufsize = ((((1 as c_int) << ((__param_memLevel + 6) as c_uint)) as c_uint)))

    ((unsafe *__local_s).pending_buf = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, (unsafe *__local_s).lit_bufsize, 4) as *mut u8)))

    ((unsafe *__local_s).pending_buf_size = ((((((unsafe *__local_s).lit_bufsize as c_ulong) as c_ulong) *% (4 as c_ulong)) as c_ulong)))

    var __ci_expr_logic_14: c_int

    var __ci_expr_logic_13: c_int

    var __ci_expr_logic_12: c_int

    if ((if (unsafe *__local_s).window == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_12 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_12 = (if (if (unsafe *__local_s).prev == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_12 != 0) {
        (__ci_expr_logic_13 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_13 = (if (if (unsafe *__local_s).head == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_13 != 0) {
        (__ci_expr_logic_14 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_14 = (if (if (unsafe *__local_s).pending_buf == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_14 != 0) {
        ((unsafe *__local_s).status = ((666 as c_int)))

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

        ((unsafe *__param_strm).msg = ((z_errmsg[__ci_expr_ternary_16] as *mut c_char)))


        deflateEnd(__param_strm)

        return -4

    }


    ((unsafe *__local_s).sym_buf = (unsafe *__local_s).pending_buf + ((unsafe *__local_s).lit_bufsize as usize))

    ((unsafe *__local_s).sym_end = (((((((unsafe *__local_s).lit_bufsize as c_uint) -% (1 as c_uint)) as c_uint) *% (3 as c_uint)) as c_uint)))

    ((unsafe *__local_s).level = __local_level)

    ((unsafe *__local_s).strategy = __param_strategy)

    ((unsafe *__local_s).method = ((__param_method as u8)))

    return deflateReset(__param_strm)

}

pub unsafe fn deflateResetKeep(__param_strm: *mut z_stream_s) -> c_int {
    var __local_s: *mut internal_state

    if (deflateStateCheck(__param_strm) != 0) {
        return -2

    }

    ((unsafe *__param_strm).total_out = ((0 as c_ulong)))

    ((unsafe *__param_strm).total_in = (unsafe *__param_strm).total_out)


    ((unsafe *__param_strm).msg = null)

    ((unsafe *__param_strm).data_type = ((2 as c_int)))

    (__local_s = (unsafe *__param_strm).state)

    ((unsafe *__local_s).pending = ((0 as c_ulong)))

    ((unsafe *__local_s).pending_out = (unsafe *__local_s).pending_buf)

    if ((if (unsafe *__local_s).wrap < 0: 1 else: 0) != 0) {
        ((unsafe *__local_s).wrap = (((0 - (unsafe *__local_s).wrap) as c_int)))

    }

    var __ci_expr_ternary_0: c_int = 0

    if ((if (unsafe *__local_s).wrap == 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((57 as c_int)))
    } else {
        (__ci_expr_ternary_0 = ((42 as c_int)))
    }

    ((unsafe *__local_s).status = __ci_expr_ternary_0)


    var __ci_expr_ternary_1: c_ulong = 0

    if ((if (unsafe *__local_s).wrap == 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))
    } else {
        (__ci_expr_ternary_1 = ((adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))
    }

    ((unsafe *__param_strm).adler = __ci_expr_ternary_1)


    ((unsafe *__local_s).last_flush = ((-2 as c_int)))

    _tr_init(__local_s)

    return 0

}

unsafe fn deflate_stored(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_min_block: c_uint = with 0 as __ci_expr_seq_9 {
        var __ci_expr_ternary_0: c_ulong = 0
        if ((if (((unsafe *__param_s).pending_buf_size as c_ulong) -% (5 as c_ulong)) > (unsafe *__param_s).w_size: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((unsafe *__param_s).w_size as c_ulong)))
        } else {
            (__ci_expr_ternary_0 = (((((unsafe *__param_s).pending_buf_size as c_ulong) -% (5 as c_ulong)) as c_ulong)))
        }
        (__ci_expr_ternary_0 as c_uint)
    }

    var __local_last: c_int = ((0 as c_int))

    var __local_len: c_uint

    var __local_left: c_uint

    var __local_have: c_uint


    var __local_used: c_uint = (unsafe *__param_s).strm.avail_in

    loop {
        (__local_len = ((65535 as c_uint)))

        (__local_have = ((((((((unsafe *__param_s).bi_valid as c_uint) as c_uint) +% (42 as c_uint)) as c_uint) >> (3 as c_uint)) as c_uint)))

        if ((if (unsafe *__param_s).strm.avail_out < __local_have: 1 else: 0) != 0) {
            break
        }

        (__local_have = (((((unsafe *__param_s).strm.avail_out as c_uint) -% (__local_have as c_uint)) as c_uint)))

        (__local_left = ((((unsafe *__param_s).strstart - (unsafe *__param_s).block_start) as c_uint)))

        if ((if __local_len > (((__local_left as c_ulong) as c_ulong) +% ((unsafe *__param_s).strm.avail_in as c_ulong)): 1 else: 0) != 0) {
            (__local_len = ((((__local_left as c_uint) +% ((unsafe *__param_s).strm.avail_in as c_uint)) as c_uint)))
        }

        if ((if __local_len > __local_have: 1 else: 0) != 0) {
            (__local_len = __local_have)
        }

        var __ci_expr_logic_4: c_int = 0

        if ((if __local_len < __local_min_block: 1 else: 0) != 0) {
            var __ci_expr_logic_3: c_int

            var __ci_expr_logic_2: c_int

            var __ci_expr_logic_1: c_int = 0

            if ((if __local_len == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if __local_len != ((__local_left as c_uint) +% ((unsafe *__param_s).strm.avail_in as c_uint)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_4 != 0) {
            break
        }


        var __ci_expr_ternary_6: c_int = 0

        var __ci_expr_logic_5: c_int = 0

        if ((if __param_flush == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_len == ((__local_left as c_uint) +% ((unsafe *__param_s).strm.avail_in as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_ternary_6 = ((1 as c_int)))
        } else {
            (__ci_expr_ternary_6 = ((0 as c_int)))
        }

        (__local_last = __ci_expr_ternary_6)


        _tr_stored_block(__param_s, null, (0 as c_ulong), __local_last)

        ((unsafe (unsafe *__param_s).pending_buf[(((unsafe *__param_s).pending as c_ulong) -% (4 as c_ulong))]) = ((__local_len as u8)))

        ((unsafe (unsafe *__param_s).pending_buf[(((unsafe *__param_s).pending as c_ulong) -% (3 as c_ulong))]) = ((((__local_len as c_uint) >> (8 as c_uint)) as u8)))

        ((unsafe (unsafe *__param_s).pending_buf[(((unsafe *__param_s).pending as c_ulong) -% (2 as c_ulong))]) = (((~__local_len) as u8)))

        ((unsafe (unsafe *__param_s).pending_buf[(((unsafe *__param_s).pending as c_ulong) -% (1 as c_ulong))]) = (((((~__local_len) as c_uint) >> (8 as c_uint)) as u8)))

        flush_pending((unsafe *__param_s).strm)

        if (__local_left != 0) {
            if ((if __local_left > __local_len: 1 else: 0) != 0) {
                (__local_left = __local_len)
            }

            with_memcpy((((unsafe *__param_s).strm.next_out as *mut c_void) as *i8), ((((unsafe *__param_s).window + (((unsafe *__param_s).block_start as isize) as usize)) as *const c_void) as *i8), ((__local_left as c_ulong) as i64))

            ((unsafe *__param_s).strm.next_out = (unsafe *__param_s).strm.next_out + (__local_left as usize))

            ((unsafe *__param_s).strm.avail_out = ((unsafe *__param_s).strm.avail_out -% __local_left))

            ((unsafe *__param_s).strm.total_out = ((unsafe *__param_s).strm.total_out +% __local_left))

            ((unsafe *__param_s).block_start = (unsafe *__param_s).block_start + __local_left)

            (__local_len = (__local_len -% __local_left))

        }

        if (__local_len != 0) {
            read_buf((unsafe *__param_s).strm, (unsafe *__param_s).strm.next_out, __local_len)

            ((unsafe *__param_s).strm.next_out = (unsafe *__param_s).strm.next_out + (__local_len as usize))

            ((unsafe *__param_s).strm.avail_out = ((unsafe *__param_s).strm.avail_out -% __local_len))

            ((unsafe *__param_s).strm.total_out = ((unsafe *__param_s).strm.total_out +% __local_len))

        }

        if not (((if __local_last == 0: 1 else: 0) != 0)) {
            break
        }
    }

    (__local_used = (__local_used -% (unsafe *__param_s).strm.avail_in))

    if (__local_used != 0) {
        if ((if __local_used >= (unsafe *__param_s).w_size: 1 else: 0) != 0) {
            ((unsafe *__param_s).matches = ((2 as c_uint)))

            with_memcpy((((unsafe *__param_s).window as *mut c_void) as *i8), ((((unsafe *__param_s).strm.next_in - ((unsafe *__param_s).w_size as usize)) as *const c_void) as *i8), (((unsafe *__param_s).w_size as c_ulong) as i64))

            ((unsafe *__param_s).strstart = (unsafe *__param_s).w_size)

            ((unsafe *__param_s).insert = (unsafe *__param_s).strstart)

        } else {
            if ((if (((unsafe *__param_s).window_size as c_ulong) -% ((unsafe *__param_s).strstart as c_ulong)) <= __local_used: 1 else: 0) != 0) {
                ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart -% (unsafe *__param_s).w_size))

                with_memcpy((((unsafe *__param_s).window as *mut c_void) as *i8), ((((unsafe *__param_s).window + ((unsafe *__param_s).w_size as usize)) as *const c_void) as *i8), (((unsafe *__param_s).strstart as c_ulong) as i64))

                if ((if (unsafe *__param_s).matches < 2: 1 else: 0) != 0) {
                    ((unsafe *__param_s).matches = ((unsafe *__param_s).matches +% 1))
                }

                if ((if (unsafe *__param_s).insert > (unsafe *__param_s).strstart: 1 else: 0) != 0) {
                    ((unsafe *__param_s).insert = (unsafe *__param_s).strstart)
                }

            }

            with_memcpy(((((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize)) as *mut c_void) as *i8), ((((unsafe *__param_s).strm.next_in - (__local_used as usize)) as *const c_void) as *i8), ((__local_used as c_ulong) as i64))

            ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% __local_used))

            var __ci_expr_ternary_7: c_uint = 0

            if ((if __local_used > (((unsafe *__param_s).w_size as c_uint) -% ((unsafe *__param_s).insert as c_uint)): 1 else: 0) != 0) {
                (__ci_expr_ternary_7 = (((((unsafe *__param_s).w_size as c_uint) -% ((unsafe *__param_s).insert as c_uint)) as c_uint)))
            } else {
                (__ci_expr_ternary_7 = __local_used)
            }

            ((unsafe *__param_s).insert = ((unsafe *__param_s).insert +% __ci_expr_ternary_7))


        }

        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

    }

    if ((if (unsafe *__param_s).high_water < (unsafe *__param_s).strstart: 1 else: 0) != 0) {
        ((unsafe *__param_s).high_water = (((unsafe *__param_s).strstart as c_ulong)))
    }

    if (__local_last != 0) {
        ((unsafe *__param_s).bi_used = ((8 as c_int)))

        return 3

    }

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    if ((if __param_flush != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_8 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_8 != 0) {
        (__ci_expr_logic_9 = (if (if (unsafe *__param_s).strm.avail_in == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_9 != 0) {
        (__ci_expr_logic_10 = (if (if (((unsafe *__param_s).strstart as c_long)) == (unsafe *__param_s).block_start: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_10 != 0) {
        return 1
    }


    (__local_have = (((((unsafe *__param_s).window_size as c_ulong) -% ((unsafe *__param_s).strstart as c_ulong)) as c_uint)))

    var __ci_expr_logic_11: c_int = 0

    if ((if (unsafe *__param_s).strm.avail_in > __local_have: 1 else: 0) != 0) {
        (__ci_expr_logic_11 = (if (if (unsafe *__param_s).block_start >= (((unsafe *__param_s).w_size as c_long)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_11 != 0) {
        ((unsafe *__param_s).block_start = (unsafe *__param_s).block_start - (unsafe *__param_s).w_size)

        ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart -% (unsafe *__param_s).w_size))

        with_memcpy((((unsafe *__param_s).window as *mut c_void) as *i8), ((((unsafe *__param_s).window + ((unsafe *__param_s).w_size as usize)) as *const c_void) as *i8), (((unsafe *__param_s).strstart as c_ulong) as i64))

        if ((if (unsafe *__param_s).matches < 2: 1 else: 0) != 0) {
            ((unsafe *__param_s).matches = ((unsafe *__param_s).matches +% 1))
        }

        (__local_have = (__local_have +% (unsafe *__param_s).w_size))

        if ((if (unsafe *__param_s).insert > (unsafe *__param_s).strstart: 1 else: 0) != 0) {
            ((unsafe *__param_s).insert = (unsafe *__param_s).strstart)
        }

    }


    if ((if __local_have > (unsafe *__param_s).strm.avail_in: 1 else: 0) != 0) {
        (__local_have = (unsafe *__param_s).strm.avail_in)
    }

    if (__local_have != 0) {
        read_buf((unsafe *__param_s).strm, ((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize)), __local_have)

        ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% __local_have))

        var __ci_expr_ternary_12: c_uint = 0

        if ((if __local_have > (((unsafe *__param_s).w_size as c_uint) -% ((unsafe *__param_s).insert as c_uint)): 1 else: 0) != 0) {
            (__ci_expr_ternary_12 = (((((unsafe *__param_s).w_size as c_uint) -% ((unsafe *__param_s).insert as c_uint)) as c_uint)))
        } else {
            (__ci_expr_ternary_12 = __local_have)
        }

        ((unsafe *__param_s).insert = ((unsafe *__param_s).insert +% __ci_expr_ternary_12))


    }

    if ((if (unsafe *__param_s).high_water < (unsafe *__param_s).strstart: 1 else: 0) != 0) {
        ((unsafe *__param_s).high_water = (((unsafe *__param_s).strstart as c_ulong)))
    }

    (__local_have = ((((((((unsafe *__param_s).bi_valid as c_uint) as c_uint) +% (42 as c_uint)) as c_uint) >> (3 as c_uint)) as c_uint)))

    var __ci_expr_ternary_13: c_ulong = 0

    if ((if (((unsafe *__param_s).pending_buf_size as c_ulong) -% (__local_have as c_ulong)) > 65535: 1 else: 0) != 0) {
        (__ci_expr_ternary_13 = ((65535 as c_ulong)))
    } else {
        (__ci_expr_ternary_13 = (((((unsafe *__param_s).pending_buf_size as c_ulong) -% (__local_have as c_ulong)) as c_ulong)))
    }

    (__local_have = ((__ci_expr_ternary_13 as c_uint)))


    var __ci_expr_ternary_14: c_uint = 0

    if ((if __local_have > (unsafe *__param_s).w_size: 1 else: 0) != 0) {
        (__ci_expr_ternary_14 = (unsafe *__param_s).w_size)
    } else {
        (__ci_expr_ternary_14 = __local_have)
    }

    (__local_min_block = __ci_expr_ternary_14)


    (__local_left = ((((unsafe *__param_s).strstart - (unsafe *__param_s).block_start) as c_uint)))

    var __ci_expr_logic_19: c_int

    if ((if __local_left >= __local_min_block: 1 else: 0) != 0) {
        (__ci_expr_logic_19 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_18: c_int = 0

        var __ci_expr_logic_17: c_int = 0

        var __ci_expr_logic_16: c_int = 0

        var __ci_expr_logic_15: c_int

        if (__local_left != 0) {
            (__ci_expr_logic_15 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_15 = (if (if __param_flush == 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_logic_16 = (if (if __param_flush != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_16 != 0) {
            (__ci_expr_logic_17 = (if (if (unsafe *__param_s).strm.avail_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_17 != 0) {
            (__ci_expr_logic_18 = (if (if __local_left <= __local_have: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_19 = (if __ci_expr_logic_18 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_19 != 0) {
        var __ci_expr_ternary_20: c_uint = 0

        if ((if __local_left > __local_have: 1 else: 0) != 0) {
            (__ci_expr_ternary_20 = __local_have)
        } else {
            (__ci_expr_ternary_20 = __local_left)
        }

        (__local_len = __ci_expr_ternary_20)


        var __ci_expr_ternary_23: c_int = 0

        var __ci_expr_logic_22: c_int = 0

        var __ci_expr_logic_21: c_int = 0

        if ((if __param_flush == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if (if (unsafe *__param_s).strm.avail_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_logic_22 = (if (if __local_len == __local_left: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_ternary_23 = ((1 as c_int)))
        } else {
            (__ci_expr_ternary_23 = ((0 as c_int)))
        }

        (__local_last = __ci_expr_ternary_23)


        _tr_stored_block(__param_s, (((unsafe *__param_s).window as *mut c_char) + (((unsafe *__param_s).block_start as isize) as usize)), (__local_len as c_ulong), __local_last)

        ((unsafe *__param_s).block_start = (unsafe *__param_s).block_start + __local_len)

        flush_pending((unsafe *__param_s).strm)

    }


    if (__local_last != 0) {
        ((unsafe *__param_s).bi_used = ((8 as c_int)))
    }

    var __ci_expr_ternary_24: c_int = 0

    if (__local_last != 0) {
        (__ci_expr_ternary_24 = finish_started)
    } else {
        (__ci_expr_ternary_24 = need_more)
    }

    return __ci_expr_ternary_24


}

unsafe fn deflate_fast(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_hash_head: c_uint

    var __local_bflush: c_int

    while true {
        if ((if (unsafe *__param_s).lookahead < 262: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: c_int = 0

            if ((if (unsafe *__param_s).lookahead < 262: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                return 0

            }


            if ((if (unsafe *__param_s).lookahead == 0: 1 else: 0) != 0) {
                break
            }

        }

        (__local_hash_head = ((0 as c_uint)))

        if ((if (unsafe *__param_s).lookahead >= 3: 1 else: 0) != 0) {
            ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

            ((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) = (((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) as c_ushort)))

            (__local_hash_head = (((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) as c_uint)))

            ((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) = (((unsafe *__param_s).strstart as c_ushort)))


        }

        var __ci_expr_logic_1: c_int = 0

        if ((if __local_hash_head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (((unsafe *__param_s).strstart as c_uint) -% (__local_hash_head as c_uint)) <= (((unsafe *__param_s).w_size as c_uint) -% (262 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            ((unsafe *__param_s).match_length = ((longest_match(__param_s, __local_hash_head) as c_uint)))

        }


        if ((if (unsafe *__param_s).match_length >= 3: 1 else: 0) != 0) {
            var __local_len: u8 = (((((unsafe *__param_s).match_length as c_uint) -% (3 as c_uint)) as u8))

            var __local_dist: c_ushort = (((((unsafe *__param_s).strstart as c_uint) -% ((unsafe *__param_s).match_start as c_uint)) as c_ushort))

            var __ci_expr_old_2: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_2]) = ((__local_dist as u8)))


            var __ci_expr_old_3: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_3]) = ((((__local_dist as c_int) >> (8 as c_uint)) as u8)))


            var __ci_expr_old_4: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_4]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((unsafe *__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq = ((unsafe *__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq +% 1))

            var __ci_expr_ternary_5: c_int = 0

            if ((if __local_dist < 256: 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = ((_dist_code[__local_dist] as c_int)))
            } else {
                (__ci_expr_ternary_5 = ((_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int)))
            }

            ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_5].fc.freq = ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_5].fc.freq +% 1))


            (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


            ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% (unsafe *__param_s).match_length))

            var __ci_expr_logic_6: c_int = 0

            if ((if (unsafe *__param_s).match_length <= (unsafe *__param_s).max_lazy_match: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if (if (unsafe *__param_s).lookahead >= 3: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                ((unsafe *__param_s).match_length = ((unsafe *__param_s).match_length -% 1))

                loop {
                    ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

                    ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

                    ((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) = (((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) as c_ushort)))

                    (__local_hash_head = (((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) as c_uint)))

                    ((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) = (((unsafe *__param_s).strstart as c_ushort)))


                    ((unsafe *__param_s).match_length = ((unsafe *__param_s).match_length -% 1))
                    if not (((if (unsafe *__param_s).match_length != 0: 1 else: 0) != 0)) {
                        break
                    }
                }

                ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

            } else {
                ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% (unsafe *__param_s).match_length))

                ((unsafe *__param_s).match_length = ((0 as c_uint)))

                ((unsafe *__param_s).ins_h = (((unsafe (unsafe *__param_s).window[(unsafe *__param_s).strstart]) as c_uint)))

                ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) +% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

            }


        } else {
            var __local_cc: u8 = (((unsafe (unsafe *__param_s).window[(unsafe *__param_s).strstart]) as u8))

            var __ci_expr_old_7: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_7]) = ((0 as u8)))


            var __ci_expr_old_8: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_8]) = ((0 as u8)))


            var __ci_expr_old_9: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_9]) = __local_cc)


            ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq = ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

            (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


            ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% 1))

            ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

        }

        if (__local_bflush != 0) {
            var __ci_expr_ternary_10: *mut c_char = null

            if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_10 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
            } else {
                (__ci_expr_ternary_10 = ((null as *mut c_char)))
            }

            _tr_flush_block(__param_s, __ci_expr_ternary_10, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


            ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

            flush_pending((unsafe *__param_s).strm)


            if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }

    }

    var __ci_expr_ternary_11: c_uint = 0

    if ((if (unsafe *__param_s).strstart < 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_11 = (unsafe *__param_s).strstart)
    } else {
        (__ci_expr_ternary_11 = ((2 as c_uint)))
    }

    ((unsafe *__param_s).insert = __ci_expr_ternary_11)


    if ((if __param_flush == 4: 1 else: 0) != 0) {
        var __ci_expr_ternary_12: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_12 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_12 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_12, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (1 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }


        return 3

    }

    if ((unsafe *__param_s).sym_next != 0) {
        var __ci_expr_ternary_13: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_13 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_13 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_13, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }

    return 1

}

unsafe fn deflate_slow(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_hash_head: c_uint

    var __local_bflush: c_int

    while true {
        if ((if (unsafe *__param_s).lookahead < 262: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: c_int = 0

            if ((if (unsafe *__param_s).lookahead < 262: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                return 0

            }


            if ((if (unsafe *__param_s).lookahead == 0: 1 else: 0) != 0) {
                break
            }

        }

        (__local_hash_head = ((0 as c_uint)))

        if ((if (unsafe *__param_s).lookahead >= 3: 1 else: 0) != 0) {
            ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

            ((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) = (((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) as c_ushort)))

            (__local_hash_head = (((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) as c_uint)))

            ((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) = (((unsafe *__param_s).strstart as c_ushort)))


        }

        ((unsafe *__param_s).prev_length = (unsafe *__param_s).match_length)

        ((unsafe *__param_s).prev_match = (unsafe *__param_s).match_start)


        ((unsafe *__param_s).match_length = ((2 as c_uint)))

        var __ci_expr_logic_2: c_int = 0

        var __ci_expr_logic_1: c_int = 0

        if ((if __local_hash_head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe *__param_s).prev_length < (unsafe *__param_s).max_lazy_match: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if (if (((unsafe *__param_s).strstart as c_uint) -% (__local_hash_head as c_uint)) <= (((unsafe *__param_s).w_size as c_uint) -% (262 as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            ((unsafe *__param_s).match_length = ((longest_match(__param_s, __local_hash_head) as c_uint)))

            var __ci_expr_logic_5: c_int = 0

            if ((if (unsafe *__param_s).match_length <= 5: 1 else: 0) != 0) {
                var __ci_expr_logic_4: c_int

                if ((if (unsafe *__param_s).strategy == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if (unsafe *__param_s).match_length == 3: 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if (if (((unsafe *__param_s).strstart as c_uint) -% ((unsafe *__param_s).match_start as c_uint)) > 4096: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

                }

                (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_5 != 0) {
                ((unsafe *__param_s).match_length = ((2 as c_uint)))

            }


        }


        var __ci_expr_logic_6: c_int = 0

        if ((if (unsafe *__param_s).prev_length >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe *__param_s).match_length <= (unsafe *__param_s).prev_length: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            var __local_max_insert: c_uint = (((((((unsafe *__param_s).strstart as c_uint) +% ((unsafe *__param_s).lookahead as c_uint)) as c_uint) -% (3 as c_uint)) as c_uint))

            var __local_len: u8 = (((((unsafe *__param_s).prev_length as c_uint) -% (3 as c_uint)) as u8))

            var __local_dist: c_ushort = (((((((unsafe *__param_s).strstart as c_uint) -% (1 as c_uint)) as c_uint) -% ((unsafe *__param_s).prev_match as c_uint)) as c_ushort))

            var __ci_expr_old_7: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_7]) = ((__local_dist as u8)))


            var __ci_expr_old_8: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_8]) = ((((__local_dist as c_int) >> (8 as c_uint)) as u8)))


            var __ci_expr_old_9: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_9]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((unsafe *__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq = ((unsafe *__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq +% 1))

            var __ci_expr_ternary_10: c_int = 0

            if ((if __local_dist < 256: 1 else: 0) != 0) {
                (__ci_expr_ternary_10 = ((_dist_code[__local_dist] as c_int)))
            } else {
                (__ci_expr_ternary_10 = ((_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int)))
            }

            ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_10].fc.freq = ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_10].fc.freq +% 1))


            (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


            ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% (((unsafe *__param_s).prev_length as c_uint) -% (1 as c_uint))))

            ((unsafe *__param_s).prev_length = ((unsafe *__param_s).prev_length -% 2))

            loop {
                ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

                if ((if (unsafe *__param_s).strstart <= __local_max_insert: 1 else: 0) != 0) {
                    ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) +% (2 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

                    ((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) = (((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) as c_ushort)))

                    (__local_hash_head = (((unsafe (unsafe *__param_s).prev[(((unsafe *__param_s).strstart as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) as c_uint)))

                    ((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) = (((unsafe *__param_s).strstart as c_ushort)))


                }


                ((unsafe *__param_s).prev_length = ((unsafe *__param_s).prev_length -% 1))
                if not (((if (unsafe *__param_s).prev_length != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            ((unsafe *__param_s).match_available = ((0 as c_int)))

            ((unsafe *__param_s).match_length = ((2 as c_uint)))

            ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

            if (__local_bflush != 0) {
                var __ci_expr_ternary_11: *mut c_char = null

                if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_11 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
                } else {
                    (__ci_expr_ternary_11 = ((null as *mut c_char)))
                }

                _tr_flush_block(__param_s, __ci_expr_ternary_11, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


                ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

                flush_pending((unsafe *__param_s).strm)


                if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                    return 0
                }

            }

        } else {
            if ((unsafe *__param_s).match_available != 0) {
                var __local_cc: u8 = (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) -% (1 as c_uint))]) as u8))

                var __ci_expr_old_12: c_uint = (unsafe *__param_s).sym_next

                ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

                ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_12]) = ((0 as u8)))


                var __ci_expr_old_13: c_uint = (unsafe *__param_s).sym_next

                ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

                ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_13]) = ((0 as u8)))


                var __ci_expr_old_14: c_uint = (unsafe *__param_s).sym_next

                ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

                ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_14]) = __local_cc)


                ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq = ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

                (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


                if (__local_bflush != 0) {
                    var __ci_expr_ternary_15: *mut c_char = null

                    if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_15 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
                    } else {
                        (__ci_expr_ternary_15 = ((null as *mut c_char)))
                    }

                    _tr_flush_block(__param_s, __ci_expr_ternary_15, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


                    ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

                    flush_pending((unsafe *__param_s).strm)


                }

                ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

                ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% 1))

                if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                    return 0
                }

            } else {
                ((unsafe *__param_s).match_available = ((1 as c_int)))

                ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

                ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% 1))

            }
        }


    }

    if ((unsafe *__param_s).match_available != 0) {
        var __local_cc_1: u8 = (((unsafe (unsafe *__param_s).window[(((unsafe *__param_s).strstart as c_uint) -% (1 as c_uint))]) as u8))

        var __ci_expr_old_16: c_uint = (unsafe *__param_s).sym_next

        ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

        ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_16]) = ((0 as u8)))


        var __ci_expr_old_17: c_uint = (unsafe *__param_s).sym_next

        ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

        ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_17]) = ((0 as u8)))


        var __ci_expr_old_18: c_uint = (unsafe *__param_s).sym_next

        ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

        ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_18]) = __local_cc_1)


        ((unsafe *__param_s).dyn_ltree[__local_cc_1].fc.freq = ((unsafe *__param_s).dyn_ltree[__local_cc_1].fc.freq +% 1))

        (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


        ((unsafe *__param_s).match_available = ((0 as c_int)))

    }

    var __ci_expr_ternary_19: c_uint = 0

    if ((if (unsafe *__param_s).strstart < 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_19 = (unsafe *__param_s).strstart)
    } else {
        (__ci_expr_ternary_19 = ((2 as c_uint)))
    }

    ((unsafe *__param_s).insert = __ci_expr_ternary_19)


    if ((if __param_flush == 4: 1 else: 0) != 0) {
        var __ci_expr_ternary_20: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_20 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_20 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_20, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (1 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }


        return 3

    }

    if ((unsafe *__param_s).sym_next != 0) {
        var __ci_expr_ternary_21: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_21 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_21 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_21, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
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
        if ((if (unsafe *__param_s).lookahead <= 258: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: c_int = 0

            if ((if (unsafe *__param_s).lookahead <= 258: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __param_flush == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                return 0

            }


            if ((if (unsafe *__param_s).lookahead == 0: 1 else: 0) != 0) {
                break
            }

        }

        ((unsafe *__param_s).match_length = ((0 as c_uint)))

        var __ci_expr_logic_1: c_int = 0

        if ((if (unsafe *__param_s).lookahead >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe *__param_s).strstart > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_scan = ((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize)) - ((1 as isize) as usize))

            (__local_prev = (((unsafe *__local_scan) as c_uint)))

            var __ci_expr_logic_3: c_int = 0

            var __ci_expr_logic_2: c_int = 0

            (__local_scan = __local_scan + 1)

            if ((if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0) {
                (__local_scan = __local_scan + 1)

                (__ci_expr_logic_2 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_2 != 0) {
                (__local_scan = __local_scan + 1)

                (__ci_expr_logic_3 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_3 != 0) {
                (__local_strend = ((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize)) + ((258 as isize) as usize))

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

                    if ((if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_4 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_4 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_5 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_5 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_6 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_6 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_7 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_7 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_8 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_8 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_9 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_9 != 0) {
                        (__local_scan = __local_scan + 1)

                        (__ci_expr_logic_10 = (if (if __local_prev == (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_10 != 0) {
                        (__ci_expr_logic_11 = (if (if __local_scan < __local_strend: 1 else: 0) != 0: 1 else: 0))
                    }

                    if not ((__ci_expr_logic_11 != 0)) {
                        break
                    }
                }

                ((unsafe *__param_s).match_length = ((((258 as c_uint) -% (((((__local_strend as usize) -% (__local_scan as usize)) / sizeof[u8]()) as c_uint) as c_uint)) as c_uint)))

                if ((if (unsafe *__param_s).match_length > (unsafe *__param_s).lookahead: 1 else: 0) != 0) {
                    ((unsafe *__param_s).match_length = (unsafe *__param_s).lookahead)
                }

            }


        }


        if ((if (unsafe *__param_s).match_length >= 3: 1 else: 0) != 0) {
            var __local_len: u8 = (((((unsafe *__param_s).match_length as c_uint) -% (3 as c_uint)) as u8))

            var __local_dist: c_ushort = ((1 as c_ushort))

            var __ci_expr_old_12: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_12]) = ((__local_dist as u8)))


            var __ci_expr_old_13: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_13]) = ((((__local_dist as c_int) >> (8 as c_uint)) as u8)))


            var __ci_expr_old_14: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_14]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((unsafe *__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq = ((unsafe *__param_s).dyn_ltree[(((_length_code[__local_len] as c_int) + 256) + 1)].fc.freq +% 1))

            var __ci_expr_ternary_15: c_int = 0

            if ((if __local_dist < 256: 1 else: 0) != 0) {
                (__ci_expr_ternary_15 = ((_dist_code[__local_dist] as c_int)))
            } else {
                (__ci_expr_ternary_15 = ((_dist_code[(256 + ((__local_dist as c_int) >> (7 as c_uint)))] as c_int)))
            }

            ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_15].fc.freq = ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_15].fc.freq +% 1))


            (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


            ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% (unsafe *__param_s).match_length))

            ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% (unsafe *__param_s).match_length))

            ((unsafe *__param_s).match_length = ((0 as c_uint)))

        } else {
            var __local_cc: u8 = (((unsafe (unsafe *__param_s).window[(unsafe *__param_s).strstart]) as u8))

            var __ci_expr_old_16: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_16]) = ((0 as u8)))


            var __ci_expr_old_17: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_17]) = ((0 as u8)))


            var __ci_expr_old_18: c_uint = (unsafe *__param_s).sym_next

            ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

            ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_18]) = __local_cc)


            ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq = ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

            (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


            ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% 1))

            ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

        }

        if (__local_bflush != 0) {
            var __ci_expr_ternary_19: *mut c_char = null

            if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_19 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
            } else {
                (__ci_expr_ternary_19 = ((null as *mut c_char)))
            }

            _tr_flush_block(__param_s, __ci_expr_ternary_19, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


            ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

            flush_pending((unsafe *__param_s).strm)


            if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }

    }

    ((unsafe *__param_s).insert = ((0 as c_uint)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        var __ci_expr_ternary_20: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_20 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_20 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_20, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (1 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }


        return 3

    }

    if ((unsafe *__param_s).sym_next != 0) {
        var __ci_expr_ternary_21: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_21 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_21 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_21, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }

    return 1

}

unsafe fn deflate_huff(__param_s: *mut internal_state, __param_flush: c_int) -> i32 {
    var __local_bflush: c_int

    while true {
        if ((if (unsafe *__param_s).lookahead == 0: 1 else: 0) != 0) {
            fill_window(__param_s)

            if ((if (unsafe *__param_s).lookahead == 0: 1 else: 0) != 0) {
                if ((if __param_flush == 0: 1 else: 0) != 0) {
                    return 0
                }

                break

            }

        }

        ((unsafe *__param_s).match_length = ((0 as c_uint)))

        var __local_cc: u8 = (((unsafe (unsafe *__param_s).window[(unsafe *__param_s).strstart]) as u8))

        var __ci_expr_old_0: c_uint = (unsafe *__param_s).sym_next

        ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

        ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_0]) = ((0 as u8)))


        var __ci_expr_old_1: c_uint = (unsafe *__param_s).sym_next

        ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

        ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_1]) = ((0 as u8)))


        var __ci_expr_old_2: c_uint = (unsafe *__param_s).sym_next

        ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

        ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_2]) = __local_cc)


        ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq = ((unsafe *__param_s).dyn_ltree[__local_cc].fc.freq +% 1))

        (__local_bflush = (((if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0) as c_int)))


        ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead -% 1))

        ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart +% 1))

        if (__local_bflush != 0) {
            var __ci_expr_ternary_3: *mut c_char = null

            if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_3 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
            } else {
                (__ci_expr_ternary_3 = ((null as *mut c_char)))
            }

            _tr_flush_block(__param_s, __ci_expr_ternary_3, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


            ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

            flush_pending((unsafe *__param_s).strm)


            if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }

    }

    ((unsafe *__param_s).insert = ((0 as c_uint)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        var __ci_expr_ternary_4: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_4 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_4 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_4, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (1 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 2
        }


        return 3

    }

    if ((unsafe *__param_s).sym_next != 0) {
        var __ci_expr_ternary_5: *mut c_char = null

        if ((if (unsafe *__param_s).block_start >= 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = ((((&raw const (unsafe (unsafe *__param_s).window[((unsafe *__param_s).block_start as c_uint)]) as *const u8) as *mut u8) as *mut c_char)))
        } else {
            (__ci_expr_ternary_5 = ((null as *mut c_char)))
        }

        _tr_flush_block(__param_s, __ci_expr_ternary_5, ((((unsafe *__param_s).strstart as c_long) - (unsafe *__param_s).block_start) as c_ulong), (0 as c_int))


        ((unsafe *__param_s).block_start = (((unsafe *__param_s).strstart as c_long)))

        flush_pending((unsafe *__param_s).strm)


        if ((if (unsafe *__param_s).strm.avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }

    return 1

}

unsafe fn slide_hash(__param_s: *mut internal_state) -> Unit {
    var __local_n: c_uint

    var __local_m: c_uint


    var __local_p: *mut c_ushort

    var __local_wsize: c_uint = (unsafe *__param_s).w_size

    (__local_n = (unsafe *__param_s).hash_size)

    (__local_p = (((&raw const (unsafe (unsafe *__param_s).head[__local_n]) as *const c_ushort) as *mut c_ushort)))

    loop {
        (__local_p = __local_p - 1)

        (__local_m = (((unsafe *__local_p) as c_uint)))


        var __ci_expr_ternary_0: c_uint = 0

        if ((if __local_m >= __local_wsize: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((((__local_m as c_uint) -% (__local_wsize as c_uint)) as c_uint)))
        } else {
            (__ci_expr_ternary_0 = ((0 as c_uint)))
        }

        ((unsafe *__local_p) = ((__ci_expr_ternary_0 as c_ushort)))


        (__local_n = (__local_n -% 1))
        if not ((__local_n != 0)) {
            break
        }
    }

    (__local_n = __local_wsize)

    (__local_p = (((&raw const (unsafe (unsafe *__param_s).prev[__local_n]) as *const c_ushort) as *mut c_ushort)))

    loop {
        (__local_p = __local_p - 1)

        (__local_m = (((unsafe *__local_p) as c_uint)))


        var __ci_expr_ternary_1: c_uint = 0

        if ((if __local_m >= __local_wsize: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = ((((__local_m as c_uint) -% (__local_wsize as c_uint)) as c_uint)))
        } else {
            (__ci_expr_ternary_1 = ((0 as c_uint)))
        }

        ((unsafe *__local_p) = ((__ci_expr_ternary_1 as c_ushort)))


        (__local_n = (__local_n -% 1))
        if not ((__local_n != 0)) {
            break
        }
    }

    ((unsafe *__param_s).slid = ((1 as c_int)))

}

unsafe fn read_buf(__param_strm: *mut z_stream_s, __param_buf: *mut u8, __param_size: c_uint) -> c_uint {
    var __local_len: c_uint = (unsafe *__param_strm).avail_in

    if ((if __local_len > __param_size: 1 else: 0) != 0) {
        (__local_len = __param_size)
    }

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return 0
    }

    ((unsafe *__param_strm).avail_in = ((unsafe *__param_strm).avail_in -% __local_len))

    with_memcpy(((__param_buf as *mut c_void) as *i8), (((unsafe *__param_strm).next_in as *const c_void) as *i8), ((__local_len as c_ulong) as i64))

    if ((if (unsafe *(unsafe *__param_strm).state).wrap == 1: 1 else: 0) != 0) {
        ((unsafe *__param_strm).adler = ((adler32((unsafe *__param_strm).adler, (__param_buf as *const u8), __local_len) as c_ulong)))

    } else {
        if ((if (unsafe *(unsafe *__param_strm).state).wrap == 2: 1 else: 0) != 0) {
            ((unsafe *__param_strm).adler = ((crc32((unsafe *__param_strm).adler, (__param_buf as *const u8), __local_len) as c_ulong)))

        }
    }

    ((unsafe *__param_strm).next_in = (unsafe *__param_strm).next_in + (__local_len as usize))

    ((unsafe *__param_strm).total_in = ((unsafe *__param_strm).total_in +% __local_len))

    return __local_len

}

unsafe fn fill_window(__param_s: *mut internal_state) -> Unit {
    var __local_n: c_uint

    var __local_more: c_uint

    var __local_wsize: c_uint = (unsafe *__param_s).w_size

    loop {
        (__local_more = (((((((unsafe *__param_s).window_size as c_ulong) -% (((unsafe *__param_s).lookahead as c_ulong) as c_ulong)) as c_ulong) -% (((unsafe *__param_s).strstart as c_ulong) as c_ulong)) as c_uint)))

        if ((if sizeof[c_int]() <= 2: 1 else: 0) != 0) {
            var __ci_expr_logic_2: c_int = 0

            var __ci_expr_logic_1: c_int = 0

            if ((if __local_more == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if (unsafe *__param_s).strstart == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_2 = (if (if (unsafe *__param_s).lookahead == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__local_more = __local_wsize)

            } else {
                if ((if __local_more == ((-1 as c_uint)): 1 else: 0) != 0) {
                    (__local_more = (__local_more -% 1))

                }
            }


        }

        if ((if (unsafe *__param_s).strstart >= ((__local_wsize as c_uint) +% ((((unsafe *__param_s).w_size as c_uint) -% (262 as c_uint)) as c_uint)): 1 else: 0) != 0) {
            with_memcpy((((unsafe *__param_s).window as *mut c_void) as *i8), ((((unsafe *__param_s).window + (__local_wsize as usize)) as *const c_void) as *i8), ((((__local_wsize as c_uint) -% (__local_more as c_uint)) as c_ulong) as i64))

            ((unsafe *__param_s).match_start = ((unsafe *__param_s).match_start -% __local_wsize))

            ((unsafe *__param_s).strstart = ((unsafe *__param_s).strstart -% __local_wsize))

            ((unsafe *__param_s).block_start = (unsafe *__param_s).block_start - (__local_wsize as c_long))

            if ((if (unsafe *__param_s).insert > (unsafe *__param_s).strstart: 1 else: 0) != 0) {
                ((unsafe *__param_s).insert = (unsafe *__param_s).strstart)
            }

            slide_hash(__param_s)

            (__local_more = (__local_more +% __local_wsize))

        }

        if ((if (unsafe *__param_s).strm.avail_in == 0: 1 else: 0) != 0) {
            break
        }

        (__local_n = ((read_buf((unsafe *__param_s).strm, (((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize)) + ((unsafe *__param_s).lookahead as usize)), __local_more) as c_uint)))

        ((unsafe *__param_s).lookahead = ((unsafe *__param_s).lookahead +% __local_n))

        if ((if (((unsafe *__param_s).lookahead as c_uint) +% ((unsafe *__param_s).insert as c_uint)) >= 3: 1 else: 0) != 0) {
            var __local_str: c_uint = (((((unsafe *__param_s).strstart as c_uint) -% ((unsafe *__param_s).insert as c_uint)) as c_uint))

            ((unsafe *__param_s).ins_h = (((unsafe (unsafe *__param_s).window[__local_str]) as c_uint)))

            ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[((__local_str as c_uint) +% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

            while ((unsafe *__param_s).insert != 0) {
                ((unsafe *__param_s).ins_h = (((((((((unsafe *__param_s).ins_h as c_uint) << ((unsafe *__param_s).hash_shift as c_uint)) as c_uint) ^ (((unsafe (unsafe *__param_s).window[((((__local_str as c_uint) +% (3 as c_uint)) as c_uint) -% (1 as c_uint))]) as c_int) as c_uint)) as c_uint) & ((unsafe *__param_s).hash_mask as c_uint)) as c_uint)))

                ((unsafe (unsafe *__param_s).prev[((__local_str as c_uint) & ((unsafe *__param_s).w_mask as c_uint))]) = (((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) as c_ushort)))

                ((unsafe (unsafe *__param_s).head[(unsafe *__param_s).ins_h]) = ((__local_str as c_ushort)))

                (__local_str = (__local_str +% 1))

                ((unsafe *__param_s).insert = ((unsafe *__param_s).insert -% 1))

                if ((if (((unsafe *__param_s).lookahead as c_uint) +% ((unsafe *__param_s).insert as c_uint)) < 3: 1 else: 0) != 0) {
                    break
                }

            }

        }

        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *__param_s).lookahead < 262: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *__param_s).strm.avail_in != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    if ((if (unsafe *__param_s).high_water < (unsafe *__param_s).window_size: 1 else: 0) != 0) {
        var __local_curr: c_ulong = (((((unsafe *__param_s).strstart as c_ulong) +% (((unsafe *__param_s).lookahead as c_ulong) as c_ulong)) as c_ulong))

        var __local_init: c_ulong

        if ((if (unsafe *__param_s).high_water < __local_curr: 1 else: 0) != 0) {
            (__local_init = (((((unsafe *__param_s).window_size as c_ulong) -% (__local_curr as c_ulong)) as c_ulong)))

            if ((if __local_init > 258: 1 else: 0) != 0) {
                (__local_init = ((258 as c_ulong)))
            }

            with_memset(((((unsafe *__param_s).window + (__local_curr as usize)) as *mut c_void) as *i8), (0 as c_int), ((__local_init as c_uint) as i64))

            ((unsafe *__param_s).high_water = ((((__local_curr as c_ulong) +% (__local_init as c_ulong)) as c_ulong)))

        } else {
            if ((if (unsafe *__param_s).high_water < ((__local_curr as c_ulong) +% (258 as c_ulong)): 1 else: 0) != 0) {
                (__local_init = ((((((__local_curr as c_ulong) +% (258 as c_ulong)) as c_ulong) -% ((unsafe *__param_s).high_water as c_ulong)) as c_ulong)))

                if ((if __local_init > (((unsafe *__param_s).window_size as c_ulong) -% ((unsafe *__param_s).high_water as c_ulong)): 1 else: 0) != 0) {
                    (__local_init = (((((unsafe *__param_s).window_size as c_ulong) -% ((unsafe *__param_s).high_water as c_ulong)) as c_ulong)))
                }

                with_memset(((((unsafe *__param_s).window + ((unsafe *__param_s).high_water as usize)) as *mut c_void) as *i8), (0 as c_int), ((__local_init as c_uint) as i64))

                ((unsafe *__param_s).high_water = ((unsafe *__param_s).high_water +% __local_init))

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
        (__ci_expr_logic_0 = (if (if (unsafe *__param_strm).zalloc == ((0 as unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__param_strm).zfree == ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return 1
    }


    (__local_s = (unsafe *__param_strm).state)

    var __ci_expr_logic_10: c_int

    var __ci_expr_logic_2: c_int

    if ((if __local_s == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (unsafe *__local_s).strm != __param_strm: 1 else: 0) != 0: 1 else: 0))
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

        if ((if (unsafe *__local_s).status != 42: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if (unsafe *__local_s).status != 57: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if (if (unsafe *__local_s).status != 69: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if (unsafe *__local_s).status != 73: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if (unsafe *__local_s).status != 91: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_logic_7 = (if (if (unsafe *__local_s).status != 103: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_logic_8 = (if (if (unsafe *__local_s).status != 113: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_logic_9 = (if (if (unsafe *__local_s).status != 666: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_10 != 0) {
        return 1
    }


    return 0

}

unsafe fn lm_init(__param_s: *mut internal_state) -> Unit {
    ((unsafe *__param_s).window_size = (((((2 as c_ulong) as c_ulong) *% ((unsafe *__param_s).w_size as c_ulong)) as c_ulong)))

    loop {
        ((unsafe (unsafe *__param_s).head[(((unsafe *__param_s).hash_size as c_uint) -% (1 as c_uint))]) = ((0 as c_ushort)))

        with_memset((((unsafe *__param_s).head as *mut c_void) as *i8), (0 as c_int), (((((((unsafe *__param_s).hash_size as c_uint) -% (1 as c_uint)) as c_ulong) *% (sizeof[c_ushort]() as c_ulong)) as c_ulong) as i64))

        ((unsafe *__param_s).slid = ((0 as c_int)))

        if not ((0 != 0)) {
            break
        }
    }

    ((unsafe *__param_s).max_lazy_match = ((configuration_table[(unsafe *__param_s).level].max_lazy as c_uint)))

    ((unsafe *__param_s).good_match = ((configuration_table[(unsafe *__param_s).level].good_length as c_uint)))

    ((unsafe *__param_s).nice_match = ((configuration_table[(unsafe *__param_s).level].nice_length as c_int)))

    ((unsafe *__param_s).max_chain_length = ((configuration_table[(unsafe *__param_s).level].max_chain as c_uint)))

    ((unsafe *__param_s).strstart = ((0 as c_uint)))

    ((unsafe *__param_s).block_start = ((0 as c_long)))

    ((unsafe *__param_s).lookahead = ((0 as c_uint)))

    ((unsafe *__param_s).insert = ((0 as c_uint)))

    ((unsafe *__param_s).prev_length = ((2 as c_uint)))

    ((unsafe *__param_s).match_length = (unsafe *__param_s).prev_length)


    ((unsafe *__param_s).match_available = ((0 as c_int)))

    ((unsafe *__param_s).ins_h = ((0 as c_uint)))

}

unsafe fn putShortMSB(__param_s: *mut internal_state, __param_b: c_uint) -> Unit {
    var __ci_expr_old_0: c_ulong = (unsafe *__param_s).pending

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_0]) = ((((__param_b as c_uint) >> (8 as c_uint)) as u8)))



    var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = ((((__param_b as c_uint) & (255 as c_uint)) as u8)))



}

unsafe fn flush_pending(__param_strm: *mut z_stream_s) -> Unit {
    var __local_len: c_uint

    var __local_s: *mut internal_state = (unsafe *__param_strm).state

    _tr_flush_bits(__local_s)

    var __ci_expr_ternary_0: c_uint = 0

    if ((if (unsafe *__local_s).pending > (unsafe *__param_strm).avail_out: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = (unsafe *__param_strm).avail_out)
    } else {
        (__ci_expr_ternary_0 = (((unsafe *__local_s).pending as c_uint)))
    }

    (__local_len = __ci_expr_ternary_0)


    if ((if __local_len == 0: 1 else: 0) != 0) {
        return
    }

    with_memcpy((((unsafe *__param_strm).next_out as *mut c_void) as *i8), (((unsafe *__local_s).pending_out as *const c_void) as *i8), ((__local_len as c_ulong) as i64))

    ((unsafe *__param_strm).next_out = (unsafe *__param_strm).next_out + (__local_len as usize))

    ((unsafe *__local_s).pending_out = (unsafe *__local_s).pending_out + (__local_len as usize))

    ((unsafe *__param_strm).total_out = ((unsafe *__param_strm).total_out +% __local_len))

    ((unsafe *__param_strm).avail_out = ((unsafe *__param_strm).avail_out -% __local_len))

    ((unsafe *__local_s).pending = ((unsafe *__local_s).pending -% __local_len))

    if ((if (unsafe *__local_s).pending == 0: 1 else: 0) != 0) {
        ((unsafe *__local_s).pending_out = (unsafe *__local_s).pending_buf)

    }

}

unsafe fn longest_match(__param_s: *mut internal_state, __param_cur_match: c_uint) -> c_uint {
    var __local_cur_match = __param_cur_match
    var __local_chain_length: c_uint = (unsafe *__param_s).max_chain_length

    var __local_scan: *mut u8 = ((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize))

    var __local_match_: *mut u8

    var __local_len: c_int

    var __local_best_len: c_int = (((unsafe *__param_s).prev_length as c_int))

    var __local_nice_match: c_int = (unsafe *__param_s).nice_match

    var __local_limit: c_uint = with 0 as __ci_expr_seq_15 {
        var __ci_expr_ternary_0: c_uint = 0
        if ((if (unsafe *__param_s).strstart > (((unsafe *__param_s).w_size as c_uint) -% (262 as c_uint)): 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((((unsafe *__param_s).strstart as c_uint) -% ((((unsafe *__param_s).w_size as c_uint) -% (262 as c_uint)) as c_uint)) as c_uint)))
        } else {
            (__ci_expr_ternary_0 = ((0 as c_uint)))
        }
        __ci_expr_ternary_0
    }

    var __local_prev: *mut c_ushort = (unsafe *__param_s).prev

    var __local_wmask: c_uint = (unsafe *__param_s).w_mask

    var __local_strend: *mut u8 = (((unsafe *__param_s).window + ((unsafe *__param_s).strstart as usize)) + ((258 as isize) as usize))

    var __local_scan_end1: u8 = (((unsafe __local_scan[(__local_best_len - 1)]) as u8))

    var __local_scan_end: u8 = (((unsafe __local_scan[__local_best_len]) as u8))

    if ((if (unsafe *__param_s).prev_length >= (unsafe *__param_s).good_match: 1 else: 0) != 0) {
        (__local_chain_length = __local_chain_length >> (2 as c_uint))

    }

    if ((if ((__local_nice_match as c_uint)) > (unsafe *__param_s).lookahead: 1 else: 0) != 0) {
        (__local_nice_match = (((unsafe *__param_s).lookahead as c_int)))
    }

    loop {
        (__local_match_ = (unsafe *__param_s).window + (__local_cur_match as usize))

        var __ci_expr_logic_4: c_int

        var __ci_expr_logic_3: c_int

        var __ci_expr_logic_2: c_int

        if ((if (unsafe __local_match_[__local_best_len]) != __local_scan_end: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (unsafe __local_match_[(__local_best_len - 1)]) != __local_scan_end1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if (unsafe *__local_match_) != (unsafe *__local_scan): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__local_match_ = __local_match_ + 1)

            (__ci_expr_logic_4 = (if (if (unsafe *__local_match_) != (unsafe __local_scan[1]): 1 else: 0) != 0: 1 else: 0))

        }

        if (__ci_expr_logic_4 != 0) {
            var __ci_expr_logic_1: c_int = 0

            (__local_cur_match = (((unsafe __local_prev[((__local_cur_match as c_uint) & (__local_wmask as c_uint))]) as c_uint)))

            if ((if __local_cur_match > __local_limit: 1 else: 0) != 0) {
                (__local_chain_length = (__local_chain_length -% 1))

                (__ci_expr_logic_1 = (if (if __local_chain_length != 0: 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_1 != 0) {
                continue
            }
            break

        }


        (__local_scan = __local_scan + ((2 as isize) as usize))

        (__local_match_ = __local_match_ + 1)


        loop {
            0
            var __ci_expr_logic_12: c_int = 0

            var __ci_expr_logic_11: c_int = 0

            var __ci_expr_logic_10: c_int = 0

            var __ci_expr_logic_9: c_int = 0

            var __ci_expr_logic_8: c_int = 0

            var __ci_expr_logic_7: c_int = 0

            var __ci_expr_logic_6: c_int = 0

            var __ci_expr_logic_5: c_int = 0

            (__local_scan = __local_scan + 1)

            (__local_match_ = __local_match_ + 1)

            if ((if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_5 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_5 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_6 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_6 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_7 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_7 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_8 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_8 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_9 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_9 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_10 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_10 != 0) {
                (__local_scan = __local_scan + 1)

                (__local_match_ = __local_match_ + 1)

                (__ci_expr_logic_11 = (if (if (unsafe *__local_scan) == (unsafe *__local_match_): 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_11 != 0) {
                (__ci_expr_logic_12 = (if (if __local_scan < __local_strend: 1 else: 0) != 0: 1 else: 0))
            }

            if not ((__ci_expr_logic_12 != 0)) {
                break
            }
        }

        (__local_len = (((258 - ((((__local_strend as usize) -% (__local_scan as usize)) / sizeof[u8]()) as c_int)) as c_int)))

        (__local_scan = __local_strend - ((258 as isize) as usize))

        if ((if __local_len > __local_best_len: 1 else: 0) != 0) {
            ((unsafe *__param_s).match_start = __local_cur_match)

            (__local_best_len = __local_len)

            if ((if __local_len >= __local_nice_match: 1 else: 0) != 0) {
                break
            }

            (__local_scan_end1 = (((unsafe __local_scan[(__local_best_len - 1)]) as u8)))

            (__local_scan_end = (((unsafe __local_scan[__local_best_len]) as u8)))

        }

        var __ci_expr_logic_1: c_int = 0

        (__local_cur_match = (((unsafe __local_prev[((__local_cur_match as c_uint) & (__local_wmask as c_uint))]) as c_uint)))

        if ((if __local_cur_match > __local_limit: 1 else: 0) != 0) {
            (__local_chain_length = (__local_chain_length -% 1))

            (__ci_expr_logic_1 = (if (if __local_chain_length != 0: 1 else: 0) != 0: 1 else: 0))

        }

        if not ((__ci_expr_logic_1 != 0)) {
            break
        }
    }

    if ((if ((__local_best_len as c_uint)) <= (unsafe *__param_s).lookahead: 1 else: 0) != 0) {
        return ((__local_best_len as c_uint))
    }

    return (unsafe *__param_s).lookahead

}

let configuration_table: [10]config_s = [config_s { good_length: 0, max_lazy: 0, nice_length: 0, max_chain: 0, func: deflate_stored }, config_s { good_length: 4, max_lazy: 4, nice_length: 8, max_chain: 4, func: deflate_fast }, config_s { good_length: 4, max_lazy: 5, nice_length: 16, max_chain: 8, func: deflate_fast }, config_s { good_length: 4, max_lazy: 6, nice_length: 32, max_chain: 32, func: deflate_fast }, config_s { good_length: 4, max_lazy: 4, nice_length: 16, max_chain: 16, func: deflate_slow }, config_s { good_length: 8, max_lazy: 16, nice_length: 32, max_chain: 32, func: deflate_slow }, config_s { good_length: 8, max_lazy: 16, nice_length: 128, max_chain: 128, func: deflate_slow }, config_s { good_length: 8, max_lazy: 32, nice_length: 128, max_chain: 256, func: deflate_slow }, config_s { good_length: 32, max_lazy: 128, nice_length: 258, max_chain: 1024, func: deflate_slow }, config_s { good_length: 32, max_lazy: 258, nice_length: 258, max_chain: 4096, func: deflate_slow }]
