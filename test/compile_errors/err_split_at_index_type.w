//! expect-check-fail: wrong argument type in call to 'Vec.split_at'

fn main:
    let xs = [1, 2, 3]
    let _parts = xs.split_at("middle")
