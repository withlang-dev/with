fn add_one(x: &mut i32):
    *x = *x + 1

fn main -> i32:
    let mut n = 10
    add_one(&mut n)
    println(n)
    let val = n
    println(val)
