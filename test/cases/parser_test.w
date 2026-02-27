//! expect-stdout: ok

use Token
use Lexer
use Ast
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_simple_fn:
    let src = "fn main:\n    42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())
    let name_str = AstPool.get_data0(p.pool, decl)
    assert(AstPool.get_string(p.pool, name_str) == "main")
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_INT_LIT())

fn test_fn_with_params:
    let src = "fn add(a: i32, b: i32) -> i32:\n    a\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())
    let name_str = AstPool.get_data0(p.pool, decl)
    assert(AstPool.get_string(p.pool, name_str) == "add")
    // Check extra: [param_count=2, flags=0, ret_type, a_name, a_type, b_name, b_type]
    let extra_idx = AstPool.get_data2(p.pool, decl)
    assert(AstPool.get_extra(p.pool, extra_idx) == 2)  // param_count

fn test_binary_expr:
    let src = "fn f:\n    1 + 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_ADD())

fn test_if_expr:
    let src = "fn f:\n    if true then 1 else 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_IF_EXPR())
    let cond = AstPool.get_data0(p.pool, body)
    assert(AstPool.kind(p.pool, cond) == NK_BOOL_LIT())
    let then_body = AstPool.get_data1(p.pool, body)
    assert(AstPool.kind(p.pool, then_body) == NK_INT_LIT())
    let else_body = AstPool.get_data2(p.pool, body)
    assert(AstPool.kind(p.pool, else_body) == NK_INT_LIT())

fn test_let_binding:
    let src = "fn f:\n    let x = 42\n    x\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    // Body should be a block with one stmt (let) and tail (x)
    assert(AstPool.kind(p.pool, body) == NK_BLOCK())
    let tail = AstPool.get_data2(p.pool, body)
    assert(AstPool.kind(p.pool, tail) == NK_IDENT())

fn test_call:
    let src = "fn f:\n    foo(1, 2)\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_CALL())
    assert(AstPool.get_data2(p.pool, body) == 2)  // arg_count

fn test_type_decl_struct:
    let src = "type Point = {\n    x: i32,\n    y: i32,\n}\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_TYPE_DECL())
    let flags = AstPool.get_data2(p.pool, decl)
    let kind_bits = (flags / 256)  // field_count in upper bits
    assert(kind_bits == 2)  // 2 fields

fn test_use_decl:
    let src = "use Token\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_USE_DECL())

fn test_type_named:
    let src = "fn f(x: i32) -> bool:\n    true\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let extra_idx = AstPool.get_data2(p.pool, decl)
    let ret_type_node = AstPool.get_extra(p.pool, extra_idx + 2)
    assert(AstPool.kind(p.pool, ret_type_node) == NK_TYPE_NAMED())

fn test_while_loop:
    let src = "fn f:\n    while true:\n        42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_WHILE())

fn test_match:
    let src = "fn f:\n    match x\n        0 -> 1\n        _ -> 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_MATCH())
    assert(AstPool.get_data2(p.pool, body) == 2)  // 2 arms

fn main:
    test_simple_fn()
    test_fn_with_params()
    test_binary_expr()
    test_if_expr()
    test_let_binding()
    test_call()
    test_type_decl_struct()
    test_use_decl()
    test_type_named()
    test_while_loop()
    test_match()
    println("ok")
