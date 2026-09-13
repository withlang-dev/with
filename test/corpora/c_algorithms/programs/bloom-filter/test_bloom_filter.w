// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.bloom_filter
use std.calg_testing.framework
use std.calg_testing.hash_string
use std.libc

pub fn test_bloom_filter_new_free() -> Unit {
    var __local_filter: *mut _BloomFilter

    (__local_filter = bloom_filter_new((128 as c_uint), string_hash, (1 as c_uint)))

    if ((((if not ((if __local_filter != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (38 as c_int), c"filter != NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter) }

    (__local_filter = bloom_filter_new((128 as c_uint), string_hash, (64 as c_uint)))

    if ((((if not ((if __local_filter != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (45 as c_int), c"filter != NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter) }

    (__local_filter = bloom_filter_new((128 as c_uint), string_hash, (50000 as c_uint)))

    if ((((if not ((if __local_filter == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (52 as c_int), c"filter == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    (__local_filter = bloom_filter_new((128 as c_uint), string_hash, (1 as c_uint)))

    if ((((if not ((if __local_filter == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (59 as c_int), c"filter == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_filter = bloom_filter_new((128 as c_uint), string_hash, (1 as c_uint)))

    if ((((if not ((if __local_filter == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_new_free".ptr, c"test-bloom-filter.c".ptr, (65 as c_int), c"filter == NULL".ptr)
    } else {
        0
    }

}

pub fn test_bloom_filter_insert_query() -> Unit {
    var __local_filter: *mut _BloomFilter

    (__local_filter = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter, ("test 1" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (76 as c_int), c"bloom_filter_query(filter, \"test 1\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter, ("test 2" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (77 as c_int), c"bloom_filter_query(filter, \"test 2\") == 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_insert(__local_filter, ("test 1" as *mut c_void)) }

    unsafe { bloom_filter_insert(__local_filter, ("test 2" as *mut c_void)) }

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter, ("test 1" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (84 as c_int), c"bloom_filter_query(filter, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter, ("test 2" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_insert_query".ptr, c"test-bloom-filter.c".ptr, (85 as c_int), c"bloom_filter_query(filter, \"test 2\") != 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter) }

}

pub fn test_bloom_filter_read_load() -> Unit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    var __local_state: [16]u8

    (__local_filter1 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    unsafe { bloom_filter_insert(__local_filter1, ("test 1" as *mut c_void)) }

    unsafe { bloom_filter_insert(__local_filter1, ("test 2" as *mut c_void)) }

    unsafe { bloom_filter_read(__local_filter1, (&__local_state[0] as *mut u8)) }

    unsafe { bloom_filter_free(__local_filter1) }

    (__local_filter2 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    unsafe { bloom_filter_load(__local_filter2, (&__local_state[0] as *mut u8)) }

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter2, ("test 1" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_read_load".ptr, c"test-bloom-filter.c".ptr, (113 as c_int), c"bloom_filter_query(filter2, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter2, ("test 2" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_read_load".ptr, c"test-bloom-filter.c".ptr, (114 as c_int), c"bloom_filter_query(filter2, \"test 2\") != 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

}

pub fn test_bloom_filter_intersection() -> Unit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    var __local_result: *mut _BloomFilter

    (__local_filter1 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    unsafe { bloom_filter_insert(__local_filter1, ("test 1" as *mut c_void)) }

    unsafe { bloom_filter_insert(__local_filter1, ("test 2" as *mut c_void)) }

    (__local_filter2 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    unsafe { bloom_filter_insert(__local_filter2, ("test 1" as *mut c_void)) }

    if ((((if not ((if unsafe { bloom_filter_query(__local_filter2, ("test 2" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (139 as c_int), c"bloom_filter_query(filter2, \"test 2\") == 0".ptr)
    } else {
        0
    }

    (__local_result = unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) })

    if ((((if not ((if unsafe { bloom_filter_query(__local_result, ("test 1" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (146 as c_int), c"bloom_filter_query(result, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_query(__local_result, ("test 2" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (147 as c_int), c"bloom_filter_query(result, \"test 2\") == 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_result) }

    alloc_test_set_limit((0 as c_int))

    (__local_result = unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) })

    if ((((if not ((if __local_result == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_intersection".ptr, c"test-bloom-filter.c".ptr, (154 as c_int), c"result == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter1) }

    unsafe { bloom_filter_free(__local_filter2) }

}

pub fn test_bloom_filter_union() -> Unit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    var __local_result: *mut _BloomFilter

    (__local_filter1 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    unsafe { bloom_filter_insert(__local_filter1, ("test 1" as *mut c_void)) }

    (__local_filter2 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    unsafe { bloom_filter_insert(__local_filter2, ("test 2" as *mut c_void)) }

    (__local_result = unsafe { bloom_filter_union(__local_filter1, __local_filter2) })

    if ((((if not ((if unsafe { bloom_filter_query(__local_result, ("test 1" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_union".ptr, c"test-bloom-filter.c".ptr, (180 as c_int), c"bloom_filter_query(result, \"test 1\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_query(__local_result, ("test 2" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_union".ptr, c"test-bloom-filter.c".ptr, (181 as c_int), c"bloom_filter_query(result, \"test 2\") != 0".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_result) }

    alloc_test_set_limit((0 as c_int))

    (__local_result = unsafe { bloom_filter_union(__local_filter1, __local_filter2) })

    if ((((if not ((if __local_result == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_union".ptr, c"test-bloom-filter.c".ptr, (188 as c_int), c"result == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter1) }

    unsafe { bloom_filter_free(__local_filter2) }

}

pub fn test_bloom_filter_mismatch() -> Unit {
    var __local_filter1: *mut _BloomFilter

    var __local_filter2: *mut _BloomFilter

    (__local_filter1 = bloom_filter_new((128 as c_uint), string_hash, (4 as c_uint)))

    (__local_filter2 = bloom_filter_new((64 as c_uint), string_hash, (4 as c_uint)))

    if ((((if not ((if unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (205 as c_int), c"bloom_filter_intersection(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_union(__local_filter1, __local_filter2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (206 as c_int), c"bloom_filter_union(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

    (__local_filter2 = bloom_filter_new((128 as c_uint), string_nocase_hash, (4 as c_uint)))

    if ((((if not ((if unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (211 as c_int), c"bloom_filter_intersection(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_union(__local_filter1, __local_filter2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (212 as c_int), c"bloom_filter_union(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

    (__local_filter2 = bloom_filter_new((128 as c_uint), string_hash, (32 as c_uint)))

    if ((((if not ((if unsafe { bloom_filter_intersection(__local_filter1, __local_filter2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (217 as c_int), c"bloom_filter_intersection(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { bloom_filter_union(__local_filter1, __local_filter2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_bloom_filter_mismatch".ptr, c"test-bloom-filter.c".ptr, (218 as c_int), c"bloom_filter_union(filter1, filter2) == NULL".ptr)
    } else {
        0
    }

    unsafe { bloom_filter_free(__local_filter2) }

    unsafe { bloom_filter_free(__local_filter1) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [7]extern "C" fn() -> Unit = [test_bloom_filter_new_free, test_bloom_filter_insert_query, test_bloom_filter_read_load, test_bloom_filter_intersection, test_bloom_filter_union, test_bloom_filter_mismatch, null]
