// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.avl_tree
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.libc

pub unsafe fn find_subtree_height(__param_node: *mut _AVLTreeNode) -> c_int {
    var __local_left_subtree: *mut _AVLTreeNode

    var __local_right_subtree: *mut _AVLTreeNode

    var __local_left_height: c_int

    var __local_right_height: c_int


    if ((if __param_node == null: 1 else: 0) != 0) {
        return 0

    }

    (__local_left_subtree = avl_tree_node_child(__param_node, (0 as i32)))

    (__local_right_subtree = avl_tree_node_child(__param_node, (1 as i32)))

    (__local_left_height = ((find_subtree_height(__local_left_subtree) as c_int)))

    (__local_right_height = ((find_subtree_height(__local_right_subtree) as c_int)))

    if ((if __local_left_height > __local_right_height: 1 else: 0) != 0) {
        return (__local_left_height + 1)

    }
    return (__local_right_height + 1)


}

pub unsafe fn validate_subtree(__param_node: *mut _AVLTreeNode) -> c_int {
    var __local_left_node: *mut _AVLTreeNode

    var __local_right_node: *mut _AVLTreeNode


    var __local_left_height: c_int

    var __local_right_height: c_int


    var __local_key: *mut c_int

    if ((if __param_node == null: 1 else: 0) != 0) {
        return 0

    }

    (__local_left_node = avl_tree_node_child(__param_node, (0 as i32)))

    (__local_right_node = avl_tree_node_child(__param_node, (1 as i32)))

    if ((if __local_left_node != null: 1 else: 0) != 0) {
        if ((((if not ((if avl_tree_node_parent(__local_left_node) == __param_node: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (99 as c_int), c"avl_tree_node_parent(left_node) == node".ptr)
        } else {
            0
        }

    }

    if ((if __local_right_node != null: 1 else: 0) != 0) {
        if ((((if not ((if avl_tree_node_parent(__local_right_node) == __param_node: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (102 as c_int), c"avl_tree_node_parent(right_node) == node".ptr)
        } else {
            0
        }

    }

    (__local_left_height = ((validate_subtree(__local_left_node) as c_int)))

    (__local_key = ((avl_tree_node_key(__param_node) as *mut c_int)))

    if ((((if not ((if (unsafe *__local_key) > counter: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (112 as c_int), c"*key > counter".ptr)
    } else {
        0
    }

    (counter = (unsafe *__local_key))

    (__local_right_height = ((validate_subtree(__local_right_node) as c_int)))

    if ((((if not ((if avl_tree_subtree_height(__local_left_node) == __local_left_height: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (119 as c_int), c"avl_tree_subtree_height(left_node) == left_height".ptr)
    } else {
        0
    }

    if ((((if not ((if avl_tree_subtree_height(__local_right_node) == __local_right_height: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (120 as c_int), c"avl_tree_subtree_height(right_node) == right_height".ptr)
    } else {
        0
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if (__local_left_height - __local_right_height) < 2: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (__local_right_height - __local_left_height) < 2: 1 else: 0) != 0: 1 else: 0))
    }

    if ((((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"validate_subtree".ptr, c"test-avl-tree.c".ptr, (124 as c_int), c"left_height - right_height < 2 && right_height - left_height < 2".ptr)
    } else {
        0
    }


    if ((if __local_left_height > __local_right_height: 1 else: 0) != 0) {
        return (__local_left_height + 1)

    }
    return (__local_right_height + 1)


}

pub unsafe fn validate_tree(__param_tree: *mut _AVLTree) -> Unit {
    var __local_root_node: *mut _AVLTreeNode

    var __local_height: c_int

    (__local_root_node = avl_tree_root_node(__param_tree))

    if ((if __local_root_node != null: 1 else: 0) != 0) {
        (__local_height = ((find_subtree_height(__local_root_node) as c_int)))

        if ((((if not ((if avl_tree_subtree_height(__local_root_node) == __local_height: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"validate_tree".ptr, c"test-avl-tree.c".ptr, (143 as c_int), c"avl_tree_subtree_height(root_node) == height".ptr)
        } else {
            0
        }

    }

    (counter = ((-1 as c_int)))

    validate_subtree(__local_root_node)

}

pub fn create_tree() -> *mut _AVLTree {
    var __local_tree: *mut _AVLTree

    var __local_i: c_int

    (__local_tree = avl_tree_new(int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        unsafe { avl_tree_insert(__local_tree, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    return __local_tree

}

pub fn test_avl_tree_new() -> Unit {
    var __local_tree: *mut _AVLTree

    (__local_tree = avl_tree_new(int_compare))

    if ((((if not ((if __local_tree != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (172 as c_int), c"tree != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { avl_tree_root_node(__local_tree) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (173 as c_int), c"avl_tree_root_node(tree) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (174 as c_int), c"avl_tree_num_entries(tree) == 0".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

    alloc_test_set_limit((0 as c_int))

    (__local_tree = avl_tree_new(int_compare))

    if ((((if not ((if __local_tree == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_new".ptr, c"test-avl-tree.c".ptr, (183 as c_int), c"tree == NULL".ptr)
    } else {
        0
    }

}

pub fn test_avl_tree_insert_lookup() -> Unit {
    var __local_tree: *mut _AVLTree

    var __local_node: *mut _AVLTreeNode

    var __local_i: c_uint

    var __local_value: *mut c_int

    (__local_tree = avl_tree_new(int_compare))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (test_array[__local_i] = ((__local_i as c_int)))

        unsafe { avl_tree_insert(__local_tree, (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }

        if ((((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == ((__local_i as c_uint) +% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (201 as c_int), c"avl_tree_num_entries(tree) == i + 1".ptr)
        } else {
            0
        }

        unsafe { validate_tree(__local_tree) }


        (__local_i = (__local_i +% 1))

    }


    if ((((if not ((if unsafe { avl_tree_root_node(__local_tree) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (205 as c_int), c"avl_tree_root_node(tree) != NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (__local_node = unsafe { avl_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut c_uint) as *mut c_void)) })

        if ((((if not ((if __local_node != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (210 as c_int), c"node != NULL".ptr)
        } else {
            0
        }

        (__local_value = ((unsafe { avl_tree_node_key(__local_node) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_value) == ((__local_i as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (212 as c_int), c"*value == (int) i".ptr)
        } else {
            0
        }

        (__local_value = ((unsafe { avl_tree_node_value(__local_node) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_value) == ((__local_i as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (214 as c_int), c"*value == (int) i".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_i = ((1100 as c_uint)))

    if ((((if not ((if unsafe { avl_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut c_uint) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_insert_lookup".ptr, c"test-avl-tree.c".ptr, (219 as c_int), c"avl_tree_lookup_node(tree, &i) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_child() -> Unit {
    var __local_tree: *mut _AVLTree

    var __local_root: *mut _AVLTreeNode

    var __local_left: *mut _AVLTreeNode

    var __local_right: *mut _AVLTreeNode

    var __local_values: [3]c_int = [(1 as c_int), (2 as c_int), (3 as c_int)]

    var __local_p: *mut c_int

    var __local_i: c_int

    (__local_tree = avl_tree_new(int_compare))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 3: 1 else: 0) != 0) {
        unsafe { avl_tree_insert(__local_tree, (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_root = unsafe { avl_tree_root_node(__local_tree) })

    (__local_p = ((unsafe { avl_tree_node_value(__local_root) } as *mut c_int)))

    if ((((if not ((if (unsafe *__local_p) == 2: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (245 as c_int), c"*p == 2".ptr)
    } else {
        0
    }

    (__local_left = unsafe { avl_tree_node_child(__local_root, (0 as i32)) })

    (__local_p = ((unsafe { avl_tree_node_value(__local_left) } as *mut c_int)))

    if ((((if not ((if (unsafe *__local_p) == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (249 as c_int), c"*p == 1".ptr)
    } else {
        0
    }

    (__local_right = unsafe { avl_tree_node_child(__local_root, (1 as i32)) })

    (__local_p = ((unsafe { avl_tree_node_value(__local_right) } as *mut c_int)))

    if ((((if not ((if (unsafe *__local_p) == 3: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (253 as c_int), c"*p == 3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { avl_tree_node_child(__local_root, (10000 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (256 as c_int), c"avl_tree_node_child(root, 10000) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { avl_tree_node_child(__local_root, (2 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_child".ptr, c"test-avl-tree.c".ptr, (257 as c_int), c"avl_tree_node_child(root, 2) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_out_of_memory() -> Unit {
    var __local_tree: *mut _AVLTree

    var __local_node: *mut _AVLTreeNode

    var __local_i: c_int

    (__local_tree = create_tree())

    alloc_test_set_limit((0 as c_int))

    (__local_i = ((10000 as c_int)))

    while ((if __local_i < 20000: 1 else: 0) != 0) {
        (__local_node = unsafe { avl_tree_insert(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void), ((&raw mut __local_i as *mut c_int) as *mut c_void)) })

        if ((((if not ((if __local_node == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-avl-tree.c".ptr, (277 as c_int), c"node == NULL".ptr)
        } else {
            0
        }

        unsafe { validate_tree(__local_tree) }


        (__local_i = __local_i + 1)

    }


    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_free() -> Unit {
    var __local_tree: *mut _AVLTree

    (__local_tree = avl_tree_new(int_compare))

    unsafe { avl_tree_free(__local_tree) }

    (__local_tree = create_tree())

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_lookup() -> Unit {
    var __local_tree: *mut _AVLTree

    var __local_i: c_int

    var __local_value: *mut c_int

    (__local_tree = create_tree())

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (__local_value = ((unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } as *mut c_int)))

        if ((((if not ((if __local_value != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (309 as c_int), c"value != NULL".ptr)
        } else {
            0
        }

        if ((((if not ((if (unsafe *__local_value) == __local_i: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (310 as c_int), c"*value == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as c_int)))

    if ((((if not ((if unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (315 as c_int), c"avl_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = (((1000 + 1) as c_int)))

    if ((((if not ((if unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (317 as c_int), c"avl_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = ((8724897 as c_int)))

    if ((((if not ((if unsafe { avl_tree_lookup(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_lookup".ptr, c"test-avl-tree.c".ptr, (319 as c_int), c"avl_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_remove() -> Unit {
    var __local_tree: *mut _AVLTree

    var __local_i: c_int

    var __local_x: c_int

    var __local_y: c_int

    var __local_z: c_int


    var __local_value: c_int

    var __local_expected_entries: c_uint

    (__local_tree = create_tree())

    (__local_i = (((1000 + 100) as c_int)))

    if ((((if not ((if unsafe { avl_tree_remove(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (336 as c_int), c"avl_tree_remove(tree, &i) == 0".ptr)
    } else {
        0
    }

    (__local_i = ((-1 as c_int)))

    if ((((if not ((if unsafe { avl_tree_remove(__local_tree, ((&raw mut __local_i as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (338 as c_int), c"avl_tree_remove(tree, &i) == 0".ptr)
    } else {
        0
    }

    (__local_expected_entries = ((1000 as c_uint)))

    (__local_x = ((0 as c_int)))

    while ((if __local_x < 10: 1 else: 0) != 0) {
        (__local_y = ((0 as c_int)))

        while ((if __local_y < 10: 1 else: 0) != 0) {
            (__local_z = ((0 as c_int)))

            while ((if __local_z < 10: 1 else: 0) != 0) {
                (__local_value = (((((__local_z * 100) + ((9 - __local_y) * 10)) + __local_x) as c_int)))

                if ((((if not ((if unsafe { avl_tree_remove(__local_tree, ((&raw mut __local_value as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                    __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (349 as c_int), c"avl_tree_remove(tree, &value) != 0".ptr)
                } else {
                    0
                }

                unsafe { validate_tree(__local_tree) }

                (__local_expected_entries = (__local_expected_entries -% 1))

                if ((((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == __local_expected_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                    __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (353 as c_int), c"avl_tree_num_entries(tree) == expected_entries".ptr)
                } else {
                    0
                }


                (__local_z = __local_z + 1)

            }



            (__local_y = __local_y + 1)

        }



        (__local_x = __local_x + 1)

    }


    if ((((if not ((if unsafe { avl_tree_root_node(__local_tree) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_remove".ptr, c"test-avl-tree.c".ptr, (359 as c_int), c"avl_tree_root_node(tree) == NULL".ptr)
    } else {
        0
    }

    unsafe { avl_tree_free(__local_tree) }

}

pub fn test_avl_tree_to_array() -> Unit {
    var __local_tree: *mut _AVLTree

    var __local_entries: [10]c_int = [(89 as c_int), (23 as c_int), (42 as c_int), (4 as c_int), (16 as c_int), (15 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int)]

    var __local_sorted: [10]c_int = [(4 as c_int), (8 as c_int), (15 as c_int), (16 as c_int), (23 as c_int), (30 as c_int), (42 as c_int), (50 as c_int), (89 as c_int), (99 as c_int)]

    var __local_num_entries: c_uint = ((10 as c_uint))

    var __local_i: c_uint

    var __local_array: *mut *mut c_int

    (__local_tree = avl_tree_new(int_compare))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { avl_tree_insert(__local_tree, (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void), null) }


        (__local_i = (__local_i +% 1))

    }


    if ((((if not ((if unsafe { avl_tree_num_entries(__local_tree) } == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_to_array".ptr, c"test-avl-tree.c".ptr, (380 as c_int), c"avl_tree_num_entries(tree) == num_entries".ptr)
    } else {
        0
    }

    (__local_array = ((unsafe { avl_tree_to_array(__local_tree) } as *mut *mut c_int)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        if ((((if not ((if (unsafe *((unsafe __local_array[__local_i]) as *mut c_int)) == __local_sorted[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_avl_tree_to_array".ptr, c"test-avl-tree.c".ptr, (386 as c_int), c"*array[i] == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as c_int))

    (__local_array = ((unsafe { avl_tree_to_array(__local_tree) } as *mut *mut c_int)))

    if ((((if not ((if __local_array == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_avl_tree_to_array".ptr, c"test-avl-tree.c".ptr, (395 as c_int), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { validate_tree(__local_tree) }

    unsafe { avl_tree_free(__local_tree) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [9]extern "C" fn() -> Unit = [test_avl_tree_new, test_avl_tree_free, test_avl_tree_child, test_avl_tree_insert_lookup, test_avl_tree_lookup, test_avl_tree_remove, test_avl_tree_to_array, test_out_of_memory, null]
