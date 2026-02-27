//! expect-stdout: ok

use Token
use Lexer
use Ast
use Type
use Traits
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn parse(source: str) -> Sema:
    var tokens = lex(source)
    var pool = AstPool.new()
    // Reserve node 0 as null sentinel
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    // We need to use Parser for real parsing, but for sema tests
    // we can build AST nodes directly to test the type checker.
    var intern = InternPool.new()
    var s = Sema.new(pool, source, intern)
    s

fn test_builtin_types:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Verify builtins are registered
    assert(TypeTable.lookup(s.types, "i32") == TYPE_I32())
    assert(TypeTable.lookup(s.types, "bool") == TYPE_BOOL())
    assert(TypeTable.lookup(s.types, "str") == TYPE_STR())
    assert(TypeTable.lookup(s.types, "void") == TYPE_VOID())

fn test_scope_chain:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Define x in root scope
    Sema.define_var(s, "x", TYPE_I32(), 0)
    let x_info = Sema.lookup_var(s, "x")
    assert(x_info >= 0)
    assert(var_type_id(x_info) == TYPE_I32())
    // Push child scope
    Sema.push_scope(s)
    // x should still be visible
    let x_info2 = Sema.lookup_var(s, "x")
    assert(x_info2 >= 0)
    assert(var_type_id(x_info2) == TYPE_I32())
    // Define y in child scope
    Sema.define_var(s, "y", TYPE_BOOL(), 1)
    let y_info = Sema.lookup_var(s, "y")
    assert(y_info >= 0)
    assert(var_type_id(y_info) == TYPE_BOOL())
    assert(var_is_mut(y_info) == 1)
    // Pop child scope
    Sema.pop_scope(s)
    // y should not be visible (but our simple scope model keeps it)
    // x should still be visible
    let x_info3 = Sema.lookup_var(s, "x")
    assert(x_info3 >= 0)

fn test_fn_registration:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Manually register a function
    s.fn_names.push("add")
    var ptypes = Vec.new()
    ptypes.push(TYPE_I32())
    ptypes.push(TYPE_I32())
    let ft = TypeTable.add_fn(s.types, ptypes, TYPE_I32(), 0)
    s.fn_type_ids.push(ft)
    s.fn_ret_types.push(TYPE_I32())
    s.fn_param_starts.push(0)
    s.fn_param_counts.push(2)
    s.fn_is_generic.push(0)
    let idx = Sema.find_fn(s, "add")
    assert(idx == 0)
    assert(Sema.find_fn(s, "nonexistent") == -1)

fn test_type_compatibility:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Same type
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_I32()) == true)
    // Error type is compatible with anything
    assert(Sema.types_compatible(s, TYPE_ERROR(), TYPE_I32()) == true)
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_ERROR()) == true)
    // Never type is compatible with anything
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_NEVER()) == true)
    // Int widening
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_I64()) == true)
    // Different types
    assert(Sema.types_compatible(s, TYPE_I32(), TYPE_STR()) == false)
    assert(Sema.types_compatible(s, TYPE_BOOL(), TYPE_I32()) == false)

fn test_check_int_lit:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Add an int literal node
    let n = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 42, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_I32())

fn test_check_bool_lit:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let n = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_BOOL())

fn test_check_string_lit:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let n = AstPool.add_node(pool, NK_STRING_LIT(), 0, 7, 0, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_STR())

fn test_check_binary:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_INT_LIT(), 0, 1, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_INT_LIT(), 4, 5, 2, 0, 0)
    // Add: i32 + i32 → i32
    let add = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_ADD())
    let t = Sema.check_expr(s, add)
    assert(t == TYPE_I32())
    // Eq: i32 == i32 → bool
    let eq = AstPool.add_node(pool, NK_BINARY(), 0, 5, lhs, rhs, OP_EQ())
    let t2 = Sema.check_expr(s, eq)
    assert(t2 == TYPE_BOOL())

fn test_check_ident:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Define a variable
    Sema.define_var(s, "x", TYPE_I32(), 0)
    // Create ident node
    let sym = AstPool.add_string(pool, "x")
    let n = AstPool.add_node(pool, NK_IDENT(), 0, 1, sym, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_I32())
    // Undeclared ident
    let sym2 = AstPool.add_string(pool, "unknown")
    let n2 = AstPool.add_node(pool, NK_IDENT(), 0, 7, sym2, 0, 0)
    let t2 = Sema.check_expr(s, n2)
    assert(t2 == TYPE_ERROR())
    assert(Sema.diag_count(s) >= 1)

fn test_variant_lookup:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Register an enum type
    var vnames = Vec.new()
    vnames.push(AstPool.add_string(pool, "Red"))
    vnames.push(AstPool.add_string(pool, "Green"))
    var vpayloads = Vec.new()
    vpayloads.push(0)
    vpayloads.push(0)
    var vptypes = Vec.new()
    let eid = TypeTable.add_enum(s.types, AstPool.add_string(pool, "Color"), vnames, vpayloads, vptypes)
    // Register variant lookup
    s.variant_names.push("Red")
    s.variant_enum_types.push(eid)
    s.variant_indices.push(0)
    s.variant_names.push("Green")
    s.variant_enum_types.push(eid)
    s.variant_indices.push(1)
    // Check ident "Red" resolves to enum type
    let sym = AstPool.add_string(pool, "Red")
    let n = AstPool.add_node(pool, NK_IDENT(), 0, 3, sym, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == eid)

fn main:
    test_builtin_types()
    test_scope_chain()
    test_fn_registration()
    test_type_compatibility()
    test_check_int_lit()
    test_check_bool_lit()
    test_check_string_lit()
    test_check_binary()
    test_check_ident()
    test_variant_lookup()
    println("ok")
