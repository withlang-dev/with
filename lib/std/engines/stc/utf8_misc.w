// Migrated from C
use std.engines.stc.defs

// contract: unproved:0:read only,unproved:1:read only
unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: i64) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as u64) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

// contract: unproved:0:read only
unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    var __local_block: u64 = ((0 as u64))


    while (__local_len >= ((sizeof[u64]() as i64))) {
        with_memcpy((((&raw mut __local_block as *mut u64) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        (__local_h = (__local_h as u64) ^ (__local_block as u64))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[u64]() as i64) as usize))

        (__local_len = __local_len - (sizeof[u64]() as i64))

    }

    while true {
        var __ci_expr_old_0: i64 = __local_len

        (__local_len = __local_len - 1)

        if (not __ci_expr_old_0) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_1) as u64))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

// contract: unproved:0:read only
unsafe fn c_hash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_b8: u64

    var __local_b4: u32

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut u64) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as u64) as i64))

            return ((__local_b8 as u64) *% (((0 as u64) -% 4132994306676758115) as u64))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut u32) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as u64) as i64))

            return ((__local_b4 as u64) *% (((0 as u64) -% 3750763034362895579) as u64))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

// contract: unproved:0:read only
unsafe fn c_hash_str(__param_str: *const c_char) -> u64 {
    var __local_msg: *const u8 = ((__param_str as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    while (*__local_msg) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_0) as u64))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

// contract: unproved:0:out-parameter read before the write
unsafe fn c_hash_mix_n(__param_h: *mut u64, __param_n: i64) -> u64 {
    var __local_i: i64 = ((1 as i64))

    while (__local_i < __param_n) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as u64) ^ ((__param_h[__local_i]) as u64))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: i64) -> i64 {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (1 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (2 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (4 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (8 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (16 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (32 as u32)) as i64))

    return (__local_n + 1)

}

// contract: unproved:0:read only,unproved:2:read only
unsafe fn c_strnstrn(__param_str: *const c_char, __param_slen: i64, __param_needle: *const c_char, __param_nlen: i64) -> *mut c_char {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if (__param_nlen == 0) {
        return ((__local_str as *mut c_char))
    }

    if (__param_nlen > __local_slen) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((*__local_str) == (*__param_needle)) {
            (__ci_expr_logic_1 = (if not with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if true: __param_nlen else: (-1 as i64)) as u64) as i64)): 1 else: 0))
        }

        if __ci_expr_logic_1 {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: i64 = __local_slen

        (__local_slen = __local_slen - 1)

        if not (__ci_expr_old_0) {
            break
        }
    }

    return ((null as *mut c_char))

}

// contract: receiver-mut:cutf8_decode_t,unproved:1:read only,unproved:2:read only
pub unsafe fn cutf8_decode_codepoint(__param_d: *mut cutf8_decode_t, __param_s: *const c_char, __param_end: *const c_char) -> i32 {
    var __local_s = __param_s
    var __local_start__goto_29_17: *const c_char = null

    var __local_len__goto_38_9: i32 = 0

    var __ci_expr_old_0: *const c_char = null

    var __ci_expr_switch_1: u32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_start__goto_29_17 = __local_s)
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__ci_expr_old_0 = __local_s)
        (__local_s = __local_s + 1)
        (__ci_expr_switch_1 = cutf8_decode(__param_d, (((*__ci_expr_old_0) as u8) as u32)))
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if (__local_s != __param_end) {
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
        return ((((((__local_s as usize) -% (__local_start__goto_29_17 as usize)) as i64) / (sizeof[c_char]() as i64)) as i32))
    }

    '__ci_bb_7 {
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        ((*__param_d).state = ((0 as u32)))
        ((*__param_d).codep = ((65533 as u32)))
        (__local_len__goto_38_9 = ((((((__local_s as usize) -% (__local_start__goto_29_17 as usize)) as i64) / (sizeof[c_char]() as i64)) as i32)))
        return (if __local_len__goto_38_9 <= 2: (1 as i32) else: ((__local_len__goto_38_9 - 1) as i32))
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

// contract: unproved:0:read only
pub unsafe fn cutf8_peek(__param_s: *const c_char) -> u32 {
    var __local_s = __param_s
    var __local_d: cutf8_decode_t = cutf8_decode_t.zeroed()

    loop {
        var __ci_expr_old_0: *const c_char = __local_s

        (__local_s = __local_s + 1)

        cutf8_decode((&raw mut __local_d as *mut cutf8_decode_t), (((*__ci_expr_old_0) as u8) as u32))


        if not (((*(&raw const __local_d as *const cutf8_decode_t)).state > 12)) {
            break
        }
    }

    return (if (*(&raw const __local_d as *const cutf8_decode_t)).state == 0: (*(&raw const __local_d as *const cutf8_decode_t)).codep else: (65533 as u32))

}

unsafe fn cutf8_decode(__param_d: *mut cutf8_decode_t, __param_byte: u32) -> u32 {
    var __local_cutf8_dtab: []u8

    var __local_type_: u32 = ((__local_cutf8_dtab[__param_byte] as u32))

    ((*__param_d).codep = (((if (*__param_d).state: (((((__param_byte as u32) & (63 as u32)) as u32) | ((((*__param_d).codep as u32) << (6 as u32)) as u32)) as u32) else: (((((255 as u32) >> (__local_type_ as u32)) as u32) & (__param_byte as u32)) as u32)) as u32)))

    ((*__param_d).state = ((__local_cutf8_dtab[((((256 as u32) +% ((*__param_d).state as u32)) as u32) +% (__local_type_ as u32))] as u32)))

    return (*__param_d).state


}
