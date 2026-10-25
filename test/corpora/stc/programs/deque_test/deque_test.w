// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
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

unsafe fn IDeq_reserve(__param_self_: *mut IDeq, __param_cap: i64) -> bool {
    var __local_oldpow2: i64 = ((((*__param_self_).capmask + (((*__param_self_).capmask as i64) & (1 as i64))) as i64))

    var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

    if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
        return (((((*__param_self_).cbuf != null)) as bool))
    }

    var __local_d: *mut i32 = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[i32]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[i32]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32))

    if ((if __local_d == null: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_head: i64 = (((__local_oldpow2 - (*__param_self_).start) as i64))

    if (not ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0)) {
        if ((if __local_head < (*__param_self_).end: 1 else: 0) != 0) {
            with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((*__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

        } else {
            with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).end * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((*__param_self_).end = (*__param_self_).end + __local_oldpow2)

        }
    }

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    ((*__param_self_).cbuf = __local_d)

    return ((true as bool))

}

unsafe fn IDeq_clear(__param_self_: *mut IDeq) {
    var __local_i: IDeq_iter = IDeq_begin((((&raw const (*__param_self_) as *const IDeq) as *mut IDeq) as *const IDeq))

    while ((*(&raw const __local_i as *const IDeq_iter)).ref != null) {


        (*(&raw mut __local_i as *mut IDeq_iter)).next()

    }


    ((*__param_self_).start = ((0 as i64)))

    ((*__param_self_).end = ((0 as i64)))


}

// contract: unproved:0:read only
unsafe fn IDeq_drop(__param_cself: *const IDeq) {
    var __local_self_: *mut IDeq = ((__param_cself as *mut IDeq))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    IDeq_clear(__local_self_)

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

unsafe fn IDeq_push(__param_self_: *mut IDeq, __param_value: i32) -> *mut i32 {
    var __local_end: i64 = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not IDeq_reserve(__param_self_, (((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut i32))
        }

        (__local_end = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut i32 = ((*__param_self_).cbuf + (((*__param_self_).end as i64) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

unsafe fn IDeq_shrink_to_fit(__param_self_: *mut IDeq) {
    var __local_sz: i64 = ((IDeq_size((__param_self_ as *const IDeq)) as i64))

    var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

    if ((if __local_newpow2 > (*__param_self_).capmask: 1 else: 0) != 0) {
        return
    }

    if ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove((((*__param_self_).cbuf as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        ((*__param_self_).start = ((0 as i64)))

        ((*__param_self_).end = __local_sz)


    } else {
        var __local_n: i64 = (((((*__param_self_).capmask - (*__param_self_).start) + 1) as i64))

        with_memmove(((((*__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        ((*__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

    }

    ((*__param_self_).cbuf = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[i32]() as i64)) as i64) else: ((((*__param_self_).capmask + 1) * (sizeof[i32]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)))

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

}

fn IDeq_advance(__param_it_: IDeq_iter, __param_n: i64) -> IDeq_iter {
    var __local_len: i64 = ((unsafe { IDeq_size((*(&raw const __param_it_ as *const IDeq_iter))._s) } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const IDeq_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const IDeq_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const IDeq_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const IDeq_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const IDeq_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const IDeq_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut i32)))
    }

    return __param_it_

}

// contract: receiver-mut:IDeq,unproved:1:read only
pub unsafe fn IDeq_put_n(__param_self_: *mut IDeq, __param_raw: *const i32, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        IDeq_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn IDeq_value_drop(__param_self_: *const IDeq, __param_val: *mut i32) {
    return
}

pub fn IDeq_init() -> IDeq {
    var __local_out: IDeq = IDeq.zeroed()

    return __local_out

}

pub fn IDeq_with_capacity(__param_cap: i64) -> IDeq {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as i64)) as i64)))

    var __local_out: IDeq = IDeq { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn IDeq_with_size_uninit(__param_size: i64) -> IDeq {
    var __local_out: IDeq = IDeq_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

pub fn IDeq_with_size(__param_size: i64, __param_default_raw: i32) -> IDeq {
    var __local_out: IDeq = IDeq_with_capacity(__param_size)

    while ((if (unsafe *(&raw const __local_out as *const IDeq)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (unsafe *(&raw const __local_out as *const IDeq)).end

        (__local_out.end = (unsafe *(&raw const __local_out as *const IDeq)).end + 1)

        ((unsafe __local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn IDeq_from_n(__param_raw: *const i32, __param_n: i64) -> IDeq {
    var __local_out: IDeq = IDeq_with_capacity(__param_n)

    IDeq_put_n((&raw mut __local_out as *mut IDeq), __param_raw, __param_n)

    return __local_out

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn IDeq_eq(__param_self_: *const IDeq, __param_other: *const IDeq) -> bool {
    if ((if IDeq_size(__param_self_) != IDeq_size(__param_other): 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_i: IDeq_iter = IDeq_begin(__param_self_)

    var __local_j: IDeq_iter = IDeq_begin(__param_other)


    while ((*(&raw const __local_i as *const IDeq_iter)).ref != null) {
        var __local__rx: i32 = (*((*(&raw const __local_i as *const IDeq_iter)).ref))

        var __local__ry: i32 = (*((*(&raw const __local_j as *const IDeq_iter)).ref))


        if ((if not ((if (*(&raw const __local__rx as *const i32)) == (*(&raw const __local__ry as *const i32)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return ((false as bool))
        }


        (*(&raw mut __local_i as *mut IDeq_iter)).next()

        (*(&raw mut __local_j as *mut IDeq_iter)).next()


    }


    return ((true as bool))

}

fn IDeq_clone(__param_q: IDeq) -> IDeq {
    var __local_out: IDeq = __param_q

    var __local_self_: *mut IDeq = ((&raw mut __local_out as *mut IDeq))



    (__local_out.start = ((0 as i64)))

    (__local_out.end = ((unsafe { IDeq_size(((&raw mut __param_q as *mut IDeq) as *const IDeq)) } as i64)))

    (__local_out.capmask = (((c_next_pow2((((unsafe *(&raw const __local_out as *const IDeq)).end + 1) as i64)) - 1) as i64)))

    (__local_out.cbuf = (((with_alloc((((if 1 != 0: ((((unsafe *(&raw const __local_out as *const IDeq)).capmask + 1) * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)))

    var __local_i: i64 = ((0 as i64))

    if ((unsafe *(&raw const __local_out as *const IDeq)).cbuf != null) {
        var __local_it_: IDeq_iter = unsafe { IDeq_begin(((&raw mut __param_q as *mut IDeq) as *const IDeq)) }

        while ((unsafe *(&raw const __local_it_ as *const IDeq_iter)).ref != null) {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i + 1)

            ((unsafe __local_out.cbuf[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_it_ as *const IDeq_iter)).ref)))


            unsafe { (*(&raw mut __local_it_ as *mut IDeq_iter)).next() }

        }

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn IDeq_value_clone(__param_self_: *const IDeq, __param_val: i32) -> i32 {

    return __param_val

}

// contract: receiver-mut:IDeq,unproved:1:read only
pub unsafe fn IDeq_copy(__param_self_: *mut IDeq, __param_other: *const IDeq) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    IDeq_drop((__param_self_ as *const IDeq))

    let __ci_copy_18: IDeq = IDeq_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[IDeq]())

}

// contract: unproved:0:read only
pub unsafe fn IDeq_size(__param_self_: *const IDeq) -> i64 {
    return ((((*__param_self_).end - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_capacity(__param_self_: *const IDeq) -> i64 {
    return (*__param_self_).capmask

}

// contract: unproved:0:read only
pub unsafe fn IDeq_is_empty(__param_self_: *const IDeq) -> bool {
    return (((((*__param_self_).start == (*__param_self_).end)) as bool))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_value_toraw(__param_pval: *const i32) -> i32 {
    return (*__param_pval)

}

// contract: unproved:0:read only
pub unsafe fn IDeq_front(__param_self_: *const IDeq) -> *const i32 {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_front_mut(__param_self_: *mut IDeq) -> *mut i32 {
    return ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_back(__param_self_: *const IDeq) -> *const i32 {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_back_mut(__param_self_: *mut IDeq) -> *mut i32 {
    return ((IDeq_back((__param_self_ as *const IDeq)) as *mut i32))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_begin(__param_self_: *const IDeq) -> IDeq_iter {
    return ((IDeq_iter { ref: (if IDeq_is_empty(__param_self_): ((null) as *mut i32) else: ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))), pos: (*__param_self_).start, _s: __param_self_ } as IDeq_iter))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_rbegin(__param_self_: *const IDeq) -> IDeq_iter {
    var __local_pos: i64 = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    return ((IDeq_iter { ref: (if IDeq_is_empty(__param_self_): ((null) as *mut i32) else: ((*__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as IDeq_iter))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_end(__param_self_: *const IDeq) -> IDeq_iter {

    return ((IDeq_iter.zeroed() as IDeq_iter))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_rend(__param_self_: *const IDeq) -> IDeq_iter {

    return ((IDeq_iter.zeroed() as IDeq_iter))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_index(__param_self_: *const IDeq, __param_it_: IDeq_iter) -> i64 {
    return ((((*(&raw const __param_it_ as *const IDeq_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64))

}

unsafe fn IDeq_push_front(__param_self_: *mut IDeq, __param_value: i32) -> *mut i32 {
    var __local_start: i64 = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_start == (*__param_self_).end: 1 else: 0) != 0) {
        if ((if not IDeq_reserve(__param_self_, (((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut i32))
        }

        (__local_start = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut i32 = ((*__param_self_).cbuf + ((__local_start as i64) as usize))

    ((*__param_self_).start = __local_start)

    ((*__local_v) = __param_value)

    return __local_v

}

// contract: receiver-mut:IDeq,unproved:2:read only
unsafe fn IDeq_insert_n(__param_self_: *mut IDeq, __param_idx: i64, __param_arr: *const i32, __param_n: i64) -> IDeq_iter {
    var __local_it_: IDeq_iter = IDeq_insert_uninit(__param_self_, __param_idx, __param_n)

    var __local_i: i64 = __param_idx

    var __local_j: i64 = ((0 as i64))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(IDeq_at_mut(__param_self_, __local_i))) = (((__param_arr[__local_j]) as i32)))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

unsafe fn IDeq_insert_uninit(__param_self_: *mut IDeq, __param_idx: i64, __param_n: i64) -> IDeq_iter {
    var __local_len: i64 = ((IDeq_size((__param_self_ as *const IDeq)) as i64))

    var __local_it_: IDeq_iter = IDeq_iter { _s: (__param_self_ as *const IDeq) }

    if ((if (__local_len + __param_n) >= (*__param_self_).capmask: 1 else: 0) != 0) {
        if ((if not IDeq_reserve(__param_self_, ((__local_len + __param_n) as i64)): 1 else: 0) != 0) {
            return __local_it_
        }
    }

    (__local_it_.pos = ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    (__local_it_.ref = (*__param_self_).cbuf + (((*(&raw const __local_it_ as *const IDeq_iter)).pos as i64) as usize))

    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    if ((if (*(&raw const __local_it_ as *const IDeq_iter)).pos < (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove(((((*(&raw const __local_it_ as *const IDeq_iter)).ref + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __local_it_ as *const IDeq_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
    } else {
        var __local_i: i64 = (((__local_len - 1) as i64))

        var __local_j: i64 = (((__local_i + __param_n) as i64))


        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
            ((*(IDeq_at_mut(__param_self_, __local_j))) = (*(IDeq_at((__param_self_ as *const IDeq), __local_i))))

            (__local_i = __local_i - 1)

            (__local_j = __local_j - 1)


        }

    }

    return __local_it_

}

unsafe fn IDeq_erase_n(__param_self_: *mut IDeq, __param_idx: i64, __param_n: i64) {
    var __local_len: i64 = ((IDeq_size((__param_self_ as *const IDeq)) as i64))

    if (((if not ((if (__param_idx + __param_n) <= __local_len: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IDeq_erase_n".ptr, c"deque.h".ptr, (149 as i32), c"idx + n <= len".ptr)
    } else {
        0
    }

    var __local_i: i64 = ((((__param_idx + __param_n) - 1) as i64))

    while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
        IDeq_at_mut(__param_self_, __local_i)

        (__local_i = __local_i - 1)

    }


    var __local_i_1: i64 = __param_idx

    var __local_j: i64 = (((__local_i_1 + __param_n) as i64))


    while ((if __local_j < __local_len: 1 else: 0) != 0) {
        ((*(IDeq_at_mut(__param_self_, __local_i_1))) = (*(IDeq_at((__param_self_ as *const IDeq), __local_j))))

        (__local_i_1 = __local_i_1 + 1)

        (__local_j = __local_j + 1)


    }


    ((*__param_self_).end = ((((((*__param_self_).end - __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_at(__param_self_: *const IDeq, __param_idx: i64) -> *const i32 {
    if (((if not ((if ((__param_idx as u64)) < ((IDeq_size(__param_self_) as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IDeq_at".ptr, c"deque.h".ptr, (53 as i32), c"((size_t)(idx) < (size_t)(IDeq_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IDeq_at_mut(__param_self_: *mut IDeq, __param_idx: i64) -> *mut i32 {
    return ((IDeq_at((__param_self_ as *const IDeq), __param_idx) as *mut i32))

}

// contract: unproved:0:read only
unsafe fn IDeq_find_in(__param_self_: *const IDeq, __param_i1: IDeq_iter, __param_i2: IDeq_iter, __param_raw: i32) -> IDeq_iter {

    while ((if (*(&raw const __param_i1 as *const IDeq_iter)).ref != (*(&raw const __param_i2 as *const IDeq_iter)).ref: 1 else: 0) != 0) {
        var __local_r: i32 = (*((*(&raw const __param_i1 as *const IDeq_iter)).ref))

        if ((if (*(&raw mut __param_raw as *mut i32)) == (*(&raw const __local_r as *const i32)): 1 else: 0) != 0) {
            break
        }


        (*(&raw mut __param_i1 as *mut IDeq_iter)).next()

    }

    return __param_i1

}

// contract: unproved:0:read only
pub unsafe fn IDeq_find(__param_self_: *const IDeq, __param_raw: i32) -> IDeq_iter {
    return IDeq_find_in(__param_self_, IDeq_begin(__param_self_), IDeq_end(__param_self_), __param_raw)

}

// contract: unproved:0:read only
pub unsafe fn IDeq_contains(__param_self_: *const IDeq, __param_raw: i32) -> bool {
    return ((((IDeq_find(__param_self_, __param_raw).ref != null)) as bool))

}

@[repr(C)]
pub type ctest_deque_basics_run__c_i2_anon { _ref: *const *mut IDeq = null, ref: *mut *mut IDeq = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_deque_basics_run__c_i2_anon
fn ctest_deque_basics_run() {
    var __local_d: IDeq = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [i32; 12] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        unsafe { IDeq_from_n((&__ci_expr_lit_0[0] as *mut i32), (12 as i64)) }
    }

    assert_compare((1 as i32), c"==".ptr, (12 as i64), (unsafe { IDeq_size(((&raw mut __local_d as *mut IDeq) as *const IDeq)) } as i64), c"deque_test.c".ptr, (9 as i32))

    var __local__c_i1: i64 = ((0 as i64))

    var __local__c_end__c_i1: i64 = ((5 as i64))


    while ((if __local__c_i1 < __local__c_end__c_i1: 1 else: 0) != 0) {
        unsafe { (*(&raw mut __local_d as *mut IDeq)).pop_front() }

        (__local__c_i1 = __local__c_i1 + 1)

    }


    var __local_i: i32 = ((2 as i32))

    var __local__c_end_i: i32 = ((9 as i32))


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        unsafe { (*(&raw mut __local_d as *mut IDeq)).push_back(((__local_i * 10) as i32)) }

        (__local_i = __local_i + 1)

    }


    var __local_res1: IDeq = with 0 as __ci_expr_seq_27 {
        var __ci_expr_lit_1: [i32; 14] = [6, 7, 8, 9, 10, 11, 12, 20, 30, 40, 50, 60, 70, 80]
        unsafe { IDeq_from_n((&__ci_expr_lit_1[0] as *mut i32), (14 as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IDeq_eq(((&raw mut __local_res1 as *mut IDeq) as *const IDeq), ((&raw mut __local_d as *mut IDeq) as *const IDeq)) } as bool), c"deque_test.c".ptr, (17 as i32))

    assert_compare((1 as i32), c"==".ptr, (14 as i64), (unsafe { IDeq_size(((&raw mut __local_d as *mut IDeq) as *const IDeq)) } as i64), c"deque_test.c".ptr, (18 as i32))

    unsafe { IDeq_erase_n((&raw mut __local_d as *mut IDeq), (7 as i64), (4 as i64)) }

    var __local_res2: IDeq = with 0 as __ci_expr_seq_35 {
        var __ci_expr_lit_2: [i32; 10] = [6, 7, 8, 9, 10, 11, 12, 60, 70, 80]
        unsafe { IDeq_from_n((&__ci_expr_lit_2[0] as *mut i32), (10 as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IDeq_eq(((&raw mut __local_res2 as *mut IDeq) as *const IDeq), ((&raw mut __local_d as *mut IDeq) as *const IDeq)) } as bool), c"deque_test.c".ptr, (23 as i32))

    var __local_nums: List[i32] = [200, 300, 400, 500]

    unsafe { IDeq_insert_n((&raw mut __local_d as *mut IDeq), (7 as i64), (&__local_nums[0] as *mut i32), (4 as i64)) }

    var __local_res3: IDeq = with 0 as __ci_expr_seq_43 {
        var __ci_expr_lit_3: [i32; 14] = [6, 7, 8, 9, 10, 11, 12, 200, 300, 400, 500, 60, 70, 80]
        unsafe { IDeq_from_n((&__ci_expr_lit_3[0] as *mut i32), (14 as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IDeq_eq(((&raw mut __local_res3 as *mut IDeq) as *const IDeq), ((&raw mut __local_d as *mut IDeq) as *const IDeq)) } as bool), c"deque_test.c".ptr, (29 as i32))

    assert_compare((1 as i32), c"==".ptr, ((unsafe *(unsafe { IDeq_find(((&raw mut __local_res3 as *mut IDeq) as *const IDeq), (400 as i32)) }.ref)) as i64), (400 as i64), c"deque_test.c".ptr, (30 as i32))

    assert_pointers((1 as i32), c"==".ptr, (null as *const c_void), (unsafe { IDeq_find(((&raw mut __local_res3 as *mut IDeq) as *const IDeq), (401 as i32)) }.ref as *const c_void), c"deque_test.c".ptr, (31 as i32))

    assert_compare((1 as i32), c"==".ptr, (14 as i64), (unsafe { IDeq_size(((&raw mut __local_d as *mut IDeq) as *const IDeq)) } as i64), c"deque_test.c".ptr, (33 as i32))

    assert_compare((1 as i32), c"==".ptr, (200 as i64), ((unsafe *unsafe { IDeq_at(((&raw mut __local_d as *mut IDeq) as *const IDeq), (7 as i64)) }) as i64), c"deque_test.c".ptr, (34 as i32))

    loop {
        var __local__c_i2: ctest_deque_basics_run__c_i2_anon = ctest_deque_basics_run__c_i2_anon.zeroed()

        var __ci_expr_lit_4: [*mut IDeq; 4] = [(&raw mut __local_d as *mut IDeq), (&raw mut __local_res1 as *mut IDeq), (&raw mut __local_res2 as *mut IDeq), (&raw mut __local_res3 as *mut IDeq)]

        __local__c_i2 = ctest_deque_basics_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_4)[0] as *mut *mut IDeq) as *const *mut IDeq)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_deque_basics_run__c_i2_anon))._ref as *mut *mut IDeq)
        __local__c_i2.size = (((((4 * (sizeof[usize]() as usize)) as u64) / (sizeof[IDeq]() as u64))) as i32)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_deque_basics_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_deque_basics_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { IDeq_drop(((*((*(&raw const __local__c_i2 as *const ctest_deque_basics_run__c_i2_anon)).ref)) as *const IDeq)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_deque_basics_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_deque_basics_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

impl IDeq {
    pub mut fn move_() -> IDeq {
        let __param_self_: *mut IDeq = self as *mut IDeq
        var __local_m: IDeq = (unsafe *__param_self_)

        ((unsafe *__param_self_).end = ((0 as i64)))

        ((unsafe *__param_self_).start = (unsafe *__param_self_).end)

        ((unsafe *__param_self_).capmask = (unsafe *__param_self_).start)


        ((unsafe *__param_self_).cbuf = ((null as *mut i32)))

        return __local_m

    }

    pub mut fn take(__param_unowned: IDeq) -> Unit {
        let __param_self_: *mut IDeq = self as *mut IDeq
        unsafe { IDeq_drop((__param_self_ as *const IDeq)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IDeq]())

    }

    pub mut fn pop_front() {
        let __param_self_: *mut IDeq = self as *mut IDeq
        if (((if not ((if not unsafe { IDeq_is_empty((__param_self_ as *const IDeq)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IDeq_pop_front".ptr, c"queue_prv.h".ptr, (133 as i32), c"!IDeq_is_empty(self)".ptr)
        } else {
            0
        }


        ((unsafe *__param_self_).start = ((((((unsafe *__param_self_).start + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn pull_front() -> i32 {
        let __param_self_: *mut IDeq = self as *mut IDeq
        if (((if not ((if not unsafe { IDeq_is_empty((__param_self_ as *const IDeq)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IDeq_pull_front".ptr, c"queue_prv.h".ptr, (139 as i32), c"!IDeq_is_empty(self)".ptr)
        } else {
            0
        }

        var __local_s: i64 = (unsafe *__param_self_).start

        ((unsafe *__param_self_).start = (((((__local_s + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (unsafe (*__param_self_).cbuf[__local_s])

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut IDeq = self as *mut IDeq
        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn push_back(__param_val: i32) -> *mut i32 {
        let __param_self_: *mut IDeq = self as *mut IDeq
        return ((unsafe { IDeq_push(__param_self_, __param_val) } as *mut i32))

    }

    pub mut fn pop_back() {
        let __param_self_: *mut IDeq = self as *mut IDeq
        if (((if not ((if not unsafe { IDeq_is_empty((__param_self_ as *const IDeq)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IDeq_pop_back".ptr, c"deque.h".ptr, (67 as i32), c"!IDeq_is_empty(self)".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))


    }

    pub mut fn pull_back() -> i32 {
        let __param_self_: *mut IDeq = self as *mut IDeq
        if (((if not ((if not unsafe { IDeq_is_empty((__param_self_ as *const IDeq)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IDeq_pull_back".ptr, c"deque.h".ptr, (73 as i32), c"!IDeq_is_empty(self)".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (unsafe (*__param_self_).cbuf[(*__param_self_).end])

    }

    pub mut fn insert_at(__param_it_: IDeq_iter, __param_val: i32) -> IDeq_iter {
        let __param_self_: *mut IDeq = self as *mut IDeq
        var __local_idx: i64 = ((((((unsafe *(&raw const __param_it_ as *const IDeq_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        return unsafe { IDeq_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const i32), (1 as i64)) }

    }

    pub mut fn erase_at(__param_it_: IDeq_iter) -> IDeq_iter {
        let __param_self_: *mut IDeq = self as *mut IDeq
        unsafe { IDeq_erase_n(__param_self_, (((((*(&raw const __param_it_ as *const IDeq_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64), (1 as i64)) }

        if ((if (unsafe *(&raw const __param_it_ as *const IDeq_iter)).pos == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            (__param_it_.ref = ((null as *mut i32)))
        }

        return __param_it_

    }

    pub mut fn erase_range(__param_it1: IDeq_iter, __param_it2: IDeq_iter) -> IDeq_iter {
        let __param_self_: *mut IDeq = self as *mut IDeq
        var __local_idx1: i64 = ((((((unsafe *(&raw const __param_it1 as *const IDeq_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        var __local_idx2: i64 = ((((((unsafe *(&raw const __param_it2 as *const IDeq_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        unsafe { IDeq_erase_n(__param_self_, __local_idx1, ((__local_idx2 - __local_idx1) as i64)) }

        if ((if (unsafe *(&raw const __param_it1 as *const IDeq_iter)).pos == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            (__param_it1.ref = ((null as *mut i32)))
        }

        return __param_it1

    }

}

impl IDeq_iter {
    pub mut fn next() {
        let __param_it_: *mut IDeq_iter = self as *mut IDeq_iter
        if ((if (unsafe *__param_it_).pos != (unsafe *(*__param_it_)._s).capmask: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos + 1)

        } else {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - (((unsafe *__param_it_).pos as i64) as usize))

            ((unsafe *__param_it_).pos = ((0 as i64)))

        }

        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut i32)))
        }

    }

    pub mut fn rnext() -> Unit {
        let __param_it_: *mut IDeq_iter = self as *mut IDeq_iter
        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).start: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut i32)))
        } else {
            if ((if (unsafe *__param_it_).pos != 0: 1 else: 0) != 0) {
                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

                ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos - 1)

            } else {
                ((unsafe *__param_it_).pos = (unsafe *(*__param_it_)._s).capmask)

                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + (((unsafe *__param_it_).pos as i64) as usize))

            }
        }

    }

}

var ctest_deque_basics: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("deque" as *mut c_char) as *const c_char), ttname: (("basics" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_deque_basics_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_deque_basics_run()
    print("ran deque.basics")
    return ctest_failure_count()
