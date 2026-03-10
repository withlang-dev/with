//! expect-stdout: ok

// Compile error test: assignment to immutable bindings
// Tests that Sema correctly tracks mutability

use Ast
use Types
use Sema
use InternPool

fn test_immutable_var:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // let x = 42 (immutable, is_mut=0)
    Sema.define_var(s, "x", TYPE_I32, 0)
    let info = Sema.lookup_var(s, "x")
    assert(info >= 0)
    assert(var_is_mut(info) == 0)

fn test_mutable_var:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // var y = 42 (mutable, is_mut=1)
    Sema.define_var(s, "y", TYPE_I32, 1)
    let info = Sema.lookup_var(s, "y")
    assert(info >= 0)
    assert(var_is_mut(info) == 1)

fn test_mixed_mutability:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    Sema.define_var(s, "a", TYPE_I32, 0)  // let
    Sema.define_var(s, "b", TYPE_I32, 1)  // var
    Sema.define_var(s, "c", TYPE_STR, 0)  // let
    let a_info = Sema.lookup_var(s, "a")
    let b_info = Sema.lookup_var(s, "b")
    let c_info = Sema.lookup_var(s, "c")
    assert(var_is_mut(a_info) == 0)
    assert(var_is_mut(b_info) == 1)
    assert(var_is_mut(c_info) == 0)

fn main:
    test_immutable_var()
    test_mutable_var()
    test_mixed_mutability()
    println("ok")
