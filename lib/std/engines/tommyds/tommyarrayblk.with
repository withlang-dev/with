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

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_arrayblk_ref(__param_array: *mut tommy_arrayblk_struct, __param_pos: u64) -> *mut *mut c_void {
    var __local_ptr: *mut *mut c_void

    if ((if not (__param_pos < (*__param_array).count): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_arrayblk_ref".ptr, c"tommyarrayblk.h".ptr, (91 as i32), c"pos < array->count".ptr)
    } else {
        0
    }

    (__local_ptr = ((tommy_array_get(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), (((__param_pos as u64) / (4096 as u64)) as u64)) as *mut *mut c_void)))

    return (((&raw const (__local_ptr[((__param_pos as u64) % (4096 as u64))]) as *const *mut c_void) as *mut *mut c_void))

}

// contract: receiver:tommy_arrayblk_struct,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn tommy_arrayblk_set(__param_array: *mut tommy_arrayblk_struct, __param_pos: u64, __param_element: *mut c_void) {
    ((*(tommy_arrayblk_ref(__param_array, __param_pos))) = __param_element)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_arrayblk_get(__param_array: *mut tommy_arrayblk_struct, __param_pos: u64) -> *mut c_void {
    return (*(tommy_arrayblk_ref(__param_array, __param_pos)))

}

// contract: receiver-mut:tommy_arrayblk_struct,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn tommy_arrayblk_insert(__param_array: *mut tommy_arrayblk_struct, __param_element: *mut c_void) {
    var __local_pos: u64 = (*__param_array).count

    (*__param_array).tommy_arrayblk_grow((((__local_pos as u64) +% (1 as u64)) as u64))

    tommy_arrayblk_set(__param_array, __local_pos, __param_element)

}

impl tommy_arrayblk_struct {
    pub mut fn tommy_arrayblk_init() {
        let __param_array: *mut tommy_arrayblk_struct = self as *mut tommy_arrayblk_struct
        unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_init() }

        ((unsafe *__param_array).count = ((0 as u64)))

    }

    pub fn tommy_arrayblk_done() {
        let __param_array: *mut tommy_arrayblk_struct = (self as *const tommy_arrayblk_struct) as *mut tommy_arrayblk_struct
        var __local_i: u64

        (__local_i = ((0 as u64)))

        while (__local_i < unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_size() }) {
            with_free((unsafe { tommy_array_get(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_i) } as *mut u8))

            (__local_i = (__local_i +% 1))

        }


        unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_done() }

    }

    pub mut fn tommy_arrayblk_grow(__param_count: u64) {
        let __param_array: *mut tommy_arrayblk_struct = self as *mut tommy_arrayblk_struct
        var __local_block_max: u64

        var __local_block_mac: u64

        if ((unsafe *__param_array).count >= __param_count) {
            return
        }

        ((unsafe *__param_array).count = __param_count)

        (__local_block_max = ((((((((__param_count as u64) +% (4096 as u64)) as u64) -% (1 as u64)) as u64) / (4096 as u64)) as u64)))

        (__local_block_mac = ((unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_size() } as u64)))

        if (__local_block_mac < __local_block_max) {
            unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_grow(__local_block_max) }

            while (__local_block_mac < __local_block_max) {
                var __local_ptr: *mut *mut c_void = (((with_alloc_zeroed(((4096 as u64) as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut c_void))

                unsafe { tommy_array_set(((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct), __local_block_mac, (__local_ptr as *mut c_void)) }

                (__local_block_mac = (__local_block_mac +% 1))

            }

        }

    }

    pub fn tommy_arrayblk_size() -> u64 {
        let __param_array: *mut tommy_arrayblk_struct = (self as *const tommy_arrayblk_struct) as *mut tommy_arrayblk_struct
        return (unsafe *__param_array).count

    }

    pub fn tommy_arrayblk_memory_usage() -> u64 {
        let __param_array: *mut tommy_arrayblk_struct = (self as *const tommy_arrayblk_struct) as *mut tommy_arrayblk_struct
        return ((unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_memory_usage() } as u64) +% (((((unsafe { (*((&raw const (*__param_array).block as *const tommy_array_struct) as *mut tommy_array_struct)).tommy_array_size() } as u64) *% (4096 as u64)) as u64) *% (8 as u64)) as u64))

    }

}
