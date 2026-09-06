//! T23 silent-recovery probe: malformed input that lexes to wrong-but-accepted stream?
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
    // Unterminated regular string -> STRING_LIT, swallows rest of file (Lex.w:459-460).
    print(tags_of("\"unterminated"))
    // Unterminated raw string -> STRING_LIT (Lex.w:781-782).
    print(tags_of("r#\"unterminated"))
    // Unterminated triple-quote: Lex.w:440 loop `while pos+2 < slen` MISSES a
    // closing """ ending exactly at EOF; falls to recovery STRING_LIT (447-448).
    print(tags_of("\"\"\"unterminated"))
    print(tags_of("\"\"\"abc\"\"\""))
    // Unterminated f-string -> STRING_LIT (Lex.w:694).
    print(tags_of("f\"abc{def"))
    // Bad escape "q" accepted silently as STRING_LIT (no escape validation).
    print(tags_of("\"\\q\""))
    // Negative controls: these MUST stay INVALID (not silently accepted).
    var l1 = Lexer.init("$-", 0)
    assert(l1.tokenize().get_tag(0) == TokenKind.TK_INVALID)
    var l2 = Lexer.init("'\\x4'", 0)
    assert(l2.tokenize().get_tag(0) == TokenKind.TK_INVALID)
    print("T23-OK")
