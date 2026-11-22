//! expect-stdout: true
//! expect-stdout: true
//! expect-stdout: true
//! expect-stdout: false
//! expect-stdout: true
//! expect-stdout: true
//! expect-stdout: true
//! expect-stdout: true
//! expect-stdout: 1

// #3483 (D110): `str.contains`, `starts_with` and `ends_with` are declared
// in the standard library; the compiler has no built-ins of those names.
// Read by a call, at compile time, by `in`, as a method value, on a view
// and inside a pipeline.
const HAS: bool = comptime "hello".starts_with("he")
fn main:
    let s = "hello world"
    print(s.contains("lo w"))
    print(s.starts_with("hello"))
    print(s.ends_with("world"))
    print(s.starts_with("world"))
    print("lo" in s)
    print(HAS)
    let f = str.starts_with
    print(f(s, "he"))
    let v = s[0..5]
    print(v.ends_with("lo"))
    let xs = ["ab", "cd"].iter() |> filter(it.starts_with("a")) |> collect[List]()
    print(xs.len())
