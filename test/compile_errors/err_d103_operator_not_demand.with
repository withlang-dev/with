//! expect-check-fail: comparison operands must have compatible types

// §4.9a (D103): an operator's operands are not demand sites. The left
// operand's type reaches the right one as a hint, never as a demand, so
// `3` is not `Some(3)` here and the comparison stays an error.
fn main:
    let o: Option[i32] = Some(3)
    print(o == 3)
