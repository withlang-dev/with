// Migrated from C
use std.engines.stc.defs
use std.libc

pub unsafe fn _fmt_time(__param_fmt: *const c_char, __param_tm: *const tm, __param_buf: *mut c_char, __param_bufsize: c_int) -> *const c_char {
    strftime(__param_buf, (__param_bufsize as c_ulong), __param_fmt, __param_tm)

    return ((__param_buf as *const c_char))

}

pub unsafe fn fmt_close(__param_ss: *mut fmt_stream) {
    with_free((((*__param_ss).data as *mut c_void) as *mut u8))

}

pub unsafe fn _fmt_parse(__param_p: *mut c_char, __param_nargs: c_int, __param_fmt: *const c_char, ...) -> c_int {
    var __local_p = __param_p
    var __local_fmt = __param_fmt
    var __local_arg__goto_250_11: *mut c_char = null

    var __local_p0__goto_250_17: *mut c_char = null

    var __local_ch__goto_250_21: c_char = 0

    var __local_n__goto_251_9: c_int = 0

    var __local_empty__goto_251_16: c_int = 0

    var __local_args__goto_252_13: c_va_list = va_start()

    var __ci_expr_switch_0: c_int = 0

    var __ci_expr_old_1: *mut c_char = null

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_old_3: *mut c_char = null

    var __ci_expr_old_4: *mut c_char = null

    var __ci_expr_old_5: *mut c_char = null

    var __ci_expr_old_6: *const c_char = null

    var __ci_expr_old_7: *mut c_char = null

    var __ci_expr_old_8: *mut c_char = null

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_old_11: *mut c_char = null

    var __ci_expr_old_12: *mut c_char = null

    var __ci_expr_old_13: *const c_char = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_n__goto_251_9 = ((0 as c_int)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_ch__goto_250_21 = (*__local_fmt))
        (__ci_expr_switch_0 = __local_ch__goto_250_21)
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if (__local_ch__goto_250_21 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        return __local_n__goto_251_9
    }

    '__ci_bb_4 {
        if (__ci_expr_switch_0 == 37) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_5 {
        (__ci_expr_old_12 = __local_p)
        (__local_p = __local_p + 1)
        (__ci_expr_old_13 = __local_fmt)
        (__local_fmt = __local_fmt + 1)
        ((*__ci_expr_old_12) = (*__ci_expr_old_13))
        goto '__ci_bb_2
    }

    '__ci_bb_6 {
        (__ci_expr_old_1 = __local_p)
        (__local_p = __local_p + 1)
        ((*__ci_expr_old_1) = ((37 as c_char)))
        goto '__ci_bb_5
    }

    '__ci_bb_7 {
        (__local_fmt = __local_fmt + 1)
        if ((if (*__local_fmt) == 125: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_5
    }

    '__ci_bb_9 {
        (__local_n__goto_251_9 = ((99 as c_int)))
        goto '__ci_bb_2
    }

    '__ci_bb_10 {
        (__local_fmt = __local_fmt + 1)
        if ((if (*__local_fmt) == 123: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_11 {
        goto '__ci_bb_5
    }

    '__ci_bb_12 {
        (__local_n__goto_251_9 = __local_n__goto_251_9 + 1)
        if ((if __local_n__goto_251_9 > __param_nargs: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_13 {
        goto '__ci_bb_2
    }

    '__ci_bb_14 {
        (__ci_expr_logic_2 = 0)
        if ((if (*__local_fmt) != 58: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (*__local_fmt) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_15 {
        (__local_n__goto_251_9 = ((99 as c_int)))
        goto '__ci_bb_16
    }

    '__ci_bb_16 {
        (__local_fmt = __local_fmt + (((if (*__local_fmt) == 58: 1 else: 0) as isize) as usize))
        (__local_empty__goto_251_16 = (((if (*__local_fmt) == 125: 1 else: 0) as c_int)))
        (__local_arg__goto_250_11 = ((__local_args__goto_252_13.arg[*mut c_char]() as *mut c_char)))
        (__ci_expr_old_3 = __local_p)
        (__local_p = __local_p + 1)
        ((*__ci_expr_old_3) = ((37 as c_char)))
        (__local_p0__goto_250_17 = __local_p)
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if (1 != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        goto '__ci_bb_20
    }

    '__ci_bb_19 {
        goto '__ci_bb_24
    }

    '__ci_bb_20 {
        if ((*__local_fmt) == 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_21 {
        goto '__ci_bb_17
    }

    '__ci_bb_22 {
        (__local_n__goto_251_9 = ((99 as c_int)))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        goto '__ci_bb_24
    }

    '__ci_bb_24 {
        goto '__ci_bb_37
    }

    '__ci_bb_25 {
        (__ci_expr_old_4 = __local_p)
        (__local_p = __local_p + 1)
        ((*__ci_expr_old_4) = ((45 as c_char)))
        (__local_fmt = __local_fmt + 1)
        goto '__ci_bb_21
    }

    '__ci_bb_26 {
        (__local_p0__goto_250_17 = ((null as *mut c_char)))
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        (__local_fmt = __local_fmt + 1)
        goto '__ci_bb_21
    }

    '__ci_bb_28 {
        (__local_n__goto_251_9 = __local_n__goto_251_9 + 1)
        if ((if __local_n__goto_251_9 <= __param_nargs: 1 else: 0) != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_29 {
        (__local_arg__goto_250_11 = ((__local_args__goto_252_13.arg[*mut c_char]() as *mut c_char)))
        goto '__ci_bb_30
    }

    '__ci_bb_30 {
        goto '__ci_bb_31
    }

    '__ci_bb_31 {
        (__ci_expr_old_5 = __local_p)
        (__local_p = __local_p + 1)
        (__ci_expr_old_6 = __local_fmt)
        (__local_fmt = __local_fmt + 1)
        ((*__ci_expr_old_5) = (*__ci_expr_old_6))
        goto '__ci_bb_21
    }

    '__ci_bb_32 {
        if ((*__local_fmt) == 125) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_33 {
        if ((*__local_fmt) == 60) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_34 {
        if ((*__local_fmt) == 62) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_35 {
        if ((*__local_fmt) == 45) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_36 {
        if ((*__local_fmt) == 42) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_37 {
        if ((*__local_arg__goto_250_11) == 103) {
            goto '__ci_bb_39
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_38 {
        if ((if strchr(c"csdioxXufFeEaAgGnp".ptr, ((__local_fmt[-1]) as c_int)) == null: 1 else: 0) != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_39 {
        if (__local_empty__goto_251_16 != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_40 {
        with_memcpy(((__local_p as *mut c_void) as *mut u8), ((".8" as *const c_void) as *const u8), ((2 as c_ulong) as i64))
        (__local_p = __local_p + ((2 as isize) as usize))
        goto '__ci_bb_41
    }

    '__ci_bb_41 {
        goto '__ci_bb_38
    }

    '__ci_bb_42 {
        (__local_arg__goto_250_11 = __local_arg__goto_250_11 + 1)
        if (__local_empty__goto_251_16 != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        with_memcpy(((__local_p as *mut c_void) as *mut u8), ((".16" as *const c_void) as *const u8), ((3 as c_ulong) as i64))
        (__local_p = __local_p + ((3 as isize) as usize))
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        goto '__ci_bb_38
    }

    '__ci_bb_45 {
        if ((*__local_arg__goto_250_11) == 64) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_46 {
        goto '__ci_bb_48
    }

    '__ci_bb_47 {
        (__ci_expr_logic_10 = 0)
        if (__local_p0__goto_250_17 != null) {
            var __ci_expr_logic_9: c_int

            if ((if (__local_p[-1]) == 115: 1 else: 0) != 0) {
                (__ci_expr_logic_9 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_9 = (if (if (__local_p[-1]) == 99: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_48 {
        if ((*__local_arg__goto_250_11) != 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_49 {
        (__ci_expr_old_7 = __local_p)
        (__local_p = __local_p + 1)
        (__ci_expr_old_8 = __local_arg__goto_250_11)
        (__local_arg__goto_250_11 = __local_arg__goto_250_11 + 1)
        ((*__ci_expr_old_7) = (*__ci_expr_old_8))
        goto '__ci_bb_48
    }

    '__ci_bb_50 {
        goto '__ci_bb_47
    }

    '__ci_bb_51 {
        (__ci_expr_old_11 = __local_p)
        (__local_p = __local_p + 1)
        with_memmove((((__local_p0__goto_250_17 + ((1 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_p0__goto_250_17 as *const c_void) as *const u8), ((((((__ci_expr_old_11 as usize) -% (__local_p0__goto_250_17 as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_ulong) as i64))
        ((*__local_p0__goto_250_17) = ((45 as c_char)))
        goto '__ci_bb_52
    }

    '__ci_bb_52 {
        (__local_fmt = __local_fmt + (((if (*__local_fmt) == 125: 1 else: 0) as isize) as usize))
        goto '__ci_bb_2
    }

    '__ci_bb_53 {
        if (__ci_expr_switch_0 == 125) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        if (__ci_expr_switch_0 == 123) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_5
        }
    }

    __ci_unreachable()

}

pub unsafe fn _fmt_sprint(__param_ss: *mut fmt_stream, __param_fmt: *const c_char, ...) -> Unit {
    var __local_args__goto_229_13: c_va_list = va_start()

    var __local_args2__goto_229_19: c_va_list

    var __local_n__goto_236_15: c_int = 0

    var __local_pos__goto_238_21: c_long = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        if ((if __param_ss == null: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        vprintf(__param_fmt, __local_args__goto_229_13)
        putchar((10 as c_int))
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        (__local_args2__goto_229_19 = __local_args__goto_229_13)
        (__local_n__goto_236_15 = ((vsnprintf((null as *mut c_char), (0 as c_ulong), __param_fmt, __local_args__goto_229_13) as c_int)))
        if ((if __local_n__goto_236_15 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_3 {
        return
    }

    '__ci_bb_4 {
        goto '__ci_bb_6
    }

    '__ci_bb_5 {
        (__local_pos__goto_238_21 = (((if (*__param_ss).overwrite != 0: (0 as c_long) else: (*__param_ss).len) as c_long)))
        ((*__param_ss).len = (((__local_pos__goto_238_21 + __local_n__goto_236_15) as c_long)))
        if ((if (*__param_ss).len > (*__param_ss).cap: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        goto '__ci_bb_3
    }

    '__ci_bb_7 {
        ((*__param_ss).cap = ((((*__param_ss).len + ((*__param_ss).cap / 2)) as c_long)))
        ((*__param_ss).data = (((with_realloc((((*__param_ss).data as *mut c_void) as *mut u8), (0 as i64), (((((*__param_ss).cap as c_ulong) +% (1 as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut c_char)))
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        vsnprintf(((*__param_ss).data + ((__local_pos__goto_238_21 as isize) as usize)), (((__local_n__goto_236_15 as c_ulong) +% (1 as c_ulong)) as c_ulong), __param_fmt, __local_args2__goto_229_19)
        goto '__ci_bb_6
    }

    __ci_unreachable()

}
