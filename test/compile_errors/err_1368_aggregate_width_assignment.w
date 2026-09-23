//! expect-error: type mismatch in assignment: the place is `(i64, i64)` but the value is `(i32, i32)`

// #1368: assignment of a tuple with narrower elements was invalid MIR.
fn pair -> (i32, i32): (3, 4)
fn main:
    var w: (i64, i64) = (0, 0)
    w = pair()
    print(f"{w.0}")
