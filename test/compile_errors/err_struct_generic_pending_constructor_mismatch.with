//! expect-check-fail: field type mismatch for 'b'

use std.collections.HashSet
type Pair[T] { a: T, b: T }

fn main:
    let v: List[i64] = List.new()
    let _w = Pair { a: v, b: HashSet.new() }
