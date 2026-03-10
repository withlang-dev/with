//! expect-stdout: ok

// Behavior test: advanced async features (spec SS14.6, SS14.9, SS14.10, SS14.13)
// Missing features:
// - async: blocks (NK_ASYNC_BLOCK defined, never generated)
// - select await (TK_KW_SELECT lexed, not parsed)
// - async scope (not parsed)
// - scope |s|: (OS thread structured concurrency, not parsed)

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_async_keyword:
    var tokens = lex("async")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_ASYNC)
    assert(TK_KW_ASYNC == 38)

fn test_await_keyword:
    var tokens = lex("await")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_AWAIT)
    assert(TK_KW_AWAIT == 39)

fn test_spawn_keyword:
    var tokens = lex("spawn")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_SPAWN)
    assert(TK_KW_SPAWN == 40)

fn test_select_keyword:
    var tokens = lex("select")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_SELECT)
    assert(TK_KW_SELECT == 50)

fn test_async_block_node_constant:
    assert(NK_ASYNC_BLOCK == 58)

fn test_await_node_constant:
    assert(NK_AWAIT == 57)

fn test_spawn_node_constant:
    assert(NK_SPAWN == 59)

fn test_yield_node_constant:
    assert(NK_YIELD == 60)

fn test_select_await_tokens:
    // select await:
    //     result1 = task1 -> handle1
    //     result2 = task2 -> handle2
    var tokens = lex("select await:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_SELECT)
    assert(TokenList.tag_at(tokens, 1) == TK_KW_AWAIT)
    assert(TokenList.tag_at(tokens, 2) == TK_COLON)

fn test_async_block_tokens:
    // async:
    //     body
    var tokens = lex("async:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_ASYNC)
    assert(TokenList.tag_at(tokens, 1) == TK_COLON)

fn test_async_fn_flag:
    assert(FN_FLAG_ASYNC == 2)

fn test_gen_fn_flag:
    assert(FN_FLAG_GEN == 4)

fn main:
    test_async_keyword()
    test_await_keyword()
    test_spawn_keyword()
    test_select_keyword()
    test_async_block_node_constant()
    test_await_node_constant()
    test_spawn_node_constant()
    test_yield_node_constant()
    test_select_await_tokens()
    test_async_block_tokens()
    test_async_fn_flag()
    test_gen_fn_flag()
    println("ok")
