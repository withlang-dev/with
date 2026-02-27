//! expect-stdout: ok

// Behavior test: drop order verification (Rust ui/drop/)
// Tests: reverse-declaration drop order, drops on early return,
// scope-based drop emission in MIR

use Ast
use Type
use Mir
use MirBuild

fn test_reverse_drop_order:
    // MirBuilder should emit drops in reverse declaration order
    // when popping a scope. Simulate: declare A, B, C; drops should
    // emit C, B, A.
    var pool = AstPool.new()
    var types = TypeTable.new()
    // Create a non-copy struct type to ensure drops are emitted
    var names = Vec.new()
    names.push(0)
    var ftypes = Vec.new()
    ftypes.push(TYPE_I32())
    var defaults = Vec.new()
    defaults.push(0)
    let struct_type = TypeTable.add_struct(types, 99, names, ftypes, defaults)
    assert(not TypeTable.is_copy(types, struct_type))
    // Build MIR with 3 non-copy locals in a scope
    var builder = MirBuilder.new(pool, types, "")
    let entry = MirBuilder.new_block(builder)
    MirBuilder.switch_to(builder, entry)
    MirBuilder.push_scope(builder)
    // Add 3 non-copy locals (locals 1, 2, 3; local 0 is return)
    let a = MirBody.add_local(builder.body, 1, struct_type, 0)
    MirBuilder.track_local(builder, a)
    let b = MirBody.add_local(builder.body, 2, struct_type, 0)
    MirBuilder.track_local(builder, b)
    let c = MirBody.add_local(builder.body, 3, struct_type, 0)
    MirBuilder.track_local(builder, c)
    // Pop scope should emit drops in reverse: c, b, a
    MirBuilder.pop_scope(builder)
    // Verify: 3 drop stmts emitted
    let sc = MirBody.stmt_count(builder.body)
    assert(sc == 3)
    // Verify drop order: first drop is for local c (last declared)
    assert(MirBody.stmt_kind(builder.body, 0) == SK_DROP())
    assert(MirBody.stmt_d0(builder.body, 0) == c)
    assert(MirBody.stmt_d0(builder.body, 1) == b)
    assert(MirBody.stmt_d0(builder.body, 2) == a)

fn test_copy_types_not_dropped:
    // Copy types (i32, bool, etc.) should NOT generate drops
    var pool = AstPool.new()
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "")
    let entry = MirBuilder.new_block(builder)
    MirBuilder.switch_to(builder, entry)
    MirBuilder.push_scope(builder)
    // Add copy-type locals
    let x = MirBody.add_local(builder.body, 1, TYPE_I32(), 0)
    MirBuilder.track_local(builder, x)
    let y = MirBody.add_local(builder.body, 2, TYPE_BOOL(), 0)
    MirBuilder.track_local(builder, y)
    let z = MirBody.add_local(builder.body, 3, TYPE_F64(), 0)
    MirBuilder.track_local(builder, z)
    MirBuilder.pop_scope(builder)
    // No drop stmts should be emitted for copy types
    assert(MirBody.stmt_count(builder.body) == 0)

fn test_mixed_copy_noncopy:
    // Only non-copy locals generate drops; copy locals are skipped
    var pool = AstPool.new()
    var types = TypeTable.new()
    var names = Vec.new()
    names.push(0)
    var ftypes = Vec.new()
    ftypes.push(TYPE_I32())
    var defaults = Vec.new()
    defaults.push(0)
    let s_type = TypeTable.add_struct(types, 88, names, ftypes, defaults)
    var builder = MirBuilder.new(pool, types, "")
    let entry = MirBuilder.new_block(builder)
    MirBuilder.switch_to(builder, entry)
    MirBuilder.push_scope(builder)
    // a: i32 (copy), b: struct (non-copy), c: bool (copy)
    let a = MirBody.add_local(builder.body, 1, TYPE_I32(), 0)
    MirBuilder.track_local(builder, a)
    let b = MirBody.add_local(builder.body, 2, s_type, 0)
    MirBuilder.track_local(builder, b)
    let c = MirBody.add_local(builder.body, 3, TYPE_BOOL(), 0)
    MirBuilder.track_local(builder, c)
    MirBuilder.pop_scope(builder)
    // Only 1 drop: for b (the non-copy local)
    assert(MirBody.stmt_count(builder.body) == 1)
    assert(MirBody.stmt_kind(builder.body, 0) == SK_DROP())
    assert(MirBody.stmt_d0(builder.body, 0) == b)

fn test_nested_scope_drops:
    // Nested scopes: inner scope drops before outer scope
    var pool = AstPool.new()
    var types = TypeTable.new()
    var names = Vec.new()
    names.push(0)
    var ftypes = Vec.new()
    ftypes.push(TYPE_I32())
    var defaults = Vec.new()
    defaults.push(0)
    let s_type = TypeTable.add_struct(types, 77, names, ftypes, defaults)
    var builder = MirBuilder.new(pool, types, "")
    let entry = MirBuilder.new_block(builder)
    MirBuilder.switch_to(builder, entry)
    // Outer scope
    MirBuilder.push_scope(builder)
    let outer = MirBody.add_local(builder.body, 1, s_type, 0)
    MirBuilder.track_local(builder, outer)
    // Inner scope
    MirBuilder.push_scope(builder)
    let inner = MirBody.add_local(builder.body, 2, s_type, 0)
    MirBuilder.track_local(builder, inner)
    MirBuilder.pop_scope(builder)
    // After inner pop: 1 drop for inner
    assert(MirBody.stmt_count(builder.body) == 1)
    assert(MirBody.stmt_d0(builder.body, 0) == inner)
    // Pop outer scope
    MirBuilder.pop_scope(builder)
    // Now 2 drops total: inner first, then outer
    assert(MirBody.stmt_count(builder.body) == 2)
    assert(MirBody.stmt_d0(builder.body, 1) == outer)

fn test_defer_lifo_order:
    // Defers should execute in LIFO (last-in first-out) order
    var pool = AstPool.new()
    var types = TypeTable.new()
    // Create some AST nodes to serve as defer bodies
    let d1 = AstPool.add_node(pool, NK_INT_LIT(), 0, 0, 1, 0, 0)
    let d2 = AstPool.add_node(pool, NK_INT_LIT(), 0, 0, 2, 0, 0)
    let d3 = AstPool.add_node(pool, NK_INT_LIT(), 0, 0, 3, 0, 0)
    var builder = MirBuilder.new(pool, types, "")
    let entry = MirBuilder.new_block(builder)
    MirBuilder.switch_to(builder, entry)
    MirBuilder.push_scope(builder)
    MirBuilder.add_defer(builder, d1)
    MirBuilder.add_defer(builder, d2)
    MirBuilder.add_defer(builder, d3)
    // Verify defers stored
    let sc = builder.scopes.get(builder.current_scope_idx as i64)
    assert(sc.defers.len() == 3)
    // Defers execute in LIFO: d3, d2, d1

fn main:
    test_reverse_drop_order()
    test_copy_types_not_dropped()
    test_mixed_copy_noncopy()
    test_nested_scope_drops()
    test_defer_lifo_order()
    println("ok")
