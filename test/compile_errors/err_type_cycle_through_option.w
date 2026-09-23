//! expect-error: dependency loop with length 1

// #1439: an enum holding itself through Option[E] has infinite size; the check did not follow a generic's arguments and the layout pass overflowed the stack.
enum E:
    A(o: Option[E])
    B

fn main:
    let e = E.B
    print("unreachable")
