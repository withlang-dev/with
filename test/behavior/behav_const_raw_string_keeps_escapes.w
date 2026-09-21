//! expect-stdout: ok

// #1246: `const` desugars to a comptime-wrapped let. The evaluator decoded
// the literal (a raw literal keeps its bytes), then re-emitted the value as
// a plain string literal, and codegen decoded the escapes a second time:
// `r#"a\"b\n"#` came out as `a"b` + newline. The re-emitted literal now
// carries the raw marker — decoded bytes are taken as written.

const C: str = r#"a\"b\n"#
let L: str = r#"a\"b\n"#
const D: str = "a\"b"

fn main:
    // six bytes: a \ " b \ n — the backslashes survive, no newline
    assert(C.len() == 6)
    assert(C == L)
    assert(C[1] == '\\' and C[2] == '"' and C[4] == '\\' and C[5] == 'n')
    // an ordinary const literal is decoded exactly once
    assert(D.len() == 3 and D[1] == '"')
    let rendered = f"[{C}] [{D}]"
    print(if rendered.len() == 14: "ok" else: "bad")
