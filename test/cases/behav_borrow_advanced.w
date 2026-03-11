//! check-only

// Behavior test: advanced borrow checker features
// Tests basic borrow checking: mutable vs shared references.
// TODO: disjoint field borrowing, drop-as-implicit-use not yet implemented.

fn takes_ref(x: &i32) -> i32:
    *x

fn main:
    var a = 10
    let v = takes_ref(&a)
    assert(v == 10)
