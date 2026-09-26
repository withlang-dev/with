//! expect-check-fail: missing return

// #1494 (§4.10, D43): a value on one path and fall-off on another is a
// missing return for an unannotated function too; it was `i32.default()`.

fn f(p: bool):
    if p: return 5
    print("x")

fn main: print(f(false))
