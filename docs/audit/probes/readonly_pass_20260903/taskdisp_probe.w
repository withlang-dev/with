use std.builtins.print
async fn borrows(x: &i32) -> i32: *x + 1
fn main:
    let v = 10
    borrows(&v)
    print("done")
