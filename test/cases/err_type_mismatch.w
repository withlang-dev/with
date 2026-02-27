//! expect-stdout: ok

// Compile error test: type mismatches
// Tests that the self-hosted Sema correctly detects type errors

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn test_incompatible_types:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // i32 and str are not compatible
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_STR()) == false)
    // bool and i32 are not compatible
    assert(Sema.types_compatible(s, TYPE_BOOL(), TYPE_I32()) == false)
    // void and i32 are not compatible
    assert(Sema.types_compatible(s, TYPE_VOID(), TYPE_I32()) == false)
    // str and bool are not compatible
    assert(Sema.types_compatible(s, TYPE_STR(), TYPE_BOOL()) == false)
    // f32 and str are not compatible
    assert(Sema.types_compatible(s, TYPE_F32(), TYPE_STR()) == false)

fn test_same_types_compatible:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_I32()) == true)
    assert(Sema.types_compatible(s, TYPE_STR(), TYPE_STR()) == true)
    assert(Sema.types_compatible(s, TYPE_BOOL(), TYPE_BOOL()) == true)
    assert(Sema.types_compatible(s, TYPE_F64(), TYPE_F64()) == true)

fn test_error_type_compat:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Error type is compatible with anything (for error recovery)
    assert(Sema.types_compatible(s, TYPE_ERROR(), TYPE_I32()) == true)
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_ERROR()) == true)
    assert(Sema.types_compatible(s, TYPE_ERROR(), TYPE_STR()) == true)

fn test_never_type_compat:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Never type is compatible with anything (for return/break)
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_NEVER()) == true)
    assert(Sema.types_compatible(s, TYPE_STR(), TYPE_NEVER()) == true)

fn main:
    test_incompatible_types()
    test_same_types_compatible()
    test_error_type_compat()
    test_never_type_compat()
    println("ok")
