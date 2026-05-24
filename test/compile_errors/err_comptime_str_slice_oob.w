//! expect-check-fail: str.slice() bounds out of range in comptime

comptime fn slice_oob() -> str:
    let s = "hello"
    s.slice(0, 100)

fn main:
    let bad: str = comptime slice_oob()
    print(bad)
