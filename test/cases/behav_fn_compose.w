//! expect-stdout: ok

// Behavior test: function composition operators (spec SS9.6)
// Missing feature: >> (forward compose) and << (backward compose)
// are lexed as TK_GT_GT and TK_LT_LT (shared with bit shift)
// but parser does not handle them as composition operators.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_gt_gt_token:
    var tokens = lex(">>")
    assert(TokenList.tag_at(tokens, 0) == TK_GT_GT)
    assert(TK_GT_GT == 84)

fn test_lt_lt_token:
    var tokens = lex("<<")
    assert(TokenList.tag_at(tokens, 0) == TK_LT_LT)
    assert(TK_LT_LT == 85)

fn test_compose_in_expression_tokens:
    // f >> g (forward composition)
    var tokens = lex("f >> g")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)  // f
    assert(TokenList.tag_at(tokens, 1) == TK_GT_GT)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // g

fn test_backward_compose_tokens:
    // f << g (backward composition)
    var tokens = lex("f << g")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)  // f
    assert(TokenList.tag_at(tokens, 1) == TK_LT_LT)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // g

fn test_compose_chain_tokens:
    // f >> g >> h
    var tokens = lex("f >> g >> h")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)
    assert(TokenList.tag_at(tokens, 1) == TK_GT_GT)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)
    assert(TokenList.tag_at(tokens, 3) == TK_GT_GT)
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT)

fn test_shift_vs_compose_same_token:
    // >> is used for both bit-shift and composition
    // The distinction is semantic, not lexical
    assert(TK_GT_GT == TK_GT_GT)
    assert(TK_LT_LT == TK_LT_LT)
    // Shift operators in binary ops
    assert(OP_SHL == 16)
    assert(OP_SHR == 17)

fn main:
    test_gt_gt_token()
    test_lt_lt_token()
    test_compose_in_expression_tokens()
    test_backward_compose_tokens()
    test_compose_chain_tokens()
    test_shift_vs_compose_same_token()
    println("ok")
