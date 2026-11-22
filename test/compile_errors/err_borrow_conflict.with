//! expect-check-fail: `&mut` is not part of safe With (§3.1)

// Test: &mut is rejected at P12 lockdown.

use std.builtins.int_to_string
fn main:
    var x = 5
    let r1 = &x
    let r2 = &mut x
    print(int_to_string(*r1 + *r2))
