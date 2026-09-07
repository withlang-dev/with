// Control: same as t13_impl_for_type.w but WITHOUT `for Foo`. If the
// diagnostic is identical, the `for Foo` target is silently discarded.
trait Show:
    fn show(x: i32) -> i32

fn takes(x: impl Show) -> i32:
    0

fn main:
    assert(takes(0) == 0)
