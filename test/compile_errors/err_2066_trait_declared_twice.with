//! expect-check-fail: trait `Named` is declared twice in this module

// #2066: a trait name is declared once per module, like a type name.

trait Named:
    fn name(self: &Self) -> str
trait Named:
    fn label(self: &Self) -> str

fn main:
    print("unreachable")
