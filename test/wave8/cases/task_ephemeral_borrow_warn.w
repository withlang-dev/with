async fn borrow(x: &mut i32) -> i32:
    *x

fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let mut x = 7
    let t = borrow(&mut x)
    sink(t)
    0
