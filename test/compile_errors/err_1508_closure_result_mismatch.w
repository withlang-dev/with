//! expect-check-fail: closure return type mismatch

// D71 / §12 (#1508): a closure's `-> T` is checked like a declared return
// type — the body must produce that type. The parser dropped the annotation,
// so this compiled, ran, and printed 2.

fn main:
    let f = (x: i32) -> str => x
    let y: i32 = f(2)
    print(f"{y}")
