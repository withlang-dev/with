//! expect-error: the count is not a compile-time constant

// #1478 (§4.3a): the count of `[value; N]` is an integer literal or a
// `const`; a runtime value is refused by name, never one silent copy.
fn main:
    let n = 4
    let a = [0; n]
    print(f"{a.len()}")
