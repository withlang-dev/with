//! expect-stdout: ok

// Inherent generic impl `impl[T] Type[T]:` — methods on a generic type with no
// trait. The parser previously demanded `for` after the generic arguments (it
// assumed any `impl[..] Name[..]` was a trait impl). D7 P3 needs this: relocating
// top-level `fn Type.method(self)` into impl blocks requires it for generic types
// like `List[T]`. Associated functions (no receiver) stay at top level.

type Box[T] { val: T }

impl[T] Box[T]:
    fn get(): self.val                   // read borrow, implicit self: &Self
    mut fn set(v: T): self.val = v       // mut self
    move fn unwrap(): self.val           // move self

fn Box.make[T](v: T) -> Box[T]: Box { val: v }

fn main:
    var b = Box.make(5)
    b.set(10)
    assert(b.get() == 10)
    let c = Box.make(99)
    assert(c.unwrap() == 99)
    print("ok")
