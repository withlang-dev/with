//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1302: a match arm that binds a non-Copy payload BY VALUE out of a field
// place is an implicit field move (§2.2, D32) — the fix-its are `move self.cur`
// to vacate the field or `&self.cur` / `.clone()` to observe it. Non-binding
// patterns on the same place observe it and are not an error. A Vec payload,
// not a str: a str payload is copied (D111).
enum Tok { LBrace | S(Vec[i32]) }
type P { cur: Option[Tok] = Some(.LBrace) }
extend P:
    mut fn peek_len() -> i32:
        let seen = match self.cur { Some(.LBrace) => 1, _ => 0 }
        match self.cur:
            Some(.S(s)) => s.len() as i32 + seen
            _ => 0
fn main:
    var p = P {}
    print(f"{p.peek_len()}")
