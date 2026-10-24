// Migrated from C
use std.engines.c_algorithms.defs
use std.option

pub fn binary_heap_new(__param_heap_type: i32, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _BinaryHeap {
    var __local_heap: *mut _BinaryHeap

    (__local_heap = (((with_alloc(((sizeof[_BinaryHeap]() as u64) as i64)) as *mut c_void) as *mut _BinaryHeap)))

    if ((if __local_heap == null: 1 else: 0) != 0) {
        return ((null as *mut _BinaryHeap))

    }

    ((unsafe *__local_heap).heap_type = __param_heap_type)

    ((unsafe *__local_heap).num_values = ((0 as u32)))

    ((unsafe *__local_heap).compare_func = __param_compare_func)

    ((unsafe *__local_heap).alloced_size = ((16 as u32)))

    ((unsafe *__local_heap).values = (((with_alloc(((((sizeof[usize]() as u64) *% ((unsafe *__local_heap).alloced_size as u64)) as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

    if ((if (unsafe *__local_heap).values == null: 1 else: 0) != 0) {
        with_free(((__local_heap as *mut c_void) as *mut u8))

        return ((null as *mut _BinaryHeap))

    }

    return __local_heap

}

pub unsafe fn binary_heap_free(__param_heap: *mut _BinaryHeap) {
    with_free((((*__param_heap).values as *mut c_void) as *mut u8))

    with_free(((__param_heap as *mut c_void) as *mut u8))

}

pub unsafe fn binary_heap_insert(__param_heap: *mut _BinaryHeap, __param_value: *mut c_void) -> i32 {
    var __local_new_values: *mut *mut c_void

    var __local_index: u32

    var __local_new_size: u32

    var __local_parent: u32

    if ((if (*__param_heap).num_values >= (*__param_heap).alloced_size: 1 else: 0) != 0) {
        (__local_new_size = (((((*__param_heap).alloced_size as u32) *% (2 as u32)) as u32)))

        (__local_new_values = (((with_realloc((((*__param_heap).values as *mut c_void) as *mut u8), (0 as i64), ((((sizeof[usize]() as u64) *% (__local_new_size as u64)) as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

        if ((if __local_new_values == null: 1 else: 0) != 0) {
            return 0

        }

        ((*__param_heap).alloced_size = __local_new_size)

        ((*__param_heap).values = __local_new_values)

    }

    (__local_index = (*__param_heap).num_values)

    ((*__param_heap).num_values = ((*__param_heap).num_values +% 1))

    while ((if __local_index > 0: 1 else: 0) != 0) {
        (__local_parent = ((((((__local_index as u32) -% (1 as u32)) as u32) / (2 as u32)) as u32)))

        if ((if binary_heap_cmp(__param_heap, ((*__param_heap).values[__local_parent]), __param_value) < 0: 1 else: 0) != 0) {
            break

        }
        (((*__param_heap).values[__local_index]) = ((*__param_heap).values[__local_parent]))

        (__local_index = __local_parent)


    }

    (((*__param_heap).values[__local_index]) = __param_value)

    return 1

}

pub unsafe fn binary_heap_pop(__param_heap: *mut _BinaryHeap) -> *mut c_void {
    var __local_result: *mut c_void

    var __local_new_value: *mut c_void

    var __local_index: u32

    var __local_next_index: u32

    var __local_child1: u32

    var __local_child2: u32


    if ((if (*__param_heap).num_values == 0: 1 else: 0) != 0) {
        return binary_heap_null_value

    }

    (__local_result = ((*__param_heap).values[0]))

    (__local_new_value = ((*__param_heap).values[(((*__param_heap).num_values as u32) -% (1 as u32))]))

    ((*__param_heap).num_values = ((*__param_heap).num_values -% 1))

    (__local_index = ((0 as u32)))

    while true {
        (__local_child1 = ((((((__local_index as u32) *% (2 as u32)) as u32) +% (1 as u32)) as u32)))

        (__local_child2 = ((((((__local_index as u32) *% (2 as u32)) as u32) +% (2 as u32)) as u32)))

        var __ci_expr_logic_0: i32 = 0

        if ((if __local_child1 < (*__param_heap).num_values: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if binary_heap_cmp(__param_heap, __local_new_value, ((*__param_heap).values[__local_child1])) > 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            var __ci_expr_logic_1: i32 = 0

            if ((if __local_child2 < (*__param_heap).num_values: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if binary_heap_cmp(__param_heap, ((*__param_heap).values[__local_child1]), ((*__param_heap).values[__local_child2])) > 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__local_next_index = __local_child2)

            } else {
                (__local_next_index = __local_child1)

            }


        } else {
            var __ci_expr_logic_2: i32 = 0

            if ((if __local_child2 < (*__param_heap).num_values: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if binary_heap_cmp(__param_heap, __local_new_value, ((*__param_heap).values[__local_child2])) > 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__local_next_index = __local_child2)

            } else {
                (((*__param_heap).values[__local_index]) = __local_new_value)

                break

            }

        }


        (((*__param_heap).values[__local_index]) = ((*__param_heap).values[__local_next_index]))

        (__local_index = __local_next_index)

    }

    return __local_result

}

pub unsafe fn binary_heap_num_entries(__param_heap: *mut _BinaryHeap) -> u32 {
    return (*__param_heap).num_values

}

unsafe fn binary_heap_cmp(__param_heap: *mut _BinaryHeap, __param_data1: *mut c_void, __param_data2: *mut c_void) -> i32 {
    if ((if (*__param_heap).heap_type == 0: 1 else: 0) != 0) {
        return (*__param_heap).compare_func.unwrap()(__param_data1, __param_data2)

    }
    return (0 - (*__param_heap).compare_func.unwrap()(__param_data1, __param_data2))


}

let binary_heap_null_value: *mut c_void = null
