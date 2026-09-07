//! T10 token-identity probe: keywords, literals, string/interp edges, number bases, comment nesting.
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
    // Keywords vs idents (Lex.w:702-705 tag_from_keyword).
    var lx = Lexer.init("fn FN fnx let顾客 _x", 0)
    let k = lx.tokenize()
    assert(k.get_tag(0) == TokenKind.TK_KW_FN)
    assert(k.get_tag(1) == TokenKind.TK_IDENT)
    assert(k.get_tag(2) == TokenKind.TK_IDENT)
    assert(k.get_tag(3) == TokenKind.TK_KW_LET)
    print(tags_of("fn FN fnx let"))
    // true/false are literal tags, not idents (TK_TRUE=8, TK_FALSE=9).
    var lb = Lexer.init("true false truex", 0)
    let b = lb.tokenize()
    assert(b.get_tag(0) == TokenKind.TK_TRUE)
    assert(b.get_tag(1) == TokenKind.TK_FALSE)
    assert(b.get_tag(2) == TokenKind.TK_IDENT)
    print(tags_of("true false truex"))
    // Number bases (Lex.w:469-485): 0x/0b/0o + bad-digit resplit.
    print(tags_of("0xFF 0b1010 0o77 0xG 0b10_2 0x_FF"))
    var ln = Lexer.init("0xG", 0)
    let n = ln.tokenize()
    assert(n.get_tag(0) == TokenKind.TK_INT_LIT)
    assert(n.get_tag(1) == TokenKind.TK_IDENT)
    // Float edges: 1.5 vs range 1..10 vs 1..=10 vs exponent.
    print(tags_of("1.5 1..10 1..=10 1...10 1e10 1e+10 1E-3"))
    // String edges: plain "x" has NO interpolation (Lex.w:450); f".." is one STRING_LIT.
    print(tags_of("\"a{b}c\" f\"a{b}c\" c\"ffi\" r\"a\\nb\" r#\"x\"# b'A'"))
    var ls = Lexer.init("\"a{b}c\"", 0)
    assert(ls.tokenize().get_tag(0) == TokenKind.TK_STRING_LIT)
    // Triple-quote (Lex.w:434-448).
    print(tags_of("\"\"\"abc\"\"\""))
    // Comments: // to EOL only; /* */ is NOT a block comment (Lex.w:338-347).
    print(tags_of("// hi\nx"))
    print(tags_of("/* x */"))
    print(tags_of("// outer // inner\nx"))
    // Char/label edges (Lex.w:391-411).
    print(tags_of("'a' '\\n' '\\x41' 'name '"))
    var lc = Lexer.init("'name", 0)
    assert(lc.tokenize().get_tag(0) == TokenKind.TK_LABEL)
    print("T10-OK")
