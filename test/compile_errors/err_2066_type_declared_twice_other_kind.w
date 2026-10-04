//! expect-check-fail: type `Shape` is declared twice in this module

// #2066: every kind of type declaration takes the one name: a struct and
// an enum, an alias, an opaque type or a union of that name are the same
// collision.

type Shape { sides: i32 }
enum Shape:
    Round
    Square

fn main:
    print("unreachable")
