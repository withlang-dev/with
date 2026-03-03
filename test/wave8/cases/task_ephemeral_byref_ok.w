async fn borrow(x: &mut i32) -> i32:
    *x

fn inspect(t: &i32) -> i32:
    *t

fn main -> i32:
    let mut x = 11
    let t = borrow(&mut x)
    inspect(&t)
    0
