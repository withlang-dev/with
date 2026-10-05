//! expect-check-fail: the annotation names `Vec` and the value is `i32`

// #2144: a bare generic annotation still names a type the value must have.
fn main:
    let xs: Vec = 3
    print(xs)
