// Migrated from C
use std.tommyds.defs
use std.tommyds.tommyarray
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

unsafe fn tommy_array_ref(__param_array: *mut tommy_array_struct, __param_pos: c_ulonglong) -> *mut *mut c_void {
    var __local_bsr: c_uint

    if ((((if not ((if __param_pos < (unsafe *__param_array).count: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_array_ref".ptr, c"tommyarray.h".ptr, (92 as c_int), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_bsr = ((tommy_ilog2_u64((((__param_pos as c_ulonglong) | (1 as c_ulonglong)) as c_ulonglong)) as c_uint)))

    return (((&raw const (unsafe (unsafe *__param_array).bucket[__local_bsr][__param_pos]) as *const *mut c_void) as *mut *mut c_void))

}

unsafe fn tommy_array_set(__param_array: *mut tommy_array_struct, __param_pos: c_ulonglong, __param_element: *mut c_void) -> Unit {
    ((unsafe *(tommy_array_ref(__param_array, __param_pos))) = __param_element)

}

unsafe fn tommy_array_get(__param_array: *mut tommy_array_struct, __param_pos: c_ulonglong) -> *mut c_void {
    return (unsafe *(tommy_array_ref(__param_array, __param_pos)))

}

unsafe fn tommy_array_insert(__param_array: *mut tommy_array_struct, __param_element: *mut c_void) -> Unit {
    var __local_pos: c_ulonglong = (unsafe *__param_array).count

    tommy_array_grow(__param_array, (((__local_pos as c_ulonglong) +% (1 as c_ulonglong)) as c_ulonglong))

    tommy_array_set(__param_array, __local_pos, __param_element)

}

unsafe fn tommy_array_size(__param_array: *mut tommy_array_struct) -> c_ulonglong {
    return (unsafe *__param_array).count

}

pub unsafe fn tommy_arrayblk_init(__param_array: *mut tommy_arrayblk_struct) -> Unit {
    tommy_array_init(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct))

    ((unsafe *__param_array).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_arrayblk_done(__param_array: *mut tommy_arrayblk_struct) -> Unit {
    var __local_i: c_ulonglong

    (__local_i = ((0 as c_ulonglong)))

    while ((if __local_i < tommy_array_size(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)): 1 else: 0) != 0) {
        with_free((tommy_array_get(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_i) as *mut u8))

        (__local_i = (__local_i +% 1))

    }


    tommy_array_done(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct))

}

pub unsafe fn tommy_arrayblk_grow(__param_array: *mut tommy_arrayblk_struct, __param_count: c_ulonglong) -> Unit {
    var __local_block_max: c_ulonglong

    var __local_block_mac: c_ulonglong

    if ((if (unsafe *__param_array).count >= __param_count: 1 else: 0) != 0) {
        return
    }

    ((unsafe *__param_array).count = __param_count)

    (__local_block_max = ((((((((__param_count as c_ulonglong) +% (4096 as c_ulonglong)) as c_ulonglong) -% (1 as c_ulonglong)) as c_ulonglong) / (4096 as c_ulonglong)) as c_ulonglong)))

    (__local_block_mac = ((tommy_array_size(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)) as c_ulonglong)))

    if ((if __local_block_mac < __local_block_max: 1 else: 0) != 0) {
        tommy_array_grow(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_block_max)

        while ((if __local_block_mac < __local_block_max: 1 else: 0) != 0) {
            var __local_ptr: *mut *mut c_void = (((with_alloc_zeroed(((4096 as c_ulong) as i64), ((sizeof[usize]() as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void))

            tommy_array_set(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_block_mac, (__local_ptr as *mut c_void))

            (__local_block_mac = (__local_block_mac +% 1))

        }

    }

}

unsafe fn tommy_arrayblk_ref(__param_array: *mut tommy_arrayblk_struct, __param_pos: c_ulonglong) -> *mut *mut c_void {
    var __local_ptr: *mut *mut c_void

    if ((((if not ((if __param_pos < (unsafe *__param_array).count: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_arrayblk_ref".ptr, c"tommyarrayblk.h".ptr, (91 as c_int), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_ptr = ((tommy_array_get(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), (((__param_pos as c_ulonglong) / (4096 as c_ulonglong)) as c_ulonglong)) as *mut *mut c_void)))

    return (((&raw const (unsafe __local_ptr[((__param_pos as c_ulonglong) % (4096 as c_ulonglong))]) as *const *mut c_void) as *mut *mut c_void))

}

unsafe fn tommy_arrayblk_set(__param_array: *mut tommy_arrayblk_struct, __param_pos: c_ulonglong, __param_element: *mut c_void) -> Unit {
    ((unsafe *(tommy_arrayblk_ref(__param_array, __param_pos))) = __param_element)

}

unsafe fn tommy_arrayblk_get(__param_array: *mut tommy_arrayblk_struct, __param_pos: c_ulonglong) -> *mut c_void {
    return (unsafe *(tommy_arrayblk_ref(__param_array, __param_pos)))

}

unsafe fn tommy_arrayblk_insert(__param_array: *mut tommy_arrayblk_struct, __param_element: *mut c_void) -> Unit {
    var __local_pos: c_ulonglong = (unsafe *__param_array).count

    tommy_arrayblk_grow(__param_array, (((__local_pos as c_ulonglong) +% (1 as c_ulonglong)) as c_ulonglong))

    tommy_arrayblk_set(__param_array, __local_pos, __param_element)

}

unsafe fn tommy_arrayblk_size(__param_array: *mut tommy_arrayblk_struct) -> c_ulonglong {
    return (unsafe *__param_array).count

}

pub unsafe fn tommy_arrayblk_memory_usage(__param_array: *mut tommy_arrayblk_struct) -> c_ulonglong {
    return ((tommy_array_memory_usage(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)) as c_ulonglong) +% (((((tommy_array_size(((&raw const (unsafe *__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)) as c_ulonglong) *% (4096 as c_ulonglong)) as c_ulonglong) *% (8 as c_ulonglong)) as c_ulonglong))

}
