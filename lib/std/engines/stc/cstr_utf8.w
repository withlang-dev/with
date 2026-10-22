// Migrated from C
use std.stc.defs
use std.stc.utf8_misc
use std.stc.ucd
use std.stc.cstr_core
use std.stc.cstr_misc
use std.stc.cstr_io
use std.libc
use std.option
use std.collections

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

unsafe fn c_hash_str(__param_str_: *const i8) -> c_ulong {
    var __local_msg: *const u8 = ((__param_str_ as *const u8))

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

unsafe fn c_strnstrn(__param_str_: *const i8, __param_slen: c_long, __param_needle: *const i8, __param_nlen: c_long) -> *mut i8 {
    var __local_str_ = __param_str_
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return (((__local_str_ as *mut c_char) as *mut i8))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut i8))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if (*__local_str_) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str_ as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return (((__local_str_ as *mut c_char) as *mut i8))
        }


        (__local_str_ = __local_str_ + 1)

        var __ci_expr_old_0: c_long = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut i8))

}

unsafe fn cutf8_chr_size(__param_s: *const i8) -> c_int {
    return ((((((4837428950035665169 as c_ulonglong) >> (((((((*__param_s) as u8) as c_int) >> (4 as c_uint)) as c_int) << (2 as c_uint)) as c_uint)) as c_ulonglong) & (15 as c_ulonglong)) as c_int))

}

unsafe fn cutf8_count(__param_s: *const i8) -> c_long {
    var __local_s = __param_s
    var __local_size: c_long = ((0 as c_long))

    while ((*__local_s) != 0) {
        (__local_s = __local_s + 1)

        (__local_size = __local_size + (if (((*__local_s) as c_int) & (192 as c_int)) != 128: 1 else: 0))

    }

    return __local_size

}

unsafe fn cutf8_count_n(__param_s: *const i8, __param_nbytes: c_long) -> c_long {
    var __local_s = __param_s
    var __local_nbytes = __param_nbytes
    var __local_size: c_long = ((0 as c_long))

    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_long = __local_nbytes

        (__local_nbytes = __local_nbytes - 1)

        if ((if __ci_expr_old_0 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (*__local_s) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        (__local_s = __local_s + 1)

        (__local_size = __local_size + (if (((*__local_s) as c_int) & (192 as c_int)) != 128: 1 else: 0))

    }

    return __local_size

}

unsafe fn cutf8_at(__param_s: *const i8, __param_u8pos: c_long) -> *const i8 {
    var __local_s = __param_s
    var __local_u8pos = __param_u8pos
    while ((((if __local_u8pos > 0: 1 else: 0) as c_int) & ((if (*__local_s) != 0: 1 else: 0) as c_int)) != 0) {
        (__local_s = __local_s + 1)

        (__local_u8pos = __local_u8pos - (if (((*__local_s) as c_int) & (192 as c_int)) != 128: 1 else: 0))

    }

    if (((if not ((if __local_u8pos == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cutf8_at".ptr, c"utf8_prv.h".ptr, (57 as c_int), c"u8pos == 0".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn cutf8_offset(__param_s: *const i8, __param_u8pos: c_long) -> *const i8 {
    var __local_s = __param_s
    var __local_u8pos = __param_u8pos
    var __local_inc: c_int = ((1 as c_int))

    if ((if __local_u8pos < 0: 1 else: 0) != 0) {
        (__local_u8pos = (((0 - __local_u8pos) as c_long)))

        (__local_inc = ((-1 as c_int)))

    }

    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_u8pos != 0) {
            (__ci_expr_logic_0 = (if (*__local_s) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_s = __local_s + ((__local_inc as c_long) as usize))

        (__local_u8pos = __local_u8pos - (if (((*__local_s) as c_int) & (192 as c_int)) != 128: 1 else: 0))

    }

    if (((if not ((if __local_u8pos == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cutf8_offset".ptr, c"utf8_prv.h".ptr, (66 as c_int), c"u8pos == 0".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn cutf8_to_index(__param_s: *const i8, __param_u8pos: c_long) -> c_long {
    return ((((cutf8_at(__param_s, __param_u8pos) as usize) -% (__param_s as usize)) as c_long) / (sizeof[c_char]() as c_long))

}

unsafe fn cutf8_subview(__param_s: *const i8, __param_u8pos: c_long, __param_u8len: c_long) -> csview {
    var __local_span: csview

    (__local_span.buf = ((cutf8_at(__param_s, __param_u8pos) as *mut c_char)))

    (__local_span.size = ((cutf8_to_index(((*(&raw const __local_span as *const csview)).buf as *const i8), __param_u8len) as c_long)))

    return __local_span

}

unsafe fn cutf8_decode(__param_d: *mut cutf8_decode_t, __param_byte: c_uint) -> c_uint {
    var __local_cutf8_dtab: []u8

    var __local_type_: c_uint = ((__local_cutf8_dtab[__param_byte] as c_uint))

    ((*__param_d).codep = (((if (*__param_d).state != 0: (((((__param_byte as c_uint) & (63 as c_uint)) as c_uint) | ((((*__param_d).codep as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) else: (((((255 as c_uint) >> (__local_type_ as c_uint)) as c_uint) & (__param_byte as c_uint)) as c_uint)) as c_uint)))

    ((*__param_d).state = ((__local_cutf8_dtab[((((256 as c_uint) +% ((*__param_d).state as c_uint)) as c_uint) +% (__local_type_ as c_uint))] as c_uint)))

    return (*__param_d).state


}

pub unsafe fn cutf8_valid(__param_s: *const i8) -> bool {
    var __local_s = __param_s
    var __local_d: cutf8_decode_t = cutf8_decode_t.zeroed()

    while ((((if cutf8_decode((&raw mut __local_d as *mut cutf8_decode_t), (((*__local_s) as u8) as c_uint)) != 12: 1 else: 0) as c_int) & ((if (*__local_s) != 0: 1 else: 0) as c_int)) != 0) {
        (__local_s = __local_s + 1)
    }

    return (((*(&raw const __local_d as *const cutf8_decode_t)).state == 0))

}

pub unsafe fn cutf8_valid_n(__param_s: *const i8, __param_nbytes: c_long) -> bool {
    var __local_s = __param_s
    var __local_nbytes = __param_nbytes
    var __local_d: cutf8_decode_t = cutf8_decode_t.zeroed()

    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_long = __local_nbytes

        (__local_nbytes = __local_nbytes - 1)

        if ((if __ci_expr_old_0 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (((if cutf8_decode((&raw mut __local_d as *mut cutf8_decode_t), (((*__local_s) as u8) as c_uint)) != 12: 1 else: 0) as c_int) & ((if (*__local_s) != 0: 1 else: 0) as c_int)) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        (__local_s = __local_s + 1)

    }

    return (((*(&raw const __local_d as *const cutf8_decode_t)).state == 0))

}

pub unsafe fn cutf8_encode(__param_out: *mut i8, __param_c: c_uint) -> c_int {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        ((__param_out[0]) = ((__param_c as c_char)))

        return 1

    }
    if ((if __param_c < 2048: 1 else: 0) != 0) {
        ((__param_out[0]) = ((((((((__param_c as c_uint) >> (6 as c_uint)) as c_uint) & (31 as c_uint)) as c_uint) | (192 as c_uint)) as c_char)))

        ((__param_out[1]) = ((((((__param_c as c_uint) & (63 as c_uint)) as c_uint) | (128 as c_uint)) as c_char)))

        return 2

    }
    if ((if __param_c < 65536: 1 else: 0) != 0) {
        if ((((if __param_c < 55296: 1 else: 0) as c_int) | ((if __param_c >= 57344: 1 else: 0) as c_int)) != 0) {
            ((__param_out[0]) = ((((((((__param_c as c_uint) >> (12 as c_uint)) as c_uint) & (15 as c_uint)) as c_uint) | (224 as c_uint)) as c_char)))

            ((__param_out[1]) = ((((((((__param_c as c_uint) >> (6 as c_uint)) as c_uint) & (63 as c_uint)) as c_uint) | (128 as c_uint)) as c_char)))

            ((__param_out[2]) = ((((((__param_c as c_uint) & (63 as c_uint)) as c_uint) | (128 as c_uint)) as c_char)))

            return 3

        }

    } else {
        if ((if __param_c < 1114112: 1 else: 0) != 0) {
            ((__param_out[0]) = ((((((((__param_c as c_uint) >> (18 as c_uint)) as c_uint) & (7 as c_uint)) as c_uint) | (240 as c_uint)) as c_char)))

            ((__param_out[1]) = ((((((((__param_c as c_uint) >> (12 as c_uint)) as c_uint) & (63 as c_uint)) as c_uint) | (128 as c_uint)) as c_char)))

            ((__param_out[2]) = ((((((((__param_c as c_uint) >> (6 as c_uint)) as c_uint) & (63 as c_uint)) as c_uint) | (128 as c_uint)) as c_char)))

            ((__param_out[3]) = ((((((__param_c as c_uint) & (63 as c_uint)) as c_uint) | (128 as c_uint)) as c_char)))

            return 4

        }
    }

    return 0

}

pub fn cutf8_casefold(__param_c: c_uint) -> c_uint {
    var __local_i: c_int

    loop {
        var __local__n: c_int = casefold_len

        var __local__i: c_int = ((0 as c_int))

        var __local__mid: c_int = (((__local__n / 2) as c_int))


        var __local__c: c_uint = __param_c

        while ((if __local__n > 0: 1 else: 0) != 0) {
            if ((if (unsafe *((&raw const casemappings[(__local__i + __local__mid)].c2 as *const c_ushort) as *mut c_ushort)) < (unsafe *(&raw mut __local__c as *mut c_uint)): 1 else: 0) != 0) {
                (__local__i = __local__i + (__local__mid + 1))

                (__local__n = __local__n - (__local__mid + 1))

                (__local__mid = ((((__local__n * 7) / 8) as c_int)))

            } else {
                (__local__n = __local__mid)

                (__local__mid = (((__local__n / 8) as c_int)))

            }

        }

        ((unsafe *(&raw mut __local_i as *mut c_int)) = __local__i)

        if not ((0 != 0)) {
            break
        }
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_i < casefold_len: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if casemappings[__local_i].c1 <= __param_c: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_entry: CaseMapping = casemappings[__local_i]

        var __local_d: c_int = (((((unsafe *(&raw const __local_entry as *const CaseMapping)).m2 as c_int) - ((unsafe *(&raw const __local_entry as *const CaseMapping)).c2 as c_int)) as c_int))

        if ((if __local_d == 1: 1 else: 0) != 0) {
            return ((__param_c as c_uint) +% ((if ((((unsafe *(&raw const __local_entry as *const CaseMapping)).c2 as c_int) as c_uint) & (1 as c_uint)) == ((__param_c as c_uint) & (1 as c_uint)): 1 else: 0) as c_uint))
        }

        return ((((__param_c as c_int) + __local_d) as c_uint))

    }


    return __param_c

}

pub fn cutf8_tolower(__param_c: c_uint) -> c_uint {
    var __local_i: c_int

    var __local_n: c_int = ((162 as c_int))


    loop {
        var __local__n: c_int = __local_n

        var __local__i: c_int = ((0 as c_int))

        var __local__mid: c_int = (((__local__n / 2) as c_int))


        var __local__c: c_uint = __param_c

        while ((if __local__n > 0: 1 else: 0) != 0) {
            if ((if (unsafe *((&raw const casemappings[upcase_ind[(__local__i + __local__mid)]].c2 as *const c_ushort) as *mut c_ushort)) < (unsafe *(&raw mut __local__c as *mut c_uint)): 1 else: 0) != 0) {
                (__local__i = __local__i + (__local__mid + 1))

                (__local__n = __local__n - (__local__mid + 1))

                (__local__mid = ((((__local__n * 7) / 8) as c_int)))

            } else {
                (__local__n = __local__mid)

                (__local__mid = (((__local__n / 8) as c_int)))

            }

        }

        ((unsafe *(&raw mut __local_i as *mut c_int)) = __local__i)

        if not ((0 != 0)) {
            break
        }
    }

    if ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __local_entry: CaseMapping = casemappings[upcase_ind[__local_i]]

        if ((if (unsafe *(&raw const __local_entry as *const CaseMapping)).c1 <= __param_c: 1 else: 0) != 0) {
            var __local_d: c_int = (((((unsafe *(&raw const __local_entry as *const CaseMapping)).m2 as c_int) - ((unsafe *(&raw const __local_entry as *const CaseMapping)).c2 as c_int)) as c_int))

            if ((if __local_d == 1: 1 else: 0) != 0) {
                return ((__param_c as c_uint) +% ((if ((((unsafe *(&raw const __local_entry as *const CaseMapping)).c2 as c_int) as c_uint) & (1 as c_uint)) == ((__param_c as c_uint) & (1 as c_uint)): 1 else: 0) as c_uint))
            }

            return ((((__param_c as c_int) + __local_d) as c_uint))

        }

    }

    return __param_c

}

pub fn cutf8_toupper(__param_c: c_uint) -> c_uint {
    var __local_i: c_int

    var __local_n: c_int = ((184 as c_int))


    loop {
        var __local__n: c_int = __local_n

        var __local__i: c_int = ((0 as c_int))

        var __local__mid: c_int = (((__local__n / 2) as c_int))


        var __local__c: c_uint = __param_c

        while ((if __local__n > 0: 1 else: 0) != 0) {
            if ((if (unsafe *((&raw const casemappings[lowcase_ind[(__local__i + __local__mid)]].m2 as *const c_ushort) as *mut c_ushort)) < (unsafe *(&raw mut __local__c as *mut c_uint)): 1 else: 0) != 0) {
                (__local__i = __local__i + (__local__mid + 1))

                (__local__n = __local__n - (__local__mid + 1))

                (__local__mid = ((((__local__n * 7) / 8) as c_int)))

            } else {
                (__local__n = __local__mid)

                (__local__mid = (((__local__n / 8) as c_int)))

            }

        }

        ((unsafe *(&raw mut __local_i as *mut c_int)) = __local__i)

        if not ((0 != 0)) {
            break
        }
    }

    if ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __local_entry: CaseMapping = casemappings[lowcase_ind[__local_i]]

        var __local_d: c_int = (((((unsafe *(&raw const __local_entry as *const CaseMapping)).m2 as c_int) - ((unsafe *(&raw const __local_entry as *const CaseMapping)).c2 as c_int)) as c_int))

        if ((if ((((unsafe *(&raw const __local_entry as *const CaseMapping)).c1 as c_int) as c_uint) +% (__local_d as c_uint)) <= __param_c: 1 else: 0) != 0) {
            if ((if __local_d == 1: 1 else: 0) != 0) {
                return ((__param_c as c_uint) -% ((if ((((unsafe *(&raw const __local_entry as *const CaseMapping)).m2 as c_int) as c_uint) & (1 as c_uint)) == ((__param_c as c_uint) & (1 as c_uint)): 1 else: 0) as c_uint))
            }

            return ((((__param_c as c_int) - __local_d) as c_uint))

        }

    }

    return __param_c

}

pub fn cutf8_icmp_sv(__param_s1: csview, __param_s2: csview) -> c_int {
    var __local_d1: cutf8_decode_t = cutf8_decode_t.zeroed()

    var __local_d2: cutf8_decode_t = cutf8_decode_t.zeroed()


    var __local_e1: *const c_char = ((((unsafe *(&raw const __param_s1 as *const csview)).buf + (((unsafe *(&raw const __param_s1 as *const csview)).size as c_long) as usize)) as *const c_char))

    var __local_e2: *const c_char = ((((unsafe *(&raw const __param_s2 as *const csview)).buf + (((unsafe *(&raw const __param_s2 as *const csview)).size as c_long) as usize)) as *const c_char))


    var __local_j1: c_long = ((0 as c_long))

    var __local_j2: c_long = ((0 as c_long))


    while ((((if __local_j1 < (unsafe *(&raw const __param_s1 as *const csview)).size: 1 else: 0) as c_int) & ((if __local_j2 < (unsafe *(&raw const __param_s2 as *const csview)).size: 1 else: 0) as c_int)) != 0) {
        if ((if (unsafe (*(&raw const __param_s2 as *const csview)).buf[__local_j2]) == 0: 1 else: 0) != 0) {
            return (unsafe (*(&raw const __param_s1 as *const csview)).buf[__local_j1])
        }

        (__local_j1 = __local_j1 + unsafe { cutf8_decode_codepoint((&raw mut __local_d1 as *mut cutf8_decode_t), (((*(&raw const __param_s1 as *const csview)).buf + ((__local_j1 as c_long) as usize)) as *const i8), __local_e1) })

        (__local_j2 = __local_j2 + unsafe { cutf8_decode_codepoint((&raw mut __local_d2 as *mut cutf8_decode_t), (((*(&raw const __param_s2 as *const csview)).buf + ((__local_j2 as c_long) as usize)) as *const i8), __local_e2) })

        var __local_c: c_int = ((((cutf8_casefold((unsafe *(&raw const __local_d1 as *const cutf8_decode_t)).codep) as c_int) - (cutf8_casefold((unsafe *(&raw const __local_d2 as *const cutf8_decode_t)).codep) as c_int)) as c_int))

        if ((if __local_c != 0: 1 else: 0) != 0) {
            return __local_c
        }

    }

    return ((((unsafe *(&raw const __param_s1 as *const csview)).size - (unsafe *(&raw const __param_s2 as *const csview)).size) as c_int))

}

unsafe fn cutf8_peek_at(__param_s: *const i8, __param_offset: c_long) -> c_uint {
    return cutf8_peek(cutf8_offset(__param_s, __param_offset))

}

fn cutf8_isupper(__param_c: c_uint) -> bool {
    return ((if (if __param_c < 128: 1 else: 0) != 0: ((((if __param_c >= 65: 1 else: 0) as c_int) & ((if __param_c <= 90: 1 else: 0) as c_int)) as c_int) else: ((if cutf8_tolower(__param_c) != __param_c: 1 else: 0) as c_int)) != 0)

}

fn cutf8_islower(__param_c: c_uint) -> bool {
    return ((if (if __param_c < 128: 1 else: 0) != 0: ((((if __param_c >= 97: 1 else: 0) as c_int) & ((if __param_c <= 122: 1 else: 0) as c_int)) as c_int) else: ((if cutf8_toupper(__param_c) != __param_c: 1 else: 0) as c_int)) != 0)

}

unsafe fn cutf8_icmp(__param_s1: *const i8, __param_s2: *const i8) -> c_int {
    return cutf8_icmp_sv((csview { buf: __param_s1, size: 9223372036854775807 } as csview), (csview { buf: __param_s2, size: 9223372036854775807 } as csview))

}

fn cutf8_isdigit(__param_c: c_uint) -> bool {
    return ((if (if __param_c < 128: 1 else: 0) != 0: ((((if __param_c >= 48: 1 else: 0) as c_int) & ((if __param_c <= 57: 1 else: 0) as c_int)) as c_int) else: (cutf8_isgroup(U8G_Nd, __param_c) as c_int)) != 0)

}

fn cutf8_isalpha(__param_c: c_uint) -> bool {
    return ((if (if __param_c < 128: 1 else: 0) != 0: ((if isalpha((__param_c as c_int)) != 0: 1 else: 0) as c_int) else: (cutf8_isgroup(U8G_L, __param_c) as c_int)) != 0)

}

fn cutf8_iscased(__param_c: c_uint) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((isalpha((__param_c as c_int)) != 0))
    }

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

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

    return (__ci_expr_logic_1 != 0)


}

fn cutf8_isalnum(__param_c: c_uint) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((isalnum((__param_c as c_int)) != 0))
    }

    var __ci_expr_logic_0: c_int

    if (cutf8_isgroup(U8G_L, __param_c) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Nd, __param_c) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

fn cutf8_isword(__param_c: c_uint) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((if isalnum((__param_c as c_int)) != 0: 1 else: 0) as c_int) | ((if __param_c == 95: 1 else: 0) as c_int)) != 0)
    }

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

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

    return (__ci_expr_logic_1 != 0)


}

fn cutf8_isblank(__param_c: c_uint) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((((if __param_c == 32: 1 else: 0) as c_int) | ((if __param_c == 9: 1 else: 0) as c_int)) != 0)
    }

    return cutf8_isgroup(U8G_Zs, __param_c)

}

fn cutf8_isspace(__param_c: c_uint) -> bool {
    if ((if __param_c < 128: 1 else: 0) != 0) {
        return ((isspace((__param_c as c_int)) != 0))
    }

    var __ci_expr_logic_0: c_int

    if ((((if __param_c == 8232: 1 else: 0) as c_int) | ((if __param_c == 8233: 1 else: 0) as c_int)) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if cutf8_isgroup(U8G_Zs, __param_c) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

pub unsafe fn cstr_u8_valid(__param_self_: *const cstr) -> bool {
    return cutf8_valid(cstr_str(__param_self_))

}

pub unsafe fn cstr_u8_erase(__param_self_: *mut cstr, __param_u8pos: c_long, __param_u8len: c_long) {
    var __local_b: csview = cstr_sv((__param_self_ as *const cstr))

    var __local_span: csview = cutf8_subview(((*(&raw const __local_b as *const csview)).buf as *const i8), __param_u8pos, __param_u8len)

    with_memmove(((((&raw const (__local_span.buf[0]) as *const c_char) as *mut c_char) as *mut c_void) as *mut u8), ((((&raw const (__local_span.buf[(*(&raw const __local_span as *const csview)).size]) as *const c_char) as *mut c_char) as *const c_void) as *const u8), (((if 1 != 0: ((((*(&raw const __local_b as *const csview)).size - (*(&raw const __local_span as *const csview)).size) - (((((*(&raw const __local_span as *const csview)).buf as usize) -% ((*(&raw const __local_b as *const csview)).buf as usize)) as c_long) / (sizeof[c_char]() as c_long))) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

    _cstr_set_size(__param_self_, (((*(&raw const __local_b as *const csview)).size - (*(&raw const __local_span as *const csview)).size) as c_long))

}

unsafe fn cstr_getbuf(__param_s: *mut cstr) -> cstr_buf {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (cstr_buf { data: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as c_long), cap: (((~(*(&raw const (*__param_s).lon as *const cstr_lon)).ncap)) as c_long) } as cstr_buf) else: (cstr_buf { data: (&raw const (*__param_s).sml.data[0] as *mut c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as c_long)), cap: 22 } as cstr_buf))

}

unsafe fn cstr_zv(__param_s: *const cstr) -> zsview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (zsview { str_: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as c_long) } as zsview) else: (zsview { str_: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as c_long)) } as zsview))

}

unsafe fn cstr_sv(__param_s: *const cstr) -> csview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (csview { buf: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as c_long) } as csview) else: (csview { buf: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as c_long)) } as csview))

}

unsafe fn cstr_from_n(__param_str_: *const i8, __param_len: c_long) -> cstr {
    var __local_s: cstr

    with_memcpy(((_cstr_init((&raw mut __local_s as *mut cstr), __param_len, __param_len) as *mut c_void) as *mut u8), ((__param_str_ as *const c_void) as *const u8), (((if 1 != 0: __param_len else: (-1 as c_long)) as c_ulong) as i64))

    return __local_s

}

unsafe fn cstr_from(__param_str_: *const i8) -> cstr {
    return cstr_from_n(__param_str_, (strlen(__param_str_) as c_long))

}

fn cstr_from_sv(__param_sv: csview) -> cstr {
    return unsafe { cstr_from_n(((*(&raw const __param_sv as *const csview)).buf as *const i8), (*(&raw const __param_sv as *const csview)).size) }

}

fn cstr_from_zv(__param_zv: zsview) -> cstr {
    return unsafe { cstr_from_n(((*(&raw const __param_zv as *const zsview)).str_ as *const i8), (*(&raw const __param_zv as *const zsview)).size) }

}

fn cstr_with_size(__param_size: c_long, __param_value: c_char) -> cstr {
    var __local_s: cstr

    with_memset(((unsafe { _cstr_init((&raw mut __local_s as *mut cstr), __param_size, __param_size) } as *mut c_void) as *mut u8), (__param_value as c_int), (((if 1 != 0: __param_size else: (-1 as c_long)) as c_ulong) as i64))

    return __local_s

}

fn cstr_with_capacity(__param_cap: c_long) -> cstr {
    var __local_s: cstr

    unsafe { _cstr_init((&raw mut __local_s as *mut cstr), (0 as c_long), __param_cap) }

    return __local_s

}

unsafe fn cstr_move(__param_self_: *mut cstr) -> cstr {
    var __local_tmp: cstr = (*__param_self_)

    let __ci_copy_7: cstr = (cstr.zeroed() as cstr)
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_7 as *const u8), sizeof[cstr]())

    return __local_tmp

}

fn cstr_clone(__param_s: cstr) -> cstr {
    var __local_sv: csview = unsafe { cstr_sv(((&raw mut __param_s as *mut cstr) as *const cstr)) }

    return unsafe { cstr_from_n(((*(&raw const __local_sv as *const csview)).buf as *const i8), (*(&raw const __local_sv as *const csview)).size) }

}

unsafe fn _cstr_set_size(__param_self_: *mut cstr, __param_len: c_long) -> Unit {
    if ((if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0) {
        ((*__param_self_).lon.size = ((__param_len as c_ulong)))

        (((*__param_self_).lon.data[(*(&raw const (*__param_self_).lon as *const cstr_lon)).size]) = ((0 as c_char)))

    } else {
        ((*__param_self_).sml.size = ((__param_len as u8)))

        ((*__param_self_).sml.data[(*(&raw const (*__param_self_).sml as *const cstr_sml)).size] = ((0 as c_char)))

    }

}

unsafe fn cstr_clear(__param_self_: *mut cstr) {
    _cstr_set_size(__param_self_, (0 as c_long))

}

unsafe fn cstr_data(__param_self_: *mut cstr) -> *mut i8 {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *mut c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *mut c_char)) as *mut i8))

}

unsafe fn cstr_str(__param_self_: *const cstr) -> *const i8 {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const i8))

}

unsafe fn cstr_toraw(__param_self_: *const cstr) -> *const i8 {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const i8))

}

unsafe fn cstr_size(__param_self_: *const cstr) -> c_long {
    return (if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).size as c_long) else: ((*(&raw const (*__param_self_).sml as *const cstr_sml)).size as c_long))

}

unsafe fn cstr_is_empty(__param_self_: *const cstr) -> bool {
    return ((cstr_size(__param_self_) == 0))

}

unsafe fn cstr_capacity(__param_self_: *const cstr) -> c_long {
    return (if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((~(*(&raw const (*__param_self_).lon as *const cstr_lon)).ncap) as c_long) else: (22 as c_long))

}

unsafe fn cstr_to_index(__param_self_: *const cstr, __param_it_: cstr_iter) -> c_long {
    return (((((*(&raw const __param_it_ as *const cstr_iter)).ref as usize) -% (cstr_str(__param_self_) as usize)) as c_long) / (sizeof[c_char]() as c_long))

}

fn cstr_from_s(__param_s: cstr, __param_pos: c_long, __param_len: c_long) -> cstr {
    return unsafe { cstr_from_n((unsafe { cstr_str(((&raw mut __param_s as *mut cstr) as *const cstr)) } + ((__param_pos as c_long) as usize)), __param_len) }

}

unsafe fn cstr_subview(__param_self_: *const cstr, __param_pos: c_long, __param_len: c_long) -> csview {
    var __local_len = __param_len
    var __local_sv: csview = cstr_sv(__param_self_)

    if (((if not ((((if ((__param_pos as c_ulong)) <= (((*(&raw const __local_sv as *const csview)).size as c_ulong)): 1 else: 0) as c_int) & ((if __local_len >= 0: 1 else: 0) as c_int)) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cstr_subview".ptr, c"cstr_prv.h".ptr, (174 as c_int), c"((size_t)pos <= (size_t)sv.size) & (len >= 0)".ptr)
    } else {
        0
    }

    if ((if (__param_pos + __local_len) > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_len = ((((*(&raw const __local_sv as *const csview)).size - __param_pos) as c_long)))
    }

    return ((csview { buf: ((*(&raw const __local_sv as *const csview)).buf + ((__param_pos as c_long) as usize)), size: __local_len } as csview))

}

unsafe fn cstr_tail(__param_self_: *const cstr, __param_len: c_long) -> zsview {
    var __local_len = __param_len
    if (((if not ((if __local_len >= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cstr_tail".ptr, c"cstr_prv.h".ptr, (180 as c_int), c"len >= 0".ptr)
    } else {
        0
    }

    var __local_sv: csview = cstr_sv(__param_self_)

    if ((if __local_len > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_len = (*(&raw const __local_sv as *const csview)).size)
    }

    return ((zsview { str_: ((&raw const (__local_sv.buf[((*(&raw const __local_sv as *const csview)).size - __local_len)]) as *const c_char) as *mut c_char), size: __local_len } as zsview))

}

unsafe fn cstr_u8_from(__param_str_: *const i8, __param_u8pos: c_long, __param_u8len: c_long) -> cstr {
    var __local_str_ = __param_str_
    (__local_str_ = ((cutf8_at(__local_str_, __param_u8pos) as *const c_char)))

    return cstr_from_n(__local_str_, (cutf8_to_index(__local_str_, __param_u8len) as c_long))

}

unsafe fn cstr_u8_size(__param_self_: *const cstr) -> c_long {
    return cutf8_count(cstr_str(__param_self_))

}

unsafe fn cstr_u8_to_index(__param_self_: *const cstr, __param_u8pos: c_long) -> c_long {
    return cutf8_to_index(cstr_str(__param_self_), __param_u8pos)

}

unsafe fn cstr_u8_tail(__param_self_: *const cstr, __param_u8len: c_long) -> zsview {
    var __local_u8len = __param_u8len
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_p: *const c_char = ((((&raw const (__local_sv.buf[(*(&raw const __local_sv as *const csview)).size]) as *const c_char) as *mut c_char) as *const c_char))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_u8len != 0) {
            (__ci_expr_logic_0 = (if (if __local_p != (*(&raw const __local_sv as *const csview)).buf: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_p = __local_p - 1)

        (__local_u8len = __local_u8len - (if (((*__local_p) as c_int) & (192 as c_int)) != 128: 1 else: 0))

    }

    return ((zsview { str_: __local_p, size: ((*(&raw const __local_sv as *const csview)).size - (((((__local_p as usize) -% ((*(&raw const __local_sv as *const csview)).buf as usize)) as c_long) / (sizeof[c_char]() as c_long)))) } as zsview))

}

unsafe fn cstr_u8_subview(__param_self_: *const cstr, __param_u8pos: c_long, __param_u8len: c_long) -> csview {
    return cutf8_subview(cstr_str(__param_self_), __param_u8pos, __param_u8len)

}

unsafe fn cstr_u8_at(__param_self_: *const cstr, __param_u8pos: c_long) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8_: cstr_iter_u8 { chr: csview { buf: cutf8_at(cstr_str(__param_self_), __param_u8pos) }, dec: cutf8_decode_t.zeroed() } }

    (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8_ as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const i8)) as c_long)))

    if ((if (*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *const c_char)))
    }

    return __local_it_

}

unsafe fn cstr_begin(__param_self_: *const cstr) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8_: cstr_iter_u8 { chr: csview { buf: cstr_str(__param_self_) }, dec: cutf8_decode_t.zeroed() } }

    if ((if (*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *const c_char)))
    } else {
        (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8_ as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const i8)) as c_long)))
    }

    return __local_it_

}

unsafe fn cstr_end(__param_self_: *const cstr) -> cstr_iter {

    var __local_it_: cstr_iter = cstr_iter.zeroed()

    return __local_it_

}

unsafe fn cstr_next(__param_it_: *mut cstr_iter) -> Unit {
    ((*__param_it_).ref = (*__param_it_).ref + (((*(&raw const (*__param_it_).chr as *const csview)).size as c_long) as usize))

    if ((if (*((*__param_it_).ref)) == 0: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *const c_char)))
    } else {
        ((*__param_it_).chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*__param_it_).u8_ as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*__param_it_).ref, (null as *const i8)) as c_long)))
    }

}

fn cstr_advance(__param_it_: cstr_iter, __param_u8pos: c_long) -> cstr_iter {
    (__param_it_.ref = ((unsafe { cutf8_offset((*(&raw const __param_it_ as *const cstr_iter)).ref, __param_u8pos) } as *const c_char)))

    if ((if (unsafe *((*(&raw const __param_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *const c_char)))
    } else {
        (__param_it_.chr.size = ((unsafe { cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __param_it_ as *const cstr_iter)).u8_ as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __param_it_ as *const cstr_iter)).ref, (null as *const i8)) } as c_long)))
    }

    return __param_it_

}

unsafe fn cstr_codepoint(__param_it_: *const cstr_iter) -> c_uint {
    return (*(&raw const (*__param_it_).u8_.dec as *const cutf8_decode_t)).codep

}

pub fn cstr_tocase_sv(__param_sv: csview, __param_k: c_int) -> cstr {
    var __local_out: cstr = cstr.zeroed()

    var __local_buf: *mut c_char = ((unsafe { cstr_reserve((&raw mut __local_out as *mut cstr), ((((*(&raw const __param_sv as *const csview)).size * 3) / 2) as c_long)) } as *mut c_char))

    var __local_sz: c_long = ((0 as c_long))

    var __local_d: cutf8_decode_t = cutf8_decode_t { state: 0 }

    var __local_end: *const c_char = ((((unsafe *(&raw const __param_sv as *const csview)).buf + (((unsafe *(&raw const __param_sv as *const csview)).size as c_long) as usize)) as *const c_char))

    while ((if (unsafe *(&raw const __param_sv as *const csview)).buf < __local_end: 1 else: 0) != 0) {
        (__param_sv.buf = (unsafe *(&raw const __param_sv as *const csview)).buf + ((unsafe { cutf8_decode_codepoint((&raw mut __local_d as *mut cutf8_decode_t), ((*(&raw const __param_sv as *const csview)).buf as *const i8), __local_end) } as c_long) as usize))

        if ((if (unsafe *(&raw const __local_d as *const cutf8_decode_t)).codep < 128: 1 else: 0) != 0) {
            var __ci_expr_old_0: c_long = __local_sz

            (__local_sz = __local_sz + 1)

            ((unsafe __local_buf[__ci_expr_old_0]) = ((fn_tocase[__param_k].conv_asc.unwrap()(((unsafe *(&raw const __local_d as *const cutf8_decode_t)).codep as c_int)) as c_char)))

        } else {
            var __local_cp: c_uint = ((fn_tocase[__param_k].conv_utf.unwrap()((unsafe *(&raw const __local_d as *const cutf8_decode_t)).codep) as c_uint))

            (__local_sz = __local_sz + unsafe { cutf8_encode((__local_buf + ((__local_sz as c_long) as usize)), __local_cp) })

        }

    }

    unsafe { _cstr_set_size((&raw mut __local_out as *mut cstr), __local_sz) }

    unsafe { cstr_shrink_to_fit((&raw mut __local_out as *mut cstr)) }

    return __local_out

}

fn cstr_casefold_sv(__param_sv: csview) -> cstr {
    return cstr_tocase_sv(__param_sv, (0 as c_int))

}

fn cstr_tolower_sv(__param_sv: csview) -> cstr {
    return cstr_tocase_sv(__param_sv, (1 as c_int))

}

fn cstr_toupper_sv(__param_sv: csview) -> cstr {
    return cstr_tocase_sv(__param_sv, (2 as c_int))

}

unsafe fn cstr_tolower(__param_str_: *const i8) -> cstr {
    return cstr_tolower_sv((csview { buf: __param_str_, size: (strlen(__param_str_) as c_long) } as csview))

}

unsafe fn cstr_toupper(__param_str_: *const i8) -> cstr {
    return cstr_toupper_sv((csview { buf: __param_str_, size: (strlen(__param_str_) as c_long) } as csview))

}

unsafe fn cstr_lowercase(__param_self_: *mut cstr) -> Unit {
    cstr_take(__param_self_, cstr_tolower_sv(cstr_sv((__param_self_ as *const cstr))))

}

unsafe fn cstr_uppercase(__param_self_: *mut cstr) -> Unit {
    cstr_take(__param_self_, cstr_toupper_sv(cstr_sv((__param_self_ as *const cstr))))

}

unsafe fn cstr_istarts_with(__param_self_: *const cstr, __param_sub: *const i8) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_len: c_long = ((strlen(__param_sub) as c_long))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_len <= (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_sv.size = __local_len)

        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__local_sv, (csview { buf: __param_sub, size: __local_len } as csview)) != 0): 1 else: 0) != 0: 1 else: 0))

    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn cstr_iends_with(__param_self_: *const cstr, __param_sub: *const i8) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_len: c_long = ((strlen(__param_sub) as c_long))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_len <= (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp(((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as c_long) as usize)) - ((__local_len as c_long) as usize)) as *const i8), __param_sub) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn cstr_icmp(__param_s1: *const cstr, __param_s2: *const cstr) -> c_int {
    return cutf8_icmp(cstr_str(__param_s1), cstr_str(__param_s2))

}

unsafe fn cstr_ieq(__param_s1: *const cstr, __param_s2: *const cstr) -> bool {
    var __local_x: csview = cstr_sv(__param_s1)

    var __local_y: csview = cstr_sv(__param_s2)


    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__local_x, __local_y) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn cstr_iequals(__param_self_: *const cstr, __param_str_: *const i8) -> bool {
    return ((not (cutf8_icmp(cstr_str(__param_self_), __param_str_) != 0)))

}

unsafe fn cstr_cmp(__param_s1: *const cstr, __param_s2: *const cstr) -> c_int {
    return strcmp(cstr_str(__param_s1), cstr_str(__param_s2))

}

unsafe fn cstr_eq(__param_s1: *const cstr, __param_s2: *const cstr) -> bool {
    var __local_x: csview = cstr_sv(__param_s1)

    var __local_y: csview = cstr_sv(__param_s2)


    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((*(&raw const __local_x as *const csview)).buf as *const c_void) as *const u8), (((*(&raw const __local_y as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __local_x as *const csview)).size else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn cstr_equals(__param_self_: *const cstr, __param_str_: *const i8) -> bool {
    return ((not (strcmp(cstr_str(__param_self_), __param_str_) != 0)))

}

unsafe fn cstr_equals_sv(__param_self_: *const cstr, __param_sv: csview) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __param_sv as *const csview)).size == cstr_size(__param_self_): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sv as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sv as *const csview)).size else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn cstr_find(__param_self_: *const cstr, __param_search: *const i8) -> c_long {
    var __local_str_: *const c_char = ((cstr_str(__param_self_) as *const c_char))

    var __local_res: *const c_char = ((strstr(((__local_str_ as *mut c_char) as *const i8), __param_search) as *const c_char))


    return (if __local_res != null: (((((__local_res as usize) -% (__local_str_ as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_long) else: (9223372036854775807 as c_long))

}

unsafe fn cstr_contains(__param_self_: *const cstr, __param_search: *const i8) -> bool {
    return ((strstr(((cstr_str(__param_self_) as *mut c_char) as *const i8), __param_search) != null))

}

unsafe fn cstr_contains_sv(__param_self_: *const cstr, __param_search: csview) -> bool {
    return ((cstr_find_sv(__param_self_, __param_search) != 9223372036854775807))

}

unsafe fn cstr_starts_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    if ((if (*(&raw const __param_sub as *const csview)).size > cstr_size(__param_self_): 1 else: 0) != 0) {
        return false
    }

    return ((not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sub as *const csview)).size else: (-1 as c_long)) as c_ulong) as i64)) != 0)))

}

unsafe fn cstr_starts_with(__param_self_: *const cstr, __param_sub: *const i8) -> bool {
    var __local_sub = __param_sub
    var __local_str_: *const c_char = ((cstr_str(__param_self_) as *const c_char))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((*__local_sub) != 0) {
            (__ci_expr_logic_0 = (if (if (*__local_str_) == (*__local_sub): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_str_ = __local_str_ + 1)

        (__local_sub = __local_sub + 1)

    }

    return ((not ((*__local_sub) != 0)))

}

unsafe fn cstr_ends_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    if ((if (*(&raw const __param_sub as *const csview)).size > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        return false
    }

    return ((not (with_memcmp((((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as c_long) as usize)) - (((*(&raw const __param_sub as *const csview)).size as c_long) as usize)) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sub as *const csview)).size else: (-1 as c_long)) as c_ulong) as i64)) != 0)))

}

unsafe fn cstr_ends_with(__param_self_: *const cstr, __param_sub: *const i8) -> bool {
    return cstr_ends_with_sv(__param_self_, (csview { buf: __param_sub, size: (strlen(__param_sub) as c_long) } as csview))

}

unsafe fn cstr_assign(__param_self_: *mut cstr, __param_str_: *const i8) -> *mut i8 {
    return ((cstr_assign_n(__param_self_, __param_str_, (strlen(__param_str_) as c_long)) as *mut i8))

}

unsafe fn cstr_assign_sv(__param_self_: *mut cstr, __param_sv: csview) -> *mut i8 {
    return ((cstr_assign_n(__param_self_, ((*(&raw const __param_sv as *const csview)).buf as *const i8), (*(&raw const __param_sv as *const csview)).size) as *mut i8))

}

unsafe fn cstr_copy(__param_self_: *mut cstr, __param_s: cstr) -> *mut i8 {
    var __local_sv: csview = cstr_sv(((&raw mut __param_s as *mut cstr) as *const cstr))

    return ((cstr_assign_n(__param_self_, ((*(&raw const __local_sv as *const csview)).buf as *const i8), (*(&raw const __local_sv as *const csview)).size) as *mut i8))

}

unsafe fn cstr_push(__param_self_: *mut cstr, __param_chr: *const i8) -> *mut i8 {
    return ((cstr_append_n(__param_self_, __param_chr, (cutf8_chr_size(__param_chr) as c_long)) as *mut i8))

}

unsafe fn cstr_pop(__param_self_: *mut cstr) {
    var __local_sv: csview = cstr_sv((__param_self_ as *const cstr))

    var __local_s: *const c_char = ((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as c_long) as usize)) as *const c_char))

    while true {
        (__local_s = __local_s - 1)

        if (not ((if (((*__local_s) as c_int) & (192 as c_int)) == 128: 1 else: 0) != 0)) {
            break
        }

    }

    _cstr_set_size(__param_self_, (((((__local_s as usize) -% ((*(&raw const __local_sv as *const csview)).buf as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_long))

}

unsafe fn cstr_append(__param_self_: *mut cstr, __param_str_: *const i8) -> *mut i8 {
    return ((cstr_append_n(__param_self_, __param_str_, (strlen(__param_str_) as c_long)) as *mut i8))

}

unsafe fn cstr_append_sv(__param_self_: *mut cstr, __param_sv: csview) -> *mut i8 {
    return ((cstr_append_n(__param_self_, ((*(&raw const __param_sv as *const csview)).buf as *const i8), (*(&raw const __param_sv as *const csview)).size) as *mut i8))

}

unsafe fn cstr_append_s(__param_self_: *mut cstr, __param_s: cstr) -> *mut i8 {
    return ((cstr_append_sv(__param_self_, cstr_sv(((&raw mut __param_s as *mut cstr) as *const cstr))) as *mut i8))

}

unsafe fn cstr_join_array(__param_self_: *mut cstr, __param_sep: *const i8, __param_arr: *mut *const i8, __param_n: c_long) {
    var __local_arr = __param_arr
    var __local_n = __param_n
    var __local__sep: *const c_char = (((if cstr_is_empty((__param_self_ as *const cstr)) != 0: c"".ptr else: (__param_sep as *const c_char)) as *const c_char))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        cstr_append(__param_self_, __local__sep)

        var __ci_expr_old_1: *mut *const i8 = __local_arr

        (__local_arr = __local_arr + 1)

        cstr_append(__param_self_, (*(&(__ci_expr_old_1[0]) as *mut *const i8)))

        (__local__sep = ((__param_sep as *const c_char)))

    }

}

unsafe fn cstr_join_array_s(__param_self_: *mut cstr, __param_sep: *const i8, __param_arr: *mut cstr, __param_n: c_long) {
    var __local_arr = __param_arr
    var __local_n = __param_n
    var __local__sep: *const c_char = (((if cstr_is_empty((__param_self_ as *const cstr)) != 0: c"".ptr else: (__param_sep as *const c_char)) as *const c_char))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        cstr_append(__param_self_, __local__sep)

        var __ci_expr_old_1: *mut cstr = __local_arr

        (__local_arr = __local_arr + 1)

        cstr_append_s(__param_self_, (*(&(__ci_expr_old_1[0]) as *mut cstr)))

        (__local__sep = ((__param_sep as *const c_char)))

    }

}

unsafe fn cstr_replace_sv(__param_self_: *mut cstr, __param_search: csview, __param_repl: csview, __param_count: c_int) -> Unit {
    cstr_take(__param_self_, cstr_from_replace(cstr_sv((__param_self_ as *const cstr)), __param_search, __param_repl, __param_count))

}

unsafe fn cstr_replace_nfirst(__param_self_: *mut cstr, __param_search: *const i8, __param_repl: *const i8, __param_count: c_int) {
    cstr_replace_sv(__param_self_, (csview { buf: __param_search, size: (strlen(__param_search) as c_long) } as csview), (csview { buf: __param_repl, size: (strlen(__param_repl) as c_long) } as csview), __param_count)

}

unsafe fn cstr_replace(__param_self_: *mut cstr, __param_search: *const i8, __param_repl: *const i8) {
    cstr_replace_nfirst(__param_self_, __param_search, __param_repl, (2147483647 as c_int))

}

unsafe fn cstr_replace_at_sv(__param_self_: *mut cstr, __param_pos: c_long, __param_len: c_long, __param_repl: csview) -> Unit {
    var __local_d: *mut c_char = ((_cstr_internal_move(__param_self_, ((__param_pos + __param_len) as c_long), ((__param_pos + (*(&raw const __param_repl as *const csview)).size) as c_long)) as *mut c_char))

    with_memcpy((((__local_d + ((__param_pos as c_long) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __param_repl as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_repl as *const csview)).size else: (-1 as c_long)) as c_ulong) as i64))

}

unsafe fn cstr_replace_at(__param_self_: *mut cstr, __param_pos: c_long, __param_len: c_long, __param_repl: *const i8) {
    cstr_replace_at_sv(__param_self_, __param_pos, __param_len, (csview { buf: __param_repl, size: (strlen(__param_repl) as c_long) } as csview))

}

unsafe fn cstr_u8_replace(__param_self_: *mut cstr, __param_u8pos: c_long, __param_u8len: c_long, __param_repl: *const i8) {
    var __local_s: *const c_char = ((cstr_str((__param_self_ as *const cstr)) as *const c_char))

    var __local_span: csview = cutf8_subview(__local_s, __param_u8pos, __param_u8len)

    cstr_replace_at(__param_self_, ((((((*(&raw const __local_span as *const csview)).buf as usize) -% (__local_s as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_long), (*(&raw const __local_span as *const csview)).size, __param_repl)

}

unsafe fn cstr_insert_sv(__param_self_: *mut cstr, __param_pos: c_long, __param_sv: csview) {
    cstr_replace_at_sv(__param_self_, __param_pos, (0 as c_long), __param_sv)

}

unsafe fn cstr_insert(__param_self_: *mut cstr, __param_pos: c_long, __param_str_: *const i8) {
    cstr_replace_at_sv(__param_self_, __param_pos, (0 as c_long), (csview { buf: __param_str_, size: (strlen(__param_str_) as c_long) } as csview))

}

unsafe fn cstr_u8_insert(__param_self_: *mut cstr, __param_u8pos: c_long, __param_str_: *const i8) {
    cstr_insert(__param_self_, (cutf8_to_index(cstr_str((__param_self_ as *const cstr)), __param_u8pos) as c_long), __param_str_)

}

unsafe fn cstr_getline(__param_self_: *mut cstr, __param_fp: *mut c_void) -> bool {
    return cstr_getdelim(__param_self_, (10 as c_int), __param_fp)

}

fn toLower(__param_c: c_int) -> c_int {
    var __ci_expr_ternary_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_c >= 65: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_c <= 90: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = (((__param_c + 32) as c_int)))
    } else {
        (__ci_expr_ternary_1 = __param_c)
    }

    return __ci_expr_ternary_1


}

fn toUpper(__param_c: c_int) -> c_int {
    var __ci_expr_ternary_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if __param_c >= 97: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_c <= 122: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = (((__param_c - 32) as c_int)))
    } else {
        (__ci_expr_ternary_1 = __param_c)
    }

    return __ci_expr_ternary_1


}

let casemappings: List[CaseMapping] = [CaseMapping { c1: 65, c2: 90, m2: 122 }, CaseMapping { c1: 181, c2: 181, m2: 956 }, CaseMapping { c1: 192, c2: 214, m2: 246 }, CaseMapping { c1: 216, c2: 222, m2: 254 }, CaseMapping { c1: 256, c2: 302, m2: 303 }, CaseMapping { c1: 306, c2: 310, m2: 311 }, CaseMapping { c1: 313, c2: 327, m2: 328 }, CaseMapping { c1: 330, c2: 374, m2: 375 }, CaseMapping { c1: 376, c2: 376, m2: 255 }, CaseMapping { c1: 377, c2: 381, m2: 382 }, CaseMapping { c1: 383, c2: 383, m2: 115 }, CaseMapping { c1: 385, c2: 385, m2: 595 }, CaseMapping { c1: 386, c2: 388, m2: 389 }, CaseMapping { c1: 390, c2: 390, m2: 596 }, CaseMapping { c1: 391, c2: 391, m2: 392 }, CaseMapping { c1: 393, c2: 394, m2: 599 }, CaseMapping { c1: 395, c2: 395, m2: 396 }, CaseMapping { c1: 398, c2: 398, m2: 477 }, CaseMapping { c1: 399, c2: 399, m2: 601 }, CaseMapping { c1: 400, c2: 400, m2: 603 }, CaseMapping { c1: 401, c2: 401, m2: 402 }, CaseMapping { c1: 403, c2: 403, m2: 608 }, CaseMapping { c1: 404, c2: 404, m2: 611 }, CaseMapping { c1: 406, c2: 406, m2: 617 }, CaseMapping { c1: 407, c2: 407, m2: 616 }, CaseMapping { c1: 408, c2: 408, m2: 409 }, CaseMapping { c1: 412, c2: 412, m2: 623 }, CaseMapping { c1: 413, c2: 413, m2: 626 }, CaseMapping { c1: 415, c2: 415, m2: 629 }, CaseMapping { c1: 416, c2: 420, m2: 421 }, CaseMapping { c1: 422, c2: 422, m2: 640 }, CaseMapping { c1: 423, c2: 423, m2: 424 }, CaseMapping { c1: 425, c2: 425, m2: 643 }, CaseMapping { c1: 428, c2: 428, m2: 429 }, CaseMapping { c1: 430, c2: 430, m2: 648 }, CaseMapping { c1: 431, c2: 431, m2: 432 }, CaseMapping { c1: 433, c2: 434, m2: 651 }, CaseMapping { c1: 435, c2: 437, m2: 438 }, CaseMapping { c1: 439, c2: 439, m2: 658 }, CaseMapping { c1: 440, c2: 440, m2: 441 }, CaseMapping { c1: 444, c2: 444, m2: 445 }, CaseMapping { c1: 452, c2: 452, m2: 454 }, CaseMapping { c1: 453, c2: 453, m2: 454 }, CaseMapping { c1: 455, c2: 455, m2: 457 }, CaseMapping { c1: 456, c2: 456, m2: 457 }, CaseMapping { c1: 458, c2: 458, m2: 460 }, CaseMapping { c1: 459, c2: 475, m2: 476 }, CaseMapping { c1: 478, c2: 494, m2: 495 }, CaseMapping { c1: 497, c2: 497, m2: 499 }, CaseMapping { c1: 498, c2: 500, m2: 501 }, CaseMapping { c1: 502, c2: 502, m2: 405 }, CaseMapping { c1: 503, c2: 503, m2: 447 }, CaseMapping { c1: 504, c2: 542, m2: 543 }, CaseMapping { c1: 544, c2: 544, m2: 414 }, CaseMapping { c1: 546, c2: 562, m2: 563 }, CaseMapping { c1: 570, c2: 570, m2: 11365 }, CaseMapping { c1: 571, c2: 571, m2: 572 }, CaseMapping { c1: 573, c2: 573, m2: 410 }, CaseMapping { c1: 574, c2: 574, m2: 11366 }, CaseMapping { c1: 577, c2: 577, m2: 578 }, CaseMapping { c1: 579, c2: 579, m2: 384 }, CaseMapping { c1: 580, c2: 580, m2: 649 }, CaseMapping { c1: 581, c2: 581, m2: 652 }, CaseMapping { c1: 582, c2: 590, m2: 591 }, CaseMapping { c1: 837, c2: 837, m2: 953 }, CaseMapping { c1: 880, c2: 882, m2: 883 }, CaseMapping { c1: 886, c2: 886, m2: 887 }, CaseMapping { c1: 895, c2: 895, m2: 1011 }, CaseMapping { c1: 902, c2: 902, m2: 940 }, CaseMapping { c1: 904, c2: 906, m2: 943 }, CaseMapping { c1: 908, c2: 908, m2: 972 }, CaseMapping { c1: 910, c2: 911, m2: 974 }, CaseMapping { c1: 913, c2: 929, m2: 961 }, CaseMapping { c1: 931, c2: 939, m2: 971 }, CaseMapping { c1: 962, c2: 962, m2: 963 }, CaseMapping { c1: 975, c2: 975, m2: 983 }, CaseMapping { c1: 976, c2: 976, m2: 946 }, CaseMapping { c1: 977, c2: 977, m2: 952 }, CaseMapping { c1: 981, c2: 981, m2: 966 }, CaseMapping { c1: 982, c2: 982, m2: 960 }, CaseMapping { c1: 984, c2: 1006, m2: 1007 }, CaseMapping { c1: 1008, c2: 1008, m2: 954 }, CaseMapping { c1: 1009, c2: 1009, m2: 961 }, CaseMapping { c1: 1012, c2: 1012, m2: 952 }, CaseMapping { c1: 1013, c2: 1013, m2: 949 }, CaseMapping { c1: 1015, c2: 1015, m2: 1016 }, CaseMapping { c1: 1017, c2: 1017, m2: 1010 }, CaseMapping { c1: 1018, c2: 1018, m2: 1019 }, CaseMapping { c1: 1021, c2: 1023, m2: 893 }, CaseMapping { c1: 1024, c2: 1039, m2: 1119 }, CaseMapping { c1: 1040, c2: 1071, m2: 1103 }, CaseMapping { c1: 1120, c2: 1152, m2: 1153 }, CaseMapping { c1: 1162, c2: 1214, m2: 1215 }, CaseMapping { c1: 1216, c2: 1216, m2: 1231 }, CaseMapping { c1: 1217, c2: 1229, m2: 1230 }, CaseMapping { c1: 1232, c2: 1326, m2: 1327 }, CaseMapping { c1: 1329, c2: 1366, m2: 1414 }, CaseMapping { c1: 4256, c2: 4293, m2: 11557 }, CaseMapping { c1: 4295, c2: 4295, m2: 11559 }, CaseMapping { c1: 4301, c2: 4301, m2: 11565 }, CaseMapping { c1: 5112, c2: 5117, m2: 5109 }, CaseMapping { c1: 7296, c2: 7296, m2: 1074 }, CaseMapping { c1: 7297, c2: 7297, m2: 1076 }, CaseMapping { c1: 7298, c2: 7298, m2: 1086 }, CaseMapping { c1: 7299, c2: 7300, m2: 1090 }, CaseMapping { c1: 7301, c2: 7301, m2: 1090 }, CaseMapping { c1: 7302, c2: 7302, m2: 1098 }, CaseMapping { c1: 7303, c2: 7303, m2: 1123 }, CaseMapping { c1: 7304, c2: 7304, m2: 42571 }, CaseMapping { c1: 7312, c2: 7354, m2: 4346 }, CaseMapping { c1: 7357, c2: 7359, m2: 4351 }, CaseMapping { c1: 7680, c2: 7828, m2: 7829 }, CaseMapping { c1: 7835, c2: 7835, m2: 7777 }, CaseMapping { c1: 7838, c2: 7838, m2: 223 }, CaseMapping { c1: 7840, c2: 7934, m2: 7935 }, CaseMapping { c1: 7944, c2: 7951, m2: 7943 }, CaseMapping { c1: 7960, c2: 7965, m2: 7957 }, CaseMapping { c1: 7976, c2: 7983, m2: 7975 }, CaseMapping { c1: 7992, c2: 7999, m2: 7991 }, CaseMapping { c1: 8008, c2: 8013, m2: 8005 }, CaseMapping { c1: 8025, c2: 8031, m2: 8023 }, CaseMapping { c1: 8040, c2: 8047, m2: 8039 }, CaseMapping { c1: 8072, c2: 8079, m2: 8071 }, CaseMapping { c1: 8088, c2: 8095, m2: 8087 }, CaseMapping { c1: 8104, c2: 8111, m2: 8103 }, CaseMapping { c1: 8120, c2: 8121, m2: 8113 }, CaseMapping { c1: 8122, c2: 8123, m2: 8049 }, CaseMapping { c1: 8124, c2: 8124, m2: 8115 }, CaseMapping { c1: 8126, c2: 8126, m2: 953 }, CaseMapping { c1: 8136, c2: 8139, m2: 8053 }, CaseMapping { c1: 8140, c2: 8140, m2: 8131 }, CaseMapping { c1: 8152, c2: 8153, m2: 8145 }, CaseMapping { c1: 8154, c2: 8155, m2: 8055 }, CaseMapping { c1: 8168, c2: 8169, m2: 8161 }, CaseMapping { c1: 8170, c2: 8171, m2: 8059 }, CaseMapping { c1: 8172, c2: 8172, m2: 8165 }, CaseMapping { c1: 8184, c2: 8185, m2: 8057 }, CaseMapping { c1: 8186, c2: 8187, m2: 8061 }, CaseMapping { c1: 8188, c2: 8188, m2: 8179 }, CaseMapping { c1: 8486, c2: 8486, m2: 969 }, CaseMapping { c1: 8490, c2: 8490, m2: 107 }, CaseMapping { c1: 8491, c2: 8491, m2: 229 }, CaseMapping { c1: 8498, c2: 8498, m2: 8526 }, CaseMapping { c1: 8544, c2: 8559, m2: 8575 }, CaseMapping { c1: 8579, c2: 8579, m2: 8580 }, CaseMapping { c1: 9398, c2: 9423, m2: 9449 }, CaseMapping { c1: 11264, c2: 11311, m2: 11359 }, CaseMapping { c1: 11360, c2: 11360, m2: 11361 }, CaseMapping { c1: 11362, c2: 11362, m2: 619 }, CaseMapping { c1: 11363, c2: 11363, m2: 7549 }, CaseMapping { c1: 11364, c2: 11364, m2: 637 }, CaseMapping { c1: 11367, c2: 11371, m2: 11372 }, CaseMapping { c1: 11373, c2: 11373, m2: 593 }, CaseMapping { c1: 11374, c2: 11374, m2: 625 }, CaseMapping { c1: 11375, c2: 11375, m2: 592 }, CaseMapping { c1: 11376, c2: 11376, m2: 594 }, CaseMapping { c1: 11378, c2: 11378, m2: 11379 }, CaseMapping { c1: 11381, c2: 11381, m2: 11382 }, CaseMapping { c1: 11390, c2: 11391, m2: 576 }, CaseMapping { c1: 11392, c2: 11490, m2: 11491 }, CaseMapping { c1: 11499, c2: 11501, m2: 11502 }, CaseMapping { c1: 11506, c2: 11506, m2: 11507 }, CaseMapping { c1: 42560, c2: 42604, m2: 42605 }, CaseMapping { c1: 42624, c2: 42650, m2: 42651 }, CaseMapping { c1: 42786, c2: 42798, m2: 42799 }, CaseMapping { c1: 42802, c2: 42862, m2: 42863 }, CaseMapping { c1: 42873, c2: 42875, m2: 42876 }, CaseMapping { c1: 42877, c2: 42877, m2: 7545 }, CaseMapping { c1: 42878, c2: 42886, m2: 42887 }, CaseMapping { c1: 42891, c2: 42891, m2: 42892 }, CaseMapping { c1: 42893, c2: 42893, m2: 613 }, CaseMapping { c1: 42896, c2: 42898, m2: 42899 }, CaseMapping { c1: 42902, c2: 42920, m2: 42921 }, CaseMapping { c1: 42922, c2: 42922, m2: 614 }, CaseMapping { c1: 42923, c2: 42923, m2: 604 }, CaseMapping { c1: 42924, c2: 42924, m2: 609 }, CaseMapping { c1: 42925, c2: 42925, m2: 620 }, CaseMapping { c1: 42926, c2: 42926, m2: 618 }, CaseMapping { c1: 42928, c2: 42928, m2: 670 }, CaseMapping { c1: 42929, c2: 42929, m2: 647 }, CaseMapping { c1: 42930, c2: 42930, m2: 669 }, CaseMapping { c1: 42931, c2: 42931, m2: 43859 }, CaseMapping { c1: 42932, c2: 42946, m2: 42947 }, CaseMapping { c1: 42948, c2: 42948, m2: 42900 }, CaseMapping { c1: 42949, c2: 42949, m2: 642 }, CaseMapping { c1: 42950, c2: 42950, m2: 7566 }, CaseMapping { c1: 42951, c2: 42953, m2: 42954 }, CaseMapping { c1: 42960, c2: 42960, m2: 42961 }, CaseMapping { c1: 42966, c2: 42968, m2: 42969 }, CaseMapping { c1: 42997, c2: 42997, m2: 42998 }, CaseMapping { c1: 43888, c2: 43967, m2: 5103 }, CaseMapping { c1: 65313, c2: 65338, m2: 65370 }, CaseMapping { c1: 304, c2: 304, m2: 105 }, CaseMapping { c1: 461, c2: 475, m2: 476 }, CaseMapping { c1: 500, c2: 500, m2: 501 }, CaseMapping { c1: 5024, c2: 5103, m2: 43967 }, CaseMapping { c1: 5104, c2: 5109, m2: 5117 }, CaseMapping { c1: 924, c2: 924, m2: 181 }, CaseMapping { c1: 73, c2: 73, m2: 305 }, CaseMapping { c1: 83, c2: 83, m2: 383 }, CaseMapping { c1: 931, c2: 931, m2: 962 }, CaseMapping { c1: 914, c2: 914, m2: 976 }, CaseMapping { c1: 920, c2: 920, m2: 977 }, CaseMapping { c1: 934, c2: 934, m2: 981 }, CaseMapping { c1: 928, c2: 928, m2: 982 }, CaseMapping { c1: 922, c2: 922, m2: 1008 }, CaseMapping { c1: 929, c2: 929, m2: 1009 }, CaseMapping { c1: 917, c2: 917, m2: 1013 }, CaseMapping { c1: 1042, c2: 1042, m2: 7296 }, CaseMapping { c1: 1044, c2: 1044, m2: 7297 }, CaseMapping { c1: 1054, c2: 1054, m2: 7298 }, CaseMapping { c1: 1057, c2: 1058, m2: 7300 }, CaseMapping { c1: 1058, c2: 1058, m2: 7301 }, CaseMapping { c1: 1066, c2: 1066, m2: 7302 }, CaseMapping { c1: 1122, c2: 1122, m2: 7303 }, CaseMapping { c1: 42570, c2: 42570, m2: 7304 }, CaseMapping { c1: 7776, c2: 7776, m2: 7835 }, CaseMapping { c1: 921, c2: 921, m2: 8126 }]
let upcase_ind: List[u8] = [0, 2, 3, 4, 192, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 43, 45, 193, 47, 48, 194, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 65, 66, 67, 68, 69, 70, 71, 72, 73, 75, 80, 83, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 195, 196, 109, 110, 111, 113, 114, 115, 116, 117, 118, 119, 120, 121, 125, 126, 129, 131, 132, 133, 134, 135, 136, 137, 139, 140, 141, 142, 144, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 191]
let lowcase_ind: List[u8] = [0, 197, 113, 2, 3, 8, 4, 198, 5, 6, 7, 9, 199, 60, 12, 14, 16, 20, 50, 25, 57, 53, 29, 31, 33, 35, 37, 39, 40, 51, 41, 43, 45, 193, 17, 47, 48, 194, 52, 54, 56, 158, 59, 63, 154, 152, 155, 11, 13, 15, 18, 19, 174, 21, 175, 22, 170, 173, 24, 23, 177, 148, 176, 26, 153, 27, 28, 150, 30, 184, 32, 179, 34, 61, 36, 62, 38, 180, 178, 65, 66, 88, 68, 69, 72, 200, 73, 70, 71, 201, 202, 203, 204, 75, 80, 205, 206, 86, 67, 207, 85, 87, 90, 89, 91, 92, 94, 93, 95, 96, 109, 110, 196, 208, 209, 210, 211, 212, 213, 214, 215, 167, 149, 185, 111, 216, 114, 115, 116, 117, 118, 119, 120, 121, 126, 129, 132, 136, 134, 137, 122, 123, 124, 125, 127, 217, 130, 131, 133, 135, 138, 142, 144, 146, 147, 55, 58, 151, 156, 157, 159, 160, 161, 97, 98, 99, 162, 163, 164, 165, 166, 168, 169, 171, 183, 172, 182, 186, 187, 188, 189, 181, 195, 191]
let fn_tocase: List[fn_tocase_anon] = [fn_tocase_anon { conv_asc: Some(toLower), conv_utf: Some(cutf8_casefold) }, fn_tocase_anon { conv_asc: Some(toLower), conv_utf: Some(cutf8_tolower) }, fn_tocase_anon { conv_asc: Some(toUpper), conv_utf: Some(cutf8_toupper) }]
