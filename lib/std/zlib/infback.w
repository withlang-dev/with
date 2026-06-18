// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
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

pub unsafe fn inflateBack(__param_strm: *mut z_stream_s, __param_in_: unsafe extern "C" fn(*mut c_void, *mut *mut u8) -> c_uint, __param_in_desc: *mut c_void, __param_out: unsafe extern "C" fn(*mut c_void, *mut u8, c_uint) -> c_int, __param_out_desc: *mut c_void) -> c_int {
    var __local_state__goto_193_31: *mut inflate_state = null

    var __local_next__goto_194_32: *mut u8 = null

    var __local_put__goto_195_24: *mut u8 = null

    var __local_have__goto_196_14: c_uint = 0

    var __local_left__goto_196_20: c_uint = 0

    var __local_hold__goto_197_19: c_ulong = 0

    var __local_bits__goto_198_14: c_uint = 0

    var __local_copy___goto_199_14: c_uint = 0

    var __local_from__goto_200_24: *mut u8 = null

    var __local_here__goto_201_10: code

    var __local_last__goto_202_10: code

    var __local_len__goto_203_14: c_uint = 0

    var __local_ret__goto_204_9: c_int = 0

    var __local_order__goto_205_33: [19]c_ushort

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_ternary_1: c_uint = 0

    var __ci_expr_old_2: *mut u8 = null

    var __ci_expr_old_3: *mut u8 = null

    var __ci_expr_old_4: *mut u8 = null

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_old_6: *mut u8 = null

    var __ci_expr_old_7: c_uint = 0

    var __ci_expr_old_8: c_uint = 0

    var __ci_expr_old_9: *mut u8 = null

    var __ci_expr_old_10: c_uint = 0

    var __ci_expr_old_11: *mut u8 = null

    var __ci_expr_old_12: *mut u8 = null

    var __ci_expr_old_13: *mut u8 = null

    var __ci_expr_old_14: c_uint = 0

    var __ci_expr_old_15: c_uint = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_old_17: *mut u8 = null

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_old_19: *mut u8 = null

    var __ci_expr_old_20: *mut u8 = null

    var __ci_expr_old_21: *mut u8 = null

    var __ci_expr_old_22: *mut u8 = null

    var __ci_expr_old_23: *mut u8 = null

    var __ci_expr_old_24: *mut u8 = null

    var __ci_expr_ternary_25: c_uint = 0

    var __ci_expr_old_26: *mut u8 = null

    var __ci_expr_old_27: *mut u8 = null

    var __ci_expr_logic_28: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_order__goto_205_33 = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15])
        if ((if __param_strm == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe *__param_strm).state == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        return -2
    }

    '__ci_bb_2 {
        (__local_state__goto_193_31 = (((unsafe *__param_strm).state as *mut inflate_state)))
        ((unsafe *__param_strm).msg = null)
        ((unsafe *__local_state__goto_193_31).mode = ((16191 as i32)))
        ((unsafe *__local_state__goto_193_31).last = ((0 as c_int)))
        ((unsafe *__local_state__goto_193_31).whave = ((0 as c_uint)))
        (__local_next__goto_194_32 = (unsafe *__param_strm).next_in)
        (__ci_expr_ternary_1 = 0)
        if ((if __local_next__goto_194_32 != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = (unsafe *__param_strm).avail_in)
        } else {
            (__ci_expr_ternary_1 = ((0 as c_uint)))
        }
        (__local_have__goto_196_14 = __ci_expr_ternary_1)
        (__local_hold__goto_197_19 = ((0 as c_ulong)))
        (__local_bits__goto_198_14 = ((0 as c_uint)))
        (__local_put__goto_195_24 = (unsafe *__local_state__goto_193_31).window)
        (__local_left__goto_196_20 = (unsafe *__local_state__goto_193_31).wsize)
        goto '__ci_bb_3
    }

    '__ci_bb_3 {
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        goto '__ci_bb_7
    }

    '__ci_bb_5 {
        goto '__ci_bb_3
    }

    '__ci_bb_7 {
        if ((unsafe *__local_state__goto_193_31).mode == 16191) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_430
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_5
    }

    '__ci_bb_9 {
        if ((unsafe *__local_state__goto_193_31).last != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_10 {
        goto '__ci_bb_12
    }

    '__ci_bb_11 {
        goto '__ci_bb_15
    }

    '__ci_bb_12 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (((__local_bits__goto_198_14 as c_uint) & (7 as c_uint)) as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((__local_bits__goto_198_14 as c_uint) & (7 as c_uint))))
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        if (0 != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_14 {
        ((unsafe *__local_state__goto_193_31).mode = ((16208 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_15 {
        goto '__ci_bb_18
    }

    '__ci_bb_16 {
        if (0 != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_17 {
        ((unsafe *__local_state__goto_193_31).last = (((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (1 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_int)))
        goto '__ci_bb_32
    }

    '__ci_bb_18 {
        if ((if __local_bits__goto_198_14 < ((3 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_19 {
        goto '__ci_bb_21
    }

    '__ci_bb_20 {
        goto '__ci_bb_16
    }

    '__ci_bb_21 {
        goto '__ci_bb_24
    }

    '__ci_bb_22 {
        if (0 != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_23 {
        goto '__ci_bb_18
    }

    '__ci_bb_24 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_25 {
        if (0 != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_26 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_2 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_2) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_22
    }

    '__ci_bb_27 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_25
    }

    '__ci_bb_29 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_30 {
        goto '__ci_bb_28
    }

    '__ci_bb_31 {
        if ((if __local_left__goto_196_20 < (unsafe *__local_state__goto_193_31).wsize: 1 else: 0) != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_436
        }
    }

    '__ci_bb_32 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (1 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (1 as c_uint)))
        goto '__ci_bb_33
    }

    '__ci_bb_33 {
        if (0 != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_34 {
        goto '__ci_bb_35
    }

    '__ci_bb_35 {
        if ((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) == 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_36 {
        goto '__ci_bb_43
    }

    '__ci_bb_37 {
        ((unsafe *__local_state__goto_193_31).mode = ((16193 as i32)))
        goto '__ci_bb_36
    }

    '__ci_bb_38 {
        inflate_fixed(__local_state__goto_193_31)
        ((unsafe *__local_state__goto_193_31).mode = ((16200 as i32)))
        goto '__ci_bb_36
    }

    '__ci_bb_39 {
        ((unsafe *__local_state__goto_193_31).mode = ((16196 as i32)))
        goto '__ci_bb_36
    }

    '__ci_bb_40 {
        ((unsafe *__param_strm).msg = (("invalid block type" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_36
    }

    '__ci_bb_41 {
        if ((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) == 1) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_42 {
        if ((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) == 2) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_40
        }
    }

    '__ci_bb_43 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (2 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (2 as c_uint)))
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        if (0 != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_45 {
        goto '__ci_bb_8
    }

    '__ci_bb_46 {
        goto '__ci_bb_47
    }

    '__ci_bb_47 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (((__local_bits__goto_198_14 as c_uint) & (7 as c_uint)) as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((__local_bits__goto_198_14 as c_uint) & (7 as c_uint))))
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        if (0 != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_49 {
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        goto '__ci_bb_53
    }

    '__ci_bb_51 {
        if (0 != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_52 {
        if ((if ((__local_hold__goto_197_19 as c_ulong) & (65535 as c_ulong)) != ((((__local_hold__goto_197_19 as c_ulong) >> (16 as c_uint)) as c_ulong) ^ (65535 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_53 {
        if ((if __local_bits__goto_198_14 < ((32 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_54 {
        goto '__ci_bb_56
    }

    '__ci_bb_55 {
        goto '__ci_bb_51
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
        goto '__ci_bb_53
    }

    '__ci_bb_59 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_60 {
        if (0 != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_61 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_3 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_3) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_57
    }

    '__ci_bb_62 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_65
        }
    }

    '__ci_bb_63 {
        goto '__ci_bb_60
    }

    '__ci_bb_64 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_65 {
        goto '__ci_bb_63
    }

    '__ci_bb_66 {
        ((unsafe *__param_strm).msg = (("invalid stored block lengths" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_67 {
        ((unsafe *__local_state__goto_193_31).length = (((((__local_hold__goto_197_19 as c_uint) as c_uint) & (65535 as c_uint)) as c_uint)))
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        (__local_hold__goto_197_19 = ((0 as c_ulong)))
        (__local_bits__goto_198_14 = ((0 as c_uint)))
        goto '__ci_bb_69
    }

    '__ci_bb_69 {
        if (0 != 0) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_70 {
        goto '__ci_bb_71
    }

    '__ci_bb_71 {
        if ((if (unsafe *__local_state__goto_193_31).length != 0: 1 else: 0) != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_72 {
        (__local_copy___goto_199_14 = (unsafe *__local_state__goto_193_31).length)
        goto '__ci_bb_74
    }

    '__ci_bb_73 {
        ((unsafe *__local_state__goto_193_31).mode = ((16191 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_74 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_78
        }
    }

    '__ci_bb_75 {
        if (0 != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_76 {
        goto '__ci_bb_81
    }

    '__ci_bb_77 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_79
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_78 {
        goto '__ci_bb_75
    }

    '__ci_bb_79 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_80 {
        goto '__ci_bb_78
    }

    '__ci_bb_81 {
        if ((if __local_left__goto_196_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_82 {
        if (0 != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_83
        }
    }

    '__ci_bb_83 {
        if ((if __local_copy___goto_199_14 > __local_have__goto_196_14: 1 else: 0) != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_84 {
        (__local_put__goto_195_24 = (unsafe *__local_state__goto_193_31).window)
        (__local_left__goto_196_20 = (unsafe *__local_state__goto_193_31).wsize)
        ((unsafe *__local_state__goto_193_31).whave = __local_left__goto_196_20)
        if (__param_out(__param_out_desc, __local_put__goto_195_24, __local_left__goto_196_20) != 0) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_87
        }
    }

    '__ci_bb_85 {
        goto '__ci_bb_82
    }

    '__ci_bb_86 {
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_87 {
        goto '__ci_bb_85
    }

    '__ci_bb_88 {
        (__local_copy___goto_199_14 = __local_have__goto_196_14)
        goto '__ci_bb_89
    }

    '__ci_bb_89 {
        if ((if __local_copy___goto_199_14 > __local_left__goto_196_20: 1 else: 0) != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_91
        }
    }

    '__ci_bb_90 {
        (__local_copy___goto_199_14 = __local_left__goto_196_20)
        goto '__ci_bb_91
    }

    '__ci_bb_91 {
        with_memcpy(((__local_put__goto_195_24 as *mut c_void) as *i8), ((__local_next__goto_194_32 as *const c_void) as *i8), ((__local_copy___goto_199_14 as c_ulong) as i64))
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% __local_copy___goto_199_14))
        (__local_next__goto_194_32 = __local_next__goto_194_32 + (__local_copy___goto_199_14 as usize))
        (__local_left__goto_196_20 = (__local_left__goto_196_20 -% __local_copy___goto_199_14))
        (__local_put__goto_195_24 = __local_put__goto_195_24 + (__local_copy___goto_199_14 as usize))
        ((unsafe *__local_state__goto_193_31).length = ((unsafe *__local_state__goto_193_31).length -% __local_copy___goto_199_14))
        goto '__ci_bb_71
    }

    '__ci_bb_92 {
        goto '__ci_bb_93
    }

    '__ci_bb_93 {
        goto '__ci_bb_96
    }

    '__ci_bb_94 {
        if (0 != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_95 {
        ((unsafe *__local_state__goto_193_31).nlen = (((((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (5 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (257 as c_uint)) as c_uint)))
        goto '__ci_bb_109
    }

    '__ci_bb_96 {
        if ((if __local_bits__goto_198_14 < ((14 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_97 {
        goto '__ci_bb_99
    }

    '__ci_bb_98 {
        goto '__ci_bb_94
    }

    '__ci_bb_99 {
        goto '__ci_bb_102
    }

    '__ci_bb_100 {
        if (0 != 0) {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_101 {
        goto '__ci_bb_96
    }

    '__ci_bb_102 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_103 {
        if (0 != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_104 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_4 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_4) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_100
    }

    '__ci_bb_105 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_108
        }
    }

    '__ci_bb_106 {
        goto '__ci_bb_103
    }

    '__ci_bb_107 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_108 {
        goto '__ci_bb_106
    }

    '__ci_bb_109 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (5 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (5 as c_uint)))
        goto '__ci_bb_110
    }

    '__ci_bb_110 {
        if (0 != 0) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_111 {
        ((unsafe *__local_state__goto_193_31).ndist = (((((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (5 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (1 as c_uint)) as c_uint)))
        goto '__ci_bb_112
    }

    '__ci_bb_112 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (5 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (5 as c_uint)))
        goto '__ci_bb_113
    }

    '__ci_bb_113 {
        if (0 != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_114 {
        ((unsafe *__local_state__goto_193_31).ncode = (((((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (4 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) +% (4 as c_uint)) as c_uint)))
        goto '__ci_bb_115
    }

    '__ci_bb_115 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (4 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (4 as c_uint)))
        goto '__ci_bb_116
    }

    '__ci_bb_116 {
        if (0 != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_117 {
        if ((if (unsafe *__local_state__goto_193_31).nlen > 286: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_5 = (if (if (unsafe *__local_state__goto_193_31).ndist > 30: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_118 {
        ((unsafe *__param_strm).msg = (("too many length or distance symbols" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_119 {
        ((unsafe *__local_state__goto_193_31).have = ((0 as c_uint)))
        goto '__ci_bb_120
    }

    '__ci_bb_120 {
        if ((if (unsafe *__local_state__goto_193_31).have < (unsafe *__local_state__goto_193_31).ncode: 1 else: 0) != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_121 {
        goto '__ci_bb_123
    }

    '__ci_bb_122 {
        goto '__ci_bb_142
    }

    '__ci_bb_123 {
        goto '__ci_bb_126
    }

    '__ci_bb_124 {
        if (0 != 0) {
            goto '__ci_bb_123
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_125 {
        (__ci_expr_old_7 = (unsafe *__local_state__goto_193_31).have)
        ((unsafe *__local_state__goto_193_31).have = ((unsafe *__local_state__goto_193_31).have +% 1))
        ((unsafe *__local_state__goto_193_31).lens[__local_order__goto_205_33[__ci_expr_old_7]] = (((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (3 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_ushort)))
        goto '__ci_bb_139
    }

    '__ci_bb_126 {
        if ((if __local_bits__goto_198_14 < ((3 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_127 {
        goto '__ci_bb_129
    }

    '__ci_bb_128 {
        goto '__ci_bb_124
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
        goto '__ci_bb_126
    }

    '__ci_bb_132 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_133 {
        if (0 != 0) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_134 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_6 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_6) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_130
    }

    '__ci_bb_135 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_136 {
        goto '__ci_bb_133
    }

    '__ci_bb_137 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_138 {
        goto '__ci_bb_136
    }

    '__ci_bb_139 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (3 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (3 as c_uint)))
        goto '__ci_bb_140
    }

    '__ci_bb_140 {
        if (0 != 0) {
            goto '__ci_bb_139
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_141 {
        goto '__ci_bb_120
    }

    '__ci_bb_142 {
        if ((if (unsafe *__local_state__goto_193_31).have < 19: 1 else: 0) != 0) {
            goto '__ci_bb_143
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_143 {
        (__ci_expr_old_8 = (unsafe *__local_state__goto_193_31).have)
        ((unsafe *__local_state__goto_193_31).have = ((unsafe *__local_state__goto_193_31).have +% 1))
        ((unsafe *__local_state__goto_193_31).lens[__local_order__goto_205_33[__ci_expr_old_8]] = ((0 as c_ushort)))
        goto '__ci_bb_142
    }

    '__ci_bb_144 {
        ((unsafe *__local_state__goto_193_31).next = (&(unsafe *__local_state__goto_193_31).codes[0] as *mut code))
        ((unsafe *__local_state__goto_193_31).lencode = (((unsafe *__local_state__goto_193_31).next as *const code)))
        ((unsafe *__local_state__goto_193_31).lenbits = ((7 as c_uint)))
        (__local_ret__goto_204_9 = ((inflate_table((0 as i32), (&(unsafe *__local_state__goto_193_31).lens[0] as *mut c_ushort), (19 as c_uint), ((&raw const (unsafe *__local_state__goto_193_31).next as *const *mut code) as *mut *mut code), ((&raw const (unsafe *__local_state__goto_193_31).lenbits as *const c_uint) as *mut c_uint), (&(unsafe *__local_state__goto_193_31).work[0] as *mut c_ushort)) as c_int)))
        if (__local_ret__goto_204_9 != 0) {
            goto '__ci_bb_145
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_145 {
        ((unsafe *__param_strm).msg = (("invalid code lengths set" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_146 {
        ((unsafe *__local_state__goto_193_31).have = ((0 as c_uint)))
        goto '__ci_bb_147
    }

    '__ci_bb_147 {
        if ((if (unsafe *__local_state__goto_193_31).have < (((unsafe *__local_state__goto_193_31).nlen as c_uint) +% ((unsafe *__local_state__goto_193_31).ndist as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_148 {
        goto '__ci_bb_150
    }

    '__ci_bb_149 {
        if ((if (unsafe *__local_state__goto_193_31).mode == 16209: 1 else: 0) != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_150 {
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        with_memcpy((&raw mut __local_here__goto_201_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_193_31).lencode[(((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_193_31).lenbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)) <= __local_bits__goto_198_14: 1 else: 0) != 0) {
            goto '__ci_bb_154
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_152 {
        goto '__ci_bb_150
    }

    '__ci_bb_153 {
        if ((if (unsafe *(&raw const __local_here__goto_201_10 as *const code)).val < 16: 1 else: 0) != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_154 {
        goto '__ci_bb_153
    }

    '__ci_bb_155 {
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        goto '__ci_bb_159
    }

    '__ci_bb_157 {
        if (0 != 0) {
            goto '__ci_bb_156
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_158 {
        goto '__ci_bb_152
    }

    '__ci_bb_159 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_160 {
        if (0 != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_161 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_9 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_9) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_157
    }

    '__ci_bb_162 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_163 {
        goto '__ci_bb_160
    }

    '__ci_bb_164 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_165 {
        goto '__ci_bb_163
    }

    '__ci_bb_166 {
        goto '__ci_bb_169
    }

    '__ci_bb_167 {
        if ((if (unsafe *(&raw const __local_here__goto_201_10 as *const code)).val == 16: 1 else: 0) != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_168 {
        goto '__ci_bb_147
    }

    '__ci_bb_169 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_170
    }

    '__ci_bb_170 {
        if (0 != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_171 {
        (__ci_expr_old_10 = (unsafe *__local_state__goto_193_31).have)
        ((unsafe *__local_state__goto_193_31).have = ((unsafe *__local_state__goto_193_31).have +% 1))
        ((unsafe *__local_state__goto_193_31).lens[__ci_expr_old_10] = (unsafe *(&raw const __local_here__goto_201_10 as *const code)).val)
        goto '__ci_bb_168
    }

    '__ci_bb_172 {
        goto '__ci_bb_175
    }

    '__ci_bb_173 {
        if ((if (unsafe *(&raw const __local_here__goto_201_10 as *const code)).val == 17: 1 else: 0) != 0) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_200
        }
    }

    '__ci_bb_174 {
        if ((if (((unsafe *__local_state__goto_193_31).have as c_uint) +% (__local_copy___goto_199_14 as c_uint)) > (((unsafe *__local_state__goto_193_31).nlen as c_uint) +% ((unsafe *__local_state__goto_193_31).ndist as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_175 {
        goto '__ci_bb_178
    }

    '__ci_bb_176 {
        if (0 != 0) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_177 {
        goto '__ci_bb_191
    }

    '__ci_bb_178 {
        if ((if __local_bits__goto_198_14 < (((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_int) + 2) as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_179
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_179 {
        goto '__ci_bb_181
    }

    '__ci_bb_180 {
        goto '__ci_bb_176
    }

    '__ci_bb_181 {
        goto '__ci_bb_184
    }

    '__ci_bb_182 {
        if (0 != 0) {
            goto '__ci_bb_181
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_183 {
        goto '__ci_bb_178
    }

    '__ci_bb_184 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_185 {
        if (0 != 0) {
            goto '__ci_bb_184
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_186 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_11 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_11) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_182
    }

    '__ci_bb_187 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_188 {
        goto '__ci_bb_185
    }

    '__ci_bb_189 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_190 {
        goto '__ci_bb_188
    }

    '__ci_bb_191 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        if (0 != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_193
        }
    }

    '__ci_bb_193 {
        if ((if (unsafe *__local_state__goto_193_31).have == 0: 1 else: 0) != 0) {
            goto '__ci_bb_194
        } else {
            goto '__ci_bb_195
        }
    }

    '__ci_bb_194 {
        ((unsafe *__param_strm).msg = (("invalid bit length repeat" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_149
    }

    '__ci_bb_195 {
        (__local_len__goto_203_14 = (((unsafe *__local_state__goto_193_31).lens[(((unsafe *__local_state__goto_193_31).have as c_uint) -% (1 as c_uint))] as c_uint)))
        (__local_copy___goto_199_14 = ((((3 as c_uint) +% ((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (2 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        goto '__ci_bb_196
    }

    '__ci_bb_196 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (2 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (2 as c_uint)))
        goto '__ci_bb_197
    }

    '__ci_bb_197 {
        if (0 != 0) {
            goto '__ci_bb_196
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_198 {
        goto '__ci_bb_174
    }

    '__ci_bb_199 {
        goto '__ci_bb_202
    }

    '__ci_bb_200 {
        goto '__ci_bb_224
    }

    '__ci_bb_201 {
        goto '__ci_bb_174
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
        goto '__ci_bb_218
    }

    '__ci_bb_205 {
        if ((if __local_bits__goto_198_14 < (((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_int) + 3) as c_uint)): 1 else: 0) != 0) {
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
        goto '__ci_bb_211
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
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_214
        } else {
            goto '__ci_bb_215
        }
    }

    '__ci_bb_212 {
        if (0 != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_213
        }
    }

    '__ci_bb_213 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_12 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_12) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_209
    }

    '__ci_bb_214 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_216
        } else {
            goto '__ci_bb_217
        }
    }

    '__ci_bb_215 {
        goto '__ci_bb_212
    }

    '__ci_bb_216 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_217 {
        goto '__ci_bb_215
    }

    '__ci_bb_218 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_219
    }

    '__ci_bb_219 {
        if (0 != 0) {
            goto '__ci_bb_218
        } else {
            goto '__ci_bb_220
        }
    }

    '__ci_bb_220 {
        (__local_len__goto_203_14 = ((0 as c_uint)))
        (__local_copy___goto_199_14 = ((((3 as c_uint) +% ((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (3 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        goto '__ci_bb_221
    }

    '__ci_bb_221 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (3 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (3 as c_uint)))
        goto '__ci_bb_222
    }

    '__ci_bb_222 {
        if (0 != 0) {
            goto '__ci_bb_221
        } else {
            goto '__ci_bb_223
        }
    }

    '__ci_bb_223 {
        goto '__ci_bb_201
    }

    '__ci_bb_224 {
        goto '__ci_bb_227
    }

    '__ci_bb_225 {
        if (0 != 0) {
            goto '__ci_bb_224
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_226 {
        goto '__ci_bb_240
    }

    '__ci_bb_227 {
        if ((if __local_bits__goto_198_14 < (((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_int) + 7) as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_228
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_228 {
        goto '__ci_bb_230
    }

    '__ci_bb_229 {
        goto '__ci_bb_225
    }

    '__ci_bb_230 {
        goto '__ci_bb_233
    }

    '__ci_bb_231 {
        if (0 != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_232 {
        goto '__ci_bb_227
    }

    '__ci_bb_233 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_236
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_234 {
        if (0 != 0) {
            goto '__ci_bb_233
        } else {
            goto '__ci_bb_235
        }
    }

    '__ci_bb_235 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_13 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_13) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_231
    }

    '__ci_bb_236 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_238
        } else {
            goto '__ci_bb_239
        }
    }

    '__ci_bb_237 {
        goto '__ci_bb_234
    }

    '__ci_bb_238 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_239 {
        goto '__ci_bb_237
    }

    '__ci_bb_240 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_241
    }

    '__ci_bb_241 {
        if (0 != 0) {
            goto '__ci_bb_240
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_242 {
        (__local_len__goto_203_14 = ((0 as c_uint)))
        (__local_copy___goto_199_14 = ((((11 as c_uint) +% ((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << (7 as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)) as c_uint)))
        goto '__ci_bb_243
    }

    '__ci_bb_243 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> (7 as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (7 as c_uint)))
        goto '__ci_bb_244
    }

    '__ci_bb_244 {
        if (0 != 0) {
            goto '__ci_bb_243
        } else {
            goto '__ci_bb_245
        }
    }

    '__ci_bb_245 {
        goto '__ci_bb_201
    }

    '__ci_bb_246 {
        ((unsafe *__param_strm).msg = (("invalid bit length repeat" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_149
    }

    '__ci_bb_247 {
        goto '__ci_bb_248
    }

    '__ci_bb_248 {
        (__ci_expr_old_14 = __local_copy___goto_199_14)
        (__local_copy___goto_199_14 = (__local_copy___goto_199_14 -% 1))
        if (__ci_expr_old_14 != 0) {
            goto '__ci_bb_249
        } else {
            goto '__ci_bb_250
        }
    }

    '__ci_bb_249 {
        (__ci_expr_old_15 = (unsafe *__local_state__goto_193_31).have)
        ((unsafe *__local_state__goto_193_31).have = ((unsafe *__local_state__goto_193_31).have +% 1))
        ((unsafe *__local_state__goto_193_31).lens[__ci_expr_old_15] = ((__local_len__goto_203_14 as c_ushort)))
        goto '__ci_bb_248
    }

    '__ci_bb_250 {
        goto '__ci_bb_168
    }

    '__ci_bb_251 {
        goto '__ci_bb_8
    }

    '__ci_bb_252 {
        if ((if (unsafe *__local_state__goto_193_31).lens[256] == 0: 1 else: 0) != 0) {
            goto '__ci_bb_253
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_253 {
        ((unsafe *__param_strm).msg = (("invalid code -- missing end-of-block" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_254 {
        ((unsafe *__local_state__goto_193_31).next = (&(unsafe *__local_state__goto_193_31).codes[0] as *mut code))
        ((unsafe *__local_state__goto_193_31).lencode = (((unsafe *__local_state__goto_193_31).next as *const code)))
        ((unsafe *__local_state__goto_193_31).lenbits = ((9 as c_uint)))
        (__local_ret__goto_204_9 = ((inflate_table((1 as i32), (&(unsafe *__local_state__goto_193_31).lens[0] as *mut c_ushort), (unsafe *__local_state__goto_193_31).nlen, ((&raw const (unsafe *__local_state__goto_193_31).next as *const *mut code) as *mut *mut code), ((&raw const (unsafe *__local_state__goto_193_31).lenbits as *const c_uint) as *mut c_uint), (&(unsafe *__local_state__goto_193_31).work[0] as *mut c_ushort)) as c_int)))
        if (__local_ret__goto_204_9 != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_255 {
        ((unsafe *__param_strm).msg = (("invalid literal/lengths set" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_256 {
        ((unsafe *__local_state__goto_193_31).distcode = (((unsafe *__local_state__goto_193_31).next as *const code)))
        ((unsafe *__local_state__goto_193_31).distbits = ((6 as c_uint)))
        (__local_ret__goto_204_9 = ((inflate_table((2 as i32), ((&(unsafe *__local_state__goto_193_31).lens[0] as *mut c_ushort) + ((unsafe *__local_state__goto_193_31).nlen as usize)), (unsafe *__local_state__goto_193_31).ndist, ((&raw const (unsafe *__local_state__goto_193_31).next as *const *mut code) as *mut *mut code), ((&raw const (unsafe *__local_state__goto_193_31).distbits as *const c_uint) as *mut c_uint), (&(unsafe *__local_state__goto_193_31).work[0] as *mut c_ushort)) as c_int)))
        if (__local_ret__goto_204_9 != 0) {
            goto '__ci_bb_257
        } else {
            goto '__ci_bb_258
        }
    }

    '__ci_bb_257 {
        ((unsafe *__param_strm).msg = (("invalid distances set" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_258 {
        ((unsafe *__local_state__goto_193_31).mode = ((16200 as i32)))
        goto '__ci_bb_259
    }

    '__ci_bb_259 {
        (__ci_expr_logic_16 = 0)
        if ((if __local_have__goto_196_14 >= 6: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if __local_left__goto_196_20 >= 258: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_260
        } else {
            goto '__ci_bb_261
        }
    }

    '__ci_bb_260 {
        goto '__ci_bb_262
    }

    '__ci_bb_261 {
        goto '__ci_bb_270
    }

    '__ci_bb_262 {
        ((unsafe *__param_strm).next_out = __local_put__goto_195_24)
        ((unsafe *__param_strm).avail_out = __local_left__goto_196_20)
        ((unsafe *__param_strm).next_in = __local_next__goto_194_32)
        ((unsafe *__param_strm).avail_in = __local_have__goto_196_14)
        ((unsafe *__local_state__goto_193_31).hold = __local_hold__goto_197_19)
        ((unsafe *__local_state__goto_193_31).bits = __local_bits__goto_198_14)
        goto '__ci_bb_263
    }

    '__ci_bb_263 {
        if (0 != 0) {
            goto '__ci_bb_262
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_264 {
        if ((if (unsafe *__local_state__goto_193_31).whave < (unsafe *__local_state__goto_193_31).wsize: 1 else: 0) != 0) {
            goto '__ci_bb_265
        } else {
            goto '__ci_bb_266
        }
    }

    '__ci_bb_265 {
        ((unsafe *__local_state__goto_193_31).whave = (((((unsafe *__local_state__goto_193_31).wsize as c_uint) -% (__local_left__goto_196_20 as c_uint)) as c_uint)))
        goto '__ci_bb_266
    }

    '__ci_bb_266 {
        inflate_fast(__param_strm, (unsafe *__local_state__goto_193_31).wsize)
        goto '__ci_bb_267
    }

    '__ci_bb_267 {
        (__local_put__goto_195_24 = (unsafe *__param_strm).next_out)
        (__local_left__goto_196_20 = (unsafe *__param_strm).avail_out)
        (__local_next__goto_194_32 = (unsafe *__param_strm).next_in)
        (__local_have__goto_196_14 = (unsafe *__param_strm).avail_in)
        (__local_hold__goto_197_19 = (unsafe *__local_state__goto_193_31).hold)
        (__local_bits__goto_198_14 = (unsafe *__local_state__goto_193_31).bits)
        goto '__ci_bb_268
    }

    '__ci_bb_268 {
        if (0 != 0) {
            goto '__ci_bb_267
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_269 {
        goto '__ci_bb_8
    }

    '__ci_bb_270 {
        goto '__ci_bb_271
    }

    '__ci_bb_271 {
        with_memcpy((&raw mut __local_here__goto_201_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_193_31).lencode[(((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_193_31).lenbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)) <= __local_bits__goto_198_14: 1 else: 0) != 0) {
            goto '__ci_bb_274
        } else {
            goto '__ci_bb_275
        }
    }

    '__ci_bb_272 {
        goto '__ci_bb_270
    }

    '__ci_bb_273 {
        (__ci_expr_logic_18 = 0)
        if ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op != 0) {
            (__ci_expr_logic_18 = (if (if ((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_int) as c_int) & (240 as c_int)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_286
        } else {
            goto '__ci_bb_287
        }
    }

    '__ci_bb_274 {
        goto '__ci_bb_273
    }

    '__ci_bb_275 {
        goto '__ci_bb_276
    }

    '__ci_bb_276 {
        goto '__ci_bb_279
    }

    '__ci_bb_277 {
        if (0 != 0) {
            goto '__ci_bb_276
        } else {
            goto '__ci_bb_278
        }
    }

    '__ci_bb_278 {
        goto '__ci_bb_272
    }

    '__ci_bb_279 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_283
        }
    }

    '__ci_bb_280 {
        if (0 != 0) {
            goto '__ci_bb_279
        } else {
            goto '__ci_bb_281
        }
    }

    '__ci_bb_281 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_17 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_17) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_277
    }

    '__ci_bb_282 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_284
        } else {
            goto '__ci_bb_285
        }
    }

    '__ci_bb_283 {
        goto '__ci_bb_280
    }

    '__ci_bb_284 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_285 {
        goto '__ci_bb_283
    }

    '__ci_bb_286 {
        with_memcpy((&raw mut __local_last__goto_202_10 as *i8), (&raw const __local_here__goto_201_10 as *i8), sizeof[code]())
        goto '__ci_bb_288
    }

    '__ci_bb_287 {
        goto '__ci_bb_307
    }

    '__ci_bb_288 {
        goto '__ci_bb_289
    }

    '__ci_bb_289 {
        with_memcpy((&raw mut __local_here__goto_201_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_193_31).lencode[((((unsafe *(&raw const __local_last__goto_202_10 as *const code)).val as c_int) as c_uint) +% ((((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).op as c_int)) as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) >> ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_int)) as c_uint)) <= __local_bits__goto_198_14: 1 else: 0) != 0) {
            goto '__ci_bb_292
        } else {
            goto '__ci_bb_293
        }
    }

    '__ci_bb_290 {
        goto '__ci_bb_288
    }

    '__ci_bb_291 {
        goto '__ci_bb_304
    }

    '__ci_bb_292 {
        goto '__ci_bb_291
    }

    '__ci_bb_293 {
        goto '__ci_bb_294
    }

    '__ci_bb_294 {
        goto '__ci_bb_297
    }

    '__ci_bb_295 {
        if (0 != 0) {
            goto '__ci_bb_294
        } else {
            goto '__ci_bb_296
        }
    }

    '__ci_bb_296 {
        goto '__ci_bb_290
    }

    '__ci_bb_297 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_298 {
        if (0 != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_299
        }
    }

    '__ci_bb_299 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_19 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_19) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_295
    }

    '__ci_bb_300 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_302
        } else {
            goto '__ci_bb_303
        }
    }

    '__ci_bb_301 {
        goto '__ci_bb_298
    }

    '__ci_bb_302 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_303 {
        goto '__ci_bb_301
    }

    '__ci_bb_304 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_305
    }

    '__ci_bb_305 {
        if (0 != 0) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_306
        }
    }

    '__ci_bb_306 {
        goto '__ci_bb_287
    }

    '__ci_bb_307 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_308
    }

    '__ci_bb_308 {
        if (0 != 0) {
            goto '__ci_bb_307
        } else {
            goto '__ci_bb_309
        }
    }

    '__ci_bb_309 {
        ((unsafe *__local_state__goto_193_31).length = (((unsafe *(&raw const __local_here__goto_201_10 as *const code)).val as c_uint)))
        if ((if (unsafe *(&raw const __local_here__goto_201_10 as *const code)).op == 0: 1 else: 0) != 0) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_311
        }
    }

    '__ci_bb_310 {
        goto '__ci_bb_312
    }

    '__ci_bb_311 {
        if (((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_int) as c_int) & (32 as c_int)) != 0) {
            goto '__ci_bb_319
        } else {
            goto '__ci_bb_320
        }
    }

    '__ci_bb_312 {
        if ((if __local_left__goto_196_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_315
        } else {
            goto '__ci_bb_316
        }
    }

    '__ci_bb_313 {
        if (0 != 0) {
            goto '__ci_bb_312
        } else {
            goto '__ci_bb_314
        }
    }

    '__ci_bb_314 {
        (__ci_expr_old_20 = __local_put__goto_195_24)
        (__local_put__goto_195_24 = __local_put__goto_195_24 + 1)
        ((unsafe *__ci_expr_old_20) = (((unsafe *__local_state__goto_193_31).length as u8)))
        (__local_left__goto_196_20 = (__local_left__goto_196_20 -% 1))
        ((unsafe *__local_state__goto_193_31).mode = ((16200 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_315 {
        (__local_put__goto_195_24 = (unsafe *__local_state__goto_193_31).window)
        (__local_left__goto_196_20 = (unsafe *__local_state__goto_193_31).wsize)
        ((unsafe *__local_state__goto_193_31).whave = __local_left__goto_196_20)
        if (__param_out(__param_out_desc, __local_put__goto_195_24, __local_left__goto_196_20) != 0) {
            goto '__ci_bb_317
        } else {
            goto '__ci_bb_318
        }
    }

    '__ci_bb_316 {
        goto '__ci_bb_313
    }

    '__ci_bb_317 {
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_318 {
        goto '__ci_bb_316
    }

    '__ci_bb_319 {
        ((unsafe *__local_state__goto_193_31).mode = ((16191 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_320 {
        if (((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_int) as c_int) & (64 as c_int)) != 0) {
            goto '__ci_bb_321
        } else {
            goto '__ci_bb_322
        }
    }

    '__ci_bb_321 {
        ((unsafe *__param_strm).msg = (("invalid literal/length code" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_322 {
        ((unsafe *__local_state__goto_193_31).extra = ((((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_uint) as c_uint) & (15 as c_uint)) as c_uint)))
        if ((if (unsafe *__local_state__goto_193_31).extra != 0: 1 else: 0) != 0) {
            goto '__ci_bb_323
        } else {
            goto '__ci_bb_324
        }
    }

    '__ci_bb_323 {
        goto '__ci_bb_325
    }

    '__ci_bb_324 {
        goto '__ci_bb_344
    }

    '__ci_bb_325 {
        goto '__ci_bb_328
    }

    '__ci_bb_326 {
        if (0 != 0) {
            goto '__ci_bb_325
        } else {
            goto '__ci_bb_327
        }
    }

    '__ci_bb_327 {
        ((unsafe *__local_state__goto_193_31).length = ((unsafe *__local_state__goto_193_31).length +% (((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_193_31).extra as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))))
        goto '__ci_bb_341
    }

    '__ci_bb_328 {
        if ((if __local_bits__goto_198_14 < (unsafe *__local_state__goto_193_31).extra: 1 else: 0) != 0) {
            goto '__ci_bb_329
        } else {
            goto '__ci_bb_330
        }
    }

    '__ci_bb_329 {
        goto '__ci_bb_331
    }

    '__ci_bb_330 {
        goto '__ci_bb_326
    }

    '__ci_bb_331 {
        goto '__ci_bb_334
    }

    '__ci_bb_332 {
        if (0 != 0) {
            goto '__ci_bb_331
        } else {
            goto '__ci_bb_333
        }
    }

    '__ci_bb_333 {
        goto '__ci_bb_328
    }

    '__ci_bb_334 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_337
        } else {
            goto '__ci_bb_338
        }
    }

    '__ci_bb_335 {
        if (0 != 0) {
            goto '__ci_bb_334
        } else {
            goto '__ci_bb_336
        }
    }

    '__ci_bb_336 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_21 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_21) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_332
    }

    '__ci_bb_337 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_339
        } else {
            goto '__ci_bb_340
        }
    }

    '__ci_bb_338 {
        goto '__ci_bb_335
    }

    '__ci_bb_339 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_340 {
        goto '__ci_bb_338
    }

    '__ci_bb_341 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *__local_state__goto_193_31).extra as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (unsafe *__local_state__goto_193_31).extra))
        goto '__ci_bb_342
    }

    '__ci_bb_342 {
        if (0 != 0) {
            goto '__ci_bb_341
        } else {
            goto '__ci_bb_343
        }
    }

    '__ci_bb_343 {
        goto '__ci_bb_324
    }

    '__ci_bb_344 {
        goto '__ci_bb_345
    }

    '__ci_bb_345 {
        with_memcpy((&raw mut __local_here__goto_201_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_193_31).distcode[(((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_193_31).distbits as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)) <= __local_bits__goto_198_14: 1 else: 0) != 0) {
            goto '__ci_bb_348
        } else {
            goto '__ci_bb_349
        }
    }

    '__ci_bb_346 {
        goto '__ci_bb_344
    }

    '__ci_bb_347 {
        if ((if ((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_int) as c_int) & (240 as c_int)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_360
        } else {
            goto '__ci_bb_361
        }
    }

    '__ci_bb_348 {
        goto '__ci_bb_347
    }

    '__ci_bb_349 {
        goto '__ci_bb_350
    }

    '__ci_bb_350 {
        goto '__ci_bb_353
    }

    '__ci_bb_351 {
        if (0 != 0) {
            goto '__ci_bb_350
        } else {
            goto '__ci_bb_352
        }
    }

    '__ci_bb_352 {
        goto '__ci_bb_346
    }

    '__ci_bb_353 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_356
        } else {
            goto '__ci_bb_357
        }
    }

    '__ci_bb_354 {
        if (0 != 0) {
            goto '__ci_bb_353
        } else {
            goto '__ci_bb_355
        }
    }

    '__ci_bb_355 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_22 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_22) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_351
    }

    '__ci_bb_356 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_358
        } else {
            goto '__ci_bb_359
        }
    }

    '__ci_bb_357 {
        goto '__ci_bb_354
    }

    '__ci_bb_358 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_359 {
        goto '__ci_bb_357
    }

    '__ci_bb_360 {
        with_memcpy((&raw mut __local_last__goto_202_10 as *i8), (&raw const __local_here__goto_201_10 as *i8), sizeof[code]())
        goto '__ci_bb_362
    }

    '__ci_bb_361 {
        goto '__ci_bb_381
    }

    '__ci_bb_362 {
        goto '__ci_bb_363
    }

    '__ci_bb_363 {
        with_memcpy((&raw mut __local_here__goto_201_10 as *i8), (&raw const (unsafe (unsafe *__local_state__goto_193_31).distcode[((((unsafe *(&raw const __local_last__goto_202_10 as *const code)).val as c_int) as c_uint) +% ((((((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).op as c_int)) as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint) >> ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_uint)) as c_uint))]) as *i8), sizeof[code]())
        if ((if (((((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_int) + ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_int)) as c_uint)) <= __local_bits__goto_198_14: 1 else: 0) != 0) {
            goto '__ci_bb_366
        } else {
            goto '__ci_bb_367
        }
    }

    '__ci_bb_364 {
        goto '__ci_bb_362
    }

    '__ci_bb_365 {
        goto '__ci_bb_378
    }

    '__ci_bb_366 {
        goto '__ci_bb_365
    }

    '__ci_bb_367 {
        goto '__ci_bb_368
    }

    '__ci_bb_368 {
        goto '__ci_bb_371
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
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_374
        } else {
            goto '__ci_bb_375
        }
    }

    '__ci_bb_372 {
        if (0 != 0) {
            goto '__ci_bb_371
        } else {
            goto '__ci_bb_373
        }
    }

    '__ci_bb_373 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_23 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_23) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_369
    }

    '__ci_bb_374 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_376
        } else {
            goto '__ci_bb_377
        }
    }

    '__ci_bb_375 {
        goto '__ci_bb_372
    }

    '__ci_bb_376 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_377 {
        goto '__ci_bb_375
    }

    '__ci_bb_378 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_last__goto_202_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_379
    }

    '__ci_bb_379 {
        if (0 != 0) {
            goto '__ci_bb_378
        } else {
            goto '__ci_bb_380
        }
    }

    '__ci_bb_380 {
        goto '__ci_bb_361
    }

    '__ci_bb_381 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% ((unsafe *(&raw const __local_here__goto_201_10 as *const code)).bits as c_uint)))
        goto '__ci_bb_382
    }

    '__ci_bb_382 {
        if (0 != 0) {
            goto '__ci_bb_381
        } else {
            goto '__ci_bb_383
        }
    }

    '__ci_bb_383 {
        if (((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_int) as c_int) & (64 as c_int)) != 0) {
            goto '__ci_bb_384
        } else {
            goto '__ci_bb_385
        }
    }

    '__ci_bb_384 {
        ((unsafe *__param_strm).msg = (("invalid distance code" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_385 {
        ((unsafe *__local_state__goto_193_31).offset = (((unsafe *(&raw const __local_here__goto_201_10 as *const code)).val as c_uint)))
        ((unsafe *__local_state__goto_193_31).extra = ((((((unsafe *(&raw const __local_here__goto_201_10 as *const code)).op as c_uint) as c_uint) & (15 as c_uint)) as c_uint)))
        if ((if (unsafe *__local_state__goto_193_31).extra != 0: 1 else: 0) != 0) {
            goto '__ci_bb_386
        } else {
            goto '__ci_bb_387
        }
    }

    '__ci_bb_386 {
        goto '__ci_bb_388
    }

    '__ci_bb_387 {
        (__ci_expr_ternary_25 = 0)
        if ((if (unsafe *__local_state__goto_193_31).whave < (unsafe *__local_state__goto_193_31).wsize: 1 else: 0) != 0) {
            (__ci_expr_ternary_25 = __local_left__goto_196_20)
        } else {
            (__ci_expr_ternary_25 = ((0 as c_uint)))
        }
        if ((if (unsafe *__local_state__goto_193_31).offset > (((unsafe *__local_state__goto_193_31).wsize as c_uint) -% (__ci_expr_ternary_25 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_407
        } else {
            goto '__ci_bb_408
        }
    }

    '__ci_bb_388 {
        goto '__ci_bb_391
    }

    '__ci_bb_389 {
        if (0 != 0) {
            goto '__ci_bb_388
        } else {
            goto '__ci_bb_390
        }
    }

    '__ci_bb_390 {
        ((unsafe *__local_state__goto_193_31).offset = ((unsafe *__local_state__goto_193_31).offset +% (((__local_hold__goto_197_19 as c_uint) as c_uint) & (((((1 as c_uint) << ((unsafe *__local_state__goto_193_31).extra as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint))))
        goto '__ci_bb_404
    }

    '__ci_bb_391 {
        if ((if __local_bits__goto_198_14 < (unsafe *__local_state__goto_193_31).extra: 1 else: 0) != 0) {
            goto '__ci_bb_392
        } else {
            goto '__ci_bb_393
        }
    }

    '__ci_bb_392 {
        goto '__ci_bb_394
    }

    '__ci_bb_393 {
        goto '__ci_bb_389
    }

    '__ci_bb_394 {
        goto '__ci_bb_397
    }

    '__ci_bb_395 {
        if (0 != 0) {
            goto '__ci_bb_394
        } else {
            goto '__ci_bb_396
        }
    }

    '__ci_bb_396 {
        goto '__ci_bb_391
    }

    '__ci_bb_397 {
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_400
        } else {
            goto '__ci_bb_401
        }
    }

    '__ci_bb_398 {
        if (0 != 0) {
            goto '__ci_bb_397
        } else {
            goto '__ci_bb_399
        }
    }

    '__ci_bb_399 {
        (__local_have__goto_196_14 = (__local_have__goto_196_14 -% 1))
        (__ci_expr_old_24 = __local_next__goto_194_32)
        (__local_next__goto_194_32 = __local_next__goto_194_32 + 1)
        (__local_hold__goto_197_19 = (__local_hold__goto_197_19 +% ((((unsafe *__ci_expr_old_24) as c_ulong) as c_ulong) << (__local_bits__goto_198_14 as c_uint))))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 +% 8))
        goto '__ci_bb_395
    }

    '__ci_bb_400 {
        (__local_have__goto_196_14 = ((__param_in_(__param_in_desc, (&raw mut __local_next__goto_194_32 as *mut *mut u8)) as c_uint)))
        if ((if __local_have__goto_196_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_402
        } else {
            goto '__ci_bb_403
        }
    }

    '__ci_bb_401 {
        goto '__ci_bb_398
    }

    '__ci_bb_402 {
        (__local_next__goto_194_32 = null)
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_403 {
        goto '__ci_bb_401
    }

    '__ci_bb_404 {
        (__local_hold__goto_197_19 = __local_hold__goto_197_19 >> ((unsafe *__local_state__goto_193_31).extra as c_uint))
        (__local_bits__goto_198_14 = (__local_bits__goto_198_14 -% (unsafe *__local_state__goto_193_31).extra))
        goto '__ci_bb_405
    }

    '__ci_bb_405 {
        if (0 != 0) {
            goto '__ci_bb_404
        } else {
            goto '__ci_bb_406
        }
    }

    '__ci_bb_406 {
        goto '__ci_bb_387
    }

    '__ci_bb_407 {
        ((unsafe *__param_strm).msg = (("invalid distance too far back" as *mut c_char)))
        ((unsafe *__local_state__goto_193_31).mode = ((16209 as i32)))
        goto '__ci_bb_8
    }

    '__ci_bb_408 {
        goto '__ci_bb_409
    }

    '__ci_bb_409 {
        goto '__ci_bb_412
    }

    '__ci_bb_410 {
        if ((if (unsafe *__local_state__goto_193_31).length != 0: 1 else: 0) != 0) {
            goto '__ci_bb_409
        } else {
            goto '__ci_bb_411
        }
    }

    '__ci_bb_411 {
        goto '__ci_bb_8
    }

    '__ci_bb_412 {
        if ((if __local_left__goto_196_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_415
        } else {
            goto '__ci_bb_416
        }
    }

    '__ci_bb_413 {
        if (0 != 0) {
            goto '__ci_bb_412
        } else {
            goto '__ci_bb_414
        }
    }

    '__ci_bb_414 {
        (__local_copy___goto_199_14 = (((((unsafe *__local_state__goto_193_31).wsize as c_uint) -% ((unsafe *__local_state__goto_193_31).offset as c_uint)) as c_uint)))
        if ((if __local_copy___goto_199_14 < __local_left__goto_196_20: 1 else: 0) != 0) {
            goto '__ci_bb_419
        } else {
            goto '__ci_bb_420
        }
    }

    '__ci_bb_415 {
        (__local_put__goto_195_24 = (unsafe *__local_state__goto_193_31).window)
        (__local_left__goto_196_20 = (unsafe *__local_state__goto_193_31).wsize)
        ((unsafe *__local_state__goto_193_31).whave = __local_left__goto_196_20)
        if (__param_out(__param_out_desc, __local_put__goto_195_24, __local_left__goto_196_20) != 0) {
            goto '__ci_bb_417
        } else {
            goto '__ci_bb_418
        }
    }

    '__ci_bb_416 {
        goto '__ci_bb_413
    }

    '__ci_bb_417 {
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_418 {
        goto '__ci_bb_416
    }

    '__ci_bb_419 {
        (__local_from__goto_200_24 = __local_put__goto_195_24 + (__local_copy___goto_199_14 as usize))
        (__local_copy___goto_199_14 = ((((__local_left__goto_196_20 as c_uint) -% (__local_copy___goto_199_14 as c_uint)) as c_uint)))
        goto '__ci_bb_421
    }

    '__ci_bb_420 {
        (__local_from__goto_200_24 = __local_put__goto_195_24 - ((unsafe *__local_state__goto_193_31).offset as usize))
        (__local_copy___goto_199_14 = __local_left__goto_196_20)
        goto '__ci_bb_421
    }

    '__ci_bb_421 {
        if ((if __local_copy___goto_199_14 > (unsafe *__local_state__goto_193_31).length: 1 else: 0) != 0) {
            goto '__ci_bb_422
        } else {
            goto '__ci_bb_423
        }
    }

    '__ci_bb_422 {
        (__local_copy___goto_199_14 = (unsafe *__local_state__goto_193_31).length)
        goto '__ci_bb_423
    }

    '__ci_bb_423 {
        ((unsafe *__local_state__goto_193_31).length = ((unsafe *__local_state__goto_193_31).length -% __local_copy___goto_199_14))
        (__local_left__goto_196_20 = (__local_left__goto_196_20 -% __local_copy___goto_199_14))
        goto '__ci_bb_424
    }

    '__ci_bb_424 {
        (__ci_expr_old_26 = __local_put__goto_195_24)
        (__local_put__goto_195_24 = __local_put__goto_195_24 + 1)
        (__ci_expr_old_27 = __local_from__goto_200_24)
        (__local_from__goto_200_24 = __local_from__goto_200_24 + 1)
        ((unsafe *__ci_expr_old_26) = (unsafe *__ci_expr_old_27))
        goto '__ci_bb_425
    }

    '__ci_bb_425 {
        (__local_copy___goto_199_14 = (__local_copy___goto_199_14 -% 1))
        if (__local_copy___goto_199_14 != 0) {
            goto '__ci_bb_424
        } else {
            goto '__ci_bb_426
        }
    }

    '__ci_bb_426 {
        goto '__ci_bb_410
    }

    '__ci_bb_427 {
        (__local_ret__goto_204_9 = ((1 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_428 {
        (__local_ret__goto_204_9 = ((-3 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_429 {
        (__local_ret__goto_204_9 = ((-2 as c_int)))
        goto '__ci_bb_31
    }

    '__ci_bb_430 {
        if ((unsafe *__local_state__goto_193_31).mode == 16193) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_431 {
        if ((unsafe *__local_state__goto_193_31).mode == 16196) {
            goto '__ci_bb_92
        } else {
            goto '__ci_bb_432
        }
    }

    '__ci_bb_432 {
        if ((unsafe *__local_state__goto_193_31).mode == 16200) {
            goto '__ci_bb_259
        } else {
            goto '__ci_bb_433
        }
    }

    '__ci_bb_433 {
        if ((unsafe *__local_state__goto_193_31).mode == 16208) {
            goto '__ci_bb_427
        } else {
            goto '__ci_bb_434
        }
    }

    '__ci_bb_434 {
        if ((unsafe *__local_state__goto_193_31).mode == 16209) {
            goto '__ci_bb_428
        } else {
            goto '__ci_bb_429
        }
    }

    '__ci_bb_435 {
        (__ci_expr_logic_28 = 0)
        if (__param_out(__param_out_desc, (unsafe *__local_state__goto_193_31).window, (((unsafe *__local_state__goto_193_31).wsize as c_uint) -% (__local_left__goto_196_20 as c_uint))) != 0) {
            (__ci_expr_logic_28 = (if (if __local_ret__goto_204_9 == 1: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_28 != 0) {
            goto '__ci_bb_437
        } else {
            goto '__ci_bb_438
        }
    }

    '__ci_bb_436 {
        ((unsafe *__param_strm).next_in = __local_next__goto_194_32)
        ((unsafe *__param_strm).avail_in = __local_have__goto_196_14)
        return __local_ret__goto_204_9
    }

    '__ci_bb_437 {
        (__local_ret__goto_204_9 = ((-5 as c_int)))
        goto '__ci_bb_438
    }

    '__ci_bb_438 {
        goto '__ci_bb_436
    }

}

pub unsafe fn inflateBackEnd(__param_strm: *mut z_stream_s) -> c_int {
    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __param_strm == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_strm).state == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__param_strm).zfree == ((0 as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return -2
    }


    (unsafe *__param_strm).zfree((unsafe *__param_strm).opaque_, ((unsafe *__param_strm).state as *mut c_void))

    ((unsafe *__param_strm).state = null)

    return 0

}

pub unsafe fn inflateBackInit_(__param_strm: *mut z_stream_s, __param_windowBits: c_int, __param_window: *mut u8, __param_version: *const i8, __param_stream_size: c_int) -> c_int {
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


    var __ci_expr_logic_4: c_int

    var __ci_expr_logic_3: c_int

    var __ci_expr_logic_2: c_int

    if ((if __param_strm == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if __param_window == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if (if __param_windowBits < 8: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if __param_windowBits > 15: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
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

    ((unsafe *__param_strm).state = ((__local_state as *mut internal_state)))

    ((unsafe *__local_state).dmax = ((32768 as c_uint)))

    ((unsafe *__local_state).wbits = ((__param_windowBits as c_uint)))

    ((unsafe *__local_state).wsize = ((((1 as c_uint) << (__param_windowBits as c_uint)) as c_uint)))

    ((unsafe *__local_state).window = __param_window)

    ((unsafe *__local_state).wnext = ((0 as c_uint)))

    ((unsafe *__local_state).whave = ((0 as c_uint)))

    ((unsafe *__local_state).sane = ((1 as c_int)))

    return 0

}
