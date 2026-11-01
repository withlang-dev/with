// Migrated from C
use std.engines.stc.defs
use std.engines.stc.utf8_misc
use std.engines.stc.cstr_utf8
use std.libc
use std.collections

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

// contract: unproved:0:read only
unsafe fn cutf8_chr_size(__param_s: *const c_char) -> i32 {
    return ((((((4837428950035665169 as u64) >> (((((((*__param_s) as u8) as i32) >> (4 as u32)) as i32) << (2 as u32)) as u32)) as u64) & (15 as u64)) as i32))

}

// contract: unproved:0:read only
unsafe fn cutf8_count(__param_s: *const c_char) -> i64 {
    var __local_s = __param_s
    var __local_size: i64 = ((0 as i64))

    while (*__local_s) {
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

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (*__local_s) != 0: 1 else: 0))
        }

        if (not __ci_expr_logic_1) {
            break
        }

        (__local_s = __local_s + 1)

        (__local_size = __local_size + (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    return __local_size

}

unsafe fn cutf8_at(__param_s: *const c_char, __param_u8pos: i64) -> *const c_char {
    var __local_s = __param_s
    var __local_u8pos = __param_u8pos
    while (((if __local_u8pos > 0: 1 else: 0) as i32) & ((if (*__local_s) != 0: 1 else: 0) as i32)) {
        (__local_s = __local_s + 1)

        (__local_u8pos = __local_u8pos - (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    if ((if not (__local_u8pos == 0): 1 else: 0) as i64) {
        __assert_rtn(c"cutf8_at".ptr, c"utf8_prv.h".ptr, (57 as i32), c"u8pos == 0".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn cutf8_offset(__param_s: *const c_char, __param_u8pos: i64) -> *const c_char {
    var __local_s = __param_s
    var __local_u8pos = __param_u8pos
    var __local_inc: i32 = ((1 as i32))

    if (__local_u8pos < 0) {
        (__local_u8pos = (((0 - __local_u8pos) as i64)))

        (__local_inc = ((-1 as i32)))

    }

    while true {
        var __ci_expr_logic_0: i32 = 0

        if __local_u8pos {
            (__ci_expr_logic_0 = (if (*__local_s): 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_s = __local_s + ((__local_inc as i64) as usize))

        (__local_u8pos = __local_u8pos - (if (((*__local_s) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    if ((if not (__local_u8pos == 0): 1 else: 0) as i64) {
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

    ((*__param_d).codep = (((if (*__param_d).state: (((((__param_byte as u32) & (63 as u32)) as u32) | ((((*__param_d).codep as u32) << (6 as u32)) as u32)) as u32) else: (((((255 as u32) >> (__local_type_ as u32)) as u32) & (__param_byte as u32)) as u32)) as u32)))

    ((*__param_d).state = ((__local_cutf8_dtab[((((256 as u32) +% ((*__param_d).state as u32)) as u32) +% (__local_type_ as u32))] as u32)))

    return (*__param_d).state


}

pub fn cutf8_isgroup(__param_group: i32, __param_c: u32) -> bool {
    var __local_i: i32

    var __local_n: i32 = _utf8_unicode_groups[__param_group].nr16


    loop {
        var __local__n: i32 = __local_n

        var __local__i: i32 = ((0 as i32))

        var __local__mid: i32 = (((__local__n / 2) as i32))


        var __local__c: u32 = __param_c

        while (__local__n > 0) {
            if ((unsafe *(&raw const (_utf8_unicode_groups[__param_group].r16[(__local__i + __local__mid)]).hi as *const u16)) < (unsafe *(&raw mut __local__c as *mut u32))) {
                (__local__i = __local__i + (__local__mid + 1))

                (__local__n = __local__n - (__local__mid + 1))

                (__local__mid = ((((__local__n * 7) / 8) as i32)))

            } else {
                (__local__n = __local__mid)

                (__local__mid = (((__local__n / 8) as i32)))

            }

        }

        ((unsafe *(&raw mut __local_i as *mut i32)) = __local__i)

        if not (false) {
            break
        }
    }

    var __ci_expr_logic_0: i32 = 0

    if (__local_i < __local_n) {
        (__ci_expr_logic_0 = (if __param_c >= (unsafe _utf8_unicode_groups[__param_group].r16[__local_i]).lo: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:0:read only
unsafe fn cutf8_peek_at(__param_s: *const c_char, __param_offset: i64) -> u32 {
    return cutf8_peek(cutf8_offset(__param_s, __param_offset))

}

fn cutf8_isupper(__param_c: u32) -> bool {
    return ((((if __param_c < 128: ((((if __param_c >= 65: 1 else: 0) as i32) & ((if __param_c <= 90: 1 else: 0) as i32)) as i32) else: ((if cutf8_tolower(__param_c) != __param_c: 1 else: 0) as i32)) != 0) as bool))

}

fn cutf8_islower(__param_c: u32) -> bool {
    return ((((if __param_c < 128: ((((if __param_c >= 97: 1 else: 0) as i32) & ((if __param_c <= 122: 1 else: 0) as i32)) as i32) else: ((if cutf8_toupper(__param_c) != __param_c: 1 else: 0) as i32)) != 0) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cutf8_icmp(__param_s1: *const c_char, __param_s2: *const c_char) -> i32 {
    return cutf8_icmp_sv((csview { buf: __param_s1, size: 9223372036854775807 } as csview), (csview { buf: __param_s2, size: 9223372036854775807 } as csview))

}

fn cutf8_isdigit(__param_c: u32) -> bool {
    return ((((if __param_c < 128: ((((if __param_c >= 48: 1 else: 0) as i32) & ((if __param_c <= 57: 1 else: 0) as i32)) as i32) else: (cutf8_isgroup(U8G_Nd, __param_c) as i32)) != 0) as bool))

}

fn cutf8_isalpha(__param_c: u32) -> bool {
    return ((((if __param_c < 128: ((if isalpha((__param_c as i32)) != 0: 1 else: 0) as i32) else: (cutf8_isgroup(U8G_L, __param_c) as i32)) != 0) as bool))

}

fn cutf8_iscased(__param_c: u32) -> bool {
    if (__param_c < 128) {
        return ((((isalpha((__param_c as i32)) != 0)) as bool))
    }

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if (cutf8_toupper(__param_c) != __param_c) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_tolower(__param_c) != __param_c: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if cutf8_isgroup(U8G_Lt, __param_c): 1 else: 0))
    }

    return (((__ci_expr_logic_1 != 0) as bool))


}

fn cutf8_isalnum(__param_c: u32) -> bool {
    if (__param_c < 128) {
        return ((((isalnum((__param_c as i32)) != 0)) as bool))
    }

    var __ci_expr_logic_0: i32

    if cutf8_isgroup(U8G_L, __param_c) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Nd, __param_c): 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

fn cutf8_isword(__param_c: u32) -> bool {
    if (__param_c < 128) {
        return ((((((if isalnum((__param_c as i32)) != 0: 1 else: 0) as i32) | ((if __param_c == 95: 1 else: 0) as i32)) != 0) as bool))
    }

    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if cutf8_isgroup(U8G_L, __param_c) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Nd, __param_c): 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if cutf8_isgroup(U8G_Pc, __param_c): 1 else: 0))
    }

    return (((__ci_expr_logic_1 != 0) as bool))


}

fn cutf8_isblank(__param_c: u32) -> bool {
    if (__param_c < 128) {
        return ((((((if __param_c == 32: 1 else: 0) as i32) | ((if __param_c == 9: 1 else: 0) as i32)) != 0) as bool))
    }

    return cutf8_isgroup(U8G_Zs, __param_c)

}

fn cutf8_isspace(__param_c: u32) -> bool {
    if (__param_c < 128) {
        return ((((isspace((__param_c as i32)) != 0)) as bool))
    }

    var __ci_expr_logic_0: i32

    if (((if __param_c == 8232: 1 else: 0) as i32) | ((if __param_c == 8233: 1 else: 0) as i32)) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Zs, __param_c): 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

let Cc_range16: List[URange16] = [URange16 { lo: 0, hi: 31 }, URange16 { lo: 127, hi: 159 }]
let L_range16: List[URange16] = [URange16 { lo: 65, hi: 90 }, URange16 { lo: 97, hi: 122 }, URange16 { lo: 170, hi: 170 }, URange16 { lo: 181, hi: 181 }, URange16 { lo: 186, hi: 186 }, URange16 { lo: 192, hi: 214 }, URange16 { lo: 216, hi: 246 }, URange16 { lo: 248, hi: 705 }, URange16 { lo: 710, hi: 721 }, URange16 { lo: 736, hi: 740 }, URange16 { lo: 748, hi: 748 }, URange16 { lo: 750, hi: 750 }, URange16 { lo: 880, hi: 884 }, URange16 { lo: 886, hi: 887 }, URange16 { lo: 890, hi: 893 }, URange16 { lo: 895, hi: 895 }, URange16 { lo: 902, hi: 902 }, URange16 { lo: 904, hi: 906 }, URange16 { lo: 908, hi: 908 }, URange16 { lo: 910, hi: 929 }, URange16 { lo: 931, hi: 1013 }, URange16 { lo: 1015, hi: 1153 }, URange16 { lo: 1162, hi: 1327 }, URange16 { lo: 1329, hi: 1366 }, URange16 { lo: 1369, hi: 1369 }, URange16 { lo: 1376, hi: 1416 }, URange16 { lo: 1488, hi: 1514 }, URange16 { lo: 1519, hi: 1522 }, URange16 { lo: 1568, hi: 1610 }, URange16 { lo: 1646, hi: 1647 }, URange16 { lo: 1649, hi: 1747 }, URange16 { lo: 1749, hi: 1749 }, URange16 { lo: 1765, hi: 1766 }, URange16 { lo: 1774, hi: 1775 }, URange16 { lo: 1786, hi: 1788 }, URange16 { lo: 1791, hi: 1791 }, URange16 { lo: 1808, hi: 1808 }, URange16 { lo: 1810, hi: 1839 }, URange16 { lo: 1869, hi: 1957 }, URange16 { lo: 1969, hi: 1969 }, URange16 { lo: 1994, hi: 2026 }, URange16 { lo: 2036, hi: 2037 }, URange16 { lo: 2042, hi: 2042 }, URange16 { lo: 2048, hi: 2069 }, URange16 { lo: 2074, hi: 2074 }, URange16 { lo: 2084, hi: 2084 }, URange16 { lo: 2088, hi: 2088 }, URange16 { lo: 2112, hi: 2136 }, URange16 { lo: 2144, hi: 2154 }, URange16 { lo: 2160, hi: 2183 }, URange16 { lo: 2185, hi: 2190 }, URange16 { lo: 2208, hi: 2249 }, URange16 { lo: 2308, hi: 2361 }, URange16 { lo: 2365, hi: 2365 }, URange16 { lo: 2384, hi: 2384 }, URange16 { lo: 2392, hi: 2401 }, URange16 { lo: 2417, hi: 2432 }, URange16 { lo: 2437, hi: 2444 }, URange16 { lo: 2447, hi: 2448 }, URange16 { lo: 2451, hi: 2472 }, URange16 { lo: 2474, hi: 2480 }, URange16 { lo: 2482, hi: 2482 }, URange16 { lo: 2486, hi: 2489 }, URange16 { lo: 2493, hi: 2493 }, URange16 { lo: 2510, hi: 2510 }, URange16 { lo: 2524, hi: 2525 }, URange16 { lo: 2527, hi: 2529 }, URange16 { lo: 2544, hi: 2545 }, URange16 { lo: 2556, hi: 2556 }, URange16 { lo: 2565, hi: 2570 }, URange16 { lo: 2575, hi: 2576 }, URange16 { lo: 2579, hi: 2600 }, URange16 { lo: 2602, hi: 2608 }, URange16 { lo: 2610, hi: 2611 }, URange16 { lo: 2613, hi: 2614 }, URange16 { lo: 2616, hi: 2617 }, URange16 { lo: 2649, hi: 2652 }, URange16 { lo: 2654, hi: 2654 }, URange16 { lo: 2674, hi: 2676 }, URange16 { lo: 2693, hi: 2701 }, URange16 { lo: 2703, hi: 2705 }, URange16 { lo: 2707, hi: 2728 }, URange16 { lo: 2730, hi: 2736 }, URange16 { lo: 2738, hi: 2739 }, URange16 { lo: 2741, hi: 2745 }, URange16 { lo: 2749, hi: 2749 }, URange16 { lo: 2768, hi: 2768 }, URange16 { lo: 2784, hi: 2785 }, URange16 { lo: 2809, hi: 2809 }, URange16 { lo: 2821, hi: 2828 }, URange16 { lo: 2831, hi: 2832 }, URange16 { lo: 2835, hi: 2856 }, URange16 { lo: 2858, hi: 2864 }, URange16 { lo: 2866, hi: 2867 }, URange16 { lo: 2869, hi: 2873 }, URange16 { lo: 2877, hi: 2877 }, URange16 { lo: 2908, hi: 2909 }, URange16 { lo: 2911, hi: 2913 }, URange16 { lo: 2929, hi: 2929 }, URange16 { lo: 2947, hi: 2947 }, URange16 { lo: 2949, hi: 2954 }, URange16 { lo: 2958, hi: 2960 }, URange16 { lo: 2962, hi: 2965 }, URange16 { lo: 2969, hi: 2970 }, URange16 { lo: 2972, hi: 2972 }, URange16 { lo: 2974, hi: 2975 }, URange16 { lo: 2979, hi: 2980 }, URange16 { lo: 2984, hi: 2986 }, URange16 { lo: 2990, hi: 3001 }, URange16 { lo: 3024, hi: 3024 }, URange16 { lo: 3077, hi: 3084 }, URange16 { lo: 3086, hi: 3088 }, URange16 { lo: 3090, hi: 3112 }, URange16 { lo: 3114, hi: 3129 }, URange16 { lo: 3133, hi: 3133 }, URange16 { lo: 3160, hi: 3162 }, URange16 { lo: 3165, hi: 3165 }, URange16 { lo: 3168, hi: 3169 }, URange16 { lo: 3200, hi: 3200 }, URange16 { lo: 3205, hi: 3212 }, URange16 { lo: 3214, hi: 3216 }, URange16 { lo: 3218, hi: 3240 }, URange16 { lo: 3242, hi: 3251 }, URange16 { lo: 3253, hi: 3257 }, URange16 { lo: 3261, hi: 3261 }, URange16 { lo: 3293, hi: 3294 }, URange16 { lo: 3296, hi: 3297 }, URange16 { lo: 3313, hi: 3314 }, URange16 { lo: 3332, hi: 3340 }, URange16 { lo: 3342, hi: 3344 }, URange16 { lo: 3346, hi: 3386 }, URange16 { lo: 3389, hi: 3389 }, URange16 { lo: 3406, hi: 3406 }, URange16 { lo: 3412, hi: 3414 }, URange16 { lo: 3423, hi: 3425 }, URange16 { lo: 3450, hi: 3455 }, URange16 { lo: 3461, hi: 3478 }, URange16 { lo: 3482, hi: 3505 }, URange16 { lo: 3507, hi: 3515 }, URange16 { lo: 3517, hi: 3517 }, URange16 { lo: 3520, hi: 3526 }, URange16 { lo: 3585, hi: 3632 }, URange16 { lo: 3634, hi: 3635 }, URange16 { lo: 3648, hi: 3654 }, URange16 { lo: 3713, hi: 3714 }, URange16 { lo: 3716, hi: 3716 }, URange16 { lo: 3718, hi: 3722 }, URange16 { lo: 3724, hi: 3747 }, URange16 { lo: 3749, hi: 3749 }, URange16 { lo: 3751, hi: 3760 }, URange16 { lo: 3762, hi: 3763 }, URange16 { lo: 3773, hi: 3773 }, URange16 { lo: 3776, hi: 3780 }, URange16 { lo: 3782, hi: 3782 }, URange16 { lo: 3804, hi: 3807 }, URange16 { lo: 3840, hi: 3840 }, URange16 { lo: 3904, hi: 3911 }, URange16 { lo: 3913, hi: 3948 }, URange16 { lo: 3976, hi: 3980 }, URange16 { lo: 4096, hi: 4138 }, URange16 { lo: 4159, hi: 4159 }, URange16 { lo: 4176, hi: 4181 }, URange16 { lo: 4186, hi: 4189 }, URange16 { lo: 4193, hi: 4193 }, URange16 { lo: 4197, hi: 4198 }, URange16 { lo: 4206, hi: 4208 }, URange16 { lo: 4213, hi: 4225 }, URange16 { lo: 4238, hi: 4238 }, URange16 { lo: 4256, hi: 4293 }, URange16 { lo: 4295, hi: 4295 }, URange16 { lo: 4301, hi: 4301 }, URange16 { lo: 4304, hi: 4346 }, URange16 { lo: 4348, hi: 4680 }, URange16 { lo: 4682, hi: 4685 }, URange16 { lo: 4688, hi: 4694 }, URange16 { lo: 4696, hi: 4696 }, URange16 { lo: 4698, hi: 4701 }, URange16 { lo: 4704, hi: 4744 }, URange16 { lo: 4746, hi: 4749 }, URange16 { lo: 4752, hi: 4784 }, URange16 { lo: 4786, hi: 4789 }, URange16 { lo: 4792, hi: 4798 }, URange16 { lo: 4800, hi: 4800 }, URange16 { lo: 4802, hi: 4805 }, URange16 { lo: 4808, hi: 4822 }, URange16 { lo: 4824, hi: 4880 }, URange16 { lo: 4882, hi: 4885 }, URange16 { lo: 4888, hi: 4954 }, URange16 { lo: 4992, hi: 5007 }, URange16 { lo: 5024, hi: 5109 }, URange16 { lo: 5112, hi: 5117 }, URange16 { lo: 5121, hi: 5740 }, URange16 { lo: 5743, hi: 5759 }, URange16 { lo: 5761, hi: 5786 }, URange16 { lo: 5792, hi: 5866 }, URange16 { lo: 5873, hi: 5880 }, URange16 { lo: 5888, hi: 5905 }, URange16 { lo: 5919, hi: 5937 }, URange16 { lo: 5952, hi: 5969 }, URange16 { lo: 5984, hi: 5996 }, URange16 { lo: 5998, hi: 6000 }, URange16 { lo: 6016, hi: 6067 }, URange16 { lo: 6103, hi: 6103 }, URange16 { lo: 6108, hi: 6108 }, URange16 { lo: 6176, hi: 6264 }, URange16 { lo: 6272, hi: 6276 }, URange16 { lo: 6279, hi: 6312 }, URange16 { lo: 6314, hi: 6314 }, URange16 { lo: 6320, hi: 6389 }, URange16 { lo: 6400, hi: 6430 }, URange16 { lo: 6480, hi: 6509 }, URange16 { lo: 6512, hi: 6516 }, URange16 { lo: 6528, hi: 6571 }, URange16 { lo: 6576, hi: 6601 }, URange16 { lo: 6656, hi: 6678 }, URange16 { lo: 6688, hi: 6740 }, URange16 { lo: 6823, hi: 6823 }, URange16 { lo: 6917, hi: 6963 }, URange16 { lo: 6981, hi: 6988 }, URange16 { lo: 7043, hi: 7072 }, URange16 { lo: 7086, hi: 7087 }, URange16 { lo: 7098, hi: 7141 }, URange16 { lo: 7168, hi: 7203 }, URange16 { lo: 7245, hi: 7247 }, URange16 { lo: 7258, hi: 7293 }, URange16 { lo: 7296, hi: 7304 }, URange16 { lo: 7312, hi: 7354 }, URange16 { lo: 7357, hi: 7359 }, URange16 { lo: 7401, hi: 7404 }, URange16 { lo: 7406, hi: 7411 }, URange16 { lo: 7413, hi: 7414 }, URange16 { lo: 7418, hi: 7418 }, URange16 { lo: 7424, hi: 7615 }, URange16 { lo: 7680, hi: 7957 }, URange16 { lo: 7960, hi: 7965 }, URange16 { lo: 7968, hi: 8005 }, URange16 { lo: 8008, hi: 8013 }, URange16 { lo: 8016, hi: 8023 }, URange16 { lo: 8025, hi: 8025 }, URange16 { lo: 8027, hi: 8027 }, URange16 { lo: 8029, hi: 8029 }, URange16 { lo: 8031, hi: 8061 }, URange16 { lo: 8064, hi: 8116 }, URange16 { lo: 8118, hi: 8124 }, URange16 { lo: 8126, hi: 8126 }, URange16 { lo: 8130, hi: 8132 }, URange16 { lo: 8134, hi: 8140 }, URange16 { lo: 8144, hi: 8147 }, URange16 { lo: 8150, hi: 8155 }, URange16 { lo: 8160, hi: 8172 }, URange16 { lo: 8178, hi: 8180 }, URange16 { lo: 8182, hi: 8188 }, URange16 { lo: 8305, hi: 8305 }, URange16 { lo: 8319, hi: 8319 }, URange16 { lo: 8336, hi: 8348 }, URange16 { lo: 8450, hi: 8450 }, URange16 { lo: 8455, hi: 8455 }, URange16 { lo: 8458, hi: 8467 }, URange16 { lo: 8469, hi: 8469 }, URange16 { lo: 8473, hi: 8477 }, URange16 { lo: 8484, hi: 8484 }, URange16 { lo: 8486, hi: 8486 }, URange16 { lo: 8488, hi: 8488 }, URange16 { lo: 8490, hi: 8493 }, URange16 { lo: 8495, hi: 8505 }, URange16 { lo: 8508, hi: 8511 }, URange16 { lo: 8517, hi: 8521 }, URange16 { lo: 8526, hi: 8526 }, URange16 { lo: 8579, hi: 8580 }, URange16 { lo: 11264, hi: 11492 }, URange16 { lo: 11499, hi: 11502 }, URange16 { lo: 11506, hi: 11507 }, URange16 { lo: 11520, hi: 11557 }, URange16 { lo: 11559, hi: 11559 }, URange16 { lo: 11565, hi: 11565 }, URange16 { lo: 11568, hi: 11623 }, URange16 { lo: 11631, hi: 11631 }, URange16 { lo: 11648, hi: 11670 }, URange16 { lo: 11680, hi: 11686 }, URange16 { lo: 11688, hi: 11694 }, URange16 { lo: 11696, hi: 11702 }, URange16 { lo: 11704, hi: 11710 }, URange16 { lo: 11712, hi: 11718 }, URange16 { lo: 11720, hi: 11726 }, URange16 { lo: 11728, hi: 11734 }, URange16 { lo: 11736, hi: 11742 }, URange16 { lo: 11823, hi: 11823 }, URange16 { lo: 12293, hi: 12294 }, URange16 { lo: 12337, hi: 12341 }, URange16 { lo: 12347, hi: 12348 }, URange16 { lo: 12353, hi: 12438 }, URange16 { lo: 12445, hi: 12447 }, URange16 { lo: 12449, hi: 12538 }, URange16 { lo: 12540, hi: 12543 }, URange16 { lo: 12549, hi: 12591 }, URange16 { lo: 12593, hi: 12686 }, URange16 { lo: 12704, hi: 12735 }, URange16 { lo: 12784, hi: 12799 }, URange16 { lo: 13312, hi: 19903 }, URange16 { lo: 19968, hi: 42124 }, URange16 { lo: 42192, hi: 42237 }, URange16 { lo: 42240, hi: 42508 }, URange16 { lo: 42512, hi: 42527 }, URange16 { lo: 42538, hi: 42539 }, URange16 { lo: 42560, hi: 42606 }, URange16 { lo: 42623, hi: 42653 }, URange16 { lo: 42656, hi: 42725 }, URange16 { lo: 42775, hi: 42783 }, URange16 { lo: 42786, hi: 42888 }, URange16 { lo: 42891, hi: 42954 }, URange16 { lo: 42960, hi: 42961 }, URange16 { lo: 42963, hi: 42963 }, URange16 { lo: 42965, hi: 42969 }, URange16 { lo: 42994, hi: 43009 }, URange16 { lo: 43011, hi: 43013 }, URange16 { lo: 43015, hi: 43018 }, URange16 { lo: 43020, hi: 43042 }, URange16 { lo: 43072, hi: 43123 }, URange16 { lo: 43138, hi: 43187 }, URange16 { lo: 43250, hi: 43255 }, URange16 { lo: 43259, hi: 43259 }, URange16 { lo: 43261, hi: 43262 }, URange16 { lo: 43274, hi: 43301 }, URange16 { lo: 43312, hi: 43334 }, URange16 { lo: 43360, hi: 43388 }, URange16 { lo: 43396, hi: 43442 }, URange16 { lo: 43471, hi: 43471 }, URange16 { lo: 43488, hi: 43492 }, URange16 { lo: 43494, hi: 43503 }, URange16 { lo: 43514, hi: 43518 }, URange16 { lo: 43520, hi: 43560 }, URange16 { lo: 43584, hi: 43586 }, URange16 { lo: 43588, hi: 43595 }, URange16 { lo: 43616, hi: 43638 }, URange16 { lo: 43642, hi: 43642 }, URange16 { lo: 43646, hi: 43695 }, URange16 { lo: 43697, hi: 43697 }, URange16 { lo: 43701, hi: 43702 }, URange16 { lo: 43705, hi: 43709 }, URange16 { lo: 43712, hi: 43712 }, URange16 { lo: 43714, hi: 43714 }, URange16 { lo: 43739, hi: 43741 }, URange16 { lo: 43744, hi: 43754 }, URange16 { lo: 43762, hi: 43764 }, URange16 { lo: 43777, hi: 43782 }, URange16 { lo: 43785, hi: 43790 }, URange16 { lo: 43793, hi: 43798 }, URange16 { lo: 43808, hi: 43814 }, URange16 { lo: 43816, hi: 43822 }, URange16 { lo: 43824, hi: 43866 }, URange16 { lo: 43868, hi: 43881 }, URange16 { lo: 43888, hi: 44002 }, URange16 { lo: 44032, hi: 55203 }, URange16 { lo: 55216, hi: 55238 }, URange16 { lo: 55243, hi: 55291 }, URange16 { lo: 63744, hi: 64109 }, URange16 { lo: 64112, hi: 64217 }, URange16 { lo: 64256, hi: 64262 }, URange16 { lo: 64275, hi: 64279 }, URange16 { lo: 64285, hi: 64285 }, URange16 { lo: 64287, hi: 64296 }, URange16 { lo: 64298, hi: 64310 }, URange16 { lo: 64312, hi: 64316 }, URange16 { lo: 64318, hi: 64318 }, URange16 { lo: 64320, hi: 64321 }, URange16 { lo: 64323, hi: 64324 }, URange16 { lo: 64326, hi: 64433 }, URange16 { lo: 64467, hi: 64829 }, URange16 { lo: 64848, hi: 64911 }, URange16 { lo: 64914, hi: 64967 }, URange16 { lo: 65008, hi: 65019 }, URange16 { lo: 65136, hi: 65140 }, URange16 { lo: 65142, hi: 65276 }, URange16 { lo: 65313, hi: 65338 }, URange16 { lo: 65345, hi: 65370 }, URange16 { lo: 65382, hi: 65470 }, URange16 { lo: 65474, hi: 65479 }, URange16 { lo: 65482, hi: 65487 }, URange16 { lo: 65490, hi: 65495 }, URange16 { lo: 65498, hi: 65500 }]
let Lm_range16: List[URange16] = [URange16 { lo: 688, hi: 705 }, URange16 { lo: 710, hi: 721 }, URange16 { lo: 736, hi: 740 }, URange16 { lo: 748, hi: 748 }, URange16 { lo: 750, hi: 750 }, URange16 { lo: 884, hi: 884 }, URange16 { lo: 890, hi: 890 }, URange16 { lo: 1369, hi: 1369 }, URange16 { lo: 1600, hi: 1600 }, URange16 { lo: 1765, hi: 1766 }, URange16 { lo: 2036, hi: 2037 }, URange16 { lo: 2042, hi: 2042 }, URange16 { lo: 2074, hi: 2074 }, URange16 { lo: 2084, hi: 2084 }, URange16 { lo: 2088, hi: 2088 }, URange16 { lo: 2249, hi: 2249 }, URange16 { lo: 2417, hi: 2417 }, URange16 { lo: 3654, hi: 3654 }, URange16 { lo: 3782, hi: 3782 }, URange16 { lo: 4348, hi: 4348 }, URange16 { lo: 6103, hi: 6103 }, URange16 { lo: 6211, hi: 6211 }, URange16 { lo: 6823, hi: 6823 }, URange16 { lo: 7288, hi: 7293 }, URange16 { lo: 7468, hi: 7530 }, URange16 { lo: 7544, hi: 7544 }, URange16 { lo: 7579, hi: 7615 }, URange16 { lo: 8305, hi: 8305 }, URange16 { lo: 8319, hi: 8319 }, URange16 { lo: 8336, hi: 8348 }, URange16 { lo: 11388, hi: 11389 }, URange16 { lo: 11631, hi: 11631 }, URange16 { lo: 11823, hi: 11823 }, URange16 { lo: 12293, hi: 12293 }, URange16 { lo: 12337, hi: 12341 }, URange16 { lo: 12347, hi: 12347 }, URange16 { lo: 12445, hi: 12446 }, URange16 { lo: 12540, hi: 12542 }, URange16 { lo: 40981, hi: 40981 }, URange16 { lo: 42232, hi: 42237 }, URange16 { lo: 42508, hi: 42508 }, URange16 { lo: 42623, hi: 42623 }, URange16 { lo: 42652, hi: 42653 }, URange16 { lo: 42775, hi: 42783 }, URange16 { lo: 42864, hi: 42864 }, URange16 { lo: 42888, hi: 42888 }, URange16 { lo: 42994, hi: 42996 }, URange16 { lo: 43000, hi: 43001 }, URange16 { lo: 43471, hi: 43471 }, URange16 { lo: 43494, hi: 43494 }, URange16 { lo: 43632, hi: 43632 }, URange16 { lo: 43741, hi: 43741 }, URange16 { lo: 43763, hi: 43764 }, URange16 { lo: 43868, hi: 43871 }, URange16 { lo: 43881, hi: 43881 }, URange16 { lo: 65392, hi: 65392 }, URange16 { lo: 65438, hi: 65439 }]
let Lt_range16: List[URange16] = [URange16 { lo: 453, hi: 453 }, URange16 { lo: 456, hi: 456 }, URange16 { lo: 459, hi: 459 }, URange16 { lo: 498, hi: 498 }, URange16 { lo: 8072, hi: 8079 }, URange16 { lo: 8088, hi: 8095 }, URange16 { lo: 8104, hi: 8111 }, URange16 { lo: 8124, hi: 8124 }, URange16 { lo: 8140, hi: 8140 }, URange16 { lo: 8188, hi: 8188 }]
let Nd_range16: List[URange16] = [URange16 { lo: 48, hi: 57 }, URange16 { lo: 1632, hi: 1641 }, URange16 { lo: 1776, hi: 1785 }, URange16 { lo: 1984, hi: 1993 }, URange16 { lo: 2406, hi: 2415 }, URange16 { lo: 2534, hi: 2543 }, URange16 { lo: 2662, hi: 2671 }, URange16 { lo: 2790, hi: 2799 }, URange16 { lo: 2918, hi: 2927 }, URange16 { lo: 3046, hi: 3055 }, URange16 { lo: 3174, hi: 3183 }, URange16 { lo: 3302, hi: 3311 }, URange16 { lo: 3430, hi: 3439 }, URange16 { lo: 3558, hi: 3567 }, URange16 { lo: 3664, hi: 3673 }, URange16 { lo: 3792, hi: 3801 }, URange16 { lo: 3872, hi: 3881 }, URange16 { lo: 4160, hi: 4169 }, URange16 { lo: 4240, hi: 4249 }, URange16 { lo: 6112, hi: 6121 }, URange16 { lo: 6160, hi: 6169 }, URange16 { lo: 6470, hi: 6479 }, URange16 { lo: 6608, hi: 6617 }, URange16 { lo: 6784, hi: 6793 }, URange16 { lo: 6800, hi: 6809 }, URange16 { lo: 6992, hi: 7001 }, URange16 { lo: 7088, hi: 7097 }, URange16 { lo: 7232, hi: 7241 }, URange16 { lo: 7248, hi: 7257 }, URange16 { lo: 42528, hi: 42537 }, URange16 { lo: 43216, hi: 43225 }, URange16 { lo: 43264, hi: 43273 }, URange16 { lo: 43472, hi: 43481 }, URange16 { lo: 43504, hi: 43513 }, URange16 { lo: 43600, hi: 43609 }, URange16 { lo: 44016, hi: 44025 }, URange16 { lo: 65296, hi: 65305 }]
let Nl_range16: List[URange16] = [URange16 { lo: 5870, hi: 5872 }, URange16 { lo: 8544, hi: 8578 }, URange16 { lo: 8581, hi: 8584 }, URange16 { lo: 12295, hi: 12295 }, URange16 { lo: 12321, hi: 12329 }, URange16 { lo: 12344, hi: 12346 }, URange16 { lo: 42726, hi: 42735 }]
let No_range16: List[URange16] = [URange16 { lo: 178, hi: 179 }, URange16 { lo: 185, hi: 185 }, URange16 { lo: 188, hi: 190 }, URange16 { lo: 2548, hi: 2553 }, URange16 { lo: 2930, hi: 2935 }, URange16 { lo: 3056, hi: 3058 }, URange16 { lo: 3192, hi: 3198 }, URange16 { lo: 3416, hi: 3422 }, URange16 { lo: 3440, hi: 3448 }, URange16 { lo: 3882, hi: 3891 }, URange16 { lo: 4969, hi: 4988 }, URange16 { lo: 6128, hi: 6137 }, URange16 { lo: 6618, hi: 6618 }, URange16 { lo: 8304, hi: 8304 }, URange16 { lo: 8308, hi: 8313 }, URange16 { lo: 8320, hi: 8329 }, URange16 { lo: 8528, hi: 8543 }, URange16 { lo: 8585, hi: 8585 }, URange16 { lo: 9312, hi: 9371 }, URange16 { lo: 9450, hi: 9471 }, URange16 { lo: 10102, hi: 10131 }, URange16 { lo: 11517, hi: 11517 }, URange16 { lo: 12690, hi: 12693 }, URange16 { lo: 12832, hi: 12841 }, URange16 { lo: 12872, hi: 12879 }, URange16 { lo: 12881, hi: 12895 }, URange16 { lo: 12928, hi: 12937 }, URange16 { lo: 12977, hi: 12991 }, URange16 { lo: 43056, hi: 43061 }]
let P_range16: List[URange16] = [URange16 { lo: 33, hi: 35 }, URange16 { lo: 37, hi: 42 }, URange16 { lo: 44, hi: 47 }, URange16 { lo: 58, hi: 59 }, URange16 { lo: 63, hi: 64 }, URange16 { lo: 91, hi: 93 }, URange16 { lo: 95, hi: 95 }, URange16 { lo: 123, hi: 123 }, URange16 { lo: 125, hi: 125 }, URange16 { lo: 161, hi: 161 }, URange16 { lo: 167, hi: 167 }, URange16 { lo: 171, hi: 171 }, URange16 { lo: 182, hi: 183 }, URange16 { lo: 187, hi: 187 }, URange16 { lo: 191, hi: 191 }, URange16 { lo: 894, hi: 894 }, URange16 { lo: 903, hi: 903 }, URange16 { lo: 1370, hi: 1375 }, URange16 { lo: 1417, hi: 1418 }, URange16 { lo: 1470, hi: 1470 }, URange16 { lo: 1472, hi: 1472 }, URange16 { lo: 1475, hi: 1475 }, URange16 { lo: 1478, hi: 1478 }, URange16 { lo: 1523, hi: 1524 }, URange16 { lo: 1545, hi: 1546 }, URange16 { lo: 1548, hi: 1549 }, URange16 { lo: 1563, hi: 1563 }, URange16 { lo: 1565, hi: 1567 }, URange16 { lo: 1642, hi: 1645 }, URange16 { lo: 1748, hi: 1748 }, URange16 { lo: 1792, hi: 1805 }, URange16 { lo: 2039, hi: 2041 }, URange16 { lo: 2096, hi: 2110 }, URange16 { lo: 2142, hi: 2142 }, URange16 { lo: 2404, hi: 2405 }, URange16 { lo: 2416, hi: 2416 }, URange16 { lo: 2557, hi: 2557 }, URange16 { lo: 2678, hi: 2678 }, URange16 { lo: 2800, hi: 2800 }, URange16 { lo: 3191, hi: 3191 }, URange16 { lo: 3204, hi: 3204 }, URange16 { lo: 3572, hi: 3572 }, URange16 { lo: 3663, hi: 3663 }, URange16 { lo: 3674, hi: 3675 }, URange16 { lo: 3844, hi: 3858 }, URange16 { lo: 3860, hi: 3860 }, URange16 { lo: 3898, hi: 3901 }, URange16 { lo: 3973, hi: 3973 }, URange16 { lo: 4048, hi: 4052 }, URange16 { lo: 4057, hi: 4058 }, URange16 { lo: 4170, hi: 4175 }, URange16 { lo: 4347, hi: 4347 }, URange16 { lo: 4960, hi: 4968 }, URange16 { lo: 5120, hi: 5120 }, URange16 { lo: 5742, hi: 5742 }, URange16 { lo: 5787, hi: 5788 }, URange16 { lo: 5867, hi: 5869 }, URange16 { lo: 5941, hi: 5942 }, URange16 { lo: 6100, hi: 6102 }, URange16 { lo: 6104, hi: 6106 }, URange16 { lo: 6144, hi: 6154 }, URange16 { lo: 6468, hi: 6469 }, URange16 { lo: 6686, hi: 6687 }, URange16 { lo: 6816, hi: 6822 }, URange16 { lo: 6824, hi: 6829 }, URange16 { lo: 7002, hi: 7008 }, URange16 { lo: 7037, hi: 7038 }, URange16 { lo: 7164, hi: 7167 }, URange16 { lo: 7227, hi: 7231 }, URange16 { lo: 7294, hi: 7295 }, URange16 { lo: 7360, hi: 7367 }, URange16 { lo: 7379, hi: 7379 }, URange16 { lo: 8208, hi: 8231 }, URange16 { lo: 8240, hi: 8259 }, URange16 { lo: 8261, hi: 8273 }, URange16 { lo: 8275, hi: 8286 }, URange16 { lo: 8317, hi: 8318 }, URange16 { lo: 8333, hi: 8334 }, URange16 { lo: 8968, hi: 8971 }, URange16 { lo: 9001, hi: 9002 }, URange16 { lo: 10088, hi: 10101 }, URange16 { lo: 10181, hi: 10182 }, URange16 { lo: 10214, hi: 10223 }, URange16 { lo: 10627, hi: 10648 }, URange16 { lo: 10712, hi: 10715 }, URange16 { lo: 10748, hi: 10749 }, URange16 { lo: 11513, hi: 11516 }, URange16 { lo: 11518, hi: 11519 }, URange16 { lo: 11632, hi: 11632 }, URange16 { lo: 11776, hi: 11822 }, URange16 { lo: 11824, hi: 11855 }, URange16 { lo: 11858, hi: 11869 }, URange16 { lo: 12289, hi: 12291 }, URange16 { lo: 12296, hi: 12305 }, URange16 { lo: 12308, hi: 12319 }, URange16 { lo: 12336, hi: 12336 }, URange16 { lo: 12349, hi: 12349 }, URange16 { lo: 12448, hi: 12448 }, URange16 { lo: 12539, hi: 12539 }, URange16 { lo: 42238, hi: 42239 }, URange16 { lo: 42509, hi: 42511 }, URange16 { lo: 42611, hi: 42611 }, URange16 { lo: 42622, hi: 42622 }, URange16 { lo: 42738, hi: 42743 }, URange16 { lo: 43124, hi: 43127 }, URange16 { lo: 43214, hi: 43215 }, URange16 { lo: 43256, hi: 43258 }, URange16 { lo: 43260, hi: 43260 }, URange16 { lo: 43310, hi: 43311 }, URange16 { lo: 43359, hi: 43359 }, URange16 { lo: 43457, hi: 43469 }, URange16 { lo: 43486, hi: 43487 }, URange16 { lo: 43612, hi: 43615 }, URange16 { lo: 43742, hi: 43743 }, URange16 { lo: 43760, hi: 43761 }, URange16 { lo: 44011, hi: 44011 }, URange16 { lo: 64830, hi: 64831 }, URange16 { lo: 65040, hi: 65049 }, URange16 { lo: 65072, hi: 65106 }, URange16 { lo: 65108, hi: 65121 }, URange16 { lo: 65123, hi: 65123 }, URange16 { lo: 65128, hi: 65128 }, URange16 { lo: 65130, hi: 65131 }, URange16 { lo: 65281, hi: 65283 }, URange16 { lo: 65285, hi: 65290 }, URange16 { lo: 65292, hi: 65295 }, URange16 { lo: 65306, hi: 65307 }, URange16 { lo: 65311, hi: 65312 }, URange16 { lo: 65339, hi: 65341 }, URange16 { lo: 65343, hi: 65343 }, URange16 { lo: 65371, hi: 65371 }, URange16 { lo: 65373, hi: 65373 }, URange16 { lo: 65375, hi: 65381 }]
let Pc_range16: List[URange16] = [URange16 { lo: 95, hi: 95 }, URange16 { lo: 8255, hi: 8256 }, URange16 { lo: 8276, hi: 8276 }, URange16 { lo: 65075, hi: 65076 }, URange16 { lo: 65101, hi: 65103 }, URange16 { lo: 65343, hi: 65343 }]
let Pd_range16: List[URange16] = [URange16 { lo: 45, hi: 45 }, URange16 { lo: 1418, hi: 1418 }, URange16 { lo: 1470, hi: 1470 }, URange16 { lo: 5120, hi: 5120 }, URange16 { lo: 6150, hi: 6150 }, URange16 { lo: 8208, hi: 8213 }, URange16 { lo: 11799, hi: 11799 }, URange16 { lo: 11802, hi: 11802 }, URange16 { lo: 11834, hi: 11835 }, URange16 { lo: 11840, hi: 11840 }, URange16 { lo: 11869, hi: 11869 }, URange16 { lo: 12316, hi: 12316 }, URange16 { lo: 12336, hi: 12336 }, URange16 { lo: 12448, hi: 12448 }, URange16 { lo: 65073, hi: 65074 }, URange16 { lo: 65112, hi: 65112 }, URange16 { lo: 65123, hi: 65123 }, URange16 { lo: 65293, hi: 65293 }]
let Pe_range16: List[URange16] = [URange16 { lo: 41, hi: 41 }, URange16 { lo: 93, hi: 93 }, URange16 { lo: 125, hi: 125 }, URange16 { lo: 3899, hi: 3899 }, URange16 { lo: 3901, hi: 3901 }, URange16 { lo: 5788, hi: 5788 }, URange16 { lo: 8262, hi: 8262 }, URange16 { lo: 8318, hi: 8318 }, URange16 { lo: 8334, hi: 8334 }, URange16 { lo: 8969, hi: 8969 }, URange16 { lo: 8971, hi: 8971 }, URange16 { lo: 9002, hi: 9002 }, URange16 { lo: 10089, hi: 10089 }, URange16 { lo: 10091, hi: 10091 }, URange16 { lo: 10093, hi: 10093 }, URange16 { lo: 10095, hi: 10095 }, URange16 { lo: 10097, hi: 10097 }, URange16 { lo: 10099, hi: 10099 }, URange16 { lo: 10101, hi: 10101 }, URange16 { lo: 10182, hi: 10182 }, URange16 { lo: 10215, hi: 10215 }, URange16 { lo: 10217, hi: 10217 }, URange16 { lo: 10219, hi: 10219 }, URange16 { lo: 10221, hi: 10221 }, URange16 { lo: 10223, hi: 10223 }, URange16 { lo: 10628, hi: 10628 }, URange16 { lo: 10630, hi: 10630 }, URange16 { lo: 10632, hi: 10632 }, URange16 { lo: 10634, hi: 10634 }, URange16 { lo: 10636, hi: 10636 }, URange16 { lo: 10638, hi: 10638 }, URange16 { lo: 10640, hi: 10640 }, URange16 { lo: 10642, hi: 10642 }, URange16 { lo: 10644, hi: 10644 }, URange16 { lo: 10646, hi: 10646 }, URange16 { lo: 10648, hi: 10648 }, URange16 { lo: 10713, hi: 10713 }, URange16 { lo: 10715, hi: 10715 }, URange16 { lo: 10749, hi: 10749 }, URange16 { lo: 11811, hi: 11811 }, URange16 { lo: 11813, hi: 11813 }, URange16 { lo: 11815, hi: 11815 }, URange16 { lo: 11817, hi: 11817 }, URange16 { lo: 11862, hi: 11862 }, URange16 { lo: 11864, hi: 11864 }, URange16 { lo: 11866, hi: 11866 }, URange16 { lo: 11868, hi: 11868 }, URange16 { lo: 12297, hi: 12297 }, URange16 { lo: 12299, hi: 12299 }, URange16 { lo: 12301, hi: 12301 }, URange16 { lo: 12303, hi: 12303 }, URange16 { lo: 12305, hi: 12305 }, URange16 { lo: 12309, hi: 12309 }, URange16 { lo: 12311, hi: 12311 }, URange16 { lo: 12313, hi: 12313 }, URange16 { lo: 12315, hi: 12315 }, URange16 { lo: 12318, hi: 12319 }, URange16 { lo: 64830, hi: 64830 }, URange16 { lo: 65048, hi: 65048 }, URange16 { lo: 65078, hi: 65078 }, URange16 { lo: 65080, hi: 65080 }, URange16 { lo: 65082, hi: 65082 }, URange16 { lo: 65084, hi: 65084 }, URange16 { lo: 65086, hi: 65086 }, URange16 { lo: 65088, hi: 65088 }, URange16 { lo: 65090, hi: 65090 }, URange16 { lo: 65092, hi: 65092 }, URange16 { lo: 65096, hi: 65096 }, URange16 { lo: 65114, hi: 65114 }, URange16 { lo: 65116, hi: 65116 }, URange16 { lo: 65118, hi: 65118 }, URange16 { lo: 65289, hi: 65289 }, URange16 { lo: 65341, hi: 65341 }, URange16 { lo: 65373, hi: 65373 }, URange16 { lo: 65376, hi: 65376 }, URange16 { lo: 65379, hi: 65379 }]
let Pf_range16: List[URange16] = [URange16 { lo: 187, hi: 187 }, URange16 { lo: 8217, hi: 8217 }, URange16 { lo: 8221, hi: 8221 }, URange16 { lo: 8250, hi: 8250 }, URange16 { lo: 11779, hi: 11779 }, URange16 { lo: 11781, hi: 11781 }, URange16 { lo: 11786, hi: 11786 }, URange16 { lo: 11789, hi: 11789 }, URange16 { lo: 11805, hi: 11805 }, URange16 { lo: 11809, hi: 11809 }]
let Pi_range16: List[URange16] = [URange16 { lo: 171, hi: 171 }, URange16 { lo: 8216, hi: 8216 }, URange16 { lo: 8219, hi: 8220 }, URange16 { lo: 8223, hi: 8223 }, URange16 { lo: 8249, hi: 8249 }, URange16 { lo: 11778, hi: 11778 }, URange16 { lo: 11780, hi: 11780 }, URange16 { lo: 11785, hi: 11785 }, URange16 { lo: 11788, hi: 11788 }, URange16 { lo: 11804, hi: 11804 }, URange16 { lo: 11808, hi: 11808 }]
let Ps_range16: List[URange16] = [URange16 { lo: 40, hi: 40 }, URange16 { lo: 91, hi: 91 }, URange16 { lo: 123, hi: 123 }, URange16 { lo: 3898, hi: 3898 }, URange16 { lo: 3900, hi: 3900 }, URange16 { lo: 5787, hi: 5787 }, URange16 { lo: 8218, hi: 8218 }, URange16 { lo: 8222, hi: 8222 }, URange16 { lo: 8261, hi: 8261 }, URange16 { lo: 8317, hi: 8317 }, URange16 { lo: 8333, hi: 8333 }, URange16 { lo: 8968, hi: 8968 }, URange16 { lo: 8970, hi: 8970 }, URange16 { lo: 9001, hi: 9001 }, URange16 { lo: 10088, hi: 10088 }, URange16 { lo: 10090, hi: 10090 }, URange16 { lo: 10092, hi: 10092 }, URange16 { lo: 10094, hi: 10094 }, URange16 { lo: 10096, hi: 10096 }, URange16 { lo: 10098, hi: 10098 }, URange16 { lo: 10100, hi: 10100 }, URange16 { lo: 10181, hi: 10181 }, URange16 { lo: 10214, hi: 10214 }, URange16 { lo: 10216, hi: 10216 }, URange16 { lo: 10218, hi: 10218 }, URange16 { lo: 10220, hi: 10220 }, URange16 { lo: 10222, hi: 10222 }, URange16 { lo: 10627, hi: 10627 }, URange16 { lo: 10629, hi: 10629 }, URange16 { lo: 10631, hi: 10631 }, URange16 { lo: 10633, hi: 10633 }, URange16 { lo: 10635, hi: 10635 }, URange16 { lo: 10637, hi: 10637 }, URange16 { lo: 10639, hi: 10639 }, URange16 { lo: 10641, hi: 10641 }, URange16 { lo: 10643, hi: 10643 }, URange16 { lo: 10645, hi: 10645 }, URange16 { lo: 10647, hi: 10647 }, URange16 { lo: 10712, hi: 10712 }, URange16 { lo: 10714, hi: 10714 }, URange16 { lo: 10748, hi: 10748 }, URange16 { lo: 11810, hi: 11810 }, URange16 { lo: 11812, hi: 11812 }, URange16 { lo: 11814, hi: 11814 }, URange16 { lo: 11816, hi: 11816 }, URange16 { lo: 11842, hi: 11842 }, URange16 { lo: 11861, hi: 11861 }, URange16 { lo: 11863, hi: 11863 }, URange16 { lo: 11865, hi: 11865 }, URange16 { lo: 11867, hi: 11867 }, URange16 { lo: 12296, hi: 12296 }, URange16 { lo: 12298, hi: 12298 }, URange16 { lo: 12300, hi: 12300 }, URange16 { lo: 12302, hi: 12302 }, URange16 { lo: 12304, hi: 12304 }, URange16 { lo: 12308, hi: 12308 }, URange16 { lo: 12310, hi: 12310 }, URange16 { lo: 12312, hi: 12312 }, URange16 { lo: 12314, hi: 12314 }, URange16 { lo: 12317, hi: 12317 }, URange16 { lo: 64831, hi: 64831 }, URange16 { lo: 65047, hi: 65047 }, URange16 { lo: 65077, hi: 65077 }, URange16 { lo: 65079, hi: 65079 }, URange16 { lo: 65081, hi: 65081 }, URange16 { lo: 65083, hi: 65083 }, URange16 { lo: 65085, hi: 65085 }, URange16 { lo: 65087, hi: 65087 }, URange16 { lo: 65089, hi: 65089 }, URange16 { lo: 65091, hi: 65091 }, URange16 { lo: 65095, hi: 65095 }, URange16 { lo: 65113, hi: 65113 }, URange16 { lo: 65115, hi: 65115 }, URange16 { lo: 65117, hi: 65117 }, URange16 { lo: 65288, hi: 65288 }, URange16 { lo: 65339, hi: 65339 }, URange16 { lo: 65371, hi: 65371 }, URange16 { lo: 65375, hi: 65375 }, URange16 { lo: 65378, hi: 65378 }]
let Sc_range16: List[URange16] = [URange16 { lo: 36, hi: 36 }, URange16 { lo: 162, hi: 165 }, URange16 { lo: 1423, hi: 1423 }, URange16 { lo: 1547, hi: 1547 }, URange16 { lo: 2046, hi: 2047 }, URange16 { lo: 2546, hi: 2547 }, URange16 { lo: 2555, hi: 2555 }, URange16 { lo: 2801, hi: 2801 }, URange16 { lo: 3065, hi: 3065 }, URange16 { lo: 3647, hi: 3647 }, URange16 { lo: 6107, hi: 6107 }, URange16 { lo: 8352, hi: 8384 }, URange16 { lo: 43064, hi: 43064 }, URange16 { lo: 65020, hi: 65020 }, URange16 { lo: 65129, hi: 65129 }, URange16 { lo: 65284, hi: 65284 }, URange16 { lo: 65504, hi: 65505 }, URange16 { lo: 65509, hi: 65510 }]
let Sk_range16: List[URange16] = [URange16 { lo: 94, hi: 94 }, URange16 { lo: 96, hi: 96 }, URange16 { lo: 168, hi: 168 }, URange16 { lo: 175, hi: 175 }, URange16 { lo: 180, hi: 180 }, URange16 { lo: 184, hi: 184 }, URange16 { lo: 706, hi: 709 }, URange16 { lo: 722, hi: 735 }, URange16 { lo: 741, hi: 747 }, URange16 { lo: 749, hi: 749 }, URange16 { lo: 751, hi: 767 }, URange16 { lo: 885, hi: 885 }, URange16 { lo: 900, hi: 901 }, URange16 { lo: 2184, hi: 2184 }, URange16 { lo: 8125, hi: 8125 }, URange16 { lo: 8127, hi: 8129 }, URange16 { lo: 8141, hi: 8143 }, URange16 { lo: 8157, hi: 8159 }, URange16 { lo: 8173, hi: 8175 }, URange16 { lo: 8189, hi: 8190 }, URange16 { lo: 12443, hi: 12444 }, URange16 { lo: 42752, hi: 42774 }, URange16 { lo: 42784, hi: 42785 }, URange16 { lo: 42889, hi: 42890 }, URange16 { lo: 43867, hi: 43867 }, URange16 { lo: 43882, hi: 43883 }, URange16 { lo: 64434, hi: 64450 }, URange16 { lo: 65342, hi: 65342 }, URange16 { lo: 65344, hi: 65344 }, URange16 { lo: 65507, hi: 65507 }]
let Sm_range16: List[URange16] = [URange16 { lo: 43, hi: 43 }, URange16 { lo: 60, hi: 62 }, URange16 { lo: 124, hi: 124 }, URange16 { lo: 126, hi: 126 }, URange16 { lo: 172, hi: 172 }, URange16 { lo: 177, hi: 177 }, URange16 { lo: 215, hi: 215 }, URange16 { lo: 247, hi: 247 }, URange16 { lo: 1014, hi: 1014 }, URange16 { lo: 1542, hi: 1544 }, URange16 { lo: 8260, hi: 8260 }, URange16 { lo: 8274, hi: 8274 }, URange16 { lo: 8314, hi: 8316 }, URange16 { lo: 8330, hi: 8332 }, URange16 { lo: 8472, hi: 8472 }, URange16 { lo: 8512, hi: 8516 }, URange16 { lo: 8523, hi: 8523 }, URange16 { lo: 8592, hi: 8596 }, URange16 { lo: 8602, hi: 8603 }, URange16 { lo: 8608, hi: 8608 }, URange16 { lo: 8611, hi: 8611 }, URange16 { lo: 8614, hi: 8614 }, URange16 { lo: 8622, hi: 8622 }, URange16 { lo: 8654, hi: 8655 }, URange16 { lo: 8658, hi: 8658 }, URange16 { lo: 8660, hi: 8660 }, URange16 { lo: 8692, hi: 8959 }, URange16 { lo: 8992, hi: 8993 }, URange16 { lo: 9084, hi: 9084 }, URange16 { lo: 9115, hi: 9139 }, URange16 { lo: 9180, hi: 9185 }, URange16 { lo: 9655, hi: 9655 }, URange16 { lo: 9665, hi: 9665 }, URange16 { lo: 9720, hi: 9727 }, URange16 { lo: 9839, hi: 9839 }, URange16 { lo: 10176, hi: 10180 }, URange16 { lo: 10183, hi: 10213 }, URange16 { lo: 10224, hi: 10239 }, URange16 { lo: 10496, hi: 10626 }, URange16 { lo: 10649, hi: 10711 }, URange16 { lo: 10716, hi: 10747 }, URange16 { lo: 10750, hi: 11007 }, URange16 { lo: 11056, hi: 11076 }, URange16 { lo: 11079, hi: 11084 }, URange16 { lo: 64297, hi: 64297 }, URange16 { lo: 65122, hi: 65122 }, URange16 { lo: 65124, hi: 65126 }, URange16 { lo: 65291, hi: 65291 }, URange16 { lo: 65308, hi: 65310 }, URange16 { lo: 65372, hi: 65372 }, URange16 { lo: 65374, hi: 65374 }, URange16 { lo: 65506, hi: 65506 }, URange16 { lo: 65513, hi: 65516 }]
let Zl_range16: List[URange16] = [URange16 { lo: 8232, hi: 8232 }]
let Zp_range16: List[URange16] = [URange16 { lo: 8233, hi: 8233 }]
let Zs_range16: List[URange16] = [URange16 { lo: 32, hi: 32 }, URange16 { lo: 160, hi: 160 }, URange16 { lo: 5760, hi: 5760 }, URange16 { lo: 8192, hi: 8202 }, URange16 { lo: 8239, hi: 8239 }, URange16 { lo: 8287, hi: 8287 }, URange16 { lo: 12288, hi: 12288 }]
let Arabic_range16: List[URange16] = [URange16 { lo: 1536, hi: 1540 }, URange16 { lo: 1542, hi: 1547 }, URange16 { lo: 1549, hi: 1562 }, URange16 { lo: 1564, hi: 1566 }, URange16 { lo: 1568, hi: 1599 }, URange16 { lo: 1601, hi: 1610 }, URange16 { lo: 1622, hi: 1647 }, URange16 { lo: 1649, hi: 1756 }, URange16 { lo: 1758, hi: 1791 }, URange16 { lo: 1872, hi: 1919 }, URange16 { lo: 2160, hi: 2190 }, URange16 { lo: 2192, hi: 2193 }, URange16 { lo: 2200, hi: 2273 }, URange16 { lo: 2275, hi: 2303 }, URange16 { lo: 64336, hi: 64450 }, URange16 { lo: 64467, hi: 64829 }, URange16 { lo: 64832, hi: 64911 }, URange16 { lo: 64914, hi: 64967 }, URange16 { lo: 64975, hi: 64975 }, URange16 { lo: 65008, hi: 65023 }, URange16 { lo: 65136, hi: 65140 }, URange16 { lo: 65142, hi: 65276 }]
let Bengali_range16: List[URange16] = [URange16 { lo: 2432, hi: 2435 }, URange16 { lo: 2437, hi: 2444 }, URange16 { lo: 2447, hi: 2448 }, URange16 { lo: 2451, hi: 2472 }, URange16 { lo: 2474, hi: 2480 }, URange16 { lo: 2482, hi: 2482 }, URange16 { lo: 2486, hi: 2489 }, URange16 { lo: 2492, hi: 2500 }, URange16 { lo: 2503, hi: 2504 }, URange16 { lo: 2507, hi: 2510 }, URange16 { lo: 2519, hi: 2519 }, URange16 { lo: 2524, hi: 2525 }, URange16 { lo: 2527, hi: 2531 }, URange16 { lo: 2534, hi: 2558 }]
let Cyrillic_range16: List[URange16] = [URange16 { lo: 1024, hi: 1156 }, URange16 { lo: 1159, hi: 1327 }, URange16 { lo: 7296, hi: 7304 }, URange16 { lo: 7467, hi: 7467 }, URange16 { lo: 7544, hi: 7544 }, URange16 { lo: 11744, hi: 11775 }, URange16 { lo: 42560, hi: 42655 }, URange16 { lo: 65070, hi: 65071 }]
let Devanagari_range16: List[URange16] = [URange16 { lo: 2304, hi: 2384 }, URange16 { lo: 2389, hi: 2403 }, URange16 { lo: 2406, hi: 2431 }, URange16 { lo: 43232, hi: 43263 }]
let Georgian_range16: List[URange16] = [URange16 { lo: 4256, hi: 4293 }, URange16 { lo: 4295, hi: 4295 }, URange16 { lo: 4301, hi: 4301 }, URange16 { lo: 4304, hi: 4346 }, URange16 { lo: 4348, hi: 4351 }, URange16 { lo: 7312, hi: 7354 }, URange16 { lo: 7357, hi: 7359 }, URange16 { lo: 11520, hi: 11557 }, URange16 { lo: 11559, hi: 11559 }, URange16 { lo: 11565, hi: 11565 }]
let Greek_range16: List[URange16] = [URange16 { lo: 880, hi: 883 }, URange16 { lo: 885, hi: 887 }, URange16 { lo: 890, hi: 893 }, URange16 { lo: 895, hi: 895 }, URange16 { lo: 900, hi: 900 }, URange16 { lo: 902, hi: 902 }, URange16 { lo: 904, hi: 906 }, URange16 { lo: 908, hi: 908 }, URange16 { lo: 910, hi: 929 }, URange16 { lo: 931, hi: 993 }, URange16 { lo: 1008, hi: 1023 }, URange16 { lo: 7462, hi: 7466 }, URange16 { lo: 7517, hi: 7521 }, URange16 { lo: 7526, hi: 7530 }, URange16 { lo: 7615, hi: 7615 }, URange16 { lo: 7936, hi: 7957 }, URange16 { lo: 7960, hi: 7965 }, URange16 { lo: 7968, hi: 8005 }, URange16 { lo: 8008, hi: 8013 }, URange16 { lo: 8016, hi: 8023 }, URange16 { lo: 8025, hi: 8025 }, URange16 { lo: 8027, hi: 8027 }, URange16 { lo: 8029, hi: 8029 }, URange16 { lo: 8031, hi: 8061 }, URange16 { lo: 8064, hi: 8116 }, URange16 { lo: 8118, hi: 8132 }, URange16 { lo: 8134, hi: 8147 }, URange16 { lo: 8150, hi: 8155 }, URange16 { lo: 8157, hi: 8175 }, URange16 { lo: 8178, hi: 8180 }, URange16 { lo: 8182, hi: 8190 }, URange16 { lo: 8486, hi: 8486 }, URange16 { lo: 43877, hi: 43877 }]
let Han_range16: List[URange16] = [URange16 { lo: 11904, hi: 11929 }, URange16 { lo: 11931, hi: 12019 }, URange16 { lo: 12032, hi: 12245 }, URange16 { lo: 12293, hi: 12293 }, URange16 { lo: 12295, hi: 12295 }, URange16 { lo: 12321, hi: 12329 }, URange16 { lo: 12344, hi: 12347 }, URange16 { lo: 13312, hi: 19903 }, URange16 { lo: 19968, hi: 40959 }, URange16 { lo: 63744, hi: 64109 }, URange16 { lo: 64112, hi: 64217 }]
let Hiragana_range16: List[URange16] = [URange16 { lo: 12353, hi: 12438 }, URange16 { lo: 12445, hi: 12447 }]
let Katakana_range16: List[URange16] = [URange16 { lo: 12449, hi: 12538 }, URange16 { lo: 12541, hi: 12543 }, URange16 { lo: 12784, hi: 12799 }, URange16 { lo: 13008, hi: 13054 }, URange16 { lo: 13056, hi: 13143 }, URange16 { lo: 65382, hi: 65391 }, URange16 { lo: 65393, hi: 65437 }]
let Latin_range16: List[URange16] = [URange16 { lo: 65, hi: 90 }, URange16 { lo: 97, hi: 122 }, URange16 { lo: 170, hi: 170 }, URange16 { lo: 186, hi: 186 }, URange16 { lo: 192, hi: 214 }, URange16 { lo: 216, hi: 246 }, URange16 { lo: 248, hi: 696 }, URange16 { lo: 736, hi: 740 }, URange16 { lo: 7424, hi: 7461 }, URange16 { lo: 7468, hi: 7516 }, URange16 { lo: 7522, hi: 7525 }, URange16 { lo: 7531, hi: 7543 }, URange16 { lo: 7545, hi: 7614 }, URange16 { lo: 7680, hi: 7935 }, URange16 { lo: 8305, hi: 8305 }, URange16 { lo: 8319, hi: 8319 }, URange16 { lo: 8336, hi: 8348 }, URange16 { lo: 8490, hi: 8491 }, URange16 { lo: 8498, hi: 8498 }, URange16 { lo: 8526, hi: 8526 }, URange16 { lo: 8544, hi: 8584 }, URange16 { lo: 11360, hi: 11391 }, URange16 { lo: 42786, hi: 42887 }, URange16 { lo: 42891, hi: 42954 }, URange16 { lo: 42960, hi: 42961 }, URange16 { lo: 42963, hi: 42963 }, URange16 { lo: 42965, hi: 42969 }, URange16 { lo: 42994, hi: 43007 }, URange16 { lo: 43824, hi: 43866 }, URange16 { lo: 43868, hi: 43876 }, URange16 { lo: 43878, hi: 43881 }, URange16 { lo: 64256, hi: 64262 }, URange16 { lo: 65313, hi: 65338 }, URange16 { lo: 65345, hi: 65370 }]
let Thai_range16: List[URange16] = [URange16 { lo: 3585, hi: 3642 }, URange16 { lo: 3648, hi: 3675 }]
let _utf8_unicode_groups: List[UGroup] = [UGroup { r16: (&raw const Cc_range16[0] as *const URange16), nr16: ((Cc_range16.len() as u64) as i32) }, UGroup { r16: (&raw const L_range16[0] as *const URange16), nr16: ((L_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Lm_range16[0] as *const URange16), nr16: ((Lm_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Lt_range16[0] as *const URange16), nr16: ((Lt_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Nd_range16[0] as *const URange16), nr16: ((Nd_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Nl_range16[0] as *const URange16), nr16: ((Nl_range16.len() as u64) as i32) }, UGroup { r16: (&raw const No_range16[0] as *const URange16), nr16: ((No_range16.len() as u64) as i32) }, UGroup { r16: (&raw const P_range16[0] as *const URange16), nr16: ((P_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Pc_range16[0] as *const URange16), nr16: ((Pc_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Pd_range16[0] as *const URange16), nr16: ((Pd_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Pe_range16[0] as *const URange16), nr16: ((Pe_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Pf_range16[0] as *const URange16), nr16: ((Pf_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Pi_range16[0] as *const URange16), nr16: ((Pi_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Ps_range16[0] as *const URange16), nr16: ((Ps_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Sc_range16[0] as *const URange16), nr16: ((Sc_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Sk_range16[0] as *const URange16), nr16: ((Sk_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Sm_range16[0] as *const URange16), nr16: ((Sm_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Zl_range16[0] as *const URange16), nr16: ((Zl_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Zp_range16[0] as *const URange16), nr16: ((Zp_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Zs_range16[0] as *const URange16), nr16: ((Zs_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Arabic_range16[0] as *const URange16), nr16: ((Arabic_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Bengali_range16[0] as *const URange16), nr16: ((Bengali_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Cyrillic_range16[0] as *const URange16), nr16: ((Cyrillic_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Devanagari_range16[0] as *const URange16), nr16: ((Devanagari_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Georgian_range16[0] as *const URange16), nr16: ((Georgian_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Greek_range16[0] as *const URange16), nr16: ((Greek_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Han_range16[0] as *const URange16), nr16: ((Han_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Hiragana_range16[0] as *const URange16), nr16: ((Hiragana_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Katakana_range16[0] as *const URange16), nr16: ((Katakana_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Latin_range16[0] as *const URange16), nr16: ((Latin_range16.len() as u64) as i32) }, UGroup { r16: (&raw const Thai_range16[0] as *const URange16), nr16: ((Thai_range16.len() as u64) as i32) }]
