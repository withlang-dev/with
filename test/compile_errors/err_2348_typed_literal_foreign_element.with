//! expect-error: sequence literal element is `str` where `i32` is demanded

// #2348 (§4.3c): a literal typed by a demand still has to hold the
// demanded element; `["a"]` is not a `List[i32]`.
fn take(xs: List[i32]) -> isize: xs.len()
fn main:
    let a: List[i32] = ["a"]
    print(take(a))
