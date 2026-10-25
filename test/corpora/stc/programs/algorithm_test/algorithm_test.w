// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
use std.engines.stc_testing.utf8_misc
use std.engines.stc_testing.cstr_utf8
use std.engines.stc_testing.ucd
use std.engines.stc_testing.cstr_core
use std.engines.stc_testing.cstr_misc
use std.engines.stc_testing.cstr_io
use std.engines.stc_testing.cspan
use std.libc
use std.option

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
pub unsafe fn IVec_capacity(__param_self_: *const IVec) -> i64 {
    return (*__param_self_).capacity

}

// contract: unproved:0:read only
pub unsafe fn IVec_drop(__param_cself: *const IVec) {
    var __local_self_: *mut IVec = ((__param_cself as *mut IVec))

    (*__local_self_).clear()

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

// contract: unproved:0:read only
pub unsafe fn IVec_size(__param_self_: *const IVec) -> i64 {
    return (*__param_self_).size

}

// contract: unproved:0:read only
pub unsafe fn IVec_is_empty(__param_self_: *const IVec) -> bool {
    return ((((not ((*__param_self_).size != 0))) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn IVec_value_drop(__param_self_: *const IVec, __param_val: *mut i32) {
    return
}

// contract: unproved:0:read only
pub unsafe fn IVec_front(__param_self_: *const IVec) -> *const i32 {
    return ((((&raw const ((*__param_self_).data[0]) as *const i32) as *mut i32) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IVec_front_mut(__param_self_: *mut IVec) -> *mut i32 {
    return (((&raw const ((*__param_self_).data[0]) as *const i32) as *mut i32))

}

// contract: unproved:0:read only
pub unsafe fn IVec_back(__param_self_: *const IVec) -> *const i32 {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const i32) as *mut i32) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IVec_back_mut(__param_self_: *mut IVec) -> *mut i32 {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const i32) as *mut i32))

}

// contract: unproved:0:read only
pub unsafe fn IVec_top(__param_self_: *const IVec) -> *const i32 {
    return ((IVec_back(__param_self_) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IVec_top_mut(__param_self_: *mut IVec) -> *mut i32 {
    return ((IVec_back_mut(__param_self_) as *mut i32))

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

pub fn IVec_init() -> IVec {
    var __local_out: IVec = IVec.zeroed()

    return __local_out

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

// contract: unproved:0:read only
pub unsafe fn IVec_at(__param_self_: *const IVec, __param_idx: i64) -> *const i32 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IVec_at".ptr, c"stack.h".ptr, (189 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const i32))

}

// contract: unproved:0:read only
pub unsafe fn IVec_at_mut(__param_self_: *mut IVec, __param_idx: i64) -> *mut i32 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"IVec_at_mut".ptr, c"stack.h".ptr, (192 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((*__param_self_).data + ((__param_idx as i64) as usize))

}

pub fn IVec_clone(__param_stk: IVec) -> IVec {
    var __local_out: IVec = __param_stk

    var __local_self_: *mut IVec = ((&raw mut __local_out as *mut IVec))



    (__local_out.data = ((null as *mut i32)))

    (__local_out.capacity = ((0 as i64)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const IVec)).capacity)


    unsafe { (*(&raw mut __local_out as *mut IVec)).reserve((*(&raw const __param_stk as *const IVec)).size) }

    (__local_out.size = (unsafe *(&raw const __param_stk as *const IVec)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_stk as *const IVec)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_stk as *const IVec)).data[__local_i]) as i32)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

// contract: receiver-mut:IVec,unproved:1:read only
pub unsafe fn IVec_copy(__param_self_: *mut IVec, __param_other: *const IVec) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    (*__param_self_).clear()

    (*__param_self_).reserve((*__param_other).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*__param_self_).size

        ((*__param_self_).size = (*__param_self_).size + 1)

        (((*__param_self_).data[__ci_expr_old_0]) = ((((*__param_other).data[__local_i]) as i32)))


        (__local_i = __local_i + 1)

    }


}

// contract: unproved:0:read only
pub unsafe fn IVec_value_clone(__param_self_: *const IVec, __param_val: i32) -> i32 {

    return __param_val

}

// contract: unproved:0:read only
pub unsafe fn IVec_value_toraw(__param_val: *const i32) -> i32 {
    return (*__param_val)

}

// contract: unproved:0:read only
pub unsafe fn IVec_begin(__param_self_: *const IVec) -> IVec_iter {
    var __local_it_: IVec_iter = IVec_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.end = (*(&raw const __local_it_ as *const IVec_iter)).end + (((*__param_self_).size as i64) as usize))
    } else {
        (__local_it_.ref = ((null as *mut i32)))
    }

    return __local_it_

}

// contract: unproved:0:read only
pub unsafe fn IVec_rbegin(__param_self_: *const IVec) -> IVec_iter {
    var __local_it_: IVec_iter = IVec_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const IVec_iter)).ref + ((((*__param_self_).size - 1) as i64) as usize))

        (__local_it_.end = (*(&raw const __local_it_ as *const IVec_iter)).end - ((1 as i64) as usize))

    } else {
        (__local_it_.ref = ((null as *mut i32)))
    }

    return __local_it_

}

// contract: unproved:0:read only
pub unsafe fn IVec_end(__param_self_: *const IVec) -> IVec_iter {

    var __local_it_: IVec_iter = IVec_iter.zeroed()

    return __local_it_

}

// contract: unproved:0:read only
pub unsafe fn IVec_rend(__param_self_: *const IVec) -> IVec_iter {

    var __local_it_: IVec_iter = IVec_iter.zeroed()

    return __local_it_

}

pub fn IVec_advance(__param_it_: IVec_iter, __param_n: u64) -> IVec_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const IVec_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const IVec_iter)).ref >= (unsafe *(&raw const __param_it_ as *const IVec_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut i32)))
    }


    return __param_it_

}

// contract: unproved:0:read only
pub unsafe fn IVec_index(__param_self_: *const IVec, __param_it_: IVec_iter) -> i64 {
    return (((((*(&raw const __param_it_ as *const IVec_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[i32]() as i64))

}

pub fn crange_make_3(__param_start: i64, __param_stop: i64, __param_step: i64) -> crange {
    var __local_r: crange = crange { start: __param_start, end: (__param_stop - (((if __param_step > 0: 1 else: 0)) as i64)), step: __param_step }

    return __local_r

}

pub fn crange_advance(__param_it_: crange_iter, __param_n: u64) -> crange_iter {
    ((unsafe *((*(&raw const __param_it_ as *const crange_iter)).ref)) = (unsafe *((*(&raw const __param_it_ as *const crange_iter)).ref)) + ((unsafe *(&raw const __param_it_ as *const crange_iter)).step * (__param_n as i64)))

    if ((if (if (unsafe *(&raw const __param_it_ as *const crange_iter)).step > 0: 1 else: 0) == (if (unsafe *((*(&raw const __param_it_ as *const crange_iter)).ref)) > (unsafe *(&raw const __param_it_ as *const crange_iter)).end: 1 else: 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut i64)))
    }


    return __param_it_

}

pub fn crange32_make_3(__param_start: i32, __param_stop: i32, __param_step: i32) -> crange32 {
    var __local_r: crange32 = crange32 { start: __param_start, end: (__param_stop - ((if __param_step > 0: 1 else: 0))), step: __param_step }

    return __local_r

}

pub fn crange32_advance(__param_it_: crange32_iter, __param_n: u32) -> crange32_iter {
    ((unsafe *((*(&raw const __param_it_ as *const crange32_iter)).ref)) = (unsafe *((*(&raw const __param_it_ as *const crange32_iter)).ref)) + ((unsafe *(&raw const __param_it_ as *const crange32_iter)).step * (__param_n as i32)))

    if ((if (if (unsafe *(&raw const __param_it_ as *const crange32_iter)).step > 0: 1 else: 0) == (if (unsafe *((*(&raw const __param_it_ as *const crange32_iter)).ref)) > (unsafe *(&raw const __param_it_ as *const crange32_iter)).end: 1 else: 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut i32)))
    }


    return __param_it_

}

// contract: unproved:0:read only
pub unsafe fn c_min_i32n(__param_a: *mut i32, __param_n: i64) -> i32 {
    var __local_x: i32 = (((__param_a[0]) as i32))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as i32)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_max_i32n(__param_a: *mut i32, __param_n: i64) -> i32 {
    var __local_x: i32 = (((__param_a[0]) as i32))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as i32)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_min_zin(__param_a: *mut i64, __param_n: i64) -> i64 {
    var __local_x: i64 = (((__param_a[0]) as i64))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as i64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_max_zin(__param_a: *mut i64, __param_n: i64) -> i64 {
    var __local_x: i64 = (((__param_a[0]) as i64))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as i64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_min_zun(__param_a: *mut u64, __param_n: i64) -> u64 {
    var __local_x: u64 = (((__param_a[0]) as u64))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as u64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_max_zun(__param_a: *mut u64, __param_n: i64) -> u64 {
    var __local_x: u64 = (((__param_a[0]) as u64))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as u64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_min_f32n(__param_a: *mut f32, __param_n: i64) -> f32 {
    var __local_x: f32 = (((__param_a[0]) as f32))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f32)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_max_f32n(__param_a: *mut f32, __param_n: i64) -> f32 {
    var __local_x: f32 = (((__param_a[0]) as f32))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f32)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_min_f64n(__param_a: *mut f64, __param_n: i64) -> f64 {
    var __local_x: f64 = (((__param_a[0]) as f64))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) < __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

}

// contract: unproved:0:read only
pub unsafe fn c_max_f64n(__param_a: *mut f64, __param_n: i64) -> f64 {
    var __local_x: f64 = (((__param_a[0]) as f64))

    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if (__param_a[__local_i]) > __local_x: 1 else: 0) != 0) {
            (__local_x = (((__param_a[__local_i]) as f64)))
        }

        (__local_i = __local_i + 1)

    }


    return __local_x

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

// contract: unproved:0:read only
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

// contract: unproved:0:read only
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

// contract: unproved:0:read only
unsafe fn cstr_getbuf(__param_s: *mut cstr) -> cstr_buf {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (cstr_buf { data: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64), cap: (((~(*(&raw const (*__param_s).lon as *const cstr_lon)).ncap)) as i64) } as cstr_buf) else: (cstr_buf { data: (&raw const (*__param_s).sml.data[0] as *mut c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)), cap: 22 } as cstr_buf))

}

// contract: unproved:0:read only
unsafe fn cstr_zv(__param_s: *const cstr) -> zsview {
    return (if (if (*(&raw const (*__param_s).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (zsview { str: (*(&raw const (*__param_s).lon as *const cstr_lon)).data, size: (((*(&raw const (__param_s).lon as *const cstr_lon)).size) as i64) } as zsview) else: (zsview { str: (&raw const (*__param_s).sml.data[0] as *const c_char), size: (((*(&raw const (__param_s).sml as *const cstr_sml)).size as i64)) } as zsview))

}

// contract: unproved:0:read only
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

// contract: unproved:0:read only
unsafe fn cstr_data(__param_self_: *mut cstr) -> *mut c_char {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: (*(&raw const (*__param_self_).lon as *const cstr_lon)).data else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *mut c_char)) as *mut c_char))

}

// contract: unproved:0:read only
unsafe fn cstr_str(__param_self_: *const cstr) -> *const c_char {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const c_char))

}

// contract: unproved:0:read only
unsafe fn cstr_toraw(__param_self_: *const cstr) -> *const c_char {
    return (((if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).data as *const c_char) else: (&(*(&raw const (*__param_self_).sml as *const cstr_sml)).data[0] as *const c_char)) as *const c_char))

}

// contract: unproved:0:read only
unsafe fn cstr_size(__param_self_: *const cstr) -> i64 {
    return (if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((*(&raw const (*__param_self_).lon as *const cstr_lon)).size as i64) else: ((*(&raw const (*__param_self_).sml as *const cstr_sml)).size as i64))

}

// contract: unproved:0:read only
unsafe fn cstr_is_empty(__param_self_: *const cstr) -> bool {
    return ((((cstr_size(__param_self_) == 0)) as bool))

}

// contract: unproved:0:read only
unsafe fn cstr_capacity(__param_self_: *const cstr) -> i64 {
    return (if (if (*(&raw const (*__param_self_).sml as *const cstr_sml)).size >= 128: 1 else: 0) != 0: ((~(*(&raw const (*__param_self_).lon as *const cstr_lon)).ncap) as i64) else: (22 as i64))

}

// contract: unproved:0:read only
unsafe fn cstr_to_index(__param_self_: *const cstr, __param_it_: cstr_iter) -> i64 {
    return (((((*(&raw const __param_it_ as *const cstr_iter)).ref as usize) -% (cstr_str(__param_self_) as usize)) as i64) / (sizeof[c_char]() as i64))

}

fn cstr_from_s(__param_s: cstr, __param_pos: i64, __param_len: i64) -> cstr {
    return unsafe { cstr_from_n((unsafe { cstr_str(((&raw mut __param_s as *mut cstr) as *const cstr)) } + ((__param_pos as i64) as usize)), __param_len) }

}

// contract: unproved:0:read only
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

// contract: unproved:0:read only
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

// contract: unproved:0:read only
unsafe fn cstr_u8_size(__param_self_: *const cstr) -> i64 {
    return cutf8_count(cstr_str(__param_self_))

}

// contract: unproved:0:read only
unsafe fn cstr_u8_to_index(__param_self_: *const cstr, __param_u8pos: i64) -> i64 {
    return cutf8_to_index(cstr_str(__param_self_), __param_u8pos)

}

// contract: unproved:0:read only
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

// contract: unproved:0:read only
unsafe fn cstr_u8_subview(__param_self_: *const cstr, __param_u8pos: i64, __param_u8len: i64) -> csview {
    return cutf8_subview(cstr_str(__param_self_), __param_u8pos, __param_u8len)

}

// contract: unproved:0:read only
unsafe fn cstr_u8_at(__param_self_: *const cstr, __param_u8pos: i64) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8: cstr_iter_u8 { chr: csview { buf: cutf8_at(cstr_str(__param_self_), __param_u8pos) }, dec: cutf8_decode_t.zeroed() } }

    (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const c_char)) as i64)))

    if ((if (*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *const c_char)))
    }

    return __local_it_

}

// contract: unproved:0:read only
unsafe fn cstr_begin(__param_self_: *const cstr) -> cstr_iter {
    var __local_it_: cstr_iter = cstr_iter { u8: cstr_iter_u8 { chr: csview { buf: cstr_str(__param_self_) }, dec: cutf8_decode_t.zeroed() } }

    if ((if (*((*(&raw const __local_it_ as *const cstr_iter)).ref)) == 0: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *const c_char)))
    } else {
        (__local_it_.chr.size = ((cutf8_decode_codepoint(((&raw const (*(&raw const (*(&raw const __local_it_ as *const cstr_iter)).u8 as *const cstr_iter_u8)).dec as *const cutf8_decode_t) as *mut cutf8_decode_t), (*(&raw const __local_it_ as *const cstr_iter)).ref, (null as *const c_char)) as i64)))
    }

    return __local_it_

}

// contract: unproved:0:read only
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

// contract: unproved:0:read only
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
    (*__param_self_).take(cstr_tolower_sv(cstr_sv((__param_self_ as *const cstr))))

}

unsafe fn cstr_uppercase(__param_self_: *mut cstr) -> Unit {
    (*__param_self_).take(cstr_toupper_sv(cstr_sv((__param_self_ as *const cstr))))

}

// contract: unproved:0:read only,unproved:1:read only
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

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_iends_with(__param_self_: *const cstr, __param_sub: *const c_char) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    var __local_len: i64 = ((strlen(__param_sub) as i64))

    var __ci_expr_logic_0: i32 = 0

    if ((if __local_len <= (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp(((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) - ((__local_len as i64) as usize)) as *const c_char), __param_sub) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_icmp(__param_s1: *const cstr, __param_s2: *const cstr) -> i32 {
    return cutf8_icmp(cstr_str(__param_s1), cstr_str(__param_s2))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_ieq(__param_s1: *const cstr, __param_s2: *const cstr) -> bool {
    var __local_x: csview = cstr_sv(__param_s1)

    var __local_y: csview = cstr_sv(__param_s2)


    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (cutf8_icmp_sv(__local_x, __local_y) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_iequals(__param_self_: *const cstr, __param_str: *const c_char) -> bool {
    return ((((not (cutf8_icmp(cstr_str(__param_self_), __param_str) != 0))) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_cmp(__param_s1: *const cstr, __param_s2: *const cstr) -> i32 {
    return strcmp(cstr_str(__param_s1), cstr_str(__param_s2))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_eq(__param_s1: *const cstr, __param_s2: *const cstr) -> bool {
    var __local_x: csview = cstr_sv(__param_s1)

    var __local_y: csview = cstr_sv(__param_s2)


    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __local_x as *const csview)).size == (*(&raw const __local_y as *const csview)).size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp((((*(&raw const __local_x as *const csview)).buf as *const c_void) as *const u8), (((*(&raw const __local_y as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __local_x as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_equals(__param_self_: *const cstr, __param_str: *const c_char) -> bool {
    return ((((not (strcmp(cstr_str(__param_self_), __param_str) != 0))) as bool))

}

// contract: unproved:0:read only
unsafe fn cstr_equals_sv(__param_self_: *const cstr, __param_sv: csview) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __param_sv as *const csview)).size == cstr_size(__param_self_): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sv as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sv as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_find(__param_self_: *const cstr, __param_search: *const c_char) -> i64 {
    var __local_str: *const c_char = cstr_str(__param_self_)

    var __local_res: *const c_char = ((strstr(((__local_str as *mut c_char) as *const c_char), __param_search) as *const c_char))


    return (if __local_res != null: (((((__local_res as usize) -% (__local_str as usize)) as i64) / (sizeof[c_char]() as i64)) as i64) else: (9223372036854775807 as i64))

}

// contract: unproved:0:read only,unproved:1:read only
unsafe fn cstr_contains(__param_self_: *const cstr, __param_search: *const c_char) -> bool {
    return ((((strstr(((cstr_str(__param_self_) as *mut c_char) as *const c_char), __param_search) != null)) as bool))

}

// contract: unproved:0:read only
unsafe fn cstr_contains_sv(__param_self_: *const cstr, __param_search: csview) -> bool {
    return ((((cstr_find_sv(__param_self_, __param_search) != 9223372036854775807)) as bool))

}

// contract: unproved:0:read only
unsafe fn cstr_starts_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    if ((if (*(&raw const __param_sub as *const csview)).size > cstr_size(__param_self_): 1 else: 0) != 0) {
        return ((false as bool))
    }

    return ((((not (with_memcmp(((cstr_str(__param_self_) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sub as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0))) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
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

// contract: unproved:0:read only
unsafe fn cstr_ends_with_sv(__param_self_: *const cstr, __param_sub: csview) -> bool {
    var __local_sv: csview = cstr_sv(__param_self_)

    if ((if (*(&raw const __param_sub as *const csview)).size > (*(&raw const __local_sv as *const csview)).size: 1 else: 0) != 0) {
        return ((false as bool))
    }

    return ((((not (with_memcmp((((((*(&raw const __local_sv as *const csview)).buf + (((*(&raw const __local_sv as *const csview)).size as i64) as usize)) - (((*(&raw const __param_sub as *const csview)).size as i64) as usize)) as *const c_void) as *const u8), (((*(&raw const __param_sub as *const csview)).buf as *const c_void) as *const u8), (((if 1 != 0: (*(&raw const __param_sub as *const csview)).size else: (-1 as i64)) as u64) as i64)) != 0))) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
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

// contract: receiver-mut:cstr,stored-unknown:1,unproved:2:read only
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

// contract: receiver-mut:cstr,stored-unknown:1,unproved:2:read only
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
    (*__param_self_).take(cstr_from_replace(cstr_sv((__param_self_ as *const cstr)), __param_search, __param_repl, __param_count))

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

// contract: receiver-mut:cstr,stored-unknown:1
unsafe fn cstr_getline(__param_self_: *mut cstr, __param_fp: *mut c_void) -> bool {
    return cstr_getdelim(__param_self_, (10 as i32), __param_fp)

}

// contract: unproved:0:read only,unproved:1:read only,unproved:2:read only,unproved:3:read only
unsafe fn ISpan_slice_(__param_d: *mut i32, __param_shape: *mut i32, __param_stri: *mut i32, __param_args: *mut [i64; 3], __param_rank: i32) -> ISpan {
    var __local_s: ISpan

    var __local_outrank: i32

    (__local_s.data = __param_d + ((_cspan_slice((&(*(&raw const __local_s as *const ISpan)).shape[0] as *mut i32), (&(*(&raw const __local_s.stride as *const cspan_tuple1)).d[0] as *mut i32), (&raw mut __local_outrank as *mut i32), (&(__param_shape[0]) as *mut i32), (&(__param_stri[0]) as *mut i32), (&(__param_args[0]) as *mut [i64; 3]), __param_rank) as i64) as usize))

    if (((if not ((if __local_outrank == 1: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"ISpan_slice_".ptr, c"algorithm_test.c".ptr, (9 as i32), c"outrank == 1".ptr)
    } else {
        0
    }

    return __local_s

}

// contract: unproved:0:read only
unsafe fn ISpan_begin(__param_self_: *const ISpan) -> ISpan_iter {
    var __ci_expr_ternary_1: *mut i32 = null

    var __ci_expr_logic_0: i32 = 0

    if ((if 1 == 1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_self_).shape[0] == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = ((null as *mut i32)))
    } else {
        (__ci_expr_ternary_1 = (*__param_self_).data)
    }

    return ((ISpan_iter { ref: __ci_expr_ternary_1, _s: __param_self_ } as ISpan_iter))


}

// contract: unproved:0:read only
unsafe fn ISpan_end(__param_self_: *const ISpan) -> ISpan_iter {

    return ((ISpan_iter.zeroed() as ISpan_iter))

}

unsafe fn ISpan_next(__param_it_: *mut ISpan_iter) -> Unit {
    var __local_off: i64 = (((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple1)).d[(1 - 1)] as i64))

    var __local_done: bool = with 0 as __ci_expr_seq_6 {
        ((*__param_it_).pos[0] = (*__param_it_).pos[0] + 1)
        (((*__param_it_).pos[0] == (*(*__param_it_)._s).shape[0]))
    }

    if __local_done {
        ((*__param_it_).ref = ((null as *mut i32)))
    } else {
        ((*__param_it_).ref = (*__param_it_).ref + ((__local_off as i64) as usize))
    }

}

// contract: unproved:0:read only
unsafe fn ISpan_size(__param_self_: *const ISpan) -> i64 {
    return _cspan_size((&(*__param_self_).shape[0] as *mut i32), (1 as i32))

}

fn ISpan_transposed(__param_sp: ISpan) -> ISpan {
    unsafe { _cspan_transpose((&(*(&raw const __param_sp as *const ISpan)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple1)).d[0] as *mut i32), (1 as i32)) }

    return __param_sp

}

fn ISpan_swapped_axes(__param_sp: ISpan, __param_ax1: i32, __param_ax2: i32) -> ISpan {
    unsafe { _cspan_swap_axes((&(*(&raw const __param_sp as *const ISpan)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple1)).d[0] as *mut i32), (1 as i32), __param_ax1, __param_ax2) }

    return __param_sp

}

// contract: unproved:0:read only
unsafe fn ISpan_from_n(__param_dataptr: *mut i32, __param_n: i64) -> ISpan {
    return ((ISpan { data: __param_dataptr, shape: [((__param_n) as i32)], stride: cspan_tuple1 { d: [1] } } as ISpan))

}

// contract: unproved:0:read only
unsafe fn ISpan_at(__param_self_: *const ISpan, __param_idx: i64) -> *const i32 {
    if (((if not ((if __param_idx < (*__param_self_).shape[0]: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"ISpan_at".ptr, c"algorithm_test.c".ptr, (9 as i32), c"(idx) < (self)->shape[0]".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + (((__param_idx * (*(&raw const (*__param_self_).stride as *const cspan_tuple1)).d[0]) as i64) as usize)) as *const i32))


}

// contract: unproved:0:read only
unsafe fn ISpan_at_mut(__param_self_: *mut ISpan, __param_idx: i64) -> *mut i32 {
    if (((if not ((if __param_idx < (*__param_self_).shape[0]: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"ISpan_at_mut".ptr, c"algorithm_test.c".ptr, (9 as i32), c"(idx) < (self)->shape[0]".ptr)
    } else {
        0
    }

    return ((*__param_self_).data + (((__param_idx * (*(&raw const (*__param_self_).stride as *const cspan_tuple1)).d[0]) as i64) as usize))


}

extern fn assert_str(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_char, __param_real: *const c_char, __param_caller: *const c_char, __param_line: i32)
extern fn assert_wstr(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const i32, __param_real: *const i32, __param_caller: *const c_char, __param_line: i32)
extern fn assert_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_interval(__param_diag: i32, __param_low: i64, __param_high: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_pointers(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const c_char, __param_line: i32)
extern fn assert_bool(__param_diag: i32, __param_exp: bool, __param_real: bool, __param_caller: *const c_char, __param_line: i32)
extern fn assert_dbl_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_fail(__param_caller: *const c_char, __param_line: i32)
@[repr(C)]
pub type roman { d: i32 = 0, r: *const c_char = null }
impl Copy for roman
@[repr(C)]
pub type to_roman_i_anon { _ref: *const roman = null, ref: *mut roman = null, size: i32 = 0, index: i32 = 0 }
impl Copy for to_roman_i_anon
fn to_roman(__param_value: i32) -> cstr {
    var __local_value = __param_value
    var __local_result: cstr = cstr.zeroed()


    var __local_i: to_roman_i_anon = to_roman_i_anon.zeroed()

    var __ci_expr_lit_0: [roman; 13] = [roman { d: 1000, r: (("M" as *mut c_char) as *const c_char) }, roman { d: 900, r: (("CM" as *mut c_char) as *const c_char) }, roman { d: 500, r: (("D" as *mut c_char) as *const c_char) }, roman { d: 400, r: (("CD" as *mut c_char) as *const c_char) }, roman { d: 100, r: (("C" as *mut c_char) as *const c_char) }, roman { d: 90, r: (("XC" as *mut c_char) as *const c_char) }, roman { d: 50, r: (("L" as *mut c_char) as *const c_char) }, roman { d: 40, r: (("XL" as *mut c_char) as *const c_char) }, roman { d: 10, r: (("X" as *mut c_char) as *const c_char) }, roman { d: 9, r: (("IX" as *mut c_char) as *const c_char) }, roman { d: 5, r: (("V" as *mut c_char) as *const c_char) }, roman { d: 4, r: (("IV" as *mut c_char) as *const c_char) }, roman { d: 1, r: (("I" as *mut c_char) as *const c_char) }]

    __local_i = to_roman_i_anon.zeroed()
    __local_i._ref = ((&raw const (__ci_expr_lit_0)[0] as *mut roman) as *const roman)
    __local_i.ref = ((unsafe *(&raw const __local_i as *const to_roman_i_anon))._ref as *mut roman)
    __local_i.size = ((([roman { d: 1000, r: (("M" as *mut c_char) as *const c_char) }, roman { d: 900, r: (("CM" as *mut c_char) as *const c_char) }, roman { d: 500, r: (("D" as *mut c_char) as *const c_char) }, roman { d: 400, r: (("CD" as *mut c_char) as *const c_char) }, roman { d: 100, r: (("C" as *mut c_char) as *const c_char) }, roman { d: 90, r: (("XC" as *mut c_char) as *const c_char) }, roman { d: 50, r: (("L" as *mut c_char) as *const c_char) }, roman { d: 40, r: (("XL" as *mut c_char) as *const c_char) }, roman { d: 10, r: (("X" as *mut c_char) as *const c_char) }, roman { d: 9, r: (("IX" as *mut c_char) as *const c_char) }, roman { d: 5, r: (("V" as *mut c_char) as *const c_char) }, roman { d: 4, r: (("IV" as *mut c_char) as *const c_char) }, roman { d: 1, r: (("I" as *mut c_char) as *const c_char) }].len() as u64)) as i32)


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
    var __local__c_i4: i32 = ((0 as i32))

    while ((if __local__c_i4 == 0: 1 else: 0) != 0) {
        var __local_s: cstr = to_roman((2024 as i32))

        while true {
            var __ci_expr_old_0: i32 = __local__c_i4

            (__local__c_i4 = __local__c_i4 + 1)

            if (not ((if __ci_expr_old_0 == 0: 1 else: 0) != 0)) {
                break
            }

            assert_str((1 as i32), c"==".ptr, c"MMXXIV".ptr, unsafe { cstr_str(((&raw mut __local_s as *mut cstr) as *const cstr)) }, c"algorithm_test.c".ptr, (40 as i32))

            unsafe { cstr_drop(((&raw mut __local_s as *mut cstr) as *const cstr)) }

        }

    }


}

fn ctest_algorithm_c_find_if_run() -> Unit {
    var __local_nums__goto_47_11: ISpan

    var __local_it___goto_49_16: ISpan_iter = ISpan_iter.zeroed()

    var __local__out__goto_50_5: *mut ISpan_iter = null

    var __local_value__goto_50_5: *const i32 = null

    var __local__endref__goto_50_5: *const i32 = null

    var __ci_expr_lit_0: [i32; 9]

    goto '__ci_bb_0

    '__ci_bb_0 {
        let __ci_copy_33: [i32; 9] = [1, 1, 2, 3, 5, 8, 13, 21, 34]
        with_memcpy((&raw mut __ci_expr_lit_0 as *mut u8), (&raw const __ci_copy_33 as *const u8), sizeof[[i32; 9]]())
        (__local_nums__goto_47_11 = unsafe { ISpan_from_n((&__ci_expr_lit_0[0] as *mut i32), (9 as i64)) })
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local__out__goto_50_5 = ((&raw mut __local_it___goto_49_16 as *mut ISpan_iter)))
        (__local__endref__goto_50_5 = ((null as *const i32)))
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
        assert_compare((1 as i32), c"==".ptr, (13 as i64), ((unsafe *((*(&raw const __local_it___goto_49_16 as *const ISpan_iter)).ref)) as i64), c"algorithm_test.c".ptr, (52 as i32))
        return
    }

    '__ci_bb_4 {
        (__local_value__goto_50_5 = (((unsafe *__local__out__goto_50_5).ref as *const i32)))
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
        ((unsafe *__local__out__goto_50_5).ref = ((null as *mut i32)))
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
        var __ci_expr_lit_0: [i32; 10] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 10]
        unsafe { IVec_from_n((&__ci_expr_lit_0[0] as *mut i32), (10 as i64)) }
    }

    var __local_sum: i64 = ((0 as i64))

    loop {
        var __local_fltbase: _flt_base = _flt_base.zeroed()

        var __local__it: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value: *mut i32 = (unsafe *(&raw const __local__it as *const IVec_iter)).ref

        var __local__mapped: i32 = ((0 as i32))



        while ((((if not (unsafe *(&raw const __local_fltbase as *const _flt_base)).done: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local__it as *const IVec_iter)).ref != null: 1 else: 0) as i32)) != 0) {
            var __ci_expr_logic_4: i32 = 0

            var __ci_expr_logic_3: i32 = 0

            var __ci_expr_logic_2: i32 = 0

            var __ci_expr_old_1: u8 = (unsafe *(&raw const __local_fltbase as *const _flt_base)).sb_top

            (__local_fltbase.sb_top = ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sb_top +% 1))

            (__local_fltbase.sb[__ci_expr_old_1] = (((((unsafe *(&raw const __local_fltbase as *const _flt_base)).sb[__ci_expr_old_1] as i32) | ((if not ((if (((unsafe *__local_value) as i32) & (1 as i32)) == 1: 1 else: 0) != 0): 1 else: 0) as i32)) as bool)))

            if ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sb[__ci_expr_old_1] != 0) {
                (__local_fltbase.sn_top = ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top +% 1))

                (__local_fltbase.sn[(unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top] = ((unsafe *(&raw const __local_fltbase as *const _flt_base)).sn[(unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top] +% 1))

                (__ci_expr_logic_2 = (if (if (unsafe *(&raw const __local_fltbase as *const _flt_base)).sn[(unsafe *(&raw const __local_fltbase as *const _flt_base)).sn_top] > 1: 1 else: 0) != 0: 1 else: 0))

            }

            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if (if (((unsafe *__local_value) as i32) & (1 as i32)) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if unsafe { (*(&raw mut __local_fltbase as *mut _flt_base))._flt_take((2 as u32)) } != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                (__local_sum = __local_sum + (unsafe *__local_value))
            }


            unsafe { (*(&raw mut __local__it as *mut IVec_iter)).next() }

            (__local_value = (unsafe *(&raw const __local__it as *const IVec_iter)).ref)

            (__local_fltbase.sn_top = ((0 as u8)))

            (__local_fltbase.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as i32), c"==".ptr, (42 as i64), __local_sum, c"algorithm_test.c".ptr, (70 as i32))

    var __local_hash: u64 = ((0 as u64))

    loop {
        var __local_fltbase_1: _flt_base = _flt_base.zeroed()

        var __local__it_1: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_1: *mut i32 = (unsafe *(&raw const __local__it_1 as *const IVec_iter)).ref

        var __local__mapped_1: i32 = ((0 as i32))



        while ((((if not (unsafe *(&raw const __local_fltbase_1 as *const _flt_base)).done: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local__it_1 as *const IVec_iter)).ref != null: 1 else: 0) as i32)) != 0) {
            var __ci_expr_lit_5: [u64; 2] = [__local_hash, ((unsafe *__local_value_1) as u64)]

            (__local_hash = ((unsafe { c_hash_mix_n((&__ci_expr_lit_5[0] as *mut u64), (2 as i64)) } as u64)))


            unsafe { (*(&raw mut __local__it_1 as *mut IVec_iter)).next() }

            (__local_value_1 = (unsafe *(&raw const __local__it_1 as *const IVec_iter)).ref)

            (__local_fltbase_1.sn_top = ((0 as u8)))

            (__local_fltbase_1.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as i32), c"==".ptr, (658 as i64), (__local_hash as i64), c"algorithm_test.c".ptr, (74 as i32))

    (__local_hash = ((0 as u64)))

    loop {
        var __local_fltbase_2: _flt_base = _flt_base.zeroed()

        var __local__it_2: IVec_iter = unsafe { IVec_rbegin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_2: *mut i32 = (unsafe *(&raw const __local__it_2 as *const IVec_iter)).ref

        var __local__mapped_2: i32 = ((0 as i32))



        while ((((if not (unsafe *(&raw const __local_fltbase_2 as *const _flt_base)).done: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local__it_2 as *const IVec_iter)).ref != null: 1 else: 0) as i32)) != 0) {
            var __ci_expr_lit_6: [u64; 2] = [__local_hash, ((unsafe *__local_value_2) as u64)]

            (__local_hash = ((unsafe { c_hash_mix_n((&__ci_expr_lit_6[0] as *mut u64), (2 as i64)) } as u64)))


            unsafe { (*(&raw mut __local__it_2 as *mut IVec_iter)).rnext() }

            (__local_value_2 = (unsafe *(&raw const __local__it_2 as *const IVec_iter)).ref)

            (__local_fltbase_2.sn_top = ((0 as u8)))

            (__local_fltbase_2.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as i32), c"==".ptr, (10897 as i64), (__local_hash as i64), c"algorithm_test.c".ptr, (78 as i32))

    (__local_sum = ((0 as i64)))

    loop {
        var __local_fltbase_3: _flt_base = _flt_base.zeroed()

        var __local__it_3: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_3: *mut i32 = (unsafe *(&raw const __local__it_3 as *const IVec_iter)).ref

        var __local__mapped_3: i32 = ((0 as i32))



        while ((((if not (unsafe *(&raw const __local_fltbase_3 as *const _flt_base)).done: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local__it_3 as *const IVec_iter)).ref != null: 1 else: 0) as i32)) != 0) {
            (__local_sum = __local_sum + (unsafe *__local_value_3))

            unsafe { (*(&raw mut __local__it_3 as *mut IVec_iter)).next() }

            (__local_value_3 = (unsafe *(&raw const __local__it_3 as *const IVec_iter)).ref)

            (__local_fltbase_3.sn_top = ((0 as u8)))

            (__local_fltbase_3.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as i32), c"==".ptr, (98 as i64), __local_sum, c"algorithm_test.c".ptr, (82 as i32))

    (__local_sum = ((0 as i64)))

    loop {
        var __local_fltbase_4: _flt_base = _flt_base.zeroed()

        var __local__it_4: IVec_iter = unsafe { IVec_rbegin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local_value_4: *mut i32 = (unsafe *(&raw const __local__it_4 as *const IVec_iter)).ref

        var __local__mapped_4: i32 = ((0 as i32))



        while ((((if not (unsafe *(&raw const __local_fltbase_4 as *const _flt_base)).done: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local__it_4 as *const IVec_iter)).ref != null: 1 else: 0) as i32)) != 0) {
            (__local_sum = __local_sum + (unsafe *__local_value_4))

            unsafe { (*(&raw mut __local__it_4 as *mut IVec_iter)).rnext() }

            (__local_value_4 = (unsafe *(&raw const __local__it_4 as *const IVec_iter)).ref)

            (__local_fltbase_4.sn_top = ((0 as u8)))

            (__local_fltbase_4.sb_top = ((0 as u8)))


        }


        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as i32), c"==".ptr, (98 as i64), __local_sum, c"algorithm_test.c".ptr, (86 as i32))

    (__local_sum = ((0 as i64)))

    loop {
        var __local_fltbase_5: _flt_base = _flt_base.zeroed()

        var __local__it1: IVec_iter = unsafe { IVec_begin(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

        var __local__it2: crange_iter = unsafe { (*((&raw const (crange { start: -6, end: ((9223372036854775807) - 1), step: 1 } as crange) as *const crange) as *mut crange)).begin() }

        var __local_value1: *mut i32 = (unsafe *(&raw const __local__it1 as *const IVec_iter)).ref

        var __local__mapped1: i32



        var __local_value2: *mut i64 = (unsafe *(&raw const __local__it2 as *const crange_iter)).ref

        var __local__mapped2: i64



        while ((((((if not (unsafe *(&raw const __local_fltbase_5 as *const _flt_base)).done: 1 else: 0) as i32) & ((if (unsafe *(&raw const __local__it1 as *const IVec_iter)).ref != null: 1 else: 0) as i32)) as i32) & ((if (unsafe *(&raw const __local__it2 as *const crange_iter)).ref != null: 1 else: 0) as i32)) != 0) {
            (__local_sum = __local_sum + ((unsafe *__local_value1) * (unsafe *__local_value2)))

            unsafe { (*(&raw mut __local__it1 as *mut IVec_iter)).next() }

            (__local_value1 = (unsafe *(&raw const __local__it1 as *const IVec_iter)).ref)

            unsafe { (*(&raw mut __local__it2 as *mut crange_iter)).next() }

            (__local_value2 = (unsafe *(&raw const __local__it2 as *const crange_iter)).ref)

            (__local_fltbase_5.sn_top = ((0 as u8)))

            (__local_fltbase_5.sb_top = ((0 as u8)))


        }

        if not ((0 != 0)) {
            break
        }
    }

    assert_compare((1 as i32), c"==".ptr, (73 as i64), __local_sum, c"algorithm_test.c".ptr, (90 as i32))

    unsafe { IVec_drop(((&raw mut __local_vec as *mut IVec) as *const IVec)) }

}

// contract: unproved:0:read only
pub unsafe fn Action_drop(__param_self_: *mut Action) {
    var __local_s: *mut cstr = (((&raw const (*(&raw const (*__param_self_).ActionSpeak as *const Action_ActionSpeak)).item as *const cstr) as *mut cstr))

    while true {
        var __ci_expr_logic_0: i32 = 0

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

// contract: unproved:0:read only,unproved:1:out-parameter read before the write
unsafe fn action(__param_action: *mut Action, __param_out: *mut cstr) {
    var __local__vp1: *mut Action = __param_action

    while (__local__vp1 != null) {
        while true {
            match (*__local__vp1).tag {
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
                    var __local_r: *mut ActionRunFunc_type = (((&raw const (*(&raw const (*__local__vp1).ActionRunFunc as *const Action_ActionRunFunc)).item as *const ActionRunFunc_type) as *mut ActionRunFunc_type))

                    while (__local_r != null) {
                        var __local_res: i32 = (((*__local_r).func.unwrap()((*__local_r).v1, (*__local_r).v2) as i32))

                        cstr_printf(__param_out, c"v1: %d, v2: %d, res: %d\n".ptr, (*__local_r).v1, (*__local_r).v2, __local_res)


                        (__local_r = ((null as *mut ActionRunFunc_type)))

                    }

                },
                _ => {
                    if ((1 as i64) != 0) {
                        __assert_rtn(c"action".ptr, c"algorithm_test.c".ptr, (126 as i32), c"0".ptr)
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

fn add(__param_a: i32, __param_b: i32) -> i32 {
    return (__param_a + __param_b)

}

@[repr(C)]
pub type ctest_algorithm_c_union_run__c_i2_anon { _ref: *const *mut Action = null, ref: *mut *mut Action = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_algorithm_c_union_run__c_i2_anon
@[repr(C)]
pub type ctest_algorithm_c_union_run__c_i2_anon_2 { _ref: *const *mut cstr = null, ref: *mut *mut cstr = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_algorithm_c_union_run__c_i2_anon_2
fn ctest_algorithm_c_union_run() {
    var __local_act1: Action = ((Action { ActionSpeak: Action_ActionSpeak { id: 105000, item: unsafe { cstr_from(c"Hello!".ptr) } } } as Action))

    var __local_act2: Action = ((Action { ActionQuit: Action_ActionQuit { id: 105002, item: true } } as Action))

    var __local_act3: Action = ((Action { ActionRunFunc: Action_ActionRunFunc { id: 105003, item: ActionRunFunc_type { func: Some(add), v1: 5, v2: 6 } } } as Action))

    var __local_act4: Action = ((Action { ActionLog: Action_ActionLog { id: 105001, item: unsafe { cstr_from(c"Alert mode on".ptr) } } } as Action))

    var __local_res: cstr = cstr.zeroed()

    unsafe { action((&raw mut __local_act1 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as i32), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"Asked to speak or log message: Hello!\n".ptr, c"algorithm_test.c".ptr, (143 as i32))

    unsafe { action((&raw mut __local_act2 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as i32), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"Asked to quit!\n".ptr, c"algorithm_test.c".ptr, (145 as i32))

    unsafe { action((&raw mut __local_act3 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as i32), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"v1: 5, v2: 6, res: 11\n".ptr, c"algorithm_test.c".ptr, (147 as i32))

    unsafe { action((&raw mut __local_act4 as *mut Action), (&raw mut __local_res as *mut cstr)) }

    assert_str((1 as i32), c"==".ptr, unsafe { cstr_str(((&raw mut __local_res as *mut cstr) as *const cstr)) }, c"Asked to speak or log message: Alert mode on\n".ptr, c"algorithm_test.c".ptr, (149 as i32))

    assert_bool((1 as i32), (true as bool), ((((unsafe *(&raw const (*(&raw mut __local_act1 as *mut Action)).ActionSpeak as *const Action_ActionSpeak)).id == 105000)) as bool), c"algorithm_test.c".ptr, (151 as i32))

    assert_str((1 as i32), c"==".ptr, unsafe { cstr_str((((&raw const (*(&raw const (*(&raw const __local_act1 as *const Action)).ActionSpeak as *const Action_ActionSpeak)).item as *const cstr) as *mut cstr) as *const cstr)) }, c"Hello!".ptr, c"algorithm_test.c".ptr, (152 as i32))

    loop {
        var __local__c_i2: ctest_algorithm_c_union_run__c_i2_anon = ctest_algorithm_c_union_run__c_i2_anon.zeroed()

        var __ci_expr_lit_0: [*mut Action; 3] = [(&raw mut __local_act1 as *mut Action), (&raw mut __local_act2 as *mut Action), (&raw mut __local_act3 as *mut Action)]

        __local__c_i2 = ctest_algorithm_c_union_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_0)[0] as *mut *mut Action) as *const *mut Action)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_algorithm_c_union_run__c_i2_anon))._ref as *mut *mut Action)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as u64) / (sizeof[Action]() as u64))) as i32)


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
        __local__c_i2_1.size = (((((1 * (sizeof[usize]() as usize)) as u64) / (sizeof[cstr]() as u64))) as i32)


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

impl IVec {
    pub mut fn move_() -> IVec {
        let __param_self_: *mut IVec = self as *mut IVec
        var __local_m: IVec = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).data = ((null as *mut i32)))

        return __local_m

    }

    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut IVec = self as *mut IVec
        var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param_self_).size else: __param_cap) as i64))

        if ((((if __param_cap > (unsafe *__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (unsafe *__param_self_).capacity: 1 else: 0) as i32)) != 0) {
            var __local_d: *mut i32 = (((with_realloc((((unsafe *__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[i32]() as i64)) as i64) else: (((unsafe *__param_self_).capacity * (sizeof[i32]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32))

            if ((if __local_d == null: 1 else: 0) != 0) {
                return ((false as bool))
            }

            ((unsafe *__param_self_).data = __local_d)

            ((unsafe *__param_self_).capacity = __local_n)

        }

        return (((((unsafe *__param_self_).data != null)) as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut IVec = self as *mut IVec
        var __local_i: i64 = (unsafe *__param_self_).size

        while true {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
                break
            }

        }

        ((unsafe *__param_self_).size = ((0 as i64)))

    }

    pub mut fn take(__param_unowned: IVec) -> Unit {
        let __param_self_: *mut IVec = self as *mut IVec
        unsafe { IVec_drop((__param_self_ as *const IVec)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IVec]())

    }

    pub mut fn append_uninit(__param_n: i64) -> *mut i32 {
        let __param_self_: *mut IVec = self as *mut IVec
        var __local_len: i64 = (unsafe *__param_self_).size

        if ((if (__local_len + __param_n) >= unsafe { IVec_capacity((__param_self_ as *const IVec)) }: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve(((((__local_len * 3) / 2) + __param_n) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut i32))
            }
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

        return ((unsafe *__param_self_).data + ((__local_len as i64) as usize))

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut IVec = self as *mut IVec
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn push(__param_val: i32) -> *mut i32 {
        let __param_self_: *mut IVec = self as *mut IVec
        if ((if (unsafe *__param_self_).size == unsafe { IVec_capacity((__param_self_ as *const IVec)) }: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 4) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut i32))
            }
        }

        var __local_vp: *mut i32 = with 0 as __ci_expr_seq_10 {
            var __ci_expr_old_0: i64 = (unsafe *__param_self_).size
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size + 1)
            ((unsafe *__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
        }

        ((unsafe *__local_vp) = __param_val)

        return __local_vp

    }

    pub mut fn pop() {
        let __param_self_: *mut IVec = self as *mut IVec
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"IVec_pop".ptr, c"stack.h".ptr, (149 as i32), c"self->size".ptr)
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
            __assert_rtn(c"IVec_pull".ptr, c"stack.h".ptr, (152 as i32), c"self->size".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)

        return (unsafe (*__param_self_).data[(*__param_self_).size])


    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut IVec = self as *mut IVec
        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

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

impl _flt_base {
    pub mut fn _flt_take(__param_n: u32) -> bool {
        let __param_base: *mut _flt_base = self as *mut _flt_base
        var __local_k: u32 = with 0 as __ci_expr_seq_7 {
            ((unsafe *__param_base).sn_top = ((unsafe *__param_base).sn_top +% 1))
            ((unsafe *__param_base).sn[(unsafe *__param_base).sn_top] = ((unsafe *__param_base).sn[(unsafe *__param_base).sn_top] +% 1))
            ((unsafe *__param_base).sn[(unsafe *__param_base).sn_top] as u32)
        }

        ((unsafe *__param_base).done = (((((unsafe *__param_base).done as i32) | ((if __local_k >= __param_n: 1 else: 0) as i32)) as bool)))

        return ((((__param_n > 0)) as bool))

    }

    pub mut fn _flt_takewhile(__param_pred: bool) -> bool {
        let __param_base: *mut _flt_base = self as *mut _flt_base
        var __local_skip: bool = with 0 as __ci_expr_seq_9 {
            var __ci_expr_old_0: u8 = (unsafe *__param_base).sb_top
            ((unsafe *__param_base).sb_top = ((unsafe *__param_base).sb_top +% 1))
            ((unsafe *__param_base).sb[__ci_expr_old_0] = (((((unsafe *__param_base).sb[__ci_expr_old_0] as i32) | ((if not __param_pred: 1 else: 0) as i32)) as bool)))
            (unsafe *__param_base).sb[__ci_expr_old_0]
        }

        ((unsafe *__param_base).done = (((((unsafe *__param_base).done as i32) | (__local_skip as i32)) as bool)))

        return ((((not __local_skip)) as bool))

    }

}

impl crange {
    pub mut fn begin() -> crange_iter {
        let __param_self_: *mut crange = self as *mut crange
        ((unsafe *__param_self_).value = (unsafe *__param_self_).start)

        var __local_it_: crange_iter = crange_iter { ref: ((&raw const (unsafe *__param_self_).value as *const i64) as *mut i64), end: (unsafe *__param_self_).end, step: (unsafe *__param_self_).step }

        return __local_it_

    }

}

impl crange32 {
    pub mut fn begin() -> crange32_iter {
        let __param_self_: *mut crange32 = self as *mut crange32
        ((unsafe *__param_self_).value = (unsafe *__param_self_).start)

        var __local_it_: crange32_iter = crange32_iter { ref: ((&raw const (unsafe *__param_self_).value as *const i32) as *mut i32), end: (unsafe *__param_self_).end, step: (unsafe *__param_self_).step }

        return __local_it_

    }

}

impl crange32_iter {
    pub mut fn next() {
        let __param_it_: *mut crange32_iter = self as *mut crange32_iter
        ((unsafe *((*__param_it_).ref)) = (unsafe *((*__param_it_).ref)) + (unsafe *__param_it_).step)

        if ((if (if (unsafe *__param_it_).step > 0: 1 else: 0) == (if (unsafe *((*__param_it_).ref)) > (unsafe *__param_it_).end: 1 else: 0): 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut i32)))
        }


    }

}

impl crange_iter {
    pub mut fn next() {
        let __param_it_: *mut crange_iter = self as *mut crange_iter
        ((unsafe *((*__param_it_).ref)) = (unsafe *((*__param_it_).ref)) + (unsafe *__param_it_).step)

        if ((if (if (unsafe *__param_it_).step > 0: 1 else: 0) == (if (unsafe *((*__param_it_).ref)) > (unsafe *__param_it_).end: 1 else: 0): 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut i64)))
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
