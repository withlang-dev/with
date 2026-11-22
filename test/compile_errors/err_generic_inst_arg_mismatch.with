//! expect-check-fail: wrong argument type
//! expect-check-fail: Box[str]
//! expect-check-fail: Box[i32]

type Box[T] { value: T }

fn take_i32_box(box: Box[i32]) -> i32:
    box.value

fn main:
    let s: Box[str] = Box { value: "no" }
    take_i32_box(s)
