//! expect-stdout: 3
//! expect-stdout: 7

// #1857 (§12 callable values): a generic function named where a
// `fn(i32) -> i32` is expected is instantiated at that type; Sema types the
// name as the expected callable and records the instantiation (D65), so MIR
// never sees a Unit argument.

fn identity[T](x: T) -> T: x
fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main:
    print(f"{apply(identity, 3)}")
    let g: fn(i32) -> i32 = identity
    print(f"{g(7)}")
