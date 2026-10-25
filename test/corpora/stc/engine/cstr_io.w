// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.utf8_misc
use std.engines.stc_testing.cstr_utf8
use std.engines.stc_testing.ucd
use std.engines.stc_testing.cstr_core
use std.engines.stc_testing.cstr_misc
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

// contract: stored-unknown:0,variadic — stores an argument; ownership not modeled
pub unsafe fn cstr_from_fmt(__param_fmt: *const c_char, ...) -> cstr {
    var __local_s: cstr = ((cstr.zeroed() as cstr))


    var __local_args: c_va_list = va_start()

    cstr_vfmt((&raw mut __local_s as *mut cstr), (0 as i64), __param_fmt, __local_args)


    return __local_s

}

// contract: unproved:0:read only
pub unsafe fn cstr_from_file(__param_fname: *const c_char) -> cstr {
    var __local_s: cstr = cstr.zeroed()

    var __local_fp: *mut c_void = fopen(__param_fname, c"rb".ptr)

    if (__local_fp != null) {
        fseek(__local_fp, (0 as i64), (libc.SEEK_END as i32))

        var __local_n: i64 = ((0 as i64))

        var __local_sz: i64 = ((ftell(__local_fp) as i64))


        var __local_buf: *mut c_char = (*(&raw mut __local_s as *mut cstr)).append_uninit(__local_sz)

        if (__local_buf != null) {
            rewind(__local_fp)

            (__local_n = ((fread((__local_buf as *mut c_void), (1 as u64), (__local_sz as u64), __local_fp) as i64)))

        }

        if (((if not ((if __local_n == __local_sz: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"cstr_from_file".ptr, c"cstr_prv.c".ptr, (199 as i32), c"n == sz".ptr)
        } else {
            0
        }

        fclose(__local_fp)

    }

    return __local_s

}

// contract: receiver-mut:cstr,stored-unknown:1,variadic — stores an argument; ownership not modeled
pub unsafe fn cstr_append_fmt(__param_self_: *mut cstr, __param_fmt: *const c_char, ...) -> i64 {

    var __local_args: c_va_list = va_start()

    var __local_n: i64 = ((cstr_vfmt(__param_self_, (cstr_size((__param_self_ as *const cstr)) as i64), __param_fmt, __local_args) as i64))


    return __local_n

}

// contract: receiver-mut:cstr,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn cstr_getdelim(__param_self_: *mut cstr, __param_delim: i32, __param_fp: *mut c_void) -> bool {
    var __local_c: i32 = ((fgetc(__param_fp) as i32))

    if ((if __local_c == -1: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_pos: i64 = ((0 as i64))

    var __local_b: cstr_buf = cstr_getbuf(__param_self_)

    while true {
        var __ci_expr_logic_0: i32

        if ((if __local_c == __param_delim: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __local_c == -1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            _cstr_set_size(__param_self_, __local_pos)

            return ((true as bool))

        }


        if ((if __local_pos == (*(&raw const __local_b as *const cstr_buf)).cap: 1 else: 0) != 0) {
            _cstr_set_size(__param_self_, __local_pos)

            var __local_data: *mut c_char = with 0 as __ci_expr_seq_21 {
                (__local_b.cap = ((((((*(&raw const __local_b as *const cstr_buf)).cap * 3) / 2) + 16) as i64)))
                (*__param_self_).reserve((*(&raw const __local_b as *const cstr_buf)).cap)
            }

            (__local_b.data = __local_data)

        }

        var __ci_expr_old_1: i64 = __local_pos

        (__local_pos = __local_pos + 1)

        ((__local_b.data[__ci_expr_old_1]) = ((__local_c as c_char)))


        (__local_c = ((fgetc(__param_fp) as i32)))

    }

}

// contract: receiver-mut:cstr,stored-unknown:1,variadic — stores an argument; ownership not modeled
pub unsafe fn cstr_printf(__param_self_: *mut cstr, __param_fmt: *const c_char, ...) -> i64 {

    var __local_args: c_va_list = va_start()

    var __local_n: i64 = ((cstr_vfmt(__param_self_, (0 as i64), __param_fmt, __local_args) as i64))


    return __local_n

}

// contract: receiver-mut:cstr,unproved:2:read only
pub unsafe fn cstr_vfmt(__param_self_: *mut cstr, __param_start: i64, __param_fmt: *const c_char, __param_args: c_va_list) -> i64 {

    var __local_args2: c_va_list = __param_args

    var __local_n: i32 = ((vsnprintf((null as *mut c_char), (0 as u64), __param_fmt, __param_args) as i32))

    vsnprintf(((*__param_self_).reserve(((__param_start + __local_n) as i64)) + ((__param_start as i64) as usize)), (((__local_n as u64) +% (1 as u64)) as u64), __param_fmt, __local_args2)


    _cstr_set_size(__param_self_, ((__param_start + __local_n) as i64))

    return ((__local_n as i64))

}

unsafe fn cstr_getbuf(__param_s: *mut cstr) -> cstr_buf {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (cstr_buf { data: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64), cap: (((~(*(&raw const (*__param_s).lon as *const cstr_lon)).ncap)) as i64) } as cstr_buf) else: (cstr_buf { data: (&raw const (*__param_s).sml.data[0] as *mut c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)), cap: 22 } as cstr_buf))

}

unsafe fn cstr_zv(__param_s: *const cstr) -> zsview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (zsview { str: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64) } as zsview) else: (zsview { str: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)) } as zsview))

}

unsafe fn cstr_sv(__param_s: *const cstr) -> csview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (csview { buf: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64) } as csview) else: (csview { buf: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)) } as csview))

}

// contract: unproved:0:read only
unsafe fn cstr_from_n(__param_str: *const c_char, __param_len: i64) -> cstr {
    var __local_s: cstr

    with_memcpy((((*(&raw mut __local_s as *mut cstr))._cstr_init(__param_len, __param_len) as *mut c_void) as *mut u8), ((__param_str as *const c_void) as *const u8), (((if 1 != 0: __param_len else: (-1 as i64)) as u64) as i64))

    return __local_s

}

// contract: unproved:0:read only
unsafe fn cstr_from(__param_str: *const c_char) -> cstr {
    return cstr_from_n(__param_str, (strlen(__param_str) as i64))

}

fn cstr_from_sv(__param_sv: csview) -> cstr {
    return unsafe { cstr_from_n(((*(&raw const __param_sv as *const csview)).buf as *const c_char), (*(&raw const __param_sv as *const csview)).size) }

}

fn cstr_from_zv(__param_zv: zsview) -> cstr {
    return unsafe { cstr_from_n(((*(&raw const __param_zv as *const zsview)).str as *const c_char), (*(&raw const __param_zv as *const zsview)).size) }

}

fn cstr_with_size(__param_size: i64, __param_value: c_char) -> cstr {
    var __local_s: cstr

    with_memset(((unsafe { (*(&raw mut __local_s as *mut cstr))._cstr_init(__param_size, __param_size) } as *mut c_void) as *mut u8), (__param_value as i32), (((if 1 != 0: __param_size else: (-1 as i64)) as u64) as i64))

    return __local_s

}

fn cstr_with_capacity(__param_cap: i64) -> cstr {
    var __local_s: cstr

    unsafe { (*(&raw mut __local_s as *mut cstr))._cstr_init((0 as i64), __param_cap) }

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

    return unsafe { cstr_from_n(((*(&raw const __local_sv as *const csview)).buf as *const c_char), (*(&raw const __local_sv as *const csview)).size) }

}

unsafe fn _cstr_set_size(__param_self_: *mut cstr, __param_len: i64) -> Unit {
    if ((if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0) {
        ((*__param_self_).lon.size = ((__param_len as u64)))

        (((*__param_self_).lon.data[(*(&raw const (*__param_self_).lon as *const cstr_lon)).size]) = ((0 as c_char)))

    } else {
        ((*__param_self_).sml.size = ((__param_len as u8)))

        ((*__param_self_).sml.data[(*(&raw const (*__param_self_).sml as *const cstr_sml)).size] = ((0 as c_char)))

    }

}

unsafe fn cstr_clear(__param_self_: *mut cstr) {
    _cstr_set_size(__param_self_, (0 as i64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn cstr_data(__param_self_: *mut cstr) -> *mut c_char {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (*(&raw const (*__param_self_).lon as *const cstr_lon)).data else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *mut c_char)) as *mut c_char))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn cstr_str(__param_self_: *const cstr) -> *const c_char {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const c_char))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn cstr_toraw(__param_self_: *const cstr) -> *const c_char {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const c_char))

}

unsafe fn cstr_size(__param_self_: *const cstr) -> i64 {
    return (if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).size as i64) else: ((*(&raw const (*__param_self_).sml as *const cstr_sml)).size as i64))

}

unsafe fn cstr_is_empty(__param_self_: *const cstr) -> bool {
    return ((((cstr_size(__param_self_) == 0)) as bool))

}

unsafe fn cstr_capacity(__param_self_: *const cstr) -> i64 {
    return (if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((~(*(&raw const (*__param_self_).lon as *const cstr_lon)).ncap) as i64) else: (22 as i64))

}

unsafe fn cstr_to_index(__param_self_: *const cstr, __param_it_: cstr_iter) -> i64 {
    return (((((*(&raw const __param_it_ as *const cstr_iter)).ref as usize) -% (cstr_str(__param_self_) as usize)) as i64) / (sizeof[c_char]() as i64))

}

fn cstr_from_s(__param_s: cstr, __param_pos: i64, __param_len: i64) -> cstr {
    return unsafe { cstr_from_n((unsafe { cstr_str(((&raw mut __param_s as *mut cstr) as *const cstr)) } + ((__param_pos as i64) as usize)), __param_len) }

}

unsafe fn cstr_subview(__param_self_: *const cstr, __param_pos: i64, __param_len: i64) -> csview {
    var __local_len = __param_len
    var __local_sv: csview = cstr_sv(__param_self_)

    if (((if not ((((if ((__param_pos as u64)) <= (((*(&raw const __local_sv as *const csview)).size as u64)): 1 else: 0) as i32) & ((if __local_len >= 0: 1 else: 0) as i32)) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cstr_subview".ptr, c"cstr_prv.h".ptr, (174 as i32), c"((size_t)pos <= (size_t)sv.size) & (len >= 0)".ptr)
    } else {
        0
    }

    if ((if (__param_pos + __local_len) > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_len = ((((*(&raw const __local_sv as *const csview)).size - __param_pos) as i64)))
    }

    return ((csview { buf: ((*(&raw const __local_sv as *const csview)).buf + ((__param_pos as i64) as usize)), size: __local_len } as csview))

}

unsafe fn cstr_tail(__param_self_: *const cstr, __param_len: i64) -> zsview {
    var __local_len = __param_len
    if (((if not ((if __local_len >= 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cstr_tail".ptr, c"cstr_prv.h".ptr, (180 as i32), c"len >= 0".ptr)
    } else {
        0
    }

    var __local_sv: csview = cstr_sv(__param_self_)

    if ((if __local_len > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_len = (*(&raw const __local_sv as *const csview)).size)
    }

    return ((zsview { str: ((&raw const (__local_sv.buf[((*(&raw const __local_sv as *const csview)).size - __local_len)]) as *const c_char) as *mut c_char), size: __local_len } as zsview))

}

// contract: unproved:0:read only
unsafe fn cstr_u8_from(__param_str: *const c_char, __param_u8pos: i64, __param_u8len: i64) -> cstr {
    var __local_str = __param_str
    (__local_str = cutf8_at(__local_str, __param_u8pos))

    return cstr_from_n(__local_str, (cutf8_to_index(__local_str, __param_u8len) as i64))

}

unsafe fn cstr_u8_size(__param_self_: *const cstr) -> i64 {
    return cutf8_count(cstr_str(__param_self_))

}

unsafe fn cstr_u8_to_index(__param_self_: *const cstr, __param_u8pos: i64) -> i64 {
    return cutf8_to_index(cstr_str(__param_self_), __param_u8pos)

}

unsafe fn cstr_u8_tail(__param_self_: *const cstr, __param_u8len: i64) -> zsview {
    var __local_u8len = __param_u8len
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_p: *const c_char = ((((&raw const (__local_sv.buf[(*(&raw const __local_sv as *const csview)).size]) as *const c_char) as *mut c_char) as *const c_char))

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_u8len != 0) {
            (__ci_expr_logic_0 = (if (if __local_p != (*(&raw const __local_sv as *const csview)).buf: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_p = __local_p - 1)

        (__local_u8len = __local_u8len - (if (((*__local_p) as i32) & (192 as i32)) != 128: 1 else: 0))

    }

    return ((zsview { str: __local_p, size: ((*(&raw const __local_sv as *const csview)).size - (((((__local_p as usize) -% ((*(&raw const __local_sv as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)))) } as zsview))

}

unsafe fn cstr_u8_subview(__param_self_: *const cstr, __param_u8pos: i64, __param_u8len: i64) -> csview {
    return cutf8_subview(cstr_str(__param_self_), __param_u8pos, __param_u8len)

}

unsafe fn cstr_u8_at(__param_self_: *const cstr, __param_u8pos: i64) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8: cstr_iter_u8 { chr: csview { buf: cutf8_at(cstr_str(__param_self_), __param_u8pos) }, dec: cutf8_decode_t.zeroed() } }

    (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const c_char)) as i64)))

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
        (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const c_char)) as i64)))
    }

    return __local_it_

}

unsafe fn cstr_end(__param_self_: *const cstr) -> cstr_iter {

    var __local_it_: cstr_iter = cstr_iter.zeroed()

    return __local_it_

}

unsafe fn cstr_next(__param_it_: *mut cstr_iter) -> Unit {
    ((*__param_it_).ref = (*__param_it_).ref + (((*(&raw const (*__param_it_).chr as *const csview)).size as i64) as usize))

    if ((if (*((*__param_it_).ref)) == 0: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *const c_char)))
    } else {
        ((*__param_it_).chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*__param_it_).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*__param_it_).ref, (null as *const c_char)) as i64)))
    }

}

fn cstr_advance(__param_it_: cstr_iter, __param_u8pos: i64) -> cstr_iter {
    (__param_it_.ref = unsafe { cutf8_offset((*(&raw const __param_it_ as *const cstr_iter)).ref, __param_u8pos) })

    if ((if (unsafe *((*(&raw const __param_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *const c_char)))
    } else {
        (__param_it_.chr.size = ((unsafe { cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __param_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __param_it_ as *const cstr_iter)).ref, (null as *const c_char)) } as i64)))
    }

    return __param_it_

}

unsafe fn cstr_codepoint(__param_it_: *const cstr_iter) -> u32 {
    return (*(&raw const (*__param_it_).u8.dec as *const cutf8_decode_t)).codep

}

fn cstr_casefold_sv(__param_sv: csview) -> cstr {
    return cstr_tocase_sv(__param_sv, (0 as i32))

}

fn cstr_tolower_sv(__param_sv: csview) -> cstr {
    return cstr_tocase_sv(__param_sv, (1 as i32))

}

fn cstr_toupper_sv(__param_sv: csview) -> cstr {
    return cstr_tocase_sv(__param_sv, (2 as i32))

}

// contract: unproved:0:read only
unsafe fn cstr_tolower(__param_str: *const c_char) -> cstr {
    return cstr_tolower_sv((csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

// contract: unproved:0:read only
unsafe fn cstr_toupper(__param_str: *const c_char) -> cstr {
    return cstr_toupper_sv((csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

unsafe fn cstr_lowercase(__param_self_: *mut cstr) -> Unit {
    (((*__param_self_).take(cstr_tolower_sv(cstr_sv((__param_self_ as *const cstr)))) as *const cstr) as *mut cstr)

}

unsafe fn cstr_uppercase(__param_self_: *mut cstr) -> Unit {
    (((*__param_self_).take(cstr_toupper_sv(cstr_sv((__param_self_ as *const cstr)))) as *const cstr) as *mut cstr)

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_istarts_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_len: i64 = ((strlen(__param_sub) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_len <= (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__local_sv.size = __local_len)

        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__local_sv, (csview { buf: __param_sub, size: __local_len } as csview)) != 0): 1 else: 0) != 0: 1 else: 0))

    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_iends_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_len: i64 = ((strlen(__param_sub) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_len <= (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp(((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) - ((__local_len as i64) as usize)) as *const c_char), __param_sub) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_icmp(__param_s1: *const cstr, __param_s2: *const cstr) -> i32 {
    return cutf8_icmp(cstr_str(__param_s1), cstr_str(__param_s2))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_ieq(__param_s1: *const cstr, __param_s2: *const cstr) -> bool {
    var __local_x: csview = cstr_sv(__param_s1)

    var __local_y: csview = cstr_sv(__param_s2)


    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__local_x, __local_y) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_iequals(__param_self_: *const cstr, __param_str: *const c_char) -> bool {
    return ((((not (cutf8_icmp(cstr_str(__param_self_), __param_str) != 0))) as bool))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_cmp(__param_s1: *const cstr, __param_s2: *const cstr) -> i32 {
    return strcmp(cstr_str(__param_s1), cstr_str(__param_s2))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_eq(__param_s1: *const cstr, __param_s2: *const cstr) -> bool {
    var __local_x: csview = cstr_sv(__param_s1)

    var __local_y: csview = cstr_sv(__param_s2)


    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((*(&raw const __local_x as *const csview)).buf as *const c_void) as *const u8), (((*(&raw const __local_y as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __local_x as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_equals(__param_self_: *const cstr, __param_str: *const c_char) -> bool {
    return ((((not (strcmp(cstr_str(__param_self_), __param_str) != 0))) as bool))

}

unsafe fn cstr_equals_sv(__param_self_: *const cstr, __param_sv: csview) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __param_sv as *const csview)).size == cstr_size(__param_self_): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sv as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sv as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_find(__param_self_: *const cstr, __param_search: *const c_char) -> i64 {
    var __local_str: *const c_char = cstr_str(__param_self_)

    var __local_res: *const c_char = ((strstr(((__local_str as *mut c_char) as *const c_char), __param_search) as *const c_char))


    return (if __local_res != null: (((((__local_res as usize) -% (__local_str as usize)) as i64) / (sizeof[c_char]() as i64)) as i64) else: (9223372036854775807 as i64))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_contains(__param_self_: *const cstr, __param_search: *const c_char) -> bool {
    return ((((strstr(((cstr_str(__param_self_) as *mut c_char) as *const c_char), __param_search) != null)) as bool))

}

unsafe fn cstr_contains_sv(__param_self_: *const cstr, __param_search: csview) -> bool {
    return (((((*__param_self_).find_sv(__param_search) != 9223372036854775807)) as bool))

}

unsafe fn cstr_starts_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    if ((if (*(&raw const __param_sub as *const csview)).size > cstr_size(__param_self_): 1 else: 0) != 0) {
        return ((false as bool))
    }

    return ((((not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sub as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0))) as bool))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_starts_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    var __local_sub = __param_sub
    var __local_str: *const c_char = cstr_str(__param_self_)

    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((*__local_sub) != 0) {
            (__ci_expr_logic_0 = (if (if (*__local_str) == (*__local_sub): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_str = __local_str + 1)

        (__local_sub = __local_sub + 1)

    }

    return ((((not ((*__local_sub) != 0))) as bool))

}

unsafe fn cstr_ends_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    if ((if (*(&raw const __param_sub as *const csview)).size > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        return ((false as bool))
    }

    return ((((not (with_memcmp((((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) - (((*(&raw const __param_sub as *const csview)).size as i64) as usize)) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sub as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0))) as bool))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_ends_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    return cstr_ends_with_sv(__param_self_, (csview { buf: __param_sub, size: (strlen(__param_sub) as i64) } as csview))

}

// contract: receiver-mut:cstr,unproved:1:read only
unsafe fn cstr_assign(__param_self_: *mut cstr, __param_str: *const c_char) -> *mut c_char {
    return ((cstr_assign_n(__param_self_, __param_str, (strlen(__param_str) as i64)) as *mut c_char))

}

unsafe fn cstr_assign_sv(__param_self_: *mut cstr, __param_sv: csview) -> *mut c_char {
    return ((cstr_assign_n(__param_self_, ((*(&raw const __param_sv as *const csview)).buf as *const c_char), (*(&raw const __param_sv as *const csview)).size) as *mut c_char))

}

unsafe fn cstr_copy(__param_self_: *mut cstr, __param_s: cstr) -> *mut c_char {
    var __local_sv: csview = cstr_sv(((&raw mut __param_s as *mut cstr) as *const cstr))

    return ((cstr_assign_n(__param_self_, ((*(&raw const __local_sv as *const csview)).buf as *const c_char), (*(&raw const __local_sv as *const csview)).size) as *mut c_char))

}

// contract: receiver-mut:cstr,unproved:1:read only
unsafe fn cstr_push(__param_self_: *mut cstr, __param_chr: *const c_char) -> *mut c_char {
    return ((cstr_append_n(__param_self_, __param_chr, (cutf8_chr_size(__param_chr) as i64)) as *mut c_char))

}

unsafe fn cstr_pop(__param_self_: *mut cstr) {
    var __local_sv: csview = cstr_sv((__param_self_ as *const cstr))

    var __local_s: *const c_char = ((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) as *const c_char))

    while true {
        (__local_s = __local_s - 1)

        if (not ((if (((*__local_s) as i32) & (192 as i32)) == 128: 1 else: 0) != 0)) {
            break
        }

    }

    _cstr_set_size(__param_self_, (((((__local_s as usize) -% ((*(&raw const __local_sv as *const csview)).buf as usize)) as i64) / (sizeof[c_char]() as i64)) as i64))

}

// contract: receiver-mut:cstr,unproved:1:read only
unsafe fn cstr_append(__param_self_: *mut cstr, __param_str: *const c_char) -> *mut c_char {
    return ((cstr_append_n(__param_self_, __param_str, (strlen(__param_str) as i64)) as *mut c_char))

}

unsafe fn cstr_append_sv(__param_self_: *mut cstr, __param_sv: csview) -> *mut c_char {
    return ((cstr_append_n(__param_self_, ((*(&raw const __param_sv as *const csview)).buf as *const c_char), (*(&raw const __param_sv as *const csview)).size) as *mut c_char))

}

unsafe fn cstr_append_s(__param_self_: *mut cstr, __param_s: cstr) -> *mut c_char {
    return ((cstr_append_sv(__param_self_, cstr_sv(((&raw mut __param_s as *mut cstr) as *const cstr))) as *mut c_char))

}

// contract: receiver-mut:cstr,stored-unknown:1,unproved:2:read only — stores an argument; ownership not modeled
unsafe fn cstr_join_array(__param_self_: *mut cstr, __param_sep: *const c_char, __param_arr: *mut *const c_char, __param_n: i64) {
    var __local_arr = __param_arr
    var __local_n = __param_n
    var __local__sep: *const c_char = (if cstr_is_empty((__param_self_ as *const cstr)) != 0: c"".ptr else: __param_sep)

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        cstr_append(__param_self_, __local__sep)

        var __ci_expr_old_1: *mut *const c_char = __local_arr

        (__local_arr = __local_arr + 1)

        cstr_append(__param_self_, (*(&(__ci_expr_old_1[0]) as *mut *const c_char)))

        (__local__sep = __param_sep)

    }

}

// contract: receiver-mut:cstr,stored-unknown:1,unproved:2:read only — stores an argument; ownership not modeled
unsafe fn cstr_join_array_s(__param_self_: *mut cstr, __param_sep: *const c_char, __param_arr: *mut cstr, __param_n: i64) {
    var __local_arr = __param_arr
    var __local_n = __param_n
    var __local__sep: *const c_char = (if cstr_is_empty((__param_self_ as *const cstr)) != 0: c"".ptr else: __param_sep)

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        cstr_append(__param_self_, __local__sep)

        var __ci_expr_old_1: *mut cstr = __local_arr

        (__local_arr = __local_arr + 1)

        cstr_append_s(__param_self_, (*(&(__ci_expr_old_1[0]) as *mut cstr)))

        (__local__sep = __param_sep)

    }

}

unsafe fn cstr_replace_sv(__param_self_: *mut cstr, __param_search: csview, __param_repl: csview, __param_count: i32) -> Unit {
    (((*__param_self_).take(cstr_from_replace(cstr_sv((__param_self_ as *const cstr)), __param_search, __param_repl, __param_count)) as *const cstr) as *mut cstr)

}

// contract: receiver-mut:cstr,unproved:1:read only,unproved:2:read only
unsafe fn cstr_replace_nfirst(__param_self_: *mut cstr, __param_search: *const c_char, __param_repl: *const c_char, __param_count: i32) {
    cstr_replace_sv(__param_self_, (csview { buf: __param_search, size: (strlen(__param_search) as i64) } as csview), (csview { buf: __param_repl, size: (strlen(__param_repl) as i64) } as csview), __param_count)

}

// contract: receiver-mut:cstr,unproved:1:read only,unproved:2:read only
unsafe fn cstr_replace(__param_self_: *mut cstr, __param_search: *const c_char, __param_repl: *const c_char) {
    cstr_replace_nfirst(__param_self_, __param_search, __param_repl, (2147483647 as i32))

}

unsafe fn cstr_replace_at_sv(__param_self_: *mut cstr, __param_pos: i64, __param_len: i64, __param_repl: csview) -> Unit {
    var __local_d: *mut c_char = (*__param_self_)._cstr_internal_move(((__param_pos + __param_len) as i64), ((__param_pos + (*(&raw const __param_repl as *const csview)).size) as i64))

    with_memcpy((((__local_d + ((__param_pos as i64) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __param_repl as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_repl as *const csview)).size else: (-1 as i64)) as u64) as i64))

}

// contract: receiver-mut:cstr,unproved:3:read only
unsafe fn cstr_replace_at(__param_self_: *mut cstr, __param_pos: i64, __param_len: i64, __param_repl: *const c_char) {
    cstr_replace_at_sv(__param_self_, __param_pos, __param_len, (csview { buf: __param_repl, size: (strlen(__param_repl) as i64) } as csview))

}

// contract: receiver-mut:cstr,unproved:3:read only
unsafe fn cstr_u8_replace(__param_self_: *mut cstr, __param_u8pos: i64, __param_u8len: i64, __param_repl: *const c_char) {
    var __local_s: *const c_char = cstr_str((__param_self_ as *const cstr))

    var __local_span: csview = cutf8_subview(__local_s, __param_u8pos, __param_u8len)

    cstr_replace_at(__param_self_, ((((((*(&raw const __local_span as *const csview)).buf as usize) -% (__local_s as usize)) as i64) / (sizeof[c_char]() as i64)) as i64), (*(&raw const __local_span as *const csview)).size, __param_repl)

}

unsafe fn cstr_insert_sv(__param_self_: *mut cstr, __param_pos: i64, __param_sv: csview) {
    cstr_replace_at_sv(__param_self_, __param_pos, (0 as i64), __param_sv)

}

// contract: receiver-mut:cstr,unproved:2:read only
unsafe fn cstr_insert(__param_self_: *mut cstr, __param_pos: i64, __param_str: *const c_char) {
    cstr_replace_at_sv(__param_self_, __param_pos, (0 as i64), (csview { buf: __param_str, size: (strlen(__param_str) as i64) } as csview))

}

// contract: receiver-mut:cstr,unproved:2:read only
unsafe fn cstr_u8_insert(__param_self_: *mut cstr, __param_u8pos: i64, __param_str: *const c_char) {
    cstr_insert(__param_self_, (cutf8_to_index(cstr_str((__param_self_ as *const cstr)), __param_u8pos) as i64), __param_str)

}

// contract: receiver-mut:cstr,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn cstr_getline(__param_self_: *mut cstr, __param_fp: *mut c_void) -> bool {
    return cstr_getdelim(__param_self_, (10 as i32), __param_fp)

}

impl cstr {
    pub mut fn append_uninit(__param_len: i64) -> *mut c_char {
        let __param_self_: *mut cstr = self as *mut cstr
        var __local_b: cstr_buf = unsafe { cstr_getbuf(__param_self_) }

        var __ci_expr_logic_0: i32 = 0

        if ((if ((unsafe *(&raw const __local_b as *const cstr_buf)).size + __param_len) > (unsafe *(&raw const __local_b as *const cstr_buf)).cap: 1 else: 0) != 0) {
            (__local_b.data = unsafe { (*__param_self_).reserve((((((*(&raw const __local_b as *const cstr_buf)).size * 3) / 2) + __param_len) as i64)) })

            (__ci_expr_logic_0 = (if (if (unsafe *(&raw const __local_b as *const cstr_buf)).data == null: 1 else: 0) != 0: 1 else: 0))

        }

        if (__ci_expr_logic_0 != 0) {
            return ((null as *mut c_char))
        }


        unsafe { _cstr_set_size(__param_self_, (((*(&raw const __local_b as *const cstr_buf)).size + __param_len) as i64)) }

        return ((unsafe *(&raw const __local_b as *const cstr_buf)).data + (((unsafe *(&raw const __local_b as *const cstr_buf)).size as i64) as usize))

    }

}
