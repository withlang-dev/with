use std.builtins.print_i32
async fn fetch() -> i32: 42
fn f(x: i32 = fetch().await) -> i32: x
fn main:
    print_i32(f())
