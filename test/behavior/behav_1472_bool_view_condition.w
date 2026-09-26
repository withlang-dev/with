//! expect-stdout: 1 a
//! expect-stdout: 2 b
//! expect-stdout: 1

// #1472: a condition is an owned `bool` demand; a `&bool` element or field
// view materializes its pointee (D22 contextual Copy), the same as
// `let b: bool = v[i]`.

type D { flags: Vec[bool] }

fn f(d: &D, i: i32) -> str: if d.flags[i]: "a" else: "b"

fn main:
    let v: Vec[bool] = Vec.new()
    v.push(true)
    v.push(false)
    let x = if v[0]: 1 else: 2
    let y = if v[1]: 1 else: 2
    let d = D { flags: v }
    print(f"{x} {f(d, 0)}")
    print(f"{y} {f(d, 1)}")
    var n = 0
    while d.flags[n]:
        n += 1
    print(f"{n}")
