//! expect-debug-alloc: leak count=0
//! expect-stdout: ABC
// #2190: collect[String]() copies the bytes out of a staging List[u8] and
// frees it.
let xs: List[u8] = [65, 66, 67]
let text: str = xs.iter() |> collect[String]()
print(text)
