//! expect-error: `(i32, f64)` cannot be a map key: it holds a `f64`
// §11.7 (D96): a float part makes a type not a key; a NaN key is never found
// again.
use std.collections.HashSet

fn main:
    var points: HashSet[(i32, f64)] = HashSet.new()
    points.insert((1, 0.5))
    print(points.len())
