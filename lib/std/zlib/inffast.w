// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
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

pub unsafe fn inflate_fast(__param_strm: *mut z_stream_s, __param_start: c_uint) -> Unit {
    var __local_state__goto_51_31: *mut inflate_state = null

    var __local_in___goto_52_32: *mut u8 = null

    var __local_last__goto_53_32: *mut u8 = null

    var __local_out__goto_54_24: *mut u8 = null

    var __local_beg__goto_55_24: *mut u8 = null

    var __local_end__goto_56_24: *mut u8 = null

    var __local_wsize__goto_60_14: c_uint = 0

    var __local_whave__goto_61_14: c_uint = 0

    var __local_wnext__goto_62_14: c_uint = 0

    var __local_window__goto_63_24: *mut u8 = null

    var __local_hold__goto_64_19: c_ulong = 0

    var __local_bits__goto_65_14: c_uint = 0

    var __local_lcode__goto_66_21: *const code = null

    var __local_dcode__goto_67_21: *const code = null

    var __local_lmask__goto_68_14: c_uint = 0

    var __local_dmask__goto_69_14: c_uint = 0

    var __local_here__goto_70_17: *const code = null

    var __local_op__goto_71_14: c_uint = 0

    var __local_len__goto_73_14: c_uint = 0

    var __local_dist__goto_74_14: c_uint = 0

    var __local_from__goto_75_24: *mut u8 = null

    var __ci_expr_old_0: *mut u8 = null

    var __ci_expr_old_1: *mut u8 = null

    var __ci_expr_old_2: *mut u8 = null

    var __ci_expr_old_3: *mut u8 = null

    var __ci_expr_old_4: *mut u8 = null

    var __ci_expr_old_5: *mut u8 = null

    var __ci_expr_old_6: *mut u8 = null

    var __ci_expr_old_7: *mut u8 = null

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_old_9: *mut u8 = null

    var __ci_expr_old_10: *mut u8 = null

    var __ci_expr_old_11: *mut u8 = null

    var __ci_expr_old_12: *mut u8 = null

    var __ci_expr_old_13: *mut u8 = null

    var __ci_expr_old_14: *mut u8 = null

    var __ci_expr_old_15: *mut u8 = null

    var __ci_expr_old_16: *mut u8 = null

    var __ci_expr_old_17: *mut u8 = null

    var __ci_expr_old_18: *mut u8 = null

    var __ci_expr_old_19: *mut u8 = null

    var __ci_expr_old_20: *mut u8 = null

    var __ci_expr_old_21: *mut u8 = null

    var __ci_expr_old_22: *mut u8 = null

    var __ci_expr_old_23: *mut u8 = null

    var __ci_expr_old_24: *mut u8 = null

    var __ci_expr_old_25: *mut u8 = null

    var __ci_expr_old_26: *mut u8 = null

    var __ci_expr_old_27: *mut u8 = null

    var __ci_expr_old_28: *mut u8 = null

    var __ci_expr_old_29: *mut u8 = null

    var __ci_expr_old_30: *mut u8 = null

    var __ci_expr_old_31: *mut u8 = null

    var __ci_expr_old_32: *mut u8 = null

    var __ci_expr_old_33: *mut u8 = null

    var __ci_expr_old_34: *mut u8 = null

    var __ci_expr_old_35: *mut u8 = null

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_ternary_37: c_long = 0

    var __ci_expr_ternary_38: c_long = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_state__goto_51_31 = (((unsafe *__param_strm).state as *mut inflate_state)))
        (__local_in___goto_52_32 = (unsafe *__param_strm).next_in)
        (__local_last__goto_53_32 = __local_in___goto_52_32 + ((((unsafe *__param_strm).avail_in as c_uint) -% (5 as c_uint)) as usize))
        (__local_out__goto_54_24 = (unsafe *__param_strm).next_out)
        (__local_beg__goto_55_24 = __local_out__goto_54_24 - (((__param_start as c_uint) -% ((unsafe *__param_strm).avail_out as c_uint)) as usize))
        (__local_end__goto_56_24 = __local_out__goto_54_24 + ((((unsafe *__param_strm).avail_out as c_uint) -% (257 as c_uint)) as usize))
        (__local_wsize__goto_60_14 = (unsafe *__local_state__goto_51_31).wsize)
        (__local_whave__goto_61_14 = (unsafe *__local_state__goto_51_31).whave)
        (__local_wnext__goto_62_14 = (unsafe *__local_state__goto_51_31).wnext)
        (__local_window__goto_63_24 = (unsafe *__local_state__goto_51_31).window)
        (__local_hold__goto_64_19 = (unsafe *__local_state__goto_51_31).hold)
        (__local_bits__goto_65_14 = (unsafe *__local_state__goto_51_31).bits)
        (__local_lcode__goto_66_21 = (unsafe *__local_state__goto_51_31).lencode)
        (__local_dcode__goto_67_21 = (unsafe *__local_state__goto_51_31).distcode)
        (__local_lmask__goto_68_14 = ((((((1 as c_uint) << ((unsafe *__local_state__goto_51_31).lenbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)))
        (__local_dmask__goto_69_14 = ((((((1 as c_uint) << ((unsafe *__local_state__goto_51_31).distbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((if __local_bits__goto_65_14 < 15: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_2 {
        (__ci_expr_logic_36 = 0)
        if ((if __local_in___goto_52_32 < __local_last__goto_53_32: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if (if __local_out__goto_54_24 < __local_end__goto_56_24: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        (__local_len__goto_73_14 = ((((__local_bits__goto_65_14 as c_uint) >> (3 as c_uint)) as c_uint)))
        (__local_in___goto_52_32 = __local_in___goto_52_32 - (__local_len__goto_73_14 as usize))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 -% ((__local_len__goto_73_14 as c_uint) << (3 as c_uint))))
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 as c_ulong) & (((((1 as c_uint) << (__local_bits__goto_65_14 as c_uint)) as c_uint) -% (1 as c_uint)) as c_ulong))
        ((unsafe *__param_strm).next_in = __local_in___goto_52_32)
        ((unsafe *__param_strm).next_out = __local_out__goto_54_24)
        (__ci_expr_ternary_37 = 0)
        if ((if __local_in___goto_52_32 < __local_last__goto_53_32: 1 else: 0) != 0) {
            (__ci_expr_ternary_37 = (((5 + (((__local_last__goto_53_32 as usize) -% (__local_in___goto_52_32 as usize)) / sizeof[u8]())) as c_long)))
        } else {
            (__ci_expr_ternary_37 = (((5 - (((__local_in___goto_52_32 as usize) -% (__local_last__goto_53_32 as usize)) / sizeof[u8]())) as c_long)))
        }
        ((unsafe *__param_strm).avail_in = ((__ci_expr_ternary_37 as c_uint)))
        (__ci_expr_ternary_38 = 0)
        if ((if __local_out__goto_54_24 < __local_end__goto_56_24: 1 else: 0) != 0) {
            (__ci_expr_ternary_38 = (((257 + (((__local_end__goto_56_24 as usize) -% (__local_out__goto_54_24 as usize)) / sizeof[u8]())) as c_long)))
        } else {
            (__ci_expr_ternary_38 = (((257 - (((__local_out__goto_54_24 as usize) -% (__local_end__goto_56_24 as usize)) / sizeof[u8]())) as c_long)))
        }
        ((unsafe *__param_strm).avail_out = ((__ci_expr_ternary_38 as c_uint)))
        ((unsafe *__local_state__goto_51_31).hold = __local_hold__goto_64_19)
        ((unsafe *__local_state__goto_51_31).bits = __local_bits__goto_65_14)
        return
    }

    '__ci_bb_4 {
        (__ci_expr_old_0 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_0) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        (__ci_expr_old_1 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_1) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        goto '__ci_bb_5
    }

    '__ci_bb_5 {
        (__local_here__goto_70_17 = __local_lcode__goto_66_21 + (((__local_hold__goto_64_19 as c_ulong) & (__local_lmask__goto_68_14 as c_ulong)) as usize))
        goto '__ci_bb_6
    }

    '__ci_bb_6 {
        (__local_op__goto_71_14 = (((unsafe *__local_here__goto_70_17).bits as c_uint)))
        (__local_hold__goto_64_19 = __local_hold__goto_64_19 >> (__local_op__goto_71_14 as c_uint))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 -% __local_op__goto_71_14))
        (__local_op__goto_71_14 = (((unsafe *__local_here__goto_70_17).op as c_uint)))
        if ((if __local_op__goto_71_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_7 {
        (__ci_expr_old_2 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        ((unsafe *__ci_expr_old_2) = (((unsafe *__local_here__goto_70_17).val as u8)))
        goto '__ci_bb_9
    }

    '__ci_bb_8 {
        if (((__local_op__goto_71_14 as c_uint) & (16 as c_uint)) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_9 {
        goto '__ci_bb_2
    }

    '__ci_bb_10 {
        (__local_len__goto_73_14 = (((unsafe *__local_here__goto_70_17).val as c_uint)))
        (__local_op__goto_71_14 = (__local_op__goto_71_14 as c_uint) & (15 as c_uint))
        if (__local_op__goto_71_14 != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_11 {
        if ((if ((__local_op__goto_71_14 as c_uint) & (64 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_78
        }
    }

    '__ci_bb_12 {
        goto '__ci_bb_9
    }

    '__ci_bb_13 {
        if ((if __local_bits__goto_65_14 < __local_op__goto_71_14: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_14 {
        if ((if __local_bits__goto_65_14 < 15: 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_15 {
        (__ci_expr_old_3 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_3) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        goto '__ci_bb_16
    }

    '__ci_bb_16 {
        (__local_len__goto_73_14 = (__local_len__goto_73_14 +% (((__local_hold__goto_64_19 as c_uint) as c_uint) & (((((1 as c_uint) << (__local_op__goto_71_14 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))))
        (__local_hold__goto_64_19 = __local_hold__goto_64_19 >> (__local_op__goto_71_14 as c_uint))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 -% __local_op__goto_71_14))
        goto '__ci_bb_14
    }

    '__ci_bb_17 {
        (__ci_expr_old_4 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_4) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        (__ci_expr_old_5 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_5) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        goto '__ci_bb_18
    }

    '__ci_bb_18 {
        (__local_here__goto_70_17 = __local_dcode__goto_67_21 + (((__local_hold__goto_64_19 as c_ulong) & (__local_dmask__goto_69_14 as c_ulong)) as usize))
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        (__local_op__goto_71_14 = (((unsafe *__local_here__goto_70_17).bits as c_uint)))
        (__local_hold__goto_64_19 = __local_hold__goto_64_19 >> (__local_op__goto_71_14 as c_uint))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 -% __local_op__goto_71_14))
        (__local_op__goto_71_14 = (((unsafe *__local_here__goto_70_17).op as c_uint)))
        if (((__local_op__goto_71_14 as c_uint) & (16 as c_uint)) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        (__local_dist__goto_74_14 = (((unsafe *__local_here__goto_70_17).val as c_uint)))
        (__local_op__goto_71_14 = (__local_op__goto_71_14 as c_uint) & (15 as c_uint))
        if ((if __local_bits__goto_65_14 < __local_op__goto_71_14: 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_21 {
        if ((if ((__local_op__goto_71_14 as c_uint) & (64 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_22 {
        goto '__ci_bb_12
    }

    '__ci_bb_23 {
        (__ci_expr_old_6 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_6) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        if ((if __local_bits__goto_65_14 < __local_op__goto_71_14: 1 else: 0) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_24 {
        (__local_dist__goto_74_14 = (__local_dist__goto_74_14 +% (((__local_hold__goto_64_19 as c_uint) as c_uint) & (((((1 as c_uint) << (__local_op__goto_71_14 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))))
        (__local_hold__goto_64_19 = __local_hold__goto_64_19 >> (__local_op__goto_71_14 as c_uint))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 -% __local_op__goto_71_14))
        (__local_op__goto_71_14 = (((((__local_out__goto_54_24 as usize) -% (__local_beg__goto_55_24 as usize)) / sizeof[u8]()) as c_uint)))
        if ((if __local_dist__goto_74_14 > __local_op__goto_71_14: 1 else: 0) != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_25 {
        (__ci_expr_old_7 = __local_in___goto_52_32)
        (__local_in___goto_52_32 = __local_in___goto_52_32 + 1)
        (__local_hold__goto_64_19 = (__local_hold__goto_64_19 +% ((((unsafe *__ci_expr_old_7) as c_ulong) as c_ulong) << (__local_bits__goto_65_14 as c_uint))))
        (__local_bits__goto_65_14 = (__local_bits__goto_65_14 +% 8))
        goto '__ci_bb_26
    }

    '__ci_bb_26 {
        goto '__ci_bb_24
    }

    '__ci_bb_27 {
        (__local_op__goto_71_14 = ((((__local_dist__goto_74_14 as c_uint) -% (__local_op__goto_71_14 as c_uint)) as c_uint)))
        if ((if __local_op__goto_71_14 > __local_whave__goto_61_14: 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_28 {
        (__local_from__goto_75_24 = __local_out__goto_54_24 - (__local_dist__goto_74_14 as usize))
        goto '__ci_bb_67
    }

    '__ci_bb_29 {
        goto '__ci_bb_22
    }

    '__ci_bb_30 {
        if ((unsafe *__local_state__goto_51_31).sane != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_31 {
        (__local_from__goto_75_24 = __local_window__goto_63_24)
        if ((if __local_wnext__goto_62_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_32 {
        ((unsafe *__param_strm).msg = (("invalid distance too far back" as *mut c_char)))
        ((unsafe *__local_state__goto_51_31).mode = ((16209 as i32)))
        goto '__ci_bb_3
    }

    '__ci_bb_33 {
        goto '__ci_bb_31
    }

    '__ci_bb_34 {
        (__local_from__goto_75_24 = __local_from__goto_75_24 + (((__local_wsize__goto_60_14 as c_uint) -% (__local_op__goto_71_14 as c_uint)) as usize))
        if ((if __local_op__goto_71_14 < __local_len__goto_73_14: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_35 {
        if ((if __local_wnext__goto_62_14 < __local_op__goto_71_14: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_36 {
        goto '__ci_bb_60
    }

    '__ci_bb_37 {
        (__local_len__goto_73_14 = (__local_len__goto_73_14 -% __local_op__goto_71_14))
        goto '__ci_bb_39
    }

    '__ci_bb_38 {
        goto '__ci_bb_36
    }

    '__ci_bb_39 {
        (__ci_expr_old_8 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_9 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_8) = (unsafe *__ci_expr_old_9))
        goto '__ci_bb_40
    }

    '__ci_bb_40 {
        (__local_op__goto_71_14 = (__local_op__goto_71_14 -% 1))
        if (__local_op__goto_71_14 != 0) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_41 {
        (__local_from__goto_75_24 = __local_out__goto_54_24 - (__local_dist__goto_74_14 as usize))
        goto '__ci_bb_38
    }

    '__ci_bb_42 {
        (__local_from__goto_75_24 = __local_from__goto_75_24 + (((((__local_wsize__goto_60_14 as c_uint) +% (__local_wnext__goto_62_14 as c_uint)) as c_uint) -% (__local_op__goto_71_14 as c_uint)) as usize))
        (__local_op__goto_71_14 = (__local_op__goto_71_14 -% __local_wnext__goto_62_14))
        if ((if __local_op__goto_71_14 < __local_len__goto_73_14: 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_43 {
        (__local_from__goto_75_24 = __local_from__goto_75_24 + (((__local_wnext__goto_62_14 as c_uint) -% (__local_op__goto_71_14 as c_uint)) as usize))
        if ((if __local_op__goto_71_14 < __local_len__goto_73_14: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_44 {
        goto '__ci_bb_36
    }

    '__ci_bb_45 {
        (__local_len__goto_73_14 = (__local_len__goto_73_14 -% __local_op__goto_71_14))
        goto '__ci_bb_47
    }

    '__ci_bb_46 {
        goto '__ci_bb_44
    }

    '__ci_bb_47 {
        (__ci_expr_old_10 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_11 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_10) = (unsafe *__ci_expr_old_11))
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        (__local_op__goto_71_14 = (__local_op__goto_71_14 -% 1))
        if (__local_op__goto_71_14 != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_49 {
        (__local_from__goto_75_24 = __local_window__goto_63_24)
        if ((if __local_wnext__goto_62_14 < __local_len__goto_73_14: 1 else: 0) != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_50 {
        (__local_op__goto_71_14 = __local_wnext__goto_62_14)
        (__local_len__goto_73_14 = (__local_len__goto_73_14 -% __local_op__goto_71_14))
        goto '__ci_bb_52
    }

    '__ci_bb_51 {
        goto '__ci_bb_46
    }

    '__ci_bb_52 {
        (__ci_expr_old_12 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_13 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_12) = (unsafe *__ci_expr_old_13))
        goto '__ci_bb_53
    }

    '__ci_bb_53 {
        (__local_op__goto_71_14 = (__local_op__goto_71_14 -% 1))
        if (__local_op__goto_71_14 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        (__local_from__goto_75_24 = __local_out__goto_54_24 - (__local_dist__goto_74_14 as usize))
        goto '__ci_bb_51
    }

    '__ci_bb_55 {
        (__local_len__goto_73_14 = (__local_len__goto_73_14 -% __local_op__goto_71_14))
        goto '__ci_bb_57
    }

    '__ci_bb_56 {
        goto '__ci_bb_44
    }

    '__ci_bb_57 {
        (__ci_expr_old_14 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_15 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_14) = (unsafe *__ci_expr_old_15))
        goto '__ci_bb_58
    }

    '__ci_bb_58 {
        (__local_op__goto_71_14 = (__local_op__goto_71_14 -% 1))
        if (__local_op__goto_71_14 != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_59 {
        (__local_from__goto_75_24 = __local_out__goto_54_24 - (__local_dist__goto_74_14 as usize))
        goto '__ci_bb_56
    }

    '__ci_bb_60 {
        if ((if __local_len__goto_73_14 > 2: 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_61 {
        (__ci_expr_old_16 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_17 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_16) = (unsafe *__ci_expr_old_17))
        (__ci_expr_old_18 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_19 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_18) = (unsafe *__ci_expr_old_19))
        (__ci_expr_old_20 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_21 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_20) = (unsafe *__ci_expr_old_21))
        (__local_len__goto_73_14 = (__local_len__goto_73_14 -% 3))
        goto '__ci_bb_60
    }

    '__ci_bb_62 {
        if (__local_len__goto_73_14 != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_63 {
        (__ci_expr_old_22 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_23 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_22) = (unsafe *__ci_expr_old_23))
        if ((if __local_len__goto_73_14 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_64 {
        goto '__ci_bb_29
    }

    '__ci_bb_65 {
        (__ci_expr_old_24 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_25 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_24) = (unsafe *__ci_expr_old_25))
        goto '__ci_bb_66
    }

    '__ci_bb_66 {
        goto '__ci_bb_64
    }

    '__ci_bb_67 {
        (__ci_expr_old_26 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_27 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_26) = (unsafe *__ci_expr_old_27))
        (__ci_expr_old_28 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_29 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_28) = (unsafe *__ci_expr_old_29))
        (__ci_expr_old_30 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_31 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_30) = (unsafe *__ci_expr_old_31))
        (__local_len__goto_73_14 = (__local_len__goto_73_14 -% 3))
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        if ((if __local_len__goto_73_14 > 2: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_69 {
        if (__local_len__goto_73_14 != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_70 {
        (__ci_expr_old_32 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_33 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_32) = (unsafe *__ci_expr_old_33))
        if ((if __local_len__goto_73_14 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_71 {
        goto '__ci_bb_29
    }

    '__ci_bb_72 {
        (__ci_expr_old_34 = __local_out__goto_54_24)
        (__local_out__goto_54_24 = __local_out__goto_54_24 + 1)
        (__ci_expr_old_35 = __local_from__goto_75_24)
        (__local_from__goto_75_24 = __local_from__goto_75_24 + 1)
        ((unsafe *__ci_expr_old_34) = (unsafe *__ci_expr_old_35))
        goto '__ci_bb_73
    }

    '__ci_bb_73 {
        goto '__ci_bb_71
    }

    '__ci_bb_74 {
        (__local_here__goto_70_17 = (__local_dcode__goto_67_21 + (((unsafe *__local_here__goto_70_17).val as c_uint) as usize)) + (((__local_hold__goto_64_19 as c_ulong) & (((((1 as c_uint) << (__local_op__goto_71_14 as c_uint)) as c_uint) -% (1 as c_uint)) as c_ulong)) as usize))
        goto '__ci_bb_19
    }

    '__ci_bb_75 {
        ((unsafe *__param_strm).msg = (("invalid distance code" as *mut c_char)))
        ((unsafe *__local_state__goto_51_31).mode = ((16209 as i32)))
        goto '__ci_bb_3
    }

    '__ci_bb_77 {
        (__local_here__goto_70_17 = (__local_lcode__goto_66_21 + (((unsafe *__local_here__goto_70_17).val as c_uint) as usize)) + (((__local_hold__goto_64_19 as c_ulong) & (((((1 as c_uint) << (__local_op__goto_71_14 as c_uint)) as c_uint) -% (1 as c_uint)) as c_ulong)) as usize))
        goto '__ci_bb_6
    }

    '__ci_bb_78 {
        if (((__local_op__goto_71_14 as c_uint) & (32 as c_uint)) != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_80 {
        ((unsafe *__local_state__goto_51_31).mode = ((16191 as i32)))
        goto '__ci_bb_3
    }

    '__ci_bb_81 {
        ((unsafe *__param_strm).msg = (("invalid literal/length code" as *mut c_char)))
        ((unsafe *__local_state__goto_51_31).mode = ((16209 as i32)))
        goto '__ci_bb_3
    }

}
