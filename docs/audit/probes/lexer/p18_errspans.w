//! T18 lexer-error-span probe: every lex error — correct span? correct error?
use Lexer
use Token

fn tags_of(src: str) -> str:
    var lx = Lexer.init(src, 0)
    let t = lx.tokenize()
    var out = f"n={t.len()}:"
    for i in 0..t.len():
        out = out ++ f" {t.get_tag(i)}[{t.get_start(i)},{t.get_end(i)})"
    out

fn main:
    // Unknown char (Lex.w:413-415): single-char INVALID span.
    print(tags_of("$"))
    var l1 = Lexer.init("$", 0)
    let t1 = l1.tokenize()
    assert(t1.get_tag(0) == TokenKind.TK_INVALID)
    assert(t1.get_start(0) == 0)
    assert(t1.get_end(0) == 1)
    // Lone quote (Lex.w:391+411): INVALID, span [0,1).
    print(tags_of("'"))
    // Bad hex escape in char literal (Lex.w:394-401 falls through to INVALID).
    print(tags_of("'\\x4'"))
    var l2 = Lexer.init("'\\x4'", 0)
    assert(l2.tokenize().get_tag(0) == TokenKind.TK_INVALID)
    // Unterminated regex: newline -> INVALID (Lex.w:746-747); EOF -> INVALID (749).
    print(tags_of("/abc\n"))
    print(tags_of("= /abc"))
    // Lone $ capture / bad capture char (Lex.w:707-719).
    print(tags_of("$ $1 $x $-"))
    var l3 = Lexer.init("$-", 0)
    assert(l3.tokenize().get_tag(0) == TokenKind.TK_INVALID)
    // Backtick is unknown char -> INVALID.
    print(tags_of("`"))
    // Stray quote-label "' " paths.
    print(tags_of("' 1"))
    print("T18-OK")
