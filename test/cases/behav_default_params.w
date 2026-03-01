//! expect-stdout: ok

// Behavior test: default function parameters (spec SS9.1a)
// Missing feature: parser should support fn f(x: i32 = 5)
// Currently not parsed; default values in fn params are ignored.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_default_param_token_sequence:
    // fn f(x: i32 = 5):
    var tokens = lex("fn f(x: i32 = 5):")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FN())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())  // f
    assert(TokenList.tag_at(tokens, 2) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 3) == TK_IDENT())  // x
    assert(TokenList.tag_at(tokens, 4) == TK_COLON())
    assert(TokenList.tag_at(tokens, 5) == TK_IDENT())  // i32
    assert(TokenList.tag_at(tokens, 6) == TK_EQ())      // =
    assert(TokenList.tag_at(tokens, 7) == TK_INT_LIT())  // 5
    assert(TokenList.tag_at(tokens, 8) == TK_R_PAREN())
    assert(TokenList.tag_at(tokens, 9) == TK_COLON())

fn test_multiple_default_params_tokens:
    // fn greet(name: str = "world", times: i32 = 1):
    var tokens = lex("fn greet(name: str = \"world\", times: i32 = 1):")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FN())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())  // greet
    assert(TokenList.tag_at(tokens, 2) == TK_L_PAREN())
    // name: str = "world"
    assert(TokenList.tag_at(tokens, 3) == TK_IDENT())  // name
    assert(TokenList.tag_at(tokens, 4) == TK_COLON())
    assert(TokenList.tag_at(tokens, 5) == TK_IDENT())  // str
    assert(TokenList.tag_at(tokens, 6) == TK_EQ())
    assert(TokenList.tag_at(tokens, 7) == TK_STRING_LIT())  // "world"
    assert(TokenList.tag_at(tokens, 8) == TK_COMMA())

fn test_fn_decl_node:
    assert(NK_FN_DECL() == 1)

fn main:
    test_default_param_token_sequence()
    test_multiple_default_params_tokens()
    test_fn_decl_node()
    println("ok")
