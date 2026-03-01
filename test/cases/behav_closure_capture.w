//! expect-stdout: ok

// Behavior test: closure capture semantics (Rust ui/closures/)
// Tests: capture by reference, immutable capture, fn pointer types,
// closure type construction

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_closure_token:
    var tokens = lex("|x| => x")
    assert(TokenList.tag_at(tokens, 0) == TK_PIPE())

fn test_parse_closure_with_body:
    let src = "fn f:\n    |x| => x + 1\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_CLOSURE())

fn test_fn_ptr_type_single_param:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    let ft = TypeTable.add_fn(types, params, TYPE_I32(), 0)
    assert(TypeTable.is_fn(types, ft))
    assert(TypeTable.fn_param_count(types, ft) == 1)
    assert(TypeTable.fn_return_type(types, ft) == TYPE_I32())
    assert(TypeTable.fn_param_type(types, ft, 0) == TYPE_I32())

fn test_fn_ptr_type_multi_param:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    params.push(TYPE_F64())
    params.push(TYPE_BOOL())
    let ft = TypeTable.add_fn(types, params, TYPE_STR(), 0)
    assert(TypeTable.fn_param_count(types, ft) == 3)
    assert(TypeTable.fn_param_type(types, ft, 0) == TYPE_I32())
    assert(TypeTable.fn_param_type(types, ft, 1) == TYPE_F64())
    assert(TypeTable.fn_param_type(types, ft, 2) == TYPE_BOOL())
    assert(TypeTable.fn_return_type(types, ft) == TYPE_STR())

fn test_fn_ptr_type_no_params:
    var types = TypeTable.new()
    var params = Vec.new()
    let ft = TypeTable.add_fn(types, params, TYPE_VOID(), 0)
    assert(TypeTable.fn_param_count(types, ft) == 0)
    assert(TypeTable.fn_return_type(types, ft) == TYPE_VOID())

fn test_fn_ptr_type_returning_fn:
    // Higher-order: fn() -> fn(i32) -> i32
    var types = TypeTable.new()
    var inner_params = Vec.new()
    inner_params.push(TYPE_I32())
    let inner_ft = TypeTable.add_fn(types, inner_params, TYPE_I32(), 0)
    var outer_params = Vec.new()
    let outer_ft = TypeTable.add_fn(types, outer_params, inner_ft, 0)
    assert(TypeTable.fn_return_type(types, outer_ft) == inner_ft)
    assert(TypeTable.is_fn(types, TypeTable.fn_return_type(types, outer_ft)))

fn test_closure_scope_capture:
    // In Sema, captured variables are looked up through scope chain
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Define a variable in outer scope
    Sema.define_var(s, "x", TYPE_I32(), 0)
    // Push inner scope (simulating closure body)
    Sema.push_scope(s)
    // Variable should still be visible through scope chain
    let v = Sema.lookup_var(s, "x")
    assert(v >= 0)
    assert(var_type_id(v) == TYPE_I32())
    assert(var_is_mut(v) == 0)
    Sema.pop_scope(s)

fn test_captured_let_immutable:
    // A `let` binding captured by a closure cannot be mutated
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // let x = 5 (immutable)
    Sema.define_var(s, "x", TYPE_I32(), 0)
    Sema.push_scope(s)
    let v = Sema.lookup_var(s, "x")
    assert(var_is_mut(v) == 0)
    Sema.pop_scope(s)

fn main:
    test_closure_token()
    test_parse_closure_with_body()
    test_fn_ptr_type_single_param()
    test_fn_ptr_type_multi_param()
    test_fn_ptr_type_no_params()
    test_fn_ptr_type_returning_fn()
    test_closure_scope_capture()
    test_captured_let_immutable()
    println("ok")
