//! expect-check-fail: collect[String]() currently supports u8 iterator elements

fn main:
    let xs: Vec[i32] = Vec.new()
    let _text = xs.iter() |> collect[String]()
