// Migrated from C
use std.engines.c_algorithms.defs
use std.option
use std.collections

pub fn binomial_heap_new(__param_heap_type: i32, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _BinomialHeap {
    var __local_new_heap: *mut _BinomialHeap

    (__local_new_heap = (((with_alloc_zeroed(((1 as u64) as i64), ((sizeof[_BinomialHeap]() as u64) as i64)) as *mut c_void) as *mut _BinomialHeap)))

    if (__local_new_heap == null) {
        return ((null as *mut _BinomialHeap))

    }

    ((unsafe *__local_new_heap).heap_type = __param_heap_type)

    ((unsafe *__local_new_heap).compare_func = __param_compare_func)

    return __local_new_heap

}

// contract: unproved:0:frees a part of it
pub unsafe fn binomial_heap_free(__param_heap: *mut _BinomialHeap) {
    var __local_i: u32

    (__local_i = ((0 as u32)))

    while (__local_i < (*__param_heap).roots_length) {
        binomial_tree_unref(((*__param_heap).roots[__local_i]))


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_heap).roots as *mut c_void) as *mut u8))

    with_free(((__param_heap as *mut c_void) as *mut u8))

}

// contract: receiver-mut:_BinomialHeap,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn binomial_heap_insert(__param_heap: *mut _BinomialHeap, __param_value: *mut c_void) -> i32 {
    var __local_fake_heap: _BinomialHeap

    var __local_new_tree: *mut _BinomialTree

    var __local_result: i32

    (__local_new_tree = (((with_alloc(((sizeof[_BinomialTree]() as u64) as i64)) as *mut c_void) as *mut _BinomialTree)))

    if (__local_new_tree == null) {
        return 0

    }

    ((*__local_new_tree).value = __param_value)

    ((*__local_new_tree).order = ((0 as u16)))

    ((*__local_new_tree).refcount = ((1 as u16)))

    ((*__local_new_tree).subtrees = ((null as *mut *mut _BinomialTree)))

    (__local_fake_heap.heap_type = (*__param_heap).heap_type)

    (__local_fake_heap.compare_func = (*__param_heap).compare_func)

    (__local_fake_heap.num_values = ((1 as u32)))

    (__local_fake_heap.roots = ((&raw mut __local_new_tree as *mut *mut _BinomialTree)))

    (__local_fake_heap.roots_length = ((1 as u32)))

    (__local_result = ((binomial_heap_merge(__param_heap, (&raw mut __local_fake_heap as *mut _BinomialHeap)) as i32)))

    if (__local_result != 0) {
        ((*__param_heap).num_values = ((*__param_heap).num_values +% 1))

    }

    binomial_tree_unref(__local_new_tree)

    return __local_result

}

// contract: receiver:_BinomialHeap,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn binomial_heap_cmp(__param_heap: *mut _BinomialHeap, __param_data1: *mut c_void, __param_data2: *mut c_void) -> i32 {
    if ((*__param_heap).heap_type == 0) {
        return (*__param_heap).compare_func.unwrap()(__param_data1, __param_data2)

    }
    return (0 - (*__param_heap).compare_func.unwrap()(__param_data1, __param_data2))


}

// contract: unproved:0:NULL is an accepted argument
unsafe fn binomial_tree_ref(__param_tree: *mut _BinomialTree) {
    if (__param_tree != null) {
        ((*__param_tree).refcount = ((*__param_tree).refcount +% 1))

    }

}

// contract: unproved:0:NULL is an accepted argument
unsafe fn binomial_tree_unref(__param_tree: *mut _BinomialTree) -> Unit {
    var __local_i: i32

    if (__param_tree == null) {
        return

    }

    ((*__param_tree).refcount = ((*__param_tree).refcount -% 1))

    if ((*__param_tree).refcount == 0) {
        (__local_i = ((0 as i32)))

        while (__local_i < (*__param_tree).order) {
            binomial_tree_unref(((*__param_tree).subtrees[__local_i]))


            (__local_i = __local_i + 1)

        }


        with_free((((*__param_tree).subtrees as *mut c_void) as *mut u8))

        with_free(((__param_tree as *mut c_void) as *mut u8))

    }

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn binomial_tree_merge(__param_heap: *mut _BinomialHeap, __param_tree1: *mut _BinomialTree, __param_tree2: *mut _BinomialTree) -> *mut _BinomialTree {
    var __local_tree1 = __param_tree1
    var __local_tree2 = __param_tree2
    var __local_new_tree: *mut _BinomialTree

    var __local_tmp: *mut _BinomialTree

    var __local_i: i32

    if (binomial_heap_cmp(__param_heap, (*__local_tree1).value, (*__local_tree2).value) > 0) {
        (__local_tmp = __local_tree1)

        (__local_tree1 = __local_tree2)

        (__local_tree2 = __local_tmp)

    }

    (__local_new_tree = (((with_alloc(((sizeof[_BinomialTree]() as u64) as i64)) as *mut c_void) as *mut _BinomialTree)))

    if (__local_new_tree == null) {
        return ((null as *mut _BinomialTree))

    }

    ((*__local_new_tree).refcount = ((0 as u16)))

    ((*__local_new_tree).order = (((((*__local_tree1).order as i32) + 1) as u16)))

    ((*__local_new_tree).value = (*__local_tree1).value)

    ((*__local_new_tree).subtrees = (((with_alloc(((((sizeof[usize]() as u64) *% (((*__local_new_tree).order as i32) as u64)) as u64) as i64)) as *mut c_void) as *mut *mut _BinomialTree)))

    if ((*__local_new_tree).subtrees == null) {
        with_free(((__local_new_tree as *mut c_void) as *mut u8))

        return ((null as *mut _BinomialTree))

    }

    with_memcpy((((*__local_new_tree).subtrees as *mut c_void) as *mut u8), (((*__local_tree1).subtrees as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((*__local_tree1).order as i32) as u64)) as u64) as i64))

    (((*__local_new_tree).subtrees[(((*__local_new_tree).order as i32) - 1)]) = __local_tree2)

    (__local_i = ((0 as i32)))

    while (__local_i < (*__local_new_tree).order) {
        binomial_tree_ref(((*__local_new_tree).subtrees[__local_i]))


        (__local_i = __local_i + 1)

    }


    return __local_new_tree

}

// contract: unproved:0:read only
unsafe fn binomial_heap_merge_undo(__param_new_roots: *mut *mut _BinomialTree, __param_count: u32) {
    var __local_i: u32

    (__local_i = ((0 as u32)))

    while (__local_i <= __param_count) {
        binomial_tree_unref((__param_new_roots[__local_i]))


        (__local_i = (__local_i +% 1))

    }


    with_free(((__param_new_roots as *mut c_void) as *mut u8))

}

// contract: receiver-mut:_BinomialHeap,unproved:1:read only
unsafe fn binomial_heap_merge(__param_heap: *mut _BinomialHeap, __param_other: *mut _BinomialHeap) -> i32 {
    var __local_new_roots: *mut *mut _BinomialTree

    var __local_new_roots_length: u32

    var __local_vals: List[*mut _BinomialTree] = [null; 3]

    var __local_num_vals: i32

    var __local_carry: *mut _BinomialTree

    var __local_new_carry: *mut _BinomialTree

    var __local_max: u32

    var __local_i: u32

    if ((*__param_heap).roots_length > (*__param_other).roots_length) {
        (__local_max = (((((*__param_heap).roots_length as u32) +% (1 as u32)) as u32)))

    } else {
        (__local_max = (((((*__param_other).roots_length as u32) +% (1 as u32)) as u32)))

    }

    (__local_new_roots = (((with_alloc(((((sizeof[usize]() as u64) *% (__local_max as u64)) as u64) as i64)) as *mut c_void) as *mut *mut _BinomialTree)))

    if (__local_new_roots == null) {
        return 0

    }

    (__local_new_roots_length = ((0 as u32)))

    (__local_carry = ((null as *mut _BinomialTree)))

    (__local_i = ((0 as u32)))

    while (__local_i < __local_max) {
        (__local_num_vals = ((0 as i32)))

        var __ci_expr_logic_0: i32 = 0

        if (__local_i < (*__param_heap).roots_length) {
            (__ci_expr_logic_0 = (if ((*__param_heap).roots[__local_i]) != null: 1 else: 0))
        }

        if __ci_expr_logic_0 {
            (__local_vals[__local_num_vals] = ((*__param_heap).roots[__local_i]))

            (__local_num_vals = __local_num_vals + 1)

        }


        var __ci_expr_logic_1: i32 = 0

        if (__local_i < (*__param_other).roots_length) {
            (__ci_expr_logic_1 = (if ((*__param_other).roots[__local_i]) != null: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            (__local_vals[__local_num_vals] = ((*__param_other).roots[__local_i]))

            (__local_num_vals = __local_num_vals + 1)

        }


        if (__local_carry != null) {
            (__local_vals[__local_num_vals] = __local_carry)

            (__local_num_vals = __local_num_vals + 1)

        }

        if (((__local_num_vals as i32) & (1 as i32)) != 0) {
            ((__local_new_roots[__local_i]) = __local_vals[(__local_num_vals - 1)])

            binomial_tree_ref((__local_new_roots[__local_i]))

            (__local_new_roots_length = ((((__local_i as u32) +% (1 as u32)) as u32)))

        } else {
            ((__local_new_roots[__local_i]) = ((null as *mut _BinomialTree)))

        }

        if (((__local_num_vals as i32) & (2 as i32)) != 0) {
            (__local_new_carry = binomial_tree_merge(__param_heap, __local_vals[0], __local_vals[1]))

            if (__local_new_carry == null) {
                binomial_heap_merge_undo(__local_new_roots, __local_i)

                binomial_tree_unref(__local_carry)

                return 0

            }

        } else {
            (__local_new_carry = ((null as *mut _BinomialTree)))

        }

        binomial_tree_unref(__local_carry)

        (__local_carry = __local_new_carry)

        binomial_tree_ref(__local_carry)


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((0 as u32)))

    while (__local_i < (*__param_heap).roots_length) {
        if (((*__param_heap).roots[__local_i]) != null) {
            binomial_tree_unref(((*__param_heap).roots[__local_i]))

        }


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_heap).roots as *mut c_void) as *mut u8))

    ((*__param_heap).roots = __local_new_roots)

    ((*__param_heap).roots_length = __local_new_roots_length)

    return 1

}

impl _BinomialHeap {
    pub mut fn binomial_heap_pop() -> *mut c_void {
        let __param_heap: *mut _BinomialHeap = self as *mut _BinomialHeap
        var __local_least_tree: *mut _BinomialTree

        var __local_fake_heap: _BinomialHeap

        var __local_result: *mut c_void

        var __local_i: u32

        var __local_least_index: u32

        if ((unsafe *__param_heap).num_values == 0) {
            return binomial_heap_null_value

        }

        (__local_least_index = ((((((2147483647 as u32) *% (2 as u32)) as u32) +% (1 as u32)) as u32)))

        (__local_i = ((0 as u32)))

        while (__local_i < (unsafe *__param_heap).roots_length) {
            if ((unsafe (*__param_heap).roots[__local_i]) == null) {
                (__local_i = (__local_i +% 1))

                continue


            }

            var __ci_expr_logic_0: i32

            if (__local_least_index == ((((2147483647 as u32) *% (2 as u32)) as u32) +% (1 as u32))) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if unsafe { binomial_heap_cmp(__param_heap, ((*__param_heap).roots[__local_i]).value, ((*__param_heap).roots[__local_least_index]).value) } < 0: 1 else: 0))
            }

            if __ci_expr_logic_0 {
                (__local_least_index = __local_i)

            }



            (__local_i = (__local_i +% 1))

        }


        (__local_least_tree = (unsafe (*__param_heap).roots[__local_least_index]))

        ((unsafe (*__param_heap).roots[__local_least_index]) = ((null as *mut _BinomialTree)))

        (__local_fake_heap.heap_type = (unsafe *__param_heap).heap_type)

        (__local_fake_heap.compare_func = (unsafe *__param_heap).compare_func)

        (__local_fake_heap.roots = (unsafe *__local_least_tree).subtrees)

        (__local_fake_heap.roots_length = (((unsafe *__local_least_tree).order as u32)))

        if unsafe { binomial_heap_merge(__param_heap, (&raw mut __local_fake_heap as *mut _BinomialHeap)) } {
            (__local_result = (unsafe *__local_least_tree).value)

            unsafe { binomial_tree_unref(__local_least_tree) }

            ((unsafe *__param_heap).num_values = ((unsafe *__param_heap).num_values -% 1))

            return __local_result

        }
        ((unsafe (*__param_heap).roots[__local_least_index]) = __local_least_tree)

        return binomial_heap_null_value


    }

    pub fn binomial_heap_num_entries() -> u32 {
        let __param_heap: *mut _BinomialHeap = (self as *const _BinomialHeap) as *mut _BinomialHeap
        return (unsafe *__param_heap).num_values

    }

}

let binomial_heap_null_value: *mut c_void = null
