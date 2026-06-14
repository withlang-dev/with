//! expect-error: slice rest binding for dynamic slices is not implemented yet

fn main:
    let arr = [1, 2, 3]
    let view = arr[0..3]
    let [first, ..rest] = view else return
    let _x = first
