fn apply(f: fn(i32) -> i32, value: i32) -> i32: f(value)

fn main:
    let offset = 3
    assert(apply(x => x + offset, 4) == 7)
