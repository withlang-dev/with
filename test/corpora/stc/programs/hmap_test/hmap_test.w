// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
use std.engines.stc_testing.utf8_misc
use std.engines.stc_testing.cstr_utf8
use std.engines.stc_testing.ucd
use std.engines.stc_testing.cstr_core
use std.engines.stc_testing.cstr_misc
use std.engines.stc_testing.cstr_io
use std.libc
use std.option

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

unsafe fn c_hash_str(__param_str: *const i8) -> c_ulong {
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

unsafe fn c_strnstrn(__param_str: *const i8, __param_slen: c_long, __param_needle: *const i8, __param_nlen: c_long) -> *mut i8 {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return (((__local_str as *mut c_char) as *mut i8))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut i8))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return (((__local_str as *mut c_char) as *mut i8))
        }


        (__local_str = __local_str + 1)

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

unsafe fn cstr_getbuf(__param_s: *mut cstr) -> cstr_buf {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (cstr_buf { data: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as c_long), cap: (((~(*(&raw const (*__param_s).lon as *const cstr_lon)).ncap)) as c_long) } as cstr_buf) else: (cstr_buf { data: (&raw const (*__param_s).sml.data[0] as *mut c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as c_long)), cap: 22 } as cstr_buf))

}

unsafe fn cstr_zv(__param_s: *const cstr) -> zsview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (zsview { str: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as c_long) } as zsview) else: (zsview { str: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as c_long)) } as zsview))

}

unsafe fn cstr_sv(__param_s: *const cstr) -> csview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (csview { buf: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as c_long) } as csview) else: (csview { buf: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as c_long)) } as csview))

}

unsafe fn cstr_from_n(__param_str: *const i8, __param_len: c_long) -> cstr {
    var __local_s: cstr

    with_memcpy(((_cstr_init((&raw mut __local_s as *mut cstr), __param_len, __param_len) as *mut c_void) as *mut u8), ((__param_str as *const c_void) as *const u8), (((if 1 != 0: __param_len else: (-1 as c_long)) as c_ulong) as i64))

    return __local_s

}

unsafe fn cstr_from(__param_str: *const i8) -> cstr {
    return cstr_from_n(__param_str, (strlen(__param_str) as c_long))

}

fn cstr_from_sv(__param_sv: csview) -> cstr {
    return unsafe { cstr_from_n(((*(&raw const __param_sv as *const csview)).buf as *const i8), (*(&raw const __param_sv as *const csview)).size) }

}

fn cstr_from_zv(__param_zv: zsview) -> cstr {
    return unsafe { cstr_from_n(((*(&raw const __param_zv as *const zsview)).str as *const i8), (*(&raw const __param_zv as *const zsview)).size) }

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

    return ((zsview { str: ((&raw const (__local_sv.buf[((*(&raw const __local_sv as *const csview)).size - __local_len)]) as *const c_char) as *mut c_char), size: __local_len } as zsview))

}

unsafe fn cstr_u8_from(__param_str: *const i8, __param_u8pos: c_long, __param_u8len: c_long) -> cstr {
    var __local_str = __param_str
    (__local_str = ((cutf8_at(__local_str, __param_u8pos) as *const c_char)))

    return cstr_from_n(__local_str, (cutf8_to_index(__local_str, __param_u8len) as c_long))

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

    return ((zsview { str: __local_p, size: ((*(&raw const __local_sv as *const csview)).size - (((((__local_p as usize) -% ((*(&raw const __local_sv as *const csview)).buf as usize)) as c_long) / (sizeof[c_char]() as c_long)))) } as zsview))

}

unsafe fn cstr_u8_subview(__param_self_: *const cstr, __param_u8pos: c_long, __param_u8len: c_long) -> csview {
    return cutf8_subview(cstr_str(__param_self_), __param_u8pos, __param_u8len)

}

unsafe fn cstr_u8_at(__param_self_: *const cstr, __param_u8pos: c_long) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8: cstr_iter_u8 { chr: csview { buf: cutf8_at(cstr_str(__param_self_), __param_u8pos) }, dec: cutf8_decode_t.zeroed() } }

    (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const i8)) as c_long)))

    if ((if (*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *const c_char)))
    }

    return __local_it_

}

unsafe fn cstr_begin(__param_self_: *const cstr) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8: cstr_iter_u8 { chr: csview { buf: cstr_str(__param_self_) }, dec: cutf8_decode_t.zeroed() } }

    if ((if (*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *const c_char)))
    } else {
        (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const i8)) as c_long)))
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
        ((*__param_it_).chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*__param_it_).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*__param_it_).ref, (null as *const i8)) as c_long)))
    }

}

fn cstr_advance(__param_it_: cstr_iter, __param_u8pos: c_long) -> cstr_iter {
    (__param_it_.ref = ((unsafe { cutf8_offset((*(&raw const __param_it_ as *const cstr_iter)).ref, __param_u8pos) } as *const c_char)))

    if ((if (unsafe *((*(&raw const __param_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *const c_char)))
    } else {
        (__param_it_.chr.size = ((unsafe { cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __param_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __param_it_ as *const cstr_iter)).ref, (null as *const i8)) } as c_long)))
    }

    return __param_it_

}

unsafe fn cstr_codepoint(__param_it_: *const cstr_iter) -> c_uint {
    return (*(&raw const (*__param_it_).u8.dec as *const cutf8_decode_t)).codep

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

unsafe fn cstr_tolower(__param_str: *const i8) -> cstr {
    return cstr_tolower_sv((csview { buf: __param_str, size: (strlen(__param_str) as c_long) } as csview))

}

unsafe fn cstr_toupper(__param_str: *const i8) -> cstr {
    return cstr_toupper_sv((csview { buf: __param_str, size: (strlen(__param_str) as c_long) } as csview))

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

unsafe fn cstr_iequals(__param_self_: *const cstr, __param_str: *const i8) -> bool {
    return ((not (cutf8_icmp(cstr_str(__param_self_), __param_str) != 0)))

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

unsafe fn cstr_equals(__param_self_: *const cstr, __param_str: *const i8) -> bool {
    return ((not (strcmp(cstr_str(__param_self_), __param_str) != 0)))

}

unsafe fn cstr_equals_sv(__param_self_: *const cstr, __param_sv: csview) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __param_sv as *const csview)).size == cstr_size(__param_self_): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sv as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sv as *const csview)).size else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn cstr_find(__param_self_: *const cstr, __param_search: *const i8) -> c_long {
    var __local_str: *const c_char = ((cstr_str(__param_self_) as *const c_char))

    var __local_res: *const c_char = ((strstr(((__local_str as *mut c_char) as *const i8), __param_search) as *const c_char))


    return (if __local_res != null: (((((__local_res as usize) -% (__local_str as usize)) as c_long) / (sizeof[c_char]() as c_long)) as c_long) else: (9223372036854775807 as c_long))

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
    var __local_str: *const c_char = ((cstr_str(__param_self_) as *const c_char))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((*__local_sub) != 0) {
            (__ci_expr_logic_0 = (if (if (*__local_str) == (*__local_sub): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_str = __local_str + 1)

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

unsafe fn cstr_assign(__param_self_: *mut cstr, __param_str: *const i8) -> *mut i8 {
    return ((cstr_assign_n(__param_self_, __param_str, (strlen(__param_str) as c_long)) as *mut i8))

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

unsafe fn cstr_append(__param_self_: *mut cstr, __param_str: *const i8) -> *mut i8 {
    return ((cstr_append_n(__param_self_, __param_str, (strlen(__param_str) as c_long)) as *mut i8))

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

unsafe fn cstr_insert(__param_self_: *mut cstr, __param_pos: c_long, __param_str: *const i8) {
    cstr_replace_at_sv(__param_self_, __param_pos, (0 as c_long), (csview { buf: __param_str, size: (strlen(__param_str) as c_long) } as csview))

}

unsafe fn cstr_u8_insert(__param_self_: *mut cstr, __param_u8pos: c_long, __param_str: *const i8) {
    cstr_insert(__param_self_, (cutf8_to_index(cstr_str((__param_self_ as *const cstr)), __param_u8pos) as c_long), __param_str)

}

unsafe fn cstr_getline(__param_self_: *mut cstr, __param_fp: *mut c_void) -> bool {
    return cstr_getdelim(__param_self_, (10 as c_int), __param_fp)

}

extern fn assert_str(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const i8, __param_real: *const i8, __param_caller: *const i8, __param_line: c_int)
extern fn assert_wstr(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_int, __param_real: *const c_int, __param_caller: *const i8, __param_line: c_int)
extern fn assert_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_interval(__param_diag: c_int, __param_low: c_long, __param_high: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_pointers(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const i8, __param_line: c_int)
extern fn assert_bool(__param_diag: c_int, __param_exp: bool, __param_real: bool, __param_caller: *const i8, __param_line: c_int)
extern fn assert_dbl_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const i8, __param_line: c_int)
extern fn assert_fail(__param_caller: *const i8, __param_line: c_int)
fn Intmap_clone(__param_map: Intmap) -> Intmap {
    if ((if (unsafe *(&raw const __param_map as *const Intmap)).bucket_count == 0: 1 else: 0) != 0) {
        return ((Intmap.zeroed() as Intmap))
    }

    var __local_out: Intmap = __param_map

    var __local_self_: *mut Intmap = ((&raw mut __local_out as *mut Intmap))


    var __local__mbytes: c_long = (((((unsafe *(&raw const __param_map as *const Intmap)).bucket_count + 1) * (sizeof[hmap_meta]() as c_long)) as c_long))

    (__local_out.table = (((with_alloc((((if 1 != 0: (((unsafe *(&raw const __param_map as *const Intmap)).bucket_count * (sizeof[Intmap_value]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_value)))

    (__local_out.meta = (((with_alloc((((if 1 != 0: __local__mbytes else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    var __ci_expr_logic_0: c_int = 0

    if ((unsafe *(&raw const __local_out as *const Intmap)).table != null) {
        (__ci_expr_logic_0 = (if (unsafe *(&raw const __local_out as *const Intmap)).meta != null: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy((((unsafe *(&raw const __local_out as *const Intmap)).meta as *mut c_void) as *mut u8), (((unsafe *(&raw const __param_map as *const Intmap)).meta as *const c_void) as *const u8), (((if 1 != 0: __local__mbytes else: (-1 as c_long)) as c_ulong) as i64))

        var __local_i: c_long = ((0 as c_long))

        while ((if __local_i < (unsafe *(&raw const __param_map as *const Intmap)).bucket_count: 1 else: 0) != 0) {
            if (((unsafe __param_map.meta[__local_i])).dist() != 0) {
                ((unsafe __local_out.table[__local_i]) = unsafe { Intmap_value_clone((__local_self_ as *const Intmap), ((*(&raw const __param_map as *const Intmap)).table[__local_i])) })
            }

            (__local_i = __local_i + 1)

        }


        return __local_out

    }
    if ((unsafe *(&raw const __local_out as *const Intmap)).meta != null) {
        with_free((((unsafe *(&raw const __local_out as *const Intmap)).meta as *mut c_void) as *mut u8))
    }

    if ((unsafe *(&raw const __local_out as *const Intmap)).table != null) {
        (sizeof[Intmap_value]() as usize)

        with_free((((unsafe *(&raw const __local_out as *const Intmap)).table as *mut c_void) as *mut u8))

    }

    return ((Intmap.zeroed() as Intmap))



}

unsafe fn Intmap_drop(__param_cself: *const Intmap) {
    var __local_self_: *mut Intmap = ((__param_cself as *mut Intmap))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    Intmap_wipe_(__local_self_)

    (sizeof[hmap_meta]() as usize)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))


    (sizeof[Intmap_value]() as usize)

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))


}

unsafe fn Intmap_clear(__param_self_: *mut Intmap) -> Unit {
    if ((if (*__param_self_).meta == null: 1 else: 0) != 0) {
        return
    }

    Intmap_wipe_(__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    with_memset((((*__param_self_).meta as *mut c_void) as *mut u8), (0 as c_int), (((if 1 != 0: (((sizeof[hmap_meta]() as c_long) * (*__param_self_).bucket_count) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

}

unsafe fn Intmap_reserve(__param__self: *mut Intmap, __param__cap: c_long) -> bool {
    var __local__newcap: c_long = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (*__param__self).size else: __param__cap) as c_long))

    var __local__newbucks: c_long = ((((((__local__newcap as f32) / i_max_load_factor) as c_long) + 4) as c_long))

    (__local__newbucks = ((c_next_pow2(__local__newbucks) as c_long)))

    var __ci_expr_logic_0: c_int

    if ((if __local__newbucks == (*__param__self).bucket_count: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param__cap <= (((((*__param__self).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return true
    }


    var __local_map: Intmap = (*__param__self)

    var __local_self_: *mut Intmap = ((&raw mut __local_map as *mut Intmap))



    (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[Intmap_value]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_value)))

    (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as c_long) else: (-1 as c_long)) as c_ulong) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    (__local_map.bucket_count = __local__newbucks)

    var __local_ok: bool = with 0 as __ci_expr_seq_26 {
        var __ci_expr_logic_1: c_int = 0
        if ((*(&raw const __local_map as *const Intmap)).table != null) {
            (__ci_expr_logic_1 = (if (*(&raw const __local_map as *const Intmap)).meta != null: 1 else: 0))
        }
        (__ci_expr_logic_1 != 0)
    }

    if __local_ok {
        ((__local_map.meta[__local__newbucks])).set_dist(((1023 as c_ushort)))

        var __local_d: *const Intmap_value = (((*__param__self).table as *const Intmap_value))

        var __local_m: *const hmap_meta = (((*__param__self).meta as *const hmap_meta))

        var __local_i: c_long = ((0 as c_long))

        while ((if __local_i < (*__param__self).bucket_count: 1 else: 0) != 0) {
            if ((if ((__local_m[__local_i])).dist() != 0: 1 else: 0) != 0) {
                var __local_r: c_int = (*(&raw const (*__local_d).first as *const c_int))

                with_memcpy((&raw mut (*(Intmap_bucket_insert_(((&raw mut __local_map as *mut Intmap) as *const Intmap), ((&raw mut __local_r as *mut c_int) as *const c_int)).ref)) as *mut u8), (&raw const (*__local_d) as *const u8), sizeof[Intmap_value]())

            }

            (__local_i = __local_i + 1)

            (__local_d = __local_d + 1)


        }


        loop {
            var __local__xp: *mut Intmap = __param__self

            var __local__yp: *mut Intmap = ((&raw mut __local_map as *mut Intmap))


            var __local__tv: Intmap = (*__local__xp)

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

    }

    (sizeof[hmap_meta]() as usize)

    with_free((((*(&raw const __local_map as *const Intmap)).meta as *mut c_void) as *mut u8))


    (sizeof[Intmap_value]() as usize)

    with_free((((*(&raw const __local_map as *const Intmap)).table as *mut c_void) as *mut u8))


    return __local_ok

}

unsafe fn Intmap_erase_entry(__param_self_: *mut Intmap, __param__val: *mut Intmap_value) {
    var __local_d: *mut Intmap_value = (*__param_self_).table

    var __local_m: *mut hmap_meta = (*__param_self_).meta

    var __local_i: c_ulong = ((((((__param__val as usize) -% (__local_d as usize)) as c_long) / (sizeof[Intmap_value]() as c_long)) as c_ulong))

    var __local_j: c_ulong = __local_i


    var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    Intmap_value_drop((__param_self_ as *const Intmap), __param__val)

    while true {
        (__local_j = ((((((__local_j as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

        if ((if ((__local_m[__local_j])).dist() < 2: 1 else: 0) != 0) {
            break
        }

        ((__local_d[__local_i]) = (__local_d[__local_j]))

        ((__local_m[__local_i]) = (__local_m[__local_j]))

        ((__local_m[__local_i])).set_dist((((__local_m[__local_i])).dist() -% 1))

        (__local_i = __local_j)

    }

    ((__local_m[__local_i])).set_dist(((0 as c_ushort)))

    ((*__param_self_).size = (*__param_self_).size - 1)

}

unsafe fn Intmap_max_load_factor(__param_self_: *const Intmap) -> f32 {

    return i_max_load_factor

}

unsafe fn Intmap_capacity(__param_map: *const Intmap) -> c_long {
    return (((((*__param_map).bucket_count as f32) * i_max_load_factor) as c_long))

}

unsafe fn Intmap_bucket_lookup_(__param_self_: *const Intmap, __param_rkeyptr: *const c_int) -> Intmap_result {
    var __local__hash: c_ulong = ((c_hash_n((__param_rkeyptr as *const c_void), (4 as c_long)) as c_ulong))

    var __local__idxmask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    var __local__res: Intmap_result = Intmap_result { idx: ((__local__hash as c_ulong) & (__local__idxmask as c_ulong)), hashx: (((((((__local__hash as c_ulong) >> (24 as c_uint))) as c_ulong) & (63 as c_ulong))) as u8), dist: 1 }

    while ((if (*(&raw const __local__res as *const Intmap_result)).dist <= (((*__param_self_).meta[(*(&raw const __local__res as *const Intmap_result)).idx])).dist(): 1 else: 0) != 0) {
        if ((if (((*__param_self_).meta[(*(&raw const __local__res as *const Intmap_result)).idx])).hashx() == (*(&raw const __local__res as *const Intmap_result)).hashx: 1 else: 0) != 0) {
            var __local__raw: c_int = (*((&raw const (*((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const Intmap_result)).idx]) as *const Intmap_value) as *mut Intmap_value)).first as *const c_int) as *mut c_int))

            if ((if (*(&raw const __local__raw as *const c_int)) == (*__param_rkeyptr): 1 else: 0) != 0) {
                (__local__res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const Intmap_result)).idx]) as *const Intmap_value) as *mut Intmap_value)))

                break

            }

        }

        (__local__res.idx = (((((((*(&raw const __local__res as *const Intmap_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local__idxmask as c_ulong)) as c_ulong)))

        (__local__res.dist = ((*(&raw const __local__res as *const Intmap_result)).dist +% 1))

    }

    return __local__res

}

unsafe fn Intmap_bucket_insert_(__param_self_: *const Intmap, __param_rkeyptr: *const c_int) -> Intmap_result {
    var __local_res: Intmap_result = Intmap_bucket_lookup_(__param_self_, __param_rkeyptr)

    if ((*(&raw const __local_res as *const Intmap_result)).ref != null) {
        return __local_res
    }

    (__local_res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const Intmap_result)).idx]) as *const Intmap_value) as *mut Intmap_value)))

    (__local_res.inserted = true)

    var __local_mnew: hmap_meta = with 0 as __ci_bits_seq_59 { var __ci_bits: hmap_meta = hmap_meta.zeroed(); __ci_bits.set_hashx((((((((*(&raw const __local_res as *const Intmap_result)).hashx as c_uint) as c_int) as c_uint) & (63 as c_uint))) as c_ushort)); __ci_bits.set_dist((((((((*(&raw const __local_res as *const Intmap_result)).dist as c_uint) as c_int) as c_uint) & (1023 as c_uint))) as c_ushort)); __ci_bits }

    var __local_mcur: hmap_meta = ((*__param_self_).meta[(*(&raw const __local_res as *const Intmap_result)).idx])

    (((*__param_self_).meta[(*(&raw const __local_res as *const Intmap_result)).idx]) = __local_mnew)

    if ((if __local_mcur.dist() != 0: 1 else: 0) != 0) {
        var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

        var __local_dcur: Intmap_value = (*((*(&raw const __local_res as *const Intmap_result)).ref))

        while true {
            (__local_res.idx = (((((((*(&raw const __local_res as *const Intmap_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

            __local_mcur.set_dist((__local_mcur.dist() +% 1))

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const Intmap_result)).idx])).dist() == 0: 1 else: 0) != 0) {
                break
            }

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const Intmap_result)).idx])).dist() < __local_mcur.dist(): 1 else: 0) != 0) {
                loop {
                    var __local__xp: *mut hmap_meta = ((&raw mut __local_mcur as *mut hmap_meta))

                    var __local__yp: *mut hmap_meta = (((&raw const ((*__param_self_).meta[(*(&raw const __local_res as *const Intmap_result)).idx]) as *const hmap_meta) as *mut hmap_meta))


                    var __local__tv: hmap_meta = (*__local__xp)

                    ((*__local__xp) = (*__local__yp))

                    ((*__local__yp) = __local__tv)

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_1: *mut Intmap_value = ((&raw mut __local_dcur as *mut Intmap_value))

                    var __local__yp_1: *mut Intmap_value = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const Intmap_result)).idx]) as *const Intmap_value) as *mut Intmap_value))


                    var __local__tv_1: Intmap_value = (*__local__xp_1)

                    ((*__local__xp_1) = (*__local__yp_1))

                    ((*__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

        }

        (((*__param_self_).meta[(*(&raw const __local_res as *const Intmap_result)).idx]) = __local_mcur)

        (((*__param_self_).table[(*(&raw const __local_res as *const Intmap_result)).idx]) = __local_dcur)

    }

    return __local_res

}

unsafe fn Intmap_is_empty(__param_map: *const Intmap) -> bool {
    return ((not ((*__param_map).size != 0)))

}

unsafe fn Intmap_size(__param_map: *const Intmap) -> c_long {
    return (*__param_map).size

}

unsafe fn Intmap_bucket_count(__param_map: *mut Intmap) -> c_long {
    return (*__param_map).bucket_count

}

unsafe fn Intmap_contains(__param_self_: *const Intmap, __param_rkey: c_int) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if Intmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut c_int) as *const c_int)).ref != null: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn Intmap_shrink_to_fit(__param_self_: *mut Intmap) -> Unit {
    Intmap_reserve(__param_self_, (9223372036854775807 as c_long))

}

unsafe fn Intmap_insert_entry_(__param_self_: *mut Intmap, __param_rkey: c_int) -> Intmap_result {
    if ((if (*__param_self_).size >= (((((*__param_self_).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0) {
        if ((if not Intmap_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 2) as c_long)): 1 else: 0) != 0) {
            return ((Intmap_result.zeroed() as Intmap_result))
        }
    }

    var __local_res: Intmap_result = Intmap_bucket_insert_((__param_self_ as *const Intmap), ((&raw mut __param_rkey as *mut c_int) as *const c_int))

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const Intmap_result)).inserted as c_int))

    return __local_res

}

unsafe fn Intmap_insert_or_assign(__param_self_: *mut Intmap, __param__key: c_int, __param__mapped: c_int) -> Intmap_result {
    var __local__res: Intmap_result = Intmap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut c_int)))

    var __local__mp: *mut c_int = (if (*(&raw const __local__res as *const Intmap_result)).ref != null: ((&raw const (*(*(&raw const __local__res as *const Intmap_result)).ref).second as *const c_int) as *mut c_int) else: (&raw mut __param__mapped as *mut c_int))

    if (*(&raw const __local__res as *const Intmap_result)).inserted {
        ((*(*(&raw const __local__res as *const Intmap_result)).ref).first = __param__key)
    } else {


    }

    ((*__local__mp) = __param__mapped)

    return __local__res

}

unsafe fn Intmap_at(__param_self_: *const Intmap, __param_rkey: c_int) -> *const c_int {
    var __local_res: Intmap_result = Intmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut c_int) as *const c_int))

    if (((if not ((*(&raw const __local_res as *const Intmap_result)).ref != null): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Intmap_at".ptr, c"hmap.h".ptr, (136 as c_int), c"res.ref".ptr)
    } else {
        0
    }

    return ((((&raw const (*(*(&raw const __local_res as *const Intmap_result)).ref).second as *const c_int) as *mut c_int) as *const c_int))

}

unsafe fn Intmap_at_mut(__param_self_: *mut Intmap, __param_rkey: c_int) -> *mut c_int {
    return ((Intmap_at((__param_self_ as *const Intmap), __param_rkey) as *mut c_int))

}

unsafe fn Intmap_copy(__param_self_: *mut Intmap, __param_other: *const Intmap) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Intmap_drop((__param_self_ as *const Intmap))

    let __ci_copy_18: Intmap = Intmap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[Intmap]())

}

unsafe fn Intmap_value_clone(__param_self_: *const Intmap, __param__val: Intmap_value) -> Intmap_value {

    ((*((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const c_int) as *mut c_int)) = (*((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const c_int) as *mut c_int)))

    (__param__val.second = (*(&raw const __param__val as *const Intmap_value)).second)

    return __param__val

}

unsafe fn Intmap_value_toraw(__param_val: *const Intmap_value) -> Intmap_raw {
    return ((Intmap_raw { first: ((*(&raw const (*__param_val).first as *const c_int))), second: ((*(&raw const (*__param_val).second as *const c_int))) } as Intmap_raw))

}

unsafe fn Intmap_value_drop(__param_self_: *const Intmap, __param__val: *mut Intmap_value) {
    return
}

unsafe fn Intmap_move(__param_self_: *mut Intmap) -> Intmap {
    var __local_m: Intmap = (*__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    ((*__param_self_).bucket_count = (*__param_self_).size)


    ((*__param_self_).meta = ((null as *mut hmap_meta)))

    ((*__param_self_).table = ((null as *mut Intmap_value)))

    return __local_m

}

unsafe fn Intmap_take(__param_self_: *mut Intmap, __param_unowned: Intmap) -> Unit {
    Intmap_drop((__param_self_ as *const Intmap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Intmap]())

}

unsafe fn Intmap_insert(__param_self_: *mut Intmap, __param__key: c_int, __param__mapped: c_int) -> Intmap_result {
    var __local__res: Intmap_result = Intmap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut c_int)))

    if (*(&raw const __local__res as *const Intmap_result)).inserted {
        ((*((&raw const (*(*(&raw const __local__res as *const Intmap_result)).ref).first as *const c_int) as *mut c_int)) = __param__key)

        ((*(*(&raw const __local__res as *const Intmap_result)).ref).second = __param__mapped)

    } else {


    }

    return __local__res

}

unsafe fn Intmap_push(__param_self_: *mut Intmap, __param__val: Intmap_value) -> *mut Intmap_value {
    var __local__res: Intmap_result = Intmap_insert_entry_(__param_self_, (*((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const c_int) as *mut c_int)))

    if ((if not (*(&raw const __local__res as *const Intmap_result)).inserted: 1 else: 0) != 0) {
        Intmap_value_drop((__param_self_ as *const Intmap), (*(&raw const __local__res as *const Intmap_result)).ref)
    }

    with_memcpy((&raw mut (*((*(&raw const __local__res as *const Intmap_result)).ref)) as *mut u8), (&raw const __param__val as *const u8), sizeof[Intmap_value]())

    return (*(&raw const __local__res as *const Intmap_result)).ref

}

unsafe fn Intmap_put(__param_self_: *mut Intmap, __param_rkey: c_int, __param_rmapped: c_int) -> Intmap_result {
    return Intmap_insert_or_assign(__param_self_, __param_rkey, __param_rmapped)

}

unsafe fn Intmap_put_n(__param_self_: *mut Intmap, __param_raw: *const Intmap_raw, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        Intmap_put(__param_self_, (*__local_raw).first, (*__local_raw).second)

        (__local_raw = __local_raw + 1)

    }

}

fn Intmap_init() -> Intmap {
    var __local_cx: Intmap = Intmap.zeroed()

    return __local_cx

}

unsafe fn Intmap_from_n(__param_raw: *const Intmap_raw, __param_n: c_long) -> Intmap {
    var __local_cx: Intmap = Intmap.zeroed()

    Intmap_put_n((&raw mut __local_cx as *mut Intmap), __param_raw, __param_n)

    return __local_cx

}

fn Intmap_with_capacity(__param_cap: c_long) -> Intmap {
    var __local_cx: Intmap = Intmap.zeroed()

    unsafe { Intmap_reserve((&raw mut __local_cx as *mut Intmap), __param_cap) }

    return __local_cx

}

unsafe fn Intmap_begin(__param_self_: *const Intmap) -> Intmap_iter {
    var __local_it_: Intmap_iter = Intmap_iter { ref: (*__param_self_).table, _end: (*__param_self_).table, _mref: (*__param_self_).meta }

    if ((if (*(&raw const __local_it_ as *const Intmap_iter)).ref == null: 1 else: 0) != 0) {
        return __local_it_
    }

    (__local_it_._end = (*(&raw const __local_it_ as *const Intmap_iter))._end + (((*__param_self_).bucket_count as c_long) as usize))

    while ((if (*(*(&raw const __local_it_ as *const Intmap_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const Intmap_iter)).ref + 1)

        (__local_it_._mref = (*(&raw const __local_it_ as *const Intmap_iter))._mref + 1)

    }

    if ((if (*(&raw const __local_it_ as *const Intmap_iter)).ref == (*(&raw const __local_it_ as *const Intmap_iter))._end: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *mut Intmap_value)))
    }

    return __local_it_

}

unsafe fn Intmap_end(__param_self_: *const Intmap) -> Intmap_iter {

    return ((Intmap_iter.zeroed() as Intmap_iter))

}

unsafe fn Intmap_next(__param_it_: *mut Intmap_iter) {
    while true {
        ((*__param_it_).ref = (*__param_it_).ref + 1)

        ((*__param_it_)._mref = (*__param_it_)._mref + 1)

        if (not ((if (*(*__param_it_)._mref).dist() == 0: 1 else: 0) != 0)) {
            break
        }

    }

    if ((if (*__param_it_).ref == (*__param_it_)._end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut Intmap_value)))
    }

}

fn Intmap_advance(__param_it_: Intmap_iter, __param_n: c_ulong) -> Intmap_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const Intmap_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { Intmap_next((&raw mut __param_it_ as *mut Intmap_iter)) }

    }

    return __param_it_

}

unsafe fn Intmap_find(__param_self_: *const Intmap, __param_rkey: c_int) -> Intmap_iter {
    var __local_ref: *mut Intmap_value

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = Intmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut c_int) as *const c_int)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((Intmap_iter { ref: __local_ref, _end: ((&raw const ((*__param_self_).table[(*__param_self_).bucket_count]) as *const Intmap_value) as *mut Intmap_value), _mref: ((&raw const ((*__param_self_).meta[((((__local_ref as usize) -% ((*__param_self_).table as usize)) as c_long) / (sizeof[Intmap_value]() as c_long))]) as *const hmap_meta) as *mut hmap_meta) } as Intmap_iter))
    }


    return Intmap_end(__param_self_)

}

unsafe fn Intmap_get(__param_self_: *const Intmap, __param_rkey: c_int) -> *const Intmap_value {
    return (((if (*__param_self_).size != 0: Intmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut c_int) as *const c_int)).ref else: (null as *mut Intmap_value)) as *const Intmap_value))

}

unsafe fn Intmap_get_mut(__param_self_: *mut Intmap, __param_rkey: c_int) -> *mut Intmap_value {
    return ((Intmap_get((__param_self_ as *const Intmap), __param_rkey) as *mut Intmap_value))

}

unsafe fn Intmap_erase(__param_self_: *mut Intmap, __param_rkey: c_int) -> c_int {
    var __local_ref: *mut Intmap_value

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = Intmap_bucket_lookup_((__param_self_ as *const Intmap), ((&raw mut __param_rkey as *mut c_int) as *const c_int)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        Intmap_erase_entry(__param_self_, __local_ref)

        return 1

    }


    return 0

}

unsafe fn Intmap_erase_at(__param_self_: *mut Intmap, __param_it_: Intmap_iter) -> Intmap_iter {
    Intmap_erase_entry(__param_self_, (*(&raw const __param_it_ as *const Intmap_iter)).ref)

    if ((if (*(*(&raw const __param_it_ as *const Intmap_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        Intmap_next((&raw mut __param_it_ as *mut Intmap_iter))
    }

    return __param_it_

}

unsafe fn Intmap_eq(__param_self_: *const Intmap, __param_other: *const Intmap) -> bool {
    if ((if Intmap_size(__param_self_) != Intmap_size(__param_other): 1 else: 0) != 0) {
        return false
    }

    var __local_i: Intmap_iter = Intmap_begin(__param_self_)

    while ((*(&raw const __local_i as *const Intmap_iter)).ref != null) {
        var __local__raw: c_int = (*((&raw const (*(*(&raw const __local_i as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))

        if ((if not Intmap_contains(__param_other, __local__raw): 1 else: 0) != 0) {
            return false
        }


        Intmap_next((&raw mut __local_i as *mut Intmap_iter))

    }


    return true

}

unsafe fn Intmap_wipe_(__param_self_: *mut Intmap) {
    var __local_d: *mut Intmap_value = (*__param_self_).table

    var __local_m: *const hmap_meta = (((*__param_self_).meta as *const hmap_meta))

    var __local_n: c_long = (*__param_self_).bucket_count

    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const hmap_meta = __local_m

        (__local_m = __local_m + 1)

        if ((*__ci_expr_old_0).dist() != 0) {
            Intmap_value_drop((__param_self_ as *const Intmap), ((&raw const (__local_d[__local_i]) as *const Intmap_value) as *mut Intmap_value))
        }


        (__local_i = __local_i + 1)

    }


}

fn ctest_hashmap_mapdemo1_run() {
    var __local_nums: Intmap = Intmap.zeroed()

    unsafe { Intmap_insert((&raw mut __local_nums as *mut Intmap), (8 as c_int), (64 as c_int)) }

    unsafe { Intmap_insert((&raw mut __local_nums as *mut Intmap), (11 as c_int), (121 as c_int)) }

    assert_compare((1 as c_int), c"==".ptr, (64 as c_long), ((unsafe *unsafe { Intmap_at(((&raw mut __local_nums as *mut Intmap) as *const Intmap), (8 as c_int)) }) as c_long), c"hmap_test.c".ptr, (13 as c_int))

    unsafe { Intmap_drop(((&raw mut __local_nums as *mut Intmap) as *const Intmap)) }

}

fn SImap_clone(__param_map: SImap) -> SImap {
    if ((if (unsafe *(&raw const __param_map as *const SImap)).bucket_count == 0: 1 else: 0) != 0) {
        return ((SImap.zeroed() as SImap))
    }

    var __local_out: SImap = __param_map

    var __local_self_: *mut SImap = ((&raw mut __local_out as *mut SImap))


    var __local__mbytes: c_long = (((((unsafe *(&raw const __param_map as *const SImap)).bucket_count + 1) * (sizeof[hmap_meta]() as c_long)) as c_long))

    (__local_out.table = (((with_alloc((((if 1 != 0: (((unsafe *(&raw const __param_map as *const SImap)).bucket_count * (sizeof[SImap_value]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut SImap_value)))

    (__local_out.meta = (((with_alloc((((if 1 != 0: __local__mbytes else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    var __ci_expr_logic_0: c_int = 0

    if ((unsafe *(&raw const __local_out as *const SImap)).table != null) {
        (__ci_expr_logic_0 = (if (unsafe *(&raw const __local_out as *const SImap)).meta != null: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy((((unsafe *(&raw const __local_out as *const SImap)).meta as *mut c_void) as *mut u8), (((unsafe *(&raw const __param_map as *const SImap)).meta as *const c_void) as *const u8), (((if 1 != 0: __local__mbytes else: (-1 as c_long)) as c_ulong) as i64))

        var __local_i: c_long = ((0 as c_long))

        while ((if __local_i < (unsafe *(&raw const __param_map as *const SImap)).bucket_count: 1 else: 0) != 0) {
            if (((unsafe __param_map.meta[__local_i])).dist() != 0) {
                ((unsafe __local_out.table[__local_i]) = unsafe { SImap_value_clone((__local_self_ as *const SImap), ((*(&raw const __param_map as *const SImap)).table[__local_i])) })
            }

            (__local_i = __local_i + 1)

        }


        return __local_out

    }
    if ((unsafe *(&raw const __local_out as *const SImap)).meta != null) {
        with_free((((unsafe *(&raw const __local_out as *const SImap)).meta as *mut c_void) as *mut u8))
    }

    if ((unsafe *(&raw const __local_out as *const SImap)).table != null) {
        (sizeof[SImap_value]() as usize)

        with_free((((unsafe *(&raw const __local_out as *const SImap)).table as *mut c_void) as *mut u8))

    }

    return ((SImap.zeroed() as SImap))



}

unsafe fn SImap_drop(__param_cself: *const SImap) {
    var __local_self_: *mut SImap = ((__param_cself as *mut SImap))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    SImap_wipe_(__local_self_)

    (sizeof[hmap_meta]() as usize)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))


    (sizeof[SImap_value]() as usize)

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))


}

unsafe fn SImap_clear(__param_self_: *mut SImap) -> Unit {
    if ((if (*__param_self_).meta == null: 1 else: 0) != 0) {
        return
    }

    SImap_wipe_(__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    with_memset((((*__param_self_).meta as *mut c_void) as *mut u8), (0 as c_int), (((if 1 != 0: (((sizeof[hmap_meta]() as c_long) * (*__param_self_).bucket_count) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

}

unsafe fn SImap_reserve(__param__self: *mut SImap, __param__cap: c_long) -> bool {
    var __local__newcap: c_long = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (*__param__self).size else: __param__cap) as c_long))

    var __local__newbucks: c_long = ((((((__local__newcap as f32) / i_max_load_factor) as c_long) + 4) as c_long))

    (__local__newbucks = ((c_next_pow2(__local__newbucks) as c_long)))

    var __ci_expr_logic_0: c_int

    if ((if __local__newbucks == (*__param__self).bucket_count: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param__cap <= (((((*__param__self).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return true
    }


    var __local_map: SImap = (*__param__self)

    var __local_self_: *mut SImap = ((&raw mut __local_map as *mut SImap))



    (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[SImap_value]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut SImap_value)))

    (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as c_long) else: (-1 as c_long)) as c_ulong) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    (__local_map.bucket_count = __local__newbucks)

    var __local_ok: bool = with 0 as __ci_expr_seq_26 {
        var __ci_expr_logic_1: c_int = 0
        if ((*(&raw const __local_map as *const SImap)).table != null) {
            (__ci_expr_logic_1 = (if (*(&raw const __local_map as *const SImap)).meta != null: 1 else: 0))
        }
        (__ci_expr_logic_1 != 0)
    }

    if __local_ok {
        ((__local_map.meta[__local__newbucks])).set_dist(((1023 as c_ushort)))

        var __local_d: *const SImap_value = (((*__param__self).table as *const SImap_value))

        var __local_m: *const hmap_meta = (((*__param__self).meta as *const hmap_meta))

        var __local_i: c_long = ((0 as c_long))

        while ((if __local_i < (*__param__self).bucket_count: 1 else: 0) != 0) {
            if ((if ((__local_m[__local_i])).dist() != 0: 1 else: 0) != 0) {
                var __local_r: *const i8 = cstr_toraw((&raw const (*__local_d).first as *const cstr))

                with_memcpy((&raw mut (*(SImap_bucket_insert_(((&raw mut __local_map as *mut SImap) as *const SImap), ((&raw mut __local_r as *mut *const i8) as *const *const i8)).ref)) as *mut u8), (&raw const (*__local_d) as *const u8), sizeof[SImap_value]())

            }

            (__local_i = __local_i + 1)

            (__local_d = __local_d + 1)


        }


        loop {
            var __local__xp: *mut SImap = __param__self

            var __local__yp: *mut SImap = ((&raw mut __local_map as *mut SImap))


            var __local__tv: SImap = (*__local__xp)

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

    }

    (sizeof[hmap_meta]() as usize)

    with_free((((*(&raw const __local_map as *const SImap)).meta as *mut c_void) as *mut u8))


    (sizeof[SImap_value]() as usize)

    with_free((((*(&raw const __local_map as *const SImap)).table as *mut c_void) as *mut u8))


    return __local_ok

}

unsafe fn SImap_erase_entry(__param_self_: *mut SImap, __param__val: *mut SImap_value) {
    var __local_d: *mut SImap_value = (*__param_self_).table

    var __local_m: *mut hmap_meta = (*__param_self_).meta

    var __local_i: c_ulong = ((((((__param__val as usize) -% (__local_d as usize)) as c_long) / (sizeof[SImap_value]() as c_long)) as c_ulong))

    var __local_j: c_ulong = __local_i


    var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    SImap_value_drop((__param_self_ as *const SImap), __param__val)

    while true {
        (__local_j = ((((((__local_j as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

        if ((if ((__local_m[__local_j])).dist() < 2: 1 else: 0) != 0) {
            break
        }

        ((__local_d[__local_i]) = (__local_d[__local_j]))

        ((__local_m[__local_i]) = (__local_m[__local_j]))

        ((__local_m[__local_i])).set_dist((((__local_m[__local_i])).dist() -% 1))

        (__local_i = __local_j)

    }

    ((__local_m[__local_i])).set_dist(((0 as c_ushort)))

    ((*__param_self_).size = (*__param_self_).size - 1)

}

unsafe fn SImap_max_load_factor(__param_self_: *const SImap) -> f32 {

    return i_max_load_factor

}

unsafe fn SImap_capacity(__param_map: *const SImap) -> c_long {
    return (((((*__param_map).bucket_count as f32) * i_max_load_factor) as c_long))

}

unsafe fn SImap_bucket_lookup_(__param_self_: *const SImap, __param_rkeyptr: *const *const i8) -> SImap_result {
    var __local__hash: c_ulong = ((c_hash_str((*__param_rkeyptr)) as c_ulong))

    var __local__idxmask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    var __local__res: SImap_result = SImap_result { idx: ((__local__hash as c_ulong) & (__local__idxmask as c_ulong)), hashx: (((((((__local__hash as c_ulong) >> (24 as c_uint))) as c_ulong) & (63 as c_ulong))) as u8), dist: 1 }

    while ((if (*(&raw const __local__res as *const SImap_result)).dist <= (((*__param_self_).meta[(*(&raw const __local__res as *const SImap_result)).idx])).dist(): 1 else: 0) != 0) {
        if ((if (((*__param_self_).meta[(*(&raw const __local__res as *const SImap_result)).idx])).hashx() == (*(&raw const __local__res as *const SImap_result)).hashx: 1 else: 0) != 0) {
            var __local__raw: *const i8 = cstr_toraw((((&raw const (*((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const SImap_result)).idx]) as *const SImap_value) as *mut SImap_value)).first as *const cstr) as *mut cstr) as *const cstr))

            if ((if strcmp((*(&raw const __local__raw as *const *const i8)), (*__param_rkeyptr)) == 0: 1 else: 0) != 0) {
                (__local__res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const SImap_result)).idx]) as *const SImap_value) as *mut SImap_value)))

                break

            }

        }

        (__local__res.idx = (((((((*(&raw const __local__res as *const SImap_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local__idxmask as c_ulong)) as c_ulong)))

        (__local__res.dist = ((*(&raw const __local__res as *const SImap_result)).dist +% 1))

    }

    return __local__res

}

unsafe fn SImap_bucket_insert_(__param_self_: *const SImap, __param_rkeyptr: *const *const i8) -> SImap_result {
    var __local_res: SImap_result = SImap_bucket_lookup_(__param_self_, __param_rkeyptr)

    if ((*(&raw const __local_res as *const SImap_result)).ref != null) {
        return __local_res
    }

    (__local_res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const SImap_result)).idx]) as *const SImap_value) as *mut SImap_value)))

    (__local_res.inserted = true)

    var __local_mnew: hmap_meta = with 0 as __ci_bits_seq_59 { var __ci_bits: hmap_meta = hmap_meta.zeroed(); __ci_bits.set_hashx((((((((*(&raw const __local_res as *const SImap_result)).hashx as c_uint) as c_int) as c_uint) & (63 as c_uint))) as c_ushort)); __ci_bits.set_dist((((((((*(&raw const __local_res as *const SImap_result)).dist as c_uint) as c_int) as c_uint) & (1023 as c_uint))) as c_ushort)); __ci_bits }

    var __local_mcur: hmap_meta = ((*__param_self_).meta[(*(&raw const __local_res as *const SImap_result)).idx])

    (((*__param_self_).meta[(*(&raw const __local_res as *const SImap_result)).idx]) = __local_mnew)

    if ((if __local_mcur.dist() != 0: 1 else: 0) != 0) {
        var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

        var __local_dcur: SImap_value = (*((*(&raw const __local_res as *const SImap_result)).ref))

        while true {
            (__local_res.idx = (((((((*(&raw const __local_res as *const SImap_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

            __local_mcur.set_dist((__local_mcur.dist() +% 1))

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const SImap_result)).idx])).dist() == 0: 1 else: 0) != 0) {
                break
            }

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const SImap_result)).idx])).dist() < __local_mcur.dist(): 1 else: 0) != 0) {
                loop {
                    var __local__xp: *mut hmap_meta = ((&raw mut __local_mcur as *mut hmap_meta))

                    var __local__yp: *mut hmap_meta = (((&raw const ((*__param_self_).meta[(*(&raw const __local_res as *const SImap_result)).idx]) as *const hmap_meta) as *mut hmap_meta))


                    var __local__tv: hmap_meta = (*__local__xp)

                    ((*__local__xp) = (*__local__yp))

                    ((*__local__yp) = __local__tv)

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_1: *mut SImap_value = ((&raw mut __local_dcur as *mut SImap_value))

                    var __local__yp_1: *mut SImap_value = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const SImap_result)).idx]) as *const SImap_value) as *mut SImap_value))


                    var __local__tv_1: SImap_value = (*__local__xp_1)

                    ((*__local__xp_1) = (*__local__yp_1))

                    ((*__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

        }

        (((*__param_self_).meta[(*(&raw const __local_res as *const SImap_result)).idx]) = __local_mcur)

        (((*__param_self_).table[(*(&raw const __local_res as *const SImap_result)).idx]) = __local_dcur)

    }

    return __local_res

}

unsafe fn SImap_is_empty(__param_map: *const SImap) -> bool {
    return ((not ((*__param_map).size != 0)))

}

unsafe fn SImap_size(__param_map: *const SImap) -> c_long {
    return (*__param_map).size

}

unsafe fn SImap_bucket_count(__param_map: *mut SImap) -> c_long {
    return (*__param_map).bucket_count

}

unsafe fn SImap_contains(__param_self_: *const SImap, __param_rkey: *const i8) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if SImap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref != null: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn SImap_shrink_to_fit(__param_self_: *mut SImap) -> Unit {
    SImap_reserve(__param_self_, (9223372036854775807 as c_long))

}

unsafe fn SImap_insert_entry_(__param_self_: *mut SImap, __param_rkey: *const i8) -> SImap_result {
    if ((if (*__param_self_).size >= (((((*__param_self_).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0) {
        if ((if not SImap_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 2) as c_long)): 1 else: 0) != 0) {
            return ((SImap_result.zeroed() as SImap_result))
        }
    }

    var __local_res: SImap_result = SImap_bucket_insert_((__param_self_ as *const SImap), ((&raw mut __param_rkey as *mut *const i8) as *const *const i8))

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const SImap_result)).inserted as c_int))

    return __local_res

}

unsafe fn SImap_insert_or_assign(__param_self_: *mut SImap, __param__key: cstr, __param__mapped: c_int) -> SImap_result {
    var __local__res: SImap_result = SImap_insert_entry_(__param_self_, cstr_toraw(((&raw mut __param__key as *mut cstr) as *const cstr)))

    var __local__mp: *mut c_int = (if (*(&raw const __local__res as *const SImap_result)).ref != null: ((&raw const (*(*(&raw const __local__res as *const SImap_result)).ref).second as *const c_int) as *mut c_int) else: (&raw mut __param__mapped as *mut c_int))

    if (*(&raw const __local__res as *const SImap_result)).inserted {
        with_memcpy((&raw mut (*(*(&raw const __local__res as *const SImap_result)).ref).first as *mut u8), (&raw const __param__key as *const u8), sizeof[cstr]())
    } else {
        cstr_drop(((&raw mut __param__key as *mut cstr) as *const cstr))


    }

    ((*__local__mp) = __param__mapped)

    return __local__res

}

unsafe fn SImap_emplace_or_assign(__param_self_: *mut SImap, __param_rkey: *const i8, __param_rmapped: c_int) -> SImap_result {
    var __local__res: SImap_result = SImap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local__res as *const SImap_result)).inserted {
        let __ci_copy_12: cstr = cstr_from(__param_rkey)
        with_memcpy((&raw mut (*(*(&raw const __local__res as *const SImap_result)).ref).first as *mut u8), (&raw const __ci_copy_12 as *const u8), sizeof[cstr]())
    } else {
        if ((if (*(&raw const __local__res as *const SImap_result)).ref == null: 1 else: 0) != 0) {
            return __local__res
        }


    }

    ((*(*(&raw const __local__res as *const SImap_result)).ref).second = __param_rmapped)

    return __local__res

}

unsafe fn SImap_at(__param_self_: *const SImap, __param_rkey: *const i8) -> *const c_int {
    var __local_res: SImap_result = SImap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8))

    if (((if not ((*(&raw const __local_res as *const SImap_result)).ref != null): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"SImap_at".ptr, c"hmap.h".ptr, (136 as c_int), c"res.ref".ptr)
    } else {
        0
    }

    return ((((&raw const (*(*(&raw const __local_res as *const SImap_result)).ref).second as *const c_int) as *mut c_int) as *const c_int))

}

unsafe fn SImap_at_mut(__param_self_: *mut SImap, __param_rkey: *const i8) -> *mut c_int {
    return ((SImap_at((__param_self_ as *const SImap), __param_rkey) as *mut c_int))

}

unsafe fn SImap_copy(__param_self_: *mut SImap, __param_other: *const SImap) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    SImap_drop((__param_self_ as *const SImap))

    let __ci_copy_18: SImap = SImap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[SImap]())

}

unsafe fn SImap_value_clone(__param_self_: *const SImap, __param__val: SImap_value) -> SImap_value {

    let __ci_copy_18: cstr = cstr_clone((*((&raw const (*(&raw mut __param__val as *mut SImap_value)).first as *const cstr) as *mut cstr)))
    with_memcpy((&raw mut (*((&raw const (*(&raw mut __param__val as *mut SImap_value)).first as *const cstr) as *mut cstr)) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[cstr]())

    (__param__val.second = (*(&raw const __param__val as *const SImap_value)).second)

    return __param__val

}

unsafe fn SImap_emplace(__param_self_: *mut SImap, __param_rkey: *const i8, __param_rmapped: c_int) -> SImap_result {
    var __local__res: SImap_result = SImap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local__res as *const SImap_result)).inserted {
        let __ci_copy_16: cstr = cstr_from(__param_rkey)
        with_memcpy((&raw mut (*((&raw const (*(*(&raw const __local__res as *const SImap_result)).ref).first as *const cstr) as *mut cstr)) as *mut u8), (&raw const __ci_copy_16 as *const u8), sizeof[cstr]())

        ((*(*(&raw const __local__res as *const SImap_result)).ref).second = __param_rmapped)

    }

    return __local__res

}

unsafe fn SImap_value_toraw(__param_val: *const SImap_value) -> SImap_raw {
    return ((SImap_raw { first: cstr_toraw((&raw const (*__param_val).first as *const cstr)), second: ((*(&raw const (*__param_val).second as *const c_int))) } as SImap_raw))

}

unsafe fn SImap_value_drop(__param_self_: *const SImap, __param__val: *mut SImap_value) {

    cstr_drop((((&raw const (*__param__val).first as *const cstr) as *mut cstr) as *const cstr))


}

unsafe fn SImap_move(__param_self_: *mut SImap) -> SImap {
    var __local_m: SImap = (*__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    ((*__param_self_).bucket_count = (*__param_self_).size)


    ((*__param_self_).meta = ((null as *mut hmap_meta)))

    ((*__param_self_).table = ((null as *mut SImap_value)))

    return __local_m

}

unsafe fn SImap_take(__param_self_: *mut SImap, __param_unowned: SImap) -> Unit {
    SImap_drop((__param_self_ as *const SImap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[SImap]())

}

unsafe fn SImap_insert(__param_self_: *mut SImap, __param__key: cstr, __param__mapped: c_int) -> SImap_result {
    var __local__res: SImap_result = SImap_insert_entry_(__param_self_, cstr_toraw(((&raw mut __param__key as *mut cstr) as *const cstr)))

    if (*(&raw const __local__res as *const SImap_result)).inserted {
        with_memcpy((&raw mut (*((&raw const (*(*(&raw const __local__res as *const SImap_result)).ref).first as *const cstr) as *mut cstr)) as *mut u8), (&raw const __param__key as *const u8), sizeof[cstr]())

        ((*(*(&raw const __local__res as *const SImap_result)).ref).second = __param__mapped)

    } else {
        cstr_drop(((&raw mut __param__key as *mut cstr) as *const cstr))


    }

    return __local__res

}

unsafe fn SImap_push(__param_self_: *mut SImap, __param__val: SImap_value) -> *mut SImap_value {
    var __local__res: SImap_result = SImap_insert_entry_(__param_self_, cstr_toraw((((&raw const (*(&raw mut __param__val as *mut SImap_value)).first as *const cstr) as *mut cstr) as *const cstr)))

    if ((if not (*(&raw const __local__res as *const SImap_result)).inserted: 1 else: 0) != 0) {
        SImap_value_drop((__param_self_ as *const SImap), (*(&raw const __local__res as *const SImap_result)).ref)
    }

    with_memcpy((&raw mut (*((*(&raw const __local__res as *const SImap_result)).ref)) as *mut u8), (&raw const __param__val as *const u8), sizeof[SImap_value]())

    return (*(&raw const __local__res as *const SImap_result)).ref

}

unsafe fn SImap_put(__param_self_: *mut SImap, __param_rkey: *const i8, __param_rmapped: c_int) -> SImap_result {
    return SImap_emplace_or_assign(__param_self_, __param_rkey, __param_rmapped)

}

unsafe fn SImap_put_n(__param_self_: *mut SImap, __param_raw: *const SImap_raw, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        SImap_put(__param_self_, (*__local_raw).first, (*__local_raw).second)

        (__local_raw = __local_raw + 1)

    }

}

fn SImap_init() -> SImap {
    var __local_cx: SImap = SImap.zeroed()

    return __local_cx

}

unsafe fn SImap_from_n(__param_raw: *const SImap_raw, __param_n: c_long) -> SImap {
    var __local_cx: SImap = SImap.zeroed()

    SImap_put_n((&raw mut __local_cx as *mut SImap), __param_raw, __param_n)

    return __local_cx

}

fn SImap_with_capacity(__param_cap: c_long) -> SImap {
    var __local_cx: SImap = SImap.zeroed()

    unsafe { SImap_reserve((&raw mut __local_cx as *mut SImap), __param_cap) }

    return __local_cx

}

unsafe fn SImap_begin(__param_self_: *const SImap) -> SImap_iter {
    var __local_it_: SImap_iter = SImap_iter { ref: (*__param_self_).table, _end: (*__param_self_).table, _mref: (*__param_self_).meta }

    if ((if (*(&raw const __local_it_ as *const SImap_iter)).ref == null: 1 else: 0) != 0) {
        return __local_it_
    }

    (__local_it_._end = (*(&raw const __local_it_ as *const SImap_iter))._end + (((*__param_self_).bucket_count as c_long) as usize))

    while ((if (*(*(&raw const __local_it_ as *const SImap_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const SImap_iter)).ref + 1)

        (__local_it_._mref = (*(&raw const __local_it_ as *const SImap_iter))._mref + 1)

    }

    if ((if (*(&raw const __local_it_ as *const SImap_iter)).ref == (*(&raw const __local_it_ as *const SImap_iter))._end: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *mut SImap_value)))
    }

    return __local_it_

}

unsafe fn SImap_end(__param_self_: *const SImap) -> SImap_iter {

    return ((SImap_iter.zeroed() as SImap_iter))

}

unsafe fn SImap_next(__param_it_: *mut SImap_iter) {
    while true {
        ((*__param_it_).ref = (*__param_it_).ref + 1)

        ((*__param_it_)._mref = (*__param_it_)._mref + 1)

        if (not ((if (*(*__param_it_)._mref).dist() == 0: 1 else: 0) != 0)) {
            break
        }

    }

    if ((if (*__param_it_).ref == (*__param_it_)._end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut SImap_value)))
    }

}

fn SImap_advance(__param_it_: SImap_iter, __param_n: c_ulong) -> SImap_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const SImap_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { SImap_next((&raw mut __param_it_ as *mut SImap_iter)) }

    }

    return __param_it_

}

unsafe fn SImap_find(__param_self_: *const SImap, __param_rkey: *const i8) -> SImap_iter {
    var __local_ref: *mut SImap_value

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = SImap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((SImap_iter { ref: __local_ref, _end: ((&raw const ((*__param_self_).table[(*__param_self_).bucket_count]) as *const SImap_value) as *mut SImap_value), _mref: ((&raw const ((*__param_self_).meta[((((__local_ref as usize) -% ((*__param_self_).table as usize)) as c_long) / (sizeof[SImap_value]() as c_long))]) as *const hmap_meta) as *mut hmap_meta) } as SImap_iter))
    }


    return SImap_end(__param_self_)

}

unsafe fn SImap_get(__param_self_: *const SImap, __param_rkey: *const i8) -> *const SImap_value {
    return (((if (*__param_self_).size != 0: SImap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref else: (null as *mut SImap_value)) as *const SImap_value))

}

unsafe fn SImap_get_mut(__param_self_: *mut SImap, __param_rkey: *const i8) -> *mut SImap_value {
    return ((SImap_get((__param_self_ as *const SImap), __param_rkey) as *mut SImap_value))

}

unsafe fn SImap_erase(__param_self_: *mut SImap, __param_rkey: *const i8) -> c_int {
    var __local_ref: *mut SImap_value

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = SImap_bucket_lookup_((__param_self_ as *const SImap), ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        SImap_erase_entry(__param_self_, __local_ref)

        return 1

    }


    return 0

}

unsafe fn SImap_erase_at(__param_self_: *mut SImap, __param_it_: SImap_iter) -> SImap_iter {
    SImap_erase_entry(__param_self_, (*(&raw const __param_it_ as *const SImap_iter)).ref)

    if ((if (*(*(&raw const __param_it_ as *const SImap_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        SImap_next((&raw mut __param_it_ as *mut SImap_iter))
    }

    return __param_it_

}

unsafe fn SImap_eq(__param_self_: *const SImap, __param_other: *const SImap) -> bool {
    if ((if SImap_size(__param_self_) != SImap_size(__param_other): 1 else: 0) != 0) {
        return false
    }

    var __local_i: SImap_iter = SImap_begin(__param_self_)

    while ((*(&raw const __local_i as *const SImap_iter)).ref != null) {
        var __local__raw: *const i8 = cstr_toraw((((&raw const (*(*(&raw const __local_i as *const SImap_iter)).ref).first as *const cstr) as *mut cstr) as *const cstr))

        if ((if not SImap_contains(__param_other, __local__raw): 1 else: 0) != 0) {
            return false
        }


        SImap_next((&raw mut __local_i as *mut SImap_iter))

    }


    return true

}

unsafe fn SImap_wipe_(__param_self_: *mut SImap) {
    var __local_d: *mut SImap_value = (*__param_self_).table

    var __local_m: *const hmap_meta = (((*__param_self_).meta as *const hmap_meta))

    var __local_n: c_long = (*__param_self_).bucket_count

    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const hmap_meta = __local_m

        (__local_m = __local_m + 1)

        if ((*__ci_expr_old_0).dist() != 0) {
            SImap_value_drop((__param_self_ as *const SImap), ((&raw const (__local_d[__local_i]) as *const SImap_value) as *mut SImap_value))
        }


        (__local_i = __local_i + 1)

    }


}

fn ctest_hashmap_mapdemo2_run() {
    var __local_nums: SImap = SImap.zeroed()

    unsafe { SImap_clear((&raw mut __local_nums as *mut SImap)) }

    unsafe { SImap_put((&raw mut __local_nums as *mut SImap), c"Hello".ptr, (64 as c_int)) }

    unsafe { SImap_put((&raw mut __local_nums as *mut SImap), c"Groovy".ptr, (121 as c_int)) }

    unsafe { SImap_put((&raw mut __local_nums as *mut SImap), c"Groovy".ptr, (200 as c_int)) }

    assert_compare((1 as c_int), c"==".ptr, (200 as c_long), ((unsafe *unsafe { SImap_at(((&raw mut __local_nums as *mut SImap) as *const SImap), c"Groovy".ptr) }) as c_long), c"hmap_test.c".ptr, (28 as c_int))

    assert_compare((1 as c_int), c"==".ptr, (64 as c_long), ((unsafe *unsafe { SImap_at(((&raw mut __local_nums as *mut SImap) as *const SImap), c"Hello".ptr) }) as c_long), c"hmap_test.c".ptr, (29 as c_int))

    unsafe { SImap_drop(((&raw mut __local_nums as *mut SImap) as *const SImap)) }

}

fn Strmap_clone(__param_map: Strmap) -> Strmap {
    if ((if (unsafe *(&raw const __param_map as *const Strmap)).bucket_count == 0: 1 else: 0) != 0) {
        return ((Strmap.zeroed() as Strmap))
    }

    var __local_out: Strmap = __param_map

    var __local_self_: *mut Strmap = ((&raw mut __local_out as *mut Strmap))


    var __local__mbytes: c_long = (((((unsafe *(&raw const __param_map as *const Strmap)).bucket_count + 1) * (sizeof[hmap_meta]() as c_long)) as c_long))

    (__local_out.table = (((with_alloc((((if 1 != 0: (((unsafe *(&raw const __param_map as *const Strmap)).bucket_count * (sizeof[Strmap_value]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Strmap_value)))

    (__local_out.meta = (((with_alloc((((if 1 != 0: __local__mbytes else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    var __ci_expr_logic_0: c_int = 0

    if ((unsafe *(&raw const __local_out as *const Strmap)).table != null) {
        (__ci_expr_logic_0 = (if (unsafe *(&raw const __local_out as *const Strmap)).meta != null: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy((((unsafe *(&raw const __local_out as *const Strmap)).meta as *mut c_void) as *mut u8), (((unsafe *(&raw const __param_map as *const Strmap)).meta as *const c_void) as *const u8), (((if 1 != 0: __local__mbytes else: (-1 as c_long)) as c_ulong) as i64))

        var __local_i: c_long = ((0 as c_long))

        while ((if __local_i < (unsafe *(&raw const __param_map as *const Strmap)).bucket_count: 1 else: 0) != 0) {
            if (((unsafe __param_map.meta[__local_i])).dist() != 0) {
                ((unsafe __local_out.table[__local_i]) = unsafe { Strmap_value_clone((__local_self_ as *const Strmap), ((*(&raw const __param_map as *const Strmap)).table[__local_i])) })
            }

            (__local_i = __local_i + 1)

        }


        return __local_out

    }
    if ((unsafe *(&raw const __local_out as *const Strmap)).meta != null) {
        with_free((((unsafe *(&raw const __local_out as *const Strmap)).meta as *mut c_void) as *mut u8))
    }

    if ((unsafe *(&raw const __local_out as *const Strmap)).table != null) {
        (sizeof[Strmap_value]() as usize)

        with_free((((unsafe *(&raw const __local_out as *const Strmap)).table as *mut c_void) as *mut u8))

    }

    return ((Strmap.zeroed() as Strmap))



}

unsafe fn Strmap_drop(__param_cself: *const Strmap) {
    var __local_self_: *mut Strmap = ((__param_cself as *mut Strmap))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    Strmap_wipe_(__local_self_)

    (sizeof[hmap_meta]() as usize)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))


    (sizeof[Strmap_value]() as usize)

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))


}

unsafe fn Strmap_clear(__param_self_: *mut Strmap) -> Unit {
    if ((if (*__param_self_).meta == null: 1 else: 0) != 0) {
        return
    }

    Strmap_wipe_(__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    with_memset((((*__param_self_).meta as *mut c_void) as *mut u8), (0 as c_int), (((if 1 != 0: (((sizeof[hmap_meta]() as c_long) * (*__param_self_).bucket_count) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

}

unsafe fn Strmap_reserve(__param__self: *mut Strmap, __param__cap: c_long) -> bool {
    var __local__newcap: c_long = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (*__param__self).size else: __param__cap) as c_long))

    var __local__newbucks: c_long = ((((((__local__newcap as f32) / i_max_load_factor) as c_long) + 4) as c_long))

    (__local__newbucks = ((c_next_pow2(__local__newbucks) as c_long)))

    var __ci_expr_logic_0: c_int

    if ((if __local__newbucks == (*__param__self).bucket_count: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param__cap <= (((((*__param__self).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return true
    }


    var __local_map: Strmap = (*__param__self)

    var __local_self_: *mut Strmap = ((&raw mut __local_map as *mut Strmap))



    (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[Strmap_value]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Strmap_value)))

    (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as c_long) else: (-1 as c_long)) as c_ulong) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    (__local_map.bucket_count = __local__newbucks)

    var __local_ok: bool = with 0 as __ci_expr_seq_26 {
        var __ci_expr_logic_1: c_int = 0
        if ((*(&raw const __local_map as *const Strmap)).table != null) {
            (__ci_expr_logic_1 = (if (*(&raw const __local_map as *const Strmap)).meta != null: 1 else: 0))
        }
        (__ci_expr_logic_1 != 0)
    }

    if __local_ok {
        ((__local_map.meta[__local__newbucks])).set_dist(((1023 as c_ushort)))

        var __local_d: *const Strmap_value = (((*__param__self).table as *const Strmap_value))

        var __local_m: *const hmap_meta = (((*__param__self).meta as *const hmap_meta))

        var __local_i: c_long = ((0 as c_long))

        while ((if __local_i < (*__param__self).bucket_count: 1 else: 0) != 0) {
            if ((if ((__local_m[__local_i])).dist() != 0: 1 else: 0) != 0) {
                var __local_r: *const i8 = cstr_toraw((&raw const (*__local_d).first as *const cstr))

                with_memcpy((&raw mut (*(Strmap_bucket_insert_(((&raw mut __local_map as *mut Strmap) as *const Strmap), ((&raw mut __local_r as *mut *const i8) as *const *const i8)).ref)) as *mut u8), (&raw const (*__local_d) as *const u8), sizeof[Strmap_value]())

            }

            (__local_i = __local_i + 1)

            (__local_d = __local_d + 1)


        }


        loop {
            var __local__xp: *mut Strmap = __param__self

            var __local__yp: *mut Strmap = ((&raw mut __local_map as *mut Strmap))


            var __local__tv: Strmap = (*__local__xp)

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

    }

    (sizeof[hmap_meta]() as usize)

    with_free((((*(&raw const __local_map as *const Strmap)).meta as *mut c_void) as *mut u8))


    (sizeof[Strmap_value]() as usize)

    with_free((((*(&raw const __local_map as *const Strmap)).table as *mut c_void) as *mut u8))


    return __local_ok

}

unsafe fn Strmap_erase_entry(__param_self_: *mut Strmap, __param__val: *mut Strmap_value) {
    var __local_d: *mut Strmap_value = (*__param_self_).table

    var __local_m: *mut hmap_meta = (*__param_self_).meta

    var __local_i: c_ulong = ((((((__param__val as usize) -% (__local_d as usize)) as c_long) / (sizeof[Strmap_value]() as c_long)) as c_ulong))

    var __local_j: c_ulong = __local_i


    var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    Strmap_value_drop((__param_self_ as *const Strmap), __param__val)

    while true {
        (__local_j = ((((((__local_j as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

        if ((if ((__local_m[__local_j])).dist() < 2: 1 else: 0) != 0) {
            break
        }

        ((__local_d[__local_i]) = (__local_d[__local_j]))

        ((__local_m[__local_i]) = (__local_m[__local_j]))

        ((__local_m[__local_i])).set_dist((((__local_m[__local_i])).dist() -% 1))

        (__local_i = __local_j)

    }

    ((__local_m[__local_i])).set_dist(((0 as c_ushort)))

    ((*__param_self_).size = (*__param_self_).size - 1)

}

unsafe fn Strmap_max_load_factor(__param_self_: *const Strmap) -> f32 {

    return i_max_load_factor

}

unsafe fn Strmap_capacity(__param_map: *const Strmap) -> c_long {
    return (((((*__param_map).bucket_count as f32) * i_max_load_factor) as c_long))

}

unsafe fn Strmap_bucket_lookup_(__param_self_: *const Strmap, __param_rkeyptr: *const *const i8) -> Strmap_result {
    var __local__hash: c_ulong = ((c_hash_str((*__param_rkeyptr)) as c_ulong))

    var __local__idxmask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    var __local__res: Strmap_result = Strmap_result { idx: ((__local__hash as c_ulong) & (__local__idxmask as c_ulong)), hashx: (((((((__local__hash as c_ulong) >> (24 as c_uint))) as c_ulong) & (63 as c_ulong))) as u8), dist: 1 }

    while ((if (*(&raw const __local__res as *const Strmap_result)).dist <= (((*__param_self_).meta[(*(&raw const __local__res as *const Strmap_result)).idx])).dist(): 1 else: 0) != 0) {
        if ((if (((*__param_self_).meta[(*(&raw const __local__res as *const Strmap_result)).idx])).hashx() == (*(&raw const __local__res as *const Strmap_result)).hashx: 1 else: 0) != 0) {
            var __local__raw: *const i8 = cstr_toraw((((&raw const (*((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const Strmap_result)).idx]) as *const Strmap_value) as *mut Strmap_value)).first as *const cstr) as *mut cstr) as *const cstr))

            if ((if strcmp((*(&raw const __local__raw as *const *const i8)), (*__param_rkeyptr)) == 0: 1 else: 0) != 0) {
                (__local__res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const Strmap_result)).idx]) as *const Strmap_value) as *mut Strmap_value)))

                break

            }

        }

        (__local__res.idx = (((((((*(&raw const __local__res as *const Strmap_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local__idxmask as c_ulong)) as c_ulong)))

        (__local__res.dist = ((*(&raw const __local__res as *const Strmap_result)).dist +% 1))

    }

    return __local__res

}

unsafe fn Strmap_bucket_insert_(__param_self_: *const Strmap, __param_rkeyptr: *const *const i8) -> Strmap_result {
    var __local_res: Strmap_result = Strmap_bucket_lookup_(__param_self_, __param_rkeyptr)

    if ((*(&raw const __local_res as *const Strmap_result)).ref != null) {
        return __local_res
    }

    (__local_res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const Strmap_result)).idx]) as *const Strmap_value) as *mut Strmap_value)))

    (__local_res.inserted = true)

    var __local_mnew: hmap_meta = with 0 as __ci_bits_seq_59 { var __ci_bits: hmap_meta = hmap_meta.zeroed(); __ci_bits.set_hashx((((((((*(&raw const __local_res as *const Strmap_result)).hashx as c_uint) as c_int) as c_uint) & (63 as c_uint))) as c_ushort)); __ci_bits.set_dist((((((((*(&raw const __local_res as *const Strmap_result)).dist as c_uint) as c_int) as c_uint) & (1023 as c_uint))) as c_ushort)); __ci_bits }

    var __local_mcur: hmap_meta = ((*__param_self_).meta[(*(&raw const __local_res as *const Strmap_result)).idx])

    (((*__param_self_).meta[(*(&raw const __local_res as *const Strmap_result)).idx]) = __local_mnew)

    if ((if __local_mcur.dist() != 0: 1 else: 0) != 0) {
        var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

        var __local_dcur: Strmap_value = (*((*(&raw const __local_res as *const Strmap_result)).ref))

        while true {
            (__local_res.idx = (((((((*(&raw const __local_res as *const Strmap_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

            __local_mcur.set_dist((__local_mcur.dist() +% 1))

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const Strmap_result)).idx])).dist() == 0: 1 else: 0) != 0) {
                break
            }

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const Strmap_result)).idx])).dist() < __local_mcur.dist(): 1 else: 0) != 0) {
                loop {
                    var __local__xp: *mut hmap_meta = ((&raw mut __local_mcur as *mut hmap_meta))

                    var __local__yp: *mut hmap_meta = (((&raw const ((*__param_self_).meta[(*(&raw const __local_res as *const Strmap_result)).idx]) as *const hmap_meta) as *mut hmap_meta))


                    var __local__tv: hmap_meta = (*__local__xp)

                    ((*__local__xp) = (*__local__yp))

                    ((*__local__yp) = __local__tv)

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_1: *mut Strmap_value = ((&raw mut __local_dcur as *mut Strmap_value))

                    var __local__yp_1: *mut Strmap_value = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const Strmap_result)).idx]) as *const Strmap_value) as *mut Strmap_value))


                    var __local__tv_1: Strmap_value = (*__local__xp_1)

                    ((*__local__xp_1) = (*__local__yp_1))

                    ((*__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

        }

        (((*__param_self_).meta[(*(&raw const __local_res as *const Strmap_result)).idx]) = __local_mcur)

        (((*__param_self_).table[(*(&raw const __local_res as *const Strmap_result)).idx]) = __local_dcur)

    }

    return __local_res

}

unsafe fn Strmap_is_empty(__param_map: *const Strmap) -> bool {
    return ((not ((*__param_map).size != 0)))

}

unsafe fn Strmap_size(__param_map: *const Strmap) -> c_long {
    return (*__param_map).size

}

unsafe fn Strmap_bucket_count(__param_map: *mut Strmap) -> c_long {
    return (*__param_map).bucket_count

}

unsafe fn Strmap_contains(__param_self_: *const Strmap, __param_rkey: *const i8) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if Strmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref != null: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

unsafe fn Strmap_shrink_to_fit(__param_self_: *mut Strmap) -> Unit {
    Strmap_reserve(__param_self_, (9223372036854775807 as c_long))

}

unsafe fn Strmap_insert_entry_(__param_self_: *mut Strmap, __param_rkey: *const i8) -> Strmap_result {
    if ((if (*__param_self_).size >= (((((*__param_self_).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0) {
        if ((if not Strmap_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 2) as c_long)): 1 else: 0) != 0) {
            return ((Strmap_result.zeroed() as Strmap_result))
        }
    }

    var __local_res: Strmap_result = Strmap_bucket_insert_((__param_self_ as *const Strmap), ((&raw mut __param_rkey as *mut *const i8) as *const *const i8))

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const Strmap_result)).inserted as c_int))

    return __local_res

}

unsafe fn Strmap_insert_or_assign(__param_self_: *mut Strmap, __param__key: cstr, __param__mapped: cstr) -> Strmap_result {
    var __local__res: Strmap_result = Strmap_insert_entry_(__param_self_, cstr_toraw(((&raw mut __param__key as *mut cstr) as *const cstr)))

    var __local__mp: *mut cstr = (if (*(&raw const __local__res as *const Strmap_result)).ref != null: ((&raw const (*(*(&raw const __local__res as *const Strmap_result)).ref).second as *const cstr) as *mut cstr) else: (&raw mut __param__mapped as *mut cstr))

    if (*(&raw const __local__res as *const Strmap_result)).inserted {
        with_memcpy((&raw mut (*(*(&raw const __local__res as *const Strmap_result)).ref).first as *mut u8), (&raw const __param__key as *const u8), sizeof[cstr]())
    } else {
        cstr_drop(((&raw mut __param__key as *mut cstr) as *const cstr))

        cstr_drop((__local__mp as *const cstr))

    }

    with_memcpy((&raw mut (*__local__mp) as *mut u8), (&raw const __param__mapped as *const u8), sizeof[cstr]())

    return __local__res

}

unsafe fn Strmap_emplace_or_assign(__param_self_: *mut Strmap, __param_rkey: *const i8, __param_rmapped: *const i8) -> Strmap_result {
    var __local__res: Strmap_result = Strmap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local__res as *const Strmap_result)).inserted {
        let __ci_copy_12: cstr = cstr_from(__param_rkey)
        with_memcpy((&raw mut (*(*(&raw const __local__res as *const Strmap_result)).ref).first as *mut u8), (&raw const __ci_copy_12 as *const u8), sizeof[cstr]())
    } else {
        if ((if (*(&raw const __local__res as *const Strmap_result)).ref == null: 1 else: 0) != 0) {
            return __local__res
        }

        cstr_drop((((&raw const (*(*(&raw const __local__res as *const Strmap_result)).ref).second as *const cstr) as *mut cstr) as *const cstr))

    }

    let __ci_copy_38: cstr = cstr_from(__param_rmapped)
    with_memcpy((&raw mut (*(*(&raw const __local__res as *const Strmap_result)).ref).second as *mut u8), (&raw const __ci_copy_38 as *const u8), sizeof[cstr]())

    return __local__res

}

unsafe fn Strmap_at(__param_self_: *const Strmap, __param_rkey: *const i8) -> *const cstr {
    var __local_res: Strmap_result = Strmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8))

    if (((if not ((*(&raw const __local_res as *const Strmap_result)).ref != null): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Strmap_at".ptr, c"hmap.h".ptr, (136 as c_int), c"res.ref".ptr)
    } else {
        0
    }

    return ((((&raw const (*(*(&raw const __local_res as *const Strmap_result)).ref).second as *const cstr) as *mut cstr) as *const cstr))

}

unsafe fn Strmap_at_mut(__param_self_: *mut Strmap, __param_rkey: *const i8) -> *mut cstr {
    return ((Strmap_at((__param_self_ as *const Strmap), __param_rkey) as *mut cstr))

}

unsafe fn Strmap_copy(__param_self_: *mut Strmap, __param_other: *const Strmap) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Strmap_drop((__param_self_ as *const Strmap))

    let __ci_copy_18: Strmap = Strmap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[Strmap]())

}

unsafe fn Strmap_value_clone(__param_self_: *const Strmap, __param__val: Strmap_value) -> Strmap_value {

    let __ci_copy_18: cstr = cstr_clone((*((&raw const (*(&raw mut __param__val as *mut Strmap_value)).first as *const cstr) as *mut cstr)))
    with_memcpy((&raw mut (*((&raw const (*(&raw mut __param__val as *mut Strmap_value)).first as *const cstr) as *mut cstr)) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[cstr]())

    let __ci_copy_24: cstr = cstr_clone((*(&raw const __param__val as *const Strmap_value)).second)
    with_memcpy((&raw mut __param__val.second as *mut u8), (&raw const __ci_copy_24 as *const u8), sizeof[cstr]())

    return __param__val

}

unsafe fn Strmap_emplace(__param_self_: *mut Strmap, __param_rkey: *const i8, __param_rmapped: *const i8) -> Strmap_result {
    var __local__res: Strmap_result = Strmap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local__res as *const Strmap_result)).inserted {
        let __ci_copy_16: cstr = cstr_from(__param_rkey)
        with_memcpy((&raw mut (*((&raw const (*(*(&raw const __local__res as *const Strmap_result)).ref).first as *const cstr) as *mut cstr)) as *mut u8), (&raw const __ci_copy_16 as *const u8), sizeof[cstr]())

        let __ci_copy_22: cstr = cstr_from(__param_rmapped)
        with_memcpy((&raw mut (*(*(&raw const __local__res as *const Strmap_result)).ref).second as *mut u8), (&raw const __ci_copy_22 as *const u8), sizeof[cstr]())

    }

    return __local__res

}

unsafe fn Strmap_value_toraw(__param_val: *const Strmap_value) -> Strmap_raw {
    return ((Strmap_raw { first: cstr_toraw((&raw const (*__param_val).first as *const cstr)), second: cstr_toraw((&raw const (*__param_val).second as *const cstr)) } as Strmap_raw))

}

unsafe fn Strmap_value_drop(__param_self_: *const Strmap, __param__val: *mut Strmap_value) {

    cstr_drop((((&raw const (*__param__val).first as *const cstr) as *mut cstr) as *const cstr))

    cstr_drop((((&raw const (*__param__val).second as *const cstr) as *mut cstr) as *const cstr))

}

unsafe fn Strmap_move(__param_self_: *mut Strmap) -> Strmap {
    var __local_m: Strmap = (*__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    ((*__param_self_).bucket_count = (*__param_self_).size)


    ((*__param_self_).meta = ((null as *mut hmap_meta)))

    ((*__param_self_).table = ((null as *mut Strmap_value)))

    return __local_m

}

unsafe fn Strmap_take(__param_self_: *mut Strmap, __param_unowned: Strmap) -> Unit {
    Strmap_drop((__param_self_ as *const Strmap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Strmap]())

}

unsafe fn Strmap_insert(__param_self_: *mut Strmap, __param__key: cstr, __param__mapped: cstr) -> Strmap_result {
    var __local__res: Strmap_result = Strmap_insert_entry_(__param_self_, cstr_toraw(((&raw mut __param__key as *mut cstr) as *const cstr)))

    if (*(&raw const __local__res as *const Strmap_result)).inserted {
        with_memcpy((&raw mut (*((&raw const (*(*(&raw const __local__res as *const Strmap_result)).ref).first as *const cstr) as *mut cstr)) as *mut u8), (&raw const __param__key as *const u8), sizeof[cstr]())

        with_memcpy((&raw mut (*(*(&raw const __local__res as *const Strmap_result)).ref).second as *mut u8), (&raw const __param__mapped as *const u8), sizeof[cstr]())

    } else {
        cstr_drop(((&raw mut __param__key as *mut cstr) as *const cstr))

        cstr_drop(((&raw mut __param__mapped as *mut cstr) as *const cstr))

    }

    return __local__res

}

unsafe fn Strmap_push(__param_self_: *mut Strmap, __param__val: Strmap_value) -> *mut Strmap_value {
    var __local__res: Strmap_result = Strmap_insert_entry_(__param_self_, cstr_toraw((((&raw const (*(&raw mut __param__val as *mut Strmap_value)).first as *const cstr) as *mut cstr) as *const cstr)))

    if ((if not (*(&raw const __local__res as *const Strmap_result)).inserted: 1 else: 0) != 0) {
        Strmap_value_drop((__param_self_ as *const Strmap), (*(&raw const __local__res as *const Strmap_result)).ref)
    }

    with_memcpy((&raw mut (*((*(&raw const __local__res as *const Strmap_result)).ref)) as *mut u8), (&raw const __param__val as *const u8), sizeof[Strmap_value]())

    return (*(&raw const __local__res as *const Strmap_result)).ref

}

unsafe fn Strmap_put(__param_self_: *mut Strmap, __param_rkey: *const i8, __param_rmapped: *const i8) -> Strmap_result {
    return Strmap_emplace_or_assign(__param_self_, __param_rkey, __param_rmapped)

}

unsafe fn Strmap_put_n(__param_self_: *mut Strmap, __param_raw: *const Strmap_raw, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        Strmap_put(__param_self_, (*__local_raw).first, (*__local_raw).second)

        (__local_raw = __local_raw + 1)

    }

}

fn Strmap_init() -> Strmap {
    var __local_cx: Strmap = Strmap.zeroed()

    return __local_cx

}

unsafe fn Strmap_from_n(__param_raw: *const Strmap_raw, __param_n: c_long) -> Strmap {
    var __local_cx: Strmap = Strmap.zeroed()

    Strmap_put_n((&raw mut __local_cx as *mut Strmap), __param_raw, __param_n)

    return __local_cx

}

fn Strmap_with_capacity(__param_cap: c_long) -> Strmap {
    var __local_cx: Strmap = Strmap.zeroed()

    unsafe { Strmap_reserve((&raw mut __local_cx as *mut Strmap), __param_cap) }

    return __local_cx

}

unsafe fn Strmap_begin(__param_self_: *const Strmap) -> Strmap_iter {
    var __local_it_: Strmap_iter = Strmap_iter { ref: (*__param_self_).table, _end: (*__param_self_).table, _mref: (*__param_self_).meta }

    if ((if (*(&raw const __local_it_ as *const Strmap_iter)).ref == null: 1 else: 0) != 0) {
        return __local_it_
    }

    (__local_it_._end = (*(&raw const __local_it_ as *const Strmap_iter))._end + (((*__param_self_).bucket_count as c_long) as usize))

    while ((if (*(*(&raw const __local_it_ as *const Strmap_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const Strmap_iter)).ref + 1)

        (__local_it_._mref = (*(&raw const __local_it_ as *const Strmap_iter))._mref + 1)

    }

    if ((if (*(&raw const __local_it_ as *const Strmap_iter)).ref == (*(&raw const __local_it_ as *const Strmap_iter))._end: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *mut Strmap_value)))
    }

    return __local_it_

}

unsafe fn Strmap_end(__param_self_: *const Strmap) -> Strmap_iter {

    return ((Strmap_iter.zeroed() as Strmap_iter))

}

unsafe fn Strmap_next(__param_it_: *mut Strmap_iter) {
    while true {
        ((*__param_it_).ref = (*__param_it_).ref + 1)

        ((*__param_it_)._mref = (*__param_it_)._mref + 1)

        if (not ((if (*(*__param_it_)._mref).dist() == 0: 1 else: 0) != 0)) {
            break
        }

    }

    if ((if (*__param_it_).ref == (*__param_it_)._end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut Strmap_value)))
    }

}

fn Strmap_advance(__param_it_: Strmap_iter, __param_n: c_ulong) -> Strmap_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const Strmap_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { Strmap_next((&raw mut __param_it_ as *mut Strmap_iter)) }

    }

    return __param_it_

}

unsafe fn Strmap_find(__param_self_: *const Strmap, __param_rkey: *const i8) -> Strmap_iter {
    var __local_ref: *mut Strmap_value

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = Strmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((Strmap_iter { ref: __local_ref, _end: ((&raw const ((*__param_self_).table[(*__param_self_).bucket_count]) as *const Strmap_value) as *mut Strmap_value), _mref: ((&raw const ((*__param_self_).meta[((((__local_ref as usize) -% ((*__param_self_).table as usize)) as c_long) / (sizeof[Strmap_value]() as c_long))]) as *const hmap_meta) as *mut hmap_meta) } as Strmap_iter))
    }


    return Strmap_end(__param_self_)

}

unsafe fn Strmap_get(__param_self_: *const Strmap, __param_rkey: *const i8) -> *const Strmap_value {
    return (((if (*__param_self_).size != 0: Strmap_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref else: (null as *mut Strmap_value)) as *const Strmap_value))

}

unsafe fn Strmap_get_mut(__param_self_: *mut Strmap, __param_rkey: *const i8) -> *mut Strmap_value {
    return ((Strmap_get((__param_self_ as *const Strmap), __param_rkey) as *mut Strmap_value))

}

unsafe fn Strmap_erase(__param_self_: *mut Strmap, __param_rkey: *const i8) -> c_int {
    var __local_ref: *mut Strmap_value

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = Strmap_bucket_lookup_((__param_self_ as *const Strmap), ((&raw mut __param_rkey as *mut *const i8) as *const *const i8)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        Strmap_erase_entry(__param_self_, __local_ref)

        return 1

    }


    return 0

}

unsafe fn Strmap_erase_at(__param_self_: *mut Strmap, __param_it_: Strmap_iter) -> Strmap_iter {
    Strmap_erase_entry(__param_self_, (*(&raw const __param_it_ as *const Strmap_iter)).ref)

    if ((if (*(*(&raw const __param_it_ as *const Strmap_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        Strmap_next((&raw mut __param_it_ as *mut Strmap_iter))
    }

    return __param_it_

}

unsafe fn Strmap_eq(__param_self_: *const Strmap, __param_other: *const Strmap) -> bool {
    if ((if Strmap_size(__param_self_) != Strmap_size(__param_other): 1 else: 0) != 0) {
        return false
    }

    var __local_i: Strmap_iter = Strmap_begin(__param_self_)

    while ((*(&raw const __local_i as *const Strmap_iter)).ref != null) {
        var __local__raw: *const i8 = cstr_toraw((((&raw const (*(*(&raw const __local_i as *const Strmap_iter)).ref).first as *const cstr) as *mut cstr) as *const cstr))

        if ((if not Strmap_contains(__param_other, __local__raw): 1 else: 0) != 0) {
            return false
        }


        Strmap_next((&raw mut __local_i as *mut Strmap_iter))

    }


    return true

}

unsafe fn Strmap_wipe_(__param_self_: *mut Strmap) {
    var __local_d: *mut Strmap_value = (*__param_self_).table

    var __local_m: *const hmap_meta = (((*__param_self_).meta as *const hmap_meta))

    var __local_n: c_long = (*__param_self_).bucket_count

    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const hmap_meta = __local_m

        (__local_m = __local_m + 1)

        if ((*__ci_expr_old_0).dist() != 0) {
            Strmap_value_drop((__param_self_ as *const Strmap), ((&raw const (__local_d[__local_i]) as *const Strmap_value) as *mut Strmap_value))
        }


        (__local_i = __local_i + 1)

    }


}

@[repr(C)]
pub type ctest_hashmap_mapdemo3_run__c_i2_anon { _ref: *const *mut Strmap = null, ref: *mut *mut Strmap = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_hashmap_mapdemo3_run__c_i2_anon
fn ctest_hashmap_mapdemo3_run() {
    var __local_map: Strmap = Strmap.zeroed()

    unsafe { Strmap_emplace((&raw mut __local_map as *mut Strmap), c"Map".ptr, c"test".ptr) }

    unsafe { Strmap_emplace((&raw mut __local_map as *mut Strmap), c"Make".ptr, c"my".ptr) }

    unsafe { Strmap_emplace((&raw mut __local_map as *mut Strmap), c"Hello".ptr, c"world".ptr) }

    unsafe { Strmap_emplace((&raw mut __local_map as *mut Strmap), c"Sunny".ptr, c"day".ptr) }

    var __local_it_: Strmap_iter = unsafe { Strmap_find(((&raw mut __local_map as *mut Strmap) as *const Strmap), c"Make".ptr) }

    unsafe { Strmap_erase_at((&raw mut __local_map as *mut Strmap), __local_it_) }

    unsafe { Strmap_erase((&raw mut __local_map as *mut Strmap), c"Hello".ptr) }

    var __local_res1: Strmap = with 0 as __ci_expr_seq_13 {
        var __ci_expr_lit_0: [Strmap_raw; 2] = [Strmap_raw { first: (("Map" as *mut c_char) as *const i8), second: (("" as *mut c_char) as *const i8) }, Strmap_raw { first: (("Sunny" as *mut c_char) as *const i8), second: (("" as *mut c_char) as *const i8) }]
        unsafe { Strmap_from_n((&__ci_expr_lit_0[0] as *mut Strmap_raw), (2 as c_long)) }
    }

    var __local_res2: Strmap = with 0 as __ci_expr_seq_18 {
        var __ci_expr_lit_1: [Strmap_raw; 2] = [Strmap_raw { first: (("Sunny" as *mut c_char) as *const i8), second: (("" as *mut c_char) as *const i8) }, Strmap_raw { first: (("Map" as *mut c_char) as *const i8), second: (("" as *mut c_char) as *const i8) }]
        unsafe { Strmap_from_n((&__ci_expr_lit_1[0] as *mut Strmap_raw), (2 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { Strmap_eq(((&raw mut __local_res1 as *mut Strmap) as *const Strmap), ((&raw mut __local_map as *mut Strmap) as *const Strmap)) } as bool), c"hmap_test.c".ptr, (53 as c_int))

    assert_bool((1 as c_int), (true as bool), (unsafe { Strmap_eq(((&raw mut __local_res2 as *mut Strmap) as *const Strmap), ((&raw mut __local_map as *mut Strmap) as *const Strmap)) } as bool), c"hmap_test.c".ptr, (54 as c_int))

    loop {
        var __local__c_i2: ctest_hashmap_mapdemo3_run__c_i2_anon = ctest_hashmap_mapdemo3_run__c_i2_anon.zeroed()

        var __ci_expr_lit_2: [*mut Strmap; 3] = [(&raw mut __local_map as *mut Strmap), (&raw mut __local_res1 as *mut Strmap), (&raw mut __local_res2 as *mut Strmap)]

        __local__c_i2 = ctest_hashmap_mapdemo3_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_2)[0] as *mut *mut Strmap) as *const *mut Strmap)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_hashmap_mapdemo3_run__c_i2_anon))._ref as *mut *mut Strmap)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[Strmap]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_hashmap_mapdemo3_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_hashmap_mapdemo3_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { Strmap_drop(((*((*(&raw const __local__c_i2 as *const ctest_hashmap_mapdemo3_run__c_i2_anon)).ref)) as *const Strmap)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_hashmap_mapdemo3_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_hashmap_mapdemo3_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

var ctest_hashmap_mapdemo1: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("hashmap" as *mut c_char) as *const c_char), ttname: (("mapdemo1" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_hashmap_mapdemo1_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_hashmap_mapdemo2: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("hashmap" as *mut c_char) as *const c_char), ttname: (("mapdemo2" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_hashmap_mapdemo2_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_hashmap_mapdemo3: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("hashmap" as *mut c_char) as *const c_char), ttname: (("mapdemo3" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_hashmap_mapdemo3_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_hashmap_mapdemo1_run()
    print("ran hashmap.mapdemo1")
    ctest_hashmap_mapdemo2_run()
    print("ran hashmap.mapdemo2")
    ctest_hashmap_mapdemo3_run()
    print("ran hashmap.mapdemo3")
    return ctest_failure_count()
