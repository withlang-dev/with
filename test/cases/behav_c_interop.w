//! expect-stdout: ok

// Behavior test: C interop features (spec SS15.3, SS16.1)
// Missing features:
// - C-string literals c"hello" (lexed as TK_C_STRING_LIT, AST has NK_C_STRING_LIT)
// - c_import(...) directive (keyword lexed, AST has NK_C_IMPORT)
// Lexer handles c"..." but parser may not generate NK_C_STRING_LIT.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_c_string_token:
    var tokens = lex("c\"hello\"")
    assert(TokenList.tag_at(tokens, 0) == TK_C_STRING_LIT)
    assert(TK_C_STRING_LIT == 3)

fn test_c_string_with_escape:
    var tokens = lex("c\"hello\\nworld\"")
    assert(TokenList.tag_at(tokens, 0) == TK_C_STRING_LIT)

fn test_c_string_empty:
    var tokens = lex("c\"\"")
    assert(TokenList.tag_at(tokens, 0) == TK_C_STRING_LIT)

fn test_c_import_keyword:
    var tokens = lex("c_import")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_C_IMPORT)
    assert(TK_KW_C_IMPORT == 48)

fn test_c_import_node_constant:
    assert(NK_C_IMPORT == 6)

fn test_c_string_node_constant:
    assert(NK_C_STRING_LIT == 50)

fn test_c_import_call_tokens:
    // c_import("stdio.h")
    var tokens = lex("c_import(\"stdio.h\")")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_C_IMPORT)
    assert(TokenList.tag_at(tokens, 1) == TK_L_PAREN)
    assert(TokenList.tag_at(tokens, 2) == TK_STRING_LIT)
    assert(TokenList.tag_at(tokens, 3) == TK_R_PAREN)

fn test_extern_fn_node_constant:
    // extern fn is the current C interop mechanism
    assert(NK_EXTERN_FN == 5)

fn main:
    test_c_string_token()
    test_c_string_with_escape()
    test_c_string_empty()
    test_c_import_keyword()
    test_c_import_node_constant()
    test_c_string_node_constant()
    test_c_import_call_tokens()
    test_extern_fn_node_constant()
    println("ok")
