//! expect-check-fail: method 'Vec.split_at_mut' requires a mutable receiver

// A read-only view of a Vec cannot be split into mutable halves.
fn halves(xs: &Vec[i32]):
    let _parts = xs.split_at_mut(1)

fn main:
    halves([1, 2, 3])
