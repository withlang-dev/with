//! expect-stdout: ok

// Behavior test: boolean operations
// Tests: and, or, not, short-circuit, comparisons

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

fn test_bool_keywords:
    var tokens = lex("true false and or not")
    assert(TokenList.tag_at(tokens, 0) == TK_TRUE())
    assert(TokenList.tag_at(tokens, 1) == TK_FALSE())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_AND())
    assert(TokenList.tag_at(tokens, 3) == TK_KW_OR())
    assert(TokenList.tag_at(tokens, 4) == TK_KW_NOT())

fn test_parse_bool_lit:
    let src = "fn f:\n    true\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BOOL_LIT())
    assert(AstPool.get_data0(p.pool, body) == 1)

fn test_parse_false_lit:
    let src = "fn f:\n    false\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BOOL_LIT())
    assert(AstPool.get_data0(p.pool, body) == 0)

fn test_parse_and:
    let src = "fn f:\n    true and false\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_AND())

fn test_parse_or:
    let src = "fn f:\n    true or false\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_OR())

fn test_parse_not:
    let src = "fn f:\n    not true\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_UNARY())
    assert(AstPool.get_data1(p.pool, body) == UOP_NOT())

fn test_sema_bool_lit:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let n = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_BOOL())

fn test_sema_and_or:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_BOOL_LIT(), 9, 14, 0, 0, 0)
    // and: bool and bool → bool
    let and_node = AstPool.add_node(pool, NK_BINARY(), 0, 14, lhs, rhs, OP_AND())
    let t1 = Sema.check_expr(s, and_node)
    assert(t1 == TYPE_BOOL())
    // or: bool or bool → bool
    let or_node = AstPool.add_node(pool, NK_BINARY(), 0, 14, lhs, rhs, OP_OR())
    let t2 = Sema.check_expr(s, or_node)
    assert(t2 == TYPE_BOOL())

fn test_sema_not:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let operand = AstPool.add_node(pool, NK_BOOL_LIT(), 4, 8, 1, 0, 0)
    let not_node = AstPool.add_node(pool, NK_UNARY(), 0, 8, operand, UOP_NOT(), 0)
    let t = Sema.check_expr(s, not_node)
    assert(t == TYPE_BOOL())

fn test_sema_eq_bool:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let lhs = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let rhs = AstPool.add_node(pool, NK_BOOL_LIT(), 8, 13, 0, 0, 0)
    let eq = AstPool.add_node(pool, NK_BINARY(), 0, 13, lhs, rhs, OP_EQ())
    let t = Sema.check_expr(s, eq)
    assert(t == TYPE_BOOL())

fn main:
    test_bool_keywords()
    test_parse_bool_lit()
    test_parse_false_lit()
    test_parse_and()
    test_parse_or()
    test_parse_not()
    test_sema_bool_lit()
    test_sema_and_or()
    test_sema_not()
    test_sema_eq_bool()
    println("ok")
