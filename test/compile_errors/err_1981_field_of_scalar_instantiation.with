//! expect-error: unknown field 'v' for type 'isize'

// #1981 (§11.2: an unbounded generic relies on instantiation-time
// checking): `f(3)` instantiates `f` with `i32`, which has no field `v`.
// The access was left untyped and the program printed 0.
fn f[T](x: T) -> i32: x.v

fn main:
    print(f(3))
