//! expect-error: reading a union field other than the last-written field requires unsafe

type Value = union { a: i32, b: i32 }

fn main:
    var v = Value { a: 1 }
    let x = v.b
    print("x")
