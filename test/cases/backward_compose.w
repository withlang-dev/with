fn double(x: i32) -> i32 = x * 2
fn add_one(x: i32) -> i32 = x + 1

fn main() -> i32 =
    let f = add_one >> double
    assert(f(5) == 12)
    let g = add_one << double
    assert(g(5) == 11)
    0
