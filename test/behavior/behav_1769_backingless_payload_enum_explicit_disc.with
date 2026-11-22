//! expect-stdout: 5
//! expect-stdout: 6
//! expect-stdout: 9

// #1769 (§4.4a): an explicit `= N` on a backing-less enum with a payload
// variant makes it a discriminant enum in the inferred i32 (as a fieldless
// one is, #309, and an @[flags] one, #1482). The parser parsed the `= N`
// and emitted the plain-enum extras, which have no slot for it: the tag
// was the variant index (0), silently.

enum M:
    A = 5
    B(i32)
    C(str) = 9

fn mt(m: M) -> i32: m as i32

fn main:
    print(mt(M.A))
    print(mt(M.B(1)))
    print(M.C("x") as i32)
