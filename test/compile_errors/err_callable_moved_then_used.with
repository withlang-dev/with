//! expect-check-fail: use of moved value

// D63 (§12.4): `fn(A) -> R` is not Copy, bare functions included —
// `let g = f` moves `f`. Calling through a binding observes it.
fn shout(s: &str) -> str: s.clone() ++ "!"

fn main:
    let f = shout
    let g = f
    print(g("a"))
    print(f("b"))
