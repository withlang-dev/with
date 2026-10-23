// Migrated from C
use std.engines.tommyds.defs
use std.libc

fn tommy_ilog2_u32(__param_value: u32) -> u32 {
    return (((((__param_value as u32).clz() as i32) ^ (31 as i32)) as u32))

}

fn tommy_ilog2_u64(__param_value: u64) -> u32 {
    return (((((__param_value as u64).clz() as i32) ^ (63 as i32)) as u32))

}

fn tommy_ctz_u32(__param_value: u32) -> u32 {
    return (((__param_value as u32).ctz() as u32))

}

fn tommy_ctz_u64(__param_value: u64) -> u32 {
    return (((__param_value as u64).ctz() as u32))

}

fn tommy_roundup_pow2_u32(__param_value: u32) -> u32 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (1 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (2 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (4 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (8 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (16 as u32)) as u32))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: u64) -> u64 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (1 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (2 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (4 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (8 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (16 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (32 as u32)) as u64))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: u32) -> i32 {
    return (if ((((((__param_value as u32) -% (16843009 as u32)) as u32) & ((~__param_value) as u32)) as u32) & (2155905152 as u32)) != 0: 1 else: 0)

}

pub unsafe fn tommy_array_init(__param_array: *mut tommy_array_struct) {
    var __local_i: u32

    ((*__param_array).bucket_bit = ((6 as u32)))

    ((*__param_array).bucket_max = ((((1 as u64) << ((*__param_array).bucket_bit as u32)) as u64)))

    ((*__param_array).bucket[0] = (((with_alloc_zeroed(((*__param_array).bucket_max as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

    (__local_i = ((1 as u32)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        ((*__param_array).bucket[__local_i] = (*__param_array).bucket[0])

        (__local_i = (__local_i +% 1))

    }


    ((*__param_array).count = ((0 as u64)))

}

pub unsafe fn tommy_array_done(__param_array: *mut tommy_array_struct) {
    var __local_i: u32

    with_free((((*__param_array).bucket[0] as *mut c_void) as *mut u8))

    (__local_i = ((6 as u32)))

    while ((if __local_i < (*__param_array).bucket_bit: 1 else: 0) != 0) {
        var __local_segment: *mut *mut c_void = (*__param_array).bucket[__local_i]

        with_free(((((&raw const (__local_segment[((1 as i64) << (__local_i as u32))]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8))


        (__local_i = (__local_i +% 1))

    }


}

pub unsafe fn tommy_array_grow(__param_array: *mut tommy_array_struct, __param_count: u64) {
    if ((if (*__param_array).count >= __param_count: 1 else: 0) != 0) {
        return
    }

    ((*__param_array).count = __param_count)

    while ((if __param_count > (*__param_array).bucket_max: 1 else: 0) != 0) {
        var __local_segment: *mut *mut c_void

        (__local_segment = (((with_alloc_zeroed(((*__param_array).bucket_max as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

        ((*__param_array).bucket[(*__param_array).bucket_bit] = (((&raw const (__local_segment[(0 - ((*__param_array).bucket_max as i64))]) as *const *mut c_void) as *mut *mut c_void)))

        ((*__param_array).bucket_bit = ((*__param_array).bucket_bit +% 1))

        ((*__param_array).bucket_max = ((((1 as u64) << ((*__param_array).bucket_bit as u32)) as u64)))

    }

}

pub unsafe fn tommy_array_ref(__param_array: *mut tommy_array_struct, __param_pos: u64) -> *mut *mut c_void {
    var __local_bsr: u32

    if (((if not ((if __param_pos < (*__param_array).count: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"tommy_array_ref".ptr, c"tommyarray.h".ptr, (92 as i32), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_bsr = ((tommy_ilog2_u64((((__param_pos as u64) | (1 as u64)) as u64)) as u32)))

    return (((&raw const ((*__param_array).bucket[__local_bsr][__param_pos]) as *const *mut c_void) as *mut *mut c_void))

}

pub unsafe fn tommy_array_set(__param_array: *mut tommy_array_struct, __param_pos: u64, __param_element: *mut c_void) {
    ((*(tommy_array_ref(__param_array, __param_pos))) = __param_element)

}

pub unsafe fn tommy_array_get(__param_array: *mut tommy_array_struct, __param_pos: u64) -> *mut c_void {
    return (*(tommy_array_ref(__param_array, __param_pos)))

}

pub unsafe fn tommy_array_insert(__param_array: *mut tommy_array_struct, __param_element: *mut c_void) {
    var __local_pos: u64 = (*__param_array).count

    tommy_array_grow(__param_array, (((__local_pos as u64) +% (1 as u64)) as u64))

    tommy_array_set(__param_array, __local_pos, __param_element)

}

pub unsafe fn tommy_array_size(__param_array: *mut tommy_array_struct) -> u64 {
    return (*__param_array).count

}

pub unsafe fn tommy_array_memory_usage(__param_array: *mut tommy_array_struct) -> u64 {
    return (((*__param_array).bucket_max as u64) *% (sizeof[usize]() as u64))

}
