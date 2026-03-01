//! expect-stdout: ok

// Behavior test: move semantics
// Tests: copy types, non-copy types, variable state tracking

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_copy_types:
    var types = TypeTable.new()
    // Primitive integers are copy
    assert(TypeTable.is_copy(types, TYPE_I8()))
    assert(TypeTable.is_copy(types, TYPE_I16()))
    assert(TypeTable.is_copy(types, TYPE_I32()))
    assert(TypeTable.is_copy(types, TYPE_I64()))
    assert(TypeTable.is_copy(types, TYPE_U8()))
    assert(TypeTable.is_copy(types, TYPE_U16()))
    assert(TypeTable.is_copy(types, TYPE_U32()))
    assert(TypeTable.is_copy(types, TYPE_U64()))
    // Floats are copy
    assert(TypeTable.is_copy(types, TYPE_F32()))
    assert(TypeTable.is_copy(types, TYPE_F64()))
    // Bool is copy
    assert(TypeTable.is_copy(types, TYPE_BOOL()))

fn test_non_copy_types:
    var types = TypeTable.new()
    // str is not copy
    assert(not TypeTable.is_copy(types, TYPE_STR()))

fn test_var_state_encoding:
    // Variable info encoding: type_id * 4 + is_mut * 2 + state
    // state: 0=live, 1=moved
    let encoded = 5 * 4 + 1 * 2 + 0  // TYPE_I32, mutable, live
    assert(var_type_id(encoded) == 5)
    assert(var_is_mut(encoded) == 1)
    assert(var_state(encoded) == 0)

fn test_scope_define_lookup:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Define mutable x
    Sema.define_var(s, "x", TYPE_I32(), 1)
    let info = Sema.lookup_var(s, "x")
    assert(info >= 0)
    assert(var_type_id(info) == TYPE_I32())
    assert(var_is_mut(info) == 1)
    // Define immutable y
    Sema.define_var(s, "y", TYPE_STR(), 0)
    let info2 = Sema.lookup_var(s, "y")
    assert(info2 >= 0)
    assert(var_type_id(info2) == TYPE_STR())
    assert(var_is_mut(info2) == 0)

fn test_scope_nested:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    Sema.define_var(s, "outer", TYPE_I32(), 0)
    Sema.push_scope(s)
    Sema.define_var(s, "inner", TYPE_BOOL(), 0)
    // Both visible
    assert(Sema.lookup_var(s, "outer") >= 0)
    assert(Sema.lookup_var(s, "inner") >= 0)
    Sema.pop_scope(s)
    // Only outer visible (scope model keeps all, but inner was in child)
    assert(Sema.lookup_var(s, "outer") >= 0)

fn main:
    test_copy_types()
    test_non_copy_types()
    test_var_state_encoding()
    test_scope_define_lookup()
    test_scope_nested()
    println("ok")
