// Migrated from C
use std.calg_testing.defs
use std.libc

pub fn alloc_test_malloc(__param_bytes: c_ulong) -> *mut c_void {
    var __local_header: *mut _BlockHeader

    var __local_ptr: *mut c_void

    if ((if allocation_limit == 0: 1 else: 0) != 0) {
        return null

    }

    (__local_header = (((unsafe { with_alloc(((((sizeof[_BlockHeader]() as c_ulong) +% (__param_bytes as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut _BlockHeader)))

    if ((if __local_header == null: 1 else: 0) != 0) {
        return null

    }

    ((unsafe *__local_header).magic_number = ((1928102610 as c_uint)))

    ((unsafe *__local_header).bytes = __param_bytes)

    (__local_ptr = (((__local_header + ((1 as isize) as usize)) as *mut c_void)))

    unsafe { alloc_test_overwrite(__local_ptr, __param_bytes, (3131961357 as c_uint)) }

    (allocated_bytes = (allocated_bytes +% __param_bytes))

    if ((if allocation_limit > 0: 1 else: 0) != 0) {
        (allocation_limit = allocation_limit - 1)

    }

    return (((__local_header + ((1 as isize) as usize)) as *mut c_void))

}

pub unsafe fn alloc_test_free(__param_ptr: *mut c_void) -> Unit {
    var __local_header: *mut _BlockHeader

    var __local_block_size: c_ulong

    if ((if __param_ptr == null: 1 else: 0) != 0) {
        return

    }

    (__local_header = alloc_test_get_header(__param_ptr))

    (__local_block_size = (unsafe *__local_header).bytes)

    if ((((if not ((if allocated_bytes >= __local_block_size: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"alloc_test_free".ptr, c"alloc-testing.c".ptr, (145 as c_int), c"allocated_bytes >= block_size".ptr)
    } else {
        0
    }

    alloc_test_overwrite(__param_ptr, (unsafe *__local_header).bytes, (3735928559 as c_uint))

    ((unsafe *__local_header).magic_number = ((0 as c_uint)))

    with_free(((__local_header as *mut c_void) as *mut u8))

    (allocated_bytes = (allocated_bytes -% __local_block_size))

}

pub unsafe fn alloc_test_realloc(__param_ptr: *mut c_void, __param_bytes: c_ulong) -> *mut c_void {
    var __local_header: *mut _BlockHeader

    var __local_new_ptr: *mut c_void

    var __local_bytes_to_copy: c_ulong

    (__local_new_ptr = alloc_test_malloc(__param_bytes))

    if ((if __local_new_ptr == null: 1 else: 0) != 0) {
        return null

    }

    if ((if __param_ptr != null: 1 else: 0) != 0) {
        (__local_header = alloc_test_get_header(__param_ptr))

        (__local_bytes_to_copy = (unsafe *__local_header).bytes)

        if ((if __local_bytes_to_copy > __param_bytes: 1 else: 0) != 0) {
            (__local_bytes_to_copy = __param_bytes)

        }

        with_memcpy((__local_new_ptr as *mut u8), ((__param_ptr as *const c_void) as *const u8), (__local_bytes_to_copy as i64))

        alloc_test_free(__param_ptr)

    }

    return __local_new_ptr

}

pub fn alloc_test_calloc(__param_nmemb: c_ulong, __param_bytes: c_ulong) -> *mut c_void {
    var __local_result: *mut c_void

    var __local_total_bytes: c_ulong = ((((__param_nmemb as c_ulong) *% (__param_bytes as c_ulong)) as c_ulong))

    (__local_result = alloc_test_malloc(__local_total_bytes))

    if ((if __local_result == null: 1 else: 0) != 0) {
        return null

    }

    unsafe { with_memset((__local_result as *mut u8), (0 as c_int), (__local_total_bytes as i64)) }

    return __local_result

}

pub unsafe fn alloc_test_strdup(__param_string: *const i8) -> *mut i8 {
    var __local_result: *mut c_char

    (__local_result = ((alloc_test_malloc((((strlen(__param_string) as c_ulong) +% (1 as c_ulong)) as c_ulong)) as *mut c_char)))

    if ((if __local_result == null: 1 else: 0) != 0) {
        return ((null as *mut i8))

    }

    strcpy(__local_result, __param_string)

    return ((__local_result as *mut i8))

}

pub fn alloc_test_set_limit(__param_alloc_count: c_int) -> Unit {
    (allocation_limit = __param_alloc_count)

}

pub fn alloc_test_get_allocated() -> c_ulong {
    return allocated_bytes

}

unsafe fn alloc_test_get_header(__param_ptr: *mut c_void) -> *mut _BlockHeader {
    var __local_result: *mut _BlockHeader

    (__local_result = (__param_ptr as *mut _BlockHeader) - ((1 as isize) as usize))

    if ((((if not ((if (unsafe *__local_result).magic_number == 1928102610: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"alloc_test_get_header".ptr, c"alloc-testing.c".ptr, (70 as c_int), c"result->magic_number == ALLOC_TEST_MAGIC".ptr)
    } else {
        0
    }

    return __local_result

}

unsafe fn alloc_test_overwrite(__param_ptr: *mut c_void, __param_length: c_ulong, __param_pattern: c_uint) -> Unit {
    var __local_byte_ptr: *mut u8

    var __local_pattern_seq: c_int

    var __local_b: u8

    var __local_i: c_ulong

    (__local_byte_ptr = ((__param_ptr as *mut u8)))

    (__local_i = ((0 as c_ulong)))

    while ((if __local_i < __param_length: 1 else: 0) != 0) {
        (__local_pattern_seq = ((((__local_i as c_ulong) & (3 as c_ulong)) as c_int)))

        (__local_b = ((((((__param_pattern as c_uint) >> ((8 * __local_pattern_seq) as c_uint)) as c_uint) & (255 as c_uint)) as u8)))

        ((unsafe __local_byte_ptr[__local_i]) = __local_b)


        (__local_i = (__local_i +% 1))

    }


}

var allocated_bytes: c_ulong = 0
