//! expect-check-fail: unsupported collect target

fn main:
    let xs: Vec[i32] = Vec.new()
    let _opt = xs.iter() |> collect[Option[i32]]()
