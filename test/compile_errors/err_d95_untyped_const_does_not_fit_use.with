//! expect-error: constant `BIG` does not fit `i32`
// §4.2.1 (D95, #2101): an untyped constant that a use's type cannot hold is
// an error at that use, never at the declaration.
pub const BIG = 5_000_000_000

fn narrow(n: i32): n

fn main:
    let fine: i64 = BIG
    print(narrow(BIG))
