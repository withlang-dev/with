async fn work() -> i32: 42
fn first() -> i32: work().await
fn second() -> i32: first()

fn main:
    no_suspend:
        let _ = second()
