//! expect-check-fail: an argument retains access to the `mut` receiver `a` when the call begins (§3.2)

// §3.2 — a str value read from the mutable receiver's fields shares the
// underlying buffer (shallow Copy) and so retains access during the call.

type Acc { buf: str, n: i32 }

fn Acc.add(mut self: Self, piece: str) -> i32:
    self.n = self.n + 1
    piece.len() as i32

fn main:
    var a = Acc { buf: "xyz", n: 0 }
    let r = a.add(a.buf)
    print(f"{r}")
