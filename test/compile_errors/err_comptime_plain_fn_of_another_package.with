//! expect-check-fail: cannot evaluate 'plain' at compile time: it belongs to another package (ctlib) and is not declared `comptime fn`
// A compile-time call that crosses a package boundary reaches only a
// `comptime fn`: without the marker, an edit that adds I/O to `plain`
// would break this build from inside another package.
use ctlib.math

const TWO: i32 = comptime plain(1)

fn main:
    print(f"{TWO}")
