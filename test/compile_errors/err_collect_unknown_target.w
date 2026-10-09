//! expect-check-fail: unsupported collect target

fn main:
    let xs: List[i32] = List.new()
    let _opt = xs.iter() |> collect[Option[i32]]()
