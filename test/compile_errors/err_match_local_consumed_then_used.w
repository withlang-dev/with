//! expect-check-fail: use of moved value

// #1302: a match arm that binds a non-Copy payload by value out of a LOCAL
// consumes the local whole (§2.2: whole values decompose whole), so a later
// use is a use-after-move — not a silent read of the reset sentinel. A Vec
// payload, not a str: a str is a value and is copied (D111).
enum Tok { LBrace | S(Vec[i32]) }
fn show(t: &Option[Tok]) -> i32: match t { Some(_) => 1, None => 0 }
fn main:
    var y: Option[Tok] = Some(.S([1]))
    let n = match y { Some(.S(s)) => s.len(), _ => 0 }
    print(f"{n} {show(&y)}")
