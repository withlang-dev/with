//! expect-check-fail: collect[HashMap[K, V]] requires iterator elements of type (K, V)

fn main:
    let xs: Vec[i32] = Vec.new()
    let _map = xs.iter() |> collect[HashMap[i32, i32]]()
