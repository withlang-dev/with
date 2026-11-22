//! expect-stdout: 8
//! expect-stdout: 8
//! expect-stdout: 3

// §11: a method's own type parameters join its impl's. `impl[T] Box[T]:
// fn conv[U](f: fn(&T) -> U)` names both; validated against its own
// alone, every use of the impl's `T` in its signature was "unknown type
// 'T'".
type Box[T] { v: T }

impl[T] Box[T]:
    fn observe[U](f: fn(&T) -> U) -> U: f(self.v)
    fn take[U](f: fn(T) -> U) -> U: f(self.v)
    fn pick[U](u: U, t: &T) -> U: u

fn main:
    let b: Box[i32] = Box { v: 7 }
    print(b.observe((x) => *x + 1))
    print(b.take((x) => x + 1))
    print(b.pick(3, 4))
