//! expect-error: comparison operands must have the same tuple type: `(i8, i64)` and `(i32, i32)`

// #1996: two typed tuples of different element types do not compare;
// §4.2.6 converts no typed value implicitly. Sema accepted the pair and
// left MIR validation to refuse it.

fn main:
    let a: (i8, i64) = (1, 2)
    let b: (i32, i32) = (1, 2)
    print(f"{a == b}")
