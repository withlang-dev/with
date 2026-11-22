//! expect-check-fail: is not object-safe: method 'id' is generic
// §11: a trait with a generic method is not object-safe (cannot be used as dyn).
trait Container:
    fn id[T](self: &Self, value: T) -> T
type Bag { n: i32 }
impl Container for Bag:
    fn id[T](self: &Self, value: T) -> T: value
fn use_dyn(c: &dyn Container) -> i32: 1
fn main:
    let b = Bag { n: 0 }
    print_i32(use_dyn(&b))
