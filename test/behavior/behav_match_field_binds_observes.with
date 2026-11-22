//! expect-stdout: 2

// #1302, then D144: a match arm that binds a non-Copy payload out of a
// field place observes it (the binding is a view of the payload's place);
// nothing moves out of the field and the field stays whole afterwards.
// Before D144 this was the D32 implicit-field-move error. A List payload,
// not a str: a str payload is copied (D111).
enum Tok { LBrace | S(List[Tok]) }
type P { cur: Option[Tok] = Some(.S([.LBrace, .LBrace])) }
extend P:
    mut fn peek_len() -> i32:
        let seen = match self.cur { Some(.LBrace) => 1, _ => 0 }
        match self.cur:
            Some(.S(s)) => s.len() as i32 + seen
            _ => 0
fn main:
    var p = P {}
    let n = p.peek_len()
    print(f"{n + p.peek_len() - n}")
