// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing

pub fn rb_tree_new(__param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _RBTree {
    var __local_new_tree: *mut _RBTree

    (__local_new_tree = ((alloc_test_malloc((sizeof[_RBTree]() as c_ulong)) as *mut _RBTree)))

    if ((if __local_new_tree == null: 1 else: 0) != 0) {
        return ((null as *mut _RBTree))

    }

    ((unsafe *__local_new_tree).root_node = ((null as *mut _RBTreeNode)))

    ((unsafe *__local_new_tree).num_nodes = ((0 as c_int)))

    ((unsafe *__local_new_tree).compare_func = __param_compare_func)

    return __local_new_tree

}

pub unsafe fn rb_tree_free(__param_tree: *mut _RBTree) -> Unit {
    rb_tree_free_subtree((unsafe *__param_tree).root_node)

    alloc_test_free((__param_tree as *mut c_void))

}

pub unsafe fn rb_tree_insert(__param_tree: *mut _RBTree, __param_key: *mut c_void, __param_value: *mut c_void) -> *mut _RBTreeNode {
    var __local_node: *mut _RBTreeNode

    var __local_rover: *mut *mut _RBTreeNode

    var __local_parent: *mut _RBTreeNode

    var __local_side: i32

    (__local_node = ((alloc_test_malloc((sizeof[_RBTreeNode]() as c_ulong)) as *mut _RBTreeNode)))

    if ((if __local_node == null: 1 else: 0) != 0) {
        return ((null as *mut _RBTreeNode))

    }

    ((unsafe *__local_node).key = __param_key)

    ((unsafe *__local_node).value = __param_value)

    ((unsafe *__local_node).color = ((0 as i32)))

    ((unsafe *__local_node).children[RB_TREE_NODE_LEFT] = ((null as *mut _RBTreeNode)))

    ((unsafe *__local_node).children[RB_TREE_NODE_RIGHT] = ((null as *mut _RBTreeNode)))

    (__local_parent = ((null as *mut _RBTreeNode)))

    (__local_rover = (((&raw const (unsafe *__param_tree).root_node as *const *mut _RBTreeNode) as *mut *mut _RBTreeNode)))

    while ((if (unsafe *__local_rover) != null: 1 else: 0) != 0) {
        (__local_parent = (unsafe *__local_rover))

        if ((if (unsafe *__param_tree).compare_func(__param_key, (unsafe *(unsafe *__local_rover)).key) < 0: 1 else: 0) != 0) {
            (__local_side = ((0 as i32)))

        } else {
            (__local_side = ((1 as i32)))

        }

        (__local_rover = (((&raw const (unsafe *(unsafe *__local_rover)).children[__local_side] as *const *mut _RBTreeNode) as *mut *mut _RBTreeNode)))

    }

    ((unsafe *__local_rover) = __local_node)

    ((unsafe *__local_node).parent = __local_parent)

    rb_tree_insert_case1(__param_tree, __local_node)

    ((unsafe *__param_tree).num_nodes = (unsafe *__param_tree).num_nodes + 1)

    return __local_node

}

pub unsafe fn rb_tree_remove_node(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    return
}

pub unsafe fn rb_tree_remove(__param_tree: *mut _RBTree, __param_key: *mut c_void) -> c_int {
    var __local_node: *mut _RBTreeNode

    (__local_node = rb_tree_lookup_node(__param_tree, __param_key))

    if ((if __local_node == null: 1 else: 0) != 0) {
        return 0

    }

    rb_tree_remove_node(__param_tree, __local_node)

    return 1

}

pub unsafe fn rb_tree_lookup_node(__param_tree: *mut _RBTree, __param_key: *mut c_void) -> *mut _RBTreeNode {
    var __local_node: *mut _RBTreeNode

    var __local_side: i32

    var __local_diff: c_int

    (__local_node = (unsafe *__param_tree).root_node)

    while ((if __local_node != null: 1 else: 0) != 0) {
        (__local_diff = (((unsafe *__param_tree).compare_func(__param_key, (unsafe *__local_node).key) as c_int)))

        if ((if __local_diff == 0: 1 else: 0) != 0) {
            return __local_node

        }
        if ((if __local_diff < 0: 1 else: 0) != 0) {
            (__local_side = ((0 as i32)))

        } else {
            (__local_side = ((1 as i32)))

        }

        (__local_node = (unsafe *__local_node).children[__local_side])

    }

    return ((null as *mut _RBTreeNode))

}

pub unsafe fn rb_tree_lookup(__param_tree: *mut _RBTree, __param_key: *mut c_void) -> *mut c_void {
    var __local_node: *mut _RBTreeNode

    (__local_node = rb_tree_lookup_node(__param_tree, __param_key))

    if ((if __local_node == null: 1 else: 0) != 0) {
        return rb_tree_null_value

    }
    return (unsafe *__local_node).value


}

pub unsafe fn rb_tree_root_node(__param_tree: *mut _RBTree) -> *mut _RBTreeNode {
    return (unsafe *__param_tree).root_node

}

pub unsafe fn rb_tree_node_key(__param_node: *mut _RBTreeNode) -> *mut c_void {
    return (unsafe *__param_node).key

}

pub unsafe fn rb_tree_node_value(__param_node: *mut _RBTreeNode) -> *mut c_void {
    return (unsafe *__param_node).value

}

pub unsafe fn rb_tree_node_child(__param_node: *mut _RBTreeNode, __param_side: i32) -> *mut _RBTreeNode {
    var __ci_expr_logic_0: c_int

    if ((if __param_side == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_side == 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return (((unsafe *__param_node).children[__param_side] as *mut _RBTreeNode))

    }
    return ((null as *mut _RBTreeNode))



}

pub unsafe fn rb_tree_node_parent(__param_node: *mut _RBTreeNode) -> *mut _RBTreeNode {
    return (unsafe *__param_node).parent

}

extern fn rb_tree_subtree_height(__param_node: *mut _RBTreeNode) -> c_int
pub unsafe fn rb_tree_to_array(__param_tree: *mut _RBTree) -> *mut *mut c_void {
    return ((null as *mut *mut c_void))

}

pub unsafe fn rb_tree_num_entries(__param_tree: *mut _RBTree) -> c_int {
    return (unsafe *__param_tree).num_nodes

}

unsafe fn rb_tree_node_side(__param_node: *mut _RBTreeNode) -> i32 {
    if ((if (unsafe *(unsafe *__param_node).parent).children[RB_TREE_NODE_LEFT] == __param_node: 1 else: 0) != 0) {
        return 0

    }
    return 1


}

unsafe fn rb_tree_node_sibling(__param_node: *mut _RBTreeNode) -> *mut _RBTreeNode {
    var __local_side: i32

    (__local_side = ((rb_tree_node_side(__param_node) as i32)))

    return (((unsafe *(unsafe *__param_node).parent).children[((1 as c_uint) -% (__local_side as c_uint))] as *mut _RBTreeNode))

}

pub unsafe fn rb_tree_node_uncle(__param_node: *mut _RBTreeNode) -> *mut _RBTreeNode {
    return ((rb_tree_node_sibling((unsafe *__param_node).parent) as *mut _RBTreeNode))

}

unsafe fn rb_tree_node_replace(__param_tree: *mut _RBTree, __param_node1: *mut _RBTreeNode, __param_node2: *mut _RBTreeNode) -> Unit {
    var __local_side: c_int

    if ((if __param_node2 != null: 1 else: 0) != 0) {
        ((unsafe *__param_node2).parent = (unsafe *__param_node1).parent)

    }

    if ((if (unsafe *__param_node1).parent == null: 1 else: 0) != 0) {
        ((unsafe *__param_tree).root_node = __param_node2)

    } else {
        (__local_side = ((rb_tree_node_side(__param_node1) as c_int)))

        ((unsafe *(unsafe *__param_node1).parent).children[__local_side] = __param_node2)

    }

}

unsafe fn rb_tree_rotate(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode, __param_direction: i32) -> *mut _RBTreeNode {
    var __local_new_root: *mut _RBTreeNode

    (__local_new_root = (unsafe *__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))])

    rb_tree_node_replace(__param_tree, __param_node, __local_new_root)

    ((unsafe *__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))] = (unsafe *__local_new_root).children[__param_direction])

    ((unsafe *__local_new_root).children[__param_direction] = __param_node)

    ((unsafe *__param_node).parent = __local_new_root)

    if ((if (unsafe *__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))] != null: 1 else: 0) != 0) {
        ((unsafe *__param_node).children[((1 as c_uint) -% (__param_direction as c_uint))].parent = __param_node)

    }

    return __local_new_root

}

unsafe fn rb_tree_free_subtree(__param_node: *mut _RBTreeNode) -> Unit {
    if ((if __param_node != null: 1 else: 0) != 0) {
        rb_tree_free_subtree((unsafe *__param_node).children[RB_TREE_NODE_LEFT])

        rb_tree_free_subtree((unsafe *__param_node).children[RB_TREE_NODE_RIGHT])

        alloc_test_free((__param_node as *mut c_void))

    }

}

unsafe fn rb_tree_insert_case1(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    if ((if (unsafe *__param_node).parent == null: 1 else: 0) != 0) {
        ((unsafe *__param_node).color = ((1 as i32)))

    } else {
        rb_tree_insert_case2(__param_tree, __param_node)

    }

}

unsafe fn rb_tree_insert_case2(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    if ((if (unsafe *(unsafe *__param_node).parent).color != 1: 1 else: 0) != 0) {
        rb_tree_insert_case3(__param_tree, __param_node)

    }

}

unsafe fn rb_tree_insert_case3(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    var __local_grandparent: *mut _RBTreeNode

    var __local_uncle: *mut _RBTreeNode

    (__local_grandparent = (unsafe *(unsafe *__param_node).parent).parent)

    (__local_uncle = rb_tree_node_uncle(__param_node))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_uncle != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *__local_uncle).color == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((unsafe *(unsafe *__param_node).parent).color = ((1 as i32)))

        ((unsafe *__local_uncle).color = ((1 as i32)))

        ((unsafe *__local_grandparent).color = ((0 as i32)))

        rb_tree_insert_case1(__param_tree, __local_grandparent)

    } else {
        rb_tree_insert_case4(__param_tree, __param_node)

    }


}

unsafe fn rb_tree_insert_case4(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    var __local_next_node: *mut _RBTreeNode

    var __local_side: i32

    (__local_side = ((rb_tree_node_side(__param_node) as i32)))

    if ((if __local_side != rb_tree_node_side((unsafe *__param_node).parent): 1 else: 0) != 0) {
        (__local_next_node = (unsafe *__param_node).parent)

        rb_tree_rotate(__param_tree, (unsafe *__param_node).parent, (((1 as c_uint) -% (__local_side as c_uint)) as i32))

    } else {
        (__local_next_node = __param_node)

    }

    rb_tree_insert_case5(__param_tree, __local_next_node)

}

unsafe fn rb_tree_insert_case5(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    var __local_parent: *mut _RBTreeNode

    var __local_grandparent: *mut _RBTreeNode

    var __local_side: i32

    (__local_parent = (unsafe *__param_node).parent)

    (__local_grandparent = (unsafe *__local_parent).parent)

    (__local_side = ((rb_tree_node_side(__param_node) as i32)))

    rb_tree_rotate(__param_tree, __local_grandparent, (((1 as c_uint) -% (__local_side as c_uint)) as i32))

    ((unsafe *__local_parent).color = ((1 as i32)))

    ((unsafe *__local_grandparent).color = ((0 as i32)))

}

let rb_tree_null_value: *mut c_void = null
