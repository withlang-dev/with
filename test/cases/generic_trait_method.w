// Phase 5 gap: generic trait methods (object-safety precondition) not implemented
trait Maker =
    fn make[T](self: Self, x: T) -> T

type Id = {}

impl Maker for Id =
    fn make[T](self: Id, x: T) -> T = x

fn main() -> i32 =
    let id = Id {}
    if id.make(42) == 42 then 0 else 1
