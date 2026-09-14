// Migrated from C
use std.c_algorithms.defs

pub fn binary_heap_new(__param_heap_type: i32, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _BinaryHeap {
    var __local_heap: *mut _BinaryHeap

    (__local_heap = (((unsafe { with_alloc(((sizeof[_BinaryHeap]() as c_ulong) as i64)) } as *mut c_void) as *mut _BinaryHeap)))

    if ((if __local_heap == null: 1 else: 0) != 0) {
        return ((null as *mut _BinaryHeap))

    }

    ((unsafe *__local_heap).heap_type = __param_heap_type)

    ((unsafe *__local_heap).num_values = ((0 as c_uint)))

    ((unsafe *__local_heap).compare_func = __param_compare_func)

    ((unsafe *__local_heap).alloced_size = ((16 as c_uint)))

    ((unsafe *__local_heap).values = (((unsafe { with_alloc(((((sizeof[usize]() as c_ulong) *% ((unsafe *__local_heap).alloced_size as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut *mut c_void)))

    if ((if (unsafe *__local_heap).values == null: 1 else: 0) != 0) {
        unsafe { with_free(((__local_heap as *mut c_void) as *mut u8)) }

        return ((null as *mut _BinaryHeap))

    }

    return __local_heap

}

pub unsafe fn binary_heap_free(__param_heap: *mut _BinaryHeap) -> Unit {
    with_free((((unsafe *__param_heap).values as *mut c_void) as *mut u8))

    with_free(((__param_heap as *mut c_void) as *mut u8))

}

pub unsafe fn binary_heap_insert(__param_heap: *mut _BinaryHeap, __param_value: *mut c_void) -> c_int {
    var __local_new_values: *mut *mut c_void

    var __local_index: c_uint

    var __local_new_size: c_uint

    var __local_parent: c_uint

    if ((if (unsafe *__param_heap).num_values >= (unsafe *__param_heap).alloced_size: 1 else: 0) != 0) {
        (__local_new_size = (((((unsafe *__param_heap).alloced_size as c_uint) *% (2 as c_uint)) as c_uint)))

        (__local_new_values = (((with_realloc((((unsafe *__param_heap).values as *mut c_void) as *mut u8), (0 as i64), ((((sizeof[usize]() as c_ulong) *% (__local_new_size as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

        if ((if __local_new_values == null: 1 else: 0) != 0) {
            return 0

        }

        ((unsafe *__param_heap).alloced_size = __local_new_size)

        ((unsafe *__param_heap).values = __local_new_values)

    }

    (__local_index = (unsafe *__param_heap).num_values)

    ((unsafe *__param_heap).num_values = ((unsafe *__param_heap).num_values +% 1))

    while ((if __local_index > 0: 1 else: 0) != 0) {
        (__local_parent = ((((((__local_index as c_uint) -% (1 as c_uint)) as c_uint) / (2 as c_uint)) as c_uint)))

        if ((if binary_heap_cmp(__param_heap, (unsafe (unsafe *__param_heap).values[__local_parent]), __param_value) < 0: 1 else: 0) != 0) {
            break

        }
        ((unsafe (unsafe *__param_heap).values[__local_index]) = (unsafe (unsafe *__param_heap).values[__local_parent]))

        (__local_index = __local_parent)


    }

    ((unsafe (unsafe *__param_heap).values[__local_index]) = __param_value)

    return 1

}

pub unsafe fn binary_heap_pop(__param_heap: *mut _BinaryHeap) -> *mut c_void {
    var __local_result: *mut c_void

    var __local_new_value: *mut c_void

    var __local_index: c_uint

    var __local_next_index: c_uint

    var __local_child1: c_uint

    var __local_child2: c_uint


    if ((if (unsafe *__param_heap).num_values == 0: 1 else: 0) != 0) {
        return binary_heap_null_value

    }

    (__local_result = (unsafe (unsafe *__param_heap).values[0]))

    (__local_new_value = (unsafe (unsafe *__param_heap).values[(((unsafe *__param_heap).num_values as c_uint) -% (1 as c_uint))]))

    ((unsafe *__param_heap).num_values = ((unsafe *__param_heap).num_values -% 1))

    (__local_index = ((0 as c_uint)))

    while true {
        (__local_child1 = ((((((__local_index as c_uint) *% (2 as c_uint)) as c_uint) +% (1 as c_uint)) as c_uint)))

        (__local_child2 = ((((((__local_index as c_uint) *% (2 as c_uint)) as c_uint) +% (2 as c_uint)) as c_uint)))

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_child1 < (unsafe *__param_heap).num_values: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if binary_heap_cmp(__param_heap, __local_new_value, (unsafe (unsafe *__param_heap).values[__local_child1])) > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            var __ci_expr_logic_1: c_int = 0

            if ((if __local_child2 < (unsafe *__param_heap).num_values: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if binary_heap_cmp(__param_heap, (unsafe (unsafe *__param_heap).values[__local_child1]), (unsafe (unsafe *__param_heap).values[__local_child2])) > 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__local_next_index = __local_child2)

            } else {
                (__local_next_index = __local_child1)

            }


        } else {
            var __ci_expr_logic_2: c_int = 0

            if ((if __local_child2 < (unsafe *__param_heap).num_values: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if binary_heap_cmp(__param_heap, __local_new_value, (unsafe (unsafe *__param_heap).values[__local_child2])) > 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__local_next_index = __local_child2)

            } else {
                ((unsafe (unsafe *__param_heap).values[__local_index]) = __local_new_value)

                break

            }

        }


        ((unsafe (unsafe *__param_heap).values[__local_index]) = (unsafe (unsafe *__param_heap).values[__local_next_index]))

        (__local_index = __local_next_index)

    }

    return __local_result

}

pub unsafe fn binary_heap_num_entries(__param_heap: *mut _BinaryHeap) -> c_uint {
    return (unsafe *__param_heap).num_values

}

unsafe fn binary_heap_cmp(__param_heap: *mut _BinaryHeap, __param_data1: *mut c_void, __param_data2: *mut c_void) -> c_int {
    if ((if (unsafe *__param_heap).heap_type == 0: 1 else: 0) != 0) {
        return (unsafe *__param_heap).compare_func(__param_data1, __param_data2)

    }
    return (0 - (unsafe *__param_heap).compare_func(__param_data1, __param_data2))


}

let binary_heap_null_value: *mut c_void = null
