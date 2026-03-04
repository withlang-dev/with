//! expect-stdout: ok

use Lexer
use Token

fn assert_tags(src: str, a: i32, b: i32, c: i32):
    var lexer = Lexer.init(src, 0)
    let t = lexer.tokenize()
    assert(t.len() == 3)
    assert(t.get_tag(0) == a)
    assert(t.get_tag(1) == b)
    assert(t.get_tag(2) == c)

fn main:
    // Unknown suffix stays split as int-literal then identifier.
    assert_tags("42_i33", TK_INT_LIT(), TK_IDENT(), TK_EOF())
    assert_tags("1__2_f64x", TK_INT_LIT(), TK_IDENT(), TK_EOF())

    // Prefix scans stop at invalid digit and resume with a new token.
    assert_tags("0xG", TK_INT_LIT(), TK_IDENT(), TK_EOF())
    assert_tags("0b10_2", TK_INT_LIT(), TK_INT_LIT(), TK_EOF())

    // Separator-heavy forms must tokenize deterministically.
    var l1 = Lexer.init("0x_FF", 0)
    let t1 = l1.tokenize()
    assert(t1.get_tag(0) == TK_INT_LIT())
    assert(t1.get_tag(1) == TK_EOF())

    var l2 = Lexer.init("3.14_f32", 0)
    let t2 = l2.tokenize()
    assert(t2.get_tag(0) == TK_FLOAT_LIT())
    assert(t2.get_tag(1) == TK_EOF())

    println("ok")
