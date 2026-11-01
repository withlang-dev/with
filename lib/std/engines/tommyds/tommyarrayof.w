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

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_arrayof_ref(__param_array: *mut tommy_arrayof_struct, __param_pos: u64) -> *mut c_void {
    var __local_ptr: *mut u8

    var __local_bsr: u32

    if ((if not (__param_pos < (*__param_array).count): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_arrayof_ref".ptr, c"tommyarrayof.h".ptr, (101 as i32), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_bsr = ((tommy_ilog2_u64((((__param_pos as u64) | (1 as u64)) as u64)) as u32)))

    (__local_ptr = (((*__param_array).bucket[__local_bsr] as *mut u8)))

    return (((__local_ptr + (((__param_pos as u64) *% ((*__param_array).element_size as u64)) as usize)) as *mut c_void))

}

impl tommy_arrayof_struct {
    pub mut fn tommy_arrayof_init(__param_element_size: u64) {
        let __param_array: *mut tommy_arrayof_struct = self as *mut tommy_arrayof_struct
        var __local_i: u32

        ((unsafe *__param_array).element_size = __param_element_size)

        ((unsafe *__param_array).bucket_bit = ((6 as u32)))

        ((unsafe *__param_array).bucket_max = ((((1 as u64) << ((unsafe *__param_array).bucket_bit as u32)) as u64)))

        ((unsafe *__param_array).bucket[0] = ((with_alloc_zeroed(((unsafe *__param_array).bucket_max as i64), ((unsafe *__param_array).element_size as i64)) as *mut c_void)))

        (__local_i = ((1 as u32)))

        while (__local_i < 6) {
            ((unsafe *__param_array).bucket[__local_i] = (unsafe *__param_array).bucket[0])

            (__local_i = (__local_i +% 1))

        }


        ((unsafe *__param_array).count = ((0 as u64)))

    }

    pub fn tommy_arrayof_done() {
        let __param_array: *mut tommy_arrayof_struct = (self as *const tommy_arrayof_struct) as *mut tommy_arrayof_struct
        var __local_i: u32

        with_free(((unsafe *__param_array).bucket[0] as *mut u8))

        (__local_i = ((6 as u32)))

        while (__local_i < (unsafe *__param_array).bucket_bit) {
            var __local_segment: *mut u8 = (((unsafe *__param_array).bucket[__local_i] as *mut u8))

            with_free((((__local_segment + (((((1 as i64) << (__local_i as u32)) as u64) *% ((unsafe *__param_array).element_size as u64)) as usize)) as *mut c_void) as *mut u8))


            (__local_i = (__local_i +% 1))

        }


    }

    pub mut fn tommy_arrayof_grow(__param_count: u64) {
        let __param_array: *mut tommy_arrayof_struct = self as *mut tommy_arrayof_struct
        if ((unsafe *__param_array).count >= __param_count) {
            return
        }

        ((unsafe *__param_array).count = __param_count)

        while (__param_count > (unsafe *__param_array).bucket_max) {
            var __local_segment: *mut u8

            (__local_segment = (((with_alloc_zeroed(((unsafe *__param_array).bucket_max as i64), ((unsafe *__param_array).element_size as i64)) as *mut c_void) as *mut u8)))

            ((unsafe *__param_array).bucket[(unsafe *__param_array).bucket_bit] = (((__local_segment - (((((unsafe *__param_array).bucket_max as i64) as u64) *% ((unsafe *__param_array).element_size as u64)) as usize)) as *mut c_void)))

            ((unsafe *__param_array).bucket_bit = ((unsafe *__param_array).bucket_bit +% 1))

            ((unsafe *__param_array).bucket_max = ((((1 as u64) << ((unsafe *__param_array).bucket_bit as u32)) as u64)))

        }

    }

    pub fn tommy_arrayof_size() -> u64 {
        let __param_array: *mut tommy_arrayof_struct = (self as *const tommy_arrayof_struct) as *mut tommy_arrayof_struct
        return (unsafe *__param_array).count

    }

    pub fn tommy_arrayof_memory_usage() -> u64 {
        let __param_array: *mut tommy_arrayof_struct = (self as *const tommy_arrayof_struct) as *mut tommy_arrayof_struct
        return (((unsafe *__param_array).bucket_max as u64) *% ((unsafe *__param_array).element_size as u64))

    }

}
