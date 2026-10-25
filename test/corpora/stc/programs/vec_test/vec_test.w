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

// contract: unproved:0:casts away const
unsafe fn IVec_drop(__param_cself: *const IVec) {
    var __local_self_: *mut IVec = ((__param_cself as *mut IVec))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    IVec_clear(__local_self_)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

unsafe fn IVec_clear(__param_self_: *mut IVec) {
    var __local_i: i64 = (*__param_self_).size

    while true {
        var __ci_expr_old_0: i64 = __local_i

        (__local_i = __local_i - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

    }

    ((*__param_self_).size = ((0 as i64)))

}

unsafe fn IVec_reserve(__param_self_: *mut IVec, __param_cap: i64) -> bool {
    var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as i64))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as i32)) != 0) {
        var __local_d: *mut i32 = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[i32]() as i64)) as i64) else: (((*__param_self_).capacity * (sizeof[i32]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((((*__param_self_).data != null)) as bool))

}

unsafe fn IVec_resize(__param_self_: *mut IVec, __param_len: i64, __param_null_: i32) -> bool {
    if ((if not IVec_reserve(__param_self_, __param_len): 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_n: i64 = (*__param_self_).size

    var __local_i: i64 = __param_len

    while ((if __local_i < __local_n: 1 else: 0) != 0) {


        (__local_i = __local_i + 1)

    }


    var __local_i_1: i64 = __local_n

    while ((if __local_i_1 < __param_len: 1 else: 0) != 0) {
        (((*__param_self_).data[__local_i_1]) = __param_null_)

        (__local_i_1 = __local_i_1 + 1)

    }


    ((*__param_self_).size = __param_len)

    return ((true as bool))

}

unsafe fn IVec_erase_n(__param_self_: *mut IVec, __param_idx: i64, __param_len: i64) -> IVec_iter {
    if (((if not ((if (__param_idx + __param_len) <= (*__param_self_).size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IVec_erase_n".ptr, c"vec.h".ptr, (337 as i32), c"idx + len <= self->size".ptr)
    } else {
        0
    }

    var __local_d: *mut i32 = ((*__param_self_).data + ((__param_idx as i64) as usize))

    var __local_p: *mut i32 = __local_d

    var __local_end: *mut i32 = ((*__param_self_).data + (((*__param_self_).size as i64) as usize))


    var __local_i: i64 = ((0 as i64))

    while ((if __local_i < __param_len: 1 else: 0) != 0) {


        (__local_i = __local_i + 1)

        (__local_p = __local_p + 1)


    }


    with_memmove(((__local_d as *mut c_void) as *mut u8), ((__local_p as *const c_void) as *const u8), ((((((((__local_end as usize) -% (__local_p as usize)) as i64) / (sizeof[i32]() as i64)) as u64) *% (sizeof[i32]() as u64)) as u64) as i64))

    ((*__param_self_).size = (*__param_self_).size - __param_len)

    return ((IVec_iter { ref: (if __local_p == __local_end: ((null) as *mut i32) else: __local_d), end: (__local_end - ((__param_len as i64) as usize)) } as IVec_iter))

}

unsafe fn IVec_insert_uninit(__param_self_: *mut IVec, __param_idx: i64, __param_n: i64) -> IVec_iter {
    if ((if ((*__param_self_).size + __param_n) >= (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not IVec_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + __param_n) as i64)): 1 else: 0) != 0) {
            return (*(__param_self_ as *const IVec)).end()
        }
    }

    var __local_pos: *mut i32 = ((*__param_self_).data + ((__param_idx as i64) as usize))

    with_memmove((((__local_pos + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), ((__local_pos as *const c_void) as *const u8), (((if 1 != 0: ((((*__param_self_).size - __param_idx) * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((IVec_iter { ref: __local_pos, end: ((*__param_self_).data + (((*__param_self_).size as i64) as usize)) } as IVec_iter))

}

unsafe fn IVec_find_in(__param_self_: *const IVec, __param_i1: IVec_iter, __param_i2: IVec_iter, __param_raw: i32) -> IVec_iter {

    var __local_p2: *const i32 = with 0 as __ci_expr_seq_15 {
        var __ci_expr_ternary_1: *mut i32 = null
        var __ci_expr_logic_0: i32 = 0
        if ((*(&raw const __param_i1 as *const IVec_iter)).ref != null) {
            (__ci_expr_logic_0 = (if (if not ((*(&raw const __param_i2 as *const IVec_iter)).ref != null): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_ternary_1 = (*(&raw const __param_i1 as *const IVec_iter)).end)
        } else {
            (__ci_expr_ternary_1 = (*(&raw const __param_i2 as *const IVec_iter)).ref)
        }
        (__ci_expr_ternary_1 as *const i32)
    }

    while ((if (*(&raw const __param_i1 as *const IVec_iter)).ref != __local_p2: 1 else: 0) != 0) {
        var __local_r: i32 = (*((*(&raw const __param_i1 as *const IVec_iter)).ref))

        if ((if (*(&raw mut __param_raw as *mut i32)) == (*(&raw const __local_r as *const i32)): 1 else: 0) != 0) {
            return __param_i1
        }


        (__param_i1.ref = (*(&raw const __param_i1 as *const IVec_iter)).ref + 1)

    }

    (__param_i2.ref = ((null as *mut i32)))

    return __param_i2

}

// contract: receiver:IVec,unproved:1:read only
pub unsafe fn IVec_value_drop(__param_self_: *const IVec, __param_val: *mut i32) {
    return
}

// contract: receiver-mut:IVec,unproved:1:read only
pub unsafe fn IVec_put_n(__param_self_: *mut IVec, __param_raw: *const i32, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).push((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: receiver-mut:IVec,unproved:1:read only
unsafe fn IVec_copy(__param_self_: *mut IVec, __param_other: *const IVec) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    IVec_clear(__param_self_)

    IVec_reserve(__param_self_, (*__param_other).size)

    ((*__param_self_).size = (*__param_other).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        (((*__param_self_).data[__local_i]) = ((((*__param_other).data[__local_i]) as i32)))

        (__local_i = __local_i + 1)

    }


}

// contract: receiver-mut:IVec,unproved:2:read only
unsafe fn IVec_copy_to(__param_self_: *mut IVec, __param_idx: i64, __param_arr: *mut i32, __param_n: i64) -> IVec_iter {
    var __local_arr = __param_arr
    var __local_it_: IVec_iter = IVec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const IVec_iter)).ref != null) {
        var __local_p: *mut i32 = (*(&raw const __local_it_ as *const IVec_iter)).ref

        var __local_q: *mut i32 = (__local_p + ((__param_n as i64) as usize))


        while ((if __local_p != __local_q: 1 else: 0) != 0) {
            var __ci_expr_old_0: *mut i32 = __local_p

            (__local_p = __local_p + 1)

            ((*__ci_expr_old_0) = (*__local_arr))


            (__local_arr = __local_arr + 1)

        }

    }

    return __local_it_

}

fn IVec_clone(__param_vec: IVec) -> IVec {
    var __local_out: IVec = __param_vec

    var __local_self_: *mut IVec = ((&raw mut __local_out as *mut IVec))



    (__local_out.data = ((null as *mut i32)))

    (__local_out.capacity = ((0 as i64)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const IVec)).capacity)


    unsafe { IVec_reserve((&raw mut __local_out as *mut IVec), (*(&raw const __param_vec as *const IVec)).size) }

    (__local_out.size = (unsafe *(&raw const __param_vec as *const IVec)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_vec as *const IVec)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_vec as *const IVec)).data[__local_i]) as i32)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn IVec_value_toraw(__param_val: *const i32) -> i32 {
    return (*__param_val)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IVec_front(__param_self_: *const IVec) -> *const i32 {
    return (((*__param_self_).data as *const i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IVec_front_mut(__param_self_: *mut IVec) -> *mut i32 {
    return (*__param_self_).data

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IVec_back(__param_self_: *const IVec) -> *const i32 {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const i32) as *mut i32) as *const i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IVec_back_mut(__param_self_: *mut IVec) -> *mut i32 {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const i32) as *mut i32))

}

pub fn IVec_init() -> IVec {
    return ((IVec.zeroed() as IVec))

}

pub fn IVec_with_capacity(__param_cap: i64) -> IVec {
    var __local_out: IVec = IVec { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), size: 0, capacity: __param_cap }

    return __local_out

}

pub fn IVec_with_size_uninit(__param_size: i64) -> IVec {
    var __local_out: IVec = IVec { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), size: __param_size, capacity: __param_size }

    return __local_out

}

pub fn IVec_with_size(__param_size: i64, __param_default_raw: i32) -> IVec {
    var __local_size = __param_size
    var __local_out: IVec = IVec { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn IVec_from_n(__param_raw: *const i32, __param_n: i64) -> IVec {
    var __local_out: IVec = IVec_with_capacity(__param_n)

    IVec_put_n((&raw mut __local_out as *mut IVec), __param_raw, __param_n)

    return __local_out

}

// contract: receiver-mut:IVec,unproved:2:read only
pub unsafe fn IVec_insert_n(__param_self_: *mut IVec, __param_idx: i64, __param_arr: *mut i32, __param_n: i64) -> IVec_iter {
    var __local_it_: IVec_iter = IVec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const IVec_iter)).ref != null) {
        with_memcpy((((*(&raw const __local_it_ as *const IVec_iter)).ref as *mut c_void) as *mut u8), ((&(__param_arr[0]) as *mut i32) as *const u8), (((if 1 != 0: ((__param_n * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
    }

    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IVec_at(__param_self_: *const IVec, __param_idx: i64) -> *const i32 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IVec_at".ptr, c"vec.h".ptr, (206 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IVec_at_mut(__param_self_: *mut IVec, __param_idx: i64) -> *mut i32 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IVec_at_mut".ptr, c"vec.h".ptr, (210 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((*__param_self_).data + ((__param_idx as i64) as usize))

}

pub fn IVec_advance(__param_it_: IVec_iter, __param_n: u64) -> IVec_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const IVec_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const IVec_iter)).ref >= (unsafe *(&raw const __param_it_ as *const IVec_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut i32)))
    }


    return __param_it_

}

// contract: receiver:IVec,unproved:1:read only
pub unsafe fn IVec_eq(__param_self_: *const IVec, __param_other: *const IVec) -> bool {
    return ((((with_memcmp((((*__param_self_).data as *const c_void) as *const u8), (((*__param_other).data as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).size * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) == 0)) as bool))

}

@[repr(C)]
pub type ctest_vec_basics_run__c_i2_anon { _ref: *const *mut IVec = null, ref: *mut *mut IVec = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_vec_basics_run__c_i2_anon
fn ctest_vec_basics_run() {
    var __local_d: IVec = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [i32; 12] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        unsafe { IVec_from_n((&__ci_expr_lit_0[0] as *mut i32), (12 as i64)) }
    }

    assert_compare((1 as i32), c"==".ptr, (12 as i64), (unsafe { (*((&raw mut __local_d as *mut IVec) as *const IVec)).size() } as i64), c"vec_test.c".ptr, (9 as i32))

    unsafe { IVec_erase_n((&raw mut __local_d as *mut IVec), (0 as i64), (5 as i64)) }

    var __local_i: i32 = ((2 as i32))

    var __local__c_end_i: i32 = ((9 as i32))


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        unsafe { (*(&raw mut __local_d as *mut IVec)).push_back(((__local_i * 10) as i32)) }

        (__local_i = __local_i + 1)

    }


    var __local_res: IVec = with 0 as __ci_expr_seq_20 {
        var __ci_expr_lit_1: [i32; 14] = [6, 7, 8, 9, 10, 11, 12, 20, 30, 40, 50, 60, 70, 80]
        unsafe { IVec_from_n((&__ci_expr_lit_1[0] as *mut i32), (14 as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IVec_eq(((&raw mut __local_res as *mut IVec) as *const IVec), ((&raw mut __local_d as *mut IVec) as *const IVec)) } as bool), c"vec_test.c".ptr, (16 as i32))

    assert_compare((1 as i32), c"==".ptr, (14 as i64), (unsafe { (*((&raw mut __local_d as *mut IVec) as *const IVec)).size() } as i64), c"vec_test.c".ptr, (17 as i32))

    unsafe { IVec_erase_n((&raw mut __local_d as *mut IVec), (7 as i64), (4 as i64)) }

    var __ci_expr_lit_2: [i32; 10] = [6, 7, 8, 9, 10, 11, 12, 60, 70, 80]

    unsafe { (*(&raw mut __local_res as *mut IVec)).take(unsafe { IVec_from_n((&__ci_expr_lit_2[0] as *mut i32), (10 as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { IVec_eq(((&raw mut __local_res as *mut IVec) as *const IVec), ((&raw mut __local_d as *mut IVec) as *const IVec)) } as bool), c"vec_test.c".ptr, (22 as i32))

    var __local_nums: List[i32] = [200, 300, 400, 500]

    unsafe { IVec_insert_n((&raw mut __local_d as *mut IVec), (7 as i64), (&__local_nums[0] as *mut i32), (4 as i64)) }

    var __ci_expr_lit_3: [i32; 14] = [6, 7, 8, 9, 10, 11, 12, 200, 300, 400, 500, 60, 70, 80]

    unsafe { (*(&raw mut __local_res as *mut IVec)).take(unsafe { IVec_from_n((&__ci_expr_lit_3[0] as *mut i32), (14 as i64)) }) }


    assert_bool((1 as i32), (true as bool), (unsafe { IVec_eq(((&raw mut __local_res as *mut IVec) as *const IVec), ((&raw mut __local_d as *mut IVec) as *const IVec)) } as bool), c"vec_test.c".ptr, (28 as i32))

    assert_compare((1 as i32), c"==".ptr, (14 as i64), (unsafe { (*((&raw mut __local_d as *mut IVec) as *const IVec)).size() } as i64), c"vec_test.c".ptr, (30 as i32))

    assert_compare((1 as i32), c"==".ptr, (200 as i64), ((unsafe *unsafe { IVec_at(((&raw mut __local_d as *mut IVec) as *const IVec), (7 as i64)) }) as i64), c"vec_test.c".ptr, (31 as i32))

    loop {
        var __local__c_i2: ctest_vec_basics_run__c_i2_anon = ctest_vec_basics_run__c_i2_anon.zeroed()

        var __ci_expr_lit_4: [*mut IVec; 2] = [(&raw mut __local_d as *mut IVec), (&raw mut __local_res as *mut IVec)]

        __local__c_i2 = ctest_vec_basics_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_4)[0] as *mut *mut IVec) as *const *mut IVec)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon))._ref as *mut *mut IVec)
        __local__c_i2.size = (((((2 * (sizeof[usize]() as usize)) as u64) / (sizeof[IVec]() as u64))) as i32)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { IVec_drop(((*((*(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon)).ref)) as *const IVec)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

impl IVec {
    pub mut fn move_() -> IVec {
        let __param_self_: *mut IVec = self as *mut IVec
        var __local_m: IVec = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).data = ((null as *mut i32)))

        return __local_m

    }

    pub mut fn take(__param_unowned: IVec) -> Unit {
        let __param_self_: *mut IVec = self as *mut IVec
        unsafe { IVec_drop((__param_self_ as *const IVec)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IVec]())

    }

    pub mut fn push(__param_value: i32) -> *mut i32 {
        let __param_self_: *mut IVec = self as *mut IVec
        if ((if (unsafe *__param_self_).size == (unsafe *__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not unsafe { IVec_reserve(__param_self_, ((((*__param_self_).size * 2) + 4) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut i32))
            }
        }

        var __local_v: *mut i32 = with 0 as __ci_expr_seq_10 {
            var __ci_expr_old_0: i64 = (unsafe *__param_self_).size
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size + 1)
            ((unsafe *__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
        }

        ((unsafe *__local_v) = __param_value)

        return __local_v

    }

    pub fn value_clone(__param_val: i32) -> i32 {
        let __param_self_: *const IVec = self as *const IVec

        return __param_val

    }

    pub fn size() -> i64 {
        let __param_self_: *const IVec = self as *const IVec
        return (unsafe *__param_self_).size

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const IVec = self as *const IVec
        return (unsafe *__param_self_).capacity

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const IVec = self as *const IVec
        return ((((not ((unsafe *__param_self_).size != 0))) as bool))

    }

    pub mut fn pop() {
        let __param_self_: *mut IVec = self as *mut IVec
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IVec_pop".ptr, c"vec.h".ptr, (151 as i32), c"self->size".ptr)
        } else {
            0
        }

        var __local_p: *mut i32 = with 0 as __ci_expr_seq_8 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)
            ((&raw const (unsafe (*__param_self_).data[(*__param_self_).size]) as *const i32) as *mut i32)
        }


    }

    pub mut fn pull() -> i32 {
        let __param_self_: *mut IVec = self as *mut IVec
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IVec_pull".ptr, c"vec.h".ptr, (153 as i32), c"self->size".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)

        return (unsafe (*__param_self_).data[(*__param_self_).size])


    }

    pub mut fn push_back(__param_value: i32) -> *mut i32 {
        let __param_self_: *mut IVec = self as *mut IVec
        return ((unsafe { (*__param_self_).push(__param_value) } as *mut i32))

    }

    pub mut fn pop_back() {
        let __param_self_: *mut IVec = self as *mut IVec
        unsafe { (*__param_self_).pop() }

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut IVec = self as *mut IVec
        unsafe { IVec_reserve(__param_self_, (9223372036854775807 as i64)) }

    }

    pub mut fn insert_at(__param_it_: IVec_iter, __param_value: i32) -> IVec_iter {
        let __param_self_: *mut IVec = self as *mut IVec
        return unsafe { IVec_insert_n(__param_self_, ((((((if (*(&raw const __param_it_ as *const IVec_iter)).ref != null: (*(&raw const __param_it_ as *const IVec_iter)).ref else: (*(&raw const __param_it_ as *const IVec_iter)).end) as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[i32]() as i64)) as i64), ((&raw const __param_value as *const i32) as *mut i32), (1 as i64)) }

    }

    pub mut fn erase_at(__param_it_: IVec_iter) -> IVec_iter {
        let __param_self_: *mut IVec = self as *mut IVec
        return unsafe { IVec_erase_n(__param_self_, ((((((*(&raw const __param_it_ as *const IVec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[i32]() as i64)) as i64), (1 as i64)) }

    }

    pub mut fn erase_range(__param_i1: IVec_iter, __param_i2: IVec_iter) -> IVec_iter {
        let __param_self_: *mut IVec = self as *mut IVec
        var __ci_expr_ternary_1: *mut i32 = null

        var __ci_expr_logic_0: i32 = 0

        if ((unsafe *(&raw const __param_i1 as *const IVec_iter)).ref != null) {
            (__ci_expr_logic_0 = (if (if not ((unsafe *(&raw const __param_i2 as *const IVec_iter)).ref != null): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_ternary_1 = (unsafe *(&raw const __param_i1 as *const IVec_iter)).end)
        } else {
            (__ci_expr_ternary_1 = (unsafe *(&raw const __param_i2 as *const IVec_iter)).ref)
        }

        return unsafe { IVec_erase_n(__param_self_, ((((((*(&raw const __param_i1 as *const IVec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[i32]() as i64)) as i64), (((((__ci_expr_ternary_1 as usize) -% ((*(&raw const __param_i1 as *const IVec_iter)).ref as usize)) as i64) / (sizeof[i32]() as i64)) as i64)) }


    }

    pub fn begin() -> IVec_iter {
        let __param_self_: *const IVec = self as *const IVec
        var __local_it_: IVec_iter = IVec_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if ((unsafe *__param_self_).size != 0) {
            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const IVec_iter)).end + (((unsafe *__param_self_).size as i64) as usize))
        } else {
            (__local_it_.ref = ((null as *mut i32)))
        }

        return __local_it_

    }

    pub fn rbegin() -> IVec_iter {
        let __param_self_: *const IVec = self as *const IVec
        var __local_it_: IVec_iter = IVec_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if ((unsafe *__param_self_).size != 0) {
            (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const IVec_iter)).ref + ((((unsafe *__param_self_).size - 1) as i64) as usize))

            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const IVec_iter)).end - ((1 as i64) as usize))

        } else {
            (__local_it_.ref = ((null as *mut i32)))
        }

        return __local_it_

    }

    pub fn end() -> IVec_iter {
        let __param_self_: *const IVec = self as *const IVec

        var __local_it_: IVec_iter = IVec_iter.zeroed()

        return __local_it_

    }

    pub fn rend() -> IVec_iter {
        let __param_self_: *const IVec = self as *const IVec

        var __local_it_: IVec_iter = IVec_iter.zeroed()

        return __local_it_

    }

    pub fn index(__param_it_: IVec_iter) -> i64 {
        let __param_self_: *const IVec = self as *const IVec
        return (((((unsafe *(&raw const __param_it_ as *const IVec_iter)).ref as usize) -% ((unsafe *__param_self_).data as usize)) as i64) / (sizeof[i32]() as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut IVec = self as *mut IVec
        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

    }

    pub fn find(__param_raw: i32) -> IVec_iter {
        let __param_self_: *const IVec = self as *const IVec
        return unsafe { IVec_find_in(__param_self_, unsafe { (*__param_self_).begin() }, unsafe { (*__param_self_).end() }, __param_raw) }

    }

    pub fn contains(__param_raw: i32) -> bool {
        let __param_self_: *const IVec = self as *const IVec
        return ((((unsafe { (*__param_self_).find(__param_raw) }.ref != null)) as bool))

    }

}

impl IVec_iter {
    pub mut fn next() {
        let __param_it_: *mut IVec_iter = self as *mut IVec_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut i32)))
        }


    }

    pub mut fn rnext() {
        let __param_it_: *mut IVec_iter = self as *mut IVec_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut i32)))
        }


    }

}

var ctest_vec_basics: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("vec" as *mut c_char) as *const c_char), ttname: (("basics" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_vec_basics_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_vec_basics_run()
    print("ran vec.basics")
    return ctest_failure_count()
