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

extern fn assert_str(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_char, __param_real: *const c_char, __param_caller: *const c_char, __param_line: i32)
extern fn assert_wstr(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const i32, __param_real: *const i32, __param_caller: *const c_char, __param_line: i32)
extern fn assert_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_interval(__param_diag: i32, __param_low: i64, __param_high: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_pointers(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const c_char, __param_line: i32)
extern fn assert_bool(__param_diag: i32, __param_exp: bool, __param_real: bool, __param_caller: *const c_char, __param_line: i32)
extern fn assert_dbl_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_fail(__param_caller: *const c_char, __param_line: i32)
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

unsafe fn cstr_getbuf(__param_s: *mut cstr) -> cstr_buf {
    return (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: (cstr_buf { data: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64), cap: (((~(*(&raw const (*__param_s).lon as *const cstr_lon)).ncap)) as i64) } as cstr_buf) else: (cstr_buf { data: (&raw const (*__param_s).sml.data[0] as *mut c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)), cap: 22 } as cstr_buf))

}

unsafe fn cstr_zv(__param_s: *const cstr) -> zsview {
    return (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: (zsview { str: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64) } as zsview) else: (zsview { str: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)) } as zsview))

}

unsafe fn cstr_sv(__param_s: *const cstr) -> csview {
    return (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: (csview { buf: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64) } as csview) else: (csview { buf: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)) } as csview))

}

// contract: unproved:0:read only
unsafe fn cstr_from_n(__param_str: *const c_char, __param_len: i64) -> cstr {
    var __local_s: cstr

    with_memcpy((((*(&raw mut __local_s as *mut cstr))._cstr_init(__param_len, __param_len) as *mut c_void) as *mut u8), ((__param_str as *const c_void) as *const u8), (((if true: __param_len else: (-1 as i64)) as u64) as i64))

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

    with_memset(((unsafe { (*(&raw mut __local_s as *mut cstr))._cstr_init(__param_size, __param_size) } as *mut c_void) as *mut u8), (__param_value as i32), (((if true: __param_size else: (-1 as i64)) as u64) as i64))

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
    if ((*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128) {
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
    return (((if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: (*(&raw const (*__param_self_).lon as *const cstr_lon)).data else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *mut c_char)) as *mut c_char))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn cstr_str(__param_self_: *const cstr) -> *const c_char {
    return (((if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const c_char))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn cstr_toraw(__param_self_: *const cstr) -> *const c_char {
    return (((if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const c_char))

}

unsafe fn cstr_size(__param_self_: *const cstr) -> i64 {
    return (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).size as i64) else: ((*(&raw const (*__param_self_).sml as *const cstr_sml)).size as i64))

}

unsafe fn cstr_is_empty(__param_self_: *const cstr) -> bool {
    return ((((cstr_size(__param_self_) == 0)) as bool))

}

unsafe fn cstr_capacity(__param_self_: *const cstr) -> i64 {
    return (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: ((~(*(&raw const (*__param_self_).lon as *const cstr_lon)).ncap) as i64) else: (22 as i64))

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

    if ((if not (((if ((__param_pos as u64)) <= (((*(&raw const __local_sv as *const csview)).size as u64)): 1 else: 0) as i32) & ((if __local_len >= 0: 1 else: 0) as i32)): 1 else: 0) as i64) {
        __assert_rtn(c"cstr_subview".ptr, c"cstr_prv.h".ptr, (174 as i32), c"((size_t)pos <= (size_t)sv.size) & (len >= 0)".ptr)
    } else {
        0
    }

    if ((__param_pos + __local_len) > (*(&raw const __local_sv as *const csview)).size) {
        (__local_len = ((((*(&raw const __local_sv as *const csview)).size - __param_pos) as i64)))
    }

    return ((csview { buf: ((*(&raw const __local_sv as *const csview)).buf + ((__param_pos as i64) as usize)), size: __local_len } as csview))

}

unsafe fn cstr_tail(__param_self_: *const cstr, __param_len: i64) -> zsview {
    var __local_len = __param_len
    if ((if not (__local_len >= 0): 1 else: 0) as i64) {
        __assert_rtn(c"cstr_tail".ptr, c"cstr_prv.h".ptr, (180 as i32), c"len >= 0".ptr)
    } else {
        0
    }

    var __local_sv: csview = cstr_sv(__param_self_)

    if (__local_len > (*(&raw const __local_sv as *const csview)).size) {
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

        if __local_u8len {
            (__ci_expr_logic_0 = (if __local_p != (*(&raw const __local_sv as *const csview)).buf: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
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

    if ((*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0) {
        (__local_it_.ref = ((null as *const c_char)))
    }

    return __local_it_

}

unsafe fn cstr_begin(__param_self_: *const cstr) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8: cstr_iter_u8 { chr: csview { buf: cstr_str(__param_self_) }, dec: cutf8_decode_t.zeroed() } }

    if ((*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0) {
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

    if ((*((*__param_it_).ref)) == 0) {
        ((*__param_it_).ref = ((null as *const c_char)))
    } else {
        ((*__param_it_).chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*__param_it_).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*__param_it_).ref, (null as *const c_char)) as i64)))
    }

}

fn cstr_advance(__param_it_: cstr_iter, __param_u8pos: i64) -> cstr_iter {
    (__param_it_.ref = unsafe { cutf8_offset((*(&raw const __param_it_ as *const cstr_iter)).ref, __param_u8pos) })

    if ((unsafe *((*(&raw const __param_it_ as *const cstr_iter)).ref)) == 0) {
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

    if (__local_len <= (*(&raw const __local_sv as *const csview)).size) {
        (__local_sv.size = __local_len)

        (__ci_expr_logic_0 = (if not cutf8_icmp_sv(__local_sv, (csview { buf: __param_sub, size: __local_len } as csview)): 1 else: 0))

    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_iends_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_len: i64 = ((strlen(__param_sub) as i64))

    var __ci_expr_logic_0: i32 = 0

    if (__local_len <= (*(&raw const __local_sv as *const csview)).size) {
        (__ci_expr_logic_0 = (if not cutf8_icmp(((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) - ((__local_len as i64) as usize)) as *const c_char), __param_sub): 1 else: 0))
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

    if ((*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size) {
        (__ci_expr_logic_0 = (if not cutf8_icmp_sv(__local_x, __local_y): 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_iequals(__param_self_: *const cstr, __param_str: *const c_char) -> bool {
    return ((((not cutf8_icmp(cstr_str(__param_self_), __param_str))) as bool))

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

    if ((*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size) {
        (__ci_expr_logic_0 = (if not with_memcmp((((*(&raw const __local_x as *const csview)).buf as *const c_void) as *const u8), (((*(&raw const __local_y as *const csview)).buf as *const c_void) as *const u8), (((if true: (*(&raw const __local_x as *const csview)).size else: (-1 as i64)) as u64) as i64)): 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_equals(__param_self_: *const cstr, __param_str: *const c_char) -> bool {
    return ((((not strcmp(cstr_str(__param_self_), __param_str))) as bool))

}

unsafe fn cstr_equals_sv(__param_self_: *const cstr, __param_sv: csview) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((*(&raw const __param_sv as *const csview)).size == cstr_size(__param_self_)) {
        (__ci_expr_logic_0 = (if not with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sv as *const csview)).buf as *const c_void) as *const u8), (((if true: (*(&raw const __param_sv as *const csview)).size else: (-1 as i64)) as u64) as i64)): 1 else: 0))
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
    if ((*(&raw const __param_sub as *const csview)).size > cstr_size(__param_self_)) {
        return ((false as bool))
    }

    return ((((not with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if true: (*(&raw const __param_sub as *const csview)).size else: (-1 as i64)) as u64) as i64)))) as bool))

}

// contract: receiver:cstr,unproved:1:read only
unsafe fn cstr_starts_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    var __local_sub = __param_sub
    var __local_str: *const c_char = cstr_str(__param_self_)

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (*__local_sub) {
            (__ci_expr_logic_0 = (if (*__local_str) == (*__local_sub): 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_str = __local_str + 1)

        (__local_sub = __local_sub + 1)

    }

    return ((((not (*__local_sub))) as bool))

}

unsafe fn cstr_ends_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    if ((*(&raw const __param_sub as *const csview)).size > (*(&raw const __local_sv as *const csview)).size) {
        return ((false as bool))
    }

    return ((((not with_memcmp((((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) - (((*(&raw const __param_sub as *const csview)).size as i64) as usize)) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if true: (*(&raw const __param_sub as *const csview)).size else: (-1 as i64)) as u64) as i64)))) as bool))

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

        if (not ((((*__local_s) as i32) & (192 as i32)) == 128)) {
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
    var __local__sep: *const c_char = (if cstr_is_empty((__param_self_ as *const cstr)): c"".ptr else: __param_sep)

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not __ci_expr_old_0) {
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
    var __local__sep: *const c_char = (if cstr_is_empty((__param_self_ as *const cstr)): c"".ptr else: __param_sep)

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not __ci_expr_old_0) {
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

    with_memcpy((((__local_d + ((__param_pos as i64) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __param_repl as *const csview)).buf as *const c_void) as *const u8), (((if true: (*(&raw const __param_repl as *const csview)).size else: (-1 as i64)) as u64) as i64))

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

// contract: receiver-mut:Mymap,unproved:2:read only
unsafe fn Mymap_emplace(__param_self_: *mut Mymap, __param_rkey: i32, __param_rmapped: *const c_char) -> Mymap_result {
    var __local_res: Mymap_result = Mymap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local_res as *const Mymap_result)).inserted {
        ((*((&raw const (*(*(&raw const __local_res as *const Mymap_result)).ref).first as *const i32) as *mut i32)) = __param_rkey)

        let __ci_copy_20: cstr = cstr_from(__param_rmapped)
        with_memcpy((&raw mut (*(*(&raw const __local_res as *const Mymap_result)).ref).second as *mut u8), (&raw const __ci_copy_20 as *const u8), sizeof[cstr]())

    }

    return __local_res

}

fn Mymap_clone(__param_tree: Mymap) -> Mymap {
    var __local_out: Mymap = __param_tree

    (__local_out.capacity = ((0 as i32)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Mymap)).capacity)

    (__local_out.head = (unsafe *(&raw const __local_out as *const Mymap)).size)

    (__local_out.disp = (unsafe *(&raw const __local_out as *const Mymap)).head)

    (__local_out.root = (unsafe *(&raw const __local_out as *const Mymap)).disp)


    (__local_out.nodes = ((null as *mut Mymap_node)))

    unsafe { Mymap_reserve((&raw mut __local_out as *mut Mymap), ((*(&raw const __param_tree as *const Mymap)).size as i64)) }

    (__local_out.root = ((unsafe { Mymap_clone_r_((&raw mut __local_out as *mut Mymap), (*(&raw const __param_tree as *const Mymap)).nodes, (*(&raw const __param_tree as *const Mymap)).root) } as i32)))

    return __local_out

}

// contract: unproved:0:casts away const
unsafe fn Mymap_drop(__param_cself: *const Mymap) {
    var __local_self_: *mut Mymap = ((__param_cself as *mut Mymap))

    if ((*__local_self_).nodes == null) {
        return
    }

    Mymap_drop_r_(__local_self_, (*__local_self_).root)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))

}

unsafe fn Mymap_reserve(__param_self_: *mut Mymap, __param_cap: i64) -> bool {
    if (__param_cap <= (*__param_self_).capacity) {
        return ((false as bool))
    }

    var __local_nodes: *mut Mymap_node = (((with_realloc((((*__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if true: ((if true: (((__param_cap + 1) * (sizeof[Mymap_node]() as i64)) as i64) else: ((((*__param_self_).capacity + 1) * (sizeof[Mymap_node]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Mymap_node))

    if (__local_nodes == null) {
        return ((false as bool))
    }

    ((__local_nodes[0]) = ((Mymap_node.zeroed() as Mymap_node)))

    ((*__param_self_).nodes = __local_nodes)

    ((*__param_self_).capacity = ((__param_cap as i32)))

    return ((true as bool))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:2:out-parameter read before the write
unsafe fn Mymap_find_it(__param_self_: *const Mymap, __param_rkey: i32, __param_out: *mut Mymap_iter) -> *mut Mymap_value {
    var __local_tn: i32 = (*__param_self_).root

    var __local_d: *mut Mymap_node = with 0 as __ci_expr_seq_6 {
        ((*__param_out)._d = (*__param_self_).nodes)
        (*__param_out)._d
    }

    ((*__param_out)._top = ((0 as i32)))

    while __local_tn {
        var __local_c: i32

        var __local__raw: i32 = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)).first as *const i32) as *mut i32))

        (__local_c = ((((if (*(&raw mut __param_rkey as *mut i32)) < (*(&raw const __local__raw as *const i32)): 1 else: 0) - (if (*(&raw const __local__raw as *const i32)) < (*(&raw mut __param_rkey as *mut i32)): 1 else: 0)) as i32)))

        if (__local_c < 0) {
            (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
        } else {
            if (__local_c > 0) {
                var __ci_expr_old_0: i32 = (*__param_out)._top

                ((*__param_out)._top = (*__param_out)._top + 1)

                ((*__param_out)._st[__ci_expr_old_0] = __local_tn)


                (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))

            } else {
                ((*__param_out)._tn = (((__local_d[__local_tn]).link[1] as i32)))

                ((*__param_out).ref = (((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)))

                return (*__param_out).ref


            }
        }


    }

    ((*__param_out).ref = ((null as *mut Mymap_value)))

    return (*__param_out).ref


}

unsafe fn Mymap_lower_bound(__param_self_: *const Mymap, __param_rkey: i32) -> Mymap_iter {
    var __local_it_: Mymap_iter

    Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter))

    var __ci_expr_logic_0: i32 = 0

    if ((*(&raw const __local_it_ as *const Mymap_iter)).ref == null) {
        (__ci_expr_logic_0 = (if (*(&raw const __local_it_ as *const Mymap_iter))._top != 0: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        var __local_tn: i32 = with 0 as __ci_expr_seq_11 {
            (__local_it_._top = (*(&raw const __local_it_ as *const Mymap_iter))._top - 1)
            ((*(&raw const __local_it_ as *const Mymap_iter))._st[(*(&raw const __local_it_ as *const Mymap_iter))._top] as i32)
        }

        (__local_it_._tn = ((((*(&raw const __local_it_ as *const Mymap_iter))._d[__local_tn]).link[1] as i32)))

        (__local_it_.ref = (((&raw const (__local_it_._d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)))

    }


    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn Mymap_front(__param_self_: *const Mymap) -> *mut Mymap_value {
    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while (__local_d[__local_tn]).link[0] {
        (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn Mymap_back(__param_self_: *const Mymap) -> *mut Mymap_value {
    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while (__local_d[__local_tn]).link[1] {
        (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value))

}

unsafe fn Mymap_erase(__param_self_: *mut Mymap, __param_rkey: i32) -> i32 {
    var __local_erased: i32 = ((0 as i32))

    var __local_root: i32 = ((Mymap_erase_r_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut i32) as *const i32), (&raw mut __local_erased as *mut i32)) as i32))

    if (__local_erased == 0) {
        return 0
    }

    ((*__param_self_).root = __local_root)

    ((*__param_self_).size = (*__param_self_).size - 1)

    return 1

}

unsafe fn Mymap_erase_at(__param_self_: *mut Mymap, __param_it_: Mymap_iter) -> Mymap_iter {
    var __local_raw: i32 = (*((&raw const (*(*(&raw const __param_it_ as *const Mymap_iter)).ref).first as *const i32) as *mut i32))

    Mymap_next((&raw mut __param_it_ as *mut Mymap_iter))

    if ((*(&raw const __param_it_ as *const Mymap_iter)).ref != null) {
        var __local_nxt: i32 = (*((&raw const (*(*(&raw const __param_it_ as *const Mymap_iter)).ref).first as *const i32) as *mut i32))

        Mymap_erase(__param_self_, __local_raw)

        Mymap_find_it((__param_self_ as *const Mymap), __local_nxt, (&raw mut __param_it_ as *mut Mymap_iter))

    } else {
        Mymap_erase(__param_self_, __local_raw)
    }

    return __param_it_

}

unsafe fn Mymap_erase_range(__param_self_: *mut Mymap, __param_it1: Mymap_iter, __param_it2: Mymap_iter) -> Mymap_iter {
    var __local_it1 = __param_it1
    if ((*(&raw const __param_it2 as *const Mymap_iter)).ref == null) {
        while ((*(&raw const __local_it1 as *const Mymap_iter)).ref != null) {
            let __ci_copy_21: Mymap_iter = Mymap_erase_at(__param_self_, __local_it1)
            with_memcpy((&raw mut __local_it1 as *mut u8), (&raw const __ci_copy_21 as *const u8), sizeof[Mymap_iter]())
        }

        return __local_it1

    }

    var __local_k1: i32 = (*((&raw const (*(*(&raw const __local_it1 as *const Mymap_iter)).ref).first as *const i32) as *mut i32))

    var __local_k2: i32 = (*((&raw const (*(*(&raw const __param_it2 as *const Mymap_iter)).ref).first as *const i32) as *mut i32))


    var __local_r1: i32 = (*(&raw mut __local_k1 as *mut i32))

    while true {
        if (with_memcmp((((&raw mut __local_k1 as *mut i32) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut i32) as *const c_void) as *const u8), ((sizeof[i32]() as u64) as i64)) == 0) {
            return __local_it1
        }

        Mymap_next((&raw mut __local_it1 as *mut Mymap_iter))

        (__local_k1 = (*((&raw const (*(*(&raw const __local_it1 as *const Mymap_iter)).ref).first as *const i32) as *mut i32)))

        Mymap_erase(__param_self_, __local_r1)

        (__local_r1 = (*(&raw mut __local_k1 as *mut i32)))

        Mymap_find_it((__param_self_ as *const Mymap), __local_r1, (&raw mut __local_it1 as *mut Mymap_iter))

    }

}

unsafe fn Mymap_begin(__param_self_: *const Mymap) -> Mymap_iter {
    var __local_it_: Mymap_iter

    (__local_it_.ref = ((null as *mut Mymap_value)))

    (__local_it_._d = (*__param_self_).nodes)

    (__local_it_._top = ((0 as i32)))


    (__local_it_._tn = (*__param_self_).root)

    if (*(&raw const __local_it_ as *const Mymap_iter))._tn {
        Mymap_next((&raw mut __local_it_ as *mut Mymap_iter))
    }

    return __local_it_

}

unsafe fn Mymap_next(__param_it_: *mut Mymap_iter) -> Unit {
    var __local_tn: i32 = (*__param_it_)._tn

    var __ci_expr_logic_0: i32

    if (*__param_it_)._top {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_tn: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        while __local_tn {
            var __ci_expr_old_1: i32 = (*__param_it_)._top

            ((*__param_it_)._top = (*__param_it_)._top + 1)

            ((*__param_it_)._st[__ci_expr_old_1] = __local_tn)


            (__local_tn = ((((*__param_it_)._d[__local_tn]).link[0] as i32)))

        }

        ((*__param_it_)._top = (*__param_it_)._top - 1)

        (__local_tn = (((*__param_it_)._st[(*__param_it_)._top] as i32)))


        ((*__param_it_)._tn = ((((*__param_it_)._d[__local_tn]).link[1] as i32)))

        ((*__param_it_).ref = (((&raw const ((*__param_it_)._d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)))

    } else {
        ((*__param_it_).ref = ((null as *mut Mymap_value)))
    }


}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Mymap_get(__param_self_: *const Mymap, __param_rkey: i32) -> *const Mymap_value {
    var __local_it_: Mymap_iter

    return ((Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) as *const Mymap_value))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Mymap_get_mut(__param_self_: *mut Mymap, __param_rkey: i32) -> *mut Mymap_value {
    var __local_it_: Mymap_iter

    return ((Mymap_find_it((__param_self_ as *const Mymap), __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) as *mut Mymap_value))

}

// contract: receiver:Mymap,unproved:1:read only
pub unsafe fn Mymap_value_drop(__param_self_: *const Mymap, __param_val: *mut Mymap_value) {


    cstr_drop((((&raw const (*__param_val).second as *const cstr) as *mut cstr) as *const cstr))

}

// contract: receiver-mut:Mymap,unproved:1:read only
pub unsafe fn Mymap_copy(__param_self_: *mut Mymap, __param_other: *const Mymap) -> Unit {
    if (__param_self_ == __param_other) {
        return
    }

    Mymap_drop((__param_self_ as *const Mymap))

    let __ci_copy_16: Mymap = Mymap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_16 as *const u8), sizeof[Mymap]())

}

unsafe fn Mymap_insert_entry_(__param_self_: *mut Mymap, __param_rkey: i32) -> Mymap_result {
    var __local_res: Mymap_result = Mymap_result.zeroed()

    var __local_tn: i32 = ((Mymap_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut i32) as *const i32), (&raw mut __local_res as *mut Mymap_result)) as i32))

    ((*__param_self_).root = __local_tn)

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const Mymap_result)).inserted as i32))

    return __local_res

}

unsafe fn Mymap_insert_or_assign(__param_self_: *mut Mymap, __param__key: i32, __param__mapped: cstr) -> Mymap_result {
    var __local__res: Mymap_result = Mymap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut i32)))

    var __local__mp: *mut cstr = (if (*(&raw const __local__res as *const Mymap_result)).ref != null: ((&raw const (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *const cstr) as *mut cstr) else: (&raw mut __param__mapped as *mut cstr))

    if (*(&raw const __local__res as *const Mymap_result)).inserted {
        ((*(*(&raw const __local__res as *const Mymap_result)).ref).first = __param__key)
    } else {

        cstr_drop((__local__mp as *const cstr))

    }

    with_memcpy((&raw mut (*__local__mp) as *mut u8), (&raw const __param__mapped as *const u8), sizeof[cstr]())

    return __local__res

}

// contract: receiver-mut:Mymap,unproved:2:read only
unsafe fn Mymap_emplace_or_assign(__param_self_: *mut Mymap, __param_rkey: i32, __param_rmapped: *const c_char) -> Mymap_result {
    var __local__res: Mymap_result = Mymap_insert_entry_(__param_self_, __param_rkey)

    if (*(&raw const __local__res as *const Mymap_result)).inserted {
        ((*(*(&raw const __local__res as *const Mymap_result)).ref).first = __param_rkey)
    } else {
        if ((*(&raw const __local__res as *const Mymap_result)).ref == null) {
            return __local__res
        }

        cstr_drop((((&raw const (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *const cstr) as *mut cstr) as *const cstr))

    }

    let __ci_copy_34: cstr = cstr_from(__param_rmapped)
    with_memcpy((&raw mut (*(*(&raw const __local__res as *const Mymap_result)).ref).second as *mut u8), (&raw const __ci_copy_34 as *const u8), sizeof[cstr]())

    return __local__res

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Mymap_at(__param_self_: *const Mymap, __param_rkey: i32) -> *const cstr {
    var __local_it_: Mymap_iter

    return ((((&raw const Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)).second as *const cstr) as *mut cstr) as *const cstr))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Mymap_at_mut(__param_self_: *mut Mymap, __param_rkey: i32) -> *mut cstr {
    var __local_it_: Mymap_iter

    return (((&raw const Mymap_find_it((__param_self_ as *const Mymap), __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)).second as *const cstr) as *mut cstr))

}

pub fn Mymap_advance(__param_it_: Mymap_iter, __param_n: u64) -> Mymap_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if __ci_expr_old_0 {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const Mymap_iter)).ref != null: 1 else: 0))
        }

        if (not __ci_expr_logic_1) {
            break
        }

        unsafe { Mymap_next((&raw mut __param_it_ as *mut Mymap_iter)) }

    }

    return __param_it_

}

// contract: receiver:Mymap,unproved:1:read only
pub unsafe fn Mymap_eq(__param_self_: *const Mymap, __param_other: *const Mymap) -> bool {
    if ((*__param_self_).size() != (*__param_other).size()) {
        return ((false as bool))
    }

    var __local_i: Mymap_iter = Mymap_begin(__param_self_)

    var __local_j: Mymap_iter = Mymap_begin(__param_other)


    while ((*(&raw const __local_i as *const Mymap_iter)).ref != null) {
        var __local__rx: i32 = (*((&raw const (*(*(&raw const __local_i as *const Mymap_iter)).ref).first as *const i32) as *mut i32))

        var __local__ry: i32 = (*((&raw const (*(*(&raw const __local_j as *const Mymap_iter)).ref).first as *const i32) as *mut i32))


        if (not ((*(&raw const __local__rx as *const i32)) == (*(&raw const __local__ry as *const i32)))) {
            return ((false as bool))
        }


        Mymap_next((&raw mut __local_i as *mut Mymap_iter))

        Mymap_next((&raw mut __local_j as *mut Mymap_iter))


    }

    return ((true as bool))

}

// contract: receiver-mut:Mymap,unproved:2:read only
pub unsafe fn Mymap_put(__param_self_: *mut Mymap, __param_rkey: i32, __param_rmapped: *const c_char) -> Mymap_result {
    return Mymap_emplace_or_assign(__param_self_, __param_rkey, __param_rmapped)

}

// contract: receiver-mut:Mymap,unproved:1:read only
pub unsafe fn Mymap_put_n(__param_self_: *mut Mymap, __param_raw: *const Mymap_raw, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not __ci_expr_old_0) {
            break
        }

        Mymap_put(__param_self_, (*__local_raw).first, (*__local_raw).second)

        (__local_raw = __local_raw + 1)

    }

}

pub fn Mymap_init() -> Mymap {
    var __local_cx: Mymap = Mymap.zeroed()

    return __local_cx

}

// contract: unproved:0:Mymap_put_n may write through it
pub unsafe fn Mymap_from_n(__param_raw: *const Mymap_raw, __param_n: i64) -> Mymap {
    var __local_cx: Mymap = Mymap.zeroed()

    Mymap_put_n((&raw mut __local_cx as *mut Mymap), __param_raw, __param_n)

    return __local_cx

}

pub fn Mymap_with_capacity(__param_cap: i64) -> Mymap {
    var __local_cx: Mymap = Mymap.zeroed()

    unsafe { Mymap_reserve((&raw mut __local_cx as *mut Mymap), __param_cap) }

    return __local_cx

}

unsafe fn Mymap_new_node_(__param_self_: *mut Mymap, __param_level: i32) -> i32 {
    var __local_tn: i32

    if ((*__param_self_).disp != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as i32)))

    } else {
        if ((*__param_self_).head == (*__param_self_).capacity) {
            if (not Mymap_reserve(__param_self_, (((((*__param_self_).head * 3) / 2) + 4) as i64))) {
                return 0
            }
        }

        ((*__param_self_).head = (*__param_self_).head + 1)

        (__local_tn = (*__param_self_).head)


    }

    var __local_dn: *mut Mymap_node = (((&raw const ((*__param_self_).nodes[__local_tn]) as *const Mymap_node) as *mut Mymap_node))

    ((*__local_dn).link[1] = ((0 as i32)))

    ((*__local_dn).link[0] = (((*__local_dn).link[1] as i32)))


    ((*__local_dn).level = ((__param_level as i8)))

    return __local_tn

}

// contract: unproved:0:indexed as an array
unsafe fn Mymap_skew_(__param_d: *mut Mymap_node, __param_tn: i32) -> i32 {
    var __local_tn = __param_tn
    var __ci_expr_logic_0: i32 = 0

    if (__local_tn != 0) {
        (__ci_expr_logic_0 = (if (__param_d[(__param_d[__local_tn]).link[0]]).level == (__param_d[__local_tn]).level: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        var __local_tmp: i32 = (((__param_d[__local_tn]).link[0] as i32))

        ((__param_d[__local_tn]).link[0] = (((__param_d[__local_tmp]).link[1] as i32)))

        ((__param_d[__local_tmp]).link[1] = __local_tn)

        (__local_tn = __local_tmp)

    }


    return __local_tn

}

// contract: unproved:0:indexed as an array
unsafe fn Mymap_split_(__param_d: *mut Mymap_node, __param_tn: i32) -> i32 {
    var __local_tn = __param_tn
    if ((__param_d[(__param_d[(__param_d[__local_tn]).link[1]]).link[1]]).level == (__param_d[__local_tn]).level) {
        var __local_tmp: i32 = (((__param_d[__local_tn]).link[1] as i32))

        ((__param_d[__local_tn]).link[1] = (((__param_d[__local_tmp]).link[0] as i32)))

        ((__param_d[__local_tmp]).link[0] = __local_tn)

        (__local_tn = __local_tmp)

        ((__param_d[__local_tn]).level = (__param_d[__local_tn]).level + 1)

    }

    return __local_tn

}

// contract: receiver-mut:Mymap,unproved:2:read only,unproved:3:out-parameter written conditionally
unsafe fn Mymap_insert_entry_i_(__param_self_: *mut Mymap, __param_tn: i32, __param_rkey: *const i32, __param__res: *mut Mymap_result) -> i32 {
    var __local_up: List[i32] = [0; 64]

    var __local_tx: i32 = __param_tn


    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    var __local_c: i32

    var __local_top: i32 = ((0 as i32))

    var __local_dir: i32 = ((0 as i32))


    while __local_tx {
        var __ci_expr_old_0: i32 = __local_top

        (__local_top = __local_top + 1)

        (__local_up[__ci_expr_old_0] = __local_tx)


        var __local__raw: i32 = (*((&raw const (*((&raw const (__local_d[__local_tx]).value as *const Mymap_value) as *mut Mymap_value)).first as *const i32) as *mut i32))

        (__local_c = ((((if (*__param_rkey) < (*(&raw const __local__raw as *const i32)): 1 else: 0) - (if (*(&raw const __local__raw as *const i32)) < (*__param_rkey): 1 else: 0)) as i32)))

        if (__local_c == 0) {
            ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Mymap_value) as *mut Mymap_value)))

            return __param_tn

        }


        (__local_dir = (((if __local_c < 0: 1 else: 0) as i32)))

        (__local_tx = (((__local_d[__local_tx]).link[__local_dir] as i32)))

    }

    (__local_tx = ((Mymap_new_node_(__param_self_, (1 as i32)) as i32)))

    if (__local_tx == 0) {
        return 0
    }


    (__local_d = (*__param_self_).nodes)

    ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Mymap_value) as *mut Mymap_value)))

    ((*__param__res).inserted = true)

    if (__local_top == 0) {
        return __local_tx
    }

    ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = __local_tx)

    while true {
        var __ci_expr_old_1: i32 = __local_top

        (__local_top = __local_top - 1)

        if (not __ci_expr_old_1) {
            break
        }

        if (__local_top != 0) {
            (__local_dir = (((if (__local_d[__local_up[(__local_top - 1)]]).link[1] == __local_up[__local_top]: 1 else: 0) as i32)))
        }

        (__local_up[__local_top] = ((Mymap_skew_(__local_d, (__local_up[__local_top] as i32)) as i32)))

        (__local_up[__local_top] = ((Mymap_split_(__local_d, (__local_up[__local_top] as i32)) as i32)))

        if __local_top {
            ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = ((__local_up[__local_top] as i32)))
        }

    }

    return __local_up[0]

}

// contract: receiver-mut:Mymap,unproved:2:read only,unproved:3:out-parameter a return before the write
unsafe fn Mymap_erase_r_(__param_self_: *mut Mymap, __param_tn: i32, __param_rkey: *const i32, __param_erased: *mut i32) -> i32 {
    var __local_tn = __param_tn
    var __local_d: *mut Mymap_node = (*__param_self_).nodes

    if (__local_tn == 0) {
        return 0
    }

    var __local_raw: i32 = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)).first as *const i32) as *mut i32))

    var __local_tx: i32

    var __local_c: i32 = ((((if (*__param_rkey) < (*(&raw mut __local_raw as *mut i32)): 1 else: 0) - (if (*(&raw mut __local_raw as *mut i32)) < (*__param_rkey): 1 else: 0)) as i32))

    if (__local_c != 0) {
        ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] = ((Mymap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] as i32), __param_rkey, __param_erased) as i32)))
    } else {
        var __ci_expr_old_0: i32 = (*__param_erased)

        ((*__param_erased) = (*__param_erased) + 1)

        if (__ci_expr_old_0 == 0) {
            Mymap_value_drop((__param_self_ as *const Mymap), ((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value))
        }


        var __ci_expr_logic_1: i32 = 0

        if (__local_d[__local_tn]).link[0] {
            (__ci_expr_logic_1 = (if (__local_d[__local_tn]).link[1]: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            (__local_tx = (((__local_d[__local_tn]).link[0] as i32)))

            while (__local_d[__local_tx]).link[1] {
                (__local_tx = (((__local_d[__local_tx]).link[1] as i32)))
            }

            with_memcpy((&raw mut (__local_d[__local_tn]).value as *mut u8), (&raw const (__local_d[__local_tx]).value as *const u8), sizeof[Mymap_value]())

            (__local_raw = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Mymap_value) as *mut Mymap_value)).first as *const i32) as *mut i32)))

            ((__local_d[__local_tn]).link[0] = ((Mymap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[0] as i32), ((&raw mut __local_raw as *mut i32) as *const i32), __param_erased) as i32)))

        } else {
            (__local_tx = __local_tn)

            (__local_tn = (((__local_d[__local_tn]).link[(if (__local_d[__local_tn]).link[0] == 0: 1 else: 0)] as i32)))

            ((__local_d[__local_tx]).link[1] = (*__param_self_).disp)

            ((*__param_self_).disp = __local_tx)

        }


    }

    (__local_tx = (((__local_d[__local_tn]).link[1] as i32)))

    var __ci_expr_logic_2: i32

    if ((__local_d[(__local_d[__local_tn]).link[0]]).level < (((__local_d[__local_tn]).level as i32) - 1)) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (__local_d[__local_tx]).level < (((__local_d[__local_tn]).level as i32) - 1): 1 else: 0))
    }

    if __ci_expr_logic_2 {
        ((__local_d[__local_tn]).level = (__local_d[__local_tn]).level - 1)

        if ((__local_d[__local_tx]).level > (__local_d[__local_tn]).level) {
            ((__local_d[__local_tx]).level = (__local_d[__local_tn]).level)
        }


        (__local_tn = ((Mymap_skew_(__local_d, __local_tn) as i32)))

        ((__local_d[__local_tn]).link[1] = ((Mymap_skew_(__local_d, ((__local_d[__local_tn]).link[1] as i32)) as i32)))

        (__local_tx = (((__local_d[__local_tn]).link[1] as i32)))


        ((__local_d[__local_tx]).link[1] = ((Mymap_skew_(__local_d, ((__local_d[__local_tx]).link[1] as i32)) as i32)))

        (__local_tn = ((Mymap_split_(__local_d, __local_tn) as i32)))

        ((__local_d[__local_tn]).link[1] = ((Mymap_split_(__local_d, ((__local_d[__local_tn]).link[1] as i32)) as i32)))

    }


    return __local_tn

}

// contract: receiver-mut:Mymap,unproved:1:read only
unsafe fn Mymap_clone_r_(__param_self_: *mut Mymap, __param_src: *mut Mymap_node, __param_sn: i32) -> i32 {
    if (__param_sn == 0) {
        return 0
    }

    var __local_tx: i32

    var __local_tn: i32 = ((Mymap_new_node_(__param_self_, ((__param_src[__param_sn]).level as i32)) as i32))


    let __ci_copy_31: Mymap_value = (*(__param_self_ as *const Mymap)).value_clone((__param_src[__param_sn]).value)
    with_memcpy((&raw mut ((*__param_self_).nodes[__local_tn]).value as *mut u8), (&raw const __ci_copy_31 as *const u8), sizeof[Mymap_value]())

    (__local_tx = ((Mymap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[0] as i32)) as i32)))

    (((*__param_self_).nodes[__local_tn]).link[0] = __local_tx)

    (__local_tx = ((Mymap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[1] as i32)) as i32)))

    (((*__param_self_).nodes[__local_tn]).link[1] = __local_tx)

    return __local_tn

}

unsafe fn Mymap_drop_r_(__param_s: *mut Mymap, __param_tn: i32) -> Unit {
    if (__param_tn != 0) {
        Mymap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[0] as i32))

        Mymap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[1] as i32))

        Mymap_value_drop((__param_s as *const Mymap), ((&raw const ((*__param_s).nodes[__param_tn]).value as *const Mymap_value) as *mut Mymap_value))

    }

}

@[repr(C)]
pub type ctest_sortedmap_erase_run__c_i2_anon { _ref: *const *mut Mymap = null, ref: *mut *mut Mymap = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_sortedmap_erase_run__c_i2_anon
fn ctest_sortedmap_erase_run() {
    var __local_m1: Mymap = Mymap.zeroed()

    var __local_res: Mymap = Mymap.zeroed()

    unsafe { (*(&raw mut __local_m1 as *mut Mymap)).insert((1 as i32), unsafe { cstr_from_n(c"A".ptr, ((((2 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) }) }

    unsafe { (*(&raw mut __local_m1 as *mut Mymap)).insert((2 as i32), unsafe { cstr_from_n(c"B".ptr, ((((2 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) }) }

    unsafe { (*(&raw mut __local_m1 as *mut Mymap)).insert((3 as i32), unsafe { cstr_from_n(c"C".ptr, ((((2 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) }) }

    unsafe { (*(&raw mut __local_m1 as *mut Mymap)).insert((4 as i32), unsafe { cstr_from_n(c"D".ptr, ((((2 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) }) }

    unsafe { (*(&raw mut __local_m1 as *mut Mymap)).insert((5 as i32), unsafe { cstr_from_n(c"E".ptr, ((((2 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) }) }

    var __ci_expr_lit_0: [Mymap_raw; 5] = [Mymap_raw { first: 1, second: (("A" as *mut c_char) as *const c_char) }, Mymap_raw { first: 2, second: (("B" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("C" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("D" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("E" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_0[0] as *mut Mymap_raw), (([Mymap_raw { first: 1, second: (("A" as *mut c_char) as *const c_char) }, Mymap_raw { first: 2, second: (("B" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("C" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("D" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("E" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m1 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (23 as i32))

    unsafe { Mymap_erase_at((&raw mut __local_m1 as *mut Mymap), Mymap_advance(unsafe { Mymap_begin(((&raw mut __local_m1 as *mut Mymap) as *const Mymap)) }, (1 as u64))) }

    var __ci_expr_lit_1: [Mymap_raw; 4] = [Mymap_raw { first: 1, second: (("A" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("C" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("D" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("E" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_1[0] as *mut Mymap_raw), (([Mymap_raw { first: 1, second: (("A" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("C" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("D" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("E" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m1 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (28 as i32))

    var __local_m2: Mymap = with 0 as __ci_expr_seq_21 {
        var __ci_expr_lit_2: [Mymap_raw; 5] = [Mymap_raw { first: 10, second: (("Bob" as *mut c_char) as *const c_char) }, Mymap_raw { first: 11, second: (("Rob" as *mut c_char) as *const c_char) }, Mymap_raw { first: 12, second: (("Robert" as *mut c_char) as *const c_char) }, Mymap_raw { first: 13, second: (("Bert" as *mut c_char) as *const c_char) }, Mymap_raw { first: 14, second: (("Bobby" as *mut c_char) as *const c_char) }]
        unsafe { Mymap_from_n((&__ci_expr_lit_2[0] as *mut Mymap_raw), (([Mymap_raw { first: 10, second: (("Bob" as *mut c_char) as *const c_char) }, Mymap_raw { first: 11, second: (("Rob" as *mut c_char) as *const c_char) }, Mymap_raw { first: 12, second: (("Robert" as *mut c_char) as *const c_char) }, Mymap_raw { first: 13, second: (("Bert" as *mut c_char) as *const c_char) }, Mymap_raw { first: 14, second: (("Bobby" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }
    }

    var __local_it1: Mymap_iter = Mymap_advance(unsafe { Mymap_begin(((&raw mut __local_m2 as *mut Mymap) as *const Mymap)) }, (1 as u64))

    var __local_it2: Mymap_iter = unsafe { (*((&raw mut __local_m2 as *mut Mymap) as *const Mymap)).find(unsafe { Mymap_back(((&raw mut __local_m2 as *mut Mymap) as *const Mymap)) }.first) }

    unsafe { Mymap_erase_range((&raw mut __local_m2 as *mut Mymap), __local_it1, __local_it2) }

    var __ci_expr_lit_3: [Mymap_raw; 2] = [Mymap_raw { first: 10, second: (("Bob" as *mut c_char) as *const c_char) }, Mymap_raw { first: 14, second: (("Bobby" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_3[0] as *mut Mymap_raw), (([Mymap_raw { first: 10, second: (("Bob" as *mut c_char) as *const c_char) }, Mymap_raw { first: 14, second: (("Bobby" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m2 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (48 as i32))

    var __local_m3: Mymap = Mymap.zeroed()

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (1 as i32), c"red".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (2 as i32), c"yellow".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (3 as i32), c"blue".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (4 as i32), c"green".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (5 as i32), c"orange".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (6 as i32), c"purple".ptr) }

    unsafe { Mymap_emplace((&raw mut __local_m3 as *mut Mymap), (7 as i32), c"pink".ptr) }

    var __ci_expr_lit_4: [Mymap_raw; 7] = [Mymap_raw { first: 1, second: (("red" as *mut c_char) as *const c_char) }, Mymap_raw { first: 2, second: (("yellow" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("blue" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("green" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("orange" as *mut c_char) as *const c_char) }, Mymap_raw { first: 6, second: (("purple" as *mut c_char) as *const c_char) }, Mymap_raw { first: 7, second: (("pink" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_4[0] as *mut Mymap_raw), (([Mymap_raw { first: 1, second: (("red" as *mut c_char) as *const c_char) }, Mymap_raw { first: 2, second: (("yellow" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("blue" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("green" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("orange" as *mut c_char) as *const c_char) }, Mymap_raw { first: 6, second: (("purple" as *mut c_char) as *const c_char) }, Mymap_raw { first: 7, second: (("pink" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (63 as i32))

    var __local_count: i32 = ((unsafe { Mymap_erase((&raw mut __local_m3 as *mut Mymap), (2 as i32)) } as i32))

    assert_compare((1 as i32), c"==".ptr, (1 as i64), (__local_count as i64), c"smap_test.c".ptr, (67 as i32))

    var __ci_expr_lit_5: [Mymap_raw; 6] = [Mymap_raw { first: 1, second: (("red" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("blue" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("green" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("orange" as *mut c_char) as *const c_char) }, Mymap_raw { first: 6, second: (("purple" as *mut c_char) as *const c_char) }, Mymap_raw { first: 7, second: (("pink" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_5[0] as *mut Mymap_raw), (([Mymap_raw { first: 1, second: (("red" as *mut c_char) as *const c_char) }, Mymap_raw { first: 3, second: (("blue" as *mut c_char) as *const c_char) }, Mymap_raw { first: 4, second: (("green" as *mut c_char) as *const c_char) }, Mymap_raw { first: 5, second: (("orange" as *mut c_char) as *const c_char) }, Mymap_raw { first: 6, second: (("purple" as *mut c_char) as *const c_char) }, Mymap_raw { first: 7, second: (("pink" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (70 as i32))

    loop {
        var __local__c_i2: ctest_sortedmap_erase_run__c_i2_anon = ctest_sortedmap_erase_run__c_i2_anon.zeroed()

        var __ci_expr_lit_6: [*mut Mymap; 4] = [(&raw mut __local_m1 as *mut Mymap), (&raw mut __local_m2 as *mut Mymap), (&raw mut __local_m3 as *mut Mymap), (&raw mut __local_res as *mut Mymap)]

        __local__c_i2 = ctest_sortedmap_erase_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_6)[0] as *mut *mut Mymap) as *const *mut Mymap)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon))._ref as *mut *mut Mymap)
        __local__c_i2.size = (((((4 * (sizeof[usize]() as usize)) as u64) / (sizeof[Mymap]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).size) {
            unsafe { Mymap_drop(((*((*(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).ref)) as *const Mymap)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_erase_run__c_i2_anon)).index + 1)


        }


        if not (false) {
            break
        }
    }

}

fn Intmap_clone(__param_tree: Intmap) -> Intmap {
    var __local_out: Intmap = __param_tree

    (__local_out.capacity = ((0 as i32)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Intmap)).capacity)

    (__local_out.head = (unsafe *(&raw const __local_out as *const Intmap)).size)

    (__local_out.disp = (unsafe *(&raw const __local_out as *const Intmap)).head)

    (__local_out.root = (unsafe *(&raw const __local_out as *const Intmap)).disp)


    (__local_out.nodes = ((null as *mut Intmap_node)))

    unsafe { Intmap_reserve((&raw mut __local_out as *mut Intmap), ((*(&raw const __param_tree as *const Intmap)).size as i64)) }

    (__local_out.root = ((unsafe { Intmap_clone_r_((&raw mut __local_out as *mut Intmap), (*(&raw const __param_tree as *const Intmap)).nodes, (*(&raw const __param_tree as *const Intmap)).root) } as i32)))

    return __local_out

}

// contract: unproved:0:casts away const
unsafe fn Intmap_drop(__param_cself: *const Intmap) {
    var __local_self_: *mut Intmap = ((__param_cself as *mut Intmap))

    if ((*__local_self_).nodes == null) {
        return
    }

    Intmap_drop_r_(__local_self_, (*__local_self_).root)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))

}

unsafe fn Intmap_reserve(__param_self_: *mut Intmap, __param_cap: i64) -> bool {
    if (__param_cap <= (*__param_self_).capacity) {
        return ((false as bool))
    }

    var __local_nodes: *mut Intmap_node = (((with_realloc((((*__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if true: ((if true: (((__param_cap + 1) * (sizeof[Intmap_node]() as i64)) as i64) else: ((((*__param_self_).capacity + 1) * (sizeof[Intmap_node]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Intmap_node))

    if (__local_nodes == null) {
        return ((false as bool))
    }

    ((__local_nodes[0]) = ((Intmap_node.zeroed() as Intmap_node)))

    ((*__param_self_).nodes = __local_nodes)

    ((*__param_self_).capacity = ((__param_cap as i32)))

    return ((true as bool))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:2:out-parameter read before the write
unsafe fn Intmap_find_it(__param_self_: *const Intmap, __param_rkey: i32, __param_out: *mut Intmap_iter) -> *mut Intmap_value {
    var __local_tn: i32 = (*__param_self_).root

    var __local_d: *mut Intmap_node = with 0 as __ci_expr_seq_6 {
        ((*__param_out)._d = (*__param_self_).nodes)
        (*__param_out)._d
    }

    ((*__param_out)._top = ((0 as i32)))

    while __local_tn {
        var __local_c: i32

        var __local__raw: i32 = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)).first as *const i32) as *mut i32))

        (__local_c = ((((if (*(&raw mut __param_rkey as *mut i32)) < (*(&raw const __local__raw as *const i32)): 1 else: 0) - (if (*(&raw const __local__raw as *const i32)) < (*(&raw mut __param_rkey as *mut i32)): 1 else: 0)) as i32)))

        if (__local_c < 0) {
            (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
        } else {
            if (__local_c > 0) {
                var __ci_expr_old_0: i32 = (*__param_out)._top

                ((*__param_out)._top = (*__param_out)._top + 1)

                ((*__param_out)._st[__ci_expr_old_0] = __local_tn)


                (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))

            } else {
                ((*__param_out)._tn = (((__local_d[__local_tn]).link[1] as i32)))

                ((*__param_out).ref = (((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)))

                return (*__param_out).ref


            }
        }


    }

    ((*__param_out).ref = ((null as *mut Intmap_value)))

    return (*__param_out).ref


}

unsafe fn Intmap_lower_bound(__param_self_: *const Intmap, __param_rkey: i32) -> Intmap_iter {
    var __local_it_: Intmap_iter

    Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter))

    var __ci_expr_logic_0: i32 = 0

    if ((*(&raw const __local_it_ as *const Intmap_iter)).ref == null) {
        (__ci_expr_logic_0 = (if (*(&raw const __local_it_ as *const Intmap_iter))._top != 0: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        var __local_tn: i32 = with 0 as __ci_expr_seq_11 {
            (__local_it_._top = (*(&raw const __local_it_ as *const Intmap_iter))._top - 1)
            ((*(&raw const __local_it_ as *const Intmap_iter))._st[(*(&raw const __local_it_ as *const Intmap_iter))._top] as i32)
        }

        (__local_it_._tn = ((((*(&raw const __local_it_ as *const Intmap_iter))._d[__local_tn]).link[1] as i32)))

        (__local_it_.ref = (((&raw const (__local_it_._d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)))

    }


    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn Intmap_front(__param_self_: *const Intmap) -> *mut Intmap_value {
    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while (__local_d[__local_tn]).link[0] {
        (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn Intmap_back(__param_self_: *const Intmap) -> *mut Intmap_value {
    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while (__local_d[__local_tn]).link[1] {
        (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value))

}

unsafe fn Intmap_erase(__param_self_: *mut Intmap, __param_rkey: i32) -> i32 {
    var __local_erased: i32 = ((0 as i32))

    var __local_root: i32 = ((Intmap_erase_r_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut i32) as *const i32), (&raw mut __local_erased as *mut i32)) as i32))

    if (__local_erased == 0) {
        return 0
    }

    ((*__param_self_).root = __local_root)

    ((*__param_self_).size = (*__param_self_).size - 1)

    return 1

}

unsafe fn Intmap_erase_at(__param_self_: *mut Intmap, __param_it_: Intmap_iter) -> Intmap_iter {
    var __local_raw: i32 = (*((&raw const (*(*(&raw const __param_it_ as *const Intmap_iter)).ref).first as *const i32) as *mut i32))

    Intmap_next((&raw mut __param_it_ as *mut Intmap_iter))

    if ((*(&raw const __param_it_ as *const Intmap_iter)).ref != null) {
        var __local_nxt: i32 = (*((&raw const (*(*(&raw const __param_it_ as *const Intmap_iter)).ref).first as *const i32) as *mut i32))

        Intmap_erase(__param_self_, __local_raw)

        Intmap_find_it((__param_self_ as *const Intmap), __local_nxt, (&raw mut __param_it_ as *mut Intmap_iter))

    } else {
        Intmap_erase(__param_self_, __local_raw)
    }

    return __param_it_

}

unsafe fn Intmap_erase_range(__param_self_: *mut Intmap, __param_it1: Intmap_iter, __param_it2: Intmap_iter) -> Intmap_iter {
    var __local_it1 = __param_it1
    if ((*(&raw const __param_it2 as *const Intmap_iter)).ref == null) {
        while ((*(&raw const __local_it1 as *const Intmap_iter)).ref != null) {
            let __ci_copy_21: Intmap_iter = Intmap_erase_at(__param_self_, __local_it1)
            with_memcpy((&raw mut __local_it1 as *mut u8), (&raw const __ci_copy_21 as *const u8), sizeof[Intmap_iter]())
        }

        return __local_it1

    }

    var __local_k1: i32 = (*((&raw const (*(*(&raw const __local_it1 as *const Intmap_iter)).ref).first as *const i32) as *mut i32))

    var __local_k2: i32 = (*((&raw const (*(*(&raw const __param_it2 as *const Intmap_iter)).ref).first as *const i32) as *mut i32))


    var __local_r1: i32 = (*(&raw mut __local_k1 as *mut i32))

    while true {
        if (with_memcmp((((&raw mut __local_k1 as *mut i32) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut i32) as *const c_void) as *const u8), ((sizeof[i32]() as u64) as i64)) == 0) {
            return __local_it1
        }

        Intmap_next((&raw mut __local_it1 as *mut Intmap_iter))

        (__local_k1 = (*((&raw const (*(*(&raw const __local_it1 as *const Intmap_iter)).ref).first as *const i32) as *mut i32)))

        Intmap_erase(__param_self_, __local_r1)

        (__local_r1 = (*(&raw mut __local_k1 as *mut i32)))

        Intmap_find_it((__param_self_ as *const Intmap), __local_r1, (&raw mut __local_it1 as *mut Intmap_iter))

    }

}

unsafe fn Intmap_begin(__param_self_: *const Intmap) -> Intmap_iter {
    var __local_it_: Intmap_iter

    (__local_it_.ref = ((null as *mut Intmap_value)))

    (__local_it_._d = (*__param_self_).nodes)

    (__local_it_._top = ((0 as i32)))


    (__local_it_._tn = (*__param_self_).root)

    if (*(&raw const __local_it_ as *const Intmap_iter))._tn {
        Intmap_next((&raw mut __local_it_ as *mut Intmap_iter))
    }

    return __local_it_

}

unsafe fn Intmap_next(__param_it_: *mut Intmap_iter) -> Unit {
    var __local_tn: i32 = (*__param_it_)._tn

    var __ci_expr_logic_0: i32

    if (*__param_it_)._top {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_tn: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        while __local_tn {
            var __ci_expr_old_1: i32 = (*__param_it_)._top

            ((*__param_it_)._top = (*__param_it_)._top + 1)

            ((*__param_it_)._st[__ci_expr_old_1] = __local_tn)


            (__local_tn = ((((*__param_it_)._d[__local_tn]).link[0] as i32)))

        }

        ((*__param_it_)._top = (*__param_it_)._top - 1)

        (__local_tn = (((*__param_it_)._st[(*__param_it_)._top] as i32)))


        ((*__param_it_)._tn = ((((*__param_it_)._d[__local_tn]).link[1] as i32)))

        ((*__param_it_).ref = (((&raw const ((*__param_it_)._d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)))

    } else {
        ((*__param_it_).ref = ((null as *mut Intmap_value)))
    }


}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Intmap_get(__param_self_: *const Intmap, __param_rkey: i32) -> *const Intmap_value {
    var __local_it_: Intmap_iter

    return ((Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) as *const Intmap_value))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Intmap_get_mut(__param_self_: *mut Intmap, __param_rkey: i32) -> *mut Intmap_value {
    var __local_it_: Intmap_iter

    return ((Intmap_find_it((__param_self_ as *const Intmap), __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) as *mut Intmap_value))

}

// contract: receiver:Intmap,unproved:1:read only
pub unsafe fn Intmap_value_drop(__param_self_: *const Intmap, __param_val: *mut Intmap_value) {
    return
}

// contract: receiver-mut:Intmap,unproved:1:read only
pub unsafe fn Intmap_copy(__param_self_: *mut Intmap, __param_other: *const Intmap) -> Unit {
    if (__param_self_ == __param_other) {
        return
    }

    Intmap_drop((__param_self_ as *const Intmap))

    let __ci_copy_16: Intmap = Intmap_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_16 as *const u8), sizeof[Intmap]())

}

unsafe fn Intmap_insert_entry_(__param_self_: *mut Intmap, __param_rkey: i32) -> Intmap_result {
    var __local_res: Intmap_result = Intmap_result.zeroed()

    var __local_tn: i32 = ((Intmap_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut i32) as *const i32), (&raw mut __local_res as *mut Intmap_result)) as i32))

    ((*__param_self_).root = __local_tn)

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const Intmap_result)).inserted as i32))

    return __local_res

}

unsafe fn Intmap_insert_or_assign(__param_self_: *mut Intmap, __param__key: i32, __param__mapped: i32) -> Intmap_result {
    var __local__res: Intmap_result = Intmap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut i32)))

    var __local__mp: *mut i32 = (if (*(&raw const __local__res as *const Intmap_result)).ref != null: ((&raw const (*(*(&raw const __local__res as *const Intmap_result)).ref).second as *const i32) as *mut i32) else: (&raw mut __param__mapped as *mut i32))

    if (*(&raw const __local__res as *const Intmap_result)).inserted {
        ((*(*(&raw const __local__res as *const Intmap_result)).ref).first = __param__key)
    } else {


    }

    ((*__local__mp) = __param__mapped)

    return __local__res

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Intmap_at(__param_self_: *const Intmap, __param_rkey: i32) -> *const i32 {
    var __local_it_: Intmap_iter

    return ((((&raw const Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)).second as *const i32) as *mut i32) as *const i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Intmap_at_mut(__param_self_: *mut Intmap, __param_rkey: i32) -> *mut i32 {
    var __local_it_: Intmap_iter

    return (((&raw const Intmap_find_it((__param_self_ as *const Intmap), __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)).second as *const i32) as *mut i32))

}

pub fn Intmap_advance(__param_it_: Intmap_iter, __param_n: u64) -> Intmap_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if __ci_expr_old_0 {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const Intmap_iter)).ref != null: 1 else: 0))
        }

        if (not __ci_expr_logic_1) {
            break
        }

        unsafe { Intmap_next((&raw mut __param_it_ as *mut Intmap_iter)) }

    }

    return __param_it_

}

// contract: receiver:Intmap,unproved:1:read only
pub unsafe fn Intmap_eq(__param_self_: *const Intmap, __param_other: *const Intmap) -> bool {
    if ((*__param_self_).size() != (*__param_other).size()) {
        return ((false as bool))
    }

    var __local_i: Intmap_iter = Intmap_begin(__param_self_)

    var __local_j: Intmap_iter = Intmap_begin(__param_other)


    while ((*(&raw const __local_i as *const Intmap_iter)).ref != null) {
        var __local__rx: i32 = (*((&raw const (*(*(&raw const __local_i as *const Intmap_iter)).ref).first as *const i32) as *mut i32))

        var __local__ry: i32 = (*((&raw const (*(*(&raw const __local_j as *const Intmap_iter)).ref).first as *const i32) as *mut i32))


        if (not ((*(&raw const __local__rx as *const i32)) == (*(&raw const __local__ry as *const i32)))) {
            return ((false as bool))
        }


        Intmap_next((&raw mut __local_i as *mut Intmap_iter))

        Intmap_next((&raw mut __local_j as *mut Intmap_iter))


    }

    return ((true as bool))

}

// contract: receiver-mut:Intmap,unproved:1:read only
pub unsafe fn Intmap_put_n(__param_self_: *mut Intmap, __param_raw: *const Intmap_raw, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not __ci_expr_old_0) {
            break
        }

        (*__param_self_).put((*__local_raw).first, (*__local_raw).second)

        (__local_raw = __local_raw + 1)

    }

}

pub fn Intmap_init() -> Intmap {
    var __local_cx: Intmap = Intmap.zeroed()

    return __local_cx

}

// contract: unproved:0:Intmap_put_n may write through it
pub unsafe fn Intmap_from_n(__param_raw: *const Intmap_raw, __param_n: i64) -> Intmap {
    var __local_cx: Intmap = Intmap.zeroed()

    Intmap_put_n((&raw mut __local_cx as *mut Intmap), __param_raw, __param_n)

    return __local_cx

}

pub fn Intmap_with_capacity(__param_cap: i64) -> Intmap {
    var __local_cx: Intmap = Intmap.zeroed()

    unsafe { Intmap_reserve((&raw mut __local_cx as *mut Intmap), __param_cap) }

    return __local_cx

}

unsafe fn Intmap_new_node_(__param_self_: *mut Intmap, __param_level: i32) -> i32 {
    var __local_tn: i32

    if ((*__param_self_).disp != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as i32)))

    } else {
        if ((*__param_self_).head == (*__param_self_).capacity) {
            if (not Intmap_reserve(__param_self_, (((((*__param_self_).head * 3) / 2) + 4) as i64))) {
                return 0
            }
        }

        ((*__param_self_).head = (*__param_self_).head + 1)

        (__local_tn = (*__param_self_).head)


    }

    var __local_dn: *mut Intmap_node = (((&raw const ((*__param_self_).nodes[__local_tn]) as *const Intmap_node) as *mut Intmap_node))

    ((*__local_dn).link[1] = ((0 as i32)))

    ((*__local_dn).link[0] = (((*__local_dn).link[1] as i32)))


    ((*__local_dn).level = ((__param_level as i8)))

    return __local_tn

}

// contract: unproved:0:indexed as an array
unsafe fn Intmap_skew_(__param_d: *mut Intmap_node, __param_tn: i32) -> i32 {
    var __local_tn = __param_tn
    var __ci_expr_logic_0: i32 = 0

    if (__local_tn != 0) {
        (__ci_expr_logic_0 = (if (__param_d[(__param_d[__local_tn]).link[0]]).level == (__param_d[__local_tn]).level: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        var __local_tmp: i32 = (((__param_d[__local_tn]).link[0] as i32))

        ((__param_d[__local_tn]).link[0] = (((__param_d[__local_tmp]).link[1] as i32)))

        ((__param_d[__local_tmp]).link[1] = __local_tn)

        (__local_tn = __local_tmp)

    }


    return __local_tn

}

// contract: unproved:0:indexed as an array
unsafe fn Intmap_split_(__param_d: *mut Intmap_node, __param_tn: i32) -> i32 {
    var __local_tn = __param_tn
    if ((__param_d[(__param_d[(__param_d[__local_tn]).link[1]]).link[1]]).level == (__param_d[__local_tn]).level) {
        var __local_tmp: i32 = (((__param_d[__local_tn]).link[1] as i32))

        ((__param_d[__local_tn]).link[1] = (((__param_d[__local_tmp]).link[0] as i32)))

        ((__param_d[__local_tmp]).link[0] = __local_tn)

        (__local_tn = __local_tmp)

        ((__param_d[__local_tn]).level = (__param_d[__local_tn]).level + 1)

    }

    return __local_tn

}

// contract: receiver-mut:Intmap,unproved:2:read only,unproved:3:out-parameter written conditionally
unsafe fn Intmap_insert_entry_i_(__param_self_: *mut Intmap, __param_tn: i32, __param_rkey: *const i32, __param__res: *mut Intmap_result) -> i32 {
    var __local_up: List[i32] = [0; 64]

    var __local_tx: i32 = __param_tn


    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    var __local_c: i32

    var __local_top: i32 = ((0 as i32))

    var __local_dir: i32 = ((0 as i32))


    while __local_tx {
        var __ci_expr_old_0: i32 = __local_top

        (__local_top = __local_top + 1)

        (__local_up[__ci_expr_old_0] = __local_tx)


        var __local__raw: i32 = (*((&raw const (*((&raw const (__local_d[__local_tx]).value as *const Intmap_value) as *mut Intmap_value)).first as *const i32) as *mut i32))

        (__local_c = ((((if (*__param_rkey) < (*(&raw const __local__raw as *const i32)): 1 else: 0) - (if (*(&raw const __local__raw as *const i32)) < (*__param_rkey): 1 else: 0)) as i32)))

        if (__local_c == 0) {
            ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Intmap_value) as *mut Intmap_value)))

            return __param_tn

        }


        (__local_dir = (((if __local_c < 0: 1 else: 0) as i32)))

        (__local_tx = (((__local_d[__local_tx]).link[__local_dir] as i32)))

    }

    (__local_tx = ((Intmap_new_node_(__param_self_, (1 as i32)) as i32)))

    if (__local_tx == 0) {
        return 0
    }


    (__local_d = (*__param_self_).nodes)

    ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const Intmap_value) as *mut Intmap_value)))

    ((*__param__res).inserted = true)

    if (__local_top == 0) {
        return __local_tx
    }

    ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = __local_tx)

    while true {
        var __ci_expr_old_1: i32 = __local_top

        (__local_top = __local_top - 1)

        if (not __ci_expr_old_1) {
            break
        }

        if (__local_top != 0) {
            (__local_dir = (((if (__local_d[__local_up[(__local_top - 1)]]).link[1] == __local_up[__local_top]: 1 else: 0) as i32)))
        }

        (__local_up[__local_top] = ((Intmap_skew_(__local_d, (__local_up[__local_top] as i32)) as i32)))

        (__local_up[__local_top] = ((Intmap_split_(__local_d, (__local_up[__local_top] as i32)) as i32)))

        if __local_top {
            ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = ((__local_up[__local_top] as i32)))
        }

    }

    return __local_up[0]

}

// contract: receiver-mut:Intmap,unproved:2:read only,unproved:3:out-parameter a return before the write
unsafe fn Intmap_erase_r_(__param_self_: *mut Intmap, __param_tn: i32, __param_rkey: *const i32, __param_erased: *mut i32) -> i32 {
    var __local_tn = __param_tn
    var __local_d: *mut Intmap_node = (*__param_self_).nodes

    if (__local_tn == 0) {
        return 0
    }

    var __local_raw: i32 = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)).first as *const i32) as *mut i32))

    var __local_tx: i32

    var __local_c: i32 = ((((if (*__param_rkey) < (*(&raw mut __local_raw as *mut i32)): 1 else: 0) - (if (*(&raw mut __local_raw as *mut i32)) < (*__param_rkey): 1 else: 0)) as i32))

    if (__local_c != 0) {
        ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] = ((Intmap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] as i32), __param_rkey, __param_erased) as i32)))
    } else {
        var __ci_expr_old_0: i32 = (*__param_erased)

        ((*__param_erased) = (*__param_erased) + 1)

        if (__ci_expr_old_0 == 0) {
            Intmap_value_drop((__param_self_ as *const Intmap), ((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value))
        }


        var __ci_expr_logic_1: i32 = 0

        if (__local_d[__local_tn]).link[0] {
            (__ci_expr_logic_1 = (if (__local_d[__local_tn]).link[1]: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            (__local_tx = (((__local_d[__local_tn]).link[0] as i32)))

            while (__local_d[__local_tx]).link[1] {
                (__local_tx = (((__local_d[__local_tx]).link[1] as i32)))
            }

            with_memcpy((&raw mut (__local_d[__local_tn]).value as *mut u8), (&raw const (__local_d[__local_tx]).value as *const u8), sizeof[Intmap_value]())

            (__local_raw = (*((&raw const (*((&raw const (__local_d[__local_tn]).value as *const Intmap_value) as *mut Intmap_value)).first as *const i32) as *mut i32)))

            ((__local_d[__local_tn]).link[0] = ((Intmap_erase_r_(__param_self_, ((__local_d[__local_tn]).link[0] as i32), ((&raw mut __local_raw as *mut i32) as *const i32), __param_erased) as i32)))

        } else {
            (__local_tx = __local_tn)

            (__local_tn = (((__local_d[__local_tn]).link[(if (__local_d[__local_tn]).link[0] == 0: 1 else: 0)] as i32)))

            ((__local_d[__local_tx]).link[1] = (*__param_self_).disp)

            ((*__param_self_).disp = __local_tx)

        }


    }

    (__local_tx = (((__local_d[__local_tn]).link[1] as i32)))

    var __ci_expr_logic_2: i32

    if ((__local_d[(__local_d[__local_tn]).link[0]]).level < (((__local_d[__local_tn]).level as i32) - 1)) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (__local_d[__local_tx]).level < (((__local_d[__local_tn]).level as i32) - 1): 1 else: 0))
    }

    if __ci_expr_logic_2 {
        ((__local_d[__local_tn]).level = (__local_d[__local_tn]).level - 1)

        if ((__local_d[__local_tx]).level > (__local_d[__local_tn]).level) {
            ((__local_d[__local_tx]).level = (__local_d[__local_tn]).level)
        }


        (__local_tn = ((Intmap_skew_(__local_d, __local_tn) as i32)))

        ((__local_d[__local_tn]).link[1] = ((Intmap_skew_(__local_d, ((__local_d[__local_tn]).link[1] as i32)) as i32)))

        (__local_tx = (((__local_d[__local_tn]).link[1] as i32)))


        ((__local_d[__local_tx]).link[1] = ((Intmap_skew_(__local_d, ((__local_d[__local_tx]).link[1] as i32)) as i32)))

        (__local_tn = ((Intmap_split_(__local_d, __local_tn) as i32)))

        ((__local_d[__local_tn]).link[1] = ((Intmap_split_(__local_d, ((__local_d[__local_tn]).link[1] as i32)) as i32)))

    }


    return __local_tn

}

// contract: receiver-mut:Intmap,unproved:1:read only
unsafe fn Intmap_clone_r_(__param_self_: *mut Intmap, __param_src: *mut Intmap_node, __param_sn: i32) -> i32 {
    if (__param_sn == 0) {
        return 0
    }

    var __local_tx: i32

    var __local_tn: i32 = ((Intmap_new_node_(__param_self_, ((__param_src[__param_sn]).level as i32)) as i32))


    let __ci_copy_31: Intmap_value = (*(__param_self_ as *const Intmap)).value_clone((__param_src[__param_sn]).value)
    with_memcpy((&raw mut ((*__param_self_).nodes[__local_tn]).value as *mut u8), (&raw const __ci_copy_31 as *const u8), sizeof[Intmap_value]())

    (__local_tx = ((Intmap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[0] as i32)) as i32)))

    (((*__param_self_).nodes[__local_tn]).link[0] = __local_tx)

    (__local_tx = ((Intmap_clone_r_(__param_self_, __param_src, ((__param_src[__param_sn]).link[1] as i32)) as i32)))

    (((*__param_self_).nodes[__local_tn]).link[1] = __local_tx)

    return __local_tn

}

unsafe fn Intmap_drop_r_(__param_s: *mut Intmap, __param_tn: i32) -> Unit {
    if (__param_tn != 0) {
        Intmap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[0] as i32))

        Intmap_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[1] as i32))

        Intmap_value_drop((__param_s as *const Intmap), ((&raw const ((*__param_s).nodes[__param_tn]).value as *const Intmap_value) as *mut Intmap_value))

    }

}

// contract: unproved:0:casts away const
unsafe fn Pairvec_drop(__param_cself: *const Pairvec) {
    var __local_self_: *mut Pairvec = ((__param_cself as *mut Pairvec))

    if ((*__local_self_).data == null) {
        return
    }

    Pairvec_clear(__local_self_)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

unsafe fn Pairvec_clear(__param_self_: *mut Pairvec) {
    var __local_i: i64 = (*__param_self_).size

    while true {
        var __ci_expr_old_0: i64 = __local_i

        (__local_i = __local_i - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

    }

    ((*__param_self_).size = ((0 as i64)))

}

unsafe fn Pairvec_reserve(__param_self_: *mut Pairvec, __param_cap: i64) -> bool {
    var __local_n: i64 = (((if __param_cap == 9223372036854775807: (*__param_self_).size else: __param_cap) as i64))

    if (((if __param_cap > (*__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as i32)) {
        var __local_d: *mut Intmap_raw = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if true: ((if true: ((__local_n * (sizeof[Intmap_raw]() as i64)) as i64) else: (((*__param_self_).capacity * (sizeof[Intmap_raw]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Intmap_raw))

        if (__local_d == null) {
            return ((false as bool))
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((((*__param_self_).data != null)) as bool))

}

unsafe fn Pairvec_resize(__param_self_: *mut Pairvec, __param_len: i64, __param_null_: Intmap_raw) -> bool {
    if (not Pairvec_reserve(__param_self_, __param_len)) {
        return ((false as bool))
    }

    var __local_n: i64 = (*__param_self_).size

    var __local_i: i64 = __param_len

    while (__local_i < __local_n) {


        (__local_i = __local_i + 1)

    }


    var __local_i_1: i64 = __local_n

    while (__local_i_1 < __param_len) {
        (((*__param_self_).data[__local_i_1]) = __param_null_)

        (__local_i_1 = __local_i_1 + 1)

    }


    ((*__param_self_).size = __param_len)

    return ((true as bool))

}

unsafe fn Pairvec_erase_n(__param_self_: *mut Pairvec, __param_idx: i64, __param_len: i64) -> Pairvec_iter {
    if ((if not ((__param_idx + __param_len) <= (*__param_self_).size): 1 else: 0) as i64) {
        __assert_rtn(c"Pairvec_erase_n".ptr, c"vec.h".ptr, (337 as i32), c"idx + len <= self->size".ptr)
    } else {
        0
    }

    var __local_d: *mut Intmap_raw = ((*__param_self_).data + ((__param_idx as i64) as usize))

    var __local_p: *mut Intmap_raw = __local_d

    var __local_end: *mut Intmap_raw = ((*__param_self_).data + (((*__param_self_).size as i64) as usize))


    var __local_i: i64 = ((0 as i64))

    while (__local_i < __param_len) {


        (__local_i = __local_i + 1)

        (__local_p = __local_p + 1)


    }


    with_memmove(((__local_d as *mut c_void) as *mut u8), ((__local_p as *const c_void) as *const u8), ((((((((__local_end as usize) -% (__local_p as usize)) as i64) / (sizeof[Intmap_raw]() as i64)) as u64) *% (sizeof[Intmap_raw]() as u64)) as u64) as i64))

    ((*__param_self_).size = (*__param_self_).size - __param_len)

    return ((Pairvec_iter { ref: (if __local_p == __local_end: ((null) as *mut Intmap_raw) else: __local_d), end: (__local_end - ((__param_len as i64) as usize)) } as Pairvec_iter))

}

unsafe fn Pairvec_insert_uninit(__param_self_: *mut Pairvec, __param_idx: i64, __param_n: i64) -> Pairvec_iter {
    if (((*__param_self_).size + __param_n) >= (*__param_self_).capacity) {
        if (not Pairvec_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + __param_n) as i64))) {
            return (*(__param_self_ as *const Pairvec)).end()
        }
    }

    var __local_pos: *mut Intmap_raw = ((*__param_self_).data + ((__param_idx as i64) as usize))

    with_memmove((((__local_pos + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), ((__local_pos as *const c_void) as *const u8), (((if true: ((((*__param_self_).size - __param_idx) * (sizeof[Intmap_raw]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((Pairvec_iter { ref: __local_pos, end: ((*__param_self_).data + (((*__param_self_).size as i64) as usize)) } as Pairvec_iter))

}

// contract: receiver:Pairvec,unproved:1:read only
pub unsafe fn Pairvec_value_drop(__param_self_: *const Pairvec, __param_val: *mut Intmap_raw) {
    return
}

// contract: receiver-mut:Pairvec,unproved:1:read only
pub unsafe fn Pairvec_put_n(__param_self_: *mut Pairvec, __param_raw: *const Intmap_raw, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not __ci_expr_old_0) {
            break
        }

        (*__param_self_).push((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: receiver-mut:Pairvec,unproved:1:read only
unsafe fn Pairvec_copy(__param_self_: *mut Pairvec, __param_other: *const Pairvec) {
    if (__param_self_ == __param_other) {
        return
    }

    Pairvec_clear(__param_self_)

    Pairvec_reserve(__param_self_, (*__param_other).size)

    ((*__param_self_).size = (*__param_other).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (*__param_other).size


    while (__local_i < __local__c_end_i) {
        (((*__param_self_).data[__local_i]) = ((*__param_other).data[__local_i]))

        (__local_i = __local_i + 1)

    }


}

// contract: receiver-mut:Pairvec,unproved:2:read only
unsafe fn Pairvec_copy_to(__param_self_: *mut Pairvec, __param_idx: i64, __param_arr: *mut Intmap_raw, __param_n: i64) -> Pairvec_iter {
    var __local_arr = __param_arr
    var __local_it_: Pairvec_iter = Pairvec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const Pairvec_iter)).ref != null) {
        var __local_p: *mut Intmap_raw = (*(&raw const __local_it_ as *const Pairvec_iter)).ref

        var __local_q: *mut Intmap_raw = (__local_p + ((__param_n as i64) as usize))


        while (__local_p != __local_q) {
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

    (__local_out.capacity = ((0 as i64)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Pairvec)).capacity)


    unsafe { Pairvec_reserve((&raw mut __local_out as *mut Pairvec), (*(&raw const __param_vec as *const Pairvec)).size) }

    (__local_out.size = (unsafe *(&raw const __param_vec as *const Pairvec)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_vec as *const Pairvec)).size


    while (__local_i < __local__c_end_i) {
        ((unsafe __local_out.data[__local_i]) = (unsafe (*(&raw const __param_vec as *const Pairvec)).data[__local_i]))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Pairvec_front(__param_self_: *const Pairvec) -> *const Intmap_raw {
    return (((*__param_self_).data as *const Intmap_raw))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Pairvec_front_mut(__param_self_: *mut Pairvec) -> *mut Intmap_raw {
    return (*__param_self_).data

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Pairvec_back(__param_self_: *const Pairvec) -> *const Intmap_raw {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const Intmap_raw) as *mut Intmap_raw) as *const Intmap_raw))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Pairvec_back_mut(__param_self_: *mut Pairvec) -> *mut Intmap_raw {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const Intmap_raw) as *mut Intmap_raw))

}

pub fn Pairvec_init() -> Pairvec {
    return ((Pairvec.zeroed() as Pairvec))

}

pub fn Pairvec_with_capacity(__param_cap: i64) -> Pairvec {
    var __local_out: Pairvec = Pairvec { data: (((with_alloc((((if true: ((__param_cap * (sizeof[Intmap_raw]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Intmap_raw)), size: 0, capacity: __param_cap }

    return __local_out

}

pub fn Pairvec_with_size_uninit(__param_size: i64) -> Pairvec {
    var __local_out: Pairvec = Pairvec { data: (((with_alloc((((if true: ((__param_size * (sizeof[Intmap_raw]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Intmap_raw)), size: __param_size, capacity: __param_size }

    return __local_out

}

pub fn Pairvec_with_size(__param_size: i64, __param_default_raw: Intmap_raw) -> Pairvec {
    var __local_size = __param_size
    var __local_out: Pairvec = Pairvec { data: (((with_alloc((((if true: ((__local_size * (sizeof[Intmap_raw]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Intmap_raw)), size: __local_size, capacity: __local_size }

    while __local_size {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

// contract: receiver-mut:Pairvec,unproved:2:read only
pub unsafe fn Pairvec_insert_n(__param_self_: *mut Pairvec, __param_idx: i64, __param_arr: *mut Intmap_raw, __param_n: i64) -> Pairvec_iter {
    var __local_it_: Pairvec_iter = Pairvec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const Pairvec_iter)).ref != null) {
        with_memcpy((((*(&raw const __local_it_ as *const Pairvec_iter)).ref as *mut c_void) as *mut u8), ((&(__param_arr[0]) as *mut Intmap_raw) as *const u8), (((if true: ((__param_n * (sizeof[Intmap_raw]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
    }

    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Pairvec_at(__param_self_: *const Pairvec, __param_idx: i64) -> *const Intmap_raw {
    if ((if not (((__param_idx as u64)) < (((*__param_self_).size as u64))): 1 else: 0) as i64) {
        __assert_rtn(c"Pairvec_at".ptr, c"vec.h".ptr, (206 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const Intmap_raw))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn Pairvec_at_mut(__param_self_: *mut Pairvec, __param_idx: i64) -> *mut Intmap_raw {
    if ((if not (((__param_idx as u64)) < (((*__param_self_).size as u64))): 1 else: 0) as i64) {
        __assert_rtn(c"Pairvec_at_mut".ptr, c"vec.h".ptr, (210 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((*__param_self_).data + ((__param_idx as i64) as usize))

}

pub fn Pairvec_advance(__param_it_: Pairvec_iter, __param_n: u64) -> Pairvec_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const Pairvec_iter)).ref + (__param_n as usize))

    if ((unsafe *(&raw const __param_it_ as *const Pairvec_iter)).ref >= (unsafe *(&raw const __param_it_ as *const Pairvec_iter)).end) {
        (__param_it_.ref = ((null as *mut Intmap_raw)))
    }


    return __param_it_

}

@[repr(C)]
pub type ctest_sortedmap_insert_run__c_i2_anon { _ref: *const *mut Intmap = null, ref: *mut *mut Intmap = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_sortedmap_insert_run__c_i2_anon
@[repr(C)]
pub type ctest_sortedmap_insert_run__c_i2_anon_2 { _ref: *const *mut Mymap = null, ref: *mut *mut Mymap = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_sortedmap_insert_run__c_i2_anon_2
@[repr(C)]
pub type ctest_sortedmap_insert_run__c_i2_anon_3 { _ref: *const *mut Pairvec = null, ref: *mut *mut Pairvec = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_sortedmap_insert_run__c_i2_anon_3
fn ctest_sortedmap_insert_run() {
    var __local_m1: Intmap = Intmap.zeroed()

    var __local_res: Intmap = Intmap.zeroed()

    unsafe { (*(&raw mut __local_m1 as *mut Intmap)).insert((1 as i32), (10 as i32)) }

    unsafe { (*(&raw mut __local_m1 as *mut Intmap)).push((Intmap_value { first: 2, second: 20 } as Intmap_value)) }

    var __ci_expr_lit_0: [Intmap_raw; 2] = [Intmap_raw { first: 1, second: 10 }, Intmap_raw { first: 2, second: 20 }]

    unsafe { (*(&raw mut __local_res as *mut Intmap)).take(unsafe { Intmap_from_n((&__ci_expr_lit_0[0] as *mut Intmap_raw), (([Intmap_raw { first: 1, second: 10 }, Intmap_raw { first: 2, second: 20 }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Intmap_eq(((&raw mut __local_res as *mut Intmap) as *const Intmap), ((&raw mut __local_m1 as *mut Intmap) as *const Intmap)) } as bool), c"smap_test.c".ptr, (97 as i32))

    var __local_ret: Intmap_result = unsafe { (*(&raw mut __local_m1 as *mut Intmap)).insert((1 as i32), (111 as i32)) }

    assert_bool((1 as i32), (false as bool), (unsafe *(&raw const __local_ret as *const Intmap_result)).inserted, c"smap_test.c".ptr, (101 as i32))

    unsafe { (*(&raw mut __local_m1 as *mut Intmap)).insert((3 as i32), (30 as i32)) }

    var __ci_expr_lit_1: [Intmap_raw; 3] = [Intmap_raw { first: 1, second: 10 }, Intmap_raw { first: 2, second: 20 }, Intmap_raw { first: 3, second: 30 }]

    unsafe { (*(&raw mut __local_res as *mut Intmap)).take(unsafe { Intmap_from_n((&__ci_expr_lit_1[0] as *mut Intmap_raw), (([Intmap_raw { first: 1, second: 10 }, Intmap_raw { first: 2, second: 20 }, Intmap_raw { first: 3, second: 30 }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Intmap_eq(((&raw mut __local_res as *mut Intmap) as *const Intmap), ((&raw mut __local_m1 as *mut Intmap) as *const Intmap)) } as bool), c"smap_test.c".ptr, (106 as i32))

    var __local_m2: Intmap = Intmap.zeroed()

    var __local_v: Pairvec = Pairvec.zeroed()

    unsafe { (*(&raw mut __local_v as *mut Pairvec)).push((Intmap_raw { first: 43, second: 294 } as Intmap_raw)) }

    unsafe { (*(&raw mut __local_v as *mut Pairvec)).push((Intmap_raw { first: 41, second: 262 } as Intmap_raw)) }

    unsafe { (*(&raw mut __local_v as *mut Pairvec)).push((Intmap_raw { first: 45, second: 330 } as Intmap_raw)) }

    unsafe { (*(&raw mut __local_v as *mut Pairvec)).push((Intmap_raw { first: 42, second: 277 } as Intmap_raw)) }

    unsafe { (*(&raw mut __local_v as *mut Pairvec)).push((Intmap_raw { first: 44, second: 311 } as Intmap_raw)) }

    unsafe { Intmap_put_n((&raw mut __local_m2 as *mut Intmap), ((*(&raw const __local_v as *const Pairvec)).data as *const Intmap_raw), (unsafe { (*((&raw mut __local_v as *mut Pairvec) as *const Pairvec)).size() } as i64)) }

    var __ci_expr_lit_2: [Intmap_raw; 5] = [Intmap_raw { first: 41, second: 262 }, Intmap_raw { first: 42, second: 277 }, Intmap_raw { first: 43, second: 294 }, Intmap_raw { first: 44, second: 311 }, Intmap_raw { first: 45, second: 330 }]

    unsafe { (*(&raw mut __local_res as *mut Intmap)).take(unsafe { Intmap_from_n((&__ci_expr_lit_2[0] as *mut Intmap_raw), (([Intmap_raw { first: 41, second: 262 }, Intmap_raw { first: 42, second: 277 }, Intmap_raw { first: 43, second: 294 }, Intmap_raw { first: 44, second: 311 }, Intmap_raw { first: 45, second: 330 }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Intmap_eq(((&raw mut __local_res as *mut Intmap) as *const Intmap), ((&raw mut __local_m2 as *mut Intmap) as *const Intmap)) } as bool), c"smap_test.c".ptr, (122 as i32))

    var __local_m3: Mymap = Mymap.zeroed()

    var __local_res3: Mymap = Mymap.zeroed()

    var __local_ip1: Mymap_value = Mymap_value { first: 475, second: unsafe { cstr_from_n(c"blue".ptr, ((((5 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) } }

    var __local_ip2: Mymap_value = Mymap_value { first: 510, second: unsafe { cstr_from_n(c"green".ptr, ((((6 * (sizeof[c_char]() as usize)) as i64) - 1) as i64)) } }


    unsafe { (*(&raw mut __local_m3 as *mut Mymap)).insert((*(&raw const __local_ip1 as *const Mymap_value)).first, unsafe { cstr_move(((&raw const (*(&raw const __local_ip1 as *const Mymap_value)).second as *const cstr) as *mut cstr)) }) }

    var __ci_expr_lit_3: [Mymap_raw; 1] = [Mymap_raw { first: 475, second: (("blue" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res3 as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_3[0] as *mut Mymap_raw), (([Mymap_raw { first: 475, second: (("blue" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res3 as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (134 as i32))

    unsafe { (*(&raw mut __local_m3 as *mut Mymap)).insert((*(&raw const __local_ip2 as *const Mymap_value)).first, unsafe { cstr_move(((&raw const (*(&raw const __local_ip2 as *const Mymap_value)).second as *const cstr) as *mut cstr)) }) }

    var __ci_expr_lit_4: [Mymap_raw; 2] = [Mymap_raw { first: 475, second: (("blue" as *mut c_char) as *const c_char) }, Mymap_raw { first: 510, second: (("green" as *mut c_char) as *const c_char) }]

    unsafe { (*(&raw mut __local_res3 as *mut Mymap)).take(unsafe { Mymap_from_n((&__ci_expr_lit_4[0] as *mut Mymap_raw), (([Mymap_raw { first: 475, second: (("blue" as *mut c_char) as *const c_char) }, Mymap_raw { first: 510, second: (("green" as *mut c_char) as *const c_char) }].len() as u64) as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { Mymap_eq(((&raw mut __local_res3 as *mut Mymap) as *const Mymap), ((&raw mut __local_m3 as *mut Mymap) as *const Mymap)) } as bool), c"smap_test.c".ptr, (140 as i32))

    loop {
        var __local__c_i2: ctest_sortedmap_insert_run__c_i2_anon = ctest_sortedmap_insert_run__c_i2_anon.zeroed()

        var __ci_expr_lit_5: [*mut Intmap; 3] = [(&raw mut __local_m1 as *mut Intmap), (&raw mut __local_m2 as *mut Intmap), (&raw mut __local_res as *mut Intmap)]

        __local__c_i2 = ctest_sortedmap_insert_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_5)[0] as *mut *mut Intmap) as *const *mut Intmap)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon))._ref as *mut *mut Intmap)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as u64) / (sizeof[Intmap]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).size) {
            unsafe { Intmap_drop(((*((*(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).ref)) as *const Intmap)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_sortedmap_insert_run__c_i2_anon)).index + 1)


        }


        if not (false) {
            break
        }
    }

    loop {
        var __local__c_i2_1: ctest_sortedmap_insert_run__c_i2_anon_2 = ctest_sortedmap_insert_run__c_i2_anon_2.zeroed()

        var __ci_expr_lit_6: [*mut Mymap; 2] = [(&raw mut __local_m3 as *mut Mymap), (&raw mut __local_res3 as *mut Mymap)]

        __local__c_i2_1 = ctest_sortedmap_insert_run__c_i2_anon_2.zeroed()
        __local__c_i2_1._ref = ((&raw const (__ci_expr_lit_6)[0] as *mut *mut Mymap) as *const *mut Mymap)
        __local__c_i2_1.ref = ((unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2))._ref as *mut *mut Mymap)
        __local__c_i2_1.size = (((((2 * (sizeof[usize]() as usize)) as u64) / (sizeof[Mymap]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).index < (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).size) {
            unsafe { Mymap_drop(((*((*(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).ref)) as *const Mymap)) }

            (__local__c_i2_1.ref = (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).ref + 1)

            (__local__c_i2_1.index = (unsafe *(&raw const __local__c_i2_1 as *const ctest_sortedmap_insert_run__c_i2_anon_2)).index + 1)


        }


        if not (false) {
            break
        }
    }

    loop {
        var __local__c_i2_2: ctest_sortedmap_insert_run__c_i2_anon_3 = ctest_sortedmap_insert_run__c_i2_anon_3.zeroed()

        var __ci_expr_lit_7: [*mut Pairvec; 1] = [(&raw mut __local_v as *mut Pairvec)]

        __local__c_i2_2 = ctest_sortedmap_insert_run__c_i2_anon_3.zeroed()
        __local__c_i2_2._ref = ((&raw const (__ci_expr_lit_7)[0] as *mut *mut Pairvec) as *const *mut Pairvec)
        __local__c_i2_2.ref = ((unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3))._ref as *mut *mut Pairvec)
        __local__c_i2_2.size = (((((1 * (sizeof[usize]() as usize)) as u64) / (sizeof[Pairvec]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).index < (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).size) {
            unsafe { Pairvec_drop(((*((*(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).ref)) as *const Pairvec)) }

            (__local__c_i2_2.ref = (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).ref + 1)

            (__local__c_i2_2.index = (unsafe *(&raw const __local__c_i2_2 as *const ctest_sortedmap_insert_run__c_i2_anon_3)).index + 1)


        }


        if not (false) {
            break
        }
    }

}

impl Intmap {
    pub fn is_empty() -> bool {
        let __param_self_: *const Intmap = self as *const Intmap
        return (((((unsafe *__param_self_).size == 0)) as bool))

    }

    pub fn size() -> i64 {
        let __param_self_: *const Intmap = self as *const Intmap
        return (((unsafe *__param_self_).size as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const Intmap = self as *const Intmap
        return (((unsafe *__param_self_).capacity as i64))

    }

    pub fn find(__param_rkey: i32) -> Intmap_iter {
        let __param_self_: *const Intmap = self as *const Intmap
        var __local_it_: Intmap_iter

        unsafe { Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) }

        return __local_it_

    }

    pub fn contains(__param_rkey: i32) -> bool {
        let __param_self_: *const Intmap = self as *const Intmap
        var __local_it_: Intmap_iter

        return ((((unsafe { Intmap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Intmap_iter)) } != null)) as bool))

    }

    pub mut fn move_() -> Intmap {
        let __param_self_: *mut Intmap = self as *mut Intmap
        var __local_m: Intmap = (unsafe *__param_self_)

        ((unsafe *__param_self_).head = ((0 as i32)))

        ((unsafe *__param_self_).disp = (unsafe *__param_self_).head)

        ((unsafe *__param_self_).root = (unsafe *__param_self_).disp)

        ((unsafe *__param_self_).size = (unsafe *__param_self_).root)

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).nodes = ((null as *mut Intmap_node)))

        return __local_m

    }

    pub mut fn clear() -> Unit {
        let __param_self_: *mut Intmap = self as *mut Intmap
        unsafe { Intmap_drop((__param_self_ as *const Intmap)) }

        unsafe { (*__param_self_).move_() }

    }

    pub mut fn take(__param_unowned: Intmap) -> Unit {
        let __param_self_: *mut Intmap = self as *mut Intmap
        unsafe { Intmap_drop((__param_self_ as *const Intmap)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Intmap]())

    }

    pub fn value_clone(__param__val: Intmap_value) -> Intmap_value {
        let __param_self_: *const Intmap = self as *const Intmap

        ((unsafe *((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const i32) as *mut i32)) = (unsafe *((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const i32) as *mut i32)))

        (__param__val.second = (unsafe *(&raw const __param__val as *const Intmap_value)).second)

        return __param__val

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut Intmap = self as *mut Intmap
        if ((unsafe *__param_self_).size == (unsafe *__param_self_).capacity) {
            return
        }

        var __local_tmp: Intmap = Intmap_clone((unsafe *__param_self_))

        unsafe { Intmap_drop((__param_self_ as *const Intmap)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __local_tmp as *const u8), sizeof[Intmap]())

    }

    pub fn end() -> Intmap_iter {
        let __param_self_: *const Intmap = self as *const Intmap
        var __local_it_: Intmap_iter


        (__local_it_.ref = ((null as *mut Intmap_value)))

        (__local_it_._top = ((0 as i32)))

        (__local_it_._tn = ((0 as i32)))


        return __local_it_

    }

    pub mut fn insert(__param__key: i32, __param__mapped: i32) -> Intmap_result {
        let __param_self_: *mut Intmap = self as *mut Intmap
        var __local__res: Intmap_result = unsafe { Intmap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut i32))) }

        if (unsafe *(&raw const __local__res as *const Intmap_result)).inserted {
            ((unsafe *((&raw const (*(*(&raw const __local__res as *const Intmap_result)).ref).first as *const i32) as *mut i32)) = __param__key)

            ((unsafe *(*(&raw const __local__res as *const Intmap_result)).ref).second = __param__mapped)

        } else {


        }

        return __local__res

    }

    pub mut fn push(__param__val: Intmap_value) -> *mut Intmap_value {
        let __param_self_: *mut Intmap = self as *mut Intmap
        var __local__res: Intmap_result = unsafe { Intmap_insert_entry_(__param_self_, (*((&raw const (*(&raw mut __param__val as *mut Intmap_value)).first as *const i32) as *mut i32))) }

        if (not (unsafe *(&raw const __local__res as *const Intmap_result)).inserted) {
            unsafe { Intmap_value_drop((__param_self_ as *const Intmap), (*(&raw const __local__res as *const Intmap_result)).ref) }
        }

        with_memcpy((&raw mut (unsafe *((*(&raw const __local__res as *const Intmap_result)).ref)) as *mut u8), (&raw const __param__val as *const u8), sizeof[Intmap_value]())

        return (unsafe *(&raw const __local__res as *const Intmap_result)).ref

    }

    pub mut fn put(__param_rkey: i32, __param_rmapped: i32) -> Intmap_result {
        let __param_self_: *mut Intmap = self as *mut Intmap
        return unsafe { Intmap_insert_or_assign(__param_self_, __param_rkey, __param_rmapped) }

    }

}

impl Intmap_raw {
    pub fn Pairvec_value_toraw() -> Intmap_raw {
        let __param_val: *const Intmap_raw = self as *const Intmap_raw
        return (unsafe *__param_val)

    }

    pub fn Pairvec_from_n(__param_n: i64) -> Pairvec {
        let __param_raw: *const Intmap_raw = self as *const Intmap_raw
        var __local_out: Pairvec = Pairvec_with_capacity(__param_n)

        unsafe { Pairvec_put_n((&raw mut __local_out as *mut Pairvec), __param_raw, __param_n) }

        return __local_out

    }

}

impl Intmap_value {
    pub fn toraw() -> Intmap_raw {
        let __param_val: *const Intmap_value = self as *const Intmap_value
        return ((Intmap_raw { first: ((unsafe *(&raw const (*__param_val).first as *const i32))), second: ((unsafe *(&raw const (*__param_val).second as *const i32))) } as Intmap_raw))

    }

}

impl Mymap {
    pub fn is_empty() -> bool {
        let __param_self_: *const Mymap = self as *const Mymap
        return (((((unsafe *__param_self_).size == 0)) as bool))

    }

    pub fn size() -> i64 {
        let __param_self_: *const Mymap = self as *const Mymap
        return (((unsafe *__param_self_).size as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const Mymap = self as *const Mymap
        return (((unsafe *__param_self_).capacity as i64))

    }

    pub fn find(__param_rkey: i32) -> Mymap_iter {
        let __param_self_: *const Mymap = self as *const Mymap
        var __local_it_: Mymap_iter

        unsafe { Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) }

        return __local_it_

    }

    pub fn contains(__param_rkey: i32) -> bool {
        let __param_self_: *const Mymap = self as *const Mymap
        var __local_it_: Mymap_iter

        return ((((unsafe { Mymap_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut Mymap_iter)) } != null)) as bool))

    }

    pub mut fn move_() -> Mymap {
        let __param_self_: *mut Mymap = self as *mut Mymap
        var __local_m: Mymap = (unsafe *__param_self_)

        ((unsafe *__param_self_).head = ((0 as i32)))

        ((unsafe *__param_self_).disp = (unsafe *__param_self_).head)

        ((unsafe *__param_self_).root = (unsafe *__param_self_).disp)

        ((unsafe *__param_self_).size = (unsafe *__param_self_).root)

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).nodes = ((null as *mut Mymap_node)))

        return __local_m

    }

    pub mut fn clear() -> Unit {
        let __param_self_: *mut Mymap = self as *mut Mymap
        unsafe { Mymap_drop((__param_self_ as *const Mymap)) }

        unsafe { (*__param_self_).move_() }

    }

    pub mut fn take(__param_unowned: Mymap) -> Unit {
        let __param_self_: *mut Mymap = self as *mut Mymap
        unsafe { Mymap_drop((__param_self_ as *const Mymap)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Mymap]())

    }

    pub fn value_clone(__param__val: Mymap_value) -> Mymap_value {
        let __param_self_: *const Mymap = self as *const Mymap

        ((unsafe *((&raw const (*(&raw mut __param__val as *mut Mymap_value)).first as *const i32) as *mut i32)) = (unsafe *((&raw const (*(&raw mut __param__val as *mut Mymap_value)).first as *const i32) as *mut i32)))

        let __ci_copy_22: cstr = cstr_clone((unsafe *(&raw const __param__val as *const Mymap_value)).second)
        with_memcpy((&raw mut __param__val.second as *mut u8), (&raw const __ci_copy_22 as *const u8), sizeof[cstr]())

        return __param__val

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut Mymap = self as *mut Mymap
        if ((unsafe *__param_self_).size == (unsafe *__param_self_).capacity) {
            return
        }

        var __local_tmp: Mymap = Mymap_clone((unsafe *__param_self_))

        unsafe { Mymap_drop((__param_self_ as *const Mymap)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __local_tmp as *const u8), sizeof[Mymap]())

    }

    pub fn end() -> Mymap_iter {
        let __param_self_: *const Mymap = self as *const Mymap
        var __local_it_: Mymap_iter


        (__local_it_.ref = ((null as *mut Mymap_value)))

        (__local_it_._top = ((0 as i32)))

        (__local_it_._tn = ((0 as i32)))


        return __local_it_

    }

    pub mut fn insert(__param__key: i32, __param__mapped: cstr) -> Mymap_result {
        let __param_self_: *mut Mymap = self as *mut Mymap
        var __local__res: Mymap_result = unsafe { Mymap_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut i32))) }

        if (unsafe *(&raw const __local__res as *const Mymap_result)).inserted {
            ((unsafe *((&raw const (*(*(&raw const __local__res as *const Mymap_result)).ref).first as *const i32) as *mut i32)) = __param__key)

            with_memcpy((&raw mut (unsafe *(*(&raw const __local__res as *const Mymap_result)).ref).second as *mut u8), (&raw const __param__mapped as *const u8), sizeof[cstr]())

        } else {

            unsafe { cstr_drop(((&raw mut __param__mapped as *mut cstr) as *const cstr)) }

        }

        return __local__res

    }

    pub mut fn push(__param__val: Mymap_value) -> *mut Mymap_value {
        let __param_self_: *mut Mymap = self as *mut Mymap
        var __local__res: Mymap_result = unsafe { Mymap_insert_entry_(__param_self_, (*((&raw const (*(&raw mut __param__val as *mut Mymap_value)).first as *const i32) as *mut i32))) }

        if (not (unsafe *(&raw const __local__res as *const Mymap_result)).inserted) {
            unsafe { Mymap_value_drop((__param_self_ as *const Mymap), (*(&raw const __local__res as *const Mymap_result)).ref) }
        }

        with_memcpy((&raw mut (unsafe *((*(&raw const __local__res as *const Mymap_result)).ref)) as *mut u8), (&raw const __param__val as *const u8), sizeof[Mymap_value]())

        return (unsafe *(&raw const __local__res as *const Mymap_result)).ref

    }

}

impl Mymap_value {
    pub fn toraw() -> Mymap_raw {
        let __param_val: *const Mymap_value = self as *const Mymap_value
        return ((Mymap_raw { first: ((unsafe *(&raw const (*__param_val).first as *const i32))), second: unsafe { cstr_toraw((&raw const (*__param_val).second as *const cstr)) } } as Mymap_raw))

    }

}

impl Pairvec {
    pub mut fn move_() -> Pairvec {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        var __local_m: Pairvec = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).data = ((null as *mut Intmap_raw)))

        return __local_m

    }

    pub mut fn take(__param_unowned: Pairvec) -> Unit {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        unsafe { Pairvec_drop((__param_self_ as *const Pairvec)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Pairvec]())

    }

    pub mut fn push(__param_value: Intmap_raw) -> *mut Intmap_raw {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        if ((unsafe *__param_self_).size == (unsafe *__param_self_).capacity) {
            if (not unsafe { Pairvec_reserve(__param_self_, ((((*__param_self_).size * 2) + 4) as i64)) }) {
                return ((null as *mut Intmap_raw))
            }
        }

        var __local_v: *mut Intmap_raw = with 0 as __ci_expr_seq_10 {
            var __ci_expr_old_0: i64 = (unsafe *__param_self_).size
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size + 1)
            ((unsafe *__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
        }

        with_memcpy((&raw mut (unsafe *__local_v) as *mut u8), (&raw const __param_value as *const u8), sizeof[Intmap_raw]())

        return __local_v

    }

    pub fn value_clone(__param_val: Intmap_raw) -> Intmap_raw {
        let __param_self_: *const Pairvec = self as *const Pairvec

        return __param_val

    }

    pub fn size() -> i64 {
        let __param_self_: *const Pairvec = self as *const Pairvec
        return (unsafe *__param_self_).size

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const Pairvec = self as *const Pairvec
        return (unsafe *__param_self_).capacity

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const Pairvec = self as *const Pairvec
        return ((((not (unsafe *__param_self_).size)) as bool))

    }

    pub mut fn pop() {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        if ((if not (unsafe *__param_self_).size: 1 else: 0) as i64) {
            __assert_rtn(c"Pairvec_pop".ptr, c"vec.h".ptr, (151 as i32), c"self->size".ptr)
        } else {
            0
        }

        var __local_p: *mut Intmap_raw = with 0 as __ci_expr_seq_8 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)
            ((&raw const (unsafe (*__param_self_).data[(*__param_self_).size]) as *const Intmap_raw) as *mut Intmap_raw)
        }


    }

    pub mut fn pull() -> Intmap_raw {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        if ((if not (unsafe *__param_self_).size: 1 else: 0) as i64) {
            __assert_rtn(c"Pairvec_pull".ptr, c"vec.h".ptr, (153 as i32), c"self->size".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)

        return (unsafe (*__param_self_).data[(*__param_self_).size])


    }

    pub mut fn push_back(__param_value: Intmap_raw) -> *mut Intmap_raw {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        return ((unsafe { (*__param_self_).push(__param_value) } as *mut Intmap_raw))

    }

    pub mut fn pop_back() {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        unsafe { (*__param_self_).pop() }

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        unsafe { Pairvec_reserve(__param_self_, (9223372036854775807 as i64)) }

    }

    pub mut fn insert_at(__param_it_: Pairvec_iter, __param_value: Intmap_raw) -> Pairvec_iter {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        return unsafe { Pairvec_insert_n(__param_self_, ((((((if (*(&raw const __param_it_ as *const Pairvec_iter)).ref != null: (*(&raw const __param_it_ as *const Pairvec_iter)).ref else: (*(&raw const __param_it_ as *const Pairvec_iter)).end) as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[Intmap_raw]() as i64)) as i64), ((&raw const __param_value as *const Intmap_raw) as *mut Intmap_raw), (1 as i64)) }

    }

    pub mut fn erase_at(__param_it_: Pairvec_iter) -> Pairvec_iter {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        return unsafe { Pairvec_erase_n(__param_self_, ((((((*(&raw const __param_it_ as *const Pairvec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[Intmap_raw]() as i64)) as i64), (1 as i64)) }

    }

    pub mut fn erase_range(__param_i1: Pairvec_iter, __param_i2: Pairvec_iter) -> Pairvec_iter {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        var __ci_expr_ternary_1: *mut Intmap_raw = null

        var __ci_expr_logic_0: i32 = 0

        if ((unsafe *(&raw const __param_i1 as *const Pairvec_iter)).ref != null) {
            (__ci_expr_logic_0 = (if not ((unsafe *(&raw const __param_i2 as *const Pairvec_iter)).ref != null): 1 else: 0))
        }

        if __ci_expr_logic_0 {
            (__ci_expr_ternary_1 = (unsafe *(&raw const __param_i1 as *const Pairvec_iter)).end)
        } else {
            (__ci_expr_ternary_1 = (unsafe *(&raw const __param_i2 as *const Pairvec_iter)).ref)
        }

        return unsafe { Pairvec_erase_n(__param_self_, ((((((*(&raw const __param_i1 as *const Pairvec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[Intmap_raw]() as i64)) as i64), (((((__ci_expr_ternary_1 as usize) -% ((*(&raw const __param_i1 as *const Pairvec_iter)).ref as usize)) as i64) / (sizeof[Intmap_raw]() as i64)) as i64)) }


    }

    pub fn begin() -> Pairvec_iter {
        let __param_self_: *const Pairvec = self as *const Pairvec
        var __local_it_: Pairvec_iter = Pairvec_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if (unsafe *__param_self_).size {
            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const Pairvec_iter)).end + (((unsafe *__param_self_).size as i64) as usize))
        } else {
            (__local_it_.ref = ((null as *mut Intmap_raw)))
        }

        return __local_it_

    }

    pub fn rbegin() -> Pairvec_iter {
        let __param_self_: *const Pairvec = self as *const Pairvec
        var __local_it_: Pairvec_iter = Pairvec_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if (unsafe *__param_self_).size {
            (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const Pairvec_iter)).ref + ((((unsafe *__param_self_).size - 1) as i64) as usize))

            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const Pairvec_iter)).end - ((1 as i64) as usize))

        } else {
            (__local_it_.ref = ((null as *mut Intmap_raw)))
        }

        return __local_it_

    }

    pub fn end() -> Pairvec_iter {
        let __param_self_: *const Pairvec = self as *const Pairvec

        var __local_it_: Pairvec_iter = Pairvec_iter.zeroed()

        return __local_it_

    }

    pub fn rend() -> Pairvec_iter {
        let __param_self_: *const Pairvec = self as *const Pairvec

        var __local_it_: Pairvec_iter = Pairvec_iter.zeroed()

        return __local_it_

    }

    pub fn index(__param_it_: Pairvec_iter) -> i64 {
        let __param_self_: *const Pairvec = self as *const Pairvec
        return (((((unsafe *(&raw const __param_it_ as *const Pairvec_iter)).ref as usize) -% ((unsafe *__param_self_).data as usize)) as i64) / (sizeof[Intmap_raw]() as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut Pairvec = self as *mut Pairvec
        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

    }

}

impl Pairvec_iter {
    pub mut fn next() {
        let __param_it_: *mut Pairvec_iter = self as *mut Pairvec_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

        if ((unsafe *__param_it_).ref == (unsafe *__param_it_).end) {
            ((unsafe *__param_it_).ref = ((null as *mut Intmap_raw)))
        }


    }

    pub mut fn rnext() {
        let __param_it_: *mut Pairvec_iter = self as *mut Pairvec_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

        if ((unsafe *__param_it_).ref == (unsafe *__param_it_).end) {
            ((unsafe *__param_it_).ref = ((null as *mut Intmap_raw)))
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
