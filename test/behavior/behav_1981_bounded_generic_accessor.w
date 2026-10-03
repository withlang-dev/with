//! expect-stdout: 5 9
// #1981: a field access in a generic body is checked per instantiation
// (§11.2); a bounded `T` whose trait provides the value still works, and an
// instantiation whose type has the field reads it.
trait HasV:
    fn v(self: &Self) -> i32

type A { x: i32 }
impl HasV for A:
    fn v(self: &Self) -> i32: self.x

type B { v: i32 }

fn via_bound[T: HasV](t: &T) -> i32: t.v()
fn via_field[T](t: &T) -> i32: t.v

fn main:
    let a = A { x: 5 }
    let b = B { v: 9 }
    print(f"{via_bound(&a)} {via_field(&b)}")
