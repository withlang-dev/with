//! expect-stdout: ok

use Lexer
use Token

fn main:
    var lexer1 = Lexer.init("fn let with match for if else return break continue async await unsafe type trait impl use module pub extend var comptime gen in as mut then loop while ephemeral spawn defer error extern", 0)
    let tokens1 = lexer1.tokenize()
    assert(tokens1.get_tag(0) == TK_KW_FN())
    assert(tokens1.get_tag(1) == TK_KW_LET())
    assert(tokens1.get_tag(2) == TK_KW_WITH())
    assert(tokens1.get_tag(3) == TK_KW_MATCH())
    assert(tokens1.get_tag(tokens1.len() - 2) == TK_KW_EXTERN())
    assert(tokens1.get_tag(tokens1.len() - 1) == TK_EOF())

    var lexer2 = Lexer.init("fnx lett withhold matcher", 0)
    let tokens2 = lexer2.tokenize()
    assert(tokens2.get_tag(0) == TK_IDENT())
    assert(tokens2.get_tag(1) == TK_IDENT())
    assert(tokens2.get_tag(2) == TK_IDENT())
    assert(tokens2.get_tag(3) == TK_IDENT())
    assert(tokens2.get_tag(4) == TK_EOF())

    println("ok")
