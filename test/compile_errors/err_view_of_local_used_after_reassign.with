//! expect-check-fail: is a live view

// #1249 / §21.1 rule 1: reassigning the borrowed place invalidates the view;
// the str case (`&x` then `x = ...`).

fn main:
    var x = "a" ++ "b"
    let s = &x
    x = "c" ++ "d"
    print(f"{s.len()}")
