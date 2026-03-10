//! expect-stdout: ok

use Types
use Ast
use Mir
use MirLower

fn test_mir_body_basics:
    var body = MirBody.new()
    // Local 0 is return place
    assert(MirBody.local_count(body) == 1)
    // Add locals
    let l1 = MirBody.add_local(body, 10, TYPE_I32, 0)
    let l2 = MirBody.add_local(body, 11, TYPE_BOOL, 1)
    assert(l1 == 1)
    assert(l2 == 2)
    assert(MirBody.local_count(body) == 3)
    let d1 = MirBody.get_local(body, 1)
    assert(d1.name_sym == 10)
    assert(d1.type_id == TYPE_I32)
    assert(d1.is_mutable == 0)
    let d2 = MirBody.get_local(body, 2)
    assert(d2.name_sym == 11)
    assert(d2.type_id == TYPE_BOOL)
    assert(d2.is_mutable == 1)

fn test_basic_blocks:
    var body = MirBody.new()
    let bb0 = MirBody.add_block(body)
    let bb1 = MirBody.add_block(body)
    let bb2 = MirBody.add_block(body)
    assert(bb0 == 0)
    assert(bb1 == 1)
    assert(bb2 == 2)
    assert(MirBody.block_count(body) == 3)

fn test_statements:
    var body = MirBody.new()
    let l1 = MirBody.add_local(body, -1, TYPE_I32, 0)
    let bb0 = MirBody.add_block(body)
    // Add assign statement
    MirBody.add_assign(body, bb0, l1, RV_CONSTANT, 42, 0)
    assert(MirBody.stmt_count(body) == 1)
    assert(MirBody.stmt_kind(body, 0) == SK_ASSIGN)
    assert(MirBody.stmt_d0(body, 0) == l1)
    assert(MirBody.stmt_d1(body, 0) == RV_CONSTANT)
    // Add drop statement
    MirBody.add_drop(body, bb0, l1)
    assert(MirBody.stmt_count(body) == 2)
    assert(MirBody.stmt_kind(body, 1) == SK_DROP)
    assert(MirBody.stmt_d0(body, 1) == l1)
    // Add nop
    MirBody.add_nop(body, bb0)
    assert(MirBody.stmt_count(body) == 3)
    assert(MirBody.stmt_kind(body, 2) == SK_NOP)

fn test_terminators:
    var body = MirBody.new()
    let bb0 = MirBody.add_block(body)
    let bb1 = MirBody.add_block(body)
    let bb2 = MirBody.add_block(body)
    // Goto
    MirBody.set_goto(body, bb0, bb1)
    assert(MirBody.get_extra(body, 0) == TM_GOTO)
    assert(MirBody.get_extra(body, 1) == bb1)
    // Return
    MirBody.set_return(body, bb1)
    assert(MirBody.get_extra(body, 4) == TM_RETURN)
    // Switch
    MirBody.set_switch_int(body, bb2, 1, bb0, bb1)
    assert(MirBody.get_extra(body, 8) == TM_SWITCH_INT)
    assert(MirBody.get_extra(body, 9) == 1)
    assert(MirBody.get_extra(body, 10) == bb0)
    assert(MirBody.get_extra(body, 11) == bb1)

fn test_builder_simple_fn:
    // Build AST for: fn f: 42
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let body_node = AstPool.add_node(pool, NK_INT_LIT, 0, 2, 42, 0, 0)
    let name_sym = AstPool.add_string(pool, "f")
    // extra: [param_count=0, flags=0, ret_type=0]
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL, 0, 10, name_sym, body_node, e0)
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "fn f: 42")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    // Should have entry block + locals
    assert(MirBody.block_count(mir) >= 1)
    assert(MirBody.local_count(mir) >= 1)

fn test_builder_if_expr:
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let cond = AstPool.add_node(pool, NK_BOOL_LIT, 0, 4, 1, 0, 0)
    let then_n = AstPool.add_node(pool, NK_INT_LIT, 5, 6, 1, 0, 0)
    let else_n = AstPool.add_node(pool, NK_INT_LIT, 7, 8, 2, 0, 0)
    let if_node = AstPool.add_node(pool, NK_IF_EXPR, 0, 8, cond, then_n, else_n)
    let name_sym = AstPool.add_string(pool, "g")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL, 0, 20, name_sym, if_node, e0)
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    // Should have entry + then + else + join blocks (at least 4)
    assert(MirBody.block_count(mir) >= 4)

fn test_builder_while:
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let cond = AstPool.add_node(pool, NK_BOOL_LIT, 0, 4, 1, 0, 0)
    let body_n = AstPool.add_node(pool, NK_INT_LIT, 5, 7, 0, 0, 0)
    let while_node = AstPool.add_node(pool, NK_WHILE, 0, 10, cond, body_n, 0)
    let name_sym = AstPool.add_string(pool, "h")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL, 0, 20, name_sym, while_node, e0)
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    // Should have entry + cond + body + exit blocks (at least 4)
    assert(MirBody.block_count(mir) >= 4)

fn test_place:
    let p = Place.local_only(5)
    assert(p.local == 5)
    assert(p.proj_count == 0)

fn main:
    test_mir_body_basics()
    test_basic_blocks()
    test_statements()
    test_terminators()
    test_builder_simple_fn()
    test_builder_if_expr()
    test_builder_while()
    test_place()
    println("ok")
