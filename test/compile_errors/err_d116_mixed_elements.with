//! expect-error: `++` needs one element type

// D116 (§15.4.9): the two sequences share one element type.
fn main:
    let xs: List[i32] = [1, 2]
    let ys = ["a"]
    let z = xs ++ ys
    print(z.len())
