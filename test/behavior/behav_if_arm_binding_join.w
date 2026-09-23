//! expect-stdout: [xy] [xy] [xy] [uv]
//! expect-stdout: 2 [xy]
//! expect-stdout: [xy] [xy]
//! expect-stdout: [uv] [xy]
//! expect-stdout: 3 1
//! expect-stdout: [k] [xy]

// #1380 (§2.2): a value `if`/`match` arm that yields a whole binding moves
// it, so a program that keeps the binding clones in the arm (or joins
// views). Each read below must see the text; before the fix the moved arm
// was accepted and every later read printed "".
use std.process

fn main:
    let a = "x" ++ "y"
    let b = "u" ++ "v"
    let c = args().len() < 100
    let p = if c: a.clone() else: b.clone()
    let q = if c: a.clone() else: b.clone()
    print(f"[{p}] [{q}] [{a}] [{b}]")

    let n = (if c: a.clone() else: b.clone()).len()
    print(f"{n} [{a}]")

    let r = match c:
        true => a.clone()
        false => b.clone()
    print(f"[{r}] [{a}]")

    // the arm that moves is the last use: nothing is read after it
    let s = if c: b else: "none" ++ ""
    print(f"[{s}] [{a}]")

    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    var ys: Vec[i32] = Vec.new()
    for i in 0..3: ys.push(i)
    let v = if c: ys else: Vec.new()
    print(f"{v.len()} {xs.len()}")

    // a block-local tail is the block's own value; the outer binding stays
    let t = if c:
        let k = "k" ++ ""
        k
    else:
        "z" ++ ""
    print(f"[{t}] [{a}]")
