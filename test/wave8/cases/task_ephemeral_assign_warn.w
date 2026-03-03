async fn borrow(x: &mut i32) -> i32:
    *x

fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let mut x = 9
    let t1 = borrow(&mut x)
    let t2 = t1
    sink(t2)
    0
