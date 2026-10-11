//! expect-stdout: 1 1 -1

// §4.2.1 rule 2 (D114): an untyped literal argument takes its parameter's
// type in a generic call too, where the arguments are checked before the
// parameters are known; `1` for an `i32` parameter is not an `isize`.
fn reg[T](name: str, n: i32, data: T) -> i32: n

type Holder { v: i32 }

impl Holder:
    fn add[T](name: str, n: i32, data: T) -> i32: n + self.v

fn main:
    let h = Holder { v: -2 }
    print(f"{reg("x", 1, 5)} {reg("y", 1, true)} {h.add("z", 1, 'c')}")
