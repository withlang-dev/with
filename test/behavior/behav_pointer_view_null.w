type PointerNode { children: [2]*mut PointerNode }

unsafe fn has_child(node: *mut PointerNode, index: i32):
    (*node).children[index] != null

fn test_pointer_views_compare_with_null:
    var node = PointerNode { children: [null as *mut PointerNode; 2] }
    var child = PointerNode { children: [null as *mut PointerNode; 2] }
    node.children[1] = &raw mut child
    assert(unsafe { has_child(&raw mut node, 1) })
    assert(not unsafe { has_child(&raw mut node, 0) })
    assert(node.children[0] == null)
    assert(null == node.children[0])
    assert(node.children[1] != null)
    assert(null != node.children[1])
    let observed = node.children[1]
    assert(observed != null)
    let values: Vec[*mut PointerNode] = [null, &raw mut child]
    assert(values[0] == null)
    assert(null != values[1])
    let mapping: HashMap[i32, *mut PointerNode] = [1: &raw mut child]
    assert(mapping.get(1).unwrap() != null)

