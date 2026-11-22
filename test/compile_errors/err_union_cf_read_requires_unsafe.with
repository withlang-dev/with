//! expect-error: reading a union field other than the last-written field requires unsafe

// After control flow writes different fields on different paths, the
// last-written field is unknown, so a safe read is rejected.

type Value = union { a: i32, b: i32 }

fn pick(cond: bool) -> i32:
    var v = Value { a: 1 }
    if cond:
        v.a = 2
    else:
        v.b = 3
    v.a

fn main:
    let _ = pick(true)
    print("x")
