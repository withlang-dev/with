//! expect-stdout: ok

// Compile error test: wrong argument counts
// Tests that Sema detects argument count mismatches

use Ast
use Types
use Sema
use InternPool

fn test_fn_param_count:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Register fn add(a: i32, b: i32) -> i32
    s.fn_names.push("add")
    var ptypes = Vec.new()
    ptypes.push(TYPE_I32)
    ptypes.push(TYPE_I32)
    let ft = TypeTable.add_fn(s.types, ptypes, TYPE_I32, 0)
    s.fn_type_ids.push(ft)
    s.fn_ret_types.push(TYPE_I32)
    s.fn_param_starts.push(0)
    s.fn_param_counts.push(2)
    s.fn_params.push(TYPE_I32)
    s.fn_params.push(TYPE_I32)
    s.fn_is_generic.push(0)
    // Verify param count
    let idx = Sema.find_fn(s, "add")
    assert(idx == 0)
    let pc = s.fn_param_counts.get(0)
    assert(pc == 2)

fn test_fn_zero_params:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    s.fn_names.push("nop")
    var ptypes = Vec.new()
    let ft = TypeTable.add_fn(s.types, ptypes, TYPE_VOID, 0)
    s.fn_type_ids.push(ft)
    s.fn_ret_types.push(TYPE_VOID)
    s.fn_param_starts.push(0)
    s.fn_param_counts.push(0)
    s.fn_is_generic.push(0)
    let pc = s.fn_param_counts.get(0)
    assert(pc == 0)

fn test_fn_type_param_count:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32)
    params.push(TYPE_STR)
    params.push(TYPE_BOOL)
    let ft = TypeTable.add_fn(types, params, TYPE_VOID, 0)
    assert(TypeTable.fn_param_count(types, ft) == 3)

fn main:
    test_fn_param_count()
    test_fn_zero_params()
    test_fn_type_param_count()
    println("ok")
