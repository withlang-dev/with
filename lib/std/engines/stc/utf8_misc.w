// Migrated from C
use std.engines.stc.defs

unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: c_long) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as c_ulong) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: c_long) -> c_ulong {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: c_ulong = ((((0 as c_ulong) -% 3750763034362895579) as c_ulong))

    var __local_block: c_ulong = ((0 as c_ulong))


    while ((if __local_len >= ((sizeof[c_ulong]() as c_long)): 1 else: 0) != 0) {
        with_memcpy((((&raw mut __local_block as *mut c_ulong) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[c_ulong]() as c_ulong) as i64))

        (__local_h = (__local_h as c_ulong) ^ (__local_block as c_ulong))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[c_ulong]() as c_long) as usize))

        (__local_len = __local_len - (sizeof[c_ulong]() as c_long))

    }

    while true {
        var __ci_expr_old_0: c_long = __local_len

        (__local_len = __local_len - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as c_ulong) ^ ((*__ci_expr_old_1) as c_ulong))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_n(__param_key: *const c_void, __param_len: c_long) -> c_ulong {
    var __local_b8: c_ulonglong

    var __local_b4: c_uint

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut c_ulonglong) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as c_ulong) as i64))

            return ((((__local_b8 as c_ulonglong) *% (((0 as c_ulonglong) -% 4132994306676758115) as c_ulonglong)) as c_ulong))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut c_uint) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as c_ulong) as i64))

            return ((__local_b4 as c_ulong) *% (((0 as c_ulong) -% 3750763034362895579) as c_ulong))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

unsafe fn c_hash_str(__param_str: *const c_char) -> c_ulong {
    var __local_msg: *const u8 = ((__param_str as *const u8))

    var __local_h: c_ulong = ((((0 as c_ulong) -% 3750763034362895579) as c_ulong))

    while ((*__local_msg) != 0) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as c_ulong) ^ ((*__ci_expr_old_0) as c_ulong))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_mix_n(__param_h: *mut c_ulong, __param_n: c_long) -> c_ulong {
    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as c_ulong) ^ ((__param_h[__local_i]) as c_ulong))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: c_long) -> c_long {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (1 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (2 as c_uint)) as c_long))


    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (4 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (8 as c_uint)) as c_long))


    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (16 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (32 as c_uint)) as c_long))

    return (__local_n + 1)

}

unsafe fn c_strnstrn(__param_str: *const c_char, __param_slen: c_long, __param_needle: *const c_char, __param_nlen: c_long) -> *mut c_char {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return ((__local_str as *mut c_char))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: c_long = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut c_char))

}

pub unsafe fn cutf8_decode_codepoint(__param_d: *mut cutf8_decode_t, __param_s: *const c_char, __param_end: *const c_char) -> c_int {
    var __local_s = __param_s
    var __local_start__goto_29_17: *const c_char = null

    var __local_len__goto_38_9: c_int = 0

    var __ci_expr_old_0: *const c_char = null

    var __ci_expr_switch_1: c_uint = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_start__goto_29_17 = __local_s)
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__ci_expr_old_0 = __local_s)
        (__local_s = __local_s + 1)
        (__ci_expr_switch_1 = cutf8_decode(__param_d, (((*__ci_expr_old_0) as u8) as c_uint)))
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if ((if __local_s != __param_end: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        goto '__ci_bb_8
    }

    '__ci_bb_4 {
        if (__ci_expr_switch_1 == 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_5 {
        goto '__ci_bb_2
    }

    '__ci_bb_6 {
        return ((((((__local_s as usize) -% (__local_start__goto_29_17 as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_int))
    }

    '__ci_bb_7 {
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        ((*__param_d).state = ((0 as c_uint)))
        ((*__param_d).codep = ((65533 as c_uint)))
        (__local_len__goto_38_9 = ((((((__local_s as usize) -% (__local_start__goto_29_17 as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_int)))
        return (if (if __local_len__goto_38_9 <= 2: 1 else: 0) != 0: (1 as c_int) else: ((__local_len__goto_38_9 - 1) as c_int))
    }

    '__ci_bb_9 {
        if (__ci_expr_switch_1 == 12) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_5
        }
    }

    __ci_unreachable()

}

pub unsafe fn cutf8_peek(__param_s: *const c_char) -> c_uint {
    var __local_s = __param_s
    var __local_d: cutf8_decode_t = cutf8_decode_t.zeroed()

    loop {
        var __ci_expr_old_0: *const c_char = __local_s

        (__local_s = __local_s + 1)

        cutf8_decode((&raw mut __local_d as *mut cutf8_decode_t), (((*__ci_expr_old_0) as u8) as c_uint))


        if not (((if (*(&raw const __local_d as *const cutf8_decode_t)).state > 12: 1 else: 0) != 0)) {
            break
        }
    }

    return (if (if (*(&raw const __local_d as *const cutf8_decode_t)).state == 0: 1 else: 0) != 0: (*(&raw const __local_d as *const cutf8_decode_t)).codep else: (65533 as c_uint))

}

unsafe fn cutf8_decode(__param_d: *mut cutf8_decode_t, __param_byte: c_uint) -> c_uint {
    var __local_cutf8_dtab: []u8

    var __local_type_: c_uint = ((__local_cutf8_dtab[__param_byte] as c_uint))

    ((*__param_d).codep = (((if (*__param_d).state != 0: (((((__param_byte as c_uint) & (63 as c_uint)) as c_uint) | ((((*__param_d).codep as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) else: (((((255 as c_uint) >> (__local_type_ as c_uint)) as c_uint) & (__param_byte as c_uint)) as c_uint)) as c_uint)))

    ((*__param_d).state = ((__local_cutf8_dtab[((((256 as c_uint) +% ((*__param_d).state as c_uint)) as c_uint) +% (__local_type_ as c_uint))] as c_uint)))

    return (*__param_d).state


}
