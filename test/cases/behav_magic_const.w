//! expect-stdout: ok

// Behavior test: magic constants (spec SS17.0)
// Missing feature: __FILE__, __LINE__, __FN__ should be recognized
// as special identifiers and replaced at compile time.
// Currently they lex as plain TK_IDENT.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_file_magic_lexes_as_ident:
    // __FILE__ currently lexes as a regular identifier
    var tokens = lex("__FILE__")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)

fn test_line_magic_lexes_as_ident:
    // __LINE__ currently lexes as a regular identifier
    var tokens = lex("__LINE__")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)

fn test_fn_magic_lexes_as_ident:
    // __FN__ currently lexes as a regular identifier
    var tokens = lex("__FN__")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)

fn test_magic_in_expression_tokens:
    // println(__FILE__ ++ ":" ++ __LINE__)
    var tokens = lex("__FILE__ ++ __LINE__")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)  // __FILE__
    assert(TokenList.tag_at(tokens, 1) == TK_PLUS_PLUS)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // __LINE__

fn test_comptime_node:
    // Magic constants are related to comptime evaluation
    assert(NK_COMPTIME == 61)
    assert(TK_KW_COMPTIME == 42)

fn main:
    test_file_magic_lexes_as_ident()
    test_line_magic_lexes_as_ident()
    test_fn_magic_lexes_as_ident()
    test_magic_in_expression_tokens()
    test_comptime_node()
    println("ok")
