// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.compare_int
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.rb_tree
use std.libc
use std.option
use std.collections

extern fn rb_tree_subtree_height(__param_node: *mut _RBTreeNode) -> i32
// contract: unproved:0:NULL is an accepted argument
pub unsafe fn find_subtree_height(__param_node: *mut _RBTreeNode) -> i32 {
    var __local_left_subtree: *mut _RBTreeNode

    var __local_right_subtree: *mut _RBTreeNode

    var __local_left_height: i32

    var __local_right_height: i32


    if (__param_node == null) {
        return 0

    }

    (__local_left_subtree = rb_tree_node_child(__param_node, (0 as i32)))

    (__local_right_subtree = rb_tree_node_child(__param_node, (1 as i32)))

    (__local_left_height = ((find_subtree_height(__local_left_subtree) as i32)))

    (__local_right_height = ((find_subtree_height(__local_right_subtree) as i32)))

    if (__local_left_height > __local_right_height) {
        return (__local_left_height + 1)

    }
    return (__local_right_height + 1)


}

pub fn create_tree() -> *mut _RBTree writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_i: i32

    (__local_tree = rb_tree_new(Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 1000) {
        (test_array[__local_i] = __local_i)

        unsafe { rb_tree_insert(__local_tree, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    return __local_tree

}

pub fn test_rb_tree_new() -> Unit writes allocation_limit {
    var __local_tree: *mut _RBTree

    (__local_tree = rb_tree_new(Some(int_compare)))

    if ((if not (__local_tree != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_new".ptr, c"test-rb-tree.c".ptr, (107 as i32), c"tree != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { rb_tree_root_node(__local_tree) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_new".ptr, c"test-rb-tree.c".ptr, (108 as i32), c"rb_tree_root_node(tree) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { (*__local_tree).rb_tree_num_entries() } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_new".ptr, c"test-rb-tree.c".ptr, (109 as i32), c"rb_tree_num_entries(tree) == 0".ptr)
    } else {
        0
    }

    unsafe { rb_tree_free(__local_tree) }

    alloc_test_set_limit((0 as i32))

    (__local_tree = rb_tree_new(Some(int_compare)))

    if ((if not (__local_tree == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_new".ptr, c"test-rb-tree.c".ptr, (118 as i32), c"tree == NULL".ptr)
    } else {
        0
    }

}

pub fn test_rb_tree_insert_lookup() writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_node: *mut _RBTreeNode

    var __local_i: i32

    var __local_value: *mut i32

    (__local_tree = rb_tree_new(Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 1000) {
        (test_array[__local_i] = __local_i)

        unsafe { rb_tree_insert(__local_tree, (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) }

        if ((if not (unsafe { (*__local_tree).rb_tree_num_entries() } == (__local_i + 1)): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (136 as i32), c"rb_tree_num_entries(tree) == i + 1".ptr)
        } else {
            0
        }

        unsafe { (*__local_tree).validate_tree() }


        (__local_i = __local_i + 1)

    }


    if ((if not (unsafe { rb_tree_root_node(__local_tree) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (140 as i32), c"rb_tree_root_node(tree) != NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < 1000) {
        (__local_node = unsafe { rb_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) })

        if ((if not (__local_node != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (145 as i32), c"node != NULL".ptr)
        } else {
            0
        }

        (__local_value = ((unsafe { rb_tree_node_key(__local_node) } as *mut i32)))

        if ((if not ((unsafe *__local_value) == __local_i): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (147 as i32), c"*value == i".ptr)
        } else {
            0
        }

        (__local_value = ((unsafe { rb_tree_node_value(__local_node) } as *mut i32)))

        if ((if not ((unsafe *__local_value) == __local_i): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (149 as i32), c"*value == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as i32)))

    if ((if not (unsafe { rb_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (154 as i32), c"rb_tree_lookup_node(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = (((1000 + 100) as i32)))

    if ((if not (unsafe { rb_tree_lookup_node(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_insert_lookup".ptr, c"test-rb-tree.c".ptr, (156 as i32), c"rb_tree_lookup_node(tree, &i) == NULL".ptr)
    } else {
        0
    }

    unsafe { rb_tree_free(__local_tree) }

}

pub fn test_rb_tree_child() writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_root: *mut _RBTreeNode

    var __local_left: *mut _RBTreeNode

    var __local_right: *mut _RBTreeNode

    var __local_values: List[i32] = [1, 2, 3]

    var __local_p: *mut i32

    var __local_i: i32

    (__local_tree = rb_tree_new(Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < 3) {
        unsafe { rb_tree_insert(__local_tree, (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_root = unsafe { rb_tree_root_node(__local_tree) })

    (__local_p = ((unsafe { rb_tree_node_value(__local_root) } as *mut i32)))

    if ((if not ((unsafe *__local_p) == 2): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_child".ptr, c"test-rb-tree.c".ptr, (182 as i32), c"*p == 2".ptr)
    } else {
        0
    }

    (__local_left = unsafe { rb_tree_node_child(__local_root, (0 as i32)) })

    (__local_p = ((unsafe { rb_tree_node_value(__local_left) } as *mut i32)))

    if ((if not ((unsafe *__local_p) == 1): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_child".ptr, c"test-rb-tree.c".ptr, (186 as i32), c"*p == 1".ptr)
    } else {
        0
    }

    (__local_right = unsafe { rb_tree_node_child(__local_root, (1 as i32)) })

    (__local_p = ((unsafe { rb_tree_node_value(__local_right) } as *mut i32)))

    if ((if not ((unsafe *__local_p) == 3): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_child".ptr, c"test-rb-tree.c".ptr, (190 as i32), c"*p == 3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { rb_tree_node_child(__local_root, (10000 as i32)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_child".ptr, c"test-rb-tree.c".ptr, (193 as i32), c"rb_tree_node_child(root, 10000) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { rb_tree_node_child(__local_root, (2 as i32)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_child".ptr, c"test-rb-tree.c".ptr, (194 as i32), c"rb_tree_node_child(root, 2) == NULL".ptr)
    } else {
        0
    }

    unsafe { rb_tree_free(__local_tree) }

}

pub fn test_out_of_memory() writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_node: *mut _RBTreeNode

    var __local_i: i32

    (__local_tree = create_tree())

    alloc_test_set_limit((0 as i32))

    (__local_i = ((10000 as i32)))

    while (__local_i < 20000) {
        (__local_node = unsafe { rb_tree_insert(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void), ((&raw mut __local_i as *mut i32) as *mut c_void)) })

        if ((if not (__local_node == null): 1 else: 0) as i64) {
            __assert_rtn(c"test_out_of_memory".ptr, c"test-rb-tree.c".ptr, (214 as i32), c"node == NULL".ptr)
        } else {
            0
        }

        unsafe { (*__local_tree).validate_tree() }


        (__local_i = __local_i + 1)

    }


    unsafe { rb_tree_free(__local_tree) }

}

pub fn test_rb_tree_free() writes allocation_limit {
    var __local_tree: *mut _RBTree

    (__local_tree = rb_tree_new(Some(int_compare)))

    unsafe { rb_tree_free(__local_tree) }

    (__local_tree = create_tree())

    unsafe { rb_tree_free(__local_tree) }

}

pub fn test_rb_tree_lookup() writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_i: i32

    var __local_value: *mut i32

    (__local_tree = create_tree())

    (__local_i = ((0 as i32)))

    while (__local_i < 1000) {
        (__local_value = ((unsafe { rb_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } as *mut i32)))

        if ((if not (__local_value != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_lookup".ptr, c"test-rb-tree.c".ptr, (246 as i32), c"value != NULL".ptr)
        } else {
            0
        }

        if ((if not ((unsafe *__local_value) == __local_i): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_lookup".ptr, c"test-rb-tree.c".ptr, (247 as i32), c"*value == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1 as i32)))

    if ((if not (unsafe { rb_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_lookup".ptr, c"test-rb-tree.c".ptr, (252 as i32), c"rb_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = (((1000 + 1) as i32)))

    if ((if not (unsafe { rb_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_lookup".ptr, c"test-rb-tree.c".ptr, (254 as i32), c"rb_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    (__local_i = ((8724897 as i32)))

    if ((if not (unsafe { rb_tree_lookup(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_lookup".ptr, c"test-rb-tree.c".ptr, (256 as i32), c"rb_tree_lookup(tree, &i) == NULL".ptr)
    } else {
        0
    }

    unsafe { rb_tree_free(__local_tree) }

}

pub fn test_rb_tree_remove() writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_i: i32

    var __local_x: i32

    var __local_y: i32

    var __local_z: i32


    var __local_value: i32

    var __local_expected_entries: i32

    (__local_tree = create_tree())

    (__local_i = (((1000 + 100) as i32)))

    if ((if not (unsafe { rb_tree_remove(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_remove".ptr, c"test-rb-tree.c".ptr, (273 as i32), c"rb_tree_remove(tree, &i) == 0".ptr)
    } else {
        0
    }

    (__local_i = ((-1 as i32)))

    if ((if not (unsafe { rb_tree_remove(__local_tree, ((&raw mut __local_i as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_remove".ptr, c"test-rb-tree.c".ptr, (275 as i32), c"rb_tree_remove(tree, &i) == 0".ptr)
    } else {
        0
    }

    (__local_expected_entries = ((1000 as i32)))

    (__local_x = ((0 as i32)))

    while (__local_x < 10) {
        (__local_y = ((0 as i32)))

        while (__local_y < 10) {
            (__local_z = ((0 as i32)))

            while (__local_z < 10) {
                (__local_value = (((((__local_z * 100) + ((9 - __local_y) * 10)) + __local_x) as i32)))

                if ((if not (unsafe { rb_tree_remove(__local_tree, ((&raw mut __local_value as *mut i32) as *mut c_void)) } != 0): 1 else: 0) as i64) {
                    __assert_rtn(c"test_rb_tree_remove".ptr, c"test-rb-tree.c".ptr, (286 as i32), c"rb_tree_remove(tree, &value) != 0".ptr)
                } else {
                    0
                }

                unsafe { (*__local_tree).validate_tree() }

                (__local_expected_entries = __local_expected_entries - 1)

                if ((if not (unsafe { (*__local_tree).rb_tree_num_entries() } == __local_expected_entries): 1 else: 0) as i64) {
                    __assert_rtn(c"test_rb_tree_remove".ptr, c"test-rb-tree.c".ptr, (290 as i32), c"rb_tree_num_entries(tree) == expected_entries".ptr)
                } else {
                    0
                }


                (__local_z = __local_z + 1)

            }



            (__local_y = __local_y + 1)

        }



        (__local_x = __local_x + 1)

    }


    if ((if not (unsafe { rb_tree_root_node(__local_tree) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_remove".ptr, c"test-rb-tree.c".ptr, (296 as i32), c"rb_tree_root_node(tree) == NULL".ptr)
    } else {
        0
    }

    unsafe { rb_tree_free(__local_tree) }

}

pub fn test_rb_tree_to_array() writes allocation_limit {
    var __local_tree: *mut _RBTree

    var __local_entries: List[i32] = [89, 23, 42, 4, 16, 15, 8, 99, 50, 30]

    var __local_sorted: List[i32] = [4, 8, 15, 16, 23, 30, 42, 50, 89, 99]

    var __local_num_entries: i32 = (((__local_entries.len() as u64) as i32))

    var __local_i: i32

    var __local_array: *mut *mut i32

    (__local_tree = rb_tree_new(Some(int_compare)))

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num_entries) {
        unsafe { rb_tree_insert(__local_tree, (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void), null) }


        (__local_i = __local_i + 1)

    }


    if ((if not (unsafe { (*__local_tree).rb_tree_num_entries() } == __local_num_entries): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_to_array".ptr, c"test-rb-tree.c".ptr, (317 as i32), c"rb_tree_num_entries(tree) == num_entries".ptr)
    } else {
        0
    }

    (__local_array = ((unsafe { rb_tree_to_array(__local_tree) } as *mut *mut i32)))

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num_entries) {
        if ((if not ((unsafe *((__local_array[__local_i]) as *mut i32)) == __local_sorted[__local_i]): 1 else: 0) as i64) {
            __assert_rtn(c"test_rb_tree_to_array".ptr, c"test-rb-tree.c".ptr, (323 as i32), c"*array[i] == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as i32))

    (__local_array = ((unsafe { rb_tree_to_array(__local_tree) } as *mut *mut i32)))

    if ((if not (__local_array == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_rb_tree_to_array".ptr, c"test-rb-tree.c".ptr, (332 as i32), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { (*__local_tree).validate_tree() }

    unsafe { rb_tree_free(__local_tree) }

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

impl _RBTree {
    pub fn validate_tree() {
        let __param_tree: *mut _RBTree = (self as *const _RBTree) as *mut _RBTree
        return
    }

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_rb_tree_new), Some(test_rb_tree_free), Some(test_rb_tree_child), Some(test_rb_tree_insert_lookup), Some(test_rb_tree_lookup), Some(test_out_of_memory), null]
