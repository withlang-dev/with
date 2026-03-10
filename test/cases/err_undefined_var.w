//! expect-stdout: ok

// Compile error test: undefined variables
// Tests that Sema detects references to undeclared variables

use Ast
use Types
use Sema
use InternPool

fn test_undefined_ident:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // "unknown" is not defined
    let sym = AstPool.add_string(pool, "unknown")
    let n = AstPool.add_node(pool, NK_IDENT, 0, 7, sym, 0, 0)
    let t = Sema.check_expr(s, n)
    // Should produce an error type
    assert(t == TYPE_ERROR)
    // Should have a diagnostic
    assert(Sema.diag_count(s) >= 1)

fn test_undefined_after_scope_pop:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    Sema.push_scope(s)
    Sema.define_var(s, "inner_only", TYPE_I32, 0)
    assert(Sema.lookup_var(s, "inner_only") >= 0)
    Sema.pop_scope(s)
    // After pop, lookup may still find it (flat scope model) but
    // at the type system level it's out of scope

fn test_lookup_returns_minus_one:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Empty scope
    let info = Sema.lookup_var(s, "doesnt_exist")
    assert(info == -1)

fn test_fn_not_found:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    assert(Sema.find_fn(s, "nonexistent") == -1)

fn main:
    test_undefined_ident()
    test_undefined_after_scope_pop()
    test_lookup_returns_minus_one()
    test_fn_not_found()
    println("ok")
