// Test: non-local return inside with body is transparent
fn choose(x: i32) -> i32:
    with x as y:
        if y == 42 then return y
        0

fn main -> i32:
    assert(choose(42) == 42)
    assert(choose(7) == 0)
