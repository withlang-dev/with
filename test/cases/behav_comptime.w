//! expect-stdout: ok

// Behavior test: comptime
// Tests: comptime keyword, parsing

use Token
use Lexer
use Ast
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_comptime_keyword:
    var tokens = lex("comptime")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_COMPTIME)

fn test_parse_comptime_fn:
    let src = "comptime fn pi() -> f64:\n    3.14\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) >= 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL)

fn test_fn_decl_flags:
    // Verify flag constants are distinct
    assert(FN_FLAG_PUB == 1)
    assert(FN_FLAG_ASYNC == 2)
    assert(FN_FLAG_GEN == 4)
    assert(FN_FLAG_COMPTIME == 8)
    assert(FN_FLAG_TAILREC == 16)
    assert(FN_FLAG_MUST_USE == 32)
    assert(FN_FLAG_VARIADIC == 64)

fn main:
    test_comptime_keyword()
    test_parse_comptime_fn()
    test_fn_decl_flags()
    println("ok")
