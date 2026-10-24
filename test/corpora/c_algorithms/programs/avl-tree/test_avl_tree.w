// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.avl_tree
use std.engines.c_algorithms_testing.compare_int
use std.engines.c_algorithms_testing.framework
use std.libc
use std.option
use std.collections

pub unsafe fn find_subtree_height(__param_node: *mut _AVLTreeNode) -> i32 {
    var __local_left_subtree: *mut _AVLTreeNode

    var __local_right_subtree: *mut _AVLTreeNode

    var __local_left_height: i32

    var __local_right_height: i32


    if ((if __param_node == null: 1 else: 0) != 0) {
        return 0

    }

    (__local_left_subtree = avl_tree_node_child(__param_node, (0 as i32)))

    (__local_right_subtree = avl_tree_node_child(__param_node, (1 as i32)))

    (__local_left_height = ((find_subtree_height(__local_left_subtree) as i32)))

    (__local_right_height = ((find_subtree_height(__local_right_subtree) as i32)))

    if ((if __local_left_height > __local_right_height: 1 else: 0) != 0) {
        return (__local_left_height + 1)

    }
    return (__local_right_height + 1)


}

pub unsafe fn validate_subtree(__param_node: *mut _AVLTreeNode) -> i32 writes counter {
    var __local_left_node: *mut _AVLTreeNode

    var __local_right_node: *mut _AVLTreeNode


    var __local_left_height: i32

    var __local_right_height: i32


    var __local_key: *mut i32

    if ((if __param_node == null: 1 else: 0) != 0) {
        return 0

    }

    (__local_left_node = avl_tree_node_child(__param_node, (0 as i32)))

    (__local_right_node = avl_tree_node_child(__param_node, (1 as i32)))

    if ((if __local_left_node != null: 1 else: 0) != 0) {
        if (((if not ((if avl_tree_node_parent(__local_left_node) == __param_node: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (99 as i32), c"avl_tree_node_parent(left_node) == node".ptr)
        } else {
            0
        }

    }

    if ((if __local_right_node != null: 1 else: 0) != 0) {
        if (((if not ((if avl_tree_node_parent(__local_right_node) == __param_node: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (102 as i32), c"avl_tree_node_parent(right_node) == node".ptr)
        } else {
            0
        }

    }

    (__local_left_height = ((validate_subtree(__local_left_node) as i32)))

    (__local_key = ((avl_tree_node_key(__param_node) as *mut i32)))

    if (((if not ((if (*__local_key) > counter: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (112 as i32), c"*key > counter".ptr)
    } else {
        0
    }

    (counter = (*__local_key))

    (__local_right_height = ((validate_subtree(__local_right_node) as i32)))

    if (((if not ((if avl_tree_subtree_height(__local_left_node) == __local_left_height: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (119 as i32), c"avl_tree_subtree_height(left_node) == left_height".ptr)
    } else {
        0
    }

    if (((if not ((if avl_tree_subtree_height(__local_right_node) == __local_right_height: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (120 as i32), c"avl_tree_subtree_height(right_node) == right_height".ptr)
    } else {
        0
    }

    var __ci_expr_logic_0: i32 = 0

    if ((if (__local_left_height - __local_right_height) < 2: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (__local_right_height - __local_left_height) < 2: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (124 as i32), c"left_height - right_height < 2 && right_height - left_height < 2".ptr)
    } else {
        0
    }


    if ((if __local_left_height > __local_right_height: 1 else: 0) != 0) {
        return (__local_left_height + 1)

    }
    return (__local_right_height + 1)


}

pub unsafe fn validate_tree(__param_tree: *mut _AVLTree) -> Unit writes counter {
    var __local_root_node: *mut _AVLTreeNode

    var __local_height: i32

    (__local_root_node = avl_tree_root_node(__param_tree))

    if ((if __local_root_node != null: 1 else: 0) != 0) {
        (__local_height = ((find_subtree_height(__local_root_node) as i32)))

        if (((if not ((if avl_tree_subtree_height(__local_root_node) == __local_height: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"validate_tree".ptr, c"test-avl-tree.c".ptr, (143 as i32), c"avl_tree_subtree_height(root_node) == height".ptr)
        } else {
            0
        }

    }

    (counter = ((-1 as i32)))

    validate_subtree(__local_root_node)

}

pub fn create_tree() -> *mut _AVLTree writes allocation_limit {
    var __local_tree: *mut _AVLTree

    var __local_i: i32

    (__local_tree = avl_tree_new(Some(int_compare)))

    (__local_i = ((0 as i32)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        unsafe { avl_tree_insert(__local_tree, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    return __local_tree

}

pub fn test_avl_tree_new() -> Unit writes allocation_limit {
    var __local_tree: *mut _AVLTree

    (__local_tree = avl_tree_new(Some(int_compare)))

    if (((if not ((if __local_tree != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (172 as i32), c"tree != NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { avl_tree_root_node(__local_tree) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (173 as i32), c"avl_tree_root_node(tree) == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (174 as i32), c"avl_tree_num_entries(tree) == 0".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

    alloc_test_set_limit((0 as i32))

    (__local_tree = avl_tree_new(Some(int_compare)))

    if (((if not ((if __local_tree == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (183 as i32), c"tree == NULL".ptr)
    } else {
        0
    }

}

pub fn test_avl_tree_insert_lookup() writes allocation_limit, counter {
    var __local_tree: *mut _AVLTree

    var __local_node: *mut _AVLTreeNode

    var __local_i: u32

    var __local_value: *mut i32

    (__local_tree = avl_tree_new(Some(int_compare)))

    (__local_i = ((0 as u32)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (test_array[__local_i] = ((__local_i as i32)))

        unsafe { avl_tree_insert(__local_tree, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) }

        if (((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == ((__local_i as u32) +% (1 as u32)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (201 as i32), c"avl_tree_num_entries(tree) == i + 1".ptr)
        } else {
            0
        }

        unsafe { validate_tree(__local_tree) }


        (__local_i = (__local_i +% 1))

    }


    if (((if not ((if unsafe { avl_tree_root_node(__local_tree) } != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (205 as i32), c"avl_tree_root_node(tree) != NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as u32)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (__local_node = unsafe { avl_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut u32) as *mut c_void)) })

        if (((if not ((if __local_node != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (210 as i32), c"node != NULL".ptr)
        } else {
            0
        }

        (__local_value = ((unsafe { avl_tree_node_key(__local_node) } as *mut i32)))

        if (((if not ((if (unsafe *__local_value) == ((__local_i as i32)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (212 as i32), c"*value == (int) i".ptr)
        } else {
            0
        }

        (__local_value = ((unsafe { avl_tree_node_value(__local_node) } as *mut i32)))

        if (((if not ((if (unsafe *__local_value) == ((__local_i as i32)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (214 as i32), c"*value == (int) i".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((1100 as u32)))

    if (((if not ((if unsafe { avl_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut u32) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (219 as i32), c"avl_tree_lookup_node(tree, &i) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_child() writes allocation_limit {
    var __local_tree: *mut _AVLTree

    var __local_root: *mut _AVLTreeNode

    var __local_left: *mut _AVLTreeNode

    var __local_right: *mut _AVLTreeNode

    var __local_values: List[i32] = [1, 2, 3]

    var __local_p: *mut i32

    var __local_i: i32

    (__local_tree = avl_tree_new(Some(int_compare)))

    (__local_i = ((0 as i32)))

    while ((if __local_i < 3: 1 else: 0) != 0) {
        unsafe { avl_tree_insert(__local_tree, (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_root = unsafe { avl_tree_root_node(__local_tree) })

    (__local_p = ((unsafe { avl_tree_node_value(__local_root) } as *mut i32)))

    if (((if not ((if (unsafe *__local_p) == 2: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (245 as i32), c"*p == 2".ptr)
    } else {
        0
    }

    (__local_left = unsafe { avl_tree_node_child(__local_root, (0 as i32)) })

    (__local_p = ((unsafe { avl_tree_node_value(__local_left) } as *mut i32)))

    if (((if not ((if (unsafe *__local_p) == 1: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (249 as i32), c"*p == 1".ptr)
    } else {
        0
    }

    (__local_right = unsafe { avl_tree_node_child(__local_root, (1 as i32)) })

    (__local_p = ((unsafe { avl_tree_node_value(__local_right) } as *mut i32)))

    if (((if not ((if (unsafe *__local_p) == 3: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (253 as i32), c"*p == 3".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { avl_tree_node_child(__local_root, (10000 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (256 as i32), c"avl_tree_node_child(root, 10000) == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { avl_tree_node_child(__local_root, (2 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (257 as i32), c"avl_tree_node_child(root, 2) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_out_of_memory() writes allocation_limit, counter {
    var __local_tree: *mut _AVLTree

    var __local_node: *mut _AVLTreeNode

    var __local_i: i32

    (__local_tree = create_tree())

    alloc_test_set_limit((0 as i32))

    (__local_i = ((10000 as i32)))

    while ((if __local_i < 20000: 1 else: 0) != 0) {
        (__local_node = unsafe { avl_tree_insert(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void), ((&raw mut __local_i as *mut i32) as *mut c_void)) })

        if (((if not ((if __local_node == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-avl-tree.c".ptr, (277 as i32), c"node == NULL".ptr)
        } else {
            0
        }

        unsafe { validate_tree(__local_tree) }


        (__local_i = __local_i + 1)

    }


    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_free() writes allocation_limit {
    var __local_tree: *mut _AVLTree

    (__local_tree = avl_tree_new(Some(int_compare)))

    unsafe { avl_tree_free(__local_tree) }

    (__local_tree = create_tree())

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_lookup() writes allocation_limit {
    var __local_tree: *mut _AVLTree

    var __local_i: i32

    var __local_value: *mut i32

    (__local_tree = create_tree())

    (__local_i = ((0 as i32)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (__local_value = ((unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } as *mut i32)))

        if (((if not ((if __local_value != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (309 as i32), c"value != NULL".ptr)
        } else {
            0
        }

        if (((if not ((if (unsafe *__local_value) == __local_i: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (310 as i32), c"*value == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as i32)))

    if (((if not ((if unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (315 as i32), c"avl_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = (((1000 + 1) as i32)))

    if (((if not ((if unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (317 as i32), c"avl_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = ((8724897 as i32)))

    if (((if not ((if unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (319 as i32), c"avl_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_remove() writes allocation_limit, counter {
    var __local_tree: *mut _AVLTree

    var __local_i: i32

    var __local_x: i32

    var __local_y: i32

    var __local_z: i32


    var __local_value: i32

    var __local_expected_entries: u32

    (__local_tree = create_tree())

    (__local_i = (((1000 + 100) as i32)))

    if (((if not ((if unsafe { avl_tree_remove(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (336 as i32), c"avl_tree_remove(tree, &i) == 0".ptr)
    } else {
        0
    }

    (__local_i = ((-1 as i32)))

    if (((if not ((if unsafe { avl_tree_remove(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (338 as i32), c"avl_tree_remove(tree, &i) == 0".ptr)
    } else {
        0
    }

    (__local_expected_entries = ((1000 as u32)))

    (__local_x = ((0 as i32)))

    while ((if __local_x < 10: 1 else: 0) != 0) {
        (__local_y = ((0 as i32)))

        while ((if __local_y < 10: 1 else: 0) != 0) {
            (__local_z = ((0 as i32)))

            while ((if __local_z < 10: 1 else: 0) != 0) {
                (__local_value = (((((__local_z * 100) + ((9 - __local_y) * 10)) + __local_x) as i32)))

                if (((if not ((if unsafe { avl_tree_remove(__local_tree, ((&raw mut __local_value as *mut i32) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                    __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (349 as i32), c"avl_tree_remove(tree, &value) != 0".ptr)
                } else {
                    0
                }

                unsafe { validate_tree(__local_tree) }

                (__local_expected_entries = (__local_expected_entries -% 1))

                if (((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == __local_expected_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                    __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (353 as i32), c"avl_tree_num_entries(tree) == expected_entries".ptr)
                } else {
                    0
                }


                (__local_z = __local_z + 1)

            }



            (__local_y = __local_y + 1)

        }



        (__local_x = __local_x + 1)

    }


    if (((if not ((if unsafe { avl_tree_root_node(__local_tree) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (359 as i32), c"avl_tree_root_node(tree) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_to_array() writes allocation_limit, counter {
    var __local_tree: *mut _AVLTree

    var __local_entries: List[i32] = [89, 23, 42, 4, 16, 15, 8, 99, 50, 30]

    var __local_sorted: List[i32] = [4, 8, 15, 16, 23, 30, 42, 50, 89, 99]

    var __local_num_entries: u32 = ((10 as u32))

    var __local_i: u32

    var __local_array: *mut *mut i32

    (__local_tree = avl_tree_new(Some(int_compare)))

    (__local_i = ((0 as u32)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { avl_tree_insert(__local_tree, (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void), null) }


        (__local_i = (__local_i +% 1))

    }


    if (((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_to_array".ptr, c"test-avl-tree.c".ptr, (380 as i32), c"avl_tree_num_entries(tree) == num_entries".ptr)
    } else {
        0
    }

    (__local_array = ((unsafe { avl_tree_to_array(__local_tree) } as *mut *mut i32)))

    (__local_i = ((0 as u32)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        if (((if not ((if (unsafe *((__local_array[__local_i]) as *mut i32)) == __local_sorted[__local_i]: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_avl_tree_to_array".ptr, c"test-avl-tree.c".ptr, (386 as i32), c"*array[i] == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as i32))

    (__local_array = ((unsafe { avl_tree_to_array(__local_tree) } as *mut *mut i32)))

    if (((if not ((if __local_array == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_avl_tree_to_array".ptr, c"test-avl-tree.c".ptr, (395 as i32), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { validate_tree(__local_tree) }

    unsafe { avl_tree_free(__local_tree) }

}

pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_avl_tree_new), Some(test_avl_tree_free), Some(test_avl_tree_child), Some(test_avl_tree_insert_lookup), Some(test_avl_tree_lookup), Some(test_avl_tree_remove), Some(test_avl_tree_to_array), Some(test_out_of_memory), null]
