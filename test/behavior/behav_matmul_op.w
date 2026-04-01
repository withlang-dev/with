//! expect-stdout: ok

type Mat2 { a: i32, b: i32, c: i32, d: i32 }

impl Mat2:
    fn matmul(self: Mat2, rhs: Mat2) -> Mat2:
        Mat2 {
            a: self.a * rhs.a + self.b * rhs.c,
            b: self.a * rhs.b + self.b * rhs.d,
            c: self.c * rhs.a + self.d * rhs.c,
            d: self.c * rhs.b + self.d * rhs.d,
        }

fn main:
    let identity = Mat2 { a: 1, b: 0, c: 0, d: 1 }
    let m = Mat2 { a: 1, b: 2, c: 3, d: 4 }
    // identity @ m should equal m
    let result = identity @ m
    assert(result.a == 1)
    assert(result.b == 2)
    assert(result.c == 3)
    assert(result.d == 4)
    // m @ identity should also equal m
    let result2 = m @ identity
    assert(result2.a == 1)
    assert(result2.b == 2)
    // chained: (m @ identity) @ identity == m
    let result3 = m @ identity @ identity
    assert(result3.a == 1)
    assert(result3.d == 4)
    print("ok")
