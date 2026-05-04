//! expect-check-fail: requires an explicit receiver mode
trait Foo =
    fn bar(self: Self) -> i32
