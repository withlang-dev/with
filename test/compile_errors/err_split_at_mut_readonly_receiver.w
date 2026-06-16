//! expect-check-fail: split_at_mut() requires a mutable place receiver

fn main:
    let _parts = [1, 2, 3].split_at_mut(1)
