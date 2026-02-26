// Test references and dereferencing
fn add_to(ptr: &mut i32, val: i32) =
    *ptr = *ptr + val

fn main() -> i32 =
    let mut x = 10
    add_to(&mut x, 5)
    println(x)

    let mut y = 100
    add_to(&mut y, 50)
    println(y)
    0
