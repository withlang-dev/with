use std.builtins.print_i64

const C64_ADD: i64 = 9223372036854775807i64 + 1i64
const C64_NEG: i64 = -(-9223372036854775807i64 - 1i64)
const C64_DIV: i64 = (-9223372036854775807i64 - 1i64) / -1i64

fn main:
    print_i64(C64_ADD)
    print_i64(C64_NEG)
    print_i64(C64_DIV)
