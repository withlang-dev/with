//! expect-error: array literal has 2 elements, but `[4]i32` holds 4

// #1478 (§4.3a): a fixed-size destination has the literal's length; typing
// the literal as the annotation regardless read uninitialized elements.
fn main:
    let b: [4]i32 = [1, 2]
    print(f"{b[3]}")
