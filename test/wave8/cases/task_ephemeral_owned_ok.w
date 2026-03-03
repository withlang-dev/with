async fn owned(x: i32) -> i32:
    x + 1

fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let t = owned(1)
    sink(t)
    0
