//! expect-stdout: ok

// Behavior test: string interpolation (spec SS15.3)
// Missing feature: lexer should split "hello {name}" into
// TK_STRING_START, TK_STRING_FRAGMENT, expression, TK_STRING_END.
// Currently the lexer treats interpolated strings as plain TK_STRING_LIT.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_interpolation_token_constants:
    // Token constants for string interpolation are defined
    assert(TK_STRING_START() == 4)
    assert(TK_STRING_END() == 5)
    assert(TK_STRING_FRAGMENT() == 6)

fn test_plain_string_unchanged:
    // Plain strings without interpolation should remain TK_STRING_LIT
    var tokens = lex("\"hello world\"")
    assert(TokenList.tag_at(tokens, 0) == TK_STRING_LIT())

fn test_interpolation_not_yet_split:
    // Currently "hello {name}" is lexed as a single TK_STRING_LIT
    // Once implemented, this should be TK_STRING_START + expr + TK_STRING_END
    var tokens = lex("\"hello {name}\"")
    assert(TokenList.tag_at(tokens, 0) == TK_STRING_LIT())

fn test_string_lit_constant:
    assert(TK_STRING_LIT() == 2)

fn test_empty_string:
    var tokens = lex("\"\"")
    assert(TokenList.tag_at(tokens, 0) == TK_STRING_LIT())

fn main:
    test_interpolation_token_constants()
    test_plain_string_unchanged()
    test_interpolation_not_yet_split()
    test_string_lit_constant()
    test_empty_string()
    println("ok")
