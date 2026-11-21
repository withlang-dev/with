//! expect-stdout: 72
//! expect-stdout: 111
//! expect-stdout: Hello
//! expect-stdout: World
//! expect-stdout: 0
//! expect-stdout: 97
//! expect-stdout: el
//! expect-stdout: llo
//! expect-stdout: bcd
//! expect-stdout: el
//! expect-stdout: 101
//! expect-stdout: be

// #3483 (D110): `str.byte_at` and `str.slice` are declared in the standard
// library over the runtime's functions; the compiler has no built-ins of
// those names. With them every `str` method is a library declaration.
const FIRST: i32 = comptime "abc".byte_at(0)
const MID: str = comptime "hello".slice(1, 3)
fn main:
    let s = "Hello World"
    print(s.byte_at(0))
    print(s.byte_at(4))
    print(s.slice(0, 5))
    print(s.slice(6, 99))
    print(s.slice(4, 2).len())
    print(FIRST)
    print(MID)
    let n: i32 = 2
    print(s.slice(n, n + 3))
    let f = str.slice
    print(f("abcdef", 1, 4))
    let v = s[0..5]
    print(v.slice(1, 3))
    print(v.byte_at(1))
    let parts = ["alpha", "beta"].iter() |> map(it.slice(0, 2)) |> collect[List]()
    print(parts[1])
