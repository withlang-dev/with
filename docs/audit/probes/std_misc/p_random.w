use std.random

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn main():
    // Reproducibility: same seed -> same sequence
    seed(42)
    let a1 = next_i32()
    let a2 = next_i32()
    seed(42)
    let b1 = next_i32()
    let b2 = next_i32()
    expect("seed reproducible 1", a1 == b1)
    expect("seed reproducible 2", a2 == b2)
    // Different seeds diverge (smoke)
    seed(1)
    let c1 = next_i32()
    seed(2)
    let d1 = next_i32()
    expect("different seeds diverge", c1 != d1)
    // range_i32 edge: hi <= lo returns lo (no crash, no hang)
    expect("range hi==lo", range_i32(5, 5) == 5)
    expect("range hi<lo", range_i32(9, 3) == 9)
    // range_i32 in-bounds smoke over 200 draws
    seed(7)
    var ok = true
    for i in 0..200:
        let v = range_i32(10, 20)
        if v < 10 or v >= 20: ok = false
    expect("range in bounds x200", ok)
    // range size 1 always lo
    expect("range size 1", range_i32(4, 5) == 4)
    // chance edges
    expect("chance 0 false", chance(0) == false)
    expect("chance -5 false", chance(-5) == false)
    expect("chance 100 true", chance(100) == true)
    expect("chance 200 true", chance(200) == true)
    // chance(50) smoke: both outcomes over 200 draws
    seed(1234)
    var t = 0
    for i in 0..200:
        if chance(50): t = t + 1
    expect("chance 50 mixed", t > 50 and t < 150)
    // seed_now does not crash; next works after
    seed_now()
    let _ = next_i32()
    expect("seed_now ok", true)
