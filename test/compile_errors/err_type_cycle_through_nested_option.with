//! expect-error: dependency loop with length 1

// #1439: Option[Option[E]] holds E by value through both layers.
enum E:
    A(o: Option[Option[E]])
    B

fn main:
    print(1)
