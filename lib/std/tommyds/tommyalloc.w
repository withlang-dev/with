// Migrated from C
use std.tommyds.defs

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

pub unsafe fn tommy_allocator_init(__param_alloc: *mut tommy_allocator_struct, __param_block_size: c_ulonglong, __param_align_size: c_ulonglong) -> Unit {
    var __local_block_size = __param_block_size
    var __local_align_size = __param_align_size
    if ((if __local_align_size < 8: 1 else: 0) != 0) {
        (__local_align_size = ((8 as c_ulonglong)))
    }

    if ((if ((__local_block_size as c_ulonglong) % (__local_align_size as c_ulonglong)) != 0: 1 else: 0) != 0) {
        (__local_block_size = (__local_block_size +% ((__local_align_size as c_ulonglong) -% (((__local_block_size as c_ulonglong) % (__local_align_size as c_ulonglong)) as c_ulonglong))))
    }

    ((unsafe *__param_alloc).block_size = __local_block_size)

    ((unsafe *__param_alloc).align_size = __local_align_size)

    ((unsafe *__param_alloc).count = ((0 as c_ulonglong)))

    ((unsafe *__param_alloc).free_block = null)

    ((unsafe *__param_alloc).used_segment = null)

}

pub unsafe fn tommy_allocator_done(__param_alloc: *mut tommy_allocator_struct) -> Unit {
    allocator_reset(__param_alloc)

}

pub unsafe fn tommy_allocator_alloc(__param_alloc: *mut tommy_allocator_struct) -> *mut c_void {
    var __local_ptr: *mut c_void

    if ((if not ((unsafe *__param_alloc).free_block != null): 1 else: 0) != 0) {
        var __local_off: c_ulong

        var __local_mis: c_ulong


        var __local_size: c_ulonglong

        var __local_data: *mut c_char

        var __local_segment: *mut tommy_allocator_entry_struct

        (__local_size = ((4032 as c_ulonglong)))

        if ((if __local_size < ((((8 as c_ulonglong) +% ((unsafe *__param_alloc).align_size as c_ulonglong)) as c_ulonglong) +% ((unsafe *__param_alloc).block_size as c_ulonglong)): 1 else: 0) != 0) {
            (__local_size = ((((((8 as c_ulonglong) +% ((unsafe *__param_alloc).align_size as c_ulonglong)) as c_ulonglong) +% ((unsafe *__param_alloc).block_size as c_ulonglong)) as c_ulonglong)))
        }

        (__local_data = (((with_alloc(((__local_size as c_ulong) as i64)) as *mut c_void) as *mut c_char)))

        (__local_segment = ((__local_data as *mut tommy_allocator_entry_struct)))

        ((unsafe *__local_segment).next = (unsafe *__param_alloc).used_segment)

        ((unsafe *__param_alloc).used_segment = __local_segment)

        (__local_data = __local_data + (sizeof[tommy_allocator_entry_struct]() as usize))

        (__local_off = ((__local_data as c_ulong)))

        (__local_mis = ((((__local_off as c_ulonglong) % ((unsafe *__param_alloc).align_size as c_ulonglong)) as c_ulong)))

        if ((if __local_mis != 0: 1 else: 0) != 0) {
            (__local_data = __local_data + ((((unsafe *__param_alloc).align_size as c_ulonglong) -% (__local_mis as c_ulonglong)) as usize))

            (__local_size = (__local_size -% (((unsafe *__param_alloc).align_size as c_ulonglong) -% (__local_mis as c_ulonglong))))

        }

        loop {
            var __local_free_block: *mut tommy_allocator_entry_struct = ((__local_data as *mut tommy_allocator_entry_struct))

            ((unsafe *__local_free_block).next = (unsafe *__param_alloc).free_block)

            ((unsafe *__param_alloc).free_block = __local_free_block)

            (__local_data = __local_data + ((unsafe *__param_alloc).block_size as usize))

            (__local_size = (__local_size -% (unsafe *__param_alloc).block_size))

            if not (((if __local_size >= (unsafe *__param_alloc).block_size: 1 else: 0) != 0)) {
                break
            }
        }

    }

    (__local_ptr = (((unsafe *__param_alloc).free_block as *mut c_void)))

    ((unsafe *__param_alloc).free_block = (unsafe *(unsafe *__param_alloc).free_block).next)

    ((unsafe *__param_alloc).count = ((unsafe *__param_alloc).count +% 1))

    return __local_ptr

}

pub unsafe fn tommy_allocator_free(__param_alloc: *mut tommy_allocator_struct, __param_ptr: *mut c_void) -> Unit {
    var __local_free_block: *mut tommy_allocator_entry_struct = ((__param_ptr as *mut tommy_allocator_entry_struct))

    ((unsafe *__local_free_block).next = (unsafe *__param_alloc).free_block)

    ((unsafe *__param_alloc).free_block = __local_free_block)

    ((unsafe *__param_alloc).count = ((unsafe *__param_alloc).count -% 1))

}

pub unsafe fn tommy_allocator_memory_usage(__param_alloc: *mut tommy_allocator_struct) -> c_ulonglong {
    return (((unsafe *__param_alloc).count as c_ulonglong) *% ((unsafe *__param_alloc).block_size as c_ulonglong))

}

unsafe fn allocator_reset(__param_alloc: *mut tommy_allocator_struct) -> Unit {
    var __local_block: *mut tommy_allocator_entry_struct = (unsafe *__param_alloc).used_segment

    while (__local_block != null) {
        var __local_block_next: *mut tommy_allocator_entry_struct = (unsafe *__local_block).next

        with_free(((__local_block as *mut c_void) as *mut u8))

        (__local_block = __local_block_next)

    }

    ((unsafe *__param_alloc).count = ((0 as c_ulonglong)))

    ((unsafe *__param_alloc).free_block = null)

    ((unsafe *__param_alloc).used_segment = null)

}
