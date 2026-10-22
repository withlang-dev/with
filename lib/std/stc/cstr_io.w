// Migrated from C
use std.stc.defs
use std.stc.utf8_misc
use std.stc.cstr_utf8
use std.stc.ucd
use std.stc.cstr_core
use std.stc.cstr_misc
use std.libc

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

pub unsafe fn cstr_from_fmt(__param_fmt: *const i8, ...) -> cstr {
    var __local_s: cstr = ((cstr.zeroed() as cstr))


    var __local_args: c_va_list = va_start()

    cstr_vfmt((&raw mut __local_s as *mut cstr), (0 as c_long), __param_fmt, __local_args)


    return __local_s

}

pub unsafe fn cstr_from_file(__param_fname: *const i8) -> cstr {
    var __local_s: cstr = cstr.zeroed()

    var __local_fp: *mut c_void = fopen(__param_fname, c"rb".ptr)

    if (__local_fp != null) {
        fseek(__local_fp, (0 as c_long), (libc.SEEK_END as c_int))

        var __local_n: c_long = ((0 as c_long))

        var __local_sz: c_long = ((ftell(__local_fp) as c_long))


        var __local_buf: *mut c_char = ((cstr_append_uninit((&raw mut __local_s as *mut cstr), __local_sz) as *mut c_char))

        if (__local_buf != null) {
            rewind(__local_fp)

            (__local_n = ((fread((__local_buf as *mut c_void), (1 as c_ulong), (__local_sz as c_ulong), __local_fp) as c_long)))

        }

        if (((if not ((if __local_n == __local_sz: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"cstr_from_file".ptr, c"cstr_prv.c".ptr, (199 as c_int), c"n == sz".ptr)
        } else {
            0
        }

        fclose(__local_fp)

    }

    return __local_s

}

pub unsafe fn cstr_append_fmt(__param_self_: *mut cstr, __param_fmt: *const i8, ...) -> c_long {

    var __local_args: c_va_list = va_start()

    var __local_n: c_long = ((cstr_vfmt(__param_self_, (cstr_size((__param_self_ as *const cstr)) as c_long), __param_fmt, __local_args) as c_long))


    return __local_n

}

pub unsafe fn cstr_append_uninit(__param_self_: *mut cstr, __param_len: c_long) -> *mut i8 {
    var __local_b: cstr_buf = cstr_getbuf(__param_self_)

    var __ci_expr_logic_0: c_int = 0

    if ((if ((*(&raw const __local_b as *const cstr_buf)).size + __param_len) > (*(&raw const __local_b as *const cstr_buf)).cap: 1 else: 0) != 0) {
        (__local_b.data = ((cstr_reserve(__param_self_, (((((*(&raw const __local_b as *const cstr_buf)).size * 3) / 2) + __param_len) as c_long)) as *mut c_char)))

        (__ci_expr_logic_0 = (if (if (*(&raw const __local_b as *const cstr_buf)).data == null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((null as *mut i8))
    }


    _cstr_set_size(__param_self_, (((*(&raw const __local_b as *const cstr_buf)).size + __param_len) as c_long))

    return ((((*(&raw const __local_b as *const cstr_buf)).data + (((*(&raw const __local_b as *const cstr_buf)).size as c_long) as usize)) as *mut i8))

}

pub unsafe fn cstr_getdelim(__param_self_: *mut cstr, __param_delim: c_int, __param_fp: *mut c_void) -> bool {
    var __local_c: c_int = ((fgetc(__param_fp) as c_int))

    if ((if __local_c == -1: 1 else: 0) != 0) {
        return false
    }

    var __local_pos: c_long = ((0 as c_long))

    var __local_b: cstr_buf = cstr_getbuf(__param_self_)

    while true {
        var __ci_expr_logic_0: c_int

        if ((if __local_c == __param_delim: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_c == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            _cstr_set_size(__param_self_, __local_pos)

            return true

        }


        if ((if __local_pos == (*(&raw const __local_b as *const cstr_buf)).cap: 1 else: 0) != 0) {
            _cstr_set_size(__param_self_, __local_pos)

            var __local_data: *mut c_char = with 0 as __ci_expr_seq_21 {
                (__local_b.cap = ((((((*(&raw const __local_b as *const cstr_buf)).cap * 3) / 2) + 16) as c_long)))
                (cstr_reserve(__param_self_, (*(&raw const __local_b as *const cstr_buf)).cap) as *mut c_char)
            }

            (__local_b.data = ((__local_data as *mut c_char)))

        }

        var __ci_expr_old_1: c_long = __local_pos

        (__local_pos = __local_pos + 1)

        ((__local_b.data[__ci_expr_old_1]) = ((__local_c as c_char)))


        (__local_c = ((fgetc(__param_fp) as c_int)))

    }

}

pub unsafe fn cstr_printf(__param_self_: *mut cstr, __param_fmt: *const i8, ...) -> c_long {

    var __local_args: c_va_list = va_start()

    var __local_n: c_long = ((cstr_vfmt(__param_self_, (0 as c_long), __param_fmt, __local_args) as c_long))


    return __local_n

}

pub unsafe fn cstr_vfmt(__param_self_: *mut cstr, __param_start: c_long, __param_fmt: *const i8, __param_args: c_va_list) -> c_long {

    var __local_args2: c_va_list = __param_args

    var __local_n: c_int = ((vsnprintf((null as *mut i8), (0 as c_ulong), __param_fmt, __param_args) as c_int))

    vsnprintf((cstr_reserve(__param_self_, ((__param_start + __local_n) as c_long)) + ((__param_start as c_long) as usize)), (((__local_n as c_ulong) +% (1 as c_ulong)) as c_ulong), __param_fmt, __local_args2)


    _cstr_set_size(__param_self_, ((__param_start + __local_n) as c_long))

    return ((__local_n as c_long))

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
