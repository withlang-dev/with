//! expect-stdout: 7
//! expect-stdout: 7
//! expect-stdout: hi
//! expect-stdout: ok

// #3048 (§11.6): `impl[T: Bound] Trait for T` provides `Trait` for every type
// satisfying `Bound`; a method of `Trait` called on a concrete value, or on a
// generic parameter whose bound is `Trait`, resolves to the blanket impl's
// method and monomorphizes it for that type.

trait Printable:
    fn show_it(self: &Self)

impl[T: Display] Printable for T:
    fn show_it(self: &Self):
        print(self)

fn call_bounded[T: Printable](v: &T):
    v.show_it()

fn main:
    call_bounded(&7)
    7.show_it()
    "hi".show_it()
    print("ok")
