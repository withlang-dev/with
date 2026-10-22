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
use std.collections

extern fn assert_str(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const i8, __param_real: *const i8, __param_caller: *const i8, __param_line: c_int)
extern fn assert_wstr(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_int, __param_real: *const c_int, __param_caller: *const i8, __param_line: c_int)
extern fn assert_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_interval(__param_diag: c_int, __param_low: c_long, __param_high: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_pointers(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const i8, __param_line: c_int)
extern fn assert_bool(__param_diag: c_int, __param_exp: bool, __param_real: bool, __param_caller: *const i8, __param_line: c_int)
extern fn assert_dbl_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const i8, __param_line: c_int)
extern fn assert_fail(__param_caller: *const i8, __param_line: c_int)
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

unsafe fn Mymap_emplace(__param_self_: *mut Mymap, __param_rkey: c_int, __param_rmapped: *const i8) -> Mymap_result {
    var __local_res: Mymap_result = Mymap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local_res as *const Mymap_result)).inserted {
        ((*((&raw const (*(*(&raw const __local_res as *const Mymap_result)).ref).first as *const c_int) as *mut c_int)) = __param_rkey)

        let __ci_copy_20: cstr = cstr_from(__param_rmapped)
        with_memcpy((&raw mut (*(*(&raw const __local_res as *const Mymap_result)).ref).second as *mut u8), (&raw const __ci_copy_20 as *const u8), sizeof[cstr]())

    }

    return __local_res

}

fn Mymap_clone(__param_tree: Mymap) -> Mymap {
    var __local_out: Mymap = __param_tree

    (__local_out.capacity = ((0 as c_int)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Mymap)).capacity)

    (__local_out.head = (unsafe *(&raw const __local_out as *const Mymap)).size)

    (__local_out.disp = (unsafe *(&raw const __local_out as *const Mymap)).head)

    (__local_out.root = (unsafe *(&raw const __local_out as *const Mymap)).disp)


    (__local_out.nodes = ((null as *mut Mymap_node)))

    unsafe { Mymap_reserve((&raw mut __local_out as *mut Mymap), ((*(&raw const __param_tree as *const Mymap)).size as c_long)) }

    (__local_out.root = ((unsafe { Mymap_clone_r_((&raw mut __local_out as *mut Mymap), (*(&raw const __param_tree as *const Mymap)).nodes, (*(&raw const __param_tree as *const Mymap)).root) } as c_int)))

    return __local_out

}

unsafe fn Mymap_drop(__param_cself: *const Mymap) {
    var __local_self_: *mut Mymap = ((__param_cself as *mut Mymap))

    if ((if (*__local_self_).nodes == null: 1 else: 0) != 0) {
        return
    }

    Mymap_drop_r_(__local_self_, (*__local_self_).root)

    (sizeof[Mymap_node]() as usize)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))


}

unsafe fn Mymap_reserve(__param_self_: *mut Mymap, __param_cap: c_long) -> bool {
    if ((if __param_cap <= (*__param_self_).capacity: 1 else: 0) != 0) {
        return false
    }

    var __local_nodes: *mut Mymap_node = (((with_realloc((((*__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: (((__param_cap + 1) * (sizeof[Mymap_node]() as c_long)) as c_long) else: ((((*__param_self_).capacity + 1) * (sizeof[Mymap_node]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Mymap_node))

    if ((if __local_nodes == null: 1 else: 0) != 0) {
        return false
    }

    ((__local_nodes[0]) = ((Mymap_node.zeroed() as Mymap_node)))

    ((*__param_self_).nodes = __local_nodes)

    ((*__param_self_).capacity = ((__param_cap as c_int)))

    return true

}

unsafe fn Mymap_find_it(__param_self_: *const Mymap, __param_rkey: c_int, __param_out: *mut Mymap_iter) -> *mut Mymap_value {
    var __local_tn: c_int = (*__param_self_).root

    var __local_d: *mut Mymap_node = with 0 as __ci_expr_seq_6 {
        ((*__param_out)._d = (*__param_self_).nodes)
        (*__param_out)._d
    }

    ((*__param_out)._top = ((0 as c_int)))

    while (__local_tn != 0) {
        var __local_c: c_int

        var __local__raw: c_int = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)).first as *const c_int) as *mut c_int))

        (__local_c = ((((if (*(&raw mut __param_rkey as *mut c_int)) < (*(&raw const __local__raw as *const c_int)): 1 else: 0) - (if (*(&raw const __local__raw as *const c_int)) < (*(&raw mut __param_rkey as *mut c_int)): 1 else: 0)) as c_int)))

        if ((if __local_c < 0: 1 else: 0) != 0) {
            (__local_tn = (((__local_d[__local_tn]).link[1] as c_int)))
        } else {
            if ((if __local_c > 0: 1 else: 0) != 0) {
                var __ci_expr_old_0: c_int = (*__param_out)._top

                ((*__param_out)._top = (*__param_out)._top + 1)

                ((*__param_out)._st[__ci_expr_old_0] = __local_tn)


                (__local_tn = (((__local_d[__local_tn]).link[0] as c_int)))

            } else {
                ((*__param_out)._tn = (((__local_d[__local_tn]).link[1] as c_int)))

                ((*__param_out).ref = (((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)))

                return (*__param_out).ref


            }
        }


    }

    ((*__param_out).ref = ((null as *mut Mymap_value)))

    return (*__param_out).ref


}

unsafe fn Mymap_lower_bound(__param_self_: *const Mymap, __param_rkey: c_int) -> Mymap_iter {
    var __local_it_: Mymap_iter

    Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter))

    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __local_it_ as *const Mymap_iter)).ref == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const __local_it_ as *const Mymap_iter))._top != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tn: c_int = with 0 as __ci_expr_seq_11 {
            (__local_it_._top = (*(&raw const __local_it_ as *const Mymap_iter))._top - 1)
            ((*(&raw const __local_it_ as *const Mymap_iter))._st[(*(&raw const __local_it_ as *const Mymap_iter))._top] as c_int)
        }

        (__local_it_._tn = ((((*(&raw const __local_it_ as *const Mymap_iter))._d[__local_tn]).link[1] as c_int)))

        (__local_it_.ref = (((&raw const (__local_it_._d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)))

    }


    return __local_it_

}

unsafe fn Mymap_front(__param_self_: *const Mymap) -> *mut Mymap_value {
    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    var __local_tn: c_int = (*__param_self_).root

    while ((__local_d[__local_tn]).link[0] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[0] as c_int)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value))

}

unsafe fn Mymap_back(__param_self_: *const Mymap) -> *mut Mymap_value {
    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    var __local_tn: c_int = (*__param_self_).root

    while ((__local_d[__local_tn]).link[1] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[1] as c_int)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value))

}

unsafe fn Mymap_erase(__param_self_: *mut Mymap, __param_rkey: c_int) -> c_int {
    var __local_erased: c_int = ((0 as c_int))

    var __local_root: c_int = ((Mymap_erase_r_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut c_int) as *const c_int), (&raw mut __local_erased as *mut c_int)) as c_int))

    if ((if __local_erased == 0: 1 else: 0) != 0) {
        return 0
    }

    ((*__param_self_).root = __local_root)

    ((*__param_self_).size = (*__param_self_).size - 1)

    return 1

}

unsafe fn Mymap_erase_at(__param_self_: *mut Mymap, __param_it_: Mymap_iter) -> Mymap_iter {
    var __local_raw: c_int = (*((&raw const (*(*(&raw const __param_it_ as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int))

    Mymap_next((&raw mut __param_it_ as *mut Mymap_iter))

    if ((if (*(&raw const __param_it_ as *const Mymap_iter)).ref != null: 1 else: 0) != 0) {
        var __local_nxt: c_int = (*((&raw const (*(*(&raw const __param_it_ as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int))

        Mymap_erase(__param_self_, __local_raw)

        Mymap_find_it((__param_self_ as *const Mymap), __local_nxt, (&raw mut __param_it_ as *mut Mymap_iter))

    } else {
        Mymap_erase(__param_self_, __local_raw)
    }

    return __param_it_

}

unsafe fn Mymap_erase_range(__param_self_: *mut Mymap, __param_it1: Mymap_iter, __param_it2: Mymap_iter) -> Mymap_iter {
    var __local_it1 = __param_it1
    if ((if (*(&raw const __param_it2 as *const Mymap_iter)).ref == null: 1 else: 0) != 0) {
        while ((if (*(&raw const __local_it1 as *const Mymap_iter)).ref != null: 1 else: 0) != 0) {
            let __ci_copy_25: Mymap_iter = Mymap_erase_at(__param_self_, __local_it1)
            with_memcpy((&raw mut __local_it1 as *mut u8), (&raw const __ci_copy_25 as *const u8), sizeof[Mymap_iter]())
        }

        return __local_it1

    }

    var __local_k1: c_int = (*((&raw const (*(*(&raw const __local_it1 as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int))

    var __local_k2: c_int = (*((&raw const (*(*(&raw const __param_it2 as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int))


    var __local_r1: c_int = (*(&raw mut __local_k1 as *mut c_int))

    while true {
        if ((if with_memcmp((((&raw mut __local_k1 as *mut c_int) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut c_int) as *const c_void) as *const u8), ((sizeof[c_int]() as c_ulong) as i64)) == 0: 1 else: 0) != 0) {
            return __local_it1
        }

        Mymap_next((&raw mut __local_it1 as *mut Mymap_iter))

        (__local_k1 = (*((&raw const (*(*(&raw const __local_it1 as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int)))

        Mymap_erase(__param_self_, __local_r1)

        (__local_r1 = (*(&raw mut __local_k1 as *mut c_int)))

        Mymap_find_it((__param_self_ as *const Mymap), __local_r1, (&raw mut __local_it1 as *mut Mymap_iter))

    }

}

unsafe fn Mymap_begin(__param_self_: *const Mymap) -> Mymap_iter {
    var __local_it_: Mymap_iter

    (__local_it_.ref = ((null as *mut Mymap_value)))

    (__local_it_._d = (*__param_self_).nodes)

    (__local_it_._top = ((0 as c_int)))


    (__local_it_._tn = (*__param_self_).root)

    if ((*(&raw const __local_it_ as *const Mymap_iter))._tn != 0) {
        Mymap_next((&raw mut __local_it_ as *mut Mymap_iter))
    }

    return __local_it_

}

unsafe fn Mymap_next(__param_it_: *mut Mymap_iter) -> Unit {
    var __local_tn: c_int = (*__param_it_)._tn

    var __ci_expr_logic_0: c_int

    if ((*__param_it_)._top != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_tn != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        while (__local_tn != 0) {
            var __ci_expr_old_1: c_int = (*__param_it_)._top

            ((*__param_it_)._top = (*__param_it_)._top + 1)

            ((*__param_it_)._st[__ci_expr_old_1] = __local_tn)


            (__local_tn = ((((*__param_it_)._d[__local_tn]).link[0] as c_int)))

        }

        ((*__param_it_)._top = (*__param_it_)._top - 1)

        (__local_tn = (((*__param_it_)._st[(*__param_it_)._top] as c_int)))


        ((*__param_it_)._tn = ((((*__param_it_)._d[__local_tn]).link[1] as c_int)))

        ((*__param_it_).ref = (((&raw const ((*__param_it_)._d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)))

    } else {
        ((*__param_it_).ref = ((null as *mut Mymap_value)))
    }


}

unsafe fn Mymap_is_empty(__param_self_: *const Mymap) -> bool {
    return (((*__param_self_).size == 0))

}

unsafe fn Mymap_size(__param_self_: *const Mymap) -> c_long {
    return (((*__param_self_).size as c_long))

}

unsafe fn Mymap_capacity(__param_self_: *const Mymap) -> c_long {
    return (((*__param_self_).capacity as c_long))

}

unsafe fn Mymap_find(__param_self_: *const Mymap, __param_rkey: c_int) -> Mymap_iter {
    var __local_it_: Mymap_iter

    Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter))

    return __local_it_

}

unsafe fn Mymap_contains(__param_self_: *const Mymap, __param_rkey: c_int) -> bool {
    var __local_it_: Mymap_iter

    return ((Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) != null))

}

unsafe fn Mymap_get(__param_self_: *const Mymap, __param_rkey: c_int) -> *const Mymap_value {
    var __local_it_: Mymap_iter

    return ((Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) as *const Mymap_value))

}

unsafe fn Mymap_get_mut(__param_self_: *mut Mymap, __param_rkey: c_int) -> *mut Mymap_value {
    var __local_it_: Mymap_iter

    return ((Mymap_find_it((__param_self_ as *const Mymap), __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) as *mut Mymap_value))

}

unsafe fn Mymap_value_toraw(__param_val: *const Mymap_value) -> Mymap_raw {
    return ((Mymap_raw { first: ((*(&raw const (*__param_val).first as *const c_int))), second: cstr_toraw((&raw const (*__param_val).second as *const cstr)) } as Mymap_raw))

}

unsafe fn Mymap_value_drop(__param_self_: *const Mymap, __param_val: *mut Mymap_value) {


    cstr_drop((((&raw const (*__param_val).second as *const cstr) as *mut cstr) as *const cstr))

}

unsafe fn Mymap_move(__param_self_: *mut Mymap) -> Mymap {
    var __local_m: Mymap = (*__param_self_)

    ((*__param_self_).head = ((0 as c_int)))

    ((*__param_self_).disp = (*__param_self_).head)

    ((*__param_self_).root = (*__param_self_).disp)

    ((*__param_self_).size = (*__param_self_).root)

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).nodes = ((null as *mut Mymap_node)))

    return __local_m

}

unsafe fn Mymap_clear(__param_self_: *mut Mymap) -> Unit {
    Mymap_drop((__param_self_ as *const Mymap))

    Mymap_move(__param_self_)

}

unsafe fn Mymap_take(__param_self_: *mut Mymap, __param_unowned: Mymap) -> Unit {
    Mymap_drop((__param_self_ as *const Mymap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Mymap]())

}

unsafe fn Mymap_value_clone(__param_self_: *const Mymap, __param__val: Mymap_value) -> Mymap_value {

    ((*((&raw const (*(&raw mut __param__val as *mut Mymap_value)).first as *const c_int) as *mut c_int)) = (*((&raw const (*(&raw mut __param__val as *mut Mymap_value)).first as *const c_int) as *mut c_int)))

    let __ci_copy_22: cstr = cstr_clone((*(&raw const __param__val as *const Mymap_value)).second)
    with_memcpy((&raw mut __param__val.second as *mut u8), (&raw const __ci_copy_22 as *const u8), sizeof[cstr]())

    return __param__val

}

unsafe fn Mymap_copy(__param_self_: *mut Mymap, __param_other: *const Mymap) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Mymap_drop((__param_self_ as *const Mymap))

    let __ci_copy_18: Mymap = Mymap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[Mymap]())

}

unsafe fn Mymap_shrink_to_fit(__param_self_: *mut Mymap) -> Unit {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        return
    }

    var __local_tmp: Mymap = Mymap_clone((*__param_self_))

    Mymap_drop((__param_self_ as *const Mymap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __local_tmp as *const u8), sizeof[Mymap]())

}

unsafe fn Mymap_insert_entry_(__param_self_: *mut Mymap, __param_rkey: c_int) -> Mymap_result {
    var __local_res: Mymap_result = Mymap_result.zeroed()

    var __local_tn: c_int = ((Mymap_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut c_int) as *const c_int), (&raw mut __local_res as *mut Mymap_result)) as c_int))

    ((*__param_self_).root = __local_tn)

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const Mymap_result)).inserted as c_int))

    return __local_res

}

unsafe fn Mymap_insert_or_assign(__param_self_: *mut Mymap, __param__key: c_int, __param__mapped: cstr) -> Mymap_result {
    var __local__res: Mymap_result = Mymap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut c_int)))

    var __local__mp: *mut cstr = (if (*(&raw const __local__res as *const Mymap_result)).ref != null: ((&raw const (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *const cstr) as *mut cstr) else: (&raw mut __param__mapped as *mut cstr))

    if (*(&raw const __local__res as *const Mymap_result)).inserted {
        ((*(*(&raw const __local__res as *const Mymap_result)).ref).first = __param__key)
    } else {

        cstr_drop((__local__mp as *const cstr))

    }

    with_memcpy((&raw mut (*__local__mp) as *mut u8), (&raw const __param__mapped as *const u8), sizeof[cstr]())

    return __local__res

}

unsafe fn Mymap_emplace_or_assign(__param_self_: *mut Mymap, __param_rkey: c_int, __param_rmapped: *const i8) -> Mymap_result {
    var __local__res: Mymap_result = Mymap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local__res as *const Mymap_result)).inserted {
        ((*(*(&raw const __local__res as *const Mymap_result)).ref).first = __param_rkey)
    } else {
        if ((if (*(&raw const __local__res as *const Mymap_result)).ref == null: 1 else: 0) != 0) {
            return __local__res
        }

        cstr_drop((((&raw const (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *const cstr) as *mut cstr) as *const cstr))

    }

    let __ci_copy_36: cstr = cstr_from(__param_rmapped)
    with_memcpy((&raw mut (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *mut u8), (&raw const __ci_copy_36 as *const u8), sizeof[cstr]())

    return __local__res

}

unsafe fn Mymap_at(__param_self_: *const Mymap, __param_rkey: c_int) -> *const cstr {
    var __local_it_: Mymap_iter

    return ((((&raw const Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)).second as *const cstr) as *mut cstr) as *const cstr))

}

unsafe fn Mymap_at_mut(__param_self_: *mut Mymap, __param_rkey: c_int) -> *mut cstr {
    var __local_it_: Mymap_iter

    return (((&raw const Mymap_find_it((__param_self_ as *const Mymap), __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)).second as *const cstr) as *mut cstr))

}

unsafe fn Mymap_end(__param_self_: *const Mymap) -> Mymap_iter {
    var __local_it_: Mymap_iter


    (__local_it_.ref = ((null as *mut Mymap_value)))

    (__local_it_._top = ((0 as c_int)))

    (__local_it_._tn = ((0 as c_int)))


    return __local_it_

}

fn Mymap_advance(__param_it_: Mymap_iter, __param_n: c_ulong) -> Mymap_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const Mymap_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { Mymap_next((&raw mut __param_it_ as *mut Mymap_iter)) }

    }

    return __param_it_

}

unsafe fn Mymap_eq(__param_self_: *const Mymap, __param_other: *const Mymap) -> bool {
    if ((if Mymap_size(__param_self_) != Mymap_size(__param_other): 1 else: 0) != 0) {
        return false
    }

    var __local_i: Mymap_iter = Mymap_begin(__param_self_)

    var __local_j: Mymap_iter = Mymap_begin(__param_other)


    while ((*(&raw const __local_i as *const Mymap_iter)).ref != null) {
        var __local__rx: c_int = (*((&raw const (*(*(&raw const __local_i as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int))

        var __local__ry: c_int = (*((&raw const (*(*(&raw const __local_j as *const Mymap_iter)).ref).first as *const c_int) as *mut c_int))


        if ((if not ((if (*(&raw const __local__rx as *const c_int)) == (*(&raw const __local__ry as *const c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return false
        }


        Mymap_next((&raw mut __local_i as *mut Mymap_iter))

        Mymap_next((&raw mut __local_j as *mut Mymap_iter))


    }

    return true

}

unsafe fn Mymap_insert(__param_self_: *mut Mymap, __param__key: c_int, __param__mapped: cstr) -> Mymap_result {
    var __local__res: Mymap_result = Mymap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut c_int)))

    if (*(&raw const __local__res as *const Mymap_result)).inserted {
        ((*((&raw const (*(*(&raw const __local__res as *const Mymap_result)).ref).first as *const c_int) as *mut c_int)) = __param__key)

        with_memcpy((&raw mut (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *mut u8), (&raw const __param__mapped as *const u8), sizeof[cstr]())

    } else {

        cstr_drop(((&raw mut __param__mapped as *mut cstr) as *const cstr))

    }

    return __local__res

}

unsafe fn Mymap_push(__param_self_: *mut Mymap, __param__val: Mymap_value) -> *mut Mymap_value {
    var __local__res: Mymap_result = Mymap_insert_entry_(__param_self_, (*((&raw const (*(&raw mut __param__val as *mut Mymap_value)).first as *const c_int) as *mut c_int)))

    if ((if not (*(&raw const __local__res as *const Mymap_result)).inserted: 1 else: 0) != 0) {
        Mymap_value_drop((__param_self_ as *const Mymap), (*(&raw const __local__res as *const Mymap_result)).ref)
    }

    with_memcpy((&raw mut (*((*(&raw const __local__res as *const Mymap_result)).ref)) as *mut u8), (&raw const __param__val as *const u8), sizeof[Mymap_value]())

    return (*(&raw const __local__res as *const Mymap_result)).ref

}

unsafe fn Mymap_put(__param_self_: *mut Mymap, __param_rkey: c_int, __param_rmapped: *const i8) -> Mymap_result {
    return Mymap_emplace_or_assign(__param_self_, __param_rkey, __param_rmapped)

}

unsafe fn Mymap_put_n(__param_self_: *mut Mymap, __param_raw: *const Mymap_raw, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        Mymap_put(__param_self_, (*__local_raw).first, (*__local_raw).second)

        (__local_raw = __local_raw + 1)

    }

}

fn Mymap_init() -> Mymap {
    var __local_cx: Mymap = Mymap.zeroed()

    return __local_cx

}

unsafe fn Mymap_from_n(__param_raw: *const Mymap_raw, __param_n: c_long) -> Mymap {
    var __local_cx: Mymap = Mymap.zeroed()

    Mymap_put_n((&raw mut __local_cx as *mut Mymap), __param_raw, __param_n)

    return __local_cx

}

fn Mymap_with_capacity(__param_cap: c_long) -> Mymap {
    var __local_cx: Mymap = Mymap.zeroed()

    unsafe { Mymap_reserve((&raw mut __local_cx as *mut Mymap), __param_cap) }

    return __local_cx

}

unsafe fn Mymap_new_node_(__param_self_: *mut Mymap, __param_level: c_int) -> c_int {
    var __local_tn: c_int

    if ((if (*__param_self_).disp != 0: 1 else: 0) != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as c_int)))

    } else {
        if ((if (*__param_self_).head == (*__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not Mymap_reserve(__param_self_, (((((*__param_self_).head * 3) / 2) + 4) as c_long)): 1 else: 0) != 0) {
                return 0
            }
        }

        ((*__param_self_).head = (*__param_self_).head + 1)

        (__local_tn = (*__param_self_).head)


    }

    var __local_dn: *mut Mymap_node = (((&raw const ((*__param_self_).nodes[__local_tn]) as *const Mymap_node) as *mut Mymap_node))

    ((*__local_dn).link[1] = ((0 as c_int)))

    ((*__local_dn).link[0] = (((*__local_dn).link[1] as c_int)))


    ((*__local_dn).level = ((__param_level as c_char)))

    return __local_tn

}

unsafe fn Mymap_skew_(__param_d: *mut Mymap_node, __param_tn: c_int) -> c_int {
    var __local_tn = __param_tn
    var __ci_expr_logic_0: c_int = 0

    if ((if __local_tn != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (__param_d[(__param_d[__local_tn]).link[0]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tmp: c_int = (((__param_d[__local_tn]).link[0] as c_int))

        ((__param_d[__local_tn]).link[0] = (((__param_d[__local_tmp]).link[1] as c_int)))

        ((__param_d[__local_tmp]).link[1] = __local_tn)

        (__local_tn = __local_tmp)

    }


    return __local_tn

}

unsafe fn Mymap_split_(__param_d: *mut Mymap_node, __param_tn: c_int) -> c_int {
    var __local_tn = __param_tn
    if ((if (__param_d[(__param_d[(__param_d[__local_tn]).link[1]]).link[1]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0) {
        var __local_tmp: c_int = (((__param_d[__local_tn]).link[1] as c_int))

        ((__param_d[__local_tn]).link[1] = (((__param_d[__local_tmp]).link[0] as c_int)))

        ((__param_d[__local_tmp]).link[0] = __local_tn)

        (__local_tn = __local_tmp)

        ((__param_d[__local_tn]).level = (__param_d[__local_tn]).level + 1)

    }

    return __local_tn

}

unsafe fn Mymap_insert_entry_i_(__param_self_: *mut Mymap, __param_tn: c_int, __param_rkey: *const c_int, __param__res: *mut Mymap_result) -> c_int {
    var __local_up: List[c_int] = [0; 64]

    var __local_tx: c_int = __param_tn


    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    var __local_c: c_int

    var __local_top: c_int = ((0 as c_int))

    var __local_dir: c_int = ((0 as c_int))


    while (__local_tx != 0) {
        var __ci_expr_old_0: c_int = __local_top

        (__local_top = __local_top + 1)

        (__local_up[__ci_expr_old_0] = __local_tx)


        var __local__raw: c_int = (*((&raw const (*((&raw const (__local_d[__local_tx]).value as *const Mymap_value) as *mut Mymap_value)).first as *const c_int) as *mut c_int))

        (__local_c = ((((if (*__param_rkey) < (*(&raw const __local__raw as *const c_int)): 1 else: 0) - (if (*(&raw const __local__raw as *const c_int)) < (*__param_rkey): 1 else: 0)) as c_int)))

        if ((if __local_c == 0: 1 else: 0) != 0) {
            ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Mymap_value) as *mut Mymap_value)))

            return __param_tn

        }


        (__local_dir = (((if __local_c < 0: 1 else: 0) as c_int)))

        (__local_tx = (((__local_d[__local_tx]).link[__local_dir] as c_int)))

    }

    (__local_tx = ((Mymap_new_node_(__param_self_, (1 as c_int)) as c_int)))

    if ((if __local_tx == 0: 1 else: 0) != 0) {
        return 0
    }


    (__local_d = (*__param_self_).nodes)

    ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Mymap_value) as *mut Mymap_value)))

    ((*__param__res).inserted = true)

    if ((if __local_top == 0: 1 else: 0) != 0) {
        return __local_tx
    }

    ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = __local_tx)

    while true {
        var __ci_expr_old_1: c_int = __local_top

        (__local_top = __local_top - 1)

        if (not (__ci_expr_old_1 != 0)) {
            break
        }

        if ((if __local_top != 0: 1 else: 0) != 0) {
            (__local_dir = (((if (__local_d[__local_up[(__local_top - 1)]]).link[1] == __local_up[__local_top]: 1 else: 0) as c_int)))
        }

        (__local_up[__local_top] = ((Mymap_skew_(__local_d, (__local_up[__local_top] as c_int)) as c_int)))

        (__local_up[__local_top] = ((Mymap_split_(__local_d, (__local_up[__local_top] as c_int)) as c_int)))

        if (__local_top != 0) {
            ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = ((__local_up[__local_top] as c_int)))
        }

    }

    return __local_up[0]

}

unsafe fn Mymap_erase_r_(__param_self_: *mut Mymap, __param_tn: c_int, __param_rkey: *const c_int, __param_erased: *mut c_int) -> c_int {
    var __local_tn = __param_tn
    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    if ((if __local_tn == 0: 1 else: 0) != 0) {
        return 0
    }

    var __local_raw: c_int = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)).first as *const c_int) as *mut c_int))

    var __local_tx: c_int

    var __local_c: c_int = ((((if (*__param_rkey) < (*(&raw mut __local_raw as *mut c_int)): 1 else: 0) - (if (*(&raw mut __local_raw as *mut c_int)) < (*__param_rkey): 1 else: 0)) as c_int))

    if ((if __local_c != 0: 1 else: 0) != 0) {
        ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] = ((Mymap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] as c_int), __param_rkey, __param_erased) as c_int)))
    } else {
        var __ci_expr_old_0: c_int = (*__param_erased)

        ((*__param_erased) = (*__param_erased) + 1)

        if ((if __ci_expr_old_0 == 0: 1 else: 0) != 0) {
            Mymap_value_drop((__param_self_ as *const Mymap), ((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value))
        }


        var __ci_expr_logic_1: c_int = 0

        if ((__local_d[__local_tn]).link[0] != 0) {
            (__ci_expr_logic_1 = (if (__local_d[__local_tn]).link[1] != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_tx = (((__local_d[__local_tn]).link[0] as c_int)))

            while ((__local_d[__local_tx]).link[1] != 0) {
                (__local_tx = (((__local_d[__local_tx]).link[1] as c_int)))
            }

            with_memcpy((&raw mut (__local_d[__local_tn]).value as *mut u8), (&raw const (__local_d[__local_tx]).value as *const u8), sizeof[Mymap_value]())

            (__local_raw = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)).first as *const c_int) as *mut c_int)))

            ((__local_d[__local_tn]).link[0] = ((Mymap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[0] as c_int), ((&raw mut __local_raw as *mut c_int) as *const c_int), __param_erased) as c_int)))

        } else {
            (__local_tx = __local_tn)

            (__local_tn = (((__local_d[__local_tn]).link[(if (__local_d[__local_tn]).link[0] == 0: 1 else: 0)] as c_int)))

            ((__local_d[__local_tx]).link[1] = (*__param_self_).disp)

            ((*__param_self_).disp = __local_tx)

        }


    }

    (__local_tx = (((__local_d[__local_tn]).link[1] as c_int)))

    var __ci_expr_logic_2: c_int

    if ((if (__local_d[(__local_d[__local_tn]).link[0]]).level < ((__local_d[__local_tn]).level - 1): 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (__local_d[__local_tx]).level < ((__local_d[__local_tn]).level - 1): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        ((__local_d[__local_tn]).level = (__local_d[__local_tn]).level - 1)

        if ((if (__local_d[__local_tx]).level > (__local_d[__local_tn]).level: 1 else: 0) != 0) {
            ((__local_d[__local_tx]).level = (__local_d[__local_tn]).level)
        }


        (__local_tn = ((Mymap_skew_(__local_d, __local_tn) as c_int)))

        ((__local_d[__local_tn]).link[1] = ((Mymap_skew_(__local_d, ((__local_d[__local_tn]).link[1] as c_int)) as c_int)))

        (__local_tx = (((__local_d[__local_tn]).link[1] as c_int)))


        ((__local_d[__local_tx]).link[1] = ((Mymap_skew_(__local_d, ((__local_d[__local_tx]).link[1] as c_int)) as c_int)))

        (__local_tn = ((Mymap_split_(__local_d, __local_tn) as c_int)))

        ((__local_d[__local_tn]).link[1] = ((Mymap_split_(__local_d, ((__local_d[__local_tn]).link[1] as c_int)) as c_int)))

    }


    return __local_tn

}

unsafe fn Mymap_clone_r_(__param_self_: *mut Mymap, __param_src: *mut Mymap_node, __param_sn: c_int) -> c_int {
    if ((if __param_sn == 0: 1 else: 0) != 0) {
        return 0
    }

    var __local_tx: c_int

    var __local_tn: c_int = ((Mymap_new_node_(__param_self_, ((__param_src[__param_sn]).level as c_int)) as c_int))


    let __ci_copy_31: Mymap_value = Mymap_value_clone((__param_self_ as *const Mymap), (__param_src[__param_sn]).value)
    with_memcpy((&raw mut ((*__param_self_).nodes[__local_tn]).value as *mut u8), (&raw const __ci_copy_31 as *const u8), sizeof[Mymap_value]())

    (__local_tx = ((Mymap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[0] as c_int)) as c_int)))

    (((*__param_self_).nodes[__local_tn]).link[0] = __local_tx)

    (__local_tx = ((Mymap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[1] as c_int)) as c_int)))

    (((*__param_self_).nodes[__local_tn]).link[1] = __local_tx)

    return __local_tn

}

unsafe fn Mymap_drop_r_(__param_s: *mut Mymap, __param_tn: c_int) {
    if ((if __param_tn != 0: 1 else: 0) != 0) {
        Mymap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[0] as c_int))

        Mymap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[1] as c_int))

        Mymap_value_drop((__param_s as *const Mymap), ((&raw const ((*__param_s).nodes[__param_tn]).value as *const Mymap_value) as *mut Mymap_value))

    }

}

@[repr(C)]
pub type ctest_sortedmap_erase_run__c_i2_anon { _ref: *const *mut Mymap = null, ref: *mut *mut Mymap = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_sortedmap_erase_run__c_i2_anon
fn ctest_sortedmap_erase_run() {
    var __local_m1: Mymap = Mymap.zeroed()

    var __local_res: Mymap = Mymap.zeroed()

    unsafe { Mymap_insert((&raw mut __local_m1 as *mut Mymap), (1 as c_int), unsafe { cstr_from_n(c"A".ptr, ((((2 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) }) }

    unsafe { Mymap_insert((&raw mut __local_m1 as *mut Mymap), (2 as c_int), unsafe { cstr_from_n(c"B".ptr, ((((2 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) }) }

    unsafe { Mymap_insert((&raw mut __local_m1 as *mut Mymap), (3 as c_int), unsafe { cstr_from_n(c"C".ptr, ((((2 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) }) }

    unsafe { Mymap_insert((&raw mut __local_m1 as *mut Mymap), (4 as c_int), unsafe { cstr_from_n(c"D".ptr, ((((2 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) }) }

    unsafe { Mymap_insert((&raw mut __local_m1 as *mut Mymap), (5 as c_int), unsafe { cstr_from_n(c"E".ptr, ((((2 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) }) }

    var __ci_expr_lit_0: [Mymap_raw; 5] = [Mymap_raw { first: 1, second: (("A" as *mut c_char) as *const i8) }, Mymap_raw { first: 2, second: (("B" as *mut c_char) as *const i8) }, Mymap_raw { first: 3, second: (("C" as *mut c_char) as *const i8) }, Mymap_raw { first: 4, second: (("D" as *mut c_char) as *const i8) }, Mymap_raw { first: 5, second: (("E" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_0[0] as *mut Mymap_raw), (5 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m1 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (23 as c_int))

    unsafe { Mymap_erase_at((&raw mut __local_m1 as *mut Mymap), Mymap_advance(unsafe { Mymap_begin(((&raw mut __local_m1 as *mut Mymap) as *const Mymap)) }, (1 as c_ulong))) }

    var __ci_expr_lit_1: [Mymap_raw; 4] = [Mymap_raw { first: 1, second: (("A" as *mut c_char) as *const i8) }, Mymap_raw { first: 3, second: (("C" as *mut c_char) as *const i8) }, Mymap_raw { first: 4, second: (("D" as *mut c_char) as *const i8) }, Mymap_raw { first: 5, second: (("E" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_1[0] as *mut Mymap_raw), (4 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m1 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (28 as c_int))

    var __local_m2: Mymap = with 0 as __ci_expr_seq_21 {
        var __ci_expr_lit_2: [Mymap_raw; 5] = [Mymap_raw { first: 10, second: (("Bob" as *mut c_char) as *const i8) }, Mymap_raw { first: 11, second: (("Rob" as *mut c_char) as *const i8) }, Mymap_raw { first: 12, second: (("Robert" as *mut c_char) as *const i8) }, Mymap_raw { first: 13, second: (("Bert" as *mut c_char) as *const i8) }, Mymap_raw { first: 14, second: (("Bobby" as *mut c_char) as *const i8) }]
        unsafe { Mymap_from_n((&__ci_expr_lit_2[0] as *mut Mymap_raw), (5 as c_long)) }
    }

    var __local_it1: Mymap_iter = Mymap_advance(unsafe { Mymap_begin(((&raw mut __local_m2 as *mut Mymap) as *const Mymap)) }, (1 as c_ulong))

    var __local_it2: Mymap_iter = unsafe { Mymap_find(((&raw mut __local_m2 as *mut Mymap) as *const Mymap), unsafe { Mymap_back(((&raw mut __local_m2 as *mut Mymap) as *const Mymap)) }.first) }

    unsafe { Mymap_erase_range((&raw mut __local_m2 as *mut Mymap), __local_it1, __local_it2) }

    var __ci_expr_lit_3: [Mymap_raw; 2] = [Mymap_raw { first: 10, second: (("Bob" as *mut c_char) as *const i8) }, Mymap_raw { first: 14, second: (("Bobby" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_3[0] as *mut Mymap_raw), (2 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m2 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (48 as c_int))

    var __local_m3: Mymap = Mymap.zeroed()

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (1 as c_int), c"red".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (2 as c_int), c"yellow".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (3 as c_int), c"blue".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (4 as c_int), c"green".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (5 as c_int), c"orange".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (6 as c_int), c"purple".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (7 as c_int), c"pink".ptr) }

    var __ci_expr_lit_4: [Mymap_raw; 7] = [Mymap_raw { first: 1, second: (("red" as *mut c_char) as *const i8) }, Mymap_raw { first: 2, second: (("yellow" as *mut c_char) as *const i8) }, Mymap_raw { first: 3, second: (("blue" as *mut c_char) as *const i8) }, Mymap_raw { first: 4, second: (("green" as *mut c_char) as *const i8) }, Mymap_raw { first: 5, second: (("orange" as *mut c_char) as *const i8) }, Mymap_raw { first: 6, second: (("purple" as *mut c_char) as *const i8) }, Mymap_raw { first: 7, second: (("pink" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_4[0] as *mut Mymap_raw), (7 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (63 as c_int))

    var __local_count: c_int = ((unsafe { Mymap_erase((&raw mut __local_m3 as *mut Mymap), (2 as c_int)) } as c_int))

    assert_compare((1 as c_int), c"==".ptr, (1 as c_long), (__local_count as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (67 as c_int))

    var __ci_expr_lit_5: [Mymap_raw; 6] = [Mymap_raw { first: 1, second: (("red" as *mut c_char) as *const i8) }, Mymap_raw { first: 3, second: (("blue" as *mut c_char) as *const i8) }, Mymap_raw { first: 4, second: (("green" as *mut c_char) as *const i8) }, Mymap_raw { first: 5, second: (("orange" as *mut c_char) as *const i8) }, Mymap_raw { first: 6, second: (("purple" as *mut c_char) as *const i8) }, Mymap_raw { first: 7, second: (("pink" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_5[0] as *mut Mymap_raw), (6 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (70 as c_int))

    loop {
        var __local__c_i2: ctest_sortedmap_erase_run__c_i2_anon = ctest_sortedmap_erase_run__c_i2_anon.zeroed()

        var __ci_expr_lit_6: [*mut Mymap; 4] = [(&raw mut __local_m1 as *mut Mymap), (&raw mut __local_m2 as *mut Mymap), (&raw mut __local_m3 as *mut Mymap), (&raw mut __local_res as *mut Mymap)]

        __local__c_i2 = ctest_sortedmap_erase_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_6)[0] as *mut *mut Mymap) as *const *mut Mymap)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon))._ref as *mut *mut Mymap)
        __local__c_i2.size = (((((4 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[Mymap]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { Mymap_drop(((*((*(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).ref)) as *const Mymap)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

fn Intmap_clone(__param_tree: Intmap) -> Intmap {
    var __local_out: Intmap = __param_tree

    (__local_out.capacity = ((0 as c_int)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Intmap)).capacity)

    (__local_out.head = (unsafe *(&raw const __local_out as *const Intmap)).size)

    (__local_out.disp = (unsafe *(&raw const __local_out as *const Intmap)).head)

    (__local_out.root = (unsafe *(&raw const __local_out as *const Intmap)).disp)


    (__local_out.nodes = ((null as *mut Intmap_node)))

    unsafe { Intmap_reserve((&raw mut __local_out as *mut Intmap), ((*(&raw const __param_tree as *const Intmap)).size as c_long)) }

    (__local_out.root = ((unsafe { Intmap_clone_r_((&raw mut __local_out as *mut Intmap), (*(&raw const __param_tree as *const Intmap)).nodes, (*(&raw const __param_tree as *const Intmap)).root) } as c_int)))

    return __local_out

}

unsafe fn Intmap_drop(__param_cself: *const Intmap) {
    var __local_self_: *mut Intmap = ((__param_cself as *mut Intmap))

    if ((if (*__local_self_).nodes == null: 1 else: 0) != 0) {
        return
    }

    Intmap_drop_r_(__local_self_, (*__local_self_).root)

    (sizeof[Intmap_node]() as usize)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))


}

unsafe fn Intmap_reserve(__param_self_: *mut Intmap, __param_cap: c_long) -> bool {
    if ((if __param_cap <= (*__param_self_).capacity: 1 else: 0) != 0) {
        return false
    }

    var __local_nodes: *mut Intmap_node = (((with_realloc((((*__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: (((__param_cap + 1) * (sizeof[Intmap_node]() as c_long)) as c_long) else: ((((*__param_self_).capacity + 1) * (sizeof[Intmap_node]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_node))

    if ((if __local_nodes == null: 1 else: 0) != 0) {
        return false
    }

    ((__local_nodes[0]) = ((Intmap_node.zeroed() as Intmap_node)))

    ((*__param_self_).nodes = __local_nodes)

    ((*__param_self_).capacity = ((__param_cap as c_int)))

    return true

}

unsafe fn Intmap_find_it(__param_self_: *const Intmap, __param_rkey: c_int, __param_out: *mut Intmap_iter) -> *mut Intmap_value {
    var __local_tn: c_int = (*__param_self_).root

    var __local_d: *mut Intmap_node = with 0 as __ci_expr_seq_6 {
        ((*__param_out)._d = (*__param_self_).nodes)
        (*__param_out)._d
    }

    ((*__param_out)._top = ((0 as c_int)))

    while (__local_tn != 0) {
        var __local_c: c_int

        var __local__raw: c_int = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)).first as *const c_int) as *mut c_int))

        (__local_c = ((((if (*(&raw mut __param_rkey as *mut c_int)) < (*(&raw const __local__raw as *const c_int)): 1 else: 0) - (if (*(&raw const __local__raw as *const c_int)) < (*(&raw mut __param_rkey as *mut c_int)): 1 else: 0)) as c_int)))

        if ((if __local_c < 0: 1 else: 0) != 0) {
            (__local_tn = (((__local_d[__local_tn]).link[1] as c_int)))
        } else {
            if ((if __local_c > 0: 1 else: 0) != 0) {
                var __ci_expr_old_0: c_int = (*__param_out)._top

                ((*__param_out)._top = (*__param_out)._top + 1)

                ((*__param_out)._st[__ci_expr_old_0] = __local_tn)


                (__local_tn = (((__local_d[__local_tn]).link[0] as c_int)))

            } else {
                ((*__param_out)._tn = (((__local_d[__local_tn]).link[1] as c_int)))

                ((*__param_out).ref = (((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)))

                return (*__param_out).ref


            }
        }


    }

    ((*__param_out).ref = ((null as *mut Intmap_value)))

    return (*__param_out).ref


}

unsafe fn Intmap_lower_bound(__param_self_: *const Intmap, __param_rkey: c_int) -> Intmap_iter {
    var __local_it_: Intmap_iter

    Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter))

    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __local_it_ as *const Intmap_iter)).ref == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const __local_it_ as *const Intmap_iter))._top != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tn: c_int = with 0 as __ci_expr_seq_11 {
            (__local_it_._top = (*(&raw const __local_it_ as *const Intmap_iter))._top - 1)
            ((*(&raw const __local_it_ as *const Intmap_iter))._st[(*(&raw const __local_it_ as *const Intmap_iter))._top] as c_int)
        }

        (__local_it_._tn = ((((*(&raw const __local_it_ as *const Intmap_iter))._d[__local_tn]).link[1] as c_int)))

        (__local_it_.ref = (((&raw const (__local_it_._d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)))

    }


    return __local_it_

}

unsafe fn Intmap_front(__param_self_: *const Intmap) -> *mut Intmap_value {
    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    var __local_tn: c_int = (*__param_self_).root

    while ((__local_d[__local_tn]).link[0] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[0] as c_int)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value))

}

unsafe fn Intmap_back(__param_self_: *const Intmap) -> *mut Intmap_value {
    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    var __local_tn: c_int = (*__param_self_).root

    while ((__local_d[__local_tn]).link[1] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[1] as c_int)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value))

}

unsafe fn Intmap_erase(__param_self_: *mut Intmap, __param_rkey: c_int) -> c_int {
    var __local_erased: c_int = ((0 as c_int))

    var __local_root: c_int = ((Intmap_erase_r_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut c_int) as *const c_int), (&raw mut __local_erased as *mut c_int)) as c_int))

    if ((if __local_erased == 0: 1 else: 0) != 0) {
        return 0
    }

    ((*__param_self_).root = __local_root)

    ((*__param_self_).size = (*__param_self_).size - 1)

    return 1

}

unsafe fn Intmap_erase_at(__param_self_: *mut Intmap, __param_it_: Intmap_iter) -> Intmap_iter {
    var __local_raw: c_int = (*((&raw const (*(*(&raw const __param_it_ as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))

    Intmap_next((&raw mut __param_it_ as *mut Intmap_iter))

    if ((if (*(&raw const __param_it_ as *const Intmap_iter)).ref != null: 1 else: 0) != 0) {
        var __local_nxt: c_int = (*((&raw const (*(*(&raw const __param_it_ as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))

        Intmap_erase(__param_self_, __local_raw)

        Intmap_find_it((__param_self_ as *const Intmap), __local_nxt, (&raw mut __param_it_ as *mut Intmap_iter))

    } else {
        Intmap_erase(__param_self_, __local_raw)
    }

    return __param_it_

}

unsafe fn Intmap_erase_range(__param_self_: *mut Intmap, __param_it1: Intmap_iter, __param_it2: Intmap_iter) -> Intmap_iter {
    var __local_it1 = __param_it1
    if ((if (*(&raw const __param_it2 as *const Intmap_iter)).ref == null: 1 else: 0) != 0) {
        while ((if (*(&raw const __local_it1 as *const Intmap_iter)).ref != null: 1 else: 0) != 0) {
            let __ci_copy_25: Intmap_iter = Intmap_erase_at(__param_self_, __local_it1)
            with_memcpy((&raw mut __local_it1 as *mut u8), (&raw const __ci_copy_25 as *const u8), sizeof[Intmap_iter]())
        }

        return __local_it1

    }

    var __local_k1: c_int = (*((&raw const (*(*(&raw const __local_it1 as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))

    var __local_k2: c_int = (*((&raw const (*(*(&raw const __param_it2 as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))


    var __local_r1: c_int = (*(&raw mut __local_k1 as *mut c_int))

    while true {
        if ((if with_memcmp((((&raw mut __local_k1 as *mut c_int) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut c_int) as *const c_void) as *const u8), ((sizeof[c_int]() as c_ulong) as i64)) == 0: 1 else: 0) != 0) {
            return __local_it1
        }

        Intmap_next((&raw mut __local_it1 as *mut Intmap_iter))

        (__local_k1 = (*((&raw const (*(*(&raw const __local_it1 as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int)))

        Intmap_erase(__param_self_, __local_r1)

        (__local_r1 = (*(&raw mut __local_k1 as *mut c_int)))

        Intmap_find_it((__param_self_ as *const Intmap), __local_r1, (&raw mut __local_it1 as *mut Intmap_iter))

    }

}

unsafe fn Intmap_begin(__param_self_: *const Intmap) -> Intmap_iter {
    var __local_it_: Intmap_iter

    (__local_it_.ref = ((null as *mut Intmap_value)))

    (__local_it_._d = (*__param_self_).nodes)

    (__local_it_._top = ((0 as c_int)))


    (__local_it_._tn = (*__param_self_).root)

    if ((*(&raw const __local_it_ as *const Intmap_iter))._tn != 0) {
        Intmap_next((&raw mut __local_it_ as *mut Intmap_iter))
    }

    return __local_it_

}

unsafe fn Intmap_next(__param_it_: *mut Intmap_iter) -> Unit {
    var __local_tn: c_int = (*__param_it_)._tn

    var __ci_expr_logic_0: c_int

    if ((*__param_it_)._top != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_tn != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        while (__local_tn != 0) {
            var __ci_expr_old_1: c_int = (*__param_it_)._top

            ((*__param_it_)._top = (*__param_it_)._top + 1)

            ((*__param_it_)._st[__ci_expr_old_1] = __local_tn)


            (__local_tn = ((((*__param_it_)._d[__local_tn]).link[0] as c_int)))

        }

        ((*__param_it_)._top = (*__param_it_)._top - 1)

        (__local_tn = (((*__param_it_)._st[(*__param_it_)._top] as c_int)))


        ((*__param_it_)._tn = ((((*__param_it_)._d[__local_tn]).link[1] as c_int)))

        ((*__param_it_).ref = (((&raw const ((*__param_it_)._d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)))

    } else {
        ((*__param_it_).ref = ((null as *mut Intmap_value)))
    }


}

unsafe fn Intmap_is_empty(__param_self_: *const Intmap) -> bool {
    return (((*__param_self_).size == 0))

}

unsafe fn Intmap_size(__param_self_: *const Intmap) -> c_long {
    return (((*__param_self_).size as c_long))

}

unsafe fn Intmap_capacity(__param_self_: *const Intmap) -> c_long {
    return (((*__param_self_).capacity as c_long))

}

unsafe fn Intmap_find(__param_self_: *const Intmap, __param_rkey: c_int) -> Intmap_iter {
    var __local_it_: Intmap_iter

    Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter))

    return __local_it_

}

unsafe fn Intmap_contains(__param_self_: *const Intmap, __param_rkey: c_int) -> bool {
    var __local_it_: Intmap_iter

    return ((Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) != null))

}

unsafe fn Intmap_get(__param_self_: *const Intmap, __param_rkey: c_int) -> *const Intmap_value {
    var __local_it_: Intmap_iter

    return ((Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) as *const Intmap_value))

}

unsafe fn Intmap_get_mut(__param_self_: *mut Intmap, __param_rkey: c_int) -> *mut Intmap_value {
    var __local_it_: Intmap_iter

    return ((Intmap_find_it((__param_self_ as *const Intmap), __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) as *mut Intmap_value))

}

unsafe fn Intmap_value_toraw(__param_val: *const Intmap_value) -> Intmap_raw {
    return ((Intmap_raw { first: ((*(&raw const (*__param_val).first as *const c_int))), second: ((*(&raw const (*__param_val).second as *const c_int))) } as Intmap_raw))

}

unsafe fn Intmap_value_drop(__param_self_: *const Intmap, __param_val: *mut Intmap_value) {
    return
}

unsafe fn Intmap_move(__param_self_: *mut Intmap) -> Intmap {
    var __local_m: Intmap = (*__param_self_)

    ((*__param_self_).head = ((0 as c_int)))

    ((*__param_self_).disp = (*__param_self_).head)

    ((*__param_self_).root = (*__param_self_).disp)

    ((*__param_self_).size = (*__param_self_).root)

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).nodes = ((null as *mut Intmap_node)))

    return __local_m

}

unsafe fn Intmap_clear(__param_self_: *mut Intmap) -> Unit {
    Intmap_drop((__param_self_ as *const Intmap))

    Intmap_move(__param_self_)

}

unsafe fn Intmap_take(__param_self_: *mut Intmap, __param_unowned: Intmap) -> Unit {
    Intmap_drop((__param_self_ as *const Intmap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Intmap]())

}

unsafe fn Intmap_value_clone(__param_self_: *const Intmap, __param__val: Intmap_value) -> Intmap_value {

    ((*((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const c_int) as *mut c_int)) = (*((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const c_int) as *mut c_int)))

    (__param__val.second = (*(&raw const __param__val as *const Intmap_value)).second)

    return __param__val

}

unsafe fn Intmap_copy(__param_self_: *mut Intmap, __param_other: *const Intmap) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Intmap_drop((__param_self_ as *const Intmap))

    let __ci_copy_18: Intmap = Intmap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[Intmap]())

}

unsafe fn Intmap_shrink_to_fit(__param_self_: *mut Intmap) -> Unit {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        return
    }

    var __local_tmp: Intmap = Intmap_clone((*__param_self_))

    Intmap_drop((__param_self_ as *const Intmap))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __local_tmp as *const u8), sizeof[Intmap]())

}

unsafe fn Intmap_insert_entry_(__param_self_: *mut Intmap, __param_rkey: c_int) -> Intmap_result {
    var __local_res: Intmap_result = Intmap_result.zeroed()

    var __local_tn: c_int = ((Intmap_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut c_int) as *const c_int), (&raw mut __local_res as *mut Intmap_result)) as c_int))

    ((*__param_self_).root = __local_tn)

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
    var __local_it_: Intmap_iter

    return ((((&raw const Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)).second as *const c_int) as *mut c_int) as *const c_int))

}

unsafe fn Intmap_at_mut(__param_self_: *mut Intmap, __param_rkey: c_int) -> *mut c_int {
    var __local_it_: Intmap_iter

    return (((&raw const Intmap_find_it((__param_self_ as *const Intmap), __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)).second as *const c_int) as *mut c_int))

}

unsafe fn Intmap_end(__param_self_: *const Intmap) -> Intmap_iter {
    var __local_it_: Intmap_iter


    (__local_it_.ref = ((null as *mut Intmap_value)))

    (__local_it_._top = ((0 as c_int)))

    (__local_it_._tn = ((0 as c_int)))


    return __local_it_

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

unsafe fn Intmap_eq(__param_self_: *const Intmap, __param_other: *const Intmap) -> bool {
    if ((if Intmap_size(__param_self_) != Intmap_size(__param_other): 1 else: 0) != 0) {
        return false
    }

    var __local_i: Intmap_iter = Intmap_begin(__param_self_)

    var __local_j: Intmap_iter = Intmap_begin(__param_other)


    while ((*(&raw const __local_i as *const Intmap_iter)).ref != null) {
        var __local__rx: c_int = (*((&raw const (*(*(&raw const __local_i as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))

        var __local__ry: c_int = (*((&raw const (*(*(&raw const __local_j as *const Intmap_iter)).ref).first as *const c_int) as *mut c_int))


        if ((if not ((if (*(&raw const __local__rx as *const c_int)) == (*(&raw const __local__ry as *const c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return false
        }


        Intmap_next((&raw mut __local_i as *mut Intmap_iter))

        Intmap_next((&raw mut __local_j as *mut Intmap_iter))


    }

    return true

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

unsafe fn Intmap_new_node_(__param_self_: *mut Intmap, __param_level: c_int) -> c_int {
    var __local_tn: c_int

    if ((if (*__param_self_).disp != 0: 1 else: 0) != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as c_int)))

    } else {
        if ((if (*__param_self_).head == (*__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not Intmap_reserve(__param_self_, (((((*__param_self_).head * 3) / 2) + 4) as c_long)): 1 else: 0) != 0) {
                return 0
            }
        }

        ((*__param_self_).head = (*__param_self_).head + 1)

        (__local_tn = (*__param_self_).head)


    }

    var __local_dn: *mut Intmap_node = (((&raw const ((*__param_self_).nodes[__local_tn]) as *const Intmap_node) as *mut Intmap_node))

    ((*__local_dn).link[1] = ((0 as c_int)))

    ((*__local_dn).link[0] = (((*__local_dn).link[1] as c_int)))


    ((*__local_dn).level = ((__param_level as c_char)))

    return __local_tn

}

unsafe fn Intmap_skew_(__param_d: *mut Intmap_node, __param_tn: c_int) -> c_int {
    var __local_tn = __param_tn
    var __ci_expr_logic_0: c_int = 0

    if ((if __local_tn != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (__param_d[(__param_d[__local_tn]).link[0]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tmp: c_int = (((__param_d[__local_tn]).link[0] as c_int))

        ((__param_d[__local_tn]).link[0] = (((__param_d[__local_tmp]).link[1] as c_int)))

        ((__param_d[__local_tmp]).link[1] = __local_tn)

        (__local_tn = __local_tmp)

    }


    return __local_tn

}

unsafe fn Intmap_split_(__param_d: *mut Intmap_node, __param_tn: c_int) -> c_int {
    var __local_tn = __param_tn
    if ((if (__param_d[(__param_d[(__param_d[__local_tn]).link[1]]).link[1]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0) {
        var __local_tmp: c_int = (((__param_d[__local_tn]).link[1] as c_int))

        ((__param_d[__local_tn]).link[1] = (((__param_d[__local_tmp]).link[0] as c_int)))

        ((__param_d[__local_tmp]).link[0] = __local_tn)

        (__local_tn = __local_tmp)

        ((__param_d[__local_tn]).level = (__param_d[__local_tn]).level + 1)

    }

    return __local_tn

}

unsafe fn Intmap_insert_entry_i_(__param_self_: *mut Intmap, __param_tn: c_int, __param_rkey: *const c_int, __param__res: *mut Intmap_result) -> c_int {
    var __local_up: List[c_int] = [0; 64]

    var __local_tx: c_int = __param_tn


    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    var __local_c: c_int

    var __local_top: c_int = ((0 as c_int))

    var __local_dir: c_int = ((0 as c_int))


    while (__local_tx != 0) {
        var __ci_expr_old_0: c_int = __local_top

        (__local_top = __local_top + 1)

        (__local_up[__ci_expr_old_0] = __local_tx)


        var __local__raw: c_int = (*((&raw const (*((&raw const (__local_d[__local_tx]).value as *const Intmap_value) as *mut Intmap_value)).first as *const c_int) as *mut c_int))

        (__local_c = ((((if (*__param_rkey) < (*(&raw const __local__raw as *const c_int)): 1 else: 0) - (if (*(&raw const __local__raw as *const c_int)) < (*__param_rkey): 1 else: 0)) as c_int)))

        if ((if __local_c == 0: 1 else: 0) != 0) {
            ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Intmap_value) as *mut Intmap_value)))

            return __param_tn

        }


        (__local_dir = (((if __local_c < 0: 1 else: 0) as c_int)))

        (__local_tx = (((__local_d[__local_tx]).link[__local_dir] as c_int)))

    }

    (__local_tx = ((Intmap_new_node_(__param_self_, (1 as c_int)) as c_int)))

    if ((if __local_tx == 0: 1 else: 0) != 0) {
        return 0
    }


    (__local_d = (*__param_self_).nodes)

    ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Intmap_value) as *mut Intmap_value)))

    ((*__param__res).inserted = true)

    if ((if __local_top == 0: 1 else: 0) != 0) {
        return __local_tx
    }

    ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = __local_tx)

    while true {
        var __ci_expr_old_1: c_int = __local_top

        (__local_top = __local_top - 1)

        if (not (__ci_expr_old_1 != 0)) {
            break
        }

        if ((if __local_top != 0: 1 else: 0) != 0) {
            (__local_dir = (((if (__local_d[__local_up[(__local_top - 1)]]).link[1] == __local_up[__local_top]: 1 else: 0) as c_int)))
        }

        (__local_up[__local_top] = ((Intmap_skew_(__local_d, (__local_up[__local_top] as c_int)) as c_int)))

        (__local_up[__local_top] = ((Intmap_split_(__local_d, (__local_up[__local_top] as c_int)) as c_int)))

        if (__local_top != 0) {
            ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = ((__local_up[__local_top] as c_int)))
        }

    }

    return __local_up[0]

}

unsafe fn Intmap_erase_r_(__param_self_: *mut Intmap, __param_tn: c_int, __param_rkey: *const c_int, __param_erased: *mut c_int) -> c_int {
    var __local_tn = __param_tn
    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    if ((if __local_tn == 0: 1 else: 0) != 0) {
        return 0
    }

    var __local_raw: c_int = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)).first as *const c_int) as *mut c_int))

    var __local_tx: c_int

    var __local_c: c_int = ((((if (*__param_rkey) < (*(&raw mut __local_raw as *mut c_int)): 1 else: 0) - (if (*(&raw mut __local_raw as *mut c_int)) < (*__param_rkey): 1 else: 0)) as c_int))

    if ((if __local_c != 0: 1 else: 0) != 0) {
        ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] = ((Intmap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] as c_int), __param_rkey, __param_erased) as c_int)))
    } else {
        var __ci_expr_old_0: c_int = (*__param_erased)

        ((*__param_erased) = (*__param_erased) + 1)

        if ((if __ci_expr_old_0 == 0: 1 else: 0) != 0) {
            Intmap_value_drop((__param_self_ as *const Intmap), ((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value))
        }


        var __ci_expr_logic_1: c_int = 0

        if ((__local_d[__local_tn]).link[0] != 0) {
            (__ci_expr_logic_1 = (if (__local_d[__local_tn]).link[1] != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_tx = (((__local_d[__local_tn]).link[0] as c_int)))

            while ((__local_d[__local_tx]).link[1] != 0) {
                (__local_tx = (((__local_d[__local_tx]).link[1] as c_int)))
            }

            with_memcpy((&raw mut (__local_d[__local_tn]).value as *mut u8), (&raw const (__local_d[__local_tx]).value as *const u8), sizeof[Intmap_value]())

            (__local_raw = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)).first as *const c_int) as *mut c_int)))

            ((__local_d[__local_tn]).link[0] = ((Intmap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[0] as c_int), ((&raw mut __local_raw as *mut c_int) as *const c_int), __param_erased) as c_int)))

        } else {
            (__local_tx = __local_tn)

            (__local_tn = (((__local_d[__local_tn]).link[(if (__local_d[__local_tn]).link[0] == 0: 1 else: 0)] as c_int)))

            ((__local_d[__local_tx]).link[1] = (*__param_self_).disp)

            ((*__param_self_).disp = __local_tx)

        }


    }

    (__local_tx = (((__local_d[__local_tn]).link[1] as c_int)))

    var __ci_expr_logic_2: c_int

    if ((if (__local_d[(__local_d[__local_tn]).link[0]]).level < ((__local_d[__local_tn]).level - 1): 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (__local_d[__local_tx]).level < ((__local_d[__local_tn]).level - 1): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        ((__local_d[__local_tn]).level = (__local_d[__local_tn]).level - 1)

        if ((if (__local_d[__local_tx]).level > (__local_d[__local_tn]).level: 1 else: 0) != 0) {
            ((__local_d[__local_tx]).level = (__local_d[__local_tn]).level)
        }


        (__local_tn = ((Intmap_skew_(__local_d, __local_tn) as c_int)))

        ((__local_d[__local_tn]).link[1] = ((Intmap_skew_(__local_d, ((__local_d[__local_tn]).link[1] as c_int)) as c_int)))

        (__local_tx = (((__local_d[__local_tn]).link[1] as c_int)))


        ((__local_d[__local_tx]).link[1] = ((Intmap_skew_(__local_d, ((__local_d[__local_tx]).link[1] as c_int)) as c_int)))

        (__local_tn = ((Intmap_split_(__local_d, __local_tn) as c_int)))

        ((__local_d[__local_tn]).link[1] = ((Intmap_split_(__local_d, ((__local_d[__local_tn]).link[1] as c_int)) as c_int)))

    }


    return __local_tn

}

unsafe fn Intmap_clone_r_(__param_self_: *mut Intmap, __param_src: *mut Intmap_node, __param_sn: c_int) -> c_int {
    if ((if __param_sn == 0: 1 else: 0) != 0) {
        return 0
    }

    var __local_tx: c_int

    var __local_tn: c_int = ((Intmap_new_node_(__param_self_, ((__param_src[__param_sn]).level as c_int)) as c_int))


    let __ci_copy_31: Intmap_value = Intmap_value_clone((__param_self_ as *const Intmap), (__param_src[__param_sn]).value)
    with_memcpy((&raw mut ((*__param_self_).nodes[__local_tn]).value as *mut u8), (&raw const __ci_copy_31 as *const u8), sizeof[Intmap_value]())

    (__local_tx = ((Intmap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[0] as c_int)) as c_int)))

    (((*__param_self_).nodes[__local_tn]).link[0] = __local_tx)

    (__local_tx = ((Intmap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[1] as c_int)) as c_int)))

    (((*__param_self_).nodes[__local_tn]).link[1] = __local_tx)

    return __local_tn

}

unsafe fn Intmap_drop_r_(__param_s: *mut Intmap, __param_tn: c_int) {
    if ((if __param_tn != 0: 1 else: 0) != 0) {
        Intmap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[0] as c_int))

        Intmap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[1] as c_int))

        Intmap_value_drop((__param_s as *const Intmap), ((&raw const ((*__param_s).nodes[__param_tn]).value as *const Intmap_value) as *mut Intmap_value))

    }

}

unsafe fn Pairvec_drop(__param_cself: *const Pairvec) {
    var __local_self_: *mut Pairvec = ((__param_cself as *mut Pairvec))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    Pairvec_clear(__local_self_)

    (sizeof[Intmap_raw]() as usize)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))


}

unsafe fn Pairvec_clear(__param_self_: *mut Pairvec) {
    var __local_i: c_long = (*__param_self_).size

    while true {
        var __ci_expr_old_0: c_long = __local_i

        (__local_i = __local_i - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

    }

    ((*__param_self_).size = ((0 as c_long)))

}

unsafe fn Pairvec_reserve(__param_self_: *mut Pairvec, __param_cap: c_long) -> bool {
    var __local_n: c_long = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as c_long))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as c_int) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as c_int)) != 0) {
        var __local_d: *mut Intmap_raw = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[Intmap_raw]() as c_long)) as c_long) else: (((*__param_self_).capacity * (sizeof[Intmap_raw]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_raw))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return false
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((*__param_self_).data != null))

}

unsafe fn Pairvec_resize(__param_self_: *mut Pairvec, __param_len: c_long, __param_null_: Intmap_raw) -> bool {
    if ((if not Pairvec_reserve(__param_self_, __param_len): 1 else: 0) != 0) {
        return false
    }

    var __local_n: c_long = (*__param_self_).size

    var __local_i: c_long = __param_len

    while ((if __local_i < __local_n: 1 else: 0) != 0) {


        (__local_i = __local_i + 1)

    }


    var __local_i_1: c_long = __local_n

    while ((if __local_i_1 < __param_len: 1 else: 0) != 0) {
        (((*__param_self_).data[__local_i_1]) = __param_null_)

        (__local_i_1 = __local_i_1 + 1)

    }


    ((*__param_self_).size = __param_len)

    return true

}

unsafe fn Pairvec_erase_n(__param_self_: *mut Pairvec, __param_idx: c_long, __param_len: c_long) -> Pairvec_iter {
    if (((if not ((if (__param_idx + __param_len) <= (*__param_self_).size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Pairvec_erase_n".ptr, c"vec.h".ptr, (337 as c_int), c"idx + len <= self->size".ptr)
    } else {
        0
    }

    var __local_d: *mut Intmap_raw = ((*__param_self_).data + ((__param_idx as c_long) as usize))

    var __local_p: *mut Intmap_raw = __local_d

    var __local_end: *mut Intmap_raw = ((*__param_self_).data + (((*__param_self_).size as c_long) as usize))


    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __param_len: 1 else: 0) != 0) {


        (__local_i = __local_i + 1)

        (__local_p = __local_p + 1)


    }


    with_memmove(((__local_d as *mut c_void) as *mut u8), ((__local_p as *const c_void) as *const u8), ((((((((__local_end as usize) -% (__local_p as usize)) as c_long) / (sizeof[Intmap_raw]() as c_long)) as c_ulong) *% (sizeof[Intmap_raw]() as c_ulong)) as c_ulong) as i64))

    ((*__param_self_).size = (*__param_self_).size - __param_len)

    return ((Pairvec_iter { ref: (if __local_p == __local_end: ((null) as *mut Intmap_raw) else: __local_d), end: (__local_end - ((__param_len as c_long) as usize)) } as Pairvec_iter))

}

unsafe fn Pairvec_insert_uninit(__param_self_: *mut Pairvec, __param_idx: c_long, __param_n: c_long) -> Pairvec_iter {
    if ((if ((*__param_self_).size + __param_n) >= (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not Pairvec_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + __param_n) as c_long)): 1 else: 0) != 0) {
            return Pairvec_end((__param_self_ as *const Pairvec))
        }
    }

    var __local_pos: *mut Intmap_raw = ((*__param_self_).data + ((__param_idx as c_long) as usize))

    with_memmove((((__local_pos + ((__param_n as c_long) as usize)) as *mut c_void) as *mut u8), ((__local_pos as *const c_void) as *const u8), (((if 1 != 0: ((((*__param_self_).size - __param_idx) * (sizeof[Intmap_raw]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((Pairvec_iter { ref: __local_pos, end: ((*__param_self_).data + (((*__param_self_).size as c_long) as usize)) } as Pairvec_iter))

}

unsafe fn Pairvec_value_drop(__param_self_: *const Pairvec, __param_val: *mut Intmap_raw) {
    return
}

unsafe fn Pairvec_move(__param_self_: *mut Pairvec) -> Pairvec {
    var __local_m: Pairvec = (*__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).data = ((null as *mut Intmap_raw)))

    return __local_m

}

unsafe fn Pairvec_take(__param_self_: *mut Pairvec, __param_unowned: Pairvec) -> Unit {
    Pairvec_drop((__param_self_ as *const Pairvec))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Pairvec]())

}

unsafe fn Pairvec_push(__param_self_: *mut Pairvec, __param_value: Intmap_raw) -> *mut Intmap_raw {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not Pairvec_reserve(__param_self_, ((((*__param_self_).size * 2) + 4) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut Intmap_raw))
        }
    }

    var __local_v: *mut Intmap_raw = with 0 as __ci_expr_seq_10 {
        var __ci_expr_old_0: c_long = (*__param_self_).size
        ((*__param_self_).size = (*__param_self_).size + 1)
        ((*__param_self_).data + ((__ci_expr_old_0 as c_long) as usize))
    }

    with_memcpy((&raw mut (*__local_v) as *mut u8), (&raw const __param_value as *const u8), sizeof[Intmap_raw]())

    return __local_v

}

unsafe fn Pairvec_put_n(__param_self_: *mut Pairvec, __param_raw: *const Intmap_raw, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        Pairvec_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

unsafe fn Pairvec_copy(__param_self_: *mut Pairvec, __param_other: *const Pairvec) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Pairvec_clear(__param_self_)

    Pairvec_reserve(__param_self_, (*__param_other).size)

    ((*__param_self_).size = (*__param_other).size)

    var __local_i: c_long = ((0 as c_long))

    var __local__c_end_i: c_long = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        (((*__param_self_).data[__local_i]) = ((*__param_other).data[__local_i]))

        (__local_i = __local_i + 1)

    }


}

unsafe fn Pairvec_copy_to(__param_self_: *mut Pairvec, __param_idx: c_long, __param_arr: *mut Intmap_raw, __param_n: c_long) -> Pairvec_iter {
    var __local_arr = __param_arr
    var __local_it_: Pairvec_iter = Pairvec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const Pairvec_iter)).ref != null) {
        var __local_p: *mut Intmap_raw = (*(&raw const __local_it_ as *const Pairvec_iter)).ref

        var __local_q: *mut Intmap_raw = (__local_p + ((__param_n as c_long) as usize))


        while ((if __local_p != __local_q: 1 else: 0) != 0) {
            var __ci_expr_old_0: *mut Intmap_raw = __local_p

            (__local_p = __local_p + 1)

            with_memcpy((&raw mut (*__ci_expr_old_0) as *mut u8), (&raw const (*__local_arr) as *const u8), sizeof[Intmap_raw]())


            (__local_arr = __local_arr + 1)

        }

    }

    return __local_it_

}

fn Pairvec_clone(__param_vec: Pairvec) -> Pairvec {
    var __local_out: Pairvec = __param_vec

    var __local_self_: *mut Pairvec = ((&raw mut __local_out as *mut Pairvec))



    (__local_out.data = ((null as *mut Intmap_raw)))

    (__local_out.capacity = ((0 as c_long)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Pairvec)).capacity)


    unsafe { Pairvec_reserve((&raw mut __local_out as *mut Pairvec), (*(&raw const __param_vec as *const Pairvec)).size) }

    (__local_out.size = (unsafe *(&raw const __param_vec as *const Pairvec)).size)

    var __local_i: c_long = ((0 as c_long))

    var __local__c_end_i: c_long = (unsafe *(&raw const __param_vec as *const Pairvec)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (unsafe (*(&raw const __param_vec as *const Pairvec)).data[__local_i]))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

unsafe fn Pairvec_value_clone(__param_self_: *const Pairvec, __param_val: Intmap_raw) -> Intmap_raw {

    return __param_val

}

unsafe fn Pairvec_size(__param_self_: *const Pairvec) -> c_long {
    return (*__param_self_).size

}

unsafe fn Pairvec_capacity(__param_self_: *const Pairvec) -> c_long {
    return (*__param_self_).capacity

}

unsafe fn Pairvec_is_empty(__param_self_: *const Pairvec) -> bool {
    return ((not ((*__param_self_).size != 0)))

}

unsafe fn Pairvec_value_toraw(__param_val: *const Intmap_raw) -> Intmap_raw {
    return (*__param_val)

}

unsafe fn Pairvec_front(__param_self_: *const Pairvec) -> *const Intmap_raw {
    return (((*__param_self_).data as *const Intmap_raw))

}

unsafe fn Pairvec_front_mut(__param_self_: *mut Pairvec) -> *mut Intmap_raw {
    return (*__param_self_).data

}

unsafe fn Pairvec_back(__param_self_: *const Pairvec) -> *const Intmap_raw {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const Intmap_raw) as *mut Intmap_raw) as *const Intmap_raw))

}

unsafe fn Pairvec_back_mut(__param_self_: *mut Pairvec) -> *mut Intmap_raw {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const Intmap_raw) as *mut Intmap_raw))

}

unsafe fn Pairvec_pop(__param_self_: *mut Pairvec) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Pairvec_pop".ptr, c"vec.h".ptr, (151 as c_int), c"self->size".ptr)
    } else {
        0
    }

    var __local_p: *mut Intmap_raw = with 0 as __ci_expr_seq_8 {
        ((*__param_self_).size = (*__param_self_).size - 1)
        ((&raw const ((*__param_self_).data[(*__param_self_).size]) as *const Intmap_raw) as *mut Intmap_raw)
    }


}

unsafe fn Pairvec_pull(__param_self_: *mut Pairvec) -> Intmap_raw {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Pairvec_pull".ptr, c"vec.h".ptr, (153 as c_int), c"self->size".ptr)
    } else {
        0
    }

    ((*__param_self_).size = (*__param_self_).size - 1)

    return ((*__param_self_).data[(*__param_self_).size])


}

unsafe fn Pairvec_push_back(__param_self_: *mut Pairvec, __param_value: Intmap_raw) -> *mut Intmap_raw {
    return ((Pairvec_push(__param_self_, __param_value) as *mut Intmap_raw))

}

unsafe fn Pairvec_pop_back(__param_self_: *mut Pairvec) {
    Pairvec_pop(__param_self_)

}

fn Pairvec_init() -> Pairvec {
    return ((Pairvec.zeroed() as Pairvec))

}

fn Pairvec_with_capacity(__param_cap: c_long) -> Pairvec {
    var __local_out: Pairvec = Pairvec { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[Intmap_raw]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_raw)), size: 0, capacity: __param_cap }

    return __local_out

}

fn Pairvec_with_size_uninit(__param_size: c_long) -> Pairvec {
    var __local_out: Pairvec = Pairvec { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[Intmap_raw]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_raw)), size: __param_size, capacity: __param_size }

    return __local_out

}

fn Pairvec_with_size(__param_size: c_long, __param_default_raw: Intmap_raw) -> Pairvec {
    var __local_size = __param_size
    var __local_out: Pairvec = Pairvec { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[Intmap_raw]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut Intmap_raw)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

unsafe fn Pairvec_from_n(__param_raw: *const Intmap_raw, __param_n: c_long) -> Pairvec {
    var __local_out: Pairvec = Pairvec_with_capacity(__param_n)

    Pairvec_put_n((&raw mut __local_out as *mut Pairvec), __param_raw, __param_n)

    return __local_out

}

unsafe fn Pairvec_shrink_to_fit(__param_self_: *mut Pairvec) -> Unit {
    Pairvec_reserve(__param_self_, (9223372036854775807 as c_long))

}

unsafe fn Pairvec_insert_n(__param_self_: *mut Pairvec, __param_idx: c_long, __param_arr: *mut Intmap_raw, __param_n: c_long) -> Pairvec_iter {
    var __local_it_: Pairvec_iter = Pairvec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const Pairvec_iter)).ref != null) {
        with_memcpy((((*(&raw const __local_it_ as *const Pairvec_iter)).ref as *mut c_void) as *mut u8), ((&(__param_arr[0]) as *mut Intmap_raw) as *const u8), (((if 1 != 0: ((__param_n * (sizeof[Intmap_raw]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))
    }

    return __local_it_

}

unsafe fn Pairvec_insert_at(__param_self_: *mut Pairvec, __param_it_: Pairvec_iter, __param_value: Intmap_raw) -> Pairvec_iter {
    return Pairvec_insert_n(__param_self_, ((((((if (*(&raw const __param_it_ as *const Pairvec_iter)).ref != null: (*(&raw const __param_it_ as *const Pairvec_iter)).ref else: (*(&raw const __param_it_ as *const Pairvec_iter)).end) as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[Intmap_raw]() as c_long)) as c_long), ((&raw const __param_value as *const Intmap_raw) as *mut Intmap_raw), (1 as c_long))

}

unsafe fn Pairvec_erase_at(__param_self_: *mut Pairvec, __param_it_: Pairvec_iter) -> Pairvec_iter {
    return Pairvec_erase_n(__param_self_, ((((((*(&raw const __param_it_ as *const Pairvec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[Intmap_raw]() as c_long)) as c_long), (1 as c_long))

}

unsafe fn Pairvec_erase_range(__param_self_: *mut Pairvec, __param_i1: Pairvec_iter, __param_i2: Pairvec_iter) -> Pairvec_iter {
    var __ci_expr_ternary_1: *mut Intmap_raw = null

    var __ci_expr_logic_0: c_int = 0

    if ((*(&raw const __param_i1 as *const Pairvec_iter)).ref != null) {
        (__ci_expr_logic_0 = (if (if not ((*(&raw const __param_i2 as *const Pairvec_iter)).ref != null): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = (*(&raw const __param_i1 as *const Pairvec_iter)).end)
    } else {
        (__ci_expr_ternary_1 = (*(&raw const __param_i2 as *const Pairvec_iter)).ref)
    }

    return Pairvec_erase_n(__param_self_, ((((((*(&raw const __param_i1 as *const Pairvec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[Intmap_raw]() as c_long)) as c_long), (((((__ci_expr_ternary_1 as usize) -% ((*(&raw const __param_i1 as *const Pairvec_iter)).ref as usize)) as c_long) / (sizeof[Intmap_raw]() as c_long)) as c_long))


}

unsafe fn Pairvec_at(__param_self_: *const Pairvec, __param_idx: c_long) -> *const Intmap_raw {
    if (((if not ((if ((__param_idx as c_ulong)) < (((*__param_self_).size as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Pairvec_at".ptr, c"vec.h".ptr, (206 as c_int), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as c_long) as usize)) as *const Intmap_raw))

}

unsafe fn Pairvec_at_mut(__param_self_: *mut Pairvec, __param_idx: c_long) -> *mut Intmap_raw {
    if (((if not ((if ((__param_idx as c_ulong)) < (((*__param_self_).size as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"Pairvec_at_mut".ptr, c"vec.h".ptr, (210 as c_int), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as c_long) as usize)) as *mut Intmap_raw))

}

unsafe fn Pairvec_begin(__param_self_: *const Pairvec) -> Pairvec_iter {
    var __local_it_: Pairvec_iter = Pairvec_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.end = (*(&raw const __local_it_ as *const Pairvec_iter)).end + (((*__param_self_).size as c_long) as usize))
    } else {
        (__local_it_.ref = ((null as *mut Intmap_raw)))
    }

    return __local_it_

}

unsafe fn Pairvec_rbegin(__param_self_: *const Pairvec) -> Pairvec_iter {
    var __local_it_: Pairvec_iter = Pairvec_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const Pairvec_iter)).ref + ((((*__param_self_).size - 1) as c_long) as usize))

        (__local_it_.end = (*(&raw const __local_it_ as *const Pairvec_iter)).end - ((1 as c_long) as usize))

    } else {
        (__local_it_.ref = ((null as *mut Intmap_raw)))
    }

    return __local_it_

}

unsafe fn Pairvec_end(__param_self_: *const Pairvec) -> Pairvec_iter {

    var __local_it_: Pairvec_iter = Pairvec_iter.zeroed()

    return __local_it_

}

unsafe fn Pairvec_rend(__param_self_: *const Pairvec) -> Pairvec_iter {

    var __local_it_: Pairvec_iter = Pairvec_iter.zeroed()

    return __local_it_

}

unsafe fn Pairvec_next(__param_it_: *mut Pairvec_iter) {
    ((*__param_it_).ref = (*__param_it_).ref + 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut Intmap_raw)))
    }


}

unsafe fn Pairvec_rnext(__param_it_: *mut Pairvec_iter) {
    ((*__param_it_).ref = (*__param_it_).ref - 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut Intmap_raw)))
    }


}

fn Pairvec_advance(__param_it_: Pairvec_iter, __param_n: c_ulong) -> Pairvec_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const Pairvec_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const Pairvec_iter)).ref >= (unsafe *(&raw const __param_it_ as *const Pairvec_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut Intmap_raw)))
    }


    return __param_it_

}

unsafe fn Pairvec_index(__param_self_: *const Pairvec, __param_it_: Pairvec_iter) -> c_long {
    return (((((*(&raw const __param_it_ as *const Pairvec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[Intmap_raw]() as c_long))

}

unsafe fn Pairvec_adjust_end_(__param_self_: *mut Pairvec, __param_n: c_long) {
    ((*__param_self_).size = (*__param_self_).size + __param_n)

}

@[repr(C)]
pub type ctest_sortedmap_insert_run__c_i2_anon { _ref: *const *mut Intmap = null, ref: *mut *mut Intmap = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_sortedmap_insert_run__c_i2_anon
@[repr(C)]
pub type ctest_sortedmap_insert_run__c_i2_anon_2 { _ref: *const *mut Mymap = null, ref: *mut *mut Mymap = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_sortedmap_insert_run__c_i2_anon_2
@[repr(C)]
pub type ctest_sortedmap_insert_run__c_i2_anon_3 { _ref: *const *mut Pairvec = null, ref: *mut *mut Pairvec = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_sortedmap_insert_run__c_i2_anon_3
fn ctest_sortedmap_insert_run() {
    var __local_m1: Intmap = Intmap.zeroed()

    var __local_res: Intmap = Intmap.zeroed()

    unsafe { Intmap_insert((&raw mut __local_m1 as *mut Intmap), (1 as c_int), (10 as c_int)) }

    unsafe { Intmap_push((&raw mut __local_m1 as *mut Intmap), (Intmap_value { first: 2, second: 20 } as Intmap_value)) }

    var __ci_expr_lit_0: [Intmap_raw; 2] = [Intmap_raw { first: 1, second: 10 }, Intmap_raw { first: 2, second: 20 }]

    unsafe { Intmap_take((&raw mut __local_res as *mut Intmap), unsafe { Intmap_from_n((&__ci_expr_lit_0[0] as *mut Intmap_raw), (2 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Intmap_eq(((&raw mut __local_res as *mut Intmap) as *const Intmap), ((&raw mut __local_m1 as *mut Intmap) as *const Intmap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (97 as c_int))

    var __local_ret: Intmap_result = unsafe { Intmap_insert((&raw mut __local_m1 as *mut Intmap), (1 as c_int), (111 as c_int)) }

    assert_bool((1 as c_int), (false as bool), (unsafe *(&raw const __local_ret as *const Intmap_result)).inserted, c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (101 as c_int))

    unsafe { Intmap_insert((&raw mut __local_m1 as *mut Intmap), (3 as c_int), (30 as c_int)) }

    var __ci_expr_lit_1: [Intmap_raw; 3] = [Intmap_raw { first: 1, second: 10 }, Intmap_raw { first: 2, second: 20 }, Intmap_raw { first: 3, second: 30 }]

    unsafe { Intmap_take((&raw mut __local_res as *mut Intmap), unsafe { Intmap_from_n((&__ci_expr_lit_1[0] as *mut Intmap_raw), (3 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Intmap_eq(((&raw mut __local_res as *mut Intmap) as *const Intmap), ((&raw mut __local_m1 as *mut Intmap) as *const Intmap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (106 as c_int))

    var __local_m2: Intmap = Intmap.zeroed()

    var __local_v: Pairvec = Pairvec.zeroed()

    unsafe { Pairvec_push((&raw mut __local_v as *mut Pairvec), (Intmap_raw { first: 43, second: 294 } as Intmap_raw)) }

    unsafe { Pairvec_push((&raw mut __local_v as *mut Pairvec), (Intmap_raw { first: 41, second: 262 } as Intmap_raw)) }

    unsafe { Pairvec_push((&raw mut __local_v as *mut Pairvec), (Intmap_raw { first: 45, second: 330 } as Intmap_raw)) }

    unsafe { Pairvec_push((&raw mut __local_v as *mut Pairvec), (Intmap_raw { first: 42, second: 277 } as Intmap_raw)) }

    unsafe { Pairvec_push((&raw mut __local_v as *mut Pairvec), (Intmap_raw { first: 44, second: 311 } as Intmap_raw)) }

    unsafe { Intmap_put_n((&raw mut __local_m2 as *mut Intmap), ((*(&raw const __local_v as *const Pairvec)).data as *const Intmap_raw), (unsafe { Pairvec_size(((&raw mut __local_v as *mut Pairvec) as *const Pairvec)) } as c_long)) }

    var __ci_expr_lit_2: [Intmap_raw; 5] = [Intmap_raw { first: 41, second: 262 }, Intmap_raw { first: 42, second: 277 }, Intmap_raw { first: 43, second: 294 }, Intmap_raw { first: 44, second: 311 }, Intmap_raw { first: 45, second: 330 }]

    unsafe { Intmap_take((&raw mut __local_res as *mut Intmap), unsafe { Intmap_from_n((&__ci_expr_lit_2[0] as *mut Intmap_raw), (5 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Intmap_eq(((&raw mut __local_res as *mut Intmap) as *const Intmap), ((&raw mut __local_m2 as *mut Intmap) as *const Intmap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (122 as c_int))

    var __local_m3: Mymap = Mymap.zeroed()

    var __local_res3: Mymap = Mymap.zeroed()

    var __local_ip1: Mymap_value = Mymap_value { first: 475, second: unsafe { cstr_from_n(c"blue".ptr, ((((5 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) } }

    var __local_ip2: Mymap_value = Mymap_value { first: 510, second: unsafe { cstr_from_n(c"green".ptr, ((((6 * (sizeof[c_char]() as usize)) as c_long) - 1) as c_long)) } }


    unsafe { Mymap_insert((&raw mut __local_m3 as *mut Mymap), (*(&raw const __local_ip1 as *const Mymap_value)).first, unsafe { cstr_move(((&raw const (*(&raw const __local_ip1 as *const Mymap_value)).second as *const cstr) as *mut cstr)) }) }

    var __ci_expr_lit_3: [Mymap_raw; 1] = [Mymap_raw { first: 475, second: (("blue" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res3 as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_3[0] as *mut Mymap_raw), (1 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res3 as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (134 as c_int))

    unsafe { Mymap_insert((&raw mut __local_m3 as *mut Mymap), (*(&raw const __local_ip2 as *const Mymap_value)).first, unsafe { cstr_move(((&raw const (*(&raw const __local_ip2 as *const Mymap_value)).second as *const cstr) as *mut cstr)) }) }

    var __ci_expr_lit_4: [Mymap_raw; 2] = [Mymap_raw { first: 475, second: (("blue" as *mut c_char) as *const i8) }, Mymap_raw { first: 510, second: (("green" as *mut c_char) as *const i8) }]

    unsafe { Mymap_take((&raw mut __local_res3 as *mut Mymap), unsafe { Mymap_from_n((&__ci_expr_lit_4[0] as *mut Mymap_raw), (2 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res3 as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-smap_test/smap_test.c".ptr, (140 as c_int))

    loop {
        var __local__c_i2: ctest_sortedmap_insert_run__c_i2_anon = ctest_sortedmap_insert_run__c_i2_anon.zeroed()

        var __ci_expr_lit_5: [*mut Intmap; 3] = [(&raw mut __local_m1 as *mut Intmap), (&raw mut __local_m2 as *mut Intmap), (&raw mut __local_res as *mut Intmap)]

        __local__c_i2 = ctest_sortedmap_insert_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_5)[0] as *mut *mut Intmap) as *const *mut Intmap)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon))._ref as *mut *mut Intmap)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[Intmap]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { Intmap_drop(((*((*(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).ref)) as *const Intmap)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__c_i2_1: ctest_sortedmap_insert_run__c_i2_anon_2 = ctest_sortedmap_insert_run__c_i2_anon_2.zeroed()

        var __ci_expr_lit_6: [*mut Mymap; 2] = [(&raw mut __local_m3 as *mut Mymap), (&raw mut __local_res3 as *mut Mymap)]

        __local__c_i2_1 = ctest_sortedmap_insert_run__c_i2_anon_2.zeroed()
        __local__c_i2_1._ref = ((&raw const (__ci_expr_lit_6)[0] as *mut *mut Mymap) as *const *mut Mymap)
        __local__c_i2_1.ref = ((unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2))._ref as *mut *mut Mymap)
        __local__c_i2_1.size = (((((2 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[Mymap]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).index < (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).size: 1 else: 0) != 0) {
            unsafe { Mymap_drop(((*((*(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).ref)) as *const Mymap)) }

            (__local__c_i2_1.ref = (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).ref + 1)

            (__local__c_i2_1.index = (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__c_i2_2: ctest_sortedmap_insert_run__c_i2_anon_3 = ctest_sortedmap_insert_run__c_i2_anon_3.zeroed()

        var __ci_expr_lit_7: [*mut Pairvec; 1] = [(&raw mut __local_v as *mut Pairvec)]

        __local__c_i2_2 = ctest_sortedmap_insert_run__c_i2_anon_3.zeroed()
        __local__c_i2_2._ref = ((&raw const (__ci_expr_lit_7)[0] as *mut *mut Pairvec) as *const *mut Pairvec)
        __local__c_i2_2.ref = ((unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3))._ref as *mut *mut Pairvec)
        __local__c_i2_2.size = (((((1 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[Pairvec]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).index < (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).size: 1 else: 0) != 0) {
            unsafe { Pairvec_drop(((*((*(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).ref)) as *const Pairvec)) }

            (__local__c_i2_2.ref = (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).ref + 1)

            (__local__c_i2_2.index = (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

var ctest_sortedmap_erase: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("sortedmap" as *mut c_char) as *const c_char), ttname: (("erase" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_sortedmap_erase_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_sortedmap_insert: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("sortedmap" as *mut c_char) as *const c_char), ttname: (("insert" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_sortedmap_insert_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_sortedmap_erase_run()
    print("ran sortedmap.erase")
    ctest_sortedmap_insert_run()
    print("ran sortedmap.insert")
    return ctest_failure_count()
