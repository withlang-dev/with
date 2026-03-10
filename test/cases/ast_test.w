//! expect-stdout: ok

use Ast

fn main:
    var pool = AstPool.new()

    // Test adding nodes
    let n0 = AstPool.add_node(pool, NK_INT_LIT, 0, 2, 42, 0, 0)
    assert(n0 == 0)
    let n1 = AstPool.add_node(pool, NK_IDENT, 3, 7, 0, 0, 0)
    assert(n1 == 1)
    assert(AstPool.node_count(pool) == 2)

    // Test reading node data
    assert(AstPool.kind(pool, 0) == NK_INT_LIT)
    assert(AstPool.kind(pool, 1) == NK_IDENT)
    assert(AstPool.get_data0(pool, 0) == 42)
    assert(AstPool.get_start(pool, 0) == 0)
    assert(AstPool.get_end(pool, 0) == 2)
    assert(AstPool.get_start(pool, 1) == 3)
    assert(AstPool.get_end(pool, 1) == 7)

    // Test extra data
    let e0 = AstPool.add_extra(pool, 10)
    let e1 = AstPool.add_extra(pool, 20)
    let e2 = AstPool.add_extra(pool, 30)
    assert(e0 == 0)
    assert(e1 == 1)
    assert(AstPool.get_extra(pool, 0) == 10)
    assert(AstPool.get_extra(pool, 1) == 20)
    assert(AstPool.get_extra(pool, 2) == 30)

    // Test string table
    let s0 = AstPool.add_string(pool, "hello")
    let s1 = AstPool.add_string(pool, "world")
    assert(s0 == 0)
    assert(s1 == 1)
    assert(AstPool.get_string(pool, 0) == "hello")
    assert(AstPool.get_string(pool, 1) == "world")

    // Test decl tracking
    let fn_node = AstPool.add_node(pool, NK_FN_DECL, 0, 50, 0, 0, 0)
    AstPool.add_decl(pool, fn_node)
    assert(AstPool.decl_count(pool) == 1)
    assert(AstPool.get_decl(pool, 0) == fn_node)

    // Test binary node
    let lhs = AstPool.add_node(pool, NK_INT_LIT, 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT, 4, 5, 2, 0, 0)
    let bin = AstPool.add_node(pool, NK_BINARY, 0, 5, lhs, rhs, OP_ADD)
    assert(AstPool.kind(pool, bin) == NK_BINARY)
    assert(AstPool.get_data0(pool, bin) == lhs)
    assert(AstPool.get_data1(pool, bin) == rhs)
    assert(AstPool.get_data2(pool, bin) == OP_ADD)

    println("ok")
