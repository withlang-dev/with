//! expect-exit: 134
//! expect-stderr: parse_i128: value out of range for i128

// #914: 2^127 fits u128 but not i128 — parse_i128 rejects it by name.
use std.string.parse_i128

fn main:
    print(parse_i128("170141183460469231731687303715884105728"))
