//! expect-check-fail: expected right brace
// §29.13.1.24: `fn f: { x: 1, y: 2 }` — a bare `{ ... }` is NOT a meaningful
// expression in With (there are no anonymous record literals), so the
// colon-then-brace form is a parse error here.
type P { x: i32, y: i32 }

fn make() -> P: { x: 1, y: 2 }

fn main:
    let _p = make()
