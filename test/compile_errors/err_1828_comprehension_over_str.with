//! expect-error: cannot iterate over `str`: a `for` iterable implements `Iter[T]`

// #1828 (§13.5, §13.6): a comprehension clause iterates the same way a
// `for` loop does; over a `str` it passed check and failed MIR lowering.
fn main:
    let s = "ab" ++ "cd"
    let v = [c for c in s]
    print(f"{v.len()}")
