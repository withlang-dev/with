//! expect-stdout: ok

// Behavior test: pipeline operator (|>)
// Tests: tokenization, parsing

use Token
use Lexer
use Ast
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_pipe_token:
    var tokens = lex("|>")
    assert(TokenList.tag_at(tokens, 0) == TK_PIPE_GT())

fn test_backward_pipe_token:
    var tokens = lex("<|")
    assert(TokenList.tag_at(tokens, 0) == TK_LT_PIPE())

fn test_parse_pipeline:
    let src = "fn f:\n    x |> foo\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_PIPELINE())
    let lhs = AstPool.get_data0(p.pool, body)
    assert(AstPool.kind(p.pool, lhs) == NK_IDENT())
    let rhs = AstPool.get_data1(p.pool, body)
    assert(AstPool.kind(p.pool, rhs) == NK_IDENT())

fn test_pipe_plus_regular:
    // | alone is TK_PIPE, |> is TK_PIPE_GT
    var tokens = lex("| |>")
    assert(TokenList.tag_at(tokens, 0) == TK_PIPE())
    assert(TokenList.tag_at(tokens, 1) == TK_PIPE_GT())

fn main:
    test_pipe_token()
    test_backward_pipe_token()
    test_parse_pipeline()
    test_pipe_plus_regular()
    println("ok")
