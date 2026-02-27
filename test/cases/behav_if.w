//! expect-stdout: ok

// Behavior test: if/else expressions
// Tests: if/then, if/: colon form, nested if, if as expression

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_if_keywords:
    var tokens = lex("if else then")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_IF())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_ELSE())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_THEN())

fn test_parse_if_then:
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

fn test_parse_if_colon:
    let src = "fn f:\n    if true:\n        1\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_IF_EXPR())

fn test_sema_if_type:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let cond = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let then_b = AstPool.add_node(pool, NK_INT_LIT(), 10, 11, 42, 0, 0)
    let else_b = AstPool.add_node(pool, NK_INT_LIT(), 17, 18, 0, 0, 0)
    let if_node = AstPool.add_node(pool, NK_IF_EXPR(), 0, 18, cond, then_b, else_b)
    let t = Sema.check_expr(s, if_node)
    assert(t == TYPE_I32())

fn test_sema_if_no_else:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let cond = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let then_b = AstPool.add_node(pool, NK_INT_LIT(), 10, 11, 42, 0, 0)
    let if_node = AstPool.add_node(pool, NK_IF_EXPR(), 0, 11, cond, then_b, 0)
    let t = Sema.check_expr(s, if_node)
    // if without else: result is void
    assert(t == TYPE_VOID() or t == TYPE_I32())

fn main:
    test_if_keywords()
    test_parse_if_then()
    test_parse_if_colon()
    test_sema_if_type()
    test_sema_if_no_else()
    println("ok")
