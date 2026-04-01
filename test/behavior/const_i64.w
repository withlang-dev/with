//! expect-stdout: 42
//! expect-stdout: ok

const SMALL_I64: i64 = 42
const BIG_I64: i64 = 4294967296

fn takes_i64(n: i64) -> i64:
    n

fn main:
    let x: i64 = SMALL_I64
    print(int_to_string(takes_i64(x)))
    assert(BIG_I64 > 0)
    print("ok")
