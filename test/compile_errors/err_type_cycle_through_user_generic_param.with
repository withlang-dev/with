//! expect-error: dependency loop with length 1

// #1439: a user generic holding its parameter by value (Wrap[T] { t: T }) holds E by value.
type Wrap[T] { t: T }

enum E:
    A(w: Wrap[E])
    B

fn main:
    print(1)
