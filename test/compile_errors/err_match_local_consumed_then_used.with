//! expect-check-fail: use of moved value

// #1302 / D144: a match on `move y` that binds a non-Copy payload by value
// consumes the local whole (§2.2: whole values decompose whole), so a later
// use is a use-after-move — not a silent read of the reset sentinel. A match
// on the bare local observes it (D144) and leaves `y` readable. A List
// payload, not a str: a str is a value and is copied (D111).
enum Tok { LBrace | S(List[Tok]) }
fn show(t: &Option[Tok]) -> i32: match t { Some(_) => 1, None => 0 }
fn main:
    var y: Option[Tok] = Some(.S([.LBrace]))
    let n = match move y { Some(.S(s)) => s.len(), _ => 0 }
    print(f"{n} {show(&y)}")
