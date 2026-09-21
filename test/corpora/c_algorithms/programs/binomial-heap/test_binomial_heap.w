// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.binomial_heap
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.libc

pub fn test_binomial_heap_new_free() -> Unit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: c_int

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (__local_heap = binomial_heap_new((0 as i32), int_compare))

        unsafe { binomial_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if binomial_heap_new((0 as i32), int_compare) == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_binomial_heap_new_free".ptr, c"test-binomial-heap.c".ptr, (47 as c_int), c"binomial_heap_new(BINOMIAL_HEAP_TYPE_MIN, int_compare) == NULL".ptr)
    } else {
        0
    }

}

pub fn test_binomial_heap_insert() -> Unit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: c_int

    (__local_heap = binomial_heap_new((0 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((((if not ((if unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_binomial_heap_insert".ptr, c"test-binomial-heap.c".ptr, (59 as c_int), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if unsafe { binomial_heap_num_entries(__local_heap) } == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_binomial_heap_insert".ptr, c"test-binomial-heap.c".ptr, (61 as c_int), c"binomial_heap_num_entries(heap) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { binomial_heap_insert(__local_heap, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_binomial_heap_insert".ptr, c"test-binomial-heap.c".ptr, (65 as c_int), c"binomial_heap_insert(heap, &i) == 0".ptr)
    } else {
        0
    }

    unsafe { binomial_heap_free(__local_heap) }

}

pub fn test_min_heap() -> Unit {
    var __local_heap: *mut _BinomialHeap

    var __local_val: *mut c_int

    var __local_i: c_int

    (__local_heap = binomial_heap_new((0 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((((if not ((if unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_min_heap".ptr, c"test-binomial-heap.c".ptr, (81 as c_int), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as c_int)))

    while ((if unsafe { binomial_heap_num_entries(__local_heap) } > 0: 1 else: 0) != 0) {
        (__local_val = ((unsafe { binomial_heap_pop(__local_heap) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_val) == (__local_i + 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_min_heap".ptr, c"test-binomial-heap.c".ptr, (89 as c_int), c"*val == i + 1".ptr)
        } else {
            0
        }

        (__local_i = (unsafe *__local_val))

    }

    (__local_val = ((unsafe { binomial_heap_pop(__local_heap) } as *mut c_int)))

    if ((((if not ((if __local_val == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_min_heap".ptr, c"test-binomial-heap.c".ptr, (95 as c_int), c"val == NULL".ptr)
    } else {
        0
    }

    unsafe { binomial_heap_free(__local_heap) }

}

pub fn test_max_heap() -> Unit {
    var __local_heap: *mut _BinomialHeap

    var __local_val: *mut c_int

    var __local_i: c_int

    (__local_heap = binomial_heap_new((1 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((((if not ((if unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_max_heap".ptr, c"test-binomial-heap.c".ptr, (111 as c_int), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((10000 as c_int)))

    while ((if unsafe { binomial_heap_num_entries(__local_heap) } > 0: 1 else: 0) != 0) {
        (__local_val = ((unsafe { binomial_heap_pop(__local_heap) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_val) == (__local_i - 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_max_heap".ptr, c"test-binomial-heap.c".ptr, (119 as c_int), c"*val == i - 1".ptr)
        } else {
            0
        }

        (__local_i = (unsafe *__local_val))

    }

    (__local_val = ((unsafe { binomial_heap_pop(__local_heap) } as *mut c_int)))

    if ((((if not ((if __local_val == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_max_heap".ptr, c"test-binomial-heap.c".ptr, (125 as c_int), c"val == NULL".ptr)
    } else {
        0
    }

    unsafe { binomial_heap_free(__local_heap) }

}

fn generate_heap() -> *mut _BinomialHeap {
    var __local_heap: *mut _BinomialHeap

    var __local_i: c_int

    (__local_heap = binomial_heap_new((0 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((if __local_i != (10000 / 2): 1 else: 0) != 0) {
            if ((((if not ((if unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"generate_heap".ptr, c"test-binomial-heap.c".ptr, (143 as c_int), c"binomial_heap_insert(heap, &test_array[i]) != 0".ptr)
            } else {
                0
            }

        }


        (__local_i = __local_i + 1)

    }


    return __local_heap

}

unsafe fn verify_heap(__param_heap: *mut _BinomialHeap) -> Unit {
    var __local_num_vals: c_uint

    var __local_val: *mut c_int

    var __local_i: c_int

    (__local_num_vals = ((binomial_heap_num_entries(__param_heap) as c_uint)))

    if ((((if not ((if __local_num_vals == 9999: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"verify_heap".ptr, c"test-binomial-heap.c".ptr, (159 as c_int), c"num_vals == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        if ((if __local_i == (10000 / 2): 1 else: 0) != 0) {
            (__local_i = __local_i + 1)

            continue


        }

        (__local_val = ((binomial_heap_pop(__param_heap) as *mut c_int)))

        if ((((if not ((if (*__local_val) == __local_i: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"verify_heap".ptr, c"test-binomial-heap.c".ptr, (168 as c_int), c"*val == i".ptr)
        } else {
            0
        }

        (__local_num_vals = (__local_num_vals -% 1))

        if ((((if not ((if binomial_heap_num_entries(__param_heap) == __local_num_vals: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"verify_heap".ptr, c"test-binomial-heap.c".ptr, (172 as c_int), c"binomial_heap_num_entries(heap) == num_vals".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


}

fn test_insert_out_of_memory() -> Unit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: c_int

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        (__local_heap = generate_heap())

        alloc_test_set_limit(__local_i)

        (test_array[(10000 / 2)] = (((10000 / 2) as c_int)))

        if ((((if not ((if unsafe { binomial_heap_insert(__local_heap, (((&raw const test_array[(10000 / 2)] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_insert_out_of_memory".ptr, c"test-binomial-heap.c".ptr, (191 as c_int), c"binomial_heap_insert(heap, &test_array[TEST_VALUE]) == 0".ptr)
        } else {
            0
        }

        alloc_test_set_limit((-1 as c_int))

        unsafe { verify_heap(__local_heap) }

        unsafe { binomial_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


}

pub fn test_pop_out_of_memory() -> Unit {
    var __local_heap: *mut _BinomialHeap

    var __local_i: c_int

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        (__local_heap = generate_heap())

        alloc_test_set_limit(__local_i)

        if ((((if not ((if unsafe { binomial_heap_pop(__local_heap) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_pop_out_of_memory".ptr, c"test-binomial-heap.c".ptr, (215 as c_int), c"binomial_heap_pop(heap) == NULL".ptr)
        } else {
            0
        }

        alloc_test_set_limit((-1 as c_int))

        unsafe { binomial_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [7]extern "C" fn() -> Unit = [test_binomial_heap_new_free, test_binomial_heap_insert, test_min_heap, test_max_heap, test_insert_out_of_memory, test_pop_out_of_memory, null]
