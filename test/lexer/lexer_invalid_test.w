//! expect-stdout: ok

use Lexer
use Token

fn main:
    var lexer1 = Lexer.init("$", 0)
    let t1 = lexer1.tokenize()
    assert(t1.get_tag(0) == TokenKind.TK_INVALID)
    assert(t1.get_tag(1) == TokenKind.TK_EOF)

    var lexer2 = Lexer.init("'\\x4'", 0)
    let t2 = lexer2.tokenize()
    assert(t2.get_tag(0) == TokenKind.TK_INVALID)
    assert(t2.get_tag(t2.len() - 1) == TokenKind.TK_EOF)

    // #1005: a string the source ends inside is one invalid token to the
    // end (the parser names it), never a string the program accepts.
    var lexer3 = Lexer.init("r#\"unterminated", 0)
    let t3 = lexer3.tokenize()
    assert(t3.get_tag(0) == TokenKind.TK_INVALID)
    assert(t3.get_tag(1) == TokenKind.TK_EOF)

    var lexer4 = Lexer.init("\"\"\"unterminated", 0)
    let t4 = lexer4.tokenize()
    assert(t4.get_tag(0) == TokenKind.TK_INVALID)
    assert(t4.get_tag(1) == TokenKind.TK_EOF)

    for src in ["\"abc", "f\"abc", "c\"abc"]:
        var lx = Lexer.init(src, 0)
        let tx = lx.tokenize()
        assert(tx.get_tag(0) == TokenKind.TK_INVALID)
        assert(tx.get_tag(1) == TokenKind.TK_EOF)

    var lexer5 = Lexer.init("\"\\q\"", 0)
    let t5 = lexer5.tokenize()
    assert(t5.get_tag(0) == TokenKind.TK_STRING_LIT)
    assert(t5.get_tag(1) == TokenKind.TK_EOF)

    print("ok")
