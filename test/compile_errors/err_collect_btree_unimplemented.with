//! expect-check-fail: collect[BTreeSet[T]] element type must implement Ord
use std.collections.BTreeSet

type Key { value: i32 }

fn main:
    let xs: List[Key] = List.new()
    xs.push(Key { value: 1 })
    let _set = xs.iter() |> map(key => Key { value: key.value }) |> collect[BTreeSet[Key]]()
