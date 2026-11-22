//! expect-error: name the trait: `AVal.val(…)` or `BVal.val(…)`
// #2520 (§11.4): a bare method call with two applicable trait
// implementations is ambiguous; the programmer names the trait
// (`AVal.val(x)`, D169). Before trait identity the second impl silently
// displaced the first under one fn symbol.
trait AVal:
    fn val(self: &Self) -> i32

trait BVal:
    fn val(self: &Self) -> i32

type X { v: i32 }

impl AVal for X:
    fn val(): self.v + 1

impl BVal for X:
    fn val(): self.v + 2

fn main:
    let x = X { v: 1 }
    print(x.val())
