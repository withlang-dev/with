//! expect-stdout: ok

// Compile error test: undefined functions
// Tests that Sema detects calls to undeclared functions

use Ast
use Types
use Sema
use InternPool

fn test_fn_not_found:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // No functions registered
    assert(Sema.find_fn(s, "foo") == -1)
    assert(Sema.find_fn(s, "bar") == -1)

fn test_fn_found_after_registration:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    s.fn_names.push("foo")
    var ptypes = Vec.new()
    let ft = TypeTable.add_fn(s.types, ptypes, TYPE_VOID, 0)
    s.fn_type_ids.push(ft)
    s.fn_ret_types.push(TYPE_VOID)
    s.fn_param_starts.push(0)
    s.fn_param_counts.push(0)
    s.fn_is_generic.push(0)
    assert(Sema.find_fn(s, "foo") == 0)
    assert(Sema.find_fn(s, "bar") == -1)

fn test_method_not_found:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // No methods registered
    let count = s.method_names.len()
    assert(count == 0)

fn main:
    test_fn_not_found()
    test_fn_found_after_registration()
    test_method_not_found()
    println("ok")
