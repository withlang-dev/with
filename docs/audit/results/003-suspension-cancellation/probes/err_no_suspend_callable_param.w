async fn work() -> i32: 42
fn invoke(cb: fn() -> i32) -> i32: cb()

fn main:
    let cb = () => work().await
    no_suspend:
        let _ = invoke(cb)
