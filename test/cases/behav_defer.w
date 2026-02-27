//! expect-stdout: ok

// Behavior test: defer
// Tests: defer keyword, parse, MIR lowering

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_defer_keyword:
    var tokens = lex("defer")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_DEFER())

fn test_parse_defer:
    let src = "fn f:\n    defer 42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_DEFER())
    let deferred = AstPool.get_data0(p.pool, body)
    assert(AstPool.kind(p.pool, deferred) == NK_INT_LIT())

fn test_sema_defer:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let expr = AstPool.add_node(pool, NK_INT_LIT(), 6, 8, 42, 0, 0)
    let defer_node = AstPool.add_node(pool, NK_DEFER(), 0, 8, expr, 0, 0)
    let t = Sema.check_expr(s, defer_node)
    assert(t == TYPE_VOID())

fn main:
    test_defer_keyword()
    test_parse_defer()
    test_sema_defer()
    println("ok")
