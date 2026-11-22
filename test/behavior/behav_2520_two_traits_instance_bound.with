//! expect-stdout: 11 12
// #2520 (§11.4): the instance form of bound dispatch — two traits give
// X a `val`, and each bound names its own trait's body.
trait AVal:
    fn val(self: &Self) -> i32

trait BVal:
    fn val(self: &Self) -> i32

type X { v: i32 }

impl AVal for X:
    fn val(): self.v + 1

impl BVal for X:
    fn val(): self.v + 2

fn via_a[T: AVal](x: T) -> i32: x.val()
fn via_b[T: BVal](x: T) -> i32: x.val()

fn main:
    let x = X { v: 10 }
    print(f"{via_a(x)} {via_b(x)}")
