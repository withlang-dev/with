//! expect-check-fail: the keyword decides the receiver (D7)
// #897: a written receiver whose mode is not the method keyword's is refused;
// `mut fn` with `move self` would leave which receiver the method takes
// ambiguous.
type P { n: i32 }

impl P:
    mut fn bump(move self): self.n = self.n + 1

fn main:
    var p = P { n: 1 }
    p.bump()
