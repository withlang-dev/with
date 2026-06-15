//! expect-check-fail: collect[BTreeSet[T]] element type must implement Ord

type Key { value: i32 }

fn main:
    let xs: Vec[Key] = Vec.new()
    xs.push(Key { value: 1 })
    let _set = xs.iter() |> collect[BTreeSet[Key]]()
