// Migrated from C
use std.engines.c_algorithms.defs
use std.option

pub fn binary_heap_new(__param_heap_type: i32, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _BinaryHeap {
    var __local_heap: *mut _BinaryHeap

    (__local_heap = (((with_alloc(((sizeof[_BinaryHeap]() as u64) as i64)) as *mut c_void) as *mut _BinaryHeap)))

    if (__local_heap == null) {
        return ((null as *mut _BinaryHeap))

    }

    ((unsafe *__local_heap).heap_type = __param_heap_type)

    ((unsafe *__local_heap).num_values = ((0 as u32)))

    ((unsafe *__local_heap).compare_func = __param_compare_func)

    ((unsafe *__local_heap).alloced_size = ((16 as u32)))

    ((unsafe *__local_heap).values = (((with_alloc(((((sizeof[usize]() as u64) *% ((unsafe *__local_heap).alloced_size as u64)) as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

    if ((unsafe *__local_heap).values == null) {
        with_free(((__local_heap as *mut c_void) as *mut u8))

        return ((null as *mut _BinaryHeap))

    }

    return __local_heap

}

// contract: unproved:0:frees a part of it
pub unsafe fn binary_heap_free(__param_heap: *mut _BinaryHeap) {
    with_free((((*__param_heap).values as *mut c_void) as *mut u8))

    with_free(((__param_heap as *mut c_void) as *mut u8))

}

// contract: receiver-mut:_BinaryHeap,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn binary_heap_insert(__param_heap: *mut _BinaryHeap, __param_value: *mut c_void) -> i32 {
    var __local_new_values: *mut *mut c_void

    var __local_index: u32

    var __local_new_size: u32

    var __local_parent: u32

    if ((*__param_heap).num_values >= (*__param_heap).alloced_size) {
        (__local_new_size = (((((*__param_heap).alloced_size as u32) *% (2 as u32)) as u32)))

        (__local_new_values = (((with_realloc((((*__param_heap).values as *mut c_void) as *mut u8), (0 as i64), ((((sizeof[usize]() as u64) *% (__local_new_size as u64)) as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

        if (__local_new_values == null) {
            return 0

        }

        ((*__param_heap).alloced_size = __local_new_size)

        ((*__param_heap).values = __local_new_values)

    }

    (__local_index = (*__param_heap).num_values)

    ((*__param_heap).num_values = ((*__param_heap).num_values +% 1))

    while (__local_index > 0) {
        (__local_parent = ((((((__local_index as u32) -% (1 as u32)) as u32) / (2 as u32)) as u32)))

        if (binary_heap_cmp(__param_heap, ((*__param_heap).values[__local_parent]), __param_value) < 0) {
            break

        }
        (((*__param_heap).values[__local_index]) = ((*__param_heap).values[__local_parent]))

        (__local_index = __local_parent)


    }

    (((*__param_heap).values[__local_index]) = __param_value)

    return 1

}

// contract: receiver:_BinaryHeap,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn binary_heap_cmp(__param_heap: *mut _BinaryHeap, __param_data1: *mut c_void, __param_data2: *mut c_void) -> i32 {
    if ((*__param_heap).heap_type == 0) {
        return (*__param_heap).compare_func.unwrap()(__param_data1, __param_data2)

    }
    return (0 - (*__param_heap).compare_func.unwrap()(__param_data1, __param_data2))


}

impl _BinaryHeap {
    pub mut fn binary_heap_pop() -> *mut c_void {
        let __param_heap: *mut _BinaryHeap = self as *mut _BinaryHeap
        var __local_result: *mut c_void

        var __local_new_value: *mut c_void

        var __local_index: u32

        var __local_next_index: u32

        var __local_child1: u32

        var __local_child2: u32


        if ((unsafe *__param_heap).num_values == 0) {
            return binary_heap_null_value

        }

        (__local_result = (unsafe (*__param_heap).values[0]))

        (__local_new_value = (unsafe (*__param_heap).values[(((*__param_heap).num_values as u32) -% (1 as u32))]))

        ((unsafe *__param_heap).num_values = ((unsafe *__param_heap).num_values -% 1))

        (__local_index = ((0 as u32)))

        while true {
            (__local_child1 = ((((((__local_index as u32) *% (2 as u32)) as u32) +% (1 as u32)) as u32)))

            (__local_child2 = ((((((__local_index as u32) *% (2 as u32)) as u32) +% (2 as u32)) as u32)))

            var __ci_expr_logic_0: i32 = 0

            if (__local_child1 < (unsafe *__param_heap).num_values) {
                (__ci_expr_logic_0 = (if unsafe { binary_heap_cmp(__param_heap, __local_new_value, ((*__param_heap).values[__local_child1])) } > 0: 1 else: 0))
            }

            if __ci_expr_logic_0 {
                var __ci_expr_logic_1: i32 = 0

                if (__local_child2 < (unsafe *__param_heap).num_values) {
                    (__ci_expr_logic_1 = (if unsafe { binary_heap_cmp(__param_heap, ((*__param_heap).values[__local_child1]), ((*__param_heap).values[__local_child2])) } > 0: 1 else: 0))
                }

                if __ci_expr_logic_1 {
                    (__local_next_index = __local_child2)

                } else {
                    (__local_next_index = __local_child1)

                }


            } else {
                var __ci_expr_logic_2: i32 = 0

                if (__local_child2 < (unsafe *__param_heap).num_values) {
                    (__ci_expr_logic_2 = (if unsafe { binary_heap_cmp(__param_heap, __local_new_value, ((*__param_heap).values[__local_child2])) } > 0: 1 else: 0))
                }

                if __ci_expr_logic_2 {
                    (__local_next_index = __local_child2)

                } else {
                    ((unsafe (*__param_heap).values[__local_index]) = __local_new_value)

                    break

                }

            }


            ((unsafe (*__param_heap).values[__local_index]) = (unsafe (*__param_heap).values[__local_next_index]))

            (__local_index = __local_next_index)

        }

        return __local_result

    }

    pub fn binary_heap_num_entries() -> u32 {
        let __param_heap: *mut _BinaryHeap = (self as *const _BinaryHeap) as *mut _BinaryHeap
        return (unsafe *__param_heap).num_values

    }

}

let binary_heap_null_value: *mut c_void = null
