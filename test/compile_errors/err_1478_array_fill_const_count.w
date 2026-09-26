//! expect-check-fail: needs an integer literal count

// #1478 (§4.3a): a non-literal fill count silently built a 1-element array;
// a typed binding then read uninitialized tail elements. It is refused
// loudly until the fill is evaluated by Sema.

let N: i64 = 4

fn main:
    let a = [7 as i32; N]
    print(f"{a.len()}")
