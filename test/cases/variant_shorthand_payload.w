// Test .Variant(payload) shorthand syntax

type Color = Red | Green | Blue | Custom(i32)

fn describe(c: Color) -> i32:
    match c
        .Red -> 1
        .Green -> 2
        .Blue -> 3
        .Custom(v) -> v

fn main -> i32:
    let c1: Color = .Red
    let c2: Color = .Custom(42)
    let r1 = describe(c1)
    let r2 = describe(c2)
    println(r1)
    println(r2)
    if r1 == 1 and r2 == 42
        0
    else
        1
