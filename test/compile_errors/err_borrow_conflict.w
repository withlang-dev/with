//! expect-check-fail: `&mut` is not part of safe With

// Test: &mut is rejected at P12 lockdown.

fn main:
    var x = 5
    let r1 = &x
    let r2 = &mut x
    print(int_to_string(*r1 + *r2))
