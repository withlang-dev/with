// Test: local file import
use helpers

fn main() -> i32 =
    let sum = add(10, 20)
    let d = double(15)
    assert(sum == 30)
    assert(d == 30)
    0
