async fn work() -> i32: 42
fn invoke(cb: fn() -> i32) -> i32: cb()
fn forward(cb: fn() -> i32) -> i32: invoke(cb)

fn main:
    let cb = () => work().await
    no_suspend:
        let _ = forward(cb)
