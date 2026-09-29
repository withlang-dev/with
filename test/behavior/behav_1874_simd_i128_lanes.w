//! expect-stdout: i128 170141183460469231731687303715884105727 3 -1 5
//! expect-stdout: u128 340282366920938463463374607431768211455 4 3 32

// §4.3d (D78, #1874): T is any primitive integer (§4.1), i128 and u128
// included: construction, lanes, arithmetic, bitwise, reductions and
// `.bits()` work on 128-bit lanes.
fn main:
    let a = Vector[2, i128](170141183460469231731687303715884105726, 1)
    let b = Vector[2, i128](1, 2)
    let s = a + b
    let n = -b
    let t = Vector[2, i128](2, 3)
    print(f"i128 {s[0]} {s[1]} {(n & Vector[2, i128](-1, -1))[0]} {t.reduce_add()}")
    let u = Vector[2, u128](340282366920938463463374607431768211455, 4)
    let bits: Vector[2, u128] = s.bits()
    print(f"u128 {u[0]} {u[1]} {bits[1]} {size_of[Vector[2, i128]]()}")
