// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.binomial_heap
use std.engines.c_algorithms_testing.compare_int
use std.engines.c_algorithms_testing.framework
use std.libc
use std.option
use std.collections

pub fn test_binomial_heap_new_free() -> Unit writes allocation_limit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: i32

    (__local_i = ((0 as i32)))

    while (__local_i < 10000) {
        (__local_heap = binomial_heap_new((0 as i32), Some(int_compare)))

        unsafe { binomial_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


    alloc_test_set_limit((0 as i32))

    if ((if not (binomial_heap_new((0 as i32), Some(int_compare)) == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_binomial_heap_new_free".ptr, c"test-binomial-heap.c".ptr, (47 as i32), c"binomial_heap_new(BINOMIAL_HEAP_TYPE_MIN, int_compare) == NULL".ptr)
    } else {
        0
    }

}

pub fn test_binomial_heap_insert() writes allocation_limit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: i32

    (__local_heap = binomial_heap_new((0 as i32), Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 10000) {
        (test_array[__local_i] = __local_i)

        if ((if not (unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != 0): 1 else: 0) as i64) {
            __assert_rtn(c"test_binomial_heap_insert".ptr, c"test-binomial-heap.c".ptr, (59 as i32), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((if not (unsafe { (*__local_heap).binomial_heap_num_entries() } == 10000): 1 else: 0) as i64) {
        __assert_rtn(c"test_binomial_heap_insert".ptr, c"test-binomial-heap.c".ptr, (61 as i32), c"binomial_heap_num_entries(heap) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    if ((if not (unsafe { binomial_heap_insert(__local_heap, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_binomial_heap_insert".ptr, c"test-binomial-heap.c".ptr, (65 as i32), c"binomial_heap_insert(heap, &i) == 0".ptr)
    } else {
        0
    }

    unsafe { binomial_heap_free(__local_heap) }

}

pub fn test_min_heap() writes allocation_limit {
    var __local_heap: *mut _BinomialHeap

    var __local_val: *mut i32

    var __local_i: i32

    (__local_heap = binomial_heap_new((0 as i32), Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 10000) {
        (test_array[__local_i] = __local_i)

        if ((if not (unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != 0): 1 else: 0) as i64) {
            __assert_rtn(c"test_min_heap".ptr, c"test-binomial-heap.c".ptr, (81 as i32), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as i32)))

    while (unsafe { (*__local_heap).binomial_heap_num_entries() } > 0) {
        (__local_val = ((unsafe { (*__local_heap).binomial_heap_pop() } as *mut i32)))

        if ((if not ((unsafe *__local_val) == (__local_i + 1)): 1 else: 0) as i64) {
            __assert_rtn(c"test_min_heap".ptr, c"test-binomial-heap.c".ptr, (89 as i32), c"*val == i + 1".ptr)
        } else {
            0
        }

        (__local_i = (unsafe *__local_val))

    }

    (__local_val = ((unsafe { (*__local_heap).binomial_heap_pop() } as *mut i32)))

    if ((if not (__local_val == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_min_heap".ptr, c"test-binomial-heap.c".ptr, (95 as i32), c"val == NULL".ptr)
    } else {
        0
    }

    unsafe { binomial_heap_free(__local_heap) }

}

pub fn test_max_heap() writes allocation_limit {
    var __local_heap: *mut _BinomialHeap

    var __local_val: *mut i32

    var __local_i: i32

    (__local_heap = binomial_heap_new((1 as i32), Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 10000) {
        (test_array[__local_i] = __local_i)

        if ((if not (unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != 0): 1 else: 0) as i64) {
            __assert_rtn(c"test_max_heap".ptr, c"test-binomial-heap.c".ptr, (111 as i32), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((10000 as i32)))

    while (unsafe { (*__local_heap).binomial_heap_num_entries() } > 0) {
        (__local_val = ((unsafe { (*__local_heap).binomial_heap_pop() } as *mut i32)))

        if ((if not ((unsafe *__local_val) == (__local_i - 1)): 1 else: 0) as i64) {
            __assert_rtn(c"test_max_heap".ptr, c"test-binomial-heap.c".ptr, (119 as i32), c"*val == i - 1".ptr)
        } else {
            0
        }

        (__local_i = (unsafe *__local_val))

    }

    (__local_val = ((unsafe { (*__local_heap).binomial_heap_pop() } as *mut i32)))

    if ((if not (__local_val == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_max_heap".ptr, c"test-binomial-heap.c".ptr, (125 as i32), c"val == NULL".ptr)
    } else {
        0
    }

    unsafe { binomial_heap_free(__local_heap) }

}

fn generate_heap() -> *mut _BinomialHeap {
    var __local_heap: *mut _BinomialHeap

    var __local_i: i32

    (__local_heap = binomial_heap_new((0 as i32), Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 10000) {
        (test_array[__local_i] = __local_i)

        if (__local_i != (10000 / 2)) {
            if ((if not (unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != 0): 1 else: 0) as i64) {
                __assert_rtn(c"generate_heap".ptr, c"test-binomial-heap.c".ptr, (143 as i32), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
            } else {
                0
            }

        }


        (__local_i = __local_i + 1)

    }


    return __local_heap

}

unsafe fn verify_heap(__param_heap: *mut _BinomialHeap) {
    var __local_num_vals: u32

    var __local_val: *mut i32

    var __local_i: i32

    (__local_num_vals = (((*__param_heap).binomial_heap_num_entries() as u32)))

    if ((if not (__local_num_vals == 9999): 1 else: 0) as i64) {
        __assert_rtn(c"verify_heap".ptr, c"test-binomial-heap.c".ptr, (159 as i32), c"num_vals == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < 10000) {
        if (__local_i == (10000 / 2)) {
            (__local_i = __local_i + 1)

            continue


        }

        (__local_val = (((*__param_heap).binomial_heap_pop() as *mut i32)))

        if ((if not ((*__local_val) == __local_i): 1 else: 0) as i64) {
            __assert_rtn(c"verify_heap".ptr, c"test-binomial-heap.c".ptr, (168 as i32), c"*val == i".ptr)
        } else {
            0
        }

        (__local_num_vals = (__local_num_vals -% 1))

        if ((if not ((*__param_heap).binomial_heap_num_entries() == __local_num_vals): 1 else: 0) as i64) {
            __assert_rtn(c"verify_heap".ptr, c"test-binomial-heap.c".ptr, (172 as i32), c"binomial_heap_num_entries(heap) == num_vals".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


}

fn test_insert_out_of_memory() {
    var __local_heap: *mut _BinomialHeap

    var __local_i: i32

    (__local_i = ((0 as i32)))

    while (__local_i < 6) {
        (__local_heap = generate_heap())

        alloc_test_set_limit(__local_i)

        (test_array[(10000 / 2)] = (((10000 / 2) as i32)))

        if ((if not (unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[(10000 / 2)] as *const i32) as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
            __assert_rtn(c"test_insert_out_of_memory".ptr, c"test-binomial-heap.c".ptr, (191 as i32), c"binomial_heap_insert(heap, &test_array[TEST_VALUE]) == 0".ptr)
        } else {
            0
        }

        alloc_test_set_limit((-1 as i32))

        unsafe { verify_heap(__local_heap) }

        unsafe { binomial_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


}

pub fn test_pop_out_of_memory() writes allocation_limit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: i32

    (__local_i = ((0 as i32)))

    while (__local_i < 6) {
        (__local_heap = generate_heap())

        alloc_test_set_limit(__local_i)

        if ((if not (unsafe { (*__local_heap).binomial_heap_pop() } == null): 1 else: 0) as i64) {
            __assert_rtn(c"test_pop_out_of_memory".ptr, c"test-binomial-heap.c".ptr, (215 as i32), c"binomial_heap_pop(heap) == NULL".ptr)
        } else {
            0
        }

        alloc_test_set_limit((-1 as i32))

        unsafe { binomial_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_binomial_heap_new_free), Some(test_binomial_heap_insert), Some(test_min_heap), Some(test_max_heap), Some(test_insert_out_of_memory), Some(test_pop_out_of_memory), null]
