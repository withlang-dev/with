fn bump(value: i32) -> i32: value + 1

fn apply_raw(f: *const fn(i32) -> i32, value: i32) -> i32: f(value)

fn main:
    assert(apply_raw(&bump, 1) == 2)
