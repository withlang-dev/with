//! expect-stdout: ok

// Behavior test: functions
// Tests: fn declaration, params, return types, call, recursion

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

fn test_fn_keyword:
    var tokens = lex("fn return")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FN())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_RETURN())

fn test_parse_simple_fn:
    let src = "fn main:\n    42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())
    let name_str = AstPool.get_data0(p.pool, decl)
    assert(AstPool.get_string(p.pool, name_str) == "main")

fn test_parse_fn_params:
    let src = "fn add(a: i32, b: i32) -> i32:\n    a\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let extra_idx = AstPool.get_data2(p.pool, decl)
    assert(AstPool.get_extra(p.pool, extra_idx) == 2)  // param_count

fn test_parse_fn_return_type:
    let src = "fn f() -> bool:\n    true\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let extra_idx = AstPool.get_data2(p.pool, decl)
    let ret_type_node = AstPool.get_extra(p.pool, extra_idx + 2)
    assert(AstPool.kind(p.pool, ret_type_node) == NK_TYPE_NAMED())

fn test_parse_call:
    let src = "fn f:\n    foo(1, 2)\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_CALL())
    assert(AstPool.get_data2(p.pool, body) == 2)  // arg_count

fn test_parse_return:
    let src = "fn f:\n    return 42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_RETURN())
    let value = AstPool.get_data0(p.pool, body)
    assert(AstPool.kind(p.pool, value) == NK_INT_LIT())

fn test_parse_multi_fn:
    let src = "fn a:\n    1\n\nfn b:\n    2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 2)

fn test_sema_fn_registration:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
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

fn test_type_fn:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    params.push(TYPE_I32())
    let ft = TypeTable.add_fn(types, params, TYPE_BOOL(), 0)
    assert(TypeTable.kind(types, ft) == TK_FN())
    assert(TypeTable.fn_param_count(types, ft) == 2)
    assert(TypeTable.fn_return_type(types, ft) == TYPE_BOOL())
    assert(TypeTable.fn_param_type(types, ft, 0) == TYPE_I32())
    assert(TypeTable.fn_param_type(types, ft, 1) == TYPE_I32())

fn main:
    test_fn_keyword()
    test_parse_simple_fn()
    test_parse_fn_params()
    test_parse_fn_return_type()
    test_parse_call()
    test_parse_return()
    test_parse_multi_fn()
    test_sema_fn_registration()
    test_type_fn()
    println("ok")
