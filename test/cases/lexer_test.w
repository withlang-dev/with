//! expect-stdout: ok

use Token
use Lexer

fn main:
    // Test basic tokenization
    let src = "fn main -> i32: 42"
    var lex = Lexer.new(src, 0)
    var tokens = Lexer.tokenize(lex)

    // fn main -> i32 : 42 eof
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FN)
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT)
    assert(TokenList.tag_at(tokens, 2) == TK_ARROW)
    assert(TokenList.tag_at(tokens, 3) == TK_IDENT)  // i32
    assert(TokenList.tag_at(tokens, 4) == TK_COLON)
    assert(TokenList.tag_at(tokens, 5) == TK_INT_LIT)
    assert(TokenList.tag_at(tokens, 6) == TK_EOF)

    // Test operators
    let src2 = "== != <= >= |> ?? -> =>"
    var lex2 = Lexer.new(src2, 0)
    var tokens2 = Lexer.tokenize(lex2)
    assert(TokenList.tag_at(tokens2, 0) == TK_EQ_EQ)
    assert(TokenList.tag_at(tokens2, 1) == TK_BANG_EQ)
    assert(TokenList.tag_at(tokens2, 2) == TK_LT_EQ)
    assert(TokenList.tag_at(tokens2, 3) == TK_GT_EQ)
    assert(TokenList.tag_at(tokens2, 4) == TK_PIPE_GT)
    assert(TokenList.tag_at(tokens2, 5) == TK_QUESTION_QUESTION)
    assert(TokenList.tag_at(tokens2, 6) == TK_ARROW)
    assert(TokenList.tag_at(tokens2, 7) == TK_FAT_ARROW)

    // Test keywords
    let src3 = "let var if else while for match type"
    var lex3 = Lexer.new(src3, 0)
    var tokens3 = Lexer.tokenize(lex3)
    assert(TokenList.tag_at(tokens3, 0) == TK_KW_LET)
    assert(TokenList.tag_at(tokens3, 1) == TK_KW_VAR)
    assert(TokenList.tag_at(tokens3, 2) == TK_KW_IF)
    assert(TokenList.tag_at(tokens3, 3) == TK_KW_ELSE)
    assert(TokenList.tag_at(tokens3, 4) == TK_KW_WHILE)
    assert(TokenList.tag_at(tokens3, 5) == TK_KW_FOR)
    assert(TokenList.tag_at(tokens3, 6) == TK_KW_MATCH)
    assert(TokenList.tag_at(tokens3, 7) == TK_KW_TYPE)

    // Test numbers
    let src4 = "42 3.14 0xFF 0b1010"
    var lex4 = Lexer.new(src4, 0)
    var tokens4 = Lexer.tokenize(lex4)
    assert(TokenList.tag_at(tokens4, 0) == TK_INT_LIT)
    assert(TokenList.tag_at(tokens4, 1) == TK_FLOAT_LIT)
    assert(TokenList.tag_at(tokens4, 2) == TK_INT_LIT)
    assert(TokenList.tag_at(tokens4, 3) == TK_INT_LIT)

    // Test string
    let src5 = "\"hello world\""
    var lex5 = Lexer.new(src5, 0)
    var tokens5 = Lexer.tokenize(lex5)
    assert(TokenList.tag_at(tokens5, 0) == TK_STRING_LIT)

    // Test comments are skipped
    let src6 = "let x // comment\nlet y"
    var lex6 = Lexer.new(src6, 0)
    var tokens6 = Lexer.tokenize(lex6)
    // let x newline let y eof
    assert(TokenList.tag_at(tokens6, 0) == TK_KW_LET)
    assert(TokenList.tag_at(tokens6, 1) == TK_IDENT)
    assert(TokenList.tag_at(tokens6, 2) == TK_NEWLINE)
    assert(TokenList.tag_at(tokens6, 3) == TK_KW_LET)
    assert(TokenList.tag_at(tokens6, 4) == TK_IDENT)

    // Test span tracking
    let src7 = "fn main"
    var lex7 = Lexer.new(src7, 0)
    var tokens7 = Lexer.tokenize(lex7)
    assert(TokenList.start_at(tokens7, 0) == 0)  // "fn" starts at 0
    assert(TokenList.end_at(tokens7, 0) == 2)    // "fn" ends at 2
    assert(TokenList.start_at(tokens7, 1) == 3)  // "main" starts at 3
    assert(TokenList.end_at(tokens7, 1) == 7)    // "main" ends at 7

    println("ok")
