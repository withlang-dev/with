//! expect-stdout: 4
//! expect-stdout: 4 7
//! expect-stdout: 4 1
//! expect-stdout: 8
//! expect-stdout: 3 0
//! expect-stdout: 2
//! expect-stdout: 3 7

// #1478 (§4.3a): `[value; N]` builds N copies of value when N is a `const`
// or a constant expression, not only an integer literal. The parser's
// fill desugar handled a literal count only and silently used ONE copy
// otherwise, so a typed binding read uninitialized tail elements.
const N = 4
const HALF = N / 2

fn main:
    let a = [7; N]
    print(f"{a.len()}")
    let b: [4]i32 = [7; N]
    print(f"{b.len()} {b[3]}")
    let c = [1; 2 + 2]
    print(f"{c.len()} {c[3]}")
    let d = [0 as u8; N * 2]
    print(f"{d.len()}")
    let v: Vec[i32] = [0; 3]
    print(f"{v.len()} {v[2]}")
    let w: Vec[i32] = [9; HALF]
    print(f"{w.len()}")
    print(f"{A.len()} {A[2]}")

const A = [7; N - 1]
