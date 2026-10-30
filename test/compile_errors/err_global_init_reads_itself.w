//! expect-error: the initializer of global `a` reads its own value
// A global's initializer runs before the global has a value.
let a: i64 = a + 1

fn main:
    print(f"{a}")
