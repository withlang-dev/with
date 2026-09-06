use std.testing

fn main:
    assert(true)
    assert(true, "explicit msg")
    require(true, "req pass")
    check(true, "check pass")
    assert_eq(1, 1)
    assert_eq("a", "a")
    assert_ne(1, 2)
    print("testing-pass-ok")
