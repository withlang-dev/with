//! expect-check-fail: collect[HashMap[K, V]] requires iterator elements of type (K, V)
use std.collections.HashMap

fn main:
    let xs: List[i32] = List.new()
    let _map = xs.iter() |> collect[HashMap[i32, i32]]()
