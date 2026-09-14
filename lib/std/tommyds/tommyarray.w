// Migrated from C
use std.tommyds.defs
use std.libc

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).clz() as c_int) ^ (31 as c_int))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).clz() as c_int) ^ (63 as c_int))

}

fn tommy_ctz_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).ctz() as c_uint))

}

fn tommy_ctz_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).ctz() as c_uint))

}

fn tommy_roundup_pow2_u32(__param_value: c_uint) -> c_uint {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (1 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (2 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (4 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (8 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (16 as c_uint)) as c_uint))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: c_ulonglong) -> c_ulonglong {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (1 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (2 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (4 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (8 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (16 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (32 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: c_uint) -> c_int {
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & ((2155905152 as c_uint) as c_uint)) != 0: 1 else: 0)

}

pub unsafe fn tommy_array_init(__param_array: *mut tommy_array_struct) -> Unit {
    var __local_i: c_uint

    ((unsafe *__param_array).bucket_bit = ((6 as c_uint)))

    ((unsafe *__param_array).bucket_max = (((((1 as c_ulonglong) as c_ulonglong) << ((unsafe *__param_array).bucket_bit as c_uint)) as c_ulonglong)))

    ((unsafe *__param_array).bucket[0] = (((with_alloc_zeroed((((unsafe *__param_array).bucket_max as c_ulong) as i64), ((sizeof[usize]() as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

    (__local_i = ((1 as c_uint)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        ((unsafe *__param_array).bucket[__local_i] = (unsafe *__param_array).bucket[0])

        (__local_i = (__local_i +% 1))

    }


    ((unsafe *__param_array).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_array_done(__param_array: *mut tommy_array_struct) -> Unit {
    var __local_i: c_uint

    with_free((((unsafe *__param_array).bucket[0] as *mut c_void) as *mut u8))

    (__local_i = ((6 as c_uint)))

    while ((if __local_i < (unsafe *__param_array).bucket_bit: 1 else: 0) != 0) {
        var __local_segment: *mut *mut c_void = (unsafe *__param_array).bucket[__local_i]

        with_free(((((&raw const (unsafe __local_segment[(((1 as c_long) as c_long) << (__local_i as c_uint))]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8))


        (__local_i = (__local_i +% 1))

    }


}

pub unsafe fn tommy_array_grow(__param_array: *mut tommy_array_struct, __param_count: c_ulonglong) -> Unit {
    if ((if (unsafe *__param_array).count >= __param_count: 1 else: 0) != 0) {
        return
    }

    ((unsafe *__param_array).count = __param_count)

    while ((if __param_count > (unsafe *__param_array).bucket_max: 1 else: 0) != 0) {
        var __local_segment: *mut *mut c_void

        (__local_segment = (((with_alloc_zeroed((((unsafe *__param_array).bucket_max as c_ulong) as i64), ((sizeof[usize]() as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

        ((unsafe *__param_array).bucket[(unsafe *__param_array).bucket_bit] = (((&raw const (unsafe __local_segment[(0 - ((unsafe *__param_array).bucket_max as c_long))]) as *const *mut c_void) as *mut *mut c_void)))

        ((unsafe *__param_array).bucket_bit = ((unsafe *__param_array).bucket_bit +% 1))

        ((unsafe *__param_array).bucket_max = (((((1 as c_ulonglong) as c_ulonglong) << ((unsafe *__param_array).bucket_bit as c_uint)) as c_ulonglong)))

    }

}

pub unsafe fn tommy_array_ref(__param_array: *mut tommy_array_struct, __param_pos: c_ulonglong) -> *mut *mut c_void {
    var __local_bsr: c_uint

    if ((((if not ((if __param_pos < (unsafe *__param_array).count: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_array_ref".ptr, c"tommyarray.h".ptr, (92 as c_int), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_bsr = ((tommy_ilog2_u64((((__param_pos as c_ulonglong) | (1 as c_ulonglong)) as c_ulonglong)) as c_uint)))

    return (((&raw const (unsafe (unsafe *__param_array).bucket[__local_bsr][__param_pos]) as *const *mut c_void) as *mut *mut c_void))

}

pub unsafe fn tommy_array_set(__param_array: *mut tommy_array_struct, __param_pos: c_ulonglong, __param_element: *mut c_void) -> Unit {
    ((unsafe *(tommy_array_ref(__param_array, __param_pos))) = __param_element)

}

pub unsafe fn tommy_array_get(__param_array: *mut tommy_array_struct, __param_pos: c_ulonglong) -> *mut c_void {
    return (unsafe *(tommy_array_ref(__param_array, __param_pos)))

}

pub unsafe fn tommy_array_insert(__param_array: *mut tommy_array_struct, __param_element: *mut c_void) -> Unit {
    var __local_pos: c_ulonglong = (unsafe *__param_array).count

    tommy_array_grow(__param_array, (((__local_pos as c_ulonglong) +% (1 as c_ulonglong)) as c_ulonglong))

    tommy_array_set(__param_array, __local_pos, __param_element)

}

pub unsafe fn tommy_array_size(__param_array: *mut tommy_array_struct) -> c_ulonglong {
    return (unsafe *__param_array).count

}

pub unsafe fn tommy_array_memory_usage(__param_array: *mut tommy_array_struct) -> c_ulonglong {
    return (((unsafe *__param_array).bucket_max as c_ulonglong) *% ((sizeof[usize]() as c_ulonglong) as c_ulonglong))

}
