// Migrated from C
use std.engines.stc.defs
use std.engines.stc.utf8_misc
use std.engines.stc.cstr_utf8
use std.engines.stc.ucd
use std.libc

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


    while ((if __local_len >= ((sizeof[u64]() as i64)): 1 else: 0) != 0) {
        with_memcpy((((&raw mut __local_block as *mut u64) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        (__local_h = (__local_h as u64) ^ (__local_block as u64))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[u64]() as i64) as usize))

        (__local_len = __local_len - (sizeof[u64]() as i64))

    }

    while true {
        var __ci_expr_old_0: i64 = __local_len

        (__local_len = __local_len - 1)

        if (not (__ci_expr_old_0 != 0)) {
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

    while ((*__local_msg) != 0) {
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

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
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
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return ((__local_str as *mut c_char))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: i64 = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut c_char))

}

// contract: unproved:0:read only
unsafe fn cutf8_chr_size(__param_s: *const c_char) -> i32 {
    return ((((((4837428950035665169 as u64) >> (((((((*__param_s) as u8) as i32) >> (4 as u32)) as i32) << (2 as u32)) as u32)) as u64) & (15 as u64)) as i32))

}

// contract: unproved:0:read only
unsafe fn cutf8_count(__param_s: *const c_char) -> i64 {
    var __local_s = __param_s
    var __local_size: i64 = ((0 as i64))

    while ((*__local_s) != 0) {
        (__local_s = __local_s + 1)

        (__local_size = __local_size + (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    return __local_size

}

// contract: unproved:0:read only
unsafe fn cutf8_count_n(__param_s: *const c_char, __param_nbytes: i64) -> i64 {
    var __local_s = __param_s
    var __local_nbytes = __param_nbytes
    var __local_size: i64 = ((0 as i64))

    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: i64 = __local_nbytes

        (__local_nbytes = __local_nbytes - 1)

        if ((if __ci_expr_old_0 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__local_s) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        (__local_s = __local_s + 1)

        (__local_size = __local_size + (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    return __local_size

}

// contract: unproved:0:read only
unsafe fn cutf8_at(__param_s: *const c_char, __param_u8pos: i64) -> *const c_char {
    var __local_s = __param_s
    var __local_u8pos = __param_u8pos
    while ((((if __local_u8pos > 0: 1 else: 0) as i32) & ((if (*__local_s) != 0: 1 else: 0) as i32)) != 0) {
        (__local_s = __local_s + 1)

        (__local_u8pos = __local_u8pos - (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    if (((if not ((if __local_u8pos == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cutf8_at".ptr, c"utf8_prv.h".ptr, (57 as i32), c"u8pos == 0".ptr)
    } else {
        0
    }

    return __local_s

}

// contract: unproved:0:read only
unsafe fn cutf8_offset(__param_s: *const c_char, __param_u8pos: i64) -> *const c_char {
    var __local_s = __param_s
    var __local_u8pos = __param_u8pos
    var __local_inc: i32 = ((1 as i32))

    if ((if __local_u8pos < 0: 1 else: 0) != 0) {
        (__local_u8pos = (((0 - __local_u8pos) as i64)))

        (__local_inc = ((-1 as i32)))

    }

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_u8pos != 0) {
            (__ci_expr_logic_0 = (if (*__local_s) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_s = __local_s + ((__local_inc as i64) as usize))

        (__local_u8pos = __local_u8pos - (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    if (((if not ((if __local_u8pos == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cutf8_offset".ptr, c"utf8_prv.h".ptr, (66 as i32), c"u8pos == 0".ptr)
    } else {
        0
    }

    return __local_s

}

// contract: unproved:0:read only
unsafe fn cutf8_to_index(__param_s: *const c_char, __param_u8pos: i64) -> i64 {
    return ((((cutf8_at(__param_s, __param_u8pos) as usize) -% (__param_s as usize)) as i64) / (sizeof[c_char]() as i64))

}

// contract: unproved:0:read only
unsafe fn cutf8_subview(__param_s: *const c_char, __param_u8pos: i64, __param_u8len: i64) -> csview {
    var __local_span: csview

    (__local_span.buf = ((cutf8_at(__param_s, __param_u8pos) as *mut c_char)))

    (__local_span.size = ((cutf8_to_index(((*(&raw const __local_span as *const csview)).buf as *const c_char), __param_u8len) as i64)))

    return __local_span

}

unsafe fn cutf8_decode(__param_d: *mut cutf8_decode_t, __param_byte: u32) -> u32 {
    var __local_cutf8_dtab: []u8

    var __local_type_: u32 = ((__local_cutf8_dtab[__param_byte] as u32))

    ((*__param_d).codep = (((if (*__param_d).state != 0: (((((__param_byte as u32) & (63 as u32)) as u32) | ((((*__param_d).codep as u32) << (6 as u32)) as u32)) as u32) else: (((((255 as u32) >> (__local_type_ as u32)) as u32) & (__param_byte as u32)) as u32)) as u32)))

    ((*__param_d).state = ((__local_cutf8_dtab[((((256 as u32) +% ((*__param_d).state as u32)) as u32) +% (__local_type_ as u32))] as u32)))

    return (*__param_d).state


}

// contract: unproved:0:read only
unsafe fn cutf8_peek_at(__param_s: *const c_char, __param_offset: i64) -> u32 {
    return cutf8_peek(cutf8_offset(__param_s, __param_offset))

}

fn cutf8_isupper(__param_c: u32) -> bool {
    return ((((if (if __param_c < 128: 1 else: 0) != 0: ((((if __param_c >= 65: 1 else: 0) as i32) & ((if __param_c <= 90: 1 else: 0) as i32)) as i32) else: ((if cutf8_tolower(__param_c) != __param_c: 1 else: 0) as i32)) != 0) as bool))

}

fn cutf8_islower(__param_c: u32) -> bool {
    return ((((if (if __param_c < 128: 1 else: 0) != 0: ((((if __param_c >= 97: 1 else: 0) as i32) & ((if __param_c <= 122: 1 else: 0) as i32)) as i32) else: ((if cutf8_toupper(__param_c) != __param_c: 1 else: 0) as i32)) != 0) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cutf8_icmp(__param_s1: *const c_char, __param_s2: *const c_char) -> i32 {
    return cutf8_icmp_sv((csview { buf: __param_s1, size: 9223372036854775807 } as csview), (csview { buf: __param_s2, size: 9223372036854775807 } as csview))

}

fn cutf8_isdigit(__param_c: u32) -> bool {
    return ((((if (if __param_c < 128: 1 else: 0) != 0: ((((if __param_c >= 48: 1 else: 0) as i32) & ((if __param_c <= 57: 1 else: 0) as i32)) as i32) else: (cutf8_isgroup(U8G_Nd, __param_c) as i32)) != 0) as bool))

}

fn cutf8_isalpha(__param_c: u32) -> bool {
    return ((((if (if __param_c < 128: 1 else: 0) != 0: ((if isalpha((__param_c as i32)) != 0: 1 else: 0) as i32) else: (cutf8_isgroup(U8G_L, __param_c) as i32)) != 0) as bool))

}

fn cutf8_iscased(__param_c: u32) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((isalpha((__param_c as i32)) != 0)) as bool))
    }

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if ((if cutf8_toupper(__param_c) != __param_c: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if cutf8_tolower(__param_c) != __param_c: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if cutf8_isgroup(U8G_Lt, __param_c) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_1 != 0) as bool))


}

fn cutf8_isalnum(__param_c: u32) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((isalnum((__param_c as i32)) != 0)) as bool))
    }

    var __ci_expr_logic_0: i32

    if (cutf8_isgroup(U8G_L, __param_c) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Nd, __param_c) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

fn cutf8_isword(__param_c: u32) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((((if isalnum((__param_c as i32)) != 0: 1 else: 0) as i32) | ((if __param_c == 95: 1 else: 0) as i32)) != 0) as bool))
    }

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if (cutf8_isgroup(U8G_L, __param_c) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Nd, __param_c) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if cutf8_isgroup(U8G_Pc, __param_c) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_1 != 0) as bool))


}

fn cutf8_isblank(__param_c: u32) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((((if __param_c == 32: 1 else: 0) as i32) | ((if __param_c == 9: 1 else: 0) as i32)) != 0) as bool))
    }

    return cutf8_isgroup(U8G_Zs, __param_c)

}

fn cutf8_isspace(__param_c: u32) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((isspace((__param_c as i32)) != 0)) as bool))
    }

    var __ci_expr_logic_0: i32

    if ((((if __param_c == 8232: 1 else: 0) as i32) | ((if __param_c == 8233: 1 else: 0) as i32)) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Zs, __param_c) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

pub fn csview_advance(__param_it_: csview_iter, __param_u8pos: i64) -> csview_iter {
    var __local_u8pos = __param_u8pos
    var __local_inc: i32 = ((1 as i32))

    if ((if __local_u8pos < 0: 1 else: 0) != 0) {
        (__local_u8pos = (((0 - __local_u8pos) as i64)))

        (__local_inc = ((-1 as i32)))

    }

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_u8pos != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *(&raw const __param_it_ as *const csview_iter)).ref != (unsafe *(&raw const __param_it_.u8 as *const csview_iter_u8)).end: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const csview_iter)).ref + ((__local_inc as i64) as usize))

        (__local_u8pos = __local_u8pos - (if (((unsafe *((*(&raw const __param_it_ as *const csview_iter)).ref)) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    if ((if (unsafe *(&raw const __param_it_ as *const csview_iter)).ref == (unsafe *(&raw const __param_it_.u8 as *const csview_iter_u8)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut c_char)))
    } else {
        (__param_it_.chr.size = ((unsafe { cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __param_it_ as *const csview_iter)).u8 as *const csview_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), ((*(&raw const __param_it_ as *const csview_iter)).ref as *const c_char), ((*(&raw const __param_it_.u8 as *const csview_iter_u8)).end as *const c_char)) } as i64)))
    }

    return __param_it_

}

pub fn csview_subview_pro(__param_sv: csview, __param_pos: i64, __param_len: i64) -> csview {
    var __local_pos = __param_pos
    var __local_len = __param_len
    if ((if __local_pos < 0: 1 else: 0) != 0) {
        (__local_pos = __local_pos + (unsafe *(&raw const __param_sv as *const csview)).size)

        if ((if __local_pos < 0: 1 else: 0) != 0) {
            (__local_pos = ((0 as i64)))
        }

    }

    if ((if __local_pos > (unsafe *(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_pos = (unsafe *(&raw const __param_sv as *const csview)).size)
    }

    if ((if (__local_pos + __local_len) > (unsafe *(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_len = ((((unsafe *(&raw const __param_sv as *const csview)).size - __local_pos) as i64)))
    }

    (__param_sv.buf = (unsafe *(&raw const __param_sv as *const csview)).buf + ((__local_pos as i64) as usize))

    (__param_sv.size = __local_len)


    return __param_sv

}

// contract: unproved:1:read only,unproved:2:out-parameter written conditionally
pub unsafe fn csview_split(__param_sv: csview, __param_sep: *const c_char, __param_pos: *mut i64) -> csview {
    if ((if (*__param_pos) >= (*(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        return ((csview { buf: ("" as *mut c_char), size: ((((1 * (sizeof[c_char]() as usize)) as i64) - 1)) } as csview))
    }

    var __local_sep_size: i64 = ((strlen(__param_sep) as i64))

    var __local_in_: csview = csview { buf: ((*(&raw const __param_sv as *const csview)).buf + (((*__param_pos) as i64) as usize)), size: ((*(&raw const __param_sv as *const csview)).size - (*__param_pos)) }

    var __local_res: *const c_char = ((c_strnstrn(((*(&raw const __local_in_ as *const csview)).buf as *const c_char), (*(&raw const __local_in_ as *const csview)).size, __param_sep, __local_sep_size) as *const c_char))

    if (__local_res != null) {
        (__local_in_.size = ((((((__local_res as usize) -% ((*(&raw const __local_in_ as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)) as i64)))

        ((*__param_pos) = (*__param_pos) + ((*(&raw const __local_in_ as *const csview)).size + __local_sep_size))

    } else {
        ((*__param_pos) = ((9223372036854775807 as i64)))
    }

    return __local_in_

}

// contract: unproved:1:read only,unproved:2:out-parameter written conditionally
pub unsafe fn csview_strtok(__param_sv: csview, __param_delims: *const c_char, __param_pos: *mut i64) -> csview {
    if ((if (*__param_pos) >= (*(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        return ((csview { buf: ("" as *mut c_char), size: ((((1 * (sizeof[c_char]() as usize)) as i64) - 1)) } as csview))
    }

    var __local_dec: cutf8_decode_t = cutf8_decode_t.zeroed()

    var __local_in_: csview = csview { buf: ((*(&raw const __param_sv as *const csview)).buf + (((*__param_pos) as i64) as usize)), size: ((*(&raw const __param_sv as *const csview)).size - (*__param_pos)) }

    var __local_i: csview_iter = csview_begin(((&raw mut __local_in_ as *mut csview) as *const csview))

    while ((*(&raw const __local_i as *const csview_iter)).ref != null) {
        var __local_m: *const c_char = __param_delims

        while ((*__local_m) != 0) {
            var __ci_expr_logic_0: i32 = 0

            if ((if cutf8_decode((&raw mut __local_dec as *mut cutf8_decode_t), (((*__local_m) as u8) as u32)) == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if (*(&raw const __local_i.u8.dec as *const cutf8_decode_t)).codep == (*(&raw const __local_dec as *const cutf8_decode_t)).codep: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (__local_in_.size = (((((((*(&raw const __local_i.chr as *const csview)).buf as usize) -% ((*(&raw const __local_in_ as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)) as i64)))

                ((*__param_pos) = (*__param_pos) + ((*(&raw const __local_in_ as *const csview)).size + (*(&raw const __local_i.chr as *const csview)).size))

                return __local_in_

            }



            (__local_m = __local_m + 1)

        }



        (*(&raw mut __local_i as *mut csview_iter)).next()

    }


    ((*__param_pos) = ((9223372036854775807 as i64)))

    return __local_in_

}

pub fn csview_u8_subview(__param_sv: csview, __param_u8pos: i64, __param_u8len: i64) -> csview {
    var __local_u8pos = __param_u8pos
    var __local_u8len = __param_u8len
    var __local_s: *const c_char

    var __local_end: *const c_char = ((((&raw const (unsafe __param_sv.buf[(*(&raw const __param_sv as *const csview)).size]) as *const c_char) as *mut c_char) as *const c_char))


    while ((((if __local_u8pos > 0: 1 else: 0) as i32) & ((if (unsafe *(&raw const __param_sv as *const csview)).buf != __local_end: 1 else: 0) as i32)) != 0) {
        (__param_sv.buf = (unsafe *(&raw const __param_sv as *const csview)).buf + 1)

        (__local_u8pos = __local_u8pos - (if (((unsafe *((*(&raw const __param_sv as *const csview)).buf)) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    (__local_s = (((unsafe *(&raw const __param_sv as *const csview)).buf as *const c_char)))

    while ((((if __local_u8len > 0: 1 else: 0) as i32) & ((if __local_s != __local_end: 1 else: 0) as i32)) != 0) {
        (__local_s = __local_s + 1)

        (__local_u8len = __local_u8len - (if (((unsafe *__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    (__param_sv.size = ((((((__local_s as usize) -% ((unsafe *(&raw const __param_sv as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)) as i64)))

    return __param_sv

}

pub fn csview_u8_tail(__param_sv: csview, __param_u8len: i64) -> csview {
    var __local_u8len = __param_u8len
    var __local_p: *const c_char = ((((&raw const (unsafe __param_sv.buf[(*(&raw const __param_sv as *const csview)).size]) as *const c_char) as *mut c_char) as *const c_char))

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_u8len != 0) {
            (__ci_expr_logic_0 = (if (if __local_p != (unsafe *(&raw const __param_sv as *const csview)).buf: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_p = __local_p - 1)

        (__local_u8len = __local_u8len - (if (((unsafe *__local_p) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    (__param_sv.size = (unsafe *(&raw const __param_sv as *const csview)).size - ((((__local_p as usize) -% ((unsafe *(&raw const __param_sv as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)))

    (__param_sv.buf = ((__local_p as *mut c_char)))


    return __param_sv

}

pub fn csview_u8_at(__param_sv: csview, __param_u8pos: i64) -> csview_iter {
    var __local_u8pos = __param_u8pos
    var __local_it_: csview_iter = csview_iter { u8: csview_iter_u8 { chr: __param_sv, end: ((unsafe *(&raw const __param_sv as *const csview)).buf + (((unsafe *(&raw const __param_sv as *const csview)).size as i64) as usize)), dec: cutf8_decode_t.zeroed() } }

    while ((((if __local_u8pos > 0: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local_it_ as *const csview_iter)).ref != (unsafe *(&raw const __local_it_.u8 as *const csview_iter_u8)).end: 1 else: 0) as i32)) != 0) {
        (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const csview_iter)).ref + 1)

        (__local_u8pos = __local_u8pos - (if (((unsafe *((*(&raw const __local_it_ as *const csview_iter)).ref)) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    if (((if not ((if __local_u8pos == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"csview_u8_at".ptr, c"csview.h".ptr, (264 as i32), c"u8pos == 0".ptr)
    } else {
        0
    }

    (__local_it_.chr.size = ((unsafe { cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const csview_iter)).u8 as *const csview_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), ((*(&raw const __local_it_ as *const csview_iter)).ref as *const c_char), ((*(&raw const __local_it_.u8 as *const csview_iter_u8)).end as *const c_char)) } as i64)))

    return __local_it_

}

// contract: unproved:0:read only
pub unsafe fn csview_from(__param_str: *const c_char) -> csview {
    return ((csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

// contract: unproved:0:read only
pub unsafe fn csview_from_n(__param_str: *const c_char, __param_n: i64) -> csview {
    return ((csview { buf: __param_str, size: __param_n } as csview))

}

pub fn csview_size(__param_sv: csview) -> i64 {
    return (unsafe *(&raw const __param_sv as *const csview)).size

}

pub fn csview_is_empty(__param_sv: csview) -> bool {
    return (((((unsafe *(&raw const __param_sv as *const csview)).size == 0)) as bool))

}

pub fn csview_equals_sv(__param_sv1: csview, __param_sv2: csview) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((if (unsafe *(&raw const __param_sv1 as *const csview)).size == (unsafe *(&raw const __param_sv2 as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((unsafe *(&raw const __param_sv1 as *const csview)).buf as *const c_void) as *const u8), (((unsafe *(&raw const __param_sv2 as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (unsafe *(&raw const __param_sv1 as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:1:read only
pub unsafe fn csview_equals(__param_sv: csview, __param_str: *const c_char) -> bool {
    return csview_equals_sv(__param_sv, (csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

// contract: unproved:0:read only
pub unsafe fn csview_hash(__param_self_: *const csview) -> u64 {
    return c_basehash_n(((*__param_self_).buf as *const c_void), (*__param_self_).size)

}

pub fn csview_find_sv(__param_sv: csview, __param_search: csview) -> i64 {
    var __local_res: *mut c_char = unsafe { c_strnstrn(((*(&raw const __param_sv as *const csview)).buf as *const c_char), (*(&raw const __param_sv as *const csview)).size, ((*(&raw const __param_search as *const csview)).buf as *const c_char), (*(&raw const __param_search as *const csview)).size) }

    return (if __local_res != null: (((((__local_res as usize) -% ((unsafe *(&raw const __param_sv as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)) as i64) else: (9223372036854775807 as i64))

}

// contract: unproved:1:read only
pub unsafe fn csview_find(__param_sv: csview, __param_str: *const c_char) -> i64 {
    return csview_find_sv(__param_sv, (csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

// contract: unproved:1:read only
pub unsafe fn csview_contains(__param_sv: csview, __param_str: *const c_char) -> bool {
    return ((((csview_find(__param_sv, __param_str) != 9223372036854775807)) as bool))

}

// contract: unproved:1:read only
pub unsafe fn csview_starts_with(__param_sv: csview, __param_str: *const c_char) -> bool {
    var __local_n: i64 = ((strlen(__param_str) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_n <= (*(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((*(&raw const __param_sv as *const csview)).buf as *const c_void) as *const u8), ((__param_str as *const c_void) as *const u8), (((if 1 != 0: __local_n else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:1:read only
pub unsafe fn csview_ends_with(__param_sv: csview, __param_str: *const c_char) -> bool {
    var __local_n: i64 = ((strlen(__param_str) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_n <= (*(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((((*(&raw const __param_sv as *const csview)).buf + (((*(&raw const __param_sv as *const csview)).size as i64) as usize)) - ((__local_n as i64) as usize)) as *const c_void) as *const u8), ((__param_str as *const c_void) as *const u8), (((if 1 != 0: __local_n else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

pub fn csview_subview(__param_sv: csview, __param_pos: i64, __param_len: i64) -> csview {
    var __local_len = __param_len
    if (((if not ((((if ((__param_pos as u64)) <= (((unsafe *(&raw const __param_sv as *const csview)).size as u64)): 1 else: 0) as i32) & ((if __local_len >= 0: 1 else: 0) as i32)) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"csview_subview".ptr, c"csview.h".ptr, (80 as i32), c"((size_t)pos <= (size_t)sv.size) & (len >= 0)".ptr)
    } else {
        0
    }

    if ((if (__param_pos + __local_len) > (unsafe *(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_len = ((((unsafe *(&raw const __param_sv as *const csview)).size - __param_pos) as i64)))
    }

    (__param_sv.buf = (unsafe *(&raw const __param_sv as *const csview)).buf + ((__param_pos as i64) as usize))

    (__param_sv.size = __local_len)


    return __param_sv

}

pub fn csview_slice(__param_sv: csview, __param_p1: i64, __param_p2: i64) -> csview {
    var __local_p2 = __param_p2
    if (((if not ((((if ((__param_p1 as u64)) <= ((__local_p2 as u64)): 1 else: 0) as i32) & ((if ((__param_p1 as u64)) <= (((unsafe *(&raw const __param_sv as *const csview)).size as u64)): 1 else: 0) as i32)) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"csview_slice".ptr, c"csview.h".ptr, (87 as i32), c"((size_t)p1 <= (size_t)p2) & ((size_t)p1 <= (size_t)sv.size)".ptr)
    } else {
        0
    }

    if ((if __local_p2 > (unsafe *(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_p2 = (unsafe *(&raw const __param_sv as *const csview)).size)
    }

    (__param_sv.buf = (unsafe *(&raw const __param_sv as *const csview)).buf + ((__param_p1 as i64) as usize))

    (__param_sv.size = (((__local_p2 - __param_p1) as i64)))


    return __param_sv

}

pub fn csview_trim_start(__param_sv: csview) -> csview {
    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((unsafe *(&raw const __param_sv as *const csview)).size != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *((*(&raw const __param_sv as *const csview)).buf)) <= 32: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__param_sv.buf = (unsafe *(&raw const __param_sv as *const csview)).buf + 1)

        (__param_sv.size = (unsafe *(&raw const __param_sv as *const csview)).size - 1)

    }

    return __param_sv

}

pub fn csview_trim_end(__param_sv: csview) -> csview {
    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((unsafe *(&raw const __param_sv as *const csview)).size != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe (*(&raw const __param_sv as *const csview)).buf[((*(&raw const __param_sv as *const csview)).size - 1)]) <= 32: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__param_sv.size = (unsafe *(&raw const __param_sv as *const csview)).size - 1)

    }

    return __param_sv

}

pub fn csview_trim(__param_sv: csview) -> csview {
    return csview_trim_end(csview_trim_start(__param_sv))

}

pub fn csview_tail(__param_sv: csview, __param_len: i64) -> csview {
    return csview_subview(__param_sv, (((unsafe *(&raw const __param_sv as *const csview)).size - __param_len) as i64), __param_len)

}

// contract: unproved:0:read only
pub unsafe fn csview_begin(__param_self_: *const csview) -> csview_iter {
    var __local_it_: csview_iter = csview_iter { u8: csview_iter_u8 { chr: csview { buf: (*__param_self_).buf }, end: ((*__param_self_).buf + (((*__param_self_).size as i64) as usize)), dec: cutf8_decode_t.zeroed() } }

    if ((if (*(&raw const __local_it_ as *const csview_iter)).ref == (*(&raw const __local_it_.u8 as *const csview_iter_u8)).end: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *mut c_char)))
    } else {
        (__local_it_.u8.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const csview_iter)).u8 as *const csview_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), ((*(&raw const __local_it_ as *const csview_iter)).ref as *const c_char), ((*(&raw const __local_it_.u8 as *const csview_iter_u8)).end as *const c_char)) as i64)))
    }

    return __local_it_

}

// contract: unproved:0:read only
pub unsafe fn csview_end(__param_self_: *const csview) -> csview_iter {

    var __local_it_: csview_iter = csview_iter.zeroed()

    return __local_it_

}

// contract: unproved:0:read only
pub unsafe fn csview_codepoint(__param_it_: *const csview_iter) -> u32 {
    return (*(&raw const (*__param_it_).u8.dec as *const cutf8_decode_t)).codep

}

// contract: unproved:0:read only
pub unsafe fn csview_u8_from(__param_str: *const c_char, __param_u8pos: i64, __param_u8len: i64) -> csview {
    return cutf8_subview(__param_str, __param_u8pos, __param_u8len)

}

pub fn csview_u8_size(__param_sv: csview) -> i64 {
    return unsafe { cutf8_count_n(((*(&raw const __param_sv as *const csview)).buf as *const c_char), (*(&raw const __param_sv as *const csview)).size) }

}

pub fn csview_u8_valid(__param_sv: csview) -> bool {
    return unsafe { cutf8_valid_n(((*(&raw const __param_sv as *const csview)).buf as *const c_char), (*(&raw const __param_sv as *const csview)).size) }

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn csview_cmp(__param_x: *const csview, __param_y: *const csview) -> i32 {
    var __local_n: i64 = (((if (if (*__param_x).size < (*__param_y).size: 1 else: 0) != 0: (*__param_x).size else: (*__param_y).size) as i64))

    var __local_c: i32 = ((with_memcmp((((*__param_x).buf as *const c_void) as *const u8), (((*__param_y).buf as *const c_void) as *const u8), (((if 1 != 0: __local_n else: (-1 as i64)) as u64) as i64)) as i32))

    return (if __local_c != 0: __local_c else: (((if (*(&raw const (*__param_y).size as *const i64)) < (*(&raw const (*__param_x).size as *const i64)): 1 else: 0) - (if (*(&raw const (*__param_x).size as *const i64)) < (*(&raw const (*__param_y).size as *const i64)): 1 else: 0)) as i32))

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn csview_eq(__param_x: *const csview, __param_y: *const csview) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_x).size == (*__param_y).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((*__param_x).buf as *const c_void) as *const u8), (((*__param_y).buf as *const c_void) as *const u8), (((if 1 != 0: (*__param_x).size else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

pub fn csview_iequals_sv(__param_sv1: csview, __param_sv2: csview) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((if (unsafe *(&raw const __param_sv1 as *const csview)).size == (unsafe *(&raw const __param_sv2 as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__param_sv1, __param_sv2) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:1:read only
pub unsafe fn csview_iequals(__param_sv: csview, __param_str: *const c_char) -> bool {
    return csview_iequals_sv(__param_sv, (csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn csview_ieq(__param_x: *const csview, __param_y: *const csview) -> bool {
    return csview_iequals_sv((*__param_x), (*__param_y))

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn csview_icmp(__param_x: *const csview, __param_y: *const csview) -> i32 {
    return cutf8_icmp_sv((*__param_x), (*__param_y))

}

// contract: unproved:1:read only
pub unsafe fn csview_istarts_with(__param_sv: csview, __param_str: *const c_char) -> bool {
    var __local_n: i64 = ((strlen(__param_str) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_n <= (*(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__param_sv, (csview { buf: __param_str, size: __local_n } as csview)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:1:read only
pub unsafe fn csview_iends_with(__param_sv: csview, __param_str: *const c_char) -> bool {
    var __local_n: i64 = ((strlen(__param_str) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_n <= (*(&raw const __param_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp(((((*(&raw const __param_sv as *const csview)).buf + (((*(&raw const __param_sv as *const csview)).size as i64) as usize)) - ((__local_n as i64) as usize)) as *const c_char), __param_str) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

impl csview {
    pub mut fn clear() -> Unit {
        let __param_self_: *mut csview = self as *mut csview
        let __ci_copy_20: csview = (csview { buf: ("" as *mut c_char), size: ((((1 * (sizeof[c_char]() as usize)) as i64) - 1)) } as csview)
        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __ci_copy_20 as *const u8), sizeof[csview]())

    }

}

impl csview_iter {
    pub mut fn next() -> Unit {
        let __param_it_: *mut csview_iter = self as *mut csview_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + (((unsafe *(&raw const (*__param_it_).chr as *const csview)).size as i64) as usize))

        if ((if (unsafe *__param_it_).ref == (unsafe *(&raw const (*__param_it_).u8 as *const csview_iter_u8)).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut c_char)))
        } else {
            ((unsafe *__param_it_).chr.size = ((unsafe { cutf8_decode_codepoint(((&raw const (*(&raw const (*__param_it_).u8 as *const csview_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), ((*__param_it_).ref as *const c_char), ((*(&raw const (*__param_it_).u8 as *const csview_iter_u8)).end as *const c_char)) } as i64)))
        }

    }

}
