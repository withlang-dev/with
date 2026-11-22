//! expect-check-fail: cannot evaluate 'plain' at compile time: it belongs to another package (ctlib) and is not declared `comptime fn`; reached through mine
// The rule is transitive: `mine` is this package's and needs no marker, but
// the call it makes crosses the boundary. The error names the chain.
use ctlib.math

fn mine(n: i32) -> i32: plain(n) * 2

const FOUR: i32 = comptime mine(1)

fn main:
    print(f"{FOUR}")
