// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.libc

pub fn alloc_test_malloc(__param_bytes: u64) -> *mut c_void writes allocation_limit {
    var __local_header: *mut _BlockHeader

    var __local_ptr: *mut c_void

    if (allocation_limit == 0) {
        return null

    }

    (__local_header = (((with_alloc(((((sizeof[_BlockHeader]() as u64) +% (__param_bytes as u64)) as u64) as i64)) as *mut c_void) as *mut _BlockHeader)))

    if (__local_header == null) {
        return null

    }

    ((unsafe *__local_header).magic_number = ((1928102610 as u32)))

    ((unsafe *__local_header).bytes = __param_bytes)

    (__local_ptr = (((__local_header + ((1 as isize) as usize)) as *mut c_void)))

    unsafe { alloc_test_overwrite(__local_ptr, __param_bytes, (3131961357 as u32)) }

    (allocated_bytes = (allocated_bytes +% __param_bytes))

    if (allocation_limit > 0) {
        (allocation_limit = allocation_limit - 1)

    }

    return (((__local_header + ((1 as isize) as usize)) as *mut c_void))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn alloc_test_free(__param_ptr: *mut c_void) {
    var __local_header: *mut _BlockHeader

    var __local_block_size: u64

    if (__param_ptr == null) {
        return

    }

    (__local_header = alloc_test_get_header(__param_ptr))

    (__local_block_size = (*__local_header).bytes)

    if ((if not (allocated_bytes >= __local_block_size): 1 else: 0) as i64) {
        __assert_rtn(c"alloc_test_free".ptr, c"alloc-testing.c".ptr, (145 as i32), c"allocated_bytes >= block_size".ptr)
    } else {
        0
    }

    alloc_test_overwrite(__param_ptr, (*__local_header).bytes, (3735928559 as u32))

    ((*__local_header).magic_number = ((0 as u32)))

    with_free(((__local_header as *mut c_void) as *mut u8))

    (allocated_bytes = (allocated_bytes -% __local_block_size))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn alloc_test_realloc(__param_ptr: *mut c_void, __param_bytes: u64) -> *mut c_void writes allocation_limit {
    var __local_header: *mut _BlockHeader

    var __local_new_ptr: *mut c_void

    var __local_bytes_to_copy: u64

    (__local_new_ptr = alloc_test_malloc(__param_bytes))

    if (__local_new_ptr == null) {
        return null

    }

    if (__param_ptr != null) {
        (__local_header = alloc_test_get_header(__param_ptr))

        (__local_bytes_to_copy = (*__local_header).bytes)

        if (__local_bytes_to_copy > __param_bytes) {
            (__local_bytes_to_copy = __param_bytes)

        }

        with_memcpy((__local_new_ptr as *mut u8), ((__param_ptr as *const c_void) as *const u8), (__local_bytes_to_copy as i64))

        alloc_test_free(__param_ptr)

    }

    return __local_new_ptr

}

pub fn alloc_test_calloc(__param_nmemb: u64, __param_bytes: u64) -> *mut c_void writes allocation_limit {
    var __local_result: *mut c_void

    var __local_total_bytes: u64 = ((((__param_nmemb as u64) *% (__param_bytes as u64)) as u64))

    (__local_result = alloc_test_malloc(__local_total_bytes))

    if (__local_result == null) {
        return null

    }

    with_memset((__local_result as *mut u8), (0 as i32), (__local_total_bytes as i64))

    return __local_result

}

// contract: unproved:0:read only
pub unsafe fn alloc_test_strdup(__param_string: *const c_char) -> *mut c_char writes allocation_limit {
    var __local_result: *mut c_char

    (__local_result = ((alloc_test_malloc((((strlen(__param_string) as u64) +% (1 as u64)) as u64)) as *mut c_char)))

    if (__local_result == null) {
        return ((null as *mut c_char))

    }

    strcpy(__local_result, __param_string)

    return __local_result

}

pub fn alloc_test_set_limit(__param_alloc_count: i32) writes allocation_limit {
    (allocation_limit = __param_alloc_count)

}

pub fn alloc_test_get_allocated() -> u64 {
    return allocated_bytes

}

// contract: unproved:0:returns a pointer loaded from the parameter
unsafe fn alloc_test_get_header(__param_ptr: *mut c_void) -> *mut _BlockHeader {
    var __local_result: *mut _BlockHeader

    (__local_result = (__param_ptr as *mut _BlockHeader) - ((1 as isize) as usize))

    if ((if not ((*__local_result).magic_number == 1928102610): 1 else: 0) as i64) {
        __assert_rtn(c"alloc_test_get_header".ptr, c"alloc-testing.c".ptr, (70 as i32), c"result->magic_number == ALLOC_TEST_MAGIC".ptr)
    } else {
        0
    }

    return __local_result

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
unsafe fn alloc_test_overwrite(__param_ptr: *mut c_void, __param_length: u64, __param_pattern: u32) {
    var __local_byte_ptr: *mut u8

    var __local_pattern_seq: i32

    var __local_b: u8

    var __local_i: u64

    (__local_byte_ptr = ((__param_ptr as *mut u8)))

    (__local_i = ((0 as u64)))

    while (__local_i < __param_length) {
        (__local_pattern_seq = ((((__local_i as u64) & (3 as u64)) as i32)))

        (__local_b = ((((((__param_pattern as u32) >> ((8 * __local_pattern_seq) as u32)) as u32) & (255 as u32)) as u8)))

        ((__local_byte_ptr[__local_i]) = __local_b)


        (__local_i = (__local_i +% 1))

    }


}

var allocated_bytes: u64 = 0
