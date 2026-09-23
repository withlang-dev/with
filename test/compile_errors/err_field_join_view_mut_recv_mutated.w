//! expect-check-fail: while `x` is a live view into it

// #1408: the `mut fn` receiver form — the joined view's origin is `self`.
type P { p: str, q: str }

impl P:
    mut fn f(c: bool):
        let x = if c: self.p else: self.q
        self.p = "z".clone()
        print(x)

fn main:
    var s = P { p: "a" ++ "", q: "b" ++ "" }
    s.f(true)
