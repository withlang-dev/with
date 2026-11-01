// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.bloom_filter
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.hash_string
use std.libc
use std.option
use std.collections

pub fn test_bloom_filter_new_free() -> Unit writes allocation_limit {
    var __local_filter: *mut _BloomFilter

    (__local_filter = bloom_filter_new((128 as u32), Some(string_hash), (1 as u32)))

    if ((if not (__local_filter != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (38 as i32), c"filter != NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter) }

    (__local_filter = bloom_filter_new((128 as u32), Some(string_hash), (64 as u32)))

    if ((if not (__local_filter != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (45 as i32), c"filter != NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter) }

    (__local_filter = bloom_filter_new((128 as u32), Some(string_hash), (50000 as u32)))

    if ((if not (__local_filter == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (52 as i32), c"filter == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    (__local_filter = bloom_filter_new((128 as u32), Some(string_hash), (1 as u32)))

    if ((if not (__local_filter == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (59 as i32), c"filter == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as i32))

    (__local_filter = bloom_filter_new((128 as u32), Some(string_hash), (1 as u32)))

    if ((if not (__local_filter == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (65 as i32), c"filter == NULL".ptr)
    } else {
        0
    }

}

pub fn test_bloom_filter_insert_query() writes allocation_limit {
    var __local_filter: *mut _BloomFilter

    (__local_filter = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    if ((if not (unsafe { bloom_filter_query(__local_filter, ("test 1" as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (76 as i32), c"bloom_filter_query(filter, \"test 1\") == 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_query(__local_filter, ("test 2" as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (77 as i32), c"bloom_filter_query(filter, \"test 2\") == 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_insert(__local_filter, ("test 1" as *mut c_void)) }

    unsafe { bloom_filter_insert(__local_filter, ("test 2" as *mut c_void)) }

    if ((if not (unsafe { bloom_filter_query(__local_filter, ("test 1" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (84 as i32), c"bloom_filter_query(filter, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_query(__local_filter, ("test 2" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (85 as i32), c"bloom_filter_query(filter, \"test 2\") != 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter) }

}

pub fn test_bloom_filter_read_load() writes allocation_limit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    var __local_state: List[u8] = [0; 16]

    (__local_filter1 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    unsafe { bloom_filter_insert(__local_filter1, ("test 1" as *mut c_void)) }

    unsafe { bloom_filter_insert(__local_filter1, ("test 2" as *mut c_void)) }

    unsafe { bloom_filter_read(__local_filter1, (&__local_state[0] as *mut u8)) }

    unsafe { bloom_filter_free(__local_filter1) }

    (__local_filter2 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    unsafe { bloom_filter_load(__local_filter2, (&__local_state[0] as *mut u8)) }

    if ((if not (unsafe { bloom_filter_query(__local_filter2, ("test 1" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_read_load".ptr, c"test-bloom-filter.c".ptr, (113 as i32), c"bloom_filter_query(filter2, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_query(__local_filter2, ("test 2" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_read_load".ptr, c"test-bloom-filter.c".ptr, (114 as i32), c"bloom_filter_query(filter2, \"test 2\") != 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

}

pub fn test_bloom_filter_intersection() writes allocation_limit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    var __local_result: *mut _BloomFilter

    (__local_filter1 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    unsafe { bloom_filter_insert(__local_filter1, ("test 1" as *mut c_void)) }

    unsafe { bloom_filter_insert(__local_filter1, ("test 2" as *mut c_void)) }

    (__local_filter2 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    unsafe { bloom_filter_insert(__local_filter2, ("test 1" as *mut c_void)) }

    if ((if not (unsafe { bloom_filter_query(__local_filter2, ("test 2" as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (139 as i32), c"bloom_filter_query(filter2, \"test 2\") == 0".ptr)
    } else {
        0
    }

    (__local_result = unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) })

    if ((if not (unsafe { bloom_filter_query(__local_result, ("test 1" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (146 as i32), c"bloom_filter_query(result, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_query(__local_result, ("test 2" as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (147 as i32), c"bloom_filter_query(result, \"test 2\") == 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_result) }

    alloc_test_set_limit((0 as i32))

    (__local_result = unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) })

    if ((if not (__local_result == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (154 as i32), c"result == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter1) }

    unsafe { bloom_filter_free(__local_filter2) }

}

pub fn test_bloom_filter_union() writes allocation_limit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    var __local_result: *mut _BloomFilter

    (__local_filter1 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    unsafe { bloom_filter_insert(__local_filter1, ("test 1" as *mut c_void)) }

    (__local_filter2 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    unsafe { bloom_filter_insert(__local_filter2, ("test 2" as *mut c_void)) }

    (__local_result = unsafe { bloom_filter_union(__local_filter1, __local_filter2) })

    if ((if not (unsafe { bloom_filter_query(__local_result, ("test 1" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_union".ptr, c"test-bloom-filter.c".ptr, (180 as i32), c"bloom_filter_query(result, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_query(__local_result, ("test 2" as *mut c_void)) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_union".ptr, c"test-bloom-filter.c".ptr, (181 as i32), c"bloom_filter_query(result, \"test 2\") != 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_result) }

    alloc_test_set_limit((0 as i32))

    (__local_result = unsafe { bloom_filter_union(__local_filter1, __local_filter2) })

    if ((if not (__local_result == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_union".ptr, c"test-bloom-filter.c".ptr, (188 as i32), c"result == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter1) }

    unsafe { bloom_filter_free(__local_filter2) }

}

pub fn test_bloom_filter_mismatch() writes allocation_limit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    (__local_filter1 = bloom_filter_new((128 as u32), Some(string_hash), (4 as u32)))

    (__local_filter2 = bloom_filter_new((64 as u32), Some(string_hash), (4 as u32)))

    if ((if not (unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (205 as i32), c"bloom_filter_intersection(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_union(__local_filter1, __local_filter2) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (206 as i32), c"bloom_filter_union(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

    (__local_filter2 = bloom_filter_new((128 as u32), Some(string_nocase_hash), (4 as u32)))

    if ((if not (unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (211 as i32), c"bloom_filter_intersection(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_union(__local_filter1, __local_filter2) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (212 as i32), c"bloom_filter_union(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

    (__local_filter2 = bloom_filter_new((128 as u32), Some(string_hash), (32 as u32)))

    if ((if not (unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (217 as i32), c"bloom_filter_intersection(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { bloom_filter_union(__local_filter1, __local_filter2) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (218 as i32), c"bloom_filter_union(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

    unsafe { bloom_filter_free(__local_filter1) }

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_bloom_filter_new_free), Some(test_bloom_filter_insert_query), Some(test_bloom_filter_read_load), Some(test_bloom_filter_intersection), Some(test_bloom_filter_union), Some(test_bloom_filter_mismatch), null]
