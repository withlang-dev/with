//! expect-stdout: ok

// Compile error test: return type mismatches
// Tests that Sema tracks return types for functions

use Ast
use Type
use Sema
use InternPool

fn test_return_type_tracking:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Set current return type to i32
    s.current_return_type = TYPE_I32()
    assert(s.current_return_type == TYPE_I32())
    // Return type compat check
    assert(Sema.types_compatible(s, TYPE_I32(), s.current_return_type) == true)
    assert(Sema.types_compatible(s, TYPE_STR(), s.current_return_type) == false)

fn test_fn_return_type_registration:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    s.fn_names.push("get_name")
    var ptypes = Vec.new()
    let ft = TypeTable.add_fn(s.types, ptypes, TYPE_STR(), 0)
    s.fn_type_ids.push(ft)
    s.fn_ret_types.push(TYPE_STR())
    s.fn_param_starts.push(0)
    s.fn_param_counts.push(0)
    s.fn_is_generic.push(0)
    assert(s.fn_ret_types.get(0) == TYPE_STR())

fn test_void_return:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    s.current_return_type = TYPE_VOID()
    assert(Sema.types_compatible(s, TYPE_VOID(), s.current_return_type) == true)

fn main:
    test_return_type_tracking()
    test_fn_return_type_registration()
    test_void_return()
    println("ok")
