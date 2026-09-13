// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.binary_heap
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.libc

pub fn test_binary_heap_new_free() -> Unit {
    var __local_heap: *mut _BinaryHeap

    var __local_i: c_int

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (__local_heap = binary_heap_new((0 as i32), int_compare))

        unsafe { binary_heap_free(__local_heap) }


        (__local_i = __local_i + 1)

    }


    alloc_test_set_limit((0 as c_int))

    (__local_heap = binary_heap_new((0 as i32), int_compare))

    if ((((if not ((if __local_heap == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_binary_heap_new_free".ptr, c"test-binary-heap.c".ptr, (47 as c_int), c"heap == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_heap = binary_heap_new((0 as i32), int_compare))

    if ((((if not ((if __local_heap == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_binary_heap_new_free".ptr, c"test-binary-heap.c".ptr, (51 as c_int), c"heap == NULL".ptr)
    } else {
        0
    }

}

pub fn test_binary_heap_insert() -> Unit {
    var __local_heap: *mut _BinaryHeap

    var __local_i: c_int

    (__local_heap = binary_heap_new((0 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((((if not ((if unsafe { binary_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_binary_heap_insert".ptr, c"test-binary-heap.c".ptr, (63 as c_int), c"binary_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if unsafe { binary_heap_num_entries(__local_heap) } == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_binary_heap_insert".ptr, c"test-binary-heap.c".ptr, (66 as c_int), c"binary_heap_num_entries(heap) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    unsafe { binary_heap_free(__local_heap) }

}

pub fn test_min_heap() -> Unit {
    var __local_heap: *mut _BinaryHeap

    var __local_val: *mut c_int

    var __local_i: c_int

    (__local_heap = binary_heap_new((0 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((((if not ((if unsafe { binary_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_min_heap".ptr, c"test-binary-heap.c".ptr, (82 as c_int), c"binary_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as c_int)))

    while ((if unsafe { binary_heap_num_entries(__local_heap) } > 0: 1 else: 0) != 0) {
        (__local_val = ((unsafe { binary_heap_pop(__local_heap) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_val) == (__local_i + 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_min_heap".ptr, c"test-binary-heap.c".ptr, (90 as c_int), c"*val == i + 1".ptr)
        } else {
            0
        }

        (__local_i = (unsafe *__local_val))

    }

    if ((((if not ((if unsafe { binary_heap_num_entries(__local_heap) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_min_heap".ptr, c"test-binary-heap.c".ptr, (95 as c_int), c"binary_heap_num_entries(heap) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { binary_heap_pop(__local_heap) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_min_heap".ptr, c"test-binary-heap.c".ptr, (96 as c_int), c"binary_heap_pop(heap) == BINARY_HEAP_NULL".ptr)
    } else {
        0
    }

    unsafe { binary_heap_free(__local_heap) }

}

pub fn test_max_heap() -> Unit {
    var __local_heap: *mut _BinaryHeap

    var __local_val: *mut c_int

    var __local_i: c_int

    (__local_heap = binary_heap_new((1 as i32), int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        if ((((if not ((if unsafe { binary_heap_insert(__local_heap, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_max_heap".ptr, c"test-binary-heap.c".ptr, (112 as c_int), c"binary_heap_insert(heap, &test_array[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((10000 as c_int)))

    while ((if unsafe { binary_heap_num_entries(__local_heap) } > 0: 1 else: 0) != 0) {
        (__local_val = ((unsafe { binary_heap_pop(__local_heap) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_val) == (__local_i - 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_max_heap".ptr, c"test-binary-heap.c".ptr, (120 as c_int), c"*val == i - 1".ptr)
        } else {
            0
        }

        (__local_i = (unsafe *__local_val))

    }

    unsafe { binary_heap_free(__local_heap) }

}

pub fn test_out_of_memory() -> Unit {
    var __local_heap: *mut _BinaryHeap

    var __local_value: *mut c_int

    var __local_values: [16]c_int = [(15 as c_int), (14 as c_int), (13 as c_int), (12 as c_int), (11 as c_int), (10 as c_int), (9 as c_int), (8 as c_int), (7 as c_int), (6 as c_int), (5 as c_int), (4 as c_int), (3 as c_int), (2 as c_int), (1 as c_int), (0 as c_int)]

    var __local_i: c_int

    (__local_heap = binary_heap_new((0 as i32), int_compare))

    alloc_test_set_limit((0 as c_int))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 16: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { binary_heap_insert(__local_heap, (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-binary-heap.c".ptr, (143 as c_int), c"binary_heap_insert(heap, &values[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if unsafe { binary_heap_num_entries(__local_heap) } == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_out_of_memory".ptr, c"test-binary-heap.c".ptr, (146 as c_int), c"binary_heap_num_entries(heap) == 16".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 16: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { binary_heap_insert(__local_heap, (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-binary-heap.c".ptr, (150 as c_int), c"binary_heap_insert(heap, &values[i]) == 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { binary_heap_num_entries(__local_heap) } == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-binary-heap.c".ptr, (151 as c_int), c"binary_heap_num_entries(heap) == 16".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 16: 1 else: 0) != 0) {
        (__local_value = ((unsafe { binary_heap_pop(__local_heap) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_value) == __local_i: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-binary-heap.c".ptr, (158 as c_int), c"*value == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if unsafe { binary_heap_num_entries(__local_heap) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_out_of_memory".ptr, c"test-binary-heap.c".ptr, (161 as c_int), c"binary_heap_num_entries(heap) == 0".ptr)
    } else {
        0
    }

    unsafe { binary_heap_free(__local_heap) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [6]extern "C" fn() -> Unit = [test_binary_heap_new_free, test_binary_heap_insert, test_min_heap, test_max_heap, test_out_of_memory, null]
