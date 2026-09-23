//! expect-error: this slice pattern never matches: it matches at least 4 elements, and the array has 3

// #1367 (§9.7): `[a, b, ..rest, z]` needs room for both ends; against a
// shorter fixed array it can never match, with or without an else.
fn main:
    let arr = [1, 2, 3]
    let [a, b, c, .., d] = arr else: return
    print(f"{a} {b} {c} {d}")
