//! expect-error: a tuple pattern can contain only one '..'

// #1366 (§9.7): one `..` per tuple pattern; two leave the split ambiguous.
fn main:
    let (a, .., b, .., c) = (1, 2, 3, 4, 5)
    print(f"{a} {b} {c}")
