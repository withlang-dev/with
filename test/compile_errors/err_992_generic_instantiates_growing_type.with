//! expect-check-fail: recursive generic instantiation: `grow` is instantiated 64 deep
// #992: a generic that calls itself at a type that grows each time has no
// last instance. Each instance's body check nested inside the last until
// the compiler's stack ran out: SIGSEGV, no output.
fn grow[T](x: T) -> i32: grow(Some(x))

fn main:
    print(grow(1))
