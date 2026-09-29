//! expect-stdout: i128 9223372036854775807 3 -1 5 true false true
//! expect-stdout: u128 true 4 3 32

// §4.3d (D78/D80, #1874): T is any primitive integer (§4.1), i128 and u128
// included: construction, lanes, arithmetic, bitwise, reductions,
// `.bits()` and comparisons (W = 128) work on 128-bit lanes. (A value
// beyond 64 bits is checked through `>> 64` and `==`: formatting a 128-bit
// integer is not implemented for scalars either.)
fn main:
    let a = Vector[2, i128](170141183460469231731687303715884105726, 1)
    let b = Vector[2, i128](1, 2)
    let s = a + b
    let n = -b
    let t = Vector[2, i128](2, 3)
    let lt = s < Vector[2, i128](170141183460469231731687303715884105727, 3)
    let top = (s[0] >> 64) as i64
    print(f"i128 {top} {s[1]} {(n & Vector[2, i128](-1, -1))[0]} {t.reduce_add()} {(s == s).all()} {lt.any()} {s[0] == 170141183460469231731687303715884105727}")
    let u = Vector[2, u128](340282366920938463463374607431768211455, 4)
    let bits: Vector[2, u128] = s.bits()
    print(f"u128 {u[0] == 340282366920938463463374607431768211455} {u[1]} {bits[1]} {size_of[Vector[2, i128]]()}")
