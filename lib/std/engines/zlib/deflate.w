// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.compress
use std.engines.zlib.uncompr
use std.engines.zlib.gzlib
use std.engines.zlib.gzwrite
use std.engines.zlib.gzread
use std.engines.zlib.gzclose
use std.engines.zlib.adler32
use std.engines.zlib.crc32
use std.engines.zlib.inftrees
use std.engines.zlib.trees
use std.option
use std.collections

pub unsafe fn deflate(__param_strm: *mut z_stream_s, __param_flush: i32) -> i32 {
    var __local_old_flush: i32

    var __local_s: *mut internal_state

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

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

    var __ci_expr_logic_5: i32

    var __ci_expr_logic_3: i32

    if ((if (*__param_strm).next_out == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_2: i32 = 0

        if ((if (*__param_strm).avail_in != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (*__param_strm).next_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_5 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_4: i32 = 0

        if ((if (*__local_s).status == 666: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_5 != 0) {
        var __ci_expr_ternary_7: i32 = 0

        var __ci_expr_logic_6: i32

        if ((if -2 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if -2 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (__ci_expr_ternary_7 = ((9 as i32)))
        } else {
            (__ci_expr_ternary_7 = (((2 - -2) as i32)))
        }

        ((*__param_strm).msg = z_errmsg[__ci_expr_ternary_7])

        return -2


    }


    if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
        var __ci_expr_ternary_9: i32 = 0

        var __ci_expr_logic_8: i32

        if ((if -5 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_8 != 0) {
            (__ci_expr_ternary_9 = ((9 as i32)))
        } else {
            (__ci_expr_ternary_9 = (((2 - -5) as i32)))
        }

        ((*__param_strm).msg = z_errmsg[__ci_expr_ternary_9])

        return -5

    }

    (__local_old_flush = (*__local_s).last_flush)

    ((*__local_s).last_flush = __param_flush)

    if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
        flush_pending(__param_strm)

        if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
            ((*__local_s).last_flush = ((-1 as i32)))

            return 0

        }

    } else {
        var __ci_expr_logic_11: i32 = 0

        var __ci_expr_logic_10: i32 = 0

        if ((if (*__param_strm).avail_in == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if ((__param_flush * 2) - (if (if __param_flush > 4: 1 else: 0) != 0: (9 as i32) else: (0 as i32))) <= ((__local_old_flush * 2) - (if (if __local_old_flush > 4: 1 else: 0) != 0: (9 as i32) else: (0 as i32))): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_11 != 0) {
            var __ci_expr_ternary_13: i32 = 0

            var __ci_expr_logic_12: i32

            if ((if -5 < -6: 1 else: 0) != 0) {
                (__ci_expr_logic_12 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_12 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_12 != 0) {
                (__ci_expr_ternary_13 = ((9 as i32)))
            } else {
                (__ci_expr_ternary_13 = (((2 - -5) as i32)))
            }

            ((*__param_strm).msg = z_errmsg[__ci_expr_ternary_13])

            return -5


        }

    }

    var __ci_expr_logic_14: i32 = 0

    if ((if (*__local_s).status == 666: 1 else: 0) != 0) {
        (__ci_expr_logic_14 = (if (if (*__param_strm).avail_in != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_14 != 0) {
        var __ci_expr_ternary_16: i32 = 0

        var __ci_expr_logic_15: i32

        if ((if -5 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_15 = (if (if -5 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_ternary_16 = ((9 as i32)))
        } else {
            (__ci_expr_ternary_16 = (((2 - -5) as i32)))
        }

        ((*__param_strm).msg = z_errmsg[__ci_expr_ternary_16])

        return -5


    }


    var __ci_expr_logic_17: i32 = 0

    if ((if (*__local_s).status == 42: 1 else: 0) != 0) {
        (__ci_expr_logic_17 = (if (if (*__local_s).wrap == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_17 != 0) {
        ((*__local_s).status = ((113 as i32)))
    }


    if ((if (*__local_s).status == 42: 1 else: 0) != 0) {
        var __local_header: u32 = ((((((8 as u32) +% ((((((*__local_s).w_bits as u32) -% (8 as u32)) as u32) << (4 as u32)) as u32)) as u32) << (8 as u32)) as u32))

        var __local_level_flags: u32

        var __ci_expr_logic_18: i32

        if ((if (*__local_s).strategy >= 2: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_18 = (if (if (*__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_18 != 0) {
            (__local_level_flags = ((0 as u32)))
        } else {
            if ((if (*__local_s).level < 6: 1 else: 0) != 0) {
                (__local_level_flags = ((1 as u32)))
            } else {
                if ((if (*__local_s).level == 6: 1 else: 0) != 0) {
                    (__local_level_flags = ((2 as u32)))
                } else {
                    (__local_level_flags = ((3 as u32)))
                }
            }
        }


        (__local_header = (__local_header as u32) | (((__local_level_flags as u32) << (6 as u32)) as u32))

        if ((if (*__local_s).strstart != 0: 1 else: 0) != 0) {
            (__local_header = (__local_header as u32) | (32 as u32))
        }

        (__local_header = (__local_header +% ((31 as u32) -% (((__local_header as u32) % (31 as u32)) as u32))))

        putShortMSB(__local_s, __local_header)

        if ((if (*__local_s).strstart != 0: 1 else: 0) != 0) {
            putShortMSB(__local_s, ((((*__param_strm).adler as u64) >> (16 as u32)) as u32))

            putShortMSB(__local_s, ((((*__param_strm).adler as u64) & (65535 as u64)) as u32))

        }

        ((*__param_strm).adler = ((adler32((0 as u64), null, (0 as u32)) as u64)))

        ((*__local_s).status = ((113 as i32)))

        flush_pending(__param_strm)

        if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
            ((*__local_s).last_flush = ((-1 as i32)))

            return 0

        }

    }

    if ((if (*__local_s).status == 57: 1 else: 0) != 0) {
        ((*__param_strm).adler = ((crc32((0 as u64), null, (0 as u32)) as u64)))

        var __ci_expr_old_19: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_19]) = ((31 as u8)))




        var __ci_expr_old_20: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_20]) = ((139 as u8)))




        var __ci_expr_old_21: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_21]) = ((8 as u8)))




        if ((if (*__local_s).gzhead == 0: 1 else: 0) != 0) {
            var __ci_expr_old_22: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_22]) = ((0 as u8)))




            var __ci_expr_old_23: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_23]) = ((0 as u8)))




            var __ci_expr_old_24: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_24]) = ((0 as u8)))




            var __ci_expr_old_25: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_25]) = ((0 as u8)))




            var __ci_expr_old_26: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_26]) = ((0 as u8)))




            var __ci_expr_old_27: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            var __ci_expr_ternary_30: i32 = 0

            if ((if (*__local_s).level == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_30 = ((2 as i32)))
            } else {
                var __ci_expr_ternary_29: i32 = 0

                var __ci_expr_logic_28: i32

                if ((if (*__local_s).strategy >= 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_28 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_28 = (if (if (*__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_28 != 0) {
                    (__ci_expr_ternary_29 = ((4 as i32)))
                } else {
                    (__ci_expr_ternary_29 = ((0 as i32)))
                }

                (__ci_expr_ternary_30 = __ci_expr_ternary_29)

            }

            (((*__local_s).pending_buf[__ci_expr_old_27]) = ((__ci_expr_ternary_30 as u8)))




            var __ci_expr_old_31: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_31]) = ((19 as u8)))




            ((*__local_s).status = ((113 as i32)))

            flush_pending(__param_strm)

            if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                ((*__local_s).last_flush = ((-1 as i32)))

                return 0

            }

        } else {
            var __ci_expr_old_32: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_32]) = (((((((if (*(*__local_s).gzhead).text != 0: (1 as i32) else: (0 as i32)) + (if (*(*__local_s).gzhead).hcrc != 0: (2 as i32) else: (0 as i32))) + (if (if (*(*__local_s).gzhead).extra == 0: 1 else: 0) != 0: (0 as i32) else: (4 as i32))) + (if (if (*(*__local_s).gzhead).name == 0: 1 else: 0) != 0: (0 as i32) else: (8 as i32))) + (if (if (*(*__local_s).gzhead).comment == 0: 1 else: 0) != 0: (0 as i32) else: (16 as i32))) as u8)))




            var __ci_expr_old_33: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_33]) = (((((*(*__local_s).gzhead).time as u64) & (255 as u64)) as u8)))




            var __ci_expr_old_34: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_34]) = (((((((*(*__local_s).gzhead).time as u64) >> (8 as u32)) as u64) & (255 as u64)) as u8)))




            var __ci_expr_old_35: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_35]) = (((((((*(*__local_s).gzhead).time as u64) >> (16 as u32)) as u64) & (255 as u64)) as u8)))




            var __ci_expr_old_36: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_36]) = (((((((*(*__local_s).gzhead).time as u64) >> (24 as u32)) as u64) & (255 as u64)) as u8)))




            var __ci_expr_old_37: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            var __ci_expr_ternary_40: i32 = 0

            if ((if (*__local_s).level == 9: 1 else: 0) != 0) {
                (__ci_expr_ternary_40 = ((2 as i32)))
            } else {
                var __ci_expr_ternary_39: i32 = 0

                var __ci_expr_logic_38: i32

                if ((if (*__local_s).strategy >= 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_38 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_38 = (if (if (*__local_s).level < 2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_38 != 0) {
                    (__ci_expr_ternary_39 = ((4 as i32)))
                } else {
                    (__ci_expr_ternary_39 = ((0 as i32)))
                }

                (__ci_expr_ternary_40 = __ci_expr_ternary_39)

            }

            (((*__local_s).pending_buf[__ci_expr_old_37]) = ((__ci_expr_ternary_40 as u8)))




            var __ci_expr_old_41: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_41]) = (((((*(*__local_s).gzhead).os as i32) & (255 as i32)) as u8)))




            if ((if (*(*__local_s).gzhead).extra != 0: 1 else: 0) != 0) {
                var __ci_expr_old_42: u64 = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_42]) = (((((*(*__local_s).gzhead).extra_len as u32) & (255 as u32)) as u8)))




                var __ci_expr_old_43: u64 = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_43]) = (((((((*(*__local_s).gzhead).extra_len as u32) >> (8 as u32)) as u32) & (255 as u32)) as u8)))




            }

            if ((*(*__local_s).gzhead).hcrc != 0) {
                ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, ((*__local_s).pending_buf as *const u8), (*__local_s).pending) as u64)))
            }

            ((*__local_s).gzindex = ((0 as u64)))

            ((*__local_s).status = ((69 as i32)))

        }

    }

    if ((if (*__local_s).status == 69: 1 else: 0) != 0) {
        if ((if (*(*__local_s).gzhead).extra != 0: 1 else: 0) != 0) {
            var __local_beg: u64 = (*__local_s).pending

            var __local_left: u64 = (((((((*(*__local_s).gzhead).extra_len as u32) & (65535 as u32)) as u64) -% ((*__local_s).gzindex as u64)) as u64))

            while ((if (((*__local_s).pending as u64) +% (__local_left as u64)) > (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                var __local_copy_: u64 = (((((*__local_s).pending_buf_size as u64) -% ((*__local_s).pending as u64)) as u64))

                with_memcpy(((((*__local_s).pending_buf + ((*__local_s).pending as usize)) as *mut c_void) as *mut u8), ((((*(*__local_s).gzhead).extra + ((*__local_s).gzindex as usize)) as *const c_void) as *const u8), (__local_copy_ as i64))

                ((*__local_s).pending = (*__local_s).pending_buf_size)

                loop {
                    var __ci_expr_logic_44: i32 = 0

                    if ((*(*__local_s).gzhead).hcrc != 0) {
                        (__ci_expr_logic_44 = (if (if (*__local_s).pending > __local_beg: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_44 != 0) {
                        ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg as usize)) as *const u8), ((((*__local_s).pending as u64) -% (__local_beg as u64)) as u64)) as u64)))
                    }


                    if not ((0 != 0)) {
                        break
                    }
                }

                ((*__local_s).gzindex = ((*__local_s).gzindex +% __local_copy_))

                flush_pending(__param_strm)

                if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                    ((*__local_s).last_flush = ((-1 as i32)))

                    return 0

                }

                (__local_beg = ((0 as u64)))

                (__local_left = (__local_left -% __local_copy_))

            }

            with_memcpy(((((*__local_s).pending_buf + ((*__local_s).pending as usize)) as *mut c_void) as *mut u8), ((((*(*__local_s).gzhead).extra + ((*__local_s).gzindex as usize)) as *const c_void) as *const u8), (__local_left as i64))

            ((*__local_s).pending = ((*__local_s).pending +% __local_left))

            loop {
                var __ci_expr_logic_45: i32 = 0

                if ((*(*__local_s).gzhead).hcrc != 0) {
                    (__ci_expr_logic_45 = (if (if (*__local_s).pending > __local_beg: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_45 != 0) {
                    ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg as usize)) as *const u8), ((((*__local_s).pending as u64) -% (__local_beg as u64)) as u64)) as u64)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

            ((*__local_s).gzindex = ((0 as u64)))

        }

        ((*__local_s).status = ((73 as i32)))

    }

    if ((if (*__local_s).status == 73: 1 else: 0) != 0) {
        if ((if (*(*__local_s).gzhead).name != 0: 1 else: 0) != 0) {
            var __local_beg_1: u64 = (*__local_s).pending

            var __local_val: i32

            loop {
                if ((if (*__local_s).pending == (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                    loop {
                        var __ci_expr_logic_46: i32 = 0

                        if ((*(*__local_s).gzhead).hcrc != 0) {
                            (__ci_expr_logic_46 = (if (if (*__local_s).pending > __local_beg_1: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_46 != 0) {
                            ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_1 as usize)) as *const u8), ((((*__local_s).pending as u64) -% (__local_beg_1 as u64)) as u64)) as u64)))
                        }


                        if not ((0 != 0)) {
                            break
                        }
                    }

                    flush_pending(__param_strm)

                    if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                        ((*__local_s).last_flush = ((-1 as i32)))

                        return 0

                    }

                    (__local_beg_1 = ((0 as u64)))

                }

                var __ci_expr_old_47: u64 = (*__local_s).gzindex

                ((*__local_s).gzindex = ((*__local_s).gzindex +% 1))

                (__local_val = ((((*(*__local_s).gzhead).name[__ci_expr_old_47]) as i32)))


                var __ci_expr_old_48: u64 = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_48]) = ((__local_val as u8)))




                if not (((if __local_val != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            loop {
                var __ci_expr_logic_49: i32 = 0

                if ((*(*__local_s).gzhead).hcrc != 0) {
                    (__ci_expr_logic_49 = (if (if (*__local_s).pending > __local_beg_1: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_49 != 0) {
                    ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_1 as usize)) as *const u8), ((((*__local_s).pending as u64) -% (__local_beg_1 as u64)) as u64)) as u64)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

            ((*__local_s).gzindex = ((0 as u64)))

        }

        ((*__local_s).status = ((91 as i32)))

    }

    if ((if (*__local_s).status == 91: 1 else: 0) != 0) {
        if ((if (*(*__local_s).gzhead).comment != 0: 1 else: 0) != 0) {
            var __local_beg_2: u64 = (*__local_s).pending

            var __local_val_1: i32

            loop {
                if ((if (*__local_s).pending == (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                    loop {
                        var __ci_expr_logic_50: i32 = 0

                        if ((*(*__local_s).gzhead).hcrc != 0) {
                            (__ci_expr_logic_50 = (if (if (*__local_s).pending > __local_beg_2: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_50 != 0) {
                            ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_2 as usize)) as *const u8), ((((*__local_s).pending as u64) -% (__local_beg_2 as u64)) as u64)) as u64)))
                        }


                        if not ((0 != 0)) {
                            break
                        }
                    }

                    flush_pending(__param_strm)

                    if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                        ((*__local_s).last_flush = ((-1 as i32)))

                        return 0

                    }

                    (__local_beg_2 = ((0 as u64)))

                }

                var __ci_expr_old_51: u64 = (*__local_s).gzindex

                ((*__local_s).gzindex = ((*__local_s).gzindex +% 1))

                (__local_val_1 = ((((*(*__local_s).gzhead).comment[__ci_expr_old_51]) as i32)))


                var __ci_expr_old_52: u64 = (*__local_s).pending

                ((*__local_s).pending = ((*__local_s).pending +% 1))

                (((*__local_s).pending_buf[__ci_expr_old_52]) = ((__local_val_1 as u8)))




                if not (((if __local_val_1 != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            loop {
                var __ci_expr_logic_53: i32 = 0

                if ((*(*__local_s).gzhead).hcrc != 0) {
                    (__ci_expr_logic_53 = (if (if (*__local_s).pending > __local_beg_2: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_53 != 0) {
                    ((*__param_strm).adler = ((crc32_z((*__param_strm).adler, (((*__local_s).pending_buf + (__local_beg_2 as usize)) as *const u8), ((((*__local_s).pending as u64) -% (__local_beg_2 as u64)) as u64)) as u64)))
                }


                if not ((0 != 0)) {
                    break
                }
            }

        }

        ((*__local_s).status = ((103 as i32)))

    }

    if ((if (*__local_s).status == 103: 1 else: 0) != 0) {
        if ((*(*__local_s).gzhead).hcrc != 0) {
            if ((if (((*__local_s).pending as u64) +% (2 as u64)) > (*__local_s).pending_buf_size: 1 else: 0) != 0) {
                flush_pending(__param_strm)

                if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
                    ((*__local_s).last_flush = ((-1 as i32)))

                    return 0

                }

            }

            var __ci_expr_old_54: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_54]) = (((((*__param_strm).adler as u64) & (255 as u64)) as u8)))




            var __ci_expr_old_55: u64 = (*__local_s).pending

            ((*__local_s).pending = ((*__local_s).pending +% 1))

            (((*__local_s).pending_buf[__ci_expr_old_55]) = (((((((*__param_strm).adler as u64) >> (8 as u32)) as u64) & (255 as u64)) as u8)))




            ((*__param_strm).adler = ((crc32((0 as u64), null, (0 as u32)) as u64)))

        }

        ((*__local_s).status = ((113 as i32)))

        flush_pending(__param_strm)

        if ((if (*__local_s).pending != 0: 1 else: 0) != 0) {
            ((*__local_s).last_flush = ((-1 as i32)))

            return 0

        }

    }

    var __ci_expr_logic_58: i32

    var __ci_expr_logic_56: i32

    if ((if (*__param_strm).avail_in != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_56 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_56 = (if (if (*__local_s).lookahead != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_56 != 0) {
        (__ci_expr_logic_58 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_57: i32 = 0

        if ((if __param_flush != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_57 = (if (if (*__local_s).status != 666: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_58 = (if __ci_expr_logic_57 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_58 != 0) {
        var __local_bstate: i32

        (__local_bstate = (((if (if (*__local_s).level == 0: 1 else: 0) != 0: (deflate_stored(__local_s, __param_flush) as u32) else: ((if (if (*__local_s).strategy == 2: 1 else: 0) != 0: (deflate_huff(__local_s, __param_flush) as u32) else: ((if (if (*__local_s).strategy == 3: 1 else: 0) != 0: (deflate_rle(__local_s, __param_flush) as u32) else: (configuration_table[(*__local_s).level].func.unwrap()(__local_s, __param_flush) as u32)) as u32)) as u32)) as i32)))

        var __ci_expr_logic_59: i32

        if ((if __local_bstate == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_59 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_59 = (if (if __local_bstate == 3: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_59 != 0) {
            ((*__local_s).status = ((666 as i32)))

        }


        var __ci_expr_logic_60: i32

        if ((if __local_bstate == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_60 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_60 = (if (if __local_bstate == 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_60 != 0) {
            if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
                ((*__local_s).last_flush = ((-1 as i32)))

            }

            return 0

        }


        if ((if __local_bstate == 1: 1 else: 0) != 0) {
            if ((if __param_flush == 1: 1 else: 0) != 0) {
                _tr_align(__local_s)

            } else {
                if ((if __param_flush != 5: 1 else: 0) != 0) {
                    _tr_stored_block(__local_s, null, (0 as u64), (0 as i32))

                    if ((if __param_flush == 3: 1 else: 0) != 0) {
                        loop {
                            (((*__local_s).head[(((*__local_s).hash_size as u32) -% (1 as u32))]) = ((0 as u16)))

                            with_memset((((*__local_s).head as *mut c_void) as *mut u8), (0 as i32), (((((((*__local_s).hash_size as u32) -% (1 as u32)) as u64) *% (sizeof[u16]() as u64)) as u64) as i64))

                            ((*__local_s).slid = ((0 as i32)))

                            if not ((0 != 0)) {
                                break
                            }
                        }

                        if ((if (*__local_s).lookahead == 0: 1 else: 0) != 0) {
                            ((*__local_s).strstart = ((0 as u32)))

                            ((*__local_s).block_start = ((0 as i64)))

                            ((*__local_s).insert = ((0 as u32)))

                        }

                    }

                }
            }

            flush_pending(__param_strm)

            if ((if (*__param_strm).avail_out == 0: 1 else: 0) != 0) {
                ((*__local_s).last_flush = ((-1 as i32)))

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
        var __ci_expr_old_61: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_61]) = (((((*__param_strm).adler as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_62: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_62]) = (((((((*__param_strm).adler as u64) >> (8 as u32)) as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_63: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_63]) = (((((((*__param_strm).adler as u64) >> (16 as u32)) as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_64: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_64]) = (((((((*__param_strm).adler as u64) >> (24 as u32)) as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_65: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_65]) = (((((*__param_strm).total_in as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_66: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_66]) = (((((((*__param_strm).total_in as u64) >> (8 as u32)) as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_67: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_67]) = (((((((*__param_strm).total_in as u64) >> (16 as u32)) as u64) & (255 as u64)) as u8)))




        var __ci_expr_old_68: u64 = (*__local_s).pending

        ((*__local_s).pending = ((*__local_s).pending +% 1))

        (((*__local_s).pending_buf[__ci_expr_old_68]) = (((((((*__param_strm).total_in as u64) >> (24 as u32)) as u64) & (255 as u64)) as u8)))




    } else {
        putShortMSB(__local_s, ((((*__param_strm).adler as u64) >> (16 as u32)) as u32))

        putShortMSB(__local_s, ((((*__param_strm).adler as u64) & (65535 as u64)) as u32))

    }

    flush_pending(__param_strm)

    if ((if (*__local_s).wrap > 0: 1 else: 0) != 0) {
        ((*__local_s).wrap = (((0 - (*__local_s).wrap) as i32)))
    }

    return (if (if (*__local_s).pending != 0: 1 else: 0) != 0: (0 as i32) else: (1 as i32))

}

pub unsafe fn deflateEnd(__param_strm: *mut z_stream_s) -> i32 {
    var __local_status: i32

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

    return (if (if __local_status == 113: 1 else: 0) != 0: (-3 as i32) else: (0 as i32))

}

pub unsafe fn deflateSetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *const u8, __param_dictLength: u32) -> i32 {
    var __local_dictionary = __param_dictionary
    var __local_dictLength = __param_dictLength
    var __local_s: *mut internal_state

    var __local_str: u32

    var __local_n: u32


    var __local_wrap: i32

    var __local_avail: u32

    var __local_next: *mut u8

    var __ci_expr_logic_0: i32

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

    var __ci_expr_logic_3: i32

    var __ci_expr_logic_2: i32

    if ((if __local_wrap == 2: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_1: i32 = 0

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
        ((*__param_strm).adler = ((adler32((*__param_strm).adler, __local_dictionary, __local_dictLength) as u64)))
    }

    ((*__local_s).wrap = ((0 as i32)))

    if ((if __local_dictLength >= (*__local_s).w_size: 1 else: 0) != 0) {
        if ((if __local_wrap == 0: 1 else: 0) != 0) {
            loop {
                (((*__local_s).head[(((*__local_s).hash_size as u32) -% (1 as u32))]) = ((0 as u16)))

                with_memset((((*__local_s).head as *mut c_void) as *mut u8), (0 as i32), (((((((*__local_s).hash_size as u32) -% (1 as u32)) as u64) *% (sizeof[u16]() as u64)) as u64) as i64))

                ((*__local_s).slid = ((0 as i32)))

                if not ((0 != 0)) {
                    break
                }
            }

            ((*__local_s).strstart = ((0 as u32)))

            ((*__local_s).block_start = ((0 as i64)))

            ((*__local_s).insert = ((0 as u32)))

        }

        (__local_dictionary = __local_dictionary + (((__local_dictLength as u32) -% ((*__local_s).w_size as u32)) as usize))

        (__local_dictLength = (*__local_s).w_size)

    }

    (__local_avail = (*__param_strm).avail_in)

    (__local_next = (*__param_strm).next_in)

    ((*__param_strm).avail_in = __local_dictLength)

    ((*__param_strm).next_in = ((__local_dictionary as *mut u8)))

    fill_window(__local_s)

    while ((if (*__local_s).lookahead >= 3: 1 else: 0) != 0) {
        (__local_str = (*__local_s).strstart)

        (__local_n = (((((*__local_s).lookahead as u32) -% (2 as u32)) as u32)))

        loop {
            ((*__local_s).ins_h = (((((((((*__local_s).ins_h as u32) << ((*__local_s).hash_shift as u32)) as u32) ^ ((((*__local_s).window[((((__local_str as u32) +% (3 as u32)) as u32) -% (1 as u32))]) as i32) as u32)) as u32) & ((*__local_s).hash_mask as u32)) as u32)))

            (((*__local_s).prev[((__local_str as u32) & ((*__local_s).w_mask as u32))]) = ((((*__local_s).head[(*__local_s).ins_h]) as u16)))

            (((*__local_s).head[(*__local_s).ins_h]) = ((__local_str as u16)))

            (__local_str = (__local_str +% 1))

            (__local_n = (__local_n -% 1))
            if not ((__local_n != 0)) {
                break
            }
        }

        ((*__local_s).strstart = __local_str)

        ((*__local_s).lookahead = ((2 as u32)))

        fill_window(__local_s)

    }

    ((*__local_s).strstart = ((*__local_s).strstart +% (*__local_s).lookahead))

    ((*__local_s).block_start = (((*__local_s).strstart as i64)))

    ((*__local_s).insert = (*__local_s).lookahead)

    ((*__local_s).lookahead = ((0 as u32)))

    ((*__local_s).prev_length = ((2 as u32)))

    ((*__local_s).match_length = (*__local_s).prev_length)


    ((*__local_s).match_available = ((0 as i32)))

    ((*__param_strm).next_in = __local_next)

    ((*__param_strm).avail_in = __local_avail)

    ((*__local_s).wrap = __local_wrap)

    return 0

}

pub unsafe fn deflateGetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *mut u8, __param_dictLength: *mut u32) -> i32 {
    var __local_s: *mut internal_state

    var __local_len: u32

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    (__local_len = (((((*__local_s).strstart as u32) +% ((*__local_s).lookahead as u32)) as u32)))

    if ((if __local_len > (*__local_s).w_size: 1 else: 0) != 0) {
        (__local_len = (*__local_s).w_size)
    }

    var __ci_expr_logic_0: i32 = 0

    if ((if __param_dictionary != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if __local_len != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy(((__param_dictionary as *mut c_void) as *mut u8), ((((((*__local_s).window + ((*__local_s).strstart as usize)) + ((*__local_s).lookahead as usize)) - (__local_len as usize)) as *const c_void) as *const u8), ((__local_len as u64) as i64))
    }


    if ((if __param_dictLength != 0: 1 else: 0) != 0) {
        ((*__param_dictLength) = __local_len)
    }

    return 0

}

pub unsafe fn deflateCopy(__param_dest: *mut z_stream_s, __param_source: *mut z_stream_s) -> i32 {
    var __local_ds: *mut internal_state

    var __local_ss: *mut internal_state

    var __ci_expr_logic_0: i32

    if (deflateStateCheck(__param_source) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_dest == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2

    }


    (__local_ss = (*__param_source).state)

    with_memcpy(((__param_dest as *mut c_void) as *mut u8), ((__param_source as *const c_void) as *const u8), ((sizeof[z_stream_s]() as u64) as i64))

    (__local_ds = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (1 as u32), (5968 as u32)) as *mut internal_state)))

    if ((if __local_ds == 0: 1 else: 0) != 0) {
        return -4
    }

    (*__local_ds) = internal_state.zeroed()

    ((*__param_dest).state = __local_ds)

    with_memcpy(((__local_ds as *mut c_void) as *mut u8), ((__local_ss as *const c_void) as *const u8), ((sizeof[internal_state]() as u64) as i64))

    ((*__local_ds).strm = __param_dest)

    ((*__local_ds).window = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).w_size, (2 as u32)) as *mut u8)))

    ((*__local_ds).prev = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).w_size, (2 as u32)) as *mut u16)))

    ((*__local_ds).head = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).hash_size, (2 as u32)) as *mut u16)))

    ((*__local_ds).pending_buf = (((*__param_dest).zalloc.unwrap()((*__param_dest).opaque_, (*__local_ds).lit_bufsize, (4 as u32)) as *mut u8)))

    var __ci_expr_logic_3: i32

    var __ci_expr_logic_2: i32

    var __ci_expr_logic_1: i32

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

    var __ci_expr_ternary_5: u32 = 0

    var __ci_expr_logic_4: i32

    if ((*__local_ss).slid != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if (((*__local_ss).strstart as u32) -% ((*__local_ss).insert as u32)) > (*__local_ds).w_size: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_ternary_5 = (*__local_ds).w_size)
    } else {
        (__ci_expr_ternary_5 = (((((*__local_ss).strstart as u32) -% ((*__local_ss).insert as u32)) as u32)))
    }

    with_memcpy((((*__local_ds).prev as *mut c_void) as *mut u8), (((*__local_ss).prev as *const c_void) as *const u8), ((((__ci_expr_ternary_5 as u64) *% (sizeof[u16]() as u64)) as u64) as i64))


    with_memcpy((((*__local_ds).head as *mut c_void) as *mut u8), (((*__local_ss).head as *const c_void) as *const u8), (((((*__local_ds).hash_size as u64) *% (sizeof[u16]() as u64)) as u64) as i64))

    ((*__local_ds).pending_out = (*__local_ds).pending_buf + (((((((*__local_ss).pending_out as usize) -% ((*__local_ss).pending_buf as usize)) as i64) / (sizeof[u8]() as i64)) as isize) as usize))

    with_memcpy((((*__local_ds).pending_out as *mut c_void) as *mut u8), (((*__local_ss).pending_out as *const c_void) as *const u8), ((*__local_ss).pending as i64))

    ((*__local_ds).sym_buf = (*__local_ds).pending_buf + ((*__local_ds).lit_bufsize as usize))

    with_memcpy((((*__local_ds).sym_buf as *mut c_void) as *mut u8), (((*__local_ss).sym_buf as *const c_void) as *const u8), (((*__local_ss).sym_next as u64) as i64))

    ((*__local_ds).l_desc.dyn_tree = (&(*__local_ds).dyn_ltree[0] as *mut ct_data_s))

    ((*__local_ds).d_desc.dyn_tree = (&(*__local_ds).dyn_dtree[0] as *mut ct_data_s))

    ((*__local_ds).bl_desc.dyn_tree = (&(*__local_ds).bl_tree[0] as *mut ct_data_s))

    return 0

}

pub unsafe fn deflateReset(__param_strm: *mut z_stream_s) -> i32 {
    var __local_ret: i32

    (__local_ret = ((deflateResetKeep(__param_strm) as i32)))

    if ((if __local_ret == 0: 1 else: 0) != 0) {
        lm_init((*__param_strm).state)
    }

    return __local_ret

}

pub unsafe fn deflateParams(__param_strm: *mut z_stream_s, __param_level: i32, __param_strategy: i32) -> i32 {
    var __local_level = __param_level
    var __local_s: *mut internal_state

    var __local_func: Option[unsafe extern "C" fn(*mut internal_state, i32) -> i32]

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    if ((if __local_level == -1: 1 else: 0) != 0) {
        (__local_level = ((6 as i32)))
    }

    var __ci_expr_logic_2: i32

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

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

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_3: i32

    if ((if __param_strategy != (*__local_s).strategy: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if __local_func != configuration_table[__local_level].func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if (if (*__local_s).last_flush != -2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        var __local_err: i32 = ((deflate(__param_strm, (5 as i32)) as i32))

        if ((if __local_err == -2: 1 else: 0) != 0) {
            return __local_err
        }

        var __ci_expr_logic_5: i32

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
        var __ci_expr_logic_6: i32 = 0

        if ((if (*__local_s).level == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (*__local_s).matches != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            if ((if (*__local_s).matches == 1: 1 else: 0) != 0) {
                slide_hash(__local_s)
            } else {
                loop {
                    (((*__local_s).head[(((*__local_s).hash_size as u32) -% (1 as u32))]) = ((0 as u16)))

                    with_memset((((*__local_s).head as *mut c_void) as *mut u8), (0 as i32), (((((((*__local_s).hash_size as u32) -% (1 as u32)) as u64) *% (sizeof[u16]() as u64)) as u64) as i64))

                    ((*__local_s).slid = ((0 as i32)))

                    if not ((0 != 0)) {
                        break
                    }
                }
            }

            ((*__local_s).matches = ((0 as u32)))

        }


        ((*__local_s).level = __local_level)

        ((*__local_s).max_lazy_match = ((configuration_table[__local_level].max_lazy as u32)))

        ((*__local_s).good_match = ((configuration_table[__local_level].good_length as u32)))

        ((*__local_s).nice_match = ((configuration_table[__local_level].nice_length as i32)))

        ((*__local_s).max_chain_length = ((configuration_table[__local_level].max_chain as u32)))

    }

    ((*__local_s).strategy = __param_strategy)

    return 0

}

pub unsafe fn deflateTune(__param_strm: *mut z_stream_s, __param_good_length: i32, __param_max_lazy: i32, __param_nice_length: i32, __param_max_chain: i32) -> i32 {
    var __local_s: *mut internal_state

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    ((*__local_s).good_match = ((__param_good_length as u32)))

    ((*__local_s).max_lazy_match = ((__param_max_lazy as u32)))

    ((*__local_s).nice_match = __param_nice_length)

    ((*__local_s).max_chain_length = ((__param_max_chain as u32)))

    return 0

}

pub unsafe fn deflateBound(__param_strm: *mut z_stream_s, __param_sourceLen: u64) -> u64 {
    var __local_bound: u64 = ((deflateBound_z(__param_strm, __param_sourceLen) as u64))

    return (if (if __local_bound != __local_bound: 1 else: 0) != 0: (-1 as u64) else: __local_bound)

}

pub unsafe fn deflateBound_z(__param_strm: *mut z_stream_s, __param_sourceLen: u64) -> u64 {
    var __local_s: *mut internal_state

    var __local_fixedlen: u64

    var __local_storelen: u64

    var __local_wraplen: u64

    var __local_bound: u64


    (__local_fixedlen = ((((((((((__param_sourceLen as u64) +% (((__param_sourceLen as u64) >> (3 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (8 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (9 as u32)) as u64)) as u64) +% (4 as u64)) as u64)))

    if ((if __local_fixedlen < __param_sourceLen: 1 else: 0) != 0) {
        (__local_fixedlen = ((-1 as u64)))
    }

    (__local_storelen = ((((((((((__param_sourceLen as u64) +% (((__param_sourceLen as u64) >> (5 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (7 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (11 as u32)) as u64)) as u64) +% (7 as u64)) as u64)))

    if ((if __local_storelen < __param_sourceLen: 1 else: 0) != 0) {
        (__local_storelen = ((-1 as u64)))
    }

    if (deflateStateCheck(__param_strm) != 0) {
        (__local_bound = (((if (if __local_fixedlen > __local_storelen: 1 else: 0) != 0: __local_fixedlen else: __local_storelen) as u64)))

        return (if (if ((__local_bound as u64) +% (18 as u64)) < __local_bound: 1 else: 0) != 0: (-1 as u64) else: (((__local_bound as u64) +% (18 as u64)) as u64))

    }

    (__local_s = (*__param_strm).state)

    while true {
        match (if (if (*__local_s).wrap < 0: 1 else: 0) != 0: ((0 - (*__local_s).wrap) as i32) else: (*__local_s).wrap) {
            0 => {
                (__local_wraplen = ((0 as u64)))
            },
            1 => {
                (__local_wraplen = (((6 + (if (*__local_s).strstart != 0: (4 as i32) else: (0 as i32))) as u64)))
            },
            2 => {
                (__local_wraplen = ((18 as u64)))

                if ((if (*__local_s).gzhead != 0: 1 else: 0) != 0) {
                    var __local_str: *mut u8

                    if ((if (*(*__local_s).gzhead).extra != 0: 1 else: 0) != 0) {
                        (__local_wraplen = (__local_wraplen +% ((2 as u32) +% ((*(*__local_s).gzhead).extra_len as u32))))
                    }

                    (__local_str = (*(*__local_s).gzhead).name)

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

                    (__local_str = (*(*__local_s).gzhead).comment)

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

                    if ((*(*__local_s).gzhead).hcrc != 0) {
                        (__local_wraplen = (__local_wraplen +% 2))
                    }

                }

            },
            _ => {
                (__local_wraplen = ((18 as u64)))
            },
        }

        break

    }

    var __ci_expr_logic_3: i32

    if ((if (*__local_s).w_bits != 15: 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (*__local_s).hash_bits != 15: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        var __ci_expr_ternary_5: u64 = 0

        var __ci_expr_logic_4: i32 = 0

        if ((if (*__local_s).w_bits <= (*__local_s).hash_bits: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (*__local_s).level != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_ternary_5 = __local_fixedlen)
        } else {
            (__ci_expr_ternary_5 = __local_storelen)
        }

        (__local_bound = __ci_expr_ternary_5)


        return (if (if ((__local_bound as u64) +% (__local_wraplen as u64)) < __local_bound: 1 else: 0) != 0: (-1 as u64) else: (((__local_bound as u64) +% (__local_wraplen as u64)) as u64))

    }


    (__local_bound = ((((((((((((((__param_sourceLen as u64) +% (((__param_sourceLen as u64) >> (12 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (14 as u32)) as u64)) as u64) +% (((__param_sourceLen as u64) >> (25 as u32)) as u64)) as u64) +% (13 as u64)) as u64) -% (6 as u64)) as u64) +% (__local_wraplen as u64)) as u64)))

    return (if (if __local_bound < __param_sourceLen: 1 else: 0) != 0: (-1 as u64) else: __local_bound)

}

pub unsafe fn deflatePending(__param_strm: *mut z_stream_s, __param_pending: *mut u32, __param_bits: *mut i32) -> i32 {
    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    if ((if __param_bits != 0: 1 else: 0) != 0) {
        ((*__param_bits) = (*(*__param_strm).state).bi_valid)
    }

    if ((if __param_pending != 0: 1 else: 0) != 0) {
        ((*__param_pending) = (((*(*__param_strm).state).pending as u32)))

        if ((if (*__param_pending) != (*(*__param_strm).state).pending: 1 else: 0) != 0) {
            ((*__param_pending) = ((-1 as u32)))

            return -5

        }

    }

    return 0

}

pub unsafe fn deflateUsed(__param_strm: *mut z_stream_s, __param_bits: *mut i32) -> i32 {
    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    if ((if __param_bits != 0: 1 else: 0) != 0) {
        ((*__param_bits) = (*(*__param_strm).state).bi_used)
    }

    return 0

}

pub unsafe fn deflatePrime(__param_strm: *mut z_stream_s, __param_bits: i32, __param_value: i32) -> i32 {
    var __local_bits = __param_bits
    var __local_value = __param_value
    var __local_s: *mut internal_state

    var __local_put: i32

    if (deflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_s = (*__param_strm).state)

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if ((if __local_bits < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_bits > 16: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__local_s).sym_buf < ((*__local_s).pending_out + (((((16 + 7) as i32) >> (3 as u32)) as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -5
    }


    loop {
        (__local_put = (((16 - (*__local_s).bi_valid) as i32)))

        if ((if __local_put > __local_bits: 1 else: 0) != 0) {
            (__local_put = __local_bits)
        }

        ((*__local_s).bi_buf = ((*__local_s).bi_buf as u16) | (((((__local_value as i32) & ((((1 as i32) << (__local_put as u32)) - 1) as i32)) as i32) << ((*__local_s).bi_valid as u32)) as u16))

        ((*__local_s).bi_valid = (*__local_s).bi_valid + __local_put)

        _tr_flush_bits(__local_s)

        (__local_value = __local_value >> (__local_put as u32))

        (__local_bits = __local_bits - __local_put)

        if not ((__local_bits != 0)) {
            break
        }
    }

    return 0

}

pub unsafe fn deflateSetHeader(__param_strm: *mut z_stream_s, __param_head: *mut gz_header_s) -> i32 {
    var __ci_expr_logic_0: i32

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

pub unsafe fn deflateInit_(__param_strm: *mut z_stream_s, __param_level: i32, __param_version: *const c_char, __param_stream_size: i32) -> i32 {
    return deflateInit2_(__param_strm, __param_level, (8 as i32), (15 as i32), (8 as i32), (0 as i32), __param_version, __param_stream_size)

}

pub unsafe fn deflateInit2_(__param_strm: *mut z_stream_s, __param_level: i32, __param_method: i32, __param_windowBits: i32, __param_memLevel: i32, __param_strategy: i32, __param_version: *const c_char, __param_stream_size: i32) -> i32 {
    var __local_level = __param_level
    var __local_windowBits = __param_windowBits
    var __local_s: *mut internal_state

    var __local_wrap: i32 = ((1 as i32))

    var __local_my_version: List[c_char] = [49, 46, 51, 46, 50, 0]

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if ((if __param_version == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (__param_version[0]) != 49: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if ((__param_stream_size as u64)) != (sizeof[z_stream_s]() as usize): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -6

    }


    if ((if __param_strm == 0: 1 else: 0) != 0) {
        return -2
    }

    ((*__param_strm).msg = null)

    if ((if (*__param_strm).zalloc == ((0 as unsafe extern "C" fn(*mut c_void, u32, u32) -> *mut c_void)): 1 else: 0) != 0) {
        ((*__param_strm).zalloc = Some(zcalloc))

        ((*__param_strm).opaque_ = null)

    }

    if ((if (*__param_strm).zfree == ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)): 1 else: 0) != 0) {
        ((*__param_strm).zfree = Some(zcfree))
    }

    if ((if __local_level == -1: 1 else: 0) != 0) {
        (__local_level = ((6 as i32)))
    }

    if ((if __local_windowBits < 0: 1 else: 0) != 0) {
        (__local_wrap = ((0 as i32)))

        if ((if __local_windowBits < -15: 1 else: 0) != 0) {
            return -2
        }

        (__local_windowBits = (((0 - __local_windowBits) as i32)))

    } else {
        if ((if __local_windowBits > 15: 1 else: 0) != 0) {
            (__local_wrap = ((2 as i32)))

            (__local_windowBits = __local_windowBits - 16)

        }
    }

    var __ci_expr_logic_11: i32

    var __ci_expr_logic_9: i32

    var __ci_expr_logic_8: i32

    var __ci_expr_logic_7: i32

    var __ci_expr_logic_6: i32

    var __ci_expr_logic_5: i32

    var __ci_expr_logic_4: i32

    var __ci_expr_logic_3: i32

    var __ci_expr_logic_2: i32

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
        var __ci_expr_logic_10: i32 = 0

        if ((if __local_windowBits == 8: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if __local_wrap != 1: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_11 = (if __ci_expr_logic_10 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_11 != 0) {
        return -2

    }


    if ((if __local_windowBits == 8: 1 else: 0) != 0) {
        (__local_windowBits = ((9 as i32)))
    }

    (__local_s = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (1 as u32), (5968 as u32)) as *mut internal_state)))

    if ((if __local_s == 0: 1 else: 0) != 0) {
        return -4
    }

    (*__local_s) = internal_state.zeroed()

    ((*__param_strm).state = __local_s)

    ((*__local_s).strm = __param_strm)

    ((*__local_s).status = ((42 as i32)))

    ((*__local_s).wrap = __local_wrap)

    ((*__local_s).gzhead = null)

    ((*__local_s).w_bits = ((__local_windowBits as u32)))

    ((*__local_s).w_size = ((((1 as i32) << ((*__local_s).w_bits as u32)) as u32)))

    ((*__local_s).w_mask = (((((*__local_s).w_size as u32) -% (1 as u32)) as u32)))

    ((*__local_s).hash_bits = ((((__param_memLevel as u32) +% (7 as u32)) as u32)))

    ((*__local_s).hash_size = ((((1 as i32) << ((*__local_s).hash_bits as u32)) as u32)))

    ((*__local_s).hash_mask = (((((*__local_s).hash_size as u32) -% (1 as u32)) as u32)))

    ((*__local_s).hash_shift = (((((((((*__local_s).hash_bits as u32) +% (3 as u32)) as u32) -% (1 as u32)) as u32) / (3 as u32)) as u32)))

    ((*__local_s).window = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).w_size, (2 as u32)) as *mut u8)))

    ((*__local_s).prev = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).w_size, (2 as u32)) as *mut u16)))

    ((*__local_s).head = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).hash_size, (2 as u32)) as *mut u16)))

    ((*__local_s).high_water = ((0 as u64)))

    ((*__local_s).lit_bufsize = ((((1 as i32) << ((__param_memLevel + 6) as u32)) as u32)))

    ((*__local_s).pending_buf = (((*__param_strm).zalloc.unwrap()((*__param_strm).opaque_, (*__local_s).lit_bufsize, (4 as u32)) as *mut u8)))

    ((*__local_s).pending_buf_size = (((((*__local_s).lit_bufsize as u64) *% (4 as u64)) as u64)))

    var __ci_expr_logic_14: i32

    var __ci_expr_logic_13: i32

    var __ci_expr_logic_12: i32

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
        ((*__local_s).status = ((666 as i32)))

        var __ci_expr_ternary_16: i32 = 0

        var __ci_expr_logic_15: i32

        if ((if -4 < -6: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_15 = (if (if -4 > 2: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_ternary_16 = ((9 as i32)))
        } else {
            (__ci_expr_ternary_16 = (((2 - -4) as i32)))
        }

        ((*__param_strm).msg = z_errmsg[__ci_expr_ternary_16])


        deflateEnd(__param_strm)

        return -4

    }


    ((*__local_s).sym_buf = (*__local_s).pending_buf + ((*__local_s).lit_bufsize as usize))

    ((*__local_s).sym_end = (((((((*__local_s).lit_bufsize as u32) -% (1 as u32)) as u32) *% (3 as u32)) as u32)))

    ((*__local_s).level = __local_level)

    ((*__local_s).strategy = __param_strategy)

    ((*__local_s).method = ((__param_method as u8)))

    return deflateReset(__param_strm)

}

pub unsafe fn deflateResetKeep(__param_strm: *mut z_stream_s) -> i32 {
    var __local_s: *mut internal_state

    if (deflateStateCheck(__param_strm) != 0) {
        return -2

    }

    ((*__param_strm).total_out = ((0 as u64)))

    ((*__param_strm).total_in = (*__param_strm).total_out)


    ((*__param_strm).msg = null)

    ((*__param_strm).data_type = ((2 as i32)))

    (__local_s = (*__param_strm).state)

    ((*__local_s).pending = ((0 as u64)))

    ((*__local_s).pending_out = (*__local_s).pending_buf)

    if ((if (*__local_s).wrap < 0: 1 else: 0) != 0) {
        ((*__local_s).wrap = (((0 - (*__local_s).wrap) as i32)))

    }

    ((*__local_s).status = (((if (if (*__local_s).wrap == 2: 1 else: 0) != 0: (57 as i32) else: (42 as i32)) as i32)))

    ((*__param_strm).adler = (((if (if (*__local_s).wrap == 2: 1 else: 0) != 0: (crc32((0 as u64), null, (0 as u32)) as u64) else: (adler32((0 as u64), null, (0 as u32)) as u64)) as u64)))

    ((*__local_s).last_flush = ((-2 as i32)))

    _tr_init(__local_s)

    return 0

}

unsafe fn deflate_stored(__param_s: *mut internal_state, __param_flush: i32) -> i32 {
    var __local_min_block: u32 = (((if (if (((*__param_s).pending_buf_size as u64) -% (5 as u64)) > (*__param_s).w_size: 1 else: 0) != 0: ((*__param_s).w_size as u64) else: ((((*__param_s).pending_buf_size as u64) -% (5 as u64)) as u64)) as u32))

    var __local_last: i32 = ((0 as i32))

    var __local_len: u32

    var __local_left: u32

    var __local_have: u32


    var __local_used: u32 = (*(*__param_s).strm).avail_in

    loop {
        (__local_len = ((65535 as u32)))

        (__local_have = (((((((*__param_s).bi_valid as u32) +% (42 as u32)) as u32) >> (3 as u32)) as u32)))

        if ((if (*(*__param_s).strm).avail_out < __local_have: 1 else: 0) != 0) {
            break
        }

        (__local_have = (((((*(*__param_s).strm).avail_out as u32) -% (__local_have as u32)) as u32)))

        (__local_left = ((((*__param_s).strstart - (*__param_s).block_start) as u32)))

        if ((if __local_len > ((__local_left as u64) +% ((*(*__param_s).strm).avail_in as u64)): 1 else: 0) != 0) {
            (__local_len = ((((__local_left as u32) +% ((*(*__param_s).strm).avail_in as u32)) as u32)))
        }

        if ((if __local_len > __local_have: 1 else: 0) != 0) {
            (__local_len = __local_have)
        }

        var __ci_expr_logic_3: i32 = 0

        if ((if __local_len < __local_min_block: 1 else: 0) != 0) {
            var __ci_expr_logic_2: i32

            var __ci_expr_logic_1: i32

            var __ci_expr_logic_0: i32 = 0

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
                (__ci_expr_logic_2 = (if (if __local_len != ((__local_left as u32) +% ((*(*__param_s).strm).avail_in as u32)): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_3 != 0) {
            break
        }


        var __ci_expr_ternary_5: i32 = 0

        var __ci_expr_logic_4: i32 = 0

        if ((if __param_flush == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_len == ((__local_left as u32) +% ((*(*__param_s).strm).avail_in as u32)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_ternary_5 = ((1 as i32)))
        } else {
            (__ci_expr_ternary_5 = ((0 as i32)))
        }

        (__local_last = __ci_expr_ternary_5)


        _tr_stored_block(__param_s, null, (0 as u64), __local_last)

        (((*__param_s).pending_buf[(((*__param_s).pending as u64) -% (4 as u64))]) = ((__local_len as u8)))

        (((*__param_s).pending_buf[(((*__param_s).pending as u64) -% (3 as u64))]) = ((((__local_len as u32) >> (8 as u32)) as u8)))

        (((*__param_s).pending_buf[(((*__param_s).pending as u64) -% (2 as u64))]) = (((~__local_len) as u8)))

        (((*__param_s).pending_buf[(((*__param_s).pending as u64) -% (1 as u64))]) = (((((~__local_len) as u32) >> (8 as u32)) as u8)))

        flush_pending((*__param_s).strm)

        if (__local_left != 0) {
            if ((if __local_left > __local_len: 1 else: 0) != 0) {
                (__local_left = __local_len)
            }

            with_memcpy((((*(*__param_s).strm).next_out as *mut c_void) as *mut u8), ((((*__param_s).window + (((*__param_s).block_start as isize) as usize)) as *const c_void) as *const u8), ((__local_left as u64) as i64))

            ((*(*__param_s).strm).next_out = (*(*__param_s).strm).next_out + (__local_left as usize))

            ((*(*__param_s).strm).avail_out = ((*(*__param_s).strm).avail_out -% __local_left))

            ((*(*__param_s).strm).total_out = ((*(*__param_s).strm).total_out +% __local_left))

            ((*__param_s).block_start = (*__param_s).block_start + __local_left)

            (__local_len = (__local_len -% __local_left))

        }

        if (__local_len != 0) {
            read_buf((*__param_s).strm, (*(*__param_s).strm).next_out, __local_len)

            ((*(*__param_s).strm).next_out = (*(*__param_s).strm).next_out + (__local_len as usize))

            ((*(*__param_s).strm).avail_out = ((*(*__param_s).strm).avail_out -% __local_len))

            ((*(*__param_s).strm).total_out = ((*(*__param_s).strm).total_out +% __local_len))

        }

        if not (((if __local_last == 0: 1 else: 0) != 0)) {
            break
        }
    }

    (__local_used = (__local_used -% (*(*__param_s).strm).avail_in))

    if (__local_used != 0) {
        if ((if __local_used >= (*__param_s).w_size: 1 else: 0) != 0) {
            ((*__param_s).matches = ((2 as u32)))

            with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*(*__param_s).strm).next_in - ((*__param_s).w_size as usize)) as *const c_void) as *const u8), (((*__param_s).w_size as u64) as i64))

            ((*__param_s).strstart = (*__param_s).w_size)

            ((*__param_s).insert = (*__param_s).strstart)

        } else {
            if ((if (((*__param_s).window_size as u64) -% ((*__param_s).strstart as u64)) <= __local_used: 1 else: 0) != 0) {
                ((*__param_s).strstart = ((*__param_s).strstart -% (*__param_s).w_size))

                with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).window + ((*__param_s).w_size as usize)) as *const c_void) as *const u8), (((*__param_s).strstart as u64) as i64))

                if ((if (*__param_s).matches < 2: 1 else: 0) != 0) {
                    ((*__param_s).matches = ((*__param_s).matches +% 1))
                }

                if ((if (*__param_s).insert > (*__param_s).strstart: 1 else: 0) != 0) {
                    ((*__param_s).insert = (*__param_s).strstart)
                }

            }

            with_memcpy(((((*__param_s).window + ((*__param_s).strstart as usize)) as *mut c_void) as *mut u8), ((((*(*__param_s).strm).next_in - (__local_used as usize)) as *const c_void) as *const u8), ((__local_used as u64) as i64))

            ((*__param_s).strstart = ((*__param_s).strstart +% __local_used))

            ((*__param_s).insert = ((*__param_s).insert +% (if (if __local_used > (((*__param_s).w_size as u32) -% ((*__param_s).insert as u32)): 1 else: 0) != 0: ((((*__param_s).w_size as u32) -% ((*__param_s).insert as u32)) as u32) else: __local_used)))

        }

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

    }

    if ((if (*__param_s).high_water < (*__param_s).strstart: 1 else: 0) != 0) {
        ((*__param_s).high_water = (((*__param_s).strstart as u64)))
    }

    if (__local_last != 0) {
        ((*__param_s).bi_used = ((8 as i32)))

        return 3

    }

    var __ci_expr_logic_8: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    if ((if __param_flush != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_6 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_7 = (if (if (*(*__param_s).strm).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        (__ci_expr_logic_8 = (if (if (((*__param_s).strstart as i64)) == (*__param_s).block_start: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_8 != 0) {
        return 1
    }


    (__local_have = (((((*__param_s).window_size as u64) -% ((*__param_s).strstart as u64)) as u32)))

    var __ci_expr_logic_9: i32 = 0

    if ((if (*(*__param_s).strm).avail_in > __local_have: 1 else: 0) != 0) {
        (__ci_expr_logic_9 = (if (if (*__param_s).block_start >= (((*__param_s).w_size as i64)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_9 != 0) {
        ((*__param_s).block_start = (*__param_s).block_start - (*__param_s).w_size)

        ((*__param_s).strstart = ((*__param_s).strstart -% (*__param_s).w_size))

        with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).window + ((*__param_s).w_size as usize)) as *const c_void) as *const u8), (((*__param_s).strstart as u64) as i64))

        if ((if (*__param_s).matches < 2: 1 else: 0) != 0) {
            ((*__param_s).matches = ((*__param_s).matches +% 1))
        }

        (__local_have = (__local_have +% (*__param_s).w_size))

        if ((if (*__param_s).insert > (*__param_s).strstart: 1 else: 0) != 0) {
            ((*__param_s).insert = (*__param_s).strstart)
        }

    }


    if ((if __local_have > (*(*__param_s).strm).avail_in: 1 else: 0) != 0) {
        (__local_have = (*(*__param_s).strm).avail_in)
    }

    if (__local_have != 0) {
        read_buf((*__param_s).strm, ((*__param_s).window + ((*__param_s).strstart as usize)), __local_have)

        ((*__param_s).strstart = ((*__param_s).strstart +% __local_have))

        ((*__param_s).insert = ((*__param_s).insert +% (if (if __local_have > (((*__param_s).w_size as u32) -% ((*__param_s).insert as u32)): 1 else: 0) != 0: ((((*__param_s).w_size as u32) -% ((*__param_s).insert as u32)) as u32) else: __local_have)))

    }

    if ((if (*__param_s).high_water < (*__param_s).strstart: 1 else: 0) != 0) {
        ((*__param_s).high_water = (((*__param_s).strstart as u64)))
    }

    (__local_have = (((((((*__param_s).bi_valid as u32) +% (42 as u32)) as u32) >> (3 as u32)) as u32)))

    (__local_have = (((if (if (((*__param_s).pending_buf_size as u64) -% (__local_have as u64)) > 65535: 1 else: 0) != 0: (65535 as u64) else: ((((*__param_s).pending_buf_size as u64) -% (__local_have as u64)) as u64)) as u32)))

    (__local_min_block = (((if (if __local_have > (*__param_s).w_size: 1 else: 0) != 0: (*__param_s).w_size else: __local_have) as u32)))

    (__local_left = ((((*__param_s).strstart - (*__param_s).block_start) as u32)))

    var __ci_expr_logic_14: i32

    if ((if __local_left >= __local_min_block: 1 else: 0) != 0) {
        (__ci_expr_logic_14 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_13: i32 = 0

        var __ci_expr_logic_12: i32 = 0

        var __ci_expr_logic_11: i32 = 0

        var __ci_expr_logic_10: i32

        if (__local_left != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if (if __param_flush == 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if (if __param_flush != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_11 != 0) {
            (__ci_expr_logic_12 = (if (if (*(*__param_s).strm).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_logic_13 = (if (if __local_left <= __local_have: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_14 = (if __ci_expr_logic_13 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_14 != 0) {
        (__local_len = (((if (if __local_left > __local_have: 1 else: 0) != 0: __local_have else: __local_left) as u32)))

        var __ci_expr_ternary_17: i32 = 0

        var __ci_expr_logic_16: i32 = 0

        var __ci_expr_logic_15: i32 = 0

        if ((if __param_flush == 4: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if (*(*__param_s).strm).avail_in == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_15 != 0) {
            (__ci_expr_logic_16 = (if (if __local_len == __local_left: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_16 != 0) {
            (__ci_expr_ternary_17 = ((1 as i32)))
        } else {
            (__ci_expr_ternary_17 = ((0 as i32)))
        }

        (__local_last = __ci_expr_ternary_17)


        _tr_stored_block(__param_s, (((*__param_s).window as *mut c_char) + (((*__param_s).block_start as isize) as usize)), (__local_len as u64), __local_last)

        ((*__param_s).block_start = (*__param_s).block_start + __local_len)

        flush_pending((*__param_s).strm)

    }


    if (__local_last != 0) {
        ((*__param_s).bi_used = ((8 as i32)))
    }

    return (if __local_last != 0: finish_started else: need_more)

}

unsafe fn deflate_fast(__param_s: *mut internal_state, __param_flush: i32) -> i32 {
    var __local_hash_head: u32

    var __local_bflush: i32

    while true {
        if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: i32 = 0

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

        (__local_hash_head = ((0 as u32)))

        if ((if (*__param_s).lookahead >= 3: 1 else: 0) != 0) {
            ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[(((*__param_s).strstart as u32) +% (2 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

            (((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) = ((((*__param_s).head[(*__param_s).ins_h]) as u16)))

            (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) as u32)))

            (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as u16)))


        }

        var __ci_expr_logic_1: i32 = 0

        if ((if __local_hash_head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (((*__param_s).strstart as u32) -% (__local_hash_head as u32)) <= (((*__param_s).w_size as u32) -% (262 as u32)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            ((*__param_s).match_length = ((longest_match(__param_s, __local_hash_head) as u32)))

        }


        if ((if (*__param_s).match_length >= 3: 1 else: 0) != 0) {

            var __local_len: u8 = (((((*__param_s).match_length as u32) -% (3 as u32)) as u8))

            var __local_dist: u16 = (((((*__param_s).strstart as u32) -% ((*__param_s).match_start as u32)) as u16))

            var __ci_expr_old_2: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_2]) = ((__local_dist as u8)))


            var __ci_expr_old_3: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_3]) = ((((__local_dist as i32) >> (8 as u32)) as u8)))


            var __ci_expr_old_4: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_4]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((*__param_s).dyn_ltree[(((_length_code[__local_len] as i32) + 256) + 1)].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[(((_length_code[__local_len] as i32) + 256) + 1)].fc as *const ct_data_s_fc)).freq +% 1))

            ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as i32) else: (_dist_code[(256 + ((__local_dist as i32) >> (7 as u32)))] as i32))].fc.freq = ((*(&raw const (*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as i32) else: (_dist_code[(256 + ((__local_dist as i32) >> (7 as u32)))] as i32))].fc as *const ct_data_s_fc)).freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% (*__param_s).match_length))

            var __ci_expr_logic_5: i32 = 0

            if ((if (*__param_s).match_length <= (*__param_s).max_lazy_match: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if (if (*__param_s).lookahead >= 3: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_5 != 0) {
                ((*__param_s).match_length = ((*__param_s).match_length -% 1))

                loop {
                    ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                    ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[(((*__param_s).strstart as u32) +% (2 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

                    (((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) = ((((*__param_s).head[(*__param_s).ins_h]) as u16)))

                    (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) as u32)))

                    (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as u16)))


                    ((*__param_s).match_length = ((*__param_s).match_length -% 1))
                    if not (((if (*__param_s).match_length != 0: 1 else: 0) != 0)) {
                        break
                    }
                }

                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

            } else {
                ((*__param_s).strstart = ((*__param_s).strstart +% (*__param_s).match_length))

                ((*__param_s).match_length = ((0 as u32)))

                ((*__param_s).ins_h = ((((*__param_s).window[(*__param_s).strstart]) as u32)))

                ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[(((*__param_s).strstart as u32) +% (1 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

            }


        } else {

            var __local_cc: u8 = ((((*__param_s).window[(*__param_s).strstart]) as u8))

            var __ci_expr_old_6: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_6]) = ((0 as u8)))


            var __ci_expr_old_7: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_7]) = ((0 as u8)))


            var __ci_expr_old_8: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_8]) = __local_cc)


            ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[__local_cc].fc as *const ct_data_s_fc)).freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

            ((*__param_s).strstart = ((*__param_s).strstart +% 1))

        }

        if (__local_bflush != 0) {
            _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

            ((*__param_s).block_start = (((*__param_s).strstart as i64)))

            flush_pending((*__param_s).strm)




            if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }


    }

    ((*__param_s).insert = (((if (if (*__param_s).strstart < 2: 1 else: 0) != 0: (*__param_s).strstart else: (2 as u32)) as u32)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (1 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn deflate_slow(__param_s: *mut internal_state, __param_flush: i32) -> i32 {
    var __local_hash_head: u32

    var __local_bflush: i32

    while true {
        if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: i32 = 0

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

        (__local_hash_head = ((0 as u32)))

        if ((if (*__param_s).lookahead >= 3: 1 else: 0) != 0) {
            ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[(((*__param_s).strstart as u32) +% (2 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

            (((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) = ((((*__param_s).head[(*__param_s).ins_h]) as u16)))

            (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) as u32)))

            (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as u16)))


        }

        ((*__param_s).prev_length = (*__param_s).match_length)

        ((*__param_s).prev_match = (*__param_s).match_start)


        ((*__param_s).match_length = ((2 as u32)))

        var __ci_expr_logic_2: i32 = 0

        var __ci_expr_logic_1: i32 = 0

        if ((if __local_hash_head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__param_s).prev_length < (*__param_s).max_lazy_match: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if (if (((*__param_s).strstart as u32) -% (__local_hash_head as u32)) <= (((*__param_s).w_size as u32) -% (262 as u32)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            ((*__param_s).match_length = ((longest_match(__param_s, __local_hash_head) as u32)))

            var __ci_expr_logic_5: i32 = 0

            if ((if (*__param_s).match_length <= 5: 1 else: 0) != 0) {
                var __ci_expr_logic_4: i32

                if ((if (*__param_s).strategy == 1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_3: i32 = 0

                    if ((if (*__param_s).match_length == 3: 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if (if (((*__param_s).strstart as u32) -% ((*__param_s).match_start as u32)) > 4096: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

                }

                (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_5 != 0) {
                ((*__param_s).match_length = ((2 as u32)))

            }


        }


        var __ci_expr_logic_6: i32 = 0

        if ((if (*__param_s).prev_length >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (*__param_s).match_length <= (*__param_s).prev_length: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            var __local_max_insert: u32 = (((((((*__param_s).strstart as u32) +% ((*__param_s).lookahead as u32)) as u32) -% (3 as u32)) as u32))


            var __local_len: u8 = (((((*__param_s).prev_length as u32) -% (3 as u32)) as u8))

            var __local_dist: u16 = (((((((*__param_s).strstart as u32) -% (1 as u32)) as u32) -% ((*__param_s).prev_match as u32)) as u16))

            var __ci_expr_old_7: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_7]) = ((__local_dist as u8)))


            var __ci_expr_old_8: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_8]) = ((((__local_dist as i32) >> (8 as u32)) as u8)))


            var __ci_expr_old_9: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_9]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((*__param_s).dyn_ltree[(((_length_code[__local_len] as i32) + 256) + 1)].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[(((_length_code[__local_len] as i32) + 256) + 1)].fc as *const ct_data_s_fc)).freq +% 1))

            ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as i32) else: (_dist_code[(256 + ((__local_dist as i32) >> (7 as u32)))] as i32))].fc.freq = ((*(&raw const (*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as i32) else: (_dist_code[(256 + ((__local_dist as i32) >> (7 as u32)))] as i32))].fc as *const ct_data_s_fc)).freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% (((*__param_s).prev_length as u32) -% (1 as u32))))

            ((*__param_s).prev_length = ((*__param_s).prev_length -% 2))

            loop {
                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                if ((if (*__param_s).strstart <= __local_max_insert: 1 else: 0) != 0) {
                    ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[(((*__param_s).strstart as u32) +% (2 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

                    (((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) = ((((*__param_s).head[(*__param_s).ins_h]) as u16)))

                    (__local_hash_head = ((((*__param_s).prev[(((*__param_s).strstart as u32) & ((*__param_s).w_mask as u32))]) as u32)))

                    (((*__param_s).head[(*__param_s).ins_h]) = (((*__param_s).strstart as u16)))


                }


                ((*__param_s).prev_length = ((*__param_s).prev_length -% 1))
                if not (((if (*__param_s).prev_length != 0: 1 else: 0) != 0)) {
                    break
                }
            }

            ((*__param_s).match_available = ((0 as i32)))

            ((*__param_s).match_length = ((2 as u32)))

            ((*__param_s).strstart = ((*__param_s).strstart +% 1))

            if (__local_bflush != 0) {
                _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

                ((*__param_s).block_start = (((*__param_s).strstart as i64)))

                flush_pending((*__param_s).strm)




                if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
                    return 0
                }

            }


        } else {
            if ((*__param_s).match_available != 0) {

                var __local_cc: u8 = ((((*__param_s).window[(((*__param_s).strstart as u32) -% (1 as u32))]) as u8))

                var __ci_expr_old_10: u32 = (*__param_s).sym_next

                ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

                (((*__param_s).sym_buf[__ci_expr_old_10]) = ((0 as u8)))


                var __ci_expr_old_11: u32 = (*__param_s).sym_next

                ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

                (((*__param_s).sym_buf[__ci_expr_old_11]) = ((0 as u8)))


                var __ci_expr_old_12: u32 = (*__param_s).sym_next

                ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

                (((*__param_s).sym_buf[__ci_expr_old_12]) = __local_cc)


                ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[__local_cc].fc as *const ct_data_s_fc)).freq +% 1))

                (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



                if (__local_bflush != 0) {
                    _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

                    ((*__param_s).block_start = (((*__param_s).strstart as i64)))

                    flush_pending((*__param_s).strm)




                }

                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

                if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
                    return 0
                }

            } else {
                ((*__param_s).match_available = ((1 as i32)))

                ((*__param_s).strstart = ((*__param_s).strstart +% 1))

                ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

            }
        }


    }


    if ((*__param_s).match_available != 0) {

        var __local_cc_1: u8 = ((((*__param_s).window[(((*__param_s).strstart as u32) -% (1 as u32))]) as u8))

        var __ci_expr_old_13: u32 = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_13]) = ((0 as u8)))


        var __ci_expr_old_14: u32 = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_14]) = ((0 as u8)))


        var __ci_expr_old_15: u32 = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_15]) = __local_cc_1)


        ((*__param_s).dyn_ltree[__local_cc_1].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[__local_cc_1].fc as *const ct_data_s_fc)).freq +% 1))

        (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



        ((*__param_s).match_available = ((0 as i32)))

    }

    ((*__param_s).insert = (((if (if (*__param_s).strstart < 2: 1 else: 0) != 0: (*__param_s).strstart else: (2 as u32)) as u32)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (1 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn deflate_rle(__param_s: *mut internal_state, __param_flush: i32) -> i32 {
    var __local_bflush: i32

    var __local_prev: u32

    var __local_scan: *mut u8

    var __local_strend: *mut u8


    while true {
        if ((if (*__param_s).lookahead <= 258: 1 else: 0) != 0) {
            fill_window(__param_s)

            var __ci_expr_logic_0: i32 = 0

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

        ((*__param_s).match_length = ((0 as u32)))

        var __ci_expr_logic_1: i32 = 0

        if ((if (*__param_s).lookahead >= 3: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__param_s).strstart > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_scan = ((*__param_s).window + ((*__param_s).strstart as usize)) - ((1 as isize) as usize))

            (__local_prev = (((*__local_scan) as u32)))

            var __ci_expr_logic_3: i32 = 0

            var __ci_expr_logic_2: i32 = 0

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
                    var __ci_expr_logic_11: i32 = 0

                    var __ci_expr_logic_10: i32 = 0

                    var __ci_expr_logic_9: i32 = 0

                    var __ci_expr_logic_8: i32 = 0

                    var __ci_expr_logic_7: i32 = 0

                    var __ci_expr_logic_6: i32 = 0

                    var __ci_expr_logic_5: i32 = 0

                    var __ci_expr_logic_4: i32 = 0

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

                ((*__param_s).match_length = ((((258 as u32) -% (((((__local_strend as usize) -% (__local_scan as usize)) as i64) / (sizeof[u8]() as i64)) as u32)) as u32)))

                if ((if (*__param_s).match_length > (*__param_s).lookahead: 1 else: 0) != 0) {
                    ((*__param_s).match_length = (*__param_s).lookahead)
                }

            }



        }


        if ((if (*__param_s).match_length >= 3: 1 else: 0) != 0) {

            var __local_len: u8 = (((((*__param_s).match_length as u32) -% (3 as u32)) as u8))

            var __local_dist: u16 = ((1 as u16))

            var __ci_expr_old_12: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_12]) = ((__local_dist as u8)))


            var __ci_expr_old_13: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_13]) = ((((__local_dist as i32) >> (8 as u32)) as u8)))


            var __ci_expr_old_14: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_14]) = __local_len)


            (__local_dist = (__local_dist -% 1))

            ((*__param_s).dyn_ltree[(((_length_code[__local_len] as i32) + 256) + 1)].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[(((_length_code[__local_len] as i32) + 256) + 1)].fc as *const ct_data_s_fc)).freq +% 1))

            ((*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as i32) else: (_dist_code[(256 + ((__local_dist as i32) >> (7 as u32)))] as i32))].fc.freq = ((*(&raw const (*__param_s).dyn_dtree[(if (if __local_dist < 256: 1 else: 0) != 0: (_dist_code[__local_dist] as i32) else: (_dist_code[(256 + ((__local_dist as i32) >> (7 as u32)))] as i32))].fc as *const ct_data_s_fc)).freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% (*__param_s).match_length))

            ((*__param_s).strstart = ((*__param_s).strstart +% (*__param_s).match_length))

            ((*__param_s).match_length = ((0 as u32)))

        } else {

            var __local_cc: u8 = ((((*__param_s).window[(*__param_s).strstart]) as u8))

            var __ci_expr_old_15: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_15]) = ((0 as u8)))


            var __ci_expr_old_16: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_16]) = ((0 as u8)))


            var __ci_expr_old_17: u32 = (*__param_s).sym_next

            ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

            (((*__param_s).sym_buf[__ci_expr_old_17]) = __local_cc)


            ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[__local_cc].fc as *const ct_data_s_fc)).freq +% 1))

            (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



            ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

            ((*__param_s).strstart = ((*__param_s).strstart +% 1))

        }

        if (__local_bflush != 0) {
            _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

            ((*__param_s).block_start = (((*__param_s).strstart as i64)))

            flush_pending((*__param_s).strm)




            if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }


    }

    ((*__param_s).insert = ((0 as u32)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (1 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn deflate_huff(__param_s: *mut internal_state, __param_flush: i32) -> i32 {
    var __local_bflush: i32

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

        ((*__param_s).match_length = ((0 as u32)))


        var __local_cc: u8 = ((((*__param_s).window[(*__param_s).strstart]) as u8))

        var __ci_expr_old_0: u32 = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_0]) = ((0 as u8)))


        var __ci_expr_old_1: u32 = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_1]) = ((0 as u8)))


        var __ci_expr_old_2: u32 = (*__param_s).sym_next

        ((*__param_s).sym_next = ((*__param_s).sym_next +% 1))

        (((*__param_s).sym_buf[__ci_expr_old_2]) = __local_cc)


        ((*__param_s).dyn_ltree[__local_cc].fc.freq = ((*(&raw const (*__param_s).dyn_ltree[__local_cc].fc as *const ct_data_s_fc)).freq +% 1))

        (__local_bflush = (((if (*__param_s).sym_next == (*__param_s).sym_end: 1 else: 0) as i32)))



        ((*__param_s).lookahead = ((*__param_s).lookahead -% 1))

        ((*__param_s).strstart = ((*__param_s).strstart +% 1))

        if (__local_bflush != 0) {
            _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

            ((*__param_s).block_start = (((*__param_s).strstart as i64)))

            flush_pending((*__param_s).strm)




            if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
                return 0
            }

        }


    }

    ((*__param_s).insert = ((0 as u32)))

    if ((if __param_flush == 4: 1 else: 0) != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (1 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 2
        }



        return 3

    }

    if ((*__param_s).sym_next != 0) {
        _tr_flush_block(__param_s, (if (if (*__param_s).block_start >= 0: 1 else: 0) != 0: (((&raw const ((*__param_s).window[((*__param_s).block_start as u32)]) as *const u8) as *mut u8) as *mut c_char) else: (null as *mut c_char)), ((((*__param_s).strstart as i64) - (*__param_s).block_start) as u64), (0 as i32))

        ((*__param_s).block_start = (((*__param_s).strstart as i64)))

        flush_pending((*__param_s).strm)




        if ((if (*(*__param_s).strm).avail_out == 0: 1 else: 0) != 0) {
            return 0
        }

    }


    return 1

}

unsafe fn slide_hash(__param_s: *mut internal_state) {
    var __local_n: u32

    var __local_m: u32


    var __local_p: *mut u16

    var __local_wsize: u32 = (*__param_s).w_size

    (__local_n = (*__param_s).hash_size)

    (__local_p = (((&raw const ((*__param_s).head[__local_n]) as *const u16) as *mut u16)))

    loop {
        (__local_p = __local_p - 1)

        (__local_m = (((*__local_p) as u32)))


        ((*__local_p) = (((if (if __local_m >= __local_wsize: 1 else: 0) != 0: (((__local_m as u32) -% (__local_wsize as u32)) as u32) else: (0 as u32)) as u16)))

        (__local_n = (__local_n -% 1))
        if not ((__local_n != 0)) {
            break
        }
    }

    (__local_n = __local_wsize)

    (__local_p = (((&raw const ((*__param_s).prev[__local_n]) as *const u16) as *mut u16)))

    loop {
        (__local_p = __local_p - 1)

        (__local_m = (((*__local_p) as u32)))


        ((*__local_p) = (((if (if __local_m >= __local_wsize: 1 else: 0) != 0: (((__local_m as u32) -% (__local_wsize as u32)) as u32) else: (0 as u32)) as u16)))

        (__local_n = (__local_n -% 1))
        if not ((__local_n != 0)) {
            break
        }
    }

    ((*__param_s).slid = ((1 as i32)))

}

unsafe fn read_buf(__param_strm: *mut z_stream_s, __param_buf: *mut u8, __param_size: u32) -> u32 {
    var __local_len: u32 = (*__param_strm).avail_in

    if ((if __local_len > __param_size: 1 else: 0) != 0) {
        (__local_len = __param_size)
    }

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return ((0 as u32))
    }

    ((*__param_strm).avail_in = ((*__param_strm).avail_in -% __local_len))

    with_memcpy(((__param_buf as *mut c_void) as *mut u8), (((*__param_strm).next_in as *const c_void) as *const u8), ((__local_len as u64) as i64))

    if ((if (*(*__param_strm).state).wrap == 1: 1 else: 0) != 0) {
        ((*__param_strm).adler = ((adler32((*__param_strm).adler, (__param_buf as *const u8), __local_len) as u64)))

    } else {
        if ((if (*(*__param_strm).state).wrap == 2: 1 else: 0) != 0) {
            ((*__param_strm).adler = ((crc32((*__param_strm).adler, (__param_buf as *const u8), __local_len) as u64)))

        }
    }

    ((*__param_strm).next_in = (*__param_strm).next_in + (__local_len as usize))

    ((*__param_strm).total_in = ((*__param_strm).total_in +% __local_len))

    return __local_len

}

unsafe fn fill_window(__param_s: *mut internal_state) {
    var __local_n: u32

    var __local_more: u32

    var __local_wsize: u32 = (*__param_s).w_size


    loop {
        (__local_more = (((((((*__param_s).window_size as u64) -% ((*__param_s).lookahead as u64)) as u64) -% ((*__param_s).strstart as u64)) as u32)))

        if ((if (sizeof[i32]() as usize) <= 2: 1 else: 0) != 0) {
            var __ci_expr_logic_2: i32 = 0

            var __ci_expr_logic_1: i32 = 0

            if ((if __local_more == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if (*__param_s).strstart == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_2 = (if (if (*__param_s).lookahead == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__local_more = __local_wsize)

            } else {
                if ((if __local_more == ((-1 as u32)): 1 else: 0) != 0) {
                    (__local_more = (__local_more -% 1))

                }
            }


        }

        if ((if (*__param_s).strstart >= ((__local_wsize as u32) +% ((((*__param_s).w_size as u32) -% (262 as u32)) as u32)): 1 else: 0) != 0) {
            with_memcpy((((*__param_s).window as *mut c_void) as *mut u8), ((((*__param_s).window + (__local_wsize as usize)) as *const c_void) as *const u8), ((((__local_wsize as u32) -% (__local_more as u32)) as u64) as i64))

            ((*__param_s).match_start = ((*__param_s).match_start -% __local_wsize))

            ((*__param_s).strstart = ((*__param_s).strstart -% __local_wsize))

            ((*__param_s).block_start = (*__param_s).block_start - (__local_wsize as i64))

            if ((if (*__param_s).insert > (*__param_s).strstart: 1 else: 0) != 0) {
                ((*__param_s).insert = (*__param_s).strstart)
            }

            slide_hash(__param_s)

            (__local_more = (__local_more +% __local_wsize))

        }

        if ((if (*(*__param_s).strm).avail_in == 0: 1 else: 0) != 0) {
            break
        }


        (__local_n = ((read_buf((*__param_s).strm, (((*__param_s).window + ((*__param_s).strstart as usize)) + ((*__param_s).lookahead as usize)), __local_more) as u32)))

        ((*__param_s).lookahead = ((*__param_s).lookahead +% __local_n))

        if ((if (((*__param_s).lookahead as u32) +% ((*__param_s).insert as u32)) >= 3: 1 else: 0) != 0) {
            var __local_str: u32 = (((((*__param_s).strstart as u32) -% ((*__param_s).insert as u32)) as u32))

            ((*__param_s).ins_h = ((((*__param_s).window[__local_str]) as u32)))

            ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[((__local_str as u32) +% (1 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

            while ((*__param_s).insert != 0) {
                ((*__param_s).ins_h = (((((((((*__param_s).ins_h as u32) << ((*__param_s).hash_shift as u32)) as u32) ^ ((((*__param_s).window[((((__local_str as u32) +% (3 as u32)) as u32) -% (1 as u32))]) as i32) as u32)) as u32) & ((*__param_s).hash_mask as u32)) as u32)))

                (((*__param_s).prev[((__local_str as u32) & ((*__param_s).w_mask as u32))]) = ((((*__param_s).head[(*__param_s).ins_h]) as u16)))

                (((*__param_s).head[(*__param_s).ins_h]) = ((__local_str as u16)))

                (__local_str = (__local_str +% 1))

                ((*__param_s).insert = ((*__param_s).insert -% 1))

                if ((if (((*__param_s).lookahead as u32) +% ((*__param_s).insert as u32)) < 3: 1 else: 0) != 0) {
                    break
                }

            }

        }

        var __ci_expr_logic_0: i32 = 0

        if ((if (*__param_s).lookahead < 262: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (*(*__param_s).strm).avail_in != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    if ((if (*__param_s).high_water < (*__param_s).window_size: 1 else: 0) != 0) {
        var __local_curr: u64 = (((((*__param_s).strstart as u64) +% ((*__param_s).lookahead as u64)) as u64))

        var __local_init: u64

        if ((if (*__param_s).high_water < __local_curr: 1 else: 0) != 0) {
            (__local_init = (((((*__param_s).window_size as u64) -% (__local_curr as u64)) as u64)))

            if ((if __local_init > 258: 1 else: 0) != 0) {
                (__local_init = ((258 as u64)))
            }

            with_memset(((((*__param_s).window + (__local_curr as usize)) as *mut c_void) as *mut u8), (0 as i32), (((__local_init as u32) as u64) as i64))

            ((*__param_s).high_water = ((((__local_curr as u64) +% (__local_init as u64)) as u64)))

        } else {
            if ((if (*__param_s).high_water < ((__local_curr as u64) +% (258 as u64)): 1 else: 0) != 0) {
                (__local_init = ((((((__local_curr as u64) +% (258 as u64)) as u64) -% ((*__param_s).high_water as u64)) as u64)))

                if ((if __local_init > (((*__param_s).window_size as u64) -% ((*__param_s).high_water as u64)): 1 else: 0) != 0) {
                    (__local_init = (((((*__param_s).window_size as u64) -% ((*__param_s).high_water as u64)) as u64)))
                }

                with_memset(((((*__param_s).window + ((*__param_s).high_water as usize)) as *mut c_void) as *mut u8), (0 as i32), (((__local_init as u32) as u64) as i64))

                ((*__param_s).high_water = ((*__param_s).high_water +% __local_init))

            }
        }

    }


}

unsafe fn deflateStateCheck(__param_strm: *mut z_stream_s) -> i32 {
    var __local_s: *mut internal_state

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if ((if __param_strm == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_strm).zalloc == ((0 as unsafe extern "C" fn(*mut c_void, u32, u32) -> *mut c_void)): 1 else: 0) != 0: 1 else: 0))
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

    var __ci_expr_logic_10: i32

    var __ci_expr_logic_2: i32

    if ((if __local_s == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (*__local_s).strm != __param_strm: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_10 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_9: i32 = 0

        var __ci_expr_logic_8: i32 = 0

        var __ci_expr_logic_7: i32 = 0

        var __ci_expr_logic_6: i32 = 0

        var __ci_expr_logic_5: i32 = 0

        var __ci_expr_logic_4: i32 = 0

        var __ci_expr_logic_3: i32 = 0

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
    ((*__param_s).window_size = ((((2 as u64) *% ((*__param_s).w_size as u64)) as u64)))

    loop {
        (((*__param_s).head[(((*__param_s).hash_size as u32) -% (1 as u32))]) = ((0 as u16)))

        with_memset((((*__param_s).head as *mut c_void) as *mut u8), (0 as i32), (((((((*__param_s).hash_size as u32) -% (1 as u32)) as u64) *% (sizeof[u16]() as u64)) as u64) as i64))

        ((*__param_s).slid = ((0 as i32)))

        if not ((0 != 0)) {
            break
        }
    }

    ((*__param_s).max_lazy_match = ((configuration_table[(*__param_s).level].max_lazy as u32)))

    ((*__param_s).good_match = ((configuration_table[(*__param_s).level].good_length as u32)))

    ((*__param_s).nice_match = ((configuration_table[(*__param_s).level].nice_length as i32)))

    ((*__param_s).max_chain_length = ((configuration_table[(*__param_s).level].max_chain as u32)))

    ((*__param_s).strstart = ((0 as u32)))

    ((*__param_s).block_start = ((0 as i64)))

    ((*__param_s).lookahead = ((0 as u32)))

    ((*__param_s).insert = ((0 as u32)))

    ((*__param_s).prev_length = ((2 as u32)))

    ((*__param_s).match_length = (*__param_s).prev_length)


    ((*__param_s).match_available = ((0 as i32)))

    ((*__param_s).ins_h = ((0 as u32)))

}

unsafe fn putShortMSB(__param_s: *mut internal_state, __param_b: u32) {
    var __ci_expr_old_0: u64 = (*__param_s).pending

    ((*__param_s).pending = ((*__param_s).pending +% 1))

    (((*__param_s).pending_buf[__ci_expr_old_0]) = ((((__param_b as u32) >> (8 as u32)) as u8)))




    var __ci_expr_old_1: u64 = (*__param_s).pending

    ((*__param_s).pending = ((*__param_s).pending +% 1))

    (((*__param_s).pending_buf[__ci_expr_old_1]) = ((((__param_b as u32) & (255 as u32)) as u8)))




}

unsafe fn flush_pending(__param_strm: *mut z_stream_s) {
    var __local_len: u32

    var __local_s: *mut internal_state = (*__param_strm).state

    _tr_flush_bits(__local_s)

    (__local_len = (((if (if (*__local_s).pending > (*__param_strm).avail_out: 1 else: 0) != 0: (*__param_strm).avail_out else: ((*__local_s).pending as u32)) as u32)))

    if ((if __local_len == 0: 1 else: 0) != 0) {
        return
    }

    with_memcpy((((*__param_strm).next_out as *mut c_void) as *mut u8), (((*__local_s).pending_out as *const c_void) as *const u8), ((__local_len as u64) as i64))

    ((*__param_strm).next_out = (*__param_strm).next_out + (__local_len as usize))

    ((*__local_s).pending_out = (*__local_s).pending_out + (__local_len as usize))

    ((*__param_strm).total_out = ((*__param_strm).total_out +% __local_len))

    ((*__param_strm).avail_out = ((*__param_strm).avail_out -% __local_len))

    ((*__local_s).pending = ((*__local_s).pending -% __local_len))

    if ((if (*__local_s).pending == 0: 1 else: 0) != 0) {
        ((*__local_s).pending_out = (*__local_s).pending_buf)

    }

}

unsafe fn longest_match(__param_s: *mut internal_state, __param_cur_match: u32) -> u32 {
    var __local_cur_match = __param_cur_match
    var __local_chain_length: u32 = (*__param_s).max_chain_length

    var __local_scan: *mut u8 = ((*__param_s).window + ((*__param_s).strstart as usize))

    var __local_match_: *mut u8

    var __local_len: i32

    var __local_best_len: i32 = (((*__param_s).prev_length as i32))

    var __local_nice_match: i32 = (*__param_s).nice_match

    var __local_limit: u32 = (((if (if (*__param_s).strstart > (((*__param_s).w_size as u32) -% (262 as u32)): 1 else: 0) != 0: ((((*__param_s).strstart as u32) -% ((((*__param_s).w_size as u32) -% (262 as u32)) as u32)) as u32) else: (0 as u32)) as u32))

    var __local_prev: *mut u16 = (*__param_s).prev

    var __local_wmask: u32 = (*__param_s).w_mask

    var __local_strend: *mut u8 = (((*__param_s).window + ((*__param_s).strstart as usize)) + ((258 as isize) as usize))

    var __local_scan_end1: u8 = (((__local_scan[(__local_best_len - 1)]) as u8))

    var __local_scan_end: u8 = (((__local_scan[__local_best_len]) as u8))


    if ((if (*__param_s).prev_length >= (*__param_s).good_match: 1 else: 0) != 0) {
        (__local_chain_length = __local_chain_length >> (2 as u32))

    }

    if ((if ((__local_nice_match as u32)) > (*__param_s).lookahead: 1 else: 0) != 0) {
        (__local_nice_match = (((*__param_s).lookahead as i32)))
    }


    loop {

        (__local_match_ = (*__param_s).window + (__local_cur_match as usize))

        var __ci_expr_logic_3: i32

        var __ci_expr_logic_2: i32

        var __ci_expr_logic_1: i32

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
            var __ci_expr_logic_0: i32 = 0

            (__local_cur_match = (((__local_prev[((__local_cur_match as u32) & (__local_wmask as u32))]) as u32)))

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
            var __ci_expr_logic_11: i32 = 0

            var __ci_expr_logic_10: i32 = 0

            var __ci_expr_logic_9: i32 = 0

            var __ci_expr_logic_8: i32 = 0

            var __ci_expr_logic_7: i32 = 0

            var __ci_expr_logic_6: i32 = 0

            var __ci_expr_logic_5: i32 = 0

            var __ci_expr_logic_4: i32 = 0

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


        (__local_len = (((258 - (((((__local_strend as usize) -% (__local_scan as usize)) as i64) / (sizeof[u8]() as i64)) as i32)) as i32)))

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

        var __ci_expr_logic_0: i32 = 0

        (__local_cur_match = (((__local_prev[((__local_cur_match as u32) & (__local_wmask as u32))]) as u32)))

        if ((if __local_cur_match > __local_limit: 1 else: 0) != 0) {
            (__local_chain_length = (__local_chain_length -% 1))

            (__ci_expr_logic_0 = (if (if __local_chain_length != 0: 1 else: 0) != 0: 1 else: 0))

        }

        if not ((__ci_expr_logic_0 != 0)) {
            break
        }
    }

    if ((if ((__local_best_len as u32)) <= (*__param_s).lookahead: 1 else: 0) != 0) {
        return ((__local_best_len as u32))
    }

    return (*__param_s).lookahead

}

let configuration_table: List[config_s] = [config_s { good_length: 0, max_lazy: 0, nice_length: 0, max_chain: 0, func: Some(deflate_stored) }, config_s { good_length: 4, max_lazy: 4, nice_length: 8, max_chain: 4, func: Some(deflate_fast) }, config_s { good_length: 4, max_lazy: 5, nice_length: 16, max_chain: 8, func: Some(deflate_fast) }, config_s { good_length: 4, max_lazy: 6, nice_length: 32, max_chain: 32, func: Some(deflate_fast) }, config_s { good_length: 4, max_lazy: 4, nice_length: 16, max_chain: 16, func: Some(deflate_slow) }, config_s { good_length: 8, max_lazy: 16, nice_length: 32, max_chain: 32, func: Some(deflate_slow) }, config_s { good_length: 8, max_lazy: 16, nice_length: 128, max_chain: 128, func: Some(deflate_slow) }, config_s { good_length: 8, max_lazy: 32, nice_length: 128, max_chain: 256, func: Some(deflate_slow) }, config_s { good_length: 32, max_lazy: 128, nice_length: 258, max_chain: 1024, func: Some(deflate_slow) }, config_s { good_length: 32, max_lazy: 258, nice_length: 258, max_chain: 4096, func: Some(deflate_slow) }]
