//! expect-stdout: ABC
// #2190: collect[String]() copies the bytes out of a staging Vec[u8] and
// frees it.
let xs: Vec[u8] = [65, 66, 67]
let text: str = xs.iter() |> collect[String]()
print(text)
