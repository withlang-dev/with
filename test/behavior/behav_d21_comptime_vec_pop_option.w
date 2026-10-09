//! expect-stdout: ok

comptime fn empty_is_none() -> bool:
    var v = List[i32].new()
    v.pop().is_none()

comptime fn pop_value() -> i32:
    var v = List[i32].new()
    v |> push(20) |> push(22)
    v.pop().unwrap()

const EMPTY_IS_NONE: bool = comptime empty_is_none()
const POPPED: i32 = comptime pop_value()

fn main:
    assert(EMPTY_IS_NONE)
    assert(POPPED == 22)
    print("ok")
