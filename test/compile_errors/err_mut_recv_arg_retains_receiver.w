//! expect-check-fail: argument retains access to the mutable receiver

// §3.2 — a mut self receiver is exclusive for the duration of the call;
// a reference to the receiver may not be a sibling argument.

type Acc { buf: str, n: i32 }

fn Acc.add(mut self: Self, other: &Acc) -> i32:
    self.n = self.n + 1
    other.n

fn main:
    var a = Acc { buf: "x", n: 0 }
    let r = a.add(&a)
    print(f"{r}")
