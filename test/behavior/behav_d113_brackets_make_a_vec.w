//! expect-stdout: 4 4
//! expect-stdout: 6
//! expect-stdout: -v
//! expect-stdout: -q
//! expect-stdout: 2 64
//! expect-stdout: 4
//! expect-stdout: 2 a a
//! expect-stdout: 3
//! expect-stdout: 10 2

// D113 (§4.3c rule 1): a bracket literal is a List[T] unless another
// collection built from a list is demanded. With no demand it grows, is
// passed straight to a `&List` parameter, iterates, and keeps duplicates; the
// repeat form is a List too.

fn total(xs: &List[i32]): xs.iter() |> sum()

fn main:
    var a = [1, 2, 3]
    a.push(4)
    print(f"{a.len()} {a[3]}")
    print(total([1, 2, 3]))
    for flag in ["-v", "-q"]: print(flag)
    var out = []
    out.push(2)
    out.push(64)
    print(f"{out[0]} {out[1]}")
    var zeros = [0; 3]
    zeros.push(0)
    print(zeros.len())
    let twice = ["a", "a"]
    print(f"{twice.len()} {twice[0]} {twice[1]}")
    let w: List = [1, 2, 3]
    print(w.len())
    let moved = a
    print(f"{moved.iter() |> sum()} {moved[1]}")
