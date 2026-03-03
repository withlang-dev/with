async fn work(x: i32) -> i32:
    x + 1

fn main -> i32:
    spawn work(1)
    spawn work(2)
    0

