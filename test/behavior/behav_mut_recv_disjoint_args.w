//! expect-stdout: ok

// §3.2 receiver exclusivity rejects arguments that retain access to the
// receiver — but disjoint sources stay legal: another binding's fields,
// pre-bound locals, and Copy scalar fields of the receiver itself (a
// scalar is copied before the call begins; nothing is retained).
//
// `add` consumes its `piece: str`, so a field fed to it is an owned value:
// a field never moves out implicitly (§2.2, D32) and an unannotated
// `let piece = a.buf` binds a view (§3.8, D22), so both are spelled
// `.clone()` — the independent value the consuming parameter takes.

type Acc { buf: str, n: i32 }

fn Acc.add(mut self: Self, piece: str) -> i32:
    self.n = self.n + 1
    piece.len() as i32

fn Acc.bump(mut self: Self, by: i32) -> i32:
    self.n = self.n + by
    self.n

fn main:
    var a = Acc { buf: "abc", n: 0 }
    let b = Acc { buf: "wxyz", n: 7 }

    // Sibling binding's field: disjoint; cloned because `add` consumes.
    let r1 = a.add(b.buf.clone())
    assert(r1 == 4)

    // An owned copy of the receiver's own field: nothing of `a` is retained
    // across the call.
    let piece = a.buf.clone()
    let r2 = a.add(piece)
    assert(r2 == 3)

    // Copy scalar field of the receiver: copied before the call.
    let r3 = a.bump(a.n)
    assert(r3 == 4)

    assert(a.n == 4)
    print("ok")
