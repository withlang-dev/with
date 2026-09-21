// Migrated from C
use std.c_algorithms.defs

pub fn avl_tree_new(__param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _AVLTree {
    var __local_new_tree: *mut _AVLTree

    (__local_new_tree = (((unsafe { with_alloc(((sizeof[_AVLTree]() as c_ulong) as i64)) } as *mut c_void) as *mut _AVLTree)))

    if ((if __local_new_tree == null: 1 else: 0) != 0) {
        return ((null as *mut _AVLTree))

    }

    ((unsafe *__local_new_tree).root_node = ((null as *mut _AVLTreeNode)))

    ((unsafe *__local_new_tree).compare_func = __param_compare_func)

    ((unsafe *__local_new_tree).num_nodes = ((0 as c_uint)))

    return __local_new_tree

}

pub unsafe fn avl_tree_free(__param_tree: *mut _AVLTree) -> Unit {
    avl_tree_free_subtree(__param_tree, (*__param_tree).root_node)

    with_free(((__param_tree as *mut c_void) as *mut u8))

}

pub unsafe fn avl_tree_insert(__param_tree: *mut _AVLTree, __param_key: *mut c_void, __param_value: *mut c_void) -> *mut _AVLTreeNode {
    var __local_rover: *mut *mut _AVLTreeNode

    var __local_new_node: *mut _AVLTreeNode

    var __local_previous_node: *mut _AVLTreeNode

    (__local_rover = (((&raw const (*__param_tree).root_node as *const *mut _AVLTreeNode) as *mut *mut _AVLTreeNode)))

    (__local_previous_node = ((null as *mut _AVLTreeNode)))

    while ((if (*__local_rover) != null: 1 else: 0) != 0) {
        (__local_previous_node = (*__local_rover))

        if ((if (*__param_tree).compare_func(__param_key, (*(*__local_rover)).key) < 0: 1 else: 0) != 0) {
            (__local_rover = (((&raw const (*(*__local_rover)).children[AVL_TREE_NODE_LEFT] as *const *mut _AVLTreeNode) as *mut *mut _AVLTreeNode)))

        } else {
            (__local_rover = (((&raw const (*(*__local_rover)).children[AVL_TREE_NODE_RIGHT] as *const *mut _AVLTreeNode) as *mut *mut _AVLTreeNode)))

        }

    }

    (__local_new_node = (((with_alloc(((sizeof[_AVLTreeNode]() as c_ulong) as i64)) as *mut c_void) as *mut _AVLTreeNode)))

    if ((if __local_new_node == null: 1 else: 0) != 0) {
        return ((null as *mut _AVLTreeNode))

    }

    ((*__local_new_node).children[AVL_TREE_NODE_LEFT] = ((null as *mut _AVLTreeNode)))

    ((*__local_new_node).children[AVL_TREE_NODE_RIGHT] = ((null as *mut _AVLTreeNode)))

    ((*__local_new_node).parent = __local_previous_node)

    ((*__local_new_node).key = __param_key)

    ((*__local_new_node).value = __param_value)

    ((*__local_new_node).height = ((1 as c_int)))

    ((*__local_rover) = __local_new_node)

    avl_tree_balance_to_root(__param_tree, __local_previous_node)

    ((*__param_tree).num_nodes = ((*__param_tree).num_nodes +% 1))

    return __local_new_node

}

pub unsafe fn avl_tree_remove_node(__param_tree: *mut _AVLTree, __param_node: *mut _AVLTreeNode) -> Unit {
    var __local_swap_node: *mut _AVLTreeNode

    var __local_balance_startpoint: *mut _AVLTreeNode

    var __local_i: c_int

    (__local_swap_node = avl_tree_node_get_replacement(__param_tree, __param_node))

    if ((if __local_swap_node == null: 1 else: 0) != 0) {
        avl_tree_node_replace(__param_tree, __param_node, (null as *mut _AVLTreeNode))

        (__local_balance_startpoint = (*__param_node).parent)

    } else {
        if ((if (*__local_swap_node).parent == __param_node: 1 else: 0) != 0) {
            (__local_balance_startpoint = __local_swap_node)

        } else {
            (__local_balance_startpoint = (*__local_swap_node).parent)

        }

        (__local_i = ((0 as c_int)))

        while ((if __local_i < 2: 1 else: 0) != 0) {
            ((*__local_swap_node).children[__local_i] = (*__param_node).children[__local_i])

            if ((if (*__local_swap_node).children[__local_i] != null: 1 else: 0) != 0) {
                ((*__local_swap_node).children[__local_i].parent = __local_swap_node)

            }


            (__local_i = __local_i + 1)

        }


        ((*__local_swap_node).height = (*__param_node).height)

        avl_tree_node_replace(__param_tree, __param_node, __local_swap_node)

    }

    with_free(((__param_node as *mut c_void) as *mut u8))

    ((*__param_tree).num_nodes = ((*__param_tree).num_nodes -% 1))

    avl_tree_balance_to_root(__param_tree, __local_balance_startpoint)

}

pub unsafe fn avl_tree_remove(__param_tree: *mut _AVLTree, __param_key: *mut c_void) -> c_int {
    var __local_node: *mut _AVLTreeNode

    (__local_node = avl_tree_lookup_node(__param_tree, __param_key))

    if ((if __local_node == null: 1 else: 0) != 0) {
        return 0

    }

    avl_tree_remove_node(__param_tree, __local_node)

    return 1

}

pub unsafe fn avl_tree_lookup_node(__param_tree: *mut _AVLTree, __param_key: *mut c_void) -> *mut _AVLTreeNode {
    var __local_node: *mut _AVLTreeNode

    var __local_diff: c_int

    (__local_node = (*__param_tree).root_node)

    while ((if __local_node != null: 1 else: 0) != 0) {
        (__local_diff = (((*__param_tree).compare_func(__param_key, (*__local_node).key) as c_int)))

        if ((if __local_diff == 0: 1 else: 0) != 0) {
            return __local_node

        }
        if ((if __local_diff < 0: 1 else: 0) != 0) {
            (__local_node = (*__local_node).children[AVL_TREE_NODE_LEFT])

        } else {
            (__local_node = (*__local_node).children[AVL_TREE_NODE_RIGHT])

        }

    }

    return ((null as *mut _AVLTreeNode))

}

pub unsafe fn avl_tree_lookup(__param_tree: *mut _AVLTree, __param_key: *mut c_void) -> *mut c_void {
    var __local_node: *mut _AVLTreeNode

    (__local_node = avl_tree_lookup_node(__param_tree, __param_key))

    if ((if __local_node == null: 1 else: 0) != 0) {
        return avl_tree_null_value

    }
    return (*__local_node).value


}

pub unsafe fn avl_tree_root_node(__param_tree: *mut _AVLTree) -> *mut _AVLTreeNode {
    return (*__param_tree).root_node

}

pub unsafe fn avl_tree_node_key(__param_node: *mut _AVLTreeNode) -> *mut c_void {
    return (*__param_node).key

}

pub unsafe fn avl_tree_node_value(__param_node: *mut _AVLTreeNode) -> *mut c_void {
    return (*__param_node).value

}

pub unsafe fn avl_tree_node_child(__param_node: *mut _AVLTreeNode, __param_side: i32) -> *mut _AVLTreeNode {
    var __ci_expr_logic_0: c_int

    if ((if __param_side == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_side == 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return (((*__param_node).children[__param_side] as *mut _AVLTreeNode))

    }
    return ((null as *mut _AVLTreeNode))



}

pub unsafe fn avl_tree_node_parent(__param_node: *mut _AVLTreeNode) -> *mut _AVLTreeNode {
    return (*__param_node).parent

}

pub unsafe fn avl_tree_subtree_height(__param_node: *mut _AVLTreeNode) -> c_int {
    if ((if __param_node == null: 1 else: 0) != 0) {
        return 0

    }
    return (*__param_node).height


}

pub unsafe fn avl_tree_to_array(__param_tree: *mut _AVLTree) -> *mut *mut c_void {
    var __local_array: *mut *mut c_void

    var __local_index: c_int

    (__local_array = (((with_alloc(((((sizeof[usize]() as c_ulong) *% ((*__param_tree).num_nodes as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

    if ((if __local_array == null: 1 else: 0) != 0) {
        return ((null as *mut *mut c_void))

    }

    (__local_index = ((0 as c_int)))

    avl_tree_to_array_add_subtree((*__param_tree).root_node, __local_array, (&raw mut __local_index as *mut c_int))

    return __local_array

}

pub unsafe fn avl_tree_num_entries(__param_tree: *mut _AVLTree) -> c_uint {
    return (*__param_tree).num_nodes

}

unsafe fn avl_tree_free_subtree(__param_tree: *mut _AVLTree, __param_node: *mut _AVLTreeNode) -> Unit {
    if ((if __param_node == null: 1 else: 0) != 0) {
        return

    }

    avl_tree_free_subtree(__param_tree, (*__param_node).children[AVL_TREE_NODE_LEFT])

    avl_tree_free_subtree(__param_tree, (*__param_node).children[AVL_TREE_NODE_RIGHT])

    with_free(((__param_node as *mut c_void) as *mut u8))

}

unsafe fn avl_tree_update_height(__param_node: *mut _AVLTreeNode) -> Unit {
    var __local_left_subtree: *mut _AVLTreeNode

    var __local_right_subtree: *mut _AVLTreeNode

    var __local_left_height: c_int

    var __local_right_height: c_int


    (__local_left_subtree = (*__param_node).children[AVL_TREE_NODE_LEFT])

    (__local_right_subtree = (*__param_node).children[AVL_TREE_NODE_RIGHT])

    (__local_left_height = ((avl_tree_subtree_height(__local_left_subtree) as c_int)))

    (__local_right_height = ((avl_tree_subtree_height(__local_right_subtree) as c_int)))

    if ((if __local_left_height > __local_right_height: 1 else: 0) != 0) {
        ((*__param_node).height = (((__local_left_height + 1) as c_int)))

    } else {
        ((*__param_node).height = (((__local_right_height + 1) as c_int)))

    }

}

unsafe fn avl_tree_node_parent_side(__param_node: *mut _AVLTreeNode) -> i32 {
    if ((if (*(*__param_node).parent).children[AVL_TREE_NODE_LEFT] == __param_node: 1 else: 0) != 0) {
        return 0

    }
    return 1


}

unsafe fn avl_tree_node_replace(__param_tree: *mut _AVLTree, __param_node1: *mut _AVLTreeNode, __param_node2: *mut _AVLTreeNode) -> Unit {
    var __local_side: c_int

    if ((if __param_node2 != null: 1 else: 0) != 0) {
        ((*__param_node2).parent = (*__param_node1).parent)

    }

    if ((if (*__param_node1).parent == null: 1 else: 0) != 0) {
        ((*__param_tree).root_node = __param_node2)

    } else {
        (__local_side = ((avl_tree_node_parent_side(__param_node1) as c_int)))

        ((*(*__param_node1).parent).children[__local_side] = __param_node2)

        avl_tree_update_height((*__param_node1).parent)

    }

}

unsafe fn avl_tree_rotate(__param_tree: *mut _AVLTree, __param_node: *mut _AVLTreeNode, __param_direction: i32) -> *mut _AVLTreeNode {
    var __local_new_root: *mut _AVLTreeNode

    (__local_new_root = (*__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))])

    avl_tree_node_replace(__param_tree, __param_node, __local_new_root)

    ((*__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))] = (*__local_new_root).children[__param_direction])

    ((*__local_new_root).children[__param_direction] = __param_node)

    ((*__param_node).parent = __local_new_root)

    if ((if (*__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))] != null: 1 else: 0) != 0) {
        ((*__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))].parent = __param_node)

    }

    avl_tree_update_height(__local_new_root)

    avl_tree_update_height(__param_node)

    return __local_new_root

}

unsafe fn avl_tree_node_balance(__param_tree: *mut _AVLTree, __param_node: *mut _AVLTreeNode) -> *mut _AVLTreeNode {
    var __local_node = __param_node
    var __local_left_subtree: *mut _AVLTreeNode

    var __local_right_subtree: *mut _AVLTreeNode

    var __local_child: *mut _AVLTreeNode

    var __local_diff: c_int

    (__local_left_subtree = (*__local_node).children[AVL_TREE_NODE_LEFT])

    (__local_right_subtree = (*__local_node).children[AVL_TREE_NODE_RIGHT])

    (__local_diff = (((avl_tree_subtree_height(__local_right_subtree) - avl_tree_subtree_height(__local_left_subtree)) as c_int)))

    if ((if __local_diff >= 2: 1 else: 0) != 0) {
        (__local_child = __local_right_subtree)

        if ((if avl_tree_subtree_height((*__local_child).children[AVL_TREE_NODE_RIGHT]) < avl_tree_subtree_height((*__local_child).children[AVL_TREE_NODE_LEFT]): 1 else: 0) != 0) {
            avl_tree_rotate(__param_tree, __local_right_subtree, (1 as i32))

        }

        (__local_node = avl_tree_rotate(__param_tree, __local_node, (0 as i32)))

    } else {
        if ((if __local_diff <= -2: 1 else: 0) != 0) {
            (__local_child = (*__local_node).children[AVL_TREE_NODE_LEFT])

            if ((if avl_tree_subtree_height((*__local_child).children[AVL_TREE_NODE_LEFT]) < avl_tree_subtree_height((*__local_child).children[AVL_TREE_NODE_RIGHT]): 1 else: 0) != 0) {
                avl_tree_rotate(__param_tree, __local_left_subtree, (0 as i32))

            }

            (__local_node = avl_tree_rotate(__param_tree, __local_node, (1 as i32)))

        }
    }

    avl_tree_update_height(__local_node)

    return __local_node

}

unsafe fn avl_tree_balance_to_root(__param_tree: *mut _AVLTree, __param_node: *mut _AVLTreeNode) -> Unit {
    var __local_rover: *mut _AVLTreeNode

    (__local_rover = __param_node)

    while ((if __local_rover != null: 1 else: 0) != 0) {
        (__local_rover = avl_tree_node_balance(__param_tree, __local_rover))

        (__local_rover = (*__local_rover).parent)

    }

}

unsafe fn avl_tree_node_get_replacement(__param_tree: *mut _AVLTree, __param_node: *mut _AVLTreeNode) -> *mut _AVLTreeNode {
    var __local_left_subtree: *mut _AVLTreeNode

    var __local_right_subtree: *mut _AVLTreeNode

    var __local_result: *mut _AVLTreeNode

    var __local_child: *mut _AVLTreeNode

    var __local_left_height: c_int

    var __local_right_height: c_int


    var __local_side: c_int

    (__local_left_subtree = (*__param_node).children[AVL_TREE_NODE_LEFT])

    (__local_right_subtree = (*__param_node).children[AVL_TREE_NODE_RIGHT])

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_left_subtree == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_right_subtree == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((null as *mut _AVLTreeNode))

    }


    (__local_left_height = ((avl_tree_subtree_height(__local_left_subtree) as c_int)))

    (__local_right_height = ((avl_tree_subtree_height(__local_right_subtree) as c_int)))

    if ((if __local_left_height < __local_right_height: 1 else: 0) != 0) {
        (__local_side = AVL_TREE_NODE_RIGHT)

    } else {
        (__local_side = AVL_TREE_NODE_LEFT)

    }

    (__local_result = (*__param_node).children[__local_side])

    while ((if (*__local_result).children[(1 - __local_side)] != null: 1 else: 0) != 0) {
        (__local_result = (*__local_result).children[(1 - __local_side)])

    }

    (__local_child = (*__local_result).children[__local_side])

    avl_tree_node_replace(__param_tree, __local_result, __local_child)

    avl_tree_update_height((*__local_result).parent)

    return __local_result

}

unsafe fn avl_tree_to_array_add_subtree(__param_subtree: *mut _AVLTreeNode, __param_array: *mut *mut c_void, __param_index: *mut c_int) -> Unit {
    if ((if __param_subtree == null: 1 else: 0) != 0) {
        return

    }

    avl_tree_to_array_add_subtree((*__param_subtree).children[AVL_TREE_NODE_LEFT], __param_array, __param_index)

    ((__param_array[(*__param_index)]) = (*__param_subtree).key)

    ((*__param_index) = (*__param_index) + 1)

    avl_tree_to_array_add_subtree((*__param_subtree).children[AVL_TREE_NODE_RIGHT], __param_array, __param_index)

}

let avl_tree_null_value: *mut c_void = null
