//! expect-stdout: ok

use Lexer
use Token

fn main:
    var lexer1 = Lexer.init("42 1_000 3.14 0xFF 0b1010 0o77 true false \"abc\" \"hello {name}\" c\"ffi\"", 0)
    let t1 = lexer1.tokenize()
    assert(t1.get_tag(0) == TokenKind.TK_INT_LIT)
    assert(t1.get_tag(1) == TokenKind.TK_INT_LIT)
    assert(t1.get_tag(2) == TokenKind.TK_FLOAT_LIT)
    assert(t1.get_tag(3) == TokenKind.TK_INT_LIT)
    assert(t1.get_tag(4) == TokenKind.TK_INT_LIT)
    assert(t1.get_tag(5) == TokenKind.TK_INT_LIT)
    assert(t1.get_tag(6) == TokenKind.TK_TRUE)
    assert(t1.get_tag(7) == TokenKind.TK_FALSE)
    assert(t1.get_tag(8) == TokenKind.TK_STRING_LIT)
    assert(t1.get_tag(9) == TokenKind.TK_STRING_LIT)
    assert(t1.get_tag(10) == TokenKind.TK_C_STRING_LIT)
    assert(t1.get_tag(11) == TokenKind.TK_EOF)

    var lexer2 = Lexer.init("1_000_000 0xFF_AA_22 0b1111_0000 3.141_592_653 r\"a\\n{b}\" r#\"x\\t{y}\"# '\\x41' b'A' b'\\x41'", 0)
    let t2 = lexer2.tokenize()
    assert(t2.get_tag(0) == TokenKind.TK_INT_LIT)
    assert(t2.get_tag(1) == TokenKind.TK_INT_LIT)
    assert(t2.get_tag(2) == TokenKind.TK_INT_LIT)
    assert(t2.get_tag(3) == TokenKind.TK_FLOAT_LIT)
    assert(t2.get_tag(4) == TokenKind.TK_STRING_LIT)
    assert(t2.get_tag(5) == TokenKind.TK_STRING_LIT)
    assert(t2.get_tag(6) == TokenKind.TK_CHAR_LIT)
    assert(t2.get_tag(7) == TokenKind.TK_CHAR_LIT)
    assert(t2.get_tag(8) == TokenKind.TK_CHAR_LIT)
    assert(t2.get_tag(9) == TokenKind.TK_EOF)

    var lexer3 = Lexer.init("'a' '@' '\\n' b'X' b'\\n' 'outer \"apostrophe ' inside\"", 0)
    let t3 = lexer3.tokenize()
    assert(t3.get_tag(0) == TokenKind.TK_CHAR_LIT)
    assert(t3.get_tag(1) == TokenKind.TK_CHAR_LIT)
    assert(t3.get_tag(2) == TokenKind.TK_CHAR_LIT)
    assert(t3.get_tag(3) == TokenKind.TK_CHAR_LIT)
    assert(t3.get_tag(4) == TokenKind.TK_CHAR_LIT)
    assert(t3.get_tag(5) == TokenKind.TK_LABEL)
    assert(t3.get_tag(6) == TokenKind.TK_STRING_LIT)
    assert(t3.get_tag(7) == TokenKind.TK_EOF)

    print("ok")
