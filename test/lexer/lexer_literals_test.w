//! expect-stdout: ok

use Lexer
use Token

fn main:
    var lexer1 = Lexer.init("42 1_000 3.14 0xFF 0b1010 0o77 true false \"abc\" \"hello {name}\" c\"ffi\"", 0)
    let t1 = lexer1.tokenize()
    assert(t1.get_tag(0) == TK_INT_LIT())
    assert(t1.get_tag(1) == TK_INT_LIT())
    assert(t1.get_tag(2) == TK_FLOAT_LIT())
    assert(t1.get_tag(3) == TK_INT_LIT())
    assert(t1.get_tag(4) == TK_INT_LIT())
    assert(t1.get_tag(5) == TK_INT_LIT())
    assert(t1.get_tag(6) == TK_TRUE())
    assert(t1.get_tag(7) == TK_FALSE())
    assert(t1.get_tag(8) == TK_STRING_LIT())
    assert(t1.get_tag(9) == TK_STRING_LIT())
    assert(t1.get_tag(10) == TK_C_STRING_LIT())
    assert(t1.get_tag(11) == TK_EOF())

    var lexer2 = Lexer.init("1_000_000 0xFF_AA_22 0b1111_0000 3.141_592_653 r\"a\\n{b}\" r#\"x\\t{y}\"# '\\x41' b'A' b'\\x41'", 0)
    let t2 = lexer2.tokenize()
    assert(t2.get_tag(0) == TK_INT_LIT())
    assert(t2.get_tag(1) == TK_INT_LIT())
    assert(t2.get_tag(2) == TK_INT_LIT())
    assert(t2.get_tag(3) == TK_FLOAT_LIT())
    assert(t2.get_tag(4) == TK_STRING_LIT())
    assert(t2.get_tag(5) == TK_STRING_LIT())
    assert(t2.get_tag(6) == TK_CHAR_LIT())
    assert(t2.get_tag(7) == TK_CHAR_LIT())
    assert(t2.get_tag(8) == TK_CHAR_LIT())
    assert(t2.get_tag(9) == TK_EOF())

    println("ok")
