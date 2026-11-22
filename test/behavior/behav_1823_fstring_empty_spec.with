//! expect-stdout: [hello] [hello]
//! expect-stdout: [42] [42]
//! expect-stdout: [3.14] [3.14]
//! expect-stdout: [true] [true]
//! expect-stdout: [Red] [Red]

// #1823 (§15.4.1): every field of a format spec is optional, so the empty
// spec `{x:}` is the default display, the same as `{x}`. It was read as
// precision 0: a str printed nothing and an integer was refused.

enum Color:
    Red
    Blue

fn main:
    let h = "hello"
    print(f"[{h:}] [{h}]")
    let n = 42
    print(f"[{n:}] [{n}]")
    let x = 3.14
    print(f"[{x:}] [{x}]")
    let flag = true
    print(f"[{flag:}] [{flag}]")
    let c = Color.Red
    print(f"[{c:}] [{c}]")
