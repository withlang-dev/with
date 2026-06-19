// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
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
use std.zlib.inffast

pub unsafe fn inflate(__param_strm: *mut z_stream_s, __param_flush: c_int) -> c_int {
    var __local_state__goto_475_31: *mut inflate_state = null

    var __local_next__goto_476_32: *mut u8 = null

    var __local_put__goto_477_24: *mut u8 = null

    var __local_have__goto_478_14: c_uint = 0

    var __local_left__goto_478_20: c_uint = 0

    var __local_hold__goto_479_19: c_ulong = 0

    var __local_bits__goto_480_14: c_uint = 0

    var __local_in___goto_481_14: c_uint = 0

    var __local_out__goto_481_18: c_uint = 0

    var __local_copy___goto_482_14: c_uint = 0

    var __local_from__goto_483_24: *mut u8 = null

    var __local_here__goto_484_10: code

    var __local_last__goto_485_10: code

    var __local_len__goto_486_14: c_uint = 0

    var __local_ret__goto_487_9: c_int = 0

    var __local_hbuf__goto_489_19: [4]u8

    var __local_order__goto_491_33: [19]c_ushort

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_old_3: *mut u8 = null

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_ternary_7: c_int = 0

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_old_10: *mut u8 = null

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_old_12: *mut u8 = null

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_old_14: *mut u8 = null

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_ternary_18: c_uint = 0

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_old_20: c_uint = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_21: c_int = 0

    var __ci_expr_old_23: c_uint = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_old_26: c_uint = 0

    var __ci_expr_logic_28: c_int = 0

    var __ci_expr_logic_27: c_int = 0

    var __ci_expr_old_29: c_uint = 0

    var __ci_expr_logic_30: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_old_32: *mut u8 = null

    var __ci_expr_logic_33: c_int = 0

    var __ci_expr_old_34: *mut u8 = null

    var __ci_expr_logic_35: c_int = 0

    var __ci_expr_old_36: *mut u8 = null

    var __ci_expr_old_37: *mut u8 = null

    var __ci_expr_old_38: *mut u8 = null

    var __ci_expr_logic_39: c_int = 0

    var __ci_expr_old_40: *mut u8 = null

    var __ci_expr_old_41: c_uint = 0

    var __ci_expr_old_42: c_uint = 0

    var __ci_expr_old_43: *mut u8 = null

    var __ci_expr_old_44: c_uint = 0

    var __ci_expr_old_45: *mut u8 = null

    var __ci_expr_old_46: *mut u8 = null

    var __ci_expr_old_47: *mut u8 = null

    var __ci_expr_old_48: c_uint = 0

    var __ci_expr_old_49: c_uint = 0

    var __ci_expr_logic_50: c_int = 0

    var __ci_expr_old_51: *mut u8 = null

    var __ci_expr_logic_52: c_int = 0

    var __ci_expr_old_53: *mut u8 = null

    var __ci_expr_old_54: *mut u8 = null

    var __ci_expr_old_55: *mut u8 = null

    var __ci_expr_old_56: *mut u8 = null

    var __ci_expr_old_57: *mut u8 = null

    var __ci_expr_old_58: *mut u8 = null

    var __ci_expr_old_59: *mut u8 = null

    var __ci_expr_old_60: *mut u8 = null

    var __ci_expr_old_61: *mut u8 = null

    var __ci_expr_logic_62: c_int = 0

    var __ci_expr_ternary_63: c_ulong = 0

    var __ci_expr_logic_65: c_int = 0

    var __ci_expr_logic_66: c_int = 0

    var __ci_expr_old_67: *mut u8 = null

    var __ci_expr_logic_68: c_int = 0

    var __ci_expr_logic_72: c_int = 0

    var __ci_expr_logic_73: c_int = 0

    var __ci_expr_ternary_74: c_ulong = 0

    var __ci_expr_ternary_75: c_int = 0

    var __ci_expr_ternary_76: c_int = 0

    var __ci_expr_ternary_78: c_int = 0

    var __ci_expr_logic_77: c_int = 0

    var __ci_expr_logic_81: c_int = 0

    var __ci_expr_logic_80: c_int = 0

    var __ci_expr_logic_79: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_order__goto_491_33 = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15])
        if (inflateStateCheck(__param_strm) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe *__param_strm).next_out == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_1: c_int = 0

            if ((if (unsafe *__param_strm).next_in == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if (unsafe *__param_strm).avail_in != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        return -2
    }

    '__ci_bb_2 {
        (__local_state__goto_475_31 = (((unsafe *__param_strm).state as *mut inflate_state)))
        if ((if (unsafe *__local_state__goto_475_31).mode == 16191: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_3 {
        ((unsafe *__local_state__goto_475_31).mode = ((16192 as i32)))
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        goto '__ci_bb_5
    }

    '__ci_bb_5 {
        (__local_put__goto_477_24 = (unsafe *__param_strm).next_out)
        (__local_left__goto_478_20 = (unsafe *__param_strm).avail_out)
        (__local_next__goto_476_32 = (unsafe *__param_strm).next_in)
        (__local_have__goto_478_14 = (unsafe *__param_strm).avail_in)
        (__local_hold__goto_479_19 = (unsafe *__local_state__goto_475_31).hold)
        (__local_bits__goto_480_14 = (unsafe *__local_state__goto_475_31).bits)
        goto '__ci_bb_6
    }

    '__ci_bb_6 {
        if (0 != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_7 {
        (__local_in___goto_481_14 = __local_have__goto_478_14)
        (__local_out__goto_481_18 = __local_left__goto_478_20)
        (__local_ret__goto_487_9 = ((0 as c_int)))
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        goto '__ci_bb_8
    }

    '__ci_bb_12 {
        if ((unsafe *__local_state__goto_475_31).mode == 16180) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_637
        }
    }

    '__ci_bb_13 {
        goto '__ci_bb_10
    }

    '__ci_bb_14 {
        if ((if (unsafe *__local_state__goto_475_31).wrap == 0: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_15 {
        ((unsafe *__local_state__goto_475_31).mode = ((16192 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_16 {
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        goto '__ci_bb_20
    }

    '__ci_bb_18 {
        if (0 != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_19 {
        (__ci_expr_logic_4 = 0)
        if ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (2 as c_int)) != 0) {
            (__ci_expr_logic_4 = (if (if __local_hold__goto_479_19 == 35615: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_20 {
        if ((if __local_bits__goto_480_14 < ((16 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_21 {
        goto '__ci_bb_23
    }

    '__ci_bb_22 {
        goto '__ci_bb_18
    }

    '__ci_bb_23 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_24 {
        if (0 != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_25 {
        goto '__ci_bb_20
    }

    '__ci_bb_26 {
        goto '__ci_bb_28
    }

    '__ci_bb_27 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_3 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_3) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_24
    }

    '__ci_bb_28 {
        goto '__ci_bb_668
    }

    '__ci_bb_29 {
        if ((if (unsafe *__local_state__goto_475_31).wbits == 0: 1 else: 0) != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_30 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_31 {
        ((unsafe *__local_state__goto_475_31).wbits = ((15 as c_uint)))
        goto '__ci_bb_32
    }

    '__ci_bb_32 {
        ((unsafe *__local_state__goto_475_31).check = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))
        goto '__ci_bb_33
    }

    '__ci_bb_33 {
        (__local_hbuf__goto_489_19[0] = ((__local_hold__goto_479_19 as u8)))
        (__local_hbuf__goto_489_19[1] = ((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as u8)))
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (&__local_hbuf__goto_489_19[0] as *mut u8), (2 as c_uint)) as c_ulong)))
        goto '__ci_bb_34
    }

    '__ci_bb_34 {
        if (0 != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_35 {
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_37
    }

    '__ci_bb_37 {
        if (0 != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_38 {
        ((unsafe *__local_state__goto_475_31).mode = ((16181 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_39 {
        ((unsafe *__local_state__goto_475_31).head.done = ((-1 as c_int)))
        goto '__ci_bb_40
    }

    '__ci_bb_40 {
        if ((if not ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (1 as c_int)) != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_5 = (if (((((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (8 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) << (8 as c_uint)) as c_ulong) +% (((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as c_ulong)) as c_ulong) % (31 as c_ulong)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_41 {
        ((unsafe *__param_strm).msg = (("incorrect header check" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_42 {
        if ((if (((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (4 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) != 8: 1 else: 0) != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        ((unsafe *__param_strm).msg = (("unknown compression method" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_44 {
        goto '__ci_bb_45
    }

    '__ci_bb_45 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (4 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (4 as c_uint)))
        goto '__ci_bb_46
    }

    '__ci_bb_46 {
        if (0 != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_47 {
        (__local_len__goto_486_14 = (((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (4 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (8 as c_uint)) as c_uint)))
        if ((if (unsafe *__local_state__goto_475_31).wbits == 0: 1 else: 0) != 0) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_48 {
        ((unsafe *__local_state__goto_475_31).wbits = __local_len__goto_486_14)
        goto '__ci_bb_49
    }

    '__ci_bb_49 {
        if ((if __local_len__goto_486_14 > 15: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if __local_len__goto_486_14 > (unsafe *__local_state__goto_475_31).wbits: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_50 {
        ((unsafe *__param_strm).msg = (("invalid window size" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_51 {
        ((unsafe *__local_state__goto_475_31).dmax = ((((1 as c_uint) << (__local_len__goto_486_14 as c_uint)) as c_uint)))
        ((unsafe *__local_state__goto_475_31).flags = ((0 as c_int)))
        ((unsafe *__local_state__goto_475_31).check = ((adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))
        ((unsafe *__param_strm).adler = (unsafe *__local_state__goto_475_31).check)
        (__ci_expr_ternary_7 = 0)
        if (((__local_hold__goto_479_19 as c_ulong) & (512 as c_ulong)) != 0) {
            (__ci_expr_ternary_7 = DICTID)
        } else {
            (__ci_expr_ternary_7 = TYPE)
        }
        ((unsafe *__local_state__goto_475_31).mode = ((__ci_expr_ternary_7 as i32)))
        goto '__ci_bb_52
    }

    '__ci_bb_52 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_53
    }

    '__ci_bb_53 {
        if (0 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        goto '__ci_bb_13
    }

    '__ci_bb_55 {
        goto '__ci_bb_56
    }

    '__ci_bb_56 {
        goto '__ci_bb_59
    }

    '__ci_bb_57 {
        if (0 != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_58 {
        ((unsafe *__local_state__goto_475_31).flags = ((__local_hold__goto_479_19 as c_int)))
        if ((if (((unsafe *__local_state__goto_475_31).flags as c_int) & (255 as c_int)) != 8: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_59 {
        if ((if __local_bits__goto_480_14 < ((16 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_60 {
        goto '__ci_bb_62
    }

    '__ci_bb_61 {
        goto '__ci_bb_57
    }

    '__ci_bb_62 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_63 {
        if (0 != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_64 {
        goto '__ci_bb_59
    }

    '__ci_bb_65 {
        goto '__ci_bb_28
    }

    '__ci_bb_66 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_8 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_8) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_63
    }

    '__ci_bb_67 {
        ((unsafe *__param_strm).msg = (("unknown compression method" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_68 {
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (57344 as c_int)) != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_69 {
        ((unsafe *__param_strm).msg = (("unknown header flags set" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_70 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_71 {
        ((unsafe *__local_state__goto_475_31).head.text = ((((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as c_ulong) & (1 as c_ulong)) as c_int)))
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        (__ci_expr_logic_9 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_9 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_73 {
        goto '__ci_bb_75
    }

    '__ci_bb_74 {
        goto '__ci_bb_78
    }

    '__ci_bb_75 {
        (__local_hbuf__goto_489_19[0] = ((__local_hold__goto_479_19 as u8)))
        (__local_hbuf__goto_489_19[1] = ((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as u8)))
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (&__local_hbuf__goto_489_19[0] as *mut u8), (2 as c_uint)) as c_ulong)))
        goto '__ci_bb_76
    }

    '__ci_bb_76 {
        if (0 != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_74
    }

    '__ci_bb_78 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_79
    }

    '__ci_bb_79 {
        if (0 != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_80 {
        ((unsafe *__local_state__goto_475_31).mode = ((16182 as i32)))
        goto '__ci_bb_81
    }

    '__ci_bb_81 {
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        goto '__ci_bb_85
    }

    '__ci_bb_83 {
        if (0 != 0) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_84 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_94
        }
    }

    '__ci_bb_85 {
        if ((if __local_bits__goto_480_14 < ((32 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_86 {
        goto '__ci_bb_88
    }

    '__ci_bb_87 {
        goto '__ci_bb_83
    }

    '__ci_bb_88 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_89 {
        if (0 != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_90 {
        goto '__ci_bb_85
    }

    '__ci_bb_91 {
        goto '__ci_bb_28
    }

    '__ci_bb_92 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_10 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_10) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_89
    }

    '__ci_bb_93 {
        ((unsafe *__local_state__goto_475_31).head.time = __local_hold__goto_479_19)
        goto '__ci_bb_94
    }

    '__ci_bb_94 {
        (__ci_expr_logic_11 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_11 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_95
        } else {
            goto '__ci_bb_96
        }
    }

    '__ci_bb_95 {
        goto '__ci_bb_97
    }

    '__ci_bb_96 {
        goto '__ci_bb_100
    }

    '__ci_bb_97 {
        (__local_hbuf__goto_489_19[0] = ((__local_hold__goto_479_19 as u8)))
        (__local_hbuf__goto_489_19[1] = ((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as u8)))
        (__local_hbuf__goto_489_19[2] = ((((__local_hold__goto_479_19 as c_ulong) >> (16 as c_uint)) as u8)))
        (__local_hbuf__goto_489_19[3] = ((((__local_hold__goto_479_19 as c_ulong) >> (24 as c_uint)) as u8)))
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (&__local_hbuf__goto_489_19[0] as *mut u8), (4 as c_uint)) as c_ulong)))
        goto '__ci_bb_98
    }

    '__ci_bb_98 {
        if (0 != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_99 {
        goto '__ci_bb_96
    }

    '__ci_bb_100 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_101
    }

    '__ci_bb_101 {
        if (0 != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_102 {
        ((unsafe *__local_state__goto_475_31).mode = ((16183 as i32)))
        goto '__ci_bb_103
    }

    '__ci_bb_103 {
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        goto '__ci_bb_107
    }

    '__ci_bb_105 {
        if (0 != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_106 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_107 {
        if ((if __local_bits__goto_480_14 < ((16 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_108 {
        goto '__ci_bb_110
    }

    '__ci_bb_109 {
        goto '__ci_bb_105
    }

    '__ci_bb_110 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_111 {
        if (0 != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_112
        }
    }

    '__ci_bb_112 {
        goto '__ci_bb_107
    }

    '__ci_bb_113 {
        goto '__ci_bb_28
    }

    '__ci_bb_114 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_12 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_12) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_111
    }

    '__ci_bb_115 {
        ((unsafe *__local_state__goto_475_31).head.xflags = ((((__local_hold__goto_479_19 as c_ulong) & (255 as c_ulong)) as c_int)))
        ((unsafe *__local_state__goto_475_31).head.os = ((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as c_int)))
        goto '__ci_bb_116
    }

    '__ci_bb_116 {
        (__ci_expr_logic_13 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_13 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_118
        }
    }

    '__ci_bb_117 {
        goto '__ci_bb_119
    }

    '__ci_bb_118 {
        goto '__ci_bb_122
    }

    '__ci_bb_119 {
        (__local_hbuf__goto_489_19[0] = ((__local_hold__goto_479_19 as u8)))
        (__local_hbuf__goto_489_19[1] = ((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as u8)))
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (&__local_hbuf__goto_489_19[0] as *mut u8), (2 as c_uint)) as c_ulong)))
        goto '__ci_bb_120
    }

    '__ci_bb_120 {
        if (0 != 0) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_121
        }
    }

    '__ci_bb_121 {
        goto '__ci_bb_118
    }

    '__ci_bb_122 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_123
    }

    '__ci_bb_123 {
        if (0 != 0) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_124
        }
    }

    '__ci_bb_124 {
        ((unsafe *__local_state__goto_475_31).mode = ((16184 as i32)))
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (1024 as c_int)) != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_126 {
        goto '__ci_bb_129
    }

    '__ci_bb_127 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_128 {
        ((unsafe *__local_state__goto_475_31).mode = ((16185 as i32)))
        goto '__ci_bb_152
    }

    '__ci_bb_129 {
        goto '__ci_bb_132
    }

    '__ci_bb_130 {
        if (0 != 0) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_131 {
        ((unsafe *__local_state__goto_475_31).length = ((__local_hold__goto_479_19 as c_uint)))
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_132 {
        if ((if __local_bits__goto_480_14 < ((16 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_133 {
        goto '__ci_bb_135
    }

    '__ci_bb_134 {
        goto '__ci_bb_130
    }

    '__ci_bb_135 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_136 {
        if (0 != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_137 {
        goto '__ci_bb_132
    }

    '__ci_bb_138 {
        goto '__ci_bb_28
    }

    '__ci_bb_139 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_14 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_14) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_136
    }

    '__ci_bb_140 {
        ((unsafe *__local_state__goto_475_31).head.extra_len = ((__local_hold__goto_479_19 as c_uint)))
        goto '__ci_bb_141
    }

    '__ci_bb_141 {
        (__ci_expr_logic_15 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_15 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_142 {
        goto '__ci_bb_144
    }

    '__ci_bb_143 {
        goto '__ci_bb_147
    }

    '__ci_bb_144 {
        (__local_hbuf__goto_489_19[0] = ((__local_hold__goto_479_19 as u8)))
        (__local_hbuf__goto_489_19[1] = ((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as u8)))
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (&__local_hbuf__goto_489_19[0] as *mut u8), (2 as c_uint)) as c_ulong)))
        goto '__ci_bb_145
    }

    '__ci_bb_145 {
        if (0 != 0) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_146 {
        goto '__ci_bb_143
    }

    '__ci_bb_147 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_148
    }

    '__ci_bb_148 {
        if (0 != 0) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_149 {
        goto '__ci_bb_128
    }

    '__ci_bb_150 {
        ((unsafe *__local_state__goto_475_31).head.extra = null)
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        goto '__ci_bb_128
    }

    '__ci_bb_152 {
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (1024 as c_int)) != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_153 {
        (__local_copy___goto_482_14 = (unsafe *__local_state__goto_475_31).length)
        if ((if __local_copy___goto_482_14 > __local_have__goto_478_14: 1 else: 0) != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_154 {
        ((unsafe *__local_state__goto_475_31).length = ((0 as c_uint)))
        ((unsafe *__local_state__goto_475_31).mode = ((16186 as i32)))
        goto '__ci_bb_165
    }

    '__ci_bb_155 {
        (__local_copy___goto_482_14 = __local_have__goto_478_14)
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        if (__local_copy___goto_482_14 != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_157 {
        (__ci_expr_logic_17 = 0)
        (__ci_expr_logic_16 = 0)
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if (unsafe *__local_state__goto_475_31).head.extra != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            (__local_len__goto_486_14 = (((((unsafe *__local_state__goto_475_31).head.extra_len as c_uint) -% ((unsafe *__local_state__goto_475_31).length as c_uint)) as c_uint)))

            (__ci_expr_logic_17 = (if (if __local_len__goto_486_14 < (unsafe *__local_state__goto_475_31).head.extra_max: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_158 {
        if ((unsafe *__local_state__goto_475_31).length != 0) {
            goto '__ci_bb_163
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_159 {
        (__ci_expr_ternary_18 = 0)
        if ((if ((__local_len__goto_486_14 as c_uint) +% (__local_copy___goto_482_14 as c_uint)) > (unsafe *__local_state__goto_475_31).head.extra_max: 1 else: 0) != 0) {
            (__ci_expr_ternary_18 = (((((unsafe *__local_state__goto_475_31).head.extra_max as c_uint) -% (__local_len__goto_486_14 as c_uint)) as c_uint)))
        } else {
            (__ci_expr_ternary_18 = __local_copy___goto_482_14)
        }
        with_memcpy(((((unsafe *__local_state__goto_475_31).head.extra + (__local_len__goto_486_14 as usize)) as *mut c_void) as *i8), ((__local_next__goto_476_32 as *const c_void) as *i8), ((__ci_expr_ternary_18 as c_ulong) as i64))
        goto '__ci_bb_160
    }

    '__ci_bb_160 {
        (__ci_expr_logic_19 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_19 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_161 {
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (__local_next__goto_476_32 as *const u8), __local_copy___goto_482_14) as c_ulong)))
        goto '__ci_bb_162
    }

    '__ci_bb_162 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% __local_copy___goto_482_14))
        (__local_next__goto_476_32 = __local_next__goto_476_32 + (__local_copy___goto_482_14 as usize))
        ((unsafe *__local_state__goto_475_31).length = ((unsafe *__local_state__goto_475_31).length -% __local_copy___goto_482_14))
        goto '__ci_bb_158
    }

    '__ci_bb_163 {
        goto '__ci_bb_28
    }

    '__ci_bb_164 {
        goto '__ci_bb_154
    }

    '__ci_bb_165 {
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (2048 as c_int)) != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_166 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_167 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_168 {
        ((unsafe *__local_state__goto_475_31).length = ((0 as c_uint)))
        ((unsafe *__local_state__goto_475_31).mode = ((16187 as i32)))
        goto '__ci_bb_182
    }

    '__ci_bb_169 {
        goto '__ci_bb_28
    }

    '__ci_bb_170 {
        (__local_copy___goto_482_14 = ((0 as c_uint)))
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        (__ci_expr_old_20 = __local_copy___goto_482_14)
        (__local_copy___goto_482_14 = (__local_copy___goto_482_14 +% 1))
        (__local_len__goto_486_14 = (((unsafe __local_next__goto_476_32[__ci_expr_old_20]) as c_uint)))
        (__ci_expr_logic_22 = 0)
        (__ci_expr_logic_21 = 0)
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if (if (unsafe *__local_state__goto_475_31).head.name != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_logic_22 = (if (if (unsafe *__local_state__goto_475_31).length < (unsafe *__local_state__goto_475_31).head.name_max: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_172 {
        (__ci_expr_logic_24 = 0)
        if (__local_len__goto_486_14 != 0) {
            (__ci_expr_logic_24 = (if (if __local_copy___goto_482_14 < __local_have__goto_478_14: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_171
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_173 {
        (__ci_expr_logic_25 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_25 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_174 {
        (__ci_expr_old_23 = (unsafe *__local_state__goto_475_31).length)
        ((unsafe *__local_state__goto_475_31).length = ((unsafe *__local_state__goto_475_31).length +% 1))
        ((unsafe (unsafe *__local_state__goto_475_31).head.name[__ci_expr_old_23]) = ((__local_len__goto_486_14 as u8)))
        goto '__ci_bb_175
    }

    '__ci_bb_175 {
        goto '__ci_bb_172
    }

    '__ci_bb_176 {
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (__local_next__goto_476_32 as *const u8), __local_copy___goto_482_14) as c_ulong)))
        goto '__ci_bb_177
    }

    '__ci_bb_177 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% __local_copy___goto_482_14))
        (__local_next__goto_476_32 = __local_next__goto_476_32 + (__local_copy___goto_482_14 as usize))
        if (__local_len__goto_486_14 != 0) {
            goto '__ci_bb_178
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_178 {
        goto '__ci_bb_28
    }

    '__ci_bb_179 {
        goto '__ci_bb_168
    }

    '__ci_bb_180 {
        ((unsafe *__local_state__goto_475_31).head.name = null)
        goto '__ci_bb_181
    }

    '__ci_bb_181 {
        goto '__ci_bb_168
    }

    '__ci_bb_182 {
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (4096 as c_int)) != 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_183 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_184 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_185 {
        ((unsafe *__local_state__goto_475_31).mode = ((16188 as i32)))
        goto '__ci_bb_199
    }

    '__ci_bb_186 {
        goto '__ci_bb_28
    }

    '__ci_bb_187 {
        (__local_copy___goto_482_14 = ((0 as c_uint)))
        goto '__ci_bb_188
    }

    '__ci_bb_188 {
        (__ci_expr_old_26 = __local_copy___goto_482_14)
        (__local_copy___goto_482_14 = (__local_copy___goto_482_14 +% 1))
        (__local_len__goto_486_14 = (((unsafe __local_next__goto_476_32[__ci_expr_old_26]) as c_uint)))
        (__ci_expr_logic_28 = 0)
        (__ci_expr_logic_27 = 0)
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_27 = (if (if (unsafe *__local_state__goto_475_31).head.comment != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_27 != 0) {
            (__ci_expr_logic_28 = (if (if (unsafe *__local_state__goto_475_31).length < (unsafe *__local_state__goto_475_31).head.comm_max: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_28 != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_189 {
        (__ci_expr_logic_30 = 0)
        if (__local_len__goto_486_14 != 0) {
            (__ci_expr_logic_30 = (if (if __local_copy___goto_482_14 < __local_have__goto_478_14: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_30 != 0) {
            goto '__ci_bb_188
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_190 {
        (__ci_expr_logic_31 = 0)
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            (__ci_expr_logic_31 = (if (((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_193
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_191 {
        (__ci_expr_old_29 = (unsafe *__local_state__goto_475_31).length)
        ((unsafe *__local_state__goto_475_31).length = ((unsafe *__local_state__goto_475_31).length +% 1))
        ((unsafe (unsafe *__local_state__goto_475_31).head.comment[__ci_expr_old_29]) = ((__local_len__goto_486_14 as u8)))
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        goto '__ci_bb_189
    }

    '__ci_bb_193 {
        ((unsafe *__local_state__goto_475_31).check = ((crc32((unsafe *__local_state__goto_475_31).check, (__local_next__goto_476_32 as *const u8), __local_copy___goto_482_14) as c_ulong)))
        goto '__ci_bb_194
    }

    '__ci_bb_194 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% __local_copy___goto_482_14))
        (__local_next__goto_476_32 = __local_next__goto_476_32 + (__local_copy___goto_482_14 as usize))
        if (__local_len__goto_486_14 != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_195 {
        goto '__ci_bb_28
    }

    '__ci_bb_196 {
        goto '__ci_bb_185
    }

    '__ci_bb_197 {
        ((unsafe *__local_state__goto_475_31).head.comment = null)
        goto '__ci_bb_198
    }

    '__ci_bb_198 {
        goto '__ci_bb_185
    }

    '__ci_bb_199 {
        if ((((unsafe *__local_state__goto_475_31).flags as c_int) & (512 as c_int)) != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_200 {
        goto '__ci_bb_202
    }

    '__ci_bb_201 {
        if ((if (unsafe *__local_state__goto_475_31).head != 0: 1 else: 0) != 0) {
            goto '__ci_bb_218
        } else {
            goto '__ci_bb_219
        }
    }

    '__ci_bb_202 {
        goto '__ci_bb_205
    }

    '__ci_bb_203 {
        if (0 != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_204
        }
    }

    '__ci_bb_204 {
        (__ci_expr_logic_33 = 0)
        if ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0) {
            (__ci_expr_logic_33 = (if (if __local_hold__goto_479_19 != (((unsafe *__local_state__goto_475_31).check as c_ulong) & (65535 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_33 != 0) {
            goto '__ci_bb_213
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_205 {
        if ((if __local_bits__goto_480_14 < ((16 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_207
        }
    }

    '__ci_bb_206 {
        goto '__ci_bb_208
    }

    '__ci_bb_207 {
        goto '__ci_bb_203
    }

    '__ci_bb_208 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_209 {
        if (0 != 0) {
            goto '__ci_bb_208
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_210 {
        goto '__ci_bb_205
    }

    '__ci_bb_211 {
        goto '__ci_bb_28
    }

    '__ci_bb_212 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_32 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_32) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_209
    }

    '__ci_bb_213 {
        ((unsafe *__param_strm).msg = (("header crc mismatch" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_214 {
        goto '__ci_bb_215
    }

    '__ci_bb_215 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_216
    }

    '__ci_bb_216 {
        if (0 != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_217
        }
    }

    '__ci_bb_217 {
        goto '__ci_bb_201
    }

    '__ci_bb_218 {
        ((unsafe *__local_state__goto_475_31).head.hcrc = (((((((unsafe *__local_state__goto_475_31).flags as c_int) >> (9 as c_uint)) as c_int) & (1 as c_int)) as c_int)))
        ((unsafe *__local_state__goto_475_31).head.done = ((1 as c_int)))
        goto '__ci_bb_219
    }

    '__ci_bb_219 {
        ((unsafe *__local_state__goto_475_31).check = ((crc32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))
        ((unsafe *__param_strm).adler = (unsafe *__local_state__goto_475_31).check)
        ((unsafe *__local_state__goto_475_31).mode = ((16191 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_220 {
        goto '__ci_bb_221
    }

    '__ci_bb_221 {
        goto '__ci_bb_224
    }

    '__ci_bb_222 {
        if (0 != 0) {
            goto '__ci_bb_221
        } else {
            goto '__ci_bb_223
        }
    }

    '__ci_bb_223 {
        ((unsafe *__local_state__goto_475_31).check = ((((((((((((__local_hold__goto_479_19 as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as c_ulong) +% (((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as c_ulong) & (65280 as c_ulong)) as c_ulong)) as c_ulong) +% (((((__local_hold__goto_479_19 as c_ulong) & (65280 as c_ulong)) as c_ulong) << (8 as c_uint)) as c_ulong)) as c_ulong) +% (((((__local_hold__goto_479_19 as c_ulong) & (255 as c_ulong)) as c_ulong) << (24 as c_uint)) as c_ulong)) as c_ulong)))
        ((unsafe *__param_strm).adler = (unsafe *__local_state__goto_475_31).check)
        goto '__ci_bb_232
    }

    '__ci_bb_224 {
        if ((if __local_bits__goto_480_14 < ((32 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_225
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_225 {
        goto '__ci_bb_227
    }

    '__ci_bb_226 {
        goto '__ci_bb_222
    }

    '__ci_bb_227 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_228 {
        if (0 != 0) {
            goto '__ci_bb_227
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_229 {
        goto '__ci_bb_224
    }

    '__ci_bb_230 {
        goto '__ci_bb_28
    }

    '__ci_bb_231 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_34 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_34) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_228
    }

    '__ci_bb_232 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_233
    }

    '__ci_bb_233 {
        if (0 != 0) {
            goto '__ci_bb_232
        } else {
            goto '__ci_bb_234
        }
    }

    '__ci_bb_234 {
        ((unsafe *__local_state__goto_475_31).mode = ((16190 as i32)))
        goto '__ci_bb_235
    }

    '__ci_bb_235 {
        if ((if (unsafe *__local_state__goto_475_31).havedict == 0: 1 else: 0) != 0) {
            goto '__ci_bb_236
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_236 {
        goto '__ci_bb_238
    }

    '__ci_bb_237 {
        ((unsafe *__local_state__goto_475_31).check = ((adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))
        ((unsafe *__param_strm).adler = (unsafe *__local_state__goto_475_31).check)
        ((unsafe *__local_state__goto_475_31).mode = ((16191 as i32)))
        goto '__ci_bb_241
    }

    '__ci_bb_238 {
        ((unsafe *__param_strm).next_out = __local_put__goto_477_24)
        ((unsafe *__param_strm).avail_out = __local_left__goto_478_20)
        ((unsafe *__param_strm).next_in = __local_next__goto_476_32)
        ((unsafe *__param_strm).avail_in = __local_have__goto_478_14)
        ((unsafe *__local_state__goto_475_31).hold = __local_hold__goto_479_19)
        ((unsafe *__local_state__goto_475_31).bits = __local_bits__goto_480_14)
        goto '__ci_bb_239
    }

    '__ci_bb_239 {
        if (0 != 0) {
            goto '__ci_bb_238
        } else {
            goto '__ci_bb_240
        }
    }

    '__ci_bb_240 {
        return 2
    }

    '__ci_bb_241 {
        if ((if __param_flush == 5: 1 else: 0) != 0) {
            (__ci_expr_logic_35 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_35 = (if (if __param_flush == 6: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_35 != 0) {
            goto '__ci_bb_242
        } else {
            goto '__ci_bb_243
        }
    }

    '__ci_bb_242 {
        goto '__ci_bb_28
    }

    '__ci_bb_243 {
        goto '__ci_bb_244
    }

    '__ci_bb_244 {
        if ((unsafe *__local_state__goto_475_31).last != 0) {
            goto '__ci_bb_245
        } else {
            goto '__ci_bb_246
        }
    }

    '__ci_bb_245 {
        goto '__ci_bb_247
    }

    '__ci_bb_246 {
        goto '__ci_bb_250
    }

    '__ci_bb_247 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (((__local_bits__goto_480_14 as c_uint) & (7 as c_uint)) as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((__local_bits__goto_480_14 as c_uint) & (7 as c_uint))))
        goto '__ci_bb_248
    }

    '__ci_bb_248 {
        if (0 != 0) {
            goto '__ci_bb_247
        } else {
            goto '__ci_bb_249
        }
    }

    '__ci_bb_249 {
        ((unsafe *__local_state__goto_475_31).mode = ((16206 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_250 {
        goto '__ci_bb_253
    }

    '__ci_bb_251 {
        if (0 != 0) {
            goto '__ci_bb_250
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_252 {
        ((unsafe *__local_state__goto_475_31).last = (((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (1 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_int)))
        goto '__ci_bb_261
    }

    '__ci_bb_253 {
        if ((if __local_bits__goto_480_14 < ((3 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_254
        } else {
            goto '__ci_bb_255
        }
    }

    '__ci_bb_254 {
        goto '__ci_bb_256
    }

    '__ci_bb_255 {
        goto '__ci_bb_251
    }

    '__ci_bb_256 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_259
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_257 {
        if (0 != 0) {
            goto '__ci_bb_256
        } else {
            goto '__ci_bb_258
        }
    }

    '__ci_bb_258 {
        goto '__ci_bb_253
    }

    '__ci_bb_259 {
        goto '__ci_bb_28
    }

    '__ci_bb_260 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_36 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_36) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_257
    }

    '__ci_bb_261 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (1 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (1 as c_uint)))
        goto '__ci_bb_262
    }

    '__ci_bb_262 {
        if (0 != 0) {
            goto '__ci_bb_261
        } else {
            goto '__ci_bb_263
        }
    }

    '__ci_bb_263 {
        goto '__ci_bb_264
    }

    '__ci_bb_264 {
        if ((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) == 0) {
            goto '__ci_bb_266
        } else {
            goto '__ci_bb_275
        }
    }

    '__ci_bb_265 {
        goto '__ci_bb_277
    }

    '__ci_bb_266 {
        ((unsafe *__local_state__goto_475_31).mode = ((16193 as i32)))
        goto '__ci_bb_265
    }

    '__ci_bb_267 {
        inflate_fixed(__local_state__goto_475_31)
        ((unsafe *__local_state__goto_475_31).mode = ((16199 as i32)))
        if ((if __param_flush == 6: 1 else: 0) != 0) {
            goto '__ci_bb_268
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_268 {
        goto '__ci_bb_270
    }

    '__ci_bb_269 {
        goto '__ci_bb_265
    }

    '__ci_bb_270 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (2 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (2 as c_uint)))
        goto '__ci_bb_271
    }

    '__ci_bb_271 {
        if (0 != 0) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_272
        }
    }

    '__ci_bb_272 {
        goto '__ci_bb_28
    }

    '__ci_bb_273 {
        ((unsafe *__local_state__goto_475_31).mode = ((16196 as i32)))
        goto '__ci_bb_265
    }

    '__ci_bb_274 {
        ((unsafe *__param_strm).msg = (("invalid block type" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_265
    }

    '__ci_bb_275 {
        if ((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) == 1) {
            goto '__ci_bb_267
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_276 {
        if ((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) == 2) {
            goto '__ci_bb_273
        } else {
            goto '__ci_bb_274
        }
    }

    '__ci_bb_277 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (2 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (2 as c_uint)))
        goto '__ci_bb_278
    }

    '__ci_bb_278 {
        if (0 != 0) {
            goto '__ci_bb_277
        } else {
            goto '__ci_bb_279
        }
    }

    '__ci_bb_279 {
        goto '__ci_bb_13
    }

    '__ci_bb_280 {
        goto '__ci_bb_281
    }

    '__ci_bb_281 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (((__local_bits__goto_480_14 as c_uint) & (7 as c_uint)) as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((__local_bits__goto_480_14 as c_uint) & (7 as c_uint))))
        goto '__ci_bb_282
    }

    '__ci_bb_282 {
        if (0 != 0) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_283
        }
    }

    '__ci_bb_283 {
        goto '__ci_bb_284
    }

    '__ci_bb_284 {
        goto '__ci_bb_287
    }

    '__ci_bb_285 {
        if (0 != 0) {
            goto '__ci_bb_284
        } else {
            goto '__ci_bb_286
        }
    }

    '__ci_bb_286 {
        if ((if ((__local_hold__goto_479_19 as c_ulong) & (65535 as c_ulong)) != ((((__local_hold__goto_479_19 as c_ulong) >> (16 as c_uint)) as c_ulong) ^ (65535 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_295
        } else {
            goto '__ci_bb_296
        }
    }

    '__ci_bb_287 {
        if ((if __local_bits__goto_480_14 < ((32 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_288
        } else {
            goto '__ci_bb_289
        }
    }

    '__ci_bb_288 {
        goto '__ci_bb_290
    }

    '__ci_bb_289 {
        goto '__ci_bb_285
    }

    '__ci_bb_290 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_293
        } else {
            goto '__ci_bb_294
        }
    }

    '__ci_bb_291 {
        if (0 != 0) {
            goto '__ci_bb_290
        } else {
            goto '__ci_bb_292
        }
    }

    '__ci_bb_292 {
        goto '__ci_bb_287
    }

    '__ci_bb_293 {
        goto '__ci_bb_28
    }

    '__ci_bb_294 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_37 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_37) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_291
    }

    '__ci_bb_295 {
        ((unsafe *__param_strm).msg = (("invalid stored block lengths" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_296 {
        ((unsafe *__local_state__goto_475_31).length = (((((__local_hold__goto_479_19 as c_uint) as c_uint) & (65535 as c_uint)) as c_uint)))
        goto '__ci_bb_297
    }

    '__ci_bb_297 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_298
    }

    '__ci_bb_298 {
        if (0 != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_299
        }
    }

    '__ci_bb_299 {
        ((unsafe *__local_state__goto_475_31).mode = ((16194 as i32)))
        if ((if __param_flush == 6: 1 else: 0) != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_300 {
        goto '__ci_bb_28
    }

    '__ci_bb_301 {
        goto '__ci_bb_302
    }

    '__ci_bb_302 {
        ((unsafe *__local_state__goto_475_31).mode = ((16195 as i32)))
        goto '__ci_bb_303
    }

    '__ci_bb_303 {
        (__local_copy___goto_482_14 = (unsafe *__local_state__goto_475_31).length)
        if (__local_copy___goto_482_14 != 0) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_305
        }
    }

    '__ci_bb_304 {
        if ((if __local_copy___goto_482_14 > __local_have__goto_478_14: 1 else: 0) != 0) {
            goto '__ci_bb_306
        } else {
            goto '__ci_bb_307
        }
    }

    '__ci_bb_305 {
        ((unsafe *__local_state__goto_475_31).mode = ((16191 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_306 {
        (__local_copy___goto_482_14 = __local_have__goto_478_14)
        goto '__ci_bb_307
    }

    '__ci_bb_307 {
        if ((if __local_copy___goto_482_14 > __local_left__goto_478_20: 1 else: 0) != 0) {
            goto '__ci_bb_308
        } else {
            goto '__ci_bb_309
        }
    }

    '__ci_bb_308 {
        (__local_copy___goto_482_14 = __local_left__goto_478_20)
        goto '__ci_bb_309
    }

    '__ci_bb_309 {
        if ((if __local_copy___goto_482_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_311
        }
    }

    '__ci_bb_310 {
        goto '__ci_bb_28
    }

    '__ci_bb_311 {
        with_memcpy(((__local_put__goto_477_24 as *mut c_void) as *i8), ((__local_next__goto_476_32 as *const c_void) as *i8), ((__local_copy___goto_482_14 as c_ulong) as i64))
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% __local_copy___goto_482_14))
        (__local_next__goto_476_32 = __local_next__goto_476_32 + (__local_copy___goto_482_14 as usize))
        (__local_left__goto_478_20 = (__local_left__goto_478_20 -% __local_copy___goto_482_14))
        (__local_put__goto_477_24 = __local_put__goto_477_24 + (__local_copy___goto_482_14 as usize))
        ((unsafe *__local_state__goto_475_31).length = ((unsafe *__local_state__goto_475_31).length -% __local_copy___goto_482_14))
        goto '__ci_bb_13
    }

    '__ci_bb_312 {
        goto '__ci_bb_313
    }

    '__ci_bb_313 {
        goto '__ci_bb_316
    }

    '__ci_bb_314 {
        if (0 != 0) {
            goto '__ci_bb_313
        } else {
            goto '__ci_bb_315
        }
    }

    '__ci_bb_315 {
        ((unsafe *__local_state__goto_475_31).nlen = (((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (5 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (257 as c_uint)) as c_uint)))
        goto '__ci_bb_324
    }

    '__ci_bb_316 {
        if ((if __local_bits__goto_480_14 < ((14 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_317
        } else {
            goto '__ci_bb_318
        }
    }

    '__ci_bb_317 {
        goto '__ci_bb_319
    }

    '__ci_bb_318 {
        goto '__ci_bb_314
    }

    '__ci_bb_319 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_322
        } else {
            goto '__ci_bb_323
        }
    }

    '__ci_bb_320 {
        if (0 != 0) {
            goto '__ci_bb_319
        } else {
            goto '__ci_bb_321
        }
    }

    '__ci_bb_321 {
        goto '__ci_bb_316
    }

    '__ci_bb_322 {
        goto '__ci_bb_28
    }

    '__ci_bb_323 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_38 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_38) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_320
    }

    '__ci_bb_324 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (5 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (5 as c_uint)))
        goto '__ci_bb_325
    }

    '__ci_bb_325 {
        if (0 != 0) {
            goto '__ci_bb_324
        } else {
            goto '__ci_bb_326
        }
    }

    '__ci_bb_326 {
        ((unsafe *__local_state__goto_475_31).ndist = (((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (5 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (1 as c_uint)) as c_uint)))
        goto '__ci_bb_327
    }

    '__ci_bb_327 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (5 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (5 as c_uint)))
        goto '__ci_bb_328
    }

    '__ci_bb_328 {
        if (0 != 0) {
            goto '__ci_bb_327
        } else {
            goto '__ci_bb_329
        }
    }

    '__ci_bb_329 {
        ((unsafe *__local_state__goto_475_31).ncode = (((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (4 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (4 as c_uint)) as c_uint)))
        goto '__ci_bb_330
    }

    '__ci_bb_330 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (4 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (4 as c_uint)))
        goto '__ci_bb_331
    }

    '__ci_bb_331 {
        if (0 != 0) {
            goto '__ci_bb_330
        } else {
            goto '__ci_bb_332
        }
    }

    '__ci_bb_332 {
        if ((if (unsafe *__local_state__goto_475_31).nlen > 286: 1 else: 0) != 0) {
            (__ci_expr_logic_39 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_39 = (if (if (unsafe *__local_state__goto_475_31).ndist > 30: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_39 != 0) {
            goto '__ci_bb_333
        } else {
            goto '__ci_bb_334
        }
    }

    '__ci_bb_333 {
        ((unsafe *__param_strm).msg = (("too many length or distance symbols" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_334 {
        ((unsafe *__local_state__goto_475_31).have = ((0 as c_uint)))
        ((unsafe *__local_state__goto_475_31).mode = ((16197 as i32)))
        goto '__ci_bb_335
    }

    '__ci_bb_335 {
        goto '__ci_bb_336
    }

    '__ci_bb_336 {
        if ((if (unsafe *__local_state__goto_475_31).have < (unsafe *__local_state__goto_475_31).ncode: 1 else: 0) != 0) {
            goto '__ci_bb_337
        } else {
            goto '__ci_bb_338
        }
    }

    '__ci_bb_337 {
        goto '__ci_bb_339
    }

    '__ci_bb_338 {
        goto '__ci_bb_353
    }

    '__ci_bb_339 {
        goto '__ci_bb_342
    }

    '__ci_bb_340 {
        if (0 != 0) {
            goto '__ci_bb_339
        } else {
            goto '__ci_bb_341
        }
    }

    '__ci_bb_341 {
        (__ci_expr_old_41 = (unsafe *__local_state__goto_475_31).have)
        ((unsafe *__local_state__goto_475_31).have = ((unsafe *__local_state__goto_475_31).have +% 1))
        ((unsafe *__local_state__goto_475_31).lens[__local_order__goto_491_33[__ci_expr_old_41]] = (((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (3 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_ushort)))
        goto '__ci_bb_350
    }

    '__ci_bb_342 {
        if ((if __local_bits__goto_480_14 < ((3 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_343
        } else {
            goto '__ci_bb_344
        }
    }

    '__ci_bb_343 {
        goto '__ci_bb_345
    }

    '__ci_bb_344 {
        goto '__ci_bb_340
    }

    '__ci_bb_345 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_348
        } else {
            goto '__ci_bb_349
        }
    }

    '__ci_bb_346 {
        if (0 != 0) {
            goto '__ci_bb_345
        } else {
            goto '__ci_bb_347
        }
    }

    '__ci_bb_347 {
        goto '__ci_bb_342
    }

    '__ci_bb_348 {
        goto '__ci_bb_28
    }

    '__ci_bb_349 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_40 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_40) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_346
    }

    '__ci_bb_350 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (3 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (3 as c_uint)))
        goto '__ci_bb_351
    }

    '__ci_bb_351 {
        if (0 != 0) {
            goto '__ci_bb_350
        } else {
            goto '__ci_bb_352
        }
    }

    '__ci_bb_352 {
        goto '__ci_bb_336
    }

    '__ci_bb_353 {
        if ((if (unsafe *__local_state__goto_475_31).have < 19: 1 else: 0) != 0) {
            goto '__ci_bb_354
        } else {
            goto '__ci_bb_355
        }
    }

    '__ci_bb_354 {
        (__ci_expr_old_42 = (unsafe *__local_state__goto_475_31).have)
        ((unsafe *__local_state__goto_475_31).have = ((unsafe *__local_state__goto_475_31).have +% 1))
        ((unsafe *__local_state__goto_475_31).lens[__local_order__goto_491_33[__ci_expr_old_42]] = ((0 as c_ushort)))
        goto '__ci_bb_353
    }

    '__ci_bb_355 {
        ((unsafe *__local_state__goto_475_31).next = (&(unsafe *__local_state__goto_475_31).codes[0] as *mut code))
        ((unsafe *__local_state__goto_475_31).distcode = (((unsafe *__local_state__goto_475_31).next as *const code)))
        ((unsafe *__local_state__goto_475_31).lencode = (unsafe *__local_state__goto_475_31).distcode)
        ((unsafe *__local_state__goto_475_31).lenbits = ((7 as c_uint)))
        (__local_ret__goto_487_9 = ((inflate_table((0 as i32), (&(unsafe *__local_state__goto_475_31).lens[0] as *mut c_ushort), (19 as c_uint), ((&raw const (unsafe *__local_state__goto_475_31).next as *const *mut code) as *mut *mut code), ((&raw const (unsafe *__local_state__goto_475_31).lenbits as *const c_uint) as *mut c_uint), (&(unsafe *__local_state__goto_475_31).work[0] as *mut c_ushort)) as c_int)))
        if (__local_ret__goto_487_9 != 0) {
            goto '__ci_bb_356
        } else {
            goto '__ci_bb_357
        }
    }

    '__ci_bb_356 {
        ((unsafe *__param_strm).msg = (("invalid code lengths set" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_357 {
        ((unsafe *__local_state__goto_475_31).have = ((0 as c_uint)))
        ((unsafe *__local_state__goto_475_31).mode = ((16198 as i32)))
        goto '__ci_bb_358
    }

    '__ci_bb_358 {
        goto '__ci_bb_359
    }

    '__ci_bb_359 {
        if ((if (unsafe *__local_state__goto_475_31).have < (((unsafe *__local_state__goto_475_31).nlen as c_uint) +% ((unsafe *__local_state__goto_475_31).ndist as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_360
        } else {
            goto '__ci_bb_361
        }
    }

    '__ci_bb_360 {
        goto '__ci_bb_362
    }

    '__ci_bb_361 {
        if ((if (unsafe *__local_state__goto_475_31).mode == 16209: 1 else: 0) != 0) {
            goto '__ci_bb_443
        } else {
            goto '__ci_bb_444
        }
    }

    '__ci_bb_362 {
        goto '__ci_bb_363
    }

    '__ci_bb_363 {
        with_memcpy((&raw mut __local_here__goto_484_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_475_31).lencode[(((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_475_31).lenbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)) <= __local_bits__goto_480_14: 1 else: 0) != 0) {
            goto '__ci_bb_366
        } else {
            goto '__ci_bb_367
        }
    }

    '__ci_bb_364 {
        goto '__ci_bb_362
    }

    '__ci_bb_365 {
        if ((if (unsafe *(&raw const __local_here__goto_484_10 as *const code)).val < 16: 1 else: 0) != 0) {
            goto '__ci_bb_373
        } else {
            goto '__ci_bb_374
        }
    }

    '__ci_bb_366 {
        goto '__ci_bb_365
    }

    '__ci_bb_367 {
        goto '__ci_bb_368
    }

    '__ci_bb_368 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_371
        } else {
            goto '__ci_bb_372
        }
    }

    '__ci_bb_369 {
        if (0 != 0) {
            goto '__ci_bb_368
        } else {
            goto '__ci_bb_370
        }
    }

    '__ci_bb_370 {
        goto '__ci_bb_364
    }

    '__ci_bb_371 {
        goto '__ci_bb_28
    }

    '__ci_bb_372 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_43 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_43) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_369
    }

    '__ci_bb_373 {
        goto '__ci_bb_376
    }

    '__ci_bb_374 {
        if ((if (unsafe *(&raw const __local_here__goto_484_10 as *const code)).val == 16: 1 else: 0) != 0) {
            goto '__ci_bb_379
        } else {
            goto '__ci_bb_380
        }
    }

    '__ci_bb_375 {
        goto '__ci_bb_359
    }

    '__ci_bb_376 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_377
    }

    '__ci_bb_377 {
        if (0 != 0) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_378
        }
    }

    '__ci_bb_378 {
        (__ci_expr_old_44 = (unsafe *__local_state__goto_475_31).have)
        ((unsafe *__local_state__goto_475_31).have = ((unsafe *__local_state__goto_475_31).have +% 1))
        ((unsafe *__local_state__goto_475_31).lens[__ci_expr_old_44] = (unsafe *(&raw const __local_here__goto_484_10 as *const code)).val)
        goto '__ci_bb_375
    }

    '__ci_bb_379 {
        goto '__ci_bb_382
    }

    '__ci_bb_380 {
        if ((if (unsafe *(&raw const __local_here__goto_484_10 as *const code)).val == 17: 1 else: 0) != 0) {
            goto '__ci_bb_401
        } else {
            goto '__ci_bb_402
        }
    }

    '__ci_bb_381 {
        if ((if (((unsafe *__local_state__goto_475_31).have as c_uint) +% (__local_copy___goto_482_14 as c_uint)) > (((unsafe *__local_state__goto_475_31).nlen as c_uint) +% ((unsafe *__local_state__goto_475_31).ndist as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_438
        } else {
            goto '__ci_bb_439
        }
    }

    '__ci_bb_382 {
        goto '__ci_bb_385
    }

    '__ci_bb_383 {
        if (0 != 0) {
            goto '__ci_bb_382
        } else {
            goto '__ci_bb_384
        }
    }

    '__ci_bb_384 {
        goto '__ci_bb_393
    }

    '__ci_bb_385 {
        if ((if __local_bits__goto_480_14 < (((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int) + 2) as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_386
        } else {
            goto '__ci_bb_387
        }
    }

    '__ci_bb_386 {
        goto '__ci_bb_388
    }

    '__ci_bb_387 {
        goto '__ci_bb_383
    }

    '__ci_bb_388 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_391
        } else {
            goto '__ci_bb_392
        }
    }

    '__ci_bb_389 {
        if (0 != 0) {
            goto '__ci_bb_388
        } else {
            goto '__ci_bb_390
        }
    }

    '__ci_bb_390 {
        goto '__ci_bb_385
    }

    '__ci_bb_391 {
        goto '__ci_bb_28
    }

    '__ci_bb_392 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_45 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_45) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_389
    }

    '__ci_bb_393 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_394
    }

    '__ci_bb_394 {
        if (0 != 0) {
            goto '__ci_bb_393
        } else {
            goto '__ci_bb_395
        }
    }

    '__ci_bb_395 {
        if ((if (unsafe *__local_state__goto_475_31).have == 0: 1 else: 0) != 0) {
            goto '__ci_bb_396
        } else {
            goto '__ci_bb_397
        }
    }

    '__ci_bb_396 {
        ((unsafe *__param_strm).msg = (("invalid bit length repeat" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_361
    }

    '__ci_bb_397 {
        (__local_len__goto_486_14 = (((unsafe *__local_state__goto_475_31).lens[(((unsafe *__local_state__goto_475_31).have as c_uint) -% (1 as c_uint))] as c_uint)))
        (__local_copy___goto_482_14 = ((((3 as c_uint) +% ((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        goto '__ci_bb_398
    }

    '__ci_bb_398 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (2 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (2 as c_uint)))
        goto '__ci_bb_399
    }

    '__ci_bb_399 {
        if (0 != 0) {
            goto '__ci_bb_398
        } else {
            goto '__ci_bb_400
        }
    }

    '__ci_bb_400 {
        goto '__ci_bb_381
    }

    '__ci_bb_401 {
        goto '__ci_bb_404
    }

    '__ci_bb_402 {
        goto '__ci_bb_421
    }

    '__ci_bb_403 {
        goto '__ci_bb_381
    }

    '__ci_bb_404 {
        goto '__ci_bb_407
    }

    '__ci_bb_405 {
        if (0 != 0) {
            goto '__ci_bb_404
        } else {
            goto '__ci_bb_406
        }
    }

    '__ci_bb_406 {
        goto '__ci_bb_415
    }

    '__ci_bb_407 {
        if ((if __local_bits__goto_480_14 < (((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int) + 3) as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_408
        } else {
            goto '__ci_bb_409
        }
    }

    '__ci_bb_408 {
        goto '__ci_bb_410
    }

    '__ci_bb_409 {
        goto '__ci_bb_405
    }

    '__ci_bb_410 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_413
        } else {
            goto '__ci_bb_414
        }
    }

    '__ci_bb_411 {
        if (0 != 0) {
            goto '__ci_bb_410
        } else {
            goto '__ci_bb_412
        }
    }

    '__ci_bb_412 {
        goto '__ci_bb_407
    }

    '__ci_bb_413 {
        goto '__ci_bb_28
    }

    '__ci_bb_414 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_46 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_46) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_411
    }

    '__ci_bb_415 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_416
    }

    '__ci_bb_416 {
        if (0 != 0) {
            goto '__ci_bb_415
        } else {
            goto '__ci_bb_417
        }
    }

    '__ci_bb_417 {
        (__local_len__goto_486_14 = ((0 as c_uint)))
        (__local_copy___goto_482_14 = ((((3 as c_uint) +% ((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (3 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        goto '__ci_bb_418
    }

    '__ci_bb_418 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (3 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (3 as c_uint)))
        goto '__ci_bb_419
    }

    '__ci_bb_419 {
        if (0 != 0) {
            goto '__ci_bb_418
        } else {
            goto '__ci_bb_420
        }
    }

    '__ci_bb_420 {
        goto '__ci_bb_403
    }

    '__ci_bb_421 {
        goto '__ci_bb_424
    }

    '__ci_bb_422 {
        if (0 != 0) {
            goto '__ci_bb_421
        } else {
            goto '__ci_bb_423
        }
    }

    '__ci_bb_423 {
        goto '__ci_bb_432
    }

    '__ci_bb_424 {
        if ((if __local_bits__goto_480_14 < (((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int) + 7) as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_425
        } else {
            goto '__ci_bb_426
        }
    }

    '__ci_bb_425 {
        goto '__ci_bb_427
    }

    '__ci_bb_426 {
        goto '__ci_bb_422
    }

    '__ci_bb_427 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_430
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_428 {
        if (0 != 0) {
            goto '__ci_bb_427
        } else {
            goto '__ci_bb_429
        }
    }

    '__ci_bb_429 {
        goto '__ci_bb_424
    }

    '__ci_bb_430 {
        goto '__ci_bb_28
    }

    '__ci_bb_431 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_47 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_47) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_428
    }

    '__ci_bb_432 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_433
    }

    '__ci_bb_433 {
        if (0 != 0) {
            goto '__ci_bb_432
        } else {
            goto '__ci_bb_434
        }
    }

    '__ci_bb_434 {
        (__local_len__goto_486_14 = ((0 as c_uint)))
        (__local_copy___goto_482_14 = ((((11 as c_uint) +% ((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << (7 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        goto '__ci_bb_435
    }

    '__ci_bb_435 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> (7 as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (7 as c_uint)))
        goto '__ci_bb_436
    }

    '__ci_bb_436 {
        if (0 != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_437
        }
    }

    '__ci_bb_437 {
        goto '__ci_bb_403
    }

    '__ci_bb_438 {
        ((unsafe *__param_strm).msg = (("invalid bit length repeat" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_361
    }

    '__ci_bb_439 {
        goto '__ci_bb_440
    }

    '__ci_bb_440 {
        (__ci_expr_old_48 = __local_copy___goto_482_14)
        (__local_copy___goto_482_14 = (__local_copy___goto_482_14 -% 1))
        if (__ci_expr_old_48 != 0) {
            goto '__ci_bb_441
        } else {
            goto '__ci_bb_442
        }
    }

    '__ci_bb_441 {
        (__ci_expr_old_49 = (unsafe *__local_state__goto_475_31).have)
        ((unsafe *__local_state__goto_475_31).have = ((unsafe *__local_state__goto_475_31).have +% 1))
        ((unsafe *__local_state__goto_475_31).lens[__ci_expr_old_49] = ((__local_len__goto_486_14 as c_ushort)))
        goto '__ci_bb_440
    }

    '__ci_bb_442 {
        goto '__ci_bb_375
    }

    '__ci_bb_443 {
        goto '__ci_bb_13
    }

    '__ci_bb_444 {
        if ((if (unsafe *__local_state__goto_475_31).lens[256] == 0: 1 else: 0) != 0) {
            goto '__ci_bb_445
        } else {
            goto '__ci_bb_446
        }
    }

    '__ci_bb_445 {
        ((unsafe *__param_strm).msg = (("invalid code -- missing end-of-block" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_446 {
        ((unsafe *__local_state__goto_475_31).next = (&(unsafe *__local_state__goto_475_31).codes[0] as *mut code))
        ((unsafe *__local_state__goto_475_31).lencode = (((unsafe *__local_state__goto_475_31).next as *const code)))
        ((unsafe *__local_state__goto_475_31).lenbits = ((9 as c_uint)))
        (__local_ret__goto_487_9 = ((inflate_table((1 as i32), (&(unsafe *__local_state__goto_475_31).lens[0] as *mut c_ushort), (unsafe *__local_state__goto_475_31).nlen, ((&raw const (unsafe *__local_state__goto_475_31).next as *const *mut code) as *mut *mut code), ((&raw const (unsafe *__local_state__goto_475_31).lenbits as *const c_uint) as *mut c_uint), (&(unsafe *__local_state__goto_475_31).work[0] as *mut c_ushort)) as c_int)))
        if (__local_ret__goto_487_9 != 0) {
            goto '__ci_bb_447
        } else {
            goto '__ci_bb_448
        }
    }

    '__ci_bb_447 {
        ((unsafe *__param_strm).msg = (("invalid literal/lengths set" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_448 {
        ((unsafe *__local_state__goto_475_31).distcode = (((unsafe *__local_state__goto_475_31).next as *const code)))
        ((unsafe *__local_state__goto_475_31).distbits = ((6 as c_uint)))
        (__local_ret__goto_487_9 = ((inflate_table((2 as i32), ((&(unsafe *__local_state__goto_475_31).lens[0] as *mut c_ushort) + ((unsafe *__local_state__goto_475_31).nlen as usize)), (unsafe *__local_state__goto_475_31).ndist, ((&raw const (unsafe *__local_state__goto_475_31).next as *const *mut code) as *mut *mut code), ((&raw const (unsafe *__local_state__goto_475_31).distbits as *const c_uint) as *mut c_uint), (&(unsafe *__local_state__goto_475_31).work[0] as *mut c_ushort)) as c_int)))
        if (__local_ret__goto_487_9 != 0) {
            goto '__ci_bb_449
        } else {
            goto '__ci_bb_450
        }
    }

    '__ci_bb_449 {
        ((unsafe *__param_strm).msg = (("invalid distances set" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_450 {
        ((unsafe *__local_state__goto_475_31).mode = ((16199 as i32)))
        if ((if __param_flush == 6: 1 else: 0) != 0) {
            goto '__ci_bb_451
        } else {
            goto '__ci_bb_452
        }
    }

    '__ci_bb_451 {
        goto '__ci_bb_28
    }

    '__ci_bb_452 {
        goto '__ci_bb_453
    }

    '__ci_bb_453 {
        ((unsafe *__local_state__goto_475_31).mode = ((16200 as i32)))
        goto '__ci_bb_454
    }

    '__ci_bb_454 {
        (__ci_expr_logic_50 = 0)
        if ((if __local_have__goto_478_14 >= 6: 1 else: 0) != 0) {
            (__ci_expr_logic_50 = (if (if __local_left__goto_478_20 >= 258: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_50 != 0) {
            goto '__ci_bb_455
        } else {
            goto '__ci_bb_456
        }
    }

    '__ci_bb_455 {
        goto '__ci_bb_457
    }

    '__ci_bb_456 {
        ((unsafe *__local_state__goto_475_31).back = ((0 as c_int)))
        goto '__ci_bb_465
    }

    '__ci_bb_457 {
        ((unsafe *__param_strm).next_out = __local_put__goto_477_24)
        ((unsafe *__param_strm).avail_out = __local_left__goto_478_20)
        ((unsafe *__param_strm).next_in = __local_next__goto_476_32)
        ((unsafe *__param_strm).avail_in = __local_have__goto_478_14)
        ((unsafe *__local_state__goto_475_31).hold = __local_hold__goto_479_19)
        ((unsafe *__local_state__goto_475_31).bits = __local_bits__goto_480_14)
        goto '__ci_bb_458
    }

    '__ci_bb_458 {
        if (0 != 0) {
            goto '__ci_bb_457
        } else {
            goto '__ci_bb_459
        }
    }

    '__ci_bb_459 {
        inflate_fast(__param_strm, __local_out__goto_481_18)
        goto '__ci_bb_460
    }

    '__ci_bb_460 {
        (__local_put__goto_477_24 = (unsafe *__param_strm).next_out)
        (__local_left__goto_478_20 = (unsafe *__param_strm).avail_out)
        (__local_next__goto_476_32 = (unsafe *__param_strm).next_in)
        (__local_have__goto_478_14 = (unsafe *__param_strm).avail_in)
        (__local_hold__goto_479_19 = (unsafe *__local_state__goto_475_31).hold)
        (__local_bits__goto_480_14 = (unsafe *__local_state__goto_475_31).bits)
        goto '__ci_bb_461
    }

    '__ci_bb_461 {
        if (0 != 0) {
            goto '__ci_bb_460
        } else {
            goto '__ci_bb_462
        }
    }

    '__ci_bb_462 {
        if ((if (unsafe *__local_state__goto_475_31).mode == 16191: 1 else: 0) != 0) {
            goto '__ci_bb_463
        } else {
            goto '__ci_bb_464
        }
    }

    '__ci_bb_463 {
        ((unsafe *__local_state__goto_475_31).back = ((-1 as c_int)))
        goto '__ci_bb_464
    }

    '__ci_bb_464 {
        goto '__ci_bb_13
    }

    '__ci_bb_465 {
        goto '__ci_bb_466
    }

    '__ci_bb_466 {
        with_memcpy((&raw mut __local_here__goto_484_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_475_31).lencode[(((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_475_31).lenbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)) <= __local_bits__goto_480_14: 1 else: 0) != 0) {
            goto '__ci_bb_469
        } else {
            goto '__ci_bb_470
        }
    }

    '__ci_bb_467 {
        goto '__ci_bb_465
    }

    '__ci_bb_468 {
        (__ci_expr_logic_52 = 0)
        if ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op != 0) {
            (__ci_expr_logic_52 = (if (if ((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_int) as c_int) & (240 as c_int)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_52 != 0) {
            goto '__ci_bb_476
        } else {
            goto '__ci_bb_477
        }
    }

    '__ci_bb_469 {
        goto '__ci_bb_468
    }

    '__ci_bb_470 {
        goto '__ci_bb_471
    }

    '__ci_bb_471 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_474
        } else {
            goto '__ci_bb_475
        }
    }

    '__ci_bb_472 {
        if (0 != 0) {
            goto '__ci_bb_471
        } else {
            goto '__ci_bb_473
        }
    }

    '__ci_bb_473 {
        goto '__ci_bb_467
    }

    '__ci_bb_474 {
        goto '__ci_bb_28
    }

    '__ci_bb_475 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_51 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_51) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_472
    }

    '__ci_bb_476 {
        with_memcpy((&raw mut __local_last__goto_485_10 as *i8), (&raw const __local_here__goto_484_10 as *i8), sizeof[code]())
        goto '__ci_bb_478
    }

    '__ci_bb_477 {
        goto '__ci_bb_492
    }

    '__ci_bb_478 {
        goto '__ci_bb_479
    }

    '__ci_bb_479 {
        with_memcpy((&raw mut __local_here__goto_484_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_475_31).lencode[((((unsafe *(&raw const __local_last__goto_485_10 as *const code)).val as c_int) as c_uint) +% ((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).op as c_int)) as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) >> ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int)) as c_uint)) <= __local_bits__goto_480_14: 1 else: 0) != 0) {
            goto '__ci_bb_482
        } else {
            goto '__ci_bb_483
        }
    }

    '__ci_bb_480 {
        goto '__ci_bb_478
    }

    '__ci_bb_481 {
        goto '__ci_bb_489
    }

    '__ci_bb_482 {
        goto '__ci_bb_481
    }

    '__ci_bb_483 {
        goto '__ci_bb_484
    }

    '__ci_bb_484 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_487
        } else {
            goto '__ci_bb_488
        }
    }

    '__ci_bb_485 {
        if (0 != 0) {
            goto '__ci_bb_484
        } else {
            goto '__ci_bb_486
        }
    }

    '__ci_bb_486 {
        goto '__ci_bb_480
    }

    '__ci_bb_487 {
        goto '__ci_bb_28
    }

    '__ci_bb_488 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_53 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_53) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_485
    }

    '__ci_bb_489 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_490
    }

    '__ci_bb_490 {
        if (0 != 0) {
            goto '__ci_bb_489
        } else {
            goto '__ci_bb_491
        }
    }

    '__ci_bb_491 {
        ((unsafe *__local_state__goto_475_31).back = (unsafe *__local_state__goto_475_31).back + ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_int))
        goto '__ci_bb_477
    }

    '__ci_bb_492 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_493
    }

    '__ci_bb_493 {
        if (0 != 0) {
            goto '__ci_bb_492
        } else {
            goto '__ci_bb_494
        }
    }

    '__ci_bb_494 {
        ((unsafe *__local_state__goto_475_31).back = (unsafe *__local_state__goto_475_31).back + ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int))
        ((unsafe *__local_state__goto_475_31).length = (((unsafe *(&raw const __local_here__goto_484_10 as *const code)).val as c_uint)))
        if ((if (((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_int)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_495
        } else {
            goto '__ci_bb_496
        }
    }

    '__ci_bb_495 {
        ((unsafe *__local_state__goto_475_31).mode = ((16205 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_496 {
        if (((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_int) as c_int) & (32 as c_int)) != 0) {
            goto '__ci_bb_497
        } else {
            goto '__ci_bb_498
        }
    }

    '__ci_bb_497 {
        ((unsafe *__local_state__goto_475_31).back = ((-1 as c_int)))
        ((unsafe *__local_state__goto_475_31).mode = ((16191 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_498 {
        if (((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_int) as c_int) & (64 as c_int)) != 0) {
            goto '__ci_bb_499
        } else {
            goto '__ci_bb_500
        }
    }

    '__ci_bb_499 {
        ((unsafe *__param_strm).msg = (("invalid literal/length code" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_500 {
        ((unsafe *__local_state__goto_475_31).extra = ((((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_uint) as c_uint) & (15 as c_uint)) as c_uint)))
        ((unsafe *__local_state__goto_475_31).mode = ((16201 as i32)))
        goto '__ci_bb_501
    }

    '__ci_bb_501 {
        if ((unsafe *__local_state__goto_475_31).extra != 0) {
            goto '__ci_bb_502
        } else {
            goto '__ci_bb_503
        }
    }

    '__ci_bb_502 {
        goto '__ci_bb_504
    }

    '__ci_bb_503 {
        ((unsafe *__local_state__goto_475_31).was = (unsafe *__local_state__goto_475_31).length)
        ((unsafe *__local_state__goto_475_31).mode = ((16202 as i32)))
        goto '__ci_bb_518
    }

    '__ci_bb_504 {
        goto '__ci_bb_507
    }

    '__ci_bb_505 {
        if (0 != 0) {
            goto '__ci_bb_504
        } else {
            goto '__ci_bb_506
        }
    }

    '__ci_bb_506 {
        ((unsafe *__local_state__goto_475_31).length = ((unsafe *__local_state__goto_475_31).length +% (((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_475_31).extra as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))))
        goto '__ci_bb_515
    }

    '__ci_bb_507 {
        if ((if __local_bits__goto_480_14 < (unsafe *__local_state__goto_475_31).extra: 1 else: 0) != 0) {
            goto '__ci_bb_508
        } else {
            goto '__ci_bb_509
        }
    }

    '__ci_bb_508 {
        goto '__ci_bb_510
    }

    '__ci_bb_509 {
        goto '__ci_bb_505
    }

    '__ci_bb_510 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_513
        } else {
            goto '__ci_bb_514
        }
    }

    '__ci_bb_511 {
        if (0 != 0) {
            goto '__ci_bb_510
        } else {
            goto '__ci_bb_512
        }
    }

    '__ci_bb_512 {
        goto '__ci_bb_507
    }

    '__ci_bb_513 {
        goto '__ci_bb_28
    }

    '__ci_bb_514 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_54 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_54) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_511
    }

    '__ci_bb_515 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *__local_state__goto_475_31).extra as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (unsafe *__local_state__goto_475_31).extra))
        goto '__ci_bb_516
    }

    '__ci_bb_516 {
        if (0 != 0) {
            goto '__ci_bb_515
        } else {
            goto '__ci_bb_517
        }
    }

    '__ci_bb_517 {
        ((unsafe *__local_state__goto_475_31).back = (unsafe *__local_state__goto_475_31).back + (unsafe *__local_state__goto_475_31).extra)
        goto '__ci_bb_503
    }

    '__ci_bb_518 {
        goto '__ci_bb_519
    }

    '__ci_bb_519 {
        goto '__ci_bb_520
    }

    '__ci_bb_520 {
        with_memcpy((&raw mut __local_here__goto_484_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_475_31).distcode[(((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_475_31).distbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)) <= __local_bits__goto_480_14: 1 else: 0) != 0) {
            goto '__ci_bb_523
        } else {
            goto '__ci_bb_524
        }
    }

    '__ci_bb_521 {
        goto '__ci_bb_519
    }

    '__ci_bb_522 {
        if ((if ((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_int) as c_int) & (240 as c_int)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_530
        } else {
            goto '__ci_bb_531
        }
    }

    '__ci_bb_523 {
        goto '__ci_bb_522
    }

    '__ci_bb_524 {
        goto '__ci_bb_525
    }

    '__ci_bb_525 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_528
        } else {
            goto '__ci_bb_529
        }
    }

    '__ci_bb_526 {
        if (0 != 0) {
            goto '__ci_bb_525
        } else {
            goto '__ci_bb_527
        }
    }

    '__ci_bb_527 {
        goto '__ci_bb_521
    }

    '__ci_bb_528 {
        goto '__ci_bb_28
    }

    '__ci_bb_529 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_55 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_55) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_526
    }

    '__ci_bb_530 {
        with_memcpy((&raw mut __local_last__goto_485_10 as *i8), (&raw const __local_here__goto_484_10 as *i8), sizeof[code]())
        goto '__ci_bb_532
    }

    '__ci_bb_531 {
        goto '__ci_bb_546
    }

    '__ci_bb_532 {
        goto '__ci_bb_533
    }

    '__ci_bb_533 {
        with_memcpy((&raw mut __local_here__goto_484_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_475_31).distcode[((((unsafe *(&raw const __local_last__goto_485_10 as *const code)).val as c_int) as c_uint) +% ((((((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).op as c_int)) as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) >> ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int)) as c_uint)) <= __local_bits__goto_480_14: 1 else: 0) != 0) {
            goto '__ci_bb_536
        } else {
            goto '__ci_bb_537
        }
    }

    '__ci_bb_534 {
        goto '__ci_bb_532
    }

    '__ci_bb_535 {
        goto '__ci_bb_543
    }

    '__ci_bb_536 {
        goto '__ci_bb_535
    }

    '__ci_bb_537 {
        goto '__ci_bb_538
    }

    '__ci_bb_538 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_541
        } else {
            goto '__ci_bb_542
        }
    }

    '__ci_bb_539 {
        if (0 != 0) {
            goto '__ci_bb_538
        } else {
            goto '__ci_bb_540
        }
    }

    '__ci_bb_540 {
        goto '__ci_bb_534
    }

    '__ci_bb_541 {
        goto '__ci_bb_28
    }

    '__ci_bb_542 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_56 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_56) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_539
    }

    '__ci_bb_543 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_544
    }

    '__ci_bb_544 {
        if (0 != 0) {
            goto '__ci_bb_543
        } else {
            goto '__ci_bb_545
        }
    }

    '__ci_bb_545 {
        ((unsafe *__local_state__goto_475_31).back = (unsafe *__local_state__goto_475_31).back + ((unsafe *(&raw const __local_last__goto_485_10 as *const code)).bits as c_int))
        goto '__ci_bb_531
    }

    '__ci_bb_546 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_547
    }

    '__ci_bb_547 {
        if (0 != 0) {
            goto '__ci_bb_546
        } else {
            goto '__ci_bb_548
        }
    }

    '__ci_bb_548 {
        ((unsafe *__local_state__goto_475_31).back = (unsafe *__local_state__goto_475_31).back + ((unsafe *(&raw const __local_here__goto_484_10 as *const code)).bits as c_int))
        if (((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_int) as c_int) & (64 as c_int)) != 0) {
            goto '__ci_bb_549
        } else {
            goto '__ci_bb_550
        }
    }

    '__ci_bb_549 {
        ((unsafe *__param_strm).msg = (("invalid distance code" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_550 {
        ((unsafe *__local_state__goto_475_31).offset = (((unsafe *(&raw const __local_here__goto_484_10 as *const code)).val as c_uint)))
        ((unsafe *__local_state__goto_475_31).extra = ((((((unsafe *(&raw const __local_here__goto_484_10 as *const code)).op as c_uint) as c_uint) & (15 as c_uint)) as c_uint)))
        ((unsafe *__local_state__goto_475_31).mode = ((16203 as i32)))
        goto '__ci_bb_551
    }

    '__ci_bb_551 {
        if ((unsafe *__local_state__goto_475_31).extra != 0) {
            goto '__ci_bb_552
        } else {
            goto '__ci_bb_553
        }
    }

    '__ci_bb_552 {
        goto '__ci_bb_554
    }

    '__ci_bb_553 {
        ((unsafe *__local_state__goto_475_31).mode = ((16204 as i32)))
        goto '__ci_bb_568
    }

    '__ci_bb_554 {
        goto '__ci_bb_557
    }

    '__ci_bb_555 {
        if (0 != 0) {
            goto '__ci_bb_554
        } else {
            goto '__ci_bb_556
        }
    }

    '__ci_bb_556 {
        ((unsafe *__local_state__goto_475_31).offset = ((unsafe *__local_state__goto_475_31).offset +% (((__local_hold__goto_479_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_475_31).extra as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))))
        goto '__ci_bb_565
    }

    '__ci_bb_557 {
        if ((if __local_bits__goto_480_14 < (unsafe *__local_state__goto_475_31).extra: 1 else: 0) != 0) {
            goto '__ci_bb_558
        } else {
            goto '__ci_bb_559
        }
    }

    '__ci_bb_558 {
        goto '__ci_bb_560
    }

    '__ci_bb_559 {
        goto '__ci_bb_555
    }

    '__ci_bb_560 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_563
        } else {
            goto '__ci_bb_564
        }
    }

    '__ci_bb_561 {
        if (0 != 0) {
            goto '__ci_bb_560
        } else {
            goto '__ci_bb_562
        }
    }

    '__ci_bb_562 {
        goto '__ci_bb_557
    }

    '__ci_bb_563 {
        goto '__ci_bb_28
    }

    '__ci_bb_564 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_57 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_57) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_561
    }

    '__ci_bb_565 {
        (__local_hold__goto_479_19 = __local_hold__goto_479_19 >> ((unsafe *__local_state__goto_475_31).extra as c_uint))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 -% (unsafe *__local_state__goto_475_31).extra))
        goto '__ci_bb_566
    }

    '__ci_bb_566 {
        if (0 != 0) {
            goto '__ci_bb_565
        } else {
            goto '__ci_bb_567
        }
    }

    '__ci_bb_567 {
        ((unsafe *__local_state__goto_475_31).back = (unsafe *__local_state__goto_475_31).back + (unsafe *__local_state__goto_475_31).extra)
        goto '__ci_bb_553
    }

    '__ci_bb_568 {
        if ((if __local_left__goto_478_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_569
        } else {
            goto '__ci_bb_570
        }
    }

    '__ci_bb_569 {
        goto '__ci_bb_28
    }

    '__ci_bb_570 {
        (__local_copy___goto_482_14 = ((((__local_out__goto_481_18 as c_uint) -% (__local_left__goto_478_20 as c_uint)) as c_uint)))
        if ((if (unsafe *__local_state__goto_475_31).offset > __local_copy___goto_482_14: 1 else: 0) != 0) {
            goto '__ci_bb_571
        } else {
            goto '__ci_bb_572
        }
    }

    '__ci_bb_571 {
        (__local_copy___goto_482_14 = (((((unsafe *__local_state__goto_475_31).offset as c_uint) -% (__local_copy___goto_482_14 as c_uint)) as c_uint)))
        if ((if __local_copy___goto_482_14 > (unsafe *__local_state__goto_475_31).whave: 1 else: 0) != 0) {
            goto '__ci_bb_574
        } else {
            goto '__ci_bb_575
        }
    }

    '__ci_bb_572 {
        (__local_from__goto_483_24 = __local_put__goto_477_24 - ((unsafe *__local_state__goto_475_31).offset as usize))
        (__local_copy___goto_482_14 = (unsafe *__local_state__goto_475_31).length)
        goto '__ci_bb_573
    }

    '__ci_bb_573 {
        if ((if __local_copy___goto_482_14 > __local_left__goto_478_20: 1 else: 0) != 0) {
            goto '__ci_bb_583
        } else {
            goto '__ci_bb_584
        }
    }

    '__ci_bb_574 {
        if ((unsafe *__local_state__goto_475_31).sane != 0) {
            goto '__ci_bb_576
        } else {
            goto '__ci_bb_577
        }
    }

    '__ci_bb_575 {
        if ((if __local_copy___goto_482_14 > (unsafe *__local_state__goto_475_31).wnext: 1 else: 0) != 0) {
            goto '__ci_bb_578
        } else {
            goto '__ci_bb_579
        }
    }

    '__ci_bb_576 {
        ((unsafe *__param_strm).msg = (("invalid distance too far back" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_577 {
        goto '__ci_bb_575
    }

    '__ci_bb_578 {
        (__local_copy___goto_482_14 = (__local_copy___goto_482_14 -% (unsafe *__local_state__goto_475_31).wnext))
        (__local_from__goto_483_24 = (unsafe *__local_state__goto_475_31).window + ((((unsafe *__local_state__goto_475_31).wsize as c_uint) -% (__local_copy___goto_482_14 as c_uint)) as usize))
        goto '__ci_bb_580
    }

    '__ci_bb_579 {
        (__local_from__goto_483_24 = (unsafe *__local_state__goto_475_31).window + ((((unsafe *__local_state__goto_475_31).wnext as c_uint) -% (__local_copy___goto_482_14 as c_uint)) as usize))
        goto '__ci_bb_580
    }

    '__ci_bb_580 {
        if ((if __local_copy___goto_482_14 > (unsafe *__local_state__goto_475_31).length: 1 else: 0) != 0) {
            goto '__ci_bb_581
        } else {
            goto '__ci_bb_582
        }
    }

    '__ci_bb_581 {
        (__local_copy___goto_482_14 = (unsafe *__local_state__goto_475_31).length)
        goto '__ci_bb_582
    }

    '__ci_bb_582 {
        goto '__ci_bb_573
    }

    '__ci_bb_583 {
        (__local_copy___goto_482_14 = __local_left__goto_478_20)
        goto '__ci_bb_584
    }

    '__ci_bb_584 {
        (__local_left__goto_478_20 = (__local_left__goto_478_20 -% __local_copy___goto_482_14))
        ((unsafe *__local_state__goto_475_31).length = ((unsafe *__local_state__goto_475_31).length -% __local_copy___goto_482_14))
        goto '__ci_bb_585
    }

    '__ci_bb_585 {
        (__ci_expr_old_58 = __local_put__goto_477_24)
        (__local_put__goto_477_24 = __local_put__goto_477_24 + 1)
        (__ci_expr_old_59 = __local_from__goto_483_24)
        (__local_from__goto_483_24 = __local_from__goto_483_24 + 1)
        ((unsafe *__ci_expr_old_58) = (unsafe *__ci_expr_old_59))
        goto '__ci_bb_586
    }

    '__ci_bb_586 {
        (__local_copy___goto_482_14 = (__local_copy___goto_482_14 -% 1))
        if (__local_copy___goto_482_14 != 0) {
            goto '__ci_bb_585
        } else {
            goto '__ci_bb_587
        }
    }

    '__ci_bb_587 {
        if ((if (unsafe *__local_state__goto_475_31).length == 0: 1 else: 0) != 0) {
            goto '__ci_bb_588
        } else {
            goto '__ci_bb_589
        }
    }

    '__ci_bb_588 {
        ((unsafe *__local_state__goto_475_31).mode = ((16200 as i32)))
        goto '__ci_bb_589
    }

    '__ci_bb_589 {
        goto '__ci_bb_13
    }

    '__ci_bb_590 {
        if ((if __local_left__goto_478_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_591
        } else {
            goto '__ci_bb_592
        }
    }

    '__ci_bb_591 {
        goto '__ci_bb_28
    }

    '__ci_bb_592 {
        (__ci_expr_old_60 = __local_put__goto_477_24)
        (__local_put__goto_477_24 = __local_put__goto_477_24 + 1)
        ((unsafe *__ci_expr_old_60) = (((unsafe *__local_state__goto_475_31).length as u8)))
        (__local_left__goto_478_20 = (__local_left__goto_478_20 -% 1))
        ((unsafe *__local_state__goto_475_31).mode = ((16200 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_593 {
        if ((unsafe *__local_state__goto_475_31).wrap != 0) {
            goto '__ci_bb_594
        } else {
            goto '__ci_bb_595
        }
    }

    '__ci_bb_594 {
        goto '__ci_bb_596
    }

    '__ci_bb_595 {
        ((unsafe *__local_state__goto_475_31).mode = ((16207 as i32)))
        goto '__ci_bb_614
    }

    '__ci_bb_596 {
        goto '__ci_bb_599
    }

    '__ci_bb_597 {
        if (0 != 0) {
            goto '__ci_bb_596
        } else {
            goto '__ci_bb_598
        }
    }

    '__ci_bb_598 {
        (__local_out__goto_481_18 = (__local_out__goto_481_18 -% __local_left__goto_478_20))
        ((unsafe *__param_strm).total_out = ((unsafe *__param_strm).total_out +% __local_out__goto_481_18))
        ((unsafe *__local_state__goto_475_31).total = ((unsafe *__local_state__goto_475_31).total +% __local_out__goto_481_18))
        (__ci_expr_logic_62 = 0)
        if ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0) {
            (__ci_expr_logic_62 = (if __local_out__goto_481_18 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_62 != 0) {
            goto '__ci_bb_607
        } else {
            goto '__ci_bb_608
        }
    }

    '__ci_bb_599 {
        if ((if __local_bits__goto_480_14 < ((32 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_600
        } else {
            goto '__ci_bb_601
        }
    }

    '__ci_bb_600 {
        goto '__ci_bb_602
    }

    '__ci_bb_601 {
        goto '__ci_bb_597
    }

    '__ci_bb_602 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_605
        } else {
            goto '__ci_bb_606
        }
    }

    '__ci_bb_603 {
        if (0 != 0) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_604
        }
    }

    '__ci_bb_604 {
        goto '__ci_bb_599
    }

    '__ci_bb_605 {
        goto '__ci_bb_28
    }

    '__ci_bb_606 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_61 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_61) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_603
    }

    '__ci_bb_607 {
        (__ci_expr_ternary_63 = 0)
        if ((unsafe *__local_state__goto_475_31).flags != 0) {
            (__ci_expr_ternary_63 = ((crc32((unsafe *__local_state__goto_475_31).check, ((__local_put__goto_477_24 - (__local_out__goto_481_18 as usize)) as *const u8), __local_out__goto_481_18) as c_ulong)))
        } else {
            (__ci_expr_ternary_63 = ((adler32((unsafe *__local_state__goto_475_31).check, ((__local_put__goto_477_24 - (__local_out__goto_481_18 as usize)) as *const u8), __local_out__goto_481_18) as c_ulong)))
        }
        ((unsafe *__local_state__goto_475_31).check = __ci_expr_ternary_63)
        ((unsafe *__param_strm).adler = (unsafe *__local_state__goto_475_31).check)
        goto '__ci_bb_608
    }

    '__ci_bb_608 {
        (__local_out__goto_481_18 = __local_left__goto_478_20)
        (__ci_expr_logic_65 = 0)
        if ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0) {
            var __ci_expr_ternary_64: c_ulong = 0

            if ((unsafe *__local_state__goto_475_31).flags != 0) {
                (__ci_expr_ternary_64 = __local_hold__goto_479_19)
            } else {
                (__ci_expr_ternary_64 = ((((((((((((__local_hold__goto_479_19 as c_ulong) >> (24 as c_uint)) as c_ulong) & (255 as c_ulong)) as c_ulong) +% (((((__local_hold__goto_479_19 as c_ulong) >> (8 as c_uint)) as c_ulong) & (65280 as c_ulong)) as c_ulong)) as c_ulong) +% (((((__local_hold__goto_479_19 as c_ulong) & (65280 as c_ulong)) as c_ulong) << (8 as c_uint)) as c_ulong)) as c_ulong) +% (((((__local_hold__goto_479_19 as c_ulong) & (255 as c_ulong)) as c_ulong) << (24 as c_uint)) as c_ulong)) as c_ulong)))
            }

            (__ci_expr_logic_65 = (if (if __ci_expr_ternary_64 != (unsafe *__local_state__goto_475_31).check: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_65 != 0) {
            goto '__ci_bb_609
        } else {
            goto '__ci_bb_610
        }
    }

    '__ci_bb_609 {
        ((unsafe *__param_strm).msg = (("incorrect data check" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_610 {
        goto '__ci_bb_611
    }

    '__ci_bb_611 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_612
    }

    '__ci_bb_612 {
        if (0 != 0) {
            goto '__ci_bb_611
        } else {
            goto '__ci_bb_613
        }
    }

    '__ci_bb_613 {
        goto '__ci_bb_595
    }

    '__ci_bb_614 {
        (__ci_expr_logic_66 = 0)
        if ((unsafe *__local_state__goto_475_31).wrap != 0) {
            (__ci_expr_logic_66 = (if (unsafe *__local_state__goto_475_31).flags != 0: 1 else: 0))
        }
        if (__ci_expr_logic_66 != 0) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_616
        }
    }

    '__ci_bb_615 {
        goto '__ci_bb_617
    }

    '__ci_bb_616 {
        ((unsafe *__local_state__goto_475_31).mode = ((16208 as i32)))
        goto '__ci_bb_633
    }

    '__ci_bb_617 {
        goto '__ci_bb_620
    }

    '__ci_bb_618 {
        if (0 != 0) {
            goto '__ci_bb_617
        } else {
            goto '__ci_bb_619
        }
    }

    '__ci_bb_619 {
        (__ci_expr_logic_68 = 0)
        if ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0) {
            (__ci_expr_logic_68 = (if (if __local_hold__goto_479_19 != (((unsafe *__local_state__goto_475_31).total as c_ulong) & ((4294967295 as c_ulong) as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_68 != 0) {
            goto '__ci_bb_628
        } else {
            goto '__ci_bb_629
        }
    }

    '__ci_bb_620 {
        if ((if __local_bits__goto_480_14 < ((32 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_621
        } else {
            goto '__ci_bb_622
        }
    }

    '__ci_bb_621 {
        goto '__ci_bb_623
    }

    '__ci_bb_622 {
        goto '__ci_bb_618
    }

    '__ci_bb_623 {
        if ((if __local_have__goto_478_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_626
        } else {
            goto '__ci_bb_627
        }
    }

    '__ci_bb_624 {
        if (0 != 0) {
            goto '__ci_bb_623
        } else {
            goto '__ci_bb_625
        }
    }

    '__ci_bb_625 {
        goto '__ci_bb_620
    }

    '__ci_bb_626 {
        goto '__ci_bb_28
    }

    '__ci_bb_627 {
        (__local_have__goto_478_14 = (__local_have__goto_478_14 -% 1))
        (__ci_expr_old_67 = __local_next__goto_476_32)
        (__local_next__goto_476_32 = __local_next__goto_476_32 + 1)
        (__local_hold__goto_479_19 = (__local_hold__goto_479_19 +% ((((unsafe *__ci_expr_old_67) as c_ulong) as c_ulong) << (__local_bits__goto_480_14 as c_uint))))
        (__local_bits__goto_480_14 = (__local_bits__goto_480_14 +% 8))
        goto '__ci_bb_624
    }

    '__ci_bb_628 {
        ((unsafe *__param_strm).msg = (("incorrect length check" as *mut c_char)))
        ((unsafe *__local_state__goto_475_31).mode = ((16209 as i32)))
        goto '__ci_bb_13
    }

    '__ci_bb_629 {
        goto '__ci_bb_630
    }

    '__ci_bb_630 {
        (__local_hold__goto_479_19 = ((0 as c_ulong)))
        (__local_bits__goto_480_14 = ((0 as c_uint)))
        goto '__ci_bb_631
    }

    '__ci_bb_631 {
        if (0 != 0) {
            goto '__ci_bb_630
        } else {
            goto '__ci_bb_632
        }
    }

    '__ci_bb_632 {
        goto '__ci_bb_616
    }

    '__ci_bb_633 {
        (__local_ret__goto_487_9 = ((1 as c_int)))
        goto '__ci_bb_28
    }

    '__ci_bb_634 {
        (__local_ret__goto_487_9 = ((-3 as c_int)))
        goto '__ci_bb_28
    }

    '__ci_bb_635 {
        return -4
    }

    '__ci_bb_636 {
        return -2
    }

    '__ci_bb_637 {
        if ((unsafe *__local_state__goto_475_31).mode == 16181) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_638
        }
    }

    '__ci_bb_638 {
        if ((unsafe *__local_state__goto_475_31).mode == 16182) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_639
        }
    }

    '__ci_bb_639 {
        if ((unsafe *__local_state__goto_475_31).mode == 16183) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_640
        }
    }

    '__ci_bb_640 {
        if ((unsafe *__local_state__goto_475_31).mode == 16184) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_641
        }
    }

    '__ci_bb_641 {
        if ((unsafe *__local_state__goto_475_31).mode == 16185) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_642
        }
    }

    '__ci_bb_642 {
        if ((unsafe *__local_state__goto_475_31).mode == 16186) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_643
        }
    }

    '__ci_bb_643 {
        if ((unsafe *__local_state__goto_475_31).mode == 16187) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_644
        }
    }

    '__ci_bb_644 {
        if ((unsafe *__local_state__goto_475_31).mode == 16188) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_645
        }
    }

    '__ci_bb_645 {
        if ((unsafe *__local_state__goto_475_31).mode == 16189) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_646
        }
    }

    '__ci_bb_646 {
        if ((unsafe *__local_state__goto_475_31).mode == 16190) {
            goto '__ci_bb_235
        } else {
            goto '__ci_bb_647
        }
    }

    '__ci_bb_647 {
        if ((unsafe *__local_state__goto_475_31).mode == 16191) {
            goto '__ci_bb_241
        } else {
            goto '__ci_bb_648
        }
    }

    '__ci_bb_648 {
        if ((unsafe *__local_state__goto_475_31).mode == 16192) {
            goto '__ci_bb_244
        } else {
            goto '__ci_bb_649
        }
    }

    '__ci_bb_649 {
        if ((unsafe *__local_state__goto_475_31).mode == 16193) {
            goto '__ci_bb_280
        } else {
            goto '__ci_bb_650
        }
    }

    '__ci_bb_650 {
        if ((unsafe *__local_state__goto_475_31).mode == 16194) {
            goto '__ci_bb_302
        } else {
            goto '__ci_bb_651
        }
    }

    '__ci_bb_651 {
        if ((unsafe *__local_state__goto_475_31).mode == 16195) {
            goto '__ci_bb_303
        } else {
            goto '__ci_bb_652
        }
    }

    '__ci_bb_652 {
        if ((unsafe *__local_state__goto_475_31).mode == 16196) {
            goto '__ci_bb_312
        } else {
            goto '__ci_bb_653
        }
    }

    '__ci_bb_653 {
        if ((unsafe *__local_state__goto_475_31).mode == 16197) {
            goto '__ci_bb_335
        } else {
            goto '__ci_bb_654
        }
    }

    '__ci_bb_654 {
        if ((unsafe *__local_state__goto_475_31).mode == 16198) {
            goto '__ci_bb_358
        } else {
            goto '__ci_bb_655
        }
    }

    '__ci_bb_655 {
        if ((unsafe *__local_state__goto_475_31).mode == 16199) {
            goto '__ci_bb_453
        } else {
            goto '__ci_bb_656
        }
    }

    '__ci_bb_656 {
        if ((unsafe *__local_state__goto_475_31).mode == 16200) {
            goto '__ci_bb_454
        } else {
            goto '__ci_bb_657
        }
    }

    '__ci_bb_657 {
        if ((unsafe *__local_state__goto_475_31).mode == 16201) {
            goto '__ci_bb_501
        } else {
            goto '__ci_bb_658
        }
    }

    '__ci_bb_658 {
        if ((unsafe *__local_state__goto_475_31).mode == 16202) {
            goto '__ci_bb_518
        } else {
            goto '__ci_bb_659
        }
    }

    '__ci_bb_659 {
        if ((unsafe *__local_state__goto_475_31).mode == 16203) {
            goto '__ci_bb_551
        } else {
            goto '__ci_bb_660
        }
    }

    '__ci_bb_660 {
        if ((unsafe *__local_state__goto_475_31).mode == 16204) {
            goto '__ci_bb_568
        } else {
            goto '__ci_bb_661
        }
    }

    '__ci_bb_661 {
        if ((unsafe *__local_state__goto_475_31).mode == 16205) {
            goto '__ci_bb_590
        } else {
            goto '__ci_bb_662
        }
    }

    '__ci_bb_662 {
        if ((unsafe *__local_state__goto_475_31).mode == 16206) {
            goto '__ci_bb_593
        } else {
            goto '__ci_bb_663
        }
    }

    '__ci_bb_663 {
        if ((unsafe *__local_state__goto_475_31).mode == 16207) {
            goto '__ci_bb_614
        } else {
            goto '__ci_bb_664
        }
    }

    '__ci_bb_664 {
        if ((unsafe *__local_state__goto_475_31).mode == 16208) {
            goto '__ci_bb_633
        } else {
            goto '__ci_bb_665
        }
    }

    '__ci_bb_665 {
        if ((unsafe *__local_state__goto_475_31).mode == 16209) {
            goto '__ci_bb_634
        } else {
            goto '__ci_bb_666
        }
    }

    '__ci_bb_666 {
        if ((unsafe *__local_state__goto_475_31).mode == 16210) {
            goto '__ci_bb_635
        } else {
            goto '__ci_bb_667
        }
    }

    '__ci_bb_667 {
        if ((unsafe *__local_state__goto_475_31).mode == 16211) {
            goto '__ci_bb_636
        } else {
            goto '__ci_bb_636
        }
    }

    '__ci_bb_668 {
        ((unsafe *__param_strm).next_out = __local_put__goto_477_24)
        ((unsafe *__param_strm).avail_out = __local_left__goto_478_20)
        ((unsafe *__param_strm).next_in = __local_next__goto_476_32)
        ((unsafe *__param_strm).avail_in = __local_have__goto_478_14)
        ((unsafe *__local_state__goto_475_31).hold = __local_hold__goto_479_19)
        ((unsafe *__local_state__goto_475_31).bits = __local_bits__goto_480_14)
        goto '__ci_bb_669
    }

    '__ci_bb_669 {
        if (0 != 0) {
            goto '__ci_bb_668
        } else {
            goto '__ci_bb_670
        }
    }

    '__ci_bb_670 {
        if ((unsafe *__local_state__goto_475_31).wsize != 0) {
            (__ci_expr_logic_72 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_71: c_int = 0

            var __ci_expr_logic_69: c_int = 0

            if ((if __local_out__goto_481_18 != (unsafe *__param_strm).avail_out: 1 else: 0) != 0) {
                (__ci_expr_logic_69 = (if (if (unsafe *__local_state__goto_475_31).mode < 16209: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_69 != 0) {
                var __ci_expr_logic_70: c_int

                if ((if (unsafe *__local_state__goto_475_31).mode < 16206: 1 else: 0) != 0) {
                    (__ci_expr_logic_70 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_70 = (if (if __param_flush != 4: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_71 = (if __ci_expr_logic_70 != 0: 1 else: 0))

            }

            (__ci_expr_logic_72 = (if __ci_expr_logic_71 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_72 != 0) {
            goto '__ci_bb_671
        } else {
            goto '__ci_bb_672
        }
    }

    '__ci_bb_671 {
        if (updatewindow(__param_strm, ((unsafe *__param_strm).next_out as *const u8), (((__local_out__goto_481_18 as c_uint) -% ((unsafe *__param_strm).avail_out as c_uint)) as c_uint)) != 0) {
            goto '__ci_bb_673
        } else {
            goto '__ci_bb_674
        }
    }

    '__ci_bb_672 {
        (__local_in___goto_481_14 = (__local_in___goto_481_14 -% (unsafe *__param_strm).avail_in))
        (__local_out__goto_481_18 = (__local_out__goto_481_18 -% (unsafe *__param_strm).avail_out))
        ((unsafe *__param_strm).total_in = ((unsafe *__param_strm).total_in +% __local_in___goto_481_14))
        ((unsafe *__param_strm).total_out = ((unsafe *__param_strm).total_out +% __local_out__goto_481_18))
        ((unsafe *__local_state__goto_475_31).total = ((unsafe *__local_state__goto_475_31).total +% __local_out__goto_481_18))
        (__ci_expr_logic_73 = 0)
        if ((((unsafe *__local_state__goto_475_31).wrap as c_int) & (4 as c_int)) != 0) {
            (__ci_expr_logic_73 = (if __local_out__goto_481_18 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_73 != 0) {
            goto '__ci_bb_675
        } else {
            goto '__ci_bb_676
        }
    }

    '__ci_bb_673 {
        ((unsafe *__local_state__goto_475_31).mode = ((16210 as i32)))
        return -4
    }

    '__ci_bb_674 {
        goto '__ci_bb_672
    }

    '__ci_bb_675 {
        (__ci_expr_ternary_74 = 0)
        if ((unsafe *__local_state__goto_475_31).flags != 0) {
            (__ci_expr_ternary_74 = ((crc32((unsafe *__local_state__goto_475_31).check, (((unsafe *__param_strm).next_out - (__local_out__goto_481_18 as usize)) as *const u8), __local_out__goto_481_18) as c_ulong)))
        } else {
            (__ci_expr_ternary_74 = ((adler32((unsafe *__local_state__goto_475_31).check, (((unsafe *__param_strm).next_out - (__local_out__goto_481_18 as usize)) as *const u8), __local_out__goto_481_18) as c_ulong)))
        }
        ((unsafe *__local_state__goto_475_31).check = __ci_expr_ternary_74)
        ((unsafe *__param_strm).adler = (unsafe *__local_state__goto_475_31).check)
        goto '__ci_bb_676
    }

    '__ci_bb_676 {
        (__ci_expr_ternary_75 = 0)
        if ((unsafe *__local_state__goto_475_31).last != 0) {
            (__ci_expr_ternary_75 = ((64 as c_int)))
        } else {
            (__ci_expr_ternary_75 = ((0 as c_int)))
        }
        (__ci_expr_ternary_76 = 0)
        if ((if (unsafe *__local_state__goto_475_31).mode == 16191: 1 else: 0) != 0) {
            (__ci_expr_ternary_76 = ((128 as c_int)))
        } else {
            (__ci_expr_ternary_76 = ((0 as c_int)))
        }
        (__ci_expr_ternary_78 = 0)
        if ((if (unsafe *__local_state__goto_475_31).mode == 16199: 1 else: 0) != 0) {
            (__ci_expr_logic_77 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_77 = (if (if (unsafe *__local_state__goto_475_31).mode == 16194: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_77 != 0) {
            (__ci_expr_ternary_78 = ((256 as c_int)))
        } else {
            (__ci_expr_ternary_78 = ((0 as c_int)))
        }
        ((unsafe *__param_strm).data_type = (((((((unsafe *__local_state__goto_475_31).bits as c_int) + __ci_expr_ternary_75) + __ci_expr_ternary_76) + __ci_expr_ternary_78) as c_int)))
        (__ci_expr_logic_81 = 0)
        (__ci_expr_logic_79 = 0)
        if ((if __local_in___goto_481_14 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_79 = (if (if __local_out__goto_481_18 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_79 != 0) {
            (__ci_expr_logic_80 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_80 = (if (if __param_flush == 4: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_80 != 0) {
            (__ci_expr_logic_81 = (if (if __local_ret__goto_487_9 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_81 != 0) {
            goto '__ci_bb_677
        } else {
            goto '__ci_bb_678
        }
    }

    '__ci_bb_677 {
        (__local_ret__goto_487_9 = ((-5 as c_int)))
        goto '__ci_bb_678
    }

    '__ci_bb_678 {
        return __local_ret__goto_487_9
    }

}

pub unsafe fn inflateEnd(__param_strm: *mut z_stream_s) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    if ((if (unsafe *__local_state).window != 0: 1 else: 0) != 0) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *__local_state).window as *mut c_void))
    }

    (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *__param_strm).state as *mut c_void))

    ((unsafe *__param_strm).state = null)

    return 0

}

pub unsafe fn inflateSetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *const u8, __param_dictLength: c_uint) -> c_int {
    var __local_state: *mut inflate_state

    var __local_dictid: c_ulong

    var __local_ret: c_int

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__local_state).wrap != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *__local_state).mode != 16190: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2
    }


    if ((if (unsafe *__local_state).mode == 16190: 1 else: 0) != 0) {
        (__local_dictid = ((adler32((0 as c_ulong), null, (0 as c_uint)) as c_ulong)))

        (__local_dictid = ((adler32(__local_dictid, __param_dictionary, __param_dictLength) as c_ulong)))

        if ((if __local_dictid != (unsafe *__local_state).check: 1 else: 0) != 0) {
            return -3
        }

    }

    (__local_ret = ((updatewindow(__param_strm, (__param_dictionary + (__param_dictLength as usize)), __param_dictLength) as c_int)))

    if (__local_ret != 0) {
        ((unsafe *__local_state).mode = ((16210 as i32)))

        return -4

    }

    ((unsafe *__local_state).havedict = ((1 as c_int)))

    return 0

}

pub unsafe fn inflateGetDictionary(__param_strm: *mut z_stream_s, __param_dictionary: *mut u8, __param_dictLength: *mut c_uint) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((unsafe *__local_state).whave != 0) {
        (__ci_expr_logic_0 = (if (if __param_dictionary != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy(((__param_dictionary as *mut c_void) as *i8), ((((unsafe *__local_state).window + ((unsafe *__local_state).wnext as usize)) as *const c_void) as *i8), (((((unsafe *__local_state).whave as c_uint) -% ((unsafe *__local_state).wnext as c_uint)) as c_ulong) as i64))

        with_memcpy(((((__param_dictionary + ((unsafe *__local_state).whave as usize)) - ((unsafe *__local_state).wnext as usize)) as *mut c_void) as *i8), (((unsafe *__local_state).window as *const c_void) as *i8), (((unsafe *__local_state).wnext as c_ulong) as i64))

    }


    if ((if __param_dictLength != 0: 1 else: 0) != 0) {
        ((unsafe *__param_dictLength) = (unsafe *__local_state).whave)
    }

    return 0

}

pub unsafe fn inflateSync(__param_strm: *mut z_stream_s) -> c_int {
    var __local_len: c_uint

    var __local_flags: c_int

    var __local_in_: c_ulong

    var __local_out: c_ulong


    var __local_buf: [4]u8

    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__param_strm).avail_in == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *__local_state).bits < 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -5
    }


    if ((if (unsafe *__local_state).mode != 16211: 1 else: 0) != 0) {
        ((unsafe *__local_state).mode = ((16211 as i32)))

        ((unsafe *__local_state).hold = (unsafe *__local_state).hold >> ((((unsafe *__local_state).bits as c_uint) & (7 as c_uint)) as c_uint))

        ((unsafe *__local_state).bits = ((unsafe *__local_state).bits -% (((unsafe *__local_state).bits as c_uint) & (7 as c_uint))))

        (__local_len = ((0 as c_uint)))

        while ((if (unsafe *__local_state).bits >= 8: 1 else: 0) != 0) {
            var __ci_expr_old_1: c_uint = __local_len

            (__local_len = (__local_len +% 1))

            (__local_buf[__ci_expr_old_1] = (((unsafe *__local_state).hold as u8)))


            ((unsafe *__local_state).hold = (unsafe *__local_state).hold >> (8 as c_uint))

            ((unsafe *__local_state).bits = ((unsafe *__local_state).bits -% 8))

        }

        ((unsafe *__local_state).have = ((0 as c_uint)))

        syncsearch(((&raw const (unsafe *__local_state).have as *const c_uint) as *mut c_uint), (&__local_buf[0] as *mut u8), __local_len)

    }

    (__local_len = ((syncsearch(((&raw const (unsafe *__local_state).have as *const c_uint) as *mut c_uint), ((unsafe *__param_strm).next_in as *const u8), (unsafe *__param_strm).avail_in) as c_uint)))

    ((unsafe *__param_strm).avail_in = ((unsafe *__param_strm).avail_in -% __local_len))

    ((unsafe *__param_strm).next_in = (unsafe *__param_strm).next_in + (__local_len as usize))

    ((unsafe *__param_strm).total_in = ((unsafe *__param_strm).total_in +% __local_len))

    if ((if (unsafe *__local_state).have != 4: 1 else: 0) != 0) {
        return -3
    }

    if ((if (unsafe *__local_state).flags == -1: 1 else: 0) != 0) {
        ((unsafe *__local_state).wrap = ((0 as c_int)))
    } else {
        ((unsafe *__local_state).wrap = ((unsafe *__local_state).wrap as c_int) & ((~4) as c_int))
    }

    (__local_flags = (unsafe *__local_state).flags)

    (__local_in_ = (unsafe *__param_strm).total_in)

    (__local_out = (unsafe *__param_strm).total_out)

    inflateReset(__param_strm)

    ((unsafe *__param_strm).total_in = __local_in_)

    ((unsafe *__param_strm).total_out = __local_out)

    ((unsafe *__local_state).flags = __local_flags)

    ((unsafe *__local_state).mode = ((16191 as i32)))

    return 0

}

pub unsafe fn inflateCopy(__param_dest: *mut z_stream_s, __param_source: *mut z_stream_s) -> c_int {
    var __local_state: *mut inflate_state

    var __local_copy_: *mut inflate_state

    var __local_window: *mut u8

    var __ci_expr_logic_0: c_int

    if (inflateStateCheck(__param_source) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_dest == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2
    }


    (__local_state = (((unsafe *__param_source).state as *mut inflate_state)))

    (__local_copy_ = (((unsafe *__param_source).zalloc((unsafe *__param_source).opaque_, 1, 7160) as *mut inflate_state)))

    if ((if __local_copy_ == 0: 1 else: 0) != 0) {
        return -4
    }

    with_memset(((__local_copy_ as *mut c_void) as *i8), (0 as c_int), ((sizeof[inflate_state]() as c_ulong) as i64))

    (__local_window = null)

    if ((if (unsafe *__local_state).window != 0: 1 else: 0) != 0) {
        (__local_window = (((unsafe *__param_source).zalloc((unsafe *__param_source).opaque_, ((1 as c_uint) << ((unsafe *__local_state).wbits as c_uint)), 1) as *mut u8)))

        if ((if __local_window == 0: 1 else: 0) != 0) {
            (unsafe *__param_source).zfree((unsafe *__param_source).opaque_, (__local_copy_ as *mut c_void))

            return -4

        }

    }

    with_memcpy(((__param_dest as *mut c_void) as *i8), ((__param_source as *const c_void) as *i8), ((sizeof[z_stream_s]() as c_ulong) as i64))

    with_memcpy(((__local_copy_ as *mut c_void) as *i8), ((__local_state as *const c_void) as *i8), ((sizeof[inflate_state]() as c_ulong) as i64))

    ((unsafe *__local_copy_).strm = __param_dest)

    var __ci_expr_logic_1: c_int = 0

    if ((if (unsafe *__local_state).lencode >= (&(unsafe *__local_state).codes[0] as *const code): 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (unsafe *__local_state).lencode <= (((&(unsafe *__local_state).codes[0] as *mut code) + (((852 + 592) as isize) as usize)) - ((1 as isize) as usize)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((unsafe *__local_copy_).lencode = ((((&(unsafe *__local_copy_).codes[0] as *mut code) + ((((((unsafe *__local_state).lencode as usize) -% ((&(unsafe *__local_state).codes[0] as *mut code) as usize)) / sizeof[code]()) as isize) as usize)) as *const code)))

        ((unsafe *__local_copy_).distcode = ((((&(unsafe *__local_copy_).codes[0] as *mut code) + ((((((unsafe *__local_state).distcode as usize) -% ((&(unsafe *__local_state).codes[0] as *mut code) as usize)) / sizeof[code]()) as isize) as usize)) as *const code)))

    }


    ((unsafe *__local_copy_).next = (&(unsafe *__local_copy_).codes[0] as *mut code) + ((((((unsafe *__local_state).next as usize) -% ((&(unsafe *__local_state).codes[0] as *mut code) as usize)) / sizeof[code]()) as isize) as usize))

    if ((if __local_window != 0: 1 else: 0) != 0) {
        with_memcpy(((__local_window as *mut c_void) as *i8), (((unsafe *__local_state).window as *const c_void) as *i8), (((unsafe *__local_state).whave as c_ulong) as i64))
    }

    ((unsafe *__local_copy_).window = __local_window)

    ((unsafe *__param_dest).state = ((__local_copy_ as *mut internal_state)))

    return 0

}

pub unsafe fn inflateReset(__param_strm: *mut z_stream_s) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    ((unsafe *__local_state).wsize = ((0 as c_uint)))

    ((unsafe *__local_state).whave = ((0 as c_uint)))

    ((unsafe *__local_state).wnext = ((0 as c_uint)))

    return inflateResetKeep(__param_strm)

}

pub unsafe fn inflateReset2(__param_strm: *mut z_stream_s, __param_windowBits: c_int) -> c_int {
    var __local_windowBits = __param_windowBits
    var __local_wrap: c_int

    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    if ((if __local_windowBits < 0: 1 else: 0) != 0) {
        if ((if __local_windowBits < -15: 1 else: 0) != 0) {
            return -2
        }

        (__local_wrap = ((0 as c_int)))

        (__local_windowBits = (((0 - __local_windowBits) as c_int)))

    } else {
        (__local_wrap = (((((__local_windowBits as c_int) >> (4 as c_uint)) + 5) as c_int)))

        if ((if __local_windowBits < 48: 1 else: 0) != 0) {
            (__local_windowBits = (__local_windowBits as c_int) & (15 as c_int))
        }

    }

    var __ci_expr_logic_1: c_int = 0

    if (__local_windowBits != 0) {
        var __ci_expr_logic_0: c_int

        if ((if __local_windowBits < 8: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_windowBits > 15: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return -2
    }


    var __ci_expr_logic_2: c_int = 0

    if ((if (unsafe *__local_state).window != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (unsafe *__local_state).wbits != ((__local_windowBits as c_uint)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *__local_state).window as *mut c_void))

        ((unsafe *__local_state).window = null)

    }


    ((unsafe *__local_state).wrap = __local_wrap)

    ((unsafe *__local_state).wbits = ((__local_windowBits as c_uint)))

    return inflateReset(__param_strm)

}

pub unsafe fn inflatePrime(__param_strm: *mut z_stream_s, __param_bits: c_int, __param_value: c_int) -> c_int {
    var __local_value = __param_value
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    if ((if __param_bits == 0: 1 else: 0) != 0) {
        return 0
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    if ((if __param_bits < 0: 1 else: 0) != 0) {
        ((unsafe *__local_state).hold = ((0 as c_ulong)))

        ((unsafe *__local_state).bits = ((0 as c_uint)))

        return 0

    }

    var __ci_expr_logic_0: c_int

    if ((if __param_bits > 16: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (((unsafe *__local_state).bits as c_uint) +% ((__param_bits as c_uint) as c_uint)) > 32: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return -2
    }


    (__local_value = (__local_value as c_int) & ((((1 as c_long) << (__param_bits as c_uint)) - 1) as c_int))

    ((unsafe *__local_state).hold = ((unsafe *__local_state).hold +% (((__local_value as c_ulong) as c_ulong) << ((unsafe *__local_state).bits as c_uint))))

    ((unsafe *__local_state).bits = ((unsafe *__local_state).bits +% (__param_bits as c_uint)))

    return 0

}

pub unsafe fn inflateMark(__param_strm: *mut z_stream_s) -> c_long {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return (0 - ((1 as c_long) << (16 as c_uint)))
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_ternary_1: c_uint = 0

    if ((if (unsafe *__local_state).mode == 16195: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = (unsafe *__local_state).length)
    } else {
        var __ci_expr_ternary_0: c_uint = 0

        if ((if (unsafe *__local_state).mode == 16204: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((((unsafe *__local_state).was as c_uint) -% ((unsafe *__local_state).length as c_uint)) as c_uint)))
        } else {
            (__ci_expr_ternary_0 = ((0 as c_uint)))
        }

        (__ci_expr_ternary_1 = __ci_expr_ternary_0)

    }

    return (((((((unsafe *__local_state).back as c_long) as c_ulong) as c_ulong) << (16 as c_uint)) as c_long) + __ci_expr_ternary_1)


}

pub unsafe fn inflateGetHeader(__param_strm: *mut z_stream_s, __param_head: *mut gz_header_s) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    if ((if (((unsafe *__local_state).wrap as c_int) & (2 as c_int)) == 0: 1 else: 0) != 0) {
        return -2
    }

    ((unsafe *__local_state).head = __param_head)

    ((unsafe *__param_head).done = ((0 as c_int)))

    return 0

}

pub unsafe fn inflateInit_(__param_strm: *mut z_stream_s, __param_version: *const i8, __param_stream_size: c_int) -> c_int {
    return inflateInit2_(__param_strm, (15 as c_int), __param_version, __param_stream_size)

}

pub unsafe fn inflateInit2_(__param_strm: *mut z_stream_s, __param_windowBits: c_int, __param_version: *const i8, __param_stream_size: c_int) -> c_int {
    var __local_ret: c_int

    var __local_state: *mut inflate_state

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
        (__ci_expr_logic_1 = (if (if __param_stream_size != ((sizeof[z_stream_s]() as c_int)): 1 else: 0) != 0: 1 else: 0))
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

    (__local_state = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, 1, 7160) as *mut inflate_state)))

    if ((if __local_state == 0: 1 else: 0) != 0) {
        return -4
    }

    with_memset(((__local_state as *mut c_void) as *i8), (0 as c_int), ((sizeof[inflate_state]() as c_ulong) as i64))

    ((unsafe *__param_strm).state = ((__local_state as *mut internal_state)))

    ((unsafe *__local_state).strm = __param_strm)

    ((unsafe *__local_state).window = null)

    ((unsafe *__local_state).mode = ((16180 as i32)))

    (__local_ret = ((inflateReset2(__param_strm, __param_windowBits) as c_int)))

    if ((if __local_ret != 0: 1 else: 0) != 0) {
        (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, (__local_state as *mut c_void))

        ((unsafe *__param_strm).state = null)

    }

    return __local_ret

}

pub unsafe fn inflateSyncPoint(__param_strm: *mut z_stream_s) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__local_state).mode == 16193: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *__local_state).bits == 0: 1 else: 0) != 0: 1 else: 0))
    }

    return __ci_expr_logic_0


}

pub unsafe fn inflateUndermine(__param_strm: *mut z_stream_s, __param_subvert: c_int) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    __param_subvert

    ((unsafe *__local_state).sane = ((1 as c_int)))

    return -3

}

pub unsafe fn inflateValidate(__param_strm: *mut z_stream_s, __param_check: c_int) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_logic_0: c_int = 0

    if (__param_check != 0) {
        (__ci_expr_logic_0 = (if (unsafe *__local_state).wrap != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((unsafe *__local_state).wrap = ((unsafe *__local_state).wrap as c_int) | (4 as c_int))
    } else {
        ((unsafe *__local_state).wrap = ((unsafe *__local_state).wrap as c_int) & ((~4) as c_int))
    }


    return 0

}

pub unsafe fn inflateCodesUsed(__param_strm: *mut z_stream_s) -> c_ulong {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return ((-1 as c_ulong))
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    return ((((((unsafe *__local_state).next as usize) -% ((&(unsafe *__local_state).codes[0] as *mut code) as usize)) / sizeof[code]()) as c_ulong))

}

pub unsafe fn inflateResetKeep(__param_strm: *mut z_stream_s) -> c_int {
    var __local_state: *mut inflate_state

    if (inflateStateCheck(__param_strm) != 0) {
        return -2
    }

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    ((unsafe *__local_state).total = ((0 as c_ulong)))

    ((unsafe *__param_strm).total_out = (unsafe *__local_state).total)

    ((unsafe *__param_strm).total_in = (unsafe *__param_strm).total_out)


    ((unsafe *__param_strm).msg = null)

    ((unsafe *__param_strm).data_type = ((0 as c_int)))

    if ((unsafe *__local_state).wrap != 0) {
        ((unsafe *__param_strm).adler = (((((unsafe *__local_state).wrap as c_int) & (1 as c_int)) as c_ulong)))
    }

    ((unsafe *__local_state).mode = ((16180 as i32)))

    ((unsafe *__local_state).last = ((0 as c_int)))

    ((unsafe *__local_state).havedict = ((0 as c_int)))

    ((unsafe *__local_state).flags = ((-1 as c_int)))

    ((unsafe *__local_state).dmax = ((32768 as c_uint)))

    ((unsafe *__local_state).head = null)

    ((unsafe *__local_state).hold = ((0 as c_ulong)))

    ((unsafe *__local_state).bits = ((0 as c_uint)))

    ((unsafe *__local_state).next = (&(unsafe *__local_state).codes[0] as *mut code))

    ((unsafe *__local_state).distcode = (((unsafe *__local_state).next as *const code)))

    ((unsafe *__local_state).lencode = (unsafe *__local_state).distcode)


    ((unsafe *__local_state).sane = ((1 as c_int)))

    ((unsafe *__local_state).back = ((-1 as c_int)))

    return 0

}

unsafe fn inflateStateCheck(__param_strm: *mut z_stream_s) -> c_int {
    var __local_state: *mut inflate_state

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


    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    var __ci_expr_logic_4: c_int

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if __local_state == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (unsafe *__local_state).strm != __param_strm: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if (unsafe *__local_state).mode < 16180: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if (unsafe *__local_state).mode > 16211: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        return 1
    }


    return 0

}

unsafe fn updatewindow(__param_strm: *mut z_stream_s, __param_end: *const u8, __param_copy_: c_uint) -> c_int {
    var __local_copy_ = __param_copy_
    var __local_state: *mut inflate_state

    var __local_dist: c_uint

    (__local_state = (((unsafe *__param_strm).state as *mut inflate_state)))

    if ((if (unsafe *__local_state).window == 0: 1 else: 0) != 0) {
        ((unsafe *__local_state).window = (((unsafe *__param_strm).zalloc((unsafe *__param_strm).opaque_, ((1 as c_uint) << ((unsafe *__local_state).wbits as c_uint)), 1) as *mut u8)))

        if ((if (unsafe *__local_state).window == 0: 1 else: 0) != 0) {
            return 1
        }

    }

    if ((if (unsafe *__local_state).wsize == 0: 1 else: 0) != 0) {
        ((unsafe *__local_state).wsize = ((((1 as c_uint) << ((unsafe *__local_state).wbits as c_uint)) as c_uint)))

        ((unsafe *__local_state).wnext = ((0 as c_uint)))

        ((unsafe *__local_state).whave = ((0 as c_uint)))

    }

    if ((if __local_copy_ >= (unsafe *__local_state).wsize: 1 else: 0) != 0) {
        with_memcpy((((unsafe *__local_state).window as *mut c_void) as *i8), (((__param_end - ((unsafe *__local_state).wsize as usize)) as *const c_void) as *i8), (((unsafe *__local_state).wsize as c_ulong) as i64))

        ((unsafe *__local_state).wnext = ((0 as c_uint)))

        ((unsafe *__local_state).whave = (unsafe *__local_state).wsize)

    } else {
        (__local_dist = (((((unsafe *__local_state).wsize as c_uint) -% ((unsafe *__local_state).wnext as c_uint)) as c_uint)))

        if ((if __local_dist > __local_copy_: 1 else: 0) != 0) {
            (__local_dist = __local_copy_)
        }

        with_memcpy(((((unsafe *__local_state).window + ((unsafe *__local_state).wnext as usize)) as *mut c_void) as *i8), (((__param_end - (__local_copy_ as usize)) as *const c_void) as *i8), ((__local_dist as c_ulong) as i64))

        (__local_copy_ = (__local_copy_ -% __local_dist))

        if (__local_copy_ != 0) {
            with_memcpy((((unsafe *__local_state).window as *mut c_void) as *i8), (((__param_end - (__local_copy_ as usize)) as *const c_void) as *i8), ((__local_copy_ as c_ulong) as i64))

            ((unsafe *__local_state).wnext = __local_copy_)

            ((unsafe *__local_state).whave = (unsafe *__local_state).wsize)

        } else {
            ((unsafe *__local_state).wnext = ((unsafe *__local_state).wnext +% __local_dist))

            if ((if (unsafe *__local_state).wnext == (unsafe *__local_state).wsize: 1 else: 0) != 0) {
                ((unsafe *__local_state).wnext = ((0 as c_uint)))
            }

            if ((if (unsafe *__local_state).whave < (unsafe *__local_state).wsize: 1 else: 0) != 0) {
                ((unsafe *__local_state).whave = ((unsafe *__local_state).whave +% __local_dist))
            }

        }

    }

    return 0

}

unsafe fn syncsearch(__param_have: *mut c_uint, __param_buf: *const u8, __param_len: c_uint) -> c_uint {
    var __local_got: c_uint

    var __local_next: c_uint

    (__local_got = (unsafe *__param_have))

    (__local_next = ((0 as c_uint)))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_next < __param_len: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_got < 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __ci_expr_ternary_1: c_int = 0

        if ((if __local_got < 2: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = ((0 as c_int)))
        } else {
            (__ci_expr_ternary_1 = ((255 as c_int)))
        }

        if ((if (((unsafe __param_buf[__local_next]) as c_int)) == __ci_expr_ternary_1: 1 else: 0) != 0) {
            (__local_got = (__local_got +% 1))
        } else {
            if ((unsafe __param_buf[__local_next]) != 0) {
                (__local_got = ((0 as c_uint)))
            } else {
                (__local_got = ((((4 as c_uint) -% (__local_got as c_uint)) as c_uint)))
            }
        }

        (__local_next = (__local_next +% 1))

    }

    ((unsafe *__param_have) = __local_got)

    return __local_next

}
