// Migrated from C
use std.c_algorithms.defs

pub fn binomial_heap_new(__param_heap_type: i32, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _BinomialHeap {
    var __local_new_heap: *mut _BinomialHeap

    (__local_new_heap = (((unsafe { with_alloc_zeroed(((1 as c_ulong) as i64), ((sizeof[_BinomialHeap]() as c_ulong) as i64)) } as *mut c_void) as *mut _BinomialHeap)))

    if ((if __local_new_heap == null: 1 else: 0) != 0) {
        return ((null as *mut _BinomialHeap))

    }

    ((unsafe *__local_new_heap).heap_type = __param_heap_type)

    ((unsafe *__local_new_heap).compare_func = __param_compare_func)

    return __local_new_heap

}

pub unsafe fn binomial_heap_free(__param_heap: *mut _BinomialHeap) -> Unit {
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_heap).roots_length: 1 else: 0) != 0) {
        binomial_tree_unref(((*__param_heap).roots[__local_i]))


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_heap).roots as *mut c_void) as *mut u8))

    with_free(((__param_heap as *mut c_void) as *mut u8))

}

pub unsafe fn binomial_heap_insert(__param_heap: *mut _BinomialHeap, __param_value: *mut c_void) -> c_int {
    var __local_fake_heap: _BinomialHeap

    var __local_new_tree: *mut _BinomialTree

    var __local_result: c_int

    (__local_new_tree = (((with_alloc(((sizeof[_BinomialTree]() as c_ulong) as i64)) as *mut c_void) as *mut _BinomialTree)))

    if ((if __local_new_tree == null: 1 else: 0) != 0) {
        return 0

    }

    ((*__local_new_tree).value = __param_value)

    ((*__local_new_tree).order = ((0 as c_ushort)))

    ((*__local_new_tree).refcount = ((1 as c_ushort)))

    ((*__local_new_tree).subtrees = ((null as *mut *mut _BinomialTree)))

    (__local_fake_heap.heap_type = (*__param_heap).heap_type)

    (__local_fake_heap.compare_func = (*__param_heap).compare_func)

    (__local_fake_heap.num_values = ((1 as c_uint)))

    (__local_fake_heap.roots = ((&raw mut __local_new_tree as *mut *mut _BinomialTree)))

    (__local_fake_heap.roots_length = ((1 as c_uint)))

    (__local_result = ((binomial_heap_merge(__param_heap, (&raw mut __local_fake_heap as *mut _BinomialHeap)) as c_int)))

    if ((if __local_result != 0: 1 else: 0) != 0) {
        ((*__param_heap).num_values = ((*__param_heap).num_values +% 1))

    }

    binomial_tree_unref(__local_new_tree)

    return __local_result

}

pub unsafe fn binomial_heap_pop(__param_heap: *mut _BinomialHeap) -> *mut c_void {
    var __local_least_tree: *mut _BinomialTree

    var __local_fake_heap: _BinomialHeap

    var __local_result: *mut c_void

    var __local_i: c_uint

    var __local_least_index: c_uint

    if ((if (*__param_heap).num_values == 0: 1 else: 0) != 0) {
        return binomial_heap_null_value

    }

    (__local_least_index = ((((((2147483647 as c_uint) *% (2 as c_uint)) as c_uint) +% (1 as c_uint)) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_heap).roots_length: 1 else: 0) != 0) {
        if ((if ((*__param_heap).roots[__local_i]) == null: 1 else: 0) != 0) {
            (__local_i = (__local_i +% 1))

            continue


        }

        var __ci_expr_logic_0: c_int

        if ((if __local_least_index == ((((2147483647 as c_uint) *% (2 as c_uint)) as c_uint) +% (1 as c_uint)): 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if binomial_heap_cmp(__param_heap, ((*__param_heap).roots[__local_i]).value, ((*__param_heap).roots[__local_least_index]).value) < 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_least_index = __local_i)

        }



        (__local_i = (__local_i +% 1))

    }


    (__local_least_tree = ((*__param_heap).roots[__local_least_index]))

    (((*__param_heap).roots[__local_least_index]) = ((null as *mut _BinomialTree)))

    (__local_fake_heap.heap_type = (*__param_heap).heap_type)

    (__local_fake_heap.compare_func = (*__param_heap).compare_func)

    (__local_fake_heap.roots = (*__local_least_tree).subtrees)

    (__local_fake_heap.roots_length = (((*__local_least_tree).order as c_uint)))

    if (binomial_heap_merge(__param_heap, (&raw mut __local_fake_heap as *mut _BinomialHeap)) != 0) {
        (__local_result = (*__local_least_tree).value)

        binomial_tree_unref(__local_least_tree)

        ((*__param_heap).num_values = ((*__param_heap).num_values -% 1))

        return __local_result

    }
    (((*__param_heap).roots[__local_least_index]) = __local_least_tree)

    return binomial_heap_null_value


}

pub unsafe fn binomial_heap_num_entries(__param_heap: *mut _BinomialHeap) -> c_uint {
    return (*__param_heap).num_values

}

unsafe fn binomial_heap_cmp(__param_heap: *mut _BinomialHeap, __param_data1: *mut c_void, __param_data2: *mut c_void) -> c_int {
    if ((if (*__param_heap).heap_type == 0: 1 else: 0) != 0) {
        return (*__param_heap).compare_func(__param_data1, __param_data2)

    }
    return (0 - (*__param_heap).compare_func(__param_data1, __param_data2))


}

unsafe fn binomial_tree_ref(__param_tree: *mut _BinomialTree) -> Unit {
    if ((if __param_tree != null: 1 else: 0) != 0) {
        ((*__param_tree).refcount = ((*__param_tree).refcount +% 1))

    }

}

unsafe fn binomial_tree_unref(__param_tree: *mut _BinomialTree) -> Unit {
    var __local_i: c_int

    if ((if __param_tree == null: 1 else: 0) != 0) {
        return

    }

    ((*__param_tree).refcount = ((*__param_tree).refcount -% 1))

    if ((if (*__param_tree).refcount == 0: 1 else: 0) != 0) {
        (__local_i = ((0 as c_int)))

        while ((if __local_i < (*__param_tree).order: 1 else: 0) != 0) {
            binomial_tree_unref(((*__param_tree).subtrees[__local_i]))


            (__local_i = __local_i + 1)

        }


        with_free((((*__param_tree).subtrees as *mut c_void) as *mut u8))

        with_free(((__param_tree as *mut c_void) as *mut u8))

    }

}

unsafe fn binomial_tree_merge(__param_heap: *mut _BinomialHeap, __param_tree1: *mut _BinomialTree, __param_tree2: *mut _BinomialTree) -> *mut _BinomialTree {
    var __local_tree1 = __param_tree1
    var __local_tree2 = __param_tree2
    var __local_new_tree: *mut _BinomialTree

    var __local_tmp: *mut _BinomialTree

    var __local_i: c_int

    if ((if binomial_heap_cmp(__param_heap, (*__local_tree1).value, (*__local_tree2).value) > 0: 1 else: 0) != 0) {
        (__local_tmp = __local_tree1)

        (__local_tree1 = __local_tree2)

        (__local_tree2 = __local_tmp)

    }

    (__local_new_tree = (((with_alloc(((sizeof[_BinomialTree]() as c_ulong) as i64)) as *mut c_void) as *mut _BinomialTree)))

    if ((if __local_new_tree == null: 1 else: 0) != 0) {
        return ((null as *mut _BinomialTree))

    }

    ((*__local_new_tree).refcount = ((0 as c_ushort)))

    ((*__local_new_tree).order = (((((*__local_tree1).order as c_int) + 1) as c_ushort)))

    ((*__local_new_tree).value = (*__local_tree1).value)

    ((*__local_new_tree).subtrees = (((with_alloc(((((sizeof[usize]() as c_ulong) *% (((*__local_new_tree).order as c_int) as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut _BinomialTree)))

    if ((if (*__local_new_tree).subtrees == null: 1 else: 0) != 0) {
        with_free(((__local_new_tree as *mut c_void) as *mut u8))

        return ((null as *mut _BinomialTree))

    }

    with_memcpy((((*__local_new_tree).subtrees as *mut c_void) as *mut u8), (((*__local_tree1).subtrees as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% (((*__local_tree1).order as c_int) as c_ulong)) as c_ulong) as i64))

    (((*__local_new_tree).subtrees[(((*__local_new_tree).order as c_int) - 1)]) = __local_tree2)

    (__local_i = ((0 as c_int)))

    while ((if __local_i < (*__local_new_tree).order: 1 else: 0) != 0) {
        binomial_tree_ref(((*__local_new_tree).subtrees[__local_i]))


        (__local_i = __local_i + 1)

    }


    return __local_new_tree

}

unsafe fn binomial_heap_merge_undo(__param_new_roots: *mut *mut _BinomialTree, __param_count: c_uint) -> Unit {
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i <= __param_count: 1 else: 0) != 0) {
        binomial_tree_unref((__param_new_roots[__local_i]))


        (__local_i = (__local_i +% 1))

    }


    with_free(((__param_new_roots as *mut c_void) as *mut u8))

}

unsafe fn binomial_heap_merge(__param_heap: *mut _BinomialHeap, __param_other: *mut _BinomialHeap) -> c_int {
    var __local_new_roots: *mut *mut _BinomialTree

    var __local_new_roots_length: c_uint

    var __local_vals: [3]*mut _BinomialTree

    var __local_num_vals: c_int

    var __local_carry: *mut _BinomialTree

    var __local_new_carry: *mut _BinomialTree

    var __local_max: c_uint

    var __local_i: c_uint

    if ((if (*__param_heap).roots_length > (*__param_other).roots_length: 1 else: 0) != 0) {
        (__local_max = (((((*__param_heap).roots_length as c_uint) +% (1 as c_uint)) as c_uint)))

    } else {
        (__local_max = (((((*__param_other).roots_length as c_uint) +% (1 as c_uint)) as c_uint)))

    }

    (__local_new_roots = (((with_alloc(((((sizeof[usize]() as c_ulong) *% (__local_max as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut _BinomialTree)))

    if ((if __local_new_roots == null: 1 else: 0) != 0) {
        return 0

    }

    (__local_new_roots_length = ((0 as c_uint)))

    (__local_carry = ((null as *mut _BinomialTree)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_max: 1 else: 0) != 0) {
        (__local_num_vals = ((0 as c_int)))

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_i < (*__param_heap).roots_length: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if ((*__param_heap).roots[__local_i]) != null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_vals[__local_num_vals] = ((*__param_heap).roots[__local_i]))

            (__local_num_vals = __local_num_vals + 1)

        }


        var __ci_expr_logic_1: c_int = 0

        if ((if __local_i < (*__param_other).roots_length: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if ((*__param_other).roots[__local_i]) != null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_vals[__local_num_vals] = ((*__param_other).roots[__local_i]))

            (__local_num_vals = __local_num_vals + 1)

        }


        if ((if __local_carry != null: 1 else: 0) != 0) {
            (__local_vals[__local_num_vals] = __local_carry)

            (__local_num_vals = __local_num_vals + 1)

        }

        if ((if ((__local_num_vals as c_int) & (1 as c_int)) != 0: 1 else: 0) != 0) {
            ((__local_new_roots[__local_i]) = __local_vals[(__local_num_vals - 1)])

            binomial_tree_ref((__local_new_roots[__local_i]))

            (__local_new_roots_length = ((((__local_i as c_uint) +% (1 as c_uint)) as c_uint)))

        } else {
            ((__local_new_roots[__local_i]) = ((null as *mut _BinomialTree)))

        }

        if ((if ((__local_num_vals as c_int) & (2 as c_int)) != 0: 1 else: 0) != 0) {
            (__local_new_carry = binomial_tree_merge(__param_heap, __local_vals[0], __local_vals[1]))

            if ((if __local_new_carry == null: 1 else: 0) != 0) {
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


    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_heap).roots_length: 1 else: 0) != 0) {
        if ((if ((*__param_heap).roots[__local_i]) != null: 1 else: 0) != 0) {
            binomial_tree_unref(((*__param_heap).roots[__local_i]))

        }


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_heap).roots as *mut c_void) as *mut u8))

    ((*__param_heap).roots = __local_new_roots)

    ((*__param_heap).roots_length = __local_new_roots_length)

    return 1

}

let binomial_heap_null_value: *mut c_void = null
