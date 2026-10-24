// Migrated from C
use std.engines.tommyds.defs
use std.engines.tommyds.tommyarray
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

pub unsafe fn tommy_arrayblk_init(__param_array: *mut tommy_arrayblk_struct) {
    tommy_array_init(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct))

    ((*__param_array).count = ((0 as u64)))

}

pub unsafe fn tommy_arrayblk_done(__param_array: *mut tommy_arrayblk_struct) {
    var __local_i: u64

    (__local_i = ((0 as u64)))

    while ((if __local_i < tommy_array_size(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)): 1 else: 0) != 0) {
        with_free((tommy_array_get(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_i) as *mut u8))

        (__local_i = (__local_i +% 1))

    }


    tommy_array_done(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct))

}

pub unsafe fn tommy_arrayblk_grow(__param_array: *mut tommy_arrayblk_struct, __param_count: u64) {
    var __local_block_max: u64

    var __local_block_mac: u64

    if ((if (*__param_array).count >= __param_count: 1 else: 0) != 0) {
        return
    }

    ((*__param_array).count = __param_count)

    (__local_block_max = ((((((((__param_count as u64) +% (4096 as u64)) as u64) -% (1 as u64)) as u64) / (4096 as u64)) as u64)))

    (__local_block_mac = ((tommy_array_size(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)) as u64)))

    if ((if __local_block_mac < __local_block_max: 1 else: 0) != 0) {
        tommy_array_grow(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_block_max)

        while ((if __local_block_mac < __local_block_max: 1 else: 0) != 0) {
            var __local_ptr: *mut *mut c_void = (((with_alloc_zeroed(((4096 as u64) as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut c_void))

            tommy_array_set(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_block_mac, (__local_ptr as *mut c_void))

            (__local_block_mac = (__local_block_mac +% 1))

        }

    }

}

pub unsafe fn tommy_arrayblk_ref(__param_array: *mut tommy_arrayblk_struct, __param_pos: u64) -> *mut *mut c_void {
    var __local_ptr: *mut *mut c_void

    if (((if not ((if __param_pos < (*__param_array).count: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"tommy_arrayblk_ref".ptr, c"tommyarrayblk.h".ptr, (91 as i32), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_ptr = ((tommy_array_get(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), (((__param_pos as u64) / (4096 as u64)) as u64)) as *mut *mut c_void)))

    return (((&raw const (__local_ptr[((__param_pos as u64) % (4096 as u64))]) as *const *mut c_void) as *mut *mut c_void))

}

pub unsafe fn tommy_arrayblk_set(__param_array: *mut tommy_arrayblk_struct, __param_pos: u64, __param_element: *mut c_void) {
    ((*(tommy_arrayblk_ref(__param_array, __param_pos))) = __param_element)

}

pub unsafe fn tommy_arrayblk_get(__param_array: *mut tommy_arrayblk_struct, __param_pos: u64) -> *mut c_void {
    return (*(tommy_arrayblk_ref(__param_array, __param_pos)))

}

pub unsafe fn tommy_arrayblk_insert(__param_array: *mut tommy_arrayblk_struct, __param_element: *mut c_void) {
    var __local_pos: u64 = (*__param_array).count

    tommy_arrayblk_grow(__param_array, (((__local_pos as u64) +% (1 as u64)) as u64))

    tommy_arrayblk_set(__param_array, __local_pos, __param_element)

}

pub unsafe fn tommy_arrayblk_size(__param_array: *mut tommy_arrayblk_struct) -> u64 {
    return (*__param_array).count

}

pub unsafe fn tommy_arrayblk_memory_usage(__param_array: *mut tommy_arrayblk_struct) -> u64 {
    return ((tommy_array_memory_usage(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)) as u64) +% (((((tommy_array_size(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)) as u64) *% (4096 as u64)) as u64) *% (8 as u64)) as u64))

}
