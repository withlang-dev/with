//! expect-stdout: -2
//! expect-stdout: 1
//! expect-stdout: 5
//! expect-stdout: 5
//! expect-stdout: 1
//! expect-stdout: 2

// #1533 (§9.7): slice patterns covering every length are exhaustive
// without a `_` arm — the engine classified a dynamic slice as open.

fn head(s: []i32) -> i32:
    match s:
        [a, b] => a - b
        [a, ..] => a
        [] => -2

fn kind(v: Vec[i32]) -> i32:
    match v:
        [] => 0
        [_] => 1
        [_, _, ..] => 2

fn main:
    let e: [i32; 0] = []
    print(head(e[..]))
    let a: [i32; 1] = [1]
    print(head(a[..]))
    let b: [i32; 2] = [7, 2]
    print(head(b[..]))
    let c: [i32; 3] = [5, 2, 9]
    print(head(c[..]))
    let v: Vec[i32] = Vec.new()
    v.push(1)
    print(kind(v))
    let w: Vec[i32] = Vec.new()
    w.push(1)
    w.push(2)
    w.push(3)
    print(kind(w))
