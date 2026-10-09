//! expect-check-fail: collect[String]() currently supports u8 iterator elements

fn main:
    let xs: List[i32] = List.new()
    let _text = xs.iter() |> collect[String]()
