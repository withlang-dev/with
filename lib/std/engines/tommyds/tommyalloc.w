// Migrated from C
use std.engines.tommyds.defs

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

pub unsafe fn tommy_allocator_init(__param_alloc: *mut tommy_allocator_struct, __param_block_size: u64, __param_align_size: u64) {
    var __local_block_size = __param_block_size
    var __local_align_size = __param_align_size
    if ((if __local_align_size < 8: 1 else: 0) != 0) {
        (__local_align_size = ((8 as u64)))
    }

    if ((if ((__local_block_size as u64) % (__local_align_size as u64)) != 0: 1 else: 0) != 0) {
        (__local_block_size = (__local_block_size +% ((__local_align_size as u64) -% (((__local_block_size as u64) % (__local_align_size as u64)) as u64))))
    }

    ((*__param_alloc).block_size = __local_block_size)

    ((*__param_alloc).align_size = __local_align_size)

    ((*__param_alloc).count = ((0 as u64)))

    ((*__param_alloc).free_block = null)

    ((*__param_alloc).used_segment = null)

}

pub unsafe fn tommy_allocator_done(__param_alloc: *mut tommy_allocator_struct) {
    allocator_reset(__param_alloc)

}

pub unsafe fn tommy_allocator_alloc(__param_alloc: *mut tommy_allocator_struct) -> *mut c_void {
    var __local_ptr: *mut c_void

    if ((if not ((*__param_alloc).free_block != null): 1 else: 0) != 0) {
        var __local_off: u64

        var __local_mis: u64


        var __local_size: u64

        var __local_data: *mut c_char

        var __local_segment: *mut tommy_allocator_entry_struct

        (__local_size = ((4032 as u64)))

        if ((if __local_size < ((((8 as u64) +% ((*__param_alloc).align_size as u64)) as u64) +% ((*__param_alloc).block_size as u64)): 1 else: 0) != 0) {
            (__local_size = ((((((8 as u64) +% ((*__param_alloc).align_size as u64)) as u64) +% ((*__param_alloc).block_size as u64)) as u64)))
        }

        (__local_data = (((with_alloc((__local_size as i64)) as *mut c_void) as *mut c_char)))

        (__local_segment = ((__local_data as *mut tommy_allocator_entry_struct)))

        ((*__local_segment).next = (*__param_alloc).used_segment)

        ((*__param_alloc).used_segment = __local_segment)

        (__local_data = __local_data + (sizeof[tommy_allocator_entry_struct]() as usize))

        (__local_off = ((__local_data as u64)))

        (__local_mis = ((((__local_off as u64) % ((*__param_alloc).align_size as u64)) as u64)))

        if ((if __local_mis != 0: 1 else: 0) != 0) {
            (__local_data = __local_data + ((((*__param_alloc).align_size as u64) -% (__local_mis as u64)) as usize))

            (__local_size = (__local_size -% (((*__param_alloc).align_size as u64) -% (__local_mis as u64))))

        }

        loop {
            var __local_free_block: *mut tommy_allocator_entry_struct = ((__local_data as *mut tommy_allocator_entry_struct))

            ((*__local_free_block).next = (*__param_alloc).free_block)

            ((*__param_alloc).free_block = __local_free_block)

            (__local_data = __local_data + ((*__param_alloc).block_size as usize))

            (__local_size = (__local_size -% (*__param_alloc).block_size))

            if not (((if __local_size >= (*__param_alloc).block_size: 1 else: 0) != 0)) {
                break
            }
        }

    }

    (__local_ptr = (((*__param_alloc).free_block as *mut c_void)))

    ((*__param_alloc).free_block = (*(*__param_alloc).free_block).next)

    ((*__param_alloc).count = ((*__param_alloc).count +% 1))

    return __local_ptr

}

pub unsafe fn tommy_allocator_free(__param_alloc: *mut tommy_allocator_struct, __param_ptr: *mut c_void) {
    var __local_free_block: *mut tommy_allocator_entry_struct = ((__param_ptr as *mut tommy_allocator_entry_struct))

    ((*__local_free_block).next = (*__param_alloc).free_block)

    ((*__param_alloc).free_block = __local_free_block)

    ((*__param_alloc).count = ((*__param_alloc).count -% 1))

}

pub unsafe fn tommy_allocator_memory_usage(__param_alloc: *mut tommy_allocator_struct) -> u64 {
    return (((*__param_alloc).count as u64) *% ((*__param_alloc).block_size as u64))

}

unsafe fn allocator_reset(__param_alloc: *mut tommy_allocator_struct) {
    var __local_block: *mut tommy_allocator_entry_struct = (*__param_alloc).used_segment

    while (__local_block != null) {
        var __local_block_next: *mut tommy_allocator_entry_struct = (*__local_block).next

        with_free(((__local_block as *mut c_void) as *mut u8))

        (__local_block = __local_block_next)

    }

    ((*__param_alloc).count = ((0 as u64)))

    ((*__param_alloc).free_block = null)

    ((*__param_alloc).used_segment = null)

}
