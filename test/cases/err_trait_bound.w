//! expect-check-fail: does not implement trait

// Test: calling a generic function with a type that doesn't satisfy
// the trait bound is rejected.

trait Show:
    fn show(self) -> str

fn print_it[T: Show](x: T):
    println(x.show())

fn main:
    print_it(42)
