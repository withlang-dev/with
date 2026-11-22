//! expect-stdout: 6
//! expect-stdout: -1
//! expect-stdout: HELLO WORLD
//! expect-stdout: HELLO WORLD
//! expect-stdout: hello world
//! expect-stdout: hello world
//! expect-stdout: HeLLo WorLd
//! expect-stdout: ababab
//! expect-stdout: ABC
//! expect-stdout: X
//! expect-stdout: hello
//! expect-stdout: bb

// #3483 (D110): `str.index_of`, `to_upper`/`upper`, `to_lower`/`lower`,
// `replace` and `repeat` are declared in the standard library; the compiler
// has no built-ins of those names.
const UP: str = comptime "abc".to_upper()
fn main:
    let s = "Hello World"
    print(s.index_of("World"))
    print(s.index_of("zzz"))
    print(s.to_upper())
    print(s.upper())
    print(s.to_lower())
    print(s.lower())
    print(s.replace("l", "L"))
    print("ab".repeat(3))
    print(UP)
    let f = str.to_upper
    print(f("x"))
    let v = s[0..5]
    print(v.to_lower())
    let xs = ["a", "b"].iter() |> map(it.repeat(2)) |> collect[List]()
    print(xs[1])
