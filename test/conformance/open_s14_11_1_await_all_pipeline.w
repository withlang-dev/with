//! expect-stdout: 3
// §14.11.1: ids |> map(f(it)) |> await_all. #2954
use std.task.await_all
async fn sq(n: i32) -> i32: n * n
fn main:
    let xs: List[i32] = [1, 2, 3]
    let ys = xs |> map(sq(it)) |> await_all
    print(ys.len())
