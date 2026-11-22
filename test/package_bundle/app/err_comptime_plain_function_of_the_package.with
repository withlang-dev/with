//! expect-error: cannot evaluate 'tripled' at compile time: it belongs to another package (shapes) and is not declared `comptime fn`

// D227: a compile-time call across a package boundary reaches only a
// `comptime fn`. The refusal reads the same against the package's source
// and against its bundle.
use shapes

const NINE: i32 = comptime tripled(3)

fn main:
    print(f"{NINE}")
