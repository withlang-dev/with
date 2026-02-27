//! expect-stdout: ok

// Compile error test: binary operator type errors
// Tests that Sema correctly type-checks binary operations

use Ast
use Type
use Sema
use InternPool

fn test_arith_on_ints:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    // i32 + i32 → i32 (valid)
    let add = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_ADD())
    let t = Sema.check_expr(s, add)
    assert(t == TYPE_I32())

fn test_comparison_yields_bool:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    // All comparison ops should return bool
    let eq = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_EQ())
    assert(Sema.check_expr(s, eq) == TYPE_BOOL())
    let neq = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_NEQ())
    assert(Sema.check_expr(s, neq) == TYPE_BOOL())
    let lt = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_LT())
    assert(Sema.check_expr(s, lt) == TYPE_BOOL())
    let gt = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_GT())
    assert(Sema.check_expr(s, gt) == TYPE_BOOL())
    let lte = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_LTE())
    assert(Sema.check_expr(s, lte) == TYPE_BOOL())
    let gte = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_GTE())
    assert(Sema.check_expr(s, gte) == TYPE_BOOL())

fn test_logical_ops_on_bool:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_BOOL_LIT(), 9, 14, 0, 0, 0)
    let and_n = AstPool.add_node(pool, NK_BINARY(), 0, 14, lhs, rhs, OP_AND())
    assert(Sema.check_expr(s, and_n) == TYPE_BOOL())
    let or_n = AstPool.add_node(pool, NK_BINARY(), 0, 14, lhs, rhs, OP_OR())
    assert(Sema.check_expr(s, or_n) == TYPE_BOOL())

fn main:
    test_arith_on_ints()
    test_comparison_yields_bool()
    test_logical_ops_on_bool()
    println("ok")
