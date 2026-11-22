//! expect-stdout: 16
//! expect-stdout: 3
//! expect-stdout: 2

// #1653: a header's array constant (uuid.h's UUID_NULL) translates to a With
// array literal `[…]`, not `[16]u8 { … }`.
use c_import("behav_c_import_array_constant.h")
fn main:
    print(CI_UUID_NULL.len())
    print(CI_TRIPLE.len())
    print(CI_TRIPLE[1])
