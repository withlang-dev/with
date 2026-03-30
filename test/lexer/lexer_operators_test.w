//! expect-stdout: ok

use Lexer
use Token

fn main:
    var lexer1 = Lexer.init("|> <| >> << ? ?. ?? -> => .. ..= +% -% *%", 0)
    let t1 = lexer1.tokenize()
    assert(t1.get_tag(0) == TokenKind.TK_PIPE_GT())
    assert(t1.get_tag(1) == TokenKind.TK_LT_PIPE())
    assert(t1.get_tag(2) == TokenKind.TK_GT_GT())
    assert(t1.get_tag(3) == TokenKind.TK_LT_LT())
    assert(t1.get_tag(4) == TokenKind.TK_QUESTION())
    assert(t1.get_tag(5) == TokenKind.TK_QUESTION_DOT())
    assert(t1.get_tag(6) == TokenKind.TK_QUESTION_QUESTION())
    assert(t1.get_tag(7) == TokenKind.TK_ARROW())
    assert(t1.get_tag(8) == TokenKind.TK_FAT_ARROW())
    assert(t1.get_tag(9) == TokenKind.TK_DOT_DOT())
    assert(t1.get_tag(10) == TokenKind.TK_DOT_DOT_EQ())
    assert(t1.get_tag(11) == TokenKind.TK_PLUS_WRAP())
    assert(t1.get_tag(12) == TokenKind.TK_MINUS_WRAP())
    assert(t1.get_tag(13) == TokenKind.TK_STAR_WRAP())
    assert(t1.get_tag(14) == TokenKind.TK_EOF())

    var lexer2 = Lexer.init("< | - > ? . ! $", 0)
    let t2 = lexer2.tokenize()
    assert(t2.get_tag(0) == TokenKind.TK_LT())
    assert(t2.get_tag(1) == TokenKind.TK_PIPE())
    assert(t2.get_tag(2) == TokenKind.TK_MINUS())
    assert(t2.get_tag(3) == TokenKind.TK_GT())
    assert(t2.get_tag(4) == TokenKind.TK_QUESTION())
    assert(t2.get_tag(5) == TokenKind.TK_DOT())
    assert(t2.get_tag(6) == TokenKind.TK_BANG())
    assert(t2.get_tag(7) == TokenKind.TK_INVALID())
    assert(t2.get_tag(8) == TokenKind.TK_EOF())

    print("ok")
