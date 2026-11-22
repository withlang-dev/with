//! expect-stdout: 1 2 3 4 5 0
//! expect-stdout: 7 8 9 0
//! expect-stdout: 3 0
//! expect-stdout: 1 1 2

// #1295: a char or byte literal is an integer literal value (§22), so it is
// a `LITERAL_PAT` (§29) exactly like `123 =>` — bare, as a range endpoint,
// and inside a constructor pattern.

fn kind(ch: u8) -> i32:
    match ch:
        '{' => 1
        b'"' => 2
        '\n' => 3
        b'\t' => 4
        '\'' => 5
        _ => 0

fn class(ch: u8) -> i32:
    match ch:
        'a'..='z' => 7
        'A'..='Z' => 8
        b'0'..=b'9' => 9
        _ => 0

fn opt(ch: Option[u8]) -> i32:
    match ch:
        Some(b'{') => 1
        Some('}') => 2
        Some(_) => 3
        None => 0

fn main:
    print(f"{kind(b'{')} {kind(b'\"')} {kind(10)} {kind(9)} {kind(39)} {kind(b'x')}")
    print(f"{class(b'q')} {class(b'Q')} {class(b'5')} {class(b'-')}")
    let byte_val: u8 = 65
    print(f"{opt(Some(byte_val))} {opt(None)}")
    let cur: u8 = 123
    print(f"{kind(cur)} {opt(Some(cur))} {opt(Some(125))}")
