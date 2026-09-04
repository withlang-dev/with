use std.builtins.print
async fn work() -> i32:
    print("work ran")
    42
fn main:
    work()
    print("done")
