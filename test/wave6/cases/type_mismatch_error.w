// Wave 6 unit test: type mismatch error
fn add(a: i32, b: i32) -> i32:
    a + b

fn main -> i32:
    add(1, true)
