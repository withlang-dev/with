//! expect-stdout: ok

// Behavior test: pub visibility and module declaration (spec SS18.1, SS18.3)
// Missing features:
// - pub visibility modifier on fn, type, let
// - module declaration: module MyModule
// Keywords TK_KW_PUB and TK_KW_MODULE are lexed.
// FN_FLAG_PUB exists but parser doesn't set it.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_pub_keyword:
    var tokens = lex("pub")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_PUB)
    assert(TK_KW_PUB == 37)

fn test_module_keyword:
    var tokens = lex("module")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_MODULE)
    assert(TK_KW_MODULE == 36)

fn test_pub_fn_token_sequence:
    // pub fn greet():
    var tokens = lex("pub fn greet():")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_PUB)
    assert(TokenList.tag_at(tokens, 1) == TK_KW_FN)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // greet

fn test_pub_type_token_sequence:
    // pub type Point:
    var tokens = lex("pub type Point:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_PUB)
    assert(TokenList.tag_at(tokens, 1) == TK_KW_TYPE)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // Point

fn test_module_decl_token_sequence:
    // module MyLib
    var tokens = lex("module MyLib")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_MODULE)
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT)  // MyLib

fn test_pub_flag_constant:
    assert(FN_FLAG_PUB == 1)

fn main:
    test_pub_keyword()
    test_module_keyword()
    test_pub_fn_token_sequence()
    test_pub_type_token_sequence()
    test_module_decl_token_sequence()
    test_pub_flag_constant()
    println("ok")
