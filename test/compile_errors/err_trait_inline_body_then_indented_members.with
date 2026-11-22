//! expect-check-fail: an inline trait body is a single member

// #1346 (§29.13 Form 1): an inline body is one member and ends at the end of
// the header line. The indented `fn b` below is not part of `Foo`, exactly as
// an indented line after `fn f(): x` is not part of `f`.

trait Foo: fn a(self: &Self) -> i32
    fn b(self: &Self) -> i32

fn main:
    print("unreachable")
