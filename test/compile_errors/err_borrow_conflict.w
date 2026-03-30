//! expect-check-fail: cannot borrow mutably: already borrowed

// Test: borrow checker detects conflict between shared and mutable borrow.

fn main:
    var x = 5
    let r1 = &x
    let r2 = &mut x
    print(int_to_string(*r1 + *r2))
