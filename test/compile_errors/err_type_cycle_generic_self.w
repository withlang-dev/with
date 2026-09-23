//! expect-error: dependency loop with length 1

// #1439: a generic enum holding itself through Option is infinite even before it is instantiated.
enum Bad[T]:
    A(o: Option[Bad[T]])
    B

fn main:
    print(1)
