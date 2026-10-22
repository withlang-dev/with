// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
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

unsafe fn IVec_drop(__param_cself: *const IVec) {
    var __local_self_: *mut IVec = ((__param_cself as *mut IVec))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    IVec_clear(__local_self_)

    (sizeof[c_int]() as usize)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))


}

unsafe fn IVec_clear(__param_self_: *mut IVec) {
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

unsafe fn IVec_reserve(__param_self_: *mut IVec, __param_cap: c_long) -> bool {
    var __local_n: c_long = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as c_long))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as c_int) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as c_int)) != 0) {
        var __local_d: *mut c_int = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[c_int]() as c_long)) as c_long) else: (((*__param_self_).capacity * (sizeof[c_int]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_int))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return false
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((*__param_self_).data != null))

}

unsafe fn IVec_resize(__param_self_: *mut IVec, __param_len: c_long, __param_null_: c_int) -> bool {
    if ((if not IVec_reserve(__param_self_, __param_len): 1 else: 0) != 0) {
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

unsafe fn IVec_erase_n(__param_self_: *mut IVec, __param_idx: c_long, __param_len: c_long) -> IVec_iter {
    if (((if not ((if (__param_idx + __param_len) <= (*__param_self_).size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_erase_n".ptr, c"vec.h".ptr, (337 as c_int), c"idx + len <= self->size".ptr)
    } else {
        0
    }

    var __local_d: *mut c_int = ((*__param_self_).data + ((__param_idx as c_long) as usize))

    var __local_p: *mut c_int = __local_d

    var __local_end: *mut c_int = ((*__param_self_).data + (((*__param_self_).size as c_long) as usize))


    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __param_len: 1 else: 0) != 0) {


        (__local_i = __local_i + 1)

        (__local_p = __local_p + 1)


    }


    with_memmove(((__local_d as *mut c_void) as *mut u8), ((__local_p as *const c_void) as *const u8), ((((((((__local_end as usize) -% (__local_p as usize)) as c_long) / (sizeof[c_int]() as c_long)) as c_ulong) *% (sizeof[c_int]() as c_ulong)) as c_ulong) as i64))

    ((*__param_self_).size = (*__param_self_).size - __param_len)

    return ((IVec_iter { ref: (if __local_p == __local_end: ((null) as *mut c_int) else: __local_d), end: (__local_end - ((__param_len as c_long) as usize)) } as IVec_iter))

}

unsafe fn IVec_insert_uninit(__param_self_: *mut IVec, __param_idx: c_long, __param_n: c_long) -> IVec_iter {
    if ((if ((*__param_self_).size + __param_n) >= (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not IVec_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + __param_n) as c_long)): 1 else: 0) != 0) {
            return IVec_end((__param_self_ as *const IVec))
        }
    }

    var __local_pos: *mut c_int = ((*__param_self_).data + ((__param_idx as c_long) as usize))

    with_memmove((((__local_pos + ((__param_n as c_long) as usize)) as *mut c_void) as *mut u8), ((__local_pos as *const c_void) as *const u8), (((if 1 != 0: ((((*__param_self_).size - __param_idx) * (sizeof[c_int]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((IVec_iter { ref: __local_pos, end: ((*__param_self_).data + (((*__param_self_).size as c_long) as usize)) } as IVec_iter))

}

unsafe fn IVec_find_in(__param_self_: *const IVec, __param_i1: IVec_iter, __param_i2: IVec_iter, __param_raw: c_int) -> IVec_iter {

    var __local_p2: *const c_int = with 0 as __ci_expr_seq_15 {
        var __ci_expr_ternary_1: *mut c_int = null
        var __ci_expr_logic_0: c_int = 0
        if ((*(&raw const __param_i1 as *const IVec_iter)).ref != null) {
            (__ci_expr_logic_0 = (if (if not ((*(&raw const __param_i2 as *const IVec_iter)).ref != null): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_ternary_1 = (*(&raw const __param_i1 as *const IVec_iter)).end)
        } else {
            (__ci_expr_ternary_1 = (*(&raw const __param_i2 as *const IVec_iter)).ref)
        }
        (__ci_expr_ternary_1 as *const c_int)
    }

    while ((if (*(&raw const __param_i1 as *const IVec_iter)).ref != __local_p2: 1 else: 0) != 0) {
        var __local_r: c_int = (*((*(&raw const __param_i1 as *const IVec_iter)).ref))

        if ((if (*(&raw mut __param_raw as *mut c_int)) == (*(&raw const __local_r as *const c_int)): 1 else: 0) != 0) {
            return __param_i1
        }


        (__param_i1.ref = (*(&raw const __param_i1 as *const IVec_iter)).ref + 1)

    }

    (__param_i2.ref = ((null as *mut c_int)))

    return __param_i2

}

unsafe fn IVec_value_drop(__param_self_: *const IVec, __param_val: *mut c_int) {
    return
}

unsafe fn IVec_move(__param_self_: *mut IVec) -> IVec {
    var __local_m: IVec = (*__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).data = ((null as *mut c_int)))

    return __local_m

}

unsafe fn IVec_take(__param_self_: *mut IVec, __param_unowned: IVec) -> Unit {
    IVec_drop((__param_self_ as *const IVec))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IVec]())

}

unsafe fn IVec_push(__param_self_: *mut IVec, __param_value: c_int) -> *mut c_int {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not IVec_reserve(__param_self_, ((((*__param_self_).size * 2) + 4) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut c_int))
        }
    }

    var __local_v: *mut c_int = with 0 as __ci_expr_seq_10 {
        var __ci_expr_old_0: c_long = (*__param_self_).size
        ((*__param_self_).size = (*__param_self_).size + 1)
        ((*__param_self_).data + ((__ci_expr_old_0 as c_long) as usize))
    }

    ((*__local_v) = __param_value)

    return __local_v

}

unsafe fn IVec_put_n(__param_self_: *mut IVec, __param_raw: *const c_int, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        IVec_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

unsafe fn IVec_copy(__param_self_: *mut IVec, __param_other: *const IVec) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    IVec_clear(__param_self_)

    IVec_reserve(__param_self_, (*__param_other).size)

    ((*__param_self_).size = (*__param_other).size)

    var __local_i: c_long = ((0 as c_long))

    var __local__c_end_i: c_long = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        (((*__param_self_).data[__local_i]) = ((((*__param_other).data[__local_i]) as c_int)))

        (__local_i = __local_i + 1)

    }


}

unsafe fn IVec_copy_to(__param_self_: *mut IVec, __param_idx: c_long, __param_arr: *mut c_int, __param_n: c_long) -> IVec_iter {
    var __local_arr = __param_arr
    var __local_it_: IVec_iter = IVec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const IVec_iter)).ref != null) {
        var __local_p: *mut c_int = (*(&raw const __local_it_ as *const IVec_iter)).ref

        var __local_q: *mut c_int = (__local_p + ((__param_n as c_long) as usize))


        while ((if __local_p != __local_q: 1 else: 0) != 0) {
            var __ci_expr_old_0: *mut c_int = __local_p

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



    (__local_out.data = ((null as *mut c_int)))

    (__local_out.capacity = ((0 as c_long)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const IVec)).capacity)


    unsafe { IVec_reserve((&raw mut __local_out as *mut IVec), (*(&raw const __param_vec as *const IVec)).size) }

    (__local_out.size = (unsafe *(&raw const __param_vec as *const IVec)).size)

    var __local_i: c_long = ((0 as c_long))

    var __local__c_end_i: c_long = (unsafe *(&raw const __param_vec as *const IVec)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_vec as *const IVec)).data[__local_i]) as c_int)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

unsafe fn IVec_value_clone(__param_self_: *const IVec, __param_val: c_int) -> c_int {

    return __param_val

}

unsafe fn IVec_size(__param_self_: *const IVec) -> c_long {
    return (*__param_self_).size

}

unsafe fn IVec_capacity(__param_self_: *const IVec) -> c_long {
    return (*__param_self_).capacity

}

unsafe fn IVec_is_empty(__param_self_: *const IVec) -> bool {
    return ((not ((*__param_self_).size != 0)))

}

unsafe fn IVec_value_toraw(__param_val: *const c_int) -> c_int {
    return (*__param_val)

}

unsafe fn IVec_front(__param_self_: *const IVec) -> *const c_int {
    return (((*__param_self_).data as *const c_int))

}

unsafe fn IVec_front_mut(__param_self_: *mut IVec) -> *mut c_int {
    return (*__param_self_).data

}

unsafe fn IVec_back(__param_self_: *const IVec) -> *const c_int {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const c_int) as *mut c_int) as *const c_int))

}

unsafe fn IVec_back_mut(__param_self_: *mut IVec) -> *mut c_int {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const c_int) as *mut c_int))

}

unsafe fn IVec_pop(__param_self_: *mut IVec) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_pop".ptr, c"vec.h".ptr, (151 as c_int), c"self->size".ptr)
    } else {
        0
    }

    var __local_p: *mut c_int = with 0 as __ci_expr_seq_8 {
        ((*__param_self_).size = (*__param_self_).size - 1)
        ((&raw const ((*__param_self_).data[(*__param_self_).size]) as *const c_int) as *mut c_int)
    }


}

unsafe fn IVec_pull(__param_self_: *mut IVec) -> c_int {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_pull".ptr, c"vec.h".ptr, (153 as c_int), c"self->size".ptr)
    } else {
        0
    }

    ((*__param_self_).size = (*__param_self_).size - 1)

    return ((*__param_self_).data[(*__param_self_).size])


}

unsafe fn IVec_push_back(__param_self_: *mut IVec, __param_value: c_int) -> *mut c_int {
    return ((IVec_push(__param_self_, __param_value) as *mut c_int))

}

unsafe fn IVec_pop_back(__param_self_: *mut IVec) {
    IVec_pop(__param_self_)

}

fn IVec_init() -> IVec {
    return ((IVec.zeroed() as IVec))

}

fn IVec_with_capacity(__param_cap: c_long) -> IVec {
    var __local_out: IVec = IVec { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[c_int]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_int)), size: 0, capacity: __param_cap }

    return __local_out

}

fn IVec_with_size_uninit(__param_size: c_long) -> IVec {
    var __local_out: IVec = IVec { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[c_int]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_int)), size: __param_size, capacity: __param_size }

    return __local_out

}

fn IVec_with_size(__param_size: c_long, __param_default_raw: c_int) -> IVec {
    var __local_size = __param_size
    var __local_out: IVec = IVec { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[c_int]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_int)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

unsafe fn IVec_from_n(__param_raw: *const c_int, __param_n: c_long) -> IVec {
    var __local_out: IVec = IVec_with_capacity(__param_n)

    IVec_put_n((&raw mut __local_out as *mut IVec), __param_raw, __param_n)

    return __local_out

}

unsafe fn IVec_shrink_to_fit(__param_self_: *mut IVec) -> Unit {
    IVec_reserve(__param_self_, (9223372036854775807 as c_long))

}

unsafe fn IVec_insert_n(__param_self_: *mut IVec, __param_idx: c_long, __param_arr: *mut c_int, __param_n: c_long) -> IVec_iter {
    var __local_it_: IVec_iter = IVec_insert_uninit(__param_self_, __param_idx, __param_n)

    if ((*(&raw const __local_it_ as *const IVec_iter)).ref != null) {
        with_memcpy((((*(&raw const __local_it_ as *const IVec_iter)).ref as *mut c_void) as *mut u8), ((&(__param_arr[0]) as *mut c_int) as *const u8), (((if 1 != 0: ((__param_n * (sizeof[c_int]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))
    }

    return __local_it_

}

unsafe fn IVec_insert_at(__param_self_: *mut IVec, __param_it_: IVec_iter, __param_value: c_int) -> IVec_iter {
    return IVec_insert_n(__param_self_, ((((((if (*(&raw const __param_it_ as *const IVec_iter)).ref != null: (*(&raw const __param_it_ as *const IVec_iter)).ref else: (*(&raw const __param_it_ as *const IVec_iter)).end) as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[c_int]() as c_long)) as c_long), ((&raw const __param_value as *const c_int) as *mut c_int), (1 as c_long))

}

unsafe fn IVec_erase_at(__param_self_: *mut IVec, __param_it_: IVec_iter) -> IVec_iter {
    return IVec_erase_n(__param_self_, ((((((*(&raw const __param_it_ as *const IVec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[c_int]() as c_long)) as c_long), (1 as c_long))

}

unsafe fn IVec_erase_range(__param_self_: *mut IVec, __param_i1: IVec_iter, __param_i2: IVec_iter) -> IVec_iter {
    var __ci_expr_ternary_1: *mut c_int = null

    var __ci_expr_logic_0: c_int = 0

    if ((*(&raw const __param_i1 as *const IVec_iter)).ref != null) {
        (__ci_expr_logic_0 = (if (if not ((*(&raw const __param_i2 as *const IVec_iter)).ref != null): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = (*(&raw const __param_i1 as *const IVec_iter)).end)
    } else {
        (__ci_expr_ternary_1 = (*(&raw const __param_i2 as *const IVec_iter)).ref)
    }

    return IVec_erase_n(__param_self_, ((((((*(&raw const __param_i1 as *const IVec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[c_int]() as c_long)) as c_long), (((((__ci_expr_ternary_1 as usize) -% ((*(&raw const __param_i1 as *const IVec_iter)).ref as usize)) as c_long) / (sizeof[c_int]() as c_long)) as c_long))


}

unsafe fn IVec_at(__param_self_: *const IVec, __param_idx: c_long) -> *const c_int {
    if (((if not ((if ((__param_idx as c_ulong)) < (((*__param_self_).size as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_at".ptr, c"vec.h".ptr, (206 as c_int), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as c_long) as usize)) as *const c_int))

}

unsafe fn IVec_at_mut(__param_self_: *mut IVec, __param_idx: c_long) -> *mut c_int {
    if (((if not ((if ((__param_idx as c_ulong)) < (((*__param_self_).size as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_at_mut".ptr, c"vec.h".ptr, (210 as c_int), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as c_long) as usize)) as *mut c_int))

}

unsafe fn IVec_begin(__param_self_: *const IVec) -> IVec_iter {
    var __local_it_: IVec_iter = IVec_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.end = (*(&raw const __local_it_ as *const IVec_iter)).end + (((*__param_self_).size as c_long) as usize))
    } else {
        (__local_it_.ref = ((null as *mut c_int)))
    }

    return __local_it_

}

unsafe fn IVec_rbegin(__param_self_: *const IVec) -> IVec_iter {
    var __local_it_: IVec_iter = IVec_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const IVec_iter)).ref + ((((*__param_self_).size - 1) as c_long) as usize))

        (__local_it_.end = (*(&raw const __local_it_ as *const IVec_iter)).end - ((1 as c_long) as usize))

    } else {
        (__local_it_.ref = ((null as *mut c_int)))
    }

    return __local_it_

}

unsafe fn IVec_end(__param_self_: *const IVec) -> IVec_iter {

    var __local_it_: IVec_iter = IVec_iter.zeroed()

    return __local_it_

}

unsafe fn IVec_rend(__param_self_: *const IVec) -> IVec_iter {

    var __local_it_: IVec_iter = IVec_iter.zeroed()

    return __local_it_

}

unsafe fn IVec_next(__param_it_: *mut IVec_iter) {
    ((*__param_it_).ref = (*__param_it_).ref + 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut c_int)))
    }


}

unsafe fn IVec_rnext(__param_it_: *mut IVec_iter) {
    ((*__param_it_).ref = (*__param_it_).ref - 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut c_int)))
    }


}

fn IVec_advance(__param_it_: IVec_iter, __param_n: c_ulong) -> IVec_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const IVec_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const IVec_iter)).ref >= (unsafe *(&raw const __param_it_ as *const IVec_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut c_int)))
    }


    return __param_it_

}

unsafe fn IVec_index(__param_self_: *const IVec, __param_it_: IVec_iter) -> c_long {
    return (((((*(&raw const __param_it_ as *const IVec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as c_long) / (sizeof[c_int]() as c_long))

}

unsafe fn IVec_adjust_end_(__param_self_: *mut IVec, __param_n: c_long) {
    ((*__param_self_).size = (*__param_self_).size + __param_n)

}

unsafe fn IVec_find(__param_self_: *const IVec, __param_raw: c_int) -> IVec_iter {
    return IVec_find_in(__param_self_, IVec_begin(__param_self_), IVec_end(__param_self_), __param_raw)

}

unsafe fn IVec_contains(__param_self_: *const IVec, __param_raw: c_int) -> bool {
    return ((IVec_find(__param_self_, __param_raw).ref != null))

}

unsafe fn IVec_eq(__param_self_: *const IVec, __param_other: *const IVec) -> bool {
    return ((with_memcmp((((*__param_self_).data as *const c_void) as *const u8), (((*__param_other).data as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).size * (sizeof[c_int]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) == 0))

}

@[repr(C)]
pub type ctest_vec_basics_run__c_i2_anon { _ref: *const *mut IVec = null, ref: *mut *mut IVec = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_vec_basics_run__c_i2_anon
fn ctest_vec_basics_run() {
    var __local_d: IVec = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [c_int; 12] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        unsafe { IVec_from_n((&__ci_expr_lit_0[0] as *mut c_int), (12 as c_long)) }
    }

    assert_compare((1 as c_int), c"==".ptr, (12 as c_long), (unsafe { IVec_size(((&raw mut __local_d as *mut IVec) as *const IVec)) } as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (9 as c_int))

    unsafe { IVec_erase_n((&raw mut __local_d as *mut IVec), (0 as c_long), (5 as c_long)) }

    var __local_i: c_int = ((2 as c_int))

    var __local__c_end_i: c_int = ((9 as c_int))


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        unsafe { IVec_push_back((&raw mut __local_d as *mut IVec), ((__local_i * 10) as c_int)) }

        (__local_i = __local_i + 1)

    }


    var __local_res: IVec = with 0 as __ci_expr_seq_20 {
        var __ci_expr_lit_1: [c_int; 14] = [6, 7, 8, 9, 10, 11, 12, 20, 30, 40, 50, 60, 70, 80]
        unsafe { IVec_from_n((&__ci_expr_lit_1[0] as *mut c_int), (14 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IVec_eq(((&raw mut __local_res as *mut IVec) as *const IVec), ((&raw mut __local_d as *mut IVec) as *const IVec)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (16 as c_int))

    assert_compare((1 as c_int), c"==".ptr, (14 as c_long), (unsafe { IVec_size(((&raw mut __local_d as *mut IVec) as *const IVec)) } as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (17 as c_int))

    unsafe { IVec_erase_n((&raw mut __local_d as *mut IVec), (7 as c_long), (4 as c_long)) }

    var __ci_expr_lit_2: [c_int; 10] = [6, 7, 8, 9, 10, 11, 12, 60, 70, 80]

    unsafe { IVec_take((&raw mut __local_res as *mut IVec), unsafe { IVec_from_n((&__ci_expr_lit_2[0] as *mut c_int), (10 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { IVec_eq(((&raw mut __local_res as *mut IVec) as *const IVec), ((&raw mut __local_d as *mut IVec) as *const IVec)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (22 as c_int))

    var __local_nums: List[c_int] = [200, 300, 400, 500]

    unsafe { IVec_insert_n((&raw mut __local_d as *mut IVec), (7 as c_long), (&__local_nums[0] as *mut c_int), (4 as c_long)) }

    var __ci_expr_lit_3: [c_int; 14] = [6, 7, 8, 9, 10, 11, 12, 200, 300, 400, 500, 60, 70, 80]

    unsafe { IVec_take((&raw mut __local_res as *mut IVec), unsafe { IVec_from_n((&__ci_expr_lit_3[0] as *mut c_int), (14 as c_long)) }) }


    assert_bool((1 as c_int), (true as bool), (unsafe { IVec_eq(((&raw mut __local_res as *mut IVec) as *const IVec), ((&raw mut __local_d as *mut IVec) as *const IVec)) } as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (28 as c_int))

    assert_compare((1 as c_int), c"==".ptr, (14 as c_long), (unsafe { IVec_size(((&raw mut __local_d as *mut IVec) as *const IVec)) } as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (30 as c_int))

    assert_compare((1 as c_int), c"==".ptr, (200 as c_long), ((unsafe *unsafe { IVec_at(((&raw mut __local_d as *mut IVec) as *const IVec), (7 as c_long)) }) as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-vec_test/vec_test.c".ptr, (31 as c_int))

    loop {
        var __local__c_i2: ctest_vec_basics_run__c_i2_anon = ctest_vec_basics_run__c_i2_anon.zeroed()

        var __ci_expr_lit_4: [*mut IVec; 2] = [(&raw mut __local_d as *mut IVec), (&raw mut __local_res as *mut IVec)]

        __local__c_i2 = ctest_vec_basics_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_4)[0] as *mut *mut IVec) as *const *mut IVec)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_vec_basics_run__c_i2_anon))._ref as *mut *mut IVec)
        __local__c_i2.size = (((((2 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[IVec]() as c_ulong))) as c_int)


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

var ctest_vec_basics: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("vec" as *mut c_char) as *const c_char), ttname: (("basics" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_vec_basics_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_vec_basics_run()
    print("ran vec.basics")
    return ctest_failure_count()
