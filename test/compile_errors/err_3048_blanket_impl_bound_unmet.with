//! expect-check-fail: unknown method 'show_it' for type 'Opaque'

// #3048 (§11.6): `impl[T: Display] Printable for T` provides `show_it` only
// to types satisfying `Display`; a type without it has no such method.

trait Printable:
    fn show_it(self: &Self)

impl[T: Display] Printable for T:
    fn show_it(self: &Self):
        print(self)

type Opaque { value: i32 }

fn main:
    let o = Opaque { value: 1 }
    o.show_it()
