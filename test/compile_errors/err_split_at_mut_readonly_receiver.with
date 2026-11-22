//! expect-check-fail: method 'List.split_at_mut' requires a mutable receiver

// A read-only view of a List cannot be split into mutable halves.
fn halves(xs: &List[i32]):
    let _parts = xs.split_at_mut(1)

fn main:
    halves([1, 2, 3])
