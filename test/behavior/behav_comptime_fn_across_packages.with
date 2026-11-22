//! expect-stdout: 16 8 7
// A compile-time call that crosses a package boundary reaches a
// `comptime fn` (Eric, 2026-11-21). lib/ctlib is another package (it has
// its own with.toml). `cubed` reaches `helper`, which has no marker and
// needs none: it is in `cubed`'s own package. A method is a function too.
use ctlib.math

const SIXTEEN: i32 = comptime squared(4)
const EIGHT: i32 = comptime cubed(2)
const SEVEN: i32 = comptime Pair { a: 3, b: 4 }.sum()

fn main:
    print(f"{SIXTEEN} {EIGHT} {SEVEN}")
