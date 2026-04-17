//! expect-stdout: all inline if chain tests passed

fn clamp(x: i32, lo: i32, hi: i32) -> i32:
    if x < lo then lo
    else if x > hi then hi
    else x

fn classify(x: i32) -> str:
    if x > 100 then "big"
    else if x > 50 then "medium"
    else if x > 10 then "small"
    else "tiny"

fn main:
    assert(clamp(-5, 0, 10) == 0)
    assert(clamp(5, 0, 10) == 5)
    assert(clamp(15, 0, 10) == 10)

    assert(classify(200) == "big")
    assert(classify(75) == "medium")
    assert(classify(25) == "small")
    assert(classify(5) == "tiny")

    let x = if true then 42 else 0
    assert(x == 42)

    let y = if false then 1 else 2
    assert(y == 2)

    print("all inline if chain tests passed")
