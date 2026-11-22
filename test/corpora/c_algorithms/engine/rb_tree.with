// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.option

pub fn rb_tree_new(__param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _RBTree writes allocation_limit {
    var __local_new_tree: *mut _RBTree

    (__local_new_tree = ((alloc_test_malloc((sizeof[_RBTree]() as u64)) as *mut _RBTree)))

    if (__local_new_tree == null) {
        return ((null as *mut _RBTree))

    }

    ((unsafe *__local_new_tree).root_node = ((null as *mut _RBTreeNode)))

    ((unsafe *__local_new_tree).num_nodes = ((0 as i32)))

    ((unsafe *__local_new_tree).compare_func = __param_compare_func)

    return __local_new_tree

}

// contract: unproved:0:NULL is an accepted argument
pub unsafe fn rb_tree_free(__param_tree: *mut _RBTree) {
    rb_tree_free_subtree((*__param_tree).root_node)

    alloc_test_free((__param_tree as *mut c_void))

}

// contract: receiver-mut:_RBTree,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn rb_tree_insert(__param_tree: *mut _RBTree, __param_key: *mut c_void, __param_value: *mut c_void) -> *mut _RBTreeNode writes allocation_limit {
    var __local_node: *mut _RBTreeNode

    var __local_rover: *mut *mut _RBTreeNode

    var __local_parent: *mut _RBTreeNode

    var __local_side: i32

    (__local_node = ((alloc_test_malloc((sizeof[_RBTreeNode]() as u64)) as *mut _RBTreeNode)))

    if (__local_node == null) {
        return ((null as *mut _RBTreeNode))

    }

    ((*__local_node).key = __param_key)

    ((*__local_node).value = __param_value)

    ((*__local_node).color = ((0 as i32)))

    ((*__local_node).children[RB_TREE_NODE_LEFT] = ((null as *mut _RBTreeNode)))

    ((*__local_node).children[RB_TREE_NODE_RIGHT] = ((null as *mut _RBTreeNode)))

    (__local_parent = ((null as *mut _RBTreeNode)))

    (__local_rover = (((&raw const (*__param_tree).root_node as *const *mut _RBTreeNode) as *mut *mut _RBTreeNode)))

    while ((*__local_rover) != null) {
        (__local_parent = (*__local_rover))

        if ((*__param_tree).compare_func.unwrap()(__param_key, (*(*__local_rover)).key) < 0) {
            (__local_side = ((0 as i32)))

        } else {
            (__local_side = ((1 as i32)))

        }

        (__local_rover = (((&raw const (*(*__local_rover)).children[__local_side] as *const *mut _RBTreeNode) as *mut *mut _RBTreeNode)))

    }

    ((*__local_rover) = __local_node)

    ((*__local_node).parent = __local_parent)

    rb_tree_insert_case1(__param_tree, __local_node)

    ((*__param_tree).num_nodes = (*__param_tree).num_nodes + 1)

    return __local_node

}

// contract: receiver:_RBTree,unproved:1:read only
pub unsafe fn rb_tree_remove_node(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) {
    return
}

// contract: receiver:_RBTree,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn rb_tree_remove(__param_tree: *mut _RBTree, __param_key: *mut c_void) -> i32 {
    var __local_node: *mut _RBTreeNode

    (__local_node = rb_tree_lookup_node(__param_tree, __param_key))

    if (__local_node == null) {
        return 0

    }

    rb_tree_remove_node(__param_tree, __local_node)

    return 1

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn rb_tree_lookup_node(__param_tree: *mut _RBTree, __param_key: *mut c_void) -> *mut _RBTreeNode {
    var __local_node: *mut _RBTreeNode

    var __local_side: i32

    var __local_diff: i32

    (__local_node = (*__param_tree).root_node)

    while (__local_node != null) {
        (__local_diff = (((*__param_tree).compare_func.unwrap()(__param_key, (*__local_node).key) as i32)))

        if (__local_diff == 0) {
            return __local_node

        }
        if (__local_diff < 0) {
            (__local_side = ((0 as i32)))

        } else {
            (__local_side = ((1 as i32)))

        }

        (__local_node = (*__local_node).children[__local_side])

    }

    return ((null as *mut _RBTreeNode))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn rb_tree_lookup(__param_tree: *mut _RBTree, __param_key: *mut c_void) -> *mut c_void {
    var __local_node: *mut _RBTreeNode

    (__local_node = rb_tree_lookup_node(__param_tree, __param_key))

    if (__local_node == null) {
        return rb_tree_null_value

    }
    return (*__local_node).value


}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_root_node(__param_tree: *mut _RBTree) -> *mut _RBTreeNode {
    return (*__param_tree).root_node

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_node_key(__param_node: *mut _RBTreeNode) -> *mut c_void {
    return (*__param_node).key

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_node_value(__param_node: *mut _RBTreeNode) -> *mut c_void {
    return (*__param_node).value

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_node_child(__param_node: *mut _RBTreeNode, __param_side: i32) -> *mut _RBTreeNode {
    var __ci_expr_logic_0: i32

    if (__param_side == 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_side == 1: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        return (((*__param_node).children[__param_side] as *mut _RBTreeNode))

    }
    return ((null as *mut _RBTreeNode))



}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_node_parent(__param_node: *mut _RBTreeNode) -> *mut _RBTreeNode {
    return (*__param_node).parent

}

extern fn rb_tree_subtree_height(__param_node: *mut _RBTreeNode) -> i32
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_to_array(__param_tree: *mut _RBTree) -> *mut *mut c_void {
    return ((null as *mut *mut c_void))

}

unsafe fn rb_tree_node_side(__param_node: *mut _RBTreeNode) -> i32 {
    if ((*(*__param_node).parent).children[RB_TREE_NODE_LEFT] == __param_node) {
        return 0

    }
    return 1


}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
unsafe fn rb_tree_node_sibling(__param_node: *mut _RBTreeNode) -> *mut _RBTreeNode {
    var __local_side: i32

    (__local_side = ((rb_tree_node_side(__param_node) as i32)))

    return (((*(*__param_node).parent).children[((1 as u32) -% (__local_side as u32))] as *mut _RBTreeNode))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn rb_tree_node_uncle(__param_node: *mut _RBTreeNode) -> *mut _RBTreeNode {
    return ((rb_tree_node_sibling((*__param_node).parent) as *mut _RBTreeNode))

}

// contract: receiver-mut:_RBTree,unproved:1:out-parameter read before the write,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn rb_tree_node_replace(__param_tree: *mut _RBTree, __param_node1: *mut _RBTreeNode, __param_node2: *mut _RBTreeNode) -> Unit {
    var __local_side: i32

    if (__param_node2 != null) {
        ((*__param_node2).parent = (*__param_node1).parent)

    }

    if ((*__param_node1).parent == null) {
        ((*__param_tree).root_node = __param_node2)

    } else {
        (__local_side = ((rb_tree_node_side(__param_node1) as i32)))

        ((*(*__param_node1).parent).children[__local_side] = __param_node2)

    }

}

// contract: receiver-mut:_RBTree,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn rb_tree_rotate(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode, __param_direction: i32) -> *mut _RBTreeNode {
    var __local_new_root: *mut _RBTreeNode

    (__local_new_root = (*__param_node).children[((1 as u32) -% (__param_direction as u32))])

    rb_tree_node_replace(__param_tree, __param_node, __local_new_root)

    ((*__param_node).children[((1 as u32) -% (__param_direction as u32))] = (*__local_new_root).children[__param_direction])

    ((*__local_new_root).children[__param_direction] = __param_node)

    ((*__param_node).parent = __local_new_root)

    if ((*__param_node).children[((1 as u32) -% (__param_direction as u32))] != null) {
        ((*__param_node).children[((1 as u32) -% (__param_direction as u32))].parent = __param_node)

    }

    return __local_new_root

}

// contract: unproved:0:NULL is an accepted argument
unsafe fn rb_tree_free_subtree(__param_node: *mut _RBTreeNode) -> Unit {
    if (__param_node != null) {
        rb_tree_free_subtree((*__param_node).children[RB_TREE_NODE_LEFT])

        rb_tree_free_subtree((*__param_node).children[RB_TREE_NODE_RIGHT])

        alloc_test_free((__param_node as *mut c_void))

    }

}

// contract: receiver-mut:_RBTree,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn rb_tree_insert_case1(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) -> Unit {
    if ((*__param_node).parent == null) {
        ((*__param_node).color = ((1 as i32)))

    } else {
        rb_tree_insert_case2(__param_tree, __param_node)

    }

}

// contract: receiver-mut:_RBTree,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn rb_tree_insert_case2(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) {
    if ((*(*__param_node).parent).color != 1) {
        rb_tree_insert_case3(__param_tree, __param_node)

    }

}

// contract: receiver-mut:_RBTree,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn rb_tree_insert_case3(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) {
    var __local_grandparent: *mut _RBTreeNode

    var __local_uncle: *mut _RBTreeNode

    (__local_grandparent = (*(*__param_node).parent).parent)

    (__local_uncle = rb_tree_node_uncle(__param_node))

    var __ci_expr_logic_0: i32 = 0

    if (__local_uncle != null) {
        (__ci_expr_logic_0 = (if (*__local_uncle).color == 0: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        ((*(*__param_node).parent).color = ((1 as i32)))

        ((*__local_uncle).color = ((1 as i32)))

        ((*__local_grandparent).color = ((0 as i32)))

        rb_tree_insert_case1(__param_tree, __local_grandparent)

    } else {
        rb_tree_insert_case4(__param_tree, __param_node)

    }


}

// contract: receiver-mut:_RBTree,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn rb_tree_insert_case4(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) {
    var __local_next_node: *mut _RBTreeNode

    var __local_side: i32

    (__local_side = ((rb_tree_node_side(__param_node) as i32)))

    if (__local_side != rb_tree_node_side((*__param_node).parent)) {
        (__local_next_node = (*__param_node).parent)

        rb_tree_rotate(__param_tree, (*__param_node).parent, (((1 as u32) -% (__local_side as u32)) as i32))

    } else {
        (__local_next_node = __param_node)

    }

    rb_tree_insert_case5(__param_tree, __local_next_node)

}

// contract: receiver-mut:_RBTree,unproved:1:read only
unsafe fn rb_tree_insert_case5(__param_tree: *mut _RBTree, __param_node: *mut _RBTreeNode) {
    var __local_parent: *mut _RBTreeNode

    var __local_grandparent: *mut _RBTreeNode

    var __local_side: i32

    (__local_parent = (*__param_node).parent)

    (__local_grandparent = (*__local_parent).parent)

    (__local_side = ((rb_tree_node_side(__param_node) as i32)))

    rb_tree_rotate(__param_tree, __local_grandparent, (((1 as u32) -% (__local_side as u32)) as i32))

    ((*__local_parent).color = ((1 as i32)))

    ((*__local_grandparent).color = ((0 as i32)))

}

impl _RBTree {
    pub fn rb_tree_num_entries() -> i32 {
        let __param_tree: *mut _RBTree = (self as *const _RBTree) as *mut _RBTree
        return (unsafe *__param_tree).num_nodes

    }

}

let rb_tree_null_value: *mut c_void = null
