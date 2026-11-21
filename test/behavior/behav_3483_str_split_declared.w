//! expect-stdout: 4
//! expect-stdout: [one]
//! expect-stdout: [two]
//! expect-stdout: []
//! expect-stdout: [three]
//! expect-stdout: 0
//! expect-stdout: 1
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: two
//! expect-stdout: 3
//! expect-stdout: 3

// #3483 (D110): `str.split` is declared in the standard library over the
// runtime's split; the compiler has no built-in of that name.
const PARTS: i32 = comptime "a,b,c".split(",").len() as i32
fn main:
    let s = "one,two,,three"
    let parts = s.split(",")
    print(parts.len())
    for p in parts: print(f"[{p}]")
    print("".split(",").len())
    print("whole".split("").len())
    print(PARTS)
    let f = str.split
    print(f("x-y", "-").len())
    let v = s[0..7]
    print(v.split(",")[1])
    let n = ["a b", "c d e"].iter() |> map(it.split(" ").len()) |> collect[List]()
    print(n[1])
    var words = "k=v".split("=")
    words.push("more")
    print(words.len())
