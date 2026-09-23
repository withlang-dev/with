//! expect-error: this slice pattern never matches: it matches exactly 2 elements, and the array has 3

// #1367 (§9.7): `[a, b, c]` matches exactly 3 elements. A slice pattern
// whose length cannot match the fixed array is a compile error, not a
// demand for an else branch.
fn main:
    let arr = [1, 2, 3]
    let [a, b] = arr
    print(f"{a} {b}")
