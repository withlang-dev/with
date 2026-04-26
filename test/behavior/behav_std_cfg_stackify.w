//! expect-stdout: ok

use std.cfg.stackify

fn no_args -> Vec[i32]:
    Vec.new()

fn count_kind(tree: StackifyTree, kind: i32) -> i32:
    var count = 0
    var i = 0
    while i < tree.nodes.len() as i32:
        if tree.nodes.get(i as i64).kind == kind:
            count = count + 1
        i = i + 1
    count

fn has_node_for_block(tree: StackifyTree, kind: i32, block: i32) -> bool:
    var i = 0
    while i < tree.nodes.len() as i32:
        let node = tree.nodes.get(i as i64)
        if node.kind == kind and node.block == block:
            return true
        i = i + 1
    false

fn test_straight_line:
    var g = StackifyGraph.new(0)
    let b0 = g.add_block("entry")
    let b1 = g.add_block("exit")
    assert(b0 == 0)
    assert(b1 == 1)
    g.set_br(b0, b1, no_args())
    let values: Vec[i32] = Vec.new()
    values.push(7)
    g.set_return(b1, values)

    let result = stackify_graph(g)
    assert(result.ok)
    assert(result.tree.roots_count == 4)
    assert(count_kind(result.tree, StackifyNodeKind.Leaf) == 2)
    assert(count_kind(result.tree, StackifyNodeKind.ParamTransfer) == 1)
    assert(count_kind(result.tree, StackifyNodeKind.Return) == 1)

fn test_diamond_merge:
    var g = StackifyGraph.new(0)
    let entry = g.add_block("entry")
    let left = g.add_block("left")
    let right = g.add_block("right")
    let merge = g.add_block("merge")

    g.set_cond_br(entry, 10, left, no_args(), right, no_args())
    g.set_br(left, merge, no_args())
    g.set_br(right, merge, no_args())
    g.set_return(merge, no_args())

    let result = stackify_graph(g)
    assert(result.ok)
    assert(has_node_for_block(result.tree, StackifyNodeKind.Block, merge))
    assert(count_kind(result.tree, StackifyNodeKind.If) == 1)
    assert(count_kind(result.tree, StackifyNodeKind.Br) == 2)

fn test_natural_loop:
    var g = StackifyGraph.new(0)
    let entry = g.add_block("entry")
    let header = g.add_block("header")
    let done = g.add_block("done")

    g.set_br(entry, header, no_args())
    g.set_cond_br(header, 11, header, no_args(), done, no_args())
    g.set_return(done, no_args())

    let result = stackify_graph(g)
    assert(result.ok)
    assert(has_node_for_block(result.tree, StackifyNodeKind.Loop, header))
    assert(count_kind(result.tree, StackifyNodeKind.Br) >= 1)

fn one_arg(value: i32) -> Vec[i32]:
    let args: Vec[i32] = Vec.new()
    args.push(value)
    args

fn test_select_targets_transfer_params:
    var g = StackifyGraph.new(0)
    let entry = g.add_block("entry")
    let left = g.add_block("left")
    let right = g.add_block("right")
    let default_block = g.add_block("default")

    g.add_param(left, 101)
    g.add_param(right, 102)
    g.add_param(default_block, 103)
    let first_target = g.add_branch_target(left, one_arg(201))
    let _ = g.add_branch_target(right, one_arg(202))
    let default_target = g.add_branch_target(default_block, one_arg(203))
    g.set_select_targets(entry, 12, first_target, 2, default_target)
    g.set_return(left, no_args())
    g.set_return(right, no_args())
    g.set_return(default_block, no_args())

    let result = stackify_graph(g)
    assert(result.ok)
    assert(count_kind(result.tree, StackifyNodeKind.Select) == 1)
    assert(count_kind(result.tree, StackifyNodeKind.ParamTransfer) >= 3)

fn test_irreducible_rejected:
    var g = StackifyGraph.new(0)
    let entry = g.add_block("entry")
    let left = g.add_block("left")
    let right = g.add_block("right")

    g.set_cond_br(entry, 12, left, no_args(), right, no_args())
    g.set_br(left, right, no_args())
    g.set_br(right, left, no_args())

    let result = stackify_graph(g)
    assert(not result.ok)
    assert(result.message.len() > 0)

fn main:
    test_straight_line()
    test_diamond_merge()
    test_natural_loop()
    test_select_targets_transfer_params()
    test_irreducible_rejected()
    print("ok")
