//! expect-stdout: ok

// Behavior test: backward pipeline operator <| (spec SS9.6)
// Token TK_LT_PIPE exists and is lexed. Parser support unclear.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_lt_pipe_token:
    var tokens = lex("<|")
    assert(TokenList.tag_at(tokens, 0) == TK_LT_PIPE())
    assert(TK_LT_PIPE() == 83)

fn test_backward_pipe_expression_tokens:
    // f <| x  (apply f to x)
    var tokens = lex("f <| x")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())  // f
    assert(TokenList.tag_at(tokens, 1) == TK_LT_PIPE())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())  // x

fn test_forward_vs_backward:
    // |> and <| are distinct tokens
    assert(TK_PIPE_GT() != TK_LT_PIPE())
    assert(TK_PIPE_GT() == 82)
    assert(TK_LT_PIPE() == 83)

fn test_backward_chain_tokens:
    // f <| g <| x
    var tokens = lex("f <| g <| x")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())
    assert(TokenList.tag_at(tokens, 1) == TK_LT_PIPE())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())
    assert(TokenList.tag_at(tokens, 3) == TK_LT_PIPE())
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT())

fn test_pipeline_node_constant:
    // Both |> and <| would use NK_PIPELINE or similar
    assert(NK_PIPELINE() == 47)

fn main:
    test_lt_pipe_token()
    test_backward_pipe_expression_tokens()
    test_forward_vs_backward()
    test_backward_chain_tokens()
    test_pipeline_node_constant()
    println("ok")
