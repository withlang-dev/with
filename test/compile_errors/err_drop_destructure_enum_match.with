//! expect-check-fail: keep it whole (`let t = e`) or match through a borrow (`match &e`); only a `move fn` of `E` may take it apart

// #1272: an enum with its own Drop is a Drop value like any other — a variant
// pattern over it by value would skip the destructor. Outside the enum's own
// `move fn` methods the spelling that observes it is `match &e`.

var count: i32 = 0
enum E { Idle | Running(i32) }
impl Drop for E:
    move fn drop(): count = count + 1

fn main:
    let e = E.Running(3)
    match e:
        E.Running(p) => print(f"{p}")
        _ => print("0")
