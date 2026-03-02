//! expect-stdout: ok

use Lexer
use Token

fn main:
    var lexer1 = Lexer.init("|> <| >> << ? ?. ?? -> => .. ..= +% -% *%", 0)
    let t1 = lexer1.tokenize()
    assert(t1.get_tag(0) == TK_PIPE_GT())
    assert(t1.get_tag(1) == TK_LT_PIPE())
    assert(t1.get_tag(2) == TK_GT_GT())
    assert(t1.get_tag(3) == TK_LT_LT())
    assert(t1.get_tag(4) == TK_QUESTION())
    assert(t1.get_tag(5) == TK_QUESTION_DOT())
    assert(t1.get_tag(6) == TK_QUESTION_QUESTION())
    assert(t1.get_tag(7) == TK_ARROW())
    assert(t1.get_tag(8) == TK_FAT_ARROW())
    assert(t1.get_tag(9) == TK_DOT_DOT())
    assert(t1.get_tag(10) == TK_DOT_DOT_EQ())
    assert(t1.get_tag(11) == TK_PLUS_WRAP())
    assert(t1.get_tag(12) == TK_MINUS_WRAP())
    assert(t1.get_tag(13) == TK_STAR_WRAP())
    assert(t1.get_tag(14) == TK_EOF())

    var lexer2 = Lexer.init("< | - > ? . ! $", 0)
    let t2 = lexer2.tokenize()
    assert(t2.get_tag(0) == TK_LT())
    assert(t2.get_tag(1) == TK_PIPE())
    assert(t2.get_tag(2) == TK_MINUS())
    assert(t2.get_tag(3) == TK_GT())
    assert(t2.get_tag(4) == TK_QUESTION())
    assert(t2.get_tag(5) == TK_DOT())
    assert(t2.get_tag(6) == TK_BANG())
    assert(t2.get_tag(7) == TK_INVALID())
    assert(t2.get_tag(8) == TK_EOF())

    println("ok")
