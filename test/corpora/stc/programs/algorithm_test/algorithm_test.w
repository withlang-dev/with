// Migrated from C
use std.stc_testing.defs
use std.stc_testing.harness
use std.stc_testing.utf8_misc
use std.stc_testing.cstr_utf8
use std.stc_testing.ucd
use std.stc_testing.cstr_core
use std.stc_testing.cstr_misc
use std.stc_testing.cstr_io
use std.stc_testing.cspan
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

unsafe fn IVec_move(__param_self_: *mut IVec) -> IVec {
    var __local_m: IVec = (*__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).data = ((null as *mut c_int)))

    return __local_m

}

unsafe fn IVec_capacity(__param_self_: *const IVec) -> c_long {
    return (*__param_self_).capacity

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

unsafe fn IVec_drop(__param_cself: *const IVec) {
    var __local_self_: *mut IVec = ((__param_cself as *mut IVec))

    IVec_clear(__local_self_)

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    (sizeof[c_int]() as usize)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))


}

unsafe fn IVec_take(__param_self_: *mut IVec, __param_unowned: IVec) -> Unit {
    IVec_drop((__param_self_ as *const IVec))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IVec]())

}

unsafe fn IVec_size(__param_self_: *const IVec) -> c_long {
    return (*__param_self_).size

}

unsafe fn IVec_is_empty(__param_self_: *const IVec) -> bool {
    return ((not ((*__param_self_).size != 0)))

}

unsafe fn IVec_value_drop(__param_self_: *const IVec, __param_val: *mut c_int) {
    return
}

unsafe fn IVec_append_uninit(__param_self_: *mut IVec, __param_n: c_long) -> *mut c_int {
    var __local_len: c_long = (*__param_self_).size

    if ((if (__local_len + __param_n) >= IVec_capacity((__param_self_ as *const IVec)): 1 else: 0) != 0) {
        if ((if not IVec_reserve(__param_self_, ((((__local_len * 3) / 2) + __param_n) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut c_int))
        }
    }

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((((*__param_self_).data + ((__local_len as c_long) as usize)) as *mut c_int))

}

unsafe fn IVec_shrink_to_fit(__param_self_: *mut IVec) -> Unit {
    IVec_reserve(__param_self_, (9223372036854775807 as c_long))

}

unsafe fn IVec_front(__param_self_: *const IVec) -> *const c_int {
    return ((((&raw const ((*__param_self_).data[0]) as *const c_int) as *mut c_int) as *const c_int))

}

unsafe fn IVec_front_mut(__param_self_: *mut IVec) -> *mut c_int {
    return (((&raw const ((*__param_self_).data[0]) as *const c_int) as *mut c_int))

}

unsafe fn IVec_back(__param_self_: *const IVec) -> *const c_int {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const c_int) as *mut c_int) as *const c_int))

}

unsafe fn IVec_back_mut(__param_self_: *mut IVec) -> *mut c_int {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const c_int) as *mut c_int))

}

unsafe fn IVec_top(__param_self_: *const IVec) -> *const c_int {
    return ((IVec_back(__param_self_) as *const c_int))

}

unsafe fn IVec_top_mut(__param_self_: *mut IVec) -> *mut c_int {
    return ((IVec_back_mut(__param_self_) as *mut c_int))

}

unsafe fn IVec_push(__param_self_: *mut IVec, __param_val: c_int) -> *mut c_int {
    if ((if (*__param_self_).size == IVec_capacity((__param_self_ as *const IVec)): 1 else: 0) != 0) {
        if ((if not IVec_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 4) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut c_int))
        }
    }

    var __local_vp: *mut c_int = with 0 as __ci_expr_seq_10 {
        var __ci_expr_old_0: c_long = (*__param_self_).size
        ((*__param_self_).size = (*__param_self_).size + 1)
        ((*__param_self_).data + ((__ci_expr_old_0 as c_long) as usize))
    }

    ((*__local_vp) = __param_val)

    return __local_vp

}

unsafe fn IVec_pop(__param_self_: *mut IVec) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_pop".ptr, c"stack.h".ptr, (149 as c_int), c"self->size".ptr)
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
        __assert_rtn(c"IVec_pull".ptr, c"stack.h".ptr, (152 as c_int), c"self->size".ptr)
    } else {
        0
    }

    ((*__param_self_).size = (*__param_self_).size - 1)

    return ((*__param_self_).data[(*__param_self_).size])


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

fn IVec_init() -> IVec {
    var __local_out: IVec = IVec.zeroed()

    return __local_out

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

unsafe fn IVec_at(__param_self_: *const IVec, __param_idx: c_long) -> *const c_int {
    if (((if not ((if ((__param_idx as c_ulong)) < (((*__param_self_).size as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_at".ptr, c"stack.h".ptr, (189 as c_int), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as c_long) as usize)) as *const c_int))

}

unsafe fn IVec_at_mut(__param_self_: *mut IVec, __param_idx: c_long) -> *mut c_int {
    if (((if not ((if ((__param_idx as c_ulong)) < (((*__param_self_).size as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IVec_at_mut".ptr, c"stack.h".ptr, (192 as c_int), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as c_long) as usize)) as *mut c_int))

}

fn IVec_clone(__param_stk: IVec) -> IVec {
    var __local_out: IVec = __param_stk

    var __local_self_: *mut IVec = ((&raw mut __local_out as *mut IVec))



    (__local_out.data = ((null as *mut c_int)))

    (__local_out.capacity = ((0 as c_long)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const IVec)).capacity)


    unsafe { IVec_reserve((&raw mut __local_out as *mut IVec), (*(&raw const __param_stk as *const IVec)).size) }

    (__local_out.size = (unsafe *(&raw const __param_stk as *const IVec)).size)

    var __local_i: c_long = ((0 as c_long))

    var __local__c_end_i: c_long = (unsafe *(&raw const __param_stk as *const IVec)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_stk as *const IVec)).data[__local_i]) as c_int)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

unsafe fn IVec_copy(__param_self_: *mut IVec, __param_other: *const IVec) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    IVec_clear(__param_self_)

    IVec_reserve(__param_self_, (*__param_other).size)

    var __local_i: c_long = ((0 as c_long))

    var __local__c_end_i: c_long = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __ci_expr_old_0: c_long = (*__param_self_).size

        ((*__param_self_).size = (*__param_self_).size + 1)

        (((*__param_self_).data[__ci_expr_old_0]) = ((((*__param_other).data[__local_i]) as c_int)))


        (__local_i = __local_i + 1)

    }


}

unsafe fn IVec_value_clone(__param_self_: *const IVec, __param_val: c_int) -> c_int {

    return __param_val

}

unsafe fn IVec_value_toraw(__param_val: *const c_int) -> c_int {
    return (*__param_val)

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

fn crange_make_3(__param_start: c_long, __param_stop: c_long, __param_step: c_long) -> crange {
    var __local_r: crange = crange { start: __param_start, end: (__param_stop - (((if __param_step > 0: 1 else: 0)) as c_long)), step: __param_step }

    return __local_r

}

unsafe fn crange_begin(__param_self_: *mut crange) -> crange_iter {
    ((*__param_self_).value = (*__param_self_).start)

    var __local_it_: crange_iter = crange_iter { ref: ((&raw const (*__param_self_).value as *const c_long) as *mut c_long), end: (*__param_self_).end, step: (*__param_self_).step }

    return __local_it_

}

unsafe fn crange_next(__param_it_: *mut crange_iter) {
    ((*((*__param_it_).ref)) = (*((*__param_it_).ref)) + (*__param_it_).step)

    if ((if (if (*__param_it_).step > 0: 1 else: 0) == (if (*((*__param_it_).ref)) > (*__param_it_).end: 1 else: 0): 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut c_long)))
    }


}

fn crange_advance(__param_it_: crange_iter, __param_n: c_ulong) -> crange_iter {
    ((unsafe *((*(&raw const __param_it_ as *const crange_iter)).ref)) = (unsafe *((*(&raw const __param_it_ as *const crange_iter)).ref)) + ((unsafe *(&raw const __param_it_ as *const crange_iter)).step * (__param_n as c_long)))

    if ((if (if (unsafe *(&raw const __param_it_ as *const crange_iter)).step > 0: 1 else: 0) == (if (unsafe *((*(&raw const __param_it_ as *const crange_iter)).ref)) > (unsafe *(&raw const __param_it_ as *const crange_iter)).end: 1 else: 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut c_long)))
    }


    return __param_it_

}

fn crange32_make_3(__param_start: c_int, __param_stop: c_int, __param_step: c_int) -> crange32 {
    var __local_r: crange32 = crange32 { start: __param_start, end: (__param_stop - ((if __param_step > 0: 1 else: 0))), step: __param_step }

    return __local_r

}

unsafe fn crange32_begin(__param_self_: *mut crange32) -> crange32_iter {
    ((*__param_self_).value = (*__param_self_).start)

    var __local_it_: crange32_iter = crange32_iter { ref: ((&raw const (*__param_self_).value as *const c_int) as *mut c_int), end: (*__param_self_).end, step: (*__param_self_).step }

    return __local_it_

}

unsafe fn crange32_next(__param_it_: *mut crange32_iter) {
    ((*((*__param_it_).ref)) = (*((*__param_it_).ref)) + (*__param_it_).step)

    if ((if (if (*__param_it_).step > 0: 1 else: 0) == (if (*((*__param_it_).ref)) > (*__param_it_).end: 1 else: 0): 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut c_int)))
    }


}

fn crange32_advance(__param_it_: crange32_iter, __param_n: c_uint) -> crange32_iter {
    ((unsafe *((*(&raw const __param_it_ as *const crange32_iter)).ref)) = (unsafe *((*(&raw const __param_it_ as *const crange32_iter)).ref)) + ((unsafe *(&raw const __param_it_ as *const crange32_iter)).step * (__param_n as c_int)))

    if ((if (if (unsafe *(&raw const __param_it_ as *const crange32_iter)).step > 0: 1 else: 0) == (if (unsafe *((*(&raw const __param_it_ as *const crange32_iter)).ref)) > (unsafe *(&raw const __param_it_ as *const crange32_iter)).end: 1 else: 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut c_int)))
    }


    return __param_it_

}

unsafe fn _flt_take(__param_base: *mut _flt_base, __param_n: c_uint) -> bool {
    var __local_k: c_uint = with 0 as __ci_expr_seq_7 {
        ((*__param_base).sn_top = ((*__param_base).sn_top +% 1))
        ((*__param_base).sn[(*__param_base).sn_top] = ((*__param_base).sn[(*__param_base).sn_top] +% 1))
        ((*__param_base).sn[(*__param_base).sn_top] as c_uint)
    }

    ((*__param_base).done = (((((*__param_base).done as c_int) | ((if __local_k >= __param_n: 1 else: 0) as c_int)) as bool)))

    return ((__param_n > 0))

}

unsafe fn _flt_takewhile(__param_base: *mut _flt_base, __param_pred: bool) -> bool {
    var __local_skip: bool = with 0 as __ci_expr_seq_9 {
        var __ci_expr_old_0: u8 = (*__param_base).sb_top
        ((*__param_base).sb_top = ((*__param_base).sb_top +% 1))
        ((*__param_base).sb[__ci_expr_old_0] = (((((*__param_base).sb[__ci_expr_old_0] as c_int) | ((if not __param_pred: 1 else: 0) as c_int)) as bool)))
        (*__param_base).sb[__ci_expr_old_0]
    }

    ((*__param_base).done = (((((*__param_base).done as c_int) | (__local_skip as c_int)) as bool)))

    return ((not __local_skip))

}

unsafe fn c_min_i32n(__param_a: *mut c_int, __param_n: c_long) -> c_int {
    var __local_x: c_int = (((__param_a[0]) as c_int))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as c_int)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_max_i32n(__param_a: *mut c_int, __param_n: c_long) -> c_int {
    var __local_x: c_int = (((__param_a[0]) as c_int))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as c_int)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_min_zin(__param_a: *mut c_long, __param_n: c_long) -> c_long {
    var __local_x: c_long = (((__param_a[0]) as c_long))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as c_long)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_max_zin(__param_a: *mut c_long, __param_n: c_long) -> c_long {
    var __local_x: c_long = (((__param_a[0]) as c_long))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as c_long)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_min_zun(__param_a: *mut c_ulong, __param_n: c_long) -> c_ulong {
    var __local_x: c_ulong = (((__param_a[0]) as c_ulong))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as c_ulong)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_max_zun(__param_a: *mut c_ulong, __param_n: c_long) -> c_ulong {
    var __local_x: c_ulong = (((__param_a[0]) as c_ulong))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as c_ulong)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_min_f32n(__param_a: *mut f32, __param_n: c_long) -> f32 {
    var __local_x: f32 = (((__param_a[0]) as f32))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f32)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_max_f32n(__param_a: *mut f32, __param_n: c_long) -> f32 {
    var __local_x: f32 = (((__param_a[0]) as f32))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f32)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_min_f64n(__param_a: *mut f64, __param_n: c_long) -> f64 {
    var __local_x: f64 = (((__param_a[0]) as f64))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

unsafe fn c_max_f64n(__param_a: *mut f64, __param_n: c_long) -> f64 {
    var __local_x: f64 = (((__param_a[0]) as f64))

    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

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

unsafe fn ISpan_slice_(__param_d: *mut c_int, __param_shape: *mut c_int, __param_stri: *mut c_int, __param_args: *mut [c_long; 3], __param_rank: c_int) -> ISpan {
    var __local_s: ISpan

    var __local_outrank: c_int

    (__local_s.data = __param_d + ((_cspan_slice((&(*(&raw const __local_s as *const ISpan)).shape[0] as *mut c_int), (&(*(&raw const __local_s.stride as *const cspan_tuple1)).d[0] as *mut c_int), (&raw mut __local_outrank as *mut c_int), (&(__param_shape[0]) as *mut c_int), (&(__param_stri[0]) as *mut c_int), (&(__param_args[0]) as *mut [c_long; 3]), __param_rank) as c_long) as usize))

    if (((if not ((if __local_outrank == 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"ISpan_slice_".ptr, c"algorithm_test.c".ptr, (9 as c_int), c"outrank == 1".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn ISpan_begin(__param_self_: *const ISpan) -> ISpan_iter {
    var __ci_expr_ternary_1: *mut c_int = null

    var __ci_expr_logic_0: c_int = 0

    if ((if 1 == 1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_self_).shape[0] == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = ((null as *mut c_int)))
    } else {
        (__ci_expr_ternary_1 = (*__param_self_).data)
    }

    return ((ISpan_iter { ref: __ci_expr_ternary_1, _s: __param_self_ } as ISpan_iter))


}

unsafe fn ISpan_end(__param_self_: *const ISpan) -> ISpan_iter {

    return ((ISpan_iter.zeroed() as ISpan_iter))

}

unsafe fn ISpan_next(__param_it_: *mut ISpan_iter) -> Unit {
    var __local_off: c_long = (((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple1)).d[(1 - 1)] as c_long))

    var __local_done: bool = with 0 as __ci_expr_seq_6 {
        ((*__param_it_).pos[0] = (*__param_it_).pos[0] + 1)
        (((*__param_it_).pos[0] == (*(*__param_it_)._s).shape[0]))
    }

    if __local_done {
        ((*__param_it_).ref = ((null as *mut c_int)))
    } else {
        ((*__param_it_).ref = (*__param_it_).ref + ((__local_off as c_long) as usize))
    }

}

unsafe fn ISpan_size(__param_self_: *const ISpan) -> c_long {
    return _cspan_size((&(*__param_self_).shape[0] as *mut c_int), (1 as c_int))

}

fn ISpan_transposed(__param_sp: ISpan) -> ISpan {
    unsafe { _cspan_transpose((&(*(&raw const __param_sp as *const ISpan)).shape[0] as *mut c_int), (&(*(&raw const __param_sp.stride as *const cspan_tuple1)).d[0] as *mut c_int), (1 as c_int)) }

    return __param_sp

}

fn ISpan_swapped_axes(__param_sp: ISpan, __param_ax1: c_int, __param_ax2: c_int) -> ISpan {
    unsafe { _cspan_swap_axes((&(*(&raw const __param_sp as *const ISpan)).shape[0] as *mut c_int), (&(*(&raw const __param_sp.stride as *const cspan_tuple1)).d[0] as *mut c_int), (1 as c_int), __param_ax1, __param_ax2) }

    return __param_sp

}

unsafe fn ISpan_from_n(__param_dataptr: *mut c_int, __param_n: c_long) -> ISpan {
    return ((ISpan { data: __param_dataptr, shape: [((__param_n) as c_int)], stride: cspan_tuple1 { d: [1] } } as ISpan))

}

unsafe fn ISpan_at(__param_self_: *const ISpan, __param_idx: c_long) -> *const c_int {
    (sizeof[c_int]() as usize)

    if (((if not ((if __param_idx < (*__param_self_).shape[0]: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"ISpan_at".ptr, c"algorithm_test.c".ptr, (9 as c_int), c"(idx) < (self)->shape[0]".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + (((__param_idx * (*(&raw const (*__param_self_).stride as *const cspan_tuple1)).d[0]) as c_long) as usize)) as *const c_int))


}

unsafe fn ISpan_at_mut(__param_self_: *mut ISpan, __param_idx: c_long) -> *mut c_int {
    (sizeof[c_int]() as usize)

    if (((if not ((if __param_idx < (*__param_self_).shape[0]: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"ISpan_at_mut".ptr, c"algorithm_test.c".ptr, (9 as c_int), c"(idx) < (self)->shape[0]".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + (((__param_idx * (*(&raw const (*__param_self_).stride as *const cspan_tuple1)).d[0]) as c_long) as usize)) as *mut c_int))


}

extern fn assert_str(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const i8, __param_real: *const i8, __param_caller: *const i8, __param_line: c_int)
extern fn assert_wstr(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_int, __param_real: *const c_int, __param_caller: *const i8, __param_line: c_int)
extern fn assert_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_interval(__param_diag: c_int, __param_low: c_long, __param_high: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_pointers(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const i8, __param_line: c_int)
extern fn assert_bool(__param_diag: c_int, __param_exp: bool, __param_real: bool, __param_caller: *const i8, __param_line: c_int)
extern fn assert_dbl_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const i8, __param_line: c_int)
extern fn assert_fail(__param_caller: *const i8, __param_line: c_int)
@[repr(C)]
pub type roman { d: c_int = 0, r: *const i8 = null }
impl Copy for roman
@[repr(C)]
pub type to_roman_i_anon { _ref: *const roman = null, ref: *mut roman = null, size: c_int = 0, index: c_int = 0 }
impl Copy for to_roman_i_anon
fn to_roman(__param_value: c_int) -> cstr {
    var __local_value = __param_value
    var __local_result: cstr = cstr.zeroed()


    var __local_i: to_roman_i_anon = to_roman_i_anon.zeroed()

    var __ci_expr_lit_0: [roman; 13] = [roman { d: 1000, r: (("M" as *mut c_char) as *const c_char) }, roman { d: 900, r: (("CM" as *mut c_char) as *const c_char) }, roman { d: 500, r: (("D" as *mut c_char) as *const c_char) }, roman { d: 400, r: (("CD" as *mut c_char) as *const c_char) }, roman { d: 100, r: (("C" as *mut c_char) as *const c_char) }, roman { d: 90, r: (("XC" as *mut c_char) as *const c_char) }, roman { d: 50, r: (("L" as *mut c_char) as *const c_char) }, roman { d: 40, r: (("XL" as *mut c_char) as *const c_char) }, roman { d: 10, r: (("X" as *mut c_char) as *const c_char) }, roman { d: 9, r: (("IX" as *mut c_char) as *const c_char) }, roman { d: 5, r: (("V" as *mut c_char) as *const c_char) }, roman { d: 4, r: (("IV" as *mut c_char) as *const c_char) }, roman { d: 1, r: (("I" as *mut c_char) as *const c_char) }]

    __local_i = to_roman_i_anon.zeroed()
    __local_i._ref = ((&raw const (__ci_expr_lit_0)[0] as *mut roman) as *const roman)
    __local_i.ref = ((unsafe *(&raw const __local_i as *const to_roman_i_anon))._ref as *mut roman)
    __local_i.size = ((([roman { d: 1000, r: (("M" as *mut c_char) as *const c_char) }, roman { d: 900, r: (("CM" as *mut c_char) as *const c_char) }, roman { d: 500, r: (("D" as *mut c_char) as *const c_char) }, roman { d: 400, r: (("CD" as *mut c_char) as *const c_char) }, roman { d: 100, r: (("C" as *mut c_char) as *const c_char) }, roman { d: 90, r: (("XC" as *mut c_char) as *const c_char) }, roman { d: 50, r: (("L" as *mut c_char) as *const c_char) }, roman { d: 40, r: (("XL" as *mut c_char) as *const c_char) }, roman { d: 10, r: (("X" as *mut c_char) as *const c_char) }, roman { d: 9, r: (("IX" as *mut c_char) as *const c_char) }, roman { d: 5, r: (("V" as *mut c_char) as *const c_char) }, roman { d: 4, r: (("IV" as *mut c_char) as *const c_char) }, roman { d: 1, r: (("I" as *mut c_char) as *const c_char) }].len() as c_ulong)) as c_int)


    while ((if (unsafe *(&raw const __local_i as *const to_roman_i_anon)).index < (unsafe *(&raw const __local_i as *const to_roman_i_anon)).size: 1 else: 0) != 0) {
        while ((if __local_value >= (unsafe *(*(&raw const __local_i as *const to_roman_i_anon)).ref).d: 1 else: 0) != 0) {
            unsafe { cstr_append((&raw mut __local_result as *mut cstr), (*(*(&raw const __local_i as *const to_roman_i_anon)).ref).r) }

            (__local_value = __local_value - (unsafe *(*(&raw const __local_i as *const to_roman_i_anon)).ref).d)

        }


        (__local_i.ref = (unsafe *(&raw const __local_i as *const to_roman_i_anon)).ref + 1)

        (__local_i.index = (unsafe *(&raw const __local_i as *const to_roman_i_anon)).index + 1)


    }


    return __local_result

}

fn ctest_algorithm_cstr_append_run() {
    var __local__c_i4: c_int = ((0 as c_int))

    while ((if __local__c_i4 == 0: 1 else: 0) != 0) {
        var __local_s: cstr = to_roman((2024 as c_int))

        while true {
            var __ci_expr_old_0: c_int = __local__c_i4

            (__local__c_i4 = __local__c_i4 + 1)

            if (not ((if __ci_expr_old_0 == 0: 1 else: 0) != 0)) {
                break
            }

            assert_str((1 as c_int), c"==".ptr, c"MMXXIV".ptr, unsafe { cstr_str(((&raw mut __local_s as *mut cstr) as *const cstr)) }, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (40 as c_int))

            unsafe { cstr_drop(((&raw mut __local_s as *mut cstr) as *const cstr)) }

        }

    }


}

fn ctest_algorithm_c_find_if_run() -> Unit {
    var __local_nums__goto_47_11: ISpan

    var __local_it___goto_49_16: ISpan_iter = ISpan_iter.zeroed()

    var __local__out__goto_50_5: *mut ISpan_iter = null

    var __local_value__goto_50_5: *const c_int = null

    var __local__endref__goto_50_5: *const c_int = null

    var __ci_expr_lit_0: [c_int; 9]

    goto '__ci_bb_0

    '__ci_bb_0 {
        let __ci_copy_33: [c_int; 9] = [1, 1, 2, 3, 5, 8, 13, 21, 34]
        with_memcpy((&raw mut __ci_expr_lit_0 as *mut u8), (&raw const __ci_copy_33 as *const u8), sizeof[[c_int; 9]]())
        (__local_nums__goto_47_11 = unsafe { ISpan_from_n((&__ci_expr_lit_0[0] as *mut c_int), (9 as c_long)) })
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local__out__goto_50_5 = ((&raw mut __local_it___goto_49_16 as *mut ISpan_iter)))
        (__local__endref__goto_50_5 = ((null as *const c_int)))
        let __ci_copy_57: ISpan_iter = unsafe { ISpan_begin(((&raw mut __local_nums__goto_47_11 as *mut ISpan) as *const ISpan)) }
        with_memcpy((&raw mut (unsafe *__local__out__goto_50_5) as *mut u8), (&raw const __ci_copy_57 as *const u8), sizeof[ISpan_iter]())
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if (0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        assert_compare((1 as c_int), c"==".ptr, (13 as c_long), ((unsafe *((*(&raw const __local_it___goto_49_16 as *const ISpan_iter)).ref)) as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (52 as c_int))
        return
    }

    '__ci_bb_4 {
        (__local_value__goto_50_5 = (((unsafe *__local__out__goto_50_5).ref as *const c_int)))
        if ((if __local_value__goto_50_5 != __local__endref__goto_50_5: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_5 {
        if ((if (unsafe *__local_value__goto_50_5) == 13: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_6 {
        unsafe { ISpan_next(__local__out__goto_50_5) }
        goto '__ci_bb_4
    }

    '__ci_bb_7 {
        ((unsafe *__local__out__goto_50_5).ref = ((null as *mut c_int)))
        goto '__ci_bb_10
    }

    '__ci_bb_8 {
        goto '__ci_bb_10
    }

    '__ci_bb_9 {
        goto '__ci_bb_6
    }

    '__ci_bb_10 {
        goto '__ci_bb_2
    }

    __ci_unreachable()

}

fn ctest_algorithm_c_filter_run() {
    var __local_vec: IVec = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [c_int; 10] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 10]
        unsafe { IVec_from_n((&__ci_expr_lit_0[0] as *mut c_int), (10 as c_long)) }
    }

    var __local_sum: c_long = ((0 as c_long))

    loop {
        var __local_fltbase: _flt_base = _flt_base.zeroed()

        var __local__it: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value: *mut c_int = (unsafe *(&raw const __local__it as *const IVec_iter)).ref

        var __local__mapped: c_int = ((0 as c_int))



        while ((((if not (unsafe *(&raw const __local_fltbase as *const _flt_base)).done: 1 else: 0) as c_int) & ((if (unsafe *(&raw const __local__it as *const IVec_iter)).ref != null: 1 else: 0) as c_int)) != 0) {
            var __ci_expr_logic_4: c_int = 0

            var __ci_expr_logic_3: c_int = 0

            var __ci_expr_logic_2: c_int = 0

            var __ci_expr_old_1: u8 = (unsafe *(&raw const __local_fltbase as *const _flt_base)).sb_top

            (__local_fltbase.sb_top = ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sb_top +% 1))

            (__local_fltbase.sb[__ci_expr_old_1] = (((((unsafe *(&raw const __local_fltbase as *const _flt_base)).sb[__ci_expr_old_1] as c_int) | ((if not ((if (((unsafe *__local_value) as c_int) & (1 as c_int)) == 1: 1 else: 0) != 0): 1 else: 0) as c_int)) as bool)))

            if ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sb[__ci_expr_old_1] != 0) {
                (__local_fltbase.sn_top = ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top +% 1))

                (__local_fltbase.sn[(unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top] = ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sn[(unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top] +% 1))

                (__ci_expr_logic_2 = (if (if (unsafe *(&raw const __local_fltbase as *const _flt_base)).sn[(unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top] > 1: 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if (if (((unsafe *__local_value) as c_int) & (1 as c_int)) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if unsafe { _flt_take((&raw mut __local_fltbase as *mut _flt_base), (2 as c_uint)) } != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__local_sum = __local_sum + (unsafe *__local_value))
            }


            unsafe { IVec_next((&raw mut __local__it as *mut IVec_iter)) }

            (__local_value = (unsafe *(&raw const __local__it as *const IVec_iter)).ref)

            (__local_fltbase.sn_top = ((0 as u8)))

            (__local_fltbase.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as c_int), c"==".ptr, (42 as c_long), __local_sum, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (70 as c_int))

    var __local_hash: c_ulonglong = ((0 as c_ulonglong))

    loop {
        var __local_fltbase_1: _flt_base = _flt_base.zeroed()

        var __local__it_1: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_1: *mut c_int = (unsafe *(&raw const __local__it_1 as *const IVec_iter)).ref

        var __local__mapped_1: c_int = ((0 as c_int))



        while ((((if not (unsafe *(&raw const __local_fltbase_1 as *const _flt_base)).done: 1 else: 0) as c_int) & ((if (unsafe *(&raw const __local__it_1 as *const IVec_iter)).ref != null: 1 else: 0) as c_int)) != 0) {
            var __ci_expr_lit_5: [c_ulong; 2] = [(__local_hash as c_ulong), ((unsafe *__local_value_1) as c_ulong)]

            (__local_hash = ((unsafe { c_hash_mix_n((&__ci_expr_lit_5[0] as *mut c_ulong), (2 as c_long)) } as c_ulonglong)))


            unsafe { IVec_next((&raw mut __local__it_1 as *mut IVec_iter)) }

            (__local_value_1 = (unsafe *(&raw const __local__it_1 as *const IVec_iter)).ref)

            (__local_fltbase_1.sn_top = ((0 as u8)))

            (__local_fltbase_1.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as c_int), c"==".ptr, (658 as c_long), (__local_hash as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (74 as c_int))

    (__local_hash = ((0 as c_ulonglong)))

    loop {
        var __local_fltbase_2: _flt_base = _flt_base.zeroed()

        var __local__it_2: IVec_iter = unsafe { IVec_rbegin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_2: *mut c_int = (unsafe *(&raw const __local__it_2 as *const IVec_iter)).ref

        var __local__mapped_2: c_int = ((0 as c_int))



        while ((((if not (unsafe *(&raw const __local_fltbase_2 as *const _flt_base)).done: 1 else: 0) as c_int) & ((if (unsafe *(&raw const __local__it_2 as *const IVec_iter)).ref != null: 1 else: 0) as c_int)) != 0) {
            var __ci_expr_lit_6: [c_ulong; 2] = [(__local_hash as c_ulong), ((unsafe *__local_value_2) as c_ulong)]

            (__local_hash = ((unsafe { c_hash_mix_n((&__ci_expr_lit_6[0] as *mut c_ulong), (2 as c_long)) } as c_ulonglong)))


            unsafe { IVec_rnext((&raw mut __local__it_2 as *mut IVec_iter)) }

            (__local_value_2 = (unsafe *(&raw const __local__it_2 as *const IVec_iter)).ref)

            (__local_fltbase_2.sn_top = ((0 as u8)))

            (__local_fltbase_2.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as c_int), c"==".ptr, (10897 as c_long), (__local_hash as c_long), c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (78 as c_int))

    (__local_sum = ((0 as c_long)))

    loop {
        var __local_fltbase_3: _flt_base = _flt_base.zeroed()

        var __local__it_3: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_3: *mut c_int = (unsafe *(&raw const __local__it_3 as *const IVec_iter)).ref

        var __local__mapped_3: c_int = ((0 as c_int))



        while ((((if not (unsafe *(&raw const __local_fltbase_3 as *const _flt_base)).done: 1 else: 0) as c_int) & ((if (unsafe *(&raw const __local__it_3 as *const IVec_iter)).ref != null: 1 else: 0) as c_int)) != 0) {
            (__local_sum = __local_sum + (unsafe *__local_value_3))

            unsafe { IVec_next((&raw mut __local__it_3 as *mut IVec_iter)) }

            (__local_value_3 = (unsafe *(&raw const __local__it_3 as *const IVec_iter)).ref)

            (__local_fltbase_3.sn_top = ((0 as u8)))

            (__local_fltbase_3.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as c_int), c"==".ptr, (98 as c_long), __local_sum, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (82 as c_int))

    (__local_sum = ((0 as c_long)))

    loop {
        var __local_fltbase_4: _flt_base = _flt_base.zeroed()

        var __local__it_4: IVec_iter = unsafe { IVec_rbegin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_4: *mut c_int = (unsafe *(&raw const __local__it_4 as *const IVec_iter)).ref

        var __local__mapped_4: c_int = ((0 as c_int))



        while ((((if not (unsafe *(&raw const __local_fltbase_4 as *const _flt_base)).done: 1 else: 0) as c_int) & ((if (unsafe *(&raw const __local__it_4 as *const IVec_iter)).ref != null: 1 else: 0) as c_int)) != 0) {
            (__local_sum = __local_sum + (unsafe *__local_value_4))

            unsafe { IVec_rnext((&raw mut __local__it_4 as *mut IVec_iter)) }

            (__local_value_4 = (unsafe *(&raw const __local__it_4 as *const IVec_iter)).ref)

            (__local_fltbase_4.sn_top = ((0 as u8)))

            (__local_fltbase_4.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as c_int), c"==".ptr, (98 as c_long), __local_sum, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (86 as c_int))

    (__local_sum = ((0 as c_long)))

    loop {
        var __local_fltbase_5: _flt_base = _flt_base.zeroed()

        var __local__it1: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local__it2: crange_iter = unsafe { crange_begin(((&raw const (crange { start: -6, end: ((9223372036854775807) - 1), step: 1 } as crange) as *const crange) as *mut crange)) }

        var __local_value1: *mut c_int = (unsafe *(&raw const __local__it1 as *const IVec_iter)).ref

        var __local__mapped1: c_int



        var __local_value2: *mut c_long = (unsafe *(&raw const __local__it2 as *const crange_iter)).ref

        var __local__mapped2: c_long



        while ((((((if not (unsafe *(&raw const __local_fltbase_5 as *const _flt_base)).done: 1 else: 0) as c_int) & ((if (unsafe *(&raw const __local__it1 as *const IVec_iter)).ref != null: 1 else: 0) as c_int)) as c_int) & ((if (unsafe *(&raw const __local__it2 as *const crange_iter)).ref != null: 1 else: 0) as c_int)) != 0) {
            (__local_sum = __local_sum + ((unsafe *__local_value1) * (unsafe *__local_value2)))

            unsafe { IVec_next((&raw mut __local__it1 as *mut IVec_iter)) }

            (__local_value1 = (unsafe *(&raw const __local__it1 as *const IVec_iter)).ref)

            unsafe { crange_next((&raw mut __local__it2 as *mut crange_iter)) }

            (__local_value2 = (unsafe *(&raw const __local__it2 as *const crange_iter)).ref)

            (__local_fltbase_5.sn_top = ((0 as u8)))

            (__local_fltbase_5.sb_top = ((0 as u8)))


        }

        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as c_int), c"==".ptr, (73 as c_long), __local_sum, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (90 as c_int))

    unsafe { IVec_drop(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

}

pub unsafe fn Action_drop(__param_self_: *mut Action) {
    var __local_s: *mut cstr = (((&raw const (*(&raw const (*__param_self_).ActionSpeak as *const Action_ActionSpeak)).item as *const cstr) as *mut cstr))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_s != null) {
            (__ci_expr_logic_0 = (if (if (*(&raw const (*((((if 1 != 0: __local_s else: ((offsetof[Action](ActionSpeak) + offsetof[Action_ActionSpeak](item)) as *mut cstr)) as *mut c_char) - (8 as usize)) as *mut Action)).ActionSpeak as *const Action_ActionSpeak)).id == 105000: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        cstr_drop((__local_s as *const cstr))

        (__local_s = ((null as *mut cstr)))

    }


}

unsafe fn action(__param_action: *mut Action, __param_out: *mut cstr) {
    var __local__vp1: *mut Action = __param_action

    while (__local__vp1 != null) {
        while true {
            match __local__vp1.tag {
                105000 => {
                    cstr_printf(__param_out, c"Asked to speak or log message: %s\n".ptr, cstr_str((((&raw const (*(&raw const (*__param_action).ActionSpeak as *const Action_ActionSpeak)).item as *const cstr) as *mut cstr) as *const cstr)))

                },
                105001 => {
                    cstr_printf(__param_out, c"Asked to speak or log message: %s\n".ptr, cstr_str((((&raw const (*(&raw const (*__param_action).ActionSpeak as *const Action_ActionSpeak)).item as *const cstr) as *mut cstr) as *const cstr)))

                },
                105002 => {
                    cstr_printf(__param_out, c"Asked to quit!\n".ptr)

                },
                105003 => {
                    var __local_r: *mut ActionRunFunc_type = (((&raw const (*(&raw const __local__vp1.ActionRunFunc as *const Action_ActionRunFunc)).item as *const ActionRunFunc_type) as *mut ActionRunFunc_type))

                    while (__local_r != null) {
                        var __local_res: c_int = (((*__local_r).func.unwrap()((*__local_r).v1, (*__local_r).v2) as c_int))

                        cstr_printf(__param_out, c"v1: %d, v2: %d, res: %d\n".ptr, (*__local_r).v1, (*__local_r).v2, __local_res)


                        (__local_r = ((null as *mut ActionRunFunc_type)))

                    }

                },
                _ => {
                    if ((1 as c_long) != 0) {
                        __assert_rtn(c"action".ptr, c"algorithm_test.c".ptr, (126 as c_int), c"0".ptr)
                    } else {
                        0
                    }

                },
            }

            break

        }

        (__local__vp1 = ((null as *mut Action)))

    }


}

fn add(__param_a: c_int, __param_b: c_int) -> c_int {
    return (__param_a + __param_b)

}

@[repr(C)]
pub type ctest_algorithm_c_union_run__c_i2_anon { _ref: *const *mut Action = null, ref: *mut *mut Action = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_algorithm_c_union_run__c_i2_anon
@[repr(C)]
pub type ctest_algorithm_c_union_run__c_i2_anon_2 { _ref: *const *mut cstr = null, ref: *mut *mut cstr = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_algorithm_c_union_run__c_i2_anon_2
fn ctest_algorithm_c_union_run() {
    var __local_act1: Action = ((Action { ActionSpeak: Action_ActionSpeak { id: 105000, item: unsafe { cstr_from(c"Hello!".ptr) } } } as Action))

    var __local_act2: Action = ((Action { ActionQuit: Action_ActionQuit { id: 105002, item: true } } as Action))

    var __local_act3: Action = ((Action { ActionRunFunc: Action_ActionRunFunc { id: 105003, item: ActionRunFunc_type { func: Some(add), v1: 5, v2: 6 } } } as Action))

    var __local_act4: Action = ((Action { ActionLog: Action_ActionLog { id: 105001, item: unsafe { cstr_from(c"Alert mode on".ptr) } } } as Action))

    var __local_res: cstr = cstr.zeroed()

    unsafe { action((&raw mut __local_act1 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as c_int), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"Asked to speak or log message: Hello!\n".ptr, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (143 as c_int))

    unsafe { action((&raw mut __local_act2 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as c_int), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"Asked to quit!\n".ptr, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (145 as c_int))

    unsafe { action((&raw mut __local_act3 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as c_int), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"v1: 5, v2: 6, res: 11\n".ptr, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (147 as c_int))

    unsafe { action((&raw mut __local_act4 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as c_int), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"Asked to speak or log message: Alert mode on\n".ptr, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (149 as c_int))

    assert_bool((1 as c_int), (true as bool), ((((unsafe *(&raw const (*(&raw mut __local_act1 as *mut Action)).ActionSpeak as *const Action_ActionSpeak)).id == 105000)) as bool), c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (151 as c_int))

    assert_str((1 as c_int), c"==".ptr, unsafe { cstr_str((((&raw const (*(&raw const (*(&raw const __local_act1 as *const Action)).ActionSpeak as *const Action_ActionSpeak)).item as *const cstr) as *mut cstr) as *const cstr)) }, c"Hello!".ptr, c"out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c".ptr, (152 as c_int))

    loop {
        var __local__c_i2: ctest_algorithm_c_union_run__c_i2_anon = ctest_algorithm_c_union_run__c_i2_anon.zeroed()

        var __ci_expr_lit_0: [*mut Action; 3] = [(&raw mut __local_act1 as *mut Action), (&raw mut __local_act2 as *mut Action), (&raw mut __local_act3 as *mut Action)]

        __local__c_i2 = ctest_algorithm_c_union_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_0)[0] as *mut *mut Action) as *const *mut Action)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon))._ref as *mut *mut Action)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[Action]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { Action_drop((*((*(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon)).ref))) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__c_i2_1: ctest_algorithm_c_union_run__c_i2_anon_2 = ctest_algorithm_c_union_run__c_i2_anon_2.zeroed()

        var __ci_expr_lit_1: [*mut cstr; 1] = [(&raw mut __local_res as *mut cstr)]

        __local__c_i2_1 = ctest_algorithm_c_union_run__c_i2_anon_2.zeroed()
        __local__c_i2_1._ref = ((&raw const (__ci_expr_lit_1)[0] as *mut *mut cstr) as *const *mut cstr)
        __local__c_i2_1.ref = ((unsafe *(&raw const __local__c_i2_1 as *const ctest_algorithm_c_union_run__c_i2_anon_2))._ref as *mut *mut cstr)
        __local__c_i2_1.size = (((((1 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[cstr]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2_1 as *const ctest_algorithm_c_union_run__c_i2_anon_2)).index < (unsafe *(&raw const __local__c_i2_1 as *const ctest_algorithm_c_union_run__c_i2_anon_2)).size: 1 else: 0) != 0) {
            unsafe { cstr_drop(((*((*(&raw const __local__c_i2_1 as *const ctest_algorithm_c_union_run__c_i2_anon_2)).ref)) as *const cstr)) }

            (__local__c_i2_1.ref = (unsafe *(&raw const __local__c_i2_1 as *const ctest_algorithm_c_union_run__c_i2_anon_2)).ref + 1)

            (__local__c_i2_1.index = (unsafe *(&raw const __local__c_i2_1 as *const ctest_algorithm_c_union_run__c_i2_anon_2)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

var ctest_algorithm_cstr_append: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("algorithm" as *mut c_char) as *const c_char), ttname: (("cstr_append" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_algorithm_cstr_append_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_algorithm_c_find_if: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("algorithm" as *mut c_char) as *const c_char), ttname: (("c_find_if" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_algorithm_c_find_if_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_algorithm_c_filter: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("algorithm" as *mut c_char) as *const c_char), ttname: (("c_filter" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_algorithm_c_filter_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_algorithm_c_union: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("algorithm" as *mut c_char) as *const c_char), ttname: (("c_union" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_algorithm_c_union_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_algorithm_cstr_append_run()
    print("ran algorithm.cstr_append")
    ctest_algorithm_c_find_if_run()
    print("ran algorithm.c_find_if")
    ctest_algorithm_c_filter_run()
    print("ran algorithm.c_filter")
    ctest_algorithm_c_union_run()
    print("ran algorithm.c_union")
    return ctest_failure_count()
