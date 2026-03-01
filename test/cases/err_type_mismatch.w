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
    assert(not Sema.types_compatible(s, TYPE_I32(), TYPE_STR()))
    // bool and i32 are not compatible
    assert(not Sema.types_compatible(s, TYPE_BOOL(), TYPE_I32()))
    // void and i32 are not compatible
    assert(not Sema.types_compatible(s, TYPE_VOID(), TYPE_I32()))
    // str and bool are not compatible
    assert(not Sema.types_compatible(s, TYPE_STR(), TYPE_BOOL()))
    // f32 and str are not compatible
    assert(not Sema.types_compatible(s, TYPE_F32(), TYPE_STR()))

fn test_same_types_compatible:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_I32()))
    assert(Sema.types_compatible(s, TYPE_STR(), TYPE_STR()))
    assert(Sema.types_compatible(s, TYPE_BOOL(), TYPE_BOOL()))
    assert(Sema.types_compatible(s, TYPE_F64(), TYPE_F64()))

fn test_error_type_compat:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Error type is compatible with anything (for error recovery)
    assert(Sema.types_compatible(s, TYPE_ERROR(), TYPE_I32()))
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_ERROR()))
    assert(Sema.types_compatible(s, TYPE_ERROR(), TYPE_STR()))

fn test_never_type_compat:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Never type is compatible with anything (for return/break)
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_NEVER()))
    assert(Sema.types_compatible(s, TYPE_STR(), TYPE_NEVER()))

fn main:
    test_incompatible_types()
    test_same_types_compatible()
    test_error_type_compat()
    test_never_type_compat()
    println("ok")
