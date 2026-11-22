//! expect-exit: 134
//! expect-stderr: integer overflow

// #914: parse_u128 is overflow-checked — 2^128 traps instead of wrapping.
use std.string.parse_u128

fn main:
    print(parse_u128("340282366920938463463374607431768211456"))
