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

pub unsafe fn tommy_arrayof_init(__param_array: *mut tommy_arrayof_struct, __param_element_size: c_ulonglong) -> Unit {
    var __local_i: c_uint

    ((*__param_array).element_size = __param_element_size)

    ((*__param_array).bucket_bit = ((6 as c_uint)))

    ((*__param_array).bucket_max = (((((1 as c_ulonglong) as c_ulonglong) << ((*__param_array).bucket_bit as c_uint)) as c_ulonglong)))

    ((*__param_array).bucket[0] = ((with_alloc_zeroed((((*__param_array).bucket_max as c_ulong) as i64), (((*__param_array).element_size as c_ulong) as i64)) as *mut c_void)))

    (__local_i = ((1 as c_uint)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        ((*__param_array).bucket[__local_i] = (*__param_array).bucket[0])

        (__local_i = (__local_i +% 1))

    }


    ((*__param_array).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_arrayof_done(__param_array: *mut tommy_arrayof_struct) -> Unit {
    var __local_i: c_uint

    with_free(((*__param_array).bucket[0] as *mut u8))

    (__local_i = ((6 as c_uint)))

    while ((if __local_i < (*__param_array).bucket_bit: 1 else: 0) != 0) {
        var __local_segment: *mut u8 = (((*__param_array).bucket[__local_i] as *mut u8))

        with_free((((__local_segment + ((((((1 as c_long) as c_long) << (__local_i as c_uint)) as c_ulonglong) *% ((*__param_array).element_size as c_ulonglong)) as usize)) as *mut c_void) as *mut u8))


        (__local_i = (__local_i +% 1))

    }


}

pub unsafe fn tommy_arrayof_grow(__param_array: *mut tommy_arrayof_struct, __param_count: c_ulonglong) -> Unit {
    if ((if (*__param_array).count >= __param_count: 1 else: 0) != 0) {
        return
    }

    ((*__param_array).count = __param_count)

    while ((if __param_count > (*__param_array).bucket_max: 1 else: 0) != 0) {
        var __local_segment: *mut u8

        (__local_segment = (((with_alloc_zeroed((((*__param_array).bucket_max as c_ulong) as i64), (((*__param_array).element_size as c_ulong) as i64)) as *mut c_void) as *mut u8)))

        ((*__param_array).bucket[(*__param_array).bucket_bit] = (((__local_segment - (((((*__param_array).bucket_max as c_long) as c_ulonglong) *% ((*__param_array).element_size as c_ulonglong)) as usize)) as *mut c_void)))

        ((*__param_array).bucket_bit = ((*__param_array).bucket_bit +% 1))

        ((*__param_array).bucket_max = (((((1 as c_ulonglong) as c_ulonglong) << ((*__param_array).bucket_bit as c_uint)) as c_ulonglong)))

    }

}

pub unsafe fn tommy_arrayof_ref(__param_array: *mut tommy_arrayof_struct, __param_pos: c_ulonglong) -> *mut c_void {
    var __local_ptr: *mut u8

    var __local_bsr: c_uint

    if ((((if not ((if __param_pos < (*__param_array).count: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_arrayof_ref".ptr, c"tommyarrayof.h".ptr, (101 as c_int), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_bsr = ((tommy_ilog2_u64((((__param_pos as c_ulonglong) | (1 as c_ulonglong)) as c_ulonglong)) as c_uint)))

    (__local_ptr = (((*__param_array).bucket[__local_bsr] as *mut u8)))

    return (((__local_ptr + (((__param_pos as c_ulonglong) *% ((*__param_array).element_size as c_ulonglong)) as usize)) as *mut c_void))

}

pub unsafe fn tommy_arrayof_size(__param_array: *mut tommy_arrayof_struct) -> c_ulonglong {
    return (*__param_array).count

}

pub unsafe fn tommy_arrayof_memory_usage(__param_array: *mut tommy_arrayof_struct) -> c_ulonglong {
    return (((*__param_array).bucket_max as c_ulonglong) *% ((*__param_array).element_size as c_ulonglong))

}
