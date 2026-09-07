use std.builtins.print_i32
async fn fetch() -> i32: 42
async fn main:
    let t = fetch()
    let a = t.await
    let b = t.await
    print_i32(a + b)
