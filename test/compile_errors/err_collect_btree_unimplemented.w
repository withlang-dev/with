//! expect-check-fail: collect[BTreeSet] requires BTree collections, which are not implemented yet (#414)

fn main:
    let xs: Vec[i32] = Vec.new()
    let _set = xs.iter() |> collect[BTreeSet[i32]]()
